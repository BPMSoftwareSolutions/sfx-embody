-- supersede-manage-capsule-estate.sql
--
-- Rubric decision (docs/sidefx-architecture-decision-rubric.md §7/§8):
-- `manage-capsule-estate` is a legacy front whose every command port delegates to
-- operate-capsule-estate (bindingRef ../../operate-capsule-estate/projected/
-- application-binding.node.json). operate-capsule-estate is the annotated
-- REVISION_V2 and the single canonical identity. No other feature references
-- manage-capsule-estate.
--
-- Supersede it by removing it from the current estate selection. The capability
-- and its definitions are retained as history; nothing is deleted.
--
-- Default: ROLLBACK after verification. Replace the final ROLLBACK with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;

BEGIN TRANSACTION;

DECLARE @model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capPk bigint=(SELECT capability_pk FROM model.capability WHERE capability_id=N'manage-capsule-estate');
IF @capPk IS NULL THROW 51001, 'MANAGE_CAPSULE_ESTATE_NOT_FOUND', 1;

DELETE ec FROM model.estate_capability ec WHERE ec.estate_model_pk=@model AND ec.capability_pk=@capPk;

SELECT '1_manage_in_estate' AS result_set, COUNT(*) AS n FROM model.estate_capability WHERE estate_model_pk=@model AND capability_pk=@capPk;
SELECT '2_operate_still_canonical' AS result_set, COUNT(*) AS n FROM model.estate_capability ec JOIN model.capability c ON c.capability_pk=ec.capability_pk WHERE ec.estate_model_pk=@model AND c.capability_id=N'operate-capsule-estate';
SELECT '3_estate_capability_count' AS result_set, COUNT(*) AS n FROM model.estate_capability WHERE estate_model_pk=@model;

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
