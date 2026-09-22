-- repoint-altitude-stubs-to-live-model.sql
--
-- Window 2: replace the 11 altitude STUB ports of `authoring-altitude-model-stubs`
-- with placements to the live model port. Each of the 11 altitude operations is
-- re-declared onto a new port whose configuration is the selected
-- `obtain-governed-model-response-port` envelope verbatim: the projected
-- invocation of `execute-governed-model-invocation` (bindingDigest,
-- capabilityAuthorityDigest, lineageMode retain-nested-execution, requestPath
-- `currentInvocationRequest`, resultMode bind-outcome, resultPath
-- `primaryModelEvidence`, declaredApplication) - the connector path the live
-- lane uses, whose embedded execution plan carries the vault credential
-- reference `LOC_GEMINI_API_KEY` and its endpoint authority digest
-- `sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04`.
--
-- Mechanism C placements are made through model.install_model_placement_change
-- with a re-declared altitude scenario carrier (same faces, same contracts,
-- same operation ids; the operation's port changes). The re-declaration mints a
-- new execution_authority version whose operation_port_invocation rows point at
-- the new port - the relink. The 11 stub ports are then retired (links removed,
-- definitions de-selected, retirement receipts written) with the canned stub
-- transformation rows retained (retired by disuse, never deleted).
--
-- Idempotent: a linked port with byte-identical semantics answers
-- already_installed; a retired port answers already_retired; the second call for
-- each altitude is exercised inside this transaction as the replay proof.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'ALTITUDE_REPOINT_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability_id nvarchar(400)=N'authoring-altitude-model-stubs';
DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
DECLARE @live_port_id nvarchar(400)=N'obtain-governed-model-response-port';
DECLARE @live_namespace nvarchar(400)=N'sidefx:capability:obtain-governed-model-response';
-- Fast replay gate: the installed state is fully present (all 11 new placements
-- selected, all 11 stub-port retirement receipts selected, no stub port selected),
-- so a replay answers already_declared and writes nothing; the heavy semantics
-- reads and proofs below run only on the fresh install.
DECLARE @replay_ready bit=CASE WHEN
 (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
    AND d.declared_id LIKE N'%-live-model-port')=11
 AND (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
    AND d.declared_id LIKE N'%.retired.v1' AND d.definition_json LIKE N'%model-placement-retirement-receipt.v1%')=11
 AND (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
    AND (d.declared_id LIKE N'%-stub-port' OR d.declared_id=N'authoring-altitude-model-stubs-port' COLLATE Latin1_General_100_BIN2))=0
 THEN 1 ELSE 0 END;
IF @replay_ready=1
BEGIN
 SELECT N'0_replay_state' AS result_set,N'already_declared' AS disposition;
END
ELSE
BEGIN
DECLARE @live_config nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics.configuration')
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'PORT' AND d.namespace_id=@live_namespace
  AND d.declared_id=@live_port_id COLLATE Latin1_General_100_BIN2);
IF @live_config IS NULL THROW 51000,N'ALTITUDE_REPOINT_LIVE_PORT_MISSING',1;
IF JSON_VALUE(@live_config,'$.bindingDigest') IS NULL OR JSON_VALUE(@live_config,'$.capabilityAuthorityDigest') IS NULL
 OR JSON_VALUE(@live_config,'$.requestPath') IS NULL OR JSON_VALUE(@live_config,'$.resultPath') IS NULL
 OR JSON_VALUE(@live_config,'$.lineageMode')<>N'retain-nested-execution'
 OR JSON_QUERY(@live_config,'$.declaredApplication') IS NULL
 THROW 51000,N'ALTITUDE_REPOINT_LIVE_CONFIGURATION_INCOMPLETE',1;
IF @live_config NOT LIKE N'%LOC_GEMINI_API_KEY%' THROW 51000,N'ALTITUDE_REPOINT_CREDENTIAL_REFERENCE_MISSING',1;
IF @live_config NOT LIKE N'%57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04%'
 THROW 51000,N'ALTITUDE_REPOINT_ENDPOINT_DIGEST_MISSING',1;
