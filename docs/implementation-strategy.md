# Multi-agent implementation strategy

[target-architecture.md](target-architecture.md) is the decision authority: it
defines the target, the standards, and the execution protocol. This document is
the *execution plan* — how a pool of agents drives the remaining work to the
target in parallel without stopping.

Read both first. The target decides *what*; this decides *who and how*. The
binding requirement that every executable mechanic be embodied per target is
specified in [embodiment-completeness.md](embodiment-completeness.md) — a unit is
not done until that rule holds for the capability it touches.

## Rules every agent follows

1. **The target is fixed; direction is never requested.** The standards decide
   every case. A domain concern only the estate runtime could implement is a
   re-declaration, not an escalation.
2. **A unit of work is atomic.** It is the coordinated change *plus its proof*.
   If several files must change together, change them together; never land a
   subset that leaves the tree broken, never stop mid-unit.
3. **Proof is invocation.** A unit is done when `sfx capability invoke <id> …`
   returns the expected outcome through the kernel (and the delete test, when a
   module is removed). Not a file, not a row, not a green in isolation.
4. **One migration per commit**, idempotent, `ROLLBACK`→preflight→`COMMIT`.
5. **Own your files.** One agent edits a given file at a time. See the
   file-ownership map; the loader and the shared migrations are serialization
   points.
6. **Keep the tree green between units.**
7. **The only escalation is a kernel change request** (a primitive the kernel
   must interpret in every language). Format: primitive, why kernel, data that
   binds it. Nothing else is escalated.

## Lanes

Lanes run in parallel. A lane is a queue of units; agents claim a lane, take the
next unit, land it, prove it, move on.

