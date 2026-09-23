/**
 * Copied from sfx-platform/lib/run-graph.ts (sfx-platform d62697e), types removed.
 *
 * Turns the kernel's circuit record (`execution-graph-captured.v1`: cells and edges with ids,
 * altitudes and parents) into the viewer's nodes and edges. Graphs larger than the detail limit
 * collapse to the nearest enclosing cells; every raw cell and edge keeps a membership entry so its
 * testimony binds by id alone.
 *
 * KNOWN DEFECT (carried from the platform): the collapse rule, the limit, the altitude-to-primitive
 * table and the edge-family mapping are code here, not declared authority.
 */

export const DETAIL_CELL_LIMIT = 30;

function endpointCellId(endpoint) {
  return typeof endpoint === 'string' ? endpoint : endpoint?.cellId;
}

function asString(value) {
  return typeof value === 'string' && value.trim().length > 0 ? value : null;
}

/** A semantic address may be a string or the declared address object; either becomes text. */
export function semanticAddressText(address) {
  if (typeof address === 'string') return asString(address);
  if (address === null || typeof address !== 'object') return null;
  for (const key of ['mechanicId', 'responsibilityId', 'outcomeId', 'eventId', 'inputId']) {
    const value = asString(address[key]);
    if (value) return value;
  }
  return asString(address.semanticRole);
}

function labelForCell(cell) {
  const address = cell.semanticAddress ?? cell.cellId;
  const tail = address.split('/').filter(Boolean).pop() ?? address;
  const cleaned = tail.replace(/^cell:/, '');
  if (cleaned.includes(':')) {
    const parts = cleaned.split(':');
    return parts[parts.length - 1] ?? cleaned;
  }
  return cleaned;
}

export function normalizeRunGraph(graph) {
  return {
    graphId: graph.graphId,
    canonicalGraphDigest: graph.canonicalGraphDigest,
    cells: graph.cells.map((cell) => ({
      cellId: cell.cellId,
      altitude: asString(cell.altitude),
      kind: asString(cell.kind),
      parentCellId: asString(cell.parentCellId),
      semanticAddress: semanticAddressText(cell.semanticAddress),
      ports: cell.ports,
    })),
    edges: graph.edges.map((edge) => ({
      edgeId: edge.edgeId,
      kind: asString(edge.kind),
      from: endpointCellId(edge.from),
      to: endpointCellId(edge.to),
      selectsVariant: edge.selectsVariant ?? null,
      groupId: asString(edge.groupId),
    })),
  };
}

/**
 * When the graph carries more cells than the detail limit, redraw with the nearest enclosing
 * cells only: walk each drawn cell up its parent chain until the drawn set fits. Cells with no
 * parent stay drawn; a flat graph that cannot collapse is drawn whole, never truncated.
 */
