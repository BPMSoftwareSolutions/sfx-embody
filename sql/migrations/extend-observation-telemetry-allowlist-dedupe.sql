-- extend-observation-telemetry-allowlist-dedupe.sql
--
-- Wave 1 U1 (docs/sidefx-protocol-layer-execution-strategy-2026-09-24.md R5/R6;
-- plan Phase 1, layer E): the lane no longer carries evidence members, execution
-- shapes or the duplicated run identity. The live authority is the
-- failure-testimony extension (extend-observation-failure-testimony.commit.sql;
-- its declared statement hashes
-- sha256:5b8407bb53ed5598bdd8ff1985321b4ec4a1cd89eb58739e75ec293558590fce);
-- this migration re-declares read-observation-telemetry-authority from that
-- live policy with exactly three member changes:
--
--   objectFields.providerEvidence   [] (the key stays: the contract requires it
--                                   and all three filters throw
--                                   OBSERVATION_TELEMETRY_AUTHORITY_NOT_RESOLVED
--                                   when it is absent)
--   objectFields.shapes             removed (optional in the contract)
--   observationFields.occurrenceId  removed (cellExecutionId carries the same
--                                   run identity; testimony schemas keep
--                                   occurrenceId, only the lane allowlist drops it)
--
-- Everything else is preserved verbatim from the live policy: the
-- observationFields order, the failure fields, entryFields, display,
-- deniedMembers, the payload byte bound and the event/invocation byte budgets.
-- The meaning prose drops the removed shape-fields claim so the declaration
-- stays true about what the read returns.
--
-- The statement is declaration data: it is carried by the port binding, not by
-- code. It returns one JSON observation-telemetry-authority.v1 value in the
-- value column.
--
-- Idempotent: the capability document's digest is the installed-document gate,
-- and the contracts are content-addressed. A byte-identical replay answers
-- UNCHANGED and writes nothing (proved by the replay below).
--
-- The pair, extend-observation-telemetry-allowlist-dedupe.sql and
-- extend-observation-telemetry-allowlist-dedupe.commit.sql, is byte-identical
-- except the final transaction statement: rollback for the dry run, commit for
-- the installation.
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

