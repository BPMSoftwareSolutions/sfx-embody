// The observation channel carries telemetry only. These are the fields a delivery
// may publish; inputs, provider bodies and secrets are never among them.
export const OBSERVATION_FIELDS = ['observationType', 'phase', 'status', 'observedAt',
  'executionId', 'rootExecutionId', 'parentExecutionId', 'scenarioId', 'stepId', 'sequence',
  'cellId', 'cellAltitude', 'edgeId', 'durationMilliseconds', 'startedAt', 'completedAt'];

export function safeObservation(observation) {
  return Object.fromEntries(OBSERVATION_FIELDS
    .filter(key => ['string', 'number'].includes(typeof observation?.[key]) || observation?.[key] === null)
    .map(key => [key, observation[key]]));
}
