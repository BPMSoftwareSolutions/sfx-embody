-- extend-dispatch-pair-demo-leg-a-equity-fallback.sql
--
-- Gives branch A of dispatch-pair-demo the installed, live-proven equity
-- fallback chain that resolve-equity-market-price-evidence already runs:
--
--   primary   rapidapi/davethebeast/yahoo-finance166 /api/stock/get-price
--             (copied by declare-dispatch-pair-demo.sql)
--   fallback  rapidapi/yahoo-finance-real-time1 /market/get-quotes
--             (declared by add-equity-price-fallback-route.sql)
--   fallback  rapidapi/yahoo-finance15 /api/v1/markets/stock/quotes
--             (installed by install-finance15-equity-fallback.sql and guarded
--             by reject-empty-equity-fallback-quotes.sql)
--
-- Branch A today stops after the primary observe exchange, so a primary 429
-- settles the leg with the raw exchange evidence. This change copies the seven
-- transformations and eleven ports that make up the normalize + fallback route
-- rows into the capability's own namespace and re-declares only the leg-a
-- scenario with the same fifteen operations the source capability executes,
-- ending on select-finance15-price-route. The kernel then resolves branch A
-- like the source capability: primary, then real-time1, then finance15.
--
-- Copy instead of compose, for the same reason as M1: no projected binding
-- exists for resolve-equity-market-price-evidence and a nested invoke-scenario
-- would run the whole equity root as one opaque child branch. The copied rows
-- are content-addressed; nothing about the source capability changes. No row
-- of branch C, the join, the root scenario, the routing, the dispatch authority
-- or the capability envelope is authored here.
--
-- The copy is idempotent: put_semantic_definition finds the same definition
-- digest for rows already present. A replay against an already-extended leg-a
-- re-declares the same authority and changes no graph-source byte.
--
-- Default: ROLLBACK after the dry run. The install is the same file with the
-- final token replaced by COMMIT (the .commit.sql copy).
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

-- ============================== BEFORE ==============================
-- Five capabilities: the pair plus the four comparison capabilities the switch
-- migrations also pin. Only dispatch-pair-demo may move.
IF OBJECT_ID('tempdb..#before_graphs') IS NOT NULL DROP TABLE #before_graphs;
CREATE TABLE #before_graphs (capability_id nvarchar(400), graph_digest varchar(80));
IF OBJECT_ID('tempdb..#before_pair') IS NOT NULL DROP TABLE #before_pair;
CREATE TABLE #before_pair (
 graph_source nvarchar(max), mode nvarchar(100), maximum_active_branches nvarchar(20),
 dispatch_authorities nvarchar(max), transitions nvarchar(max), edge_groups nvarchar(max),
 execution_budget nvarchar(max), ready_arbitration nvarchar(max), required_execution_features nvarchar(max),
 scenarios nvarchar(max), scenario_outcomes nvarchar(max), contract_authorities nvarchar(max),
 leg_a_ops nvarchar(max), leg_a_op_count int, leg_c_authority nvarchar(max),
 join_authority nvarchar(max), root_authority nvarchar(max), envelope_digest varchar(80),
 transformation_count int, port_count int);
DECLARE @caps TABLE (ord int identity, capability_id nvarchar(400));
INSERT @caps(capability_id) VALUES
 (N'dispatch-pair-demo'),(N'say-hello-world'),(N'resolve-equity-market-price-evidence'),
 (N'project-model-provider-protocol'),(N'route-two-child-proof');
DECLARE @cap nvarchar(400), @v nvarchar(max);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id FROM @caps ORDER BY ord;
OPEN cur; FETCH NEXT FROM cur INTO @cap;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @v=graph_source FROM analysis.capability_graph_source(@cap,0,N'sidefx:capabilities');
 INSERT #before_graphs VALUES(@cap,'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@v)),2)));
 FETCH NEXT FROM cur INTO @cap;
