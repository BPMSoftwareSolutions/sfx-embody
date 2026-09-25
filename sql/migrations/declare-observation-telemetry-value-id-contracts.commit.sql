-- declare-observation-telemetry-value-id-contracts.sql
--
-- Wave 1 O3 contract follow-up (foundations plan section 12.1): the installed O3
-- policy (extend-observation-telemetry-value-ids.commit.sql; its declared
-- statement hashes
-- sha256:360905c91f189b40aef0251d5353adc4fe9c7a23e321daf01cb51bfc6a3356a2)
-- returns objectFields.valueDictionaries and objectFields.valueProjections, but
-- the installed contract observation-telemetry-authority.v1 still declared
-- objectFields.additionalProperties=false with only the seven earlier
-- properties, so a strict schema validation of the returned authority flags the
-- two new members. This migration re-declares the capability document from that
-- live policy with exactly two contract properties added and nothing else
-- changed:
--
--   objectFields.properties.valueDictionaries  object of property name -> object
--                                             of canonical value -> integer wire ID
--   objectFields.properties.valueProjections   array of {field, idField}
--                                             objects
--
-- The amended schema is the live contract literal with the two property schemas
-- inserted after invocationByteBudget and before its closing braces, so every
-- prior property, description, required list, const and additionalProperties
-- flag is preserved verbatim. The observation-telemetry-request.v1 contract, the
-- meaning, the scenario, the declared read statement and the port binding are
-- preserved verbatim from the live O3 policy; the statement hash and the
-- installed document digest are asserted before anything is declared.
--
-- Idempotent: the capability document's digest is the installed-document gate,
-- and the contracts are content-addressed. A byte-identical replay answers
-- UNCHANGED and writes nothing (proved by the replay below). On a replay the
-- live contract and the live document are this migration's own, which the
-- live-basis guards accept alongside the O3 generation they amend.
--
-- The pair, declare-observation-telemetry-value-id-contracts.sql and
-- declare-observation-telemetry-value-id-contracts.commit.sql, is byte-identical
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
-- The statement is declaration data preserved verbatim from the live O3 policy:
-- it is carried by the port binding, not by code. It receives @input (unused:
-- the authority is model-wide) and returns one JSON
-- observation-telemetry-authority.v1 value in the value column.
DECLARE @statement nvarchar(max) = N'
SELECT (SELECT N''observation-telemetry-authority.v1'' AS authorityType,
 JSON_QUERY(N''["observationType","testimonyType","phase","status","observedAt","executionId","cellExecutionId","rootExecutionId","parentCellExecutionId","sourceCellExecutionId","scenarioId","stepId","sequence","logicalOrder","cellId","cellAltitude","edgeId","durationMilliseconds","startedAt","completedAt","semanticRole","responsibilityId","responsibilityKind","responsibilityOrdinal","mechanicId","mechanicPath","childScenarioId","parentScenarioId","inputId","eventId","outcomeId","outcomeContractId","sourceCellId","destinationCellId","admissionDisposition","semanticAddress","outcomeClassification","disposition","dispositionId","outcomeVariant","iterationId","providerProfileId","failureCode","failureMessage"]'') AS observationFields,
 JSON_QUERY(N''["status","text","note","admission","timing"]'') AS entryFields,
 JSON_QUERY(N''{"providerEvidence":[],"display":["entry"],"deniedMembers":["authorization","proxy-authorization","x-api-key","x-goog-api-key","api_key","apikey","password","passwd","secret","client_secret","token","access_token","refresh_token","credential","credentials","credentialReference","opaqueCredentialBinding","privateKey","vaultKeyHandle","environment"],"payloadByteBound":4096,"eventByteBudget":65536,"invocationByteBudget":524288,"valueDictionaries":{"disposition":{"completed":1,"rejected":2,"failed":3,"cancelled":4,"held":5,"skipped":6}},"valueProjections":[{"field":"disposition","idField":"dispositionId"}]}'') AS objectFields
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-observation-telemetry-authority-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';

-- ============================== THE AMENDED CONTRACT ==============================
-- The prior contract literal, exactly as the installed O3 policy declares it
-- (schema sha256 06daa828d6206a7d9324ebacde6b2bb300551e09e283ba4667c66495c63ae3ad).
DECLARE @prior_contract_schema nvarchar(max) = N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-authority.v1.schema.json","title":"Observation telemetry authority","type":"object","additionalProperties":false,"required":["authorityType","observationFields","entryFields","objectFields"],"properties":{"authorityType":{"const":"observation-telemetry-authority.v1"},"observationFields":{"type":"array","items":{"type":"string"}},"entryFields":{"type":"array","items":{"type":"string"}},"objectFields":{"type":"object","additionalProperties":false,"required":["providerEvidence","display"],"properties":{"providerEvidence":{"type":"array","items":{"type":"string"}},"display":{"type":"array","items":{"type":"string"}},"deniedMembers":{"type":"array","items":{"type":"string"}},"shapes":{"type":"object","additionalProperties":{"type":"array","items":{"type":"string"}}},"payloadByteBound":{"type":"integer"},"eventByteBudget":{"type":"integer"},"invocationByteBudget":{"type":"integer"}}}}}';
DECLARE @value_dictionaries_schema nvarchar(max) = N'{"type":"object","additionalProperties":{"type":"object","additionalProperties":{"type":"integer"}}}';
DECLARE @value_projections_schema nvarchar(max) = N'{"type":"array","items":{"type":"object","additionalProperties":false,"required":["field","idField"],"properties":{"field":{"type":"string"},"idField":{"type":"string"}}}}';
-- The amended schema inserts the two property schemas immediately after
-- invocationByteBudget and before the four closing braces (properties,
-- objectFields, properties, schema); every byte of the prior schema stays.
DECLARE @authority_additions nvarchar(max) = N',"valueDictionaries":' + @value_dictionaries_schema
 + N',"valueProjections":' + @value_projections_schema;
DECLARE @authority_schema nvarchar(max) = STUFF(@prior_contract_schema, LEN(@prior_contract_schema)-3, 0, @authority_additions);

-- ============================== CONTRACTS AND CAPABILITY DOCUMENT ==============================
-- The request contract is preserved verbatim from the live policy; only the
-- authority contract carries the two added properties.
DECLARE @contracts nvarchar(max) = N'[
 {"id":"observation-telemetry-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/observation-telemetry-request.v1.schema.json","title":"Observation telemetry request","type":"object","additionalProperties":false,"required":["contractId"],"properties":{"contractId":{"const":"observation-telemetry-request.v1"}}}},
 {"id":"observation-telemetry-authority.v1","schema":' + @authority_schema + N'}
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
DECLARE @document_bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@document) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @amended_document_digest varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',@document_bytes),2));

