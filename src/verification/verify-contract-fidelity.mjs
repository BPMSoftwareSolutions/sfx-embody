import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import Ajv2020 from 'ajv/dist/2020.js';
import ts from 'typescript';

const hash = value => 'sha256:' + crypto.createHash('sha256').update(value).digest('hex');
const read = async file => JSON.parse(await fs.readFile(file, 'utf8'));
const literal = value => JSON.stringify(value);
const pointerAt = (root, fragment) => fragment.split('/').filter(Boolean).reduce((v, s) => v[s.replaceAll('~1', '/').replaceAll('~0', '~')], root);

// Independent validator/compiler checks. The vector corpus is test evidence,
// never contract authority or a replacement runtime provider.
export async function verifyContractFidelity(base) {
  const catalogBytes = await fs.readFile(path.join(base, 'body/contracts/authority.json'));
  const catalog = JSON.parse(catalogBytes);
  const types = await read(path.join(base, 'evidence/contract-types.json'));
  const original = new Map(Object.values(catalog.contracts).map(c => [c.schema.$id ?? c.schemaRef, c.schema]));
  const ajv = new Ajv2020({ allErrors: true, strict: false, validateFormats: false });
  for (const [id, schema] of original) ajv.addSchema(schema, id);
  const { createScenario } = await import(pathToFileURL(path.join(base, 'body/composition.mjs')));
  const target = createScenario({ observer: { observe() {} }, clock: { now: () => new Date().toISOString() } }).contracts;
  const authority = await read(path.join(base, 'evidence/authority.json'));
  let fixtures = await read(path.join(base, 'evidence/fixture-results.json'));
  if (fixtures.scope === 'CHILD_EXECUTIONS_WITHIN_PARENT_FIXTURES') fixtures = await read(path.resolve(base, 'evidence', fixtures.parentFixtureResults));
  const pool = [];
  const collect = value => {
    pool.push(value);
    if (Array.isArray(value)) value.forEach(collect);
    else if (value && typeof value === 'object') Object.values(value).forEach(collect);
  };
  for (const f of fixtures.fixtures) {
    for (const execution of f.executions ?? []) { collect(execution.input); collect(execution.outcome); }
    if (f.actual) collect(f.actual.outcome);
  }
  const fixtureAuthority = await read(path.join(base, 'evidence/fixture-authority.json'));
  fixtureAuthority.fixtures.forEach(f => collect(f.input));
  const sourceAt = pointer => {
    const [id, fragment = ''] = pointer.split('#');
    const root = original.get(id);
    if (!root) throw new Error('CONTRACT_TEST_SOURCE_UNRESOLVED:' + pointer);
    return pointerAt(root, fragment);
  };
  const resolve = (schema, pointer) => schema.$ref ? sourceAt(new URL(schema.$ref, pointer.split('#')[0]).href) : schema;
  const samples = schema => {
    const values = [null, false, true, 0, 1, -1, 42, '', 'x', [], {}, [null], { unexpected: true }];
    if (Object.hasOwn(schema, 'const')) values.push(schema.const);
    if (schema.enum) values.push(...schema.enum);
    for (const n of [schema.minLength, schema.maxLength].filter(Number.isInteger)) for (const length of [Math.max(0, n - 1), n, n + 1]) if (length <= 10000) values.push('x'.repeat(length));
    for (const n of [schema.minimum, schema.maximum].filter(Number.isFinite)) values.push(n - 1, n, n + 1);
    return values;
  };
  const assignments = [], expectedErrors = new Set(), structuralChecks = [], runtimeChecks = [];
  let line = 1;
  const addAssignment = (type, value, rejected, label) => {
    assignments.push(`const witness${assignments.length}: ${type} = ${literal(value)}; // ${label}`);
    if (rejected) expectedErrors.add(line);
    line++;
  };
  const contractModule = type => `import(${literal('../body/contracts/index.js')}).${type}`;
  // Read target declarations through the TS checker, independently of projection IR.
  const witnessFile = path.join(base, 'evidence/contract-fidelity.witness.ts');
  for (const definition of types) {
    let schema = sourceAt(definition.sourcePointer);
    const validator = ajv.compile({ $ref: definition.sourcePointer });
    const positive = pool.find(v => v !== undefined && validator(v));
    const positives = positive === undefined ? [] : [positive];
    if (positives.length) addAssignment(contractModule(definition.typeName), positives[0], false, definition.typeName);
    schema = resolve(schema, definition.sourcePointer);
    if (!schema.properties) continue;
    for (const [name, property] of Object.entries(schema.properties)) {
      const fieldType = `${contractModule(definition.typeName)}[${literal(name)}]`;
      const fieldSchema = resolve(property, definition.sourcePointer);
      const values = Object.hasOwn(fieldSchema, 'const') ? [fieldSchema.const] : fieldSchema.enum;
      if (values) {
        for (const value of values) addAssignment(fieldType, value, false, name + ': admitted literal');
        const forbidden = ['__outside_declared_literals__', 42, null, false].find(v => !values.some(a => JSON.stringify(a) === JSON.stringify(v)));
        addAssignment(fieldType, forbidden, true, name + ': closed literal');
      }
      if (schema.required?.includes(name)) {
        // This assertion fails only when the field became optional, regardless
        // of how many other required members the object contains.
        assignments.push(`const witness${assignments.length}: {} extends Pick<${contractModule(definition.typeName)}, ${literal(name)}> ? false : true = true;`);
        line++;
      }
      if (fieldSchema.type && !Array.isArray(fieldSchema.type) && fieldSchema.type !== 'null') addAssignment(fieldType, null, true, name + ': not nullable');
      if (Array.isArray(fieldSchema.type) && fieldSchema.type.includes('null')) addAssignment(fieldType, null, false, name + ': nullable');
    }
    structuralChecks.push({ typeName: definition.typeName, sourcePointer: definition.sourcePointer, positiveWitness: positives.length > 0 });
  }
  await fs.writeFile(witnessFile, assignments.join('\n') + '\n');
  const program = ts.createProgram([witnessFile], { noEmit: true, strict: true, exactOptionalPropertyTypes: true, target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.NodeNext, moduleResolution: ts.ModuleResolutionKind.NodeNext, types: [] });
  const diagnostics = ts.getPreEmitDiagnostics(program);
  const diagnosticLine = d => d.file && path.resolve(d.file.fileName) === path.resolve(witnessFile) && d.start !== undefined ? d.file.getLineAndCharacterOfPosition(d.start).line + 1 : -1;
  const observedErrors = new Set(diagnostics.map(diagnosticLine));
  const unexpected = [...observedErrors].filter(l => !expectedErrors.has(l));
  const missed = [...expectedErrors].filter(l => !observedErrors.has(l));
  // The actual emitted runtime admission is compared with independent canonical
  // validation for I/O values and mutations at every populated nested location.
  const cases = [];
  for (const [contractId, entry] of Object.entries(catalog.contracts)) {
    const validator = ajv.getSchema(entry.schema.$id ?? entry.schemaRef);
    const valid = pool.find(v => v !== undefined && validator(v));
    const vectors = samples(entry.schema);
    if (valid !== undefined) {
      vectors.push(valid);
      const mutate = (value, route = []) => {
        if (value === null || typeof value !== 'object') return;
        const replace = replacement => {
          const copy = structuredClone(valid);
          if (!route.length) return replacement;
          const parent = route.slice(0, -1).reduce((v, key) => v[key], copy);
          parent[route.at(-1)] = replacement;
          return copy;
        };
        if (Array.isArray(value)) {
          vectors.push(replace([]), replace([...value, ...value]));
          if (value.length) { vectors.push(replace(value.slice(1))); mutate(value[0], [...route, 0]); }
          return;
        }
        vectors.push(replace({ ...value, __additional_contract_test__: true }));
        for (const [key, child] of Object.entries(value)) {
          const removed = { ...value }; delete removed[key]; vectors.push(replace(removed));
          for (const bad of [null, 42, '__outside_declared_literals__', [], {}]) vectors.push(replace({ ...value, [key]: bad }));
          mutate(child, [...route, key]);
        }
      };
      mutate(valid);
    }
    const unique = [...new Map(vectors.map(v => [JSON.stringify(v), v])).values()];
    let accepted = 0, rejected = 0;
    for (const value of unique) {
      const canonical = Boolean(validator(value));
      let physical = true;
      try { await target.admit({ contractId }, structuredClone(value)); }
      catch (error) { if (error.constructor.name !== 'ContractAdmissionException') throw error; physical = false; }
      assert.equal(physical, canonical, 'CONTRACT_ADMISSION_PARITY:' + contractId);
      canonical ? accepted++ : rejected++;
    }
    cases.push({ contractId, vectors: unique.length, accepted, rejected, positiveCoverage: accepted > 0 });
  }
  runtimeChecks.push(...cases);
  const result = {
    scenarioId: authority.scenario.scenarioId, catalogDigest: hash(catalogBytes),
    staticChecks: { assignments: assignments.length, expectedRejections: expectedErrors.size, unexpectedErrorLines: unexpected, missedRejectionLines: missed,
      diagnostics: diagnostics.filter(d => !expectedErrors.has(diagnosticLine(d))).map(d => ts.flattenDiagnosticMessageText(d.messageText, '\n')) },
    structuralChecks, runtimeChecks,
    disposition: unexpected.length || missed.length ? 'FAILED' : 'CHECKED_VECTORS_PASSED',
    scope: 'Original-schema runtime admission plus native structural type witnesses. Predicate constraints (including cardinality, additional properties, and conditional variants) are enforced at runtime; TypeScript alone does not encode them.',
    limitations: ['Finite vectors are not universal proof.', 'Contracts without positive coverage remain unproven.', 'Schema format annotations follow the selected provider strict:false behavior.']
  };
  await fs.writeFile(path.join(base, 'evidence/contract-fidelity.json'), JSON.stringify(result, null, 2) + '\n');
  assert.equal(result.disposition, 'CHECKED_VECTORS_PASSED', JSON.stringify(result.staticChecks));
  return { assignments: assignments.length, expectedRejections: expectedErrors.size, runtimeVectors: cases.reduce((n, c) => n + c.vectors, 0), contracts: cases.length, missingPositiveCoverage: cases.filter(c => !c.positiveCoverage).map(c => c.contractId) };
}
