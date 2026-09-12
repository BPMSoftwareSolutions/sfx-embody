// Invoke a capability from an extracted inflight bundle, with no database
// connection. The bundle was produced by extract-inflight-bundle.mjs.
//
//   node --experimental-vm-modules scripts/invoke-from-bundle.mjs <bundle.json> [input.json]
//
// Planning reads the pinned platform from the local checkout (sdaRoot); nothing
// here contacts SQL Server.
import fs from 'node:fs/promises';
import path from 'node:path';
import { planNode } from '../src/materialize-node.mjs';
import { loadMemoryScenario } from '../src/load-memory-scenario.mjs';

const SDA_ROOT = process.env.SIDEFX_PLATFORM_ROOT ?? 'C:/lab/repos/scenario-driven-architecture';
const bundleFile = process.argv[2] ?? 'evidence/hello-world-sql/inflight-bundle.json';
const input = JSON.parse(await fs.readFile(process.argv[3] ?? 'examples/hello-world-sql.request.json', 'utf8'));

const bundle = JSON.parse(await fs.readFile(bundleFile, 'utf8'));
const plan = await planNode({ bundle, sdaRoot: SDA_ROOT });
const runtime = await loadMemoryScenario(plan);
const executions = [];
const scenario = await runtime.createScenario({ observer: { observe() {} }, clock: { now: () => new Date().toISOString() } });
const result = await scenario.execute(input, { executionId: 'invoke-from-bundle', rootExecutionId: 'invoke-from-bundle',
  rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect: v => executions.push(v) });
console.log('CAPABILITY', bundle.selection.capabilityId, 'FILES', plan.files.length);
console.log('DISPOSITION', result.disposition);
console.log('OUTCOME', JSON.stringify(result.outcome));