-- ============================== LIVE BASIS ==============================
-- The live policy and the live contract are read from base tables only (never a
-- view): the exact port version the current capability version invokes, selected
-- in the current model, and the current contract definition. The migration
-- refuses to re-declare from anything but the O3 generation (the declaration
-- that installed the value dictionaries and the value projection) or, on a
-- replay after this installation, its own amended contract and document.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @o3_statement_hash varchar(64)=N'360905c91f189b40aef0251d5353adc4fe9c7a23e321daf01cb51bfc6a3356a2';
DECLARE @o3_document_digest varchar(64)=N'21d063fe39a2180d5ce231febb1d882bb885844fd45514ba1c5dd01bed82a748';
DECLARE @prior_schema_hash varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),(@prior_contract_schema) COLLATE Latin1_General_100_BIN2_UTF8))),2));
DECLARE @amended_schema_hash varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),(@authority_schema) COLLATE Latin1_General_100_BIN2_UTF8))),2));

DECLARE @live_statement nvarchar(max), @live_port_digest binary(32);
SELECT TOP (1) @live_statement=JSON_VALUE(dt.document_text,'$.semantics.configuration.statement'),
 @live_port_digest=pv.definition_digest
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
  AND p.port_id=N'read-observation-telemetry-authority-port';
DECLARE @live_statement_hash varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),(@live_statement) COLLATE Latin1_General_100_BIN2_UTF8))),2));

