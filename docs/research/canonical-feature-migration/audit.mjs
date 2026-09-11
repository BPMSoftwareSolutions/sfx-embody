// Read-only review evidence. SQL runs as sidefx_reader; only the explicit report is written.
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';

const [databaseRoot, harnessRoot, output] = process.argv.slice(2);
if (!databaseRoot || !harnessRoot || !output) {
  throw new Error('Usage: node audit.mjs <database-root> <harness-root> <report.json>');
}
const { query } = await import(pathToFileURL(path.join(databaseRoot, 'src/query/run.mjs')));
const { parseFeature, featureScenarios, tagsToValues } = await import(pathToFileURL(path.join(databaseRoot, 'src/derive/feature.mjs')));
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const unique = xs => [...new Set(xs)].sort();
const single = xs => xs?.length === 1 && typeof xs[0] === 'string' ? xs[0] : null;
const definition = row => JSON.parse(Buffer.from(row.definition_bytes.base64, 'base64').toString('utf8'));
const corpus = [];
for (const file of (await fs.readdir(path.join(harnessRoot, 'features'))).filter(f => f.endsWith('.feature')).sort()) {
  const bytes = await fs.readFile(path.join(harnessRoot, 'features', file));
  const feature = parseFeature(bytes.toString('utf8')).feature;
  const tags = tagsToValues(feature.tags);
  corpus.push({ file, digest: hash(bytes), capabilityId: single(tags.capability), rootScenarioId: single(tags['root-scenario']),
    scenarios: featureScenarios(feature).map(({ scenario, inherited }) => {
      const values = tagsToValues([...inherited, ...scenario.tags]);
      return { id: single(values.scenario), line: scenario.location.line, name: scenario.name, tags: values, steps: scenario.steps.length };
    }) });
}
const sqlText = await fs.readFile(new URL('./audit.sql', import.meta.url), 'utf8');
const result = await query(sqlText, { retainObjects: false, rowLimit: 20000 });
if (result.truncated) throw new Error('AUDIT_TRUNCATED');
const [pin, capabilities, scenarios, appearances, lineage, retainedCounts, unselectedIdentities] = result.recordsets;
for (const f of corpus) {
  if (hash(await fs.readFile(path.join(harnessRoot, 'features', f.file))) !== f.digest) throw new Error('CORPUS_CHANGED_DURING_AUDIT:' + f.file);
}
const namespaces = unique(capabilities.map(c => c.namespace_id));
if (namespaces.length !== 1 || namespaces[0] !== 'sidefx:capabilities') throw new Error('CORPUS_NAMESPACE_REVIEW_REQUIRED');
const model = capabilities.map(c => {
  const semantic = definition(c).semantics;
  return { namespace: c.namespace_id, id: c.capability_id, versionPk: c.capability_version_pk,
    hasUserStory: Boolean(semantic.authority?.userStory), hasExperience: Boolean(semantic.authority?.experience),
    scenarios: scenarios.filter(s => s.capability_id === c.capability_id).map(s => {
      const meaning = definition(s).semantics;
      return { id: s.scenario_id, versionPk: s.scenario_version_pk, steps: meaning.scenario?.steps?.length ?? 0,
        semanticsKeys: Object.keys(meaning), hasTags: Boolean(meaning.tags),
        declaredInput: meaning.input ?? null };
    }) };
});
const declared = corpus.filter(f => f.capabilityId);
const byCapability = new Map(unique(declared.map(f => f.capabilityId)).map(id => [id, declared.filter(f => f.capabilityId === id)]));
const pairs = declared.flatMap(f => f.scenarios.filter(s => s.id).map(s => f.capabilityId + '/' + s.id));
const declarations = corpus.flatMap(f => f.scenarios.filter(s => s.id).map(s => ({ capabilityId: f.capabilityId, file: f.file, id: s.id })));
const missingCapabilities = [...byCapability].filter(([id]) => !model.some(c => c.id === id)).map(([id, files]) => ({ id, files: files.map(f => f.file), scenarioIds: unique(files.flatMap(f => f.scenarios.map(s => s.id).filter(Boolean))) }));
const modelOnlyCapabilities = model.filter(c => !byCapability.has(c.id)).map(c => ({ id: c.id, scenarioIds: c.scenarios.map(s => s.id) }));
const sharedDifferences = [...byCapability].flatMap(([id, files]) => {
  const selected = model.find(c => c.id === id);
  if (!selected) return [];
  const declaredIds = unique(files.flatMap(f => f.scenarios.map(s => s.id).filter(Boolean)));
  const selectedIds = selected.scenarios.map(s => s.id);
  const corpusOnly = declaredIds.filter(s => !selectedIds.includes(s));
  const modelOnly = selectedIds.filter(s => !declaredIds.includes(s));
  return corpusOnly.length || modelOnly.length ? [{ id, files: files.map(f => f.file), corpusOnly, modelOnly }] : [];
});
const retention = corpus.map(f => {
  const matches = appearances.filter(a => a.source_path === 'features/' + f.file);
  return { file: f.file, digest: f.digest, matchingAppearances: matches.filter(a => a.content_digest === f.digest).length,
    variants: unique(matches.map(a => a.content_digest)) };
});
const summary = {
  files: corpus.length, filesWithCapability: declared.length, distinctCapabilityIds: byCapability.size,
  scenarioBlocks: corpus.reduce((n, f) => n + f.scenarios.length, 0),
  taggedBlocks: declarations.length, globallyDistinctScenarioIds: unique(declarations.map(s => s.id)).length,
  distinctCapabilityScenarioPairs: unique(pairs).length,
  untaggedBlocks: corpus.flatMap(f => f.scenarios.filter(s => !s.id).map(s => ({ file: f.file, line: s.line, name: s.name }))),
  selectedCapabilities: model.length, selectedScenarios: scenarios.length,
  retainedCapabilityIdentities: Number(retainedCounts[0].retained_capability_identities),
  retainedCapabilityVersions: Number(retainedCounts[0].retained_capability_versions),
  missingCapabilities: missingCapabilities.length, missingCapabilityScenarios: missingCapabilities.reduce((n, c) => n + c.scenarioIds.length, 0),
  modelOnlyCapabilities: modelOnlyCapabilities.length, modelOnlyCapabilityScenarios: modelOnlyCapabilities.reduce((n, c) => n + c.scenarioIds.length, 0),
  sharedCorpusOnlyPairs: sharedDifferences.reduce((n, c) => n + c.corpusOnly.length, 0),
  sharedModelOnlyPairs: sharedDifferences.reduce((n, c) => n + c.modelOnly.length, 0),
  sharedModelOnlyDistinctIds: unique(sharedDifferences.flatMap(c => c.modelOnly)).length,
  matchingCanonicalFiles: retention.filter(f => f.matchingAppearances).length,
  retainedFeaturePaths: unique(appearances.map(a => a.source_path)).length,
  selectedScenariosWithoutSteps: model.flatMap(c => c.scenarios.filter(s => !s.steps).map(s => ({ capabilityId: c.id, scenarioId: s.id })))
};
const implementation = {};
for (const name of ['config/normalization-v1.json', 'config/normalization-v2.json', 'src/derive/feature.mjs', 'src/migration/normalize.mjs', 'src/register/capability.mjs', 'src/migration/schema.mjs', 'package-lock.json']) {
  implementation[name] = hash(await fs.readFile(path.join(databaseRoot, name)));
}
const report = { reportType: 'canonical-feature-migration-review.v1', measuredAt: new Date().toISOString(),
  databaseRoot: path.resolve(databaseRoot), harnessRoot: path.resolve(harnessRoot), pin: pin[0],
  queryEvidence: Object.fromEntries(Object.entries(result).filter(([k]) => k !== 'recordsets')),
  auditImplementationDigest: hash(await fs.readFile(new URL(import.meta.url))), databaseImplementationDigests: implementation,
  summary, filesWithoutCapability: corpus.filter(f => !f.capabilityId).map(f => f.file),
  duplicateCapabilityDeclarations: [...byCapability].filter(([, files]) => files.length > 1).map(([id, files]) => ({ id, files: files.map(f => f.file) })),
  repeatedScenarioIds: unique(declarations.map(s => s.id)).flatMap(id => { const occurrences = declarations.filter(s => s.id === id); return occurrences.length > 1 ? [{ id, occurrences }] : []; }),
  missingCapabilities, modelOnlyCapabilities, sharedDifferences, retention, featureLineage: lineage, unselectedIdentities, model,
  corpus: corpus.map(f => ({ ...f, scenarios: f.scenarios.map(({ id, line, steps }) => ({ id, line, steps })) })) };
await fs.writeFile(output, JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ pin: report.pin, summary, sharedDifferences, output: path.resolve(output) }, null, 2));
