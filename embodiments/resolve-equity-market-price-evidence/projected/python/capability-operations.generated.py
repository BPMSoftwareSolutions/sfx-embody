# GENERATED CAPABILITY OPERATIONS. Do not hand-edit.
# canonicalGraphDigest: sha256:6d8e145c32ebc8629dab66e0be7fe88e135968b4bdcd888ee3e266d712b41dbf
# realizedGraphDigest: sha256:c118fa66c8ef25d59a7d24c565d3d97614236ec481e9d99fe5b237603c3a5959
from __future__ import annotations

import base64
import hashlib
import json
import pathlib

def sfx_refuse(code):
    raise RuntimeError(code)

def sfx_is_primitive(value):
    return value is None or isinstance(value, (str, bool, int, float))

def sfx_is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)

def sfx_strict_equal(left, right):
    if isinstance(left, bool) or isinstance(right, bool):
        return isinstance(left, bool) and isinstance(right, bool) and left == right
    if sfx_is_number(left) and sfx_is_number(right):
        return left == right
    if type(left) is not type(right):
        return False
    return left == right

def sfx_truthy(value):
    if value is None:
        return False
    if isinstance(value, bool):
        return value
    if sfx_is_number(value):
        return value != 0
    if isinstance(value, str):
        return value != ""
    if isinstance(value, list):
        return len(value) > 0
    if isinstance(value, dict):
        return len(value) > 0
    return True

def sfx_value_at(source, dotted_path):
    if dotted_path == "":
        return source if source is not None else None
    current = source
    for segment in [part for part in dotted_path.split(".") if part]:
        if isinstance(current, dict):
            current = current.get(segment)
        elif isinstance(current, list) and segment.isdigit():
            index = int(segment)
            current = current[index] if index < len(current) else None
        elif isinstance(current, str) and segment.isdigit():
            index = int(segment)
            current = current[index] if index < len(current) else None
        else:
            current = None
        if current is None:
            return None
    return current

def sfx_number_text(value):
    if isinstance(value, float):
        if value == 0:
            return "0"
        return repr(value)
    return str(value)

def sfx_coerce_text(value):
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if sfx_is_number(value):
        return sfx_number_text(value)
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return ",".join(sfx_coerce_text(member) for member in value)
    if isinstance(value, dict):
        return "[object Object]"
    sfx_refuse("OPERAND_NOT_PRIMITIVE")

def sfx_equals(left, right):
    if not sfx_is_primitive(left) or not sfx_is_primitive(right):
        sfx_refuse("OPERAND_NOT_PRIMITIVE")
    return sfx_strict_equal(left, right)

def sfx_greater_than(left, right):
    ordered = (sfx_is_number(left) and sfx_is_number(right)) or (isinstance(left, str) and isinstance(right, str))
    if not ordered:
        sfx_refuse("OPERAND_NOT_ORDERED")
    return left > right

def sfx_length(value):
    if not isinstance(value, str) and not isinstance(value, list):
        sfx_refuse("OPERAND_NOT_MEASURABLE")
    return len(value)

def sfx_merge(*values):
    for value in values:
        if value is not None and not isinstance(value, dict):
            sfx_refuse("OPERAND_NOT_OBJECT")
    result = {}
    for value in values:
        if value is not None:
            result.update(value)
    return result

def sfx_join(value, separator):
    rendered = []
    for member in value:
        if member is None:
            rendered.append("")
        elif isinstance(member, bool):
            rendered.append("true" if member else "false")
        elif sfx_is_number(member):
            rendered.append(sfx_number_text(member))
        elif isinstance(member, str):
            rendered.append(member)
        else:
            sfx_refuse("OPERAND_NOT_PRIMITIVE")
    return str(separator).join(rendered)

def sfx_format(template, values):
    rendered = []
    for key, evaluated in values.items():
        if evaluated is None:
            rendered.append((key, "null"))
        elif isinstance(evaluated, bool):
            rendered.append((key, "true" if evaluated else "false"))
        elif sfx_is_number(evaluated):
            rendered.append((key, sfx_number_text(evaluated)))
        elif isinstance(evaluated, str):
            rendered.append((key, evaluated))
        else:
            sfx_refuse("OPERAND_NOT_PRIMITIVE")
    text = template
    for key, replacement in rendered:
        text = text.replace("{" + key + "}", replacement)
    return text

def sfx_unique(value):
    for member in value:
        if not sfx_is_primitive(member):
            sfx_refuse("OPERAND_NOT_PRIMITIVE")
    seen = []
    for member in value:
        if not any(sfx_strict_equal(prior, member) for prior in seen):
            seen.append(member)
    return seen

def sfx_object_values(value):
    if not isinstance(value, dict):
        sfx_refuse("OPERAND_NOT_OBJECT")
    return [value[key] for key in sorted(value)]

def sfx_parse_json(value):
    if value is None or not isinstance(value, str):
        sfx_refuse("OPERAND_NOT_PRIMITIVE")
    try:
        return json.loads(value)
    except ValueError:
        sfx_refuse("VALUE_NOT_PARSABLE")