DECLARE @live_contracts TABLE (contract_id nvarchar(400), semantic_object_definition_pk bigint,
 contract_definition_digest binary(32), schema_object_pk bigint, schema_content_digest binary(32),
 schema_byte_length bigint, schema_text nvarchar(max));
INSERT @live_contracts
SELECT s.declared_id, sod.semantic_object_definition_pk, sod.definition_digest, so.schema_object_pk,
 so.content_digest, co.byte_length,
 CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.identity_namespace n
JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk
 AND s.declared_id IN (N'observation-telemetry-request.v1',N'observation-telemetry-authority.v1')
JOIN model.semantic_object_definition sod ON sod.semantic_object_pk=s.semantic_object_pk
JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=sod.semantic_object_definition_pk AND ed.estate_model_pk=@estate
JOIN model.contract_version cv ON cv.semantic_object_definition_pk=sod.semantic_object_definition_pk
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
WHERE n.namespace_id=N'sidefx:contracts' AND n.namespace_kind=N'CONTRACT'
 AND sod.semantic_object_definition_pk=(SELECT MAX(d2.semantic_object_definition_pk)
  FROM model.estate_definition ed2 JOIN model.semantic_object_definition d2
   ON d2.semantic_object_definition_pk=ed2.semantic_object_definition_pk
  WHERE ed2.estate_model_pk=@estate AND d2.semantic_object_pk=s.semantic_object_pk);
DECLARE @live_authority_schema nvarchar(max)=(SELECT lc.schema_text FROM @live_contracts lc WHERE lc.contract_id=N'observation-telemetry-authority.v1');
DECLARE @live_contract_schema_hash varchar(64)=LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),(@live_authority_schema) COLLATE Latin1_General_100_BIN2_UTF8))),2));
DECLARE @live_request_digest varchar(64)=(SELECT LOWER(CONVERT(varchar(64),lc.contract_definition_digest,2))
 FROM @live_contracts lc WHERE lc.contract_id=N'observation-telemetry-request.v1');

DECLARE @live_document_digest varchar(64)=(SELECT JSON_VALUE(dt.document_text,'$.semantics.document_digest')
 FROM model.identity_namespace n
 JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk AND s.declared_id=N'read-observation-telemetry-authority'
 JOIN model.semantic_object_definition sod ON sod.semantic_object_pk=s.semantic_object_pk
 JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=sod.semantic_object_definition_pk AND ed.estate_model_pk=@estate
 JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
 CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document_text) dt
 WHERE n.namespace_id=N'sidefx:capability-documents' AND n.namespace_kind=N'CAPABILITY_DOCUMENT'
  AND sod.semantic_object_definition_pk=(SELECT MAX(d2.semantic_object_definition_pk)
   FROM model.estate_definition ed2 JOIN model.semantic_object_definition d2
    ON d2.semantic_object_definition_pk=ed2.semantic_object_definition_pk
   WHERE ed2.estate_model_pk=@estate AND d2.semantic_object_pk=s.semantic_object_pk));

