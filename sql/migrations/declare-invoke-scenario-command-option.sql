-- Declares scenario selection on the command surface's invoke operation by re-declaring the
-- sda-kernel-command-operations.v1 authority body with $.operations.invoke.scenario = true.
-- The body is materialized in source.content_object; the selected definition is MAX(pk) among
-- model.estate_definition links; model.put_semantic_definition appends the new locator.
-- Preflight: ends with ROLLBACK. Commit twin: declare-invoke-scenario-command-option.commit.sql.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM source.current_model WHERE singleton_id=1)
 THROW 51000,'CURRENT_MODEL_NOT_DECLARED',1;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @authority_id nvarchar(400)=N'sda-kernel-command-operations.v1';
DECLARE @wrapper nvarchar(max), @body nvarchar(max), @current_digest nvarchar(80);
SELECT TOP 1 @wrapper=CONVERT(nvarchar(max),CONVERT(varchar(max),wp.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.semantic_object so
JOIN model.semantic_object_definition sod ON sod.semantic_object_pk=so.semantic_object_pk
JOIN source.content_object wp ON wp.content_object_pk=sod.canonical_content_pk
WHERE so.declared_id=@authority_id AND so.object_kind='AUTHORITY'
 AND sod.semantic_object_definition_pk=(
  SELECT MAX(sod2.semantic_object_definition_pk)
  FROM model.estate_definition ed2
  JOIN model.semantic_object_definition sod2 ON sod2.semantic_object_definition_pk=ed2.semantic_object_definition_pk
  WHERE ed2.estate_model_pk=@estate AND sod2.semantic_object_pk=so.semantic_object_pk);
IF @wrapper IS NULL THROW 51000,'COMMAND_OPERATIONS_AUTHORITY_NOT_SELECTED',1;
SET @current_digest=JSON_VALUE(@wrapper,'$.semantics.contentDigest');
SELECT @body=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM source.content_object co
WHERE co.content_digest=CONVERT(binary(32),REPLACE(@current_digest,'sha256:',''),2);
IF @body IS NULL THROW 51000,'COMMAND_OPERATIONS_BODY_NOT_RESOLVED',1;
IF ISNULL(JSON_VALUE(@body,'$.operations.invoke.scenario'),N'false')<>N'true'
BEGIN
 SET @body=JSON_MODIFY(@body,'$.operations.invoke.scenario',CAST(1 AS bit));
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@body COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @body_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@body_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@body_digest,@bytes,DATALENGTH(@bytes));
 IF EXISTS(SELECT 1 FROM source.content_object WHERE content_digest=@body_digest AND content_bytes<>@bytes)
  THROW 51000,'INVOKE_SCENARIO_AUTHORITY_CONTENT_DIVERGED',1;
 DECLARE @semantics nvarchar(max)=N'{"authorityId":"sda-kernel-command-operations.v1","contentDigest":"sha256:'
  +LOWER(CONVERT(varchar(64),@body_digest,2))
  +N'","sourcePath":"kernel/semantic-authority/consumer/sda-kernel-command-operations.authority.v1.json","locators":["../scenario-driven-architecture/kernel/semantic-authority/consumer/sda-kernel-command-operations.authority.v1.json"]}';
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition @kind='AUTHORITY',@namespace=N'sidefx:authorities',
  @id=@authority_id,@semantics=@semantics,
  @object=@object OUTPUT,@definition=@definition OUTPUT,@digest=@digest OUTPUT;
 SELECT 'invoke_scenario_declared' AS action,@object AS object_pk,@definition AS definition_pk,
  @current_digest AS previous_content_digest,
  'sha256:'+LOWER(CONVERT(varchar(64),@body_digest,2)) AS content_digest,
  'sha256:'+LOWER(CONVERT(varchar(64),@digest,2)) AS wrapper_digest;
END
ELSE SELECT 'invoke_scenario_already_declared' AS action,@current_digest AS content_digest;
GO
SELECT 'command_operations_invoke_scenario' AS result_set, so.declared_id,
 JSON_VALUE(wrapper.text,'$.semantics.contentDigest') AS content_digest,
 body.byte_length,
 JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),body.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.operations.invoke.scenario') AS invoke_scenario,
 (SELECT COUNT(*) FROM OPENJSON(CONVERT(nvarchar(max),CONVERT(varchar(max),body.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.operations')) AS operation_count
FROM model.semantic_object so
CROSS APPLY (
 SELECT TOP 1 sod.semantic_object_definition_pk, sod.canonical_content_pk
 FROM model.estate_definition ed
 JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=ed.semantic_object_definition_pk
 WHERE ed.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
  AND sod.semantic_object_pk=so.semantic_object_pk
 ORDER BY sod.semantic_object_definition_pk DESC) sel
JOIN source.content_object wp ON wp.content_object_pk=sel.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),wp.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) wrapper
JOIN source.content_object body ON body.content_digest=CONVERT(binary(32),REPLACE(JSON_VALUE(wrapper.text,'$.semantics.contentDigest'),'sha256:',''),2)
WHERE so.declared_id=N'sda-kernel-command-operations.v1' AND so.object_kind='AUTHORITY';
ROLLBACK TRANSACTION;
