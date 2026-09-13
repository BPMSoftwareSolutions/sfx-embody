-- inspect-execution-source-dependencies.sql
--
-- Read-only inspection. Shows exactly what execution currently obtains from
-- retained source and how much of it the working declarations already own:
--
--   1. the source-authority resolution the read path performs
--      (capability-embodiment.sql resolves exactly one source authority via source_lineage)
--   2. the documents the planner (materialize-node.mjs) reads from that source
--   3. the pinned platform authority rows the planner also reads
--   4. what the model declares for the capability
--   5. the planner requirement -> model kind gap
--
-- Edit @capability_id (default hello-world-sql); @namespace_id is optional.

SET NOCOUNT ON;
DECLARE @capability_id nvarchar(400) = N'hello-world-sql';
DECLARE @namespace_id nvarchar(400) = NULL;
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
DECLARE @snap bigint = (SELECT estate_snapshot_pk FROM source.estate_model WHERE estate_model_pk = @model);
DECLARE @capPk bigint, @capVer bigint, @capSod bigint;
SELECT @capPk = ec.capability_pk, @capVer = ec.capability_version_pk, @capSod = ec.semantic_object_definition_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE ec.estate_model_pk = @model AND c.capability_id = @capability_id
  AND (@namespace_id IS NULL OR n.namespace_id = @namespace_id);

-- 0. The selection everything below is scoped to.
SELECT '0_selection' AS result_set, @model AS estate_model_pk, @snap AS estate_snapshot_pk,
       @capability_id AS capability_id, @capPk AS capability_pk,
       @capVer AS capability_version_pk, @capSod AS capability_definition_pk;

-- 1. The source-authority resolution. capability-embodiment.sql requires exactly
--    one distinct resolved source; more or fewer throws CAPABILITY_SOURCE_AUTHORITY_UNRESOLVED.
SELECT '1_source_authority_resolution' AS result_set,
  l.member_kind, l.canonical_pointer,
  a.source_appearance_pk, a.source_path, a.source_class, a.entry_id,
  CONVERT(varchar(64), a.capsule_digest, 2) AS capsule_digest,
  CONVERT(varchar(64), co.content_digest, 2) AS content_digest, co.byte_length
FROM source.source_lineage l
JOIN source.source_observation o ON o.source_observation_pk = l.source_observation_pk
JOIN source.source_appearance a ON a.source_appearance_pk = o.source_appearance_pk
JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
WHERE l.semantic_object_definition_pk = @capSod
ORDER BY a.source_path;

-- 2. How many distinct source authorities that resolution yields (must be 1 to execute).
SELECT '2_distinct_source_authorities' AS result_set, COUNT(DISTINCT a.capsule_digest) AS distinct_sources
FROM source.source_lineage l
JOIN source.source_observation o ON o.source_observation_pk = l.source_observation_pk
JOIN source.source_appearance a ON a.source_appearance_pk = o.source_appearance_pk
WHERE l.semantic_object_definition_pk = @capSod AND a.capsule_digest IS NOT NULL;

-- 3. The documents the planner reads from that source (materialize-node recordsets[1]),
--    each labelled with the role the planner consumes it as.
DECLARE @capsule binary(32) = (SELECT TOP 1 a.capsule_digest FROM source.source_lineage l
  JOIN source.source_observation o ON o.source_observation_pk = l.source_observation_pk
  JOIN source.source_appearance a ON a.source_appearance_pk = o.source_appearance_pk
  WHERE l.semantic_object_definition_pk = @capSod);
