// GENERATED CAPABILITY OPERATIONS. Do not hand-edit.
import crypto from "node:crypto";
import fs from "node:fs";
import { bindValueAt, valueAt } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/native-mechanic-primitives.mjs";

const descriptorDocument = JSON.parse(fs.readFileSync(new URL("./execution-operations.json", import.meta.url), "utf8"));
const descriptors = Array.isArray(descriptorDocument.operations) ? descriptorDocument.operations : [];
export const cellContracts = Object.freeze({"cell:mechanic:execute-projected-model-provider-attempt.operation.1":{"inputContractId":"execute-projected-model-provider-attempt-input.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10":{"inputContractId":"semantic-value.v1","outcomeContractId":"projected-model-provider-attempt-evidence.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.attempts":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.else:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.else.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.else.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.then.when.in":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.then.when.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.disposition.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.model":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.provider":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.acceptanceClaimed":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.adapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.credentialNonDisclosureVerified":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.httpStatus":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.providerKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.providerSwitchCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.redactionVerified":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.repairCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.requestHash":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.requestId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.requestLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.responseHash":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.retryCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.timing":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.receipt.fields.transportDisposition":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.finishReason":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.format":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.then.else.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.then.when.in":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.then.when.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.then.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.structuredValue.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.text":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.text:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.text.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.text.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.text.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.text.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.10:expression.fields.response.fields.text.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression.values.1.fields.requestBodyProjectionRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression.values.1.fields.requestBodyProjectionRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression.values.1.fields.requestBodyProjectionRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression.values.1.fields.requestBodyProjectionRequest.fields.payload.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression.values.1.fields.requestBodyProjectionRequest.fields.payload.fields.projectionAuthorityIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression.values.1.fields.requestBodyProjectionRequest.fields.payload.fields.providerAdapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.2:expression.values.1.fields.requestBodyProjectionRequest.fields.payload.fields.wireRequestDocument":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.3":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1.fields.credentialBindingRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1.fields.credentialBindingRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1.fields.credentialBindingRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1.fields.credentialBindingRequest.fields.payload.fields.credentialReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1.fields.credentialBindingRequest.fields.payload.fields.effectLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1.fields.credentialBindingRequest.fields.payload.fields.effectScope":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1.fields.credentialBindingRequest.fields.payload.fields.endpointAuthorityDigest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1.fields.credentialBindingRequest.fields.payload.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.4:expression.values.1.fields.credentialBindingRequest.fields.payload.fields.requestingCapabilityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.5":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.allowedResponseHeaders":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.cancellationScopeReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.credentialInjectionRuleId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.effectLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.endpointAuthorityDigest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.exchangeKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.lineageId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.maxResponseBytes":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.method":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.opaqueCredentialBinding":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.opaqueCredentialBinding.fields.bindingId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.opaqueCredentialBinding.fields.credentialInjectionRuleId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.redirectPolicy":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.requestBodyText":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.requestUrl":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.safeHeaders":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.safeHeaders.fields.content-type":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.6:expression.values.1.fields.httpExchangeRequest.fields.payload.fields.timeoutMilliseconds":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.7":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.bindings.parsedResponse":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.bindings.parsedResponse:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.bindings.parsedResponse.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.bindings.parsedResponse.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.bindings.parsedResponse.then.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.bindings.parsedResponse.then.value.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.bindings.parsedResponse.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.bindings.parsedResponse.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.bindings.parsedResponse.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.parsedProviderResponse":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.adapterIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.finishReason":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.finishReason:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.finishReason.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.finishReason.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.finishReason.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.finishReason.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.finishReason.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then.else.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then.else.value.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then.else.value.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then.when.in":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.then.when.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.when.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.observation.fields.text.when.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.providerKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.8:expression.value.values.1.fields.protocolNormalizationRequest.fields.payload.fields.requestType":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-projected-model-provider-attempt.operation.9":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:scenario:execute-projected-model-provider-attempt":{"inputContractId":"execute-projected-model-provider-attempt-input.v1","outcomeContractId":"projected-model-provider-attempt-evidence.v1"}});

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
  return invokeDeclaredOperation(descriptors[0], input, context);
}

export function operation1(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["attempts", (sfxValueAt(scope["input"], "httpExchangeEvidence.exchangeCount") ?? null)], ["disposition", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL","length","content_filter"])).includes(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason"))) ? structuredClone("PROVIDER_REQUEST_REJECTED") : structuredClone("MODEL_RESPONSE_OBTAINED")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("rejected-endpoint"))) ? structuredClone("MODEL_REQUEST_REJECTED") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("rejected-credential"))) ? structuredClone("PROVIDER_AUTHENTICATION_FAILED") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("cancelled"))) ? structuredClone("EXECUTION_CANCELLED") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("timed-out"))) ? structuredClone("PROVIDER_TIMED_OUT") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("transport-failed"))) ? structuredClone("PROVIDER_UNAVAILABLE") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("retained-non-success"))) ? structuredClone("PROVIDER_UNAVAILABLE") : structuredClone("INTERNAL_EXECUTION_FAILED")))))))) ?? null)], ["model", (sfxValueAt(scope["input"], "payload.resolvedModel") ?? null)], ["provider", (sfxValueAt(scope["input"], "payload.providerAuthorityId") ?? null)], ["receipt", (Object.fromEntries([["acceptanceClaimed", (structuredClone(false) ?? null)], ["adapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["credentialNonDisclosureVerified", (sfxValueAt(scope["input"], "credentialBindingEvidence.nonDisclosureVerified") ?? null)], ["httpStatus", (sfxValueAt(scope["input"], "httpExchangeEvidence.httpStatus") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["providerKind", (sfxValueAt(scope["input"], "payload.providerKind") ?? null)], ["providerSwitchCount", (structuredClone(0) ?? null)], ["redactionVerified", (sfxValueAt(scope["input"], "httpExchangeEvidence.redactionVerified") ?? null)], ["repairCount", (structuredClone(0) ?? null)], ["requestHash", (sfxValueAt(scope["input"], "httpExchangeEvidence.requestBodyHash") ?? null)], ["requestId", (sfxValueAt(scope["input"], "payload.requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["responseHash", (sfxValueAt(scope["input"], "httpExchangeEvidence.responseBodyHash") ?? null)], ["retryCount", (structuredClone(0) ?? null)], ["timing", (sfxValueAt(scope["input"], "httpExchangeEvidence.timing") ?? null)], ["transportDisposition", (sfxValueAt(scope["input"], "httpExchangeEvidence.transportDisposition") ?? null)]]) ?? null)], ["response", (Object.fromEntries([["finishReason", (sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason") ?? null)], ["format", (sfxValueAt(scope["input"], "payload.responseFormat") ?? null)], ["structuredValue", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.responseFormat"), structuredClone("json"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL","length","content_filter"])).includes(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason"))) ? structuredClone(null) : sfxParseJson(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.candidateText"))) : structuredClone(null)) : structuredClone(null)) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.responseFormat"), structuredClone("text"))) ? sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.candidateText") : structuredClone(null)) ?? null)]]) ?? null)]]));
}

export function operation2(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["requestBodyProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-governed-http-request-body-input.v1") ?? null)], ["payload", (Object.fromEntries([["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["projectionAuthorityIdentity", (sfxValueAt(scope["input"], "payload.protocolProjectionIdentity") ?? null)], ["providerAdapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["wireRequestDocument", (sfxValueAt(scope["input"], "protocolProjectionEvidence.payload.wireRequest") ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation3(input, context) {
  return invokeDeclaredOperation(descriptors[3], input, context);
}

export function operation4(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["credentialBindingRequest", (Object.fromEntries([["contractId", (structuredClone("bind-external-credential-reference-input.v1") ?? null)], ["payload", (Object.fromEntries([["credentialReference", (sfxValueAt(scope["input"], "payload.credentialReference") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["requestingCapabilityId", (structuredClone("execute-projected-model-provider-attempt") ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation5(input, context) {
  return invokeDeclaredOperation(descriptors[5], input, context);
}

export function operation6(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["httpExchangeRequest", (Object.fromEntries([["contractId", (structuredClone("observe-governed-http-exchange-input.v1") ?? null)], ["payload", (Object.fromEntries([["allowedResponseHeaders", (sfxValueAt(scope["input"], "payload.allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (sfxValueAt(scope["input"], "payload.cancellationScopeReference") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["exchangeKind", (structuredClone("model-provider") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["lineageId", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["maxResponseBytes", (sfxValueAt(scope["input"], "payload.maxResponseBytes") ?? null)], ["method", (structuredClone("POST") ?? null)], ["opaqueCredentialBinding", (Object.fromEntries([["bindingId", (sfxValueAt(scope["input"], "credentialBindingEvidence.opaqueBindingId") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)]]) ?? null)], ["redirectPolicy", (structuredClone("manual-no-follow") ?? null)], ["requestBodyText", (sfxValueAt(scope["input"], "requestBodyProjectionEvidence.payload.requestBodyText") ?? null)], ["requestUrl", (sfxValueAt(scope["input"], "payload.endpointUrl") ?? null)], ["safeHeaders", (Object.fromEntries([["content-type", (structuredClone("application/json") ?? null)]]) ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "payload.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation7(input, context) {
  return invokeDeclaredOperation(descriptors[7], input, context);
}

export function operation8(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["parsedResponse"]: ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed"))) ? sfxParseJson(sfxBase64DecodeUtf8(sfxValueAt(scope["input"], "httpExchangeEvidence.responseBodyBytes"))) : structuredClone({"candidates":[{"content":{"parts":[]},"finishReason":null}],"choices":[{"finish_reason":null,"message":{"content":null}}]}))) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["parsedProviderResponse", (sfxValueAt(scope["parsedResponse"], "") ?? null)], ["protocolNormalizationRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["observation", (Object.fromEntries([["finishReason", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason") : sfxValueAt(scope["parsedResponse"], "choices.0.finish_reason")) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL"])).includes(sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason"))) ? structuredClone("") : sfxJoin(((__source, scope) => __source.map((item, index) => ((scope) => sfxValueAt(scope["part"], "text"))({ ...scope, ["part"]: item, ["partIndex"]: index })))((sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts")), scope), "")) : sfxValueAt(scope["parsedResponse"], "choices.0.message.content")) ?? null)]]) ?? null)], ["providerKind", (sfxValueAt(scope["input"], "payload.providerKind") ?? null)], ["requestType", (structuredClone("normalize-observation") ?? null)]]) ?? null)]]) ?? null)]])); })(scope));
}

export function operation9(input, context) {
  return invokeDeclaredOperation(descriptors[9], input, context);
}

export function operation10(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["attempts", (sfxValueAt(scope["input"], "httpExchangeEvidence.exchangeCount") ?? null)], ["disposition", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL","length","content_filter"])).includes(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason"))) ? structuredClone("PROVIDER_REQUEST_REJECTED") : structuredClone("MODEL_RESPONSE_OBTAINED")) : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("rejected-endpoint"))) ? structuredClone("MODEL_REQUEST_REJECTED") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("rejected-credential"))) ? structuredClone("PROVIDER_AUTHENTICATION_FAILED") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("cancelled"))) ? structuredClone("EXECUTION_CANCELLED") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("timed-out"))) ? structuredClone("PROVIDER_TIMED_OUT") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("transport-failed"))) ? structuredClone("PROVIDER_UNAVAILABLE") : (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("retained-non-success"))) ? structuredClone("PROVIDER_UNAVAILABLE") : structuredClone("INTERNAL_EXECUTION_FAILED")))))))) ?? null)], ["model", (sfxValueAt(scope["input"], "payload.resolvedModel") ?? null)], ["provider", (sfxValueAt(scope["input"], "payload.providerAuthorityId") ?? null)], ["receipt", (Object.fromEntries([["acceptanceClaimed", (structuredClone(false) ?? null)], ["adapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["credentialNonDisclosureVerified", (sfxValueAt(scope["input"], "credentialBindingEvidence.nonDisclosureVerified") ?? null)], ["httpStatus", (sfxValueAt(scope["input"], "httpExchangeEvidence.httpStatus") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["providerKind", (sfxValueAt(scope["input"], "payload.providerKind") ?? null)], ["providerSwitchCount", (structuredClone(0) ?? null)], ["redactionVerified", (sfxValueAt(scope["input"], "httpExchangeEvidence.redactionVerified") ?? null)], ["repairCount", (structuredClone(0) ?? null)], ["requestHash", (sfxValueAt(scope["input"], "httpExchangeEvidence.requestBodyHash") ?? null)], ["requestId", (sfxValueAt(scope["input"], "payload.requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["responseHash", (sfxValueAt(scope["input"], "httpExchangeEvidence.responseBodyHash") ?? null)], ["retryCount", (structuredClone(0) ?? null)], ["timing", (sfxValueAt(scope["input"], "httpExchangeEvidence.timing") ?? null)], ["transportDisposition", (sfxValueAt(scope["input"], "httpExchangeEvidence.transportDisposition") ?? null)]]) ?? null)], ["response", (Object.fromEntries([["finishReason", (sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason") ?? null)], ["format", (sfxValueAt(scope["input"], "payload.responseFormat") ?? null)], ["structuredValue", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.responseFormat"), structuredClone("json"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL","length","content_filter"])).includes(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason"))) ? structuredClone(null) : sfxParseJson(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.candidateText"))) : structuredClone(null)) : structuredClone(null)) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.responseFormat"), structuredClone("text"))) ? sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.candidateText") : structuredClone(null)) ?? null)]]) ?? null)]]));
}

export function operation11(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.exchangeCount"));
}

export function operation12(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("INTERNAL_EXECUTION_FAILED"));
}

