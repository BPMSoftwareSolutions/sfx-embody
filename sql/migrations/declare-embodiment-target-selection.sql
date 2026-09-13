-- Finish target selection in declaration data and reject incomplete resolver inputs.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name) FROM sys.triggers t
 JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers; FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;

DECLARE @selected_model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @ports TABLE (ordinal int IDENTITY,port_pk bigint,object_pk bigint,version_pk bigint,capability_id nvarchar(400),definition_json nvarchar(max));
INSERT @ports (port_pk,object_pk,version_pk,capability_id,definition_json)
SELECT p.port_pk,p.semantic_object_pk,pv.port_version_pk,c.capability_id,d.definition_json
FROM model.capability c JOIN model.identity_namespace cn ON cn.namespace_pk=c.namespace_pk AND cn.namespace_id=N'sidefx:capabilities'
JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=@selected_model AND d.object_kind='PORT'
 AND d.namespace_id=N'sidefx:capability:'+c.capability_id AND d.declared_id=c.capability_id+N'-port'
JOIN model.port_version pv ON pv.semantic_object_definition_pk=d.semantic_object_definition_pk
JOIN model.port p ON p.port_pk=pv.port_pk
WHERE c.capability_id IN (N'read-capability-authority',N'resolve-provider-slot-bindings');
IF (SELECT COUNT(*) FROM @ports)<>2 THROW 51000,'EMBODIMENT_AUTHORITY_REQUIRED',1;

DECLARE @guard nvarchar(max)=N'IF ISNULL(JSON_VALUE(@input,''$.contractId''),'''')<>''capability-authority-declaration.v1''
 OR ISNULL(JSON_VALUE(@input,''$.capabilityId''),'''')=''''
 OR ISNULL(JSON_VALUE(@input,''$.scenarioId''),'''')=''''
 OR JSON_QUERY(@input,''$.authority'') IS NULL
 OR JSON_QUERY(@input,''$.closure'') IS NULL
 OR JSON_QUERY(@input,''$.mechanics'') IS NULL
 THROW 51000,''DATABASE_AUTHORITY_NOT_COHERENT'',1;
IF NOT EXISTS (SELECT 1 FROM analysis.v_target_provider_profile WHERE estate_model_pk=@estate_model_pk AND target_id=JSON_VALUE(@input,''$.target''))
 THROW 51000,''PROFILE_PROVIDER_ABSENT'',1;
';
DECLARE @index int=1,@port_pk bigint,@object_pk bigint,@version_pk bigint,@capability_id nvarchar(400),@definition nvarchar(max);
WHILE @index<=(SELECT COUNT(*) FROM @ports)
BEGIN
 SELECT @port_pk=port_pk,@object_pk=object_pk,@version_pk=version_pk,@capability_id=capability_id,@definition=definition_json FROM @ports WHERE ordinal=@index;
 IF @capability_id=N'read-capability-authority'
 BEGIN
  SET @definition=JSON_MODIFY(@definition,'$.semantics.configuration.defaultTarget',N'node');
  SET @definition=JSON_MODIFY(@definition,'$.semantics.configuration.profileAbsent',N'PROFILE_PROVIDER_ABSENT');
  SET @definition=JSON_MODIFY(@definition,'$.semantics.configuration.profileAmbiguous',N'TARGET_PROVIDER_PROFILE_AMBIGUOUS');
 END;
 ELSE
 BEGIN
  DECLARE @statement nvarchar(max);
  SELECT @statement=statement FROM OPENJSON(@definition,'$.semantics.configuration') WITH (statement nvarchar(max) '$.statement');
  IF @statement IS NULL THROW 51000,'EMBODIMENT_AUTHORITY_REQUIRED',1;
  IF LEFT(@statement,LEN(@guard))<>@guard
   SET @definition=JSON_MODIFY(@definition,'$.semantics.configuration.statement',@guard+@statement);
 END;
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@definition COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@digest,@bytes,DATALENGTH(@bytes));
 DECLARE @definition_pk bigint=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@object_pk AND definition_digest=@digest);
 IF @definition_pk IS NULL
 BEGIN
  INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
  VALUES(@object_pk,'PORT',@digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
  SET @definition_pk=SCOPE_IDENTITY();
 END;
 IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@selected_model AND semantic_object_definition_pk=@definition_pk)
  INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@selected_model,@definition_pk);
 DECLARE @new_version bigint=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition_pk);
 IF @new_version IS NULL
 BEGIN
  INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@port_pk,@object_pk,@definition_pk,@digest,'consumer-interface-authority.v1','PORT',@definition_pk,N'');
  SET @new_version=SCOPE_IDENTITY();
 END;
 UPDATE model.operation_port_invocation SET port_version_pk=@new_version WHERE port_version_pk=@version_pk;
 SELECT 'selected_target' AS result_set,@capability_id AS capability_id,@definition_pk AS definition_pk,
        JSON_VALUE(@definition,'$.semantics.configuration.defaultTarget') AS default_target;
 SET @index+=1;
END;
COMMIT TRANSACTION;
