import fs from 'node:fs';
import { BindJmiAdapterReceiptScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { BindJmiAdapterReceiptPort } from "./providers/bind-jmi-adapter-receipt-port.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new BindJmiAdapterReceiptScenario({
        "bind-jmi-adapter-receipt-port": new BindJmiAdapterReceiptPort()
    }, contracts, observer, clock);
}
