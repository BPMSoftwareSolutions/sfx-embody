-- declare-candidate-decision-receipt.sql
--
-- Lane 3, item 4: declare the receipt-only candidate-decision kind and its
-- AUTHORITY receipt writer, per docs/model-at-each-authoring-altitude-2026-09-21/
-- candidate-admit-pipeline.md B.2 kind 9, C.2 receipt shape, E phase 5, and
-- docs/estate-mcp-and-database-expressiveness-2026-09-21/crud-operations.md 7.1:
--
--   changeContract  candidate-decision.v1            (closed payload)
--   changeContract  candidate-decision-recorded.v1   (executor recordsets envelope)
--   changeKinds     candidate-decision -> install record-candidate-decision
--   changeAdmissions candidate-decision-admission.v1 -> model.record_candidate_decision
--   changeOperations record-candidate-decision (serializable, guard restore)
--   read            admit-candidate-decision (observation)
--   procedure       model.record_candidate_decision @document
--
-- The installer writes exactly one AUTHORITY definition under sidefx:candidates,
-- declared <candidateId>.decision.v1, carrying the exact decision document and
-- its digest. Replay of the same bytes -> already_installed; different bytes ->
-- CANDIDATE_DECISION_REVISION_NOT_ADMITTED. The read refuses a decision whose
-- candidate receipt is absent, whose bundleDigest does not match the receipt, or
-- whose transition is not legal. The optional capabilityDocumentDigest on an
-- ACCEPTED decision is the revision authorization the capability-authoring
-- admission joins.
--
-- Boot authority (same selected sda-kernel-boot-data-access.v1): rows appended
-- only. The re-mint asserts structural prerequisites rather than an exact prior
-- content digest, because a parallel lane may be re-minting the same authority;
-- replay is detected from the declared kind/read/contracts themselves.
--
-- Idempotent: CREATE OR ALTER is re-runnable; the authority is re-minted only
-- when the kind, read and contracts are absent; a replay prints already_declared.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'CANDIDATE_DECISION_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
-- Unrelated capability graph digests must be byte-identical across this change.
CREATE TABLE #candidate_decision_unrelated(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT #candidate_decision_unrelated(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
IF (SELECT COUNT(*) FROM #candidate_decision_unrelated)<>3 THROW 51000,N'CANDIDATE_DECISION_BASELINE_MISSING',1;
GO
CREATE OR ALTER PROCEDURE model.record_candidate_decision @document nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 51000,'CANDIDATE_DECISION_TRANSACTION_REQUIRED',1;
 IF @document IS NULL OR ISJSON(@document)<>1 OR JSON_VALUE(@document,'$.contractId')<>N'candidate-decision.v1'
  THROW 51000,'CANDIDATE_DECISION_DOCUMENT_REQUIRED',1;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @candidate nvarchar(400)=NULLIF(JSON_VALUE(@document,'$.candidateId'),N'');
 IF @candidate IS NULL THROW 51000,'CANDIDATE_DECISION_CANDIDATE_REQUIRED',1;
 DECLARE @receipt_id nvarchar(400)=@candidate+N'.decision.v1';
 DECLARE @prior nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics.document')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=N'sidefx:candidates'
   AND d.declared_id=@receipt_id COLLATE Latin1_General_100_BIN2);
 DECLARE @digest nvarchar(100)=N'sha256:'+LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
  CONVERT(varbinary(max),CONVERT(varchar(max),@document COLLATE Latin1_General_100_BIN2_UTF8))),2));
 IF @prior IS NOT NULL
 BEGIN
  IF @prior COLLATE Latin1_General_100_BIN2<>@document COLLATE Latin1_General_100_BIN2
   THROW 51000,'CANDIDATE_DECISION_REVISION_NOT_ADMITTED',1;
  SELECT N'already_installed' AS result_set,@candidate AS candidate_id,@digest AS decision_digest;
  RETURN;
 END
 DECLARE @semantics nvarchar(max)=(SELECT JSON_QUERY(@document) AS document,@digest AS decisionDigest
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@definition_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:candidates',@receipt_id,@semantics,
  @object OUTPUT,@definition OUTPUT,@definition_digest OUTPUT;
 SELECT N'candidate_decision_recorded' AS result_set,@candidate AS candidate_id,@digest AS decision_digest;
END;
GO
-- ============================== AUTHORITY ROWS ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @selected nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
IF @selected IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@selected,N'sha256:',N''),2));
IF @body IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_BODY_MISSING',1;
IF JSON_VALUE(@body,'$.authorityId')<>@authority_id THROW 51000,N'KERNEL_BOOT_AUTHORITY_IDENTITY_DIVERGED',1;

