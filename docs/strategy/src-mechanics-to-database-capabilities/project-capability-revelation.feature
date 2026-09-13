@capability:project-capability-revelation
@root-scenario:project-capability-revelation
Feature: Project one capability revelation from its declared authority

  Revelation projects what a capability declares — identity, meaning, scenarios,
  contracts, providers, lineage, authority — into views a person can read. The
  narration surface today projects meaning to text and markdown through separate
  hand-authored formatters. What the capability declares is the authority; the
  format, and the composition of each view, are declared projections.

  Every view is projected from the selected generation, binds that generation's
  digest, and states only what the declaration states. A view that would need
  meaning the declaration does not carry is held with the exact missing
  declaration rather than filled in by the formatter. A formatter never invents
  prose, never summarizes away a finding, and never becomes an authority for what
  a capability means.

  Adding a format, or a view, is declaring a projection — never writing a new
  formatter path.

  @scenario:project-capability-revelation
  @input:capability-revelation-request
  @input-contract:capability-revelation-request.v1
  @event:project-capability-revelation
  @event-authority:project-capability-revelation.v1
  @outcome:capability-revelation
  @outcome-contract:capability-revelation.v1
  @outcome-variants:REVELATION_COMPLETE|REVELATION_HELD
  @outcome-terminal
  Scenario: Project one revelation from the selected generation
    Given one capability identity and the declared projection set
    When the revelation is projected
    Then every declared view is projected and bound to the generation digest, or the exact missing declaration is held

  @scenario:project-declared-format
  @input:capability-revelation-request
  @input-contract:capability-revelation-request.v1
  @event:project-declared-revelation-format
  @event-authority:project-declared-revelation-format.v1
  @outcome:capability-revelation-view
  @outcome-contract:capability-revelation-view.v1
  Scenario: Project the declared format for a view
    Given one revelation view and its declared format
    When the view is projected
    Then the view is rendered in the declared format
    And a requested format that no projection declares returns REVELATION_FORMAT_UNDECLARED

  @scenario:hold-view-without-declared-meaning
  @input:capability-revelation-request
  @input-contract:capability-revelation-request.v1
  @event:hold-revelation-view-without-declared-meaning
  @event-authority:hold-revelation-view-without-declared-meaning.v1
  @outcome:capability-revelation-view
  @outcome-contract:capability-revelation-view.v1
  Scenario: Hold a view whose declaration is absent
    Given a declared view whose backing declaration is not present in the selected generation
    When the view is projected
    Then the view is held naming the absent declaration and no narrative is invented to fill it
