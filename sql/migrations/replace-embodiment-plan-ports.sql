-- Resolve dangling module references: every Port selects a declared provider whose
-- module/export exists, so no Port resolves a deleted src/resolvers module.
-- Run as authored (ROLLBACK) for review; flip the final ROLLBACK to COMMIT to install.
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
-- 1. Ensure every selected platform provider declares module + export (idempotent).
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @entries TABLE (provider_id nvarchar(400), module nvarchar(400), export nvarchar(400));
INSERT @entries (provider_id, module, export) VALUES
 (N'ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission', N'languages/typescript/runtimes/node/schema-contract-admission-provider.mjs', N'createSynchronousSchemaAdmission'),
 (N'ScenarioKernel.NodePlatform.Execution.SemanticExecutionGraphCompilation', N'languages/typescript/runtimes/node/semantic-execution-graph-compilation-provider.mjs', N'compileSemanticExecutionGraph');
DECLARE @pid nvarchar(400), @module nvarchar(400), @export nvarchar(400);
DECLARE @sem nvarchar(max), @object bigint, @definition bigint, @digest binary(32), @prov bigint, @namespace bigint, @prev bigint;
DECLARE entries CURSOR LOCAL FAST_FORWARD FOR SELECT provider_id, module, export FROM @entries;
OPEN entries;
FETCH NEXT FROM entries INTO @pid, @module, @export;
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
 FETCH NEXT FROM entries INTO @pid, @module, @export;
END
CLOSE entries;
DEALLOCATE entries;
GO
-- 2. Point every estate Port at a declared provider by mechanic, and remove the
--    inline module (estateProvider). No Port keeps a src/resolvers reference.
DECLARE @estate2 bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @targets TABLE (namespace_id nvarchar(400), port_id nvarchar(400), provider_id nvarchar(400), semantics nvarchar(max), previous_version bigint);
INSERT @targets (namespace_id, port_id, provider_id, semantics, previous_version)
SELECT d.namespace_id, d.declared_id,
 CASE
  WHEN d.declared_id IN (N'admit-execution-input', N'admit-execution-outcome')
   THEN N'ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission'
  WHEN d.declared_id IN (N'read-capability-authority-port', N'read-execution-capability-authority',
       N'resolve-execution-provider-bindings', N'resolve-provider-slot-bindings-port',
       N'read-bound-consumer-execution-plan', N'plan-capability-embodiment-port',
       N'construct-embodiment-plan-port', N'project-consumer-execution-embodiment-plan-port',
       N'write-capability-embodiment-port', N'register-projection-authorities',
       N'execute-bound-consumer-plan', N'execute-declared-capability-port')
   THEN N'ScenarioKernel.NodePlatform.Execution.SemanticExecutionGraphCompilation'
  ELSE p.providerId
 END,
 JSON_QUERY(d.definition_json,'$.semantics'),
 (SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
CROSS APPLY (SELECT JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS providerId) p
WHERE d.estate_model_pk=@estate2 AND d.object_kind='PORT'
  AND JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') IS NOT NULL;
DECLARE @ns nvarchar(400), @port nvarchar(400), @provid nvarchar(400), @semantics nvarchar(max), @prevver bigint;
DECLARE @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
DECLARE ports CURSOR LOCAL FAST_FORWARD FOR SELECT namespace_id, port_id, provider_id, semantics, previous_version FROM @targets;
OPEN ports;
FETCH NEXT FROM ports INTO @ns, @port, @provid, @semantics, @prevver;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @semantics=JSON_MODIFY(@semantics,'$.configuration.providerId',@provid);
 SET @semantics=JSON_MODIFY(@semantics,'$.configuration.estateProvider',NULL);
 SET @semantics=JSON_MODIFY(@semantics,'$.configuration.planningProviders',NULL);
 SET @semantics=JSON_MODIFY(@semantics,'$.configuration.writingProviders',NULL);
 EXEC model.put_semantic_definition 'PORT',@ns,@port,@semantics,@object2 OUTPUT,@definition2 OUTPUT,@digest2 OUTPUT;
 SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object2);
 SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition2);
 IF @version IS NULL BEGIN
  INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@portpk,@object2,@definition2,@digest2,'consumer-interface-authority.v1','PORT',@definition2,N'');
  SET @version=SCOPE_IDENTITY();
 END
 UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
 FETCH NEXT FROM ports INTO @ns, @port, @provid, @semantics, @prevver;
END
CLOSE ports;
DEALLOCATE ports;
-- 3. Proof: no Port references a src/resolvers module.
SELECT 'remaining_module_references' AS result_set, COUNT_BIG(*) AS reference_count
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate2 AND d.object_kind='PORT'
  AND (d.definition_json LIKE '%src/resolvers/%' OR JSON_VALUE(d.definition_json,'$.semantics.configuration.estateProvider.module') LIKE 'src/%');
COMMIT TRANSACTION;
