// Invoke a capability from an extracted bundle, with no database connection.
//
//   node --experimental-vm-modules scripts/invoke-from-bundle.mjs <bundle.json> [input.json]
//   node --experimental-vm-modules scripts/invoke-from-bundle.mjs <bundle.json> --symbol MSFT [--region US]
//   node --experimental-vm-modules scripts/invoke-from-bundle.mjs <bundle.json> --name Ada
//
// Direct arguments vary one schema-supported input without editing a file.
import fs from 'node:fs/promises';
import path from 'node:path';
import { planNode } from '../src/materialize-node.mjs';
import { loadMemoryScenario } from '../src/load-memory-scenario.mjs';

const SDA_ROOT = process.env.SIDEFX_PLATFORM_ROOT ?? 'C:/lab/repos/scenario-driven-architecture';
const args = process.argv.slice(2);
const bundleFile = args[0] ?? 'evidence/hello-world-sql/inflight-bundle.json';
const flag = name => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : undefined; };

let input;
if (args.includes('--name')) input = { contractId: 'hello-world-request.v1', payload: { name: flag('--name') } };
else if (args.includes('--symbol')) input = { contractId: 'live-equity-price-request.v1', payload: { symbol: flag('--symbol'), region: flag('--region') ?? 'US' } };
else input = JSON.parse(await fs.readFile(args[1] ?? 'examples/hello-world-sql.request.json', 'utf8'));

const bundle = JSON.parse(await fs.readFile(bundleFile, 'utf8'));
const plan = await planNode({ bundle, sdaRoot: SDA_ROOT });
const runtime = await loadMemoryScenario(plan);
const executions = [];
const scenario = await runtime.createScenario({ observer: { observe() {} }, clock: { now: () => new Date().toISOString() } });
const result = await scenario.execute(input, { executionId: 'invoke-from-bundle', rootExecutionId: 'invoke-from-bundle',
  rootInput: structuredClone(input), ancestry: [plan.selectedScenarioId], collect: v => executions.push(v) });
console.log('INPUT', JSON.stringify(input));
console.log('DISPOSITION', result.disposition);
console.log('OUTCOME', JSON.stringify(result.outcome));
