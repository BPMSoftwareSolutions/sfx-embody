// Generated from capabilities/resolve-equity-market-price-evidence/semantic-transformation.authority.json; sha256:365dc0905c7fc65fd8409e1713a251494a8d41ceac73cedaf44d13631b50413a
import { sfxEquals, sfxLength, sfxTruthy, sfxValueAt } from "./native-mechanics.mjs";
export class RejectNonconformingNativeMarketPriceTestimonyPort {
  execute(input, root = input) {
    return (() => {
      const currency = sfxTruthy(sfxValueAt({ input, root }["summaryQuote"], ""))
        ? sfxValueAt({ input, root }["summaryQuote"], "currency")
        : sfxValueAt({ input, root }["responseQuote"], "currency");
      const exchange = sfxTruthy(sfxValueAt({ input, root }["summaryQuote"], ""))
        ? sfxValueAt({ input, root }["summaryQuote"], "exchange")
        : sfxValueAt({ input, root }["responseQuote"], "exchange");
      const marketState = sfxTruthy(sfxValueAt({ input, root }["summaryQuote"], ""))
        ? sfxValueAt({ input, root }["summaryQuote"], "marketState")
        : sfxValueAt({ input, root }["responseQuote"], "marketState");
      const missing = sfxValueAt({ input, root }["requiredValues"], "").filter((v, vIndex) =>
        sfxTruthy(sfxEquals(sfxValueAt(v, ""), null)),
      );
      const missingCount = sfxLength(sfxValueAt(missing, ""));
      const native = sfxValueAt(input, "payload.nativeTestimony");
      const observedMarketTime = sfxTruthy(sfxValueAt({ input, root }["summaryQuote"], ""))
        ? sfxValueAt({ input, root }["summaryQuote"], "regularMarketTime")
        : sfxValueAt({ input, root }["responseQuote"], "regularMarketTime");
      const observedPrice = sfxTruthy(sfxValueAt({ input, root }["summaryQuote"], ""))
        ? sfxValueAt({ input, root }["summaryQuote"], "regularMarketPrice.raw")
        : sfxValueAt({ input, root }["responseQuote"], "regularMarketPrice");
      const requiredValues = [
        sfxValueAt({ input, root }["symbol"], ""),
        sfxValueAt(currency, ""),
        sfxValueAt(observedPrice, ""),
        sfxValueAt(observedMarketTime, ""),
        sfxValueAt(marketState, ""),
        sfxValueAt(exchange, ""),
        sfxValueAt({ input, root }["sourceAttribution"], ""),
      ];
      const responseQuote = sfxValueAt(native, "quoteResponse.result.0");
      const sourceAttribution = sfxTruthy(sfxValueAt({ input, root }["summaryQuote"], ""))
        ? sfxValueAt({ input, root }["summaryQuote"], "quoteSourceName")
        : sfxValueAt(responseQuote, "quoteSourceName");
      const summaryQuote = sfxValueAt(native, "quoteSummary.result.0.price");
      const $73796d626f6c = sfxTruthy(sfxValueAt(summaryQuote, ""))
        ? sfxValueAt(summaryQuote, "symbol")
        : sfxValueAt(responseQuote, "symbol");
      return {
        ["absentFieldCount"]: sfxValueAt(missingCount, ""),
        ["contractId"]: "native-equity-market-price-testimony-rejection.v1",
        ["disposition"]: "NATIVE_MARKET_PRICE_TESTIMONY_REJECTED",
        ["providerTestimony"]: {
          ["bindingId"]: sfxValueAt(input, "payload.providerBinding.bindingId"),
        },
        ["reasonCode"]: "REQUIRED_NATIVE_FIELDS_ABSENT",
      };
    })();
  }
}
