@capability:bind-external-credential-reference
@root-scenario:bind-external-credential-reference
Feature: Bind external credential references

  # Legacy oracle: generic-llm-connector/src/shared/runtime-ports.ts :: environmentCredentials

  This capability authorizes one named external credential reference for one
  invocation and exposes only an opaque effect-scoped binding. Its execution
  objective covers successful binding, absent or empty credentials,
  unauthorized or mismatched references, stale or replayed bindings, embedded
  secrets, and non-disclosure across every observable channel.

  Credential bytes remain inside the admitted platform effect provider. They
  never enter scenario carriers, logs, hashes, receipts, MCP content, retrieval
  indexes, model prompts, or durable artifacts.

  The projected capability binds its root event directly to
  sda-external-credential-reference-binding-port.v1. No authority
  transformation may synthesize a credential binding or opaque handle.

  @scenario:bind-external-credential-reference
  @input:external-credential-binding-request
  @input-contract:bind-external-credential-reference-input.v1
  @event:external-credential-reference-binding-requested
  @event-authority:bind-external-credential-reference.v1
  @outcome:external-credential-binding
  @outcome-contract:external-credential-binding-evidence.v1
  @outcome-terminal
  Scenario: Bind one authorized credential reference for one invocation
    Given one admitted credential reference name, matching invocation identity, authorized credential effect provider, and available non-empty credential
    When the external credential reference is bound
    Then an opaque invocation-scoped binding and secret-free availability lineage are returned without exposing the credential value

  @scenario:hold-missing-or-empty-external-credential
  @input:missing-or-empty-external-credential-binding-request
  @input-contract:bind-external-credential-reference-input.v1
  @event:missing-or-empty-external-credential-binding-requested
  @event-authority:hold-missing-or-empty-external-credential.v1
  @outcome:external-credential-not-available
  @outcome-contract:external-credential-binding-evidence.v1
  @outcome-terminal
  Scenario: Hold a missing or empty credential without external effects
    Given one authorized credential reference whose external value is absent or empty
    When the reference is bound
    Then CREDENTIAL_NOT_AVAILABLE and secret-free reference lineage are returned without creating a binding, reading alternatives, or authorizing an HTTP exchange

  @scenario:reject-unauthorized-external-credential-reference
  @input:unauthorized-external-credential-binding-request
  @input-contract:bind-external-credential-reference-input.v1
  @event:unauthorized-external-credential-binding-requested
  @event-authority:reject-unauthorized-external-credential-reference.v1
  @outcome:unauthorized-external-credential-reference
  @outcome-contract:external-credential-binding-evidence.v1
  @outcome-terminal
  Scenario: Reject a credential name outside admitted authority
    Given a request naming an undeclared credential source, variable, secret-store path, tenant, or scope
    When credential-reference authorization is evaluated
    Then the unauthorized reference is rejected without attempting to read it, enumerating nearby credentials, or exposing policy-private names

  @scenario:reject-mismatched-credential-invocation-identity
  @input:mismatched-credential-invocation-binding-request
  @input-contract:bind-external-credential-reference-input.v1
  @event:mismatched-credential-invocation-binding-requested
  @event-authority:reject-mismatched-credential-invocation-identity.v1
  @outcome:mismatched-credential-invocation-rejection
  @outcome-contract:external-credential-binding-evidence.v1
  @outcome-terminal
  Scenario: Reject a credential reference bound for another invocation
    Given an admitted credential reference and an invocation identity that differs from the request, provider binding, or effect authorization
    When invocation scope is evaluated
    Then no opaque binding is returned and the exact identity mismatch is retained without reading credential bytes

  @scenario:reject-stale-or-replayed-credential-binding
  @input:stale-or-replayed-external-credential-binding
  @input-contract:bind-external-credential-reference-input.v1
  @event:stale-or-replayed-credential-binding-use-requested
  @event-authority:reject-stale-or-replayed-credential-binding.v1
  @outcome:stale-or-replayed-credential-binding-rejection
  @outcome-contract:external-credential-binding-evidence.v1
  @outcome-terminal
  Scenario: Reject expired consumed or replayed opaque bindings
    Given an opaque credential binding that is expired, already consumed, belongs to another effect, or no longer matches authority
    When the binding is presented for use
    Then use is rejected without refreshing, copying, persisting, or re-reading credential material implicitly

  @scenario:reject-embedded-credential-material
  @input:credential-bearing-semantic-carrier
  @input-contract:bind-external-credential-reference-input.v1
  @event:credential-bearing-semantic-carrier-observed
  @event-authority:reject-embedded-credential-material.v1
  @outcome:embedded-credential-material-rejection
  @outcome-contract:external-credential-binding-evidence.v1
  @outcome-terminal
  Scenario: Reject credential values crossing the semantic boundary
    Given a scenario carrier containing an API key, token, authorization header, secret-bearing URL, or other credential value
    When the credential boundary is evaluated
    Then the carrier is rejected without echoing, hashing, logging, indexing, persisting, or forwarding the suspected secret

  @scenario:prove-external-credential-non-disclosure
  @input:external-credential-binding-observations
  @input-contract:bind-external-credential-reference-input.v1
  @event:external-credential-non-disclosure-proof-requested
  @event-authority:prove-external-credential-non-disclosure.v1
  @outcome:external-credential-non-disclosure-evidence
  @outcome-contract:external-credential-binding-evidence.v1
  @outcome-terminal
  Scenario: Prove credential values are absent from every observable artifact
    Given successful, unavailable, unauthorized, mismatched, stale, and rejected credential-binding observations with logs, carriers, receipts, MCP content, retrieval units, prompts, and durable artifacts
    When credential non-disclosure is evaluated
    Then every observable surface contains only admitted reference and opaque-binding facts or an exact leakage finding and no secret value is reproduced in evidence
