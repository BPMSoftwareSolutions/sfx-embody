// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { sfxEquals, sfxLength, sfxMerge, sfxTruthy, sfxValueAt } from "./native-mechanics.mjs";
export class RequireBlueprintConformanceEvidencePort {
  execute(input, root = input) {
    return (() => {
      const checksClosed = [
        sfxEquals(
          sfxValueAt(input, "payload.capabilityId"),
          sfxValueAt(input, "payload.candidate.capability.capabilityId"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.featureDigest"),
          sfxValueAt(input, "payload.candidate.sourceAuthority.featureAuthorityRef.digest"),
        ),
        sfxEquals(sfxValueAt(input, "payload.candidate.sourceAuthority.disposition"), "CANDIDATE"),
        sfxEquals(
          sfxValueAt(input, "payload.conformanceEvidence.evidenceVersion"),
          "canonical-blueprint-conformance-evidence.v1",
        ),
        sfxEquals(
          sfxValueAt(input, "payload.conformanceEvidence.blueprintAuthorityDigest"),
          sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.conformanceEvidence.carrierDigest"),
          sfxValueAt(input, "payload.candidateCarrierDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.conformanceEvidence.schemaAuthority.digest"),
          sfxValueAt(input, "payload.canonicalSchemaDigest"),
        ),
        sfxEquals(sfxValueAt(input, "payload.conformanceEvidence.disposition"), "CONFORMS"),
        sfxEquals(sfxLength(sfxValueAt(input, "payload.conformanceEvidence.findings")), 0),
      ].every((condition) => sfxTruthy(sfxValueAt(condition, "")));
      const obligationFindings = [
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.capabilityId"),
            sfxValueAt(input, "payload.candidate.capability.capabilityId"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "TARGET_CAPABILITY_ID_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.featureDigest"),
            sfxValueAt(input, "payload.candidate.sourceAuthority.featureAuthorityRef.digest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "TARGET_FEATURE_AUTHORITY_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.candidate.sourceAuthority.disposition"),
            "CANDIDATE",
          ),
        )
          ? []
          : [
              {
                ["code"]: "CANDIDATE_SOURCE_DISPOSITION_NOT_CANDIDATE",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.conformanceEvidence.evidenceVersion"),
            "canonical-blueprint-conformance-evidence.v1",
          ),
        )
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_EVIDENCE_CONTRACT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.conformanceEvidence.blueprintAuthorityDigest"),
            sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_EVIDENCE_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.conformanceEvidence.carrierDigest"),
            sfxValueAt(input, "payload.candidateCarrierDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_EVIDENCE_CARRIER_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.conformanceEvidence.schemaAuthority.digest"),
            sfxValueAt(input, "payload.canonicalSchemaDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_SCHEMA_AUTHORITY_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        sfxTruthy(
          sfxEquals(sfxValueAt(input, "payload.conformanceEvidence.disposition"), "CONFORMS"),
        )
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_DISPOSITION_NOT_CONFORMING",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        sfxTruthy(
          sfxEquals(sfxLength(sfxValueAt(input, "payload.conformanceEvidence.findings")), 0),
        )
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_EVIDENCE_HAS_FINDINGS",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
      ].flatMap((findingGroup, findingGroupIndex) => sfxValueAt(findingGroup, ""));
      return sfxMerge(sfxValueAt(input, ""), {
        ["payload"]: sfxMerge(sfxValueAt(input, "payload"), {
          ["require-blueprint-conformance-evidenceDisposition"]: {
            ["disposition"]: sfxTruthy(sfxValueAt(checksClosed, "")) ? "MET" : "UNMET",
            ["blueprintCellId"]: "require-blueprint-conformance-evidence",
            ["findings"]: sfxValueAt(obligationFindings, ""),
          },
        }),
      });
    })();
  }
}
