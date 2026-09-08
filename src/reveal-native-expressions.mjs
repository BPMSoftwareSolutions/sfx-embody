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
        const call = assertCall(s, 'sfxValueAt'); assert.equal(call.arguments.length, 2);
        const argument = unwrap(ts, call.arguments[0]);
        let from;
        if (ts.isIdentifier(argument)) {
          const matches = Object.entries(n.scope).filter(([, native]) => native === argument.text);
          assert.equal(matches.length, 1, 'Native path binding');
          from = matches[0][0];
        } else {
          assert.ok(ts.isElementAccessExpression(argument));
          const environment = unwrap(ts, argument.expression);
          assert.ok(ts.isObjectLiteralExpression(environment) && environment.properties.every(ts.isShorthandPropertyAssignment));
          assert.deepEqual(environment.properties.map(p => p.name.text), ['input', 'root']);
          from = literal(argument.argumentExpression);
        }
        optional('from', from);
        optional('path', literal(call.arguments[1]));
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
        const call = assertCall(s, 'sfxMerge'); e.values = call.arguments.map(child); break;
      }
      case 'equals': case 'greater-than': {
        const call = assertCall(s, n.operation === 'equals' ? 'sfxEquals' : 'sfxGreaterThan'); assert.equal(call.arguments.length, 2);
        e.left = child(call.arguments[0]); e.right = child(call.arguments[1]); break;
      }
      case 'if': {
        assert.ok(ts.isConditionalExpression(s));
        e.when = child(assertCall(s.condition, 'sfxTruthy').arguments[0]); e.then = child(s.whenTrue); e.else = child(s.whenFalse); break;
      }
      case 'length': {
        const call = assertCall(s, 'sfxLength'); assert.equal(call.arguments.length, 1); e.value = child(call.arguments[0]); break;
      }
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
        if (n.operation === 'find' && ts.isBinaryExpression(s)) {
          assert.equal(s.operatorToken.kind, ts.SyntaxKind.QuestionQuestionToken, 'Native find absence');
          assert.ok(unwrap(ts, s.right).kind === ts.SyntaxKind.NullKeyword, 'Native find absence');
          s = s.left;
        }
        const call = method(s, n.operation === 'flat-map' ? 'flatMap' : n.operation);
        assert.equal(call.args.length, 1);
        const arrow = unwrap(ts, call.args[0]); assert.ok(ts.isArrowFunction(arrow));
        const indexed = ['map', 'flat-map', 'filter'].includes(n.operation);
        assert.equal(arrow.parameters.length, indexed ? 2 : 1);
        e.from = child(call.receiver); e.as = binding(arrow.parameters[0].name.text, n.sourcePointer);
        if (indexed) assert.equal(binding(arrow.parameters[1].name.text, n.sourcePointer), e.as + 'Index');
        const mapping = ['map', 'flat-map'].includes(n.operation);
        e[mapping ? 'value' : 'where'] = child(mapping ? arrow.body : assertCall(arrow.body, 'sfxTruthy').arguments[0]);
        break;
      }
      case 'join': {
        const call = assertCall(s, 'sfxJoin'); assert.equal(call.arguments.length, 2);
        e.value = child(call.arguments[0]); optional('separator', literal(call.arguments[1])); break;
      }
      case 'format': {
        const call = assertCall(s, 'sfxFormat'); assert.equal(call.arguments.length, 2);
        e.template = literal(call.arguments[0]);
        const values = unwrap(ts, call.arguments[1]); assert.ok(ts.isObjectLiteralExpression(values));
        e.values = Object.fromEntries(values.properties.map(p => {
          assert.ok(ts.isPropertyAssignment(p) && ts.isComputedPropertyName(p.name));
          return [literal(p.name.expression), child(p.initializer)];
        }));
        break;
      }
      case 'json-stringify': e.value = child(assertCall(s, 'JSON.stringify').arguments[0]); break;
      case 'parse-json': e.value = child(assertCall(s, 'sfxParseJson').arguments[0]); break;
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
        const call = assertCall(s, 'sfxUnique'); assert.equal(call.arguments.length, 1); e.value = child(call.arguments[0]); break;
      }
      case 'object-values': e.value = child(assertCall(s, 'sfxObjectValues').arguments[0]); break;
      case 'try-parse-json': e.value = child(assertCall(s, 'sfxTryParseJson').arguments[0]); break;
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
