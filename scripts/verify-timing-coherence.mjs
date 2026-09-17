// IEA timing-coherence acceptance (docs/invisible-execution-authority.md,
// unit "Timing-coherence acceptance", verification).
//
//   node scripts/verify-timing-coherence.mjs [--receipt-dir DIR]
//
// Drives live streamed invocations of the capabilities the agent lane exercises
// -- `request-capability-from-objective`, `resolve-equity-market-price-evidence`,
// `compose-resolve-equity-market-price-evidence` and `obtain-governed-model-response`
// -- through the estate's declared invocation path with the three credential
// names absent from the process (the vault is the only credential source), then:
//
//   1. computes the first receipt's gap test over the streamed cell events
//      (src/timing-coherence.mjs): every consecutive window's elapsed time minus
//      the completing cell's reported duration must be zero within measurement
//      noise; positive unattributed deltas and negative gaps are the IEA signal;
//   2. closes the invocation equation: attributed cell time + declared delivery
//      phases + measured overhead = wall span, with every overhead residual
//      named by a measured class;
//   3. invokes the declared timing reading (read-invocation-timing) over the
//      same testimony and asserts the declared reading agrees with the check;
//      the reading's declared display projection is attached and asserted.
//
// The receipt carries no secret: the invocation outcomes, cell identities,
// durations, the reading payload and the display document only.
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { executeDatabaseCommand } from '../src/invoke-database-capability.mjs';
import { readAuthority } from '../src/read-authority.mjs';
import { withDatabaseReadSession } from '../src/database-read-session.mjs';
import { readExecutionDelivery } from '../src/read-execution-delivery.mjs';
import { invocationTimingCoherence, TIMING_NOISE_MILLISECONDS } from '../src/timing-coherence.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const DATABASE_ROOT = process.env.SIDEFX_DATABASE_ROOT ?? 'C:/lab/sidefx-database';
const SDA_ROOT = process.env.SIDEFX_SDA_ROOT ?? 'C:/lab/repos/scenario-driven-architecture';
const REFERENCES = ['RAPID_API_KEY', 'LOC_GEMINI_API_KEY', 'LOC_OPENAI_API_KEY'];
const startedAt = new Date().toISOString();
const receiptDir = path.resolve(root, process.argv.includes('--receipt-dir')
  ? process.argv[process.argv.indexOf('--receipt-dir') + 1]
  : path.join('evidence', 'vault-20260916', 'iea'));
const report = {
  receiptType: 'timing-coherence.v1',
  authority: 'docs/invisible-execution-authority.md',
  generatedAt: startedAt,
  runtime: {
    credentialNamesAbsent: REFERENCES,
    credentialSource: 'vault (%LOCALAPPDATA%\\sfx\\vault)',
    noiseMilliseconds: TIMING_NOISE_MILLISECONDS
  },
  cases: [],
  verdict: null
};

const note = message => console.log('TIMING-COHERENCE ' + message);
const write = async (name, value) => fs.writeFile(
  path.join(receiptDir, name),
  typeof value === 'string' ? value : JSON.stringify(value, null, 2) + '\n');

// The streamed cells as audit rows: identity, altitude and declared duration.
const streamEvents = observations => observations
  .filter(observation => typeof observation?.cellId === 'string' && Number.isFinite(observation.durationMilliseconds))
  .map(observation => ({ cellId: observation.cellId, cellAltitude: observation.cellAltitude ?? null,
    observedAt: observation.observedAt, durationMilliseconds: observation.durationMilliseconds,
    sequence: observation.sequence ?? null }));

const contributorsOf = payload => (payload.topContributors ?? []).slice(0, 5);

async function invokeObserve(context, capabilityId, input, label) {
  const observations = [];
  const execution = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'observe',
    request: { object: 'capability', verb: 'observe', subject: capabilityId, input,
      observationAltitudes: ['scenario', 'mechanic', 'provider', 'physical'] } },
  { ...context, onObservation: value => observations.push(value) });
  const result = execution.outcome.result;
  return { capabilityId, label, observations, result,
    disposition: result.disposition, outcomeVariant: result.outcomeVariant ?? null,
    outcomeContractId: result.outcome?.contractId ?? null, evidence: execution.outcome.evidence };
}

