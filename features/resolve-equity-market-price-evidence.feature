@capability:resolve-equity-market-price-evidence
@root-scenario:resolve-equity-market-price-evidence
Feature: Resolve provider-neutral equity market-price evidence

  A consumer asks for observed market-price evidence using one canonical input
  and receives one canonical outcome independent of the selected supplier. The
  provider binding, native request, native response, credential realization,
  and supplier testimony remain outside the capability's semantic identity.
  An observed price is attributable provider testimony, not an assertion of
  intrinsic value, investment suitability, or cross-provider equivalence.

  @scenario:resolve-equity-market-price-evidence
  @input:equity-market-price-evidence-request
  @input-contract:equity-market-price-evidence-request.v1
  @event:equity-market-price-evidence-requested
  @event-authority:resolve-equity-market-price-evidence.v1
  @outcome:equity-market-price-evidence
  @outcome-contract:equity-market-price-evidence.v1
  @outcome-terminal
  Scenario: Resolve an equity price observation through an admitted provider binding
    Given a canonical symbol and region, an admitted provider route, an exact native mapping, and bounded exchange authority
    When equity market-price evidence is resolved
    Then the canonical evidence retains symbol, region, currency, price, market time, market state, exchange, source attribution, and provider testimony identity
