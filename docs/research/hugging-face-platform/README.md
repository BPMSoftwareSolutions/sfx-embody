# Hugging Face platform research notes

**Researched 9 September 2026 · Supports the [team plan](../../hugging-face-platform-plan.md)**

The user's [strategic direction](strategic-direction.txt) proposes that SideFX authority should produce experiences, evaluations, datasets, content, and capability intelligence across the Hugging Face ecosystem. Research supports the architectural fit. Adoption, savings, quality, and commercial differentiation need the experiments in the plan.

Method: inspect current local documentation and selected implementation files across `sfx-embody`, `sfx-platform`, `sidefx-cli`, `sidefx-database`, and `content-creation-mission`; recheck the retained scenario census; consult primary external documentation. No fresh SQL census, live deployment inspection, provider invocation, or customer interview was performed. Local evidence includes uncommitted working-copy material, so [source-map.json](source-map.json) records inspected file hashes as well as repository HEADs. [Document verification](verification.json) checks artifact integrity and local links only.

## 1. Claims in the strategic direction

| Claim | Research finding | Planning consequence |
|---|---|---|
| NVIDIA agreed to acquire Hugging Face on September 3, 2026 for $12.9303 billion | NVIDIA's announcement states the agreement and amount; use “agreed to acquire,” not an assertion that the transaction has closed | Context only; the strategy must stand on product usefulness independently of ownership |
| Hugging Face has 18M+ developers, 3M+ models, 500K datasets, and 1M applications | Those are figures in NVIDIA's announcement, not independent measurements of reachable customers | Treat as ecosystem scale, not SideFX's addressable demand |
| Roughly $150M annualized revenue implies an 86× multiple | This research did not establish the revenue denominator from a primary company source. The arithmetic is conditional on it, and does not prove buyer motivation | Exclude the multiple from the investment case |
| A cyber-evaluation incident compromised HF systems | OpenAI's incident account describes model-driven exploitation and access to test solutions, and subsequent investigation/remediation | Support practical containment and provenance work; do not claim SideFX governance would have prevented the incident |
| A Space can embody a capability | The supported hosting options can carry a capability application; semantic equivalence remains SideFX's proof obligation | Implement one projection target with conformance evidence |
| 824 scenarios imply a large generatable application estate | The retained census confirms structural availability; internal scenarios, unresolved bindings, ownership gaps, and runtime holds limit exposed entry points | Start from explicitly published roots with complete experience and execution evidence |
| Capabilities can generate their own content | Existing SideFX content tooling supports reviewed, source-bound projections; most catalog entries still need editorial direction | Reuse the content system and measure authoring effort |

