// Build the contract data fix for capabilities whose JSON Schema declares an
// array with no `items`, which JsonSchemaTypeGraphBuilder refuses to project.
//
//   node docs/research/scaffold-projection-gap/build-contract-fix.mjs [capabilityId ...]
//
// Default capability: generate-executable-capability-scaffold.
//
// READ-ONLY. This connects with the restricted reader, computes corrected
// bytes, and writes artifacts to evidence/contract-fix/ for inspection.
// It performs NO database write and emits no statement that would run one
// implicitly. The SQL it emits is for review; see "WHAT THIS DOES NOT DO".
//
// The correction: `{"type":"array"}` -> `{"type":"array","items":{}}`.
// Identical to Ajv (an empty schema admits any item), but projectable:
// buildNode requires a non-array object at `items`, then resolves `{}` through
// its existing typeless branch to { kind: "primitive", primitive: "unknown" }.

import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { query } from 'file:///C:/lab/sidefx-database/src/query/run.mjs';

const CAPABILITIES = process.argv.slice(2).length
  ? process.argv.slice(2)
  : ['generate-executable-capability-scaffold'];

const OUT = path.resolve('evidence/contract-fix');
const sha256 = buf => createHash('sha256').update(buf).digest('hex');

// Close every item-less array in place. Returns the JSON pointers touched.
function closeOpenArrays(schema) {
  const touched = [];
  (function walk(node, ptr) {
    if (!node || typeof node !== 'object') return;
    if (Array.isArray(node)) return node.forEach((v, i) => walk(v, `${ptr}/${i}`));
    if (node.type === 'array' && (!node.items || typeof node.items !== 'object' || Array.isArray(node.items))) {
      node.items = {};
      touched.push(ptr);
    }
    for (const [k, v] of Object.entries(node)) walk(v, `${ptr}/${k}`);
  })(schema, '');
  return touched;
}

const rows = (await query(`
DECLARE @snap bigint;
SELECT @snap = estate_snapshot_pk FROM source.estate_model WHERE estate_model_pk = @estate_model_pk;

WITH capsule AS (
  SELECT DISTINCT a.capsule_digest,
         JSON_VALUE(CAST(CONVERT(varchar(max), c.content_bytes) AS nvarchar(max)),'$.capabilityId') AS capability_id
  FROM source.source_appearance a
  JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
  WHERE a.estate_snapshot_pk = @snap AND a.source_class = 'MANAGED_CAPSULE'
    AND a.entry_id = 'capability.authority.json'
)
SELECT DISTINCT k.capability_id, a.entry_id, a.source_path,
       'sha256:' + LOWER(CONVERT(varchar(64), c.content_digest, 2)) AS content_digest,
       c.byte_length, c.content_bytes
FROM source.source_appearance a
JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
JOIN capsule k ON k.capsule_digest = a.capsule_digest
WHERE a.estate_snapshot_pk = @snap AND a.source_class = 'MANAGED_CAPSULE'
  AND a.entry_id LIKE 'contracts/%.schema.json'
ORDER BY k.capability_id, a.entry_id;`,
  { rowLimit: 100000, retainObjects: false })).recordsets[0];

fs.mkdirSync(OUT, { recursive: true });
const report = [];
const statements = [];

