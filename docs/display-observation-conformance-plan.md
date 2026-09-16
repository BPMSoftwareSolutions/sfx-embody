# Display and observation conformance plan

Status: OPEN
Owner: estate + SDA (kernel) + sidefx-cli
Frame: `transistor-model.md` §1 — declared authority (1) in the database or an admitted
resolver (0) in the SDA kernel (node/python/csharp conformance floor). No third place;
code found outside the kernel moves to rows or to the resolver.

## Verdict

The declared display projection **already exists and is truthful when it runs**:
`sql/migrations/declare-observation-display-projection.sql` declares the
`sfx-display-document.v1` contract, the `<capability>-observe-display.v1` transformation
and the `semantics.cli.display`/`readings` configuration; the boot evaluates it
(`src/invoke-database-capability.mjs:423-431`) and the CLI renders it
(`sidefx-cli/src/render.mjs:235-252`). The all-green display while the declared outcome is
`EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE` is **code shadowing that declaration** — three
fabrications plus fallbacks — and one genuine kernel gap: non-node testimony shape.

## What already complies

- Document contract, display transformation and readings: `declare-observation-display-projection.sql:61-98`,
  `declare-equity-observe-display.sql:60-123`.
- Consumption: `src/invoke-database-capability.mjs:397-398` (lookup), `:424` (gate), `:429-431`
  (carrier + kernel evaluator), `:437` (attach).
- Rendering of the declared document: `sidefx-cli/src/render.mjs:221-252` (`blocks`,
  `emitDocument`).
- Kernel output the projection reads: result envelope + `cellTestimony`/`edgeTestimony`
  (node/python/csharp schedulers) with `providerEvidence` at provider/physical altitudes
  (`cell-execution-testimony.schema.json:26-36,47-48`).

## Where the changes go

| # | behavior / defect | location | class | destination |
|---|---|---|---|---|
| D1 | THEN tick hardcoded `completed` | `sidefx-cli/src/render.mjs:89` | DEFECT (fabricates meaning) | delete — the declared document supplies status; renderer keeps `emitDocument` only |
| D2 | responsibility marks read only `disposition`, ignore `outcomeVariant` | `render.mjs:75-77`, `:202` | DEFECT | delete; declared document |
| D3 | streamed entry status: mechanically-completed cell prints `completed` regardless of variant | `src/execution-drilldown.mjs:57-64` | **CLOSED** by kernel-attached classification (SDA `6ba5c42`, estate `2d61e1e`): testimony carries declared `outcomeClassification` at every altitude and the estate reads it (`success`→`completed`, `failure`→`failed`); only undeclared variants fall back to the mechanical disposition | no transformation needed; the observation-presentation work that remains is entry text/address (D4) |
| D4 | entry text/shape, address join, overlay rows, story extraction | `execution-drilldown.mjs:35-75,150-277`; `semantic-address.mjs:6-127` | 1 mislocated | same declared transformations; kernel emits `semanticAddress` and faces with testimony |
| D5 | observation field allowlist + object fields | `src/observation-filter.mjs:3-21` | 1 mislocated | declared telemetry authority (`scenario-execution.telemetry-authority.json`, currently unread); keep the scalar picker as emission seam (`:23-38`) |
| D6 | silent display downgrade: unresolved `transformationId` attaches raw config, terminal falls back to the story path | `invoke-database-capability.mjs:425-437`; `render.mjs:249` | DEFECT | hard refusal `CAPABILITY_DISPLAY_NOT_RESOLVED`, or a declared disposition; delete the legacy `{select,as}` fallback (`render.mjs:254-257`) |
| D7 | duplicate operation table / request validation / input mapping decided in boot | `invoke-database-capability.mjs:9,185-256`; `config/sfx.commands.json:2-158` | 1 mislocated | one declared mapping + declared schemas; boot keeps protocol seams |
| D8 | platform registry loader and expression evaluator imports | `invoke-database-capability.mjs:19-37,167-171` | 0 (kernel loader) / 0-seam (evaluator) | registry loader is SDA request 5 (`transistor-model.md` §10); evaluator stays the one admitted seam |
| D9 | estate runtime loop, estate-provider dynamic imports, invoke-scenario recursion | `invoke-database-capability.mjs:126-161` | 0 mislocated | kernel carrier loop (SDA) |
| D10 | `--display` effect and `--trace`/reading selection semantics live in code | `config/sfx.commands.json:81,96`; `cli.mjs:106-110`; `commands.mjs:9` | DEFECT (flag with no declared meaning) | declared readings (`semantics.cli.readings`, already declared by `declare-observation-readings.sql:52`) |
| D11 | result-shape sniffing and envelope field stripping | `render.mjs:10-15`; `delivery-result.mjs:11` | DEFECT / 1 | declared result/envelope contract |

