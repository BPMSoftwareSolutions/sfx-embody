import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const estateRoot = fileURLToPath(new URL('..', import.meta.url));
const configuration = JSON.parse(await fs.readFile(path.join(estateRoot, 'config/database-runtime.json'), 'utf8'));
const databaseRoot = path.resolve(estateRoot, 'config', configuration.databaseRoot);
const { query } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/run.mjs')).href);
const result = await query(`
SELECT DISTINCT JSON_VALUE(dependency.value,'$.path') AS dependency_path,
 JSON_VALUE(dependency.value,'$.digest') AS dependency_digest,content.content_bytes
FROM analysis.v_selected_semantic_definition d
CROSS APPLY OPENJSON(d.definition_json,'$.semantics.executionAuthority.runtime.dependencies') dependency
LEFT JOIN source.content_object content ON content.content_digest=TRY_CONVERT(binary(32),SUBSTRING(JSON_VALUE(dependency.value,'$.digest'),8,64),2)
WHERE d.estate_model_pk=@estate_model_pk AND d.object_kind='PROVIDER'
 AND JSON_VALUE(dependency.value,'$.root')='estateRoot'
ORDER BY dependency_path`, { retainObjects: false, rowLimit: 1000 });
if (result.truncated) throw new Error('PROVIDER_DEPENDENCIES_TRUNCATED');
const allowed = path.resolve(estateRoot, 'providers/consumer-execution');
const files = result.recordsets[0].map(row => {
  const destination = path.resolve(estateRoot, row.dependency_path), relative = path.relative(allowed, destination);
  if (!relative || relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('PROVIDER_REFERENCE_OUTSIDE_ROOT');
  if (!row.content_bytes?.base64) throw new Error('PROVIDER_DEPENDENCY_BYTES_ABSENT:' + row.dependency_path);
  const bytes = Buffer.from(row.content_bytes.base64, 'base64');
  if ('sha256:' + createHash('sha256').update(bytes).digest('hex') !== row.dependency_digest)
    throw new Error('PROVIDER_DEFINITION_DIGEST_MISMATCH:' + row.dependency_path);
  return { destination, bytes, digest: row.dependency_digest };
});
for (const file of files) {
  await fs.mkdir(path.dirname(file.destination), { recursive: true });
  await fs.writeFile(file.destination, file.bytes);
  if ('sha256:' + createHash('sha256').update(await fs.readFile(file.destination)).digest('hex') !== file.digest)
    throw new Error('PROVIDER_DEFINITION_DIGEST_MISMATCH:' + file.destination);
}
console.log(JSON.stringify({ disposition: 'PASSED', verifiedDependencies: files.length }));
