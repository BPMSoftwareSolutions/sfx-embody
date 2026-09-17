// The IEA timing-coherence acceptance (docs/invisible-execution-authority.md).
//
// A pure reading over one invocation's streamed observations and declared
// testimony. It computes the first receipt's gap test -- for consecutive
// streamed cell completions, elapsed time minus the completing cell's reported
// duration -- and the invocation equation
//
//   attributed cell time + declared delivery phases + measured overhead
//     = wall span
//
// Every residual gap is either zero (within measurement noise) or named by a
// measured overhead class. The check adds no instrumentation: it reads only the
// declared fields (observedAt, durationMilliseconds, startedAt/completedAt).
export const TIMING_NOISE_MILLISECONDS = 5;

const round = value => Math.round(value * 1000) / 1000;
const at = value => typeof value === 'string' ? Date.parse(value) : NaN;

// The streamed cell entries: the completing cells the gap test attributes.
// Edges are admission records, not execution windows, so they are read as
// stream events but never attributed as cell time.
export function streamedCellEvents(observations) {
  return (Array.isArray(observations) ? observations : [])
    .filter(observation => typeof observation?.cellId === 'string'
      && typeof observation.observedAt === 'string'
      && Number.isFinite(observation.durationMilliseconds))
    .map(observation => ({
      cellId: observation.cellId,
      cellAltitude: observation.cellAltitude ?? null,
      observedAt: observation.observedAt,
      durationMilliseconds: observation.durationMilliseconds,
      sequence: observation.sequence ?? null
    }))
    .sort((left, right) => at(left.observedAt) - at(right.observedAt)
      || (left.sequence ?? 0) - (right.sequence ?? 0));
}

// The gap test over a streamed event sequence. gap(e_n, e_n+1) is the elapsed
// wall time between the two streamed completions; attributed is the duration
// the completing cell reports; the residual is the IEA signal.
export function streamedGapClosure(events, noiseMilliseconds = TIMING_NOISE_MILLISECONDS) {
  const gaps = [];
  for (let index = 1; index < events.length; index++) {
    const gapMilliseconds = at(events[index].observedAt) - at(events[index - 1].observedAt);
    const attributedMilliseconds = events[index].durationMilliseconds;
    const residualMilliseconds = gapMilliseconds - attributedMilliseconds;
    gaps.push({
      from: events[index - 1].cellId,
      to: events[index].cellId,
      gapMilliseconds: round(gapMilliseconds),
      attributedMilliseconds,
      residualMilliseconds: round(residualMilliseconds),
      disposition: residualMilliseconds > noiseMilliseconds ? 'unattributed'
        : residualMilliseconds < -noiseMilliseconds ? 'negative' : 'closed'
    });
  }
  const of = disposition => gaps.filter(gap => gap.disposition === disposition);
  return {
    windows: gaps.length,
    closed: of('closed').length,
    unattributed: of('unattributed').length,
    negative: of('negative').length,
    unattributedMilliseconds: round(of('unattributed').reduce((total, gap) => total + gap.residualMilliseconds, 0)),
    maxUnattributedMilliseconds: round(of('unattributed').reduce((max, gap) => Math.max(max, gap.residualMilliseconds), 0)),
    negativeMilliseconds: round(of('negative').reduce((total, gap) => total + gap.residualMilliseconds, 0)),
    noiseMilliseconds,
    timingCoherent: !gaps.some(gap => gap.disposition !== 'closed'),
    gaps
  };
}

// The declared delivery phases the stream reports, as measured windows.
export function deliveryPhaseWindows(observations) {
  const started = new Map();
  const windows = [];
  for (const observation of Array.isArray(observations) ? observations : []) {
    if (observation?.observationType !== 'delivery-phase' || typeof observation.phase !== 'string') continue;
    if (observation.status === 'started') started.set(observation.phase, at(observation.observedAt));
    else if (started.has(observation.phase)) {
      windows.push({ phase: observation.phase, startedAt: started.get(observation.phase),
        completedAt: at(observation.observedAt),
        milliseconds: round(at(observation.observedAt) - started.get(observation.phase)) });
      started.delete(observation.phase);
    }
  }
  return windows;
}