def sfx_try_parse_json(value):
    if value is None:
        return {"disposition": "NOT_PARSED", "value": None}
    try:
        return {"disposition": "PARSED", "value": json.loads(value)}
    except ValueError:
        return {"disposition": "NOT_PARSED", "value": None}

def sfx_includes(container, target):
    if isinstance(container, str):
        return target in container
    if isinstance(container, list):
        return any(sfx_strict_equal(member, target) for member in container)
    sfx_refuse("OPERAND_NOT_ADMITTED")

def sfx_intersects(left, right):
    if not isinstance(left, list) or not isinstance(right, list):
        sfx_refuse("OPERAND_NOT_ARRAY")
    return any(any(sfx_strict_equal(member, target) for target in right) for member in left)

def sfx_collection(operation, source, scope, variable, evaluate):
    if not isinstance(source, list):
        sfx_refuse("OPERAND_NOT_ARRAY")
    result = []
    for index, item in enumerate(source):
        next_scope = {**scope, variable: item, variable + "Index": index}
        if operation in ("map", "flat-map"):
            mapped = evaluate(next_scope)
            if operation == "flat-map" and isinstance(mapped, list):
                result.extend(mapped)
            else:
                result.append(mapped)
            continue
        matched = sfx_truthy(evaluate(next_scope))
        if operation == "filter" and matched:
            result.append(item)
        elif operation == "find" and matched:
            return item
        elif operation == "some" and matched:
            return True
        elif operation == "every" and not matched:
            return False
    if operation == "some":
        return False
    if operation == "every":
        return True
    if operation == "find":
        return None
    return result

def sfx_let(scope, bindings, evaluate):
    next_scope = dict(scope)
    for name, binding in bindings:
        next_scope[name] = binding(next_scope)
    return evaluate(next_scope)

def sfx_trim(value):
    return sfx_coerce_text(value).strip()

def sfx_lower_case(value):
    return sfx_coerce_text(value).lower()

def sfx_escape_html(value):
    return (sfx_coerce_text(value)
            .replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace('"', "&quot;").replace("'", "&#39;"))

def sfx_sha256(value):
    return hashlib.sha256(sfx_coerce_text(value).encode("utf-8")).hexdigest()

def sfx_base64_decode_utf8(value):
    return base64.b64decode(sfx_coerce_text(value)).decode("utf-8")

def sfx_json_stringify(value):
    return json.dumps(value, separators=(",", ":"), ensure_ascii=False)

def sfx_canonicalize(value):
    if isinstance(value, list):
        return [sfx_canonicalize(member) for member in value]
    if isinstance(value, dict):
        return {key: sfx_canonicalize(value[key]) for key in sorted(value)}
    return value

