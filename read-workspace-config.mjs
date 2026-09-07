import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export async function readWorkspaceConfig(file = fileURLToPath(new URL('./regression.cases.json', import.meta.url))) {
  const configFile = path.resolve(file);
  const config = JSON.parse((await fs.readFile(configFile, 'utf8')).replace(/^\uFEFF/, ''));
  return {
    ...config,
    databaseRoot: path.resolve(path.dirname(configFile), config.databaseRoot),
    sdaRoot: path.resolve(path.dirname(configFile), config.sdaRoot),
  };
}
