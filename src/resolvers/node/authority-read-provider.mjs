// Estate provider: read a capability's retained authority as a declaration.
//
// This is the read step of the long-form embodiment composition. Its outcome is
// the transportable declaration the plan step consumes: the retained authority,
// the declared invocation closure and the mechanic declarations, bound to the
// snapshot and projection that produced them. It writes nothing.
import { readAuthority } from '../../read-authority.mjs';
import { pathToFileURL } from 'node:url';
import path from 'node:path';

export async function readCapabilityAuthority(configuration, input, context) {
  const { databaseRoot } = context;
  if (!input || typeof input.capabilityId !== 'string' || input.capabilityId.length === 0)
    throw new Error('READ_CAPABILITY_ID_REQUIRED');
  const target = input.target ?? configuration.defaultTarget;
  const selection = { capabilityId: input.capabilityId, target,
    ...(typeof input.namespaceId === 'string' && input.namespaceId.length > 0 ? { namespaceId: input.namespaceId } : {}),
    ...(typeof input.scenarioId === 'string' && input.scenarioId.length > 0 ? { scenarioId: input.scenarioId } : {}) };
  const bundle = await (context.readAuthority ?? readAuthority)(databaseRoot, selection, { retainObjects: false });
  const profiles = bundle.authority.recordsets[3];
  for (const role of ['pure', 'effect']) {
    const count = profiles?.filter(profile => profile.target_id === target && profile.effect_classification === role).length ?? 0;
    if (count !== 1) throw new Error((count === 0 ? configuration.profileAbsent : configuration.profileAmbiguous) + ':' + target + ':' + role + ':' + count);
  }
  const result = {
    contractId: 'capability-authority-declaration.v1',
    capabilityId: input.capabilityId,
    scenarioId: bundle.authority.recordsets[0][0].scenario_id,
    target,
    snapshotId: bundle.authority.snapshotId,
    projectionDigest: bundle.authority.projectionDigest,
    viewDefinitionDigest: bundle.authority.viewDefinitionDigest,
    authority: bundle.authority,
    closure: bundle.closure,
    mechanics: bundle.mechanics
  };
  if (!configuration.expression) return result;
  const { evaluateExpression } = await import(pathToFileURL(path.join(context.sdaRoot,
    'languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs')).href);
  return evaluateExpression(configuration.expression, { input: { request: input, result }, root: input });
}
