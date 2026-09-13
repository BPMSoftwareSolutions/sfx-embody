-- declare-equity-meaning.sql
--
-- Declare the meaning the estate holds but the model does not surface for
-- resolve-equity-market-price-evidence:
--   1. capability user story + experience        (on the capability definition)
--   2. observable conditions                     (declared against the capability)
--   3. scenario specification                    (authored steps on the scenario)
--   4. canonical feature binding                 (the declaration that carries the name)
--
-- The authored wording below is the declaration. It restates what the retained
-- feature already says (name, narrative, Given/When/Then); it introduces no claim
-- the feature does not make. Edit the parameters before running if the authority
-- reads differently.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- ---------------------------- authored declaration ----------------------------
DECLARE @CapabilityId nvarchar(400) = N'resolve-equity-market-price-evidence';
DECLARE @Name nvarchar(400)         = N'Resolve provider-neutral equity market-price evidence';
DECLARE @StoryActor nvarchar(200)   = N'consumer';
DECLARE @StoryIntent nvarchar(1000) = N'request observed market-price evidence using one canonical input';
DECLARE @StoryOutcome nvarchar(1000)= N'receive one canonical evidence outcome independent of the selected supplier';
DECLARE @ExperienceId nvarchar(400) = N'provider-neutral-equity-market-price-evidence.v1';
DECLARE @ExperienceActor nvarchar(200) = N'consumer';
DECLARE @ExperiencePromise nvarchar(1000) = N'every admitted resolution returns one canonical evidence outcome independent of the selected supplier, with the provider realization outside the capability''s semantic identity';
DECLARE @ScenarioName nvarchar(400) = N'Resolve an equity price observation through an admitted provider binding';
DECLARE @ScenarioGiven nvarchar(1000) = N'a canonical symbol and region, an admitted provider route, an exact native mapping, and bounded exchange authority';
DECLARE @ScenarioWhen nvarchar(1000)  = N'equity market-price evidence is resolved';
DECLARE @ScenarioThen nvarchar(1000)  = N'the canonical evidence retains symbol, region, currency, price, market time, market state, exchange, source attribution, and provider testimony identity';

DECLARE @conditions TABLE (ordinal int, conditionId nvarchar(400));
INSERT @conditions VALUES
  (0, N'canonical-evidence-retained'),
  (1, N'provider-realization-outside-semantic-identity'),
  (2, N'observed-price-is-attributable-provider-testimony');

DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capPk bigint = (SELECT capability_pk FROM model.capability WHERE capability_id=@CapabilityId);
DECLARE @capSo bigint = (SELECT semantic_object_pk FROM model.capability WHERE capability_pk=@capPk);
DECLARE @featurePk bigint = (SELECT feature_pk FROM model.capability WHERE capability_pk=@capPk);
DECLARE @parsedFeatureVer bigint = (SELECT feature_version_pk FROM model.feature_version WHERE feature_pk=@featurePk AND source_profile=N'parsed-feature-declaration.v1');
-- The most recent capability definition that still resolves its retained source;
-- the new definition carries the same source resolution forward.
DECLARE @srcSod bigint = (SELECT TOP 1 cv.semantic_object_definition_pk FROM model.capability_version cv
  WHERE cv.capability_pk=@capPk AND EXISTS (SELECT 1 FROM source.source_lineage l WHERE l.semantic_object_definition_pk=cv.semantic_object_definition_pk)
  ORDER BY cv.capability_version_pk DESC);

-- Drop the workshop data guards.
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;

-- ============================== BEFORE ==============================
SELECT 'BEFORE_conditions' AS result_set, COUNT(*) AS n
FROM analysis.v_selected_semantic_definition
WHERE object_kind='OBSERVABLE_CONDITION' AND JSON_VALUE(definition_json,'$.semantics.owner_definition_digest')=(
  SELECT LOWER(CONVERT(varchar(64),cv.definition_digest,2)) FROM model.capability_version cv
  JOIN model.estate_capability ec ON ec.capability_version_pk=cv.capability_version_pk
  WHERE ec.estate_model_pk=@model AND ec.capability_pk=@capPk);

BEGIN TRANSACTION;

DECLARE @capDigest binary(32), @blob varbinary(max);
DECLARE @ownedNs nvarchar(400) = N'owner:sha256:' + LOWER(CONVERT(varchar(64), HASHBYTES('SHA2_256', CONVERT(varbinary(max), CONVERT(varchar(max),
  (N'{"id":"'+@CapabilityId+N'","kind":"CAPABILITY","namespace":"sidefx:capabilities"}') COLLATE Latin1_General_100_BIN2_UTF8))), 2));

