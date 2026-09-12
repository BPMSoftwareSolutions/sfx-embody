# SDA cross-apply vs. path-addressed authority: where the capsule actually comes from

2026-09-12 · Research finding · Diagnosis verified; bounded remediation scoped, not yet implemented.

## Thesis

`sfx-embody`'s `materialize-node.mjs` is a Node-only reimplementation of a
cross-apply projection pipeline that Scenario Driven Architecture (SDA) already
provides. The deeper cause is not the materializer: SDA's *authority format* is
**path-addressed** — capability members are referenced by relative file path and
the compiler is rooted at a `workspaceRoot` directory. That single choice forces
the whole chain we have been untangling:

```
authority references members by relative path
  -> consumer projection requires a workspace file tree
  -> the database must ship a path-addressed capsule to satisfy it
  -> the mutation layer fabricates capsule appearances
  -> SQL declaration is expensive
  -> reveal (correctly reading the model) sees nothing
```

The capsule is not the cause. It exists to satisfy SDA's path addressing.

## Verified evidence

Each load-bearing claim was re-checked against the two working trees.

### 1. `materialize-node.mjs` bypasses SDA's cross-apply machinery

SDA ships the seam:

- `scenario-driven-architecture/tools/src/projection/providers/structural-provider-registry.ts`
  — a provider per target (`csharp`, `go`, `java`, `node`, `python`) plus a
  `process-json-v1` transport for out-of-process resolvers.
- `ConsumerCapabilityCompiler.compile(root, { projectionTargets })` →
  `Record<Target, …>` and `ConsumerProjectionPlanBuilder` (multi-target).

`sfx-embody/src/materialize-node.mjs`:

- imports `NodeStructuralProjectionProvider` directly from `dist`
  (`:172`), skipping the registry and its admission check;
- uses it at `:189`;
- emits `composition.mjs` as a hardcoded JS template literal (`:228`);
- never references `ConsumerCapabilityCompiler`, `ConsumerProjectionPlanBuilder`,
  or `structuralProjectionProvider`.

So `projectionTargets: ["node"]` is decorative: the pipeline downstream of it is
hardwired to Node.

### 2. SDA's authority format is path-addressed

`scenario-driven-architecture/artifacts/tools/dist/consumer-projection/model/consumer-workspace-facts.d.ts`:

```ts
export interface ConsumerCapabilityDeclaration {
  readonly feature: string;              // relative path
  readonly capability: string;           // relative path
  readonly semanticGraph: string;        // relative path
  readonly executionAuthorities: string; // relative path
  readonly interfaces: string;           // relative path
  readonly fixtures: string;             // relative path
}
```

`SourceFact.sourceRef` is a relative path, and `ConsumerCapabilityCompiler.compile`
takes `workspaceRoot: string`. `materialize-node.mjs:40` faithfully implements
exactly this: `path.posix.normalize(path.posix.join(path.posix.dirname(from.source_path), reference))`.
The file tree is not `sfx-embody`'s invention; it is SDA's authority expression.

### 3. The hexagonal seam exists but is vestigial

`scenario-driven-architecture/tools/src/ports/consumer-projection/consumer-workspace-repository.ts`:

```ts
export interface ConsumerWorkspaceRepository { load(workspaceRoot: string): ConsumerWorkspaceFacts; }
```

It is referenced only by its own definition, its Node adapter, and the compiler's
hard instantiation:

```
consumer-capability-compiler.ts:107
  const repository = new NodeConsumerWorkspaceRepository(this.repositoryRoot, schemaAdmission, new SystemClock());
```

Nothing injects through the port, and `load(workspaceRoot: string)` leaks the file
tree into the port signature itself. A database-backed adapter belongs here.

### 4. SDA has already modeled its own pipeline as capabilities

`find tools/src/capabilities -name obligation.ts | wc -l` = **46** across 10
domains (`admit-consumer-source-facts`, `compose-canonical-scenario-graph`,
`construct-consumer-projection-plan`, `prove-projected-sterility-before-publication`,
`publish-projected-capability`, and 41 more). These are the SDA capability shape
(obligation + provider + model) compiled as TypeScript inside the platform
instead of declared capabilities in the database. Self-hosting is structural but
not actual.

All 46 are classified by declarability in
[declarability-of-the-46.md](declarability-of-the-46.md): none performs direct
I/O, 41 are pure, 19 are pure and path-free, and 9 are declarable with no
upstream addressing change. That document also narrows the bootstrap objection
recorded below — `admit-consumer-source-facts` is already pure, so the bounded
seam does not require touching it.

## Two different programs

The diagnosis is correct; the cure must be split, because they are not the same
amount of work.

1. **Make SQL declaration cheap now** — back the existing
   `ConsumerWorkspaceRepository` port with a model-backed adapter and stop
   `materialize-node` consuming the path-addressed source. Bounded; delivers the
   flywheel value.
