// GENERATED CAPABILITY OPERATIONS. Do not hand-edit.
import crypto from "node:crypto";
import fs from "node:fs";
import { bindValueAt, valueAt } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/native-mechanic-primitives.mjs";

const descriptorDocument = JSON.parse(fs.readFileSync(new URL("./execution-operations.json", import.meta.url), "utf8"));
const descriptors = Array.isArray(descriptorDocument.operations) ? descriptorDocument.operations : [];
export const cellContracts = Object.freeze({"cell:mechanic:resolve-equity-market-price-evidence.operation.1":{"inputContractId":"live-equity-price-request.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.1:expression.fields.credentialReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.1:expression.fields.effectLineage":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.1:expression.fields.effectScope":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.1:expression.fields.endpointAuthorityDigest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.1:expression.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.1:expression.fields.requestingCapabilityId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.allowedResponseHeaders":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.allowedResponseHeaders.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.allowedResponseHeaders.items.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.cancellationScopeReference":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.credentialInjectionRuleId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.endpointAuthorityDigest":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.exchangeKind":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.invocationIdentity":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.lineageId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.maxResponseBytes":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.method":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.opaqueCredentialBinding":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.opaqueCredentialBinding.fields.bindingId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.opaqueCredentialBinding.fields.credentialInjectionRuleId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.redirectPolicy":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.requestBodyText":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.requestUrl":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.requestUrl.values.region":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.requestUrl.values.symbol":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.safeHeaders":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.safeHeaders.fields.X-RapidAPI-Host":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.3:expression.fields.timeoutMilliseconds":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.4":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5":{"inputContractId":"semantic-value.v1","outcomeContractId":"equity-market-price-evidence.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.bindingId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.bodyText":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.bodyText:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.bodyText.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.bodyText.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.bodyText.then.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.bodyText.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.completed":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.completed.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.completed.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.conforming":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.conforming.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.conforming.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.currency":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.currency:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.currency.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.currency.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.currency.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.exchange":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.exchange:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.exchange.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.exchange.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.exchange.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.marketState":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.marketState:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.marketState.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.marketState.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.marketState.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.missing":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.missing.from":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.missing.where":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.missing.where.left":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.missing.where.right":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.missingCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.missingCount.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.native":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.nativeShape":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.nativeShape:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.nativeShape.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.nativeShape.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.nativeShape.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedMarketTime":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedMarketTime:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedMarketTime.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedMarketTime.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedMarketTime.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedPrice":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedPrice:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedPrice.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedPrice.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.observedPrice.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.parsed":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.parsed.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.providerId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.requiredValues":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.requiredValues.items.0":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.requiredValues.items.1":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.requiredValues.items.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.requiredValues.items.3":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.requiredValues.items.4":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.requiredValues.items.5":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.requiredValues.items.6":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.responseQuote":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.sourceAttribution":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.sourceAttribution:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.sourceAttribution.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.sourceAttribution.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.sourceAttribution.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.summaryQuote":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.symbol":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.symbol:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.symbol.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.symbol.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.bindings.symbol.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.else.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.else.fields.disposition":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.else.fields.providerTestimony":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.else.fields.providerTestimony.fields.bindingId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.else.fields.providerTestimony.fields.providerId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.else.fields.reasonCode":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then:selection":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.else":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.else.fields.absentFieldCount":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.else.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.else.fields.disposition":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.else.fields.providerTestimony":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.else.fields.providerTestimony.fields.bindingId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.else.fields.providerTestimony.fields.nativeShape":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.else.fields.providerTestimony.fields.providerId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.else.fields.reasonCode":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.contractId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.disposition":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.payload":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.payload.fields.currency":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.payload.fields.exchange":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.payload.fields.marketState":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.payload.fields.observedMarketTime":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.payload.fields.observedPrice":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.payload.fields.region":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.payload.fields.sourceAttribution":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.payload.fields.symbol":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.providerTestimony":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.providerTestimony.fields.bindingId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.providerTestimony.fields.nativeShape":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.then.fields.providerTestimony.fields.providerId":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.then.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:resolve-equity-market-price-evidence.operation.5:expression.value.when":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:physical:resolve-equity-market-price-evidence.operation.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:physical:resolve-equity-market-price-evidence.operation.4":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:provider:resolve-equity-market-price-evidence.operation.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:provider:resolve-equity-market-price-evidence.operation.4":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:scenario:resolve-equity-market-price-evidence":{"inputContractId":"live-equity-price-request.v1","outcomeContractId":"equity-market-price-evidence.v1"}});

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
  return (Object.fromEntries([["credentialReference", (structuredClone("RAPID_API_KEY") ?? null)], ["effectLineage", ([] ?? null)], ["effectScope", (structuredClone("ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b") ?? null)], ["invocationIdentity", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["requestingCapabilityId", (structuredClone("resolve-equity-market-price-evidence") ?? null)]]));
}

export function operation1(input, context) {
  return invokeDeclaredOperation(descriptors[1], input, context);
}

export function operation2(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["allowedResponseHeaders", ([(structuredClone("content-type") ?? null), (structuredClone("retry-after") ?? null)] ?? null)], ["cancellationScopeReference", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialInjectionRuleId") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b") ?? null)], ["exchangeKind", (structuredClone("live-provider-input") ?? null)], ["invocationIdentity", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["lineageId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["maxResponseBytes", (structuredClone(262144) ?? null)], ["method", (structuredClone("GET") ?? null)], ["opaqueCredentialBinding", (Object.fromEntries([["bindingId", (sfxValueAt(scope["input"], "opaqueBindingId") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialInjectionRuleId") ?? null)]]) ?? null)], ["redirectPolicy", (structuredClone("manual") ?? null)], ["requestBodyText", (structuredClone("") ?? null)], ["requestUrl", (sfxFormat("https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}", Object.fromEntries([["region", (sfxValueAt(scope["root"], "payload.region"))], ["symbol", (sfxValueAt(scope["root"], "payload.symbol"))]])) ?? null)], ["safeHeaders", (Object.fromEntries([["X-RapidAPI-Host", (structuredClone("yahoo-finance166.p.rapidapi.com") ?? null)]]) ?? null)], ["timeoutMilliseconds", (structuredClone(12000) ?? null)]]));
}

