# Capability composition across the invocation closure

Goal: a capability composes another capability by declared rows, with no platform
port and no kernel change.

## Mechanism

- `model.operation_scenario_invocation` may target a Scenario in any capability of
  the same estate model.
- `analysis.v_scenario_invocation_closure` walks the declared invocation edges
  across capability boundaries and reports each downstream Scenario's owning
  capability.
- `capability-embodiment.sql` ships the referenced capability's feature text in
  the same declaration bundle; the assembled declaration view already aggregates
  the referenced capability's Ports and Transformations over the closure.
- `materialize-node` parses every declared feature in the bundle and maps the
  closure by owning capability; the body renderer is unchanged.

## What works

`compose-resolve-equity-market-price-evidence` (a declared capability whose root
authority is one `invoke-scenario → resolve-equity-market-price-evidence`) invokes
the target capability and returns its outcome. Preflighted from the uncommitted
transaction and verified through `sfx capability invoke`:
`EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`, exit 0. The target plan, its Ports and its
Transformations are read and executed under the composing capability's body.

## Drop-in composition

A capability can be composed where the invoking operation's state **equals** the
target's input contract and the target's outcome contract **equals** what the next
operation expects. `resolve-equity-market-price-evidence` is a drop-in for
`observe-governed-http-exchange`: `build-equity-price-exchange-request` produces
`observe-governed-http-exchange-input.v1`, and observe's outcome
`governed-http-exchange-evidence.v1` is what `normalize-equity-price-evidence`
consumes. The experiment
`compose-equity-observe-exchange.experiment.sql` declares exactly that substitution.

Preflighted uncommitted, it plans 11 closure Scenarios (the target's whole
closure) and **executes observe's kernel** — confirming the mechanism. It does not
terminate as a domain success:

1. observe's root rejects the equity endpoint authority (`rejected`), which is a
   legitimate domain verdict for observe; and
2. the generated parent `invoke` throws `CHILD_SCENARIO_REJECTED` on a child
   `rejected` disposition, so the composing capability fails instead of
   inheriting the child's verdict.

So observe is not a viable composition *child* for equity's endpoint, and a
capability whose normal path can reject cannot currently be composed at all.

## Adapter composition (speech)

`speech-provider`'s HTTP step is not a drop-in. Its state at the effect ordinal is
the credential-evidence carrier (`external-credential-binding-evidence.v1`) with
`payload.boundHttpRequest` and `payload.credentialEvidence`, and its downstream
`normalize` reads both `payload.credentialEvidence` and `payload.httpEvidence`.
Composing observe requires: extract `payload.boundHttpRequest` as the child input,
invoke, then merge the child's evidence back into the carrier while preserving
`credentialEvidence`.

The linear operation state cannot express that. `invoke-scenario` passes the whole
state to the child and replaces it with the child's outcome; the child's contract is
strict (`additionalProperties: false`), so the caller carrier cannot ride along. A
transformation before the invoke loses `credentialEvidence`; there is no operation
that addresses a sub-state around a child invocation.

## Findings

1. **Drop-in composition works** and is the supported form.
2. **A child rejection is a hard failure.** The generated `invoke` treats
   `rejected` like `failed`, so any capability that can reject cannot be composed
   as a successful child. The semantics of a composed child's non-success need a
   decision (propagate the verdict vs. fail the parent).
3. **Context-preserving (adapter) composition is not expressible** with
   `invoke-scenario` alone. It needs either an adapter capability whose root
   is a drop-in for the caller's ordinal, or an operation-level mapping that
   slices the caller carrier around a child invocation. Either is data; neither is
   a platform port.
4. **The authoring surface assumed a nullable `capability.feature_pk`.** Once the
   feature-direction migration made it NOT NULL, `model.scaffold_capability`
   failed: it inserted the capability before the feature and cleared `feature_pk`
   during REPLACE. Both are fixed in `sql/schema/authoring-procedures.sql` (create
   the feature first; never null the column; delete the feature after the
   capability). A capability-creating migration is then re-runnable.

## Next steps

- Decide finding 2: should a child's `rejected` surface as the parent's
  disposition (the kernel already has dispositions) rather than throw?
- For speech, express the adapter as a declared capability (its own input/output
  contracts) so the caller invokes a drop-in, or extend the operation model with a
  declared carrier mapping around an invocation.
