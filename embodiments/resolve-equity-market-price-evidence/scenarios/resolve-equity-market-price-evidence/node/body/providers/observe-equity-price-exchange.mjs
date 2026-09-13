import { observeGovernedHttpExchange } from "./sda/languages/typescript/runtimes/node/governed-http-exchange-provider.mjs";
const configuration = {
    ["credentialInjectionRules"]: [
        {
            ["headerName"]: "X-RapidAPI-Key",
            ["id"]: "rapidapi-x-rapidapi-key.v1"
        }
    ],
    ["endpointAuthorities"]: [
        {
            ["allowedRequestHeaders"]: [
                "x-rapidapi-host"
            ],
            ["allowedResponseHeaders"]: [
                "content-type",
                "retry-after"
            ],
            ["endpointAuthorityDigest"]: "sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b",
            ["methods"]: [
                "GET"
            ],
            ["urlPrefixes"]: [
                "https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?"
            ]
        }
    ]
};
export class ObserveEquityPriceExchange {
    constructor(effectContext) {
        this.effectContext = effectContext;
    }
    execute(input, root, context) {
        return observeGovernedHttpExchange(configuration, input, context, this.effectContext);
    }
}
