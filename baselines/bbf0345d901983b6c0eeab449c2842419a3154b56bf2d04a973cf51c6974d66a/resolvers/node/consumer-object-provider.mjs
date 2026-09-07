import crypto from 'node:crypto';
import path from 'node:path';
import traverseSchema from 'json-schema-traverse';

const digest = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
const identifier = value => value.split(/[^A-Za-z0-9]+/).filter(Boolean).map(x => x[0].toUpperCase() + x.slice(1)).join('');
const pointer = value => value.replaceAll('~', '~0').replaceAll('/', '~1');
const dataLiteral = value => {
  if (Array.isArray(value)) return '[\n' + value.map(dataLiteral).join(',\n') + '\n]';
  if (value && typeof value === 'object') return '{\n' + Object.entries(value).map(([key, member]) => `[${JSON.stringify(key)}]: ${dataLiteral(member)}`).join(',\n') + '\n}';
  return JSON.stringify(value);
};
const physicalSegment = value => {
  if (typeof value !== 'string' || !value || value === '.' || value === '..') throw new Error('INVALID_PHYSICAL_ID_SEGMENT');
  return encodeURIComponent(value);
};

/** Node implementation of SDA's ConsumerApplicationProvider render protocol.
 * Candidate physical projection provider; no semantic authority is authored here.
 * Native mechanic methods are extracted unchanged from the selected provider.
 */
export class NodeConsumerObjectProvider {
  target = 'node';

  // A derived type-projection view for SDA's existing nullable IR form. The
  // original schema bytes remain the runtime admission authority.
  static schemaForTypeProjection(authority, sourceRef) {
    const schema = structuredClone(authority), changes = [];
    traverseSchema(schema, { cb: { post(node, sourcePointer) {
      if (sourcePointer && node.$id) throw new Error('NESTED_SCHEMA_ID_PROJECTION_NOT_SUPPORTED:' + sourcePointer);
      if (typeof node.$ref === 'string' && !node.$ref.startsWith('#')) {
        const original = node.$ref;
        if (authority.$id) node.$ref = new URL(original, authority.$id).href;
        else node.$ref = path.posix.normalize(path.posix.join(path.posix.dirname(sourceRef), original));
        if (node.$ref !== original) changes.push({ sourcePointer: sourcePointer + '/$ref', from: original, to: node.$ref });
      }
      if (!Array.isArray(node.type)) return;
      if (node.type.length !== 2 || !node.type.includes('null') || node.oneOf) throw new Error('SCHEMA_TYPE_UNION_NOT_SUPPORTED:' + sourcePointer);
      const valueType = node.type.find(type => type !== 'null');
      const nonNull = { ...node, type: valueType };
      delete node.type;
      node.oneOf = [nonNull, { type: 'null' }];
      changes.push({ sourcePointer, from: [valueType, 'null'], to: 'nullable-oneOf' });
    } } });
    return { schema, changes };
  }

  static renderContracts(graph, profile, structuralProvider, typescript) {
    // Property identities are data. Quoted TypeScript property names preserve
    // punctuation; each module's constants remain in its own export namespace.
    const escaped = { ...graph, definitions: graph.definitions.map(definition => definition.kind === 'object'
      ? { ...definition, fields: definition.fields.map(field => ({ ...field, name: JSON.stringify(field.name) })) }
      : definition) };
    const plan = structuralProvider.render(escaped, profile);
    const index = plan.files.find(file => file.relativePath === 'index.ts');
    index.content = plan.files.filter(file => file !== index).map(file => {
      const ast = typescript.createSourceFile(file.relativePath, file.content, typescript.ScriptTarget.Latest, true);
      const matches = ast.statements.filter(s => typescript.isInterfaceDeclaration(s) || typescript.isTypeAliasDeclaration(s));
      if (matches.length !== 1) throw new Error('CONTRACT_MODULE_TYPE_AMBIGUOUS');
      const typeName = matches[0].name.text;
      const ref = JSON.stringify('./' + file.relativePath.replace(/\.ts$/, '.js'));
      return `export type { ${typeName} } from ${ref};\nexport * as ${typeName}Contract from ${ref};`;
    }).join('\n') + '\n';
    index.digest = digest(index.content);
    return plan;
  }

