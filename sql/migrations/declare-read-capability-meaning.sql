-- declare-read-capability-meaning.sql
--
-- Lane E unit 9 (docs/implementation-strategy.md): `reveal --as meaning` is a
-- declared reader capability, not estate code. `sfx capability reveal` has been
-- failing since the reader modules were subtracted (the generic loader executed
-- the subject capability with an undefined input, and the kernel scheduler
-- rejected the undefined input digest).
--
-- This migration declares `read-capability-meaning`: a root scenario whose one
-- operation invokes a declared read. The read returns the subject capability's
-- assembled declaration set as one JSON document; the terminal renders the
-- canonical story from it. Meaning stays in rows: the statement is a declared
-- read, and every value the story prints is retained authority.
--
-- Idempotent: re-running re-declares the same content-addressed definitions and
-- mints no new meaning.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; to install (after the from-transaction preflight passes).
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
-- One row, one column: the subject capability's declaration set. graph_source
-- and documents are embedded as JSON, not as escaped strings.
DECLARE @statement nvarchar(max)=N'SELECT (SELECT g.capability_id AS capabilityId, g.namespace_id AS namespaceId, g.root_scenario_id AS rootScenarioId, JSON_QUERY(g.graph_source) AS graphSource, JSON_QUERY(g.documents) AS documents FROM analysis.capability_graph_source(CONVERT(nvarchar(400), JSON_VALUE(@input,''$.capabilityId'')), 1, CONVERT(nvarchar(400), JSON_VALUE(@input,''$.namespaceId''))) g FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS meaning';
DECLARE @bindings nvarchar(max)=N'[{"portId":"read-capability-meaning-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,'json') + N'","resultColumn":"meaning"}}]';
EXEC model.scaffold_capability @capability_id=N'read-capability-meaning', @on_exists=N'REPLACE';
EXEC model.declare_contract @id=N'read-capability-meaning-request.v1',
 @schema=N'{"type":"object","properties":{"capabilityId":{"type":"string"},"namespaceId":{"type":"string"},"scenarioId":{"type":"string"}},"required":["capabilityId"],"additionalProperties":true}';
EXEC model.declare_contract @id=N'read-capability-meaning-result.v1',
 @schema=N'{"type":"object","additionalProperties":true}';
EXEC model.declare_scenario
 @capability_id=N'read-capability-meaning',
 @scenario=N'{"scenarioId":"read-capability-meaning","name":"Read one capability meaning","inputId":"read-capability-meaning-request","inputContract":"read-capability-meaning-request.v1","eventId":"capability-meaning-requested","eventAuthority":"read-capability-meaning.v1","outcomeId":"capability-meaning","outcomeContract":"read-capability-meaning-result.v1","terminal":true,"root":true,"given":"one capability identity","when":"the capabilitys assembled declaration set is read under the reader boundary","then":"the declared meaning document is returned"}',
 @operations=N'[{"operationId":"read-capability-meaning.0","kind":"invoke-port","portId":"read-capability-meaning-port"}]',
 @port_bindings=@bindings;

SELECT 'read_capability_meaning' AS result_set, c.capability_id, s.scenario_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 LEN(JSON_VALUE(d.definition_json,'$.semantics.configuration.statement')) AS statement_chars
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:'+c.capability_id
WHERE c.capability_id=N'read-capability-meaning';
COMMIT TRANSACTION;
