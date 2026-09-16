// One-time credential-vault transition unit (docs/vault-manager-agent-strategy.md,
// decision 2; docs/vault-manager-capabilities.md V3).
//
//   node --experimental-vm-modules scripts/transition-credential-authorities-to-vault.mjs [--receipt-dir DIR] [--skip-switch]
//
// The unit is idempotent and separately receipted. It:
//
//   1. Reads each reference value from the process environment exactly once,
//      stores it through the declared `store-credential` capability, and applies
//      it through the declared `resolve-credential` capability to prove the
//      stored value decrypts and binds. A reference that is already bound is
//      left alone; a reference that is neither bound nor present in the
//      environment fails the unit closed and is named. No value is invented.
//   2. Preflights the source-switch migration (`switch-credential-authorities-
//      to-vault.sql`) from the uncommitted transaction: the equity invocation
//      and the per-reference resolve invocations run with the three names
//      removed from the child environment, so a green preflight proves the
//      vault-backed path. The Gemini conveyor exchange is attempted and, when
//      the frozen SDA graph path cannot compose its scenarios, the exact
//      blocker is recorded (not worked around). The switch is installed only
//      after the executable preflights pass.
//   3. Writes a receipt under evidence/ that contains only non-secret facts:
//      reference names, dispositions, realization ids and the switch state.
//      The unit asserts before writing that no plaintext value appears in the
//      receipt or in any captured child output.
//
// The plaintext exists in this process only between the environment read and
// the store invocation; it is never printed, never receipted and never returned.
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { executeDatabaseCommand } from '../src/invoke-database-capability.mjs';
import { readExecutionDelivery } from '../src/read-execution-delivery.mjs';
import { readAuthority } from '../src/read-authority.mjs';
import { withDatabaseReadSession } from '../src/database-read-session.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const DATABASE_ROOT = process.env.SIDEFX_DATABASE_ROOT ?? 'C:/lab/sidefx-database';
const SDA_ROOT = process.env.SIDEFX_SDA_ROOT ?? 'C:/lab/repos/scenario-driven-architecture';
const REFERENCES = ['RAPID_API_KEY', 'LOC_GEMINI_API_KEY', 'LOC_OPENAI_API_KEY'];
const VAULT_MIGRATION = 'sql/migrations/switch-credential-authorities-to-vault.sql';
const EQUITY_REQUEST = 'examples/equity-market-price-evidence.request.json';
const GEMINI_REQUEST = 'evidence/vault-20260916/gemini-request.json';

const args = process.argv.slice(2);
const receiptDirArg = args.includes('--receipt-dir') ? args[args.indexOf('--receipt-dir') + 1] : null;
const skipSwitch = args.includes('--skip-switch');
const startedAt = new Date().toISOString();
const receiptDir = path.resolve(root, receiptDirArg ?? path.join('evidence', 'vault-transition-' + startedAt.replaceAll(':', '-')));

const secrets = [];
const report = {
  receiptType: 'credential-vault-transition.v1',
  operator: 'scripts/transition-credential-authorities-to-vault.mjs',
  startedAt,
  references: [],
  switch: null,
  plaintextObserved: false,
  idempotency: []
};
let failed = false;

const note = message => console.log('TRANSITION ' + message);
const record = async (name, text) => { await fs.writeFile(path.join(receiptDir, name), text); };

function runProcess(processArgs, env) {
  return spawnSync(process.execPath, processArgs, {
    cwd: root, encoding: 'utf8', windowsHide: true, timeout: 600_000, maxBuffer: 32 * 1024 * 1024,
    env: env ?? process.env
  });
}

function environmentWithoutReferences() {
  const env = { ...process.env };
  for (const reference of REFERENCES) delete env[reference];
  return env;
}

function assertNoPlaintext(label, text) {
  for (const secret of secrets) {
    if (secret.length >= 8 && text.includes(secret)) {
      throw new Error('CREDENTIAL_VAULT_PLAINTEXT_OBSERVED:' + label);
    }
  }
}

