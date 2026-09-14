-- Declared capability for the generic SQL read mechanic `readDatabaseQuery`:
-- the Port carries the SQL statement and result column; the declared provider
-- executes it under the reader boundary.
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
EXEC model.scaffold_capability @capability_id=N'database-query-provider', @on_exists=N'REPLACE';
EXEC model.declare_contract @id=N'database-query-provider-request.v1', @schema=N'{"type":"object","additionalProperties":true}';
EXEC model.declare_contract @id=N'database-query-provider-result.v1', @schema=N'{"type":"object","additionalProperties":true}';
GO
EXEC model.declare_scenario
 @capability_id=N'database-query-provider',
 @scenario=N'{"scenarioId":"database-query-provider","name":"Run one declared SQL read","inputId":"database-query-provider-request","inputContract":"database-query-provider-request.v1","eventId":"database-query-provider-requested","eventAuthority":"database-query-provider.v1","outcomeId":"database-query-provider-result","outcomeContract":"database-query-provider-result.v1","terminal":true,"root":true,"given":"one declared statement and result column","when":"the statement executes under the reader boundary","then":"the parsed result column is returned or the read is held"}',
 @operations=N'[{"operationId":"database-query-provider.0","kind":"invoke-port","portId":"database-query-provider-port"}]',
 @port_bindings=N'[{"portId":"database-query-provider-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"providerId":"database-query-provider.readDatabaseQuery","resultColumn":"bundle","statement":"SELECT (SELECT c.capability_id AS capabilityId FROM model.capability c ORDER BY c.capability_id FOR JSON PATH) AS bundle"}}]';
GO
SELECT 'database_query_provider_capability' AS result_set, c.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+c.capability_id) COLLATE Latin1_General_100_BIN2
WHERE c.capability_id=N'database-query-provider';
COMMIT TRANSACTION;
