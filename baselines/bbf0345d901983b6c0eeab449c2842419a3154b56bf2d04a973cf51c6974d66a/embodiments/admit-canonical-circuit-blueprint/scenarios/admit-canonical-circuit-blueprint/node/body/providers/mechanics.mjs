// Native bodies specialized from languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs; sha256:21fb43c57817b8dc3c3d2dd5af13551ca03111cf99f5654989f490fda6732ac5
import crypto from "node:crypto";
import { valueAt } from "./native-mechanic-primitives.mjs";
// base64-decode-utf8; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:11762-11871
export class Base64DecodeUtf8Mechanic {
    execute(expression, scope, evaluate) {
        return Buffer.from(String(evaluate(expression.value)), "base64").toString("utf8");
    }
}
// format; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:11103-11286
export class FormatMechanic {
    execute(expression, scope, evaluate) {
        return Object.entries(expression.values).reduce((text, [key, value]) => text.replaceAll(`{${key}}`, String(evaluate(value))), expression.template);
    }
}
// let; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:12396-12644
export class LetMechanic {
    execute(expression, scope, evaluate) {
        {
            let nextScope = { ...scope };
            for (const [name, value] of Object.entries(expression.bindings))
                nextScope = { ...nextScope, [name]: evaluate(value, nextScope) };
            return evaluate(expression.value, nextScope);
        }
    }
}
// literal; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:8750-8807
export class LiteralMechanic {
    execute(expression, scope, evaluate) {
        return structuredClone(expression.value);
    }
}
// merge; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:9101-9194
export class MergeMechanic {
    execute(expression, scope, evaluate) {
        return Object.assign({}, ...expression.values.map((value) => evaluate(value)));
    }
}
// object; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:8899-9021
export class ObjectMechanic {
    execute(expression, scope, evaluate) {
        return Object.fromEntries(Object.entries(expression.fields).map(([key, value]) => [key, evaluate(value)]));
    }
}
// parse-json; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:12124-12189
export class ParseJsonMechanic {
    execute(expression, scope, evaluate) {
        return JSON.parse(evaluate(expression.value));
    }
}
// path; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:8813-8893
export class PathMechanic {
    execute(expression, scope, evaluate) {
        return valueAt(scope[expression.from ?? "input"], expression.path);
    }
}
// sha256; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:11649-11756
export class Sha256Mechanic {
    execute(expression, scope, evaluate) {
        return crypto.createHash("sha256").update(String(evaluate(expression.value))).digest("hex");
    }
}
export const createMechanics = () => ({
    ["base64-decode-utf8"]: new Base64DecodeUtf8Mechanic(),
    ["format"]: new FormatMechanic(),
    ["let"]: new LetMechanic(),
    ["literal"]: new LiteralMechanic(),
    ["merge"]: new MergeMechanic(),
    ["object"]: new ObjectMechanic(),
    ["parse-json"]: new ParseJsonMechanic(),
    ["path"]: new PathMechanic(),
    ["sha256"]: new Sha256Mechanic()
});
