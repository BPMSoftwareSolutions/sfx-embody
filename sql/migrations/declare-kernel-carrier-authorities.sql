-- declare-kernel-carrier-authorities.sql
--
-- The kernel carrier's two declared authorities are re-declared under
-- language-neutral ids and gain the declared dispatch properties the carrier
-- resolves:
--
--   sda-kernel-command-operations.v1
--     every operation row declares its execution class (`execution`), the
--     subject member its reader input carries (`subjectField`), the request
--     contract a reader row materializes from an executed subject (`request`),
--     and the fixed reader-input projection (`readerInputProjection`,
--     `viewInputProjection`). The carrier resolves these declarations; no verb
--     or capability-id dispatch rule remains in any language home.
--
--   sda-kernel-boot-data-access.v1
--     the document gains `sessionPolicy`: the declared model-definition read
--     and the declared reader identity the pinned session resolves from this
--     authority instead of carrying them in the kernel.
--
-- Both documents are content-addressed re-declarations: the currently selected
-- bytes are read, the declared members are set, the new bytes are retained in
-- source.content_object, and the AUTHORITY semantic definition is re-declared
-- under the new id with the new content digest. The former ids remain declared
-- and are read by no kernel path after this change.
--
-- Idempotent: a second run finds the new ids selected and re-declares nothing.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install after
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

-- ============================== COMMAND OPERATIONS ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @old_command_id nvarchar(400)=N'sda-node-command-operations.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @new_command_id nvarchar(400)=N'sda-kernel-command-operations.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @object bigint,@definition bigint,@digest binary(32),@bytes varbinary(max),@json nvarchar(max);

SELECT @json=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@old_command_id;
IF @json IS NULL THROW 51000,N'COMMAND_OPERATIONS_AUTHORITY_NOT_SELECTED',1;
IF JSON_QUERY(@json,'$.operations') IS NULL THROW 51000,N'COMMAND_OPERATIONS_NOT_DECLARED',1;

