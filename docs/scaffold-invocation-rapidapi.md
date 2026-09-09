# Invoking the scaffold capability from the database: what it looks like, and why it holds

Assessment: 2026-09-09. Subject: invoking `generate-executable-capability-scaffold`
through the database path in [database-direct-invocation.md](database-direct-invocation.md)
to scaffold a RapidAPI provider capability.

Disposition: **HELD — CONTRACT_TYPE_OPENNESS_UNPROJECTABLE**. The capability, its
root scenario and its complete capsule authority are present and selectable in SQL.
The node planner rejects it before any body is produced. Nothing about the request
was wrong, and nothing was retained by the failed attempt.

## The command

The capability being scaffolded is `resolve-equity-market-price-evidence`, the finance
resolver from the RapidAPI provider-swap status record. That capability is a provisioned
scaffold whose invocation terminates at `PROVIDER_REQUIRED`; it is exactly the case the
scaffold capability exists to serve.

```powershell
sfx capability prepare generate-executable-capability-scaffold --timeout 600000 --json
sfx capability invoke generate-executable-capability-scaffold --input '@examples/rapidapi-scaffold.request.json' --json
```

[The request](../examples/rapidapi-scaffold.request.json) is a real
`executable-scaffold-request.v1`. It validates against the `contracts/input.schema.json`
retained in the selected capsule, using the same Ajv 8.20.0 the runtime admits with.
Its contents are read from declared authority rather than composed for the example:

| Field | Source |
| --- | --- |
| `capabilityId`, `declaredScenarios`, `terminalNodes` | The four declared scenarios of `features/resolve-equity-market-price-evidence.feature` |
| `featureDigest` | `sha256:2cef921f…` over those exact 3,680 feature bytes |
| `declaredProviderSlots` | The two bindings in `rapidapi-finance.provider-connections.candidate.json` |
| `estateInventory.capabilities` | All 219 managed capabilities selected from the same database snapshot |
| `mechanicCatalog.mechanics` | All 191 `MECHANIC` definitions returned by the same authority read |
| `declaredTopology` | Authored design testimony, marked `DESIGN_RESOLVER_CANDIDATE` |

The topology is the one part that is authored rather than read. The scaffold refuses to
invent geometry — a request carrying no declared topology returns
`BLUEPRINT_TOPOLOGY_NOT_DECLARED` — so a candidate topology has to be supplied by a human
or by the design resolver. No admitted canonical blueprint exists for this capability yet,
so the request is `DESIGN_RESOLVER_CANDIDATE` rather than blueprint-conditioned, and the
scaffold would report completeness level `TOPOLOGY_RESOLVED` rather than
`COMPOSITION_RESOLVED`.

Three of the four declared capability slots — `bind-external-credential-reference`,
`project-governed-http-request-body`, `observe-governed-http-exchange` — are present in
the supplied inventory and would resolve `FOUND`. `select-equity-market-price-provider`
is not in the estate and would resolve `NOT_FOUND`, becoming the next bounded authoring
obligation. That asymmetry is the useful part of the answer and is the reason the
inventory is supplied in full rather than summarized.

## What the database already supports

The authority read succeeds completely. Selecting only `capabilityId` resolves the root
scenario without an identity heuristic:

```text
capability                generate-executable-capability-scaffold   (sidefx:capabilities)
root scenario             generate-executable-capability-scaffold
input / event / outcome   executable-scaffold-request / … / executable-capability-scaffold
                          both RESOLVED
capsule digest            sha256:1964af7aa6efd80dc21e9699e1a84eafb368899da0838e2f695cfad38b6b81aa
retained entries          24 capsule sources + 7 pinned platform declarations
node readiness            CAN_ATTEMPT_EMBODIMENT, 0 of 1074 requirements open
```

`csharp` and `python` report the same readiness; `cpp`, `go` and `java` report
`NOT_OBSERVABLE` with 948 open requirements. All SQL responses report `MEMORY_ONLY`. So
the readiness view says this capability is embodiable, and the selection, retention and
coherence guarantees all hold for it.

## Where it stops

Planning throws, and the CLI surfaces the throw verbatim:

```json
{"error":{"code":"DATABASE_INVOCATION_FAILED","details":{"operation":"prepare",
 "result":{"error":{"message":"Array schema at 'https://schemas.agentic-harness.local/contracts/carrier.schema.json#/properties/findings' has no admitted item schema."}}}}}
```

Exit code 4. `sfx capability invoke` then returns `CAPABILITY_PREPARATION_REQUIRED`,
confirming the failed prepare retained no preparation.