SELECT '3_retained_source_documents' AS result_set,
  CASE
    WHEN a.source_path LIKE N'%interfaces.authority.json' THEN 'interfaces'
    WHEN a.source_path LIKE N'%consumer-workspace.authority.json' THEN 'consumer workspace'
    WHEN a.source_path LIKE N'%execution-authorities.authority.json' THEN 'execution authorities'
    WHEN a.source_path LIKE N'%semantic-graph.authority.json' THEN 'semantic graph'
    WHEN a.source_path LIKE N'%semantic-transformation.authority.json' THEN 'transformation'
    WHEN a.source_path LIKE N'%fixtures.authority.json' THEN 'fixtures'
    WHEN a.source_path LIKE N'%contracts/%' THEN 'contracts'
    WHEN a.source_path LIKE N'%capability.authority.json' THEN 'capability authority'
    WHEN a.source_path LIKE N'%capability.feature' OR a.source_path LIKE N'features/%' THEN 'feature'
    ELSE 'other'
  END AS role,
  a.source_path, a.source_class, a.entry_id,
  CONVERT(varchar(64), co.content_digest, 2) AS content_digest, co.byte_length
FROM source.source_appearance a
JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
WHERE a.capsule_digest = @capsule
ORDER BY role, a.source_path;

-- 4. Role summary of the planner's source documents.
SELECT '4_retained_role_summary' AS result_set, x.role, COUNT(*) AS documents
FROM (
  SELECT CASE
    WHEN a.source_path LIKE N'%interfaces.authority.json' THEN 'interfaces'
    WHEN a.source_path LIKE N'%consumer-workspace.authority.json' THEN 'consumer workspace'
    WHEN a.source_path LIKE N'%execution-authorities.authority.json' THEN 'execution authorities'
    WHEN a.source_path LIKE N'%semantic-graph.authority.json' THEN 'semantic graph'
    WHEN a.source_path LIKE N'%semantic-transformation.authority.json' THEN 'transformation'
    WHEN a.source_path LIKE N'%fixtures.authority.json' THEN 'fixtures'
    WHEN a.source_path LIKE N'%contracts/%' THEN 'contracts'
    WHEN a.source_path LIKE N'%capability.authority.json' THEN 'capability authority'
    WHEN a.source_path LIKE N'%capability.feature' OR a.source_path LIKE N'features/%' THEN 'feature'
    ELSE 'other' END AS role
  FROM source.source_appearance a WHERE a.capsule_digest = @capsule) x
GROUP BY x.role ORDER BY x.role;

-- 5. The pinned platform authority the planner also reads (materialize-node recordsets[2]).
SELECT '5_pinned_platform_authority' AS result_set, a.source_path, a.source_class,
  CONVERT(varchar(64), co.content_digest, 2) AS content_digest, co.byte_length
FROM source.source_appearance a
JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
WHERE a.source_class = 'PINNED_PLATFORM_AUTHORITY'
ORDER BY a.source_path;

