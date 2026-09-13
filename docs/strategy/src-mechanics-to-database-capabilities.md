# Transitioning `src/` mechanics to database capabilities: a data-migration strategy

2026-09-13 · Team review · Every operational mechanic in `src/` is an un-declared
row that already has a home in the model.

This document inventories the hand-authored mechanics in `sfx-embody/src`, shows
that the database already declares the runtime they implement, and orders the
migrations that move the work from code to rows. It is the operational companion
to [python-csharp-embodiment.md](python-csharp-embodiment.md).

## 1. The rule

The database is the authority. The CLI is a fixed carrier of arguments and
streams; it owns no meaning. The host language runtime exists but is not authored
by us. The **only** code the architecture legitimizes is a **declared provider
implementation** — an external adapter referenced by a mechanic id through
`provider_definition` and selected by `provider_binding`. Everything that decides
*what happens, in what order, for which target* is a row.

The corollary, and the reason this document exists:

> A hand-authored `.mjs` that drives operational behavior is not a component. It
> is a finding — an unwritten row, or a set of them.

And the definition of **blocked**: something is blocked only if it cannot be
produced through the data-migration/change lifecycle, i.e. only if it would force
a language-kernel change in every conforming language. Nothing in this inventory is
blocked.

## 2. What `src/` is today

26 `.mjs` files, 4,025 lines, grouped by the mechanic each implements:

| Group | Files | Lines | Representative files |
| --- | ---: | ---: | --- |
| Reads | 5 | 567 | `read-authority.mjs`, `list-capabilities.mjs`, `read-capability-meaning.mjs` |
| Delivery / carrier | 3 | 405 | `invoke-database-capability.mjs`, `database-delivery.mjs`, `embodiment-delivery.mjs` |
| Preparation | 1 | 86 | `prepare-database-capability.mjs` |
| Plan / render / load | 3 | 730 | `materialize-node.mjs`, `resolvers/node/consumer-object-provider.mjs`, `load-memory-scenario.mjs` |
| Node lowering | 1 | 190 | `resolvers/node/native-expression-projection.mjs` |
| Estate providers | 3 | 123 | `resolvers/node/{authority-read,embodiment-plan,embodiment-write}-provider.mjs` |
| Reveal / narration / circuit | 5 | 1,124 | `narrate-capability-{meaning,markdown}.mjs`, `diagram-{blueprint,capability}-circuit.mjs` |
| Integrity / policy | 2 | 229 | `observe-capability-integrity.mjs`, `restrict-memory-process.mjs` |
| Verification | 3 | 571 | `verification/verify-{node,native-projection,contract-fidelity}.mjs` |

Two immediate observations from the code itself:

- `list-capabilities.mjs` embeds its SQL as a string literal (`const LIST_SQL = …`)
  while `read-authority.mjs` reads `.sql` files. Same mechanic, two homes: the
  query is data either way, and one of them was typed into a `.mjs` by mistake.
- `database-delivery.mjs` and `embodiment-delivery.mjs` are byte-identical except
  for one policy line — `restrictMemoryProcess(config)` versus a literal
  `processEvidence { fsWriteAllowed: true, authorizedWriteRoot: 'embodiments' }`.
  The difference is a policy, not behavior.

That pattern — one mechanic, N instances, each instance re-authored in code — is
the whole opportunity.

## 3. The discovery: the model already declares the runtime

Measured against the committed database, 2026-09-13.

| Committed row set | Count |
| --- | ---: |
| `model.mechanic` | 191 |
| `model.provider` / `model.provider_definition` | 74 / 74 |
| `model.provider_mechanic_implementation` | 314 |
| `model.provider_capability_implementation` | 38 |
| `model.provider_profile` / `model.provider_profile_version` | 6 / 6 |
| `model.provider_slot` | 55 |
| `model.slot_port_requirement` | 41 |
| `model.fixture` | 1157 |
| `model.observable_condition` | 597 |
| **`model.provider_binding_scope`** | **0** |
| **`model.provider_binding`** | **0** |

