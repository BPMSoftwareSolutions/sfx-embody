import { readFile, writeFile, access } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import assert from 'node:assert/strict';

// Documentation provenance only: no database, provider, training, or admission effects.
const here = path.dirname(fileURLToPath(import.meta.url));
const research = path.resolve(here, '../scenario-experiences');
const featureRoot = path.resolve(here, '../../../../agentic-harness/features');
const digest = bytes => 'sha256:' + createHash('sha256').update(bytes).digest('hex');
const readJson = async file => JSON.parse(await readFile(file, 'utf8'));
const writeJson = (file, value) => writeFile(file, JSON.stringify(value, null, 2) + '\n');
const reviewDigest = 'sha256:7c64aa40bf0082a82801e78933aee289faa1ff692d684ab41257de172403fb64';
const roots = [
  'govern-model-provider-binding',
  'resolve-governed-model-invocation-profile',
  'construct-model-connection-runtime-closure',
  'execute-governed-model-invocation',
  'obtain-governed-model-response',
  'verify-governed-model-invocation-parity',
  'determine-model-role-provider-switch',
  'resolve-sidefx-eligible-providers',
  'bind-model-testimony-evidence',
  'verify-model-connection-conformance',
  'execute-governed-model-role-conveyor',
  'resolve-sidefx-capability-precedents',
];
const summary = await readJson(path.join(research, 'summary.json'));
const bindings = await readJson(path.join(research, 'scenario-bindings.json'));
const taxonomy = await readJson(path.join(research, 'contract-taxonomy.json'));
assert.equal(summary.counts.scenarios, 824, 'Retained census changed; reassess report claims.');
assert.equal(summary.counts.contracts, 630);
assert.equal(summary.counts.resolvedInputs, 812);
assert.equal(summary.counts.resolvedOutcomes, 809);
assert.equal(summary.counts.selectedDefinitions.find(x => x.object_kind === 'FIXTURE')?.definition_count, '1155');
assert.equal(digest(await readFile(path.join(here, 'team-review.txt'))), reviewDigest);

const records = [];
const censusOnly = new Set(['resolve-sidefx-eligible-providers', 'resolve-sidefx-capability-precedents']);
for (const id of roots) {
  const matches = bindings.filter(b => b.isRoot && b.scenarioId === id && b.capabilityId === id);
  assert.equal(matches.length, 2, 'Expected two root contract faces for ' + id);
  const input = matches.find(b => b.direction === 'input');
  const outcome = matches.find(b => b.direction === 'outcome');
  assert.ok(input && outcome, 'Missing input/outcome for ' + id);
  for (const b of [input, outcome]) {
    assert.ok(taxonomy.some(c => c.contractVersionPk === b.contractVersionPk &&
      c.contractId === b.contractId && c.schemaDigest === b.schemaDigest),
    'Contract taxonomy mismatch for ' + id + ' ' + b.direction);
  }
  const sourceFile = path.join(featureRoot, id + '.feature');
  let corroboratingFeature = null;
  if (!censusOnly.has(id)) {
    const bytes = await readFile(sourceFile);
    const source = bytes.toString('utf8');
    assert.ok(source.includes('@capability:' + id));
    assert.ok(source.includes('@root-scenario:' + id));
    assert.equal(source.match(/@input-contract:([^\s]+)/)?.[1], input.contractId);
    assert.equal(source.match(/@outcome-contract:([^\s]+)/)?.[1], outcome.contractId);
    const lines = source.split(/\r?\n/);
    const firstScenario = lines.findIndex(line => line.trim().startsWith('@scenario:'));
    assert.ok(firstScenario >= 0);
    corroboratingFeature = {
      file: path.relative(here, sourceFile).split(path.sep).join('/'),
      sha256: digest(bytes),
      declaredIntentExcerpt: lines.slice(0, firstScenario).join('\n').trim(),
      scope: 'Local working-tree declaration, not an execution result or proof of byte identity with the database-selected source revision.',
    };
  }
  records.push({
    capabilityId: id,
    namespace: input.namespace,
    scenarioVersionPk: input.scenarioVersionPk,
    input: { contractId: input.contractId, contractVersionPk: input.contractVersionPk,
      schemaDigest: input.schemaDigest },
    outcome: { contractId: outcome.contractId, contractVersionPk: outcome.contractVersionPk,
      schemaDigest: outcome.schemaDigest },
    corroboratingFeature,
    declarationCoverage: corroboratingFeature ? 'LOCAL_DECLARATION_INSPECTED' :
      'RETAINED_CENSUS_ONLY: no corresponding feature at the inspected agentic-harness feature root.',
  });
}

const baselineArtifacts = {};
for (const name of ['summary.json', 'scenario-bindings.json', 'contract-taxonomy.json']) {
  baselineArtifacts['../scenario-experiences/' + name] = digest(await readFile(path.join(research, name)));
}
const generatedAt = new Date().toISOString();
await writeJson(path.join(here, 'evidence-map.json'), {
  generatedAt,
  evidenceKind: 'CURATED_DECLARATION_AND_CONTRACT_MAP',
  censusObservedAt: summary.observedAt,
  censusProof: summary.proof,
  baselineArtifacts,
  limits: [
    'Reuses the retained census; no fresh database query.',
    'Twelve selected roots are integration examples, not an ML-readiness census.',
    'Contract identities/digests are retained research bindings; selected schema bytes are not revalidated here.',
    'Local feature declarations corroborate intent and root contract IDs; source bytes may differ from database-selected revisions.',
    'No provider execution, domain evaluation, training, dataset audit, promotion, or deployment was performed.',
    'bind-model-testimony-evidence currently specifies Gemini, exactly one attempt, and a structured candidate.',
  ],
  records,
});

const markdown = await readFile(path.join(here, 'README.md'), 'utf8');
const localLinks = [];
const externalReferences = [];
for (const match of markdown.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
  const target = match[1];
  if (/^https?:\/\//.test(target)) { externalReferences.push(target); continue; }
  const relative = decodeURIComponent(target.split('#')[0]);
  // The receipt is created below after all input/artifact checks pass.
  if (relative && relative !== 'verification.json') await access(path.resolve(here, relative));
  localLinks.push(target);
}
const repoReadme = await readFile(path.resolve(here, '../../../README.md'), 'utf8');
assert.ok(repoReadme.includes('(docs/research/ml-opportunity/README.md)'));
const artifactHashes = {};
for (const name of ['README.md', 'team-review.txt', 'collect-evidence.mjs', 'evidence-map.json']) {
  artifactHashes[name] = digest(await readFile(path.join(here, name)));
}
await writeJson(path.join(here, 'verification.json'), {
  verifiedAt: generatedAt,
  disposition: 'DOCUMENT_PROVENANCE_CHECKS_PASSED',
  reviewIdentity: reviewDigest,
  curatedRoots: records.length,
  resolvedContractFaces: records.length * 2,
  localDeclarationsInspected: records.filter(r => r.corroboratingFeature).length,
  rootContractTagsMatchCorroboratingDeclarations: true,
  localLinksChecked: localLinks,
  externalReferences: [...new Set(externalReferences)],
  externalReferenceCheck: 'Consulted during authoring; this script does not fetch external pages.',
  artifactHashes,
  scope: 'Document provenance and internal consistency only. Not capability execution, model quality, corpus suitability, or managed admission evidence.',
});
await access(path.join(here, 'verification.json'));
console.log(JSON.stringify({ disposition: 'DOCUMENT_PROVENANCE_CHECKS_PASSED',
  roots: records.length, contractFaces: records.length * 2, localLinks: localLinks.length }));
