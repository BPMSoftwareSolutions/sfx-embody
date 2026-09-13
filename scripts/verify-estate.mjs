import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { readAuthority } from '../src/read-authority.mjs';
import { materializeNode } from '../src/materialize-node.mjs';
import { verifyNode } from '../src/verification/verify-node.mjs';
import { readWorkspaceConfig } from '../src/read-workspace-config.mjs';
import { executeEstateCapability } from '../src/invoke-database-capability.mjs';
import { verifyConsumerFixtures } from './verify-consumer-fixtures.mjs';

const pretty = value => JSON.stringify(value, null, 2) + '\n';
const hash = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
const json = value => JSON.parse(value.replace(/^\uFEFF/, ''));
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const config = await readWorkspaceConfig(process.argv[2]);
const context = { ...config, estateRoot: root };
const verificationRoot = path.join(root, 'evidence/node-projection-verification');
const componentNames = ['package.json', 'package-lock.json', 'src/read-workspace-config.mjs', 'src/read-authority.mjs', 'src/materialize-node.mjs', 'src/verification/verify-node.mjs', 'src/verification/verify-contract-fidelity.mjs', 'src/verification/verify-native-projection.mjs', 'src/reveal-native-expressions.mjs', 'src/resolvers/node/consumer-object-provider.mjs', 'src/resolvers/node/native-expression-projection.mjs'];
const resolverNames = componentNames.filter(name => name.startsWith('src/resolvers/'));
componentNames.push('src/read-execution-graph.mjs', 'src/invoke-database-capability.mjs', 'src/load-consumer-plan.mjs',
  'src/resolvers/node/consumer-plan-provider.mjs', 'src/resolvers/node/consumer-execution-provider.mjs',
  'src/resolvers/node/consumer-write-provider.mjs', 'src/resolvers/node/consumer-authority-context.mjs');
const components = await Promise.all(componentNames.map(async name => ({ name, digest: hash(await fs.readFile(path.join(root, name))) })));
const implementationDigest = hash(pretty(components));
const cases = [];
let snapshotId, projectionDigest;
for (const request of config.cases) {
  const selection = json(await fs.readFile(request.selectionFile, 'utf8'));
  const result = { selection, implementationDigest, installations: [] };
  try {
    const bundle = await readAuthority(config.databaseRoot, selection);
    snapshotId ??= bundle.authority.snapshotId;
    projectionDigest ??= bundle.authority.projectionDigest;
    if (snapshotId !== bundle.authority.snapshotId || projectionDigest !== bundle.authority.projectionDigest) throw new Error('DATABASE_AUTHORITY_CHANGED_DURING_REGRESSION');
    const bundleFile = request.bundleFile;
    await fs.mkdir(path.dirname(bundleFile), { recursive: true });
    await fs.writeFile(bundleFile, pretty(bundle));
    // The old syntax checks prove the working per-port generation. Current
    // provider selection uses the consumer plan and is verified below.
    const baselineBundleFile = path.join(root, 'evidence/python-csharp-embodiment/baseline', selection.capabilityId + '.bundle.json');
    result.baselineBundle = { file: baselineBundleFile, digest: hash(await fs.readFile(baselineBundleFile)) };
    const materialization = await materializeNode({ bundleFile: baselineBundleFile, sdaRoot: config.sdaRoot, outputRoot: verificationRoot });
    let selectedBase;
    for (const base of materialization.outputBases) {
      const receipt = json(await fs.readFile(path.join(base, 'embodiment.receipt.json'), 'utf8'));
      if (receipt.scenarioId === selection.scenarioId) selectedBase = base;
      const cwd = path.join(base, 'body');
      const locked = await fs.stat(path.join(cwd, 'package-lock.json')).then(() => true, () => false);
      const args = [locked ? 'ci' : 'install', '--ignore-scripts', '--no-audit', '--no-fund'];
      // Only the constant npm invocation enters the Windows shell; paths are cwd.
      const install = process.platform === 'win32'
        ? spawnSync(process.env.ComSpec ?? 'cmd.exe', ['/d', '/s', '/c', 'npm.cmd ' + args.join(' ')], { cwd, encoding: 'utf8', windowsHide: true })
        : spawnSync('npm', args, { cwd, encoding: 'utf8' });
      result.installations.push({ scenarioId: receipt.scenarioId, command: 'npm ' + args.join(' '), cwd, exitStatus: install.status, stdout: install.stdout, stderr: install.stderr });
      if (install.status !== 0) throw new Error('BODY_DEPENDENCY_INSTALL_FAILED:' + receipt.scenarioId);
    }
    if (!selectedBase) throw new Error('SELECTED_SCENARIO_BODY_ABSENT');
    result.verification = await verifyNode(selectedBase, config.sdaRoot, verificationRoot);
    result.receipts = await Promise.all(materialization.outputBases.map(async base => {
      const file = path.join(base, 'embodiment.receipt.json');
      const receipt = json(await fs.readFile(file, 'utf8'));
      if (receipt.resolverVersion !== hash(pretty(components.filter(c => resolverNames.includes(c.name))))) throw new Error('RESOLVER_CHANGED_DURING_REGRESSION');
      return { file, digest: hash(await fs.readFile(file)), scenarioId: receipt.scenarioId, resolverVersion: receipt.resolverVersion, artifactDigest: receipt.artifactDigest };
    }));
    const declaration = await executeEstateCapability({ capabilityId: 'read-capability-authority' }, selection, context);
    result.consumerVerification = await verifyConsumerFixtures(declaration, {
      baselineBundleFile
    }, context);
    result.materialization = await executeEstateCapability({ capabilityId: 'materialize-capability-embodiment' }, selection, context);
    if (result.materialization.contractId !== 'capability-embodiment-materialization.v1') throw new Error('EMBODIMENT_MATERIALIZATION_FAILED');
    result.disposition = 'PASSED';
    console.log(pretty({ capabilityId: selection.capabilityId, ...result.verification, disposition: result.disposition }));
  } catch (error) {
    result.disposition = 'FAILED';
    result.error = error.message;
    console.error(pretty({ capabilityId: selection.capabilityId, disposition: result.disposition, error: result.error }));
  }
  cases.push(result);
}
for (const component of components) if (hash(await fs.readFile(path.join(root, component.name))) !== component.digest) throw new Error('IMPLEMENTATION_CHANGED_DURING_REGRESSION');
const totals = cases.reduce((total, result) => {
  for (const key of Object.keys(total)) total[key] += result.verification?.[key] ?? 0;
  return total;
}, { fixtures: 0, passed: 0, scenarioBodies: 0, kernelObservations: 0, nativeExpressionNodes: 0, nativePortComparisons: 0, negativeChecks: 0 });
const evidence = { executedAt: new Date().toISOString(), command: 'node scripts/verify-estate.mjs config/regression.cases.json',
  implementationDigest, components, snapshotId, projectionDigest, cases, totals,
  disposition: cases.every(c => c.disposition === 'PASSED') ? 'PASSED' : 'FAILED',
  scope: 'Historical per-port baseline syntax, mutation and contract checks in an isolated directory; current database-selected consumer execution against that generation; materialized consumer-plan digests.', managedAdmission: 'NOT_REQUESTED' };
await fs.mkdir(path.join(root, 'evidence'), { recursive: true });
await fs.writeFile(path.join(root, 'evidence/regression-results.json'), pretty(evidence));
console.log(pretty({ disposition: evidence.disposition, implementationDigest, ...totals }));
if (evidence.disposition !== 'PASSED') process.exitCode = 1;
