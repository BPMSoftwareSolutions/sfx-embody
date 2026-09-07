import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
import { readWorkspaceConfig } from '../src/read-workspace-config.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = async relative => JSON.parse((await fs.readFile(path.resolve(root, relative), 'utf8')).replace(/^\uFEFF/, ''));
const hash = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
const config = await readWorkspaceConfig();
const { query } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/query/run.mjs')));
const inventory = await query(`SELECT a.source_class,a.source_path,a.entry_id,
  'sha256:' + LOWER(CONVERT(varchar(64),c.content_digest,2)) AS content_digest
  FROM source.source_appearance a
  JOIN source.content_object c ON c.content_object_pk=a.content_object_pk
  JOIN source.estate_model m ON m.estate_snapshot_pk=a.estate_snapshot_pk
  WHERE m.estate_model_pk=@estate_model_pk
    AND (a.source_path LIKE '%conformance%' OR a.source_path LIKE '%mechanic%')
  ORDER BY a.source_path`, { rowLimit: 100000 });
if (inventory.truncated) throw new Error('CONFORMANCE_INVENTORY_TRUNCATED');
const used = new Map();
const pinnedCommits = [];
for (const entry of config.cases) {
  const bundle = await read(entry.bundleFile);
  for (const record of [...bundle.authority.recordsets[1], ...bundle.authority.recordsets[2]]) {
    if (!record.source_path.endsWith('.json')) continue;
    try { const v = JSON.parse(Buffer.from(record.content_bytes.base64, 'base64').toString('utf8')); if (v.sdaPlatform?.commit) pinnedCommits.push(v.sdaPlatform.commit); } catch { /* not a platform package */ }
  }
  if (bundle.authority.snapshotId !== inventory.snapshotId || bundle.authority.projectionDigest !== inventory.projectionDigest) throw new Error('CONFORMANCE_INVENTORY_AUTHORITY_CHANGED');
  // Mechanic usage is recovered from retained projection lineage; IDs are then
  // resolved against the selected database declarations, without name aliases.
  const regression = await read('evidence/regression-results.json');
  const caseResult = regression.cases.find(c => c.selection.capabilityId === bundle.selection.capabilityId);
  const ids = new Set();
  for (const receipt of caseResult.receipts) {
    const lineage = await read(path.join(path.dirname(receipt.file), 'evidence/mechanic-lineage.json'));
    lineage.forEach(port => port.nodes.forEach(node => ids.add(node.mechanicId)));
  }
  for (const record of bundle.mechanics.recordsets[0]) {
    const declaration = JSON.parse(record.definition_json);
    if (ids.has(declaration.address.id)) used.set(declaration.address.id, declaration);
  }
}
const commit = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: config.sdaRoot, encoding: 'utf8' }).trim();
const pinned = [...new Set(pinnedCommits)];
if (pinned.length !== 1) throw new Error('PINNED_PLATFORM_COMMIT_NOT_SINGULAR:' + pinned.length);
if (commit !== pinned[0]) throw new Error('INSPECTED_PLATFORM_COMMIT_IS_NOT_PINNED:' + commit + ' expected ' + pinned[0]);
const mechanics = [];
for (const [id, declaration] of [...used].sort(([a], [b]) => a.localeCompare(b))) {
  const references = [];
  for (const ref of declaration.semantics.mechanic.conformanceRefs ?? []) {
    const file = path.resolve(config.sdaRoot, ref);
    if (!file.startsWith(path.resolve(config.sdaRoot) + path.sep)) throw new Error('CONFORMANCE_REFERENCE_OUTSIDE_PLATFORM');
    const bytes = await fs.readFile(file).catch(error => { if (error.code !== 'ENOENT') throw error; return null; });
    const retainedMatches = inventory.recordsets[0].filter(r => r.source_path === ref);
    references.push({ reference: ref, exactRetainedEntries: retainedMatches, physicalFile: bytes ? { path: file, digest: hash(bytes) } : null,
      disposition: bytes || retainedMatches.length ? 'REFERENCE_FOUND_REQUIRES_VECTOR_BINDING' : 'REFERENCE_NOT_RESOLVED' });
  }
  mechanics.push({ mechanicId: id, meaning: declaration.semantics.mechanic.meaning,
    definitionDigest: hash(JSON.stringify(declaration)), references,
    meaningPresent: true, findingClass: 'EVIDENCE_REFERENCE_NOT_RESOLVED', admittedEvidence: 'NOT_ESTABLISHED_BY_THESE_REFERENCES',
    candidateLoweringEvidence: 'See evidence/native-projection.json beside each current Scenario body; this reference inventory does not invalidate the declared meaning or replace those tests.',
    reason: references.some(r => r.disposition === 'REFERENCE_NOT_RESOLVED') ? 'Declared conformance reference not resolved to retained evidence or an exact platform file.' : 'Found references still require exact vector and lowering evidence.' });
}
const report = { snapshotId: inventory.snapshotId, projectionDigest: inventory.projectionDigest, inspectedPlatformCommit: commit,
  inventory, mechanics, scope: 'Exact declared references only. Related tests are not substituted for unresolved references.',
  disposition: mechanics.some(m => m.references.some(r => r.disposition === 'REFERENCE_NOT_RESOLVED')) || !mechanics.length
    ? 'DECLARED_CONFORMANCE_REFERENCES_NOT_CLOSED' : 'DECLARED_CONFORMANCE_REFERENCES_RESOLVED_REQUIRING_VECTOR_BINDING' };
await fs.mkdir(path.join(root, 'evidence/review'), { recursive: true });
await fs.writeFile(path.join(root, 'evidence/review/lowering-evidence-readiness.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ mechanics: mechanics.length, unresolvedReferences: mechanics.flatMap(m => m.references).filter(r => r.disposition === 'REFERENCE_NOT_RESOLVED').length, disposition: report.disposition }));
