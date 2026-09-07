// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
export class RequireBlueprintGeometryProofPort {
  execute(input, root = input) {
    return (() => {
      const checksClosed = [
        input?.payload?.geometryProof?.proofType === "canonical-blueprint-geometry-proof.v1",
        input?.payload?.geometryProof?.blueprintDigest ===
          input?.payload?.candidate?.blueprintAuthority?.authorityDigest,
        input?.payload?.geometryProof?.disposition === "CONFORMS",
        input?.payload?.geometryProof?.summary?.nodeCount ===
          (input?.payload?.candidate?.nodes).length,
        input?.payload?.geometryProof?.summary?.edgeCount ===
          (input?.payload?.candidate?.edges).length,
        input?.payload?.geometryProof?.summary?.featureScenarioCount ===
          input?.payload?.featureScenarioCount,
        input?.payload?.geometryProof?.summary?.findingCount ===
          (input?.payload?.geometryProof?.findings).length,
        (input?.payload?.geometryProof?.findings).length === 0,
      ].every((condition) => Boolean(condition));
      const obligationFindings = [
        input?.payload?.geometryProof?.proofType === "canonical-blueprint-geometry-proof.v1"
          ? []
          : [
              {
                ["code"]: "GEOMETRY_PROOF_CONTRACT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        input?.payload?.geometryProof?.blueprintDigest ===
        input?.payload?.candidate?.blueprintAuthority?.authorityDigest
          ? []
          : [
              {
                ["code"]: "GEOMETRY_PROOF_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        input?.payload?.geometryProof?.disposition === "CONFORMS"
          ? []
          : [
              {
                ["code"]: "GEOMETRY_DISPOSITION_NOT_CONFORMING",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        input?.payload?.geometryProof?.summary?.nodeCount ===
        (input?.payload?.candidate?.nodes).length
          ? []
          : [
              {
                ["code"]: "GEOMETRY_NODE_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        input?.payload?.geometryProof?.summary?.edgeCount ===
        (input?.payload?.candidate?.edges).length
          ? []
          : [
              {
                ["code"]: "GEOMETRY_EDGE_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        input?.payload?.geometryProof?.summary?.featureScenarioCount ===
        input?.payload?.featureScenarioCount
          ? []
          : [
              {
                ["code"]: "GEOMETRY_FEATURE_SCENARIO_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        input?.payload?.geometryProof?.summary?.findingCount ===
        (input?.payload?.geometryProof?.findings).length
          ? []
          : [
              {
                ["code"]: "GEOMETRY_FINDING_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        (input?.payload?.geometryProof?.findings).length === 0
          ? []
          : [
              {
                ["code"]: "GEOMETRY_PROOF_HAS_FINDINGS",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
      ].flatMap((findingGroup, findingGroupIndex) => findingGroup);
      return Object.assign({}, input, {
        ["payload"]: Object.assign({}, input?.payload, {
          ["require-blueprint-geometry-proofDisposition"]: {
            ["disposition"]: checksClosed ? "MET" : "UNMET",
            ["blueprintCellId"]: "require-blueprint-geometry-proof",
            ["findings"]: obligationFindings,
          },
        }),
      });
    })();
  }
}
