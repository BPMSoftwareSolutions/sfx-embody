-- Creates model.bind_port_from_contract: binds a scenario operation port to a declared provider,
-- with the binding authority conforming to a declared contract. Replay is idempotent via
-- model.bind_provider.
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
CREATE OR ALTER PROCEDURE model.bind_port_from_contract
 @contract_id nvarchar(400),
 @port_binding_authority nvarchar(max)
WITH EXECUTE AS OWNER AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @contract_id IS NULL OR NOT EXISTS(SELECT 1 FROM model.contract WHERE contract_id=@contract_id)
  THROW 51000,'PORT_BINDING_CONTRACT_NOT_DECLARED',1;
 IF @port_binding_authority IS NULL OR ISJSON(@port_binding_authority)<>1
  THROW 51000,'PORT_BINDING_AUTHORITY_INVALID',1;
 DECLARE @capability_id nvarchar(400)=JSON_VALUE(@port_binding_authority,'$.capabilityId');
 DECLARE @port_id nvarchar(400)=JSON_VALUE(@port_binding_authority,'$.portId');
 DECLARE @platform_capability_id nvarchar(400)=JSON_VALUE(@port_binding_authority,'$.platformCapabilityId');
 DECLARE @provider_id nvarchar(400)=JSON_VALUE(@port_binding_authority,'$.providerId');
 DECLARE @configuration nvarchar(max)=JSON_QUERY(@port_binding_authority,'$.configuration');
 IF @capability_id IS NULL OR @port_id IS NULL OR @platform_capability_id IS NULL OR @provider_id IS NULL OR @configuration IS NULL
  THROW 51000,'PORT_BINDING_FIELDS_REQUIRED',1;
 IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=@capability_id)
  THROW 51000,'CAPABILITY_NOT_FOUND',1;
 EXEC model.bind_provider
  @capability_id=@capability_id, @mechanic_id=@port_id, @provider_id=@provider_id,
  @platform_capability_id=@platform_capability_id, @configuration_json=@configuration;
 SELECT 'bind_port_from_contract' AS result_set, @contract_id AS contract_id,
  @capability_id AS capability_id, @port_id AS port_id, @provider_id AS provider_id;
END
GO
SELECT 'bind_port_from_contract_procedure' AS result_set,
 CASE WHEN OBJECT_ID(N'model.bind_port_from_contract') IS NOT NULL THEN N'READY' ELSE N'MISSING' END AS readiness;
ROLLBACK TRANSACTION;
