@capability:deliver-governed-capability-invocation
@root-scenario:deliver-governed-capability-invocation
Feature: Deliver one governed capability invocation through a declared carrier

  The command line owns only argument and standard-stream carriers, canonical
  request construction, capability invocation and result rendering. A delivery
  declares its authorization as a policy: whether it may write, which root it may
  write beneath, whether it reads retained cache, and whether a memory-only storage
  proof applies. The memory-only and write-enabled deliveries differ by that policy
  alone, which is a row rather than a second transport implementation.

  The carrier resolves the selected capability from the estate, applies the
  declared policy, invokes the capability, and renders only its governed result. It
  never recreates orchestration, chooses a mutation set, infers success, or
  performs an undeclared effect.

  @scenario:deliver-governed-capability-invocation
  @input:capability-invocation-request
  @input-contract:capability-invocation-request.v1
  @event:deliver-governed-capability-invocation
  @event-authority:deliver-governed-capability-invocation.v1
  @outcome:capability-invocation-result
  @outcome-contract:capability-invocation-result.v1
  @outcome-terminal
  Scenario: Deliver one governed capability invocation
    Given one capability identity, one input and the delivery's declared policy
    When the carrier invokes the capability
    Then only the governed result is returned with the declared policy applied

  @scenario:apply-declared-delivery-policy
  @input:capability-invocation-request
  @input-contract:capability-invocation-request.v1
  @event:apply-declared-delivery-policy
  @event-authority:apply-declared-delivery-policy.v1
  @outcome:capability-invocation-result
  @outcome-contract:capability-invocation-result.v1
  Scenario: Apply the delivery policy declared for this boundary
    Given one delivery identity and its declared policy
    When the invocation is delivered
    Then the write authorization, authorized root, cache-read control and storage-proof control are applied exactly as declared

  @scenario:refuse-undeclared-effect
  @input:capability-invocation-request
  @input-contract:capability-invocation-request.v1
  @event:refuse-undeclared-capability-invocation-effect
  @event-authority:refuse-undeclared-capability-invocation-effect.v1
  @outcome:capability-invocation-result
  @outcome-contract:capability-invocation-result.v1
  @outcome-terminal
  Scenario: Refuse an effect the delivery is not authorized to perform
    Given an invocation that would write while the delivery policy authorizes no write, or would write outside the authorized root
    When the effect is attempted
    Then the invocation is refused with the exact authorization finding and no effect is performed

  @scenario:prove-memory-only-invocation
  @input:capability-invocation-request
  @input-contract:capability-invocation-request.v1
  @event:prove-memory-only-invocation
  @event-authority:prove-memory-only-invocation.v1
  @outcome:capability-invocation-result
  @outcome-contract:capability-invocation-result.v1
  @outcome-terminal
  Scenario: Prove the read-only delivery reads no retained cache and writes nothing
    Given the memory-only delivery policy
    When a capability is invoked
    Then the invocation is delivered with filesystem writes and capability-cache reads disabled, or the storage-proof violation is reported