Minimal frontdoor seam that stays (0): stdin envelope read/parse/size
(`database-delivery.mjs:11-18`), stdout single JSON (`:59`), stderr `SFX_OBSERVATION`
frame (`:38-44`), config/DB driver/sandbox (`:20-37`), read session
(`database-read-session.mjs`), terminal transport (`sidefx-cli/src/delivery.mjs:19-105`).

## Kernel gaps (SDA requests)

1. **Testimony shape parity.** Python and C# schedulers and all three projected emitters
   omit required `cell-execution-testimony.v1`/`edge-execution-testimony.v1` fields
   (python `execution_graph.py:221-239,270-280`; csharp
   `SemanticExecutionGraphScheduler.cs:223-237,280-289`; projected emitters likewise).
   Node is the only conformant shape. A language-neutral display projection needs one
   stable testimony contract in all three.
2. **Schematize the result envelope** `{disposition, outcome, outcomeVariant,
   cellTestimony, edgeTestimony, observedPathDigest}` — currently unschema'd.
3. **Duration parity**: node rounds (`scheduler.js:271`), python/csharp emit raw floats;
   the vocabulary has no rounding op — pick one (declared rounding mechanic or
   resolver-side normalization) and conform all three.
4. **Projection point (only if the display must run inside the kernel invocation).** Today
   the boot evaluates the declared transformation over the result; no kernel
   post-execution projection step exists. Not required while the boot path holds; if
   required, it is a new mechanic with the full conformance obligation
   (`semantic-value-mechanics.authority.v1.json`, registry digest re-pin, vectors,
   three-language implementations).

Recorded as request 8 in `transistor-model.md` §10.

## Estate rows to add

- Observation-presentation transformation(s): altitude lanes and entry text/address
  (D4) — the same declare pattern as `declare-observation-display-projection.sql`.
  The status token is settled by the kernel-attached `outcomeClassification` (D3,
  SDA `6ba5c42`): no status mapping belongs in rows or code.
- Telemetry authority wiring so the allowlist is read, not code (D5); readings consumed
  from `semantics.cli.readings` (D10).
- Delete the silent downgrade and the legacy `{select,as}` path (D6).
- Fix `model.configure_interface` (`sql/schema/authoring-procedures.sql:728-735` pairs
  `MAX(scenario_pk)` with `MAX(scenario_version_pk)` across history); until fixed, the
  envelope-rewrite pattern in `declare-equity-observe-display.sql:81-123` is the workaround.
- Namespace reach: a shared observation-presentation transformation must be declared in
  the capability namespace or a reachable closure (`assemble-execution-declarations.sql:73-82`).

## Acceptance

1. `sfx capability observe resolve-equity-market-price-evidence --input AVGO` with the
   provider quota available shows a live price and honest statuses.
2. With the provider unavailable (quota exhausted), the same command shows
   `EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE` / `PROVIDER_EXCHANGE_NOT_COMPLETED` — never a
   green THEN or a green `observe-equity-price-exchange`.
3. `--observation-altitude provider|physical` streams provider/physical cells with bounded
   `providerEvidence` carried end to end.
4. The CLI contains no status derivation: with the declared document removed, it renders
   nothing rather than a fabricated story.
5. Testimony is shape-identical across node/python/csharp for the shared fixtures.

## Sequencing

1. CLI deletions (D1, D2, D6 legacy fallback, D11) — no data dependency; removes the
   fabrications.
2. SDA kernel requests 1-3 (testimony parity, envelope, durations), plus request 4
   (physical-altitude effect execution and mechanic outcome aggregation —
   `docs/sda-change-request-effect-altitude-execution.md`; the equity run shows
   `BOUND` at provider altitude overridden by `CREDENTIAL_NOT_AVAILABLE` at
   physical altitude, with `exchangeCount: 0`).
3. Declared observation-presentation + telemetry rows (D4, D5, D10); remove the
   corresponding estate logic; keep only emission seams.
4. `configure_interface` fix; then D7/D9 migration as capacity allows.

## References

- `docs/display-projection-decision-record.md:35,42,168-193` (D1/D6/D3 decisions, U-series).
- `docs/display-projection-migration.md:141-142` (vocabulary limits).
- `docs/sda-change-request-projected-testimony.md:208-249` (projected-body parity, adjacent).
- `docs/sda-change-request-effect-altitude-execution.md` (physical-altitude effect
  execution and mechanic outcome aggregation; the credential/exchange failure is
  pre-network — `exchangeCount: 0` — not the rate-limited provider).
- `docs/transistor-model.md:170-191` (§3.2 boot classification), `:418-483` (§10 requests).
- `docs/next-experiences.md` §5 (observation-logic migration unit).
