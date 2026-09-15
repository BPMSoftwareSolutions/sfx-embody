-- list-projected-bodies.sql
--
-- Lists the database copy of a capability's projected mechanical bodies keyed by
-- capability + generation + projection target + relative path, with the
-- content-addressed digest of each body:
--
--   node scripts/run-query.mjs scripts/queries/list-projected-bodies.sql
--
-- The current generation is the highest generation row that carries
-- source_class='PROJECTED_BODY' rows for the capability. A capability has one
-- such generation after each publish; older generations remain readable by
-- naming their estate_snapshot_pk instead of the MAX below.
SET NOCOUNT ON;
DECLARE @capability nvarchar(400) = N'resolve-equity-market-price-evidence';
DECLARE @generationPk bigint = (
  SELECT MAX(a.estate_snapshot_pk)
  FROM source.source_appearance a
  WHERE a.source_class = 'PROJECTED_BODY'
    AND JSON_VALUE(a.container_locator, '$.capabilityId') = @capability);

SELECT 'PROJECTED_BODY' AS result_set,
  JSON_VALUE(a.container_locator, '$.capabilityId') AS capability_id,
  a.estate_snapshot_pk AS generation_pk,
  'sha256:' + LOWER(CONVERT(varchar(64), s.snapshot_digest, 2)) AS generation,
  'sha256:' + LOWER(CONVERT(varchar(64), s.estate_manifest_digest, 2)) AS manifest_digest,
  JSON_VALUE(a.container_locator, '$.projectionTarget') AS target,
  JSON_VALUE(a.container_locator, '$.relativePath') AS relative_path,
  a.entry_id AS locator_entry,
  a.source_path AS locator_path,
  'sha256:' + LOWER(CONVERT(varchar(64), c.content_digest, 2)) AS digest,
  c.byte_length AS byte_length
FROM source.source_appearance a
JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
JOIN source.estate_snapshot s ON s.estate_snapshot_pk = a.estate_snapshot_pk
WHERE a.source_class = 'PROJECTED_BODY'
  AND a.estate_snapshot_pk = @generationPk
ORDER BY target, relative_path;

-- The same read proves the mapping stays off the hot path: no model object or
-- definition, no selected definition, no execution declaration and no source
-- observation references a projected body.
SELECT 'HOT_PATH_ISOLATION' AS result_set,
  (SELECT COUNT(*) FROM model.semantic_object WHERE object_kind = 'PROJECTED_BODY') AS model_objects,
  (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition WHERE object_kind = 'PROJECTED_BODY') AS selected_definitions,
  (SELECT COUNT(*) FROM analysis.v_capability_execution_declaration WHERE source_path LIKE N'projected-bodies/%') AS declaration_documents,
  (SELECT COUNT(*) FROM model.semantic_object_definition d
     JOIN source.source_appearance a ON a.content_object_pk = d.canonical_content_pk
     WHERE a.source_class = 'PROJECTED_BODY' AND a.estate_snapshot_pk = @generationPk) AS model_definitions_over_bodies,
  (SELECT COUNT(*) FROM source.source_observation o
     JOIN source.source_appearance a ON a.source_appearance_pk = o.source_appearance_pk
     WHERE a.source_class = 'PROJECTED_BODY' AND a.estate_snapshot_pk = @generationPk) AS observations_over_bodies,
  (SELECT COUNT(*) FROM source.source_lineage l
     JOIN source.source_observation o ON o.source_observation_pk = l.source_observation_pk
     JOIN source.source_appearance a ON a.source_appearance_pk = o.source_appearance_pk
     WHERE a.source_class = 'PROJECTED_BODY' AND a.estate_snapshot_pk = @generationPk) AS lineage_rows_over_bodies;
