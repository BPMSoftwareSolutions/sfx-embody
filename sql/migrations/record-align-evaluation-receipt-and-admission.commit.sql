-- record-align-evaluation-receipt-and-admission.sql
--
-- Lane 4, item 1: declare the receipt-only `alignment-evaluation` change kind
-- and the STUB evaluator that records the ten alignment dimensions and a canned
-- convergence distance for a filed candidate bundle.
--
-- Declared in the selected sda-kernel-boot-data-access.v1 authority:
--   * a changeKinds row: changeKind `alignment-evaluation`, payload contract
--     `alignment-evaluation.v1` (already a live changeContracts entry), the
--     record-alignment-evaluation install operation and the bounded
--     capability-invocation verification recipe;
--   * a changeAdmissions row granting exactly model.record_alignment_evaluation
--     with the model-write-guards suspension set, observation read
--     admit-alignment-evaluation and result change-admitted.v1;
--   * a changeOperations row (classification effect, serializable, guards
--     restored);
--   * an observation admission read admit-alignment-evaluation that validates
--     the document against the alignment-evaluation.v1 receipt contract, checks
--     the candidate was filed with the named bundle digest, and refuses with
--     field-named findings (a missing dimensions block is accepted only because
--     the stub fills it; a present one must name exactly the ten dimensions
--     with legal dispositions);
--   * the result contract alignment-evaluation-recorded.v1.
--
-- STUB evaluator: model.record_alignment_evaluation writes exactly one
-- AUTHORITY receipt under sidefx:candidates at <candidateId>.alignment.v1. It
-- writes no capability, contract, scenario, port, transformation, provider or
-- TOOL row; a receipt is not executable machinery. The canned evaluation is the
-- ten declared dimensions with three named CANNED_STUB repairs (estate, proof,
-- novelty) and convergenceDistance 3, so the stub is self-consistent and
-- unmistakably a stub. Byte-identical replay returns already_installed; a
-- different evaluation for the same receipt id is refused.
--
-- Idempotent: the authority body is re-minted only when the kind, admission,
-- read, operation and result contract are absent; the procedure is CREATE OR
-- ALTER; a replay prints already_declared and writes nothing.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'ALIGNMENT_EVALUATION_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
CREATE OR ALTER PROCEDURE model.record_alignment_evaluation @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'ALIGNMENT_EVALUATION_TRANSACTION_REQUIRED',1;
 IF ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'alignment-evaluation.v1'
  THROW 51000,'ALIGNMENT_EVALUATION_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @candidate nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.candidateId'),N'');
 DECLARE @bundle nvarchar(100)=NULLIF(JSON_VALUE(@document,'$.bundleDigest'),N'');
 IF @candidate IS NULL OR @bundle IS NULL THROW 51000,'ALIGNMENT_EVALUATION_CANDIDATE_REQUIRED',1;
 DECLARE @receipt nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics.document')
  FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate
   AND object_kind='AUTHORITY' AND namespace_id=N'sidefx:candidates' AND declared_id=@candidate+N'.receipt.v1');
 IF @receipt IS NULL THROW 51000,'ALIGNMENT_EVALUATION_CANDIDATE_NOT_FILED',1;
 IF JSON_VALUE(@receipt,'$.bundleDigest')<>@bundle THROW 51000,'ALIGNMENT_EVALUATION_BUNDLE_DIGEST_MISMATCH',1;
 -- The canned STUB evaluation: ten dimensions, three named repairs, distance 3.
 DECLARE @stub_distance int=3;
 DECLARE @stub_dimensions nvarchar(max)=N'{"intent":{"disposition":"ALIGNED","findings":[]},'
  +N'"scenario":{"disposition":"ALIGNED","findings":[]},'
  +N'"semantic-altitude":{"disposition":"ALIGNED","findings":[]},'
  +N'"estate":{"disposition":"REPAIR","findings":["CANNED_STUB: estate reuse is not evaluated by the stub evaluator"]},'
  +N'"topology":{"disposition":"ALIGNED","findings":[]},'
  +N'"authority":{"disposition":"ALIGNED","findings":[]},'
  +N'"provider":{"disposition":"ALIGNED","findings":[]},'
  +N'"proof":{"disposition":"REPAIR","findings":["CANNED_STUB: proof obligations are not evaluated by the stub evaluator"]},'
  +N'"novelty":{"disposition":"REPAIR","findings":["CANNED_STUB: novelty is not evaluated by the stub evaluator"]},'
  +N'"admission":{"disposition":"ALIGNED","findings":[]}}';
 SET @document=JSON_MODIFY(@document,'$.evaluationId',ISNULL(NULLIF(JSON_VALUE(@document,'$.evaluationId'),N''),@candidate+N'.stub-alignment.v1'));
 SET @document=JSON_MODIFY(@document,'$.evaluatorAuthorityId',ISNULL(NULLIF(JSON_VALUE(@document,'$.evaluatorAuthorityId'),N''),N'stub-alignment-evaluator.v1'));
 IF JSON_QUERY(@document,'$.dimensions') IS NULL SET @document=JSON_MODIFY(@document,'$.dimensions',JSON_QUERY(@stub_dimensions));
 IF JSON_VALUE(@document,'$.convergenceDistance') IS NULL SET @document=JSON_MODIFY(@document,'$.convergenceDistance',@stub_distance);
 DECLARE @receipt_id nvarchar(400)=@candidate+N'.alignment.v1';
 DECLARE @digest nvarchar(100)=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@document COLLATE Latin1_General_100_BIN2_UTF8))),2));
 DECLARE @prior nvarchar(100)=(SELECT JSON_VALUE(definition_json,'$.semantics.evaluationDigest')
  FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate
   AND object_kind='AUTHORITY' AND namespace_id=N'sidefx:candidates' AND declared_id=@receipt_id);
 IF @prior IS NOT NULL
 BEGIN
  IF @prior<>@digest THROW 51000,'ALIGNMENT_EVALUATION_REVISION_NOT_ADMITTED',1;
  SELECT N'already_installed' AS result_set,@candidate AS candidate_id,@receipt_id AS receipt_id,@digest AS evaluation_digest;
  RETURN;
 END
 DECLARE @semantics nvarchar(max)=(SELECT JSON_QUERY(@document) AS document,@digest AS evaluationDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@definition_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:candidates',@receipt_id,@semantics,@object OUTPUT,@definition OUTPUT,@definition_digest OUTPUT;
 SELECT N'alignment_evaluation_recorded' AS result_set,@candidate AS candidate_id,@receipt_id AS receipt_id,
  @digest AS evaluation_digest,JSON_VALUE(@document,'$.convergenceDistance') AS convergence_distance,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@document,'$.dimensions'))) AS dimension_count;
