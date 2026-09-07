// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class EmitImmutableBlueprintAuthorityPort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.require-blueprint-conformance-evidenceDisposition" }, "/bindings/conformance", observe);
        const expression1 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.require-blueprint-geometry-proofDisposition" }, "/bindings/geometry", observe);
        const expression2 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.require-current-approved-review-receiptDisposition" }, "/bindings/review", observe);
        const expression3 = new Expression(mechanics["path"], { ["from"]: "conformance", ["path"]: "findings" }, "/bindings/allFindings/from/items/0", observe);
        const expression4 = new Expression(mechanics["path"], { ["from"]: "geometry", ["path"]: "findings" }, "/bindings/allFindings/from/items/1", observe);
        const expression5 = new Expression(mechanics["path"], { ["from"]: "review", ["path"]: "findings" }, "/bindings/allFindings/from/items/2", observe);
        const expression6 = new Expression(mechanics["array"], { ["items"]: [expression3, expression4, expression5] }, "/bindings/allFindings/from", observe);
        const expression7 = new Expression(mechanics["path"], { ["from"]: "findingGroup", ["path"]: "" }, "/bindings/allFindings/value", observe);
        const expression8 = new Expression(mechanics["flat-map"], { ["from"]: expression6, ["as"]: "findingGroup", ["value"]: expression7 }, "/bindings/allFindings", observe);
        const expression9 = new Expression(mechanics["path"], { ["from"]: "conformance", ["path"]: "disposition" }, "/bindings/closed/from/items/0/left", observe);
        const expression10 = new Expression(mechanics["literal"], { ["value"]: "MET" }, "/bindings/closed/from/items/0/right", observe);
        const expression11 = new Expression(mechanics["equals"], { ["left"]: expression9, ["right"]: expression10 }, "/bindings/closed/from/items/0", observe);
        const expression12 = new Expression(mechanics["path"], { ["from"]: "geometry", ["path"]: "disposition" }, "/bindings/closed/from/items/1/left", observe);
        const expression13 = new Expression(mechanics["literal"], { ["value"]: "MET" }, "/bindings/closed/from/items/1/right", observe);
        const expression14 = new Expression(mechanics["equals"], { ["left"]: expression12, ["right"]: expression13 }, "/bindings/closed/from/items/1", observe);
        const expression15 = new Expression(mechanics["path"], { ["from"]: "review", ["path"]: "disposition" }, "/bindings/closed/from/items/2/left", observe);
        const expression16 = new Expression(mechanics["literal"], { ["value"]: "MET" }, "/bindings/closed/from/items/2/right", observe);
        const expression17 = new Expression(mechanics["equals"], { ["left"]: expression15, ["right"]: expression16 }, "/bindings/closed/from/items/2", observe);
        const expression18 = new Expression(mechanics["array"], { ["items"]: [expression11, expression14, expression17] }, "/bindings/closed/from", observe);
        const expression19 = new Expression(mechanics["path"], { ["from"]: "condition", ["path"]: "" }, "/bindings/closed/where", observe);
        const expression20 = new Expression(mechanics["every"], { ["from"]: expression18, ["as"]: "condition", ["where"]: expression19 }, "/bindings/closed", observe);
        const expression21 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.sourceAuthority.lineage" }, "/bindings/admittedLineage/from/items/0", observe);
        const expression22 = new Expression(mechanics["literal"], { ["value"]: "canonical-blueprint-conformance-evidence.v1" }, "/bindings/admittedLineage/from/items/1/items/0/fields/authorityId", observe);
        const expression23 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidenceDigest" }, "/bindings/admittedLineage/from/items/1/items/0/fields/digest", observe);
        const expression24 = new Expression(mechanics["object"], { ["fields"]: {
                ["authorityId"]: expression22,
                ["digest"]: expression23
            } }, "/bindings/admittedLineage/from/items/1/items/0", observe);
        const expression25 = new Expression(mechanics["literal"], { ["value"]: "canonical-blueprint-geometry-proof.v1" }, "/bindings/admittedLineage/from/items/1/items/1/fields/authorityId", observe);
        const expression26 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProofDigest" }, "/bindings/admittedLineage/from/items/1/items/1/fields/digest", observe);
        const expression27 = new Expression(mechanics["object"], { ["fields"]: {
                ["authorityId"]: expression25,
                ["digest"]: expression26
            } }, "/bindings/admittedLineage/from/items/1/items/1", observe);
        const expression28 = new Expression(mechanics["literal"], { ["value"]: "canonical-blueprint-review-receipt.v1" }, "/bindings/admittedLineage/from/items/1/items/2/fields/authorityId", observe);
        const expression29 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceiptDigest" }, "/bindings/admittedLineage/from/items/1/items/2/fields/digest", observe);
        const expression30 = new Expression(mechanics["object"], { ["fields"]: {
                ["authorityId"]: expression28,
                ["digest"]: expression29
            } }, "/bindings/admittedLineage/from/items/1/items/2", observe);
        const expression31 = new Expression(mechanics["array"], { ["items"]: [expression24, expression27, expression30] }, "/bindings/admittedLineage/from/items/1", observe);
        const expression32 = new Expression(mechanics["array"], { ["items"]: [expression21, expression31] }, "/bindings/admittedLineage/from", observe);
        const expression33 = new Expression(mechanics["path"], { ["from"]: "lineageGroup", ["path"]: "" }, "/bindings/admittedLineage/value", observe);
        const expression34 = new Expression(mechanics["flat-map"], { ["from"]: expression32, ["as"]: "lineageGroup", ["value"]: expression33 }, "/bindings/admittedLineage", observe);
        const expression35 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate" }, "/bindings/admittedBlueprint/values/0", observe);
        const expression36 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.capability" }, "/bindings/admittedBlueprint/values/1/fields/capability/values/0", observe);
        const expression37 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.featureDigest" }, "/bindings/admittedBlueprint/values/1/fields/capability/values/1/fields/capabilityAuthorityDigest", observe);
        const expression38 = new Expression(mechanics["object"], { ["fields"]: {
                ["capabilityAuthorityDigest"]: expression37
            } }, "/bindings/admittedBlueprint/values/1/fields/capability/values/1", observe);
        const expression39 = new Expression(mechanics["merge"], { ["values"]: [expression36, expression38] }, "/bindings/admittedBlueprint/values/1/fields/capability", observe);
        const expression40 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.sourceAuthority" }, "/bindings/admittedBlueprint/values/1/fields/sourceAuthority/values/0", observe);
        const expression41 = new Expression(mechanics["literal"], { ["value"]: "ADMITTED" }, "/bindings/admittedBlueprint/values/1/fields/sourceAuthority/values/1/fields/disposition", observe);
        const expression42 = new Expression(mechanics["path"], { ["from"]: "admittedLineage", ["path"]: "" }, "/bindings/admittedBlueprint/values/1/fields/sourceAuthority/values/1/fields/lineage", observe);
        const expression43 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression41,
                ["lineage"]: expression42
            } }, "/bindings/admittedBlueprint/values/1/fields/sourceAuthority/values/1", observe);
        const expression44 = new Expression(mechanics["merge"], { ["values"]: [expression40, expression43] }, "/bindings/admittedBlueprint/values/1/fields/sourceAuthority", observe);
        const expression45 = new Expression(mechanics["object"], { ["fields"]: {
                ["capability"]: expression39,
                ["sourceAuthority"]: expression44
            } }, "/bindings/admittedBlueprint/values/1", observe);
        const expression46 = new Expression(mechanics["merge"], { ["values"]: [expression35, expression45] }, "/bindings/admittedBlueprint", observe);
        const expression47 = new Expression(mechanics["path"], { ["from"]: "admittedBlueprint", ["path"]: "" }, "/bindings/admittedCarrierDigest/values/hash/value/value/value", observe);
        const expression48 = new Expression(mechanics["canonicalize"], { ["value"]: expression47 }, "/bindings/admittedCarrierDigest/values/hash/value/value", observe);
        const expression49 = new Expression(mechanics["json-stringify"], { ["value"]: expression48 }, "/bindings/admittedCarrierDigest/values/hash/value", observe);
        const expression50 = new Expression(mechanics["sha256"], { ["value"]: expression49 }, "/bindings/admittedCarrierDigest/values/hash", observe);
        const expression51 = new Expression(mechanics["format"], { ["template"]: "sha256:{hash}", ["values"]: {
                ["hash"]: expression50
            } }, "/bindings/admittedCarrierDigest", observe);
        const expression52 = new Expression(mechanics["literal"], { ["value"]: "admitted-canonical-circuit-blueprint.v1" }, "/value/fields/contractId", observe);
        const expression53 = new Expression(mechanics["path"], { ["from"]: "closed", ["path"]: "" }, "/value/fields/payload/fields/disposition/when", observe);
        const expression54 = new Expression(mechanics["literal"], { ["value"]: "BLUEPRINT_AUTHORITY_ADMITTED" }, "/value/fields/payload/fields/disposition/then", observe);
        const expression55 = new Expression(mechanics["literal"], { ["value"]: "BLUEPRINT_ADMISSION_REJECTED" }, "/value/fields/payload/fields/disposition/else", observe);
        const expression56 = new Expression(mechanics["if"], { ["when"]: expression53, ["then"]: expression54, ["else"]: expression55 }, "/value/fields/payload/fields/disposition", observe);
        const expression57 = new Expression(mechanics["path"], { ["from"]: "closed", ["path"]: "" }, "/value/fields/payload/fields/blueprint/when", observe);
        const expression58 = new Expression(mechanics["path"], { ["from"]: "admittedBlueprint", ["path"]: "" }, "/value/fields/payload/fields/blueprint/then", observe);
        const expression59 = new Expression(mechanics["literal"], { ["value"]: null }, "/value/fields/payload/fields/blueprint/else", observe);
        const expression60 = new Expression(mechanics["if"], { ["when"]: expression57, ["then"]: expression58, ["else"]: expression59 }, "/value/fields/payload/fields/blueprint", observe);
        const expression61 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/value/fields/payload/fields/blueprintAuthorityDigest", observe);
        const expression62 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateCarrierDigest" }, "/value/fields/payload/fields/candidateCarrierDigest", observe);
        const expression63 = new Expression(mechanics["path"], { ["from"]: "closed", ["path"]: "" }, "/value/fields/payload/fields/admittedCarrierDigest/when", observe);
        const expression64 = new Expression(mechanics["path"], { ["from"]: "admittedCarrierDigest", ["path"]: "" }, "/value/fields/payload/fields/admittedCarrierDigest/then", observe);
        const expression65 = new Expression(mechanics["literal"], { ["value"]: null }, "/value/fields/payload/fields/admittedCarrierDigest/else", observe);
        const expression66 = new Expression(mechanics["if"], { ["when"]: expression63, ["then"]: expression64, ["else"]: expression65 }, "/value/fields/payload/fields/admittedCarrierDigest", observe);
        const expression67 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidenceDigest" }, "/value/fields/payload/fields/admissionEvidence/fields/conformanceEvidenceDigest", observe);
        const expression68 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProofDigest" }, "/value/fields/payload/fields/admissionEvidence/fields/geometryProofDigest", observe);
        const expression69 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceiptDigest" }, "/value/fields/payload/fields/admissionEvidence/fields/reviewReceiptDigest", observe);
        const expression70 = new Expression(mechanics["object"], { ["fields"]: {
                ["conformanceEvidenceDigest"]: expression67,
                ["geometryProofDigest"]: expression68,
                ["reviewReceiptDigest"]: expression69
            } }, "/value/fields/payload/fields/admissionEvidence", observe);
        const expression71 = new Expression(mechanics["path"], { ["from"]: "conformance", ["path"]: "" }, "/value/fields/payload/fields/obligationRecord/fields/conformance", observe);
        const expression72 = new Expression(mechanics["path"], { ["from"]: "geometry", ["path"]: "" }, "/value/fields/payload/fields/obligationRecord/fields/geometry", observe);
        const expression73 = new Expression(mechanics["path"], { ["from"]: "review", ["path"]: "" }, "/value/fields/payload/fields/obligationRecord/fields/review", observe);
        const expression74 = new Expression(mechanics["object"], { ["fields"]: {
                ["conformance"]: expression71,
                ["geometry"]: expression72,
                ["review"]: expression73
            } }, "/value/fields/payload/fields/obligationRecord", observe);
        const expression75 = new Expression(mechanics["path"], { ["from"]: "allFindings", ["path"]: "" }, "/value/fields/payload/fields/findings", observe);
        const expression76 = new Expression(mechanics["literal"], { ["value"]: "CLOSED" }, "/value/fields/payload/fields/blueprintRouteDisposition", observe);
        const expression77 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression56,
                ["blueprint"]: expression60,
                ["blueprintAuthorityDigest"]: expression61,
                ["candidateCarrierDigest"]: expression62,
                ["admittedCarrierDigest"]: expression66,
                ["admissionEvidence"]: expression70,
                ["obligationRecord"]: expression74,
                ["findings"]: expression75,
                ["blueprintRouteDisposition"]: expression76
            } }, "/value/fields/payload", observe);
        const expression78 = new Expression(mechanics["object"], { ["fields"]: {
                ["contractId"]: expression52,
                ["payload"]: expression77
            } }, "/value", observe);
        const expression79 = new Expression(mechanics["let"], { ["bindings"]: {
                ["conformance"]: expression0,
                ["geometry"]: expression1,
                ["review"]: expression2,
                ["allFindings"]: expression8,
                ["closed"]: expression20,
                ["admittedLineage"]: expression34,
                ["admittedBlueprint"]: expression46,
                ["admittedCarrierDigest"]: expression51
            }, ["value"]: expression78 }, "", observe);
        this.expression = expression79;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
