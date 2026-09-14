# Timing review: which architecture decisions were premature

## 1. The rubric's method (extracted)

**Starting constraint (minimality).** Begin with the least functionality that carries the intended Input → Event → Outcome to an observable result; zero/one/many providers only as the outcome requires; preserve required mechanic references; a fixture at an unresolved boundary must be labelled. Minimality does **not** authorize dropping required steps or changing topology (`sidefx-architecture-decision-rubric.md:11-21`). The initial decision need not design the eventual architecture; further structure is warranted only when actual needs/evidence/obligations support it (`:23`, `:34`).

**Scales.**
- **Contribution 0–3** (`:111`): 0 no connection; 1 indirect/future; 2 directly supports a named current step; 3 necessary to a named current step **or observed** to improve a subsequent cycle.
- **Evidence 0–2** (`:112`): 0 untested hypothesis; 1 inspected implementation/measurement/supported estimate; 2 observed in the target or a comparable cycle. Benefit and burden scored **separately**.
- Plus first-delivery effect, repetition effect, continuing burden, reversibility, distribution (`:113-117`). Scores are never summed with hours/risk (`:119`).

**Operational test (necessity).** "If this decision is omitted from this slice, which intended behavior or applicable requirement fails, and why?" "Future extensibility," "consistency" and "best practice" alone do not demonstrate a current dependency (`:89-93`). Dispositions: Needed now / Useful now / Defer (with revisit trigger) / Outside current intent / Builder decision (`:95-101`).

**Break-even.** Net hours saved over *n* examples = n × (saved/example − maintenance/example) − upfront; keep first-delivery delay visible; use only credible near-term *n* (`:121-127`).

**The work-order form of the test** (closest to this thesis). §9 restates it as six observable events (`:240-249`): SQL runs → unchanged CLI invokes → DB-defined output observed → SQL changes → CLI observes change → second identity. "A step that does not change any of those six events is not part of the loop." Selection rule: least work that closes the loop, **review/maintenance effort counted**; supporting work is partial progress until the loop closes (`:253`). Dependencies classified as execution / delivery / validation-promotion / **not necessary**; "never justified by 'the schema requires it' alone" (`:259-266`).

**The timing principle the rubric already states:** publication "was never intrinsically necessary to the flywheel; it was the cost of the guards" (`:288`); "The initial decision does not require designing the eventual full architecture" (`:23`); provenance "does not acquire new authority through the review"; document presence/age/implementation presence do not authorize a durable obligation (`:87-88`).

## 2. Inventory table

Verdict vocabulary matches the rubric: **necessary now**, **useful now**, **defer (too early)**, **not needed**.

| # | Decision | Contribution | Cost (measured / cited) | Rubric verdict | Timing |
|---|---|---|---|---|---|
| D1 | Native-body materialization (`materialize-node`, `load-memory-scenario`, `read-execution-graph`, 12 resolvers) executed per invoke (architecture 1) | Proved DB→memory execution; 17/17 fixtures parity; gives an executable path with no kernel host dependency yet | 465 body files; per-invoke replanning; process+import 0.8–1.0 s; native-body verification apparatus; target eliminates all of it (`target-architecture.md:68-69`, `scripts-disposition-review.md:52-62`) | Omission fails nothing once the kernel interprets the graph — the read path is the fix, not the materializer (`target-architecture.md:71-82`, `:210-215`) | **First demonstration: right. Retention on the path: too early/not needed** |
| D2 | Platform-commit pinning + native-body verification/parity (inverse reader, 200-vector differential, 34-file `platformDigest`, baselines, `verify:memory` parity) | Established lowering↔provider agreement and transformation round-trip (994 regions); groundwork for cross-target conformance | Pinned commit + per-run platform surface digest; retained baselines; mutation sets; verifies artifacts the target eliminates; cross-target still outstanding ("vector binding outstanding", `native-embodiment-repair.md:28,37`) | Contribution 1 (future cross-apply), evidence 2 but benefit horizon is later; break-even depends on *n* = future targets, not the loop (`:111-112`, `:127`) | **Defer / too early.** Revisit trigger: second target (cross-apply), not the SQL→CLI flywheel |
| D3 | `v_capability_graph_source` / `v_capability_execution_declaration` assembled estate-wide **before** the `capability_id` filter | Supplies the declared graph/authority the kernel interprets — target-endorsed declaration read (`target-architecture.md:186-188`) | `graph_source` **35 s warm / >120 s cold**; declaration **11–20 s**; `contract_authorities` reads the declaration view 4×; 1.08 M lob reads; `STRING_AGG` overflow says `performance-optimization.md:16-17,22-24` | The **view** is necessary (omission = `DECLARED_GRAPH_SOURCE_MISSING`). The **unfiltered assembly** changes only time — the "not necessary" class (`:259-264`); declared authority already draws invocation as a bounded closure (`bounded-execution-closure.md:21-37`) | **View: necessary now. Estate-wide assembly: not needed — fix immediately** (filter before aggregation, `performance-optimization.md:30`) |
| D4 | Per-invocation coherence pin: new pool + `tx.begin` + `pinModel` + `EXECUTE AS` + close **per `query()`** | One coherence pin per invocation (`snapshotId`/`projectionDigest`/`viewDefinitionDigest`) prevents mixed authority — a real source-of-truth/read-boundary property (`read-authority.mjs:150-155`) | **~1 s × 8 calls ≈ 8 s**: connect + applock + `sys.sql_modules` digest + `EXECUTE AS` each time (`performance-optimization.md:18`) | One pin per invocation is a **must-survive invariant** (`performance-optimization.md:42-46`); re-pinning per query is the same reuse-not-made pattern, and the smallest form is one read session (`:36`) | **One pin: necessary now. Per-query re-pin: not needed — collapse to one session** |
| D5 | "Transportable declaration" bundle (`read-authority` single JSON bundle) + inherited-bundle documents (base64 `content_bytes` document set read every invoke) | Carries the declaration off the DB for preflight/offline (`extract-inflight-bundle` → `invoke-from-bundle`) and preserves the retained-document contract the planner consumed | Declaration document recordset read on **every invoke** though invoke uses only `recordsets[0]`; loader re-reads `run-declared-graph`'s own bundle (8–20 s) (`performance-optimization.md:20,32`); holds the capsule/document shape the kernel is replacing | The bundle is a **retained-source shape inherited by presence**; presence/age do not authorize it (`:87-88`). §9.6 leaves open whether the runtime should read mutable working rows without retained capsule source at all (`:290,300-301`) | **Defer / too early.** Smallest path: return only the rows the invocation consumes; keep the bundle only for the preflight proof |
| D6 | Retained-framework digests `snapshotId` / `projectionDigest` / `viewDefinitionDigest` | Bind a read to one estate snapshot + projection + view definitions; `DATABASE_AUTHORITY_NOT_COHERENT` guard | `viewDefinitionDigest` requires a full `sys.sql_modules` scan per query (`model-pin.mjs:10-11`), folded into D4's ~1 s | Same invariant list: "One coherence pin per invocation … do not drop or weaken them" (`performance-optimization.md:44-46`); retrieval must preserve exact versions (`:215`) | **Necessary now as a single per-invocation pin.** Not as a per-query recomputation (see D4) |
| D7 | Per-invocation process spawn + delivery config (`database-delivery.mjs` spawned per `sfx` call; config file, credential resolve, `mssql` import, `restrictMemoryProcess`) | Holds the isolation boundary (no fs writes/cache reads) and a clean stdin/stdout protocol; makes each invocation independent | Process setup **0.8–1.0 s**; `mssql` import ~357 ms; spawn + config + env per invoke (`performance-optimization.md:19,39`) | The **permission boundary** is required to stay (`:47-48`); the per-invocation re-spawn/re-import is separate and is a "SDA/lib change request (CLI transport)" (`:39,64`) | **Isolation: necessary now. Per-invoke spawn/re-import: defer (long-lived delivery) once the loop is green** |
| D8 | Projection model: per-target native-body projection vs kernel interpretation; "invert projection back to JSON from the DB" (inverse native-AST reader) | Outward projection enabled native execution and inverse reading verified lowering equivalence — a cross-target asset | Inverse reader (AST literals/operators, source maps, mutation sets), 465 bodies, platform digest; it verifies emitted artifacts that no longer exist in the target (`target-architecture.md:68-69`); cross-apply still "needs the second property" | Kernel interpretation is the target rule (`target-architecture.md:15-30`); the consumer may choose the pattern but the *requirement* is only per-language embodied mechanics (`embodiment-completeness.md:91-105`); generic framework deferred unless a measured recurring gap appears (`:139`) | **Kernel interpretation: necessary now. Outward projection + inversion: defer / not needed on this loop** |

