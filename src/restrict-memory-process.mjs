import path from 'node:path';
import childProcess from 'node:child_process';
import { syncBuiltinESMExports } from 'node:module';
import { createHash } from 'node:crypto';

// Storage proof controls for this candidate provider, not a hostile-code sandbox.
// Credential lookup finishes before this boundary. Thereafter only the planner's
// read-only platform revision read and checked, declared consumer providers may
// leave the Node process. General child-process calls remain unavailable.
export function restrictMemoryProcess({ databaseRoot, sdaRoot }) {
  if (!process.permission || process.permission.has('fs.write')) throw new Error('FILESYSTEM_WRITES_MUST_BE_DISABLED');
  const forbidden = [path.resolve('embodiments'), path.join(databaseRoot, 'data')];
  if (forbidden.some(root => process.permission.has('fs.read', root))) throw new Error('CAPABILITY_CACHE_READS_MUST_BE_DISABLED');
  const childCalls = [];
  const execFileSync = childProcess.execFileSync;
  const spawn = childProcess.spawn;
  const patterns = [
    ['rev-parse', 'HEAD']
  ];
  childProcess.execFileSync = (file, args, options) => {
    if (file !== 'git' || path.resolve(options?.cwd ?? '.') !== path.resolve(sdaRoot)
      || !patterns.some(pattern => pattern.length === args?.length && pattern.every((value, i) =>
        value === null ? /^[0-9a-f]{40}$/.test(args[i]) : value === args[i]))) throw new Error('CHILD_COMMAND_UNBOUND');
    childCalls.push({ executable: file, args, cwd: options.cwd });
    return execFileSync(file, args, { ...options, windowsHide: true, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  };
  for (const method of ['exec', 'execSync', 'execFile', 'spawn', 'spawnSync', 'fork']) {
    childProcess[method] = () => { throw new Error('CHILD_PROCESS_UNBOUND:' + method); };
  }
  syncBuiltinESMExports();
  const evidence = { fsWriteAllowed: false, expandedBodyReadAllowed: false, databaseCacheReadAllowed: false, childCalls };
  // Only the provider reader receives this function, after validating the source
  // and every dependency against database authority. It is not an input field.
  Object.defineProperty(evidence, 'spawnDeclared', { value: (file, args, options) => {
    if (options?.shell !== false || path.resolve(options.cwd) !== path.resolve(sdaRoot))
      throw new Error('CHILD_COMMAND_UNBOUND');
    childCalls.push({ executable: file, argumentsDigest: 'sha256:' + createHash('sha256').update(JSON.stringify(args)).digest('hex'), cwd: options.cwd });
    return spawn(file, args, { ...options, windowsHide: true });
  } });
  return evidence;
}
