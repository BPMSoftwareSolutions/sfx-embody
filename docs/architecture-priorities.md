# Architecture priorities

**What this document is.** The ordering view over the authorities that already
decide this repo's work. It adds no requirement and settles no design question: if
it conflicts with an authority doc, the authority doc wins. Its job is to keep
"what do we build next, and why" answerable in one page, on top of four documents
that are each right but dense.

- [target-architecture.md](target-architecture.md) — what the target is.
- [embodiment-completeness.md](embodiment-completeness.md) — every executable
  mechanic in code, per language; agents must not edit SDA; change requests only.
- [transistor-model.md](transistor-model.md) — the 0/1 law, the resolver floor, and
  the standing SDA request register (§10).
- [target-experience.md](target-experience.md) — the primary experiences, the
  subtraction phase, the three buckets, the flywheel proof.
- [sidefx-architecture-decision-rubric.md](sidefx-architecture-decision-rubric.md) —
  how a decision is accounted for (§4 necessity test, §9 SQL→CLI loop).
- [next-experiences.md](next-experiences.md) — the four coming experiences and the
  classification of every remaining deliverable (data / boot / SDA request).
- [implementation-strategy.md](implementation-strategy.md) — lanes and the unit
  queue; [performance-optimization.md](performance-optimization.md) — invocation
  cost.

**Status date.** 2026-09-15. Counts and file names below are receipts, not
promises; re-verify before quoting.

## 1. The three tests every unit must pass

1. **Transistor (0 or 1).** Is the behavior declared authority (1) or an admitted
   resolver (0, per language)? There is no third place. If it is neither, it is a
   defect: declare it or resolve it. Adding a mechanic is an SDA change; binding
   one is data. Adding a language adds resolvers, never a language-specific
   declaration.
2. **Rubric (§4).** *"If this decision is omitted from this slice, which intended
   behavior or applicable requirement fails, and why?"* "Future extensibility",
   "consistency" and "best practice" do not demonstrate a present dependency.
   Dispositions: needed now / useful now / defer (with an observable revisit
   trigger) / outside current intent / builder decision. The six-event SQL→CLI
   loop is the measure for authoring work.
3. **Flywheel.** Does the next capability get materially cheaper, faster, clearer?
   One demonstration proves the interaction; the flywheel is proven only when B was
   materially easier because A was built. First-delivery effect, repetition effect,
   continuing burden and reversibility are measured separately.

**Hard constraints (never traded away):** no SDA edits (requests only); no facade
language — a passthrough is not an embodiment; no materialization on the invocation
path; one coherence pin per invocation; projected-body rows stay off the hot path;
proof is invocation, not a green in isolation; one migration per commit, installed
only after the from-transaction preflight; never fake green — an honest "blocked"
is a deliverable.

## 2. Where the estate is (honest, 2026-09-15)

| Surface | State |
|---|---|
| Invocation | one path; bounded capability read + one pinned reader session; kernel interprets the declared graph; `invoke`/`observe` share code; EPD streams cell/edge testimony at selectable altitudes and returns the planned-vs-observed overlay + `observedPathDigest`; tests 47 pass / 3 database-gated skips |
| Authoring | SQL plus the JSON surface (`model.declare_capability_document`; two JSON-authored capabilities installed); the mutation→invoke flywheel is not yet proven (no second-capability effort comparison) |
| Projection | `sfx capability project` is the native command; `--full-mechanics` selects the per-language execution emitters; `--codegen-pattern` is a declared repeatable option; the manifest carries per-file `digest` + `sourcePointers`; 137/137 slots bound, `PURE_PROJECTION_CONFORMS` |
| DB copy of bodies | installed as a generation-keyed artifact set (51 bodies: 15 node, 12 python, 16 csharp, 8 shared) with `source_class='PROJECTED_BODY'` rows and content-addressed bytes; proven off the hot path; the installed migration is 8.5 MB (see F5) |
| Perf comparison | `scripts/projected-performance.mjs` reports whole-invocation median/p95 and cross-target parity for node/python/csharp; per-cell time is blocked on generated-testimony timing (F1), and `scripts/verify-projected-testimony.mjs` is the closure probe |
| Resolver seams | closed (G7): `sql/inspect/hand-authored-module-references.sql` reports zero rows; the boot resolves a port with no `estateProvider` from the declared per-language mechanic registry |
| Presentation | no estate UI-authority store or pipeline; the login-flow capability is the first expected (target-experience §3) |
| Bootstrap | Node-only; the projector emits node/python/csharp, so three bootstraps are owed (transistor-model §6, §9.1); a language is a supported runtime only once admitted |

## 3. Priority queue

### Now — status of the three items opened 2026-09-15

