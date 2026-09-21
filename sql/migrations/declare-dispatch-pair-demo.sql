-- declare-dispatch-pair-demo.sql
--
-- M1: the serial half of the declaration-controlled concurrent dispatch proof.
-- One capability, one declared broadcast group, two independent branches, one
-- declared all-required join, and a graph-v2 dispatch authority carried on the
-- capability envelope at $.semantics.executionGraph.
--
--   root (dispatch-pair-demo)
--     broadcast group dispatch-pair, declared order [enter-a, enter-p]
--       branch A: dispatch-pair-demo-leg-a -- the REAL equity provider chain
--                 (build binding request -> bind credential -> build exchange
--                 request -> observe exchange), copied content-for-content from
--                 resolve-equity-market-price-evidence's installed rows into
--                 this capability's namespace. The same endpoint authority
--                 digest (sha256:09ecb038...), the same credential injection
--                 rule (rapidapi-x-rapidapi-key.v1), the same RAPID_API_KEY
--                 vault reference, and the same transformation expressions.
--       branch C: dispatch-pair-demo-leg-c -- a governed HTTPS exchange with the
--                 trusted local fixture https://localhost:8788/delay?ms=400,
--                 through the same governed HTTP port mechanic.
--     join group collect-pair, policy all-required, slots [a, c]
--       join cell: dispatch-pair-demo-join, outcome carrier
--       dispatch-pair-leg-settlement.v1
--
-- Why copy instead of composing: a projected binding for
-- resolve-equity-market-price-evidence does not exist in this estate
-- (interfaceAuthority.projectionBindings is empty everywhere), and a nested
-- invoke-scenario composition would execute the whole equity primary+fallback
-- root (fifteen operations) as one opaque child branch. Copying the four
-- declared primary-chain rows keeps branch A exactly the real provider chain,
-- keeps the branch a first-class dispatch leg the graph-v2
-- authority admits and joins, and adds no new authority of its own. The copied
-- transformations and ports are content-addressed rows; nothing about the
-- source capability changes.
--
-- Envelope $.semantics.executionGraph: mode serial, maximumActiveBranches 1,
-- maximumInFlightEffects 2, legCount 2, readyOrder declared-edge-order,
-- branchFailure collect, ownership join-before-return, executionBudget
-- maximumInFlightEffects 2 and deadlineMs 30000. M2
-- (switch-dispatch-pair-demo-concurrent.sql) re-mints only the dispatch
-- authority to concurrent / 2.
--
-- Idempotent: first install scaffolds the shell; a replay in the same state
-- keeps the shell and converges the declaration, and the envelope re-mint
-- reuses the definition digest with no new version. A replay that asks to
-- return to an already-minted envelope after a later switch (for example
-- replaying M1 after M2) refuses loudly rather than re-pointing the capability
-- to a definition the declaration TVFs no longer select as latest.
--
-- Default: ROLLBACK after verification. Install by replacing the final ROLLBACK
-- with COMMIT. M2 must not be installed before M1 is installed.
SET NOCOUNT ON;
SET XACT_ABORT ON;
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
BEGIN TRANSACTION;
GO

-- ============================== CONTRACTS AND CAPABILITY SHELL ==============================
-- The pair carrier contract is deliberately open: the branch outcome values are
-- the governed effect evidence objects, each with its own contract. The carrier
-- names the convergence boundary, not a second projection of the payloads.
DECLARE @request_schema nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/dispatch-pair-demo-request.v1.schema.json","title":"Dispatch pair demo request","type":"object","additionalProperties":false,"required":["contractId","payload"],"properties":{"contractId":{"const":"dispatch-pair-demo-request.v1"},"payload":{"type":"object","additionalProperties":false,"required":["symbol"],"properties":{"symbol":{"type":"string","minLength":1},"region":{"type":"string","minLength":2}}}}}';
EXEC model.declare_contract @id=N'dispatch-pair-demo-request.v1', @schema=@request_schema;
DECLARE @settlement_schema nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/dispatch-pair-leg-settlement.v1.schema.json","title":"Dispatch pair leg settlement carrier","description":"Carrier contract for the terminal settlement of one dispatched leg and for the joined capability outcome. The payload shape is owned by the settled branch contract (governed-http-exchange-evidence.v1 or external-credential-binding-evidence.v1).","type":"object","additionalProperties":true}';
EXEC model.declare_contract @id=N'dispatch-pair-leg-settlement.v1', @schema=@settlement_schema;
-- First install scaffolds the shell. A re-run keeps the existing shell and the
-- declaration below converges it to the authored state: declare_scenario
-- upserts each scenario, and the envelope re-mint replaces cli/routing/
-- executionGraph. (scaffold_capability's REPLACE path cleans only a
-- single-scenario shell, so a multi-scenario capability must not re-scaffold.)
IF NOT EXISTS (
  SELECT 1 FROM model.capability c
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=N'dispatch-pair-demo')
  EXEC model.scaffold_capability @capability_id=N'dispatch-pair-demo', @greeting_template=N'dispatch pair demo', @on_exists=N'REPLACE';
