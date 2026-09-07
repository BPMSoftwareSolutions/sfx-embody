// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { canonicalize } from "./native-mechanics.mjs";
export class RequireCurrentApprovedReviewReceiptPort {
  execute(input, root = input) {
    return (() => {
      const checksClosed = [
        input?.payload?.projectionReceipt?.capability?.capabilityId ===
          input?.payload?.capabilityId,
        (input?.payload?.reviewBoundary?.capabilities).length === 1,
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.capabilityId ===
          input?.payload?.capabilityId,
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.capabilityAuthorityDigest ===
          input?.payload?.featureDigest,
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.blueprintAuthorityDigest ===
          input?.payload?.candidate?.blueprintAuthority?.authorityDigest,
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.carrierDigest ===
          input?.payload?.candidateCarrierDigest,
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.projectionReceiptDigest ===
          input?.payload?.projectionReceiptDigest,
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.geometryProofDigest ===
          input?.payload?.geometryProofDigest,
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.geometryDisposition ===
          input?.payload?.geometryProof?.disposition,
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.geometryFindingCount ===
          (input?.payload?.geometryProof?.findings).length,
        input?.payload?.reviewReceipt?.receiptVersion === "canonical-blueprint-review-receipt.v1",
        input?.payload?.reviewReceipt?.disposition === "APPROVE",
        input?.payload?.reviewReceipt?.capabilityAuthorityDigest === input?.payload?.featureDigest,
        input?.payload?.reviewReceipt?.blueprintAuthorityDigest ===
          input?.payload?.candidate?.blueprintAuthority?.authorityDigest,
        input?.payload?.reviewReceipt?.carrierDigest === input?.payload?.candidateCarrierDigest,
        input?.payload?.reviewReceipt?.projectionReceiptDigest ===
          input?.payload?.projectionReceiptDigest,
        input?.payload?.reviewReceipt?.rationaleReference?.digest ===
          input?.payload?.reviewTestimonyDigest,
        input?.payload?.reviewTestimony?.disposition === "APPROVE",
        input?.payload?.reviewTestimony?.reviewBoundaryDigest ===
          input?.payload?.reviewBoundaryDigest,
        input?.payload?.projectionReceipt?.blueprintAuthorityDigest ===
          input?.payload?.candidate?.blueprintAuthority?.authorityDigest,
        input?.payload?.projectionReceipt?.carrierDigest === input?.payload?.candidateCarrierDigest,
        JSON.stringify(canonicalize(input?.payload?.projectionReceipt?.sources)) ===
          JSON.stringify(
            canonicalize({
              ["ascii"]: input?.payload?.reviewReceipt?.reviewedSources?.ascii,
              ["mermaid"]: input?.payload?.reviewReceipt?.reviewedSources?.mermaid,
              ["additionalViews"]: input?.payload?.reviewReceipt?.reviewedSources?.requiredViews,
            }),
          ),
        JSON.stringify(
          canonicalize(input?.payload?.reviewBoundary?.capabilities?.["0"]?.reviewedSources),
        ) === JSON.stringify(canonicalize(input?.payload?.reviewReceipt?.reviewedSources)),
        JSON.stringify(canonicalize(input?.payload?.reviewBoundary?.projectionProfileDigests)) ===
          JSON.stringify(canonicalize(input?.payload?.reviewReceipt?.projectionProfileDigests)),
      ].every((condition) => Boolean(condition));
      const obligationFindings = [
        input?.payload?.projectionReceipt?.capability?.capabilityId === input?.payload?.capabilityId
          ? []
          : [
              {
                ["code"]: "PROJECTION_RECEIPT_CAPABILITY_ID_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        (input?.payload?.reviewBoundary?.capabilities).length === 1
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_CAPABILITY_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.capabilityId ===
        input?.payload?.capabilityId
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_CAPABILITY_ID_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.capabilityAuthorityDigest ===
        input?.payload?.featureDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_FEATURE_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.blueprintAuthorityDigest ===
        input?.payload?.candidate?.blueprintAuthority?.authorityDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.carrierDigest ===
        input?.payload?.candidateCarrierDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_CARRIER_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.projectionReceiptDigest ===
        input?.payload?.projectionReceiptDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_PROJECTION_RECEIPT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.geometryProofDigest ===
        input?.payload?.geometryProofDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_GEOMETRY_PROOF_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.geometryDisposition ===
        input?.payload?.geometryProof?.disposition
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_GEOMETRY_DISPOSITION_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewBoundary?.capabilities?.["0"]?.geometryFindingCount ===
        (input?.payload?.geometryProof?.findings).length
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_GEOMETRY_FINDING_COUNT_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewReceipt?.receiptVersion === "canonical-blueprint-review-receipt.v1"
          ? []
          : [
              {
                ["code"]: "REVIEW_RECEIPT_CONTRACT_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewReceipt?.disposition === "APPROVE"
          ? []
          : [
              {
                ["code"]: "REVIEW_DISPOSITION_NOT_APPROVED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewReceipt?.capabilityAuthorityDigest === input?.payload?.featureDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_FEATURE_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewReceipt?.blueprintAuthorityDigest ===
        input?.payload?.candidate?.blueprintAuthority?.authorityDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewReceipt?.carrierDigest === input?.payload?.candidateCarrierDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_CARRIER_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewReceipt?.projectionReceiptDigest ===
        input?.payload?.projectionReceiptDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_PROJECTION_RECEIPT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewReceipt?.rationaleReference?.digest ===
        input?.payload?.reviewTestimonyDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_TESTIMONY_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewTestimony?.disposition === "APPROVE"
          ? []
          : [
              {
                ["code"]: "REVIEW_TESTIMONY_NOT_APPROVED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.reviewTestimony?.reviewBoundaryDigest ===
        input?.payload?.reviewBoundaryDigest
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.projectionReceipt?.blueprintAuthorityDigest ===
        input?.payload?.candidate?.blueprintAuthority?.authorityDigest
          ? []
          : [
              {
                ["code"]: "PROJECTION_RECEIPT_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        input?.payload?.projectionReceipt?.carrierDigest === input?.payload?.candidateCarrierDigest
          ? []
          : [
              {
                ["code"]: "PROJECTION_RECEIPT_CARRIER_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        JSON.stringify(canonicalize(input?.payload?.projectionReceipt?.sources)) ===
        JSON.stringify(
          canonicalize({
            ["ascii"]: input?.payload?.reviewReceipt?.reviewedSources?.ascii,
            ["mermaid"]: input?.payload?.reviewReceipt?.reviewedSources?.mermaid,
            ["additionalViews"]: input?.payload?.reviewReceipt?.reviewedSources?.requiredViews,
          }),
        )
          ? []
          : [
              {
                ["code"]: "REVIEWED_SOURCE_DIGESTS_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        JSON.stringify(
          canonicalize(input?.payload?.reviewBoundary?.capabilities?.["0"]?.reviewedSources),
        ) === JSON.stringify(canonicalize(input?.payload?.reviewReceipt?.reviewedSources))
          ? []
          : [
              {
                ["code"]: "REVIEW_BOUNDARY_SOURCES_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
        JSON.stringify(canonicalize(input?.payload?.reviewBoundary?.projectionProfileDigests)) ===
        JSON.stringify(canonicalize(input?.payload?.reviewReceipt?.projectionProfileDigests))
          ? []
          : [
              {
                ["code"]: "REVIEW_PROFILE_DIGESTS_DIVERGED",
                ["blueprintCellId"]: "require-current-approved-review-receipt",
              },
            ],
      ].flatMap((findingGroup, findingGroupIndex) => findingGroup);
      return Object.assign({}, input, {
        ["payload"]: Object.assign({}, input?.payload, {
          ["require-current-approved-review-receiptDisposition"]: {
            ["disposition"]: checksClosed ? "MET" : "UNMET",
            ["blueprintCellId"]: "require-current-approved-review-receipt",
            ["findings"]: obligationFindings,
          },
        }),
      });
    })();
  }
}
