// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class AdaptJobMarketIntelligenceEvidencePort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordRef" }, "/bindings/recordBound/from/items/0/when/left", observe);
        const expression1 = new Expression(mechanics["literal"], { ["value"]: "" }, "/bindings/recordBound/from/items/0/when/right", observe);
        const expression2 = new Expression(mechanics["equals"], { ["left"]: expression0, ["right"]: expression1 }, "/bindings/recordBound/from/items/0/when", observe);
        const expression3 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/recordBound/from/items/0/then", observe);
        const expression4 = new Expression(mechanics["literal"], { ["value"]: true }, "/bindings/recordBound/from/items/0/else", observe);
        const expression5 = new Expression(mechanics["if"], { ["when"]: expression2, ["then"]: expression3, ["else"]: expression4 }, "/bindings/recordBound/from/items/0", observe);
        const expression6 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordDigest" }, "/bindings/recordBound/from/items/1/when/left", observe);
        const expression7 = new Expression(mechanics["literal"], { ["value"]: "" }, "/bindings/recordBound/from/items/1/when/right", observe);
        const expression8 = new Expression(mechanics["equals"], { ["left"]: expression6, ["right"]: expression7 }, "/bindings/recordBound/from/items/1/when", observe);
        const expression9 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/recordBound/from/items/1/then", observe);
        const expression10 = new Expression(mechanics["literal"], { ["value"]: true }, "/bindings/recordBound/from/items/1/else", observe);
        const expression11 = new Expression(mechanics["if"], { ["when"]: expression8, ["then"]: expression9, ["else"]: expression10 }, "/bindings/recordBound/from/items/1", observe);
        const expression12 = new Expression(mechanics["array"], { ["items"]: [expression5, expression11] }, "/bindings/recordBound/from", observe);
        const expression13 = new Expression(mechanics["path"], { ["from"]: "check", ["path"]: "" }, "/bindings/recordBound/where", observe);
        const expression14 = new Expression(mechanics["every"], { ["from"]: expression12, ["as"]: "check", ["where"]: expression13 }, "/bindings/recordBound", observe);
        const expression15 = new Expression(mechanics["literal"], { ["value"]: [
                "job-market-observation-scope.v1",
                "job-market-intelligence-state.v1",
                "job-market-observation-request.v1",
                "public-job-market-observation-state.v1",
                "experience-admission-scope.v1",
                "experience-gap-resolution-scope.v1",
                "market-driven-experience-acquisition-scope.v1",
                "experience-mission-planning-scope.v1"
            ] }, "/bindings/typeAdmitted/in", observe);
        const expression16 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordType" }, "/bindings/typeAdmitted/value", observe);
        const expression17 = new Expression(mechanics["includes"], { ["in"]: expression15, ["value"]: expression16 }, "/bindings/typeAdmitted", observe);
        const expression18 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "adapterAuthorityId" }, "/bindings/authorityBound/from/items/0/left", observe);
        const expression19 = new Expression(mechanics["literal"], { ["value"]: "sidefx-jmi-adapter-authority.v1" }, "/bindings/authorityBound/from/items/0/right", observe);
        const expression20 = new Expression(mechanics["equals"], { ["left"]: expression18, ["right"]: expression19 }, "/bindings/authorityBound/from/items/0", observe);
        const expression21 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "adapterAuthorityDigest" }, "/bindings/authorityBound/from/items/1/when/left", observe);
        const expression22 = new Expression(mechanics["literal"], { ["value"]: "" }, "/bindings/authorityBound/from/items/1/when/right", observe);
        const expression23 = new Expression(mechanics["equals"], { ["left"]: expression21, ["right"]: expression22 }, "/bindings/authorityBound/from/items/1/when", observe);
        const expression24 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/authorityBound/from/items/1/then", observe);
        const expression25 = new Expression(mechanics["literal"], { ["value"]: true }, "/bindings/authorityBound/from/items/1/else", observe);
        const expression26 = new Expression(mechanics["if"], { ["when"]: expression23, ["then"]: expression24, ["else"]: expression25 }, "/bindings/authorityBound/from/items/1", observe);
        const expression27 = new Expression(mechanics["array"], { ["items"]: [expression20, expression26] }, "/bindings/authorityBound/from", observe);
        const expression28 = new Expression(mechanics["path"], { ["from"]: "check", ["path"]: "" }, "/bindings/authorityBound/where", observe);
        const expression29 = new Expression(mechanics["every"], { ["from"]: expression27, ["as"]: "check", ["where"]: expression28 }, "/bindings/authorityBound", observe);
        const expression30 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "observedWindow" }, "/bindings/windowDeclared/when/left", observe);
        const expression31 = new Expression(mechanics["literal"], { ["value"]: "" }, "/bindings/windowDeclared/when/right", observe);
        const expression32 = new Expression(mechanics["equals"], { ["left"]: expression30, ["right"]: expression31 }, "/bindings/windowDeclared/when", observe);
        const expression33 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/windowDeclared/then", observe);
        const expression34 = new Expression(mechanics["literal"], { ["value"]: true }, "/bindings/windowDeclared/else", observe);
        const expression35 = new Expression(mechanics["if"], { ["when"]: expression32, ["then"]: expression33, ["else"]: expression34 }, "/bindings/windowDeclared", observe);
        const expression36 = new Expression(mechanics["path"], { ["from"]: "recordBound", ["path"]: "" }, "/bindings/adaptationDisposition/when/left", observe);
        const expression37 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/adaptationDisposition/when/right", observe);
        const expression38 = new Expression(mechanics["equals"], { ["left"]: expression36, ["right"]: expression37 }, "/bindings/adaptationDisposition/when", observe);
        const expression39 = new Expression(mechanics["literal"], { ["value"]: "ADAPTATION_HELD" }, "/bindings/adaptationDisposition/then", observe);
        const expression40 = new Expression(mechanics["path"], { ["from"]: "typeAdmitted", ["path"]: "" }, "/bindings/adaptationDisposition/else/when/left", observe);
        const expression41 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/adaptationDisposition/else/when/right", observe);
        const expression42 = new Expression(mechanics["equals"], { ["left"]: expression40, ["right"]: expression41 }, "/bindings/adaptationDisposition/else/when", observe);
        const expression43 = new Expression(mechanics["literal"], { ["value"]: "ADAPTATION_HELD" }, "/bindings/adaptationDisposition/else/then", observe);
        const expression44 = new Expression(mechanics["path"], { ["from"]: "authorityBound", ["path"]: "" }, "/bindings/adaptationDisposition/else/else/when/left", observe);
        const expression45 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/adaptationDisposition/else/else/when/right", observe);
        const expression46 = new Expression(mechanics["equals"], { ["left"]: expression44, ["right"]: expression45 }, "/bindings/adaptationDisposition/else/else/when", observe);
        const expression47 = new Expression(mechanics["literal"], { ["value"]: "ADAPTATION_HELD" }, "/bindings/adaptationDisposition/else/else/then", observe);
        const expression48 = new Expression(mechanics["path"], { ["from"]: "windowDeclared", ["path"]: "" }, "/bindings/adaptationDisposition/else/else/else/when/left", observe);
        const expression49 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/adaptationDisposition/else/else/else/when/right", observe);
        const expression50 = new Expression(mechanics["equals"], { ["left"]: expression48, ["right"]: expression49 }, "/bindings/adaptationDisposition/else/else/else/when", observe);
        const expression51 = new Expression(mechanics["literal"], { ["value"]: "ADAPTATION_HELD" }, "/bindings/adaptationDisposition/else/else/else/then", observe);
        const expression52 = new Expression(mechanics["literal"], { ["value"]: "ADAPTED_EVIDENCE_BINDING" }, "/bindings/adaptationDisposition/else/else/else/else", observe);
        const expression53 = new Expression(mechanics["if"], { ["when"]: expression50, ["then"]: expression51, ["else"]: expression52 }, "/bindings/adaptationDisposition/else/else/else", observe);
        const expression54 = new Expression(mechanics["if"], { ["when"]: expression46, ["then"]: expression47, ["else"]: expression53 }, "/bindings/adaptationDisposition/else/else", observe);
        const expression55 = new Expression(mechanics["if"], { ["when"]: expression42, ["then"]: expression43, ["else"]: expression54 }, "/bindings/adaptationDisposition/else", observe);
        const expression56 = new Expression(mechanics["if"], { ["when"]: expression38, ["then"]: expression39, ["else"]: expression55 }, "/bindings/adaptationDisposition", observe);
        const expression57 = new Expression(mechanics["path"], { ["from"]: "recordBound", ["path"]: "" }, "/bindings/findingCodes/when/left", observe);
        const expression58 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/findingCodes/when/right", observe);
        const expression59 = new Expression(mechanics["equals"], { ["left"]: expression57, ["right"]: expression58 }, "/bindings/findingCodes/when", observe);
        const expression60 = new Expression(mechanics["literal"], { ["value"]: [
                "JMI_RECORD_UNBOUND"
            ] }, "/bindings/findingCodes/then", observe);
        const expression61 = new Expression(mechanics["path"], { ["from"]: "typeAdmitted", ["path"]: "" }, "/bindings/findingCodes/else/when/left", observe);
        const expression62 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/findingCodes/else/when/right", observe);
        const expression63 = new Expression(mechanics["equals"], { ["left"]: expression61, ["right"]: expression62 }, "/bindings/findingCodes/else/when", observe);
        const expression64 = new Expression(mechanics["literal"], { ["value"]: [
                "JMI_RECORD_TYPE_UNADMITTED"
            ] }, "/bindings/findingCodes/else/then", observe);
        const expression65 = new Expression(mechanics["path"], { ["from"]: "authorityBound", ["path"]: "" }, "/bindings/findingCodes/else/else/when/left", observe);
        const expression66 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/findingCodes/else/else/when/right", observe);
        const expression67 = new Expression(mechanics["equals"], { ["left"]: expression65, ["right"]: expression66 }, "/bindings/findingCodes/else/else/when", observe);
        const expression68 = new Expression(mechanics["literal"], { ["value"]: [
                "ADAPTER_AUTHORITY_UNADMITTED"
            ] }, "/bindings/findingCodes/else/else/then", observe);
        const expression69 = new Expression(mechanics["path"], { ["from"]: "windowDeclared", ["path"]: "" }, "/bindings/findingCodes/else/else/else/when/left", observe);
        const expression70 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/findingCodes/else/else/else/when/right", observe);
        const expression71 = new Expression(mechanics["equals"], { ["left"]: expression69, ["right"]: expression70 }, "/bindings/findingCodes/else/else/else/when", observe);
        const expression72 = new Expression(mechanics["literal"], { ["value"]: [
                "OBSERVATION_WINDOW_ABSENT"
            ] }, "/bindings/findingCodes/else/else/else/then", observe);
        const expression73 = new Expression(mechanics["literal"], { ["value"]: [] }, "/bindings/findingCodes/else/else/else/else", observe);
        const expression74 = new Expression(mechanics["if"], { ["when"]: expression71, ["then"]: expression72, ["else"]: expression73 }, "/bindings/findingCodes/else/else/else", observe);
        const expression75 = new Expression(mechanics["if"], { ["when"]: expression67, ["then"]: expression68, ["else"]: expression74 }, "/bindings/findingCodes/else/else", observe);
        const expression76 = new Expression(mechanics["if"], { ["when"]: expression63, ["then"]: expression64, ["else"]: expression75 }, "/bindings/findingCodes/else", observe);
        const expression77 = new Expression(mechanics["if"], { ["when"]: expression59, ["then"]: expression60, ["else"]: expression76 }, "/bindings/findingCodes", observe);
        const expression78 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordRef" }, "/bindings/adapterReceiptDigest/values/digest/value/value/fields/jmiRecordRef", observe);
        const expression79 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordType" }, "/bindings/adapterReceiptDigest/values/digest/value/value/fields/jmiRecordType", observe);
        const expression80 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordDigest" }, "/bindings/adapterReceiptDigest/values/digest/value/value/fields/jmiRecordDigest", observe);
        const expression81 = new Expression(mechanics["path"], { ["from"]: "adaptationDisposition", ["path"]: "" }, "/bindings/adapterReceiptDigest/values/digest/value/value/fields/adaptationDisposition", observe);
        const expression82 = new Expression(mechanics["object"], { ["fields"]: {
                ["jmiRecordRef"]: expression78,
                ["jmiRecordType"]: expression79,
                ["jmiRecordDigest"]: expression80,
                ["adaptationDisposition"]: expression81
            } }, "/bindings/adapterReceiptDigest/values/digest/value/value", observe);
        const expression83 = new Expression(mechanics["json-stringify"], { ["value"]: expression82 }, "/bindings/adapterReceiptDigest/values/digest/value", observe);
        const expression84 = new Expression(mechanics["sha256"], { ["value"]: expression83 }, "/bindings/adapterReceiptDigest/values/digest", observe);
        const expression85 = new Expression(mechanics["format"], { ["template"]: "sha256:{digest}", ["values"]: {
                ["digest"]: expression84
            } }, "/bindings/adapterReceiptDigest", observe);
        const expression86 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "" }, "/value/values/0", observe);
        const expression87 = new Expression(mechanics["literal"], { ["value"]: "job-market-intelligence-adapter-record.v1" }, "/value/values/1/fields/contractId", observe);
        const expression88 = new Expression(mechanics["path"], { ["from"]: "adaptationDisposition", ["path"]: "" }, "/value/values/1/fields/adaptationDisposition", observe);
        const expression89 = new Expression(mechanics["path"], { ["from"]: "findingCodes", ["path"]: "" }, "/value/values/1/fields/findingCodes", observe);
        const expression90 = new Expression(mechanics["path"], { ["from"]: "adapterReceiptDigest", ["path"]: "" }, "/value/values/1/fields/adapterReceiptDigest", observe);
        const expression91 = new Expression(mechanics["object"], { ["fields"]: {
                ["contractId"]: expression87,
                ["adaptationDisposition"]: expression88,
                ["findingCodes"]: expression89,
                ["adapterReceiptDigest"]: expression90
            } }, "/value/values/1", observe);
        const expression92 = new Expression(mechanics["merge"], { ["values"]: [expression86, expression91] }, "/value", observe);
        const expression93 = new Expression(mechanics["let"], { ["bindings"]: {
                ["recordBound"]: expression14,
                ["typeAdmitted"]: expression17,
                ["authorityBound"]: expression29,
                ["windowDeclared"]: expression35,
                ["adaptationDisposition"]: expression56,
                ["findingCodes"]: expression77,
                ["adapterReceiptDigest"]: expression85
            }, ["value"]: expression92 }, "", observe);
        this.expression = expression93;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
