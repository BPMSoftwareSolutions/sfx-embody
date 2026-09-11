# Canonical feature normalization: target model and migration

Reviewed on 2026-09-11. The evidence below is read-only; no database was changed
by this review. The schema is under active development, generated from
`catalog.mjs`, `schema.mjs` and `views.mjs`. The current `model.capability` and
`model.scenario` shape is a starting point, not a constraint. This document
defines the target model for canonical features and the expand/contract migration
that reaches it.

## 1. Required outcome

**Every invocation-addressable capability version binds to exactly one canonical
feature version, and the feature is the authority for that capability's declared
scenarios and authored behavior.** Non-managed platform dependency rows are out
of scope and are removed from inventory rather than migrated (§2.1).

The feature is a **first-class normalized object** in the model. It is not an
opaque digest in a capability envelope, and it is not a separately maintained
face list on a registration specification. Retaining `.feature` bytes at a
matching path does not satisfy this outcome on its own.

The model must hold all of the following:

- the normalized feature declaration (title, narrative, tags, language);
- the exact scenario versions the feature declares, with their authored Gherkin;
- an explicit, version-owned binding from the capability version to its one
  canonical feature version;
- provenance from the feature declaration back to the exact retained bytes.

This applies equally to managed and provisional capabilities. There is no
separate authored candidate catalog in this strategy, and provisional status
does not relax feature completeness.

A feature with no corresponding capability is an inventory item, not an
instruction to register a new capability. Conversely, an existing managed or
provisional capability cannot be excluded because its writeup is missing,
untagged, or outside the Harness `features/` directory. This scope covers the
`sidefx:capabilities` namespace. The non-managed `sidefx:platform-capabilities`
catalog rows described in §2.1 are not capabilities and are excluded rather than
dispositioned as drafts.

## 2. Verified baseline

The [read-only audit](research/canonical-feature-migration/audit.mjs) uses the
existing database Gherkin parser and restricted SQL reader. The
[retained report](research/canonical-feature-migration/review-20260911.json)
contains file hashes, declared IDs, differences, selected scenario versions,
feature lineage, and implementation hashes. Every figure cited below is
reproduced by standalone SQL in the
[SQL appendix](research/canonical-feature-migration/appendix.md).

| Pin | Value |
| --- | --- |
| Selected estate model | `34` |
| Snapshot | `sha256:1a770ac0795d10665a88166f8d8c968dc5b2d030fdfab2b837aa6071d135f9e9` |
| Projection / mapping manifest | `sha256:8aae1f306ced5952333da0fb936d2f846081f8ed31b6f627a2099ad49cbbfdb0` |
| Corpus compared | `C:/lab/repos/agentic-harness/features/*.feature` |
| Selected Capability namespace | `sidefx:capabilities` |

| Measure | Verified value |
| --- | ---: |
| Capability identities retained in `model.capability` | **290** (220 managed + 70 non-managed platform) |
| Capability versions retained in `model.capability_version` | **313** (228 managed + 85 non-managed platform) |
| Managed capability identities in `sidefx:capabilities` | **220** |
| Managed capability versions in `sidefx:capabilities` | **228** |
| Currently selected capabilities / owned scenarios | 220 / 825 |
| Canonical files / files with matching retained bytes | 235 / 235 |
| Files with a capability tag / distinct capability IDs | 234 / **233** |
| Scenario blocks / blocks carrying a scenario ID | 1,053 / 1,041 |
| Globally distinct scenario ID strings | 1,028 |
| Distinct `(capability ID, scenario ID)` pairs | **1,031** |
| Selected scenarios with authored steps / without steps | 824 / 1 |
| Distinct retained `.feature` source paths in this snapshot | 390 |

The original report covered 220 selected capabilities. **The migration inventory
must cover all 220 managed identities and reconcile all 228 retained managed
versions.** The report's `unselectedIdentities` names 70 identities, but all 70
are the non-managed `sidefx:platform-capabilities` catalog (§2.1), not unselected
managed capabilities. There are no unselected `sidefx:capabilities` identities.
The platform rows are excluded rather than dispositioned as drafts. Historical
managed definitions remain immutable, but history must be accounted for and
every invocation-addressable managed version needs an exact canonical feature
binding.

