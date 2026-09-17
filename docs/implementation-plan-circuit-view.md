# Implementation plan — the circuit view (multi-agent)

**Status.** Proposed 2026-09-17. Realizes
[circuit-view-flywheel.md](circuit-view-flywheel.md). Applies the
[sidefx-architecture-decision-rubric.md](sidefx-architecture-decision-rubric.md)
(§4 dispositions, §5 measures, §7 compact record) and the
[implementation-strategy.md](implementation-strategy.md) conventions (lanes,
units, disjoint ownership, unit template, definition of done). The terminal
outcome: `sfx capability observe <any-capability> --format circuit` streams the
declared graph's circuit live — boxes for cells, arrows for edges, lighting
from testimony — for **every** capability, with no per-capability work.

## Current state (what the units build on)

- The declared graph exists and is addressable: `analysis.capability_graph_source`
  (scenarios, executionAuthorities, transitions/routing, port bindings),
  compiled by the kernel into cells/edges.
- The planned↔observed join already exists: the drilldown overlay
  (`src/execution-drilldown.mjs`) joins planned topology with testimony and
  powers `--trace`; the streamed entries carry status, duration and gap.
- The declared-reading pattern is proven: `read-invocation-timing` reads
  testimony passed as input and returns a declared view model plus a declared
  display projection.
- The display path exists (U1/U2/U4: declared display documents and streamed
  `display.entry`); `render.mjs` still owns presentation vocabulary and is the
  retirement target.
- The layout reference is the sketch in
  [target-harness-experience.md](target-harness-experience.md) §"The cleanest
  sketch" (currently encoding-corrupted; repaired in CV-E0).

## Target shape

1. **View model (declared).** `read-capability-circuit` — a declared read (+
   transformation) whose input is `{capabilityId, cellTestimony, edgeTestimony,
   granularity?}` and whose output is
   `circuit-view.v1`: `nodes[]` `{cellId, kind, altitude, label, parentId,
   status, durationMilliseconds, observedAt}` and `edges[]` `{edgeId, kind,
   from, to, selected, selectsVariant}`. Derivation rules: collapse to semantic
   components (scenario / responsibility / provider / physical / terminal
   outcome), planned nodes without testimony render `unobserved`, selection
   edges carry the routing variant actually taken, durations come from
   testimony verbatim.
2. **Streamed fragments (declared).** The lane's display path emits one
   `display.entry` per component with its exact text (including box glyphs as
   declared literals) as the cell completes — the real-time lighting.
3. **Terminal = transport.** The CLI prints declared entries/documents
   verbatim (phase 1: one generic circuit emitter over the view model, marked
   transitional; phase 2: bytes only). `render.mjs` retires; `--json` stays
   byte-identical; process, flushing and stderr diagnostics remain.
4. **Acceptance pair.** Structure: every planned cell maps to testimony and
   every observed cell maps to a planned cell for the exercised capabilities.
   Time: `npm run verify:timing` unchanged. A combined verdict names both.

## Lanes and units