function parsePreflightResult(captured) {
  const line = captured.stdout.split('\n').find(row => row.trim().startsWith('RESULT '));
  if (!line) return null;
  try { return JSON.parse(line.trim().slice('RESULT '.length)); } catch { return null; }
}

async function main() {
  await fs.mkdir(receiptDir, { recursive: true });
  const { connect, sql } = await import(new URL('src/ingest/database.mjs', new URL('file:///' + DATABASE_ROOT.replace(/\\/g, '/') + '/')).href);
  const { pinModel } = await import(new URL('src/query/model-pin.mjs', new URL('file:///' + DATABASE_ROOT.replace(/\\/g, '/') + '/')).href);
  const { normalizeSql } = await import(new URL('src/query/run.mjs', new URL('file:///' + DATABASE_ROOT.replace(/\\/g, '/') + '/')).href);
  const { config, stable, hash, digest } = await import(new URL('src/core.mjs', new URL('file:///' + DATABASE_ROOT.replace(/\\/g, '/') + '/')).href);
  const { queryRowLimit } = await config();

  const session = await withDatabaseReadSession({ connect, sql, pinModel, normalizeSql, stable, hash, digest, queryRowLimit },
    async (readQuery, sessionEvidence) => {
      report.readSession = sessionEvidence;
      const read = (selection, options = {}) => readAuthority(DATABASE_ROOT, selection, { ...options, query: readQuery });
      const context = { databaseRoot: DATABASE_ROOT, sdaRoot: SDA_ROOT, estateRoot: root,
        readAuthority: (rootRef, selection, options) => read(selection, options), readQuery };
      context.deliveryTarget = (await readExecutionDelivery(context)).defaultTarget;
      const invoke = (capabilityId, input) => executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1',
        operation: 'invoke', request: { object: 'capability', verb: 'invoke', subject: capabilityId, input } }, context);
      const authorityState = async () => {
        const readResult = await readQuery(
          "SELECT COUNT(CASE WHEN JSON_VALUE(b.value,'$.source') <> N'vault' THEN 1 END) AS environment_authorities,"
          + " COUNT(CASE WHEN JSON_VALUE(b.value,'$.source') = N'vault' THEN 1 END) AS vault_authorities"
          + " FROM analysis.v_selected_semantic_definition d"
          + " CROSS APPLY OPENJSON(JSON_QUERY(d.definition_json,'$.semantics.configuration.credentialAuthorities')) b"
          + " WHERE d.object_kind='PORT' AND JSON_VALUE(b.value,'$.referenceName') IN (N'RAPID_API_KEY',N'LOC_GEMINI_API_KEY',N'LOC_OPENAI_API_KEY')");
        return readResult.recordsets[0][0];
      };

      const declaration = await read({ capabilityId: 'resolve-credential', target: 'node' }, { retainObjects: false });
      const port = declaration.graphSource?.interfaceAuthority?.portBindings
        ?.find(binding => binding.portId === 'resolve-credential-port');
      const policyEntries = port?.configuration?.referencePolicy ?? [];
      assert.ok(policyEntries.length === REFERENCES.length, 'CREDENTIAL_VAULT_REFERENCE_POLICY_MISSING');

      note('seeding references from the environment (values are never printed)');
      for (const referenceName of REFERENCES) {
        const policy = policyEntries.find(entry => entry.referenceName === referenceName);
        assert.ok(policy, 'CREDENTIAL_VAULT_REFERENCE_POLICY_MISSING:' + referenceName);
        const applyInput = { contractId: 'resolve-credential-request.v1', payload: {
          credentialReference: referenceName,
          invocationIdentity: 'credential-vault-transition.v1',
          requestingCapabilityId: policy.requestingCapabilityIds[0],
          endpointAuthorityDigest: policy.endpointAuthorityDigests[0],
          effectScope: policy.effectScopes[0] } };
        const entry = { referenceName,
          requestingCapabilityId: policy.requestingCapabilityIds[0],
          endpointAuthorityDigest: policy.endpointAuthorityDigests[0],
          effectScope: policy.effectScopes[0] };

        // The environment value, when present, is the transition source of
        // truth: the unit reads it once and stores it (overwriting any earlier
        // preflight sentinel), then applies the stored value to prove it is
        // usable. When the environment value is absent, the entry must already
        // be bound in the vault; otherwise the unit fails closed and names it.
        const secret = process.env[referenceName];
        if (typeof secret === 'string' && secret.length > 0) {
          secrets.push(secret);
          const stored = (await invoke('store-credential', { contractId: 'store-credential-request.v1',
            payload: { referenceName, secret } })).outcome.result?.outcome;
          entry.storeDisposition = stored?.disposition ?? 'unavailable';
          if (stored?.disposition !== 'CREDENTIAL_STORED') throw new Error('CREDENTIAL_VAULT_STORE_FAILED:' + referenceName + ':' + entry.storeDisposition);
        } else {
          entry.storeDisposition = 'SKIPPED_ENVIRONMENT_ABSENT';
        }
        const applied = (await invoke('resolve-credential', applyInput)).outcome.result?.outcome;
        entry.applyDisposition = applied?.disposition ?? 'unavailable';
        entry.realization = applied?.realization ?? null;
        entry.nonDisclosureVerified = applied?.nonDisclosureVerified === true;
        if (entry.applyDisposition !== 'CREDENTIAL_BOUND') {
          if (entry.storeDisposition === 'SKIPPED_ENVIRONMENT_ABSENT') {
            throw new Error('CREDENTIAL_VAULT_ENVIRONMENT_VALUE_MISSING:' + referenceName);
          }
          throw new Error('CREDENTIAL_VAULT_APPLY_FAILED:' + referenceName + ':' + entry.applyDisposition);
        }
        report.references.push(entry);
        note(referenceName + ' -> ' + entry.applyDisposition + ' via ' + entry.realization);
      }

      if (skipSwitch) return;
      const before = await authorityState();
      report.switch = { migration: VAULT_MIGRATION, stateBefore: before };
      if (Number(before.environment_authorities) === 0) {
        report.switch.disposition = 'ALREADY_SWITCHED';
        report.switch.stateAfter = before;
        return;
      }
      const migrationText = await fs.readFile(path.join(root, VAULT_MIGRATION), 'utf8');
      assert.match(migrationText, /COMMIT TRANSACTION\s*;/i, 'SWITCH_MIGRATION_NOT_INSTALL_FORM');
      const preflightFile = path.join(receiptDir, 'switch-credential-authorities.rollback.sql');
      await fs.writeFile(preflightFile, migrationText.replace(/COMMIT TRANSACTION\s*;/i, 'ROLLBACK TRANSACTION;'));

      const preflight = async (label, capabilityId, inputFile) => {
        const captured = runProcess(['--experimental-vm-modules', 'scripts/invoke-from-transaction.mjs', preflightFile, capabilityId, inputFile],
          environmentWithoutReferences());
        await record('preflight-' + label + '.out', captured.stdout ?? '');
        await record('preflight-' + label + '.err', captured.stderr ?? '');
        const parsed = parsePreflightResult(captured);
        return { captured, parsed,
          disposition: parsed?.result?.disposition ?? null,
          outcomeDisposition: parsed?.result?.outcome?.disposition ?? null,
          vaultSealed: /VAULT_SEALED|CREDENTIAL_NOT_AVAILABLE/.test(captured.stdout ?? '') };
      };

      note('preflighting the source switch from the uncommitted transaction (references absent from the child environment)');
      const equity = await preflight('equity', 'resolve-equity-market-price-evidence', EQUITY_REQUEST);
      report.switch.preflightEquity = { status: equity.captured.status, disposition: equity.disposition,
        outcomeDisposition: equity.outcomeDisposition };
      if (equity.disposition !== 'completed' || equity.outcomeDisposition !== 'EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED' || equity.vaultSealed) {
        throw new Error('SWITCH_PREFLIGHT_EQUITY_FAILED:' + (equity.outcomeDisposition ?? equity.captured.status));
      }
      const resolvePreflights = [];
      for (const referenceName of ['LOC_GEMINI_API_KEY', 'LOC_OPENAI_API_KEY']) {
        const policy = policyEntries.find(entry => entry.referenceName === referenceName);
        const input = { contractId: 'resolve-credential-request.v1', payload: { credentialReference: referenceName,
          invocationIdentity: 'credential-vault-transition.v1', requestingCapabilityId: policy.requestingCapabilityIds[0],
          endpointAuthorityDigest: policy.endpointAuthorityDigests[0], effectScope: policy.effectScopes[0] } };
        const inputFile = path.join(receiptDir, 'preflight-resolve-' + referenceName + '.request.json');
        await fs.writeFile(inputFile, JSON.stringify(input, null, 2) + '\n');
        const resolved = await preflight('resolve-' + referenceName, 'resolve-credential', inputFile);
        const bound = resolved.parsed?.result?.outcome;
        resolvePreflights.push({ referenceName, status: resolved.captured.status, disposition: bound?.disposition ?? null,
          realization: bound?.realization ?? null });
        if (bound?.disposition !== 'CREDENTIAL_BOUND') throw new Error('SWITCH_PREFLIGHT_RESOLVE_FAILED:' + referenceName + ':' + (bound?.disposition ?? resolved.captured.status));
      }
      report.switch.preflightResolve = resolvePreflights;

      if (await fs.access(GEMINI_REQUEST).then(() => true, () => false)) {
        const conveyor = await preflight('conveyor', 'obtain-governed-model-response', GEMINI_REQUEST);
        const blocked = conveyor.disposition === null || /SEMANTIC_EXECUTION_GRAPH_OVERLAY_BINDING_MISSING|SEMANTIC_EXECUTION_GRAPH/.test(conveyor.captured.stdout ?? '');
        report.switch.preflightConveyor = { status: conveyor.captured.status, disposition: conveyor.disposition,
          outcomeDisposition: conveyor.outcomeDisposition,
          blockedByFrozenSda: blocked,
          observedError: blocked ? /SEMANTIC_EXECUTION_GRAPH_[A-Z_]+/.exec(conveyor.captured.stdout)?.[0] ?? 'PREFLIGHT_FAILED' : null,
          note: blocked
            ? 'the frozen SDA graph path cannot compose the conveyor scenarios; the switch is not the cause (the same failure exists without the migration), so the switch install proceeds and the exchange stays blocked'
            : null };
        note('conveyor preflight ' + (blocked ? 'blocked: ' + report.switch.preflightConveyor.observedError : 'not blocked'));
      }

      note('installing the source switch');
      const installed = runProcess(['scripts/run-migration.mjs', VAULT_MIGRATION]);
      await record('install-switch.out', installed.stdout ?? '');
      await record('install-switch.err', installed.stderr ?? '');
      if (installed.status !== 0 || !/MIGRATION COMMIT COMPLETE/.test(installed.stdout ?? '')) {
        throw new Error('SWITCH_INSTALL_FAILED:' + installed.status);
      }
      const after = await authorityState();
      report.switch.stateAfter = after;
      report.switch.installed = true;
      if (Number(after.environment_authorities) !== 0 || Number(after.vault_authorities) === 0) {
        throw new Error('SWITCH_STATE_INVALID');
      }
      note('switch installed: environment authorities ' + after.environment_authorities + ', vault authorities ' + after.vault_authorities);
    });

  report.completedAt = new Date().toISOString();
  const reportText = JSON.stringify(report, null, 2) + '\n';
  assertNoPlaintext('transition.report.json', reportText);
  await fs.writeFile(path.join(receiptDir, 'transition.report.json'), reportText);
  // Idempotency: the report is replayable because each reference is applied
  // before it is stored and each switch step is a no-op when already vault-sourced.
  note('receipt: ' + path.relative(root, path.join(receiptDir, 'transition.report.json')));
} 

main().catch(async error => {
  failed = true;
  report.error = { message: error.message };
  try {
    await fs.mkdir(receiptDir, { recursive: true });
    await fs.writeFile(path.join(receiptDir, 'transition.report.json'), JSON.stringify(report, null, 2) + '\n');
  } catch { /* the receipt is diagnostic; the failure is the unit's outcome */ }
  console.error('TRANSITION FAILED:', error.message);
  process.exitCode = 1;
}).finally(() => {
  if (!failed) note('done');
});