export function operation13(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("PROVIDER_UNAVAILABLE"));
}

export function operation14(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("retained-non-success")));
}

export function operation15(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"));
}

export function operation16(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("retained-non-success"));
}

export function operation17(input, context) {
  return invokeDeclaredOperation(descriptors[17], input, context);
}

export function operation18(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("PROVIDER_UNAVAILABLE"));
}

export function operation19(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("transport-failed")));
}

export function operation20(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"));
}

export function operation21(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("transport-failed"));
}

export function operation22(input, context) {
  return invokeDeclaredOperation(descriptors[22], input, context);
}

export function operation23(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("PROVIDER_TIMED_OUT"));
}

export function operation24(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("timed-out")));
}

export function operation25(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"));
}

export function operation26(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("timed-out"));
}

export function operation27(input, context) {
  return invokeDeclaredOperation(descriptors[27], input, context);
}

export function operation28(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EXECUTION_CANCELLED"));
}

export function operation29(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("cancelled")));
}

export function operation30(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"));
}

export function operation31(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("cancelled"));
}

export function operation32(input, context) {
  return invokeDeclaredOperation(descriptors[32], input, context);
}

export function operation33(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("PROVIDER_AUTHENTICATION_FAILED"));
}

export function operation34(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("rejected-credential")));
}

