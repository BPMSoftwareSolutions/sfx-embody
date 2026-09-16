# Display projection migration — the change map

**The decision.** The observation display is declared authority (1). Status
derivation, altitude lanes, GIVEN/WHEN/THEN ordering, and which outcome
variant/evidence surfaces become a **declared display projection** — a
transformation over the carrier + testimony, resolved by the kernel. No code
keeps its found location: **rows for the projection, seams only in the boot,
bytes only in the CLI.** A missing interpretation mechanic is the one SDA
request; otherwise nothing here is a kernel gap.

**Status date.** 2026-09-15, estate `e4ad16f`. Research read-only, three agents;
no database writes. Line references come from that pass and must be re-checked
before editing.

## 1. Verdict (decisive)

- **The declared vocabulary can express the display.** Two frame elements were
  compiled and evaluated against the real `say-hello-world` carrier and
  testimony with the installed kernel resolver: the WHEN responsibility lane
  (join by `cellId` + `execution.configuration.portId`, declared order,
  disposition/timing) and status derivation (`completed + retained-non-success`
  → `completed-with-finding`, `mark`, `reasonCode`) — both schema-valid, both
  producing the expected values.
- **Two things are not expressible**, and only conditionally needed:
  **numeric aggregation** (no `sum`/fold/arithmetic — the scenario's elapsed
  total from child cell timings) and **runtime keyed ordering** (no `order-by` —
  avoidable by iterating declared authority, which the recommended mechanism
  does). The one SDA request, if the display must show aggregate elapsed, is
  **`sum`** (resolver 0, node/python/csharp).
- **The display needs the plan in scope.** Testimony alone (cell ids) cannot be
  joined to declared responsibility without parsing kernel-generated ids; the
  compiled plan already carries `semanticAddress` and
  `execution.configuration.portId`. The scope is: `authority` (graphSource) +
  `plan` + `execution` (result/testimony) + selection/input.
- **Where it executes:** as a declared transformation evaluated at the
  invocation boundary — not terminal-side, not a second DB round-trip, not a
  new mechanic. The interface declares *which* transformation and how to render
  it; the kernel resolves it; the boot invokes and attaches; the CLI prints
  bytes.

## 2. Target data flow

```
declare: capability authoring + interface configuration
  <cap>-display.v1  (TRANSFORMATION; semantics.expression)
  cli interface display = { "transformationId": "<cap>-display.v1", "as": "json|text" }

invoke/observe (boot seams only)
  read declaration (declared reads) → compile/execute (kernel) → carrier
  scope = { selection, selected, scenarioInput, rootExecutionId,
            authority, plan, execution }        // plan captured via onState
  kernel resolves the declared display transformation once
  outcome.display = { document: <sfx-display-document.v1> }

terminal (bytes only)
  emit blocks: heading/field/lane/tree/list/display/line/blank
  bytes = glyphs, padding, indentation, separators, stream routing
```

`--json` stays canonical and additive: `story`/`overlay`/`observedPathDigest`
are unchanged; `display.document` joins them. `--display` prints the declared
value instead of the terminal evaluating `select`. `--trace` and
`--observation-altitude` become **declared reading selections** (default
reading / trace reading / named altitudes) that the CLI forwards, not CLI-side
maps.

## 3. Where every change goes

### 3.1 Estate rows (declared, 1)

