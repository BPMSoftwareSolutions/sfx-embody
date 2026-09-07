import fs from 'node:fs';
import { RequireCurrentApprovedReviewReceiptScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { RequireCurrentApprovedReviewReceiptPort as Dependency0 } from "./providers/port-0.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new RequireCurrentApprovedReviewReceiptScenario({
        "require-current-approved-review-receipt-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "require-current-approved-review-receipt", portId: "require-current-approved-review-receipt-port" }))
    }, contracts, observer, clock);
}
