# Implementation plan — the Capability-Authoring Evaluation Circuit

**Status.** Authored 2026-09-22; revised 2026-09-22 to the deliberative
semantic compiler target. This is research and plan only: nothing is
declared, installed, or filed. No migration, row, contract, capability or SDA
change exists because of this document. The plan proposes; the team disposes
(§9).

**Authority.** The governing target is the deliberative semantic compiler in
`SDA:docs/authoring-altitude-model-stubs-2026-09-21/specialized-cognitive-providers.md`
(read-only): models as specialized cognitive providers around a durable
semantic circuit — models deliberate, the database remembers, the kernel
executes, evidence teaches. Supporting targets:
[capability-authoring-evaluation-circuit.md](capability-authoring-evaluation-circuit.md)
(the closed learning circuit: author → align → review → prove → admit →
capsule → learn → author again) and
[model-evaluation-circuit.md](model-evaluation-circuit.md) (provider
disposition, governance requirement vector, governance elasticity/efficiency).
Grounding authorities:
[architecture-achieved.md](architecture-achieved.md) (what holds),
[transistor-model.md](transistor-model.md) (declared 1 vs resolver 0),
[implementation-plan-capability-demand-flywheel.md](implementation-plan-capability-demand-flywheel.md)
(retrieval repair units CD-C1–CD-C7, adopted here as Wave 1),
[capability-estate-research.md](capability-estate-research.md) (live estate
gaps G1–G4), [sql/README.md](../sql/README.md) (change lifecycle),
[AGENTS.md](../AGENTS.md) (dependency law, rows-only vocabulary).
SDA-side read-only references (agents must not edit that repo):
`SDA:docs/model-at-each-authoring-altitude-2026-09-21/candidate-admit-pipeline.md`
(the write-seam design this plan builds on),
`SDA:docs/compact-altitude-request-plan-2026-09-22.md` and
`SDA:docs/compact-altitude-request-verification-2026-09-22.md` (the compact
request lane now in the working tree).

**Binding constraints.**

1. `sfx-embody` depends on nothing ([AGENTS.md](../AGENTS.md) dependency law).
   Every unit below is estate rows, a declared capability, the installed
   kernel, the vault, or an SDA **request** — never a sibling-repo edit, never
   a new package, never a new CLI verb unless the team explicitly admits one.
2. One migration per commit; idempotent; `ROLLBACK` → dry-run → from-transaction
   preflight → `COMMIT` → live-verify → commit ([sql/README.md](../sql/README.md)).
3. Proof is invocation through the installed kernel, not a row count in
   isolation ([implementation-strategy.md](implementation-strategy.md) rule 3).
4. On the database surface it is *all rows*: the vision doc's "CAPSULE" is a
   receipt set under `sidefx:candidates`, never a new artifact vocabulary in
   migrations ([AGENTS.md](../AGENTS.md) non-negotiables).
5. Evaluators are receipt-only. No alignment, disposition, or learning
   installer may write capability, contract, scenario, port, transformation,
   provider or TOOL rows. The only writers of executable rows are the six
   authoring writer kinds behind the ACCEPTED gate.
6. The transistor holds: which mechanic runs and with what configuration is
   declared (1); native implementation is resolver (0). A unit that needs a
   mechanic the kernel cannot express is an SDA request (§7), not an estate
   workaround.
7. Deliberation is bounded and state-mediated. Models propose and critique at
   declared stations; durable candidate state accumulates only through
   admission; no model-to-model channel exists — stations coordinate through
   the canonical candidate state in the database, never with each other.

**Ground pin.** Timings and digests below are host observations; a later
kernel or estate invalidates the *values*, not the shape of the plan.

| Field | Value |
| --- | --- |
| Estate HEAD | `5d2a740` ("Four lanes landed. Status:") |
| SDA HEAD (read-only) | `fbaac64` ("Stub wave landed and proven.") |
| Installed kernel | `%LOCALAPPDATA%\sfx\kernel\feb893ae1eba…\KernelEntry.exe` (`sfx.config.json`) |
| Migrations on disk | 208 authoring files under `sql/migrations/` (plus `.commit.sql` copies) |
| Working tree | 10 modified + 14 untracked migration files (§3, Wave 0 inventory) |
| Boot authority | `sda-kernel-boot-data-access.v1`, re-minted per-lane with structural prerequisites |
| Live proof capabilities | `say-hello-world`, `authoring-altitude-model-stubs` (11 stubs), `resolve-equity-market-price-evidence`, `request-capability-from-objective`, `dispatch-pair-demo` |

**Evidence labels.** **Live** = executed and observed;
**Recorded** = retained receipt, row, or cited file:line; **Projected** =
not built, named as such.

---

## 1. The target, and the half that is missing

The governing target is the **deliberative semantic compiler**: models are
no longer "the author" but specialized cognitive providers positioned
around a durable semantic circuit. The database is the surface of change,
models are temporary intelligence resolving uncertainty, and the admitted
capability is the durable result. One line: models deliberate, the database
remembers, the kernel executes, evidence teaches.

```text
HUMAN INTENT → INTENT/INPUT MODEL → INPUT SHAPE → OUTCOME MODEL
  → OUTCOME CONTRACT → BLUEPRINT MODEL → CANDIDATE BLUEPRINT
  → REVIEWER SWARM → REVIEW TESTIMONY → REVIEWED BLUEPRINT
  → ALTITUDE CIRCUIT (01 → 02 → … → 11, each a bounded question)
  → CANDIDATE ESTATE → BLUEPRINT COMPARISON → ALIGNMENT TRAJECTORY
  → REVIEW → REPAIR/ACCEPT → PROVE → ADMIT → RECEIPTS
  → EVALUATION EVIDENCE → LEARN/PROMOTE → NEXT RUN
```

Three rules from the target reshape this plan:

1. Models coordinate through durable semantic state, never with each other.
   No manager-agent, no agent-to-agent channel: the canonical candidate
   state is the common cognitive workspace (constraint 7).
2. The blueprint is a design hypothesis, not admitted truth. The blueprint
   model has exactly one job — explain the semantic distance between the
   admitted input and the desired outcome — and the authoring circuit is
   allowed to prove it wrong (intelligent alignment, not obedience).
3. Evaluation is a trajectory, not an end score: at every station and
   altitude, what the model received / proposed / reused / invented, what
   reviewers challenged, what survived, what needed human correction, and
   what was admitted.

The **production half** (file → evaluate → decide → gate → install) is
substantially **Recorded**: the candidate write seam exists as rows with a
canned evaluator standing in for real scoring. The **deliberative +
learning half** (shaping, blueprint, reviewer swarm, altitude circuit,
comparison, trajectory, per-role dispositions, promotion) is **Projected**.
This plan lands the production half completely (Wave 0), builds scoring
and repair (Waves 1–4), the evaluation harness (Wave 5), the deliberative
pipeline (Waves 6–7), role-specialized evaluation (Wave 8), and flywheel
closure (Wave 9), so that every wave ends with a live invocation proving
its stage of the circuit.

