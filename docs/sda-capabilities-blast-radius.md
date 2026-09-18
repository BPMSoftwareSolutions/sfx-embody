# SDA `capabilities/**` blast radius and declaration-homing ledger

**Status.** Recorded 2026-09-17 from a read-only inventory of the SDA repository
(`C:\lab\repos\scenario-driven-architecture`, HEAD `618a0b4`, working tree clean).
SDA was not modified. The ledger is written to the estate because agents must not
edit SDA. The inventory tree is `capabilities/**`: 2,891 files / 27,579,135 bytes
(26.3 MiB) across three trees (`sda-api`, `sda-platform`, `sda-tooling`) plus one
root `README.md`. Under the builder's rule — all meaning is declared authority
resolved at runtime, and repo-resident declared data is migration debt — the whole
tree moves to declaration; nothing in it remains repo-resident. Authority documents
become rows via the estate migration pattern; projected bodies are eliminated (no
materialization); fixtures/vectors/receipts become conformance rows or receipts;
the only executable files outside `projected/**` are six `.ts` carrier fixtures,
which are conformance data, not resolver code.

Authorities applied: estate `docs/transistor-model.md` (resolver(0) vs declared(1),
no third state), estate `docs/target-architecture.md` (no materialization; the only
code is the irreducible three + boot config; composition is `invoke-scenario` with
mapped contracts), estate `docs/sda-tools-uid-homing.md` (methods, evidence legend,
agent-ready unit shape). SDA was the read-only subject; all writes land in the
estate.

Citation roots: this doc is in `sfx-embody`; `SDA:` resolves to
`C:\lab\repos\scenario-driven-architecture`; `DB:` to `C:\lab\sidefx-database`;
sibling estate repos are `sidefx-cli`, `sidefx-database`.

---

## 1. Method

- Enumerated every file under `SDA:capabilities/**` (path, extension, bytes) and
  classified each into the builder's categories by path/name, with residual
  categories resolved by inspection.
- Grepped every reference to `capabilities/` and to `capabilities/sda-*` across
  SDA outside the tree (408 and 206 hits respectively), then separated true
  tree references from false positives: relative imports `../../capabilities/...`
  resolve to `tools/src/capabilities/**` (the tooling capability sources), not
  the repository tree, and are excluded.
- Grepped the three consuming repos for `capabilities/` and capability directory
  names.
- Traced the seven `providerAuthorityRef` paths to their resolvers and decided,
  per resolver, whether resolution happens at runtime or only in tools/conformance.

**Edge classes used in this ledger**, per the request:

| Class | Meaning |
|---|---|
| declared-data ref | a path string inside declared authority (catalog, contract, governance policy) |
| tooling authoring | a tool reads/writes capability files as data (projection, digest, publish) |
| test fixture | a test reads capability files as its input corpus |
| execution | executable code imports or loads a capability file at run time |

---

## 2. Inventory

### 2.1 Tree shape

| Tree | Top-level dirs | Shape |
|---|---:|---|
| `sda-api` | 2 capabilities + `catalog.json` | 2 capability declarations + one catalog |
| `sda-platform` | 40 capabilities | heterogeneous: 3 carry the full 8-authority set + `projected/`; most are authority+contracts+feature packages; `kernel-decomposition` carries 2 candidate trees (194 files / 4.1 MB) |
| `sda-tooling` | 11 domains + `projected-tools/` (48 tools) + `catalog.json` | 11 hand-authored tooling capability packages (capability.json + observation-bindings + provider-bindings + contracts + features); 48 projected tools each with the 8-authority set + `projected/**` |

Extension census (whole tree): `.json` 2,134 (26,830,738 B); `.mjs` 220 (54,736 B);
`.feature` 162 (315,378 B); `.cs` 110 (75,532 B); `.csproj` 104 (98,679 B);
`.props` 53 (107,641 B); `.py` 51 (7,191 B); `.md` 21; `.source` 16; `.cache` 8;
`.ts` 6 (43,670 B); `.editorconfig` 2; `.base64` 2; `.targets` 2.

### 2.2 Category matrix per tree (files / bytes)

| Category | `sda-api` | `sda-platform` | `sda-tooling` | Total |
|---|---:|---:|---:|---:|
| declared capability authorities (`capability*.json`, `catalog.json`, `contract-catalog.json`, `feature-capabilities.json`) | 3 / 14,539 | 8 / 23,653 | 61 / 118,315 | 72 / 156,507 |
| declared contract authorities (`contracts/**`, `*.schema.json`) | - | 154 / 375,752 | 279 / 268,513 | 433 / 644,265 |
| declared execution authorities (`execution-authorities`, `semantic-graph`, `semantic-transformation`, `projection-authorities`, `consumer-workspace`, acceptance/scope authorities) | - | 32 / 347,763 | 245 / 167,887 | 277 / 515,650 |
| declared provider/resolver authorities (`provider-bindings`, `observation-bindings`, `*.authority.json`, `provider-registry*`, `native-binding-requirements`) | - | 34 / 147,158 | 22 / 35,320 | 56 / 182,478 |
| declared fixture authorities (`fixtures.authority.json`) | - | 6 / 108,828 | 49 / 345,053 | 55 / 453,881 |
| other declared data (interface authorities, profiles, policies, identities, language models, kernel-decomposition inventory/candidates) | - | 6 / 25,171 | 49 / 36,603 | 55 / 61,774 |
| features (`*.feature`, `features/**`) | - | 69 / 162,302 | 93 / 153,076 | 162 / 315,378 |
| fixtures / vectors (non-projected `fixtures/**`, `*.fixture*`) | - | 91 / 151,421 | - | 91 / 151,421 |
| conformance receipts (non-projected `*evidence*`, `*receipt*`, `*conformance*`) | - | 12 / 50,305 | 1 / 14,224 | 13 / 64,529 |
| projection sterility receipts (`projected/projection-conformance.json`) | - | 6 / 2,880 | 49 / 23,520 | 55 / 26,400 |
| projected bodies: csharp | - | 15 / 15,789 | 240 / 252,414 | 255 / 268,203 |
| projected bodies: node | - | 24 / 5,926 | 196 / 48,810 | 220 / 54,736 |
| projected bodies: python | - | 3 / 423 | 48 / 6,768 | 51 / 7,191 |
| projected bodies: wpf | - | 30 / 439,845 | - | 30 / 439,845 |
| projected data (plans, query, scenarios, telemetry, fixtures, bindings, manifests, transitions) | - | 146 / 6,326,271 | 877 / 17,815,337 | 1,023 / 24,141,608 |
| other residual data (identity/model/profile JSON) | - | 22 / 72,200 | - | 22 / 72,200 |
| README/docs | 1 (root) / 1,844 | 20 / 21,225 | - | 21 / 23,069 |
| **Tree total** | **3 / 14,539** | **678 / 8,276,912** | **2,209 / 19,285,840** | **2,891 / 27,579,135** |

