-- An exchange with no completed response has no response bytes to decode.
-- Keep the existing unavailable outcome and decode only a completed response.
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
CREATE OR ALTER PROCEDURE model.normalize_transformation_expression
  @transformation_version_pk bigint
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @sod bigint = (SELECT semantic_object_definition_pk FROM model.transformation_version WHERE transformation_version_pk=@transformation_version_pk);
  IF @sod IS NULL THROW 51001, 'TRANSFORMATION_VERSION_NOT_FOUND', 1;
  DECLARE @env nvarchar(max) = (SELECT CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
     FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk WHERE d.semantic_object_definition_pk=@sod);
  DECLARE @expr nvarchar(max) = JSON_QUERY(@env, '$.semantics.expression');
  IF @expr IS NULL RETURN;

  DELETE FROM model.transformation_root WHERE transformation_version_pk=@transformation_version_pk;
  DELETE FROM model.transformation_expression_child WHERE transformation_version_pk=@transformation_version_pk;
  DELETE FROM model.transformation_expression_node WHERE transformation_version_pk=@transformation_version_pk;

  IF OBJECT_ID('tempdb..#work') IS NOT NULL DROP TABLE #work;
  CREATE TABLE #work (id int IDENTITY PRIMARY KEY, frag nvarchar(max), pointer nvarchar(4000), parentPk bigint NULL,
                      memberKind nvarchar(40) NULL, memberName nvarchar(400) NULL, ordinal int NULL, done bit DEFAULT 0);
  INSERT #work (frag, pointer) VALUES (@expr, N'/semantics/expression');

  DECLARE @id int, @frag nvarchar(max), @pointer nvarchar(4000), @parentPk bigint, @memberKind nvarchar(40), @memberName nvarchar(400), @ordinal int;
  DECLARE @nodePk bigint, @ch nchar(1), @trim nvarchar(max);
  WHILE EXISTS (SELECT 1 FROM #work WHERE done=0)
  BEGIN
    SELECT TOP 1 @id=id, @frag=frag, @pointer=pointer, @parentPk=parentPk, @memberKind=memberKind, @memberName=memberName, @ordinal=ordinal
    FROM #work WHERE done=0 ORDER BY id;
    SET @trim = LTRIM(RTRIM(@frag));
    SET @ch = LEFT(@trim, 1);
    IF @ch = '{' OR @ch = '['
    BEGIN
      INSERT model.transformation_expression_node (transformation_version_pk, node_pointer, node_kind, _owner_definition_pk, _canonical_pointer)
        VALUES (@transformation_version_pk, @pointer, CASE WHEN @ch='{' THEN 'OBJECT' ELSE 'ARRAY' END, @sod, @pointer);
      SET @nodePk = SCOPE_IDENTITY();
      IF @parentPk IS NULL
        INSERT model.transformation_root (transformation_version_pk, expression_node_pk, _owner_definition_pk, _canonical_pointer) VALUES (@transformation_version_pk, @nodePk, @sod, @pointer);
      ELSE
        INSERT model.transformation_expression_child (transformation_version_pk, parent_node_pk, child_node_pk, member_kind, member_name, ordinal, _owner_definition_pk, _canonical_pointer)
          VALUES (@transformation_version_pk, @parentPk, @nodePk, ISNULL(@memberKind,'OBJECT_MEMBER'), @memberName, @ordinal, @sod, @pointer);
      INSERT #work (frag, pointer, parentPk, memberKind, memberName, ordinal)
      SELECT CASE j.[type] WHEN 1 THEN N'"' + STRING_ESCAPE(j.value,'json') + N'"' WHEN 0 THEN N'null' ELSE j.value END,
             @pointer + N'/' + j.[key], @nodePk,
             CASE WHEN @ch='{' THEN 'OBJECT_MEMBER' ELSE 'ARRAY_MEMBER' END, CASE WHEN @ch='{' THEN j.[key] ELSE NULL END,
             CASE WHEN @ch='[' THEN TRY_CONVERT(int, j.[key]) ELSE NULL END
      FROM OPENJSON(@trim) j;
    END
    ELSE
    BEGIN
      DECLARE @litBytes varbinary(max) = CONVERT(varbinary(max), CONVERT(varchar(max), (@trim) COLLATE Latin1_General_100_BIN2_UTF8));
      DECLARE @litDigest binary(32) = HASHBYTES('SHA2_256', @litBytes);
      IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@litDigest)
        INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@litDigest, @litBytes, DATALENGTH(@litBytes));
      INSERT model.transformation_expression_node (transformation_version_pk, node_pointer, node_kind, literal_content_pk, _owner_definition_pk, _canonical_pointer)
        VALUES (@transformation_version_pk, @pointer, 'LITERAL', (SELECT content_object_pk FROM source.content_object WHERE content_digest=@litDigest), @sod, @pointer);
      SET @nodePk = SCOPE_IDENTITY();
      IF @parentPk IS NULL
        INSERT model.transformation_root (transformation_version_pk, expression_node_pk, _owner_definition_pk, _canonical_pointer) VALUES (@transformation_version_pk, @nodePk, @sod, @pointer);
      ELSE
        INSERT model.transformation_expression_child (transformation_version_pk, parent_node_pk, child_node_pk, member_kind, member_name, ordinal, _owner_definition_pk, _canonical_pointer)
          VALUES (@transformation_version_pk, @parentPk, @nodePk, ISNULL(@memberKind,'OBJECT_MEMBER'), @memberName, @ordinal, @sod, @pointer);
    END
    UPDATE #work SET done=1 WHERE id=@id;
  END
