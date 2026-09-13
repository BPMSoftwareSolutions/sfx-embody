@capability:project-capability-revelation
@root-scenario:project-capability-revelation
Feature: Project one capability revelation from its declared authority

  Store the capability. Project the explanation. Execute the effect.

  This capability owns the inspection projection of the revelation protocol. Its
  input is one capability revelation record: the capsule digest, capability
  identity and version, declared purpose, scenario list, contracts, providers,
  verification state, interfaces, projection targets, authority references, and
  lineage. Its outcome is the complete deterministic revelation view set:
  identity, summary, documentation, feature, scenarios, contracts, execution
  circuit, monotonicity, test results, proof, providers, interfaces, lineage,
  authority, source, and workspace. Every view is projected from the record
  without the original authoring workspace, every view binds the record digest, and
  a record missing any protocol-required declaration is held.

  What the record declares is the authority; each view and its format is a
  declared projection. A formatter never invents prose, never summarizes away a
  finding, and never becomes an authority for what a capability means. Adding a
  format, or a view, is declaring a projection — never writing a new formatter
  path. A view that would need meaning the record does not carry is held with the
  exact missing declaration rather than filled in by the formatter.

  @scenario:project-capability-revelation
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:capability-revelation-projection-requested
  @event-authority:project-capability-revelation.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  @outcome-terminal
  Scenario: Project one capability revelation from its capsule
    Given one capability capsule record with digest, identity, purpose, scenarios, contracts, providers, verification state, interfaces, projection targets, authority references, and lineage
    When the revelation is projected
    Then the revelation is REVELATION_COMPLETE or REVELATION_HELD with the exact holding finding, and a receipt binds capsule digest, capability identity, view digests, and disposition

  @scenario:project-capsule-identity-view
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:capsule-identity-view-projection-requested
  @event-authority:project-capsule-identity-view.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  @outcome-terminal
  Scenario: Project the capsule identity view
    Given one capsule digest, one capability identity, and one version
    When the identity view is projected
    Then the identity view renders capability identity, version, and capsule digest, reporting CAPSULE_IDENTITY_ABSENT otherwise

  @scenario:project-capsule-summary-view
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:capsule-summary-view-projection-requested
  @event-authority:project-capsule-summary-view.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  @outcome-terminal
  Scenario: Project the capsule summary view
    Given one declared purpose, one scenario list, and one provider list
    When the summary view is projected
    Then the summary view renders purpose, scenario count, and provider count, reporting CAPSULE_PURPOSE_ABSENT otherwise

  @scenario:project-capsule-documentation-view
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:capsule-documentation-view-projection-requested
  @event-authority:project-capsule-documentation-view.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  @outcome-terminal
  Scenario: Project the capsule documentation view
    Given one declared purpose, one scenario list, one contract list, one provider list, and one verification state
    When the documentation view is projected
    Then the documentation view renders markdown with purpose, scenarios, an execution circuit diagram, providers, and verification, without the original authoring workspace

  @scenario:project-capsule-verification-view
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:capsule-verification-view-projection-requested
  @event-authority:project-capsule-verification-view.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  @outcome-terminal
  Scenario: Project the capsule verification view
    Given one verification state with scenario coverage, monotonicity disposition, and conformance disposition
    When the verification view is projected
    Then the verification view renders coverage, monotonicity, and conformance, reporting VERIFICATION_STATE_ABSENT otherwise

  @scenario:project-capsule-specification-views
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:capsule-specification-views-projection-requested
  @event-authority:project-capsule-specification-views.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  @outcome-terminal
  Scenario: Project the feature, scenarios, contracts, and execution circuit views
    Given one declared purpose, one scenario list, one contract list, and one capability identity
    When the specification views are projected
    Then the feature view renders the declared purpose, the scenarios view renders the scenario identities, the contracts view renders input and outcome contracts, and the execution circuit view renders the scenario flow diagram

  @scenario:project-capsule-proof-views
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:capsule-proof-views-projection-requested
  @event-authority:project-capsule-proof-views.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  @outcome-terminal
  Scenario: Project the monotonicity, test results, and proof views
    Given one verification state with coverage, monotonicity, and conformance dispositions and one capsule digest
    When the proof views are projected
    Then the monotonicity view renders the monotonicity disposition, the test results view renders the scenario coverage, and the proof view binds the capsule digest to the proof state

  @scenario:project-capsule-exposure-views
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:capsule-exposure-views-projection-requested
  @event-authority:project-capsule-exposure-views.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  @outcome-terminal
  Scenario: Project the providers, interfaces, lineage, authority, source, and workspace views
    Given one provider list, one interface list, one lineage, one authority reference list, and one projection target list
    When the exposure views are projected
    Then every exposure view renders its declared list or target set from the capsule

  @scenario:project-declared-format
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:declared-revelation-format-projection-requested
  @event-authority:project-declared-revelation-format.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  Scenario: Project a view in its declared format
    Given one revelation view and its declared format
    When the view is projected
    Then the view is rendered in the declared format
    And a requested format that no projection declares returns REVELATION_FORMAT_UNDECLARED

  @scenario:hold-view-without-declared-meaning
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:revelation-view-without-declared-meaning-held
  @event-authority:hold-revelation-view-without-declared-meaning.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  Scenario: Hold a view whose declaration is absent
    Given a declared view whose backing declaration is not present in the selected generation
    When the view is projected
    Then the view is held naming the absent declaration and no narrative is invented to fill it

  @scenario:bind-revelation-receipt
  @input:capability-revelation-record
  @input-contract:capability-revelation-record.v1
  @event:revelation-receipt-binding-requested
  @event-authority:bind-revelation-receipt.v1
  @outcome:capability-revelation-record
  @outcome-contract:capability-revelation-record.v1
  @outcome-terminal
  Scenario: Bind one revelation receipt
    Given one revelation disposition over one capsule record
    When the revelation receipt is bound
    Then the capsule digest, capability identity, view digests, and disposition bind into one replayable revelation receipt
