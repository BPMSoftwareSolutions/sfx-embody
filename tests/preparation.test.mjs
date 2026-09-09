import test from 'node:test';
import assert from 'node:assert/strict';
import { planArtifacts, verifyPreparedPlan } from '../src/prepare-database-capability.mjs';

const identity = { scenarioDefinitionDigest: 'revision', pinnedPlatformCommit: 'commit', platformDigest: 'compiler', resolverVersion: 'resolver', artifactDigest: 'body' };
const plan = () => ({ receipts: [{ plan: { scenarioId: 'root' }, receipt: { ...identity } }, { plan: { scenarioId: 'child' }, receipt: { ...identity } }] });
test('execution checks all prepared scenario bodies and their physical platform identity', () => {
  const value = plan(), proof = { status: 'PASSED', artifacts: planArtifacts(value) };
  // Database canonical serialization can change object property order.
  const reordered = structuredClone(proof);
  reordered.artifacts = reordered.artifacts.map(item => Object.fromEntries(Object.entries(item).reverse()));
  assert.doesNotThrow(() => verifyPreparedPlan(value, reordered));
  for (const field of Object.keys(identity)) {
    const changed = plan(); changed.receipts[1].receipt[field] = 'different';
    assert.throws(() => verifyPreparedPlan(changed, proof), /CAPABILITY_PREPARATION_STALE/, field);
  }
  assert.throws(() => verifyPreparedPlan({ receipts: value.receipts.slice(0, 1) }, proof), /CAPABILITY_PREPARATION_STALE/);
});
