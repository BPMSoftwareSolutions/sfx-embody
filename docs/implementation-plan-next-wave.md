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

**The one question per row (rubric §4):** if this decision is omitted from its
wave, which intended behavior fails, and why?

## W1 — Close the circuit for the recording (Needed now)

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
|---|---|---|---|---|
| Remove the temporary `diagnostic` field from `shape-agent-refusal-evidence` (authored in `declare-agent-capability.sql`; flagged in `agent-lane.md`) | Builder intent: "remove it before recording"; the refusal contract (`agent-refusal-evidence.v1`) is the recorded artifact | Omitting it ships debug vocabulary in the demo's expected output and in the contract consumers read | Benefit: the refusal receipt states exactly what is claimed. Burden: one transformation re-declaration + preflight (both objectives) + note; minutes | **Needed now** |
| Beat 1 provider line in the declared display (`EXECUTION TESTIMONY / provider …`), the "one tiny detail" from the target experience | The display decision ("the display is 1") — the reading is declared rows, not terminal code | Omitting it leaves the recorded Beat 1 frame without the route attribution the target experience asks for; the identity exists only in testimony | Benefit: OUTCOME MEANING ≠ PHYSICAL PROVIDER TESTIMONY becomes visible in the frame. Burden: one display-transformation change + verify; small | **Useful now** (revisit only if a second display consumer changes the reading) |
| Record the D1 provider-access decision as observed: the primary 429 is the fallback trigger | `sidefx-public-demo-readiness.md` D1; observed receipts (primary `retained-non-success` `exchangeCount: 1`, real-time1 answers) | Omitting it re-opens an already answered question at recording time | Benefit: no credential renewal needed; the degraded path is the story. Burden: none beyond the record | **Needed now** (doc row) |
| Final command pass against `demo-commands.md` verbatim (three beats, PowerShell and cmd quoting) | The doc is the recorded script; B6 discipline ("the surface wins") | Omitting it risks a recorded command that does not run as written | Benefit: recording confidence; catch quoting drift. Burden: one read-through with live runs; small | **Needed now** |

## W2 — The release flywheel (Useful now)

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
|---|---|---|---|---|
| One-step install: `scripts/install-projected-csharp.mjs` (project → `dotnet publish` both emitted projects → install root → fixture run; manifest + digest receipt) | `projected-csharp-install.md` "Flywheel shape"; builder intent: "a true release process for a client machine" | Omitting it keeps the install as three manual steps per capability, on the critical path of every client release | Benefit: removes manual `dotnet publish` invocation and path drift; names the artifact set. Burden: one script + receipt schema; hours. Reversibility: delete the script, no data impact. Break-even: unknown install count; the named outcome (client release) carries the decision, not arithmetic | **Useful now** (revisit when the pinned-DLL change lands) |
| Replace the build-time SDA project reference with pinned adapter DLLs so a client build needs no SDA source | Same; projection emits the reference (`ProjectedConsumer*.generated.csproj`) | Omitting it keeps the client build coupled to an SDA checkout — the opposite of the release claim | Benefit: builds from the published artifact set alone. Burden: projector/install coordination; the DLL set already ships under `providers/consumer-execution/<sha>/` | **Useful now** (requires an authoring-surface decision: emit a DLL hint or rewrite at install; builder decision if the projector must change) |
| Install the remaining demo capabilities (equity installed; compose and the routing proof next; model lane is vault/network-backed and installs fixture-only) | `projected-csharp-install.md` artifacts; each install is a row of evidence | Omitting it leaves the client surface at one capability | Benefit: the installed set becomes the client's capability surface. Burden: per-capability install runs; minutes each | **Useful now** |
| Cross-language performance comparison from the existing harness (`scripts/projected-performance.mjs`) over the installed set | `performance-optimization.md`; the harness already exists | Omitting it leaves "same capability, different provider realization" unquantified for client planning | Benefit: medians per target on one machine. Burden: run + report; small | **Defer** (trigger: a client packaging choice needs the numbers) |

