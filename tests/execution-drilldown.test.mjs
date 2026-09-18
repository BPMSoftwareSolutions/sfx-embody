import test from 'node:test';
import assert from 'node:assert/strict';
import { validateDatabaseCommand, executeDatabaseCommand, createObservationFilter } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/command-carrier.mjs';

// Observation retirement W4.1: the drilldown module is gone. The stream is the
// kernel's declared testimony, scoped by the interface's declared readings; the
// overlay and story are the declared read-observation-projection value. These
// tests hold the boot to the declaration: no altitude vocabulary, no address
// join and no entry composition lives in the estate runtime.

const command = (input, verb = 'invoke', extra = {}) => ({ deliveryType: 'sfx-command-delivery.v1', operation: verb,
  request: { object: 'capability', verb, subject: 'example', input, ...extra } });

// The declared observation telemetry authority
// (sql/migrations/declare-observation-telemetry-authority.sql): the seam reads
// the members from this document; no field name is code.
const DECLARED_TELEMETRY = {
  authorityType: 'observation-telemetry-authority.v1',
  observationFields: ['observationType', 'phase', 'status', 'observedAt', 'executionId', 'rootExecutionId',
    'parentExecutionId', 'scenarioId', 'stepId', 'sequence', 'cellId', 'cellAltitude', 'edgeId',
    'durationMilliseconds', 'startedAt', 'completedAt', 'semanticRole', 'responsibilityId', 'responsibilityKind',
    'responsibilityOrdinal', 'mechanicId', 'mechanicPath', 'childScenarioId', 'parentScenarioId', 'inputId', 'eventId',
    'outcomeId', 'outcomeContractId', 'sourceCellId', 'destinationCellId', 'admissionDisposition'],
  entryFields: ['status', 'text', 'note', 'admission', 'timing'],
  objectFields: { providerEvidence: ['reachedStage', 'exchangeCount', 'transportDisposition', 'redactionVerified',
    'httpStatus'], display: ['entry'] }
};

test('the observation altitude request is shape-validated before the interface is read', () => {
  const observe = altitude => command(null, 'observe', { observationAltitudes: altitude });
  assert.deepEqual(validateDatabaseCommand(observe(['scenario', 'physical'])).observationAltitudes, ['scenario', 'physical']);
  assert.deepEqual(validateDatabaseCommand(observe(['scenario', 'mechanic', 'provider', 'physical'])).observationAltitudes,
    ['scenario', 'mechanic', 'provider', 'physical']);
  assert.throws(() => validateDatabaseCommand(observe([])), /CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(observe(['scenario', 'scenario'])), /CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(observe([1])), /CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(observe('scenario')), /CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED/);
  assert.throws(() => validateDatabaseCommand(command(null, 'invoke', { observationAltitudes: ['scenario'] })), /DATABASE_COMMAND_REJECTED/);
});

test('the declared observation filter carries the bounded httpStatus and keeps other provider evidence out', () => {
  const filter = createObservationFilter(DECLARED_TELEMETRY);
  const safe = filter({ observationType: 'cell-execution-testimony.v1',
    providerEvidence: { reachedStage: 'response-complete', exchangeCount: 1, transportDisposition: 'completed',
      redactionVerified: true, httpStatus: 429, responseBodyBytes: 'c2VjcmV0', secret: 'x' } });
  assert.deepEqual(safe.providerEvidence, { reachedStage: 'response-complete', exchangeCount: 1,
    transportDisposition: 'completed', redactionVerified: true, httpStatus: 429 });
});

test('the declared observation filter selects only the declared members, never a built-in field list', () => {
  const narrowed = createObservationFilter({
    observationFields: ['cellId', 'durationMilliseconds'],
    entryFields: ['status'],
    objectFields: { providerEvidence: ['exchangeCount'], display: ['entry'] } });
  const safe = narrowed({ observationType: 'cell-execution-testimony.v1', cellId: 'cell:scenario',
    durationMilliseconds: 5, disposition: 'completed',
    providerEvidence: { exchangeCount: 0, httpStatus: 429 },
    display: { entry: { status: 'completed', text: 'declared', timing: '5 ms' } } });
  assert.deepEqual(safe, { cellId: 'cell:scenario', durationMilliseconds: 5,
    display: { entry: { status: 'completed' } }, providerEvidence: { exchangeCount: 0 } });
});

test('an unresolved observation telemetry authority refuses the channel', () => {
  assert.throws(() => createObservationFilter({}), /OBSERVATION_TELEMETRY_AUTHORITY_NOT_RESOLVED/);
  assert.throws(() => createObservationFilter(null), /OBSERVATION_TELEMETRY_AUTHORITY_NOT_RESOLVED/);
  assert.throws(() => createObservationFilter({ observationFields: [], entryFields: [], objectFields: {} }),
    /OBSERVATION_TELEMETRY_AUTHORITY_NOT_RESOLVED/);
});