SELECT N'0_live_connector_envelope' AS result_set,@live_namespace AS namespace_id,@live_port_id AS port_id,
 JSON_VALUE(@live_config,'$.bindingDigest') AS binding_digest,
 JSON_VALUE(@live_config,'$.capabilityAuthorityDigest') AS capability_authority_digest,
 JSON_VALUE(@live_config,'$.requestPath') AS request_path,
 JSON_VALUE(@live_config,'$.resultPath') AS result_path,
 N'LOC_GEMINI_API_KEY' AS credential_reference,
 N'sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04' AS endpoint_authority_digest;

-- ============================== BASELINE ==============================
DECLARE @digest_before TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @digest_before(capability_id,digest,bytes)
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
IF (SELECT COUNT(*) FROM @digest_before)<>4 THROW 51000,N'ALTITUDE_REPOINT_BASELINE_MISSING',1;
DECLARE @contracts_before TABLE(contract_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,definition_digest varchar(64));
INSERT @contracts_before(contract_id,definition_digest)
SELECT d.declared_id,LOWER(CONVERT(varchar(64),d.definition_digest,2))
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT'
 AND (d.declared_id=N'authoring-altitude-model-stubs-request.v1' OR d.declared_id LIKE N'altitude-%-output.v1');
IF (SELECT COUNT(*) FROM @contracts_before)<>12 THROW 51000,N'ALTITUDE_REPOINT_CONTRACT_BASELINE_MISSING',1;
DECLARE @stub_transformations_before int=(SELECT COUNT(*) FROM model.transformation t
 JOIN model.semantic_object o ON o.semantic_object_pk=t.semantic_object_pk
 JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
 WHERE n.namespace_id=@namespace AND (o.declared_id=N'authoring-altitude-model-stubs-transform.v1' OR o.declared_id LIKE N'altitude-%-stub-transform.v1'));
IF @stub_transformations_before<>11 THROW 51000,N'ALTITUDE_REPOINT_STUB_TRANSFORMATIONS_MISSING',1;

-- ============================== ALTITUDE DISCOVERY ==============================
-- Stable identities only: the capability's selected scenarios, each carrying its
-- execution authority id (<scenarioId>.v1), one invoke-port operation, and its
-- declared faces. The stub/new port ids are named deterministically from them.
DECLARE @alt TABLE(ordinal int NOT NULL PRIMARY KEY,
 altitude_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 scenario_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 authority_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 operation_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 old_port_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 new_port_id nvarchar(400) COLLATE Latin1_General_100_BIN2 NOT NULL,
 scenario_json nvarchar(max) NOT NULL);
