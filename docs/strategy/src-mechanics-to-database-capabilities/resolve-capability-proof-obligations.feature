@capability:resolve-capability-proof-obligations
@root-scenario:resolve-capability-proof-obligations
Feature: Resolve the proof obligations one admitted design owes

  A capability design already declares everything its proof must cover: an input
  contract with required fields, an outcome contract with variants, terminal
  dispositions, observable conditions, and any declared effect failures. Deriving
  the proof obligations from those declarations is mechanical, and rediscovering
  them for every capability is the entropy that produces hand-written fixture
  authoring aids.

  This capability resolves the obligation set and the fixture topology that
  discharges it. It does not author domain values. A fixture's shape, kind and
  coverage target are derived; the concrete values a fixture carries remain
  candidate testimony supplied or authored elsewhere.

  Resolution is pure. It consumes the declared contracts, variants, dispositions,
  conditions and effect failures it is given. It reads no filesystem, executes no
  fixture, and admits nothing.

  Coverage is proven, never assumed. Every terminal disposition owes one
  obligation. Every required input field owes a missing-input obligation and an
  invalid-input obligation. Every observable condition owes an obligation. Every
  declared effect failure owes one. An obligation set that omits any of these is
  incomplete and says so, because a proof that covers only the happy path proves
  only that the happy path exists.

  The native-mutation witness (a semantic distinction asserted against an emitted
  body) and the independent validator/compiler witness are checks the current code
  performs without a declared counterpart. Each must resolve to a declared
  obligation and fixture before the code check can be retired; until then the
  check has no declared coverage and that absence is a finding.

  @scenario:resolve-capability-proof-obligations
  @input:proof-obligation-request
  @input-contract:proof-obligation-request.v1
  @event:resolve-capability-proof-obligations
  @event-authority:resolve-capability-proof-obligations.v1
  @outcome:capability-proof-obligation-set
  @outcome-contract:capability-proof-obligation-set.v1
  @outcome-terminal
  Scenario: Return one exact obligation set for one admitted design
    Given one declared input contract, outcome contract, terminal disposition set and observable condition set
    When the proof obligations are resolved
    Then one obligation set binds every derived obligation, its fixture candidate, and the exact coverage of each declared surface
    And PROOF_OBLIGATIONS_CLOSED is returned only when no declared surface remains uncovered

  @scenario:derive-positive-obligation
  @input:proof-obligation-request
  @input-contract:proof-obligation-request.v1
  @event:derive-positive-obligation
  @event-authority:derive-positive-obligation.v1
  @outcome:positive-obligation
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Derive the obligation that the capability performs its promise
    Given one declared outcome contract
    When the positive obligation is derived
    Then exactly one positive obligation is derived for the declared successful outcome
    And a design declaring no successful outcome returns POSITIVE_OUTCOME_UNDECLARED

  @scenario:derive-missing-input-obligations
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:derive-missing-input-obligations
  @event-authority:derive-missing-input-obligations.v1
  @outcome:missing-input-obligations
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Derive one missing-input obligation for every required field
    Given one declared input contract carrying required fields
    When the missing-input obligations are derived
    Then every required field owes exactly one missing-input obligation
    And a required field without a missing-input obligation returns REQUIRED_INPUT_FIELD_UNCOVERED

  @scenario:derive-invalid-input-obligations
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:derive-invalid-input-obligations
  @event-authority:derive-invalid-input-obligations.v1
  @outcome:invalid-input-obligations
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Derive one invalid-input obligation for every constrained field
    Given one declared input contract carrying constrained fields
    When the invalid-input obligations are derived
    Then every constrained field owes exactly one invalid-input obligation
    And a constraint that no obligation exercises returns INPUT_CONSTRAINT_UNCOVERED

  @scenario:derive-terminal-variant-obligations
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:derive-terminal-variant-obligations
  @event-authority:derive-terminal-variant-obligations.v1
  @outcome:terminal-variant-obligations
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Derive one obligation for every declared terminal disposition
    Given one declared terminal disposition set
    When the terminal variant obligations are derived
    Then every terminal disposition owes exactly one obligation
    And a design declaring no terminal disposition returns TERMINAL_DISPOSITIONS_UNDECLARED rather than an empty obligation set

  @scenario:derive-effect-failure-obligations
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:derive-effect-failure-obligations
  @event-authority:derive-effect-failure-obligations.v1
  @outcome:effect-failure-obligations
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Derive one obligation for every declared effect failure
    Given one declared effect failure set
    When the effect failure obligations are derived
    Then every declared effect failure owes exactly one obligation
    And a capability declaring effects without declaring their failures returns EFFECT_FAILURE_UNDECLARED

  @scenario:derive-observable-condition-obligations
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:derive-observable-condition-obligations
  @event-authority:derive-observable-condition-obligations.v1
  @outcome:observable-condition-obligations
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Derive one obligation for every observable condition
    Given one declared observable condition set
    When the observable condition obligations are derived
    Then every observable condition the experience promises owes exactly one obligation
    And an unobserved promised condition returns OBSERVABLE_CONDITION_UNCOVERED

  @scenario:derive-native-mutation-obligations
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:derive-native-mutation-obligations
  @event-authority:derive-native-mutation-obligations.v1
  @outcome:native-mutation-obligations
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Derive one obligation for every native mutation the proof asserts
    Given the semantic distinctions the native projection proof asserts against an emitted body
    When the native mutation obligations are derived
    Then every asserted distinction owes exactly one obligation bound to the declared body region it exercises
    And an asserted distinction with no declared obligation returns NATIVE_MUTATION_UNCOVERED

  @scenario:derive-validator-witness-obligations
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:derive-validator-witness-obligations
  @event-authority:derive-validator-witness-obligations.v1
  @outcome:validator-witness-obligations
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Derive one obligation for every independent validator or compiler witness
    Given the projected contracts and the independent validator and compiler checks performed over them
    When the validator witness obligations are derived
    Then every independent check owes exactly one obligation stating the contract surface it witnesses
    And an independent check with no declared obligation returns VALIDATOR_WITNESS_UNCOVERED

  @scenario:bind-fixture-candidates-without-authoring-values
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:bind-fixture-candidates-without-authoring-values
  @event-authority:bind-fixture-candidates-without-authoring-values.v1
  @outcome:fixture-candidate-set
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Bind fixture topology while leaving domain values to testimony
    Given one derived obligation set
    When the fixture candidates are bound
    Then every obligation carries one fixture candidate naming its kind and coverage target
    And a fixture candidate carrying an invented domain value returns PROOF_VALUE_FABRICATED, because deriving what must be proven is not the same as deciding what the answer is

  @scenario:close-proof-coverage
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:close-proof-coverage
  @event-authority:close-proof-coverage.v1
  @outcome:proof-coverage-ledger
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Prove expected against covered surfaces
    Given one obligation set and the declared surfaces it must cover
    When coverage is closed
    Then the ledger reports every declared surface, its obligation, and any surface left uncovered
    And any uncovered surface holds the resolution rather than reporting closure

  @scenario:replay-proof-obligation-resolution
  @input:proof-obligation-inputs
  @input-contract:proof-obligation-carrier.v1
  @event:replay-proof-obligation-resolution
  @event-authority:replay-proof-obligation-resolution.v1
  @outcome:obligation-replay-disposition
  @outcome-contract:proof-obligation-carrier.v1
  Scenario: Require byte-identical replay without self-issued correctness
    Given one frozen design declaration
    When the obligations are resolved twice
    Then both obligation sets are byte-identical
    And a divergent replay returns PROOF_OBLIGATION_REPLAY_DIVERGED rather than the later set