1. **Per-cell timing and testimony parity in generated bodies (F1, F2) — filed.**
   SDA emitters only. The request is
   [sda-change-request-projected-testimony.md](sda-change-request-projected-testimony.md):
   node `capability-execution-emitter.ts` (`recordPatternTestimony`,
   `recordCellTestimony`, `recordEdgeTestimony`), python `_record_cell`/
   `_record_edge`, csharp `RecordEdge`/`RecordCell`, stamping the kernel
   schedulers' existing `startedAt`/`completedAt`/`durationMilliseconds`. The
   closure probe `scripts/verify-projected-testimony.mjs` reports `TESTIMONY OPEN`
   today: timing absent on every record in all three targets; python
   `observedPathDigest` null; csharp omits it and `resolverTestimony`; cell-id
   sets differ (node 8 / python 111 / csharp 5, with 70 python ids semantic-id
   normalized forms). This is the only item blocking the §1 experience's last leg.
2. **Residual resolver seams (G7) — closed.** `sql/inspect/hand-authored-module-references.sql`
   reports zero rows: 22 ports freed, 8 module carriers and 7 estate-module
   PROVIDER rows deleted (target disposition: elimination; deleted resolvers were
   not restored), and the boot resolves a port with no `estateProvider` from the
   declared per-language mechanic registry. All 15 touched capabilities compared
   pre/post with identical dispositions and `observedPathDigest`s; tests 47/50.
3. **The flywheel proof — observed.** `read-declared-capability-document` (B) was
   JSON-authored on the back of A in 95 seconds from T0 to a verified CLI
   invocation with zero failed attempts; [flywheel-proof.md](flywheel-proof.md)
   records the three rubric observations, the reuse/new-maintenance inventory, and
   the scope limit: proven for the declared-read JSON shape, not for pure-mechanics
   or provider-backed capabilities, and the install lifecycle cost did not drop.
4. **Display projection migration — U1 landed (2026-09-15).** The
   `sfx-display-document.v1` contract, the `say-hello-world` display
   transformation, the interface switch and the one boot seam are installed,
   with byte parity and the rows-only loop proof recorded in
   [display-projection-decision-record.md](display-projection-decision-record.md)
   §5. D5 closed: the kernel materialized provider/physical descent (SDA
   `6aa2434`/`171d96f`). U2 (equity display, estate `099e48a`) and U4 (declared
   readings + streamed `display.entry` + bounded `providerEvidence`, estate
   `4a6049e`/`7f5cfa2`, CLI `783723b`) landed 2026-09-16. Next: U3 (reader
   documents) and U5 (boot/CLI reduction); the map is
   [display-projection-migration.md](display-projection-migration.md).

### Next — the experiences behind the current one

4. **JSON authoring friction** (target-experience §primary 1): every new stored
   procedure must name the recurring authoring action it removes friction from;
   otherwise it waits.
5. **Presentation pipeline** (target-experience §primary 3): the login-flow
   capability's UI-authority rows, framework never in authority.
6. **Per-language bootstraps** for the three admitted projection targets
   (transistor-model §6, §9.1; next-experiences §2), on admission, not before.

### Deferred with triggers (demotion, not refutation)

| Item | Revisit trigger |
|---|---|
| Inverse projection (DB → declaration JSON) | a measured recurring need; today only bridges exist |
| Long-lived delivery host (no per-invoke spawn) | measured spawn/re-import cost on the critical path |
| Full JSON workspace reconstruction | a consumer that cannot read the staged workspace |
| Native-body materialization as an invocation mechanism | never — kernel interpretation is the target rule |
| Additional UI targets / generic frameworks | the login-flow slice exposes a measured recurring gap |
| Sealed bootstrap binary | distribution requirement; does not substitute per-language bootstraps |

## 4. SDA change-request register (agents never edit SDA)

Format per `embodiment-completeness.md`: primitive / why kernel / affected
languages / data that binds it / evidence.

| # | Request | Status |
|---|---|---|
| 1 | Declare resolver boundaries in each `languages/*/binding/*.binding.json` (G1) | open |
| 2 | Wire the repository-wide sterility gate; add `.go` to the evaluator (G2, G5) | open |
| 3 | Language-level missing-resolver admission (G3) | open |
| 4 | Publish the mechanic taxonomy authority; end the duplicated twelve names (G4) | open |
| 5 | Per-language mechanic-registry loader + bootstrap surface (G6) | open |
| 6 | `sourcePointers` in the published manifest + portable seam specifier | `sourcePointers` landed in `projection-manifest.json`; portable seam open |
| 7 | Generated testimony must carry `durationMilliseconds`/`startedAt`/`completedAt` (F1) | request filed: `docs/sda-change-request-projected-testimony.md`; probe reports OPEN |
| 8 | Testimony parity across projected targets: `observedPathDigest`, `resolverTestimony`, granularity (F2) | request filed with item 7; probe reports OPEN |
| 9 | Projector DB artifact target and uniform timing emission (next-experiences §1) | open |
| 10 | Stale C++ inventory correction (G8, G10) | open (doc-level) |