-- 6. What the model declares for this capability (working declarations).
DECLARE @scnVers TABLE (scenario_version_pk bigint);
INSERT @scnVers SELECT cs.scenario_version_pk FROM model.capability_scenario cs WHERE cs.capability_version_pk = @capVer;
SELECT '6_model_declarations' AS result_set, object_kind, rows_declared FROM (
  SELECT 'CAPABILITY' AS object_kind, COUNT(*) AS rows_declared FROM model.capability_version WHERE capability_pk = @capPk
  UNION ALL SELECT 'SCENARIO', (SELECT COUNT(*) FROM @scnVers)
  UNION ALL SELECT 'SCENARIO_INPUT', (SELECT COUNT(*) FROM model.scenario_input WHERE scenario_version_pk IN (SELECT scenario_version_pk FROM @scnVers))
  UNION ALL SELECT 'SCENARIO_EVENT', (SELECT COUNT(*) FROM model.scenario_event WHERE scenario_version_pk IN (SELECT scenario_version_pk FROM @scnVers))
  UNION ALL SELECT 'SCENARIO_OUTCOME', (SELECT COUNT(*) FROM model.scenario_outcome WHERE scenario_version_pk IN (SELECT scenario_version_pk FROM @scnVers))
  UNION ALL SELECT 'EXECUTION_AUTHORITY', (SELECT COUNT(*) FROM model.execution_authority ea JOIN model.identity_namespace n ON n.namespace_pk = ea.namespace_pk WHERE n.namespace_id = N'sidefx:capability:' + @capability_id)
  UNION ALL SELECT 'PORT', (SELECT COUNT(*) FROM model.port p JOIN model.identity_namespace n ON n.namespace_pk = p.namespace_pk WHERE n.namespace_id = N'sidefx:capability:' + @capability_id)
  UNION ALL SELECT 'TRANSFORMATION', (SELECT COUNT(*) FROM model.transformation t JOIN model.identity_namespace n ON n.namespace_pk = t.namespace_pk WHERE n.namespace_id = N'sidefx:capability:' + @capability_id)
  UNION ALL SELECT 'OBSERVABLE_CONDITION', (SELECT COUNT(*) FROM model.observable_condition WHERE owner_definition_pk = @capSod)
  UNION ALL SELECT 'FEATURE', (SELECT COUNT(*) FROM model.feature WHERE feature_id = @capability_id)
  UNION ALL SELECT 'CONTRACT', (SELECT COUNT(DISTINCT cv.contract_pk) FROM model.contract_version cv WHERE cv.contract_version_pk IN (
      SELECT si.input_contract_version_pk FROM model.scenario_input si WHERE si.scenario_version_pk IN (SELECT scenario_version_pk FROM @scnVers)
      UNION SELECT soc.contract_version_pk FROM model.scenario_outcome_contract soc WHERE soc.scenario_version_pk IN (SELECT scenario_version_pk FROM @scnVers)))
) k ORDER BY object_kind;

-- 7. The planner's requirement -> model kind gap. `model_kind` is the model kind that
--    would own it; '(none)' means the model has no kind for it today.
SELECT '7_planner_input_gap' AS result_set, requirement, source_artifact, model_kind FROM (VALUES
  ('capability authority',      'capabilities/<id>/capability.authority.json',       'CAPABILITY'),
  ('feature',                   'features/<id>.feature',                             'FEATURE'),
  ('execution authorities',     'capabilities/<id>/execution-authorities.authority.json', 'EXECUTION_AUTHORITY'),
  ('ports / interface binding', 'capabilities/<id>/interfaces.authority.json',       'PORT'),
  ('transformation',            'capabilities/<id>/semantic-transformation.authority.json', 'TRANSFORMATION'),
  ('contracts + schemas',       'capabilities/<id>/contracts/*',                     'CONTRACT'),
  ('observable conditions',     '(capability authority experience)',                 'OBSERVABLE_CONDITION'),
  ('fixtures',                  'capabilities/<id>/fixtures.authority.json',         'FIXTURE'),
  ('consumer workspace',        'capabilities/<id>/consumer-workspace.authority.json', '(none)'),
  ('semantic graph',            'capabilities/<id>/semantic-graph.authority.json',   '(none)'),
  ('platform registry',         'node-mechanic-registry.authority.v1.json',          '(source: PINNED_PLATFORM_AUTHORITY)')
) p(requirement, source_artifact, model_kind);

-- 8. Dependency summary.
SELECT '8_dependency_summary' AS result_set,
  (SELECT COUNT(*) FROM source.source_lineage WHERE semantic_object_definition_pk = @capSod) AS lineage_rows,
  (SELECT COUNT(DISTINCT a.capsule_digest) FROM source.source_appearance a WHERE a.capsule_digest = @capsule) AS source_documents_distinct_sources,
  (SELECT COUNT(*) FROM source.source_appearance a WHERE a.capsule_digest = @capsule) AS source_documents,
  (SELECT COUNT(*) FROM source.source_appearance WHERE source_class = 'PINNED_PLATFORM_AUTHORITY') AS platform_authority_rows,
  (SELECT COUNT(*) FROM model.estate_definition WHERE estate_model_pk = @model) AS model_definitions;
