@capability:project-capability-circuit
@root-scenario:project-capability-circuit
Feature: Project the declared circuit of one capability

  A capability declares its scenarios, operations, ports and their ordering. The
  circuit surface renders that structure as a diagram. Today two hand-authored
  diagram builders render two graphs. What the declaration already carries is the
  graph; the layout and the diagram are projections of it.

  The capability projects the declared nodes and edges — nothing more. It draws no
  edge the declaration does not state, infers no ordering that is not declared,
  and holds a graph with an unresolved endpoint rather than presenting a plausible
  shape. The projection binds the generation digest and reproduces byte-identically
  for a frozen generation.

  @scenario:project-capability-circuit
  @input:capability-circuit-projection-request
  @input-contract:capability-circuit-projection-request.v1
  @event:project-capability-circuit
  @event-authority:project-capability-circuit.v1
  @outcome:capability-circuit-projection
  @outcome-contract:capability-circuit-projection.v1
  @outcome-variants:CIRCUIT_PROJECTED|CIRCUIT_HELD
  @outcome-terminal
  Scenario: Project the declared circuit of one capability
    Given one capability identity and its declared scenarios, operations and ports
    When the circuit is projected
    Then the declared nodes and edges are rendered and bound to the generation digest, or the unresolved endpoint is held

  @scenario:project-declared-edges-only
  @input:capability-circuit-projection-request
  @input-contract:capability-circuit-projection-request.v1
  @event:project-declared-circuit-edges
  @event-authority:project-declared-circuit-edges.v1
  @outcome:capability-circuit-projection
  @outcome-contract:capability-circuit-projection.v1
  Scenario: Draw only the declared nodes and edges
    Given one declared circuit
    When the edges are projected
    Then every drawn edge corresponds to a declared relationship
    And a diagram requiring an inferred edge returns CIRCUIT_EDGE_UNDECLARED

  @scenario:replay-circuit-projection
  @input:capability-circuit-projection-request
  @input-contract:capability-circuit-projection-request.v1
  @event:replay-capability-circuit-projection
  @event-authority:replay-capability-circuit-projection.v1
  @outcome:capability-circuit-projection
  @outcome-contract:capability-circuit-projection.v1
  Scenario: Reproduce the projection byte-identically for one frozen generation
    Given one frozen generation
    When the circuit is projected twice
    Then both projections are byte-identical
    And a divergent replay returns CIRCUIT_PROJECTION_REPLAY_DIVERGED