The vision's load-bearing concepts and where this plan puts each:

| Concept | Vision meaning | Plan home |
| --- | --- | --- |
| Authoring context pack | corpus / precedents / laws / schemas / mechanics / proof obligations / budget, pinned per run | Wave 1 (retrieval) + Wave 5 (pinning) |
| 10 alignment dimensions | intent, scenario, semantic-altitude, estate, topology, authority, provider, proof, novelty, admission | Wave 2 (real evaluators) |
| Convergence distance | countable work-to-admission per candidate | Wave 3 (computed reads) |
| Shaping stations | bounded intent/input/outcome models producing INPUT SHAPE + OUTCOME CONTRACT | Wave 6 |
| Candidate blueprint | one job: explain the semantic distance between admitted input and desired outcome | Wave 6 |
| Reviewer swarm + reconciliation | semantic / reuse / architectural / adversarial / proof reviewers → testimony → blueprint v2 | Wave 6 |
| Altitude circuit | 11 bounded questions, each with admitted state + blueprint + precedents + vocabulary + prior products | Wave 7 |
| Blueprint comparison | MATCH / OMISSION / ADDITION / RESHAPE / SUBSTITUTION / CONTRADICTION / UNRESOLVED; authoring may prove the blueprint wrong | Wave 7 |
| Alignment trajectory | per-station received / proposed / reused / invented / challenged / survived / corrections / admitted | Wave 8 |
| Authoring disposition | per (provider × role) tendencies over many trials | Wave 8 |
| Governance profiles G0–G5 (authoring) | suggestion → feature → full circuit → estate-aware → novel-mechanic → admission participant, role-scoped | Wave 8 |
| Multi-model broadcast + live status | same request → A/B/C → join — now one tactic per station, not the whole architecture | Wave 5 |
| Flywheel closure | 9-item admitted trail → precedent; recurring correction → context fix; legitimate novelty → pattern; eventual determinism 001 → 1000 | Wave 9 |
| Capsule | the durable per-candidate record | Wave 9 (as `sidefx:candidates` receipt set, rows only) |

---

## 2. Current state: what the estate already holds

### 2.1 Landed (Recorded, installed)

- **Candidate filing.** `sql/migrations/declare-capability-candidate-filing.sql`:
  `capability-candidate` kind, `capability-candidate-bundle.v1` envelope,
  `sidefx:candidates/<candidateId>.receipt.v1` AUTHORITY receipt, bundle
  digest, idempotent replay, revision-held. Also publishes (data only)
  `capability-candidate-receipt.v1` and `alignment-evaluation.v1`.
- **Writer-kind skeleton.** `declare-authoring-writer-kinds-skeleton.sql`: six
  kinds (capability-authoring, contract-change, scenario-authoring,
  transformation-change, execution-authority-change, feature-binding-change)
  declared refuse-by-default with closed payload/result contracts.
- **TOOL surface.** 31 TOOL rows under `sidefx:tools`
  (`declare-model-tool-registry.sql`, drift withdrawn by
  `withdraw-model-tool-registry.sql`), `list-tools` / `admit-tool-call`
  reads, `candidate.read`, and the deterministic STUB lane route
  `select-authoring-tool`
  (`declare-candidate-read-and-tool-bindings.sql`). All 31 tools bound
  (22 altitude-stub, 9 shared).
- **11-altitude provability.** `declare-authoring-altitude-model-stubs.sql`:
  capability `authoring-altitude-model-stubs` with 11 chained STUB scenarios,
  one invocation executes all 11 with observation testimony. Proves no
  altitude blocks declaration or execution.
- **Governed single-model lane.** `declare-agent-capability.sql` et seq:
  `request-capability-from-objective` with ADMITTED/REFUSED routing;
  `project-model-provider-protocol` with OpenAI/Gemini text+structured
  projection, normalization, testimony, determinism and no-effect proofs
  (`declare-model-provider-protocol-routing.sql`,
  `update-model-provider-protocol-route-contract.sql`).
- **Concurrency substrate.** `declare-dispatch-pair-demo.sql` (+ serial/
  concurrent switches, equity-fallback extension, result projection):
  declared broadcast group, two branches, all-required join,
  `$.semantics.executionGraph` dispatch authority, serial and concurrent
  modes proven.
- **Placement lifecycle stubs.**
  `declare-model-placement-lifecycle-stubs.sql`: three refuse-by-default
  placement operations (mechanisms A–D vocabulary) awaiting real bodies.

### 2.2 In the working tree, unlanded (Recorded, dirty — Wave 0 scope)

10 modified files (5 migrations × working + `.commit.sql` copies):

| Migration | Content |
| --- | --- |
| `declare-accepted-candidate-gate.sql` | ACCEPTED-decision gate across all six writer kinds (`CANDIDATE_NOT_ACCEPTED` unreachable-around) |
| `declare-candidate-decision-receipt.sql` | receipt-only `candidate-decision` kind, `<candidateId>.decision.v1` |
| `implement-capability-authoring-change.sql` | real body for writer kind 1 (scaffold → contracts → scenarios → meaning → interface → feature → receipt) |
| `implement-model-placement-procedures.sql` | real bodies for the three placement procedures (mechanisms A–D, replace, retire) |
| `record-align-evaluation-receipt-and-admission.sql` | receipt-only `alignment-evaluation` kind + **STUB** evaluator (canned 10 dims, 3 `CANNED_STUB` repairs, distance 3) |

14 untracked files (7 migrations × working + `.commit.sql`, minus one
commit copy):

| Migration | Content |
| --- | --- |
| `implement-remaining-writer-kind-bodies.sql` | real bodies for writer kinds 2–6 |
| `implement-dynamic-tool-dispatch.sql` | execution-authority-change body (duplicate of kind 5 — see §8 risk R1) + agent-lane child rebind to declared-child dispatch |
| `declare-altitude-model-request-contracts.sql` | `altitude-model-request.v1` carrier contracts |
| `compose-altitude-request-transformation.sql` | `compose-altitude-request.v1` adapter (KB-scale request, drops estate context by construction) |
| `enforce-altitude-request-cap.sql` | 256 KB + embedded-context guard read capability |
| `declare-altitude-context-ref-read.sql` | `context-ref` read (resolve one definition by kind/id/digest) |
| `repoint-altitude-stubs-to-live-model.sql` | 11 stub ports → live model port placements (mechanism C, Gemini connector) |
| `repoint-altitude-live-model-to-compact-request.sql` | adapter operation ahead of each live model op; `requestPath` "." (working file only — **commit copy missing**) |

### 2.3 Still stub or skeleton (the honest gaps)

