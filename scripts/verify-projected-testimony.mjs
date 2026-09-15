// Verification probe for projected-testimony parity (F1/F2 closure).
//
//   node scripts/verify-projected-testimony.mjs [--projected <dir>] [--fixture <id>]
//     [--python <exe>] [--timeout-ms N] [--expect-closed]
//
// Runs each target's committed projected body on the declared fixture (one
// process per target, no retry) and checks the executed testimony for the
// closure criteria of docs/sda-change-request-projected-testimony.md:
//
//   1. every cell / edge / pattern testimony record carries the kernel's
//      timing fields: durationMilliseconds, startedAt, completedAt (validated,
//      never synthesized);
//   2. graphExecution.observedPathDigest is present, non-null and equal across
//      targets for the identical declared-fixture execution;
//   3. graphExecution.resolverTestimony is present in every target;
//   4. every observed cellId is a canonical cell id (canonicalGraph.cells of
//      the target's consumer-execution-plan.<target>.v3.json), and for an
//      identical declared-fixture execution the observed cell-id sets (and
//      per-cell occurrence counts) are equal across targets.
//
// The declaration itself never depends on a successful exchange: an outcome of
// EQUITY_MARKET_PRICE_PROVIDER_UNAVAILABLE (or any other variant) is accepted,
// and structural findings are still reported. A live fetch is never retried.
//
// Exit code: 1 while TESTIMONY OPEN, 0 when TESTIMONY CLOSED, 2 on usage.
// --expect-closed asserts closure (the post-fix gate): 0 only when CLOSED.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SDA_ROOT = path.resolve(REPO_ROOT, '..', 'scenario-driven-architecture');
const DEFAULT_PROJECTED_ROOT = path.join(REPO_ROOT, 'embodiments', 'resolve-equity-market-price-evidence', 'projected');
const DEFAULT_FIXTURE_ID = 'equity-qqq-evidence-resolves';
const TIMING_FIELDS = ['durationMilliseconds', 'startedAt', 'completedAt'];
const TARGETS = ['node', 'python', 'csharp'];

const USAGE = [
  'usage: node scripts/verify-projected-testimony.mjs [options]',
  '  --projected <dir>      projected workspace (default embodiments/resolve-equity-market-price-evidence/projected)',
  '  --fixture <fixtureId>  fixture to run (default equity-qqq-evidence-resolves)',
  '  --python <exe>         python interpreter (default python)',
  '  --timeout-ms N         per-process timeout (default 600000)',
  '  --expect-closed        assert closure (0 only when TESTIMONY CLOSED)',
  '  --help                 print this usage'
].join('\n');

function fail(message) {
  console.error('verify-projected-testimony: ' + message);
  process.exit(2);
}

function parseArguments(argv) {
  const options = {
    projectedRoot: DEFAULT_PROJECTED_ROOT,
    fixtureId: DEFAULT_FIXTURE_ID,
    python: 'python',
    timeoutMilliseconds: 600_000,
    expectClosed: false
  };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    const value = () => {
      index += 1;
      if (index >= argv.length) fail(argument + ' requires a value');
      return argv[index];
    };
    if (argument === '--help' || argument === '-h') {
      console.log(USAGE);
      process.exit(0);
    } else if (argument === '--projected') {
      options.projectedRoot = path.resolve(value());
    } else if (argument === '--fixture') {
      options.fixtureId = value();
    } else if (argument === '--python') {
      options.python = value();
    } else if (argument === '--timeout-ms') {
      options.timeoutMilliseconds = Number.parseInt(value(), 10);
      if (!Number.isInteger(options.timeoutMilliseconds) || options.timeoutMilliseconds < 1) fail('--timeout-ms must be a positive integer');
    } else if (argument === '--expect-closed') {
      options.expectClosed = true;
    } else {
      fail('unknown option: ' + argument + '\n' + USAGE);
    }
  }
  return options;
}

function readJsonIfPresent(file) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return null;
  }
}

function truncate(text, limit = 600) {
  if (typeof text !== 'string') return '';
  const collapsed = text.replaceAll('\r', '').trim();
  return collapsed.length <= limit ? collapsed : collapsed.slice(0, limit) + '...[' + (collapsed.length - limit) + ' more bytes]';
}

