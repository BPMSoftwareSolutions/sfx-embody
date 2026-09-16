import test from 'node:test';
import assert from 'node:assert/strict';
import { executeDatabaseCommand, executeEstateCapability } from '../src/invoke-database-capability.mjs';
import { CREDENTIAL_STORE_REALIZATION_MECHANIC_ID } from '../src/credential-vault-realization.mjs';

const KEY_BYTES = Array.from(Buffer.from('0123456789abcdef0123456789abcdef', 'utf8'));
const KEY_SENTINELS = [Buffer.from(KEY_BYTES).toString('base64'), Buffer.from(KEY_BYTES).toString('hex'), '0123456789abcdef'];

const dataModule = source => 'data:text/javascript,' + encodeURIComponent(source);

const fixtureRealizationModule = dataModule([
  'export function createFixtureRealization(options = {}) {',
  '  globalThis.__fixtureRealizationCreations = (globalThis.__fixtureRealizationCreations ?? 0) + 1;',
  '  return {',
  "    realizationId: options.realizationId ?? 'fixture-credential-store',",
  '    releaseKeyHandle() { return { vaultId: "fixture-vault", keyVersion: 1, keyBytes: Uint8Array.from(' + JSON.stringify(KEY_BYTES) + ') }; }',
  '  };',
  '}',
  "export const sealedRealization = () => ({ realizationId: 'fixture-sealed-store', releaseKeyHandle: () => ({ sealed: true }) });",
  "export const notARealization = () => ({ realizationId: 'fixture-not-a-store' });"
].join('\n'));

// The kernel host stand-in: it consumes exactly the seam the SDA effect factory
// consumes (`context.effectContextOverrides.credentialStoreRealization`), calls
// the realization's release boundary, and returns only non-secret evidence.
const fixturePortModule = dataModule([
  'export const invoke = async (configuration, state, context) => {',
  '  const overrides = context?.effectContextOverrides ?? {};',
  '  const realization = overrides.credentialStoreRealization;',
  '  let released = null;',
  '  try { released = typeof realization?.releaseKeyHandle === "function" ? realization.releaseKeyHandle({ storeLocator: configuration?.storeLocator }) : null; } catch { released = null; }',
  '  const sealed = !realization || !released || released.sealed === true || !released.keyBytes;',
  '  return { disposition: "completed", outcome: {',
  '    realizationId: realization?.realizationId ?? "unavailable",',
  '    sealed,',
  '    releasedKeyBytes: sealed ? 0 : released.keyBytes.length,',
  '    credentialReaderPresent: typeof overrides.credentialReader === "function",',
  '    vaultCredentialReaderPresent: typeof overrides.vaultCredentialReader === "function",',
  '    secretVaultKeyHandlePresent: overrides.secretVaultKeyHandle !== undefined',
  '  } };',
  '};'
].join('\n'));

function bindingConfiguration({ declaration = true, profile = 'fixture-credential-store-provider.v1',
  module: moduleRef = fixtureRealizationModule, exportName = 'createFixtureRealization', exportAbsent = false } = {}) {
  const configuration = { estateProvider: { module: fixturePortModule, export: 'invoke' } };
  if (declaration) {
    configuration.overlayBindings = [{ mechanicId: CREDENTIAL_STORE_REALIZATION_MECHANIC_ID, providerProfileId: profile,
      providerProfileDigest: 'sha256:' + '0'.repeat(64), implementationRef: 'fixture-credential-store-realization' }];
    configuration.providers = exportAbsent ? [] : [{ providerProfileId: profile, module: moduleRef, export: exportName, factory: true }];
  }
  return configuration;
}

function bundleFor(configuration) {
  return {
    authority: { recordsets: [[{ scenario_id: 'fixture-scenario' }]] },
    closure: { recordsets: [[]] },
    graphSource: { capabilityId: 'fixture',
      executionAuthorities: [{ owningScenarioId: 'fixture-scenario',
        operations: [{ kind: 'invoke-port', portId: 'fixture-port' }] }],
      interfaceAuthority: { portBindings: [{ portId: 'fixture-port', configuration }] } }
  };
}

function estateContext(configuration, overrides = {}) {
  return { sdaRoot: process.cwd(), readAuthority: async () => bundleFor(configuration), ...overrides };
}

const identity = { snapshotId: 'snapshot', projectionDigest: 'projection', viewDefinitionDigest: 'views', truncated: false };

