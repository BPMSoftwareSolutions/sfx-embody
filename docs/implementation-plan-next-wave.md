# Implementation plan — the wave after the agent lane and IEA

**Status.** Proposed 2026-09-17, applying
[sidefx-architecture-decision-rubric.md](sidefx-architecture-decision-rubric.md)
(§4 dispositions, §5 measures, §7 compact record). Scope: the units that
remain after the agent lane was declared and installed (`d89b7f9`), the driver
retired (`6962040`), cross-capability composition resolved (`1c11d74`, SDA
`8d5b7a0`), timing coherence named and accepted (`invisible-execution-authority.md`,
`bda0ad6`), the vault-only environment installed (`b660b1a`, `67fd91a`,
`48ba173`), and the first projected C# executable installed
(`projected-csharp-install.md`). Authority: `target-architecture.md`,
`target-experience.md`, `embodiment-completeness.md`, `transistor-model.md`;
the rubric owns the method, this plan owns the sequence, and nothing here
expands admission.

**Already declared and installed, awaiting integration:** the agentic-client
surfaces are not proposed work — the estate already declares them. The MCP
delivery `deliver-capability-change-mcp` exposes the four authority-declared
change tools (open, seal, publish, observe) with their exact schemas,
annotations and failure carriers (`capability-change-mcp-tool-request.v1` and
siblings; rollout `deliver-capsule-estate-mcp` for the capsule estate), and
the context capabilities `assemble-sidefx-capability-authoring-context` and
`carry-consumer-authority-context` assemble and carry context as declared
work. What remains is integration and demonstration, staged in W4.

**The one question per row (rubric §4):** if this decision is omitted from its
wave, which intended behavior fails, and why?

## W1 — Close the circuit for the recording (Needed now)

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
|---|---|---|---|---|
| Remove the temporary `diagnostic` field from `shape-agent-refusal-evidence` (authored in `declare-agent-capability.sql`; flagged in `agent-lane.md`) | Builder intent: "remove it before recording"; the refusal contract (`agent-refusal-evidence.v1`) is the recorded artifact | Omitting it ships debug vocabulary in the demo's expected output and in the contract consumers read | Benefit: the refusal receipt states exactly what is claimed. Burden: one transformation re-declaration + preflight (both objectives) + note; minutes | **Needed now** |
| Beat 1 provider line in the declared display (`EXECUTION TESTIMONY / provider …`), the "one tiny detail" from the target experience (`target-harness-experience.md:560`, echoed at `agent-lane.md:126`) | The display decision ("the display is 1") — the reading is declared rows, not terminal code | Omitting it leaves the recorded Beat 1 frame without the route attribution the target experience asks for; the identity exists only in testimony | Benefit: OUTCOME MEANING ≠ PHYSICAL PROVIDER TESTIMONY becomes visible in the frame. Burden: one display-transformation change + verify; small | **Needed now** (before recording; the source asks for it before the recording, so this is not a deferrable display nicety) |
| Record the D1 provider-access decision as observed: the primary 429 is the fallback trigger | `sidefx-public-demo-readiness.md` D1; observed receipts (primary `retained-non-success` `exchangeCount: 1`, real-time1 answers) | Omitting it re-opens an already answered question at recording time | Benefit: no credential renewal needed; the degraded path is the story. Burden: none beyond the record | **Needed now** (doc row) — records the disposition already directed by `demo-commands.md:21-23`; no new team decision |
| Final command pass against `demo-commands.md` verbatim (three beats, PowerShell and cmd quoting) | The doc is the recorded script; B6 discipline ("the surface wins") | Omitting it risks a recorded command that does not run as written | Benefit: recording confidence; catch quoting drift. Burden: one read-through with live runs; small | **Needed now** |

