-- extend-observation-telemetry-value-ids.sql
--
-- Wave 1 O3 (docs/sidefx-protocol-layer-execution-strategy-2026-09-24.md,
-- output-boundary plan section 13): the source must be able to assign a numeric
-- ID to the canonical disposition value, so the next boundary crossing can
-- decode node / signal disposition / value admitted from numeric wire IDs. The
-- live policy is the U1 generation
-- (extend-observation-telemetry-allowlist-dedupe.commit.sql; its declared
-- statement hashes
-- sha256:4c9d97fdd97647e5ab368dd5dcd5369bab5f7198c2b542f89a92d815d23c3054).
-- This migration re-declares read-observation-telemetry-authority from that
-- live policy with exactly three member additions and nothing else changed:
--
--   observationFields              "dispositionId" added immediately after
--                                  "disposition" (44 fields now)
--   objectFields.valueDictionaries {"disposition":{"completed":1,"rejected":2,
--                                  "failed":3,"cancelled":4,"held":5,"skipped":6}}
--                                  (the six declared disposition values, exact
--                                  and 1-based)
--   objectFields.valueProjections  [{"field":"disposition","idField":"dispositionId"}]
--
-- Everything else is preserved verbatim from the live policy: the
-- observationFields order, the failure fields, entryFields, display,
-- deniedMembers, the payload byte bound, the event/invocation byte budgets, and
-- the contract (unchanged: providerEvidence stays, no shapes are added).
--
-- The statement is declaration data: it is carried by the port binding, not by
-- code. It receives @input (unused: the authority is model-wide) and returns one
-- JSON observation-telemetry-authority.v1 value in the value column. The
-- re-declared statement hashes
-- sha256:360905c91f189b40aef0251d5353adc4fe9c7a23e321daf01cb51bfc6a3356a2.
--
-- Idempotent: the capability document's digest is the installed-document gate,
-- and the contracts are content-addressed. A byte-identical replay answers
-- UNCHANGED and writes nothing (proved by the replay below).
--
-- The pair, extend-observation-telemetry-value-ids.sql and
-- extend-observation-telemetry-value-ids.commit.sql, is byte-identical except
-- the final transaction statement: rollback for the dry run, commit for the
-- installation.
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
 JSON_QUERY(N''["observationType","testimonyType","phase","status","observedAt","executionId","cellExecutionId","rootExecutionId","parentCellExecutionId","sourceCellExecutionId","scenarioId","stepId","sequence","logicalOrder","cellId","cellAltitude","edgeId","durationMilliseconds","startedAt","completedAt","semanticRole","responsibilityId","responsibilityKind","responsibilityOrdinal","mechanicId","mechanicPath","childScenarioId","parentScenarioId","inputId","eventId","outcomeId","outcomeContractId","sourceCellId","destinationCellId","admissionDisposition","semanticAddress","outcomeClassification","disposition","dispositionId","outcomeVariant","iterationId","providerProfileId","failureCode","failureMessage"]'') AS observationFields,
 JSON_QUERY(N''["status","text","note","admission","timing"]'') AS entryFields,
 JSON_QUERY(N''{"providerEvidence":[],"display":["entry"],"deniedMembers":["authorization","proxy-authorization","x-api-key","x-goog-api-key","api_key","apikey","password","passwd","secret","client_secret","token","access_token","refresh_token","credential","credentials","credentialReference","opaqueCredentialBinding","privateKey","vaultKeyHandle","environment"],"payloadByteBound":4096,"eventByteBudget":65536,"invocationByteBudget":524288,"valueDictionaries":{"disposition":{"completed":1,"rejected":2,"failed":3,"cancelled":4,"held":5,"skipped":6}},"valueProjections":[{"field":"disposition","idField":"dispositionId"}]}'') AS objectFields
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

