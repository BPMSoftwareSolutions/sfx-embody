# GENERATED CAPABILITY EXECUTION BODY. Do not hand-edit.
# canonicalGraphDigest: sha256:6d8e145c32ebc8629dab66e0be7fe88e135968b4bdcd888ee3e266d712b41dbf
# realizedGraphDigest: sha256:c118fa66c8ef25d59a7d24c565d3d97614236ec481e9d99fe5b237603c3a5959
from __future__ import annotations

import copy
import hashlib
import importlib
import importlib.util
import json
import pathlib
import re
import sys

from scenario_kernel.platform.consumer import _plan_contract_admission
from scenario_kernel.platform.governed_effect_ports import create_governed_effect_context
from scenario_kernel.platform.execution_pattern_resolvers import execute_decomposition as pattern_decomposition
from scenario_kernel.platform.execution_pattern_resolvers import execute_recurrence as pattern_recurrence
from scenario_kernel.platform.execution_pattern_resolvers import execute_selection as pattern_selection
from scenario_kernel.platform.execution_pattern_resolvers import execute_sequence as pattern_sequence

_BASE = pathlib.Path(__file__).resolve().parent
CARRIER = json.loads((_BASE / "capability-carrier.json").read_text(encoding="utf-8"))
PATTERN_CATALOG = json.loads((_BASE / "execution-patterns.json").read_text(encoding="utf-8"))
CONTRACTS = json.loads((_BASE / "capability-contracts.json").read_text(encoding="utf-8"))
_BINDING_DOCUMENT = json.loads((_BASE / "capability-bindings.json").read_text(encoding="utf-8"))
_FIXTURES_PATH = _BASE.parent / "fixtures" / "fixtures.json"
FIXTURES = json.loads(_FIXTURES_PATH.read_text(encoding="utf-8")) if _FIXTURES_PATH.exists() else {"fixtures": []}

_OPERATIONS_PATH = _BASE / "capability-operations.generated.py"
_OPERATIONS_SPEC = importlib.util.spec_from_file_location("capability_operations_generated", _OPERATIONS_PATH)
OPERATIONS = importlib.util.module_from_spec(_OPERATIONS_SPEC)
sys.modules["capability_operations_generated"] = OPERATIONS
_OPERATIONS_SPEC.loader.exec_module(OPERATIONS)

CAPABILITY_ID = str(CARRIER.get("capabilityId") or "")
sfx_value_at = OPERATIONS.sfx_value_at
_DESCRIPTORS = {str(item.get("carrierCellId")): item for item in OPERATIONS.DESCRIPTORS}
_SCENARIO_DESCRIPTORS = {str(item.get("scenarioId")): item for item in OPERATIONS.DESCRIPTORS if item.get("kind") == "scenario"}
_ROOT_SCENARIO_ID = "resolve-equity-market-price-evidence"
_MECHANIC_CIRCUITS = {str(circuit.get("parentExecutionCellId")): circuit for circuit in (CARRIER.get("mechanicCircuits") or [])}
_BINDING_AUTHORITIES = {str(item.get("id")): item for item in _BINDING_DOCUMENT if isinstance(item, dict) and item.get("id")} if isinstance(_BINDING_DOCUMENT, list) else {}
_BINDING_FUNCTIONS = getattr(OPERATIONS, "BINDING_FUNCTIONS", {})
_PATTERN_BY_ID = {str(pattern.get("patternId")): pattern for pattern in PATTERN_CATALOG.get("patterns") or []}

PATTERN_RESOLVERS = {
    "decomposition": pattern_decomposition,
    "recurrence": pattern_recurrence,
    "selection": pattern_selection,
    "sequence": pattern_sequence,
}

_RECURRENCE_BY_CELL = {}
_FOR_EACH_BY_CELL = {}
_DECOMPOSITION_BY_PARTICIPANT = {}
for _pattern in PATTERN_CATALOG.get("patterns") or []:
    _pattern_type = str(_pattern.get("patternType") or "")
    _participants = [str(cell_id) for cell_id in _pattern.get("participantCellIds") or []]
    if _pattern_type == "recurrence":
        for _cell_id in _participants:
            _RECURRENCE_BY_CELL.setdefault(_cell_id, _pattern)
    elif _pattern_type == "for-each":
        for _cell_id in _participants:
            _FOR_EACH_BY_CELL.setdefault(_cell_id, _pattern)
    elif _pattern_type == "decomposition":
        for _cell_id in _participants:
            _DECOMPOSITION_BY_PARTICIPANT.setdefault(_cell_id, _pattern)

_TERMINAL_CELLS = {}
for _projection in CARRIER.get("eventExecutionProjections") or []:
    _projection_cells = {str(cell.get("cellId")) for cell in _projection.get("cells") or []}
    _scenario_id = str(_projection.get("parentScenarioId") or "")
    for _route in _projection.get("routes") or []:
        _destination = str(_route.get("toCellId"))
        if _destination not in _projection_cells:
            _TERMINAL_CELLS[str(_route.get("fromCellId"))] = _scenario_id

