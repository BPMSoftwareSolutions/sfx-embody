-- declare-reader-display-documents.sql
--
-- W1.1 of docs/hand-authored-code-retirement-agent-strategy.md (U3 of
-- docs/display-projection-migration.md): the reader operations reveal, list,
-- find, catalogue, circuit and artifact render declared reader documents, not
-- terminal-shaped boot output.
--
-- What this migration declares:
--   1. read-capability-meaning returns the additive declared facts its display
--      document cannot derive in the expression vocabulary: featureLines (the
--      feature document's non-empty trailing-trimmed lines, in order) and
--      contractIds (the declared contract identities, ascending), plus the
--      snapshotId the read ran under. The read's other facts are unchanged.
--   2. Three display transformations, one per reader capability, each building
--      the sfx-display-document.v1 document the frontdoor delivers:
--        * read-capability-meaning-display.v1    (reveal --as meaning)
--        * list-capabilities-display.v1          (list/find/catalogue)
--        * read-retained-publication-display.v1  (circuit/artifact/reveal --as circuit)
--      read-capability-circuit already declares its own display transformation
--      (declare-read-capability-circuit.sql / extend-circuit-attestation.sql);
--      this migration does not touch it.
--   3. Each reader capability's CLI interface selects its declared display
--      transformation. The boot evaluates the declared expression and attaches
--      outcome.display.document; the terminal emits its bytes.
--
-- Parity before/after (evidence/vault-20260916/retirement/w1.1/): live reveal
-- (agent lane and equity, text and --format markdown, 215/208 and 85/78 lines)
-- and the listings (catalogue 313 rows, find-scaffold) are byte-identical to
-- the recorded before-renders.
--
-- Idempotent: content-addressed definitions and the guarded configure_interface
-- calls re-declare nothing on replay.
--
-- Default was ROLLBACK. Installed 2026-09-17 after the rollback dry run
-- (evidence/vault-20260916/retirement/w1.1/dryrun.out) and the from-transaction
-- preflight (preflight.out: reveal/list/find/catalogue documents attached, the
-- publication errors preserved, the subject invocation unchanged).
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

-- ============================== 1. THE MEANING READ'S DISPLAY FACTS ==============================
DECLARE @namespace nvarchar(400)=N'sidefx:capability:read-capability-meaning';
DECLARE @port_id nvarchar(400)=N'read-capability-meaning-port';
DECLARE @statement nvarchar(max)=N'DECLARE @scenario_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.scenarioId''),N'''');
DECLARE @capability_id nvarchar(400)=JSON_VALUE(@input,''$.capabilityId'');
DECLARE @namespace_id nvarchar(400)=JSON_VALUE(@input,''$.namespaceId'');
DECLARE @meaning nvarchar(max)=(
 SELECT g.capability_id AS capabilityId,g.namespace_id AS namespaceId,g.root_scenario_id AS rootScenarioId,
  JSON_QUERY(g.graph_source) AS graphSource,JSON_QUERY(g.documents) AS documents
 FROM analysis.capability_graph_source(CONVERT(nvarchar(400),@capability_id),1,CONVERT(nvarchar(400),@namespace_id)) g
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
IF @scenario_id IS NOT NULL
BEGIN
 DECLARE @matches bigint,@capability_version_pk bigint;
 SELECT @matches=COUNT_BIG(*),@capability_version_pk=MAX(ec.capability_version_pk)
 FROM model.estate_capability ec
 JOIN model.capability c ON c.capability_pk=ec.capability_pk
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
 WHERE ec.estate_model_pk=@estate_model_pk AND c.capability_id=@capability_id
  AND (@namespace_id IS NULL OR n.namespace_id=@namespace_id);
 IF @matches=0 THROW 51000,''CAPABILITY_NOT_FOUND'',1;
 IF @matches<>1 THROW 51000,''CAPABILITY_NAMESPACE_AMBIGUOUS'',1;
 DECLARE @selected_matches bigint,@selected_version bigint;
 SELECT @selected_matches=COUNT(DISTINCT cl.downstream_scenario_version_pk),@selected_version=MAX(cl.downstream_scenario_version_pk)
 FROM model.capability_scenario cs
 JOIN analysis.v_scenario_invocation_closure cl ON cl.capability_version_pk=cs.capability_version_pk AND cl.selected_scenario_version_pk=cs.scenario_version_pk
 JOIN model.scenario_version sv ON sv.scenario_version_pk=cl.downstream_scenario_version_pk
 JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
 WHERE cs.capability_version_pk=@capability_version_pk AND s.scenario_id=@scenario_id
 OPTION(MAXRECURSION 32767);
 IF @selected_matches=0 THROW 51000,''SCENARIO_NOT_IN_CAPABILITY'',1;
 IF @selected_matches<>1 THROW 51000,''SCENARIO_NAMESPACE_AMBIGUOUS'',1;
 DECLARE @selected_owner nvarchar(400);
 SELECT @selected_owner=c.capability_id
 FROM model.scenario_version sv JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
 JOIN model.capability c ON c.capability_pk=s.capability_pk
 WHERE sv.scenario_version_pk=@selected_version;
 DECLARE @selected_faces nvarchar(max)=(
  SELECT s.scenario_id AS scenarioId,@selected_owner AS capabilityId,
   JSON_QUERY((SELECT si.input_id AS inputId,
     JSON_QUERY((SELECT ct.contract_id AS contractId FROM model.contract_version cv
       JOIN model.contract ct ON ct.contract_pk=cv.contract_pk
       WHERE cv.contract_version_pk=si.input_contract_version_pk FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS contract
     FROM model.scenario_input si WHERE si.scenario_version_pk=sv.scenario_version_pk FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS input,
   JSON_QUERY((SELECT se.event_id AS eventId,ea.execution_authority_id AS executionAuthorityId
     FROM model.scenario_event se
     JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
     JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk
     WHERE se.scenario_version_pk=sv.scenario_version_pk FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS event,
   JSON_QUERY((SELECT so.outcome_id AS outcomeId,
     JSON_QUERY((SELECT ct.contract_id AS contractId FROM model.scenario_outcome_contract soc
       JOIN model.contract_version cv ON cv.contract_version_pk=soc.contract_version_pk
       JOIN model.contract ct ON ct.contract_pk=cv.contract_pk
       WHERE soc.scenario_version_pk=sv.scenario_version_pk FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS contract,
     CONVERT(bit,so.terminal) AS terminal
     FROM model.scenario_outcome so WHERE so.scenario_version_pk=sv.scenario_version_pk FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) AS outcome
  FROM model.scenario_version sv JOIN model.scenario s ON s.scenario_pk=sv.scenario_pk
  WHERE sv.scenario_version_pk=@selected_version
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @meaning=JSON_MODIFY(@meaning,''$.selectedScenarioId'',@scenario_id);
 SET @meaning=JSON_MODIFY(@meaning,''$.selectedScenario'',JSON_QUERY(@selected_faces));
END
-- Additive declared facts: the feature''s non-empty trailing-trimmed lines
-- (string splitting is outside the expression vocabulary) and the declared
-- contract identities in declared order. Both are read-side rows.
DECLARE @feature nvarchar(max);
SELECT @feature=JSON_VALUE(value,''$.document'')
FROM OPENJSON(COALESCE(JSON_QUERY(@meaning,''$.documents''),N''[]''))
WHERE JSON_VALUE(value,''$.entry_id'')=N''capability.feature'';
DECLARE @feature_lines nvarchar(max)=N''[]'';
IF NULLIF(@feature,N'''') IS NOT NULL
BEGIN
 WITH feature_lines AS (
  SELECT 1 AS line_no,LEFT(@feature,CHARINDEX(CHAR(10),@feature+CHAR(10))-1) AS line_text,
   STUFF(@feature,1,CHARINDEX(CHAR(10),@feature+CHAR(10)),'''') AS rest
  UNION ALL
  SELECT line_no+1,LEFT(rest,CHARINDEX(CHAR(10),rest+CHAR(10))-1),
   STUFF(rest,1,CHARINDEX(CHAR(10),rest+CHAR(10)),'''')
  FROM feature_lines WHERE rest<>''''
 )
 SELECT @feature_lines=N''[''+STRING_AGG(N''"''+STRING_ESCAPE(RTRIM(REPLACE(line_text,CHAR(13),N'''')),N''json'')+N''"'',N'','')
  WITHIN GROUP (ORDER BY line_no)+N'']''
 FROM feature_lines WHERE LTRIM(RTRIM(line_text))<>'''';
END
DECLARE @contract_ids nvarchar(max)=N''[]'';
SELECT @contract_ids=N''[''+STRING_AGG(N''"''+STRING_ESCAPE([key],N''json'')+N''"'',N'','') WITHIN GROUP (ORDER BY [key])+N'']''
FROM OPENJSON(COALESCE(JSON_QUERY(@meaning,''$.graphSource.contractAuthorities.contracts''),N''{}''));
SET @meaning=JSON_MODIFY(@meaning,''$.featureLines'',JSON_QUERY(@feature_lines));
SET @meaning=JSON_MODIFY(@meaning,''$.contractIds'',JSON_QUERY(@contract_ids));
SET @meaning=JSON_MODIFY(@meaning,''$.snapshotId'',CONVERT(nvarchar(400),@snapshot_id));
SELECT @meaning AS meaning;';
DECLARE @sem nvarchar(max),@previous_definition bigint,@previous_version bigint;
SELECT @sem=JSON_QUERY(d.definition_json,'$.semantics'),@previous_definition=d.semantic_object_definition_pk
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port_id COLLATE Latin1_General_100_BIN2;
IF @sem IS NULL THROW 51000,'READ_CAPABILITY_MEANING_PORT_NOT_DECLARED',1;
SET @sem=JSON_MODIFY(@sem,'$.configuration.statement',@statement);
DECLARE @object bigint,@definition bigint,@digest binary(32);
EXEC model.put_semantic_definition 'PORT',@namespace,@port_id,@sem,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
DECLARE @port_pk bigint=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
DECLARE @version bigint=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
IF @version IS NULL BEGIN
 INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@port_pk,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
 SET @version=SCOPE_IDENTITY();
END
SELECT @previous_version=port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@previous_definition;
IF @previous_version IS NOT NULL AND @previous_version<>@version
 UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@previous_version;

-- ============================== 2. THE DECLARED DISPLAY TRANSFORMATIONS ==============================
DECLARE @transformations TABLE (namespace_id nvarchar(400), transformation_id nvarchar(400), expression nvarchar(max));
INSERT @transformations(namespace_id,transformation_id,expression) VALUES(N'sidefx:capability:read-capability-meaning',N'read-capability-meaning-display.v1',N'{"op":"let","bindings":{"meaning":{"op":"path","from":"execution","path":"outcome"},"graph":{"op":"path","from":"meaning","path":"graphSource"},"documents":{"op":"path","from":"meaning","path":"documents"},"authorityEntry":{"op":"find","from":{"op":"path","from":"documents","path":""},"as":"entry","where":{"op":"equals","left":{"op":"path","from":"entry","path":"entry_id"},"right":{"op":"literal","value":"capability.authority.json"}}},"parsed":{"op":"try-parse-json","value":{"op":"path","from":"authorityEntry","path":"document"}},"authority":{"op":"path","from":"parsed","path":"value"},"userStory":{"op":"path","from":"authority","path":"userStory"},"experience":{"op":"path","from":"authority","path":"experience"},"selected":{"op":"path","from":"meaning","path":"selectedScenario"},"hasSelected":{"op":"every","from":{"op":"array","items":[{"op":"if","when":{"op":"path","from":"meaning","path":"selectedScenarioId"},"then":{"op":"literal","value":true},"else":{"op":"literal","value":false}},{"op":"if","when":{"op":"equals","left":{"op":"path","from":"meaning","path":"selectedScenarioId"},"right":{"op":"path","from":"meaning","path":"rootScenarioId"}},"then":{"op":"literal","value":false},"else":{"op":"literal","value":true}}]},"as":"check","where":{"op":"path","from":"check","path":""}}},"value":{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"flat-map","from":{"op":"flat-map","from":{"op":"array","items":[{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Capability  {value}","values":{"value":{"op":"if","when":{"op":"path","from":"meaning","path":"capabilityId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"meaning","path":"capabilityId"}},"then":{"op":"path","from":"meaning","path":"capabilityId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Namespace   {value}","values":{"value":{"op":"if","when":{"op":"path","from":"meaning","path":"namespaceId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"meaning","path":"namespaceId"}},"then":{"op":"path","from":"meaning","path":"namespaceId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Root        {value}","values":{"value":{"op":"if","when":{"op":"path","from":"meaning","path":"rootScenarioId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"meaning","path":"rootScenarioId"}},"then":{"op":"path","from":"meaning","path":"rootScenarioId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"if","when":{"op":"path","from":"meaning","path":"selectedScenarioId"},"then":{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Selected    {value}","values":{"value":{"op":"if","when":{"op":"path","from":"meaning","path":"selectedScenarioId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"meaning","path":"selectedScenarioId"}},"then":{"op":"path","from":"meaning","path":"selectedScenarioId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},"else":null},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"View        {value}","values":{"value":{"op":"if","when":{"op":"path","from":"view","path":""},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"view","path":""}},"then":{"op":"path","from":"view","path":""},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Snapshot    {value}","values":{"value":{"op":"if","when":{"op":"path","from":"meaning","path":"snapshotId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"meaning","path":"snapshotId"}},"then":{"op":"path","from":"meaning","path":"snapshotId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}}]},{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"blank"}}},{"op":"if","when":{"op":"path","from":"meaning","path":"featureLines"},"then":{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"literal","value":"Canonical feature"}}},"else":null},{"op":"flat-map","from":{"op":"path","from":"meaning","path":"featureLines"},"as":"featureLine","value":{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"  {line}","values":{"line":{"op":"path","from":"featureLine","path":""}}}}}}]},{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"blank"}}},{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"literal","value":"User story"}}},{"op":"if","when":{"op":"path","from":"userStory","path":""},"then":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Actor     {value}","values":{"value":{"op":"if","when":{"op":"path","from":"userStory","path":"actor"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"userStory","path":"actor"}},"then":{"op":"path","from":"userStory","path":"actor"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Intent    {value}","values":{"value":{"op":"if","when":{"op":"path","from":"userStory","path":"intent"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"userStory","path":"intent"}},"then":{"op":"path","from":"userStory","path":"intent"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Outcome   {value}","values":{"value":{"op":"if","when":{"op":"path","from":"userStory","path":"outcome"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"userStory","path":"outcome"}},"then":{"op":"path","from":"userStory","path":"outcome"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}}]},"else":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"literal","value":"The estate declares no user story for this capability. (not declared)"}}}]}}]},{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"blank"}}},{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"literal","value":"Experience"}}},{"op":"if","when":{"op":"path","from":"experience","path":""},"then":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Actor       {value}","values":{"value":{"op":"if","when":{"op":"path","from":"experience","path":"actor"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"experience","path":"actor"}},"then":{"op":"path","from":"experience","path":"actor"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Experience  {value}","values":{"value":{"op":"if","when":{"op":"path","from":"experience","path":"experienceId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"experience","path":"experienceId"}},"then":{"op":"path","from":"experience","path":"experienceId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Promise     {value}","values":{"value":{"op":"if","when":{"op":"path","from":"experience","path":"promise"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"experience","path":"promise"}},"then":{"op":"path","from":"experience","path":"promise"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"Conditions  {value}","values":{"value":{"op":"join","value":{"op":"map","from":{"op":"path","from":"experience","path":"observableConditions"},"as":"condition","value":{"op":"path","from":"condition","path":"conditionId"}},"separator":", "}}}}}]},"else":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"literal","value":"The estate declares no experience for this capability. (not declared)"}}}]}}]},{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"blank"}}},{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Scenarios ({count})","values":{"count":{"op":"length","value":{"op":"path","from":"graph","path":"scenarios"}}}}}},{"op":"flat-map","from":{"op":"path","from":"graph","path":"scenarios"},"as":"scenario","value":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"  {id}","values":{"id":{"op":"path","from":"scenario","path":"scenarioId"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"join","value":{"op":"array","items":[{"op":"format","template":"    input    {id}","values":{"id":{"op":"if","when":{"op":"path","from":"scenario","path":"input.inputId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"scenario","path":"input.inputId"}},"then":{"op":"path","from":"scenario","path":"input.inputId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"format","template":"  ({contract})","values":{"contract":{"op":"if","when":{"op":"path","from":"scenario","path":"input.contract.contractId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"scenario","path":"input.contract.contractId"}},"then":{"op":"path","from":"scenario","path":"input.contract.contractId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}]},"separator":""}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"join","value":{"op":"array","items":[{"op":"format","template":"    event    {id}","values":{"id":{"op":"if","when":{"op":"path","from":"scenario","path":"event.eventId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"scenario","path":"event.eventId"}},"then":{"op":"path","from":"scenario","path":"event.eventId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"format","template":"  ({authority})","values":{"authority":{"op":"if","when":{"op":"path","from":"scenario","path":"event.executionAuthorityId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"scenario","path":"event.executionAuthorityId"}},"then":{"op":"path","from":"scenario","path":"event.executionAuthorityId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}]},"separator":""}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"join","value":{"op":"array","items":[{"op":"format","template":"    outcome  {id}","values":{"id":{"op":"if","when":{"op":"path","from":"scenario","path":"outcome.outcomeId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"scenario","path":"outcome.outcomeId"}},"then":{"op":"path","from":"scenario","path":"outcome.outcomeId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"format","template":"  ({contract})","values":{"contract":{"op":"if","when":{"op":"path","from":"scenario","path":"outcome.contract.contractId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"scenario","path":"outcome.contract.contractId"}},"then":{"op":"path","from":"scenario","path":"outcome.contract.contractId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"if","when":{"op":"path","from":"scenario","path":"outcome.terminal"},"then":{"op":"literal","value":"  [terminal]"},"else":{"op":"literal","value":""}}]},"separator":""}}}]}}]},{"op":"array","items":[{"op":"if","when":{"op":"path","from":"hasSelected","path":""},"then":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"blank"}}},{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Selected scenario ({id})","values":{"id":{"op":"if","when":{"op":"path","from":"meaning","path":"selectedScenarioId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"meaning","path":"selectedScenarioId"}},"then":{"op":"path","from":"meaning","path":"selectedScenarioId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"  owning capability  {value}","values":{"value":{"op":"if","when":{"op":"path","from":"selected","path":"capabilityId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"selected","path":"capabilityId"}},"then":{"op":"path","from":"selected","path":"capabilityId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"join","value":{"op":"array","items":[{"op":"format","template":"  input    {id}","values":{"id":{"op":"if","when":{"op":"path","from":"selected","path":"input.inputId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"selected","path":"input.inputId"}},"then":{"op":"path","from":"selected","path":"input.inputId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"format","template":"  ({contract})","values":{"contract":{"op":"if","when":{"op":"path","from":"selected","path":"input.contract.contractId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"selected","path":"input.contract.contractId"}},"then":{"op":"path","from":"selected","path":"input.contract.contractId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}]},"separator":""}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"join","value":{"op":"array","items":[{"op":"format","template":"  event    {id}","values":{"id":{"op":"if","when":{"op":"path","from":"selected","path":"event.eventId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"selected","path":"event.eventId"}},"then":{"op":"path","from":"selected","path":"event.eventId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"format","template":"  ({authority})","values":{"authority":{"op":"if","when":{"op":"path","from":"selected","path":"event.executionAuthorityId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"selected","path":"event.executionAuthorityId"}},"then":{"op":"path","from":"selected","path":"event.executionAuthorityId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}]},"separator":""}}},{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"join","value":{"op":"array","items":[{"op":"format","template":"  outcome  {id}","values":{"id":{"op":"if","when":{"op":"path","from":"selected","path":"outcome.outcomeId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"selected","path":"outcome.outcomeId"}},"then":{"op":"path","from":"selected","path":"outcome.outcomeId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"format","template":"  ({contract})","values":{"contract":{"op":"if","when":{"op":"path","from":"selected","path":"outcome.contract.contractId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"selected","path":"outcome.contract.contractId"}},"then":{"op":"path","from":"selected","path":"outcome.contract.contractId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"if","when":{"op":"path","from":"selected","path":"outcome.terminal"},"then":{"op":"literal","value":"  [terminal]"},"else":{"op":"literal","value":""}}]},"separator":""}}}]},"else":null}]},{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"blank"}}},{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Execution plan ({count})","values":{"count":{"op":"length","value":{"op":"path","from":"graph","path":"executionAuthorities"}}}}}},{"op":"flat-map","from":{"op":"path","from":"graph","path":"executionAuthorities"},"as":"authority","value":{"op":"flat-map","from":{"op":"array","items":[{"op":"object","fields":{"part":{"op":"literal","value":"header"}}},{"op":"object","fields":{"part":{"op":"literal","value":"operations"},"operations":{"op":"path","from":"authority","path":"operations"}}}]},"as":"section","value":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"section","path":"part"},"right":{"op":"literal","value":"header"}},"then":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"join","value":{"op":"array","items":[{"op":"format","template":"  {id}","values":{"id":{"op":"if","when":{"op":"path","from":"authority","path":"id"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"authority","path":"id"}},"then":{"op":"path","from":"authority","path":"id"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"format","template":"  owning {owner}","values":{"owner":{"op":"if","when":{"op":"path","from":"authority","path":"owningScenarioId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"authority","path":"owningScenarioId"}},"then":{"op":"path","from":"authority","path":"owningScenarioId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}]},"separator":""}}}]},"else":{"op":"map","from":{"op":"path","from":"section","path":"operations"},"as":"operation","value":{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"join","value":{"op":"array","items":[{"op":"format","template":"    {kind}","values":{"kind":{"op":"if","when":{"op":"path","from":"operation","path":"kind"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"operation","path":"kind"}},"then":{"op":"path","from":"operation","path":"kind"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"literal","value":" -> "},{"op":"if","when":{"op":"path","from":"operation","path":"portId"},"then":{"op":"path","from":"operation","path":"portId"},"else":{"op":"if","when":{"op":"path","from":"operation","path":"scenarioId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"operation","path":"scenarioId"}},"then":{"op":"path","from":"operation","path":"scenarioId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}]},"separator":""}}}}}}}]},{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"blank"}}},{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Ports ({count})","values":{"count":{"op":"length","value":{"op":"path","from":"graph","path":"interfaceAuthority.portBindings"}}}}}},{"op":"map","from":{"op":"path","from":"graph","path":"interfaceAuthority.portBindings"},"as":"port","value":{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"join","value":{"op":"array","items":[{"op":"format","template":"  {id}","values":{"id":{"op":"if","when":{"op":"path","from":"port","path":"portId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"port","path":"portId"}},"then":{"op":"path","from":"port","path":"portId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}},{"op":"literal","value":"  ->  "},{"op":"if","when":{"op":"path","from":"port","path":"platformCapabilityId"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"port","path":"platformCapabilityId"}},"then":{"op":"path","from":"port","path":"platformCapabilityId"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}]},"separator":""}}}}]},{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"blank"}}},{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Contracts ({count})","values":{"count":{"op":"length","value":{"op":"path","from":"meaning","path":"contractIds"}}}}}},{"op":"map","from":{"op":"path","from":"meaning","path":"contractIds"},"as":"contractId","value":{"op":"object","fields":{"type":{"op":"literal","value":"line"},"text":{"op":"format","template":"  {id}","values":{"id":{"op":"path","from":"contractId","path":""}}}}}}]}]},"as":"group","value":{"op":"path","from":"group","path":""}},"as":"top","value":{"op":"path","from":"top","path":""}}}}}');
INSERT @transformations(namespace_id,transformation_id,expression) VALUES(N'sidefx:capability:list-capabilities',N'list-capabilities-display.v1',N'{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Capabilities ({count})","values":{"count":{"op":"length","value":{"op":"path","from":"execution","path":"outcome"}}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"list"},"items":{"op":"map","from":{"op":"path","from":"execution","path":"outcome"},"as":"item","value":{"op":"object","fields":{"text":{"op":"let","bindings":{"identity":{"op":"format","template":"{id}  {ns}","values":{"id":{"op":"path","from":"item","path":"capabilityId"},"ns":{"op":"if","when":{"op":"path","from":"item","path":"namespaceId"},"then":{"op":"path","from":"item","path":"namespaceId"},"else":{"op":"if","when":{"op":"path","from":"item","path":"capabilityVersion"},"then":{"op":"if","when":{"op":"trim","value":{"op":"path","from":"item","path":"capabilityVersion"}},"then":{"op":"path","from":"item","path":"capabilityVersion"},"else":{"op":"literal","value":"(not declared)"}},"else":{"op":"literal","value":"(not declared)"}}}}},"scenarios":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"item","path":"scenarioCount"},"right":{"op":"literal","value":1}},"then":{"op":"literal","value":"  (1 scenario)"},"else":{"op":"if","when":{"op":"path","from":"item","path":"scenarioCount"},"then":{"op":"format","template":"  ({count} scenarios)","values":{"count":{"op":"path","from":"item","path":"scenarioCount"}}},"else":{"op":"literal","value":""}}},"circuit":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"item","path":"circuitAvailable"},"right":{"op":"literal","value":true}},"then":{"op":"literal","value":"  [circuit retained]"},"else":{"op":"literal","value":""}}},"value":{"op":"join","value":{"op":"array","items":[{"op":"path","from":"identity","path":""},{"op":"path","from":"scenarios","path":""},{"op":"path","from":"circuit","path":""}]},"separator":""}}}}},"emptyText":{"op":"literal","value":"(none)"}}}]}}}');
INSERT @transformations(namespace_id,transformation_id,expression) VALUES(N'sidefx:capability:read-retained-publication',N'read-retained-publication-display.v1',N'{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"display"},"as":{"op":"literal","value":"json"},"value":{"op":"path","from":"execution","path":"outcome"}}}]}}}');
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT namespace_id,transformation_id,expression FROM @transformations;
DECLARE @tns nvarchar(400),@tid nvarchar(400),@texpr nvarchar(max);
OPEN cur;
FETCH NEXT FROM cur INTO @tns,@tid,@texpr;
WHILE @@FETCH_STATUS=0 BEGIN
 DECLARE @tsem nvarchar(max)=N'{"id":'+(SELECT '"'+STRING_ESCAPE(@tid,N'json')+'"')+',"expression":'+@texpr+N'}';
 DECLARE @tobj bigint,@tdef bigint,@tdig binary(32),@tpk bigint,@tver bigint;
 EXEC model.put_semantic_definition 'TRANSFORMATION',@tns,@tid,@tsem,@tobj OUTPUT,@tdef OUTPUT,@tdig OUTPUT;
 SET @tpk=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@tobj);
 IF @tpk IS NULL BEGIN
  INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
  SELECT namespace_pk,@tid,@tobj,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@tobj;
  SET @tpk=SCOPE_IDENTITY();
 END
 SET @tver=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@tdef);
 IF @tver IS NULL BEGIN
  INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@tpk,@tobj,@tdef,@tdig,'json-expression-tree.v1','TRANSFORMATION',@tdef,N'');
  SET @tver=SCOPE_IDENTITY();
  EXEC model.normalize_transformation_expression @tver;
 END
 FETCH NEXT FROM cur INTO @tns,@tid,@texpr;
END
CLOSE cur; DEALLOCATE cur;

-- ============================== 3. THE INTERFACES SELECT THEIR DOCUMENT ==============================
DECLARE @interfaces TABLE (capability_id nvarchar(120), cli_json nvarchar(max));
INSERT @interfaces(capability_id,cli_json) VALUES(N'read-capability-meaning',N'{"display":{"transformationId":"read-capability-meaning-display.v1","as":"text"}}');
INSERT @interfaces(capability_id,cli_json) VALUES(N'list-capabilities',N'{"display":{"transformationId":"list-capabilities-display.v1","as":"text"}}');
INSERT @interfaces(capability_id,cli_json) VALUES(N'read-retained-publication',N'{"display":{"transformationId":"read-retained-publication-display.v1","as":"json"}}');
DECLARE icur CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id,cli_json FROM @interfaces;
DECLARE @cid nvarchar(120),@cli nvarchar(max);
OPEN icur;
FETCH NEXT FROM icur INTO @cid,@cli;
WHILE @@FETCH_STATUS=0 BEGIN
 DECLARE @before nvarchar(max);
 SELECT @before=JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli')
 FROM model.estate_capability ec
 JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE ec.estate_model_pk=@estate AND ec.capability_pk=(SELECT capability_pk FROM model.capability
  WHERE capability_id=@cid AND namespace_pk=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_id=N'sidefx:capabilities'));
 IF ISNULL(JSON_VALUE(@before,'$.display.transformationId'),N'')<>JSON_VALUE(@cli,'$.display.transformationId')
 BEGIN
  DECLARE @merged nvarchar(max)=JSON_MODIFY(COALESCE(@before,N'{}'),'$.display',JSON_QUERY(@cli,'$.display'));
  EXEC model.configure_interface @capability_id=@cid,@cli_json=@merged;
 END
 FETCH NEXT FROM icur INTO @cid,@cli;
END
CLOSE icur; DEALLOCATE icur;

-- ============================== PROOF ==============================
-- The selected meaning read carries the additive declared facts.
SELECT '1_meaning_read' AS result_set, d.namespace_id, d.declared_id,
 CONVERT(bit,CASE WHEN d.definition_json LIKE N'%featureLines%' THEN 1 ELSE 0 END) AS feature_lines_declared,
 CONVERT(bit,CASE WHEN d.definition_json LIKE N'%contractIds%' THEN 1 ELSE 0 END) AS contract_ids_declared,
 CONVERT(bit,CASE WHEN d.definition_json LIKE N'%$.snapshotId%' THEN 1 ELSE 0 END) AS snapshot_declared
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@namespace AND d.declared_id=@port_id;

-- The declared transformations are selected with non-empty expressions.
SELECT '2_transformations' AS result_set, d.declared_id AS transformation_id, d.namespace_id,
 LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='TRANSFORMATION'
 AND d.declared_id IN (N'read-capability-meaning-display.v1',N'list-capabilities-display.v1',N'read-retained-publication-display.v1')
ORDER BY d.declared_id;

-- The interfaces name the declared transformations.
SELECT '3_interfaces' AS result_set, c.capability_id,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli.display.transformationId') AS display_transformation_id,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.cli.display.as') AS display_as
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE c.capability_id IN (N'read-capability-meaning',N'list-capabilities',N'read-retained-publication')
ORDER BY c.capability_id;

-- The assembled graph sources from the uncommitted transaction carry the
-- transformation the interface selects.
DECLARE @graph nvarchar(max),@cap nvarchar(400),@transform nvarchar(400);
DECLARE gcur CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id, display_transformation_id FROM (VALUES
 (N'read-capability-meaning',N'read-capability-meaning-display.v1'),
 (N'list-capabilities',N'list-capabilities-display.v1'),
 (N'read-retained-publication',N'read-retained-publication-display.v1')) v(capability_id,display_transformation_id);
OPEN gcur;
FETCH NEXT FROM gcur INTO @cap,@transform;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @graph=(SELECT graph_source FROM analysis.capability_graph_source(@cap,0,N'sidefx:capabilities'));
 SELECT '4_graph_source' AS result_set, @cap AS capability_id,
  JSON_VALUE(JSON_QUERY(@graph,'$.interfaceAuthority.interfaces[0].configuration'),'$.display.transformationId') AS interface_display,
  CONVERT(bit,CASE WHEN EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@graph,'$.semanticTransformations')) t
   WHERE JSON_VALUE(t.value,'$.id')=@transform) THEN 1 ELSE 0 END) AS transformation_present;
 FETCH NEXT FROM gcur INTO @cap,@transform;
END
CLOSE gcur; DEALLOCATE gcur;

-- The extended read runs from the uncommitted state and reports the additive
-- facts (the feature's first line and the declared contract identities).
DECLARE @read_input nvarchar(max)=N'{"capabilityId":"resolve-equity-market-price-evidence","namespaceId":"sidefx:capabilities"}';
DECLARE @reading TABLE (meaning nvarchar(max));
INSERT @reading EXEC sp_executesql @statement,N'@input nvarchar(max), @estate_model_pk bigint, @snapshot_id varchar(71)',
 @input=@read_input,@estate_model_pk=@estate,@snapshot_id=N'sha256:0000000000000000000000000000000000000000000000000000000000000000';
SELECT '5_read_preflight' AS result_set,
 JSON_VALUE(meaning,'$.capabilityId') AS capability_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(meaning,'$.featureLines'))) AS feature_lines,
 JSON_VALUE(meaning,'$.featureLines[0]') AS first_feature_line,
 JSON_QUERY(meaning,'$.contractIds') AS contract_ids,
 JSON_VALUE(meaning,'$.snapshotId') AS snapshot_id
FROM @reading;
COMMIT TRANSACTION;
