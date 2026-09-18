import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { randomUUID } from 'node:crypto';
import { executeDatabaseCommand } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/command-carrier.mjs';
import { executeDeclaredCapability } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/declared-operation-carrier.mjs';
import { CREDENTIAL_STORE_REALIZATION_MECHANIC_ID, resolveCredentialVaultLocators,
  resolveCredentialVaultLocatorsInGraphSource, resolveDeclaredEnvironmentReference } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/credential-realization.mjs';
import { withDatabaseReadSession } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/database-read-session.mjs';
import { readAuthority } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/authority-read.mjs';
import { readExecutionDelivery } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/delivery-read.mjs';

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

function fixtureMechanic(binding) {
  const provider = binding?.configuration?.estateProvider;
  if (!provider || typeof provider.module !== 'string' || typeof provider.export !== 'string') return null;
  return import(provider.module).then(module => typeof module[provider.export] === 'function' ? module[provider.export] : null);
}

function estateContext(configuration, overrides = {}) {
  return { sdaRoot: process.cwd(), resolveMechanic: fixtureMechanic,
    readAuthority: async () => bundleFor(configuration), ...overrides };
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
    resolveMechanic: fixtureMechanic,
    readQuery: async () => ({ ...identity, recordsets: [
      [{ provider_id: 'delivery', configuration: JSON.stringify({ capabilityId: 'run-declared-graph', requestExpression: {}, resultExpression: {} }) }],
      [{ default_target: 'node' }]] }),
    readAuthority: async selection => ({ selection,
      authority: { ...identity, recordsets: [[{ scenario_id: selection.capabilityId === 'run-declared-graph' ? 'executor' : 'root' }]] },
      closure: { recordsets: [[]] },
      graphSource: structuredClone(selection.capabilityId === 'run-declared-graph' ? executor : subject) }) };
}

test('the declared provider profile resolves the realization into the kernel host overrides', async () => {
  const context = estateContext(bindingConfiguration());
  const result = await executeDeclaredCapability({ capabilityId: 'fixture' }, { input: null }, context);
  assert.equal(result.outcome.realizationId, 'fixture-credential-store');
  assert.equal(result.outcome.sealed, false);
  assert.equal(result.outcome.releasedKeyBytes, 32);
  assert.equal(context.effectContextOverrides, undefined);
});

test('the resolution is cached for the invocation and never written onto the context', async () => {
  globalThis.__fixtureRealizationCreations = 0;
  const context = estateContext(bindingConfiguration());
  await executeDeclaredCapability({ capabilityId: 'fixture' }, { input: null }, context);
  await executeDeclaredCapability({ capabilityId: 'fixture' }, { input: null }, context);
  assert.equal(globalThis.__fixtureRealizationCreations, 1);
  assert.equal(context.effectContextOverrides, undefined);
  assert.equal(Object.keys(context).includes('credentialStoreRealization'), false);
});

test('an undeclared realization injects nothing and never falls back to environment credentials', async () => {
  const result = await executeDeclaredCapability({ capabilityId: 'fixture' }, { input: null },
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
    const result = await executeDeclaredCapability({ capabilityId: 'fixture' }, { input: null }, estateContext(configuration));
    assert.equal(result.outcome.realizationId, 'fixture-credential-store-provider.v1');
    assert.equal(result.outcome.sealed, true);
    assert.equal(result.outcome.releasedKeyBytes, 0);
  }
});

test('a sealed realization refuses without releasing key bytes', async () => {
  const result = await executeDeclaredCapability({ capabilityId: 'fixture' }, { input: null },
    estateContext(bindingConfiguration({ exportName: 'sealedRealization' })));
  assert.equal(result.outcome.realizationId, 'fixture-sealed-store');
  assert.equal(result.outcome.sealed, true);
  assert.equal(result.outcome.releasedKeyBytes, 0);
});

test('an explicit boot-supplied realization takes precedence over the declared profile', async () => {
  const bootRealization = { realizationId: 'boot-supplied-store', releaseKeyHandle: () => ({ sealed: true }) };
  const result = await executeDeclaredCapability({ capabilityId: 'fixture' }, { input: null },
    estateContext(bindingConfiguration(), { effectContextOverrides: { credentialStoreRealization: bootRealization } }));
  assert.equal(result.outcome.realizationId, 'boot-supplied-store');
  assert.equal(result.outcome.sealed, true);
});

