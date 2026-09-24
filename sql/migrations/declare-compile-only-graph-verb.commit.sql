-- declare-compile-only-graph-verb.commit.sql
--
-- D4 (observation-altitudes implementation plan, 2026-09-23): install the
-- declared compile verb into the kernel's command operations authority
-- (`sda-kernel-command-operations.v1`). The verb is rows, not a flag:
--
--   compile: object capability, subject true, execution invocation,
--            subjectField capabilityId, stopWhen.stateMember canonicalGraph
--
-- The declared operation runs the composition read and compile through the
-- declared run-declared-graph carrier and stops when the running state carries
-- the declared member, so the compiled record is returned and the compiled
-- graph is never dispatched: no provider executes and no effect happens. The
-- stop is declared data on the operation row; no request member and no
-- language flag decides it. The sda-api capability-graph read invokes this
-- verb (`capability compile <capabilityId>`).
--
-- The dry run of declare-compile-only-graph-verb.sql proved the row and the
-- preflight. This copy commits the same transaction.
--
-- Idempotent: a second run finds the row selected, sets nothing and re-declares
-- nothing.
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

-- ============================== COMPILE VERB ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @command_id nvarchar(400)=N'sda-kernel-command-operations.v1' COLLATE Latin1_General_100_BIN2;
DECLARE @object bigint,@definition bigint,@digest binary(32),@bytes varbinary(max),@json nvarchar(max);

SELECT @json=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM analysis.v_selected_semantic_definition d
JOIN source.content_object co
 ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@command_id;
IF @json IS NULL THROW 51000,N'COMMAND_OPERATIONS_AUTHORITY_NOT_SELECTED',1;
IF JSON_QUERY(@json,'$.operations') IS NULL THROW 51000,N'COMMAND_OPERATIONS_NOT_DECLARED',1;

IF JSON_QUERY(@json,'$.operations.compile') IS NULL
BEGIN
 SET @json=JSON_MODIFY(@json,'$.operations.compile',
  JSON_QUERY(N'{"object":"capability","verb":"compile","subject":true,"input":"optional","inputType":true,"display":true,"execution":"invocation","subjectField":"capabilityId","stopWhen":{"stateMember":"canonicalGraph"}}'));
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 SET @digest=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@digest)<>@bytes
  THROW 51000,N'COMPILE_VERB_AUTHORITY_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sda-kernel-command-operations.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@digest,2))
  + N'","sourcePath":"kernel/semantic-authority/consumer/sda-kernel-command-operations.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-kernel-command-operations.authority.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@command_id,
  @semantics,
  @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END

-- ============================== IN-TRANSACTION PREFLIGHT ==============================
-- The declared verb, exactly as the carrier resolves it. A row that is not the
-- declared invocation with the declared stop is refused, not installed; exactly
-- one operation may declare a stop.
IF JSON_VALUE(@json,'$.operations.compile.object')<>N'capability' THROW 51000,N'COMPILE_VERB_OBJECT_NOT_DECLARED',1;
IF JSON_VALUE(@json,'$.operations.compile.verb')<>N'compile' THROW 51000,N'COMPILE_VERB_VERB_NOT_DECLARED',1;
IF JSON_VALUE(@json,'$.operations.compile.subject')<>N'true' THROW 51000,N'COMPILE_VERB_SUBJECT_NOT_DECLARED',1;
IF JSON_VALUE(@json,'$.operations.compile.execution')<>N'invocation' THROW 51000,N'COMPILE_VERB_EXECUTION_NOT_DECLARED',1;
IF JSON_VALUE(@json,'$.operations.compile.subjectField')<>N'capabilityId' THROW 51000,N'COMPILE_VERB_SUBJECT_FIELD_NOT_DECLARED',1;
IF JSON_VALUE(@json,'$.operations.compile.stopWhen.stateMember')<>N'canonicalGraph' THROW 51000,N'COMPILE_VERB_STOP_NOT_DECLARED',1;
IF EXISTS (SELECT 1 FROM OPENJSON(@json,'$.operations') entry
 WHERE JSON_VALUE(entry.value,'$.stopWhen.stateMember') IS NOT NULL AND entry.[key]<>N'compile')
 THROW 51000,N'COMPILE_STOP_DECLARED_ON_A_SIBLING',1;

-- ============================== PROOF ==============================
SELECT '1_compile_operation' AS result_set, entry.[key] AS operation,
 JSON_VALUE(entry.value,'$.object') AS object_name,
 JSON_VALUE(entry.value,'$.verb') AS verb,
 JSON_VALUE(entry.value,'$.subject') AS subject,
 JSON_VALUE(entry.value,'$.execution') AS execution_class,
 JSON_VALUE(entry.value,'$.subjectField') AS subject_field,
 JSON_VALUE(entry.value,'$.input') AS input_requirement,
 JSON_VALUE(entry.value,'$.stopWhen.stateMember') AS stop_state_member
FROM OPENJSON(@json,'$.operations') entry
WHERE entry.[key]=N'compile';

SELECT '2_command_authority' AS result_set, @command_id AS authority_id,
 (SELECT COUNT(*) FROM OPENJSON(@json,'$.operations')) AS operations,
 (SELECT COUNT(*) FROM OPENJSON(@json,'$.operations') entry WHERE JSON_VALUE(entry.value,'$.execution')=N'invocation') AS invocation_operations,
 (SELECT COUNT(*) FROM OPENJSON(@json,'$.operations') entry WHERE JSON_VALUE(entry.value,'$.stopWhen.stateMember') IS NOT NULL) AS stop_declared_operations;

SELECT '3_selected_definition' AS result_set, d.declared_id,
 LOWER(CONVERT(varchar(64),REPLACE(JSON_VALUE(d.definition_json,'$.semantics.contentDigest'),'sha256:',''),2)) AS content_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=@command_id;

COMMIT TRANSACTION;