## 5. Findings register

| # | Finding | Class | Evidence |
|---|---|---|---|
| F1 | Projected bodies record cell/edge/resolver testimony with digests and logical order but **no timing fields** in node, python or csharp | SDA emitter request — filed | `docs/sda-change-request-projected-testimony.md`; `scripts/verify-projected-testimony.mjs` OPEN report (timing absent on every record) |
| F2 | Projected testimony is not cross-language parity: python `observedPathDigest: null`, csharp omits it and `resolverTestimony`, cell-id sets differ (node 8 / python 111 / csharp 5; 70 python ids semantic-id normalized) | SDA emitter request — filed | probe report; generated bodies |
| F3 | Codegen-mode patterns are rendered locally by the tools emitters (sync renderers cannot invoke Python/C# at projection time); node output is byte-identical to the registered resolver `emit`, python/C# are semantically verified only | Pin before any digest-bound release | `docs/capability-command-surface.md` §Projection |
| F4 | Generated bodies import the SDA runtime through generation-depth-relative paths; a moved body resolves only at its generation depth | SDA request (portable specifiers) | node body imports; manifest carries `sourcePointers`, not portability |
| F5 | The database copy is installed as an 8.5 MB migration, so the bodies live in git twice (files + rows) | Revisit trigger: a persistence path replaces the generated migration | `sql/migrations/publish-projected-bodies-*.sql`; `scripts/publish-projected-bodies.mjs` |
| F6 | The declared RapidAPI credential is rate-limited to zero (429, ~20.8-day reset), so the live equity acceptance cannot be reproduced until reset; invocation behavior is otherwise unchanged (identical pre/post disposition, digests) | Environment — **routed around**: the fallback route (estate `9230b83`) resolves through `yahoo-finance-real-time1` while 166 is rate-limited; the quota remains the primary's condition and the demo's fallback trigger | preflight/invoke receipts; quota headers; `docs/declare-provider-fallback-validation.md` |
| F7 | Three execution-graph capabilities (`compile-declared-authority`, `execute-semantic-execution-graph`, `execute-semantic-value-graph`) still fail the CLI path with `SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING` for their own mechanic id; pre-existing and independent of G7 (the kernel binds cells by `platformCapabilityId`, never by `providerId`) | Estate overlay-completeness unit | G7 receipts; `execute-declared-capability` shows the same failure before and after the module rows left |
| F8 | JSON authoring friction FF1–FF6: `cmd /c` input quoting, a migration is required to install a document, file/SQL-literal byte duplication with no keeper, scaffold residue rendered by `reveal`, no declared absence convention, concurrent-writer conditions | Authoring-surface units | `docs/flywheel-proof.md` |
| F9 | The observation display executes as code outside the kernel: status derivation, lanes, ordering and semantics in `src/execution-drilldown.mjs`, `src/semantic-address.mjs`, `src/observation-filter.mjs`, `src/invoke-database-capability.mjs` and `sidefx-cli/src/render.mjs` | Declared-authority migration (decision: the display is 1) — U1 landed 2026-09-15 (contract + hello-world transformation + boot seam + byte parity + rows-only loop proof) | `docs/display-projection-migration.md`; `docs/display-projection-decision-record.md` |
| F10 | Physical-altitude cells re-invoke platform effect ports with the provider cell's outcome, and the mechanic cell surfaces that artifact: the equity run shows `BOUND` at provider altitude overridden by `CREDENTIAL_NOT_AVAILABLE` at physical altitude, with `exchangeCount: 0` — no HTTP attempt, so the quota is not the cause | **Landed** — SDA `1dd253d`; live verification 2026-09-16 (`BOUND` at all altitudes; primary exchange `retained-non-success` with `exchangeCount: 1`); the fallback route installed on it resolves through real-time1 (estate `9230b83`) | `docs/sda-change-request-effect-altitude-execution.md`; `docs/declare-provider-fallback-validation.md` §4–5 |

## 6. How a unit lands (unchanged, for quick reference)

Evidence first (a readable bundle or an extracted generation that worked) → one
idempotent `.sql` migration that drops the guard triggers inside its own
transaction and ends in `ROLLBACK` → dry-run with `scripts/run-migration.mjs` →
preflight the uncommitted state with `scripts/invoke-from-transaction.mjs` (same
disposition as production) → flip to `COMMIT` and install → verify through
`sfx capability invoke --json` (captured through `cmd /c`) → commit with the unit
template (lane / unit / standard / change / proof). **Proof debt** is machinery
that remains after the uncertainty it answered is resolved: keep the evidence,
delete the ceremony from the live path.
