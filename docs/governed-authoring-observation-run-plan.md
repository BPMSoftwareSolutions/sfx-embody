# Governed authoring observation run plan

**Status:** proposed observation contract and repeatable runbook, 2026-09-24. This document changes no estate authority or runtime behavior. It complements the [capability-authoring evaluation plan](implementation-plan-capability-authoring-evaluation-circuit.md) and the [circuit view plan](implementation-plan-circuit-view.md). Record each trial's actual authority and kernel digests; do not treat the examples or a previous trial as current state.

## Question and boundary

For one governed authoring run, show **which declared input entered each cell, what value left it, which edge handed that value to the next cell, and why a candidate was held, repaired, accepted, or installed**. A viewer must be able to follow the same value across source, provider, and circuit ports without inferring identity from timestamps or display text. The record must remain inspectable after the servers restart.

The database owns capability meaning, contracts, routing, capture policy, and admitted candidate receipts. The SDA kernel owns execution-boundary testimony and source identity. The SDA API owns run event IDs and replay. `fractal-lab-providers` owns collection, durable storage, and its own frontend. Fractal Lab only routes the registered provider and observer contracts; it receives no authoring-specific capture logic. Models propose under declared authority and do not send messages directly to one another.

## What can be observed now

| Surface | Available now | Limit to state explicitly |
| --- | --- | --- |
| SDA run API | `POST /v1/runs`, paged/SSE events, run graph, terminal output, evidence references. Each event has source-assigned `eventId = urn:sda-api:run-event:<runId>:<cursor>`; SSE `id` remains the cursor. | The host retains 1,000 events per run in memory. Event payloads are bounded at 4 KiB. Evidence records and members leave the lane, but `GET /v1/evidence/{ref}` currently returns `501 EVIDENCE_PROVIDER_NOT_CONFIGURED`. An evidence reference is **not** a retrievable payload today. |
| Execution testimony | Cell testimony supplies `cellExecutionId`, `inputContractId`/`inputDigest`, `outcomeContractId`/`outcomeDigest`, disposition and graph lineage. Edge testimony supplies source outcome digest, destination cell/port, binding digest and admission disposition. | These are topology and digest evidence, not the input and output JSON bodies. A terminal output is available separately if under the output cap; it is not every intermediate baton. |
| SDA telemetry provider | Streams and validates the SDA `eventId` into a circuit invocation and exposes a separate listener frontend. | Its captured-run cache is process memory, capped at ten runs. It is a viewer/relay, not durable evidence storage. |
| Circuit observer and telemetry provider | The observer preserves an SDA event's `eventId` as `observationKey` at both ports. The provider frontend shows/filter/copies the event JSON. | Circuit SSE history is process memory, capped at 10,000 messages. The frontend mirrors the bounded source event; it cannot recover a missing evidence body. |
| SFX observer demo (`:8787`) | Displays CLI observation records and assigns `sfx-observer:<instance>:<sequence>` keys for its own feed. | A CLI demo run and an SDA API run are separate invocations. Their keys must not be presented as one-to-one matches unless a common source emission actually links them. |

The current working trees also contain **uncommitted** SDA observation-filter and estate telemetry-allowlist drafts. They are not a deployed contract. Reconcile their treatment of `shapes`, payload limits, and denied members before using either as a basis for a capture claim.

## The observation contract to add

Keep the live lane small. Each boundary event carries identity, topology, contract, digests, and capture disposition. A separately authorized evidence provider stores a **redacted, immutable value body** and resolves its reference. No listener invents a replacement ID or reconstructs a body from display text.

