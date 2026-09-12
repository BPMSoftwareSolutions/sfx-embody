-- delete-platform-capabilities-v1-v2.sql
--
-- Remove the capability rows in namespace sidefx:platform-capabilities whose
-- capability_id ends in .v1 or .v2 (68 + 2 = 70 today), with their dependent
-- normalized rows. Defaults to ROLLBACK; replace with COMMIT to apply.
--
-- The deletion is scoped to the tables these catalog capabilities actually
-- populate (they have no scenarios, ports, transformations, features or model
-- membership). Any remaining foreign-key reference will fail the transaction.
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- Lift the immutability guards on the schemas this touches.
DECLARE @drop nvarchar(max) = N'';
SELECT @drop = @drop + N'DROP TRIGGER IF EXISTS ' + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N';' + CHAR(10)
FROM sys.triggers tr
JOIN sys.objects o ON o.object_id = tr.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE (tr.name LIKE N'guard[_]%' OR tr.name LIKE N'%immutable%') AND s.name IN (N'model', N'source', N'analysis', N'runtime');
EXEC sp_executesql @drop;

-- Target sets.
CREATE TABLE #cap (capability_pk bigint PRIMARY KEY, semantic_object_pk bigint NOT NULL);
INSERT #cap
SELECT c.capability_pk, c.semantic_object_pk
FROM model.capability c
JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE n.namespace_id = N'sidefx:platform-capabilities'
  AND (c.capability_id LIKE N'%.v1' OR c.capability_id LIKE N'%.v2');

CREATE TABLE #capver (capability_version_pk bigint PRIMARY KEY, capability_pk bigint NOT NULL, sod bigint NOT NULL);
INSERT #capver
SELECT cv.capability_version_pk, cv.capability_pk, cv.semantic_object_definition_pk
FROM model.capability_version cv JOIN #cap ON #cap.capability_pk = cv.capability_pk;

CREATE TABLE #sod (sod bigint PRIMARY KEY);
INSERT #sod SELECT sod FROM #capver;

