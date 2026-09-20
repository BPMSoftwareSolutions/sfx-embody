-- repair-kernel-authority-neutral-references.sql
--
-- The data-access authority was re-declared under the language-neutral id
-- `sda-kernel-boot-data-access.v1` by declare-kernel-carrier-authorities.sql,
-- but its embedded body kept two references to the retired Node-home names:
-- the `$schema` pointer still named the retired Node-home schema file, and
-- `runtimeResolution.authorityRef` still named the retired Node-home authority
-- file. The retired spellings are deliberately not repeated here; the historic
-- migrations that were applied are the record of them. The kernel home has since
-- gained the schema under the neutral name
-- (kernel/schemas/sda-kernel-boot-data-access-authority.v1.schema.json), which
-- the boot validates the authority against on load. This migration re-declares
-- the selected authority content with the neutral schema id and authority
-- reference, recomputes both the content digest and the document's self-digest,
-- and fails closed if the selected bytes are not the exact generation this
-- migration was authored against. No DML trigger is dropped: the declared guard
-- inventory must already be empty, exactly as the two preceding re-declarations
-- require.
--
-- Idempotent: a second run finds the selected digest already the neutral one
-- and re-declares nothing.
--
-- Installed copy. To dry-run, replace the final COMMIT TRANSACTION with
-- ROLLBACK TRANSACTION and run the lifecycle runner again.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @lock int;
EXEC @lock=sys.sp_getapplock @Resource=N'sidefx:model-write',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=30000;
IF @lock<0 THROW 51000,N'KERNEL_AUTHORITY_REPAIR_LOCK_FAILED',1;
IF EXISTS(SELECT 1 FROM sys.triggers t JOIN sys.tables p ON p.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=p.schema_id
 WHERE s.name IN (N'model',N'source')) THROW 51000,N'GUARD_INVENTORY_CHANGED_REDECLARE_EXPLICIT_SET',1;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @neutral_schema nvarchar(400)=N'https://schemas.scenario-driven.dev/kernel/sda-kernel-boot-data-access-authority.v1.schema.json';
DECLARE @neutral_ref nvarchar(400)=N'kernel/semantic-authority/consumer/sda-kernel-boot-data-access.authority.v1.json';
DECLARE @stale_content nvarchar(80)=N'sha256:cf0f7bda1496ce137ad16cd4b22678a297357d539218bd2a7dd77f7ec3adb750';
DECLARE @neutral_content nvarchar(80)=N'sha256:84c0ee351bc0332a56a30f0969658d5a526216485d3b8a3e2ee9d2e286fe72cb';
DECLARE @neutral_authority_digest nvarchar(80)=N'sha256:19d40e09af0b88e3103c0cbe883c6dc6cf76f7784d538f611bd07002af3da255';

DECLARE @json nvarchar(max),@selected nvarchar(80);
SELECT @json=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),
       @selected=JSON_VALUE(d.definition_json,'$.semantics.contentDigest')
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id;
IF @json IS NULL THROW 51000,N'KERNEL_BOOT_AUTHORITY_NOT_SELECTED',1;
IF JSON_VALUE(@json,'$.authorityId')<>N'sda-kernel-boot-data-access.v1' THROW 51000,N'KERNEL_BOOT_AUTHORITY_ID_MISMATCH',1;
IF @selected NOT IN (@stale_content,@neutral_content) THROW 51000,N'KERNEL_BOOT_AUTHORITY_CHANGED_REBASE_DECLARATION',1;

IF @selected=@stale_content
BEGIN
 -- Replace only the two retired references and the self-digest member. The
 -- authored digest below was computed from the exact neutral document; a
 -- JSON_MODIFY result that differs from it throws rather than stamping bytes
 -- that no reviewer computed.
 SET @json=JSON_MODIFY(@json,'$."$schema"',@neutral_schema);
 SET @json=JSON_MODIFY(@json,'$.runtimeResolution.authorityRef',@neutral_ref);
 SET @json=JSON_MODIFY(@json,'$.authorityDigest',@neutral_authority_digest);
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF LOWER(CONVERT(varchar(64),@content,2))<>N'84c0ee351bc0332a56a30f0969658d5a526216485d3b8a3e2ee9d2e286fe72cb'
  THROW 51000,N'KERNEL_BOOT_AUTHORITY_NEUTRAL_REWRITE_DIVERGED',1;
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content)<>@bytes
  THROW 51000,N'KERNEL_BOOT_AUTHORITY_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sda-kernel-boot-data-access.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@content,2))
  + N'","sourcePath":"kernel/semantic-authority/consumer/sda-kernel-boot-data-access.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-kernel-boot-data-access.authority.v1.json"]}';
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,
  @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END

-- ============================== IN-TRANSACTION PREFLIGHT ==============================
-- The exact fixed ground read the kernel boot carries, executed against the
-- uncommitted rows. The selected content digest is the cryptographic claim: the
-- pinned neutral digest already excludes any other stale member anywhere in the
-- document, and the member checks make the repair explicit.
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
IF JSON_VALUE(@body,'$.authorityId')<>N'sda-kernel-boot-data-access.v1' THROW 51000,N'KERNEL_BOOT_AUTHORITY_ID_MISMATCH',1;
IF JSON_VALUE(@body,'$."$schema"')<>@neutral_schema THROW 51000,N'KERNEL_BOOT_AUTHORITY_SCHEMA_NOT_NEUTRAL',1;
IF JSON_VALUE(@body,'$.runtimeResolution.authorityRef')<>@neutral_ref THROW 51000,N'KERNEL_BOOT_AUTHORITY_REF_NOT_NEUTRAL',1;
IF JSON_VALUE(@body,'$.authorityDigest')<>@neutral_authority_digest THROW 51000,N'KERNEL_BOOT_AUTHORITY_DIGEST_NOT_NEUTRAL',1;
IF (SELECT content_digest FROM @ground_authority)<>N'84c0ee351bc0332a56a30f0969658d5a526216485d3b8a3e2ee9d2e286fe72cb'
 THROW 51000,N'KERNEL_BOOT_AUTHORITY_CONTENT_NOT_NEUTRAL',1;

SELECT '1_neutral_authority' AS result_set,@authority_id AS authority_id,
 (SELECT content_digest FROM @ground_authority) AS content_digest,
 JSON_VALUE(@body,'$."$schema"') AS body_schema,
 JSON_VALUE(@body,'$.runtimeResolution.authorityRef') AS body_authority_ref,
 JSON_VALUE(@body,'$.authorityDigest') AS authority_digest,
 (SELECT COUNT(*) FROM OPENJSON(@body,'$.reads')) AS read_count,
 (SELECT COUNT(*) FROM OPENJSON(@body,'$.changeOperations')) AS change_operation_count,
 CASE WHEN @selected=@neutral_content THEN N'already_neutral' ELSE N'rerepaired' END AS disposition;

COMMIT TRANSACTION;
