import test from 'node:test';
import assert from 'node:assert/strict';
import { buildObservedStory, createSemanticAuthority, semanticAddress } from '../src/semantic-address.mjs';
import { createExecutionDrilldown } from '../src/execution-drilldown.mjs';
import { executeDatabaseCommand } from '../src/invoke-database-capability.mjs';

const graph = {
  capabilityId: 'example', rootScenarioId: 'example',
  scenarios: [{ scenarioId: 'example',
    input: { inputId: 'example-request', contract: { contractId: 'example-request.v1' } },
    event: { eventId: 'example-requested', executionAuthorityId: 'example.v1' },
    outcome: { outcomeId: 'example-result', contract: { contractId: 'example-result.v1' }, terminal: true } },
    { scenarioId: 'child',
      input: { inputId: 'child-request', contract: { contractId: 'child-request.v1' } },
      event: { eventId: 'child-requested', executionAuthorityId: 'child.v1' },
      outcome: { outcomeId: 'child-result', contract: { contractId: 'child-result.v1' }, terminal: true } }],
  executionAuthorities: [
    { id: 'example.v1', owningScenarioId: 'example', operations: [
      { operationId: 'example.1', kind: 'invoke-port', portId: 'first-port' },
      { operationId: 'example.2', kind: 'invoke-scenario', scenarioId: 'child' },
      { operationId: 'example.3', kind: 'invoke-port', portId: 'third-port' }] },
    { id: 'child.v1', owningScenarioId: 'child', operations: [
      { operationId: 'child.1', kind: 'invoke-port', portId: 'child-port' }] }]
};

test('a cell addresses to its declared scenario, responsibility and mechanic', () => {
  const authority = createSemanticAuthority(graph);
  assert.deepEqual(semanticAddress(authority, 'cell:scenario:example', null), {
    scenarioId: 'example', parentScenarioId: null, semanticRole: 'SCENARIO_OUTCOME',
    inputId: 'example-request', eventId: 'example-requested', outcomeId: 'example-result', outcomeContractId: 'example-result.v1' });
  assert.deepEqual(semanticAddress(authority, 'cell:mechanic:example.operation.2', null), {
    scenarioId: 'example', parentScenarioId: null, semanticRole: 'EXECUTION_RESPONSIBILITY',
    responsibilityId: 'child', responsibilityKind: 'invoke-scenario', responsibilityOrdinal: 2,
    inputId: null, eventId: null, outcomeId: null, outcomeContractId: null });
  assert.deepEqual(semanticAddress(authority, 'cell:mechanic:example.operation.3:expression.fields.value', 'object'), {
    scenarioId: 'example', parentScenarioId: null, semanticRole: 'MECHANIC',
    responsibilityId: 'third-port', responsibilityKind: 'invoke-port', responsibilityOrdinal: 3,
    inputId: null, eventId: null, outcomeId: null, outcomeContractId: null, mechanicId: 'object',
    mechanicPath: 'value' });
  // A composed child names its own scenario and its declared parent.
  assert.equal(semanticAddress(authority, 'cell:mechanic:child.operation.1', null).parentScenarioId, 'example');
  assert.equal(semanticAddress(authority, 'cell:scenario:child', null).parentScenarioId, 'example');
  // Nothing is invented for a cell the declaration does not name.
  assert.equal(semanticAddress(authority, 'cell:provider:unknown', null), null);
  assert.equal(semanticAddress(authority, 'cell:mechanic:absent.operation.1', null).responsibilityId, null);
});

test('a mechanic address carries the declared expression path it computed', () => {
  const authority = createSemanticAuthority(graph);
  const address = semanticAddress(authority, 'cell:mechanic:example.operation.3:expression.fields.requestUrl.values.symbol', 'format');
  assert.deepEqual([address.mechanicId, address.mechanicPath, address.responsibilityId],
    ['format', 'requestUrl.symbol', 'third-port']);
  const indexed = semanticAddress(createSemanticAuthority({ executionAuthorities: [{ owningScenarioId: 'example', operations: [
    { kind: 'invoke-port', portId: 'port' }] }], scenarios: [] }),
  'cell:mechanic:example.operation.1:expression.bindings.requiredValues.items.2', 'array');
  assert.equal(indexed.mechanicPath, 'requiredValues[2]');
});

