import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { isDeepStrictEqual } from 'node:util';
import { pathToFileURL } from 'node:url';
import ts from 'typescript';
import { NodeConsumerObjectProvider } from '../resolvers/node/consumer-object-provider.mjs';
import { NativeExpressionProjection, nativeDigest, nativeSyntax, locateNativeRegions } from '../resolvers/node/native-expression-projection.mjs';
import { revealNativeExpressions, comparableExpression, unwrap } from '../reveal-native-expressions.mjs';

const read = async file => JSON.parse(await fs.readFile(file, 'utf8'));
const pretty = value => JSON.stringify(value, null, 2) + '\n';
const normalized = expression => JSON.stringify(comparableExpression(expression));
const L = value => ({ op: 'literal', value });
const P = (path = '', from = 'input') => ({ op: 'path', from, path });
const vectorProofCache = new Map();
// Each entry names a semantic distinction the reveal asserts. Textual so it can
// be applied to any emitted body without re-deriving its AST.
const mutationSet = [
  { label: 'strict equality', from: ' === ', to: ' !== ' },
  { label: 'ordering comparison', from: ' > ', to: ' < ' },
  { label: 'path optionality', from: '?.', to: '.' },
  { label: 'mechanic identity', from: 'JSON.stringify(', to: 'JSON.parse(' },
  { label: 'collection mapping', from: '.flatMap(', to: '.map(' },
  { label: 'collection quantifier', from: '.some(', to: '.every(' },
  { label: 'string casing', from: '.toLowerCase(', to: '.trim(' },
  { label: 'digest algorithm', from: "'sha256'", to: "'sha512'" },
];

function observeGraph(value, seen = new Map()) {
  if (value === null || typeof value !== 'object') {
    if (typeof value === 'function') return { function: String(value) };
    if (Object.is(value, -0)) return { number: '-0' };
    if (value === undefined) return { undefined: true };
    return value;
  }
  if (seen.has(value)) return { reference: seen.get(value) };
  const identity = seen.size; seen.set(value, identity);
  const prototype = Object.getPrototypeOf(value);
  return { identity, prototype: prototype === Object.prototype ? 'Object.prototype' : prototype === Array.prototype ? 'Array.prototype' : observeGraph(prototype, seen),
    properties: Object.getOwnPropertyNames(value).map(key => [key, observeGraph(value[key], seen)]) };
}