END;
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
-- authority's declared shape, not one pinned digest: the base admission reads the
-- wave installs must be present and the authority identity digest must not drift.
IF NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-capability-authoring-change')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'capability-candidate')
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_UNEXPECTED_SHAPE',1;

DECLARE @declared bit=CASE WHEN
 EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'alignment-evaluation')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeAdmissions') WHERE JSON_VALUE(value,'$.readId')=N'admit-alignment-evaluation')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-alignment-evaluation')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeOperations') WHERE JSON_VALUE(value,'$.changeId')=N'record-alignment-evaluation')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'alignment-evaluation-recorded.v1')
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
IF (SELECT COUNT(*) FROM @baseline)<>3 THROW 51000,N'ALIGNMENT_EVALUATION_BASELINE_MISSING',1;

DECLARE @admit_stmt nvarchar(max)=N'DECLARE @findings TABLE(ordinal int IDENTITY(1,1),code nvarchar(100),field nvarchar(400),message nvarchar(2000));
IF ISJSON(@input)<>1
 INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_DOCUMENT_REQUIRED'',NULL,N''the evaluation must be a JSON alignment-evaluation.v1'');
ELSE BEGIN
 DECLARE @candidate nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.candidateId''),N'''');
 DECLARE @bundle nvarchar(100)=NULLIF(JSON_VALUE(@input,''$.bundleDigest''),N'''');
 IF JSON_VALUE(@input,''$.contractId'')<>N''alignment-evaluation.v1''
  INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be alignment-evaluation.v1'');
 IF @candidate IS NULL
  INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_CANDIDATE_REQUIRED'',N''candidateId'',N''the evaluation must name the filed candidate it evaluates'');
 IF @bundle IS NULL OR @bundle NOT LIKE N''sha256:[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]''
  INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_DIGEST_REQUIRED'',N''bundleDigest'',N''bundleDigest must be a sha256 bundle digest'');
 IF JSON_VALUE(@input,''$.evaluationId'') IS NULL
  INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_ID_REQUIRED'',N''evaluationId'',N''the evaluation must declare its evaluationId'');
 IF JSON_VALUE(@input,''$.evaluatorAuthorityId'') IS NULL
  INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_EVALUATOR_REQUIRED'',N''evaluatorAuthorityId'',N''the evaluation must name the evaluator authority that produced it'');
 IF @candidate IS NOT NULL AND @bundle IS NOT NULL AND NOT EXISTS(
  SELECT 1 FROM analysis.v_selected_semantic_definition r WHERE r.estate_model_pk=@estate_model_pk
   AND r.object_kind=''AUTHORITY'' AND r.namespace_id=N''sidefx:candidates'' AND r.declared_id=@candidate+N''.receipt.v1''
   AND JSON_VALUE(r.definition_json,''$.semantics.document.bundleDigest'')=@bundle)
  INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_CANDIDATE_NOT_FILED'',N''candidateId'',N''no filed candidate receipt matches this candidateId and bundleDigest'');
 IF JSON_QUERY(@input,''$.dimensions'') IS NOT NULL BEGIN
  IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@input,''$.dimensions'')) d WHERE d.[key] IN
   (N''intent'',N''scenario'',N''semantic-altitude'',N''estate'',N''topology'',N''authority'',N''provider'',N''proof'',N''novelty'',N''admission''))<>10
   INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_DIMENSIONS_INCOMPLETE'',N''dimensions'',N''a present dimensions block must name exactly the ten declared dimensions'');
  IF EXISTS(SELECT 1 FROM OPENJSON(JSON_QUERY(@input,''$.dimensions'')) d WHERE d.[key] NOT IN
   (N''intent'',N''scenario'',N''semantic-altitude'',N''estate'',N''topology'',N''authority'',N''provider'',N''proof'',N''novelty'',N''admission''))
   INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_DIMENSION_UNDECLARED'',N''dimensions'',N''the dimensions block carries an undeclared dimension name'');
  IF EXISTS(SELECT 1 FROM OPENJSON(JSON_QUERY(@input,''$.dimensions'')) d WHERE JSON_VALUE(d.value,''$.disposition'') NOT IN (N''ALIGNED'',N''REPAIR'',N''UNRESOLVED''))
   INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_DIMENSION_DISPOSITION'',N''dimensions'',N''every dimension must dispose ALIGNED, REPAIR or UNRESOLVED'');
 END
 IF JSON_VALUE(@input,''$.convergenceDistance'') IS NOT NULL
  AND (TRY_CONVERT(int,JSON_VALUE(@input,''$.convergenceDistance'')) IS NULL OR TRY_CONVERT(int,JSON_VALUE(@input,''$.convergenceDistance''))<0)
  INSERT @findings(code,field,message) VALUES(N''ALIGNMENT_EVALUATION_DISTANCE_INVALID'',N''convergenceDistance'',N''convergenceDistance must be a non-negative integer when present'');
