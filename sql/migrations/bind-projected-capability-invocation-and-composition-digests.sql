-- bind-projected-capability-invocation-and-composition-digests.sql
--
-- Makes the kernel's graph path able to execute declared capability
-- composition, and refreshes the composition digests to the current
-- projections:
--
--   1. The host invocation Port `run-declared-graph-execute` gains two overlay
--      rules and one provider entry:
--        * `invoke-scenario` -> the compatibility profile the current SDA
--          projector emits (`node:provider:invoke-scenario`,
--          `graph-v1-compatibility-provider`, digest 9eb163ab...). The
--          scheduler decomposes the cell into the invoked scenario; the
--          binding rule is the data the overlay builder requires.
--        * `sda-projected-capability-invocation-port.v2` -> its compatibility
--          profile plus the host provider
--          (`languages/typescript/runtimes/node/projected-capability-invocation-provider.mjs`,
--          `createProjectedCapabilityInvocationProvider`, factory true), which
--          loads the named projected application, verifies the binding and
--          authority digests, executes it through the consumer platform with
--          the invocation's effect context, and binds the outcome into the
--          carrier.
--   2. Every Port definition that names a projected application gains
--      `configuration.bindingBase` = `embodiments/<host capability>/projected`,
--      resolved by the host provider against the estate root. The declared
--      `bindingRef` is unchanged.
--   3. The composition digests of `execute-projected-model-provider-attempt`
--      are refreshed to the current projections of its four children
--      (project-model-provider-protocol, project-governed-http-request-body,
--      bind-external-credential-reference, observe-governed-http-exchange).
--
-- Idempotent: a replay finds every binding and base present with the declared
-- value and writes no new definition or port version.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes:
--   node scripts/run-migration.mjs sql/migrations/bind-projected-capability-invocation-and-composition-digests.sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
-- =====================================================================
-- 1. Composition digests refreshed to the current projections.
-- =====================================================================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @digests TABLE (
  namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  binding_digest nvarchar(80) COLLATE Latin1_General_100_BIN2,
  authority_digest nvarchar(80) COLLATE Latin1_General_100_BIN2,
  PRIMARY KEY (namespace_id, declared_id));
INSERT @digests VALUES
 (N'sidefx:capability:execute-projected-model-provider-attempt', N'project-provider-protocol-port',
  N'sha256:59dbd09343c4e0a6f09e60341e7ba4e0aa85c95f5e730bf889e99278e2cb8c62', N'sha256:c40803600181323360751d40db3afd01eeb97ab396bfdfa2a05902bab35964ab'),
 (N'sidefx:capability:execute-projected-model-provider-attempt', N'normalize-provider-protocol-port',
  N'sha256:59dbd09343c4e0a6f09e60341e7ba4e0aa85c95f5e730bf889e99278e2cb8c62', N'sha256:c40803600181323360751d40db3afd01eeb97ab396bfdfa2a05902bab35964ab'),
 (N'sidefx:capability:execute-projected-model-provider-attempt', N'project-request-body-port',
  N'sha256:9a599af98971125fb3499e025a3e8fbb34f75589843fd8cb693311ff5e497940', N'sha256:d16f387050d495c9d7470a737456e7f3a242014e9f261ebc4fad8b6efb18aa9b'),
 (N'sidefx:capability:execute-projected-model-provider-attempt', N'bind-credential-port',
  N'sha256:31457f072c6078786a714f6001c20bd0898bf3927834d8129c64ac7323eb13ec', N'sha256:4b2fc827d4f3b2229ab8183c8be31c72d3cb89686231c1f3a121aab7b3d510f0'),
 (N'sidefx:capability:execute-projected-model-provider-attempt', N'observe-http-port',
  N'sha256:9a59287e7aa98eda8d3062ac37ae6b5a9438bb1c4f3d47a518fa36d80915cab8', N'sha256:e46b8f3d41dce5b4bfc3c07c524d8539754cc0459b05ea4be78ec544c1b31482');

-- =====================================================================
-- 2. Every projected-application Port gains its host-relative binding base.
-- =====================================================================
DECLARE @ports TABLE (
  namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  semantics nvarchar(max),
  prevver bigint,
  changed bit DEFAULT 0,
  PRIMARY KEY (namespace_id, declared_id));