test('an edge observation names its source, destination and admission', () => {
  const observed = [];
  const drilldown = createExecutionDrilldown({ scenarioId: 'example', observe: value => observed.push(value),
    authority: graph, observationAltitudes: ['mechanic'] });
  drilldown.setPlan({ canonicalGraph: { graphId: 'example-graph', cells: [
    { cellId: 'cell:mechanic:example.operation.1', altitude: 'mechanic', parentCellId: 'cell:scenario:example' },
    { cellId: 'cell:mechanic:example.operation.1:expression.fields.value', altitude: 'mechanic',
      parentCellId: 'cell:mechanic:example.operation.1' }], edges: [
    { edgeId: 'edge:one', kind: 'sequence', from: { cellId: 'cell:mechanic:example.operation.1' },
      to: { cellId: 'cell:mechanic:example.operation.1:expression.fields.value' } }] } });
  drilldown.sink({ testimonyType: 'edge-execution-testimony.v1', edgeId: 'edge:one',
    destinationCellId: 'cell:mechanic:example.operation.1:expression.fields.value', sourceCellExecutionId: 'exec:1',
    admissionDisposition: 'admitted', logicalOrder: 0, durationMilliseconds: 2 });
  assert.deepEqual(observed.map(({ sourceCellId, destinationCellId, admissionDisposition, mechanicId, mechanicPath }) =>
    ({ sourceCellId, destinationCellId, admissionDisposition, mechanicId, mechanicPath })), [{
    sourceCellId: 'cell:mechanic:example.operation.1',
    destinationCellId: 'cell:mechanic:example.operation.1:expression.fields.value',
    admissionDisposition: 'admitted', mechanicId: undefined, mechanicPath: 'value' }]);
});

test('a scenario cell sharing an execution id with its operation keeps its own observed summary', () => {
  const drilldown = createExecutionDrilldown({ scenarioId: 'example', observe: () => {}, authority: graph,
    observationAltitudes: ['scenario', 'mechanic'] });
  const operation = { testimonyType: 'cell-execution-testimony.v1', cellId: 'cell:mechanic:example.operation.1',
    cellAltitude: 'mechanic', cellExecutionId: 'exec:shared', disposition: 'completed', outcomeVariant: 'SUCCESS', logicalOrder: 0 };
  const scenario = { ...operation, cellId: 'cell:scenario:example', cellAltitude: 'scenario', logicalOrder: 1 };
  drilldown.absorb({ cellTestimony: [operation, scenario] });
  const overlay = drilldown.buildOverlay({ observedPathDigest: 'sha256:path' });
  assert.deepEqual(Object.fromEntries(overlay.cells.map(cell => [cell.cellId, cell.observed.length])),
    { 'cell:scenario:example': 1, 'cell:mechanic:example.operation.1': 1 });
});

test('the observed story orders declared responsibilities and keeps composed scenarios separate', () => {
  const authority = createSemanticAuthority(graph);
  const story = buildObservedStory({ authority, scenarioId: 'example', observedPathDigest: 'sha256:path', responsibilities: [
    { ...semanticAddress(authority, 'cell:mechanic:example.operation.3', null), disposition: 'completed', durationMilliseconds: 9 },
    { ...semanticAddress(authority, 'cell:mechanic:example.operation.1', null), disposition: 'completed', durationMilliseconds: 4 },
    { ...semanticAddress(authority, 'cell:mechanic:child.operation.1', null), disposition: 'completed', durationMilliseconds: 2 }] });
  assert.equal(story.scenario.scenarioId, 'example');
  assert.equal(story.scenario.inputId, 'example-request');
  assert.deepEqual(story.scenario.responsibilities.map(entry => [entry.responsibilityId, entry.responsibilityOrdinal]),
    [['first-port', 1], ['third-port', 3]]);
  assert.deepEqual(story.composedScenarios.map(entry => entry.scenarioId), ['child']);
  assert.equal(story.composedScenarios[0].parentScenarioId, 'example');
  assert.equal(story.observedPathDigest, 'sha256:path');
});

const canonicalGraph = {
  graphType: 'sda-semantic-execution-graph.v1', graphId: 'example-graph', rootCellId: 'cell:scenario:example',
  cells: [
    { cellId: 'cell:scenario:example', altitude: 'scenario', parentCellId: null, input: { contractId: 'example-request.v1' },
      outcome: { contractId: 'example-result.v1' }, execution: { authorityId: 'example.v1', authorityDigest: 'sha256:s' } },
    { cellId: 'cell:mechanic:example.operation.1', altitude: 'mechanic', parentCellId: 'cell:scenario:example',
      input: { contractId: 'example-request.v1' }, outcome: { contractId: 'semantic-value.v1' },
      execution: { authorityId: 'operation:first-port.v1', authorityDigest: 'sha256:a' } },
    { cellId: 'cell:mechanic:example.operation.1:expression', altitude: 'mechanic', parentCellId: 'cell:mechanic:example.operation.1',
      input: { contractId: 'semantic-value.v1' }, outcome: { contractId: 'semantic-value.v1' },
      execution: { authorityId: 'mechanic:object.v1', authorityDigest: 'sha256:b' } },
    { cellId: 'cell:mechanic:example.operation.2', altitude: 'mechanic', parentCellId: 'cell:scenario:example',
      input: { contractId: 'semantic-value.v1' }, outcome: { contractId: 'child-result.v1' },
      execution: { authorityId: 'operation:child.v1', authorityDigest: 'sha256:c' } }
  ],
  edges: []
};
const cell = (cellId, duration, order) => ({ testimonyType: 'cell-execution-testimony.v1', cellId, cellAltitude: 'mechanic',
  cellExecutionId: `exec:${order}`, rootExecutionId: 'root', parentCellExecutionId: 'exec:0', outcomeContractId: 'semantic-value.v1',
  outcomeVariant: 'VALUE', disposition: 'completed', selectedEdgeIds: [], logicalOrder: order, durationMilliseconds: duration });
