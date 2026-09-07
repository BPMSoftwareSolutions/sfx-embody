import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import ts from 'typescript';
import { fileURLToPath } from 'node:url';
import { readWorkspaceConfig } from '../src/read-workspace-config.mjs';

// Read-only inspection of the retained authority and materialized code.
// This does not regenerate bodies, revise authority, or change execution receipts.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = async file => JSON.parse((await fs.readFile(file, 'utf8')).replace(/^\uFEFF/, ''));
const regression = await read(path.join(root, 'evidence/regression-results.json'));
const cases = await readWorkspaceConfig();
const result = { implementationDigest: regression.implementationDigest, files: [], scenarios: [], contractFindings: [] };
const digest = text => 'sha256:' + crypto.createHash('sha256').update(text).digest('hex');
for (const tested of regression.cases) {
  const testCase = cases.cases.find(c => c.selectionFile === tested.selectionFile)
    ?? (await Promise.all(cases.cases.map(async c => ({ ...c, selection: await read(c.selectionFile) })))).find(c => c.selection.capabilityId === tested.selection.capabilityId);
  const bundle = await read(testCase.bundleFile);
  const mechanicForms = new Map(bundle.mechanics.recordsets[0].map(r => JSON.parse(r.definition_json)).filter(d => d.semantics.mechanic?.authoringForm).map(d => [d.address.id, d.semantics.mechanic.authoringForm]));
  for (const reference of tested.receipts) {
    const base = path.dirname(reference.file);
    const plan = await read(path.join(base, 'evidence/embodiment-plan.json'));
    const authority = await read(path.join(base, 'evidence/authority.json'));
    const lineage = await read(path.join(base, 'evidence/mechanic-lineage.json'));
    const row = { capabilityId: tested.selection.capabilityId, scenarioId: reference.scenarioId, numberedExpressions: 0, numberedStates: 0, numberedDependencyImports: 0, declaredBindings: [], declaredIterationBindings: [], fileCount: plan.files.length };
    for (const port of lineage) {
      const source = bundle.authority.recordsets[1].filter(r => r.source_path === port.sourceRef);
      if (source.length !== 1) throw new Error('AUDIT_SOURCE_NOT_RESOLVED:' + port.sourceRef);
      const document = JSON.parse(Buffer.from(source[0].content_bytes.base64, 'base64'));
      const transformation = document.transformations.find(t => t.id === port.transformationId);
      const visit = (node, pointer = '') => {
        const form = mechanicForms.get(node.op);
        if (!form) throw new Error('AUDIT_MECHANIC_NOT_RESOLVED:' + node.op);
        if (node.op === 'let') for (const name of Object.keys(node.bindings)) row.declaredBindings.push({ transformationId: transformation.id, sourcePointer: pointer + '/bindings/' + name, name });
        if (typeof node.as === 'string') row.declaredIterationBindings.push({ transformationId: transformation.id, sourcePointer: pointer, name: node.as });
        for (const [key, shape] of Object.entries(form.arguments)) {
          if (!Object.hasOwn(node, key)) continue;
          const value = node[key];
          if (shape === 'semantic-expression') visit(value, pointer + '/' + key);
          if (shape === 'expression-list') value.forEach((child, index) => visit(child, pointer + '/' + key + '/' + index));
          if (shape === 'expression-map') for (const [name, child] of Object.entries(value)) visit(child, pointer + '/' + key + '/' + name);
        }
      };
      visit(transformation.expression);
    }
    const contracts = await read(path.join(base, 'body/contracts/authority.json'));
    for (const file of plan.files) {
      const absolute = path.join(root, file.relativePath);
      const content = await fs.readFile(absolute, 'utf8');
      if (digest(content) !== file.digest) throw new Error('BODY_MODIFIED_SINCE_REGRESSION:' + absolute);
      const summary = { capabilityId: row.capabilityId, scenarioId: row.scenarioId, path: absolute, lines: content.split('\n').length - 1, digest: file.digest, kind: file.relativePath.includes('/providers/sda/') ? 'COPIED_SDA_RUNTIME' : file.relativePath.includes('/contracts/') ? 'CONTRACT' : 'GENERATED_COMPOSITION', numberedExpressions: [], declaredLocals: [] };
      if (/\.(mjs|js|ts)$/.test(file.relativePath)) {
        const ast = ts.createSourceFile(absolute, content, ts.ScriptTarget.Latest, true);
        const inspect = node => {
          if (ts.isVariableDeclaration(node) && ts.isIdentifier(node.name)) {
            summary.declaredLocals.push(node.name.text);
            if (/^expression\d+$/.test(node.name.text)) {
              const invocation = node.initializer;
              const pointer = ts.isNewExpression(invocation) && ts.isStringLiteral(invocation.arguments?.[2]) ? invocation.arguments[2].text : null;
              summary.numberedExpressions.push({ name: node.name.text, sourcePointer: pointer, line: ast.getLineAndCharacterOfPosition(node.getStart(ast)).line + 1 });
              row.numberedExpressions++;
            }
            if (/^state\d+$/.test(node.name.text)) row.numberedStates++;
          }
          if (ts.isImportSpecifier(node) && /^Dependency\d+$/.test(node.name.text)) row.numberedDependencyImports++;
          ts.forEachChild(node, inspect);
        };
        inspect(ast);
        if (file.relativePath.includes('/contracts/') && file.relativePath.endsWith('.ts')) {
          const declaration = ast.statements.find(ts.isInterfaceDeclaration);
          if (declaration) {
            const schema = Object.values(contracts.contracts).find(c => (c.schema.$id ?? c.schemaRef) + '#' === file.sourcePointers[0])?.schema;
            if (schema) {
              const fields = declaration.members.filter(ts.isPropertySignature).map(m => m.name.text);
              const missingRequiredConstants = (schema.required ?? []).filter(name => Object.hasOwn(schema.properties?.[name] ?? {}, 'const') && !fields.includes(name));
              if (missingRequiredConstants.length) result.contractFindings.push({ capabilityId: row.capabilityId, scenarioId: row.scenarioId, path: absolute, type: declaration.name.text, missingRequiredConstants });
            }
          }
        }
      }
      result.files.push(summary);
    }
    row.bindingNamesSurfacedAsLocals = row.declaredBindings.filter(b => result.files.filter(f => f.scenarioId === row.scenarioId && f.kind === 'GENERATED_COMPOSITION').some(f => f.declaredLocals.includes(b.name))).length;
    result.scenarios.push(row);
  }
}
result.totals = { bodyFiles: result.files.length, distinctFileContents: new Set(result.files.map(f => f.digest)).size, scenarioBodies: result.scenarios.length,
  numberedExpressions: result.scenarios.reduce((n, s) => n + s.numberedExpressions, 0), numberedStates: result.scenarios.reduce((n, s) => n + s.numberedStates, 0),
  numberedDependencyImports: result.scenarios.reduce((n, s) => n + s.numberedDependencyImports, 0), declaredBindings: result.scenarios.reduce((n, s) => n + s.declaredBindings.length, 0),
  declaredIterationBindings: result.scenarios.reduce((n, s) => n + s.declaredIterationBindings.length, 0), contractFilesMissingRequiredConstants: result.contractFindings.length };
await fs.mkdir(path.join(root, 'evidence/review'), { recursive: true });
await fs.writeFile(path.join(root, 'evidence/review/semantic-expression-audit.json'), JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify({ totals: result.totals, scenarios: result.scenarios.map(({ declaredBindings, declaredIterationBindings, ...s }) => ({ ...s, declaredBindings: declaredBindings.length, declaredIterationBindings: declaredIterationBindings.length })) }, null, 2));