The 191 declared mechanics include the exact operations `src/` performs by hand:
`cli-delivery`, `query-cli-delivery`, `query-command-dispatch`,
`declared-query-evaluation`, `json-reading`, `contract-document-reading`,
`schema-admission`, `authority-resolution`, `contract-validation`,
`governed-feature-reference-resolution`, `scenario-orchestration`,
`scenario-invocation`, `event-port-invocation`, `semantic-execution`,
`semantic-execution-graph-compilation`, `capsule-contained-module-materialization`,
`runtime-projection`, `state-projection`, `consumer-projection-publication`,
`experience-authority-projection`, `interaction-authority-projection`,
`accessibility-intent-projection`, `transition-binding-projection`,
`authority-binding-projection`, `semantic-layout-projection`,
`bounded-projected-fixture-execution`, `observable-view-state`, `ordered-findings`,
`deterministic-finding-order`, `bounded-declared-resource-observation`,
`post-effect-absence-proof`, and more.

The 74 providers declare which mechanics they implement
(`provider_mechanic_implementation` = 314), and the 6 profiles group them per
language. The 55 slots declare what each capability needs
(`slot_port_requirement` = 41, plus `slot_mechanic_requirement` and
`slot_profile_requirement`). The 1,157 fixtures and 597 observable conditions are
the expectations the verification code re-expresses.

What is missing is the drive: `provider_binding_scope` and `provider_binding` are
empty. The model knows every mechanic, every implementation, every slot
requirement and every expectation. It does not know **which provider fills which
slot** — and that selection is exactly what `src/` hardcodes, keyed on `'node'`.

**The migration is therefore not "reimplement the runtime as data." The model is
already the runtime. It is to populate the drive and delete the shadow.**

## 4. Disposition: `src/` → declared mechanic → declared provider

| `src/` group | Declared mechanics | Declared providers (example) | Replaced by |
| --- | --- | --- | --- |
| Reads | `declared-query-evaluation`, `json-reading`, `contract-document-reading`, `query-cli-delivery`, `query-command-dispatch` | `ScenarioKernel.NodePlatform.Interface.JsonQueryCli`, `…Interface.JsonCli` | declared query rows + the carrier's query runner |
| Delivery / carrier | `cli-delivery` | `ScenarioKernel.NodePlatform.Interface.JsonCli`, `scenario_kernel.platform.consumer` | one carrier + a declared delivery policy |
| Delivery policy (fs-write / memory-only) | `authorized-file-system-plan-execution`, `bounded-declared-resource-observation`, `post-effect-absence-proof` | per profile | `processEvidence` as a policy row |
| Preparation | `schema-admission`, `authority-resolution`, `contract-validation`, `governed-feature-reference-resolution` | `…Schema.JsonSchemaContractAdmission`, `ScenarioKernel.Adapters.Schema.JsonSchemaContractValidator` | binding rows + declared admission |
| Plan / render / load | `scenario-orchestration`, `runtime-projection`, `state-projection`, `semantic-execution`, `semantic-execution-graph-compilation`, `capsule-contained-module-materialization`, `consumer-projection-publication` | `ScenarioKernel.NodePlatform.Execution.*`, `…Projection.*` | declared embodiment plan + bound providers |
| Node lowering | `state-projection` | `ScenarioKernel.NodePlatform.Projection.AuthorityTransformation`, `…Projection.DeclarativeStateProjection` | the declared evaluator (removes the lowering) |
| Estate providers | the provider's mechanic | the module as a `provider_definition` | provider definition + binding |
| Reveal / narration / circuit | `experience-authority-projection`, `interaction-authority-projection`, `accessibility-intent-projection`, `transition-binding-projection`, `authority-binding-projection`, `semantic-layout-projection` | projection providers | declared projections |
| Integrity / policy | `bounded-projected-fixture-execution`, `observable-view-state`, `ordered-findings`, `deterministic-finding-order` | evaluation providers | declared fixtures/conditions + evaluation |
| Verification | `bounded-projected-fixture-execution`, `exact-evaluation-receipt`, `exact-validation-receipt` | evaluation providers | the 1,157 declared fixtures + 597 conditions |

None of these requires a kernel change. Each is a row set.

## 5. The migration path

Ordered so each phase is independently reviewable and each is a
`ROLLBACK`-defaulted migration under `sql/migrations/`. Lifecycle:
[AGENTS.md](../../AGENTS.md), [sql/README.md](../../sql/README.md).

### Phase 0 — Baseline (evidence, no change)

Capture the working generation per capability: `invoke` disposition, `observe`
telemetry, `planDigest`/`artifactDigest`. Every later phase is a diff against
this. No code and no rows change.

### Phase 1 — Reads

Declare the queries the readers run (starting with the inline `LIST_SQL`) beside
`capability-embodiment.sql`, and let the carrier execute *any* declared query
generically. The five read files collapse to one generic runner plus rows.

