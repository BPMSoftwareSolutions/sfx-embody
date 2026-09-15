// Project a declared capability into executable mechanical bodies.
//
// One pinned database read assembles the capability's declared documents; they
// are staged into the requested workspace; the admitted consumer projector runs
// over the workspace and writes the per-target carriers, generated bodies,
// execution plans, queries, fixtures and conformance evidence under
// <workspace>/projected. A projection is review/publish output: nothing here is
// on the invocation path, and no reader, loader or graph source consults it.
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { withDatabaseReadSession } from './database-read-session.mjs';

const OPERATION = 'project';
const ADMITTED_TARGETS = Object.freeze(['node', 'python', 'csharp']);
const requestFields = ['object', 'verb', 'subject', 'workspace', 'targets', 'fullMechanics'];

const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const present = value => typeof value === 'string' && value.length > 0;

function validate(envelope) {
  if (!object(envelope) || envelope.deliveryType !== 'sfx-command-delivery.v1' || envelope.operation !== OPERATION
    || !Object.keys(envelope).every(key => ['deliveryType', 'operation', 'request'].includes(key))) throw new Error('DELIVERY_PROTOCOL_REJECTED');
  const request = envelope.request;
  if (!object(request) || request.object !== 'capability' || request.verb !== OPERATION
    || !Object.keys(request).every(key => requestFields.includes(key))) throw new Error('PROJECTION_COMMAND_REJECTED');
  if (!present(request.subject)) throw new Error('PROJECTION_CAPABILITY_REQUIRED');
  if (!present(request.workspace)) throw new Error('PROJECTION_WORKSPACE_REQUIRED');
  if (request.targets !== undefined && (!Array.isArray(request.targets) || request.targets.length === 0
    || !request.targets.every(target => ADMITTED_TARGETS.includes(target)))) throw new Error('PROJECTION_TARGETS_REJECTED');
  if (request.fullMechanics !== undefined && request.fullMechanics !== true) throw new Error('PROJECTION_FULL_MECHANICS_REJECTED');
  return request;
}

async function readDocuments(config, capabilityId, readQuery) {
  const read = await readQuery(
    "SELECT CONVERT(nvarchar(max), g.documents) AS documents"
    + " FROM analysis.capability_graph_source(CONVERT(nvarchar(400), JSON_VALUE(@input, '$.capabilityId')), 1, NULL) g",
    { input: { capabilityId } });
  const raw = read.recordsets?.[0]?.[0]?.documents;
  if (typeof raw !== 'string' || !raw.length) throw new Error('PROJECTION_DECLARATION_NOT_FOUND:' + capabilityId);
  const documents = JSON.parse(raw);
  if (!Array.isArray(documents)) throw new Error('PROJECTION_DECLARATION_REJECTED:' + capabilityId);
  return { documents, snapshotId: read.snapshotId, projectionDigest: read.projectionDigest };
}