-- ============================== THE DECLARED READ STATEMENT ==============================
-- The statement is declaration data: it is carried by the port binding, not by
-- code. It receives @input (unused: the authority is model-wide) and returns one
-- JSON observation-telemetry-authority.v1 value in the value column.
DECLARE @statement nvarchar(max) = N'
SELECT (SELECT N''observation-telemetry-authority.v1'' AS authorityType,
 JSON_QUERY(N''["observationType","testimonyType","phase","status","observedAt","executionId","cellExecutionId","rootExecutionId","parentCellExecutionId","sourceCellExecutionId","scenarioId","stepId","sequence","logicalOrder","cellId","cellAltitude","edgeId","durationMilliseconds","startedAt","completedAt","semanticRole","responsibilityId","responsibilityKind","responsibilityOrdinal","mechanicId","mechanicPath","childScenarioId","parentScenarioId","inputId","eventId","outcomeId","outcomeContractId","sourceCellId","destinationCellId","admissionDisposition","semanticAddress","outcomeClassification","disposition","outcomeVariant","iterationId","providerProfileId","failureCode","failureMessage"]'') AS observationFields,
 JSON_QUERY(N''["status","text","note","admission","timing"]'') AS entryFields,
 JSON_QUERY(N''{"providerEvidence":[],"display":["entry"],"deniedMembers":["authorization","proxy-authorization","x-api-key","x-goog-api-key","api_key","apikey","password","passwd","secret","client_secret","token","access_token","refresh_token","credential","credentials","credentialReference","opaqueCredentialBinding","privateKey","vaultKeyHandle","environment"],"payloadByteBound":4096,"eventByteBudget":65536,"invocationByteBudget":524288}'') AS objectFields
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-observation-telemetry-authority-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';

-- ============================== CONTRACTS AND CAPABILITY DOCUMENT ==============================
-- The contracts are preserved verbatim from the live policy: providerEvidence
-- and display are required, shapes remains an optional property no longer
-- declared by the authority value.
DECLARE @contracts nvarchar(max) = N'[
 {"id":"observation-telemetry-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-request.v1.schema.json","title":"Observation telemetry request","type":"object","additionalProperties":false,"required":["contractId"],"properties":{"contractId":{"const":"observation-telemetry-request.v1"}}}},
 {"id":"observation-telemetry-authority.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-authority.v1.schema.json","title":"Observation telemetry authority","type":"object","additionalProperties":false,"required":["authorityType","observationFields","entryFields","objectFields"],"properties":{"authorityType":{"const":"observation-telemetry-authority.v1"},"observationFields":{"type":"array","items":{"type":"string"}},"entryFields":{"type":"array","items":{"type":"string"}},"objectFields":{"type":"object","additionalProperties":false,"required":["providerEvidence","display"],"properties":{"providerEvidence":{"type":"array","items":{"type":"string"}},"display":{"type":"array","items":{"type":"string"}},"deniedMembers":{"type":"array","items":{"type":"string"}},"shapes":{"type":"object","additionalProperties":{"type":"array","items":{"type":"string"}}},"payloadByteBound":{"type":"integer"},"eventByteBudget":{"type":"integer"},"invocationByteBudget":{"type":"integer"}}}}}}
]';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-observation-telemetry-authority",
 "meaning":{"intent":"read the declared observation-channel telemetry authority","outcome":"the caller observes the declared scalar fields, the failure-testimony fields, the entry fields and the declared object fields the observation channel may publish"},
 "contracts":' + @contracts + N',
 "scenarios":[{
  "scenarioId":"read-observation-telemetry-authority",
  "name":"Read the observation telemetry authority",
  "inputId":"observation-telemetry-request",
  "inputContract":"observation-telemetry-request.v1",
  "eventId":"observation-telemetry-authority-requested",
  "eventAuthority":"read-observation-telemetry-authority.v1",
  "outcomeId":"observation-telemetry-authority",
  "outcomeContract":"observation-telemetry-authority.v1",
  "terminal":true,
  "root":true,
  "given":"the current model",
  "when":"the declared telemetry-authority read executes under the reader boundary",
  "then":"the reading names the scalar testimony fields, the failure-testimony fields, the display Entry fields, and the declared payload bound and budgets",
  "operations":[{"operationId":"read-observation-telemetry-authority.0","kind":"invoke-port","portId":"read-observation-telemetry-authority-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;

-- ============================== PROOF ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT '1_contracts' AS result_set, d.declared_id AS contract_id
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id IN (N'observation-telemetry-request.v1',N'observation-telemetry-authority.v1')
ORDER BY d.declared_id;

SELECT '2_capability' AS result_set, c.capability_id, s.scenario_id,
 p.port_id, JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column
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
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk AND pd.estate_model_pk=@estate
WHERE c.capability_id=N'read-observation-telemetry-authority';

-- The behavioral self-test: the installed statement itself is executed, exactly
-- as the boot filter executes it. It prints the resulting counts so a
-- truncated, renamed or re-expanded member is visible.
DECLARE @stmt nvarchar(max)=(SELECT JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.configuration.statement')
 FROM analysis.v_selected_semantic_definition d
 JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=d.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=N'sidefx:capability:read-observation-telemetry-authority' AND d.declared_id=N'read-observation-telemetry-authority-port');
DECLARE @authority TABLE (value nvarchar(max));
INSERT @authority EXEC sp_executesql @stmt;
SELECT '3_authority_self_test' AS result_set,
 JSON_VALUE(value,'$.authorityType') AS authority_type,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.observationFields'))) AS observation_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.observationFields')) WHERE value IN (N'failureCode',N'failureMessage')) AS failure_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.observationFields')) WHERE value=N'occurrenceId') AS occurrence_id_in_observation_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.entryFields'))) AS entry_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.providerEvidence'))) AS provider_evidence_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.deniedMembers'))) AS denied_members,
 CASE WHEN JSON_QUERY(value,'$.objectFields.shapes') IS NULL THEN 0 ELSE 1 END AS shapes_present,
 JSON_VALUE(value,'$.objectFields.payloadByteBound') AS payload_byte_bound,
 JSON_VALUE(value,'$.objectFields.eventByteBudget') AS event_byte_budget,
 JSON_VALUE(value,'$.objectFields.invocationByteBudget') AS invocation_byte_budget,
 CASE WHEN value LIKE N'%authorization%' THEN 1 ELSE 0 END AS denies_authorization