SELECT '1_shell' AS result_set, c.capability_id, ec.capability_version_pk
FROM source.current_model cm
JOIN model.estate_capability ec ON ec.estate_model_pk=cm.estate_model_pk
JOIN model.capability c ON c.capability_pk=ec.capability_pk
WHERE cm.singleton_id=1 AND c.capability_id=N'dispatch-pair-demo';
GO

-- ============================== COPY THE REAL EQUITY CHAIN AND DECLARE THE ENVELOPE ==============================
-- Branch A is the real chain, not a lookalike: the newest installed semantics
-- of the two transformations and the two governed ports that make up the
-- primary exchange are copied verbatim into this capability's namespace, and
-- the transformation expression trees are re-normalized exactly as an authored
-- transformation would be. The envelope re-mint then carries cli, routing and
-- the graph-v2 authority; it runs before the scenario declarations so a re-run
-- against an existing version re-points that version and the declarations that
-- follow update its scenario links.
DECLARE @capability_id nvarchar(400)=N'dispatch-pair-demo';
DECLARE @dst_ns nvarchar(400)=N'sidefx:capability:dispatch-pair-demo';
DECLARE @src_ns nvarchar(400)=N'sidefx:capability:resolve-equity-market-price-evidence';
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_id=@src_ns)
 THROW 51000,N'DISPATCH_PAIR_SOURCE_NAMESPACE_MISSING',1;

DECLARE @copy TABLE (ord int identity, transformation_id nvarchar(400), semantics nvarchar(max));
INSERT @copy(transformation_id, semantics)
SELECT t.transformation_id, latest.semantics
FROM model.identity_namespace n
JOIN model.transformation t ON t.namespace_pk=n.namespace_pk
CROSS APPLY (
  SELECT TOP (1) JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics') AS semantics
  FROM model.transformation_version tv
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=tv.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE tv.transformation_pk=t.transformation_pk
  ORDER BY tv.transformation_version_pk DESC
) latest
WHERE n.namespace_id=@src_ns COLLATE Latin1_General_100_BIN2
 AND t.transformation_id IN (N'build-equity-price-binding-request',N'build-equity-price-exchange-request');
IF (SELECT COUNT(*) FROM @copy)<>2 THROW 51000,N'DISPATCH_PAIR_SOURCE_TRANSFORMATIONS_MISSING',1;

DECLARE @tid nvarchar(400), @tsem nvarchar(max), @tobj bigint, @tdef bigint, @tdig binary(32), @tpk bigint, @tver bigint;
DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR SELECT transformation_id, semantics FROM @copy ORDER BY ord;
OPEN tcur; FETCH NEXT FROM tcur INTO @tid,@tsem;
WHILE @@FETCH_STATUS=0
BEGIN
 EXEC model.put_semantic_definition 'TRANSFORMATION',@dst_ns,@tid,@tsem,@tobj OUTPUT,@tdef OUTPUT,@tdig OUTPUT;
 SET @tpk=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@tobj);
 IF @tpk IS NULL
 BEGIN
  INSERT model.transformation(namespace_pk,transformation_id,semantic_object_pk,object_kind)
   SELECT namespace_pk,@tid,@tobj,'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@tobj;
  SET @tpk=SCOPE_IDENTITY();
 END
 SET @tver=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@tdef);
 IF @tver IS NULL
 BEGIN
  INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@tpk,@tobj,@tdef,@tdig,'json-expression-tree.v1','TRANSFORMATION',@tdef,N'');
  SET @tver=SCOPE_IDENTITY();
  EXEC model.normalize_transformation_expression @tver;
 END
 FETCH NEXT FROM tcur INTO @tid,@tsem;
END
CLOSE tcur; DEALLOCATE tcur;

DECLARE @equity_ports nvarchar(max)=(
 SELECT N'['+STRING_AGG(ports.semantics,N',') WITHIN GROUP (ORDER BY ports.port_id)+N']'
 FROM (
  SELECT p.port_id, latest.semantics
  FROM model.identity_namespace n
  JOIN model.port p ON p.namespace_pk=n.namespace_pk
  CROSS APPLY (
    SELECT TOP (1) JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics') AS semantics
    FROM model.port_version pv
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=pv.semantic_object_definition_pk
    JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE pv.port_pk=p.port_pk
    ORDER BY pv.port_version_pk DESC
  ) latest
  WHERE n.namespace_id=@src_ns COLLATE Latin1_General_100_BIN2
   AND p.port_id IN (N'build-equity-price-binding-request',N'bind-equity-price-provider-credential',N'build-equity-price-exchange-request',N'observe-equity-price-exchange')
 ) ports
);
IF (SELECT COUNT(*) FROM OPENJSON(@equity_ports))<>4 THROW 51000,N'DISPATCH_PAIR_SOURCE_PORTS_MISSING',1;
IF CHARINDEX(N'sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b',@equity_ports)=0
 THROW 51000,N'DISPATCH_PAIR_SOURCE_ENDPOINT_AUTHORITY_NOT_FOUND',1;