SELECT '0_live_basis' AS result_set,
 @live_statement_hash AS live_statement_sha256,
 LEN(@live_statement) AS live_statement_length,
 CASE WHEN @live_statement_hash=@o3_statement_hash THEN N'O3' ELSE N'OTHER' END AS statement_generation,
 @live_contract_schema_hash AS live_contract_schema_sha256,
 @prior_schema_hash AS prior_schema_sha256,
 @amended_schema_hash AS amended_schema_sha256,
 CASE WHEN @live_contract_schema_hash=@prior_schema_hash THEN N'O3_PRIOR'
      WHEN @live_contract_schema_hash=@amended_schema_hash THEN N'O3_AMENDED'
      ELSE N'OTHER' END AS contract_generation,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@live_authority_schema,'$.properties.objectFields.properties')) p
  WHERE p.[key] IN (N'valueDictionaries',N'valueProjections')) AS live_contract_new_properties,
 @live_document_digest AS live_document_digest,
 @amended_document_digest AS amended_document_digest,
 CASE WHEN @live_document_digest=@o3_document_digest THEN N'O3'
      WHEN @live_document_digest=@amended_document_digest THEN N'O3_AMENDED'
      ELSE N'OTHER' END AS document_generation;

IF @live_statement_hash IS NULL OR @live_statement_hash<>@o3_statement_hash
 THROW 51000,N'VALUE_ID_CONTRACTS_LIVE_POLICY_NOT_O3',1;
IF @live_contract_schema_hash IS NULL OR @live_contract_schema_hash NOT IN (@prior_schema_hash,@amended_schema_hash)
 THROW 51000,N'VALUE_ID_CONTRACTS_LIVE_CONTRACT_NOT_O3_OR_AMENDED',1;
IF @live_document_digest IS NULL OR @live_document_digest NOT IN (@o3_document_digest,@amended_document_digest)
 THROW 51000,N'VALUE_ID_CONTRACTS_LIVE_DOCUMENT_NOT_O3_OR_AMENDED',1;

EXEC model.declare_capability_document @document=@document;

-- ============================== PROOF ==============================
-- The installed contract, re-read from base tables after the declaration.
DECLARE @installed_contracts TABLE (contract_id nvarchar(400), semantic_object_definition_pk bigint,
 contract_definition_digest binary(32), schema_object_pk bigint, schema_content_digest binary(32),
 schema_byte_length bigint, schema_text nvarchar(max));
INSERT @installed_contracts
SELECT s.declared_id, sod.semantic_object_definition_pk, sod.definition_digest, so.schema_object_pk,
 so.content_digest, co.byte_length,
 CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.identity_namespace n
JOIN model.semantic_object s ON s.namespace_pk=n.namespace_pk
 AND s.declared_id IN (N'observation-telemetry-request.v1',N'observation-telemetry-authority.v1')
JOIN model.semantic_object_definition sod ON sod.semantic_object_pk=s.semantic_object_pk
JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=sod.semantic_object_definition_pk AND ed.estate_model_pk=@estate
JOIN model.contract_version cv ON cv.semantic_object_definition_pk=sod.semantic_object_definition_pk
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
WHERE n.namespace_id=N'sidefx:contracts' AND n.namespace_kind=N'CONTRACT'
 AND sod.semantic_object_definition_pk=(SELECT MAX(d2.semantic_object_definition_pk)
  FROM model.estate_definition ed2 JOIN model.semantic_object_definition d2
   ON d2.semantic_object_definition_pk=ed2.semantic_object_definition_pk
  WHERE ed2.estate_model_pk=@estate AND d2.semantic_object_pk=s.semantic_object_pk);
DECLARE @installed_schema nvarchar(max)=(SELECT ic.schema_text FROM @installed_contracts ic WHERE ic.contract_id=N'observation-telemetry-authority.v1');
DECLARE @installed_schema_digest binary(32)=(SELECT ic.schema_content_digest FROM @installed_contracts ic WHERE ic.contract_id=N'observation-telemetry-authority.v1');
DECLARE @installed_contract_digest binary(32)=(SELECT ic.contract_definition_digest FROM @installed_contracts ic WHERE ic.contract_id=N'observation-telemetry-authority.v1');
DECLARE @installed_contract_sod bigint=(SELECT ic.semantic_object_definition_pk FROM @installed_contracts ic WHERE ic.contract_id=N'observation-telemetry-authority.v1');
DECLARE @installed_request_digest varchar(64)=(SELECT LOWER(CONVERT(varchar(64),ic.contract_definition_digest,2))
 FROM @installed_contracts ic WHERE ic.contract_id=N'observation-telemetry-request.v1');