| Field | Meaning and owner |
| --- | --- |
| `runId`, `eventId`, `cursor` | SDA API run and emission identity, stamped once at source and preserved through every listener. |
| `graphId`, `canonicalGraphDigest`, `cellExecutionId`, `edgeId`, `logicalOrder` | Join an observed boundary to the compiled graph and cell/edge testimony. Use the fields applicable to that boundary. |
| `batonId`, `parentBatonIds[]` | Kernel-assigned identity for a value crossing a boundary. The same baton ID is retained across a handoff; a transformation creates a new baton and names its parents. Fan-out retains one source baton and records each destination edge. This is distinct from `eventId`, which identifies one emission. |
| `boundary`, `fromPortId`, `toPortId`, `contractId` | Closed boundary vocabulary: input, output, edge handoff, provider request/response, or terminal output, with declared port and contract identities. |
| `valueDigest`, `visibleDigest`, `payloadBytes`, `payloadRef` | `valueDigest` is the kernel's value testimony; `visibleDigest` covers the redacted body the observer may fetch. `payloadRef` exists only after that body is durably written and verified. The two digests need not match after redaction. |
| `captureDisposition`, `reason`, `policyDigest` | Explicit `CAPTURED`, `REDACTED`, `OMITTED_BY_POLICY`, `OVERSIZE`, or `FAILED`; name the declared policy version and reason. A required capture that is absent makes the trial incomplete. |

The exact schema and baton-assignment point need an SDA interface authority and cross-language conformance vectors. The estate declares which contracts and boundaries require bodies, which members are denied, and the size/time budgets. Credential handles, authorization headers, tokens, secret-shaped values, and raw provider bodies outside the admitted policy never enter the viewer or an export. Required capture cannot silently degrade to a digest-only success: the run report marks it incomplete or failed with a named reason.

Store event envelopes as append-only NDJSON and redacted payloads as content-addressed blobs under a configured **provider-owned data directory outside every repository**. Persist a run manifest and cursor checkpoints atomically. Index by `runId`, `eventId`, `batonId`, cell/edge identity and digest; deduplicate replay by source `eventId`. A provider-owned authenticated read endpoint may resolve a stored payload for the frontend. The current SDA evidence-content route must either gain its declared storage provider or remain explicitly unavailable; the provider must not pretend its mirror is SDA evidence.

## Run one observation

1. **Pin the trial.** Record the selected estate authority digest, installed kernel digest, provider registry/catalog digests, capability ID, fixture ID and input digest, capture policy digest, model/provider identity, and explicit `fixture` or `live` mode. Keep credentials out of the manifest. Use a disposable candidate/estate namespace for mutation trials and a declared cost/time cap for live model calls.
2. **Compile first.** Use the declared `capability compile` path or the SDA capability-graph read. Save the returned graph and digest; record a refusal if it cannot compile. Map the expected cells, ports, branches and terminal contract before submitting a run. Compilation must not invoke a provider or install a change.
3. **Start collection before dispatch.** Connect the provider-owned collector to the SDA event stream and circuit SSE feed. Arm it to attach as soon as run admission yields `runId`, replaying from `after=0`. It must persist each source event and advance its checkpoint only after the event is written. Record the circuit's separate SSE cursor as a delivery cursor, never as the SDA `eventId`.
4. **Submit exactly one pinned invocation.** Use the registered `sda-capability` provider through Fractal Lab when testing port propagation, or submit directly to the SDA API when isolating the source. Record the SDA `runId` and the circuit invocation ID as different identities. Reuse the same idempotency key only to resume the same intended run.
5. **Drain to a real terminal.** Page/reconnect from the last persisted SDA cursor until `terminal && !hasMore`. A retention `gap`, host restart, invalid source ID, mismatched port key, missing required boundary, or unavailable payload reference is an explicit incomplete result. Do not fill it from another run or silently retry as a new run.
6. **Collect the separate documents.** Save the run graph, terminal output or its declared unavailability, evidence-reference list, candidate/decision/evaluation receipt IDs and digests, and any authorized redacted payload bodies. Verify each blob digest before marking `CAPTURED`. A reference returning 501 remains `UNAVAILABLE`, with no body displayed.
7. **Reconcile and present.** Produce one report joining source events to circuit messages by exact `eventId`/`observationKey`; join cell and edge testimony to the graph; join input/output/handoff records by `batonId` and parent IDs; compare declared contracts and value digests at each crossing. The provider frontend shows a graph/timeline with expandable boundary JSON, copy, and a payload link only when the authorized body exists. Preserve missing and held states visibly.

## Trials, in order