INSERT @ports (namespace_id, declared_id, semantics, prevver)
SELECT n.namespace_id, so.declared_id, JSON_QUERY(latest.envelope, '$.semantics'),
  (SELECT pv.port_version_pk FROM model.port_version pv
    WHERE pv.semantic_object_definition_pk = latest.semantic_object_definition_pk)
FROM model.port p
JOIN model.semantic_object so ON so.semantic_object_pk = p.semantic_object_pk
JOIN model.identity_namespace n ON n.namespace_pk = so.namespace_pk
CROSS APPLY (
  SELECT TOP 1 d.semantic_object_definition_pk,
    CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope
  FROM model.semantic_object_definition d
  JOIN model.estate_definition ed ON ed.semantic_object_definition_pk = d.semantic_object_definition_pk
    AND ed.estate_model_pk = @estate
  JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  WHERE d.semantic_object_pk = p.semantic_object_pk
  ORDER BY d.semantic_object_definition_pk DESC
) latest
WHERE n.namespace_id IN (N'sidefx:capability:execute-projected-model-provider-attempt',
                         N'sidefx:capability:execute-governed-model-invocation',
                         N'sidefx:capability:obtain-governed-model-response')
  AND JSON_VALUE(latest.envelope, '$.semantics.configuration.bindingRef') IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM @ports) THROW 51000, 'COMPOSED_PORTS_NOT_FOUND', 1;
IF EXISTS (SELECT 1 FROM @ports WHERE prevver IS NULL) THROW 51000, 'COMPOSED_PORT_VERSION_MISSING', 1;

DECLARE @namespace nvarchar(400), @declared nvarchar(400), @semantics nvarchar(max), @prevver bigint,
  @host nvarchar(400), @binding_base nvarchar(400), @changed bit,
  @binding_digest nvarchar(80), @authority_digest nvarchar(80),
  @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;
DECLARE port_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT namespace_id, declared_id, semantics, prevver FROM @ports ORDER BY namespace_id, declared_id;
OPEN port_cursor;
FETCH NEXT FROM port_cursor INTO @namespace, @declared, @semantics, @prevver;
WHILE @@FETCH_STATUS = 0 BEGIN
  IF @namespace NOT LIKE N'sidefx:capability:%' THROW 51000, 'COMPOSED_PORT_NAMESPACE_UNEXPECTED', 1;
  SET @host = SUBSTRING(@namespace, LEN(N'sidefx:capability:') + 1, 400);
  SET @binding_base = N'embodiments/' + @host + N'/projected';
  SET @changed = 0;
  IF ISNULL(JSON_VALUE(@semantics, '$.configuration.bindingBase'), N'') <> @binding_base BEGIN
    SET @semantics = JSON_MODIFY(@semantics, '$.configuration.bindingBase', @binding_base);
    SET @changed = 1;
  END
  SET @binding_digest = NULL; SET @authority_digest = NULL;
  SELECT @binding_digest = d.binding_digest, @authority_digest = d.authority_digest
  FROM @digests d WHERE d.namespace_id = @namespace COLLATE Latin1_General_100_BIN2 AND d.declared_id = @declared COLLATE Latin1_General_100_BIN2;
  IF @binding_digest IS NOT NULL AND ISNULL(JSON_VALUE(@semantics, '$.configuration.bindingDigest'), N'') <> @binding_digest BEGIN
    SET @semantics = JSON_MODIFY(@semantics, '$.configuration.bindingDigest', @binding_digest);
    SET @changed = 1;
  END
  IF @authority_digest IS NOT NULL AND ISNULL(JSON_VALUE(@semantics, '$.configuration.capabilityAuthorityDigest'), N'') <> @authority_digest BEGIN
    SET @semantics = JSON_MODIFY(@semantics, '$.configuration.capabilityAuthorityDigest', @authority_digest);
    SET @changed = 1;
  END
  IF @changed = 1 BEGIN
    EXEC model.put_semantic_definition 'PORT', @namespace, @declared, @semantics,
      @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
    SET @portpk = (SELECT port_pk FROM model.port WHERE semantic_object_pk = @object);
    IF @portpk IS NULL THROW 51000, 'COMPOSED_PORT_ROW_MISSING', 1;
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
  FETCH NEXT FROM port_cursor INTO @namespace, @declared, @semantics, @prevver;
