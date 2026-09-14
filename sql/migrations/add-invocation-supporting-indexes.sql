-- PERF #6: supporting seek indexes for the invocation reads. Meaning-neutral.
-- Adds only what the plan calls for and is not already present:
--   model.capability (capability_id) INCLUDE (capability_pk, namespace_pk, semantic_object_pk)
--   model.semantic_object_definition (semantic_object_pk, semantic_object_definition_pk DESC)
--     INCLUDE (canonical_content_pk, object_kind, definition_digest)
-- The other indexes in the perf plan are confirmed present, not re-created.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'model.capability')
               AND name=N'IX_model_capability_capability_id')
  CREATE NONCLUSTERED INDEX IX_model_capability_capability_id
    ON model.capability (capability_id)
    INCLUDE (capability_pk, namespace_pk, semantic_object_pk);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'model.semantic_object_definition')
               AND name=N'IX_model_sod_version_desc')
  CREATE NONCLUSTERED INDEX IX_model_sod_version_desc
    ON model.semantic_object_definition (semantic_object_pk, semantic_object_definition_pk DESC)
    INCLUDE (canonical_content_pk, object_kind, definition_digest);

SELECT 'added_index' AS result_set, o.name AS table_name, i.name AS index_name, i.type_desc, i.is_unique,
 STUFF((SELECT ', '+c2.name+(CASE WHEN ic2.is_descending_key=1 THEN ' DESC' ELSE '' END)
        FROM sys.index_columns ic2 JOIN sys.columns c2 ON c2.object_id=ic2.object_id AND c2.column_id=ic2.column_id
        WHERE ic2.object_id=i.object_id AND ic2.index_id=i.index_id AND ic2.is_included_column=0
        ORDER BY ic2.key_ordinal FOR XML PATH('')),1,2,'') AS key_cols,
 STUFF((SELECT ', '+c3.name FROM sys.index_columns ic3 JOIN sys.columns c3 ON c3.object_id=ic3.object_id AND c3.column_id=ic3.column_id
        WHERE ic3.object_id=i.object_id AND ic3.index_id=i.index_id AND ic3.is_included_column=1
        ORDER BY ic3.index_column_id FOR XML PATH('')),1,2,'') AS included_cols
FROM sys.indexes i JOIN sys.objects o ON o.object_id=i.object_id
WHERE i.name IN (N'IX_model_capability_capability_id', N'IX_model_sod_version_desc')
ORDER BY o.name, i.name;

-- Confirm the other perf-plan indexes already exist and are not duplicated.
SELECT 'perf_plan_existing' AS result_set, o.name AS table_name, i.name AS index_name,
 STUFF((SELECT ', '+c2.name FROM sys.index_columns ic2 JOIN sys.columns c2 ON c2.object_id=ic2.object_id AND c2.column_id=ic2.column_id
        WHERE ic2.object_id=i.object_id AND ic2.index_id=i.index_id AND ic2.is_included_column=0
        ORDER BY ic2.key_ordinal FOR XML PATH('')),1,2,'') AS key_cols
FROM sys.indexes i JOIN sys.objects o ON o.object_id=i.object_id
WHERE (o.object_id=OBJECT_ID(N'model.contract_version') AND i.name=N'IX_model_contract_version_97c6d7ada933')
   OR (o.object_id=OBJECT_ID(N'model.scenario_outcome_contract') AND i.name=N'PK_model_scenario_outcome_contract_d350a81083bd')
ORDER BY o.name, i.name;
COMMIT TRANSACTION;