-- ============================== LIVE BASIS ==============================
-- The live policy is read from base tables only (never a view): the exact port
-- version the current capability version invokes, selected in the current
-- model. The migration refuses to re-declare from anything but the U1
-- generation (the declaration that installed providerEvidence [], dropped
-- shapes and dropped occurrenceId) or, on a replay after this installation,
-- its own O3 statement.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @live_statement nvarchar(max)=(SELECT TOP (1) JSON_VALUE(dt.document_text,'$.semantics.configuration.statement')
 FROM model.identity_namespace n
 JOIN model.capability c ON c.namespace_pk=n.namespace_pk AND c.capability_id=N'read-observation-telemetry-authority'
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
 JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
 JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
 JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
 JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=pv.semantic_object_definition_pk AND ed.estate_model_pk=@estate
 JOIN model.port p ON p.port_pk=pv.port_pk
 JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
 WHERE n.namespace_id=N'sidefx:capabilities' AND n.namespace_kind=N'CAPABILITY'
  AND p.port_id=N'read-observation-telemetry-authority-port');
DECLARE @live_statement_hash varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),(@live_statement) COLLATE Latin1_General_100_BIN2_UTF8))),2));
SELECT '0_live_basis' AS result_set, @live_statement_hash AS live_statement_sha256,
 CASE WHEN @live_statement_hash=N'4c9d97fdd97647e5ab368dd5dcd5369bab5f7198c2b542f89a92d815d23c3054' THEN N'U1'
      WHEN @live_statement_hash=N'360905c91f189b40aef0251d5353adc4fe9c7a23e321daf01cb51bfc6a3356a2' THEN N'O3'
      ELSE N'OTHER' END AS live_generation;
IF @live_statement_hash IS NULL OR @live_statement_hash NOT IN (N'4c9d97fdd97647e5ab368dd5dcd5369bab5f7198c2b542f89a92d815d23c3054',N'360905c91f189b40aef0251d5353adc4fe9c7a23e321daf01cb51bfc6a3356a2')
 THROW 51000,N'VALUE_IDS_LIVE_POLICY_NOT_U1',1;
EXEC model.declare_capability_document @document=@document;

-- ============================== PROOF ==============================
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
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.observationFields')) WHERE value=N'disposition') AS disposition_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.observationFields')) WHERE value=N'dispositionId') AS disposition_id_fields,
 (SELECT MIN(TRY_CONVERT(int,[key])) FROM OPENJSON(JSON_QUERY(value,'$.observationFields')) WHERE value=N'dispositionId') AS disposition_id_position,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.observationFields')) WHERE value IN (N'failureCode',N'failureMessage')) AS failure_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.observationFields')) WHERE value=N'occurrenceId') AS occurrence_id_in_observation_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.entryFields'))) AS entry_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.providerEvidence'))) AS provider_evidence_fields,
 CASE WHEN JSON_QUERY(value,'$.objectFields.providerEvidence') IS NULL THEN 0 ELSE 1 END AS provider_evidence_key_present,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.deniedMembers'))) AS denied_members,
 CASE WHEN JSON_QUERY(value,'$.objectFields.shapes') IS NULL THEN 0 ELSE 1 END AS shapes_present,
 JSON_VALUE(value,'$.objectFields.payloadByteBound') AS payload_byte_bound,
 JSON_VALUE(value,'$.objectFields.eventByteBudget') AS event_byte_budget,
 JSON_VALUE(value,'$.objectFields.invocationByteBudget') AS invocation_byte_budget,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.valueDictionaries'),'$.disposition')) AS disposition_dictionary_entries,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.valueProjections'))) AS value_projection_entries,
 JSON_VALUE(value,'$.objectFields.valueProjections[0].field') AS value_projection_field,
 JSON_VALUE(value,'$.objectFields.valueProjections[0].idField') AS value_projection_id_field
FROM @authority;

-- The declared disposition dictionary, printed in numeric-id order: the exact
-- six values and their exact 1-based IDs.
DECLARE @authority_value nvarchar(max)=(SELECT TOP (1) value FROM @authority);
SELECT '4_disposition_dictionary' AS result_set, d.[key] AS disposition_value, TRY_CONVERT(int,d.[value]) AS numeric_id
FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.valueDictionaries'),'$.disposition') d
ORDER BY TRY_CONVERT(int,d.[value]);

