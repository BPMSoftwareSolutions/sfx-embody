-- Why `generate-executable-capability-scaffold` cannot be prepared, and
-- `resolve-sidefx-eligible-providers` can.
--
-- Self-contained: resolves the published model from source.current_model, so it
-- runs as-is in SSMS / Azure Data Studio against the `sidefx` database.
-- Run the whole file, or any block below the DECLARE block. Do not insert GO
-- between blocks -- the variables are declared once for the whole batch.
--
-- (If you instead run this through `npm run query`, that harness already injects
-- @estate_model_pk. Delete the first DECLARE line to avoid a redeclare error.)
--
-- Summary of what these return today: nothing is missing from the scaffold. It
-- carries strictly more authority than the working capability. The only
-- discriminator is query 3 -- nine JSON Schema arrays declared without `items`,
-- which the node type-graph builder refuses to project.

SET NOCOUNT ON;

DECLARE @estate_model_pk bigint =
  (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);

DECLARE @snap bigint =
  (SELECT estate_snapshot_pk FROM source.estate_model WHERE estate_model_pk = @estate_model_pk);

SELECT @estate_model_pk AS estate_model_pk, @snap AS estate_snapshot_pk;


---------------------------------------------------------------------------
-- 1. Preparation state. `sfx capability invoke` loads a prepared body; it does
--    not plan. A capability with no row here fails CAPABILITY_PREPARATION_REQUIRED.
---------------------------------------------------------------------------
SELECT c.capability_id, p.target,
       DATALENGTH(p.payload_bytes) AS payload_bytes, p.prepared_at
FROM model.capability c
LEFT JOIN runtime.capability_preparation p ON p.capability_pk = c.capability_pk
WHERE c.capability_id IN ('generate-executable-capability-scaffold',
                          'resolve-sidefx-eligible-providers')
ORDER BY c.capability_id, p.prepared_at;

-- Estate-wide: how many capabilities ever prepared successfully.
SELECT COUNT_BIG(DISTINCT p.capability_pk) AS prepared,
       (SELECT COUNT_BIG(*) FROM model.capability
         WHERE capability_id NOT LIKE 'sda-%') AS harness_capabilities
FROM runtime.capability_preparation p;


---------------------------------------------------------------------------
-- 2. Capsule entry inventory, side by side. Confirms the scaffold is not
--    missing any authority document the working capability has.
---------------------------------------------------------------------------
SELECT a.entry_id,
       MAX(CASE WHEN a.source_path LIKE 'capabilities/generate-executable-capability-scaffold/%'
                THEN c.byte_length END) AS scaffold_bytes,
       MAX(CASE WHEN a.source_path LIKE 'capabilities/resolve-sidefx-eligible-providers/%'
                THEN c.byte_length END) AS providers_bytes
FROM source.source_appearance a
JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
WHERE a.estate_snapshot_pk = @snap AND a.source_class = 'MANAGED_CAPSULE'
  AND (a.source_path LIKE 'capabilities/generate-executable-capability-scaffold/%'
    OR a.source_path LIKE 'capabilities/resolve-sidefx-eligible-providers/%')
GROUP BY a.entry_id
ORDER BY a.entry_id;

-- Note: `resolve-sidefx-eligible-providers` shows only contracts/contract-catalog.json.
-- Its schema documents resolve through catalog locators to shared repository
-- source paths outside its own capsule prefix, so they are absent from this
-- comparison by design -- not missing.


