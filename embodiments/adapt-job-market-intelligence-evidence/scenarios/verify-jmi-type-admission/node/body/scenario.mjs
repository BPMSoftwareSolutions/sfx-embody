// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "verify-jmi-type-admission",
    ["input"]: {
        ["inputId"]: "job-market-intelligence-adapter-record",
        ["contract"]: {
            ["contractId"]: "job-market-intelligence-adapter-record.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "jmi-type-admission-verification-requested",
        ["executionAuthorityId"]: "verify-jmi-type-admission.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "job-market-intelligence-adapter-record",
        ["contract"]: {
            ["contractId"]: "job-market-intelligence-adapter-record.v1"
        },
        ["experience"]: {
            ["statement"]: "the type is one of the admitted JMI record types under the adapter authority, reporting JMI_RECORD_TYPE_UNADMITTED or ADAPTER_AUTHORITY_UNADMITTED otherwise"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "verify-jmi-type-admission.given",
            ["text"]: "one JMI record type and one adapter authority identity"
        },
        ["when"]: {
            ["semanticRef"]: "verify-jmi-type-admission.when",
            ["text"]: "type admission verification is evaluated"
        },
        ["then"]: {
            ["semanticRef"]: "verify-jmi-type-admission.then",
            ["text"]: "the type is one of the admitted JMI record types under the adapter authority, reporting JMI_RECORD_TYPE_UNADMITTED or ADAPTER_AUTHORITY_UNADMITTED otherwise"
        }
    },
    ["name"]: "Verify the JMI record type against the admitted adapter vocabulary"
};
export class VerifyJmiTypeAdmissionScenario {
    static capabilityId = "adapt-job-market-intelligence-evidence";
    static scenarioId = "verify-jmi-type-admission";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const root = context.rootInput ?? input;
        const verifyJmiTypeAdmissionPortResult = await this.dependencies["verify-jmi-type-admission-port"].execute(input, root);
        return verifyJmiTypeAdmissionPortResult;
    }
    async execute(input, context) {
        const kernel = new ScenarioKernel(this.contracts, {
            async resolve(event) {
                if (event.executionAuthorityId !== declaration.event.executionAuthorityId)
                    throw new Error('EXECUTION_AUTHORITY_DIVERGENCE');
                return { executionAuthorityId: event.executionAuthorityId, handler: declaration.event };
            }
        }, { execute: async (_authority, value) => this.perform(value, context) }, new DispositionResolver(), this.observer, this.clock);
        const execution = await kernel.execute(declaration, { ...context, input });
        context.collect?.(execution);
        return execution;
    }
    async invoke(input, parent, ordinal) {
        const ancestry = parent.ancestry ?? [];
        if (ancestry.includes(declaration.scenarioId))
            throw new Error('RECURSIVE_SCENARIO_INVOCATION');
        const execution = await this.execute(input, { ...parent,
            executionId: parent.executionId + '/' + ordinal + '/' + declaration.scenarioId,
            rootInput: structuredClone(input), parentExecutionId: parent.executionId, ancestry: [...ancestry, declaration.scenarioId]
        });
        if (execution.disposition === 'failed' || execution.disposition === 'rejected')
            throw new Error('CHILD_SCENARIO_' + execution.disposition.toUpperCase());
        return execution.outcome;
    }
}
