import fs from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

const digest = bytes => 'sha256:' + createHash('sha256').update(bytes).digest('hex');
const one = (items, reason) => {
  if (items.length !== 1) throw new Error(reason + ':' + items.length);
  return items[0];
};

// Read the declaration into the existing platform graph compiler's input. This
// reader performs no provider selection, native lowering, writing or execution.
export async function readExecutionGraph(declaration, sdaRoot) {
  const { authority, closure, mechanics } = declaration;
  const selected = one(authority.recordsets[0], 'CAPABILITY_SCENARIO_SELECTION');
  if (selected.capability_id !== declaration.capabilityId || selected.scenario_id !== declaration.scenarioId)
    throw new Error('SELECTION_DIVERGENCE');
  for (const result of [authority, closure, mechanics]) {
    if (result.truncated || result.snapshotId !== authority.snapshotId || result.projectionDigest !== authority.projectionDigest
      || result.viewDefinitionDigest !== authority.viewDefinitionDigest) throw new Error('MIXED_DATABASE_AUTHORITY');
  }
  const records = [...authority.recordsets[1], ...authority.recordsets[2]].map(record => {
    const bytes = Buffer.from(record.content_bytes.base64, 'base64');
    if (digest(bytes) !== record.content_digest) throw new Error('SOURCE_BYTES_DIGEST_MISMATCH:' + record.source_path);
    return { ...record, text: bytes.toString('utf8') };
  });
  const document = record => ({ ...record, value: JSON.parse(record.text.replace(/^\uFEFF/, '')) });
  const documents = records.filter(record => record.source_path.endsWith('.json')).map(document);
  const at = (from, reference) => one(records.filter(record => record.source_path ===
    path.posix.normalize(path.posix.join(path.posix.dirname(from.source_path), reference))), 'SOURCE_REFERENCE:' + reference);
  const documentAt = (from, reference) => document(at(from, reference));
  const workspace = one(documents.filter(record => record.value.workspaceType === 'consumer-workspace-authority.v1'), 'WORKSPACE_AUTHORITY');
  const entry = one(workspace.value.capabilities.filter(value => documentAt(workspace, value.capability).value.capabilityId === declaration.capabilityId), 'WORKSPACE_CAPABILITY');
  const capability = documentAt(workspace, entry.capability);
  const executions = documentAt(workspace, entry.executionAuthorities);
  const graphAuthority = documentAt(workspace, entry.semanticGraph);
  const interfaces = documentAt(workspace, entry.interfaces);
  const fixtures = documentAt(workspace, entry.fixtures);
  const platform = one(documents.filter(record => record.value.sdaPlatform?.commit), 'PINNED_PLATFORM_PACKAGE');
  const commit = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: sdaRoot, encoding: 'utf8' }).trim();
  if (commit !== platform.value.sdaPlatform.commit) throw new Error('PHYSICAL_PLATFORM_COMMIT_MISMATCH');
  const tracked = ['tools/src', 'languages/typescript', 'package.json'];
  if (execFileSync('git', ['diff', '--name-only', commit, '--', ...tracked], { cwd: sdaRoot, encoding: 'utf8' }).trim())
    throw new Error('PHYSICAL_PLATFORM_SOURCE_MODIFIED');
  if (execFileSync('git', ['ls-files', '--others', '--exclude-standard', '--', ...tracked], { cwd: sdaRoot, encoding: 'utf8' }).trim())
    throw new Error('PHYSICAL_PLATFORM_SOURCE_UNTRACKED');

  // The parser and compiler are the same pinned platform implementations used
  // by the native reader. Built module bytes and their imports are recorded.
  const platformFiles = new Map();
  const { default: ts } = await import('typescript');
  const load = async relative => {
    const visit = async file => {
      const normalized = path.posix.normalize(file);
      if (normalized.startsWith('../') || path.isAbsolute(normalized)) throw new Error('PLATFORM_READ_OUTSIDE_ROOT');
      if (platformFiles.has(normalized)) return;
      const bytes = await fs.readFile(path.join(sdaRoot, normalized));
      platformFiles.set(normalized, digest(bytes));
      const ast = ts.createSourceFile(normalized, bytes.toString('utf8'), ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
      for (const statement of ast.statements) {
        const specifier = statement.moduleSpecifier;
        if ((ts.isImportDeclaration(statement) || ts.isExportDeclaration(statement)) && specifier && ts.isStringLiteral(specifier)
          && specifier.text.startsWith('.')) await visit(path.posix.join(path.posix.dirname(normalized), specifier.text));
      }
    };
    await visit(relative);
    return import(pathToFileURL(path.join(sdaRoot, relative)).href);
  };
  const { AnnotatedGherkinParser } = await load('artifacts/tools/dist/adapters/consumer-projection/annotated-gherkin-parser.js');
  const { GherkinScenarioGraphBuilder } = await load('artifacts/tools/dist/consumer-projection/authority/gherkin-scenario-graph-builder.js');
  const { SemanticTransitionGraphBuilder } = await load('artifacts/tools/dist/consumer-projection/authority/semantic-transition-graph-builder.js');
  const { SemanticExecutionGraphCompiler } = await load('languages/typescript/runtimes/node/semantic-execution-graph/index.js');
  const parser = new GherkinScenarioGraphBuilder(new AnnotatedGherkinParser());
  const features = records.filter(record => record.source_path.startsWith('capabilities/') && record.source_path.endsWith('.feature'));
  const parsed = features.flatMap(record => {
    const owner = one([...record.text.matchAll(/^\s*@capability:([^\s]+)\s*$/gm)].map(match => match[1]), 'FEATURE_CAPABILITY_AUTHORITY');
    return parser.build(record.text).map(scenario => ({ owner, scenario }));
  });
  for (const row of closure.recordsets[0]) {
    if (row.cycle_detected) throw new Error('SCENARIO_INVOCATION_CYCLE');
    if (!parsed.some(item => item.owner === (row.owning_capability_id ?? declaration.capabilityId) && item.scenario.scenarioId === row.downstream_scenario_id))
      throw new Error('SCENARIO_SOURCE_RESOLUTION:' + row.downstream_scenario_id);
  }
  const scenarios = parsed.map(item => item.scenario);
  const transitions = new SemanticTransitionGraphBuilder().build(graphAuthority.value, Object.fromEntries(scenarios.map(scenario => [scenario.scenarioId, scenario])));
  const interfaceAuthority = structuredClone(interfaces.value);
  const transformations = [];
  const transformationSources = [];
  for (const binding of [...interfaceAuthority.portBindings, ...(interfaceAuthority.projectionBindings ?? [])]) {
    const reference = binding.configuration?.transformationAuthorityRef;
    if (!reference) continue;
    const source = documentAt(interfaces, reference);
    const transformation = one(source.value.transformations.filter(item => item.id === binding.configuration.transformationId), 'TRANSFORMATION_RESOLUTION');
    binding.configuration.expression = transformation.expression;
    if (!transformations.some(item => item.id === transformation.id)) transformations.push(transformation);
    transformationSources.push(source.source_path);
  }
  const catalog = documentAt(interfaces, interfaceAuthority.contractCatalog);
  const contracts = Object.fromEntries(Object.entries(catalog.value).map(([id, reference]) => {
    const source = documentAt(catalog, reference);
    return [id, { schemaRef: source.source_path, schemaId: source.value.$id, schemaDigest: digest(JSON.stringify(source.value)).slice(7), schema: source.value }];
  }));
  const sourceRefs = [...new Set([capability.source_path, ...features.map(record => record.source_path), executions.source_path,
    graphAuthority.source_path, interfaces.source_path, ...transformationSources])];
  const graphInput = { capability: capability.value, scenarios, transitions, executionAuthorities: executions.value.executionAuthorities,
    interfaceAuthority, semanticTransformations: transformations, sourceRefs };
  const compiled = new SemanticExecutionGraphCompiler().compile(graphInput);
  const surface = [...platformFiles].sort(([a], [b]) => a.localeCompare(b)).map(([file, fileDigest]) => ({ file, digest: fileDigest }));
  return { compiled, graphInput, contractCatalog: { contracts }, fixtureAuthority: fixtures.value,
    sources: records.map(({ text, content_bytes, ...record }) => record),
    platform: { commit, digest: digest(JSON.stringify(surface)), files: surface } };
}