END
CLOSE cur; DEALLOCATE cur;
DECLARE @pair nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'dispatch-pair-demo',0,N'sidefx:capabilities'));
DECLARE @env_digest varchar(80);
SELECT @env_digest='sha256:'+LOWER(CONVERT(varchar(64),d.definition_digest,2))
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=N'dispatch-pair-demo'
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
WHERE ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @dst_ns nvarchar(400)=N'sidefx:capability:dispatch-pair-demo';
DECLARE @transformation_count int=(SELECT COUNT(*) FROM model.identity_namespace n JOIN model.transformation t ON t.namespace_pk=n.namespace_pk WHERE n.namespace_id=@dst_ns);
DECLARE @port_count int=(SELECT COUNT(*) FROM model.identity_namespace n JOIN model.port p ON p.namespace_pk=n.namespace_pk WHERE n.namespace_id=@dst_ns);
INSERT #before_pair
SELECT @pair,
 JSON_VALUE(@pair,N'$.dispatchAuthorities[0].mode'),
 JSON_VALUE(@pair,N'$.dispatchAuthorities[0].maximumActiveBranches'),
 JSON_QUERY(@pair,N'$.dispatchAuthorities'),
 JSON_QUERY(@pair,N'$.transitions'),
 JSON_QUERY(@pair,N'$.edgeGroups'),
 JSON_QUERY(@pair,N'$.executionBudget'),
 JSON_VALUE(@pair,N'$.readyArbitration'),
 JSON_QUERY(@pair,N'$.requiredExecutionFeatures'),
 JSON_QUERY(@pair,N'$.scenarios'),
 JSON_QUERY(@pair,N'$.scenarioOutcomes'),
 JSON_QUERY(@pair,N'$.contractAuthorities'),
 (SELECT a.value FROM OPENJSON(@pair,N'$.executionAuthorities') a
  WHERE JSON_VALUE(a.value,N'$.owningScenarioId')=N'dispatch-pair-demo-leg-a'),
 (SELECT COUNT(*) FROM OPENJSON(
   (SELECT a.value FROM OPENJSON(@pair,N'$.executionAuthorities') a
    WHERE JSON_VALUE(a.value,N'$.owningScenarioId')=N'dispatch-pair-demo-leg-a'),N'$.operations')),
 (SELECT a.value FROM OPENJSON(@pair,N'$.executionAuthorities') a
  WHERE JSON_VALUE(a.value,N'$.owningScenarioId')=N'dispatch-pair-demo-leg-c'),
 (SELECT a.value FROM OPENJSON(@pair,N'$.executionAuthorities') a
  WHERE JSON_VALUE(a.value,N'$.owningScenarioId')=N'dispatch-pair-demo-join'),
 (SELECT a.value FROM OPENJSON(@pair,N'$.executionAuthorities') a
  WHERE JSON_VALUE(a.value,N'$.owningScenarioId')=N'dispatch-pair-demo'),
 @env_digest,@transformation_count,@port_count;