function findNodeCli(projectedRoot) {
  const nodeRoot = path.join(projectedRoot, 'node');
  const candidates = fs.readdirSync(nodeRoot).filter((name) => name.endsWith('-cli.generated.mjs'));
  if (candidates.length !== 1) {
    throw new Error('expected exactly one *-cli.generated.mjs under ' + path.relative(REPO_ROOT, nodeRoot) + ', found ' + candidates.length);
  }
  return path.join(nodeRoot, candidates[0]);
}

function csharpNeedsBuild(csharpRoot) {
  const assembly = path.join(csharpRoot, 'bin', 'Debug', 'net10.0', 'ProjectedConsumerCli.dll');
  let assemblyTime = 0;
  try {
    assemblyTime = fs.statSync(assembly).mtimeMs;
  } catch {
    return { assembly, needed: true, reason: 'assembly absent' };
  }
  let newestSource = 0;
  for (const name of fs.readdirSync(csharpRoot)) {
    if (!name.endsWith('.cs') && !name.endsWith('.csproj') && !name.endsWith('.json')) continue;
    newestSource = Math.max(newestSource, fs.statSync(path.join(csharpRoot, name)).mtimeMs);
  }
  return newestSource > assemblyTime
    ? { assembly, needed: true, reason: 'generated sources newer than the built assembly' }
    : { assembly, needed: false, reason: null };
}

function targetLaunch(target, fixtureId, options) {
  const projectedRoot = options.projectedRoot;
  if (target === 'node') {
    return {
      command: process.execPath,
      args: [findNodeCli(projectedRoot), '--fixture=' + fixtureId],
      environment: { SFX_EMBODY_ROOT: REPO_ROOT }
    };
  }
  if (target === 'python') {
    const entry = path.join(projectedRoot, 'python', 'consumer.generated.py');
    const pythonPath = [path.join(SDA_ROOT, 'languages', 'python', 'src'), process.env.PYTHONPATH]
      .filter((value) => typeof value === 'string' && value.length > 0)
      .join(path.delimiter);
    return {
      command: options.python,
      args: [entry, '--fixture=' + fixtureId],
      environment: { SFX_EMBODY_ROOT: REPO_ROOT, PYTHONPATH: pythonPath, PYTHONIOENCODING: 'utf-8' }
    };
  }
  const csharpRoot = path.join(projectedRoot, 'csharp');
  const build = csharpNeedsBuild(csharpRoot);
  return {
    command: 'dotnet',
    args: [build.assembly, '--fixture=' + fixtureId],
    environment: { SFX_EMBODY_ROOT: REPO_ROOT },
    preflight: build.needed
      ? {
          purpose: 'build the emitted csharp CLI once (sources newer than the assembly)',
          command: 'dotnet',
          args: ['build', path.join(csharpRoot, 'ProjectedConsumerCli.generated.csproj'), '--nologo', '-v:q'],
          reason: build.reason
        }
      : null,
    assembly: build.assembly
  };
}

function parseResult(stdout) {
  const lines = stdout.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  for (let index = lines.length - 1; index >= 0; index -= 1) {
    try {
      const parsed = JSON.parse(lines[index]);
      if (parsed && typeof parsed === 'object' && typeof parsed.disposition === 'string') return parsed;
    } catch {
      // provider chatter / build banner
    }
  }
  return null;
}

function runProcess(launch, options) {
  const environment = { ...process.env, ...launch.environment };
  const started = performance.now();
  const run = spawnSync(launch.command, launch.args, {
    cwd: REPO_ROOT,
    env: environment,
    encoding: 'utf8',
    windowsHide: true,
    timeout: options.timeoutMilliseconds,
    maxBuffer: 256 * 1024 * 1024
  });
  return {
    durationMilliseconds: Math.round((performance.now() - started) * 1000) / 1000,
    exitCode: run.status,
    error: run.error ? { code: run.error.code ?? null, message: run.error.message } : null,
    stdout: typeof run.stdout === 'string' ? run.stdout : '',
    stderr: truncate(typeof run.stderr === 'string' ? run.stderr : '')
  };
}

function preflight(launch, options) {
  if (!launch.preflight) return { status: 'not-needed', reason: 'assembly current with generated sources' };
  const run = spawnSync(launch.preflight.command, launch.preflight.args, {
    cwd: REPO_ROOT,
    env: process.env,
    encoding: 'utf8',
    windowsHide: true,
    timeout: options.timeoutMilliseconds,
    maxBuffer: 64 * 1024 * 1024
  });
  return {
    status: run.status === 0 ? 'built' : 'failed',
    reason: launch.preflight.reason,
    exitCode: run.status,
    stderr: truncate(typeof run.stderr === 'string' ? run.stderr : '')
  };
}

