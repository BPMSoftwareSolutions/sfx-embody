-- Scaffold one capability per hand-authored Node mechanic. These are capability
-- identities only (no provider binding): the behavior is to be declared as data.
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
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
-- authority-read-provider.mjs
EXEC model.scaffold_capability @capability_id=N'read-declared-authority', @on_exists=N'REPLACE';
-- consumer-authority-context.mjs
EXEC model.scaffold_capability @capability_id=N'carry-consumer-authority-context', @on_exists=N'REPLACE';
-- consumer-execution-provider.mjs
EXEC model.scaffold_capability @capability_id=N'execute-consumer-plan', @on_exists=N'REPLACE';
-- consumer-object-provider.mjs
EXEC model.scaffold_capability @capability_id=N'render-consumer-object', @on_exists=N'REPLACE';
-- consumer-plan-provider.mjs
EXEC model.scaffold_capability @capability_id=N'plan-consumer-execution', @on_exists=N'REPLACE';
-- consumer-write-provider.mjs
EXEC model.scaffold_capability @capability_id=N'write-consumer-embodiment', @on_exists=N'REPLACE';
-- contract-admission-provider.mjs
EXEC model.scaffold_capability @capability_id=N'admit-declared-contract', @on_exists=N'REPLACE';
-- database-query-provider.mjs
EXEC model.scaffold_capability @capability_id=N'run-declared-query', @on_exists=N'REPLACE';
-- embodiment-plan-provider.mjs
EXEC model.scaffold_capability @capability_id=N'plan-capability-embodiment', @on_exists=N'REPLACE';
-- embodiment-write-provider.mjs
EXEC model.scaffold_capability @capability_id=N'write-capability-embodiment', @on_exists=N'REPLACE';
-- execution-graph-read-provider.mjs
EXEC model.scaffold_capability @capability_id=N'read-declared-execution-graph', @on_exists=N'REPLACE';
-- native-expression-projection.mjs
EXEC model.scaffold_capability @capability_id=N'project-native-expressions', @on_exists=N'REPLACE';
GO
SELECT 'scaffolded_mechanic_capabilities' AS result_set, c.capability_id
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
WHERE c.capability_id IN (N'read-declared-authority',N'carry-consumer-authority-context',N'execute-consumer-plan',
 N'render-consumer-object',N'plan-consumer-execution',N'write-consumer-embodiment',N'admit-declared-contract',
 N'run-declared-query',N'plan-capability-embodiment',N'write-capability-embodiment',N'read-declared-execution-graph',
 N'project-native-expressions')
ORDER BY c.capability_id;
COMMIT TRANSACTION;
