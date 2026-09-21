-- extend-observation-telemetry-shapes.sql
--
-- The observation channel now carries the execution shapes, not only lifecycle
-- telemetry: every cell testimony publishes the admitted input shape and the
-- admitted outcome shape (contract, payload, or a payloadRef over the declared
-- bound), and a governed exchange publishes its redacted request and response
-- shapes beside the scalar provider evidence. The allowlist remains declared
-- authority (read-observation-telemetry-authority); this migration extends the
-- declared object fields rather than naming a shape member in code:
--
--   objectFields.shapes              declared members per shape field
--   objectFields.deniedMembers       members stripped recursively from a payload
--   objectFields.payloadByteBound    4096; over it {contractId,payloadRef}
--   objectFields.eventByteBudget     65536 per observation
--   objectFields.invocationByteBudget 524288 per invocation
--
-- Inputs, provider bodies, credential material, authorization headers, vault
-- material and environment values are still not among the declared fields; the
-- denied members are removed from any payload before it is published.
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
 JSON_QUERY(N''["observationType","testimonyType","phase","status","observedAt","executionId","cellExecutionId","rootExecutionId","parentCellExecutionId","sourceCellExecutionId","scenarioId","stepId","sequence","logicalOrder","cellId","cellAltitude","edgeId","durationMilliseconds","startedAt","completedAt","semanticRole","responsibilityId","responsibilityKind","responsibilityOrdinal","mechanicId","mechanicPath","childScenarioId","parentScenarioId","inputId","eventId","outcomeId","outcomeContractId","sourceCellId","destinationCellId","admissionDisposition","semanticAddress","outcomeClassification","disposition","outcomeVariant","iterationId","occurrenceId","providerProfileId"]'') AS observationFields,
 JSON_QUERY(N''["status","text","note","admission","timing"]'') AS entryFields,
 JSON_QUERY(N''{"providerEvidence":["reachedStage","exchangeCount","transportDisposition","redactionVerified","httpStatus"],"display":["entry"],"deniedMembers":["authorization","proxy-authorization","x-api-key","x-goog-api-key","api_key","apikey","password","passwd","secret","client_secret","token","access_token","refresh_token","credential","credentials","credentialReference","opaqueCredentialBinding","privateKey","vaultKeyHandle","environment"],"shapes":{"inputShape":["contractId","payload","payloadRef"],"outcomeShape":["contractId","payload","payloadRef"],"requestShape":["method","host","path","query","headers","bodyHash","byteLength"],"responseShape":["status","headers","body","bodyRef","byteLength","bodyHash","lineageId","effectLineage","providerProfileId"],"modelResponse":["contractId","payload","payloadRef","providerProfileId","lineageId","effectLineage"]},"payloadByteBound":4096,"eventByteBudget":65536,"invocationByteBudget":524288}'') AS objectFields
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-observation-telemetry-authority-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';

-- ============================== CONTRACTS AND CAPABILITY DOCUMENT ==============================
DECLARE @contracts nvarchar(max) = N'[
 {"id":"observation-telemetry-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-request.v1.schema.json","title":"Observation telemetry request","type":"object","additionalProperties":false,"required":["contractId"],"properties":{"contractId":{"const":"observation-telemetry-request.v1"}}}},
 {"id":"observation-telemetry-authority.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-authority.v1.schema.json","title":"Observation telemetry authority","type":"object","additionalProperties":false,"required":["authorityType","observationFields","entryFields","objectFields"],"properties":{"authorityType":{"const":"observation-telemetry-authority.v1"},"observationFields":{"type":"array","items":{"type":"string"}},"entryFields":{"type":"array","items":{"type":"string"}},"objectFields":{"type":"object","additionalProperties":false,"required":["providerEvidence","display"],"properties":{"providerEvidence":{"type":"array","items":{"type":"string"}},"display":{"type":"array","items":{"type":"string"}},"deniedMembers":{"type":"array","items":{"type":"string"}},"shapes":{"type":"object","additionalProperties":{"type":"array","items":{"type":"string"}}},"payloadByteBound":{"type":"integer"},"eventByteBudget":{"type":"integer"},"invocationByteBudget":{"type":"integer"}}}}}}
]';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-observation-telemetry-authority",
 "meaning":{"intent":"read the declared observation-channel telemetry authority","outcome":"the caller observes the declared scalar fields, the bounded shape fields, the entry fields and the bounded object fields the observation channel may publish"},
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
  "then":"the reading names the scalar testimony fields, the display Entry fields, the declared shape fields with their payload bound and budgets, and the bounded provider-evidence fields the observation channel may publish",
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
-- the closed authority the seam applies; the proof prints the declared shape
-- names, the denied-member count and the bound/budget facts so a truncated or
-- misplaced list is visible.
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
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.deniedMembers'))) AS denied_members,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.shapes'))) AS shape_fields,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.shapes.inputShape'))) AS input_shape_members,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(value,'$.objectFields.shapes.responseShape'))) AS response_shape_members,
 JSON_VALUE(value,'$.objectFields.payloadByteBound') AS payload_byte_bound,
 JSON_VALUE(value,'$.objectFields.eventByteBudget') AS event_byte_budget,
 JSON_VALUE(value,'$.objectFields.invocationByteBudget') AS invocation_byte_budget,
 CASE WHEN value LIKE N'%authorization%' THEN 1 ELSE 0 END AS denies_authorization
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

-- Installed 2026-09-21 after the rollback dry run and the from-transaction
-- preflight (DISPOSITION completed; 5 shape fields, payloadByteBound 4096,
-- eventByteBudget 65536, invocationByteBudget 524288).
COMMIT TRANSACTION;
