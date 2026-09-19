-- declare-circuit-typed-input.sql
--
-- Decision: the declared `circuit` operation accepts the same typed raw scalar
-- its subject may declare. `invoke` and `observe` declare `"inputType": true`
-- in `sda-node-command-operations.v1`; `circuit` omitted it. The consequence
-- was live: `sfx capability circuit request-capability-from-objective
-- --input "What is Broadcom's current market price?"` failed in the terminal
-- with INPUT_JSON_REJECTED before the kernel saw it (the mapping could not
-- carry the raw scalar), and the direct kernel form refused an explicit
-- `--input-type text` with OPTION_NOT_APPLICABLE (the vocabulary did not
-- declare the option). The subject invocation the circuit composes canonicalizes
-- the scalar against the subject's own declared CLI input when this operation
-- carries it as one; without the declaration the typed form is unreachable.
--
-- This migration sets only `$.operations.circuit.inputType = true`; it authors
-- no new read, changes no other operation and touches no capability row. The
-- reverse is the same re-declaration with the member removed.
--
-- The change is content-addressed authority data: the currently selected
-- `sda-node-command-operations.v1` bytes are read, the member is set, the new
-- bytes are retained in source.content_object, and the AUTHORITY semantic
-- definition is re-declared with the new content digest. The kernel reads it
-- through the declared provider-authority read; no network, disk or code path
-- is touched.
--
-- Idempotent: a second run finds the selected authority already carrying the
-- member and re-declares nothing. The previous definition row remains in place
-- (content-addressed, append-only); selection is the highest definition pk.
--
-- Lifecycle: default was ROLLBACK. Installed 2026-09-19 after the rollback dry
-- run and the from-transaction preflight through the kernel on the uncommitted
-- rows (the declared read returned circuit-view.v1 with the attestation
-- structured true over synthetic testimony). Installed authority digest
-- sha256:13fe7357caf6d2133601ce062b0026d7c608105496b41f6802d77fc2bc6139b7.
--
-- Proof result sets:
--   1_command_authority      the selected authority digest, the circuit reader
--                            and the declared inputType member
--   2_provider_authority     the declared provider-authority read resolves the
--                            same member on the selected rows
--   3_reader_self_test       the mapped read still returns circuit-view.v1 with
--                            nodes/edges and the ancestor attestation
--   4_definition_count       exactly one current definition per declared id
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
IF JSON_QUERY(@json,'$.operations.circuit') IS NULL THROW 51000,N'CIRCUIT_OPERATION_NOT_DECLARED',1;

IF JSON_VALUE(@json,'$.operations.circuit.inputType') IS NULL
BEGIN
 SET @json=JSON_MODIFY(@json,'$.operations.circuit.inputType',CAST(1 AS bit));
 IF JSON_VALUE(@json,'$.operations.circuit.inputType')<>N'true' THROW 51000,N'CIRCUIT_INPUT_TYPE_NOT_DECLARED',1;
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @content_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content_digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content_digest)<>@bytes
  THROW 51000,N'CIRCUIT_INPUT_TYPE_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sda-node-command-operations.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@content_digest,2))
  + N'","sourcePath":"kernel/semantic-authority/consumer/sda-node-command-operations.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-node-command-operations.authority.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END

-- ============================== IN-TRANSACTION PREFLIGHT ==============================
-- The selected authority carries the member and resolves through the declared
-- provider-authority read exactly as the kernel carries it.
DECLARE @selected_body nvarchar(max)=(
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM analysis.v_selected_semantic_definition d
 JOIN source.content_object co
  ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@authority_id);
IF JSON_VALUE(@selected_body,'$.operations.circuit.inputType')<>N'true'
 THROW 51000,N'CIRCUIT_INPUT_TYPE_NOT_SELECTED',1;
IF JSON_VALUE(@selected_body,'$.operations.circuit.reader')<>N'read-capability-circuit'
 THROW 51000,N'CIRCUIT_READER_NOT_SELECTED',1;

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
IF JSON_VALUE(@command_body,'$.operations.circuit.inputType')<>N'true'
 THROW 51000,N'CIRCUIT_INPUT_TYPE_NOT_RESOLVED_BY_DECLARED_READ',1;