_OPTIONS = {}
_OCCURRENCES = {}
_FIXTURE_OCCURRENCES = {}
_READ_PROVIDERS = {}
_CELL_TESTIMONY = []
_EDGE_TESTIMONY = []
_TESTIMONY_ORDER = [0]
_TESTIMONY_OCCURRENCES = {}
_STEP_BOUND = 100000


def _semantic_id(value):
    normalized = re.sub(r"[^a-z0-9._:-]+", ".", str(value).lower())
    return (normalized.strip("._:-") or "value")[:200]


def _contract_admission():
    catalog = CONTRACTS if isinstance(CONTRACTS, dict) else {}
    contracts = catalog.get("contracts")
    if not isinstance(contracts, dict) or not contracts:
        return None
    return _plan_contract_admission({"contractCatalog": catalog})

_CONTRACT_ADMISSION = _contract_admission()


def _admit(contract_id, value):
    identifier = str(contract_id or "")
    if _CONTRACT_ADMISSION is None or identifier == "" or identifier == "semantic-value.v1":
        return True
    return bool(_CONTRACT_ADMISSION(identifier, value))


def _variant_key(value):
    return _semantic_id(value) if value is not None else ""


def _digest(value):
    encoded = json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    return "sha256:" + hashlib.sha256(encoded).hexdigest()


def _record_cell(cell_id, descriptor, outcome):
    occurrence = _TESTIMONY_OCCURRENCES.get(cell_id, 0)
    _TESTIMONY_OCCURRENCES[cell_id] = occurrence + 1
    declared = descriptor if isinstance(descriptor, dict) else {}
    order = _TESTIMONY_ORDER[0]
    _TESTIMONY_ORDER[0] = order + 1
    _CELL_TESTIMONY.append({
        "testimonyType": "cell-execution-testimony.v1",
        "cellId": cell_id,
        "cellExecutionId": str(_OPTIONS.get("rootExecutionId")) + ":" + cell_id + ":" + str(occurrence),
        "providerProfileId": declared.get("providerProfileId"),
        "outcomeVariant": outcome.get("variant"),
        "disposition": outcome.get("disposition"),
        "outcomeDigest": _digest(outcome.get("value")),
        "logicalOrder": order,
    })


def _record_edge(route, admission_disposition="admitted"):
    from_cell_id = str(route.get("fromCellId") or "")
    to_cell_id = str(route.get("toCellId") or "")
    order = _TESTIMONY_ORDER[0]
    _TESTIMONY_ORDER[0] = order + 1
    entry = {
        "testimonyType": "edge-execution-testimony.v1",
        "edgeId": "route:" + from_cell_id + "->" + to_cell_id,
        "sourceCellId": from_cell_id,
        "destinationCellId": to_cell_id,
    }
    for key in ("edgeKind", "groupId", "joinSlotId", "selectsVariant", "bindingAuthorityId"):
        if isinstance(route.get(key), str):
            entry[key] = route[key]
    entry["admissionDisposition"] = admission_disposition
    entry["logicalOrder"] = order
    _EDGE_TESTIMONY.append(entry)


def _outcome(value, variant=None, disposition="completed", routes=()):
    outcome = {"value": value, "disposition": disposition, "routes": list(routes)}
    if variant is not None:
        outcome["variant"] = variant
    return outcome


def _variant(value, descriptor):
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    variants = list((descriptor or {}).get("variants") or [])
    if isinstance(value, str) and value in variants:
        return value
    if isinstance(value, dict):
        for key in ("outcomeVariant", "variant", "route", "disposition", "status", "kind"):
            if isinstance(value.get(key), str):
                return value[key]
    if len(variants) == 1:
        return str(variants[0])
    return "SUCCESS"


def _fixture_port_output(port_id, declared, input_value):
    selected = declared
    if isinstance(declared, dict) and isinstance(declared.get("byCarrierType"), dict):
        carrier_type = input_value.get("carrierType") if isinstance(input_value, dict) else None
        selected = declared["byCarrierType"].get(str(carrier_type), declared)
    if not isinstance(selected, dict):
        raise RuntimeError("FIXTURE_PORT_OUTCOME_INVALID: '" + str(port_id) + "'.")
    if selected.get("status") == "FAILURE":
        error = selected.get("error")
        code = error.get("code") if isinstance(error, dict) else None
        raise RuntimeError("FIXTURE_PORT_FAILURE: '" + str(port_id) + "'" + (":" + str(code) if code else ""))
    if "output" in selected:
        return copy.deepcopy(selected["output"])
    if "status" not in selected:
        return copy.deepcopy(selected)
    raise RuntimeError("FIXTURE_PORT_OUTPUT_MISSING: '" + str(port_id) + "'.")