def sfx_directed_graph_closure(value):
    graph_input_valid = isinstance(value, dict)
    graph = value if graph_input_valid else {}
    declared_node_ids = graph.get("nodeIds") if isinstance(graph.get("nodeIds"), list) else []
    declared_edges = graph.get("edges") if isinstance(graph.get("edges"), list) else []
    declared_root_node_ids = graph.get("rootNodeIds") if isinstance(graph.get("rootNodeIds"), list) else []
    declared_terminal_node_ids = graph.get("terminalNodeIds") if isinstance(graph.get("terminalNodeIds"), list) else []
    findings = []
    finding_keys = set()

    def add_finding(code, subject_id):
        key = code + "\u0000" + subject_id
        if key in finding_keys:
            return
        finding_keys.add(key)
        findings.append({"code": code, "subjectId": subject_id})

    if not graph_input_valid:
        add_finding("GRAPH_INPUT_INVALID", "input")
    if not isinstance(graph.get("nodeIds"), list):
        add_finding("GRAPH_NODE_IDS_REQUIRED", "nodeIds")
    if not isinstance(graph.get("edges"), list):
        add_finding("GRAPH_EDGES_REQUIRED", "edges")
    if not isinstance(graph.get("rootNodeIds"), list):
        add_finding("GRAPH_ROOT_NODE_IDS_REQUIRED", "rootNodeIds")
    if not isinstance(graph.get("terminalNodeIds"), list):
        add_finding("GRAPH_TERMINAL_NODE_IDS_REQUIRED", "terminalNodeIds")

    node_counts = {}
    for node_id in declared_node_ids:
        if not isinstance(node_id, str) or len(node_id) == 0:
            add_finding("GRAPH_NODE_ID_INVALID", str(node_id))
            continue
        node_counts[node_id] = node_counts.get(node_id, 0) + 1
    for node_id, count in node_counts.items():
        if count > 1:
            add_finding("GRAPH_NODE_ID_DUPLICATE", node_id)
    node_ids = sorted(node_counts)
    node_set = set(node_ids)

    edge_counts = {}
    edges = []
    for edge in declared_edges:
        if (not isinstance(edge, dict)
                or not isinstance(edge.get("edgeId"), str) or len(edge.get("edgeId", "")) == 0
                or not isinstance(edge.get("from"), str) or len(edge.get("from", "")) == 0
                or not isinstance(edge.get("to"), str) or len(edge.get("to", "")) == 0):
            add_finding("GRAPH_EDGE_INVALID", str(edge.get("edgeId", "") if isinstance(edge, dict) else ""))
            continue
        edge_id = edge["edgeId"]
        edge_counts[edge_id] = edge_counts.get(edge_id, 0) + 1
        edges.append({"edgeId": edge_id, "from": edge["from"], "to": edge["to"]})
    for edge_id, count in edge_counts.items():
        if count > 1:
            add_finding("GRAPH_EDGE_ID_DUPLICATE", edge_id)
    edges.sort(key=lambda edge: (edge["edgeId"], edge["from"], edge["to"]))
    for edge in edges:
        if edge["from"] not in node_set:
            add_finding("GRAPH_EDGE_SOURCE_UNRESOLVED", edge["edgeId"])
        if edge["to"] not in node_set:
            add_finding("GRAPH_EDGE_TARGET_UNRESOLVED", edge["edgeId"])

    def normalize_declared_nodes(values, invalid_code, invalid_identity_code):
        for node_id in values:
            if not isinstance(node_id, str) or len(node_id) == 0:
                add_finding(invalid_identity_code, str(node_id))
        normalized = []
        seen = set()
        for node_id in values:
            if isinstance(node_id, str) and len(node_id) > 0 and node_id not in seen:
                seen.add(node_id)
                normalized.append(node_id)
        normalized.sort()
        for node_id in normalized:
            if node_id not in node_set:
                add_finding(invalid_code, node_id)
        return [node_id for node_id in normalized if node_id in node_set]

    root_node_ids = normalize_declared_nodes(declared_root_node_ids, "GRAPH_ROOT_NODE_UNRESOLVED", "GRAPH_ROOT_NODE_ID_INVALID")
    terminal_node_ids = normalize_declared_nodes(declared_terminal_node_ids, "GRAPH_TERMINAL_NODE_UNRESOLVED", "GRAPH_TERMINAL_NODE_ID_INVALID")
    terminal_node_set = set(terminal_node_ids)

    findings.sort(key=lambda finding: (finding["code"], finding["subjectId"]))
    if findings:
        return {
            "disposition": "REJECTED",
            "nodeIds": node_ids,
            "edgeIds": sorted({edge["edgeId"] for edge in edges}),
            "rootNodeIds": root_node_ids,
            "terminalNodeIds": terminal_node_ids,
            "reachableNodeIds": [],
            "unreachableNodeIds": node_ids,
            "traversalNodeIds": [],
            "traversalEdgeIds": [],
            "reachablePairs": [],
            "terminalReachability": [],
            "cycleComponents": [],
            "cycleEdgeIds": [],
            "fixedPointPasses": 0,
            "findings": findings,
        }

    adjacency = {node_id: [] for node_id in node_ids}
    for edge in edges:
        adjacency[edge["from"]].append(edge)
    for outgoing in adjacency.values():
        outgoing.sort(key=lambda edge: (edge["to"], edge["edgeId"]))

    def closure_from(start_node_id):
        reached = {start_node_id}
        frontier = [start_node_id]
        passes = 0
        while frontier:
            next_frontier = set()
            for node_id in sorted(frontier):
                for edge in adjacency[node_id]:
                    if edge["to"] not in reached:
                        reached.add(edge["to"])
                        next_frontier.add(edge["to"])
            frontier = list(next_frontier)
            passes += 1
        return sorted(reached), passes

    closures = {node_id: closure_from(node_id) for node_id in node_ids}
    reachable_pairs = [{"from": start, "to": reached} for start in node_ids for reached in closures[start][0]]
    reachable_node_set = set()
    for root_node_id in root_node_ids:
        reachable_node_set.update(closures[root_node_id][0])
    reachable_node_ids = sorted(reachable_node_set)
    unreachable_node_ids = [node_id for node_id in node_ids if node_id not in reachable_node_set]

    traversal_node_ids = []
    traversal_edge_ids = []
    traversed_nodes = set()
    traversed_edges = set()
    frontier = list(root_node_ids)
    while frontier:
        node_id = frontier.pop(0)
        if node_id in traversed_nodes:
            continue
        traversed_nodes.add(node_id)
        traversal_node_ids.append(node_id)
        for edge in adjacency[node_id]:
            if edge["edgeId"] not in traversed_edges:
                traversed_edges.add(edge["edgeId"])
                traversal_edge_ids.append(edge["edgeId"])
            if edge["to"] not in traversed_nodes:
                frontier.append(edge["to"])
        frontier.sort()

    terminal_reachability = [
        {"nodeId": node_id, "terminalNodeIds": [reached for reached in closures[node_id][0] if reached in terminal_node_set]}
        for node_id in node_ids
    ]
    assigned_cycle_nodes = set()
    cycle_components = []
    for node_id in node_ids:
        if node_id in assigned_cycle_nodes:
            continue
        mutually_reachable = [
            candidate for candidate in node_ids
            if candidate in closures[node_id][0] and node_id in closures[candidate][0]
        ]
        has_self_loop = any(edge["from"] == node_id and edge["to"] == node_id for edge in edges)
        if len(mutually_reachable) > 1 or has_self_loop:
            assigned_cycle_nodes.update(mutually_reachable)
            cycle_components.append(mutually_reachable)
    cycle_components.sort(key=lambda component: "\u0000".join(component))
    cycle_component_by_node = {}
    for index, component in enumerate(cycle_components):
        for node_id in component:
            cycle_component_by_node[node_id] = index
    cycle_edge_ids = sorted(
        edge["edgeId"] for edge in edges
        if edge["from"] in cycle_component_by_node
        and cycle_component_by_node.get(edge["from"]) == cycle_component_by_node.get(edge["to"])
    )
    return {
        "disposition": "CLOSED",
        "nodeIds": node_ids,
        "edgeIds": [edge["edgeId"] for edge in edges],
        "rootNodeIds": root_node_ids,
        "terminalNodeIds": terminal_node_ids,
        "reachableNodeIds": reachable_node_ids,
        "unreachableNodeIds": unreachable_node_ids,
        "traversalNodeIds": traversal_node_ids,
        "traversalEdgeIds": traversal_edge_ids,
        "reachablePairs": reachable_pairs,
        "terminalReachability": terminal_reachability,
        "cycleComponents": cycle_components,
        "cycleEdgeIds": cycle_edge_ids,
        "fixedPointPasses": max([0, *[closures[node_id][1] for node_id in node_ids]]),
        "findings": [],
    }

