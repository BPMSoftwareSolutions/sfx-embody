@capability:plan-capability-embodiment
@root-scenario:plan-capability-embodiment
Feature: Plan one capability embodiment for a selected profile and provider binding

  A capability authority declaration states what must be embodied and which
  mechanics the selected profile requires. This capability turns that declaration
  into one content-addressed embodiment plan for the requested target.

  The plan is provider-driven. Each operation the plan will execute names the
  provider binding that will execute it, resolved from the declared bindings for
  the selected profile. The plan carries no target-specific code path: the target
  selects a profile, the profile selects providers, and the same authority plans
  for every profile. The plan records the profile, the provider bindings, the
  per-scenario body plan and the digests.

  Planning invokes no provider and writes nothing. A required operation whose
  provider is unbound is held rather than planned with a placeholder, and the plan
  is byte-identical when replayed against the same authority and bindings.

  @scenario:plan-capability-embodiment
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:plan-capability-embodiment
  @event-authority:plan-capability-embodiment.v1
  @outcome:capability-embodiment-plan
  @outcome-contract:capability-embodiment-plan.v1
  @outcome-variants:EMBODIMENT_PLANNED|EMBODIMENT_PLAN_HELD
  @outcome-terminal
  Scenario: Plan one embodiment for the declared authority and profile
    Given one capability authority declaration and one selected provider binding set
    When the embodiment plan is derived
    Then one plan binds the profile, the provider bindings, the per-scenario body plan, the plan digest and the artifact digest, or the unbound requirement is held

  @scenario:bind-plan-operations-to-providers
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:bind-plan-operations-to-providers
  @event-authority:bind-plan-operations-to-providers.v1
  @outcome:planned-operation-binding
  @outcome-contract:planned-operation-binding.v1
  Scenario: Bind every planned operation to its declared provider
    Given the declared operations and the resolved provider binding set
    When each operation is bound
    Then every operation names the provider definition that will execute it
    And an operation with no bound provider returns PLANNED_OPERATION_PROVIDER_UNBOUND

  @scenario:replay-embodiment-plan
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:replay-embodiment-plan
  @event-authority:replay-embodiment-plan.v1
  @outcome:capability-embodiment-plan
  @outcome-contract:capability-embodiment-plan.v1
  @outcome-terminal
  Scenario: Reproduce byte-identical plans for one authority and binding set
    Given one frozen authority declaration and binding set
    When the plan is derived twice
    Then both plans and both digests are byte-identical
    And a divergent replay returns EMBODIMENT_PLAN_REPLAY_DIVERGED
