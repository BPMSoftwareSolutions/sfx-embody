-- Select the request-named consumer-runtime definition for sda-cli-invoke-port.
--
-- Live state: model.bind_provider is digest-idempotent, so re-running
-- rebind-sda-cli-invoke-port.commit.sql re-pointed model.operation_port_invocation
-- at port_version 4357 (definition 211129, platformCapabilityId
-- sda-node-consumer-runtime.v1) but did not mint a new definition. The estate's
-- selection is the highest linked definition per object
-- (analysis.v_selected_semantic_definition = MAX(estate_definition.
-- semantic_object_definition_pk) among this object's links), and the pinned v2
-- definition 211164 (port_version 4376) is still linked, so the graph source
-- resolved the pinned application. The request-named binding was installed but
-- not selected.
--
-- This migration de-selects exactly this port object's estate links that are
-- newer than the request-named definition and declare another platform
-- capability. Every definition row, port version and content object is retained
-- as unselected history (the withdraw-model-tool-registry de-selection
-- precedent): restoring the pinned selection is one estate_definition link, not
-- a re-declaration, so the pinned path remains available.
--
-- It also re-points the selected invocation row at the request-named port
-- version so the invocation pointer and the selection agree.
--
-- Idempotent: when the selected definition already declares
-- sda-node-consumer-runtime.v1, no link is removed and no pointer moves.
--
-- Preflight: ends with ROLLBACK; run as a dry run with the migration runner.
-- The install is the .commit.sql copy (identical except COMMIT).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'SDA_CLI_INVOKE_REQUEST_NAMED_LOCK_FAILED',1;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @namespace nvarchar(400)=N'sidefx:capability:sda-cli-invoke';
DECLARE @port nvarchar(400)=N'sda-cli-invoke-port';
DECLARE @carrier nvarchar(400)=N'sda-node-consumer-runtime.v1';
DECLARE @carrier_definition bigint, @carrier_port_version bigint;
DECLARE @object bigint=(
 SELECT MAX(so.semantic_object_pk)
 FROM model.semantic_object so
 JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk AND n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
 WHERE so.declared_id=@port COLLATE Latin1_General_100_BIN2 AND so.object_kind=N'PORT');
IF @object IS NULL THROW 51000,N'SDA_CLI_INVOKE_PORT_OBJECT_MISSING',1;

-- The request-named definition is the linked history row that declares the
-- consumer-runtime mechanic. Its link is never removed.
SELECT TOP 1 @carrier_definition=d.semantic_object_definition_pk, @carrier_port_version=pv.port_version_pk
FROM model.semantic_object_definition d
JOIN model.port_version pv ON pv.semantic_object_definition_pk=d.semantic_object_definition_pk
JOIN model.estate_definition ed ON ed.estate_model_pk=@estate AND ed.semantic_object_definition_pk=d.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dt
WHERE d.semantic_object_pk=@object
 AND JSON_VALUE(dt.text,'$.semantics.platformCapabilityId')=@carrier COLLATE Latin1_General_100_BIN2
ORDER BY d.semantic_object_definition_pk DESC;
IF @carrier_definition IS NULL THROW 51000,N'SDA_CLI_INVOKE_REQUEST_NAMED_DEFINITION_MISSING',1;

DECLARE @selected_definition bigint, @selected_capability nvarchar(400);
SELECT @selected_definition=d.semantic_object_definition_pk,
 @selected_capability=JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId')
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT'
 AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
 AND d.declared_id=@port COLLATE Latin1_General_100_BIN2;
IF @selected_definition IS NULL THROW 51000,N'SDA_CLI_INVOKE_PORT_NOT_SELECTED',1;

IF @selected_definition<>@carrier_definition
BEGIN
  -- Refuse on any newer linked definition whose mechanic cannot be read: the
  -- de-selection must be exactly "a superseding declaration of another
  -- platform capability", never an unreadable body.
  IF EXISTS (
    SELECT 1
    FROM model.estate_definition ed
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
    JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dt
    WHERE ed.estate_model_pk=@estate
     AND d.semantic_object_pk=@object
     AND d.semantic_object_definition_pk>@carrier_definition
     AND (ISJSON(dt.text)<>1 OR JSON_VALUE(dt.text,'$.semantics.platformCapabilityId') IS NULL
          OR JSON_VALUE(dt.text,'$.semantics.platformCapabilityId')=@carrier COLLATE Latin1_General_100_BIN2))
   THROW 51000,N'SDA_CLI_INVOKE_REQUEST_NAMED_SUPERSEDING_BODY_UNREADABLE',1;

  DELETE ed
  FROM model.estate_definition ed
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ed.semantic_object_definition_pk
  WHERE ed.estate_model_pk=@estate
   AND d.semantic_object_pk=@object
   AND d.semantic_object_definition_pk>@carrier_definition;

  SELECT @selected_definition=d.semantic_object_definition_pk,
   @selected_capability=JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT'
   AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@port COLLATE Latin1_General_100_BIN2;
  IF @selected_definition<>@carrier_definition
   THROW 51000,N'SDA_CLI_INVOKE_REQUEST_NAMED_SELECTION_DIVERGED',1;

  UPDATE opi SET opi.port_version_pk=@carrier_port_version
  FROM model.operation_port_invocation opi
  JOIN model.execution_operation eo ON eo.execution_operation_pk=opi.execution_operation_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
  JOIN model.scenario_event se ON se.execution_authority_version_pk=eav.execution_authority_version_pk
  JOIN model.scenario_version sv ON sv.scenario_version_pk=se.scenario_version_pk
  JOIN model.capability_scenario cs ON cs.scenario_version_pk=sv.scenario_version_pk
  JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=N'invoke'
  JOIN model.capability c ON c.capability_pk=cs.capability_pk AND c.capability_id=N'sda-cli-invoke'
  WHERE opi.port_version_pk<>@carrier_port_version;
END
ELSE
  SELECT 'sda_cli_invoke_request_named_already_selected' AS result_set,
   @selected_definition AS selected_definition, @selected_capability AS platform_capability_id;

-- Readback: the selected definition, the invocation pointer and the carrier paths.
SELECT 'sda_cli_invoke_request_named' AS result_set,
 c.capability_id, p.port_id, n.namespace_id, pv.port_version_pk,
 sod.semantic_object_definition_pk,
 JSON_VALUE(dt.text,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(dt.text,'$.semantics.configuration.capabilityIdPath') AS capability_id_path,
 JSON_VALUE(dt.text,'$.semantics.configuration.requestPath') AS request_path,
 JSON_VALUE(dt.text,'$.semantics.configuration.resultPath') AS result_path,
 JSON_VALUE(dt.text,'$.semantics.configuration.lineageMode') AS lineage_mode,
 JSON_VALUE(dt.text,'$.semantics.configuration.authoritySource') AS authority_source
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=N'sda-cli-invoke'
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=N'invoke'
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dt
WHERE ec.estate_model_pk=@estate;

SELECT 'sda_cli_invoke_selected_port' AS result_set, d.semantic_object_definition_pk,
 JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT'
 AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
 AND d.declared_id=@port COLLATE Latin1_General_100_BIN2;
ROLLBACK TRANSACTION;