Notes:

- `sda-platform` has 40 capabilities; `sda-api` has 2; `sda-tooling` has 11
  hand-authored domains + 48 projected tools. `projected-tools/` is 1,988 files /
  18,898,541 B, i.e. 98% of `sda-tooling` bytes.
- The wpf body count (30) includes 24 build-residue files under
  `projected/wpf/obj/**` and `projected/wpf/proof/obj/**` (12 project.assets /
  nuget / Debug files each); only 6 files are authored projections
  (`ProjectedSemanticElementRealization.generated.cs/.csproj`,
  `projection-manifest.json`, `proof/NativeEquivalenceProof.generated.csproj`,
  `proof/Program.generated.cs`, `proof/fixtures/all-semantic-kinds.ui-embodiment-plan.v1.json`).
- Projected data is dominated by `projected/query/**` (424 files / 19,119,680 B;
  `conformance-query*.json` alone is ~16.2 MB), then `execution-plans/**`
  (58 / 3,448,703 B), `scenarios/**` (86), `telemetry/expected-trace.json` (55),
  `fixtures/fixtures.json` (55), `application-binding*` (116), `projection-manifest.json`
  (55), projected `capability.json` (55), `transitions/**` (23).
- Largest capability directories: `sda-platform/kernel-decomposition`
  (194 / 4,079,668), `sda-platform/semantic-corpus-artifact-repository`
  (60 / 1,768,522), `sda-platform/project-presentation-capabilities`
  (81 / 871,387), `sda-tooling/projected-tools/construct-consumer-projection-plan`
  (81 / 745,810), `sda-platform/semantic-corpus-derivation` (34 / 572,562).

### 2.3 Executable code outside `projected/**` — complete list

The tree contains **no** `.mjs`, `.py`, `.cs`, `.js`, or `.cjs` outside
`projected/**`. Every one of the 220 `.mjs`, 51 `.py`, and 110 `.cs` files is a
projected body. The only executable files outside `projected/**` are the six
`.ts` carrier fixtures (all under `sda-platform`, all test fixtures):

| File | Bytes | Use |
|---|---:|---|
| `SDA:capabilities/sda-platform/verify-scenario-semantic-carrier-extraction-conformance/fixtures/valid-extractor.carrier.ts` | 6,759 | test fixture |
| `SDA:capabilities/sda-platform/verify-scenario-semantic-carrier-extraction-conformance/fixtures/valid-managed-extractor.carrier.ts` | 13,211 | test fixture |
| `SDA:capabilities/sda-platform/verify-scenario-semantic-carrier-validation-conformance/fixtures/hidden-meaning.carrier.ts` | 1,890 | test fixture |
| `SDA:capabilities/sda-platform/verify-scenario-semantic-carrier-validation-conformance/fixtures/unresolved-identity.carrier.ts` | 1,604 | test fixture |
| `SDA:capabilities/sda-platform/verify-scenario-semantic-carrier-validation-conformance/fixtures/valid-managed-validator.carrier.ts` | 13,211 | test fixture |
| `SDA:capabilities/sda-platform/verify-scenario-semantic-carrier-validation-conformance/fixtures/valid-validator.carrier.ts` | 6,995 | test fixture |

These are conformance vectors (declared data), not resolver bodies. No file in
the tree is resolver(0) code; the resolver bodies they exercise live in
`SDA:languages/**`.

---

## 3. Dependency edges (exact `file:line`, by consumer)

### 3.1 SDA kernel authority refs (declared-data)

`SDA:kernel/semantic-authority/consumer/sda-platform-capabilities.semantic-authority.json`
carries seven provider-authority entries:

| Line | `capabilityId` | `providerAuthorityRef` target |
|---:|---|---|
| 121 | `sda-json-authority-ingestion-port.v1` | `capabilities/sda-platform/bind-profile-governed-json-authority-ingestion/profile-governed-json-authority-ingestor.authority.json` |
| 142 | `sda-proof-binding-evaluation-port.v1` | `capabilities/sda-platform/bind-profile-governed-proof-binding-evaluation/profile-governed-proof-binding-evaluator.authority.json` |
| 165 | `sda-scenario-semantic-carrier-validation-port.v1` | `capabilities/sda-platform/bind-scenario-semantic-carrier-validation/scenario-semantic-carrier-validator.authority.json` |
| 188 | `sda-scenario-semantic-carrier-extraction-port.v1` | `capabilities/sda-platform/bind-scenario-semantic-carrier-extraction/scenario-semantic-carrier-extractor.authority.json` |
| 209 | `sda-scenario-semantic-carrier-evaluation-port.v1` | `capabilities/sda-platform/bind-scenario-semantic-carrier-evaluation/scenario-semantic-carrier-evaluator.authority.json` |
| 228 | `sda-semantic-vector-index.v1` | `capabilities/sda-platform/bind-deterministic-semantic-vector-index/deterministic-semantic-vector-indexer.authority.json` |
| 246 | `sda-os-environment-credential-port.v1` | `capabilities/sda-platform/verify-os-environment-credential-conformance/conformance/os-environment-credential-conformance.v1.json` |

Each entry also pins `providerAuthorityDigest` and `conformanceDigest`.

**Who resolves these seven refs** (grep of `providerAuthorityRef` resolvers):

- *Runtime readers (file-based; only when an invocation configuration carries the
  ref):*
  - `SDA:languages/typescript/runtimes/node/json-authority-ingestion-provider.mjs:695,697,740-742` (`readBoundAuthority`, ref+digest required)
  - `SDA:languages/typescript/runtimes/node/proof-binding-evaluation-provider.mjs:271`
  - `SDA:languages/typescript/runtimes/node/semantic-carrier-evaluator-provider.mjs:140`
  - `SDA:languages/typescript/runtimes/node/semantic-carrier-extractor-provider.mjs:250-262,270`
  - `SDA:languages/typescript/runtimes/node/semantic-carrier-validator/index.mjs:62`
  - `SDA:languages/typescript/runtimes/node/semantic-vector-index-provider.mjs:56,186-189`
  - These require `file:` URLs and `fs.readFileSync` (`SEMANTIC_CARRIER_EXTRACTOR_PROVIDER_AUTHORITY_LOCAL_FILE_REQUIRED`). No invocation configuration in current rows or published plans carries the refs (verified: zero `providerAuthorityRef` in `sfx-embody/providers/*/projected/execution-plans/**` and `projected/node/**`); they appear only in published `projected/query/conformance-query*.json` bundles and in tests. Resolution is therefore **tools/conformance only today**.