def op_0(scope):
    return ({"credentialReference": ("RAPID_API_KEY"), "effectLineage": ([]), "effectScope": ("ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"), "endpointAuthorityDigest": ("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"), "invocationIdentity": ("equity-market-price-evidence.v1"), "requestingCapabilityId": ("resolve-equity-market-price-evidence")})

def op_2(scope):
    return ({"allowedResponseHeaders": ([("content-type"), ("retry-after")]), "cancellationScopeReference": ("equity-market-price-evidence.v1"), "credentialInjectionRuleId": (sfx_value_at(scope.get("input"), "credentialInjectionRuleId")), "endpointAuthorityDigest": ("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"), "exchangeKind": ("live-provider-input"), "invocationIdentity": ("equity-market-price-evidence.v1"), "lineageId": ("equity-market-price-evidence.v1"), "maxResponseBytes": (262144), "method": ("GET"), "opaqueCredentialBinding": ({"bindingId": (sfx_value_at(scope.get("input"), "opaqueBindingId")), "credentialInjectionRuleId": (sfx_value_at(scope.get("input"), "credentialInjectionRuleId"))}), "redirectPolicy": ("manual"), "requestBodyText": (""), "requestUrl": (sfx_format("https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}", {"region": (sfx_value_at(scope.get("root"), "payload.region")), "symbol": (sfx_value_at(scope.get("root"), "payload.symbol"))})), "safeHeaders": ({"X-RapidAPI-Host": ("yahoo-finance166.p.rapidapi.com")}), "timeoutMilliseconds": (12000)})

def op_4(scope):
    return (sfx_let(scope, [("completed", lambda scope: sfx_equals(sfx_value_at(scope.get("input"), "disposition"), "completed")), ("bodyText", lambda scope: (sfx_base64_decode_utf8(sfx_value_at(scope.get("input"), "responseBodyBytes")) if sfx_truthy(sfx_value_at(scope.get("completed"), "")) else "")), ("parsed", lambda scope: sfx_try_parse_json(sfx_value_at(scope.get("bodyText"), ""))), ("native", lambda scope: sfx_value_at(scope.get("parsed"), "value")), ("summaryQuote", lambda scope: sfx_value_at(scope.get("native"), "quoteSummary.result.0.price")), ("responseQuote", lambda scope: sfx_value_at(scope.get("native"), "quoteResponse.result.0")), ("symbol", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "symbol") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "symbol"))), ("currency", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "currency") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "currency"))), ("observedPrice", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "regularMarketPrice.raw") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "regularMarketPrice"))), ("observedMarketTime", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "regularMarketTime") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "regularMarketTime"))), ("marketState", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "marketState") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "marketState"))), ("exchange", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "exchange") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "exchange"))), ("sourceAttribution", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "quoteSourceName") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "quoteSourceName"))), ("requiredValues", lambda scope: [(sfx_value_at(scope.get("symbol"), "")), (sfx_value_at(scope.get("currency"), "")), (sfx_value_at(scope.get("observedPrice"), "")), (sfx_value_at(scope.get("observedMarketTime"), "")), (sfx_value_at(scope.get("marketState"), "")), (sfx_value_at(scope.get("exchange"), "")), (sfx_value_at(scope.get("sourceAttribution"), ""))]), ("missing", lambda scope: sfx_collection("filter", sfx_value_at(scope.get("requiredValues"), ""), scope, "v", lambda scope: sfx_equals(sfx_value_at(scope.get("v"), ""), None))), ("missingCount", lambda scope: sfx_length(sfx_value_at(scope.get("missing"), ""))), ("conforming", lambda scope: sfx_equals(sfx_value_at(scope.get("missingCount"), ""), 0)), ("nativeShape", lambda scope: ("quoteSummary.result.0.price" if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else "quoteResponse.result.0")), ("bindingId", lambda scope: "rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED"), ("providerId", lambda scope: "rapidapi/davethebeast/yahoo-finance166")], lambda scope: (({"contractId": ("equity-market-price-evidence.v1"), "disposition": ("EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"), "payload": ({"symbol": (sfx_value_at(scope.get("symbol"), "")), "region": (sfx_value_at(scope.get("root"), "payload.region")), "currency": (sfx_value_at(scope.get("currency"), "")), "observedPrice": (sfx_value_at(scope.get("observedPrice"), "")), "observedMarketTime": (sfx_value_at(scope.get("observedMarketTime"), "")), "marketState": (sfx_value_at(scope.get("marketState"), "")), "exchange": (sfx_value_at(scope.get("exchange"), "")), "sourceAttribution": (sfx_value_at(scope.get("sourceAttribution"), ""))}), "providerTestimony": ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), "")), "nativeShape": (sfx_value_at(scope.get("nativeShape"), ""))})} if sfx_truthy(sfx_value_at(scope.get("conforming"), "")) else {"contractId": ("equity-market-price-evidence.v1"), "disposition": ("NATIVE_MARKET_PRICE_TESTIMONY_REJECTED"), "reasonCode": ("REQUIRED_NATIVE_FIELDS_ABSENT"), "absentFieldCount": (sfx_value_at(scope.get("missingCount"), "")), "providerTestimony": ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), "")), "nativeShape": (sfx_value_at(scope.get("nativeShape"), ""))})}) if sfx_truthy(sfx_value_at(scope.get("completed"), "")) else {"contractId": ("equity-market-price-evidence.v1"), "disposition": ("EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE"), "reasonCode": ("PROVIDER_EXCHANGE_NOT_COMPLETED"), "providerTestimony": ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), ""))})})))

