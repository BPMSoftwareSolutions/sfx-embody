import test from 'node:test';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { executeDatabaseCommand } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/command-carrier.mjs';
import { createDatabaseConnectBoundary, connectionString, sql } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/database-connect-boundary.mjs';
import { withDatabaseReadSession, digest, hash, normalizeSql, pinModel, stable } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/database-read-session.mjs';
import { readAuthority } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/authority-read.mjs';
import { readExecutionDelivery } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/delivery-read.mjs';

// The retired harness (scripts/verify-demo.mjs, W1.4) is replaced by the
// declared read sql/migrations/declare-read-demo-acceptance.sql: the physical
// collection stays in the harness layer, while the twelve-case catalog, every
// acceptance rule and the no-synthesized-values verdict are declared SQL. This
// case exercises the installed read against the live estate; it is the
// retirement's covering test and runs only when the database integration flag
// is set.
const databaseIntegration = process.env.SFX_DATABASE_INTEGRATION === '1';

// The retired sidefx-database loader is gone; the covering case runs on the
// kernel ground: the connection boundary resolves the string by its declared
// environment-variable name and the read session is the kernel's own.
const CONNECTION_NAME = 'sidefx-connection-string';

async function databaseRuntime() {
  const sdaRoot = fileURLToPath(new URL('../../scenario-driven-architecture/', import.meta.url));
  const connect = createDatabaseConnectBoundary({ sql, connectionString: connectionString(CONNECTION_NAME),
    connectionName: CONNECTION_NAME, requestTimeoutMs: 600000 });
  return { sdaRoot, connect, sql, normalizeSql, pinModel, stable, hash, digest, queryRowLimit: 1000 };
}

function capture(caseId, context, exitCode, stdout, claims = [], stderr = null) {
  return { caseId, context, exitCode, stdout, ...(stderr ? { stderr } : {}),
    claims: claims.map(([name, value, equalsCase]) => ({ name, value, ...(equalsCase ? { equalsCase } : {}) })) };
}

// The twelve declared cases, with compact captures that carry every declared
// marker and claim: the same shape the W1.4 acceptance collection supplied.
function baseCaptures() {
  return [
    capture('list-capabilities', 'offline', 0, 'Capabilities (3) say-hello-world sidefx:capabilities', [['capabilities', '3']]),
    capture('find-scaffold', 'offline', 0, 'generate-executable-capability-scaffold'),
    capture('reveal-equity-market-price-evidence', 'offline', 0,
      'Snapshot sha256:AAAA resolve-equity-market-price-evidence observe-equity-price-exchange sda-governed-http-exchange-port.v1',
      [['snapshotId', 'sha256:AAAA']]),
    capture('reveal-equity-market-price-evidence-markdown', 'offline', 0, '## Canonical feature observe-equity-price-exchange'),
    capture('invoke-say-hello-world', 'offline', 0, 'completed hello-world-greeting.v1 Hello, World! sha256:BBBB',
      [['result.disposition', 'completed'], ['result.outcome.payload.message', 'Hello, World!'], ['result.observedPathDigest', 'sha256:BBBB']]),
    capture('observe-say-hello-world-trace', 'offline', 0, 'Scenario say-hello-world say-hello-world-port TRACE'),
    capture('observe-say-hello-world-json', 'offline', 0, 'Hello, World! overlay sha256:BBBB',
      [['result.observedPathDigest', 'sha256:BBBB', 'invoke-say-hello-world']]),
    capture('invoke-resolve-sidefx-eligible-providers', 'offline', 0, 'PROVIDERS_RESOLVED eligibleCount 1',
      [['result.outcome.disposition', 'PROVIDERS_RESOLVED'], ['result.outcome.eligibleCount', '1']]),
    capture('circuit-say-hello-world', 'offline', 4, '', [], 'CIRCUIT_PUBLICATION_UNAVAILABLE'),
    capture('media-artifact-unavailable', 'offline', 4, '', [], 'CIRCUIT_PUBLICATION_UNAVAILABLE'),
    capture('live-invoke-equity-market-price-evidence', 'live', 0, 'EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED QQQ 717.395',
      [['result.outcome.disposition', 'EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED'], ['result.outcome.payload.symbol', 'QQQ'], ['result.outcome.payload.observedPrice', '717.395']]),
    capture('live-observe-equity-market-price-evidence-display', 'live', 0,
      'Scenario resolve-equity-market-price-evidence QQQ observe-equity-price-exchange')
  ];
}

const request = captures => ({ contractId: 'demo-acceptance-request.v1', payload: { harness: 'covering test', captures } });

