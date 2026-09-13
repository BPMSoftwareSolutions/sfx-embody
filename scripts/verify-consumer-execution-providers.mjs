import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import { readExecutionGraph } from '../src/read-execution-graph.mjs';
import { executeConsumerPlan } from '../src/resolvers/node/consumer-execution-provider.mjs';

export async function verifyConsumerExecutionProviders(bindingSet, test, context) {
  assert.equal(bindingSet.disposition, 'PROVIDER_SLOTS_BOUND');
  const declaration = bindingSet.authorityDeclaration;
  const read = await readExecutionGraph(declaration, context.sdaRoot);
  const statement = await fs.readFile(new URL('../sql/inspect/consumer-execution-providers.sql', import.meta.url), 'utf8');
  const { recordsets } = await context.readQuery(statement, { input: declaration });
  const [profiles, runtimes, bindings] = recordsets;
  assert.equal(runtimes.length, 1, 'One native execution boundary');
  const executionAuthority = JSON.parse(runtimes[0].execution_authority);
  const graph = read.compiled.graph;
  const pure = profiles.filter(x => x.effect_classification === 'pure');
  const effect = profiles.filter(x => x.effect_classification === 'effect');
  assert.equal(pure.length, 1);
  assert.equal(effect.length, 1);
  const selections = [], physical = [], pureMechanics = [];
  for (const slot of graph.requiredProviderSlots) {
    const cell = graph.cells.find(x => x.cellId === slot.cellId);
    const port = cell.execution.configuration?.binding;
    if (!port) { pureMechanics.push(slot.mechanicId); continue; }
    const selected = bindings.filter(x => x.port_id === port.portId);
    assert.equal(selected.length, 1, slot.slotId);
    const binding = selected[0];
    assert.equal(binding.disposition, 'PROVIDER_SLOTS_BOUND');
    if (!selections.some(x => x.mechanicIds.includes(slot.mechanicId))) selections.push({ targetId: declaration.target,
      profileId: effect[0].provider_profile_id, profileDigest: effect[0].profile_definition_digest,
      implementationRef: binding.implementation_ref, mechanicIds: [slot.mechanicId] });
    if (binding.host_provider) physical.push({ cellId: cell.cellId, providerId: binding.provider_id,
      implementationRef: binding.host_implementation_ref, implementationDigest: binding.host_implementation_digest,
      providerExport: binding.host_provider_export });
  }
  selections.push({ targetId: declaration.target, profileId: pure[0].provider_profile_id,
    profileDigest: pure[0].profile_definition_digest, implementationRef: pure[0].provider_module_root + '/' + pure[0].provider_module,
    mechanicIds: [...new Set(pureMechanics)] });
  const root = path.join(context.sdaRoot, 'languages/typescript/runtimes/node/semantic-execution-graph');
  const { resolveRealizationOverlay } = await import(pathToFileURL(path.join(root, 'overlay-resolver.js')).href);
  const { createPlanV3 } = await import(pathToFileURL(path.join(root, 'plan-v3.js')).href);
  const plan = createPlanV3(graph, resolveRealizationOverlay(graph, declaration.target, selections), read.compiled.sourceMap, read.contractCatalog);
  const run = async overrides => executeConsumerPlan({}, { plan, executionAuthority, scenarioInput: test.scenarioInput,
    providerBindings: physical }, { ...context, estateRoot: path.resolve('.'), effectContextOverrides: overrides });
  const unavailable = await run({ credentialReader: () => undefined });
  assert.equal(unavailable.result.disposition, 'completed');
  assert.equal(unavailable.result.outcome.disposition, test.unavailableDisposition);
  const observed = await run();
  assert.equal(observed.result.disposition, 'completed');
  assert.equal(observed.result.outcome.disposition, test.completedDisposition);
  if (test.evidenceFile) await fs.writeFile(test.evidenceFile, JSON.stringify({ unavailable, observed }, null, 2) + '\n');
  return { target: declaration.target, providerSourceDigest: observed.providerSourceDigest,
    unavailableDisposition: unavailable.result.outcome.disposition, completedDisposition: observed.result.outcome.disposition };
}