def _resolve_fixture_graph_value(value, catalog, stack=()):
    if isinstance(value, list):
        return [_resolve_fixture_graph_value(item, catalog, stack) for item in value]
    if not isinstance(value, dict):
        return copy.deepcopy(value)
    if len(value) == 1 and isinstance(value.get("$fixtureRef"), str):
        reference = str(value["$fixtureRef"])
        if reference not in catalog:
            raise RuntimeError("FIXTURE_GRAPH_OUTCOME_REFERENCE_MISSING: '" + reference + "'")
        if reference in stack:
            chain = " -> ".join((*stack, reference))
            raise RuntimeError("FIXTURE_GRAPH_OUTCOME_REFERENCE_CYCLE: '" + chain + "'")
        return _resolve_fixture_graph_value(catalog[reference], catalog, (*stack, reference))
    return {str(key): _resolve_fixture_graph_value(item, catalog, stack) for key, item in value.items()}


def _pattern_context(step):
    def step_many(cell_ids, input_value):
        return [step(str(cell_id), input_value) for cell_id in cell_ids]
    return {"step": step, "stepMany": step_many, "cancelled": lambda: False}


def _invoke_declared_port(descriptor, input_value):
    module = importlib.import_module(str(descriptor.get("portModule")))
    function = getattr(module, str(descriptor.get("portExport")))
    configuration = descriptor.get("configuration") or {}
    if descriptor.get("invocation") == "effects":
        return function(configuration, input_value, {"rootExecutionId": _OPTIONS.get("rootExecutionId")}, _OPTIONS.get("effectContext"))
    return function(configuration, input_value, {"cellId": descriptor.get("cellId"), "rootExecutionId": _OPTIONS.get("rootExecutionId")})


def _read_declared(descriptor, input_value):
    key = str(descriptor.get("portModule")) + "#" + str(descriptor.get("portExport"))
    provider = _READ_PROVIDERS.get(key)
    if provider is None:
        factory = getattr(importlib.import_module(str(descriptor.get("portModule"))), str(descriptor.get("portExport")))
        provider = factory({"readQuery": _OPTIONS.get("readQuery"), "databaseRoot": _OPTIONS.get("databaseRoot")})
        _READ_PROVIDERS[key] = provider
    return provider(input_value, {"cellId": descriptor.get("cellId"), "configuration": descriptor.get("configuration") or {}})


def _fixture_declared(cell_id, input_value):
    scenario_id = _TERMINAL_CELLS.get(cell_id)
    descriptor = _DESCRIPTORS.get(cell_id) or {}
    port_id = descriptor.get("portId")
    declared = None
    if scenario_id is not None and isinstance(_OPTIONS.get("graphOutcomes"), dict):
        declared = _OPTIONS["graphOutcomes"].get(scenario_id)
    if declared is None and port_id is not None and isinstance(_OPTIONS.get("portOutcomes"), dict) and port_id in _OPTIONS["portOutcomes"]:
        declared = {"outcomeValue": _fixture_port_output(port_id, _OPTIONS["portOutcomes"][port_id], input_value)}
    if declared is None:
        return None
    occurrence_key = scenario_id if scenario_id is not None else port_id
    occurrence = _FIXTURE_OCCURRENCES.get(occurrence_key, 0)
    _FIXTURE_OCCURRENCES[occurrence_key] = occurrence + 1
    selected = declared[min(occurrence, len(declared) - 1)] if isinstance(declared, list) else declared
    if not isinstance(selected, dict):
        raise RuntimeError("FIXTURE_GRAPH_OUTCOME_INVALID: '" + str(occurrence_key) + "'.")
    referenced_value = None
    outcome_reference = selected.get("outcomeRef")
    if isinstance(outcome_reference, str):
        catalog = _OPTIONS.get("graphOutcomeCatalog") or {}
        if outcome_reference not in catalog:
            raise RuntimeError("FIXTURE_GRAPH_OUTCOME_REFERENCE_MISSING: '" + outcome_reference + "'")
        referenced_value = catalog[outcome_reference]
    fixture_value = selected.get("outcomeValue")
    if fixture_value is None:
        fixture_value = referenced_value
    if fixture_value is None:
        fixture_value = copy.deepcopy(_OPTIONS.get("rootInput"))
        if isinstance(fixture_value, dict) and isinstance(selected.get("outcomeVariant"), str):
            fixture_value["outcomeVariant"] = selected["outcomeVariant"]
        elif fixture_value is None:
            fixture_value = copy.deepcopy(input_value)
    fixture_value = _resolve_fixture_graph_value(fixture_value, _OPTIONS.get("graphOutcomeCatalog") or {})
    return _outcome(copy.deepcopy(fixture_value), selected.get("outcomeVariant"), selected.get("disposition") or "completed")


def _binding_value(route, value):
    binding_authority_id = route.get("bindingAuthorityId")
    if not isinstance(binding_authority_id, str) or binding_authority_id == "":
        return value
    authority = _BINDING_AUTHORITIES.get(binding_authority_id)
    if authority is None:
        raise RuntimeError("EDGE_BINDING_AUTHORITY_MISSING: '" + binding_authority_id + "'")
    binding = authority.get("binding")
    configuration = binding.get("configuration") if isinstance(binding, dict) else None
    if isinstance(configuration, dict) and "output" in configuration:
        return copy.deepcopy(configuration.get("output"))
    function = _BINDING_FUNCTIONS.get(binding_authority_id)
    if function is None:
        raise RuntimeError("EDGE_BINDING_REALIZATION_MISSING: '" + binding_authority_id + "'")
    return function({"input": value, "root": _OPTIONS.get("rootInput")})


