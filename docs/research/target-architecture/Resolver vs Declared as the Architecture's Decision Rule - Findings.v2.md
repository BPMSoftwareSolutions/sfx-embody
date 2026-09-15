I have gathered comprehensive evidence. Here is the structured report.

---

# SDA Language Resolver Model — Research Report

Repository investigated: `C:\lab\repos\scenario-driven-architecture` (HEAD as checked out; working tree has 3 modified files, none in `languages/`). All paths below are absolute under that root.

---

## (a) The resolver definition

### 1. What "resolving language" means

There is **no type, class, or registry identifier named `LanguageResolver`, `LanguageResolverRegistry`, `ResolverRegistry`, or `language_resolver` anywhere in the repository** (grep: no matches). The term is a *policy* term, not a runtime type.

Two distinct meanings of "resolve" exist and must not be conflated:

**(i) Kernel "resolution" = an execution-vector step kind.** The canonical vector declares five steps; two are `kind: "unprotected"`:
- `resolve-event-authority` — `kernel/contracts/execution/scenario-kernel-execution-vector.json:16-22`
- `resolve-disposition` — `kernel/contracts/execution/scenario-kernel-execution-vector.json:39-45`

These resolve a declared event into a concrete execution authority, and an admitted outcome into a disposition. They are kernel-law steps, not "language" selection.

**(ii) "Language resolver" = ADR-0013's term for the only hand-authored executable surface.** Definition verbatim, `docs/decisions/0013-hand-authored-surface-is-language-resolvers-only.md:33-40`:

> "A language resolver is the admitted hand-authored executable body that embodies the forbidden executable mechanics natively and resolves them from semantic data: authority, contracts, transformations, projection and execution authority, target profiles, and lineage. It is the sole surface allowed to contain branching, iteration, exception policy, throwing, object construction, serialization, normalization, validation, fallback, retry, and state mutation as its own execution body."

Declared-surface rule, same file `:48-53`: the declared surface is *"the language kernel, its platform mechanic providers, and the native mechanic-provider bodies admitted as that resolver. Projection, CLI, compatibility, document-generation, and capability-scenario tooling are not resolver bodies and must be projected."*

This is raised to a hard governance rule **K029**, `governance/workspace/governance-rules.json:235-241` (description `:238`): every executable file must either (a) reside inside a declared language-resolver boundary — *"the projectReferences.kernel path of an admitted language-binding manifest plus its admitted native mechanic-provider bodies"* — or (b) score zero on all twelve forbidden mechanics and carry projection provenance. Violation = `NON_RESOLVER_HAND_AUTHORED_MECHANIC`.

### 2. Where the running language/target is determined

There is **no closed enum for languages**; admission is by registration. The load-bearing identifiers and data:

- **`LanguageBinding.language`** — the declared language identity in each binding manifest. Schema: `kernel/schemas/language-binding.schema.json:24-28`; the description explicitly says: *"Open target identity. Admission is resolved through language-target-registration.v1 rather than a closed schema enum."*
- **`language-target-registration.v1`** — one registration file per language at `languages/<dir>/projection/language-target-registration.json`, schema `kernel/schemas/language-target-registration.schema.json` (description `:5`: *"Admits one discoverable language projection target … without extending a central language enum"*). Required fields incl. `status` (line 25: `DECLARED|IMPLEMENTING`) and `providers` (`:64-75`).
- **`NodeLanguageTargetRegistry`** — the actual discovery/resolution registry in TypeScript: `tools/src/adapters/projection/node-language-target-registry.ts`. It scans `languages/*/projection/language-target-registration.json` (`:12`, `:51-66`), exposes `discover()`, `targets()`, `registration(target)` (`:68-80`), and `verifiedProvider` digest parity (`:98-108`). Missing target → `"No admitted language target registration exists for '<target>'."` (`:78`).
- **`ProjectionTarget`** — `tools/src/projection/model/projection-profile.ts:1-2`: `/** Open identity admitted by language-target-registration.v1. */ export type ProjectionTarget = string;`
- **`languageEcosystemId` / `languageEcosystemRoot`** — maps target id to filesystem ecosystem: `tools/src/adapters/workspace/language-ecosystem-root.ts:3-13`, with `IMPLEMENTATION_ECOSYSTEMS = { node: "typescript" }`.
- **`LANGUAGE_ECOSYSTEMS`** — the *closed* workspace set of 8 programming-language roots: `tools/src/governance/language-ecosystem-layout.ts:4-13` = `cpp, csharp, go, java, kotlin, python, swift, typescript`. `OWNED_IMPLEMENTATION_ROOTS` (`:15-23`) maps runtime/framework targets to owners (node→typescript, javafx→java, swiftui→swift, android-compose→kotlin).
- **Per-language mechanic registry authority** — declared data naming every resolver body per language: `kernel/semantic-authority/consumer/<language>-mechanic-registry.authority.v1.json` (6 files: node, python, csharp, java, go, cpp). Each has a `language` field and a `digestAlgorithm` (`"sha256 of canonical recursive-key-order JSON excluding authorityDigest"`).
- **`sda-language-mechanic-profile-resolution.v1`** — the computed per-language resolution shape; its `language` enum is `["csharp","node","python","java","go"]` (`kernel/schemas/sda-language-mechanic-profile-resolution.schema.json:19`), with `bindingStatus` `DECLARED|IMPLEMENTING` and `kernelAdmission` `ADMITTED|NOT_ADMITTED|NOT_APPLICABLE` (`:20-21`). Built by `MechanicConformanceObserver` at `tools/src/consumer-projection/proof/mechanic-conformance-observer.ts:8-44`.

So: **language selection is resolved by directory discovery of `language-target-registration.json` and binding manifests; the running language is the `targetId`/`language` carried by those declared files, mapped to an ecosystem directory by `IMPLEMENTATION_ECOSYSTEMS`.**

---

## (b) Languages × resolver components (paths + status)

**Status note.** Binding `status` is declared *intent only* and is capped at `DECLARED|IMPLEMENTING` (`kernel/schemas/language-binding.schema.json:37-41`). The schema explicitly says `ADMITTED`/`CONFORMING` are **computed** facts found in `artifacts/conformance/<language>.conformance-result.json`'s `admissionDisposition`. That directory is **gitignored** (`.gitignore:64` = `artifacts/conformance/`; confirmed via `git check-ignore`), and I found **no `scenario-kernel-*.conformance-result.json` in the checkout** (glob: "No files found"). Therefore every IMPLEMENTING language computes as `NOT_ADMITTED` in a fresh checkout until the gate runs. The only in-repo `ADMITTED` witness is the graph conformance target table below.

### Binding / registration files

| Language (dir) | targetId | Binding manifest | Status | Target registration | Mechanic registry authority |
|---|---|---|---|---|---|
| typescript | `node` | `languages/typescript/binding/scenario-kernel-node.binding.json` | IMPLEMENTING (line 7) | `languages/typescript/projection/language-target-registration.json` (targetId `node`, line 3) | `kernel/semantic-authority/consumer/node-mechanic-registry.authority.v1.json` |
| python | `python` | `languages/python/binding/scenario-kernel-python.binding.json` | IMPLEMENTING | `languages/python/projection/language-target-registration.json` | `.../python-mechanic-registry.authority.v1.json` |
| csharp | `csharp` | `languages/csharp/binding/scenario-kernel-csharp.binding.json` | IMPLEMENTING | `languages/csharp/projection/language-target-registration.json` | `.../csharp-mechanic-registry.authority.v1.json` |
| java | `java` | `languages/java/binding/scenario-kernel-java.binding.json` | IMPLEMENTING | `languages/java/projection/language-target-registration.json` | `.../java-mechanic-registry.authority.v1.json` |
| go | `go` | `languages/go/binding/scenario-kernel-go.binding.json` | IMPLEMENTING | `languages/go/projection/language-target-registration.json` | `.../go-mechanic-registry.authority.v1.json` |
| cpp | `cpp` | `languages/cpp/binding/scenario-kernel-cpp.binding.json` | IMPLEMENTING (line 7) | `languages/cpp/projection/language-target-registration.json` | `.../cpp-mechanic-registry.authority.v1.json` |
| swift | — | **not found** | — | **not found** | **not found** |
| kotlin | — | **not found** | — | **not found** | **not found** |

No binding manifest declares a resolver boundary (grep for `resolver|resolverBoundary|handAuthored` in `languages/**/*.binding.json`: no matches). The inventory doc records this as an open gap (`docs/languages-resolver-boundary-and-projection-inventory.md:387`, `:397`).

### Resolver component files per language

| Component | node (typescript) | python | csharp | java | go | cpp |
|---|---|---|---|---|---|---|
| Kernel state machine | `languages/typescript/src/kernel/scenario-kernel.ts` | `languages/python/src/scenario_kernel/kernel/scenario_kernel.py` | `languages/csharp/src/ScenarioKernel/ScenarioKernel.cs` | `languages/java/src/main/java/scenario/kernel/kernel/ScenarioKernel.java` | `languages/go/kernel/scenario_kernel.go` | **generated**: `languages/cpp/generated/execution/scenario_kernel_execution.generated.cpp` (hand-authored kernel not found) |
| Disposition resolver | `src/kernel/disposition-resolver.ts` | `kernel/disposition_resolver.py` | `src/ScenarioKernel/DispositionResolver.cs` | `kernel/DispositionResolver.java` (+ duplicate `execution/DispositionResolver.java`) | `kernel/disposition_resolver.go` (`CanonicalDispositionResolver`) | generated in same `.generated.cpp` (`CanonicalDispositionResolver`) |
| Execution ports | `languages/typescript/src/execution/execution-authority-resolver.ts`, `execution-observer.ts` | `execution/execution_authority_resolver.py`, `execution_observer.py` | `src/ScenarioKernel.Execution/*.cs` (`IContractValidator`, `IDispositionResolver`, `IExecutionAuthorityResolver`, `IExecutionObserver`, `ISemanticExecutor`) | `execution/*.java` (`ContractValidator`, `ExecutionAuthorityResolver`, `ExecutionObserver`, `SemanticExecutor`, `DispositionResolver`) | `execution/ports.go` | generated execution ports |
| Transformation evaluator | `runtimes/node/semantic-transformation-evaluator.mjs` | `src/scenario_kernel/adapters/semantic_transformation_evaluator.py` | `src/ScenarioKernel.Adapters/Consumer/SemanticTransformationEngine.cs` | `src/main/java/scenario/kernel/adapters/SemanticTransformationEngine.java` | `platform/platform.go` (`SemanticTransformationEngine`) / `platform/transformation.go` | `languages/cpp/graph/transformation_evaluator.cpp` |
| Graph scheduler | `runtimes/node/semantic-execution-graph/scheduler.js` (`GraphTokenScheduler`) | `src/scenario_kernel/platform/execution_graph.py` (`SemanticExecutionGraphScheduler`) | `src/ScenarioKernel.Adapters/Graph/SemanticExecutionGraphScheduler.cs` | `src/main/java/scenario/kernel/platform/SemanticExecutionGraphScheduler.java` | `platform/execution_graph.go` | `languages/cpp/graph/execution_graph_scheduler.cpp` |
| Execution-pattern resolvers | `runtimes/node/execution-pattern-resolvers.mjs` (10 exports) | `platform/execution_pattern_resolvers.py` (10 exports) | `Graph/ExecutionPatternResolvers.cs` (10 exports) | **not found** | **not found** | **not found** |
| Graph mechanic provider | `semantic-execution-graph-mechanic-provider.mjs` | `adapters/semantic_execution_graph_mechanic_provider.py` | `Graph/SemanticExecutionGraphMechanicProvider.cs` | `platform/SemanticExecutionGraphMechanicProvider.java` | `platform/graph_mechanic_provider.go` | `graph/execution_graph_mechanic_provider.cpp` |
| Declared-read provider | `semantic-execution-graph-declared-read-provider.mjs` | `adapters/semantic_execution_graph_declared_read_provider.py` | `Graph/SemanticExecutionGraphDeclaredReadProvider.cs` | `platform/SemanticExecutionGraphDeclaredReadProvider.java` | `platform/graph_declared_read_provider.go` | `graph/execution_graph_declared_read_provider.cpp` |
| Effect provider | `semantic-execution-graph-effect-provider.mjs` | `adapters/semantic_execution_graph_effect_provider.py` | `Graph/SemanticExecutionGraphEffectProvider.cs` | `platform/SemanticExecutionGraphEffectProvider.java` | `platform/graph_effect_provider.go` | `graph/execution_graph_effect_provider.cpp` |
| Compilation / execution / overlay providers | `semantic-execution-graph-{compilation,execution,overlay}-provider.mjs` | `adapters/semantic_execution_graph_{compilation,execution,overlay}_provider.py` | `Graph/SemanticExecutionGraph{Compilation,Execution,Overlay}Provider.cs` | `platform/SemanticExecutionGraph{Compilation,Execution,Overlay}Provider.java` | `platform/graph_{compilation,execution,overlay}_provider.go` | `graph/execution_graph_{compilation,execution,overlay}_provider.cpp` |
| Native primitives | `runtimes/node/native-mechanic-primitives.mjs` (`valueAt`,`bindValueAt`,`canonicalizeValue`,`canonicalDigest`,`createGovernedEffectContext`) | `core.py` + evaluator | — (engine) | — (validator) | — | `graph/ordered_json.cpp`, `platform/sha256.cpp` |
| Registry loader | `runtimes/node/node-mechanic-registry-loader.mjs` | **not found** (host hard-coded) | **not found** | **not found** | **not found** | **not found** |
| Consumer platform entrypoint | `runtimes/node/admitted-consumer-platform.mjs`, `admitted-graph-platform.mjs` | `platform/consumer.py` | `Adapters/Consumer/AdmittedConsumerPlatform.cs` (+ `ScenarioKernel.Platform.csproj`) | `platform/AdmittedConsumerPlatform.java` | `platform/platform.go` | `platform/consumer_platform.cpp` |
| Schema / contract admission | `runtimes/node/schema-contract-admission-provider.mjs` | `platform/consumer.py` (`_plan_contract_admission`), `adapters/core.py` | `Adapters/Schema/JsonSchemaContractValidator.cs`, `KernelSchemaRegistry.cs`, `SemanticContractCatalogAdmission.cs` | `platform/SemanticExecutionGraphConsumerHost.java` (`createSynchronousSchemaAdmission`) | `platform/graph_consumer_host.go` (`CreateSynchronousSchemaAdmission`) | `graph/contract_catalog_admission.cpp` |
| Effect ports (registry rows) | external-observation, http, credential, LLM, etc. (many) | filesystem-artifact-store only | **none** (contractAdmissions/event ports omit them) | credential + http via ConsumerHost | credential + http via ConsumerHost | credential + http via governed_effect_ports.cpp |
| Conformance suite | `languages/typescript/test/conformance/*` | `languages/python/tests/conformance/*` | `languages/csharp/tests/ScenarioKernel.ConformanceTests/*` | `src/test/java/scenario/kernel/conformance/ConformanceSuite.java` | `languages/go/conformance/*` | `languages/cpp/conformance/*` |
| Cross-language vector host | mjs evaluator directly | `conformance/execution-graph/python-mechanic-evaluator-bridge.mjs` | `conformance/execution-graph/csharp-mechanic-evaluator-bridge.mjs` + `languages/csharp/conformance/mechanic-vector-host/` | `java-mechanic-evaluator-bridge.mjs` + `conformance/mechanic-vector-host/MechanicVectorHost.java` | `go-mechanic-evaluator-bridge.mjs` + `conformance/mechanic-vector-host/main.go` | `cpp-mechanic-evaluator-bridge.mjs` + `conformance/mechanic_vector_host.cpp` |

