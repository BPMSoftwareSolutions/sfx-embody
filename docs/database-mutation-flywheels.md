# Database mutation flywheels

2026-09-12 Â· Team share Â· What we built today and why it compounds

## The flywheel

The loop is the same one the work orders have targeted: **SQL authors a capability
â†’ the unchanged CLI invokes it â†’ the observed result changes as the SQL data
changes â†’ repeat.** No capability-specific source edits, no rebuild, no
per-capability code. What changed today is *what the database can declare* â€” and
each new declaration makes the next capability cheaper.

The operating principle: the database is the mutation layer. A capability's
declarations are database rows; the CLI and runtime read them. Presentation and
input are **read-side**: they reshape the carrier, never the canonical result.

## The pattern

```
capability declaration (rows)
        â”‚
        â–¼
   CLI carrier / estate resolution
        â”‚
        â–¼
   canonical input â†’ execution â†’ canonical outcome
        â”‚
        â–¼
   declared projection (input mapping, display) applied at the surface
```

Four flywheels, each a loop that now closes without code changes:

| Flywheel | Declares | Loop it closes |
| --- | --- | --- |
| **Binding resolution** | a provider implements a platform capability | `reveal` walks `port â†’ platform capability â†’ provider â†’ mechanic` |
| **Definition selection** | one current definition per declared id | consumers read one declaration, not the union of superseded ones |
| **Meaning declaration** | user story, experience, observable conditions, scenario spec, canonical feature | the capability states its meaning without a source edit |
| **CLI surface** | input mapping and display projection | `--input 'AAPL'` and `--display` from the capability's own contract |

## 1. Binding resolution flywheel

**Problem:** every port's provider chain was empty â€” `reveal` reported
`PLATFORM_CAPABILITY_WITHOUT_PROVIDER` and `Mechanics (0)`, because
`model.provider_capability_implementation` had zero rows while the 74 provider
definitions already declared the bindings in their `sda-platform-capability-catalog.v1`
envelopes.

**Database change:** `sql/migrations/populate-platform-provider-bindings.sql` reads those
catalogs, (re)creates the 38 platform-capability identities they name, and inserts
the 38 provider bindings. Resolution (`analysis.v_declared_platform_implementation`)
now reads them.

**Result:** `reveal resolve-equity-market-price-evidence` â†’ `Mechanics (10)`;
`hello-world-sql` â†’ `Mechanics (2)`. Execution unchanged.

## 2. Definition selection flywheel

**Problem:** the selected model carried every historical definition of a declared
id, so consumers read the union of superseded and current declarations â€”
`EXECUTION_AUTHORITY_DEFINITIONS_DISAGREE`, `PORT_DEFINITIONS_REPEATED`,
`TRANSFORMATION_DEFINITIONS_REPEATED`, and three `SCENARIO_INVOCATION_UNRESOLVED`.

**Database change:** `sql/schema/select-one-definition-per-declared-id.sql` replaces
`analysis.v_selected_semantic_definition` so each declared id yields the **current**
definition (highest `semantic_object_definition_pk` per semantic object). Superseded
definitions remain in the model; they stop being the one read.

**Result:** the equity review dropped 11 â†’ 5 observations. The view now presents one
definition per declared id (`0` with more than one); the definitions are **retained,
not deleted** â€” **38 semantic objects** in the selected model carry more than one
definition (74 superseded rows), and **312 declared ids** carry more than one across
every retained definition. This is selection at the read boundary. The old comment's "275 of 8,524"
was that generation's selected model; do not read the rule as `275 â†’ 38`.

## 3. Meaning declaration flywheel

**Problem:** the capability declared no user story, experience, observable
conditions, scenario specification, or canonical feature binding â€” five
"meaning absent" observations, all with no source.

**Database change:** `sql/migrations/declare-equity-meaning.sql` declares them on the
capability and scenario definitions, riding the same current-definition rule. A
follow-up, `sql/migrations/fix-equity-meaning-lineage.sql`, carries the retained-source
resolution forward so the read path still resolves exactly one source for the new
definition.

**Result:** the equity review dropped 5 â†’ **0 observations**, while
`observe` still executes live:
`EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`, `observedPrice`, live provider.

**Corrected accounting** (a prior summary double-counted the three provider
observations):

| Change | Removed | Running total |
| --- | --- | --- |
| Provider bindings | 3 | 14 â†’ 11 |
| Definition selection | 6 | 11 â†’ 5 |
| Meaning declaration | 5 | 5 â†’ 0 |