def _route_target(route):
    declared = route.get("toCellId")
    if isinstance(declared, str) and declared:
        return declared
    scenario_id = route.get("targetScenarioId")
    if isinstance(scenario_id, str) and scenario_id:
        return "cell:scenario:" + scenario_id
    return ""


def _route_candidates(routes, disposition, variant):
    candidates = []
    for route in routes:
        kind = str(route.get("edgeKind") or "sequence")
        if disposition in ("failed", "rejected"):
            if kind == "failure" or (kind == "selection" and _variant_key(route.get("selectsVariant")) == _variant_key(variant)):
                candidates.append(route)
        elif disposition == "cancelled":
            if kind == "cancellation":
                candidates.append(route)
        elif kind not in ("failure", "cancellation"):
            candidates.append(route)
    return candidates


def _default_selection_route(members, pattern):
    default_cell = None
    if isinstance(pattern, dict):
        selection = pattern.get("selection")
        if isinstance(selection, dict):
            default_cell = selection.get("defaultDecisionId")
        if default_cell is None:
            for decision in pattern.get("decisions") or []:
                if isinstance(decision, dict) and decision.get("default") is True:
                    default_cell = decision.get("field")
                    break
    if default_cell is None:
        return None
    for route in members:
        if _semantic_id(_route_target(route)) == str(default_cell):
            return route
    return None


def _selected_routes(routes, disposition, variant):
    candidates = _route_candidates(routes, disposition, variant)
    selected = []
    handled = set()
    for route in candidates:
        group_id = route.get("groupId")
        if not isinstance(group_id, str) or group_id == "":
            selected.append(route)
            continue
        if group_id in handled:
            continue
        handled.add(group_id)
        members = [item for item in candidates if item.get("groupId") == group_id]
        pattern = _PATTERN_BY_ID.get(_semantic_id(group_id))
        pattern_type = str(pattern.get("patternType")) if isinstance(pattern, dict) else ""
        if pattern_type == "selection":
            chosen = next((item for item in members if item.get("selectsVariant") is not None and _variant_key(item.get("selectsVariant")) == _variant_key(variant)), None)
            if chosen is None:
                chosen = _default_selection_route(members, pattern)
            if chosen is not None:
                selected.append(chosen)
            continue
        if pattern_type in ("recurrence", "for-each"):
            continue
        selected.extend(members)
    for route in selected:
        _record_edge(route)
    return selected


def _route_continuations(routes, outcome, join_buffers):
    continuations = []
    for route in routes:
        target = _route_target(route)
        kind = str(route.get("edgeKind") or "sequence")
        projected = _binding_value(route, outcome.get("value"))
        if kind != "join":
            continuations.append({"target": target, "input": projected, "joinPattern": None})
            continue
        group_id = str(route.get("groupId") or "")
        buffer_key = group_id + "\x00" + target
        state = join_buffers.get(buffer_key)
        if state is None:
            state = {"slots": {}, "admitted": False}
            join_buffers[buffer_key] = state
        slot_id = _semantic_id(route.get("joinSlotId") if route.get("joinSlotId") is not None else str(len(state["slots"])))
        pattern = _PATTERN_BY_ID.get(_semantic_id(group_id))
        declared = pattern.get("join") if isinstance(pattern, dict) else None
        policy = str((declared or {}).get("policy") or "all-required")
        if policy == "first-admitted":
            if state["admitted"]:
                continue
            state["admitted"] = True
            continuations.append({"target": target, "input": {slot_id: projected}, "joinPattern": pattern})
            continue
        state["slots"][slot_id] = projected
        required = [str(slot) for slot in (declared or {}).get("requiredSlotIds") or []]
        if required and not all(slot in state["slots"] for slot in required):
            continue
        buffer = dict(sorted(state["slots"].items()))
        del join_buffers[buffer_key]
        continuations.append({"target": target, "input": buffer, "joinPattern": pattern})
    return continuations


def _anchor_pattern(cell_id, scope_cell_ids):
    pattern = _RECURRENCE_BY_CELL.get(cell_id)
    if pattern is not None and all(str(participant) in scope_cell_ids for participant in pattern.get("participantCellIds") or []):
        return pattern
    pattern = _FOR_EACH_BY_CELL.get(cell_id)
    if pattern is not None and all(str(participant) in scope_cell_ids for participant in pattern.get("participantCellIds") or []):
        return pattern
    return None


