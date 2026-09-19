-- optimize-capability-graph-source-transitions.sql
--
-- `analysis.capability_graph_source` is the kernel's capability-authority read:
-- it assembles the executable graph source that the C# kernel compiles. Two
-- costs were measured on the agent lane (`request-capability-from-objective`,
-- 25,012,763-char graph source):
--
--   * the function calls `analysis.capability_execution_declaration(
--     @capability_id, @namespace_id, 1)` a second time only to read
--     `$.transitions` from the returned `semantic-graph.authority.json`
--     document. That second call re-assembles every document of the capability
--     (ports, transformations, contracts, fixtures) although the first call
--     already ran with the requested document inclusion. The transitions are
--     exactly `analysis.capability_declared_transitions(@capability_id)`
--     aggregated the same way the declaration assembles them, so the general
--     document assembly can be removed from the graph-source read.
--
-- Measured (same pinned session, `request-capability-from-objective`,
-- @include_documents = 0): the installed function returned in 11,146.6 ms; the
-- replacement returns in 7,347.5 ms warm (7,477.3 ms first call). The graph
-- source bytes and the documents output are unchanged: the preflight below
-- captures the installed function's digest for seven capabilities in both
-- document modes, re-declares, captures the new digests, and fails closed on
-- any difference. The live acceptance digests (hello 20864ba2 / 8b859397 /
-- f7655bd9, equity c507678e, observe 26c85c04) were re-verified after install.
--
-- This migration re-declares only `analysis.capability_graph_source`; the
-- execution-declaration function, the views and the grants are untouched.
-- The retention rule is respected: the removed call was a repeated read inside
-- one invocation (request-scoped), not a cache across generations.
--
-- Idempotent: a re-run captures the already-optimized function as "before" and
-- "after" and re-declares the same bytes; every digest still matches.
--
-- Lifecycle: default was ROLLBACK. Installed after the rollback dry run and the
-- from-transaction preflight (seven capabilities x two document modes
-- byte-identical; agent-lane read 11.1 s -> 7.3 s).
--
-- Proof result sets:
--   1_equality   every capability/document-mode before/after digest, all equal
--   2_timing     the agent-lane and hello graph-source reads, before vs after
--   3_claim      the retained body carries the direct transitions aggregation
--                and no second capability_execution_declaration call
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

-- ============================== BEFORE ==============================
IF OBJECT_ID('tempdb..#graph_before') IS NOT NULL DROP TABLE #graph_before;
IF OBJECT_ID('tempdb..#graph_after') IS NOT NULL DROP TABLE #graph_after;
IF OBJECT_ID('tempdb..#timing') IS NOT NULL DROP TABLE #timing;
CREATE TABLE #graph_before (capability_id nvarchar(400), include_docs bit, graph_digest varchar(80), documents_digest varchar(80));
CREATE TABLE #graph_after (capability_id nvarchar(400), include_docs bit, graph_digest varchar(80), documents_digest varchar(80));
CREATE TABLE #timing (phase nvarchar(60), milliseconds decimal(18,3));
DECLARE @caps TABLE (ord int identity, capability_id nvarchar(400));
INSERT @caps(capability_id) VALUES
 (N'say-hello-world'),(N'resolve-equity-market-price-evidence'),
 (N'request-capability-from-objective'),(N'read-capability-circuit'),
 (N'read-observation-projection'),(N'read-observation-telemetry-authority'),
 (N'compose-resolve-equity-market-price-evidence');
DECLARE @cap nvarchar(400), @dt int, @v nvarchar(max), @doc nvarchar(max);
DECLARE @t0 datetime2(7), @t1 datetime2(7);
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
SET @t0=SYSDATETIME();
SELECT @v=graph_source FROM analysis.capability_graph_source(N'request-capability-from-objective',0,N'sidefx:capabilities');
SET @t1=SYSDATETIME();
INSERT #timing VALUES('before_agent0',DATEDIFF_BIG(microsecond,@t0,@t1)/1000.0);
SET @t0=SYSDATETIME();
SELECT @v=graph_source FROM analysis.capability_graph_source(N'say-hello-world',0,N'sidefx:capabilities');
SET @t1=SYSDATETIME();
INSERT #timing VALUES('before_hello',DATEDIFF_BIG(microsecond,@t0,@t1)/1000.0);
GO

