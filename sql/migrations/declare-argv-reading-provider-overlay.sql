-- Declare the argv-reading platform mechanic in the host execution overlay.
--
-- argv-provider's root authority invokes argv-reading-port, whose selected
-- definition declares platformCapabilityId `sda-argv-reading-port.v1`. The
-- installed C# mechanic registry now declares scheduler provider profiles for
-- that mechanic (node:/csharp: provider:sda-argv-reading-port.v1) and a direct
-- event-port body, but the host execution port `run-declared-graph-execute`
-- maps mechanic ids to provider profiles in its declared overlayBindings, and
-- that rule set did not name the mechanic. A direct
-- `capability invoke argv-provider` therefore compiled and refused
-- SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING.
--
-- This migration adds exactly one overlay rule to the selected
-- `run-declared-graph-execute` semantics:
--   mechanicId sda-argv-reading-port.v1 -> node:provider:sda-argv-reading-port.v1
-- The provider body is the C# `ProcessArgumentsProvider` the registry names; the
-- profile digest is the content address of that body.
--
-- Idempotent: a replay finds the rule with the same profile/digest/implementation
-- and mints no definition or port version. A rule naming the mechanic with a
-- different profile refuses OVERLAY_RULE_PROFILE_CONFLICT.
--
-- Preflight: ends with ROLLBACK; run as a dry run with the migration runner.
-- The install is the .commit.sql copy (identical except COMMIT).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @namespace nvarchar(400) = N'sidefx:capability:run-declared-graph';
DECLARE @port nvarchar(400) = N'run-declared-graph-execute';
DECLARE @mechanic nvarchar(400) = N'sda-argv-reading-port.v1';
DECLARE @profile nvarchar(400) = N'node:provider:sda-argv-reading-port.v1';
DECLARE @profile_digest nvarchar(80) = N'sha256:4e01499156677df5ad0b59c9057d6d4e1029dd2ea7a3712dd1150ebfaa4bff6a';
DECLARE @implementation_ref nvarchar(400) = N'languages/csharp/src/ScenarioKernel.Adapters/Consumer/ProcessArgumentsProvider.cs';
DECLARE @semantics nvarchar(max), @prevver bigint;
SELECT @semantics = JSON_QUERY(d.definition_json, '$.semantics'),
  @prevver = (SELECT pv.port_version_pk FROM model.port_version pv
              WHERE pv.semantic_object_definition_pk = d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate AND d.object_kind = 'PORT'
  AND d.namespace_id = @namespace COLLATE Latin1_General_100_BIN2
  AND d.declared_id = @port COLLATE Latin1_General_100_BIN2;
IF @semantics IS NULL OR @prevver IS NULL THROW 51000, 'RUN_DECLARED_GRAPH_EXECUTE_PORT_MISSING', 1;
IF EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
           WHERE JSON_VALUE(b.value, '$.mechanicId') = @mechanic COLLATE Latin1_General_100_BIN2
             AND JSON_VALUE(b.value, '$.providerProfileId') <> @profile COLLATE Latin1_General_100_BIN2)
 THROW 51000, 'OVERLAY_RULE_PROFILE_CONFLICT', 1;
IF NOT EXISTS (SELECT 1 FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
               WHERE JSON_VALUE(b.value, '$.mechanicId') = @mechanic COLLATE Latin1_General_100_BIN2
                 AND JSON_VALUE(b.value, '$.providerProfileId') = @profile COLLATE Latin1_General_100_BIN2
                 AND JSON_VALUE(b.value, '$.providerProfileDigest') = @profile_digest COLLATE Latin1_General_100_BIN2
                 AND JSON_VALUE(b.value, '$.implementationRef') = @implementation_ref COLLATE Latin1_General_100_BIN2)
BEGIN
  DECLARE @with_rule nvarchar(max) = (
    SELECT mechanicId, providerProfileId, providerProfileDigest, implementationRef
    FROM (
      SELECT JSON_VALUE(b.value, '$.mechanicId') AS mechanicId,
             JSON_VALUE(b.value, '$.providerProfileId') AS providerProfileId,
             JSON_VALUE(b.value, '$.providerProfileDigest') AS providerProfileDigest,
             JSON_VALUE(b.value, '$.implementationRef') AS implementationRef,
             0 AS source_rank, CONVERT(bigint, b.[key]) AS sort_key
      FROM OPENJSON(JSON_QUERY(@semantics, '$.configuration.overlayBindings')) b
      WHERE JSON_VALUE(b.value, '$.mechanicId') <> @mechanic COLLATE Latin1_General_100_BIN2
      UNION ALL
      SELECT @mechanic, @profile, @profile_digest, @implementation_ref, 1, NULL
    ) combined
    ORDER BY source_rank, sort_key, mechanicId
    FOR JSON PATH);
  SET @semantics = JSON_MODIFY(@semantics, '$.configuration.overlayBindings', JSON_QUERY(@with_rule));
  DECLARE @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;
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

-- Readback: the rule, the selected execution port version and its rule count.
SELECT 'argv_reading_overlay' AS result_set, p.port_id, pv.port_version_pk,
 COUNT(*) AS overlay_rule_count,
 SUM(CASE WHEN JSON_VALUE(b.value,'$.mechanicId')=@mechanic THEN 1 ELSE 0 END) AS argv_reading_rules,
 MAX(CASE WHEN JSON_VALUE(b.value,'$.mechanicId')=@mechanic
   THEN JSON_VALUE(b.value,'$.providerProfileId') END) AS argv_reading_profile
FROM model.port p
JOIN model.port_version pv ON pv.port_pk=p.port_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dt
CROSS APPLY OPENJSON(JSON_QUERY(dt.text,'$.semantics.configuration.overlayBindings')) b
WHERE p.port_id=@port
  AND pv.port_version_pk=(SELECT MAX(pv2.port_version_pk) FROM model.port_version pv2 WHERE pv2.port_pk=p.port_pk)
GROUP BY p.port_id, pv.port_version_pk;
ROLLBACK TRANSACTION;
