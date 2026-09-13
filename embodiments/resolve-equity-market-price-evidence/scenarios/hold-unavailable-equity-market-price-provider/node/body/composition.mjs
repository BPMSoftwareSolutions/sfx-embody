import fs from 'node:fs';
import { HoldUnavailableEquityMarketPriceProviderScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { createGovernedEffectContext } from './providers/native-mechanic-primitives.mjs';
import { HoldUnavailableEquityMarketPriceProviderPort } from "./providers/hold-unavailable-equity-market-price-provider-port.mjs";
export function createScenario({ observer, clock, effectContext }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    const effects = effectContext ?? createGovernedEffectContext();
    return new HoldUnavailableEquityMarketPriceProviderScenario({
        "hold-unavailable-equity-market-price-provider-port": new HoldUnavailableEquityMarketPriceProviderPort()
    }, contracts, observer, clock, effects);
}