## 3. Smallest sufficient path per decision (one line each)

- **D1/D2:** keep the *demonstration* result as evidence; route invocation through kernel interpretation; do not restore materialization or its verifiers (`target-architecture.md:84-97`).
- **D3:** inline TVF / `CROSS APPLY` filtered to one `capability_id` before JSON aggregation (`performance-optimization.md:30`).
- **D4/D6:** one pool + one `pinModel` + one `EXECUTE AS`, N statements, one close (`performance-optimization.md:36`).
- **D5:** invoke reads only the selection/CLI/interface/graph rows it executes; make the document recordset conditional (`performance-optimization.md:32`).
- **D7:** keep `restrictMemoryProcess`; move to a long-lived delivery transport (SDA change request) only after the loop is proven (`performance-optimization.md:39`).
- **D8:** interpret the declared graph in process; if a native projection is ever needed it is a consumer choice, not an invocation prerequisite (`embodiment-completeness.md:91-105`).

## 4. Where the rubric already anticipated this

- **Minimality vs eventual architecture:** `:23`, `:34` — the initial decision does not design the end state.
- **Necessity is outcome-relative, not best-practice:** `:89-93` — "Future extensibility," "consistency," "best practice" alone fail the test. This is the direct test for D1/D2/D8.
- **Break-even for framework-like investments:** `:121-127`, esp. the generic-framework illustration ("24 hours before this demonstration… 16 further examples… supports deferral"). This is D2/D5/D8 almost verbatim.
- **Defer generic framework before one component:** §6 `:139` — "Defer… Revisit when required cases expose a measured recurring gap." D8.
- **Supporting work is partial progress:** §9.2 `:253` — "schema plumbing, validation, extraction… is partial progress until the loop closes." D1/D2/D5.
- **Six-event loop; steps off the loop are not part of it:** §9.1 `:240-249`. Any of D1–D8 that does not change an event is out.
- **Necessity classes incl. "Not necessary":** §9.3 `:259-266` — "if omitted, which event fails"; "never justified by 'the schema requires it' alone." D3's unfiltered assembly.
- **Publication precedent — a machinery cost, not a loop requirement:** §9.5 `:280-288` — "It was never intrinsically necessary to the flywheel; it was the cost of the guards." The template for "wrong timing": the thing existed to satisfy a guard, not the outcome.
- **Inherited shape does not gain authority by repetition/presence:** `:87-88`. D5's retained-document bundle.
- **Open retained-source question already flagged:** §9.6 `:290,300-301` — whether the runtime should read a mutable working definition "without any retained capsule source at all."
- **Invariants that constrain the fix:** `performance-optimization.md:42-55` — keep one coherence pin/`EXECUTE AS`/boundary; any materialized read must be rebuildable and generation-keyed. These bound D3–D7 and confirm the pin itself is not negotiable.

## 5. Narrative: the timing principle

The thesis holds, with one distinction the rubric forces. **None of these decisions was wrong as a demonstration; several were wrong as a *durable* commitment.** The first DB→memory execution (D1) was exactly the rubric's "first executable demonstration at an unresolved boundary" (`:17`) — correct to build, and it produced real evidence. The error was converting the demonstration's machinery into the standing invocation shape before the SQL→CLI loop had been shown to close. That is the rubric's "wrong timing": *the initial decision does not require designing the eventual full architecture* (`:23`).

Three premature patterns recur:

1. **Building the eventual framework before the loop closes** (D2, D5, D8): platform pinning, transportable bundles and the inverse reader are conformance/cross-target assets. Their contribution score is 1 (future), not 2–3, and their break-even depends on *n* future targets, not the current slice. The rubric's generic-framework illustration (`:127`) defers exactly this.
2. **Re-deriving the estate when the caller asked for one capability** (D3, D4): the declared authority already bounded invocation to a closure (`bounded-execution-closure.md:21-37`); assembling all capabilities before filtering and re-pinning per query changes no observable event — the "not necessary" class (`:264`).
3. **Granting a transitional shape authority by inheritance** (D5): the retained-document bundle survives because the planner once consumed it, not because the kernel needs it; presence/age does not confer authority (`:87-88`).

The correct disposition is therefore not deletion-as-refutation but **demotion**: keep the evidence the first slice produced, and let the smallest path that closes the six events govern the standing implementation. The rubric states the standard for that demotion in its own words: a dependency that cannot name its failing event "is either publication overhead to be minimized or work that belongs to a different decision" (`:303`).

