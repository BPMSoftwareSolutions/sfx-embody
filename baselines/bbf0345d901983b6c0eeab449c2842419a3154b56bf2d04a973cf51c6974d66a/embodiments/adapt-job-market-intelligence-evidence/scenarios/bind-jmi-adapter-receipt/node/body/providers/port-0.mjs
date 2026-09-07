// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class BindJmiAdapterReceiptPort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordRef" }, "/bindings/adapterReceiptDigest/values/digest/value/value/fields/jmiRecordRef", observe);
        const expression1 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordType" }, "/bindings/adapterReceiptDigest/values/digest/value/value/fields/jmiRecordType", observe);
        const expression2 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "jmiRecordDigest" }, "/bindings/adapterReceiptDigest/values/digest/value/value/fields/jmiRecordDigest", observe);
        const expression3 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "adaptationDisposition" }, "/bindings/adapterReceiptDigest/values/digest/value/value/fields/adaptationDisposition", observe);
        const expression4 = new Expression(mechanics["object"], { ["fields"]: {
                ["jmiRecordRef"]: expression0,
                ["jmiRecordType"]: expression1,
                ["jmiRecordDigest"]: expression2,
                ["adaptationDisposition"]: expression3
            } }, "/bindings/adapterReceiptDigest/values/digest/value/value", observe);
        const expression5 = new Expression(mechanics["json-stringify"], { ["value"]: expression4 }, "/bindings/adapterReceiptDigest/values/digest/value", observe);
        const expression6 = new Expression(mechanics["sha256"], { ["value"]: expression5 }, "/bindings/adapterReceiptDigest/values/digest", observe);
        const expression7 = new Expression(mechanics["format"], { ["template"]: "sha256:{digest}", ["values"]: {
                ["digest"]: expression6
            } }, "/bindings/adapterReceiptDigest", observe);
        const expression8 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "" }, "/value/values/0", observe);
        const expression9 = new Expression(mechanics["path"], { ["from"]: "adapterReceiptDigest", ["path"]: "" }, "/value/values/1/fields/adapterReceiptDigest", observe);
        const expression10 = new Expression(mechanics["object"], { ["fields"]: {
                ["adapterReceiptDigest"]: expression9
            } }, "/value/values/1", observe);
        const expression11 = new Expression(mechanics["merge"], { ["values"]: [expression8, expression10] }, "/value", observe);
        const expression12 = new Expression(mechanics["let"], { ["bindings"]: {
                ["adapterReceiptDigest"]: expression7
            }, ["value"]: expression11 }, "", observe);
        this.expression = expression12;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
