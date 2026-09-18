import test from 'node:test';
import assert from 'node:assert/strict';
import { executeDatabaseCommand } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/command-carrier.mjs';
import { COMMAND_OPERATIONS, withDeclaredGroundRead } from './kernel-declared-authority.fixture.mjs';

// Semantic address retirement W4.1: src/semantic-address.mjs is gone. The
// kernel emits the declared semanticAddress on every cell and edge testimony
// (SDA a696fdd), the declared read-observation-projection joins it against the
// declared authority rows in SQL, and the boot neither parses an id nor
// composes an address. These tests hold the boot to that boundary.

const command = (input, verb = 'invoke', extra = {}) => ({ deliveryType: 'sfx-command-delivery.v1', operation: verb,
  request: { object: 'capability', verb, subject: 'example', input, ...extra } });

const identity = { snapshotId: 'snapshot', projectionDigest: 'projection', viewDefinitionDigest: 'views', truncated: false };
// The declared execution authority rows the projection read joins against.
const graph = {
  capabilityId: 'example', rootScenarioId: 'example',
  scenarios: [{ scenarioId: 'example',
    input: { inputId: 'example-request', contract: { contractId: 'example-request.v1' } },
    event: { eventId: 'example-requested', executionAuthorityId: 'example.v1' },
    outcome: { outcomeId: 'example-result', contract: { contractId: 'example-result.v1' }, terminal: true } }],
  executionAuthorities: [{ id: 'example.v1', owningScenarioId: 'example',
    operations: [{ kind: 'invoke-port', portId: 'first-port' }] }],
  interfaceAuthority: { interfaces: [{ kind: 'cli', configuration: {
    readings: [{ reading: 'default', altitudes: ['scenario'] },
      { reading: 'trace', altitudes: ['scenario', 'mechanic', 'provider', 'physical'] }] } }] } };

const canonicalGraph = {
  graphType: 'sda-semantic-execution-graph.v1', graphId: 'example-graph', rootCellId: 'cell:scenario:example',
  cells: [
    { cellId: 'cell:scenario:example', altitude: 'scenario', parentCellId: null, input: { contractId: 'example-request.v1' },
      outcome: { contractId: 'example-result.v1' }, execution: { authorityId: 'example.v1', authorityDigest: 'sha256:s' },
      semanticAddress: 'example/scenario/example' },
    { cellId: 'cell:mechanic:example.operation.1', altitude: 'mechanic', parentCellId: 'cell:scenario:example',
      input: { contractId: 'example-request.v1' }, outcome: { contractId: 'semantic-value.v1' },
      execution: { kind: 'mechanic', authorityId: 'operation:first-port', authorityDigest: 'sha256:a',
        configuration: { kind: 'invoke-port', portId: 'first-port' } },
      sourcePointers: ['executionAuthorities/example/operations/0'],
      semanticAddress: 'example/scenario/example/operation/example.operation.1' },
    { cellId: 'cell:mechanic:example.operation.1:expression.fields.value', altitude: 'mechanic',
      parentCellId: 'cell:mechanic:example.operation.1', input: { contractId: 'semantic-value.v1' },
      outcome: { contractId: 'semantic-value.v1' },
      execution: { kind: 'mechanic', authorityId: 'mechanic:literal.v1', authorityDigest: 'sha256:b',
        configuration: { op: 'literal', value: 7 } },
      semanticAddress: 'example-transformation#/expression/fields/value' }
  ],
  edges: []
};
const cell = (cellId, address, order) => ({ testimonyType: 'cell-execution-testimony.v1', cellId,
  cellAltitude: 'mechanic', semanticAddress: address, cellExecutionId: `exec:${order}`, rootExecutionId: 'root',
  parentCellExecutionId: 'exec:0', outcomeContractId: 'semantic-value.v1', outcomeVariant: 'VALUE',
  disposition: 'completed', selectedEdgeIds: [], logicalOrder: order, durationMilliseconds: order,
  display: { entry: { status: 'completed', text: address } } });
const cells = [
  cell('cell:mechanic:example.operation.1', 'example/scenario/example/operation/example.operation.1', 1),
  cell('cell:mechanic:example.operation.1:expression.fields.value', 'example-transformation#/expression/fields/value', 2),
  { ...cell('cell:scenario:example', 'example/scenario/example', 3), cellAltitude: 'scenario', outcomeContractId: 'example-result.v1' }
];

const moduleUrl = source => 'data:text/javascript,' + encodeURIComponent(source);
const compileModule = moduleUrl(`export const compile = async (_, input) => ({ canonicalGraph: ${JSON.stringify(canonicalGraph)},
  canonicalGraphDigest: 'sha256:plan', realizationOverlay: { physicalCells: [], physicalEdges: [] }, input: input.input });`);
