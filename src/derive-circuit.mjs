import { createHash } from 'node:crypto';

// Derive a capability's circuits from the selected database authority.
//
// A circuit is a view of authority, not a separately compiled product: the
// database selects the capability, its declared scenario closure and its
// declared effect ports, and this projects them into the workbench's
// `circuit-scene.v1` contract. It is the same authority `invoke` reads, so the
// circuits and the executed body agree by construction and nothing outside the
// database participates.

const entityId = (...parts) => 'n-' + createHash('sha256').update(parts.join('/')).digest('hex').slice(0, 24);
const BOX = [270, 135];
const GAP = 190;
const TRANSFORMATION_PORT = 'sda-authority-transformation-port.v1';

function sourceDocument(bundle, sourcePath) {
  const records = [...bundle.authority.recordsets[1], ...bundle.authority.recordsets[2]];
  for (const record of records) {
    if (record.source_path === sourcePath) {
      return JSON.parse(Buffer.from(record.content_bytes.base64, 'base64').toString('utf8'));
    }
  }
  return null;
}

// A capability obtains external testimony through declared effect ports, read
// from the same interface authority the planner materializes.
function declaredEffectPorts(capabilityId, bundle) {
  const interfaces = sourceDocument(bundle, `capabilities/${capabilityId}/interfaces.authority.json`);
  if (!interfaces) return [];
  return (interfaces.portBindings ?? []).filter(binding => binding.platformCapabilityId !== TRANSFORMATION_PORT);
}

