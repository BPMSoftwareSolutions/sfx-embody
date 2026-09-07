// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "require-blueprint-geometry-proof",
    ["input"]: {
        ["inputId"]: "canonical-blueprint-admission-request",
        ["contract"]: {
            ["contractId"]: "canonical-blueprint-admission-request.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "require-blueprint-geometry-proof",
        ["executionAuthorityId"]: "require-blueprint-geometry-proof.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "geometry-obligation-disposition",
        ["contract"]: {
            ["contractId"]: "blueprint-admission-obligation-disposition.v1"
        },
        ["experience"]: {
            ["statement"]: "a holding disposition, a summary whose totals do not reconcile, and a proof bound to a different digest are each unmet obligations"
        }
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "require-blueprint-geometry-proof.given",
            ["text"]: "one admission request naming a candidate and its geometry proof"
        },
        ["when"]: {
            ["semanticRef"]: "require-blueprint-geometry-proof.when",
            ["text"]: "the proof is resolved and its counted summary and disposition are inspected"
        },
        ["then"]: {
            ["semanticRef"]: "require-blueprint-geometry-proof.then",
            ["text"]: "a holding disposition, a summary whose totals do not reconcile, and a proof bound to a different digest are each unmet obligations"
        }
    },
    ["name"]: "Require a conforming geometry proof bound to this candidate digest"
};
export class RequireBlueprintGeometryProofScenario {
    static capabilityId = "admit-canonical-circuit-blueprint";
    static scenarioId = "require-blueprint-geometry-proof";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const requireBlueprintGeometryProofPortResult = await this.dependencies["require-blueprint-geometry-proof-port"].execute(input, context.rootInput);
        return requireBlueprintGeometryProofPortResult;
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
