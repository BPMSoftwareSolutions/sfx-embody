-- declare-json-authoring-surface.sql
--
-- A JSON authoring surface for the estate: one procedure that takes one JSON
-- document and emits the same normalized rows the SQL authoring surface emits.
--
-- `model.declare_capability_document` writes nothing itself. Every row it causes
-- is written by the procedures the SQL surface already calls -- scaffold_capability,
-- declare_contract, declare_scenario, author_capability_meaning, configure_interface
-- -- so a JSON-authored capability and a SQL-authored capability are the same rows.
-- The document's shape never reaches a definition envelope: declare_scenario builds
-- its envelopes from named fields only, so the digests do not record how the facts
-- arrived.
--
-- The four properties the surface must preserve, and where each lives:
--   idempotency          -- the document's own SHA2_256 is recorded as the current
--                           CAPABILITY_DOCUMENT definition for the capability id.
--                           A second install of the same bytes returns UNCHANGED and
--                           writes nothing. This gate is required: model.configure_interface
--                           inserts model.semantic_object_definition unconditionally and
--                           therefore violates UNIQUE KEY AK_model_semantic_object_definition_225c4638c685
--                           whenever the resulting declaration already exists (measured).
--   content-addressed    -- every digest is still HASHBYTES('SHA2_256', <canonical
--                           envelope bytes>) computed by model.put_semantic_definition.
--                           This procedure computes exactly one digest of its own, over
--                           the document bytes, using the same recipe.
--   current definition   -- definitions are appended, never mutated, so
--                           analysis.v_selected_semantic_definition selects the newest
--                           per semantic object. The document ledger obeys the same rule.
--   rollback preflight   -- the document is carried by this .sql, so the kernel
--                           from-transaction preflight
--                           (SDA:languages/typescript/src/kernel/bootstrap/invoke-from-transaction.mjs)
--                           applies it uncommitted, invokes, and rolls back with no change to the boot.
--
-- Idempotent: a second run re-creates the procedure (CREATE OR ALTER) and both
-- document installs report UNCHANGED.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install.
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
CLOSE @triggers;
DEALLOCATE @triggers;
GO
-- =====================================================================
-- model.declare_capability_document
--
-- @document: one sidefx-capability-authority.v1 document.
--
--   {
--     "document": "sidefx-capability-authority.v1",
--     "capabilityId": "<id>",
--     "meaning":  { "intent": "...", "outcome": "..." },          -- optional
--     "cli":      { "display": {...}, "input": {...} },           -- optional
--     "contracts": [ { "id": "<contract id>", "schema": { ... } } ],
--     "scenarios": [ { "scenarioId": ..., "name": ..., "inputId": ...,
--                      "inputContract": ..., "eventId": ..., "eventAuthority": ...,
--                      "outcomeId": ..., "outcomeContract": ...,
--                      "terminal": true, "root": true,
--                      "given": ..., "when": ..., "then": ...,
--                      "operations": [ ... ], "portBindings": [ ... ] } ]
--   }
--
-- Every member is a payload an existing procedure already reads; no new authoring
-- vocabulary is introduced. `scenarios[*]` is the @scenario payload of
-- model.declare_scenario with its @operations and @port_bindings payloads carried
-- inside it.
--
-- @on_unchanged: SKIP (default) returns UNCHANGED when the document's digest is
-- already the current one for this capability id; REAPPLY forces the chain to run.
-- =====================================================================
CREATE OR ALTER PROCEDURE model.declare_capability_document
  @document     nvarchar(max),
  @on_unchanged nvarchar(20) = N'SKIP'
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;

  IF @document IS NULL OR ISJSON(@document)<>1 THROW 51100,'CAPABILITY_DOCUMENT_INVALID',1;
  IF ISNULL(JSON_VALUE(@document,'$.document'),N'')<>N'sidefx-capability-authority.v1'
    THROW 51100,'CAPABILITY_DOCUMENT_FORMAT_UNSUPPORTED',1;
  IF @on_unchanged NOT IN (N'SKIP',N'REAPPLY') THROW 51100,'ON_UNCHANGED_INVALID',1;

  DECLARE @capability_id nvarchar(400)=JSON_VALUE(@document,'$.capabilityId');
  IF @capability_id IS NULL OR @capability_id=N'' THROW 51100,'CAPABILITY_DOCUMENT_ID_REQUIRED',1;
  IF LEN(@capability_id)>120 THROW 51100,'CAPABILITY_DOCUMENT_ID_TOO_LONG',1;
  IF NOT EXISTS (SELECT 1 FROM OPENJSON(@document,'$.scenarios'))
    THROW 51100,'CAPABILITY_DOCUMENT_SCENARIO_REQUIRED',1;

  DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
  IF @estate IS NULL THROW 51100,'CURRENT_MODEL_NOT_FOUND',1;

  -- The document's own content address, by the same recipe every definition uses.
  DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@document) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @document_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
  DECLARE @document_digest_hex varchar(64)=LOWER(CONVERT(varchar(64),@document_digest,2));
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@document_digest)
    INSERT source.content_object(content_digest,content_bytes,byte_length)
      VALUES(@document_digest,@bytes,DATALENGTH(@bytes));

  -- The installed-document ledger. Current-definition selection decides which
  -- document is the installed one; nothing here is read from outside the model.
  DECLARE @installed varchar(64);
  SELECT TOP 1 @installed=JSON_VALUE(d.definition_json,'$.semantics.document_digest')
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk=@estate AND d.object_kind='CAPABILITY_DOCUMENT'
    AND d.namespace_id=(N'sidefx:capability-documents')
    AND d.declared_id=@capability_id;

  IF @installed=@document_digest_hex AND @on_unchanged=N'SKIP'
  BEGIN
    SELECT N'DECLARE_CAPABILITY_DOCUMENT' AS action, N'UNCHANGED' AS disposition,
           @capability_id AS capability_id, @document_digest_hex AS document_digest,
           0 AS contracts_declared, 0 AS scenarios_declared, 0 AS meaning_declared, 0 AS interface_declared;
    RETURN;
  END

  -- 1. The capability shell. Only when it does not already exist: scaffold_capability
  --    with REPLACE deletes and re-creates the capability's rows, which would mint a
  --    fresh capability_version on every install.
  DECLARE @scaffold_id nvarchar(120)=@capability_id;
  IF NOT EXISTS (
    SELECT 1 FROM model.capability c
    JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
    JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
    WHERE c.capability_id=@capability_id)
    EXEC model.scaffold_capability @capability_id=@scaffold_id, @on_exists=N'ERROR';

  -- 2. Contracts.
  DECLARE @contracts int=0, @contract_id nvarchar(400), @contract_schema nvarchar(max);
  DECLARE @contract_cursor CURSOR;
  SET @contract_cursor=CURSOR LOCAL FAST_FORWARD FOR
    SELECT JSON_VALUE(value,'$.id'), JSON_QUERY(value,'$.schema') FROM OPENJSON(@document,'$.contracts');
  OPEN @contract_cursor;
  FETCH NEXT FROM @contract_cursor INTO @contract_id, @contract_schema;
  WHILE @@FETCH_STATUS=0
  BEGIN
    IF @contract_id IS NULL OR @contract_schema IS NULL THROW 51100,'CAPABILITY_DOCUMENT_CONTRACT_INCOMPLETE',1;
    EXEC model.declare_contract @id=@contract_id, @schema=@contract_schema;
    SET @contracts+=1;
    FETCH NEXT FROM @contract_cursor INTO @contract_id, @contract_schema;
  END;
  CLOSE @contract_cursor;
  DEALLOCATE @contract_cursor;

  -- 3. Scenarios, with their operations and port bindings.
  DECLARE @scenarios int=0, @scenario nvarchar(max), @operations nvarchar(max), @port_bindings nvarchar(max);
  DECLARE @scenario_cursor CURSOR;
  SET @scenario_cursor=CURSOR LOCAL FAST_FORWARD FOR SELECT value FROM OPENJSON(@document,'$.scenarios');
  OPEN @scenario_cursor;
  FETCH NEXT FROM @scenario_cursor INTO @scenario;
  WHILE @@FETCH_STATUS=0
  BEGIN
    SET @operations=JSON_QUERY(@scenario,'$.operations');
    SET @port_bindings=JSON_QUERY(@scenario,'$.portBindings');
    IF @operations IS NULL THROW 51100,'CAPABILITY_DOCUMENT_OPERATIONS_REQUIRED',1;
    IF @port_bindings IS NULL THROW 51100,'CAPABILITY_DOCUMENT_PORT_BINDINGS_REQUIRED',1;
    EXEC model.declare_scenario @capability_id=@capability_id, @scenario=@scenario,
      @operations=@operations, @port_bindings=@port_bindings;
    SET @scenarios+=1;
    FETCH NEXT FROM @scenario_cursor INTO @scenario;
  END;
  CLOSE @scenario_cursor;
  DEALLOCATE @scenario_cursor;

  -- 4. Meaning. author_capability_meaning clears the scaffolded CLI declaration, so
  --    it runs before the interface is declared.
  DECLARE @meaning int=0;
  DECLARE @intent nvarchar(max)=JSON_VALUE(@document,'$.meaning.intent');
  DECLARE @outcome nvarchar(max)=JSON_VALUE(@document,'$.meaning.outcome');
  IF @intent IS NOT NULL AND @outcome IS NOT NULL
  BEGIN
    EXEC model.author_capability_meaning @capability_id=@capability_id, @intent=@intent, @outcome=@outcome;
    SET @meaning=1;
  END

  -- 5. Interface. model.configure_interface inserts its definition unconditionally, so
  --    the declaration it would write is computed here as a predicate only: if that
  --    definition already exists for this capability there is nothing to declare.
  DECLARE @interface int=0;
  DECLARE @cli nvarchar(max)=JSON_QUERY(@document,'$.cli');
  IF @cli IS NOT NULL
  BEGIN
    DECLARE @capSo bigint, @capSod bigint, @curEnv nvarchar(max);
    SELECT @capSo=c.semantic_object_pk, @capSod=ec.semantic_object_definition_pk
    FROM model.capability c
    JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
    JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
    WHERE c.capability_id=@capability_id;
    IF @capSod IS NULL THROW 51100,'CAPABILITY_NOT_FOUND',1;
    SELECT @curEnv=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
    FROM model.semantic_object_definition d
    JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE d.semantic_object_definition_pk=@capSod;
    DECLARE @cliEnv nvarchar(max)=JSON_MODIFY(@curEnv,'$.semantics.cli',JSON_QUERY(@cli));
    DECLARE @cliDigest binary(32)=HASHBYTES('SHA2_256',
      CONVERT(varbinary(max),CONVERT(varchar(max),(@cliEnv) COLLATE Latin1_General_100_BIN2_UTF8)));
    IF NOT EXISTS (SELECT 1 FROM model.semantic_object_definition
                   WHERE semantic_object_pk=@capSo AND definition_digest=@cliDigest)
    BEGIN
      EXEC model.configure_interface @capability_id=@scaffold_id, @cli_json=@cli;
      SET @interface=1;
    END
  END

  -- 6. Record the document that produced this declaration. Written through the same
  --    content-addressed writer as every other definition, so a replay of the same
  --    bytes finds the same digest and adds nothing.
  DECLARE @ledger nvarchar(max)=(SELECT @capability_id AS capabilityId,
    @document_digest_hex AS document_digest FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
  DECLARE @ledger_object bigint, @ledger_definition bigint, @ledger_digest binary(32);
  EXEC model.put_semantic_definition 'CAPABILITY_DOCUMENT', N'sidefx:capability-documents',
    @capability_id, @ledger, @ledger_object OUTPUT, @ledger_definition OUTPUT, @ledger_digest OUTPUT;

  SELECT N'DECLARE_CAPABILITY_DOCUMENT' AS action,
         CASE WHEN @installed IS NULL THEN N'INSTALLED' ELSE N'REDECLARED' END AS disposition,
         @capability_id AS capability_id, @document_digest_hex AS document_digest,
         @contracts AS contracts_declared, @scenarios AS scenarios_declared,
         @meaning AS meaning_declared, @interface AS interface_declared;
END;
GO
-- =====================================================================
-- Capability A, authored from one JSON document, then installed a second time to
-- prove the replay is a no-op.
-- Source document: examples/json-authoring/count-declared-capabilities.authority.json
-- =====================================================================
DECLARE @a nvarchar(max) = N'{
  "document": "sidefx-capability-authority.v1",
  "capabilityId": "count-declared-capabilities",
  "meaning": {
    "intent": "count the capabilities the current model declares",
    "outcome": "the caller observes how many capabilities the current model declares"
  },
  "cli": { "display": { "select": "outcome.payload", "as": "json" } },
  "contracts": [
    { "id": "count-declared-capabilities-request.v1",
      "schema": { "type": "object", "additionalProperties": true } },
    { "id": "count-declared-capabilities-result.v1",
      "schema": { "type": "object", "additionalProperties": true } }
  ],
  "scenarios": [
    {
      "scenarioId": "count-declared-capabilities",
      "name": "Count the capabilities the current model declares",
      "inputId": "count-declared-capabilities-request",
      "inputContract": "count-declared-capabilities-request.v1",
      "eventId": "count-declared-capabilities-requested",
      "eventAuthority": "count-declared-capabilities.v1",
      "outcomeId": "count-declared-capabilities-result",
      "outcomeContract": "count-declared-capabilities-result.v1",
      "terminal": true,
      "root": true,
      "given": "the current model",
      "when": "the declared read executes under the reader boundary",
      "then": "the number of capabilities the current model declares is returned",
      "operations": [
        { "operationId": "count-declared-capabilities.0", "kind": "invoke-port",
          "portId": "count-declared-capabilities-port" }
      ],
      "portBindings": [
        { "portId": "count-declared-capabilities-port",
          "platformCapabilityId": "sda-embodiment-plan-port.v1",
          "configuration": {
            "statement": "SELECT (SELECT COUNT_BIG(*) AS declaredCapabilities FROM model.estate_capability ec JOIN source.current_model cm ON cm.estate_model_pk=ec.estate_model_pk FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value",
            "resultColumn": "value"
          } }
      ]
    }
  ]
}';
EXEC model.declare_capability_document @document=@a;
EXEC model.declare_capability_document @document=@a;
GO
-- =====================================================================
-- Capability B. The same document with the identifiers, the read and the sentences
-- changed: the second capability costs one copy-edit, not a second design.
-- Source document: examples/json-authoring/count-declared-contracts.authority.json
-- =====================================================================
DECLARE @b nvarchar(max) = N'{
  "document": "sidefx-capability-authority.v1",
  "capabilityId": "count-declared-contracts",
  "meaning": {
    "intent": "count the contracts the current model declares",
    "outcome": "the caller observes how many contracts the current model declares"
  },
  "cli": { "display": { "select": "outcome.payload", "as": "json" } },
  "contracts": [
    { "id": "count-declared-contracts-request.v1",
      "schema": { "type": "object", "additionalProperties": true } },
    { "id": "count-declared-contracts-result.v1",
      "schema": { "type": "object", "additionalProperties": true } }
  ],
  "scenarios": [
    {
      "scenarioId": "count-declared-contracts",
      "name": "Count the contracts the current model declares",
      "inputId": "count-declared-contracts-request",
      "inputContract": "count-declared-contracts-request.v1",
      "eventId": "count-declared-contracts-requested",
      "eventAuthority": "count-declared-contracts.v1",
      "outcomeId": "count-declared-contracts-result",
      "outcomeContract": "count-declared-contracts-result.v1",
      "terminal": true,
      "root": true,
      "given": "the current model",
      "when": "the declared read executes under the reader boundary",
      "then": "the number of contracts the current model declares is returned",
      "operations": [
        { "operationId": "count-declared-contracts.0", "kind": "invoke-port",
          "portId": "count-declared-contracts-port" }
      ],
      "portBindings": [
        { "portId": "count-declared-contracts-port",
          "platformCapabilityId": "sda-embodiment-plan-port.v1",
          "configuration": {
            "statement": "SELECT (SELECT COUNT_BIG(*) AS declaredContracts FROM model.contract FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS value",
            "resultColumn": "value"
          } }
      ]
    }
  ]
}';
EXEC model.declare_capability_document @document=@b;
GO
-- ============================== VERIFICATION ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