**Verdict summary:** necessary now — the filtered declaration read (D3 view), one coherence pin per invocation (D4/D6), the isolation boundary (D7), kernel interpretation (D8). Too early / defer — platform pinning and native-body parity (D2), estate-wide assembly as authored (D3 shape), per-query re-pin (D4), the transportable/inherited bundle (D5), per-invoke spawn/re-import (D7), outward projection and inverse reader (D8). Not needed on this loop — native-body materialization as the invocation mechanism (D1).

---

# Research report: the SDA projector, its four surfaces, and the inversion gap

Read-only. No files changed. Sources are `C:\lab\repos\scenario-driven-architecture` (SDA/platform) and `C:\lab\repos\sfx-embody` (estate/reader).

---

## 1. The SDA kernel / projector model

**What SDA owns as a language-neutral authority**
- `kernel/README.md` — the kernel is authority, not an implementation: schemas (JSON Schema 2020-12), semantic-authority, contracts, fixtures; no runtime source in `kernel/`.
- `conformance/` — a single shared corpus all languages run against (`conformance/README.md`).

**What the projector compiles**

SDA has two stacked projections that share one canonical execution graph.

1. **Semantic execution graph** — `languages/typescript/runtimes/node/semantic-execution-graph/`
   - `compiler.js` (`SemanticExecutionGraphCompiler.compile`) turns declared capability/scenario/execution-authority/transition/transformation facts into a graph of **cells** (scenario cells, mechanic cells, transformation sub-cells), **edges** (sequence/return/selection/join/recurrence), **decompositions**, **edgeGroups**, **recurrenceAuthorities**, and **requiredProviderSlots**. Every cell carries `sourcePointers` and `sourceAuthorityDigests` back to declared authority.
   - `normalizer.js` provides `normalizeGraph` and `canonicalGraphDigest` (recursive key-order canonical JSON, sorted collections), plus `normalizeOverlay` / `realizedGraphDigest`.
   - `validator.js` / `topology-verifier.js` admit the graph and verify planned vs observed topology; `scheduler.js` is the target-native token scheduler; `projections.js` renders the Mermaid view and `reverseExecutionLineage`.

2. **Consumer projection / embodiment plans** — `tools/src/consumer-projection/`
   - `application/consumer-capability-compiler.ts` runs the projection itself as a composed scenario chain (`admit-consumer-source-facts` → `compose-canonical-scenario-graph` → `resolve-platform-responsibilities` → `construct-consumer-projection-plan` → `prove-projected-sterility-before-publication` → `publish-projected-capability`).
   - `application/consumer-execution-embodiment-compiler.ts` calls the graph compiler and `createPlanV3`, binding each `requiredProviderSlot` through a `providerProfiles` map to a per-target `implementationRef`.
   - `application/consumer-projection-plan-builder.ts` decides plan shape per capability: linear v1/v2 plans, or **graph-native v3 only** when the capability declares edge groups/recurrence (`graphNativeTopology`, lines 89–102).
   - `languages/.../plan-v3.js` (`createPlanV3`) emits `consumer-execution-embodiment-plan.v3` carrying `canonicalGraph`, `canonicalGraphDigest`, `realizationOverlay`, `realizedGraphDigest`, `sourceMap`, `contractCatalog`, `bindingAuthorities`, closures and expected topology.

**Per-language plans/bindings.** Each target's application provider (`tools/src/consumer-projection/providers/{node,csharp,python}/consumer-application-provider.ts`) renders generated code plus its own `application-binding.<target>.json` and `query/*.<target>.json`. Resolution is `mechanicId → providerProfileId → code module/export` (data), per `docs/embodiment-completeness.md`.

**Multi-language conformance.** Conformance is digest parity, not textual parity:
- The three targets emit the **same** `canonicalGraph` and `canonicalGraphDigest`; they differ only in `realizationOverlay` / `realizedGraphDigest` (`normalizer.js:36–49`; `conformance/execution-graph/language-graph-v1-conformance.json`; `docs/execution-plan-encoding-remediation-strategy-2026-08-17.md` §"All three plans have the same canonicalGraphDigest").
- `docs/embodiment-completeness.md` — "The proof": per target run all fixtures; cross-target the node/python/csharp plans must share `canonicalGraphDigest` and outcome digest; every required provider slot bound, every contract carried, no passthrough.
- `docs/handoff/semantic-execution-graph-compilation-python-csharp.md` and `docs/cross-target-embodiment.md` (sfx-embody) record the 157-vector / 32-mechanic cross-language parity work.
- ADR-0014 (`docs/decisions/0014-...`) admits exactly one versioned bootstrap compiler with reproducible self-hosting.

---

## 2. The four projection surfaces

### (a) Database surface — capabilities as rows, estate views
- **Producer:** `sfx-embody/sql/schema/*.sql` and `sql/migrations/*.sql` (authoring), executed against the `sidefx-database` connection/runner.
- **Rows:** normalized `model.*` (capability, capability_version, scenario, execution_authority + operations, port, transformation, contract, mechanic, provider_capability_implementation, estate_capability, target).
- **The estate views that project rows back into compiler input:**
  - `analysis.v_capability_execution_declaration` — the executable **source-document set**, reassembled per `source_path`/`entry_id` from retained source (`sql/schema/assemble-execution-declarations.sql`; later versions in `sql/migrations/include-declared-schema-references.sql`, `declare-graph-native-consumer-topology.sql`).
  - `analysis.v_capability_graph_source` — assembles the flat declared authority (scenarios, executionAuthorities, interfaceAuthority, semanticTransformation, contractAuthorities, graph-native topology) that the SDA compiler consumes, *from normalised rows plus retained documents* (`sql/migrations/assemble-capability-graph-source.sql`, `expose-contract-authorities-in-graph-source.sql`).
  - Also `analysis.v_scenario_language_resolution`, `analysis.v_declared_platform_implementation`, `analysis.v_selected_semantic_definition`, `analysis.v_scenario_invocation_closure`.
- **Reader (boot):** `sfx-embody/src/read-authority.mjs` (authority/closure/resolution/mechanics reads) and `src/invoke-database-capability.mjs` (reads `graph_source`, CLI config, hands the graph to `run-declared-graph`).

