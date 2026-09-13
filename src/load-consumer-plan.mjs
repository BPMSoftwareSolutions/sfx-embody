import path from 'node:path';
import { createHash } from 'node:crypto';

const digest = bytes => 'sha256:' + createHash('sha256').update(bytes).digest('hex');

// A declaration supplies the manifest and binding path. The same reader checks
// in-memory bytes or materialized bytes before returning the executable plan.
export async function loadConsumerPlan(manifest, bindingPath, read) {
  const files = new Map();
  for (const file of manifest.files) {
    if (files.has(file.relativePath) || path.posix.isAbsolute(file.relativePath) || path.win32.isAbsolute(file.relativePath)
      || file.relativePath.includes('\\')
      || file.relativePath.split('/').includes('..')) throw new Error('EMBODIMENT_FILE_LAYOUT_NOT_DECLARED');
    const bytes = await read(file.relativePath);
    if (digest(bytes) !== file.digest) throw new Error('EMBODIMENT_WRITE_DIGEST_MISMATCH:' + file.relativePath);
    files.set(file.relativePath, bytes);
  }
  const document = file => {
    if (!files.has(file)) throw new Error('EMBODIMENT_FILE_NOT_DECLARED:' + file);
    return JSON.parse(files.get(file).toString('utf8'));
  };
  const binding = document(bindingPath);
  const reference = relative => {
    if (typeof relative !== 'string' || path.posix.isAbsolute(relative) || path.win32.isAbsolute(relative)
      || relative.includes('\\')) throw new Error('EMBODIMENT_FILE_LAYOUT_NOT_DECLARED');
    return path.posix.normalize(path.posix.join(path.posix.dirname(bindingPath), relative));
  };
  const planPath = reference(binding.executionPlan);
  const plan = document(planPath);
  if (digest(files.get(planPath)) !== binding.executionPlanDigest) throw new Error('PROVIDER_BINDING_DIVERGENCE');
  return { plan, executionAuthority: binding.executionAuthority, providerBindings: binding.providerBindings,
    fixtureAuthority: document(reference(binding.fixtures)), conformance: document(reference(binding.mechanicalSterility)) };
}
