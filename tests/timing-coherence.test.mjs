import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { invocationTimingCoherence, streamedGapClosure, streamedCellEvents } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/timing-coherence.mjs';
import { executeDatabaseCommand } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/command-carrier.mjs';
import { readAuthority } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/authority-read.mjs';
import { withDatabaseReadSession } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/database-read-session.mjs';
import { readExecutionDelivery } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/delivery-read.mjs';

// W2.1/U5c retired the estate oracle: it is homed on the SDA kernel ground at
// languages/typescript/src/kernel/bootstrap/timing-coherence.mjs (the admitted
// independent test floor, builder decision 5). The accepted authority is the
// declared read-invocation-timing; its covering case below exercises the
// installed read against the same synthetic testimony and runs only when the
// database integration flag is set.

// The acceptance reading, exercised on synthetic streams that stand in for the
// live agent-lane receipt: declared phases bracket the execution, cells complete
// in sequence, and every window must close against the completing cell's
// reported duration (docs/invisible-execution-authority.md).
const T0 = Date.parse('2026-09-17T00:00:00.000Z');
const iso = offset => new Date(T0 + offset).toISOString();
const phase = (name, status, offset) => ({ observationType: 'delivery-phase', phase: name, status, observedAt: iso(offset) });
const cell = (cellId, cellAltitude, offset, durationMilliseconds) => ({
  observationType: 'cell-execution-testimony.v1', cellId, cellAltitude, observedAt: iso(offset), durationMilliseconds });

function stream() {
  return {
    observations: [
      phase('readExecutionDelivery', 'started', 0), phase('readExecutionDelivery', 'completed', 100),
      phase('readAuthority', 'started', 100), phase('readAuthority', 'completed', 200),
      phase('executeDeclaredGraph', 'started', 200),
      cell('cell:scenario:a', 'scenario', 210, 10),
      cell('cell:mechanic:b', 'mechanic', 310, 100),
      cell('cell:mechanic:c', 'mechanic', 390, 80)
    ],
    cellTestimony: [
      { cellId: 'cell:scenario:a', cellAltitude: 'scenario', durationMilliseconds: 10 },
      { cellId: 'cell:mechanic:b', cellAltitude: 'mechanic', durationMilliseconds: 100 },
      { cellId: 'cell:mechanic:c', cellAltitude: 'mechanic', durationMilliseconds: 80 }
    ]
  };
}

test('every streamed window closes and the invocation equation names all overhead', () => {
  const reading = invocationTimingCoherence(stream());
  assert.equal(reading.events, 3);
  assert.deepEqual({ ...reading.gapClosure, gaps: undefined }, {
    windows: 2, closed: 2, unattributed: 0, negative: 0,
    unattributedMilliseconds: 0, maxUnattributedMilliseconds: 0, negativeMilliseconds: 0,
    noiseMilliseconds: 5, timingCoherent: true, gaps: undefined
  });
  assert.equal(reading.attributedCellMilliseconds, 190);
  assert.equal(reading.declaredDeliveryPhaseMilliseconds, 200);
  assert.equal(reading.wallSpanMilliseconds, 390);
  assert.equal(reading.measuredOverheadMilliseconds, 0);
  assert.deepEqual(reading.namedOverhead.map(item => item.name),
    ['kernel-before-first-streamed-cell', 'inter-event-slack']);
  assert.equal(reading.namedOverheadMilliseconds, 0);
  assert.equal(reading.unaccountedOverheadMilliseconds, 0);
  assert.equal(reading.timingCoherent, true);
});

test('a positive unattributed delta above noise is the IEA signal', () => {
  const input = stream();
  input.observations[6] = cell('cell:mechanic:b', 'mechanic', 410, 100);
  input.observations[7] = cell('cell:mechanic:c', 'mechanic', 490, 80);
  const reading = invocationTimingCoherence(input);
  assert.equal(reading.gapClosure.unattributed, 1);
  assert.equal(reading.gapClosure.unattributedMilliseconds, 100);
  assert.equal(reading.gapClosure.maxUnattributedMilliseconds, 100);
  assert.equal(reading.gapClosure.timingCoherent, false);
  assert.equal(reading.timingCoherent, false);
  const open = reading.gapClosure.gaps.find(gap => gap.disposition === 'unattributed');
  assert.equal(open.to, 'cell:mechanic:b');
  assert.equal(open.attributedMilliseconds, 100);
});

test('a negative gap is named as clock inconsistency, never closed', () => {
  const input = stream();
  input.observations[6] = cell('cell:mechanic:b', 'mechanic', 250, 100);
  const reading = invocationTimingCoherence(input);
  assert.equal(reading.gapClosure.negative, 1);
  assert.equal(reading.gapClosure.negativeMilliseconds, -60);
  assert.equal(reading.gapClosure.timingCoherent, false);
});

test('edges are stream events but never attributed as cell windows', () => {
  const input = stream();
  const events = streamedCellEvents([...input.observations,
    { observationType: 'edge-execution-testimony.v1', edgeId: 'edge:a', observedAt: iso(215), durationMilliseconds: 2 }]);
  assert.equal(events.length, 3);
  const closure = streamedGapClosure(events);
  assert.equal(closure.windows, 2);
  assert.equal(closure.timingCoherent, true);
});