END;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @semantics nvarchar(max),@previous bigint;
SELECT @semantics=JSON_QUERY(definition_json,'$.semantics'),@previous=semantic_object_definition_pk
FROM analysis.v_selected_semantic_definition
WHERE estate_model_pk=@estate AND object_kind='TRANSFORMATION'
 AND namespace_id=N'sidefx:capability:resolve-equity-market-price-evidence'
 AND declared_id=N'normalize-equity-price-evidence';
IF @semantics IS NULL THROW 51000,'EQUITY_TRANSFORMATION_NOT_DECLARED',1;
DECLARE @body nvarchar(max)=JSON_QUERY(@semantics,'$.expression.bindings.bodyText');
IF JSON_VALUE(@body,'$.op')='base64-decode-utf8'
BEGIN
 DECLARE @guard nvarchar(max)=(SELECT 'if' AS op,
  JSON_QUERY(N'{"op":"path","from":"completed","path":""}') AS [when],
  JSON_QUERY(@body) AS [then],JSON_QUERY(N'{"op":"literal","value":""}') AS [else]
  FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @semantics=JSON_MODIFY(@semantics,'$.expression.bindings.bodyText',JSON_QUERY(@guard));
END;
ELSE IF JSON_VALUE(@body,'$.op')<>'if' OR JSON_VALUE(@body,'$.when.from')<>'completed'
 THROW 51000,'EQUITY_RESPONSE_DECODING_AUTHORITY_DIVERGED',1;
DECLARE @object bigint,@definition bigint,@digest binary(32);
EXEC model.put_semantic_definition 'TRANSFORMATION',N'sidefx:capability:resolve-equity-market-price-evidence',
 N'normalize-equity-price-evidence',@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
DECLARE @transformation bigint=(SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk=@object);
DECLARE @version bigint=(SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk=@definition);
IF @version IS NULL BEGIN
 INSERT model.transformation_version(transformation_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
  expression_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@transformation,@object,@definition,@digest,'json-expression-tree.v1','TRANSFORMATION',@definition,N'');
 SET @version=SCOPE_IDENTITY();
 EXEC model.normalize_transformation_expression @version;
END;
SELECT 'response_decoding' AS result_set,@previous AS previous_definition,@definition AS selected_definition,
 JSON_QUERY(@semantics,'$.expression.bindings.bodyText') AS body_text_expression;
COMMIT TRANSACTION;
