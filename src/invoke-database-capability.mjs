import fs from 'node:fs/promises';
import { createHash, randomUUID } from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { readExecutionDelivery } from './read-execution-delivery.mjs';
import { createExecutionDrilldown, isObservationAltitudeSelection } from './execution-drilldown.mjs';

const digest = value => 'sha256:' + createHash('sha256').update(JSON.stringify(value)).digest('hex');
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const requestFields = ['object', 'verb', 'subject', 'namespace', 'input', 'inputType', 'query', 'as', 'scenario', 'format', 'display', 'observationAltitudes'];
// The estate runtime root: a Port binding configuration may name an estate
// provider module relative to this root.
const ESTATE_RUNTIME_ROOT = new URL('../', import.meta.url);
// The target language's admitted mechanic registry is declared authority. A Port
// that names a platform mechanic by `platformCapabilityId` carries no module
// path; the boot resolves the per-language implementation from the registry.
const PLATFORM_REGISTRY_REF = 'kernel/semantic-authority/consumer/node-mechanic-registry.authority.v1.json';
const platformRegistries = new Map();
const sdaBaseUrl = sdaRoot => pathToFileURL(String(sdaRoot).replace(/\\/g, '/').replace(/\/?$/, '/'));
async function readPlatformRegistry(sdaRoot) {
  const url = new URL(PLATFORM_REGISTRY_REF, sdaBaseUrl(sdaRoot));
  if (!platformRegistries.has(url.href)) platformRegistries.set(url.href, fs.readFile(url, 'utf8').then(text => JSON.parse(text)));
  return platformRegistries.get(url.href);
}
async function resolvePlatformMechanic(binding, context) {
  const platformCapabilityId = binding?.platformCapabilityId;
  if (typeof platformCapabilityId !== 'string' || platformCapabilityId.length === 0
    || typeof context?.sdaRoot !== 'string' || context.sdaRoot.length === 0) return null;
  const registry = await readPlatformRegistry(context.sdaRoot);
  const entries = [...(registry.contractAdmissions ?? []), ...(registry.eventPorts ?? []), ...(registry.stateProjections ?? [])];
  const entry = entries.find(candidate => candidate.platformCapabilityId === platformCapabilityId
    && candidate.kind === 'direct' && candidate.invocation === 'configuration'
    && typeof candidate.providerModule === 'string' && typeof candidate.providerExport === 'string');
  if (!entry) return null;
  const moduleRoot = typeof registry.providerModuleRoot === 'string' ? registry.providerModuleRoot : '';
  const providerModule = await import(new URL(moduleRoot + '/' + entry.providerModule, sdaBaseUrl(context.sdaRoot)).href);
  return typeof providerModule[entry.providerExport] === 'function' ? providerModule[entry.providerExport] : null;
}

