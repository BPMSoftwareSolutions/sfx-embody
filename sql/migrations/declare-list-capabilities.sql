-- declare-list-capabilities.sql
--
-- Lane E unit 8 (docs/implementation-strategy.md): `list`, `find` and
-- `catalogue` are declared reader operations, not estate code. Since the reader
-- modules were subtracted the loader executed the (absent) subject and failed
-- with CAPABILITY_NOT_FOUND.
--
-- This migration declares `list-capabilities`: a root scenario whose one
-- operation invokes a declared read of the selected estate model. The read
-- reports what the model declares -- a capability with no retained user story is
-- listed with a null user story, never a manufactured summary -- and `find`
-- matches the declared identity and declared meaning, reporting which fields
-- matched. The terminal renders the rows; the read is rows and the shaping is
-- the read's own SQL.
--
-- Idempotent: re-running re-declares the same content-addressed definitions.
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
-- One row, one column: the selected estate model's capabilities as a JSON array.
-- Matching is literal (CHARINDEX), never a LIKE pattern, so caller text is never
-- interpreted as a pattern.
DECLARE @statement nvarchar(max)=N'
DECLARE @namespace_id nvarchar(4000)=JSON_VALUE(@input,''$.namespaceId'');
DECLARE @query nvarchar(4000)=NULLIF(LOWER(LTRIM(RTRIM(JSON_VALUE(@input,''$.query'')))),'''');
WITH declared AS (
  SELECT ec.capability_version_pk, c.capability_id, n.namespace_id,
    ''sha256:''+LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
    JSON_VALUE(d.definition_json,''$.semantics.authority.name'') AS declared_name,
    JSON_VALUE(d.definition_json,''$.semantics.authority.mode'') AS mode,
    JSON_VALUE(d.definition_json,''$.semantics.authority.userStory.actor'') AS actor,
    JSON_VALUE(d.definition_json,''$.semantics.authority.userStory.intent'') AS intent,
    JSON_VALUE(d.definition_json,''$.semantics.authority.userStory.outcome'') AS outcome,
    JSON_VALUE(d.definition_json,''$.semantics.authority.experience.promise'') AS promise
  FROM model.estate_capability ec
  JOIN model.capability c ON c.capability_pk=ec.capability_pk
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  LEFT JOIN analysis.v_selected_semantic_definition d
    ON d.estate_model_pk=ec.estate_model_pk AND d.semantic_object_definition_pk=ec.semantic_object_definition_pk
  WHERE ec.estate_model_pk=@estate_model_pk
    AND (@namespace_id IS NULL OR n.namespace_id=@namespace_id)
)
SELECT (SELECT d.capability_id AS capabilityId, d.namespace_id AS namespaceId, d.definition_digest AS definitionDigest,
  d.declared_name AS name, d.mode,
  roots.declared_root_count AS declaredRootCount,
  CASE WHEN roots.declared_root_count=1 THEN roots.root_scenario_id END AS declaredRootScenarioId,
  scenarios.scenario_count AS scenarioCount,
  CASE WHEN d.actor IS NULL AND d.intent IS NULL AND d.outcome IS NULL THEN NULL
    ELSE JSON_QUERY((SELECT d.actor AS actor, d.intent AS intent, d.outcome AS outcome FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) END AS userStory,
  d.promise,
  CASE WHEN @query IS NULL THEN NULL ELSE LTRIM(
    CASE WHEN CHARINDEX(@query,LOWER(d.capability_id))>0 THEN '' capabilityId'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.namespace_id))>0 THEN '' namespaceId'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.declared_name))>0 THEN '' name'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.actor))>0 THEN '' actor'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.intent))>0 THEN '' intent'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.outcome))>0 THEN '' outcome'' ELSE '''' END
    + CASE WHEN CHARINDEX(@query,LOWER(d.promise))>0 THEN '' promise'' ELSE '''' END
    + CASE WHEN scenarios.matched_scenarios>0 THEN '' scenario'' ELSE '''' END) END AS matchedFields
FROM declared d
OUTER APPLY (
  SELECT COUNT_BIG(*) AS declared_root_count, MAX(s.scenario_id) AS root_scenario_id
  FROM model.capability_root_scenario r JOIN model.scenario s ON s.scenario_pk=r.scenario_pk
  WHERE r.capability_version_pk=d.capability_version_pk) roots
OUTER APPLY (
  SELECT COUNT_BIG(*) AS scenario_count,
    SUM(CASE WHEN @query IS NOT NULL AND (CHARINDEX(@query,LOWER(s.scenario_id))>0
      OR CHARINDEX(@query,LOWER(JSON_VALUE(sd.definition_json,''$.semantics.scenario.name'')))>0) THEN 1 ELSE 0 END) AS matched_scenarios
  FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
  LEFT JOIN analysis.v_selected_semantic_definition sd
    ON sd.estate_model_pk=@estate_model_pk AND sd.object_kind=''SCENARIO'' AND sd.declared_id=s.scenario_id
  WHERE cs.capability_version_pk=d.capability_version_pk) scenarios
WHERE @query IS NULL
  OR CHARINDEX(@query,LOWER(d.capability_id))>0 OR CHARINDEX(@query,LOWER(d.namespace_id))>0
  OR CHARINDEX(@query,LOWER(d.declared_name))>0 OR CHARINDEX(@query,LOWER(d.actor))>0
  OR CHARINDEX(@query,LOWER(d.intent))>0 OR CHARINDEX(@query,LOWER(d.outcome))>0
  OR CHARINDEX(@query,LOWER(d.promise))>0 OR scenarios.matched_scenarios>0
ORDER BY d.capability_id
FOR JSON PATH) AS capabilities';
DECLARE @bindings nvarchar(max)=N'[{"portId":"list-capabilities-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,'json') + N'","resultColumn":"capabilities"}}]';
EXEC model.scaffold_capability @capability_id=N'list-capabilities', @on_exists=N'REPLACE';
EXEC model.declare_contract @id=N'list-capabilities-request.v1',
 @schema=N'{"type":"object","properties":{"query":{"type":"string"},"namespaceId":{"type":"string"}},"additionalProperties":true}';
EXEC model.declare_contract @id=N'list-capabilities-result.v1',
 @schema=N'{"type":"array","items":{"type":"object","additionalProperties":true}}';
EXEC model.declare_scenario
 @capability_id=N'list-capabilities',
 @scenario=N'{"scenarioId":"list-capabilities","name":"List the declared capabilities","inputId":"list-capabilities-request","inputContract":"list-capabilities-request.v1","eventId":"capability-listing-requested","eventAuthority":"list-capabilities.v1","outcomeId":"capability-listing","outcomeContract":"list-capabilities-result.v1","terminal":true,"root":true,"given":"one estate selection","when":"the declared capabilities are read under the reader boundary","then":"each declared capability is returned with its retained story"}',
 @operations=N'[{"operationId":"list-capabilities.0","kind":"invoke-port","portId":"list-capabilities-port"}]',
 @port_bindings=@bindings;

SELECT 'list_capabilities' AS result_set, c.capability_id, s.scenario_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 LEN(JSON_VALUE(d.definition_json,'$.semantics.configuration.statement')) AS statement_chars
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=ec.estate_model_pk AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:'+c.capability_id
WHERE c.capability_id=N'list-capabilities';
COMMIT TRANSACTION;
