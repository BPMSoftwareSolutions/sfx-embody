import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { readWorkspaceConfig } from '../read-workspace-config.mjs';
const config = await readWorkspaceConfig();
const { query } = await import(pathToFileURL(path.join(config.databaseRoot, 'src/query/run.mjs')));
const input = JSON.parse(await fs.readFile(new URL('../second-root.input.json', import.meta.url), 'utf8'));
const result = await query(`SELECT definition_json FROM analysis.v_selected_semantic_definition
  WHERE estate_model_pk=@estate_model_pk AND object_kind='SCENARIO'
  AND JSON_VALUE(definition_json,'$.address.id')=JSON_VALUE(@input,'$.scenarioId')`, { input, rowLimit: 100000 });
await fs.writeFile(new URL('./scenario-round-trip-authority.json', import.meta.url), JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify(result.recordsets[0].map(r => JSON.parse(r.definition_json)), null, 2));
