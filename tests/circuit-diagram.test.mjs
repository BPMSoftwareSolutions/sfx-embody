import test from 'node:test';
import assert from 'node:assert/strict';
import { circuitDiagram, scenarioDiagram, executionOrderDiagrams } from '../src/diagram-capability-circuit.mjs';
import { observeCapabilityIntegrity } from '../src/observe-capability-integrity.mjs';

// A structural check over generated Mermaid: every node an edge names must be
// declared, blocks must close, and no label may carry a character that would end
// the label or the edge caption. This catches a diagram that renders as bare
// generated identifiers instead of the circuit it is supposed to show.
function validateFlowchart(lines) {
  const declared = new Set();
  const referenced = new Set();
  let depth = 0;
  for (const line of lines) {
    const text = line.trim();
    if (text.startsWith('subgraph')) { depth += 1; continue; }
    if (text === 'end') { depth -= 1; assert(depth >= 0, 'unbalanced subgraph'); continue; }
    if (text.startsWith('classDef') || text.startsWith('flowchart')) continue;
    const node = /^(n\d+)\[/.exec(text);
    if (node) {
      assert(!declared.has(node[1]), `node ${node[1]} declared twice`);
      declared.add(node[1]);
      const label = /^n\d+\["(.*)"\]/.exec(text);
      assert(label, `node ${node[1]} has no quoted label: ${text}`);
      assert(!label[1].includes('"'), `node ${node[1]} label carries a raw quote`);
      continue;
    }
    const edge = /^(n\d+)\s+-[.-]*->(?:\|([^|]*)\|)?\s*(n\d+)$/.exec(text);
    assert(edge, `unrecognised line: ${text}`);
    referenced.add(edge[1]);
    referenced.add(edge[3]);
  }
  assert.equal(depth, 0, 'unbalanced subgraph');
  for (const id of referenced) assert(declared.has(id), `edge names undeclared node ${id}`);
  return { declared: declared.size, referenced: referenced.size };
}

function validateSequence(lines) {
  const participants = new Set();
  assert.equal(lines[0], 'sequenceDiagram');
  for (const line of lines.slice(1)) {
    const text = line.trim();
    if (text === 'autonumber') continue;
    const participant = /^participant (n\d+) as (.+)$/.exec(text);
    if (participant) {
      assert(!participants.has(participant[1]), `participant ${participant[1]} declared twice`);
      assert(!participant[2].includes(':'), 'participant alias carries the message separator');
      participants.add(participant[1]);
      continue;
    }
    const note = /^Note (?:right of|over) (n\d+): /.exec(text);
    if (note) { assert(participants.has(note[1]), `note names undeclared participant ${note[1]}`); continue; }
    const message = /^(n\d+)->>(n\d+): /.exec(text);
    assert(message, `unrecognised line: ${text}`);
    for (const id of [message[1], message[2]]) assert(participants.has(id), `message names undeclared participant ${id}`);
  }
  return participants.size;
}

// Shaped after conditions observed in the live estate: an authority with several
// retained definitions that disagree, an invocation the closure does not
// resolve, a scenario that declares a face rather than a specification, a port
// with no transformation, and a provider that declares no mechanic.
const meaning = {
  snapshotId: 'sha256:aa', projectionDigest: 'sha256:bb', viewDefinitionDigest: 'sha256:cc',
  capability: {
    capabilityId: 'example-capability', namespaceId: 'example:namespace',
    declaredRootScenarioId: 'root-scenario', declaredRootCount: 1, selectedScenarioId: 'root-scenario',
    definitionDigest: 'sha256:dd', mode: 'capability', name: 'example-capability',
    userStory: null, experience: null,
  },
  scenarios: [
    { scenarioId: 'root-scenario', minimumDepth: 0, cycleDetected: false, definitions: [
      { definitionDigest: 'sha256:11', format: 'sidefx-semantic-definition.v1', specification: null,
        face: { capabilityId: 'example-capability', event: 'requested', input: 'in', outcome: 'out' } }] },
    { scenarioId: 'orphan-scenario', minimumDepth: 1, cycleDetected: false, definitions: [] },
  ],
  executionAuthorities: [
    { authorityId: 'root-scenario.v1', definitions: [
      { definitionDigest: 'sha256:21', owningScenarioId: 'root-scenario', operations: [
        { kind: 'invoke-port', portId: 'example-port' },
        { kind: 'invoke-scenario', scenarioId: 'not-in-closure' }] },
      { definitionDigest: 'sha256:22', owningScenarioId: 'root-scenario', operations: [
        { kind: 'invoke-port', portId: 'example-port' }] },
      { definitionDigest: 'sha256:23', owningScenarioId: 'root-scenario', operations: [
        { kind: 'emit-observation' }] },
    ] },
  ],
  ports: [{ portId: 'example-port', definitions: [
    { definitionDigest: 'sha256:31', platformCapabilityId: 'example-platform.v1', transformationId: null, configuration: null }] }],
  transformations: [],
  observableConditions: [],
  invocations: [],
  // The estate configures this platform capability with a transformation on 4 of
  // its 5 ports, so the one here that declares none is the exception.
  platformCapabilityUsage: [{ platformCapabilityId: 'example-platform.v1', portCount: 5, withTransformation: 4 }],
  implementations: [{ platformCapabilityId: 'example-platform.v1', providerId: 'Example.Provider', mechanicId: null, definitionProfile: null }],
  mechanics: [],
  providers: ['Example.Provider'],
};

test('the circuit diagram declares every node its edges name', () => {
  const counts = validateFlowchart(circuitDiagram(meaning));
  assert(counts.declared > 0 && counts.referenced > 0);
  validateFlowchart(scenarioDiagram(meaning));
});

test('the circuit carries the declared execution order and where definitions disagree', () => {
  const circuit = circuitDiagram(meaning).join('\n');
  // operations is an ordered array; the step numbers are that order.
  assert.match(circuit, /\|1\. invoke-port \(2 of 3 definitions\)\|/);
  assert.match(circuit, /\|2\. invoke-scenario \(1 of 3 definitions\), not in closure\|/);
  assert.match(circuit, /3 definitions, 3 operation sets/);
  // An operation that names neither a port nor a scenario still gets a node.
  assert.match(circuit, /\["emit-observation"\]/);
  // Declared gaps are drawn as gaps, not as ordinary nodes in the chain.
  assert.match(circuit, /no execution authority/);
  assert.match(circuit, /declares no mechanic/);
  assert.match(circuit, /no transformation declared/);
});

test('each execution-order trace is a sequence some definition actually declares', () => {
  const traces = executionOrderDiagrams(meaning);
  // Three definitions declaring three sequences produce three traces, never one
  // merged order that no definition declares.
  assert.equal(traces.length, 3);
  for (const trace of traces) validateSequence(trace.lines);
  assert.deepEqual(traces.map(trace => trace.digests.length), [1, 1, 1]);
  assert.match(traces[0].lines.join('\n'), /invoke-scenario \(not in closure\)/);
});

test('integrity observations report declared state without inventing a cause', () => {
  const codes = observeCapabilityIntegrity(meaning).map(observation => observation.code);
  for (const expected of ['SCENARIO_DEFINITION_ABSENT', 'SCENARIO_WITHOUT_EXECUTION_AUTHORITY',
    'SCENARIO_INVOCATION_UNRESOLVED', 'PORT_WITHOUT_TRANSFORMATION', 'PROVIDER_WITHOUT_MECHANIC',
    'EXECUTION_AUTHORITY_DEFINITIONS_DISAGREE', 'USER_STORY_ABSENT', 'EXPERIENCE_ABSENT',
    'OBSERVABLE_CONDITIONS_ABSENT', 'SCENARIO_SPECIFICATION_ABSENT']) {
    assert(codes.includes(expected), `expected observation ${expected}`);
  }
  // One statement per authority and target, carrying how many definitions
  // declare it -- not one per definition.
  assert.equal(codes.filter(code => code === 'SCENARIO_INVOCATION_UNRESOLVED').length, 1);
  const unresolved = observeCapabilityIntegrity(meaning).find(item => item.code === 'SCENARIO_INVOCATION_UNRESOLVED');
  assert.match(unresolved.statement, /Declared by 1 of its 3 retained definitions\./);
  // The transformation check reports the exception against how the estate
  // configures the same platform capability, never the norm.
  const transformation = observeCapabilityIntegrity(meaning).find(item => item.code === 'PORT_WITHOUT_TRANSFORMATION');
  assert.match(transformation.statement, /4 of the 5 ports/);
  const quiet = observeCapabilityIntegrity({ ...meaning,
    platformCapabilityUsage: [{ platformCapabilityId: 'example-platform.v1', portCount: 5, withTransformation: 0 }] });
  assert(!quiet.some(item => item.code === 'PORT_WITHOUT_TRANSFORMATION'),
    'a platform capability the estate never configures with a transformation is not an exception');
});
