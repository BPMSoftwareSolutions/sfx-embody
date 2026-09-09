# Repair decision: the `"undefined"` absence-comparison literals

Status: **applied 2026-09-09.** The repair was executed as an owner login with
the verification matrix clean, then committed. The post-fix acceptance —
invoking `generate-executable-capability-scaffold` with the plain request, no
blueprint, no padding — passes: exit 0, `SCENARIO_DECLARED`,
`TOPOLOGY_RESOLVED`. The residues listed below stand as recorded.

The fix artifact is
[`apply-undefined-literal-fix.sql`](apply-undefined-literal-fix.sql), which
ends in ROLLBACK. The defect inventory is
[`undefined-literal-inventory.sql`](undefined-literal-inventory.sql).

## The defect

Each affected node is the right operand of a comparison whose left operand is
`json-stringify(path(input, …))`. A missing path evaluates to `null` (absence is
one value; a target-specific second empty value such as JavaScript `undefined`
is declared non-portable), and `json-stringify(null)` is the string `"null"`.
The comparison can therefore never be true; the empty branch is unreachable and
the absent value proceeds to the next mechanic, where `filter` throws on null
and `length` throws `OPERAND_NOT_MEASURABLE`.

| Table / column | Rows | Correct value |
| --- | ---: | --- |
| `model.transformation_expression_node.literal_content_pk` → `source.content_object.content_bytes` | 35 nodes | `"null"` (6 bytes) |
| `source.content_object.content_bytes` via `source.source_appearance.entry_id = 'semantic-transformation.authority.json'` | 5 documents, 35 occurrences | `"null"` |
| `model.semantic_object_definition.canonical_content_pk` (derived definition envelope) | 5 envelopes, 35 occurrences | `"null"` |

Per-capability occurrence counts: generate-executable-capability-scaffold 12,
provision-capability-artifacts 8, admit-registry-asset 8,
resolve-capability-proof-obligations 4, resolve-estate-dependency-closure 3.
The shared literal is content_object 5029 (11 bytes, 35 expression-node
references, 0 other references). All occurrences are guard right-operands; no
legitimate use of the shared bytes exists.

## The repair inventory (what the script does, all in one transaction)

1. **Source documents** — the location that changes invocation behaviour
   (`planNode` reads these bytes). 5 documents are rewritten
   (`REPLACE` in varchar space), each becomes a NEW content object
   (digest = `HASHBYTES('SHA2_256', new_bytes)`, the derivation's own rule via
   the `content_digest` check constraint), and only the CURRENT snapshot's
   appearance is repointed (5 rows). Snapshot 1 keeps its original bytes.

2. **Normalized expression nodes** — one new content object holding `"null"`
   (6 bytes), 35 `literal_content_pk` rows repointed off 5029. Object 5029 is
   left in place and becomes unreferenced.

3. **Canonical definition envelopes** — the 5 transformation definitions'
   canonical content is the DERIVED envelope
   (`sidefx-semantic-definition.v1`, expression embedded under `$.semantics`),
   a separate set of objects from the source documents
   (scaffold: envelope pk 13846 vs document pk 2123). Each envelope is
   rewritten the same way, `canonical_content_pk` is repointed (5 rows), and
   `definition_digest` is recomputed — not asserted — as the hash of the new
   envelope bytes, matching the derivation (`definition_digest =
   content.content_digest`). `model.transformation_version.definition_digest`
   (5 rows) is updated to the same value.

4. **FK suspension** — `FK_model_transformation_version_38605ba41d7d` keys on
   the digest composite, so parent and child cannot move while it is enforced.
   `NOCHECK` → both updates → `WITH CHECK CHECK`, then a throw if the FK comes
   back disabled or untrusted. Verified: only 5 `transformation_version` rows
   carry the digest; `estate_definition` and `source.source_lineage` reference
   the definition pk only and are untouched.

5. **Guards** — five AFTER guards throw 51003 IMMUTABLE_INSPECTION_DATA on any
   UPDATE. They are disabled inside the transaction and re-enabled before it
   ends: `guard_content_object`, `guard_source_appearance`,
   `guard_transformation_expression_node`,
   `guard_semantic_object_definition`, `guard_transformation_version`.
   Requires owner ALTER; `sidefx_importer` is INSERT-only by grant.

## Verification matrix (dry run, all clean)

| Check | Expect | Observed |
| --- | --- | --- |
| Precondition: literal 5029 value | `"undefined"` | PASS |
| Precondition: nodes on 5029 | 35 | PASS |
| Documents rewritten | 5 | PASS |
| Document appearance repoints | 5 | PASS |
| Node repoints | 35 | PASS |
| Definitions rewritten | 5 | PASS |
| Definition digest updates | 5 | PASS |
| Version digest updates | 5 | PASS |
| Precondition: stored digest == hash of canonical content | all | PASS |
| FK trusted after WITH CHECK | trusted | PASS |
| `loc1_documents_expect_0` | 0 | 0 |
| `loc2_expression_nodes_expect_0` | 0 | 0 |
| `loc3_definitions_expect_0` | 0 | 0 |
| `definitions_with_stale_digest_expect_0` | 0 | 0 |
| `versions_disagreeing_with_definition_expect_0` | 0 | 0 |
| Snapshot 1 documents still original | 5 | 5 |
| New document digests recomputed from stored bytes | DIGEST_OK × 5 | PASS |
| Byte delta per document | exactly 5 × occurrences (−60/−40/−40/−20/−15) | PASS |
| Rollback leaves 35 nodes on 5029, zero new objects, guards enabled | clean | PASS |

