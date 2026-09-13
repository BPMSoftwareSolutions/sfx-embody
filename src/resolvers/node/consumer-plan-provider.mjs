import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { readExecutionGraph } from '../../read-execution-graph.mjs';

const hash = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
const pretty = value => JSON.stringify(value, null, 2) + '\n';
const one = (values, code) => {
  if (values.length !== 1) throw new Error(code + ':' + values.length);
  return values[0];
};
const segment = value => {
  if (typeof value !== 'string' || !/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(value)) throw new Error('EMBODIMENT_IDENTITY_REJECTED');
  return value;
};

// The compiler reads meaning. These rows supply the implementations and the
// file layout. No native-language syntax is inspected or generated here.
export async function readConsumerEmbodimentPlan(configuration, bindingSet, context) {
  if (bindingSet.disposition !== 'PROVIDER_SLOTS_BOUND') throw new Error('PROVIDER_SLOT_UNBOUND');
  const declaration = bindingSet.authorityDeclaration;
  const read = await readExecutionGraph(declaration, context.sdaRoot);
  const query = context.readQuery ?? (await import(pathToFileURL(path.join(context.databaseRoot, 'src/query/run.mjs')).href)).query;
  const records = await query(configuration.statement, { input: declaration, rowLimit: configuration.rowLimit, retainObjects: false });
  if (records.truncated || records.snapshotId !== declaration.snapshotId || records.projectionDigest !== declaration.projectionDigest
      || records.viewDefinitionDigest !== declaration.viewDefinitionDigest) throw new Error('DATABASE_AUTHORITY_NOT_COHERENT');
  const [profiles, runtimes, bindings, mechanics] = records.recordsets;
  const executionAuthority = JSON.parse(one(runtimes, 'PROJECTION_AUTHORITY_UNREGISTERED').execution_authority);
  const pure = one(profiles.filter(profile => profile.effect_classification === 'pure'), 'PROFILE_PROVIDER_ABSENT');
  const effect = one(profiles.filter(profile => profile.effect_classification === 'effect'), 'PROFILE_PROVIDER_ABSENT');
  const graph = read.compiled.graph;
  const cells = new Map(graph.cells.map(cell => [cell.cellId, cell]));
  const selections = [], physical = [], pureMechanics = new Map();
  const implementationByMechanic = new Map();
  for (const slot of graph.requiredProviderSlots) {
    const cell = cells.get(slot.cellId);
    const port = cell.execution.configuration?.binding;
    if (!port) {
      const mechanic = one(mechanics.filter(mechanic => mechanic.mechanic_id === slot.mechanicId), 'PROVIDER_IMPLEMENTATION_ABSENT:' + slot.mechanicId);
      pureMechanics.set(slot.mechanicId, mechanic.implementation_ref);
      continue;
    }
    const binding = one(bindings.filter(candidate => candidate.port_id === port.portId), 'DECLARED_OPERATION_PROVIDER_UNBOUND:' + slot.slotId);
    if (binding.disposition !== 'PROVIDER_SLOTS_BOUND') throw new Error(binding.disposition + ':' + slot.slotId);
    if (!bindingSet.bindings.some(candidate => candidate.slotId === binding.slot_id && candidate.providerId === binding.provider_id
      && candidate.providerDefinitionDigest === binding.provider_definition_digest)) throw new Error('PROVIDER_BINDING_DIVERGENCE:' + slot.slotId);
    const previous = implementationByMechanic.get(slot.mechanicId);
    if (previous && previous !== binding.implementation_ref) throw new Error('PROVIDER_BINDING_DIVERGENCE:' + slot.slotId);
    if (!previous) {
      implementationByMechanic.set(slot.mechanicId, binding.implementation_ref);
      selections.push({ targetId: declaration.target, profileId: effect.provider_profile_id,
        profileDigest: effect.profile_definition_digest, implementationRef: binding.implementation_ref, mechanicIds: [slot.mechanicId] });
    }
    if (binding.host_provider) physical.push({ cellId: cell.cellId, providerId: binding.provider_id,
      implementationRef: binding.host_implementation_ref, implementationDigest: binding.host_implementation_digest,
      providerExport: binding.host_provider_export });
  }
  for (const [mechanicId, implementationRef] of pureMechanics) selections.push({ targetId: declaration.target,
    profileId: pure.provider_profile_id, profileDigest: pure.profile_definition_digest, implementationRef, mechanicIds: [mechanicId] });
  const moduleRoot = path.join(context.sdaRoot, 'languages/typescript/runtimes/node/semantic-execution-graph');
  const { resolveRealizationOverlay } = await import(pathToFileURL(path.join(moduleRoot, 'overlay-resolver.js')).href);
  const { createPlanV3 } = await import(pathToFileURL(path.join(moduleRoot, 'plan-v3.js')).href);
  const bindingAuthorities = (read.graphInput.interfaceAuthority.projectionBindings ?? []).map(binding => ({ id: binding.bindingId, binding }));
  const plan = createPlanV3(graph, resolveRealizationOverlay(graph, declaration.target, selections), read.compiled.sourceMap, read.contractCatalog, bindingAuthorities);
  const base = [configuration.relativeRoot, segment(declaration.capabilityId), 'scenarios', segment(declaration.scenarioId), segment(declaration.target)].join('/');
  const fromBinding = file => path.posix.relative(path.posix.dirname(configuration.files.binding), file);
  const documents = { plan, binding: { bindingType: configuration.bindingType, executionPlan: fromBinding(configuration.files.plan),
    fixtures: fromBinding(configuration.files.fixtures), mechanicalSterility: fromBinding(configuration.files.conformance),
    executionPlanDigest: hash(pretty(plan)), executionAuthority, providerBindings: physical },
    fixtures: read.fixtureAuthority, sourceMap: read.compiled.sourceMap,
    conformance: { disposition: configuration.candidateDisposition, canonicalGraphDigest: plan.canonicalGraphDigest,
      realizedGraphDigest: plan.realizedGraphDigest, providerBindings: bindingSet.bindings } };
  const files = Object.entries(configuration.files).map(([key, relative]) => {
    if (!(key in documents) || typeof relative !== 'string' || path.posix.isAbsolute(relative) || relative.split('/').includes('..')) throw new Error('EMBODIMENT_FILE_LAYOUT_NOT_DECLARED');
    const content = pretty(documents[key]);
    return { relativePath: base + '/' + relative, content, digest: hash(content), sourcePointers: read.sources.map(source => source.source_path) };
  }).sort((a, b) => a.relativePath.localeCompare(b.relativePath));
  const resolverVersion = hash(await fs.readFile(new URL(import.meta.url)));
  const result = { contractId: configuration.outcomeContract, capabilityId: declaration.capabilityId, scenarioId: declaration.scenarioId,
    target: declaration.target, planDigest: hash(pretty({ plan, files: files.map(({ content, ...file }) => file), resolverVersion })),
    artifactDigest: hash(pretty(files)), scenarioDefinitionDigest: declaration.authority.recordsets[0][0].scenario_definition_digest,
    platformDigest: hash(pretty({ platform: read.platform, executionAuthority })), resolverVersion, fileCount: files.length,
    files: files.map(({ content, ...file }) => file) };
  return { result, files, plan, executionAuthority, providerBindings: physical, fixtureAuthority: read.fixtureAuthority };
}

export async function planConsumerEmbodiment(configuration, input, context) {
  return (await readConsumerEmbodimentPlan(configuration, input, context)).result;
}
