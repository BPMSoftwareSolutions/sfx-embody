import fs from 'node:fs';
import { RequireBlueprintConformanceEvidenceScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { RequireBlueprintConformanceEvidencePort } from "./providers/require-blueprint-conformance-evidence-port.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new RequireBlueprintConformanceEvidenceScenario({
        "require-blueprint-conformance-evidence-port": new RequireBlueprintConformanceEvidencePort()
    }, contracts, observer, clock);
}
