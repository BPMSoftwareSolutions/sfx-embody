// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import {
  canonicalize,
  sfxEquals,
  sfxLength,
  sfxMerge,
  sfxTruthy,
  sfxValueAt,
} from "./native-mechanics.mjs";
export class RequireCurrentApprovedReviewReceiptPort {
  execute(input, root = input) {
    return (() => {
      const checksClosed = [
        sfxEquals(
          sfxValueAt(input, "payload.projectionReceipt.capability.capabilityId"),
          sfxValueAt(input, "payload.capabilityId"),
        ),
        sfxEquals(sfxLength(sfxValueAt(input, "payload.reviewBoundary.capabilities")), 1),
        sfxEquals(
          sfxValueAt(input, "payload.reviewBoundary.capabilities.0.capabilityId"),
          sfxValueAt(input, "payload.capabilityId"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewBoundary.capabilities.0.capabilityAuthorityDigest"),
          sfxValueAt(input, "payload.featureDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewBoundary.capabilities.0.blueprintAuthorityDigest"),
          sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewBoundary.capabilities.0.carrierDigest"),
          sfxValueAt(input, "payload.candidateCarrierDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewBoundary.capabilities.0.projectionReceiptDigest"),
          sfxValueAt(input, "payload.projectionReceiptDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewBoundary.capabilities.0.geometryProofDigest"),
          sfxValueAt(input, "payload.geometryProofDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewBoundary.capabilities.0.geometryDisposition"),
          sfxValueAt(input, "payload.geometryProof.disposition"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewBoundary.capabilities.0.geometryFindingCount"),
          sfxLength(sfxValueAt(input, "payload.geometryProof.findings")),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewReceipt.receiptVersion"),
          "canonical-blueprint-review-receipt.v1",
        ),
        sfxEquals(sfxValueAt(input, "payload.reviewReceipt.disposition"), "APPROVE"),
        sfxEquals(
          sfxValueAt(input, "payload.reviewReceipt.capabilityAuthorityDigest"),
          sfxValueAt(input, "payload.featureDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewReceipt.blueprintAuthorityDigest"),
          sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewReceipt.carrierDigest"),
          sfxValueAt(input, "payload.candidateCarrierDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewReceipt.projectionReceiptDigest"),
          sfxValueAt(input, "payload.projectionReceiptDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.reviewReceipt.rationaleReference.digest"),
          sfxValueAt(input, "payload.reviewTestimonyDigest"),
        ),
        sfxEquals(sfxValueAt(input, "payload.reviewTestimony.disposition"), "APPROVE"),
        sfxEquals(
          sfxValueAt(input, "payload.reviewTestimony.reviewBoundaryDigest"),
          sfxValueAt(input, "payload.reviewBoundaryDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.projectionReceipt.blueprintAuthorityDigest"),
          sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
        ),
        sfxEquals(
          sfxValueAt(input, "payload.projectionReceipt.carrierDigest"),
          sfxValueAt(input, "payload.candidateCarrierDigest"),
        ),
        sfxEquals(
          JSON.stringify(canonicalize(sfxValueAt(input, "payload.projectionReceipt.sources"))),
          JSON.stringify(
            canonicalize({
              ["ascii"]: sfxValueAt(input, "payload.reviewReceipt.reviewedSources.ascii"),
              ["mermaid"]: sfxValueAt(input, "payload.reviewReceipt.reviewedSources.mermaid"),
              ["additionalViews"]: sfxValueAt(
                input,
                "payload.reviewReceipt.reviewedSources.requiredViews",
              ),
            }),
          ),
        ),
        sfxEquals(
          JSON.stringify(
            canonicalize(
              sfxValueAt(input, "payload.reviewBoundary.capabilities.0.reviewedSources"),
            ),
          ),
          JSON.stringify(canonicalize(sfxValueAt(input, "payload.reviewReceipt.reviewedSources"))),
        ),
        sfxEquals(
          JSON.stringify(
            canonicalize(sfxValueAt(input, "payload.reviewBoundary.projectionProfileDigests")),
          ),
          JSON.stringify(
            canonicalize(sfxValueAt(input, "payload.reviewReceipt.projectionProfileDigests")),
          ),
        ),
      ].every((condition) => sfxTruthy(sfxValueAt(condition, "")));
      const obligationFindings = [
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.projectionReceipt.capability.capabilityId"),
            sfxValueAt(input, "payload.capabilityId"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "PROJECTION_RECEIPT_CAPABILITY_ID_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(sfxEquals(sfxLength(sfxValueAt(input, "payload.reviewBoundary.capabilities")), 1))
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_CAPABILITY_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewBoundary.capabilities.0.capabilityId"),
            sfxValueAt(input, "payload.capabilityId"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_CAPABILITY_ID_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewBoundary.capabilities.0.capabilityAuthorityDigest"),
            sfxValueAt(input, "payload.featureDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_FEATURE_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewBoundary.capabilities.0.blueprintAuthorityDigest"),
            sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewBoundary.capabilities.0.carrierDigest"),
            sfxValueAt(input, "payload.candidateCarrierDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_CARRIER_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewBoundary.capabilities.0.projectionReceiptDigest"),
            sfxValueAt(input, "payload.projectionReceiptDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_PROJECTION_RECEIPT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewBoundary.capabilities.0.geometryProofDigest"),
            sfxValueAt(input, "payload.geometryProofDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_GEOMETRY_PROOF_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewBoundary.capabilities.0.geometryDisposition"),
            sfxValueAt(input, "payload.geometryProof.disposition"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_GEOMETRY_DISPOSITION_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewBoundary.capabilities.0.geometryFindingCount"),
            sfxLength(sfxValueAt(input, "payload.geometryProof.findings")),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_GEOMETRY_FINDING_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewReceipt.receiptVersion"),
            "canonical-blueprint-review-receipt.v1",
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_RECEIPT_CONTRACT_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(sfxEquals(sfxValueAt(input, "payload.reviewReceipt.disposition"), "APPROVE"))
          ? []
          : [
              {
                ["code"]: "REVIEW_DISPOSITION_NOT_APPROVED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewReceipt.capabilityAuthorityDigest"),
            sfxValueAt(input, "payload.featureDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_FEATURE_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewReceipt.blueprintAuthorityDigest"),
            sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewReceipt.carrierDigest"),
            sfxValueAt(input, "payload.candidateCarrierDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_CARRIER_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewReceipt.projectionReceiptDigest"),
            sfxValueAt(input, "payload.projectionReceiptDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_PROJECTION_RECEIPT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewReceipt.rationaleReference.digest"),
            sfxValueAt(input, "payload.reviewTestimonyDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_TESTIMONY_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(sfxEquals(sfxValueAt(input, "payload.reviewTestimony.disposition"), "APPROVE"))
          ? []
          : [
              {
                ["code"]: "REVIEW_TESTIMONY_NOT_APPROVED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.reviewTestimony.reviewBoundaryDigest"),
            sfxValueAt(input, "payload.reviewBoundaryDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.projectionReceipt.blueprintAuthorityDigest"),
            sfxValueAt(input, "payload.candidate.blueprintAuthority.authorityDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "PROJECTION_RECEIPT_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            sfxValueAt(input, "payload.projectionReceipt.carrierDigest"),
            sfxValueAt(input, "payload.candidateCarrierDigest"),
          ),
        )
          ? []
          : [
              {
                ["code"]: "PROJECTION_RECEIPT_CARRIER_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            JSON.stringify(canonicalize(sfxValueAt(input, "payload.projectionReceipt.sources"))),
            JSON.stringify(
              canonicalize({
                ["ascii"]: sfxValueAt(input, "payload.reviewReceipt.reviewedSources.ascii"),
                ["mermaid"]: sfxValueAt(input, "payload.reviewReceipt.reviewedSources.mermaid"),
                ["additionalViews"]: sfxValueAt(
                  input,
                  "payload.reviewReceipt.reviewedSources.requiredViews",
                ),
              }),
            ),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEWED_SOURCE_DIGESTS_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            JSON.stringify(
              canonicalize(
                sfxValueAt(input, "payload.reviewBoundary.capabilities.0.reviewedSources"),
              ),
            ),
            JSON.stringify(
              canonicalize(sfxValueAt(input, "payload.reviewReceipt.reviewedSources")),
            ),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_SOURCES_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        sfxTruthy(
          sfxEquals(
            JSON.stringify(
              canonicalize(sfxValueAt(input, "payload.reviewBoundary.projectionProfileDigests")),
            ),
            JSON.stringify(
              canonicalize(sfxValueAt(input, "payload.reviewReceipt.projectionProfileDigests")),
            ),
          ),
        )
          ? []
          : [
              {
                ["code"]: "REVIEW_PROFILE_DIGESTS_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
      ].flatMap((findingGroup, findingGroupIndex) => sfxValueAt(findingGroup, ""));
      return sfxMerge(sfxValueAt(input, ""), {
        ["payload"]: sfxMerge(sfxValueAt(input, "payload"), {
          ["require-current-approved-review-receiptDisposition"]: {
            ["disposition"]: sfxTruthy(sfxValueAt(checksClosed, "")) ? "MET" : "UNMET",
            ["blueprintCellId"]: "require-current-approved-review-receipt",
            ["findings"]: sfxValueAt(obligationFindings, ""),
          },
        }),
      });
    })();
  }
}
