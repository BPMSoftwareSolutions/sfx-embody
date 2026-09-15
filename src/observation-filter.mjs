// The observation channel carries telemetry only. These are the fields a delivery
// may publish; inputs, provider bodies and secrets are never among them.
export const OBSERVATION_FIELDS = ['observationType', 'phase', 'status', 'observedAt',
  'executionId', 'rootExecutionId', 'parentExecutionId', 'scenarioId', 'stepId', 'sequence',
  'cellId', 'cellAltitude', 'edgeId', 'durationMilliseconds', 'startedAt', 'completedAt',
  // The declared semantic address of the executed cell. The observer joins it to
  // authority to tell the scenario story; no input, body or secret is among them.
  'semanticRole', 'responsibilityId', 'responsibilityKind', 'responsibilityOrdinal',
  'mechanicId', 'childScenarioId', 'parentScenarioId', 'inputId', 'eventId', 'outcomeId', 'outcomeContractId'];

export function safeObservation(observation) {
  return Object.fromEntries(OBSERVATION_FIELDS
    .filter(key => ['string', 'number'].includes(typeof observation?.[key]) || observation?.[key] === null)
    .map(key => [key, observation[key]]));
}
