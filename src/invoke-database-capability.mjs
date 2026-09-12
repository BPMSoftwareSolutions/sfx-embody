import { createHash, randomUUID } from 'node:crypto';
import { prepareDatabaseCapability } from './prepare-database-capability.mjs';
import { planNode } from './materialize-node.mjs';
import { loadMemoryScenario } from './load-memory-scenario.mjs';
import { readAuthority } from './read-authority.mjs';
import { readCircuitMedia } from './read-circuit-media.mjs';
import { readCapabilityMeaning } from './read-capability-meaning.mjs';
import { narrateCapabilityMeaning } from './narrate-capability-meaning.mjs';
import { narrateCapabilityMarkdown } from './narrate-capability-markdown.mjs';
import { listCapabilities } from './list-capabilities.mjs';

const digest = value => 'sha256:' + createHash('sha256').update(JSON.stringify(value)).digest('hex');
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const requestFields = ['object', 'verb', 'subject', 'namespace', 'input', 'inputType', 'query', 'as', 'scenario', 'format', 'display'];

// The capability's CLI interface configuration (input mapping, display projection),
// read from its own interface declaration. A capability that declares none keeps the
// canonical input and returns the full outcome unchanged.
function readCliConfiguration(bundle) {
  const records = [...(bundle?.authority?.recordsets?.[1] ?? []), ...(bundle?.authority?.recordsets?.[2] ?? [])];
  for (const record of records) {
    if (typeof record.source_path !== 'string' || !record.source_path.endsWith('interfaces.authority.json')) continue;
    try {
      const document = JSON.parse(Buffer.from(record.content_bytes.base64, 'base64').toString('utf8'));
      const cli = Array.isArray(document.interfaces) ? document.interfaces.find(entry => entry.kind === 'cli') : null;
      if (cli?.configuration) return cli.configuration;
    } catch { /* A malformed interface document is not CLI authority. */ }
  }
  return {};
}

const INPUT_TYPES = new Set(['json', 'text', 'number', 'boolean']);

function setInputPath(target, path, value) {
  const segments = path.split('.');
  let current = target;
  for (const segment of segments.slice(0, -1)) { if (!object(current[segment])) current[segment] = {}; current = current[segment]; }
  current[segments[segments.length - 1]] = value;
  return target;
}

// Build the canonical input the contract expects from a typed scalar and the
// capability's declared mapping: the contract, the path for the scalar, and any
// declared field defaults the capability states for its CLI surface.
function buildCanonicalInput(declared, type, raw) {
  if (!declared || typeof declared.contract !== 'string' || typeof declared.path !== 'string') throw new Error('CAPABILITY_INPUT_NOT_DECLARED');
  if (!INPUT_TYPES.has(type) || type === 'json') throw new Error('CAPABILITY_INPUT_TYPE_NOT_OFFERED');
  const value = type === 'number' ? Number(raw) : type === 'boolean' ? raw === true || raw === 'true' : String(raw);
  const input = setInputPath({ contractId: declared.contract }, declared.path, value);
  for (const [path, defaultValue] of Object.entries(declared.fields ?? {})) setInputPath(input, path, defaultValue);
  return input;
}

// Each operation declares the shape it accepts. Adding an operation is a row
// here and a row in the command mapping; it is never a new dispatch rule spread
// through the delivery.
const operations = {
  invoke: { object: 'capability', subject: true, input: 'required', inputType: true, display: true },
  observe: { object: 'capability', subject: true, input: 'required', inputType: true, display: true },
  prepare: { object: 'capability', subject: true, input: 'rejected' },
  circuit: { object: 'capability', subject: true, input: 'optional', scenario: true },
  reveal: { object: 'capability', subject: true, input: 'optional', scenario: true, views: ['circuit', 'meaning'], formats: ['text', 'markdown'] },
  catalogue: { object: 'capability', subject: false, input: 'rejected' },
  list: { object: 'capability', subject: false, input: 'rejected' },
  find: { object: 'capability', subject: false, input: 'rejected', query: true },
  artifact: { object: 'media', subject: true, input: 'rejected' },
};
// Reveal without an explicit view returns the capability's canonical story.
const DEFAULT_VIEW = 'meaning';
// Plain text remains the default; Markdown is asked for explicitly.
const DEFAULT_FORMAT = 'text';

