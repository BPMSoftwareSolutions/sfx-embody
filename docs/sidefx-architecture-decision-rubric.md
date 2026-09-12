# SideFX Architecture Decision Rubric

Team review baseline · revised 2026-09-11

Purpose: account for architectural decisions by their authority, present necessity, and positive and negative effects on the builder's intended flywheel.

This document establishes the review baseline proposed for the scaffold-generation operationalization and subsequent architecture decisions. The minimal-scaffold constraint records the builder's explicit direction. The scoring scales and implementation details remain review proposals, not admitted platform policy. Saving, citing, or reusing this document does not expand their authority.

The [implementation plan](scaffold-generation-operationalization-plan.md) records the local source inspection performed on 2026-09-11 and the concrete capability changes proposed from it. Its observations replace the original draft's assumption that implementation coverage was entirely user-reported; they do not establish current managed admission or live database behavior. This rubric owns the review method; the plan owns the proposed implementation sequence. Review adoption and any subsequent capability admission are recorded separately.

## Starting constraint: the smallest complete path to the outcome

**Builder-directed baseline:** For a feature, begin with the least functionality necessary to carry its intended Input → Event → Outcome experience through to an observable result, within applicable existing constraints. Include zero, one, or multiple providers according to what that outcome requires.

The outcome determines the scaffold's scope. A provider connection is an implementation step when needed; its presence or successful response alone does not establish the intended outcome. Reuse the applicable definitions, declared mechanics, execution authority, and available implementation. Minimality does not authorize dropping required steps, inventing a different execution topology, or presenting a partial interaction as a completed result.

The first executable demonstration may use a declared fixture at an unresolved boundary. It must say which work was simulated and which outcome obligations remain unproven. **Executing the declared Input → Event → Outcome path with validated input and output proves that tested contract path; it does not by itself establish the promised behavior or external effect.** Geometry and output shape alone do not prove execution. For a provider-free transformation, real execution and behavioral assertions may establish the intended outcome. For an external booking, a simulated confirmation establishes neither the booking nor provider conformance.

Preserve the target circuit and all required mechanic references while choosing the first realization. A deferred mechanic stays visible with its reason and revisit condition. Execute an available, compatible, authorized mechanic when it can supply the work; use simulation only at an explicitly identified boundary. When a test deliberately isolates an available provider, record that purpose. Do not use an empty or preserving transformation as evidence that unresolved domain behavior has been supplied.

This scaffold choice is the first architectural decision accounted for by the rubric. Record its authority, its relationship to the feature's flywheel, the smallest sufficient path, and its expected effects. A bounded scaffold should shorten the path to credible use and reduce speculative commitments; its trade-offs may include limited coverage and later adaptation work. Check those predictions against actual delivery and subsequent use.

Evaluate consequential additions as they arise. Every addition should identify a present outcome dependency, an applicable requirement, or a proportionate benefit to the chosen flywheel. The initial decision does not require designing the eventual full architecture. Complete accounting for decisions actually made; do not manufacture hypothetical decisions to fill the ledger.

In this approach, domain-driven design and development remain connected through the same outcome:

| Part of the work | Contribution to the loop |
| --- | --- |
| Domain understanding | Establish the feature's meaning, existing vocabulary, relevant boundaries, and recognizable outcome. |
| Initial scaffold decision | Choose the smallest executable path that preserves that meaning; apply the rubric to this choice. |
| Development | Realize the path and account for materially consequential decisions as they are made. |
| Observed use | Compare actual outcomes and side effects with predictions, then justify the next change under the same authority rules. |

The resulting architecture is the accumulation of justified commitments at this stage. Further structure becomes warranted when actual needs, evidence, or applicable obligations support it. This feedback can refine the domain understanding as well as the implementation; it is not a separate comprehensive architecture phase before any useful execution.

## 1. Put the intended experience first

For each application, state its own Input → Event → Outcome experience and intended user. The diagram interaction below is the original builder-directed example, and remains the scope anchor when implementing that experience. It does not impose a diagram UI on every capability or make UI development a prerequisite for the scaffold-generator pilot.