### (b) Code embodiment surface
- **Producer:** `npm run project:consumer-capability -- <consumer-workspace> --targets=node,csharp,python` (`package.json:45`, entry `tools/src/interfaces/consumer-projection/project.ts`).
- **Artifacts per capability under `projected/`** (example: `capabilities/sda-platform/project-presentation-capabilities/project-semantic-element-realization/projected/`):
  - `application-binding.json`, `application-binding.{node,csharp,python}.json` (`projected-consumer-application-binding.v1|v2|v3`);
  - `execution-plans/consumer-execution-plan.<target>.json` and `.v3.json` (the v3 plan carries the canonical graph/digests);
  - `node/capability-runtime.generated.mjs`, `csharp/*.generated.cs(.csproj)`, `python/consumer.generated.py`;
  - `query/conformance-query.<target>.json`, `query/platform-mechanic-resolution.<target>.json`, `fixtures/fixtures.json`, `telemetry/expected-trace.json`, `projection-conformance.json`, and a hash-complete `projection-manifest.json`.
- Language resolver bodies and generated contract trees live in `languages/*` (inventory: `docs/languages-resolver-boundary-and-projection-inventory.md`, ADR-0013).
- sfx-embody's older `embodiments/*` (materialized Node bodies via `materialize-node`) are the legacy code-embodiment form; `docs/target-architecture.md` marks materialization as **eliminated** in the target.

### (c) Workspace surface (consumer workspace authority)
- **Authority:** `consumer-workspace.authority.json` (`workspaceType: consumer-workspace-authority.v1`) — kernel execution vector, governance, `conformanceQuery`, `telemetryAuthority`, `platformCapabilityCatalog`, `projectionTargets`, and the capability's declared source documents (feature, capability, semanticGraph, executionAuthorities, projectionAuthorities, interfaces, fixtures). Example: `.../project-semantic-element-realization/consumer-workspace.authority.json`.
- **SDA workspace rules:** `workspace/workspace.contract.json`, `workspace/workspace.governance.json`; `docs/workspace-shape-intent.md` (line 552: `languages/{language}/generated` has no hand-authored files).
- **Estate side:** `sfx-embody/sfx.config.json` (delivery bindings, roots), `config/sfx.commands.json` (command→delivery mapping), `src/read-workspace-config.mjs`, `src/database-delivery.mjs`.
- The workspace surface is *produced* by the projection run writing into the workspace's `projected/` directory.

### (d) Inverted projection back to JSON from the DB — status: not implemented; flow is effectively one-way
There is **no declared capability or tool** in either repo that reconstructs capability JSON declarations (`.feature`, `*.authority.json`, contracts) from the DB.

What does exist (partial ingredients only):
- `analysis.v_capability_execution_declaration` re-emits each declared source document as JSON keyed by `source_path`/`entry_id` (`sql/schema/assemble-execution-declarations.sql`). The read path in `src/read-authority.mjs:30–34` returns `source_path, entry_id, content_bytes` — i.e. DB can hand back the original document bytes it retained.
- `analysis.v_capability_graph_source` projects rows **into the compiler's JSON input** (`sql/migrations/assemble-capability-graph-source.sql`) — a row→JSON bridge, but scoped to invocation, not a general workspace reconstruction, and it still leans on retained document blobs (`JSON_QUERY(d.document, '$.executionAuthorities')`).
- `sfx capability reveal … --as meaning` renders the declared chain as human prose/Markdown (`src/narrate-capability-meaning.mjs`, `docs/capability-command-surface.md`), and `list`/`find` output row-derived JSON — readers, not an inverse authoring emitter.
- `sfx-embody/src/read-execution-delivery.mjs` reads a delivery JSON blob out of `v_selected_semantic_definition` — again a stored-declaration read, not reconstruction.
- `reconstruct-capability-workspace` and `generate-executable-capability-scaffold` appear only as **references** — in `sfx-embody/examples/*.json` and `docs/research/canonical-feature-migration/review-20260911.json` — and are defined in the adjacent `agentic-harness`, not declared in either repo's SQL.

So "inverted projection back to JSON from the DB" would mean: a declared capability that takes a capability identity and emits the full **capability workspace declaration set** (feature, capability authority, semantic graph, execution authorities, projection authorities, interfaces, fixtures, contracts, UI authority) as JSON — the exact inverse of `project:consumer-capability`. Today the direction is JSON/SQL → rows → graph/plan/code. The DB retains the source bytes and can re-emit documents (`v_capability_execution_declaration`) and can rebuild the invocation graph JSON (`v_capability_graph_source`), but no general inverse authoring projection is declared. This is a finding/gap, not an existing mechanism.

---

## 3. Division of labor: SDA vs sfx-embody

| Concern | Owner | Evidence |
|---|---|---|
| Kernel law, schemas, semantic authority, contracts, conformance corpus | **SDA** | `kernel/`, `conformance/` |
| Language resolvers and implementations (node/python/csharp/java/go; cpp/kotlin/swift) | **SDA** | `languages/`, ADR-0013, `docs/languages-resolver-boundary-and-projection-inventory.md` |
| Graph compiler, plan-v3, per-target projection, consumer application projectors | **SDA** | `tools/src/consumer-projection/`, `languages/.../semantic-execution-graph/` |
| UI presentation protocol + presentation capabilities | **SDA** | `capabilities/sda-platform/{resolve-declared-ui-presentation,compile-semantic-presentation,project-presentation-capabilities,...}` |
| Workspace governance/rules and consumer workspace authority schema | **SDA** | `workspace/`, ADR-0007/0010/0013 |
| Capability meaning authored as SQL rows; all migrations and reads | **sfx-embody** | `sql/`, AGENTS.md "prime rule" |
| Boot: frontdoor/loader, DB connection+query runner, bootstrap installer | **sfx-embody** | `src/database-delivery.mjs`, `src/invoke-database-capability.mjs`, `src/read-authority.mjs`; `docs/target-architecture.md` §"only code that may remain" |
| CLI delivery, workspace/process config, sandbox | **sfx-embody** | `sfx.config.json`, `config/sfx.commands.json`, `src/read-workspace-config.mjs`, `src/restrict-memory-process.mjs` |

Binding rule: agents must not edit SDA (`docs/embodiment-completeness.md` §"Agents must not change the SDA repo"); cross-language impact → SDA, everything else → rows (`docs/target-architecture.md` §Boundary).

---

## 4. Presentation-layer projection: the examples and their locations

