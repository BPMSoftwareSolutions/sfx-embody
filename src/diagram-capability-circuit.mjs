// Mermaid diagrams of a capability's declared circuit and its execution order.
//
// Layout and styling only. Every node, edge and step corresponds to a
// relationship the estate model declares; nothing here infers a connection,
// completes a partial chain, or draws a node the authority does not name.
//
// Execution order is authority, not presentation: an execution authority's
// `operations` is an ordered array, and the step numbers below are that order.
//
// Where the model retains several definitions of one declared id and they
// disagree, the circuit draws the union and labels each edge with how many
// definitions declare it and at which step. A reviewer therefore sees the whole
// circuit and exactly where its declarations diverge, rather than a tidy union
// that no single definition actually declares. The execution-order trace goes
// further and draws one diagram per distinct declared sequence.
//
// Fills are light with explicit dark text so the diagrams stay legible in both
// GitHub themes.
// Mermaid label text: quotes and pipes would end the label or the edge caption.
const label = text => String(text ?? '')
  .replace(/\s*\n\s*/g, ' ').replace(/"/g, '#quot;').replace(/\|/g, '/');
// A sequence-diagram alias additionally cannot carry the message separator.
const alias = text => label(text).replace(/[:;]/g, ' -');

function naming() {
  const ids = new Map();
  return key => {
    if (!ids.has(key)) ids.set(key, `n${ids.size}`);
    return ids.get(key);
  };
}

const operationKey = operation => `${operation.kind} ${operation.portId ?? operation.scenarioId ?? ''}`;
const scenarioTitle = scenario =>
  scenario.definitions.find(definition => definition.specification)?.specification.name ?? scenario.scenarioId;

// Which declarations name each operation, and at which step. A definition naming
// the same operation twice counts once per definition: this counts declarations,
// not repetitions, and keeps every declared position.
function operationCounts(definitions) {
  const counts = new Map();
  for (const definition of definitions) {
    const seen = new Set();
    (definition.operations ?? []).forEach((operation, index) => {
      const key = operationKey(operation);
      if (seen.has(key)) return;
      seen.add(key);
      const entry = counts.get(key) ?? { operation, count: 0, positions: new Set() };
      entry.count += 1;
      entry.positions.add(index + 1);
      counts.set(key, entry);
    });
  }
  return counts;
}

// The declared step, or the several steps the definitions disagree about.
function step(positions) {
  const ordered = [...positions].sort((a, b) => a - b);
  return ordered.length === 1 ? `${ordered[0]}. ` : `steps ${ordered.join(' or ')}: `;
}

// One trace per distinct declared sequence. Definitions that declare the same
// sequence share a diagram; definitions that disagree get their own, so the
// order a reviewer reads is an order some definition actually declares.
export function executionOrderDiagrams(meaning) {
  const { capability, scenarios, executionAuthorities, ports } = meaning;
  const inClosure = new Set(scenarios.map(scenario => scenario.scenarioId));
  const portsById = new Map(ports.map(port => [port.portId, port]));
  const entry = executionAuthorities.filter(authority =>
    authority.definitions.some(definition => definition.owningScenarioId === capability.selectedScenarioId));
  const scenario = scenarios.find(item => item.scenarioId === capability.selectedScenarioId);
  const diagrams = [];

  for (const authority of entry) {
    const sequences = new Map();
    for (const definition of authority.definitions) {
      const key = JSON.stringify((definition.operations ?? []).map(operationKey));
      if (!sequences.has(key)) sequences.set(key, { operations: definition.operations ?? [], digests: [] });
      sequences.get(key).digests.push(definition.definitionDigest);
    }
    for (const sequence of sequences.values()) {
      const id = naming();
      const lines = ['sequenceDiagram', '  autonumber'];
      const callerKey = `scn:${capability.selectedScenarioId}`;
      const caller = id(callerKey);
      lines.push(`  participant ${caller} as ${alias(scenario ? scenarioTitle(scenario) : capability.selectedScenarioId)}`);
      const participants = [];
      for (const operation of sequence.operations) {
        const target = operation.portId ?? operation.scenarioId ?? operation.kind;
        const key = operation.portId ? `prt:${target}` : operation.scenarioId ? `scn:${target}` : `op:${target}`;
        if (key === callerKey || participants.includes(key)) continue;
        participants.push(key);
      }
      for (const key of participants) {
        const name = key.slice(4);
        lines.push(`  participant ${id(key)} as ${alias(name)}`);
      }
      if (!sequence.operations.length) lines.push(`  Note over ${caller}: no operation declared`);
      for (const operation of sequence.operations) {
        const target = operation.portId ?? operation.scenarioId ?? operation.kind;
        const key = operation.portId ? `prt:${target}` : operation.scenarioId ? `scn:${target}` : `op:${target}`;
        const unresolved = operation.kind === 'invoke-scenario' && operation.scenarioId && !inClosure.has(operation.scenarioId);
        lines.push(`  ${caller}->>${id(key)}: ${label(operation.kind)}${unresolved ? ' (not in closure)' : ''}`);
        const port = operation.portId ? portsById.get(operation.portId) : undefined;
        if (!port) continue;
        const transformations = [...new Set(port.definitions.map(definition => definition.transformationId).filter(Boolean))];
        const platforms = [...new Set(port.definitions.map(definition => definition.platformCapabilityId).filter(Boolean))];
        const detail = [platforms.length ? platforms.join(', ') : '(no platform capability declared)',
          transformations.length ? transformations.join(', ') : '(no transformation declared)'].join(' / ');
        lines.push(`  Note right of ${id(key)}: ${label(detail)}`);
      }
      diagrams.push({ authorityId: authority.authorityId, digests: sequence.digests,
        definitionCount: authority.definitions.length, lines });
    }
  }
  return diagrams;
}
