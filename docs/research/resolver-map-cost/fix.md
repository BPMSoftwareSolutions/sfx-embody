# Fix: take `scenario-resolver-map.sql` off the invocation path

Proposal: 2026-09-09. Status: **implemented and accepted, 2026-09-09.**
Measured end-to-end result and the acceptance run are in
[Result — measured](#result--measured) and [Acceptance](#acceptance) below.
Evidence for every claim is in [findings.md](findings.md); the measurements that
justify this specific change are repeated inline below.

## Scope

**In scope.** Removing `scenario-resolver-map.sql` from
`sfx capability invoke`. Three consumer sites in `src/materialize-node.mjs` and
one call in `src/read-authority.mjs`.

**Out of scope.** Optimising `v_scenario_language_resolution`,
`v_scenario_embodiment_requirement`, or `analysis.declared_platform_implementations()`.
Those remain slow and still matter for `validate_model`, registration and
diagnostics — separate work, separate record.

## Where the 30 seconds goes — measured, layer by layer

Each layer timed in isolation against the same scenario
(`resolve-equity-market-price-evidence`, estate model 14). Queries are in
[hypotheses/](hypotheses/).

| # | Layer | Rows | Time | Verdict |
| --- | --- | ---: | ---: | --- |
| H1 | `v_scenario_invocation_closure` + scenario joins (recordset 2 verbatim) | 4 | **1 ms** | free |
| H2 | `v_declared_mechanic_resolution`, node only | 224 | **701 ms** | cheap |
| H3 | `v_scenario_embodiment_requirement`, scoped to one scenario | 187 | **28,755 ms** | **the cost** |
| — | full `scenario-resolver-map.sql` (invocation) | 187/1/4 | 30,440 ms | H3 + overhead |
| — | candidate without the platform-implementation join | 1 | 30,325 ms | unchanged — confirms H3 |
| — | `COUNT(*)` over `v_declared_platform_implementation` | 85 | instant | not the cause |

**94% of the query is one view.** Not the recursion (1 ms), not the mechanic
resolution (701 ms), not the multi-statement TVF an earlier draft of this
investigation blamed.

### Why that view costs 28.7 s to return 187 rows

`analysis.v_scenario_embodiment_requirement` has **no predicate of its own**:

```sql
CREATE OR ALTER VIEW analysis.v_scenario_embodiment_requirement AS
SELECT ...
FROM source.current_model cm
JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
CROSS APPLY analysis.scenario_embodiment_requirements(ec.capability_version_pk, cs.scenario_version_pk) r;
```

It `CROSS APPLY`s a table function across **every (capability, scenario) pair in
the estate** — 220 capabilities, 3,768 scenario versions — and the caller's
`WHERE capability_version_pk = @cv AND selected_scenario_version_pk = @sv`
filters *afterwards*.

`analysis.scenario_embodiment_requirements()` is a **multi-statement** TVF
(`RETURNS @requirements TABLE (...)`), so it is opaque: the predicate cannot be
pushed into the `CROSS APPLY`, and SQL Server must evaluate all ~3,768
applications to answer a question about one scenario. 28,755 ms / 3,768 ≈ 7.6 ms
per invocation, which is entirely consistent.

**Six query variants do not complete at all** (split queries 06–10, 12) — the
same view without a scenario predicate. Contention was ruled out by measurement:
zero application locks on `sidefx:model-write`, no session with a
`blocking_session_id`.

A path costing 28.7 s to filter its own output, and hanging outright in six
variants, is not made safe by tuning. The change below removes the dependency.
Fixing the view is worthwhile for the paths that keep it — see
[findings.md](findings.md) — but it is not a prerequisite here.

## The change

### 1. The native mechanic binding is already in the bundle

`materialize-node.mjs:115` spends the 30 s to obtain one pair:

```text
implementation_id     languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs
implementation_export evaluateExpression
```

The same pair is already present in `node-mechanic-registry.authority.v1.json`,
a `PINNED_PLATFORM_AUTHORITY` document that `capability-embodiment.sql` returns
in 1.2 s as part of the same bundle — **verified by reading it out of the live
bundle**:

```text
providerModuleRoot   languages/typescript/runtimes/node
eventPorts           31   (transformation ports: 1)
  sda-authority-transformation-port.v1 -> semantic-transformation-evaluator.mjs / evaluateExpression
```

`path.posix.join(providerModuleRoot, providerModule)` reproduces
`implementation_id` exactly, and `providerExport` is `implementation_export`.

So replace the derivation at `:115`:

```js
// before -- requires resolutions.recordsets[0], 30 s
const nativeBindings = [...new Map(requirements.filter(r => r.requirement_kind === 'MECHANIC')
  .map(r => [r.implementation_id + ':' + r.implementation_export, r])).values()];
const native = one(nativeBindings, 'NATIVE_MECHANIC_PROVIDER');

// after -- from the registry document already in the bundle
const transformationPort = one(registry.value.eventPorts.filter(p => p.invocation === 'transformation'),
  'NATIVE_MECHANIC_PROVIDER');
const native = {
  implementation_id: path.posix.join(registry.value.providerModuleRoot, transformationPort.providerModule),
  implementation_export: transformationPort.providerExport
};
```

`one(...)` is retained, so a registry declaring zero or several transformation
ports still fails loudly rather than picking one.

### 2. Drop the readiness gate

`materialize-node.mjs:24`:

```js
const readiness = one(resolutions.recordsets[1].filter(r => r.target_language === 'node'), 'NODE_READINESS');
if (readiness.readiness !== 'CAN_ATTEMPT_EMBODIMENT') throw new Error('NODE_BINDINGS_HELD');
```

Recordset 1 is an aggregate over the entire requirement set — producing it *is*
the expensive work. It pre-answers a question the planner answers a few lines
later, and worse:

| Path | Error |
| --- | --- |
| readiness gate | `NODE_BINDINGS_HELD` — names nothing |
| planner, unresolved port | `PORT_IMPLEMENTATION_NOT_RESOLVED:<portId>` |
| planner, no native provider | `NATIVE_MECHANIC_PROVIDER` assertion |

Removing the gate sharpens the failure rather than weakening it.

### 3. Replace recordset 2 with its own query

`materialize-node.mjs:92` uses `resolutions.recordsets[2]` — the 4-row downstream
closure. That recordset is already produced by a self-contained statement at the
end of `scenario-resolver-map.sql` (lines 60–70) which queries
`v_scenario_invocation_closure` joined to the scenario tables and **does not
touch the resolution chain**. Lift it verbatim into
`sql/diagnostics/scenario-closure.sql` and call that instead.

**Measured at 1 ms** returning the correct 4 rows
([h1-closure.sql](hypotheses/h1-closure.sql)). The closure recursion is not
implicated; this step is effectively free.

### 4. Stop calling the resolver map on the invoke path

`src/read-authority.mjs` issues the query unconditionally. Make it conditional so
that `invoke` reads authority + closure + mechanics, while `prepare`,
`verify-estate` and the CLI diagnostic keep the full resolver map.

## What is given up, deliberately

**The cross-check between the pinned registry and the database.** Today
`materialize-node.mjs:121` filters the registry's event ports by the
database-derived `native` pair — an independent confirmation that the pinned
platform document and the database's resolution agree. Sourcing `native` from
the registry makes that comparison a tautology.

That check has value. It does not have 30-seconds-per-invocation value. It
belongs in `prepare` or `verify:estate`, which already read the full resolver map.

**Done, not deferred.** `planNode` now performs the original resolver-map
derivation and compares it to the registry-derived pair whenever the requirement
matrix is present, failing with `NATIVE_MECHANIC_PROVIDER_DIVERGENCE`. Putting it
in the planner rather than in each caller means `prepare`, `verify:estate` and the
probe all get it without duplication, and the invoke path skips it because it has
no matrix to compare against.

The check is demonstrably live rather than vacuous: a first version omitted the
`target_language === 'node'` scope and `verify:estate` failed immediately on
`adapt-job-market-intelligence-evidence` with `NATIVE_MECHANIC_PROVIDER:4` — four
distinct pairs across the six target languages. Scoped to node it passes on all
three regression capabilities, which is the agreement being asserted.

**Cross-target readiness in generated evidence.** `materialize-node.mjs:211`
writes `evidence/target-readiness.json` from recordset 1; ten such files are
committed, each carrying all six targets. Bodies planned on the invoke path would
no longer carry it. `scripts/verify-memory-parity.mjs:16` filters to `/body/` and
does **not** compare `/evidence/` — **verified by reading** — so memory/disk
parity is unaffected. Bodies written by `verify-estate` and the probe are
unaffected because those paths keep the resolver map.

**Readiness as a diagnostic.** Still worth having — it is what reported
`CAN_ATTEMPT_EMBODIMENT, 187 requirements, 0 open` after registration. It moves
behind an explicit command where paying 30 s is a choice.

## Result — measured

Both runs are `sfx capability invoke resolve-sidefx-eligible-providers --input
'@examples/provider-resolution.request.json' --json`, same machine, same estate
model, taken from the invocation's own `evidence.timings`.

| Query | Before | After (run 1) | After (run 2) |
| --- | ---: | ---: | ---: |
| `capability-embodiment.sql` | 1,268 ms | 1,301 ms | 1,311 ms |
| `scenario-resolver-map.sql` | 31,215 ms | **not read** | **not read** |
| `scenario-closure.sql` | — | 980 ms | 996 ms |
| `mechanic-definitions.sql` | 1,172 ms | 1,087 ms | 1,144 ms |
| **`processTotal`** | **35,048 ms** | **4,875 ms** | **5,224 ms** |

**6.7×–7.2× faster, about 30 s removed.** Two runs are shown because they
straddle the 5 s figure criterion 4 was written against — see the note there.
Reporting only the 4,875 ms run would misstate the range.

The projection above said ≈3,745 ms and 9.1×. The measurement is roughly 1.1–1.5 s
slower, because the projection treated the closure as free at its isolated 1 ms;
issued as its own round trip inside the invocation it costs ~990 ms, which is
round-trip and plan overhead rather than the recursion. The projection was
optimistic; the direction and the order of magnitude held.

Remaining cost is three queries at roughly 1 s each. None of it is the resolver
map, and this change does not address it.

## Acceptance

Not "invoke got faster". Specifically — all six **run and passing**:

1. **Pass, with the criterion corrected.** The invocation returns exit 0 and
   terminates with the `PROVIDERS_RESOLVED` outcome.

   As originally written this criterion was **unachievable, and wrong** — it asked
   for a `resultDigest` identical to a pre-change run, but `resultDigest` digests
   a `result` containing `executionId`, which `invoke-database-capability.mjs`
   sets from `randomUUID()` on every call. Two *unchanged* runs would not match
   either. The digests are in fact different
   (`sha256:9be8…6341e4` before, `sha256:402f…5fbe5e871` after).

   What was actually verified is the intended guarantee: with the per-run
   execution UUIDs and clock timestamps normalised, the two `result` payloads are
   **byte-identical** — same normalised digest `4a940b0d1307803be6e80acde19a71d8`.
   The capability is unaffected, not merely working.
2. **Pass.** `npm test` — 8/8. `npm run verify:estate` — `PASSED`, 17 fixtures,
   10 scenario bodies, 994 native expression nodes, 5 negative checks.
3. **Pass.** `npm run verify:memory` — 17/17 fixtures across three capabilities,
   `identicalBodyFiles` on every case, `invalidInputParity: true`. `git status`
   reports **no change under `embodiments/`**: no body file moved.
4. **Pass on the substantive half; the 5 s threshold is a coin flip.**
   `evidence.timings.queries` contains exactly `capability-embodiment.sql`,
   `scenario-closure.sql` and `mechanic-definitions.sql` —
   `scenario-resolver-map.sql` **absent**, which is what this change is for and is
   unambiguous. `processTotal` measured 4,875 ms and 5,224 ms on two runs: one
   under the threshold, one over. The threshold was picked before any end-to-end
   number existed and lands inside the run-to-run noise of three ~1 s round trips.
   The honest statement is ~5 s, not "under 5 s".
5. **Pass.** A port made genuinely unresolvable (the transformation authority
   reference removed from the retained interfaces bytes and the record
   re-digested, resolver map dropped to reproduce the invoke path) fails with
   `PORT_IMPLEMENTATION_NOT_RESOLVED:resolve-sidefx-eligible-providers-port` —
   naming the port, and not `NODE_BINDINGS_HELD`.
6. ~~The closure query timed in isolation.~~ **Done — 1 ms** isolated, 980 ms as
   an in-invocation round trip. Not a risk.

## Open

- **No execution plan has been captured.** The attribution to
  `v_scenario_embodiment_requirement` rests on isolated timings (H3 = 28,755 ms
  against H1 = 1 ms and H2 = 701 ms) and on reading the view's `CROSS APPLY` over
  every capability/scenario pair. The arithmetic fits — 28,755 ms / 3,768 pairs ≈
  7.6 ms per application — but a plan would confirm rather than infer it. This fix
  does not depend on the answer; fixing the view for the paths that keep it does.
- **Whether any other consumer reads the resolver map** beyond the three sites
  named here. `grep` found no others across `src/` and `scripts/`, but that was
  not exhaustively verified.
- ~~**The registry cross-check moves rather than disappears.**~~ **Closed** — it
  is in `planNode`, guarded on the matrix being present, and proven live. See
  [What is given up](#what-is-given-up-deliberately).
- **The closure now costs ~990 ms as its own round trip** against 1 ms measured in
  isolation. That is a third of the remaining invocation time and was not
  anticipated. Folding the closure into `capability-embodiment.sql` as an extra
  result set would likely remove it, since it needs the same capability and
  scenario resolution that query already performs. Not attempted here.