async function readTiming(context, label, testimony, analysis) {
  const execution = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'invoke',
    request: { object: 'capability', verb: 'invoke', subject: 'read-invocation-timing', display: true,
      input: { contractId: 'invocation-timing-request.v1', payload: {
        label, cellTestimony: testimony,
        measured: { wallSpanMilliseconds: analysis.wallSpanMilliseconds,
          deliveryPhaseMilliseconds: analysis.declaredDeliveryPhaseMilliseconds },
        noiseMilliseconds: analysis.gapClosure.noiseMilliseconds, topCount: 12 } } } }, context);
  return { payload: execution.outcome.result.outcome,
    document: execution.outcome.display?.document ?? null };
}

function assertCase(label, invocation, analysis, reading) {
  // 1. The first receipt's test: every streamed window closes.
  assert.equal(analysis.gapClosure.unattributed, 0, label + ': unattributed streamed windows');
  assert.equal(analysis.gapClosure.negative, 0, label + ': negative streamed windows');
  assert.equal(analysis.gapClosure.timingCoherent, true, label + ': streamed gap closure');
  // 2. The invocation equation, with every residual named by a measured class.
  assert.ok(Number.isFinite(analysis.measuredOverheadMilliseconds), label + ': measured overhead');
  assert.ok(Math.abs(analysis.unaccountedOverheadMilliseconds) <= analysis.gapClosure.noiseMilliseconds,
    label + ': unaccounted overhead ' + analysis.unaccountedOverheadMilliseconds);
  assert.equal(analysis.timingCoherent, true, label + ': invocation timing coherence');
  // 3. The declared reading agrees with the independent check.
  assert.equal(reading.payload?.reading, 'invocation-timing-reading.v1', label + ': declared reading identity');
  assert.equal(reading.payload.cells, invocation.result.cellTestimony.length, label + ': reading cells');
  assert.equal(reading.payload.gapClosure.timingCoherent, true, label + ': declared gap closure');
  assert.equal(reading.payload.gapClosure.windows, analysis.gapClosure.windows, label + ': declared windows');
  assert.equal(reading.payload.gapClosure.unattributed, 0, label + ': declared unattributed');
  assert.equal(reading.payload.gapClosure.negative, 0, label + ': declared negative');
  assert.ok(Math.abs(reading.payload.totalAttributedMilliseconds - analysis.attributedCellMilliseconds) <= 0.01,
    label + ': declared attributed total');
  assert.ok(Math.abs(reading.payload.residualMilliseconds - analysis.measuredOverheadMilliseconds) <= 0.01,
    label + ': declared residual against the wall span');
  const longest = [...invocation.result.cellTestimony].sort((left, right) => right.durationMilliseconds - left.durationMilliseconds)[0];
  assert.equal(reading.payload.topContributors[0].cellId, longest.cellId, label + ': top contributor');
  // 4. The reading's declared display projection is attached and selected.
  assert.equal(reading.document?.documentType, 'sfx-display-document.v1', label + ': display document');
  assert.ok((reading.document.blocks ?? []).length >= 6, label + ': display blocks');
}

const caseRecord = (invocation, analysis, reading) => ({
  capabilityId: invocation.capabilityId,
  label: invocation.label,
  disposition: invocation.disposition,
  outcomeVariant: invocation.outcomeVariant,
  outcomeContractId: invocation.outcomeContractId,
  observation: {
    streamedCells: analysis.events,
    streamedSpanMilliseconds: analysis.wallSpanMilliseconds,
    gapWindows: analysis.gapClosure.windows,
    unattributedWindows: analysis.gapClosure.unattributed,
    negativeWindows: analysis.gapClosure.negative,
    maxUnattributedMilliseconds: analysis.gapClosure.maxUnattributedMilliseconds
  },
  equation: {
    wallSpanMilliseconds: analysis.wallSpanMilliseconds,
    declaredDeliveryPhaseMilliseconds: analysis.declaredDeliveryPhaseMilliseconds,
    attributedCellMilliseconds: analysis.attributedCellMilliseconds,
    measuredOverheadMilliseconds: analysis.measuredOverheadMilliseconds,
    namedOverhead: analysis.namedOverhead,
    unaccountedOverheadMilliseconds: analysis.unaccountedOverheadMilliseconds
  },
  reading: {
    capabilityId: 'read-invocation-timing',
    displayTransformationId: 'read-invocation-timing-display.v1',
    cells: reading.payload.cells,
    totalAttributedMilliseconds: reading.payload.totalAttributedMilliseconds,
    attributedByAltitude: reading.payload.attributedByAltitude,
    residualMilliseconds: reading.payload.residualMilliseconds,
    gapClosure: { ...reading.payload.gapClosure, gaps: undefined },
    topContributors: contributorsOf(reading.payload),
    displayBlocks: (reading.document.blocks ?? []).map(block => block.type)
  },
  timingCoherent: analysis.timingCoherent && reading.payload.gapClosure.timingCoherent
});

