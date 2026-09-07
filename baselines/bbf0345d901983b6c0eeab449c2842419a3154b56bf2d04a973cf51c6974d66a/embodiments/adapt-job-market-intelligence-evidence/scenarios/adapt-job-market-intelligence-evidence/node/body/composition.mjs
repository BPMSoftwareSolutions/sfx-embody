import fs from 'node:fs';
import { AdaptJobMarketIntelligenceEvidenceScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { AdaptJobMarketIntelligenceEvidencePort as Dependency0 } from "./providers/port-0.mjs";
import { createScenario as dependency1 } from "../../../verify-jmi-record-binding/node/body/composition.mjs";
import { createScenario as dependency2 } from "../../../verify-jmi-type-admission/node/body/composition.mjs";
import { createScenario as dependency3 } from "../../../bind-jmi-adapter-receipt/node/body/composition.mjs";
export function createScenario({ observer, clock, observeMechanic }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new AdaptJobMarketIntelligenceEvidenceScenario({
        "adapt-job-market-intelligence-evidence-port": new Dependency0(undefined, observation => observeMechanic?.({ ...observation, scenarioId: "adapt-job-market-intelligence-evidence", portId: "adapt-job-market-intelligence-evidence-port" })),
        "verify-jmi-record-binding": dependency1({ observer, clock, observeMechanic }),
        "verify-jmi-type-admission": dependency2({ observer, clock, observeMechanic }),
        "bind-jmi-adapter-receipt": dependency3({ observer, clock, observeMechanic })
    }, contracts, observer, clock);
}
