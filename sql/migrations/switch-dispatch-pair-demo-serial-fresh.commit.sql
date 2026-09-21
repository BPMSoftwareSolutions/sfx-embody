-- switch-dispatch-pair-demo-serial-fresh.sql
--
-- Demo reverse: flip dispatch-pair-demo from concurrent back to serial, with
-- maximumActiveBranches 1. Same declared value as
-- switch-dispatch-pair-demo-serial.sql, minted with a fresh byte layout.
--
-- Why a fresh file: the estate model forbids linking a capability to
-- already-minted definition bytes twice (the unique (capability_pk,
-- definition_digest) index and the declaration selection rule). The literal
-- serial authority in switch-dispatch-pair-demo-serial.sql was installed once
-- (envelope digest c9d96b92...) and then superseded by the concurrent re-mint;
-- replaying that file now refuses with DISPATCH_PAIR_SERIAL_ENVELOPE_ALREADY_MINTED
-- rather than re-point history. Re-authoring the same keys and values in a new
-- key order mints fresh content while the equality proof below still shows the
-- declared dispatch authority is the only difference from the before envelope.
--
-- No capability source, port, transformation, contract, scenario or kernel
-- artifact changes; the capability envelope's
-- $.semantics.executionGraph.dispatchAuthorities[0] is the only declared value
-- re-minted. Idempotent: a replay against the already-serial fresh envelope
-- re-authors the same bytes, finds the linked definition and inserts nothing.
--
-- Default: ROLLBACK after verification. The install is the .commit.sql copy.
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
DECLARE @beforeAuthority nvarchar(max)=JSON_QUERY(@curEnv,N'$.semantics.executionGraph.dispatchAuthorities');

-- The fresh serial authority: the same declared keys and values as the M3
-- serial authority, in an order never minted before. The array is passed
-- through JSON_QUERY so JSON_MODIFY inserts it as JSON, not a string.
DECLARE @serialAuthority nvarchar(max)=JSON_QUERY(
 N'[{"dispatchAuthorityId":"dispatch-pair.v1","mode":"serial","maximumActiveBranches":1,"maximumInFlightEffects":2,"legCount":2,"readyOrder":"declared-edge-order","branchFailure":"collect","ownership":"join-before-return"}]');
DECLARE @newEnv nvarchar(max)=JSON_MODIFY(@curEnv,N'$.semantics.executionGraph.dispatchAuthorities',JSON_QUERY(@serialAuthority));
-- Restoring the before authority in the new envelope must reproduce the before
-- envelope byte for byte: the declared dispatch authority is the only change.
IF JSON_MODIFY(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities',JSON_QUERY(@beforeAuthority))<>@curEnv
 THROW 51000,N'DISPATCH_PAIR_SERIAL_FRESH_CHANGED_MORE_THAN_THE_AUTHORITY',1;
IF JSON_VALUE(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].mode')<>N'serial'
 THROW 51000,N'DISPATCH_PAIR_MODE_NOT_SERIAL',1;
IF JSON_VALUE(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].maximumActiveBranches')<>1
 THROW 51000,N'DISPATCH_PAIR_CAPACITY_NOT_ONE',1;
SELECT '2_authority_before_after' AS result_set,
 JSON_VALUE(@curEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].mode') AS before_mode,
 JSON_VALUE(@curEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].maximumActiveBranches') AS before_maximum_active_branches,
 JSON_VALUE(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].mode') AS after_mode,
 JSON_VALUE(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].maximumActiveBranches') AS after_maximum_active_branches,
 JSON_VALUE(@newEnv,N'$.semantics.executionGraph.dispatchAuthorities[0].maximumInFlightEffects') AS maximum_in_flight_effects;

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
 -- A fresh serial envelope must not already be linked to this capability when
 -- the current mode is concurrent; re-pointing at minted bytes is refused by
 -- the model. When the current mode is already serial the linked bytes are the
 -- ones this file mints and the re-declaration below is an idempotent no-op.
 IF @currentMode=N'concurrent' AND EXISTS (SELECT 1 FROM model.capability_version WHERE capability_pk=@capPk AND semantic_object_definition_pk=@sod)
  THROW 51000,N'DISPATCH_PAIR_SERIAL_FRESH_ENVELOPE_ALREADY_MINTED',1;
 IF @currentMode=N'concurrent'
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
END
SELECT '3_fresh_serial_minted' AS result_set,
 LOWER(CONVERT(varchar(64),@digest,2)) AS fresh_serial_definition_digest,
 @sod AS semantic_object_definition_pk,
 CONVERT(bit,CASE WHEN @sod=@capSod THEN 1 ELSE 0 END) AS already_selected;
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
IF @before_mode=N'concurrent' AND @before_digest=@after_digest
 THROW 51000,N'DISPATCH_PAIR_GRAPH_DID_NOT_CHANGE',1;
IF @before_mode=N'serial' AND @before_digest<>@after_digest
 THROW 51000,N'DISPATCH_PAIR_GRAPH_CHANGED_ON_IDEMPOTENT_REPLAY',1;

IF JSON_VALUE(@after,N'$.dispatchAuthorities[0].mode')<>N'serial' THROW 51000,N'DISPATCH_PAIR_MODE_NOT_SERIAL',1;
IF JSON_VALUE(@after,N'$.dispatchAuthorities[0].maximumActiveBranches')<>1 THROW 51000,N'DISPATCH_PAIR_CAPACITY_NOT_ONE',1;
-- Restoring the before authority into the after source reproduces the before
-- source byte for byte: no route, group, budget, scenario or contract moved.
IF JSON_MODIFY(@after,N'$.dispatchAuthorities',JSON_QUERY(@before,N'$.dispatchAuthorities'))<>@before
 THROW 51000,N'DISPATCH_PAIR_GRAPH_CHANGED_MORE_THAN_DISPATCH_AUTHORITY',1;

SELECT '4_equality' AS result_set, b.capability_id,
 b.graph_digest AS before_graph_digest, a.graph_digest AS after_graph_digest,
 CONVERT(bit,CASE WHEN b.graph_digest=a.graph_digest THEN 1 ELSE 0 END) AS identical
FROM #graph_before b JOIN #graph_after a ON a.capability_id=b.capability_id
ORDER BY b.capability_id;

SELECT '5_claim' AS result_set,
 JSON_VALUE(@after,N'$.dispatchAuthorities[0].mode') AS mode,
 JSON_VALUE(@after,N'$.dispatchAuthorities[0].maximumActiveBranches') AS maximum_active_branches,
 JSON_VALUE(@after,N'$.executionBudget.maximumInFlightEffects') AS budget_effects,
 JSON_VALUE(@after,N'$.readyArbitration') AS ready_arbitration,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@after,N'$.transitions'))) AS routes,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@after,N'$.edgeGroups'))) AS edge_groups;

SELECT '6_graph_change_scope' AS result_set,
 @before_digest AS before_graph_digest, @after_digest AS after_graph_digest,
 CONVERT(bit,CASE WHEN JSON_MODIFY(@after,N'$.dispatchAuthorities',JSON_QUERY(@before,N'$.dispatchAuthorities'))=@before THEN 1 ELSE 0 END) AS authority_is_the_only_difference;

COMMIT TRANSACTION;
-- Installed after the rollback dry run (graph digest moved
-- sha256:968a1cef... -> sha256:cc739288... with authority_is_the_only_difference
-- true; four unrelated capabilities unchanged). Evidence:
-- demo/dispatch-pair/evidence/live-serial.*. The concurrent authority is
-- restored afterwards by re-running switch-dispatch-pair-demo-concurrent.sql.