1. **Alignment evaluation is canned.** The stub writes 10 dimensions and
   distance 3 without inspecting the candidate. 0 of 10 dimensions is
   computed (Wave 2).
2. **Convergence distance is stored, not measured.** A present integer is
   accepted; nothing counts repairs, identities, contracts, topology fixes,
   proof gaps, or human corrections (Wave 3).
3. **Retrieval is packer-not-retriever.** `assemble-sidefx-capability-authoring-context`
   packs caller-supplied context (237 KB live reveal); precedent queries run
   over a frozen 108-unit seed; multi-token `find` returns null (estate G1);
   no live contract/scenario inventory reads; no similarity scalar
   ([implementation-plan-capability-demand-flywheel.md](implementation-plan-capability-demand-flywheel.md)
   §2, CD-C1–CD-C7) (Wave 1).
4. **No repair loop.** Decisions record ACCEPTED/… but no REPAIR cycle
   returns a candidate to authoring with findings; no human-correction
   capture (Wave 4).
5. **No evaluation harness.** One intent → one model → one candidate. No
   pinned snapshot, no budget, no N-branch broadcast, no evaluation join,
   no live per-model status (Wave 5).
6. **No deliberative front-end.** No shaping stations, no candidate
   blueprint, no reviewer swarm, no reconciliation; the bundle appears
   whole rather than being deliberated into existence (Wave 6).
7. **No altitude circuit.** The 11 stubs execute in one invocation but
   answer no bounded questions, receive no prior-altitude products, and
   record no per-altitude decisions (Wave 7).
8. **No blueprint comparison.** Nothing compares blueprint hypothesis
   against authored reality; evidenced RESHAPE is inexpressible (Wave 7).
9. **No trajectory, no per-role dispositions.** Nothing records
   per-station trajectories or per-(provider × role) fitness, and G0–G5
   have no role-scoped form (Wave 8).
10. **No learning promotion.** No correction ledger, no recurring-correction
    detector, no precedent-memory promotion, no 9-item admitted trail, no
    evaluator-improvement loop, no determinism counters (Wave 9).

---

## 3. Work breakdown

Units are atomic: the migration(s) plus their proof. Sequencing inside a
wave is by `depends on`; waves are ordered but Wave 1 (retrieval) and
Wave 0 (landing) may run in parallel with separate owners per
[implementation-strategy.md](implementation-strategy.md) file-ownership
rules. Every unit follows the lifecycle in [sql/README.md](../sql/README.md)
and proves by live invocation.

### Wave 0 — Land the dirty lane (production half complete)

Goal: every working-tree migration installed, live-verified, committed
one-per-commit; the full file → stub-evaluate → decide → gate → install
path proven end to end on a real candidate.

| Unit | Scope | Depends on | Proof |
| --- | --- | --- | --- |
| W0.1 | Reconcile the kind-5 overlap: `implement-remaining-writer-kind-bodies.sql` vs `implement-dynamic-tool-dispatch.sql` both supply the `execution-authority-change` body. Decide: single body (merge dispatch-aware installer into the writer file, dispatch file keeps only the agent-lane rebind) or ordered supersession with an explicit gate. Do not install both blindly. | — | one selected `admit-execution-authority-change` read; the other file's in-transaction gate proves superseded-or-merged |
| W0.2 | Install order part 1 (boot-authority writers): writer skeleton (if not yet installed) → accepted-candidate-gate → capability-authoring body → remaining-writer bodies → placement procedures → decision receipt → align-evaluation receipt. Structural-prerequisite re-mints make replay safe in any later order; first install follows this order. | W0.1 | each install: dry-run + preflight + `COMMIT` + live invoke; unrelated-graph digests byte-identical |
| W0.3 | Install order part 2 (altitude live-model lane): altitude request contracts → compose adapter → request cap → context-ref read → repoint stubs to live model → repoint live model to compact request. Author the missing `.commit.sql` for the compact repoint first (copy + `COMMIT`, no other change). | W0.2 (placement procedures) | `authoring-altitude-model-stubs` invokes through the live model with KB-scale composed requests; cap refusals observed (`ALTITUDE_REQUEST_OVERSIZED`, `ALTITUDE_REQUEST_EMBEDDED_CONTEXT`); `context-ref` resolves a contract + a transformation by digest |
| W0.4 | Install dynamic tool dispatch (agent-lane rebind) after W0.1–W0.3. Assert the documented limit in the proof: declared-child dispatch at admission time, not per-invocation dispatch (SDA request RQ-1 in §7 stays open). | W0.1, W0.3 | `request-capability-from-objective` admits equity through the resolved tool port; unknown tool → `EXECUTION_AUTHORITY_CHANGE_TARGET_NOT_DECLARED`; prior equity digests unchanged |
| W0.5 | End-to-end production proof: file a fresh candidate bundle → stub alignment receipt → ACCEPTED decision → install one writer kind through the gate → invoke the installed capability → refuse a gate-bypass (no receipt → `CANDIDATE_NOT_ACCEPTED`). | W0.2–W0.4 | one documented pass, all five receipts under `sidefx:candidates`, live `sfx capability invoke` output retained under `evidence/` |

Exit criteria: working tree clean; Wave 0.5 pass recorded; §8 risks R1–R3
retired or explicitly carried.

### Wave 1 — Retrieval repair (context pack becomes real)

Goal: adopt the demand-flywheel retrieval units so the authoring context
pack is assembled from the live estate, not frozen prose. This wave
*adopts* [implementation-plan-capability-demand-flywheel.md](implementation-plan-capability-demand-flywheel.md)
CD-C1–CD-C7 rather than re-planning them; the units below are that plan's
retrieval spine restated as circuit dependencies.

| Unit | Scope (see flywheel plan for full design) | Proof |
| --- | --- | --- |
| W1.1 (CD-C1) | Multi-token/intersection `find` + distinguishable `NO_MATCH` / `QUERY_UNSUPPORTED` outcomes (`declare-list-capabilities.sql` read/query + result). Kills the G1 duplicate factory: until this lands, every agent query for two-token intents misleads. | `find "market price"` returns the 2–3 true rows; `find market` stays 9; no-match vs unsupported distinguishable; honest exit disposition |
| W1.2 (CD-C5/C6) | Declared contract + scenario inventory reads; estate→brain corpus projection replacing the frozen 108-unit seed as the live-estate index (refresh policy per flywheel D10). | same precedent query answers over live estate identities; channels match `find` on known cases; vector channel disableable |
| W1.3 (CD-C7) | Narrowing composition: CD-C1 → inventories → precedent reads → authoring disposition (REUSE→COMPOSE→PROFILE→AUTHOR_NEW) → context pack via `assemble-sidefx-capability-authoring-context` with declared purposes. Each narrowing question yields a classified precedent item or typed `NOT_FOUND`/`INSUFFICIENT_AUTHORITY`; no similarity scalar invented. | seven narrowing questions exercised live on a held-out intent; every answer classified or honestly absent |
| W1.4 | Authoring-context budget + provenance record: token/time budget members and corpus-snapshot pin (estate digest + contract digests) carried on the packed context so Wave 5 can pin identical packs per model. | two packs assembled from the same pin are byte-identical; a re-pin after an estate change visibly differs |

