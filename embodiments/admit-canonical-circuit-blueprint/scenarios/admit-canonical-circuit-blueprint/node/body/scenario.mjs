// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "admit-canonical-circuit-blueprint",
    ["input"]: {
        ["inputId"]: "canonical-blueprint-admission-request",
        ["contract"]: {
            ["contractId"]: "canonical-blueprint-admission-request.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "admit-canonical-circuit-blueprint",
        ["executionAuthorityId"]: "admit-canonical-circuit-blueprint.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "admitted-canonical-circuit-blueprint",
        ["contract"]: {
            ["contractId"]: "admitted-canonical-circuit-blueprint.v1"
        },
        ["experience"]: {
            ["statement"]: "immutable blueprint authority with a stable digest is emitted only when every obligation closes, and otherwise an exact rejection naming the unmet obligation is returned"
        },
        ["terminal"]: true
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "admit-canonical-circuit-blueprint.given",
            ["text"]: "one blueprint candidate with its conformance evidence, geometry proof, and review receipt"
        },
        ["when"]: {
            ["semanticRef"]: "admit-canonical-circuit-blueprint.when",
            ["text"]: "each required obligation is resolved and the reviewed digests are compared with the candidate authority"
        },
        ["then"]: {
            ["semanticRef"]: "admit-canonical-circuit-blueprint.then",
            ["text"]: "immutable blueprint authority with a stable digest is emitted only when every obligation closes, and otherwise an exact rejection naming the unmet obligation is returned"
        }
    },
    ["name"]: "Emit immutable blueprint authority only when every admission obligation closes"
};
export class AdmitCanonicalCircuitBlueprintScenario {
    static capabilityId = "admit-canonical-circuit-blueprint";
    static scenarioId = "admit-canonical-circuit-blueprint";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const root = context.rootInput ?? input;
        const admitCanonicalCircuitBlueprintPortResult = await this.dependencies["admit-canonical-circuit-blueprint-port"].execute(input, root);
        const conformanceObligationDispositionResult = await this.dependencies["require-blueprint-conformance-evidence"].invoke(admitCanonicalCircuitBlueprintPortResult, context, 1);
        const geometryObligationDispositionResult = await this.dependencies["require-blueprint-geometry-proof"].invoke(conformanceObligationDispositionResult, context, 2);
        const reviewObligationDispositionResult = await this.dependencies["require-current-approved-review-receipt"].invoke(geometryObligationDispositionResult, context, 3);
        const admittedCanonicalCircuitBlueprintResult = await this.dependencies["emit-immutable-blueprint-authority"].invoke(reviewObligationDispositionResult, context, 4);
        return admittedCanonicalCircuitBlueprintResult;
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
