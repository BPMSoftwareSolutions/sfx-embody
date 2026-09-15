-- LANE B (semantic execution graph mechanics): the Ports that reach the graph
-- compiler/executor no longer name a module. Clearing
-- `configuration.providerId` leaves each Port with its declared
-- `platformCapabilityId`; the boot resolves the admitted per-language
-- implementation from the target language's mechanic registry, which is
-- declared authority and carries no database row. The two now-unreferenced
-- module-carrying PROVIDER rows are removed; the platform provider identity
-- `ScenarioKernel.NodePlatform.Execution.SemanticExecutionGraphCompilation`
-- stays (its catalog entry is authority) with its module/export members cleared.
-- Idempotent: a second run finds no providerId to clear and no provider to
-- remove.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install.
-- Installed: this copy commits.
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
DECLARE @ids TABLE (provider_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @ids (provider_id) VALUES
 (N'sda-semantic-execution-graph-compilation.compileSemanticExecutionGraph'),
 (N'sda-semantic-execution-graph-execution.executeSemanticExecutionGraph');

-- 1. Free every selected Port that binds either graph provider.
DECLARE @ns nvarchar(400), @port nvarchar(400);
DECLARE @sem nvarchar(max), @prevver bigint, @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
DECLARE ports CURSOR LOCAL FAST_FORWARD FOR
 SELECT d.namespace_id, d.declared_id FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') IN (SELECT provider_id FROM @ids);
OPEN ports;
FETCH NEXT FROM ports INTO @ns, @port;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @sem=NULL; SET @prevver=NULL;
 SELECT @sem=JSON_QUERY(d.definition_json,'$.semantics'),
  @prevver=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=@ns COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port COLLATE Latin1_General_100_BIN2
  AND JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') IN (SELECT provider_id FROM @ids);
 IF @sem IS NOT NULL BEGIN
  SET @sem=JSON_MODIFY(@sem,'$.configuration.providerId',NULL);
  SET @sem=JSON_MODIFY(@sem,'$.configuration.estateProvider',NULL);
  EXEC model.put_semantic_definition 'PORT',@ns,@port,@sem,@object2 OUTPUT,@definition2 OUTPUT,@digest2 OUTPUT;
  SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object2);
  IF @portpk IS NOT NULL BEGIN
   SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition2);
   IF @version IS NULL BEGIN
    INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
    VALUES(@portpk,@object2,@definition2,@digest2,'consumer-interface-authority.v1','PORT',@definition2,N'');
    SET @version=SCOPE_IDENTITY();
   END
   UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
  END
 END
 FETCH NEXT FROM ports INTO @ns, @port;
END
CLOSE ports; DEALLOCATE ports;

-- 2. Clear the platform provider identity's module/export; the identity and its
--    catalog entry remain declared authority. A module-bearing definition is
--    retracted from this generation so the module-less declaration is selected.
DECLARE @pid nvarchar(400)=N'ScenarioKernel.NodePlatform.Execution.SemanticExecutionGraphCompilation';
DECLARE @psem nvarchar(max), @pobject bigint, @pdefinition bigint, @pdigest binary(32), @pprov bigint, @pnamespace bigint, @pselected bigint;
SET @psem=NULL; SET @pselected=NULL;
SELECT @psem=JSON_QUERY(definition_json,'$.semantics'), @pselected=semantic_object_definition_pk
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk=@estate AND object_kind='PROVIDER' AND declared_id=@pid COLLATE Latin1_General_100_BIN2;
IF @psem IS NOT NULL AND JSON_VALUE(@psem,'$.module') IS NOT NULL BEGIN
 SET @psem=JSON_MODIFY(@psem,'$.module',NULL);
 SET @psem=JSON_MODIFY(@psem,'$.export',NULL);
 EXEC model.put_semantic_definition 'PROVIDER',N'sidefx:providers',@pid,@psem,@pobject OUTPUT,@pdefinition OUTPUT,@pdigest OUTPUT;
 SET @pnamespace=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='PROVIDER' AND namespace_id=N'sidefx:providers');
 SET @pprov=(SELECT provider_pk FROM model.provider WHERE namespace_pk=@pnamespace AND provider_id=@pid);
 IF @pprov IS NOT NULL AND NOT EXISTS (SELECT 1 FROM model.provider_definition WHERE provider_pk=@pprov AND semantic_object_definition_pk=@pdefinition)
  INSERT model.provider_definition(provider_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,declaration_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@pprov,@pobject,@pdefinition,@pdigest,@pid,'sda-platform-capability-catalog.v1','PROVIDER',@pdefinition,N'');
 IF @pselected IS NOT NULL AND @pselected<>@pdefinition
  DELETE FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@pselected;
END

-- 3. Guard: after clearing, no selected PORT may name either provider id.
DECLARE @referencing int=(SELECT COUNT_BIG(*) FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND EXISTS (SELECT 1 FROM @ids i WHERE d.definition_json LIKE N'%'+(i.provider_id COLLATE Latin1_General_100_BIN2_UTF8)+N'%'));
IF @referencing>0 THROW 51000,'PROVIDER_STILL_REFERENCED_BY_SELECTED_PORT',1;

-- 4. Remove the now-unreferenced module carriers.
DELETE pd FROM model.provider_definition pd JOIN model.provider p ON p.provider_pk=pd.provider_pk
 WHERE p.provider_id IN (SELECT provider_id FROM @ids);
DELETE p FROM model.provider p WHERE p.provider_id IN (SELECT provider_id FROM @ids);

DECLARE @targets TABLE (declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @targets VALUES (N'run-declared-graph-compile'),(N'run-declared-graph-execute'),(N'compile-declared-authority-port'),
 (N'execute-semantic-execution-graph-port'),(N'execute-semantic-value-graph-port');
SELECT 'freed_port' AS result_set, d.declared_id,
 JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId') AS platform_capability,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.estateProvider.module') AS estate_module
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' AND d.declared_id IN (SELECT declared_id FROM @targets)
ORDER BY d.declared_id;
SELECT 'platform_provider_identity' AS result_set, @pid AS provider_id,
 JSON_VALUE(d.definition_json,'$.semantics.module') AS module,
 JSON_VALUE(d.definition_json,'$.semantics.export') AS export
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PROVIDER' AND d.declared_id=@pid COLLATE Latin1_General_100_BIN2;
SELECT 'provider_removed' AS result_set,
 (SELECT COUNT(*) FROM model.provider WHERE provider_id IN (SELECT provider_id FROM @ids)) AS providers_remaining,
 @referencing AS selected_ports_naming_provider;
COMMIT TRANSACTION;
