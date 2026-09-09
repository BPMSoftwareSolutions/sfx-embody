# Invoking the scaffold capability from the database

Assessment: 2026-09-09. Subject: invoking `generate-executable-capability-scaffold`
through the direct database path in [database-direct-invocation.md](database-direct-invocation.md)
to scaffold a RapidAPI provider capability.

The contract-openness blocker recorded in the previous assessment is resolved,
and the capability now runs end-to-end through the direct invocation. The
blueprint-conditioned path completes with exit 0. The remaining data defect is
exactly located: 35 literal rows across 5 transformations that compare
`json-stringify(...)` against `"undefined"`, a value that comparison can never
produce. The blueprint-absent path still fails on the first of those rows; the
blueprint-conditioned path survives all but one, which it works around with a
fully-populated request.

## The successful run

```powershell
sfx capability invoke generate-executable-capability-scaffold --input '@examples/rapidapi-scaffold-blueprint.request.json' --json
```

Exit 0. The kernel completed; the scaffold's own disposition is `HELD`:

```text
disposition: rejected | scaffold: HELD | completenessLevel: COMPOSITION_RESOLVED
conditioning: BLUEPRINT_CONDITIONED / CANDIDATE_CONDITIONED, contradictions: []
embodiment:   4/4 cells, 4/4 terminals, 7/7 edges, unembodied: []

executionShell (GENERATED):
  admit-input → validate-input-contract → resolve-event-authority
  → resolve-required-mechanics → resolve-capability-dependencies → resolve-providers
  → execute → collect-testimony → admit-outcome → evaluate-disposition

capabilitySlots:
  bind-external-credential-reference    FOUND
  project-governed-http-request-body    FOUND
  observe-governed-http-exchange        FOUND
  select-equity-market-price-provider   NOT_FOUND

findings: CONTRACT_ID_NOT_JSON_SAFE
authoringWorkQueue (6):
  AUTHOR_CAPABILITY               select-equity-market-price-provider
  RESOLVE_MECHANIC                resolve-equity-market-price-evidence.v1
  RESOLVE_MECHANIC                retain-equity-market-price-provider-testimony.v1
  RESOLVE_MECHANIC                hold-unavailable-equity-market-price-provider.v1
  RESOLVE_MECHANIC                reject-nonconforming-native-market-price-testimony.v1
  AUTHOR_SEMANTIC_TRANSFORMATION  transform-resolve-equity-market-price-evidence
```

It emitted 7 authoring artifacts for `resolve-equity-market-price-evidence`:
capability.authority.json, interfaces.authority.json,
execution-authorities.authority.json, semantic-graph.authority.json,
projection-authorities.authority.json, contracts/contract-catalog.json,
semantic-transformation.authority.json.

The work queue is the missing-finance-semantics gap derived by the capability
rather than asserted by an author. Evidence for both runs is retained under
`evidence/direct-invocation-20260909/`.

## The request shape matters

Two example corrections were required before the run above could exist.

1. `estateInventory.capabilities` and `mechanicCatalog.mechanics` must be
   objects carrying `capabilityId` / `mechanicId`. The earlier example carried
   bare strings; the transformation then mapped `c.capabilityId` over strings,
   produced nulls, reported every slot `NOT_FOUND`, and returned a 9-item work
   queue — a plausible wrong answer rather than an error. Both example files now
   carry the correct shape.

2. The blueprint-absent request still fails on the first guard below. The
   capability reads 23 input paths; a conforming run must supply
   `canonicalBlueprint` including `projectionAuthorities` and the three
   `declaredTopology.provenance.archetype*` fields. Absence is unhandled, which
   is the data defect, not a request-authoring rule.

## The data defect: rows, not architecture

The transformation detects absent input with comparisons of the form

```text
equals(format("{t}", { t: json-stringify(path(input, …)) }), "undefined")
```

The declared semantics make that comparison unsatisfiable: a missing path
evaluates to `null` (absence is one value; a target-specific second empty value
such as JavaScript `undefined` is non-portable), and `json-stringify(null)` is
the string `"null"`. Every one of these guards is false on absence, the empty
branch is unreachable, and the absent value proceeds to the next mechanic —
`filter` throws on null, `length` throws `OPERAND_NOT_MEASURABLE`.

Location 1 — the normalized expression nodes:

```text
table   model.transformation_expression_node
column  literal_content_pk  ->  source.content_object.content_bytes
value   "undefined"  (content_object_pk 5029, 11 bytes, sha256:cf939b39…)
refs    35 expression nodes, 0 other references
```

All 35 are the right operand of such a comparison; there is no legitimate use
of the shared bytes mixed in. Rows by namespace:

```text
sidefx:capability:generate-executable-capability-scaffold  12  (expression_node_pk 28589, 28612, 28636, 28718,
                                                              28742, 28774, 28798, 28822, 29833, 29888, 30107, 30169)
sidefx:capability:provision-capability-artifacts            8
sidefx:capability:admit-registry-asset                      8
sidefx:capability:resolve-capability-proof-obligations      4
sidefx:capability:resolve-estate-dependency-closure         3
```

Location 2 — the source documents:

```text
table   source.source_appearance.entry_id = 'semantic-transformation.authority.json'  ->  source.content_object
```

Five documents carry the same literal with the same per-namespace counts
(12/8/8/4/3; 35 total, reconciled against the normalized rows). The scaffold's
document is content_object_pk 2123, sha256:24d056c4…, 138,673 bytes. `planNode`
reads these bytes, not the normalized nodes, so Location 2 is the one that
changes invocation behavior; Location 1 keeps the normalized model honest and
both must agree.

## What a repair touches

The correct value is `"null"`, not `"undefined"`. The bytes exist in both
locations, and `source.content_object` is shared by digest, so a repair inserts
corrected bytes rather than editing shared ones. The live inventory is
`docs/research/scaffold-projection-gap/undefined-literal-inventory.sql`.

The route is a new generation, not an in-place update: all three guards
(`model.guard_transformation_expression_node`, `source.guard_content_object`,
`source.guard_source_appearance`) are enabled and reject UPDATE with 51003
IMMUTABLE_INSPECTION_DATA. Corrected source capsules flow through the ingest
pipeline into a new snapshot and a new published model, exactly as
apply-contract-fix.sql concluded for the contract bytes. The "repoint" shape is
what the derivation produces inside that new generation — new appearance rows
and new literal references — never an edit of the published rows.

## Remaining findings

`CONTRACT_ID_NOT_JSON_SAFE` appears on the successful run, and the emitted
`contract-catalog.json` maps both `equity-market-price-evidence-request.v1` and
`equity-market-price-evidence.v1` to `input.schema.json`. That aliasing has the
same shape as defect 1 in the scaffold defect record and is a separate data
finding from the `"undefined"` literals above.

## Boundaries

The blueprint-conditioned run is a completed scaffold outcome; it is not a
published capability. The scaffold was executed with `DESIGN_RESOLVER_CANDIDATE`
topology; no database write was made (direct invocation performs three
restricted reads and executes in memory). The RapidAPI provider was not called;
no credential was resolved and no HTTP exchange was attempted. The
blueprint-absent path still fails on the first `"undefined"` guard; until the
35 literal rows are corrected through a new generation, absence remains
unhandled and requests must be fully populated.
