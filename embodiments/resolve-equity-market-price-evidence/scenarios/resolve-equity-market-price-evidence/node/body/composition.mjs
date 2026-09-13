import fs from 'node:fs';
import { ResolveEquityMarketPriceEvidenceScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { createGovernedEffectContext } from './providers/native-mechanic-primitives.mjs';
import { ResolveEquityMarketPriceEvidencePort } from "./providers/resolve-equity-market-price-evidence-port.mjs";
import { createScenario as createRetainProviderRealizationOutsideMarketPriceSemanticsScenario } from "../../../retain-provider-realization-outside-market-price-semantics/node/body/composition.mjs";
import { createScenario as createHoldUnavailableEquityMarketPriceProviderScenario } from "../../../hold-unavailable-equity-market-price-provider/node/body/composition.mjs";
import { createScenario as createRejectNonconformingNativeMarketPriceTestimonyScenario } from "../../../reject-nonconforming-native-market-price-testimony/node/body/composition.mjs";
export function createScenario({ observer, clock, effectContext }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    const effects = effectContext ?? createGovernedEffectContext();
    return new ResolveEquityMarketPriceEvidenceScenario({
        "resolve-equity-market-price-evidence-port": new ResolveEquityMarketPriceEvidencePort(),
        "retain-provider-realization-outside-market-price-semantics": createRetainProviderRealizationOutsideMarketPriceSemanticsScenario({ observer, clock, effectContext: effects }),
        "hold-unavailable-equity-market-price-provider": createHoldUnavailableEquityMarketPriceProviderScenario({ observer, clock, effectContext: effects }),
        "reject-nonconforming-native-market-price-testimony": createRejectNonconformingNativeMarketPriceTestimonyScenario({ observer, clock, effectContext: effects })
    }, contracts, observer, clock, effects);
}