const identity = { snapshotId: 'snapshot', projectionDigest: 'projection', viewDefinitionDigest: 'views', truncated: false };
const graph = { capabilityId: 'example', scenarios: [], executionAuthorities: [],
  interfaceAuthority: { interfaces: [{ kind: 'cli', configuration: {
    readings: [{ reading: 'default', altitudes: ['scenario'] },
      { reading: 'trace', altitudes: ['scenario', 'mechanic', 'provider', 'physical'] }] } }] } };
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
// The kernel testimony the declaration consumes: the display entry and the
// semantic address are the kernel's declared fields, carried verbatim.
const cellScenario = { testimonyType: 'cell-execution-testimony.v1', cellId: 'cell:scenario', cellAltitude: 'scenario',
  cellExecutionId: 'exec:1', rootExecutionId: 'root:1', parentCellExecutionId: null, outcomeContractId: 'out.v1',
  outcomeVariant: 'ok', disposition: 'completed', semanticAddress: 'example/scenario/example',
  display: { entry: { status: 'completed', text: 'example/scenario/example' } },
  providerEvidence: { transportDisposition: 'denied', httpStatus: 429 },
  selectedEdgeIds: ['edge:one'], logicalOrder: 0,
  startedAt: '2026-01-01T00:00:00.000Z', completedAt: '2026-01-01T00:00:00.005Z', durationMilliseconds: 5 };
const cellProvider = { ...cellScenario, cellId: 'cell:provider', cellAltitude: 'provider', cellExecutionId: 'exec:2',
  parentCellExecutionId: 'exec:1', outcomeVariant: 'done', selectedEdgeIds: [], logicalOrder: 2, durationMilliseconds: 7,
  semanticAddress: 'example/scenario/example/provider', display: { entry: { status: 'completed', text: 'example/scenario/example/provider' } } };
const edgeOne = { testimonyType: 'edge-execution-testimony.v1', edgeId: 'edge:one', sourceCellExecutionId: 'exec:1',
  destinationCellId: 'cell:provider', admissionDisposition: 'admitted', logicalOrder: 1,
  semanticAddress: 'example/scenario/example/provider',
  display: { entry: { status: 'completed', text: 'example/scenario/example/provider', admission: 'admitted' } },
  startedAt: '2026-01-01T00:00:00.004Z', completedAt: '2026-01-01T00:00:00.006Z', durationMilliseconds: 2 };

const moduleUrl = source => 'data:text/javascript,' + encodeURIComponent(source);
// The declared read-observation-projection value, returned by the fake
// declared read; the boot attaches it without shaping it.
const PROJECTION = { projectionType: 'observation-projection.v1',
  overlay: { graphId: 'example-graph', canonicalGraphDigest: 'sha256:plan', observedPathDigest: 'sha256:observed',
    cells: [{ cellId: 'cell:scenario', altitude: 'scenario', semanticAddress: { semanticRole: 'SCENARIO_OUTCOME' }, observed: [] }],
    edges: [], counts: { plannedCells: 2, observedCells: 2, plannedEdges: 1, observedEdges: 1 } },
  story: { scenario: { scenarioId: 'example', responsibilities: [] }, observedPathDigest: 'sha256:observed' } };
const compileModule = moduleUrl(`export const compile = async (_, input) => ({ canonicalGraph: ${JSON.stringify(canonicalGraph)},
  canonicalGraphDigest: 'sha256:plan', realizationOverlay: { physicalCells: [], physicalEdges: [] }, input: input.input });`);
const executeModule = moduleUrl(`export const execute = async (_, plan, context) => {
  if (plan.input && plan.input.contractId === 'observation-projection-request.v1') {
    return { disposition: 'completed', outcome: ${JSON.stringify(PROJECTION)}, cellTestimony: [], edgeTestimony: [], observedPathDigest: 'sha256:projection' };
  }
  const cells = ${JSON.stringify([cellScenario, cellProvider])};
  const edges = ${JSON.stringify([edgeOne])};
  if (typeof context.onTestimony === 'function') { for (const cell of cells) context.onTestimony(cell); for (const edge of edges) context.onTestimony(edge); }
  return { disposition: 'completed', outcome: plan.input, outcomeVariant: 'done',
    cellTestimony: cells, edgeTestimony: edges, observedPathDigest: 'sha256:observed' };
};`);

