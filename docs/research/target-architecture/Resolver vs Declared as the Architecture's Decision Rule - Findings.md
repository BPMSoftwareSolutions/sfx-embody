# The Transistor: Resolver vs Declared as the Architecture's Decision Rule

Read-only research. No code, SQL, or SDA files were changed. Citation roots: unprefixed = `sfx-embody`; `SDA:` = `scenario-driven-architecture`; `BOOT:` = `sda-bootstrap`; `CLI:` = `sidefx-cli`; `DB:` = `sidefx-database`.

---

## 1. The rule, stated precisely

### 1.1 The primitive

| Bit | Name | Nature | Obligation |
|---|---|---|---|
| **0** | **Resolver** | Hand-authored executable code that a language runtime must run to realize a concern. It contains branch/iterate/throw/serialize/validate/effect as its own body (`SDA:docs/decisions/0013-*`). | It must exist **once per supported language** (node, python, csharp; java/go where applicable). Every resolver is a recurring cross-language cost. |
| **1** | **Declared** | Language-neutral data (rows / JSON) that names *what* and *with what configuration*. Interpreted identically by a kernel resolver. | No per-language code. It must remain selection + configuration only — never behavior. |

The reason the bit exists is the multi-language runtime. A concern that can be data is written once and interpreted everywhere; a concern that must be code must be rewritten for every language that hosts it. The transistor makes that cost visible per concern.

### 1.2 The decision test (applied in order)

For any architectural concern **C**, ask:

1. **Is C the boot?** (A reader-and-runner that must exist before any declaration can be read, the database read primitive, or the installer that writes the first declaration.) → **0**. These are the three irreducible resolvers (`target-architecture.md` §"The only code that may remain", proofs by regress/circularity/regress). The boot is a resolver too, so it carries the same per-language obligation, but it is the *terminal* executor.
2. **Does C emit, load, write, or verify a native body / materialized plan?** → **Eliminated** (not a bit; proof debt). The kernel supersedes it.
3. **Can C be written as language-neutral data that an *existing or plannable* kernel primitive interprets?** → **1 (declared)**. Formally, C is declarable iff all three hold:
   - **(a) Total expression** — C's meaning, selection, and configuration fit a declared vocabulary (ids, statements, expressions, schemas, targets).
   - **(b) Existing interpreter primitive** — a kernel operation kind / transformation evaluator / admission mechanism already interprets that vocabulary the same way in every language. *A new vocabulary word whose semantics only one language's code knows is not declarable.*
   - **(c) No language code required** — omitting all language-specific code for C still lets the capability resolve and execute.
4. **Otherwise** → **0 (resolver)** — and it is *simultaneously* a kernel change request, because it must be interpreted in every language, not selected as data (`embodiment-completeness.md` §"Agents must not change the SDA repo").

The negative detector (from the twelve forbidden executable mechanics, `SDA:docs/languages-resolver-boundary-and-projection-inventory.md` §10): if embodying C requires branching, iteration, exception policy, throwing, object construction, serialization, normalization, validation, fallback, retry, or state mutation *that the declared vocabulary cannot express*, C is a resolver. If it requires only `mechanicId → configuration` selection over a primitive the kernel already has, C is declared.

### 1.3 The two subtleties

- **Declared ≠ JSON.** A declared read `{statement, resultColumn}` is 1-data, but *executing* the SQL is a 0 resolver (the declared-read code in each language). SQL is a declared language; the query runner is a resolver. `target-architecture.md` calls this out explicitly: "its SQL content is a declared read, its execution is this runner."
- **A resolver's *set* is data, its *bodies* are code.** The registry that says "mechanic X → module/export" is 1; the module is 0. The binding is `mechanicId → providerProfileId → code module/export` (`embodiment-completeness.md` §"How the consumer application decides code vs data"). The concrete evidence of the cost: the node registry declares **32** `eventPorts`; python/csharp declare **4**; java/go/cpp declare **6** (measured from `SDA:kernel/semantic-authority/consumer/*-mechanic-registry.authority.v1.json`). The *same* declared capability graph resolves to a different amount of hand-authored code per language.

### 1.4 One-line statement

> The transistor rule: a concern is **1 (declared)** iff its meaning is language-neutral data and some kernel resolver already interprets that data identically in every language; a concern is **0 (resolver)** otherwise — and every 0 incurs a per-language implementation, so the goal is always to move a concern from 0 to 1 *without inventing a new kernel primitive*.

---

## 2. Inventory: every concern classified 0/1

Legend: **0** = resolver (hand-authored, per-language); **1** = declared (data, language-neutral); **E** = eliminated/proof-debt. Coverage cells name the realization today; **missing** means the multi-language obligation is unmet.

### 2.1 The boot (irreducible 0s)

| Concern | Bit | Evidence | node | python | csharp | java | go |
|---|---|---|---|---|---|---|---|
| Frontdoor / loader (stdin envelope → stdout result) | **0** | `src/database-delivery.mjs:10-65`; proof by regress `target-architecture.md:38-45` | ✅ `src/database-delivery.mjs`, `src/invoke-database-capability.mjs` | ❌ | ❌ | ❌ | ❌ |
| DB connection / query runner | **0** | `src/database-read-session.mjs`; injects `readQuery` from `DB:src/query/run.mjs`, `DB:src/ingest/database.mjs` (`database-delivery.mjs:27-34`); proof by circularity `target-architecture.md:47-52` | ✅ (delegates to `sidefx-database`) | ❌ | ❌ | ❌ | ❌ |
| Bootstrap installer (migrations / first rows) | **0** | `scripts/run-migration.mjs`, `sql/migrations/*`; proof by regress `target-architecture.md:54-59` | ✅ `scripts/run-migration.mjs` | ❌ | ❌ | ❌ | ❌ |
| Delivery/workspace config read | **0** boot-config | `src/read-workspace-config.mjs`; disposition row `target-architecture.md:69` | ✅ (the *config* `sfx.config.json` / `config/sfx.commands.json` is declared 1) | ❌ | ❌ | ❌ | ❌ |
| Isolation boundary (`--experimental-permission` + `restrictMemoryProcess`) | **0** boot | `src/restrict-memory-process.mjs`; `performance-optimization.md:42-55` | ✅ | ❌ | ❌ | ❌ | ❌ |

### 2.2 The kernel (0s that must exist in every language)

| Concern | Bit | node | python | csharp | java | go |
|---|---|---|---|---|---|---|
| Kernel state machine (Scenario = Input+Event+Outcome) | **0** | `SDA:languages/typescript/src/kernel/scenario-kernel.ts` | `SDA:languages/python/src/scenario_kernel/kernel/scenario_kernel.py` | `SDA:languages/csharp/src/ScenarioKernel/ScenarioKernel.cs` | `SDA:languages/java/src/main/java/scenario/kernel/kernel/ScenarioKernel.java` | `SDA:languages/go/kernel/scenario_kernel.go` |
| Disposition resolver | **0** | `.../disposition-resolver.ts` | `kernel/disposition_resolver.py` | `DispositionResolver.cs` | `kernel/DispositionResolver.java` | `kernel/disposition_resolver.go` |
| Graph **compilation** | **0** | `semantic-execution-graph-compilation-provider.mjs` + `semantic-execution-graph/compiler.js` | `platform/execution_graph.py` (registry declares `sda-semantic-execution-graph-compilation-port.v1`) | `Graph/SemanticExecutionGraphCompilationProvider.cs` | `platform/SemanticExecutionGraphCompilationProvider.java` | `platform/graph_compilation_provider.go` |
| Graph **execution** / **scheduling** (token scheduler, recurrence, joins, cancellation) | **0** | `semantic-execution-graph/scheduler.js`, `semantic-execution-graph-execution-provider.mjs` | `platform/execution_graph.py` (`SemanticExecutionGraphScheduler`) | `Graph/SemanticExecutionGraphScheduler.cs` | `platform/SemanticExecutionGraphScheduler.java` | `platform/graph_execution_provider.go` |
| Realization **overlay** (bind slots, no topology change) | **0** | `semantic-execution-graph-overlay-provider.mjs` | registry port | `Graph/SemanticExecutionGraphOverlayProvider.cs` | `platform/SemanticExecutionGraphOverlayProvider.java` | `platform/graph_overlay_provider.go` |
| **Transformation** evaluation (expression tree) | **0** | `semantic-transformation-evaluator.mjs` | `adapters/core.py::SemanticTransformationEngine` | `Adapters/Consumer/SemanticTransformationEngine.cs` | `adapters/SemanticTransformationEngine.java` | `platform/transformation.go` |
| **Contract / schema admission** | **0** | `schema-contract-admission-provider.mjs` | `_matches_schema` / plan catalog (`platform/consumer.py:126-156`) | `Schema/JsonSchemaContractValidator.cs`, `Schema/SemanticContractCatalogAdmission.cs` | `platform/SemanticContractCatalogAdmission.java`, `adapters/JsonSchemaContractValidator.java` | `platform/graph_contract_catalog_admission.go` |
| **Pure semantic-value** mechanics (`path`, `object`, `literal`, `format`, `let`, `equals`, …) | **0** | `semantic-execution-graph-mechanic-provider.mjs` | mechanic provider | `Graph/SemanticExecutionGraphMechanicProvider.cs` | `platform/SemanticExecutionGraphMechanicProvider.java` | `platform/graph_mechanic_provider.go` |
| **Collection / recurrence** mechanics (`map`, `filter`, `find`, …) | **0** | scheduler + mechanic provider | `platform/execution_graph.py` | `Graph/SemanticExecutionGraphScheduler.cs` | `platform/SemanticExecutionGraphScheduler.java` | `platform/graph_execution_provider.go` |
| **Declared data read** (`{statement, resultColumn}`) | **0** | `semantic-execution-graph-declared-read-provider.mjs` | declared-read code | `Graph/SemanticExecutionGraphDeclaredReadProvider.cs` | `platform/SemanticExecutionGraphDeclaredReadProvider.java` | `platform/graph_declared_read_provider.go` |
| **Platform effect ports** (credential binding, governed HTTP, …) | **0** | `semantic-execution-graph-effect-provider.mjs`, `external-credential-reference-binding-provider.mjs`, `governed-http-exchange-provider.mjs` | `platform/governed_effect_ports.py` (ports declared: effect + graph set) | `Graph/GovernedEffectPorts.cs` | `platform/GovernedEffectPorts.java` | `platform/governed_effect_ports.go` |
| Compilation/execution/overlay **provider** dispatch | **0** | `node-mechanic-registry-loader.mjs` | `platform/consumer.py` | `AdmittedConsumerPlatform` | `platform/AdmittedConsumerPlatform.java` | `platform/platform.go` |
| **Artifact store** (filesystem) | **0** | `filesystem-artifact-store-provider.mjs` | declared port | `SDA:.../Graph` / adapters | `platform/SemanticExecutionGraphArtifactStoreProvider.java` | `platform/graph_artifact_store_provider.go` |
| **Telemetry** emission + observation filter | **0** | `src/observation-filter.mjs`, `execution-drilldown.mjs` | `execution/execution_observer.py` | `IExecutionObserver` | `execution/ExecutionObserver.java` | `execution/ports.go` |
| **Presentation** mechanical host (thin) | **0** | `SDA:typescript/presentation/{react,browser-dom}` | ❌ (no presentation) | ❌ (`csharp/presentation` absent; WPF lives in `ScenarioKernel.Wpf`) | `java/presentation/javafx` | ❌ |

