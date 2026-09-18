-- switch-credential-authorities-to-vault.sql
--
-- W4 of docs/vault-manager-agent-strategy.md: switch every installed credential
-- authority for the three live reference names from `source: "environment"` to
-- the vault source, adding the declared store locator. Nothing else moves:
-- reference names, requesting capability ids, endpoint authority digests,
-- effect scopes, binding lifetimes and injection rules stay byte-identical.
--
--   RAPID_API_KEY       boot-external reference binding, equity primary digest
--                       sha256:09ecb038... and equity fallback digest
--                       sha256:17bd0ab8...
--   LOC_GEMINI_API_KEY  boot-external reference binding
--   LOC_OPENAI_API_KEY  boot-external reference binding and the speech provider
--
-- Every authority entry that names one of the three references is switched, so
-- no environment fallback remains for any of them. The locator is the same
-- declared store locator the vault capabilities carry
-- (`%LOCALAPPDATA%\sfx\vault`); the boot resolves it against the host
-- environment before the kernel sees it.
--
-- Dependency: grep-W2b (the vault mechanic binding and the Windows realization)
-- must be installed, and the vault must already hold the three references
-- (the transition unit stores them before switching). With the vault empty the
-- SDA credential port returns CREDENTIAL_NOT_AVAILABLE; it never falls back to
-- the environment.
--
-- Idempotent: a second run finds no `source: environment` entry for the three
-- names and writes no new definition or port version.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes
-- (per capability, with the three names absent from the invocation process):
--   node ../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/run-migration.mjs sql/migrations/switch-credential-authorities-to-vault.sql
-- To install, replace the final rollback statement with a commit statement and
-- run the same command (scripts/transition-credential-authorities-to-vault.mjs
-- performs both steps).
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
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @store_locator nvarchar(400) = N'%LOCALAPPDATA%\sfx\vault';

DECLARE @ports TABLE (
  namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  PRIMARY KEY (namespace_id, declared_id),
  semantics nvarchar(max),
  prevver bigint,
  port_pk bigint,
  changed bit DEFAULT 0
);
INSERT @ports (namespace_id, declared_id, semantics, prevver, port_pk)
SELECT d.namespace_id, d.declared_id, JSON_QUERY(d.definition_json, '$.semantics'),
  (SELECT pv.port_version_pk FROM model.port_version pv
    WHERE pv.semantic_object_definition_pk = d.semantic_object_definition_pk),
  (SELECT pv.port_pk FROM model.port_version pv
    WHERE pv.semantic_object_definition_pk = d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND JSON_QUERY(d.definition_json, '$.semantics.configuration.credentialAuthorities') IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM @ports) THROW 51000, 'CREDENTIAL_AUTHORITY_PORTS_NOT_FOUND', 1;
IF EXISTS (SELECT 1 FROM @ports WHERE prevver IS NULL OR port_pk IS NULL) THROW 51000, 'CREDENTIAL_AUTHORITY_PORT_VERSION_MISSING', 1;

DECLARE @switched TABLE (
  namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  reference_name nvarchar(400) COLLATE Latin1_General_100_BIN2,
  authority_index int,
  source_before nvarchar(400)
);
DECLARE @namespace nvarchar(400), @declared nvarchar(400), @semantics nvarchar(max),
  @prevver bigint, @object bigint, @portpk bigint, @changed bit,
  @authorities nvarchar(max), @index int, @reference nvarchar(400), @source nvarchar(400), @locator nvarchar(400),
  @definition bigint, @digest binary(32), @version bigint;
DECLARE port_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT namespace_id, declared_id, semantics, prevver, port_pk
  FROM @ports ORDER BY namespace_id, declared_id;