| # | Lane | Unit | Owns (files) | Depends | Proof |
|---|---|---|---|---|---|
| CV-E0 | E — docs | Repair `docs/target-harness-experience.md` to clean UTF-8 (layout reference; include the appended outcome payload) and commit | the doc | — | box-drawing characters render clean; git tracks the repaired bytes |
| CV-A1 | A — estate rows | Declare `circuit-view.v1` contract and the `read-capability-circuit` capability (read + transformation + display projection), deriving nodes/edges from the declared graph + testimony input | one migration | CV-E0 | fixture: the agent lane's recorded testimony yields the doc's sketch topology (11 semantic components, selected `ADMITTED` branch); `unobserved` nodes render unlit |
| CV-A2 | A — estate rows | Granularity rule as declared authority: which cells collapse into one component per altitude/kind (scenario, responsibility, provider, physical, terminal) | same migration (serial after A1) | A1 | both branches of `request-capability-from-objective` and the equity capability produce their expected component counts |
| CV-B1 | B — estate rows | Declare the lane's streamed circuit fragments: one `display.entry` per component carrying the exact text (box glyphs as literals), emitted as cells complete | one migration | A1 | `observe` streams fragments in execution order; the final frame equals the view model rendered (no drift) |
| CV-B2 | B — estate rows | Declare the same fragments for `resolve-equity-market-price-evidence` (the second instance; the marginal-effort measurement) | one migration | B1 | second capability's circuit live; effort recorded for observation 3 |
| CV-C1 | C — CLI transport | Add `--format circuit` to the observe surface (estate mapping row `format: true` for `capability.observe` + CLI option) and print the declared view model/fragments verbatim; until B1 lands, one **generic** emitter over the view model, explicitly marked transitional | CLI `src/cli.mjs`, `src/render.mjs` (transitional), estate `config/sfx.commands.json` | A1 (shape), parallel to B | live both branches; `--json` byte-identical; no per-capability layout in the CLI |
| CV-C2 | C — CLI transport | Retire `render.mjs`: declared bytes/entries printed verbatim; presentation vocabulary removed; keep process/flush/JSON | CLI `src/render.mjs`, `src/cli.mjs` | B1, B2 | suite green; story/trace output byte-identical to the declared documents for the exercised capabilities |
| CV-D1 | D — estate rows | **Declared structural attestation**: the verdict is authority, not code. Extend `read-capability-circuit` (or declare a sibling read) so its input carries the compiled plan (planned cells/edges from the overlay) plus testimony and its output carries `attestation` `{structured, plannedCells, observedCells, unmatchedObserved, onTakenPathUnobserved, unselectedPlanned[]}` with the branch-aware rule (a semantic non-fragment cell on the observed path without testimony is the failure; unselected branches and expression fragments are named, not failures) expressed in the declared read. Any runner only invokes the declared read and reports its verdict — no classification logic in `scripts/` | one migration; no new script | CV-A1, CV-B1 | invoking the declared read over the four exercised capabilities returns `attestation.structured: true` with zero on-taken-path misses; a fixture with a genuinely unobserved planned cell returns false |
| CV-E1 | E — docs | Record observations in `circuit-view-flywheel.md` (timestamps, coverage, next-capability effort) and update the register/plan | the flywheel doc, `implementation-plan-next-wave.md`, `architecture-priorities.md` | A1, B2, C2, D1 | three observations recorded with evidence or left explicitly unobserved |

Serialization: **A is serial** (one migration file at a time); **B** writes
disjoint migrations in parallel with A after A1 (the view-model shape); **C**
runs parallel to B with one writer per CLI file; **D** after A1+B1; **E** last.
No unit edits another lane's files.

## Sequencing and handoffs

1. **CV-E0** first (the layout reference must be readable).
2. **CV-A1/A2** → the view model and granularity; hand the output shape to B/C.
3. **CV-B1** and **CV-C1** in parallel (declared fragments; transport path).
4. **CV-B2** second instance; record the effort.
5. **CV-C2** retirement after B1+B2 prove declared bytes suffice.
6. **CV-D1** structural acceptance; **CV-E1** observations and register rows.

Unit commits use the implementation-strategy unit template (lane / unit /
standard / change / proof). Definition of done per the program level: proof in
the commit, no cross-lane file edits, and the flywheel observations recorded
even when they falsify the expectation.

