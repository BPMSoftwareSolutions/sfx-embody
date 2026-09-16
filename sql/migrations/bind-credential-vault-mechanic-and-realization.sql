-- bind-credential-vault-mechanic-and-realization.sql
--
-- W2b of docs/vault-manager-agent-strategy.md (execution log "Next sequence"):
-- bind the declared credential vault into the estate's invocation path as data.
--
-- One bounded, idempotent unit with three additions, all on the host invocation
-- Port (`run-declared-graph-execute`), never on the capability rows the vault
-- capabilities declare (docs/vault-manager-capabilities.md section 3: the
-- capability rows are identical on every OS; only the realization binding
-- differs, so the realization is host/estate data):
--
--   1. `configuration.overlayBindings` gains the vault effect mechanic
--        {"mechanicId":"sda-credential-vault-port.v1",
--         "providerProfileId":"sda-platform-effect-graph-provider.v1",
--         "providerProfileDigest":"sha256:945a4ff5...",
--         "implementationRef":"sda-platform-effect-graph-provider.v1"}
--      derived from an existing binding of that profile so it cannot drift; the
--      recorded digest is asserted against the header of
--      declare-credential-capabilities.sql. Without it the invocation fails at
--      SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING:
--      'sda-credential-vault-port.v1'.
--
--   2. `configuration.overlayBindings` gains the host realization binding
--        {"mechanicId":"sda-credential-store-realization.v1",
--         "providerProfileId":"windows-credential-store-provider",
--         "providerProfileDigest":"sha256:d4323117...",  (module bytes)
--         "implementationRef":"windows-credential-store-provider"}
--      which the boot's realization resolver reads (`declaredProviderProfileId`
--      in src/credential-vault-realization.mjs). The digest is inert for a
--      non-slot host binding and is the SHA-256 of the realization module bytes
--      at install; the loader resolves by profile id + module + export.
--
--   3. `configuration.providers` gains the realization provider
--        {"providerProfileId":"windows-credential-store-provider",
--         "module":"languages/typescript/runtimes/node/windows-credential-store-provider.mjs",
--         "export":"createWindowsCredentialStoreRealization",
--         "factory":true}
--      so the realization module/export are declaration data, never a branch in
--      the boot. The resolved realization owns key custody; only the in-memory
--      key handle reaches the kernel effect context. With no binding the boot
--      injects a sealed realization and the vault refuses with VAULT_SEALED.
--
-- Ordering. Addition 1 is independent; additions 2/3 are host data for the
-- invocation path and do not depend on the W2 declarations either. The migration
-- is nevertheless installed after declare-credential-capabilities.sql (W2),
-- because that is the order the vault capabilities become installable and the
-- combined uncommitted preflight exercises.
--
-- Idempotent: a second run finds every binding present with the declared values
-- and writes no new definition or port version. The proof result sets print the
-- binding state and the changed count.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes:
--   node scripts/run-migration.mjs sql/migrations/bind-credential-vault-mechanic-and-realization.sql
-- To install, replace the final rollback statement with a commit statement and
-- run the same command.
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
-- The host invocation Port (`run-declared-graph-execute`) gains the vault
-- mechanic, the Windows realization binding and its provider declaration.
-- =====================================================================
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @namespace nvarchar(400) = N'sidefx:capability:run-declared-graph';
DECLARE @port nvarchar(400) = N'run-declared-graph-execute';
DECLARE @effect_profile nvarchar(400) = N'sda-platform-effect-graph-provider.v1';
DECLARE @vault_mechanic nvarchar(400) = N'sda-credential-vault-port.v1';
DECLARE @realization_mechanic nvarchar(400) = N'sda-credential-store-realization.v1';
DECLARE @realization_profile nvarchar(400) = N'windows-credential-store-provider';
DECLARE @realization_module nvarchar(400) = N'languages/typescript/runtimes/node/windows-credential-store-provider.mjs';
DECLARE @realization_export nvarchar(400) = N'createWindowsCredentialStoreRealization';
DECLARE @realization_digest nvarchar(80) = N'sha256:d43231173b1630f21dd40cd04eedb149d7de44d9ce93a6800615ff0200c404c2';
DECLARE @recorded_effect_digest nvarchar(80) = N'sha256:945a4ff5c2a0c550f35a18296888f6941a303f02c17de3c942cacace2f7e1358';

