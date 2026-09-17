@capability:obtain-governed-model-response
@root-scenario:obtain-governed-model-response
Feature: Obtain one governed model response as untrusted testimony

  A downstream authoring capability needs model assistance without granting the
  model authority over source admission, projection, acceptance, or promotion.
  The invocation request fixes the provider authority, model alias, response
  contract, attempt limit, substitution policy, and evidence policy before any
  external model is contacted.

  Every model alias a caller may name is bound to an exact admitted provider
  and model embodiment in the model-provider conveyor authority. A declared
  alias without an admitted embodiment is rejected with exact identities â€”
  never defaulted to another alias, never substituted by guessing, and never
  satisfied by a partial carrier.

  The admitted generic LLM connector owns provider resolution and invocation.
  Credentials remain outside scenario facts and evidence. The response is
  normalized, attributed, and hash-bound so a consuming capability can admit or
  reject its contents independently.

  Provider rejection, timeout, malformed structured output, and policy failure
  remain exact governed dispositions. A response obtained from Gemini is still
  candidate testimony and cannot claim that any generated artifact conforms.

  For structured generation, the caller supplies one provider-neutral response
  schema. The conveyor carries that same schema into provider-protocol
  projection. Provider-specific schema translation remains owned by
  project-model-provider-protocol and is never pushed back into the caller.

  @scenario:obtain-governed-model-response
  @input:governed-model-invocation-request
  @input-contract:governed-model-invocation-request.v1
  @event:governed-model-response-requested
  @event-authority:obtain-governed-model-response.v1
  @outcome:governed-model-response-observed
  @outcome-contract:governed-model-response-evidence.v1
  @outcome-terminal
  Scenario: Obtain one policy-bounded model response
    Given one admitted immutable model request with fixed provider, model, response, attempt, substitution, and evidence authority
    When the admitted generic LLM connector is asked to obtain the governed response
    Then the exact normalized response or governed failure disposition is returned with provider, model, attempt, timing, and hash lineage and no acceptance claim

  @scenario:resolve-model-alias-embodiment
  @input:governed-model-invocation-request
  @input-contract:governed-model-invocation-request.v1
  @event:resolve-model-alias-embodiment
  @event-authority:resolve-model-alias-embodiment.v1
  @outcome:model-provider-embodiment-resolution
  @outcome-contract:model-provider-embodiment-resolution.v1
  @outcome-terminal
  Scenario: Resolve the model alias to its exact admitted provider and model embodiment
    Given one governed model request declaring a model alias and one provider authority, and the admitted model-provider conveyor authority
    When the alias resolves through the conveyor authority to its exact provider kind, model, adapter identity, and credential reference
    Then either one embodiment resolution carries the exact primary provider and model with the original request and alias resolution lineage, or one authorized substitute embodiment is resolved when the declared substitution policy authorizes it for a classified provider-path finding, or substitution is not authorized, or the alias is rejected with exact identities when no admitted embodiment binds it â€” and no other alias or provider is ever substituted by guessing

  @scenario:project-model-response-policy-to-provider-protocol
  @input:model-provider-embodiment-resolution
  @input-contract:model-provider-embodiment-resolution.v1
  @event:project-model-response-policy-to-provider-protocol
  @event-authority:project-model-response-policy-to-provider-protocol.v1
  @outcome:model-provider-protocol-response-policy
  @outcome-contract:model-provider-protocol-response-policy.v1
  @outcome-terminal
  Scenario: Project the model response policy into provider-neutral protocol context
    Given one model provider embodiment resolution carrying the original governed model request, the resolved provider authority, the resolved model, and the alias resolution lineage
    When the provider-neutral protocol response context is constructed
    Then text carries no responseSchema, JSON carries the exact admitted responsePolicy schema, and no provider-specific schema field is required from the caller

  @scenario:obtain-governed-provider-testimony
  @input:model-provider-protocol-response-policy
  @input-contract:model-provider-protocol-response-policy.v1
  @event:obtain-governed-provider-testimony
  @event-authority:obtain-governed-provider-testimony.v1
  @outcome:governed-provider-testimony
  @outcome-contract:governed-provider-testimony.v1
  Scenario: Obtain governed provider testimony through the admitted connector
    Given one projected provider protocol policy and the resolved model embodiment it was projected from
    When the admitted generic LLM connector is asked to obtain the provider response once
    Then governed provider testimony carrying provider, model, attempt, timing, and hash lineage is observed, or the exact governed failure disposition is returned without retry, substitution, or repair

  @scenario:establish-governed-model-response-evidence
  @input:governed-provider-testimony
  @input-contract:governed-provider-testimony.v1
  @event:establish-governed-model-response-evidence
  @event-authority:establish-governed-model-response-evidence.v1
  @outcome:governed-model-response-observed
  @outcome-contract:governed-model-response-evidence.v1
  @outcome-terminal
  Scenario: Establish the governed model response evidence
    Given one governed provider testimony with its full provider, model, attempt, timing, and hash lineage
    When the governed model response evidence is established from the testimony
    Then the exact normalized response or governed failure disposition is established with full lineage and no acceptance claim, and no testimony is repaired or reinterpreted
