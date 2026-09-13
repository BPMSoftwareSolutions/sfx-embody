// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "reject-nonconforming-native-market-price-testimony",
    ["input"]: {
        ["inputId"]: "native-equity-market-price-testimony",
        ["contract"]: {
            ["contractId"]: "native-equity-market-price-testimony.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "native-equity-market-price-testimony-observed",
        ["executionAuthorityId"]: "reject-nonconforming-native-market-price-testimony.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "native-equity-market-price-testimony-rejected",
        ["contract"]: {
            ["contractId"]: "native-equity-market-price-testimony-rejection.v1"
        },
        ["experience"]: {
            ["statement"]: "the testimony is rejected without widening the mapping or emitting canonical price evidence"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "reject-nonconforming-native-market-price-testimony.given",
            ["text"]: "bounded native testimony that is malformed, incomplete, contradictory, or outside its admitted mapping"
        },
        ["when"]: {
            ["semanticRef"]: "reject-nonconforming-native-market-price-testimony.when",
            ["text"]: "the native testimony is interpreted"
        },
        ["then"]: {
            ["semanticRef"]: "reject-nonconforming-native-market-price-testimony.then",
            ["text"]: "the testimony is rejected without widening the mapping or emitting canonical price evidence"
        }
    },
    ["name"]: "Reject native testimony that cannot satisfy the canonical mapping"
};
export class RejectNonconformingNativeMarketPriceTestimonyScenario {
    static capabilityId = "resolve-equity-market-price-evidence";
    static scenarioId = "reject-nonconforming-native-market-price-testimony";
    constructor(dependencies, contracts, observer, clock, effectContext) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
        this.effectContext = effectContext;
    }
    async perform(input, context) {
        const root = input;
        const rejectNonconformingNativeMarketPriceTestimonyPortResult = await this.dependencies["reject-nonconforming-native-market-price-testimony-port"].execute(input, root);
        return rejectNonconformingNativeMarketPriceTestimonyPortResult;
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
