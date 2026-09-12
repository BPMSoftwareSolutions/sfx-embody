-- fix-capability-feature-direction.sql
--
-- Correct the feature/capability dependency direction. The feature writeup comes
-- first; the capability is built from it and now references it. Today the
-- dependency is inverted: model.feature.capability_pk -> model.capability, and
-- model.feature_version(feature_pk, capability_pk) -> model.feature.
--
-- This migration:
--   1. adds model.capability.feature_pk with a foreign key to model.feature;
--   2. backfills it from the inverted model.feature.capability_pk;
--   3. removes the inverted FK, unique index and columns.
--
-- Default: ROLLBACK after verification. Replace the final ROLLBACK with COMMIT
-- to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- The backfill UPDATE on model.capability needs its immutability guard absent.
DROP TRIGGER IF EXISTS model.guard_capability;

-- 1. Add the forward key (nullable: 220 of 292 capabilities have a feature today).
IF COL_LENGTH(N'model.capability', N'feature_pk') IS NULL
  ALTER TABLE model.capability ADD feature_pk bigint NULL;
GO

-- 2. Backfill from the inverted key. One feature per capability today, so the
--    mapping is unambiguous.
UPDATE c SET c.feature_pk = f.feature_pk
FROM model.capability c JOIN model.feature f ON f.capability_pk = c.capability_pk
WHERE c.feature_pk IS NULL;

-- 3. Remove the inverted constraints/index before removing their columns.
IF OBJECT_ID(N'model.FK_model_feature_version_feature', N'F') IS NOT NULL
  ALTER TABLE model.feature_version DROP CONSTRAINT FK_model_feature_version_feature;
IF OBJECT_ID(N'model.FK_model_feature_capability', N'F') IS NOT NULL
  ALTER TABLE model.feature DROP CONSTRAINT FK_model_feature_capability;
IF OBJECT_ID(N'model.UK_model_feature_pk_capability', N'UQ') IS NOT NULL
  ALTER TABLE model.feature DROP CONSTRAINT UK_model_feature_pk_capability;

-- 3a. Rebuild feature_version -> feature on feature_pk only.
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_model_feature_version_feature')
  ALTER TABLE model.feature_version WITH CHECK ADD CONSTRAINT FK_model_feature_version_feature FOREIGN KEY (feature_pk) REFERENCES model.feature (feature_pk);

-- 3b. Drop the inverted column from model.feature. model.feature_version keeps
--     its capability_pk: it is a version-scoped key used by composite child FKs
--     (estate_capability_feature, capability_feature, feature_scenario) and is
--     not the feature -> capability direction this migration corrects.
IF COL_LENGTH(N'model.feature', N'capability_pk') IS NOT NULL
  ALTER TABLE model.feature DROP COLUMN capability_pk;

-- 4. Add the forward foreign key and a lookup index.
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_model_capability_feature')
  ALTER TABLE model.capability WITH CHECK ADD CONSTRAINT FK_model_capability_feature FOREIGN KEY (feature_pk) REFERENCES model.feature (feature_pk);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_model_capability_feature_pk' AND object_id = OBJECT_ID(N'model.capability'))
  CREATE NONCLUSTERED INDEX IX_model_capability_feature_pk ON model.capability (feature_pk);

-- 5. Verification.
SELECT '1_capability_columns' AS result_set, c.name AS column_name, ty.name AS type_name, c.is_nullable
FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'model.capability') ORDER BY c.column_id;
SELECT '2_feature_columns' AS result_set, c.name AS column_name, ty.name AS type_name
FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'model.feature') ORDER BY c.column_id;
SELECT '3_feature_version_columns' AS result_set, c.name AS column_name, ty.name AS type_name
FROM sys.columns c JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'model.feature_version') ORDER BY c.column_id;
SELECT '4_forward_key' AS result_set, fk.name, fk.is_disabled, fk.is_not_trusted
FROM sys.foreign_keys fk WHERE fk.name = N'FK_model_capability_feature';
SELECT '5_backfill' AS result_set,
  (SELECT COUNT(*) FROM model.capability) AS capabilities,
  (SELECT COUNT(*) FROM model.capability WHERE feature_pk IS NOT NULL) AS capabilities_with_feature;
SELECT '6_inverted_remaining' AS result_set,
  COL_LENGTH(N'model.feature', N'capability_pk') AS feature_capability_pk,
  COL_LENGTH(N'model.feature_version', N'capability_pk') AS feature_version_capability_pk_retained;

ROLLBACK TRANSACTION;
-- Replace ROLLBACK with COMMIT to install.
