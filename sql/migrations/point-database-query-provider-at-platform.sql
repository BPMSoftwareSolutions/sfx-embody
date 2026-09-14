-- database-query-provider was a pre-SDA placeholder: its Port named the local
-- hand-authored src/resolvers/node/database-query-provider.mjs and an invented
-- platform capability (sda-embodiment-plan-port.v1). Point it at the SDA platform
-- memory scenario loader, as the pilot capability does.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
GO
DECLARE @namespace nvarchar(400)=N'sidefx:capability:database-query-provider';
DECLARE @portId nvarchar(400)=N'database-query-provider-port';
DECLARE @current nvarchar(max), @object bigint, @definition bigint, @digest binary(32);
SELECT @current=JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
 WHERE object_kind='PORT' AND namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND declared_id=@portId COLLATE Latin1_General_100_BIN2;
IF @current IS NULL THROW 51000,'DATABASE_QUERY_PROVIDER_PORT_NOT_DECLARED',1;
DECLARE @sem nvarchar(max)=N'{"portId":"database-query-provider-port","platformCapabilityId":"sda-node-consumer-runtime.v1","configuration":{"providerId":"sda-node-load-memory-scenario.loadMemoryScenario"}}';
EXEC model.put_semantic_definition 'PORT', @namespace, @portId, @sem, @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
SELECT 'database_query_provider_port' AS result_set,
 JSON_VALUE(@current,'$.platformCapabilityId') AS was_platform_capability,
 JSON_VALUE(@current,'$.configuration.providerId') AS was_provider_id,
 JSON_VALUE(@sem,'$.platformCapabilityId') AS now_platform_capability,
 JSON_VALUE(@sem,'$.configuration.providerId') AS now_provider_id;
COMMIT TRANSACTION;
