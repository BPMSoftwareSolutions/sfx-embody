# Provider-add flywheel

**Status.** Authored 2026-09-19. This records the finance15 fallback install and
the one-command provider flywheel. The estate's change lifecycle and dependency
law are unchanged: the command drives the declared change and the standard
lifecycle; installation is still one migration per change.

## The finance15 probe and the contract gap

Probed live on 2026-09-19 with the vault credential `RAPID_API_KEY` (raw bodies
under `evidence/provider-add-20260919/`; instrumentation only). Two operations
on the declared `rapidapi/yahoo-finance15` host:

| Operation | Response | Canonical fields |
|---|---|---|
| `GET /api/v1/markets/quote?ticker=AVGO&type=STOCKS` | `body.primaryData` | `lastSalePrice: "$357.61"` (formatted string), `lastTradeTimestamp: "Sep 17, 2026"` (human date), `currency: null` |
| `GET /api/v1/markets/stock/quotes?ticker=AVGO` | `body[0]` | `currency: "USD"`, `regularMarketPrice: 357.61` (number), `regularMarketTime: 1789761602` (epoch seconds), `marketState`, `exchange`, `quoteSourceName` |

The quote shape's gap is genuine: no numeric price, no machine timestamp, and no
currency at any JSON path (`primaryData.currency` is null for every ticker and
`type` probed; `secondaryData` is null). No parse mechanic can invent the
currency, and a `$`-symbol inference would be fabrication.

**Decision.** The declared mapping contract is extended with the currency source
that exists: the same provider's `markets/stock/quotes` operation. The finance15
route maps `body.0` and fabricates nothing. (The quote shape remains a recorded
held case: `sfx provider add` on `examples/provider-binding-change.finance15.json`
returns `PROVIDER_CHANGE_HELD` with the three exact findings and installs
nothing.)

## Declared rows and mechanics

- `sql/migrations/declare-provider-binding-change-install.sql` declares
  `model.install_provider_binding_change`: the install mechanic for one
  `provider-binding-change.v1` document. It appends the route's ports and
  operations to the capability's current execution authority, mints the endpoint
  authority content address from the declared endpoint record, registers the
  route transformations, and re-declares the provider-slot blueprint for the new
  operation count. The normalization expression is assembled from the document's
  declared `mapping`; nothing is fabricated. A route already present is reported
  `already_installed`.
- `sql/migrations/install-finance15-equity-fallback.sql` extends the outcome
  contract's `nativeShape` enum with `body.0`/`body.primaryData` and installs the
  route: primary `yahoo-finance166` → fallback `yahoo-finance-real-time1` →
  fallback `yahoo-finance15` (15 operations). The chain is data; the same
  mechanic accepts the next route.
- `sql/migrations/fix-provider-mapping-array-path-read.sql` re-declares the
  provider authoring read so the observed-sample validation can address array
  elements (`body.0.currency` is translated to `body[0].currency`); without it
  the array shape could not be authored.

## The command

`sfx provider add --input <spec.json|@file|->` (installer class, beside
`install`/`verify`/`switch`/`provision`/`accept`):

| Stage | What it does | Reported |
|---|---|---|
| author | declared `provider set` read validates the change against the outcome contract and the observed sample and mints the endpoint digest | disposition + findings |
| render | renders the install migration (it calls `model.install_provider_binding_change`; no hand-written row SQL) | file + digest |
| dry-run | runs the migration uncommitted | `ROLLED_BACK` |
| preflight | `invoke-from-transaction.mjs` invokes the target capability from the uncommitted change | disposition + provider testimony |
| install | commits the same migration | `COMMITTED` |
| verify | invokes the installed capability live | outcome + provider testimony |

A `PROVIDER_CHANGE_HELD` authoring result returns after the author stage with
`installed: false` and writes no migration. Adding a provider is one JSON
document and one command; no provider-specific code path exists.

## Live outcome

`sfx capability observe resolve-equity-market-price-evidence --display --input AVGO`
(installed kernel, 2026-09-19): `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`,
AVGO 357.61 USD, `observedMarketTime` 1789761602, provider testimony
`rapidapi/yahoo-finance15` / `rapidapi-yahoo-finance15-stock-quotes.v1` /
`body.0`. The trace shows the chain: op 4 primary 166 `httpStatus 429`, op 9
real-time1 `httpStatus 429`, op 14 finance15 `httpStatus 200 completed`.
`sfx provider add` on the installed spec re-runs author/render/dry-run/preflight/
install/verify with the live finance15 attribution.

## Tests and declared digests

- Streaming C# suite: **268 passed / 0 failed** (baseline 265 + 3 provider-add
  tests: rendered migration carries only the declared call, held authoring writes
  and installs nothing, authored provider add is one data spec with `--dry-run`).
- Acceptance suite: `ACCEPTED`, all three declared invocations matched, receipt
  at the selected install root. Two deliberate digest updates:
  `sql/migrations/update-kernel-acceptance-suite-equity-digest.sql` (equity
  observed path) and `update-kernel-acceptance-suite-agent-lane-digest.sql`
  (agent-lane observation), mirrored in `config/kernel-acceptance-suite.v1.json`.

## Residuals

- The generated migration invokes the installed lifecycle runner from the SDA
  checkout (`--sda-root`, `SDA_ROOT`, or a sibling checkout); this is the one
  owed dependency already named in `AGENTS.md`.
- The quote shape (`body.primaryData`) stays unmapped because its currency is
  genuinely absent; a parse-currency/parse-date mechanic would not close that
  gap.
