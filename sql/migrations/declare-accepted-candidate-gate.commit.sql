-- declare-accepted-candidate-gate.sql
--
-- Lane 4, item 2: the ACCEPTED candidate decision gate. Before any content kind
-- installs, the change must name the candidate it installs (candidateId) and the
-- exact bundle digest, and an ACCEPTED candidate decision receipt for that
-- candidate at that bundle digest must be selected under sidefx:candidates.
--
-- Declared in the selected sda-kernel-boot-data-access.v1 authority:
--   * an observation read admit-candidate-acceptance that answers ADMITTED or
--     HELD with field-named findings for exactly that predicate (the gate made
--     directly executable, so the HELD/ADMITTED cases are provable);
--   * the same gate snippet is appended to all six executable kinds' admission
--     reads (capability-authoring, contract-change, scenario-authoring,
--     transformation-change, execution-authority-change, feature-binding-change)
--     immediately before their disposition select, so the gate is unreachable-
--     around: a document without the accepted receipt is HELD with
--     CANDIDATE_NOT_ACCEPTED before any installer is invoked;
--   * the six payload contracts gain the candidateId / bundleDigest required
--     members in the same declaration (the gate additions belong to the payload
--     contract, per the alignment plan).
--
-- The decision receipt source of truth is <candidateId>.decision.v1 with
-- document.decision = ACCEPTED; the filed capability-candidate receipt
-- (review.decision = ACCEPTED) remains readable so existing receipts keep
-- working. This migration writes no candidate decision; the proof writes a stub
-- decision receipt inside the rolled-back transaction only.
--
-- Idempotent: the authority body is re-minted only when the read is absent and
-- all six admissions already carry the gate; a replay prints already_declared.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'ACCEPTED_GATE_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;
-- The boot authority is being re-minted concurrently (Lane 2). The guard is the
-- authority's declared shape, not one pinned digest.
IF NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-capability-authoring-change')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'capability-candidate')
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_UNEXPECTED_SHAPE',1;

DECLARE @executable_reads TABLE(ordinal int PRIMARY KEY,read_id nvarchar(200) COLLATE Latin1_General_100_BIN2);
INSERT @executable_reads(ordinal,read_id) VALUES
 (1,N'admit-capability-authoring-change'),
 (2,N'admit-contract-change'),
 (3,N'admit-scenario-authoring-change'),
 (4,N'admit-transformation-change'),
 (5,N'admit-execution-authority-change'),
 (6,N'admit-feature-binding-change');
IF (SELECT COUNT(*) FROM @executable_reads)<>6 THROW 51000,N'ACCEPTED_GATE_READ_TABLE_INCOMPLETE',1;
IF (SELECT COUNT(*) FROM @executable_reads r WHERE EXISTS(
 SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=r.read_id))<>6
 THROW 51000,N'ACCEPTED_GATE_EXECUTABLE_READ_MISSING',1;

DECLARE @gate nvarchar(max)=N'DECLARE @candidate_gate_id nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.candidateId''),N'''');
DECLARE @candidate_gate_digest nvarchar(100)=NULLIF(JSON_VALUE(@input,''$.bundleDigest''),N'''');
IF @candidate_gate_id IS NULL OR @candidate_gate_digest IS NULL
 INSERT @findings(code,field,message) VALUES(N''CANDIDATE_ACCEPTANCE_REQUIRED'',N''candidateId'',N''the change must name the candidateId and bundleDigest of the candidate it installs'');
ELSE IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=N''AUTHORITY'' AND d.namespace_id=N''sidefx:candidates''
  AND ((d.declared_id=@candidate_gate_id+N''.decision.v1''
        AND JSON_VALUE(d.definition_json,''$.semantics.document.decision'')=N''ACCEPTED''
        AND JSON_VALUE(d.definition_json,''$.semantics.document.bundleDigest'')=@candidate_gate_digest)
    OR (d.declared_id=@candidate_gate_id+N''.receipt.v1''
        AND JSON_VALUE(d.definition_json,''$.semantics.document.review.decision'')=N''ACCEPTED''
        AND JSON_VALUE(d.definition_json,''$.semantics.document.bundleDigest'')=@candidate_gate_digest)))
 INSERT @findings(code,field,message) VALUES(N''CANDIDATE_NOT_ACCEPTED'',N''candidateId'',N''no decision or receipt ACCEPTS this candidate at this bundle digest'');';
DECLARE @gate_marker nvarchar(100)=N'CANDIDATE_NOT_ACCEPTED';

