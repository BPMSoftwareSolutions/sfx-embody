# SideFX ML opportunity

**Independent research lane · 9 September 2026 · Proposal, not an implemented ML platform**

**Models provide intelligence; capabilities own meaning.**

The opportunity is real: SideFX can make model inference, evaluation, replacement, and eventually training explicit parts of a capability architecture. A model supplies a result under declared obligations. The capability defines what that result means, how it is evaluated, what may be accepted, and what experience follows.

The existing estate provides relevant foundations for governed model invocation, provider binding, testimony, switching, and conformance. It does not yet establish a general ML feature compiler, a training platform, a validated evaluation corpus, or successful model interchangeability. Those are the work of this lane.

This assessment responds to the [team's ML review](team-review.txt), preserves its central proposition, and distinguishes observed declarations from proposed architecture and product hypotheses. No model was invoked or trained for this assessment; no ML benchmark, admission, or deployment is claimed.

## 1. Lane charter and relationship to experience projection

The ML lane owns the proposed path from a declared learning or inference responsibility to attributable model evidence and evaluated capability outcomes. Its first deliverables are responsibility profiles, feature and inference plans, evaluation specifications, and a bounded proof. Training and learning over the Capability Data Center follow after that foundation.

The [scenario experience lane](../scenario-experiences/opportunity.md) owns the proposed path from contracts and presentation authority to input forms and output experiences. Both lanes use identified contracts, explicit semantics, and evidence. They have separate implementation and acceptance paths.

| Boundary | ML lane supplies | Experience lane consumes or supplies |
| --- | --- | --- |
| Input | Required data, supported modalities, quality constraints, sensitive-data boundaries | Controls that collect values conforming to the input contract |
| Result | A typed prediction, evaluated result, abstention, hold, or failure with declared meaning | A presentation for each declared outcome and its next actions |
| Uncertainty | Score type, calibration provenance where available, reasons, limitations, review requirements | Honest labels and explanations; an uncalibrated score must not become a “probability of correctness” badge |
| Correction | A correction record with provenance and its permitted downstream use | A review interaction that can capture the correction |
| Evidence | Execution and evaluation references scoped for the consuming audience | Appropriate evidence disclosure without exposing credentials or restricted source material |

Inference can be exercised through an API or CLI before a generated form exists. Deterministic form generation can proceed without an ML dependency. Optional AI assistance may propose feature or presentation metadata, but durable metadata needs explicit validation and acceptance under the applicable authority.

## 2. Assessment of the team's claims

| Review proposition | Assessment | Qualification required in planning |
| --- | --- | --- |
| A model can provide a governed capability responsibility | Supported architectural direction with existing model-related declarations | The inspected foundations largely concern governed LLM requests; arbitrary classical ML, tensor inference, and training need additional design and proof |
| Model output is testimony before semantic acceptance | Strong fit with the existing invocation declaration | If the scenario promises only to obtain a prediction, testimony may itself be its legitimate outcome. A stronger classification or decision promise requires additional evaluation |
| Contracts can become feature authority | Contracts are a useful source of structure | Shape alone does not establish feature relevance, units, temporal availability, permissible use, transforms, or labels |
| A provider can be replaced while capability meaning stays stable | A valuable, testable goal | Adapters, modality, output semantics, operational obligations, and workload evaluation must agree; identical schemas do not prove equivalent quality |
| Scenarios can organize ML evaluation | Strong opportunity | Scenario coverage complements statistical performance on representative examples; one passing fixture cannot establish population accuracy |
| The 824-scenario estate can seed a learning corpus | Useful starting ontology and source of candidate cases | The inventory is not a labeled, deduplicated, permissioned training dataset |
| Deterministic admission makes results dependable | Repeatable policy application is achievable within specified boundaries | Passing policy does not establish factual truth. Scores, labels, uncertainty, and policy decisions remain distinct |
| Training fits the capability architecture | Plausible extension | Successful training produces a candidate and evidence. Deployment eligibility and promotion are separate decisions |
| SideFX can learn which precedents or providers to use | Plausible later product hypothesis | Recommendations need measured usefulness and exposure data; they cannot silently override current provider ordering or eligibility rules |

“Managed ML Capability Platform” is a reasonable destination to explore. This assessment establishes architectural fit and a proof agenda, not market uniqueness, customer demand, comparative superiority, or production readiness.

## 3. What exists in the inspected estate

The retained database census observed **824 selected scenarios**, **630 contracts**, **812 resolved scenario inputs**, and **809 resolved scenario outcomes** on **2026-09-09 at 11:52:50 UTC**. It also counted **1,155 selected FIXTURE definitions**. These are different entity counts, not counts of labeled ML examples. See the [original summary and database proof identities](../scenario-experiences/summary.json).

The [ML evidence map](evidence-map.json) selects twelve relevant root scenarios from that census, retaining their contract identities and schema digests. This is a curated integration map, not a census of every ML-related capability. Local feature declarations corroborate intended behavior for ten roots; the provider and precedent resolvers are represented by the retained census only. The local declarations were inspected separately and are not asserted to be byte-identical to the database's selected source revisions. No capability execution was validated in this lane.

| Existing root scenario | Relevance to this lane | Boundary of the evidence |
| --- | --- | --- |
| `govern-model-provider-binding` | Exact provider, concrete model, endpoint, adapter, host, and credential-reference binding | Binding authority does not establish task accuracy |
| `resolve-governed-model-invocation-profile` | Fixed invocation terms and permitted caller parameters | Profile resolution is separate from invocation |
| `construct-model-connection-runtime-closure` | Identified artifacts and host obligations | A described closure is not installation or successful execution |
| `execute-governed-model-invocation` | Normalized responses, attempts, timing, usage, hashes, and lineage | Explicitly excludes domain validation and candidate acceptance |
| `obtain-governed-model-response` | Response or attributable governed failure | Obtaining a response carries no acceptance claim |
| `verify-governed-model-invocation-parity` | Comparison of invocation terms and bindings | This does not prove equal predictions, model quality, or user experience |
| `determine-model-role-provider-switch` | First eligible alternative under declared ordering and constraints | No model-ranked provider selection or invocation is implied |
| `resolve-sidefx-eligible-providers` | Eligibility derived from explicit bindings and evidence | Eligibility is different from demonstrated workload performance |
| `bind-model-testimony-evidence` | Binding request, response, candidate hashes, and attempt lineage | The inspected feature specifically requires Gemini, exactly one attempt, and one structured candidate; it is not a universal ML testimony binder |
| `verify-model-connection-conformance` | Connection and protocol conformance evidence | Connection conformance is different from domain correctness |
| `execute-governed-model-role-conveyor` | Ordered role stages, budgets, testimony, and switching lineage | Orchestration alone is not an evaluation oracle |
| `resolve-sidefx-capability-precedents` | Structured precedent retrieval | Retrieval is a foundation for a learning experiment, not evidence that a learned recommender exists |

The important starting advantage is an existing distinction between invocation, testimony, and acceptance. The proposed lane should preserve that distinction while extending supported model kinds and domain evaluation.

## 4. Proposed architecture: inspectable authority around inference

The following names describe proposed design artifacts, not newly provisioned capabilities or admitted schemas.

| Artifact | What must be explicit |
| --- | --- |
| Capability and scenario authority | Responsibility, input and outcome contracts, acceptable dispositions, evidence requirements, and authorized effects |
| Feature projection authority | Source paths, semantic roles, permissible inputs, units, missing-value handling, transforms, fitted artifacts, and destination representation |
| Model role profile | Task, modality, label vocabulary or generation obligations, supported uncertainty representation, resource limits, and required provider characteristics |
| Inference plan | Exact bindings for the role, features, model/provider, adapter, invocation terms, output normalization, evaluation policy, and evidence collection |
| Evaluation and admission authority | What is checked mechanically, what needs an empirical oracle or reviewer, thresholds, abstention/hold behavior, and the scope of acceptance |
| Execution and evaluation evidence | Exact identities and digests where observable, attempts, results, failures, policy application, and limitations |

The inference plan should be an inspectable intermediate artifact. A deterministic compiler can resolve sufficiently specified authority into a plan or return precise missing or incompatible obligations. It cannot derive a statistically useful task or valid labels merely from JSON Schema.

```text
Scenario input + responsibility
             |
             v
Input admission -> feature projection -> resolved inference plan
                                                |
                                                v
                                      provider execution
                                                |
                                                v
                                  normalized model testimony
                                                |
                                                v
                                evaluation + applicable policy
                                                |
                                                v
                              typed outcome + evaluation evidence
                                                |
                                                v
                                 consuming application / experience
```

Keep three decisions separate: **input admission**, **per-inference result evaluation**, and **provider/model deployment approval**. They concern different subjects and need different evidence. A provider approved for one role and workload is not automatically approved for another.

### Feature authority must carry meaning and fitted state

A mapping from `/document/content` to a model input needs more than a path. It needs a content type, permitted decoding or extraction process, size limits, preprocessing identity, and an explicit choice of text, image, or other representation. A numerical feature needs units, a missing-value policy, and exact transform parameters. `normalize` without a defined method and fitted state is incomplete authority.

Feature plans should bind training and serving transforms, tokenizer or vocabulary versions, tensor shapes and dtypes when relevant, feature order, truncation, and unknown-category handling. Record when a value becomes available: a later human decision or outcome field must not enter a feature that is supposed to exist before prediction.

Fit learned preprocessing on the training partition and apply the fitted transform consistently to validation, test, and inference inputs. Fitting preprocessing using test data creates leakage and can make evaluation look better than it is. This is an obligation the proposed feature authority can make inspectable. [scikit-learn: common pitfalls and recommended practices](https://scikit-learn.org/stable/common_pitfalls.html).

### Bind the full inference bundle

Identify the contract closure, feature projection, fitted artifacts, role profile, provider and concrete model, adapter, prompts or templates where applicable, invocation parameters, response normalization, evaluation policy, and evidence policy. Scope identities by namespace and revision; include content digests where available. A bare contract ID or mutable model alias is insufficient for a reproducibility claim.

Some hosted services cannot expose immutable weights or guarantee stable realization. Record the provider's actual version information and that limitation. A seed or a temperature setting must not be presented as proof of repeatable model output.

## 5. Worked example: document classification

Use the review's document classification example as a candidate proof domain. The responsibility here is document-type classification, with no credit or underwriting decision implied. All example labels and scores below are illustrative.

An input identifies an authorized document, its available representation, and the requested classification role. A provider might return `label: pay_stub` and `score: 0.93`. The normalized testimony must state what that score represents: a class probability estimate, a model-specific confidence value, a similarity score, or an uncalibrated generated assertion.

The evaluator checks the allowed label vocabulary, representation requirements, evidence completeness, and applicable decision policy. It returns a typed classification accepted under that policy, abstention for insufficient information, a policy hold, or execution failure. The outcome retains the policy and model identities, uncertainty semantics, and evidence references.

An accepted prediction can still be wrong. Calibrated probabilities describe observed frequencies across comparable groups of predictions, not proof about an individual document. Calibration itself needs evaluation on data independent of model fitting; a self-reported LLM confidence number should not inherit that interpretation. [scikit-learn: probability calibration](https://scikit-learn.org/stable/modules/calibration.html).

The experience could show a classification summary, “needs review,” or a failure explanation according to the outcome contract. A raw score becomes a user-facing probability only if the contract and supporting evaluation justify that meaning. A reviewer correction becomes a separately attributable record; it does not silently rewrite the original testimony or automatically enter training.

## 6. Where determinism is achievable

| Layer | Proposed guarantee | Limit |
| --- | --- | --- |
| Plan construction | The same complete authority closure and compiler version yield the same canonical plan or findings | Missing semantic choices cannot be filled in deterministically without declared rules |
| Eligibility and switching | Fixed evidence, policy, context, and candidate order yield the same decision | Eligibility is not a prediction of task success |
| Feature execution | Fixed input, transforms, fitted state, and supported runtime yield the specified representation | Numerical behavior and dependency versions require explicit bounds |
| Result admission | Fixed testimony and evaluation inputs yield the same mechanical policy decision | Empirical truth and human judgment do not become deterministic checks |
| Inference and training | Reproducibility is characterized for a named model, runtime, platform, and configuration | Universal identical outputs or weights are not promised |
| Replay | Retained evidence supports reapplying recorded evaluation rules | Evidence replay is different from rerunning the external model |

ML runtimes themselves distinguish controlled reproducibility from cross-platform or cross-release equality. PyTorch explicitly does not guarantee full reproducibility across releases, platforms, or CPU/GPU execution; deterministic algorithms may also carry a performance cost. The lane should document a reproducibility envelope and measured tolerance where appropriate. [PyTorch: reproducibility](https://docs.pytorch.org/docs/2.14/notes/randomness.html).

The achievable foundation is deterministic control and attributable model behavior. For a stochastic or changing provider, repeated inference may produce different testimony even when every surrounding policy is applied correctly.

## 7. Scenario evaluation and dataset readiness

The scenario estate can organize **what must be evaluated**. Actual examples, trustworthy expected results, and representative workload coverage establish **how well the provider performs**. Both are necessary.

Before treating a fixture or scenario-derived case as ML data, record its source, permitted uses, input realization, expected label or allowed outcome, oracle provenance, ambiguity, and relationship to other examples. Separate domain truth from a procedural expected disposition: a fixture proving that malformed input is rejected does not establish the correct class of a real document.

Audit the 1,155 FIXTURE definitions before making corpus-size claims. Determine which contain usable inputs, which are mocks, which have independent domain labels, and which are revisions or variants of the same underlying case. Split related examples by source entity, document family, or time as appropriate; keep their synthetic variants in the same partition. Preserve a held-out test set that does not guide prompt changes, feature fitting, or threshold tuning.

For the classification proof, start with explicit scenario partitions: clean supported documents, degraded documents, unsupported types, insufficient evidence, conflicting signals, malformed provider output, provider failure, and sensitive-field boundaries. Synthetic cases can exercise contract and failure partitions; they need validation before supporting claims about real workload performance.

| Evaluation dimension | Required evidence |
| --- | --- |
| Structural conformance | Input/output validation, normalized label vocabulary, attributable malformed-output handling |
| Domain quality | Independent labeled cases, per-class performance, confusion analysis, and representative workload composition |
| Scenario obligations | Pass/fail and reasons for each applicable scenario, with sample counts rather than just percentages |
| Abstention and acceptance | Coverage, error among accepted predictions, and error/coverage tradeoffs under declared thresholds |
| Score interpretation | Calibration assessment when claiming probabilities; otherwise an explicit description of score limitations |
| Workload slices | Performance on relevant document quality, language, source, and other justified slices; disclose small or absent samples |
| Operations | End-to-end latency distribution, attempts, timeout/failure rates, and cost under a specified workload |
| Replacement | Both providers evaluated against the same role, policy, test partition, and operational obligations |

Aggregate metrics and scenario evidence answer different questions. Report uncertainty and sample counts. An automated judge may help assess open-ended generations, but its own model, rubric, disagreement rate, and independent review need to be visible; it must not silently become the source of truth.

The review's sample accuracy, F1, coverage, and latency figures are hypothetical. No such measurements were produced here.

## 8. Training, promotion, monitoring, and rollback

Training is a separate proposed lifecycle with its own contracts and effects:

```text
Authorized corpus + labels + split + objective + training profile
                              |
                              v
                         training run
                              |
                              v
                candidate artifact + run evidence
                              |
                              v
             independent evaluation and comparison
                              |
                              v
          scoped promotion decision / hold / rejection
                              |
                              v
                 versioned provider-role binding
                              |
                              v
               monitored execution and corrections
                              |
                              v
              review / rollback / new candidate cycle
```

Candidate evidence should identify the data and label versions, split membership, preprocessing, algorithm or base model, hyperparameters, environment, seeds where meaningful, training metrics, and resulting artifact. Large datasets and weights can remain in appropriate artifact stores; authority and receipts bind their identities, permitted access, and digests where available.

Promotion requires its own evaluation policy and evidence. Define the intended workload, critical scenario obligations, quality floors, acceptable cost and latency, and rollback target before promotion. Keep training metrics separate from held-out evaluation results. A finished run does not grant deployment permission.

Monitoring should distinguish changes in input distributions, prediction distributions, delayed labeled quality, and operational reliability. A drift signal starts an evaluation or review path; it does not prove quality degradation or authorize automatic retraining. New labels and human corrections need provenance, permitted use, and review before entering another corpus version.

Neither a universal training runtime nor this promotion/monitoring lifecycle was established by the inspected declarations. They remain proposed extensions.

## 9. Three tracks within the independent ML lane

| Track | Opportunity | Initial boundary and proof |
| --- | --- | --- |
| **ML as provider** | Models satisfy bounded responsibilities while capability meaning remains stable | First priority: inference, testimony, scenario evaluation, and one controlled provider replacement |
| **ML as authoring intelligence** | Propose feature semantics, scenario variants, evaluation cases, and candidate bindings | Proposals remain reviewable candidates. Measure acceptance rate, correction effort, and defects; do not let generated expectations validate themselves |
| **Learning over the Capability Data Center** | Rank useful precedents, estimate provider suitability, or identify likely conformance problems | Later experiment after evidence quality and volume are established; compare against current retrieval or ordering baselines |

The third track needs more than a pile of receipts. Capture what alternatives were available, which were actually tried, the workload and authority revision, failures, interventions, and eventual outcomes. A provider seen only on easy tasks should not win a ranking through selection bias. Untried alternatives have unknown outcomes.

Current `determine-model-role-provider-switch` authority selects the first eligible alternative in declared order. A learned ranking could propose a revised order or profile for explicit acceptance; it must not silently change the present switching rule. Deterministic rules should remain a valid provider or baseline where they fulfill the responsibility.

## 10. First proof and staged decisions

Start with one bounded document classification role and a small, audited corpus appropriate to that role. Use a deterministic baseline and one model provider. Add an alternate model provider only when the first path and evaluation are inspectable. Provider names and frameworks in the review are examples, not selected dependencies.

| Stage | Concrete deliverable | Gate to the next stage |
| --- | --- | --- |
| A. Responsibility and contracts | Role definition, input/outcome examples, dispositions, proposed feature/inference/evaluation schemas | Reviewers can distinguish prediction, acceptance, abstention, and failure without reading provider code |
| B. Dataset audit | Corpus manifest, label provenance, partition design, coverage gaps, permitted-use record | Cases are suitable for the intended evaluation; training/test separation and oracle independence are demonstrable |
| C. Inference proof | One provider path, deterministic baseline, pinned plan, testimony and policy evidence | Supported and failure scenarios produce attributable results; replay of evaluation is consistent |
| D. Evaluation and replacement | Common benchmark report, limits, alternate provider compatibility assessment | Capability contracts and meaning remain stable; each candidate independently meets predeclared quality and operational criteria |
| E. Training extension | One candidate training run and separate promotion/rollback proof | Training completion cannot bypass evaluation or alter the active binding |
| F. Learning experiments | Advisory authoring or precedent/provider recommendation study | Measured improvement over a baseline without bypassing authority or contaminating evaluation |

Set numerical acceptance thresholds and sample requirements before evaluating candidates; this document does not invent them. If the corpus is too small, report a feasibility result rather than a quality claim.

The proof should retain the authority bundle, feature plan, inference plan, dataset/label manifest, scenario evaluation specification, provider evidence, comparison report, and an explicit statement of limitations. It should show an accepted result, a valid abstention, a hold, malformed testimony, provider failure, and a replacement rejected for incompatibility or insufficient evidence.

Product value remains a hypothesis to test: reduced integration effort when replacing providers, reused evaluation obligations, faster diagnosis of failures, and clearer experiences around uncertainty. Measure implementation effort, defects, review effort, and operational outcomes before claiming savings or differentiation.

## 11. Evidence, provenance, and review status

- [Team review](team-review.txt): preserved verbatim. SHA-256 `7c64aa40bf0082a82801e78933aee289faa1ff692d684ab41257de172403fb64`.
- [ML evidence map](evidence-map.json): twelve selected roots, input/outcome contract identities and schema digests, corroborating local feature declarations and their hashes, and explicit evidence limits.
- [Evidence collector and document verification](collect-evidence.mjs): regenerates the map from the retained census and sibling `agentic-harness` checkout; checks local links, declaration/root contract correspondence, and review identity.
- [Verification receipt](verification.json): records artifact hashes and the scope of checks performed; it is document verification, not model or capability conformance evidence.
- [Database inventory and taxonomy](../scenario-experiences/README.md), [summary](../scenario-experiences/summary.json), and [scenario bindings](../scenario-experiences/scenario-bindings.json): the prior research observation, reused here without a new database query.
- [Separate experience opportunity](../scenario-experiences/opportunity.md): the companion lane and its proposed presentation architecture.

The three external technical references linked in the relevant sections were consulted on 9 September 2026. They support the specific leakage, calibration, and reproducibility qualifications; the SideFX architecture and proof stages above are proposals derived from the local estate and the team's review.

To regenerate the evidence map and check this documentation from the repository root, with the sibling `agentic-harness` checkout available:

```powershell
node docs/research/ml-opportunity/collect-evidence.mjs
```

This command reads the retained census and local declarations, then writes only the ML lane's evidence map and verification receipt. It does not query the database or execute capabilities.

**Decision recorded:** document ML as its own opportunity lane. Implementation, model selection, dataset admission, training, promotion, and production operation remain future work. The proposed first implementation scope is the bounded provider-and-evaluation proof in stages A–D.
