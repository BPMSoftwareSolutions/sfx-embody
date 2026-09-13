-- construct-embodiment-plan.sql
--
-- Declares `construct-embodiment-plan` as the long-form composition: the read
-- capability's retained-authority declaration is composed before the plan
-- capability, so the embodiment plan is produced by two declared capabilities
-- rather than by one provider that reads and plans.
--
--   input (capability identity) --read--> authority declaration --plan--> plan
--
-- Default: ROLLBACK. Replace with COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
DECLARE @capId nvarchar(400) = N'construct-embodiment-plan';
DECLARE @model bigint = (SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
EXEC model.scaffold_capability @capability_id=@capId, @on_exists=N'REPLACE';

DECLARE @capPk bigint, @capSo bigint, @capVer bigint, @capSod bigint, @scnPk bigint, @scnVer bigint, @featPk bigint, @featSo bigint;
SELECT @capPk=c.capability_pk, @capSo=c.semantic_object_pk, @featPk=c.feature_pk FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=@capId;
SELECT @capVer=capability_version_pk, @capSod=semantic_object_definition_pk FROM model.estate_capability WHERE estate_model_pk=@model AND capability_pk=@capPk;
SELECT @scnPk=rs.scenario_pk, @scnVer=cs.scenario_version_pk FROM model.capability_root_scenario rs JOIN model.capability_scenario cs ON cs.capability_pk=@capPk AND cs.capability_version_pk=@capVer AND cs.scenario_pk=rs.scenario_pk WHERE rs.capability_version_pk=@capVer;
SELECT @featSo=semantic_object_pk FROM model.feature WHERE feature_pk=@featPk;

-- Contracts: the request selection and the content-addressed plan.
DECLARE @cns bigint=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='CONTRACT' AND namespace_id=N'sidefx:contracts');
IF @cns IS NULL BEGIN INSERT model.identity_namespace (namespace_kind,namespace_id) VALUES ('CONTRACT',N'sidefx:contracts'); SET @cns=SCOPE_IDENTITY(); END
DECLARE @reqId nvarchar(400)=N'construct-embodiment-plan-request.v1';
DECLARE @reqSchema nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/construct-embodiment-plan-request.v1.schema.json","title":"Construct Embodiment Plan Request","type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","enum":["node"]}}}';
DECLARE @outId nvarchar(400)=N'capability-embodiment-plan.v1';
DECLARE @outSchema nvarchar(max)=N'{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://schemas.agentic-harness.local/contracts/capability-embodiment-plan.v1.schema.json","title":"Capability Embodiment Plan","type":"object","additionalProperties":false,"required":["contractId","capabilityId","scenarioId","target","planDigest","artifactDigest","scenarioDefinitionDigest","platformDigest","resolverVersion","fileCount","files"],"properties":{"contractId":{"const":"capability-embodiment-plan.v1"},"capabilityId":{"type":"string","minLength":1},"scenarioId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"planDigest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"},"artifactDigest":{"type":"string","minLength":1},"scenarioDefinitionDigest":{"type":"string","minLength":1},"platformDigest":{"type":"string","minLength":1},"resolverVersion":{"type":"string","minLength":1},"fileCount":{"type":"integer","minimum":1},"files":{"type":"array","minItems":1,"items":{"type":"object","additionalProperties":false,"required":["relativePath","digest"],"properties":{"relativePath":{"type":"string","minLength":1},"digest":{"type":"string","pattern":"^sha256:[a-f0-9]{64}$"},"sourcePointers":{"type":"array","items":{"type":"string"}}}}}}}';
DECLARE @cids TABLE (rn int IDENTITY, cid nvarchar(400), schema_text nvarchar(max));
INSERT @cids (cid, schema_text) VALUES (@reqId,@reqSchema),(@outId,@outSchema);
DECLARE @i int=1, @n int=(SELECT COUNT(*) FROM @cids), @cid nvarchar(400), @schema nvarchar(max), @schemaPk bigint, @cso bigint, @csod bigint, @cpk bigint, @cver bigint, @sb varbinary(max), @sd binary(32), @cd binary(32), @cb varbinary(max), @cenv nvarchar(max);
DECLARE @reqVer bigint, @outVer bigint;
WHILE @i<=@n
BEGIN
  SELECT @cid=cid, @schema=schema_text FROM @cids WHERE rn=@i;
  SET @sb=CONVERT(varbinary(max),CONVERT(varchar(max),(@schema) COLLATE Latin1_General_100_BIN2_UTF8)); SET @sd=HASHBYTES('SHA2_256',@sb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@sd) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@sd,@sb,DATALENGTH(@sb));
  SET @schemaPk=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@sd);
  IF @schemaPk IS NULL BEGIN INSERT model.schema_object (content_digest,dialect,content_object_pk) VALUES (@sd,N'https://json-schema.org/draft/2020-12/schema',(SELECT content_object_pk FROM source.content_object WHERE content_digest=@sd)); SET @schemaPk=SCOPE_IDENTITY(); END
  SET @cso=(SELECT semantic_object_pk FROM model.semantic_object WHERE object_kind='CONTRACT' AND namespace_pk=@cns AND declared_id=@cid);
  IF @cso IS NULL BEGIN INSERT model.semantic_object (object_kind,namespace_pk,declared_id) VALUES ('CONTRACT',@cns,@cid); SET @cso=SCOPE_IDENTITY(); END
  SET @cenv=N'{"address":{"id":"'+@cid+N'","kind":"CONTRACT","namespace":"sidefx:contracts"},"format":"sidefx-semantic-definition.v1","semantics":{"schema_digest":"'+LOWER(CONVERT(varchar(64),@sd,2))+N'"}}';
  SET @cb=CONVERT(varbinary(max),CONVERT(varchar(max),(@cenv) COLLATE Latin1_General_100_BIN2_UTF8)); SET @cd=HASHBYTES('SHA2_256',@cb);
  IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@cd) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@cd,@cb,DATALENGTH(@cb));
  SET @csod=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@cso AND definition_digest=@cd);
  IF @csod IS NULL BEGIN INSERT model.semantic_object_definition (semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES (@cso,'CONTRACT',@cd,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@cd)); SET @csod=SCOPE_IDENTITY(); END
  IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@csod) INSERT model.estate_definition (estate_model_pk,semantic_object_definition_pk) VALUES (@model,@csod);
  SET @cpk=(SELECT contract_pk FROM model.contract WHERE namespace_pk=@cns AND contract_id=@cid);
  IF @cpk IS NULL BEGIN INSERT model.contract (namespace_pk,contract_id,semantic_object_pk,object_kind) VALUES (@cns,@cid,@cso,'CONTRACT'); SET @cpk=SCOPE_IDENTITY(); END
  SET @cver=(SELECT MAX(contract_version_pk) FROM model.contract_version WHERE contract_pk=@cpk AND definition_digest=@cd);
  IF @cver IS NULL BEGIN INSERT model.contract_version (contract_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,contract_kind,schema_object_pk,object_kind,_owner_definition_pk,_canonical_pointer,schema_reference_state) VALUES (@cpk,@cso,@csod,@cd,NULL,NULL,@schemaPk,'CONTRACT',@csod,N'','RESOLVED'); SET @cver=SCOPE_IDENTITY(); END
  IF @cid=@reqId SET @reqVer=@cver; ELSE SET @outVer=@cver;
  SET @i=@i+1;
