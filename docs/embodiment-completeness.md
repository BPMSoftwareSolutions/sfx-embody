# Embodiment completeness

**The requirement, in one sentence:** an embodiment is complete only when *every
executable mechanic* a capability's execution uses is embodied **in code, per
target language**, and bound in the embodiment itself — with nothing left to a host
default, a passthrough, or an assumption that "the kernel handles it".

This is the unambiguous ask. It is binding, alongside
[target-architecture.md](target-architecture.md) and
[implementation-strategy.md](implementation-strategy.md).

## Agents must not change the SDA repo — kernel changes are requests, not edits

Agents working in this repo MUST NOT modify the SDA repo/kernel
(`C:\lab\repos\scenario-driven-architecture`). Doing so is a **violation**. The SDA
repo is the platform; this repo is the database authority plus the reader/boot.

- A **kernel change** is a language-resolver change that requires every language to
  conform (node, python, csharp; java/go where applicable). Kernel changes are
  *identified* here, never *performed* here.
- When the work requires one, submit an **SDA change request** to the user driving
  the session. The user inspects and validates the request, and — if valid — has the
  SDA team make the change. Agents never make it.
- Request format:
  - **primitive** — the exact change (e.g. "GraphTokenScheduler composite re-entry
    must scope its expression to its own incoming sequence input").
  - **why kernel** — why it must be interpreted in every language rather than
    selected as data.
  - **affected languages** — which of node / python / csharp (and java / go) must
    conform.
  - **data that binds it** — the rows/config that will bind the primitive once it
    exists.
  - **evidence** — the failing invocation/graph, and any local probe that isolates
    it (a probe is read-only; it is not a change).

If an agent believes an SDA change is needed, it **stops** and submits the request.
It does not edit SDA, does not wire a facade, and does not fake a green.

## Where mechanics are embodied: code files, per language — never facades

Executable mechanics live in **code**, in each target language's runtime, as real
implementations that perform the work. A language that returns its input unchanged
(or otherwise does nothing) is a **facade**, not an embodiment — the python and
csharp effect ports were exactly that before unit 17/18. Every mechanic below must
have a real implementation in **all three** languages, with parity (same
disposition and digest).

| mechanic kind | node (code file) | python (code file) | csharp (code file) |
|---|---|---|---|
| pure semantic-value | `languages/typescript/runtimes/node/semantic-execution-graph-mechanic-provider.mjs` | python mechanic provider (`platform/…`) | `Graph/SemanticExecutionGraphMechanicProvider.cs` |
| transformation / language | `semantic-transformation-evaluator.mjs` | python evaluator | `ScenarioKernel.Adapters/.../SemanticTransformationEngine` |
| collection / recurrence | scheduler + mechanic provider | `platform/execution_graph.py` + provider | `Graph/SemanticExecutionGraphScheduler.cs` + provider |
| platform effect ports | `external-credential-reference-binding-provider.mjs`, `governed-http-exchange-provider.mjs`, `semantic-execution-graph-effect-provider.mjs` | `platform/governed_effect_ports.py` | `Graph/GovernedEffectPorts.cs` |
| schema / contract admission | `schema-contract-admission-provider.mjs` | python schema admission | `Schema/SemanticContractCatalogAdmission.cs`, `JsonSchemaContractValidator.cs` |
| declared data read | kernel declared-read code | python declared-read | csharp declared-read |
| scheduling | `semantic-execution-graph/scheduler.js` | `platform/execution_graph.py` | `Graph/SemanticExecutionGraphScheduler.cs` |

(Paths are the current node/python/csharp SDA implementations; the point is the
*location and nature* — a code file in each language, executing the mechanic, not
a JSON stand-in and not a passthrough.)

## What stays data (JSON / rows)

Only **selection and configuration** is data — never a mechanic's behavior:

- the declared meaning: capability, scenario, operations, ports, transformations,
  provider bindings, contracts, topology, targets, provider profiles;
- per-node configuration: statements, credential/endpoint authorities, expressions,
  contract schemas;
- the binding: `overlayBindings` (`mechanicId → providerProfileId`) and `providers`
  (`providerProfileId → code module/export[/factory]`).

A JSON declaration says *which* code mechanic runs and *with what configuration*.
The code says *how it runs*. Neither may substitute for the other: no behavior in a
JSON default, no requirement hidden in code.

## How the consumer application decides code vs data (and keeps pattern flexibility)

The split is derived from the graph and the target registry — not hardcoded:

1. The compiled graph names each cell's mechanic as data
   (`mechanicId` / `platformCapabilityId`).
2. Each id resolves, in that target's registry, to a **provider profile** naming a
   **code file + export**. A declared read (`{ statement, resultColumn }`) resolves
   to the language's declared-read code, with the statement as data. Contract
   admission resolves to the language's schema-admission code.
3. Therefore: a cell that names a platform mechanic is executed by **language code**;
   a cell that carries a statement is executed by the declared-read **code** with
   the statement as **data**; nothing executable remains as bare JSON.

Because the binding is `mechanicId → profile → code module/export` (data), the
consumer application is free to choose the **projected code pattern** per target —
it can

- emit a native code body that imports the per-language mechanic code and threads
  the JSON configuration, or
- emit a plan/overlay and let the language host bind the same code mechanics at run
  time, or
- any other pattern,

so long as every required mechanic is bound to per-language code and executes for
real. **Data decides which mechanics and their configuration; the language code
decides how they execute; the consumer decides the pattern.** That is the
flexibility the consumer application has, and it does not change the requirement:
the mechanics are embodied in code, per language, with no facades.

## What counts as an executable mechanic

Every kind of executable step a compiled execution graph can name:

- **pure semantic-value mechanics** — `path`, `object`, `literal`, `format`, `let`,
  `identity`, `equals`, `length`, `try-parse-json`, `base64-decode-utf8`, …
- **collection / recurrence mechanics** — `map`, `filter`, `find`, `some`, `every`,
  `for-each`, …
- **platform effect ports** — `sda-external-credential-reference-binding-port.v1`,
  `sda-governed-http-exchange-port.v1`, …
- **declared data reads** — `{ statement, resultColumn }`
- **contract admission** — every input/outcome contract in `plan.contractCatalog`
- **kernel language mechanics** — transformations, schema admission, scheduling

If the graph names it, the embodiment must bind it. There is no "the host happens
to do this" exception.

## The completeness rule (per target)

For a compiled graph `G` and target `T`, an embodiment is complete only if **all**
hold:

1. **Every required slot is bound.** For each entry in `G.requiredProviderSlots`,
   the embodiment has an `overlayBindings` entry (`mechanicId → providerProfileId`)
   and a `providers` entry (`providerProfileId → module/export[/factory]`) for `T`.
   No slot may be unbound, and no slot may resolve by default.
2. **Every contract is carried.** Every contract referenced by any cell's
   `input`/`outcome` is present in the plan's `contractCatalog` with its schema,
   and every `$ref` in those schemas resolves against the catalog. No empty
   catalog, no dangling ref.
3. **Every declared read is declared.** Each read carries `{ statement,
   resultColumn }`; none points at a module.
4. **No passthrough.** No mechanic is satisfied by returning its input unchanged
   or by a host default; each is executed by its declared implementation.

## The proof

An embodiment is complete only when, for **each target**, running it against the
capability's declared fixtures returns the expected dispositions and digests.

- Per target: run all declared fixtures through that target's host; every fixture
  reaches its expected `disposition`, `outcome.disposition`, and `resolutionDigest`.
- Cross-target: the node, python and csharp plans share the same
  `canonicalGraphDigest` and produce the same outcome digest; they differ only in
  the per-target `realizedGraphDigest`.
- Estate path: `sfx capability invoke <capability>` runs the same graph with a
  `run-declared-graph` overlay whose `overlayBindings` cover the **full** mechanic
  set the graph requires (no `OVERLAY_BINDING_MISSING`).

## Failure modes — each is a violation of this rule

Every one of these has actually occurred; each is the same defect — a mechanic that
was not embodied:

| symptom | mechanic not embodied |
|---|---|
| `SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING: 'map'` | collection/recurrence mechanics absent from `overlayBindings` |
| equity `PROVIDER_EXCHANGE_NOT_COMPLETED`; effect ops passthrough | platform effect ports not dispatched by the host (python/csharp) |
| node `INPUT_REJECTED` for a contract valid input | `contractCatalog` not carried into the plan |
| csharp `OUTCOME_REJECTED` on sidefx | cross-document `$ref` not resolvable in the schema admission mechanic |
| v1 (non-graph-native) plan for a graph-native capability | graph-native topology not carried, so collection mechanics could not be embodied |

## How to fulfil it

Four places must each carry every mechanic; a gap in any one is the defect:

1. **Estate data (rows).** `analysis.v_capability_graph_source` must expose
   everything the projection needs: the declared `scenarios`,
   `executionAuthorities`, `interfaceAuthority`, `semanticTransformations`,
   **`contractAuthorities`**, and the **graph-native topology** (from the
   capability's own declared transformation). Fix by migration.
2. **Projection (SDA compiler).** The consumer projection must emit plan `v3` for
   graph-native capabilities and carry the contract catalog and all mechanic
   slots into the per-target binding/plan for node, python and csharp.
3. **Kernel/host (per language).** Each language host must dispatch **every**
   declared mechanic — pure, collection, effect ports, declared reads, contract
   admission — from the plan/overlay. No passthrough; no language may ignore a
   declared mechanic.
4. **Estate invocation overlay.** `run-declared-graph`'s `overlayBindings` (and
   `providers`) must cover the full pure-mechanic set, the collection mechanics,
   the effect ports, and declared reads, so no invoked capability hits
   `OVERLAY_BINDING_MISSING`.

## Definition of done

- For `resolve-equity-market-price-evidence` and `resolve-sidefx-eligible-providers`
  (and every subsequent capability): node, python and csharp each run all declared
  fixtures to the expected dispositions and the same outcome digest.
- `sfx capability invoke <capability>` succeeds through the estate kernel path with
  no `OVERLAY_BINDING_MISSING` and no passthrough mechanic.
- The only code outside the database is the boot; every executable mechanic is a
  declared provider bound in the embodiment.
