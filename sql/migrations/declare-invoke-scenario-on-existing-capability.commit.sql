-- Extends model.declare_scenario to declare invoke-scenario operations on an
-- existing capability. For each operation in @operations with kind
-- 'invoke-scenario', $.scenarioId names the target capability whose root
-- scenario's selected version (current estate) is the target: the resolution
-- walks estate_capability -> capability_root_scenario -> capability_scenario.
-- The operation link is written to model.operation_scenario_invocation under
-- the /semantics/authority/operations/<n> pointer convention, matching the
-- reference rows of request-capability-from-objective's execute-admitted-proposal
-- authority (execution_operation 2629 / operation_scenario_invocation target 898).
-- An unresolved $.scenarioId refuses with SCENARIO_INVOKED_CAPABILITY_NOT_DECLARED;
-- the invoke-port binding gate is restricted to invoke-port operations. The
-- authority version stays content-addressed, so replaying a declaration mints no
-- new version (the replay below proves it), and the existing UPDATE path keeps
-- re-declaring a scenario repointing its invokers' targets.
-- COMMIT twin of declare-invoke-scenario-on-existing-capability.sql.
-- Preflight: ends with ROLLBACK; run as a dry run with the migration runner.
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
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trigger_name); FETCH NEXT FROM @triggers INTO @trigger_name; END;
CLOSE @triggers; DEALLOCATE @triggers;
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
   SELECT @authority_version,JSON_VALUE(value,'$.operationId'),CONVERT(int,[key]),JSON_VALUE(value,'$.kind'),@definition,N'/semantics/authority/operations/'+[key] FROM OPENJSON(@operations);
  INSERT model.operation_port_invocation(execution_operation_pk,port_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT op.execution_operation_pk,p.port_version,'invoke-port',@definition,op._canonical_pointer
   FROM model.execution_operation op JOIN OPENJSON(@operations) j ON CONVERT(int,j.[key])=op.ordinal
   JOIN @ports p ON p.port_id=JSON_VALUE(j.value,'$.portId') WHERE op.execution_authority_version_pk=@authority_version AND op.operation_kind='invoke-port';
  INSERT model.operation_scenario_invocation(execution_operation_pk,target_scenario_version_pk,operation_kind,_owner_definition_pk,_canonical_pointer)
   SELECT op.execution_operation_pk,target.scenario_version_pk,'invoke-scenario',@definition,op._canonical_pointer
   FROM model.execution_operation op
   JOIN OPENJSON(@operations) j ON CONVERT(int,j.[key])=op.ordinal
   JOIN model.capability c ON c.capability_id=JSON_VALUE(j.value,'$.scenarioId')
   JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
   JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=@estate
   JOIN model.capability_root_scenario rs ON rs.capability_version_pk=ec.capability_version_pk
   JOIN model.capability_scenario target ON target.capability_version_pk=ec.capability_version_pk AND target.scenario_pk=rs.scenario_pk
   WHERE op.execution_authority_version_pk=@authority_version AND op.operation_kind='invoke-scenario';
  IF EXISTS (SELECT 1 FROM model.execution_operation op WHERE op.execution_authority_version_pk=@authority_version
   AND op.operation_kind='invoke-port' AND NOT EXISTS (SELECT 1 FROM model.operation_port_invocation i WHERE i.execution_operation_pk=op.execution_operation_pk))
   THROW 51000,'SCENARIO_OPERATION_BINDING_NOT_DECLARED',1;
  IF EXISTS (SELECT 1 FROM model.execution_operation op WHERE op.execution_authority_version_pk=@authority_version
   AND op.operation_kind='invoke-scenario' AND NOT EXISTS (SELECT 1 FROM model.operation_scenario_invocation i WHERE i.execution_operation_pk=op.execution_operation_pk))
   THROW 51000,'SCENARIO_INVOKED_CAPABILITY_NOT_DECLARED',1;
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
 END;
 DECLARE @variant_rows TABLE (variant_id nvarchar(400) COLLATE Latin1_General_100_BIN2, classification varchar(16), json_type int, ordinal int);
 INSERT @variant_rows
  SELECT CASE v.[type] WHEN 1 THEN v.[value] WHEN 5 THEN JSON_VALUE(v.[value], '$.variantId') END,
   CASE v.[type] WHEN 5 THEN JSON_VALUE(v.[value], '$.classification') END,
   v.[type], CONVERT(int, v.[key])
  FROM OPENJSON(@scenario, '$.variants') v;
 IF EXISTS (SELECT 1 FROM @variant_rows WHERE json_type NOT IN (1, 5))
  THROW 51000, 'SCENARIO_VARIANT_FORM_NOT_DECLARED', 1;
 IF EXISTS (SELECT 1 FROM @variant_rows WHERE variant_id IS NULL OR LEN(LTRIM(RTRIM(variant_id))) = 0)
  THROW 51000, 'SCENARIO_VARIANT_ID_REQUIRED', 1;
 IF EXISTS (SELECT 1 FROM @variant_rows WHERE classification IS NOT NULL AND classification NOT IN ('success', 'failure'))
  THROW 51000, 'SCENARIO_VARIANT_CLASSIFICATION_INVALID', 1;
 UPDATE existing SET classification = declared.classification, terminal = @terminal
 FROM model.outcome_variant existing
 JOIN @variant_rows declared ON declared.variant_id = existing.variant_id
 WHERE existing.scenario_version_pk = @version;
 INSERT model.outcome_variant(scenario_version_pk, variant_id, classification, terminal, _owner_definition_pk, _canonical_pointer)
  SELECT @version, declared.variant_id, declared.classification, @terminal, @scenario_definition, N'/variants/' + CONVERT(nvarchar(10), declared.ordinal)
  FROM @variant_rows declared
  WHERE NOT EXISTS (SELECT 1 FROM model.outcome_variant existing
    WHERE existing.scenario_version_pk = @version AND existing.variant_id = declared.variant_id);
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
SELECT 'declare_scenario_procedure' AS result_set,
 CASE WHEN EXISTS (SELECT 1 FROM sys.sql_modules WHERE object_id=OBJECT_ID(N'model.declare_scenario')
   AND definition LIKE N'%SCENARIO_INVOKED_CAPABILITY_NOT_DECLARED%')
  THEN N'READY' ELSE N'MISSING' END AS procedure_state;
GO
DECLARE @scenario nvarchar(max)=N'{"scenarioId":"execute-admitted-proposal","name":"Execute the admitted proposal","inputId":"execute-admitted-proposal-request","inputContract":"agent-route.v1","eventId":"execute-admitted-proposal-selected","eventAuthority":"execute-admitted-proposal.v1","outcomeId":"agent-admitted-evidence","outcomeContract":"agent-admitted-evidence.v1","terminal":true,"given":"the declared route admitted the proposed capability","when":"the admitted capability executes","then":"the provider-attributed capability evidence is produced"}';
DECLARE @operations nvarchar(max)=N'[{"kind":"invoke-port","portId":"shape-equity-execution-request-port"},{"kind":"invoke-scenario","scenarioId":"resolve-equity-market-price-evidence"}]';
DECLARE @port_bindings nvarchar(max)=N'[{"portId":"shape-equity-execution-request-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"shape-equity-execution-request"}}]';
DECLARE @eav_before int=(SELECT COUNT(*) FROM model.execution_authority ea
 JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=N'sidefx:capability:request-capability-from-objective'
 JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
 WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1');
DECLARE @osi_before int=(SELECT COUNT(*) FROM model.execution_authority ea
 JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=N'sidefx:capability:request-capability-from-objective'
 JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
 JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
 WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1');
EXEC model.declare_scenario @capability_id=N'request-capability-from-objective',@scenario=@scenario,@operations=@operations,@port_bindings=@port_bindings;
DECLARE @eav_first int=(SELECT COUNT(*) FROM model.execution_authority ea
 JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=N'sidefx:capability:request-capability-from-objective'
 JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
 WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1');
DECLARE @osi_first int=(SELECT COUNT(*) FROM model.execution_authority ea
 JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=N'sidefx:capability:request-capability-from-objective'
 JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
 JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
 WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1');
EXEC model.declare_scenario @capability_id=N'request-capability-from-objective',@scenario=@scenario,@operations=@operations,@port_bindings=@port_bindings;
DECLARE @eav_replay int=(SELECT COUNT(*) FROM model.execution_authority ea
 JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=N'sidefx:capability:request-capability-from-objective'
 JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
 WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1');
DECLARE @osi_replay int=(SELECT COUNT(*) FROM model.execution_authority ea
 JOIN model.identity_namespace n ON n.namespace_pk=ea.namespace_pk AND n.namespace_id=N'sidefx:capability:request-capability-from-objective'
 JOIN model.execution_authority_version eav ON eav.execution_authority_pk=ea.execution_authority_pk
 JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
 JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
 WHERE ea.execution_authority_id=N'execute-admitted-proposal.v1');
SELECT 'declare_scenario_idempotence' AS result_set, @eav_before AS eav_before, @eav_first AS eav_after_first,
 @eav_replay AS eav_after_replay, @osi_before AS osi_before, @osi_first AS osi_after_first,
 @osi_replay AS osi_after_replay,
 CASE WHEN @eav_first=@eav_replay AND @osi_first=@osi_replay THEN N'IDEMPOTENT' ELSE N'DRIFT' END AS disposition;
GO
SELECT 'invoke_scenario_wiring' AS result_set, s.scenario_id AS declared_scenario, sv.scenario_version_pk,
 eo.ordinal, eo.operation_kind, eo._canonical_pointer, osi.target_scenario_version_pk,
 ts.scenario_id AS target_scenario_id, tc.capability_id AS target_capability_id, eo._owner_definition_pk AS owner_sod,
 LOWER(CONVERT(varchar(64),eav.definition_digest,2)) AS authority_digest
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk=c.capability_pk AND ec.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
JOIN model.capability_scenario cs ON cs.capability_version_pk=ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
LEFT JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
LEFT JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
LEFT JOIN model.capability tc ON tc.capability_pk=ts.capability_pk
WHERE c.capability_id=N'request-capability-from-objective' AND s.scenario_id=N'execute-admitted-proposal'
ORDER BY eo.ordinal;
SELECT 'reference_invoke_scenario' AS result_set, eo.execution_operation_pk, eo.ordinal, eo.operation_kind,
 eo._canonical_pointer, osi.target_scenario_version_pk, osi._owner_definition_pk AS owner_sod, ts.scenario_id AS target_scenario_id
FROM model.execution_operation eo
JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
JOIN model.scenario_version tsv ON tsv.scenario_version_pk=osi.target_scenario_version_pk
JOIN model.scenario ts ON ts.scenario_pk=tsv.scenario_pk
WHERE eo.execution_operation_pk=2629;
COMMIT TRANSACTION;
