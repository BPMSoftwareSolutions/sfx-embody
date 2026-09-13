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
  closure by owning capability; the body renderer surfaces a composed child's
  governed stop (see Decisions).

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
closure) and **executes observe's kernel** — confirming the mechanism. observe's
root rejects the equity endpoint authority (a legitimate domain verdict for
observe), and the composer now surfaces that governed stop:

- the preflight `DISPOSITION` is `rejected`, and the returned execution is
  observe's (`executionId …/3/observe-governed-http-exchange`, `disposition:
  rejected`), not a failure.

So observe is a valid *governed-stop* child of equity; it is not a *successful*
child for equity's endpoint. A capability whose normal path can reject is now
composable without collapsing its verdict into a failure.

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
2. **A child's governed stop is surfaced (implemented).** The declared
   composition authority separates governed stops from failure
   (`execute-declared-scenario-composition.authority.json`:
   *execution-stops-at-the-first-non-success*, *composition-does-not-claim-acceptance*;
   governedStops include `OUTCOME_REJECTED`/`EVENT_FAILED`). The generated
   `invoke`/`execute` (`consumer-object-provider.mjs`) now stop at the first
   non-success and return the child's execution, so the composer's disposition is
   the child's (`rejected`/`failed`) instead of a generic failure. Observed:
   equity composing observe preflights to `DISPOSITION rejected`.
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

## Decisions (rubric-grounded)

**A — child non-success semantics: implemented.** Authority is the admitted
composition policy and its governed stops (§3); omission blocked composing any
capability whose path can reject (§4, observed with observe). Smallest form: the
body renderer stops at the first non-success and surfaces the child's
disposition/outcome; no model or public-contract change; reversible. Note the
kernel maps an executor throw to `failed` and does not itself express a governed
stop; the renderer carries it in the composition context and returns the child's
execution. If a future language kernel is to compose, that stop must be declared
data, not re-derived per language.

**B — adapter composition: deferred, with a trigger.** It is not required by the
current loop (`bounded-execution-closure.md`; §4/§9 — none of the six observable
events change), and the composition proof is drop-in. An adapter *capability* does
not solve it either: the linear state replaces the whole state at an invocation,
so caller context cannot be preserved. Only a declared input/merge mapping on the
invocation operation can; that is a durable model commitment (§5, medium
reversibility), so per §8 (`REUSE_EXISTING → COMPOSE_EXISTING → AUTHOR_PROFILE →
AUTHOR_NEW`) the smallest move now is to try redesigning the caller so the
invocation point is drop-in. **Revisit trigger:** a concrete second case that
cannot be redesigned to drop-in, or a measured repetition saving that beats the
model burden.