def _execute_descriptor(cell_id, descriptor, value, scope_input):
    kind = descriptor.get("kind")
    if kind == "expression":
        expression_input = scope_input if scope_input is not None else value
        scope = {"input": expression_input, "root": _OPTIONS.get("rootInput")}
        function = getattr(OPERATIONS, str(descriptor.get("function")))
        try:
            expression_value = function(scope)
            if expression_value is None:
                expression = descriptor.get("expression") or {}
                path_scope = expression.get("from", "input") if expression.get("op") == "path" else None
                if path_scope in ("input", "root"):
                    return _outcome(False, "FALSE")
                raise RuntimeError("LEXICAL_BINDING_NOT_AVAILABLE_AT_CELL_ALTITUDE")
            if descriptor.get("collection"):
                occurrence = _OCCURRENCES.get(cell_id, 0)
                _OCCURRENCES[cell_id] = occurrence + 1
                source_function = descriptor.get("sourceFunction")
                source = getattr(OPERATIONS, str(source_function))(scope) if source_function else []
                iterations = len(source) if isinstance(source, list) else 0
                return _outcome(expression_value, "continue" if occurrence < iterations else "stop")
            return _outcome(expression_value, _variant(expression_value, descriptor))
        except Exception:
            return _outcome(value, "VALUE")
    if kind == "identity":
        return _outcome(value, "VALUE")
    if kind == "declarative-value":
        configuration = descriptor.get("configuration") or {}
        outcome_value = copy.deepcopy(configuration.get("outcome"))
        return _outcome(outcome_value, _variant(outcome_value, descriptor))
    if kind == "declared-read":
        try:
            outcome_value = _read_declared(descriptor, value)
            return _outcome(outcome_value, _variant(outcome_value, descriptor))
        except Exception as error:
            return _outcome({"code": "CELL_EXECUTION_FAILED", "message": str(error)}, "FAILURE", "failed")
    if kind == "provider":
        try:
            outcome_value = _invoke_declared_port(descriptor, value)
            return _outcome(outcome_value, _variant(outcome_value, descriptor))
        except Exception as error:
            return _outcome({"code": "CELL_EXECUTION_FAILED", "message": str(error)}, "FAILURE", "failed")
    return _outcome(value, _variant(value, descriptor))


def _make_step(scope_input):
    def step(cell_id, value, options=None):
        descriptor = _DESCRIPTORS.get(cell_id)
        if descriptor is not None and not _admit(descriptor.get("inputContractId"), value):
            outcome = _outcome(value, "INPUT_REJECTED", "rejected")
        else:
            try:
                fixture = _fixture_declared(cell_id, value)
            except RuntimeError as error:
                outcome = _outcome({"code": "CELL_EXECUTION_FAILED", "message": str(error)}, "FAILURE", "failed")
            else:
                if fixture is not None:
                    outcome = fixture
                else:
                    circuit = _MECHANIC_CIRCUITS.get(cell_id)
                    if circuit is not None:
                        result = _run_scope(
                            {str(cell.get("cellId")): cell for cell in circuit.get("cells") or []},
                            circuit.get("routes") or [],
                            str(circuit.get("rootCellId")),
                            value,
                            value,
                        )
                        outcome = _settle_decomposition(result, step)
                    elif descriptor is None:
                        outcome = _outcome(value, _variant(value, {}))
                    else:
                        outcome = _execute_descriptor(cell_id, descriptor, value, scope_input)
            if outcome.get("disposition") == "completed" and descriptor is not None and not _admit(descriptor.get("outcomeContractId"), outcome.get("value")):
                outcome = _outcome(outcome.get("value"), "OUTCOME_REJECTED", "rejected")
        _record_cell(cell_id, descriptor, outcome)
        return outcome
    return step


def _settle_decomposition(result, step):
    exit_cell = result.get("exitCellId")
    pattern = _DECOMPOSITION_BY_PARTICIPANT.get(str(exit_cell)) if exit_cell else None
    resolver = PATTERN_RESOLVERS.get("decomposition")
    if pattern is None or resolver is None:
        return result
    return resolver(pattern, result, _pattern_context(step))