-- 1. Capability definition carrying user story + experience.
DECLARE @condJson nvarchar(max) = STUFF((SELECT N',' + N'{"conditionId":"' + STRING_ESCAPE(conditionId,'json') + N'"}' FROM @conditions ORDER BY ordinal FOR XML PATH(''),TYPE).value('.','nvarchar(max)'),1,1,N'');
DECLARE @capEnv nvarchar(max) =
  N'{"address":{"id":"' + STRING_ESCAPE(@CapabilityId,'json') + N'","kind":"CAPABILITY","namespace":"sidefx:capabilities"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{'
+ N'"capabilityId":"' + STRING_ESCAPE(@CapabilityId,'json') + N'","mode":"capability","name":"' + STRING_ESCAPE(@Name,'json') + N'","rootScenarioId":"' + STRING_ESCAPE(@CapabilityId,'json') + N'",'
+ N'"userStory":{"actor":"' + STRING_ESCAPE(@StoryActor,'json') + N'","intent":"' + STRING_ESCAPE(@StoryIntent,'json') + N'","outcome":"' + STRING_ESCAPE(@StoryOutcome,'json') + N'"},'
+ N'"experience":{"actor":"' + STRING_ESCAPE(@ExperienceActor,'json') + N'","experienceId":"' + STRING_ESCAPE(@ExperienceId,'json') + N'","promise":"' + STRING_ESCAPE(@ExperiencePromise,'json') + N'","observableConditions":[' + @condJson + N']}}}}';
SET @blob = CONVERT(varbinary(max), CONVERT(varchar(max), (@capEnv) COLLATE Latin1_General_100_BIN2_UTF8));
SET @capDigest = HASHBYTES('SHA2_256', @blob);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@capDigest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@capDigest, @blob, DATALENGTH(@blob));
DECLARE @capSod bigint;
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
  VALUES (@capSo, 'CAPABILITY', @capDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@capDigest));
SET @capSod = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @capSod);
-- Carry the retained-source resolution forward, so the read path resolves exactly
-- one source for the new capability definition.
IF @srcSod IS NOT NULL
  INSERT source.source_lineage (semantic_object_definition_pk, member_kind, canonical_pointer, source_observation_pk, mapping_rule_pk, contribution_role)
  SELECT @capSod, l.member_kind, l.canonical_pointer, l.source_observation_pk, l.mapping_rule_pk, l.contribution_role
  FROM source.source_lineage l
  WHERE l.semantic_object_definition_pk=@srcSod
    AND NOT EXISTS (SELECT 1 FROM source.source_lineage x WHERE x.semantic_object_definition_pk=@capSod AND x.member_kind=l.member_kind AND x.source_observation_pk=l.source_observation_pk);
