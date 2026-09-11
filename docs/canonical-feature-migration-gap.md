# Canonical feature writeups: what the database holds, and what it does not

Prepared for architecture review. This document records what was measured, how,
and what remains open. It proposes no migration and changes nothing. Every count
below was read from the selected estate snapshot
`sha256:1a770ac0795d10665a88166f8d8c968dc5b2d030fdfab2b837aa6071d135f9e9` and
from `C:\lab\repos\agentic-harness\features` on 2026-09-11.

## The short version

The canonical feature writeups **are** in the database. All 235 files are
retained, byte for byte, with matching SHA-256 content digests and no drift.

What is missing is not the content. It is the **normalization of that content
into the semantic model**. The feature corpus declares 1,041 scenarios; the
model carries 825. Thirty-nine capabilities have their canonical feature retained
as bytes but no `model.capability` row at all.

So the question for the team is not "how do we get the features in". It is
"what projects retained feature bytes into `model.capability`,
`model.capability_scenario` and the `SCENARIO` semantic definitions, when should
it run, and what is authoritative when the two disagree".

## How this was measured

| Side | Source |
| --- | --- |
| Canonical corpus | every `*.feature` in `C:\lab\repos\agentic-harness\features`, parsed for `@capability:`, `@root-scenario:`, `@scenario:` and `Scenario:` blocks |
| Retained content | `source.source_appearance` joined to `source.content_object`, filtered to `source_path LIKE '%.feature'`, scoped to the selected estate model |
| Semantic model | `model.capability`, `model.capability_scenario`, `model.scenario` |
| Authored specification | `analysis.v_selected_semantic_definition` where `object_kind='SCENARIO'`, testing `$.semantics.scenario.steps` |

Content comparison was a digest match: each file on disk was hashed and looked
for among the digests the snapshot retains at that `source_path`.

## Finding 1 — the feature bytes are already retained, and they are current

| Canonical feature files on disk | 235 |
| --- | --- |
| Retained in the snapshot with **matching** bytes | **235** |
| Retained but bytes differ from the canonical file | 0 |
| Not retained at all | 0 |

Estate-wide the snapshot retains 390 distinct `.feature` paths: 236 under
`features/`, 24 under `authority/sidefx-semantic-brain/`, and 130 elsewhere. They
arrive by more than one route — `REPOSITORY_TRACKED` for the tracked file, and
`MANAGED_CAPSULE` / `PROVISIONED_CAPSULE` for the same feature carried inside a
capsule as the entry `features/{id}.feature`.

This matters: a migration does not need to go and fetch the writeups. The bytes
are addressable in the database today.

## Finding 2 — the corpus declares more than the model carries

| Measure | Canonical corpus | Semantic model |
| --- | --- | --- |
| Capabilities | 234 declared `@capability` ids across 235 files | 220 in `model.capability` |
| Scenarios | 1,041 `@scenario` tags (1,028 globally distinct ids) | 825 in `model.capability_scenario` |
| `Scenario:` blocks | 1,053 | — |

Two corpus details worth noting before any reconciliation:

- **12 `Scenario:` blocks carry no `@scenario:` tag.** 1,053 blocks against 1,041
  tags. Whatever projects features has to decide whether an untagged block is a
  scenario.
- **13 scenario ids appear in more than one file** (1,041 per-file distinct
  against 1,028 globally distinct), and `observe-governed-http-exchange` is
  declared by two files, `observe-governed-http-exchange.feature` and
  `observe-governed-http-exchange-v2-candidate.feature`.
- **`manage-capsule-estate.feature` carries no `@capability:` tag**, and
  `manage-capsule-estate` is the one capability in the model with no
  `capability_scenario` row at all. These are consistent with each other.

## Finding 3 — the gap sorts into four distinct groups

### A. 39 canonical features with no capability in the model — 241 declared scenarios

Their writeups are retained as bytes; nothing was projected.

```
 1 admit-fixture-driven-conformance-corpus      8 observe-authoring-execution
 1 admit-language-kernel-embodiment             2 observe-authoring-expression-nodes
16 author-canonical-scenario                    8 observe-frozen-remote-api-source-bundle
 8 author-canonical-scenario-set               12 observe-remote-api-operation-exchange
22 author-capability                            1 operate-authoring-convergence-session
 1 compile-rapidapi-provider-candidates         9 preserve-provider-candidate-completeness-disposition
 9 compile-remote-api-operation-descriptor     15 project-capability-capsule
 7 converge-projectable-capability-candidate    2 project-language-mechanic-registry
 1 decide-equity-market-price-provider-route    2 project-native-presentation-shell
 5 deliver-capability-token-provisioning-cli   12 project-remote-api-operation-request
 7 enumerate-governed-repository-resources      6 project-sidefx-product-position-report
 2 evaluate-bounded-schema                      4 prove-projected-cli-outcome-equivalence
 4 evaluate-equity-market-price-provider-repl…  9 provision-capability-token
14 evaluate-required-execution-closure          7 qualify-design-mechanic-feasibility
 2 execute-authority-transformation            11 qualify-provider-slot-geometry
 1 execute-composed-scenario-authority          9 resolve-provisioned-feature-authority
 0 manage-capsule-estate                        5 resolve-scenario-visual-experience
 1 measure-authoring-fidelity                  11 reveal
 1 normalize-console-input                      1 search-estate-entities
                                                4 select-equity-market-price-provider
```

