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
const STYLES = [
  'classDef capability fill:#dbeafe,stroke:#1d4ed8,stroke-width:2px,color:#0f172a',
  'classDef scenario fill:#e0e7ff,stroke:#4338ca,color:#0f172a',
  'classDef authority fill:#dcfce7,stroke:#15803d,color:#0f172a',
  'classDef port fill:#fef9c3,stroke:#a16207,color:#0f172a',
  'classDef platform fill:#fae8ff,stroke:#a21caf,color:#0f172a',
  'classDef provider fill:#ffedd5,stroke:#c2410c,color:#0f172a',
  'classDef mechanic fill:#f1f5f9,stroke:#475569,color:#0f172a',
  'classDef divergent fill:#fee2e2,stroke:#b91c1c,stroke-width:2px,color:#0f172a',
  'classDef unresolved fill:#fee2e2,stroke:#b91c1c,stroke-dasharray:4 3,color:#0f172a',
];

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

// The scenarios this capability orchestrates, over the invocations the model
// declares as relationships. Not an ordering guessed from closure depth.
export function scenarioDiagram(meaning) {
  const { capability, scenarios, invocations } = meaning;
  const id = naming();
  const lines = ['flowchart TD', ...STYLES.map(style => `  ${style}`)];
  const present = new Set(scenarios.map(scenario => scenario.scenarioId));
  for (const scenario of scenarios) {
    const root = scenario.scenarioId === capability.selectedScenarioId;
    lines.push(`  ${id(scenario.scenarioId)}["${label(scenarioTitle(scenario))}"]:::${root ? 'capability' : 'scenario'}`);
  }
  for (const edge of invocations) {
    if (!present.has(edge.fromScenarioId) || !present.has(edge.toScenarioId)) continue;
    lines.push(`  ${id(edge.fromScenarioId)} --> ${id(edge.toScenarioId)}`);
  }
  return lines;
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

export function circuitDiagram(meaning) {
  const { capability, scenarios, executionAuthorities, ports, mechanics, implementations } = meaning;
  const id = naming();
  const lines = ['flowchart LR', ...STYLES.map(style => `  ${style}`)];
  const inClosure = new Set(scenarios.map(scenario => scenario.scenarioId));
  const portsById = new Map(ports.map(port => [port.portId, port]));
  const edges = [];
  const unresolved = new Set();

  const capabilityNode = id(`cap:${capability.capabilityId}`);
  lines.push('  subgraph g0["Capability"]');
  lines.push(`    ${capabilityNode}["${label(capability.capabilityId)}"]:::capability`);
  lines.push('  end');

  const owners = new Set(executionAuthorities.flatMap(authority =>
    authority.definitions.map(definition => definition.owningScenarioId).filter(Boolean)));
  lines.push(`  subgraph g1["Scenarios (${scenarios.length})"]`);
  for (const scenario of scenarios) {
    // A scenario no authority owns declares nothing to execute. It is drawn as
    // that rather than as an ordinary node in the chain.
    const gap = !owners.has(scenario.scenarioId);
    lines.push(`    ${id(`scn:${scenario.scenarioId}`)}["${label(scenarioTitle(scenario))}${gap ? '<br/>(no execution authority)' : ''}"]:::${gap ? 'unresolved' : 'scenario'}`);
  }
  if (!scenarios.length) lines.push(`    ${id('scn:none')}["(no scenario in closure)"]:::unresolved`);
  lines.push('  end');
  if (capability.declaredRootCount === 1 && inClosure.has(capability.declaredRootScenarioId)) {
    edges.push(`  ${capabilityNode} -->|declared root| ${id(`scn:${capability.declaredRootScenarioId}`)}`);
  }

  lines.push(`  subgraph g2["Execution authorities (${executionAuthorities.length})"]`);
  for (const authority of executionAuthorities) {
    const shapes = new Set(authority.definitions.map(definition => JSON.stringify(definition.operations)));
    const detail = authority.definitions.length > 1
      ? `<br/>${authority.definitions.length} definitions, ${shapes.size} operation set${shapes.size === 1 ? '' : 's'}` : '';
    lines.push(`    ${id(`aut:${authority.authorityId}`)}["${label(authority.authorityId)}${detail}"]:::${shapes.size > 1 ? 'divergent' : 'authority'}`);
  }
  if (!executionAuthorities.length) lines.push(`    ${id('aut:none')}["(no execution authority declared)"]:::unresolved`);
  lines.push('  end');

  const usedPorts = new Set();
  const others = new Map();
  for (const authority of executionAuthorities) {
    const node = id(`aut:${authority.authorityId}`);
    const total = authority.definitions.length;
    for (const owner of new Set(authority.definitions.map(definition => definition.owningScenarioId))) {
      if (owner && inClosure.has(owner)) edges.push(`  ${id(`scn:${owner}`)} --> ${node}`);
    }
    for (const { operation, count, positions } of operationCounts(authority.definitions).values()) {
      // Only a partial count is called out: it is the fact that divides the
      // definitions. A count equal to the total is the whole declaration.
      const share = total > 1 && count < total ? ` (${count} of ${total} definitions)` : '';
      const caption = `${step(positions)}${label(operation.kind)}${share}`;
      if (operation.portId) {
        usedPorts.add(operation.portId);
        edges.push(`  ${node} -->|${caption}| ${id(`prt:${operation.portId}`)}`);
        continue;
      }
      if (operation.kind === 'invoke-scenario' && operation.scenarioId) {
        if (inClosure.has(operation.scenarioId)) {
          edges.push(`  ${node} -->|${caption}| ${id(`scn:${operation.scenarioId}`)}`);
        } else {
          unresolved.add(operation.scenarioId);
          edges.push(`  ${node} -.->|${caption}, not in closure| ${id(`unr:${operation.scenarioId}`)}`);
        }
        continue;
      }
      others.set(`opk:${operation.kind}`, operation.kind);
      edges.push(`  ${node} -->|${caption}| ${id(`opk:${operation.kind}`)}`);
    }
  }

  if (others.size) {
    lines.push(`  subgraph g8["Other declared operations (${others.size})"]`);
    for (const [key, kind] of others) lines.push(`    ${id(key)}["${label(kind)}"]:::authority`);
    lines.push('  end');
  }

  if (unresolved.size) {
    lines.push(`  subgraph g3["Declared, not resolved into the closure (${unresolved.size})"]`);
    for (const scenarioId of [...unresolved].sort()) {
      lines.push(`    ${id(`unr:${scenarioId}`)}["${label(scenarioId)}"]:::unresolved`);
    }
    lines.push('  end');
  }

  const drawnPorts = ports.filter(port => usedPorts.has(port.portId));
  lines.push(`  subgraph g4["Ports (${usedPorts.size})"]`);
  for (const port of drawnPorts) {
    const transformations = [...new Set(port.definitions.map(definition => definition.transformationId).filter(Boolean))];
    const detail = transformations.length
      ? `<br/>transformation: ${transformations.map(label).join('<br/>')}` : '<br/>(no transformation declared)';
    lines.push(`    ${id(`prt:${port.portId}`)}["${label(port.portId)}${detail}"]:::port`);
  }
  for (const portId of usedPorts) {
    // An operation naming a port the model does not define is drawn as that.
    if (!portsById.has(portId)) lines.push(`    ${id(`prt:${portId}`)}["${label(portId)}<br/>(no port definition)"]:::unresolved`);
  }
  lines.push('  end');

  const platforms = [...new Set(drawnPorts.flatMap(port =>
    port.definitions.map(definition => definition.platformCapabilityId).filter(Boolean)))].sort();
  if (platforms.length) {
    lines.push(`  subgraph g5["Platform capabilities (${platforms.length})"]`);
    for (const platform of platforms) {
      const implemented = implementations.some(item => item.platformCapabilityId === platform);
      lines.push(`    ${id(`pfm:${platform}`)}["${label(platform)}${implemented ? '' : '<br/>(no provider implements it)'}"]:::${implemented ? 'platform' : 'unresolved'}`);
    }
    lines.push('  end');
  }
  for (const port of drawnPorts) {
    for (const platform of new Set(port.definitions.map(definition => definition.platformCapabilityId).filter(Boolean))) {
      edges.push(`  ${id(`prt:${port.portId}`)} --> ${id(`pfm:${platform}`)}`);
    }
  }

  const providers = [...new Set(implementations.map(item => item.providerId))].sort();
  if (providers.length) {
    lines.push(`  subgraph g6["Providers (${providers.length})"]`);
    for (const provider of providers) {
      // A provider declaring no mechanic is a circuit reaching it with no
      // declared mechanism behind it.
      const bare = !implementations.some(item => item.providerId === provider && item.mechanicId !== null);
      lines.push(`    ${id(`prv:${provider}`)}["${label(provider)}${bare ? '<br/>(declares no mechanic)' : ''}"]:::${bare ? 'unresolved' : 'provider'}`);
    }
    lines.push('  end');
  }
  const mechanicIds = [...new Set(mechanics.map(mechanic => mechanic.mechanicId))].sort();
  if (mechanicIds.length) {
    lines.push(`  subgraph g7["Mechanics (${mechanicIds.length})"]`);
    for (const mechanic of mechanicIds) lines.push(`    ${id(`mec:${mechanic}`)}["${label(mechanic)}"]:::mechanic`);
    lines.push('  end');
  }
  // Keyed on the values themselves: an identifier carrying a separator must not
  // be able to split one edge into another.
  const drawn = new Set();
  const once = (key, line) => { if (!drawn.has(key)) { drawn.add(key); edges.push(line); } };
  for (const item of implementations) {
    once(JSON.stringify(['pfm-prv', item.platformCapabilityId, item.providerId]),
      `  ${id(`pfm:${item.platformCapabilityId}`)} --> ${id(`prv:${item.providerId}`)}`);
    if (item.mechanicId === null) continue;
    once(JSON.stringify(['prv-mec', item.providerId, item.mechanicId]),
      `  ${id(`prv:${item.providerId}`)} --> ${id(`mec:${item.mechanicId}`)}`);
  }

  return [...lines, ...new Set(edges)];
}
