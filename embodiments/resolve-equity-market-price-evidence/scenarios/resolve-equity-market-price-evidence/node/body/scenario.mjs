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
            ["text"]: "a canonical symbol and region and one admitted provider endpoint authority"
        },
        ["when"]: {
            ["semanticRef"]: "resolve-equity-market-price-evidence.when",
            ["text"]: "the credential reference is bound, one bounded exchange is observed, and the native testimony is normalized"
        },
        ["then"]: {
            ["semanticRef"]: "resolve-equity-market-price-evidence.then",
            ["text"]: "the canonical evidence retains symbol, region, currency, price, market time, market state, exchange, source attribution, and provider testimony identity"
        }
    },
    ["name"]: "Resolve an equity price observation through a declared provider binding"
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
        const buildEquityPriceBindingRequestResult = await this.dependencies["build-equity-price-binding-request"].execute(input, root);
        const bindEquityPriceProviderCredentialResult = await this.dependencies["bind-equity-price-provider-credential"].execute(buildEquityPriceBindingRequestResult, root, context, this.effectContext);
        const buildEquityPriceExchangeRequestResult = await this.dependencies["build-equity-price-exchange-request"].execute(bindEquityPriceProviderCredentialResult, root);
        const observeEquityPriceExchangeResult = await this.dependencies["observe-equity-price-exchange"].execute(buildEquityPriceExchangeRequestResult, root, context, this.effectContext);
        const normalizeEquityPriceEvidenceResult = await this.dependencies["normalize-equity-price-evidence"].execute(observeEquityPriceExchangeResult, root);
        return normalizeEquityPriceEvidenceResult;
    }
    async execute(input, context) {
        const stop = { execution: null };
        const scoped = { ...context, input, __compositionStop: stop };
        const kernel = new ScenarioKernel(this.contracts, {
            async resolve(event) {
                if (event.executionAuthorityId !== declaration.event.executionAuthorityId)
                    throw new Error('EXECUTION_AUTHORITY_DIVERGENCE');
                return { executionAuthorityId: event.executionAuthorityId, handler: declaration.event };
            }
        }, { execute: async (_authority, value) => this.perform(value, scoped) }, new DispositionResolver(), this.observer, this.clock);
        const execution = await kernel.execute(declaration, scoped);
        // A composed child that reached a governed stop owns the disposition. The
        // kernel maps its executor's throw to 'failed', so the child's execution is
        // returned instead: composition stops at the first non-success and the
        // composed disposition/outcome is surfaced, not collapsed to a failure.
        if (stop.execution) {
            if (context.__compositionStop)
                context.__compositionStop.execution = stop.execution;
            return stop.execution;
        }
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
        if (execution.disposition === 'failed' || execution.disposition === 'rejected') {
            if (parent.__compositionStop)
                parent.__compositionStop.execution = execution;
            const stopped = new Error('COMPOSITION_STOP:' + execution.scenarioId + ':' + execution.disposition);
            stopped.__compositionStop = true;
            throw stopped;
        }
        return execution.outcome;
    }
}
