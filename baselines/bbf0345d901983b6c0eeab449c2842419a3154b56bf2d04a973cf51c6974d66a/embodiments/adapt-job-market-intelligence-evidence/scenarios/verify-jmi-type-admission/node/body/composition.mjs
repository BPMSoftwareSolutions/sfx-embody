import fs from 'node:fs';
import { VerifyJmiTypeAdmissionScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { VerifyJmiTypeAdmissionPort as Dependency0 } from "./providers/port-0.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new VerifyJmiTypeAdmissionScenario({
        "verify-jmi-type-admission-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "verify-jmi-type-admission", portId: "verify-jmi-type-admission-port" }))
    }, contracts, observer, clock);
}
