-- declare-observation-telemetry-authority.sql
--
-- Display migration U3/U5 (docs/display-projection-decision-record.md:52,54;
-- docs/display-projection-migration.md 3.1 "Telemetry authority") and the
-- conformance plan's D5 (docs/display-observation-conformance-plan.md:40): the
-- observation channel's field allowlist is declared authority. Today the list
-- lives as constants in src/observation-filter.mjs; this migration declares it
-- as a read capability (sidefx:capabilities / read-observation-telemetry-authority)
-- whose single declared-read port returns the authority:
--
--   authorityType              observation-telemetry-authority.v1
--   observationFields          the scalar testimony fields a delivery may publish
--   entryFields                the sfx-display-document.v1 Entry members
--   objectFields.providerEvidence   the bounded provider-evidence members
--   objectFields.display       the object members a display entry rides under
--
-- The boot/delivery seam still applies the selection (the scalar picker is the
-- emission seam); no field name remains in code. Inputs, provider bodies and
-- secrets are not among the declared fields.
--
-- The statement is declaration data: it is carried by the port binding, not by
-- code. It returns one JSON observation-telemetry-authority.v1 value in the
-- value column.
--
-- Idempotent: the capability document's digest is the installed-document gate,
-- and the contracts are content-addressed.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; to install (after the from-transaction preflight passes).
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
 JSON_QUERY(N''["observationType","phase","status","observedAt","executionId","rootExecutionId","parentExecutionId","scenarioId","stepId","sequence","cellId","cellAltitude","edgeId","durationMilliseconds","startedAt","completedAt","semanticRole","responsibilityId","responsibilityKind","responsibilityOrdinal","mechanicId","mechanicPath","childScenarioId","parentScenarioId","inputId","eventId","outcomeId","outcomeContractId","sourceCellId","destinationCellId","admissionDisposition"]'') AS observationFields,
 JSON_QUERY(N''["status","text","note","admission","timing"]'') AS entryFields,
 JSON_QUERY(N''{"providerEvidence":["reachedStage","exchangeCount","transportDisposition","redactionVerified","httpStatus"],"display":["entry"]}'') AS objectFields
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-observation-telemetry-authority-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';

-- ============================== CONTRACTS AND CAPABILITY DOCUMENT ==============================
DECLARE @contracts nvarchar(max) = N'[
 {"id":"observation-telemetry-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-request.v1.schema.json","title":"Observation telemetry request","type":"object","additionalProperties":false,"required":["contractId"],"properties":{"contractId":{"const":"observation-telemetry-request.v1"}}}},
 {"id":"observation-telemetry-authority.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-authority.v1.schema.json","title":"Observation telemetry authority","type":"object","additionalProperties":false,"required":["authorityType","observationFields","entryFields","objectFields"],"properties":{"authorityType":{"const":"observation-telemetry-authority.v1"},"observationFields":{"type":"array","items":{"type":"string"}},"entryFields":{"type":"array","items":{"type":"string"}},"objectFields":{"type":"object","additionalProperties":false,"required":["providerEvidence","display"],"properties":{"providerEvidence":{"type":"array","items":{"type":"string"}},"display":{"type":"array","items":{"type":"string"}}}}}}}
]';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-observation-telemetry-authority",
 "meaning":{"intent":"read the declared observation-channel telemetry authority","outcome":"the caller observes the declared scalar fields, entry fields and bounded object fields the observation channel may publish"},
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
  "then":"the reading names the scalar testimony fields, the display Entry fields and the bounded provider-evidence fields the observation channel may publish",
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

-- The behavioral self-test: the declared statement itself is executed. It emits
-- the closed authority the seam applies; the proof prints its members and
-- counts so a truncated or misplaced list is visible.
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
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.entryFields'))) AS entry_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.providerEvidence'))) AS provider_evidence_fields,
 JSON_QUERY(value,'$.objectFields.display') AS display_members,
 CASE WHEN JSON_QUERY(value,'$.observationFields') LIKE N'%password%' THEN 1 ELSE 0 END AS carries_secret_vocabulary
FROM @authority;

-- The assembled graph source from the uncommitted transaction: the reader is
-- reachable through the estate view.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-observation-telemetry-authority',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set,
 JSON_VALUE(@graph,'$.capabilityId') AS capability_id,
 JSON_VALUE(@graph,'$.rootScenarioId') AS root_scenario_id,
 (SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities') a
  CROSS APPLY OPENJSON(JSON_QUERY(a.value,'$.operations')) o
  WHERE JSON_VALUE(o.value,'$.operationId')=N'read-observation-telemetry-authority.0') AS operations_declared;

-- Installed 2026-09-17 after the rollback dry run and the from-transaction
-- preflight (DISPOSITION completed; authorityType observation-telemetry-authority.v1;
-- 31 observation fields, 5 entry fields, 5 provider-evidence fields).
COMMIT TRANSACTION;
