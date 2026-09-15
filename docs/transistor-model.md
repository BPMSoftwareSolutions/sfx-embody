# The transistor model: resolvers (0) and declared authority (1)

This is the durable statement of the architecture's smallest primitive. It exists
because the runtime must support more than one language, and therefore the
bootstrap must exist in more than one language. It answers, once, the question
every port/provider decision reduces to: *is this executable element a resolver,
or is it declared?*

Authority stack: [target-architecture.md](target-architecture.md) (what),
[embodiment-completeness.md](embodiment-completeness.md) (mechanics in code, per
language; agents must not edit SDA),
[target-experience.md](target-experience.md) (why),
[implementation-strategy.md](implementation-strategy.md) (who/how),
[performance-optimization.md](performance-optimization.md) (cost).

**Citation roots.** Unprefixed paths are this repo (`sfx-embody`). `SDA:` resolves
against the scenario-driven-architecture repo (`../scenario-driven-architecture`) —
read-only, agents must not edit it. `DB:` resolves against the sidefx-database repo
(`C:\lab\sidefx-database`), which supplies the connection and query runner only. A
sibling repo `sda-bootstrap` is named where relevant.

**Review.** This statement incorporates the required correction from
[research/target-architecture/target-model-review.md](research/target-architecture/target-model-review.md):
the transistor classifies **authority for executable behavior**, not physical
artifacts; projected executables are embodiments of declared authority (not a third
state); and there is **no third "neutral" classification** — if something is neither
declared nor inside an admitted resolver boundary, it is a defect.

---

## 1. The rule

The transistor classifies **authority for executable behavior**, not physical
artifacts. Every executable behavior has exactly one origin:

> **Every executable behavior has exactly one origin: declared authority (1),
> interpreted through resolver mechanics (0). Projected executables are embodiments
> of declared authority and never constitute a third source of executable meaning.**

| | state | what it is | cardinality | who owns it |
|---|---|---|---|---|
| **0** | **resolver** | hand-authored executable code that *interprets* declared authority | **one admitted resolver surface per language/runtime profile** | the platform (SDA), per language |
| **1** | **declared** | language-invariant data (rows, JSON) that the kernel interprets | **one canonical semantic authority identity**, however many verified physical representations exist | the database / authoring surface |

The transistor is the binary distinction. A capability is **all 1s (declared
authority) resolved by 0s (per-language resolvers)**:

```
             declared authority (1)                        resolvers (0)
capability ─┬─ feature / contracts ────────────────┐
            ├─ scenarios / execution authorities ──┼──▶ node resolver
            ├─ operations / ports / bindings ──────┤──▶ python resolver
            ├─ transformations / mechanics ────────┤──▶ csharp resolver
            └─ targets / interfaces ───────────────┘──▶ java / go / cpp resolver
                                                          │
                                                     same outcome digest
```

**The mechanic rule** (the sentence that decides most cases): *which mechanic runs
and with what configuration is always declared (1); the native implementation of the
mechanic is always a resolver (0).* Adding a mechanic is an SDA change; binding one
is data.

Two corollaries decide every case:

1. **Adding a language adds resolvers; it never adds a language-specific
   declaration.** If a new language exposes missing meaning, the canonical
   declaration is corrected **once, for every language** — never patched per
   language.
2. **The bootstrap is resolver code (0).** The thing that reads declarations and
   runs the kernel is itself executable and not declarable (proofs below). So a
   multi-language runtime owes, per language, an admitted native path from physical
   entry to canonical authority to its resolver floor — **without delegating
   executable semantics to another runtime**.

**If you cannot classify something as 0 or 1, you have found an architectural
defect.** Declare it, or resolve it; there is no third place for executable meaning
to live.

This is not new law invented here. SDA already states it as ADR-0013 and enforces it
through governance rules K016–K029.

- **SDA:docs/decisions/0013-hand-authored-surface-is-language-resolvers-only.md:33-40**
  defines the language resolver: *"the admitted hand-authored executable body that
  embodies the forbidden executable mechanics natively and resolves them from
  semantic data… the sole surface allowed to contain branching, iteration, exception
  policy, throwing, object construction, serialization, normalization, validation,
  fallback, retry, and state mutation as its own execution body."*
