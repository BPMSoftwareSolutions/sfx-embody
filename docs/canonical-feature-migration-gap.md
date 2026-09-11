# Canonical feature writeups: reconciliation and migration strategy

Reviewed on 2026-09-11. This document specifies the migration strategy and records
fresh read-only evidence. No database, schema, Harness authority or capsule was
changed by this review.

## 1. Required outcome

**Every capability in the database must have a canonical feature. This applies
equally to managed and provisional capabilities.** The feature must describe the
exact capability revision that is invoked, and its full declaration must be
available through the database's semantic model.

The canonical feature is a required part of a Capability definition. Retaining
some `.feature` bytes at a matching path is insufficient. The database needs an
explicit relationship from the Capability version to its canonical feature,
complete normalized scenarios and tags, and provenance back to the exact bytes.

This migration will backfill existing capabilities and enforce the requirement
on every subsequent registration and revision. There is no separate authored
candidate catalog in this strategy. Managed/provisional status does not relax
feature completeness or require a provisional capability to undergo managed
admission merely to have a canonical feature.

A feature file with no corresponding database capability is an inventory item,
not an instruction to register a new capability. Conversely, an existing database
capability cannot be excluded from this migration because its writeup is missing,
untagged, provisional, or outside the Harness `features/` directory.

## 2. Verified baseline

The [read-only audit](research/canonical-feature-migration/audit.mjs) uses the
existing database Gherkin parser and restricted SQL reader. The
[retained report](research/canonical-feature-migration/review-20260911.json)
contains file hashes, declared IDs, differences, selected scenario versions,
feature lineage, and implementation hashes.

| Pin | Value |
| --- | --- |
| Selected estate model | `34` |
| Snapshot | `sha256:1a770ac0795d10665a88166f8d8c968dc5b2d030fdfab2b837aa6071d135f9e9` |
| Projection / mapping manifest | `sha256:8aae1f306ced5952333da0fb936d2f846081f8ed31b6f627a2099ad49cbbfdb0` |
| Corpus compared | `C:/lab/repos/agentic-harness/features/*.feature` |
| Selected Capability namespace | `sidefx:capabilities` |

| Measure | Verified value |
| --- | ---: |
| Capability identities retained in `model.capability` | **290** |
| Capability versions retained in `model.capability_version` | **313** |
| Currently selected capabilities / owned scenarios | 220 / 825 |
| Canonical files / files with matching retained bytes | 235 / 235 |
| Files with a capability tag / distinct capability IDs | 234 / **233** |
| Scenario blocks / blocks carrying a scenario ID | 1,053 / 1,041 |
| Globally distinct scenario ID strings | 1,028 |
| Distinct `(capability ID, scenario ID)` pairs | **1,031** |
| Selected scenarios with authored steps / without steps | 824 / 1 |
| Distinct retained `.feature` source paths in this snapshot | 390 |

The original report covered 220 selected capabilities. **The migration inventory
must cover all 290 identities and reconcile all 313 retained versions.** The
report's `unselectedIdentities` names the other 70 identities; their canonical
feature coverage and registration history still need version-by-version review.
They are not excluded as drafts. Historical definitions remain immutable, but
history must be accounted for and every invocation-addressable version needs an
exact canonical feature binding.

A snapshot ID alone does not identify a model: registrations and mapping changes
can produce different generations over the same snapshot. Freeze the selected
model, mapping manifest and exact retained-source inventory for each migration
run. These counts are the reviewed baseline, not evergreen target constants.

### Corrections to the original gap accounting

Scenario identity is Capability-owned. Three repeated scenario ID strings occur
under different Capability owners and are valid distinct identities. Ten more
occur in both HTTP feature revisions under the same owner. The HTTP candidate
also declares three additional scenarios. Neither file may win by iteration order.

All 12 untagged blocks are in `manage-capsule-estate.feature`, which also lacks
`@capability`. `manage-capsule-estate` exists in the selected model with zero
scenarios. Its filename suggests a correspondence; the migration must establish
that correspondence explicitly and supply canonical identities, not guess them.

| Difference against the selected 220-capability model | Capability IDs | Owned scenarios |
| --- | ---: | ---: |
| A. Tagged corpus declarations absent from the selected model | **38** | 241 |
| B. Selected capabilities with no matching capability tag in this corpus | **25** | 40 |
| C. Shared owners with corpus-only scenario declarations | **3** | **18** |
| D. Shared owners with model-only scenario declarations | 3 | **13** |

Group B comprises the 24 SideFX semantic-brain capabilities and the untagged
capsule-estate case. Group D contains 13 owned scenarios, representing nine
unique ID strings. The original 39/24 capability split, 15 group-C scenarios and
ten group-D scenarios did not reconcile the actual identity grain.