| Trial | Exercise | Required evidence |
| --- | --- | --- |
| 0. Transport canary | `say-hello-world`, through the SDA provider and circuit observer. | Every SDA `eventId` appears once in circuit telemetry with the same key; the observer contract verifies input-to-output key preservation; graph and output saved; no gap. This proves transport, **not** intermediate payload capture. |
| 1. Read/admission | `list-tools`, `admit-tool-call` with one declared tool and one unknown tool. | Exact input/output contracts and digests; admitted and named `HELD` results; no executable-row change. |
| 2. Authoring skeleton | Compile and run the selected 11-altitude capability in an explicitly pinned fixture mode. | All expected cells/edges and branch states accounted for; each intended baton boundary either has its authorized body or an explicit capture disposition. Never describe canned output as model-authored. |
| 3. Candidate gate | File one disposable candidate, evaluate, record a decision, then exercise a missing/wrong-digest acceptance attempt and a valid accepted attempt in a test estate. | Candidate, evaluation and decision receipt lineage; named refusals; no installer reached on the refused path; installed document and live invocation proof only on the accepted path. Label canned alignment as such. |
| 4. Live model and fan-out | Run a bounded governed model call, then the declared two-branch dispatch proof. Expand to multi-model authoring only when that harness is actually declared. | Request/response baton metadata, redacted authorized bodies, provider attribution, per-branch lineage and join; budget and failure testimony. A two-branch execution proof is not a multi-model candidate join. |

## Acceptance and implementation order

**Immediate baseline:** trial 0 can run with the existing event, graph and output APIs. Before stopping either server, save the SDA paged event responses through terminal completion, `GET /v1/runs/{runId}/graph`, `GET /v1/runs/{runId}/output`, and the circuit telemetry frontend's NDJSON export into a trial directory outside the repositories. Save the request fixture and a small manifest with both run identities and the graph digest. Reconcile the exact IDs offline and state that full intermediate bodies are unavailable. This manual capture is vulnerable to in-memory retention gaps; mark such a trial incomplete rather than treating the files as a complete run package. Do not replay the entire event universe or rely on a browser buffer as the record.

The durable collector replaces that manual capture with a package of this shape (names are illustrative, not a new estate artifact type):

```text
<provider-data-dir>/runs/<runId>/
  manifest.json                 # pins, mode, source/circuit IDs, policy, terminal state
  source-events.ndjson          # source envelopes, in cursor order
  circuit-events.ndjson         # delivery mirror, with its own SSE cursors
  graph.json                    # compiled projection and digest
  output.json                   # terminal output, or explicit unavailable record
  references.json              # evidence refs and capture dispositions
  payloads/<visibleDigest>.json # authorized redacted bodies only
  reconciliation.json          # matches, gaps, missing boundaries, verdict
```

**Source work:** declare the boundary/capture schema and policy in the estate; implement generic baton identity and redacted evidence production at SDA execution boundaries; add a durable evidence resolver to the SDA API; prove the same contract in Node, Python and C#. Keep every provider or capability-specific rule in declaration data. Reconcile the uncommitted observation-filter drafts before this unit lands.

**Provider work:** add the durable collector, checkpoint/replay logic, immutable payload storage and authenticated evidence read to `fractal-lab-providers`; extend its own frontend with a baton timeline and source/circuit match view. Fractal Lab keeps its generic registry, observer ports and event forwarding. No telemetry or authoring frontend code moves into the lab app.

**Acceptance tests:** (1) 100% exact source-event-ID matches across the SDA/provider/circuit path for a complete run; (2) zero unreported cursor gaps or duplicate writes after reconnect; (3) every required cell input/output and edge handoff has a contract, digest and explicit capture disposition; (4) every `CAPTURED` reference resolves after process restart and verifies its digest; (5) redaction tests show no denied member in events, blobs, UI or export; (6) failed/held and parallel runs retain distinct lineage; (7) a complete run package can be reopened without the original processes. Measure capture bytes and added latency against the same run with capture disabled, then set declared budgets from that evidence.

The first durable deliverable is a **run package plus reconciliation report**, not a dashboard screenshot. A trial is complete only when the package explains both observed baton movement and any boundary whose body could not be captured.