OPEN port_cursor;
FETCH NEXT FROM port_cursor INTO @namespace, @declared, @semantics, @prevver, @portpk;
WHILE @@FETCH_STATUS = 0 BEGIN
  SET @authorities = JSON_QUERY(@semantics, '$.configuration.credentialAuthorities');
  SET @changed = 0;
  DECLARE authority_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT CONVERT(int, b.[key]) AS authority_index,
           JSON_VALUE(b.value, '$.referenceName') AS reference_name,
           JSON_VALUE(b.value, '$.source') AS source,
           JSON_VALUE(b.value, '$.storeLocator') AS store_locator
    FROM OPENJSON(@authorities) b
    WHERE JSON_VALUE(b.value, '$.referenceName') IN (N'RAPID_API_KEY', N'LOC_GEMINI_API_KEY', N'LOC_OPENAI_API_KEY')
    ORDER BY CONVERT(int, b.[key]);
  OPEN authority_cursor;
  FETCH NEXT FROM authority_cursor INTO @index, @reference, @source, @locator;
  WHILE @@FETCH_STATUS = 0 BEGIN
    IF @source <> N'vault' OR @locator IS NULL OR @locator <> @store_locator BEGIN
      SET @authorities = JSON_MODIFY(@authorities, N'$[' + CONVERT(nvarchar(10), @index) + N'].source', N'vault');
      SET @authorities = JSON_MODIFY(@authorities, N'$[' + CONVERT(nvarchar(10), @index) + N'].storeLocator', @store_locator);
      SET @changed = 1;
      INSERT @switched VALUES (@namespace, @declared, @reference, @index, @source);
    END
    FETCH NEXT FROM authority_cursor INTO @index, @reference, @source, @locator;
  END
  CLOSE authority_cursor;
  DEALLOCATE authority_cursor;
  IF @changed = 1 BEGIN
    SET @semantics = JSON_MODIFY(@semantics, '$.configuration.credentialAuthorities', JSON_QUERY(@authorities));
    EXEC model.put_semantic_definition 'PORT', @namespace, @declared, @semantics,
      @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
    SET @portpk = (SELECT port_pk FROM model.port WHERE semantic_object_pk = @object);
    IF @portpk IS NULL THROW 51000, 'CREDENTIAL_AUTHORITY_PORT_ROW_MISSING', 1;
    SET @version = (SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk = @definition);
    IF @version IS NULL BEGIN
      INSERT model.port_version(port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest,
        port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
      VALUES(@portpk, @object, @definition, @digest, 'consumer-interface-authority.v1', 'PORT', @definition, N'');
      SET @version = SCOPE_IDENTITY();
    END
    UPDATE model.operation_port_invocation SET port_version_pk = @version WHERE port_version_pk = @prevver;
    UPDATE @ports SET changed = 1 WHERE namespace_id = @namespace COLLATE Latin1_General_100_BIN2
      AND declared_id = @declared COLLATE Latin1_General_100_BIN2;
  END
  FETCH NEXT FROM port_cursor INTO @namespace, @declared, @semantics, @prevver, @portpk;
END
CLOSE port_cursor;
DEALLOCATE port_cursor;

-- ============================== VERIFICATION ==============================
-- 1. The authorities the run found and switched, with their source before.
SELECT '1_switched_authorities' AS result_set, s.namespace_id, s.declared_id, s.reference_name,
  s.authority_index, s.source_before
FROM @switched s ORDER BY s.namespace_id, s.declared_id, s.authority_index;

-- 2. The installed state after the run: every authority for the three names is
--    vault-sourced with the declared locator.
SELECT '2_authorities_after' AS result_set, d.namespace_id, d.declared_id,
  JSON_VALUE(b.value, '$.referenceName') AS reference_name,
  JSON_VALUE(b.value, '$.source') AS source,
  JSON_VALUE(b.value, '$.storeLocator') AS store_locator,
  JSON_VALUE(b.value, '$.injectionRule.headerName') AS header_name
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json, '$.semantics.configuration.credentialAuthorities')) b
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND JSON_VALUE(b.value, '$.referenceName') IN (N'RAPID_API_KEY', N'LOC_GEMINI_API_KEY', N'LOC_OPENAI_API_KEY')
ORDER BY d.namespace_id, d.declared_id, reference_name;

-- 3. No environment fallback remains for any of the three names.
SELECT '3_remaining_environment' AS result_set, COUNT(*) AS environment_authorities
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json, '$.semantics.configuration.credentialAuthorities')) b
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND JSON_VALUE(b.value, '$.referenceName') IN (N'RAPID_API_KEY', N'LOC_GEMINI_API_KEY', N'LOC_OPENAI_API_KEY')
  AND JSON_VALUE(b.value, '$.source') <> N'vault';

-- 4. Which ports changed and their new definition versions.
SELECT '4_ports_changed' AS result_set, p.namespace_id, p.declared_id, p.changed
FROM @ports p ORDER BY p.namespace_id, p.declared_id;
COMMIT TRANSACTION;