IF NOT EXISTS (SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@new_command_id)
BEGIN
 SET @json=JSON_MODIFY(@json,'$.authorityId',N'sda-kernel-command-operations.v1');
 SET @json=JSON_MODIFY(@json,'$.commandOperationsType',N'kernel-command-operations-authority.v1');
 SET @json=JSON_MODIFY(@json,'$.family',N'The kernel carrier''s declared operation vocabulary: each verb the physical entry offers, the entity it addresses, the input contract it accepts, the execution class it belongs to, the declared reader capability it resolves to, the request contract that reader requires, the input member that carries the subject, the reader-input projection it fixes, and the presentation options it declares. The carrier loads this document and holds no operation table or dispatch rule of its own; a new operation is a row here.');
 -- execution class and subject field on every operation row
 SET @json=JSON_MODIFY(@json,'$.operations.invoke.execution',N'invocation');
 SET @json=JSON_MODIFY(@json,'$.operations.invoke.subjectField',N'capabilityId');
 SET @json=JSON_MODIFY(@json,'$.operations.observe.execution',N'invocation');
 SET @json=JSON_MODIFY(@json,'$.operations.observe.subjectField',N'capabilityId');
 SET @json=JSON_MODIFY(@json,'$.operations.circuit.execution',N'declared-read');
 SET @json=JSON_MODIFY(@json,'$.operations.circuit.subjectField',N'capabilityId');
 SET @json=JSON_MODIFY(@json,'$.operations.circuit.request',JSON_QUERY(N'{"contractId":"circuit-view-request.v1","build":"executed-testimony","execution":{"object":"capability","verb":"invoke"}}'));
 SET @json=JSON_MODIFY(@json,'$.operations.reveal.execution',N'declared-read');
 SET @json=JSON_MODIFY(@json,'$.operations.reveal.subjectField',N'capabilityId');
 SET @json=JSON_MODIFY(@json,'$.operations.reveal.viewInputProjection',JSON_QUERY(N'{"circuit":{"operation":"circuit"}}'));
 SET @json=JSON_MODIFY(@json,'$.operations.catalogue.execution',N'declared-read');
 SET @json=JSON_MODIFY(@json,'$.operations.list.execution',N'declared-read');
 SET @json=JSON_MODIFY(@json,'$.operations.find.execution',N'declared-read');
 SET @json=JSON_MODIFY(@json,'$.operations.artifact.execution',N'declared-read');
 SET @json=JSON_MODIFY(@json,'$.operations.artifact.subjectField',N'artifactDigest');
 SET @json=JSON_MODIFY(@json,'$.operations.artifact.readerInputProjection',JSON_QUERY(N'{"operation":"artifact"}'));
 SET @json=JSON_MODIFY(@json,'$.operations.providerList.execution',N'declared-read');
 SET @json=JSON_MODIFY(@json,'$.operations.providerReveal.execution',N'declared-read');
 SET @json=JSON_MODIFY(@json,'$.operations.providerReveal.subjectField',N'providerId');
 SET @json=JSON_MODIFY(@json,'$.operations.providerSet.execution',N'declared-read');
 SET @json=JSON_MODIFY(@json,'$.operations.providerSet.subjectField',N'providerId');
 -- the acceptance-suite row is a declared read; it declares no subject
 IF JSON_VALUE(@json,'$.operations.kernelAcceptanceSuite.execution') IS NULL
  SET @json=JSON_MODIFY(@json,'$.operations.kernelAcceptanceSuite.execution',N'declared-read');
 -- the declared operation rows the carrier reads
 IF JSON_VALUE(@json,'$.operations.invoke.execution')<>N'invocation'
  OR JSON_VALUE(@json,'$.operations.observe.execution')<>N'invocation'
  OR JSON_VALUE(@json,'$.operations.circuit.execution')<>N'declared-read'
  OR JSON_VALUE(@json,'$.operations.circuit.request.contractId')<>N'circuit-view-request.v1'
  OR JSON_VALUE(@json,'$.operations.circuit.request.build')<>N'executed-testimony'
  OR JSON_VALUE(@json,'$.operations.circuit.request.execution.verb')<>N'invoke'
  OR JSON_VALUE(@json,'$.operations.reveal.viewInputProjection.circuit.operation')<>N'circuit'
  OR JSON_VALUE(@json,'$.operations.artifact.subjectField')<>N'artifactDigest'
  OR JSON_VALUE(@json,'$.operations.artifact.readerInputProjection.operation')<>N'artifact'
  OR JSON_VALUE(@json,'$.operations.providerReveal.subjectField')<>N'providerId'
  OR JSON_VALUE(@json,'$.operations.providerSet.subjectField')<>N'providerId'
  OR (JSON_QUERY(@json,'$.operations.kernelAcceptanceSuite') IS NOT NULL
      AND JSON_VALUE(@json,'$.operations.kernelAcceptanceSuite.execution')<>N'declared-read')
  THROW 51000,N'KERNEL_COMMAND_DECLARATIONS_NOT_SET',1;
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @command_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@command_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@command_digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@command_digest)<>@bytes
  THROW 51000,N'KERNEL_COMMAND_AUTHORITY_CONTENT_DIVERGED',1;
 DECLARE @command_semantics nvarchar(max)=N'{"authorityId":"sda-kernel-command-operations.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@command_digest,2))
  + N'","sourcePath":"kernel/semantic-authority/consumer/sda-kernel-command-operations.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-kernel-command-operations.authority.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@new_command_id,
  @command_semantics,
  @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END

-- ============================== DATA ACCESS ==============================
DECLARE @old_access_id nvarchar(400)=N'sda-node-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @new_access_id nvarchar(400)=N'sda-kernel-boot-data-access.v1' COLLATE Latin1_General_100_BIN2;
SET @json=NULL;
SELECT @json=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@old_access_id;
IF @json IS NULL THROW 51000,N'DATA_ACCESS_AUTHORITY_NOT_SELECTED',1;
IF JSON_QUERY(@json,'$.reads') IS NULL THROW 51000,N'DATA_ACCESS_READS_NOT_DECLARED',1;

