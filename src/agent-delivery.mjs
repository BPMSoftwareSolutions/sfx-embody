import { spawn } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';

// The agent lane is a harness composition of two governed invocations: the model
// proposal is untrusted testimony produced by the governed model invocation
// capability, and the proposed capability is resolved and then executed through
// the same estate delivery, or refused by absence. The harness never executes a
// proposal itself and never invents an authority decision.

const PROPOSAL_SCHEMA = Object.freeze({
  type: 'object',
  required: ['capability', 'input'],
  properties: { capability: { type: 'string' }, input: { type: 'string' } }
});
const DEFAULT_PROVIDER_AUTHORITY = 'primary-cognitive-provider';
const DEFAULT_MODEL_ALIAS = 'instruction-capable-model';
const DEFAULT_VISIBLE_CAPABILITIES = Object.freeze(['resolve-equity-market-price-evidence']);
const CHILD_TIMEOUT_MS = 300_000;

const canonicalDigest = value => `sha256:${crypto.createHash('sha256').update(JSON.stringify(value)).digest('hex')}`;

async function readStdin() {
  const chunks = [];
  let size = 0;
  for await (const chunk of process.stdin) {
    size += chunk.length;
    if (size > 9 * 1024 * 1024) throw new Error('AGENT_INPUT_TOO_LARGE');
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString('utf8');
}

function runEstateDelivery(args, envelope) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, args, { cwd: process.cwd(), shell: false, windowsHide: true, stdio: ['pipe', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    const timer = setTimeout(() => { child.kill(); reject(new Error('AGENT_ESTATE_DELIVERY_TIMEOUT')); }, CHILD_TIMEOUT_MS);
    child.stdout.on('data', chunk => { stdout += chunk; });
    child.stderr.on('data', chunk => { stderr = (stderr + chunk).slice(-16_384); });
    child.on('error', () => { clearTimeout(timer); reject(new Error('AGENT_ESTATE_DELIVERY_FAILED')); });
    child.on('close', code => {
      clearTimeout(timer);
      let result;
      try { result = JSON.parse(stdout.trim().split('\n').at(-1)); }
      catch { result = null; }
      if (!result) return reject(new Error(`AGENT_ESTATE_RESULT_UNREADABLE:${code}:${stderr.trim().slice(0, 400)}`));
      resolve(result);
    });
    child.stdin.end(JSON.stringify(envelope));
  });
}

function capabilityEnvelope(operation, request) {
  return { deliveryType: 'sfx-command-delivery.v1', operation, request };
}

function buildModelRequest({ objective, providerAuthorityId, modelAlias, visibleCapabilities, maximumOutputTokens }) {
  return {
    carrierType: 'governed-model-invocation-request.v1',
    requestId: `agent-objective-${crypto.randomUUID()}`,
    requestHash: '',
    modelRequest: {
      requestId: `agent-objective-${crypto.randomUUID()}`,
      providerAuthorityId,
      modelAlias,
      interaction: {
        mode: 'structured-generation',
        messages: [
          {
            role: 'system',
            content: 'You map one user objective to exactly one governed capability request. '
              + `The capabilities this invocation can see are: ${visibleCapabilities.join(', ')}. `
              + 'A visible capability can be requested directly. If no visible capability can satisfy the objective, '
              + 'propose the capability identity the objective would require, even though it is not in the list. '
              + 'Respond only with the declared JSON shape: capability is the capability identity, '
              + 'input is the scalar that capability needs (for a price capability, resolve the company to its US ticker symbol, for example Broadcom to AVGO).'
          },
          { role: 'user', content: objective }
        ]
      },
      responsePolicy: { format: 'json', maximumOutputTokens, temperature: 0, schema: PROPOSAL_SCHEMA },
      executionPolicy: { timeoutMilliseconds: 60_000, attemptAuthority: { maximumAuthorizedAttempts: 1 }, providerSubstitution: { allowed: false } },
      evidencePolicy: { captureRequestHash: true, captureResponseHash: true, captureResolvedProvider: true, captureResolvedModel: true, captureTokenUsage: true, captureTiming: true }
    },
    requestLineage: ['agent-objective', 'obtain-governed-model-response']
  };
}

