# Investor demo readiness — blockers, complications, and the defer list

**Purpose.** Team-review research for the investor demo script
([sidefx-public-demo.md](sidefx-public-demo.md)). It records what is real today,
what blocks each scripted beat, what makes the beats complicated, and what can be
deferred without weakening the storyline. It creates no requirements; the
authority stack in [architecture-priorities.md](architecture-priorities.md) still
governs, and the rubric's necessity test ("if omitted, which beat fails?") is the
filter applied below.

**Status date.** 2026-09-15, estate `e4ad16f`, tree clean. Research was read-only:
three parallel agents, no database writes, one provider probe. **Updated
2026-09-17: the verdict was overturned and the lane demonstrated — see §11 and
[agent-lane.md](agent-lane.md). Sections 3–10 and the original blocker rows are
retained as the 2026-09-15 assessment; where they conflict with §1, the blocker
dispositions below, or §11, the newer sections govern.**

## 1. Verdict

**The demo is achievable, and it was demonstrated on 2026-09-17.** Both
blockers the 2026-09-15 assessment projected were cleared without the work items
it assumed:

1. **The model/agent lane executes.** The connector-authority package is
   present in this environment, and the model is invoked as a provider inside
   governance: `obtain-governed-model-response` → Gemini returns a structured
   proposal (live receipt 2026-09-17). The composition lives in the harness
   (`sfx agent invoke`, two governed deliveries), so the graph-path
   `invoke-scenario` blocker (B2/R1) is sidestepped for the demo, not needed by
   it. See [agent-lane.md](agent-lane.md).
2. **A live price is shown through the fallback route.** The primary credential
   remains quota-exhausted (`429`, remaining `0`, reset `2026-10-06T16:52Z`),
   but that quota is now the demo's *fallback trigger*: the installed route
   resolves through `rapidapi/yahoo-finance-real-time1` (verified AVGO 339.51
   USD, POSTPOST, NMS). It blocks only the primary supplier.

**What the 2026-09-15 assessment said and what replaced it:** its "not
achievable next turn" verdict and its "model story as declared and revealable,
execution pending" scope are both superseded — the execution exists, and the
honest refusal beats (B3 in the target experience) are real via
`CAPABILITY_NOT_FOUND` with no provider reached and no effect.

## 2. What is real today

| Real capability | Evidence |
|---|---|
| Governed invocation: admission, authority resolution, provider-slot resolution, execution testimony, `observedPathDigest`, evidence, story join | `sfx capability observe resolve-equity-market-price-evidence --input @examples\equity-market-price-evidence.request.json --trace/--json`; receipts `evidence/demo-2026-09-15T14-23-18.443Z/` |
| Refusal by absence (the honest deny) | `sfx capability invoke execute-equity-purchase --json` → `CAPABILITY_NOT_FOUND`; same for `generic-http-request` |
| The declared model/agentic language | 27 model capabilities, e.g. `obtain-governed-model-response`, `execute-governed-model-invocation`, `project-model-provider-protocol`, `bind-model-testimony-evidence`; `reveal --as meaning` renders them |
| Typed input mapping | `sfx capability invoke resolve-equity-market-price-evidence --input AAPL --json` exits 0 via the declared CLI input mapping (`embodiments/…/interfaces.authority.json`) |
| Retained live receipts | `evidence/demo-2026-09-15T12-25-03.280Z`, `…12-28-14.353Z` (QQQ 709.18, `Delayed Quote`); post-digest green run 14:21Z (MSFT 498.82, `sha256:10d4386c…`) |
| Demo verifier | `scripts/verify-demo.mjs` — 11 cases, receipts + `report.json`, no synthesized values |

**Correction to a suspected regression.** The declaration-conformance migration's
digest move (`8ad3907…` → `10d4386c…`) did **not** break live equity: the post-migration
run at 14:21Z returned `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` at the new digest. The
provider quota (`429`, remaining 0) is no longer a red: the installed fallback route
answers through real-time1 while the primary is rate-limited (verified 2026-09-17, §11).

## 3. Beat-by-beat assessment

