# Embodiment as a database capability

The materialization process is declared as capabilities, not driven by a script.
Its meaning is rows; its providers are the estate's Node modules. The plan is
produced by a declared composition: a **read** capability before a **plan**
capability.

## The composed capability

`construct-embodiment-plan` composes two declared capabilities in its execution
authority:

```
input (capability identity) --invoke-scenario--> read-capability-authority
                            --invoke-scenario--> plan-capability-embodiment
                            --> content-addressed embodiment plan
```

- **`read-capability-authority`** — input `construct-embodiment-plan-request.v1`
  `{ capabilityId, scenarioId?, target }`; outcome
  `capability-authority-declaration.v1` — the retained authority, the declared
  invocation closure and the mechanic declarations, bound to the snapshot and
  projection.
- **`plan-capability-embodiment`** — input `capability-authority-declaration.v1`;
  outcome `capability-embodiment-plan.v1` — `planDigest`, `artifactDigest`,
  `scenarioDefinitionDigest`, `platformDigest`, `resolverVersion`, `fileCount`,
  `files[{ relativePath, digest, sourcePointers }]`.

Each is an estate-provider capability. Its Port binding names the provider module
and export:

```
platformCapabilityId        sda-embodiment-plan-port.v1
configuration.estateProvider { module: src/resolvers/node/<provider>.mjs, export: <export> }
```

The delivery resolves the provider from the Port binding — declaration data —
rather than dispatching on capability identity. Neither capability writes;
materialization is a separate governed effect.

## The delivery

A capability is executed by the estate runtime when its declared execution
authority composes estate-provider Ports, directly or through composed Scenarios.
`executeEstateCapability` threads the running state through the declared
operations in order: an `invoke-port` whose binding declares an estate provider
transforms the state, and an `invoke-scenario` runs the target capability's own
declared operations with that state. State flows exactly as the authority orders
it; a cycle is refused.

## Determinism

`planDigest = hash(pretty(plan))` over the per-Scenario body plan, and
`artifactDigest = hash(pretty(fileMetadata))`. Both derive from the pinned model,
the pinned platform commit and the provider bytes (`platformDigest`,
`resolverVersion` burden the 34-file platform surface). The composed plan is
identical to the plan the single-provider form produced, so the composition is
behaviour-preserving.

## Proof

```
sfx capability invoke construct-embodiment-plan \
  --input '{"capabilityId":"resolve-equity-market-price-evidence","target":"node"}' --json
```

composes read → plan and returns `planDigest sha256:d21dbcbb…` and
`artifactDigest sha256:b785cb9a…`. Regenerating the embodiment and recomputing
the digests from disk reproduces those values, and every file digest matches. The
stale four-Scenario artifact is replaced by the current one-Scenario generation
(`embodiments/resolve-equity-market-price-evidence/`).

## What remains

The write is a separate governed effect: the plan capability says what should be
written, and the crossing (staging, ordering, target-root authorization) belongs
to `materialize-authorized-file-batch`, or to a `materialize-capability-embodiment`
capability composed with it. The regeneration used the materializer's own writer;
making that write a declared effect is the next piece.