def op_5(scope):
    return ({"credentialReference": ("RAPID_API_KEY"), "effectLineage": ([]), "effectScope": ("ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"), "endpointAuthorityDigest": ("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"), "invocationIdentity": ("equity-market-price-evidence.v1"), "requestingCapabilityId": ("resolve-equity-market-price-evidence")})

def op_6(scope):
    return ("RAPID_API_KEY")

def op_7(scope):
    return ([])

def op_8(scope):
    return ("ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY")

def op_9(scope):
    return ("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b")

def op_10(scope):
    return ("equity-market-price-evidence.v1")

def op_11(scope):
    return ("resolve-equity-market-price-evidence")

def op_12(scope):
    return ({"allowedResponseHeaders": ([("content-type"), ("retry-after")]), "cancellationScopeReference": ("equity-market-price-evidence.v1"), "credentialInjectionRuleId": (sfx_value_at(scope.get("input"), "credentialInjectionRuleId")), "endpointAuthorityDigest": ("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"), "exchangeKind": ("live-provider-input"), "invocationIdentity": ("equity-market-price-evidence.v1"), "lineageId": ("equity-market-price-evidence.v1"), "maxResponseBytes": (262144), "method": ("GET"), "opaqueCredentialBinding": ({"bindingId": (sfx_value_at(scope.get("input"), "opaqueBindingId")), "credentialInjectionRuleId": (sfx_value_at(scope.get("input"), "credentialInjectionRuleId"))}), "redirectPolicy": ("manual"), "requestBodyText": (""), "requestUrl": (sfx_format("https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}", {"region": (sfx_value_at(scope.get("root"), "payload.region")), "symbol": (sfx_value_at(scope.get("root"), "payload.symbol"))})), "safeHeaders": ({"X-RapidAPI-Host": ("yahoo-finance166.p.rapidapi.com")}), "timeoutMilliseconds": (12000)})

def op_13(scope):
    return ([("content-type"), ("retry-after")])

def op_14(scope):
    return ("content-type")

def op_15(scope):
    return ("retry-after")

def op_16(scope):
    return ("equity-market-price-evidence.v1")

def op_17(scope):
    return (sfx_value_at(scope.get("input"), "credentialInjectionRuleId"))

def op_18(scope):
    return ("sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b")

def op_19(scope):
    return ("live-provider-input")

def op_20(scope):
    return ("equity-market-price-evidence.v1")

def op_21(scope):
    return ("equity-market-price-evidence.v1")

def op_22(scope):
    return (262144)

def op_23(scope):
    return ("GET")

def op_24(scope):
    return ({"bindingId": (sfx_value_at(scope.get("input"), "opaqueBindingId")), "credentialInjectionRuleId": (sfx_value_at(scope.get("input"), "credentialInjectionRuleId"))})

def op_25(scope):
    return (sfx_value_at(scope.get("input"), "opaqueBindingId"))

def op_26(scope):
    return (sfx_value_at(scope.get("input"), "credentialInjectionRuleId"))

def op_27(scope):
    return ("manual")

def op_28(scope):
    return ("")

def op_29(scope):
    return (sfx_format("https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}", {"region": (sfx_value_at(scope.get("root"), "payload.region")), "symbol": (sfx_value_at(scope.get("root"), "payload.symbol"))}))

def op_30(scope):
    return (sfx_value_at(scope.get("root"), "payload.region"))

