# Rate-limit evidence: the run store and the 30-day route selection

Decision record, 2026-09-16. Scope: [declare-provider-fallback-validation.md](declare-provider-fallback-validation.md)
§4, finding F6 in [architecture-priorities.md](architecture-priorities.md), and
the installed fallback route (`add-equity-price-fallback-route.sql`, estate
`9230b83`). One question: **where do provider evidence runs live, and what
reads them for 30-day routing?**

## Decision (short)

1. **The run is a declared capability, not a script.** A probe capability per
   provider — ports, operations, classification transformation, outcome
   contract — authored as rows and invocable through the unchanged CLI. The
   check is authority; nothing executes outside the kernel.
2. **Retention is the estate's evidence path, not a new schema.** Each run's
   `--json` receipt is retained under `evidence/<capability>/` like every other
   evidence bundle. No model table, no semantic kind, no write on the
   invocation path (which stays read-only).
3. **The 30-day selection is declared data.** A transformation consumes
   `{nowEpochSeconds, receipts[]}` supplied by the caller and emits
   `{orderedProviderIds, reason}`. The window (2 592 000 s) and the rule are
   literals in the expression.
4. **Cadence is boot-side scheduling** of probe → selection → invocation. It is
   a sequence of ordinary invocations, not executable logic in the invocation
   path.
5. **Receipt rows in the model are deferred with a trigger**: a new semantic
   kind or table is an SDA schema decision, and the model holds declarations,
   not observations of the world. Revisit when a consumer needs receipts it
   cannot receive as input (e.g., a second estate model reading the same store).

## Why the probe is not a script (and not a harness)

The skill validation established the rule mechanically: the guarded request
performs no transport (`exchangeCount: 0`), the live request's status is real
evidence (`httpStatus: 429`), and the 429 is exactly what the rate-limit record
needs. Declaring the probe makes those checks repeatable, classified, and
auditable; a script would put provider behavior back in boot code, which the
display decision and the transistor model both forbid. The probe's
classification transformation sees the **raw exchange evidence** (its input
token), including `httpStatus`, so it works before the kernel's bounded
testimony carries the field (SDA request filed:
[bounded provider evidence](sda-change-request-bounded-provider-evidence-http-status.md)).

## The receipt

A receipt is one probe run, retained as JSON:

```json
{ "capabilityId": "probe-equity-price-provider",
  "providerId": "rapidapi/yahoo-finance166",
  "observedAt": "2026-09-16T23:14:05.000Z",
  "availability": "PROVIDER_RATE_LIMITED",
  "httpStatus": 429,
  "disposition": "retained-non-success",
  "reachedStage": "response-complete",
  "exchangeCount": 1 }
```

`observedAt` is the run's own stamp; `httpStatus` comes from the raw evidence at
classification time; the streamed receipt carries the same bounded
`providerEvidence` once the SDA bound lands.

## Units

| # | Unit | Shape | Acceptance |
|---|---|---|---|
| U1 | Probe capability `probe-equity-price-provider` | Input `{providerId}`; five operations: build-binding-request, bind-credential, build-exchange-request, exchange, classify. The request builders select endpoint authority digest and URL prefix by `providerId`; classification maps `completed` → `PROVIDER_AVAILABLE` (success), `httpStatus 429` → `PROVIDER_RATE_LIMITED` (failure), other `retained-non-success` → `PROVIDER_ERROR` (failure), transport failure → `PROVIDER_UNREACHABLE` (failure) | Live: primary → `PROVIDER_RATE_LIMITED` (429); real-time1 → `PROVIDER_AVAILABLE`; both through `sfx capability invoke` |
| U2 | Order-selection capability (declared transformation) | Input `{nowEpochSeconds, receipts[]}`; output `{orderedProviderIds, reason}`; a provider whose latest receipt is `PROVIDER_RATE_LIMITED` within 30 days is placed after providers without one | Preflight: a fresh 429 receipt orders real-time1 first; a 31-day-old 429 receipt orders primary first; no receipts orders primary first |
| U3 | Equity wiring | Scenario input gains optional `providerRouteOrder`; the primary and fallback request builders guard on it (a route excluded by the order emits a guarded request: `rejected-endpoint`, no transport, `exchangeCount: 0`); selection unchanged | With `[real-time1, 166]`: primary performs no transport, run resolves via real-time1. With `[166, real-time1]`: primary attempted (429), fallback answers. Both classified as today |
| U4 | Cadence | A scheduled invocation chain (probes → U2 → equity invoke with the order); no new executable in the invocation path | One cycle observed: probe records the 429, U2 deprioritizes 166, equity resolves through real-time1 with the primary un-attempted |

U1 needs the full capability shell (contracts, scenario, authority, ports) and
is the largest unit; the JSON authoring surface currently covers declared reads
only, so U1 is authored like the fallback route (one migration, direct mint) or
the surface is extended first — an authoring-surface decision, not a runtime
one.

## Alternatives considered

- **Receipt rows published into the model by a migration per run** (mirroring
  `publish-projected-bodies.mjs`). Rejected for now: it needs a semantic kind
  the model does not have (SDA schema), it turns every run into an install,
  and the first consumer (the selection) can receive receipts as input. Kept as
  the trigger above.
- **The invocation path writing receipts.** Rejected outright: the path is
  read-only; `bodyStorage: NOT_REQUESTED` is the boundary.
- **A boot-side reader computing the order in `src/` or the CLI.** Rejected:
  ordering by evidence is meaning, so it must be a declared transformation; the
  caller supplies only facts (receipts, now).

## Evidence

- Fallback install receipt (2026-09-16): primary `retained-non-success`
  `exchangeCount: 1`; fallback `completed`; `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`
  attributed to `rapidapi/yahoo-finance-real-time1` —
  [declare-provider-fallback-validation.md](declare-provider-fallback-validation.md) §5.
- Guarded-request receipt: `rejected-endpoint`, `exchangeCount: 0` — the
  un-attempted route performs no transport (same §5).
- Estate allowlists now accept `httpStatus` (`src/observation-filter.mjs`,
  `src/execution-drilldown.mjs`); suite 49/52 (3 DB-gated skips), including the
  bounded-evidence tests.