test('the installed demo-acceptance read reproduces the twelve-case verdict from captured observations', { skip: !databaseIntegration }, async () => {
  const runtime = await databaseRuntime();
  await withDatabaseReadSession(runtime, async (readQuery, sessionEvidence) => {
    assert.ok(sessionEvidence);
    const context = { sdaRoot: runtime.sdaRoot, estateRoot: process.cwd(),
      readQuery,
      readAuthority: (selection, options) => readAuthority(selection, { ...options, query: readQuery }) };
    context.deliveryTarget = (await readExecutionDelivery(context)).defaultTarget;
    const read = async input => {
      const execution = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'invoke',
        request: { object: 'capability', verb: 'invoke', subject: 'read-demo-acceptance', input } }, context);
      const result = execution.outcome?.result;
      assert.equal(result?.disposition, 'completed', JSON.stringify(execution.outcome?.result ?? execution.outcome));
      return result.outcome;
    };

    const green = await read(request(baseCaptures()));
    assert.equal(green.verdict, 'DEMO_ACCEPTANCE_VERIFIED');
    assert.equal(green.synthesizedValues, false);
    assert.deepEqual(green.counts, { declaredCases: 12, capturedCases: 12, offlineCases: 10, liveCases: 2,
      greenCases: 12, liveUnavailableCases: 0, violationCases: 0, synthesizedCases: 0, mismatchedCases: 0 });
    assert.equal(green.cases.every(entry => entry.accepted), true);

    // A reported value the capture does not carry is a synthesized value.
    const synthesized = baseCaptures().map(entry => entry.caseId === 'invoke-say-hello-world'
      ? { ...entry, claims: entry.claims.map(value => value.name === 'result.disposition' ? { ...value, value: 'SYNTHETIC-NOT-OBSERVED' } : value) }
      : entry);
    const synthesizedReceipt = await read(request(synthesized));
    assert.equal(synthesizedReceipt.verdict, 'DEMO_ACCEPTANCE_VIOLATION');
    assert.equal(synthesizedReceipt.synthesizedValues, true);
    assert.equal(synthesizedReceipt.counts.synthesizedCases, 1);
    assert.equal(synthesizedReceipt.counts.greenCases, 11);

    // The invoke/observe observedPathDigest parity is a declared claim rule.
    const mismatched = baseCaptures().map(entry => entry.caseId === 'observe-say-hello-world-json'
      ? { ...entry, stdout: entry.stdout.replace('sha256:BBBB', 'sha256:CCCC'), claims: entry.claims.map(value => ({ ...value, value: 'sha256:CCCC' })) }
      : entry);
    const mismatchedReceipt = await read(request(mismatched));
    assert.equal(mismatchedReceipt.verdict, 'DEMO_ACCEPTANCE_VIOLATION');
    assert.equal(mismatchedReceipt.synthesizedValues, false);
    assert.equal(mismatchedReceipt.counts.mismatchedCases, 1);

    // An offline case at the wrong exit is a violation.
    const failedExit = baseCaptures().map(entry => entry.caseId === 'observe-say-hello-world-trace' ? { ...entry, exitCode: 1 } : entry);
    const failedExitReceipt = await read(request(failedExit));
    assert.equal(failedExitReceipt.verdict, 'DEMO_ACCEPTANCE_VIOLATION');
    assert.equal(failedExitReceipt.cases.find(entry => entry.caseId === 'observe-say-hello-world-trace').outcome, 'VIOLATION');

    // A missing declared case is a violation, named as such.
    const missing = baseCaptures().filter(entry => entry.caseId !== 'find-scaffold');
    const missingReceipt = await read(request(missing));
    assert.equal(missingReceipt.verdict, 'DEMO_ACCEPTANCE_VIOLATION');
    assert.equal(missingReceipt.counts.capturedCases, 11);
    assert.equal(missingReceipt.cases.find(entry => entry.caseId === 'find-scaffold').outcome, 'MISSING_CAPTURE');

    // A live case at a non-zero exit is accepted only when declared unavailable.
    const liveUnavailable = baseCaptures().map(entry => entry.caseId.startsWith('live-')
      ? { ...entry, exitCode: 1, stdout: '', claims: [], declaredUnavailable: true } : entry);
    const unavailableReceipt = await read(request(liveUnavailable));
    assert.equal(unavailableReceipt.verdict, 'DEMO_ACCEPTANCE_VERIFIED');
    assert.equal(unavailableReceipt.counts.liveUnavailableCases, 2);
    assert.equal(unavailableReceipt.counts.greenCases, 10);
  });
});