**The successor presentation capabilities (SDA platform):**
- `capabilities/sda-platform/resolve-declared-ui-presentation/` — root `produce-canonical-semantic-presentation`; contract `sda-ui-semantic-presentation.v1`; enforces the zero-opinion canvas and `UNJUSTIFIED_PRESENTATION_ELEMENT` (`capability.feature`, `resolve-declared-ui-presentation.authority.json`, `README.md`). Reference resolver at `tools/src/ui-presentation/application/declared-ui-presentation-resolver.ts`.
- `capabilities/sda-platform/compile-semantic-presentation/` — normalized IR.
- The rest of the circuit is `resolve-ui-embodiment-requirements`, `resolve-ui-embodiment-provider`, `plan-ui-embodiment`, `generate-ui-protocol-bindings`, `materialize-ui-embodiment`, plus `ui-presentation-protocol/`, `ui-embodiment/`.

**The "dishonest" (hand-authored, framework-owned) presentation projection:**
- `capabilities/sda-platform/project-presentation-capabilities/`:
  - features `features/project-semantic-element-realization.feature`, `project-activation-binding.feature`, `project-flow-composition.feature`;
  - `project-semantic-element-realization/native-binding-requirements.authority.json` — target profiles `browser-dom-web`, `react-web`, `wpf`, `avalonia`, each with native role / content / event mappings;
  - `legacy-oracles.v1.json` — frozen hand-authored oracles: `languages/csharp/src/ScenarioKernel.Wpf/V3PlanEmbodiment.cs`, `.../ScenarioKernel.Avalonia/V3PlanEmbodiment.cs`, `languages/typescript/presentation/react/runtime/v3-plan-embodiment.mjs`, `.../browser-dom/runtime/v3-plan-embodiment.mjs`, `languages/typescript/runtimes/browser/runtime/ui-embodiment-plan-v1.mjs`;
  - `project-semantic-element-realization/native-equivalence-evidence.v1.json` — only WPF is oracle-equivalent (`WPF_ELEMENT_REALIZATION_EQUIVALENT_OTHER_TARGETS_OPEN`; browser-dom/react/avalonia/wpf-flow still open).
- The broader per-target UI claimants (WPF, Avalonia, JavaFX, SwiftUI, Android Compose, C++ AppKit, WinUI3, React, browser DOM, HTML) are catalogued in `docs/ui-authority-and-parity.md` and classified `PROJECT-UI`/`PROJECT-UI (SLIM)` in `docs/languages-resolver-boundary-and-projection-inventory.md` §6.
- The honesty framing itself is `docs/research/platform-mechanic-honesty.md` (sfx-embody): domain/framework behavior living as Node-only "platform mechanics" masquerading as language resolution; ADR-0010/0012 say legacy presentation providers are frozen migration oracles and `languages/*` must not gain new successor presentation mechanics.

**How these become first login-flow capabilities in the database:**
1. Author the login flow as estate rows: a `LOGIN` capability + root scenario (`Given credentials, When authenticate, Then session`), its input/outcome contracts, execution authority (operations/ports/transformations), and provider bindings — all in `sfx-embody/sql/migrations/`, exposed through `analysis.v_capability_graph_source`.
2. Author the UI meaning separately as a `declared-ui-authority.v1` manifest (experience/interaction/presentation/semantic-read-model authorities) per the research doc's child circuit (`docs/fully-declarable-ui-authority-projection-research-2026-08-12.md`, lines 307–320, 419–433), then let `resolve-declared-ui-presentation` → `compile-semantic-presentation` → `plan-ui-embodiment` → `materialize-ui-embodiment` run through the kernel.
3. Project to targets via `project:consumer-capability` / `project-semantic-element-realization`; the semantic element facts (kind/role/content/state/event/mechanic/lineage) are what the per-target `native-binding-requirements` resolve, with no control/framework/layout decision in authority.
4. The "first login-flow capabilities in the database" are thus: the login **capability** row-set plus its **declared UI authority** rows, whose nodes/edges contain only semantic element, activation-binding, and flow-composition facts — the WPF/JavaFX/HTML/React realization being an output projection, not authority.

---

## Key file/location index

| Concern | Location |
|---|---|
| Kernel authority | `scenario-driven-architecture/kernel/` |
| Graph compiler / digests / plan-v3 | `.../languages/typescript/runtimes/node/semantic-execution-graph/{compiler,normalizer,plan-v3,validator,scheduler,topology-verifier,projections}.js` |
| Consumer projector | `.../tools/src/consumer-projection/application/{consumer-capability-compiler,consumer-execution-embodiment-compiler,consumer-projection-plan-builder}.ts` |
| Per-target projectors | `.../tools/src/consumer-projection/providers/{node,csharp,python}/consumer-application-provider.ts` |
| Cross-target conformance | `.../conformance/execution-graph/`, `.../docs/embodiment-completeness.md` |
| Presentation capabilities | `.../capabilities/sda-platform/{resolve-declared-ui-presentation,compile-semantic-presentation,project-presentation-capabilities}/` |
| Estates rows + views | `sfx-embody/sql/schema/assemble-execution-declarations.sql`, `sql/migrations/assemble-capability-graph-source.sql` |
| Boot/reader/CLI | `sfx-embody/src/{database-delivery,invoke-database-capability,read-authority,read-execution-delivery,read-workspace-config}.mjs` |
| Workspace authority | `.../project-semantic-element-realization/consumer-workspace.authority.json`; `sfx-embody/sfx.config.json`; `config/sfx.commands.json` |
| Inverted-projection references | `sfx-embody/examples/*scaffold*.json`; `docs/research/canonical-feature-migration/review-20260911.json` (`reconstruct-capability-workspace`) |

**Bottom line:** the projector is a language-neutral graph compiler plus a per-target embodiment projector, with conformance grounded in `canonicalGraphDigest` parity. The database, code-embodiment, and workspace surfaces are all real and produced at identifiable steps. The inverted projection (DB → capability JSON declarations) does **not** exist as a mechanism; only row→compiler-JSON bridges (`v_capability_graph_source`), retained-document re-emission (`v_capability_execution_declaration`), and human-facing rendering (`reveal`) exist today. The presentation layer is mid-migration: semantic capabilities and target-neutral projection facts are authored, but the framework-specific renderers remain frozen hand-authored oracles, with only WPF currently proven equivalent.

---

# Findings: the four "primary experience" items

Scope: read-only survey of `C:\lab\repos\sfx-embody` and `C:\lab\repos\scenario-driven-architecture`. No files changed.

---

## (1) Author deterministic capabilities through SQL or JSON

