-- The per-target provider that implements each platform capability, as data.
-- One row per (platformCapabilityId, target, provider). A target with no provider
-- is absent, which is the held/not-conforming state — not an empty successful pick.
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
CREATE OR ALTER VIEW analysis.v_target_capability_provider AS
SELECT
  JSON_VALUE(pdv.definition_json, '$.semantics.capabilities[0].capabilityId') COLLATE Latin1_General_100_BIN2 AS platform_capability_id,
  JSON_VALUE(pdv.definition_json, '$.semantics.capabilities[0].projectionTarget') COLLATE Latin1_General_100_BIN2 AS target_id,
  p.provider_id COLLATE Latin1_General_100_BIN2 AS provider_id,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.module') AS provider_module,
  JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.export') AS provider_export,
  JSON_VALUE(pdv.definition_json, '$.semantics.capabilities[0].implementationRef') AS implementation_ref,
  pd.provider_definition_pk,
  pdv.semantic_object_definition_pk,
  ecp.capability_version_pk
FROM model.provider_capability_implementation i
JOIN model.provider_definition pd ON pd.provider_definition_pk = i.provider_definition_pk
JOIN model.provider p ON p.provider_pk = pd.provider_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = pd.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
JOIN analysis.v_selected_semantic_definition pdv ON pdv.semantic_object_definition_pk = pd.semantic_object_definition_pk
LEFT JOIN model.capability_version ecv ON ecv.capability_version_pk = i.capability_version_pk
LEFT JOIN model.estate_capability ecp ON ecp.capability_version_pk = i.capability_version_pk
WHERE pdv.estate_model_pk = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id = 1)
  AND JSON_VALUE(pdv.definition_json, '$.semantics.capabilities[0].capabilityId') IS NOT NULL;
GO
SELECT 'target_capability_provider' AS result_set, platform_capability_id, target_id, provider_id,
       COALESCE(provider_module, implementation_ref) AS module_path, provider_export
FROM analysis.v_target_capability_provider
WHERE platform_capability_id IN (N'sda-schema-contract-admission.v1', N'sda-semantic-execution-graph-compilation-port.v1')
ORDER BY platform_capability_id, target_id;
COMMIT TRANSACTION;
