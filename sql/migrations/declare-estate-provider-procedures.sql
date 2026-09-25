-- Reusable estate-provider declaration procedures: four lanes + orchestrator.
-- Lane procedures are callable alone; model.declare_estate_provider owns ordering.
-- Rollback file: run as a dry run with the migration runner.
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
CREATE OR ALTER PROCEDURE model.declare_provider_port
 @namespace_id nvarchar(400), @port_id nvarchar(400), @platform_capability_id nvarchar(400)
WITH EXECUTE AS OWNER AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @sem nvarchar(max)=(SELECT @port_id AS portId, @platform_capability_id AS platformCapabilityId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition 'PORT', @namespace_id, @port_id, @sem, @object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 SELECT 'declare_provider_port' AS result_set, @namespace_id AS namespace_id, @port_id AS port_id,
  @platform_capability_id AS platform_capability_id, @object AS object_pk, @definition AS definition_pk;
END
GO
CREATE OR ALTER PROCEDURE model.declare_provider_mechanic
 @capability_id nvarchar(120), @mechanic_id nvarchar(400), @meaning nvarchar(400),
 @effect_classification nvarchar(40), @source_profile nvarchar(200), @native_floor bit,
 @input_contract nvarchar(400), @outcome_contract nvarchar(400), @output_field nvarchar(400)
WITH EXECUTE AS OWNER AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @form nvarchar(max)=N'{"expressedAs":"semantic-transformation-expression.v1","operation":"@op@","required":[],"optional":[],"arguments":{},"authoringNote":"Resolved from the declared host boundary."}';
 SET @form=REPLACE(@form,N'@op@',@mechanic_id);
 DECLARE @sem nvarchar(max)=N'{"authorityId":"cell-execution-protocol.v1","mechanic":{"mechanicId":"@id@","meaning":"@meaning@","effectClassification":"@ec@","inputContractId":"@in@","outcomeContractId":"@out@","sourceProfiles":["@sp@"],"nativeFloor":@nf@,"authoringForm":@form@}}';
 SET @sem=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@sem,N'@id@',@mechanic_id),N'@meaning@',@meaning),N'@ec@',@effect_classification),N'@in@',@input_contract),N'@out@',@outcome_contract),N'@sp@',@source_profile);
 SET @sem=REPLACE(@sem,N'@nf@',CASE WHEN @native_floor=1 THEN N'true' ELSE N'false' END);
 SET @sem=REPLACE(@sem,N'@form@',@form);
 DECLARE @object bigint,@definition bigint,@digest binary(32);
 EXEC model.put_semantic_definition 'MECHANIC',N'sidefx:mechanics',@mechanic_id,@sem,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 DECLARE @mechanic bigint=(SELECT mechanic_pk FROM model.mechanic WHERE semantic_object_pk=@object);
 IF @mechanic IS NULL BEGIN
  INSERT model.mechanic(namespace_pk,mechanic_id,semantic_object_pk,object_kind)
  SELECT namespace_pk,@mechanic_id,@object,'MECHANIC' FROM model.semantic_object WHERE semantic_object_pk=@object;
  SET @mechanic=SCOPE_IDENTITY();
 END;
 IF NOT EXISTS(SELECT 1 FROM model.mechanic_version WHERE semantic_object_definition_pk=@definition)
  INSERT model.mechanic_version(mechanic_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,name,mechanic_kind,definition_profile,object_kind,_owner_definition_pk,_canonical_pointer)
  VALUES(@mechanic,@object,@definition,@digest,@meaning,@effect_classification,'cell-execution-protocol.v1','MECHANIC',@definition,N'');
 EXEC model.add_mechanic @capability_id=@capability_id,@mechanic_id=@mechanic_id,@mode=N'REUSE',@arguments_json=NULL,@output_field=@output_field,@position=NULL;
 SELECT 'declare_provider_mechanic' AS result_set, @capability_id AS capability_id, @mechanic_id AS mechanic_id, @definition AS definition_pk;
END
GO
CREATE OR ALTER PROCEDURE model.bind_provider_port
 @capability_id nvarchar(120), @port_id nvarchar(400), @platform_capability_id nvarchar(400),
 @provider_id nvarchar(400), @scenario nvarchar(max)
WITH EXECUTE AS OWNER AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @op nvarchar(max)=N'[{"operationId":"@cap@.0","kind":"invoke-port","portId":"@port@"}]';
 SET @op=REPLACE(REPLACE(@op,N'@cap@',@capability_id),N'@port@',@port_id);
 DECLARE @pb nvarchar(max)=N'[{"portId":"@port@","platformCapabilityId":"@plat@","configuration":{"providerId":"@prov@"}}]';
 SET @pb=REPLACE(REPLACE(REPLACE(@pb,N'@port@',@port_id),N'@plat@',@platform_capability_id),N'@prov@',@provider_id);
 EXEC model.declare_scenario @capability_id=@capability_id,@scenario=@scenario,@operations=@op,@port_bindings=@pb;
 SELECT 'bind_provider_port' AS result_set, @capability_id AS capability_id, @port_id AS port_id, @provider_id AS provider_id;