| Declaration | Shape | Replaces |
|---|---|---|
| Display transformation per capability (or shared) | `model.put_semantic_definition 'TRANSFORMATION'` envelope + `model.normalize_transformation_expression`; expression `{op:"object", fields:[...]}` over the scope; port binding to `sda-authority-transformation-port.v1` | status derivation, lane assembly, ordering, nesting, field selection now in code |
| Display document contract | `sfx-display-document.v1` (schema/contract): typed blocks with already-derived labels/values/statuses/timings | the CLI's shape guessing and label branches |
| Interface `display` | `{transformationId, as}` replaces `{select, as}` (`declare-equity-cli-input.sql:44` is today's example) | terminal-side `select` evaluation (`render.mjs:64-65, 87-90, 210-213`) |
| Reading selection | default reading (scenario), trace reading (all), altitude names — declared on the operation/interface | `cli.mjs:102-110` trace→altitudes map; `commands.mjs:9` altitude enum; `execution-drilldown.mjs:9` duplicate |
| Request/operation spec | operation table, view/format/altitude applicability (one declaration, not three) | `invoke-database-capability.mjs:184-233` + `config/sfx.commands.json` + `sidefx-cli/src/commands.mjs:10-12` triplication |
| Telemetry authority | the streamed observation fields, including `disposition`/`outcomeVariant` (today absent, so every streamed non-mechanic cell prints ✓) | `observation-filter.mjs:3-10` allowlist |
| Session policy | rowLimit bounds, `MEMORY_ONLY`, `sorted-multiset-per-recordset.v1` | `database-read-session.mjs:26-57` constants (later unit) |

### 3.2 Boot — what leaves, what remains

| File | Leaves (target home) | Remains (seam, 0) |
|---|---|---|
| `src/invoke-database-capability.mjs` | operation spec + defaults (:184-204 → rows); validation spec (:206-233 → declared request contracts); `buildCanonicalInput`/`setInputPath`/`INPUT_TYPES` (:162-182 → transformation); interface reader (:39-83 → declared read); port/composition dispatch (:112-147 → kernel where mechanical, rows where declared); selection/reader/input/display/shaping (:274-397 → rows + projection); delete dead `digest` (:7) and `isEstateDelivery` (:85-106) | stdin/stdout envelope, dynamic imports, session/coherence wiring, callback wiring, `run-declared-graph` invocation, `display.document` attachment |
| `src/execution-drilldown.mjs` | altitude selection, address join, overlay/story construction (:9-231) → declared transformation + kernel testimony | onTestimony/onState/absorb plumbing |
| `src/observation-filter.mjs` | allowlist (:3-10) → declared telemetry authority | safe-string filtering application |
| `src/semantic-address.mjs` | all (:6-127) → plan `semanticAddress` join (no id parsing) | none |
| `src/read-authority.mjs` / `read-execution-delivery.mjs` | SQL constants + `defaultTarget` (:5-22 RED; :23-128 RA) → declared reads | readQuery execution |
| `src/database-delivery.mjs` | deliver-phase labels (:38-58 timings shape) → declared telemetry; env credential copy (:30) is a named defect | envelope, DB driver import, sandbox, session, transport |
| `src/database-read-session.mjs`, `restrict-memory-process.mjs` | policy constants → declared rows (later) | session/sandbox mechanics |

### 3.3 CLI — what leaves, what remains

| Leaves (to rows or the document) | Remains (bytes only) |
|---|---|
| `semanticLine` labels/marks/admission; `renderObservation` semantic/mechanical branch (:23-45) | control-char stripping, JSON pretty, `\n` joins, `SFX_OBSERVATION` parsing/routing |
| `capabilityLine` (:48-59); `responsibilityLine`/`storyLines` incl. hardcoded THEN ✓ (:64-92) | indentation and spacing once block text is declared |
| `traceLines` tree building/sorting/labels (:175-202) | glyph constant table (status token → character) |
| `meaningLines`, `parseJson`, `ABSENT` (:94-170) | heading style (`##`/underline) per declared `as` |
| `format` dispatch, `rows` probing, narrative branch, project report composition (:204-237), `select` (:64-65) | one emitter over `display.document`; `pretty` fallback for unknown shapes |
| `cli.mjs:102-110` trace/altitude mapping; `commands.mjs:9` enum; `operandHint`/help prose (:48-72) | option grammar, mapping load/validation, error output |

### 3.4 Kernel (SDA) — what, if anything

- **`sum` (conditional, the one request).** `{op:"sum", from, as, value}`:
  ordered numeric reduction, refuse non-array/non-numeric, pin IEEE-754
  binary64, empty → 0. Why kernel: numeric representation/rounding differs per
  language; parity requires one ruling. Node/python/csharp conformance vectors.
  Request only if the display shows aggregate elapsed; per-cell and scenario-cell
  timings are already data.
- **`order-by` (conditional, likely avoidable).** Request only if ordering must
  come from a runtime field rather than declared iteration; the plan's cells are
  lexically sorted, which is wrong for ≥10 operations (`.operation.10` before
  `.operation.2`).
- **Provider/physical evidence (resolved, 2026-09-15).** The compiler and
  scheduler support provider/physical cells and bounded `providerEvidence` for
  effect ports (`compiler.js:209-265`, `scheduler.js:8-20,358-384`); SDA
  `6aa2434`/`171d96f` materialized the descent after the earlier capture, and live
  observe now emits 2 provider + 2 physical cells for equity and streams them at
  those altitudes. Remaining: the bounded `providerEvidence` fields are not yet
  passed through the observation allowlist/drilldown (U4), and the display
  projection may surface them once they are.

## 4. Vocabulary feasibility — the matrix in brief

Validated against `SDA:kernel/schemas/semantic-transformation-authority.schema.json`
(32 admitted ops, `additionalProperties:false`) and the three embodied evaluators
(node/python/csharp, 157/157 conformance vectors).

| Display feature | Verdict | Op(s) |
|---|---|---|
| Status derivation from disposition/outcomeVariant | expressible | `if` + `equals`/`includes` + `object` |
| GIVEN/WHEN/THEN blocks and order | expressible | `object` (key order preserved) + `literal` + declared iteration |
| Responsibility lane: join testimony by cell | expressible **with plan in scope** | `filter`/`find` + `equals` on `cellId`/`portId` |
| Order responsibilities | expressible by declared iteration; **not by runtime field** | `map` over `executionAuthorities[].operations` |
| Nest composed scenarios | expressible as ordered block arrays | `map`/`filter` on `parentScenarioId`; no dynamic keyed maps |
| Select variant/evidence surfaces | expressible | `if` + `find` + `object`; encode `{fieldId, value, surface}` for omission |
| Structured blocks, labels, indentation hints | expressible | `object`/`array`/`literal`/`format`/`join` |
| Per-cell elapsed | expressible | `path durationMilliseconds` |
| Aggregate elapsed | **not expressible** | needs `sum` (request) |
| Runtime keyed ordering | **not expressible** | needs `order-by`, or avoid |
| String transforms beyond trim/lower/includes/format | not expressible | keep labels pre-shaped in rows where possible |

Worked sketch (validated): WHEN lane —

```jsonc
{"op":"map","from":{"op":"path","from":{"op":"path","from":"authority","path":"executionAuthorities.0.operations"},"path":""},
 "as":"op","value":{"op":"object","fields":{
   "responsibilityId":{"op":"path","from":"op","path":"portId"},
   "cellId":{"op":"path","from":{"op":"find", "...":"plan cells by parent+portId"},"path":"cellId"},
   "disposition":{"op":"path","from":{"op":"find","...":"testimony by cellId"},"path":"disposition"},
   "mark":{"op":"if","when":{"op":"equals","left":"…disposition","right":"completed"},"then":{"op":"literal","value":"✓"},"else":{"op":"literal","value":"×"}}}}}
```

## 5. Display document contract (`sfx-display-document.v1`)

```
{ "documentType": "sfx-display-document.v1", "blocks": [ Block ] }

Block =
  heading {text} | field {label,value,note?} | lane {label,entries} |
  tree {label,entries} | list {items,emptyText?} | display {as,value} |
  line {text} | blank
Entry = { status?, text, note?, admission?, timing?, children? }
```

The document carries derived labels/values/statuses/order; the CLI owns only
characters (glyph table, padding, indentation, heading style, stream routing).
`Entry.status` is a declared token (`completed|failed|unobserved|…`), never a
glyph; the glyph is a terminal constant.

## 6. Migration sequence (one migration per commit)

| Unit | Content | Acceptance |
|---|---|---|
| U0 | Decide `sum`/aggregate elapsed; file the request if needed | request format; no rows yet |
| U1 | `sfx-display-document.v1` contract + `say-hello-world` display transformation + interface `display.transformationId` + boot attachment at the invocation boundary | byte parity for the `observe-say-hello-world` fixture (carrier → document → old stdout); `--json` additive; tests |
| U2 | Equity display (status derivation, `PROVIDER_UNAVAILABLE` reason, evidence surfaces) + `--display` value | byte parity on equity fixtures; preflight from-transaction |
| U3 | Reader operations (`reveal`/`list`/`find`/`catalogue`/`circuit`/`artifact`) return documents; delete `meaningLines`/`capabilityLine`/`format` dispatch | byte parity on reader fixtures |
| U4 | Streamed observation entries + declared reading selection (default/trace/altitudes) + telemetry authority fields | stderr parity; altitude selection tests |
| U5 | Boot reduction (delete dead code; files left as seams) + CLI reduction; rewrite `render.test.mjs`/`observe-presentation.test.mjs` | `npm test` both repos; no semantic branch left in the CLI |

**Byte-parity method.** Pair each real receipt (carrier + expected bytes from
`evidence/demo-*`), render the document with the new emitter, assert
byte-for-byte equality; for streams, feed each `SFX_OBSERVATION` entry through
the emitter. Timings are compared structurally (live runs differ), declared
values exactly. Fixtures live in the CLI repo so its tests are estate-free.

## 7. Open decisions (team)

Dispositioned under the decision rubric in
[display-projection-decision-record.md](display-projection-decision-record.md)
(needed now / useful now / defer with triggers; builder decisions listed there).
The recommendations below remain the technical input to that record.

| # | Decision | Recommendation |
|---|---|---|
| D1 | Evaluation seam: reuse the delivery `resultExpression` (already declared, bound but unused) vs a separate display transformation id | use the declared display transformation referenced by the interface; if the delivery seam fits, prefer it and avoid a second mechanism |
| D2 | Carrier loop (`executeEstateCapability` port/composition dispatch): boot loader or kernel? | keep as the loader's minimal execution shell; move `invoke-scenario` composition to the kernel (already requested as R1 in `sidefx-public-demo-readiness.md`) |
| D3 | Semantic address source: kernel emits it with testimony vs plan-based join | plan-based for the document (validated); kernel-attached address for the live stream is a separate request |
| D4 | Aggregate elapsed definition | per-cell timings first; file `sum` only if the display must show a total |
| D5 | Provider/physical localization | closed: kernel materialization landed (SDA `6aa2434`/`171d96f`); `providerEvidence` passthrough is U4 |
| D6 | `--json` shape | additive `display.document`; `story`/`overlay` stay for compatibility, deprecate later |
| D7 | Streamed status fields | declare them in the telemetry authority and emit the display entry per event |

## 8. Evidence index

- Boot inventory with line refs: this document §3; sources `src/invoke-database-capability.mjs`, `execution-drilldown.mjs`, `observation-filter.mjs`, `semantic-address.mjs`, `database-delivery.mjs`, `read-authority.mjs`, `read-execution-delivery.mjs`, `database-read-session.mjs`.
- CLI inventory and document shape: §3.3, §5; sources `sidefx-cli/src/render.mjs`, `cli.mjs`, `commands.mjs`, `index.mjs`, `delivery.mjs`.
- Vocabulary: `SDA:kernel/schemas/semantic-transformation-authority.schema.json:31`; evaluators `languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs`, `languages/python/src/scenario_kernel/adapters/semantic_transformation_evaluator.py`, `languages/csharp/src/ScenarioKernel.Adapters/Consumer/SemanticTransformationEngine.cs`; conformance `docs/cross-target-embodiment.md:25,73,88`.
- Prior art: `sql/migrations/declare-read-capability-meaning.sql:41-53`, `declare-list-capabilities.sql`, `optimize-list-capabilities-read.sql`, `restore-equity-normalize-expression.sql:22-35`, `bind-declared-execution-delivery.sql:26`.
- Real carriers/bytes for parity: `evidence/demo-2026-09-15T14-23-18.443Z/` (`observe-say-hello-world-trace.stdout/stderr`, `observe-say-hello-world-json.stdout`, `reveal-*`, `list-capabilities`, `find-scaffold`).
- Adjacent requests: `docs/sda-change-request-projected-testimony.md` (F1/F2), `docs/sidefx-public-demo-readiness.md` (R1/R2/R4), provider/physical altitude thread.
