import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import { executeEstateCapability } from '../src/invoke-database-capability.mjs';
import { executeConsumerPlan } from '../src/resolvers/node/consumer-execution-provider.mjs';
import { loadConsumerPlan } from '../src/load-consumer-plan.mjs';
import { readFixtureConsumerPlan } from './verify-consumer-fixtures.mjs';
import { readWorkspaceConfig } from '../src/read-workspace-config.mjs';

const config = await readWorkspaceConfig(process.argv[2]);
const context = { ...config, estateRoot: path.resolve('.') };
const { satisfies, valueAt } = await import(pathToFileURL(path.join(config.sdaRoot, 'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')));
const cases = [];
for (const request of config.cases) {
  const selection = JSON.parse(await fs.readFile(request.selectionFile, 'utf8'));
  // Materialize the declared plan through the governed writer so the disk side
  // is the declared generation; the memory side is the same declaration read
  // directly. The parity check needs no pre-staged legacy body.
  const materialization = await executeEstateCapability({ capabilityId: 'materialize-capability-embodiment' }, selection, context);
  if (materialization.contractId !== 'capability-embodiment-materialization.v1') throw new Error('EMBODIMENT_MATERIALIZATION_FAILED');
  const declaration = await executeEstateCapability({ capabilityId: 'read-capability-authority' }, selection, context);
  const read = await readFixtureConsumerPlan(declaration, context);
  const bytes = new Map(read.files.map(file => [file.relativePath, Buffer.from(file.content)]));
  const memory = await loadConsumerPlan(read.result, read.bindingPath, name => bytes.get(name));
  const disk = await loadConsumerPlan(read.result, read.bindingPath, name => fs.readFile(path.resolve(context.estateRoot, name)));
  const fixtures = memory.fixtureAuthority.fixtures;
  let outcomeAssertions = 0, kernelObservations = 0;
  const run = async (runtime, fixture) => {
    const input = structuredClone(fixture.input);
    const actual = await executeConsumerPlan({}, { ...runtime, scenarioInput: input }, { ...context, rootExecutionId: fixture.fixtureId });
    assert.deepEqual(input, fixture.input);
    return actual;
  };
  for (const fixture of fixtures) {
    const actual = await run(memory, fixture), expected = await run(disk, fixture);
    assert.deepEqual(actual, expected, fixture.fixtureId);
    assert.equal(actual.result.disposition, fixture.expected.disposition === 'terminated' ? 'completed' : fixture.expected.disposition);
    for (const assertion of fixture.expected.outcomeAssertions) {
      assert(satisfies(valueAt(actual.result.outcome, assertion.path), assertion));
      outcomeAssertions++;
    }
    kernelObservations += actual.result.cellTestimony.length;
  }
  const invalid = { fixtureId: 'invalid-input', input: null };
  const rejected = await run(memory, invalid);
  assert.deepEqual(rejected, await run(disk, invalid));
  assert.equal(rejected.result.disposition, 'rejected');
  cases.push({ capabilityId: declaration.capabilityId, fixtures: fixtures.length, outcomeAssertions, kernelObservations,
    identicalDeclaredFiles: read.files.length, planDigest: read.result.planDigest, artifactDigest: read.result.artifactDigest,
    invalidInputParity: true, disposition: 'PASSED' });
}
console.log(JSON.stringify({ disposition: 'PASSED',
  scope: 'Database-selected consumer plans: every declared file digest and complete native disk/memory execution results, including cell and edge testimony, across the configured fixtures.', cases }, null, 2));
