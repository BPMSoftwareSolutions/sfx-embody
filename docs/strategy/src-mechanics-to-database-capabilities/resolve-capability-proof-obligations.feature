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

  The native-mutation witness (a semantic distinction asserted against an emitted
  body) and the independent validator/compiler witness are checks the current
  code performs without a declared counterpart. Each must resolve to a declared
  obligation and fixture before the code check can be retired; until then the
  check has no declared coverage and that absence is a finding.

  Coverage is proven, never assumed. Every terminal disposition owes one
  obligation. Every required input field owes a missing-input obligation and an
  invalid-input obligation. Every observable condition owes an obligation. Every
  declared effect failure owes one. An obligation set that omits any of these is
  incomplete and says so, because a proof that covers only the happy path proves
  only that the happy path exists.

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
