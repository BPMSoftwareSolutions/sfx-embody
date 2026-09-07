import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { NodeConsumerObjectProvider } from './resolvers/node/consumer-object-provider.mjs';
import ts from 'typescript';

const json = text => JSON.parse(text.replace(/^\uFEFF/, ''));
const hash = bytes => 'sha256:' + crypto.createHash('sha256').update(bytes).digest('hex');
const pretty = value => JSON.stringify(value, null, 2) + '\n';
const one = (items, reason) => { if (items.length !== 1) throw new Error(reason + ':' + items.length); return items[0]; };
const name = id => id.split(/[^A-Za-z0-9]+/).filter(Boolean).map(x => x[0].toUpperCase() + x.slice(1)).join('');

export async function materializeNode({ bundleFile, sdaRoot, outputRoot }) {
  const bundle = json(await fs.readFile(bundleFile, 'utf8'));
  const { selection, authority, resolutions } = bundle;
  const selected = one(authority.recordsets[0], 'CAPABILITY_SCENARIO_SELECTION');
  const capabilityId = selected.capability_id;
  if (capabilityId !== selection.capabilityId || selected.scenario_id !== selection.scenarioId) throw new Error('SELECTION_DIVERGENCE');
  if ([authority, resolutions, bundle.mechanics].some(r => r.truncated || r.snapshotId !== authority.snapshotId || r.projectionDigest !== authority.projectionDigest)) throw new Error('MIXED_DATABASE_AUTHORITY');
  const readiness = one(resolutions.recordsets[1].filter(r => r.target_language === 'node'), 'NODE_READINESS');
  if (readiness.readiness !== 'CAN_ATTEMPT_EMBODIMENT') throw new Error('NODE_BINDINGS_HELD');
  const requirements = resolutions.recordsets[0].filter(r => r.target_language === 'node');
  const records = [...authority.recordsets[1], ...authority.recordsets[2]].map(record => {
    const bytes = Buffer.from(record.content_bytes.base64, 'base64');
    if (hash(bytes) !== record.content_digest) throw new Error('SOURCE_BYTES_DIGEST_MISMATCH:' + record.source_path);
    return { ...record, bytes, text: bytes.toString('utf8') };
  });
  const documents = records.filter(r => r.source_path.endsWith('.json')).map(r => ({ ...r, value: json(r.text) }));
  const workspace = one(documents.filter(r => r.value.workspaceType === 'consumer-workspace-authority.v1'), 'WORKSPACE_AUTHORITY');
  const sourceAt = (from, reference) => one(records.filter(r => r.source_path === path.posix.normalize(path.posix.join(path.posix.dirname(from.source_path), reference))), 'SOURCE_REFERENCE:' + reference);
  const documentAt = (from, reference) => { const record = sourceAt(from, reference); return { ...record, value: json(record.text) }; };
  const capEntry = one(workspace.value.capabilities.filter(c => documentAt(workspace, c.capability).value.capabilityId === capabilityId), 'WORKSPACE_CAPABILITY');
  const capability = documentAt(workspace, capEntry.capability);
  const feature = sourceAt(workspace, capEntry.feature);
  const execution = documentAt(workspace, capEntry.executionAuthorities);
  const graphAuthority = documentAt(workspace, capEntry.semanticGraph);
  const interfaces = documentAt(workspace, capEntry.interfaces);
  const fixtures = documentAt(workspace, capEntry.fixtures);
  const platform = one(documents.filter(r => r.value.sdaPlatform?.commit), 'PINNED_PLATFORM_PACKAGE');
  const registry = one(documents.filter(r => r.value.registryType && r.value.language === 'node'), 'NODE_REGISTRY');
  const commit = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: sdaRoot, encoding: 'utf8' }).trim();
  if (commit !== platform.value.sdaPlatform.commit) throw new Error('PHYSICAL_PLATFORM_COMMIT_MISMATCH');
  const dirty = execFileSync('git', ['diff', '--name-only', commit, '--', 'tools/src', 'languages/typescript', 'package.json'], { cwd: sdaRoot, encoding: 'utf8' }).trim();
  if (dirty) throw new Error('PHYSICAL_PLATFORM_SOURCE_MODIFIED:' + dirty);
  const load = relative => import(pathToFileURL(path.join(sdaRoot, relative)));
  const { AnnotatedGherkinParser } = await load('artifacts/tools/dist/adapters/consumer-projection/annotated-gherkin-parser.js');
  const { GherkinScenarioGraphBuilder } = await load('artifacts/tools/dist/consumer-projection/authority/gherkin-scenario-graph-builder.js');
  const { SemanticTransitionGraphBuilder } = await load('artifacts/tools/dist/consumer-projection/authority/semantic-transition-graph-builder.js');
  const { SemanticExecutionGraphCompiler } = await load('languages/typescript/runtimes/node/semantic-execution-graph/index.js');
  const allScenarios = new GherkinScenarioGraphBuilder(new AnnotatedGherkinParser()).build(feature.text);
  const closure = resolutions.recordsets[2];
  if (closure.some(r => r.cycle_detected)) throw new Error('SCENARIO_INVOCATION_CYCLE');
  const scenarios = closure.map(r => one(allScenarios.filter(s => s.scenarioId === r.downstream_scenario_id), 'SCENARIO_SOURCE_RESOLUTION'));
  const executionAuthorities = scenarios.map(s => one(execution.value.executionAuthorities.filter(a => a.id === s.event.executionAuthorityId && a.owningScenarioId === s.scenarioId), 'EVENT_AUTHORITY_RESOLUTION'));
  const transitions = new SemanticTransitionGraphBuilder().build(graphAuthority.value, Object.fromEntries(allScenarios.map(s => [s.scenarioId, s])));
  // This provider currently lowers ordered invocations. Other topology remains held.
  if (transitions.some(t => scenarios.some(s => s.scenarioId === t.from.scenarioId))) throw new Error('NATIVE_TRANSITION_TRANSLATION_NOT_AVAILABLE');
  const provenance = { scenarioSourceRef: feature.source_path, executionSourceRef: execution.source_path, interfaceSourceRef: interfaces.source_path, ports: {} };
  const semanticTransformations = [];
  const interfaceAuthority = structuredClone(interfaces.value);
  for (const binding of interfaceAuthority.portBindings) {
    const ref = binding.configuration?.transformationAuthorityRef;
    if (!ref) continue;
    const source = documentAt(interfaces, ref);
    const transformation = one(source.value.transformations.filter(t => t.id === binding.configuration.transformationId), 'TRANSFORMATION_RESOLUTION');
    binding.configuration.expression = transformation.expression;
    provenance.ports[binding.portId] = { id: transformation.id, sourceRef: source.source_path, sourceDigest: source.content_digest };
    semanticTransformations.push(transformation);
  }
  const graphInput = { capability: capability.value, scenarios: allScenarios, transitions,
    executionAuthorities: execution.value.executionAuthorities, interfaceAuthority, semanticTransformations,
    sourceRefs: [capability.source_path, feature.source_path, execution.source_path, graphAuthority.source_path, interfaces.source_path, ...new Set(Object.values(provenance.ports).map(p => p.sourceRef))] };
  const compiledGraph = new SemanticExecutionGraphCompiler().compile(graphInput);
  const nativeBindings = [...new Map(requirements.filter(r => r.requirement_kind === 'MECHANIC').map(r => [r.implementation_id + ':' + r.implementation_export, r])).values()];
  const native = one(nativeBindings, 'NATIVE_MECHANIC_PROVIDER');
  const mechanicSource = await fs.readFile(path.join(sdaRoot, native.implementation_id), 'utf8');
  const provider = new NodeConsumerObjectProvider({ typescript: ts, mechanicSource, mechanicSourceRef: native.implementation_id,
    mechanicExport: native.implementation_export,
    mechanicDeclarations: bundle.mechanics.recordsets[0].map(r => json(r.definition_json)), provenance,
    resolvedTransformationPorts: registry.value.eventPorts.filter(p => p.invocation === 'transformation' && p.providerExport === native.implementation_export && path.posix.join(registry.value.providerModuleRoot, p.providerModule) === native.implementation_id).map(p => p.platformCapabilityId) });
  const files = provider.render({ repositoryRoot: sdaRoot, workspaceRoot: path.posix.dirname(workspace.source_path), capabilityId,
    interfaceAuthority, query: { authorityGraph: { scenarios, executionAuthorities } } });
  const contractCatalog = documentAt(interfaces, interfaces.value.contractCatalog);
  const contracts = {};
  const contractSources = [];
  const requiredContracts = new Set(scenarios.flatMap(s => [s.input.contract.contractId, s.outcome.contract.contractId]));
  for (const id of requiredContracts) if (!Object.hasOwn(contractCatalog.value, id)) throw new Error('SCENARIO_CONTRACT_NOT_IN_CATALOG:' + id);
  // The declared catalog includes schemas referenced by I/O contracts through
  // $id/$ref. Supplying only the direct I/O schemas breaks that authority closure.
  for (const id of Object.keys(contractCatalog.value)) {
    const ref = contractCatalog.value[id];
    if (!ref) throw new Error('CONTRACT_CATALOG_REFERENCE_MISSING:' + id);
    const source = documentAt(contractCatalog, ref);
    contracts[id] = { schemaRef: source.source_path, schemaId: source.value.$id, schemaDigest: hash(JSON.stringify(source.value)).slice(7), schema: source.value };
    contractSources.push({ id, source });
  }
  const admission = one(registry.value.contractAdmissions.filter(a => a.platformCapabilityId === interfaces.value.contractValidatorCapabilityId && a.kind === 'direct'), 'REAL_CONTRACT_ADMISSION');
  const admissionModule = path.posix.join(registry.value.providerModuleRoot, admission.providerModule);
  const { JsonSchemaTypeGraphBuilder } = await load('artifacts/tools/dist/projection/ir/json-schema-type-graph-builder.js');
  const { TargetProjectionGraphBuilder } = await load('artifacts/tools/dist/projection/ir/target-projection-graph-builder.js');
  const { NodeStructuralProjectionProvider } = await load('artifacts/tools/dist/projection/providers/node/structural-projection-provider.js');
  const structuralProfile = json(await fs.readFile(path.join(sdaRoot, 'languages/typescript/projection/scenario-kernel-node.projection.json'), 'utf8'));
  const schemaRef = source => source.value.$id ?? source.source_path;
  const schemaViews = contractSources.map(c => ({ ...c, ...NodeConsumerObjectProvider.schemaForTypeProjection(c.source.value, c.source.source_path) }));
  const profile = { ...structuralProfile, objects: contractSources.map(({ id, source }) => ({ schemaRef: schemaRef(source), typeName: name(id) })), outputDirectory: 'contracts' };
  const typeRoots = schemaViews.filter(c => requiredContracts.has(c.id) || c.schema.type === 'object').map(c => schemaRef(c.source));
  const canonicalTypes = new JsonSchemaTypeGraphBuilder(ref => one(schemaViews.filter(c => c.source.source_path === ref || c.source.value.$id === ref), 'CONTRACT_SCHEMA_SOURCE:' + ref).schema).build(typeRoots);
  profile.objects = profile.objects.filter(object => canonicalTypes.roots.some(root => root.schemaRef === object.schemaRef));
  const contractPlan = NodeConsumerObjectProvider.renderContracts(new TargetProjectionGraphBuilder(canonicalTypes, profile).build(), profile, new NodeStructuralProjectionProvider(), ts);
  const copied = new Map();
  const copyRuntime = async relative => {
    if (copied.has(relative)) return;
    if (relative.startsWith('../') || path.isAbsolute(relative)) throw new Error('NATIVE_IMPORT_OUTSIDE_PLATFORM');
    const content = await fs.readFile(path.join(sdaRoot, relative), 'utf8');
    copied.set(relative, content);
    const ast = ts.createSourceFile(relative, content, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
    const imports = [];
    const visit = node => {
      if ((ts.isImportDeclaration(node) || ts.isExportDeclaration(node)) && node.moduleSpecifier && ts.isStringLiteral(node.moduleSpecifier)) imports.push(node.moduleSpecifier.text);
      if (ts.isCallExpression(node) && node.arguments.length === 1 && ts.isStringLiteral(node.arguments[0]) && (node.expression.kind === ts.SyntaxKind.ImportKeyword || node.expression.getText(ast) === 'require')) imports.push(node.arguments[0].text);
      ts.forEachChild(node, visit);
    };
    visit(ast);
    for (const ref of imports) if (ref.startsWith('.')) await copyRuntime(path.posix.normalize(path.posix.join(path.posix.dirname(relative), ref)));
  };
  const kernelPaths = ['languages/typescript/dist/src/kernel/scenario-kernel.js', 'languages/typescript/dist/src/kernel/disposition-resolver.js', admissionModule];
  for (const relative of kernelPaths) await copyRuntime(relative);
  const primitivesRef = path.posix.join(path.posix.dirname(native.implementation_id), 'native-mechanic-primitives.mjs');
  const primitives = await fs.readFile(path.join(sdaRoot, primitivesRef), 'utf8');
  const add = (relativePath, content, sourcePointers = []) => files.push({ relativePath, content, digest: hash(content), sourcePointers, target: 'node' });
  const resolverFile = fileURLToPath(new URL('./resolvers/node/consumer-object-provider.mjs', import.meta.url));
  const resolverDigest = hash(await fs.readFile(resolverFile));
  const outputBases = [];
  for (const scenario of scenarios) {
    const base = `embodiments/${encodeURIComponent(capabilityId)}/scenarios/${encodeURIComponent(scenario.scenarioId)}/node`;
    outputBases.push(base);
    const dependencies = json(one(files.filter(f => f.relativePath === base + '/body/dependencies.json'), 'GENERATED_DEPENDENCIES').content);
    for (const file of contractPlan.files) add(`${base}/body/contracts/${file.relativePath}`, file.content, file.sourcePointers);
    add(`${base}/body/contracts/authority.json`, pretty({ contracts }), contractSources.map(c => c.source.source_path));
    add(`${base}/body/providers/native-mechanic-primitives.mjs`, primitives, [primitivesRef]);
    for (const [ref, content] of copied) add(`${base}/body/providers/sda/${ref}`, content, [ref]);
    add(`${base}/body/package.json`, pretty({ private: true, type: 'module', engines: platform.value.engines, dependencies: { ajv: platform.value.dependencies.ajv } }), [platform.source_path]);
    const imports = dependencies.map((d, i) => d.kind === 'invoke-port'
      ? `import { ${d.className} as Dependency${i} } from ${JSON.stringify(d.module)};`
      : `import { createScenario as dependency${i} } from ${JSON.stringify(d.module.replace(/scenario\.mjs$/, 'composition.mjs'))};`).join('\n');
    add(`${base}/body/composition.mjs`, `import fs from 'node:fs';\nimport { ${name(scenario.scenarioId)}Scenario } from './scenario.mjs';\nimport { ${admission.providerExport} } from './providers/sda/${admissionModule}';\n${imports}\n\nexport function createScenario({ observer, clock, observeMechanic }) {\n  const contracts = ${admission.providerExport}(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));\n  return new ${name(scenario.scenarioId)}Scenario({\n${dependencies.map((d, i) => `    ${JSON.stringify(d.id)}: ${d.kind === 'invoke-port' ? `new Dependency${i}(undefined, observation => observeMechanic?.({ ...observation, scenarioId: ${JSON.stringify(scenario.scenarioId)}, portId: ${JSON.stringify(d.id)} }))` : `dependency${i}({ observer, clock, observeMechanic })`}`).join(',\n')}\n  }, contracts, observer, clock);\n}\n`, [interfaces.source_path, execution.source_path, registry.source_path]);
    add(`${base}/evidence/authority.json`, pretty({ selection, selected, snapshotId: authority.snapshotId, projectionDigest: authority.projectionDigest,
      query: { inputDigest: authority.inputDigest, resultDigest: authority.resultDigest, resolutionDigest: resolutions.resultDigest },
      sources: records.map(({ text, bytes, content_bytes, ...r }) => r), scenario, executionAuthorities, nativeBinding: native,
      pinnedPlatformCommit: commit, resolver: { path: resolverFile, digest: resolverDigest, status: 'CANDIDATE_PHYSICAL_PROVIDER' } }));
    add(`${base}/evidence/fixture-authority.json`, fixtures.text, [fixtures.source_path]);
    add(`${base}/evidence/contract-projection.json`, pretty(schemaViews.map(c => ({ contractId: c.id, sourceRef: c.source.source_path, sourceDigest: c.source.content_digest,
      typeProjectionSchemaDigest: hash(pretty(c.schema)), changes: c.changes, runtimeAdmission: 'ORIGINAL_SCHEMA_UNCHANGED' }))));
    add(`${base}/evidence/mechanic-lineage.json`, pretty(provider.lineage.filter(l => l.scenarioId === scenario.scenarioId)));
    add(`${base}/evidence/canonical-execution-graph.json`, pretty(compiledGraph));
    add(`${base}/evidence/target-readiness.json`, pretty(resolutions.recordsets[1]));
  }
  const printer = ts.createPrinter({ newLine: ts.NewLineKind.LineFeed });
  // Format generated code for inspection; copied native runtime bytes stay exact.
  for (const file of files) {
    if (file.relativePath.endsWith('.mjs') && !file.relativePath.includes('/providers/sda/') && !file.relativePath.endsWith('/native-mechanic-primitives.mjs')) {
      const ast = ts.createSourceFile(file.relativePath, file.content, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
      if (ast.parseDiagnostics.length) throw new Error('GENERATED_SYNTAX_INVALID:' + file.relativePath);
      file.content = printer.printFile(ast);
      file.digest = hash(file.content);
    }
  }
  if (new Set(files.map(f => f.relativePath.toLowerCase())).size !== files.length) throw new Error('PHYSICAL_OUTPUT_COLLISION');
  const write = async (relative, content) => {
    const target = path.resolve(outputRoot, relative);
    if (!target.startsWith(path.resolve(outputRoot) + path.sep)) throw new Error('OUTPUT_OUTSIDE_EMBODIMENT_LOCATION');
    await fs.mkdir(path.dirname(target), { recursive: true });
    await fs.writeFile(target, content);
  };
  for (const file of files) await write(file.relativePath, file.content);
  for (const base of outputBases) {
    const body = files.filter(f => f.relativePath.startsWith(base + '/body/')).map(({ content, ...file }) => file);
    const scenarioId = one(scenarios.filter(s => base === `embodiments/${encodeURIComponent(capabilityId)}/scenarios/${encodeURIComponent(s.scenarioId)}/node`), 'PHYSICAL_SCENARIO_BINDING').scenarioId;
    const plan = { capabilityId, scenarioId, target: 'node', resolverDigest, files: body };
    await write(base + '/evidence/embodiment-plan.json', pretty(plan));
    await write(base + '/embodiment.receipt.json', pretty({ capabilityId, scenarioId, target: 'node',
      profile: 'full-mechanics', scenarioDefinitionDigest: 'sha256:' + Buffer.from(one(closure.filter(r => r.downstream_scenario_id === scenarioId), 'SCENARIO_DIGEST').scenario_definition_digest.base64, 'base64').toString('hex'),
      embodimentPlanDigest: hash(pretty(plan)), resolverVersion: resolverDigest, pinnedPlatformCommit: commit,
      providers: [...new Set(requirements.filter(r => r.downstream_scenario_id === scenarioId).flatMap(r => [r.provider_id, r.provider_profile_id]).filter(Boolean))],
      artifactDigest: hash(pretty(body)), revealDigest: null, disposition: 'MATERIALIZED_AWAITING_EXECUTION',
      managedAdmission: 'NOT_REQUESTED', resolverStatus: 'CANDIDATE_PHYSICAL_PROVIDER' }));
  }
  return { capabilityId, selectedScenarioId: selection.scenarioId, outputBases: outputBases.map(b => path.resolve(outputRoot, b)), files: files.length };
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try {
    const [bundleFile, sdaRoot, outputRoot] = process.argv.slice(2);
    console.log(pretty(await materializeNode({ bundleFile, sdaRoot, outputRoot })));
  } catch (error) { console.error(error.stack); process.exitCode = 1; }
}