### 2.3 Providers / mechanics (the declared binding vs the code behind it)

| Concern | Bit | Evidence | Coverage today |
|---|---|---|---|
| `overlayBindings` / `providers` set (mechanicId → profile → module) | **1** | `target-architecture.md:174-183`; `embodiment-completeness.md:62-75` | all languages declare a registry (data) |
| Pure value port (`sda-declarative-value-port.v1`) | 0 body / **1 config** | `SDA:node-mechanic-registry.authority.v1.json` | node/python/csharp/java/go |
| Authority transformation port (`sda-authority-transformation-port.v1`) | 0 / **1 expression** | same | node only in the *estate's* eventPorts; the pure profile covers all three (`cross-target-hold-report.md:10-16`) |
| Credential binding port (`sda-external-credential-reference-binding-port.v1`) | **0** | registry | node, **java, go, cpp**; **python/csharp registries do not declare it** |
| Governed HTTP port (`sda-governed-http-exchange-port.v1`) | **0** | registry | node, java, go, cpp; **python/csharp do not declare it** |
| Declared data read `{statement,resultColumn}` | **0** interpreter / **1** statement | `target-architecture.md:154-155` | all (per language declared-read code) |
| Credential **values** | must never be **1** | `next-experiences.md:160-179` ("Rows never carry values") | — |
| OS credential resolver (`sda-os-environment-credential-port.v1`) | **0** | registry | **node only** |
| Vault provider | **0** (to build) | `next-experiences.md:166-179` — SDA request | node partial (env), python/csharp **none** |
| Domain effect ports (LLM, repository observation, tooling, vector index, semantic-carrier, proof-binding, JSON-authority-ingestion, projected-capability-invocation) | **0** | `SDA:node-mechanic-registry...` 32 ports vs 4/6 elsewhere; `platform-mechanic-honesty.md:54-84` | **node only** |
| Presentation / UI authority (experience, interaction, presentation profile) | **1** | `target-experience.md:58-73`; `next-experiences.md` §(3) | estate has **no UI-authority store**; SDA owns the seam |

### 2.4 Declared capabilities (all 1)

| Declared concern | Bit | Evidence (rows / views) |
|---|---|---|
| Capability identity / user story / experience | **1** | `model.*`; `analysis.v_capability_graph_source`; `docs/capability-command-surface.md` |
| Scenarios (Input/Event/Outcome faces) | **1** | `sql/schema/declare-scenario.sql`; graph source `scenarios` |
| Operations (`invoke-port`, `invoke-scenario`) | **1** | `sql/migrations/*`; `target-architecture.md:170-172` |
| Ports / port bindings | **1** | `sql/migrations/declare-estate-providers.sql` |
| Transformations / expressions | **1** | `graphSource.semanticTransformations` |
| Contracts / schemas | **1** | `contractAuthorities`; `deriving-contract-schemas.md` |
| Provider bindings (`overlayBindings` / `providers`) | **1** | `embodiment-completeness.md:70-71` |
| Targets / target profiles | **1** | `v_declared_platform_implementation` |
| Provider profiles | **1** | `populate-platform-provider-bindings.sql`, `select-embodiment-provider-profiles.sql` |
| Topology (graph-native edge groups/recurrence) | **1** | `expose-...`/`declare-graph-native-consumer-topology.sql` |
| Authoring procedures (scaffold, bind, configure) | **1** | `sql/schema/authoring-procedures.sql` |
| Command mapping (`sfx.commands.json`) | **1** | `config/sfx.commands.json` |
| Telemetry authority | **1** | `SDA:kernel/semantic-authority/consumer/scenario-execution.telemetry-authority.json` |
| UI authority (future login flow) | **1** (absent today) | `target-experience.md:58-73` |

### 2.5 Projections, CLI, telemetry

| Concern | Bit | Evidence | Coverage |
|---|---|---|---|
| Database projection (rows → compiler JSON) | **1** rows, **0** view executor | `analysis.v_capability_graph_source`, `analysis.v_capability_execution_declaration`; `read-authority.mjs` | SQL + boot read (node) |
| Canonical graph **compiler** | **0** | `SDA:languages/typescript/runtimes/node/semantic-execution-graph/compiler.js` | per language (see §2.2) |
| Code embodiment projection (`project:consumer-capability`) | **0** tooling producing **1** artifacts | `SDA:tools/src/interfaces/consumer-projection/project.ts`; `SDA:tools/src/consumer-projection/providers/{node,csharp,python}/consumer-application-provider.ts` | node+csharp+python projectors; **java/go/cpp registry only** |
| Workspace projection (`consumer-workspace.authority.json`) | **1** | `target-experience-research-findings.md` §2(c) | SDA |
| Inverted projection (DB → capability JSON) | **1** (would-be; not implemented) | `target-experience-research-findings.md` §2(d) — "not implemented" | **gap** |
| CLI interface provider | **0** | `CLI:src/cli.mjs`, `delivery.mjs` | **node only** |
| Projection delivery | **0** boot | `src/projection-delivery.mjs` (`ADMITTED_TARGETS = node, python, csharp`) | node only |
| Telemetry transport (`SFX_OBSERVATION`) | **0** | `database-delivery.mjs:38-44` | node only |
| Execution drilldown / overlay | **0** | `src/execution-drilldown.mjs`, `semantic-address.mjs` | node only |

### 2.6 Eliminated (proof debt)

| Concern | Disposition | Evidence |
|---|---|---|
| `materialize-node`, `load-memory-scenario`, `prepare-database-capability`, `read-execution-graph`, `reveal-native-expressions`, `embodiment-delivery` | **E** | `target-architecture.md:70`; `scripts-disposition-review.md`; retired `2fafd6c` |
| `verify-node`, `verify-native-projection`, `verify-contract-fidelity` | **E** | `target-architecture.md:71` ("verifies artifacts that no longer exist") |
| `src/resolvers/node/*.mjs` (12) | **E** → declared capability | `target-architecture.md:65`; `platform-mechanic-honesty.md` |
| Platform-commit pinning / native-body parity | **E / defer** | `target-experience-research-findings.md` D2, D8 |

---

## 3. The multi-language obligation per resolver

Every row below is a **0** that exists in one language and is owed in the rest. Supported set per the estate: node/python/csharp; java/go "where applicable"; SDA additionally carries cpp, kotlin, swift.