- **Input:** A user selects a declared diagram component. Its input form expands from the component using the applicable existing input definition. The user supplies the required data.
- **Event:** The user submits. The form returns into the component, and the request executes through the applicable established execution path. The interaction communicates the real execution state.
- **Outcome:** The component presents the actual result or failure clearly enough for the user to understand what happened and what to do next.

The expanding form and return into the diagram are part of this experience. A review should account for their implementation cost while preserving the builder's intent. An animation's completion cannot stand in for execution success.

The proposed first slice is one component, its applicable input definition, its established execution path, and a visible result. That path may involve zero, one, or multiple providers as required; one component does not imply one provider. Verify what already works and address the concrete gaps. Broader component coverage belongs in the slice only when supported by the intended demonstration or existing applicable requirements.

**Proposed flywheel hypothesis:** A credible execution makes the blueprint useful to someone. Their use reveals the next valuable scenario or friction. Reusing what was learned or built lowers the effort of delivering the next useful example, which encourages further use and feedback.

Keep the interaction loop and this hypothesis distinct. One successful demonstration proves that the interaction can work. A flywheel needs evidence that its results improve a subsequent cycle. Feedback and adoption do not arise automatically; identify the actual people and next-use opportunity when applying the rubric.

Record three observations using the existing work process:

1. Time from starting the scoped change to the first executable simulated result and, separately, the first behaviorally verified outcome, including review overhead. Record provider-backed execution when a provider is required. If a milestone has not occurred, keep it unobserved.
2. Successful authorized executions out of attempts, with the number of distinct users and the principal failure reasons. Repeated test clicks are not evidence of adoption.
3. Effort to deliver the next comparable useful example, noting exact mechanics reused, new maintenance introduced, and which reuse or learning caused a change. If no next example exists, the flywheel remains unverified.

Do not invent numerical targets before establishing a baseline or obtaining a builder target.

## 2. Extract the commitments, including inherited ones

Review architectural commitments wherever they occur in the design document: recommendations, diagrams, schemas, task lists, acceptance criteria, dependencies, and phrases such as "must first" or "all implementations use."

An impactful decision changes a boundary, behavior, dependency, source of truth, public contract, execution path, user experience, persistence obligation, or material delivery/maintenance cost. Count materially independent commitments; group duplicate assertions while preserving their source locations. Routine local details need no separate record unless their effects become material.

Vocabulary is an inspection cue. A new term may introduce a registry, lifecycle, layer, entity, or obligation. Existing terminology may acquire a new meaning or become mandatory in a new scope. A harmless label change is not automatically an architectural decision. A familiar label does not establish authorization.

For each consequential vocabulary change, record: the term, previous meaning if known, proposed meaning, obligation introduced or expanded, and authority source. Record all supporting locations once in the same decision entry. Do not create another terminology service to perform this review.

## 3. Establish authority and current applicability

Each decision identifies its source and the scope in which that source applies. Prefer the exact instruction, document section, admitted contract reference, or recorded delegation over a paraphrase such as "the architecture requires it."

| Basis | Treatment in this review |
| --- | --- |
| Explicit builder intent for the current work | Use it to define the requested result and constraints. |
| Existing applicable admitted requirement | Preserve it within its established scope; identify the requirement and the concrete implication here. |
| Existing delegated implementation discretion | Continue routine, reversible implementation choices within that delegation. Material choices are recorded without requiring approval again. |
| Agent proposal or design inference | Keep it identifiable as a proposal. It cannot establish a new binding prerequisite through repetition. |
| Historical implementation or repeated document claim | Treat it as evidence to investigate. Trace the authority and applicability before treating it as a constraint. |
| Missing or conflicting authority | Investigate the affected decision and continue independent authorized work. Escalate only a concrete conflict or commitment outside delegation. |

An authorization does not expand merely because a later document cites it. A rule admitted for another capability, environment, language, or phase needs an applicable scope connection. Likewise, this rubric does not revoke existing requirements because they are inconvenient or because their evidence has not yet been located.

