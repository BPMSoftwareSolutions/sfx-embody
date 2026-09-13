// Generated from capabilities/resolve-equity-market-price-evidence/semantic-transformation.authority.json; sha256:e5f9b5a363f919a029d59f7889c47908d3facc34a83f47f062c9dbab746af2f3
import { sfxFormat, sfxValueAt } from "./native-mechanics.mjs";
export class BuildEquityPriceExchangeRequest {
  execute(input, root = input) {
    return {
      ["allowedResponseHeaders"]: ["content-type", "retry-after"],
      ["cancellationScopeReference"]: "equity-market-price-evidence.v1",
      ["credentialInjectionRuleId"]: sfxValueAt(input, "credentialInjectionRuleId"),
      ["endpointAuthorityDigest"]:
        "sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b",
      ["exchangeKind"]: "live-provider-input",
      ["invocationIdentity"]: "equity-market-price-evidence.v1",
      ["lineageId"]: "equity-market-price-evidence.v1",
      ["maxResponseBytes"]: 262144,
      ["method"]: "GET",
      ["opaqueCredentialBinding"]: {
        ["bindingId"]: sfxValueAt(input, "opaqueBindingId"),
        ["credentialInjectionRuleId"]: sfxValueAt(input, "credentialInjectionRuleId"),
      },
      ["redirectPolicy"]: "manual",
      ["requestBodyText"]: "",
      ["requestUrl"]: sfxFormat(
        "https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}",
        {
          ["region"]: sfxValueAt(root, "payload.region"),
          ["symbol"]: sfxValueAt(root, "payload.symbol"),
        },
      ),
      ["safeHeaders"]: { ["X-RapidAPI-Host"]: "yahoo-finance166.p.rapidapi.com" },
      ["timeoutMilliseconds"]: 12000,
    };
  }
}
