-- complete-run-declared-graph-pure-mechanic-bindings.sql
--
-- Lane C unit 4 (docs/implementation-strategy.md): the estate-level invocation
-- overlay on `run-declared-graph` must cover the pure-mechanic set the declared
-- provider actually embodies, so no invoked capability fails with
-- `SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING` for a mechanic the kernel
-- already evaluates.
--
-- Evidence first: `resolve-sidefx-eligible-providers` failed with
--   SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING: 'map'
-- (evidence/invocation-optimization-installed-2026-09-14T23-52-15.455Z/). Its
-- compiled graph requires `greater-than`, `includes`, `json-stringify`, `map`,
-- `merge` and `sha256`, all pure mechanics already evaluated by the declared
-- provider `sda-semantic-value-graph-provider.v1`; none was bound in the
-- `run-declared-graph-execute` Port's overlay.
--
-- The binding set is derived from the estate's own MECHANIC registry, not typed
-- here: every selected MECHANIC whose declared semantics route it to
-- `semantic-value-provider.v1` and that is not yet bound. The four declared
-- mechanics with no observing embodiment (`bind-path`,
-- `canonical-json-byte-validation`, `retained-lineage-authorization`,
-- `canonical-artifact-byte-planning`; conformance/execution-graph/mechanics/
-- README.md) are deliberately excluded: binding them would claim a provider
-- mapping no embodiment observes. A capability that needs one is an SDA
-- embodiment request, not an overlay gap.
--
-- The change is one Port definition: merge the missing bindings into
-- `configuration.overlayBindings`, write the new definition and Port version,
-- and relink the operation that invokes it. Existing bindings keep their order;
-- additions append in mechanic-id order. A second run adds nothing.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; to install (after the from-transaction preflight passes).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @guards TABLE (object_id int PRIMARY KEY, trigger_name nvarchar(517), is_disabled bit, definition nvarchar(max));
INSERT @guards
SELECT t.object_id, QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), t.is_disabled, m.definition
FROM sys.triggers t JOIN sys.objects o ON o.object_id = t.parent_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
LEFT JOIN sys.sql_modules m ON m.object_id = t.object_id
WHERE o.type = 'U' AND s.name IN ('model', 'source')
  AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
-- Restore the guard DDL immediately; a later installation must not remove or
-- enable/disable any guard.
SAVE TRANSACTION run_declared_graph_guards;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers = CURSOR LOCAL FAST_FORWARD FOR SELECT trigger_name FROM @guards;
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS = 0 BEGIN
  EXEC(N'DROP TRIGGER ' + @trigger_name);
  FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
