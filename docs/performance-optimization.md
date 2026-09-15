# Invocation performance: cheapest, fastest flywheel

Goal: make `sfx capability invoke|observe` the cheapest and fastest path we have,
and remove transaction/transport overhead from the flywheel. The first bounded-read
and single-session unit is installed; this document records its proof and the
remaining work.

Authority: [target-architecture.md](target-architecture.md),
[embodiment-completeness.md](embodiment-completeness.md) (agents must not edit the
SDA repo — kernel changes are **requests**), and
[implementation-strategy.md](implementation-strategy.md).

## Installed slice (2026-09-14)

Installed `sql/migrations/bound-capability-invocation-reads.sql` after its rollback
dry run and uncommitted invocation preflight. No capability meaning, SDA code,
permission flags, or persistent cache was changed.

| capability | before: delivery process | after: delivery process | after: complete CLI |
|---|---:|---:|---:|
| `say-hello-world` | 57.268 s | **2.021 s** | **3.141 s** |
| `greet-by-name` | 57.527 s | **2.121 s** | **3.130 s** |

Before is one fresh successful baseline per identity, after repairing pre-existing
UTF-16 source encoding. After is the median of three serial, fresh-process CLI
invocations per identity, with warm SQL plans. Delivery is
`evidence.timings.processTotal`; complete CLI is external wall time. These are
different measurements, not interchangeable. Delivery time fell by approximately
96%, with the same canonical graph, outcome, and observed-path digests.

The installed circuit is:

```text
one connection + transaction + pinModel + EXECUTE AS sidefx_reader WITH NO REVERT
  -> execution delivery
  -> bounded capability graph + closure + mechanics
  -> bounded executor graph + closure (reuse the same mechanics)
  -> kernel compile/execute, including any declared reads on this session
  -> rollback + close
```

- `analysis.capability_graph_source(id, include_documents, namespace)` selects the
  capability and namespace before assembly and evaluates one local declaration
  set. Both new functions are covered by the existing SQL-definition pin.
- The authority read carries the graph. There is no second `readGraphSource`
  query or timing phase. CLI mappings and executor bindings use that same graph.
- Invocation sets `documents: false`: feature, fixture, workspace, capability-face,
  and semantic-graph document assembly is skipped. Graph-required operations,
  interfaces, transformations, contracts and referenced schemas remain intact.
  Explicit extraction retains the full document set, including graph-v3 authority.
- Ordinary greeting invocations issue six statements, with one connection, pin,
  and reader switch. `run-declared-query` performs its real provider read as a
  seventh statement on that same session (2.110 s delivery, 2.778 s full CLI).
- Preflight uses the production session runner and authority reader, applying its
  rollback migration before the pin. It also extracts a full bundle, so its total
  query count is not the production invocation count.
- Requests are serialized on the transaction; inputs and result normalization,
  post-computation row limits, digests, coherence refusal, and failure cleanup are
  preserved. Enabled and disabled guard triggers survive installation unchanged.

Proof locations (local retained evidence):

- SQL parity, namespace collisions, guard restoration, idempotency and query plans:
  `evidence/bound-capability-invocation-reads-2026-09-14T23-23-24.721Z/`.
- Production-reader rollback preflight:
  `evidence/invocation-optimization-preflight-2026-09-14T23-40-33.663Z/`.
- Installed CLI receipts and timings:
  `evidence/invocation-optimization-installed-2026-09-14T23-52-15.455Z/`.
- Repeat the installed checks: `node evidence/verify-invocation-optimization.mjs installed`.
- Unit tests: `npm test` (32 passed; three opt-in integration checks skipped).
- Live reader/lock/normalization checks and installed-driver startup failure:
  `cmd /d /c "set SFX_DATABASE_INTEGRATION=1&& node --test tests/database-read-session.integration.test.mjs"`
  (three passed).

`observe`, Unicode input, a real declared SQL read, missing identities and wrong
namespaces were verified through the CLI. Five captured graph documents retain
byte equality; full declaration parity covers six capabilities. The original
views remain available to existing SQL consumers and were not rewritten.

