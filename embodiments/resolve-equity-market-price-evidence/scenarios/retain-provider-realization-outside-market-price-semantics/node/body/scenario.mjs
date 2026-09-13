// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "retain-provider-realization-outside-market-price-semantics",
    ["input"]: {
        ["inputId"]: "equity-market-price-evidence",
        ["contract"]: {
            ["contractId"]: "equity-market-price-evidence.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "equity-market-price-provider-testimony-observed",
        ["executionAuthorityId"]: "retain-equity-market-price-provider-testimony.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "equity-market-price-evidence",
        ["contract"]: {
            ["contractId"]: "equity-market-price-evidence.v1"
        },
        ["experience"]: {
            ["statement"]: "provider identity and native mapping identity are attributable realization evidence and do not enter the canonical capability identity"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "retain-provider-realization-outside-market-price-semantics.given",
            ["text"]: "canonical price evidence and the exact provider realization that produced it"
        },
        ["when"]: {
            ["semanticRef"]: "retain-provider-realization-outside-market-price-semantics.when",
            ["text"]: "provider testimony is retained"
        },
        ["then"]: {
            ["semanticRef"]: "retain-provider-realization-outside-market-price-semantics.then",
            ["text"]: "provider identity and native mapping identity are attributable realization evidence and do not enter the canonical capability identity"
        }
    },
    ["name"]: "Bind supplier testimony without changing the canonical finance promise"
};
export class RetainProviderRealizationOutsideMarketPriceSemanticsScenario {
    static capabilityId = "resolve-equity-market-price-evidence";
    static scenarioId = "retain-provider-realization-outside-market-price-semantics";
    constructor(dependencies, contracts, observer, clock, effectContext) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
        this.effectContext = effectContext;
    }
    async perform(input, context) {
        const root = input;
        const retainProviderRealizationOutsideMarketPriceSemanticsPortResult = await this.dependencies["retain-provider-realization-outside-market-price-semantics-port"].execute(input, root);
        return retainProviderRealizationOutsideMarketPriceSemanticsPortResult;
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
