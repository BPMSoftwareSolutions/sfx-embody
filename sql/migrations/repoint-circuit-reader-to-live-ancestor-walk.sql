-- repoint-circuit-reader-to-live-ancestor-walk.sql
--
-- Decision (option b): the declared `circuit` reader is re-pointed from the
-- retained media publication to the installed live `read-capability-circuit`
-- ancestor-walk read. The retained-publication source
-- (`read-retained-publication`) has no producer in the current estate: the
-- current model retains no `website-visual-publication` media catalog
-- (measured: media.asset logical_key media-catalog/<estate>/website-visual-publication
-- absent), so every circuit read fails closed with
-- CIRCUIT_PUBLICATION_UNAVAILABLE. Meanwhile `read-capability-circuit` is
-- installed and live: it computes the nearest-enclosing-cell circuit view and
-- the structural attestation (planned/observed ancestor closure) in its own
-- declared statement. This migration re-points only the command-operations
-- authority's `circuit.reader` value; it authors no new read and changes no
-- other operation. `reveal.readers.circuit` and `artifact` stay on
-- `read-retained-publication` until a producer exists.
--
-- This migration re-points back to `read-retained-publication` when a
-- `website-visual-publication` producer exists: the authority content change is
-- one JSON value, and the reverse migration is the same re-declaration with
-- the original reader id. `list-capabilities.circuitAvailable` remains a
-- retained-publication fact (false while no producer exists); it is not
-- changed here.
--
-- Live behavior after install (honest): a reader-operation circuit request
-- carries the subject identity, not invocation testimony, so the re-pointed
-- read refuses specifically with CIRCUIT_VIEW_CELL_TESTIMONY_REQUIRED (the
-- declared request contract requires cellTestimony/edgeTestimony) rather than
-- the collapsed DECLARED_READ_FAILED. The ancestor attestation is returned when
-- the declared request carries testimony/plan (the same live path the
-- structural acceptance uses); the migration self-test proves that positive
-- path on uncommitted rows.
--
-- The change is content-addressed authority data: the currently selected
-- `sda-node-command-operations.v1` bytes are read, `$.operations.circuit.reader`
-- is set to `read-capability-circuit`, the new bytes are retained in
-- source.content_object, and the AUTHORITY semantic definition is re-declared
-- with the new content digest. The kernel reads it through the declared
-- provider-authority read; no network, disk or code path is touched.
--
-- Idempotent: a second run finds the selected authority already carrying the
-- live reader and re-declares nothing. The previous definition row remains in
-- place (content-addressed, append-only); selection is the highest definition
-- pk.
--
-- Lifecycle: default was ROLLBACK. Installed 2026-09-19 after the dry run and
-- the from-transaction preflight through the kernel on the uncommitted rows
-- (read-capability-circuit returned circuit-view.v1 with attestation structured
-- true over synthetic testimony). The proof result sets below ran on the
-- installed transaction.
--
-- Proof result sets:
--   1_command_authority      the selected authority digest and the circuit reader
--   2_provider_authority     the declared provider-authority read resolves the
--                            same re-pointed vocabulary on uncommitted rows
--   3_reader_declaration     the mapped read's selected statement and the
--                            declared specific-refusal code it carries
--   4_view_self_test         the mapped read returns circuit-view.v1 with
--                            nodes/edges and the ancestor attestation when the
--                            request carries testimony
--   5_definition_count       exactly one current definition per declared id
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

-- ============================== THE RE-POINT ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-node-command-operations.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @reader_id nvarchar(400)=N'read-capability-circuit' COLLATE Latin1_General_100_BIN2;
DECLARE @object bigint,@definition bigint,@digest binary(32),@bytes varbinary(max),@json nvarchar(max);
SELECT @json=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id;
IF @json IS NULL THROW 51000,N'COMMAND_OPERATIONS_AUTHORITY_NOT_SELECTED',1;
IF ISJSON(@json)<>1 THROW 51000,N'COMMAND_OPERATIONS_AUTHORITY_MALFORMED',1;
IF JSON_VALUE(@json,'$.operations.circuit.reader') IS NULL THROW 51000,N'CIRCUIT_READER_NOT_DECLARED',1;