```text
233 declared capability IDs - 38 corpus-only + 25 model-only = 220 selected
1,031 owned scenario pairs - 241 group A - 18 group C
                          + 13 group D + 40 group B = 825 selected
```

These equations explain the selected-model comparison. They are not a target of
1,031 scenarios and do not establish coverage of all 290 database identities.
Group A means absent from the current selection, not necessarily absent from
all database history.

| Shared capability | Corpus-only IDs | Model-only IDs |
| --- | ---: | ---: |
| `author-canonical-feature` | 12 | 0 |
| `resolve-equity-market-price-evidence` | 3 | 0 |
| `observe-governed-http-exchange` (both files combined for inventory) | 3 | 0 |
| `operate-tooling-migration-promote` | 0 | 6 |
| `operate-tooling-migration-verify` | 0 | 5 |
| `operate-tooling-migration-run` | 0 | 2 |

The report's `missingCapabilities`, `modelOnlyCapabilities`, and
`sharedDifferences` retain complete IDs without truncation.

## 3. Root causes established by implementation review

There is already a feature projector. Its coverage and the separate registration
implementation explain why retained features and normalized definitions diverge.

| Boundary | Current behavior | Migration implication |
| --- | --- | --- |
| [Normalization v1](C:/lab/sidefx-database/config/normalization-v1.json) and [v2](C:/lab/sidefx-database/config/normalization-v2.json) | Managed capsule membership is explicit; v2 preserves it | A retained repository file alone does not establish selected membership; this historical rule is not the new feature-completeness boundary |
| [Managed normalizer](C:/lab/sidefx-database/src/migration/normalize.mjs) | Parses capsule features; retains scenario AST and tags; projects faces and references | Reuse this responsibility, with corrected reconciliation and completeness checks |
| [Provisioned registration](C:/lab/sidefx-database/src/register/capability.mjs) | Takes `spec.scenarios` and constructs face-only scenario semantics independently of the retained feature | Replace the independent scenario list with the same full feature projection used by managed ingestion |
| Feature source selection | Normalizer checks a `features/` entry and a `.feature` source path, including semantic-brain sources with capsule aliases | Both lineages can use one parser with explicit source selectors |
| [Publication](C:/lab/sidefx-database/src/migration/schema.mjs) | Published definitions and membership are immutable; a BUILDING generation is validated and selected atomically | Backfill through versioned definitions and a new generation, not in-place edits |

The membership rule was therefore documented. It does not justify leaving any
managed or provisional database capability without a canonical feature.

Feature narrative is also partly retained today: the managed normalizer hashes
the cleaned feature AST into Capability contributions. The actual description
is recoverable from the retained source, but is not exposed as a first-class
Capability narrative. Structured `userStory` and `experience` come from authority
JSON; general prose must not be converted into those fields by inference.

### The equity example needs revision reconciliation

The [Harness feature](C:/lab/repos/agentic-harness/features/resolve-equity-market-price-evidence.feature)
has four scenarios and root input `equity-market-price-evidence-request`. The
[registered feature](../features/resolve-equity-market-price-evidence.feature)
has one scenario and root input `live-equity-price-request`. Its
[registration specification](C:/lab/sidefx-database/config/register/resolve-equity-market-price-evidence.json)
uses the latter shape. The selected root has `live-equity-price-request` and no
Gherkin steps in its semantic definition.

The [existing meaning review](reviews/resolve-equity-market-price-evidence.md)
reports six execution-authority definitions with three operation sets; its
circuit intentionally displays their union. The three unresolved scenario
invocations belong to only some of those definitions. This is evidence of
revision disagreement, not proof that the selected implementation simply needs
three additional scenario rows.

First bind the feature, contracts and execution authorities belonging to the
same invocable revision. Fully normalizing the registered one-scenario feature
repairs specification loss for that revision. Making the four-scenario Harness
feature canonical for the current capability is a semantic revision: its support
authorities and applicable proof must agree. The migration must record the
choice explicitly, and cannot produce a hybrid from both.

## 4. Canonical feature contract

Every Capability version exposed for invocation must satisfy these invariants:

1. **One canonical feature definition.** It has an exact semantic digest and an
   explicit binding to retained raw feature bytes. Multiple identical or
   semantically equivalent appearances can contribute lineage; differing semantic
   revisions cannot jointly be the canonical feature for one Capability version.
2. **Complete owned scenario set.** Every declared scenario appears exactly once
   in `model.capability_scenario` for that version, and every modeled scenario
   belongs to the canonical feature. The root is declared, unique, belongs to the
   same Capability, and agrees with supporting Capability authority.
