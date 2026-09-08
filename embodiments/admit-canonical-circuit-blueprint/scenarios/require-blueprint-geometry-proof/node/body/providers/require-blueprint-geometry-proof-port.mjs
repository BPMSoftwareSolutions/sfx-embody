// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { sfxEquals, sfxLength, sfxMerge, sfxTruthy, sfxValueAt } from "./native-mechanics.mjs";
export class RequireBlueprintGeometryProofPort {
  execute(input, root = input) {
    return (() => {
      const checksClosed = [
        sfxEquals(
          sfxValueAt(input, "payload.geometryProof.proofType"),
          "canonical-blueprint-geometry-proof.v1",
        ),
        sfxEquals(
          sfxValueAt(input, "payload.geometryProof.blueprintDigest"),
          sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
        ),
        sfxEquals(sfxValueAt(input, "payload.geometryProof.disposition"), "CONFORMS"),
        sfxEquals(
          sfxValueAt(input, "payload.geometryProof.summary.nodeCount"),
          sfxLength(sfxValueAt(input, "payload.candidate.nodes")),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.geometryProof.summary.edgeCount"),
          sfxLength(sfxValueAt(input, "payload.candidate.edges")),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.geometryProof.summary.featureScenarioCount"),
          sfxValueAt(input, "payload.featureScenarioCount"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.geometryProof.summary.findingCount"),
          sfxLength(sfxValueAt(input, "payload.geometryProof.findings")),
        ),
        sfxEquals(sfxLength(sfxValueAt(input, "payload.geometryProof.findings")), 0),
      ].every((condition) => sfxTruthy(sfxValueAt(condition, "")));
      const obligationFindings = [
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.geometryProof.proofType"),
            "canonical-blueprint-geometry-proof.v1",
          ),
        )
          ? []
          : [
              {
                ["code"]: "GEOMETRY_PROOF_CONTRACT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.geometryProof.blueprintDigest"),
            sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "GEOMETRY_PROOF_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        sfxTruthy(sfxEquals(sfxValueAt(input, "payload.geometryProof.disposition"), "CONFORMS"))
          ? []
          : [
              {
                ["code"]: "GEOMETRY_DISPOSITION_NOT_CONFORMING",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.geometryProof.summary.nodeCount"),
            sfxLength(sfxValueAt(input, "payload.candidate.nodes")),
          ),
        )
          ? []
          : [
              {
                ["code"]: "GEOMETRY_NODE_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.geometryProof.summary.edgeCount"),
            sfxLength(sfxValueAt(input, "payload.candidate.edges")),
          ),
        )
          ? []
          : [
              {
                ["code"]: "GEOMETRY_EDGE_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.geometryProof.summary.featureScenarioCount"),
            sfxValueAt(input, "payload.featureScenarioCount"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "GEOMETRY_FEATURE_SCENARIO_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.geometryProof.summary.findingCount"),
            sfxLength(sfxValueAt(input, "payload.geometryProof.findings")),
          ),
        )
          ? []
          : [
              {
                ["code"]: "GEOMETRY_FINDING_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
        sfxTruthy(sfxEquals(sfxLength(sfxValueAt(input, "payload.geometryProof.findings")), 0))
          ? []
          : [
              {
                ["code"]: "GEOMETRY_PROOF_HAS_FINDINGS",
                ["blueprintCellId"]: "require-blueprint-geometry-proof",
              },
            ],
      ].flatMap((findingGroup, findingGroupIndex) => sfxValueAt(findingGroup, ""));
      return sfxMerge(sfxValueAt(input, ""), {
        ["payload"]: sfxMerge(sfxValueAt(input, "payload"), {
          ["require-blueprint-geometry-proofDisposition"]: {
            ["disposition"]: sfxTruthy(sfxValueAt(checksClosed, "")) ? "MET" : "UNMET",
            ["blueprintCellId"]: "require-blueprint-geometry-proof",
            ["findings"]: sfxValueAt(obligationFindings, ""),
          },
        }),
      });
    })();
  }
}
