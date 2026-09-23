/**
 * Copied from sfx-platform/components/circuit/circuit-viewer.tsx (sfx-platform d62697e) and ported
 * from React to plain DOM so the demo needs no build step. Same markup, same live classes
 * (`circuit-node--planned|active|done|failed`, `circuit-edge--…`), same outline, inspector and
 * legend. Omitted: "Play flow" — an illustrative animation of declared routes, not observed
 * execution; on a live monitor it would read as execution.
 */

import { layoutCircuit } from './geometry.js';
import { EDGE_STYLES, FIDELITY_COPY, PRIMITIVE_STYLES } from './scl-theme.js';

const SVG = 'http://www.w3.org/2000/svg';

function el(tag, attributes = {}, children = []) {
  const node = document.createElement(tag);
  for (const [name, value] of Object.entries(attributes)) {
    if (value === undefined || value === null || value === false) continue;
    if (name === 'text') node.textContent = value;
    else if (name.startsWith('on')) node.addEventListener(name.slice(2), value);
    else node.setAttribute(name, value === true ? '' : String(value));
  }
  for (const child of children) if (child) node.append(child);
  return node;
}

function svg(tag, attributes = {}, children = []) {
  const node = document.createElementNS(SVG, tag);
  for (const [name, value] of Object.entries(attributes)) {
    if (value === undefined || value === null || value === false) continue;
    if (name === 'text') node.textContent = value;
    else if (name.startsWith('on')) node.addEventListener(name.slice(2), value);
    else node.setAttribute(name, String(value));
  }
  for (const child of children) if (child) node.append(child);
  return node;
}

/**
 * @param {HTMLElement} root
 * @param {object} circuit the viewer projection: { capabilityId, scenarioId, nodes, edges, ... }
 * @param {{ liveNodes?: Record<string,string>, liveEdges?: Record<string,string>,
 *           selectedNodeId?: string, onSelectNode?: (id: string|undefined) => void }} options
 */
