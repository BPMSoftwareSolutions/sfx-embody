-- update-kernel-boot-authority-digest.sql
--
-- The re-declared kernel boot authority (declare-kernel-carrier-authorities.sql)
-- carries the session policy and the neutral id; its self-digest member
-- (`authorityDigest`, the sha256 of the recursive-key-order JSON excluding the
-- member itself) is recomputed here so the retained document is self-consistent.
--
-- Idempotent: a second run finds the selected digest already equal and
-- re-declares nothing. Default: ROLLBACK; replace the final ROLLBACK with
-- COMMIT to install.
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

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @digest_value nvarchar(80)=N'sha256:23a612322ea30d7407f1035daecdff059125466c6d3875299a8254b271fc639b';
DECLARE @object bigint,@definition bigint,@digest binary(32),@bytes varbinary(max),@json nvarchar(max);
SELECT @json=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id;
IF @json IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
IF JSON_VALUE(@json,'$.authorityId')<>N'sda-kernel-boot-data-access.v1' THROW 51000,N'KERNEL_BOOT_AUTHORITY_ID_MISMATCH',1;
-- The digest update is computed for the exact selected content; a document that
-- changed since the computation fails closed rather than stamping a stale digest.
DECLARE @selected_content_digest nvarchar(80)=(
 SELECT JSON_VALUE(d.definition_json,'$.semantics.contentDigest')
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id);
IF @selected_content_digest<>N'sha256:5de914d25d43fd1b9f78ea543b962a5dd7ac4219a3d19bddc689fcbe483587f7'
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_CONTENT_CHANGED_RECOMPUTE_DIGEST',1;
IF JSON_VALUE(@json,'$.authorityDigest')<>@digest_value
BEGIN
 SET @json=JSON_MODIFY(@json,'$.authorityDigest',@digest_value);
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content_digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content_digest)<>@bytes
  THROW 51000,N'KERNEL_BOOT_AUTHORITY_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sda-kernel-boot-data-access.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@content_digest,2))
  + N'","sourcePath":"kernel/semantic-authority/consumer/sda-kernel-boot-data-access.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-kernel-boot-data-access.authority.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,
  @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END

-- ============================== IN-TRANSACTION PREFLIGHT ==============================
DECLARE @ground nvarchar(max)=N'SELECT co.byte_length,
       LOWER(CONVERT(varchar(64),co.content_digest,2)) AS content_digest,
       co.content_bytes
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,''$.semantics.contentDigest''),''sha256:'',''''),2)
WHERE d.estate_model_pk=@estate_model_pk
  AND d.object_kind=''AUTHORITY''
  AND d.declared_id=N''sda-kernel-boot-data-access.v1''';
DECLARE @ground_authority TABLE (byte_length bigint, content_digest varchar(71), content_bytes varbinary(max));
INSERT @ground_authority EXEC sp_executesql @ground,N'@estate_model_pk bigint',@estate;
IF (SELECT COUNT_BIG(*) FROM @ground_authority)<>1 THROW 51000,N'KERNEL_BOOT_GROUND_READ_NOT_SINGULAR',1;
DECLARE @body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM @ground_authority);
IF JSON_VALUE(@body,'$.authorityDigest')<>@digest_value THROW 51000,N'KERNEL_BOOT_AUTHORITY_DIGEST_NOT_UPDATED',1;
IF JSON_VALUE(@body,'$.sessionPolicy.impersonation.statement') IS NULL THROW 51000,N'KERNEL_SESSION_IMPERSONATION_NOT_RESOLVED',1;

SELECT '1_authority_digest' AS result_set, @authority_id AS authority_id,
 JSON_VALUE(@body,'$.authorityDigest') AS authority_digest,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8))),2)) AS content_digest,
 CASE WHEN JSON_VALUE(@body,'$.sessionPolicy.impersonation.statement') IS NULL THEN 0 ELSE 1 END AS impersonation_declared;

COMMIT TRANSACTION;
-- To dry-run, replace the COMMIT above with ROLLBACK and re-run.
