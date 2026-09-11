# SideFX Architecture Decision Rubric

Draft working aid · 2026-09-11

Purpose: account for architectural decisions by their authority, present necessity, and positive and negative effects on the builder's intended flywheel.

This document proposes a review method. The minimal-scaffold constraint below records the builder's explicit clarification in this conversation; the scoring scales, examples, and procedural recommendations remain proposals, not admitted platform policy. Saving, citing, or reusing this document does not expand their authority. No repository was inspected. Existing implementation coverage is user-reported and must be checked before drawing implementation conclusions.

## Starting constraint: the smallest complete path to the outcome

**Builder-directed baseline:** For a feature, begin with the least functionality necessary to carry its intended Input → Event → Outcome experience through to an observable result, within applicable existing constraints. Include zero, one, or multiple providers according to what that outcome requires.

The outcome determines the scaffold's scope. A provider connection is an implementation step when needed; its presence or successful response alone does not establish the intended outcome. Reuse the applicable definitions, declared mechanics, execution authority, and available implementation. Minimality does not authorize dropping required steps, inventing a different execution topology, or presenting a partial interaction as a completed result.

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

The builder's stated experience is the scope anchor:

- **Input:** A user selects a declared diagram component. Its input form expands from the component using the applicable existing input definition. The user supplies the required data.
- **Event:** The user submits. The form returns into the component, and the request executes through the applicable established execution path. The interaction communicates the real execution state.
- **Outcome:** The component presents the actual result or failure clearly enough for the user to understand what happened and what to do next.

The expanding form and return into the diagram are part of this experience. A review should account for their implementation cost while preserving the builder's intent. An animation's completion cannot stand in for execution success.

The proposed first slice is one component, its applicable input definition, its established execution path, and a visible result. That path may involve zero, one, or multiple providers as required; one component does not imply one provider. Verify what already works and address the concrete gaps. Broader component coverage belongs in the slice only when supported by the intended demonstration or existing applicable requirements.

**Proposed flywheel hypothesis:** A credible execution makes the blueprint useful to someone. Their use reveals the next valuable scenario or friction. Reusing what was learned or built lowers the effort of delivering the next useful example, which encourages further use and feedback.

Keep the interaction loop and this hypothesis distinct. One successful demonstration proves that the interaction can work. A flywheel needs evidence that its results improve a subsequent cycle. Feedback and adoption do not arise automatically; identify the actual people and next-use opportunity when applying the rubric.

Record three observations using the existing work process:

1. Time from starting the scoped change to the first credible end-to-end demonstration, including review overhead.
2. Successful authorized executions out of attempts, with the number of distinct users and the principal failure reasons. Repeated test clicks are not evidence of adoption.
3. Effort to deliver the next comparable useful example, noting which reuse or learning caused a change. If no next example exists, the flywheel remains unverified.

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
| Add a decision service, registry, or policy engine to enforce this rubric | Could eventually support repeated review; adds a new system before testing the review itself. | Use a section in the existing design document first. Reconsider tooling only when repeated review produces a demonstrated burden. |
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

Review effort should scale with consequence. The first implementation of this method is a document section and a conversation grounded in the builder's intent.