export function operation3(input, context) {
  return invokeDeclaredOperation(descriptors[3], input, context);
}

export function operation4(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["completed"]: (sfxEquals(sfxValueAt(scope["input"], "disposition"), structuredClone("completed"))) }; scope = { ...scope, ["bodyText"]: ((sfxTruthy(sfxValueAt(scope["completed"], "")) ? sfxBase64DecodeUtf8(sfxValueAt(scope["input"], "responseBodyBytes")) : structuredClone(""))) }; scope = { ...scope, ["parsed"]: (sfxTryParseJson(sfxValueAt(scope["bodyText"], ""))) }; scope = { ...scope, ["native"]: (sfxValueAt(scope["parsed"], "value")) }; scope = { ...scope, ["summaryQuote"]: (sfxValueAt(scope["native"], "quoteSummary.result.0.price")) }; scope = { ...scope, ["responseQuote"]: (sfxValueAt(scope["native"], "quoteResponse.result.0")) }; scope = { ...scope, ["symbol"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "symbol") : sfxValueAt(scope["responseQuote"], "symbol"))) }; scope = { ...scope, ["currency"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "currency") : sfxValueAt(scope["responseQuote"], "currency"))) }; scope = { ...scope, ["observedPrice"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "regularMarketPrice.raw") : sfxValueAt(scope["responseQuote"], "regularMarketPrice"))) }; scope = { ...scope, ["observedMarketTime"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "regularMarketTime") : sfxValueAt(scope["responseQuote"], "regularMarketTime"))) }; scope = { ...scope, ["marketState"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "marketState") : sfxValueAt(scope["responseQuote"], "marketState"))) }; scope = { ...scope, ["exchange"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "exchange") : sfxValueAt(scope["responseQuote"], "exchange"))) }; scope = { ...scope, ["sourceAttribution"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "quoteSourceName") : sfxValueAt(scope["responseQuote"], "quoteSourceName"))) }; scope = { ...scope, ["requiredValues"]: ([(sfxValueAt(scope["symbol"], "") ?? null), (sfxValueAt(scope["currency"], "") ?? null), (sfxValueAt(scope["observedPrice"], "") ?? null), (sfxValueAt(scope["observedMarketTime"], "") ?? null), (sfxValueAt(scope["marketState"], "") ?? null), (sfxValueAt(scope["exchange"], "") ?? null), (sfxValueAt(scope["sourceAttribution"], "") ?? null)]) }; scope = { ...scope, ["missing"]: (((__source, scope) => __source.filter((item, index) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["v"], ""), structuredClone(null)))({ ...scope, ["v"]: item, ["vIndex"]: index }))))(sfxValueAt(scope["requiredValues"], ""), scope)) }; scope = { ...scope, ["missingCount"]: (sfxLength(sfxValueAt(scope["missing"], ""))) }; scope = { ...scope, ["conforming"]: (sfxEquals(sfxValueAt(scope["missingCount"], ""), structuredClone(0))) }; scope = { ...scope, ["nativeShape"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? structuredClone("quoteSummary.result.0.price") : structuredClone("quoteResponse.result.0"))) }; scope = { ...scope, ["bindingId"]: (structuredClone("rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED")) }; scope = { ...scope, ["providerId"]: (structuredClone("rapidapi/davethebeast/yahoo-finance166")) }; return (sfxTruthy(sfxValueAt(scope["completed"], "")) ? (sfxTruthy(sfxValueAt(scope["conforming"], "")) ? Object.fromEntries([["contractId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["disposition", (structuredClone("EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED") ?? null)], ["payload", (Object.fromEntries([["symbol", (sfxValueAt(scope["symbol"], "") ?? null)], ["region", (sfxValueAt(scope["root"], "payload.region") ?? null)], ["currency", (sfxValueAt(scope["currency"], "") ?? null)], ["observedPrice", (sfxValueAt(scope["observedPrice"], "") ?? null)], ["observedMarketTime", (sfxValueAt(scope["observedMarketTime"], "") ?? null)], ["marketState", (sfxValueAt(scope["marketState"], "") ?? null)], ["exchange", (sfxValueAt(scope["exchange"], "") ?? null)], ["sourceAttribution", (sfxValueAt(scope["sourceAttribution"], "") ?? null)]]) ?? null)], ["providerTestimony", (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)], ["nativeShape", (sfxValueAt(scope["nativeShape"], "") ?? null)]]) ?? null)]]) : Object.fromEntries([["contractId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["disposition", (structuredClone("NATIVE_MARKET_PRICE_TESTIMONY_REJECTED") ?? null)], ["reasonCode", (structuredClone("REQUIRED_NATIVE_FIELDS_ABSENT") ?? null)], ["absentFieldCount", (sfxValueAt(scope["missingCount"], "") ?? null)], ["providerTestimony", (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)], ["nativeShape", (sfxValueAt(scope["nativeShape"], "") ?? null)]]) ?? null)]])) : Object.fromEntries([["contractId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["disposition", (structuredClone("EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE") ?? null)], ["reasonCode", (structuredClone("PROVIDER_EXCHANGE_NOT_COMPLETED") ?? null)], ["providerTestimony", (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)]]) ?? null)]])); })(scope));
}

export function operation5(input, context) {
  return structuredClone(input);
}

export function operation6(input, context) {
  return structuredClone(input);
}

export function operation7(input, context) {
  return invokeDeclaredOperation(descriptors[7], input, context);
}

export function operation8(input, context) {
  return invokeDeclaredOperation(descriptors[8], input, context);
}

export function operation9(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["credentialReference", (structuredClone("RAPID_API_KEY") ?? null)], ["effectLineage", ([] ?? null)], ["effectScope", (structuredClone("ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b") ?? null)], ["invocationIdentity", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["requestingCapabilityId", (structuredClone("resolve-equity-market-price-evidence") ?? null)]]));
}