IF CHARINDEX(N'rapidapi-x-rapidapi-key.v1',@equity_ports)=0
 THROW 51000,N'DISPATCH_PAIR_SOURCE_INJECTION_RULE_NOT_FOUND',1;
SELECT '2_copied_equity_rows' AS result_set, n.namespace_id, t.transformation_id
FROM model.identity_namespace n JOIN model.transformation t ON t.namespace_pk=n.namespace_pk
WHERE n.namespace_id=@dst_ns AND t.transformation_id IN (N'build-equity-price-binding-request',N'build-equity-price-exchange-request')
ORDER BY t.transformation_id;
SELECT '2_copied_equity_rows' AS result_set, n.namespace_id, p.port_id
FROM model.identity_namespace n JOIN model.port p ON p.namespace_pk=n.namespace_pk
WHERE n.namespace_id=@dst_ns AND p.port_id IN (N'bind-equity-price-provider-credential',N'observe-equity-price-exchange')
ORDER BY p.port_id;

-- ---- envelope re-mint: cli, routing, executionGraph ----
DECLARE @model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capPk bigint, @capSo bigint, @capSod bigint, @capVer bigint;
SELECT @capPk=c.capability_pk, @capSo=c.semantic_object_pk, @capSod=ec.semantic_object_definition_pk, @capVer=ec.capability_version_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE ec.estate_model_pk=@model AND c.capability_id=@capability_id AND n.namespace_id=N'sidefx:capabilities';
IF @capPk IS NULL THROW 51000,N'DISPATCH_PAIR_CAPABILITY_NOT_FOUND',1;
DECLARE @curEnv nvarchar(max);
SELECT @curEnv=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE d.semantic_object_definition_pk=@capSod;
IF @curEnv IS NULL THROW 51000,N'DISPATCH_PAIR_ENVELOPE_NOT_FOUND',1;

DECLARE @cli nvarchar(max)=N'{"input":{"type":"text","contract":"dispatch-pair-demo-request.v1","path":"payload.symbol","fields":{"payload.region":"US"}},"readings":[{"reading":"default","altitudes":["scenario"]},{"reading":"trace","altitudes":["scenario","mechanic","provider","physical"]}]}';
DECLARE @routing nvarchar(max)=N'['
 + N'{"transitionId":"enter-a","fromScenario":"dispatch-pair-demo","variant":"SUCCESS","toScenario":"dispatch-pair-demo-leg-a","topologyKind":"broadcast","groupId":"dispatch-pair"},'
 + N'{"transitionId":"enter-p","fromScenario":"dispatch-pair-demo","variant":"SUCCESS","toScenario":"dispatch-pair-demo-leg-c","topologyKind":"broadcast","groupId":"dispatch-pair"},'
 + N'{"transitionId":"settle-a","fromScenario":"dispatch-pair-demo-leg-a","variant":"SUCCESS","toScenario":"dispatch-pair-demo-join","topologyKind":"join","groupId":"collect-pair","joinSlotId":"a"},'
 + N'{"transitionId":"settle-c","fromScenario":"dispatch-pair-demo-leg-c","variant":"SUCCESS","toScenario":"dispatch-pair-demo-join","topologyKind":"join","groupId":"collect-pair","joinSlotId":"c"},'
 + N'{"transitionId":"fail-a","fromScenario":"dispatch-pair-demo-leg-a","variant":"SUCCESS","toScenario":"dispatch-pair-demo-join","topologyKind":"failure","groupId":"collect-pair","joinSlotId":"a"},'
 + N'{"transitionId":"fail-c","fromScenario":"dispatch-pair-demo-leg-c","variant":"SUCCESS","toScenario":"dispatch-pair-demo-join","topologyKind":"failure","groupId":"collect-pair","joinSlotId":"c"}'
 + N']';
DECLARE @execution_graph nvarchar(max)=N'{'
 + N'"graphType":"sda-semantic-execution-graph.v2",'
 + N'"requiredExecutionFeatures":["declared-concurrent-dispatch.v1"],'
 + N'"readyArbitration":"causal-activation-order.v1",'
 + N'"executionBudget":{"maximumInFlightEffects":2,"deadlineMs":30000},'
 + N'"dispatchAuthorities":[{"dispatchAuthorityId":"dispatch-pair.v1","mode":"serial","legCount":2,"maximumActiveBranches":1,"maximumInFlightEffects":2,"readyOrder":"declared-edge-order","branchFailure":"collect","ownership":"join-before-return"}],'
 + N'"edgeGroups":['
 + N'{"groupId":"dispatch-pair","kind":"broadcast","policy":"all","edgeIds":["edge:enter-a","edge:enter-p"],"dispatchAuthorityId":"dispatch-pair.v1","completionJoinGroupId":"collect-pair"},'
 + N'{"groupId":"collect-pair","kind":"join","policy":"all-required","edgeIds":["edge:settle-a","edge:settle-c"],"joinCellId":"cell:scenario:dispatch-pair-demo-join","requiredSlotIds":["a","c"]}'
 + N']}';
