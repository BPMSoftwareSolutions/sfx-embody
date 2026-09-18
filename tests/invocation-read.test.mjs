import test from 'node:test';
import assert from 'node:assert/strict';
import { readAuthority } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/authority-read.mjs';
import { executeDatabaseCommand } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/command-carrier.mjs';
import { executeDeclaredCapability } from '../../scenario-driven-architecture/languages/typescript/src/kernel/bootstrap/declared-operation-carrier.mjs';

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
const executorFor = module => ({ capabilityId: 'run-declared-graph',
  executionAuthorities: [{ owningScenarioId: 'executor', operations: [{ kind: 'invoke-port', portId: 'port' }] }],
  interfaceAuthority: { portBindings: [{ portId: 'port', configuration: { estateProvider: { module, export: 'invoke' } } }] } });
// A listing read outcome, carried through the executor fixture so the loader's
// listing shape is exercised without interpreting the graph in the unit test.
const listingExecutor = 'data:text/javascript,' + encodeURIComponent(`
export const invoke = async (_, graph) => ({ disposition: "completed", outcome:
  graph.input.query === undefined
    ? [{ capabilityId: "example", namespaceId: graph.input.namespaceId, scenarioCount: 1, userStory: { intent: "story" } }, { capabilityId: "other" }]
    : [{ capabilityId: "other", matchedFields: ["capabilityId"] }] });`);
const executor = executorFor(fixtureModule);
// The declared reader capability the loader resolves reveal to. The read is a
// declared port in the real estate; this fixture supplies its execution and the
// capability's declared display transformation, so the test exercises the
// loader's declared-document path rather than a fixture-shaped rendering.
const declaredDocument = capabilityId => ({ op: 'literal', value: { documentType: 'sfx-display-document.v1',
  blocks: [{ type: 'display', as: 'json', value: { declaredBy: capabilityId } }] } });
const declaredReader = (capabilityId, module, exportName, transformationId) => ({
  capabilityId,
  executionAuthorities: [{ owningScenarioId: capabilityId, operations: [{ kind: 'invoke-port', portId: 'read-port' }] }],
  interfaceAuthority: {
    interfaces: [{ kind: 'cli', configuration: { display: { transformationId, as: 'text' } } }],
    portBindings: [{ portId: 'read-port', configuration: { estateProvider: { module, export: exportName } } }]
  },
  semanticTransformations: [{ id: transformationId, expression: declaredDocument(capabilityId) }]
});
const reader = declaredReader('read-capability-meaning', fixtureModule, 'invoke', 'read-capability-meaning-display.v1');
const listingModule = 'data:text/javascript,' + encodeURIComponent(`export const read = (configuration, input) => ({
  disposition: "completed",
  outcome: [
    { capabilityId: "example", namespaceId: input.namespaceId ?? null, scenarioCount: 1, userStory: { intent: "story" } },
    input.query === undefined ? { capabilityId: "other" } : { capabilityId: "other", matchedFields: ["capabilityId"] }
  ]
});`);
const listing = declaredReader('list-capabilities', listingModule, 'read', 'list-capabilities-display.v1');
// The retained-publication carrier is supplied by the executor fixture: circuit
// reads the catalogue, artifact reads one retained artifact's bytes.
const publicationExecutor = 'data:text/javascript,' + encodeURIComponent(`
export const invoke = async (_, graph) => ({ disposition: "completed", outcome:
  graph.input.operation === "artifact" ? { artifact: { url: "x", base64: "AAAA" } }
  : { capabilityId: graph.input.capabilityId ?? null, views: [] } });`);
const publication = declaredReader('read-retained-publication', fixtureModule, 'invoke', 'read-retained-publication-display.v1');
// A declared read can fail; the loader must surface its domain failure.
const failingReaderModule = 'data:text/javascript,' + encodeURIComponent(`
export const invoke = async () => ({ disposition: "failed", code: "CELL_EXECUTION_FAILED",
  error: { message: "CIRCUIT_PUBLICATION_UNAVAILABLE" } });`);
// A declared reader without a display transformation returns its read untouched.
const bareReader = { capabilityId: 'read-capability-meaning',
  executionAuthorities: [{ owningScenarioId: 'read-capability-meaning', operations: [{ kind: 'invoke-port', portId: 'read-port' }] }],
  interfaceAuthority: { portBindings: [{ portId: 'read-port', configuration: { estateProvider: { module: fixtureModule, export: 'invoke' } } }] } };

