import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { executeConsumerPlan } from '../src/resolvers/node/consumer-execution-provider.mjs';

const hash = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
async function fixture(t, source) {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'consumer-execution-'));
  t.after(() => {
    assert.equal(path.dirname(path.resolve(root)), path.resolve(os.tmpdir()));
    assert.ok(path.basename(root).startsWith('consumer-execution-'));
    return fs.rm(root, { recursive: true, force: true });
  });
  const module = 'export const createContext=()=>({}); export const invoke=(_configuration,input)=>({received:input});\n';
  await fs.writeFile(path.join(root, 'provider.mjs'), module);
  return { context: { sdaRoot: root }, input: { scenarioInput: { text: 'one argument; $()' },
    plan: { canonicalGraph: { cells: [{ cellId: 'declared', execution: { configuration: { binding: { configuration: {} } } } }] } },
    providerBindings: [{ cellId: 'declared', implementationRef: 'provider.mjs', implementationDigest: hash(module), providerExport: 'invoke' }],
    executionAuthority: { effectContext: { module: 'provider.mjs', digest: hash(module), export: 'createContext' },
      runtime: { command: process.execPath, args: ['--input-type=module', '-e', '{source}'], source, sourceDigest: hash(source),
        timeoutMilliseconds: 3000, maximumOutputBytes: 10000 } } } };
}
const worker = cellId => `import {createInterface} from 'node:readline';
const lines=createInterface({input:process.stdin});const stream=lines[Symbol.asyncIterator]();
const request=JSON.parse((await stream.next()).value);
console.log(JSON.stringify({type:'invoke-provider',cellId:${JSON.stringify(cellId)},rootExecutionId:request.rootExecutionId,input:request.input}));
const reply=JSON.parse((await stream.next()).value);if(reply.error)throw Error(reply.error);
console.log(JSON.stringify({type:'result',result:reply.outcome}));lines.close();process.stdin.destroy();`;

test('a native invocation reaches only its bound provider with the original input', async t => {
  const { input, context } = await fixture(t, worker('declared'));
  const result = await executeConsumerPlan({}, input, context);
  assert.deepEqual(result.result, { received: input.scenarioInput });
  assert.equal(result.process.exitCode, 0);
});

test('an undeclared cell cannot invoke a physical provider', async t => {
  const { input, context } = await fixture(t, worker('undeclared'));
  await assert.rejects(executeConsumerPlan({}, input, context), /DECLARED_OPERATION_PROVIDER_UNBOUND/);
});

test('altered provider bytes are refused before execution', async t => {
  const { input, context } = await fixture(t, worker('declared'));
  await fs.appendFile(path.join(context.sdaRoot, 'provider.mjs'), '\n// changed');
  await assert.rejects(executeConsumerPlan({}, input, context), /PROVIDER_DEFINITION_DIGEST_MISMATCH/);
});

test('native execution observes its declared time and output bounds', async t => {
  const timeout = await fixture(t, 'setInterval(()=>{},1000)');
  timeout.input.executionAuthority.runtime.timeoutMilliseconds = 100;
  await assert.rejects(executeConsumerPlan({}, timeout.input, timeout.context), /DECLARED_EXECUTION_TIMED_OUT/);
  const output = await fixture(t, 'console.log("x".repeat(500));setInterval(()=>{},1000)');
  output.input.executionAuthority.runtime.maximumOutputBytes = 100;
  await assert.rejects(executeConsumerPlan({}, output.input, output.context), /DECLARED_EXECUTION_OUTPUT_LIMIT/);
});
