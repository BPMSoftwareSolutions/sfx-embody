// GENERATED CAPABILITY EXECUTION BODY. Do not hand-edit.
import crypto from "node:crypto";
import fs from "node:fs";
import { createGovernedEffectContext, valueAt } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/native-mechanic-primitives.mjs";
import { createSynchronousSchemaAdmission } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs";
import {
  bindingProjectorByAuthorityId,
  cellContracts,
  conformanceClosures,
  operationDescriptorByCellId,
  operationFunctions,
  rootScenarioId,
  scenarioByExitCellId,
  scenarioByScenarioId
} from "./capability-operations.generated.mjs";
import { executeSequence as patternResolver0 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";
import { executeSelection as patternResolver1 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";
import { executeBroadcast as patternResolver2 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";
import { executeJoin as patternResolver3 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";
import { executeRecurrence as patternResolver4 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";
import { executeReturn as patternResolver5 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";
import { executeFailure as patternResolver6 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";
import { executeCancellation as patternResolver7 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";
import { executeDecomposition as patternResolver8 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";
import { executeForEach as patternResolver9 } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/execution-pattern-resolvers.mjs";

const carrier = JSON.parse(fs.readFileSync(new URL("./capability-carrier.json", import.meta.url), "utf8"));
const patternCatalog = JSON.parse(fs.readFileSync(new URL("./execution-patterns.json", import.meta.url), "utf8"));
const contractsDocument = JSON.parse(fs.readFileSync(new URL("./capability-contracts.json", import.meta.url), "utf8"));
const bindingsDocument = JSON.parse(fs.readFileSync(new URL("./capability-bindings.json", import.meta.url), "utf8"));
const contractAdmission = createSynchronousSchemaAdmission({ contracts: contractsDocument.contracts ?? {} });
const bindingAuthorityById = new Map((Array.isArray(bindingsDocument) ? bindingsDocument : []).map((authority) => [authority.id, authority]));
const patternResolverByType = new Map([
  ["sequence", patternResolver0],
  ["selection", patternResolver1],
  ["broadcast", patternResolver2],
  ["join", patternResolver3],
  ["recurrence", patternResolver4],
  ["return", patternResolver5],
  ["failure", patternResolver6],
  ["cancellation", patternResolver7],
  ["decomposition", patternResolver8],
  ["for-each", patternResolver9],
]);

function loadWorkspaceFixtures() {
  try {
    return JSON.parse(fs.readFileSync(new URL("../fixtures/fixtures.json", import.meta.url), "utf8"));
  } catch {
    return { fixtureType: "consumer-capability-fixtures.v1", fixtures: [] };
  }
}

export const capabilityId = carrier.capabilityId;
export const fixtures = loadWorkspaceFixtures();
export const fixtureIds = (fixtures.fixtures ?? []).map((fixture) => fixture.fixtureId);

function semanticId(value) {
  const normalized = String(value)
    .toLowerCase()
    .replace(/[^a-z0-9._:-]+/g, ".")
    .replace(/^[._:-]+/, "")
    .replace(/[._:-]+$/, "");
  return (normalized.length > 0 ? normalized : "value").slice(0, 200);
}

const SCENARIO_CELL_PREFIX = "cell:scenario:";

function compareText(left, right) {
  return left < right ? -1 : left > right ? 1 : 0;
}

function canonicalJson(value) {
  if (Array.isArray(value)) return "[" + value.map(canonicalJson).join(",") + "]";
  if (value !== null && typeof value === "object") {
    return "{" + Object.keys(value).sort().map((key) => JSON.stringify(key) + ":" + canonicalJson(value[key])).join(",") + "}";
  }
  return JSON.stringify(value);
}

function valueDigest(value) {
  const encoded = canonicalJson(value) ?? "null";
  return "sha256:" + crypto.createHash("sha256").update(encoded).digest("hex");
}

const PROVIDER_EVIDENCE_TOKEN = /^[A-Za-z0-9][A-Za-z0-9._:-]*$/;

function boundedProviderEvidence(value) {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return undefined;
  const evidence = {};
  if (typeof value.reachedStage === "string" && PROVIDER_EVIDENCE_TOKEN.test(value.reachedStage)) evidence.reachedStage = value.reachedStage;
  if (Number.isInteger(value.exchangeCount) && value.exchangeCount >= 0) evidence.exchangeCount = value.exchangeCount;
  if (typeof value.transportDisposition === "string" && PROVIDER_EVIDENCE_TOKEN.test(value.transportDisposition)) evidence.transportDisposition = value.transportDisposition;
  if (typeof value.redactionVerified === "boolean") evidence.redactionVerified = value.redactionVerified;
  return Object.keys(evidence).length > 0 ? Object.freeze(evidence) : undefined;
}

function patternOutcome(value, variant, disposition = "completed", routes = []) {
  return Object.freeze({
    value,
    ...(variant === undefined ? {} : { variant }),
    disposition,
    routes: Object.freeze([...routes])
  });
}

function inferVariant(value, descriptor) {
  if (typeof value === "boolean") return value ? "TRUE" : "FALSE";
  const variants = descriptor && Array.isArray(descriptor.outcomeVariants) ? descriptor.outcomeVariants : [];
  if (typeof value === "string" && variants.includes(value)) return value;
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    for (const key of ["outcomeVariant", "variant", "route", "disposition", "status", "kind"]) {
      if (typeof value[key] === "string") return value[key];
    }
  }
  return variants.length === 1 ? variants[0] : "SUCCESS";
}

function resolveFixtureGraphValue(value, catalog, stack = []) {
  if (Array.isArray(value)) return value.map((item) => resolveFixtureGraphValue(item, catalog, stack));
  if (!value || typeof value !== "object") return value;
  if (Object.keys(value).length === 1 && typeof value.$fixtureRef === "string") {
    const reference = value.$fixtureRef;
    if (!Object.hasOwn(catalog, reference)) throw new Error("FIXTURE_GRAPH_OUTCOME_REFERENCE_MISSING: '" + reference + "'.");
    if (stack.includes(reference)) throw new Error("FIXTURE_GRAPH_OUTCOME_REFERENCE_CYCLE: '" + [...stack, reference].join(" -> ") + "'.");
    return resolveFixtureGraphValue(catalog[reference], catalog, [...stack, reference]);
  }
  return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, resolveFixtureGraphValue(item, catalog, stack)]));
}

function fixturePortOutput(portId, declared, input) {
  const selected = declared && declared.byCarrierType ? declared.byCarrierType[input && input.carrierType] ?? declared : declared;
  if (!selected || typeof selected !== "object" || Array.isArray(selected)) throw new Error("FIXTURE_PORT_OUTCOME_INVALID: '" + portId + "'.");
  if (selected.status === "FAILURE") throw new Error(selected.error && selected.error.code ? selected.error.code : "FIXTURE_PORT_FAILURE: '" + portId + "'.");
  if (Object.hasOwn(selected, "output")) return structuredClone(selected.output);
  if (!Object.hasOwn(selected, "status")) return structuredClone(selected);
  throw new Error("FIXTURE_PORT_OUTPUT_MISSING: '" + portId + "'.");
}

function fixtureOverride(cellId, input, runtime) {
  const scenarioMeta = scenarioByExitCellId[cellId];
  const scenarioId = scenarioMeta && typeof scenarioMeta.scenarioId === "string" ? scenarioMeta.scenarioId : undefined;
  const graphOutcomes = runtime.options.graphOutcomes;
  const scenarioDeclared = scenarioId !== undefined && graphOutcomes ? graphOutcomes[scenarioId] : undefined;
  const cellDeclared = scenarioDeclared === undefined && graphOutcomes ? graphOutcomes[cellId] : undefined;
  const declared = scenarioDeclared !== undefined ? scenarioDeclared : cellDeclared;
  if (declared !== undefined) {
    const occurrenceKey = scenarioDeclared !== undefined ? scenarioId : cellId;
    const occurrence = runtime.fixtureOccurrence.get(occurrenceKey) ?? 0;
    runtime.fixtureOccurrence.set(occurrenceKey, occurrence + 1);
    const selected = Array.isArray(declared) ? declared[Math.min(occurrence, declared.length - 1)] : declared;
    if (!selected || typeof selected !== "object" || Array.isArray(selected)) throw new Error("FIXTURE_GRAPH_OUTCOME_INVALID: '" + occurrenceKey + "'.");
    const catalog = runtime.options.graphOutcomeCatalog ?? {};
    const referencedValue = typeof selected.outcomeRef === "string" ? catalog[selected.outcomeRef] : undefined;
    if (typeof selected.outcomeRef === "string" && referencedValue === undefined) throw new Error("FIXTURE_GRAPH_OUTCOME_REFERENCE_MISSING: '" + selected.outcomeRef + "'.");
    const fallback = input !== null && typeof input === "object" && !Array.isArray(input)
      ? { ...structuredClone(input), ...(selected.outcomeVariant ? { outcomeVariant: selected.outcomeVariant } : {}) }
      : input;
    const fixtureValue = resolveFixtureGraphValue(selected.outcomeValue ?? referencedValue ?? fallback, catalog);
    return patternOutcome(fixtureValue, selected.outcomeVariant, selected.disposition ?? "completed");
  }
  const descriptor = operationDescriptorByCellId[cellId];
  const configuration = descriptor ? descriptor.configuration : undefined;
  const portId = configuration && configuration.kind === "invoke-port" && typeof configuration.portId === "string"
    ? configuration.portId
    : descriptor && typeof descriptor.semanticAddress === "string" ? descriptor.semanticAddress.split("#/")[0] : undefined;
  const declaredPort = portId !== undefined && runtime.options.portOutcomes ? runtime.options.portOutcomes[portId] : undefined;
  if (declaredPort !== undefined) return patternOutcome(fixturePortOutput(portId, declaredPort, input));
  return undefined;
}

function admitContract(cellId, value, direction) {
  const declared = cellContracts[cellId];
  const contractId = declared ? declared[direction] : undefined;
  if (typeof contractId !== "string" || contractId.length === 0) return true;
  const contracts = contractsDocument.contracts;
  if (!contracts || typeof contracts !== "object" || !Object.hasOwn(contracts, contractId)) return true;
  return contractAdmission.admits(contractId, value) === true;
}

function admitScenarioContract(scenario, value, direction) {
  const contractId = scenario && typeof scenario[direction] === "string" ? scenario[direction] : "";
  if (contractId.length === 0) return true;
  const contracts = contractsDocument.contracts;
  if (!contracts || typeof contracts !== "object" || !Object.hasOwn(contracts, contractId)) return true;
  return contractAdmission.admits(contractId, value) === true;
}

const GROUP_PATTERN_TYPES = new Set(["selection", "broadcast", "join", "recurrence", "failure", "cancellation", "decomposition", "for-each"]);
const STRUCTURAL_PATTERN_TYPES = new Set(["selection", "broadcast", "join", "failure", "cancellation"]);
const STEP_BOUND = 100000;

function patternAnchor(pattern) {
  if (pattern.patternType === "decomposition") {
    const prefix = "decomposition:";
    return typeof pattern.patternId === "string" && pattern.patternId.startsWith(prefix) ? pattern.patternId.slice(prefix.length) : undefined;
  }
  if (pattern.patternType === "for-each") return pattern.patternId;
  if (pattern.patternType === "join" && pattern.join && typeof pattern.join.joinCellId === "string") return pattern.join.joinCellId;
  const participants = pattern.participantCellIds;
  return Array.isArray(participants) && participants.length > 0 ? participants[0] : undefined;
}

const groupedPatternByAnchor = new Map();
for (const pattern of patternCatalog.patterns ?? []) {
  if (!GROUP_PATTERN_TYPES.has(pattern.patternType)) continue;
  const anchor = patternAnchor(pattern);
  if (typeof anchor === "string" && !groupedPatternByAnchor.has(anchor)) groupedPatternByAnchor.set(anchor, pattern);
}

function groupedPatternAt(cellId) {
  return groupedPatternByAnchor.get(semanticId(cellId));
}

const semanticOperationCellIdByRef = Object.freeze(Object.fromEntries(
  Object.keys(operationDescriptorByCellId).map((cellId) => [semanticId(cellId), cellId])
));

function descentCellId(declaredCellId) {
  if (operationDescriptorByCellId[declaredCellId] !== undefined) return declaredCellId;
  return semanticOperationCellIdByRef[declaredCellId] ?? declaredCellId;
}

const carrierCellIds = new Set();
const carrierRouteKeys = new Set();
for (const projection of carrier.eventExecutionProjections ?? []) {
  for (const cell of projection.cells ?? []) carrierCellIds.add(cell.cellId);
  for (const route of projection.routes ?? []) carrierRouteKeys.add("route:" + route.fromCellId + "->" + route.toCellId);
}
for (const circuit of [...(carrier.mechanicCircuits ?? []), ...(carrier.providerCircuits ?? [])]) {
  for (const cell of circuit.cells ?? []) carrierCellIds.add(cell.cellId);
}
for (const scenario of carrier.scenarioCells ?? []) {
  const scenarioCellId = typeof scenario.scenarioCellId === "string" ? scenario.scenarioCellId : SCENARIO_CELL_PREFIX + scenario.scenarioId;
  for (const route of scenario.routes ?? []) {
    const fromCellId = typeof route.fromCellId === "string" ? route.fromCellId : scenarioCellId;
    const toCellId = typeof route.toCellId === "string"
      ? route.toCellId
      : typeof route.targetScenarioId === "string" ? SCENARIO_CELL_PREFIX + route.targetScenarioId : undefined;
    if (toCellId !== undefined) carrierRouteKeys.add("route:" + fromCellId + "->" + toCellId);
  }
}

function routeKind(route) {
  if (typeof route.edgeKind === "string" && route.edgeKind.length > 0) return route.edgeKind;
  if (typeof route.kind === "string" && route.kind.length > 0) return route.kind;
  return "sequence";
}

function routeIndex(routes) {
  const index = new Map();
  for (const route of routes ?? []) {
    if (!route || typeof route.fromCellId !== "string" || typeof route.toCellId !== "string") continue;
    const list = index.get(route.fromCellId) ?? [];
    list.push(route);
    index.set(route.fromCellId, list);
  }
  for (const list of index.values()) list.sort((left, right) => String(left.toCellId).localeCompare(String(right.toCellId)));
  return index;
}

function candidateRoutes(routes, outcome) {
  if (outcome.disposition === "failed" || outcome.disposition === "rejected") {
    return routes.filter((route) => routeKind(route) === "failure" ||
      (routeKind(route) === "selection" && route.selectsVariant === outcome.variant));
  }
  if (outcome.disposition === "cancelled") return routes.filter((route) => routeKind(route) === "cancellation");
  return routes.filter((route) => routeKind(route) !== "failure" && routeKind(route) !== "cancellation");
}

function selectionDefault(cellId, candidates) {
  const pattern = groupedPatternAt(cellId);
  const defaultDecisionId = pattern && pattern.patternType === "selection" && pattern.selection
    ? pattern.selection.defaultDecisionId : undefined;
  if (typeof defaultDecisionId !== "string") return undefined;
  return candidates.find((route) => route.toCellId === defaultDecisionId);
}

function recordPatternTestimony(runtime, pattern, groupId) {
  runtime.testimony.patterns.push(Object.freeze({
    testimonyType: "pattern-execution-testimony.v1",
    patternType: pattern.patternType,
    patternId: pattern.patternId,
    ...(groupId !== undefined ? { groupId } : {}),
    logicalOrder: runtime.testimony.order++
  }));
}

function recordCellTestimony(cellId, outcome, runtime) {
  const descriptor = operationDescriptorByCellId[cellId];
  const occurrence = runtime.occurrences.get(cellId) ?? 0;
  runtime.occurrences.set(cellId, occurrence + 1);
  const altitude = descriptor && typeof descriptor.altitude === "string" ? descriptor.altitude : "mechanic";
  const evidence = altitude === "provider" || altitude === "physical" ? boundedProviderEvidence(outcome.value) : undefined;
  runtime.testimony.cells.push(Object.freeze({
    testimonyType: "cell-execution-testimony.v1",
    cellId,
    cellAltitude: altitude,
    cellExecutionId: runtime.rootExecutionId + ":" + cellId + ":" + occurrence,
    providerProfileId: descriptor && typeof descriptor.providerProfileId === "string" ? descriptor.providerProfileId : null,
    ...(evidence !== undefined ? { providerEvidence: evidence } : {}),
    outcomeVariant: outcome.variant ?? null,
    disposition: outcome.disposition,
    outcomeDigest: valueDigest(outcome.value),
    logicalOrder: runtime.testimony.order++
  }));
}

function recordEdgeTestimony(runtime, route, admissionDisposition = "admitted") {
  runtime.testimony.edges.push(Object.freeze({
    testimonyType: "edge-execution-testimony.v1",
    edgeId: "route:" + route.fromCellId + "->" + route.toCellId,
    sourceCellId: route.fromCellId,
    destinationCellId: route.toCellId,
    ...(typeof route.edgeKind === "string" ? { edgeKind: route.edgeKind } : {}),
    ...(typeof route.groupId === "string" ? { groupId: route.groupId } : {}),
    ...(typeof route.joinSlotId === "string" ? { joinSlotId: route.joinSlotId } : {}),
    ...(typeof route.selectsVariant === "string" ? { selectsVariant: route.selectsVariant } : {}),
    ...(typeof route.bindingAuthorityId === "string" ? { bindingAuthorityId: route.bindingAuthorityId } : {}),
    admissionDisposition,
    logicalOrder: runtime.testimony.order++
  }));
}

async function runCellOperation(cellId, input, runtime) {
  const descriptor = operationDescriptorByCellId[cellId];
  if (descriptor === undefined) throw new Error("CAPABILITY_PROJECTION_MECHANIC_UNRESOLVED: '" + cellId + "'.");
  const operate = operationFunctions[descriptor.operationId];
  if (typeof operate !== "function") throw new Error("CAPABILITY_PROJECTION_OPERATION_MISSING: '" + descriptor.operationId + "'.");
  const occurrence = runtime.occurrences.get(cellId) ?? 0;
  const cellExecutionId = runtime.rootExecutionId + ":" + cellId + ":" + occurrence;
  const context = {
    cellId,
    cellExecutionId,
    rootExecutionId: runtime.rootExecutionId,
    rootInput: runtime.rootInput,
    authorityId: descriptor.mechanicId,
    providerProfileId: descriptor.providerProfileId,
    configuration: descriptor.configuration,
    bindingUrl: import.meta.url,
    effectContext: runtime.effectContext,
    readQuery: runtime.options.readQuery,
    databaseRoot: runtime.options.databaseRoot
  };
  let outcome;
  let value;
  try {
    value = await operate(input, context);
  } catch (error) {
    if (descriptor.expression !== undefined) {
      outcome = patternOutcome(input, "VALUE");
    } else {
      outcome = patternOutcome({ code: "CELL_EXECUTION_FAILED", message: error instanceof Error ? error.message : String(error) }, "FAILURE", "failed");
    }
  }
  if (outcome === undefined) {
    if (value === undefined) {
      const expression = descriptor.expression;
      const pathScope = expression && typeof expression === "object" && expression.op === "path" ? (typeof expression.from === "string" ? expression.from : "input") : null;
      if (pathScope === "input" || pathScope === "root") outcome = patternOutcome(false, "FALSE");
      else throw new Error("LEXICAL_BINDING_NOT_AVAILABLE_AT_CELL_ALTITUDE");
    } else {
      outcome = patternOutcome(value, inferVariant(value, descriptor));
    }
  }
  return outcome;
}

async function runAdmittedCell(cellId, input, runtime) {
  let outcome;
  if (!admitContract(cellId, input, "inputContractId")) {
    outcome = patternOutcome(input, "INPUT_REJECTED", "rejected");
  } else {
    outcome = await runCellOperation(cellId, input, runtime);
    if (outcome.disposition === "completed" && !admitContract(cellId, outcome.value, "outcomeContractId")) {
      outcome = patternOutcome(outcome.value, "OUTCOME_REJECTED", "rejected");
    }
  }
  recordCellTestimony(cellId, outcome, runtime);
  return outcome;
}

function patternContext(runtime) {
  const context = {
    async step(targetCellId, targetInput) {
      return runAdmittedCell(targetCellId, targetInput, runtime);
    },
    async stepMany(targetCellIds, targetInput) {
      const outcomes = [];
      for (const targetCellId of targetCellIds) outcomes.push(await context.step(targetCellId, targetInput));
      return outcomes;
    },
    cancelled: () => runtime.options.signal?.aborted === true
  };
  return context;
}

async function runCellDescent(pattern, input, runtime) {
  const entryCellIds = pattern.decomposition && Array.isArray(pattern.decomposition.entryCellIds) ? pattern.decomposition.entryCellIds : [];
  const exitCellIds = pattern.decomposition && Array.isArray(pattern.decomposition.exitCellIds) ? pattern.decomposition.exitCellIds : [];
  let outcome = patternOutcome(input);
  for (const entryCellId of entryCellIds) {
    outcome = await runAdmittedCell(descentCellId(entryCellId), outcome.value, runtime);
    if (outcome.disposition !== "completed") return outcome;
  }
  for (const exitCellId of exitCellIds) {
    outcome = await runAdmittedCell(descentCellId(exitCellId), outcome.value, runtime);
    if (outcome.disposition !== "completed") return outcome;
  }
  return outcome;
}

async function stepCell(cellId, input, runtime, options = {}) {
  if (!admitContract(cellId, input, "inputContractId")) {
    const rejected = patternOutcome(input, "INPUT_REJECTED", "rejected");
    recordCellTestimony(cellId, rejected, runtime);
    return rejected;
  }
  let fixture;
  try {
    fixture = fixtureOverride(cellId, input, runtime);
  } catch (error) {
    const failed = patternOutcome({ code: "CELL_EXECUTION_FAILED", message: error instanceof Error ? error.message : String(error) }, "FAILURE", "failed");
    recordCellTestimony(cellId, failed, runtime);
    return failed;
  }
  if (fixture !== undefined) {
    const admitted = fixture.disposition === "completed" && !admitContract(cellId, fixture.value, "outcomeContractId")
      ? patternOutcome(fixture.value, "OUTCOME_REJECTED", "rejected")
      : fixture;
    recordCellTestimony(cellId, admitted, runtime);
    return admitted;
  }
  const pattern = groupedPatternAt(cellId);
  const structural = options.structural === true;
  if (pattern !== undefined && pattern.patternType === "decomposition" &&
      pattern.decomposition && pattern.decomposition.descent === true) {
    let outcome = await runCellDescent(pattern, input, runtime);
    if (outcome.disposition === "completed" && !admitContract(cellId, outcome.value, "outcomeContractId")) {
      outcome = patternOutcome(outcome.value, "OUTCOME_REJECTED", "rejected");
    }
    recordCellTestimony(cellId, outcome, runtime);
    return outcome;
  }
  if (pattern !== undefined && !(structural && STRUCTURAL_PATTERN_TYPES.has(pattern.patternType))) {
    const resolver = patternResolverByType.get(pattern.patternType);
    if (resolver === undefined) throw new Error("EXECUTION_PATTERN_RESOLVER_MISSING: '" + pattern.patternType + "'.");
    const execute = typeof resolver.execute === "function" ? resolver.execute.bind(resolver) : resolver;
    let outcome = await execute(pattern, input, patternContext(runtime));
    recordPatternTestimony(runtime, pattern);
    if (outcome.disposition === "completed" && !admitContract(cellId, outcome.value, "outcomeContractId")) {
      outcome = patternOutcome(outcome.value, "OUTCOME_REJECTED", "rejected");
    }
    recordCellTestimony(cellId, outcome, runtime);
    return outcome;
  }
  return runAdmittedCell(cellId, input, runtime);
}

async function projectBindingValue(bindingAuthorityId, value, runtime) {
  const authority = bindingAuthorityById.get(bindingAuthorityId);
  if (authority === undefined) throw new Error("EDGE_BINDING_AUTHORITY_MISSING: '" + bindingAuthorityId + "'.");
  if (!authority.binding || typeof authority.binding !== "object") throw new Error("EDGE_BINDING_REALIZATION_MISSING: '" + bindingAuthorityId + "'.");
  const projector = bindingProjectorByAuthorityId[bindingAuthorityId];
  if (typeof projector !== "function") throw new Error("EDGE_BINDING_PROJECTOR_MISSING: '" + bindingAuthorityId + "'.");
  return projector(value, {
    bindingAuthorityId,
    rootInput: runtime.rootInput,
    rootExecutionId: runtime.rootExecutionId,
    effectContext: runtime.effectContext,
    bindingUrl: import.meta.url,
    readQuery: runtime.options.readQuery,
    databaseRoot: runtime.options.databaseRoot
  });
}

async function pushRoute(walk, route, value) {
  let projected = value;
  if (typeof route.bindingAuthorityId === "string") {
    projected = await projectBindingValue(route.bindingAuthorityId, projected, walk.runtime);
  }
  recordEdgeTestimony(walk.runtime, route);
  if (routeKind(route) === "join") {
    await bufferJoin(walk, route, projected);
    return;
  }
  if (walk.cellIds.has(route.toCellId)) walk.pending.push({ cellId: route.toCellId, input: projected });
}

async function bufferJoin(walk, route, value) {
  const joinCellId = route.toCellId;
  const groupId = typeof route.groupId === "string" ? route.groupId : "join:" + joinCellId;
  const key = groupId + "\u0000" + joinCellId;
  const pattern = groupedPatternAt(joinCellId);
  const declaredJoin = pattern && pattern.patternType === "join" && pattern.join ? pattern.join : undefined;
  const policy = declaredJoin ? declaredJoin.policy : "all-required";
  const requiredSlotIds = declaredJoin ? declaredJoin.requiredSlotIds : undefined;
  const buffer = walk.joinBuffers.get(key) ?? new Map();
  const slotId = typeof route.joinSlotId === "string" && route.joinSlotId.length > 0 ? route.joinSlotId : String(buffer.size);
  if (!buffer.has(slotId)) buffer.set(slotId, { slotId, cellId: route.fromCellId, value });
  walk.joinBuffers.set(key, buffer);
  const ready = policy === "first-admitted"
    ? !walk.completedFirstJoins.has(key)
    : Array.isArray(requiredSlotIds) && requiredSlotIds.length > 0
      ? requiredSlotIds.every((requiredSlotId) => buffer.has(requiredSlotId))
      : true;
  if (!ready) return;
  walk.joinBuffers.delete(key);
  if (policy === "first-admitted") walk.completedFirstJoins.add(key);
  await runJoin(walk, joinCellId, buffer, policy, requiredSlotIds);
}

async function runJoin(walk, joinCellId, buffer, policy, requiredSlotIds) {
  const entries = [...buffer.values()].sort((left, right) => left.slotId.localeCompare(right.slotId));
  const resolver = patternResolverByType.get("join");
  if (resolver === undefined) throw new Error("EXECUTION_PATTERN_RESOLVER_MISSING: 'join'.");
  const instance = {
    patternId: semanticId("join:" + joinCellId),
    patternType: "join",
    participantCellIds: [...entries.map((entry) => entry.cellId), joinCellId],
    inputContractId: "",
    outputContractId: "",
    decisions: [],
    invariants: [],
    dataRefs: [],
    join: {
      policy,
      requiredSlotIds: entries.map((entry) => entry.slotId),
      joinCellId
    }
  };
  const context = {
    async step(targetCellId, targetInput) {
      if (targetCellId === joinCellId) return stepCell(joinCellId, targetInput, walk.runtime, { structural: true });
      const entry = entries.find((candidate) => candidate.cellId === targetCellId);
      if (entry === undefined) throw new Error("JOIN_LEG_UNAVAILABLE: '" + targetCellId + "'.");
      return patternOutcome(entry.value, "SUFFICIENT", "completed");
    },
    async stepMany(targetCellIds, targetInput) {
      const outcomes = [];
      for (const targetCellId of targetCellIds) outcomes.push(await context.step(targetCellId, targetInput));
      return outcomes;
    },
    cancelled: () => walk.runtime.options.signal?.aborted === true
  };
  const execute = typeof resolver.execute === "function" ? resolver.execute.bind(resolver) : resolver;
  const resolved = await execute(instance, Object.fromEntries(entries.map((entry) => [entry.slotId, entry.value])), context);
  recordPatternTestimony(walk.runtime, instance, instance.join.joinCellId);
  walk.final = resolved;
  await routeOutcome(walk, joinCellId, resolved);
}

async function runBroadcast(walk, cellId, outcome, groupId, members) {
  const resolver = patternResolverByType.get("broadcast");
  if (resolver === undefined) {
    for (const route of members) await pushRoute(walk, route, outcome.value);
    return;
  }
  const instance = {
    patternId: semanticId(groupId ?? ("broadcast:" + cellId)),
    patternType: "broadcast",
    participantCellIds: members.map((route) => route.toCellId),
    inputContractId: "",
    outputContractId: "",
    decisions: [],
    invariants: [],
    dataRefs: [],
    ...(groupId ? { groupId } : {})
  };
  const memberByTarget = new Map(members.map((route) => [route.toCellId, route]));
  const context = {
    async step(targetCellId, targetInput) {
      const route = memberByTarget.get(targetCellId);
      if (route === undefined) return stepCell(targetCellId, targetInput, walk.runtime, { structural: true });
      let value = targetInput;
      if (typeof route.bindingAuthorityId === "string") {
        value = await projectBindingValue(route.bindingAuthorityId, value, walk.runtime);
      }
      recordEdgeTestimony(walk.runtime, route);
      const legOutcome = await stepCell(targetCellId, value, walk.runtime, { structural: true });
      walk.final = legOutcome;
      await routeOutcome(walk, targetCellId, legOutcome);
      return legOutcome;
    },
    async stepMany(targetCellIds, targetInput) {
      const outcomes = [];
      for (const targetCellId of targetCellIds) outcomes.push(await context.step(targetCellId, targetInput));
      return outcomes;
    },
    cancelled: () => walk.runtime.options.signal?.aborted === true
  };
  const execute = typeof resolver.execute === "function" ? resolver.execute.bind(resolver) : resolver;
  const resolved = await execute(instance, outcome.value, context);
  recordPatternTestimony(walk.runtime, instance, groupId);
  return resolved;
}

async function runDispositionResolver(walk, cellId, outcome, patternType) {
  const resolver = patternResolverByType.get(patternType);
  if (resolver === undefined) return outcome;
  const instance = {
    patternId: semanticId(patternType + ":" + cellId),
    patternType,
    participantCellIds: [cellId],
    inputContractId: "",
    outputContractId: "",
    decisions: [],
    invariants: [],
    dataRefs: []
  };
  const execute = typeof resolver.execute === "function" ? resolver.execute.bind(resolver) : resolver;
  const resolved = await execute(instance, outcome, patternContext(walk.runtime));
  recordPatternTestimony(walk.runtime, instance);
  walk.final = resolved;
  return resolved;
}

async function routeOutcome(walk, cellId, initialOutcome) {
  let outcome = initialOutcome;
  let candidates = candidateRoutes(walk.routesByFrom.get(cellId) ?? [], outcome);
  if ((outcome.disposition === "failed" || outcome.disposition === "rejected") &&
      candidates.some((route) => routeKind(route) === "failure")) {
    outcome = await runDispositionResolver(walk, cellId, outcome, "failure");
    candidates = candidateRoutes(walk.routesByFrom.get(cellId) ?? [], outcome);
  } else if (outcome.disposition === "cancelled" && candidates.some((route) => routeKind(route) === "cancellation")) {
    outcome = await runDispositionResolver(walk, cellId, outcome, "cancellation");
    candidates = candidateRoutes(walk.routesByFrom.get(cellId) ?? [], outcome);
  }
  const selectionCandidates = candidates.filter((route) => routeKind(route) === "selection" && typeof route.groupId === "string");
  if (selectionCandidates.length > 0) {
    const matched = selectionCandidates.filter((route) => route.selectsVariant === outcome.variant);
    const fallback = matched.length === 0 ? selectionDefault(cellId, selectionCandidates) : undefined;
    if (matched.length > 0) candidates = matched;
    else if (fallback !== undefined) candidates = [fallback];
    else candidates = candidates.filter((route) => routeKind(route) !== "selection");
  }
  const groups = new Map();
  const plain = [];
  for (const route of candidates) {
    if (typeof route.groupId === "string" && route.groupId.length > 0) {
      const members = groups.get(route.groupId) ?? [];
      members.push(route);
      groups.set(route.groupId, members);
    } else {
      plain.push(route);
    }
  }
  for (const route of plain) await pushRoute(walk, route, outcome.value);
  for (const [groupId, members] of groups) {
    const kind = routeKind(members[0]);
    if (kind === "broadcast") {
      await runBroadcast(walk, cellId, outcome, groupId, members);
      continue;
    }
    for (const route of members) await pushRoute(walk, route, outcome.value);
  }
}

async function runProjection(projection, input, runtime) {
  const routes = Array.isArray(projection.routes) ? projection.routes : [];
  const walk = {
    runtime,
    routesByFrom: routeIndex(routes),
    cellIds: new Set((projection.cells ?? []).map((cell) => cell.cellId)),
    joinBuffers: new Map(),
    completedFirstJoins: new Set(),
    pending: [{ cellId: projection.rootCellId, input }],
    final: patternOutcome(input)
  };
  let visited = 0;
  while (walk.pending.length > 0) {
    visited += 1;
    if (visited > STEP_BOUND) throw new Error("CAPABILITY_CARRIER_STEP_BOUND_EXCEEDED");
    const token = walk.pending.shift();
    const outcome = await stepCell(token.cellId, token.input, runtime, { structural: true });
    walk.final = outcome;
    await routeOutcome(walk, token.cellId, outcome);
  }
  return walk.final;
}

function scenarioRouteTarget(route) {
  if (route === null || typeof route !== "object" || Array.isArray(route)) return undefined;
  if (route.semanticProgress === "terminating") return undefined;
  if (typeof route.targetScenarioId === "string" && route.targetScenarioId.length > 0) return route.targetScenarioId;
  const toCellId = typeof route.toCellId === "string" ? route.toCellId : "";
  if (toCellId.startsWith(SCENARIO_CELL_PREFIX)) return semanticId(toCellId.slice(SCENARIO_CELL_PREFIX.length));
  return undefined;
}

function selectedScenarioRoutes(routes, outcome) {
  const candidates = candidateRoutes(routes ?? [], outcome);
  const selectionCandidates = candidates.filter((route) => routeKind(route) === "selection");
  if (selectionCandidates.length === 0) return candidates;
  const matched = selectionCandidates.filter((route) => route.selectsVariant === outcome.variant);
  if (matched.length > 0) return matched;
  return [];
}

function scenarioExecutionStart(scenarioCells, scenarioById) {
  const incoming = new Set();
  for (const scenario of scenarioCells) {
    for (const route of scenario.routes ?? []) {
      const target = scenarioRouteTarget(route);
      if (target !== undefined) incoming.add(target);
    }
  }
  if (typeof rootScenarioId === "string" && scenarioById.has(rootScenarioId)) return rootScenarioId;
  const ordered = [...scenarioCells].sort((left, right) =>
    ((Number(left.sequence) || 0) - (Number(right.sequence) || 0)) ||
    compareText(String(left.scenarioId), String(right.scenarioId)));
  const root = ordered.find((scenario) => !incoming.has(scenario.scenarioId));
  return (root ?? ordered[0]).scenarioId;
}

function verifyObservedCarrier(graphExecution) {
  const findings = [];
  const cellTestimony = Array.isArray(graphExecution.cellTestimony) ? graphExecution.cellTestimony : [];
  const edgeTestimony = Array.isArray(graphExecution.edgeTestimony) ? graphExecution.edgeTestimony : [];
  for (const cell of cellTestimony) {
    if (!carrierCellIds.has(cell.cellId)) findings.push({ code: "UNEXPECTED_CELL_EXECUTED", subjectId: String(cell.cellId), message: "Observed cell has no carrier address." });
    if (cell.providerProfileId === null || cell.providerProfileId === undefined) findings.push({ code: "PROVIDER_TESTIMONY_GAP", subjectId: String(cell.cellExecutionId ?? cell.cellId), message: "Observed cell omitted provider identity." });
  }
  for (const edge of edgeTestimony) {
    if (!carrierRouteKeys.has(edge.edgeId)) findings.push({ code: "UNEXPECTED_EDGE_TRAVERSED", subjectId: String(edge.edgeId), message: "Observed route has no carrier address." });
  }
  return findings;
}

function observedPathDigest(testimony) {
  return "sha256:" + crypto.createHash("sha256").update(JSON.stringify({
    cells: testimony.cells.map((cell) => ({ cellId: cell.cellId, cellExecutionId: cell.cellExecutionId })),
    edges: testimony.edges.map((edge) => edge.edgeId)
  })).digest("hex");
}

export async function executeCapability(input, options = {}) {
  const effectContext = options.effectContext ?? createGovernedEffectContext();
  const rootExecutionId = typeof options.rootExecutionId === "string" ? options.rootExecutionId : "execution:" + carrier.capabilityId;
  const runtime = {
    options,
    effectContext,
    rootInput: input,
    rootExecutionId,
    fixtureOccurrence: new Map(),
    occurrences: new Map(),
    testimony: { cells: [], edges: [], patterns: [], order: 0 }
  };
  const scenarioCells = Array.isArray(carrier.scenarioCells) ? carrier.scenarioCells : [];
  if (scenarioCells.length === 0) throw new Error("CAPABILITY_CARRIER_HAS_NO_SCENARIOS");
  const scenarioById = new Map(scenarioCells.map((scenario) => [scenario.scenarioId, scenario]));
  const projectionByScenarioId = new Map((carrier.eventExecutionProjections ?? [])
    .map((projection) => [projection.parentScenarioId, projection]));
  const executions = [];
  const scenarioOccurrences = new Map();
  const queue = [{ scenarioId: scenarioExecutionStart(scenarioCells, scenarioById), input }];
  let final = null;
  let visited = 0;
  while (queue.length > 0) {
    visited += 1;
    if (visited > STEP_BOUND) throw new Error("CAPABILITY_CARRIER_STEP_BOUND_EXCEEDED");
    const token = queue.shift();
    const scenarioId = String(token.scenarioId);
    const scenario = scenarioById.get(scenarioId);
    const projection = projectionByScenarioId.get(scenarioId);
    if (scenario === undefined || projection === undefined) {
      throw new Error("CAPABILITY_CARRIER_PROJECTION_MISSING: '" + scenarioId + "'.");
    }
    const descriptor = scenarioByScenarioId[scenarioId];
    let result;
    if (!admitScenarioContract(descriptor, token.input, "inputContractId")) {
      result = patternOutcome(token.input, "INPUT_REJECTED", "rejected");
    } else {
      result = await runProjection(projection, token.input, runtime);
      if (result.disposition === "completed") {
        result = patternOutcome(result.value, inferVariant(result.value, descriptor), "completed");
        if (!admitScenarioContract(descriptor, result.value, "outcomeContractId")) {
          result = patternOutcome(result.value, "OUTCOME_REJECTED", "rejected");
        }
      }
    }
    const occurrence = scenarioOccurrences.get(scenarioId) ?? 0;
    scenarioOccurrences.set(scenarioId, occurrence + 1);
    executions.push({
      executionId: rootExecutionId + ":" + scenarioId + (occurrence > 0 ? ":" + occurrence : ""),
      rootExecutionId,
      parentExecutionId: null,
      scenarioId,
      disposition: result.disposition,
      outcome: null
    });
    final = result;
    let routed = 0;
    for (const route of selectedScenarioRoutes(scenario.routes, result)) {
      const targetScenarioId = scenarioRouteTarget(route);
      const fromCellId = typeof route.fromCellId === "string" ? route.fromCellId : SCENARIO_CELL_PREFIX + scenarioId;
      const toCellId = typeof route.toCellId === "string"
        ? route.toCellId
        : targetScenarioId !== undefined ? SCENARIO_CELL_PREFIX + targetScenarioId : undefined;
      if (toCellId !== undefined) recordEdgeTestimony(runtime, { ...route, fromCellId, toCellId });
      if (targetScenarioId === undefined) continue;
      if (!scenarioById.has(targetScenarioId)) {
        throw new Error("CAPABILITY_CARRIER_PROJECTION_MISSING: '" + targetScenarioId + "'.");
      }
      const projected = typeof route.bindingAuthorityId === "string"
        ? await projectBindingValue(route.bindingAuthorityId, result.value, runtime)
        : result.value;
      queue.push({ scenarioId: targetScenarioId, input: projected });
      routed += 1;
    }
    if (routed === 0) break;
  }
  if (final === null) throw new Error("CAPABILITY_CARRIER_NO_TERMINAL_OUTCOME");
  const graphExecution = Object.freeze({
    disposition: final === null ? "failed" : final.disposition,
    outcome: final === null ? null : final.value,
    outcomeVariant: final === null ? "SUCCESS" : final.variant,
    cellTestimony: Object.freeze([...runtime.testimony.cells]),
    edgeTestimony: Object.freeze([...runtime.testimony.edges]),
    resolverTestimony: Object.freeze([...runtime.testimony.patterns]),
    observedPathDigest: observedPathDigest(runtime.testimony)
  });
  return {
    disposition: graphExecution.disposition === "completed" ? "terminated" : graphExecution.disposition,
    outcome: graphExecution.outcome,
    outcomeVariant: graphExecution.outcomeVariant,
    executions,
    observations: [],
    graphExecution
  };
}

export async function runFixture(fixtureId, options = {}) {
  const fixture = (fixtures.fixtures ?? []).find((candidate) => candidate.fixtureId === fixtureId);
  if (fixture === undefined) throw new Error("UNKNOWN_PROJECTED_FIXTURE: '" + fixtureId + "'.");
  const graphOutcomeCatalog = { ...(fixtures.graphOutcomeCatalog ?? {}), ...(fixture.graphOutcomeCatalog ?? {}) };
  return executeCapability(resolveFixtureGraphValue(fixture.input, graphOutcomeCatalog), {
    ...options,
    portOutcomes: { ...(fixtures.portOutcomes ?? {}), ...(fixture.portOutcomes ?? {}) },
    graphOutcomes: fixture.graphOutcomes,
    graphOutcomeCatalog
  });
}

export function conformance(observedExecution = null) {
  const findings = observedExecution && observedExecution.graphExecution
    ? verifyObservedCarrier(observedExecution.graphExecution)
    : [{ code: "EXECUTION_NOT_OBSERVED" }];
  findings.sort((left, right) => (left.code < right.code ? -1 : left.code > right.code ? 1 : 0));
  const closures = Object.fromEntries(conformanceClosures.map((closureId) => [closureId, {
    closureId,
    disposition: findings.length === 0 ? "PASS" : "FAIL",
    findings
  }]));
  return {
    queryId: "semantic-execution-graph-conformance",
    capabilityId,
    closures,
    platformMechanics: { disposition: "RESOLVED", resolutions: [] },
    executableOrigin: "PROJECTED_ONLY",
    admissionDisposition: findings.length === 0 ? "ADMITTED" : "REJECTED",
    findings
  };
}

export async function cli(argv = process.argv.slice(2)) {
  const encodedInput = argv[0] ?? (!process.stdin.isTTY ? fs.readFileSync(0, "utf8").trim() : "");
  if (!encodedInput) throw new Error("Expected canonical JSON input as one argument or on stdin.");
  if (encodedInput.startsWith("--fixture=")) {
    const fixtureId = encodedInput.slice("--fixture=".length);
    const result = await runFixture(fixtureId);
    process.stdout.write(JSON.stringify(result) + "\n");
    const fixture = (fixtures.fixtures ?? []).find((candidate) => candidate.fixtureId === fixtureId);
    process.exitCode = fixture && result.disposition === fixture.expected.disposition ? 0 : 1;
    return result;
  }
  let parsed;
  try { parsed = JSON.parse(encodedInput); }
  catch (error) {
    if (encodedInput.startsWith("{") || encodedInput.startsWith("[") || encodedInput.startsWith("\"")) throw error;
    parsed = encodedInput;
  }
  const result = await executeCapability(parsed);
  process.stdout.write(JSON.stringify(result) + "\n");
  process.exitCode = result.disposition !== "terminated" ? 1
    : result.outcome && result.outcome.interfaceExitDisposition === "NONZERO" ? 1 : 0;
  return result;
}

export { valueAt };
