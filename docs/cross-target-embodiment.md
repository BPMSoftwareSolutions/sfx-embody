This records what supporting a second and third target actually requires, and the one thing that turned out to block it. It is written against the pinned platform commit `6fcb8b34`. Where an artifact exists only on an unpinned platform branch, this says so; nothing here claims that branch's work is in force.

## The database already answers the question

Target readiness is declared, not guessed. For every Capability in `config/selections/`:

| Target | Requirements | Open | Readiness |
| --- | ---: | ---: | --- |
| node | 188 | 0 | `CAN_ATTEMPT_EMBODIMENT` |
| python | 188 | 154 | `NOT_OBSERVABLE` |
| csharp | 188 | 154 | `NOT_OBSERVABLE` |
| cpp, go, java | 188 | 158 | `NOT_OBSERVABLE` |

Every one of the 154 open requirements for python and csharp carries the same diagnostic, `EXACT_MECHANIC_TARGET_BINDING_NOT_ESTABLISHED`, at repair boundary `DECLARATION_AND_BINDING_EVIDENCE`. They resolve to 13 distinct mechanics for that Capability and 32 across the estate. The materializer's `NODE_BINDINGS_HELD` is that declaration being honoured; it is the system working, not a defect to route around.

## What already exists for python and csharp

More than expected. The platform carries, for both languages, a Scenario Kernel, a structural projection provider under `artifacts/tools/dist/projection/providers/`, and a projection profile. Contract projection is therefore not the gap. Only the semantic transformation evaluator and its registry are missing, and beneath them, the thing that would tell anyone what to implement.

## The chain, and the layer that owns the defect

| Layer | State at the pinned commit |
| --- | --- |
| 0. Declared mechanic conformance vectors | **Absent.** 36 mechanics declare a `conformanceRef`; none resolved; the directory did not exist |
| 1. Python and C# transformation evaluators | Absent; only typescript/node has one |
| 2. Per-language mechanic registry authority | Only `node-mechanic-registry.authority.v1.json` |
| 3. Database mechanic-to-target bindings | Held, as above |
| 4. sfx-embody target neutrality | Node-specific materializer, projection and reveal |

The intent's law decides the order: *repair the lowest authoritative layer that actually owns the defect, and never manufacture semantic authority to justify physical output.* Layer 0 owns it. Writing a Python evaluator before those vectors exist means choosing, without authority, what each mechanic means.

## Why layer 0 is not a formality

The declared `meaning` is prose. It settles most mechanics and leaves open exactly the questions where two targets diverge. Probing the selected Node provider against a natural Python or C# reading, 16 of 20 probes disagreed. Three examples:

- `equals` declares *"Strict equality of evaluated operands."* On two objects that is either reference identity or deep structure. Node gives reference identity, which cannot survive a language boundary; Python's natural reading gives deep structure. The word "strict" does not choose.
- `if` declares that *"an empty string, zero, and an empty value are false."* Node treats `[]` and `{}` as **true**, contradicting its own declaration. Python and C# read it the declared way naturally.
- `format` coerces through JavaScript's `String()`, so absence renders `"null"` and a composite renders `"[object Object]"`. No other target produces those strings.

Copying the Node evaluator into Python would have carried all of this across as if it were meaning, and Cross-Apply would then have compared Node against a translation of Node rather than against declared authority.

## The rulings were measured, not preferred

Before deciding any contested point, the retained corpus was instrumented and replayed across all 17 fixtures. What reaches each mechanic:

| Mechanic | Operands observed | Consequence |
| --- | --- | --- |
| `equals` | 1562, all string, number or boolean | Refusing composite operands changes no observed behaviour |
| `length` | 124, all arrays | Restricting to array and string changes nothing |
| `format` | 88, all strings | Pinning the coercion table changes nothing |
| `greater-than` | 8, all numbers | Requiring one ordered type changes nothing |
| `json-stringify` | 1473 objects, **zero** with integer-like keys | JavaScript's integer-key reordering is not load-bearing |
| `if` | 462 evaluations, 67 with a path predicate, all resolving to booleans | Empty-collection truthiness changes **zero** port outcomes |
| `unique`, `join` | never invoked | Unconstrained by observation |

