-- 00-live-model-identity.sql
--
-- Proves: the CLI-invoke inspection lane reads the live database, and fixes the
-- two identities every later file depends on:
--   * the current estate model (source.current_model.singleton_id = 1);
--   * the capability pk of sda-cli-invoke (100909) and of the comparison
--     capability request-capability-from-objective (100695), both in namespace
--     sidefx:capabilities.
-- Also reports the row counts of the model tables that carry execution
-- declarations, so later files can name companion tables from live counts
-- rather than from documentation.
--
-- Read-only: BEGIN TRANSACTION ... ROLLBACK, SELECT only.
SET NOCOUNT ON;
BEGIN TRANSACTION;

SELECT 'database_identity' AS result_set,
  DB_NAME() AS database_name,
  CONVERT(nvarchar(128),SERVERPROPERTY('ServerName')) AS server_name,
  CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) AS product_version;

SELECT 'current_estate_model' AS result_set, *
FROM source.current_model;

SELECT 'capability_identities' AS result_set,
  c.capability_pk,
  c.capability_id,
  n.namespace_id,
  (SELECT ec.capability_version_pk FROM model.estate_capability ec
    WHERE ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
      AND ec.capability_pk=c.capability_pk) AS selected_capability_version_pk
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE c.capability_pk IN (100909, 100695)
ORDER BY c.capability_id;

SELECT 'model_declaration_table_counts' AS result_set, t.name AS table_name, SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id=t.schema_id
JOIN sys.partitions p ON p.object_id=t.object_id AND p.index_id IN (0,1)
WHERE s.name=N'model' AND t.name IN (
  N'capability', N'capability_version', N'estate_capability',
  N'execution_operation', N'operation_port_invocation', N'operation_scenario_invocation',
  N'operation_state_projection', N'operation_transformation', N'operation_mechanic', N'operation_predecessor',
  N'port', N'port_version', N'scenario', N'scenario_version',
  N'provider', N'provider_definition', N'provider_capability_implementation',
  N'provider_mechanic_implementation', N'provider_profile', N'semantic_object_definition')
GROUP BY t.name
ORDER BY t.name;

ROLLBACK TRANSACTION;
