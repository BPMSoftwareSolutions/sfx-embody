// GENERATED CAPABILITY OPERATIONS. Do not hand-edit.
// canonicalGraphDigest: sha256:e2d87ee252ea78574abc47e6d02691369f5ddb9bbebffe2a287e724d9e4f67af
// realizedGraphDigest: sha256:3430cfa5286c3497762befbe9e485ac180e76986e6add552d82ae53a6d7dc8fb
#nullable enable
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Sda.ProjectedConsumer;

public static class Sfx
{
    public sealed class Refusal : Exception
    {
        public Refusal(string code) : base(code)
        {
        }
    }

    private static readonly JsonSerializerOptions RelaxedJson = new()
    {
        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
    };

    private static Refusal NotAdmitted(string code) => new(code);

    public static JsonNode? ParseLiteral(string json) => JsonNode.Parse(json);

    public static JsonNode? Var(Dictionary<string, JsonNode?> scope, string name) =>
        scope.TryGetValue(name, out var value) ? value?.DeepClone() : null;

    public static Dictionary<string, JsonNode?> Bind(Dictionary<string, JsonNode?> scope, string name, JsonNode? value)
    {
        var next = new Dictionary<string, JsonNode?>(scope, StringComparer.Ordinal);
        next[name] = value?.DeepClone();
        return next;
    }

    public static JsonNode? ValueAt(JsonNode? source, string dottedPath)
    {
        var current = source;
        foreach (var segment in dottedPath.Split('.', StringSplitOptions.RemoveEmptyEntries))
        {
            if (current is null) return null;
            if (current is JsonObject target)
            {
                current = target[segment];
            }
            else if (current is JsonArray array)
            {
                if (segment == "length") current = JsonValue.Create(array.Count);
                else if (int.TryParse(segment, NumberStyles.None, CultureInfo.InvariantCulture, out var arrayIndex)
                    && arrayIndex >= 0 && arrayIndex < array.Count) current = array[arrayIndex];
                else current = null;
            }
            else if (current is JsonValue scalar && scalar.TryGetValue<string>(out var sourceText))
            {
                if (segment == "length") current = JsonValue.Create(sourceText.Length);
                else if (int.TryParse(segment, NumberStyles.None, CultureInfo.InvariantCulture, out var textIndex)
                    && textIndex >= 0 && textIndex < sourceText.Length) current = JsonValue.Create(sourceText[textIndex].ToString());
                else current = null;
            }
            else current = null;
        }
        return current?.DeepClone();
    }

    public static bool Truthy(JsonNode? value)
    {
        if (value is null) return false;
        if (value is JsonValue scalar)
        {
            if (scalar.TryGetValue<bool>(out var flag)) return flag;
            if (scalar.TryGetValue<string>(out var text)) return text.Length > 0;
            if (TryNumber(scalar, out var number)) return number != 0 && !double.IsNaN(number);
            return true;
        }
        if (value is JsonArray array) return array.Count > 0;
        if (value is JsonObject target) return target.Count > 0;
        return true;
    }

    public static bool IsPrimitive(JsonNode? value) =>
        value is null || (value is JsonValue scalar
            && (scalar.TryGetValue<bool>(out _) || scalar.TryGetValue<string>(out _) || TryNumber(scalar, out _)));

    public static bool Equals(JsonNode? left, JsonNode? right)
    {
        if (!IsPrimitive(left) || !IsPrimitive(right)) throw NotAdmitted("OPERAND_NOT_PRIMITIVE");
        if (left is null || right is null) return left is null && right is null;
        var leftScalar = (JsonValue)left;
        var rightScalar = (JsonValue)right;
        if (leftScalar.TryGetValue<bool>(out var leftFlag) || rightScalar.TryGetValue<bool>(out var rightFlag))
        {
            return leftScalar.TryGetValue<bool>(out leftFlag) && rightScalar.TryGetValue<bool>(out rightFlag) && leftFlag == rightFlag;
        }
        if (leftScalar.TryGetValue<string>(out var leftText) || rightScalar.TryGetValue<string>(out var rightText))
        {
            return leftScalar.TryGetValue<string>(out leftText) && rightScalar.TryGetValue<string>(out rightText)
                && string.Equals(leftText, rightText, StringComparison.Ordinal);
        }
        return TryNumber(leftScalar, out var leftNumber) && TryNumber(rightScalar, out var rightNumber) && leftNumber == rightNumber;
    }

    public static bool GreaterThan(JsonNode? left, JsonNode? right)
    {
        if (TryNumber(left, out var leftNumber) && TryNumber(right, out var rightNumber)) return leftNumber > rightNumber;
        if (IsString(left) && IsString(right)) return string.CompareOrdinal(AsString(left), AsString(right)) > 0;
        throw NotAdmitted("OPERAND_NOT_ORDERED");
    }

    public static int Length(JsonNode? value)
    {
        if (value is JsonArray array) return array.Count;
        if (value is JsonValue scalar && scalar.TryGetValue<string>(out var text)) return text.Length;
        throw NotAdmitted("OPERAND_NOT_MEASURABLE");
    }

    public static JsonNode? Object(params (string Key, JsonNode? Value)[] fields)
    {
        var result = new JsonObject();
        foreach (var (key, value) in fields) result[key] = value?.DeepClone();
        return result;
    }

    public static JsonNode? Array(params JsonNode?[] items)
    {
        var result = new JsonArray();
        foreach (var item in items) result.Add(item?.DeepClone());
        return result;
    }

    public static JsonNode? Merge(params JsonNode?[] values)
    {
        var result = new JsonObject();
        foreach (var value in values)
        {
            if (value is null) continue;
            if (value is JsonObject source)
            {
                foreach (var field in source) result[field.Key] = field.Value?.DeepClone();
                continue;
            }
            if (value is JsonArray array)
            {
                for (var index = 0; index < array.Count; index++)
                    result[index.ToString(CultureInfo.InvariantCulture)] = array[index]?.DeepClone();
                continue;
            }
            throw NotAdmitted("OPERAND_NOT_OBJECT");
        }
        return result;
    }

    public static JsonNode? Map(Dictionary<string, JsonNode?> scope, JsonNode? source, string asName, Func<Dictionary<string, JsonNode?>, JsonNode?> body)
    {
        var array = AsArray(source);
        var result = new JsonArray();
        for (var index = 0; index < array.Count; index++)
        {
            var next = Bind(Bind(scope, asName, array[index]), asName + "Index", JsonValue.Create(index));
            result.Add(body(next)?.DeepClone());
        }
        return result;
    }

    public static JsonNode? FlatMap(Dictionary<string, JsonNode?> scope, JsonNode? source, string asName, Func<Dictionary<string, JsonNode?>, JsonNode?> body)
    {
        var array = AsArray(source);
        var result = new JsonArray();
        for (var index = 0; index < array.Count; index++)
        {
            var next = Bind(Bind(scope, asName, array[index]), asName + "Index", JsonValue.Create(index));
            var mapped = body(next);
            if (mapped is JsonArray mappedArray)
            {
                foreach (var item in mappedArray) result.Add(item?.DeepClone());
            }
            else
            {
                result.Add(mapped?.DeepClone());
            }
        }
        return result;
    }

    public static JsonNode? Filter(Dictionary<string, JsonNode?> scope, JsonNode? source, string asName, Func<Dictionary<string, JsonNode?>, JsonNode?> body)
    {
        var array = AsArray(source);
        var result = new JsonArray();
        for (var index = 0; index < array.Count; index++)
        {
            var next = Bind(Bind(scope, asName, array[index]), asName + "Index", JsonValue.Create(index));
            if (Truthy(body(next))) result.Add(array[index]?.DeepClone());
        }
        return result;
    }

    public static JsonNode? Find(Dictionary<string, JsonNode?> scope, JsonNode? source, string asName, Func<Dictionary<string, JsonNode?>, JsonNode?> body)
    {
        var array = AsArray(source);
        for (var index = 0; index < array.Count; index++)
        {
            var next = Bind(Bind(scope, asName, array[index]), asName + "Index", JsonValue.Create(index));
            if (Truthy(body(next))) return array[index]?.DeepClone();
        }
        return null;
    }

    public static JsonNode? Some(Dictionary<string, JsonNode?> scope, JsonNode? source, string asName, Func<Dictionary<string, JsonNode?>, JsonNode?> body)
    {
        var array = AsArray(source);
        for (var index = 0; index < array.Count; index++)
        {
            var next = Bind(Bind(scope, asName, array[index]), asName + "Index", JsonValue.Create(index));
            if (Truthy(body(next))) return JsonValue.Create(true);
        }
        return JsonValue.Create(false);
    }

    public static JsonNode? Every(Dictionary<string, JsonNode?> scope, JsonNode? source, string asName, Func<Dictionary<string, JsonNode?>, JsonNode?> body)
    {
        var array = AsArray(source);
        for (var index = 0; index < array.Count; index++)
        {
            var next = Bind(Bind(scope, asName, array[index]), asName + "Index", JsonValue.Create(index));
            if (!Truthy(body(next))) return JsonValue.Create(false);
        }
        return JsonValue.Create(true);
    }

    public static bool Includes(JsonNode? container, JsonNode? value)
    {
        if (container is JsonArray array) return array.Any(item => JsonNode.DeepEquals(item, value));
        if (container is JsonValue scalar && scalar.TryGetValue<string>(out var text))
            return text.Contains(CoerceText(value), StringComparison.Ordinal);
        throw NotAdmitted("OPERAND_NOT_ADMITTED");
    }

    public static bool Intersects(JsonNode? left, JsonNode? right)
    {
        var leftArray = AsArray(left);
        var rightArray = AsArray(right);
        return leftArray.Any(leftMember => rightArray.Any(rightMember => JsonNode.DeepEquals(leftMember, rightMember)));
    }

    public static JsonNode? Unique(JsonNode? value)
    {
        var members = AsArray(value);
        var result = new JsonArray();
        foreach (var member in members)
        {
            if (member is JsonArray || member is JsonObject) throw NotAdmitted("OPERAND_NOT_PRIMITIVE");
            var duplicate = false;
            foreach (var prior in result)
            {
                if (Equals(prior, member))
                {
                    duplicate = true;
                    break;
                }
            }
            if (!duplicate) result.Add(member?.DeepClone());
        }
        return result;
    }

    public static JsonNode? ObjectValues(JsonNode? value)
    {
        if (value is not JsonObject target) throw NotAdmitted("OPERAND_NOT_OBJECT");
        var result = new JsonArray();
        foreach (var field in target.OrderBy(field => field.Key, StringComparer.Ordinal))
            result.Add(field.Value?.DeepClone());
        return result;
    }