The cause is in the contract, not in the planner's handling of it. The scaffold's
`carrier.schema.json` declares its accumulating fields as bare arrays:

```json
"findings":       { "type": "array" },
"mechanicSlots":  { "type": "array" },
"executionShell": { "type": "object" }
```

`JsonSchemaTypeGraphBuilder.buildNode` requires an admitted `items` schema for every array
and throws when there is none. Sixteen such open positions exist across the scaffold's
three contracts: seven open arrays and one open object in the carrier, two open arrays and
five open objects in the input, one open object in the outcome.

This openness is deliberate rather than sloppy. `generate-executable-capability-scaffold`
is generic over every capability in the estate — it emits slots, findings and authored
artifacts whose shapes belong to the capability being scaffolded, not to the scaffold.
Ajv admits these documents at runtime exactly as intended. The conflict is that the node
embodiment path does not merely admit contracts, it projects them into TypeScript types,
and an unconstrained array has no type to project.

The three capabilities that work through this path today —
`resolve-sidefx-eligible-providers`, `admit-canonical-circuit-blueprint`,
`adapt-job-market-intelligence-evidence` — all carry fully closed contracts. The path has
therefore only ever been exercised against closed-contract capabilities.

## How far this reaches

Scanning all 1,114 `contracts/*.schema.json` documents retained for `MANAGED_CAPSULE`
sources in the selected snapshot separates two distinct conditions:

| Condition | Builder behavior | Documents | Capsules |
| --- | --- | ---: | ---: |
| `type: array` with no `items` | throws `has no admitted item schema` | 49 | 30 |
| `type: object` with no `properties` | projects an object type with zero properties | 184 | 102 |

The first row is the blocker the scaffold hit. The second is worse in kind and quieter:
`buildObject` reads a missing `properties` as an empty property map and emits a type
carrying none of the document's fields, with no finding and no hold. Any capability whose
contract declares an open object is already projectable in a way that silently discards
contract meaning, and 102 capsules carry at least one.

Two caveats on these counts. The builder only walks contracts reachable from the catalog
of the scenarios being projected, so 30 capsules is an upper bound on capabilities blocked
by their own contracts rather than a confirmed count. And a capsule digest is not a
capability identity; a capability with several retained revisions contributes more than
once.

## What this owes

The scaffold is not blocked on database candidate authoring, capsulization, or broader
provider profiles — the work [database-direct-invocation.md](database-direct-invocation.md)
already names as outstanding. It is blocked on a narrower and more specific question: what
a node embodiment should do with a contract that is deliberately open.

Three candidate resolutions, none of which this assessment admits:

1. **Project openness explicitly.** Give the type graph an admitted unknown/JSON node so an
   unconstrained array becomes `unknown[]` rather than a throw. `buildNode` already returns
   `{ kind: "primitive", primitive: "unknown" }` for a typeless schema, so the vocabulary
   exists; it is simply not reachable from `type: array`. This also repairs the silent
   open-object case, which should become an explicit unknown rather than an empty object.
2. **Close the scaffold's contracts.** Constrain `findings`, `mechanicSlots` and the rest to
   item schemas. This changes admitted contract authority for a published capability, and
   the openness is load-bearing for a capability generic over the estate, so it trades a
   planner limit for a design loss.
3. **Hold explicitly.** Have the planner report `CONTRACT_TYPE_OPENNESS_UNPROJECTABLE`
   naming every open position, rather than throwing the first one it meets. This resolves
   nothing on its own but converts a stack trace into a finding, and would have surfaced
   all 16 positions in one read instead of one per attempt.

Option 1 carrying option 3's reporting is the smaller and more honest change: it keeps
admitted contract authority untouched, makes the existing unknown vocabulary reachable,
and turns both the loud and the silent openness cases into declared dispositions. It would
need its own parity evidence before any claim that a scaffolded capability projects
correctly, because an unknown-typed projection is exactly the shape that
`npm run verify:memory` cannot distinguish from a correct one.

## Boundaries

The scaffold capability was never executed. No scaffold, blueprint carrier, or authoring
artifact was produced for `resolve-equity-market-price-evidence`, and none of its four
open event-mechanic slots were resolved. The RapidAPI provider was not called; no
credential was resolved and no HTTP exchange was attempted. No database write was made:
the single `prepare` attempt failed during proving and retained nothing, which the
subsequent `CAPABILITY_PREPARATION_REQUIRED` confirms. The estate-wide contract scan is a
read over one snapshot and reports document and capsule counts, not capability counts.
The slot dispositions described above are what the scaffold's declared contract requires
of a conforming run; they are expectations from reading the authority, not observed output.
