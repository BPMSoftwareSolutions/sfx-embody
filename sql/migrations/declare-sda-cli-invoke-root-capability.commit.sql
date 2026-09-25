-- Declares the sda-cli-invoke root capability: the installed CLI ignores
-- --scenario and executes the selected capability's ROOT scenario, so the
-- invoke graph must own a capability of its own. The root scenario is
-- `invoke` (input sda-cli-invoke-request.v1, event sda-cli-invoke-requested /
-- authority sda-cli-invoke.v1, terminal outcome sda-cli-invoke-result.v1)
-- with one invoke-port operation bound to sda-projected-capability-invocation-port.v2.
-- Pass-through JSON CLI input: $.semantics.cli declares input {type:json} with
-- no contract and no path, so the kernel admits the parsed input verbatim.
-- Recipe: scaffold_capability (isolated scaffold contracts) -> declare_contract
-- -> declare_scenario -> configure_interface; the explicit $schema on the
-- invoke contracts gives them a superseding definition, so the admitted invoke
-- schema is the selected one even where an earlier generic declaration shadows it.
-- Idempotent: the block is skipped when the selected capability already carries
-- the invoke root scenario, the pass-through JSON CLI interface, the admitted
-- invoke contracts and the projected-capability-invocation port binding.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @cap_pk bigint=(SELECT c.capability_pk FROM model.capability c
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 WHERE c.capability_id=N'sda-cli-invoke');
IF @cap_pk IS NULL
  EXEC model.scaffold_capability @capability_id=N'sda-cli-invoke',
    @input_id=N'sda-cli-invoke-request', @input_contract=N'sda-cli-invoke-scaffold-request.v1',
    @outcome_id=N'sda-cli-invoke-result', @outcome_contract=N'sda-cli-invoke-scaffold-result.v1';
IF NOT EXISTS (
  SELECT 1 FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk=ec.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
  JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=ec.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
  CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS body) env
  WHERE ec.estate_model_pk=@estate AND c.capability_id=N'sda-cli-invoke'
    AND JSON_VALUE(env.body,'$.semantics.cli.input.type')=N'json'
    AND JSON_VALUE(env.body,'$.semantics.cli.input.contract') IS NULL
    AND JSON_VALUE(env.body,'$.semantics.cli.input.path') IS NULL
    AND EXISTS (SELECT 1 FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
      WHERE cs.capability_version_pk=ec.capability_version_pk AND s.scenario_id=N'invoke')
    AND EXISTS (SELECT 1 FROM model.capability_root_scenario crs JOIN model.scenario rs ON rs.scenario_pk=crs.scenario_pk
      WHERE crs.capability_version_pk=ec.capability_version_pk AND rs.scenario_id=N'invoke')
    AND EXISTS (SELECT 1
      FROM model.capability_scenario cs2
      JOIN model.scenario s2 ON s2.scenario_pk=cs2.scenario_pk AND s2.scenario_id=N'invoke'
      JOIN model.scenario_input si2 ON si2.scenario_version_pk=cs2.scenario_version_pk
      JOIN model.contract_version cv2 ON cv2.contract_version_pk=si2.input_contract_version_pk
      JOIN model.schema_object so2 ON so2.schema_object_pk=cv2.schema_object_pk
      JOIN source.content_object co2 ON co2.content_object_pk=so2.content_object_pk
      CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co2.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_text) st2
      WHERE cs2.capability_version_pk=ec.capability_version_pk
        AND JSON_QUERY(st2.schema_text,'$.required') LIKE N'%capabilityId%'
        AND JSON_VALUE(st2.schema_text,'$.additionalProperties')=N'false')
    AND EXISTS (SELECT 1
      FROM model.capability_scenario cs3
      JOIN model.scenario s3 ON s3.scenario_pk=cs3.scenario_pk AND s3.scenario_id=N'invoke'
      JOIN model.scenario_outcome_contract soc3 ON soc3.scenario_version_pk=cs3.scenario_version_pk
      JOIN model.contract_version cv3 ON cv3.contract_version_pk=soc3.contract_version_pk
      JOIN model.schema_object so3 ON so3.schema_object_pk=cv3.schema_object_pk
      JOIN source.content_object co3 ON co3.content_object_pk=so3.content_object_pk
      CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co3.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_text) st3
      WHERE cs3.capability_version_pk=ec.capability_version_pk
        AND JSON_QUERY(st3.schema_text,'$.required') LIKE N'%disposition%'
        AND JSON_VALUE(st3.schema_text,'$.additionalProperties')=N'false')
    AND EXISTS (SELECT 1
      FROM model.port p
      JOIN model.identity_namespace pn ON pn.namespace_pk=p.namespace_pk AND pn.namespace_id=N'sidefx:capability:sda-cli-invoke'
      JOIN model.semantic_object_definition pd ON pd.semantic_object_pk=p.semantic_object_pk
      JOIN source.content_object pco ON pco.content_object_pk=pd.canonical_content_pk
      CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),pco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS body) pv
      WHERE p.port_id=N'sda-cli-invoke-port'
        AND pd.semantic_object_definition_pk=(SELECT MAX(d4.semantic_object_definition_pk) FROM model.semantic_object_definition d4 WHERE d4.semantic_object_pk=p.semantic_object_pk)
        AND JSON_VALUE(pv.body,'$.semantics.platformCapabilityId')=N'sda-projected-capability-invocation-port.v2'))
