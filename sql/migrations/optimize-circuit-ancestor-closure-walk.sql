-- optimize-circuit-ancestor-closure-walk.sql
--
-- The declared `circuit` command executes its subject, then serves
-- `read-capability-circuit` over the invocation testimony and the compiled
-- plan. The agent-lane circuit read (985 planned cells / 716 testimony entries)
-- spends almost all of its time in the read's ancestor closure: the retained
-- statement walks the closure with `WHILE @added>0 INSERT @anc ... FROM @anc`,
-- re-expanding every row ever inserted on every pass. The earlier RECOMPILE
-- repair (optimize-circuit-ancestor-closure.sql) fixed the table-variable
-- cardinality trap inside that pass; the full scan per pass remains.
--
-- Measured on the live reconstructed request (985 planned / 703 observed,
-- 21,909 closure rows, 33 passes), same pinned session, same input:
--   installed closure loop      51,392.967 ms
--   frontier walk (this fix)     5,180.012 ms
--   closure membership          identical (0 rows each way in both EXCEPTs)
-- The frontier walk expands only the rows added by the previous pass until a
-- pass inserts nothing; the least fixpoint is the same because the reduction
-- rules are deterministic and the NOT EXISTS gate still de-duplicates.
--
-- This migration re-declares only the `read-capability-circuit-port`
-- definition: it reads the selected statement, replaces the full-scan closure
-- block with the frontier walk (the six reduction rules unchanged), then mints
-- and relinks the port version exactly as optimize-circuit-ancestor-closure.sql
-- does. The `sidefx_reader` grants are unchanged; the view model, the
-- attestation and the ordering rules are unchanged.
--
-- Idempotent: a second run finds `DECLARE @frontier` in the selected statement
-- and re-declares nothing.
--
-- Lifecycle: default was ROLLBACK. Installed after the rollback dry run and the
-- from-transaction preflight on the uncommitted rows (the old and the new
-- statement returned byte-identical circuit-view.v1 over the generated
-- preflight testimony; the reader self-test returned the expected view).
--
-- Proof result sets:
--   1_claim            the retained statement carries the frontier walk and no
--                      longer scans the whole closure per pass
--   2_old_new_equality the old and the new statement return byte-identical
--                      circuit-view.v1 over the generated preflight testimony
--   3_reader_self_test the new read returns circuit-view.v1 with the expected
--                      nodes, edges and structured attestation
--   4_relink           the invocation points at the re-declared port version
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

-- ============================== THE FRONTIER WALK ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @ns nvarchar(400)=N'sidefx:capability:read-capability-circuit' COLLATE Latin1_General_100_BIN2;
DECLARE @port nvarchar(400)=N'read-capability-circuit-port' COLLATE Latin1_General_100_BIN2;
DECLARE @sem nvarchar(max), @stmt nvarchar(max), @old_stmt nvarchar(max), @prevver bigint,
 @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
SELECT @sem=JSON_QUERY(d.definition_json,'$.semantics'),
 @stmt=c.statement,
 @prevver=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') WITH (statement nvarchar(max) '$.statement') c
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@ns AND d.declared_id=@port;
IF @sem IS NULL THROW 51000,N'CIRCUIT_READER_PORT_NOT_SELECTED',1;
IF @stmt IS NULL THROW 51000,N'CIRCUIT_READER_STATEMENT_MISSING',1;
SET @old_stmt=@stmt;
IF CHARINDEX(N'DECLARE @frontier',@stmt)=0
BEGIN
 IF @prevver IS NULL THROW 51000,N'CIRCUIT_READER_PORT_VERSION_MISSING',1;
 DECLARE @old_block nvarchar(max)=N'DECLARE @anc TABLE(originId nvarchar(400) NOT NULL,candidate nvarchar(400) NOT NULL,PRIMARY KEY NONCLUSTERED(originId,candidate));
