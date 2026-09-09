-- Research only. Executed through sidefx_reader against one pinned model.
-- Do not use unscoped model-table counts as selected-estate counts.
SELECT object_kind, COUNT_BIG(*) AS definition_count
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk=@estate_model_pk
GROUP BY object_kind ORDER BY object_kind;

SELECT c.capability_id, ns.namespace_id, ec.capability_version_pk,
       s.scenario_id, cs.scenario_version_pk, sv.source_profile,
       CAST(CASE WHEN root.scenario_pk=cs.scenario_pk THEN 1 ELSE 0 END AS bit) AS is_root,
       si.input_id, si.name AS input_name, si.contract_reference_state AS input_contract_state,
       si.input_contract_version_pk,
       so.outcome_id, so.name AS outcome_name, so.experience, so.terminal, so.terminal_disposition,
       oc.contract_version_pk AS outcome_contract_version_pk
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace ns ON ns.namespace_pk=c.namespace_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.capability_root_scenario root ON root.capability_version_pk=ec.capability_version_pk
LEFT JOIN model.scenario_input si ON si.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.scenario_outcome so ON so.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.scenario_outcome_contract oc ON oc.scenario_version_pk=cs.scenario_version_pk
WHERE ec.estate_model_pk=@estate_model_pk
ORDER BY ns.namespace_id,c.capability_id,s.scenario_id;

SELECT ct.contract_id, ns.namespace_id, cv.contract_version_pk, cv.contract_kind,
       cv.schema_reference_state, cv.schema_object_pk, d.definition_json,
       LOWER(CONVERT(varchar(64), co.content_digest, 2)) AS schema_digest,
       co.content_bytes
FROM model.contract_version cv
JOIN model.contract ct ON ct.contract_pk=cv.contract_pk
JOIN model.identity_namespace ns ON ns.namespace_pk=ct.namespace_pk
JOIN analysis.v_selected_semantic_definition d
  ON d.semantic_object_definition_pk=cv.semantic_object_definition_pk AND d.estate_model_pk=@estate_model_pk
LEFT JOIN model.schema_object sob ON sob.schema_object_pk=cv.schema_object_pk
LEFT JOIN source.content_object co
  ON co.content_object_pk=sob.content_object_pk
  OR (sob.schema_object_pk IS NULL AND co.content_digest=TRY_CONVERT(binary(32),JSON_VALUE(d.definition_json,'$.semantics.schema_digest'),2))
ORDER BY ns.namespace_id,ct.contract_id,cv.contract_version_pk;

SELECT object_kind,semantic_object_definition_pk,definition_json
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk=@estate_model_pk AND object_kind IN ('SCENARIO','SCENARIO_INPUT','SCENARIO_OUTCOME')
ORDER BY object_kind,semantic_object_definition_pk;

SELECT v.scenario_version_pk,v.variant_id,v.terminal
FROM model.outcome_variant v
WHERE EXISTS(SELECT 1 FROM model.estate_definition ed WHERE ed.estate_model_pk=@estate_model_pk AND ed.semantic_object_definition_pk=v._owner_definition_pk)
ORDER BY v.scenario_version_pk,v.variant_id;

SELECT 'outcome_product' AS relationship,COUNT_BIG(*) AS relationship_count
FROM model.outcome_product p
WHERE EXISTS(SELECT 1 FROM model.estate_definition ed WHERE ed.estate_model_pk=@estate_model_pk AND ed.semantic_object_definition_pk=p._owner_definition_pk)
UNION ALL
SELECT 'outcome_variant_product',COUNT_BIG(*) FROM model.outcome_variant_product p
WHERE EXISTS(SELECT 1 FROM model.estate_definition ed WHERE ed.estate_model_pk=@estate_model_pk AND ed.semantic_object_definition_pk=p._owner_definition_pk);

SELECT c.capability_id,ns.namespace_id,
       (SELECT COUNT_BIG(*) FROM model.capability_scenario cs WHERE cs.capability_version_pk=ec.capability_version_pk) AS scenario_count,
       (SELECT COUNT_BIG(*) FROM model.capability_root_scenario rs WHERE rs.capability_version_pk=ec.capability_version_pk) AS root_count
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
JOIN model.identity_namespace ns ON ns.namespace_pk=c.namespace_pk
WHERE ec.estate_model_pk=@estate_model_pk
ORDER BY ns.namespace_id,c.capability_id;
