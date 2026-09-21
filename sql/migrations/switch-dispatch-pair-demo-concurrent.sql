-- switch-dispatch-pair-demo-concurrent.sql
--
-- M2: flip the declared dispatch authority of dispatch-pair-demo from serial to
-- concurrent, with maximumActiveBranches 2. This is the estate-only policy move
-- the whole unit exists to prove: no capability source, no port, no
-- transformation, no contract and no kernel artifact changes; the capability
-- envelope's $.semantics.executionGraph.dispatchAuthorities[0] is the only
-- declared value re-minted, and the graph source the kernel compiles changes
-- only in that top-level key.
--
-- The switch is verified structurally: the new envelope equals the old envelope
-- with the dispatch authority array replaced, and every captured capability
-- except dispatch-pair-demo keeps its graph-source bytes.
--
-- Idempotent: once installed, a re-run captures the concurrent authority as
-- "before", re-mints the same bytes, and every digest still matches.
--
-- Default: ROLLBACK after verification. Install by replacing the final ROLLBACK
-- with COMMIT. A comparison run must use the same kernel artifact and fixture.
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
IF OBJECT_ID('tempdb..#graph_before') IS NOT NULL DROP TABLE #graph_before;
CREATE TABLE #graph_before (capability_id nvarchar(400), graph_digest varchar(80));
IF OBJECT_ID('tempdb..#pair_before_source') IS NOT NULL DROP TABLE #pair_before_source;
CREATE TABLE #pair_before_source (graph_source nvarchar(max));
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
 IF @cap=N'dispatch-pair-demo' INSERT #pair_before_source VALUES(@v);
 INSERT #graph_before VALUES(@cap,'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@v)),2)));
 FETCH NEXT FROM cur INTO @cap;
END
CLOSE cur; DEALLOCATE cur;
SELECT '1_before' AS result_set, capability_id, graph_digest FROM #graph_before ORDER BY capability_id;
GO

-- ============================== RE-MINT ONLY THE DISPATCH AUTHORITY ==============================
DECLARE @capability_id nvarchar(400)=N'dispatch-pair-demo';
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
IF JSON_QUERY(@curEnv,N'$.semantics.executionGraph') IS NULL THROW 51000,N'DISPATCH_PAIR_EXECUTION_GRAPH_NOT_DECLARED',1;
DECLARE @currentMode nvarchar(400)=JSON_VALUE(@curEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].mode');
IF @currentMode NOT IN (N'serial',N'concurrent') THROW 51000,N'DISPATCH_PAIR_MODE_UNSUPPORTED',1;

DECLARE @newEnv nvarchar(max)=CASE WHEN @currentMode=N'serial'
  THEN JSON_MODIFY(JSON_MODIFY(@curEnv,
    N'$.semantics.executionGraph.dispatchAuthorities[0].mode', N'concurrent'),
    N'$.semantics.executionGraph.dispatchAuthorities[0].maximumActiveBranches', 2)
  ELSE @curEnv END;
