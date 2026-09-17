// GENERATED CAPABILITY OPERATIONS. Do not hand-edit.
import crypto from "node:crypto";
import fs from "node:fs";
import { bindValueAt, valueAt } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/native-mechanic-primitives.mjs";

const descriptorDocument = JSON.parse(fs.readFileSync(new URL("./execution-operations.json", import.meta.url), "utf8"));
const descriptors = Array.isArray(descriptorDocument.operations) ? descriptorDocument.operations : [];
export const cellContracts = Object.freeze({"cell:mechanic:establish-governed-model-response-evidence.operation.1":{"inputContractId":"governed-provider-testimony.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"governed-model-response-evidence.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.acceptanceClaimed":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.attemptCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.carrierType":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.disposition":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.effectLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.normalizedResponse":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.providerSwitchCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.requestHash":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.requestId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.resolvedModel":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.resolvedProtocolProjection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.resolvedProvider":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.resolvedProviderAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.responseHash":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.else.fields.timing":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.acceptanceClaimed":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.attemptCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.carrierType":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.disposition":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.effectLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.normalizedResponse":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.requestHash":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.requestId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.resolvedModel":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.resolvedProvider":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.then.fields.responseHash":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.acceptanceClaimed":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.attemptCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.carrierType":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.disposition":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.effectLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.normalizedResponse":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.requestHash":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.requestId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.resolvedModel":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.resolvedProvider":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.then.fields.responseHash":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:establish-governed-model-response-evidence.operation.2:expression.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-model-response.operation.1":{"inputContractId":"governed-model-invocation-request.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-model-response.operation.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-model-response.operation.3":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-model-response.operation.4":{"inputContractId":"semantic-value.v1","outcomeContractId":"governed-model-response-evidence.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1":{"inputContractId":"model-provider-protocol-response-policy.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.fixtureBypass":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.providerConveyor":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.providerConveyor:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.providerConveyor.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.providerConveyor.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.providerConveyor.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.providerConveyor.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.providerConveyor.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.providerSwitchCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.selectedProviderAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.then.values.1.fields.switchRequired":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.1:expression.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.model.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.model.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.model.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.model.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.provider":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.provider.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.provider.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.provider.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.provider.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.systemMessage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.systemMessage.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.systemMessage.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.systemMessage.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.bindings.systemMessage.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.adapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.allowedResponseHeaders":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.cancellationScopeReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.credentialReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointAuthorityDigest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.then.values.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.maxResponseBytes":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.adapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.maxTokens":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.messages":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.responseSchema":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.temperature":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.maxTokens":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.parts":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.parts.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.parts.items.0.fields.text":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.responseSchema":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then.fields.parts":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then.fields.parts.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then.fields.parts.items.0.fields.text":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.temperature":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.providerKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.providerAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.providerKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.requestId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.requestLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.resolvedModel":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.responseFormat":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.timeoutMilliseconds":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.then.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.10:expression.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.0:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.0.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.0.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.0.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.providerSwitchCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection.then.fields.providerAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection.then.fields.providerKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection.then.fields.requestType":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection.then.fields.resolvedModel":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection.then.fields.responseFormat":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProtocolProjection.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.1.fields.resolvedProviderAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.then.values.2.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.11:expression.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.12":{"inputContractId":"semantic-value.v1","outcomeContractId":"governed-provider-testimony.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.12:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.12:expression.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.12:expression.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.geminiBindRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.geminiBindRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.geminiBindRequest.fields.credentialReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.geminiBindRequest.fields.effectScope":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.geminiBindRequest.fields.endpointAuthorityDigest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.geminiBindRequest.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.geminiBindRequest.fields.requestingCapabilityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.openaiBindRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.openaiBindRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.openaiBindRequest.fields.credentialReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.openaiBindRequest.fields.effectScope":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.openaiBindRequest.fields.endpointAuthorityDigest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.openaiBindRequest.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.then.values.1.fields.openaiBindRequest.fields.requestingCapabilityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.2:expression.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.3":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.4":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.model.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.model.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.model.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.model.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.provider":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.provider.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.provider.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.provider.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.provider.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.systemMessage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.systemMessage.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.systemMessage.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.systemMessage.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.bindings.systemMessage.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.adapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.allowedResponseHeaders":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.cancellationScopeReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.credentialReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointAuthorityDigest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.then.values.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.maxResponseBytes":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.adapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.maxTokens":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.messages":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.responseSchema":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.temperature":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.maxTokens":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.parts":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.parts.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.parts.items.0.fields.text":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.responseSchema":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then.fields.parts":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then.fields.parts.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then.fields.parts.items.0.fields.text":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.temperature":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.providerKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.providerAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.providerKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.requestId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.requestLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.resolvedModel":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.responseFormat":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.timeoutMilliseconds":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.then.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.5:expression.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.6":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.bindings.switchRule":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.bindings.switchRule.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.bindings.switchRule.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.bindings.switchRule.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.bindings.switchRule.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.providerSwitchCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.providerSwitchCount:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.providerSwitchCount.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.providerSwitchCount.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.providerSwitchCount.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.providerSwitchCount.when.in":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.providerSwitchCount.when.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.selectedProviderAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.selectedProviderAuthorityId:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.selectedProviderAuthorityId.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.selectedProviderAuthorityId.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.selectedProviderAuthorityId.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.selectedProviderAuthorityId.when.in":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.selectedProviderAuthorityId.when.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.switchRequired":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.switchRequired.in":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.else.value.values.1.fields.switchRequired.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.then.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.then.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.then.values.1.fields.fixtureBypass":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.then.values.1.fields.primaryModelEvidence":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.then.values.1.fields.providerSwitchCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.then.values.1.fields.selectedProviderAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.then.values.1.fields.switchRequired":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.then.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.7:expression.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.model.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.model.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.model.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.model.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.provider":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.provider.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.provider.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.provider.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.provider.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.systemMessage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.systemMessage.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.systemMessage.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.systemMessage.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.bindings.systemMessage.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.adapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.allowedResponseHeaders":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.cancellationScopeReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.credentialReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointAuthorityDigest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.then.values.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.endpointUrl.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.maxResponseBytes":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.adapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.maxTokens":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.messages":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.responseSchema":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.else.fields.temperature":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.maxTokens":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.parts":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.parts.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.parts.items.0.fields.text":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.else.items.0.fields.role.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.messages.value.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.responseSchema":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then.fields.parts":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then.fields.parts.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.then.fields.parts.items.0.fields.text":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.systemInstruction.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.then.fields.temperature":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.context.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.providerKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.then.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.protocolProjectionRequest.fields.payload.fields.requestType.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.providerAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.providerKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.requestId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.requestLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.resolvedModel":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.responseFormat":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.else.value.values.1.fields.currentInvocationRequest.fields.payload.fields.attemptPlan.fields.payload.fields.timeoutMilliseconds":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.then.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.8:expression.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-governed-provider-testimony.operation.9":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1":{"inputContractId":"model-provider-embodiment-resolution.v1","outcomeContractId":"model-provider-protocol-response-policy.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy.fields.format":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy.fields.responseSchema":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy.fields.responseSchema:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy.fields.responseSchema.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy.fields.responseSchema.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy.fields.responseSchema.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy.fields.responseSchema.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy.fields.responseSchema.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:project-model-response-policy-to-provider-protocol.operation.1:expression.values.1.fields.protocolResponsePolicy.fields.schemaSourceConnector":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1":{"inputContractId":"governed-model-invocation-request.v1","outcomeContractId":"model-provider-embodiment-resolution.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.aliasEntry":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.aliasEntry:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.aliasEntry.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.aliasEntry.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.aliasEntry.then.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.aliasEntry.then.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.aliasEntry.then.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.aliasEntry.then.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.aliasEntry.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.conveyor":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.conveyor:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.conveyor.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.conveyor.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.conveyor.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.conveyor.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.conveyor.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.providerEntry":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.providerEntry.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.providerEntry.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.providerEntry.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.providerEntry.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.requestAlias":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.requestProvider":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.substitutionRequested":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.substitutionRequested:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.substitutionRequested.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.substitutionRequested.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.bindings.substitutionRequested.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.else.fields.rejectedAlias":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.else.fields.rejectedProviderAuthority":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.else.fields.resolutionStatus":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.adapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.aliasResolutionLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.aliasResolutionLineage.fields.modelAlias":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.aliasResolutionLineage.fields.providerAuthority":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.credentialReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.resolutionStatus":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.resolutionStatus:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.resolutionStatus.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.resolutionStatus.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.resolutionStatus.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.resolvedModel":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.then.fields.resolvedProviderAuthorityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-model-alias-embodiment.operation.1:expression.value.values.1.fields.payload.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:scenario:establish-governed-model-response-evidence":{"inputContractId":"governed-provider-testimony.v1","outcomeContractId":"governed-model-response-evidence.v1"},"cell:scenario:obtain-governed-model-response":{"inputContractId":"governed-model-invocation-request.v1","outcomeContractId":"governed-model-response-evidence.v1"},"cell:scenario:obtain-governed-provider-testimony":{"inputContractId":"model-provider-protocol-response-policy.v1","outcomeContractId":"governed-provider-testimony.v1"},"cell:scenario:project-model-response-policy-to-provider-protocol":{"inputContractId":"model-provider-embodiment-resolution.v1","outcomeContractId":"model-provider-protocol-response-policy.v1"},"cell:scenario:resolve-model-alias-embodiment":{"inputContractId":"governed-model-invocation-request.v1","outcomeContractId":"model-provider-embodiment-resolution.v1"}});

function sfxValueAt(source, dottedPath) {
  return valueAt(source, dottedPath) ?? null;
}
function sfxTruthy(value) {
  if (value === null || value === undefined || value === false) return false;
  if (typeof value === "number") return value !== 0 && !Number.isNaN(value);
  if (value === "") return false;
  if (Array.isArray(value)) return value.length > 0;
  if (typeof value === "object") return Object.keys(value).length > 0;
  return true;
}
function sfxNotAdmitted(code) {
  const error = new Error(code);
  error.code = code;
  throw error;
}
function sfxIsPrimitive(value) {
  return value === null || typeof value === "string" || typeof value === "number" || typeof value === "boolean";
}
function sfxIsObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
function sfxEquals(left, right) {
  if (!sfxIsPrimitive(left) || !sfxIsPrimitive(right)) sfxNotAdmitted("OPERAND_NOT_PRIMITIVE");
  return left === right;
}
function sfxGreaterThan(left, right) {
  const ordered = (typeof left === "number" && typeof right === "number") || (typeof left === "string" && typeof right === "string");
  if (!ordered) sfxNotAdmitted("OPERAND_NOT_ORDERED");
  return left > right;
}
function sfxLength(value) {
  if (typeof value !== "string" && !Array.isArray(value)) sfxNotAdmitted("OPERAND_NOT_MEASURABLE");
  return value.length;
}
function sfxMerge(...values) {
  for (const value of values) if (value !== null && !sfxIsObject(value)) sfxNotAdmitted("OPERAND_NOT_OBJECT");
  return Object.assign({}, ...values);
}
function sfxJoin(value, separator) {
  for (const member of value) if (member !== null && member !== undefined && typeof member === "object") sfxNotAdmitted("OPERAND_NOT_PRIMITIVE");
  return value.join(separator);
}
function sfxFormat(template, values) {
  const coerced = Object.entries(values).map(([key, value]) => {
    if (value === null || value === undefined) return [key, "null"];
    if (typeof value === "boolean") return [key, value ? "true" : "false"];
    if (typeof value === "number") return [key, String(value)];
    if (typeof value === "string") return [key, value];
    sfxNotAdmitted("OPERAND_NOT_PRIMITIVE");
  });
  return coerced.reduce((text, [key, value]) => text.replaceAll("{" + key + "}", value), template);
}
function sfxUnique(value) {
  for (const member of value) if (!sfxIsPrimitive(member)) sfxNotAdmitted("OPERAND_NOT_PRIMITIVE");
  return [...new Set(value)];
}
function sfxObjectValues(value) {
  if (!sfxIsObject(value)) sfxNotAdmitted("OPERAND_NOT_OBJECT");
  return Object.keys(value).sort().map((key) => value[key]);
}
function sfxParseJson(value) {
  if (value === null || typeof value !== "string") sfxNotAdmitted("OPERAND_NOT_PRIMITIVE");
  try { return JSON.parse(value); }
  catch { sfxNotAdmitted("VALUE_NOT_PARSABLE"); }
}
function sfxTryParseJson(value) {
  if (value === null || value === undefined) return { disposition: "NOT_PARSED", value: null };
  try { return { disposition: "PARSED", value: JSON.parse(value) }; }
  catch { return { disposition: "NOT_PARSED", value: null }; }
}
function sfxIntersects(left, right) {
  const members = new Set(right);
  return left.some((value) => members.has(value));
}
function sfxTrim(value) {
  return String(value).trim();
}
function sfxLowerCase(value) {
  return String(value).toLowerCase();
}
function sfxEscapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;").replaceAll("'", "&#39;");
}
function sfxSha256(value) {
  return crypto.createHash("sha256").update(String(value)).digest("hex");
}
function sfxBase64DecodeUtf8(value) {
  return Buffer.from(String(value), "base64").toString("utf8");
}
function sfxJsonStringify(value) {
  return JSON.stringify(value);
}
function sfxCanonicalize(value) {
  if (Array.isArray(value)) return value.map(sfxCanonicalize);
  if (!value || typeof value !== "object") return value;
  return Object.fromEntries(Object.keys(value).sort().map((key) => [key, sfxCanonicalize(value[key])]));
}
function sfxDirectedGraphClosure(value) {
  const graphInputValid = Boolean(value && typeof value === "object" && !Array.isArray(value));
  const graph = graphInputValid ? value : {};
  const declaredNodeIds = Array.isArray(graph.nodeIds) ? graph.nodeIds : [];
  const declaredEdges = Array.isArray(graph.edges) ? graph.edges : [];
  const declaredRootNodeIds = Array.isArray(graph.rootNodeIds) ? graph.rootNodeIds : [];
  const declaredTerminalNodeIds = Array.isArray(graph.terminalNodeIds) ? graph.terminalNodeIds : [];
  const findings = [];
  const findingKeys = new Set();
  const addFinding = (code, subjectId) => {
    const key = code + "\u0000" + subjectId;
    if (findingKeys.has(key)) return;
    findingKeys.add(key);
    findings.push({ code, subjectId });
  };
  const lexical = (left, right) => left < right ? -1 : left > right ? 1 : 0;
  if (!graphInputValid) addFinding("GRAPH_INPUT_INVALID", "input");
  if (!Array.isArray(graph.nodeIds)) addFinding("GRAPH_NODE_IDS_REQUIRED", "nodeIds");
  if (!Array.isArray(graph.edges)) addFinding("GRAPH_EDGES_REQUIRED", "edges");
  if (!Array.isArray(graph.rootNodeIds)) addFinding("GRAPH_ROOT_NODE_IDS_REQUIRED", "rootNodeIds");
  if (!Array.isArray(graph.terminalNodeIds)) addFinding("GRAPH_TERMINAL_NODE_IDS_REQUIRED", "terminalNodeIds");
  const nodeCounts = new Map();
  for (const nodeId of declaredNodeIds) {
    if (typeof nodeId !== "string" || nodeId.length === 0) {
      addFinding("GRAPH_NODE_ID_INVALID", String(nodeId));
      continue;
    }
    nodeCounts.set(nodeId, (nodeCounts.get(nodeId) ?? 0) + 1);
  }
  for (const [nodeId, count] of nodeCounts) {
    if (count > 1) addFinding("GRAPH_NODE_ID_DUPLICATE", nodeId);
  }
  const nodeIds = [...nodeCounts.keys()].sort(lexical);
  const nodeSet = new Set(nodeIds);
  const edgeCounts = new Map();
  const edges = [];
  for (const edge of declaredEdges) {
    if (!edge || typeof edge !== "object" || Array.isArray(edge)
      || typeof edge.edgeId !== "string" || edge.edgeId.length === 0
      || typeof edge.from !== "string" || edge.from.length === 0
      || typeof edge.to !== "string" || edge.to.length === 0) {
      addFinding("GRAPH_EDGE_INVALID", String(edge?.edgeId ?? ""));
      continue;
    }
    edgeCounts.set(edge.edgeId, (edgeCounts.get(edge.edgeId) ?? 0) + 1);
    edges.push({ edgeId: edge.edgeId, from: edge.from, to: edge.to });
  }
  for (const [edgeId, count] of edgeCounts) {
    if (count > 1) addFinding("GRAPH_EDGE_ID_DUPLICATE", edgeId);
  }
  edges.sort((left, right) => lexical(left.edgeId, right.edgeId)
    || lexical(left.from, right.from) || lexical(left.to, right.to));
  for (const edge of edges) {
    if (!nodeSet.has(edge.from)) addFinding("GRAPH_EDGE_SOURCE_UNRESOLVED", edge.edgeId);
    if (!nodeSet.has(edge.to)) addFinding("GRAPH_EDGE_TARGET_UNRESOLVED", edge.edgeId);
  }
  const normalizeDeclaredNodes = (values, invalidCode, invalidIdentityCode) => {
    for (const nodeId of values) {
      if (typeof nodeId !== "string" || nodeId.length === 0) addFinding(invalidIdentityCode, String(nodeId));
    }
    const normalized = [...new Set(values.filter((nodeId) => typeof nodeId === "string" && nodeId.length > 0))].sort(lexical);
    for (const nodeId of normalized) if (!nodeSet.has(nodeId)) addFinding(invalidCode, nodeId);
    return normalized.filter((nodeId) => nodeSet.has(nodeId));
  };
  const rootNodeIds = normalizeDeclaredNodes(declaredRootNodeIds, "GRAPH_ROOT_NODE_UNRESOLVED", "GRAPH_ROOT_NODE_ID_INVALID");
  const terminalNodeIds = normalizeDeclaredNodes(declaredTerminalNodeIds, "GRAPH_TERMINAL_NODE_UNRESOLVED", "GRAPH_TERMINAL_NODE_ID_INVALID");
  const terminalNodeSet = new Set(terminalNodeIds);
  findings.sort((left, right) => lexical(left.code, right.code) || lexical(left.subjectId, right.subjectId));
  if (findings.length > 0) {
    return {
      disposition: "REJECTED",
      nodeIds,
      edgeIds: [...new Set(edges.map((edge) => edge.edgeId))].sort(lexical),
      rootNodeIds,
      terminalNodeIds,
      reachableNodeIds: [],
      unreachableNodeIds: nodeIds,
      traversalNodeIds: [],
      traversalEdgeIds: [],
      reachablePairs: [],
      terminalReachability: [],
      cycleComponents: [],
      cycleEdgeIds: [],
      fixedPointPasses: 0,
      findings
    };
  }
  const adjacency = new Map(nodeIds.map((nodeId) => [nodeId, []]));
  for (const edge of edges) adjacency.get(edge.from).push(edge);
  for (const outgoing of adjacency.values()) outgoing.sort((left, right) => lexical(left.to, right.to) || lexical(left.edgeId, right.edgeId));
  const closureFrom = (startNodeId) => {
    const reached = new Set([startNodeId]);
    let frontier = [startNodeId];
    let passes = 0;
    while (frontier.length > 0) {
      const next = new Set();
      for (const nodeId of frontier.sort(lexical)) {
        for (const edge of adjacency.get(nodeId)) {
          if (!reached.has(edge.to)) {
            reached.add(edge.to);
            next.add(edge.to);
          }
        }
      }
      frontier = [...next];
      passes += 1;
    }
    return { reached: [...reached].sort(lexical), passes };
  };
  const closures = new Map(nodeIds.map((nodeId) => [nodeId, closureFrom(nodeId)]));
  const reachablePairs = nodeIds.flatMap((from) => closures.get(from).reached.map((to) => ({ from, to })));
  const reachableNodeSet = new Set(rootNodeIds.flatMap((rootNodeId) => closures.get(rootNodeId).reached));
  const reachableNodeIds = [...reachableNodeSet].sort(lexical);
  const unreachableNodeIds = nodeIds.filter((nodeId) => !reachableNodeSet.has(nodeId));
  const traversalNodeIds = [];
  const traversalEdgeIds = [];
  const traversedNodes = new Set();
  const traversedEdges = new Set();
  let frontier = [...rootNodeIds];
  while (frontier.length > 0) {
    const nodeId = frontier.shift();
    if (traversedNodes.has(nodeId)) continue;
    traversedNodes.add(nodeId);
    traversalNodeIds.push(nodeId);
    for (const edge of adjacency.get(nodeId)) {
      if (!traversedEdges.has(edge.edgeId)) {
        traversedEdges.add(edge.edgeId);
        traversalEdgeIds.push(edge.edgeId);
      }
      if (!traversedNodes.has(edge.to)) frontier.push(edge.to);
    }
    frontier.sort(lexical);
  }
  const terminalReachability = nodeIds.map((nodeId) => ({
    nodeId,
    terminalNodeIds: closures.get(nodeId).reached.filter((reachableNodeId) => terminalNodeSet.has(reachableNodeId))
  }));
  const assignedCycleNodes = new Set();
  const cycleComponents = [];
  for (const nodeId of nodeIds) {
    if (assignedCycleNodes.has(nodeId)) continue;
    const mutuallyReachable = nodeIds.filter((candidateNodeId) =>
      closures.get(nodeId).reached.includes(candidateNodeId)
      && closures.get(candidateNodeId).reached.includes(nodeId));
    const hasSelfLoop = edges.some((edge) => edge.from === nodeId && edge.to === nodeId);
    if (mutuallyReachable.length > 1 || hasSelfLoop) {
      for (const member of mutuallyReachable) assignedCycleNodes.add(member);
      cycleComponents.push(mutuallyReachable);
    }
  }
  cycleComponents.sort((left, right) => lexical(left.join("\u0000"), right.join("\u0000")));
  const cycleComponentByNode = new Map(cycleComponents.flatMap((component, index) => component.map((nodeId) => [nodeId, index])));
  const cycleEdgeIds = edges
    .filter((edge) => cycleComponentByNode.has(edge.from)
      && cycleComponentByNode.get(edge.from) === cycleComponentByNode.get(edge.to))
    .map((edge) => edge.edgeId)
    .sort(lexical);
  return {
    disposition: "CLOSED",
    nodeIds,
    edgeIds: edges.map((edge) => edge.edgeId),
    rootNodeIds,
    terminalNodeIds,
    reachableNodeIds,
    unreachableNodeIds,
    traversalNodeIds,
    traversalEdgeIds,
    reachablePairs,
    terminalReachability,
    cycleComponents,
    cycleEdgeIds,
    fixedPointPasses: Math.max(0, ...[...closures.values()].map((closure) => closure.passes)),
    findings: []
  };
}

async function invokeDeclaredOperation(descriptor, input, context) {
  const configuration = descriptor && descriptor.configuration && typeof descriptor.configuration === "object" ? descriptor.configuration : {};
  if (descriptor.sourceUnit === "identity") return input;
  const binding = configuration.binding && typeof configuration.binding === "object" ? configuration.binding : undefined;
  const sourceConfiguration = binding && binding.configuration && typeof binding.configuration === "object" ? binding.configuration : configuration;
  if (descriptor.composition === "declarative-value") {
    if (Object.hasOwn(sourceConfiguration, "outcome")) return structuredClone(sourceConfiguration.outcome);
    throw new Error("CAPABILITY_PROJECTION_MECHANIC_UNRESOLVED: '" + descriptor.mechanicId + "'.");
  }
  if (descriptor.composition === "declarative-output") {
    if (Object.hasOwn(sourceConfiguration, "output")) return structuredClone(sourceConfiguration.output);
    throw new Error("CAPABILITY_PROJECTION_MECHANIC_UNRESOLVED: '" + descriptor.mechanicId + "'.");
  }
  if (sourceConfiguration.invocationCondition !== undefined) {
    const condition = sourceConfiguration.invocationCondition;
    if (!condition || typeof condition.path !== "string" || !Object.hasOwn(condition, "equals") || condition.whenFalse !== "preserve-carrier") {
      throw new Error("DIRECT_PROVIDER_INVOCATION_CONDITION_INVALID");
    }
    if (valueAt(input, condition.path) !== condition.equals) return structuredClone(input);
  }
  const providerModulePath = descriptor.providerModuleRef || descriptor.providerModule;
  const providerExportName = descriptor.providerExport;
  if (!providerModulePath || !providerExportName) throw new Error("CAPABILITY_PROJECTION_MECHANIC_UNRESOLVED: '" + descriptor.mechanicId + "'.");
  const providerModule = await import(new URL(providerModulePath, import.meta.url).href);
  const exported = providerModule[providerExportName];
  if (typeof exported !== "function") throw new Error("CAPABILITY_PROJECTION_MECHANIC_UNRESOLVED: '" + descriptor.mechanicId + "'.");
  const provider = descriptor.factory === true
    ? exported({ readQuery: context && context.readQuery, databaseRoot: context && context.databaseRoot, effectContext: context && context.effectContext, bindingUrl: context && context.bindingUrl })
    : exported;
  if (descriptor.sourceUnit === "declared-read") return provider(input, context);
  if (sourceConfiguration.requestPath === undefined && sourceConfiguration.resultPath === undefined) {
    if (descriptor.invocation === "url-context") return provider(sourceConfiguration, input, context && context.bindingUrl);
    if (descriptor.invocation === "effects") return provider(sourceConfiguration, input, context, context && context.effectContext);
    return provider(sourceConfiguration, input, context, context && context.bindingUrl);
  }
  if (typeof sourceConfiguration.requestPath !== "string" || typeof sourceConfiguration.resultPath !== "string") {
    throw new Error("DIRECT_PROVIDER_CARRIER_BINDING_INVALID");
  }
  const request = valueAt(input, sourceConfiguration.requestPath);
  if (request === undefined) throw new Error("DIRECT_PROVIDER_REQUEST_PATH_MISSING: '" + sourceConfiguration.requestPath + "'");
  const outcome = descriptor.invocation === "effects"
    ? await provider(sourceConfiguration, request, context, context && context.effectContext)
    : await provider(sourceConfiguration, request, context, context && context.bindingUrl);
  return bindValueAt(input, sourceConfiguration.resultPath, outcome);
}

const operationDescriptorByCellId = Object.freeze(Object.fromEntries(descriptors.map((descriptor) => [descriptor.cellId, descriptor])));
const scenarioByScenarioId = Object.freeze(Object.fromEntries((descriptorDocument.scenarios ?? []).map((scenario) => [scenario.scenarioId, scenario])));
const scenarioByExitCellId = Object.freeze(Object.fromEntries((descriptorDocument.scenarios ?? []).map((scenario) => [scenario.exitCellId, scenario])));
const rootScenarioId = typeof descriptorDocument.rootScenarioId === "string" ? descriptorDocument.rootScenarioId : undefined;
const conformanceClosures = Object.freeze([...(descriptorDocument.conformanceClosures ?? [])]);

export { conformanceClosures, operationDescriptorByCellId, rootScenarioId, scenarioByExitCellId, scenarioByScenarioId };

export function operation0(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload"));
}

export function operation1(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "carrierType"), structuredClone("governed-model-response-evidence.v1"))) ? sfxValueAt(scope["input"], "") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("ALIAS_REJECTED"))) ? Object.fromEntries([["acceptanceClaimed", (structuredClone(false) ?? null)], ["attemptCount", (structuredClone(0) ?? null)], ["carrierType", (structuredClone("governed-model-response-evidence.v1") ?? null)], ["disposition", (structuredClone("MODEL_REQUEST_REJECTED") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["normalizedResponse", (structuredClone(null) ?? null)], ["payload", (sfxValueAt(scope["input"], "payload") ?? null)], ["requestHash", (sfxValueAt(scope["input"], "requestHash") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["resolvedModel", (structuredClone(null) ?? null)], ["resolvedProvider", (structuredClone(null) ?? null)], ["responseHash", (structuredClone(null) ?? null)]]) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("SUBSTITUTION_NOT_AUTHORIZED"))) ? Object.fromEntries([["acceptanceClaimed", (structuredClone(false) ?? null)], ["attemptCount", (structuredClone(0) ?? null)], ["carrierType", (structuredClone("governed-model-response-evidence.v1") ?? null)], ["disposition", (structuredClone("MODEL_REQUEST_REJECTED") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["normalizedResponse", (structuredClone(null) ?? null)], ["payload", (sfxValueAt(scope["input"], "payload") ?? null)], ["requestHash", (sfxValueAt(scope["input"], "requestHash") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["resolvedModel", (structuredClone(null) ?? null)], ["resolvedProvider", (structuredClone(null) ?? null)], ["responseHash", (structuredClone(null) ?? null)]]) : Object.fromEntries([["acceptanceClaimed", (structuredClone(false) ?? null)], ["attemptCount", (sfxValueAt(scope["input"], "attempts") ?? null)], ["carrierType", (structuredClone("governed-model-response-evidence.v1") ?? null)], ["disposition", (sfxValueAt(scope["input"], "disposition") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "receipt.requestLineage") ?? null)], ["normalizedResponse", (sfxValueAt(scope["input"], "response") ?? null)], ["providerSwitchCount", (sfxValueAt(scope["input"], "providerSwitchCount") ?? null)], ["requestHash", (sfxValueAt(scope["input"], "receipt.requestHash") ?? null)], ["requestId", (sfxValueAt(scope["input"], "receipt.requestId") ?? null)], ["resolvedModel", (sfxValueAt(scope["input"], "model") ?? null)], ["resolvedProtocolProjection", (sfxValueAt(scope["input"], "resolvedProtocolProjection") ?? null)], ["resolvedProvider", (sfxValueAt(scope["input"], "receipt.providerKind") ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["input"], "resolvedProviderAuthorityId") ?? null)], ["responseHash", (sfxValueAt(scope["input"], "receipt.responseHash") ?? null)], ["timing", (sfxValueAt(scope["input"], "receipt.timing") ?? null)]])))));
}

