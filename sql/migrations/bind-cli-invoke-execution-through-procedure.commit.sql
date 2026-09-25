-- Binds sda-cli-invoke-port to the execution boundary through model.bind_port_from_contract.
-- COMMIT twin of bind-cli-invoke-execution-through-procedure.sql.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=N'sda-cli')
 THROW 51000,'CAPABILITY_NOT_FOUND',1;
GO
EXEC model.declare_contract @id=N'sda-cli-port-binding.v1', @schema=N'{"type":"object","additionalProperties":false,"required":["capabilityId","portId","platformCapabilityId","providerId","configuration"],"properties":{"capabilityId":{"type":"string","minLength":1},"portId":{"type":"string","minLength":1},"platformCapabilityId":{"type":"string","minLength":1},"providerId":{"type":"string","minLength":1},"configuration":{"type":"object"}}}';
GO
DECLARE @port_binding_authority nvarchar(max)=N'{"capabilityId":"sda-cli","portId":"sda-cli-invoke-port","platformCapabilityId":"sda-projected-capability-invocation-port.v2","providerId":"ScenarioKernel.NodePlatform.Execution.ProjectedCapabilityInvocationAndBinding","configuration":{"providerId":"ScenarioKernel.NodePlatform.Execution.ProjectedCapabilityInvocationAndBinding"}}';
EXEC model.bind_port_from_contract @contract_id=N'sda-cli-port-binding.v1', @port_binding_authority=@port_binding_authority;
GO
SELECT 'cli_invoke_execution_binding_through_procedure' AS result_set, p.port_id, pv.port_version_pk,
 JSON_VALUE(dt.text,'$.semantics.platformCapabilityId') AS platform_capability,
 JSON_VALUE(dt.text,'$.semantics.configuration.providerId') AS bound_provider
FROM model.port p
JOIN model.port_version pv ON pv.port_pk=p.port_pk
JOIN model.semantic_object_definition sod ON sod.semantic_object_definition_pk=pv.semantic_object_definition_pk
JOIN source.content_object co ON co.content_object_pk=sod.canonical_content_pk
CROSS APPLY (SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text) dt
WHERE p.port_id=N'sda-cli-invoke-port';
COMMIT TRANSACTION;
