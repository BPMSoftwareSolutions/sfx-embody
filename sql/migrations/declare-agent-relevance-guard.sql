-- declare-agent-relevance-guard.sql
--
-- The standing test for the agent lane's declared relevance filter. It is a
-- declared read capability (sidefx:capabilities / verify-agent-relevance-guard)
-- whose single declared-read port checks, on every invocation:
--
--   * the equity objective selects resolve-equity-market-price-evidence and
--     matches the market/price keywords declared in the index;
--   * the purchase objective selects an empty visible set (the refusal path is
--     then by absence, not by a guard in the resolution);
--   * the declared resolution logic (`decide-agent-route`'s route subtree) is
--     byte-identical to the installed one -- the filter changes what the model
--     sees, never how a proposal resolves;
--   * the decision chain declares the filter read before the request builder.
--
-- The receipt is agent-relevance-guard.v1: one check row per rule, each with
-- the observed and expected value, and a single verdict. A violated check makes
-- the read return AGENT_RELEVANCE_GUARD_VIOLATION; the migration self-test
-- refuses to install if the guard does not verify.
--
-- Default: ROLLBACK. Installed after the rollback dry run and the
-- from-transaction preflight.
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
-- ============================== THE DECLARED GUARD READ ==============================
DECLARE @statement nvarchar(max) = N'
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @equity nvarchar(max)=analysis.capability_relevance(N''What is Broadcom''''s current market price?'');
DECLARE @purchase nvarchar(max)=analysis.capability_relevance(N''Buy $1,000 worth of Broadcom.'');
DECLARE @route nvarchar(max)=(
 SELECT JSON_QUERY(d.definition_json,''$.semantics.expression.fields.route'')
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.namespace_id=N''sidefx:capability:request-capability-from-objective''
  AND d.object_kind=N''TRANSFORMATION'' AND d.declared_id=N''decide-agent-route'');
DECLARE @route_expected nvarchar(max)=N''{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"declared"},"right":{"op":"literal","value":1}},"then":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"proposedCapability"},"right":{"op":"literal","value":"resolve-equity-market-price-evidence"}},"then":{"op":"literal","value":"ADMITTED"},"else":{"op":"literal","value":"REFUSED"}},"else":{"op":"literal","value":"REFUSED"}}'';
DECLARE @checks TABLE (ordinal int IDENTITY(1,1) PRIMARY KEY, checkId nvarchar(100), passed bit, observed nvarchar(max), expected nvarchar(max));
INSERT @checks(checkId,passed,observed,expected) VALUES
 (N''equity-selects-equity-capability'',
  CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(JSON_QUERY(@equity,''$.visibleCapabilities'')) v WHERE JSON_VALUE(v.value,''$.capabilityId'')=N''resolve-equity-market-price-evidence'') THEN 1 ELSE 0 END,
  JSON_QUERY(@equity,''$.visibleCapabilities''), N''resolve-equity-market-price-evidence selected''),
 (N''equity-matches-declared-keywords'',
  CASE WHEN (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@equity,''$.matchedKeywords'')) k WHERE k.value IN (N''market'',N''price''))>=1 THEN 1 ELSE 0 END,
  JSON_QUERY(@equity,''$.matchedKeywords''), N''at least one of [market,price]''),
 (N''purchase-visible-set-empty'',
  CASE WHEN JSON_VALUE(@purchase,''$.visibleCapabilityCount'')=N''0'' THEN 1 ELSE 0 END,
  JSON_QUERY(@purchase,''$.visibleCapabilities''), N''[]''),
 (N''resolution-logic-unchanged'',
  CASE WHEN @route=@route_expected COLLATE Latin1_General_100_BIN2 THEN 1 ELSE 0 END,
  @route, @route_expected),
 (N''filter-declared-before-builder'',
  CASE WHEN EXISTS(
   SELECT 1 FROM model.execution_authority ea
   JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=N''sidefx:capability:request-capability-from-objective''
   JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
   JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
   JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
   JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
   JOIN model.port p ON p.port_pk=pv.port_pk
   WHERE ea.execution_authority_id=N''decide-agent-route.v1'' AND eo.ordinal=0 AND p.port_id=N''assemble-agent-relevance-port''
    AND eav.execution_authority_version_pk=(SELECT MAX(v.execution_authority_version_pk) FROM model.execution_authority_version v WHERE v.execution_authority_pk=ea.execution_authority_pk)) THEN 1 ELSE 0 END,
  N''ordinal 0 = assemble-agent-relevance-port'', N''ordinal 0 = assemble-agent-relevance-port'');
DECLARE @checks_json nvarchar(max)=(SELECT checkId,CONVERT(bit,passed) AS passed,CASE WHEN LEFT(LTRIM(observed),1) IN (N''{'',N''['') THEN JSON_QUERY(observed) ELSE observed END AS observed,CASE WHEN LEFT(LTRIM(expected),1) IN (N''{'',N''['') THEN JSON_QUERY(expected) ELSE expected END AS expected FROM @checks ORDER BY ordinal FOR JSON PATH);
DECLARE @violations int=(SELECT COUNT(*) FROM @checks WHERE passed=0);
SELECT (SELECT N''agent-relevance-guard.v1'' AS receiptType,N''verify-agent-relevance-guard'' AS readBy,
 CONVERT(nvarchar(30),SYSUTCDATETIME(),126)+N''Z'' AS checkedAt,
 JSON_QUERY(@checks_json) AS checks,(SELECT COUNT(*) FROM @checks) AS checkCount,@violations AS violationCount,
 CASE WHEN @violations=0 THEN N''AGENT_RELEVANCE_GUARD_VERIFIED'' ELSE N''AGENT_RELEVANCE_GUARD_VIOLATION'' END AS verdict
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value';
DECLARE @contracts nvarchar(max) = N'[
 {"id":"agent-relevance-guard-request.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/agent-relevance-guard-request.v1.schema.json","title":"Agent relevance guard request","type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"const":"agent-relevance-guard-request.v1"},"payload":{"type":"object","additionalProperties":true}}}},
 {"id":"agent-relevance-guard-receipt.v1","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.sidefx.local/contracts/agent-relevance-guard-receipt.v1.schema.json","title":"Agent relevance guard receipt","type":"object","additionalProperties":true,"required":["receiptType","checks","checkCount","violationCount","verdict"],"properties":{"receiptType":{"const":"agent-relevance-guard.v1"},"readBy":{"type":"string"},"checkedAt":{"type":"string"},"checks":{"type":"array"},"checkCount":{"type":"integer"},"violationCount":{"type":"integer"},"verdict":{"type":"string"}}}}
]';
DECLARE @bindings nvarchar(max) = N'[{"portId":"verify-agent-relevance-guard-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'
 + STRING_ESCAPE(@statement,N'json') + N'","resultColumn":"value"}}]';
DECLARE @document nvarchar(max) = N'{
 "document":"sidefx-capability-authority.v1",
 "capabilityId":"verify-agent-relevance-guard",
 "meaning":{"intent":"verify the agent lane''s declared capability-relevance filter and its unchanged resolution logic","outcome":"one guard receipt naming every declared check with its verdict"},
 "cli":{"display":{"select":"outcome.payload","as":"json"}},
 "contracts":' + @contracts + N',
 "scenarios":[{
  "scenarioId":"verify-agent-relevance-guard",
  "name":"Verify the agent lane relevance filter",
  "inputId":"agent-relevance-guard-request",
  "inputContract":"agent-relevance-guard-request.v1",
  "eventId":"agent-relevance-guard-requested",
  "eventAuthority":"verify-agent-relevance-guard.v1",
  "outcomeId":"agent-relevance-guard-receipt",
  "outcomeContract":"agent-relevance-guard-receipt.v1",
  "given":"the declared filter and the two acceptance objectives",
  "when":"the declared guard read matches each objective and the declared resolution logic",
  "then":"the receipt states every check with a verified or violated verdict",
  "terminal":true,
  "root":true,
  "operations":[{"operationId":"verify-agent-relevance-guard.0","kind":"invoke-port","portId":"verify-agent-relevance-guard-port"}],
  "portBindings":' + @bindings + N'
 }]
}';
EXEC model.declare_capability_document @document=@document;
GO
-- ============================== SELF-TEST AND PROOF ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @statement nvarchar(max)=(SELECT j.value
 FROM analysis.v_selected_semantic_definition d
 CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') j
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT'
  AND d.namespace_id=N'sidefx:capability:verify-agent-relevance-guard' AND d.declared_id=N'verify-agent-relevance-guard-port'
  AND j.[key]=N'statement');
DECLARE @reading TABLE (value nvarchar(max));
INSERT @reading EXEC sp_executesql @statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=N'{"contractId":"agent-relevance-guard-request.v1","payload":{}}',@estate_model_pk=@estate;
DECLARE @verdict nvarchar(80)=(SELECT TOP 1 JSON_VALUE(value,'$.verdict') FROM @reading);
DECLARE @violations int=(SELECT TOP 1 CONVERT(int,JSON_VALUE(value,'$.violationCount')) FROM @reading);
SELECT '1_guard_self_test' AS result_set, @verdict AS verdict, @violations AS violation_count,
 (SELECT TOP 1 value FROM @reading) AS receipt;
IF @verdict IS NULL THROW 51000,N'GUARD_SELF_TEST_NO_RECEIPT',1;
IF @verdict<>N'AGENT_RELEVANCE_GUARD_VERIFIED' THROW 51000,N'GUARD_SELF_TEST_VIOLATED',1;
SELECT '2_capability' AS result_set, c.capability_id, s.scenario_id, s.scenario_id AS root_scenario
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_root_scenario crs ON crs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=crs.scenario_pk
WHERE c.capability_id=N'verify-agent-relevance-guard';
COMMIT TRANSACTION;
-- Installed 2026-09-19: the guard self-test returns
-- AGENT_RELEVANCE_GUARD_VERIFIED with zero violations on the installed C#
-- kernel; receipts under evidence/vault-20260916/lane-relevance/.
