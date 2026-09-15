// publish-projected-bodies.mjs
//
// Deterministic boot/harness generator for the database copy of a capability's
// projected mechanical bodies.
//
//   node scripts/publish-projected-bodies.mjs            -> dry-run migration (final ROLLBACK)
//   node scripts/publish-projected-bodies.mjs --install  -> committed migration (final COMMIT)
//
// Inputs:
//   --capability <id>  the declared capability (default below)
//   --manifest <path>  the projection manifest that lists the bodies (default below)
//   --out <path>       the migration to emit (default derived from the capability)
//
// The generator reads the manifest and the listed body files, verifies every
// file's sha256 against the manifest, and emits ONE idempotent migration under
// sql/migrations/. The migration:
//   * copies every body into source.content_object under its sha256 content
//     address (the CHECK constraint re-derives the digest);
//   * maps every body once in source.source_appearance with
//     source_class='PROJECTED_BODY', keyed by capability + generation +
//     projection target + relative path (container_locator carries the key as
//     JSON; source_path/entry_id carry the readable locator);
//   * mints/repairs a dedicated generation row in source.estate_snapshot whose
//     snapshot_digest is derived from the capability and the manifest digest, so
//     re-running the file is a no-op and a changed body set is a new generation;
//   * writes no model.* rows, so the authority graph source, the authority
//     bundle reader, the execution delivery reader and the loader never read it;
//   * prints the generation, the mapping rows, manifest-conformance counts and
//     hot-path isolation counts before it ends in ROLLBACK (or COMMIT).
//
// The output is a pure function of the manifest bytes and the body bytes: the
// same inputs produce the same migration byte-for-byte.
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const DEFAULTS = {
  capability: 'resolve-equity-market-price-evidence',
  manifest: 'embodiments/resolve-equity-market-price-evidence/projected/projection-manifest.json',
};
const MANIFEST_TYPE = 'consumer-capability-projection-manifest.v1';
const PROJECTION_TARGETS = ['node', 'python', 'csharp'];
// The projection store never publishes these directories; the database copy
// must not either, even if a stale manifest lists them.
const BUILD_DIRECTORIES = new Set(['bin', 'obj', '__pycache__', 'build', 'node_modules', '.build', '.gradle', '.swiftpm', 'DerivedData']);

function fail(message) {
  console.error('publish-projected-bodies:', message);
  process.exit(1);
}

function parseArguments(argv) {
  const options = { ...DEFAULTS, install: false };
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index];
    if (argument === '--install') options.install = true;
    else if (argument === '--capability') options.capability = argv[++index];
    else if (argument === '--manifest') options.manifest = argv[++index];
    else if (argument === '--out') options.out = argv[++index];
    else fail(`unknown argument '${argument}'`);
  }
  if (!options.capability || !options.manifest) fail('--capability and --manifest require values');
  options.manifest = path.resolve(ROOT, options.manifest);
  options.out = path.resolve(ROOT, options.out ?? path.join('sql/migrations', `publish-projected-bodies-${options.capability}.sql`));
  if (!options.out.startsWith(path.join(ROOT, 'sql', 'migrations') + path.sep)) fail('--out must stay under sql/migrations/');
  return options;
}

const sha256Hex = (bytes) => createHash('sha256').update(bytes).digest('hex');
const sqlString = (value) => `N'${value.replaceAll("'", "''")}'`;
const hexLiteral = (hex) => `0x${hex}`;
const isBuildByProduct = (relativePath) => relativePath.split('/').some((segment) => BUILD_DIRECTORIES.has(segment));

// A body is target-specific when it lives under a target directory or when its
// file name pins the target (`*.node.json`, `*.python.json`, `*.csharp.json`,
// `*.generated.py`, `*.generated.cs`, ...). Everything else is shared.
function projectionTarget(relativePath) {
  const segments = relativePath.split('/');
  if (PROJECTION_TARGETS.includes(segments[0])) return segments[0];
  const basename = segments.at(-1);
  return PROJECTION_TARGETS.find((target) => basename === target
    || basename.startsWith(`${target}.`)
    || basename.includes(`.${target}.`)
    || basename.endsWith(`.${target}`)) ?? 'shared';
}

