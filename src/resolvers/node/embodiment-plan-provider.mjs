// Estate provider: construct the content-addressed embodiment plan from a
// capability's retained authority declaration.
//
// This is the plan step of the long-form embodiment composition. It consumes the
// declaration the read step produced and plans the native body through the same
// materializer the direct invocation path uses. It writes nothing:
// materialization is a separate governed effect.
import { planNode } from '../../materialize-node.mjs';

export async function planCapabilityEmbodiment(configuration, input, context) {
  const { sdaRoot } = context;
  if (!input || !input.authority || !input.closure || !input.mechanics)
    throw new Error('EMBODIMENT_AUTHORITY_REQUIRED');
  const bundle = {
    selection: { capabilityId: input.capabilityId, target: input.target ?? 'node', scenarioId: input.scenarioId },
    authority: input.authority,
    closure: input.closure,
    resolutions: null,
    mechanics: input.mechanics
  };
  const plan = await planNode({ bundle, sdaRoot });
  const entry = plan.receipts.find(receipt => receipt.plan.scenarioId === plan.selectedScenarioId);
  if (!entry) throw new Error('EMBODIMENT_SELECTED_SCENARIO_NOT_PLANNED:' + plan.selectedScenarioId);
  return {
    contractId: 'capability-embodiment-plan.v1',
    capabilityId: plan.capabilityId,
    scenarioId: plan.selectedScenarioId,
    target: input.target ?? 'node',
    planDigest: entry.receipt.embodimentPlanDigest,
    artifactDigest: entry.receipt.artifactDigest,
    scenarioDefinitionDigest: entry.receipt.scenarioDefinitionDigest,
    platformDigest: entry.receipt.platformDigest,
    resolverVersion: entry.receipt.resolverVersion,
    fileCount: entry.plan.files.length,
    files: entry.plan.files.map(file => ({
      relativePath: file.relativePath,
      digest: file.digest,
      sourcePointers: file.sourcePointers
    }))
  };
}