    public static string Join(JsonNode? value, string separator)
    {
        var members = AsArray(value);
        var rendered = new List<string>();
        foreach (var member in members)
        {
            rendered.Add(member switch
            {
                null => "",
                JsonValue scalar when scalar.TryGetValue<bool>(out var flag) => flag ? "true" : "false",
                JsonValue scalar when TryNumber(scalar, out var number) => NumberText(number),
                JsonValue scalar when scalar.TryGetValue<string>(out var text) => text,
                _ => throw NotAdmitted("OPERAND_NOT_PRIMITIVE")
            });
        }
        return string.Join(separator, rendered);
    }

    public static string Format(string template, params (string Key, JsonNode? Value)[] values)
    {
        var result = template;
        foreach (var (key, value) in values)
        {
            var rendered = value switch
            {
                null => "null",
                JsonValue scalar when scalar.TryGetValue<bool>(out var flag) => flag ? "true" : "false",
                JsonValue scalar when TryNumber(scalar, out var number) => NumberText(number),
                JsonValue scalar when scalar.TryGetValue<string>(out var text) => text,
                _ => throw NotAdmitted("OPERAND_NOT_PRIMITIVE")
            };
            result = result.Replace("{" + key + "}", rendered, StringComparison.Ordinal);
        }
        return result;
    }

    public static string Trim(JsonNode? value) => CoerceText(value).Trim();

    public static string LowerCase(JsonNode? value) => CoerceText(value).ToLowerInvariant();

    public static string EscapeHtml(JsonNode? value) => CoerceText(value)
        .Replace("&", "&amp;", StringComparison.Ordinal)
        .Replace("<", "&lt;", StringComparison.Ordinal)
        .Replace(">", "&gt;", StringComparison.Ordinal)
        .Replace("\"", "&quot;", StringComparison.Ordinal)
        .Replace("'", "&#39;", StringComparison.Ordinal);

    public static string Sha256(JsonNode? value) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(CoerceText(value)))).ToLowerInvariant();

    public static string Base64DecodeUtf8(JsonNode? value) =>
        Encoding.UTF8.GetString(Convert.FromBase64String(CoerceText(value)));

    public static string JsonStringify(JsonNode? value) => value?.ToJsonString(RelaxedJson) ?? "null";

    public static JsonNode? Canonicalize(JsonNode? value)
    {
        if (value is JsonArray array) return new JsonArray(array.Select(Canonicalize).ToArray());
        if (value is JsonObject target)
        {
            var result = new JsonObject();
            foreach (var field in target.OrderBy(field => field.Key, StringComparer.Ordinal))
                result[field.Key] = Canonicalize(field.Value);
            return result;
        }
        return value?.DeepClone();
    }

    public static JsonNode? ParseJson(JsonNode? value)
    {
        if (value is not JsonValue scalar || !scalar.TryGetValue<string>(out var text)) throw NotAdmitted("OPERAND_NOT_PRIMITIVE");
        try
        {
            return JsonNode.Parse(text);
        }
        catch (JsonException)
        {
            throw NotAdmitted("VALUE_NOT_PARSABLE");
        }
    }

    public static JsonNode? TryParseJson(JsonNode? value)
    {
        if (value is not JsonValue scalar || !scalar.TryGetValue<string>(out var text)) return NotParsed();
        try
        {
            return new JsonObject
            {
                ["disposition"] = "PARSED",
                ["value"] = JsonNode.Parse(text)
            };
        }
        catch (JsonException)
        {
            return NotParsed();
        }
    }

    private static JsonNode? NotParsed() => new JsonObject
    {
        ["disposition"] = "NOT_PARSED",
        ["value"] = null
    };

    public static JsonNode? DirectedGraphClosure(JsonNode? value)
    {
        var graphInputValid = value is JsonObject;
        var graph = value as JsonObject ?? new JsonObject();
        var declaredNodeIds = AsListOrEmpty(graph, "nodeIds");
        var declaredEdges = AsListOrEmpty(graph, "edges");
        var declaredRootNodeIds = AsListOrEmpty(graph, "rootNodeIds");
        var declaredTerminalNodeIds = AsListOrEmpty(graph, "terminalNodeIds");
        var findings = new List<(string Code, string SubjectId)>();
        var findingKeys = new HashSet<string>(StringComparer.Ordinal);
        void AddFinding(string code, string subjectId)
        {
            if (findingKeys.Add(code + "\u0000" + subjectId)) findings.Add((code, subjectId));
        }

        if (!graphInputValid) AddFinding("GRAPH_INPUT_INVALID", "input");
        if (graph["nodeIds"] is not JsonArray) AddFinding("GRAPH_NODE_IDS_REQUIRED", "nodeIds");
        if (graph["edges"] is not JsonArray) AddFinding("GRAPH_EDGES_REQUIRED", "edges");
        if (graph["rootNodeIds"] is not JsonArray) AddFinding("GRAPH_ROOT_NODE_IDS_REQUIRED", "rootNodeIds");
        if (graph["terminalNodeIds"] is not JsonArray) AddFinding("GRAPH_TERMINAL_NODE_IDS_REQUIRED", "terminalNodeIds");

        var nodeCounts = new Dictionary<string, int>(StringComparer.Ordinal);
        foreach (var declared in declaredNodeIds)
        {
            var nodeId = declared is JsonValue nodeValue && nodeValue.TryGetValue<string>(out var nodeText) ? nodeText : null;
            if (string.IsNullOrEmpty(nodeId))
            {
                AddFinding("GRAPH_NODE_ID_INVALID", declared?.ToJsonString() ?? "");
                continue;
            }
            nodeCounts[nodeId] = nodeCounts.GetValueOrDefault(nodeId) + 1;
        }
        foreach (var entry in nodeCounts)
            if (entry.Value > 1) AddFinding("GRAPH_NODE_ID_DUPLICATE", entry.Key);
        var nodeIds = nodeCounts.Keys.OrderBy(id => id, StringComparer.Ordinal).ToList();
        var nodeSet = nodeIds.ToHashSet(StringComparer.Ordinal);

        var edgeCounts = new Dictionary<string, int>(StringComparer.Ordinal);
        var edges = new List<(string EdgeId, string From, string To)>();
        foreach (var declared in declaredEdges)
        {
            var declaredEdge = declared as JsonObject;
            var edgeId = declaredEdge?["edgeId"] is JsonValue edgeIdValue && edgeIdValue.TryGetValue<string>(out var edgeIdText) ? edgeIdText : null;
            var from = declaredEdge?["from"] is JsonValue fromValue && fromValue.TryGetValue<string>(out var fromText) ? fromText : null;
            var to = declaredEdge?["to"] is JsonValue toValue && toValue.TryGetValue<string>(out var toText) ? toText : null;
            if (string.IsNullOrEmpty(edgeId) || string.IsNullOrEmpty(from) || string.IsNullOrEmpty(to))
            {
                AddFinding("GRAPH_EDGE_INVALID", edgeId ?? "");
                continue;
            }
            edgeCounts[edgeId] = edgeCounts.GetValueOrDefault(edgeId) + 1;
            edges.Add((edgeId, from, to));
        }
        foreach (var entry in edgeCounts)
            if (entry.Value > 1) AddFinding("GRAPH_EDGE_ID_DUPLICATE", entry.Key);
        edges = edges.OrderBy(edge => edge.EdgeId, StringComparer.Ordinal)
            .ThenBy(edge => edge.From, StringComparer.Ordinal)
            .ThenBy(edge => edge.To, StringComparer.Ordinal).ToList();
        foreach (var edge in edges)
        {
            if (!nodeSet.Contains(edge.From)) AddFinding("GRAPH_EDGE_SOURCE_UNRESOLVED", edge.EdgeId);
            if (!nodeSet.Contains(edge.To)) AddFinding("GRAPH_EDGE_TARGET_UNRESOLVED", edge.EdgeId);
        }

        List<string> NormalizeDeclaredNodes(JsonArray values, string invalidCode, string invalidIdentityCode)
        {
            foreach (var declared in values)
            {
                var nodeId = declared is JsonValue nodeValue && nodeValue.TryGetValue<string>(out var nodeText) ? nodeText : null;
                if (string.IsNullOrEmpty(nodeId)) AddFinding(invalidIdentityCode, declared?.ToJsonString() ?? "");
            }
            var normalized = values.Select(item => item is JsonValue nodeValue && nodeValue.TryGetValue<string>(out var nodeText) ? nodeText : null)
                .Where(id => !string.IsNullOrEmpty(id))
                .Distinct(StringComparer.Ordinal)
                .OrderBy(id => id, StringComparer.Ordinal).Cast<string>().ToList();
            foreach (var nodeId in normalized)
                if (!nodeSet.Contains(nodeId)) AddFinding(invalidCode, nodeId);
            return normalized.Where(nodeSet.Contains).ToList();
        }

        var rootNodeIds = NormalizeDeclaredNodes(declaredRootNodeIds, "GRAPH_ROOT_NODE_UNRESOLVED", "GRAPH_ROOT_NODE_ID_INVALID");
        var terminalNodeIds = NormalizeDeclaredNodes(declaredTerminalNodeIds, "GRAPH_TERMINAL_NODE_UNRESOLVED", "GRAPH_TERMINAL_NODE_ID_INVALID");
        var terminalNodeSet = terminalNodeIds.ToHashSet(StringComparer.Ordinal);

        findings = findings.OrderBy(finding => finding.Code, StringComparer.Ordinal)
            .ThenBy(finding => finding.SubjectId, StringComparer.Ordinal).ToList();
        if (findings.Count > 0)
        {
            return new JsonObject
            {
                ["disposition"] = "REJECTED",
                ["nodeIds"] = ToArray(nodeIds),
                ["edgeIds"] = ToArray(edges.Select(edge => edge.EdgeId).Distinct(StringComparer.Ordinal).OrderBy(id => id, StringComparer.Ordinal).ToList()),
                ["rootNodeIds"] = ToArray(rootNodeIds),
                ["terminalNodeIds"] = ToArray(terminalNodeIds),
                ["reachableNodeIds"] = new JsonArray(),
                ["unreachableNodeIds"] = ToArray(nodeIds),
                ["traversalNodeIds"] = new JsonArray(),
                ["traversalEdgeIds"] = new JsonArray(),
                ["reachablePairs"] = new JsonArray(),
                ["terminalReachability"] = new JsonArray(),
                ["cycleComponents"] = new JsonArray(),
                ["cycleEdgeIds"] = new JsonArray(),
                ["fixedPointPasses"] = 0,
                ["findings"] = new JsonArray(findings.Select(finding => (JsonNode?)new JsonObject
                {
                    ["code"] = finding.Code,
                    ["subjectId"] = finding.SubjectId
                }).ToArray())
            };
        }

        var adjacency = nodeIds.ToDictionary(id => id, _ => new List<(string EdgeId, string From, string To)>(), StringComparer.Ordinal);
        foreach (var edge in edges) adjacency[edge.From].Add(edge);
        foreach (var nodeId in nodeIds)
            adjacency[nodeId] = adjacency[nodeId].OrderBy(edge => edge.To, StringComparer.Ordinal)
                .ThenBy(edge => edge.EdgeId, StringComparer.Ordinal).ToList();

        (List<string> Reached, int Passes) ClosureFrom(string startNodeId)
        {
            var reached = new HashSet<string>(StringComparer.Ordinal) { startNodeId };
            var frontier = new List<string> { startNodeId };
            var passes = 0;
            while (frontier.Count > 0)
            {
                var next = new HashSet<string>(StringComparer.Ordinal);
                foreach (var nodeId in frontier.OrderBy(id => id, StringComparer.Ordinal))
                    foreach (var edge in adjacency[nodeId])
                        if (reached.Add(edge.To)) next.Add(edge.To);
                frontier = next.ToList();
                passes++;
            }
            return (reached.OrderBy(id => id, StringComparer.Ordinal).ToList(), passes);
        }

        var closures = nodeIds.ToDictionary(id => id, ClosureFrom, StringComparer.Ordinal);
        var reachablePairs = nodeIds.SelectMany(from => closures[from].Reached
            .Select(to => (JsonNode?)new JsonObject { ["from"] = from, ["to"] = to })).ToArray();
        var reachableNodeSet = new HashSet<string>(rootNodeIds.SelectMany(root => closures[root].Reached), StringComparer.Ordinal);
        var reachableNodeIds = reachableNodeSet.OrderBy(id => id, StringComparer.Ordinal).ToList();
        var unreachableNodeIds = nodeIds.Where(id => !reachableNodeSet.Contains(id)).ToList();

        var traversalNodeIds = new List<string>();
        var traversalEdgeIds = new List<string>();
        var traversedNodes = new HashSet<string>(StringComparer.Ordinal);
        var traversedEdges = new HashSet<string>(StringComparer.Ordinal);
        var frontierNodes = rootNodeIds.ToList();
        while (frontierNodes.Count > 0)
        {
            var nodeId = frontierNodes[0];
            frontierNodes.RemoveAt(0);
            if (!traversedNodes.Add(nodeId)) continue;
            traversalNodeIds.Add(nodeId);
            foreach (var edge in adjacency[nodeId])
            {
                if (traversedEdges.Add(edge.EdgeId)) traversalEdgeIds.Add(edge.EdgeId);
                if (!traversedNodes.Contains(edge.To)) frontierNodes.Add(edge.To);
            }
            frontierNodes.Sort(StringComparer.Ordinal);
        }

        var terminalReachability = nodeIds.Select(nodeId => (JsonNode?)new JsonObject
        {
            ["nodeId"] = nodeId,
            ["terminalNodeIds"] = new JsonArray(closures[nodeId].Reached
                .Where(terminalNodeSet.Contains).Select(id => JsonValue.Create(id)).ToArray())
        }).ToArray();

        var assignedCycleNodes = new HashSet<string>(StringComparer.Ordinal);
        var cycleComponents = new List<List<string>>();
        foreach (var nodeId in nodeIds)
        {
            if (assignedCycleNodes.Contains(nodeId)) continue;
            var mutuallyReachable = nodeIds.Where(peerNodeId =>
                closures[nodeId].Reached.Contains(peerNodeId) && closures[peerNodeId].Reached.Contains(nodeId)).ToList();
            var hasSelfLoop = edges.Any(edge => edge.From == nodeId && edge.To == nodeId);
            if (mutuallyReachable.Count > 1 || hasSelfLoop)
            {
                foreach (var member in mutuallyReachable) assignedCycleNodes.Add(member);
                cycleComponents.Add(mutuallyReachable);
            }
        }
        cycleComponents = cycleComponents.OrderBy(component => string.Join("\u0000", component), StringComparer.Ordinal).ToList();
        var cycleComponentByNode = new Dictionary<string, int>(StringComparer.Ordinal);
        for (var index = 0; index < cycleComponents.Count; index++)
            foreach (var member in cycleComponents[index]) cycleComponentByNode[member] = index;
        var cycleEdgeIds = edges
            .Where(edge => cycleComponentByNode.ContainsKey(edge.From)
                && cycleComponentByNode[edge.From] == cycleComponentByNode.GetValueOrDefault(edge.To, -1))
            .Select(edge => edge.EdgeId).OrderBy(id => id, StringComparer.Ordinal).ToList();

        return new JsonObject
        {
            ["disposition"] = "CLOSED",
            ["nodeIds"] = ToArray(nodeIds),
            ["edgeIds"] = new JsonArray(edges.Select(edge => JsonValue.Create(edge.EdgeId)).ToArray()),
            ["rootNodeIds"] = ToArray(rootNodeIds),
            ["terminalNodeIds"] = ToArray(terminalNodeIds),
            ["reachableNodeIds"] = ToArray(reachableNodeIds),
            ["unreachableNodeIds"] = ToArray(unreachableNodeIds),
            ["traversalNodeIds"] = ToArray(traversalNodeIds),
            ["traversalEdgeIds"] = ToArray(traversalEdgeIds),
            ["reachablePairs"] = new JsonArray(reachablePairs),
            ["terminalReachability"] = new JsonArray(terminalReachability),
            ["cycleComponents"] = new JsonArray(cycleComponents.Select(component =>
                (JsonNode?)new JsonArray(component.Select(id => JsonValue.Create(id)).ToArray())).ToArray()),
            ["cycleEdgeIds"] = ToArray(cycleEdgeIds),
            ["fixedPointPasses"] = Math.Max(0, closures.Values.Select(closure => closure.Passes).DefaultIfEmpty(0).Max()),
            ["findings"] = new JsonArray()
        };
    }

    private static JsonArray AsListOrEmpty(JsonObject graph, string key) => graph[key] as JsonArray ?? new JsonArray();

    private static JsonArray ToArray(IEnumerable<string> values) =>
        new(values.Select(value => JsonValue.Create(value)).ToArray());

    private static JsonArray AsArray(JsonNode? value) =>
        value as JsonArray ?? throw NotAdmitted("OPERAND_NOT_ARRAY");

    private static bool TryNumber(JsonNode? value, out double number)
    {
        if (value is JsonValue scalar) return TryNumber(scalar, out number);
        number = 0;
        return false;
    }

    private static bool TryNumber(JsonValue scalar, out double number)
    {
        number = 0;
        if (scalar.TryGetValue<double>(out var asDouble)) { number = asDouble; return true; }
        if (scalar.TryGetValue<int>(out var asInt)) { number = asInt; return true; }
        if (scalar.TryGetValue<long>(out var asLong)) { number = asLong; return true; }
        if (scalar.TryGetValue<decimal>(out var asDecimal)) { number = (double)asDecimal; return true; }
        return false;
    }

    private static bool IsString(JsonNode? value) =>
        value is JsonValue scalar && scalar.TryGetValue<string>(out _);

    private static string AsString(JsonNode? value) =>
        value is JsonValue scalar && scalar.TryGetValue<string>(out var text) ? text : "";

    private static string CoerceText(JsonNode? value)
    {
        if (value is null) return "null";
        if (value is JsonValue scalar)
        {
            if (scalar.TryGetValue<bool>(out var flag)) return flag ? "true" : "false";
            if (TryNumber(scalar, out var number)) return NumberText(number);
            if (scalar.TryGetValue<string>(out var text)) return text;
            return "[object Object]";
        }
        if (value is JsonArray array) return string.Join(",", array.Select(CoerceText));
        return "[object Object]";
    }

    private static string NumberText(double value)
    {
        if (double.IsNaN(value)) return "NaN";
        if (value == 0) return "0";
        if (value == Math.Truncate(value) && Math.Abs(value) < 1e15)
            return ((long)value).ToString(CultureInfo.InvariantCulture);
        return value.ToString("R", CultureInfo.InvariantCulture);
    }
}