A snapshot ID alone does not identify a model: registrations and mapping changes
can produce different generations over the same snapshot. Freeze the selected
model, mapping manifest and exact retained-source inventory for each migration
run. These counts are the reviewed baseline, not evergreen target constants.

### 2.1 Non-managed platform-catalog rows (excluded)

A rogue automated change materialized the pinned platform authority's provider
catalog as `model.capability` rows. The source
`sda-platform-capabilities.semantic-authority.json` declares `capabilities[]`
entries whose `capabilityId` values describe provider ports, runtimes, stores and
transforms (for example `sda-node-consumer-runtime.v1`,
`sda-json-authority-ingestion-port.v1`). `src/migration/platform.mjs` defines
each entry as a CAPABILITY in the `sidefx:platform-capabilities` namespace, so
these dependency declarations are counted alongside genuine managed capabilities.

They are not capabilities. The platform contract itself states the catalog IDs
"are dependencies with exact definitions, not additional managed capability
memberships or invented Scenarios" (`config/platform-normalization.json`). The
identifiers also bake the definition revision into the identity (`.v1`, `.v2`),
whereas the architecture separates identity from version and otherwise preserves
a declared version label verbatim (`data-architecture-strategy.md`;
`physical-data-model-review.md` N-04). None carries an owned Scenario and none has
a canonical `.feature` lineage. This is a mis-modeling correction, not a draft
exemption: the excluded rows were never managed or provisional capabilities.

Fresh read-only evidence from selected model 34:

| Measure | Verified value |
| --- | ---: |
| `sidefx:platform-capabilities` identities | 70 |
| `sidefx:platform-capabilities` versions | 85 |
| Identities / versions ending `.v1` | 68 / 83 |
| Identities / versions ending `.v2` | 2 / 2 |
| Owned scenarios | 0 |
| Identities with canonical `.feature` lineage | 0 |
| Defining source | `sda-bootstrap@952de6bfa690fe85d85ca36261f22a1cb63c85eb/platform/kernel/semantic-authority/consumer/sda-platform-capabilities.semantic-authority.json` |

Disposition: exclude the entire `sidefx:platform-capabilities` namespace from the
canonical-feature inventory and completeness gate. Remove or reclassify these
rows through the platform mapping so provider/port/mechanic dependencies are not
stored as managed capability identities; do not demand canonical features for
them, and do not count them toward migration coverage. The gate is scoped to
`sidefx:capabilities`, so these rows can neither satisfy nor fail it.

### 2.2 Corrections to the original gap accounting

In the **current** model, Scenario identity is Capability-owned; the target model
re-parents it to the feature (§4). The repeated scenario ID strings below are
still valid distinct identities because they belong to different owners. Three
repeated scenario ID strings occur under different Capability owners. Ten more
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
1,031 scenarios and do not establish coverage of all managed database identities
(220 in `sidefx:capabilities`). Group A means absent from the current selection,
not necessarily absent from all database history.

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

## 3. Root cause

**The schema had no canonical feature entity.** That is the defect, and it
produced every downstream symptom.

The feature existed in three disconnected forms, none of which was an authority:

| Where the feature lived | Form | Consequence |
| --- | --- | --- |
| Managed ingestion (`normalize.mjs`) | Opaque digest in capability `contributions`, plus a partial `scenario_members` fragment | No readable feature declaration; the writeup is not addressable |
| Managed scenario projection | `semantics.scenario` on `model.scenario_version` | Authored behavior survives, but nothing declares which feature owns the scenario set |
| Provisional registration (`register/capability.mjs`) | A face list (`spec.scenarios`); the packed `.feature` was never parsed | The writeup was silently dropped |

Three further effects follow directly:

- **Two projectors, two behaviors.** Managed ingestion parsed features; provisional
  registration did not. Nothing forced them to agree because there was no shared
  declaration to agree on.
- **No binding.** Nothing related a capability version to one exact feature
  version, so no gate could require one.