- *Authoring writers (patch) — the only writers of the seven files and of the
  catalog digests:*
  - `SDA:tools/project-semantic-carrier-extractor-provider-authority.mjs:7-8,317-333` reads; `:345,355,365` writes authority/conformance/catalog
  - `SDA:tools/project-semantic-carrier-evaluator-provider-authority.mjs:7-8,315-318`; `:328,333,339` writes
  - `SDA:tools/project-semantic-carrier-managed-v3-provider-authority.mjs:9-10,213`; writes from `:47`
- *Kernel-catalog readers (declared-data):*
  - `SDA:tools/src/adapters/consumer-projection/node-consumer-assurance-repository.ts:32`
  - `SDA:tools/src/adapters/consumer-projection/node-consumer-workspace-repository.ts:205`
  - `SDA:tools/src/consumer-projection/application/consumer-assurance-service.ts:88`
  - `SDA:examples/generic-capability/consumer-workspace.authority.json:16` (`platformCapabilityCatalog`)
  - `SDA:tools/tests/consumer-projection/platform-capability-admission.test.js:15`; `SDA:tools/tests/consumer-projection/cross-apply-proof-profile.test.js:104`
  - `SDA:languages/typescript/runtimes/node/governed-external-root-batch-materialization-port.conformance.test.mjs:91`; `SDA:languages/typescript/runtimes/node/governed-file-system-shaping-port.conformance.test.mjs:73`
- *Conformance test readers of the seven files:* sections 3.5 and 3.7.

### 3.2 Root `package.json` scripts

| Line | Script | Reference | Class |
|---:|---|---|---|
| 7 | `test` | `capabilities/resolve-admitted-market-facts/...`, `resolve-strategic-market-signals`, `detect-established-strategic-market-patterns`, `decode-physical-capability-capsule` projected test paths | **already broken** — none of those four directories exist under `capabilities/`; `npm test` fails before this work |
| 19 | `test:projected-wpf-semantic-element-realization` | `capabilities/sda-platform/project-presentation-capabilities/project-semantic-element-realization/projected/wpf/proof/NativeEquivalenceProof.generated.csproj` | execution (dotnet run) |
| 21 | `test:projected-avalonia-semantic-element-realization` | `.../projected/avalonia/proof/NativeEquivalenceProof.generated.csproj` | **already broken** — `projected/avalonia/` does not exist |

### 3.3 SDA `tools/**` — readers that affect CLI/tooling behavior

| File:line | What it reads | Class |
|---|---|---|
| `SDA:tools/cli/sda.js:306` | `capabilities/sda-tooling/catalog.json` (`sda capability-catalog`) | tooling authoring |
| `SDA:tools/src/conformance/application/conformance-service.ts:91` | `capabilities/sda-tooling/<capabilityId>/capability.json` scenarios (drives `sda observe-conformance`, `sda implementation-admission`) | execution |
| `SDA:tools/src/consumer-projection/application/consumer-assurance-service.ts:271` | `capabilities/sda-tooling/consumer-assurance/capability.json` scenarios | execution |
| `SDA:tools/src/consumer-projection/application/consumer-capability-compiler.ts:67` | `capabilities/sda-tooling/consumer-capability-compilation/capability.json` scenarios | execution |
| `SDA:tools/src/interfaces/execution-vector-projection/run.ts:52` | `capabilities/sda-tooling/execution-vector-projection/capability.json` | execution |
| `SDA:tools/src/interfaces/structural-model-projection/run.ts:53` | `capabilities/sda-tooling/structural-model-projection/capability.json` | execution |
| `SDA:tools/src/interfaces/workspace-placement-verification/run.ts:26` | `capabilities/sda-tooling/workspace-governance/capability.json` | execution |
| `SDA:tools/src/interfaces/language-declaration-admission/run.ts:26` | `capabilities/sda-tooling/workspace-governance/capability.json` | execution |
| `SDA:tools/src/enterprise/interfaces/http/node-api-reference-host.ts:387,421` | `capabilities/sda-tooling/api-interface-projection/contracts` | execution |
| `SDA:tools/src/gherkin/application/canonical-gherkin-compiler.ts:105,106,108` | grammar/compiler/profile authority paths | execution |
| `SDA:tools/src/gherkin/application/canonical-gherkin-compiler.ts:137` | existence probe of `<root>/capabilities/sda-platform` | execution |
| `SDA:tools/src/ui-parity/application/ui-parity-projector.ts:140-142` | `ui-embodiment/feature-capabilities.json`, `ui-presentation-protocol/protocol.identity.json`, `provider-registry.json` | execution |
| `SDA:tools/src/ui-parity/application/ui-presentation-compiler.ts:8` | `capabilities/sda-platform/ui-presentation-protocol` root | execution |
| `SDA:tools/src/ui-parity/application/ui-protocol-language-model-generator.ts:6` | same root | execution |
| `SDA:tools/src/adapters/ui-parity/node-ui-embodiment-provider-registry.ts:13` | same root | execution |
| `SDA:tools/src/ui-presentation/application/ui-protocol-binding-generator.ts:83,84` | `generate-ui-protocol-bindings/ui-protocol-binding-model.v1.json`, `ui-presentation-protocol/successor.identity.json` | execution |
| `SDA:tools/src/adapters/consumer-projection/consumer-platform-input-digest.ts:32-33` | digest inputs: `capabilities/sda-tooling/consumer-capability-compilation`, `capabilities/sda-tooling/consumer-assurance` | tooling authoring (digest) |
| `SDA:tools/src/capabilities/workspace-governance/admit-language-declaration/provider.ts:4` | **imports** `capabilities/sda-tooling/projected-tools/admit-language-declaration/projected/node/capability-runtime.generated.mjs` (`executeCapability`) | execution |
| `SDA:tools/src/adapters/conformance/admission-input-digest.cts:8` | admission digest walks `capabilities/sda-tooling/{catalog.json,workspace-governance,kernel-implementation-admission,conformance-evidence-publication}` | tooling authoring (digest) |

