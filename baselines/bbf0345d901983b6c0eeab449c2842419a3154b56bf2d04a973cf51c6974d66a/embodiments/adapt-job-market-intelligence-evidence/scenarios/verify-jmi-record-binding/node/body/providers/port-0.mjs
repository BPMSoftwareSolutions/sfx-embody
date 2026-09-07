// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class VerifyJmiRecordBindingPort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordRef" }, "/bindings/bound/from/items/0/when/left", observe);
        const expression1 = new Expression(mechanics["literal"], { ["value"]: "" }, "/bindings/bound/from/items/0/when/right", observe);
        const expression2 = new Expression(mechanics["equals"], { ["left"]: expression0, ["right"]: expression1 }, "/bindings/bound/from/items/0/when", observe);
        const expression3 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/bound/from/items/0/then", observe);
        const expression4 = new Expression(mechanics["literal"], { ["value"]: true }, "/bindings/bound/from/items/0/else", observe);
        const expression5 = new Expression(mechanics["if"], { ["when"]: expression2, ["then"]: expression3, ["else"]: expression4 }, "/bindings/bound/from/items/0", observe);
        const expression6 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordDigest" }, "/bindings/bound/from/items/1/when/left", observe);
        const expression7 = new Expression(mechanics["literal"], { ["value"]: "" }, "/bindings/bound/from/items/1/when/right", observe);
        const expression8 = new Expression(mechanics["equals"], { ["left"]: expression6, ["right"]: expression7 }, "/bindings/bound/from/items/1/when", observe);
        const expression9 = new Expression(mechanics["literal"], { ["value"]: false }, "/bindings/bound/from/items/1/then", observe);
        const expression10 = new Expression(mechanics["literal"], { ["value"]: true }, "/bindings/bound/from/items/1/else", observe);
        const expression11 = new Expression(mechanics["if"], { ["when"]: expression8, ["then"]: expression9, ["else"]: expression10 }, "/bindings/bound/from/items/1", observe);
        const expression12 = new Expression(mechanics["array"], { ["items"]: [expression5, expression11] }, "/bindings/bound/from", observe);
        const expression13 = new Expression(mechanics["path"], { ["from"]: "check", ["path"]: "" }, "/bindings/bound/where", observe);
        const expression14 = new Expression(mechanics["every"], { ["from"]: expression12, ["as"]: "check", ["where"]: expression13 }, "/bindings/bound", observe);
        const expression15 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "" }, "/value/values/0", observe);
        const expression16 = new Expression(mechanics["path"], { ["from"]: "bound", ["path"]: "" }, "/value/values/1/fields/recordBindingResult/fields/bound", observe);
        const expression17 = new Expression(mechanics["object"], { ["fields"]: {
                ["bound"]: expression16
            } }, "/value/values/1/fields/recordBindingResult", observe);
        const expression18 = new Expression(mechanics["object"], { ["fields"]: {
                ["recordBindingResult"]: expression17
            } }, "/value/values/1", observe);
        const expression19 = new Expression(mechanics["merge"], { ["values"]: [expression15, expression18] }, "/value", observe);
        const expression20 = new Expression(mechanics["let"], { ["bindings"]: {
                ["bound"]: expression14
            }, ["value"]: expression19 }, "", observe);
        this.expression = expression20;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
