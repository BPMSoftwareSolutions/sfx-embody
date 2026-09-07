// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class RequireBlueprintConformanceEvidencePort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.capabilityId" }, "/bindings/checksClosed/from/items/0/left", observe);
        const expression1 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.capability.capabilityId" }, "/bindings/checksClosed/from/items/0/right", observe);
        const expression2 = new Expression(mechanics["equals"], { ["left"]: expression0, ["right"]: expression1 }, "/bindings/checksClosed/from/items/0", observe);
        const expression3 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.featureDigest" }, "/bindings/checksClosed/from/items/1/left", observe);
        const expression4 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.sourceAuthority.featureAuthorityRef.digest" }, "/bindings/checksClosed/from/items/1/right", observe);
        const expression5 = new Expression(mechanics["equals"], { ["left"]: expression3, ["right"]: expression4 }, "/bindings/checksClosed/from/items/1", observe);
        const expression6 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.sourceAuthority.disposition" }, "/bindings/checksClosed/from/items/2/left", observe);
        const expression7 = new Expression(mechanics["literal"], { ["value"]: "CANDIDATE" }, "/bindings/checksClosed/from/items/2/right", observe);
        const expression8 = new Expression(mechanics["equals"], { ["left"]: expression6, ["right"]: expression7 }, "/bindings/checksClosed/from/items/2", observe);
        const expression9 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.evidenceVersion" }, "/bindings/checksClosed/from/items/3/left", observe);
        const expression10 = new Expression(mechanics["literal"], { ["value"]: "canonical-blueprint-conformance-evidence.v1" }, "/bindings/checksClosed/from/items/3/right", observe);
        const expression11 = new Expression(mechanics["equals"], { ["left"]: expression9, ["right"]: expression10 }, "/bindings/checksClosed/from/items/3", observe);
        const expression12 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.blueprintAuthorityDigest" }, "/bindings/checksClosed/from/items/4/left", observe);
        const expression13 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/checksClosed/from/items/4/right", observe);
        const expression14 = new Expression(mechanics["equals"], { ["left"]: expression12, ["right"]: expression13 }, "/bindings/checksClosed/from/items/4", observe);
        const expression15 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.carrierDigest" }, "/bindings/checksClosed/from/items/5/left", observe);
        const expression16 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateCarrierDigest" }, "/bindings/checksClosed/from/items/5/right", observe);
        const expression17 = new Expression(mechanics["equals"], { ["left"]: expression15, ["right"]: expression16 }, "/bindings/checksClosed/from/items/5", observe);
        const expression18 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.schemaAuthority.digest" }, "/bindings/checksClosed/from/items/6/left", observe);
        const expression19 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.canonicalSchemaDigest" }, "/bindings/checksClosed/from/items/6/right", observe);
        const expression20 = new Expression(mechanics["equals"], { ["left"]: expression18, ["right"]: expression19 }, "/bindings/checksClosed/from/items/6", observe);
        const expression21 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.disposition" }, "/bindings/checksClosed/from/items/7/left", observe);
        const expression22 = new Expression(mechanics["literal"], { ["value"]: "CONFORMS" }, "/bindings/checksClosed/from/items/7/right", observe);
        const expression23 = new Expression(mechanics["equals"], { ["left"]: expression21, ["right"]: expression22 }, "/bindings/checksClosed/from/items/7", observe);
        const expression24 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.findings" }, "/bindings/checksClosed/from/items/8/left/value", observe);
        const expression25 = new Expression(mechanics["length"], { ["value"]: expression24 }, "/bindings/checksClosed/from/items/8/left", observe);
        const expression26 = new Expression(mechanics["literal"], { ["value"]: 0 }, "/bindings/checksClosed/from/items/8/right", observe);
        const expression27 = new Expression(mechanics["equals"], { ["left"]: expression25, ["right"]: expression26 }, "/bindings/checksClosed/from/items/8", observe);
        const expression28 = new Expression(mechanics["array"], { ["items"]: [expression2, expression5, expression8, expression11, expression14, expression17, expression20, expression23, expression27] }, "/bindings/checksClosed/from", observe);
        const expression29 = new Expression(mechanics["path"], { ["from"]: "condition", ["path"]: "" }, "/bindings/checksClosed/where", observe);
        const expression30 = new Expression(mechanics["every"], { ["from"]: expression28, ["as"]: "condition", ["where"]: expression29 }, "/bindings/checksClosed", observe);
        const expression31 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.capabilityId" }, "/bindings/obligationFindings/from/items/0/when/left", observe);
        const expression32 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.capability.capabilityId" }, "/bindings/obligationFindings/from/items/0/when/right", observe);
        const expression33 = new Expression(mechanics["equals"], { ["left"]: expression31, ["right"]: expression32 }, "/bindings/obligationFindings/from/items/0/when", observe);
        const expression34 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/0/then", observe);
        const expression35 = new Expression(mechanics["literal"], { ["value"]: "TARGET_CAPABILITY_ID_DIVERGED" }, "/bindings/obligationFindings/from/items/0/else/items/0/fields/code", observe);
        const expression36 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/bindings/obligationFindings/from/items/0/else/items/0/fields/blueprintCellId", observe);
        const expression37 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression35,
                ["blueprintCellId"]: expression36
            } }, "/bindings/obligationFindings/from/items/0/else/items/0", observe);
        const expression38 = new Expression(mechanics["array"], { ["items"]: [expression37] }, "/bindings/obligationFindings/from/items/0/else", observe);
        const expression39 = new Expression(mechanics["if"], { ["when"]: expression33, ["then"]: expression34, ["else"]: expression38 }, "/bindings/obligationFindings/from/items/0", observe);
        const expression40 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.featureDigest" }, "/bindings/obligationFindings/from/items/1/when/left", observe);
        const expression41 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.sourceAuthority.featureAuthorityRef.digest" }, "/bindings/obligationFindings/from/items/1/when/right", observe);
        const expression42 = new Expression(mechanics["equals"], { ["left"]: expression40, ["right"]: expression41 }, "/bindings/obligationFindings/from/items/1/when", observe);
        const expression43 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/1/then", observe);
        const expression44 = new Expression(mechanics["literal"], { ["value"]: "TARGET_FEATURE_AUTHORITY_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/1/else/items/0/fields/code", observe);
        const expression45 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/bindings/obligationFindings/from/items/1/else/items/0/fields/blueprintCellId", observe);
        const expression46 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression44,
                ["blueprintCellId"]: expression45
            } }, "/bindings/obligationFindings/from/items/1/else/items/0", observe);
        const expression47 = new Expression(mechanics["array"], { ["items"]: [expression46] }, "/bindings/obligationFindings/from/items/1/else", observe);
        const expression48 = new Expression(mechanics["if"], { ["when"]: expression42, ["then"]: expression43, ["else"]: expression47 }, "/bindings/obligationFindings/from/items/1", observe);
        const expression49 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.sourceAuthority.disposition" }, "/bindings/obligationFindings/from/items/2/when/left", observe);
        const expression50 = new Expression(mechanics["literal"], { ["value"]: "CANDIDATE" }, "/bindings/obligationFindings/from/items/2/when/right", observe);
        const expression51 = new Expression(mechanics["equals"], { ["left"]: expression49, ["right"]: expression50 }, "/bindings/obligationFindings/from/items/2/when", observe);
        const expression52 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/2/then", observe);
        const expression53 = new Expression(mechanics["literal"], { ["value"]: "CANDIDATE_SOURCE_DISPOSITION_NOT_CANDIDATE" }, "/bindings/obligationFindings/from/items/2/else/items/0/fields/code", observe);
        const expression54 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/bindings/obligationFindings/from/items/2/else/items/0/fields/blueprintCellId", observe);
        const expression55 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression53,
                ["blueprintCellId"]: expression54
            } }, "/bindings/obligationFindings/from/items/2/else/items/0", observe);
        const expression56 = new Expression(mechanics["array"], { ["items"]: [expression55] }, "/bindings/obligationFindings/from/items/2/else", observe);
        const expression57 = new Expression(mechanics["if"], { ["when"]: expression51, ["then"]: expression52, ["else"]: expression56 }, "/bindings/obligationFindings/from/items/2", observe);
        const expression58 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.evidenceVersion" }, "/bindings/obligationFindings/from/items/3/when/left", observe);
        const expression59 = new Expression(mechanics["literal"], { ["value"]: "canonical-blueprint-conformance-evidence.v1" }, "/bindings/obligationFindings/from/items/3/when/right", observe);
        const expression60 = new Expression(mechanics["equals"], { ["left"]: expression58, ["right"]: expression59 }, "/bindings/obligationFindings/from/items/3/when", observe);
        const expression61 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/3/then", observe);
        const expression62 = new Expression(mechanics["literal"], { ["value"]: "CONFORMANCE_EVIDENCE_CONTRACT_DIVERGED" }, "/bindings/obligationFindings/from/items/3/else/items/0/fields/code", observe);
        const expression63 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/bindings/obligationFindings/from/items/3/else/items/0/fields/blueprintCellId", observe);
        const expression64 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression62,
                ["blueprintCellId"]: expression63
            } }, "/bindings/obligationFindings/from/items/3/else/items/0", observe);
        const expression65 = new Expression(mechanics["array"], { ["items"]: [expression64] }, "/bindings/obligationFindings/from/items/3/else", observe);
        const expression66 = new Expression(mechanics["if"], { ["when"]: expression60, ["then"]: expression61, ["else"]: expression65 }, "/bindings/obligationFindings/from/items/3", observe);
        const expression67 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.blueprintAuthorityDigest" }, "/bindings/obligationFindings/from/items/4/when/left", observe);
        const expression68 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/obligationFindings/from/items/4/when/right", observe);
        const expression69 = new Expression(mechanics["equals"], { ["left"]: expression67, ["right"]: expression68 }, "/bindings/obligationFindings/from/items/4/when", observe);
        const expression70 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/4/then", observe);
        const expression71 = new Expression(mechanics["literal"], { ["value"]: "CONFORMANCE_EVIDENCE_BLUEPRINT_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/4/else/items/0/fields/code", observe);
        const expression72 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/bindings/obligationFindings/from/items/4/else/items/0/fields/blueprintCellId", observe);
        const expression73 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression71,
                ["blueprintCellId"]: expression72
            } }, "/bindings/obligationFindings/from/items/4/else/items/0", observe);
        const expression74 = new Expression(mechanics["array"], { ["items"]: [expression73] }, "/bindings/obligationFindings/from/items/4/else", observe);
        const expression75 = new Expression(mechanics["if"], { ["when"]: expression69, ["then"]: expression70, ["else"]: expression74 }, "/bindings/obligationFindings/from/items/4", observe);
        const expression76 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.carrierDigest" }, "/bindings/obligationFindings/from/items/5/when/left", observe);
        const expression77 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidateCarrierDigest" }, "/bindings/obligationFindings/from/items/5/when/right", observe);
        const expression78 = new Expression(mechanics["equals"], { ["left"]: expression76, ["right"]: expression77 }, "/bindings/obligationFindings/from/items/5/when", observe);
        const expression79 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/5/then", observe);
        const expression80 = new Expression(mechanics["literal"], { ["value"]: "CONFORMANCE_EVIDENCE_CARRIER_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/5/else/items/0/fields/code", observe);
        const expression81 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/bindings/obligationFindings/from/items/5/else/items/0/fields/blueprintCellId", observe);
        const expression82 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression80,
                ["blueprintCellId"]: expression81
            } }, "/bindings/obligationFindings/from/items/5/else/items/0", observe);
        const expression83 = new Expression(mechanics["array"], { ["items"]: [expression82] }, "/bindings/obligationFindings/from/items/5/else", observe);
        const expression84 = new Expression(mechanics["if"], { ["when"]: expression78, ["then"]: expression79, ["else"]: expression83 }, "/bindings/obligationFindings/from/items/5", observe);
        const expression85 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.schemaAuthority.digest" }, "/bindings/obligationFindings/from/items/6/when/left", observe);
        const expression86 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.canonicalSchemaDigest" }, "/bindings/obligationFindings/from/items/6/when/right", observe);
        const expression87 = new Expression(mechanics["equals"], { ["left"]: expression85, ["right"]: expression86 }, "/bindings/obligationFindings/from/items/6/when", observe);
        const expression88 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/6/then", observe);
        const expression89 = new Expression(mechanics["literal"], { ["value"]: "CONFORMANCE_SCHEMA_AUTHORITY_DIVERGED" }, "/bindings/obligationFindings/from/items/6/else/items/0/fields/code", observe);
        const expression90 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/bindings/obligationFindings/from/items/6/else/items/0/fields/blueprintCellId", observe);
        const expression91 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression89,
                ["blueprintCellId"]: expression90
            } }, "/bindings/obligationFindings/from/items/6/else/items/0", observe);
        const expression92 = new Expression(mechanics["array"], { ["items"]: [expression91] }, "/bindings/obligationFindings/from/items/6/else", observe);
        const expression93 = new Expression(mechanics["if"], { ["when"]: expression87, ["then"]: expression88, ["else"]: expression92 }, "/bindings/obligationFindings/from/items/6", observe);
        const expression94 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.disposition" }, "/bindings/obligationFindings/from/items/7/when/left", observe);
        const expression95 = new Expression(mechanics["literal"], { ["value"]: "CONFORMS" }, "/bindings/obligationFindings/from/items/7/when/right", observe);
        const expression96 = new Expression(mechanics["equals"], { ["left"]: expression94, ["right"]: expression95 }, "/bindings/obligationFindings/from/items/7/when", observe);
        const expression97 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/7/then", observe);
        const expression98 = new Expression(mechanics["literal"], { ["value"]: "CONFORMANCE_DISPOSITION_NOT_CONFORMING" }, "/bindings/obligationFindings/from/items/7/else/items/0/fields/code", observe);
        const expression99 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/bindings/obligationFindings/from/items/7/else/items/0/fields/blueprintCellId", observe);
        const expression100 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression98,
                ["blueprintCellId"]: expression99
            } }, "/bindings/obligationFindings/from/items/7/else/items/0", observe);
        const expression101 = new Expression(mechanics["array"], { ["items"]: [expression100] }, "/bindings/obligationFindings/from/items/7/else", observe);
        const expression102 = new Expression(mechanics["if"], { ["when"]: expression96, ["then"]: expression97, ["else"]: expression101 }, "/bindings/obligationFindings/from/items/7", observe);
        const expression103 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.conformanceEvidence.findings" }, "/bindings/obligationFindings/from/items/8/when/left/value", observe);
        const expression104 = new Expression(mechanics["length"], { ["value"]: expression103 }, "/bindings/obligationFindings/from/items/8/when/left", observe);
        const expression105 = new Expression(mechanics["literal"], { ["value"]: 0 }, "/bindings/obligationFindings/from/items/8/when/right", observe);
        const expression106 = new Expression(mechanics["equals"], { ["left"]: expression104, ["right"]: expression105 }, "/bindings/obligationFindings/from/items/8/when", observe);
        const expression107 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/8/then", observe);
        const expression108 = new Expression(mechanics["literal"], { ["value"]: "CONFORMANCE_EVIDENCE_HAS_FINDINGS" }, "/bindings/obligationFindings/from/items/8/else/items/0/fields/code", observe);
        const expression109 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/bindings/obligationFindings/from/items/8/else/items/0/fields/blueprintCellId", observe);
        const expression110 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression108,
                ["blueprintCellId"]: expression109
            } }, "/bindings/obligationFindings/from/items/8/else/items/0", observe);
        const expression111 = new Expression(mechanics["array"], { ["items"]: [expression110] }, "/bindings/obligationFindings/from/items/8/else", observe);
        const expression112 = new Expression(mechanics["if"], { ["when"]: expression106, ["then"]: expression107, ["else"]: expression111 }, "/bindings/obligationFindings/from/items/8", observe);
        const expression113 = new Expression(mechanics["array"], { ["items"]: [expression39, expression48, expression57, expression66, expression75, expression84, expression93, expression102, expression112] }, "/bindings/obligationFindings/from", observe);
        const expression114 = new Expression(mechanics["path"], { ["from"]: "findingGroup", ["path"]: "" }, "/bindings/obligationFindings/value", observe);
        const expression115 = new Expression(mechanics["flat-map"], { ["from"]: expression113, ["as"]: "findingGroup", ["value"]: expression114 }, "/bindings/obligationFindings", observe);
        const expression116 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "" }, "/value/values/0", observe);
        const expression117 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload" }, "/value/values/1/fields/payload/values/0", observe);
        const expression118 = new Expression(mechanics["path"], { ["from"]: "checksClosed", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-conformance-evidenceDisposition/fields/disposition/when", observe);
        const expression119 = new Expression(mechanics["literal"], { ["value"]: "MET" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-conformance-evidenceDisposition/fields/disposition/then", observe);
        const expression120 = new Expression(mechanics["literal"], { ["value"]: "UNMET" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-conformance-evidenceDisposition/fields/disposition/else", observe);
        const expression121 = new Expression(mechanics["if"], { ["when"]: expression118, ["then"]: expression119, ["else"]: expression120 }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-conformance-evidenceDisposition/fields/disposition", observe);
        const expression122 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-conformance-evidence" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-conformance-evidenceDisposition/fields/blueprintCellId", observe);
        const expression123 = new Expression(mechanics["path"], { ["from"]: "obligationFindings", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-conformance-evidenceDisposition/fields/findings", observe);
        const expression124 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression121,
                ["blueprintCellId"]: expression122,
                ["findings"]: expression123
            } }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-conformance-evidenceDisposition", observe);
        const expression125 = new Expression(mechanics["object"], { ["fields"]: {
                ["require-blueprint-conformance-evidenceDisposition"]: expression124
            } }, "/value/values/1/fields/payload/values/1", observe);
        const expression126 = new Expression(mechanics["merge"], { ["values"]: [expression117, expression125] }, "/value/values/1/fields/payload", observe);
        const expression127 = new Expression(mechanics["object"], { ["fields"]: {
                ["payload"]: expression126
            } }, "/value/values/1", observe);
        const expression128 = new Expression(mechanics["merge"], { ["values"]: [expression116, expression127] }, "/value", observe);
        const expression129 = new Expression(mechanics["let"], { ["bindings"]: {
                ["checksClosed"]: expression30,
                ["obligationFindings"]: expression115
            }, ["value"]: expression128 }, "", observe);
        this.expression = expression129;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
