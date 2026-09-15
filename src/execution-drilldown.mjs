// The execution performance drilldown. The kernel returns testimony for every
// cell and edge it executes; when it offers a live testimony sink this module
// receives each item, streams the ones the caller selected as observations, and
// joins the complete observed path back onto the plan's canonical graph.
const ALTITUDES = ['scenario', 'mechanic', 'provider', 'physical'];
const CELL_TESTIMONY = 'cell-execution-testimony.v1';
const EDGE_TESTIMONY = 'edge-execution-testimony.v1';
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);

export const OBSERVATION_ALTITUDES = ALTITUDES;

export function isObservationAltitudeSelection(value) {
  return Array.isArray(value) && value.length > 0
    && value.every(altitude => ALTITUDES.includes(altitude))
    && new Set(value).size === value.length;
}

const cellKey = testimony => testimony.cellExecutionId ?? `${testimony.cellId}:${testimony.logicalOrder}`;
const edgeKey = testimony => `${testimony.edgeId}:${testimony.logicalOrder}`;

const cellObservation = (testimony, scenarioId) => ({
  observationType: CELL_TESTIMONY,
  phase: 'executeDeclaredGraph',
  status: 'observed',
  observedAt: new Date().toISOString(),
  executionId: testimony.cellExecutionId,
  rootExecutionId: testimony.rootExecutionId,
  parentExecutionId: testimony.parentCellExecutionId ?? null,
  scenarioId,
  sequence: testimony.logicalOrder,
  cellId: testimony.cellId,
  cellAltitude: testimony.cellAltitude,
  startedAt: testimony.startedAt,
  completedAt: testimony.completedAt,
  durationMilliseconds: testimony.durationMilliseconds
});

const edgeObservation = (testimony, scenarioId) => ({
  observationType: EDGE_TESTIMONY,
  phase: 'executeDeclaredGraph',
  status: 'observed',
  observedAt: new Date().toISOString(),
  executionId: testimony.sourceCellExecutionId,
  rootExecutionId: testimony.rootExecutionId,
  scenarioId,
  sequence: testimony.logicalOrder,
  edgeId: testimony.edgeId,
  startedAt: testimony.startedAt,
  completedAt: testimony.completedAt,
  durationMilliseconds: testimony.durationMilliseconds
});

const cellSummary = testimony => ({
  cellExecutionId: testimony.cellExecutionId,
  disposition: testimony.disposition,
  outcomeVariant: testimony.outcomeVariant,
  selectedEdgeIds: Array.isArray(testimony.selectedEdgeIds) ? testimony.selectedEdgeIds : [],
  outcomeContractId: testimony.outcomeContractId,
  logicalOrder: testimony.logicalOrder,
  startedAt: testimony.startedAt,
  completedAt: testimony.completedAt,
  durationMilliseconds: testimony.durationMilliseconds
});

const edgeSummary = testimony => ({
  sourceCellExecutionId: testimony.sourceCellExecutionId,
  destinationCellId: testimony.destinationCellId,
  admissionDisposition: testimony.admissionDisposition,
  logicalOrder: testimony.logicalOrder,
  startedAt: testimony.startedAt,
  completedAt: testimony.completedAt,
  durationMilliseconds: testimony.durationMilliseconds
});

const planCells = plan => [...(plan?.canonicalGraph?.cells ?? []), ...(plan?.realizationOverlay?.physicalCells ?? [])];
const planEdges = plan => [...(plan?.canonicalGraph?.edges ?? []), ...(plan?.realizationOverlay?.physicalEdges ?? [])];

