// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class VerifyJmiTypeAdmissionPort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["literal"], { ["value"]: [
                "job-market-observation-scope.v1",
                "job-market-intelligence-state.v1",
                "job-market-observation-request.v1",
                "public-job-market-observation-state.v1",
                "experience-admission-scope.v1",
                "experience-gap-resolution-scope.v1",
                "market-driven-experience-acquisition-scope.v1",
                "experience-mission-planning-scope.v1"
            ] }, "/bindings/typeAdmitted/in", observe);
        const expression1 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordType" }, "/bindings/typeAdmitted/value", observe);
        const expression2 = new Expression(mechanics["includes"], { ["in"]: expression0, ["value"]: expression1 }, "/bindings/typeAdmitted", observe);
        const expression3 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "adapterAuthorityId" }, "/bindings/authorityBound/from/items/0/left", observe);
        const expression4 = new Expression(mechanics["literal"], { ["value"]: "sidefx-jmi-adapter-authority.v1" }, "/bindings/authorityBound/from/items/0/right", observe);
        const expression5 = new Expression(mechanics["equals"], { ["left"]: expression3, ["right"]: expression4 }, "/bindings/authorityBound/from/items/0", observe);
        const expression6 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "adapterAuthorityDigest" }, "/bindings/authorityBound/from/items/1/when/left", observe);
        const expression7 = new Expression(mechanics["literal"], { ["value"]: "" }, "/bindings/authorityBound/from/items/1/when/right", observe);
        const expression8 = new Expression(mechanics["equals"], { ["left"]: expression6, ["right"]: expression7 }, "/bindings/authorityBound/from/items/1/when", observe);
        const expression9 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/authorityBound/from/items/1/then", observe);
        const expression10 = new Expression(mechanics["literal"], { ["value"]: true }, "/bindings/authorityBound/from/items/1/else", observe);
        const expression11 = new Expression(mechanics["if"], { ["when"]: expression8, ["then"]: expression9, ["else"]: expression10 }, "/bindings/authorityBound/from/items/1", observe);
        const expression12 = new Expression(mechanics["array"], { ["items"]: [expression5, expression11] }, "/bindings/authorityBound/from", observe);
        const expression13 = new Expression(mechanics["path"], { ["from"]: "check", ["path"]: "" }, "/bindings/authorityBound/where", observe);
        const expression14 = new Expression(mechanics["every"], { ["from"]: expression12, ["as"]: "check", ["where"]: expression13 }, "/bindings/authorityBound", observe);
        const expression15 = new Expression(mechanics["path"], { ["from"]: "typeAdmitted", ["path"]: "" }, "/bindings/admitted/from/items/0", observe);
        const expression16 = new Expression(mechanics["path"], { ["from"]: "authorityBound", ["path"]: "" }, "/bindings/admitted/from/items/1", observe);
        const expression17 = new Expression(mechanics["array"], { ["items"]: [expression15, expression16] }, "/bindings/admitted/from", observe);
        const expression18 = new Expression(mechanics["path"], { ["from"]: "check", ["path"]: "" }, "/bindings/admitted/where", observe);
        const expression19 = new Expression(mechanics["every"], { ["from"]: expression17, ["as"]: "check", ["where"]: expression18 }, "/bindings/admitted", observe);
        const expression20 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "" }, "/value/values/0", observe);
        const expression21 = new Expression(mechanics["path"], { ["from"]: "admitted", ["path"]: "" }, "/value/values/1/fields/typeAdmissionResult/fields/admitted", observe);
        const expression22 = new Expression(mechanics["object"], { ["fields"]: {
                ["admitted"]: expression21
            } }, "/value/values/1/fields/typeAdmissionResult", observe);
        const expression23 = new Expression(mechanics["object"], { ["fields"]: {
                ["typeAdmissionResult"]: expression22
            } }, "/value/values/1", observe);
        const expression24 = new Expression(mechanics["merge"], { ["values"]: [expression20, expression23] }, "/value", observe);
        const expression25 = new Expression(mechanics["let"], { ["bindings"]: {
                ["typeAdmitted"]: expression2,
                ["authorityBound"]: expression14,
                ["admitted"]: expression19
            }, ["value"]: expression24 }, "", observe);
        this.expression = expression25;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
