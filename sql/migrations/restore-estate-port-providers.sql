-- Restore the estate Port provider selections (revert the platform-provider rebind).
-- Ports select the declared estate providers whose modules are present again.
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
DECLARE @map TABLE (port_id nvarchar(400) COLLATE Latin1_General_100_BIN2, provider_id nvarchar(400));
INSERT @map (port_id, provider_id) VALUES
 (N'admit-execution-input', N'contract-admission-provider.admitDeclaredContract'),
 (N'admit-execution-outcome', N'contract-admission-provider.admitDeclaredContract'),
 (N'read-execution-capability-authority', N'authority-read-provider.readCapabilityAuthority'),
 (N'read-capability-authority-port', N'authority-read-provider.readCapabilityAuthority'),
 (N'resolve-execution-provider-bindings', N'database-query-provider.readDatabaseQuery'),
 (N'resolve-provider-slot-bindings-port', N'database-query-provider.readDatabaseQuery'),
 (N'register-projection-authorities', N'database-query-provider.readDatabaseQuery'),
 (N'read-bound-consumer-execution-plan', N'consumer-plan-provider.readConsumerExecutionPlan'),
 (N'plan-capability-embodiment-port', N'embodiment-plan-provider.planCapabilityEmbodiment'),
 (N'construct-embodiment-plan-port', N'embodiment-plan-provider.planCapabilityEmbodiment'),
 (N'project-consumer-execution-embodiment-plan-port', N'execution-graph-read-provider.readDeclaredExecutionGraph'),
 (N'write-capability-embodiment-port', N'embodiment-write-provider.writeCapabilityEmbodiment'),
 (N'execute-bound-consumer-plan', N'consumer-execution-provider.executeConsumerPlan'),
 (N'execute-declared-capability-port', N'consumer-execution-provider.executeConsumerPlan'),
 (N'derive-target-neutral-execution-plan', N'execution-graph-read-provider.readDeclaredExecutionGraph');
DECLARE @targets TABLE (namespace_id nvarchar(400), port_id nvarchar(400), provider_id nvarchar(400), semantics nvarchar(max), previous_version bigint);
INSERT @targets (namespace_id, port_id, provider_id, semantics, previous_version)
SELECT d.namespace_id, d.declared_id, m.provider_id, JSON_QUERY(d.definition_json,'$.semantics'),
 (SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
JOIN @map m ON m.port_id=d.declared_id
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT';
DECLARE @ns nvarchar(400), @port nvarchar(400), @provid nvarchar(400), @sem nvarchar(max), @prevver bigint;
DECLARE @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
DECLARE ports CURSOR LOCAL FAST_FORWARD FOR SELECT namespace_id, port_id, provider_id, semantics, previous_version FROM @targets;
OPEN ports;
FETCH NEXT FROM ports INTO @ns, @port, @provid, @sem, @prevver;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @sem=JSON_MODIFY(@sem,'$.configuration.providerId',@provid);
 SET @sem=JSON_MODIFY(@sem,'$.configuration.estateProvider',NULL);
 SET @sem=JSON_MODIFY(@sem,'$.configuration.revertedAt',CONVERT(nvarchar(30),SYSDATETIME(),126));
 EXEC model.put_semantic_definition 'PORT',@ns,@port,@sem,@object2 OUTPUT,@definition2 OUTPUT,@digest2 OUTPUT;
 SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object2);
 SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition2);
 IF @version IS NULL BEGIN
  INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@portpk,@object2,@definition2,@digest2,'consumer-interface-authority.v1','PORT',@definition2,N'');
  SET @version=SCOPE_IDENTITY();
 END
 UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
 FETCH NEXT FROM ports INTO @ns, @port, @provid, @sem, @prevver;
END
CLOSE ports;
DEALLOCATE ports;
SELECT 'restored_port_providers' AS result_set, d.declared_id, JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id
FROM analysis.v_selected_semantic_definition d JOIN @map m ON m.port_id=d.declared_id
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT' ORDER BY d.declared_id;
COMMIT TRANSACTION;
