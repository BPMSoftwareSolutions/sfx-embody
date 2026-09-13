# Python/C# embodiment: a data-migration strategy

2026-09-13 · Team review · How the estate reaches Python and C# by rows, not by a renderer.

This document supersedes the reading in
[cross-target-hold-report.md](../cross-target-hold-report.md) and narrows
[cross-target-embodiment.md](../cross-target-embodiment.md) to the work that is left.
It is written so the team can review the path and the reasoning, not just the
conclusion.

## 1. Purpose

The question is whether the estate can embody a capability for `python` and
`csharp` the same way it does for `node`. This document answers that question and
orders the migrations that get there. The answer is **yes, by data**, and the
reason it looked otherwise is recorded first because the team should see where the
earlier reading went wrong.

## 2. The word "blocked" (settled)

For this workstream a thing is **blocked** only if it cannot be done through the
standard data-migration/change lifecycle — that is, only if it would force a
language-kernel change in *every conforming language*. Nothing else is a blocker;
it is unwritten data.

- A missing provider, binding, profile, contract or fixture is a **migration**.
- A kernel change in all languages is a **blocker**.

Everything in this document is a migration. The word "hold" is used only for a
*step that has not been authored yet*, never for a capability of the system.

## 3. Evidence: the model already carries the runtime

Measured against the committed database, 2026-09-13.

| Committed row set | Count |
| --- | ---: |
| `model.mechanic` | 191 |
| `model.provider` / `model.provider_definition` | 74 / 74 |
| `model.provider_mechanic_implementation` | 314 |
| `model.provider_capability_implementation` | 38 |
| `model.provider_port_implementation` | 0 |
| `model.provider_profile` / `model.provider_profile_version` | 6 / 6 |
| `model.provider_slot` | 55 |
| `model.slot_port_requirement` | 41 |
| `model.blueprint_node` | 449 |
| `model.fixture` | 1157 |
| `model.observable_condition` | 597 |
| `model.proof_obligation` | 0 |
| **`model.provider_binding_scope`** | **0** |
| **`model.provider_binding`** | **0** |

The runtime the estate is trying to build is already described:

- **Mechanics** are declared by id: `cli-delivery`, `declared-query-evaluation`,
  `scenario-orchestration`, `scenario-invocation`, `event-port-invocation`,
  `semantic-execution`, `semantic-execution-graph-compilation`, `runtime-projection`,
  `state-projection`, `consumer-projection-publication`,
  `capsule-contained-module-materialization`, `schema-admission`,
  `authority-resolution`, `contract-document-reading`, `json-reading`,
  `bounded-projected-fixture-execution`, and more (191 total).
- **Providers per language** are declared and each declares which mechanics it
  implements:

  | Language | Example declared providers | Registry authority |
  | --- | --- | --- |
  | node | `ScenarioKernel.NodePlatform`, `ScenarioKernel.NodePlatform.Interface.JsonCli`, `ScenarioKernel.NodePlatform.Interface.JsonQueryCli`, `ScenarioKernel.NodePlatform.Execution.AuthorityTransformation`, `ScenarioKernel.NodePlatform.Effects.GovernedHttpExchange` | `node-mechanic-registry-authority.v1` |
  | python | `scenario_kernel.platform.consumer`, `scenario_kernel.adapters.SemanticTransformationEngine`, `scenario_kernel.adapters.JsonSchemaContractValidator` | `python-mechanic-registry-authority.v1` |
  | csharp | `ScenarioKernel.Adapters.Consumer.AdmittedConsumerPlatform`, `ScenarioKernel.Adapters.Consumer.SemanticTransformationEngine`, `ScenarioKernel.Adapters.Schema.JsonSchemaContractValidator` | `csharp-mechanic-registry-authority.v1` |

- **Profiles** group them per language, two each: a pure evaluator and an effect
  host.

  | Profile id | Authority |
  | --- | --- |
  | `node-deterministic-semantic-value-provider.v1` | `node-mechanic-registry-authority.v1` |
  | `node-profile-bound-physical-provider.v1` | `node-mechanic-registry-authority.v1` |
  | `python-deterministic-semantic-value-provider.v1` | `python-mechanic-registry-authority.v1` |
  | `python-profile-bound-physical-provider.v1` | `python-mechanic-registry-authority.v1` |
  | `csharp-deterministic-semantic-value-provider.v1` | `csharp-mechanic-registry-authority.v1` |
  | `csharp-profile-bound-physical-provider.v1` | `csharp-mechanic-registry-authority.v1` |

