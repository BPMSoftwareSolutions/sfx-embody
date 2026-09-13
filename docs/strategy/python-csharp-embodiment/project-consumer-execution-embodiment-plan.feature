@capability:project-consumer-execution-embodiment-plan
@root-scenario:project-consumer-execution-embodiment-plan
Feature: Project the admitted consumer execution embodiment plan

  The consumer execution embodiment pipeline begins from an admitted projection
  context: the projected execution plan together with the registered projection
  authorities and the fixture authority. The platform pipeline consumes that
  context, but no scenario in the current model declares its production. This
  capability supplies it.

  It reads one capability's retained authority, projects the target-neutral
  execution plan and its registered projection authorities for the selected
  targets, and admits the resulting context. It does not render a candidate, run a
  fixture, or accept the projection; those remain the authority of the downstream
  composition.

  The context is an input presupposition of the consumer execution embodiment
  pipeline. Producing it here makes the pipeline's first input declared instead of
  assumed, and lets a missing plan authority be a held finding rather than a
  silently absent input.

  @scenario:project-consumer-execution-embodiment-plan
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:project-consumer-execution-embodiment-plan
  @event-authority:project-consumer-execution-embodiment-plan.v1
  @outcome:consumer-execution-embodiment-projection-context
  @outcome-contract:consumer-execution-embodiment-projection-context.v1
  @outcome-variants:EXECUTION_EMBODIMENT_CONTEXT_ADMITTED|EXECUTION_EMBODIMENT_PLAN_HELD
  @outcome-terminal
  Scenario: Project and admit the execution embodiment projection context
    Given one admitted capability embodiment authority and the selected targets
    When the execution plan and registered projection authorities are projected and the context is admitted
    Then one admitted projection context is returned or a held finding names the missing plan authority

  @scenario:derive-target-neutral-execution-plan
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:derive-target-neutral-execution-plan
  @event-authority:derive-target-neutral-execution-plan.v1
  @outcome:consumer-execution-embodiment-plan
  @outcome-contract:consumer-execution-embodiment-plan.v1
  Scenario: Derive the target-neutral execution plan
    Given one admitted capability embodiment authority
    When the execution plan is derived
    Then one target-neutral plan is returned with its operations, contracts and lineage
    And an authority that declares no execution operations returns EXECUTION_PLAN_UNDECLARED

  @scenario:register-projection-authorities
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:register-projection-authorities
  @event-authority:register-projection-authorities.v1
  @outcome:registered-projection-authority-set
  @outcome-contract:registered-projection-authority-set.v1
  Scenario: Register the projection authorities for the selected targets
    Given one execution plan and the selected targets
    When the projection authorities are registered
    Then every selected target names its admitted projection authority
    And a target with no registered projection authority returns PROJECTION_AUTHORITY_UNREGISTERED