For uncertain inherited claims, investigate the specific affected boundary. Continue reversible changes already covered by builder intent or delegation; an unsupported historical claim does not automatically suspend that work. Preserve existing verified constraints, and avoid changing an unresolved authority boundary until its applicability is understood. An unsupported claim cannot acquire new authority or broaden scope through the review. Request a builder decision only when the remaining uncertainty materially blocks authorized implementation; present the source conflict, concrete consequence, and smallest alternative.

Provenance survives reuse. A later document citing an unaccepted proposal must retain that status and its original source. Document presence, age, implementation presence, and user silence do not independently authorize a new durable architectural obligation.

## 4. Determine what is necessary now

Ask: **If this decision is omitted from this slice, which intended behavior or applicable requirement fails, and why?**

The answer names a specific failure and the smallest sufficient remedy. "Future extensibility," "consistency," and "best practice" alone do not demonstrate a current dependency. An actual failure of execution binding, input admission, or truthful result reporting would be relevant where the established mechanism requires those properties.

Use these working dispositions:

- **Needed now:** Omitting the decision prevents the stated experience or violates a sourced, applicable requirement. Implement the smallest sufficient form.
- **Useful now:** It improves the current experience or near-term repetition with proportionate burden, within existing authority and delegation.
- **Defer:** Its value depends primarily on a future scenario or insufficiently supported benefit. Record an observable revisit trigger.
- **Outside current intent:** It adds unsupported scope or conflicts with the requested result. Remove the proposed commitment from the current plan; this is not permission to delete existing implementation.
- **Builder decision needed:** A concrete conflict, durable commitment, or change to intent exceeds existing delegation. Prepare the reviewable choice and continue unaffected work.

A revisit trigger reopens consideration; it does not automatically approve the deferred architecture. A decelerating decision can still be necessary now. Benefit scores cannot waive actual authority or correctness requirements, and unverified risks cannot establish new requirements simply by being called safeguards.

## 5. Measure benefits and burdens separately

Use quantities where available and explicitly labeled judgments elsewhere. Unknown values stay unknown. Evaluate against the smallest feasible alternative that delivers the same intended experience.

| Measure | What to record |
| --- | --- |
| Contribution, 0–3 | **0:** no identified connection to this slice or its feedback. **1:** plausible indirect or future contribution. **2:** directly supports a named current interaction step. **3:** necessary to a named current step, or observed to improve a subsequent useful cycle. Cite which interpretation supports the score. |
| Evidence, 0–2 | **0:** untested hypothesis. **1:** inspected implementation, measurements from a relevant case, or a supported estimate. **2:** observed in the target slice or a comparable subsequent cycle. Score benefit and burden separately when their evidence differs. A user's explicit scope instruction is authority, not an empirical benefit measurement. |
| First-delivery effect | Range of hours or days added to or removed from the critical path. Separate actual measurements from forecasts. Total effort and elapsed delay are different quantities. |
| Repetition effect | Expected or measured hours saved or added per subsequent comparable example, with the workload and reuse assumption stated. |
| Continuing burden | Recurring engineering hours, operational costs in their own currency, additional user steps, and independent definitions or dependencies introduced. Record only relevant quantities. |
| Reversibility | Effort range to remove or replace the decision; affected data, consumers, contracts, and migration work. A public contract may have consequences beyond coding time. |
| Distribution of effects | Who benefits, who does extra work, and who bears failure or inconvenience. Record effects that the team's delivery metric would otherwise hide. |

These form a measurement profile. Do not add the ordinal scores to hours, money, or risk, and do not present them as a scientifically calibrated total. A high benefit judgment does not confer authority. The contribution score organizes review attention; necessity and disposition determine the current action.

For an optional investment whose effects can reasonably be expressed in engineering hours, use a transparent break-even calculation:

**Net engineering hours saved over n further examples = n × (hours saved per example − added maintenance hours per example) − extra upfront hours.**

Count design, implementation, validation, migration, and rubric overhead in the appropriate terms. Keep first-delivery delay visible separately, even when later savings look favorable. Use only credible near-term examples for n; do not assume unlimited future use. When net savings per example are positive, divide extra upfront hours by net savings per example and round up to estimate break-even. Uncertain inputs produce an uncertain break-even range.