SELECT '1_contracts' AS result_set, ic.contract_id, ic.semantic_object_definition_pk,
 LOWER(CONVERT(varchar(64),ic.contract_definition_digest,2)) AS contract_definition_digest,
 ic.schema_object_pk, LOWER(CONVERT(varchar(64),ic.schema_content_digest,2)) AS schema_content_digest,
 ic.schema_byte_length
FROM @installed_contracts ic ORDER BY ic.contract_id;

-- The installed port binding, re-read from base tables: the port definition is
-- unchanged because the statement is unchanged.
DECLARE @installed_port_digest binary(32), @installed_port_version_pk bigint,
 @installed_scenario_version_pk bigint, @installed_platform_capability_id nvarchar(400),
 @installed_result_column nvarchar(400);
SELECT @installed_port_version_pk=pv.port_version_pk, @installed_port_digest=pv.definition_digest,
 @installed_scenario_version_pk=cs.scenario_version_pk,
 @installed_platform_capability_id=JSON_VALUE(dt.document_text,'$.semantics.platformCapabilityId'),
 @installed_result_column=JSON_VALUE(dt.document_text,'$.semantics.configuration.resultColumn')
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
 AND p.port_id=N'read-observation-telemetry-authority-port';
DECLARE @installed_statement nvarchar(max)=(SELECT JSON_VALUE(dt.document_text,'$.semantics.configuration.statement')
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

SELECT '2_capability' AS result_set, c.capability_id, cs.scenario_version_pk, se.event_id,
 N'read-observation-telemetry-authority-port' AS port_id, @installed_port_version_pk AS port_version_pk,
 LOWER(CONVERT(varchar(64),@installed_port_digest,2)) AS port_definition_digest,
 @installed_platform_capability_id AS platform_capability_id, @installed_result_column AS result_column
FROM model.identity_namespace n
JOIN model.capability c ON c.namespace_pk=n.namespace_pk AND c.capability_id=N'read-observation-telemetry-authority'
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
WHERE n.namespace_id=N'sidefx:capabilities' AND n.namespace_kind=N'CAPABILITY';

-- The behavioral self-test: the installed statement itself is executed, exactly
-- as the boot filter executes it. It prints the resulting counts so a
-- truncated, renamed or re-expanded member is visible.
DECLARE @authority TABLE (value nvarchar(max));
INSERT @authority EXEC sp_executesql @installed_statement;
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

-- The O3 assertions, both printed and enforced: the amended contract did not
-- change what the read returns. dispositionId is declared immediately after
-- disposition (44 observation fields), the disposition dictionary holds exactly
-- the six declared values at their exact IDs, there is exactly one value
-- projection (disposition -> dispositionId), and every other member U1 declared
-- is unchanged.
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
SELECT '5_authority_assertions' AS result_set,
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
IF @observation_fields<>44 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_FIELD_COUNT',1;
IF @disposition_id_count<>1 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_ID_MISSING',1;
IF @disposition_id_index<>@disposition_index+1 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_ID_NOT_ADJACENT',1;
IF @dictionary_entries<>6 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_DICTIONARY_COUNT',1;
IF @dictionary_exact<>6 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_DICTIONARY_IDS',1;
IF @projection_count<>1 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_PROJECTION_COUNT',1;
IF @projection_exact<>1 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_PROJECTION_EXACT',1;
IF @entry_field_count<>5 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_ENTRY_FIELDS',1;
IF @failure_field_count<>2 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_FAILURE_FIELDS',1;
IF @provider_evidence_count<>0 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_PROVIDER_EVIDENCE',1;
IF @provider_evidence_key_present<>1 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_PROVIDER_EVIDENCE_KEY',1;
IF @denied_member_count<>20 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_DENIED_MEMBERS',1;
IF @shapes_present<>0 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_SHAPES',1;
IF @occurrence_id_count<>0 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_OCCURRENCE_ID',1;
IF JSON_VALUE(@authority_value,'$.objectFields.payloadByteBound')<>N'4096'
 OR JSON_VALUE(@authority_value,'$.objectFields.eventByteBudget')<>N'65536'
 OR JSON_VALUE(@authority_value,'$.objectFields.invocationByteBudget')<>N'524288'
 THROW 51000,N'VALUE_ID_CONTRACTS_AUTHORITY_BUDGETS',1;

-- The contract assertions, both printed and enforced: the installed contract is
-- the prior literal with exactly the two property schemas appended, the two new
-- properties exist with the declared shapes, additionalProperties is still
-- false at the root and at objectFields, the seven prior properties and both
-- required lists are unchanged, and nothing else in the document moved.
DECLARE @prior_prefix nvarchar(max)=LEFT(@prior_contract_schema,LEN(@prior_contract_schema)-4);
DECLARE @installed_prefix nvarchar(max)=LEFT(@installed_schema,LEN(@prior_contract_schema)-4);
DECLARE @expected_suffix nvarchar(max)=@authority_additions+N'}}}}';
DECLARE @installed_suffix nvarchar(max)=RIGHT(@installed_schema,LEN(@expected_suffix));
DECLARE @new_properties_present int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@installed_schema,'$.properties.objectFields.properties')) p
 WHERE p.[key] IN (N'valueDictionaries',N'valueProjections'));
