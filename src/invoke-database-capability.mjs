import { createHash, randomUUID } from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { readExecutionDelivery } from './read-execution-delivery.mjs';

const digest = value => 'sha256:' + createHash('sha256').update(JSON.stringify(value)).digest('hex');
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const requestFields = ['object', 'verb', 'subject', 'namespace', 'input', 'inputType', 'query', 'as', 'scenario', 'format', 'display'];
// The estate runtime root: a Port binding configuration may name an estate
// provider module relative to this root.
const ESTATE_RUNTIME_ROOT = new URL('../', import.meta.url);

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

// A capability is delivered by the estate runtime when its declared execution
// authority composes estate-provider Ports, directly or through composed
// Scenarios. The provider module and export are declaration data; nothing here
// dispatches on capability identity.
function readRecords(bundle) {
  return [...(bundle?.authority?.recordsets?.[1] ?? []), ...(bundle?.authority?.recordsets?.[2] ?? [])];
}
function readJsonDocument(bundle, suffix) {
  for (const record of readRecords(bundle)) {
    if (typeof record.source_path !== 'string' || !record.source_path.endsWith(suffix)) continue;
    try { return JSON.parse(Buffer.from(record.content_bytes.base64, 'base64').toString('utf8')); } catch { /* not authority */ }
  }
  return null;
}
function readRootAuthority(bundle, scenarioId) {
  const authorities = readJsonDocument(bundle, '/execution-authorities.authority.json');
  return authorities?.executionAuthorities?.find(a => a.owningScenarioId === scenarioId) ?? null;
}
function readEstatePortBinding(bundle, portId) {
  const interfaces = readJsonDocument(bundle, '/interfaces.authority.json');
  return interfaces?.portBindings?.find(b => b.portId === portId) ?? null;
}
function ownerOfScenario(bundle, scenarioId) {
  return bundle.closure.recordsets[0].find(r => r.downstream_scenario_id === scenarioId)?.owning_capability_id ?? null;
}

export async function isEstateDelivery(bundle, context) {
  try {
    const selected = bundle.authority.recordsets[0][0].scenario_id;
    const pending = [selected], visited = new Set();
    // The declaration already includes the complete invocation closure and its
    // port bindings. Read it once, including cycles, without querying children
    // again or executing any operation during delivery selection.
    while (pending.length) {
      const id = pending.pop();
      if (visited.has(id)) continue;
      visited.add(id);
      const authority = readRootAuthority(bundle, id);
      if (!authority) continue;
      for (const operation of authority.operations ?? []) {
        if (operation.kind === 'invoke-port') {
          if (readEstatePortBinding(bundle, operation.portId)?.configuration?.estateProvider) return true;
        } else if (operation.kind === 'invoke-scenario') pending.push(operation.scenarioId);
      }
    }
    return false;
  } catch { return false; }
}

// Execute a capability's declared execution authority as a sequence of estate
// operations: an estate-provider Port transforms the running state, and a
// composed Scenario runs its own declared operations with that state. State is
// threaded exactly as the declared authority orders it.
export async function executeEstateCapability({ capabilityId, scenarioId, namespaceId }, state, context, ancestry = []) {
  const bundle = await context.readAuthority(context.databaseRoot,
    { capabilityId, ...(context.deliveryTarget === undefined ? {} : { target: context.deliveryTarget }),
      ...(namespaceId === undefined ? {} : { namespaceId }),
      ...(scenarioId === undefined ? {} : { scenarioId }) }, { retainObjects: false });
  const selected = bundle.authority.recordsets[0][0].scenario_id;
  const authority = readRootAuthority(bundle, selected);
  if (!authority) throw new Error('ESTATE_AUTHORITY_NOT_RESOLVED:' + capabilityId);
  let current = state;
  for (const operation of authority.operations ?? []) {
    if (operation.kind === 'invoke-port') {
      const binding = readEstatePortBinding(bundle, operation.portId);
      const estate = binding?.configuration?.estateProvider;
      if (!estate || typeof estate.module !== 'string' || typeof estate.export !== 'string')
        throw new Error('ESTATE_PROVIDER_NOT_DECLARED:' + capabilityId + ':' + operation.portId);
      const provider = await import(new URL(estate.module, ESTATE_RUNTIME_ROOT).href);
      if (typeof provider[estate.export] !== 'function') throw new Error('ESTATE_PROVIDER_EXPORT_NOT_FOUND:' + estate.export);
      current = await provider[estate.export](binding.configuration, current, context);
    } else if (operation.kind === 'invoke-scenario') {
      const owner = ownerOfScenario(bundle, operation.scenarioId);
      if (!owner) throw new Error('ESTATE_TARGET_CAPABILITY_NOT_RESOLVED:' + operation.scenarioId);
      const key = owner + ':' + operation.scenarioId;
      if (ancestry.includes(key)) throw new Error('ESTATE_COMPOSITION_CYCLE:' + key);
      current = await executeEstateCapability({ capabilityId: owner, scenarioId: operation.scenarioId }, current, context, [...ancestry, key]);
    } else {
      throw new Error('ESTATE_OPERATION_NOT_SUPPORTED:' + operation.kind);
    }
  }
  return current;
}

