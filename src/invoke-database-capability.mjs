import { createHash, randomUUID } from 'node:crypto';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { prepareDatabaseCapability } from './prepare-database-capability.mjs';
import { planNode } from './materialize-node.mjs';
import { loadMemoryScenario } from './load-memory-scenario.mjs';
import { readAuthority } from './read-authority.mjs';
import { deriveCapability } from './derive-circuit.mjs';

const digest = value => 'sha256:' + createHash('sha256').update(JSON.stringify(value)).digest('hex');
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const requestFields = ['object', 'verb', 'subject', 'namespace', 'input'];

export function validateDatabaseCommand(envelope) {
  if (!object(envelope) || envelope.deliveryType !== 'sfx-command-delivery.v1'
    || !Object.keys(envelope).every(key => ['deliveryType', 'operation', 'request'].includes(key))) throw new Error('DELIVERY_PROTOCOL_REJECTED');
  const request = envelope.request;
  if (!['invoke', 'prepare', 'circuit', 'catalogue'].includes(envelope.operation) || !object(request) || request.object !== 'capability' || request.verb !== envelope.operation) throw new Error('DATABASE_OPERATION_NOT_OFFERED');
  if (!Object.keys(request).every(key => requestFields.includes(key))
    || (request.verb !== 'catalogue' && (typeof request.subject !== 'string' || !request.subject.length))
    || (request.subject !== undefined && (typeof request.subject !== 'string' || !request.subject.length))
    || (request.namespace !== undefined && (typeof request.namespace !== 'string' || !request.namespace.length))) throw new Error('DATABASE_COMMAND_REJECTED');
  if (request.verb === 'invoke' && !Object.hasOwn(request, 'input')) throw new Error('CAPABILITY_INPUT_REQUIRED');
  if (request.verb === 'prepare' && Object.hasOwn(request, 'input')) throw new Error('PREPARATION_INPUT_NOT_OFFERED');
  return request;
}

export async function executeDatabaseCommand(envelope, { databaseRoot, sdaRoot, onObservation }) {
  const timings = { unit: 'milliseconds', queries: {} };
  const observe = value => { try { onObservation?.(value); } catch { /* Observation is not execution authority. */ } };
  const measure = async (name, work) => {
    const start = performance.now();
    observe({ observationType: 'delivery-phase', phase: name, status: 'started', observedAt: new Date().toISOString() });
    try {
      const result = await work();
      observe({ observationType: 'delivery-phase', phase: name, status: 'completed', observedAt: new Date().toISOString() });
      return result;
    }
    catch (error) {
      observe({ observationType: 'delivery-phase', phase: name, status: 'failed', observedAt: new Date().toISOString() });
      throw error;
    }
    finally { timings[name] = performance.now() - start; }
  };
  const request = structuredClone(validateDatabaseCommand(envelope));
  const selection = { capabilityId: request.subject, target: 'node', ...(request.namespace === undefined ? {} : { namespaceId: request.namespace }),
    ...(request.verb === 'circuit' && typeof request.input?.scenarioId === 'string' ? { scenarioId: request.input.scenarioId } : {}) };
  const config = { databaseRoot, sdaRoot };
  if (request.verb === 'prepare') return prepareDatabaseCapability(selection, config, measure, timings);
  // The catalogue lists capabilities from the model; it derives no scene.
  if (request.verb === 'catalogue') {
    const { query } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/run.mjs')));
    const listing = await measure('readCatalogue', () => query(
      `SELECT c.capability_id AS capabilityId, n.namespace_id AS namespaceId
         FROM model.estate_capability ec
         JOIN model.capability c ON c.capability_pk = ec.capability_pk
         JOIN model.identity_namespace n ON n.namespace_pk = c.namespace_pk
        WHERE ec.estate_model_pk = @estate_model_pk
        ORDER BY c.capability_id`, { retainObjects: false, rowLimit: 100000 }));
    return { disposition: 'terminated', catalogue: { snapshotId: listing.snapshotId, projectionDigest: listing.projectionDigest,
      capabilities: listing.recordsets[0] },
      evidence: { authoritySource: 'DATABASE', snapshotId: listing.snapshotId, projectionDigest: listing.projectionDigest } };
  }
  // A circuit is a view of the same authority invocation reads. It is derived
  // here, from the selected capability and its declared closure, rather than
  // from any separately compiled product, so the database is the only source.
  if (request.verb === 'circuit') {
    const bundle = await measure('readAuthority', () => readAuthority(databaseRoot, selection, { retainObjects: false, timings: timings.queries }));
    const circuit = deriveCapability({ bundle, capabilityId: request.subject });
    return { disposition: 'terminated', circuit, evidence: { authoritySource: 'DATABASE',
      bodyStorage: 'NOT_REQUESTED', snapshotId: bundle.authority.snapshotId, projectionDigest: bundle.authority.projectionDigest,
      queries: [bundle.authority, bundle.closure].filter(Boolean).map(({ recordsets, ...identity }) => identity) } };
  }
  // Invocation is direct: it resolves the selected authority, plans the native
  // body and executes it in memory on every call. Preparation is an optional,
  // separately invoked retained proof and is never consumed here.
  const bundle = await measure('readAuthority', () => readAuthority(databaseRoot, selection, { retainObjects: false, timings: timings.queries }));
  const plan = await measure('planNativeBody', () => planNode({ bundle, sdaRoot }));
  const runtime = await measure('loadMemoryModules', () => loadMemoryScenario(plan));
  const executions = [], observations = [];
  const scenario = await measure('createScenario', () => runtime.createScenario({ observer: { observe: value => { observations.push(value); observe(value); } },
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
        queries: [bundle.authority, bundle.closure, bundle.resolutions, bundle.mechanics].filter(Boolean).map(({ recordsets, ...identity }) => identity),
        modules: runtime.modules, resources: runtime.accesses, externalDependencies: runtime.externalDependencies } } };
}
