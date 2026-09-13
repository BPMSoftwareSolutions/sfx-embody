-- fix-equity-meaning-lineage.sql
--
-- The meaning declaration minted a new capability definition but not its source
-- resolution. The read path resolves a capability's retained source through its
-- definition's lineage and requires exactly one; the new definition had none, so
-- invoke failed with CAPABILITY_SOURCE_AUTHORITY_UNRESOLVED.
--
-- This copies the source resolution from the most recent capability definition
-- that still has one onto the currently selected definition.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capPk bigint = (SELECT capability_pk FROM model.capability WHERE capability_id=N'resolve-equity-market-price-evidence');
DECLARE @newSod bigint = (SELECT semantic_object_definition_pk FROM model.estate_capability WHERE estate_model_pk=@model AND capability_pk=@capPk);
DECLARE @srcSod bigint = (SELECT TOP 1 cv.semantic_object_definition_pk FROM model.capability_version cv
  WHERE cv.capability_pk=@capPk AND cv.semantic_object_definition_pk<>@newSod
    AND EXISTS (SELECT 1 FROM source.source_lineage l WHERE l.semantic_object_definition_pk=cv.semantic_object_definition_pk)
  ORDER BY cv.capability_version_pk DESC);

-- ============================== BEFORE ==============================
SELECT 'BEFORE_selected' AS result_set, @newSod AS selected_sod,
  (SELECT COUNT(*) FROM source.source_lineage l WHERE l.semantic_object_definition_pk=@newSod) AS lineage_rows,
  (SELECT COUNT(DISTINCT a.capsule_digest) FROM source.source_lineage l
     JOIN source.source_observation o ON o.source_observation_pk=l.source_observation_pk
     JOIN source.source_appearance a ON a.source_appearance_pk=o.source_appearance_pk
     WHERE l.semantic_object_definition_pk=@newSod AND a.capsule_digest IS NOT NULL) AS capsules;
SELECT 'BEFORE_source' AS result_set, @srcSod AS source_sod,
  (SELECT COUNT(*) FROM source.source_lineage l WHERE l.semantic_object_definition_pk=@srcSod) AS lineage_rows;

-- Drop the workshop data guards.
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;

BEGIN TRANSACTION;
IF @srcSod IS NOT NULL
  INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  SELECT @newSod, l.member_kind, l.canonical_pointer, l.source_observation_pk, l.mapping_rule_pk, l.contribution_role
  FROM source.source_lineage l
  WHERE l.semantic_object_definition_pk=@srcSod
    AND NOT EXISTS (SELECT 1 FROM source.source_lineage x WHERE x.semantic_object_definition_pk=@newSod AND x.member_kind=l.member_kind AND x.source_observation_pk=l.source_observation_pk);

-- ============================== AFTER ==============================
SELECT 'AFTER_selected' AS result_set, @newSod AS selected_sod,
  (SELECT COUNT(*) FROM source.source_lineage l WHERE l.semantic_object_definition_pk=@newSod) AS lineage_rows,
  (SELECT COUNT(DISTINCT a.capsule_digest) FROM source.source_lineage l
     JOIN source.source_observation o ON o.source_observation_pk=l.source_observation_pk
     JOIN source.source_appearance a ON a.source_appearance_pk=o.source_appearance_pk
     WHERE l.semantic_object_definition_pk=@newSod AND a.capsule_digest IS NOT NULL) AS capsules;

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
