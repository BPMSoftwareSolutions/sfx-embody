-- Lane 3 of 4: DECLARED PROVIDER BINDING for argv.
-- Binds port argv-reading-port (mechanic sda-argv-reading-port.v1) to provider
-- argv-provider.provideArguments through the declared provider-binding change.
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
-- Prerequisite (lane 4): the capability and its contracts are already committed;
-- no REPLACE here, so the existing capability and its mechanic attachment stand.
GO
DECLARE @scenario nvarchar(max)=N'{"scenarioId":"argv-provider","name":"Read the process arguments","inputId":"argv-provider-request","inputContract":"argv-provider-request.v1","eventId":"argv-provider-requested","eventAuthority":"argv-provider.v1","outcomeId":"argv-provider-result","outcomeContract":"argv-provider-result.v1","terminal":true,"root":true,"given":"the physical command line","when":"the arguments are read through the declared port","then":"the argument list is returned or the read is held"}';
DECLARE @operations nvarchar(max)=N'[{"operationId":"argv-provider.0","kind":"invoke-port","portId":"argv-reading-port"}]';
DECLARE @port_bindings nvarchar(max)=N'[{"portId":"argv-reading-port","platformCapabilityId":"sda-argv-reading-port.v1","configuration":{"providerId":"argv-provider.provideArguments"}}]';
EXEC model.declare_scenario
 @capability_id=N'argv-provider',
 @scenario=@scenario,
 @operations=@operations,
 @port_bindings=@port_bindings;
GO
SELECT 'argv_provider_binding' AS result_set, c.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id,
 JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId') AS platform_capability
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+c.capability_id) COLLATE Latin1_General_100_BIN2
WHERE c.capability_id=N'argv-provider' AND d.declared_id=N'argv-reading-port' COLLATE Latin1_General_100_BIN2;
COMMIT TRANSACTION;
