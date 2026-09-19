-- optimize-circuit-ancestor-closure.sql
--
-- The declared `circuit` operation composes the subject invocation and serves
-- `read-capability-circuit` over its testimony and compiled plan. For the agent
-- lane (985 planned cells, 716 cell testimony entries) the read's ancestor
-- closure exceeded the SQL request bound: the live circuit request returned
-- `Execution Timeout Expired` after 603 s. The closure's `INSERT @anc ... SELECT
-- ... WHERE NOT EXISTS (...)` runs against a table variable, so the optimizer
-- estimated one row and chose a plan that rescans `@anc` as it grows (the
-- classic table-variable cardinality trap). `OPTION (RECOMPILE)` compiles the
-- insertion against the actual rows of each iteration.
--
-- Measured (same request, same pinned session): the unoptimized selected
-- statement timed out at 603 s; the recompile-injected statement returned the
-- circuit view in **18.95 s** (703 observed cells; the scratch preflight passed
-- no planned cells, so `structured` was false only because the observed cells
-- had no plan to match). No view-model, attestation or ordering rule changes:
-- one query hint is added to the retained statement.
--
-- This migration re-declares only the `read-capability-circuit-port`
-- definition: it reads the selected semantics, replaces the closure's insert
-- terminator with the hinted terminator, then mints and relinks the port version
-- exactly as add-catalogue-circuit-availability.sql does. The `sidefx_reader`
-- grants are unchanged.
--
-- Idempotent: a second run finds `OPTION (RECOMPILE)` in the selected statement
-- and re-declares nothing.
--
-- Lifecycle: default was ROLLBACK. Installed 2026-09-19 after the rollback dry
-- run and the from-transaction preflight on the uncommitted rows (the declared
-- read returned circuit-view.v1 with the attestation structured true over the
-- synthetic fixture). Live after install: the agent-lane circuit request
-- returned in 76 s through the installed kernel and in 75.7 s through sfx with
-- 54 nodes / 53 edges, 985 planned / 703 observed cells, 0 misses, 282
-- unselected planned and the attestation structured true; the pre-fix request
-- exceeded the 603 s SQL request bound.
--
-- Proof result sets:
--   1_claim           the retained statement carries the hint; shape is the
--                     expected single closure insert
--   2_reader_self_test the read executes over synthetic testimony and returns
--                     circuit-view.v1 with the ancestor attestation
--   3_relink          the invocation points at the re-declared port version
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

-- ============================== THE HINT ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @ns nvarchar(400)=N'sidefx:capability:read-capability-circuit' COLLATE Latin1_General_100_BIN2;
DECLARE @port nvarchar(400)=N'read-capability-circuit-port' COLLATE Latin1_General_100_BIN2;
DECLARE @sem nvarchar(max), @stmt nvarchar(max), @optimized nvarchar(max), @prevver bigint,
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
IF CHARINDEX(N'OPTION (RECOMPILE)',@stmt)=0
BEGIN
 IF @prevver IS NULL THROW 51000,N'CIRCUIT_READER_PORT_VERSION_MISSING',1;
 SET @optimized=REPLACE(@stmt,N'AND x.candidate=v.candidate);',N'AND x.candidate=v.candidate) OPTION (RECOMPILE);');
 IF @optimized=@stmt THROW 51000,N'CIRCUIT_ANCESTOR_CLOSURE_SHAPE_UNRECOGNIZED',1;
 SET @sem=JSON_MODIFY(@sem,'$.configuration.statement',@optimized);
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
IF CHARINDEX(N'OPTION (RECOMPILE)',@selected_statement)=0 THROW 51000,N'CIRCUIT_RECOMPILE_NOT_SELECTED',1;
IF CHARINDEX(N'x.candidate=v.candidate) OPTION (RECOMPILE);',@selected_statement)=0 THROW 51000,N'CIRCUIT_RECOMPILE_NOT_ON_CLOSURE',1;
DECLARE @sample nvarchar(max)=N'{"contractId":"circuit-view-request.v1","payload":{"capabilityId":"circuit-recompile-self-test","cellTestimony":[{"cellId":"cell:scenario:demo","cellAltitude":"scenario","disposition":"completed","outcomeClassification":"success","durationMilliseconds":5,"completedAt":"2026-09-18T00:00:00.005Z","logicalOrder":0},{"cellId":"cell:mechanic:demo.operation.1","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":3,"completedAt":"2026-09-18T00:00:00.011Z","logicalOrder":3}],"edgeTestimony":[{"edgeId":"edge:sequence:demo:1","sourceCellExecutionId":"execution:graph:demo:cell:mechanic:demo.operation.1:1","destinationCellId":"cell:scenario:demo","admissionDisposition":"admitted","logicalOrder":2}],"plannedCells":[{"cellId":"cell:scenario:demo","parentCellId":null,"altitude":"scenario"},{"cellId":"cell:mechanic:demo.operation.1","parentCellId":"cell:scenario:demo","altitude":"mechanic"}],"plannedEdges":[]}}';
DECLARE @view TABLE (value nvarchar(max));
INSERT @view EXEC sp_executesql @selected_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
IF (SELECT COUNT(*) FROM @view)<>1 THROW 51000,N'CIRCUIT_READER_SELF_TEST_NOT_SINGULAR',1;
DECLARE @view_body nvarchar(max)=(SELECT value FROM @view);
IF JSON_VALUE(@view_body,'$.contractId')<>N'circuit-view.v1' THROW 51000,N'CIRCUIT_READER_SELF_TEST_CONTRACT_MISMATCH',1;
IF JSON_VALUE(@view_body,'$.capabilityId')<>N'circuit-recompile-self-test' THROW 51000,N'CIRCUIT_READER_SELF_TEST_CAPABILITY_MISMATCH',1;
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.nodes')))<>2 THROW 51000,N'CIRCUIT_READER_SELF_TEST_NODE_COUNT_MISMATCH',1;
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.edges')))<>1 THROW 51000,N'CIRCUIT_READER_SELF_TEST_EDGE_COUNT_MISMATCH',1;
IF JSON_VALUE(@view_body,'$.attestation.structured')<>N'true' THROW 51000,N'CIRCUIT_READER_SELF_TEST_ATTESTATION_NOT_STRUCTURED',1;

-- ============================== PROOF ==============================
SELECT '1_claim' AS result_set, @port AS port_id,
 CONVERT(bit,CASE WHEN CHARINDEX(N'OPTION (RECOMPILE)',@selected_statement)>0 THEN 1 ELSE 0 END) AS recompile_declared,
 (LEN(@selected_statement)-LEN(REPLACE(@selected_statement,N'OPTION (RECOMPILE)',N'')))/LEN(N'OPTION (RECOMPILE)') AS recompile_occurrences,
 LEN(@selected_statement) AS statement_chars;

SELECT '2_reader_self_test' AS result_set,
 JSON_VALUE(@view_body,'$.contractId') AS contract_id,
 JSON_VALUE(@view_body,'$.capabilityId') AS capability_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.nodes'))) AS nodes,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.edges'))) AS edges,
 JSON_VALUE(@view_body,'$.attestation.structured') AS structured,
 JSON_VALUE(@view_body,'$.attestation.observedCells') AS observed_cells;

SELECT '3_relink' AS result_set, opi.execution_operation_pk, opi.port_version_pk,
 pv.semantic_object_definition_pk, @prevver AS previous_port_version_pk
FROM model.operation_port_invocation opi
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
WHERE opi.port_version_pk=(SELECT pv2.port_version_pk FROM model.port_version pv2
 WHERE pv2.semantic_object_definition_pk=(SELECT d.semantic_object_definition_pk
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' AND d.namespace_id=@ns AND d.declared_id=@port));

COMMIT TRANSACTION;
-- Installed 2026-09-19 after the rollback dry run (proof result sets green) and
-- the from-transaction preflight on the uncommitted rows.
