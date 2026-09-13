import path from 'node:path';
import { pathToFileURL } from 'node:url';
import Ajv2020 from 'ajv/dist/2020.js';
import fs from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { recordConsumerInputAdmission } from './consumer-authority-context.mjs';

// Schema, value, and both outcome forms are supplied by the port declaration.
export async function admitDeclaredContract(configuration, input, context) {
  const { evaluateExpression } = await import(pathToFileURL(path.join(context.sdaRoot,
    'languages/typescript/runtimes/node/semantic-transformation-evaluator.mjs')).href);
  const evaluate = expression => evaluateExpression(expression, { input, root: input });
  const validator = new Ajv2020({ strict: false, allErrors: true, validateFormats: false });
  if (configuration.inputAdmission && !validator.validate(configuration.inputAdmission, input))
    return evaluate(configuration.admissionFailureExpression);
  const catalog = evaluate(configuration.catalogExpression);
  const contractId = evaluate(configuration.contractIdExpression);
  if (configuration.admissionProvider) {
    const provider = configuration.admissionProvider;
    const file = path.resolve(context.sdaRoot, provider.module), relative = path.relative(context.sdaRoot, file);
    if (relative.startsWith('..') || path.isAbsolute(relative)) throw new Error('PROVIDER_REFERENCE_OUTSIDE_ROOT');
    const digest = 'sha256:' + createHash('sha256').update(await fs.readFile(file)).digest('hex');
    if (digest !== provider.digest) throw new Error('PROVIDER_DEFINITION_DIGEST_MISMATCH:' + provider.module);
    const module = await import(pathToFileURL(file).href);
    const admission = module[provider.export](catalog);
    const admitted = admission.admits(contractId, evaluate(configuration.valueExpression));
    if (admitted) recordConsumerInputAdmission(context, input, contractId);
    return evaluateExpression(admitted ? configuration.expression : configuration.rejectionExpression,
      { input: { carrier: input, contractId, errors: [] }, root: input });
  }
  const contract = catalog?.contracts?.[contractId];
  if (!contract?.schema) throw new Error('DECLARED_CONTRACT_NOT_FOUND:' + contractId);
  for (const [id, entry] of Object.entries(catalog.contracts)) {
    validator.addSchema(entry.schema, id);
  }
  const validate = validator.getSchema(contractId);
  const admitted = validate(evaluate(configuration.valueExpression));
  if (admitted) recordConsumerInputAdmission(context, input, contractId);
  return evaluateExpression(admitted ? configuration.expression : configuration.rejectionExpression,
    { input: { carrier: input, contractId, errors: validate.errors ?? [] }, root: input });
}
