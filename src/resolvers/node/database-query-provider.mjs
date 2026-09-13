// Read the SQL statement carried by the port declaration. SQL Server's
// restricted query runner owns model selection and enforces the read boundary.
// The statement, result contract and field selection are declaration data.
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export async function readDatabaseQuery(configuration, input, context) {
  const query = context.readQuery ?? (await import(pathToFileURL(path.join(context.databaseRoot, 'src/query/run.mjs')))).query;
  const result = await query(configuration.statement, { input, rowLimit: 1, retainObjects: false });
  if (result.truncated || result.recordsets.length !== 1 || result.recordsets[0].length !== 1)
    throw new Error('DATABASE_AUTHORITY_NOT_COHERENT');
  return JSON.parse(result.recordsets[0][0][configuration.resultColumn]);
}