DECLARE @object_property_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@installed_schema,'$.properties.objectFields.properties')));
DECLARE @object_property_names nvarchar(max)=(SELECT STRING_AGG(p.[key],N',') FROM OPENJSON(JSON_QUERY(@installed_schema,'$.properties.objectFields.properties')) p);
DECLARE @prior_properties_present int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@installed_schema,'$.properties.objectFields.properties')) p
 WHERE p.[key] IN (N'providerEvidence',N'display',N'deniedMembers',N'shapes',N'payloadByteBound',N'eventByteBudget',N'invocationByteBudget'));
DECLARE @object_additional_properties nvarchar(10)=JSON_VALUE(@installed_schema,'$.properties.objectFields.additionalProperties');
DECLARE @root_additional_properties nvarchar(10)=JSON_VALUE(@installed_schema,'$.additionalProperties');
DECLARE @object_required nvarchar(max)=(SELECT STRING_AGG(r.value,N',') WITHIN GROUP (ORDER BY TRY_CONVERT(int,r.[key])) FROM OPENJSON(JSON_QUERY(@installed_schema,'$.properties.objectFields.required')) r);
DECLARE @root_required nvarchar(max)=(SELECT STRING_AGG(r.value,N',') WITHIN GROUP (ORDER BY TRY_CONVERT(int,r.[key])) FROM OPENJSON(JSON_QUERY(@installed_schema,'$.required')) r);
DECLARE @dictionary_schema_exact int=CASE WHEN JSON_QUERY(@installed_schema,'$.properties.objectFields.properties.valueDictionaries')=@value_dictionaries_schema THEN 1 ELSE 0 END;
DECLARE @projection_schema_exact int=CASE WHEN JSON_QUERY(@installed_schema,'$.properties.objectFields.properties.valueProjections')=@value_projections_schema THEN 1 ELSE 0 END;
DECLARE @outcome_bound int=(SELECT COUNT(*)
 FROM model.scenario_outcome_contract soc
 JOIN model.capability_scenario cs ON cs.scenario_version_pk=soc.scenario_version_pk
 JOIN model.estate_capability ec ON ec.capability_version_pk=cs.capability_version_pk AND ec.estate_model_pk=@estate
 JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=N'read-observation-telemetry-authority'
 JOIN model.contract_version cv ON cv.contract_version_pk=soc.contract_version_pk
 WHERE cv.semantic_object_definition_pk=@installed_contract_sod);
