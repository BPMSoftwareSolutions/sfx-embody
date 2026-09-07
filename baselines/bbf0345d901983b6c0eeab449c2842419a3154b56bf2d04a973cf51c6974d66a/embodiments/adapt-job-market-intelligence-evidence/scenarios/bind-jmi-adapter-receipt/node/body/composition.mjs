import fs from 'node:fs';
import { BindJmiAdapterReceiptScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { BindJmiAdapterReceiptPort as Dependency0 } from "./providers/port-0.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new BindJmiAdapterReceiptScenario({
        "bind-jmi-adapter-receipt-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "bind-jmi-adapter-receipt", portId: "bind-jmi-adapter-receipt-port" }))
    }, contracts, observer, clock);
}