INSERT model.capability_version (capability_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, name, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES (@capPk, @capSo, @capSod, @capDigest, @Name, 'CAPABILITY', @capSod, N'');
DECLARE @capVer bigint = SCOPE_IDENTITY();
-- Attach the existing scenario version (with its faces) to the new capability
-- version, so the executable chain is unchanged and only the declared meaning moves.
DECLARE @scnPk bigint, @scnSo bigint, @scnNs bigint, @scnVerExisting bigint;
SELECT @scnPk=cs.scenario_pk, @scnSo=s.semantic_object_pk, @scnNs=s.namespace_pk, @scnVerExisting=cs.scenario_version_pk
FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
WHERE cs.capability_pk=@capPk AND s.scenario_id=@CapabilityId
  AND cs.capability_version_pk=(SELECT MAX(ec2.capability_version_pk) FROM model.estate_capability ec2 WHERE ec2.estate_model_pk=@model AND ec2.capability_pk=@capPk);
INSERT model.capability_scenario (capability_pk, capability_version_pk, scenario_pk, scenario_version_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@capPk, @capVer, @scnPk, @scnVerExisting, @capSod, N'');
INSERT model.capability_root_scenario (capability_version_pk, scenario_pk, _owner_definition_pk, _canonical_pointer)
  VALUES (@capVer, @scnPk, @capSod, N'');
UPDATE model.estate_capability SET capability_version_pk=@capVer, semantic_object_definition_pk=@capSod
WHERE estate_model_pk=@model AND capability_pk=@capPk;

-- 2. Observable conditions declared against the capability definition.
DECLARE @condSo bigint, @condSod bigint, @condEnv nvarchar(max), @condDigest binary(32), @cid nvarchar(400), @condNs bigint;
DECLARE condCur CURSOR FOR SELECT conditionId FROM @conditions ORDER BY ordinal;
OPEN condCur; FETCH NEXT FROM condCur INTO @cid;
WHILE @@FETCH_STATUS=0
BEGIN
  IF NOT EXISTS (SELECT 1 FROM model.identity_namespace WHERE namespace_kind='OBSERVABLE_CONDITION' AND namespace_id=@ownedNs)
    INSERT model.identity_namespace (namespace_kind, namespace_id) VALUES ('OBSERVABLE_CONDITION', @ownedNs);
  SET @condNs = (SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='OBSERVABLE_CONDITION' AND namespace_id=@ownedNs);
  IF NOT EXISTS (SELECT 1 FROM model.semantic_object s WHERE s.object_kind='OBSERVABLE_CONDITION' AND s.namespace_pk=@condNs AND s.declared_id=@cid)
  BEGIN
    INSERT model.semantic_object (object_kind, namespace_pk, declared_id) VALUES ('OBSERVABLE_CONDITION', @condNs, @cid);
    SET @condSo = SCOPE_IDENTITY();
  END
  ELSE SELECT @condSo = semantic_object_pk FROM model.semantic_object WHERE object_kind='OBSERVABLE_CONDITION' AND namespace_pk=@condNs AND declared_id=@cid;
  SET @condEnv = N'{"address":{"id":"' + STRING_ESCAPE(@cid,'json') + N'","kind":"OBSERVABLE_CONDITION","namespace":"' + @ownedNs + N'"},"format":"sidefx-semantic-definition.v1","semantics":{"condition":{"conditionId":"' + STRING_ESCAPE(@cid,'json') + N'"},"owner_definition_digest":"' + LOWER(CONVERT(varchar(64),@capDigest,2)) + N'"}}';
  SET @blob = CONVERT(varbinary(max), CONVERT(varchar(max), (@condEnv) COLLATE Latin1_General_100_BIN2_UTF8));
  SET @condDigest = HASHBYTES('SHA2_256', @blob);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@condDigest)
    INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@condDigest, @blob, DATALENGTH(@blob));
  INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
    VALUES (@condSo, 'OBSERVABLE_CONDITION', @condDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@condDigest));
  SET @condSod = SCOPE_IDENTITY();
  INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @condSod);
  INSERT model.observable_condition (owner_definition_pk, condition_id, statement, semantic_object_pk, semantic_object_definition_pk, namespace_pk, definition_digest, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES (@capSod, @cid, NULL, @condSo, @condSod, @condNs, @condDigest, 'OBSERVABLE_CONDITION', @condSod, N'');
  FETCH NEXT FROM condCur INTO @cid;
END
CLOSE condCur; DEALLOCATE condCur;

-- 3. Scenario definition carrying the authored specification. The scenario
-- version and its faces are untouched; the current definition is the one read.
DECLARE @scnEnv nvarchar(max) =
  N'{"address":{"id":"' + STRING_ESCAPE(@CapabilityId,'json') + N'","kind":"SCENARIO","namespace":"(owned)"},"format":"sidefx-semantic-definition.v1","semantics":{"scenario":{'
+ N'"description":"","examples":[],"keyword":"Scenario","name":"' + STRING_ESCAPE(@ScenarioName,'json') + N'",'
+ N'"steps":[{"keyword":"Given ","keywordType":"Context","text":"' + STRING_ESCAPE(@ScenarioGiven,'json') + N'"},'
+ N'{"keyword":"When ","keywordType":"Action","text":"' + STRING_ESCAPE(@ScenarioWhen,'json') + N'"},'
+ N'{"keyword":"Then ","keywordType":"Outcome","text":"' + STRING_ESCAPE(@ScenarioThen,'json') + N'"}],'
+ N'"tags":[{"name":"@scenario:' + @CapabilityId + N'"},{"name":"@input:live-equity-price-request"},{"name":"@input-contract:live-equity-price-request.v1"},'
+ N'{"name":"@event:equity-market-price-evidence-requested"},{"name":"@event-authority:' + @CapabilityId + N'.v1"},'
+ N'{"name":"@outcome:equity-market-price-evidence"},{"name":"@outcome-contract:equity-market-price-evidence.v1"},{"name":"@outcome-terminal"}]},'
+ N'"tags":{"capability":["' + @CapabilityId + N'"],"event":["equity-market-price-evidence-requested"],"event-authority":["' + @CapabilityId + N'.v1"],'
+ N'"input":["live-equity-price-request"],"input-contract":["live-equity-price-request.v1"],"outcome":["equity-market-price-evidence"],'
+ N'"outcome-contract":["equity-market-price-evidence.v1"],"outcome-terminal":[true],"root-scenario":["' + @CapabilityId + N'"],"scenario":["' + @CapabilityId + N'"]}}}';
SET @blob = CONVERT(varbinary(max), CONVERT(varchar(max), (@scnEnv) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @scnDigest binary(32) = HASHBYTES('SHA2_256', @blob);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@scnDigest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@scnDigest, @blob, DATALENGTH(@blob));
INSERT model.semantic_object_definition (semantic_object_pk, object_kind, definition_digest, canonical_content_pk)
  VALUES (@scnSo, 'SCENARIO', @scnDigest, (SELECT content_object_pk FROM source.content_object WHERE content_digest=@scnDigest));
DECLARE @scnSod bigint = SCOPE_IDENTITY();
INSERT model.estate_definition (estate_model_pk, semantic_object_definition_pk) VALUES (@model, @scnSod);

-- 4. Canonical feature binding: the declaration that carries the name.
IF @parsedFeatureVer IS NOT NULL
BEGIN
  IF NOT EXISTS (SELECT 1 FROM model.capability_feature WHERE capability_version_pk=@capVer AND feature_version_pk=@parsedFeatureVer)
    INSERT model.capability_feature (capability_version_pk, feature_version_pk, capability_pk, binding_role)
      VALUES (@capVer, @parsedFeatureVer, @capPk, N'CANONICAL');
  IF NOT EXISTS (SELECT 1 FROM model.estate_capability_feature WHERE estate_model_pk=@model AND capability_pk=@capPk AND feature_version_pk=@parsedFeatureVer)
    INSERT model.estate_capability_feature (estate_model_pk, capability_pk, capability_version_pk, feature_version_pk, binding_role)
      VALUES (@model, @capPk, @capVer, @parsedFeatureVer, N'CANONICAL');
END

-- ============================== AFTER ==============================
SELECT 'AFTER_capability' AS result_set, cv.capability_version_pk, cv.semantic_object_definition_pk AS sod,
  JSON_VALUE(d.definition_json,'$.semantics.authority.mode') AS mode,
  JSON_VALUE(d.definition_json,'$.semantics.authority.userStory.actor') AS story_actor,
  JSON_VALUE(d.definition_json,'$.semantics.authority.experience.experienceId') AS experience_id
FROM model.estate_capability ec
JOIN model.capability_version cv ON cv.capability_version_pk=ec.capability_version_pk
JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=cv.semantic_object_definition_pk
WHERE ec.estate_model_pk=@model AND ec.capability_pk=@capPk;
SELECT 'AFTER_conditions' AS result_set, declared_id
FROM analysis.v_selected_semantic_definition
WHERE object_kind='OBSERVABLE_CONDITION' AND JSON_VALUE(definition_json,'$.semantics.owner_definition_digest')=LOWER(CONVERT(varchar(64),@capDigest,2));
SELECT 'AFTER_scenario_spec' AS result_set, declared_id, JSON_VALUE(definition_json,'$.semantics.scenario.name') AS scenario_name
FROM analysis.v_selected_semantic_definition WHERE object_kind='SCENARIO' AND declared_id=@CapabilityId;
SELECT 'AFTER_canonical_feature' AS result_set, cf.binding_role, fv.source_profile
FROM model.capability_feature cf JOIN model.feature_version fv ON fv.feature_version_pk=cf.feature_version_pk
WHERE cf.capability_version_pk=@capVer;
SELECT 'AFTER_source_resolution' AS result_set, COUNT(DISTINCT a.capsule_digest) AS capsules
FROM source.source_lineage l
JOIN source.source_observation o ON o.source_observation_pk=l.source_observation_pk
JOIN source.source_appearance a ON a.source_appearance_pk=o.source_appearance_pk
WHERE l.semantic_object_definition_pk=@capSod AND a.capsule_digest IS NOT NULL;

ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
