// Deliberately incomplete carrier: the generated interface accepts it while
// the original contract requires contractId and evaluationBoundary as well.
import type { SidefxProviderResolutionRequestV1 } from '../embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/contracts/sidefx-provider-resolution-request-v1.js';
import type { SidefxSemanticProviderResolutionV1 } from '../embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body/contracts/sidefx-semantic-provider-resolution-v1.js';
export const incompleteRequest: SidefxProviderResolutionRequestV1 = {
  snapshotDigest: 'sha256:' + '0'.repeat(64),
  requestedPlatformCapabilityId: 'audit-input',
  requestedTarget: 'node',
  conformantDispositions: ['CONFORMS'],
  providerBindings: []
};
export const invalidDisposition: SidefxSemanticProviderResolutionV1['disposition'] = 42;
