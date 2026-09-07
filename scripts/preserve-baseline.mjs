import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { readWorkspaceConfig } from '../src/read-workspace-config.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const hash = bytes => 'sha256:' + crypto.createHash('sha256').update(bytes).digest('hex');
const read = async relative => JSON.parse((await fs.readFile(path.join(root, relative), 'utf8')).replace(/^\uFEFF/, ''));
const result = await read('evidence/regression-results.json');
const config = await readWorkspaceConfig();
const destination = path.join(root, 'baselines', result.implementationDigest.slice(7));
const selected = new Set(['evidence/regression-results.json', 'config/regression.cases.json', 'package.json', 'package-lock.json', ...result.components.map(c => c.name)]);
for (const entry of config.cases) {
  selected.add(path.relative(root, entry.selectionFile).replaceAll('\\', '/'));
  selected.add(path.relative(root, entry.bundleFile).replaceAll('\\', '/'));
}
async function collect(relative) {
  for (const entry of await fs.readdir(path.join(root, relative), { withFileTypes: true })) {
    if (entry.name === 'node_modules') continue;
    const child = path.posix.join(relative, entry.name);
    if (entry.isSymbolicLink()) throw new Error('BASELINE_SYMLINK:' + child);
    if (entry.isDirectory()) await collect(child);
    else if (entry.isFile()) selected.add(child);
  }
}
await collect('embodiments');
await collect('docs');
await collect('evidence');
for (const component of result.components) {
  if (hash(await fs.readFile(path.join(root, component.name))) !== component.digest) throw new Error('BASELINE_COMPONENT_CHANGED:' + component.name);
}
const files = [];
for (const relative of [...selected].sort()) {
  const bytes = await fs.readFile(path.join(root, relative));
  const target = path.resolve(destination, relative);
  if (!target.startsWith(destination + path.sep)) throw new Error('BASELINE_PATH_ESCAPE');
  await fs.mkdir(path.dirname(target), { recursive: true });
  try { await fs.writeFile(target, bytes, { flag: 'wx' }); }
  catch (error) { if (error.code !== 'EEXIST') throw error; }
  if (hash(await fs.readFile(target)) !== hash(bytes)) throw new Error('BASELINE_CONTENT_DIVERGENCE:' + relative);
  files.push({ path: relative, digest: hash(bytes) });
}
const manifest = { implementationDigest: result.implementationDigest, snapshotId: result.snapshotId, projectionDigest: result.projectionDigest, files };
await fs.writeFile(path.join(destination, 'baseline.manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
console.log(JSON.stringify({ destination, files: files.length, implementationDigest: result.implementationDigest }));
