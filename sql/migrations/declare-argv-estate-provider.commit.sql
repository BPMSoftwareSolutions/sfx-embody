-- argv-provider through the reusable orchestrator: one document, four lanes.
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
DECLARE @document nvarchar(max)=N'{"capabilityId":"argv-provider","providerModule":"src/resolvers/node/argv-provider.mjs","providerExport":"provideArguments","description":"Read the process arguments through the declared port","input":{"contract":"argv-provider-request.v1","schema":{"type":"object","additionalProperties":false}},"outcome":{"contract":"argv-provider-result.v1","schema":{"type":"object","additionalProperties":false,"required":["arguments"],"properties":{"arguments":{"type":"array","items":{"type":"string"}}}}},"port":{"portId":"argv-reading-port","platformCapabilityId":"sda-argv-reading-port.v1"},"mechanic":{"mechanicId":"read-argv","meaning":"Read the process arguments through the declared host boundary.","effectClassification":"observation","sourceProfile":"platform-effect-provider.v1","nativeFloor":true,"inputContract":"mechanic:read-argv:input.v1","outcomeContract":"mechanic:read-argv:outcome.v1","outputField":"arguments"},"binding":{"providerId":"argv-provider.provideArguments"},"scenario":{"scenarioId":"argv-provider","name":"Read the process arguments","inputId":"argv-provider-request","inputContract":"argv-provider-request.v1","eventId":"argv-provider-requested","eventAuthority":"argv-provider.v1","outcomeId":"argv-provider-result","outcomeContract":"argv-provider-result.v1","terminal":true,"root":true,"given":"the physical command line","when":"the arguments are read through the declared port","then":"the argument list is returned or the read is held"}}';
EXEC model.declare_estate_provider @document=@document;
GO
SELECT 'argv_estate_provider' AS result_set, c.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId') AS platform_capability,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+c.capability_id) COLLATE Latin1_General_100_BIN2
WHERE c.capability_id=N'argv-provider' AND d.declared_id=N'argv-reading-port' COLLATE Latin1_General_100_BIN2;
COMMIT TRANSACTION;