### 3.4 SDA `tools/**` — authoring/materialization writers (patch)

| File:line | Writes into the tree | Class |
|---|---|---|
| `SDA:tools/project-semantic-carrier-extractor-provider-authority.mjs:62-283,345-365` | `bind-scenario-semantic-carrier-extraction/**`, `verify-scenario-semantic-carrier-extraction-conformance/**`, kernel catalog/registry | tooling authoring (write) |
| `SDA:tools/project-semantic-carrier-evaluator-provider-authority.mjs:68-339` | `bind-scenario-semantic-carrier-evaluation/**`, `verify-...-evaluation-conformance/**`, kernel catalog/registry | tooling authoring (write) |
| `SDA:tools/project-semantic-carrier-managed-v3-provider-authority.mjs:41-47,213` | `bind-scenario-semantic-carrier-validation/**` managed authority + kernel catalog | tooling authoring (write) |
| `SDA:tools/scripts/project-native-semantic-element-realization.mjs:7,183` | writes `project-presentation-capabilities/.../projected/wpf/**` (dotnet materialization) | tooling authoring (write; eliminated by target-architecture) |
| `SDA:tools/scripts/project-native-avalonia-semantic-element-realization.mjs:7,174` | same for `projected/avalonia/**` (target missing; script already broken) | tooling authoring (write; eliminated) |

### 3.5 SDA `tools/tests/**` — test-fixture readers (path roots and key refs)

All are `test fixture` class. Line lists are exhaustive for true tree references
(relative `../../capabilities/**` imports into `tools/src/capabilities/**` are
excluded).

- `tools/tests/conformance/proof-binding-evaluation.test.js:17-22,75,278,282,286,318-319`
- `tools/tests/conformance/scenario-semantic-carrier-extraction.test.js:19-20,61,79-80,129-130,133`
- `tools/tests/conformance/scenario-semantic-carrier-validation.test.js:20,23-30,240-241`
- `tools/tests/conformance/scenario-semantic-carrier-evaluation.test.js:14-15,129-130`
- `tools/tests/conformance/json-authority-ingestion.test.js:17-19,135,211-213,269-270`
- `tools/tests/conformance/gherkin-semantic-ingestion.test.js:11-15,90,129,134`
- `tools/tests/conformance/semantic-vector-index.test.js:17,22`
- `tools/tests/conformance/os-environment-credential.test.js:14-15`
- `tools/tests/conformance/durable-store-mechanic-admission.test.js:17-18`
- `tools/tests/conformance/capability-authority.test.js:10,37`
- `tools/tests/conformance/implementation-admission.test.js:47,89,161`
- `tools/tests/conformance/provider-binding-runtime.test.js:15,20,31,43,55`
- `tools/tests/conformance/legacy-ui-compatibility.test.js:9-10,105`
- `tools/tests/conformance/presentation-capability-ownership.test.js:10,16,18`
- `tools/tests/conformance/resolve-declared-ui-presentation.test.js:9`
- `tools/tests/conformance/semantic-presentation-compiler.test.js:9-11`
- `tools/tests/conformance/ui-csharp-embodiment-v3.test.js:9,20,22,24,30,34-35,56,67-68,77`
- `tools/tests/conformance/ui-reference-embodiment-v3.test.js:9,24,26-27,37-39,154`
- `tools/tests/conformance/ui-embodiment-planning.test.js:9-13`
- `tools/tests/conformance/ui-presentation-ir-v3-design.test.js:9,19-20,61,93`
- `tools/tests/conformance/ui-protocol-bindings-v3.test.js:9`
- `tools/tests/consumer-projection/platform-capability-admission.test.js:15,36-37,47-48,82,90,115,136,151,164,178,198`
- `tools/tests/consumer-projection/ui-presentation-protocol.test.js:9,41-44`
- `tools/tests/consumer-projection/ui-feature-admission.test.js:14,17`
- `tools/tests/consumer-projection/cross-apply-proof-profile.test.js:104`
- `tools/tests/consumer-projection/execution-embodiment-plan.test.js:31`
- `tools/tests/consumer-projection/deterministic-regeneration.test.js:90`
- `tools/tests/consumer-projection/source-observation-provider.test.js:10`
- `tools/tests/consumer-projection/ui-parity-foundation.test.js:348,378,380`
- `tools/tests/semantic-execution-graph.test.js:145,164`
- `tools/tests/api-interface-projection.test.js:11,22-23,45,115`
- `tools/tests/openapi-projection.test.js:11,21-23`
- `tools/tests/execution-api-reference-host.test.js:12,30,98,284-285`
- `tools/tests/realization-api-reference-host.test.js:12-13,27-28,240-241`
- `tools/tests/realization-planning-capability.test.js:11,19-21`
- `tools/tests/file-backed-realization-planning.test.js:13,32`
- `tools/tests/realization-lifecycle-contracts.test.js:12,26`
- `tools/tests/registry-backed-realization-planning.test.js:12,22,24`
- `tools/tests/structural-model-projection-capability.test.js:19`
- `tools/tests/authority-conformance-capability.test.js:19,25`
- `tools/tests/workspace-placement-verification-capability.test.js:18-19`
- `tools/tests/language-declaration-admission-capability.test.js:19-20`
- `tools/tests/enterprise-execution-platform.test.js:106`
- `tools/tests/ui-change-amplification.test.js:42`
- `tools/tests/architecture-boundaries.test.js` — no tree ref (its `capabilities` root is `tools/src/capabilities`)

### 3.6 SDA top-level `conformance/**`, `interfaces/**`, `governance/**`, repo config

- `SDA:conformance/**`: **zero** references to `capabilities/`. The top-level
  conformance tree does not depend on the capability tree.
- `SDA:interfaces/sda-api/contract-catalog.json:4-16` — 13 `schemaRef` entries
  into `capabilities/sda-tooling/api-interface-projection/contracts/*.schema.json`
  (declared-data ref).
- `SDA:interfaces/sda-api/projection-fixture.json:8-9` — references
  `capabilities/sda-api/{execution-resource,realization-resource}/capability.json`
  (declared-data ref).
- `SDA:governance/ui/change-amplification-policy.json:7-8,47,52,63` — path
  prefixes over `capabilities/sda-platform/{ui-embodiment,ui-presentation-protocol,ui-recipes}`
  (declared-data ref; governs allowed changes).
- `SDA:governance/ui/sda-ui-presentation-ir-v2.freeze.json:5,9` — schema/protocol
  identity refs (declared-data ref).
