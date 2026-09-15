import test from 'node:test';
import assert from 'node:assert/strict';
import { validateDatabaseCommand, executeDatabaseCommand } from '../src/invoke-database-capability.mjs';
import { isObservationAltitudeSelection } from '../src/execution-drilldown.mjs';
import { safeObservation } from '../src/observation-filter.mjs';

const command = (input, verb = 'invoke', extra = {}) => ({ deliveryType: 'sfx-command-delivery.v1', operation: verb,
  request: { object: 'capability', verb, subject: 'example', input, ...extra } });

test('observation altitudes are validated only where the operation offers them', () => {
  const observe = altitude => command(null, 'observe', { observationAltitudes: altitude });
  assert.deepEqual(validateDatabaseCommand(observe(['scenario', 'physical'])).observationAltitudes, ['scenario', 'physical']);
  assert.deepEqual(validateDatabaseCommand(observe(['scenario', 'mechanic', 'provider', 'physical'])).observationAltitudes,
    ['scenario', 'mechanic', 'provider', 'physical']);
  assert.equal(isObservationAltitudeSelection(['edges']), false);
  assert.throws(() => validateDatabaseCommand(observe([])), /CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(observe(['scenario', 'scenario'])), /CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(observe(['edges'])), /CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(observe('scenario')), /CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(command(null, 'invoke', { observationAltitudes: ['scenario'] })), /DATABASE_COMMAND_REJECTED/);
});

test('the observation filter carries testimony fields and keeps inputs and bodies out', () => {
  const safe = safeObservation({ observationType: 'cell-execution-testimony.v1', phase: 'executeDeclaredGraph',
    status: 'observed', observedAt: '2026-01-01T00:00:00.000Z', executionId: 'exec:1', rootExecutionId: 'root:1',
    parentExecutionId: null, scenarioId: 'root', stepId: 'step', sequence: 0, cellId: 'cell:scenario',
    cellAltitude: 'scenario', edgeId: undefined, durationMilliseconds: 5, startedAt: '2026-01-01T00:00:00.000Z',
    completedAt: '2026-01-01T00:00:00.005Z', input: { secret: 1 }, body: 'secret', token: 'abc' });
  assert.deepEqual(safe, { observationType: 'cell-execution-testimony.v1', phase: 'executeDeclaredGraph',
    status: 'observed', observedAt: '2026-01-01T00:00:00.000Z', executionId: 'exec:1', rootExecutionId: 'root:1',
    parentExecutionId: null, scenarioId: 'root', stepId: 'step', sequence: 0, cellId: 'cell:scenario',
    cellAltitude: 'scenario', durationMilliseconds: 5, startedAt: '2026-01-01T00:00:00.000Z',
    completedAt: '2026-01-01T00:00:00.005Z' });
});

const identity = { snapshotId: 'snapshot', projectionDigest: 'projection', viewDefinitionDigest: 'views', truncated: false };
const graph = { capabilityId: 'example', scenarios: [], executionAuthorities: [], interfaceAuthority: { interfaces: [] } };
const canonicalGraph = {
  graphType: 'sda-semantic-execution-graph.v1', graphId: 'example-graph', rootCellId: 'cell:scenario',
  cells: [
    { cellId: 'cell:scenario', altitude: 'scenario', parentCellId: null, input: { contractId: 'in.v1' },
      outcome: { contractId: 'out.v1' }, execution: { authorityId: 'auth:scenario', authorityDigest: 'sha256:a' } },
    { cellId: 'cell:provider', altitude: 'provider', parentCellId: 'cell:scenario', input: { contractId: 'in2.v1' },
      outcome: { contractId: 'out2.v1' }, execution: { authorityId: 'auth:provider', authorityDigest: 'sha256:b' } }
  ],
  edges: [{ edgeId: 'edge:one', kind: 'sequence', from: { cellId: 'cell:scenario', portId: 'out' },
    to: { cellId: 'cell:provider', portId: 'in' }, edgeContractId: 'e.v1', authorityDigest: 'sha256:e' }]
};
const cellScenario = { testimonyType: 'cell-execution-testimony.v1', cellId: 'cell:scenario', cellAltitude: 'scenario',
  cellExecutionId: 'exec:1', rootExecutionId: 'root:1', parentCellExecutionId: null, outcomeContractId: 'out.v1',
  outcomeVariant: 'ok', disposition: 'completed', selectedEdgeIds: ['edge:one'], logicalOrder: 0,
  startedAt: '2026-01-01T00:00:00.000Z', completedAt: '2026-01-01T00:00:00.005Z', durationMilliseconds: 5 };
const cellProvider = { ...cellScenario, cellId: 'cell:provider', cellAltitude: 'provider', cellExecutionId: 'exec:2',
  parentCellExecutionId: 'exec:1', outcomeVariant: 'done', selectedEdgeIds: [], logicalOrder: 2, durationMilliseconds: 7 };
const edgeOne = { testimonyType: 'edge-execution-testimony.v1', edgeId: 'edge:one', sourceCellExecutionId: 'exec:1',
  destinationCellId: 'cell:provider', admissionDisposition: 'admitted', logicalOrder: 1,
  startedAt: '2026-01-01T00:00:00.004Z', completedAt: '2026-01-01T00:00:00.006Z', durationMilliseconds: 2 };

const moduleUrl = source => 'data:text/javascript,' + encodeURIComponent(source);
const compileModule = moduleUrl(`export const compile = async (_, input) => ({ canonicalGraph: ${JSON.stringify(canonicalGraph)},
  canonicalGraphDigest: 'sha256:plan', realizationOverlay: { physicalCells: [], physicalEdges: [] }, input: input.input });`);
