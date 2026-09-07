import fs from 'node:fs';
import { AdaptJobMarketIntelligenceEvidenceScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { AdaptJobMarketIntelligenceEvidencePort } from "./providers/adapt-job-market-intelligence-evidence-port.mjs";
import { createScenario as createVerifyJmiRecordBindingScenario } from "../../../verify-jmi-record-binding/node/body/composition.mjs";
import { createScenario as createVerifyJmiTypeAdmissionScenario } from "../../../verify-jmi-type-admission/node/body/composition.mjs";
import { createScenario as createBindJmiAdapterReceiptScenario } from "../../../bind-jmi-adapter-receipt/node/body/composition.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new AdaptJobMarketIntelligenceEvidenceScenario({
        "adapt-job-market-intelligence-evidence-port": new AdaptJobMarketIntelligenceEvidencePort(),
        "verify-jmi-record-binding": createVerifyJmiRecordBindingScenario({ observer, clock }),
        "verify-jmi-type-admission": createVerifyJmiTypeAdmissionScenario({ observer, clock }),
        "bind-jmi-adapter-receipt": createBindJmiAdapterReceiptScenario({ observer, clock })
    }, contracts, observer, clock);
}
