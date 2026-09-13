@capability:read-capability-authority
@root-scenario:read-capability-authority
Feature: Read one capability authority for a selected profile

  The materializer must learn what a capability declares before it can plan an
  embodiment. This capability reads that authority from the selected generation:
  the retained authority, the invocation closure, the mechanic declarations and
  the provider requirements, bound to the snapshot and projection.

  The read is target-neutral. It names the profile and target it is asked for and
  returns the requirements for that profile; it does not assume Node, and it does
  not resolve a provider. A capability whose authority cannot be resolved for the
  requested profile is held with the exact unresolved requirement rather than
  reported as an empty declaration.

  @scenario:read-capability-authority
  @input:capability-authority-read-request
  @input-contract:capability-authority-read-request.v1
  @event:read-capability-authority
  @event-authority:read-capability-authority.v1
  @outcome:capability-authority-declaration
  @outcome-contract:capability-authority-declaration.v1
  @outcome-variants:CAPABILITY_AUTHORITY_READ|CAPABILITY_AUTHORITY_UNRESOLVED
  @outcome-terminal
  Scenario: Read one capability authority for one profile
    Given one capability identity, one optional scenario, and one requested profile
    When the authority is read from the selected generation
    Then the retained authority, invocation closure, mechanic declarations and profile requirements are returned or the unresolved requirement is held

  @scenario:resolve-select-profile-requirements
  @input:capability-authority-read-request
  @input-contract:capability-authority-read-request.v1
  @event:resolve-selected-profile-requirements
  @event-authority:resolve-selected-profile-requirements.v1
  @outcome:profile-requirement-declaration
  @outcome-contract:profile-requirement-declaration.v1
  Scenario: Resolve the requirements of the requested profile
    Given one requested profile and the capability's declared slots
    When the profile requirements are resolved
    Then every requirement the profile names is returned from rows
    And a profile declaring no provider for a required mechanic returns PROFILE_PROVIDER_ABSENT rather than a partial declaration
