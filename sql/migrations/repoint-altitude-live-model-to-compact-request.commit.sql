-- repoint-altitude-live-model-to-compact-request.sql
--
-- Lane 3, items 3 and 6 of docs/compact-altitude-request-plan-2026-09-22.md.
-- For each of the eleven altitude scenarios of `authoring-altitude-model-stubs`:
--
--   1. declare the composing adapter port `<scenario>-compose-port` bound to the
--      declared transformation `compose-altitude-request.v1` and re-declare the
--      scenario authority with the adapter operation ahead of the live model
--      operation (`<scenario>.compose` then `<scenario>.stub`); the authority
--      re-mint relinks the scenario event and mints the operation links;
--   2. call model.replace_port_configuration on `<scenario>-live-model-port` so
--      the model operation reads its request from the adapter output
--      (`requestPath` = ".") instead of the copied lane envelope
--      (`requestPath` = "currentInvocationRequest"), and drop the copied lane
--      `invocationCondition` key that preserves the carrier when
--      payload.resolutionStatus is absent from the compact request.
--
-- What is preserved: the port's bindingDigest, capabilityAuthorityDigest,
-- lineageMode retain-nested-execution, resultMode bind-outcome, resultPath
-- primaryModelEvidence, and the declared application carrying the vault
-- credential reference LOC_GEMINI_API_KEY and the endpoint authority digest
-- sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04;
-- the adapter is a separate operation/port, so only the request shape changes.
--
-- History stays: prior port_version rows, authority versions and definitions
-- are never deleted; replace_port_configuration appends the new definition +
-- port_version and relinks the operation_port_invocation rows.
--
-- Batching: the eleven re-points exceed one 600 s request bound, so the work is
-- split per altitude (one batch each) inside the single transaction opened
-- here; the session-scoped state lives in temp tables and the helper procedure
-- is dropped before the transaction ends. Nothing outside this migration runs
-- between the batches: the runner holds one connection and the transaction open.
--
-- Idempotent: when all eleven adapter ports are selected, all eleven model ports
-- read requestPath "." and no model port keeps invocationCondition, the replay
-- answers already_declared and writes nothing; each write block also replays its
-- own replace call inside the transaction and asserts no version was minted.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'COMPACT_REPOINT_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
-- ============================== BASELINE + DISCOVERY ==============================
IF OBJECT_ID('tempdb..#alt') IS NOT NULL DROP TABLE #alt;
IF OBJECT_ID('tempdb..#digest_before') IS NOT NULL DROP TABLE #digest_before;
IF OBJECT_ID('tempdb..#contracts_before') IS NOT NULL DROP TABLE #contracts_before;
IF OBJECT_ID('tempdb..#state') IS NOT NULL DROP TABLE #state;
CREATE TABLE #alt(ordinal int NOT NULL PRIMARY KEY,
 altitude_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 scenario_json nvarchar(max) NOT NULL);
CREATE TABLE #digest_before(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,
 digest varchar(64),bytes bigint);
CREATE TABLE #contracts_before(contract_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,
 definition_digest varchar(64));
