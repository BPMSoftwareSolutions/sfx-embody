-- Data side of the declaration->graph bridge: assemble the flat declared authority
-- the SDA compiler requires (structured scenarios + execution authorities +
-- interface authority + transformations), from declared rows only.
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
CREATE OR ALTER VIEW analysis.v_capability_graph_source AS
WITH base AS (
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
        AND d.entry_id = N'semantic-transformation.authority.json') AS semantic_transformations
  FROM source.current_model cm
  JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
)
SELECT b.capability_id, b.root_scenario_id,
  JSON_QUERY((SELECT
      b.capability_id AS capabilityId,
      b.root_scenario_id AS rootScenarioId,
      JSON_QUERY(b.scenarios) AS scenarios,
      JSON_QUERY(N'[]') AS transitions,
      JSON_QUERY(b.execution_authorities) AS executionAuthorities,
      JSON_QUERY(b.interface_authority) AS interfaceAuthority,
      JSON_QUERY(b.semantic_transformations) AS semanticTransformations
   FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)) AS graph_source
FROM base b;
GO
SELECT TOP 1 capability_id, root_scenario_id,
  LEFT(graph_source, 300) AS head,
  CASE WHEN graph_source LIKE N'%executionAuthorities%' THEN 1 ELSE 0 END AS has_ea,
  CASE WHEN graph_source LIKE N'%interfaceAuthority%' THEN 1 ELSE 0 END AS has_ia,
  DATALENGTH(graph_source) AS bytes
FROM analysis.v_capability_graph_source
WHERE capability_id = N'execute-semantic-execution-graph';
COMMIT TRANSACTION;