DECLARE @newEnv nvarchar(max)=JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(@curEnv,'$.semantics.cli',JSON_QUERY(@cli)),'$.semantics.routing',JSON_QUERY(@routing)),'$.semantics.executionGraph',JSON_QUERY(@execution_graph));
DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @digest binary(32)=HASHBYTES('SHA2_256',@bytes);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@digest,@bytes,DATALENGTH(@bytes));
DECLARE @sod bigint=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition
  WHERE semantic_object_pk=@capSo AND definition_digest=@digest);
IF @sod IS NULL
BEGIN
  INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
    VALUES(@capSo,'CAPABILITY',@digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
  SET @sod=SCOPE_IDENTITY();
  INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@model,@sod);
END
IF @sod<>@capSod
BEGIN
  -- The declaration TVFs read the capability only while its linked definition
  -- is the globally latest definition of that semantic object. Re-pointing to
  -- an older definition would make the capability invisible, so a replay that
  -- asks to return to an already-minted envelope (for example after the M2
  -- concurrent switch was installed) refuses instead of re-pointing.
  IF EXISTS (SELECT 1 FROM model.capability_version WHERE capability_pk=@capPk AND semantic_object_definition_pk=@sod)
   THROW 51000,N'DISPATCH_PAIR_ENVELOPE_VERSION_CONFLICT_REPLAY_M1_BEFORE_M2',1;
  INSERT model.capability_version(capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,object_kind,_owner_definition_pk,_canonical_pointer)
    VALUES(@capPk,@capSo,@sod,@digest,@capability_id,'CAPABILITY',@sod,N'');
  DECLARE @newVer bigint=SCOPE_IDENTITY();
  INSERT model.capability_scenario(capability_pk,capability_version_pk,scenario_pk,scenario_version_pk,_owner_definition_pk,_canonical_pointer)
    SELECT capability_pk,@newVer,scenario_pk,scenario_version_pk,@sod,_canonical_pointer
    FROM model.capability_scenario WHERE capability_version_pk=@capVer;
  INSERT model.capability_root_scenario(capability_version_pk,scenario_pk,_owner_definition_pk,_canonical_pointer)
    SELECT @newVer,scenario_pk,@sod,_canonical_pointer
    FROM model.capability_root_scenario WHERE capability_version_pk=@capVer;
  UPDATE model.estate_capability SET capability_version_pk=@newVer, semantic_object_definition_pk=@sod
  WHERE estate_model_pk=@model AND capability_pk=@capPk;
END
SELECT '3_envelope_declared' AS result_set, @capability_id AS capability_id,
  JSON_VALUE(@execution_graph,'$.dispatchAuthorities[0].mode') AS mode,
  JSON_VALUE(@execution_graph,'$.dispatchAuthorities[0].maximumActiveBranches') AS maximum_active_branches;
GO

-- ============================== SCENARIOS ==============================
-- Root: carries the caller's live equity request unchanged into both branches.
-- Leg A: the real copied chain, ending on the governed exchange evidence.
-- Leg C: the local fixture chain, through the same two effect mechanics.
-- Join: the declared all-required convergence boundary; the scheduler hands it
-- the named settlement array in requiredSlotIds order.
DECLARE @capability_id nvarchar(400)=N'dispatch-pair-demo';

EXEC model.declare_scenario
  @capability_id=@capability_id,
  @scenario=N'{"scenarioId":"dispatch-pair-demo","name":"Dispatch two declared independent legs","inputId":"dispatch-pair-demo-request","inputContract":"dispatch-pair-demo-request.v1","eventId":"dispatch-pair-demo-requested","eventAuthority":"dispatch-pair-demo.v1","outcomeId":"dispatch-pair-demo-dispatched","outcomeContract":"dispatch-pair-demo-request.v1","given":"the caller supplies one canonical equity price request","when":"the declared broadcast group admits its independent legs","then":"both legs are dispatched and their settlements converge","root":true,"terminal":false,"variants":["SUCCESS"]}',
  @operations=N'[{"operationId":"dispatch-pair-demo.root.1","kind":"invoke-port","portId":"dispatch-pair-demo-root-pass"}]',
  @port_bindings=N'[{"portId":"dispatch-pair-demo-root-pass","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"expression":{"op":"path","from":"input","path":""}}}]';

