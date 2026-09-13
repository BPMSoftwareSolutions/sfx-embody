-- Execute the selected declaration with bound providers and declared admission.
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
 UPDATE invocation SET port_version_pk=p.port_version
 FROM model.operation_port_invocation invocation
 JOIN model.execution_operation op ON op.execution_operation_pk=invocation.execution_operation_pk
 JOIN OPENJSON(@operations) j ON CONVERT(int,j.[key])=op.ordinal
 JOIN @ports p ON p.port_id=JSON_VALUE(j.value,'$.portId')
 WHERE op.execution_authority_version_pk=@authority_version;
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
 UPDATE model.scenario_input SET input_contract_version_pk=@in_version WHERE scenario_version_pk=@version;
 UPDATE model.scenario_event SET execution_authority_version_pk=@authority_version WHERE scenario_version_pk=@version;
 UPDATE model.scenario_outcome_contract SET contract_version_pk=@out_version WHERE scenario_version_pk=@version;
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

IF NOT EXISTS(SELECT 1 FROM model.capability c JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk WHERE c.capability_id=N'execute-declared-capability' AND n.namespace_id=N'sidefx:capabilities')
EXEC model.scaffold_estate_provider_capability @capability_id=N'execute-declared-capability',@provider_module=N'src/resolvers/node/consumer-execution-provider.mjs',@provider_export=N'executeConsumerPlan',@input_contract=N'capability-execution-request.v1',@input_schema=N'{"type":"object","required":["capabilityId","target","scenarioInput"],"properties":{"capabilityId":{"type":"string","minLength":1},"target":{"type":"string","minLength":1},"scenarioId":{"type":"string"},"scenarioInput":{}},"additionalProperties":false}',@outcome_contract=N'capability-execution-result.v1',@outcome_schema=N'{"type":"object","required":["contractId","disposition"],"properties":{"contractId":{"const":"capability-execution-result.v1"},"disposition":{"enum":["EXECUTION_COMPLETED","EXECUTION_HELD","INPUT_REJECTED","OUTCOME_REJECTED","EXECUTION_FAILED"]}}}',@description=N'Execute the database declaration with selected providers and declared input and outcome contracts';
GO
EXEC model.declare_scenario @capability_id=N'execute-declared-capability',@scenario=N'{"scenarioId":"execute-declared-capability","name":"Execute one capability from its declaration","inputId":"capability-execution-request","inputContract":"capability-execution-request.v1","eventId":"execute-declared-capability","eventAuthority":"execute-declared-capability.v1","outcomeId":"capability-execution-result","outcomeContract":"capability-execution-result.v1","terminal":true,"root":true,"given":"one admitted declaration, one resolved provider binding set and one scenario input","when":"the declared operations execute against the bound providers","then":"the observed outcome is admitted and one disposition is returned bound to the declaration digest, or the exact held, rejected or failed disposition is returned","variants":["EXECUTION_COMPLETED","EXECUTION_HELD","INPUT_REJECTED","OUTCOME_REJECTED","EXECUTION_FAILED"]}',@operations=N'[{"operationId":"execute-declared-capability.0","kind":"invoke-port","portId":"read-execution-capability-authority"},{"operationId":"execute-declared-capability.1","kind":"invoke-port","portId":"resolve-execution-provider-bindings"},{"operationId":"execute-declared-capability.2","kind":"invoke-port","portId":"read-bound-consumer-execution-plan"},{"operationId":"execute-declared-capability.3","kind":"invoke-port","portId":"admit-execution-input"},{"operationId":"execute-declared-capability.4","kind":"invoke-port","portId":"execute-bound-consumer-plan"},{"operationId":"execute-declared-capability.5","kind":"invoke-port","portId":"admit-execution-outcome"}]',@port_bindings=N'[{"configuration":{"estateProvider":{"module":"src/resolvers/node/authority-read-provider.mjs","export":"readCapabilityAuthority"},"defaultTarget":"node","profileAbsent":"PROFILE_PROVIDER_ABSENT","profileAmbiguous":"TARGET_PROVIDER_PROFILE_AMBIGUOUS","expression":{"op":"object","fields":{"contractId":{"op":"path","from":"input","path":"result.contractId"},"capabilityId":{"op":"path","from":"input","path":"result.capabilityId"},"scenarioId":{"op":"path","from":"input","path":"result.scenarioId"},"target":{"op":"path","from":"input","path":"result.target"},"snapshotId":{"op":"path","from":"input","path":"result.snapshotId"},"projectionDigest":{"op":"path","from":"input","path":"result.projectionDigest"},"viewDefinitionDigest":{"op":"path","from":"input","path":"result.viewDefinitionDigest"},"authority":{"op":"path","from":"input","path":"result.authority"},"closure":{"op":"path","from":"input","path":"result.closure"},"mechanics":{"op":"path","from":"input","path":"result.mechanics"},"executionInput":{"op":"path","from":"input","path":"request.scenarioInput"}}}},"platformCapabilityId":"sda-embodiment-plan-port.v1","portId":"read-execution-capability-authority"},{"configuration":{"estateProvider":{"module":"src/resolvers/node/database-query-provider.mjs","export":"readDatabaseQuery"},"statement":"IF ISNULL(JSON_VALUE(@input,''$.contractId''),'''')<>''capability-authority-declaration.v1''\n OR ISNULL(JSON_VALUE(@input,''$.capabilityId''),'''')=''''\n OR ISNULL(JSON_VALUE(@input,''$.scenarioId''),'''')=''''\n OR JSON_QUERY(@input,''$.authority'') IS NULL\n OR JSON_QUERY(@input,''$.closure'') IS NULL\n OR JSON_QUERY(@input,''$.mechanics'') IS NULL\n THROW 51000,''DATABASE_AUTHORITY_NOT_COHERENT'',1;\nIF NOT EXISTS (SELECT 1 FROM analysis.v_target_provider_profile WHERE estate_model_pk=@estate_model_pk AND target_id=JSON_VALUE(@input,''$.target''))\n THROW 51000,''PROFILE_PROVIDER_ABSENT'',1;\nIF JSON_VALUE(@input,''$.contractId'') <> ''capability-authority-declaration.v1''\n OR JSON_VALUE(@input,''$.snapshotId'') IS NULL\n OR JSON_VALUE(@input,''$.snapshotId'') <> @snapshot_id\n OR JSON_VALUE(@input,''$.projectionDigest'') IS NULL\n OR JSON_VALUE(@input,''$.projectionDigest'') <> @projection_id\n OR JSON_VALUE(@input,''$.viewDefinitionDigest'') IS NULL\n OR JSON_VALUE(@input,''$.viewDefinitionDigest'') <> @view_definition_digest\n THROW 51000,''DATABASE_AUTHORITY_NOT_COHERENT'',1;\nDECLARE @slots TABLE (capability_id nvarchar(400),slot_id nvarchar(400),target_id nvarchar(400),provider_profile_id nvarchar(400),selection_policy varchar(64),provider_definition_pk bigint,port_count int,mechanic_count int,candidate_count int,binding_count int,disposition varchar(64));\nINSERT @slots\nSELECT capability_id,slot_id,target_id,provider_profile_id,selection_policy,provider_definition_pk,port_count,mechanic_count,candidate_count,binding_count,disposition\nFROM analysis.v_provider_slot_resolution\nWHERE estate_model_pk=@estate_model_pk AND target_id=JSON_VALUE(@input,''$.target'')\n AND (capability_id=JSON_VALUE(@input,''$.capabilityId'') OR capability_id IN (SELECT owning_capability_id FROM OPENJSON(@input,''$.closure.recordsets[0]'') WITH (owning_capability_id nvarchar(400) ''$.owning_capability_id'')));\nSELECT (SELECT ''provider-slot-binding-set.v1'' AS contractId,\n CASE WHEN EXISTS (SELECT 1 FROM @slots WHERE disposition=''PROVIDER_SLOT_AMBIGUOUS'') THEN ''PROVIDER_SLOT_AMBIGUOUS''\n      WHEN EXISTS (SELECT 1 FROM @slots WHERE disposition<>''PROVIDER_SLOTS_BOUND'') THEN ''PROVIDER_SLOT_UNBOUND''\n      ELSE ''PROVIDER_SLOTS_BOUND'' END AS disposition,\n JSON_QUERY(@input) AS authorityDeclaration,\n JSON_QUERY(COALESCE((SELECT provider_profile_id AS providerProfileId,effect_classification AS effectClassification,profile_definition_digest AS definitionDigest\n   FROM analysis.v_target_provider_profile WHERE estate_model_pk=@estate_model_pk AND target_id=JSON_VALUE(@input,''$.target'') ORDER BY effect_classification FOR JSON PATH),N''[]'')) AS profiles,\n JSON_QUERY(COALESCE((SELECT s.capability_id AS capabilityId,s.slot_id AS slotId,s.target_id AS target,s.provider_profile_id AS providerProfileId,s.selection_policy AS selectionPolicy,\n   p.provider_id AS providerId,''sha256:''+LOWER(CONVERT(varchar(64),pd.definition_digest,2)) AS providerDefinitionDigest\n   FROM @slots s JOIN model.provider_definition pd ON pd.provider_definition_pk=s.provider_definition_pk JOIN model.provider p ON p.provider_pk=pd.provider_pk\n   WHERE s.disposition=''PROVIDER_SLOTS_BOUND'' ORDER BY s.capability_id,s.slot_id FOR JSON PATH),N''[]'')) AS bindings,\n JSON_QUERY(COALESCE((SELECT capability_id AS capabilityId,slot_id AS slotId,target_id AS target,disposition AS code,\n   port_count AS portRequirements,mechanic_count AS mechanicRequirements,candidate_count AS candidates,binding_count AS bindings\n   FROM @slots WHERE disposition<>''PROVIDER_SLOTS_BOUND'' ORDER BY capability_id,slot_id FOR JSON PATH),N''[]'')) AS findings\n FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS result_json;","resultColumn":"result_json"},"platformCapabilityId":"sda-embodiment-plan-port.v1","portId":"resolve-execution-provider-bindings"},{"portId":"read-bound-consumer-execution-plan","platformCapabilityId":"sda-embodiment-plan-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/consumer-plan-provider.mjs","export":"readConsumerExecutionPlan"},"planner":{"statement":"-- Read the selected profiles, native execution boundary and bound ports.\nSELECT * FROM analysis.v_target_provider_profile\nWHERE estate_model_pk=@estate_model_pk AND target_id=JSON_VALUE(@input,''$.target'') ORDER BY effect_classification;\n\nSELECT d.declared_id AS provider_id,JSON_QUERY(d.definition_json,''$.semantics.executionAuthority'') AS execution_authority\nFROM analysis.v_selected_semantic_definition d\nWHERE d.estate_model_pk=@estate_model_pk AND d.object_kind=''PROVIDER''\n AND JSON_VALUE(d.definition_json,''$.semantics.executionAuthority.target'')=JSON_VALUE(@input,''$.target'');\n\nSELECT resolution.slot_id,resolution.disposition,p.port_id,i.provider_id,i.implementation_ref,\n ''sha256:''+LOWER(CONVERT(varchar(64),i.definition_digest,2)) AS provider_definition_digest,JSON_VALUE(entry.value,''$.hostProvider'') AS host_provider,\n JSON_VALUE(entry.value,''$.hostImplementationRef'') AS host_implementation_ref,\n JSON_VALUE(entry.value,''$.hostImplementationDigest'') AS host_implementation_digest,\n JSON_VALUE(entry.value,''$.hostProviderExport'') AS host_provider_export\nFROM analysis.v_provider_slot_resolution resolution\nJOIN model.slot_port_requirement r ON r.provider_slot_pk=resolution.provider_slot_pk\nJOIN model.port_version pv ON pv.port_version_pk=r.port_version_pk\nJOIN model.port p ON p.port_pk=pv.port_pk\nJOIN analysis.v_selected_semantic_definition pd ON pd.semantic_object_definition_pk=pv.semantic_object_definition_pk AND pd.estate_model_pk=@estate_model_pk\nJOIN analysis.v_target_provider_implementation i ON i.provider_definition_pk=resolution.provider_definition_pk\n AND i.target_id=resolution.target_id AND i.estate_model_pk=@estate_model_pk\n AND i.capability_id=JSON_VALUE(pd.definition_json,''$.semantics.platformCapabilityId'')\nJOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=i.semantic_object_definition_pk AND d.estate_model_pk=@estate_model_pk\nCROSS APPLY OPENJSON(d.definition_json,''$.semantics.capabilities'') entry\nWHERE resolution.estate_model_pk=@estate_model_pk AND resolution.capability_id=JSON_VALUE(@input,''$.capabilityId'')\n AND resolution.target_id=JSON_VALUE(@input,''$.target'')\n AND JSON_VALUE(entry.value,''$.projectionTarget'')=resolution.target_id\n AND JSON_VALUE(entry.value,''$.capabilityId'')=i.capability_id\nORDER BY resolution.slot_id;\n\nSELECT m.mechanic_id,COALESCE(JSON_VALUE(d.definition_json,''$.semantics.executionAuthority.runtime.sourceDigest''),\n p.provider_module_root+''/''+p.provider_module) AS implementation_ref\nFROM analysis.v_target_provider_profile p\nJOIN model.provider_mechanic_implementation i ON i.provider_profile_version_pk=p.provider_profile_version_pk\nJOIN model.mechanic_version mv ON mv.mechanic_version_pk=i.mechanic_version_pk\nJOIN model.mechanic m ON m.mechanic_pk=mv.mechanic_pk\nJOIN model.provider_definition pd ON pd.provider_definition_pk=i.provider_definition_pk\nJOIN analysis.v_selected_semantic_definition d ON d.semantic_object_definition_pk=pd.semantic_object_definition_pk AND d.estate_model_pk=@estate_model_pk\nWHERE p.estate_model_pk=@estate_model_pk AND p.target_id=JSON_VALUE(@input,''$.target'') AND p.effect_classification=''pure''\nORDER BY m.mechanic_id;\n","rowLimit":2000,"relativeRoot":"embodiments","outcomeContract":"capability-embodiment-plan.v1","bindingType":"projected-consumer-application-binding.v3","candidateDisposition":"CANDIDATE","files":{"plan":"body/execution-plan.json","binding":"body/application-binding.json","fixtures":"evidence/fixture-authority.json","sourceMap":"evidence/source-map.json","conformance":"evidence/projection-conformance.json"}},"inputAdmission":{"type":"object","required":["disposition"],"properties":{"disposition":{"const":"PROVIDER_SLOTS_BOUND"}}},"admissionFailureExpression":{"op":"object","fields":{"contractId":{"op":"literal","value":"capability-execution-result.v1"},"disposition":{"op":"literal","value":"EXECUTION_HELD"},"findings":{"op":"path","from":"input","path":"findings"}}},"expression":{"op":"object","fields":{"plan":{"op":"path","from":"input","path":"plan"},"scenario":{"op":"path","from":"input","path":"scenario"},"executionAuthority":{"op":"path","from":"input","path":"executionAuthority"},"providerBindings":{"op":"path","from":"input","path":"providerBindings"},"scenarioInput":{"op":"path","from":"input","path":"carrier.authorityDeclaration.executionInput"},"authorityIdentity":{"op":"object","fields":{"planDigest":{"op":"path","from":"input","path":"result.planDigest"},"artifactDigest":{"op":"path","from":"input","path":"result.artifactDigest"},"scenarioDefinitionDigest":{"op":"path","from":"input","path":"result.scenarioDefinitionDigest"},"platformDigest":{"op":"path","from":"input","path":"result.platformDigest"},"resolverVersion":{"op":"path","from":"input","path":"result.resolverVersion"},"capabilityId":{"op":"path","from":"input","path":"carrier.authorityDeclaration.capabilityId"},"target":{"op":"path","from":"input","path":"carrier.authorityDeclaration.target"}}}}}}},{"portId":"admit-execution-input","platformCapabilityId":"sda-json-schema-contract-admission-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/contract-admission-provider.mjs","export":"admitDeclaredContract"},"inputAdmission":{"type":"object","required":["plan","scenario","scenarioInput","executionAuthority","providerBindings","authorityIdentity"]},"admissionFailureExpression":{"op":"path","from":"input","path":""},"catalogExpression":{"op":"path","from":"input","path":"plan.contractCatalog"},"contractIdExpression":{"op":"path","from":"input","path":"scenario.input.contractId"},"valueExpression":{"op":"path","from":"input","path":"scenarioInput"},"expression":{"op":"object","fields":{"plan":{"op":"path","from":"input","path":"carrier.plan"},"scenario":{"op":"path","from":"input","path":"carrier.scenario"},"scenarioInput":{"op":"path","from":"input","path":"carrier.scenarioInput"},"executionAuthority":{"op":"path","from":"input","path":"carrier.executionAuthority"},"providerBindings":{"op":"path","from":"input","path":"carrier.providerBindings"},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"inputAdmitted":{"op":"literal","value":true}}},"rejectionExpression":{"op":"object","fields":{"contractId":{"op":"literal","value":"capability-execution-result.v1"},"disposition":{"op":"literal","value":"INPUT_REJECTED"},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"contractIdRejected":{"op":"path","from":"input","path":"contractId"},"findings":{"op":"path","from":"input","path":"errors"}}}}},{"portId":"execute-bound-consumer-plan","platformCapabilityId":"sda-semantic-execution-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/consumer-execution-provider.mjs","export":"executeConsumerPlan"},"authoritySource":"DATABASE","inputAdmission":{"type":"object","required":["plan","scenario","scenarioInput","executionAuthority","providerBindings","authorityIdentity","inputAdmitted"],"properties":{"inputAdmitted":{"const":true}}},"admissionFailureExpression":{"op":"path","from":"input","path":""},"expression":{"op":"object","fields":{"plan":{"op":"path","from":"input","path":"carrier.plan"},"scenario":{"op":"path","from":"input","path":"carrier.scenario"},"scenarioInput":{"op":"path","from":"input","path":"carrier.scenarioInput"},"executionAuthority":{"op":"path","from":"input","path":"carrier.executionAuthority"},"providerBindings":{"op":"path","from":"input","path":"carrier.providerBindings"},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"execution":{"op":"path","from":"input","path":"execution"}}}}},{"portId":"admit-execution-outcome","platformCapabilityId":"sda-json-schema-contract-admission-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/contract-admission-provider.mjs","export":"admitDeclaredContract"},"inputAdmission":{"type":"object","required":["plan","scenario","scenarioInput","executionAuthority","providerBindings","authorityIdentity","execution"]},"admissionFailureExpression":{"op":"path","from":"input","path":""},"catalogExpression":{"op":"path","from":"input","path":"plan.contractCatalog"},"contractIdExpression":{"op":"path","from":"input","path":"scenario.outcome.contractId"},"valueExpression":{"op":"path","from":"input","path":"execution.result.outcome"},"expression":{"op":"object","fields":{"contractId":{"op":"literal","value":"capability-execution-result.v1"},"disposition":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"carrier.execution.result.disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"EXECUTION_COMPLETED"},"else":{"op":"literal","value":"EXECUTION_FAILED"}},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"execution":{"op":"path","from":"input","path":"carrier.execution"}}},"rejectionExpression":{"op":"object","fields":{"contractId":{"op":"literal","value":"capability-execution-result.v1"},"disposition":{"op":"literal","value":"OUTCOME_REJECTED"},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"contractIdRejected":{"op":"path","from":"input","path":"contractId"},"findings":{"op":"path","from":"input","path":"errors"}}}}}]';
EXEC model.declare_scenario @capability_id=N'execute-declared-capability',@scenario=N'{"scenarioId":"admit-declared-input","name":"Admit the input against the declared input contract","inputId":"capability-execution-request","inputContract":"capability-execution-request.v1","eventId":"admit-declared-input","eventAuthority":"admit-declared-input.v1","outcomeId":"capability-execution-result","outcomeContract":"capability-execution-result.v1","terminal":false,"root":false,"given":"one scenario input and the declaration''s declared input contract","when":"input admission is evaluated","then":"the input is admitted or rejected with INPUT_REJECTED, and a rejected input never reaches execution"}',@operations=N'[{"operationId":"admit-declared-input.0","kind":"invoke-port","portId":"admit-execution-input"}]',@port_bindings=N'[{"portId":"admit-execution-input","platformCapabilityId":"sda-json-schema-contract-admission-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/contract-admission-provider.mjs","export":"admitDeclaredContract"},"inputAdmission":{"type":"object","required":["plan","scenario","scenarioInput","executionAuthority","providerBindings","authorityIdentity"]},"admissionFailureExpression":{"op":"path","from":"input","path":""},"catalogExpression":{"op":"path","from":"input","path":"plan.contractCatalog"},"contractIdExpression":{"op":"path","from":"input","path":"scenario.input.contractId"},"valueExpression":{"op":"path","from":"input","path":"scenarioInput"},"expression":{"op":"object","fields":{"plan":{"op":"path","from":"input","path":"carrier.plan"},"scenario":{"op":"path","from":"input","path":"carrier.scenario"},"scenarioInput":{"op":"path","from":"input","path":"carrier.scenarioInput"},"executionAuthority":{"op":"path","from":"input","path":"carrier.executionAuthority"},"providerBindings":{"op":"path","from":"input","path":"carrier.providerBindings"},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"inputAdmitted":{"op":"literal","value":true}}},"rejectionExpression":{"op":"object","fields":{"contractId":{"op":"literal","value":"capability-execution-result.v1"},"disposition":{"op":"literal","value":"INPUT_REJECTED"},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"contractIdRejected":{"op":"path","from":"input","path":"contractId"},"findings":{"op":"path","from":"input","path":"errors"}}}}}]';
EXEC model.declare_scenario @capability_id=N'execute-declared-capability',@scenario=N'{"scenarioId":"execute-declared-operations","name":"Execute every declared operation with its bound provider","inputId":"capability-execution-request","inputContract":"capability-execution-request.v1","eventId":"execute-declared-operations","eventAuthority":"execute-declared-operations.v1","outcomeId":"capability-execution-result","outcomeContract":"capability-execution-result.v1","terminal":false,"root":false,"given":"one admitted input and the declared operation order","when":"each declared operation executes","then":"every operation invokes the provider its binding selects or its target scenario''s declared operations"}',@operations=N'[{"operationId":"execute-declared-operations.0","kind":"invoke-port","portId":"execute-bound-consumer-plan"}]',@port_bindings=N'[{"portId":"execute-bound-consumer-plan","platformCapabilityId":"sda-semantic-execution-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/consumer-execution-provider.mjs","export":"executeConsumerPlan"},"authoritySource":"DATABASE","inputAdmission":{"type":"object","required":["plan","scenario","scenarioInput","executionAuthority","providerBindings","authorityIdentity","inputAdmitted"],"properties":{"inputAdmitted":{"const":true}}},"admissionFailureExpression":{"op":"path","from":"input","path":""},"expression":{"op":"object","fields":{"plan":{"op":"path","from":"input","path":"carrier.plan"},"scenario":{"op":"path","from":"input","path":"carrier.scenario"},"scenarioInput":{"op":"path","from":"input","path":"carrier.scenarioInput"},"executionAuthority":{"op":"path","from":"input","path":"carrier.executionAuthority"},"providerBindings":{"op":"path","from":"input","path":"carrier.providerBindings"},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"execution":{"op":"path","from":"input","path":"execution"}}}}}]';
EXEC model.declare_scenario @capability_id=N'execute-declared-capability',@scenario=N'{"scenarioId":"admit-declared-outcome-and-resolve-disposition","name":"Admit the observed outcome and resolve the declared disposition","inputId":"capability-execution-request","inputContract":"capability-execution-request.v1","eventId":"admit-declared-outcome-and-resolve-disposition","eventAuthority":"admit-declared-outcome-and-resolve-disposition.v1","outcomeId":"capability-execution-result","outcomeContract":"capability-execution-result.v1","terminal":true,"root":false,"given":"one observed outcome and the declaration''s declared outcome contract and terminal dispositions","when":"outcome admission and disposition resolution run","then":"the outcome is admitted and the declared disposition is returned, or OUTCOME_REJECTED is returned and no completion is claimed"}',@operations=N'[{"operationId":"admit-declared-outcome-and-resolve-disposition.0","kind":"invoke-port","portId":"admit-execution-outcome"}]',@port_bindings=N'[{"portId":"admit-execution-outcome","platformCapabilityId":"sda-json-schema-contract-admission-port.v1","configuration":{"estateProvider":{"module":"src/resolvers/node/contract-admission-provider.mjs","export":"admitDeclaredContract"},"inputAdmission":{"type":"object","required":["plan","scenario","scenarioInput","executionAuthority","providerBindings","authorityIdentity","execution"]},"admissionFailureExpression":{"op":"path","from":"input","path":""},"catalogExpression":{"op":"path","from":"input","path":"plan.contractCatalog"},"contractIdExpression":{"op":"path","from":"input","path":"scenario.outcome.contractId"},"valueExpression":{"op":"path","from":"input","path":"execution.result.outcome"},"expression":{"op":"object","fields":{"contractId":{"op":"literal","value":"capability-execution-result.v1"},"disposition":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"input","path":"carrier.execution.result.disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"EXECUTION_COMPLETED"},"else":{"op":"literal","value":"EXECUTION_FAILED"}},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"execution":{"op":"path","from":"input","path":"carrier.execution"}}},"rejectionExpression":{"op":"object","fields":{"contractId":{"op":"literal","value":"capability-execution-result.v1"},"disposition":{"op":"literal","value":"OUTCOME_REJECTED"},"authorityIdentity":{"op":"path","from":"input","path":"carrier.authorityIdentity"},"contractIdRejected":{"op":"path","from":"input","path":"contractId"},"findings":{"op":"path","from":"input","path":"errors"}}}}}]';
EXEC model.declare_capability_feature @capability_id=N'execute-declared-capability',@feature_text=N'@capability:execute-declared-capability
@root-scenario:execute-declared-capability
Feature: Execute one capability directly from its declaration

  A capability''s declaration is its body. The estate today generates a native body
  (materialize-node, consumer-object-provider), loads it (load-memory-scenario) and
  runs it. That generate-and-run triple exists only because the declaration was
  treated as something to translate into code. This capability executes the
  declared operations instead, with the providers the binding rows select.

  Execution reads the admitted declaration and its resolved provider bindings,
  admits the scenario input against the declared input contract, executes each
  declared operation in order — an invoke-port by invoking the bound provider, an
  invoke-scenario by executing the target scenario''s declared operations — admits
  the observed outcome against the declared outcome contract, and resolves the
  disposition. It generates no intermediate body and writes no file.

  The execution is target-neutral: the target selects a profile, the profile
  selects providers, and the same declaration executes on every profile whose
  required providers are bound. An operation whose provider is unbound is held, and
  a declared cycle is refused rather than run.

  @scenario:execute-declared-capability
  @input:capability-execution-request
  @input-contract:capability-execution-request.v1
  @event:execute-declared-capability
  @event-authority:execute-declared-capability.v1
  @outcome:capability-execution-result
  @outcome-contract:capability-execution-result.v1
  @outcome-variants:EXECUTION_COMPLETED|EXECUTION_HELD|INPUT_REJECTED|OUTCOME_REJECTED|EXECUTION_FAILED
  @outcome-terminal
  Scenario: Execute one capability from its declaration
    Given one admitted declaration, one resolved provider binding set and one scenario input
    When the declared operations execute against the bound providers
    Then the observed outcome is admitted and one disposition is returned bound to the declaration digest, or the exact held, rejected or failed disposition is returned

  @scenario:admit-declared-input
  @input:capability-execution-request
  @input-contract:capability-execution-request.v1
  @event:admit-declared-input
  @event-authority:admit-declared-input.v1
  @outcome:capability-execution-result
  @outcome-contract:capability-execution-result.v1
  Scenario: Admit the input against the declared input contract
    Given one scenario input and the declaration''s declared input contract
    When input admission is evaluated
    Then the input is admitted or rejected with INPUT_REJECTED, and a rejected input never reaches execution

  @scenario:execute-declared-operations
  @input:capability-execution-request
  @input-contract:capability-execution-request.v1
  @event:execute-declared-operations
  @event-authority:execute-declared-operations.v1
  @outcome:capability-execution-result
  @outcome-contract:capability-execution-result.v1
  Scenario: Execute every declared operation with its bound provider
    Given one admitted input and the declared operation order
    When each declared operation executes
    Then every operation invokes the provider its binding selects or its target scenario''s declared operations
    And an operation whose provider is unbound returns DECLARED_OPERATION_PROVIDER_UNBOUND, and a declared cycle returns DECLARED_OPERATION_CYCLE

  @scenario:admit-declared-outcome-and-resolve-disposition
  @input:capability-execution-request
  @input-contract:capability-execution-request.v1
  @event:admit-declared-outcome-and-resolve-disposition
  @event-authority:admit-declared-outcome-and-resolve-disposition.v1
  @outcome:capability-execution-result
  @outcome-contract:capability-execution-result.v1
  @outcome-terminal
  Scenario: Admit the observed outcome and resolve the declared disposition
    Given one observed outcome and the declaration''s declared outcome contract and terminal dispositions
    When outcome admission and disposition resolution run
    Then the outcome is admitted and the declared disposition is returned, or OUTCOME_REJECTED is returned and no completion is claimed
';
SELECT 'declared_execution_scenarios' AS result_set,s.scenario_id FROM model.capability c JOIN model.scenario s ON s.capability_pk=c.capability_pk WHERE c.capability_id=N'execute-declared-capability';
COMMIT TRANSACTION;
