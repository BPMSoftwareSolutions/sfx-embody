import crypto from 'node:crypto';
import path from 'node:path';
import traverseSchema from 'json-schema-traverse';
import { NativeExpressionProjection } from './native-expression-projection.mjs';

const digest = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
const identifier = value => value.split(/[^A-Za-z0-9]+/).filter(Boolean).map(x => x[0].toUpperCase() + x.slice(1)).join('');
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
 * Pure expressions lower into native syntax; native helpers retain the selected
 * provider's implementation. The candidate requires independent conformance.
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
      // Deliberately open positions admit any value at runtime; the type graph
      // has no declared shape to project. An item-less array becomes unknown[],
      // an object without properties loses its object typing so the planner can
      // map it to Record<string, unknown>. The original schema bytes remain the
      // runtime admission authority either way.
      if (node.type === 'array' && (!node.items || typeof node.items !== 'object' || Array.isArray(node.items))) {
        node.items = {};
        changes.push({ sourcePointer, from: 'open-array', to: 'unknown-item-projection' });
      }
      if (node.type === 'object') {
        const properties = node.properties;
        const open = properties === undefined || (typeof properties === 'object' && !Array.isArray(properties) && Object.keys(properties).length === 0);
        // A contract root must remain an object type for the target graph; its
        // open shape projects as an interface without declared fields. Nested
        // open objects have no declared shape to project and become unknown.
        if (open && sourcePointer !== '') {
          delete node.type;
          changes.push({ sourcePointer, from: 'open-object', to: 'unknown-projection' });
        }
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

  static renderContracts(graph, profile, structuralProvider, typescript, canonical, schemaAt, openObjectPointers) {
    const definitions = new Map(canonical.definitions.map(d => [d.sourcePointer, d.node]));
    const visit = node => {
      if (node.kind === 'nullable') { visit(node.value); return; }
      definitions.set(node.sourcePointer, node);
      if (node.kind === 'object') node.properties.forEach(p => visit(p.value));
      if (node.kind === 'array') visit(node.item);
    };
    canonical.definitions.forEach(d => visit(d.node));
    // Refine the existing SDA target graph at its Node boundary. Constant
    // declarations are also instance members; enum values are closed literals.
    // Runtime-only predicates remain enforced by the original schema admission.
    const refine = (node, fallback, seen = new Set()) => {
      if (openObjectPointers?.has(node.sourcePointer)) return 'Record<string, unknown>';
      const schema = schemaAt(node.sourcePointer);
      if (Object.hasOwn(schema, 'const')) return JSON.stringify(schema.const);
      if (schema.enum) return schema.enum.map(value => JSON.stringify(value)).join(' | ');
      if (node.kind === 'reference') {
        if (seen.has(node.targetPointer)) return fallback;
        return refine(definitions.get(node.targetPointer), fallback, new Set([...seen, node.targetPointer]));
      }
      if (node.kind === 'nullable') return `(${refine(node.value, fallback.replace(/ \| null$/, ''), seen)}) | null`;
      if (node.kind === 'array') {
        const itemType = fallback.endsWith('[]') ? fallback.slice(0, -2) : 'unknown';
        return `(${refine(node.item, itemType, seen)})[]`;
      }
      return fallback;
    };
    graph = { ...graph, definitions: graph.definitions.map(definition => {
      if (definition.kind !== 'object') return definition;
      const node = definitions.get(definition.sourcePointer);
      if (node?.kind !== 'object') throw new Error('CONTRACT_OBJECT_SHAPE_NOT_PRESERVED:' + definition.sourcePointer);
      const fields = node.properties.map(property => {
        const existing = definition.fields.find(field => field.sourcePointer === property.sourcePointer);
        if (!existing && property.constantValue === undefined) throw new Error('CONTRACT_FIELD_PROJECTION_MISSING:' + property.sourcePointer);
        return { ...(existing ?? { name: property.name, type: JSON.stringify(property.constantValue), dependencies: [], sourcePointer: property.sourcePointer }),
          optional: !property.required, type: refine(property.value, existing?.type ?? JSON.stringify(property.constantValue)) };
      });
      return { ...definition, fields };
    }) };
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
    plan.contractTypes = graph.definitions.map(d => ({ typeName: d.typeName, sourcePointer: d.sourcePointer,
      fields: d.kind === 'object' ? d.fields : undefined }));
    return plan;
  }

  constructor({ typescript, mechanicSource, mechanicSourceRef, mechanicExport, mechanicDeclarations, provenance, resolvedTransformationPorts, effectPorts = [] }) {
    this.ts = typescript;
    this.source = mechanicSource;
    this.sourceRef = mechanicSourceRef;
    this.sourceDigest = digest(mechanicSource);
    this.provenance = provenance;
    this.resolvedTransformationPorts = resolvedTransformationPorts;
    // Effects are declared platform ports, not transformations. Each entry names
    // the pinned provider module that implements it. The candidate resolves them
    // from authority like any other mechanic; nothing is selected by port name.
    this.effectPorts = new Map(effectPorts.map(port => [port.platformCapabilityId, port]));
    this.emittedImports = new Set();
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
      const dependencies = [], statements = [], helpers = new Set(), resultNames = new Set(['input']);
      let state = 'input';
      for (const [ordinal, operation] of authority.operations.entries()) {
        const responsibilityId = operation.portId ?? scenarios.find(s => s.scenarioId === operation.scenarioId)?.outcome.outcomeId;
        let next = identifier(responsibilityId);
        next = next[0].toLowerCase() + next.slice(1) + 'Result';
        while (resultNames.has(next)) next += '$occurrence';
        resultNames.add(next);
        if (operation.kind === 'invoke-port') {
          const binding = interfaceAuthority.portBindings.find(p => p.portId === operation.portId);
          if (!binding) throw new Error('PORT_IMPLEMENTATION_NOT_RESOLVED:' + operation.portId);
          const effect = this.effectPorts.get(binding.platformCapabilityId);
          if (effect) {
            // A declared effect port. The pinned provider module is carried into
            // the body from the registry, and the port configuration is the
            // authority-declared data it runs with. The shared governed effect
            // context is what lets one port's opaque credential binding reach the
            // exchange that consumes it without either leaving the boundary.
            const module = `providers/${physicalSegment(operation.portId)}.mjs`;
            const providerImport = './sda/' + effect.providerModule;
            output(`${base}/${module}`,
              `import { ${effect.providerExport} } from ${JSON.stringify(providerImport)};\n\n` +
              `const configuration = ${dataLiteral(binding.configuration ?? {})};\n\n` +
              `export class ${identifier(operation.portId)} {\n  constructor(effectContext) {\n    this.effectContext = effectContext;\n  }\n\n` +
              `  execute(input, root, context) {\n    return ${effect.providerExport}(configuration, input, context, this.effectContext);\n  }\n}\n`,
              [this.provenance.interfaceSourceRef]);
            dependencies.push({ id: operation.portId, module: './' + module, className: identifier(operation.portId), kind: 'invoke-effect' });
            statements.push(`    const ${next} = await this.dependencies[${JSON.stringify(operation.portId)}].execute(${state}, root, context, this.effectContext);`);
          } else {
            const provenance = this.provenance.ports[operation.portId];
            if (!provenance || !binding.configuration?.expression) throw new Error('PORT_IMPLEMENTATION_NOT_RESOLVED:' + operation.portId);
            const transformation = { ...provenance, expression: binding.configuration.expression };
            if (!this.resolvedTransformationPorts.includes(binding.platformCapabilityId)) throw new Error('PORT_PROVIDER_NOT_SELECTED:' + operation.portId);
            const lowering = new NativeExpressionProjection(this.ts, this.mechanics, this.bodies);
            const expression = lowering.emit(transformation.expression);
            const nodes = lowering.nodes;
            nodes.forEach(n => { n.providerSourceRef = this.sourceRef; });
            lowering.helpers.forEach(helper => helpers.add(helper));
            const module = `providers/${physicalSegment(operation.portId)}.mjs`;
            output(`${base}/${module}`, `// Generated from ${transformation.sourceRef}; ${transformation.sourceDigest}\n` +
              (lowering.helpers.size ? `import { ${[...lowering.helpers].sort().join(', ')} } from './native-mechanics.mjs';\n\n` : '') +
              `export class ${identifier(operation.portId)} {\n  execute(input, root = input) {\n    return ${expression};\n  }\n}\n`, [transformation.sourceRef]);
            dependencies.push({ id: operation.portId, module: './' + module, className: identifier(operation.portId), kind: operation.kind });
            statements.push(`    const ${next} = await this.dependencies[${JSON.stringify(operation.portId)}].execute(${state}, root);`);
            lineage.push({ scenarioId: scenario.scenarioId, operationOrdinal: ordinal, portId: operation.portId,
              transformationId: transformation.id, sourceRef: transformation.sourceRef, sourceDigest: transformation.sourceDigest,
              physicalFile: `${base}/${module}`, bindings: lowering.bindings, helpers: [...lowering.helpers], nodes });
          }
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
      const required = new Set(helpers);
      const scan = text => {
        const ast = this.ts.createSourceFile('body.mjs', text, this.ts.ScriptTarget.Latest, true);
        const visit = node => { if (this.ts.isIdentifier(node)) required.add(node.text); this.ts.forEachChild(node, visit); };
        visit(ast);
      };
      let prior;
      do {
        prior = required.size;
        for (const s of this.preludeStatements) if (s.name && required.has(s.name.text)) scan(s.getText());
      } while (required.size !== prior);
      // Every module specifier the helper module carries is recorded so the
      // materializer can hold when one does not resolve inside the body it built.
      for (const s of this.preludeStatements) if (this.ts.isImportDeclaration(s)) this.emittedImports.add(s.moduleSpecifier.text);
      const prelude = this.preludeStatements.filter(s => this.ts.isImportDeclaration(s) || (s.name && required.has(s.name.text))).map(s => s.getText()).join('\n');
      output(`${base}/providers/native-mechanics.mjs`, `// Native helpers from ${this.sourceRef}; ${this.sourceDigest}\n` + prelude +
        `\nexport { ${[...helpers].sort().join(', ')} };\n`, [this.sourceRef]);
      // The Scenario's own admitted input is the root of every transformation it
      // invokes. Binding it here gives root one meaning at every depth and every
      // ordinal: a port after a child Scenario sees the same root as a port at
      // ordinal zero, and a child Scenario's root is its own input, which is what
      // invoke already establishes when it sets rootInput. Taking it from the
      // admitted input rather than from caller-supplied context also removes the
      // last place where a caller could supply a different object, so root is
      // never a clone of input in one position and input itself in another.
      const rootBinding = dependencies.some(d => d.kind === 'invoke-port' || d.kind === 'invoke-effect') ? '    const root = input;\n' : '';
      const scenarioClass = identifier(scenario.scenarioId) + 'Scenario';
      const declaration = dataLiteral(scenario);
      const content = `// Generated from database-retained Scenario and execution authority.\n` +
        `import { ScenarioKernel } from './providers/sda/languages/typescript/dist/src/kernel/scenario-kernel.js';\n` +
        `import { DispositionResolver } from './providers/sda/languages/typescript/dist/src/kernel/disposition-resolver.js';\n\n` +
        `const declaration = ${declaration};\n\nexport class ${scenarioClass} {\n` +
        `  static capabilityId = ${JSON.stringify(capabilityId)};\n  static scenarioId = ${JSON.stringify(scenario.scenarioId)};\n` +
        `  constructor(dependencies, contracts, observer, clock, effectContext) {\n    this.dependencies = dependencies;\n    this.contracts = contracts;\n    this.observer = observer;\n    this.clock = clock;\n    this.effectContext = effectContext;\n  }\n\n` +
        `  async perform(input, context) {\n${rootBinding}${statements.join('\n')}\n    return ${state};\n  }\n\n` +
        `  async execute(input, context) {\n    const kernel = new ScenarioKernel(this.contracts, {\n      async resolve(event) {\n        if (event.executionAuthorityId !== declaration.event.executionAuthorityId) throw new Error('EXECUTION_AUTHORITY_DIVERGENCE');\n        return { executionAuthorityId: event.executionAuthorityId, handler: declaration.event };\n      }\n    }, { execute: async (_authority, value) => this.perform(value, context) }, new DispositionResolver(), this.observer, this.clock);\n` +
        `    const execution = await kernel.execute(declaration, { ...context, input });\n    context.collect?.(execution);\n    return execution;\n  }\n\n` +
        `  async invoke(input, parent, ordinal) {\n    const ancestry = parent.ancestry ?? [];\n    if (ancestry.includes(declaration.scenarioId)) throw new Error('RECURSIVE_SCENARIO_INVOCATION');\n    const execution = await this.execute(input, { ...parent,\n      executionId: parent.executionId + '/' + ordinal + '/' + declaration.scenarioId,\n      rootInput: structuredClone(input), parentExecutionId: parent.executionId, ancestry: [...ancestry, declaration.scenarioId]\n    });\n    if (execution.disposition === 'failed' || execution.disposition === 'rejected') throw new Error('CHILD_SCENARIO_' + execution.disposition.toUpperCase());\n    return execution.outcome;\n  }\n}\n`;
      output(`${base}/scenario.mjs`, content, [this.provenance.scenarioSourceRef, this.provenance.executionSourceRef]);
      output(`${base}/dependencies.json`, JSON.stringify(dependencies, null, 2) + '\n', [this.provenance.executionSourceRef, this.provenance.interfaceSourceRef]);
    }
    this.lineage = lineage;
    return files;
  }

}