- **A re-registration collision.** Because scenario content lived in the
  capability envelope only on the managed lane, a changed provisioned feature
  reused the same capability version and collided on
  `model.capability_scenario` (`(capability_version_pk, scenario_pk)`).

The evidence is decisive about the size of the data defect: **219 of 220 selected
capabilities already carry an authored scenario specification. Exactly one does
not.** The problem is not missing bytes in 220 features; it is a missing entity
in the schema.

### 3.1 The equity example

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

The migration must bind the feature, contracts and execution authorities
belonging to the same invocable revision. Fully normalizing the registered
one-scenario feature repairs specification loss for that revision. Making the
four-scenario Harness feature canonical for the current capability is a semantic
revision: its support authorities and applicable proof must agree. The migration
records the choice explicitly and never produces a hybrid from both.

## 4. Target model: the feature is the authority

The feature is a versioned, content-addressed semantic object, exactly like
Capability, Scenario and Contract. Scenario identity is re-parented to the
feature. A capability reaches a scenario **only** through the feature version it
binds.

```
FEATURE                                             stable identity
  feature_pk PK, namespace_pk FK, feature_id ID
  capability_pk FK?                                 declared owner (@capability)
  semantic_object_pk FK
  UK(namespace_pk, feature_id)
        | 1:n
FEATURE_VERSION                                     content-addressed definition
  feature_version_pk PK, feature_pk FK
  semantic_object_definition_pk FK
  capability_pk FK?                                 carried owner (see §6)
  definition_digest D
  semantics = { content_digest, source_class, source_path }   retained-source manifest;
                                                  the narrative is read from the bound bytes
  AK(feature_pk, definition_digest)
        | 1:n  the feature DECLARES its scenario set
FEATURE_SCENARIO
  feature_version_pk FK, scenario_pk FK
  scenario_version_pk FK, ordinal N
  PK(feature_version_pk, scenario_pk)
        |
        +--> SCENARIO                               identity now FEATURE-owned
        |      scenario_pk PK, feature_pk FK, scenario_id
        |      UK(feature_pk, scenario_id)
        |          | 1:n
        |      SCENARIO_VERSION                     content-addressed definition
        |          scenario_version_pk PK, scenario_pk FK
        |          semantic_object_definition_pk FK
        |          semantics = { keyword, name, description, steps, tags, examples }
        |
CAPABILITY                                          stable identity
  capability_pk PK, namespace_pk FK, capability_id, semantic_object_pk FK
        | 1:n
CAPABILITY_VERSION                                  content-addressed definition
  capability_version_pk PK, capability_pk FK
  semantic_object_definition_pk FK
  semantics = { authority, canonical_feature: { featureId, featureVersionDigest } }
  AK(capability_pk, definition_digest)
        |
        | exactly one CANONICAL binding
        v
CAPABILITY_FEATURE                                  version-owned, append-only
  capability_version_pk FK, feature_version_pk FK, capability_pk FK
  binding_role CODE                                 'CANONICAL' | 'ALTERNATE'
  UK(capability_version_pk) WHERE binding_role = 'CANONICAL'
```

Authority chain: **capability version -> feature version -> feature scenario ->
scenario version -> authored AST.** One path, no second owner.

`capability_root_scenario` remains the only capability-side scenario selection.
During the expand/contract migration `model.capability_scenario` stays a base
table, constrained so its owner agrees with the feature's (§6.1). At the contract
stage it is replaced by a derived view over the binding (`CAPABILITY_FEATURE`
joined to `FEATURE_SCENARIO`), never an independent claim. The capability
envelope no longer embeds scenario content; it carries only the canonical feature
version digest as a reference.

### 4.1 Canonical feature contract

1. **One canonical binding.** Every invocation-addressable capability version
   has exactly one `CANONICAL` `CAPABILITY_FEATURE` row, and the envelope's
   `canonical_feature.featureVersionDigest` equals the bound
   `FEATURE_VERSION.definition_digest`.
2. **Feature-declared scenario set.** The capability's scenarios are the bound
   feature version's `FEATURE_SCENARIO` set. The root is declared, belongs to
   that set, and is unique.
3. **Full authored meaning.** The feature narrative and every scenario
   specification, tag and Gherkin context survive projection. Face-only
   definitions do not satisfy the contract.