const executor = { capabilityId: 'run-declared-graph',
  executionAuthorities: [{ owningScenarioId: 'executor', operations: [
    { kind: 'invoke-port', portId: 'compile' }, { kind: 'invoke-port', portId: 'execute' }] }],
  interfaceAuthority: { portBindings: [
    { portId: 'compile', configuration: { estateProvider: { module: compileModule, export: 'compile' } } },
    { portId: 'execute', configuration: { estateProvider: { module: executeModule, export: 'execute' } } }] } };

function context() {
  const reads = [], observations = [];
  return { databaseRoot: 'unused', reads, observations,
    onObservation: observation => observations.push(observation),
    resolveMechanic: async binding => {
      const provider = binding?.configuration?.estateProvider;
      if (!provider || typeof provider.module !== 'string' || typeof provider.export !== 'string') return null;
      const module = await import(provider.module);
      return typeof module[provider.export] === 'function' ? module[provider.export] : null;
    },
    readQuery: async () => ({ ...identity, recordsets: [[{ provider_id: 'delivery',
      configuration: JSON.stringify({ capabilityId: 'run-declared-graph', requestExpression: {}, resultExpression: {} }) }],
      [{ default_target: 'node' }]] }),
    readAuthority: async selection => {
      reads.push(selection);
      const isExecutor = selection.capabilityId === 'run-declared-graph';
      return { selection, authority: { ...identity, recordsets: [[{ scenario_id: isExecutor ? 'executor' : 'root' }]] },
        closure: { recordsets: [[]] }, graphSource: structuredClone(isExecutor ? executor : graph) };
    } };
}

test('observe streams only the selected altitudes from the declared testimony', async () => {
  const config = context();
  const result = await executeDatabaseCommand(command({ value: 7 }, 'observe', { observationAltitudes: ['scenario'] }), config);
  const testimony = config.observations.filter(o => o.testimonyType?.endsWith('-execution-testimony.v1'));
  assert.deepEqual(testimony.map(o => [o.testimonyType, o.cellId ?? o.edgeId, o.cellAltitude, o.durationMilliseconds]),
    [['cell-execution-testimony.v1', 'cell:scenario', 'scenario', 5]]);
  assert.ok(typeof config.observations[0].observedAt === 'string');
  assert.ok(config.observations.some(o => o.phase === 'executeDeclaredGraph' && o.status === 'completed'));
  // The streamed fields are the kernel's declared fields, carried verbatim.
  assert.deepEqual(testimony[0].display, { entry: { status: 'completed', text: 'example/scenario/example' } });
  assert.equal(testimony[0].semanticAddress, 'example/scenario/example');
  // The overlay and story are the declared projection's value, attached as delivered.
  assert.deepEqual(result.outcome.overlay, PROJECTION.overlay);
  assert.deepEqual(result.outcome.story, PROJECTION.story);
  assert.equal(result.outcome.observedPathDigest, 'sha256:observed');
  assert.equal(result.outcome.evidence.observedPathDigest, 'sha256:observed');
});

test('the whole altitude range streams every cell and edge', async () => {
  const config = context();
  await executeDatabaseCommand(command({ value: 7 }, 'observe',
    { observationAltitudes: ['scenario', 'mechanic', 'provider', 'physical'] }), config);
  const testimony = config.observations.filter(o => o.testimonyType?.endsWith('-execution-testimony.v1'));
  assert.equal(testimony.filter(o => o.testimonyType === 'cell-execution-testimony.v1').length, 2);
  assert.equal(testimony.filter(o => o.testimonyType === 'edge-execution-testimony.v1').length, 1);
  const evidenced = config.observations.filter(o => o.providerEvidence);
  assert.equal(evidenced.length, 2);
  assert.equal(evidenced[0].providerEvidence.httpStatus, 429);
});

test('an altitude the declared readings do not name is refused', async () => {
  await assert.rejects(executeDatabaseCommand(command({ value: 7 }, 'observe', { observationAltitudes: ['scenario', 'edges'] }), context()),
    /CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED/);
});

test('invoke keeps its default output and does not stream or project', async () => {
  const config = context();
  const result = await executeDatabaseCommand(command({ value: 7 }), config);
  assert.equal(result.outcome.overlay, undefined);
  assert.equal(result.outcome.story, undefined);
  assert.equal(result.outcome.observedPathDigest, undefined);
  assert.equal(result.outcome.evidence.observedPathDigest, undefined);
  assert.equal(config.observations.some(o => o.testimonyType?.endsWith('-execution-testimony.v1')), false);
  assert.deepEqual(result.outcome.result.outcome, { value: 7 });
  // The declared projection is read only for observation.
  assert.equal(config.reads.some(selection => selection.capabilityId === 'read-observation-projection'), false);
});
