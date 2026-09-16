// W5 non-disclosure sweep (docs/vault-manager-agent-strategy.md W5;
// docs/vault-manager-capabilities.md V4).
//
//   node --experimental-vm-modules scripts/verify-credential-non-disclosure.mjs [--receipt-dir DIR]
//
// The harness stores a random sentinel under RAPID_API_KEY, then drives the
// executable vault paths through the real CLI surface and sweeps every channel
// for the sentinel: `invoke --json`, `observe --trace` (stdout and the stderr
// observation stream), the `evidence/` tree, the CLI's local delivery receipts,
// and the estate's durable rows. Every CLI child runs with the three credential
// names removed from its environment, so a resolved credential can only have
// come from the vault. After the sweep the real value is restored from the
// environment and re-proved, and a tampered vault copy is exercised as the
// negative (AES-GCM authentication failure).
//
// The sentinel is a random non-secret; the harness never prints it and the
// receipt contains only dispositions and booleans.
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { executeDatabaseCommand } from '../src/invoke-database-capability.mjs';
import { resolveDeclaredEnvironmentReference } from '../src/credential-vault-realization.mjs';
import { readExecutionDelivery } from '../src/read-execution-delivery.mjs';
import { readAuthority } from '../src/read-authority.mjs';
import { withDatabaseReadSession } from '../src/database-read-session.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const DATABASE_ROOT = process.env.SIDEFX_DATABASE_ROOT ?? 'C:/lab/sidefx-database';
const SDA_ROOT = process.env.SIDEFX_SDA_ROOT ?? 'C:/lab/repos/scenario-driven-architecture';
const REFERENCES = ['RAPID_API_KEY', 'LOC_GEMINI_API_KEY', 'LOC_OPENAI_API_KEY'];
const startedAt = new Date().toISOString();
const receiptDir = path.resolve(root, process.argv.includes('--receipt-dir')
  ? process.argv[process.argv.indexOf('--receipt-dir') + 1]
  : path.join('evidence', 'vault-non-disclosure-' + startedAt.replaceAll(':', '-')));
const sentinel = 'SENTINEL-' + randomUUID();
const report = { receiptType: 'credential-vault-non-disclosure.v1', startedAt, channels: [], tamperedStore: null, restore: null, plaintextAbsent: true };

const note = message => console.log('NON-DISCLOSURE ' + message);
const write = async (name, text) => { await fs.writeFile(path.join(receiptDir, name), text); return text; };

function runCli(command, env) {
  const started = performance.now();
  const result = spawnSync(process.env.ComSpec ?? 'cmd.exe', ['/d', '/s', '/c', `"${command}"`], {
    cwd: root, encoding: 'utf8', windowsHide: true, windowsVerbatimArguments: true,
    timeout: 300_000, maxBuffer: 32 * 1024 * 1024, env
  });
  if (result.error) throw result.error;
  return { command, status: result.status, wallMs: performance.now() - started,
    stdout: result.stdout ?? '', stderr: result.stderr ?? '' };
}

