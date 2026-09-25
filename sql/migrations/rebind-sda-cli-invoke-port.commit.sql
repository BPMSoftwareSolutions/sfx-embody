-- Rebind sda-cli-invoke-port to the request-driven consumer-runtime boundary.
--
-- The port is the invoke wrapper's only operation. The named target lives in the
-- carrier (`{"capabilityId":"<capability>"}`), so the boundary must read the
-- target from the request. The live request-driven boundary is the consumer
-- runtime: platformCapabilityId `sda-node-consumer-runtime.v1`, provider
-- `ScenarioKernel.NodePlatform` (model.provider provider_pk 6, latest
-- provider_definition_pk 147), whose declared mechanics include
-- `scenario-invocation`; live precedents that take their target from the carrier
-- are `execute-bound-consumer-plan` / `execute-declared-capability-port`
-- (sidefx:capability:execute-declared-capability) and `run-pilot-container-port`
-- (config `{}`). The v2 projected boundary is deliberately not used: every
-- invocation-carrying v2 port pins `declaredApplication`, which cannot name the
-- carrier's target.
--
-- Two rows change:
--   1. `run-declared-graph-execute` (the host execution port every CLI
--      invocation runs through) gains the overlay binding rule that selects the
--      consumer-runtime profile for mechanicId `sda-node-consumer-runtime.v1`.
--      Without it the compile-time overlay refuses
--      SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING.
--   2. `sda-cli-invoke-port` is rebound through model.bind_provider, with the
--      carrier contract the provider must consume.
--
-- Remaining gap (next unit, not declared here): the installed kernel's
-- `kernel/semantic-authority/consumer/csharp-mechanic-registry.authority.v1.json`
-- has no scheduler provider profile `node:provider:sda-node-consumer-runtime.v1`
-- / `csharp:provider:sda-node-consumer-runtime.v1`, so the scheduler refuses
-- PROVIDER_BINDING_DIVERGENCE for the profile. Registering the profile and its
-- provider body (the request-driven invocation factory) is a kernel authority
-- change, not a model row.
--
-- Idempotent: a replay finds the overlay rule and the port semantics already
-- installed and mints no definition or port version.
--
-- COMMIT twin of rebind-sda-cli-invoke-port.sql; installs the rebind.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=N'sda-cli-invoke')
 THROW 51000,'CAPABILITY_NOT_FOUND',1;
GO
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @namespace nvarchar(400) = N'sidefx:capability:run-declared-graph';
DECLARE @port nvarchar(400) = N'run-declared-graph-execute';
DECLARE @mechanic nvarchar(400) = N'sda-node-consumer-runtime.v1';
DECLARE @profile nvarchar(400) = N'node:provider:sda-node-consumer-runtime.v1';
DECLARE @profile_digest nvarchar(80) = N'sha256:8261f0415f6883d83758508dff469930801b81d0734b217f98caeb2d04afb226';
DECLARE @implementation_ref nvarchar(400) = N'languages/typescript/runtimes/node/admitted-consumer-platform.mjs';
DECLARE @semantics nvarchar(max), @prevver bigint;
SELECT @semantics = JSON_QUERY(d.definition_json, '$.semantics'),
  @prevver = (SELECT pv.port_version_pk FROM model.port_version pv
              WHERE pv.semantic_object_definition_pk = d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND d.namespace_id = @namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id = @port COLLATE Latin1_General_100_BIN2;
IF @semantics IS NULL OR @prevver IS NULL THROW 51000, 'RUN_DECLARED_GRAPH_EXECUTE_PORT_MISSING', 1;
IF EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
           WHERE JSON_VALUE(b.value, '$.mechanicId') = @mechanic COLLATE Latin1_General_100_BIN2
             AND JSON_VALUE(b.value, '$.providerProfileId') <> @profile COLLATE Latin1_General_100_BIN2)
 THROW 51000, 'OVERLAY_RULE_PROFILE_CONFLICT', 1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
               WHERE JSON_VALUE(b.value, '$.mechanicId') = @mechanic COLLATE Latin1_General_100_BIN2
                 AND JSON_VALUE(b.value, '$.providerProfileId') = @profile COLLATE Latin1_General_100_BIN2
                 AND JSON_VALUE(b.value, '$.providerProfileDigest') = @profile_digest COLLATE Latin1_General_100_BIN2
                 AND JSON_VALUE(b.value, '$.implementationRef') = @implementation_ref COLLATE Latin1_General_100_BIN2)