function deriveScenario({ bundle, capabilityId, scenario, effectPorts }) {
  const scenarioId = scenario.downstream_scenario_id;
  const digest = String(scenario.scenario_definition_digest ?? '').replace(/^sha256:/, '') || '0'.repeat(64);
  const source = pointer => ({
    id: 'authority', path: 'analysis/capability-embodiment.sql', sha256: digest, pointer,
    kind: 'DECLARED', label: `estate authority / ${capabilityId}`, encoding: 'sql-recordset',
  });
  const nodes = [], routes = [], boxes = {};
  const place = (index, node) => {
    nodes.push(node);
    boxes[node.id] = [index * (BOX[0] + GAP) + 40, 60, BOX[0], BOX[1]];
  };
  const id = role => entityId(capabilityId, scenarioId, role);
  const inputNode = id('input'), portNode = id('operation'), providerNode = id('provider'), outcomeNode = id('outcome');

  place(0, { id: inputNode, identity: `${capabilityId}/${scenarioId}/input`, kind: 'input', label: scenario.input_id,
    detail: 'Declared scenario input contract.', source: source('/input_id'),
    facts: { contractId: scenario.input_id, scenarioId } });
  place(1, { id: portNode, identity: `${capabilityId}/${scenarioId}.operation`, kind: 'provider-port', label: scenario.event_id,
    detail: scenario.responsibility || 'Declared event authority.', source: source('/event_id'),
    facts: { eventId: scenario.event_id, responsibility: scenario.responsibility, scenarioId } });
  place(3, { id: outcomeNode, identity: `${capabilityId}/${scenarioId}/outcome`, kind: 'outcome', label: scenario.outcome_id,
    detail: 'Declared scenario outcome contract.', source: source('/outcome_id'),
    facts: { contractId: scenario.outcome_id, scenarioId } });

  const findings = [];
  if (effectPorts.length) {
    const exchange = effectPorts.find(port => port.configuration?.endpointAuthorities);
    const credential = effectPorts.find(port => port.configuration?.credentialAuthorities);
    const endpoint = exchange?.configuration?.endpointAuthorities?.[0] ?? {};
    const origins = endpoint.urlPrefixes ?? [];
    place(2, { id: providerNode, identity: `${capabilityId}/${scenarioId}/provider`, kind: 'provider',
      label: origins[0] ?? 'declared provider',
      detail: `Declared effect ports: ${effectPorts.map(port => port.platformCapabilityId).join(', ')}`,
      source: { ...source('/interfaces'), path: 'interfaces.authority.json', encoding: 'declared-authority' },
      facts: { effectPorts: effectPorts.map(port => port.platformCapabilityId),
        endpointAuthorityDigest: endpoint.endpointAuthorityDigest, endpointPrefixes: origins,
        credentialReferences: [...new Set((credential?.configuration?.credentialAuthorities ?? [])
          .map(authority => authority.referenceName).filter(Boolean))].sort() } });
  } else {
    findings.push({ code: 'CIRCUIT_PROVIDER_BINDING_ABSENT', severity: 'info', identity: scenarioId,
      detail: 'no declared effect port; the operation stands alone' });
  }

  const route = (kind, label, from, to, pointer, traversable = true) => routes.push({
    id: entityId(capabilityId, scenarioId, kind, from, to), identity: `${kind}:${from}->${to}`,
    source: from, target: to, kind, label, traversable, provenance: source(pointer), facts: { scenarioId } });
  route('operation-order', 'admits', inputNode, portNode, '/input_id');
  if (effectPorts.length) route('provider-binding', 'bound effect port', providerNode, portNode, '/interfaces/portBindings', false);
  route('operation-result', 'resolves', portNode, outcomeNode, '/outcome_id');

  const width = Math.max(...Object.values(boxes).map(box => box[0] + box[2])) + 40;
  const height = Math.max(...Object.values(boxes).map(box => box[1] + box[3])) + 60;
  return {
    sceneVersion: 'circuit-scene.v1',
    sceneId: `${capabilityId}/${entityId(capabilityId, scenarioId, 'operations')}`,
    label: `Execution · ${(scenario.responsibility || scenarioId).slice(0, 80)}`,
    identities: { capabilityId, viewId: entityId(capabilityId, scenarioId, 'operations'), viewKind: 'operations',
      sourceIdentity: `${capabilityId}/operations/${scenarioId}`, scenarioId },
    traceMode: 'ILLUSTRATIVE',
    graph: { nodes, routes },
    geometry: { width, height, engine: 'derive-circuit.v1', boxes, overlaps: 0 },
    materials: [],
    hitTargets: [
      ...nodes.map(node => ({ targetId: node.id, entityKind: 'node', entityId: node.id, accessibleName: `${node.kind}: ${node.label}`, keyboardActivable: true })),
      ...routes.map(route_ => ({ targetId: route_.id, entityKind: 'route', entityId: route_.id, accessibleName: `${route_.kind}: ${route_.label}`, keyboardActivable: true })),
    ],
    coverage: { nodes: nodes.length, routes: routes.length, omittedSourceNodes: 0, omittedSourceEdges: 0, representationComplete: true,
      nodeKinds: Object.fromEntries([...new Set(nodes.map(n => n.kind))].map(kind => [kind, nodes.filter(n => n.kind === kind).length])),
      routeKinds: Object.fromEntries([...new Set(routes.map(r => r.kind))].map(kind => [kind, routes.filter(r => r.kind === kind).length])),
      observability: { instrumented: true, note: 'This capability reports scenario observations when invoked; the execution mapping places them on these nodes.' } },
    topology: { roots: [inputNode], leaves: [outcomeNode], weakComponents: 1, cyclicComponentCount: 0 },
    provenance: {
      sourceAuthority: { snapshotId: bundle.authority.snapshotId, projectionDigest: bundle.authority.projectionDigest,
        scenarioDefinitionDigest: scenario.scenario_definition_digest, readPerInvocation: true },
      ingestedFrom: { path: 'estate authority (read and planned per invocation)',
        sha256: createHash('sha256').update(JSON.stringify(scenario)).digest('hex') },
      adapter: { name: 'derive-circuit', version: '1.0.0' },
    },
    findings,
  };
}

// Every scenario in the declared closure gets its own view. A caller selects one
// by view id; the catalogue lists them without fetching any scene.
export function deriveCapability({ bundle, capabilityId }) {
  if (bundle.closure.recordsets[0].some(row => row.cycle_detected)) throw new Error('SCENARIO_INVOCATION_CYCLE');
  const effectPorts = declaredEffectPorts(capabilityId, bundle);
  const views = bundle.closure.recordsets[0]
    .slice()
    .sort((left, right) => left.minimum_depth - right.minimum_depth || left.downstream_scenario_id.localeCompare(right.downstream_scenario_id))
    .map(scenario => deriveScenario({ bundle, capabilityId, scenario, effectPorts }));
  return { snapshotId: bundle.authority.snapshotId, projectionDigest: bundle.authority.projectionDigest, capabilityId, views };
}

export function deriveCircuit({ bundle, capabilityId, scenarioId }) {
  const { views } = deriveCapability({ bundle, capabilityId });
  if (scenarioId === undefined) return views[0];
  const selected = views.find(view => view.identities.scenarioId === scenarioId);
  if (!selected) throw new Error('SCENARIO_NOT_IN_CAPABILITY');
  return selected;
}