export function operation2(input, context) {
  return invokeDeclaredOperation(descriptors[2], input, context);
}

export function operation3(input, context) {
  return invokeDeclaredOperation(descriptors[3], input, context);
}

export function operation4(input, context) {
  return invokeDeclaredOperation(descriptors[4], input, context);
}

export function operation5(input, context) {
  return invokeDeclaredOperation(descriptors[5], input, context);
}

export function operation6(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED"))) ? sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["fixtureBypass", (structuredClone(false) ?? null)], ["providerConveyor", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "providerConveyor.authorityType"), structuredClone("model-provider-conveyor-authority.v1"))) ? sfxValueAt(scope["input"], "providerConveyor") : structuredClone({"authorityType":"model-provider-conveyor-authority.v1","conveyorId":"capability-authoring-model-conveyor.v1","maximumProviderSwitches":0,"providers":[{"adapterIdentity":"gemini-generate-content.v1","allowedResponseHeaders":["content-type","x-goog-request-id"],"credentialReference":"LOC_GEMINI_API_KEY","endpointAuthorityDigest":"sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04","models":[{"alias":"instruction-capable-model","resolvedModel":"gemini-2.5-pro"},{"alias":"reasoning-capable-model","resolvedModel":"gemini-2.5-flash"}],"providerAuthorityId":"primary-cognitive-provider","providerKind":"gemini"},{"adapterIdentity":"openai-chat-completions.v1","allowedResponseHeaders":["content-type","x-request-id"],"credentialReference":"LOC_OPENAI_API_KEY","endpointAuthorityDigest":"sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109","models":[{"alias":"instruction-capable-model","resolvedModel":"gpt-4.1-mini"}],"providerAuthorityId":"secondary-cognitive-provider","providerKind":"openai"}],"switchRules":[{"fromProviderAuthorityId":"primary-cognitive-provider","onDispositions":[],"toProviderAuthorityId":"secondary-cognitive-provider"}]})) ?? null)], ["providerSwitchCount", (structuredClone(0) ?? null)], ["selectedProviderAuthorityId", (sfxValueAt(scope["input"], "modelRequest.providerAuthorityId") ?? null)], ["switchRequired", (structuredClone(false) ?? null)]])) : sfxValueAt(scope["input"], "")));
}

