@capability:observe-governed-http-exchange
@root-scenario:observe-governed-http-exchange
Feature: Observe governed HTTP exchanges

  # Legacy oracles:
  # generic-llm-connector/providers/gemini/invokes-gemini-model.ts
  # generic-llm-connector/providers/openai/invokes-openai-model.ts

  This capability performs exactly one authorized HTTP exchange from one
  projected credential-free protocol request, endpoint policy, opaque
  credential binding, timeout, cancellation scope, response bound, and
  invocation identity. Its objective covers successful and non-success HTTP
  responses, denied endpoints, invalid credential bindings, timeouts,
  cancellation, DNS/TLS/socket failures, oversized responses, secret redaction,
  and the prohibition on retry or provider substitution.

  HTTP observations are untrusted transport testimony. This capability does
  not interpret model content or map provider dispositions.

  The projected capability binds its root event directly to
  sda-governed-http-exchange-port.v1. No authority transformation may
  simulate a response, status, exchange count, timing fact, or transport
  failure.

  @scenario:observe-governed-http-exchange
  @input:governed-http-exchange-request
  @input-contract:observe-governed-http-exchange-input.v1
  @event:governed-http-exchange-requested
  @event-authority:observe-governed-http-exchange.v1
  @outcome:governed-http-exchange-observation
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Observe one successful authorized HTTP exchange
    Given one projected request, allowed HTTPS endpoint, valid opaque credential binding, positive timeout, response bound, and invocation identity
    When the admitted transport performs the single exchange
    Then exact status, policy-allowed headers, bounded response bytes, timing, credential-free request evidence, hashes, and effect lineage are returned as untrusted testimony

  @scenario:observe-non-success-http-response
  @input:non-success-governed-http-exchange
  @input-contract:observe-governed-http-exchange-input.v1
  @event:non-success-governed-http-exchange-requested
  @event-authority:observe-non-success-http-response.v1
  @outcome:non-success-http-response-observation
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Retain a complete non-success HTTP response as testimony
    Given one authorized exchange whose remote endpoint returns a non-success status with bounded response bytes
    When the transport observation is completed
    Then the exact status, safe headers, bounded bytes, hashes, timing, and lineage are returned without classifying provider meaning, throwing away testimony, retrying, or substituting an endpoint

  @scenario:reject-http-endpoint-outside-authority
  @input:unauthorized-http-endpoint-request
  @input-contract:observe-governed-http-exchange-input.v1
  @event:unauthorized-http-endpoint-exchange-requested
  @event-authority:reject-http-endpoint-outside-authority.v1
  @outcome:unauthorized-http-endpoint-rejection
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Reject a malformed forbidden or credential-bearing endpoint
    Given a request whose endpoint uses a forbidden scheme, lies outside the host allowlist, embeds credentials, redirects outside authority, or differs from the resolved provider binding
    When endpoint authority is evaluated
    Then the exchange is rejected before DNS or socket activity and safe endpoint findings are returned without following redirects or exposing secret material

  @scenario:reject-invalid-http-credential-binding
  @input:invalid-http-credential-binding-request
  @input-contract:observe-governed-http-exchange-input.v1
  @event:invalid-http-credential-binding-exchange-requested
  @event-authority:reject-invalid-http-credential-binding.v1
  @outcome:invalid-http-credential-binding-rejection
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Reject absent expired consumed or mismatched credential bindings
    Given an otherwise valid request with no opaque credential binding or one outside its invocation, provider, endpoint, effect, or lifetime scope
    When exchange prerequisites are evaluated
    Then no DNS, TLS, socket, or request transmission occurs and an attributable secret-free credential-binding rejection is returned

  @scenario:observe-governed-http-timeout
  @input:timed-out-governed-http-exchange
  @input-contract:observe-governed-http-exchange-input.v1
  @event:timed-governed-http-exchange-requested
  @event-authority:observe-governed-http-timeout.v1
  @outcome:governed-http-timeout-observation
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Stop one exchange at the admitted timeout
    Given one active authorized exchange that does not complete within its positive timeout authority
    When the timeout boundary is reached
    Then one timeout observation with elapsed timing and effect lineage is returned without another exchange, endpoint change, response invention, or secret disclosure

  @scenario:cancel-governed-http-exchange
  @input:cancelled-governed-http-exchange
  @input-contract:observe-governed-http-exchange-input.v1
  @event:governed-http-exchange-cancellation-requested
  @event-authority:cancel-governed-http-exchange.v1
  @outcome:governed-http-cancellation-observation
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Cancel before transmission or during one active exchange
    Given valid cancellation authority observed before transmission or while the authorized exchange is active
    When cancellation is applied
    Then cancellation testimony and any effects already reached are retained without starting or restarting a request, inventing response bytes, or changing endpoint authority

  @scenario:observe-governed-http-transport-failure
  @input:failed-governed-http-transport
  @input-contract:observe-governed-http-exchange-input.v1
  @event:failed-governed-http-transport-requested
  @event-authority:observe-governed-http-transport-failure.v1
  @outcome:governed-http-transport-failure-observation
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Retain DNS TLS socket and network failures as attributable testimony
    Given one authorized exchange whose DNS resolution, TLS negotiation, socket connection, transmission, or response read fails
    When the transport boundary reports failure
    Then the reached transport stage, safe native facts, timing, and lineage are returned without retry, response fabrication, provider classification, or secret-bearing diagnostic content

  @scenario:reject-oversized-http-response
  @input:oversized-governed-http-response
  @input-contract:observe-governed-http-exchange-input.v1
  @event:oversized-governed-http-response-observed
  @event-authority:reject-oversized-http-response.v1
  @outcome:oversized-http-response-rejection
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Enforce the admitted response byte bound
    Given one authorized exchange whose response exceeds the declared maximum bytes
    When bounded response collection is performed
    Then collection stops at the governed boundary and an oversized-response observation with safe hashes and lineage is returned without persisting or forwarding excess bytes

  @scenario:prove-http-secret-redaction
  @input:governed-http-redaction-observations
  @input-contract:observe-governed-http-exchange-input.v1
  @event:http-secret-redaction-proof-requested
  @event-authority:prove-http-secret-redaction.v1
  @outcome:http-secret-redaction-evidence
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Exclude secret-bearing headers URLs and diagnostics from evidence
    Given successful and failed exchange observations with credential injection, redirects, headers, errors, logs, hashes, and durable evidence
    When HTTP secret redaction is verified
    Then only credential-free request facts and policy-allowed response facts remain or an exact leakage finding is returned without reproducing the secret in proof

  @scenario:prove-single-http-exchange-authority
  @input:governed-http-exchange-count-observations
  @input-contract:observe-governed-http-exchange-input.v1
  @event:single-http-exchange-authority-proof-requested
  @event-authority:prove-single-http-exchange-authority.v1
  @outcome:single-http-exchange-authority-evidence
  @outcome-contract:governed-http-exchange-evidence.v1
  @outcome-terminal
  Scenario: Prove the transport performs no retry redirect escape or substitution
    Given observations from success, non-success, timeout, cancellation, transport failure, and oversized-response paths
    When transport effect count and destination lineage are evaluated
    Then at most one authorized destination exchange occurred with no hidden retry, out-of-policy redirect, alternate endpoint, or provider substitution