| Resolver | node | python | csharp | java | go | Obligation / gap |
|---|---|---|---|---|---|---|
| Frontdoor/loader | ✅ | ❌ | ❌ | ❌ | ❌ | **The user's concrete finding.** `BOOT:bootstrap/bootstrap.manifest.json` hardcodes `languageResolver.target: "node"`, `runtimeModuleRef: languages/typescript/runtimes/node/admitted-consumer-platform.mjs`; `BOOT:platform/languages/` contains only `typescript`. `CLI:package.json` engines `node>=20`, bin `bin/sfx.mjs`. |
| DB connection + read session | ✅ | ❌ | ❌ | ❌ | ❌ | A python/csharp host must own its own connection/runner and its own `EXECUTE AS`/pin semantics. |
| Bootstrap installer | ✅ | ❌ | ❌ | ❌ | ❌ | `scripts/run-migration.mjs` is node; `sda-bootstrap` is a node package. |
| Kernel state machine + disposition | ✅ | ✅ | ✅ | ✅ | ✅ | complete |
| Graph compile/execute/overlay/schedule | ✅ | ✅ (registry + `platform/execution_graph.py`) | ✅ (registry + `Graph/*`) | ✅ (registry + `platform/*`) | ✅ (registry + `platform/graph_*`) | complete on paper |
| Transformation / pure / collection mechanics | ✅ | ✅ | ✅ | ✅ | ✅ | complete |
| Contract admission | ✅ | ⚠️ registry **0** `contractAdmissions`; code enforces plan catalog | ⚠️ registry **0** | ✅ 2 | ✅ 2 | **declaration/code divergence** |
| Effect ports: graph set | ✅ | ✅ 4 | ✅ 4 | ✅ 6 | ✅ 6 | csharp registry lacks credential/HTTP |
| Effect ports: domain set | ✅ 32 | ❌ (4) | ❌ (4) | ❌ (6) | ❌ (6) | **the central gap.** `platform-mechanic-honesty.md` table: python/csharp/java/go/kotlin/cpp/swift = 0 domain mechanics |
| OS credential | ✅ | ❌ | ❌ | ❌ | ❌ | `sda-os-environment-credential-port.v1` node-only |
| Vault | partial (env) | ❌ | ❌ | ❌ | ❌ | `next-experiences.md:166-179` — SDA request |
| CLI | ✅ | ❌ | ❌ | ❌ | ❌ | `CLI:` node-only |
| Presentation host | ✅ react/browser-dom | ❌ | WPF in `ScenarioKernel.Wpf` (PROJECT-UI) | javafx | ❌ | catalog `sda-ui-embodiment-capabilities` |
| Projector per target | ✅ | ✅ | ✅ | ❌ (registration only) | ❌ (registration only) | `projection-delivery.mjs:15` admits node/python/csharp only |

**The obligation restated:** a resolver is not "an SDA file." It is a promise that the concern runs in every language a capability may be projected to. The current 32-vs-4-vs-6 `eventPort` divergence is that promise broken silently: a capability that binds a domain port is node-only while the graph claims to be portable (`platform-mechanic-honesty.md:26-29`).

---

## 4. How the rule subsumes the earlier findings

