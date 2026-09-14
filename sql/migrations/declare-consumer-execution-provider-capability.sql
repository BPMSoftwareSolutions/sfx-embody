-- Declared capability for the consumer execution provider
-- (src/resolvers/node/consumer-execution-provider.mjs#executeConsumerPlan). The
-- Port carries the same declared configuration the working execute-consumer-plan
-- capability used; the provider id is the module's own.
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
EXEC model.scaffold_capability @capability_id=N'consumer-execution-provider', @on_exists=N'REPLACE';
EXEC model.declare_contract @id=N'consumer-execution-provider-request.v1', @schema=N'{"type":"object","required":["carrier"],"properties":{"carrier":{"type":"object"}}}';
EXEC model.declare_contract @id=N'consumer-execution-provider-result.v1', @schema=N'{"type":"object","additionalProperties":true}';
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @config nvarchar(max);
SELECT @config=JSON_QUERY(d.definition_json,'$.semantics.configuration')
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.declared_id=N'execute-consumer-plan-port' COLLATE Latin1_General_100_BIN2;
IF @config IS NULL THROW 51000,'SOURCE_PORT_CONFIGURATION_ABSENT',1;
SET @config=JSON_MODIFY(@config,'$.providerId',N'consumer-execution-provider.executeConsumerPlan');
SET @config=JSON_MODIFY(@config,'$.revertedAt',NULL);
DECLARE @bindings nvarchar(max)=N'[{"portId":"consumer-execution-provider-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":'+CONVERT(nvarchar(max),@config)+N'}]';
EXEC model.declare_scenario
 @capability_id=N'consumer-execution-provider',
 @scenario=N'{"scenarioId":"consumer-execution-provider","name":"Execute a bound consumer execution plan","inputId":"consumer-execution-provider-request","inputContract":"consumer-execution-provider-request.v1","eventId":"consumer-execution-provider-requested","eventAuthority":"consumer-execution-provider.v1","outcomeId":"consumer-execution-provider-result","outcomeContract":"consumer-execution-provider-result.v1","terminal":true,"root":true,"given":"one bound consumer execution plan and its admitted authority","when":"the declared provider runs the plan under the delivery boundary","then":"the declared execution result is returned or the exact disposition is held"}',
 @operations=N'[{"operationId":"consumer-execution-provider.0","kind":"invoke-port","portId":"consumer-execution-provider-port"}]',
 @port_bindings=@bindings;
GO
SELECT 'consumer_execution_provider_capability' AS result_set, c.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.authoritySource') AS authority_source
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+c.capability_id) COLLATE Latin1_General_100_BIN2
WHERE c.capability_id=N'consumer-execution-provider';
COMMIT TRANSACTION;
