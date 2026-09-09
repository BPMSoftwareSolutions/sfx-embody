# Invoking the scaffold capability from the database

Assessment: 2026-09-09. Subject: invoking `generate-executable-capability-scaffold`
through the direct database path in [database-direct-invocation.md](database-direct-invocation.md)
to scaffold a RapidAPI provider capability.

The contract-openness blocker recorded in the previous assessment is resolved,
and the capability now runs end-to-end through the direct invocation on both
paths. The blueprint-conditioned request completes with exit 0 and
`COMPOSITION_RESOLVED`. The plain request — no blueprint, no padded fields —
now takes the authored absence branch and completes with exit 0,
`SCENARIO_DECLARED` and `TOPOLOGY_RESOLVED`, after a one-time repair of the
`"undefined"` absence literals described below.

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

The transformation detected absent input with comparisons of the form

```text
equals(format("{t}", { t: json-stringify(path(input, …)) }), "undefined")
```

The declared semantics make that comparison unsatisfiable: a missing path
evaluates to `null` (absence is one value; a target-specific second empty value
such as JavaScript `undefined` is non-portable), and `json-stringify(null)` is
the string `"null"`. Every one of these guards was false on absence, the empty
branch unreachable, and the absent value proceeded to the next mechanic —
`filter` threw on null, `length` threw `OPERAND_NOT_MEASURABLE`.

Location 1 — the normalized expression nodes:

```text
table   model.transformation_expression_node
column  literal_content_pk  ->  source.content_object.content_bytes
value   "undefined"  (content_object_pk 5029, 11 bytes)
refs    35 expression nodes, 0 other references
```

All 35 were the right operand of such a comparison, spanning 5 namespaces
(12/8/8/4/3). Location 2 — the five `semantic-transformation.authority.json`
source documents, which `planNode` actually reads — carried the same 35
occurrences, and a third copy existed in the derived canonical definition
envelopes.

**Repaired 2026-09-09.** [`apply-undefined-literal-fix.sql`](research/scaffold-projection-gap/apply-undefined-literal-fix.sql)
rewrites all three locations (documents, expression nodes, canonical
envelopes), recomputes the derived digests, and records its verification
matrix; the [decision record](research/scaffold-projection-gap/undefined-literal-repair-decision.md)
documents the execution and acceptance. The plain request now takes the
authored absence branch:

```text
sfx capability invoke generate-executable-capability-scaffold --input '@examples/rapidapi-scaffold.request.json'
exit 0 | SCENARIO_DECLARED | TOPOLOGY_RESOLVED | SCAFFOLD_INCOMPLETE
```

Two residues remain and are recorded, not fixed: the affected
`source.source_appearance.capsule_digest` values still name the pre-fix
capsules (nothing in SQL validates or recomputes them; they stay wrong until
the capsules are repacked), and re-running capture/derive would reproduce the
original bytes — the repaired state is hand-reproducible via the script, not
via the ingest pipeline. The estate-wide row inventory is
`docs/research/scaffold-projection-gap/undefined-literal-inventory.sql`.

## Remaining findings

`CONTRACT_ID_NOT_JSON_SAFE` appears on the successful run, and the emitted
`contract-catalog.json` maps both `equity-market-price-evidence-request.v1` and
`equity-market-price-evidence.v1` to `input.schema.json`. That aliasing has the
same shape as defect 1 in the scaffold defect record and is a separate data
finding from the `"undefined"` literals above.

## Boundaries

The blueprint-conditioned run is a completed scaffold outcome; it is not a
published capability. The plain-request run is the authored absence branch and
now completes the same way. The scaffold was executed with
`DESIGN_RESOLVER_CANDIDATE` topology; no database write was made by invocation
(direct invocation performs three restricted reads and executes in memory; the
literal repair above is a separate, recorded one-time database operation). The
RapidAPI provider was not called; no credential was resolved and no HTTP
exchange was attempted.
