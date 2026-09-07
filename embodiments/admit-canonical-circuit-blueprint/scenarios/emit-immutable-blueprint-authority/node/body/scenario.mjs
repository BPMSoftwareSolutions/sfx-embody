// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "emit-immutable-blueprint-authority",
    ["input"]: {
        ["inputId"]: "canonical-blueprint-admission-request",
        ["contract"]: {
            ["contractId"]: "canonical-blueprint-admission-request.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "emit-immutable-blueprint-authority",
        ["executionAuthorityId"]: "emit-immutable-blueprint-authority.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "admitted-canonical-circuit-blueprint",
        ["contract"]: {
            ["contractId"]: "admitted-canonical-circuit-blueprint.v1"
        },
        ["experience"]: {
            ["statement"]: "immutable blueprint authority is emitted with a stable digest, and its emission claims no fabrication, projection, or capability admission of its own"
        }
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "emit-immutable-blueprint-authority.given",
            ["text"]: "every admission obligation resolved as met for one candidate"
        },
        ["when"]: {
            ["semanticRef"]: "emit-immutable-blueprint-authority.when",
            ["text"]: "the candidate disposition is advanced to ADMITTED and its authority digest is bound"
        },
        ["then"]: {
            ["semanticRef"]: "emit-immutable-blueprint-authority.then",
            ["text"]: "immutable blueprint authority is emitted with a stable digest, and its emission claims no fabrication, projection, or capability admission of its own"
        }
    },
    ["name"]: "Emit the fixed map every later authoring request must resolve from"
};
export class EmitImmutableBlueprintAuthorityScenario {
    static capabilityId = "admit-canonical-circuit-blueprint";
    static scenarioId = "emit-immutable-blueprint-authority";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const emitImmutableBlueprintAuthorityPortResult = await this.dependencies["emit-immutable-blueprint-authority-port"].execute(input, context.rootInput);
        return emitImmutableBlueprintAuthorityPortResult;
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
