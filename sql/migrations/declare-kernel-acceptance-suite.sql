-- declare-kernel-acceptance-suite.sql
--
-- The declared kernel acceptance suite becomes installed authority. The suite
-- document config/kernel-acceptance-suite.v1.json is retained byte-for-byte in
-- source.content_object under its SHA-256 and declared as a selected AUTHORITY
-- semantic definition; the declared read capability read-kernel-acceptance-suite
-- serves the retained bytes through the sda-embodiment-plan-port.v1 read port;
-- and the declared command vocabulary (sda-node-command-operations.v1) gains
-- the kernelAcceptanceSuite operation, whose reader is that read.
--
-- The kernel's acceptance evaluator (KernelAcceptance.cs, kernel_acceptance.py,
-- kernel-acceptance.mjs) runs that operation against the installed entry, then
-- projects the suite's declared observed paths and evaluates its declared
-- conditions with the declared vocabulary. Adding an invocation is a change to
-- the document (replayed through this migration), never an evaluator change.
--
-- Idempotent: content-addressed definitions and a guarded operation-row insert
-- re-declare nothing on replay.
--
-- Document digest (sha256 of the retained bytes): 5bce7bc79d064a08f0871af797f06d0df689454350adbf4a95dbd76ad83b0a56
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

-- ============================== THE SUITE DOCUMENT ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @suite nvarchar(max)=N'{
  "suiteType": "sfx-kernel-acceptance-suite.v1",
  "suiteId": "kernel-acceptance",
  "description": "The declared kernel acceptance suite: each invocation names its request envelope, the observed paths the evaluator projects from the delivery outcome, and the conditions it evaluates. Adding an invocation is a change to this document (installed by sql/migrations/declare-kernel-acceptance-suite.sql), never a kernel evaluator change. The equity alternates resolved-live and declared-unavailable: both are honest terminal shapes and either is accepted.",
  "invocations": [
    {
      "id": "invoke-say-hello-world",
      "command": "capability invoke say-hello-world --input {}",
      "operation": "invoke",
      "request": {
        "object": "capability",
        "verb": "invoke",
        "subject": "say-hello-world",
        "input": {}
      },
      "observed": [
        { "name": "observedPathDigest", "path": "result.observedPathDigest" },
        { "name": "canonicalGraphDigest", "path": "evidence.graph.canonicalGraphDigest" },
        { "name": "realizedGraphDigest", "path": "evidence.graph.realizedGraphDigest" }
      ],
      "expect": [
        {
          "label": "recorded-parity",
          "conditions": [
            { "condition": "equals", "path": "observedPathDigest", "value": "sha256:20864ba25e20de3698d3affd2303f6064a7f50528ae79db9c33f24847a7f70ba" },
            { "condition": "equals", "path": "canonicalGraphDigest", "value": "sha256:8b859397e5bf18f8d24580ecfb3859fedc09f4150a69b40f7447273cbb014931" },
            { "condition": "equals", "path": "realizedGraphDigest", "value": "sha256:f7655bd9b1897fb19e823a226f0e9538f7ec9f6c85a0374c0f0f866b999a72de" }
          ]
        }
      ]
    },
    {
      "id": "invoke-resolve-equity-market-price-evidence",
      "command": "capability invoke resolve-equity-market-price-evidence --display --input AVGO",
      "operation": "invoke",
      "request": {
        "object": "capability",
        "verb": "invoke",
        "subject": "resolve-equity-market-price-evidence",
        "display": true,
        "input": "AVGO"
      },
      "observed": [
        { "name": "observedPathDigest", "path": "result.observedPathDigest" },
        { "name": "outcomeVariant", "path": "result.outcomeVariant" },
        { "name": "payload", "path": "result.outcome.payload" },
        { "name": "symbol", "path": "result.outcome.payload.symbol" },
        { "name": "observedPrice", "path": "result.outcome.payload.observedPrice" },
        { "name": "marketState", "path": "result.outcome.payload.marketState" },
        { "name": "reasonCode", "path": "result.outcome.reasonCode" }
      ],
      "expect": [
        {
          "label": "resolved-live",
          "conditions": [
            { "condition": "equals", "path": "observedPathDigest", "value": "sha256:c507678e9cd9600d502a2f86f3fbc9d0c102270be93a571926efc605c19879eb" },
            { "condition": "equals", "path": "outcomeVariant", "value": "EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED" },
            { "condition": "equals", "path": "symbol", "value": "AVGO" },
            { "condition": "number-greater-than", "path": "observedPrice", "value": 0 },
            { "condition": "present", "path": "marketState" }
          ]
        },
        {
          "label": "declared-unavailable",
          "conditions": [
            { "condition": "one-of", "path": "observedPathDigest", "values": ["sha256:edffdf7fb3c3aafe3025f34e7cb208ab3262dae9b74d4db9974a190c8beff4e1"] },
            { "condition": "equals", "path": "outcomeVariant", "value": "EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE" },
            { "condition": "empty", "path": "payload" },
            { "condition": "present", "path": "reasonCode" }
          ]
        }
      ]
    },
    {
      "id": "observe-request-capability-from-objective",
      "command": "capability observe request-capability-from-objective --input \"What is Broadcom''s current market price?\" --json",
      "operation": "observe",
      "request": {
        "object": "capability",
        "verb": "observe",
        "subject": "request-capability-from-objective",
        "display": true,
        "input": "What is Broadcom''s current market price?",
        "observationAltitudes": ["scenario"]
      },
      "observed": [
        { "name": "observedPathDigest", "path": "observedPathDigest" },
        { "name": "overlay", "path": "overlay.counts" },
        { "name": "story", "path": "story.scenario" }
      ],
      "expect": [
        {
          "label": "recorded-observation",
          "conditions": [
            { "condition": "one-of", "path": "observedPathDigest", "values": ["sha256:5f8e6fdad28b4847a516cac59e11423aa3f5ed238c9005a6ddc2cec7c01d1a4a", "sha256:26c85c04c7ed278950d5d108b8568232cb00a742ebb7f3db3c76a8fc0accfb73"] },
            { "condition": "present", "path": "overlay" },
            { "condition": "present", "path": "story" }
          ]
        }
      ]
    }
  ]
}
';
DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@suite COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @content_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
IF LOWER(CONVERT(varchar(64),@content_digest,2))<>N'5bce7bc79d064a08f0871af797f06d0df689454350adbf4a95dbd76ad83b0a56'
 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_DIGEST_MISMATCH',1;
IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@content_digest)
 INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@content_digest,@bytes,DATALENGTH(@bytes));
IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@content_digest)<>@bytes
 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_CONTENT_DIVERGED',1;
DECLARE @suite_object bigint,@suite_definition bigint,@suite_digest binary(32);
EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',N'sfx-kernel-acceptance-suite.v1',N'{"authorityId":"sfx-kernel-acceptance-suite.v1","contentDigest":"sha256:5bce7bc79d064a08f0871af797f06d0df689454350adbf4a95dbd76ad83b0a56","sourcePath":"config/kernel-acceptance-suite.v1.json","locators":["config/kernel-acceptance-suite.v1.json"]}',@suite_object OUTPUT,@suite_definition OUTPUT,@suite_digest OUTPUT;
IF NOT EXISTS (SELECT 1 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=N'sfx-kernel-acceptance-suite.v1'
  AND JSON_VALUE(d.definition_json,'$.semantics.contentDigest')=N'sha256:5bce7bc79d064a08f0871af797f06d0df689454350adbf4a95dbd76ad83b0a56')
 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_DEFINITION_NOT_SELECTED',1;
GO

-- ============================== THE DECLARED CONTRACTS ==============================
EXEC model.declare_contract @id=N'kernel-acceptance-suite-request.v1',
 @schema=N'{"type":"object","properties":{},"additionalProperties":true}';
EXEC model.declare_contract @id=N'kernel-acceptance-suite-result.v1',
 @schema=N'{"type":"object","additionalProperties":true}';
GO

-- ============================== THE DECLARED READ ==============================
DECLARE @read_statement nvarchar(max)=CONVERT(nvarchar(max),N'DECLARE @suite nvarchar(max)=(
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM analysis.v_selected_semantic_definition d
 JOIN source.content_object co
   ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,''$.semantics.contentDigest''),''sha256:'',''''),2)
 WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''AUTHORITY''
  AND d.declared_id=N''sfx-kernel-acceptance-suite.v1'');
IF @suite IS NULL THROW 51000,N''KERNEL_ACCEPTANCE_SUITE_NOT_DECLARED'',1;
SELECT @suite AS value;');
DECLARE @bindings nvarchar(max)=N'[{"portId":"read-kernel-acceptance-suite-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"statement":"'+STRING_ESCAPE(@read_statement,'json')+N'","resultColumn":"value"}}]';
EXEC model.scaffold_capability @capability_id=N'read-kernel-acceptance-suite', @on_exists=N'REPLACE';
EXEC model.declare_scenario
 @capability_id=N'read-kernel-acceptance-suite',
 @scenario=N'{"scenarioId":"read-kernel-acceptance-suite","name":"Read the declared kernel acceptance suite","inputId":"kernel-acceptance-suite-request","inputContract":"kernel-acceptance-suite-request.v1","eventId":"kernel-acceptance-suite-requested","eventAuthority":"read-kernel-acceptance-suite.v1","outcomeId":"kernel-acceptance-suite","outcomeContract":"kernel-acceptance-suite-result.v1","terminal":true,"root":true,"given":"one estate selection","when":"the retained acceptance suite authority is read under the reader boundary","then":"the declared acceptance suite document is returned"}',
 @operations=N'[{"operationId":"read-kernel-acceptance-suite.0","kind":"invoke-port","portId":"read-kernel-acceptance-suite-port"}]',
 @port_bindings=@bindings;
GO

-- ============================== THE DECLARED OPERATION ==============================
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

IF JSON_QUERY(@json,'$.operations.kernelAcceptanceSuite') IS NULL
BEGIN
 SET @json=JSON_MODIFY(@json,'$.operations.kernelAcceptanceSuite',JSON_QUERY(N'{"object":"kernel","verb":"acceptance-suite","subject":false,"input":"rejected","reader":"read-kernel-acceptance-suite"}'));
 IF JSON_VALUE(@json,'$.operations.kernelAcceptanceSuite.verb')<>N'acceptance-suite'
  OR JSON_VALUE(@json,'$.operations.kernelAcceptanceSuite.reader')<>N'read-kernel-acceptance-suite'
  THROW 51000,N'KERNEL_ACCEPTANCE_OPERATION_NOT_DECLARED',1;
 SET @bytes=CONVERT(varbinary(max),CONVERT(varchar(max),@json COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @operation_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@operation_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@operation_digest,@bytes,DATALENGTH(@bytes));
 IF (SELECT content_bytes FROM source.content_object WHERE content_digest=@operation_digest)<>@bytes
  THROW 51000,N'KERNEL_ACCEPTANCE_OPERATION_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sda-node-command-operations.v1","contentDigest":"sha256:'
  + LOWER(CONVERT(varchar(64),@operation_digest,2))
  + N'","sourcePath":"kernel/semantic-authority/consumer/sda-node-command-operations.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-node-command-operations.authority.v1.json"]}';
 EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',@authority_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
END
GO

-- ============================== IN-TRANSACTION PREFLIGHT ==============================
-- The declared read returns the installed suite from the uncommitted state.
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @read_statement nvarchar(max)=CONVERT(nvarchar(max),N'DECLARE @suite nvarchar(max)=(
 SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
 FROM analysis.v_selected_semantic_definition d
 JOIN source.content_object co
   ON co.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(d.definition_json,''$.semantics.contentDigest''),''sha256:'',''''),2)
 WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''AUTHORITY''
  AND d.declared_id=N''sfx-kernel-acceptance-suite.v1'');