- **Slots** are declared as blueprint nodes. 55 slots exist with 41 port
  requirements (`slot_port_requirement`). `slot_mechanic_requirement` currently
  has 0 rows and `provider_port_implementation` is 0, so the port → mechanic →
  provider chain the requirement diagnostic needs is not yet complete in rows.

**Two things are missing, not one.**

**1. The selection.** `provider_binding_scope` and `provider_binding` are empty.
The slots say what they need; the providers say what they implement; the profiles
say how to group them. Nothing says *which provider fills which slot for which
target*. That selection currently lives in `src/` — in `materialize-node.mjs` and
`src/resolvers/node/consumer-object-provider.mjs`, keyed on `'node'`.

**2. Per-target implementation coverage for some mechanics.** The 38
`provider_capability_implementation` rows are **all Node**
(`ScenarioKernel.NodePlatform*`), and provider coverage per mechanic is uneven.
Measured node/python/csharp/cpp provider counts:

| Mechanic | node | python | csharp | cpp |
| --- | ---: | ---: | ---: | ---: |
| `cli-delivery` | 1 | 1 | 1 | 0 |
| `declared-query-evaluation` | 1 | **0** | 1 | 0 |
| `consumer-projection-publication` | 1 | **0** | **0** | 0 |
| `event-port-invocation` | 31 | 2 | 3 | 0 |
| `json-reading` | 2 | 1 | 2 | 0 |
| `runtime-projection` | 1 | 3 | 2 | 1 |
| `scenario-orchestration` | 1 | 3 | 1 | 1 |
| `schema-admission` | 2 | 3 | 3 | 1 |
| `semantic-execution` | 1 | 3 | 2 | 1 |
| `state-projection` | 2 | 2 | 2 | 0 |
| `authority-resolution` | 1 | 3 | 2 | 1 |
| `contract-document-reading` | 1 | 3 | 2 | 1 |

So target neutrality is not "teach the renderer Python." It is (a) author the
binding rows, and (b) where a target has no provider for a required mechanic,
author the provider implementation — an implementation row, still not a kernel
change.

## 4. Why the earlier "hold" was a code-shape mismatch

The hold report recorded `SELECTED_NATIVE_MECHANIC_BODY_NOT_RECOGNIZED`, the
estate's Node renderer parsing `semantic_transformation_evaluator.py` as JS. That
is a symptom of the estate choosing the provider in code. It picked the Node
provider for a Python request and then tried to parse a Python file with a Node
parser.

The report then observed that Python/C# "embody a plan, not per-port bodies." That
observation is correct and it is decisive, but the conclusion drawn from it — that
the renderer must be a per-target swap — is not. Both shapes reduce to the same
declared pattern:

| | Node today (undeclared) | Python / C# today (undeclared) | Declared form |
| --- | --- | --- | --- |
| Selection | `planNode`/renderer hardcodes `'node'` | no selection exists | `provider_binding_scope` + `provider_binding` |
| Provider | Node modules under `src/resolvers/node` | `scenario_kernel.platform.consumer`, `AdmittedConsumerPlatform` | `provider_definition` (already declared) |
| Artifact | per-port body modules + kernel | seam loading a projected binding + execution plan | the projected plan carried in `consumer-execution-embodiment-projection-context` |
| Execution | `loadMemoryScenario` (node vm) | target kernel graph scheduler | declared execution boundary, provider-selected |

The two are not competing embodiment contracts. They are the same contract — a
declared provider executes a projected plan — with the node flavor currently
carrying its plan as code. The estate already declares the plan-only form:
`project-consumer-execution-embodiment-v2` composes `admit → derive → render →
observe`. Its declared contracts (measured) are input
`consumer-execution-embodiment-projection-context` and outcome
`projected-consumer-execution-embodiment-candidate`; the child pipeline chains
`consumer-execution-embodiment-projection-context` →
`admitted-consumer-execution-embodiment-projection-context` →
`consumer-execution-embodiment-projection-graph` →
`projected-consumer-execution-embodiment-bundle` →
`projected-consumer-execution-embodiment-candidate`.