export function operation7(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "fixtureBypass"), structuredClone(true))) ? sfxValueAt(scope["input"], "") : ((scope) => { scope = { ...scope, ["provider"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidate"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.providers"), scope)) }; scope = { ...scope, ["model"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")))({ ...scope, ["candidateModel"]: item }))) ?? null))(sfxValueAt(scope["provider"], "models"), scope)) }; scope = { ...scope, ["systemMessage"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")))({ ...scope, ["message"]: item }))) ?? null))(sfxValueAt(scope["input"], "modelRequest.interaction.messages"), scope)) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]])); })(scope)) : sfxValueAt(scope["input"], "")));
}

export function operation8(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED"))) ? sfxMerge((sfxTruthy(sfxValueAt(scope["input"], "switchRequired")) ? sfxValueAt(scope["input"], "fallbackModelEvidence") : sfxValueAt(scope["input"], "primaryModelEvidence")), Object.fromEntries([["providerSwitchCount", (sfxValueAt(scope["input"], "providerSwitchCount") ?? null)], ["resolvedProtocolProjection", ((sfxTruthy(sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.protocolProjectionRequest.payload.requestType")) ? Object.fromEntries([["providerAuthorityId", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerKind") ?? null)], ["requestType", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.protocolProjectionRequest.payload.requestType") ?? null)], ["resolvedModel", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)]]) : structuredClone(null)) ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["input"], "selectedProviderAuthorityId") ?? null)]]), Object.fromEntries([["payload", (sfxValueAt(scope["input"], "payload") ?? null)]])) : sfxValueAt(scope["input"], "")));
}

export function operation9(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("governed-provider-testimony.v1") ?? null)], ["payload", (sfxValueAt(scope["input"], "") ?? null)]]));
}

export function operation10(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED"))) ? sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["geminiBindRequest", (Object.fromEntries([["contractId", (structuredClone("os-environment-credential-binding-request.v1") ?? null)], ["credentialReference", (structuredClone("LOC_GEMINI_API_KEY") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04") ?? null)], ["invocationIdentity", (structuredClone("obtain-governed-model-response-execution") ?? null)], ["requestingCapabilityId", (structuredClone("obtain-governed-model-response") ?? null)]]) ?? null)], ["openaiBindRequest", (Object.fromEntries([["contractId", (structuredClone("os-environment-credential-binding-request.v1") ?? null)], ["credentialReference", (structuredClone("LOC_OPENAI_API_KEY") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109") ?? null)], ["invocationIdentity", (structuredClone("obtain-governed-model-response-execution") ?? null)], ["requestingCapabilityId", (structuredClone("obtain-governed-model-response") ?? null)]]) ?? null)]])) : sfxValueAt(scope["input"], "")));
}

export function operation11(input, context) {
  return invokeDeclaredOperation(descriptors[11], input, context);
}

export function operation12(input, context) {
  return invokeDeclaredOperation(descriptors[12], input, context);
}

export function operation13(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "fixtureBypass"), structuredClone(true))) ? sfxValueAt(scope["input"], "") : ((scope) => { scope = { ...scope, ["provider"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidate"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.providers"), scope)) }; scope = { ...scope, ["model"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")))({ ...scope, ["candidateModel"]: item }))) ?? null))(sfxValueAt(scope["provider"], "models"), scope)) }; scope = { ...scope, ["systemMessage"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")))({ ...scope, ["message"]: item }))) ?? null))(sfxValueAt(scope["input"], "modelRequest.interaction.messages"), scope)) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]])); })(scope)) : sfxValueAt(scope["input"], "")));
}

export function operation14(input, context) {
  return invokeDeclaredOperation(descriptors[14], input, context);
}

export function operation15(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "carrierType"), structuredClone("governed-model-response-evidence.v1"))) ? sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["fixtureBypass", (structuredClone(true) ?? null)], ["primaryModelEvidence", (sfxValueAt(scope["input"], "") ?? null)], ["providerSwitchCount", (structuredClone(0) ?? null)], ["selectedProviderAuthorityId", (structuredClone("primary-cognitive-provider") ?? null)], ["switchRequired", (structuredClone(false) ?? null)]])) : ((scope) => { scope = { ...scope, ["switchRule"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateRule"], "fromProviderAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidateRule"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.switchRules"), scope)) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["providerSwitchCount", ((sfxTruthy((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition"))) ? structuredClone(1) : structuredClone(0)) ?? null)], ["selectedProviderAuthorityId", ((sfxTruthy((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition"))) ? sfxValueAt(scope["switchRule"], "toProviderAuthorityId") : sfxValueAt(scope["input"], "selectedProviderAuthorityId")) ?? null)], ["switchRequired", ((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition")) ?? null)]])); })(scope)) : sfxValueAt(scope["input"], "")));
}

export function operation16(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "fixtureBypass"), structuredClone(true))) ? sfxValueAt(scope["input"], "") : ((scope) => { scope = { ...scope, ["provider"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidate"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.providers"), scope)) }; scope = { ...scope, ["model"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")))({ ...scope, ["candidateModel"]: item }))) ?? null))(sfxValueAt(scope["provider"], "models"), scope)) }; scope = { ...scope, ["systemMessage"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")))({ ...scope, ["message"]: item }))) ?? null))(sfxValueAt(scope["input"], "modelRequest.interaction.messages"), scope)) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]])); })(scope)) : sfxValueAt(scope["input"], "")));
}

export function operation17(input, context) {
  return invokeDeclaredOperation(descriptors[17], input, context);
}

