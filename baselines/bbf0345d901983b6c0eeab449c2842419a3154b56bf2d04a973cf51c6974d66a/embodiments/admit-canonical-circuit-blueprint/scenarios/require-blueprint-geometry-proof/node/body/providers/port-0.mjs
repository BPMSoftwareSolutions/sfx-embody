// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class RequireBlueprintGeometryProofPort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.proofType" }, "/bindings/checksClosed/from/items/0/left", observe);
        const expression1 = new Expression(mechanics["literal"], { ["value"]: "canonical-blueprint-geometry-proof.v1" }, "/bindings/checksClosed/from/items/0/right", observe);
        const expression2 = new Expression(mechanics["equals"], { ["left"]: expression0, ["right"]: expression1 }, "/bindings/checksClosed/from/items/0", observe);
        const expression3 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.blueprintDigest" }, "/bindings/checksClosed/from/items/1/left", observe);
        const expression4 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/checksClosed/from/items/1/right", observe);
        const expression5 = new Expression(mechanics["equals"], { ["left"]: expression3, ["right"]: expression4 }, "/bindings/checksClosed/from/items/1", observe);
        const expression6 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.disposition" }, "/bindings/checksClosed/from/items/2/left", observe);
        const expression7 = new Expression(mechanics["literal"], { ["value"]: "CONFORMS" }, "/bindings/checksClosed/from/items/2/right", observe);
        const expression8 = new Expression(mechanics["equals"], { ["left"]: expression6, ["right"]: expression7 }, "/bindings/checksClosed/from/items/2", observe);
        const expression9 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.summary.nodeCount" }, "/bindings/checksClosed/from/items/3/left", observe);
        const expression10 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.nodes" }, "/bindings/checksClosed/from/items/3/right/value", observe);
        const expression11 = new Expression(mechanics["length"], { ["value"]: expression10 }, "/bindings/checksClosed/from/items/3/right", observe);
        const expression12 = new Expression(mechanics["equals"], { ["left"]: expression9, ["right"]: expression11 }, "/bindings/checksClosed/from/items/3", observe);
        const expression13 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.summary.edgeCount" }, "/bindings/checksClosed/from/items/4/left", observe);
        const expression14 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.edges" }, "/bindings/checksClosed/from/items/4/right/value", observe);
        const expression15 = new Expression(mechanics["length"], { ["value"]: expression14 }, "/bindings/checksClosed/from/items/4/right", observe);
        const expression16 = new Expression(mechanics["equals"], { ["left"]: expression13, ["right"]: expression15 }, "/bindings/checksClosed/from/items/4", observe);
        const expression17 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.summary.featureScenarioCount" }, "/bindings/checksClosed/from/items/5/left", observe);
        const expression18 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.featureScenarioCount" }, "/bindings/checksClosed/from/items/5/right", observe);
        const expression19 = new Expression(mechanics["equals"], { ["left"]: expression17, ["right"]: expression18 }, "/bindings/checksClosed/from/items/5", observe);
        const expression20 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.summary.findingCount" }, "/bindings/checksClosed/from/items/6/left", observe);
        const expression21 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.findings" }, "/bindings/checksClosed/from/items/6/right/value", observe);
        const expression22 = new Expression(mechanics["length"], { ["value"]: expression21 }, "/bindings/checksClosed/from/items/6/right", observe);
        const expression23 = new Expression(mechanics["equals"], { ["left"]: expression20, ["right"]: expression22 }, "/bindings/checksClosed/from/items/6", observe);
        const expression24 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.findings" }, "/bindings/checksClosed/from/items/7/left/value", observe);
        const expression25 = new Expression(mechanics["length"], { ["value"]: expression24 }, "/bindings/checksClosed/from/items/7/left", observe);
        const expression26 = new Expression(mechanics["literal"], { ["value"]: 0 }, "/bindings/checksClosed/from/items/7/right", observe);
        const expression27 = new Expression(mechanics["equals"], { ["left"]: expression25, ["right"]: expression26 }, "/bindings/checksClosed/from/items/7", observe);
        const expression28 = new Expression(mechanics["array"], { ["items"]: [expression2, expression5, expression8, expression12, expression16, expression19, expression23, expression27] }, "/bindings/checksClosed/from", observe);
        const expression29 = new Expression(mechanics["path"], { ["from"]: "condition", ["path"]: "" }, "/bindings/checksClosed/where", observe);
        const expression30 = new Expression(mechanics["every"], { ["from"]: expression28, ["as"]: "condition", ["where"]: expression29 }, "/bindings/checksClosed", observe);
        const expression31 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.proofType" }, "/bindings/obligationFindings/from/items/0/when/left", observe);
        const expression32 = new Expression(mechanics["literal"], { ["value"]: "canonical-blueprint-geometry-proof.v1" }, "/bindings/obligationFindings/from/items/0/when/right", observe);
        const expression33 = new Expression(mechanics["equals"], { ["left"]: expression31, ["right"]: expression32 }, "/bindings/obligationFindings/from/items/0/when", observe);
        const expression34 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/0/then", observe);
        const expression35 = new Expression(mechanics["literal"], { ["value"]: "GEOMETRY_PROOF_CONTRACT_DIVERGED" }, "/bindings/obligationFindings/from/items/0/else/items/0/fields/code", observe);
        const expression36 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-geometry-proof" }, "/bindings/obligationFindings/from/items/0/else/items/0/fields/blueprintCellId", observe);
        const expression37 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression35,
                ["blueprintCellId"]: expression36
            } }, "/bindings/obligationFindings/from/items/0/else/items/0", observe);
        const expression38 = new Expression(mechanics["array"], { ["items"]: [expression37] }, "/bindings/obligationFindings/from/items/0/else", observe);
        const expression39 = new Expression(mechanics["if"], { ["when"]: expression33, ["then"]: expression34, ["else"]: expression38 }, "/bindings/obligationFindings/from/items/0", observe);
        const expression40 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.blueprintDigest" }, "/bindings/obligationFindings/from/items/1/when/left", observe);
        const expression41 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.blueprintAuthority.authorityDigest" }, "/bindings/obligationFindings/from/items/1/when/right", observe);
        const expression42 = new Expression(mechanics["equals"], { ["left"]: expression40, ["right"]: expression41 }, "/bindings/obligationFindings/from/items/1/when", observe);
        const expression43 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/1/then", observe);
        const expression44 = new Expression(mechanics["literal"], { ["value"]: "GEOMETRY_PROOF_BLUEPRINT_DIGEST_DIVERGED" }, "/bindings/obligationFindings/from/items/1/else/items/0/fields/code", observe);
        const expression45 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-geometry-proof" }, "/bindings/obligationFindings/from/items/1/else/items/0/fields/blueprintCellId", observe);
        const expression46 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression44,
                ["blueprintCellId"]: expression45
            } }, "/bindings/obligationFindings/from/items/1/else/items/0", observe);
        const expression47 = new Expression(mechanics["array"], { ["items"]: [expression46] }, "/bindings/obligationFindings/from/items/1/else", observe);
        const expression48 = new Expression(mechanics["if"], { ["when"]: expression42, ["then"]: expression43, ["else"]: expression47 }, "/bindings/obligationFindings/from/items/1", observe);
        const expression49 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.disposition" }, "/bindings/obligationFindings/from/items/2/when/left", observe);
        const expression50 = new Expression(mechanics["literal"], { ["value"]: "CONFORMS" }, "/bindings/obligationFindings/from/items/2/when/right", observe);
        const expression51 = new Expression(mechanics["equals"], { ["left"]: expression49, ["right"]: expression50 }, "/bindings/obligationFindings/from/items/2/when", observe);
        const expression52 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/2/then", observe);
        const expression53 = new Expression(mechanics["literal"], { ["value"]: "GEOMETRY_DISPOSITION_NOT_CONFORMING" }, "/bindings/obligationFindings/from/items/2/else/items/0/fields/code", observe);
        const expression54 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-geometry-proof" }, "/bindings/obligationFindings/from/items/2/else/items/0/fields/blueprintCellId", observe);
        const expression55 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression53,
                ["blueprintCellId"]: expression54
            } }, "/bindings/obligationFindings/from/items/2/else/items/0", observe);
        const expression56 = new Expression(mechanics["array"], { ["items"]: [expression55] }, "/bindings/obligationFindings/from/items/2/else", observe);
        const expression57 = new Expression(mechanics["if"], { ["when"]: expression51, ["then"]: expression52, ["else"]: expression56 }, "/bindings/obligationFindings/from/items/2", observe);
        const expression58 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.summary.nodeCount" }, "/bindings/obligationFindings/from/items/3/when/left", observe);
        const expression59 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.nodes" }, "/bindings/obligationFindings/from/items/3/when/right/value", observe);
        const expression60 = new Expression(mechanics["length"], { ["value"]: expression59 }, "/bindings/obligationFindings/from/items/3/when/right", observe);
        const expression61 = new Expression(mechanics["equals"], { ["left"]: expression58, ["right"]: expression60 }, "/bindings/obligationFindings/from/items/3/when", observe);
        const expression62 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/3/then", observe);
        const expression63 = new Expression(mechanics["literal"], { ["value"]: "GEOMETRY_NODE_COUNT_DIVERGED" }, "/bindings/obligationFindings/from/items/3/else/items/0/fields/code", observe);
        const expression64 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-geometry-proof" }, "/bindings/obligationFindings/from/items/3/else/items/0/fields/blueprintCellId", observe);
        const expression65 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression63,
                ["blueprintCellId"]: expression64
            } }, "/bindings/obligationFindings/from/items/3/else/items/0", observe);
        const expression66 = new Expression(mechanics["array"], { ["items"]: [expression65] }, "/bindings/obligationFindings/from/items/3/else", observe);
        const expression67 = new Expression(mechanics["if"], { ["when"]: expression61, ["then"]: expression62, ["else"]: expression66 }, "/bindings/obligationFindings/from/items/3", observe);
        const expression68 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.summary.edgeCount" }, "/bindings/obligationFindings/from/items/4/when/left", observe);
        const expression69 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.candidate.edges" }, "/bindings/obligationFindings/from/items/4/when/right/value", observe);
        const expression70 = new Expression(mechanics["length"], { ["value"]: expression69 }, "/bindings/obligationFindings/from/items/4/when/right", observe);
        const expression71 = new Expression(mechanics["equals"], { ["left"]: expression68, ["right"]: expression70 }, "/bindings/obligationFindings/from/items/4/when", observe);
        const expression72 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/4/then", observe);
        const expression73 = new Expression(mechanics["literal"], { ["value"]: "GEOMETRY_EDGE_COUNT_DIVERGED" }, "/bindings/obligationFindings/from/items/4/else/items/0/fields/code", observe);
        const expression74 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-geometry-proof" }, "/bindings/obligationFindings/from/items/4/else/items/0/fields/blueprintCellId", observe);
        const expression75 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression73,
                ["blueprintCellId"]: expression74
            } }, "/bindings/obligationFindings/from/items/4/else/items/0", observe);
        const expression76 = new Expression(mechanics["array"], { ["items"]: [expression75] }, "/bindings/obligationFindings/from/items/4/else", observe);
        const expression77 = new Expression(mechanics["if"], { ["when"]: expression71, ["then"]: expression72, ["else"]: expression76 }, "/bindings/obligationFindings/from/items/4", observe);
        const expression78 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.summary.featureScenarioCount" }, "/bindings/obligationFindings/from/items/5/when/left", observe);
        const expression79 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.featureScenarioCount" }, "/bindings/obligationFindings/from/items/5/when/right", observe);
        const expression80 = new Expression(mechanics["equals"], { ["left"]: expression78, ["right"]: expression79 }, "/bindings/obligationFindings/from/items/5/when", observe);
        const expression81 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/5/then", observe);
        const expression82 = new Expression(mechanics["literal"], { ["value"]: "GEOMETRY_FEATURE_SCENARIO_COUNT_DIVERGED" }, "/bindings/obligationFindings/from/items/5/else/items/0/fields/code", observe);
        const expression83 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-geometry-proof" }, "/bindings/obligationFindings/from/items/5/else/items/0/fields/blueprintCellId", observe);
        const expression84 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression82,
                ["blueprintCellId"]: expression83
            } }, "/bindings/obligationFindings/from/items/5/else/items/0", observe);
        const expression85 = new Expression(mechanics["array"], { ["items"]: [expression84] }, "/bindings/obligationFindings/from/items/5/else", observe);
        const expression86 = new Expression(mechanics["if"], { ["when"]: expression80, ["then"]: expression81, ["else"]: expression85 }, "/bindings/obligationFindings/from/items/5", observe);
        const expression87 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.summary.findingCount" }, "/bindings/obligationFindings/from/items/6/when/left", observe);
        const expression88 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.findings" }, "/bindings/obligationFindings/from/items/6/when/right/value", observe);
        const expression89 = new Expression(mechanics["length"], { ["value"]: expression88 }, "/bindings/obligationFindings/from/items/6/when/right", observe);
        const expression90 = new Expression(mechanics["equals"], { ["left"]: expression87, ["right"]: expression89 }, "/bindings/obligationFindings/from/items/6/when", observe);
        const expression91 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/6/then", observe);
        const expression92 = new Expression(mechanics["literal"], { ["value"]: "GEOMETRY_FINDING_COUNT_DIVERGED" }, "/bindings/obligationFindings/from/items/6/else/items/0/fields/code", observe);
        const expression93 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-geometry-proof" }, "/bindings/obligationFindings/from/items/6/else/items/0/fields/blueprintCellId", observe);
        const expression94 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression92,
                ["blueprintCellId"]: expression93
            } }, "/bindings/obligationFindings/from/items/6/else/items/0", observe);
        const expression95 = new Expression(mechanics["array"], { ["items"]: [expression94] }, "/bindings/obligationFindings/from/items/6/else", observe);
        const expression96 = new Expression(mechanics["if"], { ["when"]: expression90, ["then"]: expression91, ["else"]: expression95 }, "/bindings/obligationFindings/from/items/6", observe);
        const expression97 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload.geometryProof.findings" }, "/bindings/obligationFindings/from/items/7/when/left/value", observe);
        const expression98 = new Expression(mechanics["length"], { ["value"]: expression97 }, "/bindings/obligationFindings/from/items/7/when/left", observe);
        const expression99 = new Expression(mechanics["literal"], { ["value"]: 0 }, "/bindings/obligationFindings/from/items/7/when/right", observe);
        const expression100 = new Expression(mechanics["equals"], { ["left"]: expression98, ["right"]: expression99 }, "/bindings/obligationFindings/from/items/7/when", observe);
        const expression101 = new Expression(mechanics["array"], { ["items"]: [] }, "/bindings/obligationFindings/from/items/7/then", observe);
        const expression102 = new Expression(mechanics["literal"], { ["value"]: "GEOMETRY_PROOF_HAS_FINDINGS" }, "/bindings/obligationFindings/from/items/7/else/items/0/fields/code", observe);
        const expression103 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-geometry-proof" }, "/bindings/obligationFindings/from/items/7/else/items/0/fields/blueprintCellId", observe);
        const expression104 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression102,
                ["blueprintCellId"]: expression103
            } }, "/bindings/obligationFindings/from/items/7/else/items/0", observe);
        const expression105 = new Expression(mechanics["array"], { ["items"]: [expression104] }, "/bindings/obligationFindings/from/items/7/else", observe);
        const expression106 = new Expression(mechanics["if"], { ["when"]: expression100, ["then"]: expression101, ["else"]: expression105 }, "/bindings/obligationFindings/from/items/7", observe);
        const expression107 = new Expression(mechanics["array"], { ["items"]: [expression39, expression48, expression57, expression67, expression77, expression86, expression96, expression106] }, "/bindings/obligationFindings/from", observe);
        const expression108 = new Expression(mechanics["path"], { ["from"]: "findingGroup", ["path"]: "" }, "/bindings/obligationFindings/value", observe);
        const expression109 = new Expression(mechanics["flat-map"], { ["from"]: expression107, ["as"]: "findingGroup", ["value"]: expression108 }, "/bindings/obligationFindings", observe);
        const expression110 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "" }, "/value/values/0", observe);
        const expression111 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "payload" }, "/value/values/1/fields/payload/values/0", observe);
        const expression112 = new Expression(mechanics["path"], { ["from"]: "checksClosed", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-geometry-proofDisposition/fields/disposition/when", observe);
        const expression113 = new Expression(mechanics["literal"], { ["value"]: "MET" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-geometry-proofDisposition/fields/disposition/then", observe);
        const expression114 = new Expression(mechanics["literal"], { ["value"]: "UNMET" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-geometry-proofDisposition/fields/disposition/else", observe);
        const expression115 = new Expression(mechanics["if"], { ["when"]: expression112, ["then"]: expression113, ["else"]: expression114 }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-geometry-proofDisposition/fields/disposition", observe);
        const expression116 = new Expression(mechanics["literal"], { ["value"]: "require-blueprint-geometry-proof" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-geometry-proofDisposition/fields/blueprintCellId", observe);
        const expression117 = new Expression(mechanics["path"], { ["from"]: "obligationFindings", ["path"]: "" }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-geometry-proofDisposition/fields/findings", observe);
        const expression118 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression115,
                ["blueprintCellId"]: expression116,
                ["findings"]: expression117
            } }, "/value/values/1/fields/payload/values/1/fields/require-blueprint-geometry-proofDisposition", observe);
        const expression119 = new Expression(mechanics["object"], { ["fields"]: {
                ["require-blueprint-geometry-proofDisposition"]: expression118
            } }, "/value/values/1/fields/payload/values/1", observe);
        const expression120 = new Expression(mechanics["merge"], { ["values"]: [expression111, expression119] }, "/value/values/1/fields/payload", observe);
        const expression121 = new Expression(mechanics["object"], { ["fields"]: {
                ["payload"]: expression120
            } }, "/value/values/1", observe);
        const expression122 = new Expression(mechanics["merge"], { ["values"]: [expression110, expression121] }, "/value", observe);
        const expression123 = new Expression(mechanics["let"], { ["bindings"]: {
                ["checksClosed"]: expression30,
                ["obligationFindings"]: expression109
            }, ["value"]: expression122 }, "", observe);
        this.expression = expression123;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
