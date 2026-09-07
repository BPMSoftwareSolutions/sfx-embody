// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "verify-jmi-record-binding",
    ["input"]: {
        ["inputId"]: "job-market-intelligence-adapter-record",
        ["contract"]: {
            ["contractId"]: "job-market-intelligence-adapter-record.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "jmi-record-binding-verification-requested",
        ["executionAuthorityId"]: "verify-jmi-record-binding.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "job-market-intelligence-adapter-record",
        ["contract"]: {
            ["contractId"]: "job-market-intelligence-adapter-record.v1"
        },
        ["experience"]: {
            ["statement"]: "the reference and the content digest are declared, reporting JMI_RECORD_UNBOUND otherwise"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "verify-jmi-record-binding.given",
            ["text"]: "one JMI record reference and one JMI content digest"
        },
        ["when"]: {
            ["semanticRef"]: "verify-jmi-record-binding.when",
            ["text"]: "record binding verification is evaluated"
        },
        ["then"]: {
            ["semanticRef"]: "verify-jmi-record-binding.then",
            ["text"]: "the reference and the content digest are declared, reporting JMI_RECORD_UNBOUND otherwise"
        }
    },
    ["name"]: "Verify the JMI record binding"
};
export class VerifyJmiRecordBindingScenario {
    static capabilityId = "adapt-job-market-intelligence-evidence";
    static scenarioId = "verify-jmi-record-binding";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const root = input;
        const verifyJmiRecordBindingPortResult = await this.dependencies["verify-jmi-record-binding-port"].execute(input, root);
        return verifyJmiRecordBindingPortResult;
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
