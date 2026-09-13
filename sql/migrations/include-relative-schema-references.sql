-- Include the schema documents named by declared sibling-document references.
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
IF OBJECT_DEFINITION(OBJECT_ID('analysis.fn_contract_schema_closure')) LIKE '%@schema_base%' THROW 51000,'RELATIVE_SCHEMA_REFERENCES_ALREADY_DECLARED',1;
GO
-- Read schema documents named by absolute or sibling-document $ref values. Local fragment
-- references remain in their owning document. Repeated documents terminate the
-- traversal, including mutually recursive schema documents.
CREATE OR ALTER FUNCTION analysis.fn_contract_schema_closure(@content_pk bigint)
RETURNS @closure TABLE(schema_content_pk bigint PRIMARY KEY)
AS
BEGIN
 DECLARE @available TABLE(content_pk bigint, schema_id nvarchar(4000) COLLATE Latin1_General_100_BIN2);
 DECLARE @loaded bit=0;
 DECLARE @pending TABLE(content_pk bigint PRIMARY KEY,visited bit NOT NULL DEFAULT 0);
 INSERT @pending(content_pk) VALUES(@content_pk);
 WHILE EXISTS(SELECT 1 FROM @pending WHERE visited=0)
 BEGIN
  DECLARE @current bigint=(SELECT MIN(content_pk) FROM @pending WHERE visited=0),@document nvarchar(max),@schema_base nvarchar(4000);
  UPDATE @pending SET visited=1 WHERE content_pk=@current;
  INSERT @closure VALUES(@current);
  SELECT @document=CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM source.content_object WHERE content_object_pk=@current;
  SET @schema_base=JSON_VALUE(@document,'$."$id"');
  DECLARE @nodes TABLE(ordinal int IDENTITY,document nvarchar(max));
  DELETE @nodes;
  IF CHARINDEX('"$ref"',@document)>0 INSERT @nodes(document) VALUES(@document);
  WHILE EXISTS(SELECT 1 FROM @nodes)
  BEGIN
   DECLARE @ordinal int=(SELECT MIN(ordinal) FROM @nodes),@node nvarchar(max);
   SELECT @node=document FROM @nodes WHERE ordinal=@ordinal;
   DELETE @nodes WHERE ordinal=@ordinal;
   IF @loaded=0 AND EXISTS(SELECT 1 FROM OPENJSON(@node) WHERE [key]='$ref' AND type=1 AND value NOT LIKE '#%')
   BEGIN
    INSERT @available
    SELECT DISTINCT so.content_object_pk,JSON_VALUE(text.document,'$."$id"')
    FROM source.current_model cm
    JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=cm.estate_model_pk AND d.object_kind='CONTRACT'
    JOIN model.contract_version cv ON cv.semantic_object_definition_pk=d.semantic_object_definition_pk
    JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
    JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
    CROSS APPLY(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document) text;
    SET @loaded=1;
   END;
   INSERT @pending(content_pk)
   SELECT DISTINCT a.content_pk FROM OPENJSON(@node) member
   CROSS APPLY(SELECT LEFT(member.value,CHARINDEX('#',member.value+'#')-1) AS document_ref) reference
   JOIN @available a ON a.schema_id=CASE WHEN reference.document_ref LIKE '%://%' THEN reference.document_ref
    WHEN reference.document_ref<>'' AND reference.document_ref NOT LIKE '%/%'
     THEN LEFT(@schema_base,LEN(@schema_base)-CHARINDEX('/',REVERSE(@schema_base))+1)+reference.document_ref END COLLATE Latin1_General_100_BIN2
   WHERE member.[key]='$ref' AND member.type=1 AND member.value NOT LIKE '#%'
    AND NOT EXISTS(SELECT 1 FROM @pending p WHERE p.content_pk=a.content_pk);
   INSERT @nodes(document) SELECT value FROM OPENJSON(@node) WHERE type IN(4,5) AND CHARINDEX('"$ref"',value)>0;
  END;
 END;
 RETURN;
END;
GO
SELECT 'contract_catalog' AS result_set,document FROM analysis.v_capability_execution_declaration WHERE capability_id='resolve-sidefx-eligible-providers' AND entry_id='contracts/contract-catalog.json';
COMMIT TRANSACTION;
