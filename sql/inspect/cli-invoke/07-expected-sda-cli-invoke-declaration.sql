-- 07-expected-sda-cli-invoke-declaration.sql
--
-- Proves, as read-only assertions, the exact declaration rows a corrected
-- sda-cli-invoke must carry for the request-named invocation to run, and which
-- of them the live selected state already has:
--
--   * operation model.execution_operation.operation_kind = 'invoke-port' inside
--     selected capability version 1161266, whose scenario event authority is
--     bound (model.operation_port_invocation) to port_version_pk 4387 of
--     sda-cli-invoke-port -> MISSING (the selected version carries only
--     invoke-scenario operations; the retained invoke-port operation lives on
--     unselected versions 1161234 / 1161235);
--   * the port declaration members of selected definition 211571
--     (platformCapabilityId sda-node-consumer-runtime.v1 + configuration
--     providerId / authoritySource / capabilityIdPath / requestPath /
--     namespacePath / scenarioPath / resultPath / lineageMode) -> PRESENT, all
--     members equal to the expected literals;
--   * provider link ScenarioKernel.NodePlatform -> sda-node-consumer-runtime.v1
--     role PLATFORM -> PRESENT; overlay binding for mechanic
--     sda-node-consumer-runtime.v1 on run-declared-graph-execute -> PRESENT;
--   * provider profile node:provider:sda-node-consumer-runtime.v1 referenced by
--     that overlay rule -> no declaration row in model.provider_profile
--     (UNPROVEN whether the runtime requires one; the rule carries the digest of
--     the selected provider definition instead).
--
-- No writes: expectations are table variables and the final assertions are
-- SELECTs over live rows.
SET NOCOUNT ON;
BEGIN TRANSACTION;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability_version bigint=(SELECT ec.capability_version_pk
  FROM model.capability c
  JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_pk=c.capability_pk
  WHERE c.capability_id=N'sda-cli-invoke');

DECLARE @expected_operation TABLE(
  capability_version_pk bigint, scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  operation_kind varchar(64) COLLATE Latin1_General_100_BIN2, port_version_pk bigint);
INSERT @expected_operation(capability_version_pk, scenario_id, operation_kind, port_version_pk)
VALUES (@capability_version, N'sda-cli-invoke', N'invoke-port', 4387);

SELECT 'expected_operation_rows' AS result_set, capability_version_pk, scenario_id, operation_kind, port_version_pk
FROM @expected_operation;

WITH actual_operations AS (
  SELECT ec.capability_version_pk, s.scenario_id, eo.operation_kind, opi.port_version_pk
  FROM model.capability c
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
  JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_pk=c.capability_pk
  JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
  JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
  JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
  JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
  LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
  WHERE c.capability_id=N'sda-cli-invoke' AND eo.operation_kind=N'invoke-port'
)
SELECT 'missing_operation_rows' AS result_set, e.capability_version_pk, e.scenario_id, e.operation_kind, e.port_version_pk
FROM @expected_operation e
WHERE NOT EXISTS (
  SELECT 1 FROM actual_operations a
  WHERE a.capability_version_pk=e.capability_version_pk AND a.scenario_id=e.scenario_id
    AND a.operation_kind=e.operation_kind AND a.port_version_pk=e.port_version_pk);

WITH actual_operations AS (
  SELECT ec.capability_version_pk, s.scenario_id, eo.operation_kind, opi.port_version_pk
  FROM model.capability c
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
  JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_pk=c.capability_pk
  JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
  JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
  JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
  JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
  LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
  WHERE c.capability_id=N'sda-cli-invoke' AND eo.operation_kind=N'invoke-port'
)
SELECT 'unexpected_operation_rows' AS result_set, a.capability_version_pk, a.scenario_id, a.operation_kind, a.port_version_pk
FROM actual_operations a
WHERE NOT EXISTS (
  SELECT 1 FROM @expected_operation e
  WHERE e.capability_version_pk=a.capability_version_pk AND e.scenario_id=a.scenario_id
    AND e.operation_kind=a.operation_kind AND e.port_version_pk=a.port_version_pk);

