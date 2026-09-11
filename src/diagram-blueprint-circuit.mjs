// The declared circuit blueprint, drawn in the estate's canonical Mermaid shape.
//
// Generated from the BLUEPRINT authority the database retains, every time it is
// asked for. Nothing here is a pre-rendered artifact and nothing is inferred:
// node shape comes from the declared `kind`, the label lines come from the
// declared cell, providerSlot, requiredProducts and terminalDisposition, and
// every edge caption is the declared selectingVariant, topology, semanticProgress
// and boundedReturn.
//
// Node shape by declared kind, matching the estate's blueprint convention:
//   junction        {"..."}      convergence   {{"..."}}
//   provider-slot   [["..."]]    terminal      (("..."))
//   everything else ["..."]
const SHAPES = {
  junction: ['{"', '"}'],
  convergence: ['{{"', '"}}'],
  'provider-slot': ['[["', '"]]'],
  terminal: ['(("', '"))'],
};
const DEFAULT_SHAPE = ['["', '"]'];

// Mermaid is given the declared identifiers as node ids, so the diagram reads and
// greps as the estate names it. Only characters Mermaid cannot carry are changed.
const escape = text => String(text ?? '').replace(/"/g, '#quot;').replace(/\s*\n\s*/g, ' ');
const nodeId = id => String(id ?? '').replace(/[^A-Za-z0-9_-]/g, '-');

// The estate declares 66 distinct terminal dispositions. Only the four literal
// tokens below are classified; every other disposition keeps the neutral
// terminal style rather than being sorted into an outcome it never declared.
const COMPLETING = new Set(['COMPLETED', 'SUCCESS']);
const HOLDING = new Set(['HELD', 'REJECTED']);

function nodeLabel(node) {
  const lines = [escape(node.nodeId), `${escape(node.kind)} / ${escape(node.altitude)}`];
  if (node.cell) {
    const face = [['I', node.cell.first], ['E', node.cell.energized], ['O', node.cell.result]];
    for (const [mark, part] of face) {
      if (part?.identity) lines.push(`${mark}: ${escape(part.identity)}`);
    }
  }
  if (node.kind === 'convergence' && Array.isArray(node.requiredProducts) && node.requiredProducts.length) {
    lines.push(`R: ${node.requiredProducts.map(escape).join(' + ')}`);
  }
  if (node.kind === 'provider-slot' && node.providerSlot) {
    lines.push(`P: ${escape(node.providerSlot.portId)} / ${escape(node.providerSlot.mode)}`);
  }
  if (node.kind === 'terminal' && node.terminalDisposition) lines.push(escape(node.terminalDisposition));
  // A stated gap is a line of the label, in the same shape as everything else.
  if (node.gap) lines.push(escape(node.gap));
  return lines.join('<br/>');
}

function edgeLabel(edge, nodesById) {
  const parts = [];
  if (edge.selectingVariant) parts.push(escape(edge.selectingVariant));
  if (edge.topology) parts.push(escape(edge.topology));
  if (edge.semanticProgress) parts.push(escape(edge.semanticProgress));
  // A descent names the mode the target slot declares; a bounded return names
  // the declared return kind and bound.
  if (edge.topology === 'ALTITUDE_DESCENT') {
    const mode = nodesById.get(edge.to)?.providerSlot?.mode;
    if (mode) parts.push(escape(mode));
  }
  if (edge.boundedReturn?.kind) {
    parts.push(`${escape(edge.boundedReturn.kind)}${edge.boundedReturn.bound === undefined ? '' : `:${escape(edge.boundedReturn.bound)}`}`);
  }
  return parts.join(' / ');
}

export function blueprintDiagram(blueprint) {
  const nodes = [...blueprint.nodes].sort((a, b) => (a.projectionOrdinal ?? 0) - (b.projectionOrdinal ?? 0));
  const edges = [...blueprint.edges].sort((a, b) => (a.projectionOrdinal ?? 0) - (b.projectionOrdinal ?? 0));
  const nodesById = new Map(nodes.map(node => [node.nodeId, node]));
  const lines = ['flowchart TD'];

  for (const node of nodes) {
    const [open, close] = SHAPES[node.kind] ?? DEFAULT_SHAPE;
    lines.push(`  ${nodeId(node.nodeId)}${open}${nodeLabel(node)}${close}`);
  }
  const dashed = [];
  edges.forEach((edge, index) => {
    // A bounded return is drawn dashed, as a return rather than a advance.
    if (edge.topology === 'BOUNDED_RETURN') dashed.push(index);
    lines.push(`  ${nodeId(edge.from)} -->|"${edgeLabel(edge, nodesById)}"| ${nodeId(edge.to)}`);
  });

  lines.push(
    '  classDef scenario fill:#C2E5FF,stroke:#3DADFF',
    '  classDef success fill:#CDF4D3,stroke:#66D575',
    '  classDef failure fill:#FFE0C2,stroke:#FF9E42',
    '  classDef rejection fill:#FFCDC2,stroke:#FF7556',
    '  classDef provider fill:#DCCCFF,stroke:#874FFF',
    '  classDef terminal fill:#E8E8E8,stroke:#8A8A8A');

  const group = predicate => nodes.filter(predicate).map(node => nodeId(node.nodeId));
  const assign = (members, name) => { if (members.length) lines.push(`  class ${members.join(',')} ${name}`); };
  assign(group(node => !node.gap && node.kind !== 'terminal' && node.kind !== 'provider-slot'), 'scenario');
  assign(group(node => !node.gap && node.kind === 'provider-slot'), 'provider');
  assign(group(node => Boolean(node.gap)), 'rejection');
  assign(group(node => !node.gap && node.kind === 'terminal' && COMPLETING.has(node.terminalDisposition)), 'success');
  assign(group(node => !node.gap && node.kind === 'terminal' && HOLDING.has(node.terminalDisposition)), 'failure');
  assign(group(node => !node.gap && node.kind === 'terminal'
    && !COMPLETING.has(node.terminalDisposition) && !HOLDING.has(node.terminalDisposition)), 'terminal');
  for (const index of dashed) lines.push(`  linkStyle ${index} stroke-dasharray: 8 4`);
  return lines;
}

// The circuit the estate declares today, expressed as the same nodes and edges a
// blueprint declares so both render through blueprintDiagram and read as one
// shape. Each side keeps its own declared vocabulary: a blueprint edge is
// captioned with its declared topology, and an authority edge with the operation
// kind the authority actually declares. Nothing is translated between them.
export function circuitFromAuthority(meaning) {
  const { capability, scenarios, executionAuthorities, ports } = meaning;
  const inClosure = new Set(scenarios.map(scenario => scenario.scenarioId));
  const portsById = new Map(ports.map(port => [port.portId, port]));
  const owners = new Set(executionAuthorities.flatMap(authority =>
    authority.definitions.map(definition => definition.owningScenarioId).filter(Boolean)));
  const nodes = [];
  const edges = [];
  const seen = new Set();
  const distinct = (definitions, field) => [...new Set(definitions
    .map(definition => definition[field]).filter(Boolean))].sort();

  scenarios.forEach((scenario, index) => {
    const face = scenario.face ?? {};
    nodes.push({
      nodeId: scenario.scenarioId, kind: 'responsibility', altitude: 'CAPABILITY',
      projectionOrdinal: index,
      cell: { first: { identity: face.inputId }, energized: { identity: face.eventId },
        result: { identity: face.outcomeId } },
      ...(owners.has(scenario.scenarioId) ? {} : { gap: '(no execution authority declares it)' }),
    });
    seen.add(scenario.scenarioId);
  });

  let ordinal = scenarios.length;
  for (const authority of executionAuthorities) {
    const total = authority.definitions.length;
    const owner = distinct(authority.definitions, 'owningScenarioId')[0];
    if (!owner) continue;
    // Declared order is the operations array. Where definitions disagree, the
    // edge says at which step and how many definitions declare it.
    const declared = new Map();
    authority.definitions.forEach(definition => {
      const once = new Set();
      (definition.operations ?? []).forEach((operation, index) => {
        const key = `${operation.kind} ${operation.portId ?? operation.scenarioId ?? ''}`;
        if (once.has(key)) return;
        once.add(key);
        const entry = declared.get(key) ?? { operation, count: 0, positions: new Set() };
        entry.count += 1;
        entry.positions.add(index + 1);
        declared.set(key, entry);
      });
    });
    for (const { operation, count, positions } of declared.values()) {
      const steps = [...positions].sort((a, b) => a - b);
      // An operation naming neither a port nor a scenario is still declared, so
      // it is drawn as itself. Its second label line is the declared kind.
      let target = operation.portId ?? operation.scenarioId;
      if (!target) {
        target = `${authority.authorityId}-${operation.kind ?? 'operation'}`;
        if (!seen.has(target)) {
          nodes.push({ nodeId: target, kind: operation.kind ?? 'operation', altitude: 'CAPABILITY',
            projectionOrdinal: ordinal++ });
          seen.add(target);
        }
      }
      if (operation.portId && !seen.has(operation.portId)) {
        const port = portsById.get(operation.portId);
        nodes.push({
          nodeId: operation.portId, kind: 'provider-slot', altitude: 'PROVIDER',
          projectionOrdinal: ordinal++,
          ...(port ? { providerSlot: { portId: operation.portId,
            mode: distinct(port.definitions, 'platformCapabilityId').join(', ') || null } }
            : { gap: '(no port definition)' }),
          ...(port && !distinct(port.definitions, 'transformationId').length
            ? {} : {}),
        });
        seen.add(operation.portId);
      }
      if (operation.scenarioId && !seen.has(operation.scenarioId) && !inClosure.has(operation.scenarioId)) {
        nodes.push({ nodeId: operation.scenarioId, kind: 'responsibility', altitude: 'CAPABILITY',
          projectionOrdinal: ordinal++, gap: '(declared, not resolved into the closure)' });
        seen.add(operation.scenarioId);
      }
      edges.push({
        from: owner, to: target, projectionOrdinal: edges.length,
        topology: operation.kind,
        semanticProgress: steps.length === 1 ? `step ${steps[0]}` : `steps ${steps.join(' or ')}`,
        ...(total > 1 && count < total ? { selectingVariant: `${count} of ${total} definitions` } : {}),
      });
    }
  }
  return { nodes, edges };
}

// What the blueprint proposed against what the estate declares today. Both sides
// are read from the same snapshot; a name appearing on one side only is reported
// as exactly that, with no guess about which side is right.
export function compareBlueprintToCircuit(blueprint, meaning) {
  const proposedPorts = new Set(blueprint.nodes
    .filter(node => node.kind === 'provider-slot' && node.providerSlot?.portId)
    .map(node => node.providerSlot.portId));
  const todayPorts = new Set(meaning.ports.map(port => port.portId));
  // A blueprint's responsibility and junction nodes are the cells it proposed;
  // today's closure is the scenarios the model resolves.
  const proposedCells = new Set(blueprint.nodes
    .filter(node => ['responsibility', 'junction'].includes(node.kind)).map(node => node.nodeId));
  const todayScenarios = new Set(meaning.scenarios.map(scenario => scenario.scenarioId));
  const split = (left, right) => ({
    both: [...left].filter(item => right.has(item)).sort(),
    proposedOnly: [...left].filter(item => !right.has(item)).sort(),
    todayOnly: [...right].filter(item => !left.has(item)).sort(),
  });
  return { ports: split(proposedPorts, todayPorts), cells: split(proposedCells, todayScenarios) };
}
