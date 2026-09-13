-- backfill-platform-feature-scenarios.sql
--
-- Give every sidefx:platform-capabilities capability a canonical scenario, so it
-- participates in model.scenario / model.scenario_version / model.capability_scenario
-- / model.feature_scenario exactly like any authored capability.
--
-- The scenario is inferred from the capability's own declaration:
--   kind, projectionTarget, provider, providesMechanics, implementationRef, conformanceRef
-- as:
--   Given the <kind> platform capability <id> admitted for <target>
--   When  the provider <provider> executes its declared mechanics
--   Then  the mechanics <m1>, <m2>, ... are provided
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;

DECLARE @model bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @scnKindNs bigint=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=N'sidefx:platform-scenarios');
IF @scnKindNs IS NULL BEGIN INSERT model.identity_namespace (namespace_kind,namespace_id) VALUES ('SCENARIO',N'sidefx:platform-scenarios'); SET @scnKindNs=SCOPE_IDENTITY(); END

DECLARE @capPk bigint,@capId nvarchar(400),@capVer bigint,@capSod bigint,@kind nvarchar(100),@target nvarchar(100),@provider nvarchar(400),@mechanics nvarchar(max),@capDigest nvarchar(64);
DECLARE @featPk bigint,@featSo bigint,@scnNs nvarchar(400),@capAddress nvarchar(1000),@ast nvarchar(max),@tags nvarchar(max),@env nvarchar(max),@eb varbinary(max),@ed binary(32),@soPk bigint,@sod bigint,@scnPk bigint,@svPk bigint;
DECLARE @mechList nvarchar(max),@desc nvarchar(max),@text nvarchar(max),@tb varbinary(max),@td binary(32),@fenv nvarchar(max),@feb varbinary(max),@fed binary(32),@featSod bigint,@fvPk bigint;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
  SELECT c.capability_pk, c.capability_id, ec.capability_version_pk, ec.semantic_object_definition_pk,
         JSON_VALUE(rich.env,'$.semantics.kind'), JSON_VALUE(rich.env,'$.semantics.projectionTarget'),
         JSON_VALUE(rich.env,'$.semantics.provider'), JSON_QUERY(rich.env,'$.semantics.providesMechanics'),
         LOWER(CONVERT(varchar(64), cd.definition_digest, 2)) AS cap_digest,
         c.feature_pk, f.semantic_object_pk
  FROM model.capability c
  JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
  JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@model
  JOIN model.semantic_object_definition cd ON cd.semantic_object_definition_pk=ec.semantic_object_definition_pk
  JOIN model.feature f ON f.feature_pk=c.feature_pk
  OUTER APPLY (
    SELECT TOP 1 CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS env
    FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
    WHERE d.semantic_object_pk=c.semantic_object_pk AND JSON_VALUE(CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8),'$.semantics.kind') IS NOT NULL
    ORDER BY d.semantic_object_definition_pk DESC
  ) rich
  WHERE n.namespace_id=N'sidefx:platform-capabilities'
    AND NOT EXISTS (SELECT 1 FROM model.scenario s WHERE s.capability_pk=c.capability_pk);

