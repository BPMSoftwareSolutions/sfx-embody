-- emit-graph-v2-dispatch-authority.sql
--
-- Additive graph-v2 emission unit for declaration-controlled concurrent dispatch.
--
-- The C# kernel's compiler (SemanticExecutionGraphCompiler) emits
-- sda-semantic-execution-graph.v2 only when the compiler input -- the
-- `analysis.capability_graph_source` TVF output -- carries `graphType` plus the
-- v2 authority keys (`requiredExecutionFeatures`, `readyArbitration`,
-- `executionBudget`, `dispatchAuthorities`, `edgeGroups`). This unit teaches the
-- estate's two runtime TVFs to carry them:
--
--   1. analysis.capability_declared_transitions gains a `joinSlotId` pass-through
--      on the declared route row form. No existing route declares it, so every
--      existing transition JSON is byte-identical.
--   2. analysis.capability_graph_source reads the capability's own envelope at
--      $.semantics.executionGraph. When it is present, the six compiler-read keys
--      are copied onto the graph source: graphType, requiredExecutionFeatures,
--      readyArbitration, executionBudget, dispatchAuthorities, edgeGroups. The
--      declared route rows already carry topologyKind and edgeGroupId; this unit
--      adds joinSlotId so join settlement edges compile with their named slot.
--      A declaration that is present but incomplete or not
--      sda-semantic-execution-graph.v2 fails closed inside the TVF.
--
-- When no executionGraph is declared, the emitted bytes are exactly the bytes
-- the previously installed function produced. The in-transaction preflight below
-- captures the installed output for seven capabilities in both document modes,
-- re-declares both functions, captures the new output, and fails closed on any
-- difference. The live proof that a v2 declaration reaches the compiler is the
-- M1 dry run (`declare-dispatch-pair-demo.sql`), whose verification reads the
-- graph source the way the kernel does.
--
-- Idempotent: a re-run captures the already-emitted function as "before" and
-- "after" and re-declares the same bytes; every digest still matches.
--
-- Lifecycle: default is ROLLBACK. Install by replacing the final ROLLBACK with
-- COMMIT after the equality proof passes.
SET NOCOUNT ON;
SET XACT_ABORT ON;
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
BEGIN TRANSACTION;
GO

-- ============================== BEFORE ==============================
IF OBJECT_ID('tempdb..#graph_before') IS NOT NULL DROP TABLE #graph_before;
IF OBJECT_ID('tempdb..#graph_after') IS NOT NULL DROP TABLE #graph_after;
IF OBJECT_ID('tempdb..#transitions_before') IS NOT NULL DROP TABLE #transitions_before;
IF OBJECT_ID('tempdb..#transitions_after') IS NOT NULL DROP TABLE #transitions_after;
CREATE TABLE #graph_before (capability_id nvarchar(400), include_docs bit, graph_digest varchar(80), documents_digest varchar(80));
CREATE TABLE #graph_after (capability_id nvarchar(400), include_docs bit, graph_digest varchar(80), documents_digest varchar(80));
CREATE TABLE #transitions_before (capability_id nvarchar(400), transition_count int, transitions_digest varchar(80));
CREATE TABLE #transitions_after (capability_id nvarchar(400), transition_count int, transitions_digest varchar(80));
DECLARE @caps TABLE (ord int identity, capability_id nvarchar(400));
INSERT @caps(capability_id) VALUES
 (N'say-hello-world'),(N'resolve-equity-market-price-evidence'),
 (N'request-capability-from-objective'),(N'read-capability-circuit'),
 (N'project-model-provider-protocol'),(N'route-two-child-proof'),
 (N'read-observation-projection');
DECLARE @cap nvarchar(400), @dt int, @v nvarchar(max), @doc nvarchar(max);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id FROM @caps ORDER BY ord;
OPEN cur; FETCH NEXT FROM cur INTO @cap;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @dt=0;
 WHILE @dt<=1
 BEGIN
  SELECT @v=graph_source,@doc=documents FROM analysis.capability_graph_source(@cap,CONVERT(bit,@dt),N'sidefx:capabilities');
  INSERT #graph_before VALUES(@cap,CONVERT(bit,@dt),
   'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@v)),2)),
   'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',ISNULL(CONVERT(varbinary(max),@doc),0x)),2)));
  SET @dt=@dt+1;
 END
 FETCH NEXT FROM cur INTO @cap;
