-- Hand-authored module references in the selected generation.
-- Invocation must be driven by data: a declaration row that names an implementation
-- module (*.mjs, *.js, *.py, *.cs, *.ts) is a finding, regardless of which field
-- carries it. Run read-only with --committed against the current model.
DECLARE @estate bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);

-- 1. Provider definitions whose declared implementation is a module file.
SELECT 'PROVIDER' AS object_kind, p.provider_id AS declared_id,
       'semantics.module' AS field,
       JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.module') AS reference
FROM model.provider p
JOIN model.provider_definition pd ON pd.provider_pk = p.provider_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = pd.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
JOIN analysis.v_selected_semantic_definition sd ON sd.semantic_object_definition_pk = pd.semantic_object_definition_pk
WHERE sd.estate_model_pk = @estate
  AND JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.module') IS NOT NULL

UNION ALL

-- 2. Port definitions that still embed an estate provider module.
SELECT 'PORT', declared_id, 'semantics.configuration.estateProvider.module',
       JSON_VALUE(definition_json, '$.semantics.configuration.estateProvider.module')
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk = @estate AND object_kind = 'PORT'
  AND JSON_VALUE(definition_json, '$.semantics.configuration.estateProvider.module') IS NOT NULL

UNION ALL

-- 3. Port definitions that embed an admission provider module.
SELECT 'PORT', declared_id, 'semantics.configuration.admissionProvider.module',
       JSON_VALUE(definition_json, '$.semantics.configuration.admissionProvider.module')
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk = @estate AND object_kind = 'PORT'
  AND JSON_VALUE(definition_json, '$.semantics.configuration.admissionProvider.module') IS NOT NULL

UNION ALL

-- 4. Target-selection provider arrays (planning / writing) that name modules.
SELECT 'PORT', d.declared_id, 'semantics.configuration.planningProviders[].module', p.module
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json, '$.semantics.configuration.planningProviders') pp
CROSS APPLY (SELECT JSON_VALUE(pp.value, '$.module') AS module) p
WHERE d.estate_model_pk = @estate AND p.module IS NOT NULL

UNION ALL

SELECT 'PORT', d.declared_id, 'semantics.configuration.writingProviders[].module', p.module
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json, '$.semantics.configuration.writingProviders') wp
CROSS APPLY (SELECT JSON_VALUE(wp.value, '$.module') AS module) p
WHERE d.estate_model_pk = @estate AND p.module IS NOT NULL

UNION ALL

-- 5. Residual: any declaration whose raw text names an implementation path and is
--    not already reported above.
SELECT d.object_kind, d.declared_id, 'raw-declaration', LEFT(d.definition_json, 120)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk = @estate
  AND (d.definition_json LIKE '%src/resolvers/%' OR d.definition_json LIKE '%src/verification/%')
  AND JSON_VALUE(d.definition_json, '$.semantics.configuration.estateProvider.module') IS NULL
  AND JSON_VALUE(d.definition_json, '$.semantics.configuration.admissionProvider.module') IS NULL
  AND NOT EXISTS (SELECT 1 FROM OPENJSON(d.definition_json, '$.semantics.configuration.planningProviders') pp CROSS APPLY (SELECT JSON_VALUE(pp.value,'$.module') m) x WHERE x.m IS NOT NULL)
  AND NOT EXISTS (SELECT 1 FROM OPENJSON(d.definition_json, '$.semantics.configuration.writingProviders') wp CROSS APPLY (SELECT JSON_VALUE(wp.value,'$.module') m) x WHERE x.m IS NOT NULL)
  AND d.object_kind <> 'PROVIDER'

ORDER BY object_kind, declared_id, field;
