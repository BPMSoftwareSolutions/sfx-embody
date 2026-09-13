@capability:construct-embodiment-plan
@root-scenario:construct-embodiment-plan
Feature: Construct an embodiment plan from one capability identity, target and profile

  This capability composes the read and the plan. It reads the capability's
  authority for the selected profile, resolves the provider bindings for that
  profile, and plans the embodiment. It adds no meaning of its own and carries no
  target-specific branch.

  The composition stops at the exact first non-success and returns that child's
  disposition rather than collapsing it. A profile with an unbound requirement
  yields a held plan naming the requirement, never a plan that omits it.

  @scenario:construct-embodiment-plan
  @input:construct-embodiment-plan-request
  @input-contract:construct-embodiment-plan-request.v1
  @event:construct-embodiment-plan
  @event-authority:construct-embodiment-plan.v1
  @outcome:capability-embodiment-plan
  @outcome-contract:capability-embodiment-plan.v1
  @outcome-variants:EMBODIMENT_PLANNED|EMBODIMENT_PLAN_HELD
  @outcome-terminal
  Scenario: Compose read and plan for one target
    Given one capability identity, one optional scenario and one target
    When read-capability-authority and plan-capability-embodiment run in declared order
    Then the embodiment plan is returned or the first child non-success is returned verbatim

  @scenario:read-authority-scope
  @input:construct-embodiment-plan-request
  @input-contract:construct-embodiment-plan-request.v1
  @event:read-authority-scope
  @event-authority:read-authority-scope.v1
  @outcome:capability-authority-declaration
  @outcome-contract:capability-authority-declaration.v1
  Scenario: Read the authority for the requested target
    Given one capability identity and one requested target-profile
    When the authority read runs
    Then the authority declaration for that profile is returned or its unresolved requirement is propagated

  @scenario:plan-embodiment-scope
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:plan-embodiment-scope
  @event-authority:plan-embodiment-scope.v1
  @outcome:capability-embodiment-plan
  @outcome-contract:capability-embodiment-plan.v1
  Scenario: Plan the embodiment from the read authority
    Given one authority declaration and its resolved provider bindings
    When the plan runs
    Then the content-addressed embodiment plan for the profile is returned or the held plan is propagated
