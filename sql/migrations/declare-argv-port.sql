-- Lane 1 of 4: DECLARED PORT for argv.
-- Port: argv-reading-port in namespace sidefx:capability:argv-provider.
-- Mechanic reference: sda-argv-reading-port.v1.
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
DECLARE @namespace nvarchar(400)=N'sidefx:capability:argv-provider';
DECLARE @portId nvarchar(400)=N'argv-reading-port';
DECLARE @sem nvarchar(max)=N'{"portId":"argv-reading-port","platformCapabilityId":"sda-argv-reading-port.v1"}';
DECLARE @object bigint, @definition bigint, @digest binary(32);
EXEC model.put_semantic_definition 'PORT', @namespace, @portId, @sem,
 @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
SELECT 'argv_reading_port' AS result_set, @namespace AS namespace_id, @portId AS declared_id,
 JSON_VALUE(@sem,'$.platformCapabilityId') AS platform_capability,
 @object AS object_pk, @definition AS definition_pk;
ROLLBACK TRANSACTION;