**Arithmetic illustration, not a repository estimate:** A generic framework adds 24 hours before this demonstration. It might save 2 hours on each later example while adding 0.5 hours of maintenance per example. Its estimated break-even is 16 further examples. If only three comparable examples are in scope, it consumes 19.5 more engineering hours over that horizon and also delays the first demonstration. This supports deferral under those assumptions. An actual current requirement or different measured savings could change the decision.

## 6. Worked application to the proposed experience

These assessments are provisional. They identify what to inspect; they do not assert that the implementation or authority has been verified.

| Candidate decision | Positive and adverse effects to account for | Present assessment |
| --- | --- | --- |
| Begin with the smallest complete path to the feature's observable outcome | Reduces speculative work and brings forward credible use. Bounded coverage may require later adaptation. | Builder-directed starting constraint in this conversation; account for the initial scaffold choice and preserve applicable existing requirements. |
| Use the applicable existing input definition and execution route | Supports fidelity and avoids independently maintained definitions. Existing gaps could add integration work. | Inspect coverage and provenance; reuse where applicable. Resolve concrete gaps. |
| Expand the form from the component and return into it on submission | Delivers the explicitly requested visual continuity. Motion introduces implementation and interaction costs. | Needed for the stated experience in a bounded form; do not substitute a different workflow without builder direction. |
| Preserve established input admission, execution binding, and actual result/failure reporting | Makes the demonstration credible. Wiring may slow the first visible result. | Preserve applicable requirements and implement the smallest correct connection. Never imply execution succeeded because the animation finished. |
| Require a new generic form framework before showing one component | Could reduce work across sufficiently similar later cases; adds upfront delay and ongoing obligations. | Defer if the current fields can be expressed through existing or small local mechanics. Revisit when required cases expose a measured recurring gap. |
| Introduce a second authoritative input model for the UI | Could simplify a local renderer; adds drift, translation, and competing authority. | Prefer a derived view of the existing definition. A new independent authority requires a concrete need and authorization at the appropriate scope. |
| Operationalize the rubric inside the existing scaffold generator | Makes the minimum path, reuse basis and open obligations inspectable; adds contract and evidence maintenance. | Proposed in the [implementation plan](scaffold-generation-operationalization-plan.md). Derive concrete decisions from supplied authority and retain human judgments as attributed inputs. |
| Add a separate decision service, registry, or policy engine | Could eventually support repeated review; adds another system and authority boundary. | Defer. The design document and existing scaffold capability can carry the current decision record; revisit only on demonstrated unmet needs. |
| Reuse an old document's "all components require X" prerequisite | May reflect a valid invariant, or may preserve an unaccepted generalization. | Locate the source and scope. Preserve verified applicable requirements; do not promote repetition into authority. |

## 7. Copy into the next design document

Use one compact row per consequential decision by default. The existing design document can hold the current experience, proposed flywheel, and scope anchor once above the table.

| Decision and source location | Applicable authority and scope | Necessary now? | Expected benefit / burden | Disposition and revisit trigger |
| --- | --- | --- | --- | --- |
| [Commitment and document location] | [Instruction, requirement, delegation, or proposal] | [Concrete failure if omitted, or future benefit] | [Relevant quantities or clearly stated unknowns] | [Current action and reason] |

Add the detailed measurements below only where they could change the decision. Links can carry supporting evidence. Missing forecasts or unfilled scoring fields do not block otherwise authorized work. This is an accounting aid, not a new admission gate.

```text
Current experience and proposed flywheel:
Scope anchor / existing delegation:
Smallest feasible delivery slice:
Intended outcome and minimal execution path, including providers only as required:
Target mechanic/topology references and first-realization coverage:
What executes, what is simulated, and what remains unresolved:
Contract evidence versus behavioral/external-outcome evidence:
Reuse choice and compatibility basis; profile/binding/identity change if needed:
Baseline and next observable result:

Decision and exact source location:
Authority source, status, and applicable scope:
New or expanded vocabulary / obligation, if any:
What fails now if omitted; smallest sufficient remedy:
Positive effects / beneficiaries:
Adverse effects / who bears them:
Contribution 0–3 and reason:
Evidence 0–2, sources, and unknowns:
First-delivery effect; repetition effect; continuing burden:
Reversibility and affected commitments:
Disposition and rationale:
Revisit trigger, if deferred:
Observed result after implementation:
```

