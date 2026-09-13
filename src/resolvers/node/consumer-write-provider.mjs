import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { readCapabilityAuthority } from './authority-read-provider.mjs';
import { readConsumerEmbodimentPlan } from './consumer-plan-provider.mjs';
import { executeEstateCapability } from '../../invoke-database-capability.mjs';

const hash = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
const beneath = (root, relative) => {
  if (typeof relative !== 'string' || path.isAbsolute(relative) || path.win32.isAbsolute(relative))
    throw new Error('EMBODIMENT_OUTPUT_ROOT_NOT_DECLARED');
  const target = path.resolve(root, relative), fromRoot = path.relative(root, target);
  if (!fromRoot || fromRoot === '..' || fromRoot.startsWith('..' + path.sep) || path.isAbsolute(fromRoot))
    throw new Error('EMBODIMENT_OUTPUT_ROOT_NOT_DECLARED');
  return target;
};
const readIfPresent = file => fs.readFile(file).catch(error => { if (error.code !== 'ENOENT') throw error; return null; });
const requireResolvedWithin = async (root, file) => {
  const relative = path.relative(root, await fs.realpath(file));
  if (!relative || relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative))
    throw new Error('PREVIOUS_PLAN_PATH_OUTSIDE_BODY');
};

// The selected writer declares where its previous plan, receipt and body lived.
// Only files still matching that plan may be retired; unlisted files are kept.
export async function readPreviousEmbodimentFiles(configuration, input, outputRoot, currentFiles) {
  if (!configuration.previousPlanFile) return [];
  const base = beneath(outputRoot, path.join(configuration.planner.relativeRoot, input.capabilityId,
    'scenarios', input.scenarioId, input.target));
  const planFile = beneath(base, configuration.previousPlanFile);
  const bytes = await readIfPresent(planFile);
  if (!bytes) return [];
  const realOutputRoot = await fs.realpath(outputRoot);
  const realBase = path.resolve(realOutputRoot, path.relative(outputRoot, base));
  await requireResolvedWithin(realBase, planFile);
  const previous = JSON.parse(bytes);
  for (const key of ['capabilityId', 'scenarioId', 'target'])
    if (previous[key] !== input[key]) throw new Error('PREVIOUS_PLAN_IDENTITY_DIVERGED');
  if (!Array.isArray(previous.files)) throw new Error('PREVIOUS_PLAN_FILES_NOT_DECLARED');
  const bodyRoot = beneath(base, configuration.previousBodyRoot), stale = [], seen = new Set();
  const realBodyRoot = path.resolve(realOutputRoot, path.relative(outputRoot, bodyRoot));
  for (const file of previous.files) {
    const target = beneath(outputRoot, file.relativePath), relative = path.relative(bodyRoot, target);
    if (!relative || relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative))
      throw new Error('PREVIOUS_PLAN_PATH_OUTSIDE_BODY');
    const key = process.platform === 'win32' ? target.toLowerCase() : target;
    if (seen.has(key)) throw new Error('PREVIOUS_PLAN_FILE_DUPLICATED');
    seen.add(key);
    const content = await readIfPresent(target);
    if (content) await requireResolvedWithin(realBodyRoot, target);
    if (content && hash(content) !== file.digest) throw new Error('GENERATED_BODY_MODIFIED:' + file.relativePath);
    if (content && !currentFiles.some(current => path.resolve(outputRoot, current.relativePath) === target))
      stale.push({ path: target, digest: file.digest, root: realBodyRoot });
  }
  if (configuration.previousReceiptFile) {
    const receiptFile = beneath(base, configuration.previousReceiptFile), receiptBytes = await readIfPresent(receiptFile);
    if (receiptBytes) {
      await requireResolvedWithin(realBase, receiptFile);
      const receipt = JSON.parse(receiptBytes);
      if (receipt.embodimentPlanDigest !== hash(bytes)
        || receipt.artifactDigest !== hash(JSON.stringify(previous.files, null, 2) + '\n')
        || ['capabilityId', 'scenarioId', 'target'].some(key => receipt[key] !== input[key]))
        throw new Error('PREVIOUS_RECEIPT_DIVERGED');
      stale.push({ path: receiptFile, digest: hash(receiptBytes), root: realBase });
    }
  }
  stale.push({ path: planFile, digest: hash(bytes), root: realBase });
  return stale;
}

export async function removePreviousEmbodimentFiles(files) {
  for (const file of files) {
    const bytes = await readIfPresent(file.path);
    if (!bytes) continue;
    await requireResolvedWithin(file.root, file.path);
    if (hash(bytes) !== file.digest) throw new Error('GENERATED_BODY_MODIFIED:' + file.path);
    await fs.unlink(file.path);
  }
}

export async function writeConsumerEmbodiment(configuration, input, context) {
  const declaration = await readCapabilityAuthority(configuration.authorityReader, input,
    context.authorityBundle ? { ...context, readAuthority: async () => context.authorityBundle } : context);
  const bindings = await executeEstateCapability(configuration.bindingResolver, declaration, context);
  const plan = await readConsumerEmbodimentPlan(configuration.planner, bindings, context);
  if (plan.result.planDigest !== input.planDigest || plan.result.artifactDigest !== input.artifactDigest)
    throw new Error('EMBODIMENT_WRITE_DIVERGED');
  const outputRoot = path.resolve(configuration.outputRoot ?? context.outputRoot ?? context.estateRoot);
  const allowed = path.resolve(outputRoot, configuration.planner.relativeRoot);
  const stale = await readPreviousEmbodimentFiles(configuration, input, outputRoot, plan.files);
  for (const file of plan.files) {
    const destination = path.resolve(outputRoot, file.relativePath);
    const relative = path.relative(allowed, destination);
    if (relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('EMBODIMENT_OUTPUT_ROOT_NOT_DECLARED');
    await fs.mkdir(path.dirname(destination), { recursive: true });
    await fs.writeFile(destination, file.content, 'utf8');
    if (hash(await fs.readFile(destination)) !== file.digest) throw new Error('EMBODIMENT_WRITE_DIGEST_MISMATCH:' + file.relativePath);
  }
  await removePreviousEmbodimentFiles(stale);
  return { contractId: configuration.outcomeContract, capabilityId: input.capabilityId, scenarioId: input.scenarioId,
    target: input.target, outputRoot, planDigest: input.planDigest, artifactDigest: input.artifactDigest,
    fileCount: plan.files.length, written: plan.files.map(({ relativePath, digest }) => ({ relativePath, digest })) };
}
