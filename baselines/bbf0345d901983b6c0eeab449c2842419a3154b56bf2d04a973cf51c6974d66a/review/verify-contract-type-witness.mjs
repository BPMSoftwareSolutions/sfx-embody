import fs from 'node:fs/promises';
import { pathToFileURL, fileURLToPath } from 'node:url';
import path from 'node:path';
import assert from 'node:assert/strict';
import ts from 'typescript';

const here = path.dirname(fileURLToPath(import.meta.url));
const body = path.resolve(here, '../embodiments/resolve-sidefx-eligible-providers/scenarios/resolve-sidefx-eligible-providers/node/body');
const sourcePath = path.join(here, 'contract-type-witness.ts');
const source = await fs.readFile(sourcePath, 'utf8');
const program = ts.createProgram([sourcePath], { noEmit: true, strict: true, target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.NodeNext, moduleResolution: ts.ModuleResolutionKind.NodeNext, types: [] });
const diagnostics = ts.getPreEmitDiagnostics(program);
assert.equal(diagnostics.length, 0);
const module = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.ESNext } }).outputText;
const witness = await import('data:text/javascript;base64,' + Buffer.from(module).toString('base64'));
const authority = JSON.parse(await fs.readFile(path.join(body, '../evidence/authority.json'), 'utf8'));
const fixtures = JSON.parse(await fs.readFile(path.join(body, '../evidence/fixture-results.json'), 'utf8'));
const { createSchemaAdmission } = await import(pathToFileURL(path.join(body, 'providers/sda/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs')));
const admission = createSchemaAdmission(JSON.parse(await fs.readFile(path.join(body, 'contracts/authority.json'), 'utf8')));
const samples = [
  { description: 'Required constant fields omitted', contract: authority.scenario.input.contract, value: witness.incompleteRequest },
  { description: 'Non-enumerated numeric disposition accepted by generated type', contract: authority.scenario.outcome.contract,
    value: { ...fixtures.fixtures[0].actual.outcome, disposition: witness.invalidDisposition } }
];
const results = [];
for (const sample of samples) {
  let error;
  try { await admission.admit(sample.contract, sample.value); } catch (failure) { error = failure; }
  assert.equal(error?.constructor.name, 'ContractAdmissionException');
  results.push({ description: sample.description, generatedType: 'ACCEPTED', runtimeSchema: 'REJECTED', admissionMessage: error.message });
}
const result = { purpose: 'Witness of generated-type versus original-contract divergence', typeScriptDiagnostics: diagnostics.length, results };
await fs.writeFile(path.join(here, 'contract-type-witness.result.json'), JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify(result, null, 2));
