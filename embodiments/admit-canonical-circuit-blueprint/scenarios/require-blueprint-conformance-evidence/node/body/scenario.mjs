// Generated from database-retained Scenario and execution authority.
import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';
import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';
const declaration = {
    ["scenarioId"]: "require-blueprint-conformance-evidence",
    ["input"]: {
        ["inputId"]: "canonical-blueprint-admission-request",
        ["contract"]: {
            ["contractId"]: "canonical-blueprint-admission-request.v1"
        }
    },
    ["event"]: {
        ["eventId"]: "require-blueprint-conformance-evidence",
        ["executionAuthorityId"]: "require-blueprint-conformance-evidence.v1"
    },
    ["outcome"]: {
        ["outcomeId"]: "conformance-obligation-disposition",
        ["contract"]: {
            ["contractId"]: "blueprint-admission-obligation-disposition.v1"
        },
        ["experience"]: {
            ["statement"]: "evidence carrying findings, evidence bound to a different digest, and absent evidence are each unmet obligations"
        }
    },
    ["gherkin"]: {
        ["given"]: {
            ["semanticRef"]: "require-blueprint-conformance-evidence.given",
            ["text"]: "one admission request naming a candidate and its conformance evidence"
        },
        ["when"]: {
            ["semanticRef"]: "require-blueprint-conformance-evidence.when",
            ["text"]: "the evidence is resolved and its bound digest is compared with the candidate"
        },
        ["then"]: {
            ["semanticRef"]: "require-blueprint-conformance-evidence.then",
            ["text"]: "evidence carrying findings, evidence bound to a different digest, and absent evidence are each unmet obligations"
        }
    },
    ["name"]: "Require conformance evidence bound to this candidate digest"
};
export class RequireBlueprintConformanceEvidenceScenario {
    static capabilityId = "admit-canonical-circuit-blueprint";
    static scenarioId = "require-blueprint-conformance-evidence";
    constructor(dependencies, contracts, observer, clock) {
        this.dependencies = dependencies;
        this.contracts = contracts;
        this.observer = observer;
        this.clock = clock;
    }
    async perform(input, context) {
        const root = input;
        const requireBlueprintConformanceEvidencePortResult = await this.dependencies["require-blueprint-conformance-evidence-port"].execute(input, root);
        return requireBlueprintConformanceEvidencePortResult;
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
