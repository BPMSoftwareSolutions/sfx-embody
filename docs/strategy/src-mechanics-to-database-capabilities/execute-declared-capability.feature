@capability:execute-declared-capability
@root-scenario:execute-declared-capability
Feature: Execute one capability directly from its declaration

  A capability's declaration is its body. The estate today generates a native body
  (materialize-node, consumer-object-provider), loads it (load-memory-scenario) and
  runs it. That generate-and-run triple exists only because the declaration was
  treated as something to translate into code. This capability executes the
  declared operations instead, with the providers the binding rows select.

  Execution reads the admitted declaration and its resolved provider bindings,
  admits the scenario input against the declared input contract, executes each
  declared operation in order — an invoke-port by invoking the bound provider, an
  invoke-scenario by executing the target scenario's declared operations — admits
  the observed outcome against the declared outcome contract, and resolves the
  disposition. It generates no intermediate body and writes no file.

  The execution is target-neutral: the target selects a profile, the profile
  selects providers, and the same declaration executes on every profile whose
  required providers are bound. An operation whose provider is unbound is held, and
  a declared cycle is refused rather than run.

  @scenario:execute-declared-capability
  @input:capability-execution-request
  @input-contract:capability-execution-request.v1
  @event:execute-declared-capability
  @event-authority:execute-declared-capability.v1
  @outcome:capability-execution-result
  @outcome-contract:capability-execution-result.v1
  @outcome-variants:EXECUTION_COMPLETED|EXECUTION_HELD|INPUT_REJECTED|OUTCOME_REJECTED|EXECUTION_FAILED
  @outcome-terminal
  Scenario: Execute one capability from its declaration
    Given one admitted declaration, one resolved provider binding set and one scenario input
    When the declared operations execute against the bound providers
    Then the observed outcome is admitted and one disposition is returned bound to the declaration digest, or the exact held, rejected or failed disposition is returned

  @scenario:admit-declared-input
  @input:capability-execution-request
  @input-contract:capability-execution-request.v1
  @event:admit-declared-input
  @event-authority:admit-declared-input.v1
  @outcome:capability-execution-result
  @outcome-contract:capability-execution-result.v1
  Scenario: Admit the input against the declared input contract
    Given one scenario input and the declaration's declared input contract
    When input admission is evaluated
    Then the input is admitted or rejected with INPUT_REJECTED, and a rejected input never reaches execution

  @scenario:execute-declared-operations
  @input:capability-execution-request
  @input-contract:capability-execution-request.v1
  @event:execute-declared-operations
  @event-authority:execute-declared-operations.v1
  @outcome:capability-execution-result
  @outcome-contract:capability-execution-result.v1
  Scenario: Execute every declared operation with its bound provider
    Given one admitted input and the declared operation order
    When each declared operation executes
    Then every operation invokes the provider its binding selects or its target scenario's declared operations
    And an operation whose provider is unbound returns DECLARED_OPERATION_PROVIDER_UNBOUND, and a declared cycle returns DECLARED_OPERATION_CYCLE

  @scenario:admit-declared-outcome-and-resolve-disposition
  @input:capability-execution-request
  @input-contract:capability-execution-request.v1
  @event:admit-declared-outcome-and-resolve-disposition
  @event-authority:admit-declared-outcome-and-resolve-disposition.v1
  @outcome:capability-execution-result
  @outcome-contract:capability-execution-result.v1
  @outcome-terminal
  Scenario: Admit the observed outcome and resolve the declared disposition
    Given one observed outcome and the declaration's declared outcome contract and terminal dispositions
    When outcome admission and disposition resolution run
    Then the outcome is admitted and the declared disposition is returned, or OUTCOME_REJECTED is returned and no completion is claimed