## W2 — The release flywheel (Useful now)

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
|---|---|---|---|---|
| One-step install: `scripts/install-projected-csharp.mjs` (project → `dotnet publish` both emitted projects → install root → fixture run; manifest + digest receipt) | `projected-csharp-install.md` "Flywheel shape"; builder intent: "a true release process for a client machine" | Omitting it keeps the install as three manual steps per capability, on the critical path of every client release | Benefit: removes manual `dotnet publish` invocation and path drift; names the artifact set. Burden: one script + receipt schema; hours. Reversibility: delete the script, no data impact. Break-even: unknown install count; the named outcome (client release) carries the decision, not arithmetic | **Useful now** (revisit when the pinned-DLL change lands) |
| Replace the build-time SDA project reference with pinned adapter DLLs so a client build needs no SDA source | Same; projection emits the reference (`ProjectedConsumer*.generated.csproj`) | Omitting it keeps the client build coupled to an SDA checkout — the opposite of the release claim | Benefit: builds from the published artifact set alone. Burden: projector/install coordination; the DLL set already ships under `providers/consumer-execution/<sha>/` | **Useful now** (requires an authoring-surface decision: emit a DLL hint or rewrite at install; builder decision if the projector must change) |
| Project and install the remaining demo capabilities to the C# client (equity is installed in the client root; `compose-resolve-equity-market-price-evidence` and `route-two-child-proof` are estate-installed and execute live but have no projected workspace or client install; the model lane is vault/network-backed and installs fixture-only) | `projected-csharp-install.md` artifacts; each install is a row of evidence | Omitting it leaves the client surface at one capability; the two named capabilities are done only at the estate declaration level | Benefit: the installed set becomes the client's capability surface. Burden: per-capability project+install runs; minutes each | **Useful now** |
| Cross-language performance comparison from the existing harness (`scripts/projected-performance.mjs`) over the installed set | `performance-optimization.md`; the harness already exists | Omitting it leaves "same capability, different provider realization" unquantified for client planning | Benefit: medians per target on one machine. Burden: run + report; small | **Defer** (trigger: a client packaging choice needs the numbers) |

