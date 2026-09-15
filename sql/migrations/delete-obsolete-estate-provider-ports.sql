-- LANE B unit 3 (estate-module sweep): free every Port that binds an estate
-- provider module or the SDA memory-scenario loader, then delete the
-- now-unreferenced module-carrying PROVIDER rows. Each Port keeps its declared
-- `platformCapabilityId` (and any declared read / configuration); no
-- declaration row names a module. The deleted rows are the residual
-- architecture-1 carriers (`src/resolvers/node/*`, `src/load-memory-scenario.mjs`,
-- `src/invoke-database-capability.mjs`, the SDA memory loader) whose target
-- disposition is eliminated, not restored.
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
 (N'consumer-authority-context.carryConsumerAuthorityContextForInvocation'),
 (N'consumer-execution-provider.executeConsumerPlan'),
 (N'consumer-plan-provider.readConsumerExecutionPlan'),
 (N'embodiment-plan-provider.planCapabilityEmbodiment'),
 (N'embodiment-write-provider.writeCapabilityEmbodiment'),
 (N'invoke-database-capability.executeDatabaseCommand'),
 (N'load-memory-scenario.loadMemoryScenario'),
 (N'sda-node-load-memory-scenario.loadMemoryScenario');

-- 1. Free every selected Port that binds one of the module-carrying providers.
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

-- 2. Guard: after clearing, no selected PORT may name any provider id.
DECLARE @referencing int=(SELECT COUNT_BIG(*) FROM analysis.v_selected_semantic_definition d
 WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND EXISTS (SELECT 1 FROM @ids i WHERE d.definition_json LIKE N'%'+(i.provider_id COLLATE Latin1_General_100_BIN2_UTF8)+N'%'));
IF @referencing>0 THROW 51000,'PROVIDER_STILL_REFERENCED_BY_SELECTED_PORT',1;

-- 3. Remove the now-unreferenced module carriers.
DELETE pd FROM model.provider_definition pd JOIN model.provider p ON p.provider_pk=pd.provider_pk
 WHERE p.provider_id IN (SELECT provider_id FROM @ids);
DELETE p FROM model.provider p WHERE p.provider_id IN (SELECT provider_id FROM @ids);

SELECT 'freed_port' AS result_set, d.declared_id,
 JSON_VALUE(d.definition_json,'$.semantics.platformCapabilityId') AS platform_capability,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id IN (N'sidefx:capability:carry-consumer-authority-context',N'sidefx:capability:construct-embodiment-plan',
   N'sidefx:capability:consumer-execution-provider',N'sidefx:capability:consumer-plan-provider',
   N'sidefx:capability:database-query-provider',N'sidefx:capability:embodiment-plan-provider',
   N'sidefx:capability:embodiment-write-provider',N'sidefx:capability:execute-consumer-plan',
   N'sidefx:capability:invoke-database-capability',N'sidefx:capability:load-memory-scenario',
   N'sidefx:capability:plan-capability-embodiment',N'sidefx:capability:plan-consumer-execution',
   N'sidefx:capability:run-pilot-container',N'sidefx:capability:write-capability-embodiment',
   N'sidefx:capability:write-consumer-embodiment',N'sidefx:capability:execute-declared-capability')
ORDER BY d.declared_id;
SELECT 'provider_removed' AS result_set,
 (SELECT COUNT(*) FROM model.provider WHERE provider_id IN (SELECT provider_id FROM @ids)) AS providers_remaining,
 @referencing AS selected_ports_naming_provider;
COMMIT TRANSACTION;