| Beat | Exists today | Gap | Class | Deferrable? |
|---|---|---|---|---|
| Act 1 — direct governed invocation with control-room frame | all data: story responsibilities + dispositions/timings, declared authority id, provider identity, RESULT fields, `observedPathDigest`, timings | terminal frame layout; the demo's invented labels (execution id, evidence id, provider slot, `EXECUTION CLOSED`, 384 ms) have no source; per-responsibility provider identity and effect class are not in story/testimony | rendering + two declared projections | frame yes; data additions yes |
| Act 1 live price | historical receipts | quota-exhausted credential; stale `examples/equity-price.request.json` seam | external | only with a new credential or a recorded/unavailable storyline |
| Act 2 — agent lane (`sfx agent run`) | declared model capabilities (reveal only) | no `agent`/`eval` CLI surface; `invoke-scenario` missing on the graph path; LLM connector node-only; connector-authority package absent; no model transcript exists to replay | SDA (2 requests) + estate authoring | no for execution; yes to stage as declared-only |
| Act 3 — deny + circumvention | refusal-by-absence is real | no `execute-equity-purchase` / `generic-http-request` declared; no grant/effect-class vocabulary; no "providerReached"/"physicalEffect" field | estate authoring (grants) + SDA (principal/grant decision) | yes, restaged as refusal-by-absence (truthful) |
| Act 4 — Agency Exposure Receipt | per-invocation receipts only | no session/agent ledger; no attribution | data (ledger) | yes, a driver-composed receipt from real receipts, labeled |
| Act 5 — comparative eval (models × profiles) | nothing | `eval` surface, profiles, ≥2 wired model adapters | data + boot | yes — trigger: model lane executable |
| Act 6 — ASCII mini-circuit animation | nothing; markdown narrator was retired (`cfcaa44`); no box drawing in the terminal | terminal rendering; meaningful only after the lanes exist | rendering | yes — presentation only |
| ASCII sketches in CLI output | `--format markdown` only changes heading style; no Mermaid fences today (the Mermaid review document was the retired narrator) | a terminal frame renderer | terminal-owned (per `narration-projection-disposition.md`) | frame yes; agent/authority sketches depend on Acts 2–4 |

## 4. Blocker register

| # | Blocker | Evidence | Severity | Resolution |
|---|---|---|---|---|
| B1 | RapidAPI monthly quota exhausted | probe 2026-09-15T22:37Z: `429`, limit 500, remaining 0, reset `2026-10-06T16:52Z`; matches F6 | **no longer blocks** (2026-09-17): the fallback route answers live (estate `9230b83`; AVGO 339.51 USD via real-time1). The quota is the demo's fallback trigger, not a blocker | none for the demo; renew/replace only if the primary itself must be shown answering |
| B2 | Graph path cannot compose scenarios (`invoke-scenario`) | `obtain-governed-model-response`, `observe-governed-http-exchange` both fail `SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING: 'invoke-scenario'`; implemented only in the legacy consumer-plan path (`SDA:…/admitted-consumer-platform.mjs:159`); `SDA:docs/handoff/sda-capability-invocation.md:3` | **sidestepped for the demo** (2026-09-17): the agent lane composes two governed deliveries at the harness level (`sfx agent invoke`) | **SDA request R1** remains open for in-graph composition |
| B3 | Scheduler effect provider dispatches a two-entry map, not the admitted port catalog | `SDA:…/semantic-execution-graph-effect-provider.mjs:11-14` (credential + HTTP only); `platform-effect-provider.mjs:243-251` (read-file, bounded-process) | **not blocking the model lane** (2026-09-17): `obtain-governed-model-response` executes live through its admitted provider path | **SDA request R2** remains open for in-graph connector/generic-HTTP dispatch |
| B4 | LLM connector node-only; connector-authority package absent here | `sda-platform-capabilities…json:412-425` `projectionTarget: node`; no python/csharp implementation; `generic-llm-conveyor/config/provider-authority.json` absent from this checkout; `LOC_GEMINI_API_KEY` present | **resolved in this environment** (2026-09-17): the package is present and the node path is live-proven (`MODEL_RESPONSE_OBTAINED`, gemini-2.5-pro) | python/csharp parity remains **SDA request R4**; node needs nothing |
| B5 | No agent/authority meaning: no agent object/verb, no grants, no effect classes (`pure/observation/effect` exists, not READ_ONLY/MUTATION), no session ledger, no `providerReached`/`physicalEffect` field | greps of `sql/`, `src/`, SDA schemas; `sfx --help` offers only `capability` + `media`; policy/principal schemas exist only in the enterprise layer | **partially addressed** (2026-09-17): `sfx agent invoke` is offered, and the agency receipt is a labeled driver-composed summary of the two real receipts | grants, effect classes, and a session ledger remain future; refusal stays by absence (no policy DENY claimed) |
| B6 | Demo vocabulary mismatch | `sfx invoke … --symbol AAPL` → exit 2 (`Unknown option '--symbol'`); the surface is `sfx capability invoke … --input AAPL`; `observe` is the command that carries story/overlay | screens do not run as written | doc correction (no code) |
| B7 | Demo risk: timing, nondeterminism, concurrency | measured invocation 1.95–3.0 s vs the doc's 384 ms; live model output nondeterministic; shared `sidefx` database and a second worktree (`sfx-embody.worktrees/greeting-response-handler`) | credibility | driver prints measured wall times; freeze window; recorded fallback |

