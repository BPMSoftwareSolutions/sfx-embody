-- Point the SDA loader provider at its invocation-shaped entry so a capability can
-- select it as a provider.
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
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @providerId nvarchar(400)=N'sda-node-load-memory-scenario.loadMemoryScenario';
DECLARE @sem nvarchar(max), @object bigint, @definition bigint, @digest binary(32), @prov bigint;
SELECT @sem=JSON_QUERY(definition_json,'$.semantics') FROM analysis.v_selected_semantic_definition
 WHERE estate_model_pk=@estate AND object_kind='PROVIDER' AND declared_id=@providerId COLLATE Latin1_General_100_BIN2;
IF @sem IS NULL THROW 51000,'SDA_LOADER_PROVIDER_NOT_DECLARED',1;
SET @sem=JSON_MODIFY(@sem,'$.export',N'loadMemoryScenarioForInvocation');
EXEC model.put_semantic_definition 'PROVIDER',N'sidefx:providers',@providerId,@sem,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
SET @prov=(SELECT pd.provider_pk FROM model.provider_definition pd JOIN model.provider p ON p.provider_pk=pd.provider_pk
 WHERE pd.semantic_object_definition_pk=(SELECT MAX(x.semantic_object_definition_pk) FROM model.provider_definition x
   JOIN model.provider p2 ON p2.provider_pk=x.provider_pk WHERE p2.provider_id=@providerId));
IF NOT EXISTS (SELECT 1 FROM model.provider_definition WHERE provider_pk=@prov AND semantic_object_definition_pk=@definition)
 INSERT model.provider_definition(provider_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,declaration_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@prov,@object,@definition,@digest,@providerId,'sda-estate-provider-implementation.v1','PROVIDER',@definition,N'');
SELECT 'sda_loader_provider' AS result_set, @providerId AS provider_id,
 JSON_VALUE(@sem,'$.module') AS module, JSON_VALUE(@sem,'$.export') AS export;
COMMIT TRANSACTION;
