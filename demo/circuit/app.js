/**
 * Live circuit monitor over the demo observer.
 *
 * Every `sfx capability observe … --trace` run reaches the observer through the launcher and the
 * estate's declared sink (sfx.config.json `observability.url`): run-start, the kernel's circuit
 * record (`execution-graph-captured.v1`, emitted after compile and before execution), cell and
 * edge testimony, run-end. This page keeps the runs it sees, shows the latest run whose circuit is
 * the filtered capability, and animates that circuit from testimony, bound by cellId / edgeId.
 *
 * Limitation of the sink it reads: runs are scoped by run-start/run-end order only (the launcher
 * sends no run identity), so two runs at the same time interleave.
 */

import { renderCircuitViewer } from './circuit-viewer.js';
import { aggregateEdge, aggregateNode, cellState, edgeState } from './live-trace.js';
import { buildRunGraphView, normalizeRunGraph, runGraphViewProjection } from './run-graph.js';

const CIRCUIT_RECORD = 'execution-graph-captured.v1';
const RUN_HISTORY = 20;

const params = new URLSearchParams(location.search);
const state = {
  filter: params.get('capability') ?? '',
  runs: [],
  current: null,
  shown: null,
  selectedNodeId: undefined,
  lastSeq: 0,
  connection: 'connecting',
};

const filterInput = document.getElementById('capability');
const seenList = document.getElementById('seen-capabilities');
const statusLine = document.getElementById('status');
const runLine = document.getElementById('run');
const viewerRoot = document.getElementById('viewer');
const unmatchedBox = document.getElementById('unmatched');
filterInput.value = state.filter;

function capabilityOf(graphId) {
  return typeof graphId === 'string' ? graphId.replace(/^graph:/, '') : null;
}

function matchesFilter(run) {
  return Boolean(run.capabilityId) && (state.filter === '' || run.capabilityId === state.filter);
}

function selectShownRun() {
  const candidates = state.runs.filter((run) => run.view && matchesFilter(run));
  state.shown = candidates[candidates.length - 1] ?? null;
}

function newRun(record) {
  const run = {
    startSeq: record.seq,
    startedAt: record.receivedAt,
    nativeProcessId: record.payload?.nativeProcessId ?? null,
    capabilityId: null,
    view: null,
    projection: null,
    cells: {},
    edges: {},
    latestNodeId: null,
    unmatched: [],
    cellTestimony: 0,
    edgeTestimony: 0,
    failures: [],
    ended: false,
    exitCode: null,
  };
  state.runs.push(run);
  if (state.runs.length > RUN_HISTORY) state.runs.splice(0, state.runs.length - RUN_HISTORY);
  state.current = run;
  return run;
}

function noteUnmatched(run, id) {
  if (!run.unmatched.includes(id)) run.unmatched.push(id);
}

function applyCircuit(run, payload) {
  if (run.view) return;
  const capabilityId = capabilityOf(payload.graphId);
  run.capabilityId = capabilityId;
  run.view = buildRunGraphView(normalizeRunGraph(payload));
  run.projection = runGraphViewProjection(run.view, { capabilityId });
  addSeenCapability(capabilityId);
}

function applyCell(run, payload) {
  run.cellTestimony += 1;
  const next = cellState(payload);
  if (!next) return;
  run.cells[payload.cellId] = run.cells[payload.cellId] === 'failed' ? 'failed' : next;
  const nodeId = run.view.membership[payload.cellId];
  if (nodeId) run.latestNodeId = nodeId;
  else noteUnmatched(run, payload.cellId);
}

function applyEdge(run, payload) {
  run.edgeTestimony += 1;
  const next = edgeState(payload);
  if (next) run.edges[payload.edgeId] = run.edges[payload.edgeId] === 'failed' ? 'failed' : next;
  const bound = run.view.edgeMembership[payload.edgeId] || run.view.internalEdgeNode[payload.edgeId];
  if (!bound) noteUnmatched(run, payload.edgeId);
}

function applyFailure(run, payload) {
  run.failures.push({ code: payload.failureCode ?? 'FAILURE', message: payload.failureMessage ?? '' });
  if (payload.cellId && run.view) applyCell(run, { ...payload, testimonyType: payload.observationType });
  else if (payload.edgeId && run.view) applyEdge(run, { ...payload, testimonyType: payload.observationType });
}