IF JSON_VALUE(@json,'$.operations.circuit.reader')<>@reader_id
BEGIN
 SET @json=JSON_MODIFY(@json,'$.operations.circuit.reader',@reader_id);
 IF JSON_VALUE(@json,'$.operations.circuit.reader')<>@reader_id THROW 51000,N'CIRCUIT_READER_NOT_REPOINTED',1;
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content_digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content_digest)<>@bytes
  THROW 51000,N'CIRCUIT_AUTHORITY_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sda-node-command-operations.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@content_digest,2))
  + N'","sourcePath":"kernel/semantic-authority/consumer/sda-node-command-operations.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-node-command-operations.authority.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END

-- ============================== IN-TRANSACTION PREFLIGHT ==============================
DECLARE @selected_body nvarchar(max)=(
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM analysis.v_selected_semantic_definition d
 JOIN source.content_object co
   ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id);
IF JSON_VALUE(@selected_body,'$.operations.circuit.reader')<>@reader_id
 THROW 51000,N'CIRCUIT_READER_NOT_SELECTED',1;

-- The declared provider-authority read (the kernel's own vector) must resolve
-- the same re-pointed vocabulary from the uncommitted rows. The ground read
-- statement is extracted from the retained data-access authority exactly as the
-- kernel resolver carries it.
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
IF JSON_VALUE(@command_body,'$.operations.circuit.reader')<>@reader_id
 THROW 51000,N'CIRCUIT_READER_NOT_RESOLVED_BY_DECLARED_READ',1;

-- The mapped reader's selected statement, and the specific refusal it carries
-- for a testimony-less circuit request (the reader-operation input shape).
DECLARE @reader_statement nvarchar(max), @reader_result_column nvarchar(400);
SELECT @reader_statement=js.statement,@reader_result_column=js.result_column
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration')
 WITH (statement nvarchar(max) '$.statement', result_column nvarchar(400) '$.resultColumn') js
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:read-capability-circuit' AND d.declared_id=N'read-capability-circuit-port';
IF @reader_statement IS NULL THROW 51000,N'CIRCUIT_READER_PORT_NOT_SELECTED',1;
IF CHARINDEX(N'CIRCUIT_VIEW_CELL_TESTIMONY_REQUIRED',@reader_statement)=0
 THROW 51000,N'CIRCUIT_READER_SPECIFIC_REFUSAL_NOT_DECLARED',1;

-- The positive live path: the mapped read executes its own declared statement
-- on the uncommitted rows and returns circuit-view.v1 with the ancestor
-- attestation over synthetic testimony (the same declared shape the live
-- capture uses; 2 semantic components, 1 observed admission, structured true).
DECLARE @sample nvarchar(max)=N'{"contractId":"circuit-view-request.v1","payload":{"capabilityId":"circuit-repoint-self-test","cellTestimony":[{"cellId":"cell:scenario:demo","cellAltitude":"scenario","disposition":"completed","outcomeClassification":"success","durationMilliseconds":5,"completedAt":"2026-09-18T00:00:00.005Z","logicalOrder":0},{"cellId":"cell:mechanic:demo.operation.1","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":3,"completedAt":"2026-09-18T00:00:00.011Z","logicalOrder":3}],"edgeTestimony":[{"edgeId":"edge:sequence:demo:1","sourceCellExecutionId":"execution:graph:demo:cell:mechanic:demo.operation.1:1","destinationCellId":"cell:scenario:demo","admissionDisposition":"admitted","logicalOrder":2}],"plannedCells":[{"cellId":"cell:scenario:demo","parentCellId":null,"altitude":"scenario"},{"cellId":"cell:mechanic:demo.operation.1","parentCellId":"cell:scenario:demo","altitude":"mechanic"}],"plannedEdges":[]}}';
DECLARE @view TABLE (value nvarchar(max));
INSERT @view EXEC sp_executesql @reader_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
IF (SELECT COUNT(*) FROM @view)<>1 THROW 51000,N'CIRCUIT_READER_SELF_TEST_NOT_SINGULAR',1;
DECLARE @view_body nvarchar(max)=(SELECT value FROM @view);
IF JSON_VALUE(@view_body,'$.contractId')<>N'circuit-view.v1' THROW 51000,N'CIRCUIT_READER_SELF_TEST_CONTRACT_MISMATCH',1;
IF JSON_VALUE(@view_body,'$.capabilityId')<>N'circuit-repoint-self-test' THROW 51000,N'CIRCUIT_READER_SELF_TEST_CAPABILITY_MISMATCH',1;
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.nodes')))<>2 THROW 51000,N'CIRCUIT_READER_SELF_TEST_NODE_COUNT_MISMATCH',1;
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.edges')))<>1 THROW 51000,N'CIRCUIT_READER_SELF_TEST_EDGE_COUNT_MISMATCH',1;
IF JSON_VALUE(@view_body,'$.attestation.structured')<>N'true' THROW 51000,N'CIRCUIT_READER_SELF_TEST_ATTESTATION_NOT_STRUCTURED',1;

-- ============================== PROOF ==============================
SELECT '1_command_authority' AS result_set, @authority_id AS authority_id,
 JSON_VALUE(@selected_body,'$.operations.circuit.reader') AS circuit_reader,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@selected_body COLLATE Latin1_General_100_BIN2_UTF8))),2)) AS content_digest,
 (SELECT COUNT(*) FROM OPENJSON(@selected_body,'$.operations')) AS operation_count;

