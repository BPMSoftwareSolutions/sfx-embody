// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "resolve-sidefx-eligible-providers",
    ["input"]: {
        ["inputId"]: "sidefx-provider-resolution-request",
        ["contract"]: {
            ["contractId"]: "sidefx-provider-resolution-request.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "sidefx-provider-resolution-requested",
        ["executionAuthorityId"]: "resolve-sidefx-eligible-providers.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "sidefx-semantic-provider-resolution",
        ["contract"]: {
            ["contractId"]: "sidefx-semantic-provider-resolution.v1"
        },
        ["experience"]: {
            ["statement"]: "eligible providers cite exact binding, profile, policy, authority, and conformance evidence and every other provider is NOT_OBSERVABLE, INELIGIBLE, or NOT_APPLICABLE with its reason"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "resolve-sidefx-eligible-providers.given",
            ["text"]: "declared provider bindings, a requested platform capability, a requested target, and the admitted conformant dispositions"
        },
        ["when"]: {
            ["semanticRef"]: "resolve-sidefx-eligible-providers.when",
            ["text"]: "each binding is checked for capability match, admission, conformance evidence, and declared target"
        },
        ["then"]: {
            ["semanticRef"]: "resolve-sidefx-eligible-providers.then",
            ["text"]: "eligible providers cite exact binding, profile, policy, authority, and conformance evidence and every other provider is NOT_OBSERVABLE, INELIGIBLE, or NOT_APPLICABLE with its reason"
        }
    },
    ["name"]: "Admit only providers whose binding, conformance, and target are declared"
};
export class ResolveSidefxEligibleProvidersScenario {
    static capabilityId = "resolve-sidefx-eligible-providers";
    static scenarioId = "resolve-sidefx-eligible-providers";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const resolveSidefxEligibleProvidersPortResult = await this.dependencies["resolve-sidefx-eligible-providers-port"].execute(input, context.rootInput);
        return resolveSidefxEligibleProvidersPortResult;
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
