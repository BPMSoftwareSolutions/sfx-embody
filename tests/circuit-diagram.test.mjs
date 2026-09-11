import test from 'node:test';
import assert from 'node:assert/strict';
import { executionOrderDiagrams } from '../src/diagram-capability-circuit.mjs';
import { blueprintDiagram, circuitFromAuthority, compareBlueprintToCircuit } from '../src/diagram-blueprint-circuit.mjs';
import { observeCapabilityIntegrity } from '../src/observe-capability-integrity.mjs';

// A structural check over the estate's canonical Mermaid shape: every node an
// edge names must be declared, and no label may carry a character that would end
// it. Today's circuit and a blueprint both render through blueprintDiagram, so
// this validates one shape rather than two.
function validateFlowchart(lines) {
  const declared = new Set();
  const referenced = new Set();
  assert.equal(lines[0], 'flowchart TD');
  for (const line of lines.slice(1)) {
    const text = line.trim();
    if (text.startsWith('classDef') || text.startsWith('class ') || text.startsWith('linkStyle')) continue;
    const node = /^([A-Za-z0-9_-]+)(\["|\{\{"|\{"|\[\["|\(\(")(.*)("\]|"\}\}|"\}|"\]\]|"\)\))$/.exec(text);
    if (node) {
      assert(!declared.has(node[1]), `node ${node[1]} declared twice`);
      assert(!node[3].includes('"'), `node ${node[1]} label carries a raw quote`);
      declared.add(node[1]);
      continue;
    }
    const edge = /^([A-Za-z0-9_-]+) -->\|"([^"]*)"\| ([A-Za-z0-9_-]+)$/.exec(text);
    assert(edge, `unrecognised line: ${text}`);
    referenced.add(edge[1]);
    referenced.add(edge[3]);
  }
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
    { scenarioId: 'root-scenario', minimumDepth: 0, cycleDetected: false,
      face: { inputId: 'in', eventId: 'requested', outcomeId: 'out', responsibility: 'does the thing' },
      definitions: [
        { definitionDigest: 'sha256:11', format: 'sidefx-semantic-definition.v1', specification: null,
          face: { capabilityId: 'example-capability', event: 'requested', input: 'in', outcome: 'out' } }] },
    { scenarioId: 'orphan-scenario', minimumDepth: 1, cycleDetected: false,
      face: { inputId: null, eventId: null, outcomeId: null, responsibility: null }, definitions: [] },
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
  blueprints: [],
  // The estate configures this platform capability with a transformation on 4 of
  // its 5 ports, so the one here that declares none is the exception.
  platformCapabilityUsage: [{ platformCapabilityId: 'example-platform.v1', portCount: 5, withTransformation: 4 }],
  implementations: [{ platformCapabilityId: 'example-platform.v1', providerId: 'Example.Provider', mechanicId: null, definitionProfile: null }],
  mechanics: [],
  providers: ['Example.Provider'],
};

// A retained blueprint candidate, shaped as the estate declares one.
const blueprint = {
  blueprintId: 'example-capability-blueprint.v1', definitionDigest: 'sha256:ee',
  carrierVersion: 'canonical-circuit-blueprint.v1',
  capability: { capabilityId: 'example-capability', version: '0.1.0' },
  nodes: [
    { nodeId: 'root-cell', kind: 'responsibility', altitude: 'CAPABILITY', projectionOrdinal: 0,
      cell: { first: { identity: 'in' }, energized: { identity: 'requested' }, result: { identity: 'out' } } },
    { nodeId: 'decide', kind: 'junction', altitude: 'CAPABILITY', projectionOrdinal: 1,
      cell: { first: { identity: 'in' }, energized: { identity: 'decided' }, result: { identity: 'disposition' } } },
    { nodeId: 'gather', kind: 'convergence', altitude: 'CAPABILITY', projectionOrdinal: 2, requiredProducts: ['a', 'b'] },
    { nodeId: 'slot', kind: 'provider-slot', altitude: 'PROVIDER', projectionOrdinal: 3,
      providerSlot: { portId: 'a-port', mode: 'projected-capability-invocation' } },
    { nodeId: 'done', kind: 'terminal', altitude: 'CAPABILITY', projectionOrdinal: 4, terminalDisposition: 'COMPLETED' },
    { nodeId: 'held-other', kind: 'terminal', altitude: 'CAPABILITY', projectionOrdinal: 5, terminalDisposition: 'EFFECT_OBSERVED' },
  ],
  edges: [
    { from: 'root-cell', to: 'decide', topology: 'TRANSITION', semanticProgress: 'NARROWS', projectionOrdinal: 0 },
    { from: 'decide', to: 'gather', topology: 'BRANCH_ROUTE', semanticProgress: 'ESTABLISHES', selectingVariant: 'ACCEPTED', projectionOrdinal: 1 },
    { from: 'gather', to: 'slot', topology: 'ALTITUDE_DESCENT', semanticProgress: 'DESCENDS', projectionOrdinal: 2 },
    { from: 'slot', to: 'done', topology: 'BOUNDED_RETURN', semanticProgress: 'BOUNDED_RETURN', projectionOrdinal: 3,
      boundedReturn: { kind: 'RESUMPTION', bound: 1 } },
    { from: 'decide', to: 'held-other', topology: 'BRANCH_ROUTE', semanticProgress: 'TERMINATES', selectingVariant: 'OBSERVED', projectionOrdinal: 4 },
  ],
};

