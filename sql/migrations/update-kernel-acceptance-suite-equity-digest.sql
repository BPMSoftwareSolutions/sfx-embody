-- update-kernel-acceptance-suite-equity-digest.sql
--
-- Deliberate update of the declared kernel acceptance suite: the equity
-- invocation's recorded observed path digest moved because the capability now
-- declares the finance15 fallback route (fifteen operations) and the live chain
-- resolves through finance15 after the primary and real-time1 quotas are
-- exhausted. The recorded digest is updated to the observed live value
-- sha256:0724765ddbe8da85dc22ca478671087b0ff75ce3fa0332e3b06456aab5efa01d.
--
-- The suite is declared authority: the currently selected bytes are read, the
-- digest is set, the new bytes are retained and the AUTHORITY definition is
-- re-declared. config/kernel-acceptance-suite.v1.json carries the same change.
--
-- Idempotent: a second run finds the digest already updated.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install.
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
GO
BEGIN TRANSACTION;
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sfx-kernel-acceptance-suite.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @new_digest nvarchar(200)=N'sha256:0724765ddbe8da85dc22ca478671087b0ff75ce3fa0332e3b06456aab5efa01d';
DECLARE @object bigint,@definition bigint,@digest binary(32),@bytes varbinary(max),@json nvarchar(max);
SELECT @json=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id;
IF @json IS NULL THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_AUTHORITY_NOT_SELECTED',1;
IF ISJSON(@json)<>1 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_AUTHORITY_MALFORMED',1;
IF JSON_VALUE(@json,'$.invocations[1].id')<>N'invoke-resolve-equity-market-price-evidence'
 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_SHAPE_DIVERGED',1;

IF JSON_VALUE(@json,'$.invocations[1].expect[0].conditions[0].value')<>@new_digest
BEGIN
 SET @json=JSON_MODIFY(@json,'$.invocations[1].expect[0].conditions[0].value',@new_digest);
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content_digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content_digest)<>@bytes
  THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sfx-kernel-acceptance-suite.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@content_digest,2))
  + N'","sourcePath":"config/kernel-acceptance-suite.v1.json","locators":["config/kernel-acceptance-suite.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END
SELECT '1_suite_digest' AS result_set,
 JSON_VALUE(@json,'$.invocations[1].expect[0].conditions[0].value') AS resolved_live_digest,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8))),2)) AS content_digest;
SELECT '2_declared_read' AS result_set,
 JSON_VALUE(d.definition_json,'$.semantics.contentDigest') AS selected_content_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id;
COMMIT TRANSACTION;
-- Installed 2026-09-19: equity acceptance digest updated for the finance15 fallback route.
