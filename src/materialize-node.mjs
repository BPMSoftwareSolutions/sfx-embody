import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { NodeConsumerObjectProvider } from './resolvers/node/consumer-object-provider.mjs';
import { locateNativeRegions } from './resolvers/node/native-expression-projection.mjs';
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
  const trackedPaths = ['tools/src', 'languages/typescript', 'package.json'];
  const dirty = execFileSync('git', ['diff', '--name-only', commit, '--', ...trackedPaths], { cwd: sdaRoot, encoding: 'utf8' }).trim();
  if (dirty) throw new Error('PHYSICAL_PLATFORM_SOURCE_MODIFIED:' + dirty);
  const untracked = execFileSync('git', ['ls-files', '--others', '--exclude-standard', '--', ...trackedPaths], { cwd: sdaRoot, encoding: 'utf8' }).trim();
  if (untracked) throw new Error('PHYSICAL_PLATFORM_SOURCE_UNTRACKED:' + untracked);
  // The commit pin cannot speak for built output: dist/ is ignored in the
  // platform repository, so neither the compiler chain nor the copied kernel is
  // under revision control. Integrity for those comes from digesting the exact
  // bytes this run reads. Every platform read goes through readPlatform, so the
  // verified set is the set that was actually loaded rather than a second list.
  const platformFiles = new Map();
  const readPlatform = async relative => {
    const normalized = path.posix.normalize(relative);
    if (normalized.startsWith('../') || path.isAbsolute(normalized)) throw new Error('PLATFORM_READ_OUTSIDE_ROOT:' + relative);
    const bytes = await fs.readFile(path.join(sdaRoot, normalized));
    platformFiles.set(normalized, hash(bytes));
    return bytes;
  };
  const moduleImports = (relative, content) => {
    const ast = ts.createSourceFile(relative, content, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
    const found = [];
    const visit = node => {
      if ((ts.isImportDeclaration(node) || ts.isExportDeclaration(node)) && node.moduleSpecifier && ts.isStringLiteral(node.moduleSpecifier)) found.push(node.moduleSpecifier.text);
      if (ts.isCallExpression(node) && node.arguments.length === 1 && ts.isStringLiteral(node.arguments[0]) && (node.expression.kind === ts.SyntaxKind.ImportKeyword || node.expression.getText(ast) === 'require')) found.push(node.arguments[0].text);
      ts.forEachChild(node, visit);
    };
    visit(ast);
    return found;
  };
  // A platform module is only as trustworthy as its transitive relative imports,
  // which are what actually execute once it is loaded.
  const readPlatformModule = async relative => {
    const normalized = path.posix.normalize(relative);
    if (platformFiles.has(normalized)) return;
    const content = (await readPlatform(normalized)).toString('utf8');
    for (const ref of moduleImports(normalized, content)) {
      if (ref.startsWith('.')) await readPlatformModule(path.posix.join(path.posix.dirname(normalized), ref));
    }
  };
  const load = async relative => { await readPlatformModule(relative); return import(pathToFileURL(path.join(sdaRoot, relative))); };
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
  const mechanicSource = (await readPlatform(native.implementation_id)).toString('utf8');
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
  const structuralProfile = json((await readPlatform('languages/typescript/projection/scenario-kernel-node.projection.json')).toString('utf8'));
  const schemaRef = source => source.value.$id ?? source.source_path;
  const schemaViews = contractSources.map(c => ({ ...c, ...NodeConsumerObjectProvider.schemaForTypeProjection(c.source.value, c.source.source_path) }));
  const profile = { ...structuralProfile, objects: contractSources.map(({ id, source }) => ({ schemaRef: schemaRef(source), typeName: name(id) })), outputDirectory: 'contracts' };
  const typeRoots = schemaViews.filter(c => requiredContracts.has(c.id) || c.schema.type === 'object').map(c => schemaRef(c.source));
  const canonicalTypes = new JsonSchemaTypeGraphBuilder(ref => one(schemaViews.filter(c => c.source.source_path === ref || c.source.value.$id === ref), 'CONTRACT_SCHEMA_SOURCE:' + ref).schema).build(typeRoots);
  profile.objects = profile.objects.filter(object => canonicalTypes.roots.some(root => root.schemaRef === object.schemaRef));
  const schemaAt = pointer => {
    const [ref, fragment = ''] = pointer.split('#');
    const source = one(schemaViews.filter(c => c.source.source_path === ref || c.source.value.$id === ref), 'CONTRACT_POINTER_SOURCE:' + ref);
    return fragment.split('/').filter(Boolean).reduce((value, segment) => value[segment.replaceAll('~1', '/').replaceAll('~0', '~')], source.schema);
  };
  const contractPlan = NodeConsumerObjectProvider.renderContracts(new TargetProjectionGraphBuilder(canonicalTypes, profile).build(), profile, new NodeStructuralProjectionProvider(), ts, canonicalTypes, schemaAt);
  const copied = new Map();
  const copyRuntime = async relative => {
    if (copied.has(relative)) return;
    if (relative.startsWith('../') || path.isAbsolute(relative)) throw new Error('NATIVE_IMPORT_OUTSIDE_PLATFORM');
    const content = (await readPlatform(relative)).toString('utf8');
    copied.set(relative, content);
    for (const ref of moduleImports(relative, content)) if (ref.startsWith('.')) await copyRuntime(path.posix.normalize(path.posix.join(path.posix.dirname(relative), ref)));
  };
  const kernelPaths = ['languages/typescript/dist/src/kernel/scenario-kernel.js', 'languages/typescript/dist/src/kernel/disposition-resolver.js', admissionModule];
  for (const relative of kernelPaths) await copyRuntime(relative);
  const primitivesRef = path.posix.join(path.posix.dirname(native.implementation_id), 'native-mechanic-primitives.mjs');
  const primitives = (await readPlatform(primitivesRef)).toString('utf8');
  const add = (relativePath, content, sourcePointers = []) => files.push({ relativePath, content, digest: hash(content), sourcePointers, target: 'node' });
  const resolverFile = fileURLToPath(new URL('./resolvers/node/consumer-object-provider.mjs', import.meta.url));
  const resolverComponents = await Promise.all(['src/resolvers/node/consumer-object-provider.mjs', 'src/resolvers/node/native-expression-projection.mjs'].map(async name => ({ name, digest: hash(await fs.readFile(new URL('../' + name, import.meta.url))) })));
  const resolverDigest = hash(pretty(resolverComponents));
  const platformSurface = [...platformFiles].sort(([a], [b]) => a.localeCompare(b)).map(([file, digest]) => ({ file, digest }));
  const platformDigest = hash(pretty(platformSurface));
  const bodyPorts = base => provider.lineage.filter(port => port.physicalFile.startsWith(base + '/body/'));
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
    const imports = dependencies.map(d => d.kind === 'invoke-port'
      ? `import { ${d.className} } from ${JSON.stringify(d.module)};`
      : `import { createScenario as create${d.className} } from ${JSON.stringify(d.module.replace(/scenario\.mjs$/, 'composition.mjs'))};`).join('\n');
    add(`${base}/body/composition.mjs`, `import fs from 'node:fs';\nimport { ${name(scenario.scenarioId)}Scenario } from './scenario.mjs';\nimport { ${admission.providerExport} } from './providers/sda/${admissionModule}';\n${imports}\n\nexport function createScenario({ observer, clock }) {\n  const contracts = ${admission.providerExport}(JSON.parse(fs.readFileSync(new URL('./contracts/authority.json', import.meta.url), 'utf8')));\n  return new ${name(scenario.scenarioId)}Scenario({\n${dependencies.map(d => `    ${JSON.stringify(d.id)}: ${d.kind === 'invoke-port' ? `new ${d.className}()` : `create${d.className}({ observer, clock })`}`).join(',\n')}\n  }, contracts, observer, clock);\n}\n`, [interfaces.source_path, execution.source_path, registry.source_path]);
    add(`${base}/evidence/authority.json`, pretty({ selection, selected, snapshotId: authority.snapshotId, projectionDigest: authority.projectionDigest,
      query: { inputDigest: authority.inputDigest, resultDigest: authority.resultDigest, resolutionDigest: resolutions.resultDigest },
      sources: records.map(({ text, bytes, content_bytes, ...r }) => r), scenario, executionAuthorities, nativeBinding: native,
      pinnedPlatformCommit: commit, platform: { commit, digest: platformDigest, files: platformSurface },
      resolver: { path: resolverFile, digest: resolverDigest, components: resolverComponents, status: 'CANDIDATE_PHYSICAL_PROVIDER' } }));
    add(`${base}/evidence/fixture-authority.json`, fixtures.text, [fixtures.source_path]);
    add(`${base}/evidence/contract-projection.json`, pretty(schemaViews.map(c => ({ contractId: c.id, sourceRef: c.source.source_path, sourceDigest: c.source.content_digest,
      typeProjectionSchemaDigest: hash(pretty(c.schema)), changes: c.changes, runtimeAdmission: 'ORIGINAL_SCHEMA_UNCHANGED' }))));
    add(`${base}/evidence/contract-types.json`, pretty(contractPlan.contractTypes));
    // Test expressions may compose auxiliary pure mechanics (e.g. literal).
    // Retain their real database declarations too; production bindings remain
    // the selected requirements and per-port native lineage above.
    add(`${base}/evidence/mechanic-authority.json`, pretty(bundle.mechanics.recordsets[0].map(r => json(r.definition_json)).filter(d => d.semantics.mechanic?.authoringForm)));
    add(`${base}/evidence/transformation-authority.json`, pretty(bodyPorts(base).map(l => {
      const source = one(records.filter(r => r.source_path === l.sourceRef), 'TRANSFORMATION_SOURCE');
      return { portId: l.portId, transformationId: l.transformationId, sourceRef: l.sourceRef, sourceDigest: l.sourceDigest, contentBase64: source.bytes.toString('base64') };
    })));
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
      const port = provider.lineage.find(port => port.physicalFile === file.relativePath);
      if (port) file.content = await locateNativeRegions(ts, file.content, port.nodes, file.relativePath);
      file.digest = hash(file.content);
    }
  }
  for (const base of outputBases) add(`${base}/evidence/mechanic-lineage.json`, pretty(bodyPorts(base)));
  // Every module specifier the generated helper module carries must resolve to a
  // file this run placed in the same body, or to a Node builtin. One rule for all
  // native code entering a body, whether it was copied or emitted.
  for (const base of outputBases) {
    for (const ref of provider.emittedImports) {
      if (ref.startsWith('node:')) continue;
      if (!ref.startsWith('.')) throw new Error('NATIVE_IMPORT_NOT_RESOLVABLE_IN_BODY:' + ref);
      const resolved = path.posix.normalize(path.posix.join(base + '/body/providers', ref));
      if (!files.some(f => f.relativePath === resolved)) throw new Error('NATIVE_IMPORT_NOT_PLACED_IN_BODY:' + ref);
    }
  }
  if (new Set(files.map(f => f.relativePath.toLowerCase())).size !== files.length) throw new Error('PHYSICAL_OUTPUT_COLLISION');
  const write = async (relative, content) => {
    const target = path.resolve(outputRoot, relative);
    if (!target.startsWith(path.resolve(outputRoot) + path.sep)) throw new Error('OUTPUT_OUTSIDE_EMBODIMENT_LOCATION');
    await fs.mkdir(path.dirname(target), { recursive: true });
    await fs.writeFile(target, content);
  };
  // Retire only previously generated files whose bytes still match their plan.
  // Never remove an unplanned file or silently overwrite an inspected body edit.
  const stale = [];
  for (const base of outputBases) {
    const previous = await fs.readFile(path.resolve(outputRoot, base, 'evidence/embodiment-plan.json'), 'utf8').then(json, e => { if (e.code !== 'ENOENT') throw e; return null; });
    for (const file of previous?.files ?? []) {
      const target = path.resolve(outputRoot, file.relativePath);
      if (!target.startsWith(path.resolve(outputRoot, base, 'body') + path.sep)) throw new Error('PREVIOUS_PLAN_PATH_OUTSIDE_BODY');
      const bytes = await fs.readFile(target).catch(e => { if (e.code !== 'ENOENT') throw e; return null; });
      if (bytes && hash(bytes) !== file.digest) throw new Error('GENERATED_BODY_MODIFIED:' + file.relativePath);
      if (bytes && !files.some(f => f.relativePath === file.relativePath)) stale.push(target);
    }
  }
  for (const file of files) await write(file.relativePath, file.content);
  for (const target of stale) await fs.unlink(target);
  for (const base of outputBases) {
    const body = files.filter(f => f.relativePath.startsWith(base + '/body/')).map(({ content, ...file }) => file);
    const scenarioId = one(scenarios.filter(s => base === `embodiments/${encodeURIComponent(capabilityId)}/scenarios/${encodeURIComponent(s.scenarioId)}/node`), 'PHYSICAL_SCENARIO_BINDING').scenarioId;
    const plan = { capabilityId, scenarioId, target: 'node', resolverDigest, files: body };
    await write(base + '/evidence/embodiment-plan.json', pretty(plan));
    await write(base + '/embodiment.receipt.json', pretty({ capabilityId, scenarioId, target: 'node',
      profile: 'full-mechanics', scenarioDefinitionDigest: 'sha256:' + Buffer.from(one(closure.filter(r => r.downstream_scenario_id === scenarioId), 'SCENARIO_DIGEST').scenario_definition_digest.base64, 'base64').toString('hex'),
      embodimentPlanDigest: hash(pretty(plan)), resolverVersion: resolverDigest, pinnedPlatformCommit: commit, platformDigest,
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
