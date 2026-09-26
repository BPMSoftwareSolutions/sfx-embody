-- 03-port-semantics-request-paths.sql
--
-- Proves: where a request-derived target can be declared in this database -- in
-- the semantics of a port, not in an operation. Among selected port
-- declarations, the members capabilityIdPath / requestPath / scenarioPath /
-- namespacePath / resultPath / authoritySource / declaredApplication occur only
-- on platform-capability-bound ports. Two platform capabilities are contrasted:
--   * sda-node-consumer-runtime.v1      : 2 selected declarations with
--     authoritySource; exactly 1 (sda-cli-invoke-port, definition 211571) also
--     carries capabilityIdPath='capabilityId' + requestPath='input' -- the
--     request names the capability to invoke.
--   * sda-projected-capability-invocation-port.v2 : 82 selected declarations,
--     0 with capabilityIdPath, 24 with declaredApplication -- the target is
--     pinned as a literal capabilityId inside the declared application.
-- The v2 sample rows show that pinned literal (executionPlanDocument.capabilityId).
--
-- Read-only: BEGIN TRANSACTION ... ROLLBACK, SELECT only.
SET NOCOUNT ON;
BEGIN TRANSACTION;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT 'selected_ports_with_request_members' AS result_set,
  JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
  COUNT(*) AS selected_port_declarations,
  SUM(CASE WHEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.capabilityIdPath') IS NOT NULL THEN 1 ELSE 0 END) AS with_capability_id_path,
  SUM(CASE WHEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.requestPath') IS NOT NULL THEN 1 ELSE 0 END) AS with_request_path,
  SUM(CASE WHEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.scenarioPath') IS NOT NULL THEN 1 ELSE 0 END) AS with_scenario_path,
  SUM(CASE WHEN JSON_VALUE(sd.definition_json,'$.semantics.configuration.authoritySource') IS NOT NULL THEN 1 ELSE 0 END) AS with_authority_source,
  SUM(CASE WHEN JSON_QUERY(sd.definition_json,'$.semantics.configuration.declaredApplication') IS NOT NULL THEN 1 ELSE 0 END) AS with_declared_application
FROM analysis.v_selected_semantic_definition sd
WHERE sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
  AND (JSON_VALUE(sd.definition_json,'$.semantics.configuration.capabilityIdPath') IS NOT NULL
    OR JSON_VALUE(sd.definition_json,'$.semantics.configuration.requestPath') IS NOT NULL
    OR JSON_VALUE(sd.definition_json,'$.semantics.configuration.scenarioPath') IS NOT NULL
    OR JSON_VALUE(sd.definition_json,'$.semantics.configuration.authoritySource') IS NOT NULL
    OR JSON_QUERY(sd.definition_json,'$.semantics.configuration.declaredApplication') IS NOT NULL)
GROUP BY JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId')
ORDER BY selected_port_declarations DESC;

SELECT 'sda_cli_invoke_port_selected_declaration' AS result_set,
  sd.semantic_object_definition_pk, pv.port_version_pk, sd.namespace_id, sd.declared_id AS port_id,
  JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.providerId') AS provider_id,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.authoritySource') AS authority_source,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.capabilityIdPath') AS capability_id_path,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.requestPath') AS request_path,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.namespacePath') AS namespace_path,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.scenarioPath') AS scenario_path,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.resultPath') AS result_path,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.lineageMode') AS lineage_mode
FROM analysis.v_selected_semantic_definition sd
JOIN model.port_version pv ON pv.semantic_object_definition_pk=sd.semantic_object_definition_pk
WHERE sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
  AND sd.namespace_id=N'sidefx:capability:sda-cli-invoke' AND sd.declared_id=N'sda-cli-invoke-port';

WITH v2_apps AS (
  SELECT sd.declared_id AS port_id,
    JSON_VALUE(sd.definition_json,'$.semantics.configuration.capabilityAuthorityDigest') AS authority_digest,
    JSON_VALUE(sd.definition_json,'$.semantics.configuration.requestPath') AS request_path,
    JSON_QUERY(sd.definition_json,'$.semantics.configuration.declaredApplication') AS application_json
  FROM analysis.v_selected_semantic_definition sd
  WHERE sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
    AND JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId')=N'sda-projected-capability-invocation-port.v2'
),
v2_plans AS (
  SELECT a.port_id, a.authority_digest, a.request_path,
    CASE WHEN ISJSON(p.plan_document)=1 THEN p.plan_document END AS plan_json
  FROM v2_apps a
  OUTER APPLY OPENJSON(a.application_json) WITH (plan_document nvarchar(max) '$.executionPlanDocument') p
)
SELECT TOP (2) 'v2_pinned_target_sample' AS result_set,
  port_id,
  CASE WHEN plan_json IS NOT NULL THEN JSON_VALUE(plan_json,'$.capabilityId') END AS pinned_capability_id,
  authority_digest,
  request_path
FROM v2_plans
WHERE CASE WHEN plan_json IS NOT NULL THEN JSON_VALUE(plan_json,'$.capabilityId') END IS NOT NULL
ORDER BY port_id;

SELECT 'consumer_runtime_port_declarations' AS result_set,
  sd.declared_id AS port_id, sd.namespace_id, sd.semantic_object_definition_pk,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.capabilityIdPath') AS capability_id_path,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.authoritySource') AS authority_source,
  JSON_VALUE(sd.definition_json,'$.semantics.configuration.inputAdmission.required[0]') AS input_admission_first_required
FROM analysis.v_selected_semantic_definition sd
WHERE sd.estate_model_pk=@estate AND sd.object_kind=N'PORT'
  AND JSON_VALUE(sd.definition_json,'$.semantics.platformCapabilityId')=N'sda-node-consumer-runtime.v1'
ORDER BY sd.declared_id;

ROLLBACK TRANSACTION;
