# Embodiment as a database capability

The materialization process is declared as a capability, not driven by a script.
Its meaning is rows; its provider is the estate's Node materializer.

## `construct-embodiment-plan`

- **Input** `construct-embodiment-plan-request.v1`: `{ capabilityId, scenarioId?, target }`.
- **Outcome** `capability-embodiment-plan.v1`: the content-addressed plan —
  `planDigest`, `artifactDigest`, `scenarioDefinitionDigest`, `platformDigest`,
  `resolverVersion`, `fileCount`, and `files[{ relativePath, digest, sourcePointers }]`.

Its root Scenario's Port is an estate provider:

```
platformCapabilityId        sda-embodiment-plan-port.v1
configuration.estateProvider { module: src/resolvers/node/embodiment-plan-provider.mjs,
                               export: planCapabilityEmbodiment }
```

The delivery resolves the provider from the Port binding — declaration data —
rather than dispatching on a capability identity. The provider reads the selected
capability's retained authority and plans its native body through the same
materializer the direct invocation path uses. It **writes nothing**: materialization
is a separate governed effect.

## Determinism

`planDigest = hash(pretty(plan))` over the per-Scenario body plan, and
`artifactDigest = hash(pretty(fileMetadata))`. Both derive from the pinned model,
the pinned platform commit and the provider bytes (`platformDigest`,
`resolverVersion` already bind the 34-file platform surface). Re-running returns
the same digests; a written artifact is judged by recomputing these digests from
disk.

## Proof

```
sfx capability invoke construct-embodiment-plan \
  --input '{"capabilityId":"resolve-equity-market-price-evidence","target":"node"}' --json
```

returns the plan. Regenerating the embodiment and recomputing the digests from
disk reproduces the capability's `planDigest` and `artifactDigest`, and every
file digest matches. The stale four-Scenario artifact was replaced by the current
one-Scenario generation (`embodiments/resolve-equity-market-price-evidence/`).

## What remains

The write is a separate governed effect. The plan capability says what should be
written; the crossing (staging, ordering, target-root authorization) belongs to
`materialize-authorized-file-batch`, or to a `materialize-capability-embodiment`
capability composed with it. The regeneration above used the materializer's own
writer; making that write a declared effect is the next piece. The reader is also
still a query rather than a declared capability; composing a declared *read*
capability before the plan provider is the honest long form of the same step.