**Current state**
- Canonical authoring is **SQL-only**. Every capability change is a `.sql` migration under `sql/migrations/`, installed with the lifecycle in `sql/README.md` and `AGENTS.md`: evidence first → one idempotent migration (`BEGIN TRANSACTION` … `ROLLBACK`) → dry run (`scripts/run-migration.mjs`) → preflight uncommitted (`scripts/invoke-from-transaction.mjs`) → flip to `COMMIT` → verify via CLI.
- Migrations call reusable **authoring procedures** in `sql/schema/`:
  - `declare-scenario.sql`: `model.put_semantic_definition`, `model.declare_contract`, `model.declare_scenario`, `model.declare_capability_feature`.
  - `authoring-procedures.sql`: `model.scaffold_capability`, `configure_mechanic`, `configure_interface`, `add_example`, `add_provider`, `configure_provider`, `bind_provider`, `normalize_transformation_expression`, `add/remove_mechanic`, `configure_contract`, `scaffold_estate_provider_capability`, `scaffold_composed_capability`, `author_capability_meaning`, `inspect_capability`.
  - Installed views: `sql/schema/assemble-execution-declarations.sql`, `select-one-definition-per-declared-id.sql`, plus migrations that build `analysis.v_capability_graph_source` (`assemble-capability-graph-source.sql`, `expose-contract-authorities-in-graph-source.sql`) and `analysis.v_capability_execution_declaration`.
- **JSON is a payload inside SQL, not an authoring path.** Procedures take JSON arguments (scenario face, `@operations`, `@port_bindings`, `@semantics`) and hash them into content-addressed `sidefx-semantic-definition.v1` envelopes. `examples/*.request.json` are *invocation* inputs, not declarations.
- No authoring command exists: `config/sfx.commands.json` offers only `list/find/reveal/prepare/invoke/observe/materialize/circuit/catalogue/artifact`. There is no `sfx capability create|declare`, and no JSON document that installs capability authority without SQL.
- Nearest JSON surface is out of scope and not admission: `sidefx-capability-provisioning` (JSON + JSON-Schema `manifests/`, `schemas/`, `candidates/`) is the **provisioning** estate; its README states "Provisioning is not admission" and it never writes managed capability authority.

**Artifacts**: `sql/README.md`, `AGENTS.md`, `docs/database-mutation-flywheels.md`, `sql/schema/authoring-procedures.sql`, `sql/schema/declare-scenario.sql`, `config/sfx.commands.json`, `docs/scaffold-generation-operationalization-plan.md` (§5 "SQL as the default authoring and review surface").

**Gap to "SQL or JSON"**
- A JSON authoring path would need to compile/emit the same normalized rows (or invoke the same procedures) while preserving idempotency, content-addressed digests, current-definition selection, and the preflight lifecycle. Nothing today accepts a capability declaration as a JSON document.
- The transaction/rollback preflight (`invoke-from-transaction.mjs`) is SQL-file-shaped; a JSON surface would need an equivalent apply-uncommitted/rollback step.

---

## (2) One single deterministic invocation path (CLI / API / UI)

**Current state (the path is real and single for the CLI)**
```
sfx capability invoke|observe
  → config/sfx.commands.json (operation → database-invocation surface)
  → sfx.config.json delivery "database-memory" (process: node src/database-delivery.mjs)
  → src/database-delivery.mjs  (frontdoor: owns DB connection/query runner, injects readQuery/readAuthority; streams SFX_OBSERVATION on stderr)
  → src/invoke-database-capability.mjs#executeDatabaseCommand
       readExecutionDelivery → readAuthority (estate views) → readGraphSource
       → executeEstateCapability({ capabilityId: 'run-declared-graph' }, graphSource, config)
  → declared capability run-declared-graph (sql/migrations/declare-run-declared-graph-capability.sql)
       port 1: sda-semantic-execution-graph-compilation-port → compileSemanticExecutionGraph
       port 2: sda-semantic-execution-graph-execution-port  → executeSemanticExecutionGraph (GraphTokenScheduler)
  → kernel compiles + interprets the declared graph in process
```
- `observe` is explicitly not a second path: it runs the identical code and additionally sets `SIDEFX_OBSERVE=1` (mapping flag `"observation": true`) so the delivery streams telemetry. Documented in `docs/capability-command-surface.md`.
- The read is the estate's own declared views (`read-authority.mjs`: `analysis.v_capability_graph_source`, `analysis.v_capability_execution_declaration`, closure, mechanics), pinned by one coherence tuple (`snapshotId` / `projectionDigest` / `viewDefinitionDigest`, enforced `DATABASE_AUTHORITY_NOT_COHERENT`). No per-capability dispatch in CLI or delivery (`operations` table is a row, not a branch).
- Ports reach code through data: `analysis.v_estate_provider_resolved_port_semantics` (`sql/migrations/declare-estate-providers.sql`) injects `configuration.estateProvider` from the provider row named by `providerId`; the kernel provider set is declared in the `run-declared-graph` port binding.

**What remains for "truly single/deterministic across CLI/API/UI"**
- **API/UI are not a path in this repo.** `sfx-platform` (sibling) publishes input contracts and drives the CLI delivery; `docs/research/scenario-experiences/README.md` records that the form/view capability is research, not implemented. There is no HTTP/API invocation surface or UI invocation surface here that shares the loader.
- **Stale second surface still declared:** `config/sfx.commands.json` still exposes `materialize` and `sfx.config.json` still declares the `embodiment-materialization` delivery pointing at `src/embodiment-delivery.mjs`, a file that does not exist (`src/` has only 6 files). `target-architecture.md` dispositions materialization as eliminated.
- **Residual estate-provider seam:** `executeEstateCapability` still resolves `configuration.estateProvider` modules (`invoke-database-capability.mjs:81-110`), and many migrations still write `estateProvider`/`src/resolvers/*` bindings; target architecture calls that a data defect. Lane A/B/C of `docs/implementation-strategy.md` tracks the cleanup.
- **Determinism details:** the graph source is read twice (delivery + loader), the declaration recordset is read even for invoke, and observations go to stderr while the result stays on stdout (`docs/performance-optimization.md` ranks these).

**Artifacts**: `sfx.config.json`, `config/sfx.commands.json`, `src/database-delivery.mjs`, `src/invoke-database-capability.mjs`, `src/read-authority.mjs`, `src/read-execution-delivery.mjs`, `sql/migrations/declare-run-declared-graph-capability.sql`, `sql/migrations/declare-execute-semantic-execution-graph-capability.sql`, `docs/capability-command-surface.md`, `docs/target-architecture.md`, `docs/implementation-strategy.md`.

---

## (3) Presentation-layer capabilities projecting to WPF / JavaFX / HTML / React