-- The copied equity ports are re-read here (batch-local) so the leg-a
-- declaration always binds the newest installed semantics.
DECLARE @src_ns nvarchar(400)=N'sidefx:capability:resolve-equity-market-price-evidence';
DECLARE @leg_a_ports nvarchar(max)=(
 SELECT N'['+STRING_AGG(ports.semantics,N',') WITHIN GROUP (ORDER BY ports.port_id)+N']'
 FROM (
  SELECT p.port_id, latest.semantics
  FROM model.identity_namespace n
  JOIN model.port p ON p.namespace_pk=n.namespace_pk
  CROSS APPLY (
    SELECT TOP (1) JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics') AS semantics
    FROM model.port_version pv
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=pv.semantic_object_definition_pk
    JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE pv.port_pk=p.port_pk
    ORDER BY pv.port_version_pk DESC
  ) latest
  WHERE n.namespace_id=@src_ns COLLATE Latin1_General_100_BIN2
   AND p.port_id IN (N'build-equity-price-binding-request',N'bind-equity-price-provider-credential',N'build-equity-price-exchange-request',N'observe-equity-price-exchange')
 ) ports
);
EXEC model.declare_scenario
  @capability_id=@capability_id,
  @scenario=N'{"scenarioId":"dispatch-pair-demo-leg-a","name":"Resolve the real equity price through the governed provider chain","inputId":"dispatch-pair-demo-leg-a-request","inputContract":"dispatch-pair-demo-request.v1","eventId":"dispatch-pair-demo-leg-a-requested","eventAuthority":"dispatch-pair-demo-leg-a.v1","outcomeId":"dispatch-pair-demo-leg-a-settlement","outcomeContract":"dispatch-pair-leg-settlement.v1","given":"the broadcast group admitted the equity leg","when":"the real equity provider chain executes its declared operations","then":"the provider exchange settlement is collected","terminal":false,"variants":["SUCCESS"]}',
  @operations=N'[{"operationId":"dispatch-pair-demo.leg-a.1","kind":"invoke-port","portId":"build-equity-price-binding-request"},{"operationId":"dispatch-pair-demo.leg-a.2","kind":"invoke-port","portId":"bind-equity-price-provider-credential"},{"operationId":"dispatch-pair-demo.leg-a.3","kind":"invoke-port","portId":"build-equity-price-exchange-request"},{"operationId":"dispatch-pair-demo.leg-a.4","kind":"invoke-port","portId":"observe-equity-price-exchange"}]',
  @port_bindings=@leg_a_ports;

DECLARE @fixture_endpoint_authority nvarchar(max)=N'{"host":"localhost","method":"GET","pathPrefix":"/delay?","providerId":"dispatch-pair-fixture/local","bindingId":"dispatch-pair-fixture-delay.v1","credentialInjectionRuleId":"rapidapi-x-rapidapi-key.v1","effectScope":"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"}';
DECLARE @fixture_digest nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),(@fixture_endpoint_authority) COLLATE Latin1_General_100_BIN2_UTF8))),2));
DECLARE @fixture_rule nvarchar(400)=N'rapidapi-x-rapidapi-key.v1';
DECLARE @fixture_header nvarchar(400)=N'X-RapidAPI-Key';
DECLARE @fixture_scope nvarchar(400)=N'ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY';
DECLARE @fixture_invocation nvarchar(400)=N'dispatch-pair-demo.v1';
DECLARE @leg_c_ports nvarchar(max)=
 N'['
 + N'{"portId":"dispatch-pair-demo-build-c-binding-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"expression":{"op":"object","fields":{'
 + N'"credentialReference":{"op":"literal","value":"RAPID_API_KEY"},'
 + N'"invocationIdentity":{"op":"literal","value":"'+@fixture_invocation+N'"},'
 + N'"requestingCapabilityId":{"op":"literal","value":"'+@capability_id+N'"},'
 + N'"endpointAuthorityDigest":{"op":"literal","value":"'+@fixture_digest+N'"},'
 + N'"effectScope":{"op":"literal","value":"'+@fixture_scope+N'"},'
 + N'"effectLineage":{"op":"array","items":[]}'
 + N'}}}},'
 + N'{"portId":"dispatch-pair-demo-bind-c-credential","platformCapabilityId":"sda-external-credential-reference-binding-port.v1","configuration":{"credentialAuthorities":[{'
 + N'"effectScopes":["'+@fixture_scope+'"],'
 + N'"endpointAuthorityDigests":["'+@fixture_digest+'"],'
 + N'"injectionRule":{"headerName":"'+@fixture_header+'","id":"'+@fixture_rule+'"},'
 + N'"lifetimeMilliseconds":15000,'
 + N'"referenceName":"RAPID_API_KEY",'
 + N'"requestingCapabilityIds":["'+@capability_id+'"],'
 + N'"source":"vault",'
 + N'"storeLocator":"%LOCALAPPDATA%\\sfx\\vault"'
 + N'}]}},'
 + N'{"portId":"dispatch-pair-demo-build-c-exchange-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"expression":{"op":"object","fields":{'
 + N'"requestUrl":{"op":"literal","value":"https://localhost:8788/delay?ms=400"},'
 + N'"method":{"op":"literal","value":"GET"},'
 + N'"safeHeaders":{"op":"object","fields":{}},'
 + N'"allowedResponseHeaders":{"op":"array","items":[{"op":"literal","value":"content-type"}]},'
 + N'"timeoutMilliseconds":{"op":"literal","value":15000},'
 + N'"maxResponseBytes":{"op":"literal","value":262144},'
 + N'"requestBodyText":{"op":"literal","value":""},'
 + N'"invocationIdentity":{"op":"literal","value":"'+@fixture_invocation+'"},'
 + N'"endpointAuthorityDigest":{"op":"literal","value":"'+@fixture_digest+'"},'
 + N'"credentialInjectionRuleId":{"op":"literal","value":"'+@fixture_rule+'"},'
 + N'"opaqueCredentialBinding":{"op":"object","fields":{"bindingId":{"op":"path","from":"input","path":"opaqueBindingId"},"credentialInjectionRuleId":{"op":"literal","value":"'+@fixture_rule+'"}}},'
 + N'"effectLineage":{"op":"array","items":[]}'
 + N'}}}},'
 + N'{"portId":"dispatch-pair-demo-observe-c-exchange","platformCapabilityId":"sda-governed-http-exchange-port.v1","configuration":{'
 + N'"endpointAuthorities":[{"endpointAuthorityDigest":"'+@fixture_digest+'","urlPrefixes":["https://localhost:8788/delay?"],"methods":["GET"],"allowedRequestHeaders":[],"allowedResponseHeaders":["content-type"]}],'
 + N'"credentialInjectionRules":[{"id":"'+@fixture_rule+'","headerName":"'+@fixture_header+'"}]'
 + N'}}'
 + N']';

