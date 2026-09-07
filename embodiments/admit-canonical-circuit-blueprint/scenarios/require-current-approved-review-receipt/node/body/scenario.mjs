// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "require-current-approved-review-receipt",
    ["input"]: {
        ["inputId"]: "canonical-blueprint-admission-request",
        ["contract"]: {
            ["contractId"]: "canonical-blueprint-admission-request.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "require-current-approved-review-receipt",
        ["executionAuthorityId"]: "require-current-approved-review-receipt.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "review-obligation-disposition",
        ["contract"]: {
            ["contractId"]: "blueprint-admission-obligation-disposition.v1"
        },
        ["experience"]: {
            ["statement"]: "a hold or reject disposition, a receipt whose reviewed digests no longer match, and an absent receipt are each unmet obligations, and no assurance profile waives this requirement"
        }
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "require-current-approved-review-receipt.given",
            ["text"]: "one admission request naming a candidate and its review receipt"
        },
        ["when"]: {
            ["semanticRef"]: "require-current-approved-review-receipt.when",
            ["text"]: "the receipt disposition is resolved and every reviewed digest is compared with the current candidate authority"
        },
        ["then"]: {
            ["semanticRef"]: "require-current-approved-review-receipt.then",
            ["text"]: "a hold or reject disposition, a receipt whose reviewed digests no longer match, and an absent receipt are each unmet obligations, and no assurance profile waives this requirement"
        }
    },
    ["name"]: "Require one current approved review receipt whose digests still match"
};
export class RequireCurrentApprovedReviewReceiptScenario {
    static capabilityId = "admit-canonical-circuit-blueprint";
    static scenarioId = "require-current-approved-review-receipt";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const root = context.rootInput ?? input;
        const requireCurrentApprovedReviewReceiptPortResult = await this.dependencies["require-current-approved-review-receipt-port"].execute(input, root);
        return requireCurrentApprovedReviewReceiptPortResult;
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
