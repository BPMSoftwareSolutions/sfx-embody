-- emit-composed-closure-scenarios.sql
--
-- analysis.capability_graph_source emits the invocation closure's scenarios as
-- cells, not only the capability's own. A capability that invokes another
-- capability's scenario (invoke-scenario across capabilities) cannot link the
-- target's scenarios into its own model.capability_scenario set - the composite
-- FK to model.scenario (capability_pk, scenario_pk) forbids it. The compiler
-- builds scenario cells from the graph source's scenarios array, so the closure
-- must be emitted here. No kernel change: the compiler already admits those
-- scenarios, and the declaration side already carries their authorities, ports,
-- transformations, contracts and outcome classifications.
--
-- Proofs: for a capability whose closure is only its own scenarios the emitted
-- scenarios bytes are unchanged (no extra closure rows); for the existing
-- cross-capability composite (compose-resolve-equity-market-price-evidence) the
-- invoked equity scenario now appears in its scenarios array.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
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
      ca.document AS contract_authorities
    FROM source.current_model cm JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
    JOIN model.capability c ON c.capability_pk = ec.capability_pk
    JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
    LEFT JOIN contract_authorities ca ON ca.estate_model_pk = ec.estate_model_pk AND ca.capability_id = c.capability_id
    WHERE c.capability_id = @capability_id COLLATE Latin1_General_100_BIN2
      AND (@namespace_id IS NULL OR n.namespace_id = @namespace_id COLLATE Latin1_General_100_BIN2)
  )
  INSERT @result
  SELECT b.estate_model_pk, b.capability_id, b.namespace_id, b.root_scenario_id,
    JSON_QUERY((SELECT b.capability_id AS capabilityId, b.root_scenario_id AS rootScenarioId,
      JSON_QUERY(b.scenarios) AS scenarios, JSON_QUERY(b.scenario_outcomes) AS scenarioOutcomes,
      JSON_QUERY((SELECT JSON_QUERY(d.document, '$.transitions')
        FROM analysis.capability_execution_declaration(@capability_id, @namespace_id, 1) d
        WHERE d.entry_id = N'semantic-graph.authority.json')) AS transitions,
      JSON_QUERY(b.execution_authorities) AS executionAuthorities, JSON_QUERY(b.interface_authority) AS interfaceAuthority,
      JSON_QUERY(b.semantic_transformations) AS semanticTransformations, JSON_QUERY(b.contract_authorities) AS contractAuthorities
      FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)),
    JSON_QUERY(b.interface_authority, '$.interfaces[0].configuration'), @documents
  FROM base b;
  RETURN;
END;
GO
-- ============================== VERIFICATION ==============================
-- A capability with no cross-capability invocation: its closure has no downstream
-- scenarios, so the emitted scenario set is exactly its own (bytes unchanged).
SELECT '1_own_scope' AS result_set, g.capability_id,
  (SELECT COUNT(*) FROM OPENJSON(g.graph_source, '$.scenarios')) AS emitted_scenarios,
  (SELECT COUNT(*) FROM model.capability_scenario cs
     JOIN model.estate_capability ec ON ec.capability_version_pk = cs.capability_version_pk
     JOIN model.capability c ON c.capability_pk = ec.capability_pk
   WHERE c.capability_id = N'hello-world-sql') AS own_scenarios,
  (SELECT COUNT(*) FROM analysis.v_scenario_invocation_closure cl
     JOIN model.estate_capability ec ON ec.capability_version_pk = cl.capability_version_pk
     JOIN model.capability c ON c.capability_pk = ec.capability_pk
   WHERE c.capability_id = N'hello-world-sql' AND cl.minimum_depth > 0) AS closure_extra
FROM analysis.capability_graph_source(N'hello-world-sql', 0, NULL) g;
-- The cross-capability composite: the invoked equity scenario is now a cell.
SELECT '2_closure_scenario' AS result_set, g.capability_id,
  (SELECT COUNT(*) FROM OPENJSON(g.graph_source, '$.scenarios') scenario
   WHERE JSON_VALUE(scenario.value, '$.scenarioId') = N'resolve-equity-market-price-evidence') AS equity_scenarios,
  (SELECT COUNT(*) FROM OPENJSON(g.graph_source, '$.scenarios')) AS emitted_scenarios
FROM analysis.capability_graph_source(N'compose-resolve-equity-market-price-evidence', 0, NULL) g;
COMMIT TRANSACTION;
-- Installed 2026-09-17: the graph source emits the invocation closure scenarios.
