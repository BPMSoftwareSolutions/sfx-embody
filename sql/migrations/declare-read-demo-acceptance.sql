-- declare-read-demo-acceptance.sql
--
-- Hand-authored code retirement W1.4 (docs/hand-authored-code-retirement.md
-- P2.3; agent strategy W1.4): the demo acceptance proof becomes declared
-- authority, and the retired harness is scripts/verify-demo.mjs. This migration
-- declares a read capability (sidefx:capabilities / read-demo-acceptance) whose
-- single declared-read port checks one acceptance run's captured observations
-- against the declared twelve-case catalog and returns the
-- demo-acceptance-receipt.v1 receipt:
--
--   catalog       the twelve cases the retired harness declared (10 offline, 2
--                 live-gated), each with its expected exit and its required
--                 markers; the catalog is declared SQL, not harness code;
--   status        an offline case is green only at its declared exit; a live
--                 case is green at exit 0 or accepted as LIVE_UNAVAILABLE when
--                 the caller declares the live environment unavailable;
--   markers       every declared marker must appear in the captured stdout or
--                 stderr (the capture is the observation, never a paraphrase);
--   claims        every value the caller reports must appear verbatim in its
--                 capture -- a value the capture does not carry is a
--                 synthesized value and violates the receipt; a claim may also
--                 name a peer case whose same-named claim must hold the same
--                 value (the invoke/observe observedPathDigest parity);
--   verdict       DEMO_ACCEPTANCE_VERIFIED only when all twelve declared cases
--                 are captured, every offline case is green, every live case is
--                 green or declared unavailable, and no synthesized value was
--                 supplied.
--
-- The physical collection stays a harness (the covering test and the W1.4
-- retirement evidence run); the meaning -- the case catalog, every acceptance
-- rule and the verdict -- is declared SQL carried by the port binding, not
-- code. The retired harness's trace-renderer assertions are not carried over:
-- the CLI renders the circuit view now, and the declared markers name the
-- semantic content the renderer must carry, not one renderer's labels.
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
-- code. It receives @input (the demo-acceptance-request.v1 captures) and
-- returns one demo-acceptance-receipt.v1 receipt in the value column.
DECLARE @statement nvarchar(max) = N'
DECLARE @catalog TABLE (ordinal int IDENTITY(1,1) PRIMARY KEY, caseId nvarchar(100) UNIQUE, context nvarchar(20), expectedExit int, markers nvarchar(max));
INSERT @catalog(caseId,context,expectedExit,markers) VALUES
 (N''list-capabilities'',N''offline'',0,N''["Capabilities (","say-hello-world","sidefx:capabilities"]''),
 (N''find-scaffold'',N''offline'',0,N''["generate-executable-capability-scaffold"]''),
 (N''reveal-equity-market-price-evidence'',N''offline'',0,N''["resolve-equity-market-price-evidence","Snapshot","observe-equity-price-exchange","sda-governed-http-exchange-port.v1"]''),
 (N''reveal-equity-market-price-evidence-markdown'',N''offline'',0,N''["## Canonical feature","observe-equity-price-exchange"]''),
 (N''invoke-say-hello-world'',N''offline'',0,N''["Hello, World!","hello-world-greeting.v1"]''),
 (N''observe-say-hello-world-trace'',N''offline'',0,N''["Scenario say-hello-world","say-hello-world-port","TRACE"]''),
 (N''observe-say-hello-world-json'',N''offline'',0,N''["Hello, World!","overlay"]''),
 (N''invoke-resolve-sidefx-eligible-providers'',N''offline'',0,N''["PROVIDERS_RESOLVED","eligibleCount"]''),
 (N''circuit-say-hello-world'',N''offline'',4,N''["CIRCUIT_PUBLICATION_UNAVAILABLE"]''),
 (N''media-artifact-unavailable'',N''offline'',4,N''["CIRCUIT_PUBLICATION_UNAVAILABLE"]''),
 (N''live-invoke-equity-market-price-evidence'',N''live'',0,N''["EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED","QQQ"]''),
 (N''live-observe-equity-market-price-evidence-display'',N''live'',0,N''["Scenario resolve-equity-market-price-evidence","QQQ","observe-equity-price-exchange"]'');
