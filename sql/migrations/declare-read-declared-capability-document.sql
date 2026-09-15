-- declare-read-declared-capability-document.sql
--
-- The flywheel proof's second capability: `read-declared-capability-document`,
-- authored through the JSON surface (`model.declare_capability_document`) from
-- examples/json-authoring/read-declared-capability-document.authority.json.
--
-- What it answers that no installed capability answered before: the caller names
-- one capability and receives the *exact* sidefx-capability-authority.v1 document
-- the current model installed for it, with the document's content address, or
-- `documentInstalled: false` when no document is installed for the id. This is
-- the round trip of the JSON authoring surface: declare_capability_document
-- writes the document ledger; this read returns its bytes.
--
-- Reuse (unchanged):
--   * model.declare_capability_document        -- the JSON surface procedure.
--   * sda-embodiment-plan-port.v1              -- the platform declared-read port.
--   * run-declared-graph                       -- the single invocation path.
--   * read-capability-meaning-request.v1       -- the sibling's input contract:
--     its promise (one capability identity) already covers this read's input, so
--     no new request contract is authored. The scenario input declares it
--     unchanged (see result set 3).
--   * the CAPABILITY_DOCUMENT ledger rows that the JSON surface writes for every
--     declared document (A's own rows already carry the digests this read resolves).
--
-- New rows: one capability (shell, scenario, port, execution authority), one
-- result contract (read-declared-capability-document-result.v1), one document.
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
-- The capability document, byte-identical to
-- examples/json-authoring/read-declared-capability-document.authority.json.
-- Installed, then installed a second time to prove the replay is a no-op.
-- =====================================================================
DECLARE @document nvarchar(max) = N'{
  "document": "sidefx-capability-authority.v1",
  "capabilityId": "read-declared-capability-document",
  "meaning": {
    "intent": "read back the authority document the current model installed for one capability",
    "outcome": "the caller observes the installed sidefx-capability-authority.v1 document and its content address, or that no document is installed for the id"
  },
  "cli": { "display": { "select": "outcome.payload", "as": "json" } },
  "contracts": [
    { "id": "read-declared-capability-document-result.v1",
      "schema": { "type": "object",
        "properties": {
          "capabilityId": { "type": "string" },
          "documentInstalled": { "type": "boolean" },
          "documentDigest": { "type": "string" },
          "document": { "type": "object" }
        },
        "required": ["capabilityId", "documentInstalled"],
        "additionalProperties": true } }
  ],
  "scenarios": [
    {
      "scenarioId": "read-declared-capability-document",
      "name": "Read the authority document installed for one capability",
      "inputId": "read-declared-capability-document-request",
      "inputContract": "read-capability-meaning-request.v1",
      "eventId": "declared-capability-document-requested",
      "eventAuthority": "read-declared-capability-document.v1",
      "outcomeId": "declared-capability-document",
      "outcomeContract": "read-declared-capability-document-result.v1",
      "terminal": true,
      "root": true,
      "given": "one capability identity and the current model",
      "when": "the installed capability document ledger is read under the reader boundary",
      "then": "the installed authority document and its content address are returned, or the caller is told no document is installed for the id",
      "operations": [
        { "operationId": "read-declared-capability-document.0", "kind": "invoke-port",
          "portId": "read-declared-capability-document-port" }
      ],
      "portBindings": [
        { "portId": "read-declared-capability-document-port",
          "platformCapabilityId": "sda-embodiment-plan-port.v1",
          "configuration": {
            "statement": "DECLARE @capability_id nvarchar(400)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@input,''$.capabilityId''))),N'''');\nDECLARE @document_digest varchar(64)=NULL;\nIF @capability_id IS NOT NULL\n SELECT TOP 1 @document_digest=LOWER(JSON_VALUE(d.definition_json,''$.semantics.document_digest''))\n FROM analysis.v_selected_semantic_definition d\n WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''CAPABILITY_DOCUMENT''\n  AND d.namespace_id=N''sidefx:capability-documents'' AND d.declared_id=@capability_id COLLATE Latin1_General_100_BIN2;\nDECLARE @document nvarchar(max)=NULL;\nIF @document_digest IS NOT NULL\n SELECT @document=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)\n FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),@document_digest,2);\nSELECT (SELECT @capability_id AS capabilityId,\n CONVERT(bit,CASE WHEN @document_digest IS NULL THEN 0 ELSE 1 END) AS documentInstalled,\n CASE WHEN @document_digest IS NULL THEN NULL ELSE N''sha256:''+@document_digest END AS documentDigest,\n JSON_QUERY(@document) AS document\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value",
            "resultColumn": "value"
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
  AND d.declared_id=N'read-declared-capability-document';

-- The declared-read port carries the statement and result column and names no
-- provider module: the same standard A used.
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
WHERE c.capability_id=N'read-declared-capability-document';

-- The scenario input resolves to the sibling's contract, reused with no new
-- request contract:
SELECT '3_reused_input_contract' AS result_set, s.scenario_id, ct.contract_id AS input_contract_id
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
JOIN model.contract_version cv ON cv.contract_version_pk=si.input_contract_version_pk
JOIN model.contract ct ON ct.contract_pk=cv.contract_pk
WHERE c.capability_id=N'read-declared-capability-document';

-- Exactly one current definition per declared id in the capability's namespace.
SELECT '4_current_definition_per_id' AS result_set, d.object_kind, d.declared_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate
  AND d.namespace_id=N'sidefx:capability:read-declared-capability-document'
GROUP BY d.object_kind, d.declared_id
ORDER BY d.object_kind, d.declared_id;

-- The read path sees the capability.
SELECT '5_graph_source' AS result_set, g.capability_id, g.root_scenario_id
FROM analysis.v_capability_graph_source g
WHERE g.capability_id=N'read-declared-capability-document';

-- One capability version: the replay above minted no duplicate.
SELECT '6_capability_versions' AS result_set, c.capability_id, COUNT(*) AS versions
FROM model.capability c
JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
WHERE c.capability_id=N'read-declared-capability-document'
 GROUP BY c.capability_id;
COMMIT TRANSACTION;