export function createExecutionDrilldown({ observationAltitudes, scenarioId, observe }) {
  const selected = new Set(observationAltitudes ?? ALTITUDES);
  const cells = new Map();
  const edges = new Map();
  let plan = null;
  let altitudeByCellId = null;

  const remember = testimony => {
    if (!object(testimony)) return;
    if (testimony.testimonyType === CELL_TESTIMONY) {
      const key = cellKey(testimony);
      if (!cells.has(key)) cells.set(key, testimony);
    } else if (testimony.testimonyType === EDGE_TESTIMONY) {
      const key = edgeKey(testimony);
      if (!edges.has(key)) edges.set(key, testimony);
    }
  };

  // The selected altitudes scope the cells. Every edge is streamed when the whole
  // altitude range is selected; otherwise an edge streams when it enters a cell at
  // a selected altitude.
  const sink = testimony => {
    try {
      remember(testimony);
      if (testimony.testimonyType === CELL_TESTIMONY) {
        if (selected.has(testimony.cellAltitude)) observe(cellObservation(testimony, scenarioId));
      } else if (testimony.testimonyType === EDGE_TESTIMONY) {
        const altitude = altitudeByCellId?.get(testimony.destinationCellId);
        if (selected.size === ALTITUDES.length || selected.has(altitude)) observe(edgeObservation(testimony, scenarioId));
      }
    } catch { /* Testimony is not execution authority. */ }
  };

  // When the kernel does not stream, its result still carries the testimony; it is
  // absorbed so the overlay and digest are identical either way.
  const absorb = result => {
    for (const testimony of result?.cellTestimony ?? []) remember(testimony);
    for (const testimony of result?.edgeTestimony ?? []) remember(testimony);
  };

  // The compile boundary produces the plan the execute boundary consumes. A caller
  // captures it from the running carrier so the planned topology is never guessed.
  const setPlan = value => {
    if (plan === null && object(value) && object(value.canonicalGraph)) {
      plan = value;
      altitudeByCellId = new Map(planCells(plan).map(cell => [cell.cellId, cell.altitude]));
    }
  };

  const buildOverlay = result => {
    const canonical = plan?.canonicalGraph ?? result?.canonicalGraph ?? null;
    const realization = plan?.realizationOverlay ?? result?.realizationOverlay ?? null;
    const plannedCells = [...(canonical?.cells ?? []), ...(realization?.physicalCells ?? [])];
    const plannedEdges = [...(canonical?.edges ?? []), ...(realization?.physicalEdges ?? [])];
    const observedCells = new Map();
    for (const testimony of cells.values()) {
      if (!observedCells.has(testimony.cellId)) observedCells.set(testimony.cellId, []);
      observedCells.get(testimony.cellId).push(cellSummary(testimony));
    }
    const observedEdges = new Map();
    for (const testimony of edges.values()) {
      if (!observedEdges.has(testimony.edgeId)) observedEdges.set(testimony.edgeId, []);
      observedEdges.get(testimony.edgeId).push(edgeSummary(testimony));
    }
    const cellIds = new Set(plannedCells.map(cell => cell.cellId));
    const edgeIds = new Set(plannedEdges.map(edge => edge.edgeId));
    const cellRows = plannedCells.map(cell => ({
      cellId: cell.cellId,
      altitude: cell.altitude,
      parentCellId: cell.parentCellId ?? null,
      planned: { inputContractId: cell.input?.contractId, outcomeContractId: cell.outcome?.contractId,
        executionAuthorityId: cell.execution?.authorityId, authorityDigest: cell.execution?.authorityDigest },
      observed: observedCells.get(cell.cellId) ?? []
    }));
    for (const [cellId, observed] of observedCells) if (!cellIds.has(cellId))
      cellRows.push({ cellId, altitude: observed[0]?.cellAltitude ?? null, parentCellId: null, planned: null, observed });
    const edgeRows = plannedEdges.map(edge => ({
      edgeId: edge.edgeId,
      kind: edge.kind,
      planned: { from: edge.from ?? null, to: edge.to ?? null, selectsVariant: edge.selectsVariant ?? null },
      observed: observedEdges.get(edge.edgeId) ?? []
    }));
    for (const [edgeId, observed] of observedEdges) if (!edgeIds.has(edgeId))
      edgeRows.push({ edgeId, kind: null, planned: null, observed });
    return {
      graphId: canonical?.graphId ?? result?.graphId ?? null,
      canonicalGraphDigest: plan?.canonicalGraphDigest ?? result?.canonicalGraphDigest ?? null,
      observedPathDigest: result?.observedPathDigest ?? null,
      cells: cellRows,
      edges: edgeRows,
      counts: { plannedCells: plannedCells.length, observedCells: cells.size,
        plannedEdges: plannedEdges.length, observedEdges: edges.size }
    };
  };

  return { sink, absorb, setPlan, buildOverlay };
}
