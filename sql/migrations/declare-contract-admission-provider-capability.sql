-- Declared capability for the contract admission provider
-- (src/resolvers/node/contract-admission-provider.mjs#admitDeclaredContract). Its
-- helper, consumer-authority-context.mjs, is declared by
-- declare-consumer-authority-context-capability.sql, so nothing dangles.
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
EXEC model.scaffold_capability @capability_id=N'contract-admission-provider', @on_exists=N'REPLACE';
EXEC model.declare_contract @id=N'contract-admission-provider-request.v1', @schema=N'{"type":"object","additionalProperties":true}';
EXEC model.declare_contract @id=N'contract-admission-provider-result.v1', @schema=N'{"type":"object","additionalProperties":true}';
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @config nvarchar(max);
SELECT @config=JSON_QUERY(d.definition_json,'$.semantics.configuration')
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.declared_id=N'admit-declared-contract-port' COLLATE Latin1_General_100_BIN2;
IF @config IS NULL THROW 51000,'SOURCE_PORT_CONFIGURATION_ABSENT',1;
SET @config=JSON_MODIFY(@config,'$.providerId',N'contract-admission-provider.admitDeclaredContract');
SET @config=JSON_MODIFY(@config,'$.revertedAt',NULL);
DECLARE @bindings nvarchar(max)=N'[{"portId":"contract-admission-provider-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":'+CONVERT(nvarchar(max),@config)+N'}]';
EXEC model.declare_scenario
 @capability_id=N'contract-admission-provider',
 @scenario=N'{"scenarioId":"contract-admission-provider","name":"Admit a declared contract","inputId":"contract-admission-provider-request","inputContract":"contract-admission-provider-request.v1","eventId":"contract-admission-provider-requested","eventAuthority":"contract-admission-provider.v1","outcomeId":"contract-admission-provider-result","outcomeContract":"contract-admission-provider-result.v1","terminal":true,"root":true,"given":"one declared contract admission request","when":"the declared provider admits or rejects the input under the contract authority","then":"the declared admission result is returned"}',
 @operations=N'[{"operationId":"contract-admission-provider.0","kind":"invoke-port","portId":"contract-admission-provider-port"}]',
 @port_bindings=@bindings;
GO
SELECT 'contract_admission_provider_capability' AS result_set, c.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+c.capability_id) COLLATE Latin1_General_100_BIN2
WHERE c.capability_id=N'contract-admission-provider';
COMMIT TRANSACTION;
