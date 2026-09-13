@capability:resolve-provider-slot-bindings
@root-scenario:resolve-provider-slot-bindings
Feature: Resolve the provider that fills each declared slot for one profile

  A capability declares what it needs as provider slots, and each slot names the
  ports, mechanics and profiles it requires. Providers declare which mechanics and
  capabilities they implement. The database already holds both. What no row yet
  holds is the selection: for one selected profile and target, which provider
  fills which slot.

  This capability resolves that selection. It reads the slot requirements, the
  admitted implementations and the declared profiles, and returns one binding per
  slot or an explicit finding for a slot it cannot bind. It invokes no provider,
  renders nothing, and writes nothing.

  Coverage is measured, never assumed. A slot with no matching implementation is
  held as unbound rather than silently left to a fallback. A slot with more than
  one eligible implementation under the profile is held as ambiguous rather than
  resolved by preference. The selection is derived from rows, so adding a target
  or changing a provider is a rebinding, never a new branch.

  @scenario:resolve-provider-slot-bindings
  @input:provider-slot-binding-request
  @input-contract:provider-slot-binding-request.v1
  @event:resolve-provider-slot-bindings
  @event-authority:resolve-provider-slot-bindings.v1
  @outcome:provider-slot-binding-set
  @outcome-contract:provider-slot-binding-set.v1
  @outcome-variants:PROVIDER_SLOTS_BOUND|PROVIDER_SLOT_UNBOUND|PROVIDER_SLOT_AMBIGUOUS
  @outcome-terminal
  Scenario: Resolve one exact provider binding per declared slot
    Given one selected capability, one profile, and the declared slot requirements
    When provider bindings are resolved from the admitted implementations
    Then return one provider definition per slot or an explicit finding naming the unbound or ambiguous slot

  @scenario:read-slot-requirements
  @input:provider-slot-binding-request
  @input-contract:provider-slot-binding-request.v1
  @event:read-provider-slot-requirements
  @event-authority:read-provider-slot-requirements.v1
  @outcome:provider-slot-requirements
  @outcome-contract:provider-slot-requirements.v1
  Scenario: Read every declared requirement of every slot
    Given the selected profile and the slots declared by the capability blueprint
    When the requirements of each slot are read
    Then every port, mechanic and profile requirement of every slot is returned
    And a slot that declares no requirement returns PROVIDER_SLOT_REQUIREMENT_ABSENT

  @scenario:select-provider-under-profile
  @input:provider-slot-requirements
  @input-contract:provider-slot-requirements.v1
  @event:select-provider-under-profile
  @event-authority:select-provider-under-profile.v1
  @outcome:provider-binding-candidate-set
  @outcome-contract:provider-binding-candidate-set.v1
  @outcome-variants:PROVIDER_BINDING_SELECTED|PROVIDER_IMPLEMENTATION_ABSENT|PROVIDER_IMPLEMENTATION_AMBIGUOUS
  Scenario: Select the admitted provider that satisfies the slot
    Given one slot requirement set and the declared provider implementations
    When the eligible implementations are matched under the selected profile
    Then exactly one provider is selected, or the slot is held as absent or ambiguous evidence

  @scenario:replay-provider-slot-binding
  @input:provider-slot-binding-request
  @input-contract:provider-slot-binding-request.v1
  @event:replay-provider-slot-binding
  @event-authority:replay-provider-slot-binding.v1
  @outcome:provider-slot-binding-set
  @outcome-contract:provider-slot-binding-set.v1
  @outcome-terminal
  Scenario: Reproduce byte-identical bindings for one frozen model
    Given one frozen model, profile and target
    When the bindings are resolved twice
    Then both binding sets are byte-identical
    And a divergent replay returns PROVIDER_SLOT_BINDING_REPLAY_DIVERGED rather than the later set
