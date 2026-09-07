// Native helpers from languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs; sha256:21fb43c57817b8dc3c3d2dd5af13551ca03111cf99f5654989f490fda6732ac5
import crypto from "node:crypto";
import { valueAt } from "./native-mechanic-primitives.mjs";
function canonicalize(value) {
    if (Array.isArray(value))
        return value.map(canonicalize);
    if (!value || typeof value !== "object")
        return value;
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonicalize(value[key])]));
}
export { canonicalize };
