-- Free `execute-declared-capability` from the deleted resolver
-- `authority-read-provider.readCapabilityAuthority` on its first port. The Port is
-- re-declared as a declared data read over the estate's own view; no
-- configuration.providerId or estateProvider remains.
--
-- Default: ROLLBACK. Replace the final ROLLBACK with COMMIT to install.
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
DECLARE @ns nvarchar(400)=N'sidefx:capability:execute-declared-capability';
DECLARE @port nvarchar(400)=N'read-execution-capability-authority';
DECLARE @stmt nvarchar(max)=N'SELECT graph_source FROM analysis.v_capability_graph_source WHERE capability_id = CONVERT(nvarchar(400), JSON_VALUE(@input,''$.capabilityId''))';
DECLARE @sem nvarchar(max), @prevver bigint, @object2 bigint, @definition2 bigint, @digest2 binary(32), @portpk bigint, @version bigint;
SELECT @sem=JSON_QUERY(d.definition_json,'$.semantics'),
 @prevver=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@ns COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port COLLATE Latin1_General_100_BIN2
 AND JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') IS NOT NULL;
IF @sem IS NOT NULL BEGIN
 SET @sem=JSON_MODIFY(@sem,'$.configuration.providerId',NULL);
 SET @sem=JSON_MODIFY(@sem,'$.configuration.estateProvider',NULL);
 SET @sem=JSON_MODIFY(@sem,'$.configuration.expression',NULL);
 SET @sem=JSON_MODIFY(@sem,'$.configuration.statement',@stmt);
 SET @sem=JSON_MODIFY(@sem,'$.configuration.resultColumn',N'graph_source');
 EXEC model.put_semantic_definition 'PORT',@ns,@port,@sem,@object2 OUTPUT,@definition2 OUTPUT,@digest2 OUTPUT;
 SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object2);
 SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition2);
 IF @version IS NULL BEGIN
  INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@portpk,@object2,@definition2,@digest2,'consumer-interface-authority.v1','PORT',@definition2,N'');
  SET @version=SCOPE_IDENTITY();
 END
 UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
END
SELECT 'freed_port' AS result_set, d.declared_id,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.providerId') AS provider_id,
 JSON_QUERY(d.definition_json,'$.semantics.configuration.estateProvider') AS estate_provider,
 JSON_VALUE(d.definition_json,'$.semantics.configuration.resultColumn') AS result_column,
 LEN(JSON_VALUE(d.definition_json,'$.semantics.configuration.statement')) AS statement_len
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=@ns COLLATE Latin1_General_100_BIN2 AND d.declared_id=@port COLLATE Latin1_General_100_BIN2;
COMMIT TRANSACTION;
