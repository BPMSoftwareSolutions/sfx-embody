# Work order 002 result: proving the working loop

2026-09-12 · Result · Complete loop observed; database change rolled back.

## What was run

The loop: read the working definition → make one SQL edit → invoke the edited
definition → vary inputs → roll back. The edit is uncommitted, so the read path
must see it on the same connection. The invocation is therefore done from the
extracted in-flight bundle, not from a separate CLI connection.

```powershell
# 1-2. Apply the edit (uncommitted) and extract the edited bundle
node --experimental-vm-modules scripts/extract-inflight-bundle.mjs `
  docs/sql/work-order-002-edit-equity.sql `
  evidence/resolve-equity-market-price-evidence/edited-bundle.json `
  resolve-equity-market-price-evidence

# 3. Vary a schema-supported input directly as arguments, from the bundle
node --experimental-vm-modules scripts/invoke-from-bundle.mjs `
  evidence/resolve-equity-market-price-evidence/edited-bundle.json --symbol AAPL --region US
node --experimental-vm-modules scripts/invoke-from-bundle.mjs `
  evidence/resolve-equity-market-price-evidence/edited-bundle.json --symbol MSFT --region US
node --experimental-vm-modules scripts/invoke-from-bundle.mjs `
  evidence/resolve-equity-market-price-evidence/edited-bundle.json --symbol AAPL --region XX
```

The one edit (`docs/sql/work-order-002-edit-equity.sql`): append `-EDITED` to the
normalize transformation's `bindingId` literal
(`rapidapi-davethebeast-yahoo-finance166-stock-price.v1` →
`…-stock-price.v1-EDITED`). It is a single `REPLACE` over the retained
transformation, with a new content object and a repointed appearance.

## Step 1 — Read (actual working definition)

```
capability_id  resolve-equity-market-price-evidence
scenario_id    resolve-equity-market-price-evidence
input_id       live-equity-price-request        contract_reference_state RESOLVED
event_id       equity-market-price-evidence-requested   authority_reference_state RESOLVED
responsibility the canonical evidence retains symbol, region, currency, price, market
               time, market state, exchange, source attribution, and provider testimony
               identity, or names why resolution was held
outcome_id     equity-market-price-evidence
```

Bundle read path: `authorityRows [1,13,7]`, `closureRows [1]`, `mechanicRows [191]`.

## Step 2/3 — Edit and invoke, varied (actual outputs)

| Symbol | Region | Disposition | Outcome |
| --- | --- | --- | --- |
| AAPL | US | `terminated` | `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`, `observedPrice 332.27`, `marketState CLOSED`, `sourceAttribution "Delayed Quote"`, `providerTestimony.bindingId "…-stock-price.v1-EDITED"` |
| MSFT | US | `terminated` | `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`, `observedPrice 495.63`, `marketState CLOSED`, `sourceAttribution "Delayed Quote"`, `providerTestimony.bindingId "…-stock-price.v1-EDITED"` |
| AAPL | XX | `rejected` | `null` — invalid `region` rejected at input admission |

The edited value is visible in the outcome (`bindingId` carries `-EDITED`), and
the two symbols produced different observed prices from the live provider.

## Step 4 — Roll back (fresh read)

```
current-snapshot transformation digest   sha256:dd31ccde72c84fc8e39055485fb4c51071f2578229cc494735332fbb83966872
original definition present              yes (1 appearance)
edited digest cb42a76b… present          no  (0 content rows, 0 appearances)
edited-…-EDITED text present             no  (0 rows)
```

## Scorecard

| Measure | Before | After |
| --- | --- | --- |
| Flywheel contribution, 0–3 | **3** (proposed) | **3** — necessary to prove the loop; assess ongoing benefit after use |
| End-to-end evidence, 0–2 | **0** — untested | **2** — complete loop observed through invocation |
| CLI checkpoints | **Not run** | **4/4** — read, edit+invoke, vary+check, rollback |
| Effort and burden | Unknown | One ~40-line SQL edit + 5 commands; each equity invocation a few seconds. No new runtime maintenance. Not time-instrumented. |

## Honest scope notes

- The invoker is the local `invoke-from-bundle.mjs` harness (direct `--symbol` /
  `--region` arguments, no database for planning). The entity-neutral `sfx`
  command still takes data via `--input`; a first-class `--symbol`/`--name` flag
  on `sfx` itself remains the separate interface/mapping work.
- The equity calls are **live and online** (real provider via the environment
  credential); observed prices vary run to run by design. No fixture was used.
- The edit and its new content object were rolled back; the stored definition is
  unchanged.
- The install of the hello-world capability previously dropped the guards on the
  tables this edit touches (`source.content_object`, `source.source_appearance`);
  that is why the in-place edit is possible without further cleanup.