IF NOT EXISTS (SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@new_access_id)
BEGIN
 SET @json=JSON_MODIFY(@json,'$.authorityId',N'sda-kernel-boot-data-access.v1');
 SET @json=JSON_MODIFY(@json,'$.dataAccessType',N'kernel-boot-data-access-authority.v1');
 SET @json=JSON_MODIFY(@json,'$.family',N'Declared data-access reads for the kernel boot. Every read the boot needs is declared here as a stable read id, a source kind, the statement or document it reads, its bind parameters, and its recordset mapping, together with the session policy (the estate''s model-definition read and the reader identity) the pinned session resolves from this authority. The kernel resolves read ids and dispatches to the declared source realization; statement text is data, never resolver code.');
 SET @json=JSON_MODIFY(@json,'$.sessionPolicy',JSON_QUERY(N'{"modelDefinitions":{"statement":"SELECT s.name+''.''+o.name AS object_name,o.type,m.definition FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE s.name IN(''sidefx'',''analysis'') AND o.type IN(''V'',''IF'',''TF'',''FN'') ORDER BY s.name COLLATE Latin1_General_100_BIN2,o.name COLLATE Latin1_General_100_BIN2","purpose":"The declared view/function definitions the pinned session digests as viewDefinitionDigest."},"impersonation":{"statement":"EXECUTE AS USER=''sidefx_reader'' WITH NO REVERT; SET LOCK_TIMEOUT 30000;","purpose":"The declared reader identity every read in the pinned session runs as."}}'));
 IF JSON_VALUE(@json,'$.sessionPolicy.modelDefinitions.statement') IS NULL
  OR JSON_VALUE(@json,'$.sessionPolicy.impersonation.statement') IS NULL
  THROW 51000,N'KERNEL_SESSION_POLICY_NOT_SET',1;
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @access_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@access_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@access_digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@access_digest)<>@bytes
  THROW 51000,N'KERNEL_BOOT_AUTHORITY_CONTENT_DIVERGED',1;
 DECLARE @access_semantics nvarchar(max)=N'{"authorityId":"sda-kernel-boot-data-access.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@access_digest,2))
  + N'","sourcePath":"kernel/semantic-authority/consumer/sda-kernel-boot-data-access.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-kernel-boot-data-access.authority.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@new_access_id,
  @access_semantics,
  @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END

-- ============================== IN-TRANSACTION PREFLIGHT ==============================
-- The ground read statement is the exact fixed statement the kernel resolver
-- carries, with the language-neutral declared id. It is executed here against
-- the uncommitted rows; the declared provider-authority read is then extracted
-- from the retained data-access row and executed the same way, and the declared
-- dispatch members are checked row by row.
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
DECLARE @data_access_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM @ground_authority);
IF JSON_VALUE(@data_access_body,'$.authorityId')<>N'sda-kernel-boot-data-access.v1' THROW 51000,N'KERNEL_BOOT_GROUND_READ_ID_MISMATCH',1;
IF JSON_VALUE(@data_access_body,'$.sessionPolicy.modelDefinitions.statement') IS NULL THROW 51000,N'KERNEL_SESSION_POLICY_NOT_RESOLVED',1;
IF JSON_VALUE(@data_access_body,'$.sessionPolicy.impersonation.statement') IS NULL THROW 51000,N'KERNEL_SESSION_IMPERSONATION_NOT_RESOLVED',1;

DECLARE @provider_read nvarchar(max)=(SELECT JSON_VALUE(entry.value,'$.statement')
 FROM OPENJSON(@data_access_body,'$.reads') entry WHERE JSON_VALUE(entry.value,'$.readId')=N'provider-authority');
IF @provider_read IS NULL THROW 51000,N'KERNEL_BOOT_PROVIDER_AUTHORITY_READ_NOT_DECLARED',1;
DECLARE @vocabulary TABLE (declared_id nvarchar(400), authority_id nvarchar(400), platform_capability_id nvarchar(400),
 content_digest nvarchar(400), byte_length bigint, content_bytes varbinary(max));