**Graph-target ADMITTED table** (in-repo, tracked): `conformance/execution-graph/language-graph-v1-conformance.json:6-43` lists `node, csharp, python, java, go, cpp` each with `"status": "ADMITTED"` and a `schedulerRef`/`testRef`. Note C++'s `schedulerRef` is `languages/cpp/graph/execution_graph_scheduler.cpp` — a hand-authored file — even though its `ScenarioKernel`/`DispositionResolver` are generated.

**Registry-level asymmetries found:**
- `executionPatterns` (per-patternType resolver registration) is present in `node` (466-line registry, `:105-176`), `python` (`:77-148`), `csharp` (`:69-140`) but **absent** from `java`, `go`, and `cpp` registries. Java has no `ExecutionPatternResolvers` file at all (glob `*Pattern*.java`: none).
- `providerModuleRoot` / registries are declared, but **only Node has a registry loader**; the cross-target handoff records: *"Python and C# have no mechanic-registry loader at all … their registry authorities are not currently consumed by the runtime"* (`docs/handoff/semantic-execution-graph-cross-target-host-gaps.md:130-138`).
- `sda-language-mechanic-profile-resolution` enum omits `cpp` (`kernel/schemas/sda-language-mechanic-profile-resolution.schema.json:19`), while `language-graph-v1-conformance.json` includes it.

**Inventory-document discrepancy (flagged, not speculation):** `docs/languages-resolver-boundary-and-projection-inventory.md:214` says C++ has *"(no kernel yet) — a minimal C++ ScenarioKernel + DispositionResolver embodiment is owed."* That statement matches the conformance record (C++ kernel path is generated) but **not** the presence of hand-authored `languages/cpp/graph/*.cpp` resolver bodies, the C++ `language-target-registration.json`, the C++ mechanic registry, and the C++ `ADMITTED` graph target. The doc's Section 5.6 is stale relative to the working tree.

---

## (c) Neutral vs per-language boundary

### Language-neutral (data/authority, one copy)
- **Kernel schemas** — `kernel/schemas/*.schema.json` (~85 files), JSON Schema 2020-12. `kernel/README.md:35` ("All schema definitions are language-neutral JSON Schema 2020-12"), invariants `:37-42` ("No runtime-language source code lives in kernel/", "All language bindings must implement identical scenario semantics").
- **Kernel specification** — `kernel/specification/scenario-kernel.specification.json` (objects list `:4-13`, `executionLaws` `:14-19`); one admitted instance.
- **Execution vector** — `kernel/contracts/execution/scenario-kernel-execution-vector.json` (5 steps, `:7-46`).
- **Semantic mechanic authority** — `kernel/semantic-authority/consumer/semantic-value-mechanics.authority.v1.json` (1,092 lines; `lifecycle: ADMITTED`; each mechanic carries `meaning`, `inputContractId`, `outcomeContractId`, `effectClassification`, and `conformanceRefs` → `conformance/execution-graph/mechanics/*.v1`); `platform-effect-mechanics.authority.v1.json` (317 lines; `nativeFloor: true`).
- **Mandatory mechanic parity profile** — `kernel/semantic-authority/consumer/sda-platform-mechanic-parity.semantic-authority.json` (13 `requiredMechanics`, `:5-19`, `appliesToBindingStatuses: ["IMPLEMENTING"]`).
- **Provider/mechanic catalog** — `kernel/semantic-authority/consumer/sda-platform-capabilities.semantic-authority.json`.
- **Shared conformance corpus** — `conformance/corpus/execution/*.json` + `conformance/expectations/execution/*.expected.json` (given and then authored as separate documents, `conformance/corpus/execution/README.md:1-3`); `conformance/execution-graph/mechanics/*.v1` (one vector file per mechanic, `mechanics/README.md:1-8`: *"A vector file is the authority for its mechanic… No target's runtime is the specification, including the Node one."*); `conformance/execution-patterns/vectors.v1.json`.
- **Conformance target table** — `conformance/execution-graph/language-graph-v1-conformance.json`.
- **Execution-pattern catalog schema** — `kernel/schemas/execution-pattern.v1.schema.json` (`registration` def `:101-112`).

### Must be re-implemented per language (resolver bodies / projections)
- **Kernel state machine + disposition resolution** — one per language (table in (b)). Note the *ports* are language-neutral interfaces but their concrete adapters are per-language.
- **Transformation evaluator** — pure mechanics are declared once (`semantic-value-mechanics.authority.v1.json`) but each language must provide the lowering; the inventory classifies the Java/Python/C# AST interpreters as `COMPILER-EMITTED` end-state (`docs/...inventory.md:241`, `:261`, `:269`, `:286`).
- **Graph scheduler, pattern resolvers, graph mechanic/declared-read/effect providers, effect ports, schema admission** — declared once in the neutral registries/catalog, implemented per language.
- **Projection providers** — `language-target-registration.json` binds `structuralRenderer`, `executionRenderer`, `shapeObserver` to `tools/src/projection/providers/<lang>/*.ts` with `implementationDigest` (e.g. node targets lines 17-34). C++ uniquely uses `transport: "process-json-v1"` pointing at `tools/providers/target-projection-provider.mjs` (`languages/cpp/projection/language-target-registration.json:19-49`).
- **UI presentation runtimes** — per-framework, classified `PROJECT-UI`/`SLIM` (`docs/...inventory.md:308-324`).

Concrete neutral/per-language example: `sda-consumer-mandatory-mechanics.v1` lists `schema-admission` once (parity file `:8`); Node satisfies it via `schema-contract-admission-provider.mjs` (`node-mechanic-registry...:184-190`), Java via `SemanticExecutionGraphConsumerHost.createSynchronousSchemaAdmission` (`java-mechanic-registry...:72-78`), Go via `graph_consumer_host.go`, C++ via `contract_catalog_admission.cpp`.

---

## (d) Minimal per-language boot surface to execute a declared execution graph

The minimal surface is the set of **scheduler providers + provider profiles + registry rows** the declared registries bind. From the six `*-mechanic-registry.authority.v1.json` files:

1. **Scheduler** — one required:
   - node `semantic-execution-graph/scheduler.js` (`GraphTokenScheduler`; registry `:24`)
   - python `platform/execution_graph.py` (`SemanticExecutionGraphScheduler`; `:22`)
   - csharp `Graph/SemanticExecutionGraphScheduler.cs` (`:21`)
   - java `platform/SemanticExecutionGraphScheduler.java` (`:21`)
   - go `platform/execution_graph.go` (`NewSemanticExecutionGraphScheduler`; `:22`)
   - cpp `graph/execution_graph_scheduler.cpp` (`:21`)
2. **Mechanic provider factory** (`sda-semantic-value-graph-provider.v1`) — `createMechanicProvider` / `CreateMechanicProvider` / `create_mechanic_provider`.
3. **Declared-read provider factory** (`sda-declared-read-graph-provider.v1`).
4. **Platform-effect provider factory** (`sda-platform-effect-graph-provider.v1`).
5. **Transformation evaluator** (pure semantic values) — required for capability meaning.
6. **Execution-pattern resolvers** (`executeSequence`/`executeSelection`/… 10 patternTypes) — present/registered for node, python, csharp; **absent for java, go, cpp**.
7. **Contract/schema admission** — `sda-schema-contract-admission.v1` row (node direct; java/go/cpp direct; csharp/go missing → see G7).
8. **Effect ports** — at minimum `sda-external-credential-reference-binding-port.v1` and `sda-governed-http-exchange-port.v1` for effectful graphs; declared for node, java, go, cpp; **missing for python and csharp** (handoff `:130-138`).
9. **Filesystem artifact-store** — `sda-filesystem-artifact-store.v1` (node/python/csharp/java/go/cpp all declare it).
10. **Native runtime/platform primitives** — digest/canonicalization (`native-mechanic-primitives.mjs`, `core.py`, `ordered_json.cpp`, `platform/sha256.cpp`).
11. **Kernel state machine + disposition resolver** (for linear v1/v2 execution) — hand-authored for node/python/csharp/java/go; **generated for cpp**.
12. **Registry loader** — only Node (`node-mechanic-registry-loader.mjs`).

The composition contract: `conformance/execution-graph/language-graph-v1-conformance.json` requires only the **scheduler** as the per-target boot artifact; the rest are reached through the mechanic registry / `graphProviderProfiles` / `schedulerProviders` rows.

---

## (e) Conformance & admission mechanism