function timingCheck(records) {
  const fieldsPresent = new Set();
  const missingCounts = new Map(TIMING_FIELDS.map((field) => [field, 0]));
  const invalid = [];
  let recordsMissingAny = 0;
  for (const [index, record] of records.entries()) {
    if (!record || typeof record !== 'object') {
      invalid.push({ index, reason: 'record is not an object' });
      continue;
    }
    let anyMissing = false;
    for (const field of TIMING_FIELDS) {
      if (Object.hasOwn(record, field)) fieldsPresent.add(field);
      else {
        missingCounts.set(field, missingCounts.get(field) + 1);
        anyMissing = true;
      }
    }
    if (anyMissing) {
      recordsMissingAny += 1;
      continue;
    }
    const duration = record.durationMilliseconds;
    const started = record.startedAt;
    const completed = record.completedAt;
    if (typeof duration !== 'number' || !Number.isFinite(duration) || duration < 0) {
      invalid.push({ index, reason: 'durationMilliseconds is not a finite non-negative number: ' + JSON.stringify(duration) });
      continue;
    }
    const startedAt = typeof started === 'number' ? started : Date.parse(started);
    const completedAt = typeof completed === 'number' ? completed : Date.parse(completed);
    if (!Number.isFinite(startedAt)) {
      invalid.push({ index, reason: 'startedAt is not a parseable timestamp: ' + JSON.stringify(started) });
      continue;
    }
    if (!Number.isFinite(completedAt)) {
      invalid.push({ index, reason: 'completedAt is not a parseable timestamp: ' + JSON.stringify(completed) });
      continue;
    }
    if (completedAt < startedAt) invalid.push({ index, reason: 'completedAt precedes startedAt' });
  }
  const missing = TIMING_FIELDS.filter((field) => fieldsPresent.has(field) === false);
  const missingDetail = TIMING_FIELDS.map((field) => field + ' absent on ' + missingCounts.get(field) + '/' + records.length + ' records');
  return { fieldsPresent: [...fieldsPresent].sort(), missing, recordsMissingAny, missingDetail, invalid };
}

function semanticId(value) {
  const normalized = String(value).toLowerCase().replace(/[^a-z0-9._:-]+/gu, '.').replace(/^[._:-]+|[._:\-]+$/gu, '');
  return (normalized || 'value').slice(0, 200);
}

function canonicalCells(projectedRoot, target) {
  const plan = readJsonIfPresent(path.join(projectedRoot, 'execution-plans', 'consumer-execution-plan.' + target + '.v3.json'));
  if (plan === null || plan.canonicalGraph === undefined || !Array.isArray(plan.canonicalGraph.cells)) return null;
  return {
    cells: plan.canonicalGraph.cells.map((cell) => cell.cellId),
    digest: typeof plan.canonicalGraphDigest === 'string' ? plan.canonicalGraphDigest : null
  };
}

function occurrenceCounts(records, idField) {
  const counts = new Map();
  for (const record of records) {
    if (!record || typeof record[idField] !== 'string') continue;
    counts.set(record[idField], (counts.get(record[idField]) ?? 0) + 1);
  }
  return counts;
}

function setDifference(left, right) {
  const rightSet = right instanceof Set ? right : new Set(right);
  return [...new Set(left)].filter((item) => !rightSet.has(item));
}