export function operation10(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("RAPID_API_KEY"));
}

export function operation11(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([]);
}

export function operation12(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"));
}

export function operation13(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"));
}

export function operation14(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("equity-market-price-evidence.v1"));
}

export function operation15(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("resolve-equity-market-price-evidence"));
}

export function operation16(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["allowedResponseHeaders", ([(structuredClone("content-type") ?? null), (structuredClone("retry-after") ?? null)] ?? null)], ["cancellationScopeReference", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialInjectionRuleId") ?? null)], ["endpointAuthorityDigest", (structuredClone("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b") ?? null)], ["exchangeKind", (structuredClone("live-provider-input") ?? null)], ["invocationIdentity", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["lineageId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["maxResponseBytes", (structuredClone(262144) ?? null)], ["method", (structuredClone("GET") ?? null)], ["opaqueCredentialBinding", (Object.fromEntries([["bindingId", (sfxValueAt(scope["input"], "opaqueBindingId") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialInjectionRuleId") ?? null)]]) ?? null)], ["redirectPolicy", (structuredClone("manual") ?? null)], ["requestBodyText", (structuredClone("") ?? null)], ["requestUrl", (sfxFormat("https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}", Object.fromEntries([["region", (sfxValueAt(scope["root"], "payload.region"))], ["symbol", (sfxValueAt(scope["root"], "payload.symbol"))]])) ?? null)], ["safeHeaders", (Object.fromEntries([["X-RapidAPI-Host", (structuredClone("yahoo-finance166.p.rapidapi.com") ?? null)]]) ?? null)], ["timeoutMilliseconds", (structuredClone(12000) ?? null)]]));
}

export function operation17(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(structuredClone("content-type") ?? null), (structuredClone("retry-after") ?? null)]);
}

export function operation18(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("content-type"));
}

export function operation19(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("retry-after"));
}

export function operation20(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("equity-market-price-evidence.v1"));
}

export function operation21(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "credentialInjectionRuleId"));
}

