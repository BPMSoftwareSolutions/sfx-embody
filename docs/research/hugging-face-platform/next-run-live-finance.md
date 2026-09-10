# Next run: live stock-price capability in the Hugging Face Space

**Completed 9 September 2026 (local time):** all three original interactions and live RapidAPI stock-price retrieval are deployed and verified in the private Space. [Deployed identities and hosted evidence](../../../../sfx-platform/docs/live-finance-deployment.md) records the result. The original acceptance scope below is retained for traceability.

User direction: deploy the working Lab to the private Hugging Face Space `BPMSoftwareSolutions/SideFX` and carry it through an actual finance capability and external API call. Keep all three existing interactions working in that Space, and extend the shared experience to the RapidAPI stock-price path. **Hugging Face deployment is mandatory. Local execution is a development check and never the completion point.**

## Required result

From [the deployed Hugging Face Space](https://huggingface.co/spaces/BPMSoftwareSolutions/SideFX), select the finance capability, enter a stock symbol and an allowed region, and explicitly Run. The remotely hosted SideFX service must invoke database-selected capability authority and the declared external provider boundary, perform a real RapidAPI exchange, and return canonical price evidence to the Space. Display symbol, price, currency, market timestamp, retrieval time and provider attribution. Distinguish live retrieval from any separately labelled fixture or replay.

Completion requires the deployed Space-to-service-to-provider path, actual HTTP and native execution evidence, and verified failure behavior. Another greeting run, provider eligibility fixture, supplied stock-price payload, local web page or locally built container alone does not meet this target. Do not stop at a plan, local implementation or renderer-only deployment when the required execution work can proceed.

## Verified starting point

- `sfx-platform` implements the local Lab, three interactions, compiled ownership profiles, canonical input construction, pre-execution authority binding and generic command transport. Start it with `npm run dev:lab`.
- The existing profiles already execute database-selected capabilities, but the provider demonstration is a pure fixture calculation. None of those three interactions fetches a live stock price.
- The registered finance scaffold is `resolve-equity-market-price-evidence`, under `scaffolds/resolve-equity-market-price-evidence/`. Its corrected registration spec is `C:/lab/sidefx-database/config/register/resolve-equity-market-price-evidence.json`; the prior successful registration published model 32. Recheck the current selected estate before changing it.
- Its current input contract requires `payload.nativeTestimony`, `payload.region` and `payload.providerBinding`. Its root port binds `sda-authority-transformation-port.v1` to `transform-resolve-equity-market-price-evidence`. It normalizes supplied provider testimony; that input contract and port do not by themselves fetch a quote.
- `docs/scaffold-invocation-rapidapi.md` contains historical scaffold/registration investigations and earlier provider observations. Some sections describe superseded scaffold states. Use the current authored files, selected database authority and fresh execution evidence as the baseline.

## Implementation work

1. Inspect the selected finance authority, current provider binding, credential-reference configuration and existing governed HTTP capabilities. Reuse the configured provider/endpoint and existing credential reference; never print the key or place it in a publication or browser bundle. Verify the provider's current request/response requirements before wiring it.
2. Establish the declared execution path that accepts a symbol/region, binds the provider and credential on the SideFX server, observes the HTTP exchange, and invokes the existing finance normalization capability. Preserve its current testimony-normalization contract. If an outer composition or missing provider obligation must be authored, implement and register that authority through the existing pipeline. A standalone fetch outside the represented capability path is not sufficient evidence of capability execution.
3. Extend the shared compiler/ownership and outcome-view families as needed. Symbol/region are user-supplied only where declared; provider selection, credentials, response testimony and assurance are server-owned. Add the finance publication and permitted effects as data, without capability-name branches in the renderer or a vendor-specific CLI command.
4. Reproduce the selected finance invocation through the actual installed `sfx` command and retain exact command, input, exit status, native output and authority pins. Prove the live provider path through the service/API and browser as well. A successful normalization of a canned payload remains only a fixture check.
5. Display canonical price, currency, market and retrieval timestamps, attribution and the returned disposition. Preserve invalid-symbol, unavailable-provider, invalid/missing credential, throttling, malformed-response and uncertain-timeout states. Never manufacture a price on failure or silently retry an uncertain call.
6. Package and deploy the authenticated SideFX service to a remotely reachable HTTPS host, reusing the existing platform infrastructure where appropriate. Keep SQL and provider credentials on the SideFX execution side. The result must work independently of the author's local development servers.
7. Deploy the shared renderer and server adapter into the existing private Docker Space `BPMSoftwareSolutions/SideFX`. Configure its scoped service access, complete the Space build/startup, and verify the application through the Hugging Face URL. A placeholder page or a link out to localhost is not delivery.
8. Verify all three existing interactions and the live finance path from the Space itself. Retain source changes, deployed revision identities, compact verification and setup instructions. If an actual subscription, credential or access limitation blocks deployment or the live call, identify that specific unmet requirement and finish all independent implementation; do not report the target as complete or substitute local execution.

## Acceptance evidence

- A running application at `https://huggingface.co/spaces/BPMSoftwareSolutions/SideFX`, with its successful build/startup and deployed revision recorded.
- One fresh successful quote requested from that Space through the remotely hosted SideFX service and declared provider execution path, with no dependency on local development servers.
- Matching symbol/region and attributable canonical output, including price, currency and timestamps.
- Native scenario identity and authority digests, plus sanitized HTTP request/response metadata and response digest. No secrets in evidence.
- Server rejection of forged provider testimony, binding/credential overrides and unauthorized subjects.
- Verified provider failure presentation and no invented successful outcome.
- Successful runs of all three existing profiles in the Hugging Face Space, plus regression coverage for the shared renderer extensions.

Prices and market timestamps can change between calls. Compare stable identity/provenance fields and verify each price against its own retained response; do not require two live calls to return identical prices.

The immediate target is the complete live finance path deployed in Hugging Face. Hosting the execution service separately from the Space preserves the architecture; it does not defer either deployment. Until the live quote works from the Space, this task remains incomplete.
