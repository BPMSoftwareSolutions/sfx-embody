This is a review of the current Node embodiment implementation described in [native-embodiment-repair.md](native-embodiment-repair.md). Each finding states what the code does now and a goal for the property the solution should establish. The goals are architectural obligations, not patches: they name the invariant that should hold afterwards, so a fix can be judged by whether the invariant holds rather than by whether a particular line changed.

Nothing here contradicts a retained result. The findings concern the integrity boundary around those results, the strictness of the oracles that produce them, and the fields that carry them.

## What the review verified

`npm test` passes 4/4. `npm run audit:source` runs without the database and re-hashes all 465 planned body files against their plans with no drift, so the tracked bodies match their retained plans. The implementation digest in [native-embodiment-repair.md](native-embodiment-repair.md) and in `evidence/regression-results.json` both recompute to `sha256:a81932af…` from the current source. The headline totals (17/17 fixtures, 64 native port comparisons, 320 kernel observations, 994 expression regions) match the retained totals exactly. `npm run verify:estate` was not re-run; it requires the loaded database workspace and the pinned SDA checkout.

## What holds

The load-bearing risk in this design is that [native-expression-projection.mjs](../src/resolvers/node/native-expression-projection.mjs) re-authors each mechanic as a lowering arm rather than lowering the selected provider's own body. Equivalence therefore rests entirely on the differential corpus. The corpus is built for that job and reaches the divergences the design actually creates:

| Divergence the lowering could introduce | Vector that closes it |
| --- | --- |
| Chained `replaceAll` re-substitutes an injected placeholder; `$&` is a live replacement pattern | [verify-native-projection.mjs:63](../src/verification/verify-native-projection.mjs#L63) |
| `equals` lowers to `===`, which is reference equality on objects | [:43-48](../src/verification/verify-native-projection.mjs#L43-L48) |
| `path` lowers to optional chaining, turning a throw on a missing intermediate into `undefined` | [:37](../src/verification/verify-native-projection.mjs#L37) |
| An unresolved `from` yields `undefined` instead of holding | [:39](../src/verification/verify-native-projection.mjs#L39) |

The comparison at [:100](../src/verification/verify-native-projection.mjs#L100) uses `observeGraph`, which distinguishes prototypes, reference identity, `-0` and post-call scope mutation. The independent anchor is [:151](../src/verification/verify-native-projection.mjs#L151), comparing the revealed expression against digest-checked database bytes rather than against lineage. The whole-expression structural comparison at [:178](../src/verification/verify-native-projection.mjs#L178) and the single-class, single-return constraints at [:154-173](../src/verification/verify-native-projection.mjs#L154-L173) leave no room for unmapped executable code in a port body. These parts need no goal; they are the standard the rest should meet.

## Finding 1 — The platform pin does not cover the tools that shape the output

[materialize-node.mjs:46](../src/materialize-node.mjs#L46) checks `tools/src`, `languages/typescript` and `package.json` for modification against the pinned commit. The Gherkin parser, scenario graph builder, transition graph builder, type graph builder, target projection graph builder and structural projection provider are all loaded from `artifacts/tools/dist/…` at [:49-51](../src/materialize-node.mjs#L49-L51) and [:102-104](../src/materialize-node.mjs#L102-L104), which no checked path covers. `git diff --name-only` also does not report untracked files, so a newly added file inside a checked path passes as well.

A modified or added built tool therefore passes the commit check and silently shapes every generated body. The README states that the materializer verifies the selected source revision and source digests; that is true of the copied kernel and false of the compiler chain.

**Goal.** The set of platform files the materializer reads and the set it verifies are the same set, and that set is derived rather than declared twice. Verification should follow from the act of loading — a platform artifact becomes part of the integrity boundary because the materializer read it, not because a path list was maintained in parallel and happened to mention it. Untracked and modified files are equally disqualifying, because both mean the bytes in use are not the bytes the pin names. A platform whose readable surface cannot be established this way is a hold, not a warning.

## Finding 2 — The differential oracle compares failures only by error name

[verify-native-projection.mjs:87](../src/verification/verify-native-projection.mjs#L87) captures a throw as `{ error: error.name }`. Several vectors exist specifically to drive throws — `length` of `null`, `JSON.parse('{')`, `includes` on `null`. Two `TypeError`s arising from unrelated causes compare as equivalent, so the lowering can fail differently from the provider and still pass.

This is the softest link in an otherwise strict oracle. Both sides execute on the same Node version in the same process, so the failure detail is stable and available.

**Goal.** The oracle distinguishes two executions exactly as strictly as the runtime does, and applies the same standard to failures as to values. A vector passes only when the lowering and the selected provider are observationally indistinguishable — a failure is a result, carrying its own identity, and equivalence of failure is a claim that must be earned rather than assumed from a shared class name.

## Finding 3 — Retained evidence carries counters that cannot become non-zero

`mechanicClasses` and `mechanicInvocations` are always `0` in the regression totals: [verify-node.mjs:78](../src/verification/verify-node.mjs#L78) declares `mechanicClassCount` and never increments it, and [:167](../src/verification/verify-node.mjs#L167) hardcodes `mechanicInvocations: 0`. `nativeChecks` at [:106](../src/verification/verify-node.mjs#L106) is never appended to, so every `conformance.json` reports `nativeBodyChecks: 0`. [:26](../src/verification/verify-node.mjs#L26) passes `observeMechanic` into `createScenario`, whose generated signature is `({ observer, clock })`; the argument is dropped and `mechanicObservations` is empty in every fixture record.

These are vestiges of the retired mechanic dictionary. In a document meant to be read as proof, a zero with no path to being non-zero is worse than an absent field: it reads as a check that ran and found nothing.

**Goal.** Every field in retained evidence is produced by a check that could have failed. The evidence surface is derived from the checks actually performed, so a retired check removes its field rather than leaving a zero behind, and a reader can treat any present counter as a live measurement. Fields that record deliberate absence say so in their own vocabulary, as `NOT_PROVEN` and `NOT_REQUESTED` already do.

## Finding 4 — The root binding is supplied by a parameter default rather than by the composition

Generated ports are `execute(input, root = input)` ([consumer-object-provider.mjs:174](../src/resolvers/node/consumer-object-provider.mjs#L174)) and are called as `execute(<state>, context.rootInput)` at [:176](../src/resolvers/node/consumer-object-provider.mjs#L176). At a root scenario `context.rootInput` is undefined, so `root` falls back to the first argument. That argument is `input` only for the first operation; for a port at ordinal 1 or later it is the preceding operation's result.

This is correct today only because all ten scenarios place their port at operation 0. The first authority that orders a port after a child invocation would bind `root` to the wrong value with no diagnostic, and the differential vectors would not catch it because they exercise the lowering, not the composition.

A second question sits behind it. [:215](../src/resolvers/node/consumer-object-provider.mjs#L215) sets `rootInput: structuredClone(input)` on every child invocation, so inside a child `root` denotes that scenario's own input rather than the capability's root input. Whether that matches the declared meaning of `root` in the transformation authority should be settled explicitly rather than inherited from the current call shape.

**Goal.** `root` has one meaning, traceable to authority, and the composition supplies it explicitly at every invocation depth. No binding that authority can reference is ever produced by a language-level default that substitutes a different value when the caller omits it — an omitted binding is an error in the generated composition, not a silent substitution. The generated body should be verifiable against the declared meaning of `root` independently of which ordinal the port happens to occupy.

## Finding 5 — Native code enters bodies through two boundaries with one rule

[consumer-object-provider.mjs:201](../src/resolvers/node/consumer-object-provider.mjs#L201) emits every import declaration from the selected mechanic source unconditionally. `copyRuntime` ([materialize-node.mjs:119-133](../src/materialize-node.mjs#L119-L133)) enforces `NATIVE_IMPORT_OUTSIDE_PLATFORM` for the kernel copies, and only the single sibling `native-mechanic-primitives.mjs` is copied into the body ([:136-137](../src/materialize-node.mjs#L136-L137), [:149](../src/materialize-node.mjs#L149)).

The asymmetry is visible in the current output: the emitted `native-mechanics.mjs` imports `valueAt` and never uses it, because the only exported helper is `crypto`. It resolves today. A provider import of anything other than that one sibling would emit an unresolvable body with no diagnostic at generation time.

The verification harness has the mirror-image gap. [verify-native-projection.mjs:84-85](../src/verification/verify-native-projection.mjs#L84-L85) reconstructs helpers with `new Function` over function declarations only, so an imported helper is not modelled and a helper calling a sibling helper would not resolve. The vectors exercise a reconstruction that is not the shipped helper closure.

**Goal.** One boundary rule governs all native code entering a body, applied wherever code is copied or emitted. Every import a generated body contains resolves to a file the materializer placed in that body, and generation holds when it cannot. The differential harness executes the helpers the body actually ships rather than a reconstruction of them, so helper fidelity and helper behaviour are established over the same artifact.

## Finding 6 — The reveal's sensitivity is measured at one site by one operator

[verify-native-projection.mjs:179](../src/verification/verify-native-projection.mjs#L179) is `body.replace(' === ', ' !== ')`. `String.prototype.replace` with a string pattern mutates the first occurrence only, and a body containing no ` === ` records `mutationRejected: null` and runs no check at all.

The claim in [native-embodiment-repair.md](native-embodiment-repair.md) that equality mutation checks fail when the emitted operator changes is accurate for what runs. What runs is one operator at one site, which is weaker than the reveal's actual coverage and does not establish it.

**Goal.** The reveal's sensitivity is measured against a declared mutation set that covers each operator and structural form the reveal claims to detect, and the coverage of that set is reported as evidence rather than inferred. A body that admits no mutation from the set is a gap in the measurement and is reported as one, so the strength of the reveal is a number that can be read rather than a property that must be assumed.

## Finding 7 — Smaller items

`used` in [consumer-object-provider.mjs:152](../src/resolvers/node/consumer-object-provider.mjs#L152) is populated at [:169](../src/resolvers/node/consumer-object-provider.mjs#L169) and never read.

`mechanic-lineage.json` is written at [materialize-node.mjs:164](../src/materialize-node.mjs#L164) filtered by `scenarioId`, then wholly overwritten at [:190](../src/materialize-node.mjs#L190) filtered by `physicalFile`. The first content is discarded. `transformation-authority.json` at [:169](../src/materialize-node.mjs#L169) still uses the first filter, so the two files describe different port sets if the filters ever disagree.

`@estate_model_pk` appears in the query text at [read-authority.mjs:12](../src/read-authority.mjs#L12) and [audit-lowering-evidence.mjs:18](../scripts/audit-lowering-evidence.mjs#L18) but is never bound at either call site, which pass only `rowLimit`. The parameter resolves from ambient state inside the database reader, invisible where the query is read.

**Goal.** Each generated artifact is produced once, from one filter, and two artifacts describing the same thing derive from the same expression. Every query parameter is bound where the query is written, so the selection a query depends on is legible at the call site rather than resolved from reader state. State that is written is read.

## Calibration of the current claims

The existing documentation is unusually disciplined: `embodimentRoundTrip`, `databaseRoundTrip` and `crossApply` are carried as `NOT_PROVEN` into every receipt, and the limits of finite vectors are stated where they apply. Two statements reach slightly past what runs.

All 994 expression regions recover their transformation authority — true modulo `comparableExpression` at [reveal-native-expressions.mjs:207](../src/reveal-native-expressions.mjs#L207), which normalizes empty path segments away before comparing. Path semantics is verified against the selected provider, but path spelling is not recovered exactly, and `pathSpelling` is retained in lineage precisely because it is not.

The 994 counts regions across ten physical bodies that embody ten transformations, each independently revealed. The count is defensible as a count of verified regions and reads as a count of distinct ones.

**Goal.** Every headline number states its unit and the normalization it tolerates, so a reader arrives at the same interpretation as the code without opening the code. Where a comparison is deliberately modulo something, the claim names what it is modulo and where the un-normalized form is retained.

## Priority

| Order | Finding | Why first |
| --- | --- | --- |
| 1 | Platform pin coverage | The only finding where a wrong result could be produced and retained as correct |
| 2 | Failure comparison strictness | Cheap, and sharpens every negative vector in the corpus at once |
| 3 | Dead evidence counters | Evidence is the product; fields that cannot fail devalue the ones that can |
| 4 | Root binding | Latent, and will bite on the next authority shape rather than announcing itself |
| 5 | Native code boundary | Currently benign, fails without diagnostic when it stops being benign |
| 6 | Mutation coverage | Measurement gap, not a defect |
| 7 | Smaller items | Legibility and single-writer hygiene |