3. **Full authored meaning.** Feature narrative, scenario specifications, tags and
   Gherkin context survive projection. Face-only definitions do not satisfy this
   contract.
4. **Coherent references.** Inputs, events, outcomes, contracts and execution
   references resolve against the same revision and explicitly pinned shared
   dependencies. An unresolved reference remains a typed finding; feature
   presence alone does not prove execution readiness.
5. **Traceable revision.** Source observations and mapping rules identify exactly
   what supplied each declaration. A digest match at a path is not authority
   selection.

The feature governs the declared semantic promise and scenario set. Contracts,
execution authorities, bindings and proofs remain their own declarations, and
must agree with that promise. A discrepancy is reconciled at the source revision;
it is not settled by whichever representation has more rows.

### Source selection and authority

Produce a frozen reconciliation manifest for every database Capability identity
and version. It includes namespace/owner, current definition digest, applicable
managed/provisional lineage, exact feature digest and appearances, supporting
authority digests, root/scenario set, discrepancies, and resolution evidence.

Use the revision's applicable registration, capsule, placement or admission
records to establish its source set. Both managed and provisional sources can
supply a canonical feature. Neither class automatically overrides the other.
A newer timestamp, larger file, path spelling, or scenario count never selects
authority. Unverifiable placement evidence leaves a reconciliation item open.

Use these dispositions during migration:

| Finding | Required resolution |
| --- | --- |
| Exact feature already matches the revision | Bind it and verify full normalized fidelity |
| Matching feature retained, mapping incomplete | Re-project the full feature and affected dependencies |
| Multiple conflicting feature revisions | Select the exact coherent revision with source evidence; retain alternatives as history |
| Feature absent or missing canonical IDs | Recover the correct source or author/reconcile it through the capability's applicable change path; do not derive authority from an incomplete model |
| Model has scenarios absent from a compared file | Locate the feature that actually supplied that version, or reconcile the writeup; never delete scenarios solely to match a shorter file |

Missing canonical features are migration defects to resolve. They are not
permanent exceptions, a reason to remove a capability from inventory, or a reason
to relabel an invocable provisional capability as a draft.

## 5. One projection core for managed and provisional capabilities

`sidefx-database` should own one deterministic feature-to-semantic projection
core. Managed ingestion, provisional registration and revision operations use
that same core. Their source-selection and lifecycle evidence may differ; their
canonical feature completeness contract does not. `sfx-embody` consumes and
verifies the resulting definitions.

Retain both source layouts. Resolve packaging aliases explicitly rather than
moving files or maintaining separate semantic projectors. Registration must
parse the exact retained feature bytes; `spec.scenarios` must cease being an
independently maintained source of semantic truth. During transition it can only
be a derived value or an equality assertion against the parsed feature.

| Declaration | Normalized destination / rule |
| --- | --- |
| `@capability` | Capability identity in its explicit namespace; agree with its declared owner |
| `@root-scenario` | `model.capability_root_scenario`; agree with `rootScenarioId` and the selected scenario set |
| Feature title, description and complete AST | Explicit feature fragment in the Capability semantic envelope, with exact retained-source binding |
| `@scenario`, name and full specification | `model.scenario`, `model.scenario_version`, `model.capability_scenario`; retain `semantics.scenario.steps` for current consumers |
| `@input` / `@input-contract` | `model.scenario_input` and exact contract-version reference/state |
| `@event` / `@event-authority` | `model.scenario_event` and exact execution-authority reference/state |
| `@outcome` / `@outcome-contract` | `model.scenario_outcome` and `model.scenario_outcome_contract` |
| `@outcome-terminal` / `@terminal-disposition` | Explicit terminality and disposition; no disposition inferred from prose |
| Other tags | Preserve verbatim and classify unsupported semantic mappings; never silently discard them |

Identity remains `(namespace, capability ID)` and `(Capability, scenario ID)`.
Do not introduce filename-derived IDs or global Scenario identity. Duplicate
singleton tags, conflicting roots, and duplicate scenario declarations within
one selected revision fail canonical-feature validation. Repeated source copies
add lineage, not scenario rows. Untagged blocks remain visible findings until
authored canonical IDs resolve them.

Use the existing Gherkin parser. The mapping must preserve Rule and Background
context, Scenario Outlines, Examples, tables, doc strings, inherited tags and
ordered steps. An Outline remains one declared Scenario, not one identity per
example row. `And`/`But` inherit the preceding step kind when deriving face prose;
retaining only direct Given/When/Then keyword matches is incomplete. Unsupported
structures produce findings instead of being silently flattened.

