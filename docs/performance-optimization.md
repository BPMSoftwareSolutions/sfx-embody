# Invocation performance: cheapest, fastest flywheel

Goal: make `sfx capability invoke|observe` the cheapest and fastest path we have,
and remove transaction/transport overhead from the flywheel. Research only — no
implementation here; this is the plan.

Authority: [target-architecture.md](target-architecture.md),
[embodiment-completeness.md](embodiment-completeness.md) (agents must not edit the
SDA repo — kernel changes are **requests**), and
[implementation-strategy.md](implementation-strategy.md).

## Where the time goes (measured)

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

| # | issue | fix | expected impact | classification |
|---|---|---|---|---|
| 1 | graph source assembles the estate before filtering | parameterize to one capability **before** JSON aggregation — inline TVF `analysis.capability_graph_source(@capability_id)` (or `CROSS APPLY` with `cap` filtered first); loader calls it | removes the **35 s+** dominant term | **DB** (`sfx-embody/sql`) + loader call site |
| 2 | execution-declaration recomputes estate-wide CTEs; per-row closure TVF; dead `reachable` | scope `cap` to the selected capability first; compute the contract-closure set once (set-based recursive CTE, not a per-row multi-statement function); delete dead `reachable`; widen `STRING_AGG` | **11–20 s → ~1–2 s** | **DB** |
| 3 | declaration document recordset read on every invoke | make it conditional (as `resolution` already is) — off for invoke | removes **8–20 s/invoke** | **boot/loader** |
| 4 | `graph_source` read twice | return it in the authority read; drop the second | ~3 s + a round trip | **boot/loader** |
| 5 | closure and mechanics are separate round trips | fold into one statement/batch | ~1–2 s | **boot/loader** |
| 6 | missing supporting indexes | seek indexes on `capability(capability_id)`; `semantic_object_definition(semantic_object_pk, definition_pk DESC) INCLUDE (canonical_content_pk)`; `contract_version(schema_object_pk)`; `scenario_input/outcome_contract(scenario_version_pk)` | ms-level; helps #1/#2 | **DB**; a persisted column on `source.content_object` is SDA-owned → **request** |
| 7 | every read re-assembles documents | one **read session**: single pool + `pinModel` + `EXECUTE AS`, N statements, one close; boot slices recordsets and keeps the existing coherence checks | removes ~7 connect + 7 pin + 7 tx-begin **≈ 7 s** | **boot** (query runner) |
| 8 | 8 sequential one-shot reads | **one declared read returning all recordsets** (delivery, authority, closure, mechanics, graph source, `run-declared-graph` authority) in a single batch | combines #3–#7 | **DB + boot** |
| 9 | documents re-assembled every invocation | materialize assembled documents keyed by `(estate_model_pk, capability_id, entry_id)` **plus a row-generation key**; serve by seek | O(1) reads | **DB**, but see the invariant below — a digest-only key is unsafe |
| 10 | heavy module import per invoke; spawn per invoke | keep `typescript`/`ajv` off the path (already are); long-lived delivery (daemon/IPC) with pool + module reuse | ~0.7–0.9 s | **SDA/lib change request** (CLI transport) |
| 11 | SDA-owned `v_selected_semantic_definition` full-scan/decodes | MAX-per-object selection + `object_kind`-leading index; relocate the definition into `sfx-embody/sql/schema` per the target | 1.4–1.7 s → sub-second | **SDA change request** (sidefx-database) unless relocated |

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
  transport (daemon/IPC) in the CLI/platform; #11 `v_selected_semantic_definition`
  (sidefx-database) unless relocated to `sfx-embody/sql`; any persisted column on
  `source.content_object`.

## Definition of done

- `sfx capability invoke|observe <capability>` completes within a small single-digit
  seconds budget on an idle DB, with the same outcome/digest as today.
- One read session per invocation; one authority read (no double `graph_source`);
  no estate-wide assembly before the capability filter.
- The coherence checks, reader role, and permission boundary are intact; any
  materialized read is rebuildable and generation-keyed.
- No SDA edit was made from this repo: any kernel/transport/platform change is an
  SDA change request submitted to the session user.
