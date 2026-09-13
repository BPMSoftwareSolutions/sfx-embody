@capability:construct-embodiment-plan
@root-scenario:construct-embodiment-plan
Feature: Construct an embodiment plan from one capability identity, target and profile

  This capability composes the read, the binding resolution and the plan. It reads
  the capability's authority for the selected profile, resolves the provider
  bindings for that profile, and plans the embodiment. It adds no meaning of its
  own and carries no target-specific branch.

  The composed children are declared in order: read-capability-authority produces
  the authority declaration, resolve-provider-slot-bindings turns it into the
  provider-slot binding set, and plan-capability-embodiment consumes that set. The
  composition stops at the exact first non-success and returns that child's
  disposition rather than collapsing it. A profile with an unbound requirement
  yields a held plan naming the requirement, never a plan that omits it.

  The initial construct-embodiment-plan-request.v1 passes unchanged to
  read-capability-authority. Each subsequent child consumes the preceding child's
  outcome: capability-authority-declaration.v1, then provider-slot-binding-set.v1.
  The final outcome is capability-embodiment-plan.v1.

  @scenario:construct-embodiment-plan
  @input:construct-embodiment-plan-request
  @input-contract:construct-embodiment-plan-request.v1
  @event:construct-embodiment-plan
  @event-authority:construct-embodiment-plan.v1
  @outcome:capability-embodiment-plan
  @outcome-contract:capability-embodiment-plan.v1
  @outcome-variants:EMBODIMENT_PLANNED|EMBODIMENT_PLAN_HELD
  @outcome-terminal
  Scenario: Compose read, binding resolution and plan for one target
    Given one capability identity, one optional scenario and one target
    When read-capability-authority, resolve-provider-slot-bindings and plan-capability-embodiment run in declared order
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
    When read-capability-authority runs with the unchanged request
    Then the authority declaration for that profile is returned or its unresolved requirement is propagated

  @scenario:resolve-provider-bindings-scope
  @input:capability-authority-declaration
  @input-contract:capability-authority-declaration.v1
  @event:resolve-provider-bindings-scope
  @event-authority:resolve-provider-bindings-scope.v1
  @outcome:provider-slot-binding-set
  @outcome-contract:provider-slot-binding-set.v1
  Scenario: Resolve the provider bindings from the read authority
    Given one authority declaration for the requested target-profile
    When resolve-provider-slot-bindings runs with the unchanged authority declaration
    Then one provider-slot binding set is returned or the unbound or ambiguous slot is propagated

  @scenario:plan-embodiment-scope
  @input:provider-slot-binding-set
  @input-contract:provider-slot-binding-set.v1
  @event:plan-embodiment-scope
  @event-authority:plan-embodiment-scope.v1
  @outcome:capability-embodiment-plan
  @outcome-contract:capability-embodiment-plan.v1
  Scenario: Plan the embodiment from the resolved binding set
    Given one provider-slot binding set carrying the authority declaration and its providers
    When plan-capability-embodiment runs with the unchanged binding set
    Then the content-addressed embodiment plan for the profile is returned or the held plan is propagated
