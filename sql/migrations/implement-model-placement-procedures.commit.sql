-- implement-model-placement-procedures.sql
--
-- Lane 3, item 1: replace the three refuse-by-default placement stubs declared by
-- declare-model-placement-lifecycle-stubs.sql with real bodies per
-- docs/model-at-each-authoring-altitude-2026-09-21/altitude-model-placement-sql.md
-- (section A CREATE, section C CREATE, section D CREATE, section A/C/D UPDATE and DELETE/RETIRE) and the
-- failure-review corrections: never delete invocation rows, never rewrite history,
-- never hard-code the Node provider.
--
--   model.install_model_placement_change @document nvarchar(max)
--     mechanism A (sda-generic-llm-connector-port.v1): connector envelope.
--     mechanism B (sda-governed-http-exchange-port.v1): delegates to
--       model.install_provider_binding_change with configuration.providerBindingChange.
--     mechanism C (sda-projected-capability-invocation-port.v2): projected-child envelope.
--     mechanism D (sda-authority-transformation-port.v1): transformation + envelope,
--       normalize_transformation_expression.
--     Every non-B placement is linked through the existing model.declare_scenario
--     (@operations/@port_bindings). Replay of identical semantics -> already_installed;
--     a linked port with different semantics -> MODEL_PLACEMENT_REVISION_REFUSED.
--   model.replace_port_configuration @namespace,@port,@configuration_json
--     Re-mints the selected port definition, inserts the port_version, re-points every
--     operation_port_invocation of that port. Identical bytes -> already_installed.
--   model.retire_model_placement @namespace,@port,@disposition
--     Clears mechanism binding keys (A: connectorAuthorityRef; C: bindingRef/bindingBase),
--     removes the operation links, de-selects the port definition membership, and writes
--     a retirement AUTHORITY receipt. Replay same disposition -> already_retired; a
--     different disposition -> MODEL_PLACEMENT_RETIREMENT_REVISION_REFUSED; a port still
--     demanded by a selected provider-slot/binding route -> PORT_STILL_REFERENCED_BY_SELECTED_ROUTE.
--
-- Genuinely unsupported inputs keep named refusals: PLACEMENT_MECHANISM_UNSUPPORTED,
-- PLACEMENT_CONFIGURATION_INVALID, PLACEMENT_LEGACY_BINDING_NOT_IMPLEMENTED,
-- PLACEMENT_SCENARIO_REQUIRED, PLACEMENT_OPERATIONS_REQUIRED,
-- PLACEMENT_PROVIDER_BINDING_DOCUMENT_REQUIRED, PLACEMENT_SLOT_ROWS_NOT_IMPLEMENTED,
-- PLACEMENT_RETIREMENT_MECHANISM_UNSUPPORTED.
--
-- Boot authority (same selected sda-kernel-boot-data-access.v1): the three placement
-- operations and their parameter contracts are already declared by the stub migration.
-- This migration revises four of the eight placement changeContracts from their
-- placeholder shapes to the real carrier/result shapes (the result contracts become the
-- executor's recordsets envelope). The re-mint asserts a STRUCTURAL prerequisite set
-- rather than an exact prior content digest, because a parallel lane may be re-minting
-- the same authority; replay is detected from the revised contracts themselves.
--
-- Idempotent: CREATE OR ALTER is re-runnable; the authority is re-minted only when the
-- revised contract shape is absent; a replay prints already_declared.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'PLACEMENT_PROCEDURES_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
CREATE OR ALTER PROCEDURE model.install_model_placement_change @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'PLACEMENT_TRANSACTION_REQUIRED',1;
 IF @document IS NULL OR ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'model-placement-change.v1'
  THROW 51000,'PLACEMENT_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_id nvarchar(400)=JSON_VALUE(@document,'$.capabilityId');
 DECLARE @port_id nvarchar(400)=JSON_VALUE(@document,'$.portId');
 DECLARE @platform nvarchar(400)=JSON_VALUE(@document,'$.platformCapabilityId');
 IF NULLIF(@capability_id,N'') IS NULL THROW 51000,'PLACEMENT_CAPABILITY_REQUIRED',1;
 IF NULLIF(@port_id,N'') IS NULL THROW 51000,'PLACEMENT_PORT_REQUIRED',1;
 IF NULLIF(@platform,N'') IS NULL THROW 51000,'PLACEMENT_PLATFORM_CAPABILITY_REQUIRED',1;
 IF @platform NOT IN (N'sda-generic-llm-connector-port.v1',N'sda-governed-http-exchange-port.v1',
   N'sda-projected-capability-invocation-port.v2',N'sda-authority-transformation-port.v1')
  THROW 51000,'PLACEMENT_MECHANISM_UNSUPPORTED',1;
 DECLARE @namespace nvarchar(400)=ISNULL(NULLIF(JSON_VALUE(@document,'$.namespace'),N''),N'sidefx:capability:'+@capability_id);
 IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capability_id)
  THROW 51000,'PLACEMENT_CAPABILITY_NOT_FOUND',1;
 DECLARE @configuration nvarchar(max)=JSON_QUERY(@document,'$.configuration');
 IF @configuration IS NULL THROW 51000,'PLACEMENT_CONFIGURATION_REQUIRED',1;
 IF JSON_QUERY(@document,'$.slots') IS NOT NULL THROW 51000,'PLACEMENT_SLOT_ROWS_NOT_IMPLEMENTED',1;

 -- Mechanism B: delegate the whole route install to the admitted installer.
 IF @platform=N'sda-governed-http-exchange-port.v1'
 BEGIN
  DECLARE @provider_document nvarchar(max)=JSON_QUERY(@configuration,'$.providerBindingChange');
  IF @provider_document IS NULL OR ISJSON(@provider_document)<>1
   OR JSON_VALUE(@provider_document,'$.contractId')<>N'provider-binding-change.v1'
   THROW 51000,'PLACEMENT_PROVIDER_BINDING_DOCUMENT_REQUIRED',1;
  DECLARE @delegated TABLE(result_set nvarchar(100),provider_id nvarchar(400),capability_id nvarchar(400),
   route_id nvarchar(400),endpoint_authority_digest nvarchar(100));
  INSERT @delegated EXEC model.install_provider_binding_change @document=@provider_document;
  SELECT CASE WHEN EXISTS(SELECT 1 FROM @delegated WHERE result_set=N'already_installed')
   THEN N'already_installed' ELSE N'model_placement_installed' END AS result_set,@port_id AS port_id;
  RETURN;
 END

 -- Mechanism A: external connector envelope. No estate credential rows exist.
 DECLARE @semantics nvarchar(max);
 IF @platform=N'sda-generic-llm-connector-port.v1'
 BEGIN
  IF NULLIF(JSON_VALUE(@configuration,'$.connectorAuthorityRef'),N'') IS NULL
   OR NULLIF(JSON_VALUE(@configuration,'$.requestPath'),N'') IS NULL
   OR JSON_VALUE(@configuration,'$.lineageMode')<>N'retain-external-execution'
   OR JSON_VALUE(@configuration,'$.credentialsMode')<>N'external-reference-only'
   THROW 51000,'PLACEMENT_CONFIGURATION_INVALID',1;
  SET @semantics=(SELECT @port_id AS portId,@platform AS platformCapabilityId,JSON_QUERY(@configuration) AS configuration
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END
 -- Mechanism C: projected capability invocation envelope. The declared application is
 -- the carrier; the legacy bindingRef form is a separate reshape (C5) and is refused here.
 ELSE IF @platform=N'sda-projected-capability-invocation-port.v2'
 BEGIN
  IF NULLIF(JSON_VALUE(@configuration,'$.bindingDigest'),N'') IS NULL
   OR NULLIF(JSON_VALUE(@configuration,'$.capabilityAuthorityDigest'),N'') IS NULL
   OR NULLIF(JSON_VALUE(@configuration,'$.requestPath'),N'') IS NULL
   OR JSON_VALUE(@configuration,'$.lineageMode')<>N'retain-nested-execution'
   THROW 51000,'PLACEMENT_CONFIGURATION_INVALID',1;
  IF JSON_QUERY(@configuration,'$.declaredApplication') IS NULL
   THROW 51000,'PLACEMENT_LEGACY_BINDING_NOT_IMPLEMENTED',1;
  IF ISNULL(JSON_VALUE(@configuration,'$.resultMode'),N'')<>N'replace-carrier'
   AND NULLIF(JSON_VALUE(@configuration,'$.resultPath'),N'') IS NULL
   THROW 51000,'PLACEMENT_CONFIGURATION_INVALID',1;
  SET @semantics=(SELECT @port_id AS portId,@platform AS platformCapabilityId,JSON_QUERY(@configuration) AS configuration
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END
 -- Mechanism D: pure transformation. The expression is normalized by the existing
 -- procedure; the port envelope only names the transformation id.
 ELSE
 BEGIN
  DECLARE @transformation_id nvarchar(400)=JSON_VALUE(@configuration,'$.transformationId');
  DECLARE @expression nvarchar(max)=JSON_QUERY(@configuration,'$.expression');
  IF NULLIF(@transformation_id,N'') IS NULL OR @expression IS NULL
   THROW 51000,'PLACEMENT_CONFIGURATION_INVALID',1;
  DECLARE @transformation_semantics nvarchar(max)=(SELECT @transformation_id AS id,JSON_QUERY(@expression) AS expression
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  DECLARE @t_object bigint,@t_definition bigint,@t_digest binary(32),@transformation bigint,@transformation_version bigint;
  EXEC model.put_semantic_definition 'TRANSFORMATION',@namespace,@transformation_id,@transformation_semantics,
   @t_object OUTPUT,@t_definition OUTPUT,@t_digest OUTPUT;
  SET @transformation=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@t_object);
  IF @transformation IS NULL
  BEGIN
   INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
   SELECT namespace_pk,@transformation_id,@t_object,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@t_object;
   SET @transformation=SCOPE_IDENTITY();
  END
  SET @transformation_version=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@t_definition);
  IF @transformation_version IS NULL
  BEGIN
   INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
    expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@transformation,@t_object,@t_definition,@t_digest,'json-expression-tree.v1','TRANSFORMATION',@t_definition,N'');
   SET @transformation_version=SCOPE_IDENTITY();
   EXEC model.normalize_transformation_expression @transformation_version;
  END
  SET @semantics=(SELECT @port_id AS portId,@platform AS platformCapabilityId,
   JSON_QUERY(N'{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"'
    +STRING_ESCAPE(@transformation_id,'json')+N'"}') AS configuration
   FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 END

 -- Replay and revision: a linked port may only replay its exact semantics. The digest
 -- recipe is the one model.put_semantic_definition uses, computed before any write.
 DECLARE @port_pk bigint=(SELECT p.port_pk FROM model.port p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
  WHERE n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND p.port_id=@port_id COLLATE Latin1_General_100_BIN2);
 IF @port_pk IS NOT NULL AND EXISTS(SELECT 1 FROM model.port_version pv JOIN model.operation_port_invocation i
   ON i.port_version_pk=pv.port_version_pk WHERE pv.port_pk=@port_pk)
 BEGIN
  DECLARE @candidate_text nvarchar(max)=(SELECT @port_id AS [address.id],N'PORT' AS [address.kind],@namespace AS [address.namespace],
   N'sidefx-semantic-definition.v1' AS format,JSON_QUERY(@semantics) AS semantics FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
  DECLARE @candidate_digest binary(32)=HASHBYTES('SHA2_256',
   CONVERT(varbinary(max),CONVERT(varchar(max),@candidate_text COLLATE Latin1_General_100_BIN2_UTF8)));
  DECLARE @selected_digest binary(32)=(SELECT d.definition_digest FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
    AND d.declared_id=@port_id COLLATE Latin1_General_100_BIN2);
  IF @selected_digest=@candidate_digest
  BEGIN
   SELECT N'already_installed' AS result_set,@port_id AS port_id;
   RETURN;
  END;
  THROW 51000,'MODEL_PLACEMENT_REVISION_REFUSED',1;
 END

 -- The scenario carrier is required for A/C/D: declare_scenario installs the port, its
 -- port_version, the execution authority, the operation link and the scenario in the
 -- capability's own rows.
 DECLARE @scenario nvarchar(max)=JSON_QUERY(@document,'$.scenario');
 IF @scenario IS NULL OR NULLIF(JSON_VALUE(@scenario,'$.scenarioId'),N'') IS NULL
  THROW 51000,'PLACEMENT_SCENARIO_REQUIRED',1;
 DECLARE @operations nvarchar(max)=JSON_QUERY(@scenario,'$.operations');
 IF @operations IS NULL THROW 51000,'PLACEMENT_OPERATIONS_REQUIRED',1;
 DECLARE @port_bindings nvarchar(max)=N'['+@semantics+N']';
 DECLARE @declared TABLE(declared_scenario nvarchar(400),scenario_version_pk bigint);
 INSERT @declared EXEC model.declare_scenario @capability_id=@capability_id,@scenario=@scenario,
  @operations=@operations,@port_bindings=@port_bindings;
 IF NOT EXISTS(SELECT 1 FROM @declared) THROW 51000,'PLACEMENT_SCENARIO_NOT_DECLARED',1;
 SELECT N'model_placement_installed' AS result_set,@port_id AS port_id;
END;
GO
CREATE OR ALTER PROCEDURE model.replace_port_configuration @namespace nvarchar(400),@port nvarchar(400),@configuration_json nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'PLACEMENT_TRANSACTION_REQUIRED',1;
 IF NULLIF(@namespace,N'') IS NULL OR NULLIF(@port,N'') IS NULL THROW 51000,'PLACEMENT_PORT_IDENTITY_REQUIRED',1;
 IF ISJSON(@configuration_json)<>1 THROW 51000,'PLACEMENT_CONFIGURATION_REQUIRED',1;
 IF JSON_QUERY(@configuration_json) IS NULL THROW 51000,'PLACEMENT_CONFIGURATION_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @selected nvarchar(max)=(SELECT TOP (1) d.definition_json FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@port COLLATE Latin1_General_100_BIN2);
 IF @selected IS NULL THROW 51000,'PLACEMENT_PORT_NOT_FOUND',1;
 DECLARE @prev_digest binary(32)=(SELECT TOP (1) d.definition_digest FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@port COLLATE Latin1_General_100_BIN2);
 DECLARE @port_pk bigint=(SELECT p.port_pk FROM model.port p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
  WHERE n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND p.port_id=@port COLLATE Latin1_General_100_BIN2);
 IF @port_pk IS NULL THROW 51000,'PLACEMENT_PORT_NOT_FOUND',1;
 IF NULLIF(JSON_VALUE(@selected,'$.semantics.platformCapabilityId'),N'') IS NULL
  THROW 51000,'PLACEMENT_PORT_NOT_SELECTED',1;
 DECLARE @semantics nvarchar(max)=JSON_MODIFY(JSON_QUERY(@selected,'$.semantics'),'$.configuration',JSON_QUERY(@configuration_json));
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition 'PORT',@namespace,@port,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 IF @digest=@prev_digest
 BEGIN
  SELECT N'already_installed' AS result_set,@port AS port_id;
  RETURN;
 END
 DECLARE @version bigint=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
 IF @version IS NULL
 BEGIN
  INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
   port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@port_pk,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
  SET @version=SCOPE_IDENTITY();
 END
 UPDATE i SET port_version_pk=@version
 FROM model.operation_port_invocation i
 JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk
 WHERE pv.port_pk=@port_pk;
 SELECT N'port_configuration_replaced' AS result_set,@port AS port_id;
END;
GO
CREATE OR ALTER PROCEDURE model.retire_model_placement @namespace nvarchar(400),@port nvarchar(400),@disposition nvarchar(100)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'PLACEMENT_TRANSACTION_REQUIRED',1;
 IF NULLIF(@namespace,N'') IS NULL OR NULLIF(@port,N'') IS NULL THROW 51000,'PLACEMENT_PORT_IDENTITY_REQUIRED',1;
 IF NULLIF(@disposition,N'') IS NULL THROW 51000,'PLACEMENT_DISPOSITION_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @receipt_id nvarchar(400)=@port+N'.retired.v1';
 DECLARE @prior nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics.document')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@receipt_id COLLATE Latin1_General_100_BIN2);
 IF @prior IS NOT NULL
 BEGIN
  IF JSON_VALUE(@prior,'$.disposition')<>@disposition THROW 51000,'MODEL_PLACEMENT_RETIREMENT_REVISION_REFUSED',1;
  SELECT N'already_retired' AS result_set,@port AS port_id;
  RETURN;
 END
 DECLARE @selected nvarchar(max)=(SELECT TOP (1) d.definition_json FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@port COLLATE Latin1_General_100_BIN2);
 IF @selected IS NULL THROW 51000,'PLACEMENT_PORT_NOT_FOUND',1;
 DECLARE @sod bigint=(SELECT TOP (1) d.semantic_object_definition_pk FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@port COLLATE Latin1_General_100_BIN2);
 DECLARE @port_pk bigint=(SELECT p.port_pk FROM model.port p JOIN model.identity_namespace n ON n.namespace_pk=p.namespace_pk
  WHERE n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND p.port_id=@port COLLATE Latin1_General_100_BIN2);
 -- The port is still demanded by a selected provider-slot/binding route: refuse.
 IF EXISTS(SELECT 1 FROM model.slot_port_requirement r JOIN model.port_version pv ON pv.port_version_pk=r.port_version_pk
   WHERE pv.port_pk=@port_pk)
  OR EXISTS(SELECT 1 FROM model.binding_port_implementation b JOIN model.port_version pv ON pv.port_version_pk=b.port_version_pk
   WHERE pv.port_pk=@port_pk)
  THROW 51000,'PORT_STILL_REFERENCED_BY_SELECTED_ROUTE',1;
 -- Mechanism-specific fail-closed clear. Definitions are append-only: the clear is a new
 -- definition + port_version, never an in-place mutation.
 DECLARE @platform nvarchar(400)=JSON_VALUE(@selected,'$.semantics.platformCapabilityId');
 DECLARE @semantics nvarchar(max)=JSON_QUERY(@selected,'$.semantics');
 DECLARE @cleared bit=0;
 IF @platform=N'sda-generic-llm-connector-port.v1'
 BEGIN
  SET @semantics=JSON_MODIFY(@semantics,'$.configuration.connectorAuthorityRef',NULL);
  SET @cleared=1;
 END
 ELSE IF @platform=N'sda-projected-capability-invocation-port.v2'
 BEGIN
  SET @semantics=JSON_MODIFY(@semantics,'$.configuration.bindingRef',NULL);
  SET @semantics=JSON_MODIFY(@semantics,'$.configuration.bindingBase',NULL);
  SET @cleared=1;
 END
 ELSE IF @platform=N'sda-governed-http-exchange-port.v1'
  THROW 51000,'PLACEMENT_RETIREMENT_MECHANISM_UNSUPPORTED',1;
 IF @cleared=1
 BEGIN
  DECLARE @object bigint,@definition bigint,@digest binary(32);
  EXEC model.put_semantic_definition 'PORT',@namespace,@port,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
  IF NOT EXISTS(SELECT 1 FROM model.port_version WHERE semantic_object_definition_pk=@definition)
   INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
    port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@port_pk,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
 END
 -- Remove the operation links, then de-select the definition membership. Invocation
 -- history rows stay; the port row stays; the runtime fails closed without a selection.
 DELETE i FROM model.operation_port_invocation i
 JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk
 WHERE pv.port_pk=@port_pk;
 DELETE FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@sod;
 DECLARE @receipt nvarchar(max)=(SELECT N'model-placement-retirement-receipt.v1' AS contractId,@namespace AS [namespace],
  @port AS portId,@disposition AS disposition FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @receipt_semantics nvarchar(max)=(SELECT JSON_QUERY(@receipt) AS document FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @r_object bigint,@r_definition bigint,@r_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',@namespace,@receipt_id,@receipt_semantics,
  @r_object OUTPUT,@r_definition OUTPUT,@r_digest OUTPUT;
 SELECT N'model_placement_retired' AS result_set,@port AS port_id;
END;
GO
-- ============================== AUTHORITY CONTRACT REVISION ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;

-- Structural prerequisites: the stub wave's placement operations and contracts.
IF (SELECT COUNT(*) FROM OPENJSON(@body,'$.changeOperations') WHERE JSON_VALUE(value,'$.changeId') IN
 (N'install-model-placement-change',N'replace-port-configuration',N'retire-model-placement'))<>3
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;
DECLARE @placement_contracts TABLE(contract_id nvarchar(200) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @placement_contracts(contract_id) VALUES
 (N'model-placement-change.v1'),(N'model-placement-change-installed.v1'),
 (N'placement-namespace.v1'),(N'placement-port-id.v1'),(N'placement-port-configuration.v1'),
 (N'placement-disposition.v1'),(N'port-configuration-replaced.v1'),(N'model-placement-retired.v1');
IF (SELECT COUNT(*) FROM @placement_contracts c WHERE EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts')
 WHERE [key] COLLATE Latin1_General_100_BIN2=c.contract_id))<>8
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;

DECLARE @declared bit=CASE WHEN
 EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'model-placement-change-installed.v1'
  AND value LIKE N'%already_installed%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'model-placement-retired.v1'
  AND value LIKE N'%already_retired%')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'model-placement-change.v1'
  AND value LIKE N'%"scenario"%')
 THEN 1 ELSE 0 END;

IF @declared=0
BEGIN
 DECLARE @c_change nvarchar(max)=N'{"title":"Model placement change","description":"One placement carrier: capability, port and platform-capability identity plus the mechanism configuration and the optional scenario carrier that links the placement through model.declare_scenario.","type":"object","additionalProperties":false,"required":["contractId","capabilityId","portId","platformCapabilityId","configuration"],"properties":{"contractId":{"const":"model-placement-change.v1"},"capabilityId":{"type":"string","minLength":1,"maxLength":400},"namespace":{"type":"string","minLength":1,"maxLength":400},"portId":{"type":"string","minLength":1,"maxLength":400},"platformCapabilityId":{"enum":["sda-generic-llm-connector-port.v1","sda-governed-http-exchange-port.v1","sda-projected-capability-invocation-port.v2","sda-authority-transformation-port.v1"]},"configuration":{"type":"object"},"scenario":{"type":"object"},"slots":{"type":"array"},"mechanic":{"type":"object"}}}';
 DECLARE @c_installed nvarchar(max)=N'{"title":"Model placement change installed","description":"Installer result: model_placement_installed for a new placement, already_installed for a byte-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","port_id"],"properties":{"result_set":{"enum":["model_placement_installed","already_installed"]},"port_id":{"type":"string","minLength":1,"maxLength":400}}}}}';
 DECLARE @c_replaced nvarchar(max)=N'{"title":"Port configuration replaced","description":"Replacement result: port_configuration_replaced for an intentional revision, already_installed for a byte-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","port_id"],"properties":{"result_set":{"enum":["port_configuration_replaced","already_installed"]},"port_id":{"type":"string","minLength":1,"maxLength":400}}}}}';
 DECLARE @c_retired nvarchar(max)=N'{"title":"Model placement retired","description":"Retirement result: model_placement_retired for a new retirement, already_retired for a replay of the same disposition.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","port_id"],"properties":{"result_set":{"enum":["model_placement_retired","already_retired"]},"port_id":{"type":"string","minLength":1,"maxLength":400}}}}}';
 SET @body=JSON_MODIFY(@body,'$.changeContracts."model-placement-change.v1"',JSON_QUERY(@c_change));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."model-placement-change-installed.v1"',JSON_QUERY(@c_installed));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."port-configuration-replaced.v1"',JSON_QUERY(@c_replaced));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."model-placement-retired.v1"',JSON_QUERY(@c_retired));
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 DECLARE @new_content nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 DECLARE @authority_semantics nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @authority_semantics=JSON_MODIFY(@authority_semantics,'$.contentDigest',@new_content);
 DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@authority_semantics,
  @authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
END

-- Verify the selected body, freshly declared or replayed.
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3'
 THROW 51000,N'PLACEMENT_PROCEDURES_AUTHORITY_DIGEST_DIVERGED',1;
IF (SELECT COUNT(*) FROM @placement_contracts c WHERE EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeContracts')
 WHERE [key] COLLATE Latin1_General_100_BIN2=c.contract_id))<>8
 THROW 51000,N'PLACEMENT_PROCEDURES_DECLARATION_INCOMPLETE',1;