public static class CapabilityOperations
{
    public static JsonNode? Invoke(int operationIndex, Dictionary<string, JsonNode?> scope) => operationIndex switch
    {
        0 => Operation0(scope),
        1 => Operation1(scope),
        2 => Operation2(scope),
        3 => Operation3(scope),
        4 => Operation4(scope),
        5 => Operation5(scope),
        6 => Operation6(scope),
        7 => Operation7(scope),
        8 => Operation8(scope),
        9 => Operation9(scope),
        10 => Operation10(scope),
        11 => Operation11(scope),
        12 => Operation12(scope),
        13 => Operation13(scope),
        14 => Operation14(scope),
        15 => Operation15(scope),
        16 => Operation16(scope),
        17 => Operation17(scope),
        18 => Operation18(scope),
        19 => Operation19(scope),
        20 => Operation20(scope),
        21 => Operation21(scope),
        22 => Operation22(scope),
        23 => Operation23(scope),
        24 => Operation24(scope),
        25 => Operation25(scope),
        26 => Operation26(scope),
        27 => Operation27(scope),
        28 => Operation28(scope),
        29 => Operation29(scope),
        30 => Operation30(scope),
        31 => Operation31(scope),
        32 => Operation32(scope),
        33 => Operation33(scope),
        34 => Operation34(scope),
        35 => Operation35(scope),
        36 => Operation36(scope),
        37 => Operation37(scope),
        38 => Operation38(scope),
        39 => Operation39(scope),
        40 => Operation40(scope),
        41 => Operation41(scope),
        42 => Operation42(scope),
        43 => Operation43(scope),
        44 => Operation44(scope),
        45 => Operation45(scope),
        46 => Operation46(scope),
        47 => Operation47(scope),
        48 => Operation48(scope),
        49 => Operation49(scope),
        50 => Operation50(scope),
        51 => Operation51(scope),
        52 => Operation52(scope),
        53 => Operation53(scope),
        54 => Operation54(scope),
        55 => Operation55(scope),
        56 => Operation56(scope),
        57 => Operation57(scope),
        58 => Operation58(scope),
        59 => Operation59(scope),
        60 => Operation60(scope),
        61 => Operation61(scope),
        62 => Operation62(scope),
        63 => Operation63(scope),
        64 => Operation64(scope),
        65 => Operation65(scope),
        66 => Operation66(scope),
        67 => Operation67(scope),
        68 => Operation68(scope),
        69 => Operation69(scope),
        70 => Operation70(scope),
        71 => Operation71(scope),
        72 => Operation72(scope),
        73 => Operation73(scope),
        74 => Operation74(scope),
        75 => Operation75(scope),
        76 => Operation76(scope),
        77 => Operation77(scope),
        78 => Operation78(scope),
        79 => Operation79(scope),
        80 => Operation80(scope),
        81 => Operation81(scope),
        82 => Operation82(scope),
        83 => Operation83(scope),
        84 => Operation84(scope),
        85 => Operation85(scope),
        86 => Operation86(scope),
        87 => Operation87(scope),
        88 => Operation88(scope),
        89 => Operation89(scope),
        90 => Operation90(scope),
        91 => Operation91(scope),
        92 => Operation92(scope),
        93 => Operation93(scope),
        94 => Operation94(scope),
        95 => Operation95(scope),
        96 => Operation96(scope),
        97 => Operation97(scope),
        98 => Operation98(scope),
        99 => Operation99(scope),
        100 => Operation100(scope),
        101 => Operation101(scope),
        102 => Operation102(scope),
        103 => Operation103(scope),
        104 => Operation104(scope),
        105 => Operation105(scope),
        106 => Operation106(scope),
        107 => Operation107(scope),
        108 => Operation108(scope),
        109 => Operation109(scope),
        110 => Operation110(scope),
        111 => Operation111(scope),
        112 => Operation112(scope),
        113 => Operation113(scope),
        114 => Operation114(scope),
        115 => Operation115(scope),
        116 => Operation116(scope),
        117 => Operation117(scope),
        118 => Operation118(scope),
        119 => Operation119(scope),
        120 => Operation120(scope),
        121 => Operation121(scope),
        122 => Operation122(scope),
        123 => Operation123(scope),
        124 => Operation124(scope),
        125 => Operation125(scope),
        126 => Operation126(scope),
        127 => Operation127(scope),
        128 => Operation128(scope),
        129 => Operation129(scope),
        130 => Operation130(scope),
        131 => Operation131(scope),
        132 => Operation132(scope),
        133 => Operation133(scope),
        134 => Operation134(scope),
        135 => Operation135(scope),
        136 => Operation136(scope),
        137 => Operation137(scope),
        138 => Operation138(scope),
        139 => Operation139(scope),
        140 => Operation140(scope),
        141 => Operation141(scope),
        142 => Operation142(scope),
        143 => Operation143(scope),
        144 => Operation144(scope),
        145 => Operation145(scope),
        146 => Operation146(scope),
        147 => Operation147(scope),
        148 => Operation148(scope),
        149 => Operation149(scope),
        150 => Operation150(scope),
        151 => Operation151(scope),
        152 => Operation152(scope),
        153 => Operation153(scope),
        154 => Operation154(scope),
        155 => Operation155(scope),
        156 => Operation156(scope),
        157 => Operation157(scope),
        158 => Operation158(scope),
        159 => Operation159(scope),
        160 => Operation160(scope),
        161 => Operation161(scope),
        162 => Operation162(scope),
        163 => Operation163(scope),
        164 => Operation164(scope),
        165 => Operation165(scope),
        166 => Operation166(scope),
        167 => Operation167(scope),
        168 => Operation168(scope),
        169 => Operation169(scope),
        170 => Operation170(scope),
        171 => Operation171(scope),
        172 => Operation172(scope),
        173 => Operation173(scope),
        174 => Operation174(scope),
        175 => Operation175(scope),
        176 => Operation176(scope),
        177 => Operation177(scope),
        178 => Operation178(scope),
        179 => Operation179(scope),
        180 => Operation180(scope),
        181 => Operation181(scope),
        182 => Operation182(scope),
        183 => Operation183(scope),
        184 => Operation184(scope),
        185 => Operation185(scope),
        186 => Operation186(scope),
        187 => Operation187(scope),
        188 => Operation188(scope),
        189 => Operation189(scope),
        190 => Operation190(scope),
        191 => Operation191(scope),
        192 => Operation192(scope),
        193 => Operation193(scope),
        194 => Operation194(scope),
        195 => Operation195(scope),
        196 => Operation196(scope),
        197 => Operation197(scope),
        198 => Operation198(scope),
        199 => Operation199(scope),
        200 => Operation200(scope),
        _ => throw new InvalidOperationException("CAPABILITY_PROJECTION_MECHANIC_UNRESOLVED: operation index " + operationIndex)
    };