DECLARE @a_ordinal int,@a_scenario nvarchar(400),@a_name nvarchar(400),@a_in_id nvarchar(400),@a_in_contract nvarchar(400),
 @a_event_id nvarchar(400),@a_authority nvarchar(400),@a_out_id nvarchar(400),@a_out_contract nvarchar(400),
 @a_given nvarchar(max),@a_when nvarchar(max),@a_then nvarchar(max),@a_terminal bit,@a_root bit,@a_operation nvarchar(400),
 @a_old_port nvarchar(400),@a_new_port nvarchar(400),@a_scenario_json nvarchar(max),@a_ops nvarchar(max);
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
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk AND eo.operation_kind=N'invoke-port'
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
 SET @a_operation=@a_scenario+N'.stub';
 SET @a_old_port=CASE WHEN @a_root=1 THEN @a_scenario+N'-port' ELSE @a_scenario+N'-stub-port' END;
 SET @a_new_port=CASE WHEN @a_root=1 THEN @a_scenario+N'-live-model-port' ELSE @a_scenario+N'-live-model-port' END;
 SET @a_ops=N'[{"operationId":"'+@a_operation+N'","kind":"invoke-port","portId":"'+@a_new_port+N'"}]';
 SET @a_scenario_json=(SELECT @a_scenario AS scenarioId,@a_name AS name,@a_in_id AS inputId,@a_in_contract AS inputContract,
  @a_event_id AS eventId,@a_authority AS eventAuthority,@a_out_id AS outcomeId,@a_out_contract AS outcomeContract,
  @a_given AS given,@a_when AS [when],@a_then AS [then],CONVERT(bit,@a_root) AS [root],CONVERT(bit,@a_terminal) AS [terminal]
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @a_scenario_json=JSON_MODIFY(@a_scenario_json,'$.operations',JSON_QUERY(@a_ops));
 INSERT @alt(ordinal,altitude_id,scenario_id,authority_id,operation_id,old_port_id,new_port_id,scenario_json)
 VALUES(@a_ordinal,@a_scenario,@a_scenario,@a_authority,@a_operation,@a_old_port,@a_new_port,@a_scenario_json);
 FETCH NEXT FROM alt_cursor INTO @a_ordinal,@a_scenario,@a_name,@a_in_id,@a_in_contract,@a_event_id,@a_authority,@a_out_id,
  @a_out_contract,@a_given,@a_when,@a_then,@a_terminal,@a_root;
END
CLOSE alt_cursor; DEALLOCATE alt_cursor;
IF (SELECT COUNT(*) FROM @alt)<>11 THROW 51000,N'ALTITUDE_REPOINT_ALTITUDE_DISCOVERY_INCOMPLETE',1;
IF EXISTS(SELECT 1 FROM @alt WHERE authority_id<>scenario_id+N'.v1') THROW 51000,N'ALTITUDE_REPOINT_AUTHORITY_NAMING_CHANGED',1;
-- Installed-state gate: when every new placement is selected, every stub port is
-- retired and no stub port remains selected, the heavy placement/retire loops are
-- skipped (a replay writes nothing and answers already_declared); the proofs
-- below still run.
DECLARE @already bit=CASE WHEN
 (SELECT COUNT(*) FROM @alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate
   AND d.object_kind=N'PORT' AND d.namespace_id=@namespace AND d.declared_id=a.new_port_id COLLATE Latin1_General_100_BIN2)=11
 AND (SELECT COUNT(*) FROM @alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate
   AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace AND d.declared_id=(a.old_port_id+N'.retired.v1') COLLATE Latin1_General_100_BIN2)=11
 AND (SELECT COUNT(*) FROM @alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate
   AND d.object_kind=N'PORT' AND d.namespace_id=@namespace AND d.declared_id=a.old_port_id COLLATE Latin1_General_100_BIN2)=0
 THEN 1 ELSE 0 END;
IF @already=1 SELECT N'0_replay_state' AS result_set,N'already_declared' AS disposition,
 (SELECT COUNT(*) FROM @alt) AS altitudes,(SELECT COUNT(*) FROM @alt) AS new_placements_selectable;

-- ============================== PLACEMENTS ==============================
-- install_model_placement_change captures declare_scenario through its own
-- INSERT EXEC, so no caller may wrap it in another INSERT EXEC. Each altitude is
-- placed, then placed again in the same transaction; the second call must mint
-- no port_version (the in-transaction replay proof).
DECLARE @p_ordinal int,@p_altitude nvarchar(400),@p_new_port nvarchar(400),@p_scenario nvarchar(max),@p_document nvarchar(max);
DECLARE @p_versions_before int,@p_versions_after int,@placements_installed int=0,@placement_replays int=0;
IF @already=0
BEGIN
DECLARE place_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,altitude_id,new_port_id,scenario_json FROM @alt ORDER BY ordinal;
OPEN place_cursor;
FETCH NEXT FROM place_cursor INTO @p_ordinal,@p_altitude,@p_new_port,@p_scenario;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @p_document=(SELECT N'model-placement-change.v1' AS contractId,@capability_id AS capabilityId,@namespace AS [namespace],
  @p_new_port AS portId,N'sda-projected-capability-invocation-port.v2' AS platformCapabilityId,
  JSON_QUERY(@live_config) AS configuration,JSON_QUERY(@p_scenario) AS scenario
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @p_versions_before=(SELECT COUNT(*) FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk
  WHERE p.port_id=@p_new_port COLLATE Latin1_General_100_BIN2);
 EXEC model.install_model_placement_change @document=@p_document;
 SET @p_versions_after=(SELECT COUNT(*) FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk
  WHERE p.port_id=@p_new_port COLLATE Latin1_General_100_BIN2);
 IF @p_versions_after=@p_versions_before+1 SET @placements_installed=@placements_installed+1;
 ELSE IF @p_versions_after<>@p_versions_before THROW 51000,N'ALTITUDE_REPOINT_PLACEMENT_VERSION_CHANGED',1;
 EXEC model.install_model_placement_change @document=@p_document;
 IF (SELECT COUNT(*) FROM model.port_version pv JOIN model.port p ON p.port_pk=pv.port_pk
   WHERE p.port_id=@p_new_port COLLATE Latin1_General_100_BIN2)<>@p_versions_after
  THROW 51000,N'ALTITUDE_REPOINT_PLACEMENT_REPLAY_WROTE',1;
 SET @placement_replays=@placement_replays+1;
 FETCH NEXT FROM place_cursor INTO @p_ordinal,@p_altitude,@p_new_port,@p_scenario;
END
CLOSE place_cursor; DEALLOCATE place_cursor;
IF @already=0 AND @placement_replays<>11 THROW 51000,N'ALTITUDE_REPOINT_PLACEMENT_COUNT_CHANGED',1;
END

-- ============================== RETIRE STUB PORTS ==============================
-- The canned stub transformation rows stay: the ports that referenced them are
-- retired (links removed, definitions de-selected, receipts written). Replay of
-- the same disposition returns already_retired and writes no receipt.
DECLARE @r_ordinal int,@r_altitude nvarchar(400),@r_old_port nvarchar(400);
DECLARE @r_receipts_before int,@r_receipts_after int,@retirements int=0,@retirement_replays int=0;
IF @already=0
BEGIN
DECLARE retire_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,altitude_id,old_port_id FROM @alt ORDER BY ordinal;
OPEN retire_cursor;
FETCH NEXT FROM retire_cursor INTO @r_ordinal,@r_altitude,@r_old_port;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @r_receipts_before=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@r_old_port+N'.retired.v1' COLLATE Latin1_General_100_BIN2);
 EXEC model.retire_model_placement @namespace=@namespace,@port=@r_old_port,@disposition=N'RETIRED';
 SET @r_receipts_after=(SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND d.declared_id=@r_old_port+N'.retired.v1' COLLATE Latin1_General_100_BIN2);
 IF @r_receipts_after=@r_receipts_before+1 SET @retirements=@retirements+1;
 ELSE IF @r_receipts_after<>@r_receipts_before THROW 51000,N'ALTITUDE_REPOINT_RETIREMENT_DRIFTED',1;
 -- The port semantic object may carry more than one selected definition (the
 -- shell port holds two); retire de-selects the selected one, so the remaining
 -- memberships of this retired port are removed here. Definitions stay.
 IF @r_receipts_after=@r_receipts_before+1
  DELETE ed FROM model.estate_definition ed
  JOIN model.semantic_object_definition df ON df.semantic_object_definition_pk=ed.semantic_object_definition_pk
  JOIN model.semantic_object o ON o.semantic_object_pk=df.semantic_object_pk
  JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
  WHERE ed.estate_model_pk=@estate AND n.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
   AND o.object_kind=N'PORT' AND o.declared_id=@r_old_port COLLATE Latin1_General_100_BIN2;
 EXEC model.retire_model_placement @namespace=@namespace,@port=@r_old_port,@disposition=N'RETIRED';
 IF (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition d
   WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=@namespace COLLATE Latin1_General_100_BIN2
    AND d.declared_id=@r_old_port+N'.retired.v1' COLLATE Latin1_General_100_BIN2)<>@r_receipts_after
  THROW 51000,N'ALTITUDE_REPOINT_RETIREMENT_REPLAY_WROTE',1;
 SET @retirement_replays=@retirement_replays+1;
 FETCH NEXT FROM retire_cursor INTO @r_ordinal,@r_altitude,@r_old_port;
END
CLOSE retire_cursor; DEALLOCATE retire_cursor;
IF @already=0 AND @retirement_replays<>11 THROW 51000,N'ALTITUDE_REPOINT_RETIREMENT_COUNT_CHANGED',1;
END

-- ============================== PROOFS ==============================
-- The 11 operations relinked: each selected altitude authority carries exactly
-- one invoke-port link and it points at the new live-model port.
SELECT N'1_relinked_operations' AS result_set,a.ordinal,a.altitude_id,a.operation_id,a.old_port_id,a.new_port_id,
 eav.execution_authority_version_pk AS authority_version_pk,pv.port_version_pk,
 (SELECT COUNT(*) FROM model.operation_port_invocation i JOIN model.port_version x ON x.port_version_pk=i.port_version_pk
   JOIN model.port xp ON xp.port_pk=x.port_pk WHERE i.execution_operation_pk=eo.execution_operation_pk
   AND xp.port_id=a.new_port_id COLLATE Latin1_General_100_BIN2) AS links_to_new_port
FROM @alt a
JOIN model.capability c ON c.capability_id=@capability_id
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario sc ON sc.scenario_pk=cs.scenario_pk AND sc.scenario_id=a.scenario_id
JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk AND eo.operation_kind=N'invoke-port'
JOIN model.operation_port_invocation i ON i.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk
JOIN model.port p ON p.port_pk=pv.port_pk AND p.port_id=a.new_port_id COLLATE Latin1_General_100_BIN2
ORDER BY a.ordinal;
IF (SELECT COUNT(*) FROM @alt a
 JOIN model.capability c ON c.capability_id=@capability_id
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
 JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
 JOIN model.scenario sc ON sc.scenario_pk=cs.scenario_pk AND sc.scenario_id=a.scenario_id
 JOIN model.scenario_event se ON se.scenario_version_pk=cs.scenario_version_pk
 JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk AND eo.operation_kind=N'invoke-port'
 JOIN model.operation_port_invocation i ON i.execution_operation_pk=eo.execution_operation_pk
 JOIN model.port_version pv ON pv.port_version_pk=i.port_version_pk
 JOIN model.port p ON p.port_pk=pv.port_pk AND p.port_id=a.new_port_id COLLATE Latin1_General_100_BIN2)<>11
 THROW 51000,N'ALTITUDE_REPOINT_RELINK_COUNT_CHANGED',1;
-- Every new port carries the live connector envelope byte-for-byte.
SELECT N'2_new_placements' AS result_set,a.ordinal,a.new_port_id,
 d.declared_id AS selected_id,LOWER(CONVERT(varchar(64),d.definition_digest,2)) AS definition_digest,
 CASE WHEN JSON_VALUE(d.definition_json,'$.semantics.configuration.bindingDigest')
   =JSON_VALUE(@live_config,'$.bindingDigest') THEN N'BINDING_DIGEST_PRESERVED' ELSE N'DIVERGED' END AS binding,
 CASE WHEN JSON_VALUE(d.definition_json,'$.semantics.configuration.requestPath')
   =JSON_VALUE(@live_config,'$.requestPath') THEN N'REQUEST_PATH_PRESERVED' ELSE N'DIVERGED' END AS request_path,
 CASE WHEN JSON_VALUE(d.definition_json,'$.semantics.configuration.resultPath')
   =JSON_VALUE(@live_config,'$.resultPath') THEN N'RESULT_PATH_PRESERVED' ELSE N'DIVERGED' END AS result_path,
 CASE WHEN d.definition_json LIKE N'%LOC_GEMINI_API_KEY%' THEN N'CREDENTIAL_PRESERVED' ELSE N'DIVERGED' END AS credential
FROM @alt a
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'PORT'
 AND d.namespace_id=@namespace AND d.declared_id=a.new_port_id COLLATE Latin1_General_100_BIN2
ORDER BY a.ordinal;
IF (SELECT COUNT(*) FROM @alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'PORT'
 AND d.namespace_id=@namespace AND d.declared_id=a.new_port_id COLLATE Latin1_General_100_BIN2 WHERE d.definition_json LIKE N'%LOC_GEMINI_API_KEY%')<>11
 THROW 51000,N'ALTITUDE_REPOINT_CREDENTIAL_NOT_PRESERVED',1;
-- The stub ports are de-selected and receipted; their canned transformations stay.
SELECT N'3_stub_state' AS result_set,
 (SELECT COUNT(*) FROM @alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'PORT'
   AND d.namespace_id=@namespace AND d.declared_id=a.old_port_id COLLATE Latin1_General_100_BIN2) AS stub_ports_still_selected,
 (SELECT COUNT(*) FROM @alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY'
   AND d.namespace_id=@namespace AND d.declared_id=a.old_port_id+N'.retired.v1' COLLATE Latin1_General_100_BIN2 AND d.definition_json LIKE N'%model-placement-retirement-receipt.v1%') AS retired_receipts,
 @stub_transformations_before AS canned_transformations_before,
 (SELECT COUNT(*) FROM model.transformation t JOIN model.semantic_object o ON o.semantic_object_pk=t.semantic_object_pk
  JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
  WHERE n.namespace_id=@namespace AND (o.declared_id=N'authoring-altitude-model-stubs-transform.v1' OR o.declared_id LIKE N'altitude-%-stub-transform.v1')) AS canned_transformations_after,
 (SELECT COUNT(*) FROM @alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'PORT'
   AND d.namespace_id=@namespace AND d.declared_id=a.old_port_id COLLATE Latin1_General_100_BIN2) AS stub_ports_deleted;
IF (SELECT COUNT(*) FROM @alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'PORT'
   AND d.namespace_id=@namespace AND d.declared_id=a.old_port_id COLLATE Latin1_General_100_BIN2)<>0
 THROW 51000,N'ALTITUDE_REPOINT_STUB_PORT_STILL_SELECTED',1;
IF (SELECT COUNT(*) FROM @alt a JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY'
   AND d.namespace_id=@namespace AND d.declared_id=a.old_port_id+N'.retired.v1' COLLATE Latin1_General_100_BIN2 AND d.definition_json LIKE N'%model-placement-retirement-receipt.v1%')<>11
 THROW 51000,N'ALTITUDE_REPOINT_RETIREMENT_RECEIPTS_MISSING',1;
IF (SELECT COUNT(*) FROM model.transformation t JOIN model.semantic_object o ON o.semantic_object_pk=t.semantic_object_pk
   JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
   WHERE n.namespace_id=@namespace AND (o.declared_id=N'authoring-altitude-model-stubs-transform.v1' OR o.declared_id LIKE N'altitude-%-stub-transform.v1'))<>@stub_transformations_before
 THROW 51000,N'ALTITUDE_REPOINT_STUB_TRANSFORMATION_DELETED',1;
-- All 12 altitude contracts unchanged.
DECLARE @contracts_after TABLE(contract_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,definition_digest varchar(64));
INSERT @contracts_after(contract_id,definition_digest)
SELECT d.declared_id,LOWER(CONVERT(varchar(64),d.definition_digest,2))
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT'
 AND (d.declared_id=N'authoring-altitude-model-stubs-request.v1' OR d.declared_id LIKE N'altitude-%-output.v1');
SELECT N'4_contracts_unchanged' AS result_set,b.contract_id,b.definition_digest AS before_digest,a.definition_digest AS after_digest,
 CASE WHEN b.definition_digest=a.definition_digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @contracts_before b JOIN @contracts_after a ON a.contract_id=b.contract_id ORDER BY b.contract_id;
IF EXISTS(SELECT 1 FROM @contracts_before b JOIN @contracts_after a ON a.contract_id=b.contract_id WHERE b.definition_digest<>a.definition_digest)
 OR (SELECT COUNT(*) FROM @contracts_after)<>12
 THROW 51000,N'ALTITUDE_REPOINT_CONTRACT_CHANGED',1;
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
SELECT N'5_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @digest_before b JOIN @digest_after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @digest_before b JOIN @digest_after a ON a.capability_id=b.capability_id
 WHERE b.capability_id<>@capability_id COLLATE Latin1_General_100_BIN2 AND b.digest<>a.digest)
 THROW 51000,N'ALTITUDE_REPOINT_UNRELATED_CAPABILITY_CHANGED',1;

SELECT N'6_disposition' AS result_set,@capability_id AS capability_id,
 CASE WHEN @already=1 THEN N'already_declared' ELSE N'redeclared' END AS disposition,
 @placement_replays AS placements,
 @placements_installed AS placements_installed,
 @placement_replays AS placement_replays,
 @retirements AS retirements,
 @retirement_replays AS retirement_replays,
 (SELECT COUNT(*) FROM @alt) AS altitudes,
 (SELECT COUNT(*) FROM @contracts_after) AS contracts;
END
ROLLBACK TRANSACTION;
