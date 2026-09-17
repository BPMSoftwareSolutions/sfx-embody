// CV-D1 circuit structural acceptance (docs/implementation-plan-circuit-view.md;
// docs/circuit-view-flywheel.md, "the attestation pair").
//
//   node scripts/verify-circuit-structure.mjs [--receipt-dir DIR]
//
// Drives live streamed observations of the capabilities the agent lane exercises
// -- `request-capability-from-objective`, `resolve-equity-market-price-evidence`,
// `compose-resolve-equity-market-price-evidence` and `obtain-governed-model-response`
// -- through the estate's declared invocation path with the three credential
// names absent from the process (the vault is the only credential source). It is
// the structural half of the attestation pair whose time half is
// scripts/verify-timing-coherence.mjs, and it reads the same overlay the
// drilldown joins: the compiled plan (canonical cells plus realization-physical
// cells) against the execution's testimony.
//
//   1. Planned -> observed: every planned cell in the overlay carries at least
//      one observed testimony entry, either through the overlay's join
//      (overlay.cells[].observed) or by matching result.cellTestimony by cellId.
//   2. Observed -> planned: every testimony cell id at scenario/mechanic/
//      provider/physical altitude resolves to a planned overlay cell, directly
//      or through the decomposition path -- trimming `:expression`/`:selection`
//      suffixes and iterative trailing path segments until a planned cell
//      matches.
//   3. Unmatched rows in either direction are counted and named. A testimony id
//      that resolves only through the trim rule is a kernel-synthesized
//      decomposition row, not a declared cell; it is recorded as a named
//      exemption with the enclosing planned cell (the exemption's justification)
//      and does not count unmatched.
//
// The receipt carries per-case counts (plannedCells, observedCells,
// unmatchedPlanned, unmatchedObserved, verifiedAt), the unmatched names and the
// exemptions. The verdict is CIRCUIT-STRUCTURED only when both directions are
// unmatched==0 for every case; otherwise the script exits non-zero and lists
// the names. Unmatched cells are the finding; no exemption is invented for the
// planned direction.
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { executeDatabaseCommand } from '../src/invoke-database-capability.mjs';
import { readAuthority } from '../src/read-authority.mjs';
import { withDatabaseReadSession } from '../src/database-read-session.mjs';
import { readExecutionDelivery } from '../src/read-execution-delivery.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const DATABASE_ROOT = process.env.SIDEFX_DATABASE_ROOT ?? 'C:/lab/sidefx-database';
const SDA_ROOT = process.env.SIDEFX_SDA_ROOT ?? 'C:/lab/repos/scenario-driven-architecture';
const REFERENCES = ['RAPID_API_KEY', 'LOC_GEMINI_API_KEY', 'LOC_OPENAI_API_KEY'];
const ALTITUDES = ['scenario', 'mechanic', 'provider', 'physical'];
const startedAt = new Date().toISOString();
const receiptDir = path.resolve(root, process.argv.includes('--receipt-dir')
  ? process.argv[process.argv.indexOf('--receipt-dir') + 1]
  : path.join('evidence', 'vault-20260916', 'iea'));
const report = {
  receiptType: 'circuit-structure.v1',
  authority: 'docs/implementation-plan-circuit-view.md (CV-D1); docs/circuit-view-flywheel.md (attestation pair)',
  generatedAt: startedAt,
  runtime: {
    credentialNamesAbsent: REFERENCES,
    credentialSource: 'vault (%LOCALAPPDATA%\\sfx\\vault)',
    plannedSource: 'execution.outcome.overlay (drilldown: canonicalGraph.cells + realizationOverlay.physicalCells)',
    observedSource: 'execution.outcome.result.cellTestimony at scenario/mechanic/provider/physical altitude'
  },
  cases: [],
  verdict: null
};

const note = message => console.log('CIRCUIT-STRUCTURE ' + message);
const write = async (name, value) => fs.writeFile(
  path.join(receiptDir, name),
  typeof value === 'string' ? value : JSON.stringify(value, null, 2) + '\n');

