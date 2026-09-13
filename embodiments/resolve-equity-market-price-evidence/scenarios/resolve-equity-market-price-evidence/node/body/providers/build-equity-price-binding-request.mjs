// Generated from capabilities/resolve-equity-market-price-evidence/semantic-transformation.authority.json; sha256:e5f9b5a363f919a029d59f7889c47908d3facc34a83f47f062c9dbab746af2f3
export class BuildEquityPriceBindingRequest {
  execute(input, root = input) {
    return {
      ["credentialReference"]: "RAPID_API_KEY",
      ["effectLineage"]: [],
      ["effectScope"]: "ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY",
      ["endpointAuthorityDigest"]:
        "sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b",
      ["invocationIdentity"]: "equity-market-price-evidence.v1",
      ["requestingCapabilityId"]: "resolve-equity-market-price-evidence",
    };
  }
}
