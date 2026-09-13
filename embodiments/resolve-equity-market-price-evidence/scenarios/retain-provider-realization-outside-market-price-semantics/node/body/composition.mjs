import fs from 'node:fs';
import { RetainProviderRealizationOutsideMarketPriceSemanticsScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { createGovernedEffectContext } from './providers/native-mechanic-primitives.mjs';
import { RetainProviderRealizationOutsideMarketPriceSemanticsPort } from "./providers/retain-provider-realization-outside-market-price-semantics-port.mjs";
export function createScenario({ observer, clock, effectContext }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    const effects = effectContext ?? createGovernedEffectContext();
    return new RetainProviderRealizationOutsideMarketPriceSemanticsScenario({
        "retain-provider-realization-outside-market-price-semantics-port": new RetainProviderRealizationOutsideMarketPriceSemanticsPort()
    }, contracts, observer, clock, effects);
}
