-- Expose the declared contract authority inside analysis.v_capability_graph_source.
--
-- The SDA consumer-execution-embodiment compiler sets a plan's contractCatalog
-- from authorityGraph.contractAuthorities (createPlanV3's 4th argument). The
-- assembled graph source carried the scenarios, transitions, execution
-- authorities, interface authority and transformations, but not the declared
-- contracts, so a regenerated plan's contractCatalog was empty.
--
-- This CREATE OR ALTERs the view to pivot the capability's declared
-- contracts/contract-catalog.json (contractId -> schema filename) against the
-- contracts/<schemaRef> documents, emitting the SDA consumer contract-authority
-- document the compiler consumes:
--
--   { "authorityType": "consumer-contract-authorities.v1",
--     "contracts": { "<contractId>": { "schemaRef": "<ref>", "schemaId": "<$id>",
--                                      "schema": <the parsed schema document> } } }
--
-- schemaDigest is not emitted here: the runtime digest is sha256 over the
-- compact JSON.stringify of the parsed schema, which the view does not
-- resequence; the schema document itself is carried so the digest can be bound
-- where the document is materialized.
--
-- Meaning is authored in rows. Nothing here changes a capability's meaning.
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
CREATE OR ALTER VIEW analysis.v_capability_graph_source AS
WITH decl AS (
  SELECT d.estate_model_pk, d.capability_id, d.entry_id, d.document
  FROM analysis.v_capability_execution_declaration d
),
-- Set-based pivot of each capability's declared contract catalog onto its
-- declared schema documents. One row per capability.
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
    (SELECT JSON_QUERY(d.document, '$.executionAuthorities')
       FROM analysis.v_capability_execution_declaration d
      WHERE d.estate_model_pk = ec.estate_model_pk AND d.capability_id = c.capability_id
        AND d.entry_id = N'execution-authorities.authority.json') AS execution_authorities,
    (SELECT d.document
       FROM analysis.v_capability_execution_declaration d
      WHERE d.estate_model_pk = ec.estate_model_pk AND d.capability_id = c.capability_id
        AND d.entry_id = N'interfaces.authority.json') AS interface_authority,
    (SELECT JSON_QUERY(d.document, '$.transformations')
       FROM analysis.v_capability_execution_declaration d
      WHERE d.estate_model_pk = ec.estate_model_pk AND d.capability_id = c.capability_id
        AND d.entry_id = N'semantic-transformation.authority.json') AS semantic_transformations,
    ca.document AS contract_authorities
  FROM source.current_model cm
  JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
  LEFT JOIN contract_authorities ca
    ON ca.estate_model_pk = ec.estate_model_pk
   AND ca.capability_id = c.capability_id COLLATE Latin1_General_100_BIN2
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
-- ============================== VERIFICATION ==============================
SELECT 'view_columns' AS result_set, c.name AS column_name,
  CONVERT(nvarchar(64), t.name) AS type_name, c.max_length
FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('analysis.v_capability_graph_source')
ORDER BY c.column_id;

SELECT 'graph_source_keys' AS result_set, g.capability_id,
  CASE WHEN JSON_QUERY(g.graph_source, '$.contractAuthorities') IS NULL THEN 0 ELSE 1 END AS has_contract_authorities,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.graph_source, '$.contractAuthorities.contracts'))) AS contract_count,
  DATALENGTH(g.graph_source) AS bytes
FROM analysis.v_capability_graph_source g
WHERE g.capability_id IN (N'resolve-equity-market-price-evidence', N'run-declared-graph', N'hello-world-sql');

SELECT 'equity_contracts' AS result_set,
  ckey.[key] AS contract_id,
  JSON_VALUE(ckey.[value], '$.schemaRef') AS schema_ref,
  JSON_VALUE(ckey.[value], '$.schemaId') AS schema_id,
  CASE WHEN JSON_QUERY(ckey.[value], '$.schema') IS NULL THEN 0 ELSE 1 END AS has_schema
FROM analysis.v_capability_graph_source g
CROSS APPLY OPENJSON(JSON_QUERY(g.graph_source, '$.contractAuthorities.contracts')) ckey
WHERE g.capability_id = N'resolve-equity-market-price-evidence'
ORDER BY ckey.[key];
COMMIT TRANSACTION;
