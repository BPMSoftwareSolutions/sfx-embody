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

- **Slots** are declared as blueprint nodes and state their requirements
  (`slot_port_requirement`, `slot_mechanic_requirement`,
  `slot_profile_requirement`). 55 slots exist with 41 port requirements.

**The one missing row set is the selection:** `provider_binding_scope` and
`provider_binding` are empty. The slots say what they need; the providers say what
they implement; the profiles say how to group them. Nothing says *which provider
fills which slot for which target*. That selection currently lives in
`src/` — in `materialize-node.mjs` and `src/resolvers/node/consumer-object-provider.mjs`,
keyed on `'node'`.

So target neutrality is not "teach the renderer Python." It is **author the
binding rows**, after which the carrier resolves a provider the way it already
resolves a contract.

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
| Artifact | per-port body modules + kernel | seam loading a projected binding + execution plan | the projected plan (`consumer-execution-embodiment-plan.v2`) |
| Execution | `loadMemoryScenario` (node vm) | target kernel graph scheduler | declared execution boundary, provider-selected |

The two are not competing embodiment contracts. They are the same contract — a
declared provider executes a projected plan — with the node flavor currently
carrying its plan as code. The estate already declares the plan-only form:
`project-consumer-execution-embodiment-v2` composes `admit → derive → render →
observe` and yields `consumer-execution-embodiment-plan.v2`. Python and C# are
already past the renderer question; they are waiting on the binding rows and on
node being brought onto the same plan form.

## 5. The strategic path

Ordered so each migration is reviewable on its own and every step is a
`ROLLBACK`-defaulted migration under `sql/migrations/`. The lifecycle is in
[AGENTS.md](../../AGENTS.md) and [sql/README.md](../../sql/README.md).

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

### M3 — One source for effects and contract admission

The node registry carries 31 per-port `eventPorts`; the python/csharp registries
declare `eventPorts: []` and `contractAdmissions: []`. The database already holds
the implementations (`provider_mechanic_implementation` = 314,
`provider_capability_implementation` = 38). Reconcile on the database: the planner
resolves effects and admissions from the binding rows, and the registries stop
being a second, partial source.

- Rows: bind the effect and admission slots so all three targets resolve from the
  same rows.
- Verify: the per-target requirement diagnostic goes to zero for the selected
  scenarios, and node execution is unchanged.

### M4 — Bind the consumer application provider (render)

Bind the declared per-target consumer application provider
(`scenario_kernel.platform.consumer`, `ScenarioKernel.Adapters.Consumer.AdmittedConsumerPlatform`)
to the render/embodiment slots, exactly as the write step already binds an estate
provider. The provider's output is the seam that loads the projected plan; the
estate's job is the plan.

- Rows: slot → provider binding for the render mechanic, per profile.
- Verify: rendering for `python`/`csharp` returns a recognized artifact (no
  `SELECTED_NATIVE_MECHANIC_BODY_NOT_RECOGNIZED`).

### M5 — Bind the runtime execution provider (execute the plan)

Bind the per-target execution provider (the target kernel's graph scheduler) to the
execution slots, replacing the estate's node-only `loadMemoryScenario` assumption
with a declared execution boundary.

- Rows: slot → provider binding for `scenario-orchestration` / `semantic-execution`.
- Verify: `invoke` for a Python/C# capability executes the projected plan and
  returns a declared disposition.

### M6 — Converge node onto the plan form

Bring the node path onto the same projected plan so there is one embodiment
contract, not two. This is the point of the whole path: after M6, the only
difference between targets is a profile and a set of bindings.

- Rows: node's render/execution slots bind to its plan-form providers.
- Verify: node `planDigest`/`artifactDigest` and all 17 memory fixtures unchanged.

## 6. Flywheel opportunities

Each step compounds; none is one-off.

1. **Binding flywheel.** Adding a target becomes authoring binding rows against
   providers that already exist. cpp/go/java are `NOT_OBSERVABLE` only because
   their registries do not exist yet — the moment a registry exists, the binding
   migration is mechanical.
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
- Node `planDigest`/`artifactDigest` byte-identical across M1–M3 and unchanged
  through M6.
- The per-target readiness diagnostic resolves from rows and reads zero unmet
  requirements for the selected scenarios.
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

-- Per-language providers implement the mechanics the estate hardcodes.
SELECT p.provider_id, m.mechanic_id
FROM model.provider_mechanic_implementation i
JOIN model.provider_definition pd ON pd.provider_definition_pk = i.provider_definition_pk
JOIN model.provider p ON p.provider_pk = pd.provider_pk
JOIN model.mechanic_version mv ON mv.mechanic_version_pk = i.mechanic_version_pk
JOIN model.mechanic m ON m.mechanic_pk = mv.mechanic_pk
WHERE m.mechanic_id IN ('cli-delivery','declared-query-evaluation','scenario-orchestration',
  'runtime-projection','schema-admission','consumer-projection-publication')
ORDER BY m.mechanic_id, p.provider_id;
-- returns node, python and csharp providers for each mechanic
```

Profile binding shape (`model.provider_binding_scope` / `model.provider_binding`):
`provider_binding_scope(provider_slot_pk, binding_context_pk, binding_role, selection_policy)`
→ `provider_binding(provider_binding_scope_pk, provider_slot_pk, provider_definition_pk, selection_policy, ordinal)`.

## 10. Artifacts

| Purpose | Path |
| --- | --- |
| This strategy | `docs/strategy/python-csharp-embodiment.md` |
| Prior hold report (superseded reading) | `docs/cross-target-hold-report.md` |
| Platform-layer history | `docs/cross-target-embodiment.md` |
| Embodiment capability model | `docs/embodiment-as-capability.md` |
| Provider/mechanic inventory | `docs/research/platform-mechanic-honesty.md` |
| Lifecycle | `AGENTS.md`, `sql/README.md` |

Every migration in this path defaults to `ROLLBACK` for review and is installed by
changing the final `ROLLBACK` to `COMMIT`.
