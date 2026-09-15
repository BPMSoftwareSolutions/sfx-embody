// GENERATED CAPABILITY PROJECTED TEST. Do not hand-edit.
#nullable enable
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Nodes;
using Sda.ProjectedConsumer;

public static class CapabilityProjectedTest
{
    public static async Task<int> Main()
    {
        var failures = new List<string>();
        var fixtures = ProjectedCapabilityExecution.Fixtures["fixtures"] as JsonArray ?? new JsonArray();
        foreach (var item in fixtures)
        {
            var fixture = item!.AsObject();
            var fixtureId = fixture["fixtureId"]!.GetValue<string>();
            var expected = fixture["expected"] as JsonObject ?? new JsonObject();
            var result = await ProjectedCapabilityExecution.RunFixtureAsync(fixtureId);
            var disposition = result["disposition"]?.GetValue<string>();
            if (expected["disposition"]?.GetValue<string>() is string declaredDisposition && disposition != declaredDisposition)
                failures.Add(fixtureId + ": disposition " + disposition);
            if (expected["outcomeVariant"]?.GetValue<string>() is string declaredVariant
                && result["outcomeVariant"]?.GetValue<string>() != declaredVariant)
                failures.Add(fixtureId + ": outcomeVariant " + result["outcomeVariant"]);
            if (expected["scenarioSequence"] is JsonArray expectedSequence)
            {
                var observedSequence = new JsonArray((result["executions"] as JsonArray ?? new JsonArray())
                    .Select(execution => (JsonNode?)(execution?["scenarioId"]?.DeepClone() ?? null)).ToArray());
                if (!JsonNode.DeepEquals(observedSequence, expectedSequence))
                    failures.Add(fixtureId + ": scenarioSequence " + observedSequence.ToJsonString());
            }
            var conformance = ProjectedCapabilityExecution.Conformance(result);
            if (conformance["admissionDisposition"]?.GetValue<string>() != "ADMITTED")
                failures.Add(fixtureId + ": conformance " + conformance["findings"]?.ToJsonString());
            Console.WriteLine(new JsonObject { ["fixtureId"] = fixtureId, ["result"] = result.DeepClone() }.ToJsonString());
        }
        if (failures.Count > 0)
        {
            Console.Error.WriteLine(string.Join("\n", failures));
            return 1;
        }
        Console.WriteLine("PROJECTED_CAPABILITY_CONFORMS");
        return 0;
    }
}
