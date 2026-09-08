// Native helpers from languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs; sha256:037366141a597af82c2e801226e351e4b84d97f67296c4ddcff4d52a1cf3e1b6
import crypto from "node:crypto";
import { valueAt } from "./native-mechanic-primitives.mjs";
function sfxValueAt(source, dottedPath) {
    return valueAt(source, dottedPath) ?? null;
}
function sfxTruthy(value) {
    if (value === null || value === undefined || value === false)
        return false;
    if (typeof value === "number")
        return value !== 0 && !Number.isNaN(value);
    if (value === "")
        return false;
    if (Array.isArray(value))
        return value.length > 0;
    if (typeof value === "object")
        return Object.keys(value).length > 0;
    return true;
}
function sfxNotAdmitted(code) {
    const error = new Error(code);
    error.code = code;
    throw error;
}
function sfxIsPrimitive(value) {
    return value === null || typeof value === "string" || typeof value === "number" || typeof value === "boolean";
}
function sfxIsObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}
function sfxEquals(left, right) {
    if (!sfxIsPrimitive(left) || !sfxIsPrimitive(right))
        sfxNotAdmitted("OPERAND_NOT_PRIMITIVE");
    return left === right;
}
function sfxLength(value) {
    if (typeof value !== "string" && !Array.isArray(value))
        sfxNotAdmitted("OPERAND_NOT_MEASURABLE");
    return value.length;
}
function sfxMerge(...values) {
    for (const value of values)
        if (value !== null && !sfxIsObject(value))
            sfxNotAdmitted("OPERAND_NOT_OBJECT");
    return Object.assign({}, ...values);
}
export { sfxEquals, sfxLength, sfxMerge, sfxTruthy, sfxValueAt };
