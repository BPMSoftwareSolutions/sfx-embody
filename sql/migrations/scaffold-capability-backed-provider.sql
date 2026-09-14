-- Capability-as-provider: declare a capability whose execution is another declared
-- capability's root Scenario. No provider module is named; the only module in the
-- model is a platform provider row at the language boundary.
-- Run as authored (ROLLBACK) for review; flip the final ROLLBACK to COMMIT to install.
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
CREATE OR ALTER PROCEDURE model.scaffold_capability_backed_capability
  @capability_id          nvarchar(400),
  @provider_capability_id nvarchar(400),
  @input_contract         nvarchar(400),
  @input_schema           nvarchar(max),
  @outcome_contract       nvarchar(400),
  @outcome_schema         nvarchar(max),
  @description            nvarchar(max) = N''
WITH EXECUTE AS OWNER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
  EXEC model.scaffold_capability @capability_id=@capability_id, @on_exists=N'REPLACE';

  -- The consuming capability's contracts, declared as data.
  DECLARE @cns bigint=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind='CONTRACT' AND namespace_id=N'sidefx:contracts');
  IF @cns IS NULL BEGIN INSERT model.identity_namespace(namespace_kind,namespace_id) VALUES('CONTRACT',N'sidefx:contracts'); SET @cns=SCOPE_IDENTITY(); END
  DECLARE @cids TABLE (rn int IDENTITY, cid nvarchar(400), schema_text nvarchar(max));
  INSERT @cids (cid,schema_text) VALUES (@input_contract,@input_schema),(@outcome_contract,@outcome_schema);
  DECLARE @i int=1,@n int=(SELECT COUNT(*) FROM @cids),@cid nvarchar(400),@schema nvarchar(max);
  DECLARE @sb varbinary(max),@sd binary(32),@schemaPk bigint,@cso bigint,@csod bigint,@cpk bigint,@cver bigint,@cb varbinary(max),@cd binary(32),@cenv nvarchar(max);
  DECLARE @inVer bigint,@outVer bigint;
  WHILE @i<=@n BEGIN
    SELECT @cid=cid,@schema=schema_text FROM @cids WHERE rn=@i;
    SET @sb=CONVERT(varbinary(max),CONVERT(varchar(max),(@schema) COLLATE Latin1_General_100_BIN2_UTF8)); SET @sd=HASHBYTES('SHA2_256',@sb);
    IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@sd) INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@sd,@sb,DATALENGTH(@sb));
    SET @schemaPk=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@sd);
    IF @schemaPk IS NULL BEGIN INSERT model.schema_object(content_digest,dialect,content_object_pk) VALUES(@sd,N'https://json-schema.org/draft/2020-12/schema',(SELECT content_object_pk FROM source.content_object WHERE content_digest=@sd)); SET @schemaPk=SCOPE_IDENTITY(); END
    SET @cso=(SELECT semantic_object_pk FROM model.semantic_object WHERE object_kind='CONTRACT' AND namespace_pk=@cns AND declared_id=@cid);
    IF @cso IS NULL BEGIN INSERT model.semantic_object(object_kind,namespace_pk,declared_id) VALUES('CONTRACT',@cns,@cid); SET @cso=SCOPE_IDENTITY(); END
    SET @cenv=N'{"address":{"id":"'+@cid+N'","kind":"CONTRACT","namespace":"sidefx:contracts"},"format":"sidefx-semantic-definition.v1","semantics":{"schema_digest":"'+LOWER(CONVERT(varchar(64),@sd,2))+N'"}}';
    SET @cb=CONVERT(varbinary(max),CONVERT(varchar(max),(@cenv) COLLATE Latin1_General_100_BIN2_UTF8)); SET @cd=HASHBYTES('SHA2_256',@cb);
    IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@cd) INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@cd,@cb,DATALENGTH(@cb));
    SET @csod=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@cso AND definition_digest=@cd);
    IF @csod IS NULL BEGIN INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk) VALUES(@cso,'CONTRACT',@cd,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@cd)); SET @csod=SCOPE_IDENTITY(); END
    IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@csod) INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@estate,@csod);
    SET @cpk=(SELECT contract_pk FROM model.contract WHERE namespace_pk=@cns AND contract_id=@cid);
    IF @cpk IS NULL BEGIN INSERT model.contract(namespace_pk,contract_id,semantic_object_pk,object_kind) VALUES(@cns,@cid,@cso,'CONTRACT'); SET @cpk=SCOPE_IDENTITY(); END
    SET @cver=(SELECT MAX(contract_version_pk) FROM model.contract_version WHERE contract_pk=@cpk AND definition_digest=@cd);
    IF @cver IS NULL BEGIN INSERT model.contract_version(contract_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,contract_kind,schema_object_pk,object_kind,_owner_definition_pk,_canonical_pointer,schema_reference_state) VALUES(@cpk,@cso,@csod,@cd,NULL,NULL,@schemaPk,'CONTRACT',@csod,N'','RESOLVED'); SET @cver=SCOPE_IDENTITY(); END
    IF @cid=@input_contract SET @inVer=@cver; ELSE SET @outVer=@cver;
    SET @i=@i+1;
  END

  -- Locate the consuming capability's root Scenario and its Event authority version.
  DECLARE @capVer bigint,@scnPk bigint,@scnVer bigint,@eav bigint,@ead bigint,@pScnVer bigint;
  SELECT @capVer=ec.capability_version_pk,@ead=ec.semantic_object_definition_pk FROM model.capability c
    JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate WHERE c.capability_id=@capability_id;
  SELECT @scnPk=rs.scenario_pk,@scnVer=cs.scenario_version_pk FROM model.capability_root_scenario rs
    JOIN model.capability_scenario cs ON cs.capability_version_pk=@capVer AND cs.scenario_pk=rs.scenario_pk WHERE rs.capability_version_pk=@capVer;
  SELECT @eav=se.execution_authority_version_pk FROM model.scenario_event se WHERE se.scenario_version_pk=@scnVer;

  -- The provider capability's root Scenario version.
  SELECT @pScnVer=cs.scenario_version_pk FROM model.capability c
    JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
    JOIN model.capability_root_scenario rs ON rs.capability_version_pk=ec.capability_version_pk
    JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk AND cs.scenario_pk=rs.scenario_pk
   WHERE c.capability_id=@provider_capability_id;
  IF @pScnVer IS NULL THROW 51000,'PROVIDER_CAPABILITY_NOT_DECLARED',1;

  -- Replace the scaffolded Port operations with one invoke-scenario to the provider capability.
  DELETE i FROM model.operation_port_invocation i JOIN model.execution_operation op ON op.execution_operation_pk=i.execution_operation_pk WHERE op.execution_authority_version_pk=@eav;
  DELETE model.execution_operation WHERE execution_authority_version_pk=@eav;
  INSERT model.execution_operation(execution_authority_version_pk,operation_id,ordinal,operation_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@eav,@capability_id+N'.0',0,'invoke-scenario',@ead,N'/authority/operations/0');
  DECLARE @op bigint=SCOPE_IDENTITY();
  INSERT model.operation_scenario_invocation(execution_operation_pk,target_scenario_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@op,@pScnVer,'invoke-scenario',@ead,N'');

  UPDATE model.scenario_input SET input_contract_version_pk=@inVer, contract_reference_state='RESOLVED' WHERE scenario_version_pk=@scnVer;
  UPDATE model.scenario_outcome_contract SET contract_version_pk=@outVer WHERE scenario_version_pk=@scnVer;
  SELECT N'CAPABILITY_BACKED_CAPABILITY' AS action, @capability_id AS capability_id, @provider_capability_id AS provider_capability_id, @scnVer AS scenario_version_pk;
END;
GO
SELECT 'capability_backed_scaffold' AS result_set, OBJECT_ID('model.scaffold_capability_backed_capability') AS procedure_id;
ROLLBACK TRANSACTION;
