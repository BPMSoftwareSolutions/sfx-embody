# The circuit-view flywheel

**Status.** Named 2026-09-17. Authority: [transistor-model.md](transistor-model.md)
(declared authority vs resolver), [display-projection-decision-record.md](display-projection-decision-record.md)
(the display is 1), [invisible-execution-authority.md](invisible-execution-authority.md)
(the time test), [target-harness-experience.md](target-harness-experience.md) §"The
cleanest sketch" (the instance this flywheel generalizes). Implementation:
[implementation-plan-circuit-view.md](implementation-plan-circuit-view.md).

## The insight

The ASCII sketch is not documentation of the architecture; it **is** the
declared execution graph rendered. Every box is a cell, every arrow an edge:

| Sketch component | Declared graph element |
|---|---|
| SIDEFX HARNESS / ENTRY | root scenario cell |
| GOVERNED MODEL INVOCATION CAPABILITY, CAPABILITY EXECUTION | `invoke-scenario` child scenario cells |
| resolve requested capability, routing | mechanic cells (declared read, decision transformation) |
| MODEL PROVIDER, PHYSICAL / API PROVIDER | provider-altitude cells |
| EXECUTABLE PATH / NO PATH | `selection` edges (routing transitions with `selectsVariant`) |
| EFFECT → EVIDENCE | the exchange evidence and the terminal outcome payload |
| labels and durations | declared identities (`scenarioId`, `portId`, responsibility ids) and testimony |

So the sketch needs no authored per-capability document: one **generic view**
over the graph source (planned topology) joined with testimony (observed
path) — the same join the drilldown overlay already performs — produces the
view for **every** capability in the estate.

## The flywheel hypothesis

**If the circuit view is one generic declared projection, then every declared
capability is born inspectable, and the estate's visibility compounds.**

The loop: declare a capability → its graph exists → the circuit view lights
live as it executes → visible friction (an orphan box, an unlit branch, a
provider identity change, a time hole) → the fix lands in **rows** → the next
capability inherits the corrected shape and the same view. The output of the
loop is better declarations, cheaper verification, and reusable demo and
attestation material.

Why it compounds:

1. **Zero marginal cost per capability.** Boxes, arrows, labels and lighting
   are all derived; nothing is authored per capability. Declaring a capability
   grants its view automatically.
2. **The picture cannot drift.** The view and the execution read the same
   rows. It is not documentation that rots; it is declared authority rendered.
3. **It is half of an attestation pair.** Structure (this view: which cells
   exist, which ran, which branch was selected) plus time
   ([invisible-execution-authority.md](invisible-execution-authority.md): every
   gap closes against a declared cell) attests what ran and that nothing else
   did — generically, for every capability, in every language.
4. **One maintainer, N beneficiaries.** The cost concentrates in a single
   generic view model (and the terminal's reduction to transport); the benefit
   distributes to declarers, reviewers, the recording, clients, and any future
   front end — same view model, different emitter.
5. **It rides the proven flywheels.** The authoring flywheel
   ([flywheel-proof.md](flywheel-proof.md)) gets a visible artifact per
   declaration; the projection/install flywheel
   ([projected-csharp-install.md](projected-csharp-install.md)) gets an
   inspectable runtime; the IEA acceptance gets its structural counterpart.

## What makes it generic

- **View model, not layout gospel.** A declared reading emits nodes
  `{cellId, kind, altitude, label, parentId, status, durationMilliseconds}` and
  edges `{edgeId, kind, from, to, selected, selectsVariant}` from the declared
  graph plus the invocation's testimony. Layout (boxes, arrows, positions) is
  the emitter's generic vocabulary, never per-capability.
- **Presentation granularity is a rule, not a choice per capability.** The
  view collapses expression-level cells to semantic components (scenarios,
  responsibilities, provider/physical cells, the terminal outcome); detail
  stays available through `--trace`. The target sketch is that collapse
  applied to the agent lane.
- **Three honest states.** Planned-unobserved (box unlit), observed (box lit
  with disposition and duration), failed (box marked by classification). An
  undeclared effect has no box at all — which the gap test then catches in
  time.
- **Both branches are rendered.** The selected `selection` edge lights; the
  unselected branch renders as the no-path marker. Nothing is hidden by
  omission.

## Measurement plan (rubric §1, three observations)

Baseline: today the nearest views are the story render and `--trace` (manual
reading, no topology), and the target doc's static sketch (authored per
capability).

