import fs from 'node:fs';
import { EmitImmutableBlueprintAuthorityScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { EmitImmutableBlueprintAuthorityPort as Dependency0 } from "./providers/port-0.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new EmitImmutableBlueprintAuthorityScenario({
        "emit-immutable-blueprint-authority-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "emit-immutable-blueprint-authority", portId: "emit-immutable-blueprint-authority-port" }))
    }, contracts, observer, clock);
}
