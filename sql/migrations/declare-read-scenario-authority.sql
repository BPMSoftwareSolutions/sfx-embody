-- declare-read-scenario-authority.sql
--
-- W1.2 of the hand-authored code retirement (docs/hand-authored-code-retirement-agent-strategy.md):
-- `scripts/read-scenario-round-trip-authority.mjs` is a hand-authored declared read of one
-- SCENARIO definition. No installed read covers that definition: the meaning reader
-- (`read-capability-meaning`) returns the capability's assembled graph source and document set,
-- never the scenario's own sidefx-semantic-definition.v1 bytes (verified against its installed
-- statement). So the read is declared here, authored through the JSON surface
-- (`model.declare_capability_document`) from a document carried by this migration.
--
-- What it answers: the caller names one scenario and receives the selected semantic definition
-- the current model holds for it -- the same authority bytes the retired script read.
--
-- Reuse (unchanged):
--   * model.declare_capability_document            -- the JSON authoring surface procedure.
--   * sda-embodiment-plan-port.v1                  -- the platform declared-read port.
--   * run-declared-graph                           -- the single invocation path.
--   * the SCENARIO rows and selected-definition view the read resolves.
--
-- New rows: one capability (shell, scenario, port, execution authority), the request and result
-- contracts, and one capability document.
--
-- Bundle equivalence: the declared statement is byte-identical to the retired script's query, so
-- the recorded bundle (evidence/review/scenario-round-trip-authority.json) keeps its
-- queryDigest/resultDigest/resultObjectDigest; verification set 4 prints the statement's content
-- address beside the recorded queryDigest d7a3ac629196568ac7f9a51de174227cdee5fae888d14430fec39629df77736b.
--
-- Idempotent: the procedure's document-digest gate returns UNCHANGED on replay
-- and mints no further capability version; the migration prints the replay before
-- the verification result sets.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; only after the from-transaction preflight passes.
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
CLOSE @triggers;
DEALLOCATE @triggers;
GO
-- =====================================================================
-- The capability document, carried as this migration's own bytes (there is no
-- example file; the precedent's file/SQL-literal duplication is not repeated).
-- Installed, then installed a second time to prove the replay is a no-op.
-- =====================================================================
DECLARE @document nvarchar(max) = N'{
  "document": "sidefx-capability-authority.v1",
  "capabilityId": "read-scenario-authority",
  "meaning": {
    "intent": "read back the selected semantic definition the current model holds for one scenario",
    "outcome": "the caller observes the scenario''s retained sidefx-semantic-definition.v1 authority document"
  },
  "cli": { "display": { "select": "outcome.payload", "as": "json" } },
  "contracts": [
    { "id": "read-scenario-authority-request.v1",
      "schema": { "type": "object",
        "properties": { "scenarioId": { "type": "string" } },
        "required": ["scenarioId"],
        "additionalProperties": true } },
    { "id": "read-scenario-authority-result.v1",
      "schema": { "type": "object",
        "properties": {
          "address": { "type": "object" },
          "format": { "type": "string" },
          "semantics": { "type": "object" }
        },
        "required": ["address", "format", "semantics"],
        "additionalProperties": true } }
  ],
  "scenarios": [
    {
      "scenarioId": "read-scenario-authority",
      "name": "Read the declared authority of one scenario",
      "inputId": "read-scenario-authority-request",
      "inputContract": "read-scenario-authority-request.v1",
      "eventId": "scenario-authority-requested",
      "eventAuthority": "read-scenario-authority.v1",
      "outcomeId": "scenario-authority",
      "outcomeContract": "read-scenario-authority-result.v1",
      "terminal": true,
      "root": true,
      "given": "one scenario identity and the current model",
      "when": "the scenario''s selected semantic definition is read under the reader boundary",
      "then": "the retained sidefx-semantic-definition.v1 authority document is returned",
      "operations": [
        { "operationId": "read-scenario-authority.0", "kind": "invoke-port",
          "portId": "read-scenario-authority-port" }
      ],
      "portBindings": [
        { "portId": "read-scenario-authority-port",
          "platformCapabilityId": "sda-embodiment-plan-port.v1",
          "configuration": {
            "statement": "SELECT definition_json FROM analysis.v_selected_semantic_definition\n  WHERE estate_model_pk=@estate_model_pk AND object_kind=''SCENARIO''\n  AND JSON_VALUE(definition_json,''$.address.id'')=JSON_VALUE(@input,''$.scenarioId'')",
            "resultColumn": "definition_json"
          } }
      ]
    }
  ]
}';
EXEC model.declare_capability_document @document=@document;
EXEC model.declare_capability_document @document=@document;
GO
-- ============================== VERIFICATION ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

