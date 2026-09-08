// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { crypto, sfxFormat, sfxMerge, sfxParseJson, sfxValueAt } from "./native-mechanics.mjs";
export class AdmitCanonicalCircuitBlueprintPort {
  execute(input, root = input) {
    return (() => {
      const candidateText = Buffer.from(
        String(sfxValueAt(input, "payload.candidateBytesBase64")),
        "base64",
      ).toString("utf8");
      const candidate = sfxParseJson(sfxValueAt(candidateText, ""));
      const conformanceEvidenceText = Buffer.from(
        String(sfxValueAt(input, "payload.conformanceEvidenceBytesBase64")),
        "base64",
      ).toString("utf8");
      const geometryProofText = Buffer.from(
        String(sfxValueAt(input, "payload.geometryProofBytesBase64")),
        "base64",
      ).toString("utf8");
      const reviewReceiptText = Buffer.from(
        String(sfxValueAt(input, "payload.reviewReceiptBytesBase64")),
        "base64",
      ).toString("utf8");
      const reviewBoundaryText = Buffer.from(
        String(sfxValueAt(input, "payload.reviewBoundaryBytesBase64")),
        "base64",
      ).toString("utf8");
      const projectionReceiptText = Buffer.from(
        String(sfxValueAt(input, "payload.projectionReceiptBytesBase64")),
        "base64",
      ).toString("utf8");
      const reviewTestimonyText = Buffer.from(
        String(sfxValueAt(input, "payload.reviewTestimonyBytesBase64")),
        "base64",
      ).toString("utf8");
      const canonicalSchemaText = Buffer.from(
        String(sfxValueAt(input, "payload.canonicalSchemaBytesBase64")),
        "base64",
      ).toString("utf8");
      return sfxMerge(sfxValueAt(input, ""), {
        ["payload"]: sfxMerge(sfxValueAt(input, "payload"), {
          ["candidate"]: sfxValueAt(candidate, ""),
          ["candidateCarrierDigest"]: sfxFormat("sha256:{hash}", {
            ["hash"]: crypto
              .createHash("sha256")
              .update(String(sfxValueAt(candidateText, "")))
              .digest("hex"),
          }),
          ["conformanceEvidence"]: sfxParseJson(sfxValueAt(conformanceEvidenceText, "")),
          ["conformanceEvidenceDigest"]: sfxFormat("sha256:{hash}", {
            ["hash"]: crypto
              .createHash("sha256")
              .update(String(sfxValueAt(conformanceEvidenceText, "")))
              .digest("hex"),
          }),
          ["geometryProof"]: sfxParseJson(sfxValueAt(geometryProofText, "")),
          ["geometryProofDigest"]: sfxFormat("sha256:{hash}", {
            ["hash"]: crypto
              .createHash("sha256")
              .update(String(sfxValueAt(geometryProofText, "")))
              .digest("hex"),
          }),
          ["reviewReceipt"]: sfxParseJson(sfxValueAt(reviewReceiptText, "")),
          ["reviewReceiptDigest"]: sfxFormat("sha256:{hash}", {
            ["hash"]: crypto
              .createHash("sha256")
              .update(String(sfxValueAt(reviewReceiptText, "")))
              .digest("hex"),
          }),
          ["reviewBoundary"]: sfxParseJson(sfxValueAt(reviewBoundaryText, "")),
          ["reviewBoundaryDigest"]: sfxFormat("sha256:{hash}", {
            ["hash"]: crypto
              .createHash("sha256")
              .update(String(sfxValueAt(reviewBoundaryText, "")))
              .digest("hex"),
          }),
          ["projectionReceipt"]: sfxParseJson(sfxValueAt(projectionReceiptText, "")),
          ["projectionReceiptDigest"]: sfxFormat("sha256:{hash}", {
            ["hash"]: crypto
              .createHash("sha256")
              .update(String(sfxValueAt(projectionReceiptText, "")))
              .digest("hex"),
          }),
          ["reviewTestimony"]: sfxParseJson(sfxValueAt(reviewTestimonyText, "")),
          ["reviewTestimonyDigest"]: sfxFormat("sha256:{hash}", {
            ["hash"]: crypto
              .createHash("sha256")
              .update(String(sfxValueAt(reviewTestimonyText, "")))
              .digest("hex"),
          }),
          ["canonicalSchemaDigest"]: sfxFormat("sha256:{hash}", {
            ["hash"]: crypto
              .createHash("sha256")
              .update(String(sfxValueAt(canonicalSchemaText, "")))
              .digest("hex"),
          }),
          ["admissionRequest"]: {
            ["disposition"]: "ESTABLISHED",
            ["blueprintCellId"]: "admit-canonical-circuit-blueprint",
          },
        }),
      });
    })();
  }
}