export function operation18(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["protocolResponsePolicy", (Object.fromEntries([["format", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["responseSchema", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? sfxValueAt(scope["input"], "modelRequest.responsePolicy.schema") : structuredClone(null)) ?? null)], ["schemaSourceConnector", (structuredClone("modelRequest.responsePolicy.schema") ?? null)]]) ?? null)]])));
}

export function operation19(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["conveyor"]: ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "providerConveyor.authorityType"), structuredClone("model-provider-conveyor-authority.v1"))) ? sfxValueAt(scope["input"], "providerConveyor") : structuredClone({"authorityType":"model-provider-conveyor-authority.v1","conveyorId":"capability-authoring-model-conveyor.v1","maximumProviderSwitches":1,"providers":[{"adapterIdentity":"gemini-generate-content.v1","allowedResponseHeaders":["content-type","x-goog-request-id"],"credentialReference":"LOC_GEMINI_API_KEY","endpointAuthorityDigest":"sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04","models":[{"alias":"instruction-capable-model","resolvedModel":"gemini-2.5-pro"},{"alias":"reasoning-capable-model","resolvedModel":"gemini-2.5-flash"}],"providerAuthorityId":"primary-cognitive-provider","providerKind":"gemini"},{"adapterIdentity":"openai-chat-completions.v1","allowedResponseHeaders":["content-type","x-request-id"],"credentialReference":"LOC_OPENAI_API_KEY","endpointAuthorityDigest":"sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109","models":[{"alias":"instruction-capable-model","resolvedModel":"gpt-4.1-mini"}],"providerAuthorityId":"secondary-cognitive-provider","providerKind":"openai"}],"switchRules":[]}))) }; scope = { ...scope, ["requestProvider"]: (sfxValueAt(scope["input"], "modelRequest.providerAuthorityId")) }; scope = { ...scope, ["providerEntry"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["provider"], "providerAuthorityId"), sfxValueAt(scope["requestProvider"], "")))({ ...scope, ["provider"]: item }))) ?? null))(sfxValueAt(scope["conveyor"], "providers"), scope)) }; scope = { ...scope, ["requestAlias"]: (sfxValueAt(scope["input"], "modelRequest.modelAlias")) }; scope = { ...scope, ["aliasEntry"]: ((sfxTruthy(sfxValueAt(scope["providerEntry"], "")) ? ((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["model"], "alias"), sfxValueAt(scope["requestAlias"], "")))({ ...scope, ["model"]: item }))) ?? null))(sfxValueAt(scope["providerEntry"], "models"), scope) : structuredClone(null))) }; scope = { ...scope, ["substitutionRequested"]: ((sfxTruthy(sfxValueAt(scope["input"], "modelRequest.providerSubstitutionRequested")) ? sfxValueAt(scope["input"], "modelRequest.providerSubstitutionRequested") : structuredClone(false))) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["payload", ((sfxTruthy(sfxValueAt(scope["aliasEntry"], "")) ? Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["providerEntry"], "adapterIdentity") ?? null)], ["aliasResolutionLineage", (Object.fromEntries([["modelAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["providerAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)]]) ?? null)], ["credentialReference", (sfxValueAt(scope["providerEntry"], "credentialReference") ?? null)], ["resolutionStatus", ((sfxTruthy(sfxValueAt(scope["substitutionRequested"], "")) ? structuredClone("SUBSTITUTION_NOT_AUTHORIZED") : structuredClone("EMBODIMENT_AUTHORIZED")) ?? null)], ["resolvedModel", (sfxValueAt(scope["aliasEntry"], "resolvedModel") ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["providerEntry"], "providerAuthorityId") ?? null)]]) : Object.fromEntries([["rejectedAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["rejectedProviderAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)], ["resolutionStatus", (structuredClone("ALIAS_REJECTED") ?? null)]])) ?? null)]])); })(scope));
}

export function operation20(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload"));
}

export function operation21(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["acceptanceClaimed", (structuredClone(false) ?? null)], ["attemptCount", (sfxValueAt(scope["input"], "attempts") ?? null)], ["carrierType", (structuredClone("governed-model-response-evidence.v1") ?? null)], ["disposition", (sfxValueAt(scope["input"], "disposition") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "receipt.requestLineage") ?? null)], ["normalizedResponse", (sfxValueAt(scope["input"], "response") ?? null)], ["providerSwitchCount", (sfxValueAt(scope["input"], "providerSwitchCount") ?? null)], ["requestHash", (sfxValueAt(scope["input"], "receipt.requestHash") ?? null)], ["requestId", (sfxValueAt(scope["input"], "receipt.requestId") ?? null)], ["resolvedModel", (sfxValueAt(scope["input"], "model") ?? null)], ["resolvedProtocolProjection", (sfxValueAt(scope["input"], "resolvedProtocolProjection") ?? null)], ["resolvedProvider", (sfxValueAt(scope["input"], "receipt.providerKind") ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["input"], "resolvedProviderAuthorityId") ?? null)], ["responseHash", (sfxValueAt(scope["input"], "receipt.responseHash") ?? null)], ["timing", (sfxValueAt(scope["input"], "receipt.timing") ?? null)]]));
}

export function operation22(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(false));
}

export function operation23(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "attempts"));
}

export function operation24(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("governed-model-response-evidence.v1"));
}

export function operation25(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "disposition"));
}

export function operation26(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "receipt.requestLineage"));
}

export function operation27(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "response"));
}

export function operation28(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerSwitchCount"));
}

export function operation29(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "receipt.requestHash"));
}

export function operation30(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "receipt.requestId"));
}

export function operation31(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "model"));
}

export function operation32(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "resolvedProtocolProjection"));
}

export function operation33(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "receipt.providerKind"));
}

export function operation34(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "resolvedProviderAuthorityId"));
}

export function operation35(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "receipt.responseHash"));
}

export function operation36(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "receipt.timing"));
}

export function operation37(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["acceptanceClaimed", (structuredClone(false) ?? null)], ["attemptCount", (structuredClone(0) ?? null)], ["carrierType", (structuredClone("governed-model-response-evidence.v1") ?? null)], ["disposition", (structuredClone("MODEL_REQUEST_REJECTED") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["normalizedResponse", (structuredClone(null) ?? null)], ["payload", (sfxValueAt(scope["input"], "payload") ?? null)], ["requestHash", (sfxValueAt(scope["input"], "requestHash") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["resolvedModel", (structuredClone(null) ?? null)], ["resolvedProvider", (structuredClone(null) ?? null)], ["responseHash", (structuredClone(null) ?? null)]]));
}

export function operation38(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(false));
}

export function operation39(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(0));
}

export function operation40(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("governed-model-response-evidence.v1"));
}

export function operation41(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("MODEL_REQUEST_REJECTED"));
}

export function operation42(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestLineage"));
}

export function operation43(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation44(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload"));
}

export function operation45(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestHash"));
}

export function operation46(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestId"));
}

export function operation47(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation48(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation49(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation50(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("SUBSTITUTION_NOT_AUTHORIZED")));
}

export function operation51(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolutionStatus"));
}

export function operation52(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("SUBSTITUTION_NOT_AUTHORIZED"));
}

export function operation53(input, context) {
  return invokeDeclaredOperation(descriptors[53], input, context);
}

export function operation54(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["acceptanceClaimed", (structuredClone(false) ?? null)], ["attemptCount", (structuredClone(0) ?? null)], ["carrierType", (structuredClone("governed-model-response-evidence.v1") ?? null)], ["disposition", (structuredClone("MODEL_REQUEST_REJECTED") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["normalizedResponse", (structuredClone(null) ?? null)], ["payload", (sfxValueAt(scope["input"], "payload") ?? null)], ["requestHash", (sfxValueAt(scope["input"], "requestHash") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["resolvedModel", (structuredClone(null) ?? null)], ["resolvedProvider", (structuredClone(null) ?? null)], ["responseHash", (structuredClone(null) ?? null)]]));
}

export function operation55(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(false));
}

export function operation56(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(0));
}

export function operation57(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("governed-model-response-evidence.v1"));
}

export function operation58(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("MODEL_REQUEST_REJECTED"));
}

export function operation59(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestLineage"));
}

export function operation60(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation61(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload"));
}

export function operation62(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestHash"));
}

export function operation63(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestId"));
}

export function operation64(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation65(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation66(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation67(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("ALIAS_REJECTED")));
}

export function operation68(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolutionStatus"));
}

export function operation69(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("ALIAS_REJECTED"));
}

export function operation70(input, context) {
  return invokeDeclaredOperation(descriptors[70], input, context);
}

export function operation71(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation72(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "carrierType"), structuredClone("governed-model-response-evidence.v1")));
}

export function operation73(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "carrierType"));
}

export function operation74(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("governed-model-response-evidence.v1"));
}

export function operation75(input, context) {
  return invokeDeclaredOperation(descriptors[75], input, context);
}

export function operation76(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation77(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["provider"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidate"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.providers"), scope)) }; scope = { ...scope, ["model"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")))({ ...scope, ["candidateModel"]: item }))) ?? null))(sfxValueAt(scope["provider"], "models"), scope)) }; scope = { ...scope, ["systemMessage"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")))({ ...scope, ["message"]: item }))) ?? null))(sfxValueAt(scope["input"], "modelRequest.interaction.messages"), scope)) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]])); })(scope));
}

export function operation78(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")))({ ...scope, ["candidateModel"]: item }))) ?? null))(sfxValueAt(scope["provider"], "models"), scope));
}

export function operation79(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "models"));
}

export function operation80(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")));
}

export function operation81(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["candidateModel"], "alias"));
}

export function operation82(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.modelAlias"));
}

export function operation83(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidate"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.providers"), scope));
}

export function operation84(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerConveyor.providers"));
}

export function operation85(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")));
}

export function operation86(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["candidate"], "providerAuthorityId"));
}

export function operation87(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "selectedProviderAuthorityId"));
}

export function operation88(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")))({ ...scope, ["message"]: item }))) ?? null))(sfxValueAt(scope["input"], "modelRequest.interaction.messages"), scope));
}

export function operation89(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.interaction.messages"));
}

export function operation90(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")));
}

export function operation91(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation92(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("system"));
}

export function operation93(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation94(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation95(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation96(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation97(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("execute-governed-model-invocation-input.v1"));
}

export function operation98(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation99(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]));
}

export function operation100(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("execute-projected-model-provider-attempt-input.v1"));
}

export function operation101(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]));
}

export function operation102(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "adapterIdentity"));
}

export function operation103(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "allowedResponseHeaders"));
}

export function operation104(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("caller-signal"));
}

export function operation105(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "credentialReference"));
}

export function operation106(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "endpointAuthorityDigest"));
}

export function operation107(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("https://api.openai.com/v1/chat/completions"));
}

export function operation108(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])));
}

export function operation109(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "resolvedModel"));
}

export function operation110(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini")));
}

export function operation111(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation112(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation113(input, context) {
  return invokeDeclaredOperation(descriptors[113], input, context);
}

export function operation114(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestId"));
}

export function operation115(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(8388608));
}

export function operation116(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-model-provider-protocol"));
}

export function operation117(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]));
}

export function operation118(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-model-provider-protocol-input.v1"));
}

export function operation119(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]));
}

export function operation120(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "adapterIdentity"));
}

export function operation121(input, context) {
  return invokeDeclaredOperation(descriptors[121], input, context);
}

export function operation122(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]));
}

export function operation123(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens"));
}

export function operation124(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.interaction.messages"));
}

export function operation125(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "resolvedModel"));
}

export function operation126(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema"));
}

export function operation127(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature"));
}

export function operation128(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]));
}

export function operation129(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens"));
}

export function operation130(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope));
}

export function operation131(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.interaction.messages"));
}

export function operation132(input, context) {
  return invokeDeclaredOperation(descriptors[132], input, context);
}

export function operation133(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]);
}

export function operation134(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]));
}

export function operation135(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)]);
}

export function operation136(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]));
}

export function operation137(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "content"));
}

export function operation138(input, context) {
  return invokeDeclaredOperation(descriptors[138], input, context);
}

export function operation139(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation140(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("model"));
}

export function operation141(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant")));
}

export function operation142(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation143(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("assistant"));
}

export function operation144(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([]);
}

export function operation145(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")));
}

export function operation146(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation147(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("system"));
}

export function operation148(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema"));
}

export function operation149(input, context) {
  return invokeDeclaredOperation(descriptors[149], input, context);
}

export function operation150(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation151(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]));
}

export function operation152(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)]);
}

export function operation153(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]));
}

export function operation154(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["systemMessage"], "content"));
}

export function operation155(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system")));
}