### 1. Shared conformance corpus (digest parity)
- `conformance/execution-graph/mechanics/*.v1` — 32 vector files (e.g. `if.v1`, `map.v1`, `sha256.v1`). A target conforms when every vector reproduces its outcome exactly; a `notAdmitted` outcome must be refused (thrown or neutral code), `conformance/execution-graph/mechanics/README.md:23-25`.
- `conformance/execution-graph/run-mechanic-conformance.mjs:1-73` — one Node runner judges every target; invoked as `node run-mechanic-conformance.mjs <evaluator> [export]` (`:4-8`).
- Per-target bridges: `cpp-`, `csharp-`, `go-`, `java-`, `python-mechanic-evaluator-bridge.mjs`; documented table `mechanics/README.md:55-61`. `language-graph-v1-conformance.json:4-5` pins `canonicalGraphDigest` and `expectedObservedPathDigest`.
- Digest parity for providers is enforced in `NodeLanguageTargetRegistry.verifiedProvider` (`tools/src/adapters/projection/node-language-target-registry.ts:98-108`) — declared vs observed SHA-256, mismatch throws.
- Consumer input digest for parity freshness: `tools/src/adapters/consumer-projection/consumer-platform-input-digest.ts:20-55` (walks neutral authority + per-target capability files, plus the catalog, into one SHA-256).

### 2. Behavioral / execution-closure observation
`tools/src/adapters/conformance/language-toolchains.cts` (`NodeLanguageToolchains`):
- `observeBehavior` (`:77-84`) discovers the binding's `projectReferences.conformanceTests`, and prefers a registered `argv.v1` toolchain profile (only C++ has one — `target-toolchain-profile.json` driver `argv.v1`; all others `legacy-built-in`), else runs native suites: `dotnet test`, `node --test`, `go test ./...`, `javac`+`java … ConformanceSuite`, `pytest`.
- `observeExecutionClosure` (`:85-93`) runs the five shared execution-vector fixtures; explicit `NOT_OBSERVABLE` when a toolchain is absent. Python/C#/Java/Go use `toolchainResult`; Node uses `observeNodeClosure` (`:95-101`).
- `registeredArgvProfile` (`:34-43`) + `nativeRuntimeHostCompatible` (`:45-54`) gate on `conformance/native-runtime-boundary.json` (only `languages/cpp/conformance/native-runtime-boundary.json` exists; schema `kernel/schemas/native-runtime-boundary.schema.json`, requiring `foreignRuntimeDependencies: []` and `foreignSemanticDelegations: []`).

### 3. Admission mechanism
- Capability `kernel-implementation-admission` (`capabilities/sda-tooling/kernel-implementation-admission/capability.json`) with 11 obligations defined in `capabilities/sda-tooling/kernel-implementation-admission/contracts/implementation-admission-evidence.schema.json:7-17` (`admissionDisposition` enum `ADMITTED|BLOCKED` at `:12`; exactly 11 `obligations` at `:14`).
- Decision logic: `tools/src/capabilities/kernel-implementation-admission/decide-implementation-admission/provider.ts:4-19` — groups `WORKSPACE GOVERNANCE`, `CANONICAL AUTHORITY`, `LANGUAGE DECLARATION`, `IMPLEMENTATION PROOF`; `ADMITTED` only when no `FAIL` and no `NOT_READY` (`:19`). Behavioral/closure gaps become `NOT_READY` (`:14-15`).
- Publication: `conformance-evidence-publication` capability publishes `scenario-kernel-admission-result.v1` (`capabilities/sda-tooling/conformance-evidence-publication/contracts/published-implementation-evidence.schema.json:9-17`) and cross-language equivalence (`contracts/cross-language-equivalence-evidence.schema.json`; provider `tools/src/capabilities/conformance-evidence-publication/derive-cross-language-equivalence/provider.ts:18-37`).
- **Computed admission read:** `tools/src/adapters/consumer-projection/node-consumer-assurance-repository.ts:53-62` reads `artifacts/conformance/scenario-kernel-<language>.conformance-result.json`; `DECLARED → NOT_APPLICABLE`, missing file → `NOT_ADMITTED`, else `ADMITTED` only when `admissionDisposition === "ADMITTED"` **and** `admissionArtifactIsCurrent` (digest freshness).
- Parity composition: `tools/src/consumer-projection/proof/mechanic-conformance-observer.ts:8-44` builds `sda-language-mechanic-profile-resolution.v1`; missing mechanics → `INCOMPLETE`; `NOT_OBSERVABLE` preserved.

### 4. How a new language is admitted — and what it must implement
1. Create `languages/<ecosystem>/`; governance `LANGUAGE_ECOSYSTEMS` is closed (8 entries) and `inspectLanguageEcosystemLayout` fails on unadmitted roots (`tools/src/governance/language-ecosystem-layout.ts:38-77`).
2. Author a binding manifest `languages/<dir>/binding/scenario-kernel-<x>.binding.json` (schema `kernel/schemas/language-binding.schema.json`).
3. Author `languages/<dir>/projection/language-target-registration.json` (targetId, status, bindingRef/projectionProfileRef/toolchainProfileRef, `admittedStructuralSource`, `promotion`, three required providers with digests) and `target-toolchain-profile.json`.
4. Author `languages/<dir>/conformance/<implementationId>.conformance.json` (`scenario-kernel-implementation-conformance.v1`) mapping every semantic object and execution step to source (`languages/*/conformance/scenario-kernel-*.conformance.json`).
5. Implement the minimal boot surface (section d) and the 13 `sda-consumer-mandatory-mechanics.v1` mechanics to `ADMITTED` language-native providers (K019, `governance-rules.json:165-171`).
6. Declare a per-language mechanic-registry authority (`kernel/semantic-authority/consumer/<x>-mechanic-registry.authority.v1.json`) with digest-pinned provider modules (node registry `:1-31`, `:105-176`).
7. Pass the shared vectors/execution corpus; the gate writes `artifacts/conformance/scenario-kernel-<x>.conformance-result.json` with `admissionDisposition`.
8. Admission is then computed (never hand-set) via the 11 obligations; the language appears in `sda-language-mechanic-profile-resolution.v1` and the parity matrix.

**Discovery naming caveat (concrete finding):** directory id ≠ target id for TypeScript. `NodeLanguageBindingRepository.load()` correctly uses the binding's declared `language` (`tools/src/adapters/workspace/node-language-binding-repository.ts:70-74`), but `NodeConsumerAssuranceRepository.bindings()` constructs the path from the directory name — `languages/<entry>/binding/scenario-kernel-<entry>.binding.json` (`tools/src/adapters/consumer-projection/node-consumer-assurance-repository.ts:45-51`) — so `languages/typescript` looks for `scenario-kernel-typescript.binding.json` and **silently omits the `node` binding** from consumer-platform parity. The same naming assumption appears in the test `tools/tests/language-declaration-admission-capability.test.js:36` (`scenario-kernel-${entry.name}.binding.json`), which therefore skips `typescript`. Only `languageEcosystemId` (`language-ecosystem-root.ts:7-8`) knows `node → typescript`.

Additional recorded gap: *"There is no shared cross-language admission conformance corpus yet"* for JSON-Schema vocabulary (`docs/handoff/semantic-execution-graph-cross-target-host-gaps.md:199-201`).

---

## (f) Exact citations (key)

**Definition / policy**
- Language resolver definition: `docs/decisions/0013-hand-authored-surface-is-language-resolvers-only.md:33-40`
- Declared surface rule: same `:48-53`
- Everything else projected: same `:42-46`; fractal closure `:55-61`; monotonic shrinkage `:63-69`
- K029: `governance/workspace/governance-rules.json:235-241`; K016 `:144-150`; K017 `:151-157`; K018 `:158-164`; K019 `:165-171`; K020 `:172-178`; K021 `:179-185`; K022 `:186-192`
- ADR-0008 (ecosystem ownership): `docs/decisions/0008-language-ecosystems-own-runtime-and-presentation-providers.md:12-27`
- ADR-0014 (single bootstrap compiler, closed): `docs/decisions/0014-admit-one-versioned-execution-graph-bootstrap-compiler.md:31-61`, closure `:89-112`
- Consumer invariants (allowed origins, 13 mandatory mechanics): `docs/consumer-platform-invariants.md:13-22`, `:95-107`

**Language identity / registry**
- `kernel/schemas/language-binding.schema.json:24-28` (open identity), `:37-41` (status intent vs computed admission)
- `kernel/schemas/language-target-registration.schema.json:5`, `:25`, `:64-102`
- `kernel/schemas/sda-language-mechanic-profile-resolution.schema.json:9-21` (language enum at `:19`)
- `tools/src/adapters/projection/node-language-target-registry.ts:12`, `:29-46`, `:51-80`, `:98-108`
- `tools/src/adapters/workspace/language-ecosystem-root.ts:3-13`
- `tools/src/adapters/workspace/node-language-binding-repository.ts:42-83`
- `tools/src/governance/language-ecosystem-layout.ts:4-23`, `:38-77`
- `tools/src/projection/model/projection-profile.ts:1-2`
- `tools/src/projection/model/language-target-registration.ts:16-37`

**Kernel steps**
- `kernel/contracts/execution/scenario-kernel-execution-vector.json:7-46`
- `kernel/specification/scenario-kernel.specification.json:4-19`
- `kernel/README.md:35-42`

**Per-language registries**
- node: `kernel/semantic-authority/consumer/node-mechanic-registry.authority.v1.json:1-31`, `:105-176`, `:177-432`
- python: `.../python-mechanic-registry.authority.v1.json:1-26`, `:77-148`
- csharp: `.../csharp-mechanic-registry.authority.v1.json:1-26`, `:69-140`
- java: `.../java-mechanic-registry.authority.v1.json:1-26`, `:65-123`
- go: `.../go-mechanic-registry.authority.v1.json:1-26`, `:69-127`
- cpp: `.../cpp-mechanic-registry.authority.v1.json:1-26`, `:65-123`
- parity profile: `kernel/semantic-authority/consumer/sda-platform-mechanic-parity.semantic-authority.json:3-19`
- pure mechanics: `kernel/semantic-authority/consumer/semantic-value-mechanics.authority.v1.json:1-39`; effect mechanics: `.../platform-effect-mechanics.authority.v1.json:1-24`

**Conformance / admission**
- `conformance/execution-graph/language-graph-v1-conformance.json:1-44`
- `conformance/execution-graph/run-mechanic-conformance.mjs:1-73`
- `conformance/execution-graph/mechanics/README.md:1-74`
- `conformance/corpus/execution/README.md:1-21`
- `conformance/execution-graph/cpp-mechanic-evaluator-bridge.mjs:1-62`; `csharp-...bridge.mjs:1-31`
- `capabilities/sda-tooling/kernel-implementation-admission/contracts/implementation-admission-evidence.schema.json:7-17`
- `tools/src/capabilities/kernel-implementation-admission/decide-implementation-admission/provider.ts:4-19`
- `capabilities/sda-tooling/conformance-evidence-publication/capability.json:8-30`; `provider-bindings.json:3-7`; `contracts/published-implementation-evidence.schema.json:7-20`; `contracts/cross-language-equivalence-evidence.schema.json:7-12`
- `tools/src/capabilities/conformance-evidence-publication/derive-cross-language-equivalence/provider.ts:18-37`
- `tools/src/adapters/conformance/language-toolchains.cts:34-54`, `:75-105`
- `tools/src/adapters/consumer-projection/node-consumer-assurance-repository.ts:45-62`
- `tools/src/adapters/consumer-projection/consumer-platform-input-digest.ts:20-55`
- `tools/src/consumer-projection/proof/mechanic-conformance-observer.ts:8-44`
- `tools/src/interfaces/conformance/run-reference-gate.ts:5-17`
- Root gate scripts: `package.json` → `test:kernel`, `test:language-resolution`, `test:admission`, `test:all`
- Compute-time artifacts are gitignored: `.gitignore:64` ⇒ `artifacts/conformance/`; no `scenario-kernel-*.conformance-result.json` committed

**Docs describing the model**
- `docs/languages-resolver-boundary-and-projection-inventory.md` (full inventory): governing law `:57-71`; resolver inventory `:139-218`; projection inventory `:222-324`; gates `:384-391`; open actions `:395-416`
- `docs/handoff/semantic-execution-graph-cross-target-host-gaps.md` (runtime seam, G1–G8): `:42-90`, `:130-138`, `:153-201`, `:229-246`
- `docs/handoff/semantic-execution-graph-compilation-python-csharp.md:90-117` ("language registry / provider row"; cpp/go/java/kotlin/swift held)
- `docs/decisions/README.md:19` (ADR-0013 index row)

