// Native helpers from languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs; sha256:037366141a597af82c2e801226e351e4b84d97f67296c4ddcff4d52a1cf3e1b6
import crypto from "node:crypto";
import { valueAt } from "./native-mechanic-primitives.mjs";
function sfxValueAt(source, dottedPath) {
    return valueAt(source, dottedPath) ?? null;
}
function sfxNotAdmitted(code) {
    const error = new Error(code);
    error.code = code;
    throw error;
}
function sfxIsObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}
function sfxMerge(...values) {
    for (const value of values)
        if (value !== null && !sfxIsObject(value))
            sfxNotAdmitted("OPERAND_NOT_OBJECT");
    return Object.assign({}, ...values);
}
function sfxFormat(template, values) {
    const coerced = Object.entries(values).map(([key, value]) => {
        if (value === null || value === undefined)
            return [key, "null"];
        if (typeof value === "boolean")
            return [key, value ? "true" : "false"];
        if (typeof value === "number")
            return [key, String(value)];
        if (typeof value === "string")
            return [key, value];
        sfxNotAdmitted("OPERAND_NOT_PRIMITIVE");
    });
    return coerced.reduce((text, [key, value]) => text.replaceAll(`{${key}}`, value), template);
}
export { crypto, sfxFormat, sfxMerge, sfxValueAt };
