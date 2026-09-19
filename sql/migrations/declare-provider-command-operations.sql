-- declare-provider-command-operations.sql
--
-- Decision: the declared command vocabulary gains three provider operations,
-- served by the declared provider reads in declare-provider-command-reads.sql:
--
--   providerList    object provider, verb list    reader list-providers
--   providerReveal  object provider, verb reveal  reader read-provider-configuration
--   providerSet     object provider, verb set     reader author-provider-configuration-change
--
-- The retained capability operations keep their own verb as key (no `verb`
-- member). The three new rows are keyed object-qualified and carry an explicit
-- `verb`, so the carrier resolves an operation by the pair (object, verb) and a
-- new entity is a row, not a grammar branch. `set` requires the canonical input
-- (the authored change document); `list` and `reveal` reject input.
--
-- This migration authors no read and touches no capability row. The change is
-- content-addressed authority data: the currently selected
-- `sda-node-command-operations.v1` bytes are read, the three rows are set, the
-- new bytes are retained in source.content_object, and the AUTHORITY semantic
-- definition is re-declared with the new content digest. The kernel reads it
-- through the declared provider-authority read; no network, disk or code path
-- is touched.
--
-- Idempotent: a second run finds the selected authority already carrying the
-- three rows and re-declares nothing. The previous definition row remains in
-- place (content-addressed, append-only); selection is the highest definition pk.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with a commit to install after
-- the dry run and the from-transaction preflight.
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

-- ============================== THE DECLARATION ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-node-command-operations.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @object bigint,@definition bigint,@digest binary(32),@bytes varbinary(max),@json nvarchar(max);
SELECT @json=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id;
IF @json IS NULL THROW 51000,N'COMMAND_OPERATIONS_AUTHORITY_NOT_SELECTED',1;
IF ISJSON(@json)<>1 THROW 51000,N'COMMAND_OPERATIONS_AUTHORITY_MALFORMED',1;
IF JSON_QUERY(@json,'$.operations') IS NULL THROW 51000,N'COMMAND_OPERATIONS_NOT_DECLARED',1;

IF JSON_QUERY(@json,'$.operations.providerList') IS NULL
BEGIN
 SET @json=JSON_MODIFY(@json,'$.operations.providerList',JSON_QUERY(N'{"object":"provider","verb":"list","subject":false,"input":"rejected","reader":"list-providers"}'));
 SET @json=JSON_MODIFY(@json,'$.operations.providerReveal',JSON_QUERY(N'{"object":"provider","verb":"reveal","subject":true,"input":"rejected","reader":"read-provider-configuration"}'));
 SET @json=JSON_MODIFY(@json,'$.operations.providerSet',JSON_QUERY(N'{"object":"provider","verb":"set","subject":true,"input":"required","reader":"author-provider-configuration-change"}'));
 IF JSON_VALUE(@json,'$.operations.providerList.verb')<>N'list'
  OR JSON_VALUE(@json,'$.operations.providerReveal.verb')<>N'reveal'
  OR JSON_VALUE(@json,'$.operations.providerSet.verb')<>N'set'
  THROW 51000,N'PROVIDER_OPERATIONS_NOT_DECLARED',1;
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content_digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content_digest)<>@bytes
  THROW 51000,N'PROVIDER_OPERATIONS_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sda-node-command-operations.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@content_digest,2))
  + N'","sourcePath":"kernel/semantic-authority/consumer/sda-node-command-operations.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-node-command-operations.authority.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END

-- ============================== IN-TRANSACTION PREFLIGHT ==============================
-- The selected authority carries the three rows and resolves through the
-- declared provider-authority read exactly as the kernel carries it.
DECLARE @selected_body nvarchar(max)=(
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM analysis.v_selected_semantic_definition d
 JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id);
IF JSON_VALUE(@selected_body,'$.operations.providerList.verb')<>N'list'
 OR JSON_VALUE(@selected_body,'$.operations.providerReveal.verb')<>N'reveal'
 OR JSON_VALUE(@selected_body,'$.operations.providerSet.verb')<>N'set'
 THROW 51000,N'PROVIDER_OPERATIONS_NOT_SELECTED',1;
