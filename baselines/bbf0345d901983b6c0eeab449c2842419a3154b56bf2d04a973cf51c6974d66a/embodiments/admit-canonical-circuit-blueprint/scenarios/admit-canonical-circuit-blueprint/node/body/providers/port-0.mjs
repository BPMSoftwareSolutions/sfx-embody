// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class AdmitCanonicalCircuitBlueprintPort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateBytesBase64" }, "/bindings/candidateText/value", observe);
        const expression1 = new Expression(mechanics["base64-decode-utf8"], { ["value"]: expression0 }, "/bindings/candidateText", observe);
        const expression2 = new Expression(mechanics["path"], { ["from"]: "candidateText", ["path"]: "" }, "/bindings/candidate/value", observe);
        const expression3 = new Expression(mechanics["parse-json"], { ["value"]: expression2 }, "/bindings/candidate", observe);
        const expression4 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidenceBytesBase64" }, "/bindings/conformanceEvidenceText/value", observe);
        const expression5 = new Expression(mechanics["base64-decode-utf8"], { ["value"]: expression4 }, "/bindings/conformanceEvidenceText", observe);
        const expression6 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProofBytesBase64" }, "/bindings/geometryProofText/value", observe);
        const expression7 = new Expression(mechanics["base64-decode-utf8"], { ["value"]: expression6 }, "/bindings/geometryProofText", observe);
        const expression8 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceiptBytesBase64" }, "/bindings/reviewReceiptText/value", observe);
        const expression9 = new Expression(mechanics["base64-decode-utf8"], { ["value"]: expression8 }, "/bindings/reviewReceiptText", observe);
        const expression10 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundaryBytesBase64" }, "/bindings/reviewBoundaryText/value", observe);
        const expression11 = new Expression(mechanics["base64-decode-utf8"], { ["value"]: expression10 }, "/bindings/reviewBoundaryText", observe);
        const expression12 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceiptBytesBase64" }, "/bindings/projectionReceiptText/value", observe);
        const expression13 = new Expression(mechanics["base64-decode-utf8"], { ["value"]: expression12 }, "/bindings/projectionReceiptText", observe);
        const expression14 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewTestimonyBytesBase64" }, "/bindings/reviewTestimonyText/value", observe);
        const expression15 = new Expression(mechanics["base64-decode-utf8"], { ["value"]: expression14 }, "/bindings/reviewTestimonyText", observe);
        const expression16 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.canonicalSchemaBytesBase64" }, "/bindings/canonicalSchemaText/value", observe);
        const expression17 = new Expression(mechanics["base64-decode-utf8"], { ["value"]: expression16 }, "/bindings/canonicalSchemaText", observe);
        const expression18 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "" }, "/value/values/0", observe);
        const expression19 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload" }, "/value/values/1/fields/payload/values/0", observe);
        const expression20 = new Expression(mechanics["path"], { ["from"]: "candidate", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/candidate", observe);
        const expression21 = new Expression(mechanics["path"], { ["from"]: "candidateText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/candidateCarrierDigest/values/hash/value", observe);
        const expression22 = new Expression(mechanics["sha256"], { ["value"]: expression21 }, "/value/values/1/fields/payload/values/1/fields/candidateCarrierDigest/values/hash", observe);
        const expression23 = new Expression(mechanics["format"], { ["template"]: "sha256:{hash}", ["values"]: {
                ["hash"]: expression22
            } }, "/value/values/1/fields/payload/values/1/fields/candidateCarrierDigest", observe);
        const expression24 = new Expression(mechanics["path"], { ["from"]: "conformanceEvidenceText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/conformanceEvidence/value", observe);
        const expression25 = new Expression(mechanics["parse-json"], { ["value"]: expression24 }, "/value/values/1/fields/payload/values/1/fields/conformanceEvidence", observe);
        const expression26 = new Expression(mechanics["path"], { ["from"]: "conformanceEvidenceText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/conformanceEvidenceDigest/values/hash/value", observe);
        const expression27 = new Expression(mechanics["sha256"], { ["value"]: expression26 }, "/value/values/1/fields/payload/values/1/fields/conformanceEvidenceDigest/values/hash", observe);
        const expression28 = new Expression(mechanics["format"], { ["template"]: "sha256:{hash}", ["values"]: {
                ["hash"]: expression27
            } }, "/value/values/1/fields/payload/values/1/fields/conformanceEvidenceDigest", observe);
        const expression29 = new Expression(mechanics["path"], { ["from"]: "geometryProofText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/geometryProof/value", observe);
        const expression30 = new Expression(mechanics["parse-json"], { ["value"]: expression29 }, "/value/values/1/fields/payload/values/1/fields/geometryProof", observe);
        const expression31 = new Expression(mechanics["path"], { ["from"]: "geometryProofText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/geometryProofDigest/values/hash/value", observe);
        const expression32 = new Expression(mechanics["sha256"], { ["value"]: expression31 }, "/value/values/1/fields/payload/values/1/fields/geometryProofDigest/values/hash", observe);
        const expression33 = new Expression(mechanics["format"], { ["template"]: "sha256:{hash}", ["values"]: {
                ["hash"]: expression32
            } }, "/value/values/1/fields/payload/values/1/fields/geometryProofDigest", observe);
        const expression34 = new Expression(mechanics["path"], { ["from"]: "reviewReceiptText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/reviewReceipt/value", observe);
        const expression35 = new Expression(mechanics["parse-json"], { ["value"]: expression34 }, "/value/values/1/fields/payload/values/1/fields/reviewReceipt", observe);
        const expression36 = new Expression(mechanics["path"], { ["from"]: "reviewReceiptText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/reviewReceiptDigest/values/hash/value", observe);
        const expression37 = new Expression(mechanics["sha256"], { ["value"]: expression36 }, "/value/values/1/fields/payload/values/1/fields/reviewReceiptDigest/values/hash", observe);
        const expression38 = new Expression(mechanics["format"], { ["template"]: "sha256:{hash}", ["values"]: {
                ["hash"]: expression37
            } }, "/value/values/1/fields/payload/values/1/fields/reviewReceiptDigest", observe);
        const expression39 = new Expression(mechanics["path"], { ["from"]: "reviewBoundaryText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/reviewBoundary/value", observe);
        const expression40 = new Expression(mechanics["parse-json"], { ["value"]: expression39 }, "/value/values/1/fields/payload/values/1/fields/reviewBoundary", observe);
        const expression41 = new Expression(mechanics["path"], { ["from"]: "reviewBoundaryText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/reviewBoundaryDigest/values/hash/value", observe);
        const expression42 = new Expression(mechanics["sha256"], { ["value"]: expression41 }, "/value/values/1/fields/payload/values/1/fields/reviewBoundaryDigest/values/hash", observe);
        const expression43 = new Expression(mechanics["format"], { ["template"]: "sha256:{hash}", ["values"]: {
                ["hash"]: expression42
            } }, "/value/values/1/fields/payload/values/1/fields/reviewBoundaryDigest", observe);
        const expression44 = new Expression(mechanics["path"], { ["from"]: "projectionReceiptText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/projectionReceipt/value", observe);
        const expression45 = new Expression(mechanics["parse-json"], { ["value"]: expression44 }, "/value/values/1/fields/payload/values/1/fields/projectionReceipt", observe);
        const expression46 = new Expression(mechanics["path"], { ["from"]: "projectionReceiptText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/projectionReceiptDigest/values/hash/value", observe);
        const expression47 = new Expression(mechanics["sha256"], { ["value"]: expression46 }, "/value/values/1/fields/payload/values/1/fields/projectionReceiptDigest/values/hash", observe);
        const expression48 = new Expression(mechanics["format"], { ["template"]: "sha256:{hash}", ["values"]: {
                ["hash"]: expression47
            } }, "/value/values/1/fields/payload/values/1/fields/projectionReceiptDigest", observe);
        const expression49 = new Expression(mechanics["path"], { ["from"]: "reviewTestimonyText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/reviewTestimony/value", observe);
        const expression50 = new Expression(mechanics["parse-json"], { ["value"]: expression49 }, "/value/values/1/fields/payload/values/1/fields/reviewTestimony", observe);
        const expression51 = new Expression(mechanics["path"], { ["from"]: "reviewTestimonyText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/reviewTestimonyDigest/values/hash/value", observe);
        const expression52 = new Expression(mechanics["sha256"], { ["value"]: expression51 }, "/value/values/1/fields/payload/values/1/fields/reviewTestimonyDigest/values/hash", observe);
        const expression53 = new Expression(mechanics["format"], { ["template"]: "sha256:{hash}", ["values"]: {
                ["hash"]: expression52
            } }, "/value/values/1/fields/payload/values/1/fields/reviewTestimonyDigest", observe);
        const expression54 = new Expression(mechanics["path"], { ["from"]: "canonicalSchemaText", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/canonicalSchemaDigest/values/hash/value", observe);
        const expression55 = new Expression(mechanics["sha256"], { ["value"]: expression54 }, "/value/values/1/fields/payload/values/1/fields/canonicalSchemaDigest/values/hash", observe);
        const expression56 = new Expression(mechanics["format"], { ["template"]: "sha256:{hash}", ["values"]: {
                ["hash"]: expression55
            } }, "/value/values/1/fields/payload/values/1/fields/canonicalSchemaDigest", observe);
        const expression57 = new Expression(mechanics["literal"], { ["value"]: "ESTABLISHED" }, "/value/values/1/fields/payload/values/1/fields/admissionRequest/fields/disposition", observe);
        const expression58 = new Expression(mechanics["literal"], { ["value"]: "admit-canonical-circuit-blueprint" }, "/value/values/1/fields/payload/values/1/fields/admissionRequest/fields/blueprintCellId", observe);
        const expression59 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression57,
                ["blueprintCellId"]: expression58
            } }, "/value/values/1/fields/payload/values/1/fields/admissionRequest", observe);
        const expression60 = new Expression(mechanics["object"], { ["fields"]: {
                ["candidate"]: expression20,
                ["candidateCarrierDigest"]: expression23,
                ["conformanceEvidence"]: expression25,
                ["conformanceEvidenceDigest"]: expression28,
                ["geometryProof"]: expression30,
                ["geometryProofDigest"]: expression33,
                ["reviewReceipt"]: expression35,
                ["reviewReceiptDigest"]: expression38,
                ["reviewBoundary"]: expression40,
                ["reviewBoundaryDigest"]: expression43,
                ["projectionReceipt"]: expression45,
                ["projectionReceiptDigest"]: expression48,
                ["reviewTestimony"]: expression50,
                ["reviewTestimonyDigest"]: expression53,
                ["canonicalSchemaDigest"]: expression56,
                ["admissionRequest"]: expression59
            } }, "/value/values/1/fields/payload/values/1", observe);
        const expression61 = new Expression(mechanics["merge"], { ["values"]: [expression19, expression60] }, "/value/values/1/fields/payload", observe);
        const expression62 = new Expression(mechanics["object"], { ["fields"]: {
                ["payload"]: expression61
            } }, "/value/values/1", observe);
        const expression63 = new Expression(mechanics["merge"], { ["values"]: [expression18, expression62] }, "/value", observe);
        const expression64 = new Expression(mechanics["let"], { ["bindings"]: {
                ["candidateText"]: expression1,
                ["candidate"]: expression3,
                ["conformanceEvidenceText"]: expression5,
                ["geometryProofText"]: expression7,
                ["reviewReceiptText"]: expression9,
                ["reviewBoundaryText"]: expression11,
                ["projectionReceiptText"]: expression13,
                ["reviewTestimonyText"]: expression15,
                ["canonicalSchemaText"]: expression17
            }, ["value"]: expression63 }, "", observe);
        this.expression = expression64;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