- `SDA:governance/admitted-bootstrap-compiler.policy.v1.json:14,18` —
  `closureEvidence` and `successorRoot` point at
  `capabilities/sda-tooling/projected-tools/compile-semantic-execution-graph`
  (declared-data ref; the bootstrap compiler admission policy).
- `SDA:.gitattributes:13,17,32-44,51-52,58-59,66-67,74-75,80-83` — 27 line-ending
  rules over the tree (repo config; no semantic dependency).
- `SDA:README.md:45,52` and 37 docs lines in `SDA:docs/**` — documentation only.

### 3.7 SDA `languages/**` — the two kernel-runtime test edges

- `SDA:languages/csharp/tests/ScenarioKernel.ConformanceTests/SemanticContractCatalogAdmissionTests.cs:13`
  reads `capabilities/sda-platform/semantic-corpus-artifact-repository/projected/execution-plans/consumer-execution-plan.node.v3.json`.
- `SDA:languages/python/tests/conformance/test_platform_adapters.py:129` reads the
  same projected plan.

These are the only `capabilities/**` reads inside `languages/**`. Both are test
fixtures; no kernel resolver reads the tree on the invocation path.

### 3.8 Other repos

**estate `sfx-embody` (HEAD `1f941b6`)** — 231 matching lines / 33 files:

| Surface | Evidence | Class |
|---|---|---|
| Published provider bundles | 14 files: `providers/{obtain-governed-model-response,project-governed-http-request-body,project-model-provider-protocol,observe-governed-http-exchange,bind-external-credential-reference,execute-governed-model-invocation,execute-projected-model-provider-attempt}/projected/query/conformance-query{,.node}.json` embed all seven `providerAuthorityRef` paths (e.g. `providers/obtain-governed-model-response/projected/query/conformance-query.json:2777,2798,2821,2844,2865,2884,2902`) | declared-data ref (published projected body; eliminated under no-materialization) |
| Plan execution edge | `providers/obtain-governed-model-response/projected/execution-plans/consumer-execution-plan.node.v3.json:15333,15388` and `providers/obtain-governed-model-response/projected/node/execution-operations.json:2545,2586` carry `bindingRef: ../../../../scenario-driven-architecture/capabilities/sda-platform/bind-os-environment-credential/projected/application-binding.node.json`; also `.../projected/query/conformance-query.json:942,961` | **execution** (node kernel loads it via `bindingRef`) |
| DB rows | `sql/migrations/restore-provider-fixture-input-order.sql:45,65,66,86,87` embed `providerAuthorityRef` and `conformanceReceiptRef` for json-authority and proof-binding ports | declared-data ref (paths as row data; not dereferenced by the transformation) |
| Frozen baselines / embodiments | `baselines/**/authority-bundle.json`, `second-root-authority-bundle.json`, `third-authority-bundle.json`, `embodiments/**` (source_path refs), `docs/research/canonical-feature-migration/review-20260911.json` | declared-data ref (frozen copies; already eliminated artifacts) |
| Build residue | `build/circuit-repair/finance-circuit.json`, `finance-graph.json` | declared-data ref (build artifact) |
| Config | `config/regression.cases.json:3`, `config/database-runtime.json:4` — `sdaRoot` only (not capability paths) | boot config (resolver(0)) |

**`sidefx-cli` (HEAD `20908da`)** — zero references to the SDA capability tree;
its grep hits are links to SDA docs and to `agentic-harness/authority/**`.
Unaffected.

**`sidefx-database` (HEAD `ae83812`)** — 11 files use `capabilities/<capabilityId>/...`
as the **capsule entry convention**, not as live reads of the SDA tree:
`src/derive/project.mjs:43`; `src/register/pack.mjs:53-57`;
`src/migration/platform.mjs:48-51`; `src/migration/complete.mjs:80`;
`sql/experiments/run-and-capture.mjs:48-62`;
`sql/experiments/remove-overhead-and-scaffold-hello-world.sql:226-351`;
`test/projection.test.mjs:8,20,56,58`; docs `docs/first-snapshot.md:63-64`,
`docs/physical-data-model-review.md:83`, `docs/data-architecture-strategy.md:607`.
This is the estate migration pattern that the move reuses: rows carry
`source_path = capabilities/<capabilityId>/<entry>`. After the move, `source_path`
identities come from rows (or the convention changes to a capsule/row locator);
no sidefx-database code needs the SDA tree present.

---

## 4. Blast radius

### 4.1 Per consumer group

| Consumer group | What breaks when the paths disappear | First move required |
|---|---|---|
| SDA kernel authority (`kernel/semantic-authority/consumer/sda-platform-capabilities.semantic-authority.json`) | The seven refs become dangling strings. Nothing fails at invocation today because no configuration carries them, but the catalog's digests and the three writer scripts break. | Kernel catalog must be re-homed to rows together with its writer scripts (CB2), or the refs stay until a kernel change makes them row identities (K1). |
| SDA tools authoring/execution | `sda capability-catalog`, `sda observe-conformance`, `sda implementation-admission`, `sda structural-model-projection`, `sda execution-vector-projection`, `sda workspace-placement-verification`, `sda language-declaration-admission`, consumer projection/assurance, gherkin compile, ui-parity projection, enterprise API host, protocol binding generation: all fail at path read (`ENOENT`) or silently change output. | Tools must read declared rows (CB3) or be deleted as part of their own homing (sda-tools-uid-homing M2/M3/M5/M7). The three carrier authoring scripts must be replaced by declared authoring first. |
| Root `package.json` scripts | Not a regression: `test` (line 7) and the avalonia proof (line 21) are already broken. The wpf proof (line 19) breaks when `projected/wpf/**` is deleted (CB4), which is the intended disposition. | Fix or delete the stale scripts as part of CB6. |
| SDA conformance tests | 45+ files under `tools/tests/**` plus 2 `languages/**` tests read capability paths; every one fails or loses its corpus. The admission digest changes for every language because it hashes capability directories. | Tests are themselves no-home debt (sda-tools-uid-homing F6); each subject is homed declared(1) (vectors/receipts), resolver(0) (admitted harness), or deleted (CB5). |
| SDA top-level `interfaces/`, `governance/` | `interfaces/sda-api/contract-catalog.json` schema digests dangle; `governance/ui/*` prefixes and the bootstrap-compiler policy point at missing paths; change-amplification policy may reject or mis-scope changes. | Re-declare these references against row identities; align the policy prefix list with the post-move tree (CB6). |
| Estate `sfx-embody` | The node runtime loads projected application bindings through `bindingRef` when invoking `obtain-governed-model-response` plans; that invocation breaks when `capabilities/.../projected/application-binding.node.json` is deleted. Published `conformance-query*.json` bundles carry the seven refs as data. DB rows carry path strings (data defect only). | Estate published bundles and baselines are already elimination targets; the bindingRef mechanics must be replaced by declared `invoke-scenario` composition (K2) before the projected tree is deleted. DB rows must be re-declared with row identities (CB7). |
| `sidefx-cli` | Nothing. | None. |
| `sidefx-database` | Nothing live; only the capsule `source_path` convention overlaps. | None (pattern change lands with CB1). |

