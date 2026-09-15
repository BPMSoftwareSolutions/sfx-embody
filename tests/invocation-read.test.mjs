import test from 'node:test';
import assert from 'node:assert/strict';
import { readAuthority } from '../src/read-authority.mjs';
import { executeDatabaseCommand, executeEstateCapability } from '../src/invoke-database-capability.mjs';

const identity = { snapshotId: 'snapshot', projectionDigest: 'projection', viewDefinitionDigest: 'views', truncated: false };
const graph = { capabilityId: 'example', scenarios: [], executionAuthorities: [],
  interfaceAuthority: { interfaces: [{ kind: 'cli', configuration: { input: { type: 'text', contract: 'name.v1', path: 'payload.name' } } }] } };

test('authority reads use the injected session and return the graph without fetching documents by default on invoke', async () => {
  const calls = [];
  const query = async (statement, options) => {
    calls.push({ statement, options });
    return { ...identity, recordsets: [calls.length === 1 ? [{ capability_id: 'example', scenario_id: 'root', namespace_id: 'names',
      graph_source: JSON.stringify(graph), documents: null }] : []] };
  };
  const bundle = await readAuthority('must-not-import-a-runner', { capabilityId: 'example' }, { query, documents: false, retainObjects: false });
  assert.equal(calls.length, 3);
  assert.match(calls[0].statement, /FROM analysis\.capability_graph_source\(/);
  assert.ok(calls.every(call => !call.statement.includes('v_capability_execution_declaration')));
  assert.equal(calls[0].options.input.includeDocuments, 0);
  assert.equal(calls[1].options.input.scenarioId, 'root');
  assert.equal(calls[1].options.input.namespaceId, 'names');
  assert.ok(calls.every(call => call.options.retainObjects === false));
  assert.deepEqual(bundle.graphSource, graph);
  assert.deepEqual(bundle.selection, { capabilityId: 'example', scenarioId: 'root', namespaceId: 'names' });
});

test('standalone authority extraction can request the complete document set', async () => {
  let calls = 0;
  const documents = JSON.stringify([{ source_path: 'capabilities/example/semantic-graph.authority.json', entry_id: 'semantic-graph.authority.json',
    document: '{"executionTopologyAuthority":"graph-v3"}' }]);
  const query = async (_, options) => {
    calls++;
    if (calls === 1) assert.equal(options.input.includeDocuments, 1);
    return { ...identity, recordsets: [calls === 1 ? [{ scenario_id: 'root', graph_source: JSON.stringify(graph), documents }] : []] };
  };
  const bundle = await readAuthority('unused', { capabilityId: 'example' }, { query, retainObjects: false });
  assert.equal(bundle.authority.recordsets[0][0].documents, documents);
});

test('coherence and truncation guards remain on every authority read', async () => {
  for (const changed of [{ snapshotId: 'other' }, { projectionDigest: 'other' }, { viewDefinitionDigest: 'other' }, { truncated: true }]) {
    for (const failingRead of [2, 3]) {
      let calls = 0;
      const query = async () => ({ ...identity, ...( ++calls === failingRead ? changed : {}),
        recordsets: [calls === 1 ? [{ scenario_id: 'root', graph_source: JSON.stringify(graph) }] : []] });
      await assert.rejects(readAuthority('unused', { capabilityId: 'example' }, { query, retainObjects: false }), /DATABASE_AUTHORITY_NOT_COHERENT/);
    }
  }
  await assert.rejects(readAuthority('unused', { capabilityId: 'missing' }, {
    query: async () => ({ ...identity, recordsets: [[]] }), retainObjects: false
  }), /CAPABILITY_NOT_FOUND/);
});

// A fixture provider tests the loader's carrier only, not kernel interpretation.
const fixtureModule = 'data:text/javascript,' + encodeURIComponent('export const invoke = async (_, graph) => ({ disposition: "completed", outcome: graph.input });');
const executor = { capabilityId: 'run-declared-graph', executionAuthorities: [{ owningScenarioId: 'executor', operations: [{ kind: 'invoke-port', portId: 'port' }] }],
  interfaceAuthority: { portBindings: [{ portId: 'port', configuration: { estateProvider: { module: fixtureModule, export: 'invoke' } } }] } };
// The declared reader capability the loader dispatches reveal to. The read is a
// declared port in the real estate; this fixture supplies its execution.
const reader = { capabilityId: 'read-capability-meaning',
  executionAuthorities: [{ owningScenarioId: 'read-capability-meaning', operations: [{ kind: 'invoke-port', portId: 'read-port' }] }],
  interfaceAuthority: { portBindings: [{ portId: 'read-port', configuration: { estateProvider: { module: fixtureModule, export: 'invoke' } } }] } };

function context({ mismatch } = {}) {
  const reads = [], queries = [], observations = [];
  return { databaseRoot: 'unused', reads, queries, observations,
    onObservation: observation => { observations.push(observation); },
    readQuery: async statement => {
      queries.push(statement);
      assert.match(statement, /executionDelivery/);
      return { ...identity, recordsets: [[{ provider_id: 'delivery', configuration: JSON.stringify({ capabilityId: 'run-declared-graph',
        requestExpression: {}, resultExpression: {} }) }], [{ default_target: 'node' }]] };
    },
    readAuthority: async (_, selection, options) => {
      reads.push({ selection, options });
      const isExecutor = selection.capabilityId === 'run-declared-graph';
      const isReader = selection.capabilityId === 'read-capability-meaning';
      return { selection, authority: { ...identity, ...(mismatch === reads.length ? { viewDefinitionDigest: 'other' } : {}),
        recordsets: [[{ scenario_id: isExecutor ? 'executor' : isReader ? 'read-capability-meaning' : 'root' }]] },
        closure: { recordsets: [[]] }, graphSource: structuredClone(isExecutor ? executor : isReader ? reader : graph) };
    }
  };
}
const command = (input, verb = 'invoke') => ({ deliveryType: 'sfx-command-delivery.v1', operation: verb,
  request: { object: 'capability', verb, subject: 'example', input } });

test('invoke and observe use the same bounded graph and preserve declared scalar input mapping', async () => {
  for (const verb of ['invoke', 'observe']) {
    const config = context();
    const result = await executeDatabaseCommand(command('Zo\u00eb', verb), config);
    assert.deepEqual(result.outcome.result, { disposition: 'completed', outcome: { contractId: 'name.v1', payload: { name: 'Zo\u00eb' } } });
    assert.deepEqual(config.reads.map(read => read.selection.capabilityId), ['example', 'run-declared-graph']);
    assert.ok(config.reads.every(read => read.options.documents === false && read.options.retainObjects === false));
    assert.equal(config.queries.length, 1);
    assert.equal(result.outcome.evidence.timings.readGraphSource, undefined);
    assert.equal(result.outcome.evidence.viewDefinitionDigest, 'views');
    assert.ok(config.observations.some(o => o.phase === 'executeDeclaredGraph' && o.status === 'completed'));
  }
});

test('delivery and executor reads cannot cross authority identities', async () => {
  for (const mismatch of [1, 2]) await assert.rejects(executeDatabaseCommand(command(null), context({ mismatch })), /DATABASE_AUTHORITY_NOT_COHERENT/);
});

test('reveal reads through the declared reader capability with the subject as input', async () => {
  const config = context();
  const result = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'reveal',
    request: { object: 'capability', verb: 'reveal', subject: 'example', namespace: 'sidefx:capabilities' } }, config);
  assert.equal(result.outcome.view, 'meaning');
  assert.equal(result.outcome.capabilityId, 'example');
  assert.deepEqual(result.outcome.meaning, { capabilityId: 'example', namespaceId: 'sidefx:capabilities' });
  assert.deepEqual(config.reads.map(read => read.selection.capabilityId), ['read-capability-meaning', 'run-declared-graph']);
  assert.equal(result.outcome.evidence.snapshotId, 'snapshot');
});