def _run_scope(cells, routes, root_cell_id, input_value, scope_input):
    cell_ids = set(cells)
    outgoing = {}
    for route in routes:
        outgoing.setdefault(str(route.get("fromCellId")), []).append(route)
    for values in outgoing.values():
        values.sort(key=lambda route: (str(route.get("toCellId")), str(route.get("edgeKind")), str(route.get("selectsVariant"))))
    step = _make_step(scope_input)
    context = _pattern_context(step)
    join_buffers = {}
    queue = [{"cellId": str(root_cell_id), "input": input_value, "joinPattern": None}]
    final = None
    exit_cell = str(root_cell_id)
    visited = 0
    while queue:
        visited += 1
        if visited > _STEP_BOUND:
            raise RuntimeError("CAPABILITY_CARRIER_STEP_BOUND_EXCEEDED")
        token = queue.pop(0)
        cell_id = str(token.get("cellId"))
        value = token.get("input")
        join_pattern = token.get("joinPattern")
        if join_pattern is not None:
            resolver = PATTERN_RESOLVERS.get("join")
            if resolver is None:
                raise RuntimeError("EXECUTION_PATTERN_RESOLVER_MISSING: 'join'")
            instance = dict(join_pattern)
            declared = dict(instance.get("join") or {})
            declared["slotValues"] = value
            instance["join"] = declared
            outcome = resolver(instance, value, context)
        else:
            pattern = _anchor_pattern(cell_id, cell_ids)
            if pattern is not None:
                resolver = PATTERN_RESOLVERS.get(str(pattern.get("patternType")))
                if resolver is None:
                    raise RuntimeError("EXECUTION_PATTERN_RESOLVER_MISSING: '" + str(pattern.get("patternType")) + "'")
                outcome = resolver(pattern, value, context)
                _record_cell(cell_id, _DESCRIPTORS.get(cell_id), outcome)
            else:
                outcome = step(cell_id, value)
        disposition = str(outcome.get("disposition") or "completed")
        selected = _selected_routes(outgoing.get(cell_id) or [], disposition, outcome.get("variant"))
        continuations = []
        external = None
        for route in selected:
            if _route_target(route) not in cell_ids:
                external = route
                break
            continuations.append(route)
        if external is not None:
            final = _outcome(_binding_value(external, outcome.get("value")), outcome.get("variant"), disposition, [])
            exit_cell = cell_id
            break
        if not continuations:
            final = outcome
            exit_cell = cell_id
            if disposition != "completed":
                break
            continue
        for continuation in _route_continuations(continuations, outcome, join_buffers):
            queue.append({"cellId": continuation["target"], "input": continuation["input"], "joinPattern": continuation["joinPattern"]})
    if final is None:
        final = _outcome(input_value, None, "completed", [])
    terminal = {
        "value": final.get("value"),
        "disposition": str(final.get("disposition") or "completed"),
        "routes": list(final.get("routes") or []),
        "exitCellId": exit_cell,
    }
    if final.get("variant") is not None:
        terminal["variant"] = final.get("variant")
    return terminal