END
UPDATE model.scenario_input SET input_contract_version_pk=@reqVer, contract_reference_state='RESOLVED' WHERE scenario_version_pk=@scnVer;
UPDATE model.scenario_outcome_contract SET contract_version_pk=@outVer WHERE scenario_version_pk=@scnVer;

-- Authority: compose the declared read capability then the declared plan capability.
DECLARE @eaPk bigint, @eaSo bigint;
SELECT @eaPk=ea.execution_authority_pk, @eaSo=ea.semantic_object_pk FROM model.execution_authority ea JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk WHERE n.namespace_id=N'sidefx:capability:'+@capId AND ea.execution_authority_id=@capId+N'.v1';
DECLARE @readScnVer bigint=(SELECT cs.scenario_version_pk FROM model.capability_scenario cs JOIN model.capability c ON c.capability_pk=cs.capability_pk JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=N'read-capability-authority');
DECLARE @planScnVer bigint=(SELECT cs.scenario_version_pk FROM model.capability_scenario cs JOIN model.capability c ON c.capability_pk=cs.capability_pk JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk WHERE n.namespace_id=N'sidefx:capabilities' AND c.capability_id=N'plan-capability-embodiment');
DECLARE @authEnv nvarchar(max)=N'{"address":{"id":"'+@capId+N'.v1","kind":"EXECUTION_AUTHORITY","namespace":"sidefx:capability:'+@capId+N'"},"format":"sidefx-semantic-definition.v1","semantics":{"authority":{"id":"'+@capId+N'.v1","operations":[{"kind":"invoke-scenario","scenarioId":"read-capability-authority"},{"kind":"invoke-scenario","scenarioId":"plan-capability-embodiment"}],"owningScenarioId":"'+@capId+N'"}}}';
DECLARE @ab varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@authEnv) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @ad binary(32)=HASHBYTES('SHA2_256',@ab);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@ad) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@ad,@ab,DATALENGTH(@ab));
DECLARE @authSod bigint=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@eaSo AND definition_digest=@ad);
IF @authSod IS NULL BEGIN INSERT model.semantic_object_definition (semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES (@eaSo,'EXECUTION_AUTHORITY',@ad,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@ad)); SET @authSod=SCOPE_IDENTITY(); END
IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@authSod) INSERT model.estate_definition (estate_model_pk,semantic_object_definition_pk) VALUES (@model,@authSod);
DECLARE @newEaVer bigint=(SELECT MAX(execution_authority_version_pk) FROM model.execution_authority_version WHERE execution_authority_pk=@eaPk AND definition_digest=@ad);
IF @newEaVer IS NULL
BEGIN
  INSERT model.execution_authority_version (execution_authority_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,authority_profile,object_kind,_owner_definition_pk,_canonical_pointer)
    VALUES (@eaPk,@eaSo,@authSod,@ad,N'execution-authorities.v1','EXECUTION_AUTHORITY',@authSod,N'');
  SET @newEaVer=SCOPE_IDENTITY();
  INSERT model.execution_operation (execution_authority_version_pk,operation_id,ordinal,operation_kind,_owner_definition_pk,_canonical_pointer)
    VALUES (@newEaVer,NULL,0,'invoke-scenario',@authSod,N'/semantics/authority/operations/0'),(@newEaVer,NULL,1,'invoke-scenario',@authSod,N'/semantics/authority/operations/1');
  INSERT model.operation_scenario_invocation (execution_operation_pk,target_scenario_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
    SELECT eo.execution_operation_pk, CASE eo.ordinal WHEN 0 THEN @readScnVer ELSE @planScnVer END, 'invoke-scenario', @authSod, eo._canonical_pointer
    FROM model.execution_operation eo WHERE eo.execution_authority_version_pk=@newEaVer;
END
UPDATE model.scenario_event SET execution_authority_version_pk=@newEaVer WHERE scenario_version_pk=@scnVer;

-- Feature.
DECLARE @text nvarchar(max)=N'@capability:'+@capId+N'
@root-scenario:'+@capId+N'
Feature: Construct an embodiment plan for a capability identity

  A capability identity and target are read as retained authority, then planned
  into one content-addressed embodiment plan. The composition declares the read
  capability before the plan capability; nothing is written.

  @scenario:'+@capId+N'
  @input:construct-embodiment-plan-request
  @input-contract:'+@reqId+N'
  @event:'+@capId+N'-requested
  @event-authority:'+@capId+N'.v1
  @outcome:capability-embodiment-plan
  @outcome-contract:'+@outId+N'
  @outcome-terminal
  Scenario: Compose the read capability before the plan capability
    Given a capability identity and a target
    When the retained authority is read and planned
    Then the content-addressed embodiment plan is returned
';
DECLARE @tb varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@text) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @td binary(32)=HASHBYTES('SHA2_256',@tb);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@td) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@td,@tb,DATALENGTH(@tb));
DECLARE @fenv nvarchar(max)=N'{"address":{"id":"'+@capId+N'","kind":"FEATURE","namespace":"sidefx:features"},"format":"sidefx-semantic-definition.v1","semantics":{"name":"Construct embodiment plan","description":"Compose the read capability before the plan capability.","content_digest":"'+LOWER(CONVERT(varchar(64),@td,2))+N'","source_path":"features/'+@capId+N'.feature","scenarios":[{"scenarioId":"'+@capId+N'","scenarioVersionPk":'+CONVERT(nvarchar(20),@scnVer)+N'}]}}';
DECLARE @fb varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),(@fenv) COLLATE Latin1_General_100_BIN2_UTF8));
DECLARE @fd binary(32)=HASHBYTES('SHA2_256',@fb);
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@fd) INSERT source.content_object (content_digest,content_bytes,byte_length) VALUES (@fd,@fb,DATALENGTH(@fb));
DECLARE @featSod bigint=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@featSo AND definition_digest=@fd);
IF @featSod IS NULL BEGIN INSERT model.semantic_object_definition (semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES (@featSo,'FEATURE',@fd,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@fd)); SET @featSod=SCOPE_IDENTITY(); END
IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@model AND semantic_object_definition_pk=@featSod) INSERT model.estate_definition (estate_model_pk,semantic_object_definition_pk) VALUES (@model,@featSod);
INSERT model.feature_version (feature_pk,capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,source_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES (@featPk,@capPk,@featSo,@featSod,@fd,@capId,'parsed-feature-declaration.v1','FEATURE',@featSod,N'');
DECLARE @featVer bigint=SCOPE_IDENTITY();
INSERT model.feature_scenario (feature_version_pk,scenario_pk,scenario_version_pk,capability_pk,ordinal) VALUES (@featVer,@scnPk,@scnVer,@capPk,0);
IF EXISTS (SELECT 1 FROM model.estate_capability_feature WHERE estate_model_pk=@model AND capability_pk=@capPk)
  UPDATE model.estate_capability_feature SET capability_version_pk=@capVer, feature_version_pk=@featVer, binding_role='CANONICAL' WHERE estate_model_pk=@model AND capability_pk=@capPk;
ELSE
  INSERT model.estate_capability_feature (estate_model_pk,capability_pk,capability_version_pk,feature_version_pk,binding_role) VALUES (@model,@capPk,@capVer,@featVer,'CANONICAL');

SELECT '1_compose' AS result_set, @capId AS capability_id, @capVer AS capability_version_pk, @scnVer AS scenario_version_pk, @newEaVer AS execution_authority_version_pk, @readScnVer AS read_scenario_version, @planScnVer AS plan_scenario_version;
SELECT '2_operations' AS result_set, eo.ordinal, eo.operation_kind, ts.scenario_id AS target_scenario
FROM model.execution_operation eo
JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
WHERE eo.execution_authority_version_pk=@newEaVer
ORDER BY eo.ordinal;
ROLLBACK TRANSACTION;
-- To install, replace the ROLLBACK above with COMMIT and re-run.