Missing references preserve exact declared text and `ABSENT` versus `UNRESOLVED`.
Do not fabricate Contract, execution authority, Product or Blueprint entities.
In particular, outcome-contract misses need an explicit observation: the current
normalizer only inserts that relationship when it resolves. General Feature
prose remains narrative; structured user stories, experiences and observable
conditions retain their own authority.

Semantic digests cover normalized semantic fragments and exact semantic
references. Raw-byte/capsule digests, paths, timestamps and parser locations are
provenance. Keep raw bytes for reconstruction. Packaging changes alone must not
change semantic identity. Converging registration's current provisioning-manifest
hashing with this contract will create new definition versions under a new
mapping rule; old definitions remain intact.

## 6. Database enforcement

Use the existing Capability/Scenario identity and version model. Add an explicit
version-owned canonical-feature binding and validation through the active schema
migration path. Physical table/column names and DDL are the next implementation
artifact; the required contract is:

- The binding selects one canonical semantic feature for a Capability version,
  resolves its complete parsed fragment and exact retained source lineage, and
  is immutable with that version. Provenance may include multiple appearances.
- The Capability envelope includes the feature semantics and complete owned
  scenario membership, using the reviewed finite contribution manifest to avoid
  recursive definition hashing. Scenario/member pointers resolve to those exact
  declarations.
- A database-enforced completeness gate compares the projected scenario set,
  root, tags and feature binding. Direct SQL cannot bypass it by inserting
  face-only rows or selecting an incompletely projected generation.
- Registration, revision and publication use that gate for managed and
  provisional capabilities alike. Invocation resolves the feature belonging to
  its selected exact Capability version and reports a precise integrity error
  if the binding is missing or contradictory.
- A migration receipt records predecessor/candidate models, mapping and source
  digests, replacements, open findings, validation and cutover. Receipt status
  cannot turn an unresolved source conflict into a canonical feature.

Published historical definitions cannot be rewritten in place. Where the
migration merely establishes an evidenced feature association for an old version,
use an append-only, validated provenance association compatible with immutability.
Where authored semantics or scenario membership change, create a new version and
record supersession. Never attach changed semantics to an unchanged definition
digest. Every historical version gets a documented disposition; any version
available through invocation must meet the full contract.

New schema work must be additive and versioned. Do not edit the installed
migration-001 digest, disable guards, revive retired importers, or rebuild by
dropping retained history. Database `PUBLISHED` state does not confer Harness
managed admission on a provisional capability.

## 7. Migration sequence

| Stage | Work | Exit evidence |
| --- | --- | --- |
| 1. Inventory every Capability | Reconcile all 290 identities / 313 retained versions; identify every invocation-addressable revision and exact feature/support source set | No identity omitted; each discrepancy has a concrete resolution path |
| 2. Prove shared projection | Implement canonical-feature binding and common parser/mapping; exercise managed and provisional controls | Same semantic source set produces the same definitions through both ingestion paths |
| 3. Reconcile and backfill | Repair missing writeups/IDs and source conflicts; derive complete replacement definitions into an unpublished generation | All required canonical features are complete and coherent; no unexplained scenario additions/removals |
| 4. Verify full coverage | Apply relational, lineage, semantic-fidelity and affected execution checks | Every invocable Capability version satisfies the contract; all historical versions are dispositioned |
| 5. Cut over atomically | Recheck frozen inputs and expected predecessor; validate and select under the writer lock | Exact old/new generation receipt; concurrent stale publisher rejected |
| 6. Enforce continuously | Run the same projection/completeness gates on every registration and revision | Feature/model drift cannot be introduced by a separate provisional path |

Run pilots before the full backfill, using:

1. `resolve-sidefx-eligible-providers` as the managed semantic-brain-layout
   control, with its exact selected feature and existing fixture behavior.
2. `resolve-equity-market-price-evidence` as the provisional registration repair
   and conflicting-revision control. Establish its exact feature and supporting
   source set before projecting the replacement.
3. Both HTTP features and the three tooling-migration capabilities as conflicting
   revision and scenario-preservation controls; `manage-capsule-estate` as the
   missing-canonical-ID case.

Pilots prove the mechanism. They are not completion of the migration. Keep the
existing selected model in service while the complete replacement is built;
missing-feature enforcement on the existing estate and final cutover arrive with
the backfill. Do not drop capabilities or intentionally break invocation to make
a coverage percentage pass. Unresolved canonical-feature defects keep the
migration incomplete.

