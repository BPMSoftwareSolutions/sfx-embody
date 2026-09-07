import fs from 'node:fs';
import { EmitImmutableBlueprintAuthorityScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { EmitImmutableBlueprintAuthorityPort } from "./providers/emit-immutable-blueprint-authority-port.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new EmitImmutableBlueprintAuthorityScenario({
        "emit-immutable-blueprint-authority-port": new EmitImmutableBlueprintAuthorityPort()
    }, contracts, observer, clock);
}
