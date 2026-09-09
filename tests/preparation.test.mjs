import test from 'node:test';
import assert from 'node:assert/strict';
import { planArtifacts } from '../src/prepare-database-capability.mjs';

const identity = { scenarioDefinitionDigest: 'revision', pinnedPlatformCommit: 'commit', platformDigest: 'compiler', resolverVersion: 'resolver', artifactDigest: 'body' };
test('preparation artifacts carry every scenario body identity in stable order', () => {
  const plan = () => ({ receipts: [{ plan: { scenarioId: 'root' }, receipt: { ...identity } }, { plan: { scenarioId: 'child' }, receipt: { ...identity } }] });
  const value = plan();
  assert.deepEqual(planArtifacts(value), [
    { scenarioId: 'child', ...identity },
    { scenarioId: 'root', ...identity }
  ]);
  // Database canonical serialization can change object property order.
  const reordered = structuredClone(value);
  reordered.receipts[1].receipt = Object.fromEntries(Object.entries(reordered.receipts[1].receipt).reverse());
  assert.deepEqual(planArtifacts(reordered), planArtifacts(value));
});