SELECT '6_contract_assertions' AS result_set,
 LOWER(CONVERT(varchar(64),@installed_schema_digest,2)) AS schema_content_digest,
 LOWER(CONVERT(varchar(64),@installed_contract_digest,2)) AS contract_definition_digest,
 CASE WHEN @installed_schema=@authority_schema THEN N'EXACT' ELSE N'DIFFERS' END AS installed_schema,
 @new_properties_present AS new_properties_present,
 @dictionary_schema_exact AS value_dictionaries_schema_exact,
 @projection_schema_exact AS value_projections_schema_exact,
 @object_property_count AS object_property_count,
 @prior_properties_present AS prior_properties_present,
 @object_property_names AS object_property_names,
 @object_additional_properties AS object_fields_additional_properties,
 @root_additional_properties AS root_additional_properties,
 @object_required AS object_fields_required,
 @root_required AS root_required,
 CASE WHEN @installed_prefix=@prior_prefix THEN N'UNCHANGED' ELSE N'CHANGED' END AS prior_properties_text,
 CASE WHEN @installed_suffix=@expected_suffix THEN N'EXACT' ELSE N'DIFFERS' END AS additions_text,
 CASE WHEN @installed_request_digest=@live_request_digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS request_contract,
 CASE WHEN @installed_port_digest=@live_port_digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS port_definition,
 @outcome_bound AS outcome_contract_points_at_amended,
 CASE WHEN @installed_schema=@authority_schema AND @new_properties_present=2 AND @dictionary_schema_exact=1
   AND @projection_schema_exact=1 AND @object_property_count=9 AND @prior_properties_present=7
   AND @object_additional_properties=N'false' AND @root_additional_properties=N'false'
   AND @object_required=N'providerEvidence,display'
   AND @installed_prefix=@prior_prefix AND @installed_suffix=@expected_suffix
   AND @installed_request_digest=@live_request_digest AND @installed_port_digest=@live_port_digest AND @outcome_bound=1
  THEN N'PASS' ELSE N'FAIL' END AS disposition;
IF @installed_schema IS NULL OR @installed_schema<>@authority_schema THROW 51000,N'VALUE_ID_CONTRACTS_SCHEMA_NOT_INSTALLED',1;
IF @installed_schema_digest IS NULL OR @installed_schema_digest<>CONVERT(binary(32),@amended_schema_hash,2) THROW 51000,N'VALUE_ID_CONTRACTS_SCHEMA_DIGEST_MISMATCH',1;
IF @new_properties_present<>2 THROW 51000,N'VALUE_ID_CONTRACTS_NEW_PROPERTIES_MISSING',1;
IF @dictionary_schema_exact<>1 OR @projection_schema_exact<>1 THROW 51000,N'VALUE_ID_CONTRACTS_NEW_PROPERTY_SCHEMAS_CHANGED',1;
IF @object_property_count<>9 OR @prior_properties_present<>7 THROW 51000,N'VALUE_ID_CONTRACTS_PROPERTY_COUNT_CHANGED',1;
IF @object_additional_properties<>N'false' OR @root_additional_properties<>N'false' THROW 51000,N'VALUE_ID_CONTRACTS_ADDITIONAL_PROPERTIES_OPEN',1;
IF @installed_prefix<>@prior_prefix OR @installed_suffix<>@expected_suffix THROW 51000,N'VALUE_ID_CONTRACTS_PRIOR_PROPERTIES_CHANGED',1;
IF @object_required<>N'providerEvidence,display' THROW 51000,N'VALUE_ID_CONTRACTS_REQUIRED_LIST_CHANGED',1;
IF @installed_request_digest<>@live_request_digest THROW 51000,N'VALUE_ID_CONTRACTS_REQUEST_CONTRACT_CHANGED',1;
IF @installed_port_digest IS NULL OR @installed_port_digest<>@live_port_digest THROW 51000,N'VALUE_ID_CONTRACTS_PORT_CHANGED',1;
IF @outcome_bound<>1 THROW 51000,N'VALUE_ID_CONTRACTS_OUTCOME_NOT_BOUND',1;