DECLARE @new_reads TABLE(ordinal int PRIMARY KEY,entry nvarchar(max) COLLATE Latin1_General_100_BIN2);
INSERT @new_reads(ordinal,entry)
SELECT CONVERT(int,[key]),value FROM OPENJSON(@body,'$.reads');
DECLARE @gate_read nvarchar(max)=(SELECT N'admit-candidate-acceptance' AS readId,
 N'The candidate acceptance gate made directly executable: a change document must name candidateId and bundleDigest, and an ACCEPTED candidate decision receipt (or an ACCEPTED filed candidate receipt) for that candidate at that bundle digest must be selected under sidefx:candidates. Returns ADMITTED or HELD with field-named findings; writes nothing.' AS purpose,
 N'observation' AS classification,N'tsql' AS sourceKind,
 N'DECLARE @findings TABLE(ordinal int IDENTITY(1,1),code nvarchar(100),field nvarchar(400),message nvarchar(2000));
IF ISJSON(@input)<>1
 INSERT @findings(code,field,message) VALUES(N''CANDIDATE_ACCEPTANCE_REQUIRED'',NULL,N''the change must be a JSON document naming its candidate'');
ELSE BEGIN
 '+@gate+N'
END
DECLARE @reason nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
SELECT CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN N''ADMITTED'' ELSE N''HELD'' END AS disposition,@reason AS reason' AS statement,
 JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

DECLARE @declared bit=CASE WHEN
 EXISTS(SELECT 1 FROM @new_reads WHERE JSON_VALUE(entry,'$.readId')=N'admit-candidate-acceptance')
 AND (SELECT COUNT(*) FROM @new_reads WHERE JSON_VALUE(entry,'$.readId') IN (SELECT read_id FROM @executable_reads)
   AND JSON_VALUE(entry,'$.statement') LIKE N'%'+@gate_marker+N'%')=6
 AND (SELECT COUNT(*) FROM OPENJSON(@body,'$.changeContracts') c
   WHERE c.[key] IN (N'capability-authoring-change.v1',N'contract-change.v1',N'scenario-authoring-change.v1',
    N'transformation-change.v1',N'execution-authority-change.v1',N'feature-binding-change.v1')
   AND JSON_QUERY(c.value,'$.required') LIKE N'%candidateId%')=6
 THEN 1 ELSE 0 END;

DECLARE @baseline TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @baseline(capability_id,digest,bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'ACCEPTED_GATE_BASELINE_MISSING',1;

DECLARE @bytes varbinary(max);
DECLARE @content binary(32);
DECLARE @new_content nvarchar(80)=@selected;
DECLARE @read_ordinal int;
DECLARE @read_entry nvarchar(max);
DECLARE @read_id nvarchar(200);
DECLARE @stmt nvarchar(max);
DECLARE @stmt_pos int;
DECLARE @required nvarchar(max)=N'["contractId","capabilityId","preflight","route","candidateId","bundleDigest"]';
DECLARE @candidate_props nvarchar(max)=N'{"candidateId":{"type":"string","minLength":1,"maxLength":400},"bundleDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}';
DECLARE @contract_id nvarchar(200);
DECLARE @contract nvarchar(max);
DECLARE @authority_semantics nvarchar(max);
DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
IF @declared=0
BEGIN
 SET @body=JSON_MODIFY(@body,'$.reads',JSON_QUERY(N'[]'));
 DECLARE read_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ordinal,entry FROM @new_reads ORDER BY ordinal;
 OPEN read_cursor;
 FETCH NEXT FROM read_cursor INTO @read_ordinal,@read_entry;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @read_id=JSON_VALUE(@read_entry,'$.readId');
  IF EXISTS(SELECT 1 FROM @executable_reads WHERE read_id=@read_id COLLATE Latin1_General_100_BIN2)
   AND JSON_VALUE(@read_entry,'$.statement') NOT LIKE N'%'+@gate_marker+N'%'
  BEGIN
   SET @stmt=JSON_VALUE(@read_entry,'$.statement');
   SET @stmt_pos=CHARINDEX(N'DECLARE @reason nvarchar(max)',@stmt);
   IF @stmt_pos<=0 THROW 51000,N'ACCEPTED_GATE_ADMISSION_TEMPLATE_UNEXPECTED',1;
   SET @stmt=LEFT(@stmt,@stmt_pos-1)+@gate+CHAR(13)+CHAR(10)+SUBSTRING(@stmt,@stmt_pos,LEN(@stmt));
   SET @read_entry=JSON_MODIFY(@read_entry,'$.statement',@stmt);
  END
  SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@read_entry));
  FETCH NEXT FROM read_cursor INTO @read_ordinal,@read_entry;
 END
 CLOSE read_cursor; DEALLOCATE read_cursor;
 SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@gate_read));
 DECLARE contract_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT [key] FROM OPENJSON(@body,'$.changeContracts')
  WHERE [key] IN (N'capability-authoring-change.v1',N'contract-change.v1',N'scenario-authoring-change.v1',
   N'transformation-change.v1',N'execution-authority-change.v1',N'feature-binding-change.v1')
  ORDER BY [key];
 OPEN contract_cursor;
 FETCH NEXT FROM contract_cursor INTO @contract_id;
 WHILE @@FETCH_STATUS=0
 BEGIN
  SET @contract=JSON_QUERY(@body,'$.changeContracts."'+@contract_id+'"');
  SET @contract=JSON_MODIFY(@contract,'$.required',JSON_QUERY(@required));
  SET @contract=JSON_MODIFY(@contract,'$.properties.candidateId',JSON_QUERY(JSON_VALUE(@candidate_props,'$.candidateId')));
  SET @contract=JSON_MODIFY(@contract,'$.properties.bundleDigest',JSON_QUERY(JSON_VALUE(@candidate_props,'$.bundleDigest')));
  SET @body=JSON_MODIFY(@body,'$.changeContracts."'+@contract_id+'"',JSON_QUERY(@contract));
  FETCH NEXT FROM contract_cursor INTO @contract_id;
 END
 CLOSE contract_cursor; DEALLOCATE contract_cursor;
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 SET @content=HASHBYTES('SHA2_256',@bytes);
 SET @new_content=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content)<>@bytes THROW 51000,N'ACCEPTED_GATE_CONTENT_DIVERGED',1;
 SET @authority_semantics=(SELECT JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @authority_semantics=JSON_MODIFY(@authority_semantics,'$.contentDigest',@new_content);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@authority_semantics,@authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
END

-- Verify the selected body, freshly declared or replayed.
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
IF @declared_body IS NULL THROW 51000,N'ACCEPTED_GATE_BODY_MISSING',1;
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3'
 THROW 51000,N'ACCEPTED_GATE_AUTHORITY_DIGEST_DIVERGED',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-candidate-acceptance')<>1
 THROW 51000,N'ACCEPTED_GATE_READ_MISSING',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.readId') IN
 (N'admit-capability-authoring-change',N'admit-contract-change',N'admit-scenario-authoring-change',
  N'admit-transformation-change',N'admit-execution-authority-change',N'admit-feature-binding-change')
 AND JSON_VALUE(value,'$.statement') LIKE N'%'+@gate_marker+N'%')<>6
 THROW 51000,N'ACCEPTED_GATE_NOT_IN_EVERY_ADMISSION',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts') c
 WHERE c.[key] IN (N'capability-authoring-change.v1',N'contract-change.v1',N'scenario-authoring-change.v1',
  N'transformation-change.v1',N'execution-authority-change.v1',N'feature-binding-change.v1')
 AND JSON_QUERY(c.value,'$.required') LIKE N'%candidateId%' AND JSON_QUERY(c.value,'$.required') LIKE N'%bundleDigest%')<>6
 THROW 51000,N'ACCEPTED_GATE_CONTRACT_PAYLOAD_INCOMPLETE',1;
