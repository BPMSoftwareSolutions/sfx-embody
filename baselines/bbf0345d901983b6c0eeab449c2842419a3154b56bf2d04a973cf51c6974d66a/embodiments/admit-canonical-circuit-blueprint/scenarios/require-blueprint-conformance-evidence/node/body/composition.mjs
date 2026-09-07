import fs from 'node:fs';
import { RequireBlueprintConformanceEvidenceScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { RequireBlueprintConformanceEvidencePort as Dependency0 } from "./providers/port-0.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new RequireBlueprintConformanceEvidenceScenario({
        "require-blueprint-conformance-evidence-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "require-blueprint-conformance-evidence", portId: "require-blueprint-conformance-evidence-port" }))
    }, contracts, observer, clock);
}