2. **Make SDA self-host** — declare the 46 as managed capabilities so
   `admit-consumer-source-facts` reads the model. A multi-month platform
   migration, and it does not bootstrap cleanly: the pipeline you would use to
   declare the 46 is itself part of the 46.

Recommendation: do (1) first. It is a precondition for judging whether the 46 are
ever worth declaring.

## The bounded item is a seam plus declaration increments

Inspecting the live model shows the seam alone is not sufficient, because
`planNode` needs documents the model does not yet declare. Current model object
kinds (estate-wide) are `AUTHORITY, BLUEPRINT, CAPABILITY, CONTRACT,
EXECUTION_AUTHORITY, FEATURE, FIXTURE, MECHANIC, OBSERVABLE_CONDITION, PORT,
PROVIDER, PROVIDER_PROFILE, SCENARIO, SCENARIO_EVENT, SCENARIO_INPUT,
SCENARIO_OUTCOME, TRANSFORMATION`. There is **no** `WORKSPACE` kind, **no**
`SEMANTIC_GRAPH` kind, and **no** interface-binding kind. `hello-world-sql` has
`FIXTURE = 0`; its fixtures live only in the capsule's `fixtures.authority.json`.

What `planNode` reads, and where it can come from:

| Document the planner reads (`materialize-node.mjs`) | Model today |
| --- | --- |
| `capability.authority.json` | yes — `CAPABILITY` envelope `semantics.authority` |
| `execution-authorities.authority.json` | yes — `EXECUTION_AUTHORITY` envelope |
| `semantic-transformation.authority.json` | yes — `TRANSFORMATION` envelope |
| feature `.feature` text | derivable — `FEATURE` binding resolves the bytes via `content_digest` |
| contract catalog + schemas | derivable — `CONTRACT` `schema_digest` resolves `source.content_object` |
| `interfaces.authority.json` | **partial** — `PORT` covers port bindings; the interface list (`sda-json-cli.v1`, `contractValidatorCapabilityId`) has no kind |
| `fixtures.authority.json` | **missing** — `FIXTURE` kind exists but 0 for this capability |
| `semantic-graph.authority.json` | **missing** — no model kind |
| `consumer-workspace.authority.json` | **missing** — no model kind |
| pinned platform package + node registry | source-layer by design (`recordsets[2]`); leave as is |

So "wire the port" is: (a) introduce the repository seam and resolve capability
members by declared identity instead of relative path, and (b) add the four
missing declarations/kinds (`WORKSPACE`, `SEMANTIC_GRAPH`, interface bindings,
per-capability `FIXTURE`). Only then can `invoke` run from model declarations
alone and the capsule become an optional promotion.

## Known traps

- Do not have the database synthesize pseudo-paths (`capabilities/<id>/interfaces.authority.json`)
  for model rows so the materializer keeps working unchanged. That makes invoke
  pass while re-importing file vocabulary into the mutation layer.
- Do not make the capsule resolution "optional" in
  `sidefx-database/sql/diagnostics/capability-embodiment.sql` alone. With an empty
  per-capability recordset, `planNode` fails one line later at
  `WORKSPACE_AUTHORITY`. Making it a fallback instead creates two authority
  sources for one capability with no arbitration rule.

## Open items

- **Closed — same-namespace duplication.** `hello-world-request.v1` /
  `hello-world-greeting.v1`, and every other declared id, are now presented once.
  See "Closure" below.
- Confirm whether work itself already expects `WORKSPACE`/`SEMANTIC_GRAPH` kinds
  in `sidefx-database` before minting new ones.

## Closure — one definition per declared id

The read boundary now presents one definition per declared id:
`analysis.v_selected_semantic_definition` selects the highest
`semantic_object_definition_pk` for each semantic object in the selected model
(`docs/sql/select-one-definition-per-declared-id.sql`). Superseded definitions are
**not removed**; they remain in the model and simply stop being the definition read.

Before the change the view returned every definition, so consumers read the union of
superseded and current declarations. That one cause produced the same-namespace
`CONTRACT` duplication and the equity `EXECUTION_AUTHORITY` / `PORT` /
`TRANSFORMATION` multiplicities. After the change, 0 selected ids carry more than one
definition; 38 ids still carry multiple definitions in the model. This closes the
same-namespace open item at the read boundary, not by deleting rows.

## Status

- Diagnosis: **recorded and verified**.
- Bounded remediation: **scoped above, not implemented** (the model-backed port;
  the selection rule is a separate, delivered change).
- Self-hosting the 46: **not started**; deliberately deferred.
- Remaining live gap: the runtime still resolves exactly one retained-source row
  per capability, so capsule source remains mandatory at declaration time.