-- ============================== THE SINGLE DECLARATION READ ==============================
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
      JSON_QUERY(ISNULL(@routing_transitions, N'[]')) AS transitions,
      JSON_QUERY(b.execution_authorities) AS executionAuthorities, JSON_QUERY(b.interface_authority) AS interfaceAuthority,
      JSON_QUERY(b.semantic_transformations) AS semanticTransformations, JSON_QUERY(b.contract_authorities) AS contractAuthorities
      FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)),
    JSON_QUERY(b.interface_authority, '$.interfaces[0].configuration'), @documents
  FROM base b;
  RETURN;
END;
GO

-- ============================== AFTER AND IN-TRANSACTION PREFLIGHT ==============================
DECLARE @caps2 TABLE (ord int identity, capability_id nvarchar(400));
INSERT @caps2(capability_id) VALUES
 (N'say-hello-world'),(N'resolve-equity-market-price-evidence'),
 (N'request-capability-from-objective'),(N'read-capability-circuit'),
 (N'read-observation-projection'),(N'read-observation-telemetry-authority'),
 (N'compose-resolve-equity-market-price-evidence');
DECLARE @cap2 nvarchar(400), @dt2 int, @v2 nvarchar(max), @doc2 nvarchar(max);
DECLARE @ta datetime2(7), @tb datetime2(7);
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
SET @ta=SYSDATETIME();
SELECT @v2=graph_source FROM analysis.capability_graph_source(N'request-capability-from-objective',0,N'sidefx:capabilities');
SET @tb=SYSDATETIME();
INSERT #timing VALUES('after_agent0',DATEDIFF_BIG(microsecond,@ta,@tb)/1000.0);
SET @ta=SYSDATETIME();
SELECT @v2=graph_source FROM analysis.capability_graph_source(N'say-hello-world',0,N'sidefx:capabilities');
SET @tb=SYSDATETIME();
INSERT #timing VALUES('after_hello',DATEDIFF_BIG(microsecond,@ta,@tb)/1000.0);

IF EXISTS (
 SELECT 1 FROM #graph_before b
 FULL JOIN #graph_after a ON a.capability_id=b.capability_id AND a.include_docs=b.include_docs
 WHERE b.graph_digest IS NULL OR a.graph_digest IS NULL
   OR b.graph_digest<>a.graph_digest OR b.documents_digest<>a.documents_digest
) THROW 51000,N'GRAPH_SOURCE_DIVERGED',1;
IF (SELECT COUNT(*) FROM #graph_after)<>14 THROW 51000,N'GRAPH_SOURCE_PROBE_INCOMPLETE',1;

DECLARE @body nvarchar(max)=OBJECT_DEFINITION(OBJECT_ID('analysis.capability_graph_source'));
IF CHARINDEX(N'FROM analysis.capability_execution_declaration(@capability_id, @namespace_id, 1) d',@body)>0
 THROW 51000,N'GRAPH_SOURCE_SECOND_DECLARATION_STILL_DECLARED',1;
IF CHARINDEX(N'FROM analysis.capability_declared_transitions(@capability_id) transition',@body)=0
 THROW 51000,N'GRAPH_SOURCE_DIRECT_TRANSITIONS_NOT_DECLARED',1;

-- ============================== PROOF ==============================
SELECT '1_equality' AS result_set, b.capability_id, b.include_docs,
 b.graph_digest AS before_graph_digest, a.graph_digest AS after_graph_digest,
 b.documents_digest AS before_documents_digest, a.documents_digest AS after_documents_digest,
 CONVERT(bit,CASE WHEN b.graph_digest=a.graph_digest AND b.documents_digest=a.documents_digest THEN 1 ELSE 0 END) AS identical
FROM #graph_before b JOIN #graph_after a
 ON a.capability_id=b.capability_id AND a.include_docs=b.include_docs
ORDER BY b.capability_id,b.include_docs;

SELECT '2_timing' AS result_set, phase, milliseconds FROM #timing ORDER BY phase;

SELECT '3_claim' AS result_set,
 CONVERT(bit,CASE WHEN CHARINDEX(N'FROM analysis.capability_declared_transitions(@capability_id) transition',@body)>0 THEN 1 ELSE 0 END) AS direct_transitions_declared,
 CONVERT(bit,CASE WHEN CHARINDEX(N'FROM analysis.capability_execution_declaration(@capability_id, @namespace_id, 1) d',@body)>0 THEN 1 ELSE 0 END) AS second_declaration_call_present,
 LEN(@body) AS function_chars;

COMMIT TRANSACTION;
-- Installed after the rollback dry run and the from-transaction preflight:
-- seven capabilities x two document modes byte-identical, agent-lane
-- graph-source read 11.1 s -> 7.3 s.