def execute_capability(input_value, options=None):
    resolved = dict(options or {})
    _OPTIONS.update({
        "rootInput": input_value,
        "rootExecutionId": resolved.get("rootExecutionId") or ("execution:" + str(CARRIER.get("capabilityId"))),
        "portOutcomes": resolved.get("portOutcomes") or {},
        "graphOutcomes": resolved.get("graphOutcomes") or {},
        "graphOutcomeCatalog": resolved.get("graphOutcomeCatalog") or {},
        "effectContext": resolved.get("effectContext") or create_governed_effect_context(),
        "readQuery": resolved.get("readQuery"),
        "databaseRoot": resolved.get("databaseRoot"),
    })
    _OCCURRENCES.clear()
    _FIXTURE_OCCURRENCES.clear()
    _READ_PROVIDERS.clear()
    _CELL_TESTIMONY.clear()
    _EDGE_TESTIMONY.clear()
    _TESTIMONY_OCCURRENCES.clear()
    _TESTIMONY_ORDER[0] = 0
    projections = {
        str(projection.get("parentScenarioId")): projection
        for projection in CARRIER.get("eventExecutionProjections") or []
    }
    scenario_cells = {str(item.get("scenarioId")): item for item in CARRIER.get("scenarioCells") or []}
    ordered = sorted(scenario_cells.values(), key=lambda item: int(item.get("sequence") or 0))
    if not ordered:
        raise RuntimeError("CAPABILITY_CARRIER_HAS_NO_SCENARIOS")
    scenario_routes = {
        scenario_id: sorted(scenario_cells[scenario_id].get("routes") or [], key=lambda route: (str(route.get("targetScenarioId")), str(route.get("edgeKind")), str(route.get("selectsVariant"))))
        for scenario_id in scenario_cells
    }
    scenario_by_cell = {_semantic_id("cell:scenario:" + scenario_id): scenario_id for scenario_id in scenario_cells}
    incoming_scenarios = set()
    for _scenario in scenario_cells.values():
        for _route in _scenario.get("routes") or []:
            _target_scenario = scenario_by_cell.get(_semantic_id(_route_target(_route)))
            if _target_scenario is not None:
                incoming_scenarios.add(_target_scenario)
    root_scenario = _ROOT_SCENARIO_ID if _ROOT_SCENARIO_ID in scenario_cells else ""
    if root_scenario == "":
        root_scenario = next((str(item.get("scenarioId")) for item in ordered if str(item.get("scenarioId")) not in incoming_scenarios), "")
    if root_scenario == "":
        root_scenario = str(ordered[0].get("scenarioId"))
    executions = []
    execution_count = {}

    def execute_scenario(scenario_id, scenario_input):
        projection = projections.get(scenario_id)
        if projection is None:
            raise RuntimeError("CAPABILITY_CARRIER_PROJECTION_MISSING: '" + scenario_id + "'")
        descriptor = _SCENARIO_DESCRIPTORS.get(scenario_id) or {}
        if not _admit(descriptor.get("inputContractId"), scenario_input):
            outcome = _outcome(scenario_input, "INPUT_REJECTED", "rejected")
        else:
            cells = {str(cell.get("cellId")): cell for cell in projection.get("cells") or []}
            result = _run_scope(cells, projection.get("routes") or [], str(projection.get("rootCellId")), scenario_input, None)
            outcome = _settle_decomposition(result, _make_step(None))
            if outcome.get("disposition") == "completed" and not _admit(descriptor.get("outcomeContractId"), outcome.get("value")):
                outcome = _outcome(outcome.get("value"), "OUTCOME_REJECTED", "rejected")
        if outcome.get("disposition") == "completed":
            variant = _variant(outcome.get("value"), descriptor)
        else:
            variant = str(outcome.get("variant")) if outcome.get("variant") is not None else _variant(outcome.get("value"), descriptor)
        occurrence = execution_count.get(scenario_id, 0)
        execution_count[scenario_id] = occurrence + 1
        executions.append({
            "executionId": str(_OPTIONS["rootExecutionId"]) + ":" + scenario_id + ((":" + str(occurrence)) if occurrence else ""),
            "rootExecutionId": _OPTIONS["rootExecutionId"],
            "parentExecutionId": None,
            "scenarioId": scenario_id,
            "disposition": outcome.get("disposition"),
            "outcome": None,
        })
        return _outcome(outcome.get("value"), variant, outcome.get("disposition") or "completed", [])

    def scenario_step(cell_id, value, options=None):
        scenario_id = scenario_by_cell.get(_semantic_id(cell_id))
        if scenario_id is None:
            raise RuntimeError("UNEXPECTED_SCENARIO_STEP: '" + str(cell_id) + "'")
        return execute_scenario(scenario_id, value)

    context = _pattern_context(scenario_step)
    join_buffers = {}
    queue = [{"scenarioId": root_scenario, "input": copy.deepcopy(input_value), "joinPattern": None}]
    final = None
    visited = 0
    while queue:
        visited += 1
        if visited > _STEP_BOUND:
            raise RuntimeError("CAPABILITY_CARRIER_STEP_BOUND_EXCEEDED")
        token = queue.pop(0)
        scenario_id = str(token.get("scenarioId"))
        if scenario_id not in scenario_cells:
            raise RuntimeError("CAPABILITY_CARRIER_PROJECTION_MISSING: '" + scenario_id + "'")
        value = token.get("input")
        join_pattern = token.get("joinPattern")
        if join_pattern is not None:
            resolver = PATTERN_RESOLVERS.get("join")
            if resolver is None:
                raise RuntimeError("EXECUTION_PATTERN_RESOLVER_MISSING: 'join'")
            instance = dict(join_pattern)
            declared = dict(instance.get("join") or {})
            declared["slotValues"] = value
            instance["join"] = declared
            resolved = resolver(instance, value, context)
            scenario_outcome = _outcome(resolved.get("value"), resolved.get("variant"), resolved.get("disposition") or "completed", [])
        else:
            pattern = _anchor_pattern(_semantic_id("cell:scenario:" + scenario_id), set(scenario_by_cell))
            if pattern is not None:
                resolver = PATTERN_RESOLVERS.get(str(pattern.get("patternType")))
                if resolver is None:
                    raise RuntimeError("EXECUTION_PATTERN_RESOLVER_MISSING: '" + str(pattern.get("patternType")) + "'")
                resolved = resolver(pattern, value, context)
                scenario_outcome = _outcome(resolved.get("value"), resolved.get("variant"), resolved.get("disposition") or "completed", [])
            else:
                scenario_outcome = execute_scenario(scenario_id, value)
        selected = _selected_routes(scenario_routes.get(scenario_id) or [], scenario_outcome.get("disposition") or "completed", scenario_outcome.get("variant"))
        routed = False
        for continuation in _route_continuations(selected, scenario_outcome, join_buffers):
            target_scenario = scenario_by_cell.get(_semantic_id(continuation["target"]))
            if target_scenario is None:
                raise RuntimeError("CAPABILITY_CARRIER_PROJECTION_MISSING: '" + str(continuation["target"]) + "'")
            queue.append({"scenarioId": target_scenario, "input": continuation["input"], "joinPattern": continuation["joinPattern"]})
            routed = True
        if not routed:
            final = scenario_outcome
    if final is None:
        raise RuntimeError("CAPABILITY_CARRIER_NO_TERMINAL_OUTCOME")
    disposition = str(final.get("disposition") or "completed")
    return {
        "disposition": "terminated" if disposition == "completed" else disposition,
        "outcome": copy.deepcopy(final.get("value")),
        "outcomeVariant": final.get("variant"),
        "executions": executions,
        "observations": [],
        "graphExecution": {
            "disposition": disposition,
            "outcome": copy.deepcopy(final.get("value")),
            "outcomeVariant": final.get("variant"),
            "cellTestimony": copy.deepcopy(_CELL_TESTIMONY),
            "edgeTestimony": copy.deepcopy(_EDGE_TESTIMONY),
            "observedPathDigest": None,
        },
    }