INSERT @anc(originId,candidate)
SELECT cellId,cellId FROM @planned
UNION
SELECT cellId,cellId FROM @observed;
DECLARE @added int=1;
WHILE @added>0
BEGIN
 INSERT @anc(originId,candidate)
 SELECT DISTINCT a.originId,v.candidate
 FROM @anc a
 OUTER APPLY (SELECT pp.parentCellId FROM @planned_parent pp WHERE pp.cellId=a.candidate) d
 CROSS APPLY (VALUES
  (CASE WHEN RIGHT(a.candidate,10)=N'':selection'' THEN LEFT(a.candidate,LEN(a.candidate)-10) END),
  (CASE WHEN RIGHT(a.candidate,11)=N'':expression'' THEN LEFT(a.candidate,LEN(a.candidate)-11) END),
  (CASE WHEN CHARINDEX(N''.'',REVERSE(a.candidate))>1 AND CHARINDEX(N'':'',SUBSTRING(a.candidate,LEN(a.candidate)-CHARINDEX(N''.'',REVERSE(a.candidate))+2,400))=0
    THEN LEFT(a.candidate,LEN(a.candidate)-CHARINDEX(N''.'',REVERSE(a.candidate))) END),
  (CASE WHEN PATINDEX(N''%:expression[.:]%'',a.candidate)>0
    THEN LEFT(a.candidate,PATINDEX(N''%:expression[.:]%'',a.candidate)-1)+SUBSTRING(a.candidate,PATINDEX(N''%:expression[.:]%'',a.candidate)+11,400) END),
  (CASE WHEN PATINDEX(N''%:selection[.:]%'',a.candidate)>0
    THEN LEFT(a.candidate,PATINDEX(N''%:selection[.:]%'',a.candidate)-1)+SUBSTRING(a.candidate,PATINDEX(N''%:selection[.:]%'',a.candidate)+10,400) END),
  (d.parentCellId)
 ) v(candidate)
 WHERE v.candidate IS NOT NULL AND LEN(v.candidate)>0 AND v.candidate<>a.candidate
  AND NOT EXISTS(SELECT 1 FROM @anc x WHERE x.originId=a.originId AND x.candidate=v.candidate) OPTION (RECOMPILE);
 SET @added=@@ROWCOUNT;
END';
 DECLARE @new_block nvarchar(max)=N'DECLARE @anc TABLE(originId nvarchar(400) NOT NULL,candidate nvarchar(400) NOT NULL,PRIMARY KEY NONCLUSTERED(originId,candidate));
DECLARE @frontier TABLE(originId nvarchar(400) NOT NULL,candidate nvarchar(400) NOT NULL,PRIMARY KEY NONCLUSTERED(originId,candidate));
DECLARE @next TABLE(originId nvarchar(400) NOT NULL,candidate nvarchar(400) NOT NULL,PRIMARY KEY NONCLUSTERED(originId,candidate));
INSERT @anc(originId,candidate)
SELECT cellId,cellId FROM @planned
UNION
SELECT cellId,cellId FROM @observed;
INSERT @frontier(originId,candidate) SELECT originId,candidate FROM @anc;
WHILE 1=1
BEGIN
 DELETE @next;
 INSERT @anc(originId,candidate)
 OUTPUT inserted.originId,inserted.candidate INTO @next
 SELECT DISTINCT a.originId,v.candidate
 FROM @frontier a
 OUTER APPLY (SELECT pp.parentCellId FROM @planned_parent pp WHERE pp.cellId=a.candidate) d
 CROSS APPLY (VALUES
  (CASE WHEN RIGHT(a.candidate,10)=N'':selection'' THEN LEFT(a.candidate,LEN(a.candidate)-10) END),
  (CASE WHEN RIGHT(a.candidate,11)=N'':expression'' THEN LEFT(a.candidate,LEN(a.candidate)-11) END),
  (CASE WHEN CHARINDEX(N''.'',REVERSE(a.candidate))>1 AND CHARINDEX(N'':'',SUBSTRING(a.candidate,LEN(a.candidate)-CHARINDEX(N''.'',REVERSE(a.candidate))+2,400))=0
    THEN LEFT(a.candidate,LEN(a.candidate)-CHARINDEX(N''.'',REVERSE(a.candidate))) END),
  (CASE WHEN PATINDEX(N''%:expression[.:]%'',a.candidate)>0
    THEN LEFT(a.candidate,PATINDEX(N''%:expression[.:]%'',a.candidate)-1)+SUBSTRING(a.candidate,PATINDEX(N''%:expression[.:]%'',a.candidate)+11,400) END),
  (CASE WHEN PATINDEX(N''%:selection[.:]%'',a.candidate)>0
    THEN LEFT(a.candidate,PATINDEX(N''%:selection[.:]%'',a.candidate)-1)+SUBSTRING(a.candidate,PATINDEX(N''%:selection[.:]%'',a.candidate)+10,400) END),
  (d.parentCellId)
 ) v(candidate)
 WHERE v.candidate IS NOT NULL AND LEN(v.candidate)>0 AND v.candidate<>a.candidate
  AND NOT EXISTS(SELECT 1 FROM @anc x WHERE x.originId=a.originId AND x.candidate=v.candidate) OPTION (RECOMPILE);
 IF @@ROWCOUNT=0 BREAK;
 DELETE @frontier;
 INSERT @frontier(originId,candidate) SELECT originId,candidate FROM @next;