END
DECLARE @reason nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
SELECT CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN N''ADMITTED'' ELSE N''HELD'' END AS disposition,@reason AS reason';
DECLARE @admit_read nvarchar(max)=(SELECT N'admit-alignment-evaluation' AS readId,
 N'Validate an alignment-evaluation.v1 document against its receipt contract and the filed candidate receipt: candidate bundles must be filed, a present dimensions block must name exactly the ten declared dimensions with legal dispositions, and convergenceDistance must be a non-negative integer when present. A missing dimensions block is accepted because the stub evaluator fills it. Returns ADMITTED or HELD with field-named findings; writes nothing.' AS purpose,
 N'observation' AS classification,N'tsql' AS sourceKind,@admit_stmt AS statement,
 JSON_QUERY(N'[{"parameter":"estate_model_pk","kind":"pinned-session"}]') AS parameters
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @kind_row nvarchar(max)=(SELECT N'alignment-evaluation' AS changeKind,N'alignment-evaluation.v1' AS payloadContract,
 N'alignment-evaluation-admission.v1' AS admissionId,
 JSON_QUERY(N'{"changeId":"record-alignment-evaluation","parameterName":"document"}') AS install,
 JSON_QUERY(N'{"kind":"capability-invocation","capabilityPath":"candidateId","inputPath":"dimensions","expectedPath":"convergenceDistance","dispositionPath":"evaluationId"}') AS verification
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @admission_row nvarchar(max)=(SELECT N'alignment-evaluation-admission.v1' AS admissionId,N'ADMITTED' AS lifecycle,N'alignment-evaluation' AS changeKind,
 N'alignment-evaluation.v1' AS payloadContract,N'alignment-evaluation.v1' AS payloadAdmissionContract,
 N'record-alignment-evaluation' AS changeId,N'document' AS parameterName,
 N'admit-alignment-evaluation' AS readId,N'change-admitted.v1' AS resultContract,
 JSON_QUERY(N'{"executeProcedure":{"sourceKind":"tsql","name":"model.record_alignment_evaluation"},"suspendGuardSets":["model-write-guards"]}') AS privileges
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @operation_row nvarchar(max)=(SELECT N'record-alignment-evaluation' AS changeId,N'tsql' AS sourceKind,N'effect' AS classification,
 JSON_QUERY(N'{"kind":"procedure","name":"model.record_alignment_evaluation"}') AS operation,
 JSON_QUERY(N'[{"name":"document","contract":"alignment-evaluation.v1","binding":"parameter","encoding":"json"}]') AS parameters,
 N'alignment-evaluation-recorded.v1' AS resultContract,
 JSON_QUERY(N'{"transaction":"required","isolation":"serializable"}') AS scope,
 JSON_QUERY(N'[{"declaredGuardSuspension":"model-write-guards","restoreRequired":true}]') AS preconditions
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @recorded_contract nvarchar(max)=(SELECT N'Alignment evaluation recorded result' AS title,
 N'Result contract of the stub alignment evaluator: the recorded receipt identity, its evaluation digest, the canned convergence distance and the dimension count. The receipt grants no install power.' AS description,
 N'object' AS [type],CONVERT(bit,0) AS additionalProperties,
 JSON_QUERY(N'["result_set","candidate_id","receipt_id","evaluation_digest","convergence_distance","dimension_count"]') AS [required],
 JSON_QUERY(N'{"result_set":{"const":"alignment_evaluation_recorded"},"candidate_id":{"type":"string","minLength":1,"maxLength":400},"receipt_id":{"type":"string","minLength":1,"maxLength":400},"evaluation_digest":{"$ref":"#/$defs/digest"},"convergence_distance":{"type":"integer","minimum":0},"dimension_count":{"const":10}}') AS properties,
 JSON_QUERY(N'{"digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}') AS [$defs]
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

DECLARE @bytes varbinary(max);
DECLARE @content binary(32);
DECLARE @new_content nvarchar(80)=@selected;
IF @declared=0
BEGIN
 SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@admit_read));
 SET @body=JSON_MODIFY(@body,'append $.changeKinds',JSON_QUERY(@kind_row));
 SET @body=JSON_MODIFY(@body,'append $.changeAdmissions',JSON_QUERY(@admission_row));
 SET @body=JSON_MODIFY(@body,'append $.changeOperations',JSON_QUERY(@operation_row));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."alignment-evaluation-recorded.v1"',JSON_QUERY(@recorded_contract));
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 SET @content=HASHBYTES('SHA2_256',@bytes);
 SET @new_content=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content)<>@bytes THROW 51000,N'ALIGNMENT_EVALUATION_CONTENT_DIVERGED',1;
 DECLARE @authority_semantics nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @authority_semantics=JSON_MODIFY(@authority_semantics,'$.contentDigest',@new_content);
 DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@authority_semantics,@authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
END

-- Verify the selected body, freshly declared or replayed.
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
IF @declared_body IS NULL THROW 51000,N'ALIGNMENT_EVALUATION_BODY_MISSING',1;
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3'
 THROW 51000,N'ALIGNMENT_EVALUATION_AUTHORITY_DIGEST_DIVERGED',1;
IF (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'alignment-evaluation')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeAdmissions') WHERE JSON_VALUE(value,'$.readId')=N'admit-alignment-evaluation')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-alignment-evaluation')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeOperations') WHERE JSON_VALUE(value,'$.changeId')=N'record-alignment-evaluation')<>1
 OR (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key]=N'alignment-evaluation-recorded.v1')<>1
 THROW 51000,N'ALIGNMENT_EVALUATION_DECLARATION_INCOMPLETE',1;