export function renderCircuitViewer(root, circuit, options = {}) {
  const { liveNodes = {}, liveEdges = {}, selectedNodeId, onSelectNode } = options;
  const layout = layoutCircuit(circuit);
  const fidelity = FIDELITY_COPY[circuit.fidelity] ?? { label: circuit.fidelity, explanation: '' };
  const selected = selectedNodeId;
  const select = (id) => onSelectNode?.(id);
  const selectedNode = circuit.nodes.find((node) => node.id === selected);

  const graphic = svg('svg', {
    viewBox: `0 0 ${layout.width} ${layout.height}`,
    width: '100%',
    role: 'img',
    'aria-label': `Circuit: ${circuit.capabilityId}. ${circuit.nodes.length} nodes, ${circuit.edges.length} routes.`,
    class: 'circuit-svg',
  });

  for (const edge of layout.edges) {
    const source = circuit.edges.find((candidate) => candidate.id === edge.id);
    const style = EDGE_STYLES[source?.family ?? 'SUPPORT'];
    const live = liveEdges[edge.id];
    graphic.append(svg('path', {
      d: edge.path,
      class: live ? `circuit-edge circuit-edge--${live}` : 'circuit-edge',
      'data-live': live,
      fill: 'none',
      stroke: style.stroke,
      'stroke-width': 1.5,
      'stroke-dasharray': style.dash === '1 0' ? undefined : style.dash,
      opacity: 0.8,
    }));
  }

  for (const node of circuit.nodes) {
    const box = layout.nodeById[node.id];
    if (!box) continue;
    const style = PRIMITIVE_STYLES[node.primitive] ?? PRIMITIVE_STYLES.UNRESOLVED;
    const isSelected = node.id === selected;
    const live = liveNodes[node.id];
    const group = svg('g', {
      class: live ? `circuit-node circuit-node--${live}` : 'circuit-node',
      'data-live': live,
      role: 'button',
      tabindex: 0,
      'aria-pressed': String(isSelected),
      'aria-label': `${style.label}: ${node.label}${live ? ` (${live})` : ''}`,
      style: 'cursor: pointer',
      onclick: () => select(isSelected ? undefined : node.id),
      onkeydown: (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          select(isSelected ? undefined : node.id);
        }
      },
    }, [
      svg('rect', {
        x: box.x, y: box.y, width: box.width, height: box.height,
        rx: node.primitive === 'RESPONSIBILITY' ? 4 : 14,
        fill: style.fill,
        stroke: isSelected ? 'var(--color-signal)' : style.stroke,
        'stroke-width': isSelected ? 2.5 : 1.5,
        'stroke-dasharray': node.primitive === 'UNRESOLVED' ? '5 4' : undefined,
      }),
      svg('text', {
        x: box.x + 14, y: box.y + 20, fill: style.stroke, 'font-size': 10,
        'font-family': 'var(--font-mono)', 'letter-spacing': '0.08em', text: style.label.toUpperCase(),
      }),
      ...box.lines.map((line, index) => svg('text', {
        x: box.x + 14, y: box.y + 40 + index * 19, fill: style.text, 'font-size': 14,
        'font-family': 'var(--font-sans)', text: line,
      })),
    ]);
    graphic.append(group);
  }

  const main = el('div', { class: 'viewer-main' }, [
    el('div', { class: 'viewer-bar' }, [
      el('span', { class: 'badge', text: fidelity.label }),
      el('span', { class: 'muted mono small', text: `${circuit.sclVersion} · ${circuit.sourceProfile}` }),
      selected ? el('button', { type: 'button', class: 'button', text: 'Clear selection', onclick: () => select(undefined) }) : null,
    ]),
    el('div', { class: 'viewer-canvas', role: 'group', 'aria-label': `Capability circuit ${circuit.capabilityId}` }, [graphic]),
    el('p', { class: 'muted small', text: fidelity.explanation }),
  ]);

  const outline = el('ol', { class: 'outline' }, circuit.nodes.map((node) => {
    const style = PRIMITIVE_STYLES[node.primitive] ?? PRIMITIVE_STYLES.UNRESOLVED;
    const live = liveNodes[node.id];
    return el('li', {}, [
      el('button', {
        type: 'button',
        class: `outline-item${node.id === selected ? ' outline-item--selected' : ''}${live ? ` outline-item--${live}` : ''}`,
        'aria-pressed': String(node.id === selected),
        onclick: () => select(node.id === selected ? undefined : node.id),
      }, [
        el('span', { class: 'outline-kind', text: `${style.label}${live ? ` · ${live}` : ''}` }),
        el('span', { class: 'outline-label', text: node.label }),
      ]),
    ]);
  }));

  const inspector = selectedNode
    ? el('dl', { class: 'inspector' }, [
        el('dt', { text: 'Meaning' }), el('dd', { text: selectedNode.label }),
        el('dt', { text: 'Primitive' }), el('dd', { text: (PRIMITIVE_STYLES[selectedNode.primitive] ?? PRIMITIVE_STYLES.UNRESOLVED).label }),
        el('dt', { text: 'Source identity' }), el('dd', { class: 'mono small break', text: selectedNode.sourceId ?? 'Not declared' }),
        el('dt', { text: 'Observed state' }), el('dd', { text: liveNodes[selectedNode.id] ?? 'planned' }),
        el('dt', { text: 'Source state' }), el('dd', { text: selectedNode.state.readable }),
      ])
    : el('p', { class: 'muted small', text: 'Select a node in the circuit or the outline to read its meaning, source identity and observed state.' });

  const legend = el('ul', { class: 'legend' }, Object.entries(EDGE_STYLES).map(([, style]) => el('li', {}, [
    svg('svg', { width: 28, height: 8, 'aria-hidden': 'true' }, [
      svg('line', { x1: 0, y1: 4, x2: 28, y2: 4, stroke: style.stroke, 'stroke-width': 2, 'stroke-dasharray': style.dash === '1 0' ? undefined : style.dash }),
    ]),
    el('span', { text: style.label }),
  ])));

  const aside = el('aside', { class: 'viewer-aside' }, [
    el('nav', { class: 'card', 'aria-label': 'Circuit outline' }, [el('h3', { text: 'Circuit outline' }), outline]),
    el('div', { class: 'card' }, [el('h3', { text: 'Node inspector' }), inspector]),
    el('div', { class: 'card' }, [
      el('h3', { text: 'Legend' }),
      legend,
      el('p', { class: 'muted small', text: 'Pulsing: the node the latest testimony landed in. Lit: observed. Red: failed. Faded: planned, not observed.' }),
    ]),
    el('p', { class: 'mono tiny muted', text: `graph ${String(circuit.graphDigest).slice(7, 19)} · renderer ${circuit.rendererVersion}` }),
  ]);

  root.replaceChildren(el('div', { class: 'viewer' }, [main, aside]));
}
