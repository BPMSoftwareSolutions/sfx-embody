-- Declares the CLI `invoke` scenario through model.declare_scenario_from_contract.
-- COMMIT twin of declare-cli-invoke-scenario-through-procedure.sql.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM model.capability WHERE capability_id=N'sda-cli')
 EXEC model.scaffold_capability @capability_id=N'sda-cli', @on_exists=N'ERROR';
GO
EXEC model.declare_contract @id=N'sda-cli-scenario-declaration.v1', @schema=N'{"type":"object","additionalProperties":false,"required":["capabilityId","input","outcome","scenario","operations","portBindings"],"properties":{"capabilityId":{"type":"string","minLength":1},"input":{"type":"object","required":["contract","schema"]},"outcome":{"type":"object","required":["contract","schema"]},"scenario":{"type":"object","required":["scenarioId","eventId","eventAuthority","given","when","then"]},"operations":{"type":"array","minItems":1},"portBindings":{"type":"array","minItems":1}}}';
GO
DECLARE @scenario_authority nvarchar(max)=N'{"capabilityId":"sda-cli","input":{"contract":"sda-cli-invoke-request.v1","schema":{"type":"object","additionalProperties":false,"required":["capabilityId"],"properties":{"capabilityId":{"type":"string","minLength":1},"inputType":{"type":"string","minLength":1},"input":{},"namespace":{"type":"string","minLength":1},"scenario":{"type":"string","minLength":1}}}},"outcome":{"contract":"sda-cli-invoke-result.v1","schema":{"type":"object","additionalProperties":false,"required":["capabilityId","disposition"],"properties":{"capabilityId":{"type":"string"},"disposition":{"type":"string"},"result":{}}}},"scenario":{"scenarioId":"invoke","name":"Invoke a declared capability","inputId":"sda-cli-invoke-request","inputContract":"sda-cli-invoke-request.v1","eventId":"sda-cli-invoke-requested","eventAuthority":"sda-cli-invoke.v1","outcomeId":"sda-cli-invoke-result","outcomeContract":"sda-cli-invoke-result.v1","terminal":true,"given":"one declared capability identity and admitted input","when":"the CLI invoke carrier runs the selected capability","then":"the declared scenario output is delivered"},"operations":[{"operationId":"sda-cli-invoke.0","kind":"invoke-port","portId":"sda-cli-invoke-port"}],"portBindings":[{"portId":"sda-cli-invoke-port","platformCapabilityId":"sda-cli-invoke-port.v1","configuration":{"providerId":"sda-cli.invoke"}}]}';
EXEC model.declare_scenario_from_contract @contract_id=N'sda-cli-scenario-declaration.v1', @scenario_authority=@scenario_authority;
GO
SELECT 'cli_invoke_through_contract' AS result_set, c.capability_id, s.scenario_id, sv.scenario_version_pk,
 si.input_id, se.event_id, so.outcome_id, eo.operation_id, opi.port_version_pk
FROM model.capability c
JOIN model.capability_version cv ON cv.capability_pk=c.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk=cv.capability_version_pk
JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk=cs.scenario_version_pk
LEFT JOIN model.scenario_input si ON si.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_event se ON se.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.scenario_outcome so ON so.scenario_version_pk=sv.scenario_version_pk
LEFT JOIN model.execution_operation eo ON eo.execution_authority_version_pk=se.execution_authority_version_pk
LEFT JOIN model.operation_port_invocation opi ON opi.execution_operation_pk=eo.execution_operation_pk
WHERE c.capability_id=N'sda-cli' AND s.scenario_id=N'invoke';
COMMIT TRANSACTION;
