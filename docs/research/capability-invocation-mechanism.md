# Capability invocation as the composition mechanism

Fork resolved in favor of option 2: a capability must be able to declare that it
composes another capability, so `observe-governed-http-exchange` (and every other
domain concern) is used as a capability — not re-bound as a platform port.

## Why the current model cannot express it

- An execution authority's operations are `invoke-port` and `invoke-scenario`.
- `invoke-scenario` resolves only inside the capability's own closure
  (`analysis.v_scenario_invocation_closure` roots at the capability).
- The existing cross-capability vehicle, `sda-projected-capability-invocation-port.v2`,
  is a platform port whose registry entry has:
  - `invocation: configuration` (planner executes only `transformation`/`effects`), and
  - **no provider module** — nothing to invoke even if reclassified.

So the composition concern was absorbed by the Node runtime instead of being a
declared, language-portable mechanism.

## The mechanism that keeps the kernel honest

Capability invocation is **orchestration**: resolve a declared target capability,
load its already language-resolved body, and execute it. Orchestration is kernel
scope (like `invoke-scenario` today); the target's behavior stays data + provider.
Implement it as a declared operation and teach the planner to resolve it.

### Declaration (database)

An execution operation names a target capability and scenario, with input/output
mapping by contract. `operation_scenario_invocation` already carries
`target_scenario_version_pk`; add the ability for that target to belong to another
capability (no new platform port).

### Planner (runtime)

1. `src/materialize-node.mjs` — when planning a capability, if a declared operation
   targets another capability, plan that target capability too and carry its body
   modules into the current body.
2. `src/resolvers/node/consumer-object-provider.mjs` — for a cross-capability
   `invoke-scenario`, emit a dependency that invokes the target capability's
   scenario class, mapping the declared contracts.
3. `sql/diagnostics/scenario-closure.sql` (or a sibling view) — expose the
   cross-capability target so the planner sees it as a declared edge.

### Honesty constraint

Capability invocation must be orchestration only: load + invoke a declared target's
body. No domain logic (no HTTP, no bytes, no projections). Those remain in the
target capability's provider.

## Proof

- Declare `resolve-equity-market-price-evidence` (and `speech-provider`) as
  composing `observe-governed-http-exchange`, mapping
  `observe-governed-http-exchange-input.v1` / `governed-http-exchange-evidence.v1`.
- Invoke the consumer and observe the exchange executed by the capability, with the
  kernel carrying no HTTP knowledge.

## Status

A (union-root schema → object schema) is delivered as durable SQL
(`docs/sql/ensure-contract-object-root-schema.sql`, commit `6054168`), and
`observe-governed-http-exchange` invokes through the normal pipeline. B (this
mechanism) is a platform-runtime change and is the open work item.