  constructor({ typescript, mechanicSource, mechanicSourceRef, mechanicExport, mechanicDeclarations, provenance, resolvedTransformationPorts }) {
    this.ts = typescript;
    this.source = mechanicSource;
    this.sourceRef = mechanicSourceRef;
    this.sourceDigest = digest(mechanicSource);
    this.provenance = provenance;
    this.resolvedTransformationPorts = resolvedTransformationPorts;
    this.mechanics = new Map();
    for (const declaration of mechanicDeclarations) {
      const operation = declaration.semantics.mechanic?.authoringForm?.operation;
      if (!operation) continue;
      if (this.mechanics.has(operation)) throw new Error('AMBIGUOUS_MECHANIC_OPERATION:' + operation);
      this.mechanics.set(operation, declaration);
    }
    const ast = typescript.createSourceFile(mechanicSourceRef, mechanicSource, typescript.ScriptTarget.Latest, true);
    const evaluator = ast.statements.find(s => typescript.isFunctionDeclaration(s) && s.name?.text === mechanicExport);
    const dispatch = evaluator?.body?.statements.find(s => typescript.isSwitchStatement(s));
    if (!dispatch) throw new Error('SELECTED_NATIVE_MECHANIC_BODY_NOT_RECOGNIZED');
    this.preludeStatements = ast.statements.filter(s => s.end < evaluator.getStart(ast));
    this.bodies = new Map();
    for (const clause of dispatch.caseBlock.clauses) {
      if (!typescript.isCaseClause(clause) || !typescript.isStringLiteral(clause.expression)) continue;
      if (!clause.statements.length) throw new Error('NATIVE_FALLTHROUGH_REQUIRES_TRANSLATION:' + clause.expression.text);
      this.bodies.set(clause.expression.text, {
        body: clause.statements.map(s => s.getText(ast)).join('\n'),
        sourceStart: clause.getStart(ast), sourceEnd: clause.end
      });
    }
  }

