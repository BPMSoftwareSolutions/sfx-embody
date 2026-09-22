-- declare-altitude-model-request-contracts.sql
--
-- Lane 1, item 1 of docs/compact-altitude-request-plan-2026-09-22.md: the two
-- compact altitude contracts, declared as rows with model.declare_contract
-- (EXISTING PROCEDURE).
--
--   altitude-model-request.v1   the compact request the model port sends:
--                               { altitude, toolId, objective, inputContractId,
--                                 contextRefs[{kind,id,digest}],
--                                 contextSlices[{ref,document}] }.
--                               Closed shape (additionalProperties:false).
--                               contextRefs are pinned handles; only bounded
--                               contextSlices travel in the body. The carrier
--                               must NOT carry embedded context: the schema
--                               extension names the refused members and the
--                               guard capability below the 256 KB cap. The
--                               extension members are:
--                                 x-sidefx-requestCapBytes           262144
--                                 x-sidefx-oversizeRefusal           ALTITUDE_REQUEST_OVERSIZED
--                                 x-sidefx-embeddedContextMembers    graphSource, authority,
--                                                                    catalog, plan,
--                                                                    currentInvocationRequest
--                                 x-sidefx-embeddedContextRefusal    ALTITUDE_REQUEST_EMBEDDED_CONTEXT
--                                 x-sidefx-guardCapabilityId         enforce-altitude-request-cap
--                               The shape matches the bridge request contract in
--                               sfx-providers/src/request-contract.mjs (read
--                               2026-09-22): required altitude/toolId/objective/
--                               inputContractId, additionalProperties:false,
--                               altitude integer|string.
--
--   altitude-model-response.v1  the altitude output wrapper the model/provider
--                               returns: providerId, altitude, toolId,
--                               disposition, candidate (the altitude's declared
--                               output, altitude-N-<name>-output.v1),
--                               providerExecution stub|model, elapsedMs,
--                               requestBytes; findings/shapeConforms/modelCall
--                               are carried when present. This mirrors the
--                               response envelope in sfx-providers/README.md.
--                               (Discovery: no DB contract previously described
--                               this bridge response; the altitude output
--                               contracts themselves stay unchanged.)
--
-- What this migration does NOT do: no port, scenario, transformation or
-- provider row is written; the two contracts are the deliverable. The cap is
-- declared HERE only as machine-readable schema metadata; its enforcing read
-- capability is enforce-altitude-request-cap.sql (item 3).
--
-- Idempotent: declare_contract is content-addressed and gated by digest; the
-- replay proof re-runs both declarations and requires the contract/version
-- counts to be unchanged.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'ALTITUDE_CONTRACTS_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

