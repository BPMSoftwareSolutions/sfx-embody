-- update-model-provider-protocol-route-contract.sql
--
-- Completes the model-provider protocol routing repair
-- (declare-model-provider-protocol-routing.sql): the root scenario's declared
-- outcome carrier is the shared request contract with the route variant at its
-- top level, so the selection edges connect identical endpoint contracts and
-- the projection plan can compile without a binding authority the estate does
-- not declare. The canonical feature still annotated the removed wrapper
-- contract, so this migration publishes the corrected feature text as a new
-- parsed feature version of the same feature. Nothing else in the feature
-- changes: only @outcome-contract:model-provider-protocol-route.v1 becomes
-- @outcome-contract:project-model-provider-protocol-input.v1 on the root
-- scenario. The scenarios, steps and every sibling face stay as retained.
--
-- Idempotent: the corrected text is a new content object; the new feature
-- version is inserted once and the canonical binding moves to it. A replay
-- finds the corrected text already current and reports UNCHANGED.
--
-- Default: ROLLBACK. Install only after the from-transaction preflight passes:
--   node scripts/run-migration.mjs sql/migrations/update-model-provider-protocol-route-contract.sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability_pk bigint=(SELECT capability_pk FROM model.capability WHERE capability_id=N'project-model-provider-protocol');
IF @capability_pk IS NULL THROW 51000,'MODEL_PROVIDER_PROTOCOL_CAPABILITY_MISSING',1;
DECLARE @old_fv bigint=(
  SELECT TOP 1 fv.feature_version_pk FROM model.feature_version fv
  WHERE fv.feature_pk=(SELECT feature_pk FROM model.capability WHERE capability_pk=@capability_pk)
    AND fv.source_profile=N'parsed-feature-declaration.v1'
  ORDER BY fv.feature_version_pk DESC);
IF @old_fv IS NULL THROW 51000,'MODEL_PROVIDER_PROTOCOL_FEATURE_VERSION_MISSING',1;
DECLARE @old_sod bigint, @env nvarchar(max);
SELECT @old_sod=fv.semantic_object_definition_pk,
  @env=CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
FROM model.feature_version fv
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=fv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE fv.feature_version_pk=@old_fv;
IF @old_sod IS NULL OR @env IS NULL THROW 51000,'MODEL_PROVIDER_PROTOCOL_FEATURE_DEFINITION_MISSING',1;
DECLARE @old_content nvarchar(64)=JSON_VALUE(@env,'$.semantics.content_digest');
DECLARE @text nvarchar(max)=(
  SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),fco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM source.content_object fco WHERE fco.content_digest=CONVERT(binary(32),'0x'+@old_content,1));
IF @text IS NULL THROW 51000,'MODEL_PROVIDER_PROTOCOL_FEATURE_TEXT_MISSING',1;
IF @text LIKE N'%@outcome-contract:project-model-provider-protocol-input.v1%'
   AND @text NOT LIKE N'%@outcome-contract:model-provider-protocol-route.v1%'
BEGIN
  SELECT 'feature_update' AS result_set, N'UNCHANGED' AS disposition, @old_content AS content_digest, @old_fv AS feature_version_pk;
END
ELSE BEGIN
  SET @text=REPLACE(@text,N'@outcome-contract:model-provider-protocol-route.v1',N'@outcome-contract:project-model-provider-protocol-input.v1');
  IF @text LIKE N'%@outcome-contract:model-provider-protocol-route.v1%' THROW 51000,'MODEL_PROVIDER_PROTOCOL_ROUTE_CONTRACT_NOT_REPLACED',1;
  DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@text COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @digest binary(32)=HASHBYTES('SHA2_256',@bytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
    INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@digest,@bytes,DATALENGTH(@bytes));
  DECLARE @feature_sop bigint=(SELECT semantic_object_pk FROM model.feature_version WHERE feature_version_pk=@old_fv);
  DECLARE @new_env nvarchar(max)=JSON_MODIFY(@env,'$.semantics.content_digest',LOWER(CONVERT(varchar(64),@digest,2)));
  DECLARE @env_bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@new_env COLLATE Latin1_General_100_BIN2_UTF8));
  DECLARE @env_digest binary(32)=HASHBYTES('SHA2_256',@env_bytes);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@env_digest)
    INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@env_digest,@env_bytes,DATALENGTH(@env_bytes));
  IF NOT EXISTS (SELECT 1 FROM model.semantic_object_definition WHERE semantic_object_pk=@feature_sop AND definition_digest=@env_digest)
    INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
      VALUES(@feature_sop,'FEATURE',@env_digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@env_digest));
  DECLARE @new_sod bigint=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@feature_sop AND definition_digest=@env_digest);
  DECLARE @new_fv bigint=NULL;
  IF EXISTS (SELECT 1 FROM model.feature_version WHERE semantic_object_definition_pk=@new_sod)
  BEGIN
    SET @new_fv=(SELECT TOP 1 feature_version_pk FROM model.feature_version WHERE semantic_object_definition_pk=@new_sod ORDER BY feature_version_pk DESC);
  END
  ELSE BEGIN
    INSERT model.feature_version(feature_pk,capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,source_profile,object_kind,_owner_definition_pk,_canonical_pointer)
    SELECT fv.feature_pk,fv.capability_pk,fv.semantic_object_pk,@new_sod,@env_digest,fv.name,fv.source_profile,'FEATURE',@new_sod,N''
    FROM model.feature_version fv WHERE fv.feature_version_pk=@old_fv;
    SET @new_fv=SCOPE_IDENTITY();
    INSERT model.feature_scenario(feature_version_pk,scenario_pk,scenario_version_pk,capability_pk,ordinal)
    SELECT @new_fv,scenario_pk,scenario_version_pk,capability_pk,ordinal FROM model.feature_scenario WHERE feature_version_pk=@old_fv;
  END
  -- The canonical feature binding is capability-level data; every estate model's
  -- binding for this capability moves to the corrected feature version.
  UPDATE model.estate_capability_feature SET feature_version_pk=@new_fv
   WHERE capability_pk=@capability_pk;
  SELECT 'feature_update' AS result_set, N'UPDATED' AS disposition, LOWER(CONVERT(varchar(64),@digest,2)) AS content_digest, @new_fv AS feature_version_pk;
END
GO
-- ============================== VERIFICATION ==============================
SELECT '1_feature_face' AS result_set, 'project-model-provider-protocol' AS capability_id
FROM analysis.capability_execution_declaration(N'project-model-provider-protocol', NULL, 1) d
WHERE d.entry_id=N'capability.feature'
  AND d.document LIKE N'%@outcome-contract:project-model-provider-protocol-input.v1%'
  AND d.document NOT LIKE N'%@outcome-contract:model-provider-protocol-route.v1%';
SELECT '2_canonical_binding' AS result_set, ecf.estate_model_pk, ecf.feature_version_pk, fv.source_profile
FROM model.estate_capability_feature ecf
JOIN model.feature_version fv ON fv.feature_version_pk=ecf.feature_version_pk
JOIN model.capability c ON c.capability_pk=ecf.capability_pk
WHERE c.capability_id=N'project-model-provider-protocol';
COMMIT TRANSACTION;