test('overhead the stream does not name leaves the invocation not timing-coherent', () => {
  const input = stream();
  input.observations = [
    phase('readExecutionDelivery', 'started', 0), phase('readExecutionDelivery', 'completed', 100),
    phase('readAuthority', 'started', 100), phase('readAuthority', 'completed', 200),
    cell('cell:scenario:a', 'scenario', 1000, 100),
    cell('cell:mechanic:b', 'mechanic', 1100, 100)
  ];
  input.cellTestimony = [
    { cellId: 'cell:scenario:a', cellAltitude: 'scenario', durationMilliseconds: 100 },
    { cellId: 'cell:mechanic:b', cellAltitude: 'mechanic', durationMilliseconds: 100 }
  ];
  const reading = invocationTimingCoherence(input);
  // The windows close, but 700 ms of measured overhead has no streamed class.
  assert.equal(reading.gapClosure.timingCoherent, true);
  assert.equal(reading.measuredOverheadMilliseconds, 700);
  assert.equal(reading.unaccountedOverheadMilliseconds, 700);
  assert.equal(reading.timingCoherent, false);
});

test('a supplied wall span is honored for the declared reading agreement', () => {
  const reading = invocationTimingCoherence({ ...stream(), wallSpanMilliseconds: 400, deliveryPhaseMilliseconds: 200 });
  assert.equal(reading.wallSpanMilliseconds, 400);
  assert.equal(reading.measuredOverheadMilliseconds, 10);
  assert.equal(reading.unaccountedOverheadMilliseconds, 10);
  assert.equal(reading.timingCoherent, false);
});

// The declared read-invocation-timing is the acceptance authority. Its
// covering case hands the installed read the two-cell testimony the
// declaration's own self-test uses (one 40 ms scenario cell completed at 40 ms,
// one 60 ms mechanic cell completed at 100 ms) with the measured wall span, and
// asserts the declared reading's gap closure, attribution and residual -- and
// that it agrees with the independent oracle on the same stream.

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

const databaseIntegration = process.env.SFX_DATABASE_INTEGRATION === '1';

test('the installed timing reading closes the synthetic testimony and agrees with the oracle',
  { skip: !databaseIntegration }, async () => {
    const runtime = await databaseRuntime();
    await withDatabaseReadSession(runtime, async (readQuery, sessionEvidence) => {
      assert.ok(sessionEvidence);
      const context = { databaseRoot: runtime.databaseRoot, sdaRoot: runtime.sdaRoot, estateRoot: path.resolve('.'),
        readQuery,
        readAuthority: (selection, options) => readAuthority(selection, { ...options, query: readQuery }) };
      context.deliveryTarget = (await readExecutionDelivery(context)).defaultTarget;

      const testimony = [
        { cellId: 'cell:scenario:synthetic', cellAltitude: 'scenario', durationMilliseconds: 40,
          completedAt: new Date(T0 + 40).toISOString() },
        { cellId: 'cell:mechanic:synthetic', cellAltitude: 'mechanic', durationMilliseconds: 60,
          completedAt: new Date(T0 + 100).toISOString() }
      ];
      const input = { contractId: 'invocation-timing-request.v1', payload: {
        label: 'oracle-covering-test', cellTestimony: testimony,
        measured: { wallSpanMilliseconds: 100, deliveryPhaseMilliseconds: 0 },
        noiseMilliseconds: 5, topCount: 2 } };
      const execution = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'invoke',
        request: { object: 'capability', verb: 'invoke', subject: 'read-invocation-timing', input } }, context);
      const result = execution.outcome?.result;
      assert.equal(result?.disposition, 'completed', JSON.stringify(execution.outcome?.result ?? execution.outcome));
      const reading = result.outcome;
      assert.equal(reading.reading, 'invocation-timing-reading.v1');
      assert.equal(reading.cells, 2);
      assert.equal(reading.totalAttributedMilliseconds, 100);
      assert.deepEqual(reading.gapClosure, {
        windows: 1, closed: 1, unattributed: 0, negative: 0,
        unattributedMilliseconds: 0, maxUnattributedMilliseconds: 0, negativeMilliseconds: 0,
        noiseMilliseconds: 5, timingCoherent: true
      });
      assert.equal(reading.residualMilliseconds, 0);
      assert.equal(reading.topContributors[0].cellId, 'cell:mechanic:synthetic');
      assert.deepEqual(reading.attributedByAltitude.map(entry => [entry.altitude, entry.durationMilliseconds]),
        [['mechanic', 60], ['scenario', 40]]);

      const observations = testimony.map(entry => ({ observationType: 'cell-execution-testimony.v1',
        cellId: entry.cellId, cellAltitude: entry.cellAltitude, observedAt: entry.completedAt,
        durationMilliseconds: entry.durationMilliseconds }));
      const oracle = invocationTimingCoherence({ observations, cellTestimony: testimony,
        wallSpanMilliseconds: 100, deliveryPhaseMilliseconds: 0 });
      assert.equal(reading.gapClosure.windows, oracle.gapClosure.windows);
      assert.equal(reading.gapClosure.timingCoherent, oracle.gapClosure.timingCoherent);
      assert.equal(reading.totalAttributedMilliseconds, oracle.attributedCellMilliseconds);
      assert.equal(reading.residualMilliseconds, oracle.measuredOverheadMilliseconds);
      assert.equal(oracle.timingCoherent, true);
    });
  });
