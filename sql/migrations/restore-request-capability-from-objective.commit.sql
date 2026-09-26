-- restore-request-capability-from-objective.commit.sql
--
-- COMMIT twin of restore-request-capability-from-objective.sql. Restores the
-- working execution wiring of capability 100695 (request-capability-from-objective),
-- scenario execute-admitted-proposal sv 91540, after the
-- declare-invoke-scenario-on-existing-capability lane re-declared the scenario.
-- That re-declaration ran the existing UPDATE path
-- `UPDATE model.scenario_outcome_contract SET contract_version_pk=@out_version`
-- and reset the parent's outcome contract to agent-admitted-evidence.v1,
-- clobbering the deliberate repoint this estate's own declaration performs.
--
-- Evidence for the working state (base rows):
--   sql/migrations/declare-agent-capability.sql:167-192 declares
--   execute-admitted-proposal with outcomeContract agent-admitted-evidence.v1,
--   then explicitly repoints model.scenario_outcome_contract for the admitted
--   child's scenario_version to the invoked capability's own evidence contract
--   (equity-market-price-evidence.v1, MAX contract_version at declaration time):
--   "The admitted child's outcome is the invoked capability's own evidence
--   contract" (lines 179-181). With parent op2's outcome contract equal to the
--   child exit contract, the graph compiler synthesizes no invoke-return edge
--   (SemanticExecutionGraphCompiler.cs:445-447), so the graph executes through
--   the generic execution boundary (projectBinding: null).
--   The same migration mints the working authority version in the envelope key
--   order {id, operations, owningScenarioId} (lines 332-335) and links the
--   scenario_event to it (lines 366-394): that is eav 111617,
--   digest 13da9e87dc7cb4fe47a60a03649b18c6d22c684a1e48a69eee907aab52960708,
--   operations 2628/2629, osi target sv 898.
--   The lane's committed declare_scenario run minted eav 112514
--   (digest 543bf6ec544209ac74516651220b046226aaaa1bdd100e7c5205ac9c68f36919,
--   semantically identical, serialization key order only) and reset the
--   contract link to agent-admitted-evidence.v1 (contract_version 111680),
--   which is the refusal currently observed:
--   UNDECLARED_EDGE_BINDING_MECHANIC
--   'binding:invoke-return:cell:mechanic:execute-admitted-proposal.operation.2'.
--
-- This restore touches only two links:
--   1. model.scenario_event.execution_authority_version_pk -> 111617
--   2. model.scenario_outcome_contract.contract_version_pk -> the equity
--      evidence contract version the child exit currently links (MAX equity
--      contract_version, exactly the original declaration rule).
-- No port, operation, osi, provider or definition row is deleted or rewritten;
-- osi targets are already the working target (sv 898) on both eav candidates.
--
-- Idempotent: the UPDATEs are value-replays; a second run reports
-- ALREADY_RESTORED and changes nothing.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @capability_id nvarchar(400)=N'request-capability-from-objective';
DECLARE @scenario_version bigint=91540;
DECLARE @working_eav bigint=111617;
DECLARE @working_eav_digest binary(32)=CONVERT(binary(32),N'13da9e87dc7cb4fe47a60a03649b18c6d22c684a1e48a69eee907aab52960708',2);
DECLARE @clobbered_eav bigint=112514;

DECLARE @capability_pk bigint=(SELECT c.capability_pk FROM model.capability c
 JOIN model.identity_namespace n ON n.namespace_pk=c.namespace_pk AND n.namespace_id=N'sidefx:capabilities'
 WHERE c.capability_id=@capability_id);
IF @capability_pk IS NULL THROW 51000,'RESTORE_CAPABILITY_NOT_FOUND',1;
IF NOT EXISTS (SELECT 1 FROM model.capability_scenario cs
 JOIN model.scenario s ON s.scenario_pk=cs.scenario_pk
 WHERE cs.capability_pk=@capability_pk AND s.scenario_id=N'execute-admitted-proposal' AND cs.scenario_version_pk=@scenario_version)
 THROW 51000,'RESTORE_SCENARIO_VERSION_NOT_SELECTED',1;
IF NOT EXISTS (SELECT 1 FROM model.execution_authority_version eav
 WHERE eav.execution_authority_version_pk=@working_eav AND eav.definition_digest=@working_eav_digest)
 THROW 51000,'RESTORE_WORKING_AUTHORITY_VERSION_NOT_FOUND',1;
IF NOT EXISTS (SELECT 1 FROM model.execution_operation eo
 WHERE eo.execution_authority_version_pk=@working_eav AND eo.ordinal=1 AND eo.operation_kind=N'invoke-scenario')
 THROW 51000,'RESTORE_WORKING_AUTHORITY_INVOKE_OPERATION_NOT_FOUND',1;