4. **Coherent references.** Inputs, events, outcomes, contracts and execution
   references resolve against the same revision and pinned shared dependencies.
5. **Traceable revision.** `FEATURE_VERSION` traces through `source_lineage` to
   the exact `.feature` appearance with a matching `content_digest`. A digest at
   a path is not authority selection.

### 4.2 Source selection and authority

Produce a frozen reconciliation manifest for every capability identity and
version. It includes namespace/owner, current definition digest, applicable
managed/provisional lineage, exact feature digest and appearances, supporting
authority digests, root/scenario set, discrepancies, and resolution evidence.

Use the revision's applicable registration, capsule, placement or admission
records to establish its source set. Both managed and provisional sources can
supply a canonical feature. Neither class automatically overrides the other. A
newer timestamp, larger file, path spelling, or scenario count never selects
authority. Unverifiable placement evidence leaves a reconciliation item open.

| Finding | Required resolution |
| --- | --- |
| Exact feature already matches the revision | Bind it and verify full normalized fidelity |
| Matching feature retained, mapping incomplete | Re-project the full feature and affected dependencies |
| Multiple conflicting feature revisions | Select the exact coherent revision with source evidence; retain alternatives as `ALTERNATE` bindings |
| Feature absent or missing canonical IDs | Recover the correct source or author/reconcile it through the capability's applicable change path; do not derive authority from an incomplete model |
| Model has scenarios absent from a compared file | Locate the feature that actually supplied that version, or reconcile the writeup; never delete scenarios solely to match a shorter file |

Missing canonical features are migration defects to resolve. They are not
permanent exceptions, a reason to remove a capability from inventory, or a reason
to relabel an invocable provisional capability as a draft.

## 5. One projection core for managed and provisional capabilities

`sidefx-database` owns one deterministic feature-to-semantic projection core.
Managed ingestion, provisional registration and revision operations all use it.
Their source-selection and lifecycle evidence may differ; their canonical feature
contract does not. `sfx-embody` consumes and verifies the resulting definitions.

Registration must parse the exact retained feature bytes. `spec.scenarios` must
cease being an independently maintained source of semantic truth; during the
transition it may only be a derived value or an equality assertion against the
parsed feature.

| Declaration | Normalized destination |
| --- | --- |
| `@capability` | Capability identity in its explicit namespace, and the feature's declared owner |
| Feature narrative and tags | Bound retained `.feature` bytes; `model.feature_version` records a manifest (`content_digest`, `source_class`, `source_path`), and `model.feature_scenario` pins the authored scenario versions |
| `@scenario`, name and full specification | `model.scenario` / `model.scenario_version` (feature-owned), pinned by `model.feature_scenario` |
| `@root-scenario` | `model.capability_root_scenario`; must belong to the bound feature version's scenario set |
| `@input` / `@input-contract` | `model.scenario_input` and exact contract-version reference/state |
| `@event` / `@event-authority` | `model.scenario_event` and exact execution-authority reference/state |
| `@outcome` / `@outcome-contract` | `model.scenario_outcome` and `model.scenario_outcome_contract` |
| `@outcome-terminal` / `@terminal-disposition` | Explicit terminality and disposition; no disposition inferred from prose |
| Other tags | Preserve verbatim and classify unsupported semantic mappings; never silently discard them |

Identity is `(namespace, feature ID)` for the feature and `(feature, scenario
ID)` for the scenario. A capability reaches a scenario only through its bound
feature version. Do not introduce filename-derived IDs or a global Scenario
identity. Duplicate singleton tags, conflicting roots, and duplicate scenario
declarations within one selected revision fail canonical-feature validation.
Repeated source copies add lineage, not scenario rows. Untagged blocks remain
visible findings until authored canonical IDs resolve them.

Use the existing Gherkin parser. The mapping must preserve Rule and Background
context, Scenario Outlines, Examples, tables, doc strings, inherited tags and
ordered steps. An Outline remains one declared Scenario, not one identity per
example row. `And`/`But` inherit the preceding step kind when deriving face prose;
retaining only direct Given/When/Then keyword matches is incomplete. Unsupported
structures produce findings instead of being silently flattened.