function context({ mismatch, executorModule = fixtureModule, readerGraph } = {}) {
  const reads = [], queries = [], observations = [];
  const executor = executorFor(executorModule);
  return { databaseRoot: 'unused', reads, queries, observations,
    evaluateExpression: expression => expression.value,
    onObservation: observation => { observations.push(observation); },
    resolveMechanic: async binding => {
      const provider = binding?.configuration?.estateProvider;
      if (!provider || typeof provider.module !== 'string' || typeof provider.export !== 'string') return null;
      const module = await import(provider.module);
      return typeof module[provider.export] === 'function' ? module[provider.export] : null;
    },
    readQuery: async statement => {
      queries.push(statement);
      assert.match(statement, /executionDelivery/);
      return { ...identity, recordsets: [[{ provider_id: 'delivery', configuration: JSON.stringify({ capabilityId: 'run-declared-graph',
        requestExpression: {}, resultExpression: {} }) }], [{ default_target: 'node' }]] };
    },
    readAuthority: async (selection, options) => {
      reads.push({ selection, options });
      const isExecutor = selection.capabilityId === 'run-declared-graph';
      const isReader = selection.capabilityId === 'read-capability-meaning';
      const isListing = selection.capabilityId === 'list-capabilities';
      const isPublication = selection.capabilityId === 'read-retained-publication';
      const readerFixture = readerGraph === 'bare' ? bareReader : reader;
      return { selection, authority: { ...identity, ...(mismatch === reads.length ? { viewDefinitionDigest: 'other' } : {}),
        recordsets: [[{ scenario_id: isExecutor ? 'executor' : isReader ? 'read-capability-meaning'
          : isListing ? 'list-capabilities' : isPublication ? 'read-retained-publication' : 'root' }]] },
        closure: { recordsets: [[]] }, graphSource: structuredClone(isExecutor ? executor : isReader ? readerFixture
          : isListing ? listing : isPublication ? publication : graph) };
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
    assert.deepEqual(config.reads.map(read => read.selection.capabilityId),
      verb === 'observe' ? ['example', 'run-declared-graph', 'read-observation-projection'] : ['example', 'run-declared-graph']);
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

test('list and find read through the declared listing capability', async () => {
  const listConfig = context({ executorModule: listingExecutor });
  const listed = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'list',
    request: { object: 'capability', verb: 'list', namespace: 'sidefx:capabilities' } }, listConfig);
  assert.equal(listed.outcome.result.outcome.length, 2);
  assert.equal(listed.outcome.result.outcome[0].capabilityId, 'example');
  assert.equal(listed.outcome.result.outcome[0].namespaceId, 'sidefx:capabilities');
  // The declared display document is attached; the loader shapes nothing.
  assert.equal(listed.outcome.display.document.documentType, 'sfx-display-document.v1');
  assert.deepEqual(listed.outcome.display.document.blocks[0].value, { declaredBy: 'list-capabilities' });
  assert.equal(listed.outcome.meaning, undefined);
  assert.equal(listed.outcome.capabilities, undefined);
  assert.equal(listed.outcome.count, undefined);
  assert.deepEqual(listConfig.reads.map(read => read.selection.capabilityId), ['list-capabilities', 'run-declared-graph']);

  const findConfig = context({ executorModule: listingExecutor });
  const found = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'find',
    request: { object: 'capability', verb: 'find', query: 'example' } }, findConfig);
  assert.deepEqual(found.outcome.result.outcome[0].matchedFields, ['capabilityId']);
  assert.equal(found.outcome.display.document.documentType, 'sfx-display-document.v1');
});

