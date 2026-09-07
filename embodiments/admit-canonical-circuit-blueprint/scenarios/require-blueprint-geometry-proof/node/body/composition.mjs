import fs from 'node:fs';
import { RequireBlueprintGeometryProofScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { RequireBlueprintGeometryProofPort } from "./providers/require-blueprint-geometry-proof-port.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new RequireBlueprintGeometryProofScenario({
        "require-blueprint-geometry-proof-port": new RequireBlueprintGeometryProofPort()
    }, contracts, observer, clock);
}
