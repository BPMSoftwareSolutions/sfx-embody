import fs from 'node:fs';
import { AdmitCanonicalCircuitBlueprintScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { AdmitCanonicalCircuitBlueprintPort as Dependency0 } from "./providers/port-0.mjs";
import { createScenario as dependency1 } from "../../../require-blueprint-conformance-evidence/node/body/composition.mjs";
import { createScenario as dependency2 } from "../../../require-blueprint-geometry-proof/node/body/composition.mjs";
import { createScenario as dependency3 } from "../../../require-current-approved-review-receipt/node/body/composition.mjs";
import { createScenario as dependency4 } from "../../../emit-immutable-blueprint-authority/node/body/composition.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new AdmitCanonicalCircuitBlueprintScenario({
        "admit-canonical-circuit-blueprint-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "admit-canonical-circuit-blueprint", portId: "admit-canonical-circuit-blueprint-port" })),
        "require-blueprint-conformance-evidence": dependency1({ observer, clock, observeMechanic }),
        "require-blueprint-geometry-proof": dependency2({ observer, clock, observeMechanic }),
        "require-current-approved-review-receipt": dependency3({ observer, clock, observeMechanic }),
        "emit-immutable-blueprint-authority": dependency4({ observer, clock, observeMechanic })
    }, contracts, observer, clock);
}