async function main() {
  await fs.mkdir(receiptDir, { recursive: true });
  for (const reference of REFERENCES) delete process.env[reference];

  const { connect, sql } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/ingest/database.mjs')).href);
  const { pinModel } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/query/model-pin.mjs')).href);
  const { normalizeSql } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/query/run.mjs')).href);
  const { config, stable, hash, digest } = await import(pathToFileURL(path.join(DATABASE_ROOT, 'src/core.mjs')).href);
  const { queryRowLimit } = await config();

  await withDatabaseReadSession({ connect, sql, pinModel, normalizeSql, stable, hash, digest, queryRowLimit },
    async (readQuery, sessionEvidence) => {
      report.session = sessionEvidence;
      const base = { databaseRoot: DATABASE_ROOT, sdaRoot: SDA_ROOT, estateRoot: root,
        readAuthority: (rootRef, selection, options) => readAuthority(DATABASE_ROOT, selection, { ...options, query: readQuery }),
        readQuery };
      base.deliveryTarget = (await readExecutionDelivery(base)).defaultTarget;

      note('agent lane: observe request-capability-from-objective with the credential names absent');
      const agent = await invokeObserve(base, 'request-capability-from-objective',
        { contractId: 'agent-objective-request.v1', payload: { objective: "What is Broadcom's current market price?" } },
        'request-capability-from-objective');
      const agentAnalysis = invocationTimingCoherence({ observations: agent.observations,
        cellTestimony: agent.result.cellTestimony });
      const agentReading = await readTiming(base, 'request-capability-from-objective',
        agent.result.cellTestimony, agentAnalysis);
      assertCase('agent lane', agent, agentAnalysis, agentReading);
      note(`agent lane: ${agentAnalysis.gapClosure.windows} windows closed, attributed ` +
        `${agentAnalysis.attributedCellMilliseconds} ms, overhead named ` +
        `${agentAnalysis.namedOverheadMilliseconds} ms, unaccounted ${agentAnalysis.unaccountedOverheadMilliseconds} ms`);
      report.cases.push(caseRecord(agent, agentAnalysis, agentReading));
      await write('agent-lane.timing-reading.json', agentReading.payload);
      await write('agent-lane.display-document.json', agentReading.document);
      await write('agent-lane.stream-events.json', streamEvents(agent.observations));

      note('equity: observe resolve-equity-market-price-evidence with the credential names absent');
      const equity = await invokeObserve(base, 'resolve-equity-market-price-evidence', 'QQQ',
        'resolve-equity-market-price-evidence');
      const equityAnalysis = invocationTimingCoherence({ observations: equity.observations,
        cellTestimony: equity.result.cellTestimony });
      const equityReading = await readTiming(base, 'resolve-equity-market-price-evidence',
        equity.result.cellTestimony, equityAnalysis);
      assertCase('equity', equity, equityAnalysis, equityReading);
      note(`equity: ${equityAnalysis.gapClosure.windows} windows closed, attributed ` +
        `${equityAnalysis.attributedCellMilliseconds} ms, overhead named ` +
        `${equityAnalysis.namedOverheadMilliseconds} ms, unaccounted ${equityAnalysis.unaccountedOverheadMilliseconds} ms`);
      report.cases.push(caseRecord(equity, equityAnalysis, equityReading));
      await write('equity.timing-reading.json', equityReading.payload);
      await write('equity.display-document.json', equityReading.document);
      await write('equity.stream-events.json', streamEvents(equity.observations));

      note('compose: observe compose-resolve-equity-market-price-evidence with the credential names absent');
      const composed = await invokeObserve(base, 'compose-resolve-equity-market-price-evidence',
        { contractId: 'live-equity-price-request.v1', payload: { symbol: 'QQQ', region: 'US' } },
        'compose-resolve-equity-market-price-evidence');
      const composedAnalysis = invocationTimingCoherence({ observations: composed.observations,
        cellTestimony: composed.result.cellTestimony });
      const composedReading = await readTiming(base, 'compose-resolve-equity-market-price-evidence',
        composed.result.cellTestimony, composedAnalysis);
      assertCase('compose', composed, composedAnalysis, composedReading);
      note(`compose: ${composedAnalysis.gapClosure.windows} windows closed, attributed ` +
        `${composedAnalysis.attributedCellMilliseconds} ms, overhead named ` +
        `${composedAnalysis.namedOverheadMilliseconds} ms, unaccounted ${composedAnalysis.unaccountedOverheadMilliseconds} ms`);
      report.cases.push(caseRecord(composed, composedAnalysis, composedReading));
      await write('compose.timing-reading.json', composedReading.payload);
      await write('compose.display-document.json', composedReading.document);
      await write('compose.stream-events.json', streamEvents(composed.observations));

      note('model lane: observe obtain-governed-model-response with the credential names absent');
      const modelLane = await invokeObserve(base, 'obtain-governed-model-response', {
        carrierType: 'governed-model-invocation-request.v1',
        requestId: 'timing-coherence-model',
        requestHash: 'sha256:' + '0'.repeat(64),
        modelRequest: {
          $schema: '../../generic-llm-connector/authority/model-request.schema.v1.json',
          requestId: 'timing-coherence-model',
          providerAuthorityId: 'primary-cognitive-provider',
          modelAlias: 'instruction-capable-model',
          interaction: { mode: 'text-generation', messages: [{ role: 'user', content: 'Reply with the single word: ready' }] },
          responsePolicy: { format: 'text', maximumOutputTokens: 256, temperature: 0 },
          executionPolicy: { timeoutMilliseconds: 120000, attemptAuthority: { maximumAuthorizedAttempts: 1 }, providerSubstitution: { allowed: false } },
          evidencePolicy: { captureRequestHash: true, captureResponseHash: true, captureResolvedProvider: true,
            captureResolvedModel: true, captureTokenUsage: true, captureTiming: true }
        },
        requestLineage: ['timing-coherence', 'obtain-governed-model-response']
      }, 'obtain-governed-model-response');
      const modelLaneAnalysis = invocationTimingCoherence({ observations: modelLane.observations,
        cellTestimony: modelLane.result.cellTestimony });
      const modelLaneReading = await readTiming(base, 'obtain-governed-model-response',
        modelLane.result.cellTestimony, modelLaneAnalysis);
      assertCase('model lane', modelLane, modelLaneAnalysis, modelLaneReading);
      note(`model lane: ${modelLaneAnalysis.gapClosure.windows} windows closed, attributed ` +
        `${modelLaneAnalysis.attributedCellMilliseconds} ms, overhead named ` +
        `${modelLaneAnalysis.namedOverheadMilliseconds} ms, unaccounted ${modelLaneAnalysis.unaccountedOverheadMilliseconds} ms`);
      report.cases.push(caseRecord(modelLane, modelLaneAnalysis, modelLaneReading));
      await write('model-lane.timing-reading.json', modelLaneReading.payload);
      await write('model-lane.display-document.json', modelLaneReading.document);
      await write('model-lane.stream-events.json', streamEvents(modelLane.observations));
    });

  report.verdict = { timingCoherent: report.cases.every(item => item.timingCoherent),
    residualDisposition: 'zero-or-named' };
  assert.equal(report.verdict.timingCoherent, true, 'TIMING_COHERENCE_VERDICT');
  report.completedAt = new Date().toISOString();
  await write('timing-coherence.receipt.json', report);
  note('receipt: ' + path.relative(root, path.join(receiptDir, 'timing-coherence.receipt.json')));
  note('verdict: ' + (report.verdict.timingCoherent ? 'TIMING-COHERENT (every residual zero or named)' : 'NOT COHERENT'));
}

main().catch(async error => {
  report.error = { message: error.message };
  report.completedAt = new Date().toISOString();
  try {
    await fs.mkdir(receiptDir, { recursive: true });
    await fs.writeFile(path.join(receiptDir, 'timing-coherence.receipt.json'), JSON.stringify(report, null, 2) + '\n');
  } catch { /* diagnostic only */ }
  console.error('TIMING-COHERENCE FAILED:', error.message);
  process.exitCode = 1;
});
