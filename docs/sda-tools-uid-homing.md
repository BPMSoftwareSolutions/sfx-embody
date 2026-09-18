# SDA tools UID homing ledger

**Status.** Recorded 2026-09-17 from a read-only inventory of the SDA repository
(`C:\lab\repos\scenario-driven-architecture`, state `0bff62b`, working tree clean
except the untracked `docs/transistor-model.md`). SDA was not modified. The
ledger is written to the estate because agents must not edit SDA. Every
hand-authored executable file in SDA outside the declared kernel resolver
boundary is assigned exactly one home: **declared (1)**, **resolver (0)**,
**eliminated**, or the **irreducible boot**. A file with none of these is a
dishonesty finding under governance rule K029.

Authorities applied literally: estate `docs/transistor-model.md` §1;
estate `docs/target-architecture.md` (the only-code list, disposition, and
"How to decide a new case"); `SDA:docs/decisions/0013-hand-authored-surface-is-language-resolvers-only.md`;
`SDA:governance/workspace/governance-rules.json` K016–K029;
`SDA:kernel/schemas/projected-artifact-mechanical-sterility.schema.json`;
`SDA:tools/src/consumer-projection/proof/mechanical-sterility-evaluator.ts`.

---

## 1. Method

### 1.1 Scope

The inventory covers every tracked hand-authored executable file in SDA outside
`languages/**` and `kernel/**` — at minimum `tools/**`, plus authored `.mjs`,
`.ts`, `.js`, `.cjs` elsewhere (`conformance/**`, `capabilities/**`,
`examples/**`). Executable extensions enumerated: `.mjs .ts .js .cjs .tsx .py
.cs .java .go .cpp .swift .kt`. SQL, JSON, schemas, and manifests are declared
data, not code, and are out of scope.

Counts:

| Surface | Files |
|---|---|
| Candidate executable files outside `languages/**` + `kernel/**` | 854 |
| Generated / projected seams (excluded; carry a `GENERATED … Do not hand-edit` provenance header) | 393 |
| **Hand-authored files inventoried here** | **461** |

The excluded 393 are projected embodiments of declared authority: 340 under
`capabilities/sda-tooling/**` (including `projected-tools/**`), 35 under
`capabilities/sda-platform/**/projected/**`, 18 under
`examples/generic-capability/**`. They are the K029(b) case (zero forbidden
mechanics, projection provenance) and are not hand-authored surface. They are
exactly what the declared(1) home looks like once the conveyor has run.

### 1.2 The resolver boundary

K029 admits a file only inside "the `projectReferences.kernel` path of an
admitted language-binding manifest plus its admitted native mechanic-provider
bodies". The current binding manifests declare no resolver boundary (transistor
model G1); their `projectReferences.kernel` values are:

| Language | `projectReferences.kernel` | Note |
|---|---|---|
| node | `src/kernel` (under `languages/typescript/`) | admitted surface |
| python | `src/scenario_kernel/kernel` | admitted surface |
| csharp | `src/ScenarioKernel` | admitted surface |
| java | `src/main/java/scenario/kernel/kernel` | admitted surface |
| go | `kernel` | admitted surface |
| cpp | `generated/execution` | **projected (1), not resolver (0)** — G10 |

No inventoried file lies on any of those paths. Consequently **zero files in
this ledger can be homed resolver (0)**, and the rule the task states holds
literally: a file in `tools/` that is not in a language runtime cannot be
resolver(0). Where a file's behavior is irreducibly native (clock, SHA-256,
process spawn, module load), its declared home names the mechanic it becomes
and the per-language resolver body that must implement it.

### 1.3 Sterility counts

