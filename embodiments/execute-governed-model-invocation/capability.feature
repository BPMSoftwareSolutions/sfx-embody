@capability:execute-governed-model-invocation
@root-scenario:execute-governed-model-invocation
Feature: Execute governed model invocations

  # Legacy oracles:
  # generic-llm-connector/acceptance/obtains-model-response.feature
  # generic-llm-connector/src/obtains-model-response
  # generic-llm-connector/providers/gemini
  # generic-llm-connector/providers/openai

  This capability obtains one normalized model response under an admitted
  provider-neutral request, governed provider binding, projected adapter
  capabilities, narrow credential and HTTP effects, attempt authority, and
  evidence policy. Its execution objective includes text and structured
  success, every pre-invocation rejection, every provider and transport
  disposition, format enforcement, continuation and exhaustion, cancellation,
  evidence-policy variants, and a receipt on every exit.

  It does not author prompts, select providers, infer fallback, expose secrets,
  hide retries, repair responses, validate domain meaning, accept candidates,
  or promote implementations. Model content remains untrusted testimony.

  @scenario:execute-governed-model-invocation
  @input:governed-text-model-invocation
  @input-contract:execute-governed-model-invocation-input.v1
  @event:governed-text-model-invocation-requested
  @event-authority:execute-governed-model-invocation.v1
  @outcome:governed-text-model-response
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Obtain a text response from the exact governed provider
    Given one valid text request, exact provider binding, one authorized attempt, and available credential and HTTP effects
    When the governed model invocation is executed
    Then MODEL_RESPONSE_OBTAINED returns normalized text, exact provider and concrete model, request and response hashes, usage and timing as authorized, one attempt testimony, complete lineage, and no acceptance claim

  @scenario:obtain-structured-model-response
  @input:governed-structured-model-invocation
  @input-contract:execute-governed-model-invocation-input.v1
  @event:governed-structured-model-invocation-requested
  @event-authority:obtain-structured-model-response.v1
  @outcome:governed-structured-model-response
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Obtain structured output satisfying the declared schema
    Given one valid structured-generation request with an admitted response schema and one provider model supporting structured output
    When the governed model invocation is executed
    Then MODEL_RESPONSE_OBTAINED returns the schema-valid structured value and credential-free provider testimony with complete execution proof and no domain-validity or acceptance claim

  @scenario:reject-invalid-governed-model-request
  @input:invalid-governed-model-invocation-request
  @input-contract:execute-governed-model-invocation-input.v1
  @event:invalid-governed-model-invocation-requested
  @event-authority:reject-invalid-governed-model-request.v1
  @outcome:governed-model-request-rejection
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Reject every malformed request partition before effects
    Given a non-object request or a request with invalid identities, interaction, messages, response policy, structured schema, timeout, attempt authority, substitution declaration, or evidence flags
    When the request is admitted for invocation
    Then MODEL_REQUEST_REJECTED returns all pointer-bound findings in stable order, zero attempts, and a pre-invocation receipt without resolving authority, reading credentials, or contacting a provider

  @scenario:preserve-canonical-model-request-identity
  @input:semantically-equivalent-model-request-serializations
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-request-identity-proof-requested
  @event-authority:preserve-canonical-model-request-identity.v1
  @outcome:canonical-model-request-identity-evidence
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Canonicalize equivalent requests and distinguish semantic changes
    Given requests with equivalent object meaning in different key order and requests differing in at least one semantic value
    When their credential-free request identities are constructed across authorized attempts
    Then equivalent requests share one stable hash, changed requests have different hashes, and every attempt in one execution retains the same request hash

  @scenario:reject-stale-model-provider-binding
  @input:stale-model-provider-invocation-binding
  @input-contract:execute-governed-model-invocation-input.v1
  @event:stale-model-provider-invocation-requested
  @event-authority:reject-stale-model-provider-binding.v1
  @outcome:stale-model-provider-invocation-rejection
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Reject a binding that no longer matches admitted authority
    Given a valid model request and a provider, model, adapter, endpoint, or policy binding whose digest or request identity is stale
    When invocation prerequisites are verified
    Then the invocation is held with exact drift findings, zero attempts, and a receipt without credential access, protocol projection, or network effects

  @scenario:fail-unavailable-model-credential
  @input:model-invocation-with-unavailable-credential
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-invocation-with-unavailable-credential-requested
  @event-authority:fail-unavailable-model-credential.v1
  @outcome:model-provider-authentication-unavailable
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Fail before transmission when the credential reference is unavailable
    Given a valid invocation whose authorized credential reference is missing, empty, mismatched, expired, or unavailable from the external credential port
    When credential binding is requested
    Then PROVIDER_AUTHENTICATION_FAILED returns zero network exchanges, secret-free evidence, and a complete receipt without reading any alternative credential

  @scenario:classify-model-provider-authentication-failure
  @input:model-provider-authentication-failure-testimony
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-provider-authentication-failure-observed
  @event-authority:classify-model-provider-authentication-failure.v1
  @outcome:model-provider-authentication-failure
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Classify a provider-reported authentication failure
    Given one authorized exchange whose provider response reports invalid or unauthorized credentials
    When provider testimony is normalized
    Then PROVIDER_AUTHENTICATION_FAILED preserves the provider status and response hash without secret material, retry, fallback, or provider substitution

  @scenario:classify-model-provider-timeout
  @input:model-provider-timeout-testimony
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-provider-timeout-observed
  @event-authority:classify-model-provider-timeout.v1
  @outcome:model-provider-timeout
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Classify an elapsed provider timeout
    Given one authorized exchange that exceeds its admitted timeout or produces the equivalent transport-abort testimony
    When provider testimony is normalized
    Then PROVIDER_TIMED_OUT preserves attributable timing and attempt evidence and continues only when explicit remaining attempt authority permits it

  @scenario:classify-model-provider-unavailability
  @input:model-provider-unavailability-testimony
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-provider-unavailability-observed
  @event-authority:classify-model-provider-unavailability.v1
  @outcome:model-provider-unavailable
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Classify transport or provider unavailability
    Given one authorized exchange with DNS, TLS, socket, network, rate-limit, overload, or service-unavailable testimony classified as transient by adapter authority
    When provider testimony and continuation authority are evaluated
    Then PROVIDER_UNAVAILABLE preserves native evidence and either stops or authorizes exactly the next declared attempt without changing provider identity

  @scenario:retain-model-provider-request-rejection
  @input:model-provider-request-rejection-testimony
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-provider-request-rejection-observed
  @event-authority:retain-model-provider-request-rejection.v1
  @outcome:model-provider-request-rejected
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Retain non-transient provider rejection testimony
    Given one exchange reporting an invalid request, content-policy block, model refusal, truncated completion, or another adapter-classified non-transient provider rejection
    When provider testimony is normalized
    Then PROVIDER_REQUEST_REJECTED preserves safe native facts and hashes, consumes no further attempt, and performs no repair, fallback, or substitution

  @scenario:reject-malformed-structured-model-response
  @input:malformed-structured-model-response-testimony
  @input-contract:execute-governed-model-invocation-input.v1
  @event:malformed-structured-model-response-observed
  @event-authority:reject-malformed-structured-model-response.v1
  @outcome:malformed-structured-model-response-rejection
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Reject structured output that cannot be parsed
    Given a provider reports success but the required structured response cannot be parsed as the declared representation
    When the response format is normalized
    Then RESPONSE_FORMAT_NOT_SATISFIED retains invalid content only as its authorized hash plus safe completion facts and never repairs or returns the malformed value

  @scenario:reject-schema-incompatible-model-response
  @input:schema-incompatible-model-response-testimony
  @input-contract:execute-governed-model-invocation-input.v1
  @event:schema-incompatible-model-response-observed
  @event-authority:reject-schema-incompatible-model-response.v1
  @outcome:schema-incompatible-model-response-rejection
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Reject parsed output that violates the declared schema
    Given provider output parses as structured data but fails the admitted response contract
    When structured response conformance is evaluated
    Then RESPONSE_FORMAT_NOT_SATISFIED returns exact contract findings and response hash without returning, coercing, or repairing the nonconforming value

  @scenario:continue-transient-model-attempt
  @input:transient-model-attempt-with-continuation-authority
  @input-contract:execute-governed-model-invocation-input.v1
  @event:transient-model-attempt-continuation-requested
  @event-authority:continue-transient-model-attempt.v1
  @outcome:continued-model-attempt-evidence
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Continue after transient testimony only when explicitly authorized
    Given one transient timeout or unavailable disposition, an explicit continuation rule, and unused attempt authority
    When attempt continuation is determined
    Then exactly one next attempt against the unchanged provider binding is eligible and both attempts retain ordered testimony and one stable request identity

  @scenario:stop-non-transient-model-attempt
  @input:non-transient-model-attempt-testimony
  @input-contract:execute-governed-model-invocation-input.v1
  @event:non-transient-model-attempt-stop-requested
  @event-authority:stop-non-transient-model-attempt.v1
  @outcome:stopped-non-transient-model-attempt
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Stop after a non-transient provider disposition
    Given remaining attempt authority and authentication, request-rejection, response-format, cancellation, or internal-failure testimony
    When continuation is determined
    Then no additional attempt is eligible and the exact current disposition and attempt testimony are returned unchanged

  @scenario:exhaust-model-attempt-authority
  @input:exhausted-model-attempt-testimony
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-attempt-exhaustion-requested
  @event-authority:exhaust-model-attempt-authority.v1
  @outcome:model-attempt-authority-exhausted
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Stop exactly at the maximum authorized attempt count
    Given ordered transient provider testimony consuming every explicitly authorized attempt
    When continuation is evaluated after the final attempt
    Then ATTEMPT_AUTHORITY_EXHAUSTED returns every attempt testimony in order and no further adapter, credential, timer, or network effect is invoked

  @scenario:prevent-undeclared-model-attempt-or-substitution
  @input:undeclared-model-attempt-or-substitution-request
  @input-contract:execute-governed-model-invocation-input.v1
  @event:undeclared-model-attempt-or-substitution-requested
  @event-authority:prevent-undeclared-model-attempt-or-substitution.v1
  @outcome:undeclared-model-attempt-or-substitution-rejection
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Prevent hidden retry fallback and provider substitution
    Given a request lacking a required continuation rule or substitution authority and a failed authorized provider attempt
    When another attempt or different provider is considered
    Then no undeclared attempt or adapter is eligible and the original provider disposition and binding remain unchanged

  @scenario:cancel-model-invocation
  @input:model-invocation-cancellation
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-invocation-cancellation-requested
  @event-authority:cancel-model-invocation.v1
  @outcome:model-invocation-cancelled
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Cancel an eligible or active invocation without continuation
    Given cancellation authority observed before transmission or while one authorized exchange is active
    When cancellation is applied
    Then EXECUTION_CANCELLED returns attributable cancellation and any completed attempt testimony with no new attempt, provider substitution, response invention, or acceptance claim

  @scenario:classify-internal-model-execution-failure
  @input:internal-model-execution-failure-testimony
  @input-contract:execute-governed-model-invocation-input.v1
  @event:internal-model-execution-failure-observed
  @event-authority:classify-internal-model-execution-failure.v1
  @outcome:internal-model-execution-failed
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Retain an attributable internal connector failure
    Given projection, adapter, normalization, hashing, schema, or receipt mechanics fail outside a classified provider disposition
    When the failure boundary is observed
    Then INTERNAL_EXECUTION_FAILED returns the responsible stage and safe lineage without leaking secrets, swallowing the error, retrying, substituting, or inventing provider testimony

  @scenario:honor-model-evidence-policy
  @input:model-invocation-evidence-policy-variants
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-invocation-evidence-policy-evaluation-requested
  @event-authority:honor-model-evidence-policy.v1
  @outcome:policy-bounded-model-invocation-evidence
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Include or omit optional evidence exactly as declared
    Given equivalent completed invocations with each admitted request-hash, response-hash, provider, model, usage, and timing evidence flag enabled or disabled
    When their execution evidence is constructed
    Then required disposition and attempt lineage always remain while each optional field is present or absent exactly according to policy and no credential value is ever included

  @scenario:return-model-execution-receipt-on-every-exit
  @input:model-invocation-exit-partitions
  @input-contract:execute-governed-model-invocation-input.v1
  @event:model-execution-receipt-closure-requested
  @event-authority:return-model-execution-receipt-on-every-exit.v1
  @outcome:closed-model-execution-receipts
  @outcome-contract:governed-model-invocation-evidence.v1
  @outcome-terminal
  Scenario: Return a receipt for every reached and pre-invocation disposition
    Given one execution from each admitted success, validation, resolution, authentication, availability, timeout, rejection, format, exhaustion, cancellation, and internal-failure partition
    When receipt closure is evaluated
    Then every exit has one disposition and credential-free receipt containing exactly the authority and observations reached on that path without fabricated provider, model, attempt, timing, response, or usage evidence