EXEC model.declare_scenario
  @capability_id=@capability_id,
  @scenario=N'{"scenarioId":"dispatch-pair-demo-leg-c","name":"Exchange with the local delay fixture through the governed HTTP port","inputId":"dispatch-pair-demo-leg-c-request","inputContract":"dispatch-pair-demo-request.v1","eventId":"dispatch-pair-demo-leg-c-requested","eventAuthority":"dispatch-pair-demo-leg-c.v1","outcomeId":"dispatch-pair-demo-leg-c-settlement","outcomeContract":"dispatch-pair-leg-settlement.v1","given":"the broadcast group admitted the fixture leg","when":"the governed HTTPS exchange reaches the localhost delay fixture","then":"the fixture exchange settlement is collected","terminal":false,"variants":["SUCCESS"]}',
  @operations=N'[{"operationId":"dispatch-pair-demo.leg-c.1","kind":"invoke-port","portId":"dispatch-pair-demo-build-c-binding-request"},{"operationId":"dispatch-pair-demo.leg-c.2","kind":"invoke-port","portId":"dispatch-pair-demo-bind-c-credential"},{"operationId":"dispatch-pair-demo.leg-c.3","kind":"invoke-port","portId":"dispatch-pair-demo-build-c-exchange-request"},{"operationId":"dispatch-pair-demo.leg-c.4","kind":"invoke-port","portId":"dispatch-pair-demo-observe-c-exchange"}]',
  @port_bindings=@leg_c_ports;

EXEC model.declare_scenario
  @capability_id=@capability_id,
  @scenario=N'{"scenarioId":"dispatch-pair-demo-join","name":"Collect the declared branch settlements","inputId":"dispatch-pair-demo-join-request","inputContract":"dispatch-pair-leg-settlement.v1","eventId":"dispatch-pair-demo-joined","eventAuthority":"dispatch-pair-demo-join.v1","outcomeId":"dispatch-pair-demo-outcome","outcomeContract":"dispatch-pair-leg-settlement.v1","given":"every required branch slot has one terminal settlement","when":"the declared all-required join admits the continuation","then":"both settlements are returned as the capability outcome","root":false,"terminal":true}',
  @operations=N'[{"operationId":"dispatch-pair-demo.join.1","kind":"invoke-port","portId":"dispatch-pair-demo-join-collect"}]',
  @port_bindings=N'[{"portId":"dispatch-pair-demo-join-collect","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"expression":{"op":"object","fields":{"contractId":{"op":"literal","value":"dispatch-pair-leg-settlement.v1"},"settlements":{"op":"path","from":"input","path":""}}}}}]';

EXEC model.declare_capability_feature
  @capability_id=N'dispatch-pair-demo',
  @feature_text=N'@capability:dispatch-pair-demo
