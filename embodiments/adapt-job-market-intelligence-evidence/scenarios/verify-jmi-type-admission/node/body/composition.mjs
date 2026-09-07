import fs from 'node:fs';
import { VerifyJmiTypeAdmissionScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { VerifyJmiTypeAdmissionPort } from "./providers/verify-jmi-type-admission-port.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new VerifyJmiTypeAdmissionScenario({
        "verify-jmi-type-admission-port": new VerifyJmiTypeAdmissionPort()
    }, contracts, observer, clock);
}