export function operation156(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["systemMessage"], "role"));
}

export function operation157(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("system"));
}

export function operation158(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature"));
}

export function operation159(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini")));
}

export function operation160(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation161(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation162(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation163(input, context) {
  return invokeDeclaredOperation(descriptors[163], input, context);
}

export function operation164(input, context) {
  return invokeDeclaredOperation(descriptors[164], input, context);
}

export function operation165(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-openai-text"));
}

export function operation166(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-openai-structured"));
}

export function operation167(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json")));
}

export function operation168(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation169(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("json"));
}

export function operation170(input, context) {
  return invokeDeclaredOperation(descriptors[170], input, context);
}

export function operation171(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-gemini-text"));
}

export function operation172(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-gemini-structured"));
}

export function operation173(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json")));
}

export function operation174(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation175(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("json"));
}

export function operation176(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini")));
}

export function operation177(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation178(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation179(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerAuthorityId"));
}

export function operation180(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation181(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestId"));
}

export function operation182(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestLineage"));
}

export function operation183(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "resolvedModel"));
}

export function operation184(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation185(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds"));
}

export function operation186(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation187(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "fixtureBypass"), structuredClone(true)));
}

export function operation188(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "fixtureBypass"));
}

export function operation189(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(true));
}

export function operation190(input, context) {
  return invokeDeclaredOperation(descriptors[190], input, context);
}

export function operation191(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED")));
}

export function operation192(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolutionStatus"));
}

export function operation193(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EMBODIMENT_AUTHORIZED"));
}

export function operation194(input, context) {
  return invokeDeclaredOperation(descriptors[194], input, context);
}

export function operation195(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation196(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge((sfxTruthy(sfxValueAt(scope["input"], "switchRequired")) ? sfxValueAt(scope["input"], "fallbackModelEvidence") : sfxValueAt(scope["input"], "primaryModelEvidence")), Object.fromEntries([["providerSwitchCount", (sfxValueAt(scope["input"], "providerSwitchCount") ?? null)], ["resolvedProtocolProjection", ((sfxTruthy(sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.protocolProjectionRequest.payload.requestType")) ? Object.fromEntries([["providerAuthorityId", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerKind") ?? null)], ["requestType", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.protocolProjectionRequest.payload.requestType") ?? null)], ["resolvedModel", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)]]) : structuredClone(null)) ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["input"], "selectedProviderAuthorityId") ?? null)]]), Object.fromEntries([["payload", (sfxValueAt(scope["input"], "payload") ?? null)]])));
}

export function operation197(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "primaryModelEvidence"));
}

export function operation198(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "fallbackModelEvidence"));
}

export function operation199(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "switchRequired"));
}

export function operation200(input, context) {
  return invokeDeclaredOperation(descriptors[200], input, context);
}

export function operation201(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["providerSwitchCount", (sfxValueAt(scope["input"], "providerSwitchCount") ?? null)], ["resolvedProtocolProjection", ((sfxTruthy(sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.protocolProjectionRequest.payload.requestType")) ? Object.fromEntries([["providerAuthorityId", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerKind") ?? null)], ["requestType", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.protocolProjectionRequest.payload.requestType") ?? null)], ["resolvedModel", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)]]) : structuredClone(null)) ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["input"], "selectedProviderAuthorityId") ?? null)]]));
}

export function operation202(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerSwitchCount"));
}

export function operation203(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation204(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["providerAuthorityId", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerKind") ?? null)], ["requestType", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.protocolProjectionRequest.payload.requestType") ?? null)], ["resolvedModel", (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)]]));
}

export function operation205(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerAuthorityId"));
}

export function operation206(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.providerKind"));
}

export function operation207(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.protocolProjectionRequest.payload.requestType"));
}

export function operation208(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.resolvedModel"));
}

export function operation209(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation210(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "currentInvocationRequest.payload.attemptPlan.payload.protocolProjectionRequest.payload.requestType"));
}

export function operation211(input, context) {
  return invokeDeclaredOperation(descriptors[211], input, context);
}

export function operation212(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "selectedProviderAuthorityId"));
}

export function operation213(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["payload", (sfxValueAt(scope["input"], "payload") ?? null)]]));
}

export function operation214(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload"));
}

export function operation215(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED")));
}

export function operation216(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolutionStatus"));
}

export function operation217(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EMBODIMENT_AUTHORIZED"));
}

export function operation218(input, context) {
  return invokeDeclaredOperation(descriptors[218], input, context);
}

export function operation219(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("governed-provider-testimony.v1") ?? null)], ["payload", (sfxValueAt(scope["input"], "") ?? null)]]));
}

export function operation220(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("governed-provider-testimony.v1"));
}

export function operation221(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation222(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation223(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["fixtureBypass", (structuredClone(false) ?? null)], ["providerConveyor", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "providerConveyor.authorityType"), structuredClone("model-provider-conveyor-authority.v1"))) ? sfxValueAt(scope["input"], "providerConveyor") : structuredClone({"authorityType":"model-provider-conveyor-authority.v1","conveyorId":"capability-authoring-model-conveyor.v1","maximumProviderSwitches":0,"providers":[{"adapterIdentity":"gemini-generate-content.v1","allowedResponseHeaders":["content-type","x-goog-request-id"],"credentialReference":"LOC_GEMINI_API_KEY","endpointAuthorityDigest":"sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04","models":[{"alias":"instruction-capable-model","resolvedModel":"gemini-2.5-pro"},{"alias":"reasoning-capable-model","resolvedModel":"gemini-2.5-flash"}],"providerAuthorityId":"primary-cognitive-provider","providerKind":"gemini"},{"adapterIdentity":"openai-chat-completions.v1","allowedResponseHeaders":["content-type","x-request-id"],"credentialReference":"LOC_OPENAI_API_KEY","endpointAuthorityDigest":"sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109","models":[{"alias":"instruction-capable-model","resolvedModel":"gpt-4.1-mini"}],"providerAuthorityId":"secondary-cognitive-provider","providerKind":"openai"}],"switchRules":[{"fromProviderAuthorityId":"primary-cognitive-provider","onDispositions":[],"toProviderAuthorityId":"secondary-cognitive-provider"}]})) ?? null)], ["providerSwitchCount", (structuredClone(0) ?? null)], ["selectedProviderAuthorityId", (sfxValueAt(scope["input"], "modelRequest.providerAuthorityId") ?? null)], ["switchRequired", (structuredClone(false) ?? null)]])));
}

export function operation224(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation225(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["fixtureBypass", (structuredClone(false) ?? null)], ["providerConveyor", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "providerConveyor.authorityType"), structuredClone("model-provider-conveyor-authority.v1"))) ? sfxValueAt(scope["input"], "providerConveyor") : structuredClone({"authorityType":"model-provider-conveyor-authority.v1","conveyorId":"capability-authoring-model-conveyor.v1","maximumProviderSwitches":0,"providers":[{"adapterIdentity":"gemini-generate-content.v1","allowedResponseHeaders":["content-type","x-goog-request-id"],"credentialReference":"LOC_GEMINI_API_KEY","endpointAuthorityDigest":"sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04","models":[{"alias":"instruction-capable-model","resolvedModel":"gemini-2.5-pro"},{"alias":"reasoning-capable-model","resolvedModel":"gemini-2.5-flash"}],"providerAuthorityId":"primary-cognitive-provider","providerKind":"gemini"},{"adapterIdentity":"openai-chat-completions.v1","allowedResponseHeaders":["content-type","x-request-id"],"credentialReference":"LOC_OPENAI_API_KEY","endpointAuthorityDigest":"sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109","models":[{"alias":"instruction-capable-model","resolvedModel":"gpt-4.1-mini"}],"providerAuthorityId":"secondary-cognitive-provider","providerKind":"openai"}],"switchRules":[{"fromProviderAuthorityId":"primary-cognitive-provider","onDispositions":[],"toProviderAuthorityId":"secondary-cognitive-provider"}]})) ?? null)], ["providerSwitchCount", (structuredClone(0) ?? null)], ["selectedProviderAuthorityId", (sfxValueAt(scope["input"], "modelRequest.providerAuthorityId") ?? null)], ["switchRequired", (structuredClone(false) ?? null)]]));
}

export function operation226(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(false));
}

export function operation227(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone({"authorityType":"model-provider-conveyor-authority.v1","conveyorId":"capability-authoring-model-conveyor.v1","maximumProviderSwitches":0,"providers":[{"adapterIdentity":"gemini-generate-content.v1","allowedResponseHeaders":["content-type","x-goog-request-id"],"credentialReference":"LOC_GEMINI_API_KEY","endpointAuthorityDigest":"sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04","models":[{"alias":"instruction-capable-model","resolvedModel":"gemini-2.5-pro"},{"alias":"reasoning-capable-model","resolvedModel":"gemini-2.5-flash"}],"providerAuthorityId":"primary-cognitive-provider","providerKind":"gemini"},{"adapterIdentity":"openai-chat-completions.v1","allowedResponseHeaders":["content-type","x-request-id"],"credentialReference":"LOC_OPENAI_API_KEY","endpointAuthorityDigest":"sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109","models":[{"alias":"instruction-capable-model","resolvedModel":"gpt-4.1-mini"}],"providerAuthorityId":"secondary-cognitive-provider","providerKind":"openai"}],"switchRules":[{"fromProviderAuthorityId":"primary-cognitive-provider","onDispositions":[],"toProviderAuthorityId":"secondary-cognitive-provider"}]}));
}

export function operation228(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerConveyor"));
}

export function operation229(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "providerConveyor.authorityType"), structuredClone("model-provider-conveyor-authority.v1")));
}

export function operation230(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerConveyor.authorityType"));
}

export function operation231(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("model-provider-conveyor-authority.v1"));
}

export function operation232(input, context) {
  return invokeDeclaredOperation(descriptors[232], input, context);
}

export function operation233(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(0));
}

export function operation234(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.providerAuthorityId"));
}

export function operation235(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(false));
}

export function operation236(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED")));
}

export function operation237(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolutionStatus"));
}

export function operation238(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EMBODIMENT_AUTHORIZED"));
}

export function operation239(input, context) {
  return invokeDeclaredOperation(descriptors[239], input, context);
}

export function operation240(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation241(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["geminiBindRequest", (Object.fromEntries([["contractId", (structuredClone("os-environment-credential-binding-request.v1") ?? null)], ["credentialReference", (structuredClone("LOC_GEMINI_API_KEY") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04") ?? null)], ["invocationIdentity", (structuredClone("obtain-governed-model-response-execution") ?? null)], ["requestingCapabilityId", (structuredClone("obtain-governed-model-response") ?? null)]]) ?? null)], ["openaiBindRequest", (Object.fromEntries([["contractId", (structuredClone("os-environment-credential-binding-request.v1") ?? null)], ["credentialReference", (structuredClone("LOC_OPENAI_API_KEY") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109") ?? null)], ["invocationIdentity", (structuredClone("obtain-governed-model-response-execution") ?? null)], ["requestingCapabilityId", (structuredClone("obtain-governed-model-response") ?? null)]]) ?? null)]])));
}

export function operation242(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation243(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["geminiBindRequest", (Object.fromEntries([["contractId", (structuredClone("os-environment-credential-binding-request.v1") ?? null)], ["credentialReference", (structuredClone("LOC_GEMINI_API_KEY") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04") ?? null)], ["invocationIdentity", (structuredClone("obtain-governed-model-response-execution") ?? null)], ["requestingCapabilityId", (structuredClone("obtain-governed-model-response") ?? null)]]) ?? null)], ["openaiBindRequest", (Object.fromEntries([["contractId", (structuredClone("os-environment-credential-binding-request.v1") ?? null)], ["credentialReference", (structuredClone("LOC_OPENAI_API_KEY") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109") ?? null)], ["invocationIdentity", (structuredClone("obtain-governed-model-response-execution") ?? null)], ["requestingCapabilityId", (structuredClone("obtain-governed-model-response") ?? null)]]) ?? null)]]));
}

export function operation244(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("os-environment-credential-binding-request.v1") ?? null)], ["credentialReference", (structuredClone("LOC_GEMINI_API_KEY") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04") ?? null)], ["invocationIdentity", (structuredClone("obtain-governed-model-response-execution") ?? null)], ["requestingCapabilityId", (structuredClone("obtain-governed-model-response") ?? null)]]));
}

export function operation245(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("os-environment-credential-binding-request.v1"));
}

export function operation246(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("LOC_GEMINI_API_KEY"));
}

export function operation247(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("governed-model-invocation"));
}

export function operation248(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04"));
}

export function operation249(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("obtain-governed-model-response-execution"));
}