**"Not found" (explicit):**
- No `LanguageResolver`, `LanguageResolverRegistry`, `ResolverRegistry`, or `language_resolver` identifier anywhere.
- No resolver-boundary declaration field in any `languages/**/*.binding.json`.
- No committed `artifacts/conformance/scenario-kernel-*.conformance-result.json`.
- No binding, `language-target-registration.json`, or mechanic registry for `swift` or `kotlin` (presentation-only surfaces).
- No Java execution-pattern resolver file; no `executionPatterns` rows for java/go/cpp.
- No mechanic-registry loader for python/csharp/java/go/cpp (only Node).
- No `native-runtime-boundary.json` for any language except C++.
- No hand-authored C++ `ScenarioKernel`/`DispositionResolver` (C++ kernel path in its conformance record is generated).

---

# sfx-embody bootstrap / declaration-surface classification

Read-only research. No files modified.

## 0. Scope confirmed

- `src/`: exactly **11 files** (verified count).
- `config/`: **10 files** (7 top-level + 3 under `selections/`).
- `sfx.config.json` at repo root.
- CLI repo at `C:\lab\repos\sidefx-cli` has `src/*.mjs` (9 files) and its own `sfx.commands.json`.
- Test suite: **7 files** in `tests/`.

---

## (a) Every `src/` file — role and classification

Classification key: **(a) = language-neutral logic** (identical in any language); **(b) = Node-specific/host code** (must be re-authored per language); **(c) = data-reading/boot glue**. "Transistor" mapping to your 0/1 model is noted.

| File (absolute) | Role | Classification | Transistor note / exact anchors |
|---|---|---|---|
| `C:\lab\repos\sfx-embody\src\database-delivery.mjs` (65 lines) | Frontdoor process entry: reads stdin envelope, validates, loads runtime config, imports the DB driver, injects `readQuery`/`readAuthority`, restricts the process, runs the pinned read session + loader, writes stdout. | **(b) Node-specific host + (c) boot glue** | Type-0 boot. `process.stdin` (11–18), `process.argv[2]` (20), `pathToFileURL(...).href` + dynamic `import()` (27–35), `process.env` (30), `process.stderr.write('SFX_OBSERVATION ...')` (42), `process.stdout.write` (59), `process.exitCode` (64). Neutral content: envelope parse/validate (18–19), config shape check (22–24), session wrapper (46–53), envelope assembly (59). |
| `C:\lab\repos\sfx-embody\src\invoke-database-capability.mjs` (367 lines) | Loader / declaration interpreter: command validation, operation table, reads declarations, builds CLI input, executes the declared capability through the kernel, shapes the result envelope. | **(a) language-neutral logic** with two Node seams | Mostly type-1: `operations` dispatch table (156–169), `validateDatabaseCommand` (175–202), `executeDatabaseCommand` (204–367), reader routing (263–306), input mapping (144–151, 318–326), result shaping (358–366). Node seams: `node:crypto` `createHash`/`randomUUID` (1), `node:url` (2), and the **residual per-language resolver seam** importing the node SDA evaluator `languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs` (121–122). |
| `C:\lab\repos\sfx-embody\src\read-authority.mjs` (168 lines) | Loader declaration read: SQL statements + query orchestration + coherence checks; optional standalone CLI extraction. | **(c) data-reading/boot glue**, SQL itself is neutral data | The SQL is type-1 data: `AUTHORITY_READ` (23–32) calls `analysis.capability_graph_source(...)`; `CLOSURE_READ` (34–64); `RESOLUTION_READ` (66–125); `MECHANIC_READ` (127–128); `readAuthority` (130–158). Node-specific: `node:fs/path/url` (1–3), standalone `process.argv` main (160–168). |
| `C:\lab\repos\sfx-embody\src\read-execution-delivery.mjs` (23 lines) | Reads the declared execution-delivery provider and the default target from the DB. | **(c) data-reading/boot glue** (logic is language-neutral) | Whole file. `readExecutionDelivery` (3–23); reads `analysis.v_selected_semantic_definition` for `PROVIDER` `executionDelivery` and for the `PORT` in namespace `sidefx:capability:read-capability-authority` (5–14); returns `{capabilityId, requestExpression, resultExpression, defaultTarget, providerId, snapshotId, projectionDigest, viewDefinitionDigest}` (21–22). |
| `C:\lab\repos\sfx-embody\src\read-workspace-config.mjs` (18 lines) | Reads `config/regression.cases.json` and resolves relative paths. | **(c) boot/test glue** (Node-specific) | `node:fs/path/url` (1–3); `readWorkspaceConfig` (5–17). |
| `C:\lab\repos\sfx-embody\src\restrict-memory-process.mjs` (41 lines) | Node permission + child-process restriction (storage proof controls). | **(b) Node-specific host** | `node:path`, `node:child_process`, `node:module` `syncBuiltinESMExports`, `node:crypto` (1–4); `process.permission` checks (11–13); monkeypatches `execFileSync` and replaces `exec/execSync/execFile/spawn/spawnSync/fork` (20–30); exposes `spawnDeclared` (34–39). Must be re-authored per host language. |
| `C:\lab\repos\sfx-embody\src\database-read-session.mjs` (77 lines) | One pinned, impersonated read connection per invocation; query wrapper with row limits, normalization, digests, serialization. | **(b) host/DB-driver-specific** (semantics are neutral) | Uses the injected mssql `sql.Transaction`/`sql.Request` and `BEGIN`/`ROLLBACK`/`EXECUTE AS USER='sidefx_reader'` (11–22, 41–46); `withDatabaseReadSession` (3–77). Re-author per host DB driver. |
| `C:\lab\repos\sfx-embody\src\projection-delivery.mjs` (144 lines) | Frontdoor for `sfx capability project`: stdin envelope, DB driver import, stages declared documents, invokes the SDA consumer projector, inspects plans, counts files, writes stdout. | **(b) Node-specific host + (c) boot glue** | `ADMITTED_TARGETS = ['node','python','csharp']` (15); `validate` (21–33); `readDocuments` via `analysis.capability_graph_source(...,1,NULL)` (35–45); `stageWorkspace` (47–59); `inspectPlan` (63–71); `countFiles` (73–85); `project` (87–111); `main` stdin/argv/import (113–136); stdout/exit (136–144). |
| `C:\lab\repos\sfx-embody\src\execution-drilldown.mjs` (231 lines) | Observation altitude selection, testimony capture, planned-vs-observed overlay, observed story. | **(a) language-neutral logic** | Pure JSON/Set/Map logic; no Node built-in imports. `ALTITUDES` (9), `isObservationAltitudeSelection` (16–20), `createExecutionDrilldown` (102–231). |
| `C:\lab\repos\sfx-embody\src\observation-filter.mjs` (16 lines) | Observation field allowlist (telemetry-only channel). | **(a) language-neutral logic** | `OBSERVATION_FIELDS` (3–10), `safeObservation` (12–15). |
| `C:\lab\repos\sfx-embody\src\semantic-address.mjs` (127 lines) | Semantic address join (scenario/responsibility/mechanic) and observed-story assembly. | **(a) language-neutral logic** | Pure regex/map logic. `createSemanticAuthority` (12–28), `semanticAddress` (56–91), `buildObservedStory` (97–127). |

### `config/` and `sfx.config.json`

| File | Role | Classification |
|---|---|---|
| `config\sfx.commands.json` (158 lines) | Command mapping (`sfx-command-mapping.v1`): surfaces, operations, identities, wrapped ops. | (a) language-neutral **data** |
| `config\database-runtime.json` (5 lines) | Runtime config `sfx-database-memory-runtime.v1` with `databaseRoot`/`sdaRoot`. | (c) boot glue/config |
| `config\regression.cases.json` (9 lines) | Regression selection list (`databaseRoot`, `sdaRoot`, 3 cases). | (c) test/boot config |
| `config\embodiment-execution.preflight.json` (72 lines) | Preflight cases (python/csharp `execute-declared-capability`). | test config |
| `config\embodiment-execution-delivery.preflight.json` (157 lines) | Preflight cases for direct invocation + node/python/csharp delivery. | test config |
| `config\embodiment-composition.preflight.json` (62 lines) | Preflight composition cases (node/python/csharp). | test config |
| `config\hugging-face-pilots.json` (34 lines) | Pilot probe fixtures for 3 capabilities. | test config |
| `config\selections\adapt-job-market-intelligence-evidence.json` | Selection input `{capabilityId, scenarioId}`. | (c) selection data |
| `config\selections\admit-canonical-circuit-blueprint.json` | Selection input + `target: node`. | (c) selection data |
| `config\selections\resolve-sidefx-eligible-providers.json` | Selection input + `target: node`. | (c) selection data |
| `sfx.config.json` (36 lines) | Project config `sfx-project.v1`; two process deliveries: `database-memory` (`node` + `--experimental-vm-modules --experimental-permission --allow-child-process --allow-fs-read=...` + `src/database-delivery.mjs config/database-runtime.json`, lines 4–26) and `database-projection` (`node src/projection-delivery.mjs config/database-runtime.json`, lines 27–34). | (b) host-specific boot glue |

---

## (b) Frontdoor / loader step sequence — neutral vs per-language

### CLI side (`sidefx-cli`)
1. `loadConfiguration` reads `sfx.config.json` (or shipped mapping) — `C:\lab\repos\sidefx-cli\src\configuration.mjs:11-44`. **Data/neutral.**
2. `parseCommand` / `validateSemanticRequest` — `cli.mjs:88-109`, `commands.mjs:109-165`. **Neutral.**
3. `Sidefx.execute` resolves the wrapped surface and calls `deliverCommand` — `index.mjs:38-89`. **Neutral.**
4. `deliverCommand` builds envelope `{deliveryType:'sfx-command-delivery.v1', operation, request}` and `runProcess` spawns the configured process — `delivery.mjs:46-54`, `56-105`. **Per-language transport**: `spawn` (58), pipe stdio (59), stdin write (104), stderr observation parse `SFX_OBSERVATION ` (75–88). For `observe`, env `SIDEFX_OBSERVE=1` (52).
5. Result read by `readDeliveryResult`: stream-json parser, root must be a JSON object, root-level `executions/observations/nestedExecutions/nestedObservations` filtered out — `delivery-result.mjs:11-47`. **Per-language transport.**

### Frontdoor (`src/database-delivery.mjs`)
1. Read stdin (9 MiB cap) → JSON envelope. **Per-language (stdio).**
2. `validateDatabaseCommand(envelope)` (`invoke-database-capability.mjs:175-202`). **Neutral.**
3. Resolve `process.argv[2]` config; validate `configurationType==='sfx-database-memory-runtime.v1'`, `databaseRoot`, `sdaRoot`; resolve relative paths (20–24). **Per-language (argv/path).**
4. Dynamically import DB runner: `databaseRoot/src/core.mjs` (`config, stable, hash, digest`) and `databaseRoot/src/ingest/database.mjs` (`connectionString, connect, sql`); set credential env (27–30). **Per-language (dynamic import, DB driver).**
5. Inject `normalizeSql` and `pinModel` from `databaseRoot/src/query/*` (34–35). **Per-language (import seam); neutral contract.**
6. `restrictMemoryProcess(config)` → `processEvidence`, set `config.spawnDeclared` (36–37). **Per-language (permission flags + child-process guard).**
7. If `SIDEFX_OBSERVE==='1'`, set `config.onObservation` writing `SFX_OBSERVATION <safeObservation(...)>` to stderr (38–44). **Per-language stderr transport; neutral filter.**
8. `withDatabaseReadSession(...)` opens pool, `BEGIN`, optional `beforePin` (migration preflight), `pinModel`, `EXECUTE AS USER='sidefx_reader'`, then supplies `readQuery`; sets `config.readQuery`/`config.readAuthority` (46–53; `database-read-session.mjs:3-77`). **Per-language DB session; neutral semantics.**
9. `executeDatabaseCommand(envelope, config)` (50). **Neutral loader.**
10. Attach `readSession`/`process`/timings evidence; `process.stdout.write(JSON.stringify(result)+'\n')` (54–59). **Per-language stdout; neutral shape.**
11. Catch → failure envelope, `exitCode = 4` (60–64). **Per-language exit.**