export function operation22(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"));
}

export function operation23(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("live-provider-input"));
}

export function operation24(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("equity-market-price-evidence.v1"));
}

export function operation25(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("equity-market-price-evidence.v1"));
}

export function operation26(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(262144));
}

export function operation27(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("GET"));
}

export function operation28(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["bindingId", (sfxValueAt(scope["input"], "opaqueBindingId") ?? null)], ["credentialInjectionRuleId", (sfxValueAt(scope["input"], "credentialInjectionRuleId") ?? null)]]));
}

export function operation29(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "opaqueBindingId"));
}

export function operation30(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "credentialInjectionRuleId"));
}

export function operation31(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("manual"));
}

export function operation32(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(""));
}

export function operation33(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxFormat("https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}", Object.fromEntries([["region", (sfxValueAt(scope["root"], "payload.region"))], ["symbol", (sfxValueAt(scope["root"], "payload.symbol"))]])));
}

export function operation34(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["root"], "payload.region"));
}

export function operation35(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["root"], "payload.symbol"));
}

export function operation36(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["X-RapidAPI-Host", (structuredClone("yahoo-finance166.p.rapidapi.com") ?? null)]]));
}

export function operation37(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("yahoo-finance166.p.rapidapi.com"));
}

export function operation38(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(12000));
}