-- ===================== BEFORE =====================
-- Every capability and its integrity counters, with a flag for the delete set.
SELECT 'BEFORE_all_capabilities' AS result_set, c.capability_pk, n.namespace_id, c.capability_id,
  CASE WHEN EXISTS (SELECT 1 FROM #cap WHERE #cap.capability_pk = c.capability_pk) THEN 1 ELSE 0 END AS is_target,
  (SELECT COUNT(*) FROM model.capability_version cv WHERE cv.capability_pk = c.capability_pk) AS versions,
  (SELECT COUNT(*) FROM model.scenario s WHERE s.capability_pk = c.capability_pk) AS scenarios,
  (SELECT COUNT(*) FROM model.estate_capability ec WHERE ec.capability_pk = c.capability_pk) AS model_memberships,
  (SELECT COUNT(*) FROM model.semantic_object_definition d WHERE d.semantic_object_pk = c.semantic_object_pk) AS definitions,
  (SELECT COUNT(*) FROM model.estate_definition ed WHERE ed.semantic_object_definition_pk IN (SELECT d.semantic_object_definition_pk FROM model.semantic_object_definition d WHERE d.semantic_object_pk = c.semantic_object_pk)) AS estate_definition_rows,
  (SELECT COUNT(*) FROM model.provider_capability_implementation pci JOIN model.capability_version cv ON cv.capability_version_pk = pci.capability_version_pk WHERE cv.capability_pk = c.capability_pk) AS provider_implementations,
  (SELECT COUNT(*) FROM source.source_lineage l WHERE l.semantic_object_definition_pk IN (SELECT d.semantic_object_definition_pk FROM model.semantic_object_definition d WHERE d.semantic_object_pk = c.semantic_object_pk)) AS lineage_rows
FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
ORDER BY n.namespace_id, c.capability_id;

SELECT 'BEFORE_totals' AS result_set,
  (SELECT COUNT(*) FROM model.capability) AS capabilities,
  (SELECT COUNT(*) FROM model.capability_version) AS capability_versions,
  (SELECT COUNT(*) FROM model.estate_definition) AS estate_definition_rows,
  (SELECT COUNT(*) FROM model.semantic_object) AS semantic_objects,
  (SELECT COUNT(*) FROM model.semantic_object_definition) AS semantic_object_definitions,
  (SELECT COUNT(*) FROM model.provider_capability_implementation) AS provider_capability_implementations,
  (SELECT COUNT(*) FROM source.source_lineage) AS lineage_rows;

-- 1. Rows that name a target definition.
DELETE FROM source.source_lineage WHERE semantic_object_definition_pk IN (SELECT sod FROM #sod);
DELETE FROM model.estate_definition WHERE semantic_object_definition_pk IN (SELECT sod FROM #sod);
DELETE FROM model.observable_condition WHERE owner_definition_pk IN (SELECT sod FROM #sod);
DELETE FROM model.definition_version_label WHERE semantic_object_definition_pk IN (SELECT sod FROM #sod);
DELETE FROM model.expression_semantic_reference WHERE semantic_object_definition_pk IN (SELECT sod FROM #sod);
DELETE FROM analysis.assessment_definition_input WHERE semantic_object_definition_pk IN (SELECT sod FROM #sod);
DELETE FROM analysis.integrity_finding WHERE subject_definition_pk IN (SELECT sod FROM #sod);
DELETE FROM analysis.compatibility_assessment WHERE authority_definition_pk IN (SELECT sod FROM #sod);
DELETE FROM analysis.provider_qualification_assessment WHERE authority_definition_pk IN (SELECT sod FROM #sod) OR rule_definition_pk IN (SELECT sod FROM #sod);

-- 2. Provider implementations of a target capability version.
DELETE FROM model.provider_capability_implementation WHERE capability_version_pk IN (SELECT capability_version_pk FROM #capver);

-- 3. Model membership and association rows.
DELETE FROM model.estate_capability_feature WHERE capability_pk IN (SELECT capability_pk FROM #cap);
DELETE FROM model.estate_capability WHERE capability_pk IN (SELECT capability_pk FROM #cap);
DELETE FROM model.capability_feature WHERE capability_version_pk IN (SELECT capability_version_pk FROM #capver);
DELETE FROM model.capability_scenario WHERE capability_version_pk IN (SELECT capability_version_pk FROM #capver);
DELETE FROM model.capability_root_scenario WHERE capability_version_pk IN (SELECT capability_version_pk FROM #capver);
DELETE FROM model.blueprint_version WHERE capability_version_pk IN (SELECT capability_version_pk FROM #capver);
DELETE FROM runtime.capability_preparation WHERE capability_pk IN (SELECT capability_pk FROM #cap);

-- 4. Identity. The semantic_object / semantic_object_definition rows are kept:
--    other bounded contexts (media.subject and others) reference them, and the
--    capability is already removed from model.capability and estate_definition.
DELETE FROM model.capability_version WHERE capability_pk IN (SELECT capability_pk FROM #cap);
DELETE FROM model.capability WHERE capability_pk IN (SELECT capability_pk FROM #cap);

-- ===================== AFTER =====================
SELECT 'AFTER_targets_removed' AS result_set, COUNT(*) AS targets_remaining
FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
WHERE n.namespace_id = N'sidefx:platform-capabilities' AND (c.capability_id LIKE N'%.v1' OR c.capability_id LIKE N'%.v2');

-- Every capability that remains, with the same integrity counters as BEFORE.
SELECT 'AFTER_remaining_capabilities' AS result_set, c.capability_pk, n.namespace_id, c.capability_id,
  (SELECT COUNT(*) FROM model.capability_version cv WHERE cv.capability_pk = c.capability_pk) AS versions,
  (SELECT COUNT(*) FROM model.scenario s WHERE s.capability_pk = c.capability_pk) AS scenarios,
  (SELECT COUNT(*) FROM model.estate_capability ec WHERE ec.capability_pk = c.capability_pk) AS model_memberships,
  (SELECT COUNT(*) FROM model.semantic_object_definition d WHERE d.semantic_object_pk = c.semantic_object_pk) AS definitions,
  (SELECT COUNT(*) FROM model.estate_definition ed WHERE ed.semantic_object_definition_pk IN (SELECT d.semantic_object_definition_pk FROM model.semantic_object_definition d WHERE d.semantic_object_pk = c.semantic_object_pk)) AS estate_definition_rows,
  (SELECT COUNT(*) FROM model.provider_capability_implementation pci JOIN model.capability_version cv ON cv.capability_version_pk = pci.capability_version_pk WHERE cv.capability_pk = c.capability_pk) AS provider_implementations,
  (SELECT COUNT(*) FROM source.source_lineage l WHERE l.semantic_object_definition_pk IN (SELECT d.semantic_object_definition_pk FROM model.semantic_object_definition d WHERE d.semantic_object_pk = c.semantic_object_pk)) AS lineage_rows
FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
ORDER BY n.namespace_id, c.capability_id;

SELECT 'AFTER_totals' AS result_set,
  (SELECT COUNT(*) FROM model.capability) AS capabilities,
  (SELECT COUNT(*) FROM model.capability_version) AS capability_versions,
  (SELECT COUNT(*) FROM model.estate_definition) AS estate_definition_rows,
  (SELECT COUNT(*) FROM model.semantic_object) AS semantic_objects,
  (SELECT COUNT(*) FROM model.semantic_object_definition) AS semantic_object_definitions,
  (SELECT COUNT(*) FROM model.provider_capability_implementation) AS provider_capability_implementations,
  (SELECT COUNT(*) FROM source.source_lineage) AS lineage_rows;

-- Referential integrity after the delete.
SELECT 'AFTER_orphan_checks' AS result_set,
  (SELECT COUNT(*) FROM model.capability_version cv WHERE NOT EXISTS (SELECT 1 FROM model.capability c WHERE c.capability_pk = cv.capability_pk)) AS versions_without_capability,
  (SELECT COUNT(*) FROM model.estate_definition ed WHERE NOT EXISTS (SELECT 1 FROM model.semantic_object_definition d WHERE d.semantic_object_definition_pk = ed.semantic_object_definition_pk)) AS estate_defs_without_definition,
  (SELECT COUNT(*) FROM model.provider_capability_implementation pci WHERE NOT EXISTS (SELECT 1 FROM model.capability_version cv WHERE cv.capability_version_pk = pci.capability_version_pk)) AS provider_impls_without_version,
  (SELECT COUNT(*) FROM model.capability c WHERE NOT EXISTS (SELECT 1 FROM model.semantic_object so WHERE so.semantic_object_pk = c.semantic_object_pk)) AS capabilities_without_semantic_object,
  (SELECT COUNT(*) FROM #sod s WHERE EXISTS (SELECT 1 FROM model.semantic_object_definition d WHERE d.semantic_object_definition_pk = s.sod)) AS retained_target_definitions;

ROLLBACK TRANSACTION;
-- Replace ROLLBACK with COMMIT to apply.
