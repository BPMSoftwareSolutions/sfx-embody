import path from 'node:path';
import { pathToFileURL } from 'node:url';

// The CLI provider declares the execution capability and its carrier mappings.
// The authority reader declares the default target. Neither is chosen here.
export async function readExecutionDelivery(context) {
  const query = context.readQuery ?? (await import(pathToFileURL(path.join(context.databaseRoot, 'src/query/run.mjs')).href)).query;
  const result = await query(`SELECT declared_id AS provider_id,
    JSON_QUERY(definition_json,'$.semantics.executionDelivery') AS configuration
    FROM analysis.v_selected_semantic_definition
    WHERE estate_model_pk=@estate_model_pk AND object_kind='PROVIDER'
      AND JSON_QUERY(definition_json,'$.semantics.executionDelivery') IS NOT NULL;
    SELECT JSON_VALUE(definition_json,'$.semantics.configuration.defaultTarget') AS default_target
    FROM analysis.v_selected_semantic_definition
    WHERE estate_model_pk=@estate_model_pk AND object_kind='PORT'
      AND namespace_id='sidefx:capability:read-capability-authority'
      AND declared_id='read-capability-authority-port';`, { retainObjects: false, rowLimit: 100 });
  if (result.truncated || result.recordsets[0].length !== 1 || result.recordsets[1].length !== 1)
    throw new Error('EXECUTION_DELIVERY_NOT_RESOLVED');
  const declaration = JSON.parse(result.recordsets[0][0].configuration);
  const defaultTarget = result.recordsets[1][0].default_target;
  if (typeof declaration.capabilityId !== 'string' || !declaration.requestExpression || !declaration.resultExpression
      || typeof defaultTarget !== 'string' || !defaultTarget) throw new Error('EXECUTION_DELIVERY_NOT_RESOLVED');
  return { ...declaration, defaultTarget, providerId: result.recordsets[0][0].provider_id,
    snapshotId: result.snapshotId, projectionDigest: result.projectionDigest, viewDefinitionDigest: result.viewDefinitionDigest };
}