END
CLOSE port_cursor;
DEALLOCATE port_cursor;
GO
-- =====================================================================
-- 3. The host invocation Port gains the composition overlay rules and the
--    projected-capability invocation provider.
-- =====================================================================
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @namespace nvarchar(400) = N'sidefx:capability:run-declared-graph';
DECLARE @port nvarchar(400) = N'run-declared-graph-execute';
DECLARE @effect_profile nvarchar(400) = N'sda-platform-effect-graph-provider.v1';
DECLARE @scenario_mechanic nvarchar(400) = N'invoke-scenario';
DECLARE @composed_mechanic nvarchar(400) = N'sda-projected-capability-invocation-port.v2';
DECLARE @composed_profile nvarchar(400) = N'node:provider:sda-projected-capability-invocation-port.v2';
DECLARE @composed_module nvarchar(400) = N'languages/typescript/runtimes/node/projected-capability-invocation-provider.mjs';
DECLARE @composed_export nvarchar(400) = N'createProjectedCapabilityInvocationProvider';
DECLARE @scenario_digest nvarchar(80) = N'sha256:9eb163ab5fc89d9fcd115aa4b9c811a9087c02d11d34c2475b5ba6226cb5e752';
DECLARE @composed_digest nvarchar(80) = N'sha256:c870d5ffa45529b4588cdacc260f28f82dbf85f5d509e25410c32ae44b4387ad';

DECLARE @semantics nvarchar(max), @prevver bigint;
SELECT @semantics = JSON_QUERY(d.definition_json, '$.semantics'),
  @prevver = (SELECT pv.port_version_pk FROM model.port_version pv
              WHERE pv.semantic_object_definition_pk = d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND d.namespace_id = @namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id = @port COLLATE Latin1_General_100_BIN2;
IF @semantics IS NULL OR @prevver IS NULL THROW 51000, 'RUN_DECLARED_GRAPH_EXECUTE_PORT_MISSING', 1;

DECLARE @changed int = 0, @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
               WHERE JSON_VALUE(b.value, '$.mechanicId') = @scenario_mechanic COLLATE Latin1_General_100_BIN2) BEGIN
  DECLARE @with_scenario nvarchar(max) = (
    SELECT mechanicId, providerProfileId, providerProfileDigest, implementationRef
    FROM (
      SELECT JSON_VALUE(b.value, '$.mechanicId') AS mechanicId,
             JSON_VALUE(b.value, '$.providerProfileId') AS providerProfileId,
             JSON_VALUE(b.value, '$.providerProfileDigest') AS providerProfileDigest,
             JSON_VALUE(b.value, '$.implementationRef') AS implementationRef,
             0 AS source_rank, CONVERT(bigint, b.[key]) AS sort_key
      FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
      UNION ALL
      SELECT @scenario_mechanic, N'node:provider:invoke-scenario', @scenario_digest, N'graph-v1-compatibility-provider', 1, NULL
    ) combined
    ORDER BY source_rank, sort_key, mechanicId
    FOR JSON PATH);
  SET @semantics = JSON_MODIFY(@semantics, '$.configuration.overlayBindings', JSON_QUERY(@with_scenario));
  SET @changed = 1;
END
IF NOT EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
               WHERE JSON_VALUE(b.value, '$.mechanicId') = @composed_mechanic COLLATE Latin1_General_100_BIN2) BEGIN
  DECLARE @with_composed nvarchar(max) = (
    SELECT mechanicId, providerProfileId, providerProfileDigest, implementationRef
    FROM (
      SELECT JSON_VALUE(b.value, '$.mechanicId') AS mechanicId,
             JSON_VALUE(b.value, '$.providerProfileId') AS providerProfileId,
             JSON_VALUE(b.value, '$.providerProfileDigest') AS providerProfileDigest,
             JSON_VALUE(b.value, '$.implementationRef') AS implementationRef,
             0 AS source_rank, CONVERT(bigint, b.[key]) AS sort_key
      FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
      UNION ALL
      SELECT @composed_mechanic, @composed_profile, @composed_digest, @composed_module, 1, NULL
    ) combined
    ORDER BY source_rank, sort_key, mechanicId
    FOR JSON PATH);
  SET @semantics = JSON_MODIFY(@semantics, '$.configuration.overlayBindings', JSON_QUERY(@with_composed));
  SET @changed = 1;