export function operation250(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("obtain-governed-model-response"));
}

export function operation251(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("os-environment-credential-binding-request.v1") ?? null)], ["credentialReference", (structuredClone("LOC_OPENAI_API_KEY") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109") ?? null)], ["invocationIdentity", (structuredClone("obtain-governed-model-response-execution") ?? null)], ["requestingCapabilityId", (structuredClone("obtain-governed-model-response") ?? null)]]));
}

export function operation252(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("os-environment-credential-binding-request.v1"));
}

export function operation253(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("LOC_OPENAI_API_KEY"));
}

export function operation254(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("governed-model-invocation"));
}

export function operation255(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109"));
}

export function operation256(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("obtain-governed-model-response-execution"));
}

export function operation257(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("obtain-governed-model-response"));
}

export function operation258(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED")));
}

export function operation259(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolutionStatus"));
}

export function operation260(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EMBODIMENT_AUTHORIZED"));
}

export function operation261(input, context) {
  return invokeDeclaredOperation(descriptors[261], input, context);
}

export function operation262(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation263(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["provider"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidate"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.providers"), scope)) }; scope = { ...scope, ["model"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")))({ ...scope, ["candidateModel"]: item }))) ?? null))(sfxValueAt(scope["provider"], "models"), scope)) }; scope = { ...scope, ["systemMessage"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")))({ ...scope, ["message"]: item }))) ?? null))(sfxValueAt(scope["input"], "modelRequest.interaction.messages"), scope)) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]])); })(scope));
}

export function operation264(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")))({ ...scope, ["candidateModel"]: item }))) ?? null))(sfxValueAt(scope["provider"], "models"), scope));
}

export function operation265(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "models"));
}

export function operation266(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")));
}

export function operation267(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["candidateModel"], "alias"));
}

export function operation268(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.modelAlias"));
}

export function operation269(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidate"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.providers"), scope));
}

export function operation270(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerConveyor.providers"));
}

export function operation271(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")));
}

export function operation272(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["candidate"], "providerAuthorityId"));
}

export function operation273(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "selectedProviderAuthorityId"));
}

export function operation274(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")))({ ...scope, ["message"]: item }))) ?? null))(sfxValueAt(scope["input"], "modelRequest.interaction.messages"), scope));
}

export function operation275(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.interaction.messages"));
}

export function operation276(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")));
}

export function operation277(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation278(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("system"));
}

export function operation279(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation280(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation281(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation282(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation283(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("execute-governed-model-invocation-input.v1"));
}

export function operation284(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation285(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]));
}

export function operation286(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("execute-projected-model-provider-attempt-input.v1"));
}

export function operation287(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]));
}

export function operation288(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "adapterIdentity"));
}

export function operation289(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "allowedResponseHeaders"));
}

export function operation290(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("caller-signal"));
}

export function operation291(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "credentialReference"));
}

export function operation292(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "endpointAuthorityDigest"));
}

export function operation293(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("https://api.openai.com/v1/chat/completions"));
}

export function operation294(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])));
}

export function operation295(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "resolvedModel"));
}

export function operation296(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini")));
}

export function operation297(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation298(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation299(input, context) {
  return invokeDeclaredOperation(descriptors[299], input, context);
}

export function operation300(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestId"));
}

export function operation301(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(8388608));
}

export function operation302(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-model-provider-protocol"));
}

export function operation303(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]));
}

export function operation304(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-model-provider-protocol-input.v1"));
}

export function operation305(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]));
}

export function operation306(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "adapterIdentity"));
}

export function operation307(input, context) {
  return invokeDeclaredOperation(descriptors[307], input, context);
}

export function operation308(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]));
}

export function operation309(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens"));
}

export function operation310(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.interaction.messages"));
}

export function operation311(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "resolvedModel"));
}

export function operation312(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema"));
}

export function operation313(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature"));
}

export function operation314(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]));
}

export function operation315(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens"));
}

export function operation316(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope));
}

export function operation317(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.interaction.messages"));
}

export function operation318(input, context) {
  return invokeDeclaredOperation(descriptors[318], input, context);
}

export function operation319(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]);
}

export function operation320(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]));
}

export function operation321(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)]);
}

export function operation322(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]));
}

export function operation323(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "content"));
}

export function operation324(input, context) {
  return invokeDeclaredOperation(descriptors[324], input, context);
}

export function operation325(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation326(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("model"));
}

export function operation327(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant")));
}

export function operation328(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation329(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("assistant"));
}

export function operation330(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([]);
}

export function operation331(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")));
}

export function operation332(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation333(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("system"));
}

export function operation334(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema"));
}

export function operation335(input, context) {
  return invokeDeclaredOperation(descriptors[335], input, context);
}

export function operation336(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation337(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]));
}

export function operation338(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)]);
}

export function operation339(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]));
}

export function operation340(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["systemMessage"], "content"));
}

export function operation341(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system")));
}

export function operation342(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["systemMessage"], "role"));
}

export function operation343(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("system"));
}

export function operation344(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature"));
}

export function operation345(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini")));
}

export function operation346(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation347(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation348(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation349(input, context) {
  return invokeDeclaredOperation(descriptors[349], input, context);
}

export function operation350(input, context) {
  return invokeDeclaredOperation(descriptors[350], input, context);
}

export function operation351(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-openai-text"));
}

export function operation352(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-openai-structured"));
}

export function operation353(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json")));
}

export function operation354(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation355(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("json"));
}

export function operation356(input, context) {
  return invokeDeclaredOperation(descriptors[356], input, context);
}

export function operation357(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-gemini-text"));
}

export function operation358(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-gemini-structured"));
}

export function operation359(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json")));
}

export function operation360(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation361(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("json"));
}

export function operation362(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini")));
}

export function operation363(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation364(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation365(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerAuthorityId"));
}

export function operation366(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation367(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestId"));
}

export function operation368(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestLineage"));
}

export function operation369(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "resolvedModel"));
}

export function operation370(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation371(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds"));
}

export function operation372(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation373(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "fixtureBypass"), structuredClone(true)));
}

export function operation374(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "fixtureBypass"));
}

export function operation375(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(true));
}

export function operation376(input, context) {
  return invokeDeclaredOperation(descriptors[376], input, context);
}

export function operation377(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED")));
}

export function operation378(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolutionStatus"));
}

export function operation379(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EMBODIMENT_AUTHORIZED"));
}

export function operation380(input, context) {
  return invokeDeclaredOperation(descriptors[380], input, context);
}

export function operation381(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation382(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["switchRule"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateRule"], "fromProviderAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidateRule"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.switchRules"), scope)) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["providerSwitchCount", ((sfxTruthy((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition"))) ? structuredClone(1) : structuredClone(0)) ?? null)], ["selectedProviderAuthorityId", ((sfxTruthy((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition"))) ? sfxValueAt(scope["switchRule"], "toProviderAuthorityId") : sfxValueAt(scope["input"], "selectedProviderAuthorityId")) ?? null)], ["switchRequired", ((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition")) ?? null)]])); })(scope));
}

export function operation383(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateRule"], "fromProviderAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidateRule"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.switchRules"), scope));
}

export function operation384(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerConveyor.switchRules"));
}

export function operation385(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["candidateRule"], "fromProviderAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")));
}

export function operation386(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["candidateRule"], "fromProviderAuthorityId"));
}

export function operation387(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "selectedProviderAuthorityId"));
}

export function operation388(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["providerSwitchCount", ((sfxTruthy((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition"))) ? structuredClone(1) : structuredClone(0)) ?? null)], ["selectedProviderAuthorityId", ((sfxTruthy((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition"))) ? sfxValueAt(scope["switchRule"], "toProviderAuthorityId") : sfxValueAt(scope["input"], "selectedProviderAuthorityId")) ?? null)], ["switchRequired", ((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition")) ?? null)]])));
}

export function operation389(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation390(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["providerSwitchCount", ((sfxTruthy((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition"))) ? structuredClone(1) : structuredClone(0)) ?? null)], ["selectedProviderAuthorityId", ((sfxTruthy((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition"))) ? sfxValueAt(scope["switchRule"], "toProviderAuthorityId") : sfxValueAt(scope["input"], "selectedProviderAuthorityId")) ?? null)], ["switchRequired", ((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition")) ?? null)]]));
}

export function operation391(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(0));
}

export function operation392(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(1));
}

export function operation393(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition")));
}

export function operation394(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["switchRule"], "onDispositions"));
}

export function operation395(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "primaryModelEvidence.disposition"));
}

export function operation396(input, context) {
  return invokeDeclaredOperation(descriptors[396], input, context);
}

export function operation397(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "selectedProviderAuthorityId"));
}

export function operation398(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["switchRule"], "toProviderAuthorityId"));
}

export function operation399(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition")));
}

export function operation400(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["switchRule"], "onDispositions"));
}

export function operation401(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "primaryModelEvidence.disposition"));
}

export function operation402(input, context) {
  return invokeDeclaredOperation(descriptors[402], input, context);
}

export function operation403(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((sfxValueAt(scope["switchRule"], "onDispositions")).includes(sfxValueAt(scope["input"], "primaryModelEvidence.disposition")));
}

export function operation404(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["switchRule"], "onDispositions"));
}

export function operation405(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "primaryModelEvidence.disposition"));
}

export function operation406(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["fixtureBypass", (structuredClone(true) ?? null)], ["primaryModelEvidence", (sfxValueAt(scope["input"], "") ?? null)], ["providerSwitchCount", (structuredClone(0) ?? null)], ["selectedProviderAuthorityId", (structuredClone("primary-cognitive-provider") ?? null)], ["switchRequired", (structuredClone(false) ?? null)]])));
}

export function operation407(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation408(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["fixtureBypass", (structuredClone(true) ?? null)], ["primaryModelEvidence", (sfxValueAt(scope["input"], "") ?? null)], ["providerSwitchCount", (structuredClone(0) ?? null)], ["selectedProviderAuthorityId", (structuredClone("primary-cognitive-provider") ?? null)], ["switchRequired", (structuredClone(false) ?? null)]]));
}

export function operation409(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(true));
}

export function operation410(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation411(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(0));
}

export function operation412(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("primary-cognitive-provider"));
}

export function operation413(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(false));
}

export function operation414(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "carrierType"), structuredClone("governed-model-response-evidence.v1")));
}

export function operation415(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "carrierType"));
}

export function operation416(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("governed-model-response-evidence.v1"));
}

export function operation417(input, context) {
  return invokeDeclaredOperation(descriptors[417], input, context);
}

export function operation418(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED")));
}

export function operation419(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolutionStatus"));
}

export function operation420(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EMBODIMENT_AUTHORIZED"));
}

export function operation421(input, context) {
  return invokeDeclaredOperation(descriptors[421], input, context);
}

export function operation422(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation423(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["provider"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidate"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.providers"), scope)) }; scope = { ...scope, ["model"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")))({ ...scope, ["candidateModel"]: item }))) ?? null))(sfxValueAt(scope["provider"], "models"), scope)) }; scope = { ...scope, ["systemMessage"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")))({ ...scope, ["message"]: item }))) ?? null))(sfxValueAt(scope["input"], "modelRequest.interaction.messages"), scope)) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]])); })(scope));
}

export function operation424(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")))({ ...scope, ["candidateModel"]: item }))) ?? null))(sfxValueAt(scope["provider"], "models"), scope));
}

export function operation425(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "models"));
}

export function operation426(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["candidateModel"], "alias"), sfxValueAt(scope["input"], "modelRequest.modelAlias")));
}

export function operation427(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["candidateModel"], "alias"));
}

export function operation428(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.modelAlias"));
}

export function operation429(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")))({ ...scope, ["candidate"]: item }))) ?? null))(sfxValueAt(scope["input"], "providerConveyor.providers"), scope));
}

export function operation430(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerConveyor.providers"));
}

export function operation431(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["candidate"], "providerAuthorityId"), sfxValueAt(scope["input"], "selectedProviderAuthorityId")));
}

export function operation432(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["candidate"], "providerAuthorityId"));
}

export function operation433(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "selectedProviderAuthorityId"));
}

export function operation434(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")))({ ...scope, ["message"]: item }))) ?? null))(sfxValueAt(scope["input"], "modelRequest.interaction.messages"), scope));
}

export function operation435(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.interaction.messages"));
}

export function operation436(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")));
}

export function operation437(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation438(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("system"));
}

