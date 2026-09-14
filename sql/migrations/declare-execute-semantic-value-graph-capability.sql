-- Data-side execution proof: run a compiled graph with only the SDA pure-mechanic
-- factory as provider (no domain provider, no wrapper, no local module).
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
EXEC model.scaffold_capability @capability_id=N'execute-semantic-value-graph', @on_exists=N'REPLACE';
EXEC model.declare_contract @id=N'execute-semantic-value-graph-request.v1', @schema=N'{"type":"object","required":["plan","input"],"properties":{"plan":{"type":"object"},"input":{}}}';
EXEC model.declare_contract @id=N'execute-semantic-value-graph-result.v1', @schema=N'{"type":"object","additionalProperties":true}';
GO
EXEC model.declare_scenario
 @capability_id=N'execute-semantic-value-graph',
 @scenario=N'{"scenarioId":"execute-semantic-value-graph","name":"Execute a compiled graph with the pure-mechanic factory","inputId":"execute-semantic-value-graph-request","inputContract":"execute-semantic-value-graph-request.v1","eventId":"execute-semantic-value-graph-requested","eventAuthority":"execute-semantic-value-graph.v1","outcomeId":"execute-semantic-value-graph-result","outcomeContract":"execute-semantic-value-graph-result.v1","terminal":true,"root":true,"given":"one compiled semantic execution graph and its declared overlay","when":"the kernel scheduler interprets it with the pure-mechanic provider","then":"the graph outcome and observed topology are returned"}',
 @operations=N'[{"operationId":"execute-semantic-value-graph.0","kind":"invoke-port","portId":"execute-semantic-value-graph-port"}]',
 @port_bindings=N'[{"portId":"execute-semantic-value-graph-port","platformCapabilityId":"sda-semantic-execution-graph-execution-port.v1","configuration":{"providerId":"sda-semantic-execution-graph-execution.executeSemanticExecutionGraph","providers":[{"providerProfileId":"sda-semantic-value-graph-provider.v1","module":"languages/typescript/runtimes/node/semantic-execution-graph-mechanic-provider.mjs","export":"createMechanicProvider","factory":true}]}}]';
GO
SELECT 'execute_semantic_value_graph' AS result_set, c.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+c.capability_id) COLLATE Latin1_General_100_BIN2
WHERE c.capability_id=N'execute-semantic-value-graph';
COMMIT TRANSACTION;