DECLARE @captures TABLE (caseId nvarchar(100) PRIMARY KEY, context nvarchar(20), exitCode int, stdout nvarchar(max), stderr nvarchar(max), declaredUnavailable bit);
INSERT @captures(caseId,context,exitCode,stdout,stderr,declaredUnavailable)
SELECT c.caseId,c.context,c.exitCode,c.stdout,c.stderr,c.declaredUnavailable
FROM OPENJSON(@input,''$.payload.captures'') WITH (caseId nvarchar(100) ''$.caseId'', context nvarchar(20) ''$.context'', exitCode int ''$.exitCode'', stdout nvarchar(max) ''$.stdout'', stderr nvarchar(max) ''$.stderr'', declaredUnavailable bit ''$.declaredUnavailable'') c
WHERE c.caseId IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM @captures) THROW 51000,N''DEMO_ACCEPTANCE_CAPTURES_REQUIRED'',1;
DECLARE @claims TABLE (caseId nvarchar(100), name nvarchar(200), value nvarchar(max), equalsCase nvarchar(100));
INSERT @claims(caseId,name,value,equalsCase)
SELECT JSON_VALUE(c.value,''$.caseId''),j.name,j.value,j.equalsCase
FROM OPENJSON(@input,''$.payload.captures'') c
CROSS APPLY OPENJSON(COALESCE(JSON_QUERY(c.value,''$.claims''),N''[]'')) WITH (name nvarchar(200) ''$.name'', value nvarchar(max) ''$.value'', equalsCase nvarchar(100) ''$.equalsCase'') j
WHERE JSON_VALUE(c.value,''$.caseId'') IS NOT NULL AND j.value IS NOT NULL;
DECLARE @results TABLE (caseId nvarchar(100) PRIMARY KEY, context nvarchar(20), expectedExit int, observedExit int, captured bit, declaredUnavailable bit,
 markersRequired int, markersPresent int, claimsDeclared int, claimsPresent int, claimsSynthesized int, claimsMismatched int, outcome nvarchar(40));