- Rows: a query per read, addressed by id, executed by `declared-query-evaluation`.
- Verify: `sfx capability reveal` and list/find outputs byte-identical to Phase 0.

### Phase 2 — Carrier and delivery policy

Reduce `database-delivery.mjs` and `embodiment-delivery.mjs` to one carrier whose
authorization is a declared policy (`fsWriteAllowed`, `authorizedWriteRoot`,
cache-read and storage-proof controls). The two files were already one transport
with two literals.

- Rows: delivery policy per governed boundary.
- Verify: the memory-only proof and the write delivery both hold; no behavioral
  diff.

### Phase 3 — Provider bindings (the drive)

For every `provider_slot`, select the declared `provider_definition` satisfying the
slot's requirements and write `provider_binding_scope` + `provider_binding`. This
is the phase that lets the carrier resolve a provider from a row rather than from a
`'node'` branch. It is shared with the cross-target path; see
[python-csharp-embodiment.md](python-csharp-embodiment.md) §5 M2.

- Rows: `provider_binding_scope(slot, context, role, policy)` and
  `provider_binding(scope, slot, provider_definition, ordinal)`.
- Verify: a diagnostic returns the resolved provider per slot; node execution and
  all 17 memory fixtures unchanged.

### Phase 4 — Projections

Move narration, reveal and circuit rendering onto declared projections:
`experience-authority-projection`, `interaction-authority-projection`,
`accessibility-intent-projection`, `semantic-layout-projection`. The two narrators
(text, markdown) become one projection with two formats; the two circuit diagrams
become one projection over two graphs.

- Rows: projection per output format/graph.
- Verify: rendered output matches Phase 0 for each format.

### Phase 5 — Verification and expectations

The 1,157 fixtures and 597 observable conditions are already committed. Point the
verification runs at them through `bounded-projected-fixture-execution` and retire
the per-file assertion code. Integrity observation (`observable-view-state`,
`ordered-findings`, `deterministic-finding-order`) becomes declared evaluation.

- Rows: fixture/obligation references (no new expectations need authoring for the
  current estate; they exist).
- Verify: `verify:estate` / `verify:memory` unchanged.

### Phase 6 — Retire the body generator

Once providers are bound and plans are declared, the declaration *is* the body. The
generate-and-run triple — `materialize-node`, `consumer-object-provider`,
`load-memory-scenario` — collapses into the carrier executing declared operations
with bound providers. `native-expression-projection` is subsumed by the declared
evaluator.

- Rows: the embodiment plan (already declared via
  `project-consumer-execution-embodiment-v2`) plus the render/execution bindings.
- Verify: node `planDigest`/`artifactDigest` and every fixture unchanged; `src/`
  reduced to the carrier, the generic reader, and the host runtime.

## 6. Flywheel opportunities

1. **Declare once, reuse everywhere.** A mechanic declared once (e.g.
   `declared-query-evaluation`) serves every capability that reads. Today each read
   instance is code; after Phase 1 each is a row referencing a shared mechanic.
2. **Provider catalog compounding.** 74 providers already declare 314 mechanic
   implementations. Every new provider resolves the next capability's requirements
   against the catalog instead of a fresh audit.
3. **Selection as data.** After Phase 3, changing which provider serves a slot, or
   adding a target, is a binding row. The same change serves every capability that
   uses that slot — the reuse is structural, not copied.
4. **Expectations already paid for.** 1,157 fixtures and 597 conditions mean the
   verification flywheel does not begin from zero; it begins by pointing at rows
   that already exist.
5. **The cross-project flywheel.** The SDA language runtimes repeat the same
   mechanics per language. Once the mechanic/binding model is the single source,
   those repetitions become instances of one declared catalog rather than parallel
   codebases.

The compounding form:

```
one mechanic declared  ──►  N capabilities bind it  ──►  M targets select a provider
        (rows)                    (rows)                        (rows)
```

Each conversion deletes code once and serves every instance thereafter.

## 7. Measurement

Counts, not effort estimates (the rubric forbids invented numbers):

| Measure | Today | Direction |
| --- | ---: | --- |
| Hand-authored `src/` files | 26 | → carrier + reader |
| Hand-authored `src/` lines | 4,025 | → minimized |
| Declared mechanics | 191 | reused, not duplicated |
| Declared provider implementations | 314 | grows with new providers |
| Declared fixtures / conditions | 1,157 / 597 | already the expectations |
| **Missing bindings** | **0 of 55 slots** | the drive to author |

