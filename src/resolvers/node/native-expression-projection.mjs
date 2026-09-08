import crypto from 'node:crypto';
import { format } from 'prettier';

export const nativeDigest = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
export function nativeLiteral(value) {
  if (Object.is(value, -0)) return '-0';
  if (value === undefined) return 'undefined';
  if (Array.isArray(value)) return '[' + value.map(nativeLiteral).join(', ') + ']';
  if (value && typeof value === 'object') return '({' + Object.entries(value).map(([k, v]) => `[${JSON.stringify(k)}]: ${nativeLiteral(v)}`).join(', ') + '})';
  return JSON.stringify(value);
}
const escapePointer = value => value.replaceAll('~', '~0').replaceAll('/', '~1');

/** Candidate Node lowering of the database-selected native evaluator's pure
 * mechanics. Operation selection happens during projection, never in the body.
 * The original provider, differential vectors, and source maps accompany proof.
 */
export class NativeExpressionProjection {
  constructor(ts, declarations, nativeBodies) {
    this.ts = ts;
    this.declarations = declarations;
    this.nativeBodies = nativeBodies;
    this.nodes = [];
    this.bindings = [];
    this.helpers = new Set();
    this.names = new Set(['input', 'root', 'Object', 'Array', 'String', 'Boolean', 'JSON', 'Buffer', 'Set', 'crypto', 'canonicalize', 'directedGraphClosure', 'undefined', '$nativeRightSet', 'valueAt',
      'sfxValueAt', 'sfxTruthy', 'sfxNotAdmitted', 'sfxIsPrimitive', 'sfxIsObject', 'sfxEquals', 'sfxGreaterThan', 'sfxLength', 'sfxMerge', 'sfxJoin', 'sfxFormat', 'sfxUnique', 'sfxObjectValues', 'sfxParseJson', 'sfxTryParseJson']);
  }
  name(value, scope) {
    let candidate = value;
    const keyword = this.ts.stringToToken(value);
    if (!this.ts.isIdentifierText(value, this.ts.ScriptTarget.Latest) || keyword !== undefined) candidate = '$' + Buffer.from(value).toString('hex');
    while (this.names.has(candidate)) candidate += '$binding';
    this.names.add(candidate);
    this.bindings.push({ identity: value, nativeName: candidate, scope });
    return candidate;
  }
  emit(expression, location = '', scope = new Map([['input', 'input'], ['root', 'root']])) {
    if (!expression || typeof expression !== 'object' || Array.isArray(expression)) throw new Error('EXPRESSION_DECLARATION_REQUIRED:' + location);
    const declaration = this.declarations.get(expression.op);
    const native = this.nativeBodies.get(expression.op);
    if (!declaration || !native) throw new Error('MECHANIC_NOT_RESOLVED:' + expression.op);
    const form = declaration.semantics.mechanic.authoringForm;
    for (const key of form.required ?? []) if (!Object.hasOwn(expression, key)) throw new Error('MECHANIC_ARGUMENT_MISSING:' + location + ':' + key);
    for (const key of Object.keys(expression)) if (key !== 'op' && !Object.hasOwn(form.arguments, key)) throw new Error('MECHANIC_ARGUMENT_UNDECLARED:' + location + ':' + key);
    const index = this.nodes.length;
    const node = { sourcePointer: location, mechanicId: declaration.address.id, operation: expression.op,
      parameterNames: Object.keys(expression).filter(k => k !== 'op'), scope: Object.fromEntries(scope),
      providerSourceStart: native.sourceStart, providerSourceEnd: native.sourceEnd, providerBodyDigest: nativeDigest(native.body) };
    this.nodes.push(node);
    const child = (key, next = scope) => this.emit(expression[key], location + '/' + escapePointer(key), next);
    const list = key => expression[key].map((value, i) => this.emit(value, location + '/' + key + '/' + i, scope));
    const member = (key, name, next = scope) => this.emit(expression[key][name], location + '/' + key + '/' + escapePointer(name), next);
    let code;
    switch (expression.op) {
      case 'literal': code = nativeLiteral(expression.value); break;
      case 'path': {
        const from = expression.from ?? 'input', path = expression.path ?? '';
        if (typeof from !== 'string' || typeof path !== 'string' || expression.path === null) throw new Error('PATH_ARGUMENT_DOMAIN_NOT_SUPPORTED:' + location);
        this.helpers.add('sfxValueAt');
        code = `sfxValueAt(${scope.get(from) ?? `({input, root})[${nativeLiteral(from)}]`}, ${nativeLiteral(path)})`;
        // Path semantics are verified against the selected provider; the exact
        // spelling is retained here and normalized away only in comparison.
        node.pathSpelling = path;
        break;
      }
      case 'object': code = '({' + Object.keys(expression.fields).map(key => `[${nativeLiteral(key)}]: ${member('fields', key)}`).join(', ') + '})'; break;
      case 'array': code = '[' + list('items').join(', ') + ']'; break;
      case 'merge': this.helpers.add('sfxMerge'); code = `sfxMerge(${list('values').join(', ')})`; break;
      case 'equals': this.helpers.add('sfxEquals'); code = `sfxEquals(${child('left')}, ${child('right')})`; break;
      case 'greater-than': this.helpers.add('sfxGreaterThan'); code = `sfxGreaterThan(${child('left')}, ${child('right')})`; break;
      case 'length': this.helpers.add('sfxLength'); code = `sfxLength(${child('value')})`; break;
      case 'includes': code = `${child('in')}.includes(${child('value')})`; break;
      case 'intersects': {
        const right = child('right'), left = child('left');
        code = `(() => { const $nativeRightSet = new Set(${right}); return ${left}.some((value) => $nativeRightSet.has(value)); })()`;
        break;
      }
      case 'if': this.helpers.add('sfxTruthy'); code = `sfxTruthy(${child('when')}) ? ${child('then')} : ${child('else')}`; break;
      case 'let': {
        const next = new Map(scope), statements = [];
        for (const key of Object.keys(expression.bindings)) {
          const value = member('bindings', key, next);
          const name = this.name(key, location);
          statements.push(`const ${name} = ${value};`);
          next.set(key, name);
        }
        code = `(() => { ${statements.join('\n')} return ${child('value', next)}; })()`;
        break;
      }
      case 'map': case 'flat-map': case 'filter': case 'find': case 'some': case 'every': {
        const from = child('from');
        const binding = this.name(expression.as, location);
        const next = new Map(scope).set(expression.as, binding);
        const indexed = ['map', 'flat-map', 'filter'].includes(expression.op);
        const indexName = indexed ? this.name(expression.as + 'Index', location) : null;
        if (indexed) next.set(expression.as + 'Index', indexName);
        const mapping = ['map', 'flat-map'].includes(expression.op);
        const value = child(mapping ? 'value' : 'where', next);
        const method = expression.op === 'flat-map' ? 'flatMap' : expression.op;
        if (!mapping) this.helpers.add('sfxTruthy');
        code = `${from}.${method}((${binding}${indexed ? ', ' + indexName : ''}) => ${mapping ? value : `sfxTruthy(${value})`})`;
        if (expression.op === 'find') code += ' ?? null';
        break;
      }
      case 'join': this.helpers.add('sfxJoin'); code = `sfxJoin(${child('value')}, ${nativeLiteral(expression.separator ?? '')})`; break;
      case 'format': {
        this.helpers.add('sfxFormat');
        code = `sfxFormat(${nativeLiteral(expression.template)}, ({ ${Object.keys(expression.values).map(key => `[${nativeLiteral(key)}]: ${member('values', key)}`).join(', ')} }))`;
        break;
      }
      case 'sha256': this.helpers.add('crypto'); code = `crypto.createHash('sha256').update(String(${child('value')})).digest('hex')`; break;
      case 'base64-decode-utf8': code = `Buffer.from(String(${child('value')}), 'base64').toString('utf8')`; break;
      case 'json-stringify': code = `JSON.stringify(${child('value')})`; break;
      case 'parse-json': this.helpers.add('sfxParseJson'); code = `sfxParseJson(${child('value')})`; break;
      case 'canonicalize': this.helpers.add('canonicalize'); code = `canonicalize(${child('value')})`; break;
      case 'directed-graph-closure': this.helpers.add('directedGraphClosure'); code = `directedGraphClosure(${child('value')})`; break;
      case 'trim': code = `String(${child('value')}).trim()`; break;
      case 'lower-case': code = `String(${child('value')}).toLowerCase()`; break;
      case 'escape-html': code = `String(${child('value')}).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#39;')`; break;
      case 'unique': this.helpers.add('sfxUnique'); code = `sfxUnique(${child('value')})`; break;
      // These mechanics have native blocks with local temporaries. Their names
      // belong to the native provider, not to a new business declaration.
      case 'object-values': this.helpers.add('sfxObjectValues'); code = `sfxObjectValues(${child('value')})`; break;
      case 'try-parse-json': this.helpers.add('sfxTryParseJson'); code = `sfxTryParseJson(${child('value')})`; break;
      default: throw new Error('NATIVE_LOWERING_NOT_IMPLEMENTED:' + expression.op);
    }
    return `(/*@sfx-node:${index}*/ ${code})`;
  }
}