**Current state — SDA has the presentation seam and reference projections; the estate has none of it.**
- Governing design: `docs/adr-sda-ui-presentation-protocol-phase-0-1.md` (freeze `consumer-ui-authority.v1`; versioned `sda-ui-presentation-ir.v2`, successor v3), `docs/ui-authority-and-parity.md`, `docs/fully-declarable-ui-authority-projection-research-2026-08-12.md`, `docs/sda-ui-presentation-connascence-and-coupling-analysis-2026-08-11.md`.
- Protocol package: `capabilities/sda-platform/ui-presentation-protocol/` — `contracts/sda-ui-presentation-ir.v2.schema.json`, `ui-embodiment-provider-registry.v1.schema.json`, `compatibility-policy.json`, `protocol.identity.json`, `successor.identity.json`, `provider-registry.json`, `generated-models/`. README (current): React is the Phase-1 reference provider; WPF, JavaFX and legacy HTML remain on legacy materialization paths (post-Phase-1 work).
- Compilers/providers: `tools/src/ui-presentation/application/` (`semantic-presentation-compiler.ts`, `declared-ui-presentation-resolver.ts`, `ui-embodiment-planner.ts`, `legacy-ui-compatibility-compiler.ts`, `ui-protocol-binding-generator.ts`); `tools/src/ui-parity/application/` (`ui-presentation-compiler.ts`, `react-ui-server.ts`, `ui-parity-projector.ts`); provider interface `tools/src/ports/ui-parity/ui-embodiment-provider.ts`; discovery `tools/src/adapters/ui-parity/node-ui-embodiment-provider-registry.ts`.
- Reference example (an actual consumer UI authority + multi-target projection): `examples/generic-capability/ui.authority.json` (`consumer-ui-authority.v1` with experience/interaction/presentationProfile), projected under `examples/generic-capability/projected/{react,html,csharp,javafx,swiftui,android-compose}/...`; richer WPF example `artifacts/ui-parity/wpf-app/resume-tailoring/authority/ui-authority.csharp.json`.
- Target runtimes: React `languages/typescript/presentation/react/runtime/authority-backed-application.mjs`; vanilla HTML/DOM `languages/typescript/presentation/browser-dom/runtime/authority-backed-dom-application.mjs`; WPF `languages/csharp/src/ScenarioKernel.UiAuthority/AuthorityBackedViewModel.cs` (+ `ScenarioKernel.Wpf`); JavaFX `languages/java/presentation/javafx/src/main/java/scenario/kernel/javafx/AuthorityBackedJavaFxApplication.java`; plus C++ AppKit, SwiftUI, Android Compose, Avalonia.
- Admitted catalog: `kernel/semantic-authority/consumer/sda-ui-embodiment-capabilities.semantic-authority.json` — WPF, React, HTML, JavaFX, C++ AppKit are `ADMITTED`; SwiftUI, Compose, Avalonia are `DECLARED` (`IMPLEMENTED_AWAITING_NATIVE_PROOF`).
- **Login flow does not exist.** `docs/research/scenario-experiences/README.md:221-244` states no dedicated login root was found among the 218 selected roots and gives an illustrative-only presentation profile sketch. In the estate, presentation work is Lane E of `docs/implementation-strategy.md` (declare `narrate-*`/`diagram-*`; "if not expressible, a platform presentation mechanic"); `README.md` states the proposed experience capability "is not implemented."

**Gap to a login-flow presentation capability in the estate**
- Need an estate capability declaring: input/outcome contracts, an authentication scenario (identity + secret, success/challenge/rejected variants), a `consumer-ui-authority.v1` experience/interaction/presentation profile, and the projection/target bindings.
- The estate has **no UI-authority store or presentation pipeline**: no presentation-profile rows, no experience-plan columns, no `UiEmbodimentProvider` binding, and `analysis.v_capability_graph_source` carries only `scenarios/executionAuthorities/interfaceAuthority/semanticTransformations/contractAuthorities` — not UI authority. SDA owns the compiler/providers, but the binding rows would have to be authored here and the projection invoked.
- React is the only v2-registry provider; WPF/JavaFX/HTML need v2 (or v3) provider migration to be first-class rather than legacy.

---

## (4) Live invocation telemetry with selectable semantic altitudes (EPD)

**Current state — what `observe` actually shows today**
- `observe` = `invoke` + stderr streaming. `src/database-delivery.mjs:37-47` writes `SFX_OBSERVATION <json>` lines, whitelisting only `observationType, phase, status, observedAt, executionId, rootExecutionId, parentExecutionId, scenarioId, stepId, sequence`.
- The estate emits **`delivery-phase`** observations and per-phase timings only: `src/invoke-database-capability.mjs#executeDatabaseCommand` `measure()` emits `{ observationType:'delivery-phase', phase, status, observedAt }` for `readExecutionDelivery`, `readAuthority`, `readGraphSource`, `executeDeclaredGraph`, and records `evidence.timings` (+ `queries`); `database-delivery.mjs` adds `processSetup`/`processTotal`. Collected `observations` are streamed but the JSON result sets `outcome.observations: []`.
- The kernel path returns **testimony, not a stream**: `languages/typescript/runtimes/node/semantic-execution-graph-execution-provider.mjs` and `.../scheduler.js` return `{ disposition, outcome, outcomeVariant, cellTestimony, edgeTestimony, observedPathDigest }`. `executeSemanticExecutionGraph` is not passed an observer, so no per-cell observation reaches `SFX_OBSERVATION`.

**Semantic altitudes (actual vocabulary)**
- Cell altitude enum (`kernel/schemas/cell-execution-testimony.schema.json`): **`scenario`, `mechanic`, `provider`, `physical`**. Defined in `docs/adr-single-geometry-execution-graph.md` and `docs/single-geometry-execution-graph-implementation-plan.md` (terminology table); a `cell-execution-testimony` carries `cellId`, `cellAltitude`, `parentCellExecutionId`, `iterationId`, `inputDigest`, `authorityDigest`, `providerProfileId`, `outcomeDigest`, `disposition`, `selectedEdgeIds`, `logicalOrder`.
- The user's "operation" altitude is not a cell altitude; operations are the estate **execution authority operation list** (`invoke-port` / `invoke-scenario`), from `model.execution_operation` / `operation_port_invocation`. The estate resolution read also exposes an `altitude` column (`analysis.v_scenario_language_resolution`, used in `read-authority.mjs`).
- `edge-execution-testimony` carries `edgeId`, `sourceCellExecutionId`, `sourceOutcomeDigest`, `destinationCellId/PortId`, `groupId`, `iterationId`, `admissionDisposition` (`admitted|rejected|buffered|cancelled`), `logicalOrder`.
- Telemetry authority: `kernel/semantic-authority/consumer/scenario-execution.telemetry-authority.json` (`consumer-telemetry-authority.v1`, `emission: each-performed-vector-step`, lineage fields); schemas `scenario-execution-observation.schema.json` (v1, has `observedAt`) and `scenario-execution-observation.v2.schema.json` (graph-addressed, has `cellId`/`edgeId`/`stepId`/`sequence`, **no timestamp**).
- Observation bindings: `kernel/schemas/observation-binding.schema.json` plus per-capability `observation-bindings.json` under `capabilities/sda-tooling/*/` (bind `conditionId → evaluatorId → evidenceContractId → configurationRef`).
- Planned-vs-observed tooling: `.../semantic-execution-graph/topology-verifier.js`, `kernel/schemas/execution-topology-conformance.schema.json`, `observedPathDigest` (scheduler `result()`).

