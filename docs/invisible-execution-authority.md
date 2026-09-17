# Invisible Execution Authority (IEA) — the time test

**Status.** Named 2026-09-17 from a live receipt on
`request-capability-from-objective`. This is the temporal face of ungoverned
intelligence debt (UID): UID is meaning that lives outside declared rows; IEA
is **execution time that no declared cell accounts for**. Both are found the
same way — by asking the circuit to show its work.

## The test

For consecutive streamed events, take the elapsed wall time between them and
subtract the execution time the completing cell (or declared delivery phase)
reports:

```text
gap(e_n, e_{n+1}) = t(e_{n+1}) − t(e_n)
attributed        = duration reported by the cell completing in that window
IEA               = gap − attributed        (above measurement noise)
```

If every gap closes against a declared cell duration or a declared delivery
phase, the invocation is **timing-coherent**: the circuit accounted for its
time. Any positive unattributed delta is the signal — the lights turn on for
where authority is invisible: work with no cell (process spawns, boot-side
logic, side-channel calls), effect providers that omit duration, clock
inconsistency (negative gaps), or an altitude whose work is simply not
streamed (hidden, not missing).

## The first receipt (2026-09-17)

`sfx capability observe request-capability-from-objective --input …` at
story-first altitude showed a ~5 s hole after
`project-model-response-policy-to-provider-protocol` — a 0.06 ms entry — which
reads as if the projection cost seconds. The same invocation with `--trace`
(9.58 s span) attributes every second:

| Window | Attributed to | Duration |
|---|---|---|
| delivery setup | `readExecutionDelivery` + `readAuthority` phases | 132 + 376 ms |
| credential resolution | `bind-gemini-os-credential-port` (vault) | 849 ms |
| **the model call** | **`obtain-governed-model-response-port`** (generic LLM connector → Gemini) | **6 170 ms** |
| admitted execution | `resolve-proposed-capability-port` (declared read) | 83 ms |
| equity branch | `resolve-equity-market-price-evidence` exchange operations | 234 + 877 ms |
| projection | `project-model-response-policy-to-provider-protocol` | 0.07–0.11 ms |

So the receipt is two-sided: **IEA = 0 once the trace altitude is on** — every
gap closes against a declared cell — and the story-first view *hid* ~7 s of
declared work. The hidden altitude was the presentation defect; the IEA test is
what makes it obvious.

The retired `agent-delivery.mjs` composition is the counter-example: its
prompt-building, spawn, parse and decision time lived between deliveries, with
no cell to report it — under this test that time would light up as IEA at any
altitude, which is exactly the debt the declared capability removed.

## Rules

1. **Attribution is a claim, not a measurement.** The gap method does not prove
   who executed; it proves that *something* executed that the declaration does
   not account for. The next step is always to find the cell — or declare the
   work.
2. **Hidden is not missing.** A non-streamed altitude hides declared work; the
   fix is presentation (stream the altitude) or the declared reading, not a
   kernel change. Missing duration on a reported cell is a kernel/provider
   defect (the timing fields exist in all six languages).
3. **Measurement is already declared.** Every cell testifies
   `startedAt`/`completedAt`/`durationMilliseconds`; the coherence check is a
   reading over that testimony, not new instrumentation. Clock skew across
   processes is bounded by comparing only streamed events of one invocation.
4. **Timing coherence belongs in acceptance.** Every streamed invocation should
   close its gaps: attributed cell time + declared delivery phases + measured
   overhead ≈ wall span, with every residual gap named or zero.

## Implementation (units)

| Unit | Class | Shape |
|---|---|---|
| Terminal gap display | boot/presentation | print the elapsed gap since the previous streamed entry (e.g., `(+6.17 s)`) so holes are attributed in the story view |
| Declared timing reading | data (1) | a reading over testimony: top contributors and attributed totals per altitude; the capability's display configuration selects it, the terminal renders it |
| Timing-coherence acceptance | verification | the estate's fixture/conformance runs assert gap closure for the capabilities they exercise |
