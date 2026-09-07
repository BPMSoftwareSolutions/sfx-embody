// Native bodies specialized from languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs; sha256:21fb43c57817b8dc3c3d2dd5af13551ca03111cf99f5654989f490fda6732ac5
import crypto from "node:crypto";
import { valueAt } from "./native-mechanic-primitives.mjs";
// array; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:9027-9095
export class ArrayMechanic {
    execute(expression, scope, evaluate) {
        return expression.items.map((item) => evaluate(item));
    }
}
// equals; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:10455-10534
export class EqualsMechanic {
    execute(expression, scope, evaluate) {
        return evaluate(expression.left) === evaluate(expression.right);
    }
}
// every; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:10055-10192
export class EveryMechanic {
    execute(expression, scope, evaluate) {
        return evaluate(expression.from).every((item) => Boolean(evaluate(expression.where, { ...scope, [expression.as]: item })));
    }
}
// format; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:11103-11286
export class FormatMechanic {
    execute(expression, scope, evaluate) {
        return Object.entries(expression.values).reduce((text, [key, value]) => text.replaceAll(`{${key}}`, String(evaluate(value))), expression.template);
    }
}
// if; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:10691-10791
export class IfMechanic {
    execute(expression, scope, evaluate) {
        return evaluate(expression.when) ? evaluate(expression.then) : evaluate(expression.else);
    }
}
// includes; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:10198-10283
export class IncludesMechanic {
    execute(expression, scope, evaluate) {
        return evaluate(expression.in).includes(evaluate(expression.value));
    }
}
// json-stringify; languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs:11877-11950
export class JsonStringifyMechanic {
    execute(expression, scope, evaluate) {
        return JSON.stringify(evaluate(expression.value));
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
    ["array"]: new ArrayMechanic(),
    ["equals"]: new EqualsMechanic(),
    ["every"]: new EveryMechanic(),
    ["format"]: new FormatMechanic(),
    ["if"]: new IfMechanic(),
    ["includes"]: new IncludesMechanic(),
    ["json-stringify"]: new JsonStringifyMechanic(),
    ["let"]: new LetMechanic(),
    ["literal"]: new LiteralMechanic(),
    ["merge"]: new MergeMechanic(),
    ["object"]: new ObjectMechanic(),
    ["path"]: new PathMechanic(),
    ["sha256"]: new Sha256Mechanic()
});