END';
 IF CHARINDEX(@old_block,@stmt)=0 THROW 51000,N'CIRCUIT_CLOSURE_BLOCK_NOT_FOUND',1;
 SET @stmt=REPLACE(@stmt,@old_block,@new_block);
 IF CHARINDEX(N'DECLARE @frontier',@stmt)=0 THROW 51000,N'CIRCUIT_FRONTIER_NOT_INJECTED',1;
 SET @sem=JSON_MODIFY(@sem,'$.configuration.statement',@stmt);
 EXEC model.put_semantic_definition 'PORT',@ns,@port,@sem,@object2 OUTPUT,@definition2 OUTPUT,@digest2 OUTPUT;
 SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object2);
 IF @portpk IS NOT NULL BEGIN
  SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition2);
  IF @version IS NULL BEGIN
   INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@portpk,@object2,@definition2,@digest2,'consumer-interface-authority.v1','PORT',@definition2,N'');
   SET @version=SCOPE_IDENTITY();
  END
  UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
 END
END

-- ============================== IN-TRANSACTION PREFLIGHT ==============================
DECLARE @selected_statement nvarchar(max);
SELECT @selected_statement=c.statement
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration') WITH (statement nvarchar(max) '$.statement') c
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@ns AND d.declared_id=@port;
IF CHARINDEX(N'DECLARE @frontier',@selected_statement)=0 THROW 51000,N'CIRCUIT_FRONTIER_NOT_SELECTED',1;
IF CHARINDEX(N'FROM @frontier a',@selected_statement)=0 THROW 51000,N'CIRCUIT_FRONTIER_NOT_ON_CLOSURE',1;

-- The generated preflight testimony: a scenario, 12 operations with nested
-- expression segments, provider/physical children, declared parent links and
-- observed admissions. Both the old and the new statement execute it.
DECLARE @cells nvarchar(max), @edges nvarchar(max), @planned nvarchar(max);
;WITH n AS (SELECT TOP (12) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects),
 planned_rows AS (
  SELECT i,
   N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i) AS root,
   N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i)+N':expression.fields.field'+CONVERT(nvarchar(10),i) AS leaf,
   N'cell:scenario:synth' AS scenario
  FROM n
 ),
 all_planned AS (
  SELECT scenario AS cellId,NULL AS parentCellId,N'scenario' AS altitude FROM planned_rows
  UNION ALL SELECT N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i),N'cell:scenario:synth',N'mechanic' FROM n
  UNION ALL SELECT N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i)+N':expression',N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i),N'mechanic' FROM n
  UNION ALL SELECT N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i)+N':expression.fields.field'+CONVERT(nvarchar(10),i),N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i),N'mechanic' FROM n
  UNION ALL SELECT N'cell:provider:synth.operation.'+CONVERT(nvarchar(10),i),N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i),N'provider' FROM n
  UNION ALL SELECT N'cell:physical:synth.operation.'+CONVERT(nvarchar(10),i),N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i),N'physical' FROM n
 )
 SELECT @planned=(SELECT cellId,parentCellId,altitude FROM all_planned ORDER BY cellId FOR JSON PATH);
;WITH n AS (SELECT TOP (12) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
 SELECT @cells=(SELECT cellId,cellAltitude,disposition,outcomeClassification,durationMilliseconds,completedAt,logicalOrder FROM (
  SELECT N'cell:scenario:synth' AS cellId,N'scenario' AS cellAltitude,N'completed' AS disposition,N'success' AS outcomeClassification,1 AS durationMilliseconds,N'2026-09-19T00:00:00.001Z' AS completedAt,0 AS logicalOrder
  UNION ALL SELECT N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i),N'mechanic',N'completed',NULL,1,N'2026-09-19T00:00:00.002Z',2*i FROM n
  UNION ALL SELECT N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i)+N':expression.fields.field'+CONVERT(nvarchar(10),i),N'mechanic',N'completed',NULL,1,N'2026-09-19T00:00:00.003Z',2*i+1 FROM n
  UNION ALL SELECT N'cell:provider:synth.operation.'+CONVERT(nvarchar(10),i),N'provider',N'completed',NULL,1,N'2026-09-19T00:00:00.004Z',2*i+100 FROM n
  UNION ALL SELECT N'cell:physical:synth.operation.'+CONVERT(nvarchar(10),i),N'physical',N'completed',NULL,1,N'2026-09-19T00:00:00.005Z',2*i+200 FROM n
 ) c ORDER BY logicalOrder FOR JSON PATH);
 ;WITH n AS (SELECT TOP (12) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
 SELECT @edges=(SELECT edgeId,sourceCellExecutionId,destinationCellId,admissionDisposition,logicalOrder FROM (
  SELECT N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i)+N':expression:dependency:1' AS edgeId,
    N'execution:graph:synth:'+N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i)+N':expression.fields.field'+CONVERT(nvarchar(10),i)+N':1' AS sourceCellExecutionId,
    N'cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i)+N':expression' AS destinationCellId,
    N'admitted' AS admissionDisposition,2*i AS logicalOrder FROM n
  UNION ALL
  SELECT N'edge:sequence:synth:'+CONVERT(nvarchar(10),i),
    N'execution:graph:synth:cell:mechanic:synth.operation.'+CONVERT(nvarchar(10),i)+N':1',
    N'cell:provider:synth.operation.'+CONVERT(nvarchar(10),i),N'admitted',2*i+50 FROM n
  UNION ALL
  SELECT N'edge:descent:synth:'+CONVERT(nvarchar(10),i),
    N'execution:graph:synth:cell:provider:synth.operation.'+CONVERT(nvarchar(10),i)+N':1',
    N'cell:physical:synth.operation.'+CONVERT(nvarchar(10),i),N'admitted',2*i+60 FROM n
 ) e ORDER BY logicalOrder FOR JSON PATH);
