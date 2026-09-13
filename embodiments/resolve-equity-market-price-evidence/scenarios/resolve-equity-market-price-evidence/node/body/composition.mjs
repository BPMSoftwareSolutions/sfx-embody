import fs from 'node:fs';
import { ResolveEquityMarketPriceEvidenceScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { createGovernedEffectContext } from './providers/native-mechanic-primitives.mjs';
import { BuildEquityPriceBindingRequest } from "./providers/build-equity-price-binding-request.mjs";
import { BindEquityPriceProviderCredential } from "./providers/bind-equity-price-provider-credential.mjs";
import { BuildEquityPriceExchangeRequest } from "./providers/build-equity-price-exchange-request.mjs";
import { ObserveEquityPriceExchange } from "./providers/observe-equity-price-exchange.mjs";
import { NormalizeEquityPriceEvidence } from "./providers/normalize-equity-price-evidence.mjs";
export function createScenario({ observer, clock, effectContext }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    const effects = effectContext ?? createGovernedEffectContext();
    return new ResolveEquityMarketPriceEvidenceScenario({
        "build-equity-price-binding-request": new BuildEquityPriceBindingRequest(),
        "bind-equity-price-provider-credential": new BindEquityPriceProviderCredential(effects),
        "build-equity-price-exchange-request": new BuildEquityPriceExchangeRequest(),
        "observe-equity-price-exchange": new ObserveEquityPriceExchange(effects),
        "normalize-equity-price-evidence": new NormalizeEquityPriceEvidence()
    }, contracts, observer, clock, effects);
}
