import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { readCapabilityAuthority } from './authority-read-provider.mjs';
import { readConsumerEmbodimentPlan } from './consumer-plan-provider.mjs';
import { executeEstateCapability } from '../../invoke-database-capability.mjs';

const hash = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');

export async function writeConsumerEmbodiment(configuration, input, context) {
  const declaration = await readCapabilityAuthority(configuration.authorityReader, input,
    context.authorityBundle ? { ...context, readAuthority: async () => context.authorityBundle } : context);
  const bindings = await executeEstateCapability(configuration.bindingResolver, declaration, context);
  const plan = await readConsumerEmbodimentPlan(configuration.planner, bindings, context);
  if (plan.result.planDigest !== input.planDigest || plan.result.artifactDigest !== input.artifactDigest)
    throw new Error('EMBODIMENT_WRITE_DIVERGED');
  const outputRoot = path.resolve(configuration.outputRoot ?? context.estateRoot);
  const allowed = path.resolve(outputRoot, configuration.planner.relativeRoot);
  for (const file of plan.files) {
    const destination = path.resolve(outputRoot, file.relativePath);
    const relative = path.relative(allowed, destination);
    if (relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('EMBODIMENT_OUTPUT_ROOT_NOT_DECLARED');
    await fs.mkdir(path.dirname(destination), { recursive: true });
    await fs.writeFile(destination, file.content, 'utf8');
    if (hash(await fs.readFile(destination)) !== file.digest) throw new Error('EMBODIMENT_WRITE_DIGEST_MISMATCH:' + file.relativePath);
  }
  return { contractId: configuration.outcomeContract, capabilityId: input.capabilityId, scenarioId: input.scenarioId,
    target: input.target, outputRoot, planDigest: input.planDigest, artifactDigest: input.artifactDigest,
    fileCount: plan.files.length, written: plan.files.map(({ relativePath, digest }) => ({ relativePath, digest })) };
}
