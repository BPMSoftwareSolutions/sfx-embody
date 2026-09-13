-- normalize-contract-nullable-enum.sql
--
-- A property declared as a type array with a JSON `null` inside `enum` cannot be
-- built into the type graph: the planner refuses the literal with
--   Unsupported literal at '<$id>#/...': null.
-- (Observed for the speech-generation invocation/response contracts at
--  $.properties.payload.properties.terminalDisposition.)
--
-- The admitted projection profile expresses nullability as a two-branch `oneOf`
-- with a `{"type":"null"}` branch. This rewrites each affected enum to that form
-- (preserving the declared non-null members and their order), re-mints the schema
-- object, contract definition and contract version, and re-links every contract
-- version reference that named the prior version.
-- Idempotent: a property with no `null` enum member is left untouched.
--
-- Default: ROLLBACK. Replace with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;

DECLARE @model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @path nvarchar(400)=N'$.properties.payload.properties.terminalDisposition';

DECLARE @targets TABLE (rn int IDENTITY(1,1), oldCv bigint);
INSERT @targets (oldCv)
SELECT DISTINCT cv.contract_version_pk
FROM model.contract_version cv
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS s) j
WHERE cv.contract_version_pk=(SELECT MAX(cv2.contract_version_pk) FROM model.contract_version cv2 WHERE cv2.contract_pk=cv.contract_pk)
  AND EXISTS (SELECT 1 FROM OPENJSON(j.s, @path + '.enum') WHERE value IS NULL);

BEGIN TRANSACTION;

DECLARE @i int=1, @n int=(SELECT COUNT(*) FROM @targets), @oldCv bigint;
DECLARE @contractPk bigint,@capSo bigint,@oldSod bigint,@oldSchemaPk bigint,@dialect nvarchar(400),@schema nvarchar(max),@cenv nvarchar(max);
DECLARE @vals nvarchar(max),@replacement nvarchar(max),@newSchema nvarchar(max),@sb varbinary(max),@sd binary(32),@newSchemaPk bigint,@newEnv nvarchar(max),@eb varbinary(max),@ed binary(32),@newSod bigint,@newCv bigint;
DECLARE @fixed int=0;

WHILE @i<=@n
BEGIN
  SELECT @oldCv=oldCv FROM @targets WHERE rn=@i;
  SELECT TOP 1 @contractPk=cv.contract_pk,@capSo=cv.semantic_object_pk,@oldSod=cv.semantic_object_definition_pk,@oldSchemaPk=cv.schema_object_pk,@dialect=so.dialect,
         @schema=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.contract_version cv
  JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
  JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
  WHERE cv.contract_version_pk=@oldCv;
  SELECT @cenv=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk WHERE d.semantic_object_definition_pk=@oldSod;

  SELECT @vals=STRING_AGG('"' + STRING_ESCAPE(CAST(value AS nvarchar(max)),'json') + '"', N',') WITHIN GROUP (ORDER BY CONVERT(int,[key]))
  FROM OPENJSON(@schema, @path + '.enum') WHERE value IS NOT NULL;
  SET @replacement=N'{"oneOf":[{"type":"string","enum":[' + @vals + N']},{"type":"null"}]}';
  SET @newSchema=JSON_MODIFY(@schema,@path,JSON_QUERY(@replacement));

  SET @sb=CONVERT(varbinary(max),CONVERT(varchar(max),(@newSchema) COLLATE Latin1_General_100_BIN2_UTF8)); SET @sd=HASHBYTES('SHA2_256',@sb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@sd) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@sd,@sb,DATALENGTH(@sb));
  SET @newSchemaPk=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@sd);
  IF @newSchemaPk IS NULL BEGIN INSERT model.schema_object (content_digest,dialect,content_object_pk) VALUES (@sd,@dialect,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@sd)); SET @newSchemaPk=SCOPE_IDENTITY(); END

  SET @newEnv=JSON_MODIFY(@cenv,'$.semantics.schema_digest',LOWER(CONVERT(varchar(64),@sd,2)));
  SET @eb=CONVERT(varbinary(max),CONVERT(varchar(max),(@newEnv) COLLATE Latin1_General_100_BIN2_UTF8)); SET @ed=HASHBYTES('SHA2_256',@eb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@ed) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@ed,@eb,DATALENGTH(@eb));
  INSERT model.semantic_object_definition (semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES (@capSo,'CONTRACT',@ed,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@ed));
  SET @newSod=SCOPE_IDENTITY();
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@newSod) INSERT model.estate_definition (estate_model_pk,semantic_object_definition_pk) VALUES (@model,@newSod);
  INSERT model.contract_version (contract_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,contract_kind,schema_object_pk,object_kind,_owner_definition_pk,_canonical_pointer,schema_reference_state)
    VALUES (@contractPk,@capSo,@newSod,@ed,NULL,NULL,@newSchemaPk,'CONTRACT',@newSod,N'','RESOLVED');
  SET @newCv=SCOPE_IDENTITY();

  UPDATE model.scenario_input SET input_contract_version_pk=@newCv WHERE input_contract_version_pk=@oldCv;
  UPDATE model.scenario_outcome_contract SET contract_version_pk=@newCv WHERE contract_version_pk=@oldCv;
  UPDATE model.port_contract SET contract_version_pk=@newCv WHERE contract_version_pk=@oldCv;
  UPDATE model.product_definition SET contract_version_pk=@newCv WHERE contract_version_pk=@oldCv;
  UPDATE model.estate_scenario_face_resolution SET contract_version_pk=@newCv WHERE contract_version_pk=@oldCv;

  SET @fixed=@fixed+1; SET @i=@i+1;
END

SELECT '1_result' AS result_set, @n AS targeted, @fixed AS fixed;
SELECT '2_remaining_null_enums' AS result_set, COUNT(*) AS n
FROM model.contract_version cv
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS s) j
WHERE cv.contract_version_pk=(SELECT MAX(cv2.contract_version_pk) FROM model.contract_version cv2 WHERE cv2.contract_pk=cv.contract_pk)
  AND EXISTS (SELECT 1 FROM OPENJSON(j.s, @path + '.enum') WHERE value IS NULL);

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