function readManifest(manifestPath) {
  if (!fs.existsSync(manifestPath)) fail(`manifest not found: ${manifestPath}`);
  const bytes = fs.readFileSync(manifestPath);
  const manifest = JSON.parse(bytes.toString('utf8'));
  if (manifest.projectionManifestType !== MANIFEST_TYPE) fail(`unsupported manifest type '${manifest.projectionManifestType}'`);
  if (!Array.isArray(manifest.files)) fail('manifest has no files array');
  return { bytes, manifest };
}

function collectBodies(manifest, manifestDirectory) {
  const seen = new Set();
  const bodies = [];
  for (const entry of manifest.files) {
    if (typeof entry.path !== 'string' || !entry.path) fail('manifest file without a path');
    if (entry.path.includes('..') || path.isAbsolute(entry.path)) fail(`manifest path escapes the projection root: ${entry.path}`);
    if (isBuildByProduct(entry.path)) continue;
    if (seen.has(entry.path)) fail(`manifest lists '${entry.path}' twice`);
    seen.add(entry.path);
    const absolute = path.join(manifestDirectory, ...entry.path.split('/'));
    if (!fs.existsSync(absolute)) fail(`body not found: ${entry.path}`);
    const bytes = fs.readFileSync(absolute);
    const sha256 = sha256Hex(bytes);
    if (entry.sha256 !== sha256) fail(`body digest mismatch for '${entry.path}': manifest ${entry.sha256}, disk ${sha256}`);
    if (entry.digest !== undefined && entry.digest !== `sha256:${sha256}`) fail(`body digest field mismatch for '${entry.path}'`);
    bodies.push({ path: entry.path, bytes, sha256, target: projectionTarget(entry.path) });
  }
  if (!bodies.length) fail('manifest lists no bodies');
  return bodies.sort((left, right) => left.path.localeCompare(right.path));
}

function preamble(options, manifestSha256, generationHex, bodies) {
  const counts = Object.fromEntries([...PROJECTION_TARGETS, 'shared']
    .map((target) => [target, bodies.filter((body) => body.target === target).length]));
  const bodySummary = [...PROJECTION_TARGETS, 'shared']
    .filter((target) => counts[target] > 0)
    .map((target) => `${target} ${counts[target]}`)
    .join(', ');
  return `-- publish-projected-bodies-${options.capability}.sql
--
-- GENERATED by scripts/publish-projected-bodies.mjs -- do not hand-edit this body.
--
--   author:    node scripts/publish-projected-bodies.mjs${options.install ? ' --install' : ''}
--
-- Source manifest: ${path.relative(ROOT, options.manifest).replaceAll('\\', '/')}
-- Manifest digest: sha256:${manifestSha256}
-- Generation:      sha256:${generationHex}
-- Bodies:          ${bodies.length} content-addressed rows (${bodySummary})
--
-- Each listed body is copied into source.content_object under its sha256 content
-- address and mapped once in source.source_appearance with
-- source_class='PROJECTED_BODY' under a dedicated generation row in
-- source.estate_snapshot. The mapping row is keyed by
-- capability + generation + projection target + relative path:
--   container_locator = {"capabilityId":...,"generation":...,"projectionTarget":...,"relativePath":...}
--   source_path       = projected-bodies/<capability>/<relative path>
--   entry_id          = <relative path>
-- The generation key is derived from the capability and the manifest digest, so
-- re-running this file is a no-op and a changed body set is a new generation.
-- Mapping rows are only inserted, never updated in place.
--
-- No model.* row is written: the authority graph source
-- (analysis.v_capability_graph_source), the authority bundle reader, the
-- execution delivery reader and the loader never read these rows.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg;
WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;`;
}

function generationBatch(options, manifestSha256, generationHex) {
  const sourceHead = `projected-bodies/${options.capability}/${manifestSha256}`;
  return `DECLARE @generationDigest binary(32) = ${hexLiteral(generationHex)};
DECLARE @manifestDigest binary(32) = ${hexLiteral(manifestSha256)};
DECLARE @snapshotPk bigint = (SELECT estate_snapshot_pk FROM source.estate_snapshot WHERE snapshot_digest=@generationDigest);
IF @snapshotPk IS NULL
BEGIN
  INSERT source.estate_snapshot (snapshot_digest, estate_manifest_digest, source_head, captured_at)
    VALUES (@generationDigest, @manifestDigest, ${sqlString(sourceHead)}, NULL);
  SET @snapshotPk = SCOPE_IDENTITY();
END
SELECT '1_generation' AS result_set, @snapshotPk AS generation_pk,
  'sha256:' + LOWER(CONVERT(varchar(64), @generationDigest, 2)) AS generation,
  'sha256:' + LOWER(CONVERT(varchar(64), @manifestDigest, 2)) AS manifest_digest,
  ${sqlString(sourceHead)} AS source_head;`;
}