## 5. What makes it complicated

- **Meaning vs presentation.** The convincing frames (authority ALLOW/DENY, effect
  classes, provider-reached, physical-effect-none, agency receipt) are *meaning*,
  not layout. The transistor rule says declared (1) or resolver (0); rendering is
  terminal-owned, but the frames' nouns must come from rows. Two of them
  (per-responsibility provider identity, effect class) are declared projections
  that do not exist yet; the rest need the grant/ledger work.
- **The deny beat is a policy claim.** Today the purchase is refused because no
  capability exists (`CAPABILITY_NOT_FOUND`), not because a grant was evaluated.
  That is honest and strong ("no executable path exists") but different from
  "authority denied"; the script must say the former unless the grant model is
  authored.
- **Two providers, two failure modes.** The model lane's blocker (composition +
  connector) is independent of the provider quota; fixing one does not unblock
  the demo.
- **The held-out connector package.** Even the node LLM path needs the
  `generic-llm-conveyor` sibling checkout; this is an environment prerequisite,
  not repo work.
- **Cross-target parity debt.** The LLM connector has no python/csharp
  implementation, so any agent capability would be node-only — a parity gap to
  schedule, not to hide (transistor-model §6/§9).

## 6. Honesty boundaries for the demo (per the rubric §8)

- **May** show (updated 2026-09-17): real governed invocation and testimony;
  real refusal by absence; the declared model/agentic language via `reveal`;
  retained live receipts **labeled** with capture time, snapshot and
  `observedPathDigest`; and the agent lane (`sfx agent invoke`) — the governed
  model provider's proposal and its harness execution or refusal — as long as
  the receipt note says it is driver-composed.
- **May not** show without new work: `sfx agent run` / `sfx eval` as working
  surfaces (the surface is `sfx agent invoke`); a `CAPABILITY_NOT_FOUND` as a
  policy DENY; "provider not reached" for the purchase (the truthful statement
  is "no execution occurred"); READ_ONLY/MUTATION as declared effect classes; an
  agency receipt as database-derived (a driver-composed receipt must say so);
  the demo's 384 ms as a measurement.
- Fixture substitution, if ever used, is governed by the rubric: substitute at the
  declared provider seam, record the fixture identity, and state that provider
  conformance and the external effect remain unproven.

## 7. Recommended next-turn scope (the credible cut)

One wave, three units, all honest without B2/B3/B4/B5:

1. **Act 1 control-room frame (terminal rendering).** Add a frame presentation to
   `sidefx-cli/src/render.mjs` for `observe` results, built only from fields that
   exist (`story.scenario.responsibilities[]`, dispositions, timings,
   `eventAuthorityId`, `overlay` admission, `result.outcome`, `providerTestimony`,
   `observedPathDigest`, `evidence.timings`). Real ids and values; measured wall
   time; no invented `exec_*`/`ev_*`/provider-slot labels; ASCII GIVEN/WHEN/THEN
   lanes as terminal presentation. Gated behind a flag so existing outputs and
   tests are untouched.
2. **Refusal beat (driver).** Run the real `execute-equity-purchase` and
   `generic-http-request` refusals and frame them as "no declared capability — no
   executable path"; never print "authority denied".
3. **Demo driver (`scripts/demo-driver.mjs`, boot/harness).** Runs each beat via
   `cmd /c` with UTF-8, captures stdout/stderr/exit/wall time, renders only from
   captured output, supports `--recorded` banners for the retained receipts,
   probes the quota first, and fails when a claimed outcome did not hold (the
   `verify-demo.mjs` discipline). No database meaning, no migrations during
   recording.

Superseded 2026-09-17: **agent execution landed** as the harness-composed
`sfx agent invoke` lane (unit 3's driver is that delivery; units 1–2 remain
presentation polish). Still deferred: the session ledger, receipt-as-data,
comparative eval, profiles, animation, brokerage.