**Gap to EPD (drilldown by altitude, timings per cell, observed-path digests)**
- **No per-cell timing.** `cell-execution-testimony` has no `observedAt`/duration; only the four estate `delivery-phase` timings exist. Per-cell timing requires a kernel change (add timing to testimony) — an SDA change request, not an estate edit.
- **No altitude-selectable stream.** The scheduler returns testimony in the result; `SFX_OBSERVATION` carries only `delivery-phase`. There is no `observe --altitude scenario|mechanic|provider|physical`, no nesting by `parentCellExecutionId`, and `stepId` observations are the separate scenario-vector path.
- **Digest not surfaced to the operator.** `observedPathDigest` is computed but not emitted through the delivery/CLI (the delivery filter would drop it; `outcome.observations` is empty).
- SDA already specifies the target view: `docs/execution-plan-encoding-remediation-strategy-2026-08-17.md` §"Visualization invariants" (group/filter/collapse by altitude; planned-vs-observed overlay; stable canonical IDs) and proposes the derived `semantic-execution-graph-view.v1`; `docs/single-geometry-execution-graph-implementation-plan.md` defines cell/edge/decomposition geometry. EPD would implement that projection plus streaming and timing, and expose it through `sfx capability observe`.

**Artifacts**: `docs/capability-command-surface.md` (observe examples), `src/invoke-database-capability.mjs` (measure/timings), `src/database-delivery.mjs` (SFX_OBSERVATION), `kernel/schemas/{cell-execution-testimony,edge-execution-testimony,observation-binding,scenario-execution-observation,scenario-execution-observation.v2,consumer-telemetry-authority}.schema.json`, `kernel/semantic-authority/consumer/scenario-execution.telemetry-authority.json`, `languages/typescript/runtimes/node/semantic-execution-graph/{scheduler.js,topology-verifier.js}`, `languages/typescript/runtimes/node/semantic-execution-graph-execution-provider.mjs`, `docs/execution-plan-encoding-remediation-strategy-2026-08-17.md`, `docs/single-geometry-execution-graph-implementation-plan.md`.

---

### Cross-cutting observations
- The "single invocation path" is genuinely implemented for the CLI; the largest remaining gaps across all four items are (a) no JSON authoring surface, (b) API/UI not sharing the loader and a stale materialize surface, (c) presentation/UI authority not stored or projected by the estate, and (d) kernel testimony not streamed with timings or altitude selection.
- Several governing docs are historical relative to the code (e.g. `database-direct-invocation.md` and `README.md` still describe `materialize-node`/native bodies; `src/` no longer contains them). `target-architecture.md` + `implementation-strategy.md` are the current authority.

---

Created `docs/target-experience.md` (linked from `AGENTS.md`), consolidating the three research reports.

**The architecture we want** — the SDA language kernel/projector with multi-language conformance by **digest parity** (`canonicalGraphDigest` shared across node/python/csharp, differing only in `realizedGraphDigest`); executable capabilities as data projectable to four surfaces — **database** (rows → compiler input via the estate views), **code embodiments** (`project:consumer-capability` per-target binding/plan/code), **workspaces** (`consumer-workspace-authority.v1`), and **inverted projection** (DB → declaration JSON) which **does not exist** — only row→compiler bridges and retained-document re-emission do; and the consumer + bootstrap (`sfx-embody`: rows, boot, CLI).

**Primary experience — current state vs gap**
1. **SQL or JSON authoring** — today SQL-only; JSON is a payload inside procedures; no authoring command. Gap: a JSON surface emitting the same rows with idempotency/digest/selection/preflight preserved.
2. **One deterministic invocation path** — the CLI path is genuinely single (`observe` = `invoke` + `SIDEFX_OBSERVE=1`; no per-capability dispatch; resolution is data). Remaining: API/UI don't share the loader; the stale `materialize` surface should go; residual `estateProvider` bindings are data defects.
3. **Presentation capabilities** — SDA has the seam (IR protocol, `resolve-declared-ui-presentation` → … → `materialize-ui-embodiment`, admitted WPF/React/HTML/JavaFX, reference `examples/generic-capability/ui.authority.json`, framework renderers as frozen oracles). Authorities are semantic (no control/framework/layout). The estate has **no UI-authority store/pipeline**. The first **login-flow** capability = a login capability row-set + declared UI-authority rows, projected per target.
4. **Live telemetry / EPD** — today only `delivery-phase` timings; the kernel returns **testimony** (`cellTestimony`/`edgeTestimony`/`observedPathDigest`), not a stream. Semantic altitudes are `scenario|mechanic|provider|physical`. Gap: per-cell timing in testimony (**SDA change request**), altitude-selectable streaming, planned-vs-observed overlay.

**Timing review (rubric §9)** — the doc classifies each decision. **Needed now:** the filtered declaration read, one coherence pin per invocation, the isolation boundary, kernel interpretation. **Too early / defer:** platform-commit pinning + native-body parity (revisit at the second target), the transportable/inherited bundle, per-invoke spawn/re-import (long-lived delivery = SDA/CLI request), outward projection + inverse reader. **Not needed on this loop:** materialization as the invocation mechanism; estate-wide assembly before filtering; per-query re-pin. The rubric already names the pattern: *"the initial decision does not require designing the eventual full architecture"* (`:23`), and publication *"was never intrinsically necessary to the flywheel; it was the cost of the guards"* (`:288`). Disposition: **demotion, not refutation** — keep the evidence, let the smallest path that closes the six-event loop govern.

And the boundary stands: cross-language → **SDA change request** (agents must not edit SDA); everything else → rows.
