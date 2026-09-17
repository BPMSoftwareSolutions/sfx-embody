# Finding: cross-capability composition is not assemblable on the invocation path

**Status.** Found 2026-09-17 while preflighting the declared agent capability
(`sql/migrations/declare-agent-capability.sql`, dry-run green). The declared
capability cannot execute until the graph-source assembly emits the invocation
closure's scenarios as cells. The same latent defect applies to the existing
`compose-resolve-equity-market-price-evidence` (never invoked on the graph
path; projection-only so far).

## Evidence

Preflight receipt:

```text
node --experimental-vm-modules scripts/invoke-from-transaction.mjs \
  sql/migrations/declare-agent-capability.sql request-capability-from-objective <agent-objective-request.v1 input>
INVOKE FAILED: GRAPH_COMPILER_MISSING_INVOKED_SCENARIO: 'resolve-equity-market-price-evidence'.
readPath: { selected: request-capability-from-objective, closureRows: 6 }
```

The compiler builds scenario cells from `sources.scenarios`, which
`analysis.capability_graph_source` emits from this capability's own
`model.capability_scenario` rows:

- `SDA:compiler.js:334-337` — every `invoke-scenario` operation must find a
  `cell:scenario:<targetScenarioId>`; missing ⇒
  `GRAPH_COMPILER_MISSING_INVOKED_SCENARIO`.
- `emit-declared-routing.sql:552-570` — the scenarios subquery is
  `WHERE cs.capability_version_pk = ec.capability_version_pk`: capability-scoped
  only. The closure table is already used for outcome classifications and for
  the execution-authority documents (`capability_execution_declaration`), but
  not for the scenarios array.

Linking the closure scenarios into the capability's own scenario set is
**structurally impossible**: `model.capability_scenario` has a composite
foreign key to `model.scenario` on `(capability_pk, scenario_pk)` — its insert
fails `FK_model_capability_scenario_…` for a scenario owned by another
capability. (Verified by attempting it; the insert conflicted on
`model.scenario`.)

## Consequence

- A capability can invoke only **its own** scenarios (the model capability's
  four-child composition works; the two-child routing proof works).
- `invoke-scenario` across capabilities compiles only if the target's
  scenarios are cells in the consuming graph source. The declaration side
  already carries the closure (authorities, ports, transformations, contracts,
  outcome classifications); the scenarios array is the single gap.
- Until fixed: the declared agent capability and
  `compose-resolve-equity-market-price-evidence` fail at compile; the
  `src/agent-delivery.mjs` driver cannot be retired without breaking the demo
  lane.

## Fix 1 (landed, `emit-composed-closure-scenarios.sql`)

Emit the invocation closure's scenarios in `analysis.capability_graph_source`'s
`scenarios` JSON: union of the capability's own `capability_scenario` rows and
the downstream scenarios from `analysis.v_scenario_invocation_closure`
(same JSON shape: `scenarioId`, `input`, `event`/`executionAuthorityId`,
`outcome`/contract/terminal — all keyed by scenario version and already joined
in the declaration function). The kernel needs no change; the compiler already
admits those scenarios when present.

Proof on install: `hello-world-sql` emits its own 1 scenario (closure extra 0,
bytes unchanged); `compose-resolve-equity-market-price-evidence` emits 2
(its own root + the invoked equity scenario).

## Finding 2 — `root` in a nested scenario is the invocation root, not the scenario input

After fix 1, the declared agent capability
(`sql/migrations/declare-agent-capability.sql`, dry-run green) preflights
through the whole lane: the governed model call, the declared resolution read,
the declared routing, and the equity execution — verified 2026-09-17:

- equity objective → `ADMITTED` → the admitted child executes
  `resolve-equity-market-price-evidence` and real-time1 answers
  (`providerTestimony.providerId = rapidapi/yahoo-finance-real-time1`);
- purchase objective → `REFUSED` → the refusal child shapes
  `CAPABILITY_NOT_FOUND` with the model proposal facts.

But the admitted run's canonical payload is all null while the direct
invocation of the same capability returns AVGO 339.51 at the same moment. The
equity scenario receives the identical input in both runs (first-cell input
digest `sha256:f7fb8e9d…` in both), so the difference is inside the execution:
`build-equity-price-exchange-request` (and `normalize-equity-price-evidence`)
read `root.payload.symbol` / `root.payload.region`. **`root` is the invocation
root** — the objective request when the equity scenario runs as a composed
child, its own input when it runs top-level. The exchange request therefore
carries an empty symbol under composition and the provider answers an empty
quote that resolves with nulls.

### Required declared fix

The composed scenario's input is the token at its first operation. Make the
equity capability composition-safe by carrying what later operations need
through the token, the way the fallback route already carries its canonical
outcome: the first builder copies the scenario input's request fields into
`effectLineage` (the array every credential/exchange evidence echoes), and the
exchange-request builder and normalizer read them from `input.effectLineage`
instead of `root.payload`. Re-declare those transformations (rows), re-verify:
Beat 1 direct invocation unchanged (AVGO 339.51), the agent lane's admitted
branch now carries AVGO into the exchange, the two-child routing proof and the
projection still conform. Alternatively, SDA may define `root` as the executing
scenario's input; that is a kernel semantics decision and would fix the class
of nested capabilities at once.

### Driver retirement

Until one of those lands, `src/agent-delivery.mjs` cannot be deleted without
losing the demo lane; the declared capability is authored and dry-run green,
and the migration's refusal diagnostic stays in place for the final
verification run, to be removed before install.

Acceptance for the declared lane (both fixes):

1. `request-capability-from-objective` preflights both objectives: the equity
   branch executes the equity scenario with the proposal's ticker and returns
   the provider-attributed evidence; the refusal branch shows zero execution
   cells.
2. `compose-resolve-equity-market-price-evidence` invokes and returns the
   equity outcome (its composition proof becomes executable, not just
   projectable).
3. The C# projection of both capabilities still conforms (the declaration
   documents already carry the closure).
4. `src/agent-delivery.mjs`, the `agent-memory` delivery and the `agent`
   command mapping are deleted.