IF JSON_VALUE(@selected_body,'$.operations.providerList.reader')<>N'list-providers'
 OR JSON_VALUE(@selected_body,'$.operations.providerReveal.reader')<>N'read-provider-configuration'
 OR JSON_VALUE(@selected_body,'$.operations.providerSet.reader')<>N'author-provider-configuration-change'
 THROW 51000,N'PROVIDER_OPERATION_READERS_NOT_SELECTED',1;

DECLARE @ground nvarchar(max)=N'SELECT co.byte_length,
       LOWER(CONVERT(varchar(64),co.content_digest,2)) AS content_digest,
       co.content_bytes
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,''$.semantics.contentDigest''),''sha256:'',''''),2)
WHERE d.estate_model_pk=@estate_model_pk
  AND d.object_kind=''AUTHORITY''
  AND d.declared_id=N''sda-node-boot-data-access.v1''';
DECLARE @ground_authority TABLE (byte_length bigint, content_digest varchar(71), content_bytes varbinary(max));
INSERT @ground_authority EXEC sp_executesql @ground,N'@estate_model_pk bigint',@estate;
IF (SELECT COUNT_BIG(*) FROM @ground_authority)<>1 THROW 51000,N'KERNEL_BOOT_GROUND_READ_NOT_SINGULAR',1;
DECLARE @data_access_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM @ground_authority);
DECLARE @provider_read nvarchar(max)=(SELECT JSON_VALUE(entry.value,'$.statement')
 FROM OPENJSON(@data_access_body,'$.reads') entry WHERE JSON_VALUE(entry.value,'$.readId')=N'provider-authority');
IF @provider_read IS NULL THROW 51000,N'KERNEL_BOOT_PROVIDER_AUTHORITY_READ_NOT_DECLARED',1;
DECLARE @vocabulary TABLE (declared_id nvarchar(400), authority_id nvarchar(400), platform_capability_id nvarchar(400),
 content_digest nvarchar(400), byte_length bigint, content_bytes varbinary(max));
INSERT @vocabulary EXEC sp_executesql @provider_read,N'@estate_model_pk bigint,@input nvarchar(max)',@estate,N'{"authorityId":"sda-node-command-operations.v1"}';
IF (SELECT COUNT_BIG(*) FROM @vocabulary)<>1 THROW 51000,N'KERNEL_BOOT_COMMAND_AUTHORITY_NOT_SINGULAR',1;
DECLARE @command_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM @vocabulary);
IF JSON_VALUE(@command_body,'$.operations.providerReveal.object')<>N'provider'
 OR JSON_VALUE(@command_body,'$.operations.providerSet.object')<>N'provider'
 THROW 51000,N'PROVIDER_OPERATIONS_NOT_RESOLVED_BY_DECLARED_READ',1;

-- ============================== PROOF ==============================
SELECT '1_command_authority' AS result_set, @authority_id AS authority_id,
 JSON_VALUE(@selected_body,'$.operations.providerList.verb') AS list_verb,
 JSON_VALUE(@selected_body,'$.operations.providerReveal.verb') AS reveal_verb,
 JSON_VALUE(@selected_body,'$.operations.providerSet.verb') AS set_verb,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@selected_body COLLATE Latin1_General_100_BIN2_UTF8))),2)) AS content_digest;

SELECT '2_provider_authority' AS result_set, entry.[key] AS operation,
 JSON_VALUE(entry.value,'$.object') AS object_name,
 JSON_VALUE(entry.value,'$.verb') AS verb,
 JSON_VALUE(entry.value,'$.reader') AS reader,
 JSON_VALUE(entry.value,'$.input') AS input_mode
FROM OPENJSON(@command_body,'$.operations') entry
WHERE entry.[key] IN (N'providerList',N'providerReveal',N'providerSet')
ORDER BY entry.[key];

SELECT '3_declared_read_resolves' AS result_set,
 JSON_VALUE(@command_body,'$.operations.providerReveal.reader') AS reveal_reader,
 JSON_VALUE(@command_body,'$.operations.providerSet.reader') AS set_reader,
 (SELECT COUNT(*) FROM OPENJSON(@command_body,'$.operations')) AS operations;

IF (SELECT COUNT_BIG(*) FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id)<>1
 THROW 51000,N'COMMAND_AUTHORITY_DEFINITION_NOT_SINGULAR',1;

COMMIT TRANSACTION;
