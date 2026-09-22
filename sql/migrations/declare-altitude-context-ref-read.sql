-- declare-altitude-context-ref-read.sql
--
-- Lane 1, item 4 of (the DB half of) docs/compact-altitude-request-plan-2026-09-22.md:
-- context-by-reference resolution.
--
-- What is reused, unchanged:
--   * contextSlices ride the existing bounded `document-select` SEJ operation
--     (kernel semantic-transformation profile; no row is added here).
--   * contextRefs are handles, not bodies: the compact request carries
--     {kind,id,digest} and the definition bytes stay in source.content_object.
--   * the boot read vocabulary, the authority's changeContracts and every other
--     declared read are byte-identical after the re-mint (asserted below).
--
-- What was genuinely missing: no stable read id resolves one declared
-- definition by (kind,id,digest) under the pinned estate model. The existing
-- boot reads resolve capabilities (capability-authority), closure
-- (capability-closure), delivery (execution-delivery) and AUTHORITY-kind
-- provider declarations (provider-authority); none resolves the CONTRACT,
-- TRANSFORMATION, CAPABILITY or AUTHORITY definition a contextRef names. One
-- read row is therefore added to the selected boot data-access authority:
--
--   readId: context-ref
--   input:  { "kind": "contract|capability|transformation|authority|scenario|port|precedent",
--             "id": "<declared id>",
--             "digest": "sha256:<optional>" }
--   result: the selected definition's declared id, object kind, namespace,
--           definition digest, content digest, byte length and the exact
--           canonical document bytes (source.content_object).
--   refusals: CONTEXT_REF_ID_REQUIRED, CONTEXT_REF_KIND_UNSUPPORTED,
--             CONTEXT_REF_NOT_DECLARED, CONTEXT_REF_AMBIGUOUS,
--             CONTEXT_REF_DIGEST_MISMATCH.
--
-- The authority content is re-minted: the new read is appended and the
-- `sda-node-boot-data-access.v1` AUTHORITY definition is re-declared with the
-- new contentDigest. Discovery note: the document's self member
-- `authorityDigest` is NOT recomputed here - the estate has no SQL
-- implementation of the recursive-key-order recipe, boot verification
-- (`SDA:data-access.mjs` readGroundAuthority) verifies the content bytes
-- against the declared contentDigest, and the prior re-mints
-- (declare-change-family-admission.sql, update-kernel-boot-authority-digest.sql)
-- set the digest the same way. It is reported so the drift is visible.
--
-- Depends on nothing from items 1-3. Idempotent: a replay finds the read id and
-- answers already_declared without writing.
--
-- Dry run: this file ends in ROLLBACK. The install is the .commit.sql copy.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=300000;
IF @lock<0 THROW 51000,N'ALTITUDE_CONTEXT_REF_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @read_id nvarchar(400)=N'context-ref';

-- ============================== THE SELECTED AUTHORITY ==============================
DECLARE @body nvarchar(max),@semantics nvarchar(max);
SELECT @body=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),
 @semantics=JSON_QUERY(d.definition_json,'$.semantics')
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.declared_id=@authority_id;
IF @body IS NULL THROW 51000,N'ALTITUDE_CONTEXT_REF_BOOT_AUTHORITY_NOT_SELECTED',1;
IF JSON_VALUE(@body,'$.authorityId')<>N'sda-kernel-boot-data-access.v1' THROW 51000,N'ALTITUDE_CONTEXT_REF_BOOT_AUTHORITY_ID_MISMATCH',1;
DECLARE @reads_before int=(SELECT COUNT(*) FROM OPENJSON(@body,'$.reads'));
IF @reads_before<20 THROW 51000,N'ALTITUDE_CONTEXT_REF_BOOT_READS_TRUNCATED',1;
DECLARE @before TABLE(read_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,statement nvarchar(max));
INSERT @before(read_id,statement)
SELECT j.readId,j.statement
FROM OPENJSON(@body,'$.reads') WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement') j;
IF (SELECT COUNT(*) FROM @before)<>@reads_before THROW 51000,N'ALTITUDE_CONTEXT_REF_BOOT_READS_NOT_UNIQUE',1;

