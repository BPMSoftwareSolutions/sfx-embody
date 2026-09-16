# Display projection decision record

**Method.** [sidefx-architecture-decision-rubric.md](sidefx-architecture-decision-rubric.md):
authority and applicability (§3), the necessity test *"if this is omitted, which
intended behavior fails?"* (§4), benefit/burden separated (§5), one compact row
per consequential decision (§7), and the dependency classes for the work order
(§9.3). This record dispositions the seven decisions and the migration units in
[display-projection-migration.md](display-projection-migration.md).

**Reviewer note.** The rubric is itself *proposed for team review*; this record
is the review instrument, not an admission. Dispositions below are the review
recommendation for ratification.

## 0. Authority on the record

| Source | Status / scope |
|---|---|
| Builder intent (this session): "the display is 1 — it moves into data"; "the code cannot remain in its found location" | explicit instruction for the current work; defines the requested result |
| [transistor-model.md](transistor-model.md) (0/1, no third place; boot is host seams) | applicable admitted requirement |
| [target-architecture.md](target-architecture.md) (boot = frontdoor/loader/DB/sandbox; carrier loop over declared operations) | applicable admitted requirement |
| [narration-projection-disposition.md](narration-projection-disposition.md) (rendering is terminal; layout is not meaning) | applicable admitted requirement |
| [execution-story-projection.md](execution-story-projection.md) (story contract) | applicable admitted requirement |
| [embodiment-completeness.md](embodiment-completeness.md) (mechanics per language; SDA requests only) | applicable admitted requirement |
| Migration research (`docs/display-projection-migration.md`) | inspected implementation + validated probes; evidence, not authority |

## 1. Decision ledger

One row per consequential decision. Contribution 0–3 and Evidence 0–2 per §5;
first-delivery / repetition / continuing burden / reversibility stated where
they could change the decision.

