@capability:project-model-provider-protocol
@root-scenario:project-model-provider-protocol
# Legacy oracles:
# generic-llm-connector/providers/gemini/maps-context-to-gemini-request.ts
# generic-llm-connector/providers/gemini/maps-gemini-testimony.ts
# generic-llm-connector/providers/gemini/invokes-gemini-model.ts
# generic-llm-connector/src/obtains-model-response/normalizes-model-response.ts
# generic-llm-connector/src/obtains-model-response/classifies-model-invocation-failure.ts
Feature: Project model provider protocols

  A consumer needs an admitted provider-neutral invocation context projected
  into the exact wire request of one provider, and one provider HTTP
  observation normalized back into canonical provider testimony, with every
  provider-specific mapping held in declarative adapter authority rather than
  native code. This capability projects one provider protocol both ways.

  Projection is deterministic and credential-free. It never performs an HTTP
  effect, resolves a provider, selects a model, retries, substitutes a
  provider, repairs model content, or admits candidates. Provider-specific
  behavior comes from admitted declarative adapter authority keyed by provider
  kind, interaction mode, and adapter identity; unsupported providers, modes,
  schema vocabulary, or adapter authorities are rejected before any projection
  is emitted.

  @scenario:project-model-provider-protocol
  @input:model-provider-protocol-projection-request
  @input-contract:project-model-provider-protocol-input.v1
  @event:model-provider-protocol-projection-requested
  @event-authority:project-model-provider-protocol.v1
  @outcome:model-provider-protocol-route
  @outcome-contract:project-model-provider-protocol-input.v1
  Scenario: Route one admitted provider protocol request to one exact protocol scenario
    Given one admitted provider protocol request with one declared request type
    When the protocol scenario route is resolved
    Then one admitted route carrier retains the complete request and selects exactly one protocol scenario without projecting a provider request or performing an external effect

  @scenario:project-gemini-text-request
  @input:gemini-text-protocol-projection-request
  @input-contract:project-model-provider-protocol-input.v1
  @event:gemini-text-protocol-projection-requested
  @event-authority:project-gemini-text-request.v1
  @outcome:gemini-text-protocol-projection
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Map system user and assistant messages to a Gemini text generateContent request
    Given one text-generation context bound to the Gemini adapter with system, user, and assistant messages and a text response policy
    When the Gemini text protocol is projected
    Then one generateContent body maps system messages to systemInstruction, user messages to the user role, assistant messages to the model role, and declares maxOutputTokens and temperature without a response schema

  @scenario:project-gemini-structured-request
  @input:gemini-structured-protocol-projection-request
  @input-contract:project-model-provider-protocol-input.v1
  @event:gemini-structured-protocol-projection-requested
  @event-authority:project-gemini-structured-request.v1
  @outcome:gemini-structured-protocol-projection
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Map a structured-generation context to a Gemini request with a translated response schema
    Given one structured-generation context bound to the Gemini adapter with an admitted JSON response policy schema
    When the Gemini structured protocol is projected
    Then the body declares application/json response MIME type and a Gemini-compatible responseSchema that keeps only the admitted schema vocabulary and never passes unsupported keywords such as $schema or additionalProperties

  @scenario:project-gemini-endpoint-and-credential-rule
  @input:gemini-endpoint-protocol-projection-request
  @input-contract:project-model-provider-protocol-input.v1
  @event:gemini-endpoint-protocol-projection-requested
  @event-authority:project-gemini-endpoint-and-credential-rule.v1
  @outcome:gemini-endpoint-protocol-projection
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Project the Gemini endpoint and credential-injection rule without credential bytes
    Given one Gemini adapter authority with a default or explicit endpoint and one credential reference
    When the endpoint and credential rule are projected
    Then the HTTPS generateContent endpoint is produced with the concrete model name and one secret-free credential-injection rule that names only the environment reference and header position

  @scenario:project-openai-text-request
  @input:openai-text-protocol-projection-request
  @input-contract:project-model-provider-protocol-input.v1
  @event:openai-text-protocol-projection-requested
  @event-authority:project-openai-text-request.v1
  @outcome:openai-text-protocol-projection
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Map a provider-neutral context to an OpenAI chat-completions text request
    Given one text-generation context bound to the OpenAI adapter with system, user, and assistant messages and a text response policy
    When the OpenAI text protocol is projected
    Then one chat-completions body maps system messages to the system role, user and assistant messages to their canonical roles, and declares model, max tokens, and temperature without a structured output schema

  @scenario:project-openai-structured-request
  @input:openai-structured-protocol-projection-request
  @input-contract:project-model-provider-protocol-input.v1
  @event:openai-structured-protocol-projection-requested
  @event-authority:project-openai-structured-request.v1
  @outcome:openai-structured-protocol-projection
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Map a structured-generation context to an OpenAI request with a translated response schema
    Given one structured-generation context bound to the OpenAI adapter with an admitted JSON response policy schema
    When the OpenAI structured protocol is projected
    Then the body declares JSON response format and a provider-compatible response schema that keeps only the admitted schema vocabulary and never passes unsupported keywords

  @scenario:normalize-gemini-success-testimony
  @input:gemini-success-observation-normalization
  @input-contract:project-model-provider-protocol-input.v1
  @event:gemini-success-testimony-normalization-requested
  @event-authority:normalize-gemini-success-testimony.v1
  @outcome:gemini-success-testimony-normalization
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Normalize a successful Gemini observation into canonical provider testimony
    Given one Gemini observation with a non-blocking finish reason, candidate text, optional usage metadata, and provider request metadata
    When Gemini success testimony is normalized
    Then provider-responded testimony retains candidate text, finish reason, text-part count, usage, provider response metadata, and observation timing without interpreting the content

  @scenario:normalize-gemini-blocking-finish-testimony
  @input:gemini-blocking-finish-normalization
  @input-contract:project-model-provider-protocol-input.v1
  @event:gemini-blocking-finish-normalization-requested
  @event-authority:normalize-gemini-blocking-finish-testimony.v1
  @outcome:gemini-blocking-finish-normalization
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Classify a truncated or filtered Gemini completion as provider rejection
    Given a Gemini observation whose finish reason is SAFETY, RECITATION, PROHIBITED_CONTENT, BLOCKLIST, SPII, MALFORMED_FUNCTION_CALL, or MAX_TOKENS
    When blocking finish testimony is normalized
    Then provider-rejected-request testimony retains the exact finish reason and the blocking message without returning a provider-responded disposition

  @scenario:normalize-provider-http-failure-testimony
  @input:provider-http-failure-normalization
  @input-contract:project-model-provider-protocol-input.v1
  @event:provider-http-failure-normalization-requested
  @event-authority:normalize-provider-http-failure-testimony.v1
  @outcome:provider-http-failure-normalization
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Map one provider HTTP failure into canonical provider disposition testimony
    Given one provider HTTP observation with status and parsed error payload and the provider status classification authority
    When provider HTTP failure testimony is normalized
    Then the exact provider code and message survive as observed testimony and the canonical disposition maps authentication, timeout, availability, and request-rejection statuses without classifying meaning

  @scenario:normalize-provider-transport-testimony
  @input:provider-transport-failure-normalization
  @input-contract:project-model-provider-protocol-input.v1
  @event:provider-transport-failure-normalization-requested
  @event-authority:normalize-provider-transport-testimony.v1
  @outcome:provider-transport-failure-normalization
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Classify a transport timeout or network failure as canonical testimony
    Given one transport failure observation and its abort or timeout classification authority
    When provider transport testimony is normalized
    Then provider-timed-out or provider-unavailable testimony retains the reached transport stage and safe native facts without retrying, fabricating a response, or disclosing secret-bearing diagnostics

  @scenario:normalize-model-response-format
  @input:model-response-format-normalization
  @input-contract:project-model-provider-protocol-input.v1
  @event:model-response-format-normalization-requested
  @event-authority:normalize-model-response-format.v1
  @outcome:model-response-format-normalization
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Confirm the declared response format and structural schema satisfaction
    Given one provider response, one declared text or JSON format, and the optional structural schema
    When response format normalization is performed
    Then text format requires non-empty text, JSON format parses or extracts the structured value and checks the declared type and required properties, and every unsatisfied case yields one exact format finding without echoing the raw payload

  @scenario:reject-unsupported-provider-protocol
  @input:unsupported-provider-protocol-projection
  @input-contract:project-model-provider-protocol-input.v1
  @event:unsupported-provider-protocol-projection-requested
  @event-authority:reject-unsupported-provider-protocol.v1
  @outcome:unsupported-provider-protocol-rejection
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Reject a provider kind or adapter identity absent from adapter authority
    Given a provider-neutral context bound to a provider kind or adapter identity with no admitted declarative adapter authority
    When adapter authority is evaluated
    Then the unsupported provider or adapter is rejected with exact identities and no wire request, observation normalization, native module load, or network effect occurs

  @scenario:reject-unsupported-interaction-mode
  @input:unsupported-interaction-mode-projection
  @input-contract:project-model-provider-protocol-input.v1
  @event:unsupported-interaction-mode-projection-requested
  @event-authority:reject-unsupported-interaction-mode.v1
  @outcome:unsupported-interaction-mode-rejection
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Reject an interaction mode or response format absent from adapter authority
    Given a provider-neutral context whose interaction mode or response format is not declared by the resolved adapter authority
    When adapter capability compatibility is evaluated
    Then the unsupported mode or format is rejected without inventing a mapping, loading a fallback, or performing an external effect

  @scenario:reject-unsupported-schema-vocabulary
  @input:unsupported-schema-vocabulary-projection
  @input-contract:project-model-provider-protocol-input.v1
  @event:unsupported-schema-vocabulary-projection-requested
  @event-authority:reject-unsupported-schema-vocabulary.v1
  @outcome:unsupported-schema-vocabulary-rejection
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Reject a response schema using vocabulary the provider cannot translate
    Given a structured response policy schema declaring vocabulary outside the provider adapter allowlist
    When schema vocabulary is evaluated
    Then the unsupported keyword is named and no projection is emitted that would be silently dropped or mis-translated by the provider

  @scenario:reject-unsupported-adapter-authority
  @input:unsupported-adapter-authority-projection
  @input-contract:project-model-provider-protocol-input.v1
  @event:unsupported-adapter-authority-projection-requested
  @event-authority:reject-unsupported-adapter-authority.v1
  @outcome:unsupported-adapter-authority-rejection
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Reject incomplete stale or credential-bearing adapter authority
    Given an adapter authority that is malformed, missing request-projection or testimony-normalization capability digests, stale, or contains credential material
    When adapter authority admission is evaluated
    Then the invalid authority is rejected with exact pointer-bound findings and no credential value, executable module path, or network reference is reproduced

  @scenario:prove-deterministic-protocol-projection
  @input:deterministic-protocol-projection-observations
  @input-contract:project-model-provider-protocol-input.v1
  @event:deterministic-protocol-projection-proof-requested
  @event-authority:prove-deterministic-protocol-projection.v1
  @outcome:deterministic-protocol-projection-evidence
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Prove equivalent invocation contexts project to identical wire and normalized testimony
    Given two structurally equivalent provider-neutral invocation contexts with the same adapter authority, provider binding, and policy
    When deterministic projection is verified
    Then the wire requests, endpoint facts, and normalized testimony are byte-identical and the proof retains both digests without admitting any provider-specific branching beyond authority

  @scenario:prove-no-http-effect-in-protocol-projection
  @input:protocol-projection-effect-observations
  @input-contract:project-model-provider-protocol-input.v1
  @event:protocol-projection-effect-proof-requested
  @event-authority:prove-no-http-effect-in-protocol-projection.v1
  @outcome:protocol-projection-effect-proof
  @outcome-contract:model-provider-protocol-projection-evidence.v1
  @outcome-terminal
  Scenario: Prove protocol projection performs no HTTP retry substitution or repair
    Given successful and rejected projection and normalization observations with counts of network exchanges, retries, provider selections, model switches, and content repairs
    When protocol projection effect boundaries are evaluated
    Then zero network exchanges, retries, provider selections, model switches, or content repairs occurred and every emitted artifact is pure declarative projection
