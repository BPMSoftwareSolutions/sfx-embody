import { createHash } from 'node:crypto';

const declarations = new WeakMap();
const hash = value => createHash('sha256').update(JSON.stringify(value)).digest('hex');
const authorityKey = input => hash([input.plan, input.scenario, input.executionAuthority, input.providerBindings, input.authorityIdentity]);

// These records stay in the invocation context. Request JSON cannot supply them.
export function registerConsumerAuthority(context, input) {
  if (!declarations.has(context)) declarations.set(context, new Map());
  declarations.get(context).set(authorityKey(input), new Set());
}

export function recordConsumerInputAdmission(context, input, contractId) {
  if (input.scenario?.input?.contractId === contractId)
    declarations.get(context)?.get(authorityKey(input))?.add(hash(input.scenarioInput));
}

export function requireAdmittedConsumerAuthority(context, input) {
  if (!declarations.get(context)?.get(authorityKey(input))?.has(hash(input.scenarioInput)))
    throw new Error('DECLARED_EXECUTION_AUTHORITY_NOT_ADMITTED');
}