The reviewer summarizes: what is needed now, what helps now, what is deferred and why, and any concrete decision outside delegation. Preserve the initial prediction beside later observations. Merge redundant entries, avoid speculative precision, and evaluate whether this review itself materially delayed the intended demonstration.

Review effort should scale with consequence. The initial record lives in the design document. The proposed generator extension derives the reproducible parts of that record; it does not replace scope judgment, manufacture estimates, or turn optional scores into admission gates.

## 8. Apply the rubric operationally to scaffolding

The scaffold decision answers: **What is the least executable realization of this declared outcome, which admitted mechanics already provide it, and what evidence is still missing?** Use the same decision record for the initial slice and material later additions.

### Minimum responsibilities

| Position | Required accounting |
| --- | --- |
| Input | Exact input contract; how supplied data is validated; the failure path for invalid input. |
| Event | Declared responsibility, topology and mechanics; explicit transformation or fixture-backed simulation; admitted reuse and execution constraints. |
| Outcome | Exact output contract; validation result; behavioral assertions and evidence required to claim the intended result. |
| Execution evidence | Exact definitions and bindings used; what actually ran; simulated boundaries and fixture identities; failures, unresolved work and the scope of every success claim. |

Generation, execution and admission have separate meanings. A successful generator invocation means the generator returned its declared result, which may still be held. A generated shell is not an executed capability. A fixture pass is not evidence of an external effect. A database registration is not managed admission. Preserve each applicable status instead of reducing them to one green indicator.

The generator derives from the reviewed feature and conditioning blueprint. It must not choose a cheaper circuit by deleting declared branches, changing precedence, absorbing delegated responsibilities, or inventing a provider seam. If the minimal realization needs a topology change, return that concrete change to the existing design authority. A missing design, contract or simulation boundary is a bounded obligation, not an invitation to infer meaning.

### Reuse and semantic identity

Resolve applicability before comparing local implementation effort. Follow the Semantic Brain's recorded preference: `REUSE_EXISTING`, `COMPOSE_EXISTING`, `AUTHOR_PROFILE`, then `AUTHOR_NEW`; incomplete or ambiguous authority yields `HELD`. Resolve exact current authorities when implementing this preference. A text match or catalog entry alone does not prove compatibility.

| Requested change | Treatment | Evidence to preserve |
| --- | --- | --- |
| Different values within an existing contract | Reuse with parameters | Parameter validity and applicable constraints. |
| Specialization permitted by an admitted pattern | Use or author a profile through the applicable path | Pattern, allowed variation and profile compatibility. |
| Different implementation of the same promise | Bind a conforming implementation or provider | Input/output compatibility, effects, failure behavior and relevant conformance evidence. |
| Different promised behavior, effects or guarantees | Revise meaning or introduce semantic identity through the applicable path | Explicit semantic delta, affected consumers and why existing meaning cannot satisfy it. |

Do not make a new identity solely because implementation differs, or claim semantic equivalence solely because schemas match. Compose only where admitted composition and binding rules support the declared circuit. Generality and sharing permission are independent: a generic mechanic may have a proprietary implementation; a domain-specific mechanic may be reusable throughout an enterprise.

The semantic authority and its referenced definitions must collectively retain the promise, input/result contracts, failure semantics, effects and constraints. Profiles, provider bindings, conformance evidence and reuse permissions remain attached to their proper authorities. SQL retrieval must preserve those links and exact versions; being retrievable does not confer execution permission or compatibility.

### Provider seams and truthful simulation

Capability contracts and provider contracts may differ. Record both provider request/response contracts, the capability-to-provider and provider-to-capability mappings, configuration/credential references, and declared failure handling. A fixture substitutes at that same declared seam. Replacing it with a conforming provider changes realization and evidence without changing the capability's promise.