export function operation39(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((scope) => { scope = { ...scope, ["completed"]: (sfxEquals(sfxValueAt(scope["input"], "disposition"), structuredClone("completed"))) }; scope = { ...scope, ["bodyText"]: ((sfxTruthy(sfxValueAt(scope["completed"], "")) ? sfxBase64DecodeUtf8(sfxValueAt(scope["input"], "responseBodyBytes")) : structuredClone(""))) }; scope = { ...scope, ["parsed"]: (sfxTryParseJson(sfxValueAt(scope["bodyText"], ""))) }; scope = { ...scope, ["native"]: (sfxValueAt(scope["parsed"], "value")) }; scope = { ...scope, ["summaryQuote"]: (sfxValueAt(scope["native"], "quoteSummary.result.0.price")) }; scope = { ...scope, ["responseQuote"]: (sfxValueAt(scope["native"], "quoteResponse.result.0")) }; scope = { ...scope, ["symbol"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "symbol") : sfxValueAt(scope["responseQuote"], "symbol"))) }; scope = { ...scope, ["currency"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "currency") : sfxValueAt(scope["responseQuote"], "currency"))) }; scope = { ...scope, ["observedPrice"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "regularMarketPrice.raw") : sfxValueAt(scope["responseQuote"], "regularMarketPrice"))) }; scope = { ...scope, ["observedMarketTime"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "regularMarketTime") : sfxValueAt(scope["responseQuote"], "regularMarketTime"))) }; scope = { ...scope, ["marketState"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "marketState") : sfxValueAt(scope["responseQuote"], "marketState"))) }; scope = { ...scope, ["exchange"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "exchange") : sfxValueAt(scope["responseQuote"], "exchange"))) }; scope = { ...scope, ["sourceAttribution"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? sfxValueAt(scope["summaryQuote"], "quoteSourceName") : sfxValueAt(scope["responseQuote"], "quoteSourceName"))) }; scope = { ...scope, ["requiredValues"]: ([(sfxValueAt(scope["symbol"], "") ?? null), (sfxValueAt(scope["currency"], "") ?? null), (sfxValueAt(scope["observedPrice"], "") ?? null), (sfxValueAt(scope["observedMarketTime"], "") ?? null), (sfxValueAt(scope["marketState"], "") ?? null), (sfxValueAt(scope["exchange"], "") ?? null), (sfxValueAt(scope["sourceAttribution"], "") ?? null)]) }; scope = { ...scope, ["missing"]: (((__source, scope) => __source.filter((item, index) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["v"], ""), structuredClone(null)))({ ...scope, ["v"]: item, ["vIndex"]: index }))))(sfxValueAt(scope["requiredValues"], ""), scope)) }; scope = { ...scope, ["missingCount"]: (sfxLength(sfxValueAt(scope["missing"], ""))) }; scope = { ...scope, ["conforming"]: (sfxEquals(sfxValueAt(scope["missingCount"], ""), structuredClone(0))) }; scope = { ...scope, ["nativeShape"]: ((sfxTruthy(sfxValueAt(scope["summaryQuote"], "")) ? structuredClone("quoteSummary.result.0.price") : structuredClone("quoteResponse.result.0"))) }; scope = { ...scope, ["bindingId"]: (structuredClone("rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED")) }; scope = { ...scope, ["providerId"]: (structuredClone("rapidapi/davethebeast/yahoo-finance166")) }; return (sfxTruthy(sfxValueAt(scope["completed"], "")) ? (sfxTruthy(sfxValueAt(scope["conforming"], "")) ? Object.fromEntries([["contractId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["disposition", (structuredClone("EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED") ?? null)], ["payload", (Object.fromEntries([["symbol", (sfxValueAt(scope["symbol"], "") ?? null)], ["region", (sfxValueAt(scope["root"], "payload.region") ?? null)], ["currency", (sfxValueAt(scope["currency"], "") ?? null)], ["observedPrice", (sfxValueAt(scope["observedPrice"], "") ?? null)], ["observedMarketTime", (sfxValueAt(scope["observedMarketTime"], "") ?? null)], ["marketState", (sfxValueAt(scope["marketState"], "") ?? null)], ["exchange", (sfxValueAt(scope["exchange"], "") ?? null)], ["sourceAttribution", (sfxValueAt(scope["sourceAttribution"], "") ?? null)]]) ?? null)], ["providerTestimony", (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)], ["nativeShape", (sfxValueAt(scope["nativeShape"], "") ?? null)]]) ?? null)]]) : Object.fromEntries([["contractId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["disposition", (structuredClone("NATIVE_MARKET_PRICE_TESTIMONY_REJECTED") ?? null)], ["reasonCode", (structuredClone("REQUIRED_NATIVE_FIELDS_ABSENT") ?? null)], ["absentFieldCount", (sfxValueAt(scope["missingCount"], "") ?? null)], ["providerTestimony", (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)], ["nativeShape", (sfxValueAt(scope["nativeShape"], "") ?? null)]]) ?? null)]])) : Object.fromEntries([["contractId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["disposition", (structuredClone("EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE") ?? null)], ["reasonCode", (structuredClone("PROVIDER_EXCHANGE_NOT_COMPLETED") ?? null)], ["providerTestimony", (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)]]) ?? null)]])); })(scope));
}

export function operation40(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED"));
}

export function operation41(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(""));
}

export function operation42(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxBase64DecodeUtf8(sfxValueAt(scope["input"], "responseBodyBytes")));
}