async function main() {
  const envelope = JSON.parse(await readStdin());
  const request = envelope?.request ?? {};
  if (envelope?.deliveryType !== 'sfx-command-delivery.v1' || envelope?.operation !== 'agent-invoke'
    || request.object !== 'agent' || request.verb !== 'invoke') throw new Error('AGENT_COMMAND_REJECTED');
  const input = { ...(request.input ?? {}) };
  if (typeof request.objective === 'string' && request.objective.trim().length > 0) input.objective = request.objective;
  if (typeof request.model === 'string' && request.model.trim().length > 0) input.model = request.model;
  if (typeof input.objective !== 'string' || input.objective.trim().length === 0) throw new Error('AGENT_OBJECTIVE_REQUIRED');
  if (input.model !== undefined && input.model !== 'gemini') throw new Error('AGENT_MODEL_NOT_ADMITTED: this environment admits --model gemini');
  const providerAuthorityId = typeof input.providerAuthorityId === 'string' && input.providerAuthorityId.length > 0
    ? input.providerAuthorityId : DEFAULT_PROVIDER_AUTHORITY;
  const modelAlias = typeof input.modelAlias === 'string' && input.modelAlias.length > 0 ? input.modelAlias : DEFAULT_MODEL_ALIAS;
  const visibleCapabilities = Array.isArray(input.visibleCapabilities) && input.visibleCapabilities.every(item => typeof item === 'string') && input.visibleCapabilities.length > 0
    ? input.visibleCapabilities : [...DEFAULT_VISIBLE_CAPABILITIES];
  const maximumOutputTokens = Number.isInteger(input.maximumOutputTokens) && input.maximumOutputTokens > 0 ? input.maximumOutputTokens : 4096;

  const project = JSON.parse(await fs.readFile(path.resolve('sfx.config.json'), 'utf8'));
  const args = project?.deliveries?.['database-memory']?.args;
  if (!Array.isArray(args)) throw new Error('AGENT_DATABASE_DELIVERY_MISSING');

  const startedAt = performance.now();
  const modelRequest = buildModelRequest({ objective: input.objective, providerAuthorityId, modelAlias, visibleCapabilities, maximumOutputTokens });
  modelRequest.requestHash = canonicalDigest(modelRequest.modelRequest);
  const modelResult = await runEstateDelivery(args, capabilityEnvelope('invoke',
    { object: 'capability', verb: 'invoke', subject: 'obtain-governed-model-response', input: modelRequest }));
  const modelOutcome = modelResult?.outcome?.result?.outcome ?? modelResult?.result?.outcome ?? null;
  const proposal = modelOutcome?.normalizedResponse?.structuredValue ?? null;
  const agentLane = {
    capability: 'obtain-governed-model-response',
    disposition: modelOutcome?.disposition ?? 'MODEL_RESPONSE_NOT_OBTAINED',
    provider: modelOutcome?.resolvedProvider ?? null,
    model: modelOutcome?.resolvedModel ?? null,
    providerAuthorityId,
    modelAlias,
    proposal: proposal && typeof proposal.capability === 'string' && typeof proposal.input === 'string' ? proposal : null,
    requestHash: modelOutcome?.requestHash ?? null,
    responseHash: modelOutcome?.responseHash ?? null,
    durationMilliseconds: modelOutcome?.timing?.durationMilliseconds ?? null
  };

  let resolution = null;
  let executionLane = null;
  let refusal = null;
  if (agentLane.proposal === null) {
    refusal = 'PROPOSAL_NOT_RECEIVED';
  } else {
    const found = await runEstateDelivery(args, capabilityEnvelope('find',
      { object: 'capability', verb: 'find', query: agentLane.proposal.capability }));
    const foundOutcome = found?.outcome ?? found;
    const declared = (foundOutcome?.capabilities ?? []).some(capability => capability.capabilityId === agentLane.proposal.capability);
    resolution = { capability: agentLane.proposal.capability, declared };
    if (!declared) {
      refusal = 'CAPABILITY_NOT_FOUND';
    } else {
      const executionResult = await runEstateDelivery(args, capabilityEnvelope('invoke',
        { object: 'capability', verb: 'invoke', subject: agentLane.proposal.capability, input: agentLane.proposal.input }));
      const executionOutcome = executionResult?.outcome?.result?.outcome ?? executionResult?.result?.outcome ?? null;
      executionLane = {
        capability: agentLane.proposal.capability,
        input: agentLane.proposal.input,
        disposition: executionOutcome?.disposition ?? 'EXECUTION_NOT_COMPLETED',
        outcome: executionOutcome?.payload ?? executionOutcome ?? null,
        providerTestimony: executionOutcome?.providerTestimony ?? null,
        durationMilliseconds: executionResult?.outcome?.evidence?.timings?.executeDeclaredGraph ?? null
      };
    }
  }

  const wallMilliseconds = performance.now() - startedAt;
  const receipt = {
    requested: 1,
    executed: executionLane ? 1 : 0,
    refused: executionLane ? 0 : 1,
    modelProviderReached: agentLane.disposition === 'MODEL_RESPONSE_OBTAINED' ? 1 : 0,
    executionProviderReached: executionLane?.providerTestimony ? 1 : 0,
    wallMilliseconds: Math.round(wallMilliseconds * 10) / 10
  };
  const payload = {
    carrierType: 'sfx-agent-receipt.v1',
    objective: input.objective,
    agentLane,
    resolution,
    executionLane,
    refusal,
    receipt,
    receiptNote: 'driver-composed from the two real governed receipts; no session ledger exists'
  };
  process.stdout.write(`${JSON.stringify({ disposition: 'terminated', outcome: payload })}\n`);
}

main().catch(error => {
  const message = error.message ?? 'AGENT_DELIVERY_FAILED';
  const code = /^[A-Z][A-Z0-9_]+(?=:|$)/.exec(message)?.[0] ?? 'AGENT_DELIVERY_FAILED';
  process.stdout.write(`${JSON.stringify({ disposition: 'failed', errorCode: code, error: { code, message } })}\n`);
  process.exitCode = 4;
});