An earlier draft of this document claimed it yields
`consumer-execution-embodiment-plan.v2`; that is **wrong**. The admitted projection
context carries the projected **plan** as an input presupposition; this capability
consumes it. Measured: **no scenario in the selected model declares
`consumer-execution-embodiment-projection-context` as an outcome**, so the model
names the composition's starting point but no producer for it. Naming and declaring
that producer is a prerequisite before treating the plan path as ready. The
canonical drafts are
[`python-csharp-embodiment/project-consumer-execution-embodiment-plan.feature`](python-csharp-embodiment/project-consumer-execution-embodiment-plan.feature)
(NEW — the producer) and
[`python-csharp-embodiment/project-consumer-execution-embodiment-v2.feature`](python-csharp-embodiment/project-consumer-execution-embodiment-v2.feature)
(UPDATE — consumes a produced context).

## 5. The strategic path

Ordered so each migration is reviewable on its own and every step is a
`ROLLBACK`-defaulted migration under `sql/migrations/`. The lifecycle is in
[AGENTS.md](../../AGENTS.md) and [sql/README.md](../../sql/README.md).

Each step names the canonical `.feature` draft that declares the behavior it
implements. All drafts are in [`python-csharp-embodiment/`](python-csharp-embodiment/)
with status and rationale in its [`README.md`](python-csharp-embodiment/README.md),
and they are summarized at the end of this section.

### M0 — Baseline (evidence, no change)

Record the working generation for `resolve-equity-market-price-evidence` per
target: `construct-embodiment-plan` plan/artifact digests for `node`, and the
current first-unmet-requirement diagnostic for `python` and `csharp`. A regression
is a diff against this.

### M1 — Make target selection a profile row

The materializer already selects the registry by `selection.target` and reads the
shared `graphProviderProfiles` pure profile. Finish the split: the target selects a
**`provider_profile`** row, and the profile names the pure evaluator and the effect
host. No `'node'` literal remains in the selection path.

- Rows: bind the selected capability's target to the `{language}-deterministic-semantic-value-provider.v1`
  and `{language}-profile-bound-physical-provider.v1` profiles.
- Verify: node `planDigest`/`artifactDigest` byte-identical to M0.
- Declared behavior: [`read-capability-authority.feature`](python-csharp-embodiment/read-capability-authority.feature),
  [`plan-capability-embodiment.feature`](python-csharp-embodiment/plan-capability-embodiment.feature),
  [`construct-embodiment-plan.feature`](python-csharp-embodiment/construct-embodiment-plan.feature).

### M2 — Populate provider bindings (the drive)

For every `provider_slot`, select the declared `provider_definition` that satisfies
the slot's requirements under the selected profile, and write
`provider_binding_scope` + `provider_binding`. `selection_policy` records how the
choice was made; `binding_role` records which requirement it satisfies.

- Rows: `provider_binding_scope` (slot → context, policy, role) and
  `provider_binding` (slot → provider definition, ordinal).
- Source of truth: the DB's `provider_capability_implementation` and
  `provider_mechanic_implementation` rows, not the runtime registries.
- Verify: a diagnostic returns the resolved provider per slot per target, and the
  carrier reads it.
- Declared behavior: [`resolve-provider-slot-bindings.feature`](python-csharp-embodiment/resolve-provider-slot-bindings.feature).

### M3 — One source for effects and contract admission

The node registry carries 31 per-port `eventPorts`; the python/csharp registries
declare `eventPorts: []` and `contractAdmissions: []`. Do **not** assume the
database implements what the registries leave out. Measured:
`provider_mechanic_implementation` = 314 but uneven per target (e.g.
`consumer-projection-publication` is Node-only; `declared-query-evaluation` has no
Python implementation), and all 38 `provider_capability_implementation` rows are
Node. First establish the actual requirements per target — `slot_mechanic_requirement`
is empty and `provider_port_implementation` is 0, so the port → mechanic → provider
chain is not yet in rows — then reconcile coverage on the database.

- Rows: bind the effect and admission slots; where a target has no implementation,
  author the provider implementation row.
- Verify: the per-target requirement diagnostic resolves from rows and reports the
  remaining unimplemented requirements **explicitly**, rather than assuming zero.
- Declared behavior: [`resolve-provider-slot-bindings.feature`](python-csharp-embodiment/resolve-provider-slot-bindings.feature)
  (`PROVIDER_SLOT_UNBOUND` / `PROVIDER_IMPLEMENTATION_ABSENT`).