test('declared vault locators resolve from the host environment before the provider sees them', () => {
  process.env.SFX_TEST_CREDENTIAL_VAULT_ROOT = 'C:\\vault-root';
  try {
    const configuration = {
      operation: 'store',
      storeLocator: '%SFX_TEST_CREDENTIAL_VAULT_ROOT%\\sfx\\vault',
      unrelated: '%SFX_TEST_CREDENTIAL_VAULT_ROOT%',
      credentialAuthorities: [
        { referenceName: 'RAPID_API_KEY', source: 'vault', storeLocator: '%SFX_TEST_CREDENTIAL_VAULT_ROOT%\\sfx\\vault' },
        { referenceName: 'LOC_OPENAI_API_KEY', source: 'environment' }
      ]
    };
    const resolved = resolveCredentialVaultLocators(configuration);
    assert.equal(resolved.storeLocator, 'C:\\vault-root\\sfx\\vault');
    assert.equal(resolved.unrelated, '%SFX_TEST_CREDENTIAL_VAULT_ROOT%');
    assert.equal(resolved.credentialAuthorities[0].storeLocator, 'C:\\vault-root\\sfx\\vault');
    assert.equal(resolved.credentialAuthorities[1], configuration.credentialAuthorities[1]);
    assert.equal(configuration.storeLocator, '%SFX_TEST_CREDENTIAL_VAULT_ROOT%\\sfx\\vault', 'the declaration is not mutated');
  } finally { delete process.env.SFX_TEST_CREDENTIAL_VAULT_ROOT; }
});

test('an unresolved environment reference is left verbatim; the provider fails closed', () => {
  delete process.env.SFX_TEST_MISSING_VAULT_ROOT;
  assert.equal(resolveDeclaredEnvironmentReference('%SFX_TEST_MISSING_VAULT_ROOT%\\sfx'), '%SFX_TEST_MISSING_VAULT_ROOT%\\sfx');
  assert.equal(resolveDeclaredEnvironmentReference('C:\\fixed\\sfx'), 'C:\\fixed\\sfx');
});

