# SideFX on Hugging Face: platform direction and delivery plan

**Team review draft · 9 September 2026 · Proposed 12-week program from team approval**

SideFX should make an exposed capability usable, evaluable, and explainable from the same versioned authority. Hugging Face is the first external ecosystem in which to prove that product: a shared SideFX Lab, a reproducible capability benchmark, and evidence that can feed the existing content system. Over time, these observations can support provider recommendations scoped to a capability, workload, and policy.

The recommendation is to fund a bounded first release, then expand when its evidence and user value justify it. Start with existing deterministic capabilities to prove the shared experience and remote execution path. Add the document-classification proof already proposed in the ML lane. Publish results and an interactive companion through one reusable application. Build advisory provider intelligence after comparable evaluations exist.

This document combines the [scenario experience proposal](research/scenario-experiences/opportunity.md), [ML opportunity](research/ml-opportunity/README.md), current runtime and API code, and external research. [Research notes and sources](research/hugging-face-platform/README.md) record factual checks, implementation limits, and competing approaches. The attached strategic direction is retained as [source material](research/hugging-face-platform/strategic-direction.txt). The original research did not perform deployment, account purchase, model evaluation, or database changes.

**Implementation update, 9 September 2026 (local time):** the private Hugging Face Space is now running the shared SideFX Lab. All three original interactions and actual RapidAPI stock-price retrieval passed through the authenticated Azure service and selected database authority. The [deployment report](../../sfx-platform/docs/live-finance-deployment.md) records the HF commit, pinned service image, native execution identities and hosted verification. The research roadmap below retains its wider proposed scope.

## 1. Decisions for this review

**Mandatory next-run direction from the user:** deploy the Lab to the private Hugging Face Space `BPMSoftwareSolutions/SideFX`, keep all three existing interactions working there, and complete a live stock-price request from that Space through the remotely hosted SideFX service/database authority and RapidAPI. Local execution cannot satisfy completion. The [live finance handoff](research/hugging-face-platform/next-run-live-finance.md) defines the deployment work and acceptance evidence.

| Decision | Recommended position | Accountable role |
|---|---|---|
| Product direction | One authority can support execution, experiences, evaluation, and reviewed content; HF is the first external projection and supplier ecosystem | Product/platform sponsor |
| First product | One **SideFX Lab** with capability selection, explicit Run, outcome interpretation, and scoped evidence | Product lead |
| Initial hosting | Docker Space using the shared web renderer and a small server adapter; execution remains behind a SideFX-owned authenticated service | Platform lead |
| Invocation | Direct invocation; preparation remains optional and must not become an invocation prerequisite | Runtime lead |
| First proof | Three existing deterministic roots; then one document-classification role, deterministic baseline, one model, then an alternative | Runtime and ML leads |
| Public data | Reviewed synthetic examples and explicitly publishable evidence; public uploads of arbitrary documents deferred | ML/data lead |
| Public benchmark | SideFX-owned versioned results first; optional export to HF native evaluation results after compatibility is proved | ML lead |
| Provider recommendations | Advisory and evidence-scoped; changing an active binding remains a separate governed decision | Architecture lead |
| Initial commitment | Approve weeks 1–4, proposed $500/month non-labor ceiling, and named owners; review evidence before funding subsequent phases | Sponsor |

Suggested meeting: 10 minutes on the product, 15 on authority and execution boundaries, 15 on the first proof and evaluation, and 10 on owners, budget, and the next gate. Record each decision as approved, amended, or deferred. The schedule below assumes approval and staffing; it is not a delivery commitment already made by the team.

## 2. What the first release should do

A developer arrives from Hugging Face, a SideFX capability page, or a video. They choose a published capability, understand what they may supply, run an allowed example, and see the actual outcome. A model-backed example shows the model's response, the declared evaluation applied to it, and the resulting acceptance, abstention, hold, or failure. Each view links to the capability and the evidence supporting the claim.

