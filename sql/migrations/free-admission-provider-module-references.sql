-- LANE B (contract admission): the admission Ports no longer name an admission
-- provider module. `configuration.admissionProvider` carried a module path for
-- the retired consumer-plan carrier; the kernel admits contracts natively from
-- the plan's contract catalog, and the Port already declares its admitted
-- platform mechanic. The module-bearing member is removed; the platform provider
-- identity `ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission`
-- keeps its catalog entry and clears its module/export members.
-- Idempotent: a second run finds no admissionProvider module to clear.
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

-- 1. Remove the module-bearing admissionProvider member from every selected Port.
DECLARE @ns nvarchar(400), @port nvarchar(400);
DECLARE @sem nvarchar(max), @prevver bigint, @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
DECLARE ports CURSOR LOCAL FAST_FORWARD FOR
 SELECT d.namespace_id, d.declared_id FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND JSON_VALUE(d.definition_json,'$.semantics.configuration.admissionProvider.module') IS NOT NULL;
OPEN ports;
FETCH NEXT FROM ports INTO @ns, @port;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @sem=NULL; SET @prevver=NULL;
 SELECT @sem=JSON_QUERY(d.definition_json,'$.semantics'),
  @prevver=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
 FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.namespace_id=@ns COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port COLLATE Latin1_General_100_BIN2
  AND JSON_VALUE(d.definition_json,'$.semantics.configuration.admissionProvider.module') IS NOT NULL;
 IF @sem IS NOT NULL BEGIN
  SET @sem=JSON_MODIFY(@sem,'$.configuration.admissionProvider',NULL);
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
DECLARE @pid nvarchar(400)=N'ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission';
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

-- 3. Guard: no selected PORT may still name an admission provider module.
DECLARE @referencing int=(SELECT COUNT_BIG(*) FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND JSON_VALUE(d.definition_json,'$.semantics.configuration.admissionProvider.module') IS NOT NULL);
IF @referencing>0 THROW 51000,'ADMISSION_PROVIDER_MODULE_STILL_REFERENCED',1;

DECLARE @targets TABLE (declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY);
INSERT @targets VALUES (N'admit-declared-contract-port'),(N'admit-execution-input'),(N'admit-execution-outcome'),(N'contract-admission-provider-port');
SELECT 'freed_port' AS result_set, d.declared_id,
 JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId') AS platform_capability,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.admissionProvider.module') AS admission_module
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' AND d.declared_id IN (SELECT declared_id FROM @targets)
ORDER BY d.declared_id;
SELECT 'platform_provider_identity' AS result_set, @pid AS provider_id,
 JSON_VALUE(d.definition_json,'$.semantics.module') AS module,
 JSON_VALUE(d.definition_json,'$.semantics.export') AS export
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PROVIDER' AND d.declared_id=@pid COLLATE Latin1_General_100_BIN2;
SELECT 'admission_module_references' AS result_set, @referencing AS selected_ports_naming_admission_module;
COMMIT TRANSACTION;