### 4.2 The seven `providerAuthorityRef` refs — precise resolution

- **Authoring (read + write):** only
  `SDA:tools/project-semantic-carrier-{extractor,evaluator,managed-v3}-provider-authority.mjs`.
  They rebuild the referenced authority files, their conformance receipts, and the
  kernel catalog entry, and they rewrite the digest of
  `languages/typescript/runtimes/node/node-mechanic-registry-loader.mjs` into every
  dependent provider authority closure. There is no other writer.
- **Runtime (read):** only if an invocation configuration supplies
  `providerAuthorityRef` + `providerAuthorityDigest`. The node providers require a
  local `file:` and digest-verify the bytes. Current declared rows and published
  execution plans do not supply them; the values exist in the published
  `conformance-query*.json` bundles and in DB rows as data.
- **Conformance (read):** the seven `tools/tests/conformance/*.test.js` files and
  the kernel-catalog list in section 3.1.
- Therefore the seven refs are resolved **only in tools/conformance (and by the
  authoring scripts) today**, with a latent runtime path that activates if a
  declaration ever carries the ref. Moving the files to rows requires the kernel
  to accept row/declared-read authority (K1) so that latent path cannot become a
  `LOCAL_FILE_REQUIRED` failure.

### 4.3 Five largest blast-radius edges

1. **Estate runtime `bindingRef` into a projected application binding** —
   `sfx-embody/providers/obtain-governed-model-response/projected/execution-plans/consumer-execution-plan.node.v3.json:15333,15388`
   (and `projected/node/execution-operations.json:2545,2586`), resolved by
   `SDA:languages/typescript/runtimes/node/admitted-consumer-platform.mjs:27-35`
   and `node-mechanic-registry-loader.mjs:305,337-345`. Deleting
   `capabilities/sda-platform/bind-os-environment-credential/projected/application-binding.node.json`
   breaks that invocation; it is the only live execution edge into the tree.
2. **Tool execution import** —
   `SDA:tools/src/capabilities/workspace-governance/admit-language-declaration/provider.ts:4`
   statically imports
   `capabilities/sda-tooling/projected-tools/admit-language-declaration/projected/node/capability-runtime.generated.mjs`.
   Module load fails the moment the tree moves; language-declaration admission and
   every command that reaches it break.
3. **Repository-wide admission digests** —
   `SDA:tools/src/adapters/conformance/admission-input-digest.cts:8` hashes
   `capabilities/sda-tooling/{catalog.json,workspace-governance,kernel-implementation-admission,conformance-evidence-publication}`;
   `SDA:tools/src/adapters/consumer-projection/consumer-platform-input-digest.ts:32-33`
   hashes `consumer-capability-compilation` and `consumer-assurance`. Moving or
   deleting the tree invalidates every implementation-admission and consumer
   platform digest.
4. **Consumer projection/compilation and conformance scenario reads** —
   `SDA:tools/src/consumer-projection/application/consumer-assurance-service.ts:271`,
   `SDA:tools/src/consumer-projection/application/consumer-capability-compiler.ts:67`,
   `SDA:tools/src/conformance/application/conformance-service.ts:91` read
   `capabilities/sda-tooling/<id>/capability.json` for scenario declarations at
   execution time. The whole `sda` tool host fails closed.
5. **Kernel catalog continuity** —
   `SDA:kernel/semantic-authority/consumer/sda-platform-capabilities.semantic-authority.json:121-246`
   plus the three writer scripts. If the authority files move without K1, the
   catalog's `providerAuthorityRef`/digest fields are dangling, and the only code
   that can maintain them (the writer scripts) is gone.

Runners-up: `SDA:tools/cli/sda.js:306` (`sda capability-catalog`);
`SDA:package.json:7` (already broken); the 19.1 MB `projected/query/**` bundles
(large but low semantic blast — published data superseded by declared queries).

### 4.4 Who must be homed/replaced first

1. The three carrier authoring scripts (only writers of the seven authorities and
   the kernel catalog digests) — replace with declared authoring rows.
2. The consumer projection and conformance path readers in `tools/src/**` — these
   are simultaneously the consumers and the sda-tools-uid-homing debt (M2/M3/M5/M7).
3. The admission/consumer digest functions — re-point at row identities before any
   file moves so digests change once, deliberately.
4. The kernel catalog/provider-authority resolution — K1.
5. The estate `bindingRef` composition — replaced by declared `invoke-scenario`
   composition (K2), then delete published bundles.
Then the tree can be deleted.

---

## 5. Migration strategy — ordered units (agent-ready)

Format follows `SDA:docs/sda-tools-uid-homing.md` §8. Each unit lands coordinated
changes plus its proof. Invocation (or the named acceptance) is the proof. Agents
never edit SDA; SDA changes are change requests.

### CB0 — Baseline manifest and freeze (no move yet)

- **Scope.** All 2,891 files under `SDA:capabilities/**`; the writer scripts; the
  seven kernel refs; the tools/estate readers listed in §3.
- **Replacement.** None (gate). Produce a digest manifest keyed by
  `capabilityId/entryId` so row migration can be proven byte-equivalent.
- **Acceptance.** Manifest covers every file; `git grep` proves the three
  `project-semantic-carrier-*` scripts are the only writers into the tree; no new
  hand-authored file lands under `capabilities/**` (freeze).
- **Verification.** Recompute the manifest from the frozen commit; run the current
  `npm run test:kernel` to record the pre-move green/red baseline (line 7 `npm test`
  is already red and is not a gate).

### CB1 — Authority documents become rows (estate migration pattern)

- **Scope.** 948 JSON declared-authority files: 72 capability/catalog authorities,
  162 features, 433 contract schemas, 277 execution authorities, 56 provider
  authorities, 55 fixture authorities, 55 other declared data; plus
  `sda-tooling/catalog.json` and `sda-api/catalog.json`.