### Loader (`src/invoke-database-capability.mjs#executeDatabaseCommand`, 204–367)
1. `validateDatabaseCommand` + structuredClone (243).
2. Derive `selectedScenarioId` and selection (246–250).
3. For `invoke`/`observe`: `readExecutionDelivery(config)` → default target (255–260). **Data read (neutral).**
4. Reader operation branch: read the declared reader capability, build its input, run `executeEstateCapability({capabilityId:'run-declared-graph'}, ...)`, shape rows/meaning/circuit/artifact (263–306). **Neutral.**
5. Otherwise read the selected declaration (`readSelectedAuthority`) with coherence/truncation guards (313, 216–228). **Data read.**
6. Read CLI config from interface authority (314; 16–29); build canonical/typed input (318–326). **Neutral.**
7. Choose supplied graph vs declared `bundle.graphSource` (331–339). **Neutral.**
8. `display` projection (343–344); `observe` builds drilldown + testimony hooks `onTestimony`/`onState` (349–354). **Neutral.**
9. Compile + execute: `executeEstateCapability({ capabilityId:'run-declared-graph' }, graphSource, config)` (355). **Delegated to the per-language SDA kernel.**
10. Shape final envelope incl. `overlay`/`story`/`observedPathDigest`/evidence (356–366). **Neutral.**
11. Residual estate-provider seam: `executeEstateCapability` dynamically imports `configuration.estateProvider.module` and calls `provider[estate.export](...)` — `executeEstateCapability` at lines 86–116, import at 101–103. **Per-language resolver (type-0); target-architecture calls this a data defect.

**Neutral vs per-language summary**
- Per-language (must be re-authored): process spawn, stdin/stdout/stderr protocol, JSON envelope wire I/O, dynamic module import/VM loading (`--experimental-vm-modules`), permission flags (`--experimental-permission`, `--allow-child-process`, `--allow-fs-read`, 11–23 of `sfx.config.json`), `restrictMemoryProcess`, DB driver binding, and the SDA kernel implementations (`run-declared-graph` providers per language).
- Language-neutral: read declaration SQL, command validation/operation table, CLI configuration mapping, coherence checks, session semantics, input mapping, graph selection, result shaping, semantic address/drilldown/observation filter.

---

## (c) Projection output shape

`src/projection-delivery.mjs` (`sfx capability project`) — steps:
1. `validate` allows only `object, verb, subject, workspace, targets, fullMechanics`; targets must be in `['node','python','csharp']`; `fullMechanics` must be exactly `true` (15, 21–33).
2. One pinned read: `SELECT CONVERT(nvarchar(max), g.documents) FROM analysis.capability_graph_source(<id>, 1, NULL)` (36–39, 89).
3. Stage documents into `--workspace` (path-escape guarded) (47–59, 90).
4. `fs.rm(<workspace>/projected, {recursive,force})`; import SDA projector `artifacts/tools/dist/interfaces/consumer-projection/project.js`; call `projectConsumerCapability(workspace, { projectionTargets?, fullMechanics?, repositoryRoot: sdaRoot })` (91–99). Throws `SDA_PROJECTION_TOOLS_NOT_BUILT` if missing (94).
5. Inspect `execution-plans/*.v3.json` (plan dir under `projected/execution-plans`) and read `projected/projection-conformance.json`; count files/bytes (100–106).
6. Return shape (107–110):
```json
{ "capabilityId", "workspace", "outDir", "targets": [...],
  "documents": <staged count>, "files": <count>, "bytes": <count>,
  "fullMechanics": true|false,
  "plans": [ { "target", "canonicalGraphDigest", "realizedGraphDigest",
               "providerBindings": <n>, "requiredSlots": <n>,
               "mechanicsComplete": <bool>, "unboundSlots": [...] } ],
  "conformance": "<disposition>",
  "evidence": { "snapshotId", "projectionDigest" } }
```
Envelope written to stdout: `{ disposition:'terminated', outcome }` (136); failure `{disposition:'failed', errorCode, error}` (142). Per-plan row built by `inspectPlan` (63–71).

**Files under `embodiments/<id>/projected/<target>/`** (observed for `resolve-equity-market-price-evidence`):

- Shared/root: `application-binding.json`, `application-binding.node.json`, `application-binding.python.json`, `application-binding.csharp.json`, `capability.json`, `projection-conformance.json`, `projection-manifest.json`; `execution-plans/consumer-execution-plan.{node,python,csharp}.v3.json`; `fixtures/fixtures.json`; `scenarios/resolve-equity-market-price-evidence.json`; `telemetry/expected-trace.json`; `query/conformance-query{.node,.python,.csharp}.json`, `query/platform-mechanic-resolution{.node,.python,.csharp}.json`.
- `projected/node/`: `capability-carrier.json`, `capability-execution.generated.mjs`, `capability-operations.generated.mjs`, `capability-runtime.generated.mjs`, `capability.projected.test.mjs`, `conformance-query.generated.mjs`, `execution-operations.json`, `execution-patterns.json`, `resolve-equity-market-price-evidence-cli.generated.mjs`.
- `projected/python/`: `capability-carrier.json`, `capability-operations.generated.py`, `consumer-execution.generated.py`, `consumer.generated.py`, `execution-operations.json`, `execution-patterns.json` (plus a `__pycache__/`).
- `projected/csharp/`: `Capability.projected.test.generated.cs`, `Program.generated.cs`, `ProjectedConsumerCli.generated.cs`, `ProjectedConsumerCli.generated.csproj`, `ProjectedConsumerTest.generated.csproj`.

`projection-conformance.json` (20 lines) is `{ conformanceType:'projected-artifact-mechanical-sterility.v1', sourceOrigin:'PROJECTED', forbiddenExecutableMechanics: {all zero}, violations: [], disposition: 'PURE_PROJECTION_CONFORMS' }`. `projection-manifest.json` (524 lines) carries `authorityRefs`, `admittedPlatformCapabilities` (61 entries) and `files[]` each `{path, executableOrigin, sha256, digest, sourcePointers}`.

Doc evidence: `docs/implementation-strategy.md:112-144` (projection command, "32 files", "137/137 bindings", `PURE_PROJECTION_CONFORMS`; and the finding that generated seam specifiers are workspace-depth-relative — an SDA request). `--full-mechanics` semantics defined at `config/sfx.commands.json:129-141` and validated at `sidefx-cli/src/commands.mjs:160-163`.

---

## (d) Declaration-surface findings

### The views exist

- `analysis.v_capability_graph_source` — **yes.**
  - Created `sql\migrations\assemble-capability-graph-source.sql:19`; re-defined `sql\migrations\expose-contract-authorities-in-graph-source.sql:39`; finalized `sql\migrations\optimize-capability-graph-source.sql:152-160`.
  - Columns: `capability_id`, `root_scenario_id`, `graph_source`.
  - `graph_source` JSON keys: `capabilityId`, `rootScenarioId`, `scenarios`, `transitions` (`[]`), `executionAuthorities`, `interfaceAuthority`, `semanticTransformations`, `contractAuthorities` (see `optimize-capability-graph-source.sql:136-147`; `expose-contract-authorities-in-graph-source.sql:125-136`; contract authorities shape documented at `expose-contract-authorities-in-graph-source.sql:14-16`).
- `analysis.v_capability_execution_declaration` — **yes.**
  - Created `sql\schema\assemble-execution-declarations.sql:26`; re-created `sql\migrations\declare-estate-providers.sql:88`, `sql\migrations\declare-graph-native-consumer-topology.sql:31`, `sql\migrations\include-declared-schema-references.sql:741`.
  - Columns: `estate_model_pk`, `capability_id`, `source_path`, `entry_id`, `document` (assembled document set: `capability.authority.json`, `execution-authorities.authority.json`, `semantic-transformation.authority.json`, `semantic-graph.authority.json`, `interfaces.authority.json`, `consumer-workspace.authority.json`, `capability.feature`, `contracts/contract-catalog.json`, `contracts/<id>.schema.json`, `fixtures.authority.json`; see `assemble-execution-declarations.sql:96-210`).

### What the runtime actually reads

- `src\read-authority.mjs:23-32` does **not** select the view; it calls the inline TVF `analysis.capability_graph_source(@input capabilityId, includeDocuments, namespaceId)` and selects columns `capability_id, root_scenario_id AS scenario_id, namespace_id, graph_source, cli_configuration, documents`.
- That TVF is defined/overwritten by `sql\migrations\optimize-capability-graph-source.sql:49`, `sql\migrations\bound-capability-invocation-reads.sql:276-367`, and `sql\migrations\expose-sda-conforming-declaration-documents.sql:316-407`; return columns: `estate_model_pk, capability_id, namespace_id, root_scenario_id, graph_source, cli_configuration, documents` (`bound-capability-invocation-reads.sql:279-287`).
- Closure read uses `analysis.v_scenario_invocation_closure` (`read-authority.mjs:55-64`); resolution read uses `analysis.v_scenario_language_resolution` and `analysis.v_declared_platform_implementation` (`read-authority.mjs:85-95`); mechanics read uses `analysis.v_selected_semantic_definition` (`read-authority.mjs:127-128`). Execution delivery reads `analysis.v_selected_semantic_definition` (`read-execution-delivery.mjs:5-14`).

### Residual bindings naming `src/resolvers` / `estateProvider` / `providerId`

- The authoritative report is the query `sql\inspect\hand-authored-module-references.sql` (68 lines). It has 5 union branches + a raw-declaration residual: PROVIDER `semantics.module` (8–17); PORT `semantics.configuration.estateProvider.module` (22–26); PORT `semantics.configuration.admissionProvider.module` (31–35); PORT `planningProviders[].module` (40–44); PORT `writingProviders[].module` (48–52); raw `src/resolvers/` or `src/verification/` (58–66).
- **Stored report artifact: not found.** No JSON/receipt of this query exists in the repo; grep for `hand-authored-module-references` finds only the `.sql` and prose.
- **Stated counts (report exists as prose):** `docs\implementation-strategy.md:92-95`: "`sql/inspect/hand-authored-module-references.sql` is down from **21 to 16 rows**; **7 estate-module PROVIDER rows remain** (consumer-authority-context, consumer-execution-provider, consumer-plan-provider, embodiment-plan-provider, embodiment-write-provider, invoke-database-capability, load-memory-scenario) pending Port re-declaration." (Lane B unit 3 target in the backlog is "zero residual references", status **partial** — `implementation-strategy.md:53`.)
- **Raw grep counts (file-level, includes historical one-off migrations):** `sql\migrations\*.sql` — **21 files** contain `src/resolvers`, **27 files** contain `estateProvider`, **42 files** contain `providerId`; `sql\schema\*.sql` — **0** contain `estateProvider`; `sql\inspect\*.sql` — **1** contains `estateProvider` (the inspect query itself). The authoritative declaration-row count is the inspect query/doc figure (16 rows), not the file count.
- The residual seam mechanism: `sql\migrations\declare-estate-providers.sql:24-54` defines `analysis.fn_estate_provider_semantics(@provider_id)` and `analysis.v_estate_provider_resolved_port_semantics`, which inject `configuration.estateProvider` from the provider row named by `configuration.providerId`; lines 57–86 mint estate-module PROVIDER rows from `estateProvider.module`/`.export`. The loader resolves this at `src\invoke-database-capability.mjs:99-103`.
- Binding standard: a Port MUST NOT carry `configuration.providerId` naming a module nor `configuration.estateProvider`; any binding naming `src/resolvers/*`, `materialize-node`, or any estate module is a **data defect** (`docs\target-architecture.md:150-161`). The target-architecture research finding calls it the "Residual estate-provider seam" (`docs\research\target-architecture\target-experience-research-findings.md:265`).

### Declaration-document SDA conformance

- `sql\migrations\expose-sda-conforming-declaration-documents.sql` makes the documents SDA-conforming (port bindings `{portId, platformCapabilityId, configuration}`, transformations `{id, expression}`, workspace carries `kernel/governance/conformanceQuery/telemetryAuthority/platformCapabilityCatalog`, emits `projection-authorities.authority.json`). Documented at `docs\implementation-strategy.md:127-144`.

---

## (e) Exact citations

### `src/` role anchors
- `src\database-delivery.mjs:11-18, 19, 20-24, 27-35, 36-37, 38-44, 46-53, 54-59, 60-64`
- `src\invoke-database-capability.mjs:1-2, 16-29, 99-103, 121-122, 144-151, 156-169, 175-202, 204-367, 243, 246-260, 263-306, 313-344, 349-355, 358-366`
- `src\read-authority.mjs:1-3, 23-32, 34-64, 66-125, 127-128, 130-158, 160-168`
- `src\read-execution-delivery.mjs:3-23`
- `src\read-workspace-config.mjs:5-17`
- `src\restrict-memory-process.mjs:10-41`
- `src\database-read-session.mjs:3-77`
- `src\projection-delivery.mjs:15, 21-33, 35-45, 47-59, 63-71, 73-85, 87-111, 113-144`
- `src\execution-drilldown.mjs:9, 16-20, 102-231`
- `src\observation-filter.mjs:3-15`
- `src\semantic-address.mjs:12-28, 56-91, 97-127`