export function buildRunGraphView(graph, limit = DETAIL_CELL_LIMIT) {
  const byId = new Map(graph.cells.map((cell) => [cell.cellId, cell]));
  let drawn = new Set(byId.keys());

  while (drawn.size > limit) {
    const promoted = new Set();
    let promotedAny = false;
    for (const cellId of drawn) {
      const parent = byId.get(cellId)?.parentCellId ?? null;
      if (parent && byId.has(parent) && parent !== cellId) {
        promoted.add(parent);
        promotedAny = true;
      } else {
        promoted.add(cellId);
      }
    }
    if (!promotedAny || promoted.size >= drawn.size) break;
    drawn = promoted;
  }

  const nearestDrawn = (cellId) => {
    if (drawn.has(cellId)) return cellId;
    let cursor = byId.get(cellId)?.parentCellId ?? null;
    const seen = new Set();
    while (cursor && byId.has(cursor) && !seen.has(cursor)) {
      if (drawn.has(cursor)) return cursor;
      seen.add(cursor);
      cursor = byId.get(cursor)?.parentCellId ?? null;
    }
    return null;
  };

  const membership = {};
  const membersByNode = new Map();
  for (const cell of graph.cells) {
    const target = nearestDrawn(cell.cellId);
    if (!target) continue;
    membership[cell.cellId] = target;
    const members = membersByNode.get(target) ?? [];
    members.push(cell.cellId);
    membersByNode.set(target, members);
  }

  const nodes = [];
  for (const cell of graph.cells) {
    if (!drawn.has(cell.cellId) || !membership[cell.cellId]) continue;
    if (nodes.some((node) => node.id === cell.cellId)) continue;
    const members = membersByNode.get(cell.cellId) ?? [cell.cellId];
    const label = labelForCell(cell);
    nodes.push({
      id: cell.cellId,
      label: members.length > 1 ? `${label} · ${members.length} cells` : label,
      altitude: cell.altitude,
      kind: cell.kind,
      parentCellId: cell.parentCellId,
      semanticAddress: cell.semanticAddress,
      memberCellIds: members,
      collapsed: members.length > 1,
    });
  }

  const edgeMembership = {};
  const internalEdgeNode = {};
  const drawnEdges = [];
  const edgeByKey = new Map();
  for (const edge of graph.edges) {
    const from = membership[edge.from];
    const to = membership[edge.to];
    // Only a route between two distinct drawn nodes is drawn. A route whose endpoints collapsed
    // into the same drawn node is internal to it: bound to that node, not drawn.
    if (!from || !to) continue;
    if (from === to) {
      internalEdgeNode[edge.edgeId] = from;
      continue;
    }
    const key = `${from}|${to}|${edge.kind ?? ''}`;
    let viewEdge = edgeByKey.get(key);
    if (!viewEdge) {
      viewEdge = { id: edge.edgeId, kind: edge.kind, from, to, selectsVariant: edge.selectsVariant, groupId: edge.groupId, memberEdgeIds: [], collapsed: false };
      edgeByKey.set(key, viewEdge);
      drawnEdges.push(viewEdge);
    }
    viewEdge.memberEdgeIds.push(edge.edgeId);
    edgeMembership[edge.edgeId] = viewEdge.id;
  }
  for (const viewEdge of drawnEdges) viewEdge.collapsed = viewEdge.memberEdgeIds.length > 1;

  return {
    graphId: graph.graphId,
    canonicalGraphDigest: graph.canonicalGraphDigest,
    detailCellLimit: limit,
    totalCells: graph.cells.length,
    totalEdges: graph.edges.length,
    collapsed: drawn.size < byId.size,
    nodes,
    edges: drawnEdges,
    membership,
    edgeMembership,
    internalEdgeNode,
  };
}

const ALTITUDE_PRIMITIVE = { scenario: 'SCENARIO', mechanic: 'MECHANIC', provider: 'PROVIDER', physical: 'PHYSICAL' };

/** An unmapped altitude renders as the visible UNRESOLVED primitive, never a guess. */
export function primitiveForAltitude(altitude) {
  if (!altitude) return 'UNRESOLVED';
  return ALTITUDE_PRIMITIVE[altitude.toLowerCase()] ?? 'UNRESOLVED';
}

function familyForEdge(kind) {
  const value = kind?.toLowerCase() ?? '';
  if (value.includes('product')) return 'PRODUCT_TRANSFER';
  if (value.includes('support')) return 'SUPPORT';
  return 'EXECUTION';
}

/** The viewer's circuit for a collapsed run graph: the planned skeleton, drawn unlit. */
export function runGraphViewProjection(view, options) {
  return {
    capabilityId: options.capabilityId,
    scenarioId: options.scenarioId ?? null,
    sourceProfile: `run-graph:${view.graphId}`,
    sourceDigest: view.canonicalGraphDigest,
    graphDigest: view.canonicalGraphDigest,
    sclVersion: 'run-graph.v1',
    rendererVersion: 'sda-run-graph.v1',
    fidelity: 'RUN_GRAPH',
    nodes: view.nodes.map((node) => ({
      id: node.id,
      primitive: primitiveForAltitude(node.altitude),
      label: node.label,
      sourceId: node.semanticAddress ?? node.id,
      state: {
        value: node.altitude,
        readable: node.collapsed
          ? `Planned view cell enclosing ${node.memberCellIds.length} raw cells; lit only by their testimony.`
          : `Planned ${node.altitude ?? 'unresolved'} cell; lit only by its own testimony.`,
      },
    })),
    edges: view.edges.map((edge) => ({ id: edge.id, from: edge.from, to: edge.to, family: familyForEdge(edge.kind) })),
    diagnostics: [],
  };
}