const cells = [cell('cell:mechanic:example.operation.1', 4, 1), cell('cell:mechanic:example.operation.1:expression', 1, 2),
  cell('cell:mechanic:example.operation.2', 2, 3),
  { ...cell('cell:scenario:example', 8, 4), cellAltitude: 'scenario', outcomeContractId: 'example-result.v1' }];

const moduleUrl = source => 'data:text/javascript,' + encodeURIComponent(source);
const compileModule = moduleUrl(`export const compile = async () => ({ canonicalGraph: ${JSON.stringify(canonicalGraph)},
  canonicalGraphDigest: 'sha256:plan', realizationOverlay: { physicalCells: [], physicalEdges: [] }, input: { value: 7 } });`);
const executeModule = moduleUrl(`export const execute = async (_, __, context) => {
  const cells = ${JSON.stringify(cells)};
  if (typeof context.onTestimony === 'function') for (const item of cells) context.onTestimony(item);
  return { disposition: 'completed', outcome: { value: 7 }, cellTestimony: cells, edgeTestimony: [], observedPathDigest: 'sha256:observed' };
};`);

const command = (verb, extra = {}) => ({ deliveryType: 'sfx-command-delivery.v1', operation: verb,
  request: { object: 'capability', verb, subject: 'example', input: { value: 7 }, ...extra } });
const identity = { snapshotId: 'snapshot', projectionDigest: 'projection', viewDefinitionDigest: 'views', truncated: false };
const executor = { capabilityId: 'run-declared-graph', scenarios: [], executionAuthorities: [{ owningScenarioId: 'executor', operations: [
  { kind: 'invoke-port', portId: 'compile' }, { kind: 'invoke-port', portId: 'execute' }] }],
  interfaceAuthority: { portBindings: [
    { portId: 'compile', configuration: { estateProvider: { module: compileModule, export: 'compile' } } },
    { portId: 'execute', configuration: { estateProvider: { module: executeModule, export: 'execute' } } }] } };

function context() {
  const observations = [];
  return { databaseRoot: 'unused', observations,
    onObservation: observation => observations.push(observation),
    readQuery: async () => ({ ...identity, recordsets: [[{ provider_id: 'delivery',
      configuration: JSON.stringify({ capabilityId: 'run-declared-graph', requestExpression: {}, resultExpression: {} }) }],
      [{ default_target: 'node' }]] }),
    readAuthority: async (_, selection) => ({ selection,
      authority: { ...identity, recordsets: [[{ scenario_id: selection.capabilityId === 'run-declared-graph' ? 'executor' : 'root' }]] },
      closure: { recordsets: [[]] }, graphSource: structuredClone(selection.capabilityId === 'run-declared-graph' ? executor : graph) }) };
}

test('observe streams semantic addresses and returns the observed story; invoke takes neither', async () => {
  const config = context();
  const observed = await executeDatabaseCommand(command('observe'), config);
  const operations = config.observations.filter(o => o.semanticRole === 'EXECUTION_RESPONSIBILITY');
  assert.deepEqual(operations.map(o => [o.responsibilityId, o.responsibilityOrdinal, o.scenarioId]),
    [['first-port', 1, 'example'], ['child', 2, 'example']]);
  const mechanism = config.observations.find(o => o.semanticRole === 'MECHANIC');
  assert.deepEqual([mechanism.mechanicId, mechanism.responsibilityId], ['object', 'first-port']);
  const scenarioCell = config.observations.find(o => o.semanticRole === 'SCENARIO_OUTCOME');
  assert.deepEqual([scenarioCell.inputId, scenarioCell.eventId, scenarioCell.outcomeId],
    ['example-request', 'example-requested', 'example-result']);

  assert.equal(observed.outcome.overlay.cells[0].semanticAddress.outcomeId, 'example-result');
  assert.equal(observed.outcome.overlay.cells[1].semanticAddress.responsibilityId, 'first-port');
  const story = observed.outcome.story;
  assert.equal(story.scenario.inputContractId, 'example-request.v1');
  assert.deepEqual(story.scenario.responsibilities.map(entry => [entry.responsibilityId, entry.durationMilliseconds, entry.disposition]),
    [['first-port', 4, 'completed'], ['child', 2, 'completed']]);
  assert.equal(story.composedScenarios, undefined);
  assert.equal(story.observedPathDigest, 'sha256:observed');

  const invoked = await executeDatabaseCommand(command('invoke'), context());
  assert.equal(invoked.outcome.story, undefined);
  assert.equal(invoked.outcome.overlay, undefined);
});