test('circuit, artifact and reveal --as circuit read through the declared publication capability', async () => {
  const circuitConfig = context({ executorModule: publicationExecutor });
  const circuit = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'circuit',
    request: { object: 'capability', verb: 'circuit', subject: 'example' } }, circuitConfig);
  assert.deepEqual(circuit.outcome.result.outcome, { capabilityId: 'example', views: [] });
  assert.equal(circuit.outcome.view, undefined);
  assert.equal(circuit.outcome.circuit, undefined);
  assert.deepEqual(circuit.outcome.display.document.blocks[0].value, { declaredBy: 'read-retained-publication' });
  assert.deepEqual(circuitConfig.reads.map(read => read.selection.capabilityId),
    ['read-retained-publication', 'run-declared-graph']);

  const revealConfig = context({ executorModule: publicationExecutor });
  const revealed = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'reveal',
    request: { object: 'capability', verb: 'reveal', subject: 'example', as: 'circuit' } }, revealConfig);
  assert.equal(revealed.outcome.view, 'circuit');
  assert.equal(revealed.outcome.display.document.documentType, 'sfx-display-document.v1');
  assert.deepEqual(revealed.outcome.display.document.blocks[0].value, { declaredBy: 'read-retained-publication' });

  const artifactConfig = context({ executorModule: publicationExecutor });
  const artifact = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'artifact',
    request: { object: 'media', verb: 'artifact', subject: 'a'.repeat(64) } }, artifactConfig);
  assert.equal(artifact.outcome.result.outcome.artifact.base64, 'AAAA');
  assert.equal(artifact.outcome.media, undefined);
  assert.deepEqual(artifact.outcome.display.document.blocks[0].value, { declaredBy: 'read-retained-publication' });
});

test('reveal reads through the declared reader capability with the subject as input', async () => {
  const config = context();
  const result = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'reveal',
    request: { object: 'capability', verb: 'reveal', subject: 'example', namespace: 'sidefx:capabilities' } }, config);
  assert.equal(result.outcome.view, 'meaning');
  assert.equal(result.outcome.capabilityId, 'example');
  assert.deepEqual(result.outcome.result.outcome, { capabilityId: 'example', namespaceId: 'sidefx:capabilities' });
  // The declared transformation made the document; the terminal emits its bytes.
  assert.equal(result.outcome.display.document.documentType, 'sfx-display-document.v1');
  assert.equal(result.outcome.display.as, 'text');
  assert.equal(result.outcome.meaning, undefined);
  assert.deepEqual(config.reads.map(read => read.selection.capabilityId), ['read-capability-meaning', 'run-declared-graph']);
  assert.equal(result.outcome.evidence.snapshotId, 'snapshot');
});

test('reveal carries the selected scenario into the reader input and returns the read untouched', async () => {
  const config = context();
  const result = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'reveal',
    request: { object: 'capability', verb: 'reveal', subject: 'example', namespace: 'sidefx:capabilities',
      scenario: 'replay-scaffold-generation' } }, config);
  assert.equal(result.outcome.view, 'meaning');
  assert.equal(result.outcome.capabilityId, 'example');
  assert.notEqual(result.outcome.scenarioId, 'replay-scaffold-generation');
  // The fixture reader echoes the input it was handed, so the reader input and
  // the delivered read are the same object: the loader adds the selected
  // scenario to the read and reshapes none of the read's own outcome.
  assert.deepEqual(result.outcome.result.outcome, { capabilityId: 'example', namespaceId: 'sidefx:capabilities',
    scenarioId: 'replay-scaffold-generation' });
  assert.deepEqual(config.reads.map(read => read.selection.capabilityId), ['read-capability-meaning', 'run-declared-graph']);
  assert.equal(result.outcome.evidence.snapshotId, 'snapshot');
});

test('a read failure is the delivery failure and a reader without a declared display returns no document', async () => {
  const failing = context({ executorModule: failingReaderModule });
  await assert.rejects(executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'reveal',
    request: { object: 'capability', verb: 'reveal', subject: 'example' } }, failing), /CIRCUIT_PUBLICATION_UNAVAILABLE/);

  const bare = context({ readerGraph: 'bare' });
  const result = await executeDatabaseCommand({ deliveryType: 'sfx-command-delivery.v1', operation: 'reveal',
    request: { object: 'capability', verb: 'reveal', subject: 'example' } }, bare);
  assert.deepEqual(result.outcome.result.outcome, { capabilityId: 'example' });
  assert.equal(result.outcome.display, undefined);
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
    readAuthority: (selection, options) => readAuthority(selection, { ...options, query }) };
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
    const result = await executeDeclaredCapability({ capabilityId: 'fixture' }, { input: { value: 7 } }, {
      resolveMechanic: async binding => {
        const provider = binding?.configuration?.estateProvider;
        if (!provider || typeof provider.module !== 'string' || typeof provider.export !== 'string') return null;
        const module = await import(provider.module);
        return typeof module[provider.export] === 'function' ? module[provider.export] : null;
      },
      readAuthority: async () => ({ authority: { recordsets } })
    });
    assert.deepEqual(result, { disposition: 'completed', outcome: { value: 7 } });
  }
});
