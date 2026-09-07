import fs from 'node:fs';
import { RequireCurrentApprovedReviewReceiptScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { RequireCurrentApprovedReviewReceiptPort } from "./providers/require-current-approved-review-receipt-port.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new RequireCurrentApprovedReviewReceiptScenario({
        "require-current-approved-review-receipt-port": new RequireCurrentApprovedReviewReceiptPort()
    }, contracts, observer, clock);
}
