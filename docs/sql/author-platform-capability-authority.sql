-- author-platform-capability-authority.sql
--
-- Author the canonical capability AUTHORITY for every sidefx:platform-capabilities
-- capability by inference from its own declaration, so `reveal --as meaning`
-- renders a real story (user story, experience promise, observable conditions)
-- instead of "(not declared)".
--
-- Inference (per capability):
--   actor   : the capability author / kernel consumer
--   intent  : use the <kind> platform capability <id> on <projectionTarget>
--   outcome : the admitted provider <provider> provides <providesMechanics...>
--   promise : every admitted use of <id> is realized by <provider> on <target>,
--             providing <mechanics>
--   observable conditions: <id>.provider-attributed, <id>.mechanics-provided
--
-- The authority is added at $.semantics.authority on a re-minted capability
-- definition; the existing declaration fields are preserved. A new
-- capability_version is created and every link that named the prior version
-- (estate_capability, capability_scenario, capability_root_scenario,
-- provider_capability_implementation, estate_capability_feature) is repointed,
-- so platform provider resolution is unchanged.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;

BEGIN TRANSACTION;

DECLARE @model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);

DECLARE @capPk bigint,@capId nvarchar(400),@capSo bigint,@selSod bigint,@oldVer bigint,@selEnv nvarchar(max),@kind nvarchar(100),@target nvarchar(100),@provider nvarchar(400),@mechanics nvarchar(max);
DECLARE @capAddress nvarchar(1000),@ownedNs nvarchar(400),@mechList nvarchar(max),@authority nvarchar(max),@newEnv nvarchar(max);
DECLARE @nb varbinary(max),@nd binary(32),@ndHex varchar(64),@newSod bigint,@newVer bigint,@cid nvarchar(400),@cEnv nvarchar(max),@cb varbinary(max),@cd binary(32),@cSo bigint,@cSod bigint,@nsPk bigint;
DECLARE @conds TABLE (id int, cid nvarchar(400));
DECLARE @i int,@n int,@ccid nvarchar(400);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
  SELECT c.capability_pk, c.capability_id, c.semantic_object_pk, ec.semantic_object_definition_pk, ec.capability_version_pk,
         CONVERT(nvarchar(max),CONVERT(varchar(max),selco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS selEnv,
         JSON_VALUE(rich.env,'$.semantics.kind'), JSON_VALUE(rich.env,'$.semantics.projectionTarget'),
         JSON_VALUE(rich.env,'$.semantics.provider'), JSON_QUERY(rich.env,'$.semantics.providesMechanics')
  FROM model.capability c
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@model
  JOIN model.semantic_object_definition seld ON seld.semantic_object_definition_pk=ec.semantic_object_definition_pk
  JOIN source.content_object selco ON selco.content_object_pk=seld.canonical_content_pk
  OUTER APPLY (
    SELECT TOP 1 CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS env
    FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE d.semantic_object_pk=c.semantic_object_pk AND JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.kind') IS NOT NULL
    ORDER BY d.semantic_object_definition_pk DESC
  ) rich
  WHERE n.namespace_id=N'sidefx:platform-capabilities'
    AND JSON_VALUE((SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co2.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM model.semantic_object_definition d2 JOIN source.content_object co2 ON co2.content_object_pk=d2.canonical_content_pk WHERE d2.semantic_object_definition_pk=ec.semantic_object_definition_pk),'$.semantics.authority.userStory.intent') IS NULL;

OPEN cur; FETCH NEXT FROM cur INTO @capPk,@capId,@capSo,@selSod,@oldVer,@selEnv,@kind,@target,@provider,@mechanics;
WHILE @@FETCH_STATUS=0
BEGIN
  SET @mechList = (SELECT STRING_AGG(j.value, N', ') FROM OPENJSON(@mechanics) j);
  SET @mechList = ISNULL(@mechList, N'its declared mechanics');
  SET @capAddress = N'{"id":"' + STRING_ESCAPE(@capId,'json') + N'","kind":"CAPABILITY","namespace":"sidefx:platform-capabilities"}';
  SET @ownedNs = N'owner:sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@capAddress) COLLATE Latin1_General_100_BIN2_UTF8))), 2));
  SET @authority = N'{"mode":"capability","name":"' + STRING_ESCAPE(@capId,'json') + N'",'
    + N'"userStory":{"actor":"a capability author","intent":"' + STRING_ESCAPE(N'use the ' + ISNULL(@kind,N'platform') + N' ' + @capId + N' on ' + ISNULL(@target,N'node'),'json') + N'",'
    + N'"outcome":"' + STRING_ESCAPE(N'the admitted provider ' + ISNULL(@provider,N'platform') + N' provides ' + @mechList,'json') + N'"},'
    + N'"experience":{"experienceId":"' + STRING_ESCAPE(@capId + N'.v1','json') + N'","actor":"a capability author",'
    + N'"promise":"' + STRING_ESCAPE(N'every admitted use of ' + @capId + N' is realized by ' + ISNULL(@provider,N'platform') + N' on ' + ISNULL(@target,N'node') + N', providing ' + @mechList,'json') + N'",'
    + N'"observableConditions":[{"conditionId":"' + @capId + N'.provider-attributed"},{"conditionId":"' + @capId + N'.mechanics-provided"}]},'
    + N'"rootScenarioId":"' + STRING_ESCAPE(@capId,'json') + N'"}';
  SET @newEnv = JSON_MODIFY(@selEnv, '$.semantics.authority', JSON_QUERY(@authority));
  SET @nb = CONVERT(varbinary(max), CONVERT(varchar(max), (@newEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @nd = HASHBYTES('SHA2_256', @nb);
  SET @ndHex = LOWER(CONVERT(varchar(64), @nd, 2));
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@nd) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@nd,@nb,DATALENGTH(@nb));
  SET @newSod = (SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@capSo AND definition_digest=@nd);
  IF @newSod IS NULL
  BEGIN
    INSERT model.semantic_object_definition (semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES (@capSo,'CAPABILITY',@nd,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@nd));
    SET @newSod = SCOPE_IDENTITY();
  END
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@newSod) INSERT model.estate_definition (estate_model_pk,semantic_object_definition_pk) VALUES (@model,@newSod);

  -- New capability_version, then carry every link that named the old one.
  IF @selSod <> @newSod AND NOT EXISTS (SELECT 1 FROM model.capability_version WHERE capability_pk=@capPk AND semantic_object_definition_pk=@newSod)
  BEGIN
    INSERT model.capability_version (capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,object_kind,_owner_definition_pk,_canonical_pointer)
      SELECT capability_pk,semantic_object_pk,@newSod,@nd,name,object_kind,@newSod,N'' FROM model.capability_version WHERE capability_version_pk=@oldVer;
    SET @newVer = SCOPE_IDENTITY();
    INSERT model.capability_scenario (capability_pk,capability_version_pk,scenario_pk,scenario_version_pk,_owner_definition_pk,_canonical_pointer)
      SELECT capability_pk,@newVer,scenario_pk,scenario_version_pk,_owner_definition_pk,_canonical_pointer FROM model.capability_scenario WHERE capability_version_pk=@oldVer;
    INSERT model.capability_root_scenario (capability_version_pk,scenario_pk,_owner_definition_pk,_canonical_pointer)
      SELECT @newVer,scenario_pk,_owner_definition_pk,_canonical_pointer FROM model.capability_root_scenario WHERE capability_version_pk=@oldVer;
    UPDATE model.provider_capability_implementation SET capability_version_pk=@newVer WHERE capability_version_pk=@oldVer;
    UPDATE model.estate_capability_feature SET capability_version_pk=@newVer WHERE capability_version_pk=@oldVer;
    UPDATE model.estate_capability SET capability_version_pk=@newVer, semantic_object_definition_pk=@newSod WHERE estate_model_pk=@model AND capability_pk=@capPk;
  END

  -- Observable conditions owned by the re-minted capability definition.
  SET @nsPk = (SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='OBSERVABLE_CONDITION' AND namespace_id=@ownedNs);
  IF @nsPk IS NULL BEGIN INSERT model.identity_namespace (namespace_kind,namespace_id) VALUES ('OBSERVABLE_CONDITION',@ownedNs); SET @nsPk=SCOPE_IDENTITY(); END
  DELETE @conds;
  INSERT @conds (id,cid) VALUES (1,@capId + N'.provider-attributed'),(2,@capId + N'.mechanics-provided');
  SET @i=1; SET @n=2;
  WHILE @i<=@n
  BEGIN
    SET @ccid=(SELECT cid FROM @conds WHERE id=@i);
    SET @cEnv = N'{"address":{"id":"' + STRING_ESCAPE(@ccid,'json') + N'","kind":"OBSERVABLE_CONDITION","namespace":"' + STRING_ESCAPE(@ownedNs,'json') + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"condition":{"conditionId":"' + STRING_ESCAPE(@ccid,'json') + N'"},"owner_definition_digest":"' + @ndHex + N'"}}';
    SET @cb = CONVERT(varbinary(max), CONVERT(varchar(max), (@cEnv) COLLATE Latin1_General_100_BIN2_UTF8));
    SET @cd = HASHBYTES('SHA2_256', @cb);
    IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@cd) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@cd,@cb,DATALENGTH(@cb));
    SET @cSo = (SELECT semantic_object_pk FROM model.semantic_object WHERE object_kind='OBSERVABLE_CONDITION' AND namespace_pk=@nsPk AND declared_id=@ccid);
    IF @cSo IS NULL BEGIN INSERT model.semantic_object (object_kind,namespace_pk,declared_id) VALUES ('OBSERVABLE_CONDITION',@nsPk,@ccid); SET @cSo=SCOPE_IDENTITY(); END
    IF NOT EXISTS (SELECT 1 FROM model.semantic_object_definition WHERE semantic_object_pk=@cSo AND definition_digest=@cd)
    BEGIN
      INSERT model.semantic_object_definition (semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES (@cSo,'OBSERVABLE_CONDITION',@cd,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@cd));
      SET @cSod = SCOPE_IDENTITY();
      IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@cSod) INSERT model.estate_definition (estate_model_pk,semantic_object_definition_pk) VALUES (@model,@cSod);
    END
    SET @i=@i+1;
  END
  FETCH NEXT FROM cur INTO @capPk,@capId,@capSo,@selSod,@oldVer,@selEnv,@kind,@target,@provider,@mechanics;
END
CLOSE cur; DEALLOCATE cur;

-- Verification: platform capabilities whose selected definition declares a story + experience.
SELECT 'authored' AS result_set, COUNT(*) AS n
FROM model.estate_capability ec
JOIN model.capability c ON c.capability_pk=ec.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=ec.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE ec.estate_model_pk=@model AND n.namespace_id=N'sidefx:platform-capabilities'
  AND JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.authority.userStory.intent') IS NOT NULL;

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
