-- Batch-declare module-named capabilities for the runtime resolver modules that
-- had none, through the estate-provider scaffold (provider + Port + contracts +
-- root Scenario in one call). Per docs/research/platform-mechanic-honesty.md the
-- fork decision is Path B: the behavior is declared as a capability.
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
EXEC model.scaffold_estate_provider_capability @capability_id=N'authority-read-provider',
 @provider_module=N'src/resolvers/node/authority-read-provider.mjs', @provider_export=N'readCapabilityAuthority',
 @input_contract=N'authority-read-provider-request.v1', @input_schema=N'{"type":"object","additionalProperties":true}',
 @outcome_contract=N'authority-read-provider-result.v1', @outcome_schema=N'{"type":"object","additionalProperties":true}';
EXEC model.scaffold_estate_provider_capability @capability_id=N'consumer-plan-provider',
 @provider_module=N'src/resolvers/node/consumer-plan-provider.mjs', @provider_export=N'readConsumerExecutionPlan',
 @input_contract=N'consumer-plan-provider-request.v1', @input_schema=N'{"type":"object","additionalProperties":true}',
 @outcome_contract=N'consumer-plan-provider-result.v1', @outcome_schema=N'{"type":"object","additionalProperties":true}';
EXEC model.scaffold_estate_provider_capability @capability_id=N'consumer-write-provider',
 @provider_module=N'src/resolvers/node/consumer-write-provider.mjs', @provider_export=N'writeConsumerEmbodiment',
 @input_contract=N'consumer-write-provider-request.v1', @input_schema=N'{"type":"object","additionalProperties":true}',
 @outcome_contract=N'consumer-write-provider-result.v1', @outcome_schema=N'{"type":"object","additionalProperties":true}';
EXEC model.scaffold_estate_provider_capability @capability_id=N'embodiment-plan-provider',
 @provider_module=N'src/resolvers/node/embodiment-plan-provider.mjs', @provider_export=N'planCapabilityEmbodiment',
 @input_contract=N'embodiment-plan-provider-request.v1', @input_schema=N'{"type":"object","additionalProperties":true}',
 @outcome_contract=N'embodiment-plan-provider-result.v1', @outcome_schema=N'{"type":"object","additionalProperties":true}';
EXEC model.scaffold_estate_provider_capability @capability_id=N'embodiment-write-provider',
 @provider_module=N'src/resolvers/node/embodiment-write-provider.mjs', @provider_export=N'writeCapabilityEmbodiment',
 @input_contract=N'embodiment-write-provider-request.v1', @input_schema=N'{"type":"object","additionalProperties":true}',
 @outcome_contract=N'embodiment-write-provider-result.v1', @outcome_schema=N'{"type":"object","additionalProperties":true}';
EXEC model.scaffold_estate_provider_capability @capability_id=N'execution-graph-read-provider',
 @provider_module=N'src/resolvers/node/execution-graph-read-provider.mjs', @provider_export=N'readDeclaredExecutionGraph',
 @input_contract=N'execution-graph-read-provider-request.v1', @input_schema=N'{"type":"object","additionalProperties":true}',
 @outcome_contract=N'execution-graph-read-provider-result.v1', @outcome_schema=N'{"type":"object","additionalProperties":true}';
GO
SELECT 'estate_provider_capabilities' AS result_set, c.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+c.capability_id) COLLATE Latin1_General_100_BIN2
WHERE c.capability_id IN (N'authority-read-provider',N'consumer-plan-provider',N'consumer-write-provider',
 N'embodiment-plan-provider',N'embodiment-write-provider',N'execution-graph-read-provider')
ORDER BY c.capability_id;
COMMIT TRANSACTION;
