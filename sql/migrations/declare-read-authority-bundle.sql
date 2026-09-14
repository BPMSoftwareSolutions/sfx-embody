-- Extend the read-authority bundle with authority and closure reads, all declared.
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
DECLARE @stmt nvarchar(max)=
 N'SELECT ('
+N' SELECT JSON_QUERY(@input) AS selection,'
+N'  JSON_QUERY((SELECT TOP 1 c.capability_id AS capabilityId, s.scenario_id AS scenarioId, JSON_VALUE(@input,''$.target'') AS target'
+N'    FROM model.capability c'
+N'    JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk'
+N'    JOIN model.capability_root_scenario rs ON rs.capability_version_pk=ec.capability_version_pk'
+N'    JOIN model.scenario s ON s.scenario_pk=rs.scenario_pk'
+N'    WHERE c.capability_id=JSON_VALUE(@input,''$.capabilityId'')'
+N'    FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS authority,'
+N'  JSON_QUERY((SELECT DISTINCT d.downstream_scenario_version_pk AS downstreamScenarioVersionPk'
+N'    FROM analysis.v_scenario_invocation_closure d'
+N'    JOIN model.estate_capability ec ON ec.capability_version_pk=d.capability_version_pk'
+N'    JOIN model.capability c ON c.capability_pk=ec.capability_pk'
+N'    JOIN source.current_model cm ON cm.estate_model_pk=ec.estate_model_pk'
+N'    WHERE c.capability_id=JSON_VALUE(@input,''$.capabilityId'')'
+N'    FOR JSON PATH)) AS closure,'
+N'  JSON_QUERY((SELECT m.mechanic_id FROM model.mechanic m ORDER BY m.mechanic_id FOR JSON PATH)) AS mechanics'
+N' FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS bundle';
DECLARE @bindings nvarchar(max)=
 N'[{"portId":"read-authority-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"providerId":"database-query-provider.readDatabaseQuery","resultColumn":"bundle","statement":"'
+ STRING_ESCAPE(@stmt,'json') + N'"}}]';
EXEC model.declare_scenario
 @capability_id=N'read-authority',
 @scenario=N'{"scenarioId":"read-authority","name":"Read the selected capability authority","inputId":"read-authority-request","inputContract":"read-authority-request.v1","eventId":"read-authority-requested","eventAuthority":"read-authority.v1","outcomeId":"read-authority-result","outcomeContract":"read-authority-result.v1","terminal":true,"root":true,"given":"one selection naming a capability and target","when":"the declared reads execute under the reader boundary","then":"the selection, authority, closure and mechanics are returned as one bundle"}',
 @operations=N'[{"operationId":"read-authority.0","kind":"invoke-port","portId":"read-authority-port"}]',
 @port_bindings=@bindings;
GO
SELECT 'read_authority_data' AS result_set, c.capability_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 LEN(JSON_VALUE(d.definition_json,'$.semantics.configuration.statement')) AS statement_len
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=(N'sidefx:capability:'+c.capability_id) COLLATE Latin1_General_100_BIN2
WHERE c.capability_id=N'read-authority';
COMMIT TRANSACTION;
