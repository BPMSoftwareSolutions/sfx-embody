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

## Fix (one place)

Emit the invocation closure's scenarios in `analysis.capability_graph_source`'s
`scenarios` JSON: union of the capability's own `capability_scenario` rows and
the downstream scenarios from `analysis.v_scenario_invocation_closure`
(same JSON shape: `scenarioId`, `input`, `event`/`executionAuthorityId`,
`outcome`/contract/terminal — all keyed by scenario version and already joined
in the declaration function). The kernel needs no change; the compiler already
admits those scenarios when present.

Acceptance:

1. `request-capability-from-objective` preflights both objectives: the equity
   branch executes the equity scenario (its testimony appears; the refusal
   branch shows zero execution cells).
2. `compose-resolve-equity-market-price-evidence` invokes and returns the
   equity outcome (its composition proof becomes executable, not just
   projectable).
3. The C# projection of both capabilities still conforms (the declaration
   documents already carry the closure).