def op_31(scope):
    return (sfx_value_at(scope.get("root"), "payload.symbol"))

def op_32(scope):
    return ({"X-RapidAPI-Host": ("yahoo-finance166.p.rapidapi.com")})

def op_33(scope):
    return ("yahoo-finance166.p.rapidapi.com")

def op_34(scope):
    return (12000)

def op_35(scope):
    return (sfx_let(scope, [("completed", lambda scope: sfx_equals(sfx_value_at(scope.get("input"), "disposition"), "completed")), ("bodyText", lambda scope: (sfx_base64_decode_utf8(sfx_value_at(scope.get("input"), "responseBodyBytes")) if sfx_truthy(sfx_value_at(scope.get("completed"), "")) else "")), ("parsed", lambda scope: sfx_try_parse_json(sfx_value_at(scope.get("bodyText"), ""))), ("native", lambda scope: sfx_value_at(scope.get("parsed"), "value")), ("summaryQuote", lambda scope: sfx_value_at(scope.get("native"), "quoteSummary.result.0.price")), ("responseQuote", lambda scope: sfx_value_at(scope.get("native"), "quoteResponse.result.0")), ("symbol", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "symbol") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "symbol"))), ("currency", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "currency") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "currency"))), ("observedPrice", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "regularMarketPrice.raw") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "regularMarketPrice"))), ("observedMarketTime", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "regularMarketTime") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "regularMarketTime"))), ("marketState", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "marketState") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "marketState"))), ("exchange", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "exchange") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "exchange"))), ("sourceAttribution", lambda scope: (sfx_value_at(scope.get("summaryQuote"), "quoteSourceName") if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else sfx_value_at(scope.get("responseQuote"), "quoteSourceName"))), ("requiredValues", lambda scope: [(sfx_value_at(scope.get("symbol"), "")), (sfx_value_at(scope.get("currency"), "")), (sfx_value_at(scope.get("observedPrice"), "")), (sfx_value_at(scope.get("observedMarketTime"), "")), (sfx_value_at(scope.get("marketState"), "")), (sfx_value_at(scope.get("exchange"), "")), (sfx_value_at(scope.get("sourceAttribution"), ""))]), ("missing", lambda scope: sfx_collection("filter", sfx_value_at(scope.get("requiredValues"), ""), scope, "v", lambda scope: sfx_equals(sfx_value_at(scope.get("v"), ""), None))), ("missingCount", lambda scope: sfx_length(sfx_value_at(scope.get("missing"), ""))), ("conforming", lambda scope: sfx_equals(sfx_value_at(scope.get("missingCount"), ""), 0)), ("nativeShape", lambda scope: ("quoteSummary.result.0.price" if sfx_truthy(sfx_value_at(scope.get("summaryQuote"), "")) else "quoteResponse.result.0")), ("bindingId", lambda scope: "rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED"), ("providerId", lambda scope: "rapidapi/davethebeast/yahoo-finance166")], lambda scope: (({"contractId": ("equity-market-price-evidence.v1"), "disposition": ("EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"), "payload": ({"symbol": (sfx_value_at(scope.get("symbol"), "")), "region": (sfx_value_at(scope.get("root"), "payload.region")), "currency": (sfx_value_at(scope.get("currency"), "")), "observedPrice": (sfx_value_at(scope.get("observedPrice"), "")), "observedMarketTime": (sfx_value_at(scope.get("observedMarketTime"), "")), "marketState": (sfx_value_at(scope.get("marketState"), "")), "exchange": (sfx_value_at(scope.get("exchange"), "")), "sourceAttribution": (sfx_value_at(scope.get("sourceAttribution"), ""))}), "providerTestimony": ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), "")), "nativeShape": (sfx_value_at(scope.get("nativeShape"), ""))})} if sfx_truthy(sfx_value_at(scope.get("conforming"), "")) else {"contractId": ("equity-market-price-evidence.v1"), "disposition": ("NATIVE_MARKET_PRICE_TESTIMONY_REJECTED"), "reasonCode": ("REQUIRED_NATIVE_FIELDS_ABSENT"), "absentFieldCount": (sfx_value_at(scope.get("missingCount"), "")), "providerTestimony": ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), "")), "nativeShape": (sfx_value_at(scope.get("nativeShape"), ""))})}) if sfx_truthy(sfx_value_at(scope.get("completed"), "")) else {"contractId": ("equity-market-price-evidence.v1"), "disposition": ("EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE"), "reasonCode": ("PROVIDER_EXCHANGE_NOT_COMPLETED"), "providerTestimony": ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), ""))})})))

def op_36(scope):
    return ("rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED")

def op_37(scope):
    return ("")

def op_38(scope):
    return (sfx_base64_decode_utf8(sfx_value_at(scope.get("input"), "responseBodyBytes")))

def op_39(scope):
    return (sfx_value_at(scope.get("input"), "responseBodyBytes"))

def op_40(scope):
    return (sfx_value_at(scope.get("completed"), ""))

def op_42(scope):
    return (sfx_equals(sfx_value_at(scope.get("input"), "disposition"), "completed"))

def op_43(scope):
    return (sfx_value_at(scope.get("input"), "disposition"))