BEGIN
  EXEC model.declare_contract @id=N'sda-cli-invoke-request.v1',
    @schema=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1},"inputType":{"type":"string","minLength":1},"input":{},"namespace":{"type":"string","minLength":1},"scenario":{"type":"string","minLength":1}}}';
  EXEC model.declare_contract @id=N'sda-cli-invoke-result.v1',
    @schema=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object","additionalProperties":false,"required":["capabilityId","disposition"],"properties":{"capabilityId":{"type":"string"},"disposition":{"type":"string"},"result":{}}}';
  EXEC model.declare_scenario @capability_id=N'sda-cli-invoke',
    @scenario=N'{"scenarioId":"invoke","name":"Invoke a declared capability","inputId":"sda-cli-invoke-request","inputContract":"sda-cli-invoke-request.v1","eventId":"sda-cli-invoke-requested","eventAuthority":"sda-cli-invoke.v1","outcomeId":"sda-cli-invoke-result","outcomeContract":"sda-cli-invoke-result.v1","terminal":true,"root":true,"given":"one declared capability identity and admitted input","when":"the CLI invoke carrier runs the selected capability","then":"the declared scenario output is delivered"}',
    @operations=N'[{"operationId":"sda-cli-invoke.0","kind":"invoke-port","portId":"sda-cli-invoke-port"}]',
    @port_bindings=N'[{"portId":"sda-cli-invoke-port","platformCapabilityId":"sda-projected-capability-invocation-port.v2","configuration":{"providerId":"ScenarioKernel.NodePlatform.Execution.ProjectedCapabilityInvocationAndBinding"}}]';
  IF NOT EXISTS (
    SELECT 1 FROM model.estate_capability ec
    JOIN model.capability c ON c.capability_pk=ec.capability_pk
    JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
    JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=ec.semantic_object_definition_pk
    JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
    CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS body) env
    WHERE ec.estate_model_pk=@estate AND c.capability_id=N'sda-cli-invoke'
      AND JSON_VALUE(env.body,'$.semantics.cli.input.type')=N'json'
      AND JSON_VALUE(env.body,'$.semantics.cli.input.contract') IS NULL
      AND JSON_VALUE(env.body,'$.semantics.cli.input.path') IS NULL)
  BEGIN
    DECLARE @interface_result TABLE(action nvarchar(50), capability_id nvarchar(120), capability_version_pk bigint,
      definition_after bigint, cli_before nvarchar(max), cli_after nvarchar(max));
    INSERT @interface_result EXEC model.configure_interface @capability_id=N'sda-cli-invoke',
      @cli_json=N'{"input":{"type":"json"},"display":{"select":"outcome","as":"json"}}';
    SELECT 'sda_cli_invoke_configure' AS result_set, action, capability_id, capability_version_pk, definition_after,
      cli_before, cli_after FROM @interface_result;
  END