### CLI transport
- `C:\lab\repos\sidefx-cli\src\delivery.mjs:33-42, 46-54, 56-105`
- `C:\lab\repos\sidefx-cli\src\delivery-result.mjs:11-47`
- `C:\lab\repos\sidefx-cli\src\configuration.mjs:11-44`
- `C:\lab\repos\sidefx-cli\src\commands.mjs:9-12, 99-165`
- `C:\lab\repos\sidefx-cli\src\index.mjs:38-89`
- `C:\lab\repos\sidefx-cli\src\cli.mjs:73-84, 88-109, 132-180`

### Boot sequence docs
- `docs\research\target-architecture\target-experience-research-findings.md:242-268` (explicit invocation chain; residual seam at 265)
- `docs\target-architecture.md:34-59, 67-71, 186-210`
- `docs\scripts-disposition-review.md:22-79`
- `docs\next-experiences.md:52-66, 68-101`
- `docs\database-direct-invocation.md:120-180` (historical; note it still describes `materialize-node`, a file no longer in `src/`)
- `docs\performance-optimization.md:113-127` (boot/loader read costs)

### Projection
- `config\sfx.commands.json:17-22, 129-141`
- `sfx.config.json:4-34`
- `src\projection-delivery.mjs` (above); `docs\implementation-strategy.md:112-144`
- `embodiments\resolve-equity-market-price-evidence\projected\projection-conformance.json:1-20`
- `embodiments\resolve-equity-market-price-evidence\projected\projection-manifest.json:1-524`

### Declaration surface / residuals
- `sql\README.md:18-23`
- `sql\schema\assemble-execution-declarations.sql:26-210, 274-296`
- `sql\migrations\assemble-capability-graph-source.sql:19-89`
- `sql\migrations\expose-contract-authorities-in-graph-source.sql:39-136`
- `sql\migrations\optimize-capability-graph-source.sql:49, 136-160`
- `sql\migrations\bound-capability-invocation-reads.sql:276-367`
- `sql\migrations\expose-sda-conforming-declaration-documents.sql:316-407`
- `sql\inspect\hand-authored-module-references.sql:1-68`
- `sql\migrations\declare-estate-providers.sql:24-86`
- `docs\implementation-strategy.md:52-53, 85-98, 127-144`
- `docs\target-architecture.md:150-161`

### Language selection ownership
- The CLI has **no `--target` option**; only `--targets` (projection) — `sidefx-cli\src\cli.mjs:79`, `sidefx-cli\src\commands.mjs:11-12`.
- Target/default language comes from the estate declaration: `src\read-execution-delivery.mjs:5-22` (`defaultTarget` from the DB), consumed at `src\invoke-database-capability.mjs:255-260`; for python/csharp the target travels inside canonical input and is interpreted by the declared capability (`config\embodiment-execution-delivery.preflight.json:88-155`; `config\embodiment-composition.preflight.json:22-61`).
- Target-neutrality is a stated remaining step: `docs\cross-target-embodiment.md:28, 90` ("sfx-embody target neutrality, so the target is data rather than a branch in the materializer").

---

## (f) NPM scripts and test counts

### NPM scripts
- Root `package.json:13-15` — the **only** script is `"test": "node --test tests"`.
- **Not found:** `verify:estate`, `verify:memory`, `audit:source`, `audit:lowering`, `report`, `qualify:pilots`, `package:pilots`, `project:consumer-capability`. These are still referenced in `AGENTS.md:62-63`, `README.md:102-105`, and multiple docs, but no longer exist in `package.json` (removed in Lane D; `docs\implementation-strategy.md:56, 74-84`). The baseline manifest `baselines\...\package.json` has no scripts at all.
- Baseline `baselines\bbf0345d...\package.json:1-8` — dependencies only, no scripts.

### Test counts
- 7 test files: `consumer-plan.test.mjs` (1), `database-command.test.mjs` (7), `database-read-session.integration.test.mjs` (3, skipped unless `SFX_DATABASE_INTEGRATION=1`), `database-read-session.test.mjs` (8 static + a `for` loop over 8 phases = 16 at runtime), `execution-drilldown.test.mjs` (5), `invocation-read.test.mjs` (12), `semantic-address.test.mjs` (6).
- **Runtime total: 50 tests; 3 database-gated skips by default → 47 pass / 50.** This matches the doc claims `docs\implementation-strategy.md:124` and `:143`.
- **Static `test(...)`/`it(...)` declarations: 43** (one of them is inside an 8-iteration loop). Earlier docs state "8/8" (`docs\implementation-strategy.md:84`, `docs\scripts-disposition-review.md:154`) and "4/4" / "16 local" in older docs (`docs\embodiment-review-findings.md:9`, `docs\capability-command-surface.md:376`, `docs\database-direct-invocation.md:166`); these reflect earlier suite states, not the current tree.

---

## (g) Direct answers to the framing

- **Current bootstrap classification:** the boot is mixed. Language-neutral *logic* lives in `invoke-database-capability.mjs` (operation table / validation / shaping), `execution-drilldown.mjs`, `observation-filter.mjs`, `semantic-address.mjs`, and the SQL in `read-authority.mjs`/`read-execution-delivery.mjs`. Everything that actually performs the transport and platform binding — spawn, VM module loading (`--experimental-vm-modules`), permission flags (`--experimental-permission` + `--allow-*`), stdin/stdout/stderr protocol, child-process guards, DB-driver session, and the per-language SDA kernel — is type-0 host code that must exist per language. The single heaviest Node seam is `src\database-delivery.mjs` plus `src\restrict-memory-process.mjs`.
- **Language selection owner:** the estate/database, not the CLI. The CLI is transport only; `defaultTarget` is read from declared rows (`read-execution-delivery.mjs`) and per-capability targets are carried as invocation input.
- **Declaration surface:** both `analysis.v_capability_graph_source` and `analysis.v_capability_execution_declaration` exist and are assembled from rows; the runtime read path uses the `analysis.capability_graph_source(...)` TVF. Residual `estateProvider`/`src/resolvers` bindings persist in the migration history and in the loader's `executeEstateCapability` seam; the inspect query reports **16 rows (down from 21)**, with **7 estate-module PROVIDER rows** remaining.
- **Not found:** no stored report artifact for the module-reference inspect query; no `--target` CLI flag; no NPM scripts beyond `test`; no java/go in `ADMITTED_TARGETS` (only `node`/`python`/`csharp`).

---

I have gathered sufficient evidence. Here is the structured report.

---

# The transistor model across the SideFX estate — research report

