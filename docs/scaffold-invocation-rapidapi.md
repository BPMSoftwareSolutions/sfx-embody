# Invoking the scaffold capability from the database: projection resolved, execution held by the admitted transformation

Assessment: 2026-09-09. Subject: invoking `generate-executable-capability-scaffold`
through the direct database path in [database-direct-invocation.md](database-direct-invocation.md)
to scaffold a RapidAPI provider capability.

The contract-openness blocker recorded in the previous assessment is resolved.
`sfx capability invoke` no longer requires preparation, and the node type
projection now admits deliberately open contract positions instead of throwing.
The scaffold now resolves, plans all sixteen scenario bodies in memory, loads
224 modules, and reaches kernel execution. The remaining hold is in the
capability's own admitted semantic transformation, which fails for
blueprint-absent requests identically under the canonical SDA evaluator.

## The command

The capability being scaffolded is `resolve-equity-market-price-evidence`, the finance
resolver from the RapidAPI provider-swap status record. That capability is a provisioned
scaffold whose invocation terminates at `PROVIDER_REQUIRED`; it is exactly the case the
scaffold capability exists to serve.

```powershell
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
so the request is `DESIGN_RESOLVER_CANDIDATE` rather than blueprint-conditioned.

Three of the four declared capability slots — `bind-external-credential-reference`,
`project-governed-http-request-body`, `observe-governed-http-exchange` — are present in
the supplied inventory and would resolve `FOUND`. `select-equity-market-price-provider`
is not in the estate and would resolve `NOT_FOUND`, becoming the next bounded authoring
obligation. That asymmetry is the useful part of the answer and is the reason the
inventory is supplied in full rather than summarized.

## What the direct invocation now reaches

The authority read succeeds completely. Selecting only `capabilityId` resolves the root
scenario without an identity heuristic:

```text
capability                generate-executable-capability-scaffold   (sidefx:capabilities)
root scenario             generate-executable-capability-scaffold
input / event / outcome   executable-scaffold-request / … / executable-capability-scaffold
                          both RESOLVED
```

The node planner now projects the scaffold's deliberately open contract positions instead
of throwing on them. Three projection rules cover the estate-wide scan from the previous
assessment:

| Declared shape | Projection |
| --- | --- |
| `type: array` without `items` | `unknown[]` — items admit any value, exactly as the schema admits |
| `type: object` without `properties` (nested) | `Record<string, unknown>` — admits any object, rejects null, scalars and arrays, exactly as JSON Schema `type: object` |
| `type: object` without `properties` (contract root) | an interface without declared fields; a root must stay an object type for the target graph |

The derived type-projection view records every such change in the
`contract-projection.json` evidence with `runtimeAdmission: ORIGINAL_SCHEMA_UNCHANGED`;
the original schema bytes remain the runtime admission authority. All 16 scenario
bodies plan, and 224 modules load from memory.

Execution then fails with `CAPABILITY_EXECUTION_FAILED` (exit 4) during
`execute-event-authority`, before outcome admission. The root port throws
`TypeError: Cannot read properties of null (reading 'filter')` at its first
blueprint-derived slot resolution.

## The remaining hold: the admitted transformation assumes a forbidden absence value

The failure is not in the embodiment. The scaffold's `semantic-transformation.authority.json`
detects a missing `canonicalBlueprint` with:

```text
equals(format("{t}", { t: json-stringify(path(input, "payload.canonicalBlueprint.nodes")) }), "undefined")
```

The declared transformation semantics make this comparison impossible to satisfy:
a missing path evaluates to `null` (absence is one value, and a target-specific
second empty value such as JavaScript `undefined` is declared non-portable), and
`json-stringify(null)` is the string `"null"`. The comparison therefore always
fails, the `[]` branch is dead code, and the blueprint-derived slots are computed
from `null`, which the subsequent `filter` refuses.

The same expression fails identically under the canonical
`semantic-transformation-evaluator.mjs` from the pinned SDA checkout with the same
input, so the native lowering is faithful and there is nothing an embodiment
provider may legally change. The defect belongs to the admitted transformation
authority: its absence detection should compare against `"null"` (or use a
declared try/parse form) rather than `"undefined"`. Correcting it is a database
change-surface operation — a corrected capsule generation with honest lineage —
not an embodiment edit. The transformation's blueprint-present branch is not
exercised by this assessment.

## How far this reaches

The previous blocker is gone: no contract shape on the invocation path throws
during planning, so any capability whose contracts were previously rejected for
open arrays now plans. The regeneration of the three regression capabilities
passed the full estate verification (17/17 fixtures, 320 kernel observations,
five negative checks across ten scenario bodies) and memory parity; the changed
contract projections are confined to `Record<string, unknown>` replacements for
previously silent empty interfaces in `admit-canonical-circuit-blueprint`.

The scaffold itself remains uninvokable end-to-end only because its own
transformation defects on the blueprint-absent request. A request carrying an
admitted canonical blueprint would exercise the blueprint-present branch, which
this assessment does not run.

## Boundaries

The scaffold capability was never executed to a terminal outcome. No scaffold,
blueprint carrier, or authoring artifact was produced for
`resolve-equity-market-price-evidence`, and none of its four open event-mechanic
slots were resolved. The RapidAPI provider was not called; no credential was
resolved and no HTTP exchange was attempted. No database write was made: direct
invocation performs three restricted reads and executes in memory. The estate-wide
contract scan from the previous assessment is a read over one snapshot and reports
document and capsule counts, not capability counts. The slot dispositions described
above are what the scaffold's declared contract requires of a conforming run; they
are expectations from reading the authority, not observed output.