function vectors() {
  const cases = [];
  const add = (label, expression, input = {}, root = input) => cases.push({ label, expression, input, root });
  for (const value of [null, false, 0, -0, '', [], { nested: [{ op: 'not-an-expression', value: 4 }] }, JSON.parse('{"__proto__":{"x":1}}')]) add('literal allocation and value', L(value));
  for (const value of [null, {}, { a: null }, { a: { b: 3 } }, ['a']]) for (const key of ['', 'a.b', '.a..b.', '0', 'missing']) add('path null and absence', P(key), value);
  add('path root binding', P('value', 'root'), { value: 1 }, { value: 2 });
  add('path undeclared binding', P('', 'absent'), {});
  add('object key and evaluation semantics', { op: 'object', fields: JSON.parse('{"__proto__":{"op":"literal","value":1},"2":{"op":"literal","value":2},"a":{"op":"path","path":"missing"}}') });
  add('array preserves undefined', { op: 'array', items: [P('missing'), L(null), L({ value: 1 })] });
  for (const value of [null, {}, { a: 1 }, JSON.parse('{"__proto__":{"x":1}}')]) add('merge order and prototype semantics', { op: 'merge', values: [L(value), L({ a: 2 })] });
  for (const [left, right] of [[0, false], [0, -0], [null, null], [1, '1'], [{}, {}]]) {
    add('strict equality', { op: 'equals', left: L(left), right: L(right) });
    add('native comparison', { op: 'greater-than', left: L(left), right: L(right) });
  }
  add('shared reference equality', { op: 'equals', left: P('shared'), right: P('shared') }, { shared: {} });
  add('distinct literal identities', { op: 'equals', left: L({}), right: L({}) });
  for (const value of ['', [], [1, 2], null, {}]) add('length operand boundary', { op: 'length', value: L(value) });
  for (const value of [[], [1, '1'], 'ab', null]) add('includes operand boundary', { op: 'includes', in: L(value), value: L(1) });
  for (const value of [true, false, null, 0, [], {}]) {
    add('conditional truthiness', { op: 'if', when: L(value), then: L('taken'), else: L('alternative') });
    add('lazy conditional', { op: 'if', when: L(value), then: L('taken'), else: { op: 'parse-json', value: L('invalid json') } });
    add('lazy conditional missing length', { op: 'if', when: L(value), then: L('taken'), else: { op: 'length', value: L(null) } });
  }
  for (const op of ['map', 'flat-map', 'filter', 'every', 'some', 'find']) for (const input of [[], [0, 1, 2], [null, {}]]) add('iteration order, index and empty collection', {
    op, from: P(), as: 'member', ...(op === 'map' || op === 'flat-map' ? { value: { op: 'array', items: [P('', 'member'), P('', 'memberIndex')] } } : { where: P('', 'member') })
  }, input);
  add('sequential let and shadowing', { op: 'let', bindings: { input: P('initial'), result: P('', 'input') }, value: P('', 'result') }, { initial: 7 });
  add('nested let shadowing', { op: 'let', bindings: { result: L(1), nested: { op: 'let', bindings: { result: L(2) }, value: P('', 'result') } }, value: { op: 'array', items: [P('', 'result'), P('', 'nested')] } });
  add('escaped binding identities', { op: 'let', bindings: { 'x-y': L(2), return: L(3), Object: L(4) }, value: { op: 'array', items: [P('', 'x-y'), P('', 'return'), P('', 'Object')] } });
  for (const value of [[], ['a', null, 'b']]) for (const separator of ['', '|']) add('join separators', { op: 'join', value: L(value), separator });
  add('format replacement order', { op: 'format', template: '{a}/{b}', values: { a: L('{b}'), b: L('$&') } });
  for (const op of ['sha256', 'base64-decode-utf8', 'json-stringify', 'parse-json', 'try-parse-json', 'canonicalize', 'trim', 'lower-case', 'escape-html', 'object-values', 'unique']) for (const value of ['', 'eA==', '{"x":1}', '{', null, { b: 2, a: [{ z: 1, a: 2 }] }, ' <A&B>\"\'  ', [1, 1, 2]]) add(op + ' boundary', { op, value: L(value) });
  for (const [left, right] of [[[], []], [[1, 2], [2]], [[1], ['1']], [null, []]]) add('intersection membership and operand order', { op: 'intersects', left: L(left), right: L(right) });
  add('graph closure rejects malformed input', { op: 'directed-graph-closure', value: L(null) });
  add('graph closure reachability and cycle', { op: 'directed-graph-closure', value: P() }, {
    nodeIds: ['root', 'terminal'], edges: [{ edgeId: 'forward', from: 'root', to: 'terminal' }, { edgeId: 'return', from: 'terminal', to: 'root' }], rootNodeIds: ['root'], terminalNodeIds: ['terminal']
  });
  return cases;
}

