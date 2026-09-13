# Handoff to the SDA team â€” Capability invocation as the composition mechanism

Status: **work item, not yet implemented.** This document is the authoritative
brief for the platform-runtime change. It supersedes the earlier research note
`docs/research/capability-invocation-mechanism.md`.

## 1. The ask, in one sentence

Teach the runtime that a capability may **compose another capability** â€” resolve a
declared target capability, load its already language-resolved body, and execute
it â€” so that `observe-governed-http-exchange` (and every other domain concern) is
used **as a capability**, not re-bound as a Node-only platform port.

## 2. Why this is the right change (and the evidence)

The platform was intended to be honest: **language kernels resolve language; all
else comes from data.** Today that is not true.

- 8 languages exist: `cpp, csharp, go, java, kotlin, python, swift, typescript`.
- Platform-mechanic providers exist **only** in TypeScript/Node
  (`languages/typescript/runtimes/node/node-mechanic-registry-loader.mjs` plus its
  provider modules). `csharp-mechanic-registry.authority.v1.json` and
  `python-mechanic-registry.authority.v1.json` declare **0 eventPorts**; the other
  six languages have **0** provider implementations.
- The node registry declares **31 eventPorts** across invocation kinds
  (`transformation`, `effects`, `configuration`, `url-context`, `serial`, `llm`).
  The estate planner (`consumer-object-provider.mjs`) executes only
  `transformation` and `effects`.
- Composition currently rides on `sda-projected-capability-invocation-port.v2`, a
  platform port whose registry entry is `invocation: configuration` and declares
  **no provider module** â€” so nothing executes it.

Consequence: capabilities that delegate to another capability are silently
Node-only while claiming portability. The composition concern belongs in the
model as a declared relationship, executed by orchestration, with the target's
behavior remaining data + provider.

## 3. What is already done (database side)

- `observe-governed-http-exchange` is a real capability (10 scenarios); it reveals
  and now invokes through the normal pipeline. Commit `6054168` fixes its input
  contract schema (`sql/migrations/ensure-contract-object-root-schema.sql`) â€” the root
  was a union with no `type: object`.
- The three capabilities that bind `sda-governed-http-exchange-port.v1` directly
  are `observe-governed-http-exchange`, `resolve-equity-market-price-evidence`,
  and `speech-provider`.
- Legacy `manage-capsule-estate` was superseded (`c747778`) as a delegate of
  `operate-capsule-estate`.
- Related commits: `06edc12`, `a6e7c38`, `6a0b61d`, `6fb1993`.

Nothing on the database side is blocked. The remaining work is the runtime
mechanism below.

## 4. The work item

### 4.1 Declaration (database)

An execution authority's operations are `invoke-port` and `invoke-scenario`.
`invoke-scenario` resolves only within the capability's own closure
(`analysis.v_scenario_invocation_closure`). Allow an execution operation to name
a **target capability + scenario** belonging to another capability, with the
input/output mapping expressed by declared contracts.

`model.operation_scenario_invocation` already carries `target_scenario_version_pk`.
The database change is to permit (and expose) a cross-capability target. No new
platform port is introduced.

### 4.2 Runtime

1. `src/materialize-node.mjs`
   - When planning a capability, detect declared operations whose target belongs to
     another capability.
   - Recursively plan the target capability and carry its body modules into the
     current body.
2. `src/resolvers/node/consumer-object-provider.mjs`
   - For a cross-capability `invoke-scenario`, emit a dependency that invokes the
     target capability's scenario class, mapping the declared contracts. Today it
     handles `invoke-port` (transformation/effects); extend the
     `invoke-scenario` path to include cross-capability targets.
3. `sql/diagnostics/scenario-closure.sql` (or a sibling view)
   - Expose the cross-capability target so the planner sees it as a declared edge.

### 4.3 Honesty constraint (must hold)

Capability invocation is **orchestration only**: resolve a declared target, load
its language-resolved body, invoke it. No domain logic (HTTP, bytes, projections,
credentials) enters the kernel. Domain behavior stays in the target capability's
provider.

## 5. Acceptance criteria (the proof)

1. Declare `resolve-equity-market-price-evidence` (and `speech-provider`) as
   composing `observe-governed-http-exchange`, mapping
   `observe-governed-http-exchange-input.v1` / `governed-http-exchange-evidence.v1`.
2. `sfx capability invoke resolve-equity-market-price-evidence --input â€¦` executes
   the exchange **through the `observe-governed-http-exchange` capability**.
3. `sfx capability reveal` on both shows the declared composition edge.
4. The Node runtime carries no HTTP logic; the composition resolves identically
   when a non-Node language is the selected target (module loading is language
   resolution).

## 6. How to verify today

- `sfx capability reveal observe-governed-http-exchange` â€” story/promise/contracts.
- `sfx capability invoke observe-governed-http-exchange --input @file.json` â€”
  executes to a domain disposition (e.g. `rejected` for an unauthorized endpoint),
  proving the pipeline runs the capability.

## 7. Rubric basis

- Â§3 authority: builder intent â€” kernels resolve language only.
- Â§4 necessary now: composition is required to run these capabilities honestly.
- Â§8 semantic identity: capability invocation is a declared relationship, not a
  platform port.
- Â§5/Â§9: contribution 3, evidence 2 (observed Node-only). Under the current state
  the SQLâ†’CLI flywheel only works on Node.

## 8. Notes / risks

- This is the one legitimate exception to "durable SQL only": composition is a
  platform-runtime concern and cannot be expressed as data until the mechanism
  exists.
- The `effects` invocation kind is already the honest shape (load the declared
  provider module and invoke it); the `configuration`/`url-context`/`serial`/`llm`
  kinds are the ones the Node loader special-cases and the planner omits. After
  capability invocation lands, review those 29 ports (inventory in
  `docs/research/platform-mechanic-honesty.md`) for migration to capabilities.