test('the graph source hand-off expands vault locators on its Port bindings only', () => {
  process.env.SFX_TEST_CREDENTIAL_VAULT_ROOT = 'D:\\host-vault';
  try {
    const graphSource = { capabilityId: 'fixture',
      interfaceAuthority: { portBindings: [
        { portId: 'vault-port', configuration: { operation: 'apply', storeLocator: '%SFX_TEST_CREDENTIAL_VAULT_ROOT%\\sfx\\vault' } },
        { portId: 'other-port', configuration: { location: '%SFX_TEST_CREDENTIAL_VAULT_ROOT%\\other' } }
      ] } };
    const resolved = resolveCredentialVaultLocatorsInGraphSource(graphSource);
    assert.equal(resolved.interfaceAuthority.portBindings[0].configuration.storeLocator, 'D:\\host-vault\\sfx\\vault');
    assert.equal(resolved.interfaceAuthority.portBindings[1].configuration.location, '%SFX_TEST_CREDENTIAL_VAULT_ROOT%\\other');
    assert.equal(graphSource.interfaceAuthority.portBindings[0].configuration.storeLocator, '%SFX_TEST_CREDENTIAL_VAULT_ROOT%\\sfx\\vault');
    assert.equal(resolveCredentialVaultLocatorsInGraphSource({ capabilityId: 'no-authority' }).interfaceAuthority, undefined);
  } finally { delete process.env.SFX_TEST_CREDENTIAL_VAULT_ROOT; }
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

// The retired harness (scripts/verify-credential-non-disclosure.mjs, W1.3) is
// replaced by the declared read sql/migrations/declare-read-credential-non-disclosure.sql:
// the physical collection stays in the harness layer, while every absence claim
// and the verdict are declared SQL. This case exercises the installed read
// against the live estate; it is the retirement's covering test and runs only
// when the database integration flag is set.
const databaseIntegration = process.env.SFX_DATABASE_INTEGRATION === '1';

async function databaseRuntime() {
  const file = new URL('../config/database-runtime.json', import.meta.url);
  const runtime = JSON.parse(await fs.readFile(file, 'utf8'));
  const databaseRoot = path.resolve(path.dirname(fileURLToPath(file)), runtime.databaseRoot);
  const sdaRoot = path.resolve(path.dirname(fileURLToPath(file)), runtime.sdaRoot);
  const core = await import(pathToFileURL(path.join(databaseRoot, 'src/core.mjs')).href);
  const database = await import(pathToFileURL(path.join(databaseRoot, 'src/ingest/database.mjs')).href);
  const { normalizeSql } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/run.mjs')).href);
  const { pinModel } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/model-pin.mjs')).href);
  const { connectionEnvironmentVariable, queryRowLimit } = await core.config();
  process.env[connectionEnvironmentVariable] = database.connectionString(connectionEnvironmentVariable);
  return { databaseRoot, sdaRoot, connect: database.connect, sql: database.sql,
    normalizeSql, pinModel, ...core, queryRowLimit };
}

test('the installed non-disclosure read reproduces the sweep verdict from live observations', { skip: !databaseIntegration }, async () => {
  const runtime = await databaseRuntime();
  const sentinel = 'SENTINEL-TEST-' + randomUUID();
  const pad = 'x'.repeat(4200);
  const sweep = (channels, tamperedStore = { disposition: 'CREDENTIAL_NOT_AVAILABLE', referenceName: 'RAPID_API_KEY',
    nonDisclosureVerified: true, sentinelAbsent: true }) => ({ contractId: 'credential-non-disclosure-request.v1',
    payload: { sentinel, channels,
      fileScans: [{ channel: 'evidence/ bundles', filesScanned: 0, filesMatched: 0, matchedFiles: [] }],
      tamperedStore,
      restore: { storeDisposition: 'CREDENTIAL_STORED', applyDisposition: 'CREDENTIAL_BOUND',
        realization: 'windows-credential-store-provider' } } });
  await withDatabaseReadSession(runtime, async (readQuery, sessionEvidence) => {
    assert.ok(sessionEvidence);
    const context = { databaseRoot: runtime.databaseRoot, sdaRoot: runtime.sdaRoot, estateRoot: path.resolve('.'),
      readQuery,
      readAuthority: (selection, options) => readAuthority(selection, { ...options, query: readQuery }) };
    context.deliveryTarget = (await readExecutionDelivery(context)).defaultTarget;
    const read = async input => {
      const execution = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'invoke',
        request: { object: 'capability', verb: 'invoke', subject: 'read-credential-non-disclosure', input } }, context);
      const result = execution.outcome?.result;
      assert.equal(result?.disposition, 'completed', JSON.stringify(execution.outcome?.result ?? execution.outcome));
      return result.outcome;
    };
    const cleanChannels = [
      { channel: 'invoke --json (resolve-credential)', observed: JSON.stringify({ disposition: 'CREDENTIAL_BOUND' }),
        cliStatus: 0, disposition: 'CREDENTIAL_BOUND' },
      // The sentinel must be searched across the full capture, beyond the
      // 4000-character boundary a truncated reader would silently stop at.
      { channel: 'observe --trace stdout + observation stream', observed: pad + ' no sentinel in this capture',
        cliStatus: 0, streamedObservationLines: 14 }
    ];
    const green = await read(sweep(cleanChannels));
    assert.equal(green.verdict, 'NON_DISCLOSURE_VERIFIED');
    assert.equal(green.plaintextAbsent, true);
    assert.deepEqual(green.channels.map(channel => channel.sentinelAbsent), [true, true]);
    assert.equal(green.durableRows.sentinelAbsent, true);
    assert.equal(green.durableRows.rowsMatched, 0);
    assert.equal(green.tamperedStore.disposition, 'CREDENTIAL_NOT_AVAILABLE');
    assert.equal(green.tamperedStore.nonDisclosureVerified, true);
    assert.equal(JSON.stringify(green).includes(sentinel), false, 'the receipt never carries the sentinel');

    const leaked = await read(sweep([{ channel: 'invoke --json (resolve-credential)', observed: pad + sentinel, cliStatus: 0 }]));
    assert.equal(leaked.verdict, 'NON_DISCLOSURE_VIOLATION');
    assert.equal(leaked.plaintextAbsent, false);
    assert.equal(leaked.channels[0].sentinelAbsent, false);
    assert.equal(JSON.stringify(leaked).includes(sentinel), false, 'the violation receipt never carries the sentinel');

    const boundTampered = await read(sweep(cleanChannels, { disposition: 'CREDENTIAL_BOUND', referenceName: 'RAPID_API_KEY',
      nonDisclosureVerified: false, sentinelAbsent: true }));
    assert.equal(boundTampered.verdict, 'NON_DISCLOSURE_VIOLATION');
    assert.equal(boundTampered.tamperedStore.disposition, 'CREDENTIAL_BOUND');
  });
});