## 4. CLI surface flywheel

**Problem:** the CLI printed the whole canonical result; it had no way for a
capability to shape its own surface, and every invocation required hand-written
JSON (painful on PowerShell).

**Database change:** the capability's CLI interface declares its surface. The
estate reads it; the CLI applies it read-side.

```json
"configuration": {
  "display": { "select": "outcome.payload", "as": "json" },
  "input":   { "type": "text", "contract": "live-equity-price-request.v1",
               "path": "payload.symbol", "fields": { "payload.region": "US" } }
}
```

- `sql/migrations/scaffold-hello-world.sql` â€” declares both for `hello-world-sql`.
- `sql/migrations/declare-equity-cli-input.sql` â€” declares both for equity, resolved to
  the exact interface declaration the selected bundle reads.
- Estate (`src/invoke-database-capability.mjs`) â€” `readCliConfiguration`,
  `buildCanonicalInput`; the canonical outcome keeps its evidence while the
  surface changes.
- CLI (`config/sfx.commands.json`, `sidefx-cli` `commands.mjs`/`cli.mjs`/
  `index.mjs`/`render.mjs`) â€” `--display` and `--input-type`, raw-scalar carry for
  typed inputs, projection at render time.

**Result â€” the second is a stock symbol, no JSON:**

```powershell
sfx capability invoke hello-world-sql --display --input 'Sidney'
# Hello Sidney!

sfx capability invoke resolve-equity-market-price-evidence --display --input 'AAPL'
# { "symbol": "AAPL", "region": "US", "currency": "USD", "observedPrice": 332.27,
#   "marketState": "CLOSED", "exchange": "NMS", "sourceAttribution": "Delayed Quote" }
```

Rules the surface honors:
- The declaration declares; `--input-type` / `--display` override.
- `--input @file` / `--input -` stay canonical JSON unless a non-json type is named.
- No declaration â†’ canonical input, full outcome; a bare non-JSON scalar fails
  closed (`CAPABILITY_INPUT_JSON_REJECTED`), never coerced.
- The capability declares `fields` for its own defaults (e.g. `region`), so the CLI
  never infers meaning.

## What the rubric said

Each change was checked against the six events of the SQLâ†’CLI flywheel
(`run SQL â†’ invoke â†’ observe â†’ change â†’ re-observe â†’ second identity`). The
execution fixes (1â€“3) were delivery/interpretation necessity. The CLI surface (4)
fails none of the six â€” it is an **experience** improvement, adopted in its
smallest sufficient form (reuse the declaration the estate already reads; add no
new store) per the least-work rule. See
[sidefx-architecture-decision-rubric.md](sidefx-architecture-decision-rubric.md) Â§9.

## Scaffold re-runnability

`sql/migrations/scaffold-hello-world.sql` now writes the full normalized chain and is
re-runnable; two FK-ordering bugs in its cleanup were fixed (scenario faces before
the authority version; clear `capability.feature_pk` before deleting the feature).

## What remains open

The runtime still resolves **exactly one retained-source row per capability**
(`capability-embodiment.sql` â†’ `CAPABILITY_SOURCE_AUTHORITY_UNRESOLVED`), so a
retained source is still mandatory at declaration time rather than a later
promotion. That is the same path-addressed root traced in
[research/sda-cross-apply-authority-gap/README.md](research/sda-cross-apply-authority-gap/README.md),
and it is the next load-bearing item: make declaration cheap, make promotion
optional.

## Artifacts

| Purpose | Path |
| --- | --- |
| Provider bindings | `sql/migrations/populate-platform-provider-bindings.sql` |
| Definition selection | `sql/schema/select-one-definition-per-declared-id.sql` |
| Meaning declaration | `sql/migrations/declare-equity-meaning.sql` |
| Meaning lineage repair | `sql/migrations/fix-equity-meaning-lineage.sql` |
| Equity CLI contract | `sql/migrations/declare-equity-cli-input.sql` |
| Hello-world scaffold | `sql/migrations/scaffold-hello-world.sql` |
| Estate CLI resolution | `src/invoke-database-capability.mjs` |
| Command surface | `config/sfx.commands.json` |
| CLI flags/render | `sidefx-cli/src/{commands,cli,index,render}.mjs` |
| Diagnosis | `docs/research/sda-cross-apply-authority-gap/README.md` |

Every SQL artifact defaults to `ROLLBACK` for review and is installed by changing
the final `ROLLBACK` to `COMMIT`.