- **Replacement rows.** Estate migration pattern (`sidefx-database` capsule
  convention reused as a starting point): one row per entry keyed by
  `(capabilityId, entryId, kind, version)` with canonical bytes + digest, feature
  text, contract schemas, execution/provider authorities. Authority identity moves
  from path to row identity; `source_path` becomes an ingestion locator, not a
  runtime path. Contracts become schema rows in the same catalog used by
  `declared-json-schema-authority`.
- **Acceptance.** Every authority digest in the CB0 manifest is resolvable from
  rows by identity; no reader needs the file path; features resolve by capability
  identity.
- **Verification.** Read-equivalence receipts: for each authority, row digest ==
  frozen file digest; invoke one capability per tree whose declaration is served
  from rows.

### CB2 — The seven provider authorities and kernel resolution (kernel change K1)

- **Scope.** The seven files in §3.1, their conformance receipts, and
  `SDA:kernel/semantic-authority/consumer/sda-platform-capabilities.semantic-authority.json:121-246`.
  Replace the three writer scripts with declared authoring.
- **Replacement.** Authority content served as rows/declared reads with the same
  canonical digests; the catalog's `providerAuthorityRef` becomes a row reference.
  **Kernel change (K1):** node/python/csharp providers currently require a local
  `file:` authority (`readBoundAuthority` in the node ports). The kernel must
  accept declared authority content (or a declared-read handle) plus digest, in
  process, before the files can be deleted.
- **Acceptance.** All seven capabilities invoke with authority served from rows and
  digests unchanged; no `file:` requirement survives on the path; the catalog
  resolves all seven row references.
- **Verification.** Per-language conformance for the seven ports (node today;
  python/csharp where the ports exist); digest parity of authority content; the
  writer scripts are gone.

### CB3 — Tooling re-pointing (tools must stop reading paths)

- **Scope.** Every `tools/src/**` reader in §3.3, the two `tools/scripts/project-native-*`
  materializers (delete), `tools/src/capabilities/workspace-governance/admit-language-declaration/provider.ts:4`
  (remove the projected-body import), and the digest functions in §3.6.
- **Replacement.** Declared reads against CB1 rows; compiled capability scenarios
  read from rows; admission/consumer digests keyed by row identity; the projected
  body imported at `provider.ts:4` replaced by a kernel/resolver call
  (the capability runtime is resolver(0) in `languages/**`).
- **Acceptance.** `git grep "capabilities/sda-" -- tools/src tools/scripts tools/cli`
  is empty; `sda capability-catalog`, `sda observe-conformance`,
  `sda implementation-admission`, consumer project/assure, and ui-parity commands
  pass against rows.
- **Verification.** Run the commands; digests are computed once and documented as
  the intentional new baseline.

### CB4 — Projected bodies and projected data are eliminated

- **Scope.** All `projected/**`: 556 language bodies (255 csharp, 220 node, 51
  python, 30 wpf incl. build residue) and 1,023 projected data files (plans, query
  bundles, scenarios, telemetry, fixtures projections, bindings, manifests,
  transitions), plus the wpf `obj/` and `proof/obj/` build residue.
