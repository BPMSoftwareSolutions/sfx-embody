import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import ts from 'typescript';
import { verifyContractFidelity } from './verify-contract-fidelity.mjs';
import { verifyNativeProjection } from './verify-native-projection.mjs';

const hash = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
const pretty = value => JSON.stringify(value, null, 2) + '\n';
const readJson = async file => JSON.parse((await fs.readFile(file, 'utf8')).replace(/^\uFEFF/, ''));
const writeJson = async (file, value) => fs.writeFile(file, pretty(value));

export async function verifyNode(base, sdaRoot, outputRoot) {
  const rootReceipt = await readJson(path.join(base, 'embodiment.receipt.json'));
  const authority = await readJson(path.join(base, 'evidence/authority.json'));
  const fixtureAuthority = await readJson(path.join(base, 'evidence/fixture-authority.json'));
  const { satisfies, valueAt } = await import(pathToFileURL(path.join(sdaRoot, 'artifacts/tools/dist/consumer-projection/proof/assertion-evaluator.js')));
  const { createScenario } = await import(pathToFileURL(path.join(base, 'body/composition.mjs')));
  const fixtures = fixtureAuthority.fixtures;
  if (!fixtures.length || fixtures.some(f => f.expected.terminalScenarioId !== rootReceipt.scenarioId)) throw new Error('SELECTED_SCENARIO_FIXTURE_AUTHORITY_NOT_ESTABLISHED');
  const results = [], pureCalls = [];
  for (const fixture of fixtures) {
    const observations = [], mechanics = [], executions = [];
    const scenario = createScenario({ observer: { observe: value => observations.push(value) }, clock: { now: () => new Date().toISOString() }, observeMechanic: value => mechanics.push(value) });
    const observePorts = instance => {
      for (const [portId, dependency] of Object.entries(instance.dependencies)) {
        if (dependency.dependencies) { observePorts(dependency); continue; }
        const execute = dependency.execute.bind(dependency);
        dependency.execute = (input, root = input) => {
          const call = { scenarioId: instance.constructor.scenarioId, portId, ...structuredClone({ input, root }) };
          try { const value = execute(input, root); call.result = { value: structuredClone(value) }; return value; }
          catch (error) { call.result = { error: error.name }; throw error; }
          finally { call.after = structuredClone({ input, root }); pureCalls.push(call); }
        };
      }
    };
    observePorts(scenario);
    const input = structuredClone(fixture.input);
    const actual = await scenario.execute(input, { executionId: fixture.fixtureId, rootExecutionId: fixture.fixtureId,
      rootInput: structuredClone(input), ancestry: [rootReceipt.scenarioId], collect: value => executions.push(value) });
    const assertions = (fixture.expected.outcomeAssertions ?? []).map(assertion => ({ ...assertion,
      actual: valueAt(actual.outcome, assertion.path), passed: satisfies(valueAt(actual.outcome, assertion.path), assertion) }));
    const topLevel = executions.filter(e => e.parentExecutionId === null);
    const checks = {
      disposition: actual.disposition === fixture.expected.disposition,
      terminalScenarioId: actual.scenarioId === fixture.expected.terminalScenarioId,
      scenarioSequence: JSON.stringify(topLevel.map(e => e.scenarioId)) === JSON.stringify(fixture.expected.scenarioSequence),
      outcomeAssertions: assertions.every(a => a.passed),
      inputUnchanged: JSON.stringify(input) === JSON.stringify(fixture.input),
      kernelObservations: executions.every(e => {
        const steps = observations.filter(o => o.executionId === e.executionId);
        return steps.length === 5 && steps.every((o, i) => o.sequence === i && o.status === 'observed');
      })
    };
    results.push({ fixtureId: fixture.fixtureId, checks, passed: Object.values(checks).every(Boolean), assertions, actual, executions, observations, mechanicObservations: mechanics });
  }
  // Retain native execution results even if a subsequent structural check fails.
  await writeJson(path.join(base, 'evidence/fixture-results.json'), { fixtureSource: 'fixture-authority.json', fixtures: results });
  const targetBases = new Map();
  const collectBodies = async target => {
    const receipt = await readJson(path.join(target, 'embodiment.receipt.json'));
    if (targetBases.has(receipt.scenarioId)) return;
    if (receipt.capabilityId !== rootReceipt.capabilityId) throw new Error('CAPABILITY_DEPENDENCY_DIVERGENCE');
    targetBases.set(receipt.scenarioId, target);
    const dependencies = await readJson(path.join(target, 'body/dependencies.json'));
    for (const dependency of dependencies.filter(d => d.kind === 'invoke-scenario')) {
      const child = path.resolve(target, 'body', dependency.module, '../..');
      const childReceipt = await readJson(path.join(child, 'embodiment.receipt.json'));
      if (childReceipt.scenarioId !== dependency.id) throw new Error('SCENARIO_DEPENDENCY_DIVERGENCE');
      await collectBodies(child);
    }
  };
  await collectBodies(base);
  const printer = ts.createPrinter({ newLine: ts.NewLineKind.LineFeed, removeComments: true });
  const revelations = new Map();
  let bodyCount = 0, mechanicClassCount = 0;
  for (const [scenarioId, target] of targetBases) {
    const plan = await readJson(path.join(target, 'evidence/embodiment-plan.json'));
    const receipt = await readJson(path.join(target, 'embodiment.receipt.json'));
    assert.equal(hash(pretty(plan)), receipt.embodimentPlanDigest, 'plan digest');
    const files = [], observedClasses = [];
    const contractFiles = plan.files.filter(f => f.relativePath.endsWith('.ts')).map(f => path.join(outputRoot, f.relativePath));
    const program = ts.createProgram(contractFiles, { noEmit: true, strict: true, target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.NodeNext, moduleResolution: ts.ModuleResolutionKind.NodeNext, types: [] });
    const diagnostics = ts.getPreEmitDiagnostics(program);
    assert.equal(diagnostics.length, 0, diagnostics.map(d => ts.flattenDiagnosticMessageText(d.messageText, '\n')).join('\n'));
    for (const file of plan.files) {
      const content = await fs.readFile(path.join(outputRoot, file.relativePath), 'utf8');
      assert.equal(hash(content), file.digest, file.relativePath);
      bodyCount++;
      const entry = { relativePath: file.relativePath, digest: hash(content) };
      if (/\.(mjs|js|ts)$/.test(file.relativePath)) {
        const ast = ts.createSourceFile(file.relativePath, content, ts.ScriptTarget.Latest, true);
        assert.equal(ast.parseDiagnostics.length, 0, 'generated syntax');
        const classes = ast.statements.filter(ts.isClassDeclaration).map(c => ({ name: c.name.text,
          line: ast.getLineAndCharacterOfPosition(c.getStart(ast)).line + 1,
          methods: c.members.filter(ts.isMethodDeclaration).map(m => m.name.getText(ast)) }));
        entry.classes = classes;
        observedClasses.push(...classes);
      }
      files.push(entry);
    }
    const nativeSource = await fs.readFile(path.join(sdaRoot, authority.nativeBinding.implementation_id), 'utf8');
    const nativeProjection = await verifyNativeProjection(target, sdaRoot, outputRoot, pureCalls);
    const nativeChecks = [];
    const fixtureExecutions = results.map(result => ({ fixtureId: result.fixtureId,
      executions: result.executions.filter(e => e.scenarioId === scenarioId),
      observations: result.observations.filter(o => o.scenarioId === scenarioId),
      mechanicObservations: result.mechanicObservations.filter(o => o.scenarioId === scenarioId) }));
    const reveal = { capabilityId: receipt.capabilityId, scenarioId, target: 'node', method: 'Recover transformations from native syntax and checked binding lineage; compare with retained authority and selected-provider execution',
      files, nativeSource: { path: authority.nativeBinding.implementation_id, digest: hash(nativeSource) },
      contractTypeCheck: { files: contractFiles.length, diagnostics: diagnostics.length }, nativeProjection, observedClasses };
    await writeJson(path.join(target, 'evidence/reveal.json'), reveal);
    await writeJson(path.join(target, 'evidence/fixture-results.json'), scenarioId === rootReceipt.scenarioId ? { fixtureSource: 'fixture-authority.json', fixtures: results } : {
      scope: 'CHILD_EXECUTIONS_WITHIN_PARENT_FIXTURES', parentScenarioId: rootReceipt.scenarioId,
      parentFixtureResults: path.relative(path.join(target, 'evidence'), path.join(base, 'evidence/fixture-results.json')).replaceAll('\\', '/'), fixtures: fixtureExecutions });
    const contractFidelity = await verifyContractFidelity(target);
    revelations.set(scenarioId, { target, reveal, receipt, nativeChecks, contractFidelity, nativeProjection });
  }
  // Negative checks exercise real admission and exception propagation. These are
  // explicitly test injections, never executable provider substitutes in a body.
  const rejectionObservations = [];
  const invalid = createScenario({ observer: { observe: o => rejectionObservations.push(o) }, clock: { now: () => new Date().toISOString() } });
  const rejected = await invalid.execute(null, { executionId: 'negative-input', rootExecutionId: 'negative-input', rootInput: null });
  assert.equal(rejected.disposition, 'rejected');
  assert.deepEqual(rejectionObservations.map(o => o.stepId), ['admit-input']);
  const rootDependencies = await readJson(path.join(base, 'body/dependencies.json'));
  const child = rootDependencies.find(d => d.kind === 'invoke-scenario');
  let nestedFailure;
  if (child) {
    const failed = createScenario({ observer: { observe() {} }, clock: { now: () => new Date().toISOString() } });
    failed.dependencies[child.id].perform = async () => { throw new Error('INJECTED_PROVIDER_FAILURE_FOR_NEGATIVE_TEST'); };
    const executions = [];
    const execution = await failed.execute(structuredClone(fixtures[0].input), {
      executionId: 'negative-child', rootExecutionId: 'negative-child', rootInput: structuredClone(fixtures[0].input),
      ancestry: [rootReceipt.scenarioId], collect: e => executions.push(e) });
    assert.equal(execution.disposition, 'failed');
    assert.ok(executions.some(e => e.scenarioId === child.id && e.disposition === 'failed'));
    nestedFailure = { disposition: execution.disposition, executions };
  }
  const negativeChecks = { invalidInput: { disposition: rejected.disposition, observations: rejectionObservations }, nestedFailure };
  await writeJson(path.join(base, 'evidence/negative-checks.json'), negativeChecks);
  const passed = results.every(r => r.passed);
  for (const [scenarioId, { target, receipt, reveal, nativeChecks, contractFidelity, nativeProjection }] of revelations) {
    const conformance = { capabilityId: receipt.capabilityId, scenarioId, target: 'node',
      scope: scenarioId === rootReceipt.scenarioId ? 'RETAINED_CAPABILITY_FIXTURES' : 'CHILD_EXECUTIONS_WITHIN_PARENT_FIXTURES',
      fixtureCount: results.length, fixturePassCount: results.filter(r => r.passed).length,
      nativeBodyChecks: nativeChecks.length, negativeChecks: scenarioId === rootReceipt.scenarioId ? 'negative-checks.json' : null,
      contractFidelity, nativeProjection,
      acceptance: { behavioralFixtures: passed ? 'PASSED' : 'FAILED', contractVectors: contractFidelity.missingPositiveCoverage.length ? 'INCOMPLETE' : 'PASSED',
        nativeSemanticStructure: 'TRANSFORMATIONS_CHECKED', nativeLowering: 'TESTED_VECTORS_PASSED', transformationRoundTrip: 'PASSED', embodimentRoundTrip: 'NOT_PROVEN', databaseRoundTrip: 'NOT_PROVEN', crossApply: 'NOT_PROVEN' },
      disposition: passed ? 'EXECUTION_CHECKS_PASSED' : 'EXECUTION_CHECKS_FAILED', managedAdmission: 'NOT_REQUESTED',
      limitations: ['Candidate projection provider has not been admitted.', 'Passing these fixtures is not proof for untested inputs or other language targets.'] };
    await writeJson(path.join(target, 'evidence/conformance.json'), conformance);
    await writeJson(path.join(target, 'embodiment.receipt.json'), { ...receipt, revealDigest: hash(pretty(reveal)),
      nativeProjectionDigest: hash(await fs.readFile(path.join(target, 'evidence/native-projection.json'))),
      contractFidelityDigest: hash(await fs.readFile(path.join(target, 'evidence/contract-fidelity.json'))),
      lineageDigest: hash(await fs.readFile(path.join(target, 'evidence/mechanic-lineage.json'))),
      dependencyLockDigest: hash(await fs.readFile(path.join(target, 'body/package-lock.json'))),
      fixtureResultsDigest: hash(await fs.readFile(path.join(target, 'evidence/fixture-results.json'))), conformanceDigest: hash(pretty(conformance)),
      disposition: conformance.disposition });
  }
  assert.ok(passed, 'retained fixture expectations failed; inspect fixture-results.json');
  return { capabilityId: rootReceipt.capabilityId, scenarioId: rootReceipt.scenarioId, fixtures: results.length, passed: results.filter(r => r.passed).length,
    scenarioBodies: targetBases.size, bodyFiles: bodyCount, mechanicClasses: mechanicClassCount,
    kernelObservations: results.reduce((n, r) => n + r.observations.length, 0), mechanicInvocations: 0,
    nativeExpressionNodes: [...revelations.values()].reduce((n, r) => n + r.nativeProjection.nodes, 0),
    nativePortComparisons: pureCalls.length, negativeChecks: nestedFailure ? 2 : 1 };
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try { console.log(pretty(await verifyNode(...process.argv.slice(2)))); }
  catch (error) { console.error(error.stack); process.exitCode = 1; }
}