@root-scenario:dispatch-pair-demo
Feature: Dispatch two declared independent legs and collect their settlements

  @scenario:dispatch-pair-demo
  @input:dispatch-pair-demo-request
  @input-contract:dispatch-pair-demo-request.v1
  @event:dispatch-pair-demo-requested
  @event-authority:dispatch-pair-demo.v1
  @outcome:dispatch-pair-demo-dispatched
  @outcome-contract:dispatch-pair-demo-request.v1
  Scenario: Dispatch the declared legs
    Given the caller supplies one canonical equity price request
    When the declared broadcast group admits its independent legs
    Then both legs are dispatched and their settlements converge

  @scenario:dispatch-pair-demo-leg-a
  @input:dispatch-pair-demo-leg-a-request
  @input-contract:dispatch-pair-demo-request.v1
  @event:dispatch-pair-demo-leg-a-requested
  @event-authority:dispatch-pair-demo-leg-a.v1
  @outcome:dispatch-pair-demo-leg-a-settlement
  @outcome-contract:dispatch-pair-leg-settlement.v1
  Scenario: Resolve the real equity price
    Given the broadcast group admitted the equity leg
    When the real equity provider chain executes its declared operations
    Then the provider exchange settlement is collected

  @scenario:dispatch-pair-demo-leg-c
  @input:dispatch-pair-demo-leg-c-request
  @input-contract:dispatch-pair-demo-request.v1
  @event:dispatch-pair-demo-leg-c-requested
  @event-authority:dispatch-pair-demo-leg-c.v1
  @outcome:dispatch-pair-demo-leg-c-settlement
  @outcome-contract:dispatch-pair-leg-settlement.v1
  Scenario: Exchange with the local delay fixture
    Given the broadcast group admitted the fixture leg
    When the governed HTTPS exchange reaches the localhost delay fixture
    Then the fixture exchange settlement is collected

  @scenario:dispatch-pair-demo-join
  @input:dispatch-pair-demo-join-request
  @input-contract:dispatch-pair-leg-settlement.v1
  @event:dispatch-pair-demo-joined
  @event-authority:dispatch-pair-demo-join.v1
  @outcome:dispatch-pair-demo-outcome
  @outcome-contract:dispatch-pair-leg-settlement.v1
  @outcome-terminal
  Scenario: Collect the declared branch settlements
    Given every required branch slot has one terminal settlement
    When the declared all-required join admits the continuation
    Then both settlements are returned as the capability outcome
';
GO

-- ============================== VERIFICATION ==============================
DECLARE @capability_id nvarchar(400)=N'dispatch-pair-demo';
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(@capability_id,1,NULL));

SELECT '4_scenarios' AS result_set, s.scenario_id, CONVERT(bit,so.terminal) AS terminal,
  si.input_id, ct_in.contract_id AS input_contract, cto.contract_id AS outcome_contract,
  ISNULL((SELECT STRING_AGG(ov.variant_id,N',') FROM model.outcome_variant ov WHERE ov.scenario_version_pk=sv.scenario_version_pk),N'(none)') AS variants
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=@capability_id
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.contract_version cvi ON cvi.contract_version_pk=si.input_contract_version_pk
LEFT JOIN model.contract ct_in ON ct_in.contract_pk=cvi.contract_pk
LEFT JOIN model.scenario_outcome so ON so.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.contract_version cvo ON cvo.contract_version_pk=soc.contract_version_pk
LEFT JOIN model.contract cto ON cto.contract_pk=cvo.contract_pk
WHERE ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
ORDER BY s.scenario_id;

SELECT '5_declared_transitions' AS result_set, transition.ordinal,
  JSON_VALUE(transition.transition_json,'$.transitionId') AS transition_id,
  JSON_VALUE(transition.transition_json,'$.topologyKind') AS topology_kind,
  JSON_VALUE(transition.transition_json,'$.edgeGroupId') AS group_id,
  JSON_VALUE(transition.transition_json,'$.joinSlotId') AS join_slot_id,
  JSON_VALUE(transition.transition_json,'$.to.scenarioId') AS to_scenario
FROM analysis.capability_declared_transitions(@capability_id) transition
ORDER BY transition.ordinal;

SELECT '6_graph_source_v2' AS result_set,
  JSON_VALUE(@graph,'$.graphType') AS graph_type,
  JSON_VALUE(@graph,'$.requiredExecutionFeatures[0]') AS required_execution_feature,
  JSON_VALUE(@graph,'$.readyArbitration') AS ready_arbitration,
  JSON_VALUE(@graph,'$.executionBudget.maximumInFlightEffects') AS budget_effects,
  JSON_VALUE(@graph,'$.executionBudget.deadlineMs') AS deadline_ms,
  JSON_VALUE(@graph,'$.dispatchAuthorities[0].dispatchAuthorityId') AS dispatch_authority_id,
  JSON_VALUE(@graph,'$.dispatchAuthorities[0].mode') AS mode,
  JSON_VALUE(@graph,'$.dispatchAuthorities[0].legCount') AS leg_count,
  JSON_VALUE(@graph,'$.dispatchAuthorities[0].maximumActiveBranches') AS maximum_active_branches,
  JSON_QUERY(@graph,'$.dispatchAuthorities[0]') AS dispatch_authority,
  JSON_QUERY(@graph,'$.edgeGroups') AS edge_groups;