async function stageWorkspace(workspace, documents) {
  const staged = [];
  for (const entry of documents) {
    if (!object(entry) || !present(entry.entry_id) || typeof entry.document !== 'string') throw new Error('PROJECTION_DECLARATION_REJECTED');
    const file = path.resolve(workspace, entry.entry_id);
    const relative = path.relative(workspace, file);
    if (relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('PROJECTION_ENTRY_PATH_ESCAPED:' + entry.entry_id);
    await fs.mkdir(path.dirname(file), { recursive: true });
    await fs.writeFile(file, entry.document.endsWith('\n') ? entry.document : `${entry.document}\n`, 'utf8');
    staged.push(entry.entry_id);
  }
  return staged;
}

// A canonical cell that carries a provider slot is a mechanic the target must
// embody. Full mechanics means every one of them resolves to a projected binding.
function inspectPlan(target, plan) {
  const bindings = plan?.realizationOverlay?.providerBindings ?? [];
  const boundSlots = new Set(bindings.map(binding => binding.slotId));
  const required = (plan?.canonicalGraph?.cells ?? []).filter(cell => present(cell?.execution?.providerSlotId));
  const unbound = required.filter(cell => !boundSlots.has(cell.execution.providerSlotId));
  return { target, canonicalGraphDigest: plan?.canonicalGraphDigest, realizedGraphDigest: plan?.realizedGraphDigest,
    providerBindings: bindings.length, requiredSlots: required.length, mechanicsComplete: unbound.length === 0,
    unboundSlots: unbound.map(cell => cell.execution.providerSlotId) };
}

async function countFiles(root) {
  let files = 0;
  let bytes = 0;
  const walk = async directory => {
    for (const entry of await fs.readdir(directory, { withFileTypes: true })) {
      const file = path.join(directory, entry.name);
      if (entry.isDirectory()) await walk(file);
      else if (entry.isFile()) { files++; bytes += (await fs.stat(file)).size; }
    }
  };
  await walk(root);
  return { files, bytes };
}

async function project(request, config, readQuery) {
  const workspace = path.resolve(request.workspace);
  const { documents, snapshotId, projectionDigest } = await readDocuments(config, request.subject, readQuery);
  const staged = await stageWorkspace(workspace, documents);
  const outDir = path.join(workspace, 'projected');
  await fs.rm(outDir, { recursive: true, force: true });
  const projectorFile = path.join(config.sdaRoot, 'artifacts/tools/dist/interfaces/consumer-projection/project.js');
  try { await fs.access(projectorFile); } catch { throw new Error('SDA_PROJECTION_TOOLS_NOT_BUILT'); }
  const { projectConsumerCapability } = await import(pathToFileURL(projectorFile).href);
  await projectConsumerCapability(workspace, {
    ...(request.targets === undefined ? {} : { projectionTargets: request.targets }),
    ...(request.fullMechanics === true ? { fullMechanics: true } : {}),
    repositoryRoot: config.sdaRoot });
  const planDir = path.join(outDir, 'execution-plans');
  const planFiles = (await fs.readdir(planDir)).filter(file => file.endsWith('.v3.json')).sort();
  const plans = [];
  for (const file of planFiles) plans.push(inspectPlan(file.replace(/^consumer-execution-plan\.|\.v3\.json$/g, ''),
    JSON.parse(await fs.readFile(path.join(planDir, file), 'utf8'))));
  const conformance = JSON.parse(await fs.readFile(path.join(outDir, 'projection-conformance.json'), 'utf8'));
  const written = await countFiles(outDir);
  return { capabilityId: request.subject, workspace, outDir, targets: plans.map(plan => plan.target),
    documents: staged.length, files: written.files, bytes: written.bytes,
    fullMechanics: request.fullMechanics === true, plans, conformance: conformance.disposition,
    evidence: { snapshotId, projectionDigest } };
}

async function main() {
  const chunks = [];
  let size = 0;
  for await (const chunk of process.stdin) {
    size += chunk.length;
    if (size > 9 * 1024 * 1024) throw new Error('DELIVERY_INPUT_TOO_LARGE');
    chunks.push(chunk);
  }
  const envelope = JSON.parse(Buffer.concat(chunks).toString('utf8'));
  const request = validate(envelope);
  const configFile = path.resolve(process.argv[2]);
  const config = JSON.parse(await fs.readFile(configFile, 'utf8'));
  if (config.configurationType !== 'sfx-database-memory-runtime.v1'
    || typeof config.databaseRoot !== 'string' || typeof config.sdaRoot !== 'string') throw new Error('RUNTIME_CONFIGURATION_REJECTED');
  for (const key of ['databaseRoot', 'sdaRoot']) config[key] = path.resolve(path.dirname(configFile), config[key]);
  const { config: readDatabaseConfig, stable, hash, digest } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/core.mjs')));
  const { connectionString, connect, sql } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/ingest/database.mjs')));
  const { connectionEnvironmentVariable, queryRowLimit } = await readDatabaseConfig();
  process.env[connectionEnvironmentVariable] = connectionString(connectionEnvironmentVariable);
  const { normalizeSql } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/query/run.mjs')));
  const { pinModel } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/query/model-pin.mjs')));
  const outcome = await withDatabaseReadSession({ connect, sql, pinModel, normalizeSql, stable, hash, digest, queryRowLimit },
    readQuery => project(request, config, readQuery));
  process.stdout.write(JSON.stringify({ disposition: 'terminated', outcome }) + '\n');
}

main().catch(error => {
  const message = error.message ?? 'PROJECTION_FAILED';
  const code = /^[A-Z][A-Z0-9_]+(?=:|$)/.exec(message)?.[0] ?? 'PROJECTION_FAILED';
  process.stdout.write(JSON.stringify({ disposition: 'failed', errorCode: code, error: { code, message } }) + '\n');
  process.exitCode = 4;
});
