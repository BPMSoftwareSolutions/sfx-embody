-- Make the provider-backed scaffolded mechanics invocable: real contracts and a
-- root Scenario whose single operation binds the declared provider, copying the
-- source Port's configuration. No module path in any Port.
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
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @mechs TABLE (capability_id nvarchar(400), source_port_id nvarchar(400), provider_id nvarchar(400));
INSERT @mechs (capability_id, source_port_id, provider_id) VALUES
 (N'read-declared-authority', N'read-execution-capability-authority', N'authority-read-provider.readCapabilityAuthority'),
 (N'admit-declared-contract', N'admit-execution-input', N'contract-admission-provider.admitDeclaredContract'),
 (N'plan-consumer-execution', N'read-bound-consumer-execution-plan', N'consumer-plan-provider.readConsumerExecutionPlan'),
 (N'execute-consumer-plan', N'execute-bound-consumer-plan', N'consumer-execution-provider.executeConsumerPlan'),
 (N'write-consumer-embodiment', N'write-capability-embodiment-port', N'embodiment-write-provider.writeCapabilityEmbodiment'),
 (N'read-declared-execution-graph', N'derive-target-neutral-execution-plan', N'execution-graph-read-provider.readDeclaredExecutionGraph');
DECLARE @cap nvarchar(400), @src nvarchar(400), @prov nvarchar(400);
DECLARE @config nvarchar(max), @in nvarchar(400), @out nvarchar(400), @port nvarchar(400);
DECLARE @scenario nvarchar(max), @operations nvarchar(max), @bindings nvarchar(max);
DECLARE mechs CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id, source_port_id, provider_id FROM @mechs;
OPEN mechs;
FETCH NEXT FROM mechs INTO @cap, @src, @prov;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @config=JSON_QUERY((SELECT d.definition_json FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' AND d.declared_id=@src COLLATE Latin1_General_100_BIN2), '$.semantics.configuration');
 IF @config IS NULL THROW 51000,'SOURCE_PORT_CONFIGURATION_ABSENT',1;
 SET @config=JSON_MODIFY(@config,'$.providerId',@prov);
 SET @config=JSON_MODIFY(@config,'$.estateProvider',NULL);
 SET @config=JSON_MODIFY(@config,'$.planningProviders',NULL);
 SET @config=JSON_MODIFY(@config,'$.writingProviders',NULL);
 SET @in=@cap+N'-request.v1'; SET @out=@cap+N'-result.v1'; SET @port=@cap+N'-port';
 EXEC model.declare_contract @id=@in, @schema=N'{"type":"object"}';
 EXEC model.declare_contract @id=@out, @schema=N'{"type":"object","additionalProperties":true}';
 SET @scenario=N'{"scenarioId":"'+@cap+N'","name":"'+@cap+N'","inputId":"'+@cap+N'-request","inputContract":"'+@in+N'","eventId":"'+@cap+N'-requested","eventAuthority":"'+@cap+N'.v1","outcomeId":"'+@cap+N'-result","outcomeContract":"'+@out+N'","terminal":true,"root":true,"given":"one declared request","when":"the declared provider executes","then":"the declared result is returned or the exact disposition is held"}';
 SET @operations=N'[{"operationId":"'+@cap+N'.0","kind":"invoke-port","portId":"'+@port+N'"}]';
 SET @bindings=N'[{"portId":"'+@port+N'","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":'+CONVERT(nvarchar(max),@config)+N'}]';
 EXEC model.declare_scenario @capability_id=@cap, @scenario=@scenario, @operations=@operations, @port_bindings=@bindings;
 FETCH NEXT FROM mechs INTO @cap, @src, @prov;
END
CLOSE mechs; DEALLOCATE mechs;
SELECT 'mechanic_capabilities' AS result_set, m.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id
FROM @mechs m
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+m.capability_id) COLLATE Latin1_General_100_BIN2
ORDER BY m.capability_id;
COMMIT TRANSACTION;