export function operation43(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "responseBodyBytes"));
}

export function operation44(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["completed"], ""));
}

export function operation45(input, context) {
  return invokeDeclaredOperation(descriptors[45], input, context);
}

export function operation46(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["input"], "disposition"), structuredClone("completed")));
}

export function operation47(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], "disposition"));
}

export function operation48(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("completed"));
}

export function operation49(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["missingCount"], ""), structuredClone(0)));
}

export function operation50(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["missingCount"], ""));
}

export function operation51(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(0));
}

export function operation52(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["responseQuote"], "currency"));
}

export function operation53(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], "currency"));
}

export function operation54(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], ""));
}

export function operation55(input, context) {
  return invokeDeclaredOperation(descriptors[55], input, context);
}

export function operation56(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["responseQuote"], "exchange"));
}

export function operation57(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], "exchange"));
}

export function operation58(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], ""));
}

export function operation59(input, context) {
  return invokeDeclaredOperation(descriptors[59], input, context);
}

export function operation60(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["responseQuote"], "marketState"));
}

export function operation61(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], "marketState"));
}

export function operation62(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], ""));
}

export function operation63(input, context) {
  return invokeDeclaredOperation(descriptors[63], input, context);
}

export function operation64(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (((__source, scope) => __source.filter((item, index) => sfxTruthy(((scope) => sfxEquals(sfxValueAt(scope["v"], ""), structuredClone(null)))({ ...scope, ["v"]: item, ["vIndex"]: index }))))(sfxValueAt(scope["requiredValues"], ""), scope));
}

export function operation65(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["requiredValues"], ""));
}

export function operation66(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxEquals(sfxValueAt(scope["v"], ""), structuredClone(null)));
}

export function operation67(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["v"], ""));
}

export function operation68(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone(null));
}

export function operation69(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxLength(sfxValueAt(scope["missing"], "")));
}

export function operation70(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["missing"], ""));
}

export function operation71(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["parsed"], "value"));
}

export function operation72(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("quoteResponse.result.0"));
}

export function operation73(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("quoteSummary.result.0.price"));
}

export function operation74(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], ""));
}

export function operation75(input, context) {
  return invokeDeclaredOperation(descriptors[75], input, context);
}

export function operation76(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["responseQuote"], "regularMarketTime"));
}

export function operation77(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], "regularMarketTime"));
}

export function operation78(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], ""));
}

export function operation79(input, context) {
  return invokeDeclaredOperation(descriptors[79], input, context);
}

export function operation80(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["responseQuote"], "regularMarketPrice"));
}

export function operation81(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], "regularMarketPrice.raw"));
}

export function operation82(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], ""));
}

export function operation83(input, context) {
  return invokeDeclaredOperation(descriptors[83], input, context);
}

export function operation84(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxTryParseJson(sfxValueAt(scope["bodyText"], "")));
}

export function operation85(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["bodyText"], ""));
}

export function operation86(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("rapidapi/davethebeast/yahoo-finance166"));
}