export function validateDatabaseCommand(envelope) {
  if (!object(envelope) || envelope.deliveryType !== 'sfx-command-delivery.v1'
    || !Object.keys(envelope).every(key => ['deliveryType', 'operation', 'request'].includes(key))) throw new Error('DELIVERY_PROTOCOL_REJECTED');
  const request = envelope.request;
  const spec = Object.hasOwn(operations, envelope.operation) ? operations[envelope.operation] : undefined;
  if (!spec || !object(request) || request.object !== spec.object || request.verb !== envelope.operation) throw new Error('DATABASE_OPERATION_NOT_OFFERED');
  const present = value => typeof value === 'string' && value.length > 0;
  if (!Object.keys(request).every(key => requestFields.includes(key))
    || (spec.subject ? !present(request.subject) : request.subject !== undefined)
    || (spec.query ? !present(request.query) : request.query !== undefined)
    || (request.namespace !== undefined && !present(request.namespace))
    || (request.scenario !== undefined && (!spec.scenario || !present(request.scenario)))
    || (request.as !== undefined && (!spec.views || !present(request.as)))
    || (request.display !== undefined && spec.display !== true)
    || (request.inputType !== undefined && spec.inputType !== true)
    || (request.format !== undefined && (!spec.formats || !present(request.format)))) throw new Error('DATABASE_COMMAND_REJECTED');
  if (spec.views && request.as !== undefined && !spec.views.includes(request.as)) throw new Error('CAPABILITY_VIEW_NOT_OFFERED');
  if (spec.formats && request.format !== undefined && !spec.formats.includes(request.format)) throw new Error('CAPABILITY_FORMAT_NOT_OFFERED');
  // Only the narrated view is formatted. A retained circuit is delivered as the
  // publication retains it, so a format there is refused rather than ignored.
  if (spec.formats && request.format !== undefined && (request.as ?? DEFAULT_VIEW) !== 'meaning') throw new Error('CAPABILITY_FORMAT_NOT_OFFERED');
  if (spec.input === 'required' && !Object.hasOwn(request, 'input')) throw new Error('CAPABILITY_INPUT_REQUIRED');
  if (spec.input === 'rejected' && Object.hasOwn(request, 'input')) throw new Error(envelope.operation === 'prepare' ? 'PREPARATION_INPUT_NOT_OFFERED' : 'OPERATION_INPUT_NOT_OFFERED');
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
  // A scenario may be selected positionally for a view, or carried in the
  // circuit operation's existing input. Neither is inferred from an identity.
  const selectedScenarioId = request.scenario
    ?? (typeof request.input?.scenarioId === 'string' ? request.input.scenarioId : undefined);
  const selection = { capabilityId: request.subject, target: 'node',
    ...(request.namespace === undefined ? {} : { namespaceId: request.namespace }),
    ...(['circuit', 'reveal'].includes(request.verb) && selectedScenarioId !== undefined ? { scenarioId: selectedScenarioId } : {}) };
  const config = { databaseRoot, sdaRoot };
  if (request.verb === 'prepare') return prepareDatabaseCapability(selection, config, measure, timings);

  // Listing and finding read the estate model. They derive no scene and plan no body.
  if (['list', 'find'].includes(request.verb)) {
    const listing = await measure('readCapabilityListing', () => listCapabilities(databaseRoot, {
      ...(request.namespace === undefined ? {} : { namespaceId: request.namespace }),
      ...(request.query === undefined ? {} : { query: request.query }),
    }, { timings: timings.queries }));
    return { disposition: 'terminated', ...listing,
      evidence: { timings, authoritySource: 'DATABASE', bodyStorage: 'NOT_REQUESTED',
        snapshotId: listing.snapshotId, projectionDigest: listing.projectionDigest } };
  }

  // Revealing a capability's meaning reads its declared semantics. The narrative
  // is composed only of values the estate retains; nothing is inferred or filled in.
  if (request.verb === 'reveal' && (request.as ?? DEFAULT_VIEW) === 'meaning') {
    const meaning = await measure('readCapabilityMeaning', () => readCapabilityMeaning(databaseRoot, selection, { timings: timings.queries }));
    // Format selects how the same retained meaning is presented. It adds no
    // facts: both narrators read this one result and neither queries again.
    const format = request.format ?? DEFAULT_FORMAT;
    return { disposition: 'terminated', view: 'meaning', format,
      narrative: (format === 'markdown' ? narrateCapabilityMarkdown : narrateCapabilityMeaning)(meaning), meaning,
      evidence: { timings, authoritySource: 'DATABASE', bodyStorage: 'NOT_REQUESTED',
        snapshotId: meaning.snapshotId, projectionDigest: meaning.projectionDigest,
        viewDefinitionDigest: meaning.viewDefinitionDigest } };
  }

  if (['catalogue', 'circuit', 'artifact', 'reveal'].includes(request.verb)) {
    const media = request.verb === 'reveal' ? 'circuit' : request.verb;
    const retained = await measure('readRetainedCircuit', () => readCircuitMedia(databaseRoot, {
      operation: media, capabilityId: request.subject, viewId: request.input?.viewId,
      artifactDigest: media === 'artifact' ? request.subject : undefined,
    }));
    return { disposition: 'terminated', ...(request.verb === 'reveal' ? { view: 'circuit' } : {}),
      [media === 'catalogue' ? 'catalogue' : media === 'artifact' ? 'media' : 'circuit']: retained,
      evidence: { authoritySource: 'DATABASE_MEDIA', snapshotId: retained.snapshotId, publicationDigest: retained.publicationDigest } };
  }
  // Invocation is direct: it resolves the selected authority, plans the native
  // body and executes it in memory on every call. Observation runs the same
  // execution and additionally streams its telemetry; it is not a second path.
  // Preparation is an optional, separately invoked retained proof and is never consumed here.
  const bundle = await measure('readAuthority', () => readAuthority(databaseRoot, selection, { retainObjects: false, timings: timings.queries }));
  const cli = readCliConfiguration(bundle);
  const display = cli.display ?? null;
  const plan = await measure('planNativeBody', () => planNode({ bundle, sdaRoot }));
  const runtime = await measure('loadMemoryModules', () => loadMemoryScenario(plan));
  const executions = [], observations = [];
  const scenario = await measure('createScenario', () => runtime.createScenario({ observer: { observe: value => { observations.push(value); observe(value); } },
    clock: { now: () => new Date().toISOString() } }));
  const executionId = randomUUID();
  let input;
  if (typeof request.input !== 'string') input = structuredClone(request.input);
  else {
    const inputType = request.inputType ?? cli.input?.type ?? 'json';
    if (inputType === 'json') {
      try { input = JSON.parse(request.input); }
      catch { throw new Error('CAPABILITY_INPUT_JSON_REJECTED'); }
    } else input = buildCanonicalInput(cli.input, inputType, request.input);
  }
  const result = await measure('executeScenario', () => scenario.execute(input, { executionId, rootExecutionId: executionId,
    rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect: value => executions.push(value) }));
  const entry = plan.receipts.find(r => r.plan.scenarioId === plan.selectedScenarioId);
  return { disposition: result.disposition === 'failed' ? 'failed' : 'terminated',
    ...(result.disposition === 'failed' ? { errorCode: 'CAPABILITY_EXECUTION_FAILED' } : {}),
    outcome: { capabilityId: plan.capabilityId, scenarioId: plan.selectedScenarioId, result, executions, observations,
      ...(display ? { display } : {}),
      evidence: { timings, authoritySource: 'DATABASE', bodyStorage: 'MEMORY_ONLY', managedAdmission: 'NOT_REQUESTED',
        executionOperation: request.verb,
        providerStatus: 'CANDIDATE_PHYSICAL_PROVIDER', inputDigest: digest(input), resultDigest: digest(result),
        snapshotId: bundle.authority.snapshotId, projectionDigest: bundle.authority.projectionDigest,
        authorityIdentity: Object.fromEntries(['scenarioDefinitionDigest', 'pinnedPlatformCommit', 'platformDigest', 'resolverVersion', 'artifactDigest'].map(key => [key, entry.receipt[key]])),
        queries: [bundle.authority, bundle.closure, bundle.resolutions, bundle.mechanics].filter(Boolean).map(({ recordsets, ...identity }) => identity),
        modules: runtime.modules, resources: runtime.accesses, externalDependencies: runtime.externalDependencies } } };
}