function bodyBatch(options, body, generationHex) {
  const sourcePath = `projected-bodies/${options.capability}/${body.path}`;
  const key = JSON.stringify({
    capabilityId: options.capability,
    generation: `sha256:${generationHex}`,
    projectionTarget: body.target,
    relativePath: body.path,
  });
  const appearanceDigest = sha256Hex(Buffer.from(`PROJECTED_BODY|${generationHex}|${sourcePath}|${body.sha256}`, 'utf8'));
  return `DECLARE @bytes varbinary(max) = ${hexLiteral(body.bytes.toString('hex'))};
DECLARE @contentDigest binary(32) = HASHBYTES('SHA2_256', @bytes);
IF @contentDigest <> ${hexLiteral(body.sha256)} THROW 51010, ${sqlString(`PROJECTED_BODY_DIGEST_MISMATCH ${body.path}`)}, 1;
DECLARE @generationDigest binary(32) = ${hexLiteral(generationHex)};
DECLARE @snapshotPk bigint = (SELECT estate_snapshot_pk FROM source.estate_snapshot WHERE snapshot_digest=@generationDigest);
IF @snapshotPk IS NULL THROW 51011, N'PROJECTED_BODY_GENERATION_NOT_FOUND', 1;
IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@contentDigest)
  INSERT source.content_object (content_digest, content_bytes, byte_length) VALUES (@contentDigest, @bytes, DATALENGTH(@bytes));
DECLARE @contentObjectPk bigint = (SELECT content_object_pk FROM source.content_object WHERE content_digest=@contentDigest);
IF NOT EXISTS (SELECT 1 FROM source.source_appearance WHERE estate_snapshot_pk=@snapshotPk AND source_path=${sqlString(sourcePath)})
  INSERT source.source_appearance (estate_snapshot_pk, content_object_pk, appearance_digest, source_path, source_class, container_locator, capsule_digest, referenced_authority_digest, entry_id)
    VALUES (@snapshotPk, @contentObjectPk, ${hexLiteral(appearanceDigest)}, ${sqlString(sourcePath)}, 'PROJECTED_BODY', ${sqlString(key)}, NULL, NULL, ${sqlString(body.path)});`;
}