export function operation87(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return ([(sfxValueAt(scope["symbol"], "") ?? null), (sfxValueAt(scope["currency"], "") ?? null), (sfxValueAt(scope["observedPrice"], "") ?? null), (sfxValueAt(scope["observedMarketTime"], "") ?? null), (sfxValueAt(scope["marketState"], "") ?? null), (sfxValueAt(scope["exchange"], "") ?? null), (sfxValueAt(scope["sourceAttribution"], "") ?? null)]);
}

export function operation88(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["symbol"], ""));
}

export function operation89(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["currency"], ""));
}

export function operation90(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["observedPrice"], ""));
}

export function operation91(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["observedMarketTime"], ""));
}

export function operation92(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["marketState"], ""));
}

export function operation93(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["exchange"], ""));
}

export function operation94(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["sourceAttribution"], ""));
}

export function operation95(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["native"], "quoteResponse.result.0"));
}

export function operation96(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["responseQuote"], "quoteSourceName"));
}

export function operation97(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], "quoteSourceName"));
}

export function operation98(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], ""));
}

export function operation99(input, context) {
  return invokeDeclaredOperation(descriptors[99], input, context);
}

export function operation100(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["native"], "quoteSummary.result.0.price"));
}

export function operation101(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["responseQuote"], "symbol"));
}

export function operation102(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], "symbol"));
}

export function operation103(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["summaryQuote"], ""));
}

export function operation104(input, context) {
  return invokeDeclaredOperation(descriptors[104], input, context);
}

export function operation105(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["disposition", (structuredClone("EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE") ?? null)], ["reasonCode", (structuredClone("PROVIDER_EXCHANGE_NOT_COMPLETED") ?? null)], ["providerTestimony", (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)]]) ?? null)]]));
}

export function operation106(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("equity-market-price-evidence.v1"));
}

export function operation107(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE"));
}

export function operation108(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)]]));
}

export function operation109(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["bindingId"], ""));
}

export function operation110(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["providerId"], ""));
}

export function operation111(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("PROVIDER_EXCHANGE_NOT_COMPLETED"));
}

export function operation112(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["disposition", (structuredClone("NATIVE_MARKET_PRICE_TESTIMONY_REJECTED") ?? null)], ["reasonCode", (structuredClone("REQUIRED_NATIVE_FIELDS_ABSENT") ?? null)], ["absentFieldCount", (sfxValueAt(scope["missingCount"], "") ?? null)], ["providerTestimony", (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)], ["nativeShape", (sfxValueAt(scope["nativeShape"], "") ?? null)]]) ?? null)]]));
}

export function operation113(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["missingCount"], ""));
}

export function operation114(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("equity-market-price-evidence.v1"));
}

export function operation115(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("NATIVE_MARKET_PRICE_TESTIMONY_REJECTED"));
}

export function operation116(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)], ["nativeShape", (sfxValueAt(scope["nativeShape"], "") ?? null)]]));
}

export function operation117(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["bindingId"], ""));
}

export function operation118(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["nativeShape"], ""));
}

export function operation119(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["providerId"], ""));
}

export function operation120(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("REQUIRED_NATIVE_FIELDS_ABSENT"));
}

export function operation121(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["contractId", (structuredClone("equity-market-price-evidence.v1") ?? null)], ["disposition", (structuredClone("EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED") ?? null)], ["payload", (Object.fromEntries([["symbol", (sfxValueAt(scope["symbol"], "") ?? null)], ["region", (sfxValueAt(scope["root"], "payload.region") ?? null)], ["currency", (sfxValueAt(scope["currency"], "") ?? null)], ["observedPrice", (sfxValueAt(scope["observedPrice"], "") ?? null)], ["observedMarketTime", (sfxValueAt(scope["observedMarketTime"], "") ?? null)], ["marketState", (sfxValueAt(scope["marketState"], "") ?? null)], ["exchange", (sfxValueAt(scope["exchange"], "") ?? null)], ["sourceAttribution", (sfxValueAt(scope["sourceAttribution"], "") ?? null)]]) ?? null)], ["providerTestimony", (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)], ["nativeShape", (sfxValueAt(scope["nativeShape"], "") ?? null)]]) ?? null)]]));
}