DECLARE @expected_member TABLE(ordinal int IDENTITY, member_name nvarchar(200), expected_value nvarchar(400));
INSERT @expected_member(member_name, expected_value) VALUES
 (N'platformCapabilityId', N'sda-node-consumer-runtime.v1'),
 (N'configuration.providerId', N'ScenarioKernel.NodePlatform'),
 (N'configuration.authoritySource', N'DATABASE'),
 (N'configuration.capabilityIdPath', N'capabilityId'),
 (N'configuration.requestPath', N'input'),
 (N'configuration.namespacePath', N'namespace'),
 (N'configuration.scenarioPath', N'scenario'),
 (N'configuration.resultPath', N'result'),
 (N'configuration.lineageMode', N'retain-nested-execution');

SELECT 'expected_port_member_assertions' AS result_set, e.member_name, e.expected_value,
  CASE e.member_name
    WHEN N'platformCapabilityId' THEN JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId')
    WHEN N'configuration.providerId' THEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.providerId')
    WHEN N'configuration.authoritySource' THEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.authoritySource')
    WHEN N'configuration.capabilityIdPath' THEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.capabilityIdPath')
    WHEN N'configuration.requestPath' THEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.requestPath')
    WHEN N'configuration.namespacePath' THEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.namespacePath')
    WHEN N'configuration.scenarioPath' THEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.scenarioPath')
    WHEN N'configuration.resultPath' THEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.resultPath')
    WHEN N'configuration.lineageMode' THEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.lineageMode')
  END AS actual_value
FROM @expected_member e
CROSS JOIN analysis.v_selected_semantic_definition sd
WHERE sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
  AND sd.namespace_id=N'sidefx:capability:sda-cli-invoke' AND sd.declared_id=N'sda-cli-invoke-port';

SELECT 'expected_supporting_assertions' AS result_set, a.declaration_member, a.status, a.evidence
FROM (
  SELECT N'provider_capability_implementation(ScenarioKernel.NodePlatform -> sda-node-consumer-runtime.v1, role PLATFORM)' AS declaration_member,
    CASE WHEN EXISTS (
      SELECT 1 FROM model.provider_capability_implementation pci
      JOIN model.capability_version cv ON cv.capability_version_pk=pci.capability_version_pk
      JOIN model.capability c ON c.capability_pk=cv.capability_pk AND c.capability_id=N'sda-node-consumer-runtime.v1'
      JOIN model.provider_definition pd ON pd.provider_definition_pk=pci.provider_definition_pk
      JOIN model.provider p ON p.provider_pk=pd.provider_pk AND p.provider_id=N'ScenarioKernel.NodePlatform'
      WHERE pci.role=N'PLATFORM') THEN N'PRESENT' ELSE N'MISSING' END AS status,
    CONVERT(nvarchar(200),N'table 04; capability_version_pk 150558') AS evidence
  UNION ALL
  SELECT N'overlay_binding(run-declared-graph-execute, mechanicId sda-node-consumer-runtime.v1)',
    CASE WHEN EXISTS (
      SELECT 1 FROM analysis.v_selected_semantic_definition sd
      JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=sd.semantic_object_definition_pk
      JOIN model.semantic_object so ON so.semantic_object_pk=sod.semantic_object_pk AND so.declared_id=N'run-declared-graph-execute'
      CROSS APPLY OPENJSON(JSON_QUERY(sd.definition_json,'$.semantics.configuration.overlayBindings')) b
      WHERE sd.estate_model_pk=@estate AND JSON_VALUE(b.value,'$.mechanicId')=N'sda-node-consumer-runtime.v1') THEN N'PRESENT' ELSE N'MISSING' END,
    CONVERT(nvarchar(200),N'table 04; providerProfileId node:provider:sda-node-consumer-runtime.v1')
  UNION ALL
  SELECT N'provider_profile(node:provider:sda-node-consumer-runtime.v1)',
    CASE WHEN EXISTS (SELECT 1 FROM model.provider_profile pp
      WHERE pp.provider_profile_id=N'node:provider:sda-node-consumer-runtime.v1') THEN N'PRESENT' ELSE N'MISSING' END,
    CONVERT(nvarchar(200),N'count 0 in model.provider_profile; UNPROVEN whether required')
) a;

ROLLBACK TRANSACTION;