function handle(record) {
  state.lastSeq = Math.max(state.lastSeq, record.seq ?? 0);
  if (record.kind === 'run-start') {
    newRun(record);
    return;
  }
  if (record.kind === 'run-end') {
    if (state.current) {
      state.current.ended = true;
      state.current.exitCode = record.payload?.exitCode ?? null;
    }
    return;
  }
  const payload = record.payload ?? {};
  const run = state.current;
  if (!run) return;
  if (payload.observationType === CIRCUIT_RECORD) {
    applyCircuit(run, payload);
    return;
  }
  if (!run.view) return;
  if (payload.testimonyType === 'cell-execution-testimony.v1' && payload.cellId) applyCell(run, payload);
  else if (payload.testimonyType === 'edge-execution-testimony.v1' && payload.edgeId) applyEdge(run, payload);
  else if (typeof payload.observationType === 'string' && payload.observationType.includes('failure')) applyFailure(run, payload);
}

function addSeenCapability(capabilityId) {
  if (!capabilityId || [...seenList.options].some((option) => option.value === capabilityId)) return;
  seenList.append(new Option(capabilityId, capabilityId));
}

let frame = 0;
function scheduleRender() {
  if (frame) return;
  frame = requestAnimationFrame(() => {
    frame = 0;
    render();
  });
}

function render() {
  selectShownRun();
  statusLine.textContent = `observer ${state.connection} · ${state.runs.length} run(s) seen · filter: ${state.filter || 'any capability'}`;
  const run = state.shown;
  if (!run) {
    runLine.textContent = state.filter
      ? `Waiting for a run of ${state.filter}. Start one with: sfx capability observe ${state.filter} --input <json> --json --trace`
      : 'Waiting for a run. Start one with: sfx capability observe <capability> --input <json> --json --trace';
    viewerRoot.replaceChildren();
    unmatchedBox.replaceChildren();
    return;
  }
  const liveNodes = {};
  for (const node of run.view.nodes) {
    let live = aggregateNode(run.view, node.id, run.cells);
    if (!run.ended && node.id === run.latestNodeId && live !== 'failed') live = 'active';
    liveNodes[node.id] = live;
  }
  const liveEdges = {};
  for (const edge of run.view.edges) liveEdges[edge.id] = aggregateEdge(run.view, edge.id, run.edges);
  const lit = Object.values(liveNodes).filter((live) => live !== 'planned').length;
  runLine.textContent = [
    `${run.capabilityId}`,
    run.ended ? `ended · exit ${run.exitCode ?? '?'}` : 'running',
    `started ${new Date(run.startedAt).toLocaleTimeString()}`,
    `${run.view.totalCells} cells → ${run.view.nodes.length} drawn`,
    `${lit}/${run.view.nodes.length} lit`,
    `testimony ${run.cellTestimony} cell · ${run.edgeTestimony} edge`,
    run.failures.length ? `failures: ${run.failures.map((failure) => failure.code).join(', ')}` : null,
  ].filter(Boolean).join(' · ');
  renderCircuitViewer(viewerRoot, run.projection, {
    liveNodes,
    liveEdges,
    selectedNodeId: state.selectedNodeId,
    onSelectNode: (id) => {
      state.selectedNodeId = id;
      scheduleRender();
    },
  });
  unmatchedBox.replaceChildren();
  if (run.unmatched.length > 0) {
    const heading = document.createElement('h3');
    heading.textContent = `Unmatched testimony (${run.unmatched.length}) — no element in this circuit`;
    const list = document.createElement('ul');
    for (const id of run.unmatched) {
      const item = document.createElement('li');
      item.textContent = id;
      list.append(item);
    }
    unmatchedBox.append(heading, list);
  }
}

let source = null;
function connect() {
  source?.close();
  // Replay what the observer still holds, then stay live. On reconnect, resume after the last
  // record already applied so nothing is applied twice.
  source = new EventSource(`/events?since=${state.lastSeq}`);
  source.onopen = () => {
    state.connection = 'connected';
    scheduleRender();
  };
  source.onmessage = (message) => {
    let record;
    try {
      record = JSON.parse(message.data);
    } catch {
      console.error('[circuit] observer sent a frame that is not JSON', message.data.slice(0, 200));
      return;
    }
    handle(record);
    scheduleRender();
  };
  source.onerror = () => {
    state.connection = 'reconnecting';
    scheduleRender();
    source.close();
    setTimeout(connect, 1500);
  };
}

filterInput.addEventListener('change', () => {
  state.filter = filterInput.value.trim();
  state.selectedNodeId = undefined;
  const url = new URL(location.href);
  if (state.filter) url.searchParams.set('capability', state.filter);
  else url.searchParams.delete('capability');
  history.replaceState(null, '', url);
  scheduleRender();
});

connect();
render();