The single most leverage-bearing row set is the binding: it is the one thing the
model lacks and the one thing the code hardcodes.

## 8. Non-negotiables

- On the database surface it is *all rows*. No capsule / artifact / retained-source
  / projection vocabulary in migrations.
- Never edit `src/` to change a capability's meaning. `src/` is a finding site, not
  an authority.
- Do not invent provider or kernel behavior to make an invocation pass. A domain
  concern the runtime implements is a finding, not a reason to edit the kernel.
- One migration per commit; author, dry-run, preflight-in-transaction, install,
  verify, then commit.
- "Blocked" is reserved for a kernel change in all conforming languages.

## 9. Evidence appendix

```sql
-- The drive is missing.
SELECT 'provider_binding_scope' t, COUNT_BIG(*) n FROM model.provider_binding_scope
UNION ALL SELECT 'provider_binding', COUNT_BIG(*) FROM model.provider_binding;
-- 0, 0

-- The mechanics the estate hardcodes are declared.
SELECT mechanic_id FROM model.mechanic
WHERE mechanic_id IN ('cli-delivery','query-cli-delivery','query-command-dispatch',
  'declared-query-evaluation','json-reading','contract-document-reading','schema-admission',
  'authority-resolution','scenario-orchestration','scenario-invocation','event-port-invocation',
  'semantic-execution','semantic-execution-graph-compilation',
  'capsule-contained-module-materialization','runtime-projection','state-projection',
  'consumer-projection-publication','experience-authority-projection',
  'interaction-authority-projection','accessibility-intent-projection',
  'semantic-layout-projection','bounded-projected-fixture-execution','observable-view-state',
  'ordered-findings','deterministic-finding-order','bounded-declared-resource-observation',
  'post-effect-absence-proof')
ORDER BY mechanic_id;
-- all 27 declared

-- Slots declare their requirements; nothing binds them.
SELECT bn.node_kind, COUNT_BIG(*) n
FROM model.provider_slot ps
JOIN model.blueprint_node bn ON bn.blueprint_node_pk = ps.owner_node_pk
GROUP BY bn.node_kind;
-- provider-slot 55

-- Per-language providers implement the mechanics.
SELECT p.provider_id, m.mechanic_id
FROM model.provider_mechanic_implementation i
JOIN model.provider_definition pd ON pd.provider_definition_pk = i.provider_definition_pk
JOIN model.provider p ON p.provider_pk = pd.provider_pk
JOIN model.mechanic_version mv ON mv.mechanic_version_pk = i.mechanic_version_pk
JOIN model.mechanic m ON m.mechanic_pk = mv.mechanic_pk
WHERE m.mechanic_id = 'cli-delivery';
-- ScenarioKernel.NodePlatform.Interface.JsonCli (node),
-- ScenarioKernel.Adapters.Consumer.AdmittedConsumerPlatform (csharp),
-- scenario_kernel.platform.consumer (python)
```

Binding shape:

```
model.provider_slot(blueprint_version_pk, slot_id, owner_node_pk)
model.slot_port_requirement(provider_slot_pk, port_version_pk, ordinal, role)
model.slot_mechanic_requirement(provider_slot_pk, mechanic_version_pk, ordinal, role)
model.slot_profile_requirement(provider_slot_pk, provider_profile_version_pk, ordinal, role)
model.provider_binding_scope(provider_slot_pk, binding_context_pk, binding_role, selection_policy)
model.provider_binding(provider_binding_scope_pk, provider_slot_pk, provider_definition_pk,
                       selection_policy, ordinal)
```

## 10. Artifacts

| Purpose | Path |
| --- | --- |
| This strategy | `docs/strategy/src-mechanics-to-database-capabilities.md` |
| Cross-target strategy | `docs/strategy/python-csharp-embodiment.md` |
| Flywheel precedent | `docs/database-mutation-flywheels.md` |
| Embodiment capability model | `docs/embodiment-as-capability.md` |
| Provider/mechanic honesty inventory | `docs/research/platform-mechanic-honesty.md` |
| Decision rubric | `docs/sidefx-architecture-decision-rubric.md` |
| Lifecycle | `AGENTS.md`, `sql/README.md` |

Every migration in this path defaults to `ROLLBACK` for review and is installed by
changing the final `ROLLBACK` to `COMMIT`.
