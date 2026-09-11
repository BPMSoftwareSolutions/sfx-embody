-- Executed through the restricted, transaction-pinned database reader.
SELECT @estate_model_pk AS estate_model_pk, @snapshot_id AS snapshot_id,
       @projection_id AS projection_id;

SELECT n.namespace_id, c.capability_id, ec.capability_version_pk,
       d.canonical_content_pk, co.content_bytes AS definition_bytes
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
WHERE ec.estate_model_pk = @estate_model_pk
ORDER BY n.namespace_id, c.capability_id;

SELECT n.namespace_id, c.capability_id, s.scenario_id, cs.scenario_version_pk,
       co.content_bytes AS definition_bytes
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk = cs.scenario_version_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = sv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
WHERE ec.estate_model_pk = @estate_model_pk
ORDER BY n.namespace_id, c.capability_id, s.scenario_id;

SELECT a.source_path, a.source_class, a.entry_id, a.container_locator,
       LOWER(CONVERT(varchar(64), a.capsule_digest, 2)) AS capsule_digest,
       LOWER(CONVERT(varchar(64), co.content_digest, 2)) AS content_digest, co.byte_length
FROM source.source_appearance a
JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
JOIN source.estate_model m ON m.estate_snapshot_pk = a.estate_snapshot_pk
WHERE m.estate_model_pk = @estate_model_pk AND a.source_path LIKE '%.feature'
ORDER BY a.source_path, a.source_class, co.content_digest;

SELECT DISTINCT c.capability_id, a.source_path, a.source_class, a.entry_id,
       LOWER(CONVERT(varchar(64), co.content_digest, 2)) AS content_digest
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk = ec.capability_pk
JOIN source.source_lineage l ON l.semantic_object_definition_pk = ec.semantic_object_definition_pk
JOIN source.source_observation o ON o.source_observation_pk = l.source_observation_pk
JOIN source.source_appearance a ON a.source_appearance_pk = o.source_appearance_pk
JOIN source.content_object co ON co.content_object_pk = a.content_object_pk
WHERE ec.estate_model_pk = @estate_model_pk AND a.source_path LIKE '%.feature'
ORDER BY c.capability_id, a.source_path, a.source_class;

-- Distinguish current invocation selection from the retained identity/version inventory.
SELECT (SELECT COUNT_BIG(*) FROM model.capability) AS retained_capability_identities,
       (SELECT COUNT_BIG(*) FROM model.capability_version) AS retained_capability_versions;

SELECT n.namespace_id, c.capability_id
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE NOT EXISTS (SELECT 1 FROM model.estate_capability ec
                  WHERE ec.estate_model_pk = @estate_model_pk AND ec.capability_pk = c.capability_pk)
ORDER BY n.namespace_id, c.capability_id;
