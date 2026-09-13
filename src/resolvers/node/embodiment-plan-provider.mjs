// Estate provider: construct the content-addressed embodiment plan for a
// capability identity.
//
// This is the runtime half of the `construct-embodiment-plan` capability. The
// capability's Port binding configuration names this module and export, so the
// delivery resolves the provider from the declaration rather than from a
// hard-coded capability identity. It reads the selected capability's retained
// authority, plans the native body through the same materializer the direct
// invocation path uses, and returns the reviewable, digest-bound plan. It does
// not write any file: materialization is a separate governed effect.
import { readAuthority } from '../../read-authority.mjs';
import { planNode } from '../../materialize-node.mjs';

export async function planCapabilityEmbodiment(configuration, input, context) {
  const { databaseRoot, sdaRoot } = context;
  if (!input || typeof input.capabilityId !== 'string' || input.capabilityId.length === 0)
    throw new Error('EMBODIMENT_CAPABILITY_ID_REQUIRED');
  const target = input.target ?? 'node';
  if (target !== 'node') throw new Error('EMBODIMENT_TARGET_NOT_OFFERED:' + target);
  const selection = { capabilityId: input.capabilityId, target,
    ...(typeof input.scenarioId === 'string' && input.scenarioId.length > 0 ? { scenarioId: input.scenarioId } : {}) };
  const bundle = await readAuthority(databaseRoot, selection, { retainObjects: false });
  const plan = await planNode({ bundle, sdaRoot });
  const entry = plan.receipts.find(receipt => receipt.plan.scenarioId === plan.selectedScenarioId);
  if (!entry) throw new Error('EMBODIMENT_SELECTED_SCENARIO_NOT_PLANNED:' + plan.selectedScenarioId);
  return {
    contractId: 'capability-embodiment-plan.v1',
    capabilityId: plan.capabilityId,
    scenarioId: plan.selectedScenarioId,
    target,
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