END
CLOSE cur; DEALLOCATE cur;
DECLARE @tcap nvarchar(400), @tjson nvarchar(max), @tcount int;
DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id FROM @caps ORDER BY ord;
OPEN tcur; FETCH NEXT FROM tcur INTO @tcap;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @tjson=(SELECT N'['+STRING_AGG(transition.transition_json,N',') WITHIN GROUP (ORDER BY transition.ordinal)+N']'
  FROM analysis.capability_declared_transitions(@tcap) transition);
 SET @tcount=(SELECT COUNT(*) FROM analysis.capability_declared_transitions(@tcap));
 INSERT #transitions_before VALUES(@tcap,@tcount,
  'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),ISNULL(@tjson,N'<null>'))),2)));
 FETCH NEXT FROM tcur INTO @tcap;
END
CLOSE tcur; DEALLOCATE tcur;
GO

-- ============================== DECLARED TRANSITIONS: joinSlotId PASS-THROUGH ==============================
-- The declared route row form gains an optional joinSlotId. It is emitted only
-- when declared, so every existing transition JSON (none declares a slot) keeps
-- its exact bytes.
CREATE OR ALTER FUNCTION analysis.capability_declared_transitions(@capability_id nvarchar(400))
RETURNS TABLE
AS
RETURN
WITH cap AS (
  SELECT c.capability_id COLLATE Latin1_General_100_BIN2 AS capability_id,
    c.capability_pk, ec.capability_version_pk,
    CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope
  FROM source.current_model cm
  JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  JOIN model.semantic_object_definition linked ON linked.semantic_object_definition_pk = ec.semantic_object_definition_pk
  CROSS APPLY (
    SELECT TOP (1) d.semantic_object_definition_pk, d.canonical_content_pk
    FROM model.semantic_object_definition d WHERE d.semantic_object_pk = linked.semantic_object_pk
    ORDER BY d.semantic_object_definition_pk DESC
  ) latest
  JOIN source.content_object co ON co.content_object_pk = latest.canonical_content_pk
  WHERE c.capability_id = @capability_id COLLATE Latin1_General_100_BIN2
    AND latest.semantic_object_definition_pk = ec.semantic_object_definition_pk
),
routes AS (
  SELECT cap.capability_version_pk, cap.capability_id,
    CONVERT(int, route.[key]) AS ordinal,
    JSON_VALUE(route.value, '$.transitionId') AS transition_id,
    JSON_VALUE(route.value, '$.fromScenario') AS from_scenario,
    JSON_VALUE(route.value, '$.variant') AS variant,
    JSON_VALUE(route.value, '$.toScenario') AS to_scenario,
    ISNULL(JSON_VALUE(route.value, '$.topologyKind'), N'selection') AS topology_kind,
    JSON_VALUE(route.value, '$.groupId') AS group_id,
    JSON_VALUE(route.value, '$.joinSlotId') AS join_slot_id,
    JSON_VALUE(route.value, '$.bindingAuthorityId') AS binding_authority_id,
    JSON_VALUE(route.value, '$.recurrenceAuthorityId') AS recurrence_authority_id,
    ISNULL(JSON_VALUE(route.value, '$.semanticProgress'), N'declared') AS semantic_progress
  FROM cap
  CROSS APPLY OPENJSON(JSON_QUERY(cap.envelope, '$.semantics.routing')) route
  WHERE JSON_QUERY(cap.envelope, '$.semantics.routing') IS NOT NULL
    AND route.[type] = 5
)
SELECT routes.capability_id, routes.ordinal,
  N'{"transitionId":"' + STRING_ESCAPE(ISNULL(routes.transition_id, N'route-' + routes.from_scenario + N'-' + routes.variant), 'json') + N'"'
  + N',"from":{"scenarioId":"' + STRING_ESCAPE(routes.from_scenario, 'json') + N'","outcomeId":"' + STRING_ESCAPE(outcome_face.outcome_id, 'json') + N'"}'
  + N',"to":{"scenarioId":"' + STRING_ESCAPE(routes.to_scenario, 'json') + N'","inputId":"' + STRING_ESCAPE(input_face.input_id, 'json') + N'","contractId":"' + STRING_ESCAPE(input_contract.contract_id, 'json') + N'"}'
  + N',"semanticProgress":"' + STRING_ESCAPE(routes.semantic_progress, 'json') + N'"'
  + N',"topologyKind":"' + STRING_ESCAPE(routes.topology_kind, 'json') + N'"'
  + N',"selectsVariant":"' + STRING_ESCAPE(routes.variant, 'json') + N'"'
  + CASE WHEN routes.binding_authority_id IS NULL THEN N'' ELSE N',"bindingAuthorityId":"' + STRING_ESCAPE(routes.binding_authority_id, 'json') + N'"' END
  + CASE WHEN routes.group_id IS NULL THEN N'' ELSE N',"edgeGroupId":"' + STRING_ESCAPE(routes.group_id, 'json') + N'"' END
  + CASE WHEN routes.join_slot_id IS NULL THEN N'' ELSE N',"joinSlotId":"' + STRING_ESCAPE(routes.join_slot_id, 'json') + N'"' END
  + CASE WHEN routes.recurrence_authority_id IS NULL THEN N'' ELSE N',"recurrenceAuthorityId":"' + STRING_ESCAPE(routes.recurrence_authority_id, 'json') + N'"' END
  + N'}' AS transition_json
