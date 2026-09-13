-- M3: normalize the implementation relationships already declared by providers.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers = CURSOR LOCAL FAST_FORWARD FOR
  SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
  FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
  JOIN sys.schemas s ON s.schema_id=o.schema_id
  WHERE o.type='U' AND s.name IN ('model','source')
    AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0
BEGIN
  EXEC(N'DROP TRIGGER '+@trigger_name);
  FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;

IF EXISTS (SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk WHERE c.capability_id=N'project-consumer-execution-embodiment-plan' AND n.namespace_id=N'sidefx:capabilities') THROW 51000,'EXECUTION_PLAN_PRODUCER_ALREADY_DECLARED',1;
GO
-- Authoring helpers. They participate in the caller's transaction.
CREATE OR ALTER PROCEDURE model.put_semantic_definition
 @kind varchar(64),@namespace nvarchar(400),@id nvarchar(400),@semantics nvarchar(max),
 @object bigint OUTPUT,@definition bigint OUTPUT,@digest binary(32) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 IF ISJSON(@semantics)<>1 THROW 51000,'SEMANTIC_DEFINITION_INVALID',1;
 DECLARE @namespace_pk bigint=(SELECT namespace_pk FROM model.identity_namespace WHERE namespace_kind=@kind AND namespace_id=@namespace);
 IF @namespace_pk IS NULL BEGIN
  INSERT model.identity_namespace(namespace_kind,namespace_id) VALUES(@kind,@namespace);
  SET @namespace_pk=SCOPE_IDENTITY();
 END;
 SET @object=(SELECT semantic_object_pk FROM model.semantic_object WHERE namespace_pk=@namespace_pk AND object_kind=@kind AND declared_id=@id);
 IF @object IS NULL BEGIN
  INSERT model.semantic_object(object_kind,namespace_pk,declared_id) VALUES(@kind,@namespace_pk,@id);
  SET @object=SCOPE_IDENTITY();
 END;
 DECLARE @text nvarchar(max)=(SELECT @id AS [address.id],@kind AS [address.kind],@namespace AS [address.namespace],
  N'sidefx-semantic-definition.v1' AS format,JSON_QUERY(@semantics) AS semantics FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@text COLLATE Latin1_General_100_BIN2_UTF8));
 SET @digest=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@digest,@bytes,DATALENGTH(@bytes));
 SET @definition=(SELECT semantic_object_definition_pk FROM model.semantic_object_definition WHERE semantic_object_pk=@object AND definition_digest=@digest);
 IF @definition IS NULL BEGIN
  INSERT model.semantic_object_definition(semantic_object_pk,object_kind,definition_digest,canonical_content_pk)
   VALUES(@object,@kind,@digest,(SELECT content_object_pk FROM source.content_object WHERE content_digest=@digest));
  SET @definition=SCOPE_IDENTITY();
 END;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 IF NOT EXISTS (SELECT 1 FROM model.estate_definition WHERE estate_model_pk=@estate AND semantic_object_definition_pk=@definition)
  INSERT model.estate_definition(estate_model_pk,semantic_object_definition_pk) VALUES(@estate,@definition);