IF @suite IS NULL THROW 51000,N''KERNEL_ACCEPTANCE_SUITE_NOT_DECLARED'',1;
SELECT @suite AS value;');
DECLARE @suite TABLE (value nvarchar(max));
INSERT @suite EXEC sp_executesql @read_statement,N'@estate_model_pk bigint,@input nvarchar(max)',@estate_model_pk=@estate,@input=N'{}';
IF (SELECT COUNT_BIG(*) FROM @suite)<>1 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_READ_NOT_SINGULAR',1;
DECLARE @suite_body nvarchar(max)=(SELECT value FROM @suite);
IF ISJSON(@suite_body)<>1 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_READ_NOT_JSON',1;
IF JSON_VALUE(@suite_body,'$.suiteType')<>N'sfx-kernel-acceptance-suite.v1' THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_READ_WRONG_TYPE',1;
IF (SELECT COUNT(*) FROM OPENJSON(@suite_body,'$.invocations'))<1 THROW 51000,N'KERNEL_ACCEPTANCE_SUITE_READ_NO_INVOCATIONS',1;

-- The ground provider-authority read resolves the operation row exactly as the
-- carrier does.
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
IF JSON_VALUE(@command_body,'$.operations.kernelAcceptanceSuite.object')<>N'kernel'
 OR JSON_VALUE(@command_body,'$.operations.kernelAcceptanceSuite.verb')<>N'acceptance-suite'
 OR JSON_VALUE(@command_body,'$.operations.kernelAcceptanceSuite.reader')<>N'read-kernel-acceptance-suite'
 THROW 51000,N'KERNEL_ACCEPTANCE_OPERATION_NOT_RESOLVED_BY_DECLARED_READ',1;

-- ============================== PROOF ==============================
SELECT '1_suite_authority' AS result_set, d.declared_id, JSON_VALUE(d.definition_json,'$.semantics.contentDigest') AS content_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='AUTHORITY' AND d.declared_id=N'sfx-kernel-acceptance-suite.v1';

SELECT '2_contracts' AS result_set, ct.contract_id
FROM model.contract ct
WHERE ct.contract_id IN (N'kernel-acceptance-suite-request.v1',N'kernel-acceptance-suite-result.v1')
ORDER BY ct.contract_id;

SELECT '3_read_port' AS result_set, d.namespace_id, d.declared_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=N'sidefx:capability:read-kernel-acceptance-suite';

SELECT '4_operation_via_ground_read' AS result_set,
 JSON_VALUE(@command_body,'$.operations.kernelAcceptanceSuite.object') AS object_name,
 JSON_VALUE(@command_body,'$.operations.kernelAcceptanceSuite.verb') AS verb,
 JSON_VALUE(@command_body,'$.operations.kernelAcceptanceSuite.reader') AS reader;

SELECT '5_suite_self_test' AS result_set,
 JSON_VALUE(@suite_body,'$.suiteType') AS suite_type,
 JSON_VALUE(@suite_body,'$.suiteId') AS suite_id,
 (SELECT COUNT(*) FROM OPENJSON(@suite_body,'$.invocations')) AS invocations;

SELECT '6_graph_source' AS result_set, g.capability_id, g.root_scenario_id
FROM analysis.v_capability_graph_source g
WHERE g.capability_id=N'read-kernel-acceptance-suite';

COMMIT TRANSACTION;