- ADR-0013:42-46 — *"Everything else is a projected artifact"*: any executable file
  that is not a declared resolver body must score zero on all twelve forbidden
  mechanics and carry projection provenance; a nonzero count outside a declared
  resolver boundary is `PROJECTED_EXECUTION_MECHANIC_VIOLATION`.
- **SDA:governance/workspace/governance-rules.json:235-241** — rule K029
  (`NON_RESOLVER_HAND_AUTHORED_MECHANIC`): every executable file must either sit
  inside a declared language-resolver boundary (the binding's `projectReferences.kernel`
  path plus its admitted native mechanic-provider bodies) or score zero on all twelve
  forbidden mechanics with projection provenance.

The twelve forbidden executable mechanics (the capabilities a resolver is *allowed*
to embody) are enumerated in
**SDA:kernel/schemas/projected-artifact-mechanical-sterility.schema.json:14** and
counted by **SDA:tools/src/consumer-projection/proof/mechanical-sterility-evaluator.ts:7-20**.

---

## 2. Why the bootstrap has to be multi-language

The estate already treats three things as irreducible code
([target-architecture.md](target-architecture.md):34-59). Each has a proof, and each
is a resolver (0):

| irreducible mechanic | proof | consequence |
|---|---|---|
| **frontdoor / loader** | *regress*: a declared executor needs another reader-and-runner, forever | must exist in every language that boots a capability |
| **database connection / query runner** | *circularity*: you cannot read the declaration that would declare the reader | must exist in every language that reads authority |
| **bootstrap installer** | *regress*: the first installer cannot be declared | must exist per bootstrap |

To this the multi-language premise adds the **per-language execution floor**: the
token scheduler, the transformation evaluator, the mechanic/declared-read/effect
providers, contract admission, and the `nativeFloor:true` platform-effect mechanics
are executable, and each language must implement them natively. SDA states the
effect floor as data in
**SDA:kernel/semantic-authority/consumer/platform-effect-mechanics.authority.v1.json**
(`nativeFloor: true`) and the mandatory consumer mechanics in
**SDA:kernel/semantic-authority/consumer/sda-platform-mechanic-parity.semantic-authority.json:5-19**
(profile `sda-consumer-mandatory-mechanics.v1`, 13 mechanics).

So "multi-language runtime" does not mean one host that happens to run elsewhere. It
means: the same declared capability (1) is executed by six resolvers (0), and the
boot that feeds each resolver is itself resolver code.

---

## 3. What is 0 and what is 1 — the taxonomy

### 3.1 Executable mechanics a compiled graph can name

A compiled execution graph names **cells**; a cell's executable authority is one of
`scenario | mechanic | provider | physical | junction`
(**SDA:kernel/schemas/execution-cell.schema.json:25**). The mechanic kinds and their
state:

| mechanic kind | declared (1) — one copy | resolver (0) — per language | where the resolver lives (node reference) |
|---|---|---|---|
| pure semantic-value (`path`, `literal`, `format`, `let`, `equals`, `length`, `sha256`, …) | mechanic catalog + expression AST + contracts | evaluator + mechanic provider | `SDA:languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs`, `…/semantic-execution-graph/…` |
| collection / recurrence (`map`, `filter`, `find`, `some`, `every`, …) | `execution-pattern.v1` (`patternType`, decisions) | pattern resolvers + scheduler | `SDA:languages/typescript/runtimes/node/execution-pattern-resolvers.mjs` |
| transformation / language port | the AST recipe is data | transformation engine | `SDA:languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs` |
| platform effect ports (credential, HTTP exchange, clock, file, …) | meaning + `sourceProfiles` | **irreducible native code per language/OS** | `SDA:…/semantic-execution-graph-effect-provider.mjs`, `…/external-credential-reference-binding-provider.mjs`, `…/governed-http-exchange-provider.mjs` |
| declared data reads | `{ statement, resultColumn }` | declared-read provider + DB driver | `SDA:…/semantic-execution-graph-declared-read-provider.mjs` |
| contract / schema admission | schemas in `plan.contractCatalog` | JSON-Schema validator | `SDA:…/schema-contract-admission-provider.mjs` |
| scheduling | topology + decision fields | token scheduler | `SDA:…/semantic-execution-graph/scheduler.js` |

**The classification rule** (the one sentence to keep): *which mechanic runs and with
what configuration is always declared (1); the native implementation of the mechanic
is always a resolver (0).* Adding a mechanic is an SDA change; binding one is data.