function main() {
  const options = parseArguments(process.argv.slice(2));
  const fixtureDocument = readJsonIfPresent(path.join(options.projectedRoot, 'fixtures', 'fixtures.json'));
  if (fixtureDocument === null || !Array.isArray(fixtureDocument.fixtures) || fixtureDocument.fixtures.length === 0) {
    fail('no fixtures found under ' + path.relative(REPO_ROOT, path.join(options.projectedRoot, 'fixtures', 'fixtures.json')));
  }
  const fixture = fixtureDocument.fixtures.find((candidate) => candidate.fixtureId === options.fixtureId);
  if (fixture === undefined) fail('unknown fixture: ' + options.fixtureId);

  const canonicalByTarget = {};
  for (const target of TARGETS) canonicalByTarget[target] = canonicalCells(options.projectedRoot, target);
  const reference = canonicalByTarget.node ?? canonicalByTarget.python ?? canonicalByTarget.csharp;
  if (reference === null) fail('no canonical graph cells found in any target execution plan under ' + path.relative(REPO_ROOT, options.projectedRoot));
  const canonicalCellIds = new Set(reference.cells);

  const gaps = [];
  const reports = {};
  for (const target of TARGETS) {
    const report = { target, run: null, preflight: null, graph: null, gaps: [] };
    reports[target] = report;
    let launch;
    try {
      launch = targetLaunch(target, options.fixtureId, options);
    } catch (error) {
      report.gaps.push({ code: 'TARGET_LAUNCH_UNAVAILABLE', detail: error.message });
      continue;
    }
    report.preflight = preflight(launch, options);
    if (report.preflight.status === 'failed') {
      report.gaps.push({ code: 'CSHARP_PREFLIGHT_FAILED', detail: report.preflight.stderr });
      continue;
    }
    const run = runProcess(launch, options);
    report.run = { exitCode: run.exitCode, durationMilliseconds: run.durationMilliseconds, processError: run.error, stderr: run.stderr };
    const result = parseResult(run.stdout);
    if (result === null) {
      report.gaps.push({ code: 'RESULT_UNPARSEABLE', detail: 'exit ' + String(run.exitCode) + '; stderr: ' + run.stderr });
      continue;
    }
    if (run.exitCode !== 0) {
      report.gaps.push({ code: 'TARGET_RUN_EXIT_NONZERO', detail: 'exit ' + String(run.exitCode) + (run.error ? '; process error ' + run.error.code : '') });
    }
    const graph = result.graphExecution && typeof result.graphExecution === 'object' ? result.graphExecution : {};
    const cells = Array.isArray(graph.cellTestimony) ? graph.cellTestimony : [];
    const edges = Array.isArray(graph.edgeTestimony) ? graph.edgeTestimony : [];
    const resolverPresent = Object.hasOwn(graph, 'resolverTestimony');
    const resolvers = resolverPresent && Array.isArray(graph.resolverTestimony) ? graph.resolverTestimony : [];
    const digestPresent = Object.hasOwn(graph, 'observedPathDigest') && graph.observedPathDigest !== null && graph.observedPathDigest !== undefined;
    const observedCellIds = [...new Set(cells.map((cell) => cell.cellId).filter((id) => typeof id === 'string'))];

    report.graph = {
      disposition: result.disposition ?? null,
      outcomeVariant: graph.outcomeVariant ?? null,
      cellCount: cells.length,
      edgeCount: edges.length,
      resolverPresent,
      resolverCount: resolvers.length,
      digestPresent,
      observedPathDigest: digestPresent ? graph.observedPathDigest : null,
      observedCellIds,
      observedCellIdCount: observedCellIds.length
    };
    report.records = { cells, edges, resolvers };
    report.timing = {
      cell: timingCheck(cells),
      edge: timingCheck(edges),
      pattern: timingCheck(resolvers)
    };

    if (cells.length === 0) report.gaps.push({ code: 'CELL_TESTIMONY_EMPTY', detail: 'graphExecution.cellTestimony is absent or empty' });
    if (edges.length === 0 && cells.length > 1) report.gaps.push({ code: 'EDGE_TESTIMONY_EMPTY', detail: 'graphExecution.edgeTestimony is empty for a multi-cell path' });
    const recordCounts = { cell: cells.length, edge: edges.length, pattern: resolvers.length };
    for (const kind of ['cell', 'edge', 'pattern']) {
      const check = report.timing[kind];
      if (check.recordsMissingAny > 0 && recordCounts[kind] > 0) {
        report.gaps.push({
          code: 'TIMING_FIELDS_MISSING',
          subject: kind,
          detail: check.missingDetail.join('; ')
        });
      }
      if (check.invalid.length > 0) report.gaps.push({ code: 'TIMING_INVALID', subject: kind, detail: JSON.stringify(check.invalid.slice(0, 3)) });
    }
    if (!digestPresent) {
      report.gaps.push({
        code: 'OBSERVED_PATH_DIGEST_MISSING',
        detail: Object.hasOwn(graph, 'observedPathDigest')
          ? 'observedPathDigest is present but null'
          : 'observedPathDigest key is absent'
      });
    }
    if (!resolverPresent) report.gaps.push({ code: 'RESOLVER_TESTIMONY_MISSING', detail: 'graphExecution.resolverTestimony key is absent' });
    const foreign = setDifference(observedCellIds, canonicalCellIds);
    if (foreign.length > 0) {
      const canonicalNormalized = new Set([...canonicalCellIds].map(semanticId));
      const normalizedMatches = foreign.filter((id) => canonicalNormalized.has(semanticId(id)));
      report.gaps.push({
        code: 'CELL_ID_NOT_CANONICAL',
        detail: foreign.length + ' observed cellId(s) are not canonicalGraph.cells ids; ' + normalizedMatches.length + ' are semantic-id normalized forms of canonical ids (e.g. ' + foreign[0] + ')'
      });
    }
    gaps.push(...report.gaps.map((gap) => ({ target, ...gap })));
  }

  const parsedTargets = TARGETS.filter((target) => reports[target].graph !== null);
  const variants = parsedTargets.map((target) => reports[target].graph.outcomeVariant);
  const variantsShared = parsedTargets.length === TARGETS.length && new Set(variants).size === 1;
  if (!variantsShared) {
    gaps.push({
      code: 'OUTCOME_VARIANT_DIVERGED',
      detail: TARGETS.map((target) => target + '=' + String(reports[target].graph?.outcomeVariant ?? '(no result)')).join(', ')
    });
  }
  const canonicalDigests = TARGETS.map((target) => canonicalByTarget[target]?.digest ?? null);
  if (new Set(canonicalDigests).size !== 1) {
    gaps.push({ code: 'CANONICAL_GRAPH_DIGEST_DIVERGED', detail: TARGETS.map((target) => target + '=' + String(canonicalByTarget[target]?.digest ?? '(missing)')).join(', ') });
  }
  const canonicalSets = TARGETS.map((target) => new Set(canonicalByTarget[target]?.cells ?? []));
  if (new Set(canonicalSets.map((cells) => [...cells].sort().join('\u0000'))).size !== 1) {
    gaps.push({ code: 'CANONICAL_GRAPH_CELLS_DIVERGED', detail: TARGETS.map((target, index) => target + '=' + canonicalSets[index].size + ' cells').join(', ') });
  }

  const parity = { variantsShared, byPair: [], digestEqual: null, cellSetEqual: null, occurrenceMismatches: [] };
  if (variantsShared) {
    for (let left = 0; left < TARGETS.length; left += 1) {
      for (let right = left + 1; right < TARGETS.length; right += 1) {
        const leftIds = reports[TARGETS[left]].graph.observedCellIds;
        const rightIds = reports[TARGETS[right]].graph.observedCellIds;
        const leftOnly = setDifference(leftIds, rightIds);
        const rightOnly = setDifference(rightIds, leftIds);
        parity.byPair.push({ pair: TARGETS[left] + '/' + TARGETS[right], leftOnly, rightOnly, equal: leftOnly.length === 0 && rightOnly.length === 0 });
        if (leftOnly.length > 0 || rightOnly.length > 0) {
          gaps.push({
            target: 'parity',
            code: 'OBSERVED_CELL_SET_NOT_SHARED',
            detail: TARGETS[left] + ' vs ' + TARGETS[right] + ': ' + TARGETS[left] + '-only ' + leftOnly.length + (leftOnly.length ? ' (' + leftOnly.slice(0, 3).join(', ') + ')' : '') + '; ' + TARGETS[right] + '-only ' + rightOnly.length + (rightOnly.length ? ' (' + rightOnly.slice(0, 3).join(', ') + ')' : '')
          });
        } else {
          const leftCounts = occurrenceCounts(reports[TARGETS[left]].records.cells, 'cellId');
          const rightCounts = occurrenceCounts(reports[TARGETS[right]].records.cells, 'cellId');
          const mismatched = [...leftCounts.entries()].filter(([cellId, count]) => rightCounts.get(cellId) !== count).map(([cellId]) => cellId);
          if (mismatched.length > 0) {
            parity.occurrenceMismatches.push({ pair: TARGETS[left] + '/' + TARGETS[right], cellIds: mismatched });
            gaps.push({ target: 'parity', code: 'CELL_OCCURRENCE_COUNT_MISMATCH', detail: TARGETS[left] + ' vs ' + TARGETS[right] + ': ' + mismatched.length + ' cellId(s) with different occurrence counts: ' + mismatched.slice(0, 3).join(', ') });
          }
        }
      }
    }
    const digests = TARGETS.map((target) => reports[target].graph.observedPathDigest);
    const allPresent = TARGETS.every((target) => reports[target].graph.digestPresent);
    parity.digestEqual = allPresent ? new Set(digests).size === 1 : null;
    parity.cellSetEqual = parity.byPair.every((pair) => pair.equal);
    const resolverCounts = TARGETS.map((target) => reports[target].graph.resolverCount);
    if (new Set(resolverCounts).size > 1) {
      gaps.push({ target: 'parity', code: 'RESOLVER_TESTIMONY_COUNT_NOT_SHARED', detail: TARGETS.map((target, index) => target + '=' + resolverCounts[index]).join(', ') });
    }
    if (allPresent && !parity.digestEqual) {
      gaps.push({ target: 'parity', code: 'OBSERVED_PATH_DIGEST_NOT_SHARED', detail: TARGETS.map((target) => target + '=' + String(reports[target].graph.observedPathDigest).slice(0, 22)).join(', ') });
    }
    if (!allPresent) {
      gaps.push({ target: 'parity', code: 'OBSERVED_PATH_DIGEST_PARITY_UNVERIFIABLE', detail: TARGETS.filter((target) => !reports[target].graph.digestPresent).join(', ') + ' expose no digest to compare' });
    }
  }

  console.log('projected testimony verification - ' + fixture.fixtureId);
  console.log('  canonicalPlanCells ' + reference.cells.length);
  for (const target of TARGETS) {
    const report = reports[target];
    if (report.graph === null) {
      console.log('  ' + target.padEnd(7) + ' no result  ' + (report.gaps.map((gap) => gap.code).join(', ') || 'not run'));
      continue;
    }
    console.log([
      '  ' + target.padEnd(7),
      'exit ' + report.run.exitCode,
      'variant ' + String(report.graph.outcomeVariant),
      'cells ' + report.graph.cellCount + ' (' + report.graph.observedCellIdCount + ' unique)',
      'edges ' + report.graph.edgeCount,
      'resolverTestimony ' + (report.graph.resolverPresent ? String(report.graph.resolverCount) : 'MISSING'),
      'observedPathDigest ' + (report.graph.digestPresent ? String(report.graph.observedPathDigest).slice(0, 22) + '...' : 'MISSING')
    ].join('  '));
    for (const kind of ['cell', 'edge', 'pattern']) {
      const check = report.timing[kind];
      const count = kind === 'cell' ? report.graph.cellCount : kind === 'edge' ? report.graph.edgeCount : report.graph.resolverCount;
      if (count === 0 && kind !== 'cell') continue;
      console.log('          ' + kind.padEnd(7) + ' timing ' + (check.recordsMissingAny === 0 && check.invalid.length === 0
        ? 'complete (' + check.fieldsPresent.join(', ') + ')'
        : 'incomplete (' + check.missingDetail.join('; ') + ')' + (check.invalid.length ? ' invalid ' + check.invalid.length : '')));
    }
  }
  if (parsedTargets.length === TARGETS.length) {
    console.log('  parity  variant ' + (parity.variantsShared ? 'shared ' + String(variants[0]) : 'DIVERGED'));
    for (const pair of parity.byPair) {
      console.log('          ' + pair.pair.padEnd(15) + ' cell sets ' + (pair.equal ? 'equal' : 'differ (left-only ' + pair.leftOnly.length + ', right-only ' + pair.rightOnly.length + ')'));
    }
    console.log('          observedPathDigest ' + (parity.digestEqual === true ? 'equal' : parity.digestEqual === false ? 'differ' : 'unverifiable'));
  }
  if (gaps.length > 0) {
    console.log('  gaps');
    const seen = new Set();
    for (const gap of gaps) {
      const line = '    ' + gap.target + ': ' + gap.code + ' - ' + gap.detail;
      if (seen.has(line)) continue;
      seen.add(line);
      console.log(line);
    }
    console.log('TESTIMONY OPEN');
  } else {
    console.log('TESTIMONY CLOSED');
  }
  if (options.expectClosed && gaps.length > 0) console.log('  (--expect-closed: post-fix gate not met)');
  process.exitCode = gaps.length === 0 ? 0 : 1;
}

try {
  main();
} catch (error) {
  console.error('verify-projected-testimony: ' + error.message);
  process.exitCode = 1;
}