export function operation35(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"));
}

export function operation36(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("rejected-credential"));
}

export function operation37(input, context) {
  return invokeDeclaredOperation(descriptors[37], input, context);
}

export function operation38(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("MODEL_REQUEST_REJECTED"));
}

export function operation39(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("rejected-endpoint")));
}

export function operation40(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"));
}

export function operation41(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("rejected-endpoint"));
}

export function operation42(input, context) {
  return invokeDeclaredOperation(descriptors[42], input, context);
}

export function operation43(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("MODEL_RESPONSE_OBTAINED"));
}

export function operation44(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("PROVIDER_REQUEST_REJECTED"));
}

export function operation45(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL","length","content_filter"])).includes(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason")));
}

export function operation46(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL","length","content_filter"]));
}

export function operation47(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason"));
}

export function operation48(input, context) {
  return invokeDeclaredOperation(descriptors[48], input, context);
}

export function operation49(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed")));
}

export function operation50(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"));
}

export function operation51(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("completed"));
}

export function operation52(input, context) {
  return invokeDeclaredOperation(descriptors[52], input, context);
}

export function operation53(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.resolvedModel"));
}

export function operation54(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.providerAuthorityId"));
}

export function operation55(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["acceptanceClaimed", (structuredClone(false) ?? null)], ["adapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["credentialNonDisclosureVerified", (sfxValueAt(scope["input"], "credentialBindingEvidence.nonDisclosureVerified") ?? null)], ["httpStatus", (sfxValueAt(scope["input"], "httpExchangeEvidence.httpStatus") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["providerKind", (sfxValueAt(scope["input"], "payload.providerKind") ?? null)], ["providerSwitchCount", (structuredClone(0) ?? null)], ["redactionVerified", (sfxValueAt(scope["input"], "httpExchangeEvidence.redactionVerified") ?? null)], ["repairCount", (structuredClone(0) ?? null)], ["requestHash", (sfxValueAt(scope["input"], "httpExchangeEvidence.requestBodyHash") ?? null)], ["requestId", (sfxValueAt(scope["input"], "payload.requestId") ?? null)], ["requestLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["responseHash", (sfxValueAt(scope["input"], "httpExchangeEvidence.responseBodyHash") ?? null)], ["retryCount", (structuredClone(0) ?? null)], ["timing", (sfxValueAt(scope["input"], "httpExchangeEvidence.timing") ?? null)], ["transportDisposition", (sfxValueAt(scope["input"], "httpExchangeEvidence.transportDisposition") ?? null)]]));
}

