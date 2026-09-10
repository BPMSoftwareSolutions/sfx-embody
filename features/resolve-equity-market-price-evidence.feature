@capability:resolve-equity-market-price-evidence
@root-scenario:resolve-equity-market-price-evidence
Feature: Resolve provider-neutral equity market-price evidence

  A consumer supplies a canonical symbol and region and receives one canonical
  outcome independent of the selected supplier. The provider binding, native
  request, credential realization, bounded exchange and supplier testimony are
  declared effect authority executed by the platform, never capability code.
  An observed price is attributable provider testimony, not an assertion of
  intrinsic value, investment suitability, or cross-provider equivalence.

  @scenario:resolve-equity-market-price-evidence
  @input:live-equity-price-request
  @input-contract:live-equity-price-request.v1
  @event:equity-market-price-evidence-requested
  @event-authority:resolve-equity-market-price-evidence.v1
  @outcome:equity-market-price-evidence
  @outcome-contract:equity-market-price-evidence.v1
  @outcome-terminal
  Scenario: Resolve an equity price observation through a declared provider binding
    Given a canonical symbol and region and one admitted provider endpoint authority
    When the credential reference is bound, one bounded exchange is observed, and the native testimony is normalized
    Then the canonical evidence retains symbol, region, currency, price, market time, market state, exchange, source attribution, and provider testimony identity