export function operation122(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("equity-market-price-evidence.v1"));
}

export function operation123(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (structuredClone("EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"));
}

export function operation124(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["symbol", (sfxValueAt(scope["symbol"], "") ?? null)], ["region", (sfxValueAt(scope["root"], "payload.region") ?? null)], ["currency", (sfxValueAt(scope["currency"], "") ?? null)], ["observedPrice", (sfxValueAt(scope["observedPrice"], "") ?? null)], ["observedMarketTime", (sfxValueAt(scope["observedMarketTime"], "") ?? null)], ["marketState", (sfxValueAt(scope["marketState"], "") ?? null)], ["exchange", (sfxValueAt(scope["exchange"], "") ?? null)], ["sourceAttribution", (sfxValueAt(scope["sourceAttribution"], "") ?? null)]]));
}

export function operation125(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["currency"], ""));
}

export function operation126(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["exchange"], ""));
}

export function operation127(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["marketState"], ""));
}

export function operation128(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["observedMarketTime"], ""));
}

export function operation129(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["observedPrice"], ""));
}

export function operation130(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["root"], "payload.region"));
}

export function operation131(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["sourceAttribution"], ""));
}

export function operation132(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["symbol"], ""));
}

export function operation133(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (Object.fromEntries([["bindingId", (sfxValueAt(scope["bindingId"], "") ?? null)], ["providerId", (sfxValueAt(scope["providerId"], "") ?? null)], ["nativeShape", (sfxValueAt(scope["nativeShape"], "") ?? null)]]));
}

export function operation134(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["bindingId"], ""));
}

export function operation135(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["nativeShape"], ""));
}

export function operation136(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["providerId"], ""));
}

export function operation137(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["conforming"], ""));
}

export function operation138(input, context) {
  return invokeDeclaredOperation(descriptors[138], input, context);
}

export function operation139(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["completed"], ""));
}

export function operation140(input, context) {
  return invokeDeclaredOperation(descriptors[140], input, context);
}

const implementationByIndex = Object.freeze([operation0, operation1, operation2, operation3, operation4, operation5, operation6, operation7, operation8, operation9, operation10, operation11, operation12, operation13, operation14, operation15, operation16, operation17, operation18, operation19, operation20, operation21, operation22, operation23, operation24, operation25, operation26, operation27, operation28, operation29, operation30, operation31, operation32, operation33, operation34, operation35, operation36, operation37, operation38, operation39, operation40, operation41, operation42, operation43, operation44, operation45, operation46, operation47, operation48, operation49, operation50, operation51, operation52, operation53, operation54, operation55, operation56, operation57, operation58, operation59, operation60, operation61, operation62, operation63, operation64, operation65, operation66, operation67, operation68, operation69, operation70, operation71, operation72, operation73, operation74, operation75, operation76, operation77, operation78, operation79, operation80, operation81, operation82, operation83, operation84, operation85, operation86, operation87, operation88, operation89, operation90, operation91, operation92, operation93, operation94, operation95, operation96, operation97, operation98, operation99, operation100, operation101, operation102, operation103, operation104, operation105, operation106, operation107, operation108, operation109, operation110, operation111, operation112, operation113, operation114, operation115, operation116, operation117, operation118, operation119, operation120, operation121, operation122, operation123, operation124, operation125, operation126, operation127, operation128, operation129, operation130, operation131, operation132, operation133, operation134, operation135, operation136, operation137, operation138, operation139, operation140]);
export const operationFunctions = Object.freeze(Object.fromEntries(
  descriptors.map((descriptor, index) => [descriptor.operationId, implementationByIndex[index]])
));
const bindingDescriptors = Object.freeze([]);

const bindingImplementationByIndex = Object.freeze([]);
export const bindingProjectorByAuthorityId = Object.freeze(Object.fromEntries(
  bindingDescriptors.map((descriptor, index) => [descriptor.bindingAuthorityId, bindingImplementationByIndex[index]])
));