- **Replacement.** **Nothing is provisioned or materialized.** The kernel
  interprets the declared execution graph in process (target-architecture "No
  materialization"); the per-language resolver bodies already live in
  `SDA:languages/**`; nested capability invocation becomes a declared
  `invoke-scenario` operation with mapped contracts (target-architecture
  "Composition"), replacing `bindingRef`/application-binding loading; conformance
  queries become declared reads.
- **Acceptance.** No projection plan contains a publishable database/native target
  for this tree; `git grep` finds no reader of a deleted path; invocation outcomes
  are unchanged for the capabilities whose declarations were rows all along.
- **Verification.** Invoke a representative capability end-to-end through the
  frontdoor; `sda` tools no longer emit projected files.

### CB5 — Fixtures, vectors, receipts become conformance rows or receipts

- **Scope.** 91 non-projected fixtures (incl. the six `.ts` carrier fixtures),
  13 conformance/receipt files, 55 `fixtures.authority.json`, 55 fixture-manifest
  authorities, 55 projection-sterility receipts, 16 `.source` lexeme fixtures,
  2 `.base64` files.
- **Replacement.** Fixture/vector corpora as conformance rows keyed by
  `(capabilityId, fixtureId)`; receipts retained as admission evidence rows;
  projection sterility re-computed by the (future repo-wide) sterility gate
  instead of stored per tool.
- **Acceptance.** Every fixture has a row or a receipt identity; no test reads a
  file under `capabilities/**`; carrier `.ts` fixtures resolve from rows.
- **Verification.** The conformance suites that used the fixtures run against row
  reads; sterility scan reproduces the 55 `PURE_PROJECTION_CONFORMS` dispositions.

### CB6 — Repository consumer cleanup

- **Scope.** `SDA:package.json:7,19,21`; `.gitattributes` tree rules;
  `interfaces/sda-api/contract-catalog.json:4-16`;
  `interfaces/sda-api/projection-fixture.json:8-9`;
  `governance/ui/change-amplification-policy.json` and the freeze policy;
  `governance/admitted-bootstrap-compiler.policy.v1.json:14,18`; `README.md` and
  docs references.
- **Replacement.** Delete the already-broken scripts; re-declare interface/governance
  refs against row identities; update the change-amplification prefixes; move the
  bootstrap-compiler closure evidence to its declared home.
- **Acceptance.** `git grep "capabilities/sda-"` across SDA is empty except docs
  kept deliberately as history; `npm test` no longer references missing paths.
- **Verification.** Repository grep; `npm run test:tools`.

### CB7 — Estate cleanup (published bundles, baselines, DB rows)

- **Scope.** `sfx-embody/providers/*/projected/**` (14 files carrying the seven
  refs), the `bindingRef` plan files, `baselines/**`, `embodiments/**`,
  `sql/migrations/restore-provider-fixture-input-order.sql:45,65,66,86,87` and
  any row carrying SDA file paths.
- **Replacement.** Declared `invoke-scenario` composition (K2) for the nested
  invocation; DB rows re-declared with row identities; frozen bundles deleted per
  target-architecture disposition.
- **Acceptance.** Estate invokes `obtain-governed-model-response` (and the other
  published capabilities) through the kernel without loading any SDA path; zero
  rows name `capabilities/`.
- **Verification.** `sfx capability invoke` parity against recorded outcomes;
  `sql/inspect/hand-authored-module-references.sql` returns zero; grep for
  `scenario-driven-architecture/capabilities` in `sfx-embody` returns only
  deliberate historical docs.

### CB8 — Delete the tree (only after CB1–CB7)

- **Scope.** `SDA:capabilities/**`.
- **Replacement.** None. The tree is gone; meaning lives in rows.
- **Acceptance.** Full SDA test suite green with the tree absent (or every failure
  is a documented per-language admission gap); estate invocation parity holds.
- **Verification.** `git rm -r capabilities`; `npm run build:tools && npm run test:tools`;
  estate regression run.

**Ordering constraints.** CB0 gates all. CB1 precedes CB3 (rows must exist before
readers move). CB2 is parallel to CB1 but must land before CB4 for the seven
refs. CB3 must precede CB4 (no reader may remain when paths vanish). CB4 precedes
CB6/CB7/CB8. CB7 may land with CB4 provided estate invocation parity is proven in
the same unit.

---

## 6. What cannot move without a kernel change

| # | Primitive | Why it must be kernel | Data that binds it | Evidence |
|---|---|---|---|---|
| K1 | Provider-authority resolution from declared data: the kernel accepts authority content (or a declared-read handle) plus digest instead of requiring a local `file:` authority | The seven platform ports are cross-language (node/python/csharp) and every provider currently enforces `LOCAL_FILE_REQUIRED`; moving authority to rows without a primitive makes the latent runtime path fail closed | The seven `providerAuthorityRef`/`providerAuthorityDigest` pairs (`sda-platform-capabilities.semantic-authority.json:121-246`) and the authority documents themselves | `semantic-carrier-extractor-provider.mjs:250-262`; `semantic-carrier-validator/index.mjs:62`; `semantic-vector-index-provider.mjs:56`; `json-authority-ingestion-provider.mjs:299,695-697` |
| K2 | Projected-capability composition without materialized bindings: nested invocation expressed as declared `invoke-scenario` operations with mapped contracts, replacing runtime `bindingRef` loading of projected application bindings | Composition is a kernel execution operation, not estate code; the estate's published plans currently load projected `application-binding.*.json` by path at invocation time | The estate plan configurations `bindingRef` → `capabilities/sda-platform/bind-os-environment-credential/projected/application-binding.node.json`; `capabilityAuthorityDigest`/`bindingDigest` pins | `languages/typescript/runtimes/node/node-mechanic-registry-loader.mjs:305,317-350`; `admitted-consumer-platform.mjs:27-35`; target-architecture "Composition" standard |

Everything else in the tree moves as rows, receipts, or deletion.

---

## 7. Builder decisions required

1. **`sda-platform/kernel-decomposition/candidates/**`** (194 files / 4.1 MB,
   including two full candidate capability projections under
   `candidates/{realize,verify}-sda-execution-plan-realization/`): migrate as
   authority, or delete as candidate scratch superseded by the admitted kernel?
2. **19.1 MB `projected/query/**` bundles** (424 files): under no-materialization
   they are superseded by declared queries. Delete, or retain as admission
   evidence rows?
3. **`fixtures.authority.json` / `fixture-manifest.authority*` (110 files):**
   conformance rows or receipts? They are authority documents for fixtures, which
   has no current row shape.
4. **`sda-api` + `interfaces/sda-api` split:** the 2 capability declarations and
   the 13-contract catalog live in two homes. Move both to rows together, or keep
   the interface boundary as kernel authority?
5. **Kernel catalog home:** does
   `kernel/semantic-authority/consumer/sda-platform-capabilities.semantic-authority.json`
   itself become rows (the whole catalog), or stay as kernel authority with only
   the seven content refs row-backed?
6. **Authoring destination for the three carrier writer scripts:** declared
   authoring rows invoked through the frontdoor, or an SDA tooling capability?
   (Agents may not edit SDA; this is an SDA change request either way.)
7. **Stale `package.json` scripts:** delete `test` line 7 and the avalonia proof
   line 21, or repoint them at sda-tooling tests?
8. **Six `.ts` carrier fixtures:** move to conformance receipts (recommended), or
   retain as projected-test seams once the projected bodies are gone?

---

## 8. Report

**Category counts (whole tree).** Declared capability authorities 72; feature
authorities 162; contract authorities 433; execution authorities 277; provider/
resolver authorities 56; fixture authorities 55; other declared data 55; fixtures/
vectors 91; conformance receipts 13 (+55 projection-sterility receipts); projected
bodies 556 (255 csharp, 220 node, 51 python, 30 wpf); projected data 1,023;
executable code outside `projected/**` 6 `.ts` carrier fixtures (no resolver
code); READMEs 21. Total 2,891 files / 26.3 MiB. Per tree: `sda-api` 3 / 14.5 KB;
`sda-platform` 678 / 7.9 MiB; `sda-tooling` 2,209 / 18.4 MiB.

**Five largest blast-radius edges.** (1) estate runtime `bindingRef` loading of
`capabilities/sda-platform/bind-os-environment-credential/projected/application-binding.node.json`
from published plans; (2) `tools/src/capabilities/workspace-governance/admit-language-declaration/provider.ts:4`
static import of a projected node body; (3) admission/consumer input digests
hashing `capabilities/sda-tooling/*` directories
(`admission-input-digest.cts:8`, `consumer-platform-input-digest.ts:32-33`);
(4) consumer projection and conformance scenario reads of
`capabilities/sda-tooling/<id>/capability.json` (`consumer-assurance-service.ts:271`,
`consumer-capability-compiler.ts:67`, `conformance-service.ts:91`);
(5) kernel catalog continuity for the seven `providerAuthorityRef`s with only the
three writer scripts able to maintain them.

**Ordered unit list.** CB0 baseline/freeze; CB1 authority documents → rows; CB2
seven provider authorities + kernel resolution (K1); CB3 tooling re-pointing;
CB4 projected bodies/data eliminated (no materialization replacement); CB5
fixtures/receipts → conformance rows; CB6 repo consumer cleanup; CB7 estate
cleanup (published bundles, baselines, DB path rows; K2); CB8 delete the tree.

**Builder decisions.** Candidate trees; 19.1 MB query bundles; fixture-authority
row shape; `sda-api`/`interfaces` split; kernel catalog home; authoring
destination for the three writer scripts; stale `package.json` scripts; carrier
`.ts` fixture disposition.