IF OBJECT_ID(N'model.record_alignment_evaluation') IS NULL THROW 51000,N'ALIGNMENT_EVALUATION_INSTALLER_MISSING',1;

-- The proof candidate: the live filed bundle (do not hardcode after this line).
DECLARE @candidate nvarchar(400)=N'resolve-equity-market-price-evidence.candidate-1';
DECLARE @bundle nvarchar(100)=(SELECT JSON_VALUE(definition_json,'$.semantics.document.bundleDigest')
 FROM analysis.v_selected_semantic_definition WHERE estate_model_pk=@estate
  AND object_kind='AUTHORITY' AND namespace_id=N'sidefx:candidates' AND declared_id=@candidate+N'.receipt.v1');
IF @bundle IS NULL THROW 51000,N'ALIGNMENT_EVALUATION_PROOF_CANDIDATE_MISSING',1;
DECLARE @single TABLE(disposition nvarchar(20),reason nvarchar(max));
DECLARE @valid nvarchar(max)=(SELECT N'alignment-evaluation.v1' AS contractId,@candidate AS candidateId,@bundle AS bundleDigest,
 N'proof-evaluation-1' AS evaluationId,N'proof-evaluator.v1' AS evaluatorAuthorityId,
 JSON_QUERY(N'{"intent":{"disposition":"ALIGNED","findings":[]},"scenario":{"disposition":"ALIGNED","findings":[]},"semantic-altitude":{"disposition":"ALIGNED","findings":[]},"estate":{"disposition":"ALIGNED","findings":[]},"topology":{"disposition":"ALIGNED","findings":[]},"authority":{"disposition":"ALIGNED","findings":[]},"provider":{"disposition":"ALIGNED","findings":[]},"proof":{"disposition":"ALIGNED","findings":[]},"novelty":{"disposition":"ALIGNED","findings":[]},"admission":{"disposition":"ALIGNED","findings":[]}}') AS dimensions,
 0 AS convergenceDistance FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DELETE @single;
INSERT @single EXEC sp_executesql @admit_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@valid,@estate_model_pk=@estate;
SELECT N'1_admission_valid' AS result_set,disposition,reason FROM @single;
IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'ADMITTED') THROW 51000,N'ALIGNMENT_EVALUATION_VALID_PROOF_FAILED',1;
DECLARE @bad_disposition nvarchar(max)=JSON_MODIFY(@valid,'$.dimensions.estate.disposition',N'BROKEN');
DELETE @single;
INSERT @single EXEC sp_executesql @admit_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@bad_disposition,@estate_model_pk=@estate;
SELECT N'2_admission_bad_disposition' AS result_set,disposition,reason FROM @single;
IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'HELD' AND reason LIKE N'%DIMENSION_DISPOSITION%') THROW 51000,N'ALIGNMENT_EVALUATION_DISPOSITION_PROOF_FAILED',1;
DECLARE @unfiled nvarchar(max)=JSON_MODIFY(JSON_MODIFY(@valid,'$.candidateId',N'not-a-filed-candidate'),'$.bundleDigest',N'sha256:0000000000000000000000000000000000000000000000000000000000000000');
DELETE @single;
INSERT @single EXEC sp_executesql @admit_stmt,N'@input nvarchar(max),@estate_model_pk bigint',@input=@unfiled,@estate_model_pk=@estate;
SELECT N'3_admission_unfiled' AS result_set,disposition,reason FROM @single;
IF NOT EXISTS(SELECT 1 FROM @single WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_NOT_FILED%') THROW 51000,N'ALIGNMENT_EVALUATION_UNFILED_PROOF_FAILED',1;

-- The STUB evaluator writes the receipt in-transaction: a minimal document is
-- filled with the ten canned dimensions and the canned distance.
DECLARE @cap_before int=(SELECT COUNT(*) FROM model.capability);
DECLARE @contract_before int=(SELECT COUNT(*) FROM model.contract);
DECLARE @scenario_before int=(SELECT COUNT(*) FROM model.scenario);
DECLARE @port_before int=(SELECT COUNT(*) FROM model.port);
DECLARE @transformation_before int=(SELECT COUNT(*) FROM model.transformation);
DECLARE @stub_request nvarchar(max)=(SELECT N'alignment-evaluation.v1' AS contractId,@candidate AS candidateId,@bundle AS bundleDigest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @stub_result TABLE(result_set nvarchar(100),candidate_id nvarchar(400),receipt_id nvarchar(400),evaluation_digest nvarchar(100),convergence_distance nvarchar(40),dimension_count nvarchar(40));
INSERT @stub_result EXEC model.record_alignment_evaluation @document=@stub_request;
SELECT N'4_stub_evaluator' AS result_set,* FROM @stub_result;
IF NOT EXISTS(SELECT 1 FROM @stub_result WHERE result_set=N'alignment_evaluation_recorded' AND convergence_distance=N'3' AND dimension_count=N'10')
 THROW 51000,N'ALIGNMENT_EVALUATION_STUB_PROOF_FAILED',1;
DECLARE @replay_state TABLE(result_set nvarchar(100),candidate_id nvarchar(400),receipt_id nvarchar(400),evaluation_digest nvarchar(100));
INSERT @replay_state EXEC model.record_alignment_evaluation @document=@stub_request;
IF NOT EXISTS(SELECT 1 FROM @replay_state WHERE result_set=N'already_installed') THROW 51000,N'ALIGNMENT_EVALUATION_REPLAY_PROOF_FAILED',1;
SELECT N'5_stub_replay' AS result_set,* FROM @replay_state;
-- A revised evaluation for the same receipt id is refused.
DECLARE @revised nvarchar(max)=JSON_MODIFY(@stub_request,'$.convergenceDistance',0);
BEGIN TRY
 EXEC model.record_alignment_evaluation @document=@revised;
 THROW 51000,N'ALIGNMENT_EVALUATION_REVISION_PROOF_FAILED',1;
END TRY
BEGIN CATCH
 IF ERROR_MESSAGE() NOT LIKE N'%ALIGNMENT_EVALUATION_REVISION_NOT_ADMITTED%' THROW;
 SELECT N'6_stub_revision_refused' AS result_set,N'ALIGNMENT_EVALUATION_REVISION_NOT_ADMITTED' AS disposition;
END CATCH;
-- The recorded receipt is a receipt only: it carries the contract shape and no
-- executable row was written.
DECLARE @receipt_document nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics.document') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND namespace_id=N'sidefx:candidates' AND declared_id=@candidate+N'.alignment.v1');
SELECT N'7_receipt_recorded' AS result_set,
 JSON_VALUE(@receipt_document,'$.contractId') AS contract_id,
 JSON_VALUE(@receipt_document,'$.evaluationId') AS evaluation_id,
 JSON_VALUE(@receipt_document,'$.convergenceDistance') AS convergence_distance,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@receipt_document,'$.dimensions'))) AS dimension_count,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@receipt_document,'$.dimensions')) d WHERE JSON_VALUE(d.value,'$.disposition')=N'REPAIR') AS repairs;
