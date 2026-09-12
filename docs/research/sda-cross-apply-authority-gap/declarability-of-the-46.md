# Which of the 46 SDA capability triples are closest to declarable today

2026-09-12 · Companion to [README.md](README.md) §4 · Classification verified; nothing implemented.

## Why this exists

The README records that SDA holds **46** capability triples (`obligation.ts` +
`provider.ts` + `model.ts`) across 10 domains, and defers self-hosting them on the
grounds that it is a multi-month migration that "does not bootstrap cleanly."

That judgement was made from the count alone. This document classifies all 46 by
what declaring them would actually require. The result changes part of the
bootstrap objection.

## Method

Each triple was scored from its own source, not from naming:

| Dimension | Test |
| --- | --- |
| Direct I/O | `provider.ts` imports `node:fs`, `node:child_process`, `node:os`, `node:net`, `node:http`, or anything under `adapters/` |
| Port dependency | `provider.ts` declares a constructor (SDA's providers take their ports there) |
| Path-shaped input | `model.ts` references `SourceFact`, `sourceRef`, `workspaceRoot`, `repositoryRoot`, `filePath`, `outDir` |
| Contract shape | `model.ts` exports `isXInput` and `isXEvidence` type guards |

"Declarable today" means: pure, path-free, and both contracts guarded — so it
needs no upstream change to how authority names its members.

## Headline result

**Not one of the 46 providers performs direct I/O.** No `fs`, no
`child_process`, no adapter imports — not even `node:path` or `node:crypto`. The
impurity of the compilation pipeline lives entirely in the orchestration around
the capabilities, never inside them.

| Group | Count |
| --- | ---: |
| Pure (no constructor port) | **41** |
| Port-delegating | 5 |
| Pure **and** path-free | **19** |
| Pure, path-free, both contract guards | **9** |

## Declarable today

Ranked by model size. These need no addressing change first.

| Capability | Domain | Model LOC | Guards |
| --- | --- | ---: | --- |
| `prove-mechanical-sterility` | consumer-assurance | 10 | in + out |
| `prove-query-closure` | consumer-assurance | 12 | in + out |
| `prove-projected-sterility-before-publication` | consumer-capability-compilation | 12 | in + out |
| `prove-projected-execution-behavior` | execution-vector-projection | 13 | out only |
| `determine-platform-mechanic-conformance` | consumer-assurance | 15 | in + out |
| `prove-experience-closure` | consumer-assurance | 16 | in + out |
| `prove-cross-target-projection-equivalence` | consumer-assurance | 17 | in + out |
| `prove-cross-apply-ui-parity` | consumer-assurance | 26 | in + out |
| `verify-realization-lifecycle-contracts` | realization-planning | 40 | in + out |

Four more are pure and path-free but large enough to warrant their own scoping:
`resolve-registered-realization-plan` (116), `project-openapi-description` (138,
3 guards), `derive-api-operation-graph` (144),
`construct-deterministic-realization-plan` (320). Note that the two
realization-planning entries import port *types* without taking them in a
constructor — they receive them as method arguments, so they are pure by this
test but not dependency-free in practice.

### The triple already maps onto a declaration

Nothing in the capability shape is left over:

| In the triple | Becomes |
| --- | --- |
| `obligationId` | experience promise |
| `conditionId` | observable condition |
| `responsibilityId` | execution authority operation |
| `isXInput` / `isXEvidence` | input contract · outcome contract |
| `provider.execute()` | transformation behind a port |
| `SATISFIED` / `NOT_OBSERVABLE` | disposition — already the estate's vocabulary |

`prove-mechanical-sterility` in full, as read from source:

```
input      consumer-projection-plan.v1
outcome    projected-artifact-mechanical-sterility.v1
condition  projected-executable-files-contain-no-hidden-mechanics
operation  inspect-projected-consumer-executable-mechanics
provider   evaluateMechanicalSterility(input.plan.files)   // one line
```

The contract identifiers already exist as discriminated-union tags on the
evidence types. They are contract ids waiting to be declared, not ids to invent.

### Recommended first cohort

The seven `consumer-assurance/prove-*` capabilities: siblings, all pure, all
path-free, all under 30 model LOC, sharing one disposition vocabulary. They prove
the mechanism on the smallest surface that is still real.

## Blocked, and by what

| Group | Count | Blocker |
| --- | ---: | --- |
| Projection-graph derivations — `derive-canonical-type-graph`, `derive-target-projection-graph`, `derive-canonical-execution-graph`, `derive-target-execution-graph`, `reproduce-target-execution-vector`, `reproduce-target-structural-model`, `determine-projected-shape-equivalence`, `determine-active-language-obligations` | 8 | inputs carry `SourceFact`; needs identity-addressed provenance |
| Kernel admission · workspace governance · remaining conformance | 14 | heavier path-shaped inputs — `determine-authority-conformance` (12 hits), `admit-language-declaration` (10), `admit-consumer-source-facts` (8) |
| Port-delegating | 5 | need mechanic / effect bindings |

The five port-delegating triples and the port each takes:

| Capability | Port |
| --- | --- |
| `observe-language-behavior` | `conformance/language-toolchain` |
| `compose-canonical-scenario-graph` | `consumer-projection/gherkin-parser` |
| `publish-projected-capability` | `consumer-projection/consumer-projection-artifact-store` |
| `resolve-platform-responsibilities` | `consumer-projection/platform-capability-repository` |
| `construct-consumer-projection-plan` | constructor takes `providers[]`, no port import |

## What this changes about the bootstrap objection

The README defers the 46 partly because "the pipeline you would use to declare
the 46 is itself part of the 46." That holds in general, but one specific claim
needs revising:

**`admit-consumer-source-facts` is already pure.** It receives
`ConsumerWorkspaceFacts` and never loads them — it collects `{sourceRef, digest}`
pairs from facts handed to it and freezes an evidence object. The file-tree
dependency is not in the capability. It is in `NodeConsumerWorkspaceRepository`,
the adapter that *builds* the facts.

So the bounded item in the README — backing `ConsumerWorkspaceRepository` with a
model-backed adapter — does not require touching this capability at all. Swap the
adapter and `admit-consumer-source-facts` is unchanged. Its only remaining
coupling is that its evidence reports `sourceRef`, which the identity-addressing
work would need to widen.

That makes programs (1) and (2) less entangled than recorded: the seam can land
without self-hosting anything, and the first `prove-*` declarations can follow
independently of the 8 derivations blocked on `SourceFact`.

## Status

- Classification: **verified against source** for all 46.
- First cohort: **identified, not declared**.
- Bootstrap objection: **narrowed**, not dissolved — the 22 path-shaped and
  port-delegating triples still depend on the addressing work.
