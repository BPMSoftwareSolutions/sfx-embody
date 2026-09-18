// Verify the declared provider-authority seam against the live declaration store.
//
//   node scripts/verify-declared-provider-authority.mjs
//
// The migration is applied uncommitted on the read session's own transaction,
// then the extraction Port's declared binding is resolved through the kernel's
// declared data-access read (`provider-authority`) and the provider is invoked
// with that context. The Port's providerAuthorityRef names
// `../provider-authority/scenario-semantic-carrier-extractor.authority.json`,
// which does not exist on disk: the provider can only succeed by consuming the
// declared authority rows. The result is compared with the pure provider
// evaluation so behavior (digest, document, receipt) is identical.
import fs from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import assert from 'node:assert/strict';
import { withDatabaseReadSession } from '../src/database-read-session.mjs';
import { readAuthority } from '../src/read-authority.mjs';

const DATABASE_ROOT = process.env.SIDEFX_DATABASE_ROOT ?? 'C:/lab/sidefx-database';
const SDA_ROOT = process.env.SIDEFX_SDA_ROOT ?? 'C:/lab/repos/scenario-driven-architecture';
const MIGRATION = 'sql/migrations/declare-provider-authority-rows.sql';
const PORT_ID = 'extract-semantic-carrier-graph-provider-port';
const EXPECTED_REF = '../provider-authority/scenario-semantic-carrier-extractor.authority.json';
const CAPABILITY_ID = 'extract-semantic-carrier-graph';

const { declaredAuthorityPortContext } = await import(pathToFileURL(path.join(SDA_ROOT,
  'languages/typescript/runtimes/node/declared-authority-reader.mjs')).href);
const { evaluateScenarioSemanticCarrier } = await import(pathToFileURL(path.join(SDA_ROOT,
  'languages/typescript/runtimes/node/semantic-carrier-validator/index.mjs')).href);
const {
  evaluateScenarioSemanticCarrierExtraction,
  invokeScenarioSemanticCarrierExtraction
} = await import(pathToFileURL(path.join(SDA_ROOT,
  'languages/typescript/runtimes/node/semantic-carrier-extractor-provider.mjs')).href);

const { connect, sql } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/ingest/database.mjs')).href);
const { pinModel } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/query/model-pin.mjs')).href);
const { normalizeSql } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/query/run.mjs')).href);
const { config, stable, hash, digest } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/core.mjs')).href);
const { queryRowLimit } = await config();

let text = await fs.readFile(MIGRATION, 'utf8');
const marker = 'ROLLBACK TRANSACTION;';
const at = text.lastIndexOf(marker);
if (at < 0) throw new Error('NO_ROLLBACK_IN_MIGRATION');
const batches = text.slice(0, at).split(/^\s*GO\s*$/mi).map((batch) => batch.trim()).filter(Boolean);

const fixtureRef = path.join(SDA_ROOT,
  'capabilities/sda-platform/verify-scenario-semantic-carrier-extraction-conformance/fixtures/valid-extractor.carrier.ts');
const source = await fs.readFile(fixtureRef, 'utf8');
const sourceId = 'valid-extractor.carrier.ts';
const validatorReceipt = evaluateScenarioSemanticCarrier({ contractId: 'semantic-carrier-validation-request.v1',
  payload: { source, sourceId } });
const request = { contractId: 'semantic-carrier-extraction-request.v1', payload: { source, sourceId, validatorReceipt } };

const evidence = { migration: MIGRATION, capabilityId: CAPABILITY_ID, portId: PORT_ID,
  providerAuthorityRef: EXPECTED_REF, declaredAuthoritySource: null, locatorOnDisk: false, result: null };

await withDatabaseReadSession({ connect, sql, pinModel, normalizeSql, stable, hash, digest, queryRowLimit },
  async (readQuery, sessionEvidence) => {
    const bundle = await readAuthority(DATABASE_ROOT, { capabilityId: CAPABILITY_ID, target: 'node' },
      { query: readQuery, retainObjects: false, documents: false });
    const binding = bundle.graphSource.interfaceAuthority.portBindings.find((entry) => entry.portId === PORT_ID);
    assert.ok(binding, 'extraction provider Port must be declared');
    assert.equal(binding.platformCapabilityId, 'sda-scenario-semantic-carrier-extraction-port.v1');
    const configuration = binding.configuration;
    assert.equal(configuration.providerAuthorityRef, EXPECTED_REF);
    let locatorOnDisk = false;
    try { await fs.stat(path.resolve(SDA_ROOT, configuration.providerAuthorityRef)); locatorOnDisk = true; } catch { /* the locator is intentionally absent */ }
    evidence.locatorOnDisk = locatorOnDisk;

    const portContext = await declaredAuthorityPortContext({ configuration },
      { readQuery, sdaRoot: SDA_ROOT });
    const declared = portContext.declaredAuthorities?.[configuration.providerAuthorityRef];
    assert.ok(declared, 'the declared read must attach the provider authority');
    const authorityPath = path.join(SDA_ROOT,
      'capabilities/sda-platform/bind-scenario-semantic-carrier-extraction/scenario-semantic-carrier-extractor.authority.json');
    const authorityBytes = await fs.readFile(authorityPath);
    assert.equal('sha256:' + createHash('sha256').update(declared.bytes).digest('hex'), configuration.providerAuthorityDigest);
    assert.deepEqual(declared.bytes, authorityBytes);
    evidence.declaredAuthoritySource = {
      digest: configuration.providerAuthorityDigest,
      byteLength: declared.bytes.length,
      equalToRetainedFile: true
    };

    const invoked = invokeScenarioSemanticCarrierExtraction(configuration, request, portContext);
    const pure = evaluateScenarioSemanticCarrierExtraction(request);
    assert.deepEqual(invoked, pure);
    evidence.result = { disposition: invoked.disposition, graphDigest: invoked.graphDigest, receiptDigest: invoked.receiptDigest };
    evidence.readSession = sessionEvidence;
    evidence.boundPath = 'DECLARED_READ_TO_PROVIDER_CONTEXT';
  }, { beforePin: async (tx) => {
    for (const batch of batches) await new sql.Request(tx).batch(batch);
    evidence.migrationApplied = 'UNCOMMITTED';
  } });

console.log(JSON.stringify(evidence, null, 2));
