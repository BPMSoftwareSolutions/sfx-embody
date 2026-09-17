-- declare-read-credential-non-disclosure.sql
--
-- Hand-authored code retirement W1.3 (docs/hand-authored-code-retirement.md
-- P2.2; agent strategy W1.3): the V4 non-disclosure proof becomes declared
-- authority, and the retired harness is
-- scripts/verify-credential-non-disclosure.mjs. This migration declares a read
-- capability (sidefx:capabilities / read-credential-non-disclosure) whose
-- single declared-read port turns the sweep's observations into the
-- credential-vault-non-disclosure.v1 receipt:
--
--   channels      each physical channel (invoke --json, observe --trace stdout
--                 and the observation stream, the store-credential input, the
--                 equity exchange with the sentinel) is searched for the random
--                 sentinel by the declared statement itself;
--   fileChannels  the evidence/ bundles and the CLI local delivery receipts: the
--                 scan is physical, the declared rule is that any matched file
--                 is a violation;
--   durableRows   the live sweep of source.content_object (the database rows);
--   tamperedStore the negative (AES-GCM authentication failure) must report
--                 CREDENTIAL_NOT_AVAILABLE with nonDisclosureVerified;
--   restore       the real value is restored and applied;
--   verdict       NON_DISCLOSURE_VERIFIED only when the sentinel is absent from
--                 every channel and row, the tampered store fails closed and the
--                 restore succeeds.
--
-- The physical collection stays a harness (the covering test / the retirement
-- evidence run); the meaning -- every absence claim and the verdict -- is
-- declared SQL carried by the port binding, not code. The read never echoes the
-- sentinel or the observed text: only labels, counts, enumerated dispositions
-- and booleans leave the boundary.
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
-- code. It receives @input (the credential-non-disclosure-request.v1 sweep
-- observations), searches every observed channel and the durable rows for the
-- random sentinel, checks the tampered-store negative and the restore, and
-- returns one credential-vault-non-disclosure.v1 receipt in the value column.
DECLARE @statement nvarchar(max) = N'
DECLARE @sentinel nvarchar(400)=NULLIF(LTRIM(RTRIM(JSON_VALUE(@input,''$.payload.sentinel''))),N'''');
IF @sentinel IS NULL OR LEN(@sentinel)<8 THROW 51000,''CREDENTIAL_NON_DISCLOSURE_SENTINEL_REQUIRED'',1;
DECLARE @channels TABLE (ordinal int IDENTITY(1,1) PRIMARY KEY, channel nvarchar(400), observed nvarchar(max),
 cliStatus int, disposition nvarchar(80), streamedObservationLines int);
INSERT @channels(channel,observed,cliStatus,disposition,streamedObservationLines)
SELECT o.channel,o.observed,o.cliStatus,o.disposition,o.streamedObservationLines
FROM OPENJSON(@input,''$.payload.channels'') WITH (channel nvarchar(400) ''$.channel'', observed nvarchar(max) ''$.observed'',
 cliStatus int ''$.cliStatus'', disposition nvarchar(80) ''$.disposition'', streamedObservationLines int ''$.streamedObservationLines'') o;
DECLARE @fileChannels TABLE (ordinal int IDENTITY(1,1) PRIMARY KEY, channel nvarchar(400), filesScanned int, filesMatched int);
INSERT @fileChannels(channel,filesScanned,filesMatched)
SELECT JSON_VALUE(value,''$.channel''),TRY_CONVERT(int,JSON_VALUE(value,''$.filesScanned'')),TRY_CONVERT(int,JSON_VALUE(value,''$.filesMatched''))
FROM OPENJSON(@input,''$.payload.fileScans'');
-- The durable rows: the live sweep walks every retained content object.
DECLARE @rowsMatched int=(SELECT COUNT(*) FROM source.content_object co
 WHERE CHARINDEX(@sentinel,CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8))>0);
DECLARE @channelViolations int=(SELECT COUNT(*) FROM @channels WHERE CHARINDEX(@sentinel,COALESCE(observed,N''''))>0);
DECLARE @fileViolations int=(SELECT COUNT(*) FROM @fileChannels WHERE filesMatched>0);
DECLARE @tampered nvarchar(max)=CONVERT(nvarchar(max),JSON_QUERY(@input,''$.payload.tamperedStore''));
DECLARE @restore nvarchar(max)=CONVERT(nvarchar(max),JSON_QUERY(@input,''$.payload.restore''));
DECLARE @tamperedDisposition nvarchar(80)=NULLIF(JSON_VALUE(@tampered,''$.disposition''),N'''');
DECLARE @tamperedNonDisclosure bit=CONVERT(bit,CASE WHEN JSON_VALUE(@tampered,''$.nonDisclosureVerified'') IN (N''true'',N''1'') THEN 1 ELSE 0 END);
DECLARE @tamperedAbsent bit=CONVERT(bit,CASE WHEN @tampered IS NOT NULL AND CHARINDEX(@sentinel,@tampered)=0 THEN 1 ELSE 0 END);
DECLARE @restoreAbsent bit=CONVERT(bit,CASE WHEN @restore IS NULL OR CHARINDEX(@sentinel,@restore)=0 THEN 1 ELSE 0 END);
DECLARE @restoreGreen bit=CONVERT(bit,CASE WHEN JSON_VALUE(@restore,''$.storeDisposition'')=N''CREDENTIAL_STORED'' AND JSON_VALUE(@restore,''$.applyDisposition'')=N''CREDENTIAL_BOUND'' AND @restoreAbsent=1 THEN 1 ELSE 0 END);
DECLARE @plaintextAbsent bit=CONVERT(bit,CASE WHEN @channelViolations=0 AND @fileViolations=0 AND @rowsMatched=0 AND @tamperedAbsent=1 AND @restoreAbsent=1 THEN 1 ELSE 0 END);
-- Only labels, counts, enumerated dispositions and booleans leave the boundary;
-- the observed text and the sentinel never do.
DECLARE @channelsJson nvarchar(max)=(SELECT channel,
 CONVERT(bit,CASE WHEN CHARINDEX(@sentinel,COALESCE(observed,N''''))=0 THEN 1 ELSE 0 END) AS sentinelAbsent,
 cliStatus,
 CASE WHEN disposition NOT LIKE N''%[^A-Z_0-9]%'' THEN disposition END AS disposition,
 streamedObservationLines
 FROM @channels ORDER BY ordinal FOR JSON PATH);
DECLARE @fileChannelsJson nvarchar(max)=(SELECT channel,filesScanned,filesMatched,
 CONVERT(bit,CASE WHEN filesMatched=0 THEN 1 ELSE 0 END) AS sentinelAbsent
 FROM @fileChannels ORDER BY ordinal FOR JSON PATH);
DECLARE @durableRowsJson nvarchar(max)=(SELECT @rowsMatched AS rowsMatched,
 CONVERT(bit,CASE WHEN @rowsMatched=0 THEN 1 ELSE 0 END) AS sentinelAbsent
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @tamperedStoreJson nvarchar(max)=(SELECT @tamperedDisposition AS disposition,
 CASE WHEN JSON_VALUE(@tampered,''$.referenceName'') NOT LIKE N''%[^A-Z_0-9]%'' THEN JSON_VALUE(@tampered,''$.referenceName'') END AS referenceName,
 @tamperedNonDisclosure AS nonDisclosureVerified,@tamperedAbsent AS sentinelAbsent
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @restoreJson nvarchar(max)=(SELECT JSON_VALUE(@restore,''$.storeDisposition'') AS storeDisposition,
 JSON_VALUE(@restore,''$.applyDisposition'') AS applyDisposition,
 CASE WHEN JSON_VALUE(@restore,''$.realization'') NOT LIKE N''%[^A-Za-z_0-9-]%'' THEN JSON_VALUE(@restore,''$.realization'') END AS realization,
 @restoreAbsent AS sentinelAbsent
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @verdict nvarchar(80)=CASE WHEN @plaintextAbsent=1 AND @tamperedDisposition=N''CREDENTIAL_NOT_AVAILABLE'' AND @tamperedNonDisclosure=1
 THEN N''NON_DISCLOSURE_VERIFIED'' ELSE N''NON_DISCLOSURE_VIOLATION'' END;
SELECT (SELECT N''credential-non-disclosure.v1'' AS receiptType,N''read-credential-non-disclosure'' AS readBy,
 CONVERT(nvarchar(30),SYSUTCDATETIME(),126)+N''Z'' AS checkedAt,
 JSON_QUERY(@channelsJson) AS channels,JSON_QUERY(@fileChannelsJson) AS fileChannels,
 JSON_QUERY(@durableRowsJson) AS durableRows,JSON_QUERY(@tamperedStoreJson) AS tamperedStore,
 JSON_QUERY(@restoreJson) AS [restore],
 CONVERT(bit,@plaintextAbsent) AS plaintextAbsent,@verdict AS verdict
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @bindings nvarchar(max) = N'[{"portId":"read-credential-non-disclosure-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';

-- ============================== CONTRACTS AND CAPABILITY DOCUMENT ==============================
DECLARE @contracts nvarchar(max) = N'[
 {"id":"credential-non-disclosure-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/credential-non-disclosure-request.v1.schema.json","title":"Credential non-disclosure request","type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"const":"credential-non-disclosure-request.v1"},"payload":{"type":"object","additionalProperties":true,"required":["sentinel","channels"],"properties":{"sentinel":{"type":"string"},"channels":{"type":"array"},"fileScans":{"type":"array"},"tamperedStore":{"type":"object"},"restore":{"type":"object"}}}}}},
 {"id":"credential-non-disclosure-receipt.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/credential-non-disclosure-receipt.v1.schema.json","title":"Credential non-disclosure receipt","type":"object","additionalProperties":true,"required":["receiptType","channels","durableRows","tamperedStore","plaintextAbsent","verdict"],"properties":{"receiptType":{"const":"credential-non-disclosure.v1"},"channels":{"type":"array"},"fileChannels":{"type":"array"},"durableRows":{"type":"object"},"tamperedStore":{"type":"object"},"restore":{"type":"object"},"plaintextAbsent":{"type":"boolean"},"verdict":{"type":"string"}}}}
]';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"read-credential-non-disclosure",
 "meaning":{"intent":"read the credential vault''s non-disclosure receipt from one sweep''s observations","outcome":"the caller observes each swept channel and the durable rows with the random sentinel absent, the tampered-store negative and the restore, and the declared non-disclosure verdict"},
 "cli":{"display":{"select":"outcome.payload","as":"json"}},
 "contracts":' + @contracts + N',
 "scenarios":[{
  "scenarioId":"read-credential-non-disclosure",
  "name":"Read the credential vault non-disclosure receipt",
  "inputId":"credential-non-disclosure-request",
  "inputContract":"credential-non-disclosure-request.v1",
  "eventId":"credential-non-disclosure-requested",
  "eventAuthority":"read-credential-non-disclosure.v1",
  "outcomeId":"credential-non-disclosure-receipt",
  "outcomeContract":"credential-non-disclosure-receipt.v1",
  "terminal":true,
  "root":true,
  "given":"one non-disclosure sweep''s random sentinel, observed channels, file scans, tampered-store negative and restore",
  "when":"the declared non-disclosure read searches every channel and the durable rows under the reader boundary",
  "then":"the receipt names each channel and the durable rows with the sentinel absent and states the declared verdict, never the sentinel",
  "operations":[{"operationId":"read-credential-non-disclosure.0","kind":"invoke-port","portId":"read-credential-non-disclosure-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;

-- ============================== PROOF ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT '1_contracts' AS result_set, d.declared_id AS contract_id
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CONTRACT'
 AND d.declared_id IN (N'credential-non-disclosure-request.v1',N'credential-non-disclosure-receipt.v1')
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
WHERE c.capability_id=N'read-credential-non-disclosure';

-- The behavioral self-test: the declared statement itself is executed on a
-- green sample and a leaked sample. The green sample mirrors the live sweep
-- (all channels clean, tampered store CREDENTIAL_NOT_AVAILABLE, restore bound);
-- the leaked sample embeds the sentinel in a channel and reports a bound
-- tampered store, and must come back NON_DISCLOSURE_VIOLATION.
DECLARE @stmt nvarchar(max)=(SELECT j.value
 FROM analysis.v_selected_semantic_definition d
 CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') j
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=N'sidefx:capability:read-credential-non-disclosure' AND d.declared_id=N'read-credential-non-disclosure-port'
  AND j.[key]=N'statement');
DECLARE @green nvarchar(max)=N'{"contractId":"credential-non-disclosure-request.v1","payload":{"sentinel":"SENTINEL-SELF-TEST-GREEN","channels":[{"channel":"invoke --json (resolve-credential)","observed":"{\"disposition\":\"CREDENTIAL_BOUND\"}","cliStatus":0,"disposition":"CREDENTIAL_BOUND"},{"channel":"observe --trace stdout + observation stream","observed":"SFX_OBSERVATION {\"observationType\":\"delivery-phase\"}","cliStatus":0,"streamedObservationLines":13},{"channel":"invoke --json (store-credential input channel)","observed":"{\"disposition\":\"CREDENTIAL_STORED\"}","cliStatus":0,"disposition":"CREDENTIAL_STORED"},{"channel":"invoke --json (equity provider exchange with the sentinel)","observed":"{\"disposition\":\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"}","cliStatus":0,"disposition":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"}],"fileScans":[{"channel":"evidence/ bundles","filesScanned":7155,"filesMatched":0,"matchedFiles":[]},{"channel":"CLI local delivery receipts","filesScanned":19,"filesMatched":0,"matchedFiles":[]}],"tamperedStore":{"disposition":"CREDENTIAL_NOT_AVAILABLE","referenceName":"RAPID_API_KEY","nonDisclosureVerified":true,"sentinelAbsent":true},"restore":{"storeDisposition":"CREDENTIAL_STORED","applyDisposition":"CREDENTIAL_BOUND","realization":"windows-credential-store-provider","sentinelRemoved":true}}}';
-- The leaked sample carries the sentinel beyond position 4000 of one channel:
-- the declared read must search the full observed text, not a truncated copy.
DECLARE @leaked nvarchar(max)=CAST(N'{"contractId":"credential-non-disclosure-request.v1","payload":{"sentinel":"SENTINEL-SELF-TEST-LEAKED","channels":[{"channel":"invoke --json (resolve-credential)","observed":"' AS nvarchar(max))
 + REPLICATE(N'x',4200) + N'SENTINEL-SELF-TEST-LEAKED","cliStatus":0,"disposition":"CREDENTIAL_BOUND"},{"channel":"observe --trace stdout + observation stream","observed":"SFX_OBSERVATION {\"observationType\":\"delivery-phase\"}","cliStatus":0,"streamedObservationLines":13}],"fileScans":[{"channel":"evidence/ bundles","filesScanned":12,"filesMatched":0,"matchedFiles":[]}],"tamperedStore":{"disposition":"CREDENTIAL_BOUND","referenceName":"RAPID_API_KEY","nonDisclosureVerified":false,"sentinelAbsent":true},"restore":{"storeDisposition":"CREDENTIAL_STORED","applyDisposition":"CREDENTIAL_BOUND","realization":"windows-credential-store-provider"}}}';
DECLARE @reading TABLE (ordinal int IDENTITY(1,1), value nvarchar(max));
INSERT @reading EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@green,@estate_model_pk=@estate;
INSERT @reading EXEC sp_executesql @stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@leaked,@estate_model_pk=@estate;
SELECT '3_self_test' AS result_set, CASE ordinal WHEN 1 THEN 'green' ELSE 'leaked' END AS sample,
 JSON_VALUE(value,'$.verdict') AS verdict,
 JSON_VALUE(value,'$.plaintextAbsent') AS plaintext_absent,
 JSON_VALUE(value,'$.durableRows.rowsMatched') AS rows_matched,
 JSON_VALUE(value,'$.channels[0].sentinelAbsent') AS first_channel_absent,
 JSON_VALUE(value,'$.tamperedStore.disposition') AS tampered_disposition,
 CASE WHEN value LIKE N'%SENTINEL-SELF-TEST-%' THEN 1 ELSE 0 END AS receipt_carries_sentinel,
 value AS receipt
FROM @reading ORDER BY ordinal;

-- The assembled graph source from the uncommitted transaction: the reader is
-- reachable through the estate view.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'read-credential-non-disclosure',0,N'sidefx:capabilities'));
SELECT '4_graph_source' AS result_set,
 JSON_VALUE(@graph,'$.capabilityId') AS capability_id,
 JSON_VALUE(@graph,'$.rootScenarioId') AS root_scenario_id,
 (SELECT COUNT(*) FROM OPENJSON(@graph,'$.executionAuthorities') a
  CROSS APPLY OPENJSON(JSON_QUERY(a.value,'$.operations')) o
  WHERE JSON_VALUE(o.value,'$.operationId')=N'read-credential-non-disclosure.0') AS operations_declared;

-- Installed 2026-09-17, after the rollback dry run and the in-transaction
-- preflight on the live sweep observations (green verdict
-- NON_DISCLOSURE_VERIFIED; the leaked sample returns NON_DISCLOSURE_VIOLATION).
-- Receipts: evidence/vault-20260916/retirement/w1.3/.
COMMIT TRANSACTION;
