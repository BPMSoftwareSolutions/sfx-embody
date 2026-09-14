-- Declare the platform implementations' entry export in the provider rows so the
-- estate executor resolves configuration.estateProvider from the platform provider
-- (module + export), not from a deleted estate module.
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
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @updates TABLE (provider_id nvarchar(400), module nvarchar(400), export nvarchar(400));
INSERT @updates (provider_id, module, export) VALUES
 (N'ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission', N'languages/typescript/runtimes/node/schema-contract-admission-provider.mjs', N'createSynchronousSchemaAdmission'),
 (N'ScenarioKernel.NodePlatform.Execution.SemanticExecutionGraphCompilation', N'languages/typescript/runtimes/node/semantic-execution-graph-compilation-provider.mjs', N'compileSemanticExecutionGraph');
DECLARE @pid nvarchar(400), @module nvarchar(400), @export nvarchar(400);
DECLARE @sem nvarchar(max), @object bigint, @definition bigint, @digest binary(32), @prov bigint, @namespace bigint;
DECLARE providers CURSOR LOCAL FAST_FORWARD FOR SELECT provider_id, module, export FROM @updates;
OPEN providers;
FETCH NEXT FROM providers INTO @pid, @module, @export;
WHILE @@FETCH_STATUS=0 BEGIN
 SELECT @sem=JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate AND object_kind='PROVIDER' AND declared_id=@pid COLLATE Latin1_General_100_BIN2;
 IF @sem IS NULL THROW 51000,'PLATFORM_PROVIDER_NOT_DECLARED',1;
 SET @sem=JSON_MODIFY(@sem,'$.module',@module);
 SET @sem=JSON_MODIFY(@sem,'$.export',@export);
 EXEC model.put_semantic_definition 'PROVIDER',N'sidefx:providers',@pid,@sem,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SET @namespace=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='PROVIDER' AND namespace_id=N'sidefx:providers');
 SET @prov=(SELECT provider_pk FROM model.provider WHERE namespace_pk=@namespace AND provider_id=@pid);
 IF @prov IS NULL THROW 51000,'PLATFORM_PROVIDER_ROW_MISSING',1;
 IF NOT EXISTS (SELECT 1 FROM model.provider_definition WHERE provider_pk=@prov AND semantic_object_definition_pk=@definition)
  INSERT model.provider_definition(provider_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,declaration_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@prov,@object,@definition,@digest,@pid,'sda-platform-capability-catalog.v1','PROVIDER',@definition,N'');
 FETCH NEXT FROM providers INTO @pid, @module, @export;
END
CLOSE providers;
DEALLOCATE providers;
SELECT 'platform_provider_entries' AS result_set, u.provider_id,
 JSON_VALUE(d.definition_json,'$.semantics.module') AS module, JSON_VALUE(d.definition_json,'$.semantics.export') AS export
FROM @updates u
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@estate AND d.object_kind='PROVIDER' AND d.declared_id=u.provider_id COLLATE Latin1_General_100_BIN2;
COMMIT TRANSACTION;
