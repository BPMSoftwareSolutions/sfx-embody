// Native helpers from languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs; sha256:037366141a597af82c2e801226e351e4b84d97f67296c4ddcff4d52a1cf3e1b6
import crypto from "node:crypto";
import { valueAt } from "./native-mechanic-primitives.mjs";
function sfxValueAt(source, dottedPath) {
    return valueAt(source, dottedPath) ?? null;
}
export { sfxValueAt };