## 8. Defer list with revisit triggers

| Item | Trigger |
|---|---|
| Agent execution lane (Acts 2–4) | **Landed 2026-09-17 by a different route:** the harness composes two governed deliveries (`sfx agent invoke`); no SDA/R1/R2 dependency for the demo |
| Minimal agent row-set (single-scenario `request-capability-from-objective` binding `sda-generic-llm-connector-port.v1`; driver lane; refusal beats) | **Superseded:** the driver lane shipped; an in-graph single-scenario agent waits on R1 |
| In-graph composition (`invoke-scenario`), scheduler port catalog, LLM connector parity | unchanged: SDA R1/R2/R4 |
| Session/agent ledger and receipt-as-data | when cross-invocation attribution is required beyond a labeled driver composition |
| Authority profiles / effect classes / true policy DENY | when the grant model is authored (SDA R5 decision first) |
| Comparative eval (`sfx eval …`) | model lane executable and ≥2 adapters wired |
| ASCII animation / persistent mini-circuit | after the driver's frames are stable; presentation only |
| Real brokerage/purchase | a declared mutable-effect capability with authority and provider — outside current intent |
| Vault manager, sealed bootstrap, inverse projection, long-lived host | already tracked in `architecture-priorities.md` §3 |

## 9. Decisions the team must make

| # | Decision | Options | Recommendation |
|---|---|---|---|
| D1 | Provider access for Act 1 | renew/replace `RAPID_API_KEY`; or recorded receipt; or live unavailable branch | renew/replace if the live price matters; otherwise recorded + unavailable, both labeled |
| D2 | Agent lane scope for this demo | commit to R1/R2 + connector + estate authoring; or stage as *declared and revealable, execution pending* | stage as declared-only for the investor; commit to the build for the next one |
| D3 | Deny storyline | refusal-by-absence (real today); or author the grant model for a true policy DENY | refusal-by-absence now — it is the stronger architectural claim |
| D4 | Model if the lane is built | Gemini only (wired); OpenAI (adapter needed); Claude (nothing declared) | Gemini first, single attempt, structured response contract |

## 10. Evidence index

- Demo script: [sidefx-public-demo.md](sidefx-public-demo.md) (untracked at review time; committed alongside this assessment).
- Current terminal outputs: `evidence/demo-2026-09-15T14-23-18.443Z/` (observe trace/json, display, reveal).
- Retained live receipts: `evidence/demo-2026-09-15T12-25-03.280Z/`, `…12-28-14.353Z/`.
- Quota: probe receipt 2026-09-15T22:37Z (429, remaining 0, reset `2026-10-06T16:52Z`); F6 in `architecture-priorities.md`.
- Model lane: `sfx capability reveal obtain-governed-model-response --as meaning`; failure receipts in this review; `SDA:docs/handoff/sda-capability-invocation.md`.
- SDA requests: R1 (graph-path `invoke-scenario`), R2 (scheduler dispatch of the admitted port catalog), R4 (LLM connector parity), R5 (principal/grant/effect-class decision, deferrable) — to be filed in the standard format.

## 11. Update — the agent lane landed (2026-09-17)

The credible cut was overtaken by a smaller, stronger move: the agent lane was
realized as a **harness composition of two governed invocations**, with the
model as a provider inside the governed execution environment. See
[agent-lane.md](agent-lane.md) for the surface, receipts and boundaries.

- **B4 is resolved in this environment**: the connector package is present and
  the node model path is live-proven (`obtain-governed-model-response` →
  `MODEL_RESPONSE_OBTAINED`, provider gemini, model gemini-2.5-pro).
- **B2/B3 are sidestepped, not closed**: the composition lives in the delivery
  (two deliveries), not `invoke-scenario` inside one graph. R1/R2 remain open
  for in-graph composition; the demo does not depend on them.
- **B5 is partially addressed**: the agency receipt is a labeled
  driver-composed summary of the two real receipts; the grant model, effect
  classes and session ledger remain future.
- **Line 58's "no `agent` surface" is closed**: `sfx agent invoke` is offered
  by the estate and verified for the price objective and the purchase refusal.
- **B7 test question answered**: the estate's non-passes are DB-gated skips (0
  failures); none touches the demo path.
- Remaining before recording: the declared-display provider line in the Beat 1
  frame (display-transformation change), and the D1 provider-access decision
  (the fallback route already answers while the primary quota is exhausted).
