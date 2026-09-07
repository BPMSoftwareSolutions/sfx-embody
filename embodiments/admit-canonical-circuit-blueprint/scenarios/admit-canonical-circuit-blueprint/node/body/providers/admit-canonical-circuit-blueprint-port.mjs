// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { crypto } from "./native-mechanics.mjs";
export class AdmitCanonicalCircuitBlueprintPort {
  execute(input, root = input) {
    return (() => {
      const candidateText = Buffer.from(
        String(input?.payload?.candidateBytesBase64),
        "base64",
      ).toString("utf8");
      const candidate = JSON.parse(candidateText);
      const conformanceEvidenceText = Buffer.from(
        String(input?.payload?.conformanceEvidenceBytesBase64),
        "base64",
      ).toString("utf8");
      const geometryProofText = Buffer.from(
        String(input?.payload?.geometryProofBytesBase64),
        "base64",
      ).toString("utf8");
      const reviewReceiptText = Buffer.from(
        String(input?.payload?.reviewReceiptBytesBase64),
        "base64",
      ).toString("utf8");
      const reviewBoundaryText = Buffer.from(
        String(input?.payload?.reviewBoundaryBytesBase64),
        "base64",
      ).toString("utf8");
      const projectionReceiptText = Buffer.from(
        String(input?.payload?.projectionReceiptBytesBase64),
        "base64",
      ).toString("utf8");
      const reviewTestimonyText = Buffer.from(
        String(input?.payload?.reviewTestimonyBytesBase64),
        "base64",
      ).toString("utf8");
      const canonicalSchemaText = Buffer.from(
        String(input?.payload?.canonicalSchemaBytesBase64),
        "base64",
      ).toString("utf8");
      return Object.assign({}, input, {
        ["payload"]: Object.assign({}, input?.payload, {
          ["candidate"]: candidate,
          ["candidateCarrierDigest"]: "sha256:{hash}".replaceAll(
            "{hash}",
            String(crypto.createHash("sha256").update(String(candidateText)).digest("hex")),
          ),
          ["conformanceEvidence"]: JSON.parse(conformanceEvidenceText),
          ["conformanceEvidenceDigest"]: "sha256:{hash}".replaceAll(
            "{hash}",
            String(
              crypto.createHash("sha256").update(String(conformanceEvidenceText)).digest("hex"),
            ),
          ),
          ["geometryProof"]: JSON.parse(geometryProofText),
          ["geometryProofDigest"]: "sha256:{hash}".replaceAll(
            "{hash}",
            String(crypto.createHash("sha256").update(String(geometryProofText)).digest("hex")),
          ),
          ["reviewReceipt"]: JSON.parse(reviewReceiptText),
          ["reviewReceiptDigest"]: "sha256:{hash}".replaceAll(
            "{hash}",
            String(crypto.createHash("sha256").update(String(reviewReceiptText)).digest("hex")),
          ),
          ["reviewBoundary"]: JSON.parse(reviewBoundaryText),
          ["reviewBoundaryDigest"]: "sha256:{hash}".replaceAll(
            "{hash}",
            String(crypto.createHash("sha256").update(String(reviewBoundaryText)).digest("hex")),
          ),
          ["projectionReceipt"]: JSON.parse(projectionReceiptText),
          ["projectionReceiptDigest"]: "sha256:{hash}".replaceAll(
            "{hash}",
            String(crypto.createHash("sha256").update(String(projectionReceiptText)).digest("hex")),
          ),
          ["reviewTestimony"]: JSON.parse(reviewTestimonyText),
          ["reviewTestimonyDigest"]: "sha256:{hash}".replaceAll(
            "{hash}",
            String(crypto.createHash("sha256").update(String(reviewTestimonyText)).digest("hex")),
          ),
          ["canonicalSchemaDigest"]: "sha256:{hash}".replaceAll(
            "{hash}",
            String(crypto.createHash("sha256").update(String(canonicalSchemaText)).digest("hex")),
          ),
          ["admissionRequest"]: {
            ["disposition"]: "ESTABLISHED",
            ["blueprintCellId"]: "admit-canonical-circuit-blueprint",
          },
        }),
      });
    })();
  }
}
