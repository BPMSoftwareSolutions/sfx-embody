// GENERATED CAPABILITY PROJECTED TEST. Do not hand-edit.
import test from "node:test";
import assert from "node:assert/strict";
import { conformance, fixtureIds, fixtures, runFixture, valueAt } from "./capability-runtime.generated.mjs";

test("projected conformance requires observed execution", () => {
  const result = conformance();
  assert.equal(result.admissionDisposition, "REJECTED");
  assert.ok(result.findings.some((item) => item.code === "EXECUTION_NOT_OBSERVED"));
});

for (const fixtureId of fixtureIds) {
  const fixture = (fixtures.fixtures ?? []).find((candidate) => candidate.fixtureId === fixtureId);
  test("projected consumer circuit: " + fixtureId, async () => {
    const result = await runFixture(fixtureId);
    assert.equal(result.disposition, fixture.expected.disposition, JSON.stringify(result.outcome ?? null));
    if (fixture.expected.outcomeVariant) assert.equal(result.graphExecution.outcomeVariant, fixture.expected.outcomeVariant);
    assert.deepEqual(result.executions.map((item) => item.scenarioId), fixture.expected.scenarioSequence);
    for (const expectation of fixture.expected.outcomeAssertions ?? []) {
      const actual = valueAt(result.outcome, expectation.path);
      if (expectation.operator === "equals") assert.deepEqual(actual, expectation.value);
      else if (expectation.operator === "contains") assert.ok(actual.includes(expectation.value));
      else if (expectation.operator === "not-contains") assert.ok(!actual.includes(expectation.value));
    }
    const evaluated = conformance(result);
    assert.equal(evaluated.admissionDisposition, "ADMITTED", JSON.stringify(evaluated.findings));
  });
}