    private static JsonNode? Operation0(Dictionary<string, JsonNode?> scope) => Sfx.Object(("credentialReference", Sfx.ParseLiteral("\"RAPID_API_KEY\"")), ("effectLineage", Sfx.Array()), ("effectScope", Sfx.ParseLiteral("\"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY\"")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("requestingCapabilityId", Sfx.ParseLiteral("\"resolve-equity-market-price-evidence\"")));

    private static JsonNode? Operation1(Dictionary<string, JsonNode?> scope) => ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s0) => { s0 = Sfx.Bind(s0, "fallbackCompleted", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "input"), "disposition"), Sfx.ParseLiteral("\"completed\"")))); s0 = Sfx.Bind(s0, "prior", Sfx.ValueAt(Sfx.Var(s0, "input"), "effectLineage.0")); return (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "fallbackCompleted"), "")) ? ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s1) => { s1 = Sfx.Bind(s1, "payload", Sfx.TryParseJson(JsonValue.Create(Sfx.Base64DecodeUtf8(Sfx.ValueAt(Sfx.Var(s1, "input"), "responseBodyBytes"))))); s1 = Sfx.Bind(s1, "quote", Sfx.ValueAt(Sfx.Var(s1, "payload"), "value.quoteResponse.result.0")); return Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")), ("payload", Sfx.Object(("symbol", Sfx.ValueAt(Sfx.Var(s1, "quote"), "symbol")), ("region", Sfx.ValueAt(Sfx.Var(s1, "root"), "payload.region")), ("currency", Sfx.ValueAt(Sfx.Var(s1, "quote"), "currency")), ("observedPrice", Sfx.ValueAt(Sfx.Var(s1, "quote"), "regularMarketPrice")), ("observedMarketTime", Sfx.ValueAt(Sfx.Var(s1, "quote"), "regularMarketTime")), ("marketState", Sfx.ValueAt(Sfx.Var(s1, "quote"), "marketState")), ("exchange", Sfx.ValueAt(Sfx.Var(s1, "quote"), "exchange")), ("sourceAttribution", Sfx.ValueAt(Sfx.Var(s1, "quote"), "quoteSourceName")))), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ParseLiteral("\"rapidapi-yahoo-finance-real-time1-market-quotes.v1\"")), ("providerId", Sfx.ParseLiteral("\"rapidapi/yahoo-finance-real-time1\"")), ("nativeShape", Sfx.ParseLiteral("\"quoteResponse.result.0\""))))); }))(s0) : Sfx.ValueAt(Sfx.Var(s0, "prior"), "")); }))(scope);

    private static JsonNode? Operation2(Dictionary<string, JsonNode?> scope) => Sfx.Object(("allowedResponseHeaders", Sfx.Array(Sfx.ParseLiteral("\"content-type\""), Sfx.ParseLiteral("\"retry-after\""))), ("cancellationScopeReference", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("credentialInjectionRuleId", Sfx.ValueAt(Sfx.Var(scope, "input"), "credentialInjectionRuleId")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b\"")), ("exchangeKind", Sfx.ParseLiteral("\"live-provider-input\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("lineageId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("maxResponseBytes", Sfx.ParseLiteral("262144")), ("method", Sfx.ParseLiteral("\"GET\"")), ("opaqueCredentialBinding", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "input"), "opaqueBindingId")), ("credentialInjectionRuleId", Sfx.ValueAt(Sfx.Var(scope, "input"), "credentialInjectionRuleId")))), ("redirectPolicy", Sfx.ParseLiteral("\"manual\"")), ("requestBodyText", Sfx.ParseLiteral("\"\"")), ("requestUrl", JsonValue.Create(Sfx.Format("https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}", ("region", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region")), ("symbol", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.symbol"))))), ("safeHeaders", Sfx.Object(("X-RapidAPI-Host", Sfx.ParseLiteral("\"yahoo-finance166.p.rapidapi.com\"")))), ("timeoutMilliseconds", Sfx.ParseLiteral("12000")));

    private static JsonNode? Operation3(Dictionary<string, JsonNode?> scope) => ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s0) => { s0 = Sfx.Bind(s0, "completed", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "input"), "disposition"), Sfx.ParseLiteral("\"completed\"")))); s0 = Sfx.Bind(s0, "bodyText", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "completed"), "")) ? JsonValue.Create(Sfx.Base64DecodeUtf8(Sfx.ValueAt(Sfx.Var(s0, "input"), "responseBodyBytes"))) : Sfx.ParseLiteral("\"\""))); s0 = Sfx.Bind(s0, "parsed", Sfx.TryParseJson(Sfx.ValueAt(Sfx.Var(s0, "bodyText"), ""))); s0 = Sfx.Bind(s0, "native", Sfx.ValueAt(Sfx.Var(s0, "parsed"), "value")); s0 = Sfx.Bind(s0, "summaryQuote", Sfx.ValueAt(Sfx.Var(s0, "native"), "quoteSummary.result.0.price")); s0 = Sfx.Bind(s0, "responseQuote", Sfx.ValueAt(Sfx.Var(s0, "native"), "quoteResponse.result.0")); s0 = Sfx.Bind(s0, "symbol", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "symbol") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "symbol"))); s0 = Sfx.Bind(s0, "currency", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "currency") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "currency"))); s0 = Sfx.Bind(s0, "observedPrice", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "regularMarketPrice.raw") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "regularMarketPrice"))); s0 = Sfx.Bind(s0, "observedMarketTime", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "regularMarketTime") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "regularMarketTime"))); s0 = Sfx.Bind(s0, "marketState", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "marketState") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "marketState"))); s0 = Sfx.Bind(s0, "exchange", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "exchange") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "exchange"))); s0 = Sfx.Bind(s0, "sourceAttribution", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "quoteSourceName") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "quoteSourceName"))); s0 = Sfx.Bind(s0, "requiredValues", Sfx.Array(Sfx.ValueAt(Sfx.Var(s0, "symbol"), ""), Sfx.ValueAt(Sfx.Var(s0, "currency"), ""), Sfx.ValueAt(Sfx.Var(s0, "observedPrice"), ""), Sfx.ValueAt(Sfx.Var(s0, "observedMarketTime"), ""), Sfx.ValueAt(Sfx.Var(s0, "marketState"), ""), Sfx.ValueAt(Sfx.Var(s0, "exchange"), ""), Sfx.ValueAt(Sfx.Var(s0, "sourceAttribution"), ""))); s0 = Sfx.Bind(s0, "missing", Sfx.Filter(s0, Sfx.ValueAt(Sfx.Var(s0, "requiredValues"), ""), "v", s1 => JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s1, "v"), ""), Sfx.ParseLiteral("null"))))); s0 = Sfx.Bind(s0, "missingCount", JsonValue.Create(Sfx.Length(Sfx.ValueAt(Sfx.Var(s0, "missing"), "")))); s0 = Sfx.Bind(s0, "conforming", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "missingCount"), ""), Sfx.ParseLiteral("0")))); s0 = Sfx.Bind(s0, "nativeShape", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ParseLiteral("\"quoteSummary.result.0.price\"") : Sfx.ParseLiteral("\"quoteResponse.result.0\""))); s0 = Sfx.Bind(s0, "bindingId", Sfx.ParseLiteral("\"rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED\"")); s0 = Sfx.Bind(s0, "providerId", Sfx.ParseLiteral("\"rapidapi/davethebeast/yahoo-finance166\"")); return (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "completed"), "")) ? (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "conforming"), "")) ? Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")), ("payload", Sfx.Object(("symbol", Sfx.ValueAt(Sfx.Var(s0, "symbol"), "")), ("region", Sfx.ValueAt(Sfx.Var(s0, "root"), "payload.region")), ("currency", Sfx.ValueAt(Sfx.Var(s0, "currency"), "")), ("observedPrice", Sfx.ValueAt(Sfx.Var(s0, "observedPrice"), "")), ("observedMarketTime", Sfx.ValueAt(Sfx.Var(s0, "observedMarketTime"), "")), ("marketState", Sfx.ValueAt(Sfx.Var(s0, "marketState"), "")), ("exchange", Sfx.ValueAt(Sfx.Var(s0, "exchange"), "")), ("sourceAttribution", Sfx.ValueAt(Sfx.Var(s0, "sourceAttribution"), "")))), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(s0, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(s0, "providerId"), "")), ("nativeShape", Sfx.ValueAt(Sfx.Var(s0, "nativeShape"), ""))))) : Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"NATIVE_MARKET_PRICE_TESTIMONY_REJECTED\"")), ("reasonCode", Sfx.ParseLiteral("\"REQUIRED_NATIVE_FIELDS_ABSENT\"")), ("absentFieldCount", Sfx.ValueAt(Sfx.Var(s0, "missingCount"), "")), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(s0, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(s0, "providerId"), "")), ("nativeShape", Sfx.ValueAt(Sfx.Var(s0, "nativeShape"), "")))))) : Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE\"")), ("reasonCode", Sfx.ParseLiteral("\"PROVIDER_EXCHANGE_NOT_COMPLETED\"")), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(s0, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(s0, "providerId"), "")))))); }))(scope);

    private static JsonNode? Operation4(Dictionary<string, JsonNode?> scope) => ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s0) => { s0 = Sfx.Bind(s0, "done", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "input"), "disposition"), Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")))); s0 = Sfx.Bind(s0, "carrier", Sfx.Array(Sfx.ValueAt(Sfx.Var(s0, "input"), ""))); s0 = Sfx.Bind(s0, "request", Sfx.Object(("credentialReference", Sfx.ParseLiteral("\"RAPID_API_KEY\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("requestingCapabilityId", Sfx.ParseLiteral("\"resolve-equity-market-price-evidence\"")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769\"")), ("effectScope", Sfx.ParseLiteral("\"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY\"")), ("effectLineage", Sfx.ValueAt(Sfx.Var(s0, "carrier"), "")))); return (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "done"), "")) ? Sfx.Object(("effectLineage", Sfx.ValueAt(Sfx.Var(s0, "carrier"), ""))) : Sfx.ValueAt(Sfx.Var(s0, "request"), "")); }))(scope);

    private static JsonNode? Operation5(Dictionary<string, JsonNode?> scope) => ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s0) => { s0 = Sfx.Bind(s0, "bound", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "input"), "disposition"), Sfx.ParseLiteral("\"BOUND\"")))); s0 = Sfx.Bind(s0, "url", JsonValue.Create(Sfx.Format("https://yahoo-finance-real-time1.p.rapidapi.com/market/get-quotes?region={region}&symbols={symbols}", ("region", Sfx.ValueAt(Sfx.Var(s0, "root"), "payload.region")), ("symbols", Sfx.ValueAt(Sfx.Var(s0, "root"), "payload.symbol"))))); s0 = Sfx.Bind(s0, "request", Sfx.Object(("requestUrl", Sfx.ValueAt(Sfx.Var(s0, "url"), "")), ("method", Sfx.ParseLiteral("\"GET\"")), ("safeHeaders", Sfx.Object(("x-rapidapi-host", Sfx.ParseLiteral("\"yahoo-finance-real-time1.p.rapidapi.com\"")))), ("allowedResponseHeaders", Sfx.Array(Sfx.ParseLiteral("\"content-type\""), Sfx.ParseLiteral("\"retry-after\""))), ("timeoutMilliseconds", Sfx.ParseLiteral("15000")), ("maxResponseBytes", Sfx.ParseLiteral("262144")), ("requestBodyText", Sfx.ParseLiteral("\"\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769\"")), ("credentialInjectionRuleId", Sfx.ParseLiteral("\"rapidapi-x-rapidapi-key.v1\"")), ("opaqueCredentialBinding", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(s0, "input"), "opaqueBindingId")), ("credentialInjectionRuleId", Sfx.ParseLiteral("\"rapidapi-x-rapidapi-key.v1\"")))), ("effectLineage", Sfx.ValueAt(Sfx.Var(s0, "input"), "effectLineage")))); return (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "bound"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "request"), "") : Sfx.Object(("effectLineage", Sfx.ValueAt(Sfx.Var(s0, "input"), "effectLineage")))); }))(scope);

    private static JsonNode? Operation6(Dictionary<string, JsonNode?> scope) => ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s0) => { s0 = Sfx.Bind(s0, "fallbackCompleted", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "input"), "disposition"), Sfx.ParseLiteral("\"completed\"")))); s0 = Sfx.Bind(s0, "prior", Sfx.ValueAt(Sfx.Var(s0, "input"), "effectLineage.0")); return (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "fallbackCompleted"), "")) ? ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s1) => { s1 = Sfx.Bind(s1, "payload", Sfx.TryParseJson(JsonValue.Create(Sfx.Base64DecodeUtf8(Sfx.ValueAt(Sfx.Var(s1, "input"), "responseBodyBytes"))))); s1 = Sfx.Bind(s1, "quote", Sfx.ValueAt(Sfx.Var(s1, "payload"), "value.quoteResponse.result.0")); return Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")), ("payload", Sfx.Object(("symbol", Sfx.ValueAt(Sfx.Var(s1, "quote"), "symbol")), ("region", Sfx.ValueAt(Sfx.Var(s1, "root"), "payload.region")), ("currency", Sfx.ValueAt(Sfx.Var(s1, "quote"), "currency")), ("observedPrice", Sfx.ValueAt(Sfx.Var(s1, "quote"), "regularMarketPrice")), ("observedMarketTime", Sfx.ValueAt(Sfx.Var(s1, "quote"), "regularMarketTime")), ("marketState", Sfx.ValueAt(Sfx.Var(s1, "quote"), "marketState")), ("exchange", Sfx.ValueAt(Sfx.Var(s1, "quote"), "exchange")), ("sourceAttribution", Sfx.ValueAt(Sfx.Var(s1, "quote"), "quoteSourceName")))), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ParseLiteral("\"rapidapi-yahoo-finance-real-time1-market-quotes.v1\"")), ("providerId", Sfx.ParseLiteral("\"rapidapi/yahoo-finance-real-time1\"")), ("nativeShape", Sfx.ParseLiteral("\"quoteResponse.result.0\""))))); }))(s0) : Sfx.ValueAt(Sfx.Var(s0, "prior"), "")); }))(scope);

    private static JsonNode? Operation7(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(scope, "input"), "disposition"), Sfx.ParseLiteral("\"completed\"")));

    private static JsonNode? Operation8(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "disposition");

    private static JsonNode? Operation9(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"completed\"");

    private static JsonNode? Operation10(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "effectLineage.0");

    private static JsonNode? Operation11(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "prior"), "");

    private static JsonNode? Operation12(Dictionary<string, JsonNode?> scope) => ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s0) => { s0 = Sfx.Bind(s0, "payload", Sfx.TryParseJson(JsonValue.Create(Sfx.Base64DecodeUtf8(Sfx.ValueAt(Sfx.Var(s0, "input"), "responseBodyBytes"))))); s0 = Sfx.Bind(s0, "quote", Sfx.ValueAt(Sfx.Var(s0, "payload"), "value.quoteResponse.result.0")); return Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")), ("payload", Sfx.Object(("symbol", Sfx.ValueAt(Sfx.Var(s0, "quote"), "symbol")), ("region", Sfx.ValueAt(Sfx.Var(s0, "root"), "payload.region")), ("currency", Sfx.ValueAt(Sfx.Var(s0, "quote"), "currency")), ("observedPrice", Sfx.ValueAt(Sfx.Var(s0, "quote"), "regularMarketPrice")), ("observedMarketTime", Sfx.ValueAt(Sfx.Var(s0, "quote"), "regularMarketTime")), ("marketState", Sfx.ValueAt(Sfx.Var(s0, "quote"), "marketState")), ("exchange", Sfx.ValueAt(Sfx.Var(s0, "quote"), "exchange")), ("sourceAttribution", Sfx.ValueAt(Sfx.Var(s0, "quote"), "quoteSourceName")))), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ParseLiteral("\"rapidapi-yahoo-finance-real-time1-market-quotes.v1\"")), ("providerId", Sfx.ParseLiteral("\"rapidapi/yahoo-finance-real-time1\"")), ("nativeShape", Sfx.ParseLiteral("\"quoteResponse.result.0\""))))); }))(scope);

    private static JsonNode? Operation13(Dictionary<string, JsonNode?> scope) => Sfx.TryParseJson(JsonValue.Create(Sfx.Base64DecodeUtf8(Sfx.ValueAt(Sfx.Var(scope, "input"), "responseBodyBytes"))));

    private static JsonNode? Operation14(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Base64DecodeUtf8(Sfx.ValueAt(Sfx.Var(scope, "input"), "responseBodyBytes")));

    private static JsonNode? Operation15(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "responseBodyBytes");

    private static JsonNode? Operation16(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "payload"), "value.quoteResponse.result.0");

    private static JsonNode? Operation17(Dictionary<string, JsonNode?> scope) => Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")), ("payload", Sfx.Object(("symbol", Sfx.ValueAt(Sfx.Var(scope, "quote"), "symbol")), ("region", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region")), ("currency", Sfx.ValueAt(Sfx.Var(scope, "quote"), "currency")), ("observedPrice", Sfx.ValueAt(Sfx.Var(scope, "quote"), "regularMarketPrice")), ("observedMarketTime", Sfx.ValueAt(Sfx.Var(scope, "quote"), "regularMarketTime")), ("marketState", Sfx.ValueAt(Sfx.Var(scope, "quote"), "marketState")), ("exchange", Sfx.ValueAt(Sfx.Var(scope, "quote"), "exchange")), ("sourceAttribution", Sfx.ValueAt(Sfx.Var(scope, "quote"), "quoteSourceName")))), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ParseLiteral("\"rapidapi-yahoo-finance-real-time1-market-quotes.v1\"")), ("providerId", Sfx.ParseLiteral("\"rapidapi/yahoo-finance-real-time1\"")), ("nativeShape", Sfx.ParseLiteral("\"quoteResponse.result.0\"")))));

    private static JsonNode? Operation18(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation19(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"");

    private static JsonNode? Operation20(Dictionary<string, JsonNode?> scope) => Sfx.Object(("symbol", Sfx.ValueAt(Sfx.Var(scope, "quote"), "symbol")), ("region", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region")), ("currency", Sfx.ValueAt(Sfx.Var(scope, "quote"), "currency")), ("observedPrice", Sfx.ValueAt(Sfx.Var(scope, "quote"), "regularMarketPrice")), ("observedMarketTime", Sfx.ValueAt(Sfx.Var(scope, "quote"), "regularMarketTime")), ("marketState", Sfx.ValueAt(Sfx.Var(scope, "quote"), "marketState")), ("exchange", Sfx.ValueAt(Sfx.Var(scope, "quote"), "exchange")), ("sourceAttribution", Sfx.ValueAt(Sfx.Var(scope, "quote"), "quoteSourceName")));

    private static JsonNode? Operation21(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "quote"), "currency");

    private static JsonNode? Operation22(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "quote"), "exchange");

    private static JsonNode? Operation23(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "quote"), "marketState");

    private static JsonNode? Operation24(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "quote"), "regularMarketTime");

    private static JsonNode? Operation25(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "quote"), "regularMarketPrice");

    private static JsonNode? Operation26(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region");

    private static JsonNode? Operation27(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "quote"), "quoteSourceName");

    private static JsonNode? Operation28(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "quote"), "symbol");

    private static JsonNode? Operation29(Dictionary<string, JsonNode?> scope) => Sfx.Object(("bindingId", Sfx.ParseLiteral("\"rapidapi-yahoo-finance-real-time1-market-quotes.v1\"")), ("providerId", Sfx.ParseLiteral("\"rapidapi/yahoo-finance-real-time1\"")), ("nativeShape", Sfx.ParseLiteral("\"quoteResponse.result.0\"")));

    private static JsonNode? Operation30(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"rapidapi-yahoo-finance-real-time1-market-quotes.v1\"");

    private static JsonNode? Operation31(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"quoteResponse.result.0\"");

    private static JsonNode? Operation32(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"rapidapi/yahoo-finance-real-time1\"");

    private static JsonNode? Operation33(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "fallbackCompleted"), "");

    private static JsonNode? Operation34(Dictionary<string, JsonNode?> scope) => Sfx.Object(("credentialReference", Sfx.ParseLiteral("\"RAPID_API_KEY\"")), ("effectLineage", Sfx.Array()), ("effectScope", Sfx.ParseLiteral("\"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY\"")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("requestingCapabilityId", Sfx.ParseLiteral("\"resolve-equity-market-price-evidence\"")));

    private static JsonNode? Operation35(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"RAPID_API_KEY\"");

    private static JsonNode? Operation36(Dictionary<string, JsonNode?> scope) => Sfx.Array();

    private static JsonNode? Operation37(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY\"");

    private static JsonNode? Operation38(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b\"");

    private static JsonNode? Operation39(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation40(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"resolve-equity-market-price-evidence\"");

    private static JsonNode? Operation41(Dictionary<string, JsonNode?> scope) => Sfx.Object(("allowedResponseHeaders", Sfx.Array(Sfx.ParseLiteral("\"content-type\""), Sfx.ParseLiteral("\"retry-after\""))), ("cancellationScopeReference", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("credentialInjectionRuleId", Sfx.ValueAt(Sfx.Var(scope, "input"), "credentialInjectionRuleId")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b\"")), ("exchangeKind", Sfx.ParseLiteral("\"live-provider-input\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("lineageId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("maxResponseBytes", Sfx.ParseLiteral("262144")), ("method", Sfx.ParseLiteral("\"GET\"")), ("opaqueCredentialBinding", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "input"), "opaqueBindingId")), ("credentialInjectionRuleId", Sfx.ValueAt(Sfx.Var(scope, "input"), "credentialInjectionRuleId")))), ("redirectPolicy", Sfx.ParseLiteral("\"manual\"")), ("requestBodyText", Sfx.ParseLiteral("\"\"")), ("requestUrl", JsonValue.Create(Sfx.Format("https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}", ("region", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region")), ("symbol", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.symbol"))))), ("safeHeaders", Sfx.Object(("X-RapidAPI-Host", Sfx.ParseLiteral("\"yahoo-finance166.p.rapidapi.com\"")))), ("timeoutMilliseconds", Sfx.ParseLiteral("12000")));

    private static JsonNode? Operation42(Dictionary<string, JsonNode?> scope) => Sfx.Array(Sfx.ParseLiteral("\"content-type\""), Sfx.ParseLiteral("\"retry-after\""));

    private static JsonNode? Operation43(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"content-type\"");

    private static JsonNode? Operation44(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"retry-after\"");

    private static JsonNode? Operation45(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation46(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "credentialInjectionRuleId");

    private static JsonNode? Operation47(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b\"");

    private static JsonNode? Operation48(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"live-provider-input\"");

    private static JsonNode? Operation49(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation50(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation51(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("262144");

    private static JsonNode? Operation52(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"GET\"");

    private static JsonNode? Operation53(Dictionary<string, JsonNode?> scope) => Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "input"), "opaqueBindingId")), ("credentialInjectionRuleId", Sfx.ValueAt(Sfx.Var(scope, "input"), "credentialInjectionRuleId")));

    private static JsonNode? Operation54(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "opaqueBindingId");

    private static JsonNode? Operation55(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "credentialInjectionRuleId");

    private static JsonNode? Operation56(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"manual\"");

    private static JsonNode? Operation57(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"\"");

    private static JsonNode? Operation58(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Format("https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol={symbol}&region={region}", ("region", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region")), ("symbol", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.symbol"))));

    private static JsonNode? Operation59(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region");

    private static JsonNode? Operation60(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.symbol");

    private static JsonNode? Operation61(Dictionary<string, JsonNode?> scope) => Sfx.Object(("X-RapidAPI-Host", Sfx.ParseLiteral("\"yahoo-finance166.p.rapidapi.com\"")));

    private static JsonNode? Operation62(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"yahoo-finance166.p.rapidapi.com\"");

    private static JsonNode? Operation63(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("12000");

    private static JsonNode? Operation64(Dictionary<string, JsonNode?> scope) => ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s0) => { s0 = Sfx.Bind(s0, "completed", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "input"), "disposition"), Sfx.ParseLiteral("\"completed\"")))); s0 = Sfx.Bind(s0, "bodyText", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "completed"), "")) ? JsonValue.Create(Sfx.Base64DecodeUtf8(Sfx.ValueAt(Sfx.Var(s0, "input"), "responseBodyBytes"))) : Sfx.ParseLiteral("\"\""))); s0 = Sfx.Bind(s0, "parsed", Sfx.TryParseJson(Sfx.ValueAt(Sfx.Var(s0, "bodyText"), ""))); s0 = Sfx.Bind(s0, "native", Sfx.ValueAt(Sfx.Var(s0, "parsed"), "value")); s0 = Sfx.Bind(s0, "summaryQuote", Sfx.ValueAt(Sfx.Var(s0, "native"), "quoteSummary.result.0.price")); s0 = Sfx.Bind(s0, "responseQuote", Sfx.ValueAt(Sfx.Var(s0, "native"), "quoteResponse.result.0")); s0 = Sfx.Bind(s0, "symbol", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "symbol") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "symbol"))); s0 = Sfx.Bind(s0, "currency", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "currency") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "currency"))); s0 = Sfx.Bind(s0, "observedPrice", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "regularMarketPrice.raw") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "regularMarketPrice"))); s0 = Sfx.Bind(s0, "observedMarketTime", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "regularMarketTime") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "regularMarketTime"))); s0 = Sfx.Bind(s0, "marketState", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "marketState") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "marketState"))); s0 = Sfx.Bind(s0, "exchange", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "exchange") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "exchange"))); s0 = Sfx.Bind(s0, "sourceAttribution", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "quoteSourceName") : Sfx.ValueAt(Sfx.Var(s0, "responseQuote"), "quoteSourceName"))); s0 = Sfx.Bind(s0, "requiredValues", Sfx.Array(Sfx.ValueAt(Sfx.Var(s0, "symbol"), ""), Sfx.ValueAt(Sfx.Var(s0, "currency"), ""), Sfx.ValueAt(Sfx.Var(s0, "observedPrice"), ""), Sfx.ValueAt(Sfx.Var(s0, "observedMarketTime"), ""), Sfx.ValueAt(Sfx.Var(s0, "marketState"), ""), Sfx.ValueAt(Sfx.Var(s0, "exchange"), ""), Sfx.ValueAt(Sfx.Var(s0, "sourceAttribution"), ""))); s0 = Sfx.Bind(s0, "missing", Sfx.Filter(s0, Sfx.ValueAt(Sfx.Var(s0, "requiredValues"), ""), "v", s1 => JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s1, "v"), ""), Sfx.ParseLiteral("null"))))); s0 = Sfx.Bind(s0, "missingCount", JsonValue.Create(Sfx.Length(Sfx.ValueAt(Sfx.Var(s0, "missing"), "")))); s0 = Sfx.Bind(s0, "conforming", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "missingCount"), ""), Sfx.ParseLiteral("0")))); s0 = Sfx.Bind(s0, "nativeShape", (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "summaryQuote"), "")) ? Sfx.ParseLiteral("\"quoteSummary.result.0.price\"") : Sfx.ParseLiteral("\"quoteResponse.result.0\""))); s0 = Sfx.Bind(s0, "bindingId", Sfx.ParseLiteral("\"rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED\"")); s0 = Sfx.Bind(s0, "providerId", Sfx.ParseLiteral("\"rapidapi/davethebeast/yahoo-finance166\"")); return (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "completed"), "")) ? (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "conforming"), "")) ? Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")), ("payload", Sfx.Object(("symbol", Sfx.ValueAt(Sfx.Var(s0, "symbol"), "")), ("region", Sfx.ValueAt(Sfx.Var(s0, "root"), "payload.region")), ("currency", Sfx.ValueAt(Sfx.Var(s0, "currency"), "")), ("observedPrice", Sfx.ValueAt(Sfx.Var(s0, "observedPrice"), "")), ("observedMarketTime", Sfx.ValueAt(Sfx.Var(s0, "observedMarketTime"), "")), ("marketState", Sfx.ValueAt(Sfx.Var(s0, "marketState"), "")), ("exchange", Sfx.ValueAt(Sfx.Var(s0, "exchange"), "")), ("sourceAttribution", Sfx.ValueAt(Sfx.Var(s0, "sourceAttribution"), "")))), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(s0, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(s0, "providerId"), "")), ("nativeShape", Sfx.ValueAt(Sfx.Var(s0, "nativeShape"), ""))))) : Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"NATIVE_MARKET_PRICE_TESTIMONY_REJECTED\"")), ("reasonCode", Sfx.ParseLiteral("\"REQUIRED_NATIVE_FIELDS_ABSENT\"")), ("absentFieldCount", Sfx.ValueAt(Sfx.Var(s0, "missingCount"), "")), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(s0, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(s0, "providerId"), "")), ("nativeShape", Sfx.ValueAt(Sfx.Var(s0, "nativeShape"), "")))))) : Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE\"")), ("reasonCode", Sfx.ParseLiteral("\"PROVIDER_EXCHANGE_NOT_COMPLETED\"")), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(s0, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(s0, "providerId"), "")))))); }))(scope);

    private static JsonNode? Operation65(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"rapidapi-davethebeast-yahoo-finance166-stock-price.v1-EDITED\"");

    private static JsonNode? Operation66(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"\"");

    private static JsonNode? Operation67(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Base64DecodeUtf8(Sfx.ValueAt(Sfx.Var(scope, "input"), "responseBodyBytes")));

    private static JsonNode? Operation68(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "responseBodyBytes");

    private static JsonNode? Operation69(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "completed"), "");

    private static JsonNode? Operation70(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(scope, "input"), "disposition"), Sfx.ParseLiteral("\"completed\"")));

    private static JsonNode? Operation71(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "disposition");

    private static JsonNode? Operation72(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"completed\"");

    private static JsonNode? Operation73(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(scope, "missingCount"), ""), Sfx.ParseLiteral("0")));

    private static JsonNode? Operation74(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "missingCount"), "");

    private static JsonNode? Operation75(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("0");

    private static JsonNode? Operation76(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "responseQuote"), "currency");

    private static JsonNode? Operation77(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "currency");

    private static JsonNode? Operation78(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "");

    private static JsonNode? Operation79(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "responseQuote"), "exchange");

    private static JsonNode? Operation80(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "exchange");

    private static JsonNode? Operation81(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "");

    private static JsonNode? Operation82(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "responseQuote"), "marketState");

    private static JsonNode? Operation83(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "marketState");

    private static JsonNode? Operation84(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "");

    private static JsonNode? Operation85(Dictionary<string, JsonNode?> scope) => Sfx.Filter(scope, Sfx.ValueAt(Sfx.Var(scope, "requiredValues"), ""), "v", s0 => JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "v"), ""), Sfx.ParseLiteral("null"))));

    private static JsonNode? Operation86(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "requiredValues"), "");

    private static JsonNode? Operation87(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(scope, "v"), ""), Sfx.ParseLiteral("null")));

    private static JsonNode? Operation88(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "v"), "");

    private static JsonNode? Operation89(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("null");

    private static JsonNode? Operation90(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Length(Sfx.ValueAt(Sfx.Var(scope, "missing"), "")));

    private static JsonNode? Operation91(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "missing"), "");

    private static JsonNode? Operation92(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "parsed"), "value");

    private static JsonNode? Operation93(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"quoteResponse.result.0\"");

    private static JsonNode? Operation94(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"quoteSummary.result.0.price\"");

    private static JsonNode? Operation95(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "");

    private static JsonNode? Operation96(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "responseQuote"), "regularMarketTime");

    private static JsonNode? Operation97(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "regularMarketTime");

    private static JsonNode? Operation98(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "");

    private static JsonNode? Operation99(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "responseQuote"), "regularMarketPrice");

    private static JsonNode? Operation100(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "regularMarketPrice.raw");

    private static JsonNode? Operation101(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "");

    private static JsonNode? Operation102(Dictionary<string, JsonNode?> scope) => Sfx.TryParseJson(Sfx.ValueAt(Sfx.Var(scope, "bodyText"), ""));

    private static JsonNode? Operation103(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "bodyText"), "");

    private static JsonNode? Operation104(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"rapidapi/davethebeast/yahoo-finance166\"");

    private static JsonNode? Operation105(Dictionary<string, JsonNode?> scope) => Sfx.Array(Sfx.ValueAt(Sfx.Var(scope, "symbol"), ""), Sfx.ValueAt(Sfx.Var(scope, "currency"), ""), Sfx.ValueAt(Sfx.Var(scope, "observedPrice"), ""), Sfx.ValueAt(Sfx.Var(scope, "observedMarketTime"), ""), Sfx.ValueAt(Sfx.Var(scope, "marketState"), ""), Sfx.ValueAt(Sfx.Var(scope, "exchange"), ""), Sfx.ValueAt(Sfx.Var(scope, "sourceAttribution"), ""));

    private static JsonNode? Operation106(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "symbol"), "");

    private static JsonNode? Operation107(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "currency"), "");

    private static JsonNode? Operation108(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "observedPrice"), "");

    private static JsonNode? Operation109(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "observedMarketTime"), "");

    private static JsonNode? Operation110(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "marketState"), "");

    private static JsonNode? Operation111(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "exchange"), "");

    private static JsonNode? Operation112(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "sourceAttribution"), "");

    private static JsonNode? Operation113(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "native"), "quoteResponse.result.0");

    private static JsonNode? Operation114(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "responseQuote"), "quoteSourceName");

    private static JsonNode? Operation115(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "quoteSourceName");

    private static JsonNode? Operation116(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "");

    private static JsonNode? Operation117(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "native"), "quoteSummary.result.0.price");

    private static JsonNode? Operation118(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "responseQuote"), "symbol");

    private static JsonNode? Operation119(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "symbol");

    private static JsonNode? Operation120(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "summaryQuote"), "");

    private static JsonNode? Operation121(Dictionary<string, JsonNode?> scope) => Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE\"")), ("reasonCode", Sfx.ParseLiteral("\"PROVIDER_EXCHANGE_NOT_COMPLETED\"")), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(scope, "providerId"), "")))));

    private static JsonNode? Operation122(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation123(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE\"");

    private static JsonNode? Operation124(Dictionary<string, JsonNode?> scope) => Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(scope, "providerId"), "")));

    private static JsonNode? Operation125(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "bindingId"), "");

    private static JsonNode? Operation126(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "providerId"), "");

    private static JsonNode? Operation127(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"PROVIDER_EXCHANGE_NOT_COMPLETED\"");

    private static JsonNode? Operation128(Dictionary<string, JsonNode?> scope) => Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"NATIVE_MARKET_PRICE_TESTIMONY_REJECTED\"")), ("reasonCode", Sfx.ParseLiteral("\"REQUIRED_NATIVE_FIELDS_ABSENT\"")), ("absentFieldCount", Sfx.ValueAt(Sfx.Var(scope, "missingCount"), "")), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(scope, "providerId"), "")), ("nativeShape", Sfx.ValueAt(Sfx.Var(scope, "nativeShape"), "")))));

    private static JsonNode? Operation129(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "missingCount"), "");

    private static JsonNode? Operation130(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation131(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"NATIVE_MARKET_PRICE_TESTIMONY_REJECTED\"");

    private static JsonNode? Operation132(Dictionary<string, JsonNode?> scope) => Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(scope, "providerId"), "")), ("nativeShape", Sfx.ValueAt(Sfx.Var(scope, "nativeShape"), "")));

    private static JsonNode? Operation133(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "bindingId"), "");

    private static JsonNode? Operation134(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "nativeShape"), "");

    private static JsonNode? Operation135(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "providerId"), "");

    private static JsonNode? Operation136(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"REQUIRED_NATIVE_FIELDS_ABSENT\"");

    private static JsonNode? Operation137(Dictionary<string, JsonNode?> scope) => Sfx.Object(("contractId", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("disposition", Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")), ("payload", Sfx.Object(("symbol", Sfx.ValueAt(Sfx.Var(scope, "symbol"), "")), ("region", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region")), ("currency", Sfx.ValueAt(Sfx.Var(scope, "currency"), "")), ("observedPrice", Sfx.ValueAt(Sfx.Var(scope, "observedPrice"), "")), ("observedMarketTime", Sfx.ValueAt(Sfx.Var(scope, "observedMarketTime"), "")), ("marketState", Sfx.ValueAt(Sfx.Var(scope, "marketState"), "")), ("exchange", Sfx.ValueAt(Sfx.Var(scope, "exchange"), "")), ("sourceAttribution", Sfx.ValueAt(Sfx.Var(scope, "sourceAttribution"), "")))), ("providerTestimony", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(scope, "providerId"), "")), ("nativeShape", Sfx.ValueAt(Sfx.Var(scope, "nativeShape"), "")))));

    private static JsonNode? Operation138(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation139(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"");

    private static JsonNode? Operation140(Dictionary<string, JsonNode?> scope) => Sfx.Object(("symbol", Sfx.ValueAt(Sfx.Var(scope, "symbol"), "")), ("region", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region")), ("currency", Sfx.ValueAt(Sfx.Var(scope, "currency"), "")), ("observedPrice", Sfx.ValueAt(Sfx.Var(scope, "observedPrice"), "")), ("observedMarketTime", Sfx.ValueAt(Sfx.Var(scope, "observedMarketTime"), "")), ("marketState", Sfx.ValueAt(Sfx.Var(scope, "marketState"), "")), ("exchange", Sfx.ValueAt(Sfx.Var(scope, "exchange"), "")), ("sourceAttribution", Sfx.ValueAt(Sfx.Var(scope, "sourceAttribution"), "")));

    private static JsonNode? Operation141(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "currency"), "");

    private static JsonNode? Operation142(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "exchange"), "");

    private static JsonNode? Operation143(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "marketState"), "");

    private static JsonNode? Operation144(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "observedMarketTime"), "");

    private static JsonNode? Operation145(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "observedPrice"), "");

    private static JsonNode? Operation146(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region");

    private static JsonNode? Operation147(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "sourceAttribution"), "");

    private static JsonNode? Operation148(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "symbol"), "");

    private static JsonNode? Operation149(Dictionary<string, JsonNode?> scope) => Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "bindingId"), "")), ("providerId", Sfx.ValueAt(Sfx.Var(scope, "providerId"), "")), ("nativeShape", Sfx.ValueAt(Sfx.Var(scope, "nativeShape"), "")));

    private static JsonNode? Operation150(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "bindingId"), "");

    private static JsonNode? Operation151(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "nativeShape"), "");

    private static JsonNode? Operation152(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "providerId"), "");

    private static JsonNode? Operation153(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "conforming"), "");

    private static JsonNode? Operation154(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "completed"), "");

    private static JsonNode? Operation155(Dictionary<string, JsonNode?> scope) => ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s0) => { s0 = Sfx.Bind(s0, "done", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "input"), "disposition"), Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")))); s0 = Sfx.Bind(s0, "carrier", Sfx.Array(Sfx.ValueAt(Sfx.Var(s0, "input"), ""))); s0 = Sfx.Bind(s0, "request", Sfx.Object(("credentialReference", Sfx.ParseLiteral("\"RAPID_API_KEY\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("requestingCapabilityId", Sfx.ParseLiteral("\"resolve-equity-market-price-evidence\"")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769\"")), ("effectScope", Sfx.ParseLiteral("\"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY\"")), ("effectLineage", Sfx.ValueAt(Sfx.Var(s0, "carrier"), "")))); return (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "done"), "")) ? Sfx.Object(("effectLineage", Sfx.ValueAt(Sfx.Var(s0, "carrier"), ""))) : Sfx.ValueAt(Sfx.Var(s0, "request"), "")); }))(scope);

    private static JsonNode? Operation156(Dictionary<string, JsonNode?> scope) => Sfx.Array(Sfx.ValueAt(Sfx.Var(scope, "input"), ""));

    private static JsonNode? Operation157(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "");

    private static JsonNode? Operation158(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(scope, "input"), "disposition"), Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"")));

    private static JsonNode? Operation159(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "disposition");

    private static JsonNode? Operation160(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED\"");

    private static JsonNode? Operation161(Dictionary<string, JsonNode?> scope) => Sfx.Object(("credentialReference", Sfx.ParseLiteral("\"RAPID_API_KEY\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("requestingCapabilityId", Sfx.ParseLiteral("\"resolve-equity-market-price-evidence\"")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769\"")), ("effectScope", Sfx.ParseLiteral("\"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY\"")), ("effectLineage", Sfx.ValueAt(Sfx.Var(scope, "carrier"), "")));

    private static JsonNode? Operation162(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"RAPID_API_KEY\"");

    private static JsonNode? Operation163(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "carrier"), "");

    private static JsonNode? Operation164(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY\"");

    private static JsonNode? Operation165(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769\"");

    private static JsonNode? Operation166(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation167(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"resolve-equity-market-price-evidence\"");

    private static JsonNode? Operation168(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "request"), "");

    private static JsonNode? Operation169(Dictionary<string, JsonNode?> scope) => Sfx.Object(("effectLineage", Sfx.ValueAt(Sfx.Var(scope, "carrier"), "")));

    private static JsonNode? Operation170(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "carrier"), "");

    private static JsonNode? Operation171(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "done"), "");

    private static JsonNode? Operation172(Dictionary<string, JsonNode?> scope) => ((Func<Dictionary<string, JsonNode?>, JsonNode?>)((Dictionary<string, JsonNode?> s0) => { s0 = Sfx.Bind(s0, "bound", JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(s0, "input"), "disposition"), Sfx.ParseLiteral("\"BOUND\"")))); s0 = Sfx.Bind(s0, "url", JsonValue.Create(Sfx.Format("https://yahoo-finance-real-time1.p.rapidapi.com/market/get-quotes?region={region}&symbols={symbols}", ("region", Sfx.ValueAt(Sfx.Var(s0, "root"), "payload.region")), ("symbols", Sfx.ValueAt(Sfx.Var(s0, "root"), "payload.symbol"))))); s0 = Sfx.Bind(s0, "request", Sfx.Object(("requestUrl", Sfx.ValueAt(Sfx.Var(s0, "url"), "")), ("method", Sfx.ParseLiteral("\"GET\"")), ("safeHeaders", Sfx.Object(("x-rapidapi-host", Sfx.ParseLiteral("\"yahoo-finance-real-time1.p.rapidapi.com\"")))), ("allowedResponseHeaders", Sfx.Array(Sfx.ParseLiteral("\"content-type\""), Sfx.ParseLiteral("\"retry-after\""))), ("timeoutMilliseconds", Sfx.ParseLiteral("15000")), ("maxResponseBytes", Sfx.ParseLiteral("262144")), ("requestBodyText", Sfx.ParseLiteral("\"\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769\"")), ("credentialInjectionRuleId", Sfx.ParseLiteral("\"rapidapi-x-rapidapi-key.v1\"")), ("opaqueCredentialBinding", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(s0, "input"), "opaqueBindingId")), ("credentialInjectionRuleId", Sfx.ParseLiteral("\"rapidapi-x-rapidapi-key.v1\"")))), ("effectLineage", Sfx.ValueAt(Sfx.Var(s0, "input"), "effectLineage")))); return (Sfx.Truthy(Sfx.ValueAt(Sfx.Var(s0, "bound"), "")) ? Sfx.ValueAt(Sfx.Var(s0, "request"), "") : Sfx.Object(("effectLineage", Sfx.ValueAt(Sfx.Var(s0, "input"), "effectLineage")))); }))(scope);

    private static JsonNode? Operation173(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Equals(Sfx.ValueAt(Sfx.Var(scope, "input"), "disposition"), Sfx.ParseLiteral("\"BOUND\"")));

    private static JsonNode? Operation174(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "disposition");

    private static JsonNode? Operation175(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"BOUND\"");

    private static JsonNode? Operation176(Dictionary<string, JsonNode?> scope) => Sfx.Object(("requestUrl", Sfx.ValueAt(Sfx.Var(scope, "url"), "")), ("method", Sfx.ParseLiteral("\"GET\"")), ("safeHeaders", Sfx.Object(("x-rapidapi-host", Sfx.ParseLiteral("\"yahoo-finance-real-time1.p.rapidapi.com\"")))), ("allowedResponseHeaders", Sfx.Array(Sfx.ParseLiteral("\"content-type\""), Sfx.ParseLiteral("\"retry-after\""))), ("timeoutMilliseconds", Sfx.ParseLiteral("15000")), ("maxResponseBytes", Sfx.ParseLiteral("262144")), ("requestBodyText", Sfx.ParseLiteral("\"\"")), ("invocationIdentity", Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"")), ("endpointAuthorityDigest", Sfx.ParseLiteral("\"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769\"")), ("credentialInjectionRuleId", Sfx.ParseLiteral("\"rapidapi-x-rapidapi-key.v1\"")), ("opaqueCredentialBinding", Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "input"), "opaqueBindingId")), ("credentialInjectionRuleId", Sfx.ParseLiteral("\"rapidapi-x-rapidapi-key.v1\"")))), ("effectLineage", Sfx.ValueAt(Sfx.Var(scope, "input"), "effectLineage")));

    private static JsonNode? Operation177(Dictionary<string, JsonNode?> scope) => Sfx.Array(Sfx.ParseLiteral("\"content-type\""), Sfx.ParseLiteral("\"retry-after\""));

    private static JsonNode? Operation178(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"content-type\"");

    private static JsonNode? Operation179(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"retry-after\"");

    private static JsonNode? Operation180(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"rapidapi-x-rapidapi-key.v1\"");

    private static JsonNode? Operation181(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "effectLineage");

    private static JsonNode? Operation182(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769\"");

    private static JsonNode? Operation183(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"equity-market-price-evidence.v1\"");

    private static JsonNode? Operation184(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("262144");

    private static JsonNode? Operation185(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"GET\"");

    private static JsonNode? Operation186(Dictionary<string, JsonNode?> scope) => Sfx.Object(("bindingId", Sfx.ValueAt(Sfx.Var(scope, "input"), "opaqueBindingId")), ("credentialInjectionRuleId", Sfx.ParseLiteral("\"rapidapi-x-rapidapi-key.v1\"")));

    private static JsonNode? Operation187(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "opaqueBindingId");

    private static JsonNode? Operation188(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"rapidapi-x-rapidapi-key.v1\"");

    private static JsonNode? Operation189(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"\"");

    private static JsonNode? Operation190(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "url"), "");

    private static JsonNode? Operation191(Dictionary<string, JsonNode?> scope) => Sfx.Object(("x-rapidapi-host", Sfx.ParseLiteral("\"yahoo-finance-real-time1.p.rapidapi.com\"")));

    private static JsonNode? Operation192(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("\"yahoo-finance-real-time1.p.rapidapi.com\"");

    private static JsonNode? Operation193(Dictionary<string, JsonNode?> scope) => Sfx.ParseLiteral("15000");

    private static JsonNode? Operation194(Dictionary<string, JsonNode?> scope) => JsonValue.Create(Sfx.Format("https://yahoo-finance-real-time1.p.rapidapi.com/market/get-quotes?region={region}&symbols={symbols}", ("region", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region")), ("symbols", Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.symbol"))));

    private static JsonNode? Operation195(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.region");

    private static JsonNode? Operation196(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "root"), "payload.symbol");

    private static JsonNode? Operation197(Dictionary<string, JsonNode?> scope) => Sfx.Object(("effectLineage", Sfx.ValueAt(Sfx.Var(scope, "input"), "effectLineage")));

    private static JsonNode? Operation198(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "input"), "effectLineage");

    private static JsonNode? Operation199(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "request"), "");

    private static JsonNode? Operation200(Dictionary<string, JsonNode?> scope) => Sfx.ValueAt(Sfx.Var(scope, "bound"), "");

}