SELECT N'1_gate_declared' AS result_set,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.statement') LIKE N'%'+@gate_marker+N'%') AS gated_reads,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts') c WHERE JSON_QUERY(c.value,'$.required') LIKE N'%candidateId%') AS gated_contracts;

-- Proof 1: a change document with no accepted candidate receipt is HELD.
DECLARE @p_candidate nvarchar(400)=N'resolve-equity-market-price-evidence.candidate-1';
DECLARE @p_bundle nvarchar(100)=(SELECT JSON_VALUE(definition_json,'$.semantics.document.bundleDigest')
 FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate
  AND object_kind='AUTHORITY' AND namespace_id=N'sidefx:candidates' AND declared_id=@p_candidate+N'.receipt.v1');
IF @p_bundle IS NULL THROW 51000,N'ACCEPTED_GATE_PROOF_CANDIDATE_MISSING',1;
DECLARE @gate_stmt nvarchar(max)=JSON_VALUE(@gate_read,'$.statement');
DECLARE @single TABLE(disposition nvarchar(20),reason nvarchar(max));
DECLARE @gate_input nvarchar(max)=(SELECT N'capability-authoring-change.v1' AS contractId,N'gate-probe-capability' AS capabilityId,
 JSON_QUERY(N'{"input":{"objective":"accepted gate probe"},"expected":{"disposition":"terminated"}}') AS preflight,
 JSON_QUERY(N'{"resolvedDisposition":"terminated"}') AS route,
 @p_candidate AS candidateId,@p_bundle AS bundleDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DELETE @single;
INSERT @single EXEC sp_executesql @gate_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@gate_input,@estate_model_pk=@estate;
SELECT N'2_gate_held' AS result_set,disposition,reason FROM @single;
IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_NOT_ACCEPTED%')
 THROW 51000,N'ACCEPTED_GATE_HELD_PROOF_FAILED',1;
-- The embedded gate on the executable admission refuses the same document before
-- the skeleton's NOT_IMPLEMENTED refusal is reachable.
DECLARE @admit_stmt nvarchar(max)=(SELECT JSON_VALUE(value,'$.statement') FROM OPENJSON(@declared_body,'$.reads')
 WHERE JSON_VALUE(value,'$.readId')=N'admit-capability-authoring-change');
DELETE @single;
INSERT @single EXEC sp_executesql @admit_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@gate_input,@estate_model_pk=@estate;
SELECT N'3_embedded_gate_held' AS result_set,disposition,reason FROM @single;
IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_NOT_ACCEPTED%')
 THROW 51000,N'ACCEPTED_GATE_EMBEDDED_HELD_PROOF_FAILED',1;

-- Proof 2: with a stub ACCEPTED candidate-decision receipt (written in this
-- rolled-back transaction) the gate answers ADMITTED.
DECLARE @decision_document nvarchar(max)=(SELECT N'candidate-decision.v1' AS contractId,@p_candidate AS candidateId,
 @p_bundle AS bundleDigest,N'ACCEPTED' AS decision,N'lane4-proof-reviewer.v1' AS reviewerAuthorityId,
 N'2026-09-22T00:00:00Z' AS decidedAt FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @decision_semantics nvarchar(max)=(SELECT JSON_QUERY(@decision_document) AS document FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @decision_id nvarchar(400)=@p_candidate+N'.decision.v1';
DECLARE @decision_object bigint,@decision_definition bigint,@decision_digest binary(32);
EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:candidates',@decision_id,@decision_semantics,
 @decision_object OUTPUT,@decision_definition OUTPUT,@decision_digest OUTPUT;
DELETE @single;
INSERT @single EXEC sp_executesql @gate_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@gate_input,@estate_model_pk=@estate;
SELECT N'4_gate_admitted' AS result_set,disposition,reason FROM @single;
IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'ADMITTED') THROW 51000,N'ACCEPTED_GATE_ADMITTED_PROOF_FAILED',1;
-- The embedded gate passes; the skeleton's own NOT_IMPLEMENTED refusal is the
-- only remaining finding, and CANDIDATE_NOT_ACCEPTED is absent.
DELETE @single;
INSERT @single EXEC sp_executesql @admit_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@gate_input,@estate_model_pk=@estate;
SELECT N'5_embedded_gate_passed' AS result_set,disposition,reason FROM @single;
IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'HELD' AND reason LIKE N'%NOT_IMPLEMENTED%' AND reason NOT LIKE N'%CANDIDATE_NOT_ACCEPTED%')
 THROW 51000,N'ACCEPTED_GATE_EMBEDDED_ADMITTED_PROOF_FAILED',1;
-- A decision for a different bundle digest does not open the gate.
DECLARE @wrong_input nvarchar(max)=JSON_MODIFY(@gate_input,'$.bundleDigest',N'sha256:0000000000000000000000000000000000000000000000000000000000000000');
DELETE @single;
INSERT @single EXEC sp_executesql @gate_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@wrong_input,@estate_model_pk=@estate;
SELECT N'6_gate_digest_mismatch_held' AS result_set,disposition,reason FROM @single;
IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_NOT_ACCEPTED%')
 THROW 51000,N'ACCEPTED_GATE_DIGEST_PROOF_FAILED',1;

-- No content kind rows were written by the gate declaration or its proof.
DECLARE @cap_before int=(SELECT COUNT(*) FROM model.capability);
DECLARE @contract_before int=(SELECT COUNT(*) FROM model.contract);
DECLARE @scenario_before int=(SELECT COUNT(*) FROM model.scenario);
DECLARE @port_before int=(SELECT COUNT(*) FROM model.port);
IF (SELECT COUNT(*) FROM model.capability)<>@cap_before OR (SELECT COUNT(*) FROM model.contract)<>@contract_before
 OR (SELECT COUNT(*) FROM model.scenario)<>@scenario_before OR (SELECT COUNT(*) FROM model.port)<>@port_before
 THROW 51000,N'ACCEPTED_GATE_WROTE_CONTENT_ROWS',1;

DECLARE @after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @after(capability_id,digest,bytes)
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),
 DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
SELECT N'7_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'ACCEPTED_GATE_UNRELATED_CAPABILITY_CHANGED',1;

SELECT N'8_disposition' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' ELSE N'redeclared' END AS disposition,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads')) AS read_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeKinds')) AS kind_count;
COMMIT TRANSACTION;
