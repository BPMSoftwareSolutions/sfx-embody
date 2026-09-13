// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "hold-unavailable-equity-market-price-provider",
    ["input"]: {
        ["inputId"]: "equity-market-price-evidence-request",
        ["contract"]: {
            ["contractId"]: "equity-market-price-evidence-request.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "equity-market-price-provider-unavailable",
        ["executionAuthorityId"]: "hold-unavailable-equity-market-price-provider.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "equity-market-price-provider-unavailable",
        ["contract"]: {
            ["contractId"]: "equity-market-price-provider-unavailable.v1"
        },
        ["experience"]: {
            ["statement"]: "resolution is held with attributable provider attempt evidence and no price evidence is invented"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "hold-unavailable-equity-market-price-provider.given",
            ["text"]: "every admitted route is unavailable, ineligible, exhausted, or rejected"
        },
        ["when"]: {
            ["semanticRef"]: "hold-unavailable-equity-market-price-provider.when",
            ["text"]: "equity market-price evidence is resolved"
        },
        ["then"]: {
            ["semanticRef"]: "hold-unavailable-equity-market-price-provider.then",
            ["text"]: "resolution is held with attributable provider attempt evidence and no price evidence is invented"
        }
    },
    ["name"]: "Hold resolution when no admitted provider route can complete"
};
export class HoldUnavailableEquityMarketPriceProviderScenario {
    static capabilityId = "resolve-equity-market-price-evidence";
    static scenarioId = "hold-unavailable-equity-market-price-provider";
    constructor(dependencies, contracts, observer, clock, effectContext) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
        this.effectContext = effectContext;
    }
    async perform(input, context) {
        const root = input;
        const holdUnavailableEquityMarketPriceProviderPortResult = await this.dependencies["hold-unavailable-equity-market-price-provider-port"].execute(input, root);
        return holdUnavailableEquityMarketPriceProviderPortResult;
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