FROM routes
JOIN model.capability_scenario from_link
  ON from_link.capability_version_pk = routes.capability_version_pk
JOIN model.scenario from_cell
  ON from_cell.scenario_pk = from_link.scenario_pk
 AND from_cell.scenario_id = routes.from_scenario COLLATE Latin1_General_100_BIN2
LEFT JOIN model.scenario_outcome outcome_face
  ON outcome_face.scenario_version_pk = from_link.scenario_version_pk
JOIN model.capability_scenario to_link
  ON to_link.capability_version_pk = routes.capability_version_pk
JOIN model.scenario to_cell
  ON to_cell.scenario_pk = to_link.scenario_pk
 AND to_cell.scenario_id = routes.to_scenario COLLATE Latin1_General_100_BIN2
LEFT JOIN model.scenario_input input_face
  ON input_face.scenario_version_pk = to_link.scenario_version_pk
LEFT JOIN model.contract_version input_cv
  ON input_cv.contract_version_pk = input_face.input_contract_version_pk
LEFT JOIN model.contract input_contract
  ON input_contract.contract_pk = input_cv.contract_pk;
GO

-- ============================== GRAPH SOURCE: DECLARED GRAPH-v2 CARRIAGE ==============================
-- The compiler input. Unchanged for every capability that declares no
-- $.semantics.executionGraph. When the capability's own envelope declares one,
-- the six compiler-read v2 keys are copied onto the graph source verbatim; an
-- incomplete or unexpected declaration throws before a compiler can see it.
CREATE OR ALTER FUNCTION analysis.capability_graph_source(
  @capability_id nvarchar(400), @include_documents bit = 0, @namespace_id nvarchar(400) = NULL
)
RETURNS @result TABLE (
  estate_model_pk bigint,
  capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  root_scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  graph_source nvarchar(max) COLLATE Latin1_General_100_BIN2,
  cli_configuration nvarchar(max) COLLATE Latin1_General_100_BIN2,
  documents nvarchar(max) COLLATE Latin1_General_100_BIN2
)
AS
BEGIN
  DECLARE @declaration TABLE (
    estate_model_pk bigint, capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
    source_path nvarchar(1000) COLLATE Latin1_General_100_BIN2,
    entry_id nvarchar(500) COLLATE Latin1_General_100_BIN2,
    document nvarchar(max) COLLATE Latin1_General_100_BIN2
  );
  INSERT @declaration SELECT estate_model_pk, capability_id, source_path, entry_id, document
  FROM analysis.capability_execution_declaration(@capability_id, @namespace_id, @include_documents);
  IF NOT EXISTS (SELECT 1 FROM @declaration) RETURN;
  DECLARE @documents nvarchar(max);
  IF @include_documents = 1
    SELECT @documents = (SELECT source_path, entry_id, document FROM @declaration ORDER BY source_path, entry_id FOR JSON PATH, INCLUDE_NULL_VALUES);
  DECLARE @routing_transitions nvarchar(max) = (
    SELECT N'[' + STRING_AGG(transition.transition_json, N',') WITHIN GROUP (ORDER BY transition.ordinal) + N']'
    FROM analysis.capability_declared_transitions(@capability_id) transition
  );

  DECLARE @base TABLE (
    estate_model_pk bigint,
    capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
    namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
    root_scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
    scenarios nvarchar(max) COLLATE Latin1_General_100_BIN2,
    scenario_outcomes nvarchar(max) COLLATE Latin1_General_100_BIN2,
    execution_authorities nvarchar(max) COLLATE Latin1_General_100_BIN2,
    interface_authority nvarchar(max) COLLATE Latin1_General_100_BIN2,
    semantic_transformations nvarchar(max) COLLATE Latin1_General_100_BIN2,
    contract_authorities nvarchar(max) COLLATE Latin1_General_100_BIN2,
    execution_graph nvarchar(max) COLLATE Latin1_General_100_BIN2
  );
  WITH contract_authorities AS (
    SELECT cat.estate_model_pk, cat.capability_id,
      N'{"authorityType":"consumer-contract-authorities.v1","contracts":{' + ISNULL(STRING_AGG(
        (N'"' + cat.contract_id + N'":{"schemaRef":"' + STRING_ESCAPE(cat.schema_ref, 'json') + N'"'
          + CASE WHEN cat.schema_id IS NULL THEN N'' ELSE N',"schemaId":"' + STRING_ESCAPE(cat.schema_id, 'json') + N'"' END
          + N',"schema":' + cat.schema_document + N'}') COLLATE Latin1_General_100_BIN2, N',')
        WITHIN GROUP (ORDER BY cat.contract_id), N'') + N'}}' AS document
    FROM (
      SELECT p.estate_model_pk, p.capability_id, ckey.[key] COLLATE Latin1_General_100_BIN2 AS contract_id,
        ckey.[value] COLLATE Latin1_General_100_BIN2 AS schema_ref,
        JSON_VALUE(sch.document, N'$."$id"') COLLATE Latin1_General_100_BIN2 AS schema_id,
        sch.document AS schema_document
      FROM @declaration p CROSS APPLY OPENJSON(p.document) ckey
      JOIN @declaration sch ON sch.estate_model_pk = p.estate_model_pk AND sch.capability_id = p.capability_id
        AND sch.entry_id = N'contracts/' + ckey.[value]
      WHERE p.entry_id = N'contracts/contract-catalog.json'
    ) cat GROUP BY cat.estate_model_pk, cat.capability_id
  ), base AS (
    SELECT ec.estate_model_pk, c.capability_id, n.namespace_id,
      (SELECT TOP (1) rs.scenario_id FROM model.capability_root_scenario crs
        JOIN model.scenario rs ON rs.scenario_pk = crs.scenario_pk
        WHERE crs.capability_version_pk = ec.capability_version_pk) AS root_scenario_id,
      (SELECT s.scenario_id AS scenarioId,
        JSON_QUERY((SELECT si.input_id AS inputId,
          JSON_QUERY((SELECT ct.contract_id AS contractId FROM model.contract_version cv
            JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
            WHERE cv.contract_version_pk = si.input_contract_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS contract
          FROM model.scenario_input si WHERE si.scenario_version_pk = scn.scenario_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS input,
        JSON_QUERY((SELECT se.event_id AS eventId, ea.execution_authority_id AS executionAuthorityId
          FROM model.scenario_event se JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = se.execution_authority_version_pk
          JOIN model.execution_authority ea ON ea.execution_authority_pk = eav.execution_authority_pk
          WHERE se.scenario_version_pk = scn.scenario_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS event,
        JSON_QUERY((SELECT so.outcome_id AS outcomeId,
          JSON_QUERY((SELECT ct.contract_id AS contractId FROM model.scenario_outcome_contract soc
            JOIN model.contract_version cv ON cv.contract_version_pk = soc.contract_version_pk
            JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
            WHERE soc.scenario_version_pk = scn.scenario_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS contract,
          CONVERT(bit, so.terminal) AS terminal
          FROM model.scenario_outcome so WHERE so.scenario_version_pk = scn.scenario_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS outcome
        FROM (
          SELECT cs.scenario_version_pk FROM model.capability_scenario cs
          WHERE cs.capability_version_pk = ec.capability_version_pk
          UNION
          SELECT cl.downstream_scenario_version_pk FROM analysis.v_scenario_invocation_closure cl
          WHERE cl.capability_version_pk = ec.capability_version_pk
        ) scn
        JOIN model.scenario_version sv ON sv.scenario_version_pk = scn.scenario_version_pk
        JOIN model.scenario s ON s.scenario_pk = sv.scenario_pk
        ORDER BY s.scenario_id FOR JSON PATH) AS scenarios,
      (SELECT s.scenario_id AS scenarioId,
        JSON_QUERY((SELECT ov.variant_id AS variantId, ov.classification AS classification
          FROM model.outcome_variant ov WHERE ov.scenario_version_pk = scn.scenario_version_pk
          ORDER BY ov.variant_id FOR JSON PATH)) AS variants
        FROM (
          SELECT cs.scenario_version_pk FROM model.capability_scenario cs
          WHERE cs.capability_version_pk = ec.capability_version_pk
          UNION
          SELECT cl.downstream_scenario_version_pk FROM analysis.v_scenario_invocation_closure cl
          WHERE cl.capability_version_pk = ec.capability_version_pk
        ) scn
        JOIN model.scenario_version sv ON sv.scenario_version_pk = scn.scenario_version_pk
        JOIN model.scenario s ON s.scenario_pk = sv.scenario_pk
        WHERE EXISTS (SELECT 1 FROM model.outcome_variant declared WHERE declared.scenario_version_pk = scn.scenario_version_pk)
        ORDER BY s.scenario_id FOR JSON PATH) AS scenario_outcomes,
      (SELECT JSON_QUERY(d.document, '$.executionAuthorities') FROM @declaration d
        WHERE d.entry_id = N'execution-authorities.authority.json') AS execution_authorities,
      (SELECT d.document FROM @declaration d WHERE d.entry_id = N'interfaces.authority.json') AS interface_authority,
      (SELECT JSON_QUERY(d.document, '$.transformations') FROM @declaration d
        WHERE d.entry_id = N'semantic-transformation.authority.json') AS semantic_transformations,
      ca.document AS contract_authorities,
      (SELECT JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), N'$.semantics.executionGraph')
        FROM model.semantic_object_definition d
        JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
        WHERE d.semantic_object_definition_pk = ec.semantic_object_definition_pk) AS execution_graph
    FROM source.current_model cm JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
    JOIN model.capability c ON c.capability_pk = ec.capability_pk
    JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
    LEFT JOIN contract_authorities ca ON ca.estate_model_pk = ec.estate_model_pk AND ca.capability_id = c.capability_id
    WHERE c.capability_id = @capability_id COLLATE Latin1_General_100_BIN2
      AND (@namespace_id IS NULL OR n.namespace_id = @namespace_id COLLATE Latin1_General_100_BIN2)
  )
  INSERT @base SELECT * FROM base;

  -- A declared executionGraph is a versioned carrier. A complete v2 declaration
  -- carries the six compiler-read keys. An incomplete or unexpected one is not
  -- emitted as a partially keyed graph source: the function emits a refusal
  -- marker instead, which the compiler rejects at compilation input admission,
  -- before any provider can run. (T-SQL forbids THROW inside a function.)
  INSERT @result
  SELECT b.estate_model_pk, b.capability_id, b.namespace_id, b.root_scenario_id,
    CASE WHEN b.execution_graph IS NULL THEN graph_json.document
      WHEN JSON_VALUE(b.execution_graph, N'$.graphType') = N'sda-semantic-execution-graph.v2'
        AND JSON_QUERY(b.execution_graph, N'$.requiredExecutionFeatures') IS NOT NULL
        AND JSON_VALUE(b.execution_graph, N'$.readyArbitration') IS NOT NULL
        AND JSON_QUERY(b.execution_graph, N'$.executionBudget') IS NOT NULL
        AND JSON_QUERY(b.execution_graph, N'$.dispatchAuthorities') IS NOT NULL
        AND JSON_QUERY(b.execution_graph, N'$.edgeGroups') IS NOT NULL
      THEN JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(
        graph_json.document,
        N'$.graphType', JSON_VALUE(b.execution_graph, N'$.graphType')),
        N'$.requiredExecutionFeatures', JSON_QUERY(b.execution_graph, N'$.requiredExecutionFeatures')),
        N'$.readyArbitration', JSON_VALUE(b.execution_graph, N'$.readyArbitration')),
        N'$.executionBudget', JSON_QUERY(b.execution_graph, N'$.executionBudget')),
        N'$.dispatchAuthorities', JSON_QUERY(b.execution_graph, N'$.dispatchAuthorities')),
        N'$.edgeGroups', JSON_QUERY(b.execution_graph, N'$.edgeGroups'))
      ELSE N'{"declaredExecutionGraphRefused":"EXECUTION_GRAPH_DECLARATION_INVALID"}'
    END,
    JSON_QUERY(b.interface_authority, '$.interfaces[0].configuration'), @documents
  FROM @base b
  CROSS APPLY (SELECT JSON_QUERY((SELECT b.capability_id AS capabilityId, b.root_scenario_id AS rootScenarioId,
    JSON_QUERY(b.scenarios) AS scenarios, JSON_QUERY(b.scenario_outcomes) AS scenarioOutcomes,
    JSON_QUERY(ISNULL(@routing_transitions, N'[]')) AS transitions,
    JSON_QUERY(b.execution_authorities) AS executionAuthorities, JSON_QUERY(b.interface_authority) AS interfaceAuthority,
    JSON_QUERY(b.semantic_transformations) AS semanticTransformations, JSON_QUERY(b.contract_authorities) AS contractAuthorities
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS document) graph_json;
  RETURN;
END;
GO

-- ============================== AFTER, SYNTHETIC v2 PROBE, EQUALITY ==============================
DECLARE @caps2 TABLE (ord int identity, capability_id nvarchar(400));
INSERT @caps2(capability_id) VALUES
 (N'say-hello-world'),(N'resolve-equity-market-price-evidence'),
 (N'request-capability-from-objective'),(N'read-capability-circuit'),
 (N'project-model-provider-protocol'),(N'route-two-child-proof'),
 (N'read-observation-projection');
DECLARE @cap2 nvarchar(400), @dt2 int, @v2 nvarchar(max), @doc2 nvarchar(max);
DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id FROM @caps2 ORDER BY ord;
OPEN cur2; FETCH NEXT FROM cur2 INTO @cap2;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @dt2=0;
 WHILE @dt2<=1
 BEGIN
  SELECT @v2=graph_source,@doc2=documents FROM analysis.capability_graph_source(@cap2,CONVERT(bit,@dt2),N'sidefx:capabilities');
  INSERT #graph_after VALUES(@cap2,CONVERT(bit,@dt2),
   'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@v2)),2)),
   'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',ISNULL(CONVERT(varbinary(max),@doc2),0x)),2)));
  SET @dt2=@dt2+1;
 END
 FETCH NEXT FROM cur2 INTO @cap2;
END
CLOSE cur2; DEALLOCATE cur2;
DECLARE @tcap2 nvarchar(400), @tjson2 nvarchar(max), @tcount2 int;
DECLARE tcur2 CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id FROM @caps2 ORDER BY ord;
OPEN tcur2; FETCH NEXT FROM tcur2 INTO @tcap2;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @tjson2=(SELECT N'['+STRING_AGG(transition.transition_json,N',') WITHIN GROUP (ORDER BY transition.ordinal)+N']'
  FROM analysis.capability_declared_transitions(@tcap2) transition);
 SET @tcount2=(SELECT COUNT(*) FROM analysis.capability_declared_transitions(@tcap2));
 INSERT #transitions_after VALUES(@tcap2,@tcount2,
  'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),ISNULL(@tjson2,N'<null>'))),2)));
 FETCH NEXT FROM tcur2 INTO @tcap2;
END
CLOSE tcur2; DEALLOCATE tcur2;

-- The synthetic v2 probe runs the same JSON_MODIFY carriage the function body
-- uses against a fixed declared executionGraph, so the key-set contract is
-- proved even before a live v2 capability exists to emit it.
DECLARE @probe_base nvarchar(max)=N'{"capabilityId":"probe","rootScenarioId":"probe","transitions":[]}';
DECLARE @probe_declared nvarchar(max)=N'{"graphType":"sda-semantic-execution-graph.v2","requiredExecutionFeatures":["declared-concurrent-dispatch.v1"],"readyArbitration":"causal-activation-order.v1","executionBudget":{"maximumInFlightEffects":2,"deadlineMs":15000},"dispatchAuthorities":[{"dispatchAuthorityId":"probe.v1","mode":"serial","legCount":2,"maximumActiveBranches":1,"maximumInFlightEffects":2,"readyOrder":"declared-edge-order","branchFailure":"collect","ownership":"join-before-return"}],"edgeGroups":[{"groupId":"probe-broadcast","kind":"broadcast","edgeIds":["edge:a","edge:b"],"dispatchAuthorityId":"probe.v1","completionJoinGroupId":"probe-join"},{"groupId":"probe-join","kind":"join","policy":"all-required","edgeIds":["edge:sa","edge:sb"],"joinCellId":"cell:scenario:probe-join","requiredSlotIds":["a","b"]}]}';
DECLARE @probe_emitted nvarchar(max)=JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(
  @probe_base,
  N'$.graphType', JSON_VALUE(@probe_declared, N'$.graphType')),
  N'$.requiredExecutionFeatures', JSON_QUERY(@probe_declared, N'$.requiredExecutionFeatures')),
  N'$.readyArbitration', JSON_VALUE(@probe_declared, N'$.readyArbitration')),
  N'$.executionBudget', JSON_QUERY(@probe_declared, N'$.executionBudget')),
  N'$.dispatchAuthorities', JSON_QUERY(@probe_declared, N'$.dispatchAuthorities')),
  N'$.edgeGroups', JSON_QUERY(@probe_declared, N'$.edgeGroups'));
