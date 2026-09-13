import { bindExternalCredentialReference } from "./sda/languages/typescript/runtimes/node/external-credential-reference-binding-provider.mjs";
const configuration = {
    ["credentialAuthorities"]: [
        {
            ["effectScopes"]: [
                "ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"
            ],
            ["endpointAuthorityDigests"]: [
                "sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"
            ],
            ["injectionRule"]: {
                ["headerName"]: "X-RapidAPI-Key",
                ["id"]: "rapidapi-x-rapidapi-key.v1"
            },
            ["lifetimeMilliseconds"]: 15000,
            ["referenceName"]: "RAPID_API_KEY",
            ["requestingCapabilityIds"]: [
                "resolve-equity-market-price-evidence"
            ],
            ["source"]: "environment"
        }
    ]
};
export class BindEquityPriceProviderCredential {
    constructor(effectContext) {
        this.effectContext = effectContext;
    }
    execute(input, root, context) {
        return bindExternalCredentialReference(configuration, input, context, this.effectContext);
    }
}