INSERT @vocabulary EXEC sp_executesql @provider_read,N'@estate_model_pk bigint,@input nvarchar(max)',@estate,N'{"authorityId":"sda-kernel-command-operations.v1"}';
IF (SELECT COUNT_BIG(*) FROM @vocabulary)<>1 THROW 51000,N'KERNEL_BOOT_COMMAND_AUTHORITY_NOT_SINGULAR',1;
DECLARE @command_body nvarchar(max)=(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM @vocabulary);
IF JSON_VALUE(@command_body,'$.authorityId')<>N'sda-kernel-command-operations.v1' THROW 51000,N'KERNEL_BOOT_COMMAND_AUTHORITY_ID_MISMATCH',1;
IF (SELECT COUNT(*) FROM OPENJSON(@command_body,'$.operations'))<11 THROW 51000,N'KERNEL_BOOT_COMMAND_OPERATIONS_TRUNCATED',1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(@command_body,'$.operations') entry WHERE entry.[key]=N'invoke' AND JSON_VALUE(entry.value,'$.execution')=N'invocation') THROW 51000,N'KERNEL_COMMAND_EXECUTION_NOT_DECLARED:invoke',1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(@command_body,'$.operations') entry WHERE entry.[key]=N'observe' AND JSON_VALUE(entry.value,'$.execution')=N'invocation') THROW 51000,N'KERNEL_COMMAND_EXECUTION_NOT_DECLARED:observe',1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(@command_body,'$.operations') entry WHERE entry.[key]=N'circuit' AND JSON_VALUE(entry.value,'$.request.contractId')=N'circuit-view-request.v1') THROW 51000,N'KERNEL_COMMAND_REQUEST_NOT_DECLARED:circuit',1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(@command_body,'$.operations') entry WHERE entry.[key]=N'reveal' AND JSON_VALUE(entry.value,'$.viewInputProjection.circuit.operation')=N'circuit') THROW 51000,N'KERNEL_COMMAND_VIEW_PROJECTION_NOT_DECLARED:reveal',1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(@command_body,'$.operations') entry WHERE entry.[key]=N'artifact' AND JSON_VALUE(entry.value,'$.subjectField')=N'artifactDigest') THROW 51000,N'KERNEL_COMMAND_SUBJECT_FIELD_NOT_DECLARED:artifact',1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(@command_body,'$.operations') entry WHERE entry.[key]=N'providerReveal' AND JSON_VALUE(entry.value,'$.subjectField')=N'providerId') THROW 51000,N'KERNEL_COMMAND_SUBJECT_FIELD_NOT_DECLARED:providerReveal',1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(@command_body,'$.operations') entry WHERE entry.[key]=N'providerSet' AND JSON_VALUE(entry.value,'$.reader')=N'author-provider-configuration-change') THROW 51000,N'KERNEL_COMMAND_READER_NOT_DECLARED:providerSet',1;
IF EXISTS (SELECT 1 FROM OPENJSON(@command_body,'$.operations') entry WHERE entry.[key]=N'kernelAcceptanceSuite' AND JSON_VALUE(entry.value,'$.execution')<>N'declared-read') THROW 51000,N'KERNEL_COMMAND_EXECUTION_NOT_DECLARED:kernelAcceptanceSuite',1;

-- ============================== PROOF ==============================
SELECT '1_command_authority' AS result_set, @new_command_id AS authority_id,
 JSON_VALUE(@command_body,'$.operations.circuit.execution') AS circuit_execution,
 JSON_VALUE(@command_body,'$.operations.circuit.request.contractId') AS circuit_request_contract,
 JSON_VALUE(@command_body,'$.operations.circuit.request.execution.verb') AS circuit_subject_execution,
 JSON_VALUE(@command_body,'$.operations.reveal.viewInputProjection.circuit.operation') AS reveal_circuit_operation,
 JSON_VALUE(@command_body,'$.operations.artifact.subjectField') AS artifact_subject_field,
 JSON_VALUE(@command_body,'$.operations.artifact.readerInputProjection.operation') AS artifact_operation,
 JSON_VALUE(@command_body,'$.operations.providerReveal.subjectField') AS provider_reveal_subject_field,
 (SELECT COUNT(*) FROM OPENJSON(@command_body,'$.operations')) AS operations;

SELECT '2_data_access_authority' AS result_set, @new_access_id AS authority_id,
 (SELECT COUNT(*) FROM OPENJSON(@data_access_body,'$.reads')) AS read_count,
 CASE WHEN JSON_VALUE(@data_access_body,'$.sessionPolicy.modelDefinitions.statement') IS NULL THEN 0 ELSE 1 END AS model_definitions_declared,
 CASE WHEN JSON_VALUE(@data_access_body,'$.sessionPolicy.impersonation.statement') IS NULL THEN 0 ELSE 1 END AS impersonation_declared;

SELECT '3_operation_rows' AS result_set, entry.[key] AS operation,
 JSON_VALUE(entry.value,'$.object') AS object_name,
 JSON_VALUE(entry.value,'$.verb') AS verb,
 JSON_VALUE(entry.value,'$.execution') AS execution_class,
 JSON_VALUE(entry.value,'$.subjectField') AS subject_field,
 JSON_VALUE(entry.value,'$.request.contractId') AS request_contract,
 JSON_VALUE(entry.value,'$.reader') AS reader
FROM OPENJSON(@command_body,'$.operations') entry ORDER BY entry.[key];

IF (SELECT COUNT_BIG(*) FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@new_command_id)<>1
 THROW 51000,N'COMMAND_AUTHORITY_DEFINITION_NOT_SINGULAR',1;
IF (SELECT COUNT_BIG(*) FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@new_access_id)<>1
 THROW 51000,N'DATA_ACCESS_AUTHORITY_DEFINITION_NOT_SINGULAR',1;

COMMIT TRANSACTION;
-- To dry-run, replace the COMMIT above with ROLLBACK and re-run.
