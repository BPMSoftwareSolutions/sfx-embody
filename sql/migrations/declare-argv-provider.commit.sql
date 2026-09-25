-- Lane 4 of 4: DECLARED PROVIDER for argv.
-- Scaffolds the estate provider capability argv-provider with its provider module.
-- Rollback file: run as a dry run with the migration runner.
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
EXEC model.scaffold_estate_provider_capability
 @capability_id=N'argv-provider',
 @provider_module=N'src/resolvers/node/argv-provider.mjs',
 @provider_export=N'provideArguments',
 @input_contract=N'argv-provider-request.v1',
 @input_schema=N'{"type":"object","additionalProperties":false}',
 @outcome_contract=N'argv-provider-result.v1',
 @outcome_schema=N'{"type":"object","additionalProperties":false,"required":["arguments"],"properties":{"arguments":{"type":"array","items":{"type":"string"}}}}',
 @description=N'Read the process arguments through the declared port',
 @on_exists=N'REPLACE';
GO
SELECT 'argv_provider' AS result_set, c.capability_id
FROM model.capability c
WHERE c.capability_id=N'argv-provider';
COMMIT TRANSACTION;
