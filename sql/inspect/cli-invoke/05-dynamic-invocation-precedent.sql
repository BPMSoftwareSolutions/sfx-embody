-- 05-dynamic-invocation-precedent.sql
--
-- Proves: there is NO working precedent in the live selected graphs of a
-- capability-to-capability invocation whose target is resolved from the request.
-- The decisive count joins every invoke-port operation that belongs to a
-- selected capability version to the selected declaration of the port object it
-- invokes, and counts those whose declaration carries
-- configuration.capabilityIdPath. The result is zero rows: the only declaration
-- in the whole model with capabilityIdPath is sda-cli-invoke-port (03), and no
-- selected graph invokes it.
-- For contrast the file lists every selected-graph operation that does invoke a
-- port whose selected declaration names sda-node-consumer-runtime.v1 -- that is
-- the run-pilot-container precedent, whose configuration is {} and therefore
-- names no target from the request -- and counts selected-graph operations on
-- the v2 projected port, whose target is the pinned literal declaredApplication.
--
-- If the count in the first result set were non-zero, that row would be the
-- precedent. It is 0, so the answer to "is there a working target-from-request
-- invocation" is: not in this database state.
--
-- Read-only: BEGIN TRANSACTION ... ROLLBACK, SELECT only.
SET NOCOUNT ON;
BEGIN TRANSACTION;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

WITH selected_invoke_port AS (
  SELECT eo.execution_operation_pk, pv.port_pk
  FROM model.execution_operation eo
  JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
  JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
  JOIN model.scenario_event se ON se.execution_authority_version_pk=eav.execution_authority_version_pk
  JOIN model.capability_scenario cs ON cs.scenario_version_pk=se.scenario_version_pk
  JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_version_pk=cs.capability_version_pk
  WHERE eo.operation_kind=N'invoke-port'
),
port_selected_declaration AS (
  SELECT p.port_pk, p.port_id, pn.namespace_id AS port_namespace,
    sd.semantic_object_definition_pk,
    JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
    JSON_VALUE(sd.definition_json,'$.semantics.configuration.capabilityIdPath') AS capability_id_path,
    JSON_VALUE(sd.definition_json,'$.semantics.configuration.requestPath') AS request_path,
    JSON_VALUE(sd.definition_json,'$.semantics.configuration.authoritySource') AS authority_source,
    JSON_QUERY(sd.definition_json,'$.semantics.configuration.declaredApplication') AS declared_application
  FROM model.port p
  JOIN model.identity_namespace pn ON pn.namespace_pk=p.namespace_pk
  JOIN model.semantic_object so ON so.semantic_object_pk=p.semantic_object_pk
  JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=(
    SELECT MAX(d2.semantic_object_definition_pk)
    FROM model.estate_definition ed2
    JOIN model.semantic_object_definition d2 ON d2.semantic_object_definition_pk=ed2.semantic_object_definition_pk
    WHERE ed2.estate_model_pk=@estate AND d2.semantic_object_pk=so.semantic_object_pk)
  JOIN analysis.v_selected_semantic_definition sd
    ON sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
   AND sd.semantic_object_definition_pk=sod.semantic_object_definition_pk
)
SELECT 'dynamic_target_invocations_in_selected_graphs' AS result_set,
  COUNT(*) AS selected_graph_invoke_port_operations,
  SUM(CASE WHEN ps.capability_id_path IS NOT NULL THEN 1 ELSE 0 END) AS operations_with_request_named_target
FROM selected_invoke_port o
JOIN port_selected_declaration ps ON ps.port_pk=o.port_pk;

WITH selected_invoke_port AS (
  SELECT eo.execution_operation_pk, pv.port_pk
  FROM model.execution_operation eo
  JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
  JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
  JOIN model.scenario_event se ON se.execution_authority_version_pk=eav.execution_authority_version_pk
  JOIN model.capability_scenario cs ON cs.scenario_version_pk=se.scenario_version_pk
  JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_version_pk=cs.capability_version_pk
  WHERE eo.operation_kind=N'invoke-port'
),
port_selected_declaration AS (
  SELECT p.port_pk, p.port_id, pn.namespace_id AS port_namespace,
    JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
    JSON_VALUE(sd.definition_json,'$.semantics.configuration.capabilityIdPath') AS capability_id_path,
    JSON_VALUE(sd.definition_json,'$.semantics.configuration.authoritySource') AS authority_source
  FROM model.port p
  JOIN model.identity_namespace pn ON pn.namespace_pk=p.namespace_pk
  JOIN model.semantic_object so ON so.semantic_object_pk=p.semantic_object_pk
  JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=(
    SELECT MAX(d2.semantic_object_definition_pk)
    FROM model.estate_definition ed2
    JOIN model.semantic_object_definition d2 ON d2.semantic_object_definition_pk=ed2.semantic_object_definition_pk
    WHERE ed2.estate_model_pk=@estate AND d2.semantic_object_pk=so.semantic_object_pk)
  JOIN analysis.v_selected_semantic_definition sd
    ON sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
   AND sd.semantic_object_definition_pk=sod.semantic_object_definition_pk
)
SELECT 'consumer_runtime_invocations_in_selected_graphs' AS result_set,
  ps.port_id, ps.port_namespace, ps.platform_capability_id,
  ps.capability_id_path, ps.authority_source, COUNT(*) AS operations
FROM selected_invoke_port o
JOIN port_selected_declaration ps ON ps.port_pk=o.port_pk
WHERE ps.platform_capability_id=N'sda-node-consumer-runtime.v1'
GROUP BY ps.port_id, ps.port_namespace, ps.platform_capability_id, ps.capability_id_path, ps.authority_source
ORDER BY ps.port_id;

WITH selected_invoke_port AS (
  SELECT eo.execution_operation_pk, pv.port_pk
  FROM model.execution_operation eo
  JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
  JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
  JOIN model.scenario_event se ON se.execution_authority_version_pk=eav.execution_authority_version_pk
  JOIN model.capability_scenario cs ON cs.scenario_version_pk=se.scenario_version_pk
  JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_version_pk=cs.capability_version_pk
  WHERE eo.operation_kind=N'invoke-port'
),
port_selected_declaration AS (
  SELECT p.port_pk,
    JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
    JSON_QUERY(sd.definition_json,'$.semantics.configuration.declaredApplication') AS declared_application
  FROM model.port p
  JOIN model.semantic_object so ON so.semantic_object_pk=p.semantic_object_pk
  JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=(
    SELECT MAX(d2.semantic_object_definition_pk)
    FROM model.estate_definition ed2
    JOIN model.semantic_object_definition d2 ON d2.semantic_object_definition_pk=ed2.semantic_object_definition_pk
    WHERE ed2.estate_model_pk=@estate AND d2.semantic_object_pk=so.semantic_object_pk)
  JOIN analysis.v_selected_semantic_definition sd
    ON sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
   AND sd.semantic_object_definition_pk=sod.semantic_object_definition_pk
)
SELECT 'v2_pinned_invocations_in_selected_graphs' AS result_set,
  ps.platform_capability_id,
  SUM(CASE WHEN ps.declared_application IS NOT NULL THEN 1 ELSE 0 END) AS operations_with_pinned_application,
  COUNT(*) AS operations
FROM selected_invoke_port o
JOIN port_selected_declaration ps ON ps.port_pk=o.port_pk
WHERE ps.platform_capability_id=N'sda-projected-capability-invocation-port.v2'
GROUP BY ps.platform_capability_id;

ROLLBACK TRANSACTION;
