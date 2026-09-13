# Cross-target hold report

Attempted `resolve-equity-market-price-evidence` embodiment per declared target
after making the materializer's target selection data-driven. The database target
is now read; the first unmet requirement per target is recorded below in order.

## Changes that landed

- `planNode` selects the registry by `selection.target` (was hardcoded `'node'`).
- The native transformation provider is the registry's **`graphProviderProfiles`
  pure profile**, which every language registry declares (`node`, `python`,
  `csharp`). Node's pure profile is byte-identical to the `eventPorts`
  transformation provider the path read before.
- `resolvedTransformationPorts` is derived from the interface's declared
  transformation ports, not from the node registry's `eventPorts`.
- The embodiment request contract declares `target: ["node","python","csharp"]`.

Node is unchanged: `planDigest sha256:d21dbcbb…`, `artifactDigest sha256:b785cb9a…`.

## Ordered holds per target

| # | Requirement | node | python | csharp |
| --- | --- | --- | --- | --- |
| 1 | registry for target | ok | python registry present | csharp registry present |
| 2 | native transformation provider | ok (pure profile) | ok (pure profile) | ok (pure profile) |
| 3 | **consumer application provider (renderer)** | `NodeConsumerObjectProvider` | **HOLD `SELECTED_NATIVE_MECHANIC_BODY_NOT_RECOGNIZED`** | same |
| 4 | effect ports | 31 `eventPorts`, `invocation: effects` | registries declare `eventPorts: []` | same |
| 5 | contract admission | `contractAdmissions` direct | registries declare `[]` | same |
| 6 | runtime loader | `loadMemoryScenario` | no python loader in the estate | no csharp loader |

The Python/C# registries declare `graphProviderProfiles` (a pure evaluator and an
effect scheduler), `runtimeSupportImports` and empty `eventPorts`. Node declares
both the shared profiles **and** 31 per-port `eventPorts` carrying
`platformCapabilityId` + provider module. The estate's planner and renderer were
built on the per-port shape.

## What the first hold means

`SELECTED_NATIVE_MECHANIC_BODY_NOT_RECOGNIZED` is the estate's Node renderer
(`consumer-object-provider.mjs`) parsing the target's provider source
(`semantic_transformation_evaluator.py` / `.cs`) as JS/TS. The estate renders with
its own Node provider; the platform carries
`tools/.../providers/{python,csharp}/consumer-application-provider.ts`.

## The renderer is not a swap — the targets embody a plan, not per-port bodies

Binding the platform's Python provider and rendering gives the reason:

```
python provider target: python   files: 1
  python/consumer.generated.py
    # GENERATED PURE PROJECTION SEAM. Do not hand-edit.
    from scenario_kernel.platform.consumer import main
    raise SystemExit(main(__file__))
```

`PythonConsumerApplicationProvider.render` returns that one seam. Its runtime,
`scenario_kernel/platform/consumer.py`, loads a
**projected consumer application binding** — `projected-consumer-application-binding.v3`
referencing an `executionPlan`, `fixtures` and `mechanicalSterility` — and runs it
through the graph scheduler. C# is the same shape:
`AdmittedConsumerPlatform.RunAsync(bindingRelativePath)` — *"generic
authority-driven consumer host for projected C# seams."*

So there are two embodiment contracts, not one:

| | Node (estate path) | Python / C# (platform path) |
| --- | --- | --- |
| Artifact | per-port body modules under `embodiments/…/node/body/**` + carried kernel/providers | a seam that loads a projected **binding + execution plan** |
| Renderer | `NodeConsumerObjectProvider` (renders every port and scenario) | `renderXProgram()` (one seam line) |
| Execution | `loadMemoryScenario` (node vm) | `platform.consumer` / `AdmittedConsumerPlatform` (target kernel graph scheduler) |
| Carries | code | data (binding + plan) |

Binding the Python provider into the estate's per-port planner therefore produces
the seam and no plan; the seam would have nothing to load.

## Corrected Layer 4

The cross-target path is the **plan**, not the per-port body. The estate already
declares `project-consumer-execution-embodiment-v2`, whose authority composes
`admit → derive → render → observe`, and whose outcome is the projected
`consumer-execution-embodiment-plan.v2` (carrier: `previous-admitted-outcome`,
`failureMode: stop-at-first-non-success`, cross-capability `invoke-scenario`). The
platform projects per-target bindings and plans (e.g.
`capabilities/…/projected/execution-plans/consumer-execution-plan.node.json`).

So the corrected step is: for a target, the estate's embodiment capability should
produce the projected consumer application binding + execution plan (reusing
`project-consumer-execution-embodiment-v2`), and the target's
`AdmittedConsumerPlatform` executes it. The Node per-port path and the plan path
must converge; the plan path is the one that is already cross-language.

## Next, in order

1. **Per-target consumer application provider** (render): bind the platform's
   compiled python/csharp consumer application provider as an estate provider,
   the same way the write step binds an estate provider.
2. **Per-target effect and contract bindings**: the python/csharp registries
   declare no `eventPorts` and no `contractAdmissions`. Readiness currently comes
   from the database's `provider_capability_implementation` rows; the estate's
   planner resolves effects from the registry. The two must be reconciled —
   either the registries gain the eventPort/contract declarations, or the
   planner resolves them from the database bindings.
3. **Per-target runtime loader**: the estate executes node bodies through
   `loadMemoryScenario`; python and csharp need their own loaders (or a declared
   execution boundary) to run what is rendered.
