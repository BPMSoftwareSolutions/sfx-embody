import fs from 'node:fs';
import { RequireBlueprintGeometryProofScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { RequireBlueprintGeometryProofPort as Dependency0 } from "./providers/port-0.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new RequireBlueprintGeometryProofScenario({
        "require-blueprint-geometry-proof-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "require-blueprint-geometry-proof", portId: "require-blueprint-geometry-proof-port" }))
    }, contracts, observer, clock);
}
