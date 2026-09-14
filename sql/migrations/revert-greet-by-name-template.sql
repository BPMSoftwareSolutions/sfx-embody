-- Flywheel demonstration: change a declared row (the greeting transformation's
-- template) and observe the capability's outcome change. Reverted by the next
-- migration.
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
DECLARE @sem nvarchar(max);
SELECT @sem=JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
 WHERE object_kind='TRANSFORMATION' AND declared_id=N'greet-by-name-transform.v1'
 AND namespace_id=N'sidefx:capability:greet-by-name' COLLATE Latin1_General_100_BIN2;
IF @sem IS NULL THROW 51000,'TRANSFORMATION_NOT_FOUND',1;
SET @sem=JSON_MODIFY(@sem,'$.expression.fields.payload.fields.message.template',N'Hello, {name}!'); SET @sem=JSON_MODIFY(@sem,'$.revertedAt',CONVERT(nvarchar(40),SYSUTCDATETIME(),126));
DECLARE @object bigint,@definition bigint,@digest binary(32);
EXEC model.put_semantic_definition 'TRANSFORMATION',N'sidefx:capability:greet-by-name',N'greet-by-name-transform.v1',@sem,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
SELECT 'greet_template_change' AS result_set, JSON_VALUE(@sem,'$.expression.fields.payload.fields.message.template') AS template;
COMMIT TRANSACTION;