  render(input) {
    const { capabilityId, interfaceAuthority } = input;
    const { scenarios, executionAuthorities } = input.query.authorityGraph;
    const files = [], lineage = [];
    const names = scenarios.map(s => identifier(s.scenarioId));
    if (new Set(names).size !== names.length || names.some(n => !/^[A-Za-z_$]/.test(n))) throw new Error('NATIVE_SCENARIO_NAME_COLLISION');
    const output = (relativePath, content, sourcePointers) => files.push({
      relativePath, content, digest: digest(content), sourcePointers, target: this.target
    });
    for (const scenario of scenarios) {
      const base = `embodiments/${physicalSegment(capabilityId)}/scenarios/${physicalSegment(scenario.scenarioId)}/node/body`;
      const authority = executionAuthorities.find(a => a.id === scenario.event.executionAuthorityId);
      if (!authority) throw new Error('EXECUTION_AUTHORITY_NOT_RESOLVED:' + scenario.scenarioId);
      const dependencies = [], statements = [], used = new Set();
      let state = 'input';
      for (const [ordinal, operation] of authority.operations.entries()) {
        const next = `state${ordinal + 1}`;
        if (operation.kind === 'invoke-port') {
          const binding = interfaceAuthority.portBindings.find(p => p.portId === operation.portId);
          const provenance = this.provenance.ports[operation.portId];
          if (!binding || !provenance || !binding.configuration?.expression) throw new Error('PORT_IMPLEMENTATION_NOT_RESOLVED:' + operation.portId);
          const transformation = { ...provenance, expression: binding.configuration.expression };
          if (!this.resolvedTransformationPorts.includes(binding.platformCapabilityId)) throw new Error('PORT_PROVIDER_NOT_SELECTED:' + operation.portId);
          const nodes = [], constructions = [];
          const expression = this.expression(transformation.expression, '', used, nodes, constructions);
          const module = `providers/port-${ordinal}.mjs`;
          output(`${base}/${module}`, `// Generated from ${transformation.sourceRef}; ${transformation.sourceDigest}\n` +
            `import { Expression } from './expression.mjs';\nimport { createMechanics } from './mechanics.mjs';\n\n` +
            `export class ${identifier(operation.portId)} {\n  constructor(mechanics = createMechanics(), observe) {\n${constructions.join('\n')}\n    this.expression = ${expression};\n  }\n\n  execute(input, root = input) {\n    return this.expression.execute({ input, root });\n  }\n}\n`, [transformation.sourceRef]);
          dependencies.push({ id: operation.portId, module: './' + module, className: identifier(operation.portId), kind: operation.kind });
          statements.push(`    const ${next} = await this.dependencies[${JSON.stringify(operation.portId)}].execute(${state}, context.rootInput);`);
          lineage.push({ scenarioId: scenario.scenarioId, operationOrdinal: ordinal, portId: operation.portId,
            transformationId: transformation.id, sourceRef: transformation.sourceRef, sourceDigest: transformation.sourceDigest, nodes });
        } else if (operation.kind === 'invoke-scenario') {
          if (!scenarios.some(s => s.scenarioId === operation.scenarioId)) throw new Error('CHILD_SCENARIO_NOT_RESOLVED:' + operation.scenarioId);
          const child = `embodiments/${physicalSegment(capabilityId)}/scenarios/${physicalSegment(operation.scenarioId)}/node/body/scenario.mjs`;
          dependencies.push({ id: operation.scenarioId, module: path.posix.relative(base, child), className: identifier(operation.scenarioId) + 'Scenario', kind: operation.kind });
          statements.push(`    const ${next} = await this.dependencies[${JSON.stringify(operation.scenarioId)}].invoke(${state}, context, ${ordinal});`);
        } else {
          throw new Error('NATIVE_OPERATION_TRANSLATION_NOT_AVAILABLE:' + operation.kind);
        }
        state = next;
      }
      const nativeBodies = [...used].sort().map(operation => {
        const source = this.bodies.get(operation);
        return `// ${operation}; ${this.sourceRef}:${source.sourceStart}-${source.sourceEnd}\n` +
          `export class ${identifier(operation)}Mechanic {\n  execute(expression, scope, evaluate) {\n${source.body.split('\n').map(l => '    ' + l).join('\n')}\n  }\n}\n`;
      }).join('\n');
      const required = new Set();
      const scan = text => {
        const ast = this.ts.createSourceFile('body.mjs', text, this.ts.ScriptTarget.Latest, true);
        const visit = node => { if (this.ts.isIdentifier(node)) required.add(node.text); this.ts.forEachChild(node, visit); };
        visit(ast);
      };
      scan(nativeBodies);
      let prior;
      do {
        prior = required.size;
        for (const s of this.preludeStatements) if (s.name && required.has(s.name.text)) scan(s.getText());
      } while (required.size !== prior);
      const prelude = this.preludeStatements.filter(s => this.ts.isImportDeclaration(s) || (s.name && required.has(s.name.text))).map(s => s.getText()).join('\n');
      output(`${base}/providers/mechanics.mjs`, `// Native bodies specialized from ${this.sourceRef}; ${this.sourceDigest}\n` + prelude + '\n' + nativeBodies +
        `\nexport const createMechanics = () => ({\n${[...used].sort().map(op => `  [${JSON.stringify(op)}]: new ${identifier(op)}Mechanic()`).join(',\n')}\n});\n`, [this.sourceRef]);
      output(`${base}/providers/expression.mjs`, `// Resolver-internal object invocation; semantic identities remain in the declaration.\nexport class Expression {\n  constructor(mechanic, parameters, sourcePointer, observe) {\n    this.mechanic = mechanic;\n    this.parameters = parameters;\n    this.sourcePointer = sourcePointer;\n    this.observe = observe;\n  }\n  execute(scope) {\n    this.observe?.({ sourcePointer: this.sourcePointer, mechanic: this.mechanic.constructor.name });\n    return this.mechanic.execute(this.parameters, scope, (child, nextScope = scope) => child.execute(nextScope));\n  }\n}\n`, [this.sourceRef]);
      const scenarioClass = identifier(scenario.scenarioId) + 'Scenario';
      const declaration = dataLiteral(scenario);
      const content = `// Generated from database-retained Scenario and execution authority.\n` +
        `import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';\n` +
        `import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';\n\n` +
        `const declaration = ${declaration};\n\nexport class ${scenarioClass} {\n` +
        `  static scenarioId = ${JSON.stringify(scenario.scenarioId)};\n` +
        `  constructor(dependencies, contracts, observer, clock) {\n    this.dependencies = dependencies;\n    this.contracts = contracts;\n    this.observer = observer;\n    this.clock = clock;\n  }\n\n` +
        `  async perform(input, context) {\n${statements.join('\n')}\n    return ${state};\n  }\n\n` +
        `  async execute(input, context) {\n    const kernel = new ScenarioKernel(this.contracts, {\n      async resolve(event) {\n        if (event.executionAuthorityId !== declaration.event.executionAuthorityId) throw new Error('EXECUTION_AUTHORITY_DIVERGENCE');\n        return { executionAuthorityId: event.executionAuthorityId, handler: declaration.event };\n      }\n    }, { execute: async (_authority, value) => this.perform(value, context) }, new DispositionResolver(), this.observer, this.clock);\n` +
        `    const execution = await kernel.execute(declaration, { ...context, input });\n    context.collect?.(execution);\n    return execution;\n  }\n\n` +
        `  async invoke(input, parent, ordinal) {\n    const ancestry = parent.ancestry ?? [];\n    if (ancestry.includes(declaration.scenarioId)) throw new Error('RECURSIVE_SCENARIO_INVOCATION');\n    const execution = await this.execute(input, { ...parent,\n      executionId: parent.executionId + '/' + ordinal + '/' + declaration.scenarioId,\n      rootInput: structuredClone(input), parentExecutionId: parent.executionId, ancestry: [...ancestry, declaration.scenarioId]\n    });\n    if (execution.disposition === 'failed' || execution.disposition === 'rejected') throw new Error('CHILD_SCENARIO_' + execution.disposition.toUpperCase());\n    return execution.outcome;\n  }\n}\n`;
      output(`${base}/scenario.mjs`, content, [this.provenance.scenarioSourceRef, this.provenance.executionSourceRef]);
      output(`${base}/dependencies.json`, JSON.stringify(dependencies, null, 2) + '\n', [this.provenance.executionSourceRef, this.provenance.interfaceSourceRef]);
    }
    this.lineage = lineage;
    return files;
  }

