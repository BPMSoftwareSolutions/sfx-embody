import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { readAuthority } from './read-authority.mjs';
import { materializeNode } from './materialize-node.mjs';
import { verifyNode } from './verify-node.mjs';
import { readWorkspaceConfig } from './read-workspace-config.mjs';

const pretty = value => JSON.stringify(value, null, 2) + '\n';
const hash = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
const json = value => JSON.parse(value.replace(/^\uFEFF/, ''));
const root = path.dirname(fileURLToPath(import.meta.url));
const config = await readWorkspaceConfig(process.argv[2]);
const componentNames = ['package.json', 'package-lock.json', 'read-workspace-config.mjs', 'read-authority.mjs', 'materialize-node.mjs', 'verify-node.mjs', 'verify-contract-fidelity.mjs', 'verify-native-projection.mjs', 'reveal-native-expressions.mjs', 'resolvers/node/consumer-object-provider.mjs', 'resolvers/node/native-expression-projection.mjs'];
const components = await Promise.all(componentNames.map(async name => ({ name, digest: hash(await fs.readFile(path.join(root, name))) })));
const implementationDigest = hash(pretty(components));
const cases = [];
let snapshotId, projectionDigest;
for (const request of config.cases) {
  const selection = json(await fs.readFile(path.join(root, request.selectionFile), 'utf8'));
  const result = { selection, implementationDigest, installations: [] };
  try {
    const bundle = await readAuthority(config.databaseRoot, selection);
    snapshotId ??= bundle.authority.snapshotId;
    projectionDigest ??= bundle.authority.projectionDigest;
    if (snapshotId !== bundle.authority.snapshotId || projectionDigest !== bundle.authority.projectionDigest) throw new Error('DATABASE_AUTHORITY_CHANGED_DURING_REGRESSION');
    const bundleFile = path.join(root, request.bundleFile);
    await fs.writeFile(bundleFile, pretty(bundle));
    const materialization = await materializeNode({ bundleFile, sdaRoot: config.sdaRoot, outputRoot: root });
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
    result.verification = await verifyNode(selectedBase, config.sdaRoot, root);
    result.receipts = await Promise.all(materialization.outputBases.map(async base => {
      const file = path.join(base, 'embodiment.receipt.json');
      const receipt = json(await fs.readFile(file, 'utf8'));
      if (receipt.resolverVersion !== hash(pretty(components.filter(c => c.name.startsWith('resolvers/'))))) throw new Error('RESOLVER_CHANGED_DURING_REGRESSION');
      return { file, digest: hash(await fs.readFile(file)), scenarioId: receipt.scenarioId, resolverVersion: receipt.resolverVersion, artifactDigest: receipt.artifactDigest };
    }));
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
}, { fixtures: 0, passed: 0, scenarioBodies: 0, mechanicClasses: 0, kernelObservations: 0, mechanicInvocations: 0, nativeExpressionNodes: 0, nativePortComparisons: 0, negativeChecks: 0 });
const evidence = { executedAt: new Date().toISOString(), command: 'node verify-estate.mjs regression.cases.json',
  implementationDigest, components, snapshotId, projectionDigest, cases, totals,
  disposition: cases.every(c => c.disposition === 'PASSED') ? 'PASSED' : 'FAILED',
  scope: 'NODE_EXECUTION_OF_RETAINED_FIXTURES_FOR_DECLARED_REGRESSION_CASES', managedAdmission: 'NOT_REQUESTED' };
await fs.writeFile(path.join(root, 'regression-results.json'), pretty(evidence));
console.log(pretty({ disposition: evidence.disposition, implementationDigest, ...totals }));
if (evidence.disposition !== 'PASSED') process.exitCode = 1;