-- Structural prerequisites: the candidate-filing seam is declared.
IF NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'capability-candidate')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-capability-candidate')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'capability-candidate-receipt.v1')
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;

DECLARE @declared bit=CASE WHEN
 EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'candidate-decision')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-candidate-decision')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'candidate-decision.v1')
 AND EXISTS(SELECT 1 FROM OPENJSON(@body,'$.changeContracts') WHERE [key]=N'candidate-decision-recorded.v1')
 THEN 1 ELSE 0 END;

IF @declared=0
BEGIN
 DECLARE @admit_statement nvarchar(max)=N'DECLARE @findings TABLE(ordinal int IDENTITY(1,1),code nvarchar(100),field nvarchar(400),message nvarchar(2000));
IF ISJSON(@input)<>1 OR JSON_QUERY(@input) IS NULL
 INSERT @findings(code,field,message) VALUES(N''CANDIDATE_DECISION_DOCUMENT_REQUIRED'',NULL,N''the decision must be a JSON object'');
ELSE BEGIN
 DECLARE @candidate nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.candidateId''),N'''');
 DECLARE @bundle nvarchar(100)=NULLIF(JSON_VALUE(@input,''$.bundleDigest''),N'''');
 DECLARE @decision nvarchar(20)=JSON_VALUE(@input,''$.decision'');
 DECLARE @reviewer nvarchar(400)=NULLIF(JSON_VALUE(@input,''$.reviewerAuthorityId''),N'''');
 IF JSON_VALUE(@input,''$.contractId'')<>N''candidate-decision.v1''
  INSERT @findings(code,field,message) VALUES(N''CANDIDATE_DECISION_CONTRACT_REQUIRED'',N''contractId'',N''contractId must be candidate-decision.v1'');
 IF @candidate IS NULL
  INSERT @findings(code,field,message) VALUES(N''CANDIDATE_DECISION_CANDIDATE_REQUIRED'',N''candidateId'',N''the decision must name the candidate it decides'');
 IF @bundle IS NULL
  INSERT @findings(code,field,message) VALUES(N''CANDIDATE_DECISION_BUNDLE_REQUIRED'',N''bundleDigest'',N''the decision must carry the bundle digest it decides'');
 IF @decision IS NULL OR @decision NOT IN (N''ACCEPTED'',N''REPAIR'',N''REJECTED'')
  INSERT @findings(code,field,message) VALUES(N''CANDIDATE_DECISION_VALUE_REQUIRED'',N''decision'',N''decision must be ACCEPTED, REPAIR or REJECTED'');
 IF @reviewer IS NULL
  INSERT @findings(code,field,message) VALUES(N''CANDIDATE_REVIEWER_REQUIRED'',N''reviewerAuthorityId'',N''the decision must name the reviewer authority'');
 IF (SELECT COUNT(*) FROM @findings)=0
 BEGIN
  DECLARE @receipt nvarchar(max)=(SELECT JSON_QUERY(definition_json,''$.semantics.document'')
   FROM analysis.v_selected_semantic_definition d WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''AUTHORITY''
    AND d.namespace_id=N''sidefx:candidates'' AND d.declared_id=@candidate+N''.receipt.v1'');
  IF @receipt IS NULL
   INSERT @findings(code,field,message) VALUES(N''CANDIDATE_RECEIPT_NOT_FOUND'',N''candidateId'',N''no candidate receipt is filed for this candidate id'');
  ELSE IF JSON_VALUE(@receipt,''$.bundleDigest'')<>@bundle
   INSERT @findings(code,field,message) VALUES(N''CANDIDATE_BUNDLE_MISMATCH'',N''bundleDigest'',N''the named bundle digest is not the filed candidate bundle digest'');
  ELSE IF JSON_VALUE(@receipt,''$.author.providerId'') IS NOT NULL AND JSON_VALUE(@receipt,''$.author.providerId'')=@reviewer
   INSERT @findings(code,field,message) VALUES(N''CANDIDATE_REVIEWER_NOT_DISTINCT'',N''reviewerAuthorityId'',N''the reviewer must be distinct from the authoring provider'');
  DECLARE @prior_decision nvarchar(max)=(SELECT JSON_QUERY(definition_json,''$.semantics.document'')
   FROM analysis.v_selected_semantic_definition d WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''AUTHORITY''
    AND d.namespace_id=N''sidefx:candidates'' AND d.declared_id=@candidate+N''.decision.v1'');
  IF @prior_decision IS NOT NULL AND JSON_VALUE(@prior_decision,''$.decision'')<>@decision
   INSERT @findings(code,field,message) VALUES(N''CANDIDATE_DECISION_REVISION_NOT_ADMITTED'',N''decision'',N''a different decision already stands for this candidate'');
 END
END
DECLARE @reason nvarchar(max)=ISNULL((SELECT code,field,message FROM @findings ORDER BY ordinal FOR JSON PATH),N''[]'');
SELECT CASE WHEN (SELECT COUNT(*) FROM @findings)=0 THEN N''ADMITTED'' ELSE N''HELD'' END AS disposition,LEFT(@reason,400) AS reason';
 DECLARE @admit_read nvarchar(max)=(SELECT N'admit-candidate-decision' AS readId,
  N'Validate a candidate-decision.v1 document: contract, candidate identity, bundle digest, decision value, reviewer, the filed candidate receipt and the legal transition. Returns exactly one ADMITTED or HELD row; writes nothing.' AS purpose,
  N'observation' AS classification,N'tsql' AS sourceKind,@admit_statement AS statement
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @decision_contract nvarchar(max)=N'{"title":"Candidate decision","description":"A reviewer decision over one filed candidate at one bundle digest. capabilityDocumentDigest, when present on an ACCEPTED decision, authorizes a revision of that exact capability document.","type":"object","additionalProperties":false,"required":["contractId","candidateId","bundleDigest","decision","reviewerAuthorityId","decidedAt","preflight"],"properties":{"contractId":{"const":"candidate-decision.v1"},"candidateId":{"type":"string","minLength":1,"maxLength":400},"bundleDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"capabilityDocumentDigest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"},"decision":{"enum":["ACCEPTED","REPAIR","REJECTED"]},"reviewerAuthorityId":{"type":"string","minLength":1,"maxLength":400},"decidedAt":{"type":"string","minLength":1,"maxLength":40},"note":{"type":"string","maxLength":2000},"preflight":{"type":"object","additionalProperties":false,"required":["capabilityId","input","expected","disposition"],"properties":{"capabilityId":{"type":"string","minLength":1,"maxLength":400},"input":{"type":"object","minProperties":1},"expected":{"type":"object"},"disposition":{"type":"string","minLength":1,"maxLength":200}}}}}';
 DECLARE @recorded_contract nvarchar(max)=N'{"title":"Candidate decision recorded","description":"Installer result: candidate_decision_recorded for a new decision receipt, already_installed for a byte-identical replay.","type":"array","minItems":1,"maxItems":1,"items":{"type":"array","minItems":1,"maxItems":1,"items":{"type":"object","additionalProperties":false,"required":["result_set","candidate_id"],"properties":{"result_set":{"enum":["candidate_decision_recorded","already_installed"]},"candidate_id":{"type":"string","minLength":1,"maxLength":400},"decision_digest":{"type":"string","pattern":"^sha256:[0-9a-f]{64}$"}}}}}';
 DECLARE @kind_row nvarchar(max)=(SELECT N'candidate-decision' AS changeKind,N'candidate-decision.v1' AS payloadContract,
  N'candidate-decision-admission.v1' AS admissionId,
  JSON_QUERY(N'{"changeId":"record-candidate-decision","parameterName":"document"}') AS install,
  JSON_QUERY(N'{"kind":"capability-invocation","capabilityPath":"preflight.capabilityId","inputPath":"preflight.input","expectedPath":"preflight.expected","dispositionPath":"preflight.disposition"}') AS verification
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @admission_row nvarchar(max)=(SELECT N'candidate-decision-admission.v1' AS admissionId,N'ADMITTED' AS lifecycle,
  N'candidate-decision' AS changeKind,N'candidate-decision.v1' AS payloadContract,N'candidate-decision.v1' AS payloadAdmissionContract,
  N'record-candidate-decision' AS changeId,N'document' AS parameterName,
  N'admit-candidate-decision' AS readId,N'change-admitted.v1' AS resultContract,
  JSON_QUERY(N'{"executeProcedure":{"sourceKind":"tsql","name":"model.record_candidate_decision"},"suspendGuardSets":["model-write-guards"]}') AS privileges
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @operation_row nvarchar(max)=(SELECT N'record-candidate-decision' AS changeId,N'tsql' AS sourceKind,N'effect' AS classification,
  JSON_QUERY(N'{"kind":"procedure","name":"model.record_candidate_decision"}') AS operation,
  JSON_QUERY(N'[{"name":"document","contract":"candidate-decision.v1","binding":"parameter","encoding":"json"}]') AS parameters,
  N'candidate-decision-recorded.v1' AS resultContract,
  JSON_QUERY(N'{"transaction":"required","isolation":"serializable"}') AS scope,
  JSON_QUERY(N'[{"declaredGuardSuspension":"model-write-guards","restoreRequired":true}]') AS preconditions
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@admit_read));
 SET @body=JSON_MODIFY(@body,'append $.changeKinds',JSON_QUERY(@kind_row));
 SET @body=JSON_MODIFY(@body,'append $.changeAdmissions',JSON_QUERY(@admission_row));
 SET @body=JSON_MODIFY(@body,'append $.changeOperations',JSON_QUERY(@operation_row));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."candidate-decision.v1"',JSON_QUERY(@decision_contract));
 SET @body=JSON_MODIFY(@body,'$.changeContracts."candidate-decision-recorded.v1"',JSON_QUERY(@recorded_contract));
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 DECLARE @new_content nvarchar(80)=N'sha256:'+LOWER(CONVERT(varchar(64),@content,2));
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 DECLARE @authority_semantics nvarchar(max)=(SELECT JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
 SET @authority_semantics=JSON_MODIFY(@authority_semantics,'$.contentDigest',@new_content);
 DECLARE @authority_object bigint,@authority_definition bigint,@authority_digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@authority_semantics,
  @authority_object OUTPUT,@authority_definition OUTPUT,@authority_digest OUTPUT;
END

DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
IF JSON_VALUE(@declared_body,'$.authorityDigest')<>N'sha256:a34639fce305a43c02c4cc5f072a4e3a98c1f1ba90ffb23739d321a9e21a7db3'
 THROW 51000,N'CANDIDATE_DECISION_AUTHORITY_DIGEST_DIVERGED',1;
IF NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'candidate-decision')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.reads') WHERE JSON_VALUE(value,'$.readId')=N'admit-candidate-decision')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@declared_body,'$.changeContracts') WHERE [key]=N'candidate-decision.v1')
 THROW 51000,N'CANDIDATE_DECISION_DECLARATION_INCOMPLETE',1;
IF OBJECT_ID(N'model.record_candidate_decision') IS NULL THROW 51000,N'CANDIDATE_DECISION_PROCEDURE_MISSING',1;
SELECT N'0_receipt_kind' AS result_set,@authority_id AS authority_id,@result_content AS content_digest,
 CASE WHEN @declared=1 THEN N'already_declared' ELSE N'declared' END AS disposition,
 JSON_VALUE(value,'$.install.changeId') AS install_change_id,JSON_VALUE(value,'$.verification.kind') AS verification
FROM OPENJSON(@declared_body,'$.changeKinds') WHERE JSON_VALUE(value,'$.changeKind')=N'candidate-decision';
GO
-- ============================== RECEIPT PROOF ==============================
-- Against the two live PENDING candidate receipts, inside this transaction only.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @result_content nvarchar(80)=(SELECT JSON_VALUE(definition_json,'$.semantics.contentDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND declared_id=@authority_id);
DECLARE @declared_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM source.content_object co WHERE co.content_digest=CONVERT(binary(32),REPLACE(@result_content,N'sha256:',N''),2));
DECLARE @admit_statement nvarchar(max)=(SELECT JSON_VALUE(value,'$.statement') FROM OPENJSON(@declared_body,'$.reads')
 WHERE JSON_VALUE(value,'$.readId')=N'admit-candidate-decision');
IF @admit_statement IS NULL THROW 51000,N'CANDIDATE_DECISION_READ_MISSING',1;
DECLARE @candidate nvarchar(400)=N'resolve-equity-market-price-evidence.candidate-1';
DECLARE @bundle nvarchar(100)=(SELECT JSON_VALUE(definition_json,'$.semantics.document.bundleDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='AUTHORITY' AND namespace_id=N'sidefx:candidates'
  AND declared_id=@candidate+N'.receipt.v1');
IF @bundle IS NULL THROW 51000,N'CANDIDATE_DECISION_FIXTURE_MISSING',1;
DECLARE @decision nvarchar(max)=(SELECT @candidate AS candidateId,@bundle AS bundleDigest,N'ACCEPTED' AS decision,
 N'lane3-reviewer' AS reviewerAuthorityId,N'2026-09-22T00:00:00Z' AS decidedAt,
 JSON_QUERY(N'{"capabilityId":"resolve-equity-market-price-evidence","input":{"objective":"lane3 decision receipt proof"},"expected":{"disposition":"terminated"},"disposition":"terminated"}') AS preflight
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @admission TABLE(disposition nvarchar(20),reason nvarchar(400));
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@decision,@estate_model_pk=@estate;
SELECT N'1_admission_admitted' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'ADMITTED') THROW 51000,N'CANDIDATE_DECISION_ADMISSION_FAILED',1;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE reason=N'[]') THROW 51000,N'CANDIDATE_DECISION_ADMISSION_REASON_NOT_EMPTY',1;

BEGIN TRY
 EXEC model.record_candidate_decision @document=@decision;
 SELECT N'2_recorded' AS result_set,N'PASSED' AS disposition;
END TRY
BEGIN CATCH
 SELECT N'2_recorded' AS result_set,N'THREW:'+ERROR_MESSAGE() AS disposition;
END CATCH
IF NOT EXISTS(SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.namespace_id=N'sidefx:candidates'
  AND d.declared_id=@candidate+N'.decision.v1' AND JSON_VALUE(d.definition_json,'$.semantics.document.decision')=N'ACCEPTED')
 THROW 51000,N'CANDIDATE_DECISION_RECEIPT_NOT_WRITTEN',1;
BEGIN TRY
 EXEC model.record_candidate_decision @document=@decision;
 SELECT N'3_replay' AS result_set,N'NOT_THROWN' AS disposition;
END TRY
BEGIN CATCH
 SELECT N'3_replay' AS result_set,N'THREW:'+ERROR_MESSAGE() AS disposition;
END CATCH;
DECLARE @recorded_definitions int=(SELECT COUNT(*) FROM model.semantic_object_definition d
 JOIN model.semantic_object o ON o.semantic_object_pk=d.semantic_object_pk
 JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
 WHERE n.namespace_id=N'sidefx:candidates' AND o.declared_id=@candidate+N'.decision.v1');

-- Admission refusals are data-level: absent candidate, bundle mismatch, and a
-- decision that contradicts the standing one.
DECLARE @unknown nvarchar(max)=(SELECT N'lane3.no-such-candidate' AS candidateId,@bundle AS bundleDigest,N'ACCEPTED' AS decision,
 N'lane3-reviewer' AS reviewerAuthorityId,N'2026-09-22T00:00:00Z' AS decidedAt,
 JSON_QUERY(N'{"capabilityId":"resolve-equity-market-price-evidence","input":{"objective":"proof"},"expected":{"disposition":"terminated"},"disposition":"terminated"}') AS preflight
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@unknown,@estate_model_pk=@estate;
SELECT N'4_absent_candidate' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_RECEIPT_NOT_FOUND%')
 THROW 51000,N'CANDIDATE_DECISION_ABSENT_PROOF_FAILED',1;
DECLARE @mismatch nvarchar(max)=(SELECT @candidate AS candidateId,
 N'sha256:9999999999999999999999999999999999999999999999999999999999999999' AS bundleDigest,N'ACCEPTED' AS decision,
 N'lane3-reviewer' AS reviewerAuthorityId,N'2026-09-22T00:00:00Z' AS decidedAt,
 JSON_QUERY(N'{"capabilityId":"resolve-equity-market-price-evidence","input":{"objective":"proof"},"expected":{"disposition":"terminated"},"disposition":"terminated"}') AS preflight
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@mismatch,@estate_model_pk=@estate;
SELECT N'5_bundle_mismatch' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_BUNDLE_MISMATCH%')
 THROW 51000,N'CANDIDATE_DECISION_MISMATCH_PROOF_FAILED',1;
DECLARE @revision nvarchar(max)=REPLACE(@decision,N'"ACCEPTED"',N'"REPAIR"');
DELETE @admission;
INSERT @admission EXEC sp_executesql @admit_statement,N'@input nvarchar(max),@estate_model_pk bigint',@input=@revision,@estate_model_pk=@estate;
SELECT N'6_revision_held' AS result_set,disposition,reason FROM @admission;
IF NOT EXISTS(SELECT 1 FROM @admission WHERE disposition=N'HELD' AND reason LIKE N'%CANDIDATE_DECISION_REVISION_NOT_ADMITTED%')
 THROW 51000,N'CANDIDATE_DECISION_REVISION_PROOF_FAILED',1;
IF (SELECT COUNT(*) FROM model.semantic_object_definition d
 JOIN model.semantic_object o ON o.semantic_object_pk=d.semantic_object_pk
 JOIN model.identity_namespace n ON n.namespace_pk=o.namespace_pk
 WHERE n.namespace_id=N'sidefx:candidates' AND o.declared_id=@candidate+N'.decision.v1')<>@recorded_definitions
 THROW 51000,N'CANDIDATE_DECISION_READ_WROTE',1;
-- Unrelated capability graph digests must be byte-identical.
DECLARE @candidate_decision_after TABLE(capability_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,digest varchar(64),bytes bigint);
INSERT @candidate_decision_after(capability_id,digest,bytes)
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'say-hello-world',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'authoring-altitude-model-stubs',1,NULL) g
UNION ALL
SELECT g.capability_id,LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',
 CONVERT(varbinary(max),CONVERT(varchar(max),g.graph_source) COLLATE Latin1_General_100_BIN2_UTF8)),2)),DATALENGTH(g.graph_source)
FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',1,NULL) g;
SELECT N'7_graph_digest_compare' AS result_set,b.capability_id,b.digest AS before_digest,a.digest AS after_digest,
 CASE WHEN b.digest=a.digest THEN N'UNCHANGED' ELSE N'CHANGED' END AS disposition
FROM #candidate_decision_unrelated b JOIN @candidate_decision_after a ON a.capability_id=b.capability_id ORDER BY b.capability_id;
IF EXISTS(SELECT 1 FROM #candidate_decision_unrelated b JOIN @candidate_decision_after a ON a.capability_id=b.capability_id WHERE b.digest<>a.digest)
 THROW 51000,N'CANDIDATE_DECISION_UNRELATED_CAPABILITY_CHANGED',1;
GO
-- Installer revision refusal (dooms the transaction; the same batch rolls back).
SET XACT_ABORT OFF;
DECLARE @probe_estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @probe_candidate nvarchar(400)=N'resolve-equity-market-price-evidence.candidate-1';
DECLARE @probe_bundle nvarchar(100)=(SELECT JSON_VALUE(definition_json,'$.semantics.document.bundleDigest') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@probe_estate AND object_kind=N'AUTHORITY' AND namespace_id=N'sidefx:candidates'
  AND declared_id=@probe_candidate+N'.receipt.v1');
DECLARE @changed nvarchar(max)=(SELECT @probe_candidate AS candidateId,@probe_bundle AS bundleDigest,N'REPAIR' AS decision,
 N'lane3-reviewer' AS reviewerAuthorityId,N'2026-09-22T00:00:01Z' AS decidedAt,
 JSON_QUERY(N'{"capabilityId":"resolve-equity-market-price-evidence","input":{"objective":"lane3 revision probe"},"expected":{"disposition":"terminated"},"disposition":"terminated"}') AS preflight
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
BEGIN TRY
 EXEC model.record_candidate_decision @document=@changed;
 SELECT N'7_revision_probe' AS result_set,N'NOT_THROWN' AS disposition;
END TRY
BEGIN CATCH
 SELECT N'7_revision_probe' AS result_set,ERROR_MESSAGE() AS disposition,
  CASE WHEN ERROR_MESSAGE()=N'CANDIDATE_DECISION_REVISION_NOT_ADMITTED' THEN N'PASSED' ELSE N'FAILED' END AS probe_result;
END CATCH
ROLLBACK TRANSACTION;