The **Sterility** column is the evaluator's own arithmetic, not a judgment:
the twelve patterns at `SDA:tools/src/consumer-projection/proof/mechanical-sterility-evaluator.ts:7-20`
are matched per file, and — per the same evaluator at line 119 — every
executable file that is not a recognized projection seam additionally scores
`meaning-hidden-in-text: 1`. The column is the sum of those violation counts
(the evaluator's `violations` total). Two caveats from the transistor model:
the evaluator's extension regex omits `.go` (G5), and the evaluator itself is
one of the hand-authored files that must still be homed (see F5 and F7 below).

The counts are evidence of the current state, not of the home. A file homed
declared(1) or eliminated still carries its mechanics today; the home is where
its behavior must go. All 461 inventoried files score above zero (the
evaluator's per-file floor is 1), and 231 of the 275 declared files exceed that
floor. Under K029, any nonzero count outside a declared resolver boundary is
`NON_RESOLVER_HAND_AUTHORED_MECHANIC` **today**; this ledger does not excuse
them, it homes them.

### 1.4 Purposes and LOC

LOC is physical line count. Purposes are derived from the path and the file's
declared role; capability-provider closure below means a module reached by
import from a `tools/src/capabilities/**/provider.ts` whose binding is declared
in `capabilities/sda-tooling/<domain>/provider-bindings.json`
(`implementationRef` → `artifacts/tools/dist/...`).

---

## 2. Doctrine (self-contained)

**Transistor rule, estate `docs/transistor-model.md:44-49`:**

> **The resolver mechanics live in the SDA Kernel (scenario-driven-architecture),
> requiring a bare minimum three-language conformance (Node, Python, and CSharp).
> There is no grey area. Either it's resolver(0) code living in the SDA Kernel or
> it's declared(1) in the database, period. Hence, when we run into a bug in code
> that exist outside of the SDA Kernel, then that is decide whether it should be
> moved into data or the resolver. The code cannot remain in its found location**

**No third state, estate `docs/transistor-model.md:87-89`:**

> **If you cannot classify something as 0 or 1, you have found an architectural
> defect. Declare it, or resolve it; there is no third place for executable meaning
> to live.**

**ADR-0013:33-40 — the language resolver definition:**

> A language resolver is the admitted hand-authored executable body that embodies
> the forbidden executable mechanics natively and resolves them from semantic
> data: authority, contracts, transformations, projection and execution
> authority, target profiles, and lineage. It is the sole surface allowed to
> contain branching, iteration, exception policy, throwing, object construction,
> serialization, normalization, validation, fallback, retry, and state mutation
> as its own execution body.

**ADR-0013:42-46 — everything else is projected:**

> Every executable file in SDA that is not a declared language-resolver body must
> score zero on all twelve forbidden executable mechanics and carry projection
> provenance. Any nonzero forbidden-mechanic count outside a declared resolver
> boundary yields `PROJECTED_EXECUTION_MECHANIC_VIOLATION` and rejects admission.

**ADR-0013:48-53 — the boundary is declared, and tooling is not inside it:**

> Each admitted language binding declares its resolver boundary in its binding
> manifest. The declared surface is the language kernel, its platform mechanic
> providers, and the native mechanic-provider bodies admitted as that resolver.
> Projection, CLI, compatibility, document-generation, and capability-scenario
> tooling are not resolver bodies and must be projected.

**ADR-0013:55-61 — the fractal closure (the projector itself is projected):**

> Every language resolves itself as a fractal: each language resolver projects its
> own full tooling surface (projector, CLI, adapters, document generation,
> compatibility transforms) from semantic data through the same generic
> projection protocol. No central hand-authored projector survives; bootstrap
> circularity is closed by admitting one versioned bootstrap compiler and
> requiring reproducible self-hosting evidence before any non-resolver surface is
> admitted.

**ADR-0013:63-69 — monotonic shrinkage:**

> The hand-authored surface outside declared resolver boundaries shrinks
> monotonically, measured as a declining line or file count under `tools/src/`
> between successive baselines. Replacement proceeds through the ordinary
> semantic capability conveyor: capability feature, harness candidate authoring,
> testimony retention, deterministic repair, admission, and generic projection
> bound through `provider-bindings.json` `implementationRef` to a generated
> capability runtime.

**ADR-0013:73-82 — named cases:**

> `tools/providers/target-projection-provider.mjs` and
> `registered-source-inspector.mjs` are not C++ resolver bodies; they must be
> replaced by projected C++ capabilities resolved by the C++ resolver itself.

> `tools/cli/sda.js`, `tools/src/interfaces/*`, and
> `tools/compatibility/adapts-v1-capability-to-v2.js` are projected seams, not
> protected infrastructure.

> The `ToolCapabilityHost` sits on the line: if it sequences capability
> transitions it executes a forbidden mechanic, so it is either admitted as the
> Node resolver's own body or its sequencing is replaced by authority-backed
> mechanic execution.

**ADR-0013:86 — the harness is not SDA surface:**

> Model-invocation, authoring, and conveyor families live in the Agentic
> Harness, outside SDA, and are the mechanism rather than SDA surface.

**K029, `SDA:governance/workspace/governance-rules.json:236-241`:**

> Per ADR-0013, every executable file in the repository must either (a) reside
> inside a declared language-resolver boundary (the `projectReferences.kernel`
> path of an admitted language-binding manifest plus its admitted native
> mechanic-provider bodies) and is therefore permitted to embody the twelve
> forbidden executable mechanics, or (b) score zero on all twelve forbidden
> executable mechanics and carry projection provenance. A repository-wide
> sterility scan runs the twelve-counter evaluator over every executable file;
> any nonzero forbidden-mechanic count outside a declared resolver boundary
> yields `NON_RESOLVER_HAND_AUTHORED_MECHANIC` and rejects admission. Binding
> manifests may not declare projection, CLI, compatibility, document-generation,
> or capability-scenario tooling as resolver boundaries.

**K016, `governance-rules.json:145-150`:** projected consumer source is an
embodiment seam only; branching, iteration, exception policy, throwing, object
construction, serialization, normalization, validation, fallback, retry, state
mutation, and meaning hidden in text are forbidden. Any nonzero projected
mechanic count yields `PROJECTED_EXECUTION_MECHANIC_VIOLATION`.

**Target architecture, estate `docs/target-architecture.md:34-36`:**

> Exactly three mechanics are irreducible. Everything else is a row or is
> deleted.

The three, with their proofs (`target-architecture.md:38-59`): the
**frontdoor/loader** (regress), the **database connection/query runner**
(circularity), the **bootstrap installer** (regress); plus
**delivery/workspace config** (`read-workspace-config`) as boot config at
line 69.

**Disposition, `target-architecture.md:61-72`:**

> | Concern | Disposition |
> |---|---|
> | domain resolvers (`src/resolvers/node/*.mjs`) | **declared capability** … |
> | reader/projection operations (`read-capability-meaning`, `read-circuit-media`) | **declared capability** (SQL read + transformation) |
> | presentation (`narrate-*`, `diagram-*`) | **declared capability** (templates/transformations over authority); if not expressible, a platform presentation mechanic — never estate code |
> | frontdoor/loader, DB query runner, bootstrap installer | **code** (the irreducible three) |
> | delivery/workspace config (`read-workspace-config`) | **code** (boot config) |
> | materialization (`materialize-node`, `prepare-database-capability`, `load-memory-scenario`, `load-consumer-plan`, `read-execution-graph`, `reveal-native-expressions`, `embodiment-delivery`) | **eliminated** — nothing is emitted/loaded/written once the kernel interprets |
> | native-body verification (`verification/verify-node`, `verify-native-projection`, `verify-contract-fidelity`) | **eliminated** — verifies artifacts that no longer exist |

**How to decide a new case, `target-architecture.md:73-84`:**

> 1. **Is it the boot?** (frontdoor/loader, DB connection/query runner, bootstrap
>    installer.) → it is code — the only allowed code.
> 2. **Does it emit, load, write, or verify a native body / materialized plan?**
>    → it is **eliminated**; do not port it or declare it. This is what the kernel
>    supersedes.
> 3. **Otherwise** → it is **meaning**; it becomes rows (a declared read, a
>    declared transformation, a provider binding) and is invoked through the
>    frontdoor.

**Non-reasons to retain `target-architecture.md:86-95` include:** "it makes an
invocation pass"; materialization, native bodies, or file writes;
platform-commit pinning or build-time provenance gates; parity against retained
native-body fixtures; "we might need it later".

---

## 3. Summary counts

| Home | Files | LOC | Sterility mechanics | Share of files |
|---|---:|---:|---:|---:|
| **declared (1)** | 275 | 18,784 | 5,870 | 59.7% |
| **eliminated** (materialization + verification) | 68 | 6,121 | 2,490 | 14.8% |
| **test floor** (separate class; see §4.2) | 95 | 18,047 | 7,245 | 20.6% |
| **NO HOME — dishonesty findings** | 23 | 10,782 | 4,791 | 5.0% |
| **resolver (0)** | 0 | 0 | — | 0% |
| **irreducible three / boot** | 0 | 0 | — | 0% |
| **Total** | **461** | **53,734** | **20,396** | 100% |

By evidence code:

| Code | Files | LOC | Mechanic sum |
|---|---:|---:|---:|
| D-CAP — declared tooling capability provider closure | 144 | 6,225 | 1,721 |
| D-SEAM — projected seam (CLI / interfaces / compatibility / document generation) | 37 | 3,562 | 1,131 |
| D-ADAPTER — adapter/port/model for a declared capability | 48 | 2,753 | 745 |
| D-COMPILER — authority/consumer compiler | 6 | 1,417 | 660 |
| D-CONTRACT — contracts, models, primitives | 22 | 1,858 | 508 |
| D-CONF — conformance evidence publication | 4 | 186 | 94 |
| D-GOV — governance reading | 2 | 136 | 46 |
| D-PRESENT — UI presentation/parity | 12 | 2,647 | 965 |
| E-MAT — eliminated materialization | 41 | 4,160 | 1,714 |
| E-VER — eliminated native-body verification | 26 | 1,873 | 751 |
| E-LEG — eliminated legacy-provider equivalence oracle | 1 | 88 | 25 |
| T-HARNESS — test floor (no admitted home today) | 95 | 18,047 | 7,245 |
| N-PROJ — no home: projector authors executable meaning | 9 | 8,346 | 4,004 |
| N-UNBOUND — no home: unbound application machinery | 11 | 2,021 | 664 |
| N-HOST — no home: `ToolCapabilityHost` and provider loader | 2 | 156 | 58 |
| N-AUTH — no home: new database-artifact materialization | 1 | 259 | 65 |

The three highest single-file mechanic counts in the repository are the target
`capability-execution-emitter.ts` files (csharp 1,076; node 880; python 557) —
the files that author executable meaning into emitted bodies — followed by their
test at 1,050 and `tools/tests/semantic-execution-graph.test.js` at 1,023
(test floor).

---

## 4. Evidence legend

### 4.1 Home definitions

- **declared (1)** — the behavior is portable meaning: it becomes rows
  (a declared read, a declared transformation, a declared capability) and is
  replaced by the declared capability resolved by the kernel, projected through
  the ADR-0013 conveyor. It may not remain hand-authored in `tools/`.
- **eliminated** — the file implements a function the target architecture
  deletes (materialization: `materialize-node`, `prepare-database-capability`,
  `load-memory-scenario`, `load-consumer-plan`, `read-execution-graph`,
  `reveal-native-expressions`, `embodiment-delivery`; native-body verification:
  `verify-node`, `verify-native-projection`, `verify-contract-fidelity`).
  It is not ported and not declared.
- **resolver (0)** — only files inside a declared language-resolver boundary
  (`projectReferences.kernel` + admitted native mechanic-provider bodies).
  **No inventoried file qualifies.**
- **boot** — the irreducible three plus delivery/workspace config; named by
  `target-architecture.md:38-69`. No SDA `tools/` file is the estate boot.

### 4.2 Home test, applied in order

1. Is it the boot? → only the estate names boot files; none in this inventory.
2. Does it emit, load, write, or verify a native body or materialized plan? →
   **eliminated** (E-MAT / E-VER / E-LEG).
3. Is its behavior the meaning of a declared capability/read/transformation
   (in the declared capability closure, a projected seam, or an authority
   compiler)? → **declared (1)**.
4. Is it a test, fixture, conformance bridge, or reference double? → **test
   floor** — classified separately because the architecture has not admitted a
   harness home: the conveyor/authoring families live in the Agentic Harness,
   outside SDA (ADR-0013:86), and the estate's retirement ledger leaves "whether
   verification harnesses are admitted test floor or declared readings" as a
   builder decision (`hand-authored-code-retirement.md:55-59`). Test floor is
   therefore **not** a home under current law; it is a flagged class (F6).
5. Otherwise → **NO HOME**, the dishonesty findings of §5.

Evidence codes in the table: `D-*` declared; `E-*` eliminated; `T-HARNESS` test
floor; `N-*` no home, with the finding in §5.

---

## 5. Full table


### Consumer projection (tools/src/consumer-projection)

| Path | LOC | Purpose | Home | Evidence | Sterility |
|---|---|---|---|---|---|
| `tools/src/consumer-projection/application/consumer-assurance-service.ts` | 277 | Consumer projection: Consumer assurance service. | eliminated | E-VER | 90 |
| `tools/src/consumer-projection/application/consumer-capability-compiler.ts` | 284 | Consumer projection: Consumer capability compiler. | declared(1) | D-COMPILER | 120 |
| `tools/src/consumer-projection/application/consumer-database-artifact-emitter.ts` | 259 | Consumer projection: Consumer database artifact emitter. | NO HOME | N-AUTH | 65 |
| `tools/src/consumer-projection/application/consumer-execution-embodiment-compiler.ts` | 458 | Consumer projection: Consumer execution embodiment compiler. | eliminated | E-MAT | 220 |
| `tools/src/consumer-projection/application/consumer-projection-plan-builder.ts` | 311 | Consumer projection: Consumer projection plan builder. | eliminated | E-MAT | 96 |
| `tools/src/consumer-projection/authority/consumer-capability-composer.ts` | 52 | Consumer projection: Consumer capability composer. | declared(1) | D-COMPILER | 17 |
| `tools/src/consumer-projection/authority/gherkin-scenario-graph-builder.ts` | 38 | Consumer projection: Gherkin scenario graph builder. | declared(1) | D-COMPILER | 9 |
| `tools/src/consumer-projection/authority/platform-responsibility-resolver.ts` | 138 | Consumer projection: Platform responsibility resolver. | declared(1) | D-COMPILER | 40 |
| `tools/src/consumer-projection/authority/semantic-transition-graph-builder.ts` | 72 | Consumer projection: Semantic transition graph builder. | declared(1) | D-COMPILER | 28 |
| `tools/src/consumer-projection/model/canonical-consumer-capability.ts` | 68 | Consumer projection: Canonical consumer capability. | declared(1) | D-CONTRACT | 14 |
| `tools/src/consumer-projection/model/consumer-execution-embodiment-plan.ts` | 69 | Consumer projection: Consumer execution embodiment plan. | declared(1) | D-CONTRACT | 6 |
| `tools/src/consumer-projection/model/consumer-projection-plan.ts` | 86 | Consumer projection: Consumer projection plan. | declared(1) | D-CONTRACT | 6 |
| `tools/src/consumer-projection/model/consumer-workspace-facts.ts` | 163 | Consumer projection: Consumer workspace facts. | declared(1) | D-CONTRACT | 9 |
| `tools/src/consumer-projection/model/platform-mechanic-conformance.ts` | 39 | Consumer projection: Platform mechanic conformance. | declared(1) | D-CONTRACT | 6 |
| `tools/src/consumer-projection/model/platform-responsibility-resolution.ts` | 38 | Consumer projection: Platform responsibility resolution. | declared(1) | D-CONTRACT | 2 |
| `tools/src/consumer-projection/projection/csharp/capability-execution-emitter.ts` | 2068 | Consumer projector (csharp): Capability execution emitter. | NO HOME | N-PROJ | 1076 |
| `tools/src/consumer-projection/projection/csharp/expression-emitter.ts` | 759 | Consumer projector (csharp): Expression emitter. | NO HOME | N-PROJ | 477 |
| `tools/src/consumer-projection/projection/csharp/mechanic-registry.ts` | 105 | Consumer projector (csharp): Mechanic registry. | NO HOME | N-PROJ | 29 |
| `tools/src/consumer-projection/projection/expression-emitter.ts` | 407 | Consumer projector (expression-emitter.ts): Expression emitter. | NO HOME | N-PROJ | 257 |
| `tools/src/consumer-projection/projection/mechanic-registry.ts` | 382 | Consumer projector (mechanic-registry.ts): Mechanic registry. | NO HOME | N-PROJ | 131 |
| `tools/src/consumer-projection/projection/node/capability-execution-emitter.ts` | 1662 | Consumer projector (node): Capability execution emitter. | NO HOME | N-PROJ | 880 |
| `tools/src/consumer-projection/projection/pattern-binder.ts` | 819 | Consumer projector (pattern-binder.ts): Pattern binder. | NO HOME | N-PROJ | 330 |
| `tools/src/consumer-projection/projection/python/capability-execution-emitter.ts` | 1578 | Consumer projector (python): Capability execution emitter. | NO HOME | N-PROJ | 557 |
| `tools/src/consumer-projection/projection/python/expression-emitter.ts` | 566 | Consumer projector (python): Expression emitter. | NO HOME | N-PROJ | 267 |
| `tools/src/consumer-projection/proof/assertion-evaluator.ts` | 23 | Consumer projection: Assertion evaluator. | eliminated | E-VER | 11 |
| `tools/src/consumer-projection/proof/domain-isolation-evaluator.ts` | 44 | Consumer projection: Domain isolation evaluator. | eliminated | E-VER | 13 |
| `tools/src/consumer-projection/proof/experience-closure-observer.ts` | 56 | Consumer projection: Experience closure observer. | eliminated | E-VER | 21 |
| `tools/src/consumer-projection/proof/mechanic-conformance-observer.ts` | 45 | Consumer projection: Mechanic conformance observer. | eliminated | E-VER | 14 |
| `tools/src/consumer-projection/proof/mechanical-sterility-evaluator.ts` | 147 | Consumer projection: Mechanical sterility evaluator. | eliminated | E-VER | 106 |
| `tools/src/consumer-projection/proof/projection-equivalence-observer.ts` | 86 | Consumer projection: Projection equivalence observer. | eliminated | E-VER | 27 |
| `tools/src/consumer-projection/proof/query-closure-observer.ts` | 50 | Consumer projection: Query closure observer. | eliminated | E-VER | 11 |
| `tools/src/consumer-projection/providers/common/consumer-query-projector.ts` | 64 | Consumer projection: Consumer query projector. | eliminated | E-MAT | 10 |
| `tools/src/consumer-projection/providers/common/expected-telemetry-projector.ts` | 29 | Consumer projection: Expected telemetry projector. | eliminated | E-MAT | 7 |
| `tools/src/consumer-projection/providers/consumer-application-provider.ts` | 19 | Consumer projection: Consumer application provider. | eliminated | E-MAT | 1 |
| `tools/src/consumer-projection/providers/csharp/consumer-application-provider.ts` | 559 | Consumer projection: Consumer application provider. | eliminated | E-MAT | 236 |
| `tools/src/consumer-projection/providers/node/consumer-application-provider.ts` | 49 | Consumer projection: Consumer application provider. | eliminated | E-MAT | 5 |
| `tools/src/consumer-projection/providers/python/consumer-application-provider.ts` | 22 | Consumer projection: Consumer application provider. | eliminated | E-MAT | 1 |

### Projection (tools/src/projection)

| Path | LOC | Purpose | Home | Evidence | Sterility |
|---|---|---|---|---|---|
| `tools/src/projection/ir/execution-graph-builder.ts` | 111 | Projection: Execution graph builder. | declared(1) | D-CONTRACT | 65 |
| `tools/src/projection/ir/json-schema-type-graph-builder.ts` | 192 | Projection: JSON schema type graph builder. | declared(1) | D-CONTRACT | 74 |
| `tools/src/projection/ir/schema-mechanics.ts` | 97 | Projection: Schema mechanics. | declared(1) | D-CONTRACT | 38 |
| `tools/src/projection/ir/target-projection-graph-builder.ts` | 335 | Projection: Target projection graph builder. | declared(1) | D-CONTRACT | 135 |
| `tools/src/projection/model/canonical-execution-graph.ts` | 19 | Projection: Canonical execution graph. | declared(1) | D-CONTRACT | 2 |
| `tools/src/projection/model/canonical-type-graph.ts` | 79 | Projection: Canonical type graph. | declared(1) | D-CONTRACT | 3 |
| `tools/src/projection/model/execution-pattern.ts` | 146 | Projection: Execution pattern. | declared(1) | D-CONTRACT | 31 |
| `tools/src/projection/model/language-target-registration.ts` | 58 | Projection: Language target registration. | declared(1) | D-CONTRACT | 11 |
| `tools/src/projection/model/projection-plan.ts` | 15 | Projection: Projection plan. | declared(1) | D-CONTRACT | 1 |
| `tools/src/projection/model/projection-profile.ts` | 37 | Projection: Projection profile. | declared(1) | D-CONTRACT | 11 |
| `tools/src/projection/model/shape-evidence.ts` | 11 | Projection: Shape evidence. | declared(1) | D-CONTRACT | 2 |
| `tools/src/projection/model/target-execution-graph.ts` | 22 | Projection: Target execution graph. | declared(1) | D-CONTRACT | 2 |
| `tools/src/projection/model/target-projection-graph.ts` | 40 | Projection: Target projection graph. | declared(1) | D-CONTRACT | 2 |
| `tools/src/projection/proof/csharp-projected-shape-observer.ts` | 39 | Projection: C# projected shape observer. | eliminated | E-VER | 17 |
| `tools/src/projection/proof/go-projected-shape-observer.ts` | 33 | Projection: Go projected shape observer. | eliminated | E-VER | 12 |
| `tools/src/projection/proof/java-projected-shape-observer.ts` | 45 | Projection: Java projected shape observer. | eliminated | E-VER | 22 |
| `tools/src/projection/proof/node-projected-shape-observer.ts` | 35 | Projection: Node projected shape observer. | eliminated | E-VER | 23 |
| `tools/src/projection/proof/output-isolation.ts` | 28 | Projection: Output isolation. | eliminated | E-VER | 8 |
| `tools/src/projection/proof/projected-shape-observer-registry.ts` | 25 | Projection: Projected shape observer registry. | eliminated | E-VER | 15 |
| `tools/src/projection/proof/projected-shape-observer.ts` | 13 | Projection: Projected shape observer. | eliminated | E-VER | 2 |
| `tools/src/projection/proof/projection-observation.ts` | 40 | Projection: Projection observation. | eliminated | E-VER | 3 |
| `tools/src/projection/proof/python-projected-shape-observer.ts` | 32 | Projection: Python projected shape observer. | eliminated | E-VER | 19 |
| `tools/src/projection/proof/shape-observer-mechanics.ts` | 33 | Projection: Shape observer mechanics. | eliminated | E-VER | 17 |
| `tools/src/projection/providers/csharp/execution-projection-provider.ts` | 12 | Projection provider (csharp): Execution projection provider. | eliminated | E-MAT | 1 |
| `tools/src/projection/providers/csharp/structural-projection-provider.ts` | 36 | Projection provider (csharp): Structural projection provider. | eliminated | E-MAT | 16 |
| `tools/src/projection/providers/execution-projection-provider.ts` | 8 | Projection provider (execution-projection-provider.ts): Execution projection provider. | eliminated | E-MAT | 1 |
| `tools/src/projection/providers/execution-provider-registry.ts` | 25 | Projection provider (execution-provider-registry.ts): Execution provider registry. | eliminated | E-MAT | 15 |
| `tools/src/projection/providers/execution-rendering.ts` | 41 | Projection provider (execution-rendering.ts): Execution rendering. | eliminated | E-MAT | 22 |
| `tools/src/projection/providers/execution-template-catalog.ts` | 79 | Projection provider (execution-template-catalog.ts): Execution template catalog. | eliminated | E-MAT | 121 |
| `tools/src/projection/providers/go/execution-projection-provider.ts` | 12 | Projection provider (go): Execution projection provider. | eliminated | E-MAT | 1 |
| `tools/src/projection/providers/go/structural-projection-provider.ts` | 59 | Projection provider (go): Structural projection provider. | eliminated | E-MAT | 17 |
| `tools/src/projection/providers/java/execution-projection-provider.ts` | 12 | Projection provider (java): Execution projection provider. | eliminated | E-MAT | 1 |
| `tools/src/projection/providers/java/structural-projection-provider.ts` | 48 | Projection provider (java): Structural projection provider. | eliminated | E-MAT | 15 |
| `tools/src/projection/providers/node/execution-projection-provider.ts` | 12 | Projection provider (node): Execution projection provider. | eliminated | E-MAT | 1 |
| `tools/src/projection/providers/node/naming.ts` | 16 | Projection provider (node): Naming. | eliminated | E-MAT | 9 |
| `tools/src/projection/providers/node/structural-projection-provider.ts` | 60 | Projection provider (node): Structural projection provider. | eliminated | E-MAT | 21 |
| `tools/src/projection/providers/python/execution-projection-provider.ts` | 12 | Projection provider (python): Execution projection provider. | eliminated | E-MAT | 1 |
| `tools/src/projection/providers/python/structural-projection-provider.ts` | 73 | Projection provider (python): Structural projection provider. | eliminated | E-MAT | 28 |
| `tools/src/projection/providers/rendering.ts` | 31 | Projection provider (rendering.ts): Rendering. | eliminated | E-MAT | 9 |
| `tools/src/projection/providers/structural-projection-provider.ts` | 8 | Projection provider (structural-projection-provider.ts): Structural projection provider. | eliminated | E-MAT | 1 |
| `tools/src/projection/providers/structural-provider-registry.ts` | 25 | Projection provider (structural-provider-registry.ts): Structural provider registry. | eliminated | E-MAT | 15 |
| `tools/src/projection/toolchain/target-toolchain.ts` | 20 | Projection: Target toolchain. | eliminated | E-MAT | 3 |

### Declared tooling capabilities (tools/src/capabilities)

| Path | LOC | Purpose | Home | Evidence | Sterility |
|---|---|---|---|---|---|
| `tools/src/capabilities/api-interface-projection/derive-api-operation-graph/model.ts` | 158 | Declared tooling capability 'derive-api-operation-graph' (capabilities) â€” contract model. | declared(1) | D-CAP | 7 |
| `tools/src/capabilities/api-interface-projection/derive-api-operation-graph/obligation.ts` | 36 | Declared tooling capability 'derive-api-operation-graph' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/api-interface-projection/derive-api-operation-graph/provider.ts` | 308 | Declared tooling capability 'derive-api-operation-graph' (capabilities) â€” provider body. | declared(1) | D-CAP | 174 |
| `tools/src/capabilities/api-interface-projection/project-openapi-description/model.ts` | 147 | Declared tooling capability 'project-openapi-description' (capabilities) â€” contract model. | declared(1) | D-CAP | 8 |
| `tools/src/capabilities/api-interface-projection/project-openapi-description/obligation.ts` | 64 | Declared tooling capability 'project-openapi-description' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 11 |
| `tools/src/capabilities/api-interface-projection/project-openapi-description/provider.ts` | 362 | Declared tooling capability 'project-openapi-description' (capabilities) â€” provider body. | declared(1) | D-CAP | 163 |
| `tools/src/capabilities/conformance-evidence-publication/derive-cross-language-equivalence/model.ts` | 30 | Declared tooling capability 'derive-cross-language-equivalence' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/conformance-evidence-publication/derive-cross-language-equivalence/obligation.ts` | 30 | Declared tooling capability 'derive-cross-language-equivalence' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/conformance-evidence-publication/derive-cross-language-equivalence/provider.ts` | 38 | Declared tooling capability 'derive-cross-language-equivalence' (capabilities) â€” provider body. | declared(1) | D-CAP | 8 |
| `tools/src/capabilities/conformance-evidence-publication/observe-language-behavior/model.ts` | 17 | Declared tooling capability 'observe-language-behavior' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/conformance-evidence-publication/observe-language-behavior/obligation.ts` | 2 | Declared tooling capability 'observe-language-behavior' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/conformance-evidence-publication/observe-language-behavior/provider.ts` | 2 | Declared tooling capability 'observe-language-behavior' (capabilities) â€” provider body. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/conformance-evidence-publication/publish-implementation-evidence/model.ts` | 18 | Declared tooling capability 'publish-implementation-evidence' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/conformance-evidence-publication/publish-implementation-evidence/obligation.ts` | 23 | Declared tooling capability 'publish-implementation-evidence' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/conformance-evidence-publication/publish-implementation-evidence/provider.ts` | 2 | Declared tooling capability 'publish-implementation-evidence' (capabilities) â€” provider body. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-assurance/determine-platform-mechanic-conformance/model.ts` | 16 | Declared tooling capability 'determine-platform-mechanic-conformance' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-assurance/determine-platform-mechanic-conformance/obligation.ts` | 17 | Declared tooling capability 'determine-platform-mechanic-conformance' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/consumer-assurance/determine-platform-mechanic-conformance/provider.ts` | 10 | Declared tooling capability 'determine-platform-mechanic-conformance' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-assurance/prove-cross-apply-ui-parity/model.ts` | 30 | Declared tooling capability 'prove-cross-apply-ui-parity' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-assurance/prove-cross-apply-ui-parity/obligation.ts` | 17 | Declared tooling capability 'prove-cross-apply-ui-parity' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/consumer-assurance/prove-cross-apply-ui-parity/provider.ts` | 10 | Declared tooling capability 'prove-cross-apply-ui-parity' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-assurance/prove-cross-target-projection-equivalence/model.ts` | 17 | Declared tooling capability 'prove-cross-target-projection-equivalence' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-assurance/prove-cross-target-projection-equivalence/obligation.ts` | 11 | Declared tooling capability 'prove-cross-target-projection-equivalence' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/consumer-assurance/prove-cross-target-projection-equivalence/provider.ts` | 9 | Declared tooling capability 'prove-cross-target-projection-equivalence' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-assurance/prove-domain-isolation/model.ts` | 13 | Declared tooling capability 'prove-domain-isolation' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-assurance/prove-domain-isolation/obligation.ts` | 11 | Declared tooling capability 'prove-domain-isolation' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/consumer-assurance/prove-domain-isolation/provider.ts` | 7 | Declared tooling capability 'prove-domain-isolation' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-assurance/prove-experience-closure/model.ts` | 16 | Declared tooling capability 'prove-experience-closure' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-assurance/prove-experience-closure/obligation.ts` | 11 | Declared tooling capability 'prove-experience-closure' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-assurance/prove-experience-closure/provider.ts` | 7 | Declared tooling capability 'prove-experience-closure' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-assurance/prove-mechanical-sterility/model.ts` | 10 | Declared tooling capability 'prove-mechanical-sterility' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-assurance/prove-mechanical-sterility/obligation.ts` | 11 | Declared tooling capability 'prove-mechanical-sterility' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/consumer-assurance/prove-mechanical-sterility/provider.ts` | 7 | Declared tooling capability 'prove-mechanical-sterility' (capabilities) â€” provider body. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-assurance/prove-query-closure/model.ts` | 12 | Declared tooling capability 'prove-query-closure' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-assurance/prove-query-closure/obligation.ts` | 11 | Declared tooling capability 'prove-query-closure' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-assurance/prove-query-closure/provider.ts` | 7 | Declared tooling capability 'prove-query-closure' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-capability-compilation/admit-consumer-source-facts/model.ts` | 15 | Declared tooling capability 'admit-consumer-source-facts' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-capability-compilation/admit-consumer-source-facts/obligation.ts` | 13 | Declared tooling capability 'admit-consumer-source-facts' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-capability-compilation/admit-consumer-source-facts/provider.ts` | 24 | Declared tooling capability 'admit-consumer-source-facts' (capabilities) â€” provider body. | declared(1) | D-CAP | 8 |
| `tools/src/capabilities/consumer-capability-compilation/compose-canonical-scenario-graph/model.ts` | 14 | Declared tooling capability 'compose-canonical-scenario-graph' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-capability-compilation/compose-canonical-scenario-graph/obligation.ts` | 15 | Declared tooling capability 'compose-canonical-scenario-graph' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/consumer-capability-compilation/compose-canonical-scenario-graph/provider.ts` | 28 | Declared tooling capability 'compose-canonical-scenario-graph' (capabilities) â€” provider body. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/consumer-capability-compilation/construct-consumer-projection-plan/model.ts` | 31 | Declared tooling capability 'construct-consumer-projection-plan' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/consumer-capability-compilation/construct-consumer-projection-plan/obligation.ts` | 15 | Declared tooling capability 'construct-consumer-projection-plan' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/consumer-capability-compilation/construct-consumer-projection-plan/provider.ts` | 27 | Declared tooling capability 'construct-consumer-projection-plan' (capabilities) â€” provider body. | declared(1) | D-CAP | 8 |
| `tools/src/capabilities/consumer-capability-compilation/prove-projected-sterility-before-publication/model.ts` | 13 | Declared tooling capability 'prove-projected-sterility-before-publication' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-capability-compilation/prove-projected-sterility-before-publication/obligation.ts` | 16 | Declared tooling capability 'prove-projected-sterility-before-publication' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/consumer-capability-compilation/prove-projected-sterility-before-publication/provider.ts` | 13 | Declared tooling capability 'prove-projected-sterility-before-publication' (capabilities) â€” provider body. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/consumer-capability-compilation/publish-projected-capability/model.ts` | 18 | Declared tooling capability 'publish-projected-capability' (capabilities) â€” contract model. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-capability-compilation/publish-projected-capability/obligation.ts` | 13 | Declared tooling capability 'publish-projected-capability' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-capability-compilation/publish-projected-capability/provider.ts` | 17 | Declared tooling capability 'publish-projected-capability' (capabilities) â€” provider body. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/consumer-capability-compilation/resolve-platform-responsibilities/model.ts` | 20 | Declared tooling capability 'resolve-platform-responsibilities' (capabilities) â€” contract model. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/consumer-capability-compilation/resolve-platform-responsibilities/obligation.ts` | 18 | Declared tooling capability 'resolve-platform-responsibilities' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/consumer-capability-compilation/resolve-platform-responsibilities/provider.ts` | 27 | Declared tooling capability 'resolve-platform-responsibilities' (capabilities) â€” provider body. | declared(1) | D-CAP | 7 |
| `tools/src/capabilities/execution-vector-projection/derive-canonical-execution-graph/model.ts` | 12 | Declared tooling capability 'derive-canonical-execution-graph' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/execution-vector-projection/derive-canonical-execution-graph/obligation.ts` | 12 | Declared tooling capability 'derive-canonical-execution-graph' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/execution-vector-projection/derive-canonical-execution-graph/provider.ts` | 10 | Declared tooling capability 'derive-canonical-execution-graph' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/execution-vector-projection/derive-target-execution-graph/model.ts` | 18 | Declared tooling capability 'derive-target-execution-graph' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/execution-vector-projection/derive-target-execution-graph/obligation.ts` | 12 | Declared tooling capability 'derive-target-execution-graph' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/execution-vector-projection/derive-target-execution-graph/provider.ts` | 10 | Declared tooling capability 'derive-target-execution-graph' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/execution-vector-projection/prove-projected-execution-behavior/model.ts` | 14 | Declared tooling capability 'prove-projected-execution-behavior' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/execution-vector-projection/prove-projected-execution-behavior/obligation.ts` | 17 | Declared tooling capability 'prove-projected-execution-behavior' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 9 |
| `tools/src/capabilities/execution-vector-projection/prove-projected-execution-behavior/provider.ts` | 9 | Declared tooling capability 'prove-projected-execution-behavior' (capabilities) â€” provider body. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/execution-vector-projection/reproduce-target-execution-vector/model.ts` | 18 | Declared tooling capability 'reproduce-target-execution-vector' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/execution-vector-projection/reproduce-target-execution-vector/obligation.ts` | 14 | Declared tooling capability 'reproduce-target-execution-vector' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/execution-vector-projection/reproduce-target-execution-vector/provider.ts` | 10 | Declared tooling capability 'reproduce-target-execution-vector' (capabilities) â€” provider body. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/kernel-implementation-admission/admit-execution-vector/model.ts` | 23 | Declared tooling capability 'admit-execution-vector' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/kernel-implementation-admission/admit-execution-vector/obligation.ts` | 10 | Declared tooling capability 'admit-execution-vector' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/kernel-implementation-admission/admit-execution-vector/provider.ts` | 9 | Declared tooling capability 'admit-execution-vector' (capabilities) â€” provider body. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/kernel-implementation-admission/admit-kernel-specification/model.ts` | 33 | Declared tooling capability 'admit-kernel-specification' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/kernel-implementation-admission/admit-kernel-specification/obligation.ts` | 10 | Declared tooling capability 'admit-kernel-specification' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/kernel-implementation-admission/admit-kernel-specification/provider.ts` | 9 | Declared tooling capability 'admit-kernel-specification' (capabilities) â€” provider body. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/kernel-implementation-admission/admit-schema-family/model.ts` | 21 | Declared tooling capability 'admit-schema-family' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/kernel-implementation-admission/admit-schema-family/obligation.ts` | 10 | Declared tooling capability 'admit-schema-family' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/kernel-implementation-admission/admit-schema-family/provider.ts` | 9 | Declared tooling capability 'admit-schema-family' (capabilities) â€” provider body. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/kernel-implementation-admission/decide-implementation-admission/model.ts` | 58 | Declared tooling capability 'decide-implementation-admission' (capabilities) â€” contract model. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/kernel-implementation-admission/decide-implementation-admission/obligation.ts` | 47 | Declared tooling capability 'decide-implementation-admission' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 13 |
| `tools/src/capabilities/kernel-implementation-admission/decide-implementation-admission/provider.ts` | 20 | Declared tooling capability 'decide-implementation-admission' (capabilities) â€” provider body. | declared(1) | D-CAP | 21 |
| `tools/src/capabilities/kernel-implementation-admission/determine-authority-conformance/model.ts` | 75 | Declared tooling capability 'determine-authority-conformance' (capabilities) â€” contract model. | declared(1) | D-CAP | 22 |
| `tools/src/capabilities/kernel-implementation-admission/determine-authority-conformance/obligation.ts` | 43 | Declared tooling capability 'determine-authority-conformance' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 5 |
| `tools/src/capabilities/kernel-implementation-admission/determine-authority-conformance/provider.ts` | 77 | Declared tooling capability 'determine-authority-conformance' (capabilities) â€” provider body. | declared(1) | D-CAP | 16 |
| `tools/src/capabilities/kernel-implementation-admission/determine-behavioral-conformance/model.ts` | 21 | Declared tooling capability 'determine-behavioral-conformance' (capabilities) â€” contract model. | declared(1) | D-CAP | 15 |
| `tools/src/capabilities/kernel-implementation-admission/determine-behavioral-conformance/obligation.ts` | 2 | Declared tooling capability 'determine-behavioral-conformance' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/kernel-implementation-admission/determine-behavioral-conformance/provider.ts` | 2 | Declared tooling capability 'determine-behavioral-conformance' (capabilities) â€” provider body. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/kernel-implementation-admission/determine-execution-closure/model.ts` | 32 | Declared tooling capability 'determine-execution-closure' (capabilities) â€” contract model. | declared(1) | D-CAP | 12 |
| `tools/src/capabilities/kernel-implementation-admission/determine-execution-closure/obligation.ts` | 2 | Declared tooling capability 'determine-execution-closure' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/kernel-implementation-admission/determine-execution-closure/provider.ts` | 2 | Declared tooling capability 'determine-execution-closure' (capabilities) â€” provider body. | declared(1) | D-CAP | 5 |
| `tools/src/capabilities/kernel-implementation-admission/determine-execution-conformance/model.ts` | 26 | Declared tooling capability 'determine-execution-conformance' (capabilities) â€” contract model. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/kernel-implementation-admission/determine-execution-conformance/obligation.ts` | 2 | Declared tooling capability 'determine-execution-conformance' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/kernel-implementation-admission/determine-execution-conformance/provider.ts` | 3 | Declared tooling capability 'determine-execution-conformance' (capabilities) â€” provider body. | declared(1) | D-CAP | 14 |
| `tools/src/capabilities/kernel-implementation-admission/determine-shape-conformance/model.ts` | 34 | Declared tooling capability 'determine-shape-conformance' (capabilities) â€” contract model. | declared(1) | D-CAP | 6 |
| `tools/src/capabilities/kernel-implementation-admission/determine-shape-conformance/obligation.ts` | 2 | Declared tooling capability 'determine-shape-conformance' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/kernel-implementation-admission/determine-shape-conformance/provider.ts` | 13 | Declared tooling capability 'determine-shape-conformance' (capabilities) â€” provider body. | declared(1) | D-CAP | 16 |
| `tools/src/capabilities/projected-implementation-promotion/determine-candidate-origin/model.ts` | 5 | Declared tooling capability 'determine-candidate-origin' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/projected-implementation-promotion/determine-candidate-origin/obligation.ts` | 9 | Declared tooling capability 'determine-candidate-origin' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/projected-implementation-promotion/determine-candidate-origin/provider.ts` | 10 | Declared tooling capability 'determine-candidate-origin' (capabilities) â€” provider body. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/projected-implementation-promotion/preserve-admitted-projection-on-incomplete-regeneration/model.ts` | 4 | Declared tooling capability 'preserve-admitted-projection-on-incomplete-regeneration' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/projected-implementation-promotion/preserve-admitted-projection-on-incomplete-regeneration/obligation.ts` | 9 | Declared tooling capability 'preserve-admitted-projection-on-incomplete-regeneration' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/projected-implementation-promotion/preserve-admitted-projection-on-incomplete-regeneration/provider.ts` | 8 | Declared tooling capability 'preserve-admitted-projection-on-incomplete-regeneration' (capabilities) â€” provider body. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/projected-implementation-promotion/promote-proven-implementation/model.ts` | 4 | Declared tooling capability 'promote-proven-implementation' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/projected-implementation-promotion/promote-proven-implementation/obligation.ts` | 10 | Declared tooling capability 'promote-proven-implementation' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/projected-implementation-promotion/promote-proven-implementation/provider.ts` | 8 | Declared tooling capability 'promote-proven-implementation' (capabilities) â€” provider body. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/projected-implementation-promotion/stage-projected-candidate/model.ts` | 5 | Declared tooling capability 'stage-projected-candidate' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/projected-implementation-promotion/stage-projected-candidate/obligation.ts` | 10 | Declared tooling capability 'stage-projected-candidate' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/projected-implementation-promotion/stage-projected-candidate/provider.ts` | 6 | Declared tooling capability 'stage-projected-candidate' (capabilities) â€” provider body. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/realization-planning/construct-deterministic-realization-plan/model.ts` | 346 | Declared tooling capability 'construct-deterministic-realization-plan' (capabilities) â€” contract model. | declared(1) | D-CAP | 14 |
| `tools/src/capabilities/realization-planning/construct-deterministic-realization-plan/obligation.ts` | 32 | Declared tooling capability 'construct-deterministic-realization-plan' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/realization-planning/construct-deterministic-realization-plan/provider.ts` | 615 | Declared tooling capability 'construct-deterministic-realization-plan' (capabilities) â€” provider body. | declared(1) | D-CAP | 216 |
| `tools/src/capabilities/realization-planning/resolve-registered-realization-plan/model.ts` | 126 | Declared tooling capability 'resolve-registered-realization-plan' (capabilities) â€” contract model. | declared(1) | D-CAP | 13 |
| `tools/src/capabilities/realization-planning/resolve-registered-realization-plan/obligation.ts` | 31 | Declared tooling capability 'resolve-registered-realization-plan' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/realization-planning/resolve-registered-realization-plan/provider.ts` | 291 | Declared tooling capability 'resolve-registered-realization-plan' (capabilities) â€” provider body. | declared(1) | D-CAP | 96 |
| `tools/src/capabilities/realization-planning/verify-realization-lifecycle-contracts/model.ts` | 45 | Declared tooling capability 'verify-realization-lifecycle-contracts' (capabilities) â€” contract model. | declared(1) | D-CAP | 7 |
| `tools/src/capabilities/realization-planning/verify-realization-lifecycle-contracts/obligation.ts` | 26 | Declared tooling capability 'verify-realization-lifecycle-contracts' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/realization-planning/verify-realization-lifecycle-contracts/provider.ts` | 96 | Declared tooling capability 'verify-realization-lifecycle-contracts' (capabilities) â€” provider body. | declared(1) | D-CAP | 47 |
| `tools/src/capabilities/structural-model-projection/derive-canonical-type-graph/model.ts` | 20 | Declared tooling capability 'derive-canonical-type-graph' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/structural-model-projection/derive-canonical-type-graph/obligation.ts` | 13 | Declared tooling capability 'derive-canonical-type-graph' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/structural-model-projection/derive-canonical-type-graph/provider.ts` | 11 | Declared tooling capability 'derive-canonical-type-graph' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/structural-model-projection/derive-target-projection-graph/model.ts` | 21 | Declared tooling capability 'derive-target-projection-graph' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/structural-model-projection/derive-target-projection-graph/obligation.ts` | 12 | Declared tooling capability 'derive-target-projection-graph' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/structural-model-projection/derive-target-projection-graph/provider.ts` | 10 | Declared tooling capability 'derive-target-projection-graph' (capabilities) â€” provider body. | declared(1) | D-CAP | 2 |
| `tools/src/capabilities/structural-model-projection/determine-projected-shape-equivalence/model.ts` | 29 | Declared tooling capability 'determine-projected-shape-equivalence' (capabilities) â€” contract model. | declared(1) | D-CAP | 5 |
| `tools/src/capabilities/structural-model-projection/determine-projected-shape-equivalence/obligation.ts` | 32 | Declared tooling capability 'determine-projected-shape-equivalence' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/structural-model-projection/determine-projected-shape-equivalence/provider.ts` | 14 | Declared tooling capability 'determine-projected-shape-equivalence' (capabilities) â€” provider body. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/structural-model-projection/reproduce-target-structural-model/model.ts` | 23 | Declared tooling capability 'reproduce-target-structural-model' (capabilities) â€” contract model. | declared(1) | D-CAP | 5 |
| `tools/src/capabilities/structural-model-projection/reproduce-target-structural-model/obligation.ts` | 45 | Declared tooling capability 'reproduce-target-structural-model' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 7 |
| `tools/src/capabilities/structural-model-projection/reproduce-target-structural-model/provider.ts` | 14 | Declared tooling capability 'reproduce-target-structural-model' (capabilities) â€” provider body. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/workspace-governance/admit-language-declaration/model.ts` | 35 | Declared tooling capability 'admit-language-declaration' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/workspace-governance/admit-language-declaration/obligation.ts` | 27 | Declared tooling capability 'admit-language-declaration' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/workspace-governance/admit-language-declaration/provider.ts` | 36 | Declared tooling capability 'admit-language-declaration' (capabilities) â€” provider body. | declared(1) | D-CAP | 16 |
| `tools/src/capabilities/workspace-governance/determine-active-language-obligations/model.ts` | 32 | Declared tooling capability 'determine-active-language-obligations' (capabilities) â€” contract model. | declared(1) | D-CAP | 1 |
| `tools/src/capabilities/workspace-governance/determine-active-language-obligations/obligation.ts` | 36 | Declared tooling capability 'determine-active-language-obligations' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 5 |
| `tools/src/capabilities/workspace-governance/determine-active-language-obligations/provider.ts` | 27 | Declared tooling capability 'determine-active-language-obligations' (capabilities) â€” provider body. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/workspace-governance/discover-language-bindings/model.ts` | 44 | Declared tooling capability 'discover-language-bindings' (capabilities) â€” contract model. | declared(1) | D-CAP | 3 |
| `tools/src/capabilities/workspace-governance/discover-language-bindings/obligation.ts` | 33 | Declared tooling capability 'discover-language-bindings' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 5 |
| `tools/src/capabilities/workspace-governance/discover-language-bindings/provider.ts` | 35 | Declared tooling capability 'discover-language-bindings' (capabilities) â€” provider body. | declared(1) | D-CAP | 8 |
| `tools/src/capabilities/workspace-governance/verify-governed-placement/model.ts` | 46 | Declared tooling capability 'verify-governed-placement' (capabilities) â€” contract model. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/workspace-governance/verify-governed-placement/obligation.ts` | 20 | Declared tooling capability 'verify-governed-placement' (capabilities) â€” obligation contract. | declared(1) | D-CAP | 4 |
| `tools/src/capabilities/workspace-governance/verify-governed-placement/provider.ts` | 107 | Declared tooling capability 'verify-governed-placement' (capabilities) â€” provider body. | declared(1) | D-CAP | 36 |

### Adapters and ports (tools/src/adapters, tools/src/ports)

| Path | LOC | Purpose | Home | Evidence | Sterility |
|---|---|---|---|---|---|
| `tools/src/adapters/api-interface-projection/node-api-interface-authority-loader.ts` | 161 | Adapter: Node API interface authority loader. | declared(1) | D-ADAPTER | 69 |
| `tools/src/adapters/authority/node-authority-conformance-repository.ts` | 107 | Adapter: Node authority conformance repository. | declared(1) | D-ADAPTER | 30 |
| `tools/src/adapters/authority/node-authority-source-inspector.ts` | 135 | Adapter: Node authority source inspector. | declared(1) | D-ADAPTER | 62 |
| `tools/src/adapters/clock/system-clock.ts` | 7 | Adapter: System clock. | declared(1) | D-ADAPTER | 2 |
| `tools/src/adapters/conformance/node-conformance-authority-repository.ts` | 51 | Adapter: Node conformance authority repository. | declared(1) | D-ADAPTER | 61 |
| `tools/src/adapters/conformance/node-conformance-evidence-store.ts` | 2 | Adapter: Node conformance evidence store. | declared(1) | D-ADAPTER | 6 |
| `tools/src/adapters/consumer-projection/annotated-gherkin-parser.ts` | 82 | Adapter: Annotated Gherkin parser. | declared(1) | D-ADAPTER | 34 |
| `tools/src/adapters/consumer-projection/consumer-platform-input-digest.ts` | 64 | Adapter: Consumer platform input digest. | declared(1) | D-ADAPTER | 14 |
| `tools/src/adapters/consumer-projection/file-source-envelope.ts` | 59 | Adapter: File source envelope. | declared(1) | D-ADAPTER | 22 |
| `tools/src/adapters/consumer-projection/node-authority-transformation-semantic-read-model-provider.ts` | 163 | Adapter: Node authority transformation semantic read model provider. | declared(1) | D-ADAPTER | 46 |
| `tools/src/adapters/consumer-projection/node-consumer-assurance-evidence-store.ts` | 20 | Adapter: Node consumer assurance evidence store. | declared(1) | D-ADAPTER | 6 |
| `tools/src/adapters/consumer-projection/node-consumer-assurance-repository.ts` | 63 | Adapter: Node consumer assurance repository. | declared(1) | D-ADAPTER | 13 |
| `tools/src/adapters/consumer-projection/node-consumer-platform-toolchains.ts` | 117 | Adapter: Node consumer platform toolchains. | eliminated | E-MAT | 42 |
| `tools/src/adapters/consumer-projection/node-consumer-projection-artifact-store.ts` | 149 | Adapter: Node consumer projection artifact store. | eliminated | E-MAT | 74 |
| `tools/src/adapters/consumer-projection/node-consumer-runtime-toolchain.ts` | 108 | Adapter: Node consumer runtime toolchain. | eliminated | E-MAT | 46 |
| `tools/src/adapters/consumer-projection/node-consumer-workspace-repository.ts` | 280 | Adapter: Node consumer workspace repository. | declared(1) | D-ADAPTER | 62 |
| `tools/src/adapters/consumer-projection/node-document-text-source-observation-provider.ts` | 117 | Adapter: Node document text source observation provider. | declared(1) | D-ADAPTER | 21 |
| `tools/src/adapters/consumer-projection/node-domain-isolation-repository.ts` | 49 | Adapter: Node domain isolation repository. | declared(1) | D-ADAPTER | 16 |
| `tools/src/adapters/consumer-projection/node-platform-capability-repository.ts` | 39 | Adapter: Node platform capability repository. | declared(1) | D-ADAPTER | 9 |
| `tools/src/adapters/consumer-projection/node-text-source-observation-provider.ts` | 113 | Adapter: Node text source observation provider. | declared(1) | D-ADAPTER | 21 |
| `tools/src/adapters/contracts/function-contract-admission.ts` | 15 | Adapter: Function contract admission. | declared(1) | D-ADAPTER | 8 |
| `tools/src/adapters/node-scenario-kernel/node-scenario-kernel-runner.ts` | 141 | Adapter: Node scenario kernel runner. | declared(1) | D-ADAPTER | 31 |
| `tools/src/adapters/projection/node-language-target-registry.ts` | 119 | Adapter: Node language target registry. | eliminated | E-MAT | 67 |
| `tools/src/adapters/projection/node-projection-repository.ts` | 82 | Adapter: Node projection repository. | eliminated | E-MAT | 24 |
| `tools/src/adapters/projection/node-target-toolchain.ts` | 273 | Adapter: Node target toolchain. | eliminated | E-MAT | 129 |
| `tools/src/adapters/projection/process-json-projection-provider.ts` | 74 | Adapter: Process JSON projection provider. | eliminated | E-MAT | 27 |
| `tools/src/adapters/projection/transactional-projection-materializer.ts` | 202 | Adapter: Transactional projection materializer. | eliminated | E-MAT | 99 |
| `tools/src/adapters/realization-planning/digest-realization-projector.ts` | 77 | Adapter: Digest realization projector. | eliminated | E-MAT | 9 |
| `tools/src/adapters/realization-planning/file-system-immutable-authority-registry.ts` | 203 | Adapter: File system immutable authority registry. | eliminated | E-MAT | 108 |
| `tools/src/adapters/realization-planning/file-system-realization-planning-authority.ts` | 97 | Adapter: File system realization planning authority. | eliminated | E-MAT | 5 |
| `tools/src/adapters/realization-planning/in-memory-immutable-authority-registry.ts` | 69 | Adapter: In memory immutable authority registry. | test floor | T-HARNESS | 35 |
| `tools/src/adapters/realization-planning/on-demand-realization-policy-decision.ts` | 52 | Adapter: On demand realization policy decision. | declared(1) | D-ADAPTER | 16 |
| `tools/src/adapters/realization-planning/profiled-digest-realization-projector.ts` | 44 | Adapter: Profiled digest realization projector. | eliminated | E-MAT | 9 |
| `tools/src/adapters/realization-planning/profiled-realization-policy-decision.ts` | 76 | Adapter: Profiled realization policy decision. | declared(1) | D-ADAPTER | 25 |
| `tools/src/adapters/telemetry/in-memory-execution-observer.ts` | 9 | Adapter: In memory execution observer. | test floor | T-HARNESS | 2 |
| `tools/src/adapters/ui-parity/node-ui-embodiment-provider-registry.ts` | 99 | Adapter: Node UI embodiment provider registry. | declared(1) | D-ADAPTER | 41 |
| `tools/src/adapters/workspace/language-ecosystem-root.ts` | 13 | Adapter: Language ecosystem root. | declared(1) | D-ADAPTER | 4 |
| `tools/src/adapters/workspace/node-language-binding-repository.ts` | 84 | Adapter: Node language binding repository. | declared(1) | D-ADAPTER | 18 |
| `tools/src/adapters/workspace/node-workspace-governance-repository.ts` | 138 | Adapter: Node workspace governance repository. | declared(1) | D-ADAPTER | 38 |
| `tools/src/ports/capability-ports.ts` | 55 | Port contract: Capability ports. | declared(1) | D-ADAPTER | 3 |
| `tools/src/ports/conformance/conformance-authority-repository.ts` | 10 | Port contract: Conformance authority repository. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/conformance/conformance-evidence-store.ts` | 1 | Port contract: Conformance evidence store. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/conformance/language-toolchain.ts` | 4 | Port contract: Language toolchain. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/conformance/schema-admission.ts` | 15 | Port contract: Schema admission. | declared(1) | D-ADAPTER | 2 |
| `tools/src/ports/consumer-projection/consumer-assurance-evidence-store.ts` | 4 | Port contract: Consumer assurance evidence store. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/consumer-projection/consumer-projection-artifact-store.ts` | 8 | Port contract: Consumer projection artifact store. | declared(1) | D-ADAPTER | 3 |
| `tools/src/ports/consumer-projection/consumer-runtime-toolchain.ts` | 12 | Port contract: Consumer runtime toolchain. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/consumer-projection/consumer-semantic-read-model-provider.ts` | 26 | Port contract: Consumer semantic read model provider. | declared(1) | D-ADAPTER | 2 |
| `tools/src/ports/consumer-projection/consumer-source-observation-provider.ts` | 33 | Port contract: Consumer source observation provider. | declared(1) | D-ADAPTER | 2 |
| `tools/src/ports/consumer-projection/consumer-workspace-repository.ts` | 5 | Port contract: Consumer workspace repository. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/consumer-projection/domain-isolation-repository.ts` | 10 | Port contract: Domain isolation repository. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/consumer-projection/gherkin-parser.ts` | 11 | Port contract: Gherkin parser. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/consumer-projection/platform-capability-repository.ts` | 14 | Port contract: Platform capability repository. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/infrastructure-ports.ts` | 3 | Port contract: Infrastructure ports. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/realization-planning/immutable-authority-registry.ts` | 13 | Port contract: Immutable authority registry. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/realization-planning/realization-policy-decision.ts` | 20 | Port contract: Realization policy decision. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/realization-planning/realization-projector.ts` | 23 | Port contract: Realization projector. | declared(1) | D-ADAPTER | 1 |
| `tools/src/ports/ui-parity/ui-embodiment-provider.ts` | 39 | Port contract: UI embodiment provider. | declared(1) | D-ADAPTER | 1 |

### Interfaces, host, primitives, model, governance, gherkin, conformance

| Path | LOC | Purpose | Home | Evidence | Sterility |
|---|---|---|---|---|---|
| `tools/src/conformance/application/conformance-service.ts` | 93 | Conformance: Conformance service. | declared(1) | D-CONF | 77 |
| `tools/src/conformance/model/conformance-evidence-set.ts` | 54 | Conformance: Conformance evidence set. | declared(1) | D-CONF | 4 |
| `tools/src/conformance/model/runtime-contracts.ts` | 37 | Conformance: Runtime contracts. | declared(1) | D-CONF | 5 |
| `tools/src/conformance/proof/evidence-freshness.ts` | 16 | Conformance: Evidence freshness. | eliminated | E-VER | 2 |
| `tools/src/conformance/proof/execution-closure-mechanics.ts` | 29 | Conformance: Execution closure mechanics. | eliminated | E-VER | 30 |
| `tools/src/conformance/publication/conformance-report-builder.ts` | 2 | Conformance: Conformance report builder. | declared(1) | D-CONF | 8 |
| `tools/src/gherkin/application/canonical-gherkin-compiler.ts` | 833 | Gherkin compiler: Canonical Gherkin compiler. | declared(1) | D-COMPILER | 446 |
| `tools/src/governance/language-ecosystem-layout.ts` | 77 | Governance: Language ecosystem layout. | declared(1) | D-GOV | 22 |
| `tools/src/governance/ui-change-amplification.ts` | 59 | Governance: UI change amplification. | declared(1) | D-GOV | 24 |
| `tools/src/host/load-provider.ts` | 77 | Tool capability host: Load provider. | NO HOME | N-HOST | 40 |
| `tools/src/host/tool-capability-host.ts` | 79 | Tool capability host: Tool capability host. | NO HOME | N-HOST | 18 |
| `tools/src/interfaces/api-interface-projection/run.ts` | 194 | Interface seam: Run. | declared(1) | D-SEAM | 75 |
| `tools/src/interfaces/authority-conformance/run.ts` | 76 | Interface seam: Run. | declared(1) | D-SEAM | 19 |
| `tools/src/interfaces/conformance/admit.ts` | 4 | Interface seam: Admit. | declared(1) | D-SEAM | 13 |
| `tools/src/interfaces/conformance/assert-pinned-reference-observability.ts` | 6 | Interface seam: Assert pinned reference observability. | declared(1) | D-SEAM | 28 |
| `tools/src/interfaces/conformance/observe.ts` | 5 | Interface seam: Observe. | declared(1) | D-SEAM | 23 |
| `tools/src/interfaces/conformance/report.ts` | 4 | Interface seam: Report. | declared(1) | D-SEAM | 12 |
| `tools/src/interfaces/conformance/run-reference-gate.ts` | 46 | Interface seam: Run reference gate. | declared(1) | D-SEAM | 15 |
| `tools/src/interfaces/consumer-projection/assure.ts` | 56 | Interface seam: Assure. | declared(1) | D-SEAM | 8 |
| `tools/src/interfaces/consumer-projection/observe-platform.ts` | 26 | Interface seam: Observe platform. | declared(1) | D-SEAM | 12 |
| `tools/src/interfaces/consumer-projection/project.ts` | 101 | Interface seam: Project. | declared(1) | D-SEAM | 55 |
| `tools/src/interfaces/execution-vector-projection/generate-execution-vector.ts` | 25 | Interface seam: Generate execution vector. | declared(1) | D-SEAM | 5 |
| `tools/src/interfaces/execution-vector-projection/run.ts` | 122 | Interface seam: Run. | declared(1) | D-SEAM | 53 |
| `tools/src/interfaces/governance/check-ui-change-amplification.ts` | 35 | Interface seam: Check UI change amplification. | declared(1) | D-SEAM | 18 |
| `tools/src/interfaces/language-binding-discovery/run.ts` | 75 | Interface seam: Run. | declared(1) | D-SEAM | 19 |
| `tools/src/interfaces/language-declaration-admission/run.ts` | 58 | Interface seam: Run. | declared(1) | D-SEAM | 19 |
| `tools/src/interfaces/language-obligation-determination/run.ts` | 76 | Interface seam: Run. | declared(1) | D-SEAM | 20 |
| `tools/src/interfaces/projected-implementation-promotion/promote-proven-projection.ts` | 73 | Interface seam: Promote proven projection. | declared(1) | D-SEAM | 39 |
| `tools/src/interfaces/projection/evaluate-observation.ts` | 38 | Interface seam: Evaluate observation. | declared(1) | D-SEAM | 6 |
| `tools/src/interfaces/projection/observe-execution.ts` | 73 | Interface seam: Observe execution. | declared(1) | D-SEAM | 27 |
| `tools/src/interfaces/projection/observe-structural.ts` | 104 | Interface seam: Observe structural. | declared(1) | D-SEAM | 32 |
| `tools/src/interfaces/realization-planning/reference-providers.ts` | 18 | Interface seam: Reference providers. | declared(1) | D-SEAM | 5 |
| `tools/src/interfaces/realization-planning/run-file-registered.ts` | 70 | Interface seam: Run file registered. | declared(1) | D-SEAM | 16 |
| `tools/src/interfaces/realization-planning/run-registered.ts` | 67 | Interface seam: Run registered. | declared(1) | D-SEAM | 19 |
| `tools/src/interfaces/realization-planning/run.ts` | 65 | Interface seam: Run. | declared(1) | D-SEAM | 16 |
| `tools/src/interfaces/realization-planning/verify-lifecycle.ts` | 63 | Interface seam: Verify lifecycle. | declared(1) | D-SEAM | 17 |
| `tools/src/interfaces/structural-model-projection/generate-structural-model.ts` | 33 | Interface seam: Generate structural model. | declared(1) | D-SEAM | 7 |
| `tools/src/interfaces/structural-model-projection/run.ts` | 138 | Interface seam: Run. | declared(1) | D-SEAM | 38 |
| `tools/src/interfaces/ui-parity/collect-wpf.ts` | 44 | Interface seam: Collect WPF. | declared(1) | D-SEAM | 34 |
| `tools/src/interfaces/ui-parity/evaluate-candidate.ts` | 119 | Interface seam: Evaluate candidate. | declared(1) | D-SEAM | 50 |
| `tools/src/interfaces/ui-parity/evaluate.ts` | 72 | Interface seam: Evaluate. | declared(1) | D-SEAM | 43 |
| `tools/src/interfaces/ui-parity/project.ts` | 48 | Interface seam: Project. | declared(1) | D-SEAM | 21 |
| `tools/src/interfaces/ui-parity/promote-candidate.ts` | 56 | Interface seam: Promote candidate. | declared(1) | D-SEAM | 33 |
| `tools/src/interfaces/ui-parity/serve-react.ts` | 35 | Interface seam: Serve React. | declared(1) | D-SEAM | 17 |
| `tools/src/interfaces/workspace-placement-verification/run.ts` | 57 | Interface seam: Run. | declared(1) | D-SEAM | 19 |
| `tools/src/model/interface-kind.ts` | 17 | Model/contract: Interface kind. | declared(1) | D-ADAPTER | 2 |
| `tools/src/model/realization-lifecycle.ts` | 142 | Model/contract: Realization lifecycle. | declared(1) | D-ADAPTER | 22 |
| `tools/src/model/realization-planning-adapter-profile.ts` | 50 | Model/contract: Realization planning adapter profile. | declared(1) | D-ADAPTER | 5 |
| `tools/src/model/semantic-model.ts` | 108 | Model/contract: Semantic model. | declared(1) | D-ADAPTER | 15 |
| `tools/src/primitives/sha256.ts` | 5 | Primitive: SHA-256. | declared(1) | D-CONTRACT | 1 |
| `tools/src/primitives/strict-json.ts` | 199 | Primitive: Strict JSON. | declared(1) | D-CONTRACT | 65 |

### UI parity and presentation (tools/src/ui-*)

| Path | LOC | Purpose | Home | Evidence | Sterility |
|---|---|---|---|---|---|
| `tools/src/ui-parity/application/react-ui-server.ts` | 2 | UI parity: React UI server. | declared(1) | D-PRESENT | 2 |
| `tools/src/ui-parity/application/ui-input-resolution.ts` | 228 | UI parity: UI input resolution. | declared(1) | D-PRESENT | 79 |
| `tools/src/ui-parity/application/ui-parity-projector.ts` | 371 | UI parity: UI parity projector. | declared(1) | D-PRESENT | 169 |
| `tools/src/ui-parity/application/ui-parity-server.ts` | 176 | UI parity: UI parity server. | declared(1) | D-PRESENT | 93 |
| `tools/src/ui-parity/application/ui-presentation-compiler.ts` | 239 | UI parity: UI presentation compiler. | declared(1) | D-PRESENT | 115 |
| `tools/src/ui-parity/application/ui-protocol-language-model-generator.ts` | 38 | UI parity: UI protocol language model generator. | declared(1) | D-PRESENT | 13 |
| `tools/src/ui-parity/model/ui-parity.ts` | 222 | UI parity: UI parity. | declared(1) | D-PRESENT | 4 |
| `tools/src/ui-parity/proof/canonical-ui-authority.ts` | 95 | UI parity: Canonical UI authority. | eliminated | E-VER | 40 |
| `tools/src/ui-parity/proof/claimant-implementation-admission.ts` | 48 | UI parity: Claimant implementation admission. | eliminated | E-VER | 27 |
| `tools/src/ui-parity/proof/ui-feature-admission.ts` | 208 | UI parity: UI feature admission. | eliminated | E-VER | 76 |
| `tools/src/ui-parity/proof/ui-parity-evaluator.ts` | 201 | UI parity: UI parity evaluator. | eliminated | E-VER | 103 |
| `tools/src/ui-presentation/application/declared-ui-presentation-resolver.ts` | 304 | UI presentation: Declared UI presentation resolver. | declared(1) | D-PRESENT | 84 |
| `tools/src/ui-presentation/application/legacy-ui-compatibility-compiler.ts` | 325 | UI presentation: Legacy UI compatibility compiler. | declared(1) | D-PRESENT | 148 |
| `tools/src/ui-presentation/application/semantic-presentation-compiler.ts` | 251 | UI presentation: Semantic presentation compiler. | declared(1) | D-PRESENT | 111 |
| `tools/src/ui-presentation/application/ui-embodiment-planner.ts` | 387 | UI presentation: UI embodiment planner. | declared(1) | D-PRESENT | 105 |
| `tools/src/ui-presentation/application/ui-protocol-binding-generator.ts` | 104 | UI presentation: UI protocol binding generator. | declared(1) | D-PRESENT | 42 |

### Enterprise reference platform (tools/src/enterprise)

| Path | LOC | Purpose | Home | Evidence | Sterility |
|---|---|---|---|---|---|
| `tools/src/enterprise/adapters/allow-all-invocation-policy.ts` | 17 | Enterprise reference platform: Allow all invocation policy. | test floor | T-HARNESS | 1 |
| `tools/src/enterprise/adapters/in-memory-bundle-registry.ts` | 29 | Enterprise reference platform: In memory bundle registry. | test floor | T-HARNESS | 19 |
| `tools/src/enterprise/adapters/in-memory-execution-repository.ts` | 247 | Enterprise reference platform: In memory execution repository. | test floor | T-HARNESS | 103 |
| `tools/src/enterprise/adapters/in-memory-provider-registry.ts` | 26 | Enterprise reference platform: In memory provider registry. | test floor | T-HARNESS | 7 |
| `tools/src/enterprise/adapters/in-memory-realization-plan-repository.ts` | 49 | Enterprise reference platform: In memory realization plan repository. | test floor | T-HARNESS | 24 |
| `tools/src/enterprise/control-plane/canonical-json.ts` | 29 | Enterprise reference platform: Canonical JSON. | declared(1) | D-CONTRACT | 22 |
| `tools/src/enterprise/control-plane/capability-bundle.ts` | 136 | Enterprise reference platform: Capability bundle. | eliminated | E-VER | 15 |
| `tools/src/enterprise/control-plane/release-admission.ts` | 89 | Enterprise reference platform: Release admission. | eliminated | E-VER | 27 |
| `tools/src/enterprise/data-plane/durable-execution-orchestrator.ts` | 476 | Enterprise reference platform: Durable execution orchestrator. | NO HOME | N-UNBOUND | 153 |
| `tools/src/enterprise/data-plane/model.ts` | 94 | Enterprise reference platform: Model. | NO HOME | N-UNBOUND | 18 |
| `tools/src/enterprise/data-plane/ports.ts` | 80 | Enterprise reference platform: Ports. | NO HOME | N-UNBOUND | 6 |
| `tools/src/enterprise/interfaces/http/execution-api-application.ts` | 174 | Enterprise reference platform: Execution API application. | NO HOME | N-UNBOUND | 70 |
| `tools/src/enterprise/interfaces/http/model.ts` | 147 | Enterprise reference platform: Model. | NO HOME | N-UNBOUND | 21 |
| `tools/src/enterprise/interfaces/http/node-api-reference-host.ts` | 555 | Enterprise reference platform: Node API reference host. | NO HOME | N-UNBOUND | 286 |
| `tools/src/enterprise/interfaces/http/ports.ts` | 26 | Enterprise reference platform: Ports. | NO HOME | N-UNBOUND | 1 |
| `tools/src/enterprise/interfaces/http/realization-api-application.ts` | 263 | Enterprise reference platform: Realization API application. | NO HOME | N-UNBOUND | 101 |
| `tools/src/enterprise/interfaces/http/realization-api-model.ts` | 135 | Enterprise reference platform: Realization API model. | NO HOME | N-UNBOUND | 5 |
| `tools/src/enterprise/interfaces/http/realization-api-ports.ts` | 69 | Enterprise reference platform: Realization API ports. | NO HOME | N-UNBOUND | 2 |
| `tools/src/enterprise/interfaces/http/strict-json.ts` | 2 | Enterprise reference platform: Strict JSON. | NO HOME | N-UNBOUND | 1 |

### CLI, compatibility, legacy, providers, scripts, document generation

| Path | LOC | Purpose | Home | Evidence | Sterility |
|---|---|---|---|---|---|
| `tools/capabilities/evaluates-capability-authority-v2.js` | 74 | Tooling: Evaluates capability authority v2. | declared(1) | D-CAP | 61 |
| `tools/cli/sda.js` | 316 | Tooling: SDA. | declared(1) | D-SEAM | 116 |
| `tools/compatibility/adapts-v1-capability-to-v2.js` | 114 | Tooling: Adapts v1 capability to v2. | declared(1) | D-SEAM | 36 |
| `tools/document-generation/build_enterprise_capability_os_doc.py` | 1050 | Tooling: Build enterprise capability OS doc. | declared(1) | D-SEAM | 146 |
| `tools/legacy/tooling-migration-conveyor-provider.mjs` | 88 | Tooling: Tooling migration conveyor provider. | eliminated | E-LEG | 25 |
| `tools/project-semantic-carrier-evaluator-provider-authority.mjs` | 347 | Tooling: Project semantic carrier evaluator provider authority. | declared(1) | D-CAP | 74 |
| `tools/project-semantic-carrier-extractor-provider-authority.mjs` | 372 | Tooling: Project semantic carrier extractor provider authority. | declared(1) | D-CAP | 99 |
| `tools/project-semantic-carrier-managed-v3-provider-authority.mjs` | 239 | Tooling: Project semantic carrier managed v3 provider authority. | declared(1) | D-CAP | 85 |
| `tools/providers/registered-source-inspector.mjs` | 20 | Tooling: Registered source inspector. | declared(1) | D-CAP | 17 |
| `tools/providers/target-projection-provider.mjs` | 170 | Tooling: Target projection provider. | declared(1) | D-CAP | 78 |
| `tools/scripts/project-native-avalonia-semantic-element-realization.mjs` | 245 | Tooling: Project native Avalonia semantic element realization. | eliminated | E-MAT | 100 |
| `tools/scripts/project-native-semantic-element-realization.mjs` | 270 | Tooling: Project native semantic element realization. | eliminated | E-MAT | 101 |

### Tests and conformance harness

| Path | LOC | Purpose | Home | Evidence | Sterility |
|---|---|---|---|---|---|
| `capabilities/sda-platform/verify-scenario-semantic-carrier-extraction-conformance/fixtures/valid-extractor.carrier.ts` | 39 | Conformance fixture: Valid extractor carrier. | test floor | T-HARNESS | 25 |
| `capabilities/sda-platform/verify-scenario-semantic-carrier-extraction-conformance/fixtures/valid-managed-extractor.carrier.ts` | 310 | Conformance fixture: Valid managed extractor carrier. | test floor | T-HARNESS | 36 |
| `capabilities/sda-platform/verify-scenario-semantic-carrier-validation-conformance/fixtures/hidden-meaning.carrier.ts` | 69 | Conformance fixture: Hidden meaning carrier. | test floor | T-HARNESS | 7 |
| `capabilities/sda-platform/verify-scenario-semantic-carrier-validation-conformance/fixtures/unresolved-identity.carrier.ts` | 59 | Conformance fixture: Unresolved identity carrier. | test floor | T-HARNESS | 5 |
| `capabilities/sda-platform/verify-scenario-semantic-carrier-validation-conformance/fixtures/valid-managed-validator.carrier.ts` | 310 | Conformance fixture: Valid managed validator carrier. | test floor | T-HARNESS | 36 |
| `capabilities/sda-platform/verify-scenario-semantic-carrier-validation-conformance/fixtures/valid-validator.carrier.ts` | 138 | Conformance fixture: Valid validator carrier. | test floor | T-HARNESS | 26 |
| `conformance/execution-graph/cpp-mechanic-evaluator-bridge.mjs` | 62 | Conformance runner/bridge: Cpp mechanic evaluator bridge. | test floor | T-HARNESS | 21 |
| `conformance/execution-graph/csharp-mechanic-evaluator-bridge.mjs` | 31 | Conformance runner/bridge: C# mechanic evaluator bridge. | test floor | T-HARNESS | 10 |
| `conformance/execution-graph/go-mechanic-evaluator-bridge.mjs` | 32 | Conformance runner/bridge: Go mechanic evaluator bridge. | test floor | T-HARNESS | 10 |
| `conformance/execution-graph/java-mechanic-evaluator-bridge.mjs` | 43 | Conformance runner/bridge: Java mechanic evaluator bridge. | test floor | T-HARNESS | 10 |
| `conformance/execution-graph/providers/parity_providers.py` | 18 | Conformance runner/bridge: Parity providers. | test floor | T-HARNESS | 7 |
| `conformance/execution-graph/providers/parity-providers.node.mjs` | 14 | Conformance runner/bridge: Parity providers node. | test floor | T-HARNESS | 6 |
| `conformance/execution-graph/python-mechanic-evaluator-bridge.mjs` | 31 | Conformance runner/bridge: Python mechanic evaluator bridge. | test floor | T-HARNESS | 10 |
| `conformance/execution-graph/run-mechanic-conformance.mjs` | 73 | Conformance runner/bridge: Run mechanic conformance. | test floor | T-HARNESS | 45 |
| `tools/projection-tests/execution-projection.test.js` | 123 | Test: Execution projection. | test floor | T-HARNESS | 59 |
| `tools/projection-tests/structural-projection.test.js` | 197 | Test: Structural projection. | test floor | T-HARNESS | 82 |
| `tools/tests/api-interface-projection.test.js` | 185 | Test: API interface projection. | test floor | T-HARNESS | 73 |
| `tools/tests/architecture-boundaries.test.js` | 90 | Test: Architecture boundaries. | test floor | T-HARNESS | 50 |
| `tools/tests/authority-conformance-capability.test.js` | 119 | Test: Authority conformance capability. | test floor | T-HARNESS | 35 |
| `tools/tests/conformance/capability-authority.test.js` | 102 | Test: Capability authority. | test floor | T-HARNESS | 48 |
| `tools/tests/conformance/durable-store-mechanic-admission.test.js` | 292 | Test: Durable store mechanic admission. | test floor | T-HARNESS | 129 |
| `tools/tests/conformance/execution-closure.test.js` | 132 | Test: Execution closure. | test floor | T-HARNESS | 28 |
| `tools/tests/conformance/gherkin-semantic-ingestion.test.js` | 427 | Test: Gherkin semantic ingestion. | test floor | T-HARNESS | 137 |
| `tools/tests/conformance/implementation-admission.test.js` | 176 | Test: Implementation admission. | test floor | T-HARNESS | 79 |
| `tools/tests/conformance/json-authority-ingestion.test.js` | 275 | Test: JSON authority ingestion. | test floor | T-HARNESS | 125 |
| `tools/tests/conformance/legacy-ui-compatibility.test.js` | 225 | Test: Legacy UI compatibility. | test floor | T-HARNESS | 118 |
| `tools/tests/conformance/os-environment-credential.test.js` | 113 | Test: OS environment credential. | test floor | T-HARNESS | 58 |
| `tools/tests/conformance/presentation-capability-ownership.test.js` | 214 | Test: Presentation capability ownership. | test floor | T-HARNESS | 125 |
| `tools/tests/conformance/proof-binding-evaluation.test.js` | 336 | Test: Proof binding evaluation. | test floor | T-HARNESS | 147 |
| `tools/tests/conformance/provider-binding-runtime.test.js` | 88 | Test: Provider binding runtime. | test floor | T-HARNESS | 25 |
| `tools/tests/conformance/registered-language-toolchain.test.js` | 91 | Test: Registered language toolchain. | test floor | T-HARNESS | 47 |
| `tools/tests/conformance/resolve-declared-ui-presentation.test.js` | 218 | Test: Resolve declared UI presentation. | test floor | T-HARNESS | 95 |
| `tools/tests/conformance/runtime-contracts.test.js` | 41 | Test: Runtime contracts. | test floor | T-HARNESS | 9 |
| `tools/tests/conformance/scenario-semantic-carrier-evaluation.test.js` | 137 | Test: Scenario semantic carrier evaluation. | test floor | T-HARNESS | 46 |
| `tools/tests/conformance/scenario-semantic-carrier-extraction.test.js` | 140 | Test: Scenario semantic carrier extraction. | test floor | T-HARNESS | 78 |
| `tools/tests/conformance/scenario-semantic-carrier-validation.test.js` | 247 | Test: Scenario semantic carrier validation. | test floor | T-HARNESS | 110 |
| `tools/tests/conformance/schema-admission.test.js` | 106 | Test: Schema admission. | test floor | T-HARNESS | 65 |
| `tools/tests/conformance/semantic-presentation-compiler.test.js` | 185 | Test: Semantic presentation compiler. | test floor | T-HARNESS | 60 |
| `tools/tests/conformance/semantic-vector-index.test.js` | 242 | Test: Semantic vector index. | test floor | T-HARNESS | 100 |
| `tools/tests/conformance/ui-authority-version-freeze.test.js` | 115 | Test: UI authority version freeze. | test floor | T-HARNESS | 38 |
| `tools/tests/conformance/ui-csharp-embodiment-v3.test.js` | 91 | Test: UI C# embodiment v3. | test floor | T-HARNESS | 34 |
| `tools/tests/conformance/ui-embodiment-planning.test.js` | 154 | Test: UI embodiment planning. | test floor | T-HARNESS | 51 |
| `tools/tests/conformance/ui-presentation-ir-v3-design.test.js` | 95 | Test: UI presentation IR v3 design. | test floor | T-HARNESS | 50 |
| `tools/tests/conformance/ui-protocol-bindings-v3.test.js` | 46 | Test: UI protocol bindings v3. | test floor | T-HARNESS | 27 |
| `tools/tests/conformance/ui-reference-embodiment-v3.test.js` | 180 | Test: UI reference embodiment v3. | test floor | T-HARNESS | 66 |
| `tools/tests/consumer-projection/capability-execution-emitter.test.js` | 2457 | Test: Capability execution emitter. | test floor | T-HARNESS | 1050 |
| `tools/tests/consumer-projection/consumer-experience-closure.test.js` | 17 | Test: Consumer experience closure. | test floor | T-HARNESS | 9 |
| `tools/tests/consumer-projection/consumer-projection-equivalence.test.js` | 31 | Test: Consumer projection equivalence. | test floor | T-HARNESS | 22 |
| `tools/tests/consumer-projection/consumer-query-catalog.test.js` | 28 | Test: Consumer query catalog. | test floor | T-HARNESS | 23 |
| `tools/tests/consumer-projection/cross-apply-proof-profile.test.js` | 123 | Test: Cross apply proof profile. | test floor | T-HARNESS | 35 |
| `tools/tests/consumer-projection/csharp-consumer-projection.test.js` | 33 | Test: C# consumer projection. | test floor | T-HARNESS | 28 |
| `tools/tests/consumer-projection/database-artifact.test.js` | 148 | Test: Database artifact. | test floor | T-HARNESS | 69 |
| `tools/tests/consumer-projection/deterministic-regeneration.test.js` | 126 | Test: Deterministic regeneration. | test floor | T-HARNESS | 67 |
| `tools/tests/consumer-projection/execution-closure.test.js` | 22 | Test: Execution closure. | test floor | T-HARNESS | 19 |
| `tools/tests/consumer-projection/execution-embodiment-plan.test.js` | 78 | Test: Execution embodiment plan. | test floor | T-HARNESS | 26 |
| `tools/tests/consumer-projection/execution-pattern-registration.test.js` | 137 | Test: Execution pattern registration. | test floor | T-HARNESS | 63 |
| `tools/tests/consumer-projection/mechanic-registry-composition.test.js` | 50 | Test: Mechanic registry composition. | test floor | T-HARNESS | 16 |
| `tools/tests/consumer-projection/mechanical-sterility.test.js` | 47 | Test: Mechanical sterility. | test floor | T-HARNESS | 26 |
| `tools/tests/consumer-projection/no-domain-leakage.test.js` | 13 | Test: No domain leakage. | test floor | T-HARNESS | 7 |
| `tools/tests/consumer-projection/pattern-binder.test.js` | 545 | Test: Pattern binder. | test floor | T-HARNESS | 255 |
| `tools/tests/consumer-projection/platform-capability-admission.test.js` | 201 | Test: Platform capability admission. | test floor | T-HARNESS | 118 |
| `tools/tests/consumer-projection/python-consumer-projection.test.js` | 63 | Test: Python consumer projection. | test floor | T-HARNESS | 42 |
| `tools/tests/consumer-projection/reference-workspace.cjs` | 37 | Test: Reference workspace. | test floor | T-HARNESS | 7 |
| `tools/tests/consumer-projection/schema-contract-admission-scale.test.js` | 48 | Test: Schema contract admission scale. | test floor | T-HARNESS | 18 |
| `tools/tests/consumer-projection/source-observation-provider.test.js` | 237 | Test: Source observation provider. | test floor | T-HARNESS | 87 |
| `tools/tests/consumer-projection/ui-authority-neutrality.test.js` | 78 | Test: UI authority neutrality. | test floor | T-HARNESS | 65 |
| `tools/tests/consumer-projection/ui-feature-admission.test.js` | 69 | Test: UI feature admission. | test floor | T-HARNESS | 45 |
| `tools/tests/consumer-projection/ui-input-resolution.test.js` | 439 | Test: UI input resolution. | test floor | T-HARNESS | 143 |
| `tools/tests/consumer-projection/ui-parity-foundation.test.js` | 387 | Test: UI parity foundation. | test floor | T-HARNESS | 174 |
| `tools/tests/consumer-projection/ui-presentation-protocol.test.js` | 210 | Test: UI presentation protocol. | test floor | T-HARNESS | 73 |
| `tools/tests/consumer-projection/wpf-consumer-projection.test.js` | 88 | Test: WPF consumer projection. | test floor | T-HARNESS | 37 |
| `tools/tests/enterprise-execution-platform.test.js` | 783 | Test: Enterprise execution platform. | test floor | T-HARNESS | 192 |
| `tools/tests/execution-api-reference-host.test.js` | 485 | Test: Execution API reference host. | test floor | T-HARNESS | 154 |
| `tools/tests/file-backed-realization-planning.test.js` | 207 | Test: File backed realization planning. | test floor | T-HARNESS | 60 |
| `tools/tests/language-binding-discovery-capability.test.js` | 111 | Test: Language binding discovery capability. | test floor | T-HARNESS | 36 |
| `tools/tests/language-declaration-admission-capability.test.js` | 96 | Test: Language declaration admission capability. | test floor | T-HARNESS | 36 |
| `tools/tests/language-ecosystem-layout.test.js` | 51 | Test: Language ecosystem layout. | test floor | T-HARNESS | 15 |
| `tools/tests/language-obligation-determination-capability.test.js` | 104 | Test: Language obligation determination capability. | test floor | T-HARNESS | 35 |
| `tools/tests/openapi-projection.test.js` | 241 | Test: OpenAPI projection. | test floor | T-HARNESS | 90 |
| `tools/tests/realization-api-reference-host.test.js` | 457 | Test: Realization API reference host. | test floor | T-HARNESS | 142 |
| `tools/tests/realization-lifecycle-contracts.test.js` | 121 | Test: Realization lifecycle contracts. | test floor | T-HARNESS | 44 |
| `tools/tests/realization-planning-capability.test.js` | 381 | Test: Realization planning capability. | test floor | T-HARNESS | 92 |
| `tools/tests/registry-backed-realization-planning.test.js` | 285 | Test: Registry backed realization planning. | test floor | T-HARNESS | 82 |
| `tools/tests/run-top-level-tests.cjs` | 20 | Test: Run top level tests. | test floor | T-HARNESS | 12 |
| `tools/tests/semantic-execution-graph.test.js` | 1911 | Test: Semantic execution graph. | test floor | T-HARNESS | 1023 |
| `tools/tests/structural-model-projection-capability.test.js` | 72 | Test: Structural model projection capability. | test floor | T-HARNESS | 22 |
| `tools/tests/ui-change-amplification.test.js` | 51 | Test: UI change amplification. | test floor | T-HARNESS | 14 |
| `tools/tests/workspace-placement-verification-capability.test.js` | 102 | Test: Workspace placement verification capability. | test floor | T-HARNESS | 33 |

---

## 6. No-home findings (K029 violations)

The 23 files below have **no home**: they are not declared authority, not inside
an admitted resolver boundary, do not implement a target-architecture
materialization/verification function, and are not boot. Under K029 they are
`NON_RESOLVER_HAND_AUTHORED_MECHANIC` today. The Sterility column is the
evaluator's actual violation total (§1.3).

### F1 — The consumer projector core authors executable meaning into emitted bodies

Home: **none**. ADR-0013:48-53 excludes projection tooling from the resolver
boundary; ADR-0013:55-61 forbids a surviving central hand-authored projector and
requires exactly one admitted versioned bootstrap compiler with reproducible
self-hosting evidence — no admission record and no self-hosting evidence exists
in the tree being inventoried. These files decide the per-target semantics of
the bodies they emit and carry the highest mechanic counts in SDA.

| File | LOC | Mechanics |
|---|---:|---:|
| `tools/src/consumer-projection/projection/csharp/capability-execution-emitter.ts` | 2,068 | 1,076 |
| `tools/src/consumer-projection/projection/node/capability-execution-emitter.ts` | 1,662 | 880 |
| `tools/src/consumer-projection/projection/python/capability-execution-emitter.ts` | 1,578 | 557 |
| `tools/src/consumer-projection/projection/csharp/expression-emitter.ts` | 759 | 477 |
| `tools/src/consumer-projection/projection/python/expression-emitter.ts` | 566 | 267 |
| `tools/src/consumer-projection/projection/expression-emitter.ts` | 407 | 257 |
| `tools/src/consumer-projection/projection/pattern-binder.ts` | 819 | 330 |
| `tools/src/consumer-projection/projection/mechanic-registry.ts` | 382 | 131 |
| `tools/src/consumer-projection/projection/csharp/mechanic-registry.ts` | 105 | 29 |
| **Total** | **8,346** | **4,004** |

Rule violated: **K029** (`NON_RESOLVER_HAND_AUTHORED_MECHANIC`);
ADR-0013:42-46 (`PROJECTED_EXECUTION_MECHANIC_VIOLATION`).

### F2 — The new database-artifact materialization target

`tools/src/consumer-projection/application/consumer-database-artifact-emitter.ts`
— 259 LOC, **65** mechanics. Added at HEAD `0bff62b` ("…add the projector
database artifact target"). It emits `database/publish-projected-bodies.sql`
which copies projected native bodies into `source.content_object` /
`source.source_appearance` as `PROJECTED_BODY` rows (file lines 38-180). This is
materialization into the declaration store — the estate's `publish-projected-bodies`
function the retirement ledger is retiring — and it landed **after** the target
architecture eliminated `embodiment-delivery` and forbade file writes and
materialization (`target-architecture.md:26-28,61-72,86-95`). It also grows
hand-authored surface against ADR-0013:63-69 monotonic shrinkage. Rule:
**K029**; disposition function: `embodiment-delivery` / `materialize-node`.

### F3 — The tool-capability host and provider loader

| File | LOC | Mechanics |
|---|---:|---:|
| `tools/src/host/tool-capability-host.ts` | 79 | 18 |
| `tools/src/host/load-provider.ts` | 77 | 40 |

`ToolCapabilityHost` is named in ADR-0013:79-82 and "sits on the line": if it
sequences capability transitions it executes a forbidden mechanic, so it is
either admitted as the Node resolver's own body or its sequencing is replaced by
authority-backed mechanic execution. Neither has happened. `load-provider.ts`
dynamically imports a provider module — a native module-load mechanic sitting
outside any admitted boundary. `tools/` is not a language runtime, so neither
can be resolver(0). Rule: **K029**.

### F4 — The enterprise reference platform machinery

No declared capability binds these files: they appear in no
`provider-bindings.json` `implementationRef`, and none is reachable from a
declared capability provider or a projected seam. They are hand-authored
application/runtime behavior — an HTTP API and a durable execution orchestrator
— with no authority naming their semantics and no disposition eliminating
them.

| File | LOC | Mechanics |
|---|---:|---:|
| `tools/src/enterprise/interfaces/http/node-api-reference-host.ts` | 555 | 286 |
| `tools/src/enterprise/data-plane/durable-execution-orchestrator.ts` | 476 | 153 |
| `tools/src/enterprise/interfaces/http/realization-api-application.ts` | 263 | 101 |
| `tools/src/enterprise/interfaces/http/execution-api-application.ts` | 174 | 70 |
| `tools/src/enterprise/interfaces/http/model.ts` | 147 | 21 |
| `tools/src/enterprise/interfaces/http/realization-api-model.ts` | 135 | 5 |
| `tools/src/enterprise/data-plane/model.ts` | 94 | 18 |
| `tools/src/enterprise/data-plane/ports.ts` | 80 | 6 |
| `tools/src/enterprise/interfaces/http/realization-api-ports.ts` | 69 | 2 |
| `tools/src/enterprise/interfaces/http/ports.ts` | 26 | 1 |
| `tools/src/enterprise/interfaces/http/strict-json.ts` | 2 | 1 |
| **Total** | **2,021** | **664** |

Rule: **K029**; K025 would make these derived transport embodiments *if* public
interface authority existed for them — it does not.

### F5 — The gate itself has no admitted home (method finding)

`tools/src/consumer-projection/proof/mechanical-sterility-evaluator.ts` (147
LOC, **106** mechanics) is homed eliminated (E-VER) in the table because it
becomes a declared reading/gate. But note the self-reference: K029's required
repository-wide scan is currently hand-authored TypeScript outside every
admitted boundary, and transistor model G2 records that the gate is declared but
**not wired**. Wiring it requires homing it (inside the declared boundary or as
projected tooling). Rule: **K029** until homed.

### F6 — Test floor has no admitted home (class finding)

95 files, 18,047 LOC, **7,245** mechanics: `tools/tests/**` (72),
`tools/projection-tests/**` (2), `conformance/execution-graph/**` (8:
`run-mechanic-conformance.mjs` plus the cpp/csharp/go/java/python evaluator
bridges), and conformance fixtures (6 carrier `.ts` fixtures under
`capabilities/sda-platform/**/fixtures/`, plus 7 in-memory adapters). The
estate's own ledger defers "whether verification harnesses are admitted test
floor or declared readings" (`hand-authored-code-retirement.md:55-59`), and
ADR-0013:86 puts the conveyor/authoring families in the Agentic Harness outside
SDA. Until that decision lands, test floor is a flagged class, not a home:
these files are K029 violations too. The largest are
`tools/tests/consumer-projection/capability-execution-emitter.test.js` (1,050),
`tools/tests/semantic-execution-graph.test.js` (1,023), and
`tools/tests/conformance/*` (1,895 across 26 files).

### F7 — Scan completeness gap

The evaluator's extension regex (`mechanical-sterility-evaluator.ts:38`) omits
`.go` (G5). No authored `.go` lies in this inventory, but a repository-wide scan
that claims to cover every executable file is incomplete as written. This is an
SDA change request, not a finding about a specific file.

---

## 7. What must be deleted

Short list, highest severity first:

1. `tools/src/consumer-projection/application/consumer-database-artifact-emitter.ts`
   and its wiring: the import and use in
   `tools/src/consumer-projection/application/consumer-projection-plan-builder.ts`,
   the `ConsumerDatabaseArtifact*` types in
   `tools/src/consumer-projection/model/consumer-projection-plan.ts`, and
   `tools/tests/consumer-projection/database-artifact.test.js`. The projector
   must not emit a `database/` target.
2. The F1 projector core (9 files) once the admitted bootstrap compiler projects
   it; no hand-authored replacement may be added in the meantime.
3. `tools/src/host/tool-capability-host.ts` and `tools/src/host/load-provider.ts`
   after relocation into the admitted Node boundary or replacement by
   authority-backed mechanics.
4. The E-MAT surface: `tools/scripts/project-native-semantic-element-realization.mjs`,
   `tools/scripts/project-native-avalonia-semantic-element-realization.mjs`,
   `tools/src/projection/providers/**`, `tools/src/projection/toolchain/**`,
   `tools/src/adapters/projection/**`, the consumer projection artifact store /
   runtime toolchains / platform toolchains, the consumer-application providers
   (`tools/src/consumer-projection/providers/**`), and the embodiment
   compilers/plan-builder.
5. The E-VER surface after declared readings/receipts replace them:
   `tools/src/consumer-projection/proof/**`, `tools/src/projection/proof/**`,
   `tools/src/conformance/proof/**`, `tools/src/ui-parity/proof/**`, and the
   enterprise release gate (`release-admission.ts`, `capability-bundle.ts`).
6. `tools/legacy/tooling-migration-conveyor-provider.mjs` after promotion
   equivalence evidence lands.
7. Estate dead matter per its own target (not SDA): `embodiments/**`,
   `providers/**/projected/**`, `baselines/**`, and the tests of deleted modules
   (§9).

---

## 8. Ordered migration units (agent-ready)

A unit lands coordinated changes together plus its proof. Invocation (or the
named acceptance) is the unit's proof; a green appearing in isolation is not.

### M1 — Delete the database-artifact materialization target (F2)

- **Scope.** `tools/src/consumer-projection/application/consumer-database-artifact-emitter.ts`;
  the import/use in `consumer-projection-plan-builder.ts`; the `ConsumerDatabaseArtifact*`
  contracts in `model/consumer-projection-plan.ts`; `tools/tests/consumer-projection/database-artifact.test.js`.
- **Replacement.** None. The estate's `publish-projected-bodies` stays retired;
  the kernel interprets in process (`target-architecture.md:26-28,70`).
- **Acceptance.** No projection plan contains a `database/` target; the projector
  emits no `publish-projected-bodies.sql`; `git grep -l consumer-database-artifact-emitter`
  is empty; the retirement of the estate's `publish-projected-bodies` script is
  not blocked.
- **Verification.** `node --test tools/tests/consumer-projection/database-artifact.test.js`
  no longer exists; the consumer projection suite runs green without the
  database target; the file's 65-mechanic count disappears from the repository
  sterility scan.

### M2 — Home the projector core (F1)

- **Scope.** The 9 files in F1 (`tools/src/consumer-projection/projection/**`),
  plus the application compilers that assemble emitted bodies.
- **Replacement.** The admitted versioned bootstrap compiler required by
  ADR-0013:55-61 with reproducible self-hosting evidence. This is an SDA change
  request (no agent may edit SDA): the primitive is the bootstrap compiler
  admission; why kernel: the projector is shared by every language and must be
  projected through the same generic protocol; data that binds it: the existing
  `consumer-execution-embodiment-plan.v3` and `consumer-projection-plan`
  authority; evidence: ADR-0013:55-61, transistor model G2.
- **Acceptance.** The emitters either carry projection provenance with zero
  forbidden mechanics or are gone; an admission record names the bootstrap
  compiler version and its self-hosting evidence; no new hand-authored emitter
  is introduced (freeze).
- **Verification.** Run the twelve-counter evaluator over every executable:
  node 880 → 0, python 557 → 0, csharp 1,076 → 0, or the boundary declaration
  moves them inside `projectReferences.kernel`; `git grep` shows no authored
  emitter bodies.

### M3 — Home the tool-capability host and provider loader (F3)

- **Scope.** `tools/src/host/tool-capability-host.ts`, `tools/src/host/load-provider.ts`.
- **Replacement.** Either (a) admit them into the Node resolver boundary — add
  them to the node binding's declared resolver surface (the boundary must be
  declared per ADR-0013:48-53; G1) — or (b) replace capability sequencing with authority-backed
  mechanic execution, per ADR-0013:79-82.
- **Acceptance.** `tools/src/host/**` is either deleted or reachable only from
  inside the admitted `projectReferences.kernel` boundary.
- **Verification.** The node binding manifest shows the boundary; the sterility
  counts 18 and 40 are inside the boundary or gone; a capability invocation that
  previously used the host still resolves through the kernel.

### M4 — Eliminate the materialization surface (E-MAT, 41 files, 4,160 LOC)

- **Scope.** Projection providers/toolchains/proof-emission paths, adapter
  materializers/artifact stores/target toolchains, the two `project-native-*`
  scripts, consumer-application providers, embodiment compilers.
- **Replacement.** Nothing is emitted, loaded, or written; the kernel interprets
  the declared graph in process (`target-architecture.md:26-28,70`).
- **Acceptance.** No file under `tools/**` writes a native body or materialized
  plan; the capability conveyor publishes only projected seams.
- **Verification.** Repository grep for `writeFile`/`createWriteStream` targets
  in these paths returns zero; the projection deliverable is reviewable as seams
  with provenance.

### M5 — Eliminate/replace native-body verification (E-VER + E-LEG, 27 files)

- **Scope.** `tools/src/consumer-projection/proof/**` (apart from the gate itself,
  F5), `tools/src/projection/proof/**`, `tools/src/conformance/proof/**`,
  `tools/src/ui-parity/proof/**`, enterprise release gate, legacy oracle.
- **Replacement.** Declared readings/receipts (the estate pattern: verification
  becomes a declared reading, then the script retires) plus the promotion
  evidence ADR-0013:100-103 requires before the legacy oracle is deleted.
- **Acceptance.** Verification outcomes are declared rows/receipts; no
  hand-authored verifier remains; the legacy provider-equivalence evidence is
  retained as admission evidence, then the oracle is deleted.
- **Verification.** Invoke the replacement readings through the frontdoor and
  compare outcomes to the retired verifier's recorded acceptance; scan shows the
  E-VER files gone.

### M6 — Home the enterprise machinery (F4, 11 files, 2,021 LOC)

- **Scope.** `tools/src/enterprise/interfaces/http/**`,
  `tools/src/enterprise/data-plane/durable-execution-orchestrator.ts`,
  `model.ts`, `ports.ts`.
- **Replacement.** Either delete as superseded demonstration surface, or declare
  it: runtime orchestration and transition evaluation are projected from
  canonical authority (K015), and HTTP artifacts are derived transport
  embodiments (K025) — both require declared authority that does not exist today.
- **Acceptance.** Every remaining enterprise file is either gone or named by a
  declared capability/interface authority with generated embodiment.
- **Verification.** `git grep` finds no provider-bindings-free hand-authored
  HTTP application; the reference-host tests either relocate to the harness or
  are deleted with their subjects.

### M7 — Decide the test floor, home the gate, declare the boundary (F5/F6/F7)

- **Scope.** `tools/tests/**`, `tools/projection-tests/**`,
  `conformance/execution-graph/**`, fixtures, in-memory adapters, the
  mechanical-sterility evaluator, every language binding manifest.
- **Replacement.** Builder decision: admit a test floor or declare test
  outcomes as readings (estate `hand-authored-code-retirement.md:55-59`); admit the sterility
  evaluator as a resolver body or projected tooling (transistor model G2);
  declare resolver boundaries in binding manifests and add `.go` to the
  evaluator (transistor model G1/G5, SDA change requests 1, 2, 4).
- **Acceptance.** The repository-wide scan exists, covers every executable
  extension, and can evaluate K029's boundary condition because the boundary is
  declared; the harness class has an explicit disposition.
- **Verification.** The gate runs over the whole repository and reports zero on
  every file outside a declared boundary or names every violation.

---

## 9. Estate: authored scripts not yet covered by `docs/hand-authored-code-retirement.md`

The retirement ledger inventories `src/` (14 files at the time) and `scripts/`
(13 `.mjs` + 1 `.sql`) by name. All nine current `src/*.mjs` and all eight
current `scripts/*.mjs` plus `scripts/queries/list-projected-bodies.sql` are
named there; ten files the ledger names no longer exist (including
`observation-filter.mjs`, deleted per its own "Landed so far" note). The
following authored executable surface is **not** covered by that ledger:

| Surface | Files | LOC | Disposition |
|---|---:|---:|---|
| `tests/**` (`*.test.mjs`, including tests of deleted modules: `execution-drilldown`, `semantic-address`, `timing-coherence`) | 12 | 1,578 | Same open test-floor decision as F6; retire with their subjects or declare as readings/harness. |
| `docs/research/**/*.mjs` (`canonical-feature-migration/audit`, `ml-opportunity/collect-evidence`, `scaffold-projection-gap/build-contract-fix`, `scenario-experiences/{analyze,probe,read,verify}`) | 7 | 598 | Research/authoring mechanism: move to the Agentic Harness or delete; not SDA/estate product surface. |
| `baselines/<digest>/**` (451 executable files; the hand-authored members are `materialize-node.mjs`, `read-authority.mjs`, `resolvers/node/consumer-object-provider.mjs`, `review/contract-type-witness.ts`, `review/verify-contract-type-witness.mjs`, `verify-node.mjs`; the rest are frozen copies of projected bodies) | 451 | 5,887 | **Eliminated**: materialization and native-body verification were superseded; "parity against retained native-body fixtures" is a non-reason to retain (`target-architecture.md:86-95`). Delete the baseline bundle. |
| `embodiments/**` — materialized scenario bodies (composition/contracts/providers per capability) | 322 | 12,600 | **Eliminated**: materialization (`materialize-node`, `embodiment-delivery`) — dead matter under `target-architecture.md:70`. Delete. |
| `providers/**/projected/**` — published projected bodies (plus built `.dll` payloads under `providers/consumer-execution/**`) | 42 | 19,150 | **Eliminated**: projected native bodies the kernel supersedes. Delete with the baseline bundle. |

`sql/**` is declared data (not code); `sfx.config.json` is boot config (the
target architecture's irreducible delivery/workspace config, line 69); root
`*.out`/`*.err`/`input.json` are run residue, not authored surface.

---

## 10. Open decisions and SDA change requests

1. **Test floor (F6).** Builder decision outstanding: admit a harness boundary
   in SDA or move tests/conformance bridges to the Agentic Harness. Until then,
   95 files / 18,047 LOC / 7,245 mechanics are unflagged by any home.
2. **The gate's own home (F5).** `mechanical-sterility-evaluator.ts` is required
   by K029 and is itself a K029 violation as located; admit it inside the
   declared boundary or as projected tooling when the repo-wide scan is wired.
3. **Declare resolver boundaries in binding manifests (G1).** Without this,
   K029's "inside a declared resolver boundary" is not evaluable; every binding
   today has only `projectReferences` (no boundary key).
4. **Wire the repository-wide sterility gate and add `.go` (G2, G5).** ADR-0013
   already specifies it; `verify-resolver-boundary-sterility` is declared with no
   provider.
5. **Admit the bootstrap compiler (F1).** ADR-0013:55-61 requires one versioned
   admitted bootstrap compiler with reproducible self-hosting evidence before
   any non-resolver surface is admitted.
6. **Fix the C++ binding (G10).** Its `projectReferences.kernel` points at
   projected `generated/execution`, so its resolver boundary is undeclared by
   construction.

**Declare it or resolve it. There is no third place for executable meaning to
live.**
