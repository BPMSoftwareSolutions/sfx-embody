import { createHash, randomUUID } from 'node:crypto';
import { readAuthority } from './read-authority.mjs';
import { planNode } from './materialize-node.mjs';
import { loadMemoryScenario } from './load-memory-scenario.mjs';

const digest = value => 'sha256:' + createHash('sha256').update(JSON.stringify(value)).digest('hex');
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const requestFields = ['object', 'verb', 'subject', 'namespace', 'input'];

export function validateDatabaseCommand(envelope) {
  if (!object(envelope) || envelope.deliveryType !== 'sfx-command-delivery.v1'
    || !Object.keys(envelope).every(key => ['deliveryType', 'operation', 'request'].includes(key))) throw new Error('DELIVERY_PROTOCOL_REJECTED');
  const request = envelope.request;
  if (envelope.operation !== 'invoke' || !object(request) || request.object !== 'capability' || request.verb !== 'invoke') throw new Error('DATABASE_OPERATION_NOT_OFFERED');
  if (!Object.keys(request).every(key => requestFields.includes(key))
    || typeof request.subject !== 'string' || !request.subject.length
    || (request.namespace !== undefined && (typeof request.namespace !== 'string' || !request.namespace.length))) throw new Error('DATABASE_COMMAND_REJECTED');
  if (!Object.hasOwn(request, 'input')) throw new Error('CAPABILITY_INPUT_REQUIRED');
  return request;
}

export async function invokeDatabaseCapability(envelope, { databaseRoot, sdaRoot }) {
  const timings = { unit: 'milliseconds', queries: {} };
  const measure = async (name, work) => {
    const start = performance.now();
    try { return await work(); }
    finally { timings[name] = performance.now() - start; }
  };
  const request = structuredClone(validateDatabaseCommand(envelope));
  const bundle = await measure('readAuthority', () => readAuthority(databaseRoot, { capabilityId: request.subject, target: 'node',
    ...(request.namespace === undefined ? {} : { namespaceId: request.namespace }) }, { retainObjects: false, timings: timings.queries }));
  const plan = await measure('planNativeBody', () => planNode({ bundle, sdaRoot }));
  const runtime = await measure('loadMemoryModules', () => loadMemoryScenario(plan));
  const executions = [], observations = [];
  const scenario = await measure('createScenario', () => runtime.createScenario({ observer: { observe: value => observations.push(value) },
    clock: { now: () => new Date().toISOString() } }));
  const executionId = randomUUID();
  const input = structuredClone(request.input);
  const result = await measure('executeScenario', () => scenario.execute(input, { executionId, rootExecutionId: executionId,
    rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect: value => executions.push(value) }));
  const entry = plan.receipts.find(r => r.plan.scenarioId === plan.selectedScenarioId);
  return { disposition: result.disposition === 'failed' ? 'failed' : 'terminated',
    ...(result.disposition === 'failed' ? { errorCode: 'CAPABILITY_EXECUTION_FAILED' } : {}),
    outcome: { capabilityId: plan.capabilityId, scenarioId: plan.selectedScenarioId, result, executions, observations,
      evidence: { timings, authoritySource: 'DATABASE', bodyStorage: 'MEMORY_ONLY', managedAdmission: 'NOT_REQUESTED',
        providerStatus: 'CANDIDATE_PHYSICAL_PROVIDER', inputDigest: digest(request.input), resultDigest: digest(result),
        snapshotId: bundle.authority.snapshotId, projectionDigest: bundle.authority.projectionDigest,
        authorityIdentity: Object.fromEntries(['scenarioDefinitionDigest', 'pinnedPlatformCommit', 'platformDigest', 'resolverVersion', 'artifactDigest'].map(key => [key, entry.receipt[key]])),
        queries: [bundle.authority, bundle.resolutions, bundle.mechanics].map(({ recordsets, ...identity }) => identity),
        modules: runtime.modules, resources: runtime.accesses, externalDependencies: runtime.externalDependencies } } };
}