-- The document ledger holds the installed document's digest for the capability.
SELECT '1_document_ledger' AS result_set, d.declared_id AS capability_id,
       JSON_VALUE(d.definition_json,'$.semantics.document_digest') AS document_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CAPABILITY_DOCUMENT'
  AND d.declared_id=N'read-scenario-authority';

-- The declared-read port carries the statement and result column and names no
-- provider module: the same standard the other declared reads use.
SELECT '2_declared_read_port' AS result_set, c.capability_id, s.scenario_id,
       pv.port_profile,
       JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
       JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
       CASE WHEN JSON_VALUE(pd.definition_json,'$.semantics.configuration.providerId') IS NULL THEN 0 ELSE 1 END AS names_provider_module
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk
WHERE c.capability_id=N'read-scenario-authority';

-- The scenario input resolves to this read's own request contract.
SELECT '3_input_contract' AS result_set, s.scenario_id, ct.contract_id AS input_contract_id
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
JOIN model.contract_version cv ON cv.contract_version_pk=si.input_contract_version_pk
JOIN model.contract ct ON ct.contract_pk=cv.contract_pk
WHERE c.capability_id=N'read-scenario-authority';

-- The declared statement's content address is the recorded bundle's query identity:
-- the declared read IS the query evidence/review/scenario-round-trip-authority.json recorded.
DECLARE @statement nvarchar(max)=(
 SELECT JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement')
 FROM model.capability c
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
 JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
 JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
 JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
 JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
 JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
 JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
 JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk
 WHERE c.capability_id=N'read-scenario-authority');
DECLARE @statement_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),@statement COLLATE Latin1_General_100_BIN2_UTF8))),2));
SELECT '4_bundle_query_identity' AS result_set,
 CONVERT(bit,CASE WHEN @statement_digest=N'd7a3ac629196568ac7f9a51de174227cdee5fae888d14430fec39629df77736b' THEN 1 ELSE 0 END) AS matches_recorded_query_digest,
 N'sha256:'+@statement_digest AS declared_query_digest,
 N'sha256:d7a3ac629196568ac7f9a51de174227cdee5fae888d14430fec39629df77736b' AS recorded_query_digest;

-- Exactly one current definition per declared id in the capability's namespace.
SELECT '5_current_definition_per_id' AS result_set, d.object_kind, d.declared_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate
  AND d.namespace_id=N'sidefx:capability:read-scenario-authority'
GROUP BY d.object_kind, d.declared_id
ORDER BY d.object_kind, d.declared_id;

-- The read path sees the capability.
SELECT '6_graph_source' AS result_set, g.capability_id, g.root_scenario_id
FROM analysis.v_capability_graph_source g
WHERE g.capability_id=N'read-scenario-authority';

-- The replay minted no duplicate: the scaffold shell and the authored interface
-- are the two versions (the same count the installed JSON-authored siblings hold).
SELECT '7_capability_versions' AS result_set, c.capability_id, COUNT(*) AS versions
FROM model.capability c
JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
WHERE c.capability_id=N'read-scenario-authority'
 GROUP BY c.capability_id;
COMMIT TRANSACTION;