1. **Time to first live circuit** for the agent lane: T0 (authoring starts) →
   T1 (first circuit renders from the declared view, fixtures) → T2 (live
   invocation with both branches shown), with timestamps and review overhead.
2. **Executions out of attempts and coverage**: capabilities with a live
   circuit out of capabilities declared; principal failure reasons. Repeated
   test runs are not adoption.
3. **Effort for the next comparable example**: adding a second capability's
   live circuit. Expected ≈0 — record the exact reuse and any new maintenance.
   If the second capability costs non-trivial work, the generic claim is
   falsified and the record must say so.

Do not invent targets before the baseline exists; unknown values stay unknown.

### First-turn observations (2026-09-17)

Four lanes ran in one orchestration turn (doc repair; view-model capability;
CLI format; structural acceptance). Precise per-lane wall times were not
captured — recorded as unobserved.

| Observation | Result |
|---|---|
| Time to first live circuit | Not time-stamped. Outcome: the view-model capability was authored, dry-run, preflighted, installed and verified within its lane; the real CLI rendered the first circuit on the first run after the one reader gate landed |
| Coverage | The generic renderer rendered live circuits for **two capabilities** (equity and the agent lane, both branches lit/unlit correctly) with **zero per-capability code**. The structural verdict covered four capabilities (agent lane 985 planned / 703 observed, 0 on-taken-path misses; equity 242/180; compose 244/182; model lane 654/451) — but it was produced by a temporary script, since removed as UID; the rule is re-specified as a declared attestation and those counts stand as its expected values |
| Marginal effort, next instance | The renderer's second capability cost ≈0. The declared streamed fragments (CV-B) and the true ~11-component collapse (CV-A2 refinement) remain staged, so the *declared-bytes* half of the generic claim is unverified |

After the first-turn defects were corrected (same day): the circuit streams in
real time, box by box, and replaces the trace; the structural verdict moved
out of a script (removed as UID, `7965689`) into the declared read's
`attestation` (`b9d4499`) — live positives equal the recorded first-turn
values, and negative fixtures return `structured: false` with the removed cell
named.

Honest limitations recorded by the lanes: the view model is per-cell, not the
sketch's 11-component collapse; provider nodes carry no incoming edge because
testimony records none; the large-graph collapse limit is a terminal constant,
not declared authority; `render.mjs` still owns presentation vocabulary until
CV-B/CV-C2 land; unselected branches are only knowable from the final overlay
(an honest closing-frame fact); the declared miss rule cannot name a
non-fragment leaf without the `parentCellId` chain; and equity's overlay has no
semantic-level selection edges, so its closing frame is evidence-only.

## Honest boundaries

- **Layout expression.** Box positioning/arrows are not expressible in the
  current transformation vocabulary. Phase 1 renders from the declared view
  model with one generic emitter; phase 2 moves per-component text fragments
  into declared entries (byte transport). Until a declared layout vocabulary
  exists, the emitter is resolver code — generic, capability-independent, and
  named as such.
- **The terminal's final form is transport.** The target is no presentation
  vocabulary in code: declared fragments streamed verbatim. `render.mjs`
  retires; process, flushing and `--json` pass-through remain.
- **Per invocation, not persisted.** The view describes one execution; a
  durable history is the separate session/ledger unit.
- **Structural coverage is not behavioral proof.** A lit box says the declared
  cell ran and what it reported; it does not by itself prove the external
  effect — provider testimony and the outcome contract carry that, as the
  rubric's evidence table requires.