// The full loader path, mirroring the estate fixture loader: the declared
// executor Port carries the realization binding, and the subject graph is a
// fixture. No live database and no OS keystore are involved.
function commandContext(configuration) {
  const observations = [];
  const executor = { capabilityId: 'run-declared-graph',
    executionAuthorities: [{ owningScenarioId: 'executor', operations: [{ kind: 'invoke-port', portId: 'port' }] }],
    interfaceAuthority: { portBindings: [{ portId: 'port', configuration }] } };
  const subject = { capabilityId: 'example', scenarios: [], executionAuthorities: [] };
  return { databaseRoot: 'unused', sdaRoot: process.cwd(), observations,
    onObservation: observation => { observations.push(observation); },
    readQuery: async () => ({ ...identity, recordsets: [
      [{ provider_id: 'delivery', configuration: JSON.stringify({ capabilityId: 'run-declared-graph', requestExpression: {}, resultExpression: {} }) }],
      [{ default_target: 'node' }]] }),
    readAuthority: async (_, selection) => ({ selection,
      authority: { ...identity, recordsets: [[{ scenario_id: selection.capabilityId === 'run-declared-graph' ? 'executor' : 'root' }]] },
      closure: { recordsets: [[]] },
      graphSource: structuredClone(selection.capabilityId === 'run-declared-graph' ? executor : subject) }) };
}

test('the declared provider profile resolves the realization into the kernel host overrides', async () => {
  const context = estateContext(bindingConfiguration());
  const result = await executeEstateCapability({ capabilityId: 'fixture' }, { input: null }, context);
  assert.equal(result.outcome.realizationId, 'fixture-credential-store');
  assert.equal(result.outcome.sealed, false);
  assert.equal(result.outcome.releasedKeyBytes, 32);
  assert.equal(context.effectContextOverrides, undefined);
});

test('the resolution is cached for the invocation and never written onto the context', async () => {
  globalThis.__fixtureRealizationCreations = 0;
  const context = estateContext(bindingConfiguration());
  await executeEstateCapability({ capabilityId: 'fixture' }, { input: null }, context);
  await executeEstateCapability({ capabilityId: 'fixture' }, { input: null }, context);
  assert.equal(globalThis.__fixtureRealizationCreations, 1);
  assert.equal(context.effectContextOverrides, undefined);
  assert.equal(Object.keys(context).includes('credentialStoreRealization'), false);
});

test('an undeclared realization injects nothing and never falls back to environment credentials', async () => {
  const result = await executeEstateCapability({ capabilityId: 'fixture' }, { input: null },
    estateContext(bindingConfiguration({ declaration: false })));
  assert.equal(result.outcome.realizationId, 'unavailable');
  assert.equal(result.outcome.sealed, true);
  assert.equal(result.outcome.credentialReaderPresent, false);
  assert.equal(result.outcome.vaultCredentialReaderPresent, false);
  assert.equal(result.outcome.secretVaultKeyHandlePresent, false);
});

test('a broken or absent declared realization fails closed with the declared profile identity', async () => {
  for (const configuration of [
    bindingConfiguration({ exportAbsent: true }),
    bindingConfiguration({ module: './missing-credential-store-provider.mjs' }),
    bindingConfiguration({ exportName: 'missingExport' }),
    bindingConfiguration({ exportName: 'notARealization' })
  ]) {
    const result = await executeEstateCapability({ capabilityId: 'fixture' }, { input: null }, estateContext(configuration));
    assert.equal(result.outcome.realizationId, 'fixture-credential-store-provider.v1');
    assert.equal(result.outcome.sealed, true);
    assert.equal(result.outcome.releasedKeyBytes, 0);
  }
});

test('a sealed realization refuses without releasing key bytes', async () => {
  const result = await executeEstateCapability({ capabilityId: 'fixture' }, { input: null },
    estateContext(bindingConfiguration({ exportName: 'sealedRealization' })));
  assert.equal(result.outcome.realizationId, 'fixture-sealed-store');
  assert.equal(result.outcome.sealed, true);
  assert.equal(result.outcome.releasedKeyBytes, 0);
});

test('an explicit boot-supplied realization takes precedence over the declared profile', async () => {
  const bootRealization = { realizationId: 'boot-supplied-store', releaseKeyHandle: () => ({ sealed: true }) };
  const result = await executeEstateCapability({ capabilityId: 'fixture' }, { input: null },
    estateContext(bindingConfiguration(), { effectContextOverrides: { credentialStoreRealization: bootRealization } }));
  assert.equal(result.outcome.realizationId, 'boot-supplied-store');
  assert.equal(result.outcome.sealed, true);
});

test('no key bytes reach results or the observation stream', async () => {
  const config = commandContext(bindingConfiguration());
  const result = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'invoke',
    request: { object: 'capability', verb: 'invoke', subject: 'example', input: { value: 1 } } }, config);
  assert.equal(result.outcome.result.outcome.realizationId, 'fixture-credential-store');
  assert.equal(result.outcome.result.outcome.releasedKeyBytes, 32);
  assert.equal(config.effectContextOverrides, undefined);
  const serialized = JSON.stringify(result) + JSON.stringify(config.observations);
  for (const sentinel of KEY_SENTINELS) assert.equal(serialized.includes(sentinel), false, sentinel);
});
