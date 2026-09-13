@capability:project-consumer-execution-embodiment-v2
@root-scenario:project-consumer-execution-embodiment-v2
Feature: Project Consumer Execution Embodiment V2

  A maintainer operating the deterministic conveyor executes multi-target consumer
  execution embodiment plans deterministically across the supported runtime
  platforms. The capability consumes one admitted projection context — the
  projected plan, the registered projection authorities, and the eight-part
  fixture authority — derives a target-neutral graph, renders platform-specific
  candidates and observes identical fixture partitions across every target.

  The context is produced by project-consumer-execution-embodiment-plan; this
  composition no longer begins from an assumed input. It produces candidates only.
  Acceptance and promotion remain the authority of the deterministic conveyor.

  The root scenario composes the four supporting scenarios in declared order. Each
  consumes the immutable outcome of the preceding scenario, appends its evidence
  and lineage, and stops at the exact first non-success without reinterpreting the
  disposition.

  @scenario:project-consumer-execution-embodiment-v2
  @input:consumer-execution-embodiment-projection-context
  @input-contract:consumer-execution-embodiment-projection-context.v1
  @event:project-consumer-execution-embodiment-v2
  @event-authority:project-consumer-execution-embodiment-v2.v1
  @outcome:projected-consumer-execution-embodiment-candidate
  @outcome-contract:projected-consumer-execution-embodiment-candidate.v1
  @outcome-terminal
  Scenario: Root Consumer Execution Embodiment V2
    Given An admitted projection context carrying the plan, the registered projection authorities and the fixture authority
    When The maintainer triggers the embodiment execution pipeline through the deterministic conveyor
    Then The system completes derivation, rendering, and fixture observation, producing unified artifacts, digests, and lineage

  @scenario:admit-consumer-execution-embodiment-projection-context
  @input:consumer-execution-embodiment-projection-context
  @input-contract:consumer-execution-embodiment-projection-context.v1
  @event:admit-consumer-execution-embodiment-projection-context
  @event-authority:admit-consumer-execution-embodiment-projection-context.v1
  @outcome:admitted-consumer-execution-embodiment-projection-context
  @outcome-contract:admitted-consumer-execution-embodiment-projection-context.v1
  Scenario: Admit Execution Context
    Given An admitted projection context containing the plan, execute-composed-scenario-authority, eight-part fixture authority, and registered Node, C#, and Python projection authorities.
    When The conveyor admits the context and validates all required authorities, operations, and policy definitions.
    Then The execution context is successfully admitted or an explicit error is returned for missing authority or invalid parameters.

  @scenario:derive-consumer-execution-embodiment-projection-graph
  @input:admitted-consumer-execution-embodiment-projection-context
  @input-contract:admitted-consumer-execution-embodiment-projection-context.v1
  @event:derive-consumer-execution-embodiment-projection-graph
  @event-authority:derive-consumer-execution-embodiment-projection-graph.v1
  @outcome:consumer-execution-embodiment-projection-graph
  @outcome-contract:consumer-execution-embodiment-projection-graph.v1
  Scenario: Derive Target Neutral Graph
    Given An admitted execution context with valid invoke-port, invoke-scenario, carrier, intermediate-contract, lineage, first-failure, and recursion policies.
    When The system transforms the execution plan into an intermediate, target-agnostic structural model.
    Then A single target-neutral projection graph is established or an explicit error is returned for incomplete projection.

  @scenario:render-consumer-execution-embodiments
  @input:consumer-execution-embodiment-projection-graph
  @input-contract:consumer-execution-embodiment-projection-graph.v1
  @event:render-consumer-execution-embodiments
  @event-authority:render-consumer-execution-embodiments.v1
  @outcome:projected-consumer-execution-embodiment-bundle
  @outcome-contract:projected-consumer-execution-embodiment-bundle.v1
  Scenario: Render Embodiment Candidates
    Given A derived target-neutral projection graph and registered Node, C#, and Python projection authorities.
    When The system renders target-specific projected embodiment candidates for each supported platform target.
    Then Projected-only target candidates are generated or an explicit error is returned for unsupported targets.

  @scenario:observe-consumer-execution-embodiment-fixtures
  @input:projected-consumer-execution-embodiment-bundle
  @input-contract:projected-consumer-execution-embodiment-bundle.v1
  @event:observe-consumer-execution-embodiment-fixtures
  @event-authority:observe-consumer-execution-embodiment-fixtures.v1
  @outcome:projected-consumer-execution-embodiment-candidate
  @outcome-contract:projected-consumer-execution-embodiment-candidate.v1
  Scenario: Observe Target Fixtures
    Given Rendered target candidate embodiments and the eight-part fixture authority.
    When Identical fixture partitions are executed across all rendered target candidates.
    Then Execution artifacts, digests, observations, exact dispositions, and accumulated lineage are returned while surfacing any fixture failures or cross-target mismatches.