| Observation | Supported conclusion | Still required |
| --- | --- | --- |
| Output validates against its schema | Structural contract compatibility | Behavioral evidence and any promised external effect. |
| Fixture traverses the declared seam and passes assertions | The tested path handles that declared fixture | Actual provider conformance and outcome evidence. |
| Real provider returns a successful transport response | That exchange completed as observed | Validation, semantic interpretation and the feature's outcome conditions. |
| Required behavior and outcome conditions are evidenced | The scoped intended result is established | Any untested scenarios or later changes remain separately accounted for. |

Determinism applies to resolution rules and generation from frozen inputs. It does not make a live observation, filesystem state, clock or model response deterministic. Replay fixture results against pinned inputs; assess live runs using the declared invariants and retain their actual testimony.

### Review closure and continued use

The team reviews the initial scope, authority basis, target/realization mapping, reuse choices, simulation boundaries, acceptance evidence and distribution of costs together. Record acceptance or requested changes, reviewer, date and scope in the existing decision record. The present status is **proposed for team review**; no adoption or implementation result is implied by this file.

After the first slice, append observations beside predictions: time to simulated execution, time to verified outcome, exact reuse, new maintenance, who saved work and who inherited work. Compare the next useful example with the first. Adjust the rubric when evidence exposes recurring ambiguity; version any machine-readable rule changes through the capability's existing contract and authority process. A review-method change does not silently revise previously admitted capability meaning.

## 9. Work-order rubric: does this dependency serve the SQL → CLI flywheel?

This section applies the rubric to one bounded work order — [SQL → CLI: scaffold Hello World](sql-cli-work-order-001.md) — and to the artifact `docs/sql/scaffold-hello-world.sql`. Its purpose is to decide which records, bindings, generations and lifecycle steps are **necessary to close that loop**, and which are promotion machinery the loop does not require.

### 9.1 The loop, stated as observable events

1. Sidney runs a `.sql` file.
2. The unchanged CLI invokes the capability it created.
3. Observed output contains the database-defined message.
4. Sidney changes the message in SQL and re-runs.
5. The unchanged CLI observes the changed output.
6. The same SQL scaffolds another identity.

The loop closes when the observed CLI output changes as the SQL data changes, with **no capability-specific source file participating**. A step that does not change any of those six events is not part of the loop.

### 9.2 Selection rule: least work that closes the loop

Choose the least-work option that completes all six events. Review and maintenance effort count in the cost. Supporting work — schema plumbing, validation, extraction — is partial progress until the loop closes, not an alternative to closing it. This mirrors section 2.4 of the [implementation plan](scaffold-generation-operationalization-plan.md).

### 9.3 Necessity test for each dependency

For each record, binding, generation or lifecycle step, ask: **if this is omitted, which of the six events fails, and where?** Classify the answer:

| Class | Meaning | Treatment |
| --- | --- | --- |
| **Execution necessity** | The runtime read/execute path cannot resolve or run the capability without it. | Keep; it is the loop. |
| **Delivery necessity** | The caller cannot observe the outcome without it (the CLI/interface binding). | Keep; event 3 depends on it. |
| **Validation/promotion necessity** | Required only because a new generation is published (validation gates, carried membership, lineage completeness). | Keep while publishing; reconsider if a non-publishing path exists. |
| **Not necessary** | Removing it changes none of the six events. | Remove; it buries the meaning and adds review cost. |

A dependency is never justified by "the schema requires it" alone. State the failing event and the exact read/gate that fails.

### 9.4 Worked application: `scaffold-hello-world.sql`