Derive the complete candidate before loading. Follow foreign-key dependencies:
source/observations, reusable definitions, Capability/Scenario versions and
membership, execution authorities and operations, faces/bindings, lineage and
coverage, then publication. Plan exact references before inserting immutable
rows; never insert an unresolved face with a plan to mutate it after publication.

Recompute the affected dependency closure, including invocations, contracts,
fixtures, observable conditions, blueprint pins and preparation identities.
Carry unaffected definitions and evidence. Changed definitions do not inherit
old proof or assessments as though they had been revalidated. Canonical feature
projection alone does not supply a missing Blueprint or execution authority.

Selected meaning and execution queries must follow exact version FKs and owner
scope. Historical comparison may display alternatives explicitly. Joining on
scenario ID text alone or unioning all retained execution-authority versions
cannot define the canonical circuit of the selected Capability revision.

## 8. Idempotency, cutover and rollback

The migration run key binds the predecessor generation, frozen source-selection
manifest, mapping rule and parser/projector implementation digests. Repeating the
same plan reuses immutable content/definitions and verifies committed row
contents. Different sources, mappings or predecessor create a different plan.
Counts alone are insufficient retry evidence.

Failed loads leave the selected model untouched. Earlier table commits may remain
for diagnosis and resume; final validation failure does not undo them. Checkpoints
must belong to the exact plan. Do not reuse the existing fixed-generation loader's
checkpoints for an unrelated backfill.

The existing `source.publish_model` takes a writer lock and validates before
selection, but has no expected-predecessor argument. Add a database-enforced
compare-and-select check in the same transaction so a candidate built against an
old generation cannot replace a newer registration. Verify frozen inputs and
compatible reader definitions at that boundary as well.

Prove an owner-executed rollback operation before cutover. It must reselect the
previous published generation under the writer lock, check the expected current
generation, validate compatibility and retain a selection receipt. This is a
required extension, not an existing command: `source.publish_model` expects a
BUILDING generation and is not a general rollback selector.

Retain the previous generation and compatible reader/schema behavior throughout
the rollback window. Exercise forward selection and rollback in an isolated
database first. Rollback restores database selection, preserves source/history,
and causes subsequent invocations to resolve the restored exact revision; it
does not undo effects already executed. A rollback to the pre-migration baseline
also restores its known feature gaps and reopens migration completion.

## 9. Acceptance evidence

The migration is complete when:

- Every database Capability identity is accounted for, and every invocation-
  addressable version has exactly one fully projected canonical feature, for
  managed and provisional estates alike. Historical-version dispositions are
  complete; selected-only counts cannot conceal missing identities.
- For each migrated version, its declared and modeled scenario sets are equal,
  its root agrees, and full prose/tags/context survive. The 235 corpus files and
  other declaring sources retain digest-bound dispositions without treating
  every source file as a new Capability.
- Duplicate copies preserve identity and add lineage; same scenario text IDs
  under different owners stay distinct; conflicting revisions cannot merge.
  Missing IDs and missing references produce explicit failures/findings.
- Both registration and ingestion use the shared core. Repeat runs create no
  duplicate semantic rows; semantic changes mint new versions; published
  definitions remain immutable.
- SQL key, ownership, lineage, canonical-feature and constraint-trust gates pass.
  Relevant meaning, resolver, invocation and retained-fixture checks pass for
  changed definitions and their affected dependencies.
- Adversarial checks reject registration/publication without a canonical feature,
  extra or missing scenarios, contradictory roots, stale source/predecessor,
  and direct-SQL bypass. Interrupted load/resume and competing publishers are
  exercised. Readers observe one coherent generation during cutover/rollback.

The next implementation deliverable is the version-by-version reconciliation
manifest plus the additive binding/gate specification and shared projection
contract. Source repairs follow the applicable managed or provisional change
path; no additional policy decision about whether provisional capabilities
qualify for canonical features remains open.

## 10. Reproduce this review

From `C:/lab/repos/sfx-embody`, with the existing database reader configuration:

```powershell
node docs/research/canonical-feature-migration/audit.mjs C:/lab/sidefx-database C:/lab/repos/agentic-harness canonical-feature-review.json
```

This executes [audit.sql](research/canonical-feature-migration/audit.sql) in one
transaction-pinned restricted read, requests memory-only query delivery, rejects
truncation and writes only the explicit JSON report. It rechecks corpus file
bytes after the query. It does not recapture, ingest, register, publish or invoke.

A future run measures the then-selected generation and local corpus; compare
pins before comparing counts. The audit establishes the selected-model
reconciliation and full identity/version counts. It does not yet establish
canonical-feature coverage for all 313 versions or resolve source conflicts.
