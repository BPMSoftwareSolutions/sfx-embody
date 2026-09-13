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

## The write (governed effect)

`materialize-capability-embodiment` composes the whole loop:

```
identity --construct-embodiment-plan (read -> plan)--> embodiment plan
         --write-capability-embodiment--> materialization record
```

- **`write-capability-embodiment`** — input `capability-embodiment-plan.v1`; outcome
  `capability-embodiment-materialization.v1` (`outputRoot`, `planDigest`,
  `artifactDigest`, `fileCount`, `written[]`). The plan authorizes the crossing;
  the writer re-plans from the same authority, writes beneath the authorized
  root, and refuses (`EMBODIMENT_WRITE_DIVERGED`, `EMBODIMENT_WRITE_DIGEST_MISMATCH`)
  if the written artifact does not reproduce the plan.

The write is delivered by a **distinct governed delivery**, `embodiment-materialization`
(`sfx.config.json`): the same transport as `database-memory`, but authorized to
write `./embodiments` and not subject to the memory-only storage proof control —
which exists to prove that *invocation* reads no retained cache and writes
nothing. `src/embodiment-delivery.mjs` is the write-boundary entry.

```
sfx capability materialize materialize-capability-embodiment \
  --input '{"capabilityId":"resolve-equity-market-price-evidence","target":"node"}' --json
```

returns the materialization record and writes the body beneath the embodiment
root.

## Proof

- The read-only `database-memory` delivery still proves memory-only invocation:
  `construct-embodiment-plan` returns `planDigest sha256:d21dbcbb…` with no write.
- The write delivery returns `artifactDigest sha256:b785cb9a…`, `fileCount 30`,
  `written` 30 entries; the on-disk artifact matches every file digest.
- The stale four-Scenario artifact is replaced by the current one-Scenario
  generation (`embodiments/resolve-equity-market-price-evidence/`).

## What remains

The `materialize` subject is the composer capability (`materialize-capability-embodiment`),
with the target capability carried in the input. A friendlier surface would let the
target be the subject, with the composer named by the delivery — a small CLI/transport
change rather than a capability change. The read delivery and the write delivery are
now separate, declared effect boundaries; completing the estate's declared
`materialize-authorized-file-batch` as the concrete writer (rather than the
materializer's own writer) is the longer form still