## W3 — Next experiences and their enabling requests (Defer with triggers)

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
|---|---|---|---|---|
| F1/F2 projected testimony timing and parity (SDA requests 7/8, filed) | `sda-change-request-projected-testimony.md`; requested by the IEA projected-target acceptance | Not for W1/W2. Omitting it keeps projected-target timing coherence untestable (the projected bodies carry no duration fields — verified) | Benefit: unlocks IEA acceptance for projected bodies and the versioned-bodies experience. Burden: SDA-side emitter change | **Defer** — trigger: F1 lands; then extend `verify:timing` to the projected targets |
| `httpStatus` in bounded provider evidence (SDA request 11, filed) | `sda-change-request-bounded-provider-evidence-http-status.md`; the rate-limit record needs the signal | Not now. Omitting it keeps 403/429/500 indistinguishable in streamed evidence | Benefit: rate-limit runs become inspectable. Burden: one bounded scalar in the kernel bound; estate allowlists are ready | **Defer** — trigger: F1 or the provider-management need; then rate-limit evidence store U1–U4 (`rate-limit-evidence-store.md`) |
| Display migration U3 (reader documents) and U5 (boot/CLI reduction: `execution-drilldown`, `observation-filter`, `semantic-address` → declared readings; telemetry authority D5) | `display-projection-decision-record.md`; `next-experiences.md` §5 | Not for the recording. Omitting it keeps declared logic in boot code (the F9 class) | Benefit: removes the remaining mislocated authority; telemetry allowlist becomes rows. Burden: multi-unit migration on the hot loader path | **Defer** — trigger: a non-CLI display consumer, or the next allowlist/reading change |
| Vault V5: rotation, macOS/Linux/cloud realizations, python/csharp ports, consent boundary | `vault-manager-capabilities.md` V5; the demo environment is vault-only already | Not now. Omitting it leaves one OS realization and no rotation | Benefit: the same semantic capability across hosts. Burden: per-language+OS provider realizations | **Defer** — trigger: a second host OS, a rotation need, or client distribution |
| Session/agent ledger; receipt-as-data; comparative eval; authority profiles (SDA R5) | `agent-lane.md` remaining; `sidefx-public-demo-readiness.md` defer list | Not now. Omitting them leaves cross-invocation attribution to a record, with no claim made | Benefit: database-derived agency receipt. Burden: ledger rows + read + grants model | **Defer** — trigger: a cross-invocation question the record cannot answer |
| Sealed bootstrap binary; backdoor-script migration; per-language bootstraps | `next-experiences.md` §1–§3; `transistor-model.md` §6/§9 | Not now. Omitting them changes no current intended behavior | Benefit: distribution without implementation exposure; script debt migrates to rows. Burden: large, cross-repo | **Defer** — triggers as recorded in `next-experiences.md` |
| `sum` display arithmetic (recorded boundary in `invisible-execution-authority.md`) | The timing reading is independently selectable today | Omitting it costs one extra selection step; no failure | Benefit: a story display could carry the timing summary directly. Burden: expression-vocabulary addition (SDA) or a boot seam | **Defer** — trigger: a story-view timing selection is actually wanted, or a second consumer needs it |

## Measurement notes (rubric §5, where they could change a decision)

- **W1 rows** are hours-or-less each; first-delivery effect is negative only in
  the recording schedule sense and is recovered immediately.
- **W2 one-step install:** unknown install count keeps break-even unknown; the
  decision rests on the named outcome (client release), not on arithmetic. The
  pinned-DLL change carries the larger continuing-burden reduction (no SDA
  checkout on the client build path).
- **W3 rows** are deferred on their triggers, not on benefit doubts; none
  blocks W1/W2.

## Review closure (rubric §7)

- Proposed by this session; review needed for W1.2 (a display change visible in
  the recording) and W2.2 (the reference scheme), which are the only rows with
  commitments beyond routine delegation.
- Appended observations replace predictions as units land: record each unit's
  commit, its first-executable time and its verified outcome in the unit's
  own doc, then mark the row here.