def run_fixture(fixture_id, options=None):
    fixtures = FIXTURES.get("fixtures") or []
    fixture = next((item for item in fixtures if isinstance(item, dict) and item.get("fixtureId") == fixture_id), None)
    if fixture is None:
        raise RuntimeError("UNKNOWN_PROJECTED_FIXTURE: '" + str(fixture_id) + "'.")
    graph_outcome_catalog = {**(FIXTURES.get("graphOutcomeCatalog") or {}), **(fixture.get("graphOutcomeCatalog") or {})}
    return execute_capability(
        _resolve_fixture_graph_value(fixture.get("input"), graph_outcome_catalog),
        {
            **dict(options or {}),
            "portOutcomes": {**(FIXTURES.get("portOutcomes") or {}), **(fixture.get("portOutcomes") or {})},
            "graphOutcomes": fixture.get("graphOutcomes") or {},
            "graphOutcomeCatalog": graph_outcome_catalog,
        },
    )

FIXTURE_IDS = tuple(str(item.get("fixtureId")) for item in (FIXTURES.get("fixtures") or []) if isinstance(item, dict))

def _at_path(source, path):
    value = source
    for segment in [part for part in path.split(".") if part]:
        if isinstance(value, list) and segment.isdigit():
            value = value[int(segment)]
        elif isinstance(value, dict):
            value = value.get(segment)
        else:
            return None
    return value

def _contains(actual, expected):
    if isinstance(actual, list):
        return expected in actual
    if isinstance(actual, str):
        return str(expected) in actual
    return False

def _fixture_findings(result, expected):
    findings = []
    if result.get("disposition") != expected.get("disposition"):
        findings.append("DISPOSITION_MISMATCH")
    executions = [item for item in (result.get("executions") or []) if isinstance(item, dict)]
    if [item.get("scenarioId") for item in executions] != expected.get("scenarioSequence"):
        findings.append("SCENARIO_SEQUENCE_MISMATCH")
    if expected.get("outcomeVariant") and result.get("outcomeVariant") != expected.get("outcomeVariant"):
        findings.append("OUTCOME_VARIANT_MISMATCH")
    for assertion in expected.get("outcomeAssertions") or []:
        if not isinstance(assertion, dict):
            continue
        actual = _at_path(result.get("outcome"), str(assertion.get("path")))
        operation = assertion.get("operator")
        expected_value = assertion.get("value")
        if operation == "equals":
            matches = actual == expected_value
        elif operation == "contains":
            matches = _contains(actual, expected_value)
        elif operation == "not-contains":
            matches = not _contains(actual, expected_value)
        else:
            matches = False
        if not matches:
            findings.append("OUTCOME_ASSERTION_FAILED:" + str(assertion.get("path")))
    return findings

def prove():
    results = []
    admitted = True
    for fixture in FIXTURES.get("fixtures") or []:
        if not isinstance(fixture, dict) or not isinstance(fixture.get("expected"), dict):
            raise RuntimeError("Fixture is invalid")
        result = run_fixture(str(fixture.get("fixtureId")))
        findings = _fixture_findings(result, fixture["expected"])
        admitted = admitted and not findings
        results.append({
            "fixtureId": fixture.get("fixtureId"),
            "disposition": "PASS" if not findings else "FAIL",
            "actualDisposition": result.get("disposition"),
            "actualScenarioSequence": [item.get("scenarioId") for item in (result.get("executions") or []) if isinstance(item, dict)],
            "actualOutcome": result.get("outcome"),
            "findings": findings,
        })
    return {
        "proofType": "projected-python-consumer-conformance.v1",
        "projectionTarget": "python",
        "mechanicResolution": "RESOLVED",
        "executableOrigin": "PROJECTED_ONLY",
        "fixtures": results,
        "disposition": "ADMITTED" if admitted else "REJECTED",
    }

def value_at(source, dotted_path=""):
    return sfx_value_at(source, dotted_path)

def cli(argv=None):
    arguments = list(sys.argv[1:] if argv is None else argv)
    if arguments and arguments[0] == "--test":
        proof = prove()
        print(json.dumps(proof, separators=(",", ":"), ensure_ascii=False))
        return 0 if proof["disposition"] == "ADMITTED" else 1
    if arguments and arguments[0].startswith("--fixture="):
        fixture_id = arguments[0][len("--fixture="):]
        result = run_fixture(fixture_id)
        print(json.dumps(result, separators=(",", ":"), ensure_ascii=False))
        fixture = next((item for item in (FIXTURES.get("fixtures") or []) if isinstance(item, dict) and item.get("fixtureId") == fixture_id), None)
        expected = fixture.get("expected") if isinstance(fixture, dict) else None
        return 0 if isinstance(expected, dict) and result.get("disposition") == expected.get("disposition") else 1
    if len(arguments) != 1:
        raise ValueError("Expected one JSON-encoded canonical input argument or --test")
    result = execute_capability(json.loads(arguments[0]))
    print(json.dumps(result, separators=(",", ":"), ensure_ascii=False))
    if result.get("disposition") != "terminated":
        return 1
    outcome = result.get("outcome")
    return 1 if isinstance(outcome, dict) and outcome.get("interfaceExitDisposition") == "NONZERO" else 0
