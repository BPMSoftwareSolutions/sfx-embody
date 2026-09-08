Invoking one capability currently materializes the whole estate. This records what was measured, why the declared authority already forbids it, and the invariant a repair has to establish. It is written against harness estate `capsules/` at 219 capabilities and platform commit `7168110`.

## What happens now

`sfx capability invoke` reaches `materialize-authorized-file-batch` and exits 4. The contract `authorized-file-batch-materialization-request.v1` admits 4,096 entries; the caller submits **4,304** distinct targets, drawn from 6,920 carried entry occurrences and 657 runtime aliases across the entire estate. It selects the requested capability *after* that materialization rather than before it.

The batch bound is not the defect. It is the size of the request that is wrong.

## The necessary closure is two orders of magnitude smaller

Measured directly from the capsule packs:

| Capsule | Entries | Declared dependencies | Runtime bindings |
| --- | ---: | ---: | ---: |
| `resolve-sidefx-eligible-providers` | 33 | 0 | 1 |
| `adapt-job-market-intelligence-evidence` | 33 | 0 | 1 |
| `deliver-capsule-estate-cli` | 30 | 1 | 1 |

Thirty-three entries is the complete carried closure of a capability that today costs 4,304 materialization targets to invoke — about 130× the necessary work, and the only reason the 4,096 bound is ever reached. A correctly scoped request fits in one batch with the batch 99% empty.

## The declared authority already draws this line

`features/operate-capsule-estate.feature` separates the two operations into different scenarios. Invocation is bounded to one binding:

> **`@scenario:execute-capsule-carried-capabilities`**
> Given **one verified capsule runtime binding** and either a canonical input or an optional set of capability identities
> Then **runtime entries** are reconstructed into an ownership-marked disposable execution root

Whole-estate reconstruction is a different scenario in the same feature, with its own outcome variants and its own explicitly selected root:

> **`@scenario:reconstruct-and-project-capsule-estate`**
> Then canonical entry paths and shared authority are reconstructed from exact capsule bytes
> And **every eligible capability** is projected through the admitted consumer projector

So the estate already distinguishes *reconstruct the entries of the one selected binding* from *reconstruct everything*. Nothing declares that invoking one capability should perform the second. The implementation does the second when asked for the first.

It also inverts the declared order. The authority states the binding as a `Given` and the reconstruction as a `Then`: selection precedes materialization. The implementation materializes first and selects afterwards, which is what makes the request estate-sized regardless of what was asked for.

## The batch capability is not the place to change anything

`features/materialize-authorized-file-batch.feature` declares itself domain-neutral, in its own words:

> The capability is domain-neutral. It knows nothing about capsules, expansion, Reveal, repositories, projectors, or any consumer-specific layout. It neither discovers a destination nor grants authority to one. **The caller supplies** the target root, relative target paths, exact base64 bytes, expected SHA-256 digests, and per-target existence policy.

Its root scenario is *"Materialize **one** authorized batch."* Scope is therefore entirely the caller's decision, and 4,096 is a bound on a single batch, not a budget for a session. A caller needing more composes batches; a caller needing 33 entries sends 33.

Raising the limit would be the failure this estate's law names directly: adding physical permission to justify output that semantic authority never asked for. It would also leave the 130× intact.

## The principle

The unit of expansion is the integrated circuit of capabilities that depend on each other to achieve one objective — the selected capability's runtime binding together with its transitive declared dependencies, and nothing else. A capability that no declared dependency edge reaches is not part of the objective and has no business being written to disk to serve it.

The estate already carries this as data. Each capsule declares `runtimeBindings` and `declaredDependencies`; the closure is a walk over those edges from one root, exactly as the Scenario invocation closure is a walk over declared invocations. It does not need to be discovered, inferred, or approximated.

**Goal.** Materialization for an invocation is bounded by the declared dependency closure of the selected capability, and that bound is derived from the estate's own declarations rather than from a batch limit that happens to stop it. Selection precedes materialization, so the size of the request is a function of what was asked for and not of how large the estate has grown. A closure that cannot be resolved is a hold, not a reason to materialize more. Whole-estate reconstruction remains available where authority declares it, and never as a side effect of invoking one capability.

Two consequences follow. The 4,096 bound stops being load-bearing — it should stop being the thing that fails, and a request that legitimately exceeds one batch composes batches, including its error and disposable-root release paths. And the regression input has to be the real 219-capability estate: the existing single mocked listing fixture cannot show the difference between a bounded closure and an unbounded one, because both pass it.

## What this does not change

No contract limit, capsule, feature authority, or generated implementation should be patched to make the current request fit. The repair belongs to the provider realizing `execute-capsule-carried-capabilities`, which is the layer that chooses what to submit. `materialize-authorized-file-batch` is correct as declared and stays untouched. So does the 4,096 entry bound.

## Provenance of the numbers

The entry counts, the two feature declarations quoted above, and the domain-neutrality statement were read directly from `capsules/*.sfxcap` and `features/` in the harness estate. The 4,304 / 6,920 / 657 figures and the exit-4 behaviour come from a read-only replay of the invocation path performed alongside this analysis and recorded in the harness at `docs/cli-estate-invocation-2026-09-08.md`; they are cited here rather than independently re-measured.

Related: the embodiment side of this question is already settled — four `resolve-sidefx-eligible-providers` fixture outcomes are deeply equal between direct bootstrap invocation and the database-derived Node embodiment across 28 outcome assertions, with repeated runs deterministic. Runtime parity is established. CLI invocation is what remains blocked, and this closure is what blocks it.