### 4.1 The double authority trace (read redundancies)
`performance-optimization.md:113` records `graph_source` evaluated **twice**, the declaration document recordset read on **every** invoke though invoke uses only `recordsets[0]`, and the loader re-reading `run-declared-graph`'s own bundle (ranked #3/#4, `:125-126`). (If "double-trace" names the kernel testimony being both streamed on the sink *and* returned in `graphResult`, the classification is the same.)
- Under the transistor: the *declared authority* is 1; reading it twice is a **boot (0) implementation defect**, not a semantic one. The fix is "one read session, one authority read" (`:129`), which adds **no new resolver**.
- Contrast with the wrong fix: caching the assembled documents (#9) would add a materialized **1** — derived data that is not authoritative and must be generation-keyed (`:149-155`). The transistor says a cache is a legitimate 1 only if it is rebuildable and bounded; it is not a reason to keep a second resolver.

### 4.2 The performance bottleneck
- The 35 s/11–20 s cost is the **unfiltered declared view (1)** assembling the estate before the capability filter (`:109-110`). Fix: filter before aggregation — a 1-side fix.
- The ~1 s × 8 per-query pin is the **boot resolver (0)** re-acquiring coherence instead of reusing it (`:111`). Fix: one session — a 0-side fix.
- The transistor forbids the tempting shortcut of moving the read into a long-lived daemon as a casual optimization: a daemon is a **new 0** with its own per-language obligation and trust boundary. That is why #10 is correctly an "SDA/CLI change request," deferred rather than smuggled into the estate (`:132`).

### 4.3 Materialization / proof-debt
- Materialization was an attempt to make every mechanic a **1** (emitted native bodies) while also shipping a **0** per target to emit/verify them. Once the kernel interprets the declared graph, the emitted bodies are a *second* realization of meaning in every language — the exact multi-language cost the transistor exists to avoid.
- The transistor's disposition is therefore not "materialization was wrong" but "materialization was a **0 built for a 1 that the kernel now provides**." `target-architecture.md:70-71` eliminates it; `target-experience.md:185-188` names the residue proof debt. The earlier findings (`embodiment-review-findings.md`, `cross-target-hold-report.md`) are all symptoms of maintaining two realizations (node per-port bodies vs the plan) of one declared graph.

### 4.4 The projector
- The projector is a **0** (compiler) whose inputs and outputs are **1** (rows, plans, bindings). Its per-target providers are **0** per language (`SDA:tools/src/consumer-projection/providers/{node,csharp,python}`), and the **inverted projection** is the missing **1→1** direction requiring *no new resolver* (`target-experience-research-findings.md` §2(d)).
- The transistor clarifies the target-experience gap: `project` writes node/python/csharp only (`projection-delivery.mjs:15`, `ADMITTED_TARGETS`); java/go/cpp have target registrations but no admitted projector. That is a multi-language obligation on a **0**, not a data defect.

### 4.5 The vault
- Vault **provider** = **0** (SDA request, python/csharp absent); vault **declaration, reference names, injection rules, authority rules** = **1**; credential **values** = forbidden 1; **unseal** = boot **0** (`next-experiences.md:166-186`). The transistor separates the three bits the doc was already distinguishing informally ("SDA change request / data / boot"), and explains why the sealed binary does not remove the unseal resolver: orthogonal 0s.

### 4.6 The bootstrap binary
- The bootstrap is a **0**. Today it is a single-language realization (`BOOT:...bootstrap.manifest.json` `target: node`; `BOOT:platform/languages/typescript` only), which is exactly the user's finding.
- Sealing packages a **0**, and the attestation **digest** is a **1** verified by another **0** (the OS loader / CLI pre-spawn, `next-experiences.md:90-94`). The transistor predicts — and `next-experiences.md:94` already states — that **cross-language sealed bootstraps** are required: one per language that hosts the frontdoor/loader.

---

## 5. Cross-reference to the rubric

| Rubric instrument | What the transistor adds |
|---|---|
| **Minimality** — "least functionality that carries Input → Event → Outcome" (`rubric:13-15`) | Gives minimality a unit of account: each concern's *bit*. Adding a resolver is the maximum non-minimal act because it multiplies across languages; adding a declared row costs the one interpreter that already exists. |
| **Necessity test** — "if omitted, which event fails, and why?" (`rubric:91-93`, §9.3 `:257-266`) | Applied to executable concerns: if C can be **1**, a **0** fails the same event *and* adds a per-language obligation → "Not necessary." If C must be **0**, omission fails resolution in that language → "Needed now." |
| **"Wrong timing, not wrong"** (`rubric:288`; `target-experience.md:89-120`) | The rubric named the pattern (machinery built to satisfy a guard, not the outcome) but not the rule. The transistor identifies the premature decisions *as premature 0s*: native-body materialization and its verifiers, platform-commit pinning, native parity — resolvers built for a 1 (or for a cross-apply future) before the declared interpretation existed. |
| **Break-even for framework investments** (`rubric:121-127`) | The transistor makes the hidden term explicit: a resolver's maintenance cost is **per language**, so its break-even denominator is "supported languages," not "future examples." This is why a single-language domain port masquerading as portable is a defect (`platform-mechanic-honesty.md`). |
| **Inherited shape gains no authority by presence** (`rubric:87-88`) | A 0 that exists because it was the first realization (node-only bootstrap, node-only CLI, node-only OS credential) has no authority to remain the only realization once a second language is declared supported. |
| **The missing decision** | `target-architecture.md`'s disposition table (declared / code / eliminated) and its §"How to decide a new case" *do* encode the rule operationally (boot → code; materialization → eliminated; else → rows). What the docs lacked is (i) the **generative principle** underneath it and (ii) the **multi-language obligation** that follows from classing the boot and kernel as code. The transistor supplies both: *every 0 is a per-language bill; every 1 needs exactly one interpreter 0.* It is the decision rule that turns the disposition table from a list into a law — and it is why the bootstrap finding generalizes to every resolver in §3. |

---

## 6. Findings (not fixes)

1. **The bootstrap is a single-language resolver.** `BOOT:bootstrap/bootstrap.manifest.json` binds `languageResolver.target = node` and ships `platform/languages/typescript` only. Under the rule this is a defect once python/csharp are declared supported hosts.
2. **The CLI is a single-language resolver.** `CLI:package.json` (node engines, `bin/sfx.mjs`) and `src/cli.mjs`.
3. **The domain effect-port set is node-only while the graph claims portability.** 32 vs 4 vs 6 eventPorts (`SDA:kernel/semantic-authority/consumer/*`). This is the same defect `platform-mechanic-honesty.md` named.
4. **Python/csharp registries declare no `contractAdmissions`,** yet `implementation-strategy.md` units 17/18 landed native admission in `platform/consumer.py` and `AdmittedConsumerPlatform`. Declaration and realization diverge.
5. **The projector admits node/python/csharp only** (`projection-delivery.mjs:15`); java/go/cpp have registrations but no admitted projector — a 0 obligation on the projection resolver.
6. **The inverted projection does not exist** (`target-experience-research-findings.md` §2(d)); it is a 1→1 concern requiring no new resolver.
7. **The "double trace"** (`performance-optimization.md:113`) is a boot-0 defect, fixable without adding a resolver or a cache.

No files were modified.

---

# Research report: what a multi-language bootstrap requires

Read-only. No files, SQL, or SDA code were changed. Citations are `repo:line` where repo is `sfx-embody` unless prefixed `CLI:` (`sidefx-cli`), `DB:` (`sidefx-database`), or `SDA:` (`scenario-driven-architecture`).

---

## 1. The bootstrap today — responsibility inventory

The terminal is `sfx` (`CLI:`), which is transport only. The estate-side bootstrap is the Node process spawned by the delivery binding in `sfx.config.json:4-25`. It is three irreducible mechanics plus observation.

### 1.1 Frontdoor / process protocol

| Responsibility | Where |
|---|---|
| Spawn the declared bootstrap entry as a process; write the closed envelope to stdin; read one canonical JSON result from stdout | `CLI:src/delivery.mjs:33-54`, `56-105` |
| Envelope shape `sfx-command-delivery.v1` `{deliveryType, operation, request}` | `CLI:src/delivery.mjs:53`; `CLI:docs/process-delivery.md:55-68` |
| Result protocol: stdout object, `disposition`/`outcome`; stderr diagnostic + `SFX_OBSERVATION `-prefixed lines | `CLI:src/delivery.mjs:76-88`; `CLI:docs/process-delivery.md:77-83` |
| Result filtering (drops root `executions`/`observations` history) | `CLI:src/delivery-result.mjs:11,40-43` |
| Read stdin envelope with 9 MiB cap; JSON parse | `src/database-delivery.mjs:11-18` |
| Command validation (closed operation set, request fields, identity shapes) | `src/database-delivery.mjs:19`; `src/invoke-database-capability.mjs:175-202` |
| Load + validate runtime config (`databaseRoot`, `sdaRoot`) | `src/database-delivery.mjs:20-24` |
| Emit result to stdout; on failure emit `{disposition:'failed', errorCode}` and exit 4 | `src/database-delivery.mjs:59-64` |
| Observability flag `SIDEFX_OBSERVE=1` → stderr `SFX_OBSERVATION` lines, field-allowlisted | `src/database-delivery.mjs:38-44`; `src/observation-filter.mjs:3-16` |
| CLI-owned command mapping (declared `sfx-command-mapping.v1`) | `config/sfx.commands.json`; `CLI:src/commands.mjs:17-84` |

### 1.2 DB connection / query runner (irreducible)

| Responsibility | Where |
|---|---|
| Import DB config + driver (`mssql`/Tedious) from the separate repo | `src/database-delivery.mjs:27-28`; `DB:src/ingest/database.mjs:1,16-27` |
| Resolve connection string from env / Windows User-Machine env | `src/database-delivery.mjs:29-30`; `DB:src/ingest/database.mjs:6-15` |
| One pool + transaction + `pinModel` (applock + `sys.sql_modules` digest) + `EXECUTE AS sidefx_reader WITH NO REVERT` | `src/database-read-session.mjs:6-24`; `DB:src/query/model-pin.mjs:6-12` |
| `readQuery(statement, {input,rowLimit})`: parameter binding, retention limit, `normalizeSql`, result/digest shaping, coherence fields | `src/database-read-session.mjs:26-60`; `DB:src/query/run.mjs:5-12,44-55` |
| One-coherence-pin enforcement (`snapshotId`/`projectionDigest`/`viewDefinitionDigest`), rollback + close | `src/database-read-session.mjs:50-72`; `src/invoke-database-capability.mjs:221-222`; `src/read-authority.mjs:151-155` |
| Canonicalization primitive (`stable`, `hash`, `digest` = sha256 over canonical JSON) | `DB:src/core.mjs:7-14` |

### 1.3 Loader (reads declared authority, hands to the kernel)

| Responsibility | Where |
|---|---|
| Estate read: `analysis.capability_graph_source(...)` | `src/read-authority.mjs:23-32` |
| Closure read, optional resolver-map read, mechanic-definitions read | `src/read-authority.mjs:34-64,66-125,127-128` |
| Execution-delivery read (provider's `executionDelivery` semantics + declared `defaultTarget`) | `src/read-execution-delivery.mjs:3-23` |
| Receives `readQuery`/`readAuthority` injected by the frontdoor (no direct DB import on the invocation path) | `src/database-delivery.mjs:46-53`; target-architecture.md:192-210 |
| Command→operation table and result shaping | `src/invoke-database-capability.mjs:156-169,204-367` |
| CLI input mapping from the declared interface configuration | `src/invoke-database-capability.mjs:16-29,318-326` |
| **Dynamically import the declared provider module and call its export** | `src/invoke-database-capability.mjs:101-103` |
| Kernel entry resolution: `run-declared-graph` → `sda-semantic-execution-graph-execution.executeSemanticExecutionGraph` → Node `.mjs` | `src/invoke-database-capability.mjs:281,355`; `sql/migrations/declare-execute-semantic-execution-graph-capability.sql:19-30`; provider row resolved to `estateProvider` by `sql/migrations/bound-capability-invocation-reads.sql:117-121` |
| Declared-reader operations (`reveal`/`list`/`find`/`circuit`/`artifact`) | `src/invoke-database-capability.mjs:263-306` |
| `project` surface (off the invocation path; separate process) | `src/projection-delivery.mjs:9-137`; `sfx.config.json:27-34` |

### 1.4 Observation rendering (EPD)

| Responsibility | Where |
|---|---|
| Drilldown sink: select altitudes, stream cell/edge testimony, join to declared semantic address | `src/execution-drilldown.mjs:102-158` |
| Planned-vs-observed overlay and digest | `src/execution-drilldown.mjs:160-208` |
| Observed story in declared terms | `src/execution-drilldown.mjs:213-228` |
| Semantic join (testimony → scenario/responsibility/mechanic) | `src/semantic-address.mjs:12-28,56+` |

### 1.5 Isolation / permission model

| Responsibility | Where |
|---|---|
| Require `--experimental-permission` with no `fs.write`; refuse reads of cache roots | `src/restrict-memory-process.mjs:11-13` |
| Disable general child processes; allow only the pinned SDA `git rev-parse` and a bound `spawnDeclared` | `src/restrict-memory-process.mjs:14-39` |
| Flags that realize the boundary | `sfx.config.json:10-24` |

**Not on the invocation path:** `read-workspace-config.mjs` (regression harness config), `projection-delivery.mjs` (projection surface).

---

## 2. Responsibility split: language-neutral vs per-language

The transistor is: **0 = resolver (per-language code), 1 = declared (language-neutral data)**. The bootstrap is the terminal 0 (target-architecture.md:38-59); its *content* is mostly 1.

### (a) Language-neutral — shape, SQL, declared authority

| Concern | Nature | Where it lives today |
|---|---|---|
| Envelope/result protocol (`sfx-command-delivery.v1`, `disposition`/`outcome`/`evidence`, `SFX_OBSERVATION` prefix, field allowlist) | shape | `CLI:src/delivery.mjs`, `src/observation-filter.mjs:3-16` |
| Command mapping / operation set / input validation rules | shape (currently code + config) | `config/sfx.commands.json`, `src/invoke-database-capability.mjs:156-202` |
| Read SQL: graph source, closure, resolution map, mechanics, execution delivery, reader reads | SQL (should be shared) | functions/views in `sql/migrations/`; **inline strings** in `src/read-authority.mjs:23-128` and `src/read-execution-delivery.mjs:5-14` |
| Declared authority rows: capability/scenario/operations/ports/contracts/transformations | data | `sql/migrations/*` |
| Provider binding (`mechanicId → providerProfileId → module/export`) | data | `declare-run-declared-graph-capability.sql:27`; `sql/migrations/declare-estate-providers.sql:42-54` |
| Target list (`node`,`python`,`csharp`) and per-target implementation registry | data | `link-declared-target-provider-implementations.sql:99-103`; `declare-target-capability-provider.sql` |
| Coherence contract, digest/canonicalization *definition* | shape | `DB:src/core.mjs:7-14`; `src/read-authority.mjs:151-155` |
| Observation semantics (altitudes, cell/edge testimony shapes) | shape | `src/execution-drilldown.mjs:9-26` |

### (b) Per-language — must be reimplemented in each target

| Concern | Why per-language | Node realization today |
|---|---|---|
| DB driver + connection + parameter binding + transaction/pin/impersonation + result normalization | driver API and native bindings differ | `mssql`/Tedious, `DB:src/ingest/database.mjs`, `DB:src/query/run.mjs:5-12` |
| Dynamic load of the language kernel entry / provider modules | each runtime has its own loader | `import(new URL(...))`, `src/invoke-database-capability.mjs:101,121` |
| Permission/isolation model | no cross-language primitive exists | `process.permission` + `syncBuiltinESMExports` + child_process patch, `src/restrict-memory-process.mjs` |
| Observation rendering/framing | runtime object/stream APIs differ | `src/execution-drilldown.mjs`, `src/semantic-address.mjs` |
| Process/transport boundary (stdin/stdout/stderr) | runtime I/O differs | `src/database-delivery.mjs:10-18,59` |
| Canonical serialization implementation (`stable`/sha256) | must reproduce the same digest | `DB:src/core.mjs:7-14` |
| The kernel entry itself | kernel is per language by design | `SDA:languages/typescript/runtimes/node/semantic-execution-graph-execution-provider.mjs:115` |

**Finding (not a recommendation to edit):** the read SQL is *not* declared in `sql/`; it is embedded in the Node loader (`read-authority.mjs`, `read-execution-delivery.mjs`). That is language-neutral content trapped in one language's realization, and it is the largest obstacle to a thin per-language boot. `bound-capability-invocation-reads.sql:117-121` also resolves the `estateProvider` module with no target input (`fn_estate_provider_semantics(@provider_id)`), so the current invocation path can only ever select one language's implementation.

---

## 3. What each target language needs

Per-language kernel entries already exist and are symmetric carrier-callable functions:

- **Node:** `SDA:languages/typescript/runtimes/node/semantic-execution-graph-execution-provider.mjs:115` — `executeSemanticExecutionGraph(configuration, input, context)`; compilation at `semantic-execution-graph-compilation-provider.mjs`; compiled-seam host at `admitted-consumer-platform.mjs`.
- **Python:** `SDA:languages/python/src/scenario_kernel/adapters/semantic_execution_graph_execution_provider.py` (carrier-callable, imports declared providers under `context["sdaRoot"]`); projected-seam host `SDA:languages/python/src/scenario_kernel/platform/consumer.py:823` (`main`/`_execute_graph`).
- **C#:** `SDA:languages/csharp/src/ScenarioKernel.Adapters/Graph/SemanticExecutionGraphExecutionProvider.cs:21` — `ExecuteSemanticExecutionGraph(configuration, input, context, …)`; projected-seam host `SDA:languages/csharp/src/ScenarioKernel.Adapters/Consumer/AdmittedConsumerPlatform.cs:16,66`.

A bootstrap realization per language needs:

| Need | Node | Python | C# |
|---|---|---|---|
| DB driver | `mssql`/`tedious` (already) | `pyodbc` (ODBC Driver 18) or `pymssql`; both support transactions, parameters, `EXECUTE AS`, `sp_getapplock` | `Microsoft.Data.SqlClient` (ADO.NET) |
| Read estate views | call `analysis.capability_graph_source` and the same closure/resolution/mechanic/execution-delivery statements | same statements (currently inline in Node) | same statements |
| Session/pin/impersonation | `pinModel` + `EXECUTE AS … WITH NO REVERT` | reimplement pin as plain SQL (portable) | reimplement pin as plain SQL |
| Kernel call | dynamic `import()` of the declared module | `importlib` of the declared python module/provider | reflection/`AssemblyLoadContext` of the declared assembly/type (`SemanticExecutionGraphExecutionProvider.cs:37`) |
| Transport | stdin/stdout/stderr process | same | same |
| Isolation | `--experimental-permission` + `restrict-memory-process.mjs` | **no built-in equivalent** — needs OS sandbox or a new per-language primitive | **no built-in equivalent** — needs AppDomain/CAS or OS sandbox |
| Digest parity | `stable`+sha256 | must reproduce identical canonical bytes | must reproduce identical canonical bytes |

The DB side is highly portable: `EXECUTE AS`, `sp_getapplock`, `sys.sql_modules`, `JSON_VALUE`/`OPENJSON`, and the parameter shapes are all plain SQL. Only driver plumbing, module loading, isolation, and I/O framing are genuinely per-language.

---

## 4. Recommended shape: (a), with data-driven selection

**Recommendation: (a) — one thin boot executable per target language — and boot selection is declared data.**

Rationale against the alternatives:

- **(b) a single declared boot capability resolved per target** fails the regress proof (target-architecture.md:38-45): executing the declared boot needs a reader/runner, which needs another boot. There is no first executor.
- **(c) the bootstrap as a declared capability whose resolvers are per-language** is a category error for the *frontdoor/loader/DB-runner*: those are exactly mechanics that cannot be declared (target-architecture.md:47-59). A declaration still needs a per-language executor to run it, so (c) collapses into (a) while pretending the regress is resolved.
- **(a)** is the only shape consistent with the transistor: the boot is the terminal **0** (per-language resolver); everything it consumes — protocol, read SQL, authority, provider bindings, targets — is **1**. The *choice* of which boot runs is itself data (delivery binding / declared target), which is the "0 selected by 1" without declaring the 0.

**Smallest correct shape.** One per-language terminal that implements only the irreducible three, with everything else shared as data:

1. **Neutral (shared, one authoring):** envelope/result protocol, observation field allowlist, command/operation spec, read SQL + views, declared authority, provider bindings, target registry, coherence/canonicalization rules.
2. **Per-language (thin):** DB driver + connection/pin/impersonation + normalization; dynamic load of the declared kernel/provider module; observation framing; isolation realization; stdin/stdout/stderr.
3. **Selection (data):** delivery binding per target (`database-memory-node`/`-python`/`-csharp` in `sfx.config.json`); the declared `defaultTarget`/`targets` (`read-execution-delivery.mjs:10-18`) picks it. The per-target provider registry (`declare-target-capability-provider.sql`, `v_target_capability_provider`) already models this, but the invocation path currently ignores it because `fn_estate_provider_semantics` is not target-aware.

This keeps "kernels resolve language; everything else is data" intact: the boot is code *because it cannot be otherwise*, and its language is a data selection, not a code decision.

---

## 5. Interaction with the sealed-binary and vault work

**Sealing (next-experiences.md §2).** If the bootstrap exists per language, sealing is per-language *and* per-OS/arch: Node SEA/`postject` for node; a Python freezer (PyInstaller/Nuitka) or embedded interpreter for python; .NET single-file self-contained / ReadyToRun or NativeAOT for csharp. Consequences:

- The sealed set is frontdoor + loader + DB runner + kernel + providers *per language*; sealing node alone leaks nothing about python/csharp, but python/csharp still need their own sealed carriers. "Cross-language sealed bootstraps" is already classed as an SDA/platform request (`next-experiences.md:94`).
- The **DB connection/query runner stays irreducible code** (`target-architecture.md:47-52`), bundled or a second signed component, and the frontdoor owns it (`next-experiences.md:98-101`). Native DB bindings complicate sealing (ODBC/`Microsoft.Data.SqlClient` native deps; SEA and native addons were flagged as risks at `next-experiences.md:84-87`) — signing/attestation must cover the driver, and the CLI must verify the pinned digest **before spawn** (`next-experiences.md:91-93`), per target boot.

**Vault (next-experiences.md §4).** The unseal step belongs to the boot, the irreducible frontdoor (`next-experiences.md:180-186`). Per-language boot therefore means per-language unseal: DPAPI / Windows Credential Manager / macOS Keychain / libsecret for node; keyring/DPAPI for python; `ProtectedData`/Credential Manager for C#. The existing boot defect — the DB connection string copied into the delivery process env (`src/database-delivery.mjs:29-30`) — must be removed in **every** language by resolving at the connect boundary, handing in a live handle, and dropping the value (`next-experiences.md:175-179`). Vault *providers* per language are SDA requests; the *unseal* is boot code per language, and a declared capability cannot resolve it.

---

## Classification summary

| Concern | Class |
|---|---|
| Envelope/result protocol, observation allowlist, command/operation spec | **data** (shape; author once, consume per language) |
| Read SQL (graph source, closure, resolution, mechanics, execution delivery, readers) | **data** — should move out of `src/read-*.mjs` into `sql/`/declared reads |
| Declared authority, provider bindings, target registry | **data** (already rows) |
| Per-language boot executable (frontdoor + loader + DB runner + transport) | **per-language resolver** (irreducible boot code, one per target) |
| DB driver, connection, pin, impersonation, normalization, canonical serialization | **per-language resolver** (driver plumbing; SQL content is neutral) |
| Dynamic kernel/provider module loading | **per-language resolver** |
| Isolation/permission model (node `--experimental-permission` + `restrict-memory-process.mjs`) | **per-language resolver**, with an **SDA change request** if python/csharp have no equivalent primitive |
| Target-aware `estateProvider` resolution (today `fn_estate_provider_semantics(@provider_id)` has no target) | **SDA/DB change request** (cross-language resolution) |
| Python/C# provider rows for the estate invocation ports (today only Node is declared for `sda-semantic-execution-graph-execution-port.v1`) | **data** + **SDA embodiment request** for the kernel entries' non-node bindings |
| Sealed per-language/per-OS build; CLI pre-spawn digest verification; kernel/provider sealing | **boot/estate code** + **SDA/platform request** |
| Boot unseal per language; removing the DB connection-string env exposure | **boot** (per-language) |
| Vault provider per language | **SDA request** |

If you want, I can write this to `docs/multi-language-bootstrap.md` (a docs-only change) — say the word, since the current instruction was read-only.

---

# The multi-language resolver obligation — inventory, conformance, declared surface, misclassifications, enforcement

Read-only research report. `SDA:` prefixes the scenario-driven-architecture repo; unprefixed paths are `sfx-embody`; `DB:` is sidefx-database. No files were changed.

## 0. Snapshot of what actually exists (and what the docs assume)

| Fact | Evidence |
|---|---|
| SDA carries **six** language ecosystems: node(typescript), python, csharp, **java, go, cpp** | `SDA:languages/` |
| Every one has a kernel, a `<lang>-mechanic-registry.authority.v1.json`, a `scenario-kernel-<lang>.conformance.json`, a binding, and a scheduler in `language-graph-v1-conformance.json` | `SDA:kernel/semantic-authority/consumer/`, `SDA:conformance/execution-graph/language-graph-v1-conformance.json` |
| Every binding status is `IMPLEMENTING` (none `ADMITTED`) | `SDA:languages/<lang>/binding/scenario-kernel-<lang>.binding.json:7` |
| The **consumer projector's target union is only `"node" | "csharp" | "python"`** | `SDA:tools/src/consumer-projection/model/consumer-workspace-facts.ts:3` |
| The per-target platform catalog admits **node 37, python 20, csharp 22, java 3, go 3, cpp 3** capabilities | `SDA:kernel/semantic-authority/consumer/sda-platform-capabilities.semantic-authority.json` (grouped counts) |
| The target docs describe the trio as node/python/csharp with "java/go pending" | `docs/target-architecture.md:18`, `docs/embodiment-completeness.md:18-46` |

So: the **docs' obligation** (every mechanic in node/python/csharp; java/go pending) is real and binding, while the **SDA repo already carries java/go/cpp resolvers** that are structurally present but (a) not consumer-projection targets, (b) not admitted in the platform catalog beyond three capabilities, and (c) not covered by the cross-language projector/digest path. Both statements must be reported; neither cancels the other.

Legend for the inventory: **R** = real implementation, **P** = partial/subset, **—** = absent, **Δ** = present as structure but not admitted/declared for that target.

---

## 1. Resolver inventory (resolver → languages present → gap)

### 1a. Kernel-internal resolvers (language mechanics)

| Resolver | node | python | csharp | java | go | cpp | Gap |
|---|---|---|---|---|---|---|---|
| Graph compilation | R | R | R | R | R | R | none |
| Graph scheduling | R | R | R | R | R | R | none |
| Transformation evaluation (pure language) | R | R | R | R | R | R | none (cpp not in the vector README table) |
| Schema / contract admission | R | P | P | R | R | R | python/csharp registry `contractAdmissions: []` |
| Pure semantic-value mechanics | R | R | R | R | R | R | 4 declared mechanics have **no** embodiment anywhere |
| Collection / recurrence mechanics | R | R | R | R | R | R | per-pattern providers declared only for node/python/csharp |
| Declared data reads | R | R | R | R | R | R | only node has a DB query runner to execute the SQL |
| Memory-scenario loader | R | R | R | R | R | R | target says this is *eliminated*, not a per-language resolver |
| Content-addressed artifact store | R | R | R | R | R | R | catalog-admitted for all six |

Citations:
- Compilation: `SDA:languages/typescript/runtimes/node/semantic-execution-graph-compilation-provider.mjs`, `SDA:languages/typescript/runtimes/node/semantic-execution-graph/compiler.js`; `SDA:languages/python/src/scenario_kernel/adapters/semantic_execution_graph_compilation_provider.py` + `..._compiler.py`; `SDA:languages/csharp/src/ScenarioKernel.Adapters/Graph/SemanticExecutionGraphCompilationProvider.cs` + `SemanticExecutionGraphCompiler.cs`; `SDA:languages/java/.../platform/SemanticExecutionGraphCompilationProvider.java` + `...Compiler.java`; `SDA:languages/go/platform/graph_compilation_provider.go` + `graph_compiler.go`; `SDA:languages/cpp/graph/execution_graph_compilation_provider.cpp` + `execution_graph_compiler.cpp`.
- Scheduling: node `semantic-execution-graph/scheduler.js` (`GraphTokenScheduler`); python `platform/execution_graph.py`; csharp `Graph/SemanticExecutionGraphScheduler.cs`; java `platform/SemanticExecutionGraphScheduler.java`; go `platform/execution_graph.go`; cpp `graph/execution_graph_scheduler.cpp`. All six are named in `SDA:conformance/execution-graph/language-graph-v1-conformance.json:6-43` as `ADMITTED` for that fixture.
- Transformation evaluators: node `semantic-transformation-evaluator.mjs`; python `adapters/semantic_transformation_evaluator.py`; csharp `Consumer/SemanticTransformationEngine.cs`; java `adapters/SemanticTransformationEngine.java`; go `platform/platform.go` (`SemanticTransformationEngine`); cpp `graph/transformation_evaluator.cpp`. Vector runner/bridge table is `SDA:conformance/execution-graph/mechanics/README.md:55-68` — **it omits cpp even though `SDA:conformance/execution-graph/cpp-mechanic-evaluator-bridge.mjs` exists.**
- Schema admission: node `schema-contract-admission-provider.mjs`; csharp `Adapters/Schema/SemanticContractCatalogAdmission.cs`, `JsonSchemaContractValidator.cs`; java `platform/SemanticContractCatalogAdmission.java`; go `platform/graph_contract_catalog_admission.go`; cpp `graph/contract_catalog_admission.cpp`. Registry declarations (`contractAdmissions`): node, java, go, cpp declare direct/identity entries; **python and csharp registries declare `[]`** (`python-mechanic-registry...json:149`, `csharp-mechanic-registry...json:141`) although unit 17/18 added contract-catalog enforcement in their consumer platforms.
- Pure + collection mechanics: per-language registries declare `graphProviderProfiles` (pure) and `schedulerProviders` in all six; `executionPatterns` (sequence/selection/broadcast/join/recurrence/return/failure/cancellation/decomposition/for-each) are declared only in the node/python/csharp registries — java/go/cpp rely on their scheduler without per-pattern provider declarations.

### 1b. Platform effect ports and evolution ports

| Resolver | node | python | csharp | java | go | cpp | Gap |
|---|---|---|---|---|---|---|---|
| External credential-reference binding `sda-external-credential-reference-binding-port.v1` | R (ADMITTED) | R (ADMITTED, unit 17) | R (ADMITTED, unit 18) | Δ code + registry, **not catalog-admitted** | Δ | Δ | java/go/cpp not admitted |
| Governed HTTP exchange `sda-governed-http-exchange-port.v1` | R (ADMITTED) | R (ADMITTED) | R (ADMITTED) | Δ | Δ | Δ | java/go/cpp not admitted |
| OS-environment credential `sda-os-environment-credential-port.v1` | R (ADMITTED) | — | — | — | — | — | **node-only** |
| Vault provider (OS keychain/DPAPI/KeyVault/… ) | — | — | — | — | — | — | **absent everywhere; SDA request** |
| The other ~28 node evolution ports¹ | R (ADMITTED) | — | — | — | — | — | **node-only** |

¹ node registry `eventPorts` count = 32 (`SDA:kernel/semantic-authority/consumer/node-mechanic-registry.authority.v1.json:192-432`), including `sda-json-authority-ingestion-port.v1`, `sda-proof-binding-evaluation-port.v1`, the three `sda-scenario-semantic-carrier-*-port.v1`, `sda-generic-llm-connector-port.v1`, `sda-governed-repository-observation-port.v1`, `sda-governed-external-root-*`, `sda-bounded-base64-byte-digest-port.v1`, `sda-semantic-vector-index.v1`, `sda-governed-serial-execution-port.v1`, `sda-projected-capability-invocation-port.v1/v2`, and the governed tooling/file-system ports. python/csharp registries each declare **4** event ports (compilation, execution, overlay, filesystem-artifact-store); java/go/cpp each declare **6** (those four plus the two credential/HTTP effect ports). None of the python/csharp/java/go/cpp registries carry the remaining node ports.

Citations: node `external-credential-reference-binding-provider.mjs`, `governed-http-exchange-provider.mjs`, `semantic-execution-graph-effect-provider.mjs`; python `SDA:languages/python/src/scenario_kernel/platform/governed_effect_ports.py`; csharp `SDA:languages/csharp/src/ScenarioKernel.Adapters/Graph/GovernedEffectPorts.cs` (lines 65-67 register both ports); java `SDA:languages/java/.../platform/GovernedEffectPorts.java:65-67` (delegated to from `SemanticExecutionGraphConsumerHost.java:365`); go `SDA:languages/go/platform/graph_governed_effect_ports.go` + `graph_consumer_host.go:453-465`; cpp `SDA:languages/cpp/graph/governed_effect_ports.cpp` + `execution_graph_effect_provider.cpp:77-83`. Node-only OS credential: `SDA:languages/typescript/runtimes/node/os-environment-credential-provider.mjs`; catalog admits it for node only (and `docs/next-experiences.md:166-170` states python/csharp have no OS-credential resolver). The vault provider is a **request, not present** (`docs/next-experiences.md:144-186`).

### 1c. Estate/boot resolvers (sfx-embody)

| Resolver | node | python | csharp | java | go | cpp | Gap |
|---|---|---|---|---|---|---|---|
| Bootstrap frontdoor | R | — | — | — | — | — | node-only by construction (irreducible) |
| Loader | R | — | — | — | — | — | node-only |
| DB connection/query runner | R | — | — | — | — | — | node-only; lives in `DB:` |
| Delivery/workspace config | R | — | — | — | — | — | node-only boot config |
| `run-declared-graph` overlay/provider binding | R | — | — | — | — | — | estate overlay is node-only (its `providers` name `languages/typescript/...`) |
| Memory-scenario loader (estate capability) | R (residual) | — | — | — | — | — | target says **eliminated**, not ported |
| Presentation / UI projection | R (terminal + React/DOM claimants) | — | R (WPF/Avalonia) | R (JavaFX) | via kotlin? | R (WinUI3/AppKit) | split across SDA presentation seam, not an estate resolver |

Citations: frontdoor `src/database-delivery.mjs:27-53`; loader `src/invoke-database-capability.mjs`; declared reads `src/read-authority.mjs`; delivery binding `sfx.config.json:4-35`; command mapping `config/sfx.commands.json`; overlay `sql/migrations/declare-run-declared-graph-capability.sql:27` and `sql/migrations/complete-run-declared-graph-pure-mechanic-bindings.sql`; residual estate-module rows (7, incl. `load-memory-scenario`) `sql/inspect/hand-authored-module-references.sql` and `docs/implementation-strategy.md:93-98`; presentation seam `docs/narration-projection-disposition.md`; per-language UI claimants under `SDA:languages/{typescript/presentation, java/presentation/javafx, swift, kotlin, cpp/presentation/winui3}` and csharp `Wpf`/`Avalonia`.

---

## 2. Conformance requirement and current coverage

**The requirement (from `docs/embodiment-completeness.md:142-154` and `docs/target-experience.md:16-21`):** an embodiment is complete only when *every executable mechanic a capability's execution uses is embodied in code, per target language, and bound in the embodiment itself*, with **digest parity** as the cross-language proof — same `canonicalGraphDigest`, same outcome digest, same dispositions; targets differ only in per-target `realizedGraphDigest`. No passthrough; no host default.

**Where conformance is established today**

| Layer | Corpus / mechanism | Coverage | Evidence |
|---|---|---|---|
| Per-mechanic meaning | `SDA:conformance/execution-graph/mechanics/*.v1` — 36 declared, **32 with an observing embodiment**, 157 vectors, 17 decisions | node, python, csharp claim 157/157, 32/32; java/go documented in the runner table; **cpp has a bridge but is omitted from the table** | `SDA:conformance/execution-graph/run-mechanic-conformance.mjs`; `.../mechanics/README.md`; `docs/cross-target-embodiment.md:24-25,87-89` |
| Graph-level parity | `SDA:conformance/execution-graph/language-graph-v1-conformance.json` — one `canonicalGraphDigest sha256:c0851cb6…`, `expectedObservedPathDigest sha256:995252b6…` | targets node, csharp, python, **java, go, cpp all listed `ADMITTED`** for this fixture | same file |
| Kernel shape | `SDA:languages/<lang>/conformance/scenario-kernel-<lang>.conformance.json` (semantic-object + execution-step embodiments, data authorities) | all six | per-language files |
| Estate path | `run-declared-graph` overlay covers the full pure set | node only (16 → 37 bindings; `required_pure_unbound: 0`) | `sql/migrations/complete-run-declared-graph-pure-mechanic-bindings.sql`; `docs/performance-optimization.md:80-91` |
| Capability outcome | equity `resolve-equity-market-price-evidence` → `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` | node/python/csharp | `docs/implementation-strategy.md:127-144` |

**Where conformance is NOT established**

1. **The projector cannot prove java/go/cpp parity at all** — `ConsumerProjectionTarget = "node" | "csharp" | "python"` (`SDA:tools/src/consumer-projection/model/consumer-workspace-facts.ts:3`). The `canonicalGraphDigest`-vs-`realizedGraphDigest` proof in the target docs can only be run for three targets.
2. **Java/go/cpp are not catalog-admitted for the effect ports they implement.** Their registries and code carry credential/HTTP binding, but the platform catalog lists only 3 capabilities each (`sda-<lang>-consumer-platform.v1`, `sda-<lang>-semantic-transformation.v1`, `sda-<lang>-filesystem-artifact-store.v1`). The gate (`PlatformResponsibilityResolver`) resolves against the catalog, so a capability needing an effect port is `MISSING` for java/go/cpp even though the code exists.
3. **All six bindings are `IMPLEMENTING`, none `ADMITTED`.**
4. **Four declared mechanics have no observing embodiment in any language**: `bind-path`, `canonical-json-byte-validation`, `retained-lineage-authorization`, `canonical-artifact-byte-planning` (`SDA:conformance/execution-graph/mechanics/README.md:70-74`; the estate deliberately does not bind them, `complete-run-declared-graph-pure-mechanic-bindings.sql:20-25`).
5. **Only node has an OS-credential resolver**; no language has a vault provider.
6. The estate has **no per-language invocation path** — the loader/frontdoor/DB runner are node (`src/database-delivery.mjs`).

---

## 3. The declared (1) surface — and it is language-neutral

The `1` side is selection and configuration only; it is JSON/rows and contains no behavior. It is already language-neutral (ids, statements, schemas, expressions, digests), which is what allows the same canonical graph to be projected per target.

| Declared thing | Where (authority) | Language-neutral? |
|---|---|---|
| Capabilities | `model.estate_capability`, `model.capability`; schema `SDA:kernel/schemas/capability.v3.schema.json` | yes |
| Scenarios | `model.scenario`, `model.capability_scenario`; `SDA:kernel/schemas/scenario.v2.schema.json` | yes |
| Operations | `model.execution_operation`, `model.operation_port_invocation`; `SDA:kernel/schemas/execution-cell.schema.json` | yes |
| Ports | `model.port`, `model.port_version`; `SDA:kernel/schemas/consumer-interface-authority.schema.json` | yes |
| Transformations | `model.semantic_transformation`; `SDA:kernel/schemas/semantic-transformation-authority.schema.json` | yes |
| Contracts | `model.contract_version`, `model.contract_schema`; `SDA:kernel/schemas/*contract*`; closure TVF `sql/schema/contract-schema-closure.sql` | yes |
| Provider bindings | `model.provider`, `model.provider_definition`; `SDA:kernel/schemas/provider-profile.v2.schema.json` | yes |
| Targets | `analysis.v_target_provider_implementation`, `analysis.v_target_provider_profile`, `v_embodiment_target_selection` | yes |
| Provider profiles | `model.provider_profile_version`, `model.provider_mechanic_implementation`; `sda-mechanic-registry.authority.v1` per language | yes |
| Topology (graph-native) | `SDA:kernel/schemas/semantic-execution-graph.schema.json`, `execution-edge.schema.json`, `execution-graph-realization-overlay.schema.json` | yes |
| `overlayBindings` / `providers` | port `configuration` in `sql/migrations/declare-run-declared-graph-capability.sql:27`; `SDA:kernel/contracts/execution/scenario-kernel-data-authority.json` | yes (ids, digests, module paths — **the module path is the one non-neutral value**, see §4) |
| Binding selection/config (scenarios, statements, credentials, expressions, schemas) | `docs/embodiment-completeness.md:62-75` | yes |

The single place where "declared" carries language *behavior* rather than language-neutral data is the `providers` binding: `providerProfileId → module/export` names a concrete source file (e.g. `languages/typescript/runtimes/node/...`). That is expected — the module path is the selector for the per-language implementation — but it is exactly where a target with no such module silently loses the mechanic. The **mechanic id → profile** half (`overlayBindings`) is neutral; the **profile → module** half is per-target.

---

## 4. Misclassifications and dispositions

The 0/1 test: a concern is correctly classified when it is either (1) fully declared as neutral data, or (0) implemented as a real resolver in **every** target language. Anything in between is misclassified.

| # | Concern | Current classification | Why it is misclassified | Correct disposition |
|---|---|---|---|---|
| M1 | Node-only evolution effect ports (`sda-json-authority-ingestion-port.v1`, carrier ports, vector index, LLM connector, governed external-root/observation/serial ports, …) | Declared once, in `node-mechanic-registry...`; node catalog-admitted | They are platform **mechanics (0)** but exist in one language; capabilities assume they are portable; the estate overlay binds them to node modules | **Implement the resolver in each required language (0)** if a capability needs it, else leave node-only and make the capability's target constraint explicit and *fail closed* in other targets |
| M2 | OS-environment credential + vault | node resolver + node catalog entry | A credential resolver is a platform mechanic (0); only node has one; no vault provider exists | **Implement per language (0)**; the vault provider is an **SDA change request** (`docs/next-experiences.md:166`), the vault declaration/rules are **data (1)** |
| M3 | The four unembodied pure mechanics (`bind-path`, `canonical-json-byte-validation`, `retained-lineage-authorization`, `canonical-artifact-byte-planning`) | Declared `pure`, in `sourceProfiles: semantic-value-provider.v1`, but no target observes them | Declared as portable pure mechanics (would be 1) with no embodiment in any language (not 0); estate deliberately excludes them from the overlay | **Either implement (0) or re-declare out of the portable pure set (1)** — they must not sit in the pure set while unobserved; a capability that needs one is an SDA embodiment request |
| M4 | java/go/cpp effect ports and contract admissions | Code + registry present; **not catalog-admitted** | Present as resolvers (0) but invisible to the gate (`PlatformResponsibilityResolver` reads the catalog), so capability requirements resolve `MISSING` while code exists | **Admit them in the catalog (1/data)** once their conformance vectors pass; until then the gate is right to report MISSING |
| M5 | Consumer projection target union excludes java/go/cpp | `ConsumerProjectionTarget = node|csharp|python` | The projection path claims to be per-language but silently cannot emit or prove three of the six languages that have kernels | **Either extend the union (0) or declare java/go/cpp explicitly out of consumer scope (1)**; do not leave the mismatch implicit |
| M6 | Double-trace / presentation rendering | CLI terminal + `--trace` (`sidefx-cli/src/render.mjs:175-208` renders story **and** the hierarchical trace); SDA presentation seam; plus the frozen migration oracles `V3PlanEmbodiment.cs`, `v3-plan-embodiment.mjs` | Rendering is neither fully declared (layout is not meaning) nor a per-language resolver; three renderers exist for one authority | **Reading + selection = declared (1)** (already: `read-capability-meaning`, `list-capabilities`, `read-retained-publication`); **rendering = per-surface presentation mechanic** (terminal / SDA seam), and the frozen `V3PlanEmbodiment`/`v3-plan-embodiment` oracles are **eliminated**. `narrate-*`/`diagram-*` are **not** estate capabilities (`docs/narration-projection-disposition.md`) |
| M7 | Bootstrap frontdoor / loader / DB runner | node boot code | Not a resolver to port; the irreducible exception. But the estate's single node boot means "every language host" has no boot of its own in this repo | **Code (keep)** — the irreducible three. Cross-language hosts are SDA's `AdmittedConsumerPlatform`/`platform.consumer`; the node estate delivery binding is boot config, not data |
| M8 | Memory-scenario loader | Estate capability row naming a node module; target says eliminated | It is being carried as a resolver (0, node-only) while the target classifies it materialization → eliminated | **Eliminate** (`docs/target-architecture.md:70`); if a projected consumer path needs to load a plan, that is each target's `AdmittedConsumerPlatform` code, not an estate resolver |
| M9 | Residual estate-module references in rows (`src/resolvers/*`, `materialize-node`, `load-memory-scenario`, the 7 remaining estate-module PROVIDER rows) | Data naming code modules | A port/provider whose `configuration` names a module is a **data defect** by the port standard | **Re-declare (1)** each to a platform mechanic (`platformCapabilityId`) or a declared read `{statement, resultColumn}` (`docs/target-architecture.md:150-162`; inspection `sql/inspect/hand-authored-module-references.sql`) |
| M10 | Python/csharp registries declare `contractAdmissions: []` while the platforms implement admission | Structure present, declaration absent | The registry is the per-language declaration surface; an empty entry reads as "not provided" even where the consumer platform enforces contracts | **Declare the admission entries (1)** in the python/csharp registries (mirror node/java/go/cpp) |

**The pattern across M1/M2/M4/M5/M7/M8:** the estate declares a *single* portable graph, and the impl has quietly promoted *node* from "one target" to "the host". The target-architecture rule (`docs/target-architecture.md:174-182`) already requires every `mechanicId` a compiled graph requires to have both an `overlayBindings` entry and a `providers` entry naming the **per-language** implementation. The obligation is therefore mechanical: when a required mechanic lacks a per-language provider, the embodiment must refuse, not fall back.

---

## 5. Recommended smallest mechanism to make the obligation explicit and enforceable

**Do not invent a new subsystem.** Three small pieces already exist and only need to be connected. The existing pieces:

1. **Per-language resolver registries** — `SDA:kernel/semantic-authority/consumer/<lang>-mechanic-registry.authority.v1.json`. These *are* the declared registry the recommendation asks for; they already name modules/exports/factories, digests, and `platformCapabilityId`s.
2. **The per-graph required set** — the projector already compiles `G.requiredProviderSlots` and the per-target `realizedGraphDigest` (`SDA:kernel/schemas/semantic-execution-graph.schema.json`; `docs/embodiment-completeness.md:124-141`).
3. **The existing parity gate** — `SDA:kernel/semantic-authority/consumer/sda-platform-mechanic-parity.semantic-authority.json` (`profileId: sda-consumer-mandatory-mechanics.v1`, `appliesToBindingStatuses: ["IMPLEMENTING"]`, 13 required mechanics) enforced by `SDA:tools/src/consumer-projection/proof/mechanic-conformance-observer.ts` and `SDA:tools/src/consumer-projection/authority/platform-responsibility-resolver.ts`. It already emits `INCOMPLETE`/`MISSING` per language and requires each required mechanic to be `ADMITTED` and to `providesMechanics` include it. Schema: `SDA:kernel/schemas/sda-platform-mechanic-parity.schema.json`.

**The smallest change that closes the gap:**

1. **Widen the parity profile from platform-level to graph-level.** Keep `sda-consumer-mandatory-mechanics.v1` but add a derived `requiredMechanics` set per compilation: the union of every compiled cell's `mechanicId`/`platformCapabilityId`, plus the effect ports and declared reads. The projector already knows this set; feed it to the existing `MechanicConformanceObserver` instead of relying on the fixed 13-item list. Disposition for a target that cannot resolve a required mechanic: `INCOMPLETE` (already produced), and the projection must **fail closed** (`--full-mechanics` already enforces "every canonical provider slot bound per target", `config/sfx.commands.json:140`).

2. **Make the catalog complete for every language whose registry admits a mechanic.** Admit the java/go/cpp effect ports and contract admissions (`sda-external-credential-reference-binding-port.v1`, `sda-governed-http-exchange-port.v1`, `sda-schema-contract-admission.v1`) once their vectors pass, so `PlatformResponsibilityResolver` stops reporting `CAPABILITY_NOT_FOUND`/`MECHANIC_NOT_PROVIDED` for code that exists (M4). And declare `contractAdmissions` for python/csharp (M10).

3. **Run the vector corpus as the conformance gate for the registry**, not just as a dev tool. `SDA:conformance/execution-graph/run-mechanic-conformance.mjs` already takes any evaluator and returns pass/fail per mechanic. Wire its result into `MechanicConformanceObserver`'s `proofCurrent` (`mechanic-conformance-observer.ts:16-17` already hashes a `proofInputDigest`). A registry entry without a current passing vector is *declared but unproven* and must not be admitted. Add cpp to the documented target table (M: README omits it).

4. **Extend or explicitly scope `ConsumerProjectionTarget`.** Add `"java" | "go" | "cpp"` (M5) so the digest-parity proof can run for them, or declare them out of consumer projection in the workspace authority. The former is one type union plus their projection providers (which already exist: `SDA:tools/src/projection/providers/{java,go}/...`, `SDA:tools/src/consumer-projection/projection/{...}`); the latter is an explicit declaration, not a silent omission.

**Fail-closed rule (the capstone):** a capability invokes only if, for its target, every `requiredProviderSlot` in the compiled graph resolves through the target's registry to a per-language provider with a current conformance proof, and every contract is in the catalog. The kernel already raises `MISSING_SDA_PLATFORM_CAPABILITY` (`SDA:languages/java/.../SemanticExecutionGraphConsumerHost.java:370-376`) and `SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING`; the estate must surface these as typed refusals with the missing `mechanicId`/target, never retry on node. That single rule turns "the resolved missing module is always a re-declaration" (`docs/target-architecture.md:150-162`) from a convention into a gate, and makes the multi-language obligation explicit, per-language, and enforceable without new vocabulary.

**Classification:** items 2, 3(declaration half) and 4(scope half) are **data**; the graph-level required-set feed, the java/go/cpp projector targets, and the python/csharp OS/vault resolvers are **SDA change requests** (do not edit SDA from this repo); the estate overlay completing per-target `overlayBindings`/`providers` is **data** under `sql/migrations/`.
