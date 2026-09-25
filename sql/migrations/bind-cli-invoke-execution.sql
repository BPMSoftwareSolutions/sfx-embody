-- Re-bind sda-cli-invoke-port to the declared graph-execution boundary (recipe A).
-- Mechanics: docs/execution-binding-mechanics.md (model.bind_provider).
-- Preflight: ends with ROLLBACK; run as a dry run with the migration runner.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=N'sda-cli')
 THROW 51000,'CAPABILITY_NOT_FOUND',1;
GO
EXEC model.bind_provider
 @capability_id=N'sda-cli',
 @mechanic_id=N'sda-cli-invoke-port',
 @provider_id=N'ScenarioKernel.NodePlatform.Execution.ProjectedCapabilityInvocationAndBinding',
 @platform_capability_id=N'sda-projected-capability-invocation-port.v2',
 @configuration_json=N'{"providerId":"ScenarioKernel.NodePlatform.Execution.ProjectedCapabilityInvocationAndBinding"}';
GO
SELECT 'cli_invoke_execution_binding' AS result_set, p.port_id, pv.port_version_pk,
 JSON_VALUE(dt.text,'$.semantics.platformCapabilityId') AS platform_capability,
 JSON_VALUE(dt.text,'$.semantics.configuration.providerId') AS bound_provider
FROM model.port p
JOIN model.port_version pv ON pv.port_pk=p.port_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dt
WHERE p.port_id=N'sda-cli-invoke-port';
ROLLBACK TRANSACTION;
