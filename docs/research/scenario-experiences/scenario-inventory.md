# Scenario contract inventory

One row per selected Scenario. The complete structured taxonomy is in [contract-taxonomy.json](contract-taxonomy.json); pointer-level examples and feature counts are static research observations, not renderer certification. All rows are in `sidefx:capabilities`. Root = declared capability entry scenario.

| Capability | Scenario | Root | Input contract | Input shape | Outcome contract | Outcome shape |
|---|---|---|---|---|---|---|
| adapt-job-market-intelligence-evidence | adapt-job-market-intelligence-evidence | yes | job-market-intelligence-adapter-record.v1 | direct-record | job-market-intelligence-adapter-record.v1 | direct-record |
| adapt-job-market-intelligence-evidence | bind-jmi-adapter-receipt |  | job-market-intelligence-adapter-record.v1 | direct-record | job-market-intelligence-adapter-record.v1 | direct-record |
| adapt-job-market-intelligence-evidence | verify-jmi-record-binding |  | job-market-intelligence-adapter-record.v1 | direct-record | job-market-intelligence-adapter-record.v1 | direct-record |
| adapt-job-market-intelligence-evidence | verify-jmi-type-admission |  | job-market-intelligence-adapter-record.v1 | direct-record | job-market-intelligence-adapter-record.v1 | direct-record |
| admit-canonical-circuit-blueprint | admit-canonical-circuit-blueprint | yes | canonical-blueprint-admission-request.v1 | enveloped-record | admitted-canonical-circuit-blueprint.v1 | enveloped-record |
| admit-canonical-circuit-blueprint | emit-immutable-blueprint-authority |  | canonical-blueprint-admission-request.v1 | enveloped-record | admitted-canonical-circuit-blueprint.v1 | enveloped-record |
| admit-canonical-circuit-blueprint | require-blueprint-conformance-evidence |  | canonical-blueprint-admission-request.v1 | enveloped-record | blueprint-admission-obligation-disposition.v1 | enveloped-record |
| admit-canonical-circuit-blueprint | require-blueprint-geometry-proof |  | canonical-blueprint-admission-request.v1 | enveloped-record | blueprint-admission-obligation-disposition.v1 | enveloped-record |
| admit-canonical-circuit-blueprint | require-current-approved-review-receipt |  | canonical-blueprint-admission-request.v1 | enveloped-record | blueprint-admission-obligation-disposition.v1 | enveloped-record |
| admit-capability-authority | evaluate-capability-authority-admission | yes | capability-authority-admission-context.v1 | direct-record | capability-authority-admission-result.v1 | direct-record |
| admit-capability-authority | return-admission-hold |  | capability-authority-admission-result.v1 | direct-record | capability-authority-admission-result.v1 | direct-record |
| admit-capability-authority | return-admitted-authority |  | capability-authority-admission-result.v1 | direct-record | capability-authority-admission-result.v1 | direct-record |
| admit-capsule-execution-closure | admit-capsule-execution-closure | yes | capsule-execution-closure-record.v1 | direct-record | capsule-execution-closure-record.v1 | direct-record |
| admit-capsule-execution-closure | bind-closure-receipt |  | capsule-execution-closure-record.v1 | direct-record | capsule-execution-closure-record.v1 | direct-record |
| admit-capsule-execution-closure | verify-closure-digest |  | capsule-execution-closure-record.v1 | direct-record | capsule-execution-closure-record.v1 | direct-record |
| admit-capsule-execution-closure | verify-declared-dependency-closure |  | capsule-execution-closure-record.v1 | direct-record | capsule-execution-closure-record.v1 | direct-record |
| admit-capsule-execution-closure | verify-execution-entries |  | capsule-execution-closure-record.v1 | direct-record | capsule-execution-closure-record.v1 | direct-record |
| admit-consumer-source-facts | admit-consumer-source-facts | yes | admit-consumer-source-facts-input.v1 | enveloped-record | consumer-source-admission-evidence.v1 | direct-record |
| admit-execution-vector | admit-execution-vector | yes | execution-vector-admission-input.v1 | enveloped-record | execution-vector-admission-evidence.v1 | enveloped-record |
| admit-external-market-representation | admit-external-market-representation | yes | external-representation-receipt.v1 | direct-record | external-representation-receipt.v1 | direct-record |
| admit-external-market-representation | bind-representation-receipt |  | external-representation-receipt.v1 | direct-record | external-representation-receipt.v1 | direct-record |
| admit-external-market-representation | verify-duplication-syndication-and-use |  | external-representation-receipt.v1 | direct-record | external-representation-receipt.v1 | direct-record |
| admit-external-market-representation | verify-methodology-provenance |  | external-representation-receipt.v1 | direct-record | external-representation-receipt.v1 | direct-record |
| admit-external-market-representation | verify-source-identity |  | external-representation-receipt.v1 | direct-record | external-representation-receipt.v1 | direct-record |
| admit-kernel-specification | admit-kernel-specification | yes | kernel-specification-admission-input.v1 | enveloped-record | kernel-specification-admission-evidence.v1 | direct-record |
| admit-language-declaration | admit-language-declaration | yes | language-declaration-admission-input.v1 | enveloped-record | language-declaration-evidence.v1 | direct-record |
| admit-registry-asset | admit-registry-asset | yes | registry-asset-admission-request.v1 | composed-root | registry-asset-admission-receipt.v1 | direct-record |
| admit-registry-asset | conform-mechanic-profile |  | registry-admission-carrier.v1 | direct-record | registry-admission-carrier.v1 | direct-record |
| admit-registry-asset | conform-provider-connection |  | registry-admission-carrier.v1 | direct-record | registry-admission-carrier.v1 | direct-record |
| admit-registry-asset | conform-scenario-archetype |  | registry-admission-carrier.v1 | direct-record | registry-admission-carrier.v1 | direct-record |
| admit-registry-asset | preserve-vocabulary-separation |  | registry-admission-carrier.v1 | direct-record | registry-admission-carrier.v1 | direct-record |
| admit-registry-asset | recompute-asset-identity |  | registry-asset-admission-request.v1 | composed-root | registry-admission-carrier.v1 | direct-record |
| admit-registry-asset | reject-colliding-asset-identity |  | registry-asset-admission-request.v1 | composed-root | registry-admission-carrier.v1 | direct-record |
| admit-registry-asset | replay-registry-admission |  | registry-admission-carrier.v1 | direct-record | registry-admission-carrier.v1 | direct-record |
| admit-registry-asset | require-admitted-referenced-authority |  | registry-admission-carrier.v1 | direct-record | registry-admission-carrier.v1 | direct-record |
| admit-registry-asset | require-human-admission-disposition |  | registry-admission-carrier.v1 | direct-record | registry-admission-carrier.v1 | direct-record |
| admit-schema-family | admit-schema-family | yes | schema-family-admission-input.v1 | enveloped-record | schema-family-admission-evidence.v1 | direct-record |
| advance-sidefx-current-corpus-pointer | advance-sidefx-current-corpus-pointer | yes | sidefx-current-pointer-advancement-record.v1 | direct-record | sidefx-current-pointer-advancement-record.v1 | direct-record |
| advance-sidefx-current-corpus-pointer | refuse-open-pointer-advancement |  | sidefx-current-pointer-advancement-record.v1 | direct-record | sidefx-current-pointer-advancement-record.v1 | direct-record |
| advance-sidefx-current-corpus-pointer | report-pointer-conflict-without-mutation |  | sidefx-current-pointer-advancement-record.v1 | direct-record | sidefx-current-pointer-advancement-record.v1 | direct-record |
| analyze-sidefx-semantic-gaps | analyze-sidefx-semantic-gaps | yes | sidefx-gap-analysis-request.v1 | direct-record | sidefx-semantic-gap-analysis.v1 | direct-record |
| analyze-sidefx-semantic-impact | analyze-sidefx-semantic-impact | yes | sidefx-impact-analysis-request.v1 | direct-record | sidefx-semantic-impact-analysis.v1 | direct-record |
| assemble-sidefx-capability-authoring-context | assemble-sidefx-capability-authoring-context | yes | sidefx-authoring-context-request.v1 | direct-record | sidefx-capability-authoring-context-pack.v1 | direct-record |
| assure-presentation-provider-closure | assure-presentation-provider-closure | yes | assure-presentation-provider-closure-input.v1 | enveloped-record | presentation-provider-closure-evidence.v1 | enveloped-record |
| audit-controlled-tooling-migration-batch | audit-controlled-tooling-migration-batch | yes | controlled-tooling-migration-batch-audit-request.v1 | direct-record | controlled-tooling-migration-batch-audit-evidence.v1 | direct-record |
| author-canonical-circuit-blueprint-candidate | author-canonical-circuit-blueprint-candidate | yes | canonical-blueprint-design-request.v2 | direct-record | canonical-blueprint-authoring-result.v2 | composed-root |
| author-canonical-circuit-blueprint-candidate | bind-admitted-blueprint-precedents |  | canonical-blueprint-authoring-intermediate.v2 | direct-record | canonical-blueprint-authoring-intermediate.v2 | direct-record |
| author-canonical-circuit-blueprint-candidate | bind-blueprint-candidate-lineage |  | canonical-blueprint-authoring-intermediate.v2 | direct-record | canonical-blueprint-authoring-result.v2 | composed-root |
| author-canonical-circuit-blueprint-candidate | bind-blueprint-design-testimony |  | canonical-blueprint-authoring-intermediate.v2 | direct-record | canonical-blueprint-authoring-intermediate.v2 | direct-record |
| author-canonical-circuit-blueprint-candidate | resolve-exact-feature-authority |  | canonical-blueprint-design-request.v2 | direct-record | canonical-blueprint-authoring-intermediate.v2 | direct-record |
| author-canonical-feature | author-canonical-feature | yes | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| author-capability-candidate-from-feature-reference | author-capability-candidate-from-feature-reference | yes | blueprint-bound-capability-authoring-request.v1 | enveloped-record | blueprint-bound-capability-authoring-result.v1 | composed-root |
| author-capability-candidate-from-feature-reference | bind-approved-blueprint-authority |  | canonical-capability-feature.v1 | composed-root | bound-blueprint-authoring-authority.v1 | composed-root |
| author-capability-candidate-from-feature-reference | invoke-projectable-capability-candidate-author |  | selected-blueprint-cell.v1 | composed-root | blueprint-bound-capability-authoring-result.v1 | composed-root |
| author-capability-candidate-from-feature-reference | resolve-blueprint-cell-ledger |  | bound-blueprint-authoring-authority.v1 | composed-root | blueprint-cell-ledger.v1 | composed-root |
| author-capability-candidate-from-feature-reference | resolve-canonical-feature-authoring-input |  | blueprint-bound-capability-authoring-request.v1 | enveloped-record | canonical-capability-feature.v1 | composed-root |
| author-capability-candidate-from-feature-reference | select-one-eligible-blueprint-cell |  | blueprint-cell-ledger.v1 | composed-root | selected-blueprint-cell.v1 | composed-root |
| author-capability-candidate-from-feature-reference | verify-blueprint-authoring-lineage |  | blueprint-bound-capability-authoring-result.v1 | composed-root | verified-blueprint-authoring-lineage.v1 | enveloped-record |
| author-capability-scenario-conveyor | admit-one-scenario-authority-fragment |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | assemble-closed-capability-source-bundle-from-scenario-fragments |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | author-capability-scenario-conveyor | yes | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | author-single-scenario-capability-through-conveyor |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | construct-bounded-scenario-authoring-request |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | curate-bounded-scenario-authority-fragment-defect |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | hand-off-closed-capability-bundle-for-independent-projection |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | hold-capability-scenario-selection-with-no-eligible-unit |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | initialize-capability-scenario-authoring-ledger |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | inspect-one-scenario-authority-fragment |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | integrate-admitted-scenario-authority-fragment |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | invoke-authorized-scenario-invocation-set |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | obtain-one-scenario-authority-fragment-testimony |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | preserve-capability-scenario-authoring-deterministic-replay |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | preserve-stable-capability-authoring-user-experience |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | reject-cross-scenario-or-whole-capability-testimony |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | reject-invalid-capability-scenario-authoring-source |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | reject-premature-or-incomplete-capability-authoring-closure |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | reject-scenario-authoring-context-scope-expansion |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | reject-scenario-fragment-conflicting-with-admitted-authority |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | reject-unadmitted-duplicate-stale-or-out-of-order-fragment-integration |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | require-new-scenario-attempt-for-broadly-unusable-fragment |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | resolve-authorized-scenario-continuation |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | resume-capability-scenario-authoring-conveyor |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | retain-conveyed-route-state |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | retain-unsuccessful-scenario-authoring-attempt |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | select-next-eligible-capability-scenario |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | select-root-capability-scenario-first |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | stop-capability-scenario-authoring-on-budget-cancellation-or-rejection |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-capability-scenario-conveyor | switch-scenario-author-model-after-declared-failure |  | capability-scenario-authoring-conveyor-request.v1 | direct-record | capability-scenario-authoring-conveyor-evidence.v1 | direct-record |
| author-one-scenario-candidate | admit-scenario-meaning-boundary |  | bounded-scenario-meaning-request.v1 | direct-record | admitted-scenario-meaning-boundary.v1 | direct-record |
| author-one-scenario-candidate | author-one-scenario-candidate | yes | bounded-scenario-meaning-request.v1 | direct-record | scenario-authoring-outcome.v1 | direct-record |
| author-one-scenario-candidate | construct-scenario-meaning-request |  | admitted-scenario-meaning-boundary.v1 | direct-record | bounded-scenario-meaning-invocation.v1 | direct-record |
| author-one-scenario-candidate | obtain-scenario-meaning-testimony |  | bounded-scenario-meaning-invocation.v1 | direct-record | scenario-meaning-testimony.v1 | direct-record |
| author-one-scenario-candidate | resolve-scenario-candidate-disposition |  | scenario-meaning-testimony.v1 | direct-record | scenario-authoring-outcome.v1 | direct-record |
| author-one-scenario-solution | admit-scenario-solution-boundary |  | bounded-scenario-solution-request.v1 | direct-record | admitted-scenario-solution-boundary.v1 | direct-record |
| author-one-scenario-solution | author-one-scenario-solution | yes | bounded-scenario-solution-request.v1 | direct-record | solution-authoring-outcome.v2 | direct-record |
| author-one-scenario-solution | construct-scenario-solution-request |  | admitted-scenario-solution-boundary.v1 | direct-record | bounded-scenario-solution-invocation.v1 | direct-record |
| author-one-scenario-solution | obtain-scenario-solution-testimony |  | bounded-scenario-solution-invocation.v1 | direct-record | solution-authoring-outcome.v2 | direct-record |
| author-tooling-capability-candidate | admit-capability-authoring-context |  | capability-authoring-context.v1 | enveloped-record | admitted-capability-authoring-context.v1 | enveloped-record |
| author-tooling-capability-candidate | admit-structured-authoring-testimony |  | authoring-testimony-for-admission.v1 | enveloped-record | authoring-testimony-admission-result.v1 | enveloped-record |
| author-tooling-capability-candidate | apply-unique-mechanical-repair |  | mechanical-repair-resolution.v1 | enveloped-record | mechanically-repaired-testimony.v1 | enveloped-record |
| author-tooling-capability-candidate | assemble-canonical-authority-artifacts |  | artifact-authoring-ledger.v1 | enveloped-record | projectable-capability-candidate.v1 | enveloped-record |
| author-tooling-capability-candidate | author-tooling-capability-candidate | yes | capability-authoring-context.v1 | enveloped-record | projectable-capability-authoring-result.v2 | enveloped-record |
| author-tooling-capability-candidate | authorize-authoring-attempt |  | classified-authoring-findings.v1 | enveloped-record | authorized-authoring-attempt.v1 | enveloped-record |
| author-tooling-capability-candidate | classify-authoring-testimony |  | authoring-testimony-admission-result.v1 | enveloped-record | classified-authoring-findings.v1 | enveloped-record |
| author-tooling-capability-candidate | construct-bounded-authoring-envelope |  | authoring-work-unit-readiness-proof.v1 | enveloped-record | bounded-authoring-envelope.v1 | enveloped-record |
| author-tooling-capability-candidate | establish-conforming-authoring-work-unit |  | classified-authoring-findings.v1 | enveloped-record | conforming-authoring-work-unit.v1 | enveloped-record |
| author-tooling-capability-candidate | initialize-artifact-authoring-ledger |  | bounded-capability-authoring-profile.v2 | enveloped-record | artifact-authoring-ledger.v1 | enveloped-record |
| author-tooling-capability-candidate | integrate-conforming-authoring-work-unit |  | conforming-authoring-work-unit.v1 | enveloped-record | artifact-authoring-ledger.v1 | enveloped-record |
| author-tooling-capability-candidate | obtain-authoring-testimony |  | bounded-authoring-envelope.v1 | enveloped-record | governed-authoring-testimony.v1 | enveloped-record |
| author-tooling-capability-candidate | prepare-authoring-testimony-for-admission |  | authoring-testimony-source.v1 | enveloped-record | authoring-testimony-for-admission.v1 | enveloped-record |
| author-tooling-capability-candidate | prove-authoring-work-unit-readiness |  | eligible-artifact-authoring-work-unit.v1 | enveloped-record | authoring-work-unit-readiness-proof.v1 | enveloped-record |
| author-tooling-capability-candidate | prove-candidate-authoring-closure |  | projectable-capability-candidate.v1 | enveloped-record | projectable-capability-authoring-result.v2 | enveloped-record |
| author-tooling-capability-candidate | repair-authoring-work-unit |  | authorized-authoring-attempt.v1 | enveloped-record | bounded-authoring-repair-request.v1 | enveloped-record |
| author-tooling-capability-candidate | resolve-capability-authoring-profile |  | admitted-capability-authoring-context.v1 | enveloped-record | bounded-capability-authoring-profile.v2 | enveloped-record |
| author-tooling-capability-candidate | resolve-mechanical-repair-uniqueness |  | classified-authoring-findings.v1 | enveloped-record | mechanical-repair-resolution.v1 | enveloped-record |
| author-tooling-capability-candidate | select-next-eligible-artifact-fragment |  | artifact-authoring-ledger.v1 | enveloped-record | eligible-artifact-authoring-work-unit.v1 | enveloped-record |
| bind-canonical-blueprint-review | admit-blueprint-review-boundary |  | canonical-blueprint-review-binding-request.v2 | direct-record | blueprint-review-boundary-admission.v2 | composed-root |
| bind-canonical-blueprint-review | admit-human-blueprint-review-testimony |  | admitted-blueprint-review-boundary.v2 | composed-root | human-blueprint-review-testimony-admission.v2 | composed-root |
| bind-canonical-blueprint-review | bind-blueprint-review-disposition |  | admitted-human-blueprint-review-testimony.v2 | direct-record | blueprint-review-disposition-binding.v2 | composed-root |
| bind-canonical-blueprint-review | bind-canonical-blueprint-review | yes | canonical-blueprint-review-binding-request.v2 | direct-record | canonical-blueprint-review-receipt.v2 | composed-root |
| bind-canonical-blueprint-review | verify-blueprint-review-digest-closure |  | bound-blueprint-review-disposition.v2 | composed-root | canonical-blueprint-review-receipt.v2 | composed-root |
| bind-external-credential-reference | bind-external-credential-reference | yes | bind-external-credential-reference-input.v1 | composed-root | external-credential-binding-evidence.v1 | direct-record |
| bind-external-credential-reference | hold-missing-or-empty-external-credential |  | bind-external-credential-reference-input.v1 | composed-root | external-credential-binding-evidence.v1 | direct-record |
| bind-external-credential-reference | prove-external-credential-non-disclosure |  | bind-external-credential-reference-input.v1 | composed-root | external-credential-binding-evidence.v1 | direct-record |
| bind-external-credential-reference | reject-embedded-credential-material |  | bind-external-credential-reference-input.v1 | composed-root | external-credential-binding-evidence.v1 | direct-record |
| bind-external-credential-reference | reject-mismatched-credential-invocation-identity |  | bind-external-credential-reference-input.v1 | composed-root | external-credential-binding-evidence.v1 | direct-record |
| bind-external-credential-reference | reject-stale-or-replayed-credential-binding |  | bind-external-credential-reference-input.v1 | composed-root | external-credential-binding-evidence.v1 | direct-record |
| bind-external-credential-reference | reject-unauthorized-external-credential-reference |  | bind-external-credential-reference-input.v1 | composed-root | external-credential-binding-evidence.v1 | direct-record |
| bind-model-testimony-evidence | bind-model-testimony-evidence | yes | model-testimony-binding-request.v1 | direct-record | model-testimony-binding-evidence.v1 | direct-record |
| bind-sidefx-semantic-query-receipt | bind-sidefx-semantic-query-receipt | yes | sidefx-semantic-query-receipt-binding-request.v1 | direct-record | sidefx-semantic-query-receipt.v1 | direct-record |
| classify-sidefx-semantic-corpus-sources | classify-sidefx-semantic-corpus-sources | yes | sidefx-semantic-corpus-source-classification-request.v1 | direct-record | sidefx-semantic-source-manifest.v1 | direct-record |
| compare-projected-tooling-migration-oracle | compare-projected-tooling-migration-oracle | yes | projected-tooling-migration-oracle-comparison-request.v1 | composed-root | projected-tooling-migration-oracle-comparison-request.v1 | composed-root |
| compare-projected-tooling-migration-oracle | compare-projected-tooling-migration-oracle-observations |  | governed-repository-observation.v1 | reference-root | tooling-migration-oracle-equivalence-evidence.v1 | composed-root |
| compare-projected-tooling-migration-oracle | observe-frozen-tooling-migration-operational-oracle |  | bounded-governed-repository-observation-context.v1 | composed-root | governed-repository-observation.v1 | reference-root |
| compare-projected-tooling-migration-oracle | resolve-projected-tooling-migration-oracle-comparison-scope |  | projected-tooling-migration-oracle-comparison-request.v1 | composed-root | bounded-governed-repository-observation-context.v1 | composed-root |
| compare-sidefx-store-equivalence | compare-sidefx-store-equivalence | yes | sidefx-store-equivalence-comparison-record.v1 | direct-record | sidefx-store-equivalence-comparison-record.v1 | direct-record |
| compare-sidefx-store-equivalence | report-unavailable-provider-not-observable |  | sidefx-store-equivalence-comparison-record.v1 | direct-record | sidefx-store-equivalence-comparison-record.v1 | direct-record |
| compare-sidefx-store-equivalence | retain-provider-testimony-outside-semantic-basis |  | sidefx-store-equivalence-comparison-record.v1 | direct-record | sidefx-store-equivalence-comparison-record.v1 | direct-record |
| compose-canonical-scenario-graph | compose-canonical-scenario-graph | yes | compose-canonical-scenario-graph-input.v1 | enveloped-record | canonical-consumer-scenario-graph-evidence.v1 | direct-record |
| construct-capability-author-delegate-request | assemble-capability-author-delegate-request |  | bounded-capability-author-delegate-profile.v1 | composed-root | governed-capability-author-delegate-request.v1 | composed-root |
| construct-capability-author-delegate-request | construct-capability-author-delegate-request | yes | capability-author-delegate-construction-request.v1 | composed-root | capability-author-delegate-construction-request.v1 | composed-root |
| construct-capability-author-delegate-request | observe-delegate-canonical-feature |  | capability-author-delegate-construction-request.v1 | composed-root | observed-delegate-canonical-feature.v1 | composed-root |
| construct-capability-author-delegate-request | publish-capability-author-delegate-request |  | governed-capability-author-delegate-request.v1 | composed-root | published-capability-author-delegate-request.v1 | composed-root |
| construct-capability-author-delegate-request | resolve-delegate-authoring-profile |  | observed-delegate-canonical-feature.v1 | composed-root | bounded-capability-author-delegate-profile.v1 | composed-root |
| construct-consumer-projection-plan | construct-consumer-projection-plan | yes | construct-consumer-projection-plan-input.v1 | enveloped-record | consumer-projection-plan-evidence.v1 | direct-record |
| construct-deterministic-realization-plan | construct-deterministic-realization-plan | yes | construct-deterministic-realization-plan-input.v1 | enveloped-record | realization-plan-compilation-evidence.v1 | direct-record |
| construct-model-connection-runtime-closure | classify-model-connection-external-substrates |  | construct-model-connection-runtime-closure-input.v1 | composed-root | model-connection-runtime-closure-evidence.v1 | direct-record |
| construct-model-connection-runtime-closure | construct-model-connection-runtime-closure | yes | construct-model-connection-runtime-closure-input.v1 | composed-root | model-connection-runtime-closure-evidence.v1 | direct-record |
| construct-model-connection-runtime-closure | reject-incomplete-model-connection-host-coverage |  | construct-model-connection-runtime-closure-input.v1 | composed-root | model-connection-runtime-closure-evidence.v1 | direct-record |
| construct-model-connection-runtime-closure | reject-incomplete-runtime-artifact-set |  | construct-model-connection-runtime-closure-input.v1 | composed-root | model-connection-runtime-closure-evidence.v1 | direct-record |
| construct-model-connection-runtime-closure | reject-runtime-digest-drift |  | construct-model-connection-runtime-closure-input.v1 | composed-root | model-connection-runtime-closure-evidence.v1 | direct-record |
| construct-model-connection-runtime-closure | reject-runtime-source-loader-dependency |  | construct-model-connection-runtime-closure-input.v1 | composed-root | model-connection-runtime-closure-evidence.v1 | direct-record |
| construct-model-connection-runtime-closure | reject-sibling-repository-runtime-dependency |  | construct-model-connection-runtime-closure-input.v1 | composed-root | model-connection-runtime-closure-evidence.v1 | direct-record |
| construct-model-connection-runtime-closure | reject-undeclared-or-mutable-runtime-package |  | construct-model-connection-runtime-closure-input.v1 | composed-root | model-connection-runtime-closure-evidence.v1 | direct-record |
| construct-model-connection-runtime-closure | reject-unsafe-runtime-path |  | construct-model-connection-runtime-closure-input.v1 | composed-root | model-connection-runtime-closure-evidence.v1 | direct-record |
| construct-model-role-conveyor-plan | construct-model-role-conveyor-plan | yes | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | enforce-distinct-model-role-separation-policy |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | plan-deterministic-model-role-dependency-order |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | plan-distinct-models-across-providers |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | plan-distinct-models-from-one-provider |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | plan-model-role-provider-switch-chain |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | plan-stable-model-role-conveyor-presentation |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | preserve-model-role-plan-canonical-identity |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | reject-cyclic-or-unreachable-model-role-stage |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | reject-incomplete-model-role-effect-and-budget-policy |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | reject-incomplete-model-role-stage-authority |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | reject-invalid-model-role-provider-switch-chain |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | reject-model-role-authority-escalation |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | reject-model-role-contract-or-context-mismatch |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-model-role-conveyor-plan | reject-stale-or-unknown-model-role-binding |  | construct-model-role-conveyor-plan-input.v1 | composed-root | model-role-conveyor-plan-evidence.v1 | enveloped-record |
| construct-projectable-capability-publication-shape | construct-projectable-capability-publication-shape | yes | admitted-projectable-capability-publication-facts.v1 | direct-record | projectable-capability-publication-shape-evidence.v1 | direct-record |
| construct-sidefx-evaluation-corpus-snapshot | construct-sidefx-evaluation-corpus-snapshot | yes | sidefx-evaluation-corpus-snapshot-construction-request.v1 | direct-record | sidefx-semantic-corpus-snapshot.v1 | direct-record |
| construct-sidefx-evaluation-object-catalog | construct-sidefx-evaluation-object-catalog | yes | sidefx-evaluation-object-catalog-construction-request.v1 | direct-record | sidefx-semantic-object-catalog.v1 | direct-record |
| construct-sidefx-evaluation-relationship-graph | construct-sidefx-evaluation-relationship-graph | yes | sidefx-evaluation-relationship-graph-construction-request.v1 | direct-record | sidefx-semantic-relationship-graph.v1 | direct-record |
| construct-sidefx-semantic-query-plan | construct-sidefx-semantic-query-plan | yes | sidefx-semantic-query-plan-construction-request.v1 | direct-record | sidefx-semantic-query-plan-construction-outcome.v1 | direct-record |
| construct-tooling-migration-execution-plan | construct-tooling-migration-execution-plan | yes | controlled-tooling-migration-request.v1 | direct-record | tooling-migration-execution-plan.v1 | direct-record |
| decide-implementation-admission | decide-implementation-admission | yes | implementation-admission-input.v1 | enveloped-record | implementation-admission-evidence.v1 | enveloped-record |
| decode-physical-capability-capsule | bind-decode-receipt |  | physical-capsule-decode-record.v1 | direct-record | physical-capsule-decode-record.v1 | direct-record |
| decode-physical-capability-capsule | decode-physical-capability-capsule | yes | physical-capsule-decode-record.v1 | direct-record | physical-capsule-decode-record.v1 | direct-record |
| decode-physical-capability-capsule | verify-capsule-bytes-and-format |  | physical-capsule-decode-record.v1 | direct-record | physical-capsule-decode-record.v1 | direct-record |
| decode-physical-capability-capsule | verify-capsule-digest |  | physical-capsule-decode-record.v1 | direct-record | physical-capsule-decode-record.v1 | direct-record |
| decode-physical-capability-capsule | verify-capsule-manifest-entries |  | physical-capsule-decode-record.v1 | direct-record | physical-capsule-decode-record.v1 | direct-record |
| deliver-capability-change-api | deliver-capability-change-api | yes | capability-change-api-delivery-request.v1 | enveloped-record | capability-change-api-delivery-result.v1 | composed-root |
| deliver-capability-change-api | observe-capability-change-through-api |  | capability-change-api-operation-request.v1 | enveloped-record | capability-change-api-operation-result.v1 | enveloped-record |
| deliver-capability-change-api | open-capability-change-through-api |  | capability-change-api-operation-request.v1 | enveloped-record | capability-change-api-operation-result.v1 | enveloped-record |
| deliver-capability-change-api | represent-capability-change-api-failure |  | capability-change-api-failure.v1 | enveloped-record | capability-change-api-delivery-result.v1 | composed-root |
| deliver-capability-change-api | transition-capability-change-through-api |  | capability-change-api-operation-request.v1 | enveloped-record | capability-change-api-operation-result.v1 | enveloped-record |
| deliver-capability-change-cli | bind-capability-change-cli-command |  | capability-change-cli-request.v1 | enveloped-record | capability-change-operation-request.v1 | enveloped-record |
| deliver-capability-change-cli | deliver-capability-change-cli | yes | capability-change-cli-request.v1 | enveloped-record | capability-change-cli-result.v1 | composed-root |
| deliver-capability-change-cli | reject-unadmitted-capability-change-cli-request |  | capability-change-cli-request.v1 | enveloped-record | capability-change-cli-result.v1 | composed-root |
| deliver-capability-change-cli | render-capability-change-cli-status |  | capability-change-status.v1 | enveloped-record | capability-change-cli-result.v1 | composed-root |
| deliver-capability-change-mcp | deliver-capability-change-mcp | yes | capability-change-mcp-delivery-request.v1 | enveloped-record | capability-change-mcp-delivery-result.v1 | composed-root |
| deliver-capability-change-mcp | invoke-capability-change-mcp-tool |  | capability-change-mcp-tool-request.v1 | enveloped-record | capability-change-mcp-tool-result.v1 | enveloped-record |
| deliver-capability-change-mcp | register-capability-change-mcp-tools |  | capability-change-mcp-delivery-request.v1 | enveloped-record | capability-change-mcp-delivery-result.v1 | composed-root |
| deliver-capability-change-mcp | represent-capability-change-mcp-failure |  | capability-change-mcp-failure.v1 | enveloped-record | capability-change-mcp-delivery-result.v1 | composed-root |
| deliver-capsule-estate-cli | bind-capsule-cli-arguments |  | capsule-estate-cli-delivery-request.v2 | enveloped-record | capsule-estate-cli-binding-result.v2 | enveloped-record |
| deliver-capsule-estate-cli | deliver-capsule-estate-cli | yes | capsule-estate-cli-delivery-request.v2 | enveloped-record | capsule-estate-cli-delivery-result.v2 | enveloped-record |
| deliver-capsule-estate-cli | reject-unadmitted-capsule-cli-request |  | capsule-estate-cli-binding-result.v2 | enveloped-record | capsule-estate-cli-delivery-result.v2 | enveloped-record |
| deliver-capsule-estate-mcp | deliver-capsule-estate-mcp | yes | capsule-estate-mcp-delivery-request.v1 | enveloped-record | capsule-estate-mcp-delivery-result.v1 | enveloped-record |
| deliver-capsule-estate-mcp | invoke-capsule-estate-mcp-tool |  | capsule-estate-mcp-delivery-request.v1 | enveloped-record | capsule-estate-mcp-delivery-result.v1 | enveloped-record |
| deliver-capsule-estate-mcp | register-capsule-estate-mcp-tools |  | capsule-estate-mcp-delivery-request.v1 | enveloped-record | capsule-estate-mcp-delivery-result.v1 | enveloped-record |
| deliver-capsule-estate-mcp | represent-capsule-estate-mcp-failure |  | capsule-estate-mcp-delivery-request.v1 | enveloped-record | capsule-estate-mcp-delivery-result.v1 | enveloped-record |
| deliver-realization-api | deliver-realization-api | yes | realization-api-delivery-request.v1 | enveloped-record | realization-api-delivery-result.v1 | enveloped-record |
| deliver-realization-api | discover-realization-api-capabilities |  | realization-api-delivery-request.v1 | enveloped-record | realization-api-delivery-result.v1 | enveloped-record |
| deliver-realization-api | dispose-realization-api-roots |  | realization-api-delivery-request.v1 | enveloped-record | realization-api-delivery-result.v1 | enveloped-record |
| deliver-realization-api | observe-realization-api-projection |  | realization-api-delivery-request.v1 | enveloped-record | realization-api-delivery-result.v1 | enveloped-record |
| deliver-realization-api | plan-realization-api-target |  | realization-api-delivery-request.v1 | enveloped-record | realization-api-delivery-result.v1 | enveloped-record |
| deliver-realization-api | project-realization-api-capability |  | realization-api-delivery-request.v1 | enveloped-record | realization-api-delivery-result.v1 | enveloped-record |
| derive-api-operation-graph | derive-api-operation-graph | yes | derive-api-operation-graph-input.v1 | enveloped-record | api-operation-graph-evidence.v1 | direct-record |
| derive-canonical-execution-graph | derive-canonical-execution-graph | yes | derive-canonical-execution-graph-input.v1 | enveloped-record | canonical-execution-graph-evidence.v1 | enveloped-record |
| derive-canonical-type-graph | derive-canonical-type-graph | yes | derive-canonical-type-graph-input.v1 | enveloped-record | canonical-type-graph-evidence.v1 | enveloped-record |
| derive-cross-language-equivalence | derive-cross-language-equivalence | yes | cross-language-equivalence-input.v1 | enveloped-record | cross-language-equivalence-evidence.v1 | direct-record |
| derive-target-execution-graph | derive-target-execution-graph | yes | derive-target-execution-graph-input.v1 | enveloped-record | target-execution-graph-evidence.v1 | direct-record |
| derive-target-projection-graph | derive-target-projection-graph | yes | derive-target-projection-graph-input.v1 | enveloped-record | target-projection-graph-evidence.v1 | direct-record |
| detect-established-strategic-market-patterns | bind-market-pattern-receipt |  | market-pattern-record.v1 | direct-record | market-pattern-record.v1 | direct-record |
| detect-established-strategic-market-patterns | detect-established-strategic-market-patterns | yes | market-pattern-record.v1 | direct-record | market-pattern-record.v1 | direct-record |
| detect-established-strategic-market-patterns | verify-pattern-coverage |  | market-pattern-record.v1 | direct-record | market-pattern-record.v1 | direct-record |
| detect-established-strategic-market-patterns | verify-pattern-independence |  | market-pattern-record.v1 | direct-record | market-pattern-record.v1 | direct-record |
| detect-established-strategic-market-patterns | verify-pattern-temporality-and-contradiction |  | market-pattern-record.v1 | direct-record | market-pattern-record.v1 | direct-record |
| detect-hand-authored-code | detect-hand-authored-code | yes | hand-authored-code-detection-input.v1 | direct-record | hand-authored-code-detection-evidence.v1 | direct-record |
| determine-authority-conformance | determine-authority-conformance | yes | authority-conformance-input.v1 | enveloped-record | authority-conformance-evidence.v1 | direct-record |
| determine-behavioral-conformance | determine-behavioral-conformance | yes | behavioral-conformance-input.v1 | enveloped-record | behavioral-conformance-evidence.v1 | enveloped-record |
| determine-candidate-origin | determine-candidate-origin | yes | determine-candidate-origin-input.v1 | direct-record | candidate-origin-evidence.v1 | direct-record |
| determine-execution-closure | determine-execution-closure | yes | execution-closure-input.v1 | enveloped-record | execution-closure-evidence.v1 | direct-record |
| determine-execution-conformance | determine-execution-conformance | yes | execution-conformance-input.v1 | enveloped-record | execution-conformance-evidence.v1 | direct-record |
| determine-model-role-provider-switch | determine-model-role-provider-switch | yes | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | exhaust-model-role-provider-switch-alternatives |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | hold-unlisted-model-role-switch-condition |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | preserve-model-role-semantics-across-provider-switch |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | preserve-user-facing-stage-continuity-during-provider-switch |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | prevent-model-role-provider-switch-cycle |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | produce-deterministic-model-role-switch-selection |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | reject-incompatible-model-role-switch-target |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | respect-model-role-switch-budget-and-approval |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | retain-current-model-role-binding-after-success |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | skip-ineligible-model-role-switch-target |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-model-role-provider-switch | switch-model-role-provider-after-timeout-or-unavailability |  | determine-model-role-provider-switch-input.v1 | composed-root | model-role-provider-switch-decision-evidence.v1 | direct-record |
| determine-platform-mechanic-conformance | determine-platform-mechanic-conformance | yes | determine-platform-mechanic-conformance-input.v1 | enveloped-record | platform-mechanic-conformance-evidence.v1 | enveloped-record |
| determine-projected-shape-equivalence | determine-projected-shape-equivalence | yes | determine-shape-equivalence-input.v1 | enveloped-record | projected-shape-evidence.v1 | enveloped-record |
| determine-shape-conformance | determine-shape-conformance | yes | shape-conformance-input.v1 | enveloped-record | shape-conformance-evidence.v1 | direct-record |
| determine-sidefx-capability-authoring-disposition | determine-sidefx-capability-authoring-disposition | yes | sidefx-authoring-disposition-request.v1 | direct-record | sidefx-capability-authoring-disposition.v1 | direct-record |
| determine-sidefx-evaluation-corpus-closure | determine-sidefx-evaluation-corpus-closure | yes | sidefx-evaluation-corpus-closure-request.v1 | direct-record | sidefx-semantic-corpus-closure.v1 | composed-root |
| discover-language-bindings | discover-language-bindings | yes | language-binding-discovery-input.v1 | enveloped-record | language-binding-discovery-evidence.v1 | enveloped-record |
| establish-capsule-first-repository-closure | establish-capsule-first-repository-closure | yes | capsule-first-repository-closure-request.v1 | enveloped-record | capsule-first-repository-closure-evidence.v1 | enveloped-record |
| establish-human-capability-ownership-review-receipt | establish-human-capability-ownership-review-receipt | yes | approved-human-capability-ownership-review-transcription.v1 | enveloped-record | human-capability-ownership-review-receipt.v1 | enveloped-record |
| evaluate-scenario-solution-candidate | admit-solution-evaluation-boundary |  | scenario-solution-candidate-evaluation-request.v1 | direct-record | admitted-solution-evaluation-boundary.v1 | direct-record |
| evaluate-scenario-solution-candidate | evaluate-declared-solution-identities |  | admitted-solution-evaluation-boundary.v1 | direct-record | evaluated-solution-identities.v1 | direct-record |
| evaluate-scenario-solution-candidate | evaluate-scenario-solution-candidate | yes | scenario-solution-candidate-evaluation-request.v1 | direct-record | evaluated-scenario-solution.v1 | direct-record |
| evaluate-scenario-solution-candidate | resolve-scenario-solution-admission |  | evaluated-solution-identities.v1 | direct-record | evaluated-scenario-solution.v1 | direct-record |
| evaluate-semantic-carrier-compilation-evidence | evaluate-semantic-carrier-compilation | yes | semantic-carrier-compilation-evaluation-request.v1 | enveloped-record | semantic-carrier-compilation-evaluation-stage.v1 | direct-record |
| evaluate-semantic-carrier-compilation-evidence | return-evaluation-held |  | semantic-carrier-compilation-evaluation-stage.v1 | direct-record | semantic-carrier-compilation-evaluation-result.v1 | direct-record |
| evaluate-semantic-carrier-compilation-evidence | return-evaluator-replacement-for-independent-adjudication |  | semantic-carrier-compilation-evaluation-stage.v1 | direct-record | semantic-carrier-compilation-evaluation-result.v1 | direct-record |
| evaluate-semantic-carrier-compilation-evidence | return-review-ready-evaluation |  | semantic-carrier-compilation-evaluation-stage.v1 | direct-record | semantic-carrier-compilation-evaluation-result.v1 | direct-record |
| evaluate-sidefx-proof-binding | accept-explicit-or-deterministic-current-binding |  | sidefx-proof-binding-evaluation-record.v1 | direct-record | sidefx-proof-binding-evaluation-record.v1 | direct-record |
| evaluate-sidefx-proof-binding | evaluate-sidefx-proof-binding | yes | sidefx-proof-binding-evaluation-input.v1 | enveloped-record | sidefx-proof-binding-evaluation-record.v1 | direct-record |
| evaluate-sidefx-proof-binding | reject-prohibited-binding-basis |  | sidefx-proof-binding-evaluation-record.v1 | direct-record | sidefx-proof-binding-evaluation-record.v1 | direct-record |
| evaluate-sidefx-proof-binding | reject-stale-or-mixed-proof-lineage |  | sidefx-proof-binding-evaluation-record.v1 | direct-record | sidefx-proof-binding-evaluation-record.v1 | direct-record |
| evaluate-sidefx-proof-binding | report-admitted-exclusion-not-applicable |  | sidefx-proof-binding-evaluation-record.v1 | direct-record | sidefx-proof-binding-evaluation-record.v1 | direct-record |
| evaluate-sidefx-proof-binding | report-current-failure-not-satisfied |  | sidefx-proof-binding-evaluation-record.v1 | direct-record | sidefx-proof-binding-evaluation-record.v1 | direct-record |
| evaluate-sidefx-proof-binding | report-missing-evidence-not-observable |  | sidefx-proof-binding-evaluation-record.v1 | direct-record | sidefx-proof-binding-evaluation-record.v1 | direct-record |
| evaluate-sidefx-proof-binding | reproduce-proof-binding-evaluation-deterministically |  | sidefx-proof-binding-evaluation-record.v1 | direct-record | sidefx-proof-binding-evaluation-record.v1 | direct-record |
| evaluate-sidefx-verification-coverage | evaluate-sidefx-verification-coverage | yes | sidefx-verification-coverage-request.v1 | direct-record | sidefx-semantic-verification-coverage.v1 | direct-record |
| execute-admitted-capability | admit-outcome-and-emit-testimony |  | capability-execution-record.v1 | composed-root | capability-execution-record.v1 | composed-root |
| execute-admitted-capability | admit-scenario-input |  | capability-execution-record.v1 | composed-root | capability-execution-record.v1 | composed-root |
| execute-admitted-capability | bind-execution-receipt |  | capability-execution-record.v1 | composed-root | capability-execution-record.v1 | composed-root |
| execute-admitted-capability | execute-admitted-capability | yes | capability-execution-record.v1 | composed-root | capability-execution-record.v1 | composed-root |
| execute-admitted-capability | execute-declared-graph |  | capability-execution-record.v1 | composed-root | capability-execution-record.v1 | composed-root |
| execute-capsule-direct | admit-direct-execution-evidence |  | capsule-direct-execution-record.v1 | direct-record | capsule-direct-execution-record.v1 | direct-record |
| execute-capsule-direct | bind-direct-execution-receipt |  | capsule-direct-execution-record.v1 | direct-record | capsule-direct-execution-record.v1 | direct-record |
| execute-capsule-direct | execute-capsule-direct | yes | capsule-direct-execution-record.v1 | direct-record | capsule-direct-execution-record.v1 | direct-record |
| execute-capsule-direct | verify-capsule-gate |  | capsule-direct-execution-record.v1 | direct-record | capsule-direct-execution-record.v1 | direct-record |
| execute-capsule-runtime | admit-capsule-runtime-integrity |  | capsule-runtime-record.v1 | enveloped-record | capsule-runtime-record.v1 | enveloped-record |
| execute-capsule-runtime | bind-capsule-runtime-receipt |  | capsule-runtime-record.v1 | enveloped-record | capsule-runtime-record.v1 | enveloped-record |
| execute-capsule-runtime | execute-capsule-runtime | yes | capsule-runtime-record.v1 | enveloped-record | capsule-runtime-record.v1 | enveloped-record |
| execute-capsule-runtime | observe-capsule-execution-trace |  | capsule-runtime-record.v1 | enveloped-record | capsule-runtime-record.v1 | enveloped-record |
| execute-capsule-runtime | refuse-capsule-effect-boundary |  | capsule-runtime-record.v1 | enveloped-record | capsule-runtime-record.v1 | enveloped-record |
| execute-capsule-runtime | resolve-capsule-execution-authority |  | capsule-runtime-record.v1 | enveloped-record | capsule-runtime-record.v1 | enveloped-record |
| execute-governed-model-invocation | cancel-model-invocation |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | classify-internal-model-execution-failure |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | classify-model-provider-authentication-failure |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | classify-model-provider-timeout |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | classify-model-provider-unavailability |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | continue-transient-model-attempt |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | execute-governed-model-invocation | yes | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | exhaust-model-attempt-authority |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | fail-unavailable-model-credential |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | honor-model-evidence-policy |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | obtain-structured-model-response |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | preserve-canonical-model-request-identity |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | prevent-undeclared-model-attempt-or-substitution |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | reject-invalid-governed-model-request |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | reject-malformed-structured-model-response |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | reject-schema-incompatible-model-response |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | reject-stale-model-provider-binding |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | retain-model-provider-request-rejection |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | return-model-execution-receipt-on-every-exit |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-invocation | stop-non-transient-model-attempt |  | execute-governed-model-invocation-input.v1 | composed-root | governed-model-invocation-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | cancel-model-role-conveyor |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | enforce-model-role-attempt-switch-and-budget-limits |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | execute-governed-model-role-conveyor | yes | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | execute-only-eligible-model-role-stage |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | hold-dependent-model-roles-after-stage-failure |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | invoke-exact-model-role-binding |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | present-stable-model-role-conveyor-experience |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | preserve-model-role-context-isolation |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | preserve-model-role-testimony-authority-boundary |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | prevent-undeclared-model-role-substitution |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | require-model-role-stage-effect-approval |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | resume-model-role-conveyor-from-receipts |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | switch-model-role-provider-after-usage-failure |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-model-role-conveyor | validate-model-role-stage-output-contract |  | execute-governed-model-role-conveyor-input.v1 | composed-root | governed-model-role-conveyor-evidence.v1 | direct-record |
| execute-governed-serial-tooling-migration | execute-governed-serial-tooling-migration | yes | governed-serial-tooling-migration-request.v1 | composed-root | governed-serial-tooling-migration-request.v1 | composed-root |
| execute-governed-serial-tooling-migration | observe-governed-serial-tooling-migration-execution |  | bounded-governed-serial-tooling-migration-context.v1 | composed-root | governed-serial-tooling-migration-execution-observation.v1 | composed-root |
| execute-governed-serial-tooling-migration | publish-governed-serial-tooling-migration-evidence |  | governed-serial-tooling-migration-execution-observation.v1 | composed-root | governed-serial-tooling-migration-evidence.v1 | composed-root |
| execute-governed-serial-tooling-migration | resolve-governed-serial-tooling-migration-scope |  | governed-serial-tooling-migration-request.v1 | composed-root | bounded-governed-serial-tooling-migration-context.v1 | composed-root |
| execute-projected-model-provider-attempt | execute-projected-model-provider-attempt | yes | execute-projected-model-provider-attempt-input.v1 | enveloped-record | projected-model-provider-attempt-evidence.v1 | direct-record |
| extract-semantic-carrier-graph | extract-canonical-carrier-graph | yes | semantic-carrier-extraction-request.v1 | enveloped-record | semantic-carrier-extraction-stage.v1 | composed-root |
| extract-semantic-carrier-graph | return-extracted-graph |  | semantic-carrier-extraction-stage.v1 | composed-root | semantic-carrier-extraction-result.v1 | composed-root |
| extract-semantic-carrier-graph | return-extraction-held |  | semantic-carrier-extraction-stage.v1 | composed-root | semantic-carrier-extraction-result.v1 | composed-root |
| generate-executable-capability-scaffold | condition-scaffold-on-admitted-blueprint |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | derive-blueprint-carrier-from-declared-scenarios |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | derive-capability-slots-from-dependencies |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | derive-evidence-obligations-from-outcomes |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | derive-mechanic-slots-from-circuit |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | derive-provider-slots-from-altitude-descents |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | emit-mechanical-authoring-artifacts |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | emit-next-bounded-authoring-obligation |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | generate-executable-capability-scaffold | yes | executable-scaffold-request.v1 | composed-root | executable-capability-scaffold.v1 | direct-record |
| generate-executable-capability-scaffold | generate-standard-execution-shell |  | executable-scaffold-request.v1 | composed-root | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | preserve-semantic-transformation-as-unresolved |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | prove-blueprint-embodiment |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | reject-business-meaning-in-execution-shell |  | executable-scaffold-request.v1 | composed-root | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | replay-scaffold-generation |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | resolve-scaffold-completeness-level |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-executable-capability-scaffold | resolve-slots-against-admitted-estate |  | scaffold-derivation-carrier.v1 | direct-record | scaffold-derivation-carrier.v1 | direct-record |
| generate-governed-narration | admit-governed-narration-asset |  | attributable-narration-artifact.v1 | enveloped-record | video-narration-asset.v1 | enveloped-record |
| generate-governed-narration | generate-governed-narration | yes | presentation-scene-graph.v1 | enveloped-record | video-narration-asset.v1 | enveloped-record |
| generate-governed-narration | invoke-governed-narration-provider |  | authorized-narration-generation-request.v1 | enveloped-record | narration-media-testimony.v1 | enveloped-record |
| generate-governed-narration | materialize-narration-artifact |  | narration-media-testimony.v1 | enveloped-record | attributable-narration-artifact.v1 | enveloped-record |
| generate-governed-narration | resolve-narration-generation-authority |  | presentation-scene-graph.v1 | enveloped-record | authorized-narration-generation-request.v1 | enveloped-record |
| govern-authoring-convergence | bind-normalized-authoring-findings |  | authoring-convergence-record.v1 | enveloped-record | authoring-convergence-record.v1 | enveloped-record |
| govern-authoring-convergence | evaluate-execution-authority-closure |  | authoring-convergence-record.v1 | enveloped-record | authoring-convergence-record.v1 | enveloped-record |
| govern-authoring-convergence | evaluate-expression-operator-conformance |  | authoring-convergence-record.v1 | enveloped-record | authoring-convergence-record.v1 | enveloped-record |
| govern-authoring-convergence | evaluate-literal-discriminator-conformance |  | authoring-convergence-record.v1 | enveloped-record | authoring-convergence-record.v1 | enveloped-record |
| govern-authoring-convergence | evaluate-observed-sequence-closure |  | authoring-convergence-record.v1 | enveloped-record | authoring-convergence-record.v1 | enveloped-record |
| govern-authoring-convergence | evaluate-port-binding-closure |  | authoring-convergence-record.v1 | enveloped-record | authoring-convergence-record.v1 | enveloped-record |
| govern-authoring-convergence | evaluate-scenario-edge-realization |  | authoring-convergence-record.v1 | enveloped-record | authoring-convergence-record.v1 | enveloped-record |
| govern-authoring-convergence | govern-authoring-convergence | yes | authoring-convergence-record.v1 | enveloped-record | authoring-convergence-record.v1 | enveloped-record |
| govern-authoring-convergence | resolve-convergence-disposition |  | authoring-convergence-record.v1 | enveloped-record | authoring-convergence-record.v1 | enveloped-record |
| govern-model-provider-binding | govern-model-provider-binding | yes | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | hold-unknown-model-provider-authority |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | hold-unresolved-model-alias |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | hold-unsupported-model-interaction-mode |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | reject-ambiguous-model-provider-authority |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | reject-credential-bearing-model-provider-authority |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | reject-divergent-model-adapter-host-coverage |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | reject-incompatible-model-provider-adapter |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | reject-invalid-model-provider-authority |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | reject-stale-or-mutable-model-provider-binding |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | reject-unauthorized-model-provider-endpoint |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | reject-unprojected-model-provider-adapter |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-model-provider-binding | resolve-distinct-model-bindings-across-providers |  | govern-model-provider-binding-input.v1 | composed-root | governed-model-provider-binding-evidence.v1 | direct-record |
| govern-strategic-decision | admit-strategic-decision-authorization |  | strategic-decision-record.v1 | direct-record | strategic-decision-record.v1 | direct-record |
| govern-strategic-decision | bind-strategic-decision-lineage |  | strategic-decision-record.v1 | direct-record | strategic-decision-record.v1 | direct-record |
| govern-strategic-decision | bind-strategic-decision-receipt |  | strategic-decision-record.v1 | direct-record | strategic-decision-record.v1 | direct-record |
| govern-strategic-decision | govern-strategic-decision | yes | strategic-decision-record.v1 | direct-record | strategic-decision-record.v1 | direct-record |
| govern-strategic-decision-v2 | bind-strategic-decision-receipt |  | strategic-decision-record.v2 | direct-record | strategic-decision-record.v2 | direct-record |
| govern-strategic-decision-v2 | govern-strategic-decision-v2 | yes | strategic-decision-record.v2 | direct-record | strategic-decision-record.v2 | direct-record |
| govern-strategic-decision-v2 | verify-decision-authorization |  | strategic-decision-record.v2 | direct-record | strategic-decision-record.v2 | direct-record |
| govern-strategic-decision-v2 | verify-decision-choice-and-rationale |  | strategic-decision-record.v2 | direct-record | strategic-decision-record.v2 | direct-record |
| govern-strategic-decision-v2 | verify-decision-review-binding |  | strategic-decision-record.v2 | direct-record | strategic-decision-record.v2 | direct-record |
| greet-by-name | greet-by-name | yes | personal-greeting-request.v1 | enveloped-record | personal-greeting.v1 | enveloped-record |
| ground-sidefx-semantic-query-results | ground-sidefx-semantic-query-results | yes | sidefx-semantic-grounding-request.v1 | direct-record | sidefx-semantic-grounded-result.v1 | direct-record |
| ingest-sidefx-json-authority | hold-json-authority-with-missing-declared-schema |  | sidefx-json-authority-ingestion-receipt.v1 | composed-root | sidefx-json-authority-ingestion-receipt.v1 | composed-root |
| ingest-sidefx-json-authority | hold-json-authority-with-unsupported-version-or-dangling-reference |  | sidefx-json-authority-ingestion-receipt.v1 | composed-root | sidefx-json-authority-ingestion-receipt.v1 | composed-root |
| ingest-sidefx-json-authority | ingest-schema-admitted-json-authority | yes | sidefx-json-authority-ingestion-request.v1 | direct-record | sidefx-json-authority-ingestion-receipt.v1 | composed-root |
| ingest-sidefx-json-authority | reject-json-source-class-escalation |  | sidefx-json-authority-ingestion-receipt.v1 | composed-root | sidefx-json-authority-ingestion-receipt.v1 | composed-root |
| ingest-sidefx-json-authority | reject-malformed-or-duplicate-key-json-authority |  | sidefx-json-authority-ingestion-receipt.v1 | composed-root | sidefx-json-authority-ingestion-receipt.v1 | composed-root |
| ingest-sidefx-json-authority | reproduce-json-authority-ingestion-deterministically |  | sidefx-json-authority-ingestion-receipt.v1 | composed-root | sidefx-json-authority-ingestion-receipt.v1 | composed-root |
| inspect-canonical-circuit-blueprint-candidate | bind-blueprint-conformance-disposition |  | blueprint-inspection-record.v1 | enveloped-record | canonical-blueprint-conformance-evidence.v1 | enveloped-record |
| inspect-canonical-circuit-blueprint-candidate | inspect-altitude-appropriate-cell-geometry |  | canonical-blueprint-inspection-request.v1 | enveloped-record | blueprint-inspection-disposition.v1 | enveloped-record |
| inspect-canonical-circuit-blueprint-candidate | inspect-canonical-circuit-blueprint-candidate | yes | canonical-blueprint-inspection-request.v1 | enveloped-record | canonical-blueprint-conformance-evidence.v1 | enveloped-record |
| inspect-canonical-circuit-blueprint-candidate | inspect-declared-field-support |  | canonical-blueprint-inspection-request.v1 | enveloped-record | blueprint-inspection-disposition.v1 | enveloped-record |
| inspect-canonical-circuit-blueprint-candidate | inspect-feature-obligation-and-partition-coverage |  | canonical-blueprint-inspection-request.v1 | enveloped-record | blueprint-inspection-disposition.v1 | enveloped-record |
| inspect-canonical-circuit-blueprint-candidate | inspect-observability-and-service-level-coverage |  | canonical-blueprint-inspection-request.v1 | enveloped-record | blueprint-inspection-disposition.v1 | enveloped-record |
| inspect-canonical-circuit-blueprint-candidate | inspect-semantic-precedence |  | canonical-blueprint-inspection-request.v1 | enveloped-record | blueprint-inspection-disposition.v1 | enveloped-record |
| inspect-canonical-circuit-blueprint-candidate | validate-blueprint-inspection-request |  | canonical-blueprint-inspection-request.v1 | enveloped-record | blueprint-inspection-request-validation.v1 | enveloped-record |
| inspect-delegated-capability-candidate | derive-feature-derived-candidate-slot-scope |  | observed-delegated-candidate-inspection-inputs.v1 | composed-root | feature-derived-candidate-slot-scope.v1 | composed-root |
| inspect-delegated-capability-candidate | inspect-declarative-candidate-artifact-slots |  | feature-derived-candidate-slot-scope.v1 | composed-root | inspected-declarative-candidate-artifact-slots.v1 | composed-root |
| inspect-delegated-capability-candidate | inspect-delegated-capability-candidate | yes | delegated-capability-candidate-inspection-request.v1 | composed-root | candidate-slot-admission-evidence.v1 | composed-root |
| inspect-delegated-capability-candidate | observe-delegated-candidate-inspection-inputs |  | delegated-capability-candidate-inspection-request.v1 | composed-root | observed-delegated-candidate-inspection-inputs.v1 | composed-root |
| inspect-delegated-capability-candidate | resolve-declarative-candidate-slot-disposition |  | inspected-declarative-candidate-artifact-slots.v1 | composed-root | candidate-slot-admission-evidence.v1 | composed-root |
| interlock-agent-operation | activate-agent-interlock |  | admitted-agent-interlock-activation-request.v1 | enveloped-record | agent-interlock-activation-outcome.v1 | enveloped-record |
| interlock-agent-operation | adjudicate-covered-agent-tool-call |  | covered-agent-tool-call.v1 | enveloped-record | agent-tool-call-disposition.v1 | enveloped-record |
| interlock-agent-operation | admit-agent-interlock-request |  | agent-interlock-operation-request.v1 | enveloped-record | admitted-agent-interlock-request.v1 | enveloped-record |
| interlock-agent-operation | certify-live-agent-interlock |  | agent-interlock-certification-request.v1 | enveloped-record | agent-interlock-certification-outcome.v1 | enveloped-record |
| interlock-agent-operation | hold-untrusted-or-uncovered-agent-operation |  | untrusted-agent-operation.v1 | enveloped-record | governance-hold.v1 | enveloped-record |
| interlock-agent-operation | interlock-agent-operation | yes | agent-interlock-operation-request.v1 | enveloped-record | agent-interlock-operation-outcome.v1 | enveloped-record |
| interlock-agent-operation | protect-agent-interlock-control-plane |  | agent-interlock-control-request.v1 | enveloped-record | agent-interlock-control-outcome.v1 | enveloped-record |
| manage-capability-capsule | bind-capsule-reference |  | capability-capsule-record.v1 | direct-record | capability-capsule-record.v1 | direct-record |
| manage-capability-capsule | collapse-admitted-capability | yes | capability-capsule-record.v1 | direct-record | capability-capsule-record.v1 | direct-record |
| manage-capability-capsule | prove-capsule-round-trip-closure |  | capability-capsule-record.v1 | direct-record | capability-capsule-record.v1 | direct-record |
| manage-capability-capsule | reproduce-capsule-digest |  | capability-capsule-record.v1 | direct-record | capability-capsule-record.v1 | direct-record |
| manage-capability-capsule | resolve-capsule-contract-resource-closure |  | capability-capsule-record.v1 | direct-record | capability-capsule-record.v1 | direct-record |
| manage-capability-capsule | resolve-minimum-sufficient-representation |  | capability-capsule-record.v1 | direct-record | capability-capsule-record.v1 | direct-record |
| manage-capability-capsule | reveal-capability-representation |  | capability-capsule-record.v1 | direct-record | capability-capsule-record.v1 | direct-record |
| manage-capability-capsule | verify-capsule-self-description-boundary |  | capability-capsule-record.v1 | direct-record | capability-capsule-record.v1 | direct-record |
| materialize-authorized-file-batch | derive-authorized-file-batch-plan |  | authorized-file-batch-materialization-request.v1 | direct-record | authorized-file-batch-materialization-plan.v1 | direct-record |
| materialize-authorized-file-batch | materialize-authorized-file-batch | yes | authorized-file-batch-materialization-request.v1 | direct-record | authorized-file-batch-materialization-outcome.v1 | direct-record |
| materialize-authorized-file-batch | materialize-authorized-file-batch-effect |  | authorized-file-batch-materialization-plan.v1 | direct-record | authorized-file-batch-materialization-effect.v1 | direct-record |
| materialize-authorized-file-batch | project-authorized-file-batch-outcome |  | authorized-file-batch-materialization-effect.v1 | direct-record | authorized-file-batch-materialization-outcome.v1 | direct-record |
| materialize-converged-candidate | materialize-converged-candidate | yes | candidate-materialization-record.v1 | enveloped-record | candidate-materialization-record.v1 | enveloped-record |
| materialize-projectable-capability-candidate | materialize-projectable-capability-candidate | yes | admitted-projectable-capability-candidate.v1 | direct-record | materialized-projectable-capability-candidate.v1 | direct-record |
| observe-capability-change | hold-unobservable-capability-change |  | capability-change-observation-findings.v1 | enveloped-record | held-capability-change-observation.v1 | enveloped-record |
| observe-capability-change | observe-capability-change | yes | capability-change-status-request.v1 | enveloped-record | capability-change-status.v1 | enveloped-record |
| observe-capability-change | represent-capability-change-evidence |  | capability-change-state.v1 | enveloped-record | capability-change-evidence-view.v1 | enveloped-record |
| observe-capability-change | resolve-capability-change-next-action |  | capability-change-state.v1 | enveloped-record | capability-change-next-action.v1 | enveloped-record |
| observe-capability-change | resolve-capability-change-state |  | capability-change-status-request.v1 | enveloped-record | capability-change-state.v1 | enveloped-record |
| observe-governed-http-exchange | cancel-governed-http-exchange |  | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-http-exchange | observe-governed-http-exchange | yes | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-http-exchange | observe-governed-http-timeout |  | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-http-exchange | observe-governed-http-transport-failure |  | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-http-exchange | observe-non-success-http-response |  | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-http-exchange | prove-http-secret-redaction |  | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-http-exchange | prove-single-http-exchange-authority |  | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-http-exchange | reject-http-endpoint-outside-authority |  | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-http-exchange | reject-invalid-http-credential-binding |  | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-http-exchange | reject-oversized-http-response |  | observe-governed-http-exchange-input.v1 | composed-root | governed-http-exchange-evidence.v1 | direct-record |
| observe-governed-repository | observe-bounded-governed-repository-facts |  | bounded-governed-repository-observation-context.v1 | composed-root | governed-repository-observation.v1 | reference-root |
| observe-governed-repository | observe-governed-repository | yes | governed-repository-observation-request.v1 | composed-root | governed-repository-observation-request.v1 | composed-root |
| observe-governed-repository | resolve-governed-repository-observation-scope |  | governed-repository-observation-request.v1 | composed-root | bounded-governed-repository-observation-context.v1 | composed-root |
| observe-language-behavior | observe-language-behavior | yes | language-behavior-observation-input.v1 | enveloped-record | language-behavior-observation-evidence.v1 | enveloped-record |
| observe-live-model-connection | hold-live-model-connection-with-unavailable-credential |  | observe-live-model-connection-input.v1 | composed-root | live-model-connection-observation-evidence.v1 | direct-record |
| observe-live-model-connection | hold-live-model-identity-drift |  | observe-live-model-connection-input.v1 | composed-root | live-model-connection-observation-evidence.v1 | direct-record |
| observe-live-model-connection | hold-unproven-live-model-runtime-or-conformance |  | observe-live-model-connection-input.v1 | composed-root | live-model-connection-observation-evidence.v1 | direct-record |
| observe-live-model-connection | observe-live-model-connection | yes | observe-live-model-connection-input.v1 | composed-root | live-model-connection-observation-evidence.v1 | direct-record |
| observe-live-model-connection | prove-live-model-testimony-is-non-gating |  | observe-live-model-connection-input.v1 | composed-root | live-model-connection-observation-evidence.v1 | direct-record |
| observe-live-model-connection | prove-single-attempt-live-model-observation |  | observe-live-model-connection-input.v1 | composed-root | live-model-connection-observation-evidence.v1 | direct-record |
| observe-live-model-connection | reject-live-model-endpoint-outside-policy |  | observe-live-model-connection-input.v1 | composed-root | live-model-connection-observation-evidence.v1 | direct-record |
| observe-live-model-connection | reject-unauthorized-live-model-connection |  | observe-live-model-connection-input.v1 | composed-root | live-model-connection-observation-evidence.v1 | direct-record |
| observe-live-model-connection | retain-live-model-provider-failure |  | observe-live-model-connection-input.v1 | composed-root | live-model-connection-observation-evidence.v1 | direct-record |
| observe-native-presentation | observe-native-presentation | yes | observe-native-presentation-input.v1 | enveloped-record | native-presentation-testimony.v1 | direct-record |
| observe-projected-target-execution | observe-bounded-projected-target-execution |  | bounded-projected-target-execution-context.v1 | composed-root | projected-target-execution-observation.v1 | composed-root |
| observe-projected-target-execution | observe-projected-target-execution | yes | projected-target-execution-request.v1 | composed-root | projected-target-execution-request.v1 | composed-root |
| observe-projected-target-execution | resolve-governed-target-execution-scope |  | projected-target-execution-request.v1 | composed-root | bounded-projected-target-execution-context.v1 | composed-root |
| obtain-governed-model-response | establish-governed-model-response-evidence |  | governed-provider-testimony.v1 | enveloped-record | governed-model-response-evidence.v1 | composed-root |
| obtain-governed-model-response | obtain-governed-model-response | yes | governed-model-invocation-request.v1 | composed-root | governed-model-response-evidence.v1 | composed-root |
| obtain-governed-model-response | obtain-governed-provider-testimony |  | model-provider-protocol-response-policy.v1 | direct-record | governed-provider-testimony.v1 | enveloped-record |
| obtain-governed-model-response | project-model-response-policy-to-provider-protocol |  | model-provider-embodiment-resolution.v1 | direct-record | model-provider-protocol-response-policy.v1 | direct-record |
| obtain-governed-model-response | resolve-model-alias-embodiment |  | governed-model-invocation-request.v1 | composed-root | model-provider-embodiment-resolution.v1 | direct-record |
| obtain-governed-speech-media | observe-governed-speech-exchange |  | speech-generation-invocation.v1 | enveloped-record | speech-provider-observation.v1 | enveloped-record |
| obtain-governed-speech-media | obtain-governed-speech-media | yes | authorized-narration-generation-request.v1 | enveloped-record | narration-media-testimony.v1 | enveloped-record |
| obtain-governed-speech-media | project-speech-generation-request |  | authorized-narration-generation-request.v1 | enveloped-record | speech-generation-invocation.v1 | enveloped-record |
| open-capability-change | establish-capability-change-authoring-boundary |  | capability-change-impact.v1 | enveloped-record | capability-change-authoring-boundary.v1 | enveloped-record |
| open-capability-change | hold-unopenable-capability-change |  | capability-change-opening-findings.v1 | enveloped-record | held-capability-change.v1 | enveloped-record |
| open-capability-change | open-capability-change | yes | capability-change-open-request.v1 | enveloped-record | capability-change-set.v1 | enveloped-record |
| open-capability-change | resolve-capability-change-baseline |  | capability-change-kind.v1 | enveloped-record | capability-change-origin.v1 | enveloped-record |
| open-capability-change | resolve-capability-change-impact |  | capability-change-origin.v1 | enveloped-record | capability-change-impact.v1 | enveloped-record |
| open-capability-change | resolve-capability-change-kind |  | capability-change-open-request.v1 | enveloped-record | capability-change-kind.v1 | enveloped-record |
| open-capability-change | resolve-first-admission-authority |  | capability-change-kind.v1 | enveloped-record | capability-change-origin.v1 | enveloped-record |
| operate-capsule-estate | discover-and-inspect-capsules |  | capsule-estate-operation-request.v2 | enveloped-record | capsule-estate-operation-result.v2 | enveloped-record |
| operate-capsule-estate | execute-capsule-carried-capabilities |  | capsule-estate-operation-request.v2 | enveloped-record | capsule-estate-operation-result.v2 | enveloped-record |
| operate-capsule-estate | operate-capsule-estate | yes | capsule-estate-operation-request.v2 | enveloped-record | capsule-estate-operation-result.v2 | enveloped-record |
| operate-capsule-estate | prove-capsule-first-checkout-closure |  | capsule-estate-operation-request.v2 | enveloped-record | capsule-estate-operation-result.v2 | enveloped-record |
| operate-capsule-estate | reconstruct-and-project-capsule-estate |  | capsule-estate-operation-request.v2 | enveloped-record | capsule-estate-operation-result.v2 | enveloped-record |
| operate-capsule-estate | resolve-capsule-estate-dependencies |  | capsule-estate-operation-request.v2 | enveloped-record | capsule-estate-operation-result.v2 | enveloped-record |
| operate-capsule-estate | verify-capsule-estate |  | capsule-estate-operation-request.v2 | enveloped-record | capsule-estate-operation-result.v2 | enveloped-record |
| operate-tooling-migration-conveyor | construct-declared-tooling-migration-operation-plan |  | observed-tooling-migration-authority.v1 | composed-root | declared-tooling-migration-operation-plan.v1 | composed-root |
| operate-tooling-migration-conveyor | execute-declared-tooling-migration-operation-plan |  | declared-tooling-migration-operation-plan.v1 | composed-root | observed-tooling-migration-operation.v1 | composed-root |
| operate-tooling-migration-conveyor | observe-declared-tooling-migration-authority |  | tooling-migration-operation-context.v1 | composed-root | observed-tooling-migration-authority.v1 | composed-root |
| operate-tooling-migration-conveyor | operate-tooling-migration-conveyor | yes | tooling-migration-operation-request.v1 | composed-root | tooling-migration-operation-context.v1 | composed-root |
| operate-tooling-migration-conveyor | publish-declared-tooling-migration-operation-evidence |  | resolved-tooling-migration-operation.v1 | composed-root | tooling-migration-operation-evidence.v1 | composed-root |
| operate-tooling-migration-conveyor | resolve-tooling-migration-operation-disposition |  | observed-tooling-migration-operation.v1 | composed-root | resolved-tooling-migration-operation.v1 | composed-root |
| operate-tooling-migration-inventory | classify-declared-tooling-migration-inventory |  | observed-tooling-migration-inventory-authority.v1 | composed-root | classified-tooling-migration-inventory.v1 | composed-root |
| operate-tooling-migration-inventory | observe-declared-tooling-migration-inventory-authority |  | tooling-migration-inventory-context.v1 | composed-root | observed-tooling-migration-inventory-authority.v1 | composed-root |
| operate-tooling-migration-inventory | operate-tooling-migration-inventory | yes | tooling-migration-inventory-request.v1 | enveloped-record | tooling-migration-inventory-context.v1 | composed-root |
| operate-tooling-migration-inventory | publish-tooling-migration-inventory-outcome |  | classified-tooling-migration-inventory.v1 | composed-root | tooling-migration-inventory-evidence.v1 | composed-root |
| operate-tooling-migration-promote | operate-tooling-migration-promote | yes | tooling-migration-promote-request.v1 | composed-root | tooling-migration-promote-request.v1 | composed-root |
| operate-tooling-migration-promote | project-and-observe-tooling-candidate |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| operate-tooling-migration-promote | prove-tooling-candidate-oracle-equivalence |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| operate-tooling-migration-promote | resolve-tooling-candidate-verification |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| operate-tooling-migration-promote | resolve-tooling-migration-promote-operation |  | tooling-migration-promote-request.v1 | composed-root | UNRESOLVED | unresolved |
| operate-tooling-migration-promote | transact-tooling-provider-promotion |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| operate-tooling-migration-promote | verify-tooling-candidate-authoring-lineage |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| operate-tooling-migration-run | execute-serial-tooling-migration-run |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| operate-tooling-migration-run | operate-tooling-migration-run | yes | tooling-migration-run-request.v1 | enveloped-record | tooling-migration-run-request.v1 | enveloped-record |
| operate-tooling-migration-run | resolve-tooling-migration-run-operation |  | tooling-migration-run-request.v1 | enveloped-record | UNRESOLVED | unresolved |
| operate-tooling-migration-verify | operate-tooling-migration-verify | yes | tooling-migration-verify-request.v1 | composed-root | tooling-migration-verify-request.v1 | composed-root |
| operate-tooling-migration-verify | project-and-observe-tooling-candidate |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| operate-tooling-migration-verify | prove-tooling-candidate-oracle-equivalence |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| operate-tooling-migration-verify | resolve-tooling-candidate-verification |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| operate-tooling-migration-verify | resolve-tooling-migration-verify-operation |  | tooling-migration-verify-request.v1 | composed-root | UNRESOLVED | unresolved |
| operate-tooling-migration-verify | verify-tooling-candidate-authoring-lineage |  | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| preserve-admitted-projection-on-incomplete-regeneration | preserve-admitted-projection-on-incomplete-regeneration | yes | preserve-admitted-projection-input.v1 | enveloped-record | projection-preservation-evidence.v1 | direct-record |
| project-accessibility-binding | project-accessibility-binding | yes | project-accessibility-binding-input.v1 | enveloped-record | accessibility-binding-projection-evidence.v1 | direct-record |
| project-activation-binding | project-activation-binding | yes | project-activation-binding-input.v1 | enveloped-record | activation-binding-projection-evidence.v1 | direct-record |
| project-adaptation-binding | project-adaptation-binding | yes | project-adaptation-binding-input.v1 | enveloped-record | adaptation-binding-projection-evidence.v1 | direct-record |
| project-and-prove-semantic-carrier-graph | project-and-prove-canonical-graph | yes | semantic-carrier-graph-proof-request.v1 | direct-record | semantic-carrier-graph-proof-result.v1 | direct-record |
| project-and-prove-semantic-carrier-graph | return-proof-held |  | semantic-carrier-graph-proof-result.v1 | direct-record | semantic-carrier-graph-proof-result.v1 | direct-record |
| project-and-prove-semantic-carrier-graph | return-proof-passed |  | semantic-carrier-graph-proof-result.v1 | direct-record | semantic-carrier-graph-proof-result.v1 | direct-record |
| project-availability-presentation | project-availability-presentation | yes | project-availability-presentation-input.v1 | enveloped-record | availability-presentation-projection-evidence.v1 | direct-record |
| project-canonical-circuit-blueprint | bind-canonical-circuit-blueprint-projection-receipt |  | blueprint-replay-disposition.v1 | enveloped-record | canonical-circuit-blueprint-projection-bundle.v2 | enveloped-record |
| project-canonical-circuit-blueprint | compose-canonical-blueprint-review-document |  | blueprint-lens-set.v1 | enveloped-record | canonical-blueprint-review-document.v1 | enveloped-record |
| project-canonical-circuit-blueprint | project-canonical-circuit-blueprint | yes | canonical-circuit-blueprint-projection-request.v1 | composed-root | canonical-circuit-blueprint-projection-bundle.v2 | enveloped-record |
| project-canonical-circuit-blueprint | project-canonical-circuit-blueprint-ascii |  | canonical-circuit-blueprint.v1 | enveloped-record | blueprint-projection-source.v1 | enveloped-record |
| project-canonical-circuit-blueprint | project-canonical-circuit-blueprint-mermaid |  | canonical-circuit-blueprint.v1 | enveloped-record | blueprint-projection-source.v1 | enveloped-record |
| project-canonical-circuit-blueprint | project-declared-blueprint-lenses |  | canonical-circuit-blueprint.v1 | enveloped-record | blueprint-lens-set.v1 | enveloped-record |
| project-canonical-circuit-blueprint | resolve-canonical-circuit-blueprint |  | canonical-circuit-blueprint-projection-request.v1 | composed-root | canonical-circuit-blueprint.v1 | enveloped-record |
| project-canonical-circuit-blueprint | verify-canonical-blueprint-review-document |  | canonical-blueprint-review-document.v1 | enveloped-record | canonical-blueprint-review-document-disposition.v1 | enveloped-record |
| project-canonical-circuit-blueprint | verify-canonical-circuit-blueprint-replay |  | blueprint-lens-set.v1 | enveloped-record | blueprint-replay-disposition.v1 | enveloped-record |
| project-capability-revelation | bind-revelation-receipt |  | capability-revelation-record.v1 | direct-record | capability-revelation-record.v1 | direct-record |
| project-capability-revelation | project-capability-revelation | yes | capability-revelation-record.v1 | direct-record | capability-revelation-record.v1 | direct-record |
| project-capability-revelation | project-capsule-documentation-view |  | capability-revelation-record.v1 | direct-record | capability-revelation-record.v1 | direct-record |
| project-capability-revelation | project-capsule-exposure-views |  | capability-revelation-record.v1 | direct-record | capability-revelation-record.v1 | direct-record |
| project-capability-revelation | project-capsule-identity-view |  | capability-revelation-record.v1 | direct-record | capability-revelation-record.v1 | direct-record |
| project-capability-revelation | project-capsule-proof-views |  | capability-revelation-record.v1 | direct-record | capability-revelation-record.v1 | direct-record |
| project-capability-revelation | project-capsule-specification-views |  | capability-revelation-record.v1 | direct-record | capability-revelation-record.v1 | direct-record |
| project-capability-revelation | project-capsule-summary-view |  | capability-revelation-record.v1 | direct-record | capability-revelation-record.v1 | direct-record |
| project-capability-revelation | project-capsule-verification-view |  | capability-revelation-record.v1 | direct-record | capability-revelation-record.v1 | direct-record |
| project-collection-presentation | project-collection-presentation | yes | project-collection-presentation-input.v1 | enveloped-record | collection-presentation-projection-evidence.v1 | direct-record |
| project-consumer-execution-embodiment-v2 | admit-consumer-execution-embodiment-projection-context |  | consumer-execution-embodiment-projection-context.v1 | direct-record | admitted-consumer-execution-embodiment-projection-context.v1 | direct-record |
| project-consumer-execution-embodiment-v2 | derive-consumer-execution-embodiment-projection-graph |  | admitted-consumer-execution-embodiment-projection-context.v1 | direct-record | consumer-execution-embodiment-projection-graph.v1 | direct-record |
| project-consumer-execution-embodiment-v2 | observe-consumer-execution-embodiment-fixtures |  | projected-consumer-execution-embodiment-bundle.v1 | direct-record | projected-consumer-execution-embodiment-candidate.v1 | direct-record |
| project-consumer-execution-embodiment-v2 | project-consumer-execution-embodiment-v2 | yes | consumer-execution-embodiment-projection-context.v1 | direct-record | projected-consumer-execution-embodiment-candidate.v1 | direct-record |
| project-consumer-execution-embodiment-v2 | render-consumer-execution-embodiments |  | consumer-execution-embodiment-projection-graph.v1 | direct-record | projected-consumer-execution-embodiment-bundle.v1 | direct-record |
| project-document-presentation | project-document-presentation | yes | project-document-presentation-input.v1 | enveloped-record | document-presentation-projection-evidence.v1 | direct-record |
| project-feedback-presentation | project-feedback-presentation | yes | project-feedback-presentation-input.v1 | enveloped-record | feedback-presentation-projection-evidence.v1 | direct-record |
| project-flow-composition | project-flow-composition | yes | project-flow-composition-input.v1 | enveloped-record | flow-composition-projection-evidence.v1 | direct-record |
| project-focus-navigation | project-focus-navigation | yes | project-focus-navigation-input.v1 | enveloped-record | focus-navigation-projection-evidence.v1 | direct-record |
| project-governed-http-request-body | project-governed-http-request-body | yes | project-governed-http-request-body-input.v1 | enveloped-record | governed-http-request-body-projection-evidence.v1 | enveloped-record |
| project-input-binding | project-input-binding | yes | project-input-binding-input.v1 | enveloped-record | semantic-input-binding-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | normalize-gemini-blocking-finish-testimony |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | normalize-gemini-success-testimony |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | normalize-model-response-format |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | normalize-provider-http-failure-testimony |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | normalize-provider-transport-testimony |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | project-gemini-endpoint-and-credential-rule |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | project-gemini-structured-request |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | project-gemini-text-request |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | project-model-provider-protocol | yes | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-route.v1 | direct-record |
| project-model-provider-protocol | project-openai-structured-request |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | project-openai-text-request |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | prove-deterministic-protocol-projection |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | prove-no-http-effect-in-protocol-projection |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | reject-unsupported-adapter-authority |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | reject-unsupported-interaction-mode |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | reject-unsupported-provider-protocol |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-model-provider-protocol | reject-unsupported-schema-vocabulary |  | project-model-provider-protocol-input.v1 | composed-root | model-provider-protocol-projection-evidence.v1 | enveloped-record |
| project-openapi-description | project-openapi-description | yes | project-openapi-description-input.v1 | enveloped-record | openapi-projection-evidence.v1 | direct-record |
| project-operation-binding | project-operation-binding | yes | project-operation-binding-input.v1 | enveloped-record | declared-operation-binding-projection-evidence.v1 | direct-record |
| project-portfolio-alignment-view | admit-portfolio-view-inputs |  | portfolio-alignment-view-record.v1 | direct-record | portfolio-alignment-view-record.v1 | direct-record |
| project-portfolio-alignment-view | bind-portfolio-view-receipt |  | portfolio-alignment-view-record.v1 | direct-record | portfolio-alignment-view-record.v1 | direct-record |
| project-portfolio-alignment-view | project-portfolio-alignment-view | yes | portfolio-alignment-view-record.v1 | direct-record | portfolio-alignment-view-record.v1 | direct-record |
| project-portfolio-alignment-view | project-portfolio-view-facets |  | portfolio-alignment-view-record.v1 | direct-record | portfolio-alignment-view-record.v1 | direct-record |
| project-presentation-hosting | project-presentation-hosting | yes | project-presentation-hosting-input.v1 | enveloped-record | presentation-hosting-projection-evidence.v1 | direct-record |
| project-presentation-lifecycle | project-presentation-lifecycle | yes | project-presentation-lifecycle-input.v1 | enveloped-record | presentation-lifecycle-projection-evidence.v1 | direct-record |
| project-presentation-state-binding | project-presentation-state-binding | yes | project-presentation-state-binding-input.v1 | enveloped-record | presentation-state-binding-projection-evidence.v1 | enveloped-record |
| project-presentation-token-binding | project-presentation-token-binding | yes | project-presentation-token-binding-input.v1 | enveloped-record | presentation-token-binding-projection-evidence.v1 | direct-record |
| project-semantic-element-realization | project-semantic-element-realization | yes | project-semantic-element-realization-input.v1 | enveloped-record | semantic-element-realization-projection-evidence.v1 | direct-record |
| project-semantic-presentation-layer | project-semantic-presentation-layer | yes | project-semantic-presentation-layer-input.v1 | enveloped-record | semantic-presentation-layer-projection-evidence.v1 | direct-record |
| project-sidefx-semantic-identity-index | project-sidefx-semantic-identity-index | yes | sidefx-semantic-identity-index-projection-request.v1 | direct-record | sidefx-semantic-identity-index.v1 | direct-record |
| project-sidefx-semantic-lexical-index | project-sidefx-semantic-lexical-index | yes | sidefx-semantic-lexical-index-projection-request.v1 | direct-record | sidefx-semantic-lexical-index.v1 | direct-record |
| project-source-selection-presentation | project-source-selection-presentation | yes | project-source-selection-presentation-input.v1 | enveloped-record | source-selection-presentation-projection-evidence.v1 | direct-record |
| project-strategic-evidence-review | bind-strategic-review-receipt |  | strategic-review-record.v1 | direct-record | strategic-review-record.v1 | direct-record |
| project-strategic-evidence-review | project-strategic-evidence-review | yes | strategic-review-record.v1 | direct-record | strategic-review-record.v1 | direct-record |
| project-strategic-evidence-review | verify-evidence-plane-binding |  | strategic-review-record.v1 | direct-record | strategic-review-record.v1 | direct-record |
| project-strategic-evidence-review | verify-review-identity-binding |  | strategic-review-record.v1 | direct-record | strategic-review-record.v1 | direct-record |
| project-strategic-evidence-review | verify-review-preservation-law |  | strategic-review-record.v1 | direct-record | strategic-review-record.v1 | direct-record |
| project-structured-data-presentation | project-structured-data-presentation | yes | project-structured-data-presentation-input.v1 | enveloped-record | structured-data-presentation-projection-evidence.v1 | direct-record |
| project-validation-presentation | project-validation-presentation | yes | project-validation-presentation-input.v1 | enveloped-record | validation-presentation-projection-evidence.v1 | direct-record |
| promote-proven-implementation | promote-proven-implementation | yes | promote-proven-implementation-input.v1 | enveloped-record | promotion-evidence.v1 | direct-record |
| prove-canonical-blueprint-geometry | bind-counted-monotonic-summary |  | canonical-blueprint-geometry-proof-request.v1 | enveloped-record | canonical-blueprint-geometry-proof.v1 | enveloped-record |
| prove-canonical-blueprint-geometry | prove-branch-and-fan-out-distinction |  | canonical-blueprint-geometry-proof-request.v1 | enveloped-record | blueprint-geometry-disposition.v1 | enveloped-record |
| prove-canonical-blueprint-geometry | prove-canonical-blueprint-geometry | yes | canonical-blueprint-geometry-proof-request.v1 | enveloped-record | canonical-blueprint-geometry-proof.v1 | enveloped-record |
| prove-canonical-blueprint-geometry | prove-monotonic-advancement |  | canonical-blueprint-geometry-proof-request.v1 | enveloped-record | blueprint-geometry-disposition.v1 | enveloped-record |
| prove-canonical-blueprint-geometry | prove-orthogonal-edge-semantics |  | canonical-blueprint-geometry-proof-request.v1 | enveloped-record | blueprint-geometry-disposition.v1 | enveloped-record |
| prove-canonical-blueprint-geometry | prove-typed-node-coverage |  | canonical-blueprint-geometry-proof-request.v1 | enveloped-record | blueprint-geometry-disposition.v1 | enveloped-record |
| prove-cross-apply-ui-parity | prove-cross-apply-ui-parity | yes | prove-cross-apply-ui-parity-input.v1 | enveloped-record | consumer-ui-parity-evidence.v1 | direct-record |
| prove-cross-target-projection-equivalence | prove-cross-target-projection-equivalence | yes | prove-cross-target-projection-equivalence-input.v1 | enveloped-record | cross-target-projection-equivalence-evidence.v1 | direct-record |
| prove-domain-isolation | prove-domain-isolation | yes | prove-domain-isolation-input.v1 | enveloped-record | domain-isolation-evidence.v1 | direct-record |
| prove-experience-closure | prove-experience-closure | yes | prove-experience-closure-input.v1 | enveloped-record | experience-closure-evidence.v1 | enveloped-record |
| prove-mechanical-sterility | prove-mechanical-sterility | yes | prove-mechanical-sterility-input.v1 | enveloped-record | mechanical-sterility-evidence.v1 | enveloped-record |
| prove-monotonic-execution-circuit | bind-monotonic-circuit-receipt |  | execution-circuit-monotonicity-record.v1 | direct-record | execution-circuit-monotonicity-record.v1 | direct-record |
| prove-monotonic-execution-circuit | compose-child-dispositions-upward |  | execution-circuit-monotonicity-record.v1 | direct-record | execution-circuit-monotonicity-record.v1 | direct-record |
| prove-monotonic-execution-circuit | evaluate-execution-level-monotonicity | yes | execution-circuit-monotonicity-record.v1 | direct-record | execution-circuit-monotonicity-record.v1 | direct-record |
| prove-monotonic-execution-circuit | prove-decomposition-boundary-closure |  | execution-circuit-monotonicity-record.v1 | direct-record | execution-circuit-monotonicity-record.v1 | direct-record |
| prove-monotonic-execution-circuit | report-semantic-monotonicity-not-declared |  | execution-circuit-monotonicity-record.v1 | direct-record | execution-circuit-monotonicity-record.v1 | direct-record |
| prove-projected-execution-behavior | prove-projected-execution-behavior | yes | prove-projected-execution-behavior-input.v1 | enveloped-record | projected-execution-proof-evidence.v1 | direct-record |
| prove-projected-sterility-before-publication | prove-projected-sterility-before-publication | yes | prove-projected-sterility-before-publication-input.v1 | enveloped-record | prepublication-sterility-evidence.v1 | direct-record |
| prove-query-closure | prove-query-closure | yes | prove-query-closure-input.v1 | enveloped-record | query-closure-evidence.v1 | direct-record |
| provision-capability-artifacts | admit-provisioning-batch-request |  | provisioning-carrier.v1 | direct-record | provisioning-carrier.v1 | direct-record |
| provision-capability-artifacts | bind-provisioning-manifest-entries |  | provisioning-carrier.v1 | direct-record | provisioning-carrier.v1 | direct-record |
| provision-capability-artifacts | classify-artifact-by-declared-extension |  | provisioning-carrier.v1 | direct-record | provisioning-carrier.v1 | direct-record |
| provision-capability-artifacts | close-provisioning-coverage |  | provisioning-carrier.v1 | direct-record | provisioning-carrier.v1 | direct-record |
| provision-capability-artifacts | provision-capability-artifacts | yes | capability-provisioning-request.v1 | composed-root | capability-provisioning-decision.v1 | direct-record |
| provision-capability-artifacts | resolve-artifact-provisioning-disposition |  | provisioning-carrier.v1 | direct-record | provisioning-carrier.v1 | direct-record |
| provision-capability-artifacts | screen-observed-artifacts-against-policy |  | provisioning-carrier.v1 | direct-record | provisioning-carrier.v1 | direct-record |
| publish-bounded-tooling-migration-evidence | materialize-bounded-tooling-migration-evidence |  | bounded-tooling-migration-evidence-publication-context.v1 | composed-root | published-bounded-tooling-migration-evidence.v1 | composed-root |
| publish-bounded-tooling-migration-evidence | publish-bounded-tooling-migration-evidence | yes | bounded-tooling-migration-evidence-publication-request.v1 | composed-root | bounded-tooling-migration-evidence-publication-request.v1 | composed-root |
| publish-bounded-tooling-migration-evidence | resolve-bounded-tooling-migration-evidence-publication-scope |  | bounded-tooling-migration-evidence-publication-request.v1 | composed-root | bounded-tooling-migration-evidence-publication-context.v1 | composed-root |
| publish-capability-change | admit-and-record-capability-change |  | capability-change-mainline-proof.v1 | enveloped-record | capability-change-publication-receipt.v1 | enveloped-record |
| publish-capability-change | publish-capability-change | yes | sealed-capability-change-set.v1 | enveloped-record | published-capability-change-set.v1 | enveloped-record |
| publish-capability-change | reprove-capability-change-on-mainline |  | capability-change-baseline-revalidation.v1 | enveloped-record | capability-change-mainline-proof.v1 | enveloped-record |
| publish-capability-change | restore-prior-capability-change-admission |  | capability-change-publication-failure.v1 | enveloped-record | held-capability-change-publication.v1 | enveloped-record |
| publish-capability-change | revalidate-capability-change-baseline |  | sealed-capability-change-set.v1 | enveloped-record | capability-change-baseline-revalidation.v1 | enveloped-record |
| publish-implementation-evidence | publish-implementation-evidence | yes | implementation-evidence-publication-input.v1 | enveloped-record | published-implementation-evidence.v1 | enveloped-record |
| publish-projected-capability | publish-projected-capability | yes | publish-projected-capability-input.v1 | enveloped-record | consumer-capability-publication-evidence.v1 | direct-record |
| publish-sidefx-evidence-receipt | bind-terminal-sidefx-publication-testimony |  | sidefx-evidence-receipt-publication-record.v1 | direct-record | sidefx-evidence-receipt-publication-record.v1 | direct-record |
| publish-sidefx-evidence-receipt | publish-sidefx-evidence-receipt | yes | sidefx-evidence-receipt-publication-record.v1 | direct-record | sidefx-evidence-receipt-publication-record.v1 | direct-record |
| publish-sidefx-evidence-receipt | reject-conflicting-sidefx-evidence-receipt-publication |  | sidefx-evidence-receipt-publication-record.v1 | direct-record | sidefx-evidence-receipt-publication-record.v1 | direct-record |
| publish-sidefx-evidence-receipt | republish-sidefx-evidence-receipt-idempotently |  | sidefx-evidence-receipt-publication-record.v1 | direct-record | sidefx-evidence-receipt-publication-record.v1 | direct-record |
| qualify-provider-candidate-completeness | classify-provider-applicability |  | provider-candidate-completeness-request.v1 | composed-root | provider-candidate-qualification-disposition.v1 | direct-record |
| qualify-provider-candidate-completeness | close-provider-candidate-coverage |  | provider-candidate-coverage-inputs.v1 | direct-record | provider-candidate-coverage-ledger.v1 | direct-record |
| qualify-provider-candidate-completeness | preserve-carrier-provider-blackout |  | carrier-provider-qualification-request.v1 | direct-record | provider-candidate-qualification-disposition.v1 | direct-record |
| qualify-provider-candidate-completeness | preserve-provider-inference-as-testimony |  | provider-candidate-evidence-set.v1 | direct-record | provider-candidate-qualification-disposition.v1 | direct-record |
| qualify-provider-candidate-completeness | qualify-provider-candidate-completeness | yes | provider-candidate-completeness-request.v1 | composed-root | provider-candidate-completeness-receipt.v1 | direct-record |
| qualify-provider-candidate-completeness | qualify-provider-mapping-and-effects |  | provider-slot-realization-request.v1 | direct-record | provider-candidate-qualification-disposition.v1 | direct-record |
| qualify-provider-candidate-completeness | qualify-provider-selection |  | provider-slot-selection-request.v1 | direct-record | provider-candidate-qualification-disposition.v1 | direct-record |
| qualify-provider-candidate-completeness | qualify-provider-slot-evidence |  | provider-slot-qualification-request.v1 | direct-record | provider-candidate-qualification-disposition.v1 | direct-record |
| qualify-provider-candidate-completeness | replay-provider-candidate-qualification |  | provider-candidate-completeness-request.v1 | composed-root | provider-candidate-qualification-disposition.v1 | direct-record |
| qualify-provider-candidate-completeness | validate-provider-candidate-generation |  | provider-candidate-completeness-request.v1 | composed-root | provider-candidate-qualification-disposition.v1 | direct-record |
| read-authorized-file | read-authorized-file | yes | authorized-file-read-request.v1 | enveloped-record | authorized-file-read-outcome.v2 | composed-root |
| read-authorized-file-through-capability | read-authorized-file-through-capability | yes | authorized-file-read-request.v1 | enveloped-record | authorized-file-read-outcome.v2 | composed-root |
| realize-admitted-capability | bind-providers-to-graph |  | capability-realization-record.v1 | composed-root | capability-realization-record.v1 | composed-root |
| realize-admitted-capability | preserve-canonical-graph-identity |  | capability-realization-record.v1 | composed-root | capability-realization-record.v1 | composed-root |
| realize-admitted-capability | prove-realization-conformant |  | capability-realization-record.v1 | composed-root | capability-realization-record.v1 | composed-root |
| realize-admitted-capability | realize-admitted-capability | yes | capability-realization-record.v1 | composed-root | capability-realization-record.v1 | composed-root |
| realize-admitted-capability | resolve-required-providers |  | capability-realization-record.v1 | composed-root | capability-realization-record.v1 | composed-root |
| realize-node-execute-bounded-process | admit-bounded-process-execution-request |  | mechanic:execute-bounded-process:input.v1 | direct-record | bounded-process-request-disposition.v1 | direct-record |
| realize-node-execute-bounded-process | bind-bounded-process-execution-testimony |  | raw-bounded-process-observation.v1 | direct-record | mechanic:execute-bounded-process:outcome.v1 | direct-record |
| realize-node-execute-bounded-process | invoke-node-child-process |  | admitted-bounded-process-request.v1 | direct-record | raw-bounded-process-observation.v1 | direct-record |
| realize-node-execute-bounded-process | realize-node-execute-bounded-process | yes | mechanic:execute-bounded-process:input.v1 | direct-record | mechanic:execute-bounded-process:outcome.v1 | direct-record |
| reconstruct-capability-workspace | bind-reconstruction-receipt |  | capability-workspace-reconstruction-record.v1 | direct-record | capability-workspace-reconstruction-record.v1 | direct-record |
| reconstruct-capability-workspace | reconstruct-capability-workspace | yes | capability-workspace-reconstruction-record.v1 | direct-record | capability-workspace-reconstruction-record.v1 | direct-record |
| reconstruct-capability-workspace | verify-entry-integrity |  | capability-workspace-reconstruction-record.v1 | direct-record | capability-workspace-reconstruction-record.v1 | direct-record |
| reconstruct-capability-workspace | verify-required-coverage |  | capability-workspace-reconstruction-record.v1 | direct-record | capability-workspace-reconstruction-record.v1 | direct-record |
| reproduce-target-execution-vector | reproduce-target-execution-vector | yes | reproduce-target-execution-vector-input.v1 | enveloped-record | execution-projection-plan-evidence.v1 | direct-record |
| reproduce-target-structural-model | reproduce-target-structural-model | yes | reproduce-structural-model-input.v1 | enveloped-record | structural-projection-plan-evidence.v1 | direct-record |
| resolve-admitted-market-facts | bind-market-fact-receipt |  | market-fact-record.v1 | direct-record | market-fact-record.v1 | direct-record |
| resolve-admitted-market-facts | resolve-admitted-market-facts | yes | market-fact-record.v1 | direct-record | market-fact-record.v1 | direct-record |
| resolve-admitted-market-facts | verify-fact-lineage |  | market-fact-record.v1 | direct-record | market-fact-record.v1 | direct-record |
| resolve-admitted-market-facts | verify-fact-provenance-and-bounds |  | market-fact-record.v1 | direct-record | market-fact-record.v1 | direct-record |
| resolve-admitted-market-facts | verify-fact-type-admission |  | market-fact-record.v1 | direct-record | market-fact-record.v1 | direct-record |
| resolve-bounded-market-interpretation | bind-market-interpretation-receipt |  | market-interpretation-record.v1 | direct-record | market-interpretation-record.v1 | direct-record |
| resolve-bounded-market-interpretation | resolve-bounded-market-interpretation | yes | market-interpretation-record.v1 | direct-record | market-interpretation-record.v1 | direct-record |
| resolve-bounded-market-interpretation | verify-bounded-statement |  | market-interpretation-record.v1 | direct-record | market-interpretation-record.v1 | direct-record |
| resolve-bounded-market-interpretation | verify-interpretation-limitations |  | market-interpretation-record.v1 | direct-record | market-interpretation-record.v1 | direct-record |
| resolve-bounded-market-interpretation | verify-pattern-binding |  | market-interpretation-record.v1 | direct-record | market-interpretation-record.v1 | direct-record |
| resolve-capability-proof-obligations | bind-fixture-candidates-without-authoring-values |  | proof-obligation-carrier.v1 | direct-record | proof-obligation-carrier.v1 | direct-record |
| resolve-capability-proof-obligations | close-proof-coverage |  | proof-obligation-carrier.v1 | direct-record | proof-obligation-carrier.v1 | direct-record |
| resolve-capability-proof-obligations | derive-effect-failure-obligations |  | proof-obligation-carrier.v1 | direct-record | proof-obligation-carrier.v1 | direct-record |
| resolve-capability-proof-obligations | derive-invalid-input-obligations |  | proof-obligation-carrier.v1 | direct-record | proof-obligation-carrier.v1 | direct-record |
| resolve-capability-proof-obligations | derive-missing-input-obligations |  | proof-obligation-carrier.v1 | direct-record | proof-obligation-carrier.v1 | direct-record |
| resolve-capability-proof-obligations | derive-observable-condition-obligations |  | proof-obligation-carrier.v1 | direct-record | proof-obligation-carrier.v1 | direct-record |
| resolve-capability-proof-obligations | derive-positive-obligation |  | proof-obligation-request.v1 | composed-root | proof-obligation-carrier.v1 | direct-record |
| resolve-capability-proof-obligations | derive-terminal-variant-obligations |  | proof-obligation-carrier.v1 | direct-record | proof-obligation-carrier.v1 | direct-record |
| resolve-capability-proof-obligations | replay-proof-obligation-resolution |  | proof-obligation-carrier.v1 | direct-record | proof-obligation-carrier.v1 | direct-record |
| resolve-capability-proof-obligations | resolve-capability-proof-obligations | yes | proof-obligation-request.v1 | composed-root | capability-proof-obligation-set.v1 | direct-record |
| resolve-capability-reinforcing-fit | admit-scenario-fit-signals |  | capability-reinforcing-fit-record.v1 | composed-root | capability-reinforcing-fit-record.v1 | composed-root |
| resolve-capability-reinforcing-fit | bind-capability-fit-snapshot |  | capability-reinforcing-fit-record.v1 | composed-root | capability-reinforcing-fit-record.v1 | composed-root |
| resolve-capability-reinforcing-fit | evaluate-capability-fit-aggregate |  | capability-reinforcing-fit-record.v1 | composed-root | capability-reinforcing-fit-record.v1 | composed-root |
| resolve-capability-reinforcing-fit | resolve-capability-reinforcing-fit | yes | capability-reinforcing-fit-record.v1 | composed-root | capability-reinforcing-fit-record.v1 | composed-root |
| resolve-estate-dependency-closure | close-execution-resolvability |  | estate-closure-carrier.v1 | direct-record | estate-closure-carrier.v1 | direct-record |
| resolve-estate-dependency-closure | detect-stale-pins |  | estate-closure-carrier.v1 | direct-record | estate-closure-carrier.v1 | direct-record |
| resolve-estate-dependency-closure | recompute-binding-digests |  | estate-closure-carrier.v1 | direct-record | estate-closure-carrier.v1 | direct-record |
| resolve-estate-dependency-closure | resolve-declared-dependencies |  | estate-closure-carrier.v1 | direct-record | estate-closure-carrier.v1 | direct-record |
| resolve-estate-dependency-closure | resolve-estate-dependency-closure | yes | estate-dependency-closure-request.v1 | composed-root | estate-dependency-closure.v1 | direct-record |
| resolve-governed-model-invocation-profile | admit-model-invocation-authority |  | governed-model-invocation-profile-request.v1 | direct-record | admitted-model-invocation-authority.v1 | direct-record |
| resolve-governed-model-invocation-profile | declare-permitted-caller-parameters |  | fixed-governed-invocation-terms.v1 | direct-record | governed-model-invocation-profile.v1 | direct-record |
| resolve-governed-model-invocation-profile | resolve-fixed-invocation-terms |  | admitted-model-invocation-authority.v1 | direct-record | fixed-governed-invocation-terms.v1 | direct-record |
| resolve-governed-model-invocation-profile | resolve-governed-model-invocation-profile | yes | governed-model-invocation-profile-request.v1 | direct-record | governed-model-invocation-profile.v1 | direct-record |
| resolve-governed-scenario-route | admit-current-route-state |  | route-state-admission-context.v1 | enveloped-record | current-route-state-snapshot.v1 | enveloped-record |
| resolve-governed-scenario-route | establish-authorized-continuation |  | continuation-evidence.v1 | enveloped-record | authorized-scenario-continuation.v1 | enveloped-record |
| resolve-governed-scenario-route | resolve-bounded-return-authority |  | route-evaluation-context.v1 | enveloped-record | bounded-return-authorization.v1 | enveloped-record |
| resolve-governed-scenario-route | resolve-convergence-readiness |  | route-evaluation-context.v1 | enveloped-record | convergence-readiness.v1 | enveloped-record |
| resolve-governed-scenario-route | resolve-declared-outgoing-routes |  | selected-outcome-variant.v1 | enveloped-record | declared-outgoing-route-set.v1 | enveloped-record |
| resolve-governed-scenario-route | resolve-fan-out-membership |  | route-evaluation-context.v1 | enveloped-record | fan-out-membership.v1 | enveloped-record |
| resolve-governed-scenario-route | resolve-governed-scenario-route | yes | scenario-route-resolution-request.v1 | enveloped-record | authorized-scenario-continuation.v1 | enveloped-record |
| resolve-governed-scenario-route | resolve-selected-outcome-variant |  | scenario-route-resolution-request.v1 | enveloped-record | selected-outcome-variant.v1 | enveloped-record |
| resolve-governed-task | resolve-governed-task | yes | UNRESOLVED | unresolved | UNRESOLVED | unresolved |
| resolve-platform-responsibilities | resolve-platform-responsibilities | yes | resolve-platform-responsibilities-input.v1 | enveloped-record | platform-responsibility-resolution-evidence.v1 | direct-record |
| resolve-product-promise-fit | admit-product-fit-inputs |  | product-promise-fit-record.v1 | composed-root | product-promise-fit-record.v1 | composed-root |
| resolve-product-promise-fit | bind-product-fit-snapshot |  | product-promise-fit-record.v1 | composed-root | product-promise-fit-record.v1 | composed-root |
| resolve-product-promise-fit | evaluate-product-fit-aggregate |  | product-promise-fit-record.v1 | composed-root | product-promise-fit-record.v1 | composed-root |
| resolve-product-promise-fit | resolve-product-promise-fit | yes | product-promise-fit-record.v1 | composed-root | product-promise-fit-record.v1 | composed-root |
| resolve-registered-realization-plan | resolve-registered-realization-plan | yes | registry-backed-realization-plan-request.v1 | enveloped-record | registry-backed-realization-plan-evidence.v1 | enveloped-record |
| resolve-scenario-reinforcing-fit | admit-outcome-receipt |  | scenario-reinforcing-fit-record.v1 | composed-root | scenario-reinforcing-fit-record.v1 | composed-root |
| resolve-scenario-reinforcing-fit | bind-fit-signal-receipt |  | scenario-reinforcing-fit-record.v1 | composed-root | scenario-reinforcing-fit-record.v1 | composed-root |
| resolve-scenario-reinforcing-fit | evaluate-declared-fit-relation |  | scenario-reinforcing-fit-record.v1 | composed-root | scenario-reinforcing-fit-record.v1 | composed-root |
| resolve-scenario-reinforcing-fit | project-domain-fit-statement |  | scenario-reinforcing-fit-record.v1 | composed-root | scenario-reinforcing-fit-record.v1 | composed-root |
| resolve-scenario-reinforcing-fit | resolve-scenario-reinforcing-fit | yes | scenario-reinforcing-fit-record.v1 | composed-root | scenario-reinforcing-fit-record.v1 | composed-root |
| resolve-scenario-solution-authoring-profile | admit-solution-vocabulary-sources |  | scenario-solution-authoring-profile-request.v1 | direct-record | admitted-solution-vocabulary-sources.v1 | direct-record |
| resolve-scenario-solution-authoring-profile | bind-scenario-solution-authoring-profile |  | required-invocation-obligations.v1 | direct-record | scenario-solution-authoring-profile.v1 | direct-record |
| resolve-scenario-solution-authoring-profile | resolve-permitted-mechanic-authoring-forms |  | admitted-solution-vocabulary-sources.v1 | direct-record | permitted-mechanic-authoring-forms.v1 | direct-record |
| resolve-scenario-solution-authoring-profile | resolve-required-invocation-obligations |  | permitted-mechanic-authoring-forms.v1 | direct-record | required-invocation-obligations.v1 | direct-record |
| resolve-scenario-solution-authoring-profile | resolve-scenario-solution-authoring-profile | yes | scenario-solution-authoring-profile-request.v1 | direct-record | scenario-solution-authoring-profile.v1 | direct-record |
| resolve-sidefx-capability-precedents | resolve-sidefx-capability-precedents | yes | sidefx-capability-precedent-request.v1 | direct-record | sidefx-semantic-precedent-set.v1 | direct-record |
| resolve-sidefx-current-corpus-pointer | refuse-undeclared-pointer-scope |  | sidefx-current-pointer-resolution-record.v1 | direct-record | sidefx-current-pointer-resolution-record.v1 | direct-record |
| resolve-sidefx-current-corpus-pointer | report-absent-pointer-scope-not-observable |  | sidefx-current-pointer-resolution-record.v1 | direct-record | sidefx-current-pointer-resolution-record.v1 | direct-record |
| resolve-sidefx-current-corpus-pointer | resolve-sidefx-current-corpus-pointer | yes | sidefx-current-pointer-resolution-record.v1 | direct-record | sidefx-current-pointer-resolution-record.v1 | direct-record |
| resolve-sidefx-eligible-providers | resolve-sidefx-eligible-providers | yes | sidefx-provider-resolution-request.v1 | direct-record | sidefx-semantic-provider-resolution.v1 | direct-record |
| resolve-sidefx-semantic-knowledge-request | resolve-sidefx-semantic-knowledge-request | yes | sidefx-semantic-knowledge-request.v1 | composed-root | sidefx-semantic-knowledge-outcome.v1 | direct-record |
| resolve-sidefx-semantic-pattern-candidates | resolve-sidefx-semantic-pattern-candidates | yes | sidefx-pattern-candidate-request.v1 | direct-record | sidefx-semantic-pattern-candidate-set.v1 | direct-record |
| resolve-strategic-interpretation | admit-strategic-interpretation-inputs |  | strategic-interpretation-record.v1 | direct-record | strategic-interpretation-record.v1 | direct-record |
| resolve-strategic-interpretation | bind-strategic-interpretation-receipt |  | strategic-interpretation-record.v1 | direct-record | strategic-interpretation-record.v1 | direct-record |
| resolve-strategic-interpretation | evaluate-bounded-strategic-evidence |  | strategic-interpretation-record.v1 | direct-record | strategic-interpretation-record.v1 | direct-record |
| resolve-strategic-interpretation | resolve-strategic-interpretation | yes | strategic-interpretation-record.v1 | direct-record | strategic-interpretation-record.v1 | direct-record |
| resolve-strategic-market-fit | bind-strategic-market-fit-receipt |  | strategic-market-fit-record.v1 | composed-root | strategic-market-fit-record.v1 | composed-root |
| resolve-strategic-market-fit | resolve-strategic-market-fit | yes | strategic-market-fit-record.v1 | composed-root | strategic-market-fit-record.v1 | composed-root |
| resolve-strategic-market-fit | verify-fit-counterevidence-and-duplication |  | strategic-market-fit-record.v1 | composed-root | strategic-market-fit-record.v1 | composed-root |
| resolve-strategic-market-fit | verify-fit-coverage-and-window |  | strategic-market-fit-record.v1 | composed-root | strategic-market-fit-record.v1 | composed-root |
| resolve-strategic-market-fit | verify-fit-identity-binding |  | strategic-market-fit-record.v1 | composed-root | strategic-market-fit-record.v1 | composed-root |
| resolve-strategic-market-signals | bind-market-signal-receipt |  | market-signal-record.v1 | direct-record | market-signal-record.v1 | direct-record |
| resolve-strategic-market-signals | resolve-strategic-market-signals | yes | market-signal-record.v1 | direct-record | market-signal-record.v1 | direct-record |
| resolve-strategic-market-signals | verify-independence-and-window |  | market-signal-record.v1 | direct-record | market-signal-record.v1 | direct-record |
| resolve-strategic-market-signals | verify-signal-fact-bindings |  | market-signal-record.v1 | direct-record | market-signal-record.v1 | direct-record |
| resolve-strategic-market-signals | verify-signal-family-admission |  | market-signal-record.v1 | direct-record | market-signal-record.v1 | direct-record |
| retrieve-sidefx-semantic-candidates | retrieve-sidefx-semantic-candidates | yes | sidefx-semantic-candidate-retrieval-request.v1 | composed-root | sidefx-semantic-candidate-set.v1 | direct-record |
| reveal-and-refine-capability-meaning | admit-cognitive-video-projection |  | video-admission-evidence.v1 | enveloped-record | admitted-cognitive-video-projection.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | assemble-cognitive-video-projection |  | complete-video-production-set.v1 | enveloped-record | candidate-cognitive-video.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | evaluate-audience-projection-fidelity |  | audience-projection-evaluation-context.v1 | enveloped-record | audience-projection-fidelity-evaluation.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | evaluate-video-semantic-fidelity |  | candidate-cognitive-video.v1 | enveloped-record | video-semantic-fidelity-evaluation.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | evaluate-video-technical-quality |  | candidate-cognitive-video.v1 | enveloped-record | video-technical-quality-evaluation.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | generate-creative-video-assets |  | presentation-scene-graph.v1 | enveloped-record | creative-video-asset-set.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | generate-video-narration |  | presentation-scene-graph.v1 | enveloped-record | video-narration-asset.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | project-presentation-scene-graph |  | cognitive-video-projection-context.v1 | enveloped-record | presentation-scene-graph.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | render-authoritative-video-visuals |  | presentation-scene-graph.v1 | enveloped-record | authoritative-visual-asset-set.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | resolve-capability-meaning-review |  | admitted-cognitive-video-projection.v1 | enveloped-record | capability-meaning-review.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | resolve-cognitive-video-projection-context |  | cognitive-video-revelation-request.v1 | enveloped-record | cognitive-video-projection-context.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | resolve-semantic-clarification |  | capability-review-clarification.v1 | enveloped-record | capability-mutation-intent.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | reveal-admitted-clarification |  | published-capability-clarification.v1 | enveloped-record | bounded-return-revelation-context.v1 | enveloped-record |
| reveal-and-refine-capability-meaning | reveal-capability-for-human-cognition | yes | cognitive-video-revelation-request.v1 | enveloped-record | capability-meaning-review-experience.v1 | enveloped-record |
| route-aware-consumer-execution-surface | admit-route-governed-execution-context |  | route-governed-execution-request.v1 | enveloped-record | admitted-route-execution-context.v1 | enveloped-record |
| route-aware-consumer-execution-surface | establish-route-governed-execution-result |  | selected-invocation-set.v1 | enveloped-record | route-governed-execution-result.v1 | enveloped-record |
| route-aware-consumer-execution-surface | invoke-selected-scenario-set |  | selected-invocation-set.v1 | enveloped-record | selected-invocation-results.v1 | enveloped-record |
| route-aware-consumer-execution-surface | resolve-next-route-state |  | selected-invocation-results.v1 | enveloped-record | admitted-route-execution-context.v1 | enveloped-record |
| route-aware-consumer-execution-surface | resolve-selected-invocation-set |  | admitted-route-execution-context.v1 | enveloped-record | selected-invocation-set.v1 | enveloped-record |
| route-aware-consumer-execution-surface | route-aware-consumer-execution-surface | yes | route-governed-execution-request.v1 | enveloped-record | route-governed-execution-result.v1 | enveloped-record |
| say-hello-world | say-hello-world | yes | hello-world-request.v1 | enveloped-record | hello-world-greeting.v1 | enveloped-record |
| seal-capability-change | collapse-sealed-capability-change |  | capability-change-proof.v1 | enveloped-record | sealed-capability-change-candidate.v1 | enveloped-record |
| seal-capability-change | hold-unsealable-capability-change |  | capability-change-sealing-findings.v1 | enveloped-record | held-capability-change-seal.v1 | enveloped-record |
| seal-capability-change | inspect-capability-change-delta |  | capability-change-set.v1 | enveloped-record | capability-change-delta.v1 | enveloped-record |
| seal-capability-change | prove-capability-change-closure |  | capability-change-delta.v1 | enveloped-record | capability-change-proof.v1 | enveloped-record |
| seal-capability-change | seal-capability-change | yes | capability-change-set.v1 | enveloped-record | sealed-capability-change-set.v1 | enveloped-record |
| shape-governed-file-system-batch | admit-governed-file-system-shape-request |  | governed-file-system-shape-request.v1 | enveloped-record | governed-file-system-shape-admission.v1 | enveloped-record |
| shape-governed-file-system-batch | execute-authorized-file-system-shape-plan |  | authorized-file-system-shape-plan.v1 | direct-record | file-system-shape-effect-testimony.v1 | direct-record |
| shape-governed-file-system-batch | issue-governed-file-system-shape-receipt |  | verified-file-system-shape-context.v1 | direct-record | governed-file-system-shape-result.v1 | direct-record |
| shape-governed-file-system-batch | observe-file-system-mapping-facts |  | bounded-file-system-mapping-observation-request.v1 | enveloped-record | file-system-mapping-fact-testimony.v1 | enveloped-record |
| shape-governed-file-system-batch | reject-non-admissible-file-system-shape |  | rejected-file-system-shape-context.v1 | direct-record | governed-file-system-shape-result.v1 | direct-record |
| shape-governed-file-system-batch | resolve-bounded-file-system-mapping-paths |  | admitted-file-system-shape-context.v1 | enveloped-record | bounded-file-system-mapping-paths.v1 | enveloped-record |
| shape-governed-file-system-batch | resolve-complete-file-system-shape-plan |  | file-system-shape-resolution-context.v1 | enveloped-record | resolved-file-system-shape-plan.v1 | enveloped-record |
| shape-governed-file-system-batch | retain-incomplete-file-system-shape-effect |  | incomplete-file-system-shape-effect-context.v1 | direct-record | governed-file-system-shape-result.v1 | direct-record |
| shape-governed-file-system-batch | shape-governed-file-system-batch | yes | governed-file-system-shape-request.v1 | enveloped-record | governed-file-system-shape-request.v1 | enveloped-record |
| shape-governed-file-system-batch | verify-file-system-shape-effect |  | file-system-shape-verification-context.v1 | direct-record | verified-file-system-shape-disposition.v1 | direct-record |
| speech-provider | speech-provider-exchange | yes | speech-generation-invocation.v2 | enveloped-record | speech-provider-exchange-response.v2 | enveloped-record |
| stage-projected-candidate | stage-projected-candidate | yes | stage-projected-candidate-input.v1 | enveloped-record | projected-candidate-staging-evidence.v1 | enveloped-record |
| trace-sidefx-scenario-lineage | trace-sidefx-scenario-lineage | yes | sidefx-scenario-lineage-request.v1 | direct-record | sidefx-semantic-scenario-lineage.v1 | direct-record |
| transact-governed-tooling-responsibility-binding | complete-governed-tooling-binding-transaction |  | governed-tooling-binding-gate-observation.v1 | composed-root | governed-tooling-binding-transaction-evidence.v1 | composed-root |
| transact-governed-tooling-responsibility-binding | observe-governed-tooling-binding-full-gate |  | staged-governed-tooling-binding-observation.v1 | composed-root | governed-tooling-binding-gate-observation.v1 | composed-root |
| transact-governed-tooling-responsibility-binding | resolve-governed-tooling-binding-transaction-scope |  | governed-tooling-binding-transaction-request.v1 | composed-root | bounded-governed-tooling-binding-transaction-context.v1 | composed-root |
| transact-governed-tooling-responsibility-binding | stage-governed-tooling-responsibility-binding |  | bounded-governed-tooling-binding-transaction-context.v1 | composed-root | staged-governed-tooling-binding-observation.v1 | composed-root |
| transact-governed-tooling-responsibility-binding | transact-governed-tooling-responsibility-binding | yes | governed-tooling-binding-transaction-request.v1 | composed-root | governed-tooling-binding-transaction-request.v1 | composed-root |
| validate-semantic-carrier | return-carrier-rejection |  | carrier-validation-result.v1 | composed-root | carrier-conformance.v1 | composed-root |
| validate-semantic-carrier | return-conformant-carrier |  | carrier-validation-result.v1 | composed-root | carrier-conformance.v1 | composed-root |
| validate-semantic-carrier | validate-carrier-source | yes | semantic-carrier-source.v1 | string | carrier-validation-result.v1 | composed-root |
| verify-admitted-capability-lifecycle | verify-admitted-capability-lifecycle | yes | capability-lifecycle-proof-record.v1 | composed-root | capability-lifecycle-proof-record.v1 | composed-root |
| verify-admitted-capability-lifecycle | verify-capability-identity-preservation |  | capability-lifecycle-proof-record.v1 | composed-root | capability-lifecycle-proof-record.v1 | composed-root |
| verify-admitted-capability-lifecycle | verify-capsule-round-trip |  | capability-lifecycle-proof-record.v1 | composed-root | capability-lifecycle-proof-record.v1 | composed-root |
| verify-admitted-capability-lifecycle | verify-execution-preservation |  | capability-lifecycle-proof-record.v1 | composed-root | capability-lifecycle-proof-record.v1 | composed-root |
| verify-admitted-capability-lifecycle | verify-monotonicity-proof-binding |  | capability-lifecycle-proof-record.v1 | composed-root | capability-lifecycle-proof-record.v1 | composed-root |
| verify-admitted-capability-lifecycle | verify-scenario-outcome-proof-binding |  | capability-lifecycle-proof-record.v1 | composed-root | capability-lifecycle-proof-record.v1 | composed-root |
| verify-capability-authoring-lineage | compare-capability-authoring-lineage-evidence |  | observed-capability-authoring-lineage-evidence.v1 | composed-root | capability-authoring-lineage-evidence.v1 | composed-root |
| verify-capability-authoring-lineage | observe-capability-authoring-lineage-evidence |  | bounded-capability-authoring-lineage-context.v1 | composed-root | observed-capability-authoring-lineage-evidence.v1 | composed-root |
| verify-capability-authoring-lineage | resolve-capability-authoring-lineage-scope |  | capability-authoring-lineage-verification-request.v1 | composed-root | bounded-capability-authoring-lineage-context.v1 | composed-root |
| verify-capability-authoring-lineage | verify-capability-authoring-lineage | yes | capability-authoring-lineage-verification-request.v1 | composed-root | capability-authoring-lineage-verification-request.v1 | composed-root |
| verify-capability-scenario-outcomes | aggregate-scenario-testimony |  | capability-scenario-verification-record.v1 | direct-record | capability-scenario-verification-record.v1 | direct-record |
| verify-capability-scenario-outcomes | prove-integrated-circuit-conformance |  | capability-scenario-verification-record.v1 | direct-record | capability-scenario-verification-record.v1 | direct-record |
| verify-capability-scenario-outcomes | resolve-scenario-proof-bindings |  | capability-scenario-verification-record.v1 | direct-record | capability-scenario-verification-record.v1 | direct-record |
| verify-capability-scenario-outcomes | verify-branch-and-recurrence-coverage |  | capability-scenario-verification-record.v1 | direct-record | capability-scenario-verification-record.v1 | direct-record |
| verify-capability-scenario-outcomes | verify-capability-scenario-outcomes | yes | capability-scenario-verification-record.v1 | direct-record | capability-scenario-verification-record.v1 | direct-record |
| verify-governed-model-invocation-parity | admit-declared-model-invocations |  | governed-model-invocation-parity-request.v1 | direct-record | admitted-declared-model-invocations.v1 | direct-record |
| verify-governed-model-invocation-parity | compare-governed-invocation-terms |  | admitted-declared-model-invocations.v1 | direct-record | compared-governed-invocation-terms.v1 | direct-record |
| verify-governed-model-invocation-parity | resolve-invocation-parity-disposition |  | compared-governed-invocation-terms.v1 | direct-record | governed-model-invocation-parity-evidence.v1 | direct-record |
| verify-governed-model-invocation-parity | verify-governed-model-invocation-parity | yes | governed-model-invocation-parity-request.v1 | direct-record | governed-model-invocation-parity-evidence.v1 | direct-record |
| verify-governed-placement | verify-governed-placement | yes | governed-placement-input.v1 | enveloped-record | governed-placement-evidence.v1 | direct-record |
| verify-model-connection-conformance | detect-model-attempt-and-receipt-divergence |  | verify-model-connection-conformance-input.v1 | composed-root | model-connection-conformance-evidence.v1 | enveloped-record |
| verify-model-connection-conformance | detect-model-connection-host-divergence |  | verify-model-connection-conformance-input.v1 | composed-root | model-connection-conformance-evidence.v1 | enveloped-record |
| verify-model-connection-conformance | detect-model-connection-secret-leakage |  | verify-model-connection-conformance-input.v1 | composed-root | model-connection-conformance-evidence.v1 | enveloped-record |
| verify-model-connection-conformance | detect-model-protocol-request-projection-divergence |  | verify-model-connection-conformance-input.v1 | composed-root | model-connection-conformance-evidence.v1 | enveloped-record |
| verify-model-connection-conformance | detect-model-provider-testimony-normalization-divergence |  | verify-model-connection-conformance-input.v1 | composed-root | model-connection-conformance-evidence.v1 | enveloped-record |
| verify-model-connection-conformance | reject-incomplete-model-provider-conformance-coverage |  | verify-model-connection-conformance-input.v1 | composed-root | model-connection-conformance-evidence.v1 | enveloped-record |
| verify-model-connection-conformance | reject-nondeterministic-or-live-conformance-fixture |  | verify-model-connection-conformance-input.v1 | composed-root | model-connection-conformance-evidence.v1 | enveloped-record |
| verify-model-connection-conformance | reject-unclosed-model-connection-runtime |  | verify-model-connection-conformance-input.v1 | composed-root | model-connection-conformance-evidence.v1 | enveloped-record |
| verify-model-connection-conformance | verify-model-connection-conformance | yes | verify-model-connection-conformance-input.v1 | composed-root | model-connection-conformance-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | detect-cross-role-context-or-testimony-leakage |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | detect-missing-or-extra-model-role-stage-evidence |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | detect-model-role-budget-or-approval-violation |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | detect-model-role-dependency-order-violation |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | detect-model-role-provider-attribution-drift |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | detect-model-role-request-context-or-contract-drift |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | detect-model-role-separation-violation |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | detect-unauthorized-model-role-provider-switch |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | prove-model-role-testimony-has-no-gate-authority |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | replay-model-role-conveyor-closure-deterministically |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | verify-model-role-conveyor-closure | yes | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-model-role-conveyor-closure | verify-model-role-conveyor-terminal-experience |  | verify-model-role-conveyor-closure-input.v1 | composed-root | model-role-conveyor-closure-evidence.v1 | enveloped-record |
| verify-realization-lifecycle-contracts | verify-realization-lifecycle-contracts | yes | realization-lifecycle-fixture.v1 | enveloped-record | realization-lifecycle-contract-evidence.v1 | direct-record |
| verify-reinforcing-fit-language | admit-fit-signal-evidence |  | reinforcing-fit-language-record.v1 | composed-root | reinforcing-fit-language-record.v1 | composed-root |
| verify-reinforcing-fit-language | bind-language-conformance-receipt |  | reinforcing-fit-language-record.v1 | composed-root | reinforcing-fit-language-record.v1 | composed-root |
| verify-reinforcing-fit-language | evaluate-altitude-vocabulary-binding |  | reinforcing-fit-language-record.v1 | composed-root | reinforcing-fit-language-record.v1 | composed-root |
| verify-reinforcing-fit-language | scan-forbidden-terminology |  | reinforcing-fit-language-record.v1 | composed-root | reinforcing-fit-language-record.v1 | composed-root |
| verify-reinforcing-fit-language | verify-reinforcing-fit-language | yes | reinforcing-fit-language-record.v1 | composed-root | reinforcing-fit-language-record.v1 | composed-root |
| verify-sidefx-durable-store-admission | admit-declared-store-law-document |  | sidefx-durable-store-admission-receipt.v1 | composed-root | sidefx-durable-store-admission-receipt.v1 | composed-root |
| verify-sidefx-durable-store-admission | agree-across-admitted-store-documents |  | sidefx-durable-store-admission-receipt.v1 | composed-root | sidefx-durable-store-admission-receipt.v1 | composed-root |
| verify-sidefx-durable-store-admission | refuse-adversarial-store-contract-case |  | sidefx-durable-store-admission-receipt.v1 | composed-root | sidefx-durable-store-admission-receipt.v1 | composed-root |
| verify-sidefx-durable-store-admission | report-absent-store-document-not-observable |  | sidefx-durable-store-admission-receipt.v1 | composed-root | sidefx-durable-store-admission-receipt.v1 | composed-root |
| verify-sidefx-durable-store-admission | verify-sidefx-durable-store-admission | yes | sidefx-durable-store-admission-request.v1 | direct-record | sidefx-durable-store-admission-receipt.v1 | composed-root |
| verify-sidefx-evidence-ledger-integrity | report-ledger-generation-gap-without-inferring-failure |  | sidefx-ledger-integrity-verification-record.v1 | direct-record | sidefx-ledger-integrity-verification-record.v1 | direct-record |
| verify-sidefx-evidence-ledger-integrity | traverse-sidefx-receipt-chain-by-digest |  | sidefx-ledger-integrity-verification-record.v1 | direct-record | sidefx-ledger-integrity-verification-record.v1 | direct-record |
| verify-sidefx-evidence-ledger-integrity | verify-sidefx-evidence-ledger-integrity | yes | sidefx-ledger-integrity-verification-record.v1 | direct-record | sidefx-ledger-integrity-verification-record.v1 | direct-record |
| write-binary-artifact | observe-binary-artifact-write-result |  | binary-artifact-write-observation.v1 | composed-root | binary-artifact-write-result.v1 | composed-root |
| write-binary-artifact | validate-binary-artifact-write-request |  | binary-artifact-write-request.v1 | enveloped-record | binary-artifact-write-validation.v1 | composed-root |
| write-binary-artifact | verify-binary-artifact-readback |  | binary-artifact-readback-observation.v2 | direct-record | binary-artifact-write-outcome.v2 | direct-record |
| write-binary-artifact | write-binary-artifact | yes | binary-artifact-write-request.v1 | enveloped-record | binary-artifact-write-outcome.v2 | direct-record |