const executeModule = stream => moduleUrl(`export const execute = async (_, plan, context) => {
  const cells = ${JSON.stringify([cellScenario, cellProvider])};
  const edges = ${JSON.stringify([edgeOne])};
  if (${stream} && typeof context.onTestimony === 'function') { for (const cell of cells) context.onTestimony(cell); for (const edge of edges) context.onTestimony(edge); }
  return { disposition: 'completed', outcome: plan.input, outcomeVariant: 'done',
    cellTestimony: cells, edgeTestimony: edges, observedPathDigest: 'sha256:observed' };
};`);

const executor = stream => ({ capabilityId: 'run-declared-graph',
  executionAuthorities: [{ owningScenarioId: 'executor', operations: [
    { kind: 'invoke-port', portId: 'compile' }, { kind: 'invoke-port', portId: 'execute' }] }],
  interfaceAuthority: { portBindings: [
    { portId: 'compile', configuration: { estateProvider: { module: compileModule, export: 'compile' } } },
    { portId: 'execute', configuration: { estateProvider: { module: executeModule(stream), export: 'execute' } } }] } });

function context({ stream = true } = {}) {
  const reads = [], observations = [];
  return { databaseRoot: 'unused', reads, observations,
    onObservation: observation => observations.push(observation),
    readQuery: async () => ({ ...identity, recordsets: [[{ provider_id: 'delivery',
      configuration: JSON.stringify({ capabilityId: 'run-declared-graph', requestExpression: {}, resultExpression: {} }) }],
      [{ default_target: 'node' }]] }),
    readAuthority: async (_, selection) => {
      reads.push(selection);
      const isExecutor = selection.capabilityId === 'run-declared-graph';
      return { selection, authority: { ...identity, recordsets: [[{ scenario_id: isExecutor ? 'executor' : 'root' }]] },
        closure: { recordsets: [[]] }, graphSource: structuredClone(isExecutor ? executor(stream) : graph) };
    } };
}

test('observe streams only the selected altitudes and joins the plan against the observed path', async () => {
  const config = context();
  const result = await executeDatabaseCommand(command({ value: 7 }, 'observe', { observationAltitudes: ['scenario'] }), config);
  const testimony = config.observations.filter(o => o.observationType.endsWith('-execution-testimony.v1'));
  assert.deepEqual(testimony.map(o => [o.observationType, o.cellId ?? o.edgeId, o.cellAltitude, o.durationMilliseconds]),
    [['cell-execution-testimony.v1', 'cell:scenario', 'scenario', 5]]);
  assert.ok(config.observations.some(o => o.phase === 'executeDeclaredGraph' && o.status === 'completed'));

  const overlay = result.outcome.overlay;
  assert.equal(overlay.graphId, 'example-graph');
  assert.equal(overlay.canonicalGraphDigest, 'sha256:plan');
  assert.equal(overlay.observedPathDigest, 'sha256:observed');
  assert.deepEqual(overlay.counts, { plannedCells: 2, observedCells: 2, plannedEdges: 1, observedEdges: 1 });
  assert.deepEqual(overlay.cells.map(cell => [cell.cellId, cell.observed.length]), [['cell:scenario', 1], ['cell:provider', 1]]);
  assert.equal(overlay.cells[0].observed[0].disposition, 'completed');
  assert.deepEqual(overlay.cells[0].observed[0].selectedEdgeIds, ['edge:one']);
  assert.equal(overlay.cells[0].observed[0].completedAt, '2026-01-01T00:00:00.005Z');
  assert.equal(overlay.edges[0].observed[0].admissionDisposition, 'admitted');
  assert.equal(overlay.edges[0].observed[0].durationMilliseconds, 2);
  assert.equal(result.outcome.observedPathDigest, 'sha256:observed');
  assert.equal(result.outcome.evidence.observedPathDigest, 'sha256:observed');
});

test('the whole altitude range streams every cell and edge and absorbs silent kernel testimony', async () => {
  for (const stream of [true, false]) {
    const config = context({ stream });
    const result = await executeDatabaseCommand(command({ value: 7 }, 'observe', { observationAltitudes: ['scenario', 'mechanic', 'provider', 'physical'] }), config);
    const cells = result.outcome.overlay.cells;
    const edges = result.outcome.overlay.edges;
    assert.deepEqual(cells.map(cell => cell.observed.length), [1, 1]);
    assert.deepEqual(edges.map(edge => edge.observed.length), [1]);
    if (stream) {
      const testimony = config.observations.filter(o => o.observationType.endsWith('-execution-testimony.v1'));
      assert.equal(testimony.filter(o => o.observationType === 'cell-execution-testimony.v1').length, 2);
      assert.equal(testimony.filter(o => o.observationType === 'edge-execution-testimony.v1').length, 1);
    }
  }
});

test('invoke keeps its default output and does not stream or overlay', async () => {
  const config = context();
  const result = await executeDatabaseCommand(command({ value: 7 }), config);
  assert.equal(result.outcome.overlay, undefined);
  assert.equal(result.outcome.observedPathDigest, undefined);
  assert.equal(result.outcome.evidence.observedPathDigest, undefined);
  assert.equal(config.observations.some(o => o.observationType.endsWith('-execution-testimony.v1')), false);
  assert.deepEqual(result.outcome.result.outcome, { value: 7 });
});