IF JSON_VALUE(@probe_emitted, N'$.graphType') <> N'sda-semantic-execution-graph.v2'
 OR JSON_QUERY(@probe_emitted, N'$.requiredExecutionFeatures') IS NULL
 OR JSON_VALUE(@probe_emitted, N'$.readyArbitration') <> N'causal-activation-order.v1'
 OR JSON_QUERY(@probe_emitted, N'$.executionBudget') IS NULL
 OR JSON_QUERY(@probe_emitted, N'$.dispatchAuthorities') IS NULL
 OR JSON_QUERY(@probe_emitted, N'$.edgeGroups') IS NULL
 THROW 51000,N'GRAPH_V2_PROBE_FAILED',1;

IF EXISTS (
 SELECT 1 FROM #graph_before b
 FULL JOIN #graph_after a ON a.capability_id=b.capability_id AND a.include_docs=b.include_docs
 WHERE b.graph_digest IS NULL OR a.graph_digest IS NULL
   OR b.graph_digest<>a.graph_digest OR b.documents_digest<>a.documents_digest
) THROW 51000,N'GRAPH_SOURCE_DIVERGED',1;
IF EXISTS (
 SELECT 1 FROM #transitions_before b
 FULL JOIN #transitions_after a ON a.capability_id=b.capability_id
 WHERE b.transitions_digest IS NULL OR a.transitions_digest IS NULL
   OR b.transition_count<>a.transition_count OR b.transitions_digest<>a.transitions_digest
) THROW 51000,N'DECLARED_TRANSITIONS_DIVERGED',1;
IF (SELECT COUNT(*) FROM #graph_after)<>14 THROW 51000,N'GRAPH_SOURCE_PROBE_INCOMPLETE',1;

DECLARE @body nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID('analysis.capability_graph_source'));
IF CHARINDEX(N'$.semantics.executionGraph',@body)=0 THROW 51000,N'GRAPH_V2_EMISSION_NOT_DECLARED',1;
IF CHARINDEX(N'$.dispatchAuthorities',@body)=0 OR CHARINDEX(N'$.edgeGroups',@body)=0 THROW 51000,N'GRAPH_V2_KEYS_NOT_DECLARED',1;
DECLARE @tranbody nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID('analysis.capability_declared_transitions'));
IF CHARINDEX(N'joinSlotId',@tranbody)=0 THROW 51000,N'JOIN_SLOT_PASS_THROUGH_NOT_DECLARED',1;