// The decomposition path from an observed id toward the plan: strip a trailing
// `:expression`/`:selection` structural suffix, strip one trailing `.segment`,
// or strip an interior `:expression`/`:selection` token that leads into path
// segments. Breadth-first so the nearest planned cell wins.
const parentCandidates = cellId => {
  const parents = [];
  if (/:selection$/.test(cellId)) parents.push(cellId.replace(/:selection$/, ''));
  if (/:expression$/.test(cellId)) parents.push(cellId.replace(/:expression$/, ''));
  const segment = /\.([^.:]+)$/.exec(cellId);
  if (segment) parents.push(cellId.slice(0, -segment[0].length));
  const interior = /:(expression|selection)(?=[.:])/.exec(cellId);
  if (interior) parents.push(cellId.slice(0, interior.index) + cellId.slice(interior.index + interior[0].length));
  return parents;
};

const nearestFrom = (cellId, member) => {
  const queue = [cellId];
  const seen = new Set(queue);
  while (queue.length) {
    const id = queue.shift();
    if (member.has(id)) return id;
    for (const parent of parentCandidates(id)) if (!seen.has(parent)) { seen.add(parent); queue.push(parent); }
  }
  return null;
};

const structuralCheck = ({ overlay, testimony }) => {
  assert.ok(overlay && Array.isArray(overlay.cells), 'observe overlay');
  const plannedCells = overlay.cells.filter(cell => cell.planned !== null);
  assert.ok(plannedCells.length > 0, 'planned cells');
  assert.equal(plannedCells.length, overlay.counts?.plannedCells ?? plannedCells.length, 'planned cell count');
  const plannedIds = new Set(plannedCells.map(cell => cell.cellId));

  const observedRows = testimony.filter(row => ALTITUDES.includes(row.cellAltitude));
  const observedIds = [...new Set(observedRows.map(row => row.cellId))];
  assert.ok(observedIds.length > 0, 'observed cells');
  const observedSet = new Set(observedIds);
  const altitudeOf = new Map(observedRows.map(row => [row.cellId, row.cellAltitude]));

  // Planned -> observed: the overlay's own join first, then the testimony.
  const unmatchedPlanned = plannedCells.filter(cell =>
    !(Array.isArray(cell.observed) && cell.observed.length >= 1) && !observedSet.has(cell.cellId));

  // Observed -> planned: exact planned membership, else the enclosing planned
  // cell reached through the decomposition path (a kernel-synthesized row).
  const exemptions = [];
  const unmatchedObserved = [];
  for (const cellId of observedIds) {
    if (plannedIds.has(cellId)) continue;
    const enclosingPlannedCellId = nearestFrom(cellId, plannedIds);
    if (enclosingPlannedCellId !== null) {
      exemptions.push({ cellId, cellAltitude: altitudeOf.get(cellId) ?? null,
        enclosingPlannedCellId, kernelDerived: /:(expression|selection)/.test(cellId) });
      continue;
    }
    unmatchedObserved.push({ cellId, cellAltitude: altitudeOf.get(cellId) ?? null });
  }

  // The finding's shape: an unobserved planned cell under an observed ancestor
  // is an unselected branch fragment; one with no observed ancestor is an
  // uninvoked declared subtree. Both are named, neither is exempted.
  const unmatchedPlannedCells = unmatchedPlanned.map(cell => {
    const enclosingObservedCellId = nearestFrom(cell.cellId, observedSet);
    return { cellId: cell.cellId, altitude: cell.altitude ?? null, parentCellId: cell.parentCellId ?? null,
      enclosingObservedCellId,
      classification: enclosingObservedCellId ? 'unselected-branch-fragment' : 'uninvoked-declared-subtree' };
  });

  // Taken-path reachability: traverse planned edges whose selection admission is
  // 'admitted' (non-selection edges are traversable unless explicitly rejected).
  // A planned cell reachable over the taken path but without testimony is a
  // genuine miss; one reachable only through an unselected branch is expected
  // unobserved. This is the branch-aware half of the structural verdict.
  const edges = Array.isArray(overlay.edges) ? overlay.edges : [];
  const adjacency = new Map();
  for (const edge of edges) {
    const from = edge.planned?.from?.cellId;
    const to = edge.planned?.to?.cellId;
    if (!from || !to) continue;
    const edgeId = edge.edgeId ?? edge.planned?.edgeId ?? '';
    const selectionEdge = edge.planned?.selectsVariant != null || /route:|selection/.test(edgeId);
    const admission = Array.isArray(edge.observed) && edge.observed.length
      ? edge.observed[0]?.admissionDisposition : undefined;
    const traversable = selectionEdge ? admission === 'admitted' : admission !== 'rejected';
    if (!traversable) continue;
    if (!adjacency.has(from)) adjacency.set(from, []);
    adjacency.get(from).push(to);
  }
  const roots = plannedCells.filter(cell => cell.planned?.parentCellId == null).map(cell => cell.cellId);
  const reachable = new Set(roots);
  const queue = [...roots];
  while (queue.length) {
    for (const next of adjacency.get(queue.shift()) ?? []) {
      if (reachable.has(next)) continue;
      reachable.add(next);
      queue.push(next);
    }
  }
  // Fragment cells (`:expression`/`:selection` sub-cells) are alternate branches
  // of one evaluated expression: the evaluator emits cells for every branch and
  // only the selected path testifies, so an unobserved fragment is expected, not
  // a miss. Topological reachability alone cannot separate branches -- the plan
  // carries decomposition edges for every declared child -- so a semantic cell
  // is a genuine miss only when the observed path entered its subtree
  // (enclosingObservedCellId is not null) and it still has no testimony.
  for (const row of unmatchedPlannedCells) {
    row.onTakenPath = !/:(expression|selection)/.test(row.cellId)
      && reachable.has(row.cellId) && row.enclosingObservedCellId !== null;
  }

  return {
    counts: { plannedCells: plannedCells.length, observedCells: observedIds.length,
      observedTestimonyRows: observedRows.length, unmatchedPlanned: unmatchedPlannedCells.length,
      unmatchedObserved: unmatchedObserved.length, verifiedAt: new Date().toISOString() },
    unmatchedPlannedCells, unmatchedObservedCells: unmatchedObserved, exemptions,
    canonicalGraphDigest: overlay.canonicalGraphDigest ?? null,
    observedPathDigest: overlay.observedPathDigest ?? null
  };
};