Missing references preserve exact declared text and `ABSENT` versus `UNRESOLVED`.
Do not fabricate Contract, execution authority, Product or Blueprint entities.
General Feature prose remains narrative; structured user stories, experiences and
observable conditions retain their own authority.

Semantic digests cover normalized semantic fragments and exact semantic
references. Raw-byte/capsule digests, paths, timestamps and parser locations are
provenance. Keep raw bytes for reconstruction. Packaging changes alone must not
change semantic identity.

## 6. Schema migration: expand, backfill, prove, contract

The schema is generated code. Reaching the target model is a versioned schema
migration plus a backfill generation, not an in-place edit. Use expand/contract
so readers never break and the new parent is DB-enforced before the redundant
column is removed.

### 6.1 Expand

Add the new tables and the new parents. Nothing is removed yet.

- `model.feature`, `model.feature_version`, `model.feature_scenario`,
  `model.capability_feature`.
- `model.scenario.feature_pk` (nullable at first) and `model.scenario.capability_pk`
  (retained).
- `model.feature_version.capability_pk` and `model.feature.capability_pk`, carried
  so the owner can be enforced by composite foreign keys.

The retained `scenario.capability_pk` is a **provably redundant copy** of the
feature's owner. Make disagreement impossible with composite keys:

```sql
-- the feature's owner is the anchor
CREATE UNIQUE INDEX ux_feature_pk_capability
  ON model.feature(feature_pk, capability_pk);
ALTER TABLE model.scenario ADD CONSTRAINT fk_scenario_feature_owner
  FOREIGN KEY (feature_pk, capability_pk)
  REFERENCES model.feature(feature_pk, capability_pk);

-- a capability version can only bind a feature version of its own capability
ALTER TABLE model.capability_version
  ADD CONSTRAINT ux_cv_pk_capability UNIQUE (capability_version_pk, capability_pk);
ALTER TABLE model.feature_version
  ADD CONSTRAINT ux_fv_pk_capability UNIQUE (feature_version_pk, capability_pk);
ALTER TABLE model.capability_feature ADD CONSTRAINT fk_cf_cv
  FOREIGN KEY (capability_version_pk, capability_pk)
  REFERENCES model.capability_version(capability_version_pk, capability_pk);
ALTER TABLE model.capability_feature ADD CONSTRAINT fk_cf_fv
  FOREIGN KEY (feature_version_pk, capability_pk)
  REFERENCES model.feature_version(feature_version_pk, capability_pk);
```

Follow the same pattern between `feature_scenario` and `scenario`, and between
the retained `capability_scenario` and `scenario`, so every path pins the same
owner. Every path then resolves to the same `capability_pk`:

```text
capability_version ──(capability_pk)──► capability_feature ──(capability_pk)──► feature_version
                                                                                     |
                                                                          feature_scenario
                                                                                     |
                                                                                     v
capability_scenario ──(capability_pk)───────────────────────────────► scenario(feature_pk, capability_pk)
```

### 6.2 Backfill

The applied SQL is one file,
[`sidefx-database/sql/migrations/007-canonical-feature.sql`](C:/lab/sidefx-database/sql/migrations/007-canonical-feature.sql):

- **schema** — the additive expand DDL above;
- **load** — set-based; resolves one retained feature appearance per selected
  capability (scenario lineage first, then the `features/<capability_id>.feature`
  path convention), writes `feature`, `feature_version`, `feature_scenario`, and
  the `CANONICAL` binding;
- **verification** — counts, gaps, gate violations, and a binding sample.

The whole file runs in **one transaction** and ends in `ROLLBACK TRANSACTION;`
with `COMMIT TRANSACTION;` commented out. Apply it by switching those two lines
only after the verification selects are clean. It keeps the narrative in the
bound bytes and does not re-parse Gherkin. An optional `#override` table lets the
operator pin the canonical appearance for a capability whose revision is
contested (for example the equity feature).

