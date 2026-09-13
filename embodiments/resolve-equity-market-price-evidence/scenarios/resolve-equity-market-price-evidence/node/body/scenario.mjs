// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "resolve-equity-market-price-evidence",
    ["input"]: {
        ["inputId"]: "live-equity-price-request",
        ["contract"]: {
            ["contractId"]: "live-equity-price-request.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "equity-market-price-evidence-requested",
        ["executionAuthorityId"]: "resolve-equity-market-price-evidence.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "equity-market-price-evidence",
        ["contract"]: {
            ["contractId"]: "equity-market-price-evidence.v1"
        },
        ["experience"]: {
            ["statement"]: "the canonical evidence retains symbol, region, currency, price, market time, market state, exchange, source attribution, and provider testimony identity"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "resolve-equity-market-price-evidence.given",
            ["text"]: "a canonical symbol and region, an admitted provider route, an exact native mapping, and bounded exchange authority"
        },
        ["when"]: {
            ["semanticRef"]: "resolve-equity-market-price-evidence.when",
            ["text"]: "equity market-price evidence is resolved"
        },
        ["then"]: {
            ["semanticRef"]: "resolve-equity-market-price-evidence.then",
            ["text"]: "the canonical evidence retains symbol, region, currency, price, market time, market state, exchange, source attribution, and provider testimony identity"
        }
    },
    ["name"]: "Resolve an equity price observation through an admitted provider binding"
};
export class ResolveEquityMarketPriceEvidenceScenario {
    static capabilityId = "resolve-equity-market-price-evidence";
    static scenarioId = "resolve-equity-market-price-evidence";
    constructor(dependencies, contracts, observer, clock, effectContext) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
        this.effectContext = effectContext;
    }
    async perform(input, context) {
        const root = input;
        const resolveEquityMarketPriceEvidencePortResult = await this.dependencies["resolve-equity-market-price-evidence-port"].execute(input, root);
        const equityMarketPriceEvidenceResult = await this.dependencies["retain-provider-realization-outside-market-price-semantics"].invoke(resolveEquityMarketPriceEvidencePortResult, context, 1);
        const equityMarketPriceProviderUnavailableResult = await this.dependencies["hold-unavailable-equity-market-price-provider"].invoke(equityMarketPriceEvidenceResult, context, 2);
        const nativeEquityMarketPriceTestimonyRejectedResult = await this.dependencies["reject-nonconforming-native-market-price-testimony"].invoke(equityMarketPriceProviderUnavailableResult, context, 3);
        return nativeEquityMarketPriceTestimonyRejectedResult;
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