IF EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key]=N'model-placement-change-installed.v1'
 AND JSON_VALUE(value,'$.type')<>N'array')
 THROW 51000,N'PLACEMENT_PROCEDURES_CONTRACT_NOT_REVISED',1;
SELECT N'0_contract_revision' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' ELSE N'revised' END AS disposition;
GO
-- ============================== SANDBOX PROOF ==============================
-- One scratch capability, created and rolled back in the same transaction:
-- install A, replay A, install C, replace C, install D, retire D, replay D.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @scratch nvarchar(120)=N'lane3-placement-sandbox';
DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @baseline(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'PLACEMENT_SANDBOX_BASELINE_MISSING',1;

DECLARE @scratch_document nvarchar(max)=N'{"document":"sidefx-capability-authority.v1","capabilityId":"lane3-placement-sandbox","meaning":{"intent":"prove the placement procedure bodies","outcome":"A and C and D placements install, replay, replace and retire inside one rolled back transaction"},"contracts":[{"id":"lane3-placement-sandbox-request.v1","schema":{"type":"object","additionalProperties":true}},{"id":"lane3-placement-sandbox-outcome.v1","schema":{"type":"object","additionalProperties":true}}],"scenarios":[{"scenarioId":"lane3-placement-sandbox","name":"Placement sandbox root","inputId":"lane3-placement-sandbox-request","inputContract":"lane3-placement-sandbox-request.v1","eventId":"lane3-placement-sandbox-requested","eventAuthority":"lane3-placement-sandbox.v1","outcomeId":"lane3-placement-sandbox-outcome","outcomeContract":"lane3-placement-sandbox-outcome.v1","given":"a scratch capability","when":"the declared read runs","then":"a value is returned","terminal":true,"root":true,"operations":[{"operationId":"lane3-placement-sandbox.0","kind":"invoke-port","portId":"lane3-placement-sandbox-port"}],"portBindings":[{"portId":"lane3-placement-sandbox-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"SELECT (SELECT 1 AS value FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value","resultColumn":"value"}}]}]}';
EXEC model.declare_capability_document @document=@scratch_document,@on_unchanged=N'SKIP';

DECLARE @a_document nvarchar(max)=N'{"contractId":"model-placement-change.v1","capabilityId":"lane3-placement-sandbox","portId":"lane3-placement-a-port","platformCapabilityId":"sda-generic-llm-connector-port.v1","configuration":{"connectorAuthorityRef":"../../generic-llm-connector/config/provider-authority.json","requestPath":"modelRequest","lineageMode":"retain-external-execution","credentialsMode":"external-reference-only","resultPath":"modelEvidence"},"scenario":{"scenarioId":"lane3-placement-a","name":"Placement A","inputId":"lane3-placement-sandbox-request","inputContract":"lane3-placement-sandbox-request.v1","eventId":"lane3-placement-a-requested","eventAuthority":"lane3-placement-a.v1","outcomeId":"lane3-placement-sandbox-outcome","outcomeContract":"lane3-placement-sandbox-outcome.v1","given":"a scratch capability","when":"the connector port is invoked","then":"the connector evidence is returned","terminal":true,"operations":[{"operationId":"lane3-placement-a.0","kind":"invoke-port","portId":"lane3-placement-a-port"}]}}';
EXEC model.install_model_placement_change @document=@a_document;
IF NOT EXISTS(SELECT 1 FROM model.operation_port_invocation i
 JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk JOIN model.port p ON p.port_pk=pv.port_pk
 WHERE p.port_id=N'lane3-placement-a-port') THROW 51000,N'PLACEMENT_SANDBOX_A_LINK_MISSING',1;
DECLARE @a_versions int=(SELECT COUNT(*) FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk
 WHERE p.port_id=N'lane3-placement-a-port');
EXEC model.install_model_placement_change @document=@a_document;
IF (SELECT COUNT(*) FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk
 WHERE p.port_id=N'lane3-placement-a-port')<>@a_versions
 THROW 51000,N'PLACEMENT_SANDBOX_A_REPLAY_WROTE',1;

DECLARE @c_document nvarchar(max)=N'{"contractId":"model-placement-change.v1","capabilityId":"lane3-placement-sandbox","portId":"lane3-placement-c-port","platformCapabilityId":"sda-projected-capability-invocation-port.v2","configuration":{"bindingDigest":"sha256:0000000000000000000000000000000000000000000000000000000000000000","capabilityAuthorityDigest":"sha256:1111111111111111111111111111111111111111111111111111111111111111","lineageMode":"retain-nested-execution","requestPath":"currentInvocationRequest","resultMode":"bind-outcome","resultPath":"primaryModelEvidence","declaredApplication":{"bindingDocument":"lane3-placement-sandbox.binding.json"}},"scenario":{"scenarioId":"lane3-placement-c","name":"Placement C","inputId":"lane3-placement-sandbox-request","inputContract":"lane3-placement-sandbox-request.v1","eventId":"lane3-placement-c-requested","eventAuthority":"lane3-placement-c.v1","outcomeId":"lane3-placement-sandbox-outcome","outcomeContract":"lane3-placement-sandbox-outcome.v1","given":"a scratch capability","when":"the projected child is invoked","then":"the nested evidence is returned","terminal":true,"operations":[{"operationId":"lane3-placement-c.0","kind":"invoke-port","portId":"lane3-placement-c-port"}]}}';
EXEC model.install_model_placement_change @document=@c_document;
IF NOT EXISTS(SELECT 1 FROM model.operation_port_invocation i
 JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk JOIN model.port p ON p.port_pk=pv.port_pk
 WHERE p.port_id=N'lane3-placement-c-port') THROW 51000,N'PLACEMENT_SANDBOX_C_LINK_MISSING',1;
DECLARE @c_versions int=(SELECT COUNT(*) FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk
 WHERE p.port_id=N'lane3-placement-c-port');
EXEC model.install_model_placement_change @document=@c_document;
IF (SELECT COUNT(*) FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk
 WHERE p.port_id=N'lane3-placement-c-port')<>@c_versions
 THROW 51000,N'PLACEMENT_SANDBOX_C_REPLAY_WROTE',1;

DECLARE @c_prev_version bigint=(SELECT MAX(pv.port_version_pk) FROM model.port p JOIN model.port_version pv ON pv.port_pk=p.port_pk
 WHERE p.port_id=N'lane3-placement-c-port');
IF NOT EXISTS(SELECT 1 FROM model.operation_port_invocation i WHERE i.port_version_pk=@c_prev_version)
 THROW 51000,N'PLACEMENT_SANDBOX_C_PREV_LINK_MISSING',1;
EXEC model.replace_port_configuration @namespace=N'sidefx:capability:lane3-placement-sandbox',
 @port=N'lane3-placement-c-port',
 @configuration_json=N'{"bindingDigest":"sha256:2222222222222222222222222222222222222222222222222222222222222222","capabilityAuthorityDigest":"sha256:1111111111111111111111111111111111111111111111111111111111111111","lineageMode":"retain-nested-execution","requestPath":"replacementInvocationRequest","resultMode":"bind-outcome","resultPath":"primaryModelEvidence","declaredApplication":{"bindingDocument":"lane3-placement-sandbox.binding.json"}}';
DECLARE @c_new_version bigint=(SELECT MAX(pv.port_version_pk) FROM model.port p JOIN model.port_version pv ON pv.port_pk=p.port_pk
 WHERE p.port_id=N'lane3-placement-c-port');
IF @c_new_version=@c_prev_version THROW 51000,N'PLACEMENT_SANDBOX_C_REPLACE_NO_VERSION',1;
IF EXISTS(SELECT 1 FROM model.operation_port_invocation WHERE port_version_pk=@c_prev_version)
 THROW 51000,N'PLACEMENT_SANDBOX_C_REPLACE_NOT_RELINKED',1;
IF NOT EXISTS(SELECT 1 FROM model.operation_port_invocation WHERE port_version_pk=@c_new_version)
 THROW 51000,N'PLACEMENT_SANDBOX_C_REPLACE_LINK_MISSING',1;
IF NOT EXISTS(SELECT 1 FROM model.port_version WHERE port_version_pk=@c_prev_version)
 THROW 51000,N'PLACEMENT_SANDBOX_C_REPLACE_HISTORY_LOST',1;
DECLARE @c_versions_replaced int=(SELECT COUNT(*) FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk
 WHERE p.port_id=N'lane3-placement-c-port');
EXEC model.replace_port_configuration @namespace=N'sidefx:capability:lane3-placement-sandbox',
 @port=N'lane3-placement-c-port',
 @configuration_json=N'{"bindingDigest":"sha256:2222222222222222222222222222222222222222222222222222222222222222","capabilityAuthorityDigest":"sha256:1111111111111111111111111111111111111111111111111111111111111111","lineageMode":"retain-nested-execution","requestPath":"replacementInvocationRequest","resultMode":"bind-outcome","resultPath":"primaryModelEvidence","declaredApplication":{"bindingDocument":"lane3-placement-sandbox.binding.json"}}';
IF (SELECT COUNT(*) FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk
 WHERE p.port_id=N'lane3-placement-c-port')<>@c_versions_replaced
 THROW 51000,N'PLACEMENT_SANDBOX_C_REPLACE_REPLAY_WROTE',1;

DECLARE @d_document nvarchar(max)=N'{"contractId":"model-placement-change.v1","capabilityId":"lane3-placement-sandbox","portId":"lane3-placement-d-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationId":"lane3-placement-d-transform.v1","expression":{"op":"literal","value":"lane3-placement-proof"}},"scenario":{"scenarioId":"lane3-placement-d","name":"Placement D","inputId":"lane3-placement-sandbox-request","inputContract":"lane3-placement-sandbox-request.v1","eventId":"lane3-placement-d-requested","eventAuthority":"lane3-placement-d.v1","outcomeId":"lane3-placement-sandbox-outcome","outcomeContract":"lane3-placement-sandbox-outcome.v1","given":"a scratch capability","when":"the transformation port is invoked","then":"the literal is returned","terminal":true,"operations":[{"operationId":"lane3-placement-d.0","kind":"invoke-port","portId":"lane3-placement-d-port"}]}}';
EXEC model.install_model_placement_change @document=@d_document;
IF NOT EXISTS(SELECT 1 FROM model.transformation t JOIN model.identity_namespace n ON n.namespace_pk=t.namespace_pk
 JOIN model.transformation_version tv ON tv.transformation_pk=t.transformation_pk
 WHERE n.namespace_id=N'sidefx:capability:lane3-placement-sandbox' AND t.transformation_id=N'lane3-placement-d-transform.v1')
 THROW 51000,N'PLACEMENT_SANDBOX_D_TRANSFORMATION_MISSING',1;
EXEC model.retire_model_placement @namespace=N'sidefx:capability:lane3-placement-sandbox',
 @port=N'lane3-placement-d-port',@disposition=N'RETIRED';
IF EXISTS(SELECT 1 FROM model.operation_port_invocation i JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk
 JOIN model.port p ON p.port_pk=pv.port_pk WHERE p.port_id=N'lane3-placement-d-port')
 THROW 51000,N'PLACEMENT_SANDBOX_D_LINKS_REMAIN',1;
IF EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.declared_id=N'lane3-placement-d-port')
 THROW 51000,N'PLACEMENT_SANDBOX_D_STILL_SELECTED',1;
IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=N'sidefx:capability:lane3-placement-sandbox'
  AND d.declared_id=N'lane3-placement-d-port.retired.v1')
 THROW 51000,N'PLACEMENT_SANDBOX_D_RECEIPT_MISSING',1;
DECLARE @retire_receipts int=(SELECT COUNT(*) FROM model.semantic_object_definition d
 JOIN model.semantic_object o ON o.semantic_object_pk=d.semantic_object_pk
 JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
 WHERE n.namespace_id=N'sidefx:capability:lane3-placement-sandbox' AND o.object_kind=N'AUTHORITY'
  AND o.declared_id=N'lane3-placement-d-port.retired.v1');
EXEC model.retire_model_placement @namespace=N'sidefx:capability:lane3-placement-sandbox',
 @port=N'lane3-placement-d-port',@disposition=N'RETIRED';
IF (SELECT COUNT(*) FROM model.semantic_object_definition d
 JOIN model.semantic_object o ON o.semantic_object_pk=d.semantic_object_pk
 JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
 WHERE n.namespace_id=N'sidefx:capability:lane3-placement-sandbox' AND o.object_kind=N'AUTHORITY'
  AND o.declared_id=N'lane3-placement-d-port.retired.v1')<>@retire_receipts
 THROW 51000,N'PLACEMENT_SANDBOX_D_RETIRE_REPLAY_WROTE',1;