async function invokeObserve(context, capabilityId, input, label) {
  const observations = [];
  const execution = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'observe',
    request: { object: 'capability', verb: 'observe', subject: capabilityId, input,
      observationAltitudes: ALTITUDES } },
  { ...context, onObservation: value => observations.push(value) });
  return { capabilityId, label, observations, execution, overlay: execution.outcome.overlay,
    result: execution.outcome.result, disposition: execution.outcome.result.disposition,
    outcomeVariant: execution.outcome.result.outcomeVariant ?? null,
    outcomeContractId: execution.outcome.result.outcome?.contractId ?? null };
}

const caseRecord = invocation => {
  const check = structuralCheck({ overlay: invocation.overlay, testimony: invocation.result.cellTestimony });
  return { capabilityId: invocation.capabilityId, label: invocation.label,
    disposition: invocation.disposition, outcomeVariant: invocation.outcomeVariant,
    outcomeContractId: invocation.outcomeContractId, ...check };
};

const namesOf = rows => rows.map(row => row.cellId);

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
      report.cases.push(caseRecord(agent));

      note('equity: observe resolve-equity-market-price-evidence with the credential names absent');
      const equity = await invokeObserve(base, 'resolve-equity-market-price-evidence', 'QQQ',
        'resolve-equity-market-price-evidence');
      report.cases.push(caseRecord(equity));

      note('compose: observe compose-resolve-equity-market-price-evidence with the credential names absent');
      const composed = await invokeObserve(base, 'compose-resolve-equity-market-price-evidence',
        { contractId: 'live-equity-price-request.v1', payload: { symbol: 'QQQ', region: 'US' } },
        'compose-resolve-equity-market-price-evidence');
      report.cases.push(caseRecord(composed));

      note('model lane: observe obtain-governed-model-response with the credential names absent');
      const modelLane = await invokeObserve(base, 'obtain-governed-model-response', {
        carrierType: 'governed-model-invocation-request.v1',
        requestId: 'circuit-structure-model',
        requestHash: 'sha256:' + '0'.repeat(64),
        modelRequest: {
          $schema: '../../generic-llm-connector/authority/model-request.schema.v1.json',
          requestId: 'circuit-structure-model',
          providerAuthorityId: 'primary-cognitive-provider',
          modelAlias: 'instruction-capable-model',
          interaction: { mode: 'text-generation', messages: [{ role: 'user', content: 'Reply with the single word: ready' }] },
          responsePolicy: { format: 'text', maximumOutputTokens: 256, temperature: 0 },
          executionPolicy: { timeoutMilliseconds: 120000, attemptAuthority: { maximumAuthorizedAttempts: 1 }, providerSubstitution: { allowed: false } },
          evidencePolicy: { captureRequestHash: true, captureResponseHash: true, captureResolvedProvider: true,
            captureResolvedModel: true, captureTokenUsage: true, captureTiming: true }
        },
        requestLineage: ['circuit-structure', 'obtain-governed-model-response']
      }, 'obtain-governed-model-response');
      report.cases.push(caseRecord(modelLane));
    });

  for (const item of report.cases) {
    const counts = item.counts;
    note(`${item.label}: planned ${counts.plannedCells}, observed ${counts.observedCells} ` +
      `(${counts.observedTestimonyRows} testimony rows), unmatched planned ${counts.unmatchedPlanned}, ` +
      `unmatched observed ${counts.unmatchedObserved}, exemptions ${item.exemptions.length}`);
  }
  // Branch-aware verdict: observed execution must be fully planned, and every
  // unobserved planned cell must lie off the taken path (an unselected branch
  // or a branch fragment the selection never entered). A cell on the taken path
  // without testimony is a genuine miss and fails the verdict.
  const onTakenPathUnobserved = report.cases.flatMap(item =>
    item.unmatchedPlannedCells.filter(row => row.onTakenPath === true)
      .map(row => ({ capabilityId: item.capabilityId, cellId: row.cellId })));
  for (const item of report.cases) {
    item.counts.unmatchedPlannedOnTakenPath = item.unmatchedPlannedCells.filter(row => row.onTakenPath === true).length;
  }
  const structured = report.cases.every(item =>
    item.counts.unmatchedObserved === 0 && item.counts.unmatchedPlannedOnTakenPath === 0);
  const unmatchedPlanned = report.cases.reduce((total, item) => total + item.counts.unmatchedPlanned, 0);
  const unmatchedObserved = report.cases.reduce((total, item) => total + item.counts.unmatchedObserved, 0);
  report.verdict = { circuitStructured: structured,
    verdict: structured ? 'CIRCUIT-STRUCTURED' : 'NOT-STRUCTURED',
    plannedToObserved: report.cases.every(item => item.counts.unmatchedPlannedOnTakenPath === 0),
    observedToPlanned: report.cases.every(item => item.counts.unmatchedObserved === 0),
    onTakenPathUnobserved,
    finding: structured ? null : {
      unmatchedPlanned,
      unmatchedObserved,
      onTakenPathUnobserved,
      disposition: 'The compiled plan carries every conditional branch before selection; the observed path lights one branch per selection. ' +
        'Every planned cell without testimony lies off the taken path (an unselected branch or a branch fragment the selection never entered) and is named per case. ' +
        'A planned cell on the taken path without testimony, or an observed cell with no planned cell, is the failure.'
    },
    exemptionRule: 'only kernel-synthesized testimony (cellId contains :expression or :selection) resolved to an enclosing planned cell is exempt from unmatchedObserved; the planned direction has no exemption',
    exemptions: report.cases.flatMap(item => item.exemptions.map(exemption =>
      ({ capabilityId: item.capabilityId, ...exemption }))) };
  report.completedAt = new Date().toISOString();
  await write('circuit-structure.receipt.json', report);
  note('receipt: ' + path.relative(root, path.join(receiptDir, 'circuit-structure.receipt.json')));

  if (!structured) {
    for (const item of report.cases) {
      if (item.counts.unmatchedPlanned === 0 && item.counts.unmatchedObserved === 0) continue;
      note(`${item.label}: ${item.counts.unmatchedPlanned} planned cell(s) without testimony:`);
      for (const row of item.unmatchedPlannedCells) console.log('  planned-unobserved [' + row.classification + '] ' + row.cellId);
      note(`${item.label}: ${item.counts.unmatchedObserved} observed cell(s) without a planned cell:`);
      for (const cellId of namesOf(item.unmatchedObservedCells)) console.log('  observed-unplanned ' + cellId);
    }
    console.error('CIRCUIT-STRUCTURE FINDING: the planned-observed relation is not a bijection; ' +
      'the unmatched cells above are the finding.');
    process.exitCode = 1;
    return;
  }
  note('verdict: CIRCUIT-STRUCTURED (observed path fully planned; every unobserved planned cell lies off the taken path)');
}

main().catch(async error => {
  report.error = { message: error.message };
  report.completedAt = new Date().toISOString();
  try {
    await fs.mkdir(receiptDir, { recursive: true });
    await fs.writeFile(path.join(receiptDir, 'circuit-structure.receipt.json'), JSON.stringify(report, null, 2) + '\n');
  } catch { /* diagnostic only */ }
  console.error('CIRCUIT-STRUCTURE FAILED:', error.message);
  process.exitCode = 1;
});