-- The amended contract admits the returned authority: every objectFields member
-- the read returns is declared, the two new members have the declared shapes,
-- and no undeclared member survives a strict objectFields validation.
DECLARE @undeclared_object_members int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields')) m
 WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@installed_schema,'$.properties.objectFields.properties')) p WHERE p.[key]=m.[key]));
DECLARE @dictionary_property_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.valueDictionaries')));
DECLARE @dictionary_noninteger_values int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.valueDictionaries')) d
 CROSS APPLY OPENJSON(JSON_QUERY(d.value)) v WHERE TRY_CONVERT(int,v.value) IS NULL);
DECLARE @projection_member_count int=(SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields.valueProjections')) p
 WHERE JSON_VALUE(p.value,'$.field') IS NOT NULL AND JSON_VALUE(p.value,'$.idField') IS NOT NULL);
SELECT '7_contract_admits_read' AS result_set,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@authority_value,'$.objectFields'))) AS object_field_members,
 @undeclared_object_members AS undeclared_object_field_members,
 @dictionary_property_count AS value_dictionary_properties,
 @dictionary_noninteger_values AS value_dictionary_noninteger_values,
 @projection_member_count AS value_projection_members,
 CASE WHEN @undeclared_object_members=0 AND @dictionary_property_count=1 AND @dictionary_noninteger_values=0
   AND @projection_member_count=1 THEN N'PASS' ELSE N'FAIL' END AS disposition;
IF @undeclared_object_members<>0 THROW 51000,N'VALUE_ID_CONTRACTS_READ_UNDECLARED_MEMBER',1;
IF @dictionary_property_count<>1 OR @dictionary_noninteger_values<>0 THROW 51000,N'VALUE_ID_CONTRACTS_READ_DICTIONARY_SHAPE',1;
IF @projection_member_count<>1 THROW 51000,N'VALUE_ID_CONTRACTS_READ_PROJECTION_SHAPE',1;

-- The uncommitted replay of the same document bytes answers UNCHANGED: the
-- installed-document gate, not a second version. A byte-identical install
-- writes nothing.
DECLARE @replay TABLE (action nvarchar(64), disposition nvarchar(64), capability_id nvarchar(400), document_digest varchar(64), contracts_declared int, scenarios_declared int, meaning_declared int, interface_declared int);
INSERT @replay EXEC model.declare_capability_document @document=@document;
SELECT '8_idempotent_replay' AS result_set, disposition, contracts_declared, scenarios_declared, meaning_declared, interface_declared, document_digest FROM @replay;
IF NOT EXISTS (SELECT 1 FROM @replay WHERE disposition=N'UNCHANGED') THROW 51000,N'VALUE_ID_CONTRACTS_REPLAY_NOT_UNCHANGED',1;

-- The assembled graph source from the uncommitted transaction: the reader is
-- reachable through the estate view and carries the amended contract.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-observation-telemetry-authority',0,N'sidefx:capabilities'));
SELECT '9_graph_source' AS result_set,
 JSON_VALUE(@graph,'$.capabilityId') AS capability_id,
 JSON_VALUE(@graph,'$.rootScenarioId') AS root_scenario_id,
 (SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities') a
  CROSS APPLY OPENJSON(JSON_QUERY(a.value,'$.operations')) o
  WHERE JSON_VALUE(o.value,'$.operationId')=N'read-observation-telemetry-authority.0') AS operations_declared,
 CASE WHEN @graph LIKE N'%valueDictionaries%' AND @graph LIKE N'%valueProjections%' THEN 1 ELSE 0 END AS graph_carries_new_members;

-- The re-declaration is proved above; the final transaction statement selects
-- the dry run (rollback) or the installation (commit).
COMMIT TRANSACTION;