END
GO
CREATE OR ALTER PROCEDURE model.declare_estate_provider
 @document nvarchar(max)
WITH EXECUTE AS OWNER AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @document IS NULL OR ISJSON(@document)<>1 THROW 51002,'ESTATE_PROVIDER_DOCUMENT_INVALID',1;
 DECLARE @capability_id nvarchar(120)=JSON_VALUE(@document,'$.capabilityId');
 IF @capability_id IS NULL THROW 51002,'ESTATE_PROVIDER_CAPABILITY_REQUIRED',1;
 DECLARE @namespace_id nvarchar(400)=N'sidefx:capability:'+@capability_id;
 DECLARE @provider_module nvarchar(400)=JSON_VALUE(@document,'$.providerModule');
 DECLARE @provider_export nvarchar(400)=JSON_VALUE(@document,'$.providerExport');
 DECLARE @input_contract nvarchar(400)=JSON_VALUE(@document,'$.input.contract');
 DECLARE @input_schema nvarchar(max)=JSON_QUERY(@document,'$.input.schema');
 DECLARE @outcome_contract nvarchar(400)=JSON_VALUE(@document,'$.outcome.contract');
 DECLARE @outcome_schema nvarchar(max)=JSON_QUERY(@document,'$.outcome.schema');
 DECLARE @description nvarchar(max)=JSON_VALUE(@document,'$.description');
 DECLARE @port_id nvarchar(400)=JSON_VALUE(@document,'$.port.portId');
 DECLARE @platform_capability_id nvarchar(400)=JSON_VALUE(@document,'$.port.platformCapabilityId');
 DECLARE @mechanic_id nvarchar(400)=JSON_VALUE(@document,'$.mechanic.mechanicId');
 DECLARE @meaning nvarchar(400)=JSON_VALUE(@document,'$.mechanic.meaning');
 DECLARE @effect_classification nvarchar(40)=JSON_VALUE(@document,'$.mechanic.effectClassification');
 DECLARE @source_profile nvarchar(200)=JSON_VALUE(@document,'$.mechanic.sourceProfile');
 DECLARE @native_floor bit=TRY_CONVERT(bit,JSON_VALUE(@document,'$.mechanic.nativeFloor'));
 DECLARE @mechanic_input nvarchar(400)=JSON_VALUE(@document,'$.mechanic.inputContract');
 DECLARE @mechanic_outcome nvarchar(400)=JSON_VALUE(@document,'$.mechanic.outcomeContract');
 DECLARE @output_field nvarchar(400)=JSON_VALUE(@document,'$.mechanic.outputField');
 DECLARE @provider_id nvarchar(400)=JSON_VALUE(@document,'$.binding.providerId');
 DECLARE @scenario nvarchar(max)=JSON_QUERY(@document,'$.scenario');
 IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=@capability_id)
  EXEC model.scaffold_estate_provider_capability @capability_id=@capability_id, @provider_module=@provider_module, @provider_export=@provider_export, @input_contract=@input_contract, @input_schema=@input_schema, @outcome_contract=@outcome_contract, @outcome_schema=@outcome_schema, @description=@description, @on_exists=N'REPLACE';
 EXEC model.declare_provider_port @namespace_id=@namespace_id, @port_id=@port_id, @platform_capability_id=@platform_capability_id;
 EXEC model.declare_provider_mechanic @capability_id=@capability_id, @mechanic_id=@mechanic_id, @meaning=@meaning, @effect_classification=@effect_classification, @source_profile=@source_profile, @native_floor=@native_floor, @input_contract=@mechanic_input, @outcome_contract=@mechanic_outcome, @output_field=@output_field;
 EXEC model.bind_provider_port @capability_id=@capability_id, @port_id=@port_id, @platform_capability_id=@platform_capability_id, @provider_id=@provider_id, @scenario=@scenario;
 SELECT 'declare_estate_provider' AS result_set, @capability_id AS capability_id, @port_id AS port_id, @mechanic_id AS mechanic_id, @provider_id AS provider_id;
END
GO
SELECT 'declare_estate_provider_procedures' AS result_set,
 CASE WHEN OBJECT_ID(N'model.declare_provider_port') IS NOT NULL AND OBJECT_ID(N'model.declare_provider_mechanic') IS NOT NULL
  AND OBJECT_ID(N'model.bind_provider_port') IS NOT NULL AND OBJECT_ID(N'model.declare_estate_provider') IS NOT NULL
 THEN N'READY' ELSE N'MISSING' END AS procedures;
ROLLBACK TRANSACTION;