The first audience is AI developers and technical evaluators trying to understand whether a provider can fulfill a bounded responsibility. The first value proposition is **“Run a capability and inspect why its result was accepted or held.”** Demand for a general provider-selection product remains a hypothesis.

One application can have several entry links: Capability Lab, Provider Comparison, and Scenario Explorer. These are profiles and views over shared plans. New capabilities should require declarations, fixtures, and publication records; the host should not need a capability-name branch or bespoke route. A new semantic control family can require a reusable renderer extension and conformance evidence.

The first release excludes model training, autonomous provider promotion, whole-Hub crawling, unrestricted capability invocation, and production document processing. Those exclusions bound the investment while leaving the larger direction intact.

## 3. Starting position and the work still needed

The September 9 census contains 824 scenarios, 630 contracts, 812 resolved input bindings, and 809 resolved outcome bindings. A join of its retained root bindings confirms **216 of 218 roots have both sides structurally resolved**. These are candidate sources for experiences, not 216 runnable public applications. [Census](research/scenario-experiences/summary.json), [bindings](research/scenario-experiences/scenario-bindings.json).

| Area | Inspected foundation | Gap relevant to this plan |
|---|---|---|
| Native execution | Current `sfx-embody` code reads selected authority, plans a Node body, and executes it in memory; repository documentation retains a bounded provider-resolver proof | Reproduce readiness for the chosen pilot roots and package the complete runtime dependency closure for a remote host |
| API | `sfx-platform/services/capability-api` implements generic `POST /commands`, operation restrictions, bounded bodies, and concurrency limits | Current code has no authentication; local docs describe it as undeployed. Public authorization, run tracking, service packaging, and deployment remain work |
| Experience | Existing basic contract form and a detailed experience-plan proposal | Implement explicit ownership, scoped references, outcome interpretation, accessibility, and unsupported-state handling |
| ML | Twelve relevant roots mapped in prior research; declarations distinguish invocation, testimony, switching, and acceptance | No model invocation or dataset suitability was verified in that research; the general evaluation path needs a bounded proof |
| Knowledge | Database separates semantic definitions, source provenance, and scoped analysis | Define observation and assessment records without promoting model-card claims or test logs into authority |
| Content | Existing content workspace has versioned production records, reusable capability editions, evidence checks, and published-video records | Bind an HF companion and evaluation release into those records; editorial and learner review remain necessary |

Two architectural facts affect implementation. First, the current [invocation code](../src/invoke-database-capability.mjs) does **not** consume a retained preparation: preparation is an optional separate proof. The `sfx-platform` execution documentation has been reconciled with this behavior; its historical 94/219 preparation coverage remains historical and is not this program's readiness baseline. Second, the [memory loader](../src/load-memory-scenario.mjs) explicitly states it is not a security sandbox. Remote execution needs an actual isolation boundary.

## 4. Proposed architecture

```text
Declared capability / scenario / contracts / interaction / evaluation authority
                                  |
                    selected, versioned authority closure
                                  |
               +------------------+-------------------+
               |                                      |
      experience compiler                    inference / evaluation plan
               |                                      |
      published experience manifest                   |
               |                                      |
        HF SideFX Lab                                  |
  shared renderer + server adapter                     |
               | HTTPS                                |
     SideFX access and run service                     |
               |                                      |
     existing generic POST /commands                   |
               |                                      |
        sfx SDK -> sfx-embody -> Scenario Kernel --------+
               |                         |
         declared providers       observations + outcomes
                                         |
                            scoped assessment and evidence
                                         |
                   +---------------------+------------------+
                   |                     |                  |
              Lab results          HF dataset/results   content release
                                         |
                              advisory provider intelligence
```

### Preserve authority and use existing boundaries

The database supplies selected authority under existing identity and precedence rules. Hosting a record in SQL or HF does not grant it semantic authority. Contracts constrain values; interaction declarations specify ownership and experience; evaluation declarations specify what a result establishes. A generated plan is a derived artifact with lineage.