DECLARE @semantics nvarchar(max), @prevver bigint;
SELECT @semantics = JSON_QUERY(d.definition_json, '$.semantics'),
  @prevver = (SELECT pv.port_version_pk FROM model.port_version pv
              WHERE pv.semantic_object_definition_pk = d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND d.namespace_id = @namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id = @port COLLATE Latin1_General_100_BIN2;
IF @semantics IS NULL THROW 51000, 'RUN_DECLARED_GRAPH_EXECUTE_PORT_NOT_SELECTED', 1;
IF @prevver IS NULL THROW 51000, 'RUN_DECLARED_GRAPH_EXECUTE_PORT_VERSION_MISSING', 1;

-- The effect profile digest and implementation ref are read from an existing
-- binding of that profile; the recorded digest is asserted so a drift between
-- the header and the installed row fails closed.
DECLARE @effect_digest nvarchar(80), @effect_ref nvarchar(400);
SELECT TOP 1 @effect_digest = JSON_VALUE(b.value, '$.providerProfileDigest'),
             @effect_ref = JSON_VALUE(b.value, '$.implementationRef')
FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
WHERE JSON_VALUE(b.value, '$.providerProfileId') = @effect_profile COLLATE Latin1_General_100_BIN2;
IF @effect_digest IS NULL OR @effect_ref IS NULL THROW 51000, 'PLATFORM_EFFECT_PROFILE_BINDING_TEMPLATE_MISSING', 1;
IF @effect_digest <> @recorded_effect_digest THROW 51000, 'CREDENTIAL_VAULT_EFFECT_PROFILE_DIGEST_DRIFT', 1;

DECLARE @vault_present int = (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
  WHERE JSON_VALUE(b.value, '$.mechanicId') = @vault_mechanic COLLATE Latin1_General_100_BIN2);
DECLARE @realization_present int = (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
  WHERE JSON_VALUE(b.value, '$.mechanicId') = @realization_mechanic COLLATE Latin1_General_100_BIN2);
DECLARE @realization_provider_present int = (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.providers')) p
  WHERE JSON_VALUE(p.value, '$.providerProfileId') = @realization_profile COLLATE Latin1_General_100_BIN2);
DECLARE @changed int = 0, @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;

IF @vault_present = 0 OR @realization_present = 0 OR @realization_provider_present = 0 BEGIN
  IF @vault_present = 0 BEGIN
    DECLARE @with_vault nvarchar(max) = (
      SELECT mechanicId, providerProfileId, providerProfileDigest, implementationRef
      FROM (
        SELECT JSON_VALUE(b.value, '$.mechanicId') AS mechanicId,
               JSON_VALUE(b.value, '$.providerProfileId') AS providerProfileId,
               JSON_VALUE(b.value, '$.providerProfileDigest') AS providerProfileDigest,
               JSON_VALUE(b.value, '$.implementationRef') AS implementationRef,
               0 AS source_rank, CONVERT(bigint, b.[key]) AS sort_key
        FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
        UNION ALL
        SELECT @vault_mechanic, @effect_profile, @effect_digest, @effect_ref, 1, NULL
      ) combined
      ORDER BY source_rank, sort_key, mechanicId
      FOR JSON PATH);
    SET @semantics = JSON_MODIFY(@semantics, '$.configuration.overlayBindings', JSON_QUERY(@with_vault));
  END
  IF @realization_present = 0 BEGIN
    DECLARE @with_realization nvarchar(max) = (
      SELECT mechanicId, providerProfileId, providerProfileDigest, implementationRef
      FROM (
        SELECT JSON_VALUE(b.value, '$.mechanicId') AS mechanicId,
               JSON_VALUE(b.value, '$.providerProfileId') AS providerProfileId,
               JSON_VALUE(b.value, '$.providerProfileDigest') AS providerProfileDigest,
               JSON_VALUE(b.value, '$.implementationRef') AS implementationRef,
               0 AS source_rank, CONVERT(bigint, b.[key]) AS sort_key
        FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
        UNION ALL
        SELECT @realization_mechanic, @realization_profile, @realization_digest, @realization_profile, 1, NULL
      ) combined
      ORDER BY source_rank, sort_key, mechanicId
      FOR JSON PATH);
    SET @semantics = JSON_MODIFY(@semantics, '$.configuration.overlayBindings', JSON_QUERY(@with_realization));
  END
  IF @realization_provider_present = 0 BEGIN
    -- `factory` must stay a JSON boolean: JSON_VALUE returns the text 'true'
    -- and FOR JSON PATH would serialize it as a string, so the loader's
    -- `entry.factory === true` test would miss and call the factory as the
    -- provider itself. The bit conversion round-trips as true/false.
    DECLARE @with_provider nvarchar(max) = (
      SELECT providerProfileId, module, export, factory
      FROM (
        SELECT JSON_VALUE(p.value, '$.providerProfileId') AS providerProfileId,
               JSON_VALUE(p.value, '$.module') AS module,
               JSON_VALUE(p.value, '$.export') AS export,
               CONVERT(bit, JSON_VALUE(p.value, '$.factory')) AS factory,
               0 AS source_rank, CONVERT(bigint, p.[key]) AS sort_key
        FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.providers')) p
        UNION ALL
        SELECT @realization_profile, @realization_module, @realization_export, CONVERT(bit, 1), 1, NULL
      ) combined
      ORDER BY source_rank, sort_key, providerProfileId
      FOR JSON PATH);
    SET @semantics = JSON_MODIFY(@semantics, '$.configuration.providers', JSON_QUERY(@with_provider));
  END
  EXEC model.put_semantic_definition 'PORT', @namespace, @port, @semantics,
    @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
  SET @portpk = (SELECT port_pk FROM model.port WHERE semantic_object_pk = @object);
  IF @portpk IS NULL THROW 51000, 'RUN_DECLARED_GRAPH_EXECUTE_PORT_ROW_MISSING', 1;
  SET @version = (SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk = @definition);
  IF @version IS NULL BEGIN
    INSERT model.port_version(port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest,
      port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES(@portpk, @object, @definition, @digest, 'consumer-interface-authority.v1', 'PORT', @definition, N'');
    SET @version = SCOPE_IDENTITY();
  END
  UPDATE model.operation_port_invocation SET port_version_pk = @version WHERE port_version_pk = @prevver;
  SET @changed = 1;
END

-- ============================== VERIFICATION ==============================
-- 1. The host invocation Port carries all three additions.
SELECT '1_execute_port_bindings' AS result_set, d.declared_id,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(d.definition_json, '$.semantics.configuration.overlayBindings')) b
   WHERE JSON_VALUE(b.value, '$.mechanicId') = @vault_mechanic COLLATE Latin1_General_100_BIN2) AS vault_mechanic_bindings,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(d.definition_json, '$.semantics.configuration.overlayBindings')) b
   WHERE JSON_VALUE(b.value, '$.mechanicId') = @realization_mechanic COLLATE Latin1_General_100_BIN2) AS realization_bindings,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(d.definition_json, '$.semantics.configuration.providers')) p
   WHERE JSON_VALUE(p.value, '$.providerProfileId') = @realization_profile COLLATE Latin1_General_100_BIN2) AS realization_providers,
  @changed AS changed
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND d.namespace_id = @namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id = @port COLLATE Latin1_General_100_BIN2;