async function main() {
  await fs.mkdir(receiptDir, { recursive: true });
  const workDir = await fs.mkdtemp(path.join(os.tmpdir(), 'sfx-vault-non-disclosure-'));
  const { connect, sql } = await import(new URL('src/ingest/database.mjs', new URL('file:///' + DATABASE_ROOT.replace(/\\/g, '/') + '/')).href);
  const { pinModel } = await import(new URL('src/query/model-pin.mjs', new URL('file:///' + DATABASE_ROOT.replace(/\\/g, '/') + '/')).href);
  const { normalizeSql } = await import(new URL('src/query/run.mjs', new URL('file:///' + DATABASE_ROOT.replace(/\\/g, '/') + '/')).href);
  const { config, stable, hash, digest } = await import(new URL('src/core.mjs', new URL('file:///' + DATABASE_ROOT.replace(/\\/g, '/') + '/')).href);
  const { queryRowLimit } = await config();

  await withDatabaseReadSession({ connect, sql, pinModel, normalizeSql, stable, hash, digest, queryRowLimit },
    async (readQuery, sessionEvidence) => {
      report.readSession = sessionEvidence;
      const context = { databaseRoot: DATABASE_ROOT, sdaRoot: SDA_ROOT, estateRoot: root,
        readAuthority: (rootRef, selection, options) => readAuthority(DATABASE_ROOT, selection, { ...options, query: readQuery }), readQuery };
      context.deliveryTarget = (await readExecutionDelivery(context)).defaultTarget;
      const invoke = (capabilityId, input) => executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1',
        operation: 'invoke', request: { object: 'capability', verb: 'invoke', subject: capabilityId, input } }, context);

      const declaration = await readAuthority(DATABASE_ROOT, { capabilityId: 'resolve-credential', target: 'node' }, { query: readQuery, retainObjects: false });
      const policy = declaration.graphSource.interfaceAuthority.portBindings
        .find(binding => binding.portId === 'resolve-credential-port').configuration.referencePolicy
        .find(entry => entry.referenceName === 'RAPID_API_KEY');

      note('storing the random sentinel under RAPID_API_KEY through the declared capability');
      const sentinelApplyInput = { contractId: 'resolve-credential-request.v1', payload: {
        credentialReference: 'RAPID_API_KEY', invocationIdentity: 'credential-vault-non-disclosure.v1',
        requestingCapabilityId: policy.requestingCapabilityIds[0], endpointAuthorityDigest: policy.endpointAuthorityDigests[0],
        effectScope: policy.effectScopes[0] } };
      const stored = (await invoke('store-credential', { contractId: 'store-credential-request.v1',
        payload: { referenceName: 'RAPID_API_KEY', secret: sentinel } })).outcome.result?.outcome;
      assert.equal(stored?.disposition, 'CREDENTIAL_STORED', 'sentinel store');
      const bound = (await invoke('resolve-credential', sentinelApplyInput)).outcome.result?.outcome;
      assert.equal(bound?.disposition, 'CREDENTIAL_BOUND', 'sentinel apply');

      const sentinelRequestFile = path.join(workDir, 'resolve-request.json');
      await fs.writeFile(sentinelRequestFile, JSON.stringify(sentinelApplyInput, null, 2) + '\n');
      const storeRequestFile = path.join(workDir, 'store-request.json');
      await fs.writeFile(storeRequestFile, JSON.stringify({ contractId: 'store-credential-request.v1',
        payload: { referenceName: 'RAPID_API_KEY', secret: sentinel } }, null, 2) + '\n');

      const childEnv = { ...process.env };
      for (const reference of REFERENCES) delete childEnv[reference];
      note('driving the real CLI surface with the credential names absent from the child environment');
      const invokeSentinel = runCli(`sfx capability invoke resolve-credential --input @${sentinelRequestFile} --json`, childEnv);
      await write('invoke-resolve-credential.stdout.txt', invokeSentinel.stdout);
      await write('invoke-resolve-credential.stderr.txt', invokeSentinel.stderr);
      const observeSentinel = runCli(`sfx capability observe resolve-credential --trace --input @${sentinelRequestFile}`, childEnv);
      await write('observe-resolve-credential.stdout.txt', observeSentinel.stdout);
      await write('observe-resolve-credential.stderr.txt', observeSentinel.stderr);
      const storeSentinel = runCli(`sfx capability invoke store-credential --input @${storeRequestFile} --json`, childEnv);
      await write('invoke-store-credential.stdout.txt', storeSentinel.stdout);
      await write('invoke-store-credential.stderr.txt', storeSentinel.stderr);
      const equitySentinel = runCli('sfx capability invoke resolve-equity-market-price-evidence --input QQQ --json', childEnv);
      await write('invoke-equity-sentinel.stdout.txt', equitySentinel.stdout);
      await write('invoke-equity-sentinel.stderr.txt', equitySentinel.stderr);

      const channel = (name, text, extra = {}) => {
        const absent = !text.includes(sentinel);
        report.channels.push({ channel: name, sentinelAbsent: absent, ...extra });
        if (!absent) report.plaintextAbsent = false;
        note(name + ' sentinel ' + (absent ? 'absent' : 'PRESENT'));
      };
      channel('invoke --json (resolve-credential)', invokeSentinel.stdout + invokeSentinel.stderr,
        { cliStatus: invokeSentinel.status, disposition: /"disposition":\s*"CREDENTIAL_BOUND"/.test(invokeSentinel.stdout) ? 'CREDENTIAL_BOUND' : 'other' });
      channel('observe --trace stdout + observation stream', observeSentinel.stdout + observeSentinel.stderr,
        { cliStatus: observeSentinel.status,
          streamedObservationLines: observeSentinel.stderr.split('\n').filter(line => line.trim().length > 0).length });
      channel('invoke --json (store-credential input channel)', storeSentinel.stdout + storeSentinel.stderr,
        { cliStatus: storeSentinel.status, disposition: /VAULT_SEALED|CREDENTIAL_STORE_REJECTED/.exec(storeSentinel.stdout + storeSentinel.stderr)?.[0] ?? 'other' });
      channel('invoke --json (equity provider exchange with the sentinel)', equitySentinel.stdout + equitySentinel.stderr,
        { cliStatus: equitySentinel.status, disposition: /"disposition":\s*"(EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED|EQUITY_[A-Z_]+|[A-Z_]+)"/.exec(equitySentinel.stdout)?.[1] ?? 'other' });

      // The evidence tree and the CLI's local delivery receipts: every retained
      // capture, bundle and receipt is read and tested; the file that carries
      // the sentinel (if any) is named without echoing its content.
      const sweepTree = async directory => {
        const matches = [];
        let filesScanned = 0;
        const walk = async current => {
          let entries;
          try { entries = await fs.readdir(current, { withFileTypes: true }); } catch { return; }
          for (const entry of entries) {
            const file = path.join(current, entry.name);
            if (entry.isDirectory()) await walk(file);
            else if (entry.isFile() && (await fs.stat(file)).size <= 16 * 1024 * 1024) {
              filesScanned++;
              try { if ((await fs.readFile(file, 'utf8')).includes(sentinel)) matches.push(path.relative(root, file)); }
              catch { /* binary captures are not text channels */ }
            }
          }
        };
        await walk(directory);
        return { matches, filesScanned };
      };
      const evidenceSweep = await sweepTree(path.join(root, 'evidence'));
      channel('evidence/ bundles', evidenceSweep.matches.length > 0 ? sentinel : '',
        { filesScanned: evidenceSweep.filesScanned, filesMatched: evidenceSweep.matches.length,
          matchedFiles: evidenceSweep.matches.map(file => file.replaceAll('\\', '/')) });
      const sidefxHome = process.env.SIDEFX_HOME ?? path.join(os.homedir(), '.sidefx');
      const receiptSweep = await sweepTree(path.join(sidefxHome, 'executions'));
      channel('CLI local delivery receipts', receiptSweep.matches.length > 0 ? sentinel : '',
        { filesScanned: receiptSweep.filesScanned, filesMatched: receiptSweep.matches.length,
          matchedFiles: receiptSweep.matches.map(file => file.replaceAll('\\', '/')) });

      // Durable rows: the estate's content objects.
      const rowSweep = await readQuery(
        "SELECT COUNT(*) AS matches FROM source.content_object co"
        + " WHERE CHARINDEX(JSON_VALUE(@input,'$.sentinel'), CONVERT(nvarchar(max),"
        + " CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)) > 0",
        { input: { sentinel } });
      channel('database rows (source.content_object)', rowSweep.recordsets[0][0].matches > 0 ? sentinel : '',
        { rowsMatched: rowSweep.recordsets[0][0].matches });
      assert.equal(report.plaintextAbsent, true, 'CREDENTIAL_VAULT_SENTINEL_OBSERVED');

      // The tampered-store negative: a copy of the live vault whose ciphertext
      // tag is flipped must fail AES-GCM authentication and return only the
      // non-available disposition.
      note('tampered-store negative (GCM authentication failure)');
      const { createWindowsCredentialStoreRealization } = await import(
        'file:///' + SDA_ROOT.replace(/\\/g, '/') + '/languages/typescript/runtimes/node/windows-credential-store-provider.mjs');
      const { applyCredential } = await import(
        'file:///' + SDA_ROOT.replace(/\\/g, '/') + '/languages/typescript/runtimes/node/secret-vault-provider.mjs');
      const liveLocator = resolveDeclaredEnvironmentReference('%LOCALAPPDATA%\\sfx\\vault');
      const realization = createWindowsCredentialStoreRealization();
      const handle = realization.releaseKeyHandle({ storeLocator: liveLocator });
      assert.equal(handle?.sealed, undefined, 'live keystore handle');
      const liveVault = JSON.parse(await fs.readFile(path.join(liveLocator, 'vault.json'), 'utf8'));
      const entry = liveVault.entries.RAPID_API_KEY;
      const tag = Buffer.from(entry.tag, 'base64');
      tag[tag.length - 1] ^= 0x01;
      entry.tag = tag.toString('base64');
      const tamperedDir = path.join(receiptDir, 'tampered-store');
      await fs.mkdir(tamperedDir, { recursive: true });
      await fs.writeFile(path.join(tamperedDir, 'vault.json'), JSON.stringify(liveVault, null, 2) + '\n');
      const negative = await applyCredential({ operation: 'apply', storeLocator: tamperedDir,
        allowedReferenceNames: ['RAPID_API_KEY'], referencePolicy: [policy] }, sentinelApplyInput, {},
        { secretVaultKeyHandle: handle });
      report.tamperedStore = { disposition: negative.disposition, referenceName: negative.referenceName,
        nonDisclosureVerified: negative.nonDisclosureVerified, sentinelAbsent: !JSON.stringify(negative).includes(sentinel) };
      assert.equal(report.tamperedStore.disposition, 'CREDENTIAL_NOT_AVAILABLE', 'tampered store must fail closed');
      assert.equal(report.tamperedStore.sentinelAbsent, true, 'tampered store must not disclose');
      note('tampered store -> ' + negative.disposition);

      // Restore the real value from the environment and prove it usable. The
      // sentinel must not remain in the vault.
      note('restoring the real RAPID_API_KEY from the environment');
      const realValue = process.env.RAPID_API_KEY;
      assert.ok(typeof realValue === 'string' && realValue.length > 0, 'CREDENTIAL_VAULT_ENVIRONMENT_VALUE_MISSING:RAPID_API_KEY');
      const restored = (await invoke('store-credential', { contractId: 'store-credential-request.v1',
        payload: { referenceName: 'RAPID_API_KEY', secret: realValue } })).outcome.result?.outcome;
      const restoredApply = (await invoke('resolve-credential', sentinelApplyInput)).outcome.result?.outcome;
      report.restore = { storeDisposition: restored?.disposition, applyDisposition: restoredApply?.disposition,
        realization: restoredApply?.realization ?? null };
      assert.equal(restored?.disposition, 'CREDENTIAL_STORED', 'restore store');
      assert.equal(restoredApply?.disposition, 'CREDENTIAL_BOUND', 'restore apply');
      report.restore.sentinelRemoved = !JSON.stringify(report.restore).includes(sentinel);
      note('restored -> ' + restoredApply.disposition);
    });

  report.completedAt = new Date().toISOString();
  const receiptText = JSON.stringify(report, null, 2) + '\n';
  assert.equal(receiptText.includes(sentinel), false, 'CREDENTIAL_VAULT_RECEIPT_CARRIES_SENTINEL');
  await fs.writeFile(path.join(receiptDir, 'non-disclosure.receipt.json'), receiptText);
  // Clean the temporary carrier once the sweep is recorded; the sentinel lives
  // nowhere afterward except the receipt's absence claims.
  await fs.rm(workDir, { recursive: true, force: true });
  note('receipt: ' + path.relative(root, path.join(receiptDir, 'non-disclosure.receipt.json')));
}

main().catch(async error => {
  report.error = { message: error.message };
  try { await fs.mkdir(receiptDir, { recursive: true }); await fs.writeFile(path.join(receiptDir, 'non-disclosure.receipt.json'), JSON.stringify(report, null, 2) + '\n'); } catch { /* diagnostic only */ }
  console.error('NON-DISCLOSURE FAILED:', error.message);
  process.exitCode = 1;
});