---------------------------------------------------------------------------
-- 3. THE DISCRIMINATOR. Every JSON Schema array declared without an `items`
--    schema, per capability. JsonSchemaTypeGraphBuilder.buildNode throws
--    "Array schema at '<pointer>' has no admitted item schema." on the first one.
--
--    Scope note: this walks contracts/*.schema.json entries carried inside each
--    capsule. Schemas reached only through catalog locators to shared paths are
--    not covered, so a zero here means "no open array in its own capsule schemas".
---------------------------------------------------------------------------
WITH capsule AS (
  SELECT DISTINCT a.capsule_digest,
         JSON_VALUE(CAST(CONVERT(varchar(max), c.content_bytes) AS nvarchar(max)),'$.capabilityId') AS capability_id
  FROM source.source_appearance a
  JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
  WHERE a.estate_snapshot_pk = @snap AND a.source_class = 'MANAGED_CAPSULE'
    AND a.entry_id = 'capability.authority.json'
),
schemas AS (
  SELECT DISTINCT k.capability_id, a.entry_id,
         CAST(CONVERT(varchar(max), c.content_bytes) AS nvarchar(max)) AS body
  FROM source.source_appearance a
  JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
  JOIN capsule k ON k.capsule_digest = a.capsule_digest
  WHERE a.estate_snapshot_pk = @snap AND a.source_class = 'MANAGED_CAPSULE'
    AND a.entry_id LIKE 'contracts/%.schema.json'
    AND ISJSON(CAST(CONVERT(varchar(max), c.content_bytes) AS nvarchar(max))) = 1
),
nodes AS (
  SELECT capability_id, entry_id,
         CAST('$' AS nvarchar(4000)) COLLATE DATABASE_DEFAULT AS path,
         CAST(body AS nvarchar(max)) AS node
  FROM schemas
  UNION ALL
  -- OPENJSON keys come back BIN2; the explicit COLLATE keeps the anchor and the
  -- recursive part type-compatible. j.type 4/5 = nested array/object only.
  SELECT n.capability_id, n.entry_id,
         CAST(n.path + '.' + CAST(j.[key] AS nvarchar(400)) AS nvarchar(4000)) COLLATE DATABASE_DEFAULT,
         CAST(j.value AS nvarchar(max))
  FROM nodes n CROSS APPLY OPENJSON(n.node) j
  WHERE ISJSON(n.node) = 1 AND LEN(n.path) < 3000 AND j.type IN (4,5)
)
SELECT capability_id, entry_id, path AS open_array_pointer
FROM nodes
WHERE ISJSON(node) = 1
  AND JSON_VALUE(node,'$.type') = 'array'
  AND JSON_QUERY(node,'$.items') IS NULL
  AND capability_id IN ('generate-executable-capability-scaffold',
                        'resolve-sidefx-eligible-providers')
ORDER BY capability_id, entry_id, path
OPTION (MAXRECURSION 1000);

-- Returns 9 rows, all scaffold, zero for resolve-sidefx-eligible-providers:
--   contracts/carrier.schema.json  $.properties.authoredArtifacts
--                                  $.properties.authoringWorkQueue
--                                  $.properties.capabilitySlots
--                                  $.properties.evidenceObligations
--                                  $.properties.findings          <- the one it throws on
--                                  $.properties.mechanicSlots
--                                  $.properties.providerSlots
--   contracts/input.schema.json    $...archetypeTopology.properties.edges
--                                  $...archetypeTopology.properties.nodes


---------------------------------------------------------------------------
-- 4. Blast radius. Same walk, no capability filter, grouped per capability.
---------------------------------------------------------------------------
WITH capsule AS (
  SELECT DISTINCT a.capsule_digest,
         JSON_VALUE(CAST(CONVERT(varchar(max), c.content_bytes) AS nvarchar(max)),'$.capabilityId') AS capability_id
  FROM source.source_appearance a
  JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
  WHERE a.estate_snapshot_pk = @snap AND a.source_class = 'MANAGED_CAPSULE'
    AND a.entry_id = 'capability.authority.json'
),
schemas AS (
  SELECT DISTINCT k.capability_id, a.entry_id,
         CAST(CONVERT(varchar(max), c.content_bytes) AS nvarchar(max)) AS body
  FROM source.source_appearance a
  JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
  JOIN capsule k ON k.capsule_digest = a.capsule_digest
  WHERE a.estate_snapshot_pk = @snap AND a.source_class = 'MANAGED_CAPSULE'
    AND a.entry_id LIKE 'contracts/%.schema.json'
    AND ISJSON(CAST(CONVERT(varchar(max), c.content_bytes) AS nvarchar(max))) = 1
),
nodes AS (
  SELECT capability_id, entry_id,
         CAST('$' AS nvarchar(4000)) COLLATE DATABASE_DEFAULT AS path,
         CAST(body AS nvarchar(max)) AS node
  FROM schemas
  UNION ALL
  SELECT n.capability_id, n.entry_id,
         CAST(n.path + '.' + CAST(j.[key] AS nvarchar(400)) AS nvarchar(4000)) COLLATE DATABASE_DEFAULT,
         CAST(j.value AS nvarchar(max))
  FROM nodes n CROSS APPLY OPENJSON(n.node) j
  WHERE ISJSON(n.node) = 1 AND LEN(n.path) < 3000 AND j.type IN (4,5)
)
SELECT capability_id,
       COUNT(*)                 AS open_arrays,
       COUNT(DISTINCT entry_id) AS schema_docs
FROM nodes
WHERE ISJSON(node) = 1
  AND JSON_VALUE(node,'$.type') = 'array'
  AND JSON_QUERY(node,'$.items') IS NULL
GROUP BY capability_id
ORDER BY open_arrays DESC
OPTION (MAXRECURSION 1000);

-- Top rows observed 2026-09-09:
--   project-focus-navigation                14 open arrays / 2 docs
--   shape-governed-file-system-batch        13 / 9
--   evaluate-scenario-solution-candidate    10 / 3
--   generate-executable-capability-scaffold  9 / 2
--   resolve-estate-dependency-closure        7 / 2
--   ... 30+ capabilities affected in total.


---------------------------------------------------------------------------
-- The fix, and why it is a data fix rather than a platform fix.
--
-- `{"type":"array"}` and `{"type":"array","items":{}}` are identical to Ajv --
-- an empty schema admits any item -- but only the second is projectable:
-- buildNode requires a non-array object at `items`, then resolves `{}` through
-- its existing typeless branch to { kind: "primitive", primitive: "unknown" }.
--
-- Verified locally by patching those 9 pointers in the in-memory authority
-- bundle (and recomputing each content digest, which planNode checks):
-- planNode then produced 576 files across all 16 scaffold scenarios.
--
-- Persisting it is the open question. source.content_object is immutable and
-- sidefx_importer holds DENY UPDATE/DELETE, so this cannot be an in-place edit:
-- it needs revised bytes appended as a new estate model and published via
-- source.publish_model.
---------------------------------------------------------------------------
