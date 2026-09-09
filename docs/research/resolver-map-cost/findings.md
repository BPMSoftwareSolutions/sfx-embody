# Why `scenario-resolver-map.sql` costs 30 seconds

Investigation: 2026-09-09. Status: mechanism established, cause not yet confirmed
by timing. Every claim below is marked **measured**, **read** (from source), or
**inferred**.

## Symptom

`sfx capability invoke resolve-equity-market-price-evidence` — **measured**, two
runs:

```text
capability-embodiment.sql      1,221 ms
scenario-resolver-map.sql     30,440 ms      89% of the call
mechanic-definitions.sql       1,138 ms
readAuthority                 32,801 ms
executeScenario                    3 ms
processTotal                  34,184 ms
```

The query returns `rowCounts [187, 1, 4]`. Thirty seconds for 187 rows is a plan
problem, not a volume problem.

Selecting the view directly is worse than the invocation path. Both
`06-language-resolution-all-targets.sql` and
`07-language-resolution-node-only.sql` — **do not complete**. Observed during
this investigation.

Six of the split queries do not complete: **06, 07, 08, 09, 10 and 12** — every
one that selects from `v_scenario_language_resolution` or its aggregates. 07 is
the sharpest: it carries the same predicate set the invocation uses, including
`target_language='node'`, yet the invocation itself completes in 30 s.

**Contention was ruled out — measured.** While those queries were hanging:

```text
application locks on sidefx:model-write     0 rows
user sessions with blocking_session_id      none (35 sessions, all background/system)
active transactions                         10 (system)
```

So the hangs are real query cost, not a concurrent registration holding the
write lock. An earlier reading of this investigation attributed them to blocking;
that was wrong and is corrected here.

**The shape this points at.** `SELECT COUNT_BIG(*) FROM
analysis.v_declared_platform_implementation` returns 85 rows **instantly** —
**measured**. The function is not slow in isolation. It becomes catastrophic
*inside the join*, which is the classic multi-statement TVF failure: the
optimizer has no cardinality for it, estimates a fixed low row count, and picks
nested loops — re-invoking the function per outer row, each invocation joining
`v_selected_semantic_definition` (9,139 rows) twice and running four `JSON_VALUE`
calls per surviving row. A query that materialises 85 rows once is cheap; the
same function driven per-row is unbounded.

That the invocation survives at 30 s while a bare `SELECT` does not is consistent
with `SELECT * INTO #resolver_map` producing a different plan shape than a
streaming select, but that is **inferred** — only an execution plan confirms it.

## What the planner actually consumes

**Read** from `src/materialize-node.mjs`. The query returns three recordsets and
the planner uses:

| Recordset | Size | Used for | Site |
| --- | --- | --- | --- |
| 0 | 187 rows × 29 cols | filtered to `requirement_kind='MECHANIC'`, deduped on `(implementation_id, implementation_export)`, asserted to be **exactly one** row | [`:115`](../../../src/materialize-node.mjs) |
| 1 | 1 row | one boolean: `readiness === 'CAN_ATTEMPT_EMBODIMENT'` or throw | `:24` |
| 2 | 4 rows | downstream scenario closure and faces | `:92` |

Twenty-seven of recordset 0's twenty-nine columns are never read. The entire
187-row matrix collapses to one `(implementation_id, implementation_export)`
pair.

Recordset 2 already bypasses the resolution chain — it queries
`v_scenario_invocation_closure` joined to the scenario tables directly.

## The mechanism

**Read** from `sql/migrations/004-scenario-resolver-map.sql`.

`analysis.v_declared_platform_implementation` is not a view doing work. It is:

```sql
CREATE OR ALTER VIEW analysis.v_declared_platform_implementation AS
SELECT * FROM analysis.declared_platform_implementations();
```

and that function is **multi-statement**:

```sql
CREATE OR ALTER FUNCTION analysis.declared_platform_implementations()
RETURNS @implementations TABLE (...) AS BEGIN
  DECLARE @declarations TABLE (...);
  INSERT @declarations
    SELECT DISTINCT ... FROM model.provider_capability_implementation pi
    JOIN model.capability_version cv ...
    JOIN analysis.v_selected_semantic_definition d ...;
  INSERT @implementations
    SELECT ..., JSON_VALUE(d.definition_json,'$.semantics.projectionTarget'),
                JSON_VALUE(d.definition_json,'$.semantics.status'),
                JSON_VALUE(d.definition_json,'$.semantics.implementationRef'),
                JSON_VALUE(d.definition_json,'$.semantics.conformanceRef')
    FROM @declarations d JOIN ... JOIN analysis.v_selected_semantic_definition retained_provider ...;
  RETURN; END;
```

Three properties of a multi-statement TVF, each of which defeats the caller's
predicates:

1. **Opaque to the optimizer.** No predicate pushdown. The outer
   `WHERE estate_model_pk=@m AND target_language='node'` cannot enter the
   function; it runs to completion, then the result is filtered.
2. **Table variables carry no statistics.** The optimizer estimates a fixed low
   row count, which propagates bad plans through everything downstream.
3. It joins `analysis.v_selected_semantic_definition` **twice** and calls
   `JSON_VALUE` over `definition_json` four times per surviving row.

`v_scenario_language_resolution` references it **twice** — once to build the
`targets` CTE, once in the `LEFT JOIN` for `PLATFORM_CAPABILITY` requirements —
so it executes at least twice per invocation, in full, over the estate.

## Sizes

**Measured**:

```text
model.provider_capability_implementation           85 rows
analysis.v_declared_platform_implementation        85 rows materialized per call
analysis.v_selected_semantic_definition         9,139 rows joined through, twice
```

## What the invocation needs from that function

**Inferred** from the code trace above, not yet proven by a replacement query:

- **The `targets` CTE** — `DISTINCT estate_model_pk, target_language`. Six rows.
  With `@target` supplied the real question is a single `EXISTS`: is `node` a
  declared target? `scenario-resolver-map.sql` already performs that check
  separately at the top (`THROW 'TARGET_NOT_DECLARED'`).
- **The `PLATFORM_CAPABILITY` join** — per requirement, is there an `ADMITTED`
  implementation for this platform capability id and target? For
  `resolve-equity-market-price-evidence` that is **two ids**:
  `sda-authority-transformation-port.v1` and `sda-schema-contract-admission.v1`.

Nothing else reaches the planner. The two columns `materialize-node.mjs:115`
reads come from `v_declared_mechanic_resolution` (`nr`), not from this function
(`pi`), because the `pi` join is gated on `requirement_kind='PLATFORM_CAPABILITY'`.
`pi` contributes only to `resolution_status`, which rolls up into the readiness
boolean.

## Ruled out

Two hypotheses were tested and are dead. Recording them so they are not chased
again:

**The six-target cross join is not the cause.** `v_scenario_language_resolution`
cross joins every requirement to all declared targets, and it looked like the
reader was not narrowing it. It already was — **measured**:
`src/invoke-database-capability.mjs:32` builds the selection as
`{ capabilityId, target: 'node', ... }`, and has done so all along. Confirmation:
the resolver `inputDigest` is byte-identical with and without an added `target`
parameter (`sha256:f57f2b3f019649e` both runs), readiness returns **1** row
rather than 6, and timings were 30,440 ms → 31,979 ms, which is noise. A change
adding `target` a second time was written, measured, and reverted;
`git diff --stat src/` is clean.

**`source_lineage` is not in this path.** `scenario-resolver-map.sql` never
references it — **read**. The 518,150-row lineage table (83% of which is
`transformation_expression_node` / `_child`) is walked by
`source.validate_model`'s `G_LINEAGE_MEMBER` gate, which runs at registration,
not at invocation. That is a separate cost with a separate fix.

## The larger question: invocation does not need readiness at all

The readiness gate is [`materialize-node.mjs:24`](../../../src/materialize-node.mjs):

```js
const readiness = one(resolutions.recordsets[1].filter(r => r.target_language === 'node'), 'NODE_READINESS');
if (readiness.readiness !== 'CAN_ATTEMPT_EMBODIMENT') throw new Error('NODE_BINDINGS_HELD');
```

