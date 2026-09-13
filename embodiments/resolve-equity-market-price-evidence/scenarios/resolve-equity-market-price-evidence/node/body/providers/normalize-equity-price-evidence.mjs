// Generated from capabilities/resolve-equity-market-price-evidence/semantic-transformation.authority.json; sha256:e5f9b5a363f919a029d59f7889c47908d3facc34a83f47f062c9dbab746af2f3
import {
  sfxEquals,
  sfxLength,
  sfxTruthy,
  sfxTryParseJson,
  sfxValueAt,
} from "./native-mechanics.mjs";
export class NormalizeEquityPriceEvidence {
  execute(input, root = input) {
    return (() => {
      const completed = sfxEquals(sfxValueAt(input, "disposition"), "completed");
      const bodyText = Buffer.from(
        String(sfxValueAt(input, "responseBodyBytes")),
        "base64",
      ).toString("utf8");
      const parsed = sfxTryParseJson(sfxValueAt(bodyText, ""));
      const native = sfxValueAt(parsed, "value");
      const summaryQuote = sfxValueAt(native, "quoteSummary.result.0.price");
      const responseQuote = sfxValueAt(native, "quoteResponse.result.0");
      const $73796d626f6c = sfxTruthy(sfxValueAt(summaryQuote, ""))
        ? sfxValueAt(summaryQuote, "symbol")
        : sfxValueAt(responseQuote, "symbol");
      const currency = sfxTruthy(sfxValueAt(summaryQuote, ""))
        ? sfxValueAt(summaryQuote, "currency")
        : sfxValueAt(responseQuote, "currency");
      const observedPrice = sfxTruthy(sfxValueAt(summaryQuote, ""))
        ? sfxValueAt(summaryQuote, "regularMarketPrice.raw")
        : sfxValueAt(responseQuote, "regularMarketPrice");
      const observedMarketTime = sfxTruthy(sfxValueAt(summaryQuote, ""))
        ? sfxValueAt(summaryQuote, "regularMarketTime")
        : sfxValueAt(responseQuote, "regularMarketTime");
      const marketState = sfxTruthy(sfxValueAt(summaryQuote, ""))
        ? sfxValueAt(summaryQuote, "marketState")
        : sfxValueAt(responseQuote, "marketState");
      const exchange = sfxTruthy(sfxValueAt(summaryQuote, ""))
        ? sfxValueAt(summaryQuote, "exchange")
        : sfxValueAt(responseQuote, "exchange");
      const sourceAttribution = sfxTruthy(sfxValueAt(summaryQuote, ""))
        ? sfxValueAt(summaryQuote, "quoteSourceName")
        : sfxValueAt(responseQuote, "quoteSourceName");
      const requiredValues = [
        sfxValueAt($73796d626f6c, ""),
        sfxValueAt(currency, ""),
        sfxValueAt(observedPrice, ""),
        sfxValueAt(observedMarketTime, ""),
        sfxValueAt(marketState, ""),
        sfxValueAt(exchange, ""),
        sfxValueAt(sourceAttribution, ""),
      ];
      const missing = sfxValueAt(requiredValues, "").filter((v, vIndex) =>
        sfxTruthy(sfxEquals(sfxValueAt(v, ""), null)),
      );
      const missingCount = sfxLength(sfxValueAt(missing, ""));
      const conforming = sfxEquals(sfxValueAt(missingCount, ""), 0);
      const nativeShape = sfxTruthy(sfxValueAt(summaryQuote, ""))
        ? "quoteSummary.result.0.price"
        : "quoteResponse.result.0";
      const bindingId = "rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED";
      const providerId = "rapidapi/davethebeast/yahoo-finance166";
      return sfxTruthy(sfxValueAt(completed, ""))
        ? sfxTruthy(sfxValueAt(conforming, ""))
          ? {
              ["contractId"]: "equity-market-price-evidence.v1",
              ["disposition"]: "EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED",
              ["payload"]: {
                ["symbol"]: sfxValueAt($73796d626f6c, ""),
                ["region"]: sfxValueAt(root, "payload.region"),
                ["currency"]: sfxValueAt(currency, ""),
                ["observedPrice"]: sfxValueAt(observedPrice, ""),
                ["observedMarketTime"]: sfxValueAt(observedMarketTime, ""),
                ["marketState"]: sfxValueAt(marketState, ""),
                ["exchange"]: sfxValueAt(exchange, ""),
                ["sourceAttribution"]: sfxValueAt(sourceAttribution, ""),
              },
              ["providerTestimony"]: {
                ["bindingId"]: sfxValueAt(bindingId, ""),
                ["providerId"]: sfxValueAt(providerId, ""),
                ["nativeShape"]: sfxValueAt(nativeShape, ""),
              },
            }
          : {
              ["contractId"]: "equity-market-price-evidence.v1",
              ["disposition"]: "NATIVE_MARKET_PRICE_TESTIMONY_REJECTED",
              ["reasonCode"]: "REQUIRED_NATIVE_FIELDS_ABSENT",
              ["absentFieldCount"]: sfxValueAt(missingCount, ""),
              ["providerTestimony"]: {
                ["bindingId"]: sfxValueAt(bindingId, ""),
                ["providerId"]: sfxValueAt(providerId, ""),
                ["nativeShape"]: sfxValueAt(nativeShape, ""),
              },
            }
        : {
            ["contractId"]: "equity-market-price-evidence.v1",
            ["disposition"]: "EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE",
            ["reasonCode"]: "PROVIDER_EXCHANGE_NOT_COMPLETED",
            ["providerTestimony"]: {
              ["bindingId"]: sfxValueAt(bindingId, ""),
              ["providerId"]: sfxValueAt(providerId, ""),
            },
          };
    })();
  }
}
