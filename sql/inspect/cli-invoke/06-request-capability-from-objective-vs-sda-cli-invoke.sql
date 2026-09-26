-- 06-request-capability-from-objective-vs-sda-cli-invoke.sql
--
-- Proves the side-by-side of the two capabilities named in the question:
--   * request-capability-from-objective (capability pk 100695, selected version
--     910966): its operation 2629 (scenario execute-admitted-proposal, scenario
--     version 91540) is invoke-scenario with a literal target
--     target_scenario_version_pk 898 = resolve-equity-market-price-evidence.
--     Its ports are sda-authority-transformation-port.v1 (literal
--     transformationId) and sda-embodiment-plan-port.v1 (statement over @input);
--     none carries capabilityIdPath.
--   * sda-cli-invoke (capability pk 100909, selected version 1161266): its
--     selected scenarios carry only invoke-scenario operations, and both target
--     scenario version 102211 = sda-cli-invoke literally (a self-target).
--     The invoke-port operation that names port_version 4387 of
--     sda-cli-invoke-port survives only on unselected capability versions
--     1161234 and 1161235.
-- The decisive difference: the request-named target declaration exists only as
-- the selected port declaration 211571 (capabilityIdPath etc., file 03), and it
-- is absent from the selected capability version's operations; the operation
-- that would consume it is the retained invoke-port operation of the unselected
-- versions. The companion column of an invoke-scenario operation is a literal
-- target_scenario_version_pk, so target-from-request is not expressible through
-- invoke-scenario at all.
--
-- Read-only: BEGIN TRANSACTION ... ROLLBACK, SELECT only.
SET NOCOUNT ON;
BEGIN TRANSACTION;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT 'request_capability_operation_2629' AS result_set,
  c.capability_id, n.namespace_id, ec.capability_version_pk,
  s.scenario_id AS owning_scenario_id, se.scenario_version_pk AS owning_scenario_version_pk,
  eo.execution_operation_pk, eo.operation_kind,
  osi.target_scenario_version_pk, ts.scenario_id AS target_scenario_id
FROM model.execution_operation eo
JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
JOIN model.scenario_event se ON se.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.capability_scenario cs ON cs.scenario_version_pk=se.scenario_version_pk
JOIN model.capability_version cv ON cv.capability_version_pk=cs.capability_version_pk
JOIN model.capability c ON c.capability_pk=cv.capability_pk AND c.capability_pk=100695
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_version_pk=cv.capability_version_pk
WHERE eo.execution_operation_pk=2629;

SELECT 'sda_cli_invoke_selected_operations' AS result_set,
  ec.capability_version_pk, s.scenario_id, se.scenario_version_pk,
  eo.execution_operation_pk, eo.operation_kind,
  opi.port_version_pk, p.port_id AS invoked_port_id,
  osi.target_scenario_version_pk, ts.scenario_id AS literal_target_scenario_id
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_pk=c.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
LEFT JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
LEFT JOIN model.port p ON p.port_pk=pv.port_pk
LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
LEFT JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
LEFT JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
WHERE c.capability_id=N'sda-cli-invoke'
ORDER BY s.scenario_id, eo.ordinal;

SELECT 'sda_cli_invoke_retained_invoke_port_operations' AS result_set,
  cv.capability_version_pk,
  CASE WHEN ec.capability_version_pk IS NOT NULL THEN 1 ELSE 0 END AS capability_version_selected,
  s.scenario_id, se.scenario_version_pk,
  eo.execution_operation_pk, eo.operation_kind, eo.operation_id,
  opi.port_version_pk, p.port_id, pn.namespace_id AS port_namespace
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=cv.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN model.identity_namespace pn ON pn.namespace_pk=p.namespace_pk
LEFT JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_version_pk=cv.capability_version_pk
WHERE c.capability_id=N'sda-cli-invoke' AND eo.operation_kind=N'invoke-port'
ORDER BY cv.capability_version_pk DESC, s.scenario_id, eo.ordinal;

SELECT 'port_declarations_side_by_side' AS result_set,
  sd.namespace_id, sd.declared_id AS port_id,
  JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.capabilityIdPath') AS capability_id_path,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.requestPath') AS request_path,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.transformationId') AS transformation_id,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.statement') AS configuration_statement_present
FROM analysis.v_selected_semantic_definition sd
WHERE sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
  AND (sd.namespace_id=N'sidefx:capability:request-capability-from-objective'
    OR (sd.namespace_id=N'sidefx:capability:sda-cli-invoke' AND sd.declared_id=N'sda-cli-invoke-port'))
ORDER BY sd.namespace_id, sd.declared_id;

ROLLBACK TRANSACTION;