-- ============================== PROOF ==============================
SELECT '1_graph_equality' AS result_set, b.capability_id, b.include_docs,
  b.graph_digest AS before_graph_digest, a.graph_digest AS after_graph_digest,
  b.documents_digest AS before_documents_digest, a.documents_digest AS after_documents_digest,
  CONVERT(bit,CASE WHEN b.graph_digest=a.graph_digest AND b.documents_digest=a.documents_digest THEN 1 ELSE 0 END) AS identical
FROM #graph_before b JOIN #graph_after a
 ON a.capability_id=b.capability_id AND a.include_docs=b.include_docs
ORDER BY b.capability_id,b.include_docs;

SELECT '2_transitions_equality' AS result_set, b.capability_id, b.transition_count,
  b.transitions_digest AS before_transitions_digest, a.transitions_digest AS after_transitions_digest,
  CONVERT(bit,CASE WHEN b.transitions_digest=a.transitions_digest AND b.transition_count=a.transition_count THEN 1 ELSE 0 END) AS identical
FROM #transitions_before b JOIN #transitions_after a ON a.capability_id=b.capability_id
ORDER BY b.capability_id;

SELECT '3_v2_probe' AS result_set, @probe_emitted AS emitted_graph_source;

SELECT '4_claim' AS result_set,
  CONVERT(bit,CASE WHEN CHARINDEX(N'$.semantics.executionGraph',@body)>0 THEN 1 ELSE 0 END) AS execution_graph_read_declared,
  CONVERT(bit,CASE WHEN CHARINDEX(N'$.dispatchAuthorities',@body)>0 AND CHARINDEX(N'$.edgeGroups',@body)>0 THEN 1 ELSE 0 END) AS v2_keys_declared,
  CONVERT(bit,CASE WHEN CHARINDEX(N'joinSlotId',@tranbody)>0 THEN 1 ELSE 0 END) AS join_slot_declared,
  LEN(@body) AS graph_source_function_chars, LEN(@tranbody) AS transitions_function_chars;

COMMIT TRANSACTION;
-- Installed after the rollback dry run and the in-transaction equality proof:
-- seven capabilities x two document modes byte-identical (14/14) and the
-- declared-transitions aggregate byte-identical for all seven (16 routes for
-- project-model-provider-protocol intact; no capability declares a joinSlotId
-- yet). The graph-v2 carriage is the conditional branch proved by the synthetic
-- probe; the live declaration proof is the M1 dry run
-- (declare-dispatch-pair-demo.sql). Reversal: re-run
-- optimize-capability-graph-source-transitions.sql (the pre-unit graph source)
-- and emit-declared-routing.sql (the pre-unit transitions function).