export function operation56(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(false));
}

export function operation57(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.adapterIdentity"));
}

export function operation58(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "credentialBindingEvidence.nonDisclosureVerified"));
}

export function operation59(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.httpStatus"));
}

export function operation60(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.invocationIdentity"));
}

export function operation61(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.providerKind"));
}

export function operation62(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(0));
}

export function operation63(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.redactionVerified"));
}

export function operation64(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(0));
}

export function operation65(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.requestBodyHash"));
}

export function operation66(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.requestId"));
}

export function operation67(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.requestLineage"));
}

export function operation68(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.responseBodyHash"));
}

export function operation69(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(0));
}

export function operation70(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.timing"));
}

export function operation71(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.transportDisposition"));
}

export function operation72(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["finishReason", (sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason") ?? null)], ["format", (sfxValueAt(scope["input"], "payload.responseFormat") ?? null)], ["structuredValue", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.responseFormat"), structuredClone("json"))) ? (sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL","length","content_filter"])).includes(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason"))) ? structuredClone(null) : sfxParseJson(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.candidateText"))) : structuredClone(null)) : structuredClone(null)) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.responseFormat"), structuredClone("text"))) ? sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.candidateText") : structuredClone(null)) ?? null)]]));
}

export function operation73(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason"));
}

export function operation74(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.responseFormat"));
}

export function operation75(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation76(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation77(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxParseJson(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.candidateText")));
}

export function operation78(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.candidateText"));
}

export function operation79(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation80(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL","length","content_filter"])).includes(sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason")));
}

export function operation81(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL","length","content_filter"]));
}

export function operation82(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.finishReason"));
}

export function operation83(input, context) {
  return invokeDeclaredOperation(descriptors[83], input, context);
}

export function operation84(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed")));
}

export function operation85(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"));
}

export function operation86(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("completed"));
}

export function operation87(input, context) {
  return invokeDeclaredOperation(descriptors[87], input, context);
}

export function operation88(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.responseFormat"), structuredClone("json")));
}

export function operation89(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.responseFormat"));
}

export function operation90(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("json"));
}

export function operation91(input, context) {
  return invokeDeclaredOperation(descriptors[91], input, context);
}

export function operation92(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation93(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "normalizedProtocolEvidence.payload.normalizedTestimony.candidateText"));
}

export function operation94(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.responseFormat"), structuredClone("text")));
}

export function operation95(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.responseFormat"));
}

export function operation96(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("text"));
}

export function operation97(input, context) {
  return invokeDeclaredOperation(descriptors[97], input, context);
}