**Binding completion (installed 2026-09-15):**
`sql/migrations/complete-run-declared-graph-pure-mechanic-bindings.sql` derived the
missing overlay entries from the estate's own MECHANIC registry and merged them
into `run-declared-graph-execute` (16 → 37 bindings; `required_pure_unbound: 0`).
Preflight and the installed CLI now return `PROVIDERS_RESOLVED`, `eligibleCount: 1`
and the retained `resolutionDigest`
`sha256:02d4e6e01b2fe6c49f76d97c8af407dc03b2dbc12cad245b8aaff95b7b810ca5`; greeting
graph/outcome digests are unchanged. The four declared mechanics with no
observing embodiment (`bind-path`, `canonical-json-byte-validation`,
`retained-lineage-authorization`, `canonical-artifact-byte-planning`) are
deliberately not bound; a capability that needs one is an SDA embodiment request.
Composed equity retains its pre-existing
`GRAPH_COMPILER_MISSING_INVOKED_SCENARIO` compilation failure.

**Remaining cost:** roughly one second for connection/pin setup, several hundred
milliseconds for delivery process setup, and additional CLI transport/startup.
The six read statements still have separate round trips. External-schema references
still use the existing selected-estate schema-ID catalog. Declared providers that
explicitly query the old views still pay those views' costs; the new boot path
does not silently rewrite their declared SQL.

The older uninstalled `optimize-capability-graph-source.sql` draft is superseded by
this migration. It has an incompatible function signature and must not be installed
over the working read. Its existing worktree contents were left untouched.

## Original cost model (measured)

| phase / read | measured | cause |
|---|---:|---|
| `readGraphSource` — `analysis.v_capability_graph_source` | **35 s warm, >120 s cold** | the view assembles JSON for **every capability in the estate** before the caller's `capability_id` filter can prune it; its `contract_authorities` CTE reads `v_capability_execution_declaration` **4×** |
| `readAuthority` — `analysis.v_capability_execution_declaration` | **11–20 s** | estate-wide intermediates (`def` window over ~11k defs, `directcontract`, `capcontract` `CROSS APPLY fn_contract_schema_closure` per row — **1.08M lob reads**, dead `reachable`) computed before pruning to the one capability. 11 rows / 104 KB out |
| fixed per-`query()` cost | **~1 s × 8 calls ≈ 8 s** | each `query()` opens a new pool, `tx.begin()`, `pinModel` (applock + `sys.sql_modules` digest), `EXECUTE AS`, then closes |
| process setup | **0.8–1.0 s** | Node spawn + `mssql` import (~357 ms) + config + env |
| redundancies | several s | `graph_source` evaluated twice; the declaration document recordset is read on every invoke though invoke uses only `recordsets[0]`; the loader re-reads `run-declared-graph`'s own bundle |

Correctness flag found while measuring: the declaration view's `STRING_AGG`
concatenations can overflow 8000 bytes (it throws after ~99 s unfiltered) — widen to
`nvarchar(max)`.

## Ranked plan