## W3 — Next experiences and their enabling requests (Defer with triggers; U3/U5 re-dispositioned per the display record)

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
|---|---|---|---|---|
| F1/F2 projected testimony timing and parity (SDA requests 7/8 in the `architecture-priorities.md` §4 register; the request docs themselves are "Open request") | `sda-change-request-projected-testimony.md`; requested by the IEA projected-target acceptance | Not for W1/W2. Omitting it keeps projected-target timing coherence untestable (the projected bodies carry no duration fields — verified across `embodiments/*/projected`) | Benefit: unlocks IEA acceptance for projected bodies and the versioned-bodies experience. Burden: SDA-side emitter change | **Defer** — trigger: F1 lands; then extend `verify:timing` and `verify-projected-testimony.mjs` to the projected targets |
| `httpStatus` in bounded provider evidence (SDA request 11 in the same register) | `sda-change-request-bounded-provider-evidence-http-status.md`; the rate-limit record needs the signal | Not now. Omitting it keeps 403/429/500 indistinguishable in streamed evidence | Benefit: rate-limit runs become inspectable. Burden: one bounded scalar in the kernel bound; estate allowlists are ready | **Defer** — trigger: the rate-limit store's streamed receipt parity is required (the classification probe already works from raw exchange evidence, `rate-limit-evidence-store.md:39-42`); no F1 dependency |
| Display migration U3 (reader documents) and U5 (boot/CLI reduction: `execution-drilldown`, `observation-filter`, `semantic-address` → declared readings per `next-experiences.md` §5) | `display-projection-decision-record.md:52,54` records U3 **Useful now** and U5 **Needed now, sequenced last** under the directive "the code cannot remain" (`transistor-model.md:49`) | U3: omitting it keeps reader logic in boot code. U5: omitting it leaves a recorded Needed-now violation in place | Benefit: removes the remaining mislocated authority. Burden: multi-unit migration on the hot loader path | **Needed now** (U5, sequenced last) / **Useful now** (U3); triggers as recorded in the display record. This plan does not defer a recorded Needed-now unit |
| Vault V5: rotation, macOS/Linux/cloud realizations, python/csharp ports, consent boundary | `vault-manager-capabilities.md` V5; the demo environment is vault-only already | Not now. Omitting it leaves one OS realization and no rotation | Benefit: the same semantic capability across hosts. Burden: per-language+OS provider realizations | **Defer** — trigger: a second host OS, a rotation need, or client distribution |
| Session/agent ledger; receipt-as-data; comparative eval; authority profiles (SDA R5) | `agent-lane.md` remaining; `sidefx-public-demo-readiness.md` defer list (its "driver-composed" wording is stale after `6962040`) | Not now. Omitting them leaves cross-invocation attribution to a record, with no claim made | Benefit: database-derived agency receipt. Burden: ledger rows + read + grants model | **Defer** — separate triggers: ledger (a cross-invocation question the record cannot answer); receipt-as-data (a consumer needs the receipt as a row); authority profiles (the grant model is authored; SDA R5 first); comparative eval (a second wired adapter — the model-lane-executable condition is now met) |
| Sealed bootstrap binary; backdoor-script migration; per-language bootstraps | `architecture-priorities.md:124` (sealed bootstrap: distribution requirement); `transistor-model.md` §6/§9 (per-language bootstraps: admission); `next-experiences.md:103-110` (scripts) | Not now. Omitting them changes no current intended behavior | Benefit: distribution without implementation exposure; script debt migrates to rows. Burden: large, cross-repo | **Defer** — triggers at the sources named left (`next-experiences.md` records none) |
| `sum` display arithmetic (recorded boundary in `invisible-execution-authority.md`) | The timing reading is independently selectable today | Omitting it costs one extra selection step; no failure | Benefit: a story display could carry the timing summary directly. Burden: expression-vocabulary addition (SDA) or a boot seam | **Defer** — trigger: the display record's D4 condition (`display-projection-decision-record.md:39`) |

## W4 — The declared agentic-client surface: MCP and context assembly (installed; integration staged)

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
|---|---|---|---|---|
| Demonstrate the declared MCP tool surface: invoke `deliver-capability-change-mcp` and show the four authority-declared change tools with their schemas, effect annotations and bound operations (no undeclared tool) | The capability's own meaning (reveal: "MCP delivery owns protocol carriers, tool declarations, schema binding, annotations, invocation, and failure representation only"); the target experience's "one door to effect" for agentic clients | Not for the three recording beats. Omitting it leaves the external-agent claim (tools are declared, not granted) undemonstrated while the capability sits installed; no invocation receipt exists yet (declaration-level only) | Benefit: the MCP act states the governance claim in a second, client-facing form — the model never receives a tool SideFX did not declare. Burden: one invocation + its input example; small | **Defer** — trigger: the recording adds an agentic-client act, or an MCP client is wired |
| Verify the MCP failure semantics honestly: a governed operation failure returns its failure carrier and the server stays up (no mutation broadening, no read-only hiding of an effect, no kernel-terminating failure) | Same capability meaning; `represent-capability-change-mcp-failure` scenario | Not now; no consumer yet | Benefit: pins the boundary claims with receipts. Burden: negative-case invocation + note | **Defer** — trigger: the MCP surface is demonstrated or consumed |
| Demonstrate the capsule-estate rollout `deliver-capsule-estate-mcp` (installed with its contracts; no row before the audit) | The rollout's own declared meaning (same MCP delivery shape, capsule estate) | Not for the three recording beats | Benefit: the second estate surface is shown from rows. Burden: one invocation + input example | **Defer** — trigger: the capsule estate surface is demonstrated or consumed |
| Integrate `carry-consumer-authority-context` into a consumer path (installed; no row before the audit) | Its declared meaning and the "what the model can see is governed" claim | Not now; the lane's visible set is already declared authority inside `build-agent-model-request` (`declare-agent-capability.sql:56,115`; "the AST recipe is data", `transistor-model.md:167`) | Benefit: context carry as rows for a second consumer. Burden: one consumer wiring | **Defer** — trigger: a second consumer context is declared |
| Replace the agent lane's visible-set literal in `build-agent-model-request` with the declared context assembly (`assemble-sidefx-capability-authoring-context`, or a context capability the lane declares) | The display/authority rule ("what can be declared must be declared"); `agent-lane.md:20-21` | **Premise corrected:** the visible set is not undeclared — it is a literal inside the declared transformation, i.e. declared authority; the change is a declared change to the lane's capability and request contract, not a repair of an undeclared literal | Benefit: one authority for visibility; a changed visible set becomes a declaration. Burden: a context-assembly invocation in the decision chain + request-builder change; durable, beyond routine delegation | **Builder decision needed** (add to review closure) — trigger: the visible set changes, or a second agent lane appears |
| Route external capability-change requests through the MCP surface (the four change tools) instead of any direct path | The MCP capability's binding to the four change capabilities; the No-hand-authored-code policy for external clients | Not now; no external client is connected | Benefit: external agents get exactly the admitted mutation surface. Burden: client wiring + an MCP server run | **Defer** — trigger: an external MCP client is admitted |