So the strict rulings cost nothing against the current estate. That is the point of measuring first: it separates a ruling that tightens meaning from a ruling that changes behaviour.

## What was produced, and where it lives

On platform branch `embody-python-csharp-mechanics`, based on `6fcb8b34` and **not pinned**: 157 vectors across the 32 mechanics that have an observing embodiment, a runner that tests any target's evaluator, and 17 recorded decisions. Each decision states the question, the ruling, the rationale and the measurement that grounded it. Of the four mechanics excluded, three declare in their own authoring notes that no embodiment observes them; `bind-path` has no observing embodiment at all.

Running the existing Node evaluator against those vectors:

| | |
| --- | ---: |
| Vectors passed | 133 / 157 |
| Mechanics conformant | 16 / 32 |

The 24 failures are real and fall into three families: absence represented as a second empty value, a silent answer where the declaration admits no operand, and empty collections treated as true.

## Step 1 — the Node evaluator repair

The Node evaluator on the branch is now repaired against those vectors: `157/157` vectors pass and all `32/32` mechanics are conformant (`4f727b2`, "Bring the Node transformation evaluator into conformance with the declared mechanic vectors"). The contested mechanics delegate to named helper declarations in the evaluator module, so an embodied port ships the same bytes the provider executes.

The prediction that the 17 fixtures do not move was verified, not assumed. An experimental run of the full sfx-embody verification against the repaired branch — with the Node lowering, inverse reader and mutation set adapted to the declared semantics — passed with byte-identical fixture outcomes across all 10 Scenario bodies: 17/17 fixtures, 320 kernel observations, 994 expression regions, 64 native port comparisons, the 200-vector corpus, and the contract gate unchanged at 2337 assignments, 976 required rejections and 25764 runtime vectors. Those sfx-embody adaptations live on branch `cross-target-step-1` (`a596d0e`) and are deliberately not on main: main still materializes against the pinned commit, where the old provider semantics are the truth, and the adaptations land together with the re-pin.

## What this changes about the existing evidence

Nothing already claimed becomes false, but one distinction now has to be stated rather than assumed.

The 200-vector differential corpus in `verify-native-projection.mjs` establishes that the **lowering agrees with the selected provider** — same result, same scope mutation, same failure. It does not establish that either conforms to declared mechanic meaning, and at 16 of 32 the provider does not. Both statements are true at once: the Node bodies faithfully embody the provider they were resolved to, and that provider diverges from the declared meaning in 24 measured ways. Cross-Apply needs the second property, which is why layer 0 had to come first.

`audit:lowering` continues to report `DECLARED_CONFORMANCE_REFERENCES_NOT_CLOSED` across 21 mechanics — the subset of the 36 conformance-ref mechanics that the three selected capabilities actually use, since the audit is scoped to retained lineage. That remains correct at the pinned commit, and will stay correct until the platform branch is merged and re-pinned.

## Remaining, in order

1. ~~Repair the Node evaluator against its vectors — 24 fixes.~~ Done on the platform branch: 157/157 vectors, 32/32 mechanics conformant, and the 17 fixtures verified not to move. See Step 1 above.
2. Write the Python and C# evaluators against the vectors rather than against Node.
3. Per-language mechanic registry authority, then the database bindings, which is what moves readiness off `NOT_OBSERVABLE`.
4. sfx-embody target neutrality, so the target is data rather than a branch in the materializer.
5. Re-pin the platform in one step, and re-establish the platform digest boundary against the new bytes.

Two consequences are already known. Adopting the declared `if` ruling means the Node lowering must emit an explicit truthiness helper instead of a bare conditional, which touches both the projection and its inverse reader — developed and experimentally verified as part of Step 1, on branch `cross-target-step-1` until the re-pin. And re-pinning changes the platform digest recorded in every receipt, which is the step deliberately deferred to last.
