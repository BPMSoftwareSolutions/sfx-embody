import path from 'node:path';
import { pathToFileURL } from 'node:url';

export async function readCircuitMedia(databaseRoot, selection) {
  const { readWorkbench } = await import(pathToFileURL(path.join(databaseRoot, 'src/media/read-workbench.mjs')));
  return readWorkbench(selection);
}