SELECT '7_leg_a_operations' AS result_set, JSON_QUERY(j.value,'$.operations') AS operations
FROM analysis.capability_graph_source(@capability_id,1,NULL) g
CROSS APPLY OPENJSON(g.graph_source,'$.executionAuthorities') a
CROSS APPLY OPENJSON(CONVERT(nvarchar(max), JSON_QUERY(a.value,'$.operations'))) j
WHERE JSON_VALUE(a.value,'$.owningScenarioId')=N'dispatch-pair-demo-leg-a'
  AND JSON_VALUE(j.value,'$.portId') LIKE N'%equity-price%';

SELECT '8_assertions' AS result_set,
  CONVERT(bit,CASE WHEN JSON_VALUE(@graph,'$.graphType')=N'sda-semantic-execution-graph.v2' THEN 1 ELSE 0 END) AS graph_v2,
  CONVERT(bit,CASE WHEN (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.transitions'))) = 6 THEN 1 ELSE 0 END) AS six_routes,
  CONVERT(bit,CASE WHEN JSON_VALUE(@graph,'$.dispatchAuthorities[0].mode')=N'serial'
    AND JSON_VALUE(@graph,'$.dispatchAuthorities[0].maximumActiveBranches')=1
    AND JSON_VALUE(@graph,'$.dispatchAuthorities[0].legCount')=2 THEN 1 ELSE 0 END) AS serial_bounds,
  CONVERT(bit,CASE WHEN EXISTS (
     SELECT 1 FROM OPENJSON(JSON_QUERY(@graph,'$.edgeGroups')) g
     WHERE JSON_VALUE(g.value,'$.groupId')=N'dispatch-pair' AND JSON_VALUE(g.value,'$.kind')=N'broadcast'
      AND JSON_VALUE(g.value,'$.dispatchAuthorityId')=N'dispatch-pair.v1'
      AND JSON_VALUE(g.value,'$.completionJoinGroupId')=N'collect-pair'
      AND (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.value,'$.edgeIds'))) = 2) THEN 1 ELSE 0 END) AS broadcast_group,
  CONVERT(bit,CASE WHEN EXISTS (
     SELECT 1 FROM OPENJSON(JSON_QUERY(@graph,'$.edgeGroups')) g
     WHERE JSON_VALUE(g.value,'$.groupId')=N'collect-pair' AND JSON_VALUE(g.value,'$.kind')=N'join'
      AND JSON_VALUE(g.value,'$.policy')=N'all-required'
      AND JSON_VALUE(g.value,'$.joinCellId')=N'cell:scenario:dispatch-pair-demo-join'
      AND (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(g.value,'$.requiredSlotIds'))) = 2) THEN 1 ELSE 0 END) AS join_group,
  CONVERT(bit,CASE WHEN EXISTS (
     SELECT 1 FROM analysis.capability_graph_source(@capability_id,1,NULL) g
     CROSS APPLY OPENJSON(g.graph_source,'$.executionAuthorities') a
     CROSS APPLY OPENJSON(CONVERT(nvarchar(max), JSON_QUERY(a.value,'$.operations'))) j
     WHERE JSON_VALUE(a.value,'$.owningScenarioId')=N'dispatch-pair-demo-leg-a'
      AND JSON_VALUE(j.value,'$.portId')=N'observe-equity-price-exchange') THEN 1 ELSE 0 END) AS leg_a_real_chain;

IF JSON_VALUE(@graph,'$.graphType')<>N'sda-semantic-execution-graph.v2' THROW 51000,N'DISPATCH_PAIR_GRAPH_NOT_V2',1;
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph,'$.transitions')))<>6 THROW 51000,N'DISPATCH_PAIR_ROUTE_COUNT_NOT_SIX',1;
IF JSON_VALUE(@graph,'$.dispatchAuthorities[0].mode')<>N'serial' THROW 51000,N'DISPATCH_PAIR_MODE_NOT_SERIAL',1;
IF (SELECT COUNT(*) FROM analysis.capability_declared_transitions(@capability_id))<>6 THROW 51000,N'DISPATCH_PAIR_DECLARED_TRANSITIONS_NOT_SIX',1;

COMMIT TRANSACTION;
-- Installed after the rollback dry run and the from-transaction preflight
-- (DISPOSITION completed). The live C# kernel evidence is under
-- demo/dispatch-pair/evidence/serial.*. M2 (switch-dispatch-pair-demo-concurrent.sql)
-- re-mints only the dispatch authority on this capability's envelope.
-- Reversal: a migration that removes the capability's rows restores the
-- pre-unit estate.
