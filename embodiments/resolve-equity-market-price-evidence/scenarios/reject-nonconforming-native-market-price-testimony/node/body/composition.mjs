import fs from 'node:fs';
import { RejectNonconformingNativeMarketPriceTestimonyScenario } from './scenario.mjs';
import { createSchemaAdmission } from './providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs';
import { createGovernedEffectContext } from './providers/native-mechanic-primitives.mjs';
import { RejectNonconformingNativeMarketPriceTestimonyPort } from "./providers/reject-nonconforming-native-market-price-testimony-port.mjs";
export function createScenario({ observer, clock, effectContext }) {
    const contracts = createSchemaAdmission(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));
    const effects = effectContext ?? createGovernedEffectContext();
    return new RejectNonconformingNativeMarketPriceTestimonyScenario({
        "reject-nonconforming-native-market-price-testimony-port": new RejectNonconformingNativeMarketPriceTestimonyPort()
    }, contracts, observer, clock, effects);
}
