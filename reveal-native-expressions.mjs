import assert from 'node:assert/strict';
import { atAstPath } from './resolvers/node/native-expression-projection.mjs';

export function unwrap(ts, node) { while (ts.isParenthesizedExpression(node)) node = node.expression; return node; }
export function readNativeLiteral(ts, node) {
  node = unwrap(ts, node);
  if (ts.isStringLiteral(node) || ts.isNoSubstitutionTemplateLiteral(node)) return node.text;
  if (ts.isNumericLiteral(node)) return Number(node.text);
  if (node.kind === ts.SyntaxKind.TrueKeyword) return true;
  if (node.kind === ts.SyntaxKind.FalseKeyword) return false;
  if (node.kind === ts.SyntaxKind.NullKeyword) return null;
  if (ts.isIdentifier(node) && node.text === 'undefined') return undefined;
  if (ts.isPrefixUnaryExpression(node) && node.operator === ts.SyntaxKind.MinusToken) return -readNativeLiteral(ts, node.operand);
  if (ts.isArrayLiteralExpression(node)) return node.elements.map(n => readNativeLiteral(ts, n));
  if (ts.isObjectLiteralExpression(node)) return Object.fromEntries(node.properties.map(p => {
    assert.ok(ts.isPropertyAssignment(p), 'Only native data properties are revealable literals');
    return [ts.isComputedPropertyName(p.name) ? readNativeLiteral(ts, p.name.expression) : p.name.text, readNativeLiteral(ts, p.initializer)];
  }));
  throw new Error('NATIVE_LITERAL_NOT_REVEALABLE:' + node.getText());
}