BEGIN
  DECLARE @with_rule nvarchar(max) = (
    SELECT mechanicId, providerProfileId, providerProfileDigest, implementationRef
    FROM (
      SELECT JSON_VALUE(b.value, '$.mechanicId') AS mechanicId,
             JSON_VALUE(b.value, '$.providerProfileId') AS providerProfileId,
             JSON_VALUE(b.value, '$.providerProfileDigest') AS providerProfileDigest,
             JSON_VALUE(b.value, '$.implementationRef') AS implementationRef,
             0 AS source_rank, CONVERT(bigint, b.[key]) AS sort_key
      FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
      WHERE JSON_VALUE(b.value, '$.mechanicId') <> @mechanic COLLATE Latin1_General_100_BIN2
      UNION ALL
      SELECT @mechanic, @profile, @profile_digest, @implementation_ref, 1, NULL
    ) combined
    ORDER BY source_rank, sort_key, mechanicId
    FOR JSON PATH);
  SET @semantics = JSON_MODIFY(@semantics, '$.configuration.overlayBindings', JSON_QUERY(@with_rule));
  DECLARE @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;
  EXEC model.put_semantic_definition 'PORT', @namespace, @port, @semantics,
    @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
  SET @portpk = (SELECT port_pk FROM model.port WHERE semantic_object_pk = @object);
  IF @portpk IS NULL THROW 51000, 'RUN_DECLARED_GRAPH_EXECUTE_PORT_ROW_MISSING', 1;
  SET @version = (SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk = @definition);
  IF @version IS NULL BEGIN
    INSERT model.port_version(port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest,
      port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES(@portpk, @object, @definition, @digest, 'consumer-interface-authority.v1', 'PORT', @definition, N'');
    SET @version = SCOPE_IDENTITY();
  END
  UPDATE model.operation_port_invocation SET port_version_pk = @version WHERE port_version_pk = @prevver;
END
GO
EXEC model.bind_provider
 @capability_id=N'sda-cli-invoke',
 @mechanic_id=N'sda-cli-invoke-port',
 @provider_id=N'ScenarioKernel.NodePlatform',
 @platform_capability_id=N'sda-node-consumer-runtime.v1',
 @configuration_json=N'{"authoritySource":"DATABASE","inputAdmission":{"type":"object","required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1},"inputType":{"type":"string"},"input":{},"namespace":{"type":"string","minLength":1},"scenario":{"type":"string","minLength":1}}},"capabilityIdPath":"capabilityId","requestPath":"input","namespacePath":"namespace","scenarioPath":"scenario","resultPath":"result","lineageMode":"retain-nested-execution"}';
GO
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
SELECT 'rebind_sda_cli_invoke_port' AS result_set,
 c.capability_id, c.capability_pk, ec.capability_version_pk, ec.semantic_object_definition_pk,
 s.scenario_id, eo.operation_id, opi.port_version_pk AS invocation_port_version_pk,
 p.port_id, n.namespace_id, pv.port_version_pk,
 JSON_VALUE(dt.text,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_QUERY(dt.text,'$.semantics.configuration') AS configuration
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=N'sda-cli-invoke'
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
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
SELECT 'run_declared_graph_execute_overlay' AS result_set, p.port_id, pv.port_version_pk,
 COUNT(*) AS overlay_rule_count,
 SUM(CASE WHEN JSON_VALUE(b.value,'$.mechanicId')=N'sda-node-consumer-runtime.v1' THEN 1 ELSE 0 END) AS consumer_runtime_rules,
 MAX(CASE WHEN JSON_VALUE(b.value,'$.mechanicId')=N'sda-node-consumer-runtime.v1'
   THEN JSON_VALUE(b.value,'$.providerProfileId') END) AS consumer_runtime_profile
FROM model.port p
JOIN model.port_version pv ON pv.port_pk=p.port_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dt
CROSS APPLY OPENJSON(JSON_QUERY(dt.text,'$.semantics.configuration.overlayBindings')) b
WHERE p.port_id=N'run-declared-graph-execute'
  AND pv.port_version_pk=(SELECT MAX(pv2.port_version_pk) FROM model.port_version pv2 WHERE pv2.port_pk=p.port_pk)
GROUP BY p.port_id, pv.port_version_pk;
COMMIT TRANSACTION;