DECLARE @sample nvarchar(max)=N'{"contractId":"circuit-view-request.v1","payload":{"capabilityId":"circuit-frontier-self-test","cellTestimony":'
 + @cells + N',"edgeTestimony":'+@edges+N',"plannedCells":'+@planned+N'}}';

DECLARE @old_view TABLE (value nvarchar(max));
DECLARE @new_view TABLE (value nvarchar(max));
INSERT @old_view EXEC sp_executesql @old_stmt,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
INSERT @new_view EXEC sp_executesql @selected_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
IF (SELECT COUNT(*) FROM @old_view)<>1 OR (SELECT COUNT(*) FROM @new_view)<>1 THROW 51000,N'CIRCUIT_PREFLIGHT_NOT_SINGULAR',1;
DECLARE @old_body nvarchar(max)=(SELECT value FROM @old_view);
DECLARE @new_body nvarchar(max)=(SELECT value FROM @new_view);
IF @old_body<>@new_body THROW 51000,N'CIRCUIT_OLD_NEW_VIEW_DIVERGED',1;
IF JSON_VALUE(@new_body,'$.contractId')<>N'circuit-view.v1' THROW 51000,N'CIRCUIT_PREFLIGHT_CONTRACT_MISMATCH',1;
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@new_body,'$.nodes')))<>37 THROW 51000,N'CIRCUIT_PREFLIGHT_NODE_COUNT_MISMATCH',1;
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@new_body,'$.edges')))<>24 THROW 51000,N'CIRCUIT_PREFLIGHT_EDGE_COUNT_MISMATCH',1;
IF JSON_VALUE(@new_body,'$.attestation.structured')<>N'true' THROW 51000,N'CIRCUIT_PREFLIGHT_ATTESTATION_NOT_STRUCTURED',1;

-- ============================== PROOF ==============================
SELECT '1_claim' AS result_set, @port AS port_id,
 CONVERT(bit,CASE WHEN CHARINDEX(N'DECLARE @frontier',@selected_statement)>0 THEN 1 ELSE 0 END) AS frontier_walk_declared,
 CONVERT(bit,CASE WHEN CHARINDEX(N'DECLARE @frontier',@old_stmt)>0 THEN 1 ELSE 0 END) AS frontier_walk_was_present,
 LEN(@selected_statement) AS statement_chars;

SELECT '2_old_new_equality' AS result_set,
 'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@old_body)),2)) AS old_view_digest,
 'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@new_body)),2)) AS new_view_digest,
 CONVERT(bit,CASE WHEN @old_body=@new_body THEN 1 ELSE 0 END) AS byte_identical;

SELECT '3_reader_self_test' AS result_set,
 JSON_VALUE(@new_body,'$.contractId') AS contract_id,
 JSON_VALUE(@new_body,'$.capabilityId') AS capability_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@new_body,'$.nodes'))) AS nodes,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@new_body,'$.edges'))) AS edges,
 JSON_VALUE(@new_body,'$.attestation.structured') AS structured,
 JSON_VALUE(@new_body,'$.attestation.plannedCells') AS planned_cells,
 JSON_VALUE(@new_body,'$.attestation.observedCells') AS observed_cells;

SELECT '4_relink' AS result_set, opi.execution_operation_pk, opi.port_version_pk,
 pv.semantic_object_definition_pk, @prevver AS previous_port_version_pk
FROM model.operation_port_invocation opi
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
WHERE opi.port_version_pk=(SELECT pv2.port_version_pk FROM model.port_version pv2
 WHERE pv2.semantic_object_definition_pk=(SELECT d.semantic_object_definition_pk
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' AND d.namespace_id=@ns AND d.declared_id=@port));

COMMIT TRANSACTION;
-- Installed after the rollback dry run (proof result sets green) and the
-- from-transaction preflight: the old and the new statement returned
-- byte-identical circuit-view.v1 over the generated testimony, and the live
-- reconstructed agent-lane request (985 planned / 703 observed) closed in
-- 5.2 s against the installed 51.4 s walk with identical closure membership.