## Rubric record (compact)

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
|---|---|---|---|---|
| `read-capability-circuit` view model from the declared graph + testimony (`implementation-plan-circuit-view.md` CV-A1) | The transistor model and the display decision ("what can be declared must be declared"); the graph is already declared | Omitting it leaves the sketch an authored per-capability document — the drift the flywheel prevents | Benefit: one generic view for every capability; attestation pair with IEA. Burden: one read capability + granularity rule | **Needed now** (the flywheel's first turn) |
| Streamed declared fragments (CV-B1/B2) | The display path's streamed entries (U4) | Omitting them keeps real-time lighting in the terminal | Benefit: declared bytes; terminal reduces to transport. Burden: per-capability declared fragments until the emitter is generic | **Needed now** for the lane; B2 measures the marginal cost |
| Terminal reduction to transport (CV-C1/C2) | The display decision's boot/terminal classification; the user direction "`render.mjs` will not exist" | Omitting it leaves presentation vocabulary in code | Benefit: one transport, any front end. Burden: byte-parity work | **Needed now** for the recording path; C2 gated on B |
| Structural acceptance (CV-D1) | The IEA record's rules; rubric §8 evidence table | Omitting it leaves the structure claim asserted, not evidenced | Benefit: planned↔observed proven per capability. Burden: one verification unit | **Useful now** |
| Second instance (CV-B2) | The flywheel's observation 3 | Omitting it leaves the flywheel unverified (one instance proves a view, not a flywheel) | Benefit: measures marginal effort honestly. Burden: one migration | **Needed now** to test the hypothesis |

## First turn results (2026-09-17)

| Unit | Status | Evidence |
|---|---|---|
| CV-E0 doc repair | **done** | `4eef918`; the tracked file was already byte-clean at HEAD (the earlier mojibake was console decoding); 0 U+FFFD, box glyphs intact, AVGO payload preserved |
| CV-A1/A2 view model | **landed, installed, refinement pending** | `35f02fd`; `read-capability-circuit` (contracts `circuit-view-request.v1`/`circuit-view.v1`, declared read + display); equity 19 nodes/18 edges; agent lane 54 nodes/53 edges; statuses verbatim. The sketch's 11-component collapse is *not* implemented — the honest simpler rule (nearest enclosing cell) ships instead |
| CV-B declared presentation policy | **landed, installed** | `6e90603`; `read-circuit-presentation` returns `circuit-presentation.v1` (box min 20 / max 40 / min rows 2 / center / hyphen-preferred wrap; the glyph set; status row; altitude prefixes; `granularity.detailCellLimit 30` — the policy constant is now authority). Finding: the six glyphs are declared as JSON `\uXXXX` escapes because the rows→runtime decode path reads UTF-8 bytes under a cp1252 collation and corrupts raw non-ASCII literals (F12); escapes decode correctly at the runtime. Connectors and the stable diagram indent are not yet in the policy |
| CV-B fragments (per-component declared text) | **pending** | the declared policy is the interim; declared text fragments remain the byte-transport target |
| CV-C1 policy-driven look | **done** | estate `b34dacb` (connectors/layout declared, installed; policy 572/572), CLI `047144e` + `d687db6`; boxes obey min 20 / max 40 columns, hyphen-preferred wrap, centering, declared glyphs; a stub policy proves the output is policy-driven (24/64 columns, S/M/P/F prefixes, OK/ERR glyphs); the policy is fetched by a second delivery before execution (~2.3 s, uncached — recorded); `--json` byte-identical; CLI 67/67 |
| CV-C1 format + mapping | **done, end-to-end, real-time** | estate `1a6ac2c` + reader gate (formats: true) + CLI `30518ee`, `abe326d`; the circuit now **replaces the trace** (no scenario/phase/span lines) and streams **box by box to stdout in execution order** (chunked pipe receipt: 37 ms → 2.6 s → 9.2 s → 10.2 s → 10.8 s, not an end dump); closing frame prints the selection branches from the declared overlay plus `EVIDENCE`; equity's overlay has no semantic-level selection edges, so its frame is evidence-only (honest reading, noted); CLI 64/64; `--json` byte-identical |
| CV-C2 render.mjs retirement | **pending** | gated on CV-B |
| CV-D1 structural acceptance | **done as declared authority** | `7965689` removed the script as UID; `b9d4499` re-declares `read-capability-circuit` with `plannedCells`/`plannedEdges` input and the `attestation` output computed in the read's own statement (ancestor closure over the JSON inputs). Live: agent lane 985/703, **misses 0, structured true**; equity 242/180, misses 0, true — exactly the first-turn values; negative fixtures (removed taken-path testimony) return **structured false with the cell named**. Honest gap recorded in the migration header: a non-fragment leaf with no observed same-altitude relative is not nameable by id hierarchy alone and needs the declared `parentCellId` chain; the bidirectional candidate closure reproduces the script's intent and the recorded positives |
| CV-E1 observations | **done** | recorded in `circuit-view-flywheel.md` §First-turn observations |

## UID audit and agent guard (2026-09-17)

Trigger: an agent task for the TUI box rules was cancelled and found to have
already written `CIRCUIT_MIN_COLUMNS`/`CIRCUIT_MAX_COLUMNS`, `circuitWrap`,
`padCenter` and the shared box helper into `sidefx-cli/src/render.mjs`
**uncommitted**. The diff was reverted unreviewed; the CLI tree is clean.
Rule applied: cancelled work is never left in the tree, and geometry policy is
not renderer code.

Audit of the committed circuit renderer (`30518ee`, `abe326d`), classified:

| Item | Class | Disposition |
|---|---|---|
| Glyph repertoire (`┌ ┐ └ ┘ ─ │ ▼ ► ×`), box drawing, connector lines | Generic emitter vocabulary (recorded phase-1 boundary: layout is not expressible in the transformation vocabulary) | Keep, but frozen: no new geometry policy in code |
| `CIRCUIT_DETAIL_LIMIT = 30` (collapse threshold) | **Policy constant = UID** | **Resolved** — declared `granularity.detailCellLimit` (estate `6e90603`), consumed (`047144e`) |
| `circuitStatus` precedence (classification → display entry → disposition → `–`) | **Duplicates declared classification = UID** | **Resolved** — classification when present, else the declared `display.entry.status` (`completed`/`failed`) mapped through the policy's glyph keys; the disposition fallback is gone. Nuance recorded: streamed events carry no `outcomeClassification`, so the streamed status source is the declared entry status |
| Box metrics/glyphs/prefixes as literals | **Presentation policy = UID** | **Resolved** — declared `box`/`glyphs`/`labels.prefixes` (`6e90603`, `b34dacb`), interpreted (`047144e`, `d687db6`) |
| `circuitLabel` / collapse derivation from `semanticAddress` and cell ids | **Duplicates `read-capability-circuit`'s nodes/edges = UID** | Deferred to CV-C2 (consume the declared view model on the full-tree path); the streamed path reads testimony verbatim |
| Frame characters (`┌ ┐ └ ┘ ─ │ ┴ ┼`), branch markers (`►`, `× NO EFFECT`), `CIRCUIT`/`BRANCH`/`EVIDENCE` labels, `(N cells)`, ms/s formatting | Emitter vocabulary not yet declared | Recorded; move with the declared fragments/extension. Policy interpretation refuses unknown values (`PRESENTATION_POLICY_INCOMPLETE`) rather than guessing |
| Streaming box-by-box, trace replacement, closing frame from the overlay, `streamedCircuit` flag | Transport (when to write, which stream) | Keep; transport carries no meaning |

**Agent guard (binding for any agent touching this area):**

1. Before writing emitter code, name the declared rows the behavior reads; if
   none exist for a choice the code makes, the choice is UID — declare it or
   record a unit, never code it.
2. No capability-specific strings, no status/classification/precedence logic,
   no policy constants, no label derivation in `render.mjs` or any emitter.
3. Geometry policy (box metrics, wrapping, justification) is **declared
   presentation authority**, not renderer code. The TUI rules below are
   specified as data; the emitter at most interprets them.
4. A cancelled or interrupted agent edit is reverted before any other work;
   cancelled work never lands.
5. Commit messages name the classification of every code change (transport /
   glyph interpretation / declared-row consumption).

## TUI box rules (declared presentation specification)

The rules the emitter must interpret, to be carried by the declared
presentation (CV-B fragments and the declared view model; not hardcoded in the
renderer):

| Rule | Value |
|---|---|
| Minimum content columns | 20 |
| Maximum content columns | 40 |
| Minimum content rows | 2 (label row(s) plus one status row; no blank filler) |
| Wrapping | at spaces within the maximum width; hyphen-preferred break inside the limit; only then a hard break |
| Justification | every content line centered; the label block centered vertically within the minimum rows |
| Status row | its own centered row: `✓ 0.104 ms`, `× 0.058 ms`, `–` (unobserved); duration verbatim |
| Connectors | vertical connector centered under the box; one `│` row then one `▼` row; branch forks keep labels above the target boxes |
| Diagram column | stable indent for the streamed view (no re-centering while boxes arrive) |

## Open decisions (builder)

1. **Granularity authority**: one generic collapse rule (scenarios +
   responsibilities + provider cells + terminal) versus a declared label map
   per capability. Recommendation: generic rule first; a label map only when a
   capability's sketch needs domain-specific component names.
2. **Layout expression**: when (if ever) the display vocabulary gains a
   declared layout block instead of the generic emitter. Trigger: a second
   front end, or a sketch that the generic emitter cannot express.
3. **Surface**: `--format circuit` on `observe` (recommended, keeps `--display`
   for the declared document path) versus making the circuit the default
   display.
