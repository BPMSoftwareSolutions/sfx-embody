// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { canonicalize, crypto } from "./native-mechanics.mjs";
export class EmitImmutableBlueprintAuthorityPort {
  execute(input, root = input) {
    return (() => {
      const conformance = input?.payload?.["require-blueprint-conformance-evidenceDisposition"];
      const geometry = input?.payload?.["require-blueprint-geometry-proofDisposition"];
      const review = input?.payload?.["require-current-approved-review-receiptDisposition"];
      const allFindings = [conformance?.findings, geometry?.findings, review?.findings].flatMap(
        (findingGroup, findingGroupIndex) => findingGroup,
      );
      const closed = [
        conformance?.disposition === "MET",
        geometry?.disposition === "MET",
        review?.disposition === "MET",
      ].every((condition) => Boolean(condition));
      const admittedLineage = [
        input?.payload?.candidate?.sourceAuthority?.lineage,
        [
          {
            ["authorityId"]: "canonical-blueprint-conformance-evidence.v1",
            ["digest"]: input?.payload?.conformanceEvidenceDigest,
          },
          {
            ["authorityId"]: "canonical-blueprint-geometry-proof.v1",
            ["digest"]: input?.payload?.geometryProofDigest,
          },
          {
            ["authorityId"]: "canonical-blueprint-review-receipt.v1",
            ["digest"]: input?.payload?.reviewReceiptDigest,
          },
        ],
      ].flatMap((lineageGroup, lineageGroupIndex) => lineageGroup);
      const admittedBlueprint = Object.assign({}, input?.payload?.candidate, {
        ["capability"]: Object.assign({}, input?.payload?.candidate?.capability, {
          ["capabilityAuthorityDigest"]: input?.payload?.featureDigest,
        }),
        ["sourceAuthority"]: Object.assign({}, input?.payload?.candidate?.sourceAuthority, {
          ["disposition"]: "ADMITTED",
          ["lineage"]: admittedLineage,
        }),
      });
      const admittedCarrierDigest = "sha256:{hash}".replaceAll(
        "{hash}",
        String(
          crypto
            .createHash("sha256")
            .update(String(JSON.stringify(canonicalize(admittedBlueprint))))
            .digest("hex"),
        ),
      );
      return {
        ["contractId"]: "admitted-canonical-circuit-blueprint.v1",
        ["payload"]: {
          ["disposition"]: closed ? "BLUEPRINT_AUTHORITY_ADMITTED" : "BLUEPRINT_ADMISSION_REJECTED",
          ["blueprint"]: closed ? admittedBlueprint : null,
          ["blueprintAuthorityDigest"]:
            input?.payload?.candidate?.blueprintAuthority?.authorityDigest,
          ["candidateCarrierDigest"]: input?.payload?.candidateCarrierDigest,
          ["admittedCarrierDigest"]: closed ? admittedCarrierDigest : null,
          ["admissionEvidence"]: {
            ["conformanceEvidenceDigest"]: input?.payload?.conformanceEvidenceDigest,
            ["geometryProofDigest"]: input?.payload?.geometryProofDigest,
            ["reviewReceiptDigest"]: input?.payload?.reviewReceiptDigest,
          },
          ["obligationRecord"]: {
            ["conformance"]: conformance,
            ["geometry"]: geometry,
            ["review"]: review,
          },
          ["findings"]: allFindings,
          ["blueprintRouteDisposition"]: "CLOSED",
        },
      };
    })();
  }
}
