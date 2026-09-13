@capability:read-estate-query
@root-scenario:read-estate-query
Feature: Read one declared query from the selected capability estate

  The estate's readers — read-authority, the list/find surface, and the embodiment
  read — each run SQL against the selected generation. That read is not
  declared-query-evaluation: declared-query-evaluation orients an already-admitted
  JSON document and never touches SQL. This capability owns the database read.

  The query is declared, addressed by identity, and executed under the reader
  boundary against the selected generation. The capability returns the result set
  with its provenance: the selected generation, the query identity, the row limit
  and truncation state, and a result digest over a sorted multiset, so row order
  without an ORDER BY carries no meaning.

  The read never coerces input, never substitutes a default estate, and never
  reports a truncated result as complete. An unknown or malformed query is
  rejected; a result that reached the row limit is returned as truncated.

  @scenario:read-estate-query
  @input:estate-query-request
  @input-contract:estate-query-request.v1
  @event:read-estate-query
  @event-authority:read-estate-query.v1
  @outcome:estate-query-result
  @outcome-contract:estate-query-result.v1
  @outcome-variants:READ_QUERY_COMPLETE|READ_QUERY_TRUNCATED|ESTATE_QUERY_UNKNOWN|ESTATE_QUERY_REJECTED
  @outcome-terminal
  Scenario: Read one declared query from the selected estate
    Given one query identity and its declared input
    When the query is executed against the selected generation under the reader boundary
    Then the result set and its provenance are returned, or the exact rejection is returned

  @scenario:execute-declared-estate-query
  @input:estate-query-request
  @input-contract:estate-query-request.v1
  @event:execute-declared-estate-query
  @event-authority:execute-declared-estate-query.v1
  @outcome:estate-query-result
  @outcome-contract:estate-query-result.v1
  Scenario: Execute the declared query under the reader boundary
    Given one declared query and one admitted input document
    When the query is executed
    Then every result set is returned with its row count and the row limit that was applied

  @scenario:carry-query-provenance
  @input:estate-query-result
  @input-contract:estate-query-result.v1
  @event:carry-query-provenance
  @event-authority:carry-query-provenance.v1
  @outcome:estate-query-result
  @outcome-contract:estate-query-result.v1
  Scenario: Bind the result to the exact generation that produced it
    Given one executed query
    When the provenance is bound
    Then the selected generation, the query identity, the input digest, the result digest and the truncation state bind to the result
    And a result whose generation cannot be established returns ESTATE_QUERY_PROVENANCE_ABSENT

  @scenario:reject-unknown-or-malformed-query
  @input:estate-query-request
  @input-contract:estate-query-request.v1
  @event:reject-unknown-or-malformed-estate-query
  @event-authority:reject-unknown-or-malformed-estate-query.v1
  @outcome:estate-query-result
  @outcome-contract:estate-query-result.v1
  @outcome-terminal
  Scenario: Reject a query that is not declared or whose input is malformed
    Given an unknown query identity or an input that fails the declared query input contract
    When the query is attempted
    Then ESTATE_QUERY_UNKNOWN or ESTATE_QUERY_REJECTED is returned and no default query or default estate is substituted
