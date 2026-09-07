import fs from 'node:fs';
import { AdmitCanonicalCircuitBlueprintScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { AdmitCanonicalCircuitBlueprintPort } from "./providers/admit-canonical-circuit-blueprint-port.mjs";
import { createScenario as createRequireBlueprintConformanceEvidenceScenario } from "../../../require-blueprint-conformance-evidence/node/body/composition.mjs";
import { createScenario as createRequireBlueprintGeometryProofScenario } from "../../../require-blueprint-geometry-proof/node/body/composition.mjs";
import { createScenario as createRequireCurrentApprovedReviewReceiptScenario } from "../../../require-current-approved-review-receipt/node/body/composition.mjs";
import { createScenario as createEmitImmutableBlueprintAuthorityScenario } from "../../../emit-immutable-blueprint-authority/node/body/composition.mjs";
export function createScenario({ observer, clock }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    return new AdmitCanonicalCircuitBlueprintScenario({
        "admit-canonical-circuit-blueprint-port": new AdmitCanonicalCircuitBlueprintPort(),
        "require-blueprint-conformance-evidence": createRequireBlueprintConformanceEvidenceScenario({ observer, clock }),
        "require-blueprint-geometry-proof": createRequireBlueprintGeometryProofScenario({ observer, clock }),
        "require-current-approved-review-receipt": createRequireCurrentApprovedReviewReceiptScenario({ observer, clock }),
        "emit-immutable-blueprint-authority": createEmitImmutableBlueprintAuthorityScenario({ observer, clock })
    }, contracts, observer, clock);
}
