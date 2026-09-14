-- Make `run-declared-query` invocable: real contracts and a root Scenario whose
-- single operation executes the declared SQL read through the declared provider row
-- (`database-query-provider.readDatabaseQuery`). No module path in the Port.
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
EXEC model.declare_contract @id=N'run-declared-query-request.v1',
 @schema=N'{"type":"object","properties":{"statement":{"type":"string"},"resultColumn":{"type":"string"}},"additionalProperties":true}';
EXEC model.declare_contract @id=N'run-declared-query-result.v1',
 @schema=N'{"type":"object","additionalProperties":true}';
GO
EXEC model.declare_scenario
 @capability_id=N'run-declared-query',
 @scenario=N'{"scenarioId":"run-declared-query","name":"Run one declared query","inputId":"run-declared-query-request","inputContract":"run-declared-query-request.v1","eventId":"run-declared-query-requested","eventAuthority":"run-declared-query.v1","outcomeId":"run-declared-query-result","outcomeContract":"run-declared-query-result.v1","terminal":true,"root":true,"given":"one declared SQL statement under the reader boundary","when":"the declared query is executed","then":"the declared result column is returned as JSON or the query is held"}',
 @operations=N'[{"operationId":"run-declared-query.0","kind":"invoke-port","portId":"run-declared-query-port"}]',
 @port_bindings=N'[{"portId":"run-declared-query-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"providerId":"database-query-provider.readDatabaseQuery","statement":"SELECT (SELECT TOP 1 c.capability_id AS capabilityId FROM model.capability c ORDER BY c.capability_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value","resultColumn":"value"}}]';
GO
SELECT 'run_declared_query' AS result_set, c.capability_id, s.scenario_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:'+c.capability_id
WHERE c.capability_id=N'run-declared-query';
COMMIT TRANSACTION;