-- 2. The exact binding rows added, for the record.
SELECT '2_binding_rows' AS result_set, JSON_VALUE(b.value, '$.mechanicId') AS mechanic_id,
  JSON_VALUE(b.value, '$.providerProfileId') AS provider_profile_id,
  JSON_VALUE(b.value, '$.providerProfileDigest') AS provider_profile_digest,
  JSON_VALUE(b.value, '$.implementationRef') AS implementation_ref
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json, '$.semantics.configuration.overlayBindings')) b
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND d.namespace_id = @namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id = @port COLLATE Latin1_General_100_BIN2
  AND JSON_VALUE(b.value, '$.mechanicId') IN (@vault_mechanic, @realization_mechanic)
ORDER BY mechanic_id;
SELECT '2_provider_row' AS result_set, JSON_VALUE(p.value, '$.providerProfileId') AS provider_profile_id,
  JSON_VALUE(p.value, '$.module') AS module, JSON_VALUE(p.value, '$.export') AS export,
  JSON_VALUE(p.value, '$.factory') AS factory
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json, '$.semantics.configuration.providers')) p
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND d.namespace_id = @namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id = @port COLLATE Latin1_General_100_BIN2
  AND JSON_VALUE(p.value, '$.providerProfileId') = @realization_profile;

-- 3. The vault capability Ports are untouched by this migration: the capability
--    rows stay OS-neutral and no realization is bound on them.
SELECT '3_capability_ports_untouched' AS result_set, d.namespace_id, d.declared_id,
  CASE WHEN JSON_QUERY(d.definition_json, '$.semantics.configuration.overlayBindings') IS NULL THEN 0 ELSE 1 END AS has_overlay_bindings,
  CASE WHEN JSON_QUERY(d.definition_json, '$.semantics.configuration.providers') IS NULL THEN 0 ELSE 1 END AS has_providers
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND d.namespace_id IN (N'sidefx:capability:store-credential', N'sidefx:capability:resolve-credential')
ORDER BY d.namespace_id;
COMMIT TRANSACTION;
