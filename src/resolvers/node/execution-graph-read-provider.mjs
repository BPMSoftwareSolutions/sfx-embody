import { pathToFileURL } from 'node:url';
import path from 'node:path';
import Ajv from 'ajv';
import { readExecutionGraph } from '../../read-execution-graph.mjs';

export async function readDeclaredExecutionGraph(configuration, input, context) {
  if (configuration.inputAdmission && !new Ajv({ strict: false }).validate(configuration.inputAdmission, input))
    return structuredClone(configuration.admissionFailure);
  let read;
  const declaration = configuration.inputField
    ? configuration.inputField.split('.').reduce((value, key) => value?.[key], input) : input;
  try { read = await readExecutionGraph(declaration, context.sdaRoot); }
  catch (error) {
    const declared = configuration.errors?.find(entry => typeof entry.prefix === 'string' && entry.prefix.length > 0
      && error.message.startsWith(entry.prefix));
    if (!declared) throw error;
    return structuredClone(declared.outcome);
  }
  const { evaluateExpression } = await import(pathToFileURL(path.join(context.sdaRoot,
    'languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs')).href);
  return evaluateExpression(configuration.expression, { input: { declaration, carrier: input, ...read }, root: input });
}