| # | Decision | Authority & scope | What fails if omitted | Benefit / burden | C/E | Disposition |
|---|---|---|---|---|---|---|
| **D0** | The display is declared (1), resolved by the kernel transformation resolver | Builder intent; transistor law | Definitionally, the decision itself | Removes F9; one mechanism; one new contract | 3/1 | **Taken** (authority for this record) |
| **D1** | Evaluation seam: reuse the already-declared delivery `resultExpression`/display transformation, no second mechanism | Delegated implementation discretion; `bind-declared-execution-delivery.sql:26` exists and is bound but unused | Nothing fails; either seam could carry it — but a second mechanism adds vocabulary and review burden | One mechanism; no new vocabulary; reversibility high | 2/1 | **Delegated implementation choice — proceed with reuse** (recorded; no approval needed again per §3) |
| **D2a** | `invoke-scenario` composition moves to the kernel | target-architecture :170–172; observed failure `SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING: 'invoke-scenario'`; SDA request R1 already filed | The model/agent lane cannot execute; the demo's two-provider story fails | Unblocks Acts 2–4; one kernel ruling for all languages; burden is the SDA change + conformance | 3/1 | **Needed now** (already filed as R1; track to landing) |
| **D2b** | The carrier loop / state-thread mechanics move to the kernel | transistor-model §3.2/§4; no current failing behavior (the estate boot is node-only by design) | Nothing today; moving it now is architecture ahead of pressure | Cleaner future boundary; burden = cross-language change with no present consumer | 1/0 | **Defer** — trigger: a second admitted language boot, or the loop holding meaning on inspection |
| **D3** | Semantic address: plan-based join now; kernel emits it with testimony later | Plan cells already carry `semanticAddress` (compiler.js:83); testimony does not; estate parses ids in `semantic-address.mjs` (declared logic in code) | Nothing — the validated sketch joins from the plan, and the stream can too | Avoids a schema change now; defers the stream's id parsing removal to the same unit | 2/1 | **Defer the kernel emission** — trigger: the next opening of the testimony schema (bundle with F1/F2) |
| **D4** | Aggregate elapsed: no `sum` request | `evidence.timings` already carries measured totals (`executeDeclaredGraph`, `processTotal`); scenario-cell duration is not the children's sum | Only a *sum of child cell durations* is missing — a metric of questionable meaning beside measured wall time | Avoids a kernel change + conformance; first-delivery effect negative if pursued now | 2/1 | **Defer `sum`** — trigger: a required display shows summed per-cell duration and measured wall time is not the intended metric |
| **D5** | Provider/physical altitudes: localize why production yielded zero cells | Resolved by investigation: SDA `6aa2434`/`171d96f` materialized the descent *after* the earlier capture; no estate defect (ports classified correctly; projection and live compile both emit 2 provider + 2 physical for equity) | Nothing - the granular-tracing claim is now supportable | Landed at the kernel; the remaining bounded `providerEvidence` passthrough is U4 (telemetry/display declaration), not a kernel request | 3/2 | **Closed** - reassign the evidence passthrough to U4 |
| **D6a** | `--json` additive: `display.document` joins `story`/`overlay` | Existing consumers, tests, receipts rely on the result shape | The CLI migration cannot prove parity; or consumers break | Smallest sufficient change; reversibility high | 2/2 | **Needed now** |
| **D6b** | Remove/replace `story`/`overlay` | Public result shape | Nothing now; removal only simplifies once no consumer needs them | Reduces duplication once the document is the view; removal is semi-irreversible | 1/2 | **Defer** — trigger: U5 parity plus one release with no consumer (or re-declare as views of the document) |
| **D7** | Streamed status: declare `disposition`/`outcomeVariant` in the telemetry authority and attach a display entry per event | Truthful result reporting (§4); observed: streamed cells print ✓ regardless of outcome | The observe stream misleads during execution (the equity unavailable run showed all ✓) | Small, testable; the fields are not secrets; burden = one authority declaration + emitter entry | 2/2 | **Needed now** (inside U4) |
| **D8** | New declared vocabulary: the `sfx-display-document.v1` contract and closed block types | Builder intent; §2 vocabulary review — one document type, no registry/service | Without a closed block vocabulary the CLI cannot emit without branches, and tests cannot assert | Enables branchless byte emission and byte parity; one contract, reversible | 2/1 | **Needed now** (smallest sufficient form: one contract) |

## 2. Work-order dependency classes (§9.3)

| Unit | Class | Treatment |
|---|---|---|
| U1 — contract + `say-hello-world` display transformation + interface + boot attachment + byte parity | Execution/delivery necessity for the new display behavior; the smallest complete loop | **Keep — land first** |
| U2 — equity display (status derivation, `PROVIDER_UNAVAILABLE` reason, `--display` value) | Delivery necessity for the demo's primary capability | **Useful now**; sequence after U1 parity; required before the demo |
| U3 — reader documents (`reveal`/`list`/`find`/`catalogue`/`circuit`/`artifact`); CLI `meaningLines`/`capabilityLine` leave | Delivery necessity for the CLI reduction; no new behavior | **Useful now**; defer trigger: scope pressure before the demo |
| U4 — streamed entries + declared reading selection + telemetry fields (D7) | Delivery necessity for a truthful observe stream | **Needed now** for the demo's observe beat |
| U5 — boot/CLI reduction, dead-code deletion (`digest`, `isEstateDelivery`), test rewrites | Closure of the directive ("the code cannot remain") | **Needed now**, sequenced last; depends on U1–U4 having replaced each branch |
| U0 — `sum` / `order-by` requests | Deferred per D4/D3; not the loop | **Not necessary** now |
| Session-policy rows (`database-read-session.mjs` constants) | Validation/policy necessity, unrelated to the display loop | **Defer** (already tracked in `architecture-priorities.md`) |

## 3. The loop this migration must close (§9 spirit)

The display analogue of the six-event SQL→CLI loop:

1. Declare the display transformation in rows.
2. Invoke the capability with the unchanged CLI; **observe declared bytes**.
3. Change a display fact **in rows only** (label, surface, lane field).
4. Re-invoke with the unchanged CLI; **observe the changed bytes** — no
   capability-specific source edit in the estate or the terminal.