| Dependency | Class | Evidence | Disposition |
| --- | --- | --- | --- |
| Retained capsule-source entries (`source_appearance`/`content_object` for the capability's capsule digest) | Execution necessity | `sql/diagnostics/capability-embodiment.sql` resolves the capability and returns the retained source; `src/materialize-node.mjs` builds the body from those bytes. | Keep. |
| One lineage row: capability definition → observation → capsule appearance | Execution necessity | `capability-embodiment.sql` resolves the capsule digest only through `source.source_lineage`. | Keep exactly one. |
| Additional lineage rows (scenario, faces, port, transformation, execution authority, expression tree) | Validation/promotion necessity | Only `source.validate_model` gate `G_LINEAGE_MEMBER` reads them; the invocation read path does not. | Needed only because publication validates. |
| New `source.estate_model` BUILDING + membership carry + `source.publish_model` | Execution necessity **for a new capability** | The read path pins `source.current_model`; `model.guard_estate_capability` throws `PUBLISHED_MEMBERSHIP_IMMUTABLE` on inserts into a PUBLISHED model. | Required by the current read path (see 9.5). |
| Interface binding to `sda-json-cli.v1` | Delivery necessity | Platform provider `ScenarioKernel.NodePlatform.Interface.JsonCli`, operation `deliverArtifact(outcome, destination = process.stdout)`. | Keep; event 3 depends on it. |
| Port binding to `sda-authority-transformation-port.v1` | Execution necessity (value-producing path) | The execution authority is read from the capsule; the transformation produces the outcome the delivery writes. | Keep for a value-producing capability. |
| Parameterized `@CapabilityId` / `@Message` | Loop quality (events 4–6) | The message lives in the transformation and the outcome schema; identity lives in every id-bearing file. | Keep; it is the change-and-repeat mechanism. |

### 9.5 Is publication necessary?

Two states, distinguished by the guards, not by the loop.

**Old state (guards present).** A capability newly added through the current runtime must be published: the read path pins `source.current_model`, and `model.guard_estate_capability` refuses inserts into a PUBLISHED model (`PUBLISHED_MEMBERSHIP_IMMUTABLE`, error 51003 — observed). While those guards exist, a new generation plus `validate_model`/`publish_model` is the only SQL path that makes the capability selectable. The extra lineage and validation records are then **publication overhead**, not invocation requirements.

**Proposed state (`remove-execution-dependence-overhead.sql`).** The guards are the restriction, not the capability. Dropping the ones whose definition contains a blocking condition — and scoping importer update rights to the two objects the scaffold updates — removes the need for a generation, validation and publication. The read path still pins `source.current_model`, so `scaffold-hello-world.sql` inserts its selection rows directly into that model. Publication is then **not** part of this loop.

Publication is therefore necessary only while the immutability and membership guards are in place. It was never intrinsically necessary to the flywheel; it was the cost of the guards. The two work-order files are the decision: remove the restriction, and the lifecycle step disappears with it.

A separate, still-open question is whether the runtime should read a mutable working definition without any retained capsule source at all. That is a runtime read-path change and is not required to close this loop.

### 9.6 Decision record for the work order

| Question | Finding |
| --- | --- |
| What closes the loop? | SQL-authored retained source + CLI invocation + observed message; message and identity are parameters. |
| What is execution-necessary? | Capsule source entries for the selected digest; one lineage resolution; the CLI interface binding; a port/authority that yields the payload. |
| What is publication-necessary? | The new generation, membership carry, remaining lineage, and `validate_model`/`publish_model`. |
| What is not necessary? | Any record that neither the read path nor a validation gate consults. |
| What remains open? | Whether the runtime should read a mutable working definition without retained capsule source. The stdout call is not open: it is the existing `sda-json-cli.v1` (`Interface.JsonCli` → `deliverArtifact → process.stdout`) declared through the capability interface, and is reused with no platform change. |
| Evidence status | Executed and observed. The loop ran end to end against the live `sidefx` database: the unchanged CLI invokes `hello-world-sql` (`Hello Sidney!` on stdout), the message and identity are database data, re-running scaffolds a second identity, and `reveal` walks the declared chain with `Mechanics` resolved. `resolve-equity-market-price-evidence` additionally executed live provider conformance (`EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED`, observed price). The runtime still resolves exactly one retained-source row per capability (`capability-embodiment.sql`), so capsule source remains mandatory at declaration time — §9.6's open question. |

The team should review this record with the `.sql` and the six observable events in front of them. A dependency that cannot name its failing event is either publication overhead to be minimized or work that belongs to a different decision.