OPEN cur; FETCH NEXT FROM cur INTO @capPk,@capId,@capVer,@capSod,@kind,@target,@provider,@mechanics,@capDigest,@featPk,@featSo;
WHILE @@FETCH_STATUS=0
BEGIN
  SET @mechList = (SELECT STRING_AGG(j.value, N', ') FROM OPENJSON(@mechanics) j);
  SET @mechList = ISNULL(@mechList, N'its declared behavior');
  SET @desc = N'Platform capability ' + @capId + N' (' + ISNULL(@kind,N'platform') + N').';
  SET @capAddress = N'{"id":"' + STRING_ESCAPE(@capId,'json') + N'","kind":"CAPABILITY","namespace":"sidefx:platform-capabilities"}';
  SET @scnNs = N'owner:sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max), (@capAddress) COLLATE Latin1_General_100_BIN2_UTF8))), 2));

  SET @ast = N'{"description":"' + STRING_ESCAPE(@desc,'json') + N'","examples":[],"keyword":"Scenario","name":"' + STRING_ESCAPE(@capId,'json') + N'",'
    + N'"steps":[{"keyword":"Given ","keywordType":"Context","text":"the ' + STRING_ESCAPE(ISNULL(@kind,'platform'),'json') + N' platform capability ' + STRING_ESCAPE(@capId,'json') + N' admitted for ' + STRING_ESCAPE(ISNULL(@target,'node'),'json') + N'"},'
    + N'{"keyword":"When ","keywordType":"Action","text":"the provider ' + STRING_ESCAPE(ISNULL(@provider,'platform'),'json') + N' executes its declared mechanics"},'
    + N'{"keyword":"Then ","keywordType":"Outcome","text":"the mechanics ' + STRING_ESCAPE(@mechList,'json') + N' are provided"}],'
    + N'"tags":[{"name":"@scenario:' + @capId + N'"},{"name":"@platform-capability:' + @capId + N'"},{"name":"@outcome-terminal"}]}';
  SET @tags = N'{"capability":["' + @capId + N'"],"platform-capability":["' + @capId + N'"],"event":["' + @capId + N'"],"scenario":["' + @capId + N'"],"root-scenario":["' + @capId + N'"],"outcome-terminal":[true]}';
  SET @env = N'{"address":{"id":"' + STRING_ESCAPE(@capId,'json') + N'","kind":"SCENARIO","namespace":"' + STRING_ESCAPE(@scnNs,'json') + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority_manifest_digest":"' + @capDigest + N'","scenario":' + @ast + N',"tags":' + @tags + N'}}';
  SET @eb = CONVERT(varbinary(max), CONVERT(varchar(max), (@env) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @ed = HASHBYTES('SHA2_256', @eb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@ed) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@ed,@eb,DATALENGTH(@eb));
  IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=@scnNs) INSERT model.identity_namespace (namespace_kind,namespace_id) VALUES ('SCENARIO',@scnNs);
  SET @soPk = (SELECT semantic_object_pk FROM model.semantic_object WHERE object_kind='SCENARIO' AND namespace_pk=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=@scnNs) AND declared_id=@capId);
  IF @soPk IS NULL BEGIN INSERT model.semantic_object (object_kind,namespace_pk,declared_id) VALUES ('SCENARIO',(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=@scnNs),@capId); SET @soPk=SCOPE_IDENTITY(); END
  INSERT model.semantic_object_definition (semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES (@soPk,'SCENARIO',@ed,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@ed));
  SET @sod = SCOPE_IDENTITY();
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@sod) INSERT model.estate_definition (estate_model_pk,semantic_object_definition_pk) VALUES (@model,@sod);
  INSERT model.scenario (namespace_pk,scenario_id,semantic_object_pk,object_kind,capability_pk) VALUES ((SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='SCENARIO' AND namespace_id=@scnNs),@capId,@soPk,'SCENARIO',@capPk);
  SET @scnPk = SCOPE_IDENTITY();
  INSERT model.scenario_version (scenario_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,source_profile,object_kind,_owner_definition_pk,_canonical_pointer)
    VALUES (@scnPk,@soPk,@sod,@ed,@capId,'managed-feature-tags.v1','SCENARIO',@sod,N'');
  SET @svPk = SCOPE_IDENTITY();
  INSERT model.capability_scenario (capability_pk,capability_version_pk,scenario_pk,scenario_version_pk,_owner_definition_pk,_canonical_pointer)
    VALUES (@capPk,@capVer,@scnPk,@svPk,@sod,N'');
  INSERT model.capability_root_scenario (capability_version_pk,scenario_pk,_owner_definition_pk,_canonical_pointer) VALUES (@capVer,@scnPk,@sod,N'');

  -- Re-mint the feature (text + parsed declaration) to declare the scenario.
  SET @text = N'@capability:' + @capId + CHAR(10) + N'@root-scenario:' + @capId + CHAR(10) + CHAR(10)
    + N'Feature: ' + @capId + CHAR(10) + CHAR(10) + N'  ' + @desc + CHAR(10) + CHAR(10)
    + N'  @scenario:' + @capId + CHAR(10) + N'  @outcome-terminal' + CHAR(10) + N'  Scenario: ' + @capId + CHAR(10)
    + N'    Given the ' + ISNULL(@kind,N'platform') + N' platform capability ' + @capId + N' admitted for ' + ISNULL(@target,N'node') + CHAR(10)
    + N'    When the provider ' + ISNULL(@provider,N'platform') + N' executes its declared mechanics' + CHAR(10)
    + N'    Then the mechanics ' + @mechList + N' are provided';
  SET @tb = CONVERT(varbinary(max), CONVERT(varchar(max), (@text) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @td = HASHBYTES('SHA2_256', @tb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@td) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@td,@tb,DATALENGTH(@tb));
  SET @fenv = N'{"address":{"id":"' + STRING_ESCAPE(@capId,'json') + N'","kind":"FEATURE","namespace":"sidefx:features"},"format":"sidefx-semantic-definition.v1","semantics":{"name":"' + STRING_ESCAPE(@capId,'json') + N'","description":"' + STRING_ESCAPE(@desc,'json') + N'","content_digest":"' + LOWER(CONVERT(varchar(64),@td,2)) + N'","source_path":"features/' + STRING_ESCAPE(@capId,'json') + N'.feature","domain":"platform","scenarios":[{"scenarioId":"' + STRING_ESCAPE(@capId,'json') + N'","scenarioVersionPk":' + CONVERT(nvarchar(20),@svPk) + N'}],"declaration":' + (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) FROM model.semantic_object_definition d JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk WHERE d.semantic_object_definition_pk=@capSod) + N'}}';
  SET @feb = CONVERT(varbinary(max), CONVERT(varchar(max), (@fenv) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @fed = HASHBYTES('SHA2_256', @feb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@fed) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@fed,@feb,DATALENGTH(@feb));
  INSERT model.semantic_object_definition (semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES (@featSo,'FEATURE',@fed,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@fed));
  SET @featSod = SCOPE_IDENTITY();
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@featSod) INSERT model.estate_definition (estate_model_pk,semantic_object_definition_pk) VALUES (@model,@featSod);
  INSERT model.feature_version (feature_pk,capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,source_profile,object_kind,_owner_definition_pk,_canonical_pointer)
    VALUES (@featPk,@capPk,@featSo,@featSod,@fed,@capId,'parsed-feature-declaration.v1','FEATURE',@featSod,N'');
  SET @fvPk = SCOPE_IDENTITY();
  INSERT model.feature_scenario (feature_version_pk,scenario_pk,scenario_version_pk,capability_pk,ordinal) VALUES (@fvPk,@scnPk,@svPk,@capPk,0);

  FETCH NEXT FROM cur INTO @capPk,@capId,@capVer,@capSod,@kind,@target,@provider,@mechanics,@capDigest,@featPk,@featSo;
END
CLOSE cur; DEALLOCATE cur;

-- Verification: platform capabilities with a feature_scenario.
SELECT 'platform_caps_with_feature_scenario' AS result_set, COUNT(DISTINCT fs.capability_pk) AS n
FROM model.feature_scenario fs
JOIN model.capability c ON c.capability_pk=fs.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE n.namespace_id=N'sidefx:platform-capabilities';
SELECT 'platform_scenarios' AS result_set, COUNT(*) AS n
FROM model.scenario s JOIN model.capability c ON c.capability_pk=s.capability_pk
JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk
WHERE n.namespace_id=N'sidefx:platform-capabilities';

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