const executeModule = moduleUrl(`export const execute = async (_, plan, context) => {
  if (plan.input && plan.input.contractId === 'observation-projection-request.v1') {
    return { disposition: 'completed', cellTestimony: [], edgeTestimony: [],
      outcome: { projectionType: 'observation-projection.v1',
        overlay: { graphId: 'example-graph', received: plan.input, cells: [], edges: [], counts: {} },
        story: { scenario: { scenarioId: 'example', responsibilities: [] } } } };
  }
  const cells = ${JSON.stringify(cells)};
  if (typeof context.onTestimony === 'function') for (const item of cells) context.onTestimony(item);
  return { disposition: 'completed', outcome: { value: 7 }, cellTestimony: cells, edgeTestimony: [], observedPathDigest: 'sha256:observed' };
};`);

const executor = { capabilityId: 'run-declared-graph', scenarios: [],
  executionAuthorities: [{ owningScenarioId: 'executor', operations: [
    { kind: 'invoke-port', portId: 'compile' }, { kind: 'invoke-port', portId: 'execute' }] }],
  interfaceAuthority: { portBindings: [
    { portId: 'compile', configuration: { estateProvider: { module: compileModule, export: 'compile' } } },
    { portId: 'execute', configuration: { estateProvider: { module: executeModule, export: 'execute' } } }] } };

function context() {
  const observations = [];
  return { databaseRoot: 'unused', observations, commandOperations: COMMAND_OPERATIONS,
    onObservation: observation => observations.push(observation),
    resolveMechanic: async binding => {
      const provider = binding?.configuration?.estateProvider;
      if (!provider || typeof provider.module !== 'string' || typeof provider.export !== 'string') return null;
      const module = await import(provider.module);
      return typeof module[provider.export] === 'function' ? module[provider.export] : null;
    },
    readQuery: withDeclaredGroundRead(async () => ({ ...identity, recordsets: [[{ provider_id: 'delivery',
      configuration: JSON.stringify({ capabilityId: 'run-declared-graph', requestExpression: {}, resultExpression: {} }) }],
      [{ default_target: 'node' }]] })),
    readAuthority: async selection => ({ selection,
      authority: { ...identity, recordsets: [[{ scenario_id: selection.capabilityId === 'run-declared-graph' ? 'executor' : 'example' }]] },
      closure: { recordsets: [[]] }, graphSource: structuredClone(selection.capabilityId === 'run-declared-graph' ? executor : graph) }) };
}

test('observe streams the kernel semantic address and display entry without estate address computation', async () => {
  const config = context();
  const observed = await executeDatabaseCommand(command({ value: 7 }, 'observe',
    { observationAltitudes: ['scenario', 'mechanic', 'provider', 'physical'] }), config);
  const testimony = config.observations.filter(o => o.testimonyType?.endsWith('-execution-testimony.v1'));
  assert.deepEqual(testimony.map(o => o.semanticAddress),
    ['example/scenario/example/operation/example.operation.1', 'example-transformation#/expression/fields/value',
      'example/scenario/example']);
  // Kernel fields only: no estate-computed address members ride the stream.
  for (const event of testimony)
    for (const field of ['semanticRole', 'responsibilityId', 'responsibilityKind', 'responsibilityOrdinal',
      'mechanicId', 'mechanicPath', 'scenarioId', 'inputId', 'eventId', 'outcomeId'])
      assert.equal(event[field], undefined, field);
  // The terminal's declared entry is the kernel's; the boot composes no text.
  assert.deepEqual(testimony[1].display, { entry: { status: 'completed', text: 'example-transformation#/expression/fields/value' } });
  assert.ok(typeof testimony[0].observedAt === 'string');
  // The story is the declared projection's value, not a boot-side join.
  assert.equal(observed.outcome.story.scenario.scenarioId, 'example');
});

test('the declared projection receives the plan, the declared authority rows and the testimony', async () => {
  const observed = await executeDatabaseCommand(command({ value: 7 }, 'observe', { observationAltitudes: ['scenario'] }), context());
  const received = observed.outcome.overlay.received.payload;
  assert.equal(received.capabilityId, 'example');
  assert.equal(received.scenarioId, 'example');
  assert.equal(received.scenarios[0].scenarioId, 'example');
  assert.equal(received.executionAuthorities[0].owningScenarioId, 'example');
  assert.equal(received.plan.canonicalGraph.cells.length, 3);
  assert.deepEqual(received.cellTestimony.map(item => item.semanticAddress),
    ['example/scenario/example/operation/example.operation.1', 'example-transformation#/expression/fields/value',
      'example/scenario/example']);
});

test('invoke takes neither the projection nor the testimony stream', async () => {
  const config = context();
  const invoked = await executeDatabaseCommand(command({ value: 7 }), config);
  assert.equal(invoked.outcome.story, undefined);
  assert.equal(invoked.outcome.overlay, undefined);
  assert.equal(config.observations.some(o => o.testimonyType?.endsWith('-execution-testimony.v1')), false);
});