def op_44(scope):
    return ("completed")

def op_45(scope):
    return (sfx_equals(sfx_value_at(scope.get("missingCount"), ""), 0))

def op_46(scope):
    return (sfx_value_at(scope.get("missingCount"), ""))

def op_47(scope):
    return (0)

def op_48(scope):
    return (sfx_value_at(scope.get("responseQuote"), "currency"))

def op_49(scope):
    return (sfx_value_at(scope.get("summaryQuote"), "currency"))

def op_50(scope):
    return (sfx_value_at(scope.get("summaryQuote"), ""))

def op_52(scope):
    return (sfx_value_at(scope.get("responseQuote"), "exchange"))

def op_53(scope):
    return (sfx_value_at(scope.get("summaryQuote"), "exchange"))

def op_54(scope):
    return (sfx_value_at(scope.get("summaryQuote"), ""))

def op_56(scope):
    return (sfx_value_at(scope.get("responseQuote"), "marketState"))

def op_57(scope):
    return (sfx_value_at(scope.get("summaryQuote"), "marketState"))

def op_58(scope):
    return (sfx_value_at(scope.get("summaryQuote"), ""))

def op_60(scope):
    return (sfx_collection("filter", sfx_value_at(scope.get("requiredValues"), ""), scope, "v", lambda scope: sfx_equals(sfx_value_at(scope.get("v"), ""), None)))

def op_60_source(scope):
    return (sfx_value_at(scope.get("requiredValues"), ""))

def op_61(scope):
    return (sfx_value_at(scope.get("requiredValues"), ""))

def op_62(scope):
    return (sfx_equals(sfx_value_at(scope.get("v"), ""), None))

def op_63(scope):
    return (sfx_value_at(scope.get("v"), ""))

def op_64(scope):
    return (None)

def op_65(scope):
    return (sfx_length(sfx_value_at(scope.get("missing"), "")))

def op_66(scope):
    return (sfx_value_at(scope.get("missing"), ""))

def op_67(scope):
    return (sfx_value_at(scope.get("parsed"), "value"))

def op_68(scope):
    return ("quoteResponse.result.0")

def op_69(scope):
    return ("quoteSummary.result.0.price")

def op_70(scope):
    return (sfx_value_at(scope.get("summaryQuote"), ""))

def op_72(scope):
    return (sfx_value_at(scope.get("responseQuote"), "regularMarketTime"))

def op_73(scope):
    return (sfx_value_at(scope.get("summaryQuote"), "regularMarketTime"))

def op_74(scope):
    return (sfx_value_at(scope.get("summaryQuote"), ""))

def op_76(scope):
    return (sfx_value_at(scope.get("responseQuote"), "regularMarketPrice"))

def op_77(scope):
    return (sfx_value_at(scope.get("summaryQuote"), "regularMarketPrice.raw"))

def op_78(scope):
    return (sfx_value_at(scope.get("summaryQuote"), ""))

def op_80(scope):
    return (sfx_try_parse_json(sfx_value_at(scope.get("bodyText"), "")))

def op_81(scope):
    return (sfx_value_at(scope.get("bodyText"), ""))

def op_82(scope):
    return ("rapidapi/davethebeast/yahoo-finance166")

def op_83(scope):
    return ([(sfx_value_at(scope.get("symbol"), "")), (sfx_value_at(scope.get("currency"), "")), (sfx_value_at(scope.get("observedPrice"), "")), (sfx_value_at(scope.get("observedMarketTime"), "")), (sfx_value_at(scope.get("marketState"), "")), (sfx_value_at(scope.get("exchange"), "")), (sfx_value_at(scope.get("sourceAttribution"), ""))])

def op_84(scope):
    return (sfx_value_at(scope.get("symbol"), ""))

def op_85(scope):
    return (sfx_value_at(scope.get("currency"), ""))

def op_86(scope):
    return (sfx_value_at(scope.get("observedPrice"), ""))

def op_87(scope):
    return (sfx_value_at(scope.get("observedMarketTime"), ""))

def op_88(scope):
    return (sfx_value_at(scope.get("marketState"), ""))

def op_89(scope):
    return (sfx_value_at(scope.get("exchange"), ""))

def op_90(scope):
    return (sfx_value_at(scope.get("sourceAttribution"), ""))

def op_91(scope):
    return (sfx_value_at(scope.get("native"), "quoteResponse.result.0"))

def op_92(scope):
    return (sfx_value_at(scope.get("responseQuote"), "quoteSourceName"))

def op_93(scope):
    return (sfx_value_at(scope.get("summaryQuote"), "quoteSourceName"))

def op_94(scope):
    return (sfx_value_at(scope.get("summaryQuote"), ""))

def op_96(scope):
    return (sfx_value_at(scope.get("native"), "quoteSummary.result.0.price"))

def op_97(scope):
    return (sfx_value_at(scope.get("responseQuote"), "symbol"))

def op_98(scope):
    return (sfx_value_at(scope.get("summaryQuote"), "symbol"))

def op_99(scope):
    return (sfx_value_at(scope.get("summaryQuote"), ""))

