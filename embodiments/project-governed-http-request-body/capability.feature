@capability:project-governed-http-request-body
@root-scenario:project-governed-http-request-body
Feature: Project governed HTTP request bodies

  # Legacy oracles:
  # generic-llm-connector/providers/gemini/invokes-gemini-model.ts :: JSON.stringify(requestBody)
  # generic-llm-connector/providers/openai/invokes-openai-model.ts :: JSON.stringify(requestBody)

  This capability projects one credential-free provider wire-request document
  into canonical compact JSON text for the governed HTTP effect boundary. The
  semantic result retains the exact UTF-8 text encoding authority, media type,
  request-text digest, provider-adapter lineage, and zero-effect testimony.

  Request-body text remains semantic data. Base64 and native byte carriers are
  not introduced into the scenario circuit, and no language kernel receives a
  request-serialization, provider-routing, retry, credential, or HTTP mechanic.
  The governed HTTP effect consumes the exact projected text at its native
  boundary and remains solely responsible for observing transmitted byte
  identity.

  The projection must use admitted declarative `json-stringify`, `sha256`,
  `format`, `object`, `path`, and `literal` operations only. It must not contain
  executable source, invoke an external effect, select a provider, inject a
  credential, retry, repair, or claim admission of remote testimony.

  @scenario:project-governed-http-request-body
  @input:governed-http-request-body-projection-request
  @input-contract:project-governed-http-request-body-input.v1
  @event:governed-http-request-body-projection-requested
  @event-authority:project-governed-http-request-body.v1
  @outcome:governed-http-request-body-projection
  @outcome-contract:governed-http-request-body-projection-evidence.v1
  @outcome-terminal
  Scenario: Project one provider wire request into exact canonical JSON text
    Given one admitted credential-free provider wire-request document, provider adapter identity, invocation identity, and projection authority identity
    When the governed HTTP request body is projected
    Then canonical compact JSON text, UTF-8 encoding authority, application/json media type, exact text digest, preserved identities, and zero network exchanges are returned without base64, executable mechanics, credential material, retry, repair, provider substitution, or remote-testimony claims
