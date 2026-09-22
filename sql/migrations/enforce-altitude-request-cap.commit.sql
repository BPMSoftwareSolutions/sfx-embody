-- enforce-altitude-request-cap.sql
--
-- Lane 1, item 3 of docs/compact-altitude-request-plan-2026-09-22.md: the
-- declared request-size/cap guard. `enforce-altitude-request-cap` is a declared
-- read capability (the estate's admission-read pattern, precedent
-- declare-agent-relevance-guard.sql / declare-read-declared-capability-document.sql)
-- whose single sda-embodiment-plan-port.v1 read measures the composed request
-- and refuses, fail-fast, with the named codes:
--
--   ALTITUDE_REQUEST_OVERSIZED          request UTF-8 JSON text > 262144 bytes
--                                       (256 KB), measured before any model call
--   ALTITUDE_REQUEST_EMBEDDED_CONTEXT   graphSource, authority, catalog, plan or
--                                       currentInvocationRequest present on the
--                                       request
--
-- (Discovery correction. The plan names "the port's admission read" as the
-- enforcement point. The installed port mechanics expose no admission-read
-- member on a port configuration: sda-projected-capability-invocation-port.v2
-- reads only bindingDigest/capabilityAuthorityDigest/requestPath/lineageMode/
-- resultMode/resultPath/declaredApplication, and generic-llm-connector-port.v1
-- reads only connectorAuthorityRef/requestPath/lineageMode/credentialsMode.
-- The guard is therefore a declared READ CAPABILITY: the L3 executor adds it as
-- an operation before each live model operation, and the request contract
-- (declare-altitude-model-request-contracts.sql) records the guard id, the cap
-- and the refusal codes as schema extensions.)
--
-- The read resolves the request from the operation input directly, or from a
-- declared carrier member `request` / `altitudeRequest` / `compactAltitudeRequest`,
-- so it can guard either the composed request or the state that carries it.
-- The size is measured as UTF-8 JSON bytes with the estate's canonical
-- BIN2_UTF8 recipe; the embedded members are read as the request's own keys.
-- On admission the read returns the altitude-request-admission.v1 receipt with
-- the observed byte count.
--
-- Depends on item 1: the scenario input contract is altitude-model-request.v1
-- (gate code ALTITUDE_REQUEST_CONTRACT_NOT_DECLARED). Install order: contracts,
-- adapter, cap. The in-transaction probes below execute the read statement
-- directly against the uncommitted rows; the from-transaction preflight above
-- it exercises the same refusals through the kernel.
--
-- Idempotent: the document digest gate returns UNCHANGED on replay; the probes
-- write nothing.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'ALTITUDE_CAP_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @request_contract nvarchar(400)=N'altitude-model-request.v1';
DECLARE @guard_capability nvarchar(400)=N'enforce-altitude-request-cap';

-- ============================== BASELINE ==============================
DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64));
INSERT @baseline(capability_id,digest)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'ALTITUDE_CAP_BASELINE_MISSING',1;