export function operation98(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["requestBodyProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-governed-http-request-body-input.v1") ?? null)], ["payload", (Object.fromEntries([["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["projectionAuthorityIdentity", (sfxValueAt(scope["input"], "payload.protocolProjectionIdentity") ?? null)], ["providerAdapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["wireRequestDocument", (sfxValueAt(scope["input"], "protocolProjectionEvidence.payload.wireRequest") ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation99(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation100(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["requestBodyProjectionRequest", (Object.fromEntries([["contractId", (structuredClone("project-governed-http-request-body-input.v1") ?? null)], ["payload", (Object.fromEntries([["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["projectionAuthorityIdentity", (sfxValueAt(scope["input"], "payload.protocolProjectionIdentity") ?? null)], ["providerAdapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["wireRequestDocument", (sfxValueAt(scope["input"], "protocolProjectionEvidence.payload.wireRequest") ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation101(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("project-governed-http-request-body-input.v1") ?? null)], ["payload", (Object.fromEntries([["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["projectionAuthorityIdentity", (sfxValueAt(scope["input"], "payload.protocolProjectionIdentity") ?? null)], ["providerAdapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["wireRequestDocument", (sfxValueAt(scope["input"], "protocolProjectionEvidence.payload.wireRequest") ?? null)]]) ?? null)]]));
}

export function operation102(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-governed-http-request-body-input.v1"));
}

export function operation103(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["projectionAuthorityIdentity", (sfxValueAt(scope["input"], "payload.protocolProjectionIdentity") ?? null)], ["providerAdapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["wireRequestDocument", (sfxValueAt(scope["input"], "protocolProjectionEvidence.payload.wireRequest") ?? null)]]));
}

export function operation104(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.invocationIdentity"));
}

export function operation105(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.protocolProjectionIdentity"));
}

export function operation106(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.adapterIdentity"));
}

export function operation107(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "protocolProjectionEvidence.payload.wireRequest"));
}

export function operation108(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["credentialBindingRequest", (Object.fromEntries([["contractId", (structuredClone("bind-external-credential-reference-input.v1") ?? null)], ["payload", (Object.fromEntries([["credentialReference", (sfxValueAt(scope["input"], "payload.credentialReference") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["requestingCapabilityId", (structuredClone("execute-projected-model-provider-attempt") ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation109(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation110(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["credentialBindingRequest", (Object.fromEntries([["contractId", (structuredClone("bind-external-credential-reference-input.v1") ?? null)], ["payload", (Object.fromEntries([["credentialReference", (sfxValueAt(scope["input"], "payload.credentialReference") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["requestingCapabilityId", (structuredClone("execute-projected-model-provider-attempt") ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation111(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("bind-external-credential-reference-input.v1") ?? null)], ["payload", (Object.fromEntries([["credentialReference", (sfxValueAt(scope["input"], "payload.credentialReference") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["requestingCapabilityId", (structuredClone("execute-projected-model-provider-attempt") ?? null)]]) ?? null)]]));
}

export function operation112(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("bind-external-credential-reference-input.v1"));
}

export function operation113(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["credentialReference", (sfxValueAt(scope["input"], "payload.credentialReference") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["effectScope", (structuredClone("governed-model-invocation") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["requestingCapabilityId", (structuredClone("execute-projected-model-provider-attempt") ?? null)]]));
}

export function operation114(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.credentialReference"));
}

export function operation115(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.requestLineage"));
}

export function operation116(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("governed-model-invocation"));
}

export function operation117(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest"));
}

export function operation118(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.invocationIdentity"));
}

export function operation119(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("execute-projected-model-provider-attempt"));
}

export function operation120(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["httpExchangeRequest", (Object.fromEntries([["contractId", (structuredClone("observe-governed-http-exchange-input.v1") ?? null)], ["payload", (Object.fromEntries([["allowedResponseHeaders", (sfxValueAt(scope["input"], "payload.allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (sfxValueAt(scope["input"], "payload.cancellationScopeReference") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["exchangeKind", (structuredClone("model-provider") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["lineageId", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["maxResponseBytes", (sfxValueAt(scope["input"], "payload.maxResponseBytes") ?? null)], ["method", (structuredClone("POST") ?? null)], ["opaqueCredentialBinding", (Object.fromEntries([["bindingId", (sfxValueAt(scope["input"], "credentialBindingEvidence.opaqueBindingId") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)]]) ?? null)], ["redirectPolicy", (structuredClone("manual-no-follow") ?? null)], ["requestBodyText", (sfxValueAt(scope["input"], "requestBodyProjectionEvidence.payload.requestBodyText") ?? null)], ["requestUrl", (sfxValueAt(scope["input"], "payload.endpointUrl") ?? null)], ["safeHeaders", (Object.fromEntries([["content-type", (structuredClone("application/json") ?? null)]]) ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "payload.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation121(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation122(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["httpExchangeRequest", (Object.fromEntries([["contractId", (structuredClone("observe-governed-http-exchange-input.v1") ?? null)], ["payload", (Object.fromEntries([["allowedResponseHeaders", (sfxValueAt(scope["input"], "payload.allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (sfxValueAt(scope["input"], "payload.cancellationScopeReference") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["exchangeKind", (structuredClone("model-provider") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["lineageId", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["maxResponseBytes", (sfxValueAt(scope["input"], "payload.maxResponseBytes") ?? null)], ["method", (structuredClone("POST") ?? null)], ["opaqueCredentialBinding", (Object.fromEntries([["bindingId", (sfxValueAt(scope["input"], "credentialBindingEvidence.opaqueBindingId") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)]]) ?? null)], ["redirectPolicy", (structuredClone("manual-no-follow") ?? null)], ["requestBodyText", (sfxValueAt(scope["input"], "requestBodyProjectionEvidence.payload.requestBodyText") ?? null)], ["requestUrl", (sfxValueAt(scope["input"], "payload.endpointUrl") ?? null)], ["safeHeaders", (Object.fromEntries([["content-type", (structuredClone("application/json") ?? null)]]) ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "payload.timeoutMilliseconds") ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation123(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("observe-governed-http-exchange-input.v1") ?? null)], ["payload", (Object.fromEntries([["allowedResponseHeaders", (sfxValueAt(scope["input"], "payload.allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (sfxValueAt(scope["input"], "payload.cancellationScopeReference") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["exchangeKind", (structuredClone("model-provider") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["lineageId", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["maxResponseBytes", (sfxValueAt(scope["input"], "payload.maxResponseBytes") ?? null)], ["method", (structuredClone("POST") ?? null)], ["opaqueCredentialBinding", (Object.fromEntries([["bindingId", (sfxValueAt(scope["input"], "credentialBindingEvidence.opaqueBindingId") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)]]) ?? null)], ["redirectPolicy", (structuredClone("manual-no-follow") ?? null)], ["requestBodyText", (sfxValueAt(scope["input"], "requestBodyProjectionEvidence.payload.requestBodyText") ?? null)], ["requestUrl", (sfxValueAt(scope["input"], "payload.endpointUrl") ?? null)], ["safeHeaders", (Object.fromEntries([["content-type", (structuredClone("application/json") ?? null)]]) ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "payload.timeoutMilliseconds") ?? null)]]) ?? null)]]));
}

export function operation124(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("observe-governed-http-exchange-input.v1"));
}

export function operation125(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["allowedResponseHeaders", (sfxValueAt(scope["input"], "payload.allowedResponseHeaders") ?? null)], ["cancellationScopeReference", (sfxValueAt(scope["input"], "payload.cancellationScopeReference") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)], ["effectLineage", (sfxValueAt(scope["input"], "payload.requestLineage") ?? null)], ["endpointAuthorityDigest", (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest") ?? null)], ["exchangeKind", (structuredClone("model-provider") ?? null)], ["invocationIdentity", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["lineageId", (sfxValueAt(scope["input"], "payload.invocationIdentity") ?? null)], ["maxResponseBytes", (sfxValueAt(scope["input"], "payload.maxResponseBytes") ?? null)], ["method", (structuredClone("POST") ?? null)], ["opaqueCredentialBinding", (Object.fromEntries([["bindingId", (sfxValueAt(scope["input"], "credentialBindingEvidence.opaqueBindingId") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)]]) ?? null)], ["redirectPolicy", (structuredClone("manual-no-follow") ?? null)], ["requestBodyText", (sfxValueAt(scope["input"], "requestBodyProjectionEvidence.payload.requestBodyText") ?? null)], ["requestUrl", (sfxValueAt(scope["input"], "payload.endpointUrl") ?? null)], ["safeHeaders", (Object.fromEntries([["content-type", (structuredClone("application/json") ?? null)]]) ?? null)], ["timeoutMilliseconds", (sfxValueAt(scope["input"], "payload.timeoutMilliseconds") ?? null)]]));
}

export function operation126(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.allowedResponseHeaders"));
}

export function operation127(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.cancellationScopeReference"));
}

export function operation128(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId"));
}

export function operation129(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.requestLineage"));
}

export function operation130(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.endpointAuthorityDigest"));
}

export function operation131(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("model-provider"));
}

export function operation132(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.invocationIdentity"));
}

export function operation133(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.invocationIdentity"));
}

export function operation134(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.maxResponseBytes"));
}

export function operation135(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("POST"));
}

export function operation136(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["bindingId", (sfxValueAt(scope["input"], "credentialBindingEvidence.opaqueBindingId") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId") ?? null)]]));
}

export function operation137(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "credentialBindingEvidence.opaqueBindingId"));
}

export function operation138(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "credentialBindingEvidence.credentialInjectionRuleId"));
}

export function operation139(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("manual-no-follow"));
}

export function operation140(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "requestBodyProjectionEvidence.payload.requestBodyText"));
}

export function operation141(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.endpointUrl"));
}

export function operation142(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["content-type", (structuredClone("application/json") ?? null)]]));
}

export function operation143(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("application/json"));
}

export function operation144(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.timeoutMilliseconds"));
}

export function operation145(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["parsedResponse"]: ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed"))) ? sfxParseJson(sfxBase64DecodeUtf8(sfxValueAt(scope["input"], "httpExchangeEvidence.responseBodyBytes"))) : structuredClone({"candidates":[{"content":{"parts":[]},"finishReason":null}],"choices":[{"finish_reason":null,"message":{"content":null}}]}))) }; return sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["parsedProviderResponse", (sfxValueAt(scope["parsedResponse"], "") ?? null)], ["protocolNormalizationRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["observation", (Object.fromEntries([["finishReason", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason") : sfxValueAt(scope["parsedResponse"], "choices.0.finish_reason")) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL"])).includes(sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason"))) ? structuredClone("") : sfxJoin(((__source, scope) => __source.map((item, index) => ((scope) => sfxValueAt(scope["part"], "text"))({ ...scope, ["part"]: item, ["partIndex"]: index })))((sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts")), scope), "")) : sfxValueAt(scope["parsedResponse"], "choices.0.message.content")) ?? null)]]) ?? null)], ["providerKind", (sfxValueAt(scope["input"], "payload.providerKind") ?? null)], ["requestType", (structuredClone("normalize-observation") ?? null)]]) ?? null)]]) ?? null)]])); })(scope));
}

export function operation146(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone({"candidates":[{"content":{"parts":[]},"finishReason":null}],"choices":[{"finish_reason":null,"message":{"content":null}}]}));
}

export function operation147(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxParseJson(sfxBase64DecodeUtf8(sfxValueAt(scope["input"], "httpExchangeEvidence.responseBodyBytes"))));
}

export function operation148(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxBase64DecodeUtf8(sfxValueAt(scope["input"], "httpExchangeEvidence.responseBodyBytes")));
}

export function operation149(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.responseBodyBytes"));
}

export function operation150(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"), structuredClone("completed")));
}

export function operation151(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "httpExchangeEvidence.disposition"));
}

export function operation152(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("completed"));
}

export function operation153(input, context) {
  return invokeDeclaredOperation(descriptors[153], input, context);
}

export function operation154(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxMerge(sfxValueAt(scope["input"], ""), Object.fromEntries([["parsedProviderResponse", (sfxValueAt(scope["parsedResponse"], "") ?? null)], ["protocolNormalizationRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["observation", (Object.fromEntries([["finishReason", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason") : sfxValueAt(scope["parsedResponse"], "choices.0.finish_reason")) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL"])).includes(sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason"))) ? structuredClone("") : sfxJoin(((__source, scope) => __source.map((item, index) => ((scope) => sfxValueAt(scope["part"], "text"))({ ...scope, ["part"]: item, ["partIndex"]: index })))((sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts")), scope), "")) : sfxValueAt(scope["parsedResponse"], "choices.0.message.content")) ?? null)]]) ?? null)], ["providerKind", (sfxValueAt(scope["input"], "payload.providerKind") ?? null)], ["requestType", (structuredClone("normalize-observation") ?? null)]]) ?? null)]]) ?? null)]])));
}

export function operation155(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation156(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["parsedProviderResponse", (sfxValueAt(scope["parsedResponse"], "") ?? null)], ["protocolNormalizationRequest", (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["observation", (Object.fromEntries([["finishReason", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason") : sfxValueAt(scope["parsedResponse"], "choices.0.finish_reason")) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL"])).includes(sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason"))) ? structuredClone("") : sfxJoin(((__source, scope) => __source.map((item, index) => ((scope) => sfxValueAt(scope["part"], "text"))({ ...scope, ["part"]: item, ["partIndex"]: index })))((sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts")), scope), "")) : sfxValueAt(scope["parsedResponse"], "choices.0.message.content")) ?? null)]]) ?? null)], ["providerKind", (sfxValueAt(scope["input"], "payload.providerKind") ?? null)], ["requestType", (structuredClone("normalize-observation") ?? null)]]) ?? null)]]) ?? null)]]));
}

export function operation157(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["parsedResponse"], ""));
}

export function operation158(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("project-model-provider-protocol-input.v1") ?? null)], ["payload", (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["observation", (Object.fromEntries([["finishReason", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason") : sfxValueAt(scope["parsedResponse"], "choices.0.finish_reason")) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL"])).includes(sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason"))) ? structuredClone("") : sfxJoin(((__source, scope) => __source.map((item, index) => ((scope) => sfxValueAt(scope["part"], "text"))({ ...scope, ["part"]: item, ["partIndex"]: index })))((sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts")), scope), "")) : sfxValueAt(scope["parsedResponse"], "choices.0.message.content")) ?? null)]]) ?? null)], ["providerKind", (sfxValueAt(scope["input"], "payload.providerKind") ?? null)], ["requestType", (structuredClone("normalize-observation") ?? null)]]) ?? null)]]));
}

