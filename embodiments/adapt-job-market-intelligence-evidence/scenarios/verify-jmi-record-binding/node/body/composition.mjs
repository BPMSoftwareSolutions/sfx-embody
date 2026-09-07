import fs from 'node:fs';
import { VerifyJmiRecordBindingScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { VerifyJmiRecordBindingPort } from "./providers/verify-jmi-record-binding-port.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new VerifyJmiRecordBindingScenario({
        "verify-jmi-record-binding-port": new VerifyJmiRecordBindingPort()
    }, contracts, observer, clock);
}