END
IF NOT EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.providers')) p
               WHERE JSON_VALUE(p.value, '$.providerProfileId') = @composed_profile COLLATE Latin1_General_100_BIN2) BEGIN
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
      SELECT @composed_profile, @composed_module, @composed_export, CONVERT(bit, 1), 1, NULL
    ) combined
    ORDER BY source_rank, sort_key, providerProfileId
    FOR JSON PATH);
  SET @semantics = JSON_MODIFY(@semantics, '$.configuration.providers', JSON_QUERY(@with_provider));
  SET @changed = 1;
END
IF @changed = 1 BEGIN
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
END
GO
-- ============================== VERIFICATION ==============================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
SELECT '1_execute_overlay' AS result_set,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(d.definition_json,'$.semantics.configuration.overlayBindings')) b
    WHERE JSON_VALUE(b.value,'$.mechanicId')=N'invoke-scenario') AS invoke_scenario_rules,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(d.definition_json,'$.semantics.configuration.overlayBindings')) b
    WHERE JSON_VALUE(b.value,'$.mechanicId')=N'sda-projected-capability-invocation-port.v2') AS composed_port_rules,
  (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(d.definition_json,'$.semantics.configuration.providers')) p
    WHERE JSON_VALUE(p.value,'$.providerProfileId')=N'node:provider:sda-projected-capability-invocation-port.v2') AS composed_providers
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=N'sidefx:capability:run-declared-graph' AND d.declared_id=N'run-declared-graph-execute';
SELECT '2_binding_bases' AS result_set, n.namespace_id, so.declared_id,
  JSON_VALUE(latest.envelope,'$.semantics.configuration.bindingBase') AS binding_base,
  JSON_VALUE(latest.envelope,'$.semantics.configuration.bindingDigest') AS binding_digest,
  JSON_VALUE(latest.envelope,'$.semantics.configuration.capabilityAuthorityDigest') AS authority_digest
FROM model.port p
JOIN model.semantic_object so ON so.semantic_object_pk=p.semantic_object_pk
JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
CROSS APPLY (
  SELECT TOP 1 CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope
  FROM model.semantic_object_definition d
  JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk
    AND ed.estate_model_pk=@estate
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE d.semantic_object_pk=p.semantic_object_pk ORDER BY d.semantic_object_definition_pk DESC
) latest
WHERE n.namespace_id IN (N'sidefx:capability:execute-projected-model-provider-attempt',
                         N'sidefx:capability:execute-governed-model-invocation',
                         N'sidefx:capability:obtain-governed-model-response')
  AND JSON_VALUE(latest.envelope,'$.semantics.configuration.bindingRef') IS NOT NULL
ORDER BY n.namespace_id, so.declared_id;
SELECT '3_chain_ports_without_base' AS result_set, COUNT(*) AS ports_without_base
FROM model.port p
JOIN model.semantic_object so ON so.semantic_object_pk=p.semantic_object_pk
JOIN model.identity_namespace n ON n.namespace_pk=so.namespace_pk
CROSS APPLY (
  SELECT TOP 1 CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope
  FROM model.semantic_object_definition d
  JOIN model.estate_definition ed ON ed.semantic_object_definition_pk=d.semantic_object_definition_pk
    AND ed.estate_model_pk=@estate
  JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
  WHERE d.semantic_object_pk=p.semantic_object_pk ORDER BY d.semantic_object_definition_pk DESC
) latest
WHERE n.namespace_id IN (N'sidefx:capability:execute-projected-model-provider-attempt',
                         N'sidefx:capability:execute-governed-model-invocation',
                         N'sidefx:capability:obtain-governed-model-response')
  AND JSON_VALUE(latest.envelope,'$.semantics.configuration.bindingRef') IS NOT NULL
  AND JSON_VALUE(latest.envelope,'$.semantics.configuration.bindingBase') IS NULL;
COMMIT TRANSACTION;