Reuse the CLI/API envelope: `{ object, operation, subject, namespace?, input }`. Capability and provider identities stay in data. Keep vendor-specific transport implementation in a provider adapter selected through declared bindings. Do not add commands such as `sfx hf classify` or routes per capability. Read-side catalog and experience publications can be versioned documents; new run-status transport endpoints must remain generic and must not expand semantic command permissions.

The public catalog is an explicit publication allow-list, independent of root status. The service authorizes the exact subject, operation, caller, input constraints, and allowed effects. A web form cannot grant execution permission. A Space service credential cannot turn every visitor into a platform administrator.

### Deploy a projection host, retain execution ownership

Use a Docker Space to host the reusable web interface and a server adapter. Docker accommodates the existing Node/web direction without requiring a second semantic renderer in Python. HF supports Docker, Gradio, and static Spaces; this is a SideFX design choice among those supported targets. [HF Spaces](https://huggingface.co/docs/hub/spaces), [Docker Spaces](https://huggingface.co/docs/hub/spaces-sdks-docker).

The Space reads sanitized, digest-bound publications and calls a SideFX endpoint over HTTPS. It never connects to the canonical SQL database. The SideFX service resolves selected authority, binds system inputs, and runs approved providers in controlled workers. Keep SQL credentials, provider credentials, dataset write access, and publication credentials out of the public app. HF supports resource-scoped access tokens; select the minimum separate scopes for each service. [HF tokens](https://huggingface.co/docs/hub/security-tokens).

Use reviewed authority in a controlled runtime image; do not execute downloaded model-repository code or visitor-supplied code in that image. Workers need bounded compute, explicit outbound destinations, separate credentials, and termination behavior demonstrated by tests. Signed or hashed code identifies what was selected; it does not establish safe execution.

Store run state and evidence outside the Space's local disk so restarts cannot lose the record of an invocation. HF documents that default Space storage is ephemeral and supports attached storage; SideFX-owned durable evidence storage is the proposed authority-preserving choice here. [Space storage](https://huggingface.co/docs/hub/spaces-storage).

### Make plans and execution agree

The proposed experience manifest binds capability namespace/identity, root scenario version, selected model/snapshot, input and outcome contract digests, scoped resource closure, interaction and presentation profiles, compiler version, target binding, and publication identity. These are required responsibilities to map onto existing contracts before introducing new schema identities.

The first API compatibility spike must settle how the manifest's revision is bound to invocation. The current closed envelope has no expected-revision field. The initial service can execute against a selected immutable publication/runtime deployment; otherwise the shared invocation protocol needs an explicitly reviewed version-binding extension. A frontend-only revision check would leave a race. If the service cannot execute the displayed authority, return a stale-publication hold before execution and require a refreshed experience.

For each field, retain editable, fixed, system-bound, derived, displayed, omitted-by-policy, or unsupported status. Bind provider inventory and assurance findings server-side. A user must not be able to type `parityMatches: true` and thereby create proof. Reference resolution includes scope and digest: the census found repeated schema IDs with different bytes. Unsupported or ambiguous semantics produce a visible hold; raw JSON is appropriate only where an explicit expert interaction permits it.

### Preserve execution uncertainty

Separate transport state, kernel disposition, domain outcome, evaluation finding, and managed admission. A terminated call does not establish business success or provider approval. Preserve native result codes and provide human labels from declared presentation meaning.

Add durable run IDs and status lookup before asynchronous public model jobs. Use an idempotency key scoped to caller, command, input digest, and authority binding. A repeated key with different content is rejected. Enforce concurrent budget reservations atomically. A timeout or lost connection may mean execution is still running; show an unconfirmed state and consult run status instead of silently retrying. A cancellation request is not proof of cancellation until a worker acknowledges it. Start with read-only deterministic pilots while these semantics are established.

## 5. First proof: experience, then model evaluation

### Experience and remote execution proof

| Pilot | Why it belongs | Required qualification |
|---|---|---|
| `say-hello-world` | Action with no editable payload values | Recheck its runtime binding; census inclusion alone proves no execution |
| `greet-by-name` | Small user-supplied input and simple outcome | Exact serialization, absent/empty handling, input refusal, keyboard operation |
| `resolve-sidefx-eligible-providers` | Nested outcome collections, reasons, and system-owned inventory | Use publishable retained inventory, clearly marked as a fixture demonstration; no claim that an external provider was called or admitted |

All three roots exist in the retained census. Add the same capability to a local web host and the HF target through the same manifest. Extend internal conformance fixtures with a scalar root, branch changes, nested arrays, conflicting references, missing authority, held outcomes, and malicious markup. The broader corpus in the experience research remains the next coverage suite.

**Gate:** the third root adds no capability-specific host code; the two hosts satisfy the same independently declared serialization, ownership, state, and result-interpretation vectors. All mandatory vectors pass, with unsupported profiles explicitly held. Review keyboard navigation, focus after errors, labels, and result announcements. Record authoring effort separately from host implementation effort.

### One document-classification responsibility

Reuse the ML lane's first proof: classify a bounded set of document types, with abstention for unsupported or insufficient evidence. Begin with reviewed synthetic text examples; OCR, image processing, and real mortgage documents introduce separate modality and data requirements. The exact root identity and contracts require authority design; the prose example is not evidence that a mortgage classifier already exists.

Start with a deterministic rules baseline and one explicitly bound model/provider combination. Add a second model only after input handling, normalization, evaluation, and evidence replay are inspectable. Select candidates in week 5 by supported task/modality, access and licensing, version observability, structured-output behavior, cost, and availability. No particular model is selected by this research.

Fix the provider explicitly for benchmark runs. HF's automatic routing can change providers or fail over, so a model ID alone does not identify the evaluated system. Preserve actual provider/version information and disclose when an endpoint cannot expose an immutable realization. [Inference Providers](https://huggingface.co/docs/inference-providers/index).

The proof must demonstrate an accepted classification, valid abstention, policy hold, malformed testimony, provider failure, and an incompatible replacement being refused. Keep input admission, per-result evaluation, and provider deployment approval as separate decisions. Synthetic success supports a feasibility claim within that corpus; it does not establish real-world document accuracy.

## 6. Benchmark and publication contract

Prepare the evaluation protocol before observing candidate test scores. A planning allocation is 600 independently reviewed synthetic cases: 200 development, 100 calibration/policy selection, and 300 locked test cases. This is a workload estimate, not statistical justification for every slice. The ML lead may change it before locking the protocol. Group variants of the same source/template into one partition, deduplicate, record label provenance, and disclose where template diversity is limited. Keep locked test labels away from live demo controls and prompt tuning.

| Dimension | What the report must show |
|---|---|
| Responsibility | Capability, role, labels, modalities, allowed dispositions, policy and test split versions |
| Domain quality | Counts, per-class precision/recall or F1, confusion matrix, and uncertainty appropriate to the independent source groups |
| Acceptance behavior | Accepted fraction, error among accepted results, abstention, holds, and rejection reasons; no single score that rewards accepting everything or abstaining from everything |
| Scenario obligations | Each required contract, failure, ambiguity, and malformed-output condition with its own observed finding |
| Operations | End-to-end p50/p95 latency, cold/warm conditions, workload/concurrency, failed attempts, retries, input/output usage, and cost with denominators |
| Reproducibility | Input and dataset digests; model and provider identity; adapter, prompt, parameters, normalization, evaluator, policy, and runtime versions |
| Comparison | Same held-out cases and policy; declared tuning allowance; repeated model runs and grouped uncertainty; comparable rows only |

For an engineering proof, require all mandatory structural/failure vectors and evidence bindings to pass. A statistical deployment threshold is intentionally not invented here: the domain owner must set acceptable error, abstention, coverage, and latency before the locked evaluation. Without an approved threshold and representative workload, publish descriptive feasibility results and no provider-approval claim. A benchmark can succeed as research even when no model qualifies.

Export a corpus manifest, dataset card, run manifests, normalized results, evaluator configuration, and a readable report. Public artifacts include only reviewed source material and evidence permitted for publication. Cards need license, task, construction, limitations, intended use, and split information. [HF dataset cards](https://huggingface.co/docs/hub/en/datasets-cards).

Reuse evaluation tooling where it helps: time-box an Inspect adapter spike to two engineering days. Require it to preserve SideFX execution and scoring bindings; avoid a second model invocation outside the governed path. If it cannot preserve the evidence cheaply, keep the existing runner and export the same results. Inspect already offers composable evaluation components and analysis tools. [Inspect](https://inspect.aisi.org.uk/).

HF supports benchmark datasets and `.eval_results` in model repositories, currently as a work in progress with benchmark allow-list registration. Maintain a SideFX-owned results dataset and Lab comparison view. Export compatible metrics with links to full provider/configuration evidence; HF badges do not establish SideFX admission. Release must not depend on a model owner accepting a result PR. [HF evaluation results](https://huggingface.co/docs/hub/eval-results).

## 7. Capability intelligence and content

### Start with scoped observations

The first intelligence release covers the two evaluated model/provider combinations and a small curated candidate list for the same role. Use HF's model, dataset, and Space listing/filter APIs to gather metadata. Repository descriptions, task tags, popularity, and licenses are discovery inputs, not conformance evidence. [HF Hub search](https://huggingface.co/docs/huggingface_hub/guides/search).

Map the following responsibilities to existing database semantics before proposing tables:

| Record | Identity and scope | Effect on authority |
|---|---|---|
| Supplier observation | HF repo, revision if available, observed time, metadata source/digest, provider availability | Candidate discovery only |
| Execution observation | Run, capability/scenario, model/provider bundle, input, testimony, costs and failures | Attributable observation only |
| Capability assessment | Dataset/split, evaluator, policy, workload, result distribution, limitations, validity window | Scoped assessment, potentially inconclusive |
| Recommendation | Required role/constraints, eligible evaluated candidates, evidence, ranking rule, reasons, expiry | Advisory; separate acceptance required to change a binding |

Prefer a qualified statement such as “bundle B met policy P on workload W in evaluation E” over an unqualified `Model SATISFIES Capability` edge. Missing evidence yields unknown or insufficient evidence. A new model revision, changed adapter, changed policy, or expired operational evidence triggers reevaluation; it does not overwrite the historical record. Deterministic provider ordering remains in effect until authorized selection authority changes.

This gives the longer-term supplier resolver a defensible path: intent → declared constraints → candidates → applicable evidence → scoped recommendation → separately accepted binding. CNCF can eventually use the same conceptual separation, but implementing a CNCF connector is outside this HF proof.

### Connect to the existing content system

Use `content-creation-mission`'s versioned production store and capability editions. One evaluation release should supply a claim/evidence package, report, chart data, an interactive companion link, and an editorial brief. Video scripts and training material need audience direction, editing, and review; useful content does not follow automatically from a valid contract.

Proposed first companion: **“One capability, two providers: what changed, and what stayed governed?”** Link to the exact published evaluation and a pinned Lab experience. If only one provider is ready, tell the baseline-versus-model story honestly. Existing episodes can link to relevant companion experiences after editorial review; no video metadata changes are part of this research task.

Bind content releases to capability, evaluation, dataset, and public evidence revisions. Changed or withdrawn evidence must flag dependent claims for review. Keep public teaching examples separate from the locked benchmark test set. Viewer feedback is an observation with permitted-use metadata; it must not automatically become a label, training example, or approved provider preference.

## 8. Delivery sequence and acceptance gates

Staffing assumption: two full-time engineers (runtime/API and experience), one half-time ML/data engineer, one quarter-time product/content owner, and platform/security review at each boundary. Roles may be combined, but missing capacity requires a re-estimate. Effort below is a planning range in person-weeks, including review and integration; calendar phases depend on the preceding gates.

| Phase | Timing / effort | Deliverable and owner | Exit gate |
|---|---|---|---|
| 0. Authority and deployment design | Weeks 1–2 / 4–5 | Runtime + experience leads: selected pilot authority, support matrix, ownership profiles, current dependency/package map, revision-binding and public-access design | Chosen roots reproduced through the actual `sfx` path; differences from retained evidence recorded; service can bind displayed authority; named data/budget owners |
| 1. Private SideFX Lab | Weeks 3–4 / 5–6 | Experience + platform: compiler slice, reusable renderer, Docker packaging, authenticated staging service, three pilots | No capability-specific host dispatch; mandatory conformance vectors pass; unauthorized subjects blocked; reset/restart and uncertain-run behavior demonstrated |
| 2. CapabilityBench proof | Weeks 5–7 / 6–8 | ML + runtime: role and corpus, first model path, baseline, second provider, replay and comparison report | Locked protocol and evidence reproduced; acceptance/abstention/hold/failure distinguished; incompatible replacement refused; no unsupported quality claims |
| 3. Public presence and companion | Weeks 8–10 / 6–8 | Product + platform: public Lab, reviewed dataset/results, pinned companion and release runbook | Publication rights/claims reviewed; quotas and revocation tested; five developers complete pilot tasks; release artifacts reproducible outside the author's machine |
| 4. Advisory capability intelligence | Weeks 11–12 / 4–5 | Architecture + ML: curated supplier observations, evidence-scoped query, expiry and reevaluation proof | Recommendations trace to comparable evidence; missing evidence returns inconclusive; recommendation cannot mutate active binding |

The full estimate is 25–32 person-weeks. Weeks 1–4 are the first commitment. Experience work and corpus design can overlap after authority responsibilities are agreed. Public launch depends on both the execution gate and publishable evaluation evidence; capability intelligence can move to a later milestone if those take longer.

If a selected root is held, repair the actual missing authority/provider obligation or revise the pilot at the gate. A screenshot or a canned result is not a substitute for live execution evidence. A clearly labeled replay can remain available during outages, but live execution stays disabled until restored.

### First ten working days

1. Name the product, runtime, experience, ML/data, and release owners; accept or amend the pilot and budget.
2. Reproduce selected roots, retain exact input/output and authority bindings, and reconcile preparation-era documentation.
3. Map proposed experience/evaluation responsibilities to existing declarations; author only the missing pilot metadata.
4. Resolve immutable publication-to-run binding and the access boundary before connecting a Space to execution.
5. Build a local shared-renderer slice and a container dependency proof; review observed results and the phase-1 backlog.

## 9. Costs, operations, and measurable value

Current public HF pricing lists CPU Upgrade at $0.03/hour and T4-small at $0.40/hour. On an illustrative 720-hour month those are $21.60 and $288. Team is advertised at $20/user/month. Compute-backed Space creation requires a qualifying paid plan; a no-hourly-cost CPU tier should not be budgeted as an entirely free organizational deployment. Recheck account-specific terms before purchase. [HF pricing](https://huggingface.co/pricing), [Team plans](https://huggingface.co/enterprise), [Space creation](https://huggingface.co/docs/hub/spaces-overview).

Proposed initial **$500/month non-labor cap**: $60 for three Team seats, $21.60 for one CPU Upgrade Space, $150 for external API/runtime hosting, $150 for inference, $30 for evidence storage/telemetry, and $88.40 contingency. The latter four allocations are estimates, not vendor quotes. Existing subscriptions can reduce incremental cost. Model weights stay remote initially; a GPU-hosted variant requires a new estimate.

Benchmark call planning: 300 locked cases × 3 model repetitions × 2 model/provider bundles = 1,800 paid calls, plus 300 deterministic-baseline executions. At an **assumed** average $0.002–$0.02 per paid call, that is $3.60–$36 before retries, development runs, hosting, and storage. Use actual selected-provider usage and prices for approval. Report costs per attempt and per accepted outcome. HF routed and custom-key billing differ; credits are not a spending ceiling. [Inference billing](https://huggingface.co/docs/inference-providers/pricing).

Before public release, reserve each request's maximum allowed spend, bound input/output sizes, concurrency and attempts, and reject requests that exceed remaining budget. Start with at most two concurrent live jobs and published examples. Add caller quotas and a global daily budget. Reaching the ceiling disables new paid runs and leaves read/replay available. Test limits across multiple service instances and restart; an in-process counter alone is insufficient.

| Question | Initial proposed success measure |
|---|---|
| Does shared projection reduce repeated work? | Third pilot requires no capability-specific host code; record metadata authoring and renderer extension hours separately |
| Can people use and understand it? | At least 4 of 5 invited developers complete a run without intervention and correctly distinguish result acceptance from provider approval |
| Is comparison reproducible? | Another team member reconstructs the report from retained data/configuration; rerunning a changing model is reported separately |
| Is the surface dependable? | Mandatory failure, restart, authorization, stale-authority, and quota vectors pass; observed latency and availability published within the measured scope |
| Does distribution lead to use? | Track qualified visits → chosen capability → completed run → evidence view → return visit; measure 30 days before setting a growth forecast |
| Is provider intelligence useful? | Reviewed candidate comparisons reduce analyst work against a documented manual baseline; no recommendation without applicable evidence |

These are pilot targets. They are not claims of achieved performance or statistically representative customer research.

## 10. Risks and explicit stop conditions

| Risk | Response built into the plan | Stop or narrow scope when |
|---|---|---|
| UI invents meaning or permits fabricated evidence | Explicit ownership, scoped references, independent conformance vectors, server input binding | An obligation cannot be represented faithfully; mark that profile unsupported |
| Remote runtime exposes excessive authority | Subject/effect policy, worker isolation, credential separation, denied egress, access tests | Unauthorized invocation or unrestricted host access remains possible |
| Plan and execution use different revisions | Immutable selection or a reviewed shared protocol extension with atomic revision checks | Displayed authority cannot be bound to the run |
| Attractive benchmark overstates model fitness | Locked grouped splits, independent labels, baseline, uncertainty, explicit scope | Corpus rights/labels are inadequate or statistical claims exceed evidence |
| Provider drift invalidates comparison | Bind the full bundle and observed version; expire affected assessments | Actual provider cannot be identified sufficiently for the published claim |
| Public traffic exhausts funds or duplicates effects | Durable jobs, idempotency, atomic budgets, confirmed cancellation | Spend or duplicate execution cannot be bounded |
| HF API, pricing, or benchmark support changes | Isolated HF adapter, portable manifests/results, own canonical URLs and artifacts | Launch depends on an unavailable beta feature; use the owned comparison view |
| Content outruns evidence | Claim/evidence bindings, editorial review, stale-claim detection | A claim cannot link to publishable supporting evidence |
| Scope outruns staffing | Fund one gate at a time, measure authoring cost, defer intelligence/training | Phase-1 proof requires more capacity than the approved team can supply |

Release rollback means select the prior immutable app/publication/runtime bundle, revoke live credentials or subjects where necessary, preserve evidence, and show a dated unavailable/replay state. A corrected benchmark becomes a new version with a visible correction; history is not silently overwritten.

The next team decision is whether to authorize the four-week shared-Lab proof with the owners and limits above. Its review should show a functioning generic experience and attributable execution, then use that evidence to size the benchmark and public release.
