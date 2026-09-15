-- select-scenario-in-declared-meaning.sql
--
-- `sfx capability reveal <id> --scenario <scenario>` selects a declared scenario
-- of the subject capability; the terminal reports the declared root and the
-- selected scenario as distinct facts. The reader that serves reveal
-- (`read-capability-meaning`) accepted a `scenarioId` in its request contract
-- but its declared read ignored it, so Root and Selected could not differ.
--
-- This migration re-declares only that one port's declared read
-- (`sidefx:capability:read-capability-meaning` / `read-capability-meaning-port`):
--
--   * no scenario in the input: the read returns exactly the fields it returned
--     before (capabilityId, namespaceId, rootScenarioId, graphSource,
--     documents);
--   * a scenario in the input: the read validates the scenario belongs to the
--     capability -- its own `capability_scenario` members plus the declared
--     invocation closure the estate assembles for it -- and appends
--     `selectedScenarioId` and `selectedScenario` (the selected scenario's
--     owning capability and its declared input/event/outcome faces with their
--     contracts). The root scenario stays reported as `rootScenarioId`.
--
-- Fail closed: an unknown capability, an unknown or foreign scenario, or an
-- ambiguous identity THROWs; the read never substitutes the root for a
-- selection it cannot substantiate.
--
-- Idempotent: a second run re-writes the same content-addressed definition and
-- re-points the same invocation; no meaning is minted twice.
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
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @namespace nvarchar(400)=N'sidefx:capability:read-capability-meaning';
DECLARE @port_id nvarchar(400)=N'read-capability-meaning-port';
-- The declared read, authored here as rows. One result set, one column: the
-- subject capability's meaning, with the selected scenario appended when the
-- caller selected one.
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
UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@previous_version;

SELECT 'read_port_redefined' AS result_set, d.namespace_id, d.declared_id,
 d.semantic_object_definition_pk, LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 LEN(JSON_QUERY(d.definition_json,'$.semantics.configuration')) AS configuration_chars,
 CONVERT(bit,CASE WHEN d.definition_json LIKE N'%selectedScenarioId%' THEN 1 ELSE 0 END) AS selects_scenario,
 CONVERT(bit,CASE WHEN d.definition_json LIKE N'%SELECT @meaning AS meaning;%' THEN 1 ELSE 0 END) AS statement_tail_present
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port_id COLLATE Latin1_General_100_BIN2;
SELECT 'invocation_remapped' AS result_set, @previous_definition AS previous_definition_pk,
 @previous_version AS previous_port_version_pk, @definition AS selected_definition_pk, @version AS selected_port_version_pk,
 (SELECT COUNT(*) FROM model.operation_port_invocation i WHERE i.port_version_pk=@version) AS invocations_on_selected_port_version;
COMMIT TRANSACTION;
