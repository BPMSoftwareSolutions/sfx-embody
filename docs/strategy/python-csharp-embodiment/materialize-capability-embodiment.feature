@capability:materialize-capability-embodiment
@root-scenario:materialize-capability-embodiment
Feature: Materialize a capability embodiment end to end for any declared target

  This capability composes the plan and the write. It reads the capability
  authority for the requested target, resolves the profile's provider bindings,
  plans the embodiment and writes it beneath an authorized root. It carries the
  target as data: adding a target is a profile and a binding set, never a new
  path.

  The composition stops at the first non-success and returns it. Behavior is the
  contract: the target's declared dispositions must be reproduced, and because a
  plan-form body differs from a per-port body, the materialization establishes and
  verifies the new plan and artifact digests rather than preserving an earlier
  generation's digests.

  @scenario:materialize-capability-embodiment
  @input:materialize-capability-embodiment-request
  @input-contract:materialize-capability-embodiment-request.v1
  @event:materialize-capability-embodiment
  @event-authority:materialize-capability-embodiment.v1
  @outcome:capability-embodiment-materialization
  @outcome-contract:capability-embodiment-materialization.v1
  @outcome-variants:EMBODIMENT_WRITTEN|EMBODIMENT_HELD
  @outcome-terminal
  Scenario: Materialize one capability for one declared target
    Given one capability identity, one target and one authorized output root
    When construct-embodiment-plan and write-capability-embodiment run in declared order
    Then the materialization record is returned or the first child non-success is returned verbatim

  @scenario:hold-materialization-without-bound-provider
  @input:materialize-capability-embodiment-request
  @input-contract:materialize-capability-embodiment-request.v1
  @event:hold-materialization-without-bound-provider
  @event-authority:hold-materialization-without-bound-provider.v1
  @outcome:capability-embodiment-materialization
  @outcome-contract:capability-embodiment-materialization.v1
  @outcome-terminal
  Scenario: Hold materialization when the target has no bound provider for a required mechanic
    Given one target whose profile declares a required mechanic with no admitted provider
    When materialization runs
    Then materialization is held naming the unbound requirement and no artifact is written