-- The O3 assertions, both printed and enforced: dispositionId is declared
-- immediately after disposition (44 observation fields), the disposition
-- dictionary holds exactly the six declared values at their exact IDs, there is
-- exactly one value projection (disposition -> dispositionId), and every other
-- member U1 declared is unchanged.
DECLARE @observation_fields int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.observationFields')));
DECLARE @disposition_index int=(SELECT MIN(TRY_CONVERT(int,[key])) FROM OPENJSON(JSON_QUERY(@authority_value,'$.observationFields')) WHERE value=N'disposition');
DECLARE @disposition_id_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.observationFields')) WHERE value=N'dispositionId');
DECLARE @disposition_id_index int=(SELECT MIN(TRY_CONVERT(int,[key])) FROM OPENJSON(JSON_QUERY(@authority_value,'$.observationFields')) WHERE value=N'dispositionId');
DECLARE @failure_field_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.observationFields')) WHERE value IN (N'failureCode',N'failureMessage'));
DECLARE @occurrence_id_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.observationFields')) WHERE value=N'occurrenceId');
DECLARE @entry_field_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.entryFields')));
DECLARE @provider_evidence_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.providerEvidence')));
DECLARE @provider_evidence_key_present int=CASE WHEN JSON_QUERY(@authority_value,'$.objectFields.providerEvidence') IS NULL THEN 0 ELSE 1 END;
DECLARE @denied_member_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.deniedMembers')));
DECLARE @shapes_present int=CASE WHEN JSON_QUERY(@authority_value,'$.objectFields.shapes') IS NULL THEN 0 ELSE 1 END;
DECLARE @dictionary_entries int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.valueDictionaries'),'$.disposition'));
DECLARE @dictionary_exact int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.valueDictionaries'),'$.disposition') e
 WHERE (e.[key]=N'completed' AND TRY_CONVERT(int,e.[value])=1)
    OR (e.[key]=N'rejected'  AND TRY_CONVERT(int,e.[value])=2)
    OR (e.[key]=N'failed'    AND TRY_CONVERT(int,e.[value])=3)
    OR (e.[key]=N'cancelled' AND TRY_CONVERT(int,e.[value])=4)
    OR (e.[key]=N'held'      AND TRY_CONVERT(int,e.[value])=5)
    OR (e.[key]=N'skipped'   AND TRY_CONVERT(int,e.[value])=6));
DECLARE @projection_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.valueProjections')));
DECLARE @projection_exact int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.valueProjections')) p
 WHERE JSON_VALUE(p.value,'$.field')=N'disposition' AND JSON_VALUE(p.value,'$.idField')=N'dispositionId');
SELECT '5_assertions' AS result_set,
 @observation_fields AS observation_fields,
 @disposition_id_count AS disposition_id_fields,
 @disposition_id_index AS disposition_id_position,
 @dictionary_entries AS dictionary_entries,
 @dictionary_exact AS dictionary_exact_entries,
 @projection_count AS value_projection_entries,
 @projection_exact AS value_projection_exact,
 @entry_field_count AS entry_fields,
 @failure_field_count AS failure_fields,
 @provider_evidence_count AS provider_evidence_fields,
 @provider_evidence_key_present AS provider_evidence_key_present,
 @denied_member_count AS denied_members,
 @shapes_present AS shapes_present,
 @occurrence_id_count AS occurrence_id_in_observation_fields,
 JSON_VALUE(@authority_value,'$.objectFields.payloadByteBound') AS payload_byte_bound,
 JSON_VALUE(@authority_value,'$.objectFields.eventByteBudget') AS event_byte_budget,
 JSON_VALUE(@authority_value,'$.objectFields.invocationByteBudget') AS invocation_byte_budget,
 CASE WHEN @observation_fields=44 AND @disposition_id_count=1 AND @disposition_id_index=@disposition_index+1
   AND @dictionary_entries=6 AND @dictionary_exact=6 AND @projection_count=1 AND @projection_exact=1
   AND @entry_field_count=5 AND @failure_field_count=2 AND @provider_evidence_count=0 AND @provider_evidence_key_present=1
   AND @denied_member_count=20 AND @shapes_present=0 AND @occurrence_id_count=0
   AND JSON_VALUE(@authority_value,'$.objectFields.payloadByteBound')=N'4096'
   AND JSON_VALUE(@authority_value,'$.objectFields.eventByteBudget')=N'65536'
   AND JSON_VALUE(@authority_value,'$.objectFields.invocationByteBudget')=N'524288'
  THEN N'PASS' ELSE N'FAIL' END AS disposition;