DECLARE @child_exit_cv bigint=(SELECT TOP 1 cv.contract_version_pk
 FROM model.contract ct JOIN model.contract_version cv ON cv.contract_pk=ct.contract_pk
 WHERE ct.contract_id=N'equity-market-price-evidence.v1' ORDER BY cv.contract_version_pk DESC);
IF @child_exit_cv IS NULL THROW 51000,'RESTORE_EQUITY_OUTCOME_CONTRACT_NOT_FOUND',1;

DECLARE @event_before bigint=(SELECT execution_authority_version_pk FROM model.scenario_event WHERE scenario_version_pk=@scenario_version);
DECLARE @soc_before bigint=(SELECT contract_version_pk FROM model.scenario_outcome_contract WHERE scenario_version_pk=@scenario_version);
IF @event_before IS NULL OR @soc_before IS NULL THROW 51000,'RESTORE_SCENARIO_LINKS_NOT_FOUND',1;
DECLARE @disposition nvarchar(40)=CASE WHEN @event_before=@working_eav AND @soc_before=@child_exit_cv THEN N'ALREADY_RESTORED' ELSE N'RESTORED' END;

UPDATE model.scenario_event SET execution_authority_version_pk=@working_eav
 WHERE scenario_version_pk=@scenario_version;
UPDATE model.scenario_outcome_contract SET contract_version_pk=@child_exit_cv
 WHERE scenario_version_pk=@scenario_version;

SELECT '1_restore_disposition' AS result_set, @disposition AS disposition,
 @event_before AS event_eav_before, @working_eav AS event_eav_after,
 @soc_before AS outcome_contract_before, @child_exit_cv AS outcome_contract_after,
 @clobbered_eav AS clobbering_eav_observed, @estate AS estate_model_pk;

SELECT '2_parent_event_restored' AS result_set, se.scenario_version_pk, se.event_id,
 se.execution_authority_version_pk AS event_eav, ea.execution_authority_id,
 LOWER(CONVERT(varchar(64),eav.definition_digest,2)) AS authority_digest,
 eo.execution_operation_pk, eo.ordinal, eo.operation_kind, eo._canonical_pointer,
 osi.target_scenario_version_pk AS osi_target_sv
FROM model.scenario_event se
JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk=se.execution_authority_version_pk
JOIN model.execution_authority ea ON ea.execution_authority_pk=eav.execution_authority_pk
JOIN model.execution_operation eo ON eo.execution_authority_version_pk=eav.execution_authority_version_pk
LEFT JOIN model.operation_scenario_invocation osi ON osi.execution_operation_pk=eo.execution_operation_pk
WHERE se.scenario_version_pk=@scenario_version
ORDER BY eo.ordinal;

SELECT '3_outcome_contract_restored' AS result_set, soc.scenario_version_pk, soc.contract_version_pk,
 c.contract_id, LOWER(CONVERT(varchar(64),cv.definition_digest,2)) AS contract_digest,
 soc._owner_definition_pk, soc._canonical_pointer
FROM model.scenario_outcome_contract soc
JOIN model.contract_version cv ON cv.contract_version_pk=soc.contract_version_pk
JOIN model.contract c ON c.contract_pk=cv.contract_pk
WHERE soc.scenario_version_pk=@scenario_version;

DECLARE @g nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(@capability_id,0,NULL));
SELECT '4_graph_invoke_return_probe' AS result_set,
 JSON_VALUE(owner.value,'$.outcome.contract.contractId') AS owning_scenario_contract,
 JSON_VALUE(target.value,'$.outcome.contract.contractId') AS target_exit_contract,
 JSON_VALUE(op.value,'$.outcomeContractId') AS declared_operation_contract,
 CASE WHEN ISNULL(JSON_VALUE(op.value,'$.outcomeContractId'),JSON_VALUE(owner.value,'$.outcome.contract.contractId'))
       = JSON_VALUE(target.value,'$.outcome.contract.contractId')
   THEN N'MATCH' ELSE N'MISMATCH' END AS invoke_return_binding_needed
FROM OPENJSON(@g,'$.executionAuthorities') a
CROSS APPLY OPENJSON(a.value,'$.operations') op
OUTER APPLY (SELECT s.value FROM OPENJSON(@g,'$.scenarios') s
 WHERE JSON_VALUE(s.value,'$.scenarioId')=JSON_VALUE(a.value,'$.owningScenarioId')) owner
OUTER APPLY (SELECT s.value FROM OPENJSON(@g,'$.scenarios') s
 WHERE JSON_VALUE(s.value,'$.scenarioId')=JSON_VALUE(op.value,'$.scenarioId')) target
WHERE JSON_VALUE(a.value,'$.id')=N'execute-admitted-proposal.v1' AND JSON_VALUE(op.value,'$.kind')=N'invoke-scenario';

COMMIT TRANSACTION;
