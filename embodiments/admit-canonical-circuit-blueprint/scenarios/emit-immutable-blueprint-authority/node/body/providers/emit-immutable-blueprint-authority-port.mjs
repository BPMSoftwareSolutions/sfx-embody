// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import {
  canonicalize,
  crypto,
  sfxEquals,
  sfxFormat,
  sfxMerge,
  sfxTruthy,
  sfxValueAt,
} from "./native-mechanics.mjs";
export class EmitImmutableBlueprintAuthorityPort {
  execute(input, root = input) {
    return (() => {
      const conformance = sfxValueAt(
        input,
        "payload.require-blueprint-conformance-evidenceDisposition",
      );
      const geometry = sfxValueAt(input, "payload.require-blueprint-geometry-proofDisposition");
      const review = sfxValueAt(
        input,
        "payload.require-current-approved-review-receiptDisposition",
      );
      const allFindings = [
        sfxValueAt(conformance, "findings"),
        sfxValueAt(geometry, "findings"),
        sfxValueAt(review, "findings"),
      ].flatMap((findingGroup, findingGroupIndex) => sfxValueAt(findingGroup, ""));
      const closed = [
        sfxEquals(sfxValueAt(conformance, "disposition"), "MET"),
        sfxEquals(sfxValueAt(geometry, "disposition"), "MET"),
        sfxEquals(sfxValueAt(review, "disposition"), "MET"),
      ].every((condition) => sfxTruthy(sfxValueAt(condition, "")));
      const admittedLineage = [
        sfxValueAt(input, "payload.candidate.sourceAuthority.lineage"),
        [
          {
            ["authorityId"]: "canonical-blueprint-conformance-evidence.v1",
            ["digest"]: sfxValueAt(input, "payload.conformanceEvidenceDigest"),
          },
          {
            ["authorityId"]: "canonical-blueprint-geometry-proof.v1",
            ["digest"]: sfxValueAt(input, "payload.geometryProofDigest"),
          },
          {
            ["authorityId"]: "canonical-blueprint-review-receipt.v1",
            ["digest"]: sfxValueAt(input, "payload.reviewReceiptDigest"),
          },
        ],
      ].flatMap((lineageGroup, lineageGroupIndex) => sfxValueAt(lineageGroup, ""));
      const admittedBlueprint = sfxMerge(sfxValueAt(input, "payload.candidate"), {
        ["capability"]: sfxMerge(sfxValueAt(input, "payload.candidate.capability"), {
          ["capabilityAuthorityDigest"]: sfxValueAt(input, "payload.featureDigest"),
        }),
        ["sourceAuthority"]: sfxMerge(sfxValueAt(input, "payload.candidate.sourceAuthority"), {
          ["disposition"]: "ADMITTED",
          ["lineage"]: sfxValueAt(admittedLineage, ""),
        }),
      });
      const admittedCarrierDigest = sfxFormat("sha256:{hash}", {
        ["hash"]: crypto
          .createHash("sha256")
          .update(String(JSON.stringify(canonicalize(sfxValueAt(admittedBlueprint, "")))))
          .digest("hex"),
      });
      return {
        ["contractId"]: "admitted-canonical-circuit-blueprint.v1",
        ["payload"]: {
          ["disposition"]: sfxTruthy(sfxValueAt(closed, ""))
            ? "BLUEPRINT_AUTHORITY_ADMITTED"
            : "BLUEPRINT_ADMISSION_REJECTED",
          ["blueprint"]: sfxTruthy(sfxValueAt(closed, ""))
            ? sfxValueAt(admittedBlueprint, "")
            : null,
          ["blueprintAuthorityDigest"]: sfxValueAt(
            input,
            "payload.candidate.blueprintAuthority.authorityDigest",
          ),
          ["candidateCarrierDigest"]: sfxValueAt(input, "payload.candidateCarrierDigest"),
          ["admittedCarrierDigest"]: sfxTruthy(sfxValueAt(closed, ""))
            ? sfxValueAt(admittedCarrierDigest, "")
            : null,
          ["admissionEvidence"]: {
            ["conformanceEvidenceDigest"]: sfxValueAt(input, "payload.conformanceEvidenceDigest"),
            ["geometryProofDigest"]: sfxValueAt(input, "payload.geometryProofDigest"),
            ["reviewReceiptDigest"]: sfxValueAt(input, "payload.reviewReceiptDigest"),
          },
          ["obligationRecord"]: {
            ["conformance"]: sfxValueAt(conformance, ""),
            ["geometry"]: sfxValueAt(geometry, ""),
            ["review"]: sfxValueAt(review, ""),
          },
          ["findings"]: sfxValueAt(allFindings, ""),
          ["blueprintRouteDisposition"]: "CLOSED",
        },
      };
    })();
  }
}