export function operation159(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("project-model-provider-protocol-input.v1"));
}

export function operation160(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["adapterIdentity", (sfxValueAt(scope["input"], "payload.adapterIdentity") ?? null)], ["observation", (Object.fromEntries([["finishReason", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason") : sfxValueAt(scope["parsedResponse"], "choices.0.finish_reason")) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL"])).includes(sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason"))) ? structuredClone("") : sfxJoin(((__source, scope) => __source.map((item, index) => ((scope) => sfxValueAt(scope["part"], "text"))({ ...scope, ["part"]: item, ["partIndex"]: index })))((sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts")), scope), "")) : sfxValueAt(scope["parsedResponse"], "choices.0.message.content")) ?? null)]]) ?? null)], ["providerKind", (sfxValueAt(scope["input"], "payload.providerKind") ?? null)], ["requestType", (structuredClone("normalize-observation") ?? null)]]));
}

export function operation161(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.adapterIdentity"));
}

export function operation162(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["finishReason", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason") : sfxValueAt(scope["parsedResponse"], "choices.0.finish_reason")) ?? null)], ["text", ((sfxTruthy(sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini"))) ? (sfxTruthy((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL"])).includes(sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason"))) ? structuredClone("") : sfxJoin(((__source, scope) => __source.map((item, index) => ((scope) => sfxValueAt(scope["part"], "text"))({ ...scope, ["part"]: item, ["partIndex"]: index })))((sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts")), scope), "")) : sfxValueAt(scope["parsedResponse"], "choices.0.message.content")) ?? null)]]));
}

export function operation163(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["parsedResponse"], "choices.0.finish_reason"));
}