### 3.2 The boot

| boot element | state | disposition |
|---|---|---|
| frontdoor process entry, stdin/stdout/stderr envelope, dynamic module load, permission/sandbox flags, DB driver session | **0** | native host mechanics; one resolver surface per language |
| command mapping, declaration SQL, coherence checks, input mapping, result shaping, semantic address / drilldown / observation filter | **1** | *declared authority*. This is portable logic sitting in code today; it belongs in declared capabilities. While it remains estate code, it is the defect this document names. |
| language selection | **1** | the CLI has no `--target`; `defaultTarget` is read from declared rows (`src/read-execution-delivery.mjs:5-22`) |

There is no third category. "Portable logic" is not a state: either its behavior is
expressible as authority/data (→ **1**) or its execution irreducibly requires native
runtime mechanics (→ **0**).

Evidence in the estate: `src/database-delivery.mjs` is almost entirely host seams
(`process.stdin` :11-18, `pathToFileURL`/`import()` :27-35, `process.env` :30,
`process.stderr.write('SFX_OBSERVATION …')` :42, `process.stdout.write` :59) —
resolver (0). The `src/` files with no host imports at all —
`execution-drilldown.mjs`, `observation-filter.mjs`, `semantic-address.mjs` — carry
portable logic that is **declared authority (1) sitting in code**; it belongs in
declared capabilities, not in the boot. `src/invoke-database-capability.mjs` is
likewise mostly declared logic (operation table, validation, shaping) with two host
seams (`node:crypto`/`node:url` at :1-2 and the residual per-language evaluator
import at :121-122). Every one of these is 0 or 1; none is "neutral".

---

## 4. The irreducible resolver floor (per language)

The minimal surface a language must provide to boot and execute the *same* declared
capability, as it exists today in SDA:

| # | resolver body | node | python | csharp | java | go | cpp |
|---|---|---|---|---|---|---|---|
| 1 | token scheduler | `runtimes/node/semantic-execution-graph/scheduler.js` | `platform/execution_graph.py` | `Graph/SemanticExecutionGraphScheduler.cs` | `platform/SemanticExecutionGraphScheduler.java` | `platform/execution_graph.go` | `graph/execution_graph_scheduler.cpp` |
| 2 | mechanic provider | `semantic-execution-graph-mechanic-provider.mjs` | `adapters/semantic_execution_graph_mechanic_provider.py` | `Graph/SemanticExecutionGraphMechanicProvider.cs` | `platform/SemanticExecutionGraphMechanicProvider.java` | `platform/graph_mechanic_provider.go` | `graph/execution_graph_mechanic_provider.cpp` |
| 3 | declared-read provider | `semantic-execution-graph-declared-read-provider.mjs` | `…declared_read_provider.py` | `Graph/SemanticExecutionGraphDeclaredReadProvider.cs` | `platform/…DeclaredReadProvider.java` | `platform/graph_declared_read_provider.go` | `graph/execution_graph_declared_read_provider.cpp` |
| 4 | effect provider | `semantic-execution-graph-effect-provider.mjs` | `adapters/…effect_provider.py` | `Graph/SemanticExecutionGraphEffectProvider.cs` | `platform/…EffectProvider.java` | `platform/graph_effect_provider.go` | `graph/execution_graph_effect_provider.cpp` |
| 5 | transformation evaluator | `semantic-transformation-evaluator.mjs` | `adapters/semantic_transformation_evaluator.py` | `Consumer/SemanticTransformationEngine.cs` | `adapters/SemanticTransformationEngine.java` | `platform/transformation.go` | `graph/transformation_evaluator.cpp` |
| 6 | execution-pattern resolvers | `execution-pattern-resolvers.mjs` | `platform/execution_pattern_resolvers.py` | `Graph/ExecutionPatternResolvers.cs` | **not found** | **not found** | **not found** |
| 7 | schema / contract admission | `schema-contract-admission-provider.mjs` | `platform/consumer.py` | `Schema/SemanticContractCatalogAdmission.cs` | `platform/SemanticExecutionGraphConsumerHost.java` | `platform/graph_consumer_host.go` | `graph/contract_catalog_admission.cpp` |
| 8 | effect ports | external-credential / http / … | `platform/governed_effect_ports.py` | `Graph/GovernedEffectPorts.cs` | `platform/GovernedEffectPorts.java` | `platform/…effect ports` | `graph/governed_effect_ports.cpp` |
| 9 | kernel state machine + disposition | `src/kernel/scenario-kernel.ts` | `kernel/scenario_kernel.py` | `src/ScenarioKernel/ScenarioKernel.cs` | `kernel/ScenarioKernel.java` | `kernel/scenario_kernel.go` | **generated** (`generated/execution/…`) |
| 10 | consumer platform entry | `runtimes/node/admitted-consumer-platform.mjs` | `platform/consumer.py` | `Consumer/AdmittedConsumerPlatform.cs` | `platform/AdmittedConsumerPlatform.java` | `platform/platform.go` | `platform/consumer_platform.cpp` |
| 11 | mechanic-registry loader | `node-mechanic-registry-loader.mjs` | **not found** | **not found** | **not found** | **not found** | **not found** |
| 12 | frontdoor / loader / DB runner / sandbox | this repo `src/` | **not found** | **not found** | **not found** | **not found** | **not found** |