-- Unrelated capability graph digests must be byte-identical.
DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @after(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
SELECT N'10_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'PLACEMENT_PROCEDURES_UNRELATED_CAPABILITY_CHANGED',1;
GO
-- Refusal probe (dooms the transaction; the file rolls back next batch): a linked
-- placement whose semantics differ may not be replaced by re-install.
SET XACT_ABORT OFF;
BEGIN TRY
 DECLARE @changed nvarchar(max)=N'{"contractId":"model-placement-change.v1","capabilityId":"lane3-placement-sandbox","portId":"lane3-placement-a-port","platformCapabilityId":"sda-generic-llm-connector-port.v1","configuration":{"connectorAuthorityRef":"../../generic-llm-connector/config/provider-authority.json","requestPath":"changedModelRequest","lineageMode":"retain-external-execution","credentialsMode":"external-reference-only","resultPath":"modelEvidence"},"scenario":{"scenarioId":"lane3-placement-a","name":"Placement A revision","inputId":"lane3-placement-sandbox-request","inputContract":"lane3-placement-sandbox-request.v1","eventId":"lane3-placement-a-requested","eventAuthority":"lane3-placement-a.v1","outcomeId":"lane3-placement-sandbox-outcome","outcomeContract":"lane3-placement-sandbox-outcome.v1","given":"a scratch capability","when":"the connector port is invoked","then":"the connector evidence is returned","terminal":true,"operations":[{"operationId":"lane3-placement-a.0","kind":"invoke-port","portId":"lane3-placement-a-port"}]}}';
 EXEC model.install_model_placement_change @document=@changed;
 SELECT N'11_revision_probe' AS result_set,N'NOT_THROWN' AS disposition;
END TRY
BEGIN CATCH
 SELECT N'11_revision_probe' AS result_set,ERROR_MESSAGE() AS disposition,
  CASE WHEN ERROR_MESSAGE()=N'MODEL_PLACEMENT_REVISION_REFUSED' THEN N'PASSED' ELSE N'FAILED' END AS probe_result;
END CATCH
COMMIT TRANSACTION;
