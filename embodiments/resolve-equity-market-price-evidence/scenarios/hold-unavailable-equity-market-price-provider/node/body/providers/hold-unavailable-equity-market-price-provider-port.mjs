// Generated from capabilities/resolve-equity-market-price-evidence/semantic-transformation.authority.json; sha256:365dc0905c7fc65fd8409e1713a251494a8d41ceac73cedaf44d13631b50413a
import { sfxValueAt } from "./native-mechanics.mjs";
export class HoldUnavailableEquityMarketPriceProviderPort {
  execute(input, root = input) {
    return {
      ["attemptedBindings"]: sfxValueAt(input, "payload.attemptedBindings").map((b, bIndex) => ({
        ["bindingId"]: sfxValueAt(b, "bindingId"),
        ["providerId"]: sfxValueAt(b, "providerId"),
      })),
      ["contractId"]: "equity-market-price-provider-unavailable.v1",
      ["disposition"]: "EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE",
      ["reasonCode"]: "NO_ADMITTED_ROUTE_COMPLETED",
      ["region"]: sfxValueAt(input, "payload.region"),
      ["symbol"]: sfxValueAt(input, "payload.symbol"),
    };
  }
}