for (const row of rows.filter(r => CAPABILITIES.includes(r.capability_id))) {
  const original = Buffer.from(row.content_bytes.base64, 'base64');
  const observedDigest = 'sha256:' + sha256(original);
  if (observedDigest !== row.content_digest) {
    throw new Error(`STORED_DIGEST_MISMATCH:${row.source_path} (${row.content_digest} vs ${observedDigest})`);
  }

  const schema = JSON.parse(original.toString('utf8'));
  const touched = closeOpenArrays(schema);
  if (!touched.length) {
    report.push({ sourcePath: row.source_path, disposition: 'UNCHANGED', openArrays: 0 });
    continue;
  }

  // 2-space indent + trailing newline matches the stored documents' form.
  const corrected = Buffer.from(JSON.stringify(schema, null, 2) + '\n', 'utf8');
  const correctedDigest = 'sha256:' + sha256(corrected);

  const safe = row.source_path.replace(/[\\/]/g, '__');
  fs.writeFileSync(path.join(OUT, safe + '.original.json'), original);
  fs.writeFileSync(path.join(OUT, safe + '.corrected.json'), corrected);

  report.push({
    capabilityId: row.capability_id,
    sourcePath: row.source_path,
    entryId: row.entry_id,
    disposition: 'CORRECTED',
    openArrays: touched.length,
    pointers: touched,
    original: { digest: row.content_digest, bytes: Number(row.byte_length) },
    corrected: { digest: correctedDigest, bytes: corrected.length }
  });

  statements.push(
    `-- ${row.source_path}\n` +
    `--   ${touched.length} item-less array(s): ${touched.join(', ')}\n` +
    `--   ${row.content_digest}  (${row.byte_length} bytes)\n` +
    `--   ${correctedDigest}  (${corrected.length} bytes)\n` +
    `IF NOT EXISTS (SELECT 1 FROM source.content_object\n` +
    `               WHERE content_digest = 0x${correctedDigest.slice(7).toUpperCase()})\n` +
    `INSERT source.content_object (content_digest, content_bytes, byte_length)\n` +
    `VALUES (0x${correctedDigest.slice(7).toUpperCase()},\n` +
    `        0x${corrected.toString('hex').toUpperCase()},\n` +
    `        ${corrected.length});`
  );
}

const header = `-- Corrected contract bytes. REVIEW ONLY -- DO NOT RUN AS-IS.
--
-- Generated ${new Date().toISOString()} by build-contract-fix.mjs
-- Capabilities: ${CAPABILITIES.join(', ')}
--
-- WHAT THIS DOES NOT DO, and why it is not a complete fix:
--
--   1. It does not repoint source.source_appearance at the new content objects.
--      sidefx_importer holds DENY UPDATE/DELETE on schema::source, so an
--      appearance cannot be moved. New appearance rows belong to a new
--      estate_snapshot, not to the published one.
--
--   2. It does not create the new estate_snapshot / estate_model, re-run
--      normalization, or call source.publish_model. Published definitions and
--      their members are immutable; a correction is a new generation, not an
--      edit of generation ${'${'}current}.
--
--   3. It does not update the capsule digest. Each of these documents is an
--      entry inside a packed .sfxcap whose digest covers its bytes. Changing an
--      entry changes the capsule identity, and capsule lineage is what
--      capability-embodiment.sql uses to resolve authority.
--
--   4. It does not touch runtime.capability_preparation. Existing preparations
--      were built from the current bytes and would have to be rebuilt.
--
-- Inserting a content object alone is inert -- nothing references it. It is
-- included so the exact corrected bytes and digests can be reviewed against the
-- .original.json / .corrected.json pairs written alongside this file.
--
-- The supported route for these bytes is the ingest pipeline: correct the
-- source capsule, capture a new snapshot, derive, ingest, publish. That is a
-- new generation with honest lineage. This script exists to show precisely what
-- would change, not to smuggle it in underneath the lineage gates.

`;

fs.writeFileSync(path.join(OUT, 'content-objects.sql'), header + statements.join('\n\n') + '\n');
fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2) + '\n');

for (const r of report) {
  if (r.disposition === 'UNCHANGED') { console.log(`UNCHANGED  ${r.sourcePath}`); continue; }
  console.log(`CORRECTED  ${r.sourcePath}`);
  console.log(`           ${r.openArrays} item-less array(s)`);
  for (const p of r.pointers) console.log(`             ${p}`);
  console.log(`           ${r.original.digest}  ${r.original.bytes} bytes`);
  console.log(`           ${r.corrected.digest}  ${r.corrected.bytes} bytes`);
}
console.log(`\nartifacts -> ${OUT}`);
console.log('  content-objects.sql   review-only INSERTs + what they do not do');
console.log('  report.json           pointers and digest pairs');
console.log('  *.original.json / *.corrected.json   diff these');
