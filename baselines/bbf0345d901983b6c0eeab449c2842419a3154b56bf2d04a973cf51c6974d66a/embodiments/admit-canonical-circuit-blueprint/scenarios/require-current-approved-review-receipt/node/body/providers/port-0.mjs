// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class RequireCurrentApprovedReviewReceiptPort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceipt.capability.capabilityId" }, "/bindings/checksClosed/from/items/0/left", observe);
        const expression1 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.capabilityId" }, "/bindings/checksClosed/from/items/0/right", observe);
        const expression2 = new Expression(mechanics["equals"], { ["left"]: expression0, ["right"]: expression1 }, "/bindings/checksClosed/from/items/0", observe);
        const expression3 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities" }, "/bindings/checksClosed/from/items/1/left/value", observe);
        const expression4 = new Expression(mechanics["length"], { ["value"]: expression3 }, "/bindings/checksClosed/from/items/1/left", observe);
        const expression5 = new Expression(mechanics["literal"], { ["value"]: 1 }, "/bindings/checksClosed/from/items/1/right", observe);
        const expression6 = new Expression(mechanics["equals"], { ["left"]: expression4, ["right"]: expression5 }, "/bindings/checksClosed/from/items/1", observe);
        const expression7 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.capabilityId" }, "/bindings/checksClosed/from/items/2/left", observe);
        const expression8 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.capabilityId" }, "/bindings/checksClosed/from/items/2/right", observe);
        const expression9 = new Expression(mechanics["equals"], { ["left"]: expression7, ["right"]: expression8 }, "/bindings/checksClosed/from/items/2", observe);
        const expression10 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.capabilityAuthorityDigest" }, "/bindings/checksClosed/from/items/3/left", observe);
        const expression11 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.featureDigest" }, "/bindings/checksClosed/from/items/3/right", observe);
        const expression12 = new Expression(mechanics["equals"], { ["left"]: expression10, ["right"]: expression11 }, "/bindings/checksClosed/from/items/3", observe);
        const expression13 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.blueprintAuthorityDigest" }, "/bindings/checksClosed/from/items/4/left", observe);
        const expression14 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/checksClosed/from/items/4/right", observe);
        const expression15 = new Expression(mechanics["equals"], { ["left"]: expression13, ["right"]: expression14 }, "/bindings/checksClosed/from/items/4", observe);
        const expression16 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.carrierDigest" }, "/bindings/checksClosed/from/items/5/left", observe);
        const expression17 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateCarrierDigest" }, "/bindings/checksClosed/from/items/5/right", observe);
        const expression18 = new Expression(mechanics["equals"], { ["left"]: expression16, ["right"]: expression17 }, "/bindings/checksClosed/from/items/5", observe);
        const expression19 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.projectionReceiptDigest" }, "/bindings/checksClosed/from/items/6/left", observe);
        const expression20 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceiptDigest" }, "/bindings/checksClosed/from/items/6/right", observe);
        const expression21 = new Expression(mechanics["equals"], { ["left"]: expression19, ["right"]: expression20 }, "/bindings/checksClosed/from/items/6", observe);
        const expression22 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.geometryProofDigest" }, "/bindings/checksClosed/from/items/7/left", observe);
        const expression23 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProofDigest" }, "/bindings/checksClosed/from/items/7/right", observe);
        const expression24 = new Expression(mechanics["equals"], { ["left"]: expression22, ["right"]: expression23 }, "/bindings/checksClosed/from/items/7", observe);
        const expression25 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.geometryDisposition" }, "/bindings/checksClosed/from/items/8/left", observe);
        const expression26 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.disposition" }, "/bindings/checksClosed/from/items/8/right", observe);
        const expression27 = new Expression(mechanics["equals"], { ["left"]: expression25, ["right"]: expression26 }, "/bindings/checksClosed/from/items/8", observe);
        const expression28 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.geometryFindingCount" }, "/bindings/checksClosed/from/items/9/left", observe);
        const expression29 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.findings" }, "/bindings/checksClosed/from/items/9/right/value", observe);
        const expression30 = new Expression(mechanics["length"], { ["value"]: expression29 }, "/bindings/checksClosed/from/items/9/right", observe);
        const expression31 = new Expression(mechanics["equals"], { ["left"]: expression28, ["right"]: expression30 }, "/bindings/checksClosed/from/items/9", observe);
        const expression32 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.receiptVersion" }, "/bindings/checksClosed/from/items/10/left", observe);
        const expression33 = new Expression(mechanics["literal"], { ["value"]: "canonical-blueprint-review-receipt.v1" }, "/bindings/checksClosed/from/items/10/right", observe);
        const expression34 = new Expression(mechanics["equals"], { ["left"]: expression32, ["right"]: expression33 }, "/bindings/checksClosed/from/items/10", observe);
        const expression35 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.disposition" }, "/bindings/checksClosed/from/items/11/left", observe);
        const expression36 = new Expression(mechanics["literal"], { ["value"]: "APPROVE" }, "/bindings/checksClosed/from/items/11/right", observe);
        const expression37 = new Expression(mechanics["equals"], { ["left"]: expression35, ["right"]: expression36 }, "/bindings/checksClosed/from/items/11", observe);
        const expression38 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.capabilityAuthorityDigest" }, "/bindings/checksClosed/from/items/12/left", observe);
        const expression39 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.featureDigest" }, "/bindings/checksClosed/from/items/12/right", observe);
        const expression40 = new Expression(mechanics["equals"], { ["left"]: expression38, ["right"]: expression39 }, "/bindings/checksClosed/from/items/12", observe);
        const expression41 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.blueprintAuthorityDigest" }, "/bindings/checksClosed/from/items/13/left", observe);
        const expression42 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/checksClosed/from/items/13/right", observe);
        const expression43 = new Expression(mechanics["equals"], { ["left"]: expression41, ["right"]: expression42 }, "/bindings/checksClosed/from/items/13", observe);
        const expression44 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.carrierDigest" }, "/bindings/checksClosed/from/items/14/left", observe);
        const expression45 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateCarrierDigest" }, "/bindings/checksClosed/from/items/14/right", observe);
        const expression46 = new Expression(mechanics["equals"], { ["left"]: expression44, ["right"]: expression45 }, "/bindings/checksClosed/from/items/14", observe);
        const expression47 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.projectionReceiptDigest" }, "/bindings/checksClosed/from/items/15/left", observe);
        const expression48 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceiptDigest" }, "/bindings/checksClosed/from/items/15/right", observe);
        const expression49 = new Expression(mechanics["equals"], { ["left"]: expression47, ["right"]: expression48 }, "/bindings/checksClosed/from/items/15", observe);
        const expression50 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.rationaleReference.digest" }, "/bindings/checksClosed/from/items/16/left", observe);
        const expression51 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewTestimonyDigest" }, "/bindings/checksClosed/from/items/16/right", observe);
        const expression52 = new Expression(mechanics["equals"], { ["left"]: expression50, ["right"]: expression51 }, "/bindings/checksClosed/from/items/16", observe);
        const expression53 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewTestimony.disposition" }, "/bindings/checksClosed/from/items/17/left", observe);
        const expression54 = new Expression(mechanics["literal"], { ["value"]: "APPROVE" }, "/bindings/checksClosed/from/items/17/right", observe);
        const expression55 = new Expression(mechanics["equals"], { ["left"]: expression53, ["right"]: expression54 }, "/bindings/checksClosed/from/items/17", observe);
        const expression56 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewTestimony.reviewBoundaryDigest" }, "/bindings/checksClosed/from/items/18/left", observe);
        const expression57 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundaryDigest" }, "/bindings/checksClosed/from/items/18/right", observe);
        const expression58 = new Expression(mechanics["equals"], { ["left"]: expression56, ["right"]: expression57 }, "/bindings/checksClosed/from/items/18", observe);
        const expression59 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceipt.blueprintAuthorityDigest" }, "/bindings/checksClosed/from/items/19/left", observe);
        const expression60 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/checksClosed/from/items/19/right", observe);
        const expression61 = new Expression(mechanics["equals"], { ["left"]: expression59, ["right"]: expression60 }, "/bindings/checksClosed/from/items/19", observe);
        const expression62 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceipt.carrierDigest" }, "/bindings/checksClosed/from/items/20/left", observe);
        const expression63 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateCarrierDigest" }, "/bindings/checksClosed/from/items/20/right", observe);
        const expression64 = new Expression(mechanics["equals"], { ["left"]: expression62, ["right"]: expression63 }, "/bindings/checksClosed/from/items/20", observe);
        const expression65 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceipt.sources" }, "/bindings/checksClosed/from/items/21/left/value/value", observe);
        const expression66 = new Expression(mechanics["canonicalize"], { ["value"]: expression65 }, "/bindings/checksClosed/from/items/21/left/value", observe);
        const expression67 = new Expression(mechanics["json-stringify"], { ["value"]: expression66 }, "/bindings/checksClosed/from/items/21/left", observe);
        const expression68 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.reviewedSources.ascii" }, "/bindings/checksClosed/from/items/21/right/value/value/fields/ascii", observe);
        const expression69 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.reviewedSources.mermaid" }, "/bindings/checksClosed/from/items/21/right/value/value/fields/mermaid", observe);
        const expression70 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.reviewedSources.requiredViews" }, "/bindings/checksClosed/from/items/21/right/value/value/fields/additionalViews", observe);
        const expression71 = new Expression(mechanics["object"], { ["fields"]: {
                ["ascii"]: expression68,
                ["mermaid"]: expression69,
                ["additionalViews"]: expression70
            } }, "/bindings/checksClosed/from/items/21/right/value/value", observe);
        const expression72 = new Expression(mechanics["canonicalize"], { ["value"]: expression71 }, "/bindings/checksClosed/from/items/21/right/value", observe);
        const expression73 = new Expression(mechanics["json-stringify"], { ["value"]: expression72 }, "/bindings/checksClosed/from/items/21/right", observe);
        const expression74 = new Expression(mechanics["equals"], { ["left"]: expression67, ["right"]: expression73 }, "/bindings/checksClosed/from/items/21", observe);
        const expression75 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.reviewedSources" }, "/bindings/checksClosed/from/items/22/left/value/value", observe);
        const expression76 = new Expression(mechanics["canonicalize"], { ["value"]: expression75 }, "/bindings/checksClosed/from/items/22/left/value", observe);
        const expression77 = new Expression(mechanics["json-stringify"], { ["value"]: expression76 }, "/bindings/checksClosed/from/items/22/left", observe);
        const expression78 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.reviewedSources" }, "/bindings/checksClosed/from/items/22/right/value/value", observe);
        const expression79 = new Expression(mechanics["canonicalize"], { ["value"]: expression78 }, "/bindings/checksClosed/from/items/22/right/value", observe);
        const expression80 = new Expression(mechanics["json-stringify"], { ["value"]: expression79 }, "/bindings/checksClosed/from/items/22/right", observe);
        const expression81 = new Expression(mechanics["equals"], { ["left"]: expression77, ["right"]: expression80 }, "/bindings/checksClosed/from/items/22", observe);
        const expression82 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.projectionProfileDigests" }, "/bindings/checksClosed/from/items/23/left/value/value", observe);
        const expression83 = new Expression(mechanics["canonicalize"], { ["value"]: expression82 }, "/bindings/checksClosed/from/items/23/left/value", observe);
        const expression84 = new Expression(mechanics["json-stringify"], { ["value"]: expression83 }, "/bindings/checksClosed/from/items/23/left", observe);
        const expression85 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.projectionProfileDigests" }, "/bindings/checksClosed/from/items/23/right/value/value", observe);
        const expression86 = new Expression(mechanics["canonicalize"], { ["value"]: expression85 }, "/bindings/checksClosed/from/items/23/right/value", observe);
        const expression87 = new Expression(mechanics["json-stringify"], { ["value"]: expression86 }, "/bindings/checksClosed/from/items/23/right", observe);
        const expression88 = new Expression(mechanics["equals"], { ["left"]: expression84, ["right"]: expression87 }, "/bindings/checksClosed/from/items/23", observe);
        const expression89 = new Expression(mechanics["array"], { ["items"]: [expression2, expression6, expression9, expression12, expression15, expression18, expression21, expression24, expression27, expression31, expression34, expression37, expression40, expression43, expression46, expression49, expression52, expression55, expression58, expression61, expression64, expression74, expression81, expression88] }, "/bindings/checksClosed/from", observe);
        const expression90 = new Expression(mechanics["path"], { ["from"]: "condition", ["path"]: "" }, "/bindings/checksClosed/where", observe);
        const expression91 = new Expression(mechanics["every"], { ["from"]: expression89, ["as"]: "condition", ["where"]: expression90 }, "/bindings/checksClosed", observe);
        const expression92 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceipt.capability.capabilityId" }, "/bindings/obligationFindings/from/items/0/when/left", observe);
        const expression93 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.capabilityId" }, "/bindings/obligationFindings/from/items/0/when/right", observe);
        const expression94 = new Expression(mechanics["equals"], { ["left"]: expression92, ["right"]: expression93 }, "/bindings/obligationFindings/from/items/0/when", observe);
        const expression95 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/0/then", observe);
        const expression96 = new Expression(mechanics["literal"], { ["value"]: "PROJECTION_RECEIPT_CAPABILITY_ID_DIVERGED" }, "/bindings/obligationFindings/from/items/0/else/items/0/fields/code", observe);
        const expression97 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/0/else/items/0/fields/blueprintCellId", observe);
        const expression98 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression96,
                ["blueprintCellId"]: expression97
            } }, "/bindings/obligationFindings/from/items/0/else/items/0", observe);
        const expression99 = new Expression(mechanics["array"], { ["items"]: [expression98] }, "/bindings/obligationFindings/from/items/0/else", observe);
        const expression100 = new Expression(mechanics["if"], { ["when"]: expression94, ["then"]: expression95, ["else"]: expression99 }, "/bindings/obligationFindings/from/items/0", observe);
        const expression101 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities" }, "/bindings/obligationFindings/from/items/1/when/left/value", observe);
        const expression102 = new Expression(mechanics["length"], { ["value"]: expression101 }, "/bindings/obligationFindings/from/items/1/when/left", observe);
        const expression103 = new Expression(mechanics["literal"], { ["value"]: 1 }, "/bindings/obligationFindings/from/items/1/when/right", observe);
        const expression104 = new Expression(mechanics["equals"], { ["left"]: expression102, ["right"]: expression103 }, "/bindings/obligationFindings/from/items/1/when", observe);
        const expression105 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/1/then", observe);
        const expression106 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_CAPABILITY_COUNT_DIVERGED" }, "/bindings/obligationFindings/from/items/1/else/items/0/fields/code", observe);
        const expression107 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/1/else/items/0/fields/blueprintCellId", observe);
        const expression108 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression106,
                ["blueprintCellId"]: expression107
            } }, "/bindings/obligationFindings/from/items/1/else/items/0", observe);
        const expression109 = new Expression(mechanics["array"], { ["items"]: [expression108] }, "/bindings/obligationFindings/from/items/1/else", observe);
        const expression110 = new Expression(mechanics["if"], { ["when"]: expression104, ["then"]: expression105, ["else"]: expression109 }, "/bindings/obligationFindings/from/items/1", observe);
        const expression111 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.capabilityId" }, "/bindings/obligationFindings/from/items/2/when/left", observe);
        const expression112 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.capabilityId" }, "/bindings/obligationFindings/from/items/2/when/right", observe);
        const expression113 = new Expression(mechanics["equals"], { ["left"]: expression111, ["right"]: expression112 }, "/bindings/obligationFindings/from/items/2/when", observe);
        const expression114 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/2/then", observe);
        const expression115 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_CAPABILITY_ID_DIVERGED" }, "/bindings/obligationFindings/from/items/2/else/items/0/fields/code", observe);
        const expression116 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/2/else/items/0/fields/blueprintCellId", observe);
        const expression117 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression115,
                ["blueprintCellId"]: expression116
            } }, "/bindings/obligationFindings/from/items/2/else/items/0", observe);
        const expression118 = new Expression(mechanics["array"], { ["items"]: [expression117] }, "/bindings/obligationFindings/from/items/2/else", observe);
        const expression119 = new Expression(mechanics["if"], { ["when"]: expression113, ["then"]: expression114, ["else"]: expression118 }, "/bindings/obligationFindings/from/items/2", observe);
        const expression120 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.capabilityAuthorityDigest" }, "/bindings/obligationFindings/from/items/3/when/left", observe);
        const expression121 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.featureDigest" }, "/bindings/obligationFindings/from/items/3/when/right", observe);
        const expression122 = new Expression(mechanics["equals"], { ["left"]: expression120, ["right"]: expression121 }, "/bindings/obligationFindings/from/items/3/when", observe);
        const expression123 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/3/then", observe);
        const expression124 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_FEATURE_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/3/else/items/0/fields/code", observe);
        const expression125 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/3/else/items/0/fields/blueprintCellId", observe);
        const expression126 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression124,
                ["blueprintCellId"]: expression125
            } }, "/bindings/obligationFindings/from/items/3/else/items/0", observe);
        const expression127 = new Expression(mechanics["array"], { ["items"]: [expression126] }, "/bindings/obligationFindings/from/items/3/else", observe);
        const expression128 = new Expression(mechanics["if"], { ["when"]: expression122, ["then"]: expression123, ["else"]: expression127 }, "/bindings/obligationFindings/from/items/3", observe);
        const expression129 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.blueprintAuthorityDigest" }, "/bindings/obligationFindings/from/items/4/when/left", observe);
        const expression130 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/obligationFindings/from/items/4/when/right", observe);
        const expression131 = new Expression(mechanics["equals"], { ["left"]: expression129, ["right"]: expression130 }, "/bindings/obligationFindings/from/items/4/when", observe);
        const expression132 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/4/then", observe);
        const expression133 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_BLUEPRINT_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/4/else/items/0/fields/code", observe);
        const expression134 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/4/else/items/0/fields/blueprintCellId", observe);
        const expression135 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression133,
                ["blueprintCellId"]: expression134
            } }, "/bindings/obligationFindings/from/items/4/else/items/0", observe);
        const expression136 = new Expression(mechanics["array"], { ["items"]: [expression135] }, "/bindings/obligationFindings/from/items/4/else", observe);
        const expression137 = new Expression(mechanics["if"], { ["when"]: expression131, ["then"]: expression132, ["else"]: expression136 }, "/bindings/obligationFindings/from/items/4", observe);
        const expression138 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.carrierDigest" }, "/bindings/obligationFindings/from/items/5/when/left", observe);
        const expression139 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateCarrierDigest" }, "/bindings/obligationFindings/from/items/5/when/right", observe);
        const expression140 = new Expression(mechanics["equals"], { ["left"]: expression138, ["right"]: expression139 }, "/bindings/obligationFindings/from/items/5/when", observe);
        const expression141 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/5/then", observe);
        const expression142 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_CARRIER_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/5/else/items/0/fields/code", observe);
        const expression143 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/5/else/items/0/fields/blueprintCellId", observe);
        const expression144 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression142,
                ["blueprintCellId"]: expression143
            } }, "/bindings/obligationFindings/from/items/5/else/items/0", observe);
        const expression145 = new Expression(mechanics["array"], { ["items"]: [expression144] }, "/bindings/obligationFindings/from/items/5/else", observe);
        const expression146 = new Expression(mechanics["if"], { ["when"]: expression140, ["then"]: expression141, ["else"]: expression145 }, "/bindings/obligationFindings/from/items/5", observe);
        const expression147 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.projectionReceiptDigest" }, "/bindings/obligationFindings/from/items/6/when/left", observe);
        const expression148 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceiptDigest" }, "/bindings/obligationFindings/from/items/6/when/right", observe);
        const expression149 = new Expression(mechanics["equals"], { ["left"]: expression147, ["right"]: expression148 }, "/bindings/obligationFindings/from/items/6/when", observe);
        const expression150 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/6/then", observe);
        const expression151 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_PROJECTION_RECEIPT_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/6/else/items/0/fields/code", observe);
        const expression152 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/6/else/items/0/fields/blueprintCellId", observe);
        const expression153 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression151,
                ["blueprintCellId"]: expression152
            } }, "/bindings/obligationFindings/from/items/6/else/items/0", observe);
        const expression154 = new Expression(mechanics["array"], { ["items"]: [expression153] }, "/bindings/obligationFindings/from/items/6/else", observe);
        const expression155 = new Expression(mechanics["if"], { ["when"]: expression149, ["then"]: expression150, ["else"]: expression154 }, "/bindings/obligationFindings/from/items/6", observe);
        const expression156 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.geometryProofDigest" }, "/bindings/obligationFindings/from/items/7/when/left", observe);
        const expression157 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProofDigest" }, "/bindings/obligationFindings/from/items/7/when/right", observe);
        const expression158 = new Expression(mechanics["equals"], { ["left"]: expression156, ["right"]: expression157 }, "/bindings/obligationFindings/from/items/7/when", observe);
        const expression159 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/7/then", observe);
        const expression160 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_GEOMETRY_PROOF_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/7/else/items/0/fields/code", observe);
        const expression161 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/7/else/items/0/fields/blueprintCellId", observe);
        const expression162 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression160,
                ["blueprintCellId"]: expression161
            } }, "/bindings/obligationFindings/from/items/7/else/items/0", observe);
        const expression163 = new Expression(mechanics["array"], { ["items"]: [expression162] }, "/bindings/obligationFindings/from/items/7/else", observe);
        const expression164 = new Expression(mechanics["if"], { ["when"]: expression158, ["then"]: expression159, ["else"]: expression163 }, "/bindings/obligationFindings/from/items/7", observe);
        const expression165 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.geometryDisposition" }, "/bindings/obligationFindings/from/items/8/when/left", observe);
        const expression166 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.disposition" }, "/bindings/obligationFindings/from/items/8/when/right", observe);
        const expression167 = new Expression(mechanics["equals"], { ["left"]: expression165, ["right"]: expression166 }, "/bindings/obligationFindings/from/items/8/when", observe);
        const expression168 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/8/then", observe);
        const expression169 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_GEOMETRY_DISPOSITION_DIVERGED" }, "/bindings/obligationFindings/from/items/8/else/items/0/fields/code", observe);
        const expression170 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/8/else/items/0/fields/blueprintCellId", observe);
        const expression171 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression169,
                ["blueprintCellId"]: expression170
            } }, "/bindings/obligationFindings/from/items/8/else/items/0", observe);
        const expression172 = new Expression(mechanics["array"], { ["items"]: [expression171] }, "/bindings/obligationFindings/from/items/8/else", observe);
        const expression173 = new Expression(mechanics["if"], { ["when"]: expression167, ["then"]: expression168, ["else"]: expression172 }, "/bindings/obligationFindings/from/items/8", observe);
        const expression174 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.geometryFindingCount" }, "/bindings/obligationFindings/from/items/9/when/left", observe);
        const expression175 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.findings" }, "/bindings/obligationFindings/from/items/9/when/right/value", observe);
        const expression176 = new Expression(mechanics["length"], { ["value"]: expression175 }, "/bindings/obligationFindings/from/items/9/when/right", observe);
        const expression177 = new Expression(mechanics["equals"], { ["left"]: expression174, ["right"]: expression176 }, "/bindings/obligationFindings/from/items/9/when", observe);
        const expression178 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/9/then", observe);
        const expression179 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_GEOMETRY_FINDING_COUNT_DIVERGED" }, "/bindings/obligationFindings/from/items/9/else/items/0/fields/code", observe);
        const expression180 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/9/else/items/0/fields/blueprintCellId", observe);
        const expression181 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression179,
                ["blueprintCellId"]: expression180
            } }, "/bindings/obligationFindings/from/items/9/else/items/0", observe);
        const expression182 = new Expression(mechanics["array"], { ["items"]: [expression181] }, "/bindings/obligationFindings/from/items/9/else", observe);
        const expression183 = new Expression(mechanics["if"], { ["when"]: expression177, ["then"]: expression178, ["else"]: expression182 }, "/bindings/obligationFindings/from/items/9", observe);
        const expression184 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.receiptVersion" }, "/bindings/obligationFindings/from/items/10/when/left", observe);
        const expression185 = new Expression(mechanics["literal"], { ["value"]: "canonical-blueprint-review-receipt.v1" }, "/bindings/obligationFindings/from/items/10/when/right", observe);
        const expression186 = new Expression(mechanics["equals"], { ["left"]: expression184, ["right"]: expression185 }, "/bindings/obligationFindings/from/items/10/when", observe);
        const expression187 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/10/then", observe);
        const expression188 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_RECEIPT_CONTRACT_DIVERGED" }, "/bindings/obligationFindings/from/items/10/else/items/0/fields/code", observe);
        const expression189 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/10/else/items/0/fields/blueprintCellId", observe);
        const expression190 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression188,
                ["blueprintCellId"]: expression189
            } }, "/bindings/obligationFindings/from/items/10/else/items/0", observe);
        const expression191 = new Expression(mechanics["array"], { ["items"]: [expression190] }, "/bindings/obligationFindings/from/items/10/else", observe);
        const expression192 = new Expression(mechanics["if"], { ["when"]: expression186, ["then"]: expression187, ["else"]: expression191 }, "/bindings/obligationFindings/from/items/10", observe);
        const expression193 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.disposition" }, "/bindings/obligationFindings/from/items/11/when/left", observe);
        const expression194 = new Expression(mechanics["literal"], { ["value"]: "APPROVE" }, "/bindings/obligationFindings/from/items/11/when/right", observe);
        const expression195 = new Expression(mechanics["equals"], { ["left"]: expression193, ["right"]: expression194 }, "/bindings/obligationFindings/from/items/11/when", observe);
        const expression196 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/11/then", observe);
        const expression197 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_DISPOSITION_NOT_APPROVED" }, "/bindings/obligationFindings/from/items/11/else/items/0/fields/code", observe);
        const expression198 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/11/else/items/0/fields/blueprintCellId", observe);
        const expression199 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression197,
                ["blueprintCellId"]: expression198
            } }, "/bindings/obligationFindings/from/items/11/else/items/0", observe);
        const expression200 = new Expression(mechanics["array"], { ["items"]: [expression199] }, "/bindings/obligationFindings/from/items/11/else", observe);
        const expression201 = new Expression(mechanics["if"], { ["when"]: expression195, ["then"]: expression196, ["else"]: expression200 }, "/bindings/obligationFindings/from/items/11", observe);
        const expression202 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.capabilityAuthorityDigest" }, "/bindings/obligationFindings/from/items/12/when/left", observe);
        const expression203 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.featureDigest" }, "/bindings/obligationFindings/from/items/12/when/right", observe);
        const expression204 = new Expression(mechanics["equals"], { ["left"]: expression202, ["right"]: expression203 }, "/bindings/obligationFindings/from/items/12/when", observe);
        const expression205 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/12/then", observe);
        const expression206 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_FEATURE_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/12/else/items/0/fields/code", observe);
        const expression207 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/12/else/items/0/fields/blueprintCellId", observe);
        const expression208 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression206,
                ["blueprintCellId"]: expression207
            } }, "/bindings/obligationFindings/from/items/12/else/items/0", observe);
        const expression209 = new Expression(mechanics["array"], { ["items"]: [expression208] }, "/bindings/obligationFindings/from/items/12/else", observe);
        const expression210 = new Expression(mechanics["if"], { ["when"]: expression204, ["then"]: expression205, ["else"]: expression209 }, "/bindings/obligationFindings/from/items/12", observe);
        const expression211 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.blueprintAuthorityDigest" }, "/bindings/obligationFindings/from/items/13/when/left", observe);
        const expression212 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/obligationFindings/from/items/13/when/right", observe);
        const expression213 = new Expression(mechanics["equals"], { ["left"]: expression211, ["right"]: expression212 }, "/bindings/obligationFindings/from/items/13/when", observe);
        const expression214 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/13/then", observe);
        const expression215 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BLUEPRINT_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/13/else/items/0/fields/code", observe);
        const expression216 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/13/else/items/0/fields/blueprintCellId", observe);
        const expression217 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression215,
                ["blueprintCellId"]: expression216
            } }, "/bindings/obligationFindings/from/items/13/else/items/0", observe);
        const expression218 = new Expression(mechanics["array"], { ["items"]: [expression217] }, "/bindings/obligationFindings/from/items/13/else", observe);
        const expression219 = new Expression(mechanics["if"], { ["when"]: expression213, ["then"]: expression214, ["else"]: expression218 }, "/bindings/obligationFindings/from/items/13", observe);
        const expression220 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.carrierDigest" }, "/bindings/obligationFindings/from/items/14/when/left", observe);
        const expression221 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateCarrierDigest" }, "/bindings/obligationFindings/from/items/14/when/right", observe);
        const expression222 = new Expression(mechanics["equals"], { ["left"]: expression220, ["right"]: expression221 }, "/bindings/obligationFindings/from/items/14/when", observe);
        const expression223 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/14/then", observe);
        const expression224 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_CARRIER_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/14/else/items/0/fields/code", observe);
        const expression225 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/14/else/items/0/fields/blueprintCellId", observe);
        const expression226 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression224,
                ["blueprintCellId"]: expression225
            } }, "/bindings/obligationFindings/from/items/14/else/items/0", observe);
        const expression227 = new Expression(mechanics["array"], { ["items"]: [expression226] }, "/bindings/obligationFindings/from/items/14/else", observe);
        const expression228 = new Expression(mechanics["if"], { ["when"]: expression222, ["then"]: expression223, ["else"]: expression227 }, "/bindings/obligationFindings/from/items/14", observe);
        const expression229 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.projectionReceiptDigest" }, "/bindings/obligationFindings/from/items/15/when/left", observe);
        const expression230 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceiptDigest" }, "/bindings/obligationFindings/from/items/15/when/right", observe);
        const expression231 = new Expression(mechanics["equals"], { ["left"]: expression229, ["right"]: expression230 }, "/bindings/obligationFindings/from/items/15/when", observe);
        const expression232 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/15/then", observe);
        const expression233 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_PROJECTION_RECEIPT_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/15/else/items/0/fields/code", observe);
        const expression234 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/15/else/items/0/fields/blueprintCellId", observe);
        const expression235 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression233,
                ["blueprintCellId"]: expression234
            } }, "/bindings/obligationFindings/from/items/15/else/items/0", observe);
        const expression236 = new Expression(mechanics["array"], { ["items"]: [expression235] }, "/bindings/obligationFindings/from/items/15/else", observe);
        const expression237 = new Expression(mechanics["if"], { ["when"]: expression231, ["then"]: expression232, ["else"]: expression236 }, "/bindings/obligationFindings/from/items/15", observe);
        const expression238 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.rationaleReference.digest" }, "/bindings/obligationFindings/from/items/16/when/left", observe);
        const expression239 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewTestimonyDigest" }, "/bindings/obligationFindings/from/items/16/when/right", observe);
        const expression240 = new Expression(mechanics["equals"], { ["left"]: expression238, ["right"]: expression239 }, "/bindings/obligationFindings/from/items/16/when", observe);
        const expression241 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/16/then", observe);
        const expression242 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_TESTIMONY_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/16/else/items/0/fields/code", observe);
        const expression243 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/16/else/items/0/fields/blueprintCellId", observe);
        const expression244 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression242,
                ["blueprintCellId"]: expression243
            } }, "/bindings/obligationFindings/from/items/16/else/items/0", observe);
        const expression245 = new Expression(mechanics["array"], { ["items"]: [expression244] }, "/bindings/obligationFindings/from/items/16/else", observe);
        const expression246 = new Expression(mechanics["if"], { ["when"]: expression240, ["then"]: expression241, ["else"]: expression245 }, "/bindings/obligationFindings/from/items/16", observe);
        const expression247 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewTestimony.disposition" }, "/bindings/obligationFindings/from/items/17/when/left", observe);
        const expression248 = new Expression(mechanics["literal"], { ["value"]: "APPROVE" }, "/bindings/obligationFindings/from/items/17/when/right", observe);
        const expression249 = new Expression(mechanics["equals"], { ["left"]: expression247, ["right"]: expression248 }, "/bindings/obligationFindings/from/items/17/when", observe);
        const expression250 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/17/then", observe);
        const expression251 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_TESTIMONY_NOT_APPROVED" }, "/bindings/obligationFindings/from/items/17/else/items/0/fields/code", observe);
        const expression252 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/17/else/items/0/fields/blueprintCellId", observe);
        const expression253 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression251,
                ["blueprintCellId"]: expression252
            } }, "/bindings/obligationFindings/from/items/17/else/items/0", observe);
        const expression254 = new Expression(mechanics["array"], { ["items"]: [expression253] }, "/bindings/obligationFindings/from/items/17/else", observe);
        const expression255 = new Expression(mechanics["if"], { ["when"]: expression249, ["then"]: expression250, ["else"]: expression254 }, "/bindings/obligationFindings/from/items/17", observe);
        const expression256 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewTestimony.reviewBoundaryDigest" }, "/bindings/obligationFindings/from/items/18/when/left", observe);
        const expression257 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundaryDigest" }, "/bindings/obligationFindings/from/items/18/when/right", observe);
        const expression258 = new Expression(mechanics["equals"], { ["left"]: expression256, ["right"]: expression257 }, "/bindings/obligationFindings/from/items/18/when", observe);
        const expression259 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/18/then", observe);
        const expression260 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/18/else/items/0/fields/code", observe);
        const expression261 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/18/else/items/0/fields/blueprintCellId", observe);
        const expression262 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression260,
                ["blueprintCellId"]: expression261
            } }, "/bindings/obligationFindings/from/items/18/else/items/0", observe);
        const expression263 = new Expression(mechanics["array"], { ["items"]: [expression262] }, "/bindings/obligationFindings/from/items/18/else", observe);
        const expression264 = new Expression(mechanics["if"], { ["when"]: expression258, ["then"]: expression259, ["else"]: expression263 }, "/bindings/obligationFindings/from/items/18", observe);
        const expression265 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceipt.blueprintAuthorityDigest" }, "/bindings/obligationFindings/from/items/19/when/left", observe);
        const expression266 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/obligationFindings/from/items/19/when/right", observe);
        const expression267 = new Expression(mechanics["equals"], { ["left"]: expression265, ["right"]: expression266 }, "/bindings/obligationFindings/from/items/19/when", observe);
        const expression268 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/19/then", observe);
        const expression269 = new Expression(mechanics["literal"], { ["value"]: "PROJECTION_RECEIPT_BLUEPRINT_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/19/else/items/0/fields/code", observe);
        const expression270 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/19/else/items/0/fields/blueprintCellId", observe);
        const expression271 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression269,
                ["blueprintCellId"]: expression270
            } }, "/bindings/obligationFindings/from/items/19/else/items/0", observe);
        const expression272 = new Expression(mechanics["array"], { ["items"]: [expression271] }, "/bindings/obligationFindings/from/items/19/else", observe);
        const expression273 = new Expression(mechanics["if"], { ["when"]: expression267, ["then"]: expression268, ["else"]: expression272 }, "/bindings/obligationFindings/from/items/19", observe);
        const expression274 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceipt.carrierDigest" }, "/bindings/obligationFindings/from/items/20/when/left", observe);
        const expression275 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateCarrierDigest" }, "/bindings/obligationFindings/from/items/20/when/right", observe);
        const expression276 = new Expression(mechanics["equals"], { ["left"]: expression274, ["right"]: expression275 }, "/bindings/obligationFindings/from/items/20/when", observe);
        const expression277 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/20/then", observe);
        const expression278 = new Expression(mechanics["literal"], { ["value"]: "PROJECTION_RECEIPT_CARRIER_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/20/else/items/0/fields/code", observe);
        const expression279 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/20/else/items/0/fields/blueprintCellId", observe);
        const expression280 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression278,
                ["blueprintCellId"]: expression279
            } }, "/bindings/obligationFindings/from/items/20/else/items/0", observe);
        const expression281 = new Expression(mechanics["array"], { ["items"]: [expression280] }, "/bindings/obligationFindings/from/items/20/else", observe);
        const expression282 = new Expression(mechanics["if"], { ["when"]: expression276, ["then"]: expression277, ["else"]: expression281 }, "/bindings/obligationFindings/from/items/20", observe);
        const expression283 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.projectionReceipt.sources" }, "/bindings/obligationFindings/from/items/21/when/left/value/value", observe);
        const expression284 = new Expression(mechanics["canonicalize"], { ["value"]: expression283 }, "/bindings/obligationFindings/from/items/21/when/left/value", observe);
        const expression285 = new Expression(mechanics["json-stringify"], { ["value"]: expression284 }, "/bindings/obligationFindings/from/items/21/when/left", observe);
        const expression286 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.reviewedSources.ascii" }, "/bindings/obligationFindings/from/items/21/when/right/value/value/fields/ascii", observe);
        const expression287 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.reviewedSources.mermaid" }, "/bindings/obligationFindings/from/items/21/when/right/value/value/fields/mermaid", observe);
        const expression288 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.reviewedSources.requiredViews" }, "/bindings/obligationFindings/from/items/21/when/right/value/value/fields/additionalViews", observe);
        const expression289 = new Expression(mechanics["object"], { ["fields"]: {
                ["ascii"]: expression286,
                ["mermaid"]: expression287,
                ["additionalViews"]: expression288
            } }, "/bindings/obligationFindings/from/items/21/when/right/value/value", observe);
        const expression290 = new Expression(mechanics["canonicalize"], { ["value"]: expression289 }, "/bindings/obligationFindings/from/items/21/when/right/value", observe);
        const expression291 = new Expression(mechanics["json-stringify"], { ["value"]: expression290 }, "/bindings/obligationFindings/from/items/21/when/right", observe);
        const expression292 = new Expression(mechanics["equals"], { ["left"]: expression285, ["right"]: expression291 }, "/bindings/obligationFindings/from/items/21/when", observe);
        const expression293 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/21/then", observe);
        const expression294 = new Expression(mechanics["literal"], { ["value"]: "REVIEWED_SOURCE_DIGESTS_DIVERGED" }, "/bindings/obligationFindings/from/items/21/else/items/0/fields/code", observe);
        const expression295 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/21/else/items/0/fields/blueprintCellId", observe);
        const expression296 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression294,
                ["blueprintCellId"]: expression295
            } }, "/bindings/obligationFindings/from/items/21/else/items/0", observe);
        const expression297 = new Expression(mechanics["array"], { ["items"]: [expression296] }, "/bindings/obligationFindings/from/items/21/else", observe);
        const expression298 = new Expression(mechanics["if"], { ["when"]: expression292, ["then"]: expression293, ["else"]: expression297 }, "/bindings/obligationFindings/from/items/21", observe);
        const expression299 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.capabilities.0.reviewedSources" }, "/bindings/obligationFindings/from/items/22/when/left/value/value", observe);
        const expression300 = new Expression(mechanics["canonicalize"], { ["value"]: expression299 }, "/bindings/obligationFindings/from/items/22/when/left/value", observe);
        const expression301 = new Expression(mechanics["json-stringify"], { ["value"]: expression300 }, "/bindings/obligationFindings/from/items/22/when/left", observe);
        const expression302 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.reviewedSources" }, "/bindings/obligationFindings/from/items/22/when/right/value/value", observe);
        const expression303 = new Expression(mechanics["canonicalize"], { ["value"]: expression302 }, "/bindings/obligationFindings/from/items/22/when/right/value", observe);
        const expression304 = new Expression(mechanics["json-stringify"], { ["value"]: expression303 }, "/bindings/obligationFindings/from/items/22/when/right", observe);
        const expression305 = new Expression(mechanics["equals"], { ["left"]: expression301, ["right"]: expression304 }, "/bindings/obligationFindings/from/items/22/when", observe);
        const expression306 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/22/then", observe);
        const expression307 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_BOUNDARY_SOURCES_DIVERGED" }, "/bindings/obligationFindings/from/items/22/else/items/0/fields/code", observe);
        const expression308 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/22/else/items/0/fields/blueprintCellId", observe);
        const expression309 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression307,
                ["blueprintCellId"]: expression308
            } }, "/bindings/obligationFindings/from/items/22/else/items/0", observe);
        const expression310 = new Expression(mechanics["array"], { ["items"]: [expression309] }, "/bindings/obligationFindings/from/items/22/else", observe);
        const expression311 = new Expression(mechanics["if"], { ["when"]: expression305, ["then"]: expression306, ["else"]: expression310 }, "/bindings/obligationFindings/from/items/22", observe);
        const expression312 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewBoundary.projectionProfileDigests" }, "/bindings/obligationFindings/from/items/23/when/left/value/value", observe);
        const expression313 = new Expression(mechanics["canonicalize"], { ["value"]: expression312 }, "/bindings/obligationFindings/from/items/23/when/left/value", observe);
        const expression314 = new Expression(mechanics["json-stringify"], { ["value"]: expression313 }, "/bindings/obligationFindings/from/items/23/when/left", observe);
        const expression315 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.reviewReceipt.projectionProfileDigests" }, "/bindings/obligationFindings/from/items/23/when/right/value/value", observe);
        const expression316 = new Expression(mechanics["canonicalize"], { ["value"]: expression315 }, "/bindings/obligationFindings/from/items/23/when/right/value", observe);
        const expression317 = new Expression(mechanics["json-stringify"], { ["value"]: expression316 }, "/bindings/obligationFindings/from/items/23/when/right", observe);
        const expression318 = new Expression(mechanics["equals"], { ["left"]: expression314, ["right"]: expression317 }, "/bindings/obligationFindings/from/items/23/when", observe);
        const expression319 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/23/then", observe);
        const expression320 = new Expression(mechanics["literal"], { ["value"]: "REVIEW_PROFILE_DIGESTS_DIVERGED" }, "/bindings/obligationFindings/from/items/23/else/items/0/fields/code", observe);
        const expression321 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/bindings/obligationFindings/from/items/23/else/items/0/fields/blueprintCellId", observe);
        const expression322 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression320,
                ["blueprintCellId"]: expression321
            } }, "/bindings/obligationFindings/from/items/23/else/items/0", observe);
        const expression323 = new Expression(mechanics["array"], { ["items"]: [expression322] }, "/bindings/obligationFindings/from/items/23/else", observe);
        const expression324 = new Expression(mechanics["if"], { ["when"]: expression318, ["then"]: expression319, ["else"]: expression323 }, "/bindings/obligationFindings/from/items/23", observe);
        const expression325 = new Expression(mechanics["array"], { ["items"]: [expression100, expression110, expression119, expression128, expression137, expression146, expression155, expression164, expression173, expression183, expression192, expression201, expression210, expression219, expression228, expression237, expression246, expression255, expression264, expression273, expression282, expression298, expression311, expression324] }, "/bindings/obligationFindings/from", observe);
        const expression326 = new Expression(mechanics["path"], { ["from"]: "findingGroup", ["path"]: "" }, "/bindings/obligationFindings/value", observe);
        const expression327 = new Expression(mechanics["flat-map"], { ["from"]: expression325, ["as"]: "findingGroup", ["value"]: expression326 }, "/bindings/obligationFindings", observe);
        const expression328 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "" }, "/value/values/0", observe);
        const expression329 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload" }, "/value/values/1/fields/payload/values/0", observe);
        const expression330 = new Expression(mechanics["path"], { ["from"]: "checksClosed", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/require-current-approved-review-receiptDisposition/fields/disposition/when", observe);
        const expression331 = new Expression(mechanics["literal"], { ["value"]: "MET" }, "/value/values/1/fields/payload/values/1/fields/require-current-approved-review-receiptDisposition/fields/disposition/then", observe);
        const expression332 = new Expression(mechanics["literal"], { ["value"]: "UNMET" }, "/value/values/1/fields/payload/values/1/fields/require-current-approved-review-receiptDisposition/fields/disposition/else", observe);
        const expression333 = new Expression(mechanics["if"], { ["when"]: expression330, ["then"]: expression331, ["else"]: expression332 }, "/value/values/1/fields/payload/values/1/fields/require-current-approved-review-receiptDisposition/fields/disposition", observe);
        const expression334 = new Expression(mechanics["literal"], { ["value"]: "require-current-approved-review-receipt" }, "/value/values/1/fields/payload/values/1/fields/require-current-approved-review-receiptDisposition/fields/blueprintCellId", observe);
        const expression335 = new Expression(mechanics["path"], { ["from"]: "obligationFindings", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/require-current-approved-review-receiptDisposition/fields/findings", observe);
        const expression336 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression333,
                ["blueprintCellId"]: expression334,
                ["findings"]: expression335
            } }, "/value/values/1/fields/payload/values/1/fields/require-current-approved-review-receiptDisposition", observe);
        const expression337 = new Expression(mechanics["object"], { ["fields"]: {
                ["require-current-approved-review-receiptDisposition"]: expression336
            } }, "/value/values/1/fields/payload/values/1", observe);
        const expression338 = new Expression(mechanics["merge"], { ["values"]: [expression329, expression337] }, "/value/values/1/fields/payload", observe);
        const expression339 = new Expression(mechanics["object"], { ["fields"]: {
                ["payload"]: expression338
            } }, "/value/values/1", observe);
        const expression340 = new Expression(mechanics["merge"], { ["values"]: [expression328, expression339] }, "/value", observe);
        const expression341 = new Expression(mechanics["let"], { ["bindings"]: {
                ["checksClosed"]: expression91,
                ["obligationFindings"]: expression327
            }, ["value"]: expression340 }, "", observe);
        this.expression = expression341;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