This group is dominated by authoring, provisioning and remote-API capabilities.
Whether they *should* be in the estate model is a governance question, not a
technical one — several look like authoring-time capabilities rather than
admitted estate capabilities. **The team should decide the intended membership
rule before anything projects them.**

### B. 24 model capabilities with no canonical feature in this corpus — 40 scenarios

Every one is a `*-sidefx-*` capability, and the snapshot shows why: their
writeups live at
`authority/sidefx-semantic-brain/capabilities/<id>/capability.feature` and are
carried in capsules as `features/{id}.feature.sidefx`. They are a **second
authoring lineage**, not a gap in the first.

```
analyze-sidefx-semantic-gaps            evaluate-sidefx-proof-binding (8)
analyze-sidefx-semantic-impact          evaluate-sidefx-verification-coverage
assemble-sidefx-capability-authoring-context   ground-sidefx-semantic-query-results
bind-sidefx-semantic-query-receipt      ingest-sidefx-json-authority (6)
classify-sidefx-semantic-corpus-sources project-sidefx-semantic-identity-index
construct-sidefx-evaluation-corpus-snapshot    project-sidefx-semantic-lexical-index
construct-sidefx-evaluation-object-catalog     resolve-sidefx-capability-precedents
construct-sidefx-evaluation-relationship-graph resolve-sidefx-eligible-providers
construct-sidefx-semantic-query-plan    resolve-sidefx-semantic-knowledge-request
determine-sidefx-capability-authoring-disposition  resolve-sidefx-semantic-pattern-candidates
determine-sidefx-evaluation-corpus-closure     retrieve-sidefx-semantic-candidates
                                        trace-sidefx-scenario-lineage
                                        verify-sidefx-durable-store-admission (5)
```

Any migration has to state whether these two lineages converge on one canonical
location or stay separate with one projector each.

### C. 2 shared capabilities whose feature declares scenarios the model does not carry — 15 scenarios

| Capability | Feature | Model | Declared but absent from the model |
| --- | --- | --- | --- |
| `author-canonical-feature` | 13 | 1 | `resolve-feature-meaning`, `hold-incomplete-feature-intent`, `resolve-feature-scenario-responsibilities`, `reject-invalid-scenario-responsibility-set`, `author-canonical-scenario-set`, `compose-canonical-feature-candidate`, `conform-canonical-feature-candidate`, `review-canonical-feature-candidate`, `resolve-canonical-feature-disposition`, `repair-canonical-feature-candidate`, `hold-canonical-feature-candidate`, `admit-canonical-feature` |
| `resolve-equity-market-price-evidence` | 4 | 1 | `retain-provider-realization-outside-market-price-semantics`, `hold-unavailable-equity-market-price-provider`, `reject-nonconforming-native-market-price-testimony` |

This is the group that surfaces as a contradiction inside the estate rather than
as a silent absence — see *Where this shows up* below.

### D. 3 shared capabilities where the model carries scenarios the feature does not declare — 10 scenarios

| Capability | Feature | Model | In the model only |
| --- | --- | --- | --- |
| `operate-tooling-migration-promote` | 1 | 7 | `project-and-observe-tooling-candidate`, `prove-tooling-candidate-oracle-equivalence`, `resolve-tooling-candidate-verification`, `resolve-tooling-migration-promote-operation`, `transact-tooling-provider-promotion`, `verify-tooling-candidate-authoring-lineage` |
| `operate-tooling-migration-verify` | 1 | 6 | `project-and-observe-tooling-candidate`, `prove-tooling-candidate-oracle-equivalence`, `resolve-tooling-candidate-verification`, `resolve-tooling-migration-verify-operation`, `verify-tooling-candidate-authoring-lineage` |
| `operate-tooling-migration-run` | 1 | 3 | `execute-serial-tooling-migration-run`, `resolve-tooling-migration-run-operation` |

The model is **ahead** of the canonical writeup here. A migration that treats the
feature corpus as the source of truth would delete these unless the rule says
otherwise. That makes direction-of-authority an explicit decision, not a default.

## Finding 4 — the authored specification carries meaning the model does not

824 of the model's 825 scenarios do carry authored Gherkin steps; only
`resolve-equity-market-price-evidence` carries a definition with no steps. So the
authored *prose* is largely present.

What the feature writeup carries that the model does not consistently retain is
the **tag block** above each scenario. A single scenario in
`resolve-equity-market-price-evidence.feature` declares:

