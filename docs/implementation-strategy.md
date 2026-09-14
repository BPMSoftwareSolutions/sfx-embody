# Multi-agent implementation strategy

[target-architecture.md](target-architecture.md) is the decision authority: it
defines the target, the standards, and the execution protocol. This document is
the *execution plan* — how a pool of agents drives the remaining work to the
target in parallel without stopping.

Read both first. The target decides *what*; this decides *who and how*.

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
| **F — kernel (SDA)** | Cross-language primitives; java/go where a mechanic is still Node-only | SDA repo only | parallel |

## Backlog (seed queue)

| # | Lane | Unit | Proof |
|---|---|---|---|
| 1 | A | Loader reads selection/CLI from `analysis.v_capability_graph_source`; drop `capability-embodiment.sql`/`scenario-closure.sql` reads (removes the last `sidefx-database/sql` reach) | equity + greet invokes green; timings show no `*.sql` diagnostic queries |
| 2 | B | Re-declare the 4 ports binding `authority-read-provider.readCapabilityAuthority` (`read-declared-authority`, `read-capability-authority`, `execute-declared-capability`, `authority-read-provider`) to declared reads | each capability invokes through the kernel |
| 3 | B | Sweep every `PORT` whose `definition_json` names `src/resolvers/` or `materialize-node`; re-declare | `sql/inspect` report shows zero residual references |
| 4 | C | Complete `overlayBindings` for the full pure-mechanic set + effect ports; key by `mechanicId` from the registry | equity, greet, a domain capability all compile+execute |
| 5 | C | Declared-read provider dispatch by `mechanicId` for domain slots | domain capability executes with no local provider |
| 6 | D | Delete architecture-1 scripts (`verify-estate`, `verify-memory-parity`, `verify-consumer-*`, `package-qualified-pilots`, `pilot-container/run`, `invoke-from-bundle`, `probe-database-invocation`, `report-native-repair`, `validate-scaffold`) and their `package.json` entries | `npm test` / lifecycle scripts green; no dangling imports |
| 7 | D | Remove `materialize-node` from the delivery graph so `consumer-object-provider`/`native-expression-projection` delete | all 12 resolvers absent; kernel path green |
| 8 | E | Declare `list-capabilities` (SQL read + shaping) as a capability | `sfx capability list` routed through the frontdoor |
| 9 | E | Declare `reveal`(meaning)/`catalogue`/`circuit`/`artifact` from the DB-side reads | each operation returns from declared data |
| 10 | E | Declare `narrate-*`/`diagram-*` as templates/transformations (or request a presentation mechanic if not expressible) | reveal renders from data |
| 11 | F | java/go for any mechanic still Node-only in the target's path | cross-target parity |
| 12 | D | Update/remove tests importing deleted modules (`circuit-diagram`, `consumer-execution`, `consumer-plan`, `consumer-write`, `embodiment-binding`, `node-resolver`, `preparation`) — architecture 1 | `npm test` green |
| 13 | B | Re-declare `execute-declared-capability` root authority to reach its sub-scenarios (or drop orphan cells) — clears `UNREACHABLE_CELL` | it invokes through the kernel |
| 14 | D | Remove `sql/diagnostics` reads from `scripts/invoke-from-transaction.mjs` and `scripts/extract-inflight-bundle.mjs` | no `sql/diagnostics` outside docs/baselines |
| 15 | C | Compiled effect cells must carry the port `configuration` (`credentialAuthorities`/`endpointAuthorities`) into the cell binding so `createPlatformEffectProvider` receives it. Equity currently returns `PROVIDER_EXCHANGE_NOT_COMPLETED` though the credential env and port authorities are present; the compiled credential cell's `configuration` appears empty. If the compiler drops it, this is the kernel change request (preserve declared effect-port configuration into the compiled cell binding) | `sfx capability invoke resolve-equity-market-price-evidence --input AVGO` → `EQUITY_MARKET_PRICE_PROVIDER_COMPLETED` |
| 16 | E | Expose `contractAuthorities` (resolved from `contracts/contract-catalog.json` + `contracts/*.schema.json`) and the fixtures reference in `analysis.v_capability_graph_source` (`assemble-capability-graph-source.sql`), so regenerated plans carry a non-empty `contractCatalog` (the compiler sets it from `authorityGraph.contractAuthorities`, which the view omits) | a regenerated node plan has non-empty `contractCatalog`; node `bind` resolves |
| 17 | F (python) | Wire the platform-effect dispatch seam + input contract admission into the python consumer host (`languages/python/src/scenario_kernel/platform/consumer.py#_graph_providers`), mirroring node's `createPlatformEffectProvider` | python embodiment `disposition: terminated`, `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` |
| 18 | F (csharp) | Wire `SemanticExecutionGraphEffectProvider` into `AdmittedConsumerPlatform`'s `Provider` (dispatch `mechanicId` → declared effect provider) and enforce `plan.contractCatalog` | c# embodiment `disposition: terminated`, `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` |

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