IF @observation_fields<>44 THROW 51000,N'VALUE_IDS_OBSERVATION_FIELD_COUNT',1;
IF @disposition_id_count<>1 THROW 51000,N'VALUE_IDS_DISPOSITION_ID_MISSING',1;
IF @disposition_id_index<>@disposition_index+1 THROW 51000,N'VALUE_IDS_DISPOSITION_ID_NOT_ADJACENT',1;
IF @dictionary_entries<>6 THROW 51000,N'VALUE_IDS_DICTIONARY_ENTRY_COUNT',1;
IF @dictionary_exact<>6 THROW 51000,N'VALUE_IDS_DICTIONARY_IDS_INEXACT',1;
IF @projection_count<>1 THROW 51000,N'VALUE_IDS_PROJECTION_COUNT',1;
IF @projection_exact<>1 THROW 51000,N'VALUE_IDS_PROJECTION_NOT_DISPOSITION',1;
IF @entry_field_count<>5 THROW 51000,N'VALUE_IDS_ENTRY_FIELDS_CHANGED',1;
IF @failure_field_count<>2 THROW 51000,N'VALUE_IDS_FAILURE_FIELDS_CHANGED',1;
IF @provider_evidence_count<>0 THROW 51000,N'VALUE_IDS_PROVIDER_EVIDENCE_NOT_EMPTY',1;
IF @provider_evidence_key_present<>1 THROW 51000,N'VALUE_IDS_PROVIDER_EVIDENCE_KEY_MISSING',1;
IF @denied_member_count<>20 THROW 51000,N'VALUE_IDS_DENIED_MEMBERS_CHANGED',1;
IF @shapes_present<>0 THROW 51000,N'VALUE_IDS_SHAPES_STILL_DECLARED',1;
IF @occurrence_id_count<>0 THROW 51000,N'VALUE_IDS_OCCURRENCE_ID_STILL_DECLARED',1;
IF JSON_VALUE(@authority_value,'$.objectFields.payloadByteBound')<>N'4096'
 OR JSON_VALUE(@authority_value,'$.objectFields.eventByteBudget')<>N'65536'
 OR JSON_VALUE(@authority_value,'$.objectFields.invocationByteBudget')<>N'524288'
 THROW 51000,N'VALUE_IDS_BUDGETS_CHANGED',1;

-- The uncommitted replay of the same document bytes answers UNCHANGED: the
-- installed-document gate, not a second version. A byte-identical install
-- writes nothing.
DECLARE @replay TABLE (action nvarchar(64), disposition nvarchar(64), capability_id nvarchar(400), document_digest varchar(64), contracts_declared int, scenarios_declared int, meaning_declared int, interface_declared int);
INSERT @replay EXEC model.declare_capability_document @document=@document;
SELECT '6_idempotent_replay' AS result_set, disposition, contracts_declared, scenarios_declared, meaning_declared, interface_declared, document_digest FROM @replay;
IF NOT EXISTS (SELECT 1 FROM @replay WHERE disposition=N'UNCHANGED') THROW 51000,N'VALUE_IDS_REPLAY_NOT_UNCHANGED',1;

-- The assembled graph source from the uncommitted transaction: the reader is
-- reachable through the estate view.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-observation-telemetry-authority',0,N'sidefx:capabilities'));
SELECT '7_graph_source' AS result_set,
 JSON_VALUE(@graph,'$.capabilityId') AS capability_id,
 JSON_VALUE(@graph,'$.rootScenarioId') AS root_scenario_id,
 (SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities') a
  CROSS APPLY OPENJSON(JSON_QUERY(a.value,'$.operations')) o
  WHERE JSON_VALUE(o.value,'$.operationId')=N'read-observation-telemetry-authority.0') AS operations_declared;

-- The re-declaration is proved above; the final transaction statement selects
-- the dry run (rollback) or the installation (commit).
ROLLBACK TRANSACTION;