IF (SELECT COUNT(*) FROM #before_pair)<>1 THROW 51000,N'PAIR_BEFORE_NOT_CAPTURED',1;
IF (SELECT COUNT(*) FROM #before_graphs)<>5 THROW 51000,N'PAIR_BEFORE_GRAPHS_INCOMPLETE',1;
SELECT '1_before' AS result_set, capability_id, graph_digest FROM #before_graphs ORDER BY capability_id;
SELECT '1_pair_before' AS result_set,
 (SELECT mode FROM #before_pair) AS mode,
 (SELECT maximum_active_branches FROM #before_pair) AS maximum_active_branches,
 (SELECT leg_a_op_count FROM #before_pair) AS leg_a_operations,
 (SELECT transformation_count FROM #before_pair) AS transformations_in_namespace,
 (SELECT port_count FROM #before_pair) AS ports_in_namespace,
 (SELECT envelope_digest FROM #before_pair) AS envelope_digest;
GO

-- ============================== COPY THE FALLBACK ROUTE ROWS ==============================
-- The seven transformations the fallback ports reference, latest installed
-- semantics copied content-for-content into the destination namespace.
DECLARE @capability_id nvarchar(400)=N'dispatch-pair-demo';
DECLARE @dst_ns nvarchar(400)=N'sidefx:capability:dispatch-pair-demo';
DECLARE @src_capability nvarchar(400)=N'resolve-equity-market-price-evidence';
DECLARE @src_ns nvarchar(400)=N'sidefx:capability:resolve-equity-market-price-evidence';
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_id=@src_ns)
 THROW 51000,N'DISPATCH_PAIR_FALLBACK_SOURCE_NAMESPACE_MISSING',1;

IF OBJECT_ID('tempdb..#copied_transformations') IS NOT NULL DROP TABLE #copied_transformations;
CREATE TABLE #copied_transformations (transformation_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
DECLARE @needed TABLE (transformation_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @needed VALUES
 (N'normalize-equity-price-evidence'),
 (N'build-fallback-price-binding-request'),
 (N'build-fallback-price-exchange-request'),
 (N'select-equity-price-route'),
 (N'build-finance15-price-binding-request'),
 (N'build-finance15-price-exchange-request'),
 (N'select-finance15-price-route');
DECLARE @copy TABLE (ord int identity, transformation_id nvarchar(400), semantics nvarchar(max));
INSERT @copy(transformation_id, semantics)
SELECT t.transformation_id, latest.semantics
FROM model.identity_namespace n
JOIN model.transformation t ON t.namespace_pk=n.namespace_pk
JOIN @needed need ON need.transformation_id=t.transformation_id
CROSS APPLY (
 SELECT TOP (1) JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics') AS semantics
 FROM model.transformation_version tv
 JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=tv.semantic_object_definition_pk
 JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
 WHERE tv.transformation_pk=t.transformation_pk
 ORDER BY tv.transformation_version_pk DESC
) latest
WHERE n.namespace_id=@src_ns COLLATE Latin1_General_100_BIN2
ORDER BY t.transformation_id;
IF (SELECT COUNT(*) FROM @copy)<>7 THROW 51000,N'DISPATCH_PAIR_FALLBACK_TRANSFORMATIONS_MISSING',1;

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
 INSERT #copied_transformations VALUES(@tid);
 FETCH NEXT FROM tcur INTO @tid,@tsem;
END
CLOSE tcur; DEALLOCATE tcur;

-- The fifteen operations' ports, latest installed semantics in the source
-- namespace. declare_scenario below re-declares all fifteen in the destination
-- namespace; the four already copied by M1 find their same definition digest.
DECLARE @leg_a_port_ids TABLE (port_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @leg_a_port_ids VALUES
 (N'build-equity-price-binding-request'),
 (N'bind-equity-price-provider-credential'),
 (N'build-equity-price-exchange-request'),
 (N'observe-equity-price-exchange'),
 (N'normalize-equity-price-evidence'),
 (N'build-fallback-price-binding-request'),
 (N'bind-fallback-price-provider-credential'),
 (N'build-fallback-price-exchange-request'),
 (N'observe-fallback-price-exchange'),
 (N'select-equity-price-route'),
 (N'build-finance15-price-binding-request'),
 (N'bind-finance15-price-provider-credential'),
 (N'build-finance15-price-exchange-request'),
 (N'observe-finance15-price-exchange'),
 (N'select-finance15-price-route');
DECLARE @leg_a_ports nvarchar(max)=(
 SELECT N'['+STRING_AGG(ports.semantics,N',') WITHIN GROUP (ORDER BY ports.port_id)+N']'
 FROM (
  SELECT p.port_id, latest.semantics
  FROM model.identity_namespace n
  JOIN model.port p ON p.namespace_pk=n.namespace_pk
  JOIN @leg_a_port_ids need ON need.port_id=p.port_id
  CROSS APPLY (
    SELECT TOP (1) JSON_QUERY(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics') AS semantics
    FROM model.port_version pv
    JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=pv.semantic_object_definition_pk
    JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE pv.port_pk=p.port_pk
    ORDER BY pv.port_version_pk DESC
  ) latest
  WHERE n.namespace_id=@src_ns COLLATE Latin1_General_100_BIN2
 ) ports
);
IF (SELECT COUNT(*) FROM OPENJSON(@leg_a_ports))<>15 THROW 51000,N'DISPATCH_PAIR_FALLBACK_PORTS_MISSING',1;
IF CHARINDEX(N'sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b',@leg_a_ports)=0
 THROW 51000,N'DISPATCH_PAIR_PRIMARY_ENDPOINT_AUTHORITY_NOT_FOUND',1;
IF CHARINDEX(N'sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769',@leg_a_ports)=0
 THROW 51000,N'DISPATCH_PAIR_REALTIME1_ENDPOINT_AUTHORITY_NOT_FOUND',1;
IF CHARINDEX(N'sha256:da33b08b71343c905354d0c1e07ae3ef6a2a97cc7eef9e581bdc3c13c1e6f368',@leg_a_ports)=0
 THROW 51000,N'DISPATCH_PAIR_FINANCE15_ENDPOINT_AUTHORITY_NOT_FOUND',1;
IF CHARINDEX(N'rapidapi-x-rapidapi-key.v1',@leg_a_ports)=0
 THROW 51000,N'DISPATCH_PAIR_INJECTION_RULE_NOT_FOUND',1;

-- The source capability's installed fifteen-operation authority, read from the
-- event's bound authority version. Port ids are asserted in operation order so
-- the copied chain is the proven chain and not a re-composition.
DECLARE @src_ops nvarchar(max);
SELECT @src_ops=JSON_QUERY(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.authority.operations')
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=@src_capability
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk AND s.scenario_id=@src_capability
JOIN model.scenario_event ev ON ev.scenario_version_pk=cs.scenario_version_pk AND ev.event_id=N'equity-market-price-evidence-requested'
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=ev.execution_authority_version_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=eav.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE ec.estate_model_pk=@estate;
IF @src_ops IS NULL OR ISJSON(@src_ops)<>1 THROW 51000,N'DISPATCH_PAIR_SOURCE_OPERATIONS_MISSING',1;
IF (SELECT COUNT(*) FROM OPENJSON(@src_ops))<>15 THROW 51000,N'DISPATCH_PAIR_SOURCE_OPERATIONS_NOT_FIFTEEN',1;
DECLARE @expected_sequence nvarchar(max)=N'build-equity-price-binding-request,bind-equity-price-provider-credential,build-equity-price-exchange-request,observe-equity-price-exchange,normalize-equity-price-evidence,build-fallback-price-binding-request,bind-fallback-price-provider-credential,build-fallback-price-exchange-request,observe-fallback-price-exchange,select-equity-price-route,build-finance15-price-binding-request,bind-finance15-price-provider-credential,build-finance15-price-exchange-request,observe-finance15-price-exchange,select-finance15-price-route';
DECLARE @src_sequence nvarchar(max)=(
 SELECT STRING_AGG(JSON_VALUE(o.value,'$.portId'),N',') WITHIN GROUP (ORDER BY CONVERT(int,o.[key]))
 FROM OPENJSON(@src_ops) o);
IF @src_sequence<>@expected_sequence THROW 51000,N'DISPATCH_PAIR_SOURCE_CHAIN_DIVERGED',1;

-- Re-author only the operation ids: branch A keeps its own leg-a identity while
-- every other operation field (kind, portId, outcomeVariants) is carried.
DECLARE @leg_a_ops nvarchar(max)=N'['+ISNULL((
 SELECT STRING_AGG(CONVERT(nvarchar(max),JSON_MODIFY(o.value,'$.operationId',
   N'dispatch-pair-demo.leg-a.'+CONVERT(nvarchar(10),CONVERT(int,o.[key])+1))),N',')
  WITHIN GROUP (ORDER BY CONVERT(int,o.[key]))
 FROM OPENJSON(@src_ops) o),N'')+N']';
IF ISJSON(@leg_a_ops)<>1 OR (SELECT COUNT(*) FROM OPENJSON(@leg_a_ops))<>15
 THROW 51000,N'DISPATCH_PAIR_LEG_A_OPERATIONS_INVALID',1;

EXEC model.declare_scenario
 @capability_id=@capability_id,
 @scenario=N'{"scenarioId":"dispatch-pair-demo-leg-a","name":"Resolve the real equity price through the governed provider chain","inputId":"dispatch-pair-demo-leg-a-request","inputContract":"dispatch-pair-demo-request.v1","eventId":"dispatch-pair-demo-leg-a-requested","eventAuthority":"dispatch-pair-demo-leg-a.v1","outcomeId":"dispatch-pair-demo-leg-a-settlement","outcomeContract":"dispatch-pair-leg-settlement.v1","given":"the broadcast group admitted the equity leg","when":"the real equity provider chain executes its declared operations","then":"the provider exchange settlement is collected","terminal":false,"variants":["SUCCESS"]}',
 @operations=@leg_a_ops,
 @port_bindings=@leg_a_ports;

SELECT '2_copied_transformations' AS result_set, n.namespace_id, t.transformation_id
FROM model.identity_namespace n
JOIN model.transformation t ON t.namespace_pk=n.namespace_pk
JOIN #copied_transformations c ON c.transformation_id=t.transformation_id
WHERE n.namespace_id=@dst_ns
ORDER BY t.transformation_id;
SELECT '2_copied_ports' AS result_set, n.namespace_id, p.port_id
FROM model.identity_namespace n
JOIN model.port p ON p.namespace_pk=n.namespace_pk
WHERE n.namespace_id=@dst_ns
 AND p.port_id IN (N'normalize-equity-price-evidence',N'build-fallback-price-binding-request',N'bind-fallback-price-provider-credential',N'build-fallback-price-exchange-request',N'observe-fallback-price-exchange',N'select-equity-price-route',N'build-finance15-price-binding-request',N'bind-finance15-price-provider-credential',N'build-finance15-price-exchange-request',N'observe-finance15-price-exchange',N'select-finance15-price-route')
ORDER BY p.port_id;
SELECT '2_leg_a_operations' AS result_set, CONVERT(int,o.[key])+1 AS ordinal,
 JSON_VALUE(o.value,'$.operationId') AS operation_id, JSON_VALUE(o.value,'$.portId') AS port_id
FROM OPENJSON(@leg_a_ops) o ORDER BY CONVERT(int,o.[key]);
GO

-- ============================== AFTER, INVARIANTS AND PROOF ==============================
DECLARE @after nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'dispatch-pair-demo',0,N'sidefx:capabilities'));
DECLARE @before nvarchar(max)=(SELECT graph_source FROM #before_pair);
IF @after IS NULL OR ISJSON(@after)<>1 THROW 51000,N'DISPATCH_PAIR_AFTER_GRAPH_MISSING',1;

IF OBJECT_ID('tempdb..#after_graphs') IS NOT NULL DROP TABLE #after_graphs;
CREATE TABLE #after_graphs (capability_id nvarchar(400), graph_digest varchar(80));
DECLARE @caps2 TABLE (ord int identity, capability_id nvarchar(400));
INSERT @caps2(capability_id) VALUES
 (N'dispatch-pair-demo'),(N'say-hello-world'),(N'resolve-equity-market-price-evidence'),
 (N'project-model-provider-protocol'),(N'route-two-child-proof');
DECLARE @cap2 nvarchar(400), @v2 nvarchar(max);
DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id FROM @caps2 ORDER BY ord;
OPEN cur2; FETCH NEXT FROM cur2 INTO @cap2;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @v2=graph_source FROM analysis.capability_graph_source(@cap2,0,N'sidefx:capabilities');
 INSERT #after_graphs VALUES(@cap2,'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@v2)),2)));
 FETCH NEXT FROM cur2 INTO @cap2;
END
CLOSE cur2; DEALLOCATE cur2;

-- 1. No unrelated capability moved.
IF EXISTS (
 SELECT 1 FROM #before_graphs b JOIN #after_graphs a ON a.capability_id=b.capability_id
 WHERE b.capability_id<>N'dispatch-pair-demo' AND b.graph_digest<>a.graph_digest
) THROW 51000,N'DISPATCH_PAIR_UNRELATED_GRAPH_DIVERGED',1;
-- 2. The pair graph moves exactly once, unless this is an idempotent replay of
--    an already-extended leg-a.
DECLARE @before_digest varchar(80)=(SELECT graph_digest FROM #before_graphs WHERE capability_id=N'dispatch-pair-demo');
DECLARE @after_digest varchar(80)=(SELECT graph_digest FROM #after_graphs WHERE capability_id=N'dispatch-pair-demo');
DECLARE @before_leg_a_count int=(SELECT leg_a_op_count FROM #before_pair);
IF @before_leg_a_count=4 AND @before_digest=@after_digest
 THROW 51000,N'DISPATCH_PAIR_FALLBACK_GRAPH_DID_NOT_CHANGE',1;
IF @before_leg_a_count=15 AND @before_digest<>@after_digest
 THROW 51000,N'DISPATCH_PAIR_FALLBACK_GRAPH_CHANGED_ON_IDEMPOTENT_REPLAY',1;

-- 3. The dispatch authority, routing, budget, scenarios and contracts are
--    byte-identical. The only graph-source movement is leg-a and the two
--    namespace documents that now carry the copied rows.
IF JSON_QUERY(@after,N'$.dispatchAuthorities')<>(SELECT dispatch_authorities FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_DISPATCH_AUTHORITY_CHANGED',1;
IF JSON_QUERY(@after,N'$.transitions')<>(SELECT transitions FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_ROUTING_CHANGED',1;
IF JSON_QUERY(@after,N'$.edgeGroups')<>(SELECT edge_groups FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_EDGE_GROUPS_CHANGED',1;
IF JSON_QUERY(@after,N'$.executionBudget')<>(SELECT execution_budget FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_EXECUTION_BUDGET_CHANGED',1;
IF JSON_VALUE(@after,N'$.readyArbitration')<>(SELECT ready_arbitration FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_READY_ARBITRATION_CHANGED',1;
IF JSON_QUERY(@after,N'$.requiredExecutionFeatures')<>(SELECT required_execution_features FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_EXECUTION_FEATURES_CHANGED',1;
IF JSON_QUERY(@after,N'$.scenarios')<>(SELECT scenarios FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_SCENARIOS_CHANGED',1;
IF JSON_QUERY(@after,N'$.scenarioOutcomes')<>(SELECT scenario_outcomes FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_SCENARIO_OUTCOMES_CHANGED',1;
IF JSON_QUERY(@after,N'$.contractAuthorities')<>(SELECT contract_authorities FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_CONTRACT_AUTHORITIES_CHANGED',1;

-- 4. Branch C, the join and the root authority are untouched.
IF (SELECT a.value FROM OPENJSON(@after,N'$.executionAuthorities') a
    WHERE JSON_VALUE(a.value,N'$.owningScenarioId')=N'dispatch-pair-demo-leg-c')
   <>(SELECT leg_c_authority FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_BRANCH_C_CHANGED',1;
IF (SELECT a.value FROM OPENJSON(@after,N'$.executionAuthorities') a
    WHERE JSON_VALUE(a.value,N'$.owningScenarioId')=N'dispatch-pair-demo-join')
   <>(SELECT join_authority FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_JOIN_CHANGED',1;
IF (SELECT a.value FROM OPENJSON(@after,N'$.executionAuthorities') a
    WHERE JSON_VALUE(a.value,N'$.owningScenarioId')=N'dispatch-pair-demo')
   <>(SELECT root_authority FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_ROOT_AUTHORITY_CHANGED',1;

-- 5. The capability envelope digest did not move (no new capability version).
DECLARE @after_env_digest varchar(80);
SELECT @after_env_digest='sha256:'+LOWER(CONVERT(varchar(64),d.definition_digest,2))
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk AND c.capability_id=N'dispatch-pair-demo'
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
WHERE ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
IF @after_env_digest<>(SELECT envelope_digest FROM #before_pair)
 THROW 51000,N'DISPATCH_PAIR_ENVELOPE_DIGEST_CHANGED',1;

-- 6. Branch A now carries the fifteen-operation chain.
DECLARE @after_leg_a nvarchar(max)=(SELECT a.value FROM OPENJSON(@after,N'$.executionAuthorities') a
 WHERE JSON_VALUE(a.value,N'$.owningScenarioId')=N'dispatch-pair-demo-leg-a');
DECLARE @after_leg_a_count int=(SELECT COUNT(*) FROM OPENJSON(@after_leg_a,N'$.operations'));
IF @after_leg_a_count<>15 THROW 51000,N'DISPATCH_PAIR_LEG_A_NOT_FIFTEEN',1;
DECLARE @after_sequence nvarchar(max)=(
 SELECT STRING_AGG(JSON_VALUE(o.value,'$.portId'),N',') WITHIN GROUP (ORDER BY CONVERT(int,o.[key]))
 FROM OPENJSON(@after_leg_a,N'$.operations') o);
IF @after_sequence<>N'build-equity-price-binding-request,bind-equity-price-provider-credential,build-equity-price-exchange-request,observe-equity-price-exchange,normalize-equity-price-evidence,build-fallback-price-binding-request,bind-fallback-price-provider-credential,build-fallback-price-exchange-request,observe-fallback-price-exchange,select-equity-price-route,build-finance15-price-binding-request,bind-finance15-price-provider-credential,build-finance15-price-exchange-request,observe-finance15-price-exchange,select-finance15-price-route'
 THROW 51000,N'DISPATCH_PAIR_LEG_A_SEQUENCE_WRONG',1;

-- 7. The graph-source delta is exactly the copied namespace documents.
DECLARE @added_transformations nvarchar(max)=(
 SELECT STRING_AGG(JSON_VALUE(a.value,N'$.id'),N',') WITHIN GROUP (ORDER BY JSON_VALUE(a.value,N'$.id'))
 FROM OPENJSON(@after,N'$.semanticTransformations') a
 WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@before,N'$.semanticTransformations') b WHERE JSON_VALUE(b.value,N'$.id')=JSON_VALUE(a.value,N'$.id')));
IF @added_transformations<>N'build-fallback-price-binding-request,build-fallback-price-exchange-request,build-finance15-price-binding-request,build-finance15-price-exchange-request,normalize-equity-price-evidence,select-equity-price-route,select-finance15-price-route'
 THROW 51000,N'DISPATCH_PAIR_ADDED_TRANSFORMATIONS_NOT_EXACT',1;
IF EXISTS (
 SELECT 1 FROM OPENJSON(@before,N'$.semanticTransformations') b
 WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@after,N'$.semanticTransformations') a WHERE JSON_VALUE(a.value,N'$.id')=JSON_VALUE(b.value,N'$.id'))
) THROW 51000,N'DISPATCH_PAIR_TRANSFORMATION_REMOVED',1;
DECLARE @added_ports nvarchar(max)=(
 SELECT STRING_AGG(JSON_VALUE(a.value,N'$.portId'),N',') WITHIN GROUP (ORDER BY JSON_VALUE(a.value,N'$.portId'))
 FROM OPENJSON(@after,N'$.interfaceAuthority.portBindings') a
 WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@before,N'$.interfaceAuthority.portBindings') b WHERE JSON_VALUE(b.value,N'$.portId')=JSON_VALUE(a.value,N'$.portId')));
IF @added_ports<>N'bind-fallback-price-provider-credential,bind-finance15-price-provider-credential,build-fallback-price-binding-request,build-fallback-price-exchange-request,build-finance15-price-binding-request,build-finance15-price-exchange-request,normalize-equity-price-evidence,observe-fallback-price-exchange,observe-finance15-price-exchange,select-equity-price-route,select-finance15-price-route'
 THROW 51000,N'DISPATCH_PAIR_ADDED_PORTS_NOT_EXACT',1;
IF EXISTS (
 SELECT 1 FROM OPENJSON(@before,N'$.interfaceAuthority.portBindings') b
 WHERE NOT EXISTS (SELECT 1 FROM OPENJSON(@after,N'$.interfaceAuthority.portBindings') a WHERE JSON_VALUE(a.value,N'$.portId')=JSON_VALUE(b.value,N'$.portId'))
) THROW 51000,N'DISPATCH_PAIR_PORT_BINDING_REMOVED',1;

-- 8. Result sets.
SELECT '3_equality' AS result_set, b.capability_id,
 b.graph_digest AS before_graph_digest, a.graph_digest AS after_graph_digest,
 CONVERT(bit,CASE WHEN b.graph_digest=a.graph_digest THEN 1 ELSE 0 END) AS identical
FROM #before_graphs b JOIN #after_graphs a ON a.capability_id=b.capability_id
ORDER BY b.capability_id;
SELECT '4_claim' AS result_set,
 JSON_VALUE(@after,N'$.dispatchAuthorities[0].mode') AS mode,
 JSON_VALUE(@after,N'$.dispatchAuthorities[0].maximumActiveBranches') AS maximum_active_branches,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@after,N'$.transitions'))) AS routes,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@after,N'$.edgeGroups'))) AS edge_groups,
 @after_leg_a_count AS leg_a_operations,
 (SELECT envelope_digest FROM #before_pair) AS envelope_digest_before, @after_env_digest AS envelope_digest_after;
SELECT '5_graph_delta' AS result_set, @added_transformations AS added_transformations, @added_ports AS added_port_bindings;
SELECT '6_leg_a_operations' AS result_set, CONVERT(int,o.[key])+1 AS ordinal,
 JSON_VALUE(o.value,N'$.operationId') AS operation_id, JSON_VALUE(o.value,N'$.portId') AS port_id,
 CASE WHEN JSON_QUERY(o.value,N'$.outcomeVariants') IS NULL THEN N'' ELSE N'declared' END AS variants
FROM OPENJSON(@after_leg_a,N'$.operations') o ORDER BY CONVERT(int,o.[key]);

ROLLBACK TRANSACTION;
-- Dry run only. The install copy is
-- extend-dispatch-pair-demo-leg-a-equity-fallback.commit.sql.