U1's acceptance includes this two-step proof, not only byte parity. A display
that still requires a source edit to change fails the loop and is not done.

## 4. Reviewer summary

**Needed now:** the display decision's first slice — U1 (with the D8 contract),
D6a additive `--json`, D7 streamed status fields inside U4, and the D5
provider/physical investigation (closed: the kernel materialized the descent; the
`providerEvidence` passthrough moves to U4). D2a is needed now and already filed
as SDA R1.

**Helps now:** U2 (equity) before the demo; U3 (reader documents) when scope
allows; D1's reuse of the existing declared seam.

**Deferred, with observable triggers:** D2b (carrier loop — second language
boot), D3 (kernel address — next testimony-schema opening, bundle with F1/F2),
D4 (`sum` — summed per-cell duration required and wall time not the metric),
D6b (`story`/`overlay` removal — post-parity, no consumers), U0 requests
(not necessary now).

**Builder decisions needed (outside delegation):**

1. Ratify the deferrals D2b/D3/D4/D6b with their triggers (they set future
   obligations).
2. Approve the new declared vocabulary name/version
   `sfx-display-document.v1` (small but public).
3. Approve the first-wave scope: U1 alone, or U1+U2+U4 before the demo
   (recommended: U1 parity first, then U2+U4).
4. Confirm the demo's elapsed line is measured wall time from `evidence.timings`
   (per D4), not a declared sum.

**Observed result after implementation** is appended here beside these
predictions once U1 lands (rubric §1: compare predictions with actual delivery).

## 5. Observed result after implementation (U1, 2026-09-15)

- **Declared and installed:** `sql/migrations/declare-observation-display-projection.sql`
  — contract `sfx-display-document.v1`; transformation
  `say-hello-world-observe-display.v1`; the interface `display` switched from
  `{select, as}` to `{transformationId, as}`. The one boot seam resolves the
  declared transformation from the graph source and evaluates it with the
  kernel's declared-expression evaluator (the same mechanism as the delivery
  result expression), attaching `outcome.display.document` additively.
- **Loop proof, rows only:** the heading label changed in one migration
  (`change-hello-world-display-heading.sql`) and was observed in production
  (`"Observed scenario say-hello-world"`), then reverted
  (`revert-hello-world-display-heading.sql`); no source edit at any point. The
  revert leaves a new definition version whose expression is byte-identical to
  the U1 declaration.
- **Byte parity:** the terminal emitter landed with 43/43 CLI tests, including a
  receipt-parity test against `observe-say-hello-world-trace.stdout` (timings
  normalized because the receipt is a separate run). Live
  `sfx capability observe say-hello-world` prints the document; `--json` is
  additive (`story`, `overlay`, `observedPathDigest` unchanged).
- **Deviation from prediction:** `--trace` text now emits the document's `tree`
  block and the terminal no longer appends its legacy trace — the declared
  reading owns the selection. One CLI test asserted the opposite and was
  corrected. The reading selection itself is still derived in the boot from the
  request vocabulary (declaration gap; U4 declares it).
- **D5 closed, not by estate work:** provider/physical cells were materialized by
  SDA `6aa2434`/`171d96f`; live observe streams 2 provider + 2 physical cells for
  equity. The bounded `providerEvidence` passthrough remains U4.

## 6. Evidence index

- Migration map and line-referenced inventory: `docs/display-projection-migration.md`.
- Loop prior art and dependency classes: `sidefx-architecture-decision-rubric.md` §8, §9.
- Observed stream mis-marking: `observe --observation-altitude provider` on equity
  (zero cells) and the story's all-✓ display during `PROVIDER_EXCHANGE_NOT_COMPLETED`.
- Existing declared seam for D1: `sql/migrations/bind-declared-execution-delivery.sql:26`.
- Vocabulary validation: the two compiled/evaluated sketches in
  `docs/display-projection-migration.md` §4.