Rows 1–10 are SDA resolver bodies. **Row 11 and row 12 are the gap this document is
about**: only Node has a registry loader, and only Node has a bootstrap. The
per-language registries exist as declared authority
(**SDA:kernel/semantic-authority/consumer/<language>-mechanic-registry.authority.v1.json**,
six files) but for python/csharp/java/go/cpp they are not consumed by a runtime loader.

---

## 5. Conformance: what makes it one architecture, not N

The declared authority is shared; the resolvers diverge only in implementation. The
contract that keeps them equivalent is **digest parity**, and it is real:

| obligation | artifact |
|---|---|
| per-mechanic vectors — *"No target's runtime is the specification, including the Node one."* | **SDA:conformance/execution-graph/mechanics/\*.v1** + `run-mechanic-conformance.mjs` |
| graph digest parity — shared canonical digest, per-target realization | **SDA:conformance/execution-graph/language-graph-v1-conformance.json** (`canonicalGraphDigest sha256:c0851c…`) |
| plan carries both digests | `consumer-execution-embodiment-plan.v3.schema.json` requires `canonicalGraph` + `canonicalGraphDigest` + `realizationOverlay` + `realizedGraphDigest` |
| kernel execution-vector parity | **SDA:conformance/corpus/execution/\*.json** + `…/expectations/execution/*.expected.json` |
| per-language implementation claim | **SDA:languages/<lang>/conformance/scenario-kernel-<lang>.conformance.json** |
| 13 mandatory consumer mechanics | **SDA:kernel/semantic-authority/consumer/sda-platform-mechanic-parity.semantic-authority.json** |
| no foreign delegation | **SDA:kernel/schemas/native-runtime-boundary.schema.json** (`foreignRuntimeDependencies: 0`, `foreignSemanticDelegations: 0`) |

**Graph-scheduling status (in-repo, tracked):** all six targets — `node, csharp,
python, java, go, cpp` — are `ADMITTED` in
**SDA:conformance/execution-graph/language-graph-v1-conformance.json:6-43**.
Language *binding* status is capped at `DECLARED | IMPLEMENTING`
(**SDA:kernel/schemas/language-binding.schema.json:37-41**) and all six bindings are
`IMPLEMENTING`; **`ADMITTED` language admission is computed, never hand-set**, from
`artifacts/conformance/scenario-kernel-<lang>.conformance-result.json` via the
`kernel-implementation-admission` capability — and that directory is gitignored
(**SDA:.gitignore:64**), so a fresh checkout reads every language as `NOT_ADMITTED`
until the gate runs.

The estate's projection surface admits only `node | python | csharp`
(`src/projection-delivery.mjs:15` `ADMITTED_TARGETS`), which is why the estate's
cross-language proofs today cover those three. The SDA kernel is nonetheless
six-language.

---

## 6. The bootstrap consequence — options and the irreducible remainder

### 6.1 Current state

The boot is **Node-only**. The chain is
`sidefx-cli → spawn → src/database-delivery.mjs → src/invoke-database-capability.mjs → SDA node kernel`.
The precursor `sda-bootstrap` packages the pinned Node runtime + projector, but its
manifest declares `languageResolver.target: "node"`
(`sda-bootstrap/bootstrap/bootstrap.manifest.json`) — one language.

