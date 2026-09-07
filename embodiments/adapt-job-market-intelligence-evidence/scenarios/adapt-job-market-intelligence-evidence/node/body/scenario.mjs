// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "adapt-job-market-intelligence-evidence",
    ["input"]: {
        ["inputId"]: "job-market-intelligence-adapter-record",
        ["contract"]: {
            ["contractId"]: "job-market-intelligence-adapter-record.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "job-market-intelligence-adaptation-requested",
        ["executionAuthorityId"]: "adapt-job-market-intelligence-evidence.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "job-market-intelligence-adapter-record",
        ["contract"]: {
            ["contractId"]: "job-market-intelligence-adapter-record.v1"
        },
        ["experience"]: {
            ["statement"]: "the adaptation is ADAPTED_EVIDENCE_BINDING or ADAPTATION_HELD with the exact holding finding, and a receipt binds the JMI record reference, type, digest, and disposition"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "adapt-job-market-intelligence-evidence.given",
            ["text"]: "one JMI record reference, one admitted JMI record type, one content digest, one adapter authority identity, and one observation window"
        },
        ["when"]: {
            ["semanticRef"]: "adapt-job-market-intelligence-evidence.when",
            ["text"]: "the JMI evidence adaptation is evaluated"
        },
        ["then"]: {
            ["semanticRef"]: "adapt-job-market-intelligence-evidence.then",
            ["text"]: "the adaptation is ADAPTED_EVIDENCE_BINDING or ADAPTATION_HELD with the exact holding finding, and a receipt binds the JMI record reference, type, digest, and disposition"
        }
    },
    ["name"]: "Adapt one Job Market Intelligence evidence record"
};
export class AdaptJobMarketIntelligenceEvidenceScenario {
    static capabilityId = "adapt-job-market-intelligence-evidence";
    static scenarioId = "adapt-job-market-intelligence-evidence";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const root = context.rootInput ?? input;
        const adaptJobMarketIntelligenceEvidencePortResult = await this.dependencies["adapt-job-market-intelligence-evidence-port"].execute(input, root);
        const jobMarketIntelligenceAdapterRecordResult = await this.dependencies["verify-jmi-record-binding"].invoke(adaptJobMarketIntelligenceEvidencePortResult, context, 1);
        const jobMarketIntelligenceAdapterRecordResult$occurrence = await this.dependencies["verify-jmi-type-admission"].invoke(jobMarketIntelligenceAdapterRecordResult, context, 2);
        const jobMarketIntelligenceAdapterRecordResult$occurrence$occurrence = await this.dependencies["bind-jmi-adapter-receipt"].invoke(jobMarketIntelligenceAdapterRecordResult$occurrence, context, 3);
        return jobMarketIntelligenceAdapterRecordResult$occurrence$occurrence;
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