export function operation164(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason"));
}

export function operation165(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini")));
}

export function operation166(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.providerKind"));
}

export function operation167(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation168(input, context) {
  return invokeDeclaredOperation(descriptors[168], input, context);
}

export function operation169(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["parsedResponse"], "choices.0.message.content"));
}

export function operation170(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxJoin(((__source, scope) => __source.map((item, index) => ((scope) => sfxValueAt(scope["part"], "text"))({ ...scope, ["part"]: item, ["partIndex"]: index })))((sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts")), scope), ""));
}

export function operation171(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => __source.map((item, index) => ((scope) => sfxValueAt(scope["part"], "text"))({ ...scope, ["part"]: item, ["partIndex"]: index })))((sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts")), scope));
}

export function operation172(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["parsedResponse"], "candidates.0.content.parts"));
}

export function operation173(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["part"], "text"));
}

export function operation174(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(""));
}

export function operation175(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ((structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL"])).includes(sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason")));
}

export function operation176(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(["MAX_TOKENS","SAFETY","RECITATION","BLOCKLIST","PROHIBITED_CONTENT","SPII","MALFORMED_FUNCTION_CALL"]));
}

export function operation177(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["parsedResponse"], "candidates.0.finishReason"));
}

export function operation178(input, context) {
  return invokeDeclaredOperation(descriptors[178], input, context);
}

