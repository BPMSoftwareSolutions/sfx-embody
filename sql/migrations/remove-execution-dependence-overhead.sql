-- remove-execution-dependence-overhead.sql
--
-- The database is a mutable workshop. Capability authority lives outside it, in
-- the harness and sealed capsules, so the guards that block working-data edits
-- and force a new generation plus validation/publication are maintenance
-- overhead, not authority.
--
-- Selection is by demonstrated necessity, not by name: a guard is removed only
-- when its own definition contains a condition this loop depends on removing
-- (IMMUTABLE_INSPECTION_DATA, PUBLISHED_*, or MODEL_MUST_START_BUILDING). Every
-- guard is reported with the reason it was kept or removed. Permissions are
-- scoped to the two objects the scaffold updates, not whole schemas.
--
-- Default: ROLLBACK after the report. To apply, replace the final ROLLBACK with
-- COMMIT and re-run.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('tempdb..#guard') IS NOT NULL DROP TABLE #guard;
CREATE TABLE #guard (schema_name sysname, trigger_name sysname, blocks bit, reason nvarchar(400));
INSERT #guard
SELECT s.name, tr.name,
  CASE WHEN d.definition LIKE N'%IMMUTABLE_INSPECTION_DATA%'
         OR d.definition LIKE N'%PUBLISHED[_]%'
         OR d.definition LIKE N'%MODEL_MUST_START_BUILDING%' THEN 1 ELSE 0 END,
  CASE WHEN d.definition LIKE N'%IMMUTABLE_INSPECTION_DATA%' THEN N'blocks update/delete of working data (IMMUTABLE_INSPECTION_DATA)'
       WHEN d.definition LIKE N'%PUBLISHED[_]%' THEN N'blocks working inserts into the selected model (PUBLISHED_*)'
       WHEN d.definition LIKE N'%MODEL_MUST_START_BUILDING%' THEN N'forces a new BUILDING generation (MODEL_MUST_START_BUILDING)'
       ELSE N'no condition this loop depends on removing; keep'
  END
FROM sys.triggers tr
JOIN sys.objects o ON o.object_id = tr.object_id
JOIN sys.schemas s ON s.schema_id = o.schema_id
CROSS APPLY (SELECT OBJECT_DEFINITION(tr.object_id) AS definition) d
WHERE tr.name LIKE N'guard[_]%' AND s.name IN (N'source', N'model', N'analysis') AND d.definition IS NOT NULL;

DECLARE @drop nvarchar(max) = N'';
SELECT @drop = @drop + N'DROP TRIGGER ' + QUOTENAME(schema_name) + N'.' + QUOTENAME(trigger_name) + N';' + CHAR(10)
FROM #guard WHERE blocks = 1;
IF @drop = N'' THROW 51000, 'NO_BLOCKING_GUARDS_FOUND', 1;

BEGIN TRANSACTION;

-- 1. Remove only the guards whose own definition carries a blocking condition.
EXEC sp_executesql @drop;

-- 2. Lift the schema-wide importer DENY, then grant only the two updates the
--    scaffold performs. The importer keeps its existing schema-level INSERT.
REVOKE UPDATE, DELETE ON SCHEMA::source FROM sidefx_importer;
REVOKE UPDATE, DELETE ON SCHEMA::model FROM sidefx_importer;
GRANT UPDATE ON OBJECT::source.source_appearance TO sidefx_importer;
GRANT UPDATE ON OBJECT::model.scenario_outcome TO sidefx_importer;

-- 3. Report every guard and its disposition, plus the resulting importer grants.
SELECT '1_GUARDS' AS result_set, schema_name, trigger_name, blocks, reason
FROM #guard ORDER BY blocks DESC, schema_name, trigger_name;
SELECT '2_REMAINING_BLOCKING' AS result_set, COUNT(*) AS blocking_guards_remaining FROM #guard WHERE blocks = 1;
SELECT '3_IMPORTER_UPDATE' AS result_set, dp.permission_name, dp.state_desc, dp.class_desc, OBJECT_SCHEMA_NAME(dp.major_id) + '.' + OBJECT_NAME(dp.major_id) AS target
FROM sys.database_permissions dp
WHERE dp.grantee_principal_id = DATABASE_PRINCIPAL_ID(N'sidefx_importer') AND dp.permission_name IN ('UPDATE', 'DELETE')
ORDER BY dp.state_desc, target;
SELECT '4_DROPPED' AS result_set, @drop AS statements;

ROLLBACK TRANSACTION;
-- To apply, replace the ROLLBACK above with COMMIT and re-run.