CREATE TABLE #state(already bit,model_versions_before int);
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability_id nvarchar(400)=N'authoring-altitude-model-stubs';
DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
INSERT #digest_before(capability_id,digest,bytes)
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
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(@capability_id,1,NULL) g;
IF (SELECT COUNT(*) FROM #digest_before)<>4 THROW 51000,N'COMPACT_REPOINT_BASELINE_MISSING',1;
INSERT #contracts_before(contract_id,definition_digest)
SELECT d.declared_id,LOWER(CONVERT(varchar(64),d.definition_digest,2))
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT'
 AND (d.declared_id=N'authoring-altitude-model-stubs-request.v1' OR d.declared_id LIKE N'altitude-%-output.v1'
   OR d.declared_id IN (N'altitude-model-request.v1',N'altitude-model-response.v1'));
IF (SELECT COUNT(*) FROM #contracts_before)<>14 THROW 51000,N'COMPACT_REPOINT_CONTRACT_BASELINE_MISSING',1;
DECLARE @a_ordinal int,@a_scenario nvarchar(400),@a_name nvarchar(400),@a_in_id nvarchar(400),@a_in_contract nvarchar(400),
 @a_event_id nvarchar(400),@a_authority nvarchar(400),@a_out_id nvarchar(400),@a_out_contract nvarchar(400),
 @a_given nvarchar(max),@a_when nvarchar(max),@a_then nvarchar(max),@a_terminal bit,@a_root bit,@a_scenario_json nvarchar(max);
DECLARE alt_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT CASE WHEN crs.scenario_pk IS NOT NULL THEN 1 ELSE TRY_CONVERT(int,SUBSTRING(s.scenario_id,10,CHARINDEX(N'-',s.scenario_id+'-',10)-10)) END AS ordinal,
  s.scenario_id,sv.name,si.input_id,ci.contract_id,se.event_id,ea.execution_authority_id,so.outcome_id,co.contract_id,
  si.name,se.name,so.name,CONVERT(bit,so.terminal),CASE WHEN crs.scenario_pk IS NOT NULL THEN 1 ELSE 0 END
 FROM model.capability c
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
 JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
 JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
 JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
 JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
 JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
 JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk
 JOIN model.scenario_outcome so ON so.scenario_version_pk=sv.scenario_version_pk
 JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=sv.scenario_version_pk
 JOIN model.contract_version cov ON cov.contract_version_pk=soc.contract_version_pk
 JOIN model.contract co ON co.contract_pk=cov.contract_pk
 JOIN model.contract_version civ ON civ.contract_version_pk=si.input_contract_version_pk
 JOIN model.contract ci ON ci.contract_pk=civ.contract_pk
 LEFT JOIN model.capability_root_scenario crs ON crs.capability_version_pk=ec.capability_version_pk AND crs.scenario_pk=s.scenario_pk
 WHERE c.capability_id=@capability_id COLLATE Latin1_General_100_BIN2
 ORDER BY ordinal;
OPEN alt_cursor;
FETCH NEXT FROM alt_cursor INTO @a_ordinal,@a_scenario,@a_name,@a_in_id,@a_in_contract,@a_event_id,@a_authority,@a_out_id,
 @a_out_contract,@a_given,@a_when,@a_then,@a_terminal,@a_root;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @a_scenario_json=(SELECT @a_scenario AS scenarioId,@a_name AS name,@a_in_id AS inputId,@a_in_contract AS inputContract,
  @a_event_id AS eventId,@a_authority AS eventAuthority,@a_out_id AS outcomeId,@a_out_contract AS outcomeContract,
  @a_given AS given,@a_when AS [when],@a_then AS [then],CONVERT(bit,@a_root) AS [root],CONVERT(bit,@a_terminal) AS [terminal]
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 INSERT #alt(ordinal,altitude_id,scenario_json) VALUES(@a_ordinal,@a_scenario,@a_scenario_json);
 FETCH NEXT FROM alt_cursor INTO @a_ordinal,@a_scenario,@a_name,@a_in_id,@a_in_contract,@a_event_id,@a_authority,@a_out_id,
  @a_out_contract,@a_given,@a_when,@a_then,@a_terminal,@a_root;
END
CLOSE alt_cursor; DEALLOCATE alt_cursor;
IF (SELECT COUNT(*) FROM #alt)<>11 THROW 51000,N'COMPACT_REPOINT_ALTITUDE_DISCOVERY_INCOMPLETE',1;
DECLARE @adapter_selected int=(SELECT COUNT(*) FROM #alt a JOIN analysis.v_selected_semantic_definition d
 ON d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
 AND d.declared_id=(a.altitude_id+N'-compose-port') COLLATE Latin1_General_100_BIN2);
DECLARE @compact_selected int=(SELECT COUNT(*) FROM #alt a JOIN analysis.v_selected_semantic_definition d
 ON d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
 AND d.declared_id=(a.altitude_id+N'-live-model-port') COLLATE Latin1_General_100_BIN2
 AND JSON_VALUE(d.definition_json,'$.semantics.configuration.requestPath')=N'.'
 AND JSON_QUERY(d.definition_json,'$.semantics.configuration.invocationCondition') IS NULL);
INSERT #state(already,model_versions_before)
SELECT CASE WHEN @adapter_selected=11 AND @compact_selected=11 THEN CONVERT(bit,1) ELSE CONVERT(bit,0) END,
 (SELECT COUNT(*) FROM model.port p JOIN model.port_version pv ON pv.port_pk=p.port_pk
  WHERE p.port_id LIKE N'%-live-model-port' COLLATE Latin1_General_100_BIN2);
IF (SELECT already FROM #state)=1
 SELECT N'0_replay_state' AS result_set,N'already_declared' AS disposition,@adapter_selected AS adapter_ports,
  @compact_selected AS compact_ports;
GO
-- ============================== PER-ALTITUDE REPOINT ==============================
CREATE OR ALTER PROCEDURE model.compact_repoint_altitude @altitude nvarchar(400)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 THROW 51000,N'COMPACT_REPOINT_TRANSACTION_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability_id nvarchar(400)=N'authoring-altitude-model-stubs';
 DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
 DECLARE @adapter_transformation nvarchar(400)=N'compose-altitude-request.v1';
 DECLARE @credential_reference nvarchar(100)=N'LOC_GEMINI_API_KEY';
 DECLARE @endpoint_digest nvarchar(80)=N'sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04';
 DECLARE @scenario nvarchar(max)=(SELECT scenario_json FROM #alt WHERE altitude_id=@altitude COLLATE Latin1_General_100_BIN2);
 IF @scenario IS NULL THROW 51000,N'COMPACT_REPOINT_ALTITUDE_UNKNOWN',1;
 DECLARE @model_port nvarchar(400)=@altitude+N'-live-model-port';
 DECLARE @adapter_port nvarchar(400)=@altitude+N'-compose-port';
 DECLARE @model_semantics nvarchar(max);
 SELECT @model_semantics=JSON_QUERY(d.definition_json,'$.semantics')
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id=@model_port COLLATE Latin1_General_100_BIN2;
 IF @model_semantics IS NULL THROW 51000,N'COMPACT_REPOINT_MODEL_PORT_MISSING',1;
 DECLARE @config nvarchar(max)=JSON_QUERY(@model_semantics,'$.configuration');
 IF @config IS NULL THROW 51000,N'COMPACT_REPOINT_MODEL_CONFIG_MISSING',1;
 DECLARE @adapter_binding nvarchar(max)=N'{"portId":"'+@adapter_port+N'","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"'+@adapter_transformation+N'"}}';
 DECLARE @ops nvarchar(max)=N'[{"operationId":"'+@altitude+N'.compose","kind":"invoke-port","portId":"'+@adapter_port+N'"},{"operationId":"'+@altitude+N'.stub","kind":"invoke-port","portId":"'+@model_port+N'"}]';
 SET @scenario=JSON_MODIFY(@scenario,'$.operations',JSON_QUERY(@ops));
 DECLARE @bindings nvarchar(max)=N'['+@adapter_binding+N','+@model_semantics+N']';
 EXEC model.declare_scenario @capability_id=@capability_id,@scenario=@scenario,@operations=@ops,@port_bindings=@bindings;
 DECLARE @versions_after_declare int=(SELECT COUNT(*) FROM model.port p JOIN model.port_version pv ON pv.port_pk=p.port_pk
  WHERE p.port_id=@model_port COLLATE Latin1_General_100_BIN2);
 DECLARE @compact nvarchar(max)=JSON_MODIFY(@config,'$.requestPath',N'.');
 SET @compact=JSON_MODIFY(@compact,'$.invocationCondition',NULL);
 IF JSON_VALUE(@compact,'$.requestPath')<>N'.' THROW 51000,N'COMPACT_REPOINT_REQUEST_PATH_NOT_SET',1;
 IF @compact LIKE N'%invocationCondition%' THROW 51000,N'COMPACT_REPOINT_INVOCATION_CONDITION_KEPT',1;
 IF @compact NOT LIKE N'%'+@credential_reference+N'%' THROW 51000,N'COMPACT_REPOINT_CREDENTIAL_REFERENCE_LOST',1;
 IF @compact NOT LIKE N'%'+@endpoint_digest+N'%' THROW 51000,N'COMPACT_REPOINT_ENDPOINT_DIGEST_LOST',1;
 IF JSON_VALUE(@compact,'$.bindingDigest')<>JSON_VALUE(@config,'$.bindingDigest')
  OR JSON_VALUE(@compact,'$.capabilityAuthorityDigest')<>JSON_VALUE(@config,'$.capabilityAuthorityDigest')
  OR JSON_VALUE(@compact,'$.lineageMode')<>N'retain-nested-execution'
  OR JSON_VALUE(@compact,'$.resultMode')<>N'bind-outcome'
  OR JSON_VALUE(@compact,'$.resultPath')<>N'primaryModelEvidence'
  OR JSON_QUERY(@compact,'$.declaredApplication') IS NULL
  THROW 51000,N'COMPACT_REPOINT_ENVELOPE_MEMBER_DIVERGED',1;
 EXEC model.replace_port_configuration @namespace=@namespace,@port=@model_port,@configuration_json=@compact;
 DECLARE @versions_after_replace int=(SELECT COUNT(*) FROM model.port p JOIN model.port_version pv ON pv.port_pk=p.port_pk
  WHERE p.port_id=@model_port COLLATE Latin1_General_100_BIN2);
 IF @versions_after_replace<=@versions_after_declare THROW 51000,N'COMPACT_REPOINT_REPLACE_MINTED_NO_VERSION',1;
 EXEC model.replace_port_configuration @namespace=@namespace,@port=@model_port,@configuration_json=@compact;
 IF (SELECT COUNT(*) FROM model.port p JOIN model.port_version pv ON pv.port_pk=p.port_pk
   WHERE p.port_id=@model_port COLLATE Latin1_General_100_BIN2)<>@versions_after_replace
  THROW 51000,N'COMPACT_REPOINT_REPLACE_REPLAY_WROTE',1;
 SELECT N'1_repointed_altitude' AS result_set,@altitude AS altitude_id,@adapter_port AS adapter_port,
  @model_port AS model_port,@versions_after_declare AS model_versions_after_declare,
  @versions_after_replace AS model_versions_after_replace;
END;
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-2-capability-meaning';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-3-scenario-io';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-4-contracts-schemas';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-5-semantic-authority-envelope';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-6-transformation-ast';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-7-execution-authorities-ports';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-8-providers-bindings-overlays';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-9-interface-cli-display';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-10-fixtures-proof';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'altitude-11-alignment-evaluation';
GO
IF OBJECT_ID('tempdb..#state') IS NULL THROW 51000,N'COMPACT_REPOINT_SESSION_STATE_LOST',1;
IF (SELECT already FROM #state)=0 EXEC model.compact_repoint_altitude @altitude=N'authoring-altitude-model-stubs';
GO
-- ============================== PROOFS ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability_id nvarchar(400)=N'authoring-altitude-model-stubs';
DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
DECLARE @adapter_transformation nvarchar(400)=N'compose-altitude-request.v1';
DECLARE @credential_reference nvarchar(100)=N'LOC_GEMINI_API_KEY';
DECLARE @endpoint_digest nvarchar(80)=N'sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04';
DECLARE @repoints int=(SELECT COUNT(*) FROM #alt WHERE 1=1);
DECLARE @model_versions_before int=(SELECT model_versions_before FROM #state);
DECLARE @model_versions_after int=(SELECT COUNT(*) FROM model.port p JOIN model.port_version pv ON pv.port_pk=p.port_pk
 WHERE p.port_id LIKE N'%-live-model-port' COLLATE Latin1_General_100_BIN2);
-- Every altitude authority now carries the adapter operation first and the live
-- model operation second, each linked to its selected port version.
SELECT N'1_relinked_operations' AS result_set,a.ordinal,a.altitude_id,eo0.operation_id AS compose_operation,
 p0.port_id AS compose_port,eo1.operation_id AS model_operation,p1.port_id AS model_port,eo1.ordinal AS model_ordinal
FROM #alt a
JOIN model.capability c ON c.capability_id=@capability_id
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario sc ON sc.scenario_pk=cs.scenario_pk AND sc.scenario_id=a.altitude_id
JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
JOIN model.execution_operation eo0 ON eo0.execution_authority_version_pk=se.execution_authority_version_pk AND eo0.ordinal=0
JOIN model.operation_port_invocation i0 ON i0.execution_operation_pk=eo0.execution_operation_pk
JOIN model.port_version pv0 ON pv0.port_version_pk=i0.port_version_pk
JOIN model.port p0 ON p0.port_pk=pv0.port_pk
JOIN model.execution_operation eo1 ON eo1.execution_authority_version_pk=se.execution_authority_version_pk AND eo1.ordinal=1
JOIN model.operation_port_invocation i1 ON i1.execution_operation_pk=eo1.execution_operation_pk
JOIN model.port_version pv1 ON pv1.port_version_pk=i1.port_version_pk
JOIN model.port p1 ON p1.port_pk=pv1.port_pk
ORDER BY a.ordinal;
IF (SELECT COUNT(*) FROM #alt a
 JOIN model.capability c ON c.capability_id=@capability_id
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
 JOIN model.scenario sc ON sc.scenario_pk=cs.scenario_pk AND sc.scenario_id=a.altitude_id
 JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
 JOIN model.execution_operation eo0 ON eo0.execution_authority_version_pk=se.execution_authority_version_pk AND eo0.ordinal=0
 JOIN model.operation_port_invocation i0 ON i0.execution_operation_pk=eo0.execution_operation_pk
 JOIN model.port_version pv0 ON pv0.port_version_pk=i0.port_version_pk
 JOIN model.port p0 ON p0.port_pk=pv0.port_pk AND p0.port_id=(a.altitude_id+N'-compose-port') COLLATE Latin1_General_100_BIN2
 JOIN model.execution_operation eo1 ON eo1.execution_authority_version_pk=se.execution_authority_version_pk AND eo1.ordinal=1
 JOIN model.operation_port_invocation i1 ON i1.execution_operation_pk=eo1.execution_operation_pk
 JOIN model.port_version pv1 ON pv1.port_version_pk=i1.port_version_pk
 JOIN model.port p1 ON p1.port_pk=pv1.port_pk AND p1.port_id=(a.altitude_id+N'-live-model-port') COLLATE Latin1_General_100_BIN2)<>11
 THROW 51000,N'COMPACT_REPOINT_RELINK_COUNT_CHANGED',1;
-- Every model port now reads the adapter output; the copied lane key is gone and
-- the credential reference and endpoint digest remain.
SELECT N'2_compact_ports' AS result_set,a.altitude_id,d.declared_id AS selected_id,
 LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.requestPath') AS request_path,
 CASE WHEN JSON_QUERY(d.definition_json,'$.semantics.configuration.invocationCondition') IS NULL THEN N'REMOVED' ELSE N'KEPT' END AS invocation_condition,
 CASE WHEN d.definition_json LIKE N'%'+@credential_reference+N'%' THEN N'PRESERVED' ELSE N'LOST' END AS credential_reference,
 CASE WHEN d.definition_json LIKE N'%'+@endpoint_digest+N'%' THEN N'PRESERVED' ELSE N'LOST' END AS endpoint_digest,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.bindingDigest') AS binding_digest,
 (SELECT COUNT(*) FROM model.port p JOIN model.port_version pv ON pv.port_pk=p.port_pk
   WHERE p.port_id=(a.altitude_id+N'-live-model-port') COLLATE Latin1_General_100_BIN2) AS model_port_versions
FROM #alt a
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'PORT'
 AND d.namespace_id=@namespace AND d.declared_id=(a.altitude_id+N'-live-model-port') COLLATE Latin1_General_100_BIN2
ORDER BY a.ordinal;
IF (SELECT COUNT(*) FROM #alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'PORT'
 AND d.namespace_id=@namespace AND d.declared_id=(a.altitude_id+N'-live-model-port') COLLATE Latin1_General_100_BIN2
 WHERE JSON_VALUE(d.definition_json,'$.semantics.configuration.requestPath')=N'.'
  AND JSON_QUERY(d.definition_json,'$.semantics.configuration.invocationCondition') IS NULL
  AND d.definition_json LIKE N'%'+@credential_reference+N'%'
  AND d.definition_json LIKE N'%'+@endpoint_digest+N'%')<>11
 THROW 51000,N'COMPACT_REPOINT_PORT_STATE_CHANGED',1;
IF (SELECT COUNT(*) FROM #alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'PORT'
 AND d.namespace_id=@namespace AND d.declared_id=(a.altitude_id+N'-compose-port') COLLATE Latin1_General_100_BIN2
 WHERE JSON_VALUE(d.definition_json,'$.semantics.configuration.transformationId')=@adapter_transformation)<>11
 THROW 51000,N'COMPACT_REPOINT_ADAPTER_BINDING_CHANGED',1;
IF @model_versions_after<=@model_versions_before THROW 51000,N'COMPACT_REPOINT_NO_NEW_MODEL_VERSIONS',1;
-- All 14 altitude contracts unchanged.
DECLARE @contracts_after TABLE(contract_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,definition_digest varchar(64));
INSERT @contracts_after(contract_id,definition_digest)
SELECT d.declared_id,LOWER(CONVERT(varchar(64),d.definition_digest,2))
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT'
 AND (d.declared_id=N'authoring-altitude-model-stubs-request.v1' OR d.declared_id LIKE N'altitude-%-output.v1'
   OR d.declared_id IN (N'altitude-model-request.v1',N'altitude-model-response.v1'));
SELECT N'3_contracts_unchanged' AS result_set,b.contract_id,b.definition_digest AS before_digest,a.definition_digest AS after_digest,
 CASE WHEN b.definition_digest=a.definition_digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM #contracts_before b JOIN @contracts_after a ON a.contract_id=b.contract_id ORDER BY b.contract_id;
IF EXISTS(SELECT 1 FROM #contracts_before b JOIN @contracts_after a ON a.contract_id=b.contract_id WHERE b.definition_digest<>a.definition_digest)
 OR (SELECT COUNT(*) FROM @contracts_after)<>14
 THROW 51000,N'COMPACT_REPOINT_CONTRACT_CHANGED',1;
-- Unrelated capability graph digests byte-identical; the subject changes.
DECLARE @digest_after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @digest_after(capability_id,digest,bytes)
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
FROM analysis.capability_graph_source(N'route-two-child-proof',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(@capability_id,1,NULL) g;
SELECT N'4_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM #digest_before b JOIN @digest_after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM #digest_before b JOIN @digest_after a ON a.capability_id=b.capability_id
 WHERE b.capability_id<>@capability_id COLLATE Latin1_General_100_BIN2 AND b.digest<>a.digest)
 THROW 51000,N'COMPACT_REPOINT_UNRELATED_CAPABILITY_CHANGED',1;
IF (SELECT digest FROM #digest_before WHERE capability_id=@capability_id COLLATE Latin1_General_100_BIN2)
  =(SELECT digest FROM @digest_after WHERE capability_id=@capability_id COLLATE Latin1_General_100_BIN2)
 THROW 51000,N'COMPACT_REPOINT_SUBJECT_CAPABILITY_UNCHANGED',1;
DROP PROCEDURE model.compact_repoint_altitude;
SELECT N'5_disposition' AS result_set,@capability_id AS capability_id,
 CASE WHEN (SELECT already FROM #state)=1 THEN N'already_declared' ELSE N'repointed' END AS disposition,
 @repoints AS altitudes,@model_versions_before AS model_versions_before,@model_versions_after AS model_versions_after;
COMMIT TRANSACTION;