def op_101(scope):
    return ({"contractId": ("equity-market-price-evidence.v1"), "disposition": ("EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE"), "reasonCode": ("PROVIDER_EXCHANGE_NOT_COMPLETED"), "providerTestimony": ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), ""))})})

def op_102(scope):
    return ("equity-market-price-evidence.v1")

def op_103(scope):
    return ("EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE")

def op_104(scope):
    return ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), ""))})

def op_105(scope):
    return (sfx_value_at(scope.get("bindingId"), ""))

def op_106(scope):
    return (sfx_value_at(scope.get("providerId"), ""))

def op_107(scope):
    return ("PROVIDER_EXCHANGE_NOT_COMPLETED")

def op_108(scope):
    return ({"contractId": ("equity-market-price-evidence.v1"), "disposition": ("NATIVE_MARKET_PRICE_TESTIMONY_REJECTED"), "reasonCode": ("REQUIRED_NATIVE_FIELDS_ABSENT"), "absentFieldCount": (sfx_value_at(scope.get("missingCount"), "")), "providerTestimony": ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), "")), "nativeShape": (sfx_value_at(scope.get("nativeShape"), ""))})})

def op_109(scope):
    return (sfx_value_at(scope.get("missingCount"), ""))

def op_110(scope):
    return ("equity-market-price-evidence.v1")

def op_111(scope):
    return ("NATIVE_MARKET_PRICE_TESTIMONY_REJECTED")

def op_112(scope):
    return ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), "")), "nativeShape": (sfx_value_at(scope.get("nativeShape"), ""))})

def op_113(scope):
    return (sfx_value_at(scope.get("bindingId"), ""))

def op_114(scope):
    return (sfx_value_at(scope.get("nativeShape"), ""))

def op_115(scope):
    return (sfx_value_at(scope.get("providerId"), ""))

def op_116(scope):
    return ("REQUIRED_NATIVE_FIELDS_ABSENT")

def op_117(scope):
    return ({"contractId": ("equity-market-price-evidence.v1"), "disposition": ("EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"), "payload": ({"symbol": (sfx_value_at(scope.get("symbol"), "")), "region": (sfx_value_at(scope.get("root"), "payload.region")), "currency": (sfx_value_at(scope.get("currency"), "")), "observedPrice": (sfx_value_at(scope.get("observedPrice"), "")), "observedMarketTime": (sfx_value_at(scope.get("observedMarketTime"), "")), "marketState": (sfx_value_at(scope.get("marketState"), "")), "exchange": (sfx_value_at(scope.get("exchange"), "")), "sourceAttribution": (sfx_value_at(scope.get("sourceAttribution"), ""))}), "providerTestimony": ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), "")), "nativeShape": (sfx_value_at(scope.get("nativeShape"), ""))})})

def op_118(scope):
    return ("equity-market-price-evidence.v1")

def op_119(scope):
    return ("EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED")

def op_120(scope):
    return ({"symbol": (sfx_value_at(scope.get("symbol"), "")), "region": (sfx_value_at(scope.get("root"), "payload.region")), "currency": (sfx_value_at(scope.get("currency"), "")), "observedPrice": (sfx_value_at(scope.get("observedPrice"), "")), "observedMarketTime": (sfx_value_at(scope.get("observedMarketTime"), "")), "marketState": (sfx_value_at(scope.get("marketState"), "")), "exchange": (sfx_value_at(scope.get("exchange"), "")), "sourceAttribution": (sfx_value_at(scope.get("sourceAttribution"), ""))})

def op_121(scope):
    return (sfx_value_at(scope.get("currency"), ""))

def op_122(scope):
    return (sfx_value_at(scope.get("exchange"), ""))

def op_123(scope):
    return (sfx_value_at(scope.get("marketState"), ""))

def op_124(scope):
    return (sfx_value_at(scope.get("observedMarketTime"), ""))

def op_125(scope):
    return (sfx_value_at(scope.get("observedPrice"), ""))

def op_126(scope):
    return (sfx_value_at(scope.get("root"), "payload.region"))

def op_127(scope):
    return (sfx_value_at(scope.get("sourceAttribution"), ""))

def op_128(scope):
    return (sfx_value_at(scope.get("symbol"), ""))

def op_129(scope):
    return ({"bindingId": (sfx_value_at(scope.get("bindingId"), "")), "providerId": (sfx_value_at(scope.get("providerId"), "")), "nativeShape": (sfx_value_at(scope.get("nativeShape"), ""))})

def op_130(scope):
    return (sfx_value_at(scope.get("bindingId"), ""))

def op_131(scope):
    return (sfx_value_at(scope.get("nativeShape"), ""))

def op_132(scope):
    return (sfx_value_at(scope.get("providerId"), ""))

def op_133(scope):
    return (sfx_value_at(scope.get("conforming"), ""))

def op_135(scope):
    return (sfx_value_at(scope.get("completed"), ""))

BINDING_FUNCTIONS = {
}

_DESCRIPTORS_PATH = pathlib.Path(__file__).resolve().with_name("execution-operations.json")
DESCRIPTORS = json.loads(_DESCRIPTORS_PATH.read_text(encoding="utf-8"))["operations"]