The authored scenario content already lives in `model.scenario_version`; the load
pins those exact versions through `feature_scenario`. Where a capability's
feature declares a scenario the model has not normalized, the load reports a gap
rather than fabricating a version. Because existing rows are immutable, adding a
`scenario.feature_pk` column and backfilling it is not part of this migration;
the owner is enforced through `feature_scenario` and its composite keys instead
(§6.1). The actual re-parent happens at contract.

### 6.3 Prove

The composite keys in §6.1 make cross-owner rows impossible. The adversarial
cases use the same `reject(...)` idiom as `prove.mjs`:

```js
reject('a feature version cannot belong to another capability',
  row('feature_version', { feature_pk: fA, capability_pk: capB }), /547/);
reject('a capability version cannot bind another capability\'s feature version',
  row('capability_feature',
    { capability_version_pk: cvA, feature_version_pk: fvB, capability_pk: capA }), /547/);
reject('a feature version cannot declare another capability\'s scenario',
  row('feature_scenario', { capability_pk: capA, scenario_pk: scB }), /547/);
```

Green on those proves the new parent is enforced at the database, not by convention.

### 6.4 Gate

`007` installs `source.validate_canonical_features`, scoped to
`sidefx:capabilities`, with:

- `G_CAPABILITY_CANONICAL_FEATURE` — every selected managed capability version
  has exactly one `CANONICAL` binding.
- `G_FEATURE_SCENARIO_OWNER` — every `feature_scenario` row's scenario belongs to
  the same capability as the feature version.
- `G_FEATURE_VERSION_OWNER` — every bound feature version belongs to the same
  capability as the binding.

`008` reports the remaining gaps (selected capabilities with no resolved feature)
without failing the load. These gates require the parser and are therefore
pending until the projection is projected through one core:

- `G_FEATURE_VERSION_PIN` — the capability envelope's canonical feature digest.
- `G_ROOT_IN_FEATURE` — the root belongs to the bound feature version's set.
- `G_FEATURE_BYTES_BOUND` — the feature version traces to matching bytes.
- `G_FEATURE_TAG_OWNER` — exactly one `@capability`, resolving to the capability.
- `G_SCENARIO_AUTHORED` — the selected scenario version carries authored steps.

`007` also adds `sidefx.v_capability_feature` and
`sidefx.v_capability_feature_scenarios` so readers resolve the feature without
scanning history.

### 6.5 Contract

The target puts `feature_pk` on the scenario identity and drops
`scenario.capability_pk`. That is a new-generation operation: existing `scenario`
rows are immutable and cannot be updated, so the re-parent happens when the
scenarios are re-minted. Until then the owner is enforced through
`feature_scenario` and `capability_feature` (§6.1), and `capability_scenario`
stays a base table. This migration does not perform the contract step.

### 6.6 Consequences

- Binding or revising a feature is an append to `capability_feature` /
  `feature_scenario`. It does not rebuild 220 capability memberships. Once the
  capability envelope carries the canonical feature digest (§6.4), a feature
  change also mints a new `capability_version`.
- Published historical definitions are never rewritten. Where the migration only
  establishes an evidenced feature association for an old version, use the
  append-only binding. Where authored semantics change, mint a new version and
  record supersession.
- New schema work is additive and versioned. Do not edit the installed
  migration-001 digest, disable guards, or rebuild by dropping retained history.
- Database `PUBLISHED` state does not confer Harness managed admission on a
  provisional capability.

## 7. Migration sequence

| Stage | Work | Exit evidence |
| --- | --- | --- |
| 1. Expand | Add `feature`, `feature_version`, `feature_scenario`, `capability_feature`, and the nullable parent columns | New tables exist; existing readers unaffected |
| 2. Inventory | Reconcile all 220 managed identities / 228 managed versions (the 70 non-managed platform rows of §2.1 are excluded) | No managed identity omitted; each discrepancy has a resolution path |
| 3. Project | Run one projection core over the retained features into the new tables | Feature narrative and authored scenario specifications are complete and addressable |
| 4. Backfill and prove | Set `scenario.feature_pk`, verify owners, add the composite keys and gates, run the adversarial proof cases | Every path pins one owner; redundant column proven safe |
| 5. Cut over atomically | Build the backfill generation, validate and select under the writer lock | Old/new generation receipt; stale publisher rejected |
| 6. Enforce continuously | Require the canonical binding on every registration and revision | Feature/model drift cannot be introduced by a separate path |
| 7. Contract | Drop `scenario.capability_pk` and its composite keys | Redundancy removed; feature is the only authority |

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
existing selected model in service while the complete replacement is built; do
not drop capabilities or intentionally break invocation to make a coverage
percentage pass. Unresolved canonical-feature defects keep the migration
incomplete.

