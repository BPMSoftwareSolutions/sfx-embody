import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import Ajv from 'ajv';
import { requireAdmittedConsumerAuthority } from './consumer-authority-context.mjs';

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
  const evaluateExpression = configuration.inputAdmission || configuration.expression
    ? (await import(pathToFileURL(path.join(context.sdaRoot,
      'languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs')).href)).evaluateExpression : null;
  if (configuration.inputAdmission && !new Ajv({ strict: false }).validate(configuration.inputAdmission, input))
    return evaluateExpression(configuration.admissionFailureExpression, { input, root: input });
  if (configuration.authoritySource === 'DATABASE') requireAdmittedConsumerAuthority(context, input);
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
  const admissionAuthority = executionAuthority.contractAdmission;
  const admission = admissionAuthority ? (await checkedModule(sdaRoot, admissionAuthority.module,
    admissionAuthority.digest))[admissionAuthority.export](plan.contractCatalog) : null;
  const rootExecutionId = context.rootExecutionId ?? crypto.randomUUID();
  const observe = (phase, status, message = {}) => {
    try {
      context.onObservation?.({ observationType: 'delivery-phase', phase, status,
        observedAt: new Date().toISOString(), rootExecutionId,
        ...(typeof message.cellExecutionId === 'string' ? { executionId: message.cellExecutionId } : {}),
        ...(typeof message.cellId === 'string' ? { stepId: message.cellId } : {}) });
    } catch { /* Observation cannot change the execution result. */ }
  };
  const cancellationController = new AbortController();
  const invoke = async message => {
    const binding = bindings.get(message.cellId);
    const cell = plan.canonicalGraph.cells.find(candidate => candidate.cellId === message.cellId);
    if (!binding || !cell || message.rootExecutionId !== rootExecutionId) throw new Error('DECLARED_OPERATION_PROVIDER_UNBOUND:' + message.cellId);
    const provider = modules.get(binding.implementationRef)?.[binding.providerExport];
    if (typeof provider !== 'function') throw new Error('PROVIDER_EXPORT_NOT_FOUND:' + binding.providerExport);
    const declaredConfiguration = cell.execution.configuration.binding.configuration;
    const outcome = binding.invocation === 'expression'
      ? await provider(declaredConfiguration.expression, { input: message.input, root: scenarioInput })
      : await provider(declaredConfiguration, message.input,
        { rootInput: scenarioInput, rootExecutionId, executionId: message.cellExecutionId, signal: cancellationController.signal }, effectContext);
    try { context.collectProviderExecution?.({ cellId: message.cellId, input: structuredClone(message.input), outcome: structuredClone(outcome) }); }
    catch { /* Evidence collection cannot change the provider's result. */ }
    return outcome;
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
  const child = (context.spawnDeclared ?? spawn)(authority.command, args, { cwd: sdaRoot, env: environment, shell: false, windowsHide: true,
    stdio: ['pipe', 'pipe', 'pipe'] });
  observe('executeConsumerPlan', 'started');
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
      if (message.type === 'admit-contract') {
        if (result !== undefined || !admission || message.rootExecutionId !== rootExecutionId
          || !['input', 'outcome'].includes(message.direction)) throw new Error('EXECUTION_PROTOCOL_REJECTED');
        const cell = plan.canonicalGraph.cells.find(cell => cell.cellId === message.cellId);
        if (!cell) throw new Error('DECLARED_OPERATION_PROVIDER_UNBOUND:' + message.cellId);
        // The child names its cell and direction. Its message cannot select a
        // different schema or replace the database's contract authority.
        observe('admitContract', 'started', message);
        try {
          const admitted = admission.admits(cell[message.direction].contractId, message.value);
          observe('admitContract', admitted ? 'completed' : 'rejected', message);
          child.stdin.write(JSON.stringify({ admitted }) + '\n');
        } catch (error) {
          observe('admitContract', 'failed', message);
          child.stdin.write(JSON.stringify({ error: String(error.message) }) + '\n');
        }
      } else if (message.type === 'invoke-provider') {
        if (result !== undefined) throw new Error('EXECUTION_PROTOCOL_REJECTED');
        observe('invokeProvider', 'started', message);
        try {
          const outcome = await invoke(message);
          observe('invokeProvider', 'completed', message);
          child.stdin.write(JSON.stringify({ outcome }) + '\n');
        } catch (error) {
          observe('invokeProvider', 'failed', message);
          child.stdin.write(JSON.stringify({ error: String(error.message) }) + '\n');
        }
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
    const execution = { result, rootExecutionId, process: { exitCode: exit.code, stderrDigest: digest(stderr) },
      providerSourceDigest: authority.sourceDigest };
    observe('executeConsumerPlan', result.disposition ?? 'completed');
    return configuration.expression ? evaluateExpression(configuration.expression,
      { input: { carrier: input, execution }, root: scenarioInput }) : execution;
  } catch (error) {
    observe('executeConsumerPlan', 'failed');
    throw error;
  } finally {
    clearTimeout(timer);
    context.signal?.removeEventListener('abort', cancellation);
    lines.close();
    child.stdin.destroy();
  }
}
