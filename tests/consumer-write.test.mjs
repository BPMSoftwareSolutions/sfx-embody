import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { readPreviousEmbodimentFiles, removePreviousEmbodimentFiles } from '../src/resolvers/node/consumer-write-provider.mjs';

const pretty = value => JSON.stringify(value, null, 2) + '\n';
const hash = value => 'sha256:' + createHash('sha256').update(value).digest('hex');
async function fixture(t) {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'consumer-write-'));
  t.after(() => {
    assert.equal(path.dirname(path.resolve(root)), path.resolve(os.tmpdir()));
    assert.ok(path.basename(root).startsWith('consumer-write-'));
    return fs.rm(root, { recursive: true, force: true });
  });
  const input = { capabilityId: 'example', scenarioId: 'root', target: 'selected' };
  const base = 'embodiments/example/scenarios/root/selected';
  const generated = base + '/body/generated.mjs', kept = base + '/body/user.txt';
  await fs.mkdir(path.join(root, base, 'body'), { recursive: true });
  await fs.mkdir(path.join(root, base, 'evidence'));
  await fs.writeFile(path.join(root, generated), 'generated\n');
  await fs.writeFile(path.join(root, kept), 'user content\n');
  const manifest = { ...input, files: [{ relativePath: generated, digest: hash('generated\n') }] };
  await fs.writeFile(path.join(root, base, 'evidence/plan.json'), pretty(manifest));
  await fs.writeFile(path.join(root, base, 'receipt.json'), pretty({ ...input,
    embodimentPlanDigest: hash(pretty(manifest)), artifactDigest: hash(pretty(manifest.files)) }));
  return { root, input, base, generated, kept, manifest, configuration: { planner: { relativeRoot: 'embodiments' },
    previousPlanFile: 'evidence/plan.json', previousReceiptFile: 'receipt.json', previousBodyRoot: 'body' } };
}

test('retirement removes only unchanged files listed by the previous plan', async t => {
  const f = await fixture(t);
  const files = await readPreviousEmbodimentFiles(f.configuration, f.input, f.root, []);
  assert.equal(files.length, 3);
  await removePreviousEmbodimentFiles(files);
  assert.equal(await fs.readFile(path.join(f.root, f.kept), 'utf8'), 'user content\n');
  for (const file of files) await assert.rejects(fs.stat(file.path), { code: 'ENOENT' });
  assert.deepEqual(await readPreviousEmbodimentFiles(f.configuration, f.input, f.root, []), []);
});

test('retirement refuses edited files, including edits after inspection', async t => {
  const f = await fixture(t);
  const files = await readPreviousEmbodimentFiles(f.configuration, f.input, f.root, []);
  await fs.writeFile(path.join(f.root, f.generated), 'edited\n');
  await assert.rejects(readPreviousEmbodimentFiles(f.configuration, f.input, f.root, []), /GENERATED_BODY_MODIFIED/);
  await assert.rejects(removePreviousEmbodimentFiles(files), /GENERATED_BODY_MODIFIED/);
  assert.equal(await fs.readFile(path.join(f.root, f.generated), 'utf8'), 'edited\n');
});

test('a previous plan cannot name a file outside its declared body', async t => {
  const f = await fixture(t);
  f.manifest.files[0].relativePath = f.base + '/evidence/other.txt';
  await fs.writeFile(path.join(f.root, f.base, 'evidence/plan.json'), pretty(f.manifest));
  await assert.rejects(readPreviousEmbodimentFiles(f.configuration, f.input, f.root, []), /PREVIOUS_PLAN_PATH_OUTSIDE_BODY/);
  assert.equal(await fs.readFile(path.join(f.root, f.generated), 'utf8'), 'generated\n');
});

test('retirement refuses a directory link that leads outside the body', async t => {
  const f = await fixture(t);
  const outside = path.join(f.root, 'outside');
  await fs.mkdir(outside);
  await fs.writeFile(path.join(outside, 'generated.mjs'), 'generated\n');
  await fs.symlink(outside, path.join(f.root, f.base, 'body/linked'), process.platform === 'win32' ? 'junction' : 'dir');
  f.manifest.files[0].relativePath = f.base + '/body/linked/generated.mjs';
  await fs.writeFile(path.join(f.root, f.base, 'evidence/plan.json'), pretty(f.manifest));
  await assert.rejects(readPreviousEmbodimentFiles(f.configuration, f.input, f.root, []), /PREVIOUS_PLAN_PATH_OUTSIDE_BODY/);
  assert.equal(await fs.readFile(path.join(outside, 'generated.mjs'), 'utf8'), 'generated\n');
});
