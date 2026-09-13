-- ensure-contract-object-root-schema.sql
--
-- A contract whose schema root is an `anyOf`/`allOf`/`oneOf` union with no
-- `type: object` cannot be built into the type graph: the planner refuses it with
--   Root '<$id>#' must resolve to an object schema.
-- (Observed for observe-governed-http-exchange-input.v1.)
--
-- This makes the root an object schema by adding `"type": "object"` at the root
-- (compatible with the existing union branches), re-mints the schema object,
-- contract definition and contract version, and re-links every scenario input
-- that named the prior contract version. Idempotent: a contract whose root
-- already declares its type is left untouched.
--
-- Edit @contract_id as needed. Default: ROLLBACK. Replace with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;

DECLARE @contract_id nvarchar(400) = N'observe-governed-http-exchange-input.v1';

BEGIN TRANSACTION;

DECLARE @model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @contractPk bigint, @capSo bigint, @oldCv bigint, @oldSod bigint, @oldSchemaPk bigint, @dialect nvarchar(400), @schema nvarchar(max), @cenv nvarchar(max);
SELECT TOP 1 @contractPk=cv.contract_pk, @capSo=cv.semantic_object_pk, @oldCv=cv.contract_version_pk, @oldSod=cv.semantic_object_definition_pk,
       @oldSchemaPk=cv.schema_object_pk, @dialect=so.dialect,
       @schema=CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.contract_version cv
JOIN model.contract ct ON ct.contract_pk=cv.contract_pk
JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
WHERE ct.contract_id=@contract_id
ORDER BY cv.contract_version_pk DESC;
SELECT @cenv=CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk WHERE d.semantic_object_definition_pk=@oldSod;

DECLARE @action nvarchar(20);
IF @contractPk IS NULL SET @action=N'NOT_FOUND';
ELSE IF JSON_VALUE(@schema, '$.type') = N'object' SET @action=N'ALREADY_OBJECT';
ELSE SET @action=N'FIXED';

IF @action = N'FIXED'
BEGIN
  DECLARE @newSchema nvarchar(max)=JSON_MODIFY(@schema, '$.type', N'object');
  DECLARE @sb varbinary(max)=CONVERT(varbinary(max), CONVERT(varchar(max), (@newSchema) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @sd binary(32)=HASHBYTES('SHA2_256', @sb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@sd) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@sd,@sb,DATALENGTH(@sb));
  DECLARE @newSchemaPk bigint=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@sd);
  IF @newSchemaPk IS NULL BEGIN INSERT model.schema_object (content_digest,dialect,content_object_pk) VALUES (@sd,@dialect,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@sd)); SET @newSchemaPk=SCOPE_IDENTITY(); END

  DECLARE @newEnv nvarchar(max)=JSON_MODIFY(@cenv, '$.semantics.schema_digest', LOWER(CONVERT(varchar(64), @sd, 2)));
  DECLARE @eb varbinary(max)=CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @ed binary(32)=HASHBYTES('SHA2_256', @eb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@ed) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@ed,@eb,DATALENGTH(@eb));
  INSERT model.semantic_object_definition (semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES (@capSo,'CONTRACT',@ed,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@ed));
  DECLARE @newSod bigint=SCOPE_IDENTITY();
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@newSod) INSERT model.estate_definition (estate_model_pk,semantic_object_definition_pk) VALUES (@model,@newSod);
  INSERT model.contract_version (contract_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,contract_kind,schema_object_pk,object_kind,_owner_definition_pk,_canonical_pointer,schema_reference_state)
    VALUES (@contractPk,@capSo,@newSod,@ed,NULL,NULL,@newSchemaPk,'CONTRACT',@newSod,N'','RESOLVED');
  DECLARE @newCv bigint=SCOPE_IDENTITY();
  UPDATE model.scenario_input SET input_contract_version_pk=@newCv WHERE input_contract_version_pk=@oldCv;
  DECLARE @relinked int=@@ROWCOUNT;
END

SELECT '1_action' AS result_set, @action AS action, @contract_id AS contract_id;
SELECT '2_root_type' AS result_set, JSON_VALUE(@schema, '$.type') AS type_before,
       JSON_VALUE(JSON_MODIFY(@schema, '$.type', N'object'), '$.type') AS type_after;
SELECT '3_current_version' AS result_set, MAX(cv.contract_version_pk) AS contract_version_pk
FROM model.contract_version cv WHERE cv.contract_pk=@contractPk;
SELECT '4_inputs_on_current' AS result_set, COUNT(*) AS n
FROM model.scenario_input si
WHERE si.input_contract_version_pk = (SELECT MAX(cv.contract_version_pk) FROM model.contract_version cv WHERE cv.contract_pk=@contractPk);

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
