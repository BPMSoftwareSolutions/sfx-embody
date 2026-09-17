@capability:execute-projected-model-provider-attempt
@root-scenario:execute-projected-model-provider-attempt
Feature: Execute one projected model-provider attempt

  This internal capability executes exactly one already-selected model-provider
  attempt from admitted provider and model authority. Provider kind, concrete
  model, adapter identity, endpoint, credential reference, protocol projection,
  response-normalization identity, limits, and evidence policy are supplied as
  data in the invocation plan. No provider or model is selected in executable
  runtime code, and adding a provider does not change the conveyor or HTTP and
  credential mechanics.

  The capability monotonically composes the projected provider-protocol
  adapter, canonical HTTP request-body projection, opaque external-credential
  binding, and the single governed HTTP exchange under one shared effect
  context. It then invokes the projected protocol adapter for normalization
  and returns normalized, credential-free attempt evidence. Provider response
  content remains untrusted testimony; this capability does not retry, switch
  providers, repair content, accept candidates, or promote artifacts.

  @scenario:execute-projected-model-provider-attempt
  @input:projected-model-provider-attempt-plan
  @input-contract:execute-projected-model-provider-attempt-input.v1
  @event:projected-model-provider-attempt-requested
  @event-authority:execute-projected-model-provider-attempt.v1
  @outcome:projected-model-provider-attempt-evidence
  @outcome-contract:projected-model-provider-attempt-evidence.v1
  @outcome-terminal
  Scenario: Execute one selected provider attempt through projected capabilities
    Given one admitted provider-neutral request and one exact provider, model, adapter, endpoint, credential, protocol, effect, and evidence plan
    When the attempt is executed through projected protocol, representation, credential, and HTTP capabilities in one shared effect scope
    Then one normalized credential-free attempt receipt preserves exact provider and model identity, request and response hashes, usage, timing, native transport testimony, complete nested lineage, one exchange at most, and no retry, provider switch, repair, acceptance, or promotion claim
