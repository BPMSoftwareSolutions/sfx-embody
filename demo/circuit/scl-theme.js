/**
 * Copied from sfx-platform/components/circuit/scl-theme.ts (sfx-platform d62697e), types removed.
 *
 * Explicit mapping from SCL semantic types to palette tokens. Every node also carries a word and
 * a shape so status never depends on color.
 */

export const PRIMITIVE_STYLES = {
  INPUT: {
    label: 'Input',
    shape: 'terminal-in',
    stroke: 'var(--color-authority)',
    fill: 'color-mix(in srgb, var(--color-authority) 12%, var(--color-ink-2))',
    text: 'var(--color-text)',
  },
  EVENT: {
    label: 'Event',
    shape: 'event',
    stroke: 'var(--color-signal)',
    fill: 'color-mix(in srgb, var(--color-signal) 10%, var(--color-ink-2))',
    text: 'var(--color-text)',
  },
  RESPONSIBILITY: {
    label: 'Responsibility',
    shape: 'process',
    stroke: 'var(--color-text)',
    fill: 'var(--color-ink-2)',
    text: 'var(--color-text)',
  },
  OUTCOME: {
    label: 'Outcome',
    shape: 'terminal-out',
    stroke: '#72e1ad',
    fill: 'color-mix(in srgb, #72e1ad 12%, var(--color-ink-2))',
    text: 'var(--color-text)',
  },
  PROVIDER_SLOT: {
    label: 'Provider slot',
    shape: 'slot',
    stroke: '#82a8f9',
    fill: 'color-mix(in srgb, var(--color-telemetry) 10%, var(--color-ink-2))',
    text: 'var(--color-text)',
  },
  UNRESOLVED: {
    label: 'Unresolved',
    shape: 'unresolved',
    stroke: 'var(--color-failure)',
    fill: 'var(--color-ink-2)',
    text: 'var(--color-muted)',
  },
  SCENARIO: {
    label: 'Scenario',
    shape: 'terminal-in',
    stroke: 'var(--color-signal)',
    fill: 'color-mix(in srgb, var(--color-signal) 12%, var(--color-ink-2))',
    text: 'var(--color-text)',
  },
  MECHANIC: {
    label: 'Mechanic',
    shape: 'process',
    stroke: 'var(--color-authority)',
    fill: 'color-mix(in srgb, var(--color-authority) 8%, var(--color-ink-2))',
    text: 'var(--color-text)',
  },
  PROVIDER: {
    label: 'Provider',
    shape: 'slot',
    stroke: 'var(--color-telemetry)',
    fill: 'color-mix(in srgb, var(--color-telemetry) 10%, var(--color-ink-2))',
    text: 'var(--color-text)',
  },
  PHYSICAL: {
    label: 'Physical',
    shape: 'process',
    stroke: 'var(--color-projection)',
    fill: 'color-mix(in srgb, var(--color-projection) 10%, var(--color-ink-2))',
    text: 'var(--color-text)',
  },
};

/** Route families keep their type; a support link is not execution flow. */
export const EDGE_STYLES = {
  EXECUTION: { label: 'Execution', stroke: 'var(--color-signal)' },
  PRODUCT_TRANSFER: { label: 'Product transfer', stroke: 'var(--color-authority)', dash: '1 0' },
  SUPPORT: { label: 'Support', stroke: 'var(--color-muted)', dash: '4 4' },
};

export const FIDELITY_COPY = {
  RUN_GRAPH: {
    label: 'Run graph',
    explanation:
      'The composed execution graph of this run, as the kernel compiled it and sent it on the observation stream. Every planned cell is drawn unlit; a cell lights only when its own testimony arrives.',
  },
};
