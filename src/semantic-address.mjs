// The semantic join. Execution testimony records what happened; declared authority
// explains what it meant. This module names each executed cell in the capability's
// own declared language — scenario, responsibility, mechanic — so the observer can
// tell the scenario story without a second source of truth and without prose in the
// runtime.
const SCENARIO_CELL = /^cell:scenario:(.+)$/;
const OPERATION_CELL = /^cell:mechanic:(.+)\.operation\.(\d+)(?::(.*))?$/;
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);

// The declared index: scenario faces, ordered operations per scenario, and the
// parent of a composed child scenario.
export function createSemanticAuthority(graphSource) {
  const scenarios = new Map();
  for (const scenario of graphSource?.scenarios ?? []) {
    if (object(scenario) && typeof scenario.scenarioId === 'string') scenarios.set(scenario.scenarioId, scenario);
  }
  const operations = new Map();
  const parents = new Map();
  for (const authority of graphSource?.executionAuthorities ?? []) {
    const scenarioId = authority?.owningScenarioId;
    if (typeof scenarioId !== 'string' || !Array.isArray(authority.operations)) continue;
    operations.set(scenarioId, authority.operations.map((operation, index) => ({ ordinal: index + 1, ...operation })));
    for (const operation of authority.operations) {
      if (operation?.kind === 'invoke-scenario' && typeof operation.scenarioId === 'string') parents.set(operation.scenarioId, scenarioId);
    }
  }
  return { scenarios, operations, parents };
}

// The declared responsibility a cell executes, or undefined when the cell is not
// an operation of a declared scenario.
const declaredOperation = (authority, scenarioId, ordinal) =>
  authority.operations.get(scenarioId)?.find(operation => operation.ordinal === ordinal);

// A cell's semantic address. Scenario cells carry the declared faces; operation
// cells and their mechanic sub-cells carry the declared responsibility. Nothing is
// inferred beyond the declared structure, and an unknown cell addresses to null.
export function semanticAddress(authority, cellId, mechanicId) {
  if (!object(authority) || typeof cellId !== 'string') return null;
  const scenario = SCENARIO_CELL.exec(cellId);
  if (scenario) {
    const scenarioId = scenario[1];
    const faces = authority.scenarios.get(scenarioId) ?? {};
    return {
      scenarioId,
      parentScenarioId: authority.parents.get(scenarioId) ?? null,
      semanticRole: 'SCENARIO_OUTCOME',
      inputId: faces.input?.inputId ?? null,
      eventId: faces.event?.eventId ?? null,
      outcomeId: faces.outcome?.outcomeId ?? null,
      outcomeContractId: faces.outcome?.contract?.contractId ?? null
    };
  }
  const operation = OPERATION_CELL.exec(cellId);
  if (!operation) return null;
  const scenarioId = operation[1];
  const declared = declaredOperation(authority, scenarioId, Number(operation[2]));
  const responsibility = {
    scenarioId,
    parentScenarioId: authority.parents.get(scenarioId) ?? null,
    semanticRole: 'EXECUTION_RESPONSIBILITY',
    responsibilityId: declared?.portId ?? declared?.scenarioId ?? null,
    responsibilityKind: declared?.kind ?? null,
    responsibilityOrdinal: Number(operation[2]),
    inputId: null,
    eventId: null,
    outcomeId: null,
    outcomeContractId: null
  };
  if (operation[3] === undefined) return responsibility;
  return { ...responsibility, semanticRole: 'MECHANIC', mechanicId: mechanicId ?? null,
    responsibilityId: responsibility.responsibilityId };
}

// The observed story: the scenario's declared faces, its responsibilities in
// declared order with their observed timing and disposition, and any composed
// child scenarios that executed. Every value is declared authority or testimony;
// the presentation layer supplies the language.
export function buildObservedStory({ authority, scenarioId, responsibilities, observedPathDigest }) {
  const facesFor = id => {
    const faces = authority.scenarios.get(id) ?? {};
    return {
      scenarioId: id,
      parentScenarioId: authority.parents.get(id) ?? null,
      inputId: faces.input?.inputId ?? null,
      inputContractId: faces.input?.contract?.contractId ?? null,
      eventId: faces.event?.eventId ?? null,
      eventAuthorityId: faces.event?.executionAuthorityId ?? null,
      outcomeId: faces.outcome?.outcomeId ?? null,
      outcomeContractId: faces.outcome?.contract?.contractId ?? null
    };
  };
  const byScenario = new Map();
  for (const entry of responsibilities) {
    if (!byScenario.has(entry.scenarioId)) byScenario.set(entry.scenarioId, []);
    byScenario.get(entry.scenarioId).push(entry);
  }
  const ordered = [...byScenario.keys()].map(id => ({
    ...facesFor(id),
    responsibilities: byScenario.get(id).sort((left, right) =>
      (left.responsibilityOrdinal ?? 0) - (right.responsibilityOrdinal ?? 0))
  }));
  const root = ordered.find(entry => entry.scenarioId === scenarioId) ?? ordered[0] ?? facesFor(scenarioId);
  return {
    scenario: root,
    ...(ordered.length > 1 ? { composedScenarios: ordered.filter(entry => entry !== root) } : {}),
    ...(observedPathDigest === undefined ? {} : { observedPathDigest })
  };
}
