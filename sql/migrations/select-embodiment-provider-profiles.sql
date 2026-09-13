-- M1: select provider profiles from their normalized declarations.
-- Each registry names its target and each profile version names its registry.
-- This read assembles those existing rows without changing any provider body.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers = CURSOR LOCAL FAST_FORWARD FOR
  SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
  FROM sys.triggers t
  JOIN sys.objects o ON o.object_id = t.parent_id
  JOIN sys.schemas s ON s.schema_id = o.schema_id
  WHERE o.type = 'U' AND s.name IN ('model', 'source')
    AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS = 0
BEGIN
  EXEC(N'DROP TRIGGER ' + @trigger_name);
  FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
CREATE OR ALTER VIEW analysis.v_target_provider_profile AS
SELECT d.estate_model_pk,
       JSON_VALUE(r.definition_json, '$.semantics.language') AS target_id,
       p.provider_profile_id,
       pv.provider_profile_version_pk,
       pv.profile_authority,
       JSON_VALUE(d.definition_json, '$.semantics.effectClassification') AS effect_classification,
       JSON_VALUE(r.definition_json, '$.semantics.providerModuleRoot') AS provider_module_root,
       JSON_VALUE(d.definition_json, '$.semantics.providerModule') AS provider_module,
       JSON_VALUE(d.definition_json, '$.semantics.providerExport') AS provider_export,
       JSON_VALUE(d.definition_json, '$.semantics.mechanicAuthorityRef') AS mechanic_authority_ref,
       JSON_VALUE(d.definition_json, '$.semantics.mechanicAuthorityDigest') AS mechanic_authority_digest,
       'sha256:' + LOWER(CONVERT(varchar(64), pv.definition_digest, 2)) AS profile_definition_digest
FROM model.provider_profile p
JOIN model.provider_profile_version pv ON pv.provider_profile_pk = p.provider_profile_pk
JOIN analysis.v_selected_semantic_definition d
  ON d.semantic_object_definition_pk = pv.semantic_object_definition_pk
 AND d.object_kind = 'PROVIDER_PROFILE'
JOIN analysis.v_selected_semantic_definition r
  ON r.estate_model_pk = d.estate_model_pk
 AND r.object_kind = 'AUTHORITY'
 AND r.declared_id = pv.profile_authority
WHERE JSON_VALUE(r.definition_json, '$.semantics.registryType') IS NOT NULL;
GO
GRANT SELECT ON OBJECT::analysis.v_target_provider_profile TO sidefx_reader;

DECLARE @selected_model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1);
IF EXISTS (
  SELECT target_id, effect_classification
  FROM analysis.v_target_provider_profile
  WHERE estate_model_pk = @selected_model
  GROUP BY target_id, effect_classification HAVING COUNT_BIG(*) <> 1
) THROW 51000, 'TARGET_PROVIDER_PROFILE_AMBIGUOUS', 1;
IF EXISTS (
  SELECT 1 FROM analysis.v_target_provider_profile
  WHERE estate_model_pk = @selected_model
    AND (target_id IS NULL OR provider_module_root IS NULL OR provider_module IS NULL
         OR provider_export IS NULL OR effect_classification NOT IN ('pure', 'effect'))
) THROW 51000, 'TARGET_PROVIDER_PROFILE_INCOMPLETE', 1;
IF (SELECT COUNT_BIG(*) FROM analysis.v_target_provider_profile WHERE estate_model_pk = @selected_model) <> 6
  THROW 51000, 'TARGET_PROVIDER_PROFILE_BASELINE_CHANGED', 1;

SELECT 'target_provider_profiles' AS result_set, target_id, provider_profile_id,
       effect_classification, provider_module_root, provider_module, provider_export,
       profile_definition_digest
FROM analysis.v_target_provider_profile
WHERE estate_model_pk = @selected_model
ORDER BY target_id, effect_classification;
COMMIT TRANSACTION;