export function operation439(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation440(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation441(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["currentInvocationRequest", (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation442(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("execute-governed-model-invocation-input.v1") ?? null)], ["payload", (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation443(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("execute-governed-model-invocation-input.v1"));
}

export function operation444(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["attemptPlan", (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation445(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("execute-projected-model-provider-attempt-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]) ?? null)]]));
}

export function operation446(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("execute-projected-model-provider-attempt-input.v1"));
}

export function operation447(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["allowedResponseHeaders", (sfxValueAt(scope["provider"], "allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (structuredClone("caller-signal") ?? null)], ["credentialReference", (sfxValueAt(scope["provider"], "credentialReference") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["provider"], "endpointAuthorityDigest") ?? null)], ["endpointUrl", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])) : structuredClone("https://api.openai.com/v1/chat/completions")) ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "requestId") ?? null)], ["maxResponseBytes", (structuredClone(8388608) ?? null)], ["protocolProjectionIdentity", (structuredClone("project-model-provider-protocol") ?? null)], ["protocolProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]) ?? null)], ["providerAuthorityId", (sfxValueAt(scope["provider"], "providerAuthorityId") ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestId", (sfxValueAt(scope["input"], "requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "requestLineage") ?? null)], ["resolvedModel", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseFormat", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds") ?? null)]]));
}

export function operation448(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "adapterIdentity"));
}

export function operation449(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "allowedResponseHeaders"));
}

export function operation450(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("caller-signal"));
}

export function operation451(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "credentialReference"));
}

export function operation452(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "endpointAuthorityDigest"));
}

export function operation453(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("https://api.openai.com/v1/chat/completions"));
}

export function operation454(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxFormat("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent", Object.fromEntries([["model", (sfxValueAt(scope["model"], "resolvedModel"))]])));
}

export function operation455(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "resolvedModel"));
}

export function operation456(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini")));
}

export function operation457(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation458(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation459(input, context) {
  return invokeDeclaredOperation(descriptors[459], input, context);
}

export function operation460(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestId"));
}

export function operation461(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(8388608));
}

export function operation462(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-model-provider-protocol"));
}

export function operation463(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]) ?? null)]]));
}

export function operation464(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-model-provider-protocol-input.v1"));
}

export function operation465(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["provider"], "adapterIdentity") ?? null)], ["context", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]) : Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]])) ?? null)], ["providerKind", (sfxValueAt(scope["provider"], "providerKind") ?? null)], ["requestType", ((sfxTruthy(sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-gemini-structured") : structuredClone("project-gemini-text")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? structuredClone("project-openai-structured") : structuredClone("project-openai-text"))) ?? null)]]));
}

export function operation466(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "adapterIdentity"));
}

export function operation467(input, context) {
  return invokeDeclaredOperation(descriptors[467], input, context);
}

export function operation468(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (sfxValueAt(scope["input"], "modelRequest.interaction.messages") ?? null)], ["model", (sfxValueAt(scope["model"], "resolvedModel") ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]));
}

export function operation469(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens"));
}

export function operation470(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.interaction.messages"));
}

export function operation471(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "resolvedModel"));
}

export function operation472(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema"));
}

export function operation473(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature"));
}

export function operation474(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["maxTokens", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens") ?? null)], ["messages", (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope) ?? null)], ["responseSchema", (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema") ?? null)], ["systemInstruction", ((sfxTruthy(sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system"))) ? Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]) : structuredClone(null)) ?? null)], ["temperature", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature") ?? null)]]));
}

export function operation475(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.maximumOutputTokens"));
}

export function operation476(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => __source.flatMap((item, index) => ((scope) => (sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system"))) ? [] : [(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]))({ ...scope, ["message"]: item, ["messageIndex"]: index })))((sfxValueAt(scope["input"], "modelRequest.interaction.messages")), scope));
}

export function operation477(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.interaction.messages"));
}

export function operation478(input, context) {
  return invokeDeclaredOperation(descriptors[478], input, context);
}

export function operation479(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]) ?? null)]);
}

export function operation480(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)] ?? null)], ["role", ((sfxTruthy(sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant"))) ? structuredClone("model") : sfxValueAt(scope["message"], "role")) ?? null)]]));
}

export function operation481(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]) ?? null)]);
}

export function operation482(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["text", (sfxValueAt(scope["message"], "content") ?? null)]]));
}

export function operation483(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "content"));
}

export function operation484(input, context) {
  return invokeDeclaredOperation(descriptors[484], input, context);
}

export function operation485(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation486(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("model"));
}

export function operation487(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("assistant")));
}

export function operation488(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation489(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("assistant"));
}

export function operation490(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([]);
}

export function operation491(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["message"], "role"), structuredClone("system")));
}

export function operation492(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["message"], "role"));
}

export function operation493(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("system"));
}

export function operation494(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "protocolResponsePolicy.responseSchema"));
}

export function operation495(input, context) {
  return invokeDeclaredOperation(descriptors[495], input, context);
}

export function operation496(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation497(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["parts", ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)] ?? null)]]));
}

export function operation498(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]) ?? null)]);
}

export function operation499(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["text", (sfxValueAt(scope["systemMessage"], "content") ?? null)]]));
}

export function operation500(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["systemMessage"], "content"));
}

export function operation501(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["systemMessage"], "role"), structuredClone("system")));
}

export function operation502(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["systemMessage"], "role"));
}

export function operation503(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("system"));
}

export function operation504(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.temperature"));
}

export function operation505(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini")));
}

export function operation506(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation507(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation508(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation509(input, context) {
  return invokeDeclaredOperation(descriptors[509], input, context);
}

export function operation510(input, context) {
  return invokeDeclaredOperation(descriptors[510], input, context);
}

export function operation511(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-openai-text"));
}

export function operation512(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-openai-structured"));
}

export function operation513(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json")));
}

export function operation514(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation515(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("json"));
}

export function operation516(input, context) {
  return invokeDeclaredOperation(descriptors[516], input, context);
}

export function operation517(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-gemini-text"));
}

export function operation518(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-gemini-structured"));
}

export function operation519(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json")));
}

export function operation520(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation521(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("json"));
}

export function operation522(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerKind"), structuredClone("gemini")));
}

export function operation523(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation524(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation525(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerAuthorityId"));
}

export function operation526(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerKind"));
}

export function operation527(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestId"));
}

export function operation528(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestLineage"));
}

export function operation529(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "resolvedModel"));
}

export function operation530(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation531(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.executionPolicy.timeoutMilliseconds"));
}

export function operation532(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation533(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "fixtureBypass"), structuredClone(true)));
}

export function operation534(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "fixtureBypass"));
}

export function operation535(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(true));
}

export function operation536(input, context) {
  return invokeDeclaredOperation(descriptors[536], input, context);
}

export function operation537(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.resolutionStatus"), structuredClone("EMBODIMENT_AUTHORIZED")));
}

export function operation538(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolutionStatus"));
}

export function operation539(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EMBODIMENT_AUTHORIZED"));
}

export function operation540(input, context) {
  return invokeDeclaredOperation(descriptors[540], input, context);
}

export function operation541(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["protocolResponsePolicy", (Object.fromEntries([["format", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["responseSchema", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? sfxValueAt(scope["input"], "modelRequest.responsePolicy.schema") : structuredClone(null)) ?? null)], ["schemaSourceConnector", (structuredClone("modelRequest.responsePolicy.schema") ?? null)]]) ?? null)]])));
}

export function operation542(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation543(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["protocolResponsePolicy", (Object.fromEntries([["format", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["responseSchema", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? sfxValueAt(scope["input"], "modelRequest.responsePolicy.schema") : structuredClone(null)) ?? null)], ["schemaSourceConnector", (structuredClone("modelRequest.responsePolicy.schema") ?? null)]]) ?? null)]]));
}

export function operation544(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["format", (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format") ?? null)], ["responseSchema", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json"))) ? sfxValueAt(scope["input"], "modelRequest.responsePolicy.schema") : structuredClone(null)) ?? null)], ["schemaSourceConnector", (structuredClone("modelRequest.responsePolicy.schema") ?? null)]]));
}

export function operation545(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation546(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation547(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.schema"));
}

export function operation548(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"), structuredClone("json")));
}

export function operation549(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.responsePolicy.format"));
}

export function operation550(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("json"));
}

export function operation551(input, context) {
  return invokeDeclaredOperation(descriptors[551], input, context);
}

export function operation552(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("modelRequest.responsePolicy.schema"));
}

export function operation553(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["conveyor"]: ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "providerConveyor.authorityType"), structuredClone("model-provider-conveyor-authority.v1"))) ? sfxValueAt(scope["input"], "providerConveyor") : structuredClone({"authorityType":"model-provider-conveyor-authority.v1","conveyorId":"capability-authoring-model-conveyor.v1","maximumProviderSwitches":1,"providers":[{"adapterIdentity":"gemini-generate-content.v1","allowedResponseHeaders":["content-type","x-goog-request-id"],"credentialReference":"LOC_GEMINI_API_KEY","endpointAuthorityDigest":"sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04","models":[{"alias":"instruction-capable-model","resolvedModel":"gemini-2.5-pro"},{"alias":"reasoning-capable-model","resolvedModel":"gemini-2.5-flash"}],"providerAuthorityId":"primary-cognitive-provider","providerKind":"gemini"},{"adapterIdentity":"openai-chat-completions.v1","allowedResponseHeaders":["content-type","x-request-id"],"credentialReference":"LOC_OPENAI_API_KEY","endpointAuthorityDigest":"sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109","models":[{"alias":"instruction-capable-model","resolvedModel":"gpt-4.1-mini"}],"providerAuthorityId":"secondary-cognitive-provider","providerKind":"openai"}],"switchRules":[]}))) }; scope = { ...scope, ["requestProvider"]: (sfxValueAt(scope["input"], "modelRequest.providerAuthorityId")) }; scope = { ...scope, ["providerEntry"]: (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["provider"], "providerAuthorityId"), sfxValueAt(scope["requestProvider"], "")))({ ...scope, ["provider"]: item }))) ?? null))(sfxValueAt(scope["conveyor"], "providers"), scope)) }; scope = { ...scope, ["requestAlias"]: (sfxValueAt(scope["input"], "modelRequest.modelAlias")) }; scope = { ...scope, ["aliasEntry"]: ((sfxTruthy(sfxValueAt(scope["providerEntry"], "")) ? ((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["model"], "alias"), sfxValueAt(scope["requestAlias"], "")))({ ...scope, ["model"]: item }))) ?? null))(sfxValueAt(scope["providerEntry"], "models"), scope) : structuredClone(null))) }; scope = { ...scope, ["substitutionRequested"]: ((sfxTruthy(sfxValueAt(scope["input"], "modelRequest.providerSubstitutionRequested")) ? sfxValueAt(scope["input"], "modelRequest.providerSubstitutionRequested") : structuredClone(false))) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["payload", ((sfxTruthy(sfxValueAt(scope["aliasEntry"], "")) ? Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["providerEntry"], "adapterIdentity") ?? null)], ["aliasResolutionLineage", (Object.fromEntries([["modelAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["providerAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)]]) ?? null)], ["credentialReference", (sfxValueAt(scope["providerEntry"], "credentialReference") ?? null)], ["resolutionStatus", ((sfxTruthy(sfxValueAt(scope["substitutionRequested"], "")) ? structuredClone("SUBSTITUTION_NOT_AUTHORIZED") : structuredClone("EMBODIMENT_AUTHORIZED")) ?? null)], ["resolvedModel", (sfxValueAt(scope["aliasEntry"], "resolvedModel") ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["providerEntry"], "providerAuthorityId") ?? null)]]) : Object.fromEntries([["rejectedAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["rejectedProviderAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)], ["resolutionStatus", (structuredClone("ALIAS_REJECTED") ?? null)]])) ?? null)]])); })(scope));
}

export function operation554(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation555(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["model"], "alias"), sfxValueAt(scope["requestAlias"], "")))({ ...scope, ["model"]: item }))) ?? null))(sfxValueAt(scope["providerEntry"], "models"), scope));
}

export function operation556(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["providerEntry"], "models"));
}

export function operation557(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["model"], "alias"), sfxValueAt(scope["requestAlias"], "")));
}

export function operation558(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["model"], "alias"));
}

export function operation559(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["requestAlias"], ""));
}

export function operation560(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["providerEntry"], ""));
}

export function operation561(input, context) {
  return invokeDeclaredOperation(descriptors[561], input, context);
}