It is a pre-flight check, and it is the reason the whole resolution matrix must
be computed. Recordset 1 is an **aggregate over the full requirement set** —
producing it requires resolving every requirement for the scenario. That is the
expensive work, and it exists to answer a question the planner answers anyway by
failing a few lines later.

`planNode` already fails specifically when a binding is missing, and with a
better message than the gate provides:

| Path | Error |
| --- | --- |
| readiness gate | `NODE_BINDINGS_HELD` — names nothing |
| planner, unresolved port | `PORT_IMPLEMENTATION_NOT_RESOLVED:<portId>` |
| planner, no native provider | `NATIVE_MECHANIC_PROVIDER` assertion |

Removing the gate does not weaken the failure. It sharpens it, and removes the
only consumer that requires the aggregate.

**What invocation still needs after dropping readiness:**

1. The single `(implementation_id, implementation_export)` pair for node —
   available from `analysis.v_declared_mechanic_resolution` directly, without the
   per-requirement matrix. `pi` never supplies these columns; `nr` does.
2. The 4-row downstream closure — already a direct query against
   `v_scenario_invocation_closure` that bypasses the resolution chain entirely.

Neither needs `v_scenario_language_resolution`.

**Consequence to accept deliberately.** `materialize-node.mjs:211` writes
`evidence/target-readiness.json` into every planned body from recordset 1 — ten
such files are committed, each carrying all six targets. Dropping readiness from
the invocation path changes or removes that evidence for bodies planned that way.
`scripts/verify-memory-parity.mjs:16` filters to `/body/` and does **not** compare
`/evidence/`, so the memory/disk parity check is unaffected — **verified by
reading**, not assumed.

Readiness remains worth having as a **diagnostic**, not a runtime gate: it is what
reported `CAN_ATTEMPT_EMBODIMENT, 187 requirements, 0 open` after registration,
and cross-target readiness is genuinely informative. It belongs behind an explicit
command or the optional `prepare` path, where paying 30 seconds is a deliberate
choice, rather than on every invocation.

## Proposed fix

In preference order, cheapest and most certain first.

**1. Drop readiness from the invocation path.** Remove the gate at
`materialize-node.mjs:24`, source the native mechanic binding from
`v_declared_mechanic_resolution`, and keep the closure query as it already is.
`scenario-resolver-map.sql` then leaves the invocation path entirely. This does
not depend on diagnosing the plan, because it removes the query rather than
optimising it — and the failure messages improve. Readiness moves behind an
explicit diagnostic command.

**2. Convert `analysis.declared_platform_implementations()` to an inline TVF**
(`RETURNS TABLE AS RETURN SELECT ...`). Inline TVFs are expanded into the calling
query, so predicates push down and the optimizer sees real cardinality. The body
is already a single logical `SELECT`; the `@declarations` step is a CTE. One
function rewritten, no schema change, no caller change, no change to returned
columns. This matters for `validate_model`, registration and any diagnostic that
still needs the matrix — so it is worth doing even if (1) lands.

**3. If the matrix is still needed anywhere hot**: hoist the `targets` CTE to an
`EXISTS` when `@target` is supplied, and index the recursive join column under
`v_scenario_invocation_closure`.

(1) and (2) are independent. (1) fixes invocation; (2) fixes everything else that
touches the chain.

## Not established

- **That the MSTVF is where the 30 seconds goes.** The mechanism and the row
  counts are established; the attribution is not. The per-layer timings in
  [`investigate.sql`](investigate.sql) blocks 1 and 3 are what would confirm it.
- **Whether `v_scenario_invocation_closure` contributes materially.** `@target`
  does not touch the recursion at all, so it is untested.
- **Why `06-language-resolution-all-targets.sql` does not complete** rather than
  merely running slowly. Consistent with the MSTVF being re-executed per target
  without pushdown, but not demonstrated.
- **Whether an inline rewrite is semantically identical.** The multi-statement
  form materializes `@declarations` before the second insert; an inline form
  evaluates lazily. Both should produce the same rows for this body, but that
  needs a row-for-row comparison against the current function before adoption.