| # | issue | fix | original expected impact | classification | status |
|---|---|---|---|---|---|---|
| 1 | graph source assembles the estate before filtering | parameterized functions with a local declaration table, scoped by capability and namespace | removes the **35 s+** dominant term | **DB** (`sfx-embody/sql`) + loader call site | installed on the boot path |
| 2 | execution-declaration recomputes estate-wide CTEs; per-row closure TVF; dead `reachable` | scope capability and definition lookups first; deduplicate direct schema seeds; remove dead work; widen catalog `STRING_AGG` | **11–20 s → ~1–2 s** | **DB** | bounded assembly installed; shared reference-catalog optimization deferred |
| 3 | declaration document recordset read on every invoke | suppress graph-unused assembly and document return; explicit extraction opts in | removes **8–20 s/invoke** | **DB + boot/loader** | installed |
| 4 | `graph_source` read twice | return it in the authority read; drop the second | ~3 s + a round trip | **boot/loader** | installed |
| 5 | closure and mechanics are separate round trips | fold into one statement/batch | ~1–2 s | **boot/loader** | mechanics reused once; batching deferred, remaining cost is milliseconds |
| 6 | missing supporting indexes | seek indexes on `capability(capability_id)`; `semantic_object_definition(semantic_object_pk, definition_pk DESC) INCLUDE (canonical_content_pk)`; `contract_version(schema_object_pk)`; `scenario_input/outcome_contract(scenario_version_pk)` | ms-level; helps #1/#2 | **DB**; a persisted column on `source.content_object` is SDA-owned → **request** | done |
| 7 | per-query connection, transaction and coherence pin | one **read session**: single pool + `pinModel` + `EXECUTE AS`, N statements, rollback and close; retain coherence checks | removes ~7 connect + 7 pin + 7 tx-begin **≈ 7 s** | **boot** (query runner) | installed, including preflight |
| 8 | sequential one-shot reads | **one declared read returning all recordsets** in a single batch | combines #3–#7 | **DB + boot** | deferred; six statements now share one session |
| 9 | documents re-assembled every invocation | materialize assembled documents keyed by `(estate_model_pk, capability_id, entry_id)` **plus a row-generation key**; serve by seek | O(1) reads | **DB**, but see the invariant below — a digest-only key is unsafe | deferred; no persistent cache needed for this slice |
| 10 | heavy module import per invoke; spawn per invoke | keep `typescript`/`ajv` off the path (already are); long-lived delivery (daemon/IPC) with pool + module reuse | ~0.7–0.9 s | **SDA/lib change request** (CLI transport) | deferred until startup cost justifies a transport change |
| 11 | shared `v_selected_semantic_definition` full-scan/decodes | optimize shared selection only on measured demand; estate definition already exists in `sql/schema/select-one-definition-per-declared-id.sql` | 1.4–1.7 s → sub-second | **DB** for the estate-owned view | deferred; bounded assembly no longer uses a global newest-definition map |

Status 2026-09-14: #6 was already done (`add-invocation-supporting-indexes.sql` adds
`IX_model_capability_capability_id` and `IX_model_sod_version_desc`; the other
requested indexes already existed). The installed slice above supersedes the
earlier concurrent-agent status for invocation reads. Deferred items are not
claimed implemented, and the single-digit budget does not justify adding a cache
or delivery daemon merely to complete the original list.

## Invariants that must survive every optimization

- One coherence pin per invocation (`snapshotId` / `projectionDigest` /
  `viewDefinitionDigest`), one `EXECUTE AS sidefx_reader`, and the existing
  `DATABASE_AUTHORITY_NOT_COHERENT` check. Do not drop or weaken them.
- `restrictMemoryProcess` and the `--experimental-permission` boundary stay (no fs
  writes, no cache reads). #7/#10 must keep the same proof.
- **A derived/materialized read is never authoritative and must be rebuildable.**
  The coherence digests do **not** change on in-place `INSERT`/`UPDATE` of
  `model`/`source` rows (which is exactly how authoring migrations write meaning),
  so a cache keyed only on the digest trio is **stale after an authoring
  migration**. Any materialization (#9) needs a row-generation key bumped by every
  authoring migration, or must refresh inside the same transaction — otherwise it
  is rejected.

## Classification summary

- **Pure DB (sfx-embody/sql):** #1 graph-source parameterization, #2 declaration
  rewrite, #6 indexes, #8 combined read, #9 materialization DDL/refresh.
- **Boot/loader (estate reader — not SDA, not meaning):** #3 conditional recordset,
  #4 merge the graph read, #5 fold closure/mechanics, #7 read session, and carrying
  `run-declared-graph`'s authority once instead of re-reading it.
- **SDA change request (to the session user; do not edit SDA):** #10 the delivery
  transport (daemon/IPC) in the CLI/platform; any persisted column on
  `source.content_object`. The estate's selected-definition view is already
  declared in `sfx-embody/sql/schema`.

## Definition of done

- `sfx capability invoke|observe <capability>` completes within a small single-digit
  seconds budget on an idle DB, with the same outcome/digest as today.
- One read session per invocation; one authority read (no double `graph_source`);
  no estate-wide assembly before the capability filter.
- The coherence checks, reader role, and permission boundary are intact; any
  materialized read is rebuildable and generation-keyed.
- No SDA edit was made from this repo: any kernel/transport/platform change is an
  SDA change request submitted to the session user.