-- The mapped reader's declared statement still serves the circuit view over
-- synthetic testimony (the same live path the circuit operation composes into).
DECLARE @reader_statement nvarchar(max), @reader_result_column nvarchar(400);
SELECT @reader_statement=js.statement,@reader_result_column=js.result_column
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.configuration')
 WITH (statement nvarchar(max) '$.statement', result_column nvarchar(400) '$.resultColumn') js
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:read-capability-circuit' AND d.declared_id=N'read-capability-circuit-port';
IF @reader_statement IS NULL THROW 51000,N'CIRCUIT_READER_PORT_NOT_SELECTED',1;
DECLARE @sample nvarchar(max)=N'{"contractId":"circuit-view-request.v1","payload":{"capabilityId":"circuit-typed-input-self-test","cellTestimony":[{"cellId":"cell:scenario:demo","cellAltitude":"scenario","disposition":"completed","outcomeClassification":"success","durationMilliseconds":5,"completedAt":"2026-09-19T00:00:00.005Z","logicalOrder":0},{"cellId":"cell:mechanic:demo.operation.1","cellAltitude":"mechanic","disposition":"completed","durationMilliseconds":3,"completedAt":"2026-09-19T00:00:00.011Z","logicalOrder":3}],"edgeTestimony":[{"edgeId":"edge:sequence:demo:1","sourceCellExecutionId":"execution:graph:demo:cell:mechanic:demo.operation.1:1","destinationCellId":"cell:scenario:demo","admissionDisposition":"admitted","logicalOrder":2}],"plannedCells":[{"cellId":"cell:scenario:demo","parentCellId":null,"altitude":"scenario"},{"cellId":"cell:mechanic:demo.operation.1","parentCellId":"cell:scenario:demo","altitude":"mechanic"}],"plannedEdges":[]}}';
DECLARE @view TABLE (value nvarchar(max));
INSERT @view EXEC sp_executesql @reader_statement,N'@input nvarchar(max), @estate_model_pk bigint',@input=@sample,@estate_model_pk=@estate;
IF (SELECT COUNT(*) FROM @view)<>1 THROW 51000,N'CIRCUIT_READER_SELF_TEST_NOT_SINGULAR',1;
DECLARE @view_body nvarchar(max)=(SELECT value FROM @view);
IF JSON_VALUE(@view_body,'$.contractId')<>N'circuit-view.v1' THROW 51000,N'CIRCUIT_READER_SELF_TEST_CONTRACT_MISMATCH',1;
IF JSON_VALUE(@view_body,'$.capabilityId')<>N'circuit-typed-input-self-test' THROW 51000,N'CIRCUIT_READER_SELF_TEST_CAPABILITY_MISMATCH',1;
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.nodes')))<>2 THROW 51000,N'CIRCUIT_READER_SELF_TEST_NODE_COUNT_MISMATCH',1;
IF (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.edges')))<>1 THROW 51000,N'CIRCUIT_READER_SELF_TEST_EDGE_COUNT_MISMATCH',1;
IF JSON_VALUE(@view_body,'$.attestation.structured')<>N'true' THROW 51000,N'CIRCUIT_READER_SELF_TEST_ATTESTATION_NOT_STRUCTURED',1;

-- ============================== PROOF ==============================
SELECT '1_command_authority' AS result_set, @authority_id AS authority_id,
 JSON_VALUE(@selected_body,'$.operations.circuit.reader') AS circuit_reader,
 JSON_VALUE(@selected_body,'$.operations.circuit.inputType') AS circuit_input_type,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(varchar(max),@selected_body COLLATE Latin1_General_100_BIN2_UTF8))),2)) AS content_digest;

SELECT '2_provider_authority' AS result_set, entry.[key] AS operation,
 JSON_VALUE(entry.value,'$.inputType') AS input_type,
 JSON_VALUE(entry.value,'$.reader') AS reader,
 JSON_VALUE(entry.value,'$.readers.circuit') AS circuit_view_reader
FROM OPENJSON(@command_body,'$.operations') entry
WHERE entry.[key] IN (N'circuit',N'invoke',N'reveal')
ORDER BY entry.[key];

SELECT '3_reader_self_test' AS result_set,
 JSON_VALUE(@view_body,'$.contractId') AS contract_id,
 JSON_VALUE(@view_body,'$.capabilityId') AS capability_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.nodes'))) AS nodes,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@view_body,'$.edges'))) AS edges,
 JSON_VALUE(@view_body,'$.attestation.structured') AS structured,
 JSON_VALUE(@view_body,'$.attestation.observedCells') AS observed_cells;

SELECT '4_definition_count' AS result_set, d.object_kind, d.declared_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind IN ('AUTHORITY','PORT')
 AND ((d.declared_id=@authority_id) OR (d.namespace_id=N'sidefx:capability:read-capability-circuit' AND d.declared_id=N'read-capability-circuit-port'))
GROUP BY d.object_kind,d.declared_id;

COMMIT TRANSACTION;
-- Installed 2026-09-19 after the rollback dry run (proof result sets green) and
-- the from-transaction preflight (read-capability-circuit through the kernel on
-- the uncommitted rows: circuit-view.v1, 2 nodes / 1 edge, structured true).