test('today and a blueprint candidate render through one shape', () => {
  const counts = validateFlowchart(blueprintDiagram(circuitFromAuthority(meaning)));
  assert(counts.declared > 0 && counts.referenced > 0);
  validateFlowchart(blueprintDiagram(blueprint));
});

test('the circuit carries the declared execution order and where definitions disagree', () => {
  const circuit = blueprintDiagram(circuitFromAuthority(meaning)).join('\n');
  // operations is an ordered array; the step numbers are that order.
  assert.match(circuit, /\|"2 of 3 definitions \/ invoke-port \/ step 1"\|/);
  // An operation naming neither a port nor a scenario is still drawn.
  assert.match(circuit, /emit-observation<br\/>emit-observation \/ CAPABILITY/);
  assert.match(circuit, /\|"1 of 3 definitions \/ invoke-scenario \/ step 2"\|/);
  // The declared face is the label, in the estate's canonical line order.
  assert.match(circuit, /responsibility \/ CAPABILITY<br\/>I: in<br\/>E: requested<br\/>O: out/);
  // Declared gaps are stated on the node and carry the house rejection style.
  assert.match(circuit, /no execution authority declares it/);
  assert.match(circuit, /declared, not resolved into the closure/);
  assert.match(circuit, /class [A-Za-z0-9_,-]+ rejection/);
});

test('a blueprint draws its declared kinds, faces and edge captions', () => {
  const drawn = blueprintDiagram(blueprint).join('\n');
  assert.match(drawn, /root-cell\["root-cell<br\/>responsibility \/ CAPABILITY<br\/>I: in<br\/>E: requested<br\/>O: out"\]/);
  assert.match(drawn, /decide\{"decide<br\/>junction/);
  assert.match(drawn, /gather\{\{"gather<br\/>convergence \/ CAPABILITY<br\/>R: a \+ b"\}\}/);
  assert.match(drawn, /slot\[\["slot<br\/>provider-slot \/ PROVIDER<br\/>P: a-port \/ projected-capability-invocation"\]\]/);
  assert.match(drawn, /done\(\("done<br\/>terminal \/ CAPABILITY<br\/>COMPLETED"\)\)/);
  assert.match(drawn, /\|"ACCEPTED \/ BRANCH_ROUTE \/ ESTABLISHES"\|/);
  assert.match(drawn, /\|"ALTITUDE_DESCENT \/ DESCENDS \/ projected-capability-invocation"\|/);
  assert.match(drawn, /\|"BOUNDED_RETURN \/ BOUNDED_RETURN \/ RESUMPTION:1"\|/);
  // A COMPLETED terminal is classed; a disposition the estate does not use as a
  // completion or hold vocabulary is left neutral rather than sorted into one.
  assert.match(drawn, /class done success/);
  assert.match(drawn, /class held-other terminal/);
  assert.match(drawn, /linkStyle \d+ stroke-dasharray: 8 4/);
});

test('proposed against today reports each side without choosing between them', () => {
  const comparison = compareBlueprintToCircuit(blueprint, meaning);
  assert.deepEqual(comparison.ports.proposedOnly, ['a-port']);
  assert.deepEqual(comparison.ports.todayOnly, ['example-port']);
  assert.deepEqual(comparison.cells.proposedOnly, ['decide', 'root-cell']);
  assert.deepEqual(comparison.cells.todayOnly, ['orphan-scenario', 'root-scenario']);
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