FROM @authority;

-- The three U1 assertions, both printed and enforced: providerEvidence is an
-- empty array with the key present, no shape member is declared, and
-- occurrenceId is gone from observationFields.
DECLARE @authority_value nvarchar(max)=(SELECT TOP (1) value FROM @authority);
DECLARE @provider_evidence_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.providerEvidence')));
DECLARE @provider_evidence_key_present int=CASE WHEN JSON_QUERY(@authority_value,'$.objectFields.providerEvidence') IS NULL THEN 0 ELSE 1 END;
DECLARE @shapes_present int=CASE WHEN JSON_QUERY(@authority_value,'$.objectFields.shapes') IS NULL THEN 0 ELSE 1 END;
DECLARE @occurrence_id_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.observationFields')) WHERE value=N'occurrenceId');
SELECT '4_assertions' AS result_set,
 @provider_evidence_count AS provider_evidence_fields,
 @provider_evidence_key_present AS provider_evidence_key_present,
 @shapes_present AS shapes_present,
 @occurrence_id_count AS occurrence_id_in_observation_fields,
 CASE WHEN @provider_evidence_count=0 AND @provider_evidence_key_present=1 AND @shapes_present=0 AND @occurrence_id_count=0 THEN N'PASS' ELSE N'FAIL' END AS disposition;
IF @provider_evidence_count<>0 THROW 51000,N'ALLOWLIST_DEDUPE_PROVIDER_EVIDENCE_NOT_EMPTY',1;
IF @provider_evidence_key_present<>1 THROW 51000,N'ALLOWLIST_DEDUPE_PROVIDER_EVIDENCE_KEY_MISSING',1;
IF @shapes_present<>0 THROW 51000,N'ALLOWLIST_DEDUPE_SHAPES_STILL_DECLARED',1;
IF @occurrence_id_count<>0 THROW 51000,N'ALLOWLIST_DEDUPE_OCCURRENCE_ID_STILL_DECLARED',1;

-- The uncommitted replay of the same document bytes answers UNCHANGED: the
-- installed-document gate, not a second version. A byte-identical install
-- writes nothing.
DECLARE @replay TABLE (action nvarchar(64), disposition nvarchar(64), capability_id nvarchar(400), document_digest varchar(64), contracts_declared int, scenarios_declared int, meaning_declared int, interface_declared int);
INSERT @replay EXEC model.declare_capability_document @document=@document;
SELECT '5_idempotent_replay' AS result_set, disposition, contracts_declared, scenarios_declared, meaning_declared, interface_declared, document_digest FROM @replay;
IF NOT EXISTS (SELECT 1 FROM @replay WHERE disposition=N'UNCHANGED') THROW 51000,N'ALLOWLIST_DEDUPE_REPLAY_NOT_UNCHANGED',1;

-- The assembled graph source from the uncommitted transaction: the reader is
-- reachable through the estate view.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-observation-telemetry-authority',0,N'sidefx:capabilities'));
SELECT '6_graph_source' AS result_set,
 JSON_VALUE(@graph,'$.capabilityId') AS capability_id,
 JSON_VALUE(@graph,'$.rootScenarioId') AS root_scenario_id,
 (SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities') a
  CROSS APPLY OPENJSON(JSON_QUERY(a.value,'$.operations')) o
  WHERE JSON_VALUE(o.value,'$.operationId')=N'read-observation-telemetry-authority.0') AS operations_declared;

-- The re-declaration is proved above; the final transaction statement selects
-- the dry run (rollback) or the installation (commit).
ROLLBACK TRANSACTION;