## W5 — The circuit view (its own flywheel and multi-agent plan)

The generic live circuit — every capability's declared execution graph rendered
in real time, boxes for cells, arrows for edges, lighting from testimony — is
staged as its own record and plan rather than inferred from the rows above:
[circuit-view-flywheel.md](circuit-view-flywheel.md) (hypothesis, generality
rules, measurement, boundaries) and
[implementation-plan-circuit-view.md](implementation-plan-circuit-view.md)
(lanes CV-A…CV-E, sequencing, acceptance, rubric rows). Its first turn also
carries the repair of the layout reference
(`docs/target-harness-experience.md`, unit CV-E0).

## Measurement notes (rubric §5, where they could change a decision)

- **W1 rows**: "hours-or-less each" and "recovered immediately" are judgments
  (no measured baseline); the one real quantity is W1.1's single
  re-declaration + two preflights, which is minutes-scale.
- **W2 one-step install:** unknown install count keeps break-even unknown, and
  no per-install saved-hours or added-maintenance estimate exists, so the
  break-even range is unbounded; the decision rests on the named outcome
  (client release), which is a judgment, not arithmetic. "The pinned-DLL change
  carries the larger continuing-burden reduction" is also a judgment (SDA
  checkout removed from the client build path).
- **W3 rows** are deferred on their triggers except U3/U5, which are
  re-dispositioned per the display record (Needed now / Useful now); none blocks
  W1/W2, but "deferred on triggers, not benefit doubts" does not apply to U5.

## Review closure (rubric §7)

- Proposed by this session (2026-09-17); audited 2026-09-17 against the rubric
  with a factual-claim audit and a coherence audit, and corrected here
  (dispositions W1.2, W1.3, W3.2, W3.3, W3.5–W3.7, W4.1, W4.3; rows added for
  `deliver-capsule-estate-mcp` and `carry-consumer-authority-context`; request
  register and measurement labels). Reviewer: pending; scope: W1–W4 of this plan.
  A later change to a recorded disposition needs a new entry, not an edit.
- Beyond routine delegation (review or builder decision before execution):
  W1.2 (visible in the recording), W2.1 (a new manifest/digest receipt schema),
  W2.2 (the reference scheme), W3.3 (re-disposition of the display record's U3/U5),
  and W4.3 (a declared change to the lane's capability and request contract —
  builder decision).
- Appended observations replace predictions as units land: record each unit's
  commit, its first-executable time and its verified outcome in the unit's own
  doc, then mark the row here; keep the initial prediction beside it.
