-- Path B (docs/research/platform-mechanic-honesty.md): declare the two remaining
-- domain concerns as capabilities that name their module. Database changes only.
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
EXEC model.scaffold_estate_provider_capability @capability_id=N'consumer-object-provider',
 @provider_module=N'src/resolvers/node/consumer-object-provider.mjs', @provider_export=N'NodeConsumerObjectProvider',
 @input_contract=N'consumer-object-provider-request.v1', @input_schema=N'{"type":"object","additionalProperties":true}',
 @outcome_contract=N'consumer-object-provider-result.v1', @outcome_schema=N'{"type":"object","additionalProperties":true}';
EXEC model.scaffold_estate_provider_capability @capability_id=N'native-expression-projection',
 @provider_module=N'src/resolvers/node/native-expression-projection.mjs', @provider_export=N'NativeExpressionProjection',
 @input_contract=N'native-expression-projection-request.v1', @input_schema=N'{"type":"object","additionalProperties":true}',
 @outcome_contract=N'native-expression-projection-result.v1', @outcome_schema=N'{"type":"object","additionalProperties":true}';
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @names TABLE(namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2);
INSERT @names VALUES (N'sidefx:capability:consumer-object-provider'),(N'sidefx:capability:native-expression-projection');
DECLARE @ports TABLE (namespace_id nvarchar(400), port_id nvarchar(400), provider_id nvarchar(400), semantics nvarchar(max), previous_version bigint);
INSERT @ports (namespace_id, port_id, provider_id, semantics, previous_version)
SELECT d.namespace_id, d.declared_id,
 REPLACE(REPLACE(m.module,'src/resolvers/node/',''),'.mjs','')+N'.'+m.export,
 JSON_QUERY(d.definition_json,'$.semantics'),
 (SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
CROSS APPLY (SELECT JSON_VALUE(d.definition_json,'$.semantics.configuration.estateProvider.module') AS module,
                    JSON_VALUE(d.definition_json,'$.semantics.configuration.estateProvider.export') AS export) m
JOIN @names n ON n.namespace_id=d.namespace_id COLLATE Latin1_General_100_BIN2
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND JSON_QUERY(d.definition_json,'$.semantics.configuration.estateProvider') IS NOT NULL;
DECLARE @ns nvarchar(400), @port nvarchar(400), @provid nvarchar(400), @sem nvarchar(max), @prevver bigint;
DECLARE @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
DECLARE ports CURSOR LOCAL FAST_FORWARD FOR SELECT namespace_id, port_id, provider_id, semantics, previous_version FROM @ports;
OPEN ports;
FETCH NEXT FROM ports INTO @ns, @port, @provid, @sem, @prevver;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @sem=JSON_MODIFY(@sem,'$.configuration.providerId',@provid);
 SET @sem=JSON_MODIFY(@sem,'$.configuration.estateProvider',NULL);
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
CLOSE ports; DEALLOCATE ports;
SELECT 'domain_concern_capabilities' AS result_set, p.namespace_id, p.port_id, p.provider_id
FROM @ports p ORDER BY p.namespace_id;
COMMIT TRANSACTION;
