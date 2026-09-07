import fs from 'node:fs';
import { VerifyJmiRecordBindingScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { VerifyJmiRecordBindingPort as Dependency0 } from "./providers/port-0.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new VerifyJmiRecordBindingScenario({
        "verify-jmi-record-binding-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "verify-jmi-record-binding", portId: "verify-jmi-record-binding-port" }))
    }, contracts, observer, clock);
}
