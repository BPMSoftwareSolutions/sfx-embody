import test from 'node:test';
import assert from 'node:assert/strict';
import { invocationTimingCoherence, streamedGapClosure, streamedCellEvents } from '../src/timing-coherence.mjs';

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
