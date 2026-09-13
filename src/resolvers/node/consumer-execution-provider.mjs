import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';

const digest = bytes => 'sha256:' + crypto.createHash('sha256').update(bytes).digest('hex');

async function checkedModule(root, reference, expectedDigest) {
  const file = path.resolve(root, reference);
  const relative = path.relative(root, file);
  if (relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('PROVIDER_REFERENCE_OUTSIDE_ROOT');
  if (digest(await fs.readFile(file)) !== expectedDigest) throw new Error('PROVIDER_DEFINITION_DIGEST_MISMATCH:' + reference);
  return import(pathToFileURL(file).href);
}

// The native scheduler issues a cell invocation. Only the provider and
// configuration already bound to that cell can cross the physical boundary.
// Module names, exports, execution limits and outcome forms come from rows.
export async function executeConsumerPlan(configuration, input, context) {
  const { plan, scenarioInput, executionAuthority } = input;
  const { sdaRoot } = context;
  if (!plan || !executionAuthority || !Array.isArray(input.providerBindings)) throw new Error('EXECUTION_AUTHORITY_REQUIRED');
  const modules = new Map();
  const bindings = new Map();
  for (const binding of input.providerBindings) {
    if (bindings.has(binding.cellId)) throw new Error('PROVIDER_BINDING_AMBIGUOUS:' + binding.cellId);
    bindings.set(binding.cellId, binding);
    if (!modules.has(binding.implementationRef)) modules.set(binding.implementationRef,
      await checkedModule(sdaRoot, binding.implementationRef, binding.implementationDigest));
  }
  const primitives = await checkedModule(sdaRoot, executionAuthority.effectContext.module, executionAuthority.effectContext.digest);
  const effectContext = primitives[executionAuthority.effectContext.export](context.effectContextOverrides);
  const rootExecutionId = context.rootExecutionId ?? crypto.randomUUID();
  const cancellationController = new AbortController();
  const invoke = async message => {
    const binding = bindings.get(message.cellId);
    const cell = plan.canonicalGraph.cells.find(candidate => candidate.cellId === message.cellId);
    if (!binding || !cell || message.rootExecutionId !== rootExecutionId) throw new Error('DECLARED_OPERATION_PROVIDER_UNBOUND:' + message.cellId);
    const provider = modules.get(binding.implementationRef)?.[binding.providerExport];
    if (typeof provider !== 'function') throw new Error('PROVIDER_EXPORT_NOT_FOUND:' + binding.providerExport);
    const declaredConfiguration = cell.execution.configuration.binding.configuration;
    if (binding.invocation === 'expression') return provider(declaredConfiguration.expression, { input: message.input, root: scenarioInput });
    return provider(declaredConfiguration, message.input,
      { rootInput: scenarioInput, rootExecutionId, executionId: message.cellExecutionId, signal: cancellationController.signal }, effectContext);
  };
  const authority = executionAuthority.runtime;
  const roots = { estateRoot: context.estateRoot, sdaRoot };
  for (const dependency of authority.dependencies ?? []) {
    const root = roots[dependency.root];
    if (!root) throw new Error('PROVIDER_ROOT_NOT_DECLARED:' + dependency.root);
    const file = path.resolve(root, dependency.path), relative = path.relative(root, file);
    if (relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('PROVIDER_REFERENCE_OUTSIDE_ROOT');
    if (digest(await fs.readFile(file)) !== dependency.digest) throw new Error('PROVIDER_DEFINITION_DIGEST_MISMATCH:' + dependency.path);
  }
  if (!Number.isSafeInteger(authority.timeoutMilliseconds) || authority.timeoutMilliseconds < 1
      || !Number.isSafeInteger(authority.maximumOutputBytes) || authority.maximumOutputBytes < 1) throw new Error('EXECUTION_BOUND_NOT_DECLARED');
  const sourceBytes = Buffer.from(authority.source, 'utf8');
  if (digest(sourceBytes) !== authority.sourceDigest) throw new Error('PROVIDER_DEFINITION_DIGEST_MISMATCH');
  const args = authority.args.map(argument => argument === '{source}' ? authority.source
    : argument.replaceAll('{estateRoot}', context.estateRoot ?? '').replaceAll('{platformRoot}', sdaRoot));
  const environment = { ...process.env };
  for (const [name, value] of Object.entries(authority.environment ?? {})) {
    environment[name] = value.replaceAll('{platformRoot}', sdaRoot);
  }
  const child = spawn(authority.command, args, { cwd: sdaRoot, env: environment, shell: false, windowsHide: true,
    stdio: ['pipe', 'pipe', 'pipe'] });
  const lines = createInterface({ input: child.stdout, crlfDelay: Infinity });
  let outputBytes = 0, stderr = '', result, failure;
  const fail = error => { failure ??= error; cancellationController.abort(error); child.kill(); };
  const timer = setTimeout(() => fail(new Error('DECLARED_EXECUTION_TIMED_OUT')), authority.timeoutMilliseconds);
  child.stderr.on('data', bytes => {
    outputBytes += bytes.length;
    if (outputBytes > authority.maximumOutputBytes) fail(new Error('DECLARED_EXECUTION_OUTPUT_LIMIT'));
    else stderr += bytes;
  });
  child.stdout.on('data', bytes => {
    outputBytes += bytes.length;
    if (outputBytes > authority.maximumOutputBytes) fail(new Error('DECLARED_EXECUTION_OUTPUT_LIMIT'));
  });
  const cancellation = () => fail(new Error('DECLARED_EXECUTION_CANCELLED'));
  context.signal?.addEventListener('abort', cancellation, { once: true });
  if (context.signal?.aborted) cancellation();
  let pending = Promise.resolve();
  lines.on('line', line => {
    pending = pending.then(async () => {
      const message = JSON.parse(line);
      if (message.type === 'invoke-provider') {
        if (result !== undefined) throw new Error('EXECUTION_PROTOCOL_REJECTED');
        try { child.stdin.write(JSON.stringify({ outcome: await invoke(message) }) + '\n'); }
        catch (error) { child.stdin.write(JSON.stringify({ error: String(error.message) }) + '\n'); }
      } else if (message.type === 'result' && result === undefined) result = message.result;
      else throw new Error('EXECUTION_PROTOCOL_REJECTED');
    }).catch(fail);
  });
  child.stdin.on('error', error => { if (error.code !== 'EPIPE') fail(error); });
  const completion = new Promise((resolve, reject) => {
    child.once('error', reject);
    child.once('close', (code, signal) => resolve({ code, signal }));
  });
  child.stdin.write(JSON.stringify({ plan, input: scenarioInput, rootExecutionId,
    physicalCellIds: [...bindings.keys()] }) + '\n');
  try {
    const exit = await completion;
    await pending;
    if (failure) throw failure;
    if (exit.code !== 0 || result === undefined) throw new Error('DECLARED_EXECUTION_FAILED:' + stderr.trim());
    return { result, rootExecutionId, process: { exitCode: exit.code, stderrDigest: digest(stderr) },
      providerSourceDigest: authority.sourceDigest };
  } finally {
    clearTimeout(timer);
    context.signal?.removeEventListener('abort', cancellation);
    lines.close();
    child.stdin.destroy();
  }
}