Byte-delta arithmetic is the cheapest proof that no other bytes moved.
`varbinary → varchar → varbinary` round-trips byte-identically on all five
documents, all five envelopes, and the literal — verified before the REPLACE
was trusted (a single multi-byte character would otherwise be silently
corrupted, since the rewrite runs in varchar space).

Measurement note: occurrence counting must happen in byte/varchar space. A
`CAST → nvarchar` conversion measured one fewer occurrence per envelope (an
encoding artifact of the cast, not a property of the data); the authoritative
counts are 12/8/8/4/3 in byte space, and the script never counts through
nvarchar.

## Execution record (2026-09-09)

The script was run twice through the dbo connection (`cmsappaccount`, db_owner):

1. Dry run ending in ROLLBACK — all five verification recordsets matched the
   matrix above; new objects 53002–53006 were discarded.
2. Commit run — the final lines were flipped (`ROLLBACK` commented,
   `COMMIT` active) and the transaction committed. New document objects
   53013–53017 (`DIGEST_OK` each), byte lengths 35,433 / 138,613 / 44,985 /
   30,309 / 24,044 — deltas exactly 5 × occurrences.

Independent post-fix state check: 0 nodes on 5029, 35 nodes on the `"null"`
literal object, 0 guards disabled, FK trusted, 0 definitions carrying
`"undefined"`, 0 stale definition digests.

Acceptance:

| Run | Exit | Result |
| --- | --- | --- |
| `sfx capability invoke generate-executable-capability-scaffold --input '@examples/rapidapi-scaffold.request.json'` (plain request, the defect's own test) | 0 | terminated, `SCENARIO_DECLARED`, `TOPOLOGY_RESOLVED`, `SCAFFOLD_INCOMPLETE`, 3 FOUND / 1 NOT_FOUND, 8-item queue |
| same capability, blueprint-conditioned request | 0 | HELD, `COMPOSITION_RESOLVED` — unchanged |
| `resolve-sidefx-eligible-providers` (untouched capability) | 0 | `PROVIDERS_RESOLVED` — estate unaffected |

## Residues (unchanged by the fix, recorded not fixed)

- `source.source_appearance.capsule_digest` still names the pre-fix capsule for
  the affected entries. A capsule digest covers packed entries and the packing
  format is not in the database, so it cannot be recomputed in SQL. Nothing in
  SQL validates or recomputes it (it appears only as a column declaration and
  as join/grouping keys), so it breaks nothing at read time. It stays wrong
  until the capsules are repacked.
- Re-running capture/derive reproduces the ORIGINAL bytes and will disagree
  with the current-snapshot rows. The repaired state is hand-reproducible via
  the script, not reproducible via the ingest pipeline.
- `source.validate_model` is not run and cannot be — it requires
  `publication_state = 'BUILDING'`; this model is PUBLISHED.
- `runtime.capability_preparation` rows planned from pre-fix bytes are stale
  for the 5 affected capabilities. Invocation never reads preparations
  (direct invocation), so this is inert today.

## The alternative route (rejected for now, retained as the end-state)

The pipeline-honest repair is a new generation: correct the five
`semantic-transformation.authority.json` source documents in their source
capsules, repack, capture a new snapshot, derive, publish. That restores
capsule-digest honesty and pipeline reproducibility. It is materially more
work and moves several estates at once. The surgical repair is accepted as an
interim state on the explicit understanding that the re-ingest route remains
the obligation that closes the residues. The script's rewritten bytes are
exactly what the corrected source documents should contain.

## Execution protocol

1. Run `apply-undefined-literal-fix.sql` as an owner login (guards need ALTER).
2. Read every verification recordset; all must match the matrix above.
3. Only then change the final `ROLLBACK TRANSACTION` to
   `COMMIT TRANSACTION` and run once. Do not re-run after commit (idempotent
   inserts, but the UPDATE preconditions expect the pre-fix counts).
4. Nothing else may write the affected tables between the dry run and the
   commit run (re-verify preconditions immediately before committing).

## Post-commit acceptance (the real test)

1. **The defect's own test:** `sfx capability invoke
   generate-executable-capability-scaffold --input
   '@examples/rapidapi-scaffold.request.json'` — the ORIGINAL request, no
   blueprint, no padded `projectionAuthorities` — must complete with exit 0
   and take the authored absence branch (no `filter`/`length` throw).
2. The blueprint-conditioned run (`rapidapi-scaffold-blueprint.request.json`)
   must still return exit 0, HELD, COMPOSITION_RESOLVED.
3. The other 4 capabilities' absence branches are exercised by their own
   fixtures/consumers; no throw expected anywhere the guard previously threw.
4. sfx-embody: `npm test`, `npm run verify:memory` (the three regression
   capabilities are not among the five affected; parity must still pass),
   and the scaffold direct-invocation evidence re-run.

## Rollback

All pre-fix objects (5 documents, 5 envelopes, literal 5029) remain in the
database after the fix — unreferenced, not deleted. Reversal is the reverse of
the repoints: 5 appearance rows, 5 `canonical_content_pk` rows, 5+5 digest
rows, 35 `literal_content_pk` rows, guards re-enabled, FK re-trusted. No data
destruction is involved; DELETE is exactly what the guards exist to prevent.

## Open findings (separate from this fix)

- `CONTRACT_ID_NOT_JSON_SAFE` on the successful blueprint run, and the emitted
  `contract-catalog.json` mapping both
  `equity-market-price-evidence-request.v1` and
  `equity-market-price-evidence.v1` to `input.schema.json` — a distinct data
  finding in the scaffold's emitted catalog, recorded in
  [`../scaffold-invocation-rapidapi.md`](../scaffold-invocation-rapidapi.md).