function verificationBatch(bodies, generationHex) {
  const expected = bodies
    .map((body) => `  (${sqlString(body.target)}, ${sqlString(body.path)}, ${hexLiteral(body.sha256)})`)
    .join(',\n');
  return `DECLARE @generationDigest binary(32) = ${hexLiteral(generationHex)};
DECLARE @snapshotPk bigint = (SELECT estate_snapshot_pk FROM source.estate_snapshot WHERE snapshot_digest=@generationDigest);
DECLARE @expected TABLE (target nvarchar(64) COLLATE Latin1_General_100_BIN2, relative_path nvarchar(400) COLLATE Latin1_General_100_BIN2, digest binary(32), PRIMARY KEY (target, relative_path));
INSERT @expected (target, relative_path, digest) VALUES
${expected};

SELECT '2_capability_listing' AS result_set,
  JSON_VALUE(a.container_locator, '$.capabilityId') AS capability_id,
  'sha256:' + LOWER(CONVERT(varchar(64), s.snapshot_digest, 2)) AS generation,
  JSON_VALUE(a.container_locator, '$.projectionTarget') AS target,
  JSON_VALUE(a.container_locator, '$.relativePath') AS relative_path,
  'sha256:' + LOWER(CONVERT(varchar(64), c.content_digest, 2)) AS digest,
  c.byte_length
FROM source.source_appearance a
JOIN source.content_object c ON c.content_object_pk = a.content_object_pk
JOIN source.estate_snapshot s ON s.estate_snapshot_pk = a.estate_snapshot_pk
WHERE a.source_class = 'PROJECTED_BODY' AND a.estate_snapshot_pk = @snapshotPk
ORDER BY target, relative_path;

SELECT '3_manifest_conformance' AS result_set,
  (SELECT COUNT(*) FROM @expected) AS manifest_bodies,
  (SELECT COUNT(*) FROM @expected e
     JOIN source.source_appearance a ON a.source_class = 'PROJECTED_BODY' AND a.estate_snapshot_pk = @snapshotPk
       AND a.entry_id = e.relative_path AND JSON_VALUE(a.container_locator, '$.projectionTarget') COLLATE Latin1_General_100_BIN2 = e.target
     JOIN source.content_object c ON c.content_object_pk = a.content_object_pk AND c.content_digest = e.digest) AS digest_matches,
  (SELECT COUNT(*) FROM @expected e WHERE NOT EXISTS (
     SELECT 1 FROM source.source_appearance a WHERE a.source_class = 'PROJECTED_BODY' AND a.estate_snapshot_pk = @snapshotPk
       AND a.entry_id = e.relative_path AND JSON_VALUE(a.container_locator, '$.projectionTarget') COLLATE Latin1_General_100_BIN2 = e.target)) AS missing_rows,
  (SELECT COUNT(*) FROM source.source_appearance a WHERE a.source_class = 'PROJECTED_BODY' AND a.estate_snapshot_pk = @snapshotPk) AS mapped_rows;

SELECT '4_hot_path_isolation' AS result_set,
  (SELECT COUNT(*) FROM model.semantic_object WHERE object_kind = 'PROJECTED_BODY') AS model_objects,
  (SELECT COUNT(*) FROM analysis.v_selected_semantic_definition WHERE object_kind = 'PROJECTED_BODY') AS selected_definitions,
  (SELECT COUNT(*) FROM analysis.v_capability_execution_declaration WHERE source_path LIKE N'projected-bodies/%') AS declaration_documents,
  (SELECT COUNT(*) FROM model.semantic_object_definition d
     JOIN source.source_appearance a ON a.content_object_pk = d.canonical_content_pk
     WHERE a.source_class = 'PROJECTED_BODY' AND a.estate_snapshot_pk = @snapshotPk) AS model_definitions_over_bodies,
  (SELECT COUNT(*) FROM source.source_observation o
     JOIN source.source_appearance a ON a.source_appearance_pk = o.source_appearance_pk
     WHERE a.source_class = 'PROJECTED_BODY' AND a.estate_snapshot_pk = @snapshotPk) AS observations_over_bodies;`;
}

function footer(options) {
  return options.install
    ? `COMMIT TRANSACTION;
-- Installed copy: the generation, the content objects and the mapping rows persist.`
    : `ROLLBACK TRANSACTION;
-- Verification only: nothing is written. Install with: node scripts/publish-projected-bodies.mjs --install`;
}

function main() {
  const options = parseArguments(process.argv.slice(2));
  const { bytes: manifestBytes, manifest } = readManifest(options.manifest);
  const manifestSha256 = sha256Hex(manifestBytes);
  const bodies = collectBodies(manifest, path.dirname(options.manifest));
  const generationHex = sha256Hex(Buffer.from(`projected-body-generation.v1|${options.capability}|${manifestSha256}`, 'utf8'));

  const batches = [
    preamble(options, manifestSha256, generationHex, bodies),
    generationBatch(options, manifestSha256, generationHex),
    ...bodies.map((body) => bodyBatch(options, body, generationHex)),
    verificationBatch(bodies, generationHex),
    footer(options),
  ];
  fs.mkdirSync(path.dirname(options.out), { recursive: true });
  fs.writeFileSync(options.out, `${batches.join('\nGO\n')}\n`, 'utf8');

  const counts = Object.fromEntries([...PROJECTION_TARGETS, 'shared']
    .map((target) => [target, bodies.filter((body) => body.target === target).length]));
  console.log(JSON.stringify({
    migration: path.relative(ROOT, options.out).replaceAll('\\', '/'),
    capability: options.capability,
    manifest: path.relative(ROOT, options.manifest).replaceAll('\\', '/'),
    manifestDigest: `sha256:${manifestSha256}`,
    generation: `sha256:${generationHex}`,
    bodies: bodies.length,
    targets: counts,
    disposition: options.install ? 'COMMIT' : 'ROLLBACK',
  }, null, 2));
}

main();
