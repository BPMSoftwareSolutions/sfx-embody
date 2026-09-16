// The observation channel carries telemetry only. These are the fields a delivery
// may publish; inputs, provider bodies and secrets are never among them.
export const OBSERVATION_FIELDS = ['observationType', 'phase', 'status', 'observedAt',
  'executionId', 'rootExecutionId', 'parentExecutionId', 'scenarioId', 'stepId', 'sequence',
  'cellId', 'cellAltitude', 'edgeId', 'durationMilliseconds', 'startedAt', 'completedAt',
  // The declared semantic address of the executed cell. The observer joins it to
  // authority to tell the scenario story; no input, body or secret is among them.
  'semanticRole', 'responsibilityId', 'responsibilityKind', 'responsibilityOrdinal',
  'mechanicId', 'mechanicPath', 'childScenarioId', 'parentScenarioId', 'inputId', 'eventId',
  'outcomeId', 'outcomeContractId', 'sourceCellId', 'destinationCellId', 'admissionDisposition'];

// Structured telemetry the estate derives: the streamed display entry (the
// sfx-display-document.v1 Entry vocabulary) and the kernel's bounded provider
// evidence. Only these members may carry an object, and only their declared
// scalars survive; the bounded provider evidence adds a boolean, and no other
// nested member can ride in.
export const OBSERVATION_OBJECT_FIELDS = Object.freeze({
  providerEvidence: ['reachedStage', 'exchangeCount', 'transportDisposition', 'redactionVerified'],
  display: ['entry']
});
const ENTRY_FIELDS = ['status', 'text', 'note', 'admission', 'timing'];

const scalar = value => typeof value === 'string' || typeof value === 'number' || value === null;
const nestedScalar = value => scalar(value) || typeof value === 'boolean';
function pickObject(value, fields) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return null;
  const picked = Object.fromEntries(fields.filter(key => nestedScalar(value[key])).map(key => [key, value[key]]));
  return Object.keys(picked).length ? picked : null;
}

export function safeObservation(observation) {
  const safe = {};
  for (const key of OBSERVATION_FIELDS) if (scalar(observation?.[key])) safe[key] = observation[key];
  const entry = pickObject(observation?.display?.entry, ENTRY_FIELDS);
  if (entry) safe.display = { entry };
  const providerEvidence = pickObject(observation?.providerEvidence, OBSERVATION_OBJECT_FIELDS.providerEvidence);
  if (providerEvidence) safe.providerEvidence = providerEvidence;
  return safe;
}
