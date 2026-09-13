// Generated from capabilities/resolve-equity-market-price-evidence/semantic-transformation.authority.json; sha256:365dc0905c7fc65fd8409e1713a251494a8d41ceac73cedaf44d13631b50413a
import { sfxEquals, sfxLength, sfxTruthy, sfxValueAt } from "./native-mechanics.mjs";
export class ResolveEquityMarketPriceEvidencePort {
  execute(input, root = input) {
    return (() => {
      const conforming = sfxEquals(sfxValueAt({ input, root }["missingCount"], ""), 0);
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
      return sfxTruthy(sfxValueAt(conforming, ""))
        ? {
            ["contractId"]: "equity-market-price-evidence.v1",
            ["disposition"]: "EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED",
            ["payload"]: {
              ["currency"]: sfxValueAt(currency, ""),
              ["exchange"]: sfxValueAt(exchange, ""),
              ["marketState"]: sfxValueAt(marketState, ""),
              ["observedMarketTime"]: sfxValueAt(observedMarketTime, ""),
              ["observedPrice"]: sfxValueAt(observedPrice, ""),
              ["region"]: sfxValueAt(input, "payload.region"),
              ["sourceAttribution"]: sfxValueAt(sourceAttribution, ""),
              ["symbol"]: sfxValueAt($73796d626f6c, ""),
            },
            ["providerTestimony"]: {
              ["bindingId"]: sfxValueAt(input, "payload.providerBinding.bindingId"),
              ["nativeShape"]: sfxTruthy(sfxValueAt(summaryQuote, ""))
                ? "quoteSummary.result.0.price"
                : "quoteResponse.result.0",
              ["providerId"]: sfxValueAt(input, "payload.providerBinding.providerId"),
            },
          }
        : {
            ["absentFieldCount"]: sfxValueAt(missingCount, ""),
            ["contractId"]: "equity-market-price-evidence.v1",
            ["disposition"]: "NATIVE_MARKET_PRICE_TESTIMONY_REJECTED",
            ["providerTestimony"]: {
              ["bindingId"]: sfxValueAt(input, "payload.providerBinding.bindingId"),
              ["nativeShape"]: sfxTruthy(sfxValueAt(summaryQuote, ""))
                ? "quoteSummary.result.0.price"
                : "quoteResponse.result.0",
              ["providerId"]: sfxValueAt(input, "payload.providerBinding.providerId"),
            },
            ["reasonCode"]: "REQUIRED_NATIVE_FIELDS_ABSENT",
          };
    })();
  }
}