export async function verifyNativeProjection(base, sdaRoot, outputRoot, pureCalls = []) {
  const authority = await read(path.join(base, 'evidence/authority.json'));
  const ports = await read(path.join(base, 'evidence/mechanic-lineage.json'));
  const retained = await read(path.join(base, 'evidence/transformation-authority.json'));
  const declarations = await read(path.join(base, 'evidence/mechanic-authority.json'));
  const sourceFile = path.join(sdaRoot, authority.nativeBinding.implementation_id);
  const source = await fs.readFile(sourceFile, 'utf8');
  const reference = (await import(pathToFileURL(sourceFile)))[authority.nativeBinding.implementation_export];
  const provider = new NodeConsumerObjectProvider({ typescript: ts, mechanicSource: source, mechanicSourceRef: authority.nativeBinding.implementation_id,
    mechanicExport: authority.nativeBinding.implementation_export, mechanicDeclarations: declarations, provenance: {}, resolvedTransformationPorts: [] });
  const sourceAst = ts.createSourceFile(sourceFile, source, ts.ScriptTarget.Latest, true);
  const helperNames = sourceAst.statements.filter(s => ts.isFunctionDeclaration(s) && s.name.text !== authority.nativeBinding.implementation_export).map(s => s.name.text);
  // The provider's helpers are module-local, so they are reached by loading the
  // provider's own bytes as a module beside the body's copied primitives, where
  // its relative imports resolve exactly as they do in a shipped body. A helper
  // that closes over an import or a sibling therefore behaves here as it does
  // there, instead of resolving by accident.
  const helperProbe = path.join(base, 'body/providers/native-mechanics.vectors.mjs');
  let helpers;
  try {
    await fs.writeFile(helperProbe, source + `
export { ${['crypto', ...helperNames].join(', ')} };
`);
    const loaded = await import(pathToFileURL(helperProbe).href + '?probe=' + nativeDigest(source).slice(7, 23));
    helpers = Object.fromEntries(['crypto', ...helperNames].map(name => [name, loaded[name]]));
  } finally { await fs.unlink(helperProbe).catch(() => {}); }
  for (const [name, value] of Object.entries(helpers)) assert.ok(value !== undefined, 'Native helper not resolvable from the provider module:' + name);
  // Finding: a failure is a result. Two executions are equivalent only when they
  // fail the same way, not merely in the same error class.
  const capture = action => { try { return { value: action() }; } catch (error) { return { error: { name: error.name, message: error.message } }; } };
  const equivalent = async (expression, input, root) => {
    const lower = new NativeExpressionProjection(ts, provider.mechanics, provider.bodies);
    const marked = lower.emit(expression);
    const code = marked.replace(/\/\*@sfx-node:\d+\*\//g, '');
    const physicalFile = 'native-mechanic-vector.mjs';
    const body = await locateNativeRegions(ts, `export class NativeMechanicVector { execute(input, root = input) { return ${marked}; } }`, lower.nodes, physicalFile);
    const revealed = revealNativeExpressions(ts, body, { physicalFile, nodes: lower.nodes, bindings: lower.bindings });
    assert.equal(normalized(revealed.expression), normalized(expression), 'Native mechanic vector round trip:' + expression.op);
    const fn = new Function('input', 'root', ...Object.keys(helpers), 'return ' + code);
    const first = structuredClone({ input, root }), second = structuredClone({ input, root });
    const expected = capture(() => reference(expression, first));
    const actual = capture(() => fn(second.input, second.root, ...Object.values(helpers)));
    return isDeepStrictEqual(observeGraph({ result: actual, scope: second }), observeGraph({ result: expected, scope: first }));
  };
  const corpus = vectors();
  const vectorKey = nativeDigest(source + JSON.stringify(declarations));
  const checkedVectors = vectorProofCache.get(vectorKey) ?? [];
  for (const vector of vectorProofCache.has(vectorKey) ? [] : corpus) {
    const operations = new Set();
    const visit = e => {
      const declaration = provider.mechanics.get(e.op); if (!declaration) { operations.add(e.op); return; }
      operations.add(e.op);
      for (const [key, shape] of Object.entries(declaration.semantics.mechanic.authoringForm.arguments)) {
        if (!Object.hasOwn(e, key)) continue;
        if (shape === 'semantic-expression') visit(e[key]);
        if (shape === 'expression-list') e[key].forEach(visit);
        if (shape === 'expression-map') Object.values(e[key]).forEach(visit);
      }
    };
    visit(vector.expression);
    if ([...operations].some(op => !provider.mechanics.has(op))) continue;
    const passed = await equivalent(vector.expression, vector.input, vector.root);
    checkedVectors.push({ ...vector, operations: [...operations], passed, roundTripPassed: true });
    assert.ok(passed, 'NATIVE_MECHANIC_DIFFERENTIAL:' + vector.label + ':' + JSON.stringify(vector.expression));
  }
  vectorProofCache.set(vectorKey, checkedVectors);
  const mechanicCoverage = [...provider.bodies.keys()].map(operation => ({ operation, vectors: checkedVectors.filter(v => v.operations.includes(operation)).length }));
  assert.deepEqual(mechanicCoverage.filter(m => !m.vectors), [], 'Every pure mechanic in the selected provider needs coverage');
  const printer = ts.createPrinter({ removeComments: true });
  const normalize = (node, ast) => printer.printNode(ts.EmitHint.Unspecified, node, ast);
  const recovered = [], behavioral = [], helperChecks = [];
  const helperFile = path.join(base, 'body/providers/native-mechanics.mjs');
  const helperAst = ts.createSourceFile(helperFile, await fs.readFile(helperFile, 'utf8'), ts.ScriptTarget.Latest, true);
  for (const name of new Set(ports.flatMap(p => p.helpers))) {
    if (name === 'crypto') {
      const imported = helperAst.statements.find(s => ts.isImportDeclaration(s) && s.importClause?.name?.text === name);
      assert.equal(imported?.moduleSpecifier.text, 'node:crypto');
    } else {
      const expected = sourceAst.statements.find(s => ts.isFunctionDeclaration(s) && s.name.text === name);
      const actual = helperAst.statements.find(s => ts.isFunctionDeclaration(s) && s.name.text === name);
      assert.ok(actual && normalize(actual, helperAst) === normalize(expected, sourceAst), 'Native helper source fidelity:' + name);
    }
    helperChecks.push({ name, passed: true });
  }
  for (const port of ports) {
    const body = await fs.readFile(path.join(outputRoot, port.physicalFile), 'utf8');
    const revelation = revealNativeExpressions(ts, body, port);
    const retainedSource = retained.find(r => r.portId === port.portId);
    const bytes = Buffer.from(retainedSource.contentBase64, 'base64');
    assert.equal(nativeDigest(bytes), retainedSource.sourceDigest);
    assert.ok(authority.sources.some(s => s.source_path === retainedSource.sourceRef && s.content_digest === retainedSource.sourceDigest));
    const document = JSON.parse(bytes.toString('utf8').replace(/^\uFEFF/, ''));
    const expected = document.transformations.find(t => t.id === port.transformationId).expression;
    assert.equal(normalized(revelation.expression), normalized(expected), 'REVEALED_TRANSFORMATION_DIVERGENCE:' + port.portId);
    // Verify the full executable method around the mapped expression, so extra
    // statements cannot disappear merely because they have no lineage region.
    const cls = revelation.ast.statements.filter(ts.isClassDeclaration);
    assert.equal(cls.length, 1);
    assert.ok(revelation.ast.statements.every(s => ts.isClassDeclaration(s) || ts.isImportDeclaration(s)), 'Unmapped top-level executable code');
    const importedHelpers = [];
    for (const statement of revelation.ast.statements.filter(ts.isImportDeclaration)) {
      assert.equal(statement.moduleSpecifier.text, './native-mechanics.mjs');
      assert.ok(!statement.importClause.name && ts.isNamedImports(statement.importClause.namedBindings));
      for (const imported of statement.importClause.namedBindings.elements) {
        assert.ok(!imported.propertyName || imported.propertyName.text === imported.name.text);
        importedHelpers.push(imported.name.text);
      }
    }
    assert.deepEqual(importedHelpers.sort(), [...port.helpers].sort());
    const methods = cls[0].members.filter(ts.isMethodDeclaration);
    assert.equal(cls[0].members.length, 1); assert.equal(methods.length, 1); assert.equal(methods[0].name.text, 'execute');
    assert.equal(methods[0].modifiers?.length ?? 0, 0);
    assert.deepEqual(methods[0].parameters.map(p => p.name.text), ['input', 'root']);
    assert.equal(methods[0].parameters[1].initializer?.getText(revelation.ast), 'input');
    assert.equal(methods[0].body.statements.length, 1);
    assert.ok(ts.isReturnStatement(methods[0].body.statements[0]));
    const lower = new NativeExpressionProjection(ts, provider.mechanics, provider.bodies);
    const native = lower.emit(revelation.expression);
    const reprojection = ts.createSourceFile('projection.mjs', `const body = ${native};`, ts.ScriptTarget.Latest, true);
    const expression = reprojection.statements[0].declarationList.declarations[0].initializer;
    assert.deepEqual(nativeSyntax(ts, expression), nativeSyntax(ts, methods[0].body.statements[0].expression), 'Native structure outside the recovered mechanic grammar');
    // Every operator and structural form the reveal claims to check gets a
    // mutation. Each one that the body actually contains must be rejected, and
    // the ones it does not contain are reported as unmeasured rather than passed.
    const mutationChecks = mutationSet.map(({ label, from, to }) => {
      const mutation = body.replaceAll(from, to);
      if (mutation === body) return { label, applied: false, rejected: null };
      let rejected;
      try { revealNativeExpressions(ts, mutation, port); rejected = false; } catch { rejected = true; }
      assert.ok(rejected, 'Reveal must detect mutated native semantics:' + label + ':' + port.portId);
      return { label, applied: true, rejected };
    });
    const calls = pureCalls.filter(call => call.scenarioId === authority.scenario.scenarioId && call.portId === port.portId);
    for (const call of calls) {
      const scope = structuredClone({ input: call.input, root: call.root });
      const expectedResult = capture(() => reference(expected, scope));
      const passed = isDeepStrictEqual(expectedResult, call.result) && isDeepStrictEqual(scope, call.after);
      assert.ok(passed, 'Native port differential:' + port.portId);
      behavioral.push({ portId: port.portId, inputDigest: nativeDigest(pretty(call.input)), outcomeDigest: nativeDigest(pretty(call.result)), passed });
    }
    recovered.push({ portId: port.portId, transformationId: port.transformationId, expression: revelation.expression,
      nodeCount: revelation.nodeCount, sourceDigest: retainedSource.sourceDigest, physicalDigest: nativeDigest(body),
      mutationChecks, mutationsApplied: mutationChecks.filter(m => m.applied).length, mutationsUnmeasured: mutationChecks.filter(m => !m.applied).map(m => m.label) });
  }
  const used = [...new Set(ports.flatMap(p => p.nodes.map(n => n.operation)))];
  const missingVectors = used.filter(op => !checkedVectors.some(v => v.operations.includes(op)));
  assert.deepEqual(missingVectors, [], 'Every lowered mechanic needs explicit differential vectors');
  const proof = { scenarioId: authority.scenario.scenarioId, target: 'node', nativeProvider: { file: authority.nativeBinding.implementation_id, digest: nativeDigest(source) },
    recovered, helperChecks, mechanicCoverage, differentialVectors: checkedVectors, retainedFixturePortComparisons: behavioral,
    disposition: 'NATIVE_TRANSFORMATION_CHECKS_PASSED',
    scope: 'Native transformation syntax round trip and tested provider semantics. Full Capability/Scenario authority round trip and Cross-Apply remain separate obligations.',
    managedAdmission: 'NOT_REQUESTED' };
  await fs.writeFile(path.join(base, 'evidence/native-projection.json'), pretty(proof));
  return { transformations: ports.length, mechanics: used.length, nodes: recovered.reduce((n, r) => n + r.nodeCount, 0), vectors: checkedVectors.length, portComparisons: behavioral.length,
    mutationsApplied: recovered.reduce((n, r) => n + r.mutationsApplied, 0), mutationSetSize: mutationSet.length, helperChecks: helperChecks.length };
}