export function operation179(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "payload.providerKind"), structuredClone("gemini")));
}

export function operation180(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.providerKind"));
}

export function operation181(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("gemini"));
}

export function operation182(input, context) {
  return invokeDeclaredOperation(descriptors[182], input, context);
}

export function operation183(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "payload.providerKind"));
}

export function operation184(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("normalize-observation"));
}

const implementationByIndex = Object.freeze([operation0, operation1, operation2, operation3, operation4, operation5, operation6, operation7, operation8, operation9, operation10, operation11, operation12, operation13, operation14, operation15, operation16, operation17, operation18, operation19, operation20, operation21, operation22, operation23, operation24, operation25, operation26, operation27, operation28, operation29, operation30, operation31, operation32, operation33, operation34, operation35, operation36, operation37, operation38, operation39, operation40, operation41, operation42, operation43, operation44, operation45, operation46, operation47, operation48, operation49, operation50, operation51, operation52, operation53, operation54, operation55, operation56, operation57, operation58, operation59, operation60, operation61, operation62, operation63, operation64, operation65, operation66, operation67, operation68, operation69, operation70, operation71, operation72, operation73, operation74, operation75, operation76, operation77, operation78, operation79, operation80, operation81, operation82, operation83, operation84, operation85, operation86, operation87, operation88, operation89, operation90, operation91, operation92, operation93, operation94, operation95, operation96, operation97, operation98, operation99, operation100, operation101, operation102, operation103, operation104, operation105, operation106, operation107, operation108, operation109, operation110, operation111, operation112, operation113, operation114, operation115, operation116, operation117, operation118, operation119, operation120, operation121, operation122, operation123, operation124, operation125, operation126, operation127, operation128, operation129, operation130, operation131, operation132, operation133, operation134, operation135, operation136, operation137, operation138, operation139, operation140, operation141, operation142, operation143, operation144, operation145, operation146, operation147, operation148, operation149, operation150, operation151, operation152, operation153, operation154, operation155, operation156, operation157, operation158, operation159, operation160, operation161, operation162, operation163, operation164, operation165, operation166, operation167, operation168, operation169, operation170, operation171, operation172, operation173, operation174, operation175, operation176, operation177, operation178, operation179, operation180, operation181, operation182, operation183, operation184]);
export const operationFunctions = Object.freeze(Object.fromEntries(
  descriptors.map((descriptor, index) => [descriptor.operationId, implementationByIndex[index]])
));
const bindingDescriptors = Object.freeze([]);

const bindingImplementationByIndex = Object.freeze([]);
export const bindingProjectorByAuthorityId = Object.freeze(Object.fromEntries(
  bindingDescriptors.map((descriptor, index) => [descriptor.bindingAuthorityId, bindingImplementationByIndex[index]])
));

