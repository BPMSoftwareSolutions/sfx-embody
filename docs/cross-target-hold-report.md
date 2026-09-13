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