### 6.2 Options

| option | shape | preserves | cost / risk |
|---|---|---|---|
| **(a) per-language bootstrap** | each language re-authors frontdoor + loader + DB runner + kernel | native execution and the `nativeFloor` effect floor; no cross-language ceiling | N× the irreducible three; N× isolation boundaries (only Node's exists today: `restrict-memory-process.mjs` + `--experimental-permission`); N× DB drivers |
| **(b) sealed binary per OS** | one compiled binary per OS (Node SEA + `postject`), signed/attested; CLI verifies the digest **before spawn** | inherits Node's permission guard unchanged; one implementation to seal | still one language's runtime; sealing Node alone leaks the SDA kernel/providers unless they are bundled too; a binary cannot attest itself |
| **(c) thin shim to one canonical host** | each language shells to the canonical host | one kernel implementation | **rejected**: the `nativeFloor:true` effects would execute in the canonical host, not natively — a facade, which [embodiment-completeness.md](embodiment-completeness.md):41-46 forbids ("A language that returns its input unchanged … is a facade, not an embodiment") |

Option (b) does not remove the need for option (a): a sealed Node binary is a
single-language bootstrap. The multi-language *runtime* still needs a per-language
boot **or** a documented decision to narrow the target set. That decision is the
team's (see §9).

### 6.3 Irreducible per language, regardless of option

DB connection/query runner; frontdoor/loader; bootstrap installer; `nativeFloor`
effect mechanics; the token scheduler. **Shareable:** the declared graph/plan, the
contracts, the canonical digests, the projector output — i.e. all the 1s.

### 6.4 The trust boundary

Seal the *implementation* (frontdoor + loader + DB runner + kernel + providers); keep
the *authority rows and config* open — meaning is the product and lives in rows
([next-experiences.md](next-experiences.md):98-101). The correct primitive is a
**signed (attested) digest**, not an "encrypted digest": encryption gives
confidentiality, not authenticity.

---

## 7. Current state and gaps (honest inventory)

### 7.1 What holds

- Six-language SDA kernel, all graph-ADMITTED; six per-language mechanic registries.
- The estate declares capability meaning as rows and interprets it in-process
  ([target-architecture.md](target-architecture.md)); the kernel path is green for
  `greet-by-name`, `run-declared-query`, equity, and sidefx-eligible-providers.
- Projection (`sfx capability project … --full-mechanics`) emits per-target bodies
  with per-file `digest` + `sourcePointers` and `PURE_PROJECTION_CONFORMS`
  ([capability-command-surface.md](capability-command-surface.md):202-240).
- Detectors exist: `sql/inspect/hand-authored-module-references.sql`; the
  `detect-hand-authored-code` capability and
  `agentic-harness/governance/no-hand-authored-code.policy.v1.json`
  (`handAuthoredExecutableBodyAllowed: false`,
  `failureDisposition: NON_CANONICAL_EXECUTABLE_BODY_REJECTED`).

### 7.2 What is missing — the gaps the research found

| # | gap | evidence | class |
|---|---|---|---|
| G1 | **No resolver boundary is declared.** Every `languages/*/binding/*.binding.json` has only `projectReferences`. Without it, K029's "inside a declared resolver boundary" cannot be evaluated. | SDA:docs/languages-resolver-boundary-and-projection-inventory.md:387 | SDA change |
| G2 | **No repository-wide sterility scan is wired.** The twelve-counter evaluator runs over projection-plan files, not every executable file; `verify-resolver-boundary-sterility` is a feature with no scenario in `workspace-governance/capability.json` and no provider. | SDA:tools/src/consumer-projection/proof/mechanical-sterility-evaluator.ts; `…/verify-resolver-boundary-sterility.feature` | SDA change |
| G3 | **No language-level missing-resolver gate.** Parity is scoped to 13 consumer mechanics for `IMPLEMENTING` bindings; a language missing a resolver body fails no admission. | SDA:sda-platform-mechanic-parity.semantic-authority.json | SDA change |
| G4 | **No taxonomy authority.** The twelve mechanic names live twice (kernel schema + TS evaluator) and can drift; no `projected-execution-mechanic-taxonomy.v1`. | SDA:docs/sda-common-execution-mechanics-and-deterministic-tooling-capabilities-analysis.md:284-301 | SDA change |
| G5 | **Sterility evaluator misses `.go`.** Its extension regex omits `.go` (covers `.js|.mjs|.cjs|.ts|.tsx|.cs|.py|.java|.swift|.kt|.cpp`). | SDA:…/mechanical-sterility-evaluator.ts:38 | SDA change |
| G6 | **Only Node has a mechanic-registry loader and a bootstrap.** Python/C#/Java/Go/C++ registries are declared but not consumed at runtime. | SDA:docs/handoff/semantic-execution-graph-cross-target-host-gaps.md:130-139; `sda-bootstrap` manifest `languageResolver.target: node` | SDA change (loader) + estate decision (bootstrap) |
| G7 | **Residual estate resolver seam.** The loader still dynamically imports `configuration.estateProvider.module` (a type-0 estate module) and 7 estate-module PROVIDER rows remain. | src/invoke-database-capability.mjs:99-103; sql/inspect/hand-authored-module-references.sql; implementation-strategy.md:92-95 | **data defect** — re-declare (estate) |
| G8 | **Stale inventory.** `languages-resolver-boundary-and-projection-inventory.md:209-218` says C++ has no kernel; C++ is graph-ADMITTED with a full `graph/` provider set. | SDA:conformance/execution-graph/language-graph-v1-conformance.json:38-41 | SDA doc fix |
| G9 | **No cross-language schema-admission corpus.** | SDA:docs/handoff/semantic-execution-graph-cross-target-host-gaps.md:200-201 | SDA change |
| G10 | **C++ resolver boundary ambiguous** — binding points `kernel` at projected `generated/execution`, so its resolver boundary is undeclared. | SDA:languages/cpp/binding/scenario-kernel-cpp.binding.json | SDA change (G1) |

Note the boundary discipline: G1–G6 and G8–G10 are **cross-language → SDA change
requests** (agents must not edit SDA). G7 is **estate data** — re-declare the port to
a platform mechanic or a declared read; never restore deleted code.

---

## 8. Enforcement — the smallest mechanism that works

The transistor rule is only an architecture if a violation fails a gate. The
smallest complete mechanism has three parts:

1. **Declare the resolver boundary** in each language binding (G1). This is the
   precondition; without it there is nothing to be inside or outside of.
2. **Run the twelve-counter evaluator over every executable file** and fail on any
   nonzero count outside a declared boundary (G2, G5). ADR-0013:93-95 already
   specifies this gate; it is declared but not wired.
3. **Fail admission when a language lacks a required resolver body** (G3) — the
   resolver analogue of the 13-mechanic parity profile.

On the estate side, the two existing detectors already bound the problem:
`sql/inspect/hand-authored-module-references.sql` (declaration rows naming a module;
target zero rows) and `detect-hand-authored-code` (classify an artifact against the
twelve mechanics). The estate's obligation is to keep G7 at zero rows; it does not
need new estate code.

---

## 9. Decisions the team must make

These are builder decisions (per
[sidefx-architecture-decision-rubric.md](sidefx-architecture-decision-rubric.md):101),
not resolvable by a lane:

1. **Target set.** Is the multi-language runtime `node + python + csharp` (the estate
   projection's admitted targets today), or all six SDA graph-ADMITTED languages
   (`node, python, csharp, java, go, cpp`)? The answer fixes how many bootstraps are
   owed.
2. **Bootstrap realization.** Per-language re-authored bootstrap (§6.2a) versus a
   sealed binary per OS (§6.2b). They are orthogonal but quantify the work:
   (a) requires the irreducible three per language; (b) requires a packaging/signing
   build and pre-spawn digest verification, and still lands on one language unless
   combined with (a).
3. **Sealed artifact scope.** Whether sealing covers only the frontdoor/loader or the
   whole platform (kernel + providers), given that sealing the frontdoor alone leaks
   the kernel.
4. **Enforcement home.** Whether the resolver-boundary scan belongs to SDA admission
   (G1–G5) only, or whether the estate also runs a declaration-side check in its
   preflight.

---

## 10. SDA change requests (agents do not edit SDA)

Format per [embodiment-completeness.md](embodiment-completeness.md):12-37
(*primitive / why kernel / affected languages / data that binds it / evidence*).

1. **Declare resolver boundaries in binding manifests.**
   - *primitive:* add the resolver-boundary declaration to `language-binding.schema.json`
     and each `languages/*/binding/*.binding.json` (kernel path + native
     mechanic-provider bodies).
   - *why kernel:* it is the precondition for K029 and applies identically to every
     language.
   - *languages:* node, python, csharp, java, go, cpp.
   - *data that binds it:* the existing `projectReferences.kernel` and the per-language
     registry's provider module lists.
   - *evidence:* `SDA:docs/decisions/0013-…:48-53`; `SDA:docs/languages-resolver-boundary-and-projection-inventory.md:387`.

2. **Wire the repository-wide sterility gate.**
   - *primitive:* run `mechanical-sterility-evaluator` over every executable file and
     fail the build on a nonzero count outside a declared boundary; add `.go` to the
     evaluator's extension set.
   - *why kernel:* ADR-0013:93-95 and K029; the same gate for every language.
   - *languages:* all six.
   - *data that binds it:* the declared resolver boundaries (request 1) and the
     twelve-mechanic taxonomy (request 4).
   - *evidence:* `SDA:…/mechanical-sterility-evaluator.ts:38`;
     `SDA:…/verify-resolver-boundary-sterility.feature` (declared, unwired).

3. **Add the language-level missing-resolver admission check.**
   - *primitive:* extend admission so a required, unbound resolver body fails the
     language (not merely one capability's plan).
   - *why kernel:* resolver coverage is a property of a language, computed uniformly.
   - *languages:* all six.
   - *data that binds it:* `sda-platform-mechanic-parity.semantic-authority.json` and
     the per-language registries.
   - *evidence:* `SDA:…/sda-platform-mechanic-parity.semantic-authority.json:5-19`;
     `SDA:docs/handoff/semantic-execution-graph-cross-target-host-gaps.md:130-139`.

4. **Publish the mechanic taxonomy authority.**
   - *primitive:* one `projected-execution-mechanic-taxonomy.v1` consumed by the
     schema and the evaluator.
   - *why kernel:* the twelve names are cross-language law and currently duplicated.
   - *languages:* all six.
   - *data that binds it:* the existing schema/evaluator lists.
   - *evidence:* `SDA:docs/sda-common-execution-mechanics-and-deterministic-tooling-capabilities-analysis.md:284-301`.

5. **Provide a per-language mechanic-registry loader and bootstrap surface.**
   - *primitive:* a loader that consumes `<language>-mechanic-registry.authority.v1.json`
     at runtime in each language, and a documented bootstrap entry per language.
   - *why kernel:* today only Node reads its registry; the registries are declared but
     inert for the others.
   - *languages:* python, csharp, java, go, cpp.
   - *data that binds it:* the six registry authorities; `sda-bootstrap` manifest.
   - *evidence:* `SDA:docs/handoff/semantic-execution-graph-cross-target-host-gaps.md:130-139`.

6. **Include `sourcePointers` in the published (DB/published) projection manifest**
   and a portable seam specifier, so a projected body is reviewable outside its
   generation depth.
   - *why kernel/projector:* the manifest shape and seam specifiers are SDA-owned.
   - *languages:* all projection targets.
   - *data:* the per-file `sourcePointers` already present in the on-disk manifest.
   - *evidence:* `docs/capability-command-surface.md:242-247`;
     `docs/next-experiences.md:61-63`.

---

## 11. The one-paragraph statement

**Every executable behavior in SDA is governed by one binary distinction: resolver
(0) or declared authority (1). Declared authority owns what executes — its semantic
meaning, topology, bindings, contracts, configuration, and expected outcome; it
exists once canonically and is language-neutral. Resolvers own only the irreducible
native mechanics required to interpret and physically realize that authority; each
supported native runtime therefore owes its own admitted resolver surface and
bootstrap path. Projected executables are not a third state — they are reproducible
embodiments of declared authority. If executable behavior is neither declared nor
inside an admitted resolver boundary, it is an architectural violation. Equivalence
across languages is digest parity, computed by admission, not hand-set; today only
Node has a bootstrap. The rule is enforced by declaring resolver boundaries and
failing any executable file that carries forbidden mechanics outside one — a gate SDA
has specified (ADR-0013, K029) but not yet wired.**

**Declare it or resolve it. There is no third place for executable meaning to live.**
