import fs from 'node:fs';
import { ResolveSidefxEligibleProvidersScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { ResolveSidefxEligibleProvidersPort } from "./providers/resolve-sidefx-eligible-providers-port.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new ResolveSidefxEligibleProvidersScenario({
        "resolve-sidefx-eligible-providers-port": new ResolveSidefxEligibleProvidersPort()
    }, contracts, observer, clock);
}
