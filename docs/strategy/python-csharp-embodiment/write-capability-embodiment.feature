@capability:write-capability-embodiment
@root-scenario:write-capability-embodiment
Feature: Write one planned embodiment as a governed materialization

  A plan authorizes the crossing from declaration to artifact. This capability
  writes the planned embodiment beneath an authorized root and returns a
  materialization record. It re-derives the plan from the same authority and the
  same bindings, and refuses if what it would write diverges from the plan it was
  given.

  The write is target-neutral: the target selects the profile, and the plan names
  the artifacts and their providers. Because the plan carries the profile and the
  provider bindings, the digests for a target are established by the plan and
  verified after the write; a plan-form write may legitimately carry different
  digests than a per-port write, and the record states the digests it produced.

  The capability writes only beneath the authorized root. A divergent re-plan, a
  digest mismatch, or an unauthorized path fails closed and leaves no partial
  claim of materialization.

  @scenario:write-capability-embodiment
  @input:capability-embodiment-plan
  @input-contract:capability-embodiment-plan.v1
  @event:write-capability-embodiment
  @event-authority:write-capability-embodiment.v1
  @outcome:capability-embodiment-materialization
  @outcome-contract:capability-embodiment-materialization.v1
  @outcome-variants:EMBODIMENT_WRITTEN|EMBODIMENT_WRITE_DIVERGED|EMBODIMENT_WRITE_DIGEST_MISMATCH|EMBODIMENT_WRITE_REJECTED
  @outcome-terminal
  Scenario: Write one planned embodiment beneath the authorized root
    Given one embodiment plan and one authorized output root
    When the plan is re-derived and its artifacts are written
    Then the materialization record names the root, plan digest, artifact digest, file count and written files, or the exact divergence, mismatch or rejection is returned

  @scenario:verify-written-artifact
  @input:capability-embodiment-materialization
  @input-contract:capability-embodiment-materialization.v1
  @event:verify-written-embodiment-artifact
  @event-authority:verify-written-embodiment-artifact.v1
  @outcome:embodiment-artifact-verification
  @outcome-contract:embodiment-artifact-verification.v1
  Scenario: Verify the written bytes reproduce the plan
    Given one materialization record and the artifact on disk
    When every written file digest and the artifact digest are recomputed
    Then verification reports matched digests and file count or EXACT_BYTE_DIVERGENCE, and a divergent artifact is never reported as materialized