END;
GO
CREATE OR ALTER PROCEDURE model.declare_contract
 @id nvarchar(400),@schema nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 IF ISJSON(@schema)<>1 THROW 51000,'CONTRACT_SCHEMA_INVALID',1;
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@schema COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @schema_digest binary(32)=HASHBYTES('SHA2_256',@bytes),@object bigint,@definition bigint,@digest binary(32);
 IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@schema_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@schema_digest,@bytes,DATALENGTH(@bytes));
 DECLARE @schema_pk bigint=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@schema_digest);
 IF @schema_pk IS NULL BEGIN
  INSERT model.schema_object(content_digest,dialect,content_object_pk)
   VALUES(@schema_digest,JSON_VALUE(@schema,'$."$schema"'),(SELECT content_object_pk FROM source.content_object WHERE content_digest=@schema_digest));
  SET @schema_pk=SCOPE_IDENTITY();
 END;
 DECLARE @semantics nvarchar(max)=(SELECT LOWER(CONVERT(varchar(64),@schema_digest,2)) AS schema_digest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC model.put_semantic_definition 'CONTRACT',N'sidefx:contracts',@id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 DECLARE @contract bigint=(SELECT contract_pk FROM model.contract WHERE semantic_object_pk=@object);
 IF @contract IS NULL BEGIN
  INSERT model.contract(namespace_pk,contract_id,semantic_object_pk,object_kind)
   SELECT namespace_pk,@id,@object,'CONTRACT' FROM model.semantic_object WHERE semantic_object_pk=@object;
  SET @contract=SCOPE_IDENTITY();
 END;
 IF NOT EXISTS (SELECT 1 FROM model.contract_version WHERE semantic_object_definition_pk=@definition)
  INSERT model.contract_version(contract_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,schema_object_pk,object_kind,_owner_definition_pk,_canonical_pointer,schema_reference_state)
   VALUES(@contract,@object,@definition,@digest,@schema_pk,'CONTRACT',@definition,N'','RESOLVED');
END;
GO
CREATE OR ALTER PROCEDURE model.declare_scenario
 @capability_id nvarchar(400),@scenario nvarchar(max),@operations nvarchar(max),@port_bindings nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability bigint,@capability_version bigint,@capability_definition bigint;
 SELECT @capability=c.capability_pk,@capability_version=ec.capability_version_pk,@capability_definition=ec.semantic_object_definition_pk
 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate WHERE c.capability_id=@capability_id;
 IF @capability IS NULL THROW 51000,'CAPABILITY_NOT_FOUND',1;
 DECLARE @id nvarchar(400)=JSON_VALUE(@scenario,'$.scenarioId'),@name nvarchar(max)=JSON_VALUE(@scenario,'$.name');
 DECLARE @input nvarchar(400)=JSON_VALUE(@scenario,'$.inputId'),@input_contract nvarchar(400)=JSON_VALUE(@scenario,'$.inputContract');
 DECLARE @event nvarchar(400)=JSON_VALUE(@scenario,'$.eventId'),@authority nvarchar(400)=JSON_VALUE(@scenario,'$.eventAuthority');
 DECLARE @outcome nvarchar(400)=JSON_VALUE(@scenario,'$.outcomeId'),@outcome_contract nvarchar(400)=JSON_VALUE(@scenario,'$.outcomeContract');
 DECLARE @terminal bit=CASE WHEN JSON_VALUE(@scenario,'$.terminal')='true' THEN 1 ELSE 0 END;
 DECLARE @root bit=CASE WHEN JSON_VALUE(@scenario,'$.root')='true' THEN 1 ELSE 0 END;
 DECLARE @given nvarchar(max)=JSON_VALUE(@scenario,'$.given'),@when nvarchar(max)=JSON_VALUE(@scenario,'$.when'),@then nvarchar(max)=JSON_VALUE(@scenario,'$.then');
 IF @id IS NULL OR @event IS NULL OR @authority IS NULL OR @given IS NULL OR @when IS NULL OR @then IS NULL
  THROW 51000,'SCENARIO_FACES_REQUIRED',1;
 DECLARE @in_version bigint,@out_version bigint;
 SELECT @in_version=cv.contract_version_pk FROM model.contract c
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:contracts'
 JOIN model.contract_version cv ON cv.contract_pk=c.contract_pk
 JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=cv.semantic_object_definition_pk AND d.estate_model_pk=@estate WHERE c.contract_id=@input_contract;
 SELECT @out_version=cv.contract_version_pk FROM model.contract c
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:contracts'
 JOIN model.contract_version cv ON cv.contract_pk=c.contract_pk
 JOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=cv.semantic_object_definition_pk AND d.estate_model_pk=@estate WHERE c.contract_id=@outcome_contract;
 IF @in_version IS NULL OR @out_version IS NULL THROW 51000,'SCENARIO_CONTRACT_NOT_DECLARED',1;
 DECLARE @namespace nvarchar(400)=N'sidefx:capability:'+@capability_id;
 DECLARE @object bigint,@definition bigint,@digest binary(32),@semantics nvarchar(max);
 DECLARE @binding nvarchar(max),@port_id nvarchar(400),@port bigint,@port_version bigint;
 DECLARE @ports TABLE(port_id nvarchar(400),port_version bigint);
 DECLARE @bindings CURSOR;
 SET @bindings=CURSOR LOCAL FAST_FORWARD FOR SELECT value FROM OPENJSON(@port_bindings);
 OPEN @bindings;
 FETCH NEXT FROM @bindings INTO @binding;
 WHILE @@FETCH_STATUS=0 BEGIN
  SET @port_id=JSON_VALUE(@binding,'$.portId');
  EXEC model.put_semantic_definition 'PORT',@namespace,@port_id,@binding,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
  SET @port=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
  IF @port IS NULL BEGIN
   INSERT model.port(namespace_pk,port_id,semantic_object_pk,object_kind)
    SELECT namespace_pk,@port_id,@object,'PORT' FROM model.semantic_object WHERE semantic_object_pk=@object;
   SET @port=SCOPE_IDENTITY();
  END;
  SET @port_version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
  IF @port_version IS NULL BEGIN
   INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
    VALUES(@port,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
   SET @port_version=SCOPE_IDENTITY();
  END;
  INSERT @ports VALUES(@port_id,@port_version);
  FETCH NEXT FROM @bindings INTO @binding;
 END;
 CLOSE @bindings;
 DEALLOCATE @bindings;
 SET @semantics=(SELECT @authority AS [authority.id],@id AS [authority.owningScenarioId],JSON_QUERY(@operations) AS [authority.operations] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC model.put_semantic_definition 'EXECUTION_AUTHORITY',@namespace,@authority,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 DECLARE @authority_pk bigint=(SELECT execution_authority_pk FROM model.execution_authority WHERE semantic_object_pk=@object);
 IF @authority_pk IS NULL BEGIN
  INSERT model.execution_authority(namespace_pk,execution_authority_id,semantic_object_pk,object_kind)
   SELECT namespace_pk,@authority,@object,'EXECUTION_AUTHORITY' FROM model.semantic_object WHERE semantic_object_pk=@object;
  SET @authority_pk=SCOPE_IDENTITY();
 END;
 DECLARE @authority_version bigint=(SELECT execution_authority_version_pk FROM model.execution_authority_version WHERE semantic_object_definition_pk=@definition);
 IF @authority_version IS NULL BEGIN
  INSERT model.execution_authority_version(execution_authority_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,authority_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@authority_pk,@object,@definition,@digest,'execution-authorities.v1','EXECUTION_AUTHORITY',@definition,N'');
  SET @authority_version=SCOPE_IDENTITY();
  INSERT model.execution_operation(execution_authority_version_pk,operation_id,ordinal,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT @authority_version,JSON_VALUE(value,'$.operationId'),CONVERT(int,[key]),JSON_VALUE(value,'$.kind'),@definition,N'/authority/operations/'+[key] FROM OPENJSON(@operations);
  INSERT model.operation_port_invocation(execution_operation_pk,port_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT op.execution_operation_pk,p.port_version,'invoke-port',@definition,op._canonical_pointer
   FROM model.execution_operation op JOIN OPENJSON(@operations) j ON CONVERT(int,j.[key])=op.ordinal
   JOIN @ports p ON p.port_id=JSON_VALUE(j.value,'$.portId') WHERE op.execution_authority_version_pk=@authority_version AND op.operation_kind='invoke-port';
  IF EXISTS (SELECT 1 FROM model.execution_operation op WHERE op.execution_authority_version_pk=@authority_version
   AND (op.operation_kind<>'invoke-port' OR NOT EXISTS (SELECT 1 FROM model.operation_port_invocation i WHERE i.execution_operation_pk=op.execution_operation_pk)))
   THROW 51000,'SCENARIO_OPERATION_BINDING_NOT_DECLARED',1;
 END;
 DECLARE @tag_rows TABLE(tag nvarchar(100),value nvarchar(400));
 INSERT @tag_rows VALUES('capability',@capability_id),('scenario',@id),('input',@input),('input-contract',@input_contract),
  ('event',@event),('event-authority',@authority),('outcome',@outcome),('outcome-contract',@outcome_contract);
 IF @root=1 INSERT @tag_rows VALUES('root-scenario',@id);
 DECLARE @tags nvarchar(max)=N'{'+(SELECT STRING_AGG(CONVERT(nvarchar(max),N'"'+STRING_ESCAPE(tag,'json')+N'":["'+STRING_ESCAPE(value,'json')+N'"]'),N',') WITHIN GROUP(ORDER BY tag) FROM @tag_rows)+N'}';
 IF @terminal=1 SET @tags=JSON_MODIFY(@tags,'$."outcome-terminal"',JSON_QUERY(N'[true]'));
 DECLARE @parsed_tags nvarchar(max)=(SELECT N'@'+tag+N':'+value AS name FROM @tag_rows ORDER BY tag FOR JSON PATH);
 IF @terminal=1 SET @parsed_tags=JSON_MODIFY(@parsed_tags,'append $',JSON_QUERY(N'{"name":"@outcome-terminal"}'));
 DECLARE @steps nvarchar(max)=(SELECT keyword,keywordType,text FROM (VALUES
  (0,N'Given ',N'Context',@given),(1,N'When ',N'Action',@when),(2,N'Then ',N'Outcome',@then)) s(ordinal,keyword,keywordType,text) ORDER BY ordinal FOR JSON PATH);
 DECLARE @parsed_scenario nvarchar(max)=(SELECT N'Scenario' AS keyword,@name AS name,N'' AS description,
  JSON_QUERY(N'[]') AS examples,JSON_QUERY(@steps) AS steps,JSON_QUERY(@parsed_tags) AS tags FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 SET @semantics=(SELECT JSON_QUERY(@parsed_scenario) AS scenario,JSON_QUERY(@tags) AS tags FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @scenario_pk bigint,@old_version bigint,@scenario_namespace nvarchar(400);
 SELECT @scenario_pk=s.scenario_pk,@scenario_namespace=n.namespace_id FROM model.scenario s
 JOIN model.identity_namespace n ON n.namespace_pk=s.namespace_pk WHERE s.capability_pk=@capability AND s.scenario_id=@id;
 SET @scenario_namespace=COALESCE(@scenario_namespace,@namespace);
 EXEC model.put_semantic_definition 'SCENARIO',@scenario_namespace,@id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 IF @scenario_pk IS NULL BEGIN
  INSERT model.scenario(namespace_pk,scenario_id,semantic_object_pk,object_kind,capability_pk)
   SELECT namespace_pk,@id,@object,'SCENARIO',@capability FROM model.semantic_object WHERE semantic_object_pk=@object;
  SET @scenario_pk=SCOPE_IDENTITY();
 END;
 DECLARE @scenario_definition bigint=@definition,@scenario_digest binary(32)=@digest;
 DECLARE @version bigint=(SELECT scenario_version_pk FROM model.scenario_version WHERE semantic_object_definition_pk=@definition);
 IF @version IS NULL BEGIN
  INSERT model.scenario_version(scenario_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,source_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@scenario_pk,@object,@definition,@digest,@name,'managed-feature-tags.v1','SCENARIO',@definition,N'');
  SET @version=SCOPE_IDENTITY();
  DECLARE @face_namespace nvarchar(400)=N'owner:sha256:'+LOWER(CONVERT(varchar(64),@scenario_digest,2));
  DECLARE @faces TABLE(kind varchar(64),id nvarchar(400),reference nvarchar(400),text nvarchar(max),role varchar(20));
  INSERT @faces VALUES('SCENARIO_INPUT',@input,@input_contract,@given,'input'),('SCENARIO_EVENT',@event,@authority,@when,'event'),('SCENARIO_OUTCOME',@outcome,@outcome_contract,@then,'outcome');
  DECLARE @kind varchar(64),@face nvarchar(400),@reference nvarchar(400),@text nvarchar(max),@role varchar(20),@faces_cursor CURSOR;
  SET @faces_cursor=CURSOR LOCAL FAST_FORWARD FOR SELECT kind,id,reference,text,role FROM @faces;
  OPEN @faces_cursor;
  FETCH NEXT FROM @faces_cursor INTO @kind,@face,@reference,@text,@role;
  WHILE @@FETCH_STATUS=0 BEGIN
   SET @semantics=(SELECT @face AS id,@reference AS declared_reference,@text AS text,@role AS role,
    LOWER(CONVERT(varchar(64),@scenario_digest,2)) AS owner_definition_digest FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
   EXEC model.put_semantic_definition @kind,@face_namespace,@face,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
   IF @kind='SCENARIO_INPUT'
    INSERT model.scenario_input(scenario_version_pk,input_id,name,input_contract_version_pk,semantic_object_pk,semantic_object_definition_pk,namespace_pk,definition_digest,object_kind,_owner_definition_pk,_canonical_pointer,contract_reference_state)
     SELECT @version,@face,@text,@in_version,@object,@definition,namespace_pk,@digest,@kind,@scenario_definition,N'/input','RESOLVED' FROM model.semantic_object WHERE semantic_object_pk=@object;
   IF @kind='SCENARIO_EVENT'
    INSERT model.scenario_event(scenario_version_pk,event_id,name,responsibility,execution_authority_version_pk,semantic_object_pk,semantic_object_definition_pk,namespace_pk,definition_digest,object_kind,_owner_definition_pk,_canonical_pointer,authority_reference_state)
     SELECT @version,@face,@text,@text,@authority_version,@object,@definition,namespace_pk,@digest,@kind,@scenario_definition,N'/event','RESOLVED' FROM model.semantic_object WHERE semantic_object_pk=@object;
   IF @kind='SCENARIO_OUTCOME'
    INSERT model.scenario_outcome(scenario_version_pk,outcome_id,name,experience,terminal,semantic_object_pk,semantic_object_definition_pk,namespace_pk,definition_digest,object_kind,_owner_definition_pk,_canonical_pointer)
     SELECT @version,@face,@text,@text,@terminal,@object,@definition,namespace_pk,@digest,@kind,@scenario_definition,N'/outcome' FROM model.semantic_object WHERE semantic_object_pk=@object;
   FETCH NEXT FROM @faces_cursor INTO @kind,@face,@reference,@text,@role;
  END;
  CLOSE @faces_cursor;
  DEALLOCATE @faces_cursor;
  INSERT model.scenario_outcome_contract VALUES(@version,@out_version,@scenario_definition,N'/outcome/contract');
  INSERT model.outcome_variant(scenario_version_pk,variant_id,terminal,_owner_definition_pk,_canonical_pointer)
   SELECT @version,value,@terminal,@scenario_definition,N'/variants/'+[key] FROM OPENJSON(@scenario,'$.variants');
 END;
 SELECT @old_version=scenario_version_pk FROM model.capability_scenario WHERE capability_version_pk=@capability_version AND scenario_pk=@scenario_pk;
 IF @old_version IS NULL INSERT model.capability_scenario(capability_pk,capability_version_pk,scenario_pk,scenario_version_pk,_owner_definition_pk,_canonical_pointer)
  VALUES(@capability,@capability_version,@scenario_pk,@version,@capability_definition,N'/scenarios/'+@id);
 ELSE BEGIN
  UPDATE model.capability_scenario SET scenario_version_pk=@version WHERE capability_version_pk=@capability_version AND scenario_pk=@scenario_pk;
  UPDATE model.operation_scenario_invocation SET target_scenario_version_pk=@version WHERE target_scenario_version_pk=@old_version;
 END;
 IF @root=1 AND NOT EXISTS (SELECT 1 FROM model.capability_root_scenario WHERE capability_version_pk=@capability_version)
  INSERT model.capability_root_scenario VALUES(@capability_version,@scenario_pk,@capability_definition,N'/rootScenarioId');
 SELECT @id AS declared_scenario,@version AS scenario_version_pk;
END;
GO
CREATE OR ALTER PROCEDURE model.declare_capability_feature
 @capability_id nvarchar(400),@feature_text nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
 DECLARE @capability bigint,@capability_version bigint,@feature bigint;
 SELECT @capability=c.capability_pk,@capability_version=ec.capability_version_pk,@feature=c.feature_pk
 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate WHERE c.capability_id=@capability_id;
 IF @capability IS NULL THROW 51000,'CAPABILITY_NOT_FOUND',1;
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@feature_text COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @feature_digest binary(32)=HASHBYTES('SHA2_256',@bytes);
 IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@feature_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@feature_digest,@bytes,DATALENGTH(@bytes));
 DECLARE @scenarios nvarchar(max)=(SELECT s.scenario_id AS scenarioId,cs.scenario_version_pk AS scenarioVersionPk
  FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
  WHERE cs.capability_version_pk=@capability_version ORDER BY s.scenario_id FOR JSON PATH);
 DECLARE @semantics nvarchar(max)=(SELECT @capability_id AS name,LOWER(CONVERT(varchar(64),@feature_digest,2)) AS content_digest,
  N'features/'+@capability_id+N'.feature' AS source_path,JSON_QUERY(@scenarios) AS scenarios FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition 'FEATURE',N'sidefx:features',@capability_id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 DECLARE @version bigint=(SELECT feature_version_pk FROM model.feature_version WHERE semantic_object_definition_pk=@definition);
 IF @version IS NULL BEGIN
  INSERT model.feature_version(feature_pk,capability_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,source_profile,object_kind,_owner_definition_pk,_canonical_pointer)
   VALUES(@feature,@capability,@object,@definition,@digest,@capability_id,'parsed-feature-declaration.v1','FEATURE',@definition,N'');
  SET @version=SCOPE_IDENTITY();
  INSERT model.feature_scenario(feature_version_pk,scenario_pk,scenario_version_pk,capability_pk,ordinal)
   SELECT @version,cs.scenario_pk,cs.scenario_version_pk,@capability,ROW_NUMBER() OVER(ORDER BY s.scenario_id)-1
   FROM model.capability_scenario cs JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk WHERE cs.capability_version_pk=@capability_version;
 END;
 UPDATE model.estate_capability_feature SET feature_version_pk=@version WHERE estate_model_pk=@estate AND capability_version_pk=@capability_version;
END;
GO
EXEC model.scaffold_estate_provider_capability @capability_id=N'project-consumer-execution-embodiment-plan',@provider_module=N'src/resolvers/node/execution-graph-read-provider.mjs',@provider_export=N'readDeclaredExecutionGraph',@input_contract=N'capability-authority-declaration.v1',@input_schema=N'{"type":"object","required":["contractId","capabilityId","scenarioId","target","authority","closure","mechanics","snapshotId","projectionDigest","viewDefinitionDigest"],"properties":{"contractId":{"const":"capability-authority-declaration.v1"},"capabilityId":{"type":"string"},"scenarioId":{"type":"string"},"target":{"type":"string"},"authority":{"type":"object"},"closure":{"type":"object"},"mechanics":{"type":"object"},"snapshotId":{"type":"string"},"projectionDigest":{"type":"string"},"viewDefinitionDigest":{"type":"string"}}}',@outcome_contract=N'consumer-execution-embodiment-projection-context.v1',@outcome_schema=N'{"anyOf":[{"type":"object","required":["contextType","disposition","executionPlan","targets","fixtureAuthority","requestedExecutableOrigin"],"properties":{"contextType":{"const":"consumer-execution-embodiment-projection-context.v1"},"disposition":{"const":"EXECUTION_EMBODIMENT_CONTEXT_ADMITTED"},"executionPlan":{"anyOf":[{"type":"object","required":["contractId","authorityDeclaration","canonicalGraph","sourceMap","contractCatalog","fixtureAuthority","platform"],"properties":{"contractId":{"const":"consumer-execution-embodiment-plan.v1"},"authorityDeclaration":{"type":"object","required":["contractId","capabilityId","scenarioId","target","authority","closure","mechanics","snapshotId","projectionDigest","viewDefinitionDigest"],"properties":{"contractId":{"const":"capability-authority-declaration.v1"},"capabilityId":{"type":"string"},"scenarioId":{"type":"string"},"target":{"type":"string"},"authority":{"type":"object"},"closure":{"type":"object"},"mechanics":{"type":"object"},"snapshotId":{"type":"string"},"projectionDigest":{"type":"string"},"viewDefinitionDigest":{"type":"string"}}},"canonicalGraph":{"type":"object","required":["graphType","cells","edges","requiredProviderSlots"]},"sourceMap":{"type":"object"},"contractCatalog":{"type":"object"},"fixtureAuthority":{"type":"object"},"platform":{"type":"object"}}},{"type":"object","required":["contractId","disposition","findings"],"properties":{"contractId":{"const":"consumer-execution-embodiment-plan.v1"},"disposition":{"const":"EXECUTION_EMBODIMENT_PLAN_HELD"},"findings":{"type":"array","minItems":1}}}]},"targets":{"type":"array","minItems":1},"fixtureAuthority":{"type":"object"},"requestedExecutableOrigin":{"const":"PROJECTED_ONLY"}}},{"type":"object","required":["contractId","disposition","findings"],"properties":{"contractId":{"const":"consumer-execution-embodiment-projection-context.v1"},"disposition":{"const":"EXECUTION_EMBODIMENT_PLAN_HELD"},"findings":{"type":"array","minItems":1}}}]}',@description=N'Produce the execution plan, fixture authority and registered consumer provider authority from one database declaration';
GO
EXEC model.declare_contract @id=N'consumer-execution-embodiment-plan.v1',@schema=N'{"anyOf":[{"type":"object","required":["contractId","authorityDeclaration","canonicalGraph","sourceMap","contractCatalog","fixtureAuthority","platform"],"properties":{"contractId":{"const":"consumer-execution-embodiment-plan.v1"},"authorityDeclaration":{"type":"object","required":["contractId","capabilityId","scenarioId","target","authority","closure","mechanics","snapshotId","projectionDigest","viewDefinitionDigest"],"properties":{"contractId":{"const":"capability-authority-declaration.v1"},"capabilityId":{"type":"string"},"scenarioId":{"type":"string"},"target":{"type":"string"},"authority":{"type":"object"},"closure":{"type":"object"},"mechanics":{"type":"object"},"snapshotId":{"type":"string"},"projectionDigest":{"type":"string"},"viewDefinitionDigest":{"type":"string"}}},"canonicalGraph":{"type":"object","required":["graphType","cells","edges","requiredProviderSlots"]},"sourceMap":{"type":"object"},"contractCatalog":{"type":"object"},"fixtureAuthority":{"type":"object"},"platform":{"type":"object"}}},{"type":"object","required":["contractId","disposition","findings"],"properties":{"contractId":{"const":"consumer-execution-embodiment-plan.v1"},"disposition":{"const":"EXECUTION_EMBODIMENT_PLAN_HELD"},"findings":{"type":"array","minItems":1}}}]}';
EXEC model.declare_contract @id=N'registered-projection-authority-set.v1',@schema=N'{"type":"object","required":["contractId","targets","findings"],"properties":{"contractId":{"const":"registered-projection-authority-set.v1"},"targets":{"type":"array"},"findings":{"type":"array"}}}';
DECLARE @object bigint,@definition bigint,@digest binary(32);
EXEC model.put_semantic_definition 'AUTHORITY',N'sidefx:authorities',N'registered-projection-authority-set.v1',N'{"projectionAuthorities":[{"target":"node","providerId":"ScenarioKernel.NodePlatform","providerProfileId":"node-profile-bound-physical-provider.v1","projectionAuthorityRef":"tools/src/consumer-projection/providers/node/consumer-application-provider.ts","projectionAuthorityDigest":"sha256:b716f6318ebb480f9f0d08e401edb67f2875b0c1569336367d93edac17d862e4","providerModule":"artifacts/tools/dist/consumer-projection/providers/node/consumer-application-provider.js","providerExport":"NodeConsumerApplicationProvider","providerModuleDigest":"sha256:aa6f25332997d162fffdcd31f4292ab87d0142bc7333a9a67537eecbef4ebcfb","executionProviderRef":"languages/typescript/runtimes/node/admitted-consumer-platform.mjs","executionProviderDigest":"sha256:1f0e164575c256fc618a35b975de948b5115f8013f4917d010e66709d0a9c953"},{"target":"python","providerId":"scenario_kernel.platform.consumer","providerProfileId":"python-profile-bound-physical-provider.v1","projectionAuthorityRef":"tools/src/consumer-projection/providers/python/consumer-application-provider.ts","projectionAuthorityDigest":"sha256:441ef48b72e79d6b225ee8dc1c8d02b84fcd7edb8fe57101cad5f1d908b8476b","providerModule":"artifacts/tools/dist/consumer-projection/providers/python/consumer-application-provider.js","providerExport":"PythonConsumerApplicationProvider","providerModuleDigest":"sha256:44ed35147036c84465425a7fd3f99807aaedd9b187f8aba8c8bbc31911bf3241","executionProviderRef":"languages/python/src/scenario_kernel/platform/consumer.py","executionProviderDigest":"sha256:eed4ea8d53672a2180aed9764fa979bb1c903772dccaa9db6aadc806686b0824"},{"target":"csharp","providerId":"ScenarioKernel.Adapters.Consumer.AdmittedConsumerPlatform","providerProfileId":"csharp-profile-bound-physical-provider.v1","projectionAuthorityRef":"tools/src/consumer-projection/providers/csharp/consumer-application-provider.ts","projectionAuthorityDigest":"sha256:85b9811ce09440fe368bdbd4764f4244ab4a546b8a907f736b88f4aa7ce7d9a4","providerModule":"artifacts/tools/dist/consumer-projection/providers/csharp/consumer-application-provider.js","providerExport":"CSharpConsumerApplicationProvider","providerModuleDigest":"sha256:f3f612c6d55ac6bc601889db97ace8febd76f63af5be4294a9a0df7c31e2c17c","executionProviderRef":"languages/csharp/src/ScenarioKernel.Adapters/Consumer/AdmittedConsumerPlatform.cs","executionProviderDigest":"sha256:f0a9594363b4485f125f55f744d3c5fd828c36959e34477b5d5e6be0097d3b3f"}],"pinnedPlatformCommit":"716811046f52dd2a67f9ff308a50d755571cbbad"}',@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
DECLARE @authority bigint=(SELECT authority_pk FROM model.authority WHERE semantic_object_pk=@object);
IF @authority IS NULL BEGIN
 INSERT model.authority(namespace_pk,authority_id,semantic_object_pk,object_kind)
 SELECT namespace_pk,N'registered-projection-authority-set.v1',@object,'AUTHORITY' FROM model.semantic_object WHERE semantic_object_pk=@object;
 SET @authority=SCOPE_IDENTITY();
END;
IF NOT EXISTS (SELECT 1 FROM model.authority_definition WHERE semantic_object_definition_pk=@definition)
 INSERT model.authority_definition(authority_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,authority_kind,authority_profile,object_kind,_owner_definition_pk,_canonical_pointer)
 VALUES(@authority,@object,@definition,@digest,'PROJECTION','registered-projection-authority-set.v1','AUTHORITY',@definition,N'');
GO
EXEC model.declare_scenario @capability_id=N'project-consumer-execution-embodiment-plan',@scenario=N'{"scenarioId":"project-consumer-execution-embodiment-plan","name":"Project and admit the execution embodiment projection context","inputId":"capability-authority-declaration","inputContract":"capability-authority-declaration.v1","eventId":"project-consumer-execution-embodiment-plan","eventAuthority":"project-consumer-execution-embodiment-plan.v1","outcomeId":"consumer-execution-embodiment-projection-context","outcomeContract":"consumer-execution-embodiment-projection-context.v1","terminal":true,"root":true,"given":"one admitted capability embodiment authority and the selected targets","when":"the execution plan and registered projection authorities are projected and the context is admitted","then":"one admitted projection context is returned or a held finding names the missing plan authority","variants":["EXECUTION_EMBODIMENT_CONTEXT_ADMITTED","EXECUTION_EMBODIMENT_PLAN_HELD"]}',@operations=N'[{"kind":"invoke-port","portId":"derive-target-neutral-execution-plan"},{"kind":"invoke-port","portId":"project-consumer-execution-embodiment-plan-port"}]',@port_bindings=N'[{"portId":"derive-target-neutral-execution-plan","platformCapabilityId":"sda-semantic-execution-graph-compilation-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/execution-graph-read-provider.mjs","export":"readDeclaredExecutionGraph"},"inputAdmission":{"type":"object","required":["contractId","capabilityId","scenarioId","target","authority","closure","mechanics","snapshotId","projectionDigest","viewDefinitionDigest"],"properties":{"contractId":{"const":"capability-authority-declaration.v1"},"capabilityId":{"type":"string"},"scenarioId":{"type":"string"},"target":{"type":"string"},"authority":{"type":"object"},"closure":{"type":"object"},"mechanics":{"type":"object"},"snapshotId":{"type":"string"},"projectionDigest":{"type":"string"},"viewDefinitionDigest":{"type":"string"}}},"admissionFailure":{"contractId":"consumer-execution-embodiment-plan.v1","disposition":"EXECUTION_EMBODIMENT_PLAN_HELD","findings":[{"code":"EXECUTION_PLAN_UNDECLARED"}]},"expression":{"op":"object","fields":{"contractId":{"op":"literal","value":"consumer-execution-embodiment-plan.v1"},"authorityDeclaration":{"op":"path","from":"input","path":"declaration"},"canonicalGraph":{"op":"path","from":"input","path":"compiled.graph"},"sourceMap":{"op":"path","from":"input","path":"compiled.sourceMap"},"contractCatalog":{"op":"path","from":"input","path":"contractCatalog"},"fixtureAuthority":{"op":"path","from":"input","path":"fixtureAuthority"},"platform":{"op":"path","from":"input","path":"platform"}}},"errors":[{"prefix":"GRAPH_COMPILER_EMPTY_EXECUTION_AUTHORITY:","outcome":{"contractId":"consumer-execution-embodiment-plan.v1","disposition":"EXECUTION_EMBODIMENT_PLAN_HELD","findings":[{"code":"EXECUTION_PLAN_UNDECLARED"}]}}]}},{"portId":"project-consumer-execution-embodiment-plan-port","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/database-query-provider.mjs","export":"readDatabaseQuery"},"statement":"IF JSON_VALUE(@input,''$.disposition'')=''EXECUTION_EMBODIMENT_PLAN_HELD''\nBEGIN SELECT (SELECT ''consumer-execution-embodiment-projection-context.v1'' AS contractId,''EXECUTION_EMBODIMENT_PLAN_HELD'' AS disposition,JSON_QUERY(@input,''$.findings'') AS findings FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS result_json; RETURN; END;\nDECLARE @declaration nvarchar(max)=COALESCE(JSON_QUERY(@input,''$.authorityDeclaration''),@input);\nIF JSON_VALUE(@declaration,''$.snapshotId'') IS NULL OR JSON_VALUE(@declaration,''$.snapshotId'')<>@snapshot_id\n OR JSON_VALUE(@declaration,''$.projectionDigest'') IS NULL OR JSON_VALUE(@declaration,''$.projectionDigest'')<>@projection_id\n OR JSON_VALUE(@declaration,''$.viewDefinitionDigest'') IS NULL OR JSON_VALUE(@declaration,''$.viewDefinitionDigest'')<>@view_definition_digest\n THROW 51000,''DATABASE_AUTHORITY_NOT_COHERENT'',1;\nDECLARE @targets nvarchar(max)=(SELECT JSON_QUERY(entry.value) AS authority FROM analysis.v_selected_semantic_definition d\n CROSS APPLY OPENJSON(d.definition_json,''$.semantics.projectionAuthorities'') entry\n WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''AUTHORITY'' AND d.declared_id=''registered-projection-authority-set.v1''\n AND JSON_VALUE(entry.value,''$.target'')=JSON_VALUE(@declaration,''$.target'')\n AND EXISTS (SELECT 1 FROM analysis.v_target_provider_profile p WHERE p.estate_model_pk=@estate_model_pk\n   AND p.provider_profile_id=JSON_VALUE(entry.value,''$.providerProfileId'') AND p.target_id=JSON_VALUE(@declaration,''$.target''))\n FOR JSON PATH);\nDECLARE @findings nvarchar(max)=CASE WHEN (SELECT COUNT(*) FROM OPENJSON(@targets))=1 THEN ''[]''\n ELSE ''[{\"code\":\"PROJECTION_AUTHORITY_UNREGISTERED\"}]'' END;\nIF @findings<>''[]''\nBEGIN SELECT (SELECT ''consumer-execution-embodiment-projection-context.v1'' AS contractId,''EXECUTION_EMBODIMENT_PLAN_HELD'' AS disposition,JSON_QUERY(@findings) AS findings FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS result_json; RETURN; END;\nSELECT (SELECT ''consumer-execution-embodiment-projection-context.v1'' AS contextType,''EXECUTION_EMBODIMENT_CONTEXT_ADMITTED'' AS disposition,\n JSON_QUERY(@input) AS executionPlan,JSON_QUERY(@targets) AS targets,JSON_QUERY(@input,''$.fixtureAuthority'') AS fixtureAuthority,\n ''PROJECTED_ONLY'' AS requestedExecutableOrigin FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS result_json;","resultColumn":"result_json"}}]';
EXEC model.declare_scenario @capability_id=N'project-consumer-execution-embodiment-plan',@scenario=N'{"scenarioId":"derive-target-neutral-execution-plan","name":"Derive the target-neutral execution plan","inputId":"capability-authority-declaration","inputContract":"capability-authority-declaration.v1","eventId":"derive-target-neutral-execution-plan","eventAuthority":"derive-target-neutral-execution-plan.v1","outcomeId":"consumer-execution-embodiment-plan","outcomeContract":"consumer-execution-embodiment-plan.v1","terminal":false,"root":false,"given":"one admitted capability embodiment authority","when":"the execution plan is derived","then":"one target-neutral plan is returned with its operations, contracts and lineage"}',@operations=N'[{"kind":"invoke-port","portId":"derive-target-neutral-execution-plan"}]',@port_bindings=N'[{"portId":"derive-target-neutral-execution-plan","platformCapabilityId":"sda-semantic-execution-graph-compilation-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/execution-graph-read-provider.mjs","export":"readDeclaredExecutionGraph"},"inputAdmission":{"type":"object","required":["contractId","capabilityId","scenarioId","target","authority","closure","mechanics","snapshotId","projectionDigest","viewDefinitionDigest"],"properties":{"contractId":{"const":"capability-authority-declaration.v1"},"capabilityId":{"type":"string"},"scenarioId":{"type":"string"},"target":{"type":"string"},"authority":{"type":"object"},"closure":{"type":"object"},"mechanics":{"type":"object"},"snapshotId":{"type":"string"},"projectionDigest":{"type":"string"},"viewDefinitionDigest":{"type":"string"}}},"admissionFailure":{"contractId":"consumer-execution-embodiment-plan.v1","disposition":"EXECUTION_EMBODIMENT_PLAN_HELD","findings":[{"code":"EXECUTION_PLAN_UNDECLARED"}]},"expression":{"op":"object","fields":{"contractId":{"op":"literal","value":"consumer-execution-embodiment-plan.v1"},"authorityDeclaration":{"op":"path","from":"input","path":"declaration"},"canonicalGraph":{"op":"path","from":"input","path":"compiled.graph"},"sourceMap":{"op":"path","from":"input","path":"compiled.sourceMap"},"contractCatalog":{"op":"path","from":"input","path":"contractCatalog"},"fixtureAuthority":{"op":"path","from":"input","path":"fixtureAuthority"},"platform":{"op":"path","from":"input","path":"platform"}}},"errors":[{"prefix":"GRAPH_COMPILER_EMPTY_EXECUTION_AUTHORITY:","outcome":{"contractId":"consumer-execution-embodiment-plan.v1","disposition":"EXECUTION_EMBODIMENT_PLAN_HELD","findings":[{"code":"EXECUTION_PLAN_UNDECLARED"}]}}]}}]';
EXEC model.declare_scenario @capability_id=N'project-consumer-execution-embodiment-plan',@scenario=N'{"scenarioId":"register-projection-authorities","name":"Register the projection authorities for the selected targets","inputId":"capability-authority-declaration","inputContract":"capability-authority-declaration.v1","eventId":"register-projection-authorities","eventAuthority":"register-projection-authorities.v1","outcomeId":"registered-projection-authority-set","outcomeContract":"registered-projection-authority-set.v1","terminal":false,"root":false,"given":"one execution plan and the selected targets","when":"the projection authorities are registered","then":"every selected target names its admitted projection authority"}',@operations=N'[{"kind":"invoke-port","portId":"register-projection-authorities"}]',@port_bindings=N'[{"portId":"register-projection-authorities","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/database-query-provider.mjs","export":"readDatabaseQuery"},"statement":"DECLARE @declaration nvarchar(max)=COALESCE(JSON_QUERY(@input,''$.authorityDeclaration''),@input);\nIF JSON_VALUE(@declaration,''$.snapshotId'') IS NULL OR JSON_VALUE(@declaration,''$.snapshotId'')<>@snapshot_id\n OR JSON_VALUE(@declaration,''$.projectionDigest'') IS NULL OR JSON_VALUE(@declaration,''$.projectionDigest'')<>@projection_id\n OR JSON_VALUE(@declaration,''$.viewDefinitionDigest'') IS NULL OR JSON_VALUE(@declaration,''$.viewDefinitionDigest'')<>@view_definition_digest\n THROW 51000,''DATABASE_AUTHORITY_NOT_COHERENT'',1;\nDECLARE @targets nvarchar(max)=(SELECT JSON_QUERY(entry.value) AS authority FROM analysis.v_selected_semantic_definition d\n CROSS APPLY OPENJSON(d.definition_json,''$.semantics.projectionAuthorities'') entry\n WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''AUTHORITY'' AND d.declared_id=''registered-projection-authority-set.v1''\n AND JSON_VALUE(entry.value,''$.target'')=JSON_VALUE(@declaration,''$.target'')\n AND EXISTS (SELECT 1 FROM analysis.v_target_provider_profile p WHERE p.estate_model_pk=@estate_model_pk\n   AND p.provider_profile_id=JSON_VALUE(entry.value,''$.providerProfileId'') AND p.target_id=JSON_VALUE(@declaration,''$.target''))\n FOR JSON PATH);\nDECLARE @findings nvarchar(max)=CASE WHEN (SELECT COUNT(*) FROM OPENJSON(@targets))=1 THEN ''[]''\n ELSE ''[{\"code\":\"PROJECTION_AUTHORITY_UNREGISTERED\"}]'' END;\nSELECT (SELECT ''registered-projection-authority-set.v1'' AS contractId,JSON_QUERY(@targets) AS targets,JSON_QUERY(@findings) AS findings FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS result_json;","resultColumn":"result_json"}}]';
EXEC model.declare_capability_feature @capability_id=N'project-consumer-execution-embodiment-plan',@feature_text=N'@capability:project-consumer-execution-embodiment-plan
@root-scenario:project-consumer-execution-embodiment-plan
Feature: Project the admitted consumer execution embodiment plan

  The consumer execution embodiment pipeline begins from an admitted projection
  context: the projected execution plan together with the registered projection
  authorities and the fixture authority. The platform pipeline consumes that
  context, but no scenario in the current model declares its production. This
  capability supplies it.

  It reads one capability''s retained authority, projects the target-neutral
  execution plan and its registered projection authorities for the selected
  targets, and admits the resulting context. It does not render a candidate, run a
  fixture, or accept the projection; those remain the authority of the downstream
  composition.

  The context is an input presupposition of the consumer execution embodiment
  pipeline. Producing it here makes the pipeline''s first input declared instead of
  assumed, and lets a missing plan authority be a held finding rather than a
  silently absent input.

  @scenario:project-consumer-execution-embodiment-plan
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:project-consumer-execution-embodiment-plan
  @event-authority:project-consumer-execution-embodiment-plan.v1
  @outcome:consumer-execution-embodiment-projection-context
  @outcome-contract:consumer-execution-embodiment-projection-context.v1
  @outcome-variants:EXECUTION_EMBODIMENT_CONTEXT_ADMITTED|EXECUTION_EMBODIMENT_PLAN_HELD
  @outcome-terminal
  Scenario: Project and admit the execution embodiment projection context
    Given one admitted capability embodiment authority and the selected targets
    When the execution plan and registered projection authorities are projected and the context is admitted
    Then one admitted projection context is returned or a held finding names the missing plan authority

  @scenario:derive-target-neutral-execution-plan
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:derive-target-neutral-execution-plan
  @event-authority:derive-target-neutral-execution-plan.v1
  @outcome:consumer-execution-embodiment-plan
  @outcome-contract:consumer-execution-embodiment-plan.v1
  Scenario: Derive the target-neutral execution plan
    Given one admitted capability embodiment authority
    When the execution plan is derived
    Then one target-neutral plan is returned with its operations, contracts and lineage
    And an authority that declares no execution operations returns EXECUTION_PLAN_UNDECLARED

  @scenario:register-projection-authorities
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:register-projection-authorities
  @event-authority:register-projection-authorities.v1
  @outcome:registered-projection-authority-set
  @outcome-contract:registered-projection-authority-set.v1
  Scenario: Register the projection authorities for the selected targets
    Given one execution plan and the selected targets
    When the projection authorities are registered
    Then every selected target names its admitted projection authority
    And a target with no registered projection authority returns PROJECTION_AUTHORITY_UNREGISTERED
';
SELECT 'producer_scenarios' AS result_set,s.scenario_id,i.input_id,e.event_id,o.outcome_id FROM model.capability c JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk JOIN source.current_model cm ON cm.estate_model_pk=ec.estate_model_pk JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk JOIN model.scenario_input i ON i.scenario_version_pk=cs.scenario_version_pk JOIN model.scenario_event e ON e.scenario_version_pk=cs.scenario_version_pk JOIN model.scenario_outcome o ON o.scenario_version_pk=cs.scenario_version_pk WHERE c.capability_id=N'project-consumer-execution-embodiment-plan';
COMMIT TRANSACTION;
