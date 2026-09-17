// GENERATED CAPABILITY OPERATIONS. Do not hand-edit.
import crypto from "node:crypto";
import fs from "node:fs";
import { bindValueAt, valueAt } from "../../../../../scenario-driven-architecture/languages/typescript/runtimes/node/native-mechanic-primitives.mjs";

const descriptorDocument = JSON.parse(fs.readFileSync(new URL("./execution-operations.json", import.meta.url), "utf8"));
const descriptors = Array.isArray(descriptorDocument.operations) ? descriptorDocument.operations : [];
export const cellContracts = Object.freeze({"cell:mechanic:cancel-model-invocation.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:cancel-model-invocation.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:classify-internal-model-execution-failure.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:classify-internal-model-execution-failure.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:classify-model-provider-authentication-failure.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:classify-model-provider-authentication-failure.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:classify-model-provider-timeout.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:classify-model-provider-timeout.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:classify-model-provider-unavailability.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:classify-model-provider-unavailability.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:continue-transient-model-attempt.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:continue-transient-model-attempt.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.10":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.11":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.12":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.13":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.14":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.15":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.16":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.17":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.18":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.19":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.2":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.20":{"inputContractId":"semantic-value.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:execute-governed-model-invocation.operation.3":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.4":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.5":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.6":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.7":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.8":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:execute-governed-model-invocation.operation.9":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:exhaust-model-attempt-authority.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:exhaust-model-attempt-authority.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:fail-unavailable-model-credential.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:fail-unavailable-model-credential.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:honor-model-evidence-policy.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:honor-model-evidence-policy.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:obtain-structured-model-response.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:obtain-structured-model-response.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:preserve-canonical-model-request-identity.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:preserve-canonical-model-request-identity.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:prevent-undeclared-model-attempt-or-substitution.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:prevent-undeclared-model-attempt-or-substitution.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:reject-invalid-governed-model-request.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:reject-invalid-governed-model-request.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:reject-malformed-structured-model-response.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:reject-malformed-structured-model-response.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:reject-schema-incompatible-model-response.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:reject-schema-incompatible-model-response.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:reject-stale-model-provider-binding.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:reject-stale-model-provider-binding.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:retain-model-provider-request-rejection.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:retain-model-provider-request-rejection.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:return-model-execution-receipt-on-every-exit.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:return-model-execution-receipt-on-every-exit.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:mechanic:stop-non-transient-model-attempt.operation.1":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:mechanic:stop-non-transient-model-attempt.operation.1:expression":{"inputContractId":"semantic-value.v1","outcomeContractId":"semantic-value.v1"},"cell:scenario:cancel-model-invocation":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:classify-internal-model-execution-failure":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:classify-model-provider-authentication-failure":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:classify-model-provider-timeout":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:classify-model-provider-unavailability":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:continue-transient-model-attempt":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:execute-governed-model-invocation":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:exhaust-model-attempt-authority":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:fail-unavailable-model-credential":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:honor-model-evidence-policy":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:obtain-structured-model-response":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:preserve-canonical-model-request-identity":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:prevent-undeclared-model-attempt-or-substitution":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:reject-invalid-governed-model-request":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:reject-malformed-structured-model-response":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:reject-schema-incompatible-model-response":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:reject-stale-model-provider-binding":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:retain-model-provider-request-rejection":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:return-model-execution-receipt-on-every-exit":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"},"cell:scenario:stop-non-transient-model-attempt":{"inputContractId":"execute-governed-model-invocation-input.v1","outcomeContractId":"governed-model-invocation-evidence.v1"}});

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
  return (sfxValueAt(scope["input"], ""));
}

export function operation1(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation2(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation3(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation4(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation5(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation6(input, context) {
  return invokeDeclaredOperation(descriptors[6], input, context);
}

export function operation7(input, context) {
  return invokeDeclaredOperation(descriptors[7], input, context);
}

export function operation8(input, context) {
  return invokeDeclaredOperation(descriptors[8], input, context);
}

export function operation9(input, context) {
  return invokeDeclaredOperation(descriptors[9], input, context);
}

export function operation10(input, context) {
  return invokeDeclaredOperation(descriptors[10], input, context);
}

export function operation11(input, context) {
  return invokeDeclaredOperation(descriptors[11], input, context);
}

export function operation12(input, context) {
  return invokeDeclaredOperation(descriptors[12], input, context);
}

export function operation13(input, context) {
  return invokeDeclaredOperation(descriptors[13], input, context);
}

export function operation14(input, context) {
  return invokeDeclaredOperation(descriptors[14], input, context);
}

export function operation15(input, context) {
  return invokeDeclaredOperation(descriptors[15], input, context);
}

export function operation16(input, context) {
  return invokeDeclaredOperation(descriptors[16], input, context);
}

export function operation17(input, context) {
  return invokeDeclaredOperation(descriptors[17], input, context);
}

export function operation18(input, context) {
  return invokeDeclaredOperation(descriptors[18], input, context);
}

export function operation19(input, context) {
  return invokeDeclaredOperation(descriptors[19], input, context);
}

export function operation20(input, context) {
  return invokeDeclaredOperation(descriptors[20], input, context);
}

export function operation21(input, context) {
  return invokeDeclaredOperation(descriptors[21], input, context);
}

export function operation22(input, context) {
  return invokeDeclaredOperation(descriptors[22], input, context);
}

export function operation23(input, context) {
  return invokeDeclaredOperation(descriptors[23], input, context);
}

export function operation24(input, context) {
  return invokeDeclaredOperation(descriptors[24], input, context);
}

export function operation25(input, context) {
  return invokeDeclaredOperation(descriptors[25], input, context);
}

export function operation26(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation27(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation28(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation29(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation30(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation31(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation32(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation33(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation34(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation35(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation36(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation37(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation38(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation39(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation40(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation41(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation42(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation43(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation44(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation45(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation46(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation47(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation48(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation49(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation50(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation51(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation52(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation53(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation54(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation55(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation56(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

export function operation57(input, context) {
  const scope = { input, root: context && context.rootInput !== undefined ? context.rootInput : input };
  return (sfxValueAt(scope["input"], ""));
}

const implementationByIndex = Object.freeze([operation0, operation1, operation2, operation3, operation4, operation5, operation6, operation7, operation8, operation9, operation10, operation11, operation12, operation13, operation14, operation15, operation16, operation17, operation18, operation19, operation20, operation21, operation22, operation23, operation24, operation25, operation26, operation27, operation28, operation29, operation30, operation31, operation32, operation33, operation34, operation35, operation36, operation37, operation38, operation39, operation40, operation41, operation42, operation43, operation44, operation45, operation46, operation47, operation48, operation49, operation50, operation51, operation52, operation53, operation54, operation55, operation56, operation57]);
export const operationFunctions = Object.freeze(Object.fromEntries(
  descriptors.map((descriptor, index) => [descriptor.operationId, implementationByIndex[index]])
));
const bindingDescriptors = Object.freeze([]);

const bindingImplementationByIndex = Object.freeze([]);
export const bindingProjectorByAuthorityId = Object.freeze(Object.fromEntries(
  bindingDescriptors.map((descriptor, index) => [descriptor.bindingAuthorityId, bindingImplementationByIndex[index]])
));