// Reads values, operators, operands, collection callbacks and lexical bindings
// from the native AST. Lineage supplies semantic addresses and the reversible
// mapping of escaped identifiers; it does not supply an expression to return.
export function revealNativeExpressions(ts, source, port) {
  const ast = ts.createSourceFile(port.physicalFile, source, ts.ScriptTarget.Latest, true);
  assert.equal(ast.parseDiagnostics.length, 0);
  const regions = port.nodes.map(n => ({ metadata: n, syntax: unwrap(ts, atAstPath(ts, ast, n.generated.astPath)) }));
  const literal = n => readNativeLiteral(ts, n);
  const assertCall = (node, target) => {
    node = unwrap(ts, node);
    assert.ok(ts.isCallExpression(node), 'Expected native call: ' + target);
    const callee = value => ts.isIdentifier(value) ? value.text : ts.isPropertyAccessExpression(value) ? callee(value.expression) + '.' + value.name.text : null;
    if (target) assert.equal(callee(node.expression), target, 'Native mechanic call');
    return node;
  };
  const method = (node, name) => {
    const call = assertCall(node);
    assert.ok(ts.isPropertyAccessExpression(call.expression));
    assert.equal(call.expression.name.text, name, 'Native mechanic method');
    return { receiver: call.expression.expression, args: call.arguments };
  };
  const binding = (nativeName, scope) => {
    const matches = port.bindings.filter(b => b.nativeName === nativeName && b.scope === scope);
    assert.equal(matches.length, 1, 'Native lexical binding identity');
    return matches[0].identity;
  };
  const child = syntax => {
    syntax = unwrap(ts, syntax);
    const matches = regions.filter(r => r.syntax === syntax);
    assert.equal(matches.length, 1, 'Operand must have exactly one checked semantic region');
    return decode(matches[0]);
  };
  const decode = ({ metadata: n, syntax: s }) => {
    const e = { op: n.operation };
    const optional = (name, value) => { if (n.parameterNames.includes(name)) e[name] = value; };
    switch (n.operation) {
      case 'literal': e.value = literal(s); break;
      case 'path': {
        const segments = [];
        while ((ts.isElementAccessExpression(s) || ts.isPropertyAccessExpression(s)) && s.questionDotToken) {
          segments.unshift(ts.isElementAccessExpression(s) ? literal(s.argumentExpression) : s.name.text); s = unwrap(ts, s.expression);
        }
        let from;
        if (ts.isIdentifier(s)) {
          const matches = Object.entries(n.scope).filter(([, native]) => native === s.text);
          assert.equal(matches.length, 1, 'Native path binding');
          from = matches[0][0];
        } else {
          assert.ok(ts.isElementAccessExpression(s));
          const environment = unwrap(ts, s.expression);
          assert.ok(ts.isObjectLiteralExpression(environment) && environment.properties.every(ts.isShorthandPropertyAssignment));
          assert.deepEqual(environment.properties.map(p => p.name.text), ['input', 'root']);
          from = literal(s.argumentExpression);
        }
        optional('from', from);
        optional('path', segments.join('.'));
        break;
      }
      case 'object': {
        assert.ok(ts.isObjectLiteralExpression(s));
        e.fields = Object.fromEntries(s.properties.map(p => {
          assert.ok(ts.isPropertyAssignment(p) && ts.isComputedPropertyName(p.name));
          return [literal(p.name.expression), child(p.initializer)];
        }));
        break;
      }
      case 'array': assert.ok(ts.isArrayLiteralExpression(s)); e.items = s.elements.map(child); break;
      case 'merge': {
        const call = assertCall(s, 'Object.assign');
        assert.deepEqual(literal(call.arguments[0]), {});
        e.values = call.arguments.slice(1).map(child); break;
      }
      case 'equals': case 'greater-than':
        assert.ok(ts.isBinaryExpression(s));
        assert.equal(s.operatorToken.kind, n.operation === 'equals' ? ts.SyntaxKind.EqualsEqualsEqualsToken : ts.SyntaxKind.GreaterThanToken);
        e.left = child(s.left); e.right = child(s.right); break;
      case 'if':
        assert.ok(ts.isConditionalExpression(s));
        e.when = child(s.condition); e.then = child(s.whenTrue); e.else = child(s.whenFalse); break;
      case 'length':
        assert.ok(ts.isPropertyAccessExpression(s)); assert.equal(s.name.text, 'length'); e.value = child(s.expression); break;
      case 'includes': {
        const call = method(s, 'includes'); assert.equal(call.args.length, 1); e.in = child(call.receiver); e.value = child(call.args[0]); break;
      }
      case 'intersects': {
        const arrow = unwrap(ts, assertCall(s).expression);
        assert.ok(ts.isArrowFunction(arrow) && ts.isBlock(arrow.body));
        const initial = arrow.body.statements[0].declarationList.declarations[0].initializer;
        assert.ok(ts.isNewExpression(initial)); assert.equal(initial.expression.getText(ast), 'Set');
        e.right = child(initial.arguments[0]);
        e.left = child(method(arrow.body.statements[1].expression, 'some').receiver);
        break;
      }
      case 'let': {
        const call = assertCall(s); assert.equal(call.arguments.length, 0);
        const arrow = unwrap(ts, call.expression); assert.ok(ts.isArrowFunction(arrow) && ts.isBlock(arrow.body));
        const statements = [...arrow.body.statements];
        const returned = statements.pop(); assert.ok(ts.isReturnStatement(returned));
        e.bindings = Object.fromEntries(statements.map(statement => {
          assert.ok(ts.isVariableStatement(statement) && statement.declarationList.flags & ts.NodeFlags.Const);
          assert.equal(statement.declarationList.declarations.length, 1);
          const variable = statement.declarationList.declarations[0]; assert.ok(ts.isIdentifier(variable.name));
          return [binding(variable.name.text, n.sourcePointer), child(variable.initializer)];
        }));
        e.value = child(returned.expression); break;
      }
      case 'map': case 'flat-map': case 'filter': case 'find': case 'some': case 'every': {
        const call = method(s, n.operation === 'flat-map' ? 'flatMap' : n.operation);
        assert.equal(call.args.length, 1);
        const arrow = unwrap(ts, call.args[0]); assert.ok(ts.isArrowFunction(arrow));
        const indexed = ['map', 'flat-map', 'filter'].includes(n.operation);
        assert.equal(arrow.parameters.length, indexed ? 2 : 1);
        e.from = child(call.receiver); e.as = binding(arrow.parameters[0].name.text, n.sourcePointer);
        if (indexed) assert.equal(binding(arrow.parameters[1].name.text, n.sourcePointer), e.as + 'Index');
        const mapping = ['map', 'flat-map'].includes(n.operation);
        e[mapping ? 'value' : 'where'] = child(mapping ? arrow.body : assertCall(arrow.body, 'Boolean').arguments[0]);
        break;
      }
      case 'join': {
        const call = method(s, 'join'); assert.equal(call.args.length, 1); e.value = child(call.receiver); optional('separator', literal(call.args[0])); break;
      }
      case 'format': {
        const entries = [];
        while (ts.isCallExpression(unwrap(ts, s))) {
          const call = method(s, 'replaceAll'); assert.equal(call.args.length, 2);
          const key = literal(call.args[0]); assert.ok(key.startsWith('{') && key.endsWith('}'));
          entries.unshift([key.slice(1, -1), child(assertCall(call.args[1], 'String').arguments[0])]);
          s = unwrap(ts, call.receiver);
        }
        e.template = literal(s); e.values = Object.fromEntries(entries); break;
      }
      case 'json-stringify': e.value = child(assertCall(s, 'JSON.stringify').arguments[0]); break;
      case 'parse-json': e.value = child(assertCall(s, 'JSON.parse').arguments[0]); break;
      case 'canonicalize': e.value = child(assertCall(s, 'canonicalize').arguments[0]); break;
      case 'directed-graph-closure': e.value = child(assertCall(s, 'directedGraphClosure').arguments[0]); break;
      case 'trim': case 'lower-case': {
        const call = method(s, n.operation === 'trim' ? 'trim' : 'toLowerCase'); assert.equal(call.args.length, 0);
        e.value = child(assertCall(call.receiver, 'String').arguments[0]); break;
      }
      case 'sha256': {
        const digest = method(s, 'digest'); assert.deepEqual(digest.args.map(literal), ['hex']);
        const update = method(digest.receiver, 'update');
        const create = assertCall(update.receiver, 'crypto.createHash'); assert.deepEqual(create.arguments.map(literal), ['sha256']);
        e.value = child(assertCall(update.args[0], 'String').arguments[0]); break;
      }
      case 'base64-decode-utf8': {
        const call = method(s, 'toString'); assert.deepEqual(call.args.map(literal), ['utf8']);
        const from = assertCall(call.receiver, 'Buffer.from'); assert.equal(literal(from.arguments[1]), 'base64');
        e.value = child(assertCall(from.arguments[0], 'String').arguments[0]); break;
      }
      case 'unique': {
        assert.ok(ts.isArrayLiteralExpression(s) && s.elements.length === 1 && ts.isSpreadElement(s.elements[0]));
        const set = unwrap(ts, s.elements[0].expression); assert.ok(ts.isNewExpression(set)); assert.equal(set.expression.getText(ast), 'Set');
        e.value = child(set.arguments[0]); break;
      }
      case 'object-values': e.value = child(assertCall(s).arguments[0]); break;
      case 'try-parse-json': {
        const arrow = unwrap(ts, assertCall(s).expression); assert.ok(ts.isArrowFunction(arrow) && ts.isBlock(arrow.body));
        const attempt = arrow.body.statements[0]; assert.ok(ts.isTryStatement(attempt));
        const returned = attempt.tryBlock.statements[0].expression;
        const value = returned.properties.find(p => p.name.text === 'value');
        e.value = child(assertCall(value.initializer, 'JSON.parse').arguments[0]); break;
      }
      case 'escape-html': {
        for (let i = 0; i < 5; i++) s = unwrap(ts, method(s, 'replaceAll').receiver);
        e.value = child(assertCall(s, 'String').arguments[0]); break;
      }
      default: throw new Error('NATIVE_REVEAL_NOT_IMPLEMENTED:' + n.operation);
    }
    return e;
  };
  const root = regions.find(r => r.metadata.sourcePointer === '');
  assert.ok(root, 'Root semantic region');
  const result = decode(root);
  return { expression: result, nodeCount: regions.length, ast };
}

// Equality ignores serialization order only for ordinary records. Binding,
// object-field and format-value evaluation order remains semantically relevant.
export function comparableExpression(expression) {
  if (!expression || typeof expression !== 'object' || Array.isArray(expression)) return expression;
  const result = {};
  for (const key of Object.keys(expression).sort()) {
    const value = expression[key];
    if (expression.op === 'literal' && key === 'value') result[key] = value;
    else if (expression.op === 'path' && key === 'path') result[key] = value.split('.').filter(Boolean).join('.');
    else if (['bindings', 'fields', 'values'].includes(key) && value && !Array.isArray(value)) result[key] = Object.entries(value).map(([name, child]) => [name, comparableExpression(child)]);
    else if (Array.isArray(value)) result[key] = value.map(comparableExpression);
    else result[key] = comparableExpression(value);
  }
  return result;
}