Exit criteria: an authoring run can request "precedents for intent X" and
receive live, classified, pinned estate answers; G1 closed.

### Wave 2 — Real alignment evaluators (0/10 → 10/10)

Goal: replace the canned stub dimension-by-dimension with declared reads
that inspect the filed bundle. Design rules for every dimension unit:

- Each dimension is a **declared observation read** (`admit-<dimension>-alignment`
  pattern) returning `{disposition: ALIGNED|REPAIR|UNRESOLVED, findings[]}`
  with field-named finding codes. Reads write nothing.
- The `alignment-evaluation.v1` receipt shape is **stable**: the recorder
  procedure is revised to join real dimension reads where they exist and
  `CANNED_STUB` only where they do not. The stub's self-consistency proof
  (10 dims, named repairs) becomes a per-dimension migration proof:
  "dimension X no longer canned".
- `UNRESOLVED` is honest: a dimension answers UNRESOLVED when its inputs
  are absent (e.g. no precedent index yet), never a silent ALIGNED.
- Deterministic dimensions land before model-assisted ones; no dimension
  may call a model until Wave 5's fan-out harness exists to bound it.

| Unit | Dimension | What it checks (declared) | Depends on |
| --- | --- | --- | --- |
| W2.1 | scenario | every scenario carries Input→Event→Outcome faces; contracts resolve (in-bundle or selected `sidefx:contracts`); terminal/root/variant declarations well-formed | Wave 0 |
| W2.2 | estate | every bundle identity probed against the live estate (W1.2 inventories): EXACT reuse available? composition available? profile available? Unnecessary new identity → REPAIR naming the reusable precedent | W1.2 |
| W2.3 | proof | every scenario names fixtures/evidence obligations; fixture contracts resolve; no scenario without a provable outcome | Wave 0 |
| W2.4 | novelty | every new contract/scenario/vocabulary justified against W2.2's reuse answer; unjustified novelty → REPAIR | W2.2 |
| W2.5 | authority | no executable meaning outside declared authority: bundle carries no implementation bodies, no resolver-shaped members; bindings name declared ports/mechanics only | Wave 0 |
| W2.6 | topology | fan-out/convergence/dependencies/transitions justified: every edge resolves, no unreachable cell, no cycle unless declared; uses the graph-source assembly reachability the estate already proves | Wave 0 |
| W2.7 | provider | providers subordinate and replaceable: credential/endpoint authorities referenced by digest, effect scopes bounded, N-fallback chains as data, no provider-specific meaning in scenarios | Wave 0 |
| W2.8 | admission | distance-to-admission pre-check: runs the six writer-kind admission predicates + accepted-gate shape check in observation mode; reports which kinds would ADMIT vs HOLD | W0.2 |
| W2.9 | intent | model-assisted: does the candidate preserve the human's stated objective? Runs only through Wave 5's bounded fan-out; findings quote objective spans. | Wave 5 |
| W2.10 | semantic-altitude | model-assisted with deterministic pre-check: business meaning out of mechanics/provider detail (deterministic vocabulary/altitude-key scan first; model judges the residue). | Wave 5 |
| W2.11 | evaluator-version join | revise `model.record_alignment_evaluation` to the evaluator fan-out: join all landed dimension reads, record `evaluatorAuthorityId` per dimension, keep receipt id `<candidateId>.alignment.v1` and revision-refusal. The three canned repairs disappear dimension by dimension; the last canned repair's removal is this wave's exit proof. | W2.1–W2.10 |

Exit criteria: a filed candidate's alignment receipt carries 10 computed
dimensions, zero `CANNED_STUB` findings; a deliberately defective bundle
(a duplicate identity, a missing fixture, an unresolvable contract) yields
the expected named REPAIRs.

### Wave 3 — Computed convergence distance

Goal: distance is measured by reads, never stored by hand.

