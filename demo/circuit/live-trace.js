/**
 * Copied from sfx-platform/lib/live-trace.ts (sfx-platform d62697e), types removed.
 *
 * Only testimony moves a node: a cell's own testimony sets that cell's state, and a drawn node's
 * state is the aggregate of its member cells. Run start and run end light nothing.
 */

const FAILED_STATUS = new Set(['failed', 'rejected', 'admission-rejected', 'error']);
const DONE_STATUS = new Set(['completed', 'observed', 'admitted', 'terminated', 'succeeded', 'selected']);
const ACTIVE_STATUS = new Set(['started', 'deferred', 'buffered', 'pending']);

function isTestimony(facts) {
  return typeof facts.testimonyType === 'string' && facts.testimonyType.length > 0;
}

export function cellState(facts) {
  const status = facts.disposition ?? facts.status;
  const testimony = facts.testimonyType ?? facts.observationType ?? '';
  const displayStatus = facts.display?.entry?.status;
  const variant = facts.outcomeVariant ?? '';
  // A cell's own testimony may classify its outcome without a failed disposition: a provider
  // exchange retained as a non-success is a failure, shown as such rather than hidden behind
  // `completed`.
  if (
    facts.failureCode ||
    testimony.includes('failure') ||
    displayStatus === 'failed' ||
    facts.outcomeClassification === 'failure' ||
    variant.startsWith('retained-non-success') ||
    (status ? FAILED_STATUS.has(status) : false)
  ) {
    return 'failed';
  }
  if (status && DONE_STATUS.has(status)) return 'done';
  if (status && ACTIVE_STATUS.has(status)) return 'active';
  if (facts.cellId && isTestimony(facts)) return 'active';
  return undefined;
}

export function edgeState(facts) {
  const admission = facts.admissionDisposition ?? facts.disposition;
  const testimony = facts.testimonyType ?? facts.observationType ?? '';
  if (facts.failureCode || testimony.includes('failure') || (admission ? FAILED_STATUS.has(admission) : false)) return 'failed';
  if (admission && DONE_STATUS.has(admission)) return 'done';
  if (admission && ACTIVE_STATUS.has(admission)) return 'active';
  // A cancelled admission is testimony that the edge was not taken: it stays planned (unlit).
  if (admission === 'cancelled') return undefined;
  if (facts.edgeId && isTestimony(facts)) return 'done';
  return undefined;
}

export function aggregateNode(view, nodeId, cells) {
  const node = view.nodes.find((candidate) => candidate.id === nodeId);
  if (!node) return 'planned';
  let failed = false;
  let observed = false;
  let incomplete = false;
  for (const member of node.memberCellIds) {
    const state = cells[member];
    if (state === 'failed') failed = true;
    else if (state === 'done') observed = true;
    else if (state === 'active') {
      observed = true;
      incomplete = true;
    }
  }
  if (failed) return 'failed';
  if (!observed) return 'planned';
  if (incomplete) return 'active';
  return 'done';
}

export function aggregateEdge(view, edgeId, edgeStates) {
  const edge = view.edges.find((candidate) => candidate.id === edgeId);
  if (!edge) return 'planned';
  let result = 'planned';
  for (const member of edge.memberEdgeIds) {
    const state = edgeStates[member];
    if (state === 'failed') return 'failed';
    if (state === 'active') result = 'active';
    else if (state === 'done' && result !== 'active') result = 'done';
  }
  return result;
}
