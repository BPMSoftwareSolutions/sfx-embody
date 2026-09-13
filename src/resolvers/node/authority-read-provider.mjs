// Estate provider: read a capability's retained authority as a declaration.
//
// This is the read step of the long-form embodiment composition. Its outcome is
// the transportable declaration the plan step consumes: the retained authority,
// the declared invocation closure and the mechanic declarations, bound to the
// snapshot and projection that produced them. It writes nothing.
import { readAuthority } from '../../read-authority.mjs';

export async function readCapabilityAuthority(configuration, input, context) {
  const { databaseRoot } = context;
  if (!input || typeof input.capabilityId !== 'string' || input.capabilityId.length === 0)
    throw new Error('READ_CAPABILITY_ID_REQUIRED');
  const target = input.target ?? 'node';
  const selection = { capabilityId: input.capabilityId, target,
    ...(typeof input.scenarioId === 'string' && input.scenarioId.length > 0 ? { scenarioId: input.scenarioId } : {}) };
  const bundle = await readAuthority(databaseRoot, selection, { retainObjects: false });
  return {
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
}