| Unit | Scope | Proof |
| --- | --- | --- |
| W3.1 | Counting reads per vision class: semantic repairs, unnecessary identities, missing contracts, topology repairs, proof gaps, human semantic corrections (joins Wave 4's correction ledger; zero until it exists). Each read counts findings on the recorded alignment receipt + decision/correction receipts. | counts reproduced from receipts by an independent read; hand-editing the distance field is impossible (no such writer) |
| W3.2 | `convergence-distance.v1` observation read: sums the six counters into one distance with per-class breakdown; recorded as a receipt-only `<candidateId>.distance.v1` under `sidefx:candidates` for pinning, with the same revision-refusal as other receipts. | vision-doc example reproduced: a clean candidate shows distance ≈4-class shape, a sloppy one ≈29; recomputation from receipts matches |

Exit criteria: two candidates for the same intent show honestly different
distances traceable to named findings.

### Wave 4 — Repair loop + correction ledger

Goal: REPAIR is a cycle, not a verdict; every human correction is captured
as data the flywheel can learn from.

| Unit | Scope | Proof |
| --- | --- | --- |
| W4.1 | REPAIR decision + revision filing: a `candidate-decision.v1` with decision REPAIR names finding codes; a revised bundle files under a **new candidate id** linked to its parent (`supersedes` member on the receipt — revision keeps history, never rewrites it). Accepted-gate semantics unchanged: only ACCEPTED-at-digest installs. | parent REPAIR → child filed → child ACCEPTED → installed; parent receipt untouched |
| W4.2 | Human-correction ledger: receipt-only `candidate-correction.v1` kind recording reviewer authority, corrected dimension, before/after finding, and correction class (semantic / topology / proof / novelty / other). Writes one AUTHORITY receipt; never edits the candidate. | corrections recorded for the Wave 0.5 candidate; Wave 3's human-correction counter reads them |
| W4.3 | Divergence-explanation shape: the bundle envelope gains an optional `divergence` block (governing invariants preserved, legitimate divergence explained, intended effect closed, novelty inspectable) per the vision's ALIGNMENT formula; W2.8 checks its presence when topology diverges from precedents. The block is the evidence carrier for the Wave 7 blueprint comparison. | a candidate that deliberately improves on a precedent blueprint admits with its divergence block intact and evaluated |

Exit criteria: a candidate can travel PENDING → REPAIR → revised → ACCEPTED
→ installed with the full correction trail retained.

### Wave 5 — Multi-model fan-out evaluation harness

Goal: one intent, pinned pack, N models, N candidates, one join — the
"hell of a SideFX demo" as declared rows.

| Unit | Scope | Proof |
| --- | --- | --- |
| W5.1 | Pinned authoring run: `authoring-run.v1` receipt-only kind pinning intent, context-pack digest (W1.4), corpus snapshot, mechanic catalog digest, proof obligations, token + time budgets. All N model invocations in the run resolve the same pin. | two runs from the same pin produce identical packs; a run from a stale pin refuses with `AUTHORING_RUN_PIN_STALE` |
| W5.2 | Declared N-branch broadcast: generalize the dispatch-pair pattern (2 branches, `dispatch-pair-demo`) to an N-provider broadcast group with per-branch budgets and deadline on the `$.semantics.executionGraph` dispatch authority. Branch count is data (provider roster on the run receipt), not a new capability per N. SDA readiness check: N-branch + budget/deadline enforcement confirmed on the installed kernel first (§7 RQ-3); if refused, land 3-branch fixed as the bounded form and keep N-branch Projected. | 3-provider broadcast executes (serial mode first, concurrent second); per-branch testimony retained; over-budget branch bounded per policy |
| W5.3 | Per-branch candidate filing: each branch files its own candidate bundle under the run's namespace (`<runId>.<provider>.candidate-N`), carrying the model receipt (provider, model, request digest, response digest, token/timing testimony). Filing failures are branch findings, not run failures. | 3 candidates filed from 1 run; a branch that returns malformed output files a refusal receipt instead of a bundle |
| W5.4 | Evaluation join: deterministic graders first — run Waves 2–3 over all N candidates and record a `<runId>.join.v1` receipt with per-candidate dimensions + distances side by side. Model-based graders and human/SME review join later as additional grader receipts on the same join; the join never averages away a boundary signal (cf. `model-evaluation-circuit.md` governance-vector rule). | join receipt for a live 3-model run; the REUSE-violating branch is visibly worst on estate/novelty while possibly best on novelty-usefulness |
| W5.5 | Live run-status reads: `authoring-run-status` observation read projecting per-branch progress (precedents resolved / reusing X / authoring scenario Y / proposed N contracts / generating fixtures) from retained testimony for the demo surface. Read-only; the terminal renders, the estate declares. | status read during a live run shows per-model lines matching the vision's demo sketch |

Exit criteria: the vision's finance-capability demo runs end to end:
one intent → pinned pack → 3 models → 3 candidates → join receipt with
dimensions and distances.

### Wave 6 — Deliberative front-end (shaping → blueprint → reviewer swarm)

Goal: intent becomes a reviewed blueprint through bounded stations; every
station proposes into durable candidate state, never into another model.
Design rules:

- Each station is a declared capability (or scenario set) with a closed
  input contract (bounded question + admitted state + blueprint-so-far +
  precedents + vocabulary + prior products) and a closed product
  contract. Station products file as candidate-scoped AUTHORITY receipts.
- Providers are data: a station's provider roster lives on the authoring
  run receipt (Wave 5); swapping a station's model is a re-pin, not a
  rewrite.
- Blueprint versions are immutable; reconciliation mints v2…vN, never
  edits v1.

| Unit | Scope | Depends on | Proof |
| --- | --- | --- | --- |
| W6.1 | Intent/input shaping station: bounded question "what is being asked / what is the input / what is admissible?"; product INPUT SHAPE receipt. Deterministic admissibility pre-check (contracts/vocabulary resolve) first; the model proposes the residue. | Wave 5, W1.2 | held-out intent yields a shaped input whose contracts resolve; inadmissible input → named refusal, not a guess |
| W6.2 | Outcome shaping station: bounded question "what must become true when this is successful?"; product OUTCOME CONTRACT receipt. Same deterministic-first pattern. | W6.1 | outcome contract names provable terminal conditions; an unprovable outcome → REPAIR naming the missing evidence |
| W6.3 | Blueprint synthesis station: exactly one job — propose the circuit connecting the admitted input to the desired outcome; product CANDIDATE BLUEPRINT v1 receipt (skeletal scenarios, contracts, responsibilities, mechanics, providers, evidence, interfaces). | W6.1–W6.2 | blueprint v1 filed quoting its input/outcome receipt digests; every circuit element traces to one boundary or the other |
| W6.4 | Reviewer swarm: five bounded reviewer stations over the same blueprint pin — semantic coherence ("does this circuit establish the outcome?"), reuse ("is the estate already possessing this?"), architectural leakage ("has implementation detail entered semantic authority?"), adversarial pressure ("what assumptions fail this?"), proof closability ("could we prove this closed?"). Each files REVIEW TESTIMONY quoting blueprint spans. Broadcast reuses the Wave 5 N-branch pattern; reviewers are parallel branches, not a new primitive. | W6.3, W5.2 | a deliberately over-designed blueprint draws the expected challenges from ≥3 reviewers; testimony cites spans, not vibes |
| W6.5 | Reconciliation: deterministic-first join of the five testimonies into findings; model-assisted redraft proposes BLUEPRINT v2. Loop guard: at most N review rounds per run (declared cap, default 3), then HELD with `BLUEPRINT_REVIEW_ROUNDS_EXHAUSTED` for human disposition. | W6.4 | blueprint v1 → 5 testimonies → v2 on a live intent; findings resolved or explicitly carried; round cap observed under adversarial seeding |

Exit criteria: one intent travels shaping → v1 → swarm → v2 with every
product filed and every provider choice pinned; no station reads another
station's model output except through filed receipts.

### Wave 7 — Altitude circuit + blueprint comparison

Goal: the 11 altitudes answer bounded questions in order, each building
on prior products; authored reality is compared against the blueprint
and may prove it wrong.

| Unit | Scope | Depends on | Proof |
| --- | --- | --- | --- |
| W7.1 | Per-altitude bounded-question framing: revise the 11 altitude operations (Wave 0 live-model lane) so each receives exactly {admitted state refs, blueprint ref, precedent refs, vocabulary refs, prior altitude products, one bounded question} via the compact-request adapter + `context-ref` reads; each files its altitude product receipt. | W0.3, W6.5, W1.3 | one invocation produces 11 product receipts; any altitude re-run from its filed inputs reproduces its product |
| W7.2 | Prior-product chaining: altitude N+1's input contract requires altitude N's product digest; a missing or changed product refuses with `ALTITUDE_PRODUCT_NOT_ADMITTED`. Proven in-transaction like the existing contract-equality chaining. | W7.1 | tampering with altitude 4's product provably breaks altitude 5's admission; the chain re-converges after re-resolution |
| W7.3 | Blueprint comparison: `blueprint-comparison.v1` observation read comparing REVIEWED BLUEPRINT ↔ AUTHORED CANDIDATE REALITY per element — MATCH / OMISSION / ADDITION / RESHAPE / SUBSTITUTION / CONTRADICTION / UNRESOLVED — recorded as `<candidateId>.comparison.v1`. RESHAPE / SUBSTITUTION with evidence + review acceptance mints blueprint vN+1 (intelligent alignment); CONTRADICTION without acceptance is HELD. Consumes the W4.3 divergence block as the evidence carrier. | W7.1, W6.5, W4.1 | a seeded topology improvement (serial → concurrent join with evidence) lands as accepted RESHAPE with blueprint v3; an unevidenced contradiction is HELD |
| W7.4 | Candidate assembly: the altitude products + comparison assemble into the filed candidate bundle (existing `capability-candidate` kind); the bundle envelope carries blueprint digest + comparison digest as provenance. | W7.2–W7.3 | filed bundle re-resolves to its 11 products + comparison + blueprint version; provenance digests verify |

Exit criteria: shaping → blueprint → swarm → v2 → 11 altitudes →
comparison → filed bundle on one live intent, end to end.

### Wave 8 — Role-specialized evaluation (trajectory → dispositions → fitness)

Goal: dispositions per (provider × role); role fitness resolves which
provider staffs which station; G0–G5 bind per role. This is where "we can
measure it" becomes rows: Gemini may own blueprint synthesis while Claude
owns adversarial review, because the receipts say so.

| Unit | Scope | Depends on | Proof |
| --- | --- | --- | --- |
| W8.1 | Per-station fan-out (role bench): run the same station question across rostered providers via the Wave 5 broadcast; each files its station product under the run namespace. Generalizes old whole-candidate filing to per-station products. | Waves 5–6 | same blueprint question → 3 station products from 3 providers; a malformed branch files a refusal receipt, not a product |
| W8.2 | Alignment trajectory: `<runId>.trajectory.v1` receipt joining per-station / per-altitude records — received / proposed / precedent / reused / invented / challenged / survived / corrections / admitted. The trajectory is the evaluation record; the Wave 2 dimensions remain the admission record. | W8.1, Waves 2–4, Wave 7 | trajectory for a live run renders the vision's station-by-station ✓ / ! ledger; every mark cites its receipt |
| W8.3 | Per-role dispositions: `model-role-disposition.v1` reads aggregating per provider × role × capability family over trial windows — the 10 authoring scalars (reuse-seeking, identity rate, boundary/altitude discipline, proof awareness, provider neutrality, topology tendency, novelty usefulness, correction burden, admission convergence) plus station scalars (blueprint acceptance rate, reviewer precision vs human corrections, altitude first-pass rate). Every scalar cites its receipt set; window and family are parameters. | W8.2 + trial volume | two providers over the same 10-run window show honestly different per-role profiles (e.g. strong synthesizer / weak reviewer vs the reverse) with drill-down to runs |
| W8.4 | Role fitness resolution: `provider-role-fitness` read resolving the best-rostered provider per station from dispositions + capability risk + budgets (cf. `model-evaluation-circuit.md` provider resolution); the run roster binds through it. Advisory-only until the trial floor (§9.7) is met. | W8.3 | a run roster bound through fitness differs honestly from the default roster, with cited reasons per station |
| W8.5 | G0–G5 role-scoped: profiles as declared authority (suggestion-only → feature-candidate → complete-circuit → estate-aware → novel-mechanic-candidate → admission-participant), each declaring permitted stations + change kinds, authority-expansion limits, and review requirements. `provider-authoring-eligibility` joins disposition + profile per provider per role per family; ineligible station staffing or filing is HELD with `AUTHORING_PROFILE_NOT_ELIGIBLE`. Deterministic gates stay authoritative — G5 remains "extremely restricted". | W8.3 | a provider with LOW reuse-seeking staffs exploratory review but not routine synthesis; eligibility changes only when new evaluation receipts land |

Exit criteria: the vision's Model A / Model B story is live data —
role-sensitive staffing and governance derived from measured per-role
dispositions.

### Wave 9 — Flywheel closure (learning promotion)

Goal: every evaluation teaches the estate; the surface needing
nondeterministic reasoning shrinks over time — Capability 001 improvises,
Capability 1000 mostly reuses.

| Unit | Scope | Depends on | Proof |
| --- | --- | --- | --- |
| W9.1 | 9-item admitted trail: `<capabilityId>.trail.v1` joining intent interpretation, input-shape, outcome-shape, blueprint proposal + review, altitude decisions, novelty, corrections, conformance evidence, and final admitted blueprint. The trail is the precedent unit the next capability reads (Wave 1 retrieval indexes trails). | Waves 6–8, W4.2 | a second capability in the same family cites the first's trail in its estate-dimension reuse answer |
| W9.2 | Correction ledger analysis: `recurring-correction.v1` observation reads clustering Wave 4.2 corrections by station + class + target (e.g. "37 blueprint syntheses invented a quote capability despite the admitted one"). Output is a finding set, not an action. | W4.2, W8.2 | a seeded run of repeated identical corrections surfaces one recurring finding with count and receipt cites |
| W9.3 | Context-improvement proposals: recurring retrieval/context failures (W9.2 class = context) produce `authoring-context-proposal.v1` receipts naming the pack/precedent/catalog fix; applying one is a normal declared change through the writer kinds, not a flywheel bypass. | W9.2 | one proposal applied; the next evaluation batch shows the correction class reduced |
| W9.4 | Novelty promotion: recurring legitimate novelty (review ACCEPTED the construct ≥N times) produces `pattern-promotion-proposal.v1` naming the reusable authority/profile/mechanic to admit. Mechanism promotion that needs a new resolver mechanic becomes an SDA request (§7); authority/profile promotion stays in-estate. | W9.2 | one invented-twice construct becomes one admitted pattern; future candidates reuse it (estate dimension proves the reuse) |
| W9.5 | Evaluator improvement + determinism counters: `evaluator-performance.v1` reads comparing dimension findings against human corrections (precision/recall per dimension, station-scoped where applicable); `deterministic-coverage` and `recurring-correction-debt` counters published as observation reads. The goal line is explicit: debt shrinking, coverage growing. | W9.2 | counters move in the right direction across two promotion cycles; a dimension with poor precision is visibly the next to fix |
| W9.6 | Candidate receipt-set ("capsule") closure: `<candidateId>.close.v1` receipt joining bundle + blueprint versions + testimonies + comparison + trajectory + alignment + distance + decision + corrections + install receipts into one pinned set. Rows only; no new vocabulary in migrations. This is the durable per-candidate record the vision calls CAPSULE. | W9.1, Waves 2–8 | one closed set per acceptance-demo candidate; re-resolution from the close receipt reproduces the join and the trajectory |

Exit criteria: two full turns of DELIBERATE → AUTHOR → EVALUATE →
CORRECT → ADMIT → CAPTURE → CLASSIFY → PROMOTE → DELIBERATE AGAIN with
the debt counters moving and trail reuse visible; the vision's "two
outputs of every eval" (was this candidate good? what did SideFX learn?)
both answered from receipts.

---

## 4. End-to-end acceptance (the demo that proves the plan)

When Waves 0–9 are complete, this single pass must run live:

```text
Intent: "Author a capability that evaluates the financial position of a public company."
  → pinned authoring run (pack digest, corpus snapshot, budgets, station roster)
  → shaping stations: INPUT SHAPE + OUTCOME CONTRACT receipts
  → blueprint synthesis: CANDIDATE BLUEPRINT v1
  → reviewer swarm: 5 testimonies → reconciliation → BLUEPRINT v2
  → altitude circuit: 11 bounded products chained by digest
  → candidate assembly + blueprint comparison (accepted RESHAPE → v3 where earned)
  → alignment trajectory + 10-dimension receipt + convergence distance
  → human/governed review (ACCEPT with corrections ledger)
  → installed through the six writer kinds behind the gate
  → invoked live through the installed kernel
  → close receipt + 9-item trail + updated per-role dispositions + debt counters
```

Acceptance is the retained `--json` of every step under `evidence/` plus
the debt counters showing movement from the previous turn. No step may
require a file edit, a sibling checkout (beyond the owed lifecycle
violation in §7 RQ-2), or a human judgment that is not captured as a
receipt. And no model-to-model channel may exist anywhere: every station
product must re-resolve from filed candidate state (provable by re-running
any station from its filed inputs).

---

## 5. Sequencing and dispositions

| Wave | Disposition | Trigger / gate |
| --- | --- | --- |
| Wave 0 dirty lane | **Needed now** | working tree is dirty; nothing else is verifiable until it lands |
| Wave 1 retrieval | **Needed now** (parallel with Wave 0, separate owners) | G1 poisons every estate/novelty judgment; blocks W2.2/W2.4 |
| Wave 2 deterministic dims (W2.1–W2.8) | **Needed now**, after Wave 0 | the stub is honest but empty; W2.2/W2.4 wait on W1.2 |
| Wave 3 distance | **Needed now**, after W2.1–W2.8 + W4.2 shape | needs counters; human-correction counter reads zero until W4.2 |
| Wave 4 repair loop | **Needed now**, after Wave 0 | revision semantics needed before any real multi-candidate run |
| Wave 5 harness | **Useful now**, after Waves 1–4 | needs pinned packs, real deterministic graders, revision filing |
| Wave 2 model-assisted dims (W2.9–W2.10) | **Useful now**, after Wave 5 | bounded model calls only inside the harness |
| Wave 6 deliberative front-end | **Useful now**, after Wave 5 + W1.2/W1.3 | needs bounded invocation, live inventories, narrowing composition |
| Wave 7 altitude circuit | **Useful now**, after Wave 6 + W0.3 | needs reviewed blueprint + live-model altitude lane |
| Wave 8 role evaluation | **Useful now**, after Waves 5–7 + trial volume | needs runs before aggregation is meaningful (start with 10-run windows per provider × role × family) |
| Wave 9 flywheel | **Useful now**, after Waves 4 + 8 | needs corrections + trajectories + dispositions to learn from |
| N-branch generalized broadcast | Defer with trigger | land 3-branch fixed first; generalize when a 4th provider is rostered or a run needs heterogeneous branch counts |
| Model-based graders + SME review join | Defer with trigger | deterministic join first; add grader receipts when a dimension's precision (W9.5) proves deterministic grading insufficient |
| Per-station heterogeneous rosters | Defer with trigger | start with one roster per run; per-station rosters when fitness resolution (W8.4) evidences a role split worth staffing |
| Live dashboard surface | Defer with trigger | status reads (W5.5) first; a watched surface only when someone watches it |

---

## 6. Lanes and file ownership (parallel execution)

Per [implementation-strategy.md](implementation-strategy.md): one agent per
file, atomic units, tree green between units, proof is invocation.

| Lane | Scope | Owns | Serialization |
| --- | --- | --- | --- |
| **0 — landing** | Wave 0 installs, one migration per commit | the 24 dirty files, in W0.1–W0.5 order | **serial** — boot-authority re-mints collide otherwise; structural prerequisites make replay safe but review is not |
| **1 — retrieval** | Wave 1 reads + corpus projection | new `sql/migrations/*{find,inventory,precedent,corpus,context-pack}*.sql` | parallel with Lane 0; single writer per file |
| **2 — evaluators** | Waves 2–3 reads + recorder revision | new `sql/migrations/*{alignment,dimension,convergence}*.sql` + the recorder revision | parallel with Lane 1 after Wave 0; recorder revision serializes with Lane 0's receipt work |
| **3 — review/repair** | Wave 4 decisions + ledger | new `sql/migrations/*{candidate-decision,candidate-correction,divergence}*.sql` | parallel after Wave 0 |
| **4 — harness** | Wave 5 run/broadcast/join/status | new `sql/migrations/*{authoring-run,broadcast,join}*.sql` | parallel after Waves 1–4 |
| **5 — deliberation** | Waves 6–7 stations + circuit + comparison | new `sql/migrations/*{shaping,blueprint,reviewer,reconciliation,altitude-circuit,comparison,assembly}*.sql` | parallel after Wave 5 |
| **6 — governance/learning** | Waves 8–9 trajectory + dispositions + promotion | new `sql/migrations/*{trajectory,role-disposition,role-fitness,eligibility,recurring,promotion,trail,close}*.sql` | parallel after Waves 5–7 |

---

## 7. SDA requests (not estate work)

These are cross-language **requests** per the dependency law. Each states
the primitive, why it must be kernel, and the data that binds it. Nothing
in Waves 0–9 is blocked on them except where noted.

| ID | Primitive | Why kernel | Binds to | Blocks |
| --- | --- | --- | --- | --- |
| RQ-1 | Run-time scenario/capability resolution for `invoke-scenario` (per-invocation child dispatch) | all consumer platforms resolve `operation["scenarioId"]` at graph-assembly time (C# `DeclaredOperationCarrier.cs`, Node matrix); no declared mechanic resolves an id from run-time input (`implement-dynamic-tool-dispatch.sql:35-49` states the blocker precisely) | execution-authority-change `targetCapabilityId`; agent-lane admitted proposal | full dynamic dispatch only — Waves 0–9 proceed on admission-time declared-child dispatch |
| RQ-2 | Migration lifecycle through installed `KernelEntry.exe` (`run-migration` + `invoke-from-transaction` equivalents) | the estate's last checkout dependency ([AGENTS.md](../AGENTS.md) owed violation; `capability-estate-research.md` §6 A5) | every migration's lifecycle | nothing functionally, but every unit carries the violation until this lands |
| RQ-3 | N-branch broadcast + per-branch budget/deadline enforcement confirmation on the installed kernel | dispatch authority is interpreted by the kernel (`dispatch-pair-demo` proves 2-branch; N-branch + budgets unproven). The reviewer swarm (W6.4) and role bench (W8.1) reuse this primitive — no separate request. | W5.2 broadcast group, `authoring-run.v1` budgets | W5.2 generalized form only — 3-branch fixed is the fallback |
| RQ-4 | Station/evaluator-needed mechanics, if any (frozen SEJ graph-dispatch profile additions) | estate cannot add resolver mechanics (transistor corollary; K029–K032) | W2 dimensions and W6 stations that prove inexpressible in T-SQL + declared transforms | only the units that prove it, if any — default assumption is zero |

---

## 8. Risks

| ID | Risk | Mitigation |
| --- | --- | --- |
| R1 | **Kind-5 double body.** Two uncommitted files supply the `execution-authority-change` body. Installing both mints conflicting reads/contracts. | W0.1 reconciles before any install; the decision is recorded in the winning file's header. |
| R2 | **Boot-authority re-mint contention.** Parallel lanes re-mint `sda-kernel-boot-data-access.v1`; a lane that pins exact digests breaks when another lands first. | structural-prerequisite pattern (already used by the decision/align/placement lanes); Lane 0 serializes Wave 0; every re-mint asserts shape, detects replay from declared rows. |
| R3 | **Missing commit copy.** `repoint-altitude-live-model-to-compact-request.sql` has no `.commit.sql`. | author it in W0.3 (mechanical copy + `COMMIT`); never hand-edit install semantics between copies. |
| R4 | **Frozen-corpus staleness window.** Until W1.2 lands, estate/novelty judgments over the frozen seed mislead. | W2.2/W2.4 stay `UNRESOLVED`-capable and hard-depend on W1.2; no dimension reports ALIGNED from frozen data. |
| R5 | **Model cost/latency unbounded.** Live-model altitudes + swarm + fan-out multiply provider spend. | W1.4 budgets + W5.1 pins + `enforce-altitude-request-cap.sql` precedent; every model-calling station declares its budget and its over-budget refusal first; review rounds capped (W6.5). |
| R6 | **Human-review bottleneck.** Waves 4/8/9 assume reviewer throughput that may not exist. | model reviewers absorb first-pass review; humans are needed only at join/ACCEPT plus sampled calibration of reviewer precision (W8.3/W9.5); batching review per join (not per candidate) is the documented fallback. |
| R7 | **SDA request lead time.** RQ-1/RQ-3 gate the full forms of dispatch and fan-out. | every blocked unit names its bounded fallback (declared-child dispatch; 3-branch fixed) and lands the fallback first. |
| R8 | **Receipt-namespace collisions.** `sidefx:candidates` gains many receipt shapes; a sloppy id scheme collides. | id grammar fixed here: `<candidateId>.{receipt,alignment,distance,decision,comparison,close}.v1`, blueprint `*.blueprint-v<N>.v1`, testimony `*.review-<role>.v1`, station products `*.station-<station>.v1`, corrections `<candidateId>.correction-<N>.v1`, `<runId>.{authoring-run,join,trajectory}.v1`, trails `<capabilityId>.trail.v1`. |
| R9 | **Deliberation loops don't terminate.** Review→reconcile→review or blueprint→comparison→reblueprint can cycle. | declared round caps (W6.5 default 3) + reconciliation quorum (all five testimonies or explicit waiver); exceeded caps HELD for human disposition, never silently looped. |
| R10 | **Role-roster drift.** Station↔provider assignments made by hand drift from measured fitness. | rosters are run-pinned data bound through fitness resolution (W8.4); unpinned station staffing refused; fitness stays advisory until the trial floor (§9.7) is met. |

---

## 9. What this plan asks the team to dispose

1. **Adopt the wave order** (§5), including Wave 1 running parallel with
   Wave 0 under separate ownership.
2. **Rule on R1** (kind-5 single body vs ordered supersession) before any
   Wave 0 install.
3. **Confirm the receipt-id grammar** (§8 R8) and the rows-only capsule rule
   (constraint 4) so Waves 4–9 have no vocabulary drift.
4. **Confirm the UNRESOLVED honesty rule** (Wave 2 design rules): a dimension
   with absent inputs answers UNRESOLVED, never silent ALIGNED.
5. **Confirm the blueprint-hypothesis rule** (Wave 7): authoring may prove
   the blueprint wrong via evidenced, review-accepted RESHAPE /
   SUBSTITUTION; unevidenced CONTRADICTION is HELD.
6. **File or defer the SDA requests** (§7 RQ-1–RQ-4); RQ-2 is already owed
   and needs no new decision, only scheduling.
7. **Set the trial-volume floor for Wave 8** (proposed: 10-run windows per
   provider × role × capability family before eligibility binds; fewer
   runs = advisory-only dispositions).

---

## 10. Traceability (vision → plan → rows)

| Vision element | Plan unit | Declared rows (proposed names; `*` = already Recorded) |
| --- | --- | --- |
| Candidate + model receipt | Wave 0 | `capability-candidate` kind*, `capability-candidate-bundle.v1`*, `*.receipt.v1`* |
| 10 alignment dimensions | W2.1–W2.11 | `alignment-evaluation` kind*, `admit-<dimension>-alignment` reads, `alignment-evaluation.v1`* |
| Convergence distance | W3.1–W3.2 | `convergence-distance.v1` read, `*.distance.v1` receipts |
| Review → repair/accept | W4.1–W4.3 | `candidate-decision` kind (dirty), `*.decision.v1`, `candidate-correction.v1`, `divergence` block |
| Prove → admit | Wave 0 | six writer kinds (dirty), `admit-candidate-acceptance` (dirty) |
| Context pack | W1.1–W1.4 | `find` intersection, inventory reads, corpus projection, pack budget+pin |
| Broadcast harness + join | W5.1–W5.5 | `authoring-run.v1`, N-branch dispatch authority, `<run>.join.v1`, `authoring-run-status` |
| Shaping + blueprint + swarm | W6.1–W6.5 | shaping stations, `*.blueprint-v<N>.v1`, `*.review-<role>.v1` testimonies, reconciliation + round cap |
| Altitude circuit + comparison | W7.1–W7.4 | bounded-question framing, product chaining, `*.comparison.v1`, assembly provenance |
| Trajectory + per-role disposition + G0–G5 | W8.1–W8.5 | `<run>.trajectory.v1`, `model-role-disposition.v1`, `provider-role-fitness`, role-scoped profiles, `provider-authoring-eligibility` |
| Learn / promote + trail | W9.1–W9.6 | `*.trail.v1`, `recurring-correction.v1`, `authoring-context-proposal.v1`, `pattern-promotion-proposal.v1`, `evaluator-performance.v1`, determinism counters, `*.close.v1` |

*End of plan. Next action: dispose §9, then W0.1.*