```gherkin
  @scenario:retain-provider-realization-outside-market-price-semantics
  @input:equity-market-price-evidence
  @input-contract:equity-market-price-evidence.v1
  @event:equity-market-price-provider-testimony-observed
  @event-authority:retain-equity-market-price-provider-testimony.v1
  @outcome:equity-market-price-evidence
  @outcome-contract:equity-market-price-evidence.v1
  @outcome-terminal
  Scenario: Bind supplier testimony without changing the canonical finance promise
```

That is the scenario's identity, its input and input contract, its event and
event authority, its outcome and outcome contract, and its terminality — which is
most of what a circuit needs. Whatever projects features should be explicit about
which of these tags become model rows and which stay as retained text.

The `Feature:` narrative paragraph — the prose above the scenarios explaining what
the capability promises and what stays outside its semantic identity — has no
obvious home in the model today. `resolve-equity-market-price-evidence` also
declares no `userStory` and no `experience` in its `CAPABILITY` definition, while
216 of 220 capabilities do. Whether the `Feature:` narrative should populate those
is worth deciding deliberately.

## Where this shows up

`sfx capability reveal resolve-equity-market-price-evidence --as meaning --format markdown`
reports three observations that are all this one gap seen from inside the estate:

- `SCENARIO_INVOCATION_UNRESOLVED` ×3 — the execution authority declares
  `invoke-scenario` against `retain-provider-realization-outside-market-price-semantics`,
  `hold-unavailable-equity-market-price-provider` and
  `reject-nonconforming-native-market-price-testimony`. The model does not resolve
  any of them into the closure. **Those are exactly the three scenarios group C
  says the feature declares and the model does not carry.** The execution
  authority and the scenario model disagree, and the feature corpus shows which
  side is complete.
- `SCENARIO_SPECIFICATION_ABSENT` — the one scenario the model does carry declares
  a face (`event` / `input` / `outcome`) with no authored steps, while the feature
  file declares a full `Scenario:` with Given/When/Then.
- `USER_STORY_ABSENT`, `EXPERIENCE_ABSENT`, `OBSERVABLE_CONDITIONS_ABSENT`.

The capability also has no `BLUEPRINT` candidate, so there is nothing to compare
its circuit against. 35 of 220 capabilities have one.

## Things this document does not establish

- **Why** the projection stopped at 825 scenarios. Nothing was found that records
  a deliberate membership rule; absence of evidence is not evidence of absence,
  and someone closer to the ingestion path should confirm.
- **Whether group A should be in the estate model at all.** Several are
  authoring-time capabilities.
- **Which side is authoritative** where the corpus and the model disagree
  (groups C and D disagree in opposite directions).
- **The status of `provisioning/` capsules.** The capsule for
  `resolve-equity-market-price-evidence` carries a `features/{id}.feature` entry,
  and the snapshot retains three different byte lengths for that path
  (3,680 / 1,426 / 1,421). The 3,680-byte copy matches the canonical file today.
  It was reported during this review that that capsule is stale, so capsule
  contents should not be treated as current authority without checking placement
  receipts.

## What the team needs to decide

1. **Membership.** What makes a canonical feature an estate capability? Until
   that rule exists, group A cannot be projected safely.
2. **Direction of authority.** When the corpus and the model disagree, which
   wins — and is the answer the same for group C (model behind) and group D
   (model ahead)?
3. **One projector or two?** `features/` and
   `authority/sidefx-semantic-brain/.../capability.feature` are two lineages with
   different layouts.
4. **Tag mapping.** Which of `@input`, `@input-contract`, `@event`,
   `@event-authority`, `@outcome`, `@outcome-contract`, `@outcome-terminal`
   become model rows, and what happens when a tag names a contract the estate
   does not retain.
5. **Untagged blocks and duplicate ids.** 12 blocks carry no `@scenario:` tag; 13
   scenario ids appear in more than one file; one capability is declared by two
   files.
6. **The `Feature:` narrative.** Does it become `userStory` / `experience`, stay
   retained text, or both.
7. **Re-projection trigger.** Whether projection runs on ingestion, on
   registration, or as an explicit operation — and how a re-run reconciles rather
   than duplicates, given that 275 declared ids already carry more than one
   retained definition.

## Reproducing these numbers

```powershell
# corpus side
Get-ChildItem C:\lab\repos\agentic-harness\features\*.feature | Measure-Object
Select-String -Path C:\lab\repos\agentic-harness\features\*.feature -Pattern '@scenario:' | Measure-Object

# model side
sfx capability list --json          # 220 capabilities in the selected estate
```

```sql
-- scenarios the model carries
SELECT COUNT(*) FROM model.capability_scenario cs
JOIN model.estate_capability ec ON ec.capability_version_pk = cs.capability_version_pk
JOIN source.current_model cm ON cm.estate_model_pk = ec.estate_model_pk;

-- feature bytes the snapshot retains
SELECT a.source_class, COUNT(DISTINCT a.source_path)
FROM source.source_appearance a
JOIN source.estate_model m ON m.estate_snapshot_pk = a.estate_snapshot_pk
JOIN source.current_model cm ON cm.estate_model_pk = m.estate_model_pk
WHERE a.source_path LIKE '%.feature'
GROUP BY a.source_class;
```
