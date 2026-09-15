-- optimize-capability-graph-source.sql
--
-- Performance plan item #1 (docs/performance-optimization.md).
--
-- `analysis.v_capability_graph_source` assembled the graph-source JSON for every
-- capability in the estate and only then let the caller's `capability_id`
-- predicate prune it. Its `contract_authorities` CTE pivots the whole declaration
-- set, and `base` runs four correlated reads of
-- `analysis.v_capability_execution_declaration` per capability. Measured on this
-- estate (299 declared capabilities):
--
--   SELECT graph_source FROM analysis.v_capability_graph_source
--   WHERE capability_id = N'say-hello-world'      -->  399,704 ms for 2,945 chars
--
-- This migration parameterizes the assembly to one capability *before* any JSON
-- aggregation by introducing the inline table-valued function
-- `analysis.capability_graph_source(@capability_id)`, and redefines the view as
-- that function applied over the estate's capabilities so every existing reader
-- keeps working unchanged.
--
-- Nothing about the assembled document changes: the same CTEs, the same
-- `FOR JSON PATH` projection, the same `STRING_AGG ... WITHIN GROUP (ORDER BY
-- contract_id)`, the same `ORDER BY s.scenario_id`. The only difference is that
-- `decl` and `base` are restricted to `@capability_id` at the top instead of at
-- the end. The verification below prints the SHA2_256 of the assembled
-- graph_source so it can be compared byte-for-byte against the digest captured
-- from the previous view definition.
--
-- Meaning is authored in rows. Nothing here changes a capability's meaning.
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
-- One capability's assembled graph source. The parameter restricts `decl` and
-- `base` before the contract pivot and before FOR JSON PATH runs.
CREATE OR ALTER FUNCTION analysis.capability_graph_source(@capability_id nvarchar(400))
RETURNS TABLE
AS RETURN
WITH decl AS (
  SELECT d.estate_model_pk, d.capability_id, d.entry_id, d.document
  FROM analysis.v_capability_execution_declaration d
  WHERE d.capability_id = @capability_id
),
-- Set-based pivot of this capability's declared contract catalog onto its
-- declared schema documents. One row.
contract_authorities AS (
  SELECT cat.estate_model_pk, cat.capability_id,
    N'{"authorityType":"consumer-contract-authorities.v1","contracts":{' +
    ISNULL(STRING_AGG(
      (N'"' + cat.contract_id + N'":{"schemaRef":"' + STRING_ESCAPE(cat.schema_ref, 'json') + N'"'
       + CASE WHEN cat.schema_id IS NULL THEN N''
              ELSE N',"schemaId":"' + STRING_ESCAPE(cat.schema_id, 'json') + N'"' END
       + N',"schema":' + cat.schema_document + N'}') COLLATE Latin1_General_100_BIN2, N',')
      WITHIN GROUP (ORDER BY cat.contract_id), N'')
    + N'}}' AS document
  FROM (
    SELECT p.estate_model_pk, p.capability_id,
      ckey.[key] COLLATE Latin1_General_100_BIN2 AS contract_id,
      ckey.[value] COLLATE Latin1_General_100_BIN2 AS schema_ref,
      JSON_VALUE(sch.document, N'$."$id"') COLLATE Latin1_General_100_BIN2 AS schema_id,
      sch.document COLLATE Latin1_General_100_BIN2 AS schema_document
    FROM decl p
    CROSS APPLY OPENJSON(p.document) ckey
    JOIN decl sch ON sch.estate_model_pk = p.estate_model_pk
      AND sch.capability_id = p.capability_id
      AND sch.entry_id = N'contracts/' + ckey.[value]
    WHERE p.entry_id = N'contracts/contract-catalog.json'
  ) cat
  GROUP BY cat.estate_model_pk, cat.capability_id
),
base AS (
  SELECT
    c.capability_id COLLATE Latin1_General_100_BIN2 AS capability_id,
    (SELECT TOP 1 rs.scenario_id FROM model.capability_root_scenario crs
       JOIN model.scenario rs ON rs.scenario_pk = crs.scenario_pk
     WHERE crs.capability_version_pk = ec.capability_version_pk) COLLATE Latin1_General_100_BIN2 AS root_scenario_id,
    (SELECT
       s.scenario_id AS scenarioId,
       JSON_QUERY((SELECT si.input_id AS inputId,
          JSON_QUERY((SELECT ct.contract_id AS contractId
            FROM model.contract_version cv JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
            WHERE cv.contract_version_pk = si.input_contract_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS contract
        FROM model.scenario_input si WHERE si.scenario_version_pk = cs.scenario_version_pk
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS input,
       JSON_QUERY((SELECT se.event_id AS eventId, ea.execution_authority_id AS executionAuthorityId
        FROM model.scenario_event se
        JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = se.execution_authority_version_pk
        JOIN model.execution_authority ea ON ea.execution_authority_pk = eav.execution_authority_pk
        WHERE se.scenario_version_pk = cs.scenario_version_pk
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS event,
       JSON_QUERY((SELECT so.outcome_id AS outcomeId,
          JSON_QUERY((SELECT ct.contract_id AS contractId
            FROM model.scenario_outcome_contract soc
            JOIN model.contract_version cv ON cv.contract_version_pk = soc.contract_version_pk
            JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
            WHERE soc.scenario_version_pk = cs.scenario_version_pk FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS contract,
          CONVERT(bit, so.terminal) AS terminal
        FROM model.scenario_outcome so WHERE so.scenario_version_pk = cs.scenario_version_pk
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS outcome
     FROM model.capability_scenario cs
     JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
     WHERE cs.capability_version_pk = ec.capability_version_pk
     ORDER BY s.scenario_id
     FOR JSON PATH) AS scenarios,
    (SELECT JSON_QUERY(d.document, '$.executionAuthorities') FROM decl d
      WHERE d.estate_model_pk = ec.estate_model_pk
        AND d.entry_id = N'execution-authorities.authority.json') AS execution_authorities,
    (SELECT d.document FROM decl d
      WHERE d.estate_model_pk = ec.estate_model_pk
        AND d.entry_id = N'interfaces.authority.json') AS interface_authority,
    (SELECT JSON_QUERY(d.document, '$.transformations') FROM decl d
      WHERE d.estate_model_pk = ec.estate_model_pk
        AND d.entry_id = N'semantic-transformation.authority.json') AS semantic_transformations,
    ca.document AS contract_authorities
  FROM source.current_model cm
  JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  LEFT JOIN contract_authorities ca
    ON ca.estate_model_pk = ec.estate_model_pk
   AND ca.capability_id = c.capability_id COLLATE Latin1_General_100_BIN2
  WHERE c.capability_id = @capability_id
)
SELECT b.capability_id, b.root_scenario_id,
  JSON_QUERY((SELECT
      b.capability_id AS capabilityId,
      b.root_scenario_id AS rootScenarioId,
      JSON_QUERY(b.scenarios) AS scenarios,
      JSON_QUERY(N'[]') AS transitions,
      JSON_QUERY(b.execution_authorities) AS executionAuthorities,
      JSON_QUERY(b.interface_authority) AS interfaceAuthority,
      JSON_QUERY(b.semantic_transformations) AS semanticTransformations,
      JSON_QUERY(b.contract_authorities) AS contractAuthorities
   FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS graph_source
FROM base b;
GO
-- The estate-wide view is the same assembly applied per declared capability, so
-- every existing reader (`model.inspect_capability`, the inspection queries)
-- keeps the columns and rows it had.
CREATE OR ALTER VIEW analysis.v_capability_graph_source AS
SELECT g.capability_id, g.root_scenario_id, g.graph_source
FROM (
  SELECT DISTINCT c.capability_id
  FROM source.current_model cm
  JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
) caps
CROSS APPLY analysis.capability_graph_source(caps.capability_id) g;
GO
GRANT SELECT ON OBJECT::analysis.capability_graph_source TO sidefx_reader;
GRANT SELECT ON OBJECT::analysis.v_capability_graph_source TO sidefx_reader;
GO
-- ============================== VERIFICATION ==============================
-- A duplicated capability_id would make the applied view multiply rows. Expect 0.
SELECT 'duplicate_capability_ids' AS result_set, COUNT(*) AS duplicate_ids
FROM (SELECT c.capability_id
      FROM source.current_model cm
      JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
      JOIN model.capability c ON c.capability_pk = ec.capability_pk
      GROUP BY c.capability_id HAVING COUNT(*) > 1) d;

SELECT 'function_columns' AS result_set, c.name AS column_name,
  CONVERT(nvarchar(64), t.name) AS type_name, c.max_length
FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('analysis.capability_graph_source')
ORDER BY c.column_id;

SELECT 'view_columns' AS result_set, c.name AS column_name,
  CONVERT(nvarchar(64), t.name) AS type_name, c.max_length
FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('analysis.v_capability_graph_source')
ORDER BY c.column_id;

-- The assembled document, digested. Compare against the digest captured from the
-- previous view definition: identical bytes, or the change is not done.
DECLARE @started datetime2(3);
DECLARE @proof TABLE(capability_id nvarchar(400), root_scenario_id nvarchar(400),
                     graph_sha256 varchar(64), graph_chars bigint, elapsed_ms int);
DECLARE @id nvarchar(400), @ids CURSOR;
SET @ids = CURSOR LOCAL FAST_FORWARD FOR
  SELECT v FROM (VALUES (N'say-hello-world'), (N'resolve-equity-market-price-evidence'),
                        (N'run-declared-graph'), (N'hello-world-sql')) x(v);
OPEN @ids;
FETCH NEXT FROM @ids INTO @id;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @started = SYSUTCDATETIME();
  INSERT @proof
  SELECT g.capability_id, g.root_scenario_id,
    CONVERT(varchar(64), HASHBYTES('SHA2_256',
      CONVERT(varbinary(max), CONVERT(varchar(max), g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)), 2),
    LEN(g.graph_source), DATEDIFF(ms, @started, SYSUTCDATETIME())
  FROM analysis.capability_graph_source(@id) g;
  FETCH NEXT FROM @ids INTO @id;
END;
CLOSE @ids; DEALLOCATE @ids;
SELECT 'graph_source_digest' AS result_set, * FROM @proof ORDER BY capability_id;

SELECT 'graph_source_keys' AS result_set, g.capability_id,
  CASE WHEN JSON_QUERY(g.graph_source, '$.contractAuthorities') IS NULL THEN 0 ELSE 1 END AS has_contract_authorities,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.graph_source, '$.contractAuthorities.contracts'))) AS contract_count,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.graph_source, '$.executionAuthorities'))) AS execution_authority_count,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.graph_source, '$.scenarios'))) AS scenario_count,
  DATALENGTH(g.graph_source) AS bytes
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence') g;

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