// The CLI configuration supplies both carrier mappings. This boundary invokes
// the declared execution capability and returns its declared delivery form.
export async function executeSelectedDeclaration(delivery, selection, selected, scenarioInput, context) {
  const { evaluateExpression } = await import(new URL('languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs',
    pathToFileURL(context.sdaRoot.replace(/\\/g, '/') + '/')).href);
  const rootExecutionId = context.rootExecutionId ?? randomUUID();
  const carrier = { selection, selected, scenarioInput, rootExecutionId };
  const input = evaluateExpression(delivery.requestExpression, { input: carrier, root: scenarioInput });
  const executionResult = await executeEstateCapability({ capabilityId: delivery.capabilityId }, input,
    { ...context, rootExecutionId, deliveryTarget: delivery.defaultTarget });
  return evaluateExpression(delivery.resultExpression, { input: { ...carrier, executionResult }, root: scenarioInput });
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
  materialize: { object: 'capability', subject: true, input: 'required', inputType: true, display: true },
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

export async function executeDatabaseCommand(envelope, { databaseRoot, sdaRoot, onObservation, spawnDeclared,
  readAuthority: suppliedAuthorityReader, readQuery, rootExecutionId, signal }) {
  const timings = { unit: 'milliseconds', queries: {} };
  const observations = [];
  const observe = value => { observations.push(value); try { onObservation?.(value); } catch { /* Observation is not execution authority. */ } };
  // Reuse declarations only within this invocation. No retained body or
  // declaration cache is consulted, and callers receive independent values.
  const declarations = new Map();
  const declarationKey = (root, selection) => JSON.stringify([root,
    Object.entries(selection).filter(([, value]) => value !== undefined).sort(([a], [b]) => a.localeCompare(b))]);
  const readSelectedAuthority = async (root, selection, options) => {
    const key = declarationKey(root, selection);
    if (declarations.has(key)) return structuredClone(declarations.get(key));
    const bundle = await suppliedAuthorityReader(root, selection, options);
    declarations.set(key, bundle);
    declarations.set(declarationKey(root, bundle.selection), bundle);
    declarations.set(declarationKey(root, { ...selection, scenarioId: bundle.authority.recordsets[0][0].scenario_id }), bundle);
    return structuredClone(bundle);
  };
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
  const selection = { capabilityId: request.subject,
    ...(request.namespace === undefined ? {} : { namespaceId: request.namespace }),
    ...(['circuit', 'reveal'].includes(request.verb) && selectedScenarioId !== undefined ? { scenarioId: selectedScenarioId } : {}) };
  const config = { databaseRoot, sdaRoot, estateRoot: fileURLToPath(ESTATE_RUNTIME_ROOT), spawnDeclared,
    onObservation: observe, readAuthority: readSelectedAuthority, readQuery, rootExecutionId, signal };
  let delivery;
  if (['invoke', 'observe'].includes(request.verb)) {
    delivery = await measure('readExecutionDelivery', () => readExecutionDelivery(config));
    selection.target = delivery.defaultTarget;
    config.deliveryTarget = delivery.defaultTarget;
  }
  // The reader operations (prepare/list/find/reveal/catalogue/circuit/artifact)
  // are declared capabilities reached through the frontdoor; this loader only
  // reads the selected declaration and hands it to the kernel.
  // Invocation resolves the selected declaration and its execution delivery.
  // Observation runs the same execution and streams the same telemetry.
  // Preparation is an optional, separately invoked retained proof and is never consumed here.
  const bundle = await measure('readAuthority', () => readSelectedAuthority(databaseRoot, selection, { retainObjects: false, timings: timings.queries }));
  const cli = readCliConfiguration(bundle);
  // Invocation reads the capability's declared authority from the estate view and
  // hands it to the kernel. No per-port estate providers; no materialization.
  const selected = bundle.authority.recordsets[0][0];
  let input;
  if (typeof request.input !== 'string') input = structuredClone(request.input);
  else {
    const inputType = request.inputType ?? cli.input?.type ?? 'json';
    if (inputType === 'json') {
      try { input = JSON.parse(request.input); }
      catch { throw new Error('CAPABILITY_INPUT_JSON_REJECTED'); }
    } else input = buildCanonicalInput(cli.input, inputType, request.input);
  }
  // A graph source supplied as the invocation input is the authority handed to
  // the kernel; otherwise the selected capability's declared graph is read from
  // the estate view and the invocation input is threaded through it. The
  // assembled carrier is identical either way.
  const suppliedGraph = object(input) && typeof input.capabilityId === 'string'
    && Array.isArray(input.scenarios) && Array.isArray(input.executionAuthorities);
  let graphSource;
  if (suppliedGraph) graphSource = structuredClone(input);
  else {
    const graphRead = await measure('readGraphSource', () => readQuery(
      "SELECT graph_source FROM analysis.v_capability_graph_source WHERE capability_id = CONVERT(nvarchar(400), JSON_VALUE(@input,'$.capabilityId'))",
      { input: { capabilityId: selection.capabilityId }, rowLimit: 1, retainObjects: false }));
    if (!graphRead.recordsets[0] || graphRead.recordsets[0].length === 0) throw new Error('DECLARED_GRAPH_SOURCE_MISSING:' + selection.capabilityId);
    graphSource = JSON.parse(graphRead.recordsets[0][0].graph_source);
    graphSource.input = input;
  }
  // The display projection is declared on the capability's CLI interface, which
  // travels with the graph source's interface authority. The bundle may not carry
  // it now that the boot read uses the estate views.
  const display = graphSource?.interfaceAuthority?.interfaces?.find(entry => entry.kind === 'cli')?.configuration?.display
    ?? cli.display ?? null;
  const outcome = await measure('executeDeclaredGraph', () => executeEstateCapability({ capabilityId: 'run-declared-graph' }, graphSource, config));
  return { disposition: 'terminated',
    outcome: { capabilityId: selection.capabilityId, scenarioId: selected.scenario_id, result: { outcome }, executions: [], observations: [],
      ...(display ? { display } : {}),
      evidence: { timings, authoritySource: 'DATABASE', bodyStorage: 'NOT_REQUESTED', managedAdmission: 'NOT_REQUESTED',
        snapshotId: bundle.authority.snapshotId, projectionDigest: bundle.authority.projectionDigest } } };
}
