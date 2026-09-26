-- 02-invocation-companion-columns.sql
--
-- Proves: what the invocation companion tables can and cannot express. The
-- companion of a kind is a literal foreign key, never a selector:
--   model.operation_port_invocation     -> port_version_pk
--   model.operation_scenario_invocation -> target_scenario_version_pk
--   model.operation_state_projection    -> transformation_version_pk
-- No companion table has a column whose name carries capability/target/path/
-- expression/selector/authority selection; the only place a target can be
-- request-derived is therefore the referenced declaration itself (a port's
-- semantics, inspected in 03-port-semantics-request-paths.sql).
-- The table also shows the three declared-but-empty companions
-- (operation_transformation, operation_mechanic, operation_predecessor) and the
-- four invoke-port operations in selected capability versions that have no
-- companion row at all -- a declaration-surface hole counted, not inferred.
--
-- Read-only: BEGIN TRANSACTION ... ROLLBACK, SELECT only.
SET NOCOUNT ON;
BEGIN TRANSACTION;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT 'companion_columns' AS result_set, t.name AS table_name,
  STRING_AGG(CONVERT(nvarchar(max),c.name+N' '+ty.name) COLLATE Latin1_General_100_BIN2_UTF8, N', ')
    WITHIN GROUP (ORDER BY c.column_id) AS column_list
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.columns c ON c.object_id=t.object_id
JOIN sys.types ty ON ty.user_type_id=c.user_type_id
WHERE s.name=N'model' AND t.name IN (
  N'operation_port_invocation', N'operation_scenario_invocation', N'operation_state_projection',
  N'operation_transformation', N'operation_mechanic', N'operation_predecessor')
GROUP BY t.name
ORDER BY t.name;

SELECT 'companion_row_counts' AS result_set, t.name AS table_name, SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN (0,1)
WHERE s.name=N'model' AND t.name IN (
  N'operation_port_invocation', N'operation_scenario_invocation', N'operation_state_projection',
  N'operation_transformation', N'operation_mechanic', N'operation_predecessor')
GROUP BY t.name
ORDER BY t.name;

SELECT 'unpaired_invoke_port_operations' AS result_set,
  c.capability_id, cn.namespace_id AS capability_namespace, cv.capability_version_pk,
  s.scenario_id, se.scenario_version_pk, eo.execution_operation_pk, eo.operation_id, eo.ordinal
FROM model.execution_operation eo
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=eo.execution_authority_version_pk
JOIN model.scenario_event se ON se.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.capability_scenario cs ON cs.scenario_version_pk=se.scenario_version_pk
JOIN model.capability_version cv ON cv.capability_version_pk=cs.capability_version_pk
JOIN model.capability c ON c.capability_pk=cv.capability_pk
JOIN model.identity_namespace cn ON cn.namespace_pk=c.namespace_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.estate_capability ec ON ec.estate_model_pk=@estate AND ec.capability_version_pk=cv.capability_version_pk
WHERE eo.operation_kind=N'invoke-port'
  AND NOT EXISTS (SELECT 1 FROM model.operation_port_invocation opi WHERE opi.execution_operation_pk=eo.execution_operation_pk)
ORDER BY c.capability_id, eo.ordinal;

SELECT 'companion_example_port_invocation' AS result_set,
  opi.execution_operation_pk, opi.operation_kind, opi.port_version_pk, p.port_id, pn.namespace_id AS port_namespace
FROM model.operation_port_invocation opi
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN model.identity_namespace pn ON pn.namespace_pk=p.namespace_pk
WHERE opi.execution_operation_pk IN (8824, 8825);

SELECT 'companion_example_scenario_invocation' AS result_set,
  osi.execution_operation_pk, osi.operation_kind, osi.target_scenario_version_pk,
  ts.scenario_id AS target_scenario_id
FROM model.operation_scenario_invocation osi
JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
WHERE osi.execution_operation_pk=2629;

SELECT 'companion_example_state_projection' AS result_set,
  osp.execution_operation_pk, osp.operation_kind, osp.transformation_version_pk,
  t.transformation_id
FROM model.operation_state_projection osp
JOIN model.transformation_version tv ON tv.transformation_version_pk=osp.transformation_version_pk
JOIN model.transformation t ON t.transformation_pk=tv.transformation_pk
WHERE osp.execution_operation_pk=520;

ROLLBACK TRANSACTION;