Sources for the first three rows: [NVIDIA announcement](https://blogs.nvidia.com/blog/nvidia-to-acquire-hugging-face/). Incident source: [OpenAI incident account](https://openai.com/index/hugging-face-model-evaluation-security-incident/). These sources verify the reported events, not the proposed SideFX commercial thesis.

The strategic note uses `sidefx.com`; the local platform README identifies the project's website as **`www.sidefx.io`**. Use the project's verified domain and resolve actual capability URLs from its publication. Do not direct the team's releases to an assumed domain.

## 2. Local evidence and important limits

| Source | Observed fact | Limit |
|---|---|---|
| [Scenario census](../scenario-experiences/summary.json) and [bindings](../scenario-experiences/scenario-bindings.json) | 824 scenarios, 630 contracts, 218 roots, 812 resolved inputs, 809 resolved outcomes; locally recomputed intersection of resolved root faces is 216 | One selected observation at 2026-09-09T11:52:50.141Z; not refreshed SQL or runtime coverage |
| [Experience opportunity](../scenario-experiences/opportunity.md) | Four layers separate contracts, interaction authority, plans, and realization; 239 scenarios share input and outcome contracts; 12 repeated schema IDs have differing source digests | No universal experience compiler or cross-target parity proved |
| [ML research](../ml-opportunity/README.md) | Twelve curated roots relevant to model invocation/binding/testimony/evaluation | Declarations and selected bindings; no model runs in that lane |
| [Current invocation](../../../src/invoke-database-capability.mjs) | Direct authority read → `planNode` → memory loader → Scenario Kernel; optional `prepare` handled separately | Code inspection here; no execution performed by this research |
| [Memory loader](../../../src/load-memory-scenario.mjs) | Identifies itself as a candidate loader, explicitly not a security sandbox | Storage/import integrity is not hostile-code isolation |
| [API implementation](C:/lab/repos/sfx-platform/services/capability-api/http-server.mjs) and [service README](C:/lab/repos/sfx-platform/services/capability-api/README.md) | Closed generic command envelope, explicit command policy, 1 MiB default request bound, two default concurrent executions, no authentication; README says undeployed | No live host inspected; local package uses a sibling `file:` dependency that needs deployment packaging |
| [Older execution guide](C:/lab/repos/sfx-platform/docs/capability-execution.md) | Describes required preparation and historical 94 prepared / 125 held | Conflicts with current invocation code; treat counts and preparation latency as historical, not this plan's baseline |
| [Database strategy](C:/lab/sidefx-database/docs/data-architecture-strategy.md) | Separates semantic authority, normalized definitions, source lineage, and scoped analysis | SQL convenience does not create semantic authority; proposed intelligence records need an authority mapping |
| [Content workspace](C:/lab/repos/content-creation-mission/README.md) | Versioned content store, reusable editions, two editorially reviewed capability stories, 217 `NEEDS_DIRECTION` records, and revision-03 episode publication records | Frozen content corpus uses 219 capabilities/823 scenario boundaries; do not silently join it to the newer 824-scenario census by display name |
| [CLI rules](C:/lab/repos/sidefx-cli/AGENTS.md) | Entity identities and vendors belong in canonical data, not new commands/dispatch branches | HF adaptation must preserve this boundary |

Publication integration must resolve namespace, stable identity, source version, and relevant digests across these generations. It should return missing/stale bindings when it cannot do so. Counts from different frozen estates are not additive and must not be relabeled as current coverage.

## 3. Hosting choice

| Option | Useful property | Cost or constraint | Assessment |
|---|---|---|---|
| Static Space | Reusable HTML/JS frontend; suitable for sanitized replay | All code/configuration delivered to the browser; no confidential service credentials there | Good no-execution fallback or later thin client once user authentication is settled |
| Gradio Space | Fast Python research UI, client libraries, generated endpoint documentation | A second renderer/adapter stack for current SideFX web semantics | Use if the initial product becomes a Python-first research tool; otherwise defer |
| Docker Space | Can package the current Node/web direction and a server adapter | Team needs reproducible container/dependency build and a qualifying account plan | Recommended projection host |
| Full SideFX runtime and SQL access inside a Space | Appears to minimize remote hops | Collapses public presentation and private execution/data boundaries; increases credential and operational exposure | Decline for the first release |

HF documents all three SDK choices. Gradio's generated API/OpenAPI facilities are a Gradio integration benefit; Docker applications must explicitly implement and document their own interfaces. Automatic Gradio endpoints are not canonical SideFX command or admission contracts. [Spaces](https://huggingface.co/docs/hub/spaces), [Docker](https://huggingface.co/docs/hub/spaces-sdks-docker), [API endpoints](https://huggingface.co/docs/hub/spaces-api-endpoints).

Operational findings that matter: compute Space creation requires a paid personal or organizational plan; public Space source is visible; protected source does not make the running application private; unused free hardware sleeps; outbound networking is limited to documented HTTP(S)/8080 ports. Static Space configuration is browser-visible, including values configured as secrets. These constraints support HTTPS mediation and an explicit app authorization boundary. [Spaces overview](https://huggingface.co/docs/hub/spaces-overview). Default disk is ephemeral; attached buckets are available for persistence. [Storage](https://huggingface.co/docs/hub/spaces-storage).

## 4. Evaluation and ecosystem reuse

**HF already has evaluation distribution.** Benchmark datasets can aggregate model-repository evaluation records. The `.eval_results` and `eval.yaml` path is currently documented as work in progress, with benchmark allow-list registration. This narrows the differentiation claim: SideFX's proposed value is scoped responsibility, full provider-bundle evidence, and governed consumption of results, rather than inventing model leaderboards. [HF evaluation results](https://huggingface.co/docs/hub/eval-results).

**Inspect is a concrete reuse option.** It offers composable datasets/scorers and analysis tooling. Evaluate an adapter before building an additional benchmark framework. It must consume or invoke the governed SideFX path without silently bypassing it. A particular framework's verification badge is not a domain-correctness or SideFX admission guarantee. [Inspect](https://inspect.aisi.org.uk/).

**Model hosting and inference supply are different.** A Hub repository can exist without an available inference endpoint. HF Inference Providers is a proxy with explicit and automatic provider selection; auto selection can fail over. Select explicit providers for comparisons and record provider availability and identity at run time. Model tags and metadata can produce candidates; workload evaluation must establish fitness. [Inference Providers](https://huggingface.co/docs/inference-providers/index), [Hub search](https://huggingface.co/docs/huggingface_hub/guides/search).

**Dataset publication needs authored context.** A dataset card records content, usage context, and metadata such as license and language. It does not independently establish rights, label quality, or representative sampling. Scenario fixtures first need a suitability audit before being exported as a benchmark or training resource. [Dataset cards](https://huggingface.co/docs/hub/en/datasets-cards).

This was an architectural and product-feasibility review, not an exhaustive competitive survey. Neither the inspected local estate nor the external sources establish that SideFX is unique in governance or that customers will pay for a capability intelligence product. Five initial developer sessions and a measured analyst workflow are the first demand tests proposed in the plan.

## 5. Research conclusions translated into work

| Research question | Conclusion | Follow-up proof |
|---|---|---|
| Can one host serve many capabilities? | Plausible within explicit supported experience profiles | Third capability added by authority/publication data; independently checked semantics on local web and HF |
| Can the current service simply be made public? | No; authentication, subject/effect exposure, immutable version binding, and runtime isolation remain gaps | Private staging boundary test and actual dependency packaging |
| Can structural schemas produce a benchmark? | They can organize obligations, but need cases, labels, slices, policy, and evaluation | Locked corpus and first provider proof |
| Should the platform build a new leaderboard ecosystem? | Reuse HF publishing while retaining the more specific SideFX evidence record | Export proof preserving model/provider/configuration and workload scope |
| Does a good score authorize a provider? | No; observation, assessment, recommendation, and binding are distinct | Incompatible and insufficient-evidence replacement cases remain held |
| Can content become a compounding output? | Existing tooling gives a path, but editorial direction and audience validation remain work | One evidence-bound companion release, with measured authoring and user behavior |

## 6. Source register and reproduction scope

All external pages below were consulted on **2026-09-09**. URLs and page behavior may change; pricing and beta integration requirements should be rechecked at implementation and launch. `source-map.json` retains the local evidence hashes, the source URLs, and the root-intersection calculation. It does not claim to archive or hash remote page contents.

| Reference | Supports |
|---|---|
| [NVIDIA announcement](https://blogs.nvidia.com/blog/nvidia-to-acquire-hugging-face/) | Agreement wording, amount, and company-reported ecosystem counts |
| [OpenAI incident account](https://openai.com/index/hugging-face-model-evaluation-security-incident/) | Reported compromise and investigation; no SideFX prevention claim |
| [HF Spaces](https://huggingface.co/docs/hub/spaces) | Supported projection host choices |
| [Space overview](https://huggingface.co/docs/hub/spaces-overview) | Access, account eligibility, lifecycle, configuration, networking |
| [Docker Spaces](https://huggingface.co/docs/hub/spaces-sdks-docker) | Container hosting and server environment |
| [Space API endpoints](https://huggingface.co/docs/hub/spaces-api-endpoints) | Gradio API and OpenAPI behavior |
| [Space storage](https://huggingface.co/docs/hub/spaces-storage) | Ephemeral disk and attached persistence |
| [Access tokens](https://huggingface.co/docs/hub/security-tokens) | Resource-scoped token roles |
| [Inference Providers](https://huggingface.co/docs/inference-providers/index) | Actual inference routing/provider selection |
| [Inference pricing](https://huggingface.co/docs/inference-providers/pricing) | Routed/custom-key billing and organization billing |
| [HF pricing](https://huggingface.co/pricing) and [Team plans](https://huggingface.co/enterprise) | Current compute and subscription estimates |
| [Evaluation results](https://huggingface.co/docs/hub/eval-results) | Native benchmark/results integration and beta constraints |
| [Dataset cards](https://huggingface.co/docs/hub/en/datasets-cards) | Dataset context and discovery metadata |
| [Hub search](https://huggingface.co/docs/huggingface_hub/guides/search) | Candidate discovery APIs |
| [Inspect](https://inspect.aisi.org.uk/) | Existing evaluation-framework reuse option |

No sources were used to infer customer demand, a guaranteed quality threshold, automatic provider interchangeability, clinical/financial suitability, or acquisition-driven future platform policy. Those are either outside scope or explicit hypotheses in the plan.
