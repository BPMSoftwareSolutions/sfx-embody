-- 01-operation-kind-vocabulary.sql
--
-- Proves: the complete declared operation-kind vocabulary of the live model.
-- model.execution_operation.operation_kind has exactly three values:
--   invoke-port    -> companion model.operation_port_invocation (port_version_pk)
--   invoke-scenario-> companion model.operation_scenario_invocation (target_scenario_version_pk)
--   project-state  -> companion model.operation_state_projection (transformation_version_pk)
-- Each kind has exactly one companion table; no other companion table carries
-- rows for any kind. The per-kind example rows show that every target in a
-- companion table is a foreign key to a declared object (a port version, a
-- scenario version, a transformation version) -- i.e. literal at declaration
-- time, with no selector/expression column anywhere in the companion tables.
--
-- Read-only: BEGIN TRANSACTION ... ROLLBACK, SELECT only.
SET NOCOUNT ON;
BEGIN TRANSACTION;

SELECT 'operation_kind_vocabulary' AS result_set,
  eo.operation_kind,
  COUNT(*) AS operation_count,
  (SELECT COUNT(*) FROM model.operation_port_invocation x
    JOIN model.execution_operation xo ON xo.execution_operation_pk=x.execution_operation_pk
    WHERE xo.operation_kind=eo.operation_kind) AS port_invocation_rows,
  (SELECT COUNT(*) FROM model.operation_scenario_invocation x
    JOIN model.execution_operation xo ON xo.execution_operation_pk=x.execution_operation_pk
    WHERE xo.operation_kind=eo.operation_kind) AS scenario_invocation_rows,
  (SELECT COUNT(*) FROM model.operation_state_projection x
    JOIN model.execution_operation xo ON xo.execution_operation_pk=x.execution_operation_pk
    WHERE xo.operation_kind=eo.operation_kind) AS state_projection_rows
FROM model.execution_operation eo
GROUP BY eo.operation_kind
ORDER BY eo.operation_kind;

SELECT TOP (3) 'example_invoke_port' AS result_set,
  eo.execution_operation_pk, eo.operation_kind, eo.operation_id, eo.ordinal,
  opi.port_version_pk, p.port_id, pn.namespace_id AS port_namespace,
  JSON_VALUE(dt.text,'$.semantics.platformCapabilityId') AS platform_capability_id
FROM model.execution_operation eo
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN model.identity_namespace pn ON pn.namespace_pk=p.namespace_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dt
WHERE eo.operation_kind=N'invoke-port'
ORDER BY eo.execution_operation_pk DESC;

SELECT TOP (3) 'example_invoke_scenario' AS result_set,
  eo.execution_operation_pk, eo.operation_kind, eo.operation_id, eo.ordinal,
  osi.target_scenario_version_pk, ts.scenario_id AS target_scenario_id,
  tsv.scenario_pk AS target_scenario_pk
FROM model.execution_operation eo
JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
WHERE eo.operation_kind=N'invoke-scenario'
ORDER BY eo.execution_operation_pk DESC;

SELECT TOP (3) 'example_project_state' AS result_set,
  eo.execution_operation_pk, eo.operation_kind, eo.operation_id, eo.ordinal,
  osp.transformation_version_pk, t.transformation_id, tn.namespace_id AS transformation_namespace
FROM model.execution_operation eo
JOIN model.operation_state_projection osp ON osp.execution_operation_pk=eo.execution_operation_pk
JOIN model.transformation_version tv ON tv.transformation_version_pk=osp.transformation_version_pk
JOIN model.transformation t ON t.transformation_pk=tv.transformation_pk
JOIN model.identity_namespace tn ON tn.namespace_pk=t.namespace_pk
WHERE eo.operation_kind=N'project-state'
ORDER BY eo.execution_operation_pk DESC;

ROLLBACK TRANSACTION;