  expression(value, location, used, nodes, constructions) {
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('EXPRESSION_BODY_NOT_DECLARED:' + location);
    const declaration = this.mechanics.get(value.op), native = this.bodies.get(value.op);
    if (!declaration || !native) throw new Error('MECHANIC_BODY_NOT_RESOLVED:' + value.op);
    used.add(value.op);
    nodes.push({ sourcePointer: location, mechanicId: declaration.address.id, operation: value.op,
      providerSourceRef: this.sourceRef, providerSourceStart: native.sourceStart, providerSourceEnd: native.sourceEnd });
    const form = declaration.semantics.mechanic.authoringForm;
    const argumentsByName = form.arguments;
    for (const key of form.required ?? []) if (!Object.hasOwn(value, key)) throw new Error('MECHANIC_ARGUMENT_MISSING:' + value.op + ':' + key);
    const fields = Object.entries(value).filter(([key]) => key !== 'op').map(([key, member]) => {
      const at = location + '/' + pointer(key), shape = argumentsByName[key];
      if (!shape) throw new Error('MECHANIC_ARGUMENT_NOT_DECLARED:' + value.op + ':' + key);
      let body;
      if (shape === 'semantic-expression') body = this.expression(member, at, used, nodes, constructions);
      else if (shape === 'expression-map') body = '{\n' + Object.entries(member).map(([name, child]) => '[' + JSON.stringify(name) + ']: ' + this.expression(child, at + '/' + pointer(name), used, nodes, constructions)).join(',\n') + '\n}';
      else if (shape === 'expression-list') body = '[' + member.map((child, index) => this.expression(child, at + '/' + index, used, nodes, constructions)).join(', ') + ']';
      else body = dataLiteral(member);
      return '[' + JSON.stringify(key) + ']: ' + body;
    });
    const variable = `expression${constructions.length}`;
    constructions.push(`    const ${variable} = new Expression(mechanics[${JSON.stringify(value.op)}], {${fields.join(', ')}}, ${JSON.stringify(location)}, observe);`);
    return variable;
  }
}
