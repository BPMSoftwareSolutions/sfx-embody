-- declare-scenario-outcome-contract-integrity.commit.sql
--
-- COMMIT twin of declare-scenario-outcome-contract-integrity.sql. Installs the
-- trailing-invoke outcome contract law: when a scenario's execution authority
-- ends with an `invoke-scenario` operation, the declared outcome contract must
-- equal the invoked scenario's outcome contract, else
-- 51000 SCENARIO_OUTCOME_CONTRACT_DIVERGENCE with zero writes. The installed
-- body's unconditional outcome-contract re-assert is guarded for that case
-- (`IF @terminal_invoke=0`); every other path is byte-identical to the live
-- definition (sys.sql_modules digest
-- 9D0C1E4A4F770E1DEF199E8DAD51D077BC62490B432BDC58796A76F0C6C02BEE).
--
-- The acceptance experiments (divergent refusal, matching acceptance, identical
-- replay, unresolved contract, missing faces, non-terminal acceptance) are in
-- the preflight twin; this twin installs and reports the installed state.
-- Idempotent: CREATE OR ALTER plus read-only verification.
SET NOCOUNT ON;
SET XACT_ABORT ON;
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
BEGIN TRANSACTION;
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

 DECLARE @terminal_ordinal int=(SELECT MAX(CONVERT(int,[key])) FROM OPENJSON(@operations));
 DECLARE @terminal_kind nvarchar(100)=
  (SELECT JSON_VALUE(value,'$.kind') FROM OPENJSON(@operations) WHERE CONVERT(int,[key])=@terminal_ordinal);
 DECLARE @terminal_invoke bit=0;
 IF @terminal_kind=N'invoke-scenario'
 BEGIN
  DECLARE @invoked_scenario nvarchar(400)=
   (SELECT JSON_VALUE(value,'$.scenarioId') FROM OPENJSON(@operations) WHERE CONVERT(int,[key])=@terminal_ordinal);
  DECLARE @invoked_contract_pk bigint=NULL;
  SELECT @invoked_contract_pk=tcv.contract_pk
  FROM model.capability tc
  JOIN model.identity_namespace tn ON tn.namespace_pk=tc.namespace_pk AND tn.namespace_id=N'sidefx:capabilities'
  JOIN model.estate_capability tec ON tec.capability_pk=tc.capability_pk AND tec.estate_model_pk=@estate
  JOIN model.capability_root_scenario trs ON trs.capability_version_pk=tec.capability_version_pk
  JOIN model.capability_scenario tcs ON tcs.capability_version_pk=tec.capability_version_pk AND tcs.scenario_pk=trs.scenario_pk
  JOIN model.scenario_outcome_contract toc ON toc.scenario_version_pk=tcs.scenario_version_pk
  JOIN model.contract_version tcv ON tcv.contract_version_pk=toc.contract_version_pk
  WHERE tc.capability_id=@invoked_scenario;
  IF @invoked_contract_pk IS NULL
   SELECT @invoked_contract_pk=tcv.contract_pk
   FROM model.scenario ts
   JOIN model.capability tc ON tc.capability_pk=ts.capability_pk
   JOIN model.identity_namespace tn ON tn.namespace_pk=tc.namespace_pk AND tn.namespace_id=N'sidefx:capabilities'
   JOIN model.estate_capability tec ON tec.capability_pk=tc.capability_pk AND tec.estate_model_pk=@estate
   JOIN model.capability_scenario tcs ON tcs.capability_version_pk=tec.capability_version_pk AND tcs.scenario_pk=ts.scenario_pk
   JOIN model.scenario_outcome_contract toc ON toc.scenario_version_pk=tcs.scenario_version_pk
   JOIN model.contract_version tcv ON tcv.contract_version_pk=toc.contract_version_pk
   WHERE ts.scenario_id=@invoked_scenario;
  IF @invoked_contract_pk IS NOT NULL
   AND (SELECT contract_pk FROM model.contract_version WHERE contract_version_pk=@out_version)<>@invoked_contract_pk
   THROW 51000,'SCENARIO_OUTCOME_CONTRACT_DIVERGENCE',1;
  SET @terminal_invoke=1;
 END
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
 IF @terminal_invoke=0 UPDATE model.scenario_outcome_contract SET contract_version_pk=@out_version WHERE scenario_version_pk=@version;
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
SET NOCOUNT ON;
SELECT 'integrity_installed' AS result_set,
 CASE WHEN EXISTS (SELECT 1 FROM sys.sql_modules WHERE object_id=OBJECT_ID(N'model.declare_scenario')
   AND definition LIKE N'%SCENARIO_OUTCOME_CONTRACT_DIVERGENCE%') THEN N'READY' ELSE N'MISSING' END AS divergence_refusal,
 CASE WHEN EXISTS (SELECT 1 FROM sys.sql_modules WHERE object_id=OBJECT_ID(N'model.declare_scenario')
   AND definition LIKE N'%SCENARIO_INVOKED_CAPABILITY_NOT_DECLARED%')
  AND EXISTS (SELECT 1 FROM sys.sql_modules WHERE object_id=OBJECT_ID(N'model.declare_scenario')
   AND definition LIKE N'%SCENARIO_CONTRACT_NOT_DECLARED%')
  AND EXISTS (SELECT 1 FROM sys.sql_modules WHERE object_id=OBJECT_ID(N'model.declare_scenario')
   AND definition LIKE N'%SCENARIO_FACES_REQUIRED%') THEN N'PRESERVED' ELSE N'LOST' END AS installed_refusals,
 CASE WHEN EXISTS (SELECT 1 FROM sys.sql_modules WHERE object_id=OBJECT_ID(N'model.declare_scenario')
   AND definition LIKE N'%IF @terminal_invoke=0 UPDATE model.scenario_outcome_contract%') THEN N'GUARDED' ELSE N'UNGUARDED' END AS outcome_write,
 LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),m.definition)),2)) AS definition_sha256,
 DATALENGTH(m.definition)/2 AS definition_chars,
 CASE WHEN LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),m.definition)),2))=N'dcc9fa18a517b1ae79a1389ce93300e2f406f6f46b2935299d85910e41bbbd21' THEN 1 ELSE 0 END AS digest_matches_preflight
FROM sys.sql_modules m WHERE m.object_id=OBJECT_ID(N'model.declare_scenario');
COMMIT TRANSACTION;