END
SELECT 'sda_cli_invoke_root_capability' AS result_set, c.capability_id, c.capability_pk,
 ec.capability_version_pk, ec.semantic_object_definition_pk,
 CONVERT(varchar(64), sod.definition_digest, 2) AS envelope_digest,
 (SELECT STRING_AGG(s.scenario_id, N',') WITHIN GROUP (ORDER BY s.scenario_id)
  FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
  WHERE cs.capability_version_pk=ec.capability_version_pk) AS scenario_links,
 (SELECT STRING_AGG(rs.scenario_id, N',') WITHIN GROUP (ORDER BY rs.scenario_id)
  FROM model.capability_root_scenario crs JOIN model.scenario rs ON rs.scenario_pk=crs.scenario_pk
  WHERE crs.capability_version_pk=ec.capability_version_pk) AS root_scenario,
 JSON_QUERY(env.body, '$.semantics.cli') AS semantics_cli
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS body) env
WHERE ec.estate_model_pk=@estate AND c.capability_id=N'sda-cli-invoke';
SELECT 'sda_cli_invoke_faces' AS result_set, si.input_id, se.event_id, so.outcome_id, so.terminal,
 ea.execution_authority_id, eo.operation_id, eo.operation_kind, p.port_id, pv.port_version_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=N'invoke'
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_outcome so ON so.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
LEFT JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk
LEFT JOIN model.execution_operation eo ON eo.execution_authority_version_pk=se.execution_authority_version_pk
LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
LEFT JOIN model.port p ON p.port_pk=pv.port_pk
WHERE ec.estate_model_pk=@estate AND c.capability_id=N'sda-cli-invoke';
SELECT 'sda_cli_invoke_contract_refs' AS result_set, si.input_id, si.input_contract_version_pk,
 CONVERT(varchar(64), icv.definition_digest, 2) AS input_contract_definition_digest,
 CONVERT(varchar(64), iso.content_digest, 2) AS input_schema_digest,
 JSON_QUERY(st.schema_text,'$.required') AS input_schema_required,
 so.outcome_id, soc.contract_version_pk AS outcome_contract_version_pk,
 CONVERT(varchar(64), ocv.definition_digest, 2) AS outcome_contract_definition_digest,
 CONVERT(varchar(64), oso.content_digest, 2) AS outcome_schema_digest,
 JSON_QUERY(ost.schema_text,'$.required') AS outcome_schema_required
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=N'invoke'
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
JOIN model.scenario_outcome so ON so.scenario_version_pk=sv.scenario_version_pk
JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=sv.scenario_version_pk
JOIN model.contract_version icv ON icv.contract_version_pk=si.input_contract_version_pk
JOIN model.schema_object iso ON iso.schema_object_pk=icv.schema_object_pk
JOIN model.contract_version ocv ON ocv.contract_version_pk=soc.contract_version_pk
JOIN model.schema_object oso ON oso.schema_object_pk=ocv.schema_object_pk
OUTER APPLY (SELECT sch.schema_text FROM source.content_object co2
  CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co2.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_text) sch
  WHERE co2.content_object_pk=iso.content_object_pk) st
OUTER APPLY (SELECT sch.schema_text FROM source.content_object co3
  CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co3.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_text) sch
  WHERE co3.content_object_pk=oso.content_object_pk) ost
WHERE ec.estate_model_pk=@estate AND c.capability_id=N'sda-cli-invoke';
SELECT 'sda_cli_invoke_port_binding' AS result_set, so.declared_id, sod.semantic_object_definition_pk,
 CONVERT(varchar(64), sod.definition_digest, 2) AS digest,
 JSON_VALUE(env.body,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(env.body,'$.semantics.configuration.providerId') AS provider_id
FROM model.semantic_object so
JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk AND n.namespace_id=N'sidefx:capability:sda-cli-invoke'
JOIN model.semantic_object_definition sod ON sod.semantic_object_pk=so.semantic_object_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS body) env
WHERE so.object_kind='PORT' AND so.declared_id=N'sda-cli-invoke-port'
 AND sod.semantic_object_definition_pk=(SELECT MAX(d2.semantic_object_definition_pk) FROM model.semantic_object_definition d2 WHERE d2.semantic_object_pk=so.semantic_object_pk);
SELECT 'sda_cli_invoke_graph_source' AS result_set, g.root_scenario_id,
 JSON_VALUE(g.graph_source,'$.rootScenarioId') AS graph_root_scenario_id,
 JSON_QUERY(g.graph_source,'$.interfaceAuthority.interfaces[0].configuration') AS interface_configuration,
 JSON_QUERY(g.graph_source,'$.interfaceAuthority.portBindings[0].configuration') AS port_configuration,
 (SELECT COUNT(*) FROM OPENJSON(g.graph_source,'$.scenarios')) AS scenario_count,
 (SELECT COUNT(*) FROM OPENJSON(g.graph_source,'$.executionAuthorities')) AS authority_count
FROM analysis.capability_graph_source(N'sda-cli-invoke',0,NULL) g;
COMMIT TRANSACTION;