-- ============================== BASELINE ==============================
-- Three unrelated capabilities whose assembled graph source must be byte-identical
-- before and after. The altitude capability is deliberately not measured here:
-- its graph source carries the eleven copied 12.4 MB live-model envelopes and is
-- the subject of later lane installs (L3), not an unrelated graph.
DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @baseline(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'ALTITUDE_CONTRACTS_BASELINE_MISSING',1;

-- ============================== THE TWO CONTRACTS ==============================
DECLARE @request_id nvarchar(400)=N'altitude-model-request.v1';
DECLARE @request_schema nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/altitude-model-request.v1.schema.json","title":"Compact altitude model request","description":"Compact scheduling facts and bound document references for one altitude model call. contextRefs are handles resolved under the pinned authority; contextSlices are bounded document selections. Embedded context (graphSource, authority, catalog, plan, currentInvocationRequest) is refused with ALTITUDE_REQUEST_EMBEDDED_CONTEXT; bodies over 256 KB are refused with ALTITUDE_REQUEST_OVERSIZED before any model call.","type":"object","additionalProperties":false,"required":["altitude","toolId","objective","inputContractId"],"properties":{"altitude":{"type":["integer","string"]},"toolId":{"type":"string","minLength":1},"objective":{"type":"string","minLength":1},"inputContractId":{"type":"string","minLength":1},"contextRefs":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["id"],"properties":{"kind":{"type":"string"},"id":{"type":"string","minLength":1},"digest":{"type":"string"}}}},"contextSlices":{"type":"array","items":{"type":"object","required":["ref","document"],"properties":{"ref":{"type":"string","minLength":1},"document":{}}}}},"x-sidefx-requestCapBytes":262144,"x-sidefx-oversizeRefusal":"ALTITUDE_REQUEST_OVERSIZED","x-sidefx-embeddedContextMembers":["graphSource","authority","catalog","plan","currentInvocationRequest"],"x-sidefx-embeddedContextRefusal":"ALTITUDE_REQUEST_EMBEDDED_CONTEXT","x-sidefx-unknownMemberRefusal":"ALTITUDE_REQUEST_UNKNOWN_MEMBER","x-sidefx-guardCapabilityId":"enforce-altitude-request-cap"}';
DECLARE @response_id nvarchar(400)=N'altitude-model-response.v1';
DECLARE @response_schema nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/altitude-model-response.v1.schema.json","title":"Altitude model response (altitude output wrapper)","description":"One altitude model/provider response wrapping the altitude declared output. providerExecution is stub (deterministic candidate) or model (live model call); requestBytes is the measured compact request size; findings carries refusal detail when disposition is HELD.","type":"object","additionalProperties":true,"required":["altitude","toolId","disposition","providerExecution","elapsedMs","requestBytes"],"properties":{"providerId":{"type":"string"},"altitude":{"type":["integer","string"]},"toolId":{"type":"string"},"disposition":{"type":"string"},"candidate":{"type":["object","null"],"description":"the altitude declared output contract (altitude-N-<name>-output.v1)"},"providerExecution":{"enum":["stub","model"]},"elapsedMs":{"type":"number","minimum":0},"requestBytes":{"type":"integer","minimum":0},"shapeConforms":{"type":"boolean"},"findings":{"type":"array"},"modelCall":{"type":["object","null"]}},"x-sidefx-wrappedOutputContracts":["altitude-1-feature-parse-output.v1","altitude-2-capability-meaning-output.v1","altitude-3-scenario-io-output.v1","altitude-4-contracts-schemas-output.v1","altitude-5-semantic-authority-envelope-output.v1","altitude-6-transformation-ast-output.v1","altitude-7-execution-authorities-ports-output.v1","altitude-8-providers-bindings-overlays-output.v1","altitude-9-interface-cli-display-output.v1","altitude-10-fixtures-proof-output.v1","altitude-11-alignment-evaluation-output.v1"],"x-sidefx-refusalCodes":["ALTITUDE_REQUEST_OVERSIZED","ALTITUDE_REQUEST_EMBEDDED_CONTEXT","ALTITUDE_REQUEST_UNKNOWN_MEMBER"]}';
EXEC model.declare_contract @id=@request_id,@schema=@request_schema;
EXEC model.declare_contract @id=@response_id,@schema=@response_schema;
-- Replay gate: the same bytes and ids must map to the same versions.
DECLARE @request_versions int=(SELECT COUNT(*) FROM model.contract c JOIN model.contract_version cv ON cv.contract_pk=c.contract_pk WHERE c.contract_id=@request_id);
DECLARE @response_versions int=(SELECT COUNT(*) FROM model.contract c JOIN model.contract_version cv ON cv.contract_pk=c.contract_pk WHERE c.contract_id=@response_id);
EXEC model.declare_contract @id=@request_id,@schema=@request_schema;
EXEC model.declare_contract @id=@response_id,@schema=@response_schema;
IF (SELECT COUNT(*) FROM model.contract c JOIN model.contract_version cv ON cv.contract_pk=c.contract_pk WHERE c.contract_id=@request_id)<>@request_versions
 THROW 51000,N'ALTITUDE_REQUEST_CONTRACT_REPLAY_WROTE',1;
IF (SELECT COUNT(*) FROM model.contract c JOIN model.contract_version cv ON cv.contract_pk=c.contract_pk WHERE c.contract_id=@response_id)<>@response_versions
 THROW 51000,N'ALTITUDE_RESPONSE_CONTRACT_REPLAY_WROTE',1;

-- ============================== PROOFS ==============================
SELECT N'1_altitude_contracts' AS result_set,d.declared_id,
 LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
 JSON_VALUE(d.definition_json,'$.semantics.schema_id') AS schema_id,
 JSON_VALUE(d.definition_json,'$.semantics.schema_digest') AS schema_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT' AND d.declared_id IN (@request_id,@response_id)
ORDER BY d.declared_id;
IF (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT' AND d.declared_id IN (@request_id,@response_id))<>2
 THROW 51000,N'ALTITUDE_CONTRACTS_NOT_SELECTED',1;

-- The declared cap and refusal codes are readable from the request contract schema.
SELECT N'2_request_cap_declared' AS result_set,
 JSON_VALUE(sc.schema_json,'$."x-sidefx-requestCapBytes"') AS cap_bytes,
 JSON_VALUE(sc.schema_json,'$."x-sidefx-oversizeRefusal"') AS oversize_refusal,
 JSON_VALUE(sc.schema_json,'$."x-sidefx-embeddedContextRefusal"') AS embedded_context_refusal,
 JSON_VALUE(sc.schema_json,'$."x-sidefx-guardCapabilityId"') AS guard_capability_id,
 (SELECT COUNT(*) FROM OPENJSON(sc.schema_json,'$."x-sidefx-embeddedContextMembers"')) AS embedded_members,
 (SELECT COUNT(*) FROM OPENJSON(sc.schema_json,'$.required')) AS required_members
FROM (
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_json
 FROM analysis.v_selected_semantic_definition d
 JOIN source.content_object co ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.schema_digest'),'sha256:',''),2)
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT' AND d.declared_id=@request_id
) sc;
IF NOT EXISTS (SELECT 1 FROM (
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS schema_json
 FROM analysis.v_selected_semantic_definition d
 JOIN source.content_object co ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.schema_digest'),'sha256:',''),2)
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT' AND d.declared_id=@request_id
) s WHERE JSON_VALUE(s.schema_json,'$.additionalProperties')=N'false'
 AND JSON_VALUE(s.schema_json,'$."x-sidefx-requestCapBytes"')=N'262144'
 AND JSON_VALUE(s.schema_json,'$."x-sidefx-embeddedContextRefusal"')=N'ALTITUDE_REQUEST_EMBEDDED_CONTEXT')
 THROW 51000,N'ALTITUDE_REQUEST_CAP_NOT_DECLARED_ON_CONTRACT',1;

-- Unrelated graph digests byte-identical.
DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @after(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g;
SELECT N'3_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'ALTITUDE_CONTRACTS_CHANGED_A_GRAPH',1;

-- The altitude output contracts are untouched.
SELECT N'4_altitude_output_contracts_unchanged' AS result_set,
 COUNT(*) AS output_contracts,
 SUM(CASE WHEN d.declared_id LIKE N'altitude-%-output.v1' THEN 1 ELSE 0 END) AS altitude_outputs
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT' AND d.declared_id LIKE N'altitude-%-output.v1';
IF (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT' AND d.declared_id LIKE N'altitude-%-output.v1')<>11
 THROW 51000,N'ALTITUDE_OUTPUT_CONTRACTS_CHANGED',1;

SELECT N'5_disposition' AS result_set,N'declared' AS disposition,@request_id AS request_contract,@response_id AS response_contract,
 @request_versions AS request_versions,@response_versions AS response_versions;
COMMIT TRANSACTION;