export function operation562(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone({"authorityType":"model-provider-conveyor-authority.v1","conveyorId":"capability-authoring-model-conveyor.v1","maximumProviderSwitches":1,"providers":[{"adapterIdentity":"gemini-generate-content.v1","allowedResponseHeaders":["content-type","x-goog-request-id"],"credentialReference":"LOC_GEMINI_API_KEY","endpointAuthorityDigest":"sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04","models":[{"alias":"instruction-capable-model","resolvedModel":"gemini-2.5-pro"},{"alias":"reasoning-capable-model","resolvedModel":"gemini-2.5-flash"}],"providerAuthorityId":"primary-cognitive-provider","providerKind":"gemini"},{"adapterIdentity":"openai-chat-completions.v1","allowedResponseHeaders":["content-type","x-request-id"],"credentialReference":"LOC_OPENAI_API_KEY","endpointAuthorityDigest":"sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109","models":[{"alias":"instruction-capable-model","resolvedModel":"gpt-4.1-mini"}],"providerAuthorityId":"secondary-cognitive-provider","providerKind":"openai"}],"switchRules":[]}));
}

export function operation563(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerConveyor"));
}

export function operation564(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "providerConveyor.authorityType"), structuredClone("model-provider-conveyor-authority.v1")));
}

export function operation565(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "providerConveyor.authorityType"));
}

export function operation566(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("model-provider-conveyor-authority.v1"));
}

export function operation567(input, context) {
  return invokeDeclaredOperation(descriptors[567], input, context);
}

export function operation568(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => (__source.find((item) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["provider"], "providerAuthorityId"), sfxValueAt(scope["requestProvider"], "")))({ ...scope, ["provider"]: item }))) ?? null))(sfxValueAt(scope["conveyor"], "providers"), scope));
}

export function operation569(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["conveyor"], "providers"));
}

export function operation570(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["provider"], "providerAuthorityId"), sfxValueAt(scope["requestProvider"], "")));
}

export function operation571(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["provider"], "providerAuthorityId"));
}

export function operation572(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["requestProvider"], ""));
}

export function operation573(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.modelAlias"));
}

export function operation574(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.providerAuthorityId"));
}

export function operation575(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(false));
}

export function operation576(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.providerSubstitutionRequested"));
}

export function operation577(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "modelRequest.providerSubstitutionRequested"));
}

export function operation578(input, context) {
  return invokeDeclaredOperation(descriptors[578], input, context);
}

export function operation579(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["payload", ((sfxTruthy(sfxValueAt(scope["aliasEntry"], "")) ? Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["providerEntry"], "adapterIdentity") ?? null)], ["aliasResolutionLineage", (Object.fromEntries([["modelAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["providerAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)]]) ?? null)], ["credentialReference", (sfxValueAt(scope["providerEntry"], "credentialReference") ?? null)], ["resolutionStatus", ((sfxTruthy(sfxValueAt(scope["substitutionRequested"], "")) ? structuredClone("SUBSTITUTION_NOT_AUTHORIZED") : structuredClone("EMBODIMENT_AUTHORIZED")) ?? null)], ["resolvedModel", (sfxValueAt(scope["aliasEntry"], "resolvedModel") ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["providerEntry"], "providerAuthorityId") ?? null)]]) : Object.fromEntries([["rejectedAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["rejectedProviderAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)], ["resolutionStatus", (structuredClone("ALIAS_REJECTED") ?? null)]])) ?? null)]])));
}

export function operation580(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation581(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["payload", ((sfxTruthy(sfxValueAt(scope["aliasEntry"], "")) ? Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["providerEntry"], "adapterIdentity") ?? null)], ["aliasResolutionLineage", (Object.fromEntries([["modelAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["providerAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)]]) ?? null)], ["credentialReference", (sfxValueAt(scope["providerEntry"], "credentialReference") ?? null)], ["resolutionStatus", ((sfxTruthy(sfxValueAt(scope["substitutionRequested"], "")) ? structuredClone("SUBSTITUTION_NOT_AUTHORIZED") : structuredClone("EMBODIMENT_AUTHORIZED")) ?? null)], ["resolvedModel", (sfxValueAt(scope["aliasEntry"], "resolvedModel") ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["providerEntry"], "providerAuthorityId") ?? null)]]) : Object.fromEntries([["rejectedAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["rejectedProviderAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)], ["resolutionStatus", (structuredClone("ALIAS_REJECTED") ?? null)]])) ?? null)]]));
}

export function operation582(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["rejectedAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["rejectedProviderAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)], ["resolutionStatus", (structuredClone("ALIAS_REJECTED") ?? null)]]));
}

export function operation583(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["requestAlias"], ""));
}

export function operation584(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["requestProvider"], ""));
}

export function operation585(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("ALIAS_REJECTED"));
}

export function operation586(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["providerEntry"], "adapterIdentity") ?? null)], ["aliasResolutionLineage", (Object.fromEntries([["modelAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["providerAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)]]) ?? null)], ["credentialReference", (sfxValueAt(scope["providerEntry"], "credentialReference") ?? null)], ["resolutionStatus", ((sfxTruthy(sfxValueAt(scope["substitutionRequested"], "")) ? structuredClone("SUBSTITUTION_NOT_AUTHORIZED") : structuredClone("EMBODIMENT_AUTHORIZED")) ?? null)], ["resolvedModel", (sfxValueAt(scope["aliasEntry"], "resolvedModel") ?? null)], ["resolvedProviderAuthorityId", (sfxValueAt(scope["providerEntry"], "providerAuthorityId") ?? null)]]));
}

export function operation587(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["providerEntry"], "adapterIdentity"));
}

export function operation588(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["modelAlias", (sfxValueAt(scope["requestAlias"], "") ?? null)], ["providerAuthority", (sfxValueAt(scope["requestProvider"], "") ?? null)]]));
}

export function operation589(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["requestAlias"], ""));
}

export function operation590(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["requestProvider"], ""));
}

export function operation591(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["providerEntry"], "credentialReference"));
}

export function operation592(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EMBODIMENT_AUTHORIZED"));
}

export function operation593(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("SUBSTITUTION_NOT_AUTHORIZED"));
}

export function operation594(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["substitutionRequested"], ""));
}

export function operation595(input, context) {
  return invokeDeclaredOperation(descriptors[595], input, context);
}

export function operation596(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["aliasEntry"], "resolvedModel"));
}

export function operation597(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["providerEntry"], "providerAuthorityId"));
}

export function operation598(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["aliasEntry"], ""));
}

export function operation599(input, context) {
  return invokeDeclaredOperation(descriptors[599], input, context);
}

const implementationByIndex = Object.freeze([operation0, operation1, operation2, operation3, operation4, operation5, operation6, operation7, operation8, operation9, operation10, operation11, operation12, operation13, operation14, operation15, operation16, operation17, operation18, operation19, operation20, operation21, operation22, operation23, operation24, operation25, operation26, operation27, operation28, operation29, operation30, operation31, operation32, operation33, operation34, operation35, operation36, operation37, operation38, operation39, operation40, operation41, operation42, operation43, operation44, operation45, operation46, operation47, operation48, operation49, operation50, operation51, operation52, operation53, operation54, operation55, operation56, operation57, operation58, operation59, operation60, operation61, operation62, operation63, operation64, operation65, operation66, operation67, operation68, operation69, operation70, operation71, operation72, operation73, operation74, operation75, operation76, operation77, operation78, operation79, operation80, operation81, operation82, operation83, operation84, operation85, operation86, operation87, operation88, operation89, operation90, operation91, operation92, operation93, operation94, operation95, operation96, operation97, operation98, operation99, operation100, operation101, operation102, operation103, operation104, operation105, operation106, operation107, operation108, operation109, operation110, operation111, operation112, operation113, operation114, operation115, operation116, operation117, operation118, operation119, operation120, operation121, operation122, operation123, operation124, operation125, operation126, operation127, operation128, operation129, operation130, operation131, operation132, operation133, operation134, operation135, operation136, operation137, operation138, operation139, operation140, operation141, operation142, operation143, operation144, operation145, operation146, operation147, operation148, operation149, operation150, operation151, operation152, operation153, operation154, operation155, operation156, operation157, operation158, operation159, operation160, operation161, operation162, operation163, operation164, operation165, operation166, operation167, operation168, operation169, operation170, operation171, operation172, operation173, operation174, operation175, operation176, operation177, operation178, operation179, operation180, operation181, operation182, operation183, operation184, operation185, operation186, operation187, operation188, operation189, operation190, operation191, operation192, operation193, operation194, operation195, operation196, operation197, operation198, operation199, operation200, operation201, operation202, operation203, operation204, operation205, operation206, operation207, operation208, operation209, operation210, operation211, operation212, operation213, operation214, operation215, operation216, operation217, operation218, operation219, operation220, operation221, operation222, operation223, operation224, operation225, operation226, operation227, operation228, operation229, operation230, operation231, operation232, operation233, operation234, operation235, operation236, operation237, operation238, operation239, operation240, operation241, operation242, operation243, operation244, operation245, operation246, operation247, operation248, operation249, operation250, operation251, operation252, operation253, operation254, operation255, operation256, operation257, operation258, operation259, operation260, operation261, operation262, operation263, operation264, operation265, operation266, operation267, operation268, operation269, operation270, operation271, operation272, operation273, operation274, operation275, operation276, operation277, operation278, operation279, operation280, operation281, operation282, operation283, operation284, operation285, operation286, operation287, operation288, operation289, operation290, operation291, operation292, operation293, operation294, operation295, operation296, operation297, operation298, operation299, operation300, operation301, operation302, operation303, operation304, operation305, operation306, operation307, operation308, operation309, operation310, operation311, operation312, operation313, operation314, operation315, operation316, operation317, operation318, operation319, operation320, operation321, operation322, operation323, operation324, operation325, operation326, operation327, operation328, operation329, operation330, operation331, operation332, operation333, operation334, operation335, operation336, operation337, operation338, operation339, operation340, operation341, operation342, operation343, operation344, operation345, operation346, operation347, operation348, operation349, operation350, operation351, operation352, operation353, operation354, operation355, operation356, operation357, operation358, operation359, operation360, operation361, operation362, operation363, operation364, operation365, operation366, operation367, operation368, operation369, operation370, operation371, operation372, operation373, operation374, operation375, operation376, operation377, operation378, operation379, operation380, operation381, operation382, operation383, operation384, operation385, operation386, operation387, operation388, operation389, operation390, operation391, operation392, operation393, operation394, operation395, operation396, operation397, operation398, operation399, operation400, operation401, operation402, operation403, operation404, operation405, operation406, operation407, operation408, operation409, operation410, operation411, operation412, operation413, operation414, operation415, operation416, operation417, operation418, operation419, operation420, operation421, operation422, operation423, operation424, operation425, operation426, operation427, operation428, operation429, operation430, operation431, operation432, operation433, operation434, operation435, operation436, operation437, operation438, operation439, operation440, operation441, operation442, operation443, operation444, operation445, operation446, operation447, operation448, operation449, operation450, operation451, operation452, operation453, operation454, operation455, operation456, operation457, operation458, operation459, operation460, operation461, operation462, operation463, operation464, operation465, operation466, operation467, operation468, operation469, operation470, operation471, operation472, operation473, operation474, operation475, operation476, operation477, operation478, operation479, operation480, operation481, operation482, operation483, operation484, operation485, operation486, operation487, operation488, operation489, operation490, operation491, operation492, operation493, operation494, operation495, operation496, operation497, operation498, operation499, operation500, operation501, operation502, operation503, operation504, operation505, operation506, operation507, operation508, operation509, operation510, operation511, operation512, operation513, operation514, operation515, operation516, operation517, operation518, operation519, operation520, operation521, operation522, operation523, operation524, operation525, operation526, operation527, operation528, operation529, operation530, operation531, operation532, operation533, operation534, operation535, operation536, operation537, operation538, operation539, operation540, operation541, operation542, operation543, operation544, operation545, operation546, operation547, operation548, operation549, operation550, operation551, operation552, operation553, operation554, operation555, operation556, operation557, operation558, operation559, operation560, operation561, operation562, operation563, operation564, operation565, operation566, operation567, operation568, operation569, operation570, operation571, operation572, operation573, operation574, operation575, operation576, operation577, operation578, operation579, operation580, operation581, operation582, operation583, operation584, operation585, operation586, operation587, operation588, operation589, operation590, operation591, operation592, operation593, operation594, operation595, operation596, operation597, operation598, operation599]);
export const operationFunctions = Object.freeze(Object.fromEntries(
  descriptors.map((descriptor, index) => [descriptor.operationId, implementationByIndex[index]])
));
const bindingDescriptors = Object.freeze([]);

const bindingImplementationByIndex = Object.freeze([]);
export const bindingProjectorByAuthorityId = Object.freeze(Object.fromEntries(
  bindingDescriptors.map((descriptor, index) => [descriptor.bindingAuthorityId, bindingImplementationByIndex[index]])
));