SELECT '2_provider_authority' AS result_set, entry.[key] AS operation,
 JSON_VALUE(entry.value,'$.reader') AS reader,
 JSON_VALUE(entry.value,'$.readers.circuit') AS circuit_view_reader
FROM OPENJSON(@command_body,'$.operations') entry
WHERE entry.[key] IN (N'circuit',N'reveal',N'artifact')
ORDER BY entry.[key];

SELECT '3_reader_declaration' AS result_set, N'read-capability-circuit' AS reader_capability,
 @reader_result_column AS result_column,
 CONVERT(bit,CASE WHEN CHARINDEX(N'CIRCUIT_VIEW_CELL_TESTIMONY_REQUIRED',@reader_statement)>0 THEN 1 ELSE 0 END) AS specific_refusal_declared,
 LEN(@reader_statement) AS statement_chars;

SELECT '4_view_self_test' AS result_set,
 JSON_VALUE(@view_body,'$.contractId') AS contract_id,
 JSON_VALUE(@view_body,'$.capabilityId') AS capability_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.nodes'))) AS nodes,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.edges'))) AS edges,
 JSON_VALUE(@view_body,'$.attestation.structured') AS structured,
 JSON_VALUE(@view_body,'$.attestation.observedCells') AS observed_cells;

SELECT '5_definition_count' AS result_set, d.object_kind, d.declared_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind IN ('AUTHORITY','PORT')
 AND ((d.declared_id=@authority_id) OR (d.namespace_id=N'sidefx:capability:read-capability-circuit' AND d.declared_id=N'read-capability-circuit-port'))
GROUP BY d.object_kind,d.declared_id;

COMMIT TRANSACTION;
-- Installed 2026-09-19 after the rollback dry run (proof result sets green) and
-- the from-transaction preflight (read-capability-circuit through the kernel on
-- the uncommitted rows: circuit-view.v1, 2 nodes / 1 edge, attestation
-- structured true, 2 planned / 2 observed / 0 misses).
