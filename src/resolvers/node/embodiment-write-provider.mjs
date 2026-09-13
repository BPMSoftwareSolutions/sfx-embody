// Estate provider: write a capability's embodiment plan to an authorized root.
//
// This is the write step of the embody loop. The plan authorizes the crossing —
// its digests bind the scenario definition, the platform surface, the resolver
// and the planned files — and the writer must reproduce exactly that plan: it
// re-plans from the same authority, writes, and refuses if the written artifact
// diverges from the plan. It writes only beneath the declared output root.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { readAuthority } from '../../read-authority.mjs';
import { planNode, writeNodePlan } from '../../materialize-node.mjs';
import { pathToFileURL } from 'node:url';
import Ajv from 'ajv';

const hash = bytes => 'sha256:' + crypto.createHash('sha256').update(bytes).digest('hex');

export async function writeCapabilityEmbodiment(configuration, input, context) {
  if (configuration.inputAdmission && !new Ajv({ strict: false }).validate(configuration.inputAdmission, input)) {
    const { evaluateExpression } = await import(pathToFileURL(path.join(context.sdaRoot,
      'languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs')).href);
    return evaluateExpression(configuration.admissionFailureExpression, { input, root: input });
  }
  if (configuration.writingProviders) {
    const bundle = await (context.readAuthority ?? readAuthority)(context.databaseRoot,
      { capabilityId: input.capabilityId, scenarioId: input.scenarioId, target: input.target }, { retainObjects: false });
    const selected = configuration.writingProviders.filter(provider => bundle.authority.recordsets[3]
      .some(profile => profile.provider_profile_id === provider.providerProfileId && profile.target_id === input.target));
    if (selected.length !== 1) throw new Error('PROJECTION_AUTHORITY_UNREGISTERED:' + selected.length);
    const provider = selected[0];
    const module = await import(pathToFileURL(path.resolve(context.estateRoot, provider.module)).href);
    return module[provider.export](provider.configuration, input, { ...context, authorityBundle: bundle });
  }
  return writeNativeEmbodiment(configuration, input, context);
}

export async function writeNativeEmbodiment(configuration, input, context) {
  if (!input || typeof input.capabilityId !== 'string' || !Array.isArray(input.files) || typeof input.planDigest !== 'string')
    throw new Error('EMBODIMENT_PLAN_REQUIRED');
  const outputRoot = configuration?.outputRoot ?? context.estateRoot;
  if (typeof outputRoot !== 'string' || outputRoot.length === 0) throw new Error('EMBODIMENT_OUTPUT_ROOT_NOT_DECLARED');
  const target = input.target ?? configuration.defaultTarget;
  const selection = { capabilityId: input.capabilityId, target,
    ...(typeof input.scenarioId === 'string' && input.scenarioId.length > 0 ? { scenarioId: input.scenarioId } : {}) };
  const bundle = context.authorityBundle ?? await (context.readAuthority ?? readAuthority)(context.databaseRoot, selection, { retainObjects: false });
  const plan = await planNode({ bundle, sdaRoot: context.sdaRoot });
  const entry = plan.receipts.find(receipt => receipt.plan.scenarioId === plan.selectedScenarioId);
  if (!entry) throw new Error('EMBODIMENT_SELECTED_SCENARIO_NOT_PLANNED:' + plan.selectedScenarioId);

  const divergences = [];
  if (entry.receipt.embodimentPlanDigest !== input.planDigest) divergences.push('planDigest');
  if (entry.receipt.artifactDigest !== input.artifactDigest) divergences.push('artifactDigest');
  if (divergences.length) throw new Error('EMBODIMENT_WRITE_DIVERGED:' + divergences.join(','));

  await writeNodePlan({ plan, outputRoot });
  const mismatches = [];
  for (const file of entry.plan.files) {
    const bytes = await fs.readFile(path.join(outputRoot, file.relativePath));
    if (hash(bytes) !== file.digest) mismatches.push(file.relativePath);
  }
  if (mismatches.length) throw new Error('EMBODIMENT_WRITE_DIGEST_MISMATCH:' + mismatches.join(','));

  return {
    contractId: 'capability-embodiment-materialization.v1',
    capabilityId: input.capabilityId,
    scenarioId: plan.selectedScenarioId,
    target,
    outputRoot,
    planDigest: input.planDigest,
    artifactDigest: input.artifactDigest,
    fileCount: entry.plan.files.length,
    written: entry.plan.files.map(file => ({ relativePath: file.relativePath, digest: file.digest }))
  };
}