IF JSON_VALUE(@receipt_document,'$.contractId')<>N'alignment-evaluation.v1' OR JSON_VALUE(@receipt_document,'$.bundleDigest')<>@bundle
 OR (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@receipt_document,'$.dimensions')))<>10
 THROW 51000,N'ALIGNMENT_EVALUATION_RECEIPT_PROOF_FAILED',1;
IF (SELECT COUNT(*) FROM model.capability)<>@cap_before OR (SELECT COUNT(*) FROM model.contract)<>@contract_before
 OR (SELECT COUNT(*) FROM model.scenario)<>@scenario_before OR (SELECT COUNT(*) FROM model.port)<>@port_before
 OR (SELECT COUNT(*) FROM model.transformation)<>@transformation_before
 THROW 51000,N'ALIGNMENT_EVALUATION_WROTE_EXECUTABLE_ROWS',1;
SELECT N'8_executable_rows_unchanged' AS result_set,@cap_before AS capabilities,@contract_before AS contracts,
 @scenario_before AS scenarios,@port_before AS ports,@transformation_before AS transformations;

-- Unrelated graph digests must be byte-identical.
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
SELECT N'9_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM @baseline b JOIN @after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'ALIGNMENT_EVALUATION_UNRELATED_CAPABILITY_CHANGED',1;

SELECT N'10_disposition' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' ELSE N'redeclared' END AS disposition,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.reads')) AS read_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeKinds')) AS kind_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeAdmissions')) AS admission_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeOperations')) AS operation_count,
 (SELECT COUNT(*) FROM OPENJSON(@declared_body,'$.changeContracts')) AS contract_count;
COMMIT TRANSACTION;