Derive the complete candidate before loading. Follow foreign-key dependencies:
source/observations, reusable definitions, feature/version and scenario
membership, capability versions and binding, execution authorities and
operations, faces/bindings, lineage and coverage, then publication. Plan exact
references before inserting immutable rows.

Recompute the affected dependency closure, including invocations, contracts,
fixtures, observable conditions, blueprint pins and preparation identities.
Carry unaffected definitions and evidence. Changed definitions do not inherit
old proof or assessments as though they had been revalidated.

Selected meaning and execution queries must follow exact version FKs and owner
scope. Joining on scenario ID text alone or unioning all retained
execution-authority versions cannot define the canonical circuit of the selected
capability revision.

## 8. Idempotency, cutover and rollback

The migration run key binds the predecessor generation, frozen source-selection
manifest, mapping rule and parser/projector implementation digests. Repeating the
same plan reuses immutable content/definitions and verifies committed row
contents. Different sources, mappings or predecessor create a different plan.
Counts alone are insufficient retry evidence.

Failed loads leave the selected model untouched. Earlier table commits may remain
for diagnosis and resume; final validation failure does not undo them.
Checkpoints must belong to the exact plan.

The existing `source.publish_model` takes a writer lock and validates before
selection, but has no expected-predecessor argument. Add a database-enforced
compare-and-select check in the same transaction so a candidate built against an
old generation cannot replace a newer registration.

Prove an owner-executed rollback operation before cutover. It reselects the
previous published generation under the writer lock, checks the expected current
generation, validates compatibility and retains a selection receipt. This is a
required extension: `source.publish_model` expects a BUILDING generation and is
not a general rollback selector.

Retain the previous generation and compatible reader/schema behavior throughout
the rollback window. Rollback restores database selection, preserves
source/history, and causes subsequent invocations to resolve the restored exact
revision; it does not undo effects already executed.

## 9. Acceptance evidence

The migration is complete when:

- Every managed or provisional capability identity in `sidefx:capabilities` is
  accounted for, and every invocation-addressable version has exactly one
  canonical feature binding. The 70 non-managed platform-catalog rows are
  excluded as non-capabilities (§2.1).
- Every `FEATURE_VERSION` declares its scenario set, and each capability's
  scenario set is exactly the bound feature version's set. The root belongs to
  that set. Full prose, tags and Gherkin context survive projection.
- Feature and scenario identity are feature-scoped and stable; repeated scenario
  ID strings under different features stay distinct; conflicting revisions are
  retained as `ALTERNATE` bindings and never merged. The redundant
  `scenario.capability_pk` is proven consistent and then removed.
- Both registration and ingestion use the shared core. Repeat runs create no
  duplicate semantic rows; semantic changes mint new versions; published
  definitions remain immutable.
- SQL key, ownership, lineage, canonical-feature and constraint-trust gates pass.
  Relevant meaning, resolver, invocation and retained-fixture checks pass for
  changed definitions and their affected dependencies.
- Adversarial checks reject publication without a canonical feature, extra or
  missing scenarios, contradictory roots, cross-owner bindings, stale
  source/predecessor, and direct-SQL bypass. Readers observe one coherent
  generation during cutover and rollback.

The next implementation deliverable is the generator changes
(`catalog.mjs` / `schema.mjs` / `views.mjs`) for the expand stage, followed by
the version-by-version reconciliation manifest. Source repairs follow the
applicable managed or provisional change path; no policy decision about whether
provisional capabilities qualify for canonical features remains open.

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
canonical-feature coverage for all 228 managed versions or resolve source
conflicts. The 85 non-managed platform-catalog versions are out of scope (§2.1).
