-- Creates model.declare_scenario_from_contract: declares a scenario bound to a declared contract.
-- COMMIT twin of declare-scenario-procedure.sql.
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
CREATE OR ALTER PROCEDURE model.declare_scenario_from_contract
 @contract_id nvarchar(400),
 @scenario_authority nvarchar(max)
WITH EXECUTE AS OWNER AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @contract_id IS NULL OR NOT EXISTS(SELECT 1 FROM model.contract WHERE contract_id=@contract_id)
  THROW 51000,'SCENARIO_CONTRACT_NOT_DECLARED',1;
 IF @scenario_authority IS NULL OR ISJSON(@scenario_authority)<>1
  THROW 51000,'SCENARIO_AUTHORITY_INVALID',1;
 DECLARE @capability_id nvarchar(400)=JSON_VALUE(@scenario_authority,'$.capabilityId');
 IF @capability_id IS NULL THROW 51000,'SCENARIO_CAPABILITY_REQUIRED',1;
 IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=@capability_id) THROW 51000,'CAPABILITY_NOT_FOUND',1;
 DECLARE @input_contract nvarchar(400)=JSON_VALUE(@scenario_authority,'$.input.contract');
 DECLARE @input_schema nvarchar(max)=JSON_QUERY(@scenario_authority,'$.input.schema');
 DECLARE @outcome_contract nvarchar(400)=JSON_VALUE(@scenario_authority,'$.outcome.contract');
 DECLARE @outcome_schema nvarchar(max)=JSON_QUERY(@scenario_authority,'$.outcome.schema');
 IF @input_contract IS NULL OR @outcome_contract IS NULL THROW 51000,'SCENARIO_CONTRACT_NOT_DECLARED',1;
 EXEC model.declare_contract @id=@input_contract,@schema=@input_schema;
 EXEC model.declare_contract @id=@outcome_contract,@schema=@outcome_schema;
 DECLARE @scenario nvarchar(max)=JSON_QUERY(@scenario_authority,'$.scenario');
 IF @scenario IS NULL THROW 51000,'SCENARIO_FACES_REQUIRED',1;
 DECLARE @operations nvarchar(max)=JSON_QUERY(@scenario_authority,'$.operations');
 DECLARE @port_bindings nvarchar(max)=JSON_QUERY(@scenario_authority,'$.portBindings');
 IF @operations IS NULL OR @port_bindings IS NULL THROW 51000,'SCENARIO_OPERATION_BINDING_NOT_DECLARED',1;
 EXEC model.declare_scenario @capability_id=@capability_id,@scenario=@scenario,@operations=@operations,@port_bindings=@port_bindings;
 SELECT 'declare_scenario_from_contract' AS result_set, @contract_id AS contract_id, @capability_id AS capability_id,
  JSON_VALUE(@scenario,'$.scenarioId') AS scenario_id;
END
GO
SELECT 'declare_scenario_from_contract_procedure' AS result_set,
 CASE WHEN OBJECT_ID(N'model.declare_scenario_from_contract') IS NOT NULL THEN N'READY' ELSE N'MISSING' END
COMMIT TRANSACTION;