test('supplied graph input remains unchanged and observation failures do not affect execution', async () => {
  const input = { capabilityId: 'supplied', scenarios: [], executionAuthorities: [], input: { value: 7 } };
  const result = await executeDatabaseCommand(command(input), { ...context(), onObservation() { throw new Error('observer'); } });
  assert.deepEqual(result.outcome.result.outcome, input.input);
  assert.deepEqual(graph.executionAuthorities, []);
});

test('the actual authority reader fetches each graph once and shares mechanics only within an invocation', async () => {
  const calls = [];
  const delivery = context().readQuery;
  const query = async (statement, options) => {
    calls.push(statement);
    if (statement.includes('executionDelivery')) return delivery(statement);
    if (statement.includes('analysis.capability_graph_source(')) {
      assert.equal(options.input.includeDocuments, 0);
      const isExecutor = options.input.capabilityId === 'run-declared-graph';
      return { ...identity, recordsets: [[{ scenario_id: isExecutor ? 'executor' : 'root',
        graph_source: JSON.stringify(isExecutor ? executor : graph), documents: null }]] };
    }
    return { ...identity, recordsets: [[]] };
  };
  const config = { ...context(), readQuery: query,
    readAuthority: (root, selection, options) => readAuthority(root, selection, { ...options, query }) };
  for (let i = 1; i <= 2; i++) {
    await executeDatabaseCommand(command(null), config);
    assert.equal(calls.length, 6 * i);
    assert.equal(calls.filter(sql => sql.includes("object_kind='MECHANIC'")).length, i);
    assert.equal(calls.filter(sql => sql.includes('analysis.capability_graph_source(')).length, 2 * i);
  }
});

test('retained document recordsets still work for the exported declaration carrier', async () => {
  const record = (entry, document) => ({ source_path: '/fixture/' + entry,
    content_bytes: { base64: Buffer.from(JSON.stringify(document)).toString('base64') } });
  for (const index of [1, 2]) {
    const recordsets = [[{ scenario_id: 'executor' }], [], []];
    recordsets[index] = [record('execution-authorities.authority.json', { executionAuthorities: executor.executionAuthorities }),
      record('interfaces.authority.json', executor.interfaceAuthority)];
    const result = await executeEstateCapability({ capabilityId: 'fixture' }, { input: { value: 7 } }, {
      readAuthority: async () => ({ authority: { recordsets } })
    });
    assert.deepEqual(result, { disposition: 'completed', outcome: { value: 7 } });
  }
});