### M4 — Bind the consumer application provider (render)

Bind the declared per-target consumer application provider
(`scenario_kernel.platform.consumer`, `ScenarioKernel.Adapters.Consumer.AdmittedConsumerPlatform`)
to the render/embodiment slots, exactly as the write step already binds an estate
provider. The provider's output is the seam that loads the projected plan; the
estate's job is the plan.

- Rows: slot → provider binding for the render mechanic, per profile.
- Verify: rendering for `python`/`csharp` returns a recognized artifact (no
  `SELECTED_NATIVE_MECHANIC_BODY_NOT_RECOGNIZED`).
- Declared behavior: [`write-capability-embodiment.feature`](python-csharp-embodiment/write-capability-embodiment.feature),
  [`materialize-capability-embodiment.feature`](python-csharp-embodiment/materialize-capability-embodiment.feature).

### M5 — Bind the runtime execution provider (execute the plan)

Bind the per-target execution provider (the target kernel's graph scheduler) to the
execution slots, replacing the estate's node-only `loadMemoryScenario` assumption
with a declared execution boundary.

- Rows: slot → provider binding for `scenario-orchestration` / `semantic-execution`.
- Verify: `invoke` for a Python/C# capability executes the projected plan and
  returns a declared disposition.
- Declared behavior: [`materialize-capability-embodiment.feature`](python-csharp-embodiment/materialize-capability-embodiment.feature)
  (`hold-materialization-without-bound-provider`).

### M6 — Converge node onto the plan form

Bring the node path onto the same projected plan so there is one embodiment
contract, not two. This is the point of the whole path: after M6, the only
difference between targets is a profile and a set of bindings.

- Rows: node's render/execution slots bind to its plan-form providers.
- Verify: behavior preserved — declared dispositions and all 17 memory fixtures
  unchanged. The plan/artifact digests **change by construction**:
  `materialize-node.mjs:301` hashes `{capabilityId, scenarioId, target, resolverDigest,
  files: body}` and `hash(pretty(body))`, so this migration must establish and verify
  **new** digests, not preserve the old ones.
- Declared behavior: [`materialize-capability-embodiment.feature`](python-csharp-embodiment/materialize-capability-embodiment.feature),
  [`write-capability-embodiment.feature`](python-csharp-embodiment/write-capability-embodiment.feature).

### Canonical feature drafts

Every capability this path creates or changes has a canonical draft under
[`python-csharp-embodiment/`](python-csharp-embodiment/). Status is **NEW** (the
capability does not exist in the selected model) or **UPDATE** (it exists and its
declared meaning must change).

| Draft | Status | Step | Capability |
| --- | --- | --- | --- |
| [`resolve-provider-slot-bindings.feature`](python-csharp-embodiment/resolve-provider-slot-bindings.feature) | NEW | M2, M3 | `resolve-provider-slot-bindings` |
| [`read-capability-authority.feature`](python-csharp-embodiment/read-capability-authority.feature) | UPDATE | M1, M3 | `read-capability-authority` |
| [`plan-capability-embodiment.feature`](python-csharp-embodiment/plan-capability-embodiment.feature) | UPDATE | M1, M2 | `plan-capability-embodiment` |
| [`construct-embodiment-plan.feature`](python-csharp-embodiment/construct-embodiment-plan.feature) | UPDATE | M1 | `construct-embodiment-plan` |
| [`write-capability-embodiment.feature`](python-csharp-embodiment/write-capability-embodiment.feature) | UPDATE | M4 | `write-capability-embodiment` |
| [`materialize-capability-embodiment.feature`](python-csharp-embodiment/materialize-capability-embodiment.feature) | UPDATE | M4, M5, M6 | `materialize-capability-embodiment` |
| [`project-consumer-execution-embodiment-plan.feature`](python-csharp-embodiment/project-consumer-execution-embodiment-plan.feature) | NEW | §4 | `project-consumer-execution-embodiment-plan` |
| [`project-consumer-execution-embodiment-v2.feature`](python-csharp-embodiment/project-consumer-execution-embodiment-v2.feature) | UPDATE | §4 | `project-consumer-execution-embodiment-v2` |

The drafts state proposed contract identities that are not yet declared rows; they
become real when the migration is authored. Every `Scenario` in a draft is behavior
the corresponding migration must satisfy and verify.

## 6. Flywheel opportunities

Each step compounds; none is one-off.

1. **Binding flywheel.** Adding a target becomes authoring binding rows against
   providers that exist. cpp/go/java are `NOT_OBSERVABLE` because their registries
   do not exist yet; python/csharp registries exist but per-mechanic coverage is
   uneven, so a target may also need a provider-implementation row. Either way it
   is rows, never a kernel change.
2. **Provider catalog flywheel.** `provider_mechanic_implementation` is already at
   314 across 74 providers. Every new provider self-registers its mechanics, so the
   next target's requirements resolve against the catalog instead of a fresh
   audit.
3. **Plan flywheel.** Once node is on the plan form (M6), every target executes the
   same declared plan. A capability authored once is executable on every profile
   that binds the plan's mechanics. This is the cross-target equivalent of the
   SQL→CLI flywheel: author once, observe everywhere.
4. **Requirement-diagnostic flywheel.** `CAN_ATTEMPT_EMBODIMENT` /
   `NOT_OBSERVABLE` / first-unmet-requirement diagnostics are computed from rows.
   Authoring a provider or binding moves the diagnostic without any code change, so
   the path to readiness is legible per capability per target.

## 7. Success criteria

- For `resolve-equity-market-price-evidence` on `node`, `python`, `csharp`: a
  declared disposition from `invoke`, with `observe` streaming telemetry.
- Node `planDigest`/`artifactDigest` byte-identical across M1–M3 (selection and
  binding must not move node's body).
- Through M6, node **behavior** is unchanged (dispositions, 17 fixtures); the
  digests change by construction and the new values are verified.
- The per-target readiness diagnostic resolves from rows and reports remaining
  unimplemented requirements explicitly (not a bare zero).
- No `'node'` literal in the target-selection path.

## 8. Open decisions for the team

1. **M6 or not.** Do we converge node onto the projected plan, or keep the node
   per-port body as a declared profile-optimized path? Convergence is cleaner but
   touches the node embodiment; the alternative keeps two artifacts but one
   selection mechanism.
2. **Registry vs database authority** (M3). Confirm the database is sole authority
   for effects and admissions, with registries reduced to language-resolution
   declarations.
3. **Binding granularity.** One binding per slot per target, or one per slot with a
   profile-scoped policy? `provider_binding_scope.selection_policy` supports either;
   the team should pick the reviewable form.

## 9. Evidence appendix

All queries run read-only with `--committed`.

```sql
-- The runtime is declared.
SELECT 'mechanic' t, COUNT_BIG(*) n FROM model.mechanic
UNION ALL SELECT 'provider', COUNT_BIG(*) FROM model.provider
UNION ALL SELECT 'provider_mechanic_implementation', COUNT_BIG(*) FROM model.provider_mechanic_implementation
UNION ALL SELECT 'provider_capability_implementation', COUNT_BIG(*) FROM model.provider_capability_implementation
UNION ALL SELECT 'provider_slot', COUNT_BIG(*) FROM model.provider_slot
UNION ALL SELECT 'fixture', COUNT_BIG(*) FROM model.fixture;
-- mechanic 191, provider 74, provider_mechanic_implementation 314,
-- provider_capability_implementation 38, provider_slot 55, fixture 1157

-- The selection is missing.
SELECT 'provider_binding_scope' t, COUNT_BIG(*) n FROM model.provider_binding_scope
UNION ALL SELECT 'provider_binding', COUNT_BIG(*) FROM model.provider_binding;
-- 0, 0

-- Per-language provider coverage is uneven (this corrects the first draft's claim
-- that every mechanic has node, python and csharp providers).
SELECT m.mechanic_id,
       SUM(CASE WHEN p.provider_id LIKE 'ScenarioKernel.NodePlatform%' THEN 1 ELSE 0 END) node_n,
       SUM(CASE WHEN p.provider_id LIKE 'scenario[_]kernel%' OR p.provider_id LIKE 'scenario.kernel%' THEN 1 ELSE 0 END) python_n,
       SUM(CASE WHEN p.provider_id LIKE 'ScenarioKernel.Adapters%' THEN 1 ELSE 0 END) csharp_n,
       SUM(CASE WHEN p.provider_id LIKE 'sda::%' THEN 1 ELSE 0 END) cpp_n
FROM model.provider_mechanic_implementation i
JOIN model.provider_definition pd ON pd.provider_definition_pk = i.provider_definition_pk
JOIN model.provider p ON p.provider_pk = pd.provider_pk
JOIN model.mechanic_version mv ON mv.mechanic_version_pk = i.mechanic_version_pk
JOIN model.mechanic m ON m.mechanic_pk = mv.mechanic_pk
WHERE m.mechanic_id IN ('cli-delivery','declared-query-evaluation','scenario-orchestration',
  'runtime-projection','schema-admission','consumer-projection-publication')
GROUP BY m.mechanic_id ORDER BY m.mechanic_id;
-- cli-delivery 1/1/1/0; declared-query-evaluation 1/0/1/0;
-- consumer-projection-publication 1/0/0/0; schema-admission 2/3/3/1;
-- runtime-projection 1/3/2/1; scenario-orchestration 1/3/1/1

-- Capability implementations are Node-only.
SELECT p.provider_id, COUNT_BIG(*) n
FROM model.provider_capability_implementation i
JOIN model.provider_definition pd ON pd.provider_definition_pk = i.provider_definition_pk
JOIN model.provider p ON p.provider_pk = pd.provider_pk
GROUP BY p.provider_id;
-- 38 rows, every one ScenarioKernel.NodePlatform*

-- The declared embodiment composition's contracts (it does not output plan.v2).
SELECT s.scenario_id, i.input_id, o.outcome_id
FROM model.capability c
JOIN model.estate_capability ec ON ec.capability_pk = c.capability_pk
JOIN model.capability_scenario cs ON cs.capability_version_pk = ec.capability_version_pk
JOIN model.scenario s ON s.scenario_pk = cs.scenario_pk
JOIN model.scenario_version sv ON sv.scenario_version_pk = cs.scenario_version_pk
LEFT JOIN model.scenario_input i ON i.scenario_version_pk = sv.scenario_version_pk
LEFT JOIN model.scenario_outcome o ON o.scenario_version_pk = sv.scenario_version_pk
WHERE c.capability_id = 'project-consumer-execution-embodiment-v2';
-- input consumer-execution-embodiment-projection-context
-- outcome projected-consumer-execution-embodiment-candidate
```

Profile binding shape (`model.provider_binding_scope` / `model.provider_binding`):
`provider_binding_scope(provider_slot_pk, binding_context_pk, binding_role, selection_policy)`
→ `provider_binding(provider_binding_scope_pk, provider_slot_pk, provider_definition_pk, selection_policy, ordinal)`.

### Corrections from review (2026-09-13)

The first draft's evidence was checked against the committed database and the
source; five claims were corrected in place and are recorded here:

1. **Provider counts do not prove per-target coverage.** All 38
   `provider_capability_implementation` rows are Node; per-mechanic coverage is
   uneven (`consumer-projection-publication` node-only; `declared-query-evaluation`
   no Python). M3 establishes requirements per target before binding.
2. **The embodiment capability's contracts were misidentified.** It takes
   `consumer-execution-embodiment-projection-context` and returns
   `projected-consumer-execution-embodiment-candidate`; it does not return
   `consumer-execution-embodiment-plan.v2`, and no scenario emits its input context.
3. **`declared-query-evaluation` is not the SQL reader** — see the companion
   strategy §5 Phase 1.
4. **Fixture totals do not prove verification equivalence** — see the companion
   strategy §5 Phase 5.
5. **A plan-form node body changes the digests**, by construction
   (`materialize-node.mjs:301`); M6 verifies behavior, then verifies new digests.

## 10. Artifacts

| Purpose | Path |
| --- | --- |
| This strategy | `docs/strategy/python-csharp-embodiment.md` |
| Canonical feature drafts | `docs/strategy/python-csharp-embodiment/` (8 `.feature` + `README.md`) |
| Prior hold report (superseded reading) | `docs/cross-target-hold-report.md` |
| Platform-layer history | `docs/cross-target-embodiment.md` |
| Embodiment capability model | `docs/embodiment-as-capability.md` |
| Provider/mechanic inventory | `docs/research/platform-mechanic-honesty.md` |
| Lifecycle | `AGENTS.md`, `sql/README.md` |

Every migration in this path defaults to `ROLLBACK` for review and is installed by
changing the final `ROLLBACK` to `COMMIT`.
