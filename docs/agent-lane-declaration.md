# Transitioning the agent lane from driver code to a declared capability

**Status.** Analysis 2026-09-17. `src/agent-delivery.mjs` is UID (ungoverned
intelligence debt): the composition meaning — prompt, proposal schema,
resolution, execution choice, refusal, receipt — lives in boot code. It must
become a declared (1) capability. This record states what already supports the
transition, the one missing declared mechanism, the target row design, and the
interim honest option.

## 1. What the script does today (the meaning to declare)

1. Build a `governed-model-invocation-request.v1` from `{objective}`: system
   prompt, visible-capability list, structured proposal schema
   `{capability, input}`, provider authority/model alias, policies.
2. Invoke the **declared** capability `obtain-governed-model-response` and read
   the proposal from `normalizedResponse.structuredValue`.
3. Resolve the proposed capability against the declared estate (`find`).
4. If declared, invoke it with the proposal input; else refuse by absence.
5. Shape the agent receipt (lanes, receipt) from the two real outcomes.

Steps 1, 3, 4 and 5 are meaning; only step 2 and the transport are declared.

## 2. What already supports the declared form (verified live)

- **Cross-capability composition is installed.** `obtain-governed-model-response`
  itself is composed: its root authority is four `invoke-scenario` operations,
  and it executes live. The authoring template is
  `compose-resolve-equity-market-price-evidence.sql`:
  `model.scaffold_capability` → mint the authority envelope with
  `invoke-scenario` operations → `operation_scenario_invocation` rows →
  re-point faces to the invoked capability's contracts.
- **The transformation vocabulary covers the builders and shapers.** The
  model-side transforms (`initialize-model-provider-conveyor`,
  `stage-os-credential-bind-request`) show request-building from a small input;
  the equity selection shows `if`/selection shaping. `put_semantic_definition`
  + `transformation_version` + `normalize_transformation_expression` author
  them; the fallback migration (`add-equity-price-fallback-route.sql`) shows
  direct-mint authority authoring for non-`declare_scenario` shapes.
- **A declared read exists for resolution.** Ports bound to
  `sda-embodiment-plan-port.v1` run a declared SQL statement under the reader
  boundary (`read-declared-capability-document` is the proof). A
  `resolve-proposed-capability` port can resolve `{capabilityId, declared}` from
  the running state.
- **The graph compiler supports scenario routing.** `compiler.js` reads
  `sources.transitions` and emits edges with `selectsVariant`
  (`compiler.js:379-401`); a declared transition can route a child scenario's
  outcome variant to another scenario cell.

## 3. The one missing declared mechanism: routes are never emitted

`assemble-capability-graph-source.sql:75` emits `JSON_QUERY(N'[]') AS
transitions` — the estate's graph source carries **no declared routes**. With an
empty transition set the compiled graph is a linear chain: every operation and
every invoked child executes in declared order. There is no model table for
declared routes either (only the *observed* transition tables exist:
`model.observed_semantic_graph_transition`, …).

Consequence for the agent lane: a declared capability **cannot conditionally
skip the execution child**. For the purchase objective, the only declared
executable child (the equity price capability) would still run — with a real
transport — which contradicts the refusal-by-absence claim. The kernel feature
exists; the declared-routing data path does not.

## 4. Target design (rows, once routes are declarable)

Capability `request-capability-from-objective` (new shell, composed):

| # | Operation | Kind | Meaning carried |
|---|---|---|---|
| 1 | build-agent-model-request | invoke-port, transformation | objective → governed model request (prompt, visible set, proposal schema) |
| 2 | obtain-governed-model-response | invoke-scenario (child) | the declared model lane |
| 3 | resolve-proposed-capability | invoke-port, declared read (SQL) | `{proposedCapabilityId, proposalInput, declared}` appended to state |
| 4 | execute-admitted-proposal | invoke-scenario (child) | the declared executable set — initially `resolve-equity-market-price-evidence` |
| 5 | shape-agent-outcome | invoke-port, transformation | agent receipt: model lane, resolution, execution lane or refusal |

Routes (the missing piece):

```text
[obtain-governed-model-response] --PROPOSAL_RECEIVED--> [resolve-proposed-capability]
[resolve-proposed-capability]   --ADMITTED-->  [execute-admitted-proposal]
[resolve-proposed-capability]   --REFUSED-->   [refusal leaf: CAPABILITY_NOT_FOUND, no execution]
```

The refusal leaf is a scenario whose single transformation op shapes the
refusal outcome; it performs no effect and reaches no provider.

Contracts: `agent-objective-request.v1` `{objective}`;
`agent-invocation-evidence.v1` with the lanes, resolution, outcome-or-refusal,
and the receipt (driver-composed note remains until a session ledger exists).

## 5. The enabling unit (estate, not a side channel)

1. **Declare routes.** A new declared-routing document (rows) naming
   `{capability, fromScenario, variant, toScenario, topologyKind}` for a
   capability's graph source. Where it lives is the design decision: a
   capability-scoped semantic definition (like the other authority documents)
   or graph-source columns; it must be read by the assembly view.
2. **Emit them.** Update the graph-source assembly
   (`assemble-capability-graph-source.sql` and the view the loader reads) to
   emit `transitions` from the declaration instead of `[]`; the compiler and
   validator already accept them.
3. **Prove routing with the smallest case**: one capability, two child
   scenarios, one `selectsVariant` route; invoke both branches and show only
   the selected child's testimony.
4. **Then** author `request-capability-from-objective` per §4, preflight both
   objectives (price and purchase), install, verify; delete
   `src/agent-delivery.mjs`, the `agent-memory` delivery, and the `agent`
   mapping operations. The CLI surface may keep `sfx agent invoke` only as a
   thin forwarder to the declared capability — transport, no meaning.

## 6. Interim honest option (until §5 lands)

The demo can run the lane as **two declared invocations** with no driver:

```text
sfx capability invoke obtain-governed-model-response --input @examples/agent/model-invocation-request.json --json
sfx capability invoke resolve-equity-market-price-evidence --input AVGO
```

Every step is declared, the model is a provider inside governance, and the
refusal is stated as "the proposed capability has no declared execution" —
but the composition (reading the proposal and choosing the next invocation) is
the operator's, not the capability's. If the scripted `sfx agent invoke` is kept
for the recording, it must carry the labeled driver-composed receipt until §5
lands; that label is already in the frame.

## 7. Acceptance for the transition

- `sfx capability invoke request-capability-from-objective --input '{"objective":"…"}'`
  returns the same framed facts as the driver for both objectives.
- The purchase objective's testimony shows **no execution child invoked** and
  no provider reached — routing, not a guarded attempt.
- `src/agent-delivery.mjs` and the `agent-memory` delivery are deleted; no
  composition meaning remains in boot code.
- A `transitions`-based capability compiles and runs on node, python and
  csharp projections (routing is declared; every target resolves it).