// Generated markers exist only while associating native AST regions with
// authority. They are removed before the physical body is written.
export async function locateNativeRegions(ts, source, nodes, file) {
  const ast = ts.createSourceFile(file, source, ts.ScriptTarget.Latest, true);
  const paths = new Map();
  const walk = (node, at) => {
    if (ts.isParenthesizedExpression(node)) {
      const prefix = source.slice(node.getStart(ast), node.expression.getStart(ast));
      const match = prefix.match(/^\(\s*\/\*@sfx-node:(\d+)\*\//);
      if (match) paths.set(Number(match[1]), at);
    }
    const children = []; ts.forEachChild(node, child => { children.push(child); });
    children.forEach((child, i) => walk(child, [...at, i]));
  };
  walk(ast, []);
  const semanticPaths = new Map();
  const semanticWalk = (node, at) => {
    while (ts.isParenthesizedExpression(node)) node = node.expression;
    semanticPaths.set(node, at);
    const children = []; ts.forEachChild(node, child => { children.push(child); });
    children.forEach((child, i) => semanticWalk(child, [...at, i]));
  };
  semanticWalk(ast, []);
  const rawAt = indices => {
    let node = ast;
    for (const index of indices) { const children = []; ts.forEachChild(node, child => { children.push(child); }); node = children[index]; }
    while (ts.isParenthesizedExpression(node)) node = node.expression;
    return node;
  };
  const clean = await format(source.replace(/\/\*@sfx-node:\d+\*\/\s?/g, ''), { parser: 'babel', printWidth: 100, quoteProps: 'preserve' });
  const cleanAst = ts.createSourceFile(file, clean, ts.ScriptTarget.Latest, true);
  for (const [index, node] of nodes.entries()) {
    const originalPath = paths.get(index);
    if (!originalPath) throw new Error('NATIVE_REGION_NOT_LOCATED:' + node.sourcePointer);
    const astPath = semanticPaths.get(rawAt(originalPath));
    const region = atAstPath(ts, cleanAst, astPath);
    const start = cleanAst.getLineAndCharacterOfPosition(region.getStart(cleanAst));
    const end = cleanAst.getLineAndCharacterOfPosition(region.end);
    node.generated = { file, astPath, startLine: start.line + 1, startColumn: start.character + 1, endLine: end.line + 1, endColumn: end.character + 1,
      syntaxDigest: nativeDigest(region.getText(cleanAst)) };
  }
  return clean;
}

export function atAstPath(ts, ast, indices) {
  let node = ast;
  for (const index of indices) {
    while (ts.isParenthesizedExpression(node)) node = node.expression;
    const children = []; ts.forEachChild(node, child => { children.push(child); }); node = children[index]; if (!node) throw new Error('NATIVE_REGION_AST_CHANGED');
  }
  while (ts.isParenthesizedExpression(node)) node = node.expression;
  return node;
}

export function nativeSyntax(ts, node) {
  while (ts.isParenthesizedExpression(node)) node = node.expression;
  const children = []; ts.forEachChild(node, child => { children.push(nativeSyntax(ts, child)); });
  return [ts.SyntaxKind[node.kind], node.text ?? null, children];
}