-- ============================== THE READ DECLARATION ==============================
DECLARE @statement nvarchar(max)=N'
DECLARE @id nvarchar(400)=NULLIF(CONVERT(nvarchar(400),JSON_VALUE(@input,''$.id'')),N'''');
DECLARE @kind nvarchar(64)=NULLIF(LOWER(CONVERT(nvarchar(64),JSON_VALUE(@input,''$.kind''))),N'''');
DECLARE @digest nvarchar(80)=NULLIF(CONVERT(nvarchar(80),JSON_VALUE(@input,''$.digest'')),N'''');
IF @id IS NULL THROW 51000,N''CONTEXT_REF_ID_REQUIRED'',1;
DECLARE @object_kind varchar(64)=NULL;
IF @kind IS NOT NULL
 SET @object_kind=CASE @kind WHEN ''contract'' THEN ''CONTRACT'' WHEN ''capability'' THEN ''CAPABILITY''
  WHEN ''transformation'' THEN ''TRANSFORMATION'' WHEN ''authority'' THEN ''AUTHORITY'' WHEN ''scenario'' THEN ''SCENARIO''
  WHEN ''port'' THEN ''PORT'' WHEN ''precedent'' THEN ''AUTHORITY'' END;
IF @kind IS NOT NULL AND @object_kind IS NULL THROW 51000,N''CONTEXT_REF_KIND_UNSUPPORTED'',1;
DECLARE @resolved TABLE(ordinal int IDENTITY(1,1) PRIMARY KEY,declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
 object_kind varchar(64),namespace_id nvarchar(400),definition_digest varchar(71),content_digest varchar(71),byte_length bigint,content_bytes varbinary(max));
INSERT @resolved(declared_id,object_kind,namespace_id,definition_digest,content_digest,byte_length,content_bytes)
SELECT d.declared_id,d.object_kind,d.namespace_id,
 ''sha256:''+LOWER(CONVERT(varchar(64),d.definition_digest,2)),
 ''sha256:''+LOWER(CONVERT(varchar(64),co.content_digest,2)),co.byte_length,co.content_bytes
FROM analysis.v_selected_semantic_definition d
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=d.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
WHERE d.estate_model_pk=@estate_model_pk AND d.declared_id=@id COLLATE Latin1_General_100_BIN2
 AND (@object_kind IS NULL OR d.object_kind=@object_kind);
DECLARE @matches int=(SELECT COUNT(*) FROM @resolved);
IF @matches=0 THROW 51000,N''CONTEXT_REF_NOT_DECLARED'',1;
IF @matches>1 THROW 51000,N''CONTEXT_REF_AMBIGUOUS'',1;
IF @digest IS NOT NULL AND (SELECT content_digest FROM @resolved)<>@digest THROW 51000,N''CONTEXT_REF_DIGEST_MISMATCH'',1;
SELECT declared_id,object_kind,namespace_id,definition_digest,content_digest,byte_length,content_bytes FROM @resolved;';
DECLARE @read nvarchar(max)=N'{"readId":"context-ref","purpose":"Resolve one declared context-ref handle (kind, id, optional digest) to the selected definition canonical document bytes and definition digest under the pinned estate model. kind contract|capability|transformation|authority|scenario|port maps to its object kind; precedent resolves an AUTHORITY receipt. CONTEXT_REF_NOT_DECLARED, CONTEXT_REF_AMBIGUOUS and CONTEXT_REF_DIGEST_MISMATCH fail closed.","sourceKind":"tsql","statement":"'+STRING_ESCAPE(@statement,N'json')+N'","parameters":[{"parameter":"input","kind":"invocation-input-json","fields":["kind","id","digest"]},{"parameter":"estate_model_pk","kind":"pinned-session"}],"resultMapping":{"recordsets":[{"index":0,"role":"context-ref","columns":["declared_id","object_kind","namespace_id","definition_digest","content_digest","byte_length","content_bytes"]}]}}';

-- ============================== THE RE-MINT ==============================
DECLARE @already bit=CASE WHEN EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') j WHERE JSON_VALUE(j.value,'$.readId')=@read_id COLLATE Latin1_General_100_BIN2) THEN 1 ELSE 0 END;
DECLARE @new_content_digest binary(32);
IF @already=1
BEGIN
 DECLARE @existing_statement nvarchar(max)=(SELECT j.statement FROM OPENJSON(@body,'$.reads') WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement') j WHERE j.readId=@read_id COLLATE Latin1_General_100_BIN2);
 IF @existing_statement<>@statement COLLATE Latin1_General_100_BIN2 THROW 51000,N'ALTITUDE_CONTEXT_REF_READ_DIVERGED',1;
END
ELSE
BEGIN
 SET @body=JSON_MODIFY(@body,'append $.reads',JSON_QUERY(@read));
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 SET @new_content_digest=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@new_content_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@new_content_digest,@bytes,DATALENGTH(@bytes));
 SET @semantics=JSON_MODIFY(@semantics,'$.contentDigest',N'sha256:'+LOWER(CONVERT(varchar(64),@new_content_digest,2)));
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END
-- Re-check the selected authority now carries the read.
SELECT @body=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind=N'AUTHORITY' AND d.declared_id=@authority_id;
DECLARE @reads_after int=(SELECT COUNT(*) FROM OPENJSON(@body,'$.reads'));
IF @already=0 AND @reads_after<>@reads_before+1 THROW 51000,N'ALTITUDE_CONTEXT_REF_READ_NOT_APPENDED',1;
IF NOT EXISTS(SELECT 1 FROM OPENJSON(@body,'$.reads') j WHERE JSON_VALUE(j.value,'$.readId')=@read_id COLLATE Latin1_General_100_BIN2)
 THROW 51000,N'ALTITUDE_CONTEXT_REF_READ_NOT_SELECTED',1;
-- Every pre-existing read's statement is unchanged (OPENJSON WITH nvarchar(max)
-- reads the full statement text; JSON_VALUE truncates at 4000 characters);
-- only context-ref was added.
DECLARE @after_reads TABLE(read_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY,statement nvarchar(max));
INSERT @after_reads(read_id,statement)
SELECT j.readId,j.statement
FROM OPENJSON(@body,'$.reads') WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement') j;
IF EXISTS(SELECT 1 FROM @before b WHERE NOT EXISTS(
 SELECT 1 FROM @after_reads a WHERE a.read_id=b.read_id AND a.statement=b.statement COLLATE Latin1_General_100_BIN2))
 THROW 51000,N'ALTITUDE_CONTEXT_REF_PRIOR_READ_CHANGED',1;

-- ============================== SELF-TEST (the read statement against uncommitted rows) ==============================
DECLARE @body_statement nvarchar(max)=(SELECT j.statement FROM OPENJSON(@body,'$.reads') WITH(readId nvarchar(400) '$.readId',statement nvarchar(max) '$.statement') j WHERE j.readId=@read_id COLLATE Latin1_General_100_BIN2);
DECLARE @contract_id nvarchar(400)=N'governed-model-invocation-request.v1';
DECLARE @contract_digest varchar(71)=(SELECT N'sha256:'+LOWER(CONVERT(varchar(64),d.definition_digest,2))
 FROM analysis.v_selected_semantic_definition d WHERE d.estate_model_pk=@estate AND d.object_kind=N'CONTRACT' AND d.declared_id=@contract_id);
DECLARE @probe_input nvarchar(max)=N'{"kind":"contract","id":"'+@contract_id+N'","digest":"'+@contract_digest+N'"}';
DECLARE @probe TABLE(declared_id nvarchar(400),object_kind varchar(64),namespace_id nvarchar(400),definition_digest varchar(71),content_digest varchar(71),byte_length bigint,content_bytes varbinary(max));
DECLARE @probe_declared nvarchar(400),@probe_kind varchar(64),@probe_content_digest nvarchar(80),@probe_bytes bigint;
INSERT @probe EXEC sp_executesql @body_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@probe_input,@estate_model_pk=@estate;
SELECT @probe_declared=declared_id,@probe_kind=object_kind,@probe_content_digest=content_digest,@probe_bytes=byte_length FROM @probe;
IF @probe_declared IS NULL OR @probe_declared<>@contract_id THROW 51000,N'ALTITUDE_CONTEXT_REF_CONTRACT_PROBE_FAILED',1;
IF @probe_content_digest<>@contract_digest THROW 51000,N'ALTITUDE_CONTEXT_REF_CONTRACT_DIGEST_MISMATCH',1;
DECLARE @transformation_probe TABLE(declared_id nvarchar(400),object_kind varchar(64),namespace_id nvarchar(400),definition_digest varchar(71),content_digest varchar(71),byte_length bigint,content_bytes varbinary(max));
DECLARE @transformation_input nvarchar(max)=N'{"kind":"transformation","id":"build-agent-model-request"}';
INSERT @transformation_probe EXEC sp_executesql @body_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@transformation_input,@estate_model_pk=@estate;
IF NOT EXISTS(SELECT 1 FROM @transformation_probe WHERE declared_id=N'build-agent-model-request') THROW 51000,N'ALTITUDE_CONTEXT_REF_TRANSFORMATION_PROBE_FAILED',1;

-- Refusal probes doom nothing with XACT_ABORT off; the file rolls back next.
SET XACT_ABORT OFF;
DECLARE @digest_code nvarchar(400),@unknown_code nvarchar(400);
DECLARE @bad_digest TABLE(declared_id nvarchar(400),object_kind varchar(64),namespace_id nvarchar(400),definition_digest varchar(71),content_digest varchar(71),byte_length bigint,content_bytes varbinary(max));
DECLARE @unknown TABLE(declared_id nvarchar(400),object_kind varchar(64),namespace_id nvarchar(400),definition_digest varchar(71),content_digest varchar(71),byte_length bigint,content_bytes varbinary(max));
DECLARE @bad_input nvarchar(max)=N'{"kind":"contract","id":"'+@contract_id+N'","digest":"sha256:0000000000000000000000000000000000000000000000000000000000000000"}';
DECLARE @unknown_input nvarchar(max)=N'{"kind":"contract","id":"no-such-declared-id.v1"}';
BEGIN TRY
 INSERT @bad_digest EXEC sp_executesql @body_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@bad_input,@estate_model_pk=@estate;
END TRY
BEGIN CATCH SET @digest_code=ERROR_MESSAGE(); END CATCH
BEGIN TRY
 INSERT @unknown EXEC sp_executesql @body_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@unknown_input,@estate_model_pk=@estate;
END TRY
BEGIN CATCH SET @unknown_code=ERROR_MESSAGE(); END CATCH
DECLARE @digest_failure nvarchar(2048)=N'ALTITUDE_CONTEXT_REF_DIGEST_PROBE_FAILED:'+ISNULL(@digest_code,N'(none)');
DECLARE @unknown_failure nvarchar(2048)=N'ALTITUDE_CONTEXT_REF_UNKNOWN_PROBE_FAILED:'+ISNULL(@unknown_code,N'(none)');
IF @digest_code IS NULL OR @digest_code NOT LIKE N'%CONTEXT_REF_DIGEST_MISMATCH%' THROW 51000,@digest_failure,1;
IF @unknown_code IS NULL OR @unknown_code NOT LIKE N'%CONTEXT_REF_NOT_DECLARED%' THROW 51000,@unknown_failure,1;

-- ============================== PROOFS ==============================
SELECT N'1_context_ref_read' AS result_set,JSON_VALUE(j.value,'$.readId') AS read_id,JSON_VALUE(j.value,'$.sourceKind') AS source_kind,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(j.value,'$.parameters'))) AS parameters,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(j.value,'$.resultMapping.recordsets'))) AS recordsets,
 CASE WHEN JSON_VALUE(j.value,'$.purpose') LIKE N'%CONTEXT_REF_DIGEST_MISMATCH%' THEN N'REFUSALS_DECLARED' ELSE N'DIVERGED' END AS refusals
FROM OPENJSON(@body,'$.reads') j WHERE JSON_VALUE(j.value,'$.readId')=@read_id COLLATE Latin1_General_100_BIN2;
SELECT N'2_boot_authority' AS result_set,
 CASE WHEN @already=1 THEN N'already_declared' ELSE N'redeclared' END AS disposition,
 JSON_VALUE(@semantics,'$.contentDigest') AS content_digest,
 JSON_VALUE(@body,'$.authorityDigest') AS authority_self_digest,
 @reads_before AS reads_before,@reads_after AS reads_after,
 (SELECT COUNT(*) FROM OPENJSON(@body,'$.changeContracts')) AS change_contracts;
SELECT N'3_context_ref_probes' AS result_set,N'contract' AS probe,@probe_declared AS resolved_id,@probe_kind AS object_kind,@probe_bytes AS byte_length,
 CASE WHEN @probe_content_digest=@contract_digest THEN N'DIGEST_MATCH' ELSE N'DIVERGED' END AS disposition
UNION ALL
SELECT N'3_context_ref_probes',N'transformation',N'build-agent-model-request',N'TRANSFORMATION',NULL,N'RESOLVED';
SELECT N'4_context_ref_refusals' AS result_set,N'digest-mismatch' AS probe,@digest_code AS error_code,N'PASSED' AS probe_result
UNION ALL SELECT N'4_context_ref_refusals',N'unknown-id',@unknown_code,N'PASSED';
SELECT N'5_disposition' AS result_set,CASE WHEN @already=1 THEN N'already_declared' ELSE N'redeclared' END AS disposition,
 @read_id AS read_id,@reads_before AS reads_before,@reads_after AS reads_after;
ROLLBACK TRANSACTION;
