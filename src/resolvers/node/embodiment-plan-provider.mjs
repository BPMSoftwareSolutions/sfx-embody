// Estate provider: construct the content-addressed embodiment plan from a
// capability's retained authority declaration.
//
// This is the plan step of the long-form embodiment composition. It consumes the
// declaration the read step produced and plans the native body through the same
// materializer the direct invocation path uses. It writes nothing:
// materialization is a separate governed effect.
import { planNode } from '../../materialize-node.mjs';
import Ajv from 'ajv';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export async function planCapabilityEmbodiment(configuration, input, context) {
  if (configuration.inputAdmission && !new Ajv({ strict: false }).validate(configuration.inputAdmission, input))
    return { ...configuration.admissionFailure,
      ...Object.fromEntries((configuration.failureFields ?? []).map(field => [field, input?.[field]])) };
  if (configuration.planningProviders) {
    const selected = configuration.planningProviders.filter(provider => input.profiles?.some(profile => profile.providerProfileId === provider.providerProfileId));
    if (selected.length !== 1) throw new Error('PROJECTION_AUTHORITY_UNREGISTERED:' + selected.length);
    const provider = selected[0];
    const module = await import(pathToFileURL(path.resolve(context.estateRoot, provider.module)).href);
    return module[provider.export](provider.configuration, input, context);
  }
  return planNativeEmbodiment(configuration, input, context);
}

export async function planNativeEmbodiment(configuration, input, context) {
  const { sdaRoot } = context;
  // The port declaration selects the carrier member delivered to the planner.
  // Older declarations deliver the authority directly.
  const carrier = input;
  if (configuration.inputAdmission && !new Ajv({ strict: false }).validate(configuration.inputAdmission, carrier)) {
    return { ...configuration.admissionFailure,
      ...Object.fromEntries((configuration.failureFields ?? []).map(field => [field, carrier?.[field]])) };
  }
  if (configuration.inputField) input = carrier?.[configuration.inputField];
  if (!input || !input.authority || !input.closure || !input.mechanics)
    throw new Error('EMBODIMENT_AUTHORITY_REQUIRED');
  const bundle = {
    selection: { capabilityId: input.capabilityId, target: input.target, scenarioId: input.scenarioId },
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
    target: input.target,
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