| Lane | Scope | Owns (files) | Serialization |
|---|---|---|---|
| **A — boot read** | Replace the residual `sidefx-database/sql/diagnostics` read with the estate view; loader reads only context-supplied `readQuery`/`readAuthority` | `src/read-authority.mjs`, `src/invoke-database-capability.mjs`, `src/database-delivery.mjs`, `src/read-execution-delivery.mjs`, `src/read-workspace-config.mjs` | **serial** — one agent at a time (loader is hot) |
| **B — capability re-declaration** | Free every capability still naming a deleted resolver; re-declare ports to a platform mechanic or `{statement,resultColumn}` | one file per unit under `sql/migrations/` | parallel across capabilities |
| **C — overlay/provider completeness** | Generalize `run-declared-graph`'s overlay rule + provider set to every mechanic a graph can use (pure set, effect ports, declared reads) | `sql/migrations/declare-run-declared-graph-capability.sql` + a registry-derived rule | parallel with B; single writer on the file |
| **D — tooling deletion** | Remove architecture-1 scripts and their package.json entries; replace lifecycle scripts whose fallback was architecture 1 | `scripts/**`, `package.json` | parallel; one writer per file |
| **E — reader/presentation capabilities** | Declare `reveal`/`list`/`find`/`circuit`/`catalogue`/`artifact`/`narrate`/`diagram` as capabilities (SQL read + transformation; templates) | one file per unit under `sql/migrations/` | parallel; depends on A for the API |
| **F — kernel (SDA)** | Cross-language primitives. Units 17/18 landed natively in SDA `7fd4ff3` (python governed effect ports + contract admission; c# `SemanticExecutionGraphEffectProvider` + contract-catalog enforcement). Remaining: java/go where a mechanic is still Node-only | SDA repo only | parallel |

## Backlog (seed queue)

| # | Lane | Unit | Proof | Status |
|---|---|---|---|---|
| 1 | A | Loader reads selection/CLI from `analysis.v_capability_graph_source`; drop `capability-embodiment.sql`/`scenario-closure.sql` reads (removes the last `sidefx-database/sql` reach) | equity + greet invokes green; timings show no `*.sql` diagnostic queries | in progress |
| 2 | B | Re-declare the 4 ports binding `authority-read-provider.readCapabilityAuthority` (`read-declared-authority`, `read-capability-authority`, `execute-declared-capability`, `authority-read-provider`) to declared reads | each capability invokes through the kernel | partial |
| 3 | B | Sweep every `PORT` whose `definition_json` names `src/resolvers/` or `materialize-node`; re-declare | `sql/inspect` report shows zero residual references | partial |
| 4 | C | Complete `overlayBindings` for the full pure-mechanic set + effect ports; key by `mechanicId` from the registry | equity, greet, a domain capability all compile+execute | done: `complete-run-declared-graph-pure-mechanic-bindings.sql` merges the registry pure set (16→37 bindings); `resolve-sidefx-eligible-providers` returns `PROVIDERS_RESOLVED` with the retained `resolutionDigest`; greetings unchanged |
| 5 | C | Declared-read provider dispatch by `mechanicId` for domain slots | domain capability executes with no local provider | pending |
| 6 | D | Delete architecture-1 scripts (`verify-estate`, `verify-memory-parity`, `verify-consumer-*`, `package-qualified-pilots`, `pilot-container/run`, `invoke-from-bundle`, `probe-database-invocation`, `report-native-repair`, `validate-scaffold`) and their `package.json` entries | `npm test` / lifecycle scripts green; no dangling imports | done (working tree) |
| 7 | D | Remove `materialize-node` from the delivery graph so `consumer-object-provider`/`native-expression-projection` delete | all 12 resolvers absent; kernel path green | pending |
| 8 | E | Declare `list-capabilities` (SQL read + shaping) as a capability | `sfx capability list` routed through the frontdoor | done: `declare-list-capabilities.sql`; `list`, `find` and `catalogue` dispatch through the declared read and render live |
| 9 | E | Declare `reveal`(meaning)/`catalogue`/`circuit`/`artifact` from the DB-side reads | each operation returns from declared data | partial: `reveal --as meaning` (`declare-read-capability-meaning.sql`, extended by `select-scenario-in-declared-meaning.sql` so a caller-selected scenario is validated and returned as `selectedScenarioId`/`selectedScenario`, verified live), `list`/`find`/`catalogue` (`declare-list-capabilities.sql`) and `circuit`/`artifact`/`reveal --as circuit` (`declare-read-retained-publication.sql`) are declared and verified live; the current model reports `CIRCUIT_PUBLICATION_UNAVAILABLE`; `prepare` is subtracted from the offered surface and refused as an unknown operation |
| 10 | E | Declare `narrate-*`/`diagram-*` as templates/transformations (or request a presentation mechanic if not expressible) | reveal renders from data | pending |
| 11 | F | java/go for any mechanic still Node-only in the target's path | cross-target parity | pending |
| 12 | D | Update/remove tests importing deleted modules (`circuit-diagram`, `consumer-execution`, `consumer-plan`, `consumer-write`, `embodiment-binding`, `node-resolver`, `preparation`) — architecture 1 | `npm test` green | done (working tree) |
| 13 | B | Re-declare `execute-declared-capability` root authority to reach its sub-scenarios (or drop orphan cells) — clears `UNREACHABLE_CELL` | it invokes through the kernel | pending |
| 14 | D | Remove `sql/diagnostics` reads from `scripts/invoke-from-transaction.mjs` and `scripts/extract-inflight-bundle.mjs` | no `sql/diagnostics` outside docs/baselines | pending |
| 15 | C | Compiled effect cells must carry the port `configuration` (`credentialAuthorities`/`endpointAuthorities`) into the cell binding so `createPlatformEffectProvider` receives it. Equity currently returns `PROVIDER_EXCHANGE_NOT_COMPLETED` though the credential env and port authorities are present; the compiled credential cell's `configuration` appears empty. If the compiler drops it, this is the kernel change request (preserve declared effect-port configuration into the compiled cell binding) | `sfx capability invoke resolve-equity-market-price-evidence --input AVGO` → `EQUITY_MARKET_PRICE_PROVIDER_COMPLETED` | pending |
| 16 | E | Expose `contractAuthorities` (resolved from `contracts/contract-catalog.json` + `contracts/*.schema.json`) and the fixtures reference in `analysis.v_capability_graph_source` (`assemble-capability-graph-source.sql`), so regenerated plans carry a non-empty `contractCatalog` (the compiler sets it from `authorityGraph.contractAuthorities`, which the view omits) | a regenerated node plan has non-empty `contractCatalog`; node `bind` resolves | done (`ec6c6a7`) |
| 17 | F (python) | Wire the platform-effect dispatch seam + input contract admission into the python consumer host (`languages/python/src/scenario_kernel/platform/consumer.py#_graph_providers`), mirroring node's `createPlatformEffectProvider` | python embodiment `disposition: terminated`, `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` | done (SDA `7fd4ff3`) |
| 18 | F (csharp) | Wire `SemanticExecutionGraphEffectProvider` into `AdmittedConsumerPlatform`'s `Provider` (dispatch `mechanicId` → declared effect provider) and enforce `plan.contractCatalog` | c# embodiment `disposition: terminated`, `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` | done (SDA `7fd4ff3`) |

## Status (2026-09-14)

Completed units, as reported and with proof where stated:

- **Lane D — units 6 and 12, and the `scripts-disposition-review.md` Net
  (working tree, not yet git-committed).** The 12 eliminated scripts were deleted
  (`audit-semantic-expression`, `audit-lowering-evidence`,
  `materialize-consumer-provider-dependencies`, `preserve-baseline`,
  `qualify-pilots`, `verify-consumer-execution-providers`,
  `verify-consumer-first-failure`, `verify-consumer-fixtures`,
  `verify-declared-fixtures`, `verify-sfx-invocation.ps1`,
  `verify-sfx-preparation.ps1`, `extract-bundle`). The `package.json` lifecycle
  entries `qualify:pilots`/`audit:source`/`audit:lowering` were removed; the dead
  verifier blocks were removed from `scripts/invoke-from-transaction.mjs`; the
  `sql/README.md` diagnostics claim was corrected. Proof: `npm test` passes 8/8.
- **Lane B — units 2 and 3 (partial).** Installed migrations
  `free-declared-read-ports.sql`, `free-contract-admission-ports.sql`,
  `redeclare-execution-graph-read-ports.sql` (free the database-query-provider,
  contract-admission-provider and execution-graph-read-provider Ports from
  `configuration.providerId`) and `delete-orphaned-estate-read-providers.sql`
  (deletes the orphaned `authority-read-provider.readCapabilityAuthority` and
  `read-authority.readAuthority` provider rows).
  `sql/inspect/hand-authored-module-references.sql` is down from 21 to 16 rows;
  7 estate-module PROVIDER rows remain (consumer-authority-context,
  consumer-execution-provider, consumer-plan-provider, embodiment-plan-provider,
  embodiment-write-provider, invoke-database-capability, load-memory-scenario)
  pending Port re-declaration. Proof: `say-hello-world`, `run-declared-query`,
  `read-declared-execution-graph`, `contract-admission-provider` and
  `resolve-equity-market-price-evidence` all invoke green through the kernel.
- **Performance #6 — done.** `add-invocation-supporting-indexes.sql` adds
  `IX_model_capability_capability_id` and `IX_model_sod_version_desc`; the other
  requested indexes already existed.
- **Lane F — units 17 and 18 — done.** Implemented natively in SDA commit
  `7fd4ff3` (`governed_effect_ports.py` / `consumer.py` for python;
  `GovernedEffectPorts.cs` / `AdmittedConsumerPlatform.cs`
  `SemanticExecutionGraphEffectProvider` for c#: real non-facade ports, contract
  catalog enforced). Unit 16 (Lane E) is done via
  `expose-contract-authorities-in-graph-source.sql`, committed `ec6c6a7`.
- **Lane P / invocation reads:** the bounded-read and single-session slice is now
  installed; see the proof below and [performance-optimization.md](performance-optimization.md).
  Full closure/mechanics batching and shared reference-catalog optimization remain
  deferred, not completed.

## Wave 1 (2026-09-14) — six lanes dispatched against the target experience

The backlog above covers lanes A–F (the subtraction of architecture 1). This wave
additionally opens the three primary-experience items in
[target-experience.md](target-experience.md) that have **no estate surface at all**
today, so they are design-first: they read the estate and SDA, produce a committed
markdown design under `docs/`, and author migrations that they install only if the
preflight genuinely passes.

| Lane | Mandate | Target-experience item | Owns |
|---|---|---|---|
| **P — invocation performance** | Ranked plan #1, #2, #4, #5, #3. `say-hello-world` measured at **57 s** (readGraphSource 30.7 s, readAuthority 12.7 s, executeDeclaredGraph 11.4 s) before this wave | the flywheel's cost | `sql/schema/*`, `src/*` (boot), `sql/migrations/optimize-*` |
| **B — re-declaration** | Units 3, 13: the 7 residual estate-module PROVIDER rows; `UNREACHABLE_CELL` on `execute-declared-capability` | #2 one invocation path | `sql/migrations/free-*`, `redeclare-*`, `reach-*` |
| **D — subtraction** | Units 7, 14 + remove the stale `materialize`/`embodiment-materialization` surface | #2, the subtraction phase | `sfx.config.json`, `config/*`, `scripts/*`, `sql/migrations/remove-materialize-*` |
| **U — presentation authority** | The first login-flow capability: capability rows + declared UI authority rows, no framework in the rows | #3 presentation capabilities | `docs/ui-presentation-authority.md`, `sql/migrations/declare-login-*` |
| **T — EPD** | Altitude-selectable streaming, planned-vs-observed overlay, surface `observedPathDigest`; per-cell timing is an SDA change request | #4 execution telemetry | `docs/execution-performance-drilldown.md`, `sql/migrations/declare-observation-*` |
| **J — JSON authoring** | A JSON authoring surface emitting the same normalized rows, preserving idempotency, content-addressed digests, current-definition selection and the rollback preflight | #1 SQL *or* JSON | `docs/json-authoring-surface.md`, `sql/migrations/declare-json-authoring-*` |

**Serialization.** File ownership is the conflict rule, as above — but the *database*
is also a serialization point this wave: a migration drops and recreates the
`model`/`source` guard triggers inside its own transaction, which takes schema
locks. Concurrent migrations therefore block or deadlock each other. A lock timeout
or deadlock is **not** a data defect; the unit retries. Invocation timings are not
comparable across the wave while lane P is landing — judge a unit on its
disposition, not its duration.

**Design-first lanes state their own honesty.** U, T and J must report
authored / preflighted / installed as three distinct states, and must never install
a migration whose preflight did not pass. An accurate "blocked on X" is the
deliverable when the estate cannot yet carry the unit; a green that required
inventing provider or kernel behavior is a finding, not a fix.

## Invocation read slice installed (2026-09-14)

Lane P installed `sql/migrations/bound-capability-invocation-reads.sql` after
rollback dry-run and production-reader preflight. The loader reads each bounded
graph once, skips graph-unused documents, and shares one connection, transaction,
coherence pin, reader identity and mechanic-definition read for the invocation.
Preflight now uses that same session runner. No SDA changes or capability meaning
changes were made; the work has not been git-committed.

Proof: `say-hello-world` and `greet-by-name` retain their graph and outcome digests
at 2.02 s / 2.12 s median delivery time, versus approximately 57 s before.
Full CLI medians are 3.14 s / 3.13 s. Unicode and `observe` pass, and
`sfx capability invoke run-declared-query --input {} --json` executes a real
declared provider query on the same session (seven statements, one pin).
The six-statement greeting path, refusal behavior, cleanup, SQL normalization,
reader permissions and lock lifetime are covered by 32 unit tests and three
opt-in integration checks. Full receipts and repeat commands are in
[performance-optimization.md](performance-optimization.md).

Lane C unit 4 is installed: `complete-run-declared-graph-pure-mechanic-bindings.sql`
merged every declared pure mechanic the semantic-value provider embodies into the
`run-declared-graph-execute` overlay. The previously blocked
`resolve-sidefx-eligible-providers` now returns `PROVIDERS_RESOLVED` through the
real CLI, and the greeting digests are unchanged. The four declared mechanics with
no observing embodiment remain deliberately unbound (SDA
`conformance/execution-graph/mechanics/README.md`); a capability that requires one
is an SDA embodiment request, recorded here as a finding rather than faked green.

## Unit template (use verbatim in the commit)

```
lane: <A..F>
unit: <one line>
standard: <which target-architecture standard governs it>
change: <files/rows>
proof: <exact invocation + expected outcome; delete test if a module is removed>
```

## Coordination

- **Claiming.** An agent takes the next unit in its lane and marks it in-progress;
  no two agents hold the same lane's current unit, and no two agents edit the
  same file.
- **Handoffs.** Lane A is serial; B/C/E each write disjoint migration files; D
  owns scripts. Conflicts are resolved by file ownership, not discussion.
- **Order.** A (1) unblocks E; C (4) unblocks B for domain capabilities; D (6,7)
  only after B/C prove no capability needs the deleted modules.
- **Tracking.** The backlog table is the queue; each completed unit appends its
  commit and proof result.

## Definition of done (program level)

- Every capability invokes through the kernel; `sfx capability invoke` touches no
  `src/resolvers/*` and no `sidefx-database/sql`.
- `src/` is exactly the boot (frontdoor, loader, DB reads, config, sandbox).
- All reader/presentation operations are declared capabilities.
- The only code outside the database is the three irreducible mechanics.
- Cross-language parity for every primitive on the path (java/go included or
  explicitly out of scope).

## Escalation

A kernel change request is the only thing that blocks a lane. Everything else —
resolver references, missing providers, reader operations, tooling — is a unit in
a lane above. Agents do not stop for direction; they take the next unit.
