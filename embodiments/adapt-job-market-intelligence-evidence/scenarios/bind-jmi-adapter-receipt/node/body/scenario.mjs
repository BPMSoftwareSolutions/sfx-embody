// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "bind-jmi-adapter-receipt",
    ["input"]: {
        ["inputId"]: "job-market-intelligence-adapter-record",
        ["contract"]: {
            ["contractId"]: "job-market-intelligence-adapter-record.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "jmi-adapter-receipt-binding-requested",
        ["executionAuthorityId"]: "bind-jmi-adapter-receipt.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "job-market-intelligence-adapter-record",
        ["contract"]: {
            ["contractId"]: "job-market-intelligence-adapter-record.v1"
        },
        ["experience"]: {
            ["statement"]: "the JMI record reference, record type, content digest, and disposition bind into one replayable JMI adapter receipt"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "bind-jmi-adapter-receipt.given",
            ["text"]: "one adaptation disposition over one JMI record reference"
        },
        ["when"]: {
            ["semanticRef"]: "bind-jmi-adapter-receipt.when",
            ["text"]: "the adapter receipt is bound"
        },
        ["then"]: {
            ["semanticRef"]: "bind-jmi-adapter-receipt.then",
            ["text"]: "the JMI record reference, record type, content digest, and disposition bind into one replayable JMI adapter receipt"
        }
    },
    ["name"]: "Bind one JMI adapter receipt"
};
export class BindJmiAdapterReceiptScenario {
    static capabilityId = "adapt-job-market-intelligence-evidence";
    static scenarioId = "bind-jmi-adapter-receipt";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const root = context.rootInput ?? input;
        const bindJmiAdapterReceiptPortResult = await this.dependencies["bind-jmi-adapter-receipt-port"].execute(input, root);
        return bindJmiAdapterReceiptPortResult;
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
