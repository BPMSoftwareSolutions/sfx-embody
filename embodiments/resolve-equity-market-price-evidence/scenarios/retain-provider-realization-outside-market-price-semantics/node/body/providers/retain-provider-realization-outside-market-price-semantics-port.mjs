// Generated from capabilities/resolve-equity-market-price-evidence/semantic-transformation.authority.json; sha256:365dc0905c7fc65fd8409e1713a251494a8d41ceac73cedaf44d13631b50413a
import { sfxValueAt } from "./native-mechanics.mjs";
export class RetainProviderRealizationOutsideMarketPriceSemanticsPort {
  execute(input, root = input) {
    return {
      ["contractId"]: "equity-market-price-evidence.v1",
      ["disposition"]: sfxValueAt(input, "disposition"),
      ["payload"]: sfxValueAt(input, "payload"),
      ["providerTestimony"]: sfxValueAt(input, "providerTestimony"),
    };
  }
}