ROLLBACK TRANSACTION run_declared_graph_guards;
IF EXISTS (
  SELECT 1 FROM @guards g
  LEFT JOIN sys.triggers t ON t.object_id = g.object_id
  LEFT JOIN sys.sql_modules m ON m.object_id = g.object_id
  WHERE t.object_id IS NULL OR t.is_disabled <> g.is_disabled
    OR ISNULL(m.definition, N'') <> ISNULL(g.definition, N'')
) THROW 51000, 'RUN_DECLARED_GRAPH_GUARDS_NOT_RESTORED', 1;
SELECT 'guard_state_restored' AS result_set, COUNT(*) AS guard_count FROM @guards;
GO
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @namespace nvarchar(400) = N'sidefx:capability:run-declared-graph';
DECLARE @port nvarchar(400) = N'run-declared-graph-execute';
DECLARE @profile nvarchar(400) = N'sda-semantic-value-graph-provider.v1';
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
DECLARE @bound_before int = (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')));

-- The provider profile and implementation are taken from an existing binding of
-- that profile, so the additions cannot drift from the installed configuration.
DECLARE @profile_digest nvarchar(80), @implementation_ref nvarchar(400);
SELECT TOP 1 @profile_digest = JSON_VALUE(b.value, '$.providerProfileDigest'),
             @implementation_ref = JSON_VALUE(b.value, '$.implementationRef')
FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
WHERE JSON_VALUE(b.value, '$.providerProfileId') = @profile COLLATE Latin1_General_100_BIN2;
IF @profile_digest IS NULL OR @implementation_ref IS NULL THROW 51000, 'SEMANTIC_VALUE_PROVIDER_BINDING_TEMPLATE_MISSING', 1;

-- Declared pure mechanics the semantic-value provider embodies but the overlay
-- does not bind yet. The four unembodied declarations are excluded deliberately.
DECLARE @additions TABLE (mechanic_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @additions
SELECT d.declared_id COLLATE Latin1_General_100_BIN2
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.object_kind = 'MECHANIC'
  AND JSON_VALUE(d.definition_json, '$.semantics.mechanic.effectClassification') = N'pure'
  AND EXISTS (
    SELECT 1 FROM OPENJSON(JSON_QUERY(d.definition_json, '$.semantics.mechanic.sourceProfiles')) p
    WHERE p.value = N'semantic-value-provider.v1' COLLATE Latin1_General_100_BIN2)
  AND d.declared_id COLLATE Latin1_General_100_BIN2 NOT IN (
    N'bind-path', N'canonical-json-byte-validation',
    N'retained-lineage-authorization', N'canonical-artifact-byte-planning')
  AND NOT EXISTS (
    SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
    WHERE JSON_VALUE(b.value, '$.mechanicId') = d.declared_id COLLATE Latin1_General_100_BIN2);

DECLARE @changed int = 0, @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;
IF EXISTS (SELECT 1 FROM @additions) BEGIN
  DECLARE @merged nvarchar(max) = (
    SELECT mechanicId, providerProfileId, providerProfileDigest, implementationRef
    FROM (
      SELECT JSON_VALUE(b.value, '$.mechanicId') AS mechanicId,
             JSON_VALUE(b.value, '$.providerProfileId') AS providerProfileId,
             JSON_VALUE(b.value, '$.providerProfileDigest') AS providerProfileDigest,
             JSON_VALUE(b.value, '$.implementationRef') AS implementationRef,
             0 AS source_rank, CONVERT(bigint, b.[key]) AS sort_key
      FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
      UNION ALL
      SELECT a.mechanic_id, @profile, @profile_digest, @implementation_ref, 1, NULL
      FROM @additions a
    ) combined
    ORDER BY source_rank, sort_key, mechanicId
    FOR JSON PATH);
  SET @semantics = JSON_MODIFY(@semantics, '$.configuration.overlayBindings', JSON_QUERY(@merged));
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

DECLARE @bound_after int = (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')));
DECLARE @remaining int = (
  SELECT COUNT_BIG(*)
  FROM analysis.v_selected_semantic_definition d
  WHERE d.estate_model_pk = @estate AND d.object_kind = 'MECHANIC'
    AND JSON_VALUE(d.definition_json, '$.semantics.mechanic.effectClassification') = N'pure'
    AND EXISTS (
      SELECT 1 FROM OPENJSON(JSON_QUERY(d.definition_json, '$.semantics.mechanic.sourceProfiles')) p
      WHERE p.value = N'semantic-value-provider.v1' COLLATE Latin1_General_100_BIN2)
    AND d.declared_id COLLATE Latin1_General_100_BIN2 NOT IN (
      N'bind-path', N'canonical-json-byte-validation',
      N'retained-lineage-authorization', N'canonical-artifact-byte-planning')
    AND NOT EXISTS (
      SELECT 1 FROM @additions a WHERE a.mechanic_id = d.declared_id COLLATE Latin1_General_100_BIN2)
    AND NOT EXISTS (
      SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
      WHERE JSON_VALUE(b.value, '$.mechanicId') = d.declared_id COLLATE Latin1_General_100_BIN2));

SELECT 'run_declared_graph_overlay' AS result_set, @changed AS changed,
  @bound_before AS bound_before, @bound_after AS bound_after,
  (SELECT COUNT(*) FROM @additions) AS added, @remaining AS required_pure_unbound;
SELECT 'added_binding' AS result_set, a.mechanic_id, @profile AS provider_profile_id
FROM @additions a ORDER BY a.mechanic_id;
SELECT 'port_definition' AS result_set, d.declared_id,
  LOWER(CONVERT(varchar(64), d.definition_digest, 2)) AS definition_digest,
  (SELECT pv.port_version_pk FROM model.port_version pv
   WHERE pv.semantic_object_definition_pk = d.semantic_object_definition_pk) AS port_version_pk
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND d.namespace_id = @namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id = @port COLLATE Latin1_General_100_BIN2;

COMMIT TRANSACTION;