**Scope actually inspected:** `C:\lab\repos\sfx-embody`, `C:\lab\repos\scenario-driven-architecture` (SDA), `C:\lab\repos\sidefx-cli`, plus two adjacent repos the evidence pointed to: `C:\lab\repos\sda-bootstrap` and `C:\lab\repos\agentic-harness`. **`sidefx-database` is not at `C:\lab\repos\sidefx-database`; it is at `C:\lab\sidefx-database`** (the docs' `DB:` root `../../sidefx-database` resolves to `C:\lab\sidefx-database`, confirmed on disk). All findings below are read-only and cite files I opened.

---

## 1. Executable mechanic kinds a declared execution graph can name — resolver (0) vs declared (1)

A compiled SDA graph names **cells** and **edges**. The cell's executable authority is one of five kinds (`kernel/schemas/execution-cell.schema.json:25`): `scenario`, `mechanic`, `provider`, `physical`, `junction`. The kinds of *mechanic* that can be named, with their authorities:

| Mechanic kind | Authority file (declared catalog) | Count | What is declared (1) | What must exist per language (0 = resolver) |
|---|---|---|---|---|
| Pure semantic-value | `kernel/semantic-authority/consumer/semantic-value-mechanics.authority.v1.json` | 36 | `mechanicId`, `authoringForm` (`semantic-transformation-expression.v1`), contracts, `conformanceRefs`; `nativeFloor:false` | a transformation/expression evaluator + mechanic provider per language |
| Collection / recurrence | same authority (map/filter/find/some/every/flat-map/unique) + `kernel/schemas/execution-pattern.v1.schema.json` (`for-each`, `recurrence`, `decomposition`, `join`, `broadcast`, `selection`) | 10 patterns | `patternType`, `decisions`, `invariants`, `dataRefs`, `recurrenceAuthorities` | `execution-pattern-resolvers.*` + scheduler per language |
| Transformation / language | `sda-authority-transformation-port.v1` (node registry; `semantic-transformation-evaluator.mjs`) | 1 port | the AST recipe is data | evaluator code per language (marked **COMPILER-EMITTED** end-state in the inventory) |
| Platform effect ports | `kernel/semantic-authority/consumer/platform-effect-mechanics.authority.v1.json` | 18 (`nativeFloor:true`) | meaning + `sourceProfiles` (`platform-effect-provider.v1`) | **irreducible native code per language/OS** (file, process, clock, credential, HTTP) |
| Declared data reads | `sda-declared-read-graph-provider.v1` / `sda-declared-value-port.v1` + Port config `{statement, resultColumn}` (`sfx-embody docs/target-architecture.md:155`) | composed | the SQL statement + column | a declared-read provider per language + DB driver |
| Contract / schema admission | `sda-schema-contract-admission.v1`, `sda-fixture-contract-validator.v1` | 2 | schemas in `plan.contractCatalog` | a JSON-Schema validator per language |
| Scheduling | `kernel/semantic-authority/consumer/*-mechanic-registry.authority.v1.json` `nativeExecutionOperations`, `executionPatterns`, `schedulerProviders` | `operation:for-each` → `kernel-scheduler` | topology + decision fields | the token scheduler per language (node `semantic-execution-graph/scheduler.js`, python `platform/execution_graph.py`, csharp `Graph/SemanticExecutionGraphScheduler.cs`, etc.) |

**Classification rule made explicit:** in SDA, *which* mechanic runs and *with what configuration* is always declared (the transistor "1"); the *implementation of the mechanic* is a language resolver body (the transistor "0"). Both catalogs themselves declare `lifecycle: ADMITTED` and a digest. The twelve "forbidden mechanics" (branch, iteration, exception-handling, throw, object-construction, serialization, normalization, validation, fallback, retry, state-mutation, meaning-hidden-in-text) are exactly the capabilities a resolver is *allowed* to embody — `docs/decisions/0013-hand-authored-surface-is-language-resolvers-only.md:33-40`, `governance/workspace/governance-rules.json` K016/K029.

The edge kinds are declared data too: `sequence, selection, broadcast, join, recurrence, return, failure, cancellation, testimony` (`execution-edge.schema.json:11`); the cell protocol is `cell-execution-protocol.v1` (5 steps, `routingAuthority: outcome-variant-and-declared-edge-only`).

**Not found:** a single machine-readable `projected-execution-mechanic-taxonomy.v1` authority. The 12 names are duplicated between the kernel schema (`projected-artifact-mechanical-sterility.schema.json:14`) and the TypeScript evaluator (`tools/src/consumer-projection/proof/mechanical-sterility-evaluator.ts:7-20`); the analysis doc recommends creating the authority (`docs/sda-common-execution-mechanics-and-deterministic-tooling-capabilities-analysis.md:284-301`) but no such file exists.

---

## 2. The multi-language bootstrap — what it is now, and the minimal per-language code

### What the current bootstrap actually does (Node)

The invocation chain is **`sidefx-cli` → child process → `sfx-embody/src/database-delivery.mjs` → `invoke-database-capability.mjs` → SDA kernel**:

| Layer | File | Role |
|---|---|---|
| CLI transport | `sidefx-cli/src/delivery.mjs:33-54` | `spawn(process.execPath, [bootstrapEntry,...])`, stdin envelope, stdout result, stderr `SFX_OBSERVATION`; resolves the estate's `node_modules/sda-bootstrap` bin (`delivery.mjs:19-31`) |
| Frontdoor | `sfx-embody/src/database-delivery.mjs` | reads stdin envelope, **owns the DB connection**, dynamically `import()`s `sidefx-database/src/core.mjs`, `src/ingest/database.mjs`, `src/query/run.mjs`, `src/query/model-pin.mjs` (`:27-35`), injects `readQuery`/`readAuthority` into the loader |
| DB read session | `sfx-embody/src/database-read-session.mjs` | one pinned transaction, `EXECUTE AS USER='sidefx_reader'`, rollback-only, in-memory recordsets |
| Sandbox/permission | `sfx-embody/src/restrict-memory-process.mjs` | requires `process.permission.fs.write === false`; forbids reads of `embodiments`/DB `data`; replaces `child_process` so only a declared `git rev-parse` spawn survives |
| Loader | `sfx-embody/src/invoke-database-capability.mjs` | validates the command envelope, reads the declaration from `analysis.v_*`, hands the graph to the kernel; `bodyStorage: 'NOT_REQUESTED'` (`:363`) |
| Kernel | SDA `languages/typescript/runtimes/node/…` | compiles + interprets the graph |
| Sealed/packaged form (new) | `sda-bootstrap` repo | a single Node package bundling the pinned SDA Node runtime + projector (`bootstrap/bootstrap.manifest.json:42-57`); declares `languageResolver.target: "node"` (`:4`) |

The frontdoor also imports the estate's own Node provider module (`invoke-database-capability.mjs:121` imports `languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs`) and per-port estate providers (`:101`). So today the *entire* boot is Node.

### Minimal set of per-language code to boot and invoke the same declared capability

Distinguish **language-neutral boot logic** (portable, and in SDA already expressed as the canonical graph + schema) from **host-specific code** (must be re-authored or shimmed):

| Concern | Neutral or host-specific | Evidence |
|---|---|---|
| Read declaration / canonical graph | **Neutral** — `sda-semantic-execution-graph.v1` is the "only target-neutral authority" (`kernel/schemas/semantic-execution-graph.schema.json:5`) | graph is JSON |
| Compile graph | Neutral *as data* (projector emits plan v3), but **each language currently re-implements the compiler** — every registry declares a compilation provider (`node`, `python`, `csharp`, `java`, `go`, `cpp` registries all list `sda-semantic-execution-graph-compilation-port.v1`) | the port is fixed by `languages/typescript/runtimes/node/semantic-execution-graph/compiler.js`; the handoff demands byte-for-byte digest parity (`docs/handoff/semantic-execution-graph-compilation-python-csharp.md:49-57`) |
| Execute / schedule | **Host-specific** — token scheduler per language | `language-graph-v1-conformance.json` `schedulerRef` per target |
| Shape result | Neutral (contracts), per-language serialization | contracts are declared |
| DB connection / query runner | **Irreducible host-specific** — proof by circularity (`docs/target-architecture.md:47-52`) | node `sidefx-database/src/query/run.mjs`; the node frontdoor injects it |
| Process spawn / stdin-stdout protocol | **Host-specific** | node `database-delivery.mjs`, CLI `delivery.mjs` |
| Dynamic module load | **Host-specific** | node `import()`/`pathToFileURL` |
| Sandbox / permission flags | **Host-specific and currently Node-only** | `restrict-memory-process.mjs` |
| DB driver | **Host-specific** | mssql driver in `sidefx-database` |
| Platform effect mechanics | **Irreducible native per language** (`nativeFloor:true`) | platform-effect authority |
| Frontdoor / loader | **Irreducible** (proof by regress, `target-architecture.md:38-45`) | |
| Bootstrap installer | **Irreducible at bootstrap** (proof by regress, `target-architecture.md:54-59`) | |

So the minimal per-language boot is: **process entry + envelope protocol + DB driver/query runner + declaration read + scheduler/evaluator + effect ports + a permission boundary**. The *only* genuinely shareable pieces are the declared graph/plan, the contracts, and the canonical digests. The claim "the bootstrap must exist in multiple languages" is grounded by `target-architecture.md`'s irreducible three plus the per-language scheduler/effect floor.

---

## 3. What already exists per language toward this (consumer host that reads a declared graph and executes it)

All six language bindings are `status: "IMPLEMENTING"`. All six are marked `ADMITTED` for **graph scheduling** in `conformance/execution-graph/language-graph-v1-conformance.json:6-43`.

| Language | Kernel | Graph compiler + scheduler + providers | Registry authority | Binding status | Graph conformance |
|---|---|---|---|---|---|
| Node | `src/kernel/scenario-kernel.ts`, `disposition-resolver.ts` | `runtimes/node/semantic-execution-graph/*` (compiler, scheduler, normalizer, overlay), `semantic-execution-graph-*-provider.mjs` | `node-mechanic-registry.authority.v1.json` | IMPLEMENTING | ADMITTED |
| Python | `src/scenario_kernel/kernel/scenario_kernel.py` | `adapters/semantic_execution_graph_{compiler,compilation_provider,execution_provider,mechanic_provider,effect_provider,declared_read_provider,overlay_provider}.py`, `platform/execution_graph.py`, `platform/execution_pattern_resolvers.py`, `platform/governed_effect_ports.py` | `python-mechanic-registry.authority.v1.json` | IMPLEMENTING | ADMITTED |
| C# | `src/ScenarioKernel/ScenarioKernel.cs` | `Adapters/Graph/SemanticExecutionGraph{Scheduler,Compiler,CompilationProvider,ExecutionProvider,MechanicProvider,EffectProvider,DeclaredReadProvider,OverlayProvider}.cs`, `Schema/SemanticContractCatalogAdmission.cs` | `csharp-mechanic-registry.authority.v1.json` | IMPLEMENTING | ADMITTED |
| Java | `src/main/java/.../kernel/ScenarioKernel.java` | `platform/SemanticExecutionGraph{Scheduler,Compiler,CompilationProvider,ExecutionProvider,MechanicProvider,EffectProvider,DeclaredReadProvider,OverlayProvider,Validator}.java`, `GraphNormalizer.java`, `GovernedEffectPorts.java` | `java-mechanic-registry.authority.v1.json` | IMPLEMENTING | ADMITTED |
| Go | `kernel/scenario_kernel.go` | `platform/graph_{compiler,execution_provider,mechanic_provider,effect_provider,declared_read_provider,overlay_provider,consumer_host,normalizer,validator}.go`, `platform/execution_graph.go` | `go-mechanic-registry.authority.v1.json` | IMPLEMENTING | ADMITTED |
| C++ | *(no `kernel/` dir; `binding.projectReferences.kernel = "generated/execution"`, i.e. projected)* | `graph/execution_graph_{scheduler,compiler,compilation_provider,execution_provider,mechanic_provider,effect_provider,declared_read_provider,overlay_provider,validator}.cpp`, `graph/graph_normalizer.cpp`, `platform/consumer_platform.cpp` | `cpp-mechanic-registry.authority.v1.json` | IMPLEMENTING | ADMITTED |

**Caveat (drift):** `docs/languages-resolver-boundary-and-projection-inventory.md:209-218` (dated 2026-08-17) still says C++ "has no kernel yet" and Swift/Kotlin have no kernel. Since then C++ was admitted to graph conformance (commits `2ab27c8`, `c0515c9`, `6a529ca` in the SDA log) and now carries a full `graph/` provider set; the inventory is stale on C++. **Swift and Kotlin have only presentation surfaces** (`languages/swift/presentation/swiftui`, `languages/kotlin/presentation/android-compose`) and no programming-language kernel — confirmed, and they are *not* in `language-graph-v1-conformance.json`.

**Per-language consumer host existence:** Python/C#/Java/Go all have an `AdmittedConsumerPlatform`/`consumer`/`platform` entry that reads a plan and executes it (Runtime A). Python's and C#'s effect-dispatch and contract-admission wiring was closed 2026-09-14; **Java/Go/C++ effect ports and registry loaders remain per the registries' own gaps** (`go`/`java`/`cpp` registries declare the 2 effect ports and contract admission, but only Node has a `*-mechanic-registry-loader` — see §6).

---

## 4. Bootstrap realization options, with tradeoffs

The three options, grounded in existing artifacts:

**(a) Per-language re-authored bootstrap.** Each language implements frontdoor + loader + DB runner + kernel + effects.
- *Preserves:* per-language native execution and `nativeFloor` effects; no cross-language sandbox ceiling.
- *Cost:* N× the irreducible three; N× isolation boundaries (only Node's exists: `restrict-memory-process.mjs` + `--experimental-permission`); N× DB drivers.
- *Evidence it is intended:* the per-language provider registries and `embodiment-completeness.md:48-56` (every mechanic must exist in all three node/python/csharp, later java/go).

**(b) One sealed/compiled binary per OS.** Node SEA + `postject`, signed/attested.
- *Documented:* `sfx-embody/docs/next-experiences.md:68-101` — "Node SEA (`--experimental-sea-config` + `postject`) is the closest fit because it preserves Node's permission flags and the guard"; trust boundary is "sealed implementation (frontdoor + loader + DB runner + kernel + providers); open authority rows and config".
- *Preserves:* the Node permission guard and the "no materialization" rule unchanged; one implementation to seal, not N.
- *Cost/risk:* still one language's runtime (Node SEA embeds Node — it does not give Python/Java/etc. hosts); the doc explicitly notes the CLI must verify the digest **before spawn** ("a binary cannot attest itself"), and sealing Node alone "leaks" the SDA kernel/providers unless they are bundled too (`next-experiences.md:91-94`). `sda-bootstrap` is the current, unsealed precursor (package with bundled platform).
- *Not found:* any SEA/`postject`/signing build script or attestation in any repo; no `postject`/`--experimental-sea-config` references.

**(c) Thin per-language shim shelling to one canonical host.**
- *Preserves:* one kernel/provider implementation; simplest admission.
- *Cost:* crosses a language boundary — each shim must own the envelope protocol and the isolation boundary; and the platform-effect mechanics (`nativeFloor:true`) would still be executed by the canonical host, not natively, which contradicts the "embodied in code, per target" rule (`embodiment-completeness.md:3-6`). The estate already rejected a related facade: "A language that returns its input unchanged … is a facade, not an embodiment" (`embodiment-completeness.md:41-46`).
- *Evidence:* the CLI itself already *is* a thin shell to a spawned host (`sidefx-cli/src/delivery.mjs`), so the pattern exists at the CLI layer.

**Irreducible per language** (regardless of option): DB connection/query runner (`target-architecture.md:47-52`); frontdoor/loader (`:38-45`); bootstrap installer (`:54-59`); `nativeFloor:true` effect mechanics; the token scheduler (proven per target). **Shareable:** declared graph/plan, contracts, canonical digests, projector output.

**Isolation/permission boundary per option:** (a) re-implement per language; (b) inherit Node's `--experimental-permission` + `restrictMemoryProcess` and add pre-spawn digest verification in the CLI; (c) the shim must enforce the boundary before shelling, and the canonical host keeps its own. **"No materialization on the invocation path"** is preserved by all three only if the host never writes bodies or spawns on the invocation path; today that is explicit (`invoke-database-capability.mjs:363` `bodyStorage:'NOT_REQUESTED'`; `target-architecture.md:26-28`, `:70`, `:79-84`; `docs/next-experiences.md:65-66`).

---

## 5. Cross-language conformance obligation — what a new language must prove

The obligation is **digest parity**, and the corpus is real (files exist):

| Obligation | Artifact / gate | Citation |
|---|---|---|
| Mechanic vector parity (all declared semantics) | `conformance/execution-graph/mechanics/*.v1` (per-mechanic vectors) run by `run-mechanic-conformance.mjs`; "an implementation conforms when every vector reproduces its outcome exactly. No target's runtime is the specification, including the Node one." | `conformance/execution-graph/mechanics/README.md:6-8,44-68` |
| Graph digest parity | `conformance/execution-graph/language-graph-v1-conformance.json` — fixture `fixtures/cross-target-selection.plan.v3.json`, shared `canonicalGraphDigest: sha256:c0851c…`, `expectedObservedPathDigest`, and a `{targetId,status,schedulerRef,testRef}` row per target | `language-graph-v1-conformance.json:1-43` |
| Plan shape carries both digests | `consumer-execution-embodiment-plan.v3.schema.json` **requires** `canonicalGraph` + `canonicalGraphDigest` + `realizationOverlay` + `realizedGraphDigest` | `capabilities/sda-platform/consumer-execution-embodiment/contracts/consumer-execution-embodiment-plan.v3.schema.json:8-17` |
| Kernel execution-vector conformance | `conformance/corpus/execution/*.json` + `conformance/expectations/execution/*.expected.json` (given/then separated, K006E) | `conformance/README.md:9-19`, `governance-rules.json` K006E |
| Language implementation-conformance claim | `languages/{lang}/conformance/scenario-kernel-*.conformance.json` (K006C), e.g. node's maps every semantic object + execution step + `dataAuthority` | `languages/typescript/conformance/scenario-kernel-node.conformance.json` |
| Consumer-platform parity (13 mandatory mechanics) | `kernel/semantic-authority/consumer/sda-platform-mechanic-parity.semantic-authority.json` (`profileId: sda-consumer-mandatory-mechanics.v1`, `appliesToBindingStatuses: ["IMPLEMENTING"]`) consumed by tools | `sda-platform-mechanic-parity.semantic-authority.json:1-20`; consumers in `tools/src/adapters/consumer-projection/node-consumer-workspace-repository.ts:212-234`, `node-consumer-assurance-repository.ts:29`, test `tools/tests/consumer-projection/platform-capability-admission.test.js:16,110` |
| Outcome digest parity across targets | proof definition in `docs/embodiment-completeness.md:143-154` — same `disposition`, `outcome.disposition`, `resolutionDigest`; same canonical graph digest; per-target realized digest | |
| Native-runtime boundary (no foreign delegation) | `kernel/schemas/native-runtime-boundary.schema.json` requires `foreignRuntimeDependencies: maxItems 0`, `foreignSemanticDelegations: maxItems 0`; a C++ instance exists (`languages/cpp/conformance/native-runtime-boundary.json`) | |
| Graph compile port | `sda-semantic-execution-graph-compilation-port.v1` must be registered with `providesMechanics`, `status: ADMITTED`, and reproduce the Node compiler's digests | `docs/handoff/semantic-execution-graph-compilation-python-csharp.md:49-108` |

Mandatory mechanics profile is 13 (11 base + `authority-driven-transformation` + `durable-artifact-materialization`): `contract-document-reading, canonicalization, schema-admission, authority-resolution, semantic-execution, telemetry-observation, scenario-invocation, transition-binding-projection, interface-delivery, runtime-projection, artifact-result-delivery, authority-driven-transformation, durable-artifact-materialization`.

---

## 6. Enforcement mechanism for the transistor rule — what exists, what is missing

### Exists

| Mechanism | File | What it actually enforces |
|---|---|---|
| K016 / K029 governance rules | `governance/workspace/governance-rules.json:145-150,236-241` | declares `PROJECTED_EXECUTION_MECHANIC_VIOLATION` and `NON_RESOLVER_HAND_AUTHORED_MECHANIC` |
| Twelve-counter evaluator | `tools/src/consumer-projection/proof/mechanical-sterility-evaluator.ts:7-20,102-132` | regex counters for all 12 forbidden mechanics; allowlists exact generated seams |
| Evidence schema | `kernel/schemas/projected-artifact-mechanical-sterility.schema.json` | closed 12-key counter object; disposition enum |
| Sterility proof capability | `capabilities/sda-tooling/consumer-assurance/prove-mechanical-sterility/` + projected successor | a declared capability that runs the evaluator |
| Resolver-boundary feature (declared, not wired) | `capabilities/sda-tooling/workspace-governance/features/verify-resolver-boundary-sterility.feature` | declares K029 behavior ("any nonzero count outside a resolver boundary carries an explicit `NON_RESOLVER_HAND_AUTHORED_MECHANIC` finding") |
| Parity gate | `sda-platform-mechanic-parity.semantic-authority.json` + `tools/src/adapters/consumer-projection/node-consumer-workspace-repository.ts:212-234` | validates the 13-mechanic profile; used by admission tests |
| Declaration-level module-reference detector | `sfx-embody/sql/inspect/hand-authored-module-references.sql` | finds any declaration row naming `*.mjs/.js/.py/.cs/.ts` in provider/port/planning/writing config |
| Classifier capability | `agentic-harness/features/detect-hand-authored-code.feature` + `capsules/detect-hand-authored-code.sfxcap` | classifies supplied artifacts against the 12 mechanics (observe/classify only) |
| Harness policy | `agentic-harness/governance/no-hand-authored-code.policy.v1.json` | `handAuthoredExecutableBodyAllowed:false`, `failureDisposition: NON_CANONICAL_EXECUTABLE_BODY_REJECTED` |
| Native-boundary schema | `kernel/schemas/native-runtime-boundary.schema.json` | forbids foreign runtime deps/delegation |

### Missing / broken (explicit gaps)

1. **No resolver boundary is declared.** Every `languages/*/binding/*.binding.json` has only `projectReferences` (node, python, csharp, java, go, cpp all verified). The inventory itself records this: "*Current gap: no `languages/*/binding/*.binding.json` declares one yet*" (`languages-resolver-boundary-and-projection-inventory.md:387`). Without it K029's "inside a declared resolver boundary" cannot be evaluated.
2. **The repository-wide K029 scan is declared but not implemented.** The only twelve-counter evaluator operates on `ConsumerProjectionPlanFile[]` (projection-plan files), not on every executable file in the repo. `verify-resolver-boundary-sterility` appears as a feature but is **absent from `workspace-governance/capability.json` scenarios** and has no provider implementation in `workspace-governance/` (only `capability.json`, `observation-bindings.json`, `provider-bindings.json`, contracts, features). So there is no wired gate that fails when a non-resolver file carries behavior.
3. **No registry fails when a language lacks a *resolver*.** K019 parity is scoped to the 13 *consumer platform mechanics* and to `IMPLEMENTING` bindings; there is no analogue for the resolver bodies (kernel/evaluator/effect ports) themselves. The registries *declare* per-language providers, but a missing evaluator does not mechanically reject admission unless a specific consumer capability's plan needs it (`MISSING_SDA_PLATFORM_CAPABILITY` for that capability, not a language-level failure).
4. **The taxonomy authority is absent** (`projected-execution-mechanic-taxonomy.v1`), so the 12 names live twice and can drift.
5. **The evaluator misses Go.** `mechanical-sterility-evaluator.ts:38` matches `.js|.mjs|.cjs|.ts|.tsx|.cs|.py|.java|swift|kt|cpp` — **`.go` is not included**. The analysis doc flagged precisely this class of gap (`sda-common-execution-mechanics…analysis.md:227`).
6. **Only Node has a registry loader.** `node-mechanic-registry-loader.mjs` exists; the handoff states Python/C# "have **no mechanic-registry loader at all** … the Python/C# hosts are hard-coded, so their registry authorities are not currently consumed by the runtime" (`docs/handoff/semantic-execution-graph-cross-target-host-gaps.md:136-139`). Hence G7 (Python/C# registries omit effect ports) is open.
7. **`sidefx-database` has no ADR-0013-style rule or scan** — it is connection/query-runner only, and its `sql/diagnostics/` remain readers (per `sfx-embody` AGENTS.md the estate is forbidden to use them).

---

## 7. Prior documentation touching bootstrapping, sealed binaries, or the resolver/language split

**sfx-embody**
- `docs/target-architecture.md` — the irreducible three (frontdoor/loader, DB runner, bootstrap installer) and the "no materialization" disposition.
- `docs/next-experiences.md` §2 (sealed bootstrap binary with attested digest), §1 (versioned mechanical bodies + cross-language perf), §4 (vault/unseal boundary); §3 (backdoor-script migration) names `detect-hand-authored-code` and `hand-authored-module-references.sql`.
- `docs/embodiment-completeness.md` — every mechanic in code per language; facade prohibition; digest-parity proof.
- `docs/target-experience.md` — multi-language kernel/projector, digest parity, the bootstrap composition.
- `docs/research/platform-mechanic-honesty.md` — Node-only domain ports; "kernels resolve language and everything else comes from data".
- `docs/strategy/python-csharp-embodiment.md` — the by-rows path to Python/C#, provider-binding rows, per-mechanic coverage table.
- `docs/handoff/sda-capability-invocation.md`, `docs/cross-target-embodiment.md`, `docs/cross-target-hold-report.md` (superseded), `docs/embodiment-as-capability.md`, `docs/implementation-strategy.md`, `docs/performance-optimization.md`.

**SDA**
- `docs/decisions/0013-hand-authored-surface-is-language-resolvers-only.md` — the resolver law.
- `docs/decisions/0014-admit-one-versioned-execution-graph-bootstrap-compiler.md` — one admitted bootstrap compiler, closed 2026-08-17 with self-hosting evidence.
- `docs/decisions/0008-…` (language ecosystems own providers), `0006-…` (project the API, one Node reference host).
- `docs/languages-resolver-boundary-and-projection-inventory.md` — the file-level inventory.
- `docs/handoff/semantic-execution-graph-compilation-python-csharp.md` and `…cross-target-host-gaps.md`.
- `docs/sda-common-execution-mechanics-and-deterministic-tooling-capabilities-analysis.md` — the 12-mechanic taxonomy, cross-language ownership, **C++ as the next-language extensibility test**.
- `docs/single-geometry-execution-graph-implementation-plan.md`; `docs/execution-plan-encoding-remediation-strategy-2026-08-17.md` (canonical vs realized digest).
- `docs/consumer-platform-invariants.md` (allowed origins `PROJECTED`/`ADMITTED_PLATFORM_CAPABILITY`; 13-mechanic parity).

**sda-bootstrap** — `README.md`, `bootstrap/bootstrap.manifest.json` (`languageResolver.target: node`, pinned SDA platform commit, `packageIntegrity`), `package.json` (`sdaPlatform` commit pin). This is the sealed-binary precursor and is Node-only.

**agentic-harness** — `README.md` ("one immutable package, `sda-bootstrap`, owns all process bootstrapping"), `governance/no-hand-authored-code.policy.v1.json`, `features/detect-hand-authored-code.feature`.

**sidefx-cli** — `src/delivery.mjs` (transport/bootstrap resolution), `AGENTS.md` (entity neutrality; the CLI owns no provider implementation).

**sidefx-database** — `docs/intent.md`, `docs/scenario-embodiment.md` (connection/query runner only; its `sql/` is not on the estate invocation path).

---

## Explicit "not found" gaps

1. `sidefx-database` is **not** a git repo at the stated path; it lives at `C:\lab\sidefx-database` (and has no `.git` visible in the listing). It is Node-only and supplies connection/query only.
2. **No per-language bootstrap exists** beyond Node. Python/C#/Java/Go/C++ have kernels/schedulers but **not** a frontdoor, stdin/stdout envelope, DB driver/query runner, or permission sandbox. `sda-bootstrap` is Node-only (`languageResolver.target: node`).
3. **No resolver-boundary declaration** in any `languages/*/binding/*.binding.json`.
4. **No `projected-execution-mechanic-taxonomy.v1`** authority file.
5. **No wired repository-wide K029/ADR-0013 sterility scan**; `verify-resolver-boundary-sterility` is a feature without a declared scenario in `workspace-governance/capability.json` or a provider implementation.
6. **No SEA/`postject`/native-compilation build, signing, or pre-spawn digest verification** anywhere; `sda-bootstrap` packages the Node platform but is not sealed/attested.
7. **No language-level missing-resolver gate**; only the 13-mechanic consumer-platform parity for `IMPLEMENTING` bindings.
8. **Python/C# (and go/java/cpp) have no mechanic-registry loader**; their registries are declared authority not consumed at runtime (Python/C# effect ports G7 open).
9. **`.go` is not in the sterility evaluator's executable-extension regex**; `.cpp`/`.kt`/`.swift` are (added later).
10. **Swift and Kotlin have no kernel** and are absent from graph conformance; **C++ has graph providers but no `kernel/` directory** (its binding points `kernel` at projected `generated/execution`), so its resolver boundary is undeclared/ambiguous.
11. **No cross-language acceptance corpus for schema-admission vocabulary** exists; the handoff explicitly calls this out ("There is no shared cross-language admission conformance corpus yet", `cross-target-host-gaps.md:200-201`).
12. The inventory doc's claim that C++ lacks a kernel is **stale** relative to the current tree (`language-graph-v1-conformance.json` admits cpp; `languages/cpp/graph/*` exists).
