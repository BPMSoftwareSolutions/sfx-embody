-- Carry provider implementation relationships onto the current provider definition
-- after a provider declaration was replaced. Applies to the platform providers whose
-- semantic definition gained module/export.
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
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
DECLARE @providers TABLE (provider_id nvarchar(400));
INSERT @providers (provider_id) VALUES
 (N'ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission'),
 (N'ScenarioKernel.NodePlatform.Execution.SemanticExecutionGraphCompilation');
INSERT model.provider_capability_implementation(provider_definition_pk, capability_version_pk, role, _owner_definition_pk, _canonical_pointer)
SELECT cur.provider_definition_pk, oldi.capability_version_pk, oldi.role, cur.semantic_object_definition_pk, oldi._canonical_pointer
FROM @providers pr
JOIN model.provider p ON p.provider_id = pr.provider_id COLLATE Latin1_General_100_BIN2
JOIN model.provider_definition cur ON cur.provider_pk = p.provider_pk
JOIN model.provider_definition old ON old.provider_pk = p.provider_pk AND old.provider_definition_pk <> cur.provider_definition_pk
JOIN model.provider_capability_implementation oldi ON oldi.provider_definition_pk = old.provider_definition_pk
WHERE cur.provider_definition_pk = (SELECT MAX(pd.provider_definition_pk) FROM model.provider_definition pd WHERE pd.provider_pk = p.provider_pk)
  AND NOT EXISTS (SELECT 1 FROM model.provider_capability_implementation x
    WHERE x.provider_definition_pk = cur.provider_definition_pk AND x.capability_version_pk = oldi.capability_version_pk);
SELECT 'provider_capability_implementation' AS result_set, pr.provider_id, COUNT_BIG(*) AS implementations
FROM @providers pr
JOIN model.provider p ON p.provider_id = pr.provider_id COLLATE Latin1_General_100_BIN2
JOIN model.provider_definition cur ON cur.provider_pk = p.provider_pk
JOIN model.provider_capability_implementation i ON i.provider_definition_pk = cur.provider_definition_pk
WHERE cur.provider_definition_pk = (SELECT MAX(pd.provider_definition_pk) FROM model.provider_definition pd WHERE pd.provider_pk = p.provider_pk)
GROUP BY pr.provider_id;
COMMIT TRANSACTION;