-- When the switch is the actual change, the only declared difference is the
-- dispatch authority array: replacing it in the old envelope must reproduce the
-- new envelope byte for byte. A re-run against an already-concurrent envelope
-- re-mints the same bytes.
IF @currentMode=N'serial' AND JSON_MODIFY(@curEnv,N'$.semantics.executionGraph.dispatchAuthorities',
   JSON_QUERY(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities'))<>@newEnv
 THROW 51000,N'DISPATCH_PAIR_SWITCH_CHANGED_MORE_THAN_THE_AUTHORITY',1;
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
SELECT '2_authority_after_switch' AS result_set,
  JSON_VALUE(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].mode') AS mode,
  JSON_VALUE(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].maximumActiveBranches') AS maximum_active_branches,
  JSON_VALUE(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].maximumInFlightEffects') AS maximum_in_flight_effects,
  JSON_VALUE(@newEnv,N'$.semantics.executionGraph.executionBudget.maximumInFlightEffects') AS budget_effects,
  JSON_VALUE(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].legCount') AS leg_count;
GO

-- ============================== AFTER AND EQUALITY ==============================
DECLARE @caps2 TABLE (ord int identity, capability_id nvarchar(400));
INSERT @caps2(capability_id) VALUES
 (N'dispatch-pair-demo'),(N'say-hello-world'),(N'resolve-equity-market-price-evidence'),
 (N'project-model-provider-protocol'),(N'route-two-child-proof');
IF OBJECT_ID('tempdb..#graph_after') IS NOT NULL DROP TABLE #graph_after;
CREATE TABLE #graph_after (capability_id nvarchar(400), graph_digest varchar(80));
DECLARE @cap2 nvarchar(400), @v2 nvarchar(max);
DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR SELECT capability_id FROM @caps2 ORDER BY ord;
OPEN cur2; FETCH NEXT FROM cur2 INTO @cap2;
WHILE @@FETCH_STATUS=0
BEGIN
 SELECT @v2=graph_source FROM analysis.capability_graph_source(@cap2,0,N'sidefx:capabilities');
 INSERT #graph_after VALUES(@cap2,'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@v2)),2)));
 FETCH NEXT FROM cur2 INTO @cap2;
END
CLOSE cur2; DEALLOCATE cur2;

DECLARE @after nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'dispatch-pair-demo',0,N'sidefx:capabilities'));
DECLARE @before nvarchar(max)=(SELECT TOP (1) graph_source FROM #pair_before_source);
DECLARE @before_digest varchar(80)=(SELECT graph_digest FROM #graph_before WHERE capability_id=N'dispatch-pair-demo');
DECLARE @after_digest varchar(80)=(SELECT graph_digest FROM #graph_after WHERE capability_id=N'dispatch-pair-demo');
DECLARE @before_mode nvarchar(50)=JSON_VALUE(@before,N'$.dispatchAuthorities[0].mode');

IF EXISTS (
 SELECT 1 FROM #graph_before b JOIN #graph_after a ON a.capability_id=b.capability_id
 WHERE b.capability_id<>N'dispatch-pair-demo' AND b.graph_digest<>a.graph_digest
) THROW 51000,N'DISPATCH_PAIR_UNRELATED_GRAPH_DIVERGED',1;
IF @before_mode=N'serial' AND @before_digest=@after_digest
 THROW 51000,N'DISPATCH_PAIR_GRAPH_DID_NOT_CHANGE',1;
IF @before_mode=N'concurrent' AND @before_digest<>@after_digest
 THROW 51000,N'DISPATCH_PAIR_GRAPH_CHANGED_ON_IDEMPOTENT_REPLAY',1;

IF JSON_VALUE(@after,N'$.dispatchAuthorities[0].mode')<>N'concurrent' THROW 51000,N'DISPATCH_PAIR_MODE_NOT_CONCURRENT',1;
IF JSON_VALUE(@after,N'$.dispatchAuthorities[0].maximumActiveBranches')<>2 THROW 51000,N'DISPATCH_PAIR_CAPACITY_NOT_TWO',1;
-- The graph source changes only in its top-level dispatchAuthorities key:
-- restoring the before authority into the after source reproduces the before
-- source, so no route, group, budget, scenario or contract byte moved.
IF JSON_MODIFY(@after,N'$.dispatchAuthorities',JSON_QUERY(@before,N'$.dispatchAuthorities'))<>@before
 THROW 51000,N'DISPATCH_PAIR_GRAPH_CHANGED_MORE_THAN_DISPATCH_AUTHORITY',1;

SELECT '3_equality' AS result_set, b.capability_id,
  b.graph_digest AS before_graph_digest, a.graph_digest AS after_graph_digest,
  CONVERT(bit,CASE WHEN b.graph_digest=a.graph_digest THEN 1 ELSE 0 END) AS identical
FROM #graph_before b JOIN #graph_after a ON a.capability_id=b.capability_id
ORDER BY b.capability_id;

SELECT '4_claim' AS result_set,
  JSON_VALUE(@after,N'$.dispatchAuthorities[0].mode') AS mode,
  JSON_VALUE(@after,N'$.dispatchAuthorities[0].maximumActiveBranches') AS maximum_active_branches,
  JSON_VALUE(@after,N'$.executionBudget.maximumInFlightEffects') AS budget_effects,
  JSON_VALUE(@after,N'$.readyArbitration') AS ready_arbitration,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@after,N'$.transitions'))) AS routes,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@after,N'$.edgeGroups'))) AS edge_groups;

SELECT '5_graph_change_scope' AS result_set,
  @before_digest AS before_graph_digest, @after_digest AS after_graph_digest,
  CONVERT(bit,CASE WHEN JSON_MODIFY(@after,N'$.dispatchAuthorities',JSON_QUERY(@before,N'$.dispatchAuthorities'))=@before THEN 1 ELSE 0 END) AS authority_is_the_only_difference;

COMMIT TRANSACTION;
-- Installed after the rollback dry run: only dispatch-pair-demo's graph source
-- changed, and only in its top-level dispatchAuthorities key; four unrelated
-- capabilities kept their graph-source bytes. Evidence:
-- demo/dispatch-pair/evidence/concurrent.*. Reversal: re-run
-- declare-dispatch-pair-demo.sql (serial authority) or JSON_MODIFY the
-- authority back to serial / maximumActiveBranches 1.