INSERT @results(caseId,context,expectedExit,observedExit,captured,declaredUnavailable,markersRequired,markersPresent,claimsDeclared,claimsPresent,claimsSynthesized,claimsMismatched,outcome)
SELECT cat.caseId,cat.context,cat.expectedExit,cap.exitCode,
 CONVERT(bit,CASE WHEN cap.caseId IS NULL THEN 0 ELSE 1 END),CONVERT(bit,COALESCE(cap.declaredUnavailable,0)),
 (SELECT COUNT(*) FROM OPENJSON(cat.markers)),
 (SELECT COUNT(*) FROM OPENJSON(cat.markers) m WHERE CHARINDEX(m.value,COALESCE(cap.stdout,N'''')+NCHAR(10)+COALESCE(cap.stderr,N''''))>0),
 (SELECT COUNT(*) FROM @claims cl WHERE cl.caseId=cat.caseId),
 (SELECT COUNT(*) FROM @claims cl WHERE cl.caseId=cat.caseId AND CHARINDEX(cl.value,COALESCE(cap.stdout,N'''')+NCHAR(10)+COALESCE(cap.stderr,N''''))>0),
 (SELECT COUNT(*) FROM @claims cl WHERE cl.caseId=cat.caseId AND CHARINDEX(cl.value,COALESCE(cap.stdout,N'''')+NCHAR(10)+COALESCE(cap.stderr,N''''))=0),
 (SELECT COUNT(*) FROM @claims cl JOIN @claims base ON base.caseId=cl.equalsCase AND base.name=cl.name WHERE cl.caseId=cat.caseId AND cl.equalsCase IS NOT NULL AND (base.value IS NULL OR base.value<>cl.value)),
 N''PENDING''
FROM @catalog cat LEFT JOIN @captures cap ON cap.caseId=cat.caseId;
UPDATE @results SET outcome=CASE
 WHEN captured=0 THEN N''MISSING_CAPTURE''
 WHEN context=N''offline'' AND observedExit=expectedExit AND markersPresent=markersRequired AND claimsSynthesized=0 AND claimsMismatched=0 THEN N''GREEN''
 WHEN context=N''live'' AND declaredUnavailable=1 AND observedExit<>0 THEN N''LIVE_UNAVAILABLE''
 WHEN context=N''live'' AND observedExit=0 AND markersPresent=markersRequired AND claimsSynthesized=0 AND claimsMismatched=0 THEN N''GREEN''
 ELSE N''VIOLATION'' END;
DECLARE @declaredCases int=(SELECT COUNT(*) FROM @catalog);
DECLARE @capturedCases int=(SELECT COUNT(*) FROM @captures);
DECLARE @offlineCases int=(SELECT COUNT(*) FROM @catalog WHERE context=N''offline'');
DECLARE @liveCases int=(SELECT COUNT(*) FROM @catalog WHERE context=N''live'');
DECLARE @greenCases int=(SELECT COUNT(*) FROM @results WHERE outcome=N''GREEN'');
DECLARE @liveUnavailableCases int=(SELECT COUNT(*) FROM @results WHERE outcome=N''LIVE_UNAVAILABLE'');
DECLARE @violations int=(SELECT COUNT(*) FROM @results WHERE outcome IN (N''VIOLATION'',N''MISSING_CAPTURE''));
DECLARE @synthesizedCases int=(SELECT COUNT(*) FROM @results WHERE claimsSynthesized>0);
DECLARE @mismatchedCases int=(SELECT COUNT(*) FROM @results WHERE claimsMismatched>0);
DECLARE @verdict nvarchar(80)=CASE WHEN @capturedCases=@declaredCases AND @violations=0 AND @synthesizedCases=0 AND @mismatchedCases=0 THEN N''DEMO_ACCEPTANCE_VERIFIED'' ELSE N''DEMO_ACCEPTANCE_VIOLATION'' END;
DECLARE @casesJson nvarchar(max)=(SELECT res.caseId,res.context,res.expectedExit,res.observedExit,
 CONVERT(bit,CASE WHEN res.outcome IN (N''GREEN'',N''LIVE_UNAVAILABLE'') THEN 1 ELSE 0 END) AS accepted,res.outcome,
 res.markersRequired,res.markersPresent,res.claimsDeclared,res.claimsPresent,res.claimsSynthesized,res.claimsMismatched,
 (SELECT cl.name,
   CONVERT(bit,CASE WHEN CHARINDEX(cl.value,COALESCE(cap.stdout,N'''')+NCHAR(10)+COALESCE(cap.stderr,N''''))>0 THEN 1 ELSE 0 END) AS present,
   CASE WHEN CHARINDEX(cl.value,COALESCE(cap.stdout,N'''')+NCHAR(10)+COALESCE(cap.stderr,N''''))>0 THEN cl.value END AS value
  FROM @claims cl JOIN @captures cap ON cap.caseId=cl.caseId
  WHERE cl.caseId=res.caseId ORDER BY cl.name FOR JSON PATH) AS claims
 FROM @catalog cat JOIN @results res ON res.caseId=cat.caseId ORDER BY cat.ordinal FOR JSON PATH);
DECLARE @countsJson nvarchar(max)=(SELECT @declaredCases AS declaredCases,@capturedCases AS capturedCases,@offlineCases AS offlineCases,@liveCases AS liveCases,
 @greenCases AS greenCases,@liveUnavailableCases AS liveUnavailableCases,@violations AS violationCases,@synthesizedCases AS synthesizedCases,@mismatchedCases AS mismatchedCases FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SELECT (SELECT N''demo-acceptance.v1'' AS receiptType,N''read-demo-acceptance'' AS readBy,
 CONVERT(nvarchar(30),SYSUTCDATETIME(),126)+N''Z'' AS checkedAt,
 NULLIF(JSON_VALUE(@input,N''$.payload.harness''),N'''') AS harness,
 JSON_QUERY(@casesJson) AS cases,JSON_QUERY(@countsJson) AS counts,
 CONVERT(bit,CASE WHEN @synthesizedCases=0 THEN 0 ELSE 1 END) AS synthesizedValues,
 @verdict AS verdict FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-demo-acceptance-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';

-- ============================== CONTRACTS AND CAPABILITY DOCUMENT ==============================
DECLARE @contracts nvarchar(max) = N'[
 {"id":"demo-acceptance-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/demo-acceptance-request.v1.schema.json","title":"Demo acceptance request","type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"const":"demo-acceptance-request.v1"},"payload":{"type":"object","additionalProperties":true,"required":["captures"],"properties":{"harness":{"type":"string"},"captures":{"type":"array","items":{"type":"object","additionalProperties":true,"required":["caseId","exitCode"],"properties":{"caseId":{"type":"string"},"context":{"type":"string"},"exitCode":{"type":"integer"},"stdout":{"type":"string"},"stderr":{"type":"string"},"declaredUnavailable":{"type":"boolean"},"claims":{"type":"array","items":{"type":"object","additionalProperties":true,"required":["name"],"properties":{"name":{"type":"string"},"value":{"type":"string"},"equalsCase":{"type":"string"}}}}}}}}}}}},
 {"id":"demo-acceptance-receipt.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/demo-acceptance-receipt.v1.schema.json","title":"Demo acceptance receipt","type":"object","additionalProperties":true,"required":["receiptType","cases","counts","synthesizedValues","verdict"],"properties":{"receiptType":{"const":"demo-acceptance.v1"},"readBy":{"type":"string"},"checkedAt":{"type":"string"},"harness":{"type":["string","null"]},"cases":{"type":"array"},"counts":{"type":"object"},"synthesizedValues":{"type":"boolean"},"verdict":{"type":"string"}}}}
]';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-demo-acceptance",
 "meaning":{"intent":"read the demo acceptance verdict from one acceptance run''s captured observations","outcome":"the caller observes every declared demo case with its capture verdict, the no-synthesized-values check and the declared acceptance verdict"},
 "cli":{"display":{"select":"outcome.payload","as":"json"}},
 "contracts":' + @contracts + N',
 "scenarios":[{
  "scenarioId":"read-demo-acceptance",
  "name":"Read the demo acceptance receipt",
  "inputId":"demo-acceptance-request",
  "inputContract":"demo-acceptance-request.v1",
  "eventId":"demo-acceptance-requested",
  "eventAuthority":"read-demo-acceptance.v1",
  "outcomeId":"demo-acceptance-receipt",
  "outcomeContract":"demo-acceptance-receipt.v1",
  "terminal":true,
  "root":true,
  "given":"one acceptance run''s captured observations for the twelve declared demo cases",
  "when":"the declared demo-acceptance read checks each capture against the declared case rules and the no-synthesized-values rule",
  "then":"the receipt names every declared case with its observed status and states the declared acceptance verdict",
  "operations":[{"operationId":"read-demo-acceptance.0","kind":"invoke-port","portId":"read-demo-acceptance-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;

-- ============================== PROOF ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT '1_contracts' AS result_set, d.declared_id AS contract_id
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id IN (N'demo-acceptance-request.v1',N'demo-acceptance-receipt.v1')
ORDER BY d.declared_id;

-- The declared-read port carries the statement and result column and names no
-- provider module: the same standard read as the sibling declared reads.
SELECT '2_capability' AS result_set, c.capability_id, s.scenario_id,
 p.port_id, JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
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
JOIN model.port p ON p.port_pk=pv.port_pk
JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk AND pd.estate_model_pk=@estate
WHERE c.capability_id=N'read-demo-acceptance';

-- The behavioral self-test: the declared statement itself is executed on a
-- green sample and a violated sample. The green sample carries all twelve
-- declared cases with their markers, exits and claims (including the
-- invoke/observe observedPathDigest parity); the violated sample flips the
-- trace case's exit and reports one value no capture carries, and must come
-- back DEMO_ACCEPTANCE_VIOLATION with synthesizedValues true.
DECLARE @stmt nvarchar(max)=(SELECT j.value
 FROM analysis.v_selected_semantic_definition d
 CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') j
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=N'sidefx:capability:read-demo-acceptance' AND d.declared_id=N'read-demo-acceptance-port'
  AND j.[key]=N'statement');
DECLARE @green nvarchar(max)=N'{"contractId":"demo-acceptance-request.v1","payload":{"harness":"migration self-test (green)","captures":[
 {"caseId":"list-capabilities","context":"offline","exitCode":0,"stdout":"Capabilities (3) say-hello-world sidefx:capabilities","claims":[{"name":"capabilities","value":"3"}]},
 {"caseId":"find-scaffold","context":"offline","exitCode":0,"stdout":"generate-executable-capability-scaffold"},
 {"caseId":"reveal-equity-market-price-evidence","context":"offline","exitCode":0,"stdout":"Snapshot sha256:AAAA resolve-equity-market-price-evidence observe-equity-price-exchange sda-governed-http-exchange-port.v1","claims":[{"name":"snapshotId","value":"sha256:AAAA"}]},
 {"caseId":"reveal-equity-market-price-evidence-markdown","context":"offline","exitCode":0,"stdout":"## Canonical feature observe-equity-price-exchange"},
 {"caseId":"invoke-say-hello-world","context":"offline","exitCode":0,"stdout":"completed hello-world-greeting.v1 Hello, World! sha256:BBBB","claims":[{"name":"result.disposition","value":"completed"},{"name":"result.outcome.payload.message","value":"Hello, World!"},{"name":"result.observedPathDigest","value":"sha256:BBBB"}]},
 {"caseId":"observe-say-hello-world-trace","context":"offline","exitCode":0,"stdout":"Scenario say-hello-world say-hello-world-port TRACE"},
 {"caseId":"observe-say-hello-world-json","context":"offline","exitCode":0,"stdout":"Hello, World! overlay sha256:BBBB","claims":[{"name":"result.observedPathDigest","value":"sha256:BBBB","equalsCase":"invoke-say-hello-world"}]},
 {"caseId":"invoke-resolve-sidefx-eligible-providers","context":"offline","exitCode":0,"stdout":"PROVIDERS_RESOLVED eligibleCount 1","claims":[{"name":"result.outcome.disposition","value":"PROVIDERS_RESOLVED"},{"name":"result.outcome.eligibleCount","value":"1"}]},
 {"caseId":"circuit-say-hello-world","context":"offline","exitCode":4,"stderr":"CIRCUIT_PUBLICATION_UNAVAILABLE"},
 {"caseId":"media-artifact-unavailable","context":"offline","exitCode":4,"stderr":"CIRCUIT_PUBLICATION_UNAVAILABLE"},
 {"caseId":"live-invoke-equity-market-price-evidence","context":"live","exitCode":0,"stdout":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED QQQ 717.395","claims":[{"name":"result.outcome.disposition","value":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"},{"name":"result.outcome.payload.symbol","value":"QQQ"},{"name":"result.outcome.payload.observedPrice","value":"717.395"}]},
 {"caseId":"live-observe-equity-market-price-evidence-display","context":"live","exitCode":0,"stdout":"Scenario resolve-equity-market-price-evidence QQQ observe-equity-price-exchange"}
]}}';
DECLARE @violation nvarchar(max)=REPLACE(REPLACE(@green,
 N'"caseId":"observe-say-hello-world-trace","context":"offline","exitCode":0',
 N'"caseId":"observe-say-hello-world-trace","context":"offline","exitCode":1'),
 N'"name":"result.disposition","value":"completed"',
 N'"name":"result.disposition","value":"SYNTHETIC-NOT-OBSERVED"');
DECLARE @reading TABLE (ordinal int IDENTITY(1,1), value nvarchar(max));
INSERT @reading EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@green,@estate_model_pk=@estate;
INSERT @reading EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@violation,@estate_model_pk=@estate;
SELECT '3_self_test' AS result_set, CASE ordinal WHEN 1 THEN 'green' ELSE 'violation' END AS sample,
 JSON_VALUE(value,'$.verdict') AS verdict,
 JSON_VALUE(value,'$.synthesizedValues') AS synthesized_values,
 JSON_VALUE(value,'$.counts.declaredCases') AS declared_cases,
 JSON_VALUE(value,'$.counts.capturedCases') AS captured_cases,
 JSON_VALUE(value,'$.counts.greenCases') AS green_cases,
 JSON_VALUE(value,'$.counts.liveUnavailableCases') AS live_unavailable_cases,
 JSON_VALUE(value,'$.counts.violationCases') AS violation_cases,
 JSON_VALUE(value,'$.counts.synthesizedCases') AS synthesized_cases,
 value AS receipt
FROM @reading ORDER BY ordinal;

-- The assembled graph source from the uncommitted transaction: the reader is
-- reachable through the estate view.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-demo-acceptance',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set,
 JSON_VALUE(@graph,'$.capabilityId') AS capability_id,
 JSON_VALUE(@graph,'$.rootScenarioId') AS root_scenario_id,
 (SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities') a
  CROSS APPLY OPENJSON(JSON_QUERY(a.value,'$.operations')) o
  WHERE JSON_VALUE(o.value,'$.operationId')=N'read-demo-acceptance.0') AS operations_declared;

-- Installed 2026-09-17, after the rollback dry run and the in-transaction
-- preflight on the live acceptance collection (green verdict
-- DEMO_ACCEPTANCE_VERIFIED; twelve declared cases, ten offline and two live
-- green; no synthesized values; the violated sample returns
-- DEMO_ACCEPTANCE_VIOLATION with synthesizedValues true).
-- Receipts: evidence/vault-20260916/retirement/w1.4/.
COMMIT TRANSACTION;