-- ============================== DEPENDENCY GATE ==============================
IF NOT EXISTS (SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT' AND d.declared_id=@request_contract COLLATE Latin1_General_100_BIN2)
 THROW 51000,N'ALTITUDE_REQUEST_CONTRACT_NOT_DECLARED',1;
-- The cap and the guard id in the request contract and this file agree.
DECLARE @declared_cap bigint=(SELECT TRY_CONVERT(bigint,JSON_VALUE(sc.schema_json,'$."x-sidefx-requestCapBytes"'))
 FROM (
  SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_json
  FROM analysis.v_selected_semantic_definition d
  JOIN source.content_object co ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.schema_digest'),'sha256:',''),2)
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT' AND d.declared_id=@request_contract COLLATE Latin1_General_100_BIN2
 ) sc);
IF @declared_cap IS NULL OR @declared_cap<>262144 THROW 51000,N'ALTITUDE_CAP_CONTRACT_CONSTANT_MISSING',1;

-- ============================== THE GUARD READ ==============================
DECLARE @statement nvarchar(max)=N'
DECLARE @request nvarchar(max)=@input;
IF @request IS NULL OR JSON_VALUE(@request,''$.altitude'') IS NULL
BEGIN
 DECLARE @candidate nvarchar(max)=COALESCE(JSON_QUERY(@input,''$.request''),JSON_QUERY(@input,''$.altitudeRequest''),JSON_QUERY(@input,''$.compactAltitudeRequest''));
 IF @candidate IS NOT NULL SET @request=@candidate;
END
IF @request IS NULL OR ISJSON(@request)<>1 OR LEFT(LTRIM(@request),1)<>N''{'' THROW 51000,N''ALTITUDE_REQUEST_SHAPE_INVALID'',1;
DECLARE @bytes bigint=DATALENGTH(CONVERT(varbinary(max),CONVERT(varchar(max),@request COLLATE Latin1_General_100_BIN2_UTF8)));
IF @bytes>262144 THROW 51000,N''ALTITUDE_REQUEST_OVERSIZED'',1;
DECLARE @embedded nvarchar(100)=NULL;
SELECT TOP 1 @embedded=j.[key]
FROM OPENJSON(@request) j
WHERE j.[key] IN (N''graphSource'',N''authority'',N''catalog'',N''plan'',N''currentInvocationRequest'')
ORDER BY CASE j.[key] WHEN N''graphSource'' THEN 0 WHEN N''authority'' THEN 1 WHEN N''catalog'' THEN 2 WHEN N''plan'' THEN 3 ELSE 4 END;
IF @embedded IS NOT NULL THROW 51000,N''ALTITUDE_REQUEST_EMBEDDED_CONTEXT'',1;
SELECT (SELECT N''altitude-request-admission.v1'' AS contractId,N''ADMITTED'' AS disposition,
 JSON_VALUE(@request,''$.altitude'') AS altitude,JSON_VALUE(@request,''$.toolId'') AS toolId,
 @bytes AS requestBytes,262144 AS capBytes,N''enforce-altitude-request-cap'' AS guard,
 CONVERT(nvarchar(30),SYSUTCDATETIME(),126)+N''Z'' AS checkedAt
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';

-- ============================== THE DECLARED CONTRACT ==============================
EXEC model.declare_contract @id=N'altitude-request-admission.v1',
 @schema=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/altitude-request-admission.v1.schema.json","title":"Altitude request admission receipt","type":"object","additionalProperties":true,"required":["contractId","disposition","requestBytes","capBytes"],"properties":{"contractId":{"const":"altitude-request-admission.v1"},"disposition":{"enum":["ADMITTED"]},"altitude":{},"toolId":{"type":"string"},"requestBytes":{"type":"integer","minimum":0},"capBytes":{"const":262144},"guard":{"type":"string"},"checkedAt":{"type":"string"}}}';

-- ============================== THE GUARD CAPABILITY ==============================
DECLARE @probe_document nvarchar(max)=N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"enforce-altitude-request-cap",
 "meaning":{"intent":"refuse an oversized or context-embedded altitude model request before any model call","outcome":"the request is admitted with its measured size, or refused with ALTITUDE_REQUEST_OVERSIZED / ALTITUDE_REQUEST_EMBEDDED_CONTEXT"},
 "cli":{"display":{"select":"outcome.payload","as":"json"}},
 "contracts":[
  {"id":"altitude-request-admission.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/altitude-request-admission.v1.schema.json","type":"object","additionalProperties":true}}
 ],
 "scenarios":[{
  "scenarioId":"enforce-altitude-request-cap",
  "name":"Enforce the compact altitude request cap",
  "inputId":"enforce-altitude-request-cap-request",
  "inputContract":"altitude-model-request.v1",
  "eventId":"enforce-altitude-request-cap-requested",
  "eventAuthority":"enforce-altitude-request-cap.v1",
  "outcomeId":"altitude-request-admission",
  "outcomeContract":"altitude-request-admission.v1",
  "given":"one composed altitude model request",
  "when":"the declared admission read measures it and inspects its members",
  "then":"the request is admitted with its byte count, or refused with the named code",
  "terminal":true,
  "root":true,
  "operations":[{"operationId":"enforce-altitude-request-cap.0","kind":"invoke-port","portId":"enforce-altitude-request-cap-port"}],
  "portBindings":[{"portId":"enforce-altitude-request-cap-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"__STATEMENT__","resultColumn":"value"}}]
 }]
}';
SET @probe_document=REPLACE(@probe_document,N'__STATEMENT__',STRING_ESCAPE(@statement,N'json'));
EXEC model.declare_capability_document @document=@probe_document;
-- Replay: the same document digest writes nothing.
EXEC model.declare_capability_document @document=@probe_document;

-- ============================== PROBES (the statement, against uncommitted rows) ==============================
-- The refusal probes expect a catchable code; XACT_ABORT off keeps the
-- transaction usable after a caught THROW so both refusals can be exercised,
-- then the file rolls back.
SET XACT_ABORT OFF;
DECLARE @small nvarchar(max)=N'{"altitude":4,"toolId":"contract.author","objective":"small request","inputContractId":"contract-change.v1","contextRefs":[],"contextSlices":[]}';
DECLARE @embedded_input nvarchar(max)=N'{"altitude":4,"toolId":"contract.author","objective":"small request","inputContractId":"contract-change.v1","authority":{"compiled":"estate"}}';
DECLARE @oversized_input nvarchar(max)=N'{"altitude":4,"toolId":"contract.author","objective":"'+REPLICATE(CONVERT(nvarchar(max),N'x'),300000)+N'","inputContractId":"contract-change.v1"}';
DECLARE @reading TABLE(value nvarchar(max));
DECLARE @oversized_reading TABLE(value nvarchar(max));
DECLARE @embedded_reading TABLE(value nvarchar(max));
INSERT @reading EXEC sp_executesql @statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@small,@estate_model_pk=@estate;
DECLARE @admitted_disposition nvarchar(40)=(SELECT TOP 1 JSON_VALUE(value,'$.disposition') FROM @reading);
DECLARE @admitted_bytes bigint=(SELECT TOP 1 TRY_CONVERT(bigint,JSON_VALUE(value,'$.requestBytes')) FROM @reading);
IF @admitted_disposition<>N'ADMITTED' OR @admitted_bytes IS NULL OR @admitted_bytes>262144 THROW 51000,N'ALTITUDE_CAP_ADMITTED_PROBE_FAILED',1;
DECLARE @oversized_code nvarchar(400),@embedded_code nvarchar(400);
BEGIN TRY
 INSERT @oversized_reading EXEC sp_executesql @statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@oversized_input,@estate_model_pk=@estate;
END TRY
BEGIN CATCH SET @oversized_code=ERROR_MESSAGE(); END CATCH
BEGIN TRY
 INSERT @embedded_reading EXEC sp_executesql @statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@embedded_input,@estate_model_pk=@estate;
END TRY
BEGIN CATCH SET @embedded_code=ERROR_MESSAGE(); END CATCH
DECLARE @oversized_failure nvarchar(2048)=N'ALTITUDE_CAP_OVERSIZE_PROBE_FAILED:'+ISNULL(@oversized_code,N'(none)');
DECLARE @embedded_failure nvarchar(2048)=N'ALTITUDE_CAP_EMBEDDED_PROBE_FAILED:'+ISNULL(@embedded_code,N'(none)');
IF @oversized_code IS NULL OR @oversized_code NOT LIKE N'%ALTITUDE_REQUEST_OVERSIZED%'
 THROW 51000,@oversized_failure,1;
IF @embedded_code IS NULL OR @embedded_code NOT LIKE N'%ALTITUDE_REQUEST_EMBEDDED_CONTEXT%'
 THROW 51000,@embedded_failure,1;
SELECT N'0_probe_observed' AS result_set,ISNULL(@oversized_code,N'(none)') AS oversized_code,ISNULL(@embedded_code,N'(none)') AS embedded_code;

-- ============================== PROOFS ==============================
SELECT N'1_guard_admission_probe' AS result_set,@admitted_disposition AS disposition,@admitted_bytes AS request_bytes,262144 AS cap_bytes;
SELECT N'2_guard_refusals' AS result_set,N'oversized' AS probe,@oversized_code AS error_code,N'PASSED' AS probe_result
UNION ALL SELECT N'2_guard_refusals',N'embedded-context',@embedded_code,N'PASSED';
SELECT N'3_guard_capability' AS result_set,c.capability_id,s.scenario_id,
 JSON_VALUE(pd.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
 CASE WHEN pd.definition_json LIKE N'%ALTITUDE_REQUEST_OVERSIZED%' AND pd.definition_json LIKE N'%ALTITUDE_REQUEST_EMBEDDED_CONTEXT%' THEN N'CODES_DECLARED' ELSE N'DIVERGED' END AS refusal_codes
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
WHERE c.capability_id=@guard_capability;

DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64));
INSERT @after(capability_id,digest)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2))
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g;
SELECT N'4_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'ALTITUDE_CAP_CHANGED_UNRELATED_CAPABILITY',1;

SELECT N'5_disposition' AS result_set,N'declared' AS disposition,@guard_capability AS guard_capability,
 @declared_cap AS declared_cap_bytes,@admitted_bytes AS admitted_probe_bytes;
COMMIT TRANSACTION;