// The capability's CLI interface configuration (input mapping, display projection),
// read from its own interface declaration. A capability that declares none keeps the
// canonical input and returns the full outcome unchanged.
function readCliConfiguration(bundle) {
  const declared = bundle.graphSource?.interfaceAuthority?.interfaces?.find(entry => entry.kind === 'cli');
  if (declared?.configuration) return declared.configuration;
  const records = readRecords(bundle);
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

// The declared reading selection. The capability's CLI configuration declares
// each reading's altitude set in order; the first reading whose declared
// altitudes admit every requested altitude is the reading the display
// transformation consumes. A capability that declares no readings reads the
// default. The boot selects; it does not carry the altitude vocabulary.
function deriveReading(readings, observationAltitudes) {
  const selected = Array.isArray(observationAltitudes) ? observationAltitudes : [];
  for (const entry of Array.isArray(readings) ? readings : []) {
    if (typeof entry?.reading !== 'string' || !Array.isArray(entry.altitudes)) continue;
    if (selected.every(altitude => entry.altitudes.includes(altitude))) return entry.reading;
  }
  return 'default';
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
  if (bundle.graphSource) return bundle.graphSource.executionAuthorities?.find(a => a.owningScenarioId === scenarioId) ?? null;
  const authorities = readJsonDocument(bundle, '/execution-authorities.authority.json');
  return authorities?.executionAuthorities?.find(a => a.owningScenarioId === scenarioId) ?? null;
}
function readEstatePortBinding(bundle, portId) {
  if (bundle.graphSource) return bundle.graphSource.interfaceAuthority?.portBindings?.find(b => b.portId === portId) ?? null;
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
      ...(scenarioId === undefined ? {} : { scenarioId }) }, { retainObjects: false, documents: false });
  const selected = bundle.authority.recordsets[0][0].scenario_id;
  const authority = readRootAuthority(bundle, selected);
  if (!authority) throw new Error('ESTATE_AUTHORITY_NOT_RESOLVED:' + capabilityId);
  let current = state;
  for (const operation of authority.operations ?? []) {
    if (operation.kind === 'invoke-port') {
      const binding = readEstatePortBinding(bundle, operation.portId);
      const estate = binding?.configuration?.estateProvider;
      let invokePort;
      if (estate && typeof estate.module === 'string' && typeof estate.export === 'string') {
        const provider = await import(new URL(estate.module, ESTATE_RUNTIME_ROOT).href);
        invokePort = provider[estate.export];
        if (typeof invokePort !== 'function') throw new Error('ESTATE_PROVIDER_EXPORT_NOT_FOUND:' + estate.export);
      } else {
        invokePort = await resolvePlatformMechanic(binding, context);
        if (typeof invokePort !== 'function') throw new Error('PLATFORM_MECHANIC_NOT_DECLARED:' + capabilityId + ':' + operation.portId);
      }
      current = await invokePort(binding.configuration, current, context);
      if (typeof context?.onState === 'function') { try { context.onState(current, operation); } catch { /* State observation is not execution authority. */ } }
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

// The kernel's declared-expression evaluator: the one mechanism that evaluates a
// declared expression on this target. The execution delivery's result expression
// and the declared display projection both go through it; the boot never
// interprets an expression itself.
async function loadExpressionEvaluator(sdaRoot) {
  const { evaluateExpression } = await import(new URL('languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs',
    pathToFileURL(String(sdaRoot).replace(/\\/g, '/') + '/')).href);
  return evaluateExpression;
}

// The CLI configuration supplies both carrier mappings. This boundary invokes
// the declared execution capability and returns its declared delivery form.
export async function executeSelectedDeclaration(delivery, selection, selected, scenarioInput, context) {
  const evaluateExpression = await loadExpressionEvaluator(context.sdaRoot);
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
  observe: { object: 'capability', subject: true, input: 'required', inputType: true, display: true, observationAltitudes: true },
  circuit: { object: 'capability', subject: true, input: 'optional', scenario: true, reader: 'read-retained-publication' },
  // A reader operation is a declared capability reached through the frontdoor;
  // the subject is its input, never an execution it triggers. Reveal's reader
  // follows the declared view.
  reveal: { object: 'capability', subject: true, input: 'optional', scenario: true, views: ['circuit', 'meaning'], formats: ['text', 'markdown'],
    readers: { meaning: 'read-capability-meaning', circuit: 'read-retained-publication' } },
  catalogue: { object: 'capability', subject: false, input: 'rejected', reader: 'list-capabilities' },
  list: { object: 'capability', subject: false, input: 'rejected', reader: 'list-capabilities' },
  find: { object: 'capability', subject: false, input: 'rejected', query: true, reader: 'list-capabilities' },
  artifact: { object: 'media', subject: true, input: 'rejected', reader: 'read-retained-publication' },
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
    || (request.observationAltitudes !== undefined && spec.observationAltitudes !== true)
    || (request.format !== undefined && (!spec.formats || !present(request.format)))) throw new Error('DATABASE_COMMAND_REJECTED');
  if (spec.observationAltitudes === true && request.observationAltitudes !== undefined
    && !isObservationAltitudeSelection(request.observationAltitudes)) throw new Error('CAPABILITY_OBSERVATION_ALTITUDE_NOT_OFFERED');
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
  readAuthority: suppliedAuthorityReader, readQuery, rootExecutionId, signal, collectProviderExecution, effectContextOverrides }) {
  const timings = { unit: 'milliseconds', queries: {} };
  const observations = [];
  const observe = value => { observations.push(value); try { onObservation?.(value); } catch { /* Observation is not execution authority. */ } };
  // Reuse declarations only within this invocation. No retained body or
  // declaration cache is consulted, and callers receive independent values.
  const declarations = new Map();
  let authorityIdentity, mechanics;
  const declarationKey = (root, selection, options = {}) => JSON.stringify([root,
    options.documents ?? true, options.resolution ?? 'closure', options.retainObjects ?? true,
    Object.entries(selection).filter(([, value]) => value !== undefined).sort(([a], [b]) => a.localeCompare(b))]);
  const readSelectedAuthority = async (root, selection, options) => {
    const key = declarationKey(root, selection, options);
    if (declarations.has(key)) return structuredClone(declarations.get(key));
    const bundle = await suppliedAuthorityReader(root, selection, { ...options, mechanics });
    authorityIdentity ??= bundle.authority;
    if (bundle.authority.truncated || ['snapshotId', 'projectionDigest', 'viewDefinitionDigest'].some(
      field => bundle.authority[field] !== authorityIdentity[field])) throw new Error('DATABASE_AUTHORITY_NOT_COHERENT');
    mechanics ??= bundle.mechanics;
    declarations.set(key, bundle);
    declarations.set(declarationKey(root, bundle.selection, options), bundle);
    declarations.set(declarationKey(root, { ...selection, scenarioId: bundle.authority.recordsets[0][0].scenario_id }, options), bundle);
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
    onObservation: observe, readAuthority: readSelectedAuthority, readQuery, rootExecutionId, signal,
    collectProviderExecution, effectContextOverrides };
  let delivery;
  if (['invoke', 'observe'].includes(request.verb)) {
    delivery = await measure('readExecutionDelivery', () => readExecutionDelivery(config));
    authorityIdentity = delivery;
    selection.target = delivery.defaultTarget;
    config.deliveryTarget = delivery.defaultTarget;
  }
  // A declared reader operation resolves through its own declared capability,
  // with the subject as the read input. It never executes the subject.
  const view = request.as ?? DEFAULT_VIEW;
  const readerCapability = operations[request.verb]?.readers?.[view] ?? operations[request.verb]?.reader;
  if (readerCapability) {
    const reader = await measure('readAuthority', () => readSelectedAuthority(databaseRoot,
      { capabilityId: readerCapability }, { retainObjects: false, documents: false, timings: timings.queries }));
    if (!reader.graphSource) throw new Error('DECLARED_GRAPH_SOURCE_MISSING:' + readerCapability);
    const readerSource = structuredClone(reader.graphSource);
    // The reader input is the declared selection: a subject for reveal, a query
    // for find, a namespace for a listing, a carrier for the retained media.
    const retained = request.verb === 'circuit' || (request.verb === 'reveal' && view === 'circuit');
    readerSource.input = {
      ...(request.subject === undefined ? {} : { capabilityId: request.subject }),
      ...(request.query === undefined ? {} : { query: request.query }),
      ...(selection.namespaceId === undefined ? {} : { namespaceId: selection.namespaceId }),
      ...(selectedScenarioId === undefined ? {} : { scenarioId: selectedScenarioId }),
      ...(retained ? { operation: 'circuit' } : {}),
      ...(request.verb === 'artifact' ? { operation: 'artifact', artifactDigest: request.subject } : {}),
      ...(typeof request.input?.viewId === 'string' ? { viewId: request.input.viewId } : {}) };
    const read = await measure('executeDeclaredGraph', () => executeEstateCapability({ capabilityId: 'run-declared-graph' }, readerSource, config));
    // A reader never executes meaning; a failed read is the domain failure the
    // declared read raised, not an outcome a caller should inspect.
    if (read?.disposition === 'failed' || read?.code === 'CELL_EXECUTION_FAILED') {
      const serialized = JSON.stringify(read);
      const message = read.error?.message ?? read.message ?? read.errorCode ?? read.error?.code
        ?? /"message":"([^"]+)"/.exec(serialized)?.[1] ?? 'DECLARED_READ_FAILED';
      throw new Error(String(message));
    }
    const readerOutcome = read?.outcome ?? read;
    // The read's shape follows the operation: rows for a listing, the one meaning
    // document for reveal, or the retained catalogue, view or artifact.
    return { disposition: 'terminated',
      outcome: { ...(request.subject === undefined ? {} : { capabilityId: request.subject }),
        ...(selection.namespaceId === undefined ? {} : { namespaceId: selection.namespaceId }),
        ...(selectedScenarioId === undefined ? {} : { scenarioId: selectedScenarioId }),
        ...(request.query === undefined ? {} : { query: request.query }),
        ...(request.verb === 'reveal' ? { view } : {}),
        ...(Array.isArray(readerOutcome)
          ? { count: readerOutcome.length, capabilities: readerOutcome }
          : request.verb === 'artifact' ? { media: readerOutcome }
            : retained ? { circuit: readerOutcome }
              : { meaning: readerOutcome }),
        evidence: { timings, authoritySource: 'DATABASE', snapshotId: reader.authority.snapshotId,
          projectionDigest: reader.authority.projectionDigest, viewDefinitionDigest: reader.authority.viewDefinitionDigest } } };
  }
  // The reader operations (prepare/list/find/reveal/catalogue/circuit/artifact)
  // are declared capabilities reached through the frontdoor; this loader only
  // reads the selected declaration and hands it to the kernel.
  // Invocation resolves the selected declaration and its execution delivery.
  // Observation runs the same execution and streams the same telemetry.
  // Preparation is an optional, separately invoked retained proof and is never consumed here.
  const bundle = await measure('readAuthority', () => readSelectedAuthority(databaseRoot, selection, { retainObjects: false, documents: false, timings: timings.queries }));
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
    if (!bundle.graphSource) throw new Error('DECLARED_GRAPH_SOURCE_MISSING:' + selection.capabilityId);
    graphSource = structuredClone(bundle.graphSource);
    graphSource.input = input;
  }
  // The display projection is declared on the capability's CLI interface, which
  // travels with the graph source's interface authority. The bundle may not carry
  // it now that the boot read uses the estate views.
  const display = graphSource?.interfaceAuthority?.interfaces?.find(entry => entry.kind === 'cli')?.configuration?.display
    ?? cli.display ?? null;
  // Observation carries the drilldown; every invocation captures the compiled
  // plan from the running carrier so the declared display projection can join
  // planned topology against testimony. The plan is read from the same onState
  // seam the drilldown uses; nothing is re-compiled or guessed. Invocation keeps
  // no other drilldown behavior.
  let plan = null;
  const capturePlan = value => { if (plan === null && object(value) && object(value.canonicalGraph)) plan = value; };
  let drilldown;
  if (request.verb === 'observe') {
    drilldown = createExecutionDrilldown({ observationAltitudes: request.observationAltitudes, scenarioId: selected.scenario_id,
      observe, authority: graphSource });
    config.onTestimony = drilldown.sink;
    config.onState = value => { capturePlan(value); drilldown.setPlan(value); };
  } else {
    config.onState = capturePlan;
  }
  const outcome = await measure('executeDeclaredGraph', () => executeEstateCapability({ capabilityId: 'run-declared-graph' }, graphSource, config));
  if (drilldown) drilldown.absorb(outcome);
  // The declared display projection. The interface names the transformation and
  // the declared expression builds the display document from the carrier,
  // declared authority and testimony. Observation asks for the display;
  // invocation asks with --display. The reading is the scope field the declared
  // CLI configuration selects from the requested altitudes; the terminal only
  // forwards them.
  let displayProjection = null;
  if (display?.transformationId && (request.verb === 'observe' || request.display === true)) {
    const transformation = (graphSource.semanticTransformations ?? []).find(entry => entry?.id === display.transformationId);
    if (transformation) {
      const evaluateExpression = await loadExpressionEvaluator(sdaRoot);
      const reading = deriveReading(cli.readings, request.observationAltitudes);
      displayProjection = { document: evaluateExpression(transformation.expression, {
        selection, selected, scenarioInput: input, rootExecutionId, authority: graphSource,
        plan, execution: outcome, reading }), as: display.as ?? 'json' };
    }
  }
  const observedPathDigest = drilldown && typeof outcome?.observedPathDigest === 'string' ? outcome.observedPathDigest : undefined;
  return { disposition: 'terminated',
    outcome: { capabilityId: selection.capabilityId, scenarioId: selected.scenario_id, result: outcome, executions: [], observations: [],
      ...(displayProjection ? { display: displayProjection } : display ? { display } : {}),
      ...(drilldown ? { overlay: drilldown.buildOverlay(outcome), story: drilldown.buildStory(outcome) } : {}),
      ...(observedPathDigest !== undefined ? { observedPathDigest } : {}),
      evidence: { timings, authoritySource: 'DATABASE', bodyStorage: 'NOT_REQUESTED', managedAdmission: 'NOT_REQUESTED',
        snapshotId: bundle.authority.snapshotId, projectionDigest: bundle.authority.projectionDigest,
        viewDefinitionDigest: bundle.authority.viewDefinitionDigest,
        ...(observedPathDigest !== undefined ? { observedPathDigest } : {}) } } };
}