// Every declared phase start, whether or not the stream closed the window. The
// execution phase start is what bounds the pre-stream overhead when a stream
// fails before `executeDeclaredGraph` completes.
export function deliveryPhaseStarts(observations) {
  return (Array.isArray(observations) ? observations : [])
    .filter(observation => observation?.observationType === 'delivery-phase'
      && typeof observation.phase === 'string' && observation.status === 'started')
    .map(observation => ({ phase: observation.phase, startedAt: at(observation.observedAt) }));
}

// The invocation reading. `wallSpanMilliseconds` and `deliveryPhaseMilliseconds`
// may be supplied by the caller (the accepted streamed measurement); otherwise
// they are measured from the stream. Every overhead residual is named by a
// measured class; `unaccountedOverheadMilliseconds` must be zero or within noise.
export function invocationTimingCoherence({ observations, cellTestimony,
  wallSpanMilliseconds, deliveryPhaseMilliseconds, noiseMilliseconds = TIMING_NOISE_MILLISECONDS }) {
  const events = streamedCellEvents(observations);
  const closed = streamedGapClosure(events, noiseMilliseconds);
  const phases = deliveryPhaseWindows(observations);
  const phaseStarts = deliveryPhaseStarts(observations);
  const executionStart = phaseStarts.find(phase => phase.phase === 'executeDeclaredGraph')?.startedAt ?? null;
  const declaredPhases = phases.filter(phase => phase.phase !== 'executeDeclaredGraph');
  const attributedCellMilliseconds = round((Array.isArray(cellTestimony) ? cellTestimony : [])
    .reduce((total, cell) => total + (Number.isFinite(cell?.durationMilliseconds) ? cell.durationMilliseconds : 0), 0));
  const firstEvent = events[0] ?? null;
  const lastEvent = events[events.length - 1] ?? null;
  const firstPhase = phaseStarts.reduce((earliest, phase) => Math.min(earliest, phase.startedAt), Infinity);
  const measuredWallSpan = firstEvent && firstPhase !== Infinity
    ? at(lastEvent.observedAt) - firstPhase : null;
  const wallSpan = Number.isFinite(wallSpanMilliseconds) ? wallSpanMilliseconds : measuredWallSpan;
  const declaredDeliveryPhaseMilliseconds = Number.isFinite(deliveryPhaseMilliseconds)
    ? deliveryPhaseMilliseconds : round(declaredPhases.reduce((total, phase) => total + phase.milliseconds, 0));
  const measuredOverheadMilliseconds = Number.isFinite(wallSpan)
    ? round(wallSpan - declaredDeliveryPhaseMilliseconds - attributedCellMilliseconds) : null;
  const firstDuration = firstEvent?.durationMilliseconds ?? 0;
  const streamedAttributed = events.reduce((total, event) => total + event.durationMilliseconds, 0);
  const named = [];
  if (executionStart !== null && firstEvent) named.push({ name: 'kernel-before-first-streamed-cell',
    milliseconds: round(Math.max(0, at(firstEvent.observedAt) - firstDuration - executionStart)),
    basis: 'executeDeclaredGraph phase start to the first streamed cell start' });
  if (firstEvent && lastEvent) named.push({ name: 'inter-event-slack',
    milliseconds: round(at(lastEvent.observedAt) - at(firstEvent.observedAt) - (streamedAttributed - firstDuration)),
    basis: 'streamed span minus the cell time attributed between the first and last completions' });
  const namedOverheadMilliseconds = round(named.reduce((total, item) => total + item.milliseconds, 0));
  const unaccountedOverheadMilliseconds = measuredOverheadMilliseconds === null ? null
    : round(measuredOverheadMilliseconds - namedOverheadMilliseconds);
  return {
    events: events.length,
    gapClosure: closed,
    attributedCellMilliseconds,
    declaredDeliveryPhaseMilliseconds,
    wallSpanMilliseconds: Number.isFinite(wallSpan) ? round(wallSpan) : null,
    measuredOverheadMilliseconds,
    namedOverhead: named,
    namedOverheadMilliseconds,
    unaccountedOverheadMilliseconds,
    timingCoherent: closed.timingCoherent
      && (unaccountedOverheadMilliseconds === null || Math.abs(unaccountedOverheadMilliseconds) <= noiseMilliseconds)
  };
}