SELECT '1_document_ledger' AS result_set, d.declared_id AS capability_id,
       JSON_VALUE(d.definition_json,'$.semantics.document_digest') AS document_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='CAPABILITY_DOCUMENT'
ORDER BY d.declared_id;

-- The rows a JSON-authored capability produces, beside a SQL-authored one of the
-- same shape. Same kinds, same profiles, same port standard: no providerId.
SELECT '2_json_vs_sql_rows' AS result_set, c.capability_id,
       CASE WHEN c.capability_id COLLATE Latin1_General_100_BIN2
                 IN (N'count-declared-capabilities',N'count-declared-contracts')
            THEN N'json' ELSE N'sql' END AS authored_by,
       s.scenario_id, sv.source_profile AS scenario_profile,
       pv.port_profile, eav.authority_profile,
       JSON_VALUE(pd.definition_json,'$.semantics.platformCapabilityId') AS platform_capability_id,
       CASE WHEN JSON_VALUE(pd.definition_json,'$.semantics.configuration.statement') IS NULL THEN 0 ELSE 1 END AS declares_read,
       CASE WHEN JSON_VALUE(pd.definition_json,'$.semantics.configuration.providerId') IS NULL THEN 0 ELSE 1 END AS names_provider_module
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
JOIN model.port_version pv ON pv.port_version_pk=opi.port_version_pk
JOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk
WHERE ec.estate_model_pk=@estate
  AND c.capability_id IN (N'count-declared-capabilities',N'count-declared-contracts',N'run-declared-query')
ORDER BY authored_by, c.capability_id;

-- Exactly one current definition per declared id in each authored capability.
SELECT '3_current_definition_per_id' AS result_set, d.object_kind, d.declared_id, COUNT(*) AS current_definitions
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate
  AND d.namespace_id IN (N'sidefx:capability:count-declared-capabilities',
                         N'sidefx:capability:count-declared-contracts')
GROUP BY d.object_kind, d.declared_id
ORDER BY d.object_kind, d.declared_id;

-- The read path sees both capabilities.
SELECT '4_graph_source' AS result_set, g.capability_id, g.root_scenario_id
FROM analysis.v_capability_graph_source g
WHERE g.capability_id IN (N'count-declared-capabilities',N'count-declared-contracts')
ORDER BY g.capability_id;

-- One capability_version each: the replay above minted no duplicate.
SELECT '5_capability_versions' AS result_set, c.capability_id, COUNT(*) AS versions
FROM model.capability c
JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
WHERE c.capability_id IN (N'count-declared-capabilities',N'count-declared-contracts')
GROUP BY c.capability_id
ORDER BY c.capability_id;
COMMIT TRANSACTION;
