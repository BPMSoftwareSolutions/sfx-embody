import fs from 'node:fs';
import { ResolveSidefxEligibleProvidersScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { ResolveSidefxEligibleProvidersPort as Dependency0 } from "./providers/port-0.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new ResolveSidefxEligibleProvidersScenario({
        "resolve-sidefx-eligible-providers-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "resolve-sidefx-eligible-providers", portId: "resolve-sidefx-eligible-providers-port" }))
    }, contracts, observer, clock);
}
