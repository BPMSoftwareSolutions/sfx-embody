// Cross-language performance harness for projected capability bodies.
//
//   node scripts/projected-performance.mjs [--runs N] [--targets node,python,csharp]
//     [--out <report.json>] [--fixture <fixtureId>] [--expect-variant <variant>]
//     [--projected <dir>] [--python <exe>] [--timeout-ms N] [--omit-results]
//
// One subprocess per run per target, whole-invocation wall clock (process
// startup included), captured result and execution testimony, median/p95,
// cross-target parity on the stable acceptance, and a machine-readable report.
// Per-cell durations are read from testimony only; absent timing fields are
// reported as PER_CELL_TIMING_UNAVAILABLE with the observed field evidence.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SDA_ROOT = path.resolve(REPO_ROOT, '..', 'scenario-driven-architecture');
const DEFAULT_PROJECTED_ROOT = path.join(REPO_ROOT, 'embodiments', 'resolve-equity-market-price-evidence', 'projected');
const TIMING_FIELDS = ['durationMilliseconds', 'startedAt', 'completedAt'];
const TARGETS = ['node', 'python', 'csharp'];

const USAGE = [
  'usage: node scripts/projected-performance.mjs [options]',
  '  --runs N               timed runs per target (default 3)',
  '  --targets a,b,c        subset of node,python,csharp (default all three)',
  '  --out <report.json>    report path (default evidence/projected-performance.report.json)',
  '  --fixture <fixtureId>  fixture to run (default first declared fixture)',
  '  --expect-variant <v>   required outcome variant (default: cross-target agreement only)',
  '  --projected <dir>      projected workspace (default embodiments/resolve-equity-market-price-evidence/projected)',
  '  --python <exe>         python interpreter (default python)',
  '  --timeout-ms N         per-process timeout (default 600000)',
  '  --omit-results         omit the full per-run result JSON from the report',
  '  --help                 print this usage'
].join('\n');

function fail(message) {
  console.error('projected-performance: ' + message);
  process.exit(2);
}

function parseArguments(argv) {
  const options = {
    runs: 3,
    targets: TARGETS.slice(),
    out: path.join(REPO_ROOT, 'evidence', 'projected-performance.report.json'),
    fixture: null,
    expectVariant: null,
    projectedRoot: DEFAULT_PROJECTED_ROOT,
    python: 'python',
    timeoutMilliseconds: 600_000,
    omitResults: false
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
    } else if (argument === '--runs') {
      options.runs = Number.parseInt(value(), 10);
      if (!Number.isInteger(options.runs) || options.runs < 1) fail('--runs must be a positive integer');
    } else if (argument === '--targets') {
      options.targets = value().split(',').map((item) => item.trim()).filter(Boolean);
      for (const target of options.targets) if (!TARGETS.includes(target)) fail('unknown target: ' + target);
    } else if (argument === '--out') {
      options.out = path.resolve(value());
    } else if (argument === '--fixture') {
      options.fixture = value();
    } else if (argument === '--expect-variant') {
      options.expectVariant = value();
    } else if (argument === '--projected') {
      options.projectedRoot = path.resolve(value());
    } else if (argument === '--python') {
      options.python = value();
    } else if (argument === '--timeout-ms') {
      options.timeoutMilliseconds = Number.parseInt(value(), 10);
      if (!Number.isInteger(options.timeoutMilliseconds) || options.timeoutMilliseconds < 1) fail('--timeout-ms must be a positive integer');
    } else if (argument === '--omit-results') {
      options.omitResults = true;
    } else {
      fail('unknown option: ' + argument + '\n' + USAGE);
    }
  }
  if (options.targets.length === 0) fail('--targets selects no target');
  return options;
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function readJsonIfPresent(file) {
  try {
    return readJson(file);
  } catch {
    return null;
  }
}

function round(value) {
  return Math.round(value * 1000) / 1000;
}

function summarize(values) {
  if (values.length === 0) return { count: 0, medianMilliseconds: null, p95Milliseconds: null, minMilliseconds: null, maxMilliseconds: null };
  const sorted = [...values].sort((left, right) => left - right);
  const middle = Math.floor(sorted.length / 2);
  const median = sorted.length % 2 === 1 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
  const rank = Math.max(0, Math.ceil(0.95 * sorted.length) - 1);
  return {
    count: sorted.length,
    medianMilliseconds: round(median),
    p95Milliseconds: round(sorted[rank]),
    minMilliseconds: round(sorted[0]),
    maxMilliseconds: round(sorted[sorted.length - 1])
  };
}

function quoteArgument(argument) {
  return /[\s"]/u.test(argument) ? '"' + argument.replaceAll('"', '\\"') + '"' : argument;
}

function displayCommand(command, args, environment) {
  const prefix = environment && environment.PYTHONPATH
    ? 'PYTHONPATH=' + environment.PYTHONPATH + ' '
    : '';
  return prefix + [command, ...args].map(quoteArgument).join(' ');
}

function findNodeCli(projectedRoot) {
  const nodeRoot = path.join(projectedRoot, 'node');
  const candidates = fs.readdirSync(nodeRoot).filter((name) => name.endsWith('-cli.generated.mjs'));
  if (candidates.length !== 1) {
    throw new Error('expected exactly one *-cli.generated.mjs under ' + path.relative(REPO_ROOT, nodeRoot) + ', found ' + candidates.length);
  }
  return path.join(nodeRoot, candidates[0]);
}

function targetLaunch(target, fixtureId, options) {
  const projectedRoot = options.projectedRoot;
  if (target === 'node') {
    const cli = findNodeCli(projectedRoot);
    return {
      command: process.execPath,
      args: [cli, '--fixture=' + fixtureId],
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
  const csproj = path.join(projectedRoot, 'csharp', 'ProjectedConsumerCli.generated.csproj');
  const assembly = path.join(projectedRoot, 'csharp', 'bin', 'Debug', 'net10.0', 'ProjectedConsumerCli.dll');
  return {
    command: 'dotnet',
    args: [assembly, '--fixture=' + fixtureId],
    environment: { SFX_EMBODY_ROOT: REPO_ROOT },
    preflight: {
      purpose: 'build the emitted csharp CLI once, outside the timed runs',
      command: 'dotnet',
      args: ['build', csproj, '--nologo', '-v:q'],
      environment: {}
    }
  };
}

function parseResult(stdout) {
  const lines = stdout.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  for (let index = lines.length - 1; index >= 0; index -= 1) {
    try {
      const parsed = JSON.parse(lines[index]);
      if (parsed && typeof parsed === 'object' && typeof parsed.disposition === 'string') {
        return { result: parsed, line: lines[index] };
      }
    } catch {
      // A build banner or provider chatter is not the result line.
    }
  }
  return null;
}

function testimonyEntries(result) {
  const graph = result && typeof result.graphExecution === 'object' && result.graphExecution !== null ? result.graphExecution : {};
  return [
    ['cell', Array.isArray(graph.cellTestimony) ? graph.cellTestimony : [], 'cellId'],
    ['edge', Array.isArray(graph.edgeTestimony) ? graph.edgeTestimony : [], 'edgeId'],
    ['pattern', Array.isArray(graph.resolverTestimony) ? graph.resolverTestimony : [], 'patternId']
  ];
}

function testimonyTiming(entry) {
  if (typeof entry.durationMilliseconds === 'number' && Number.isFinite(entry.durationMilliseconds)) return entry.durationMilliseconds;
  const started = entry.startedAt;
  const completed = entry.completedAt;
  if (typeof started === 'number' && typeof completed === 'number') return completed - started;
  if (typeof started === 'string' && typeof completed === 'string') {
    const startedAt = Date.parse(started);
    const completedAt = Date.parse(completed);
    if (Number.isFinite(startedAt) && Number.isFinite(completedAt)) return completedAt - startedAt;
  }
  return null;
}

function timingFieldsOf(entries) {
  const fields = new Set();
  for (const entry of entries) {
    if (!entry || typeof entry !== 'object') continue;
    for (const field of TIMING_FIELDS) if (Object.hasOwn(entry, field)) fields.add(field);
  }
  return [...fields].sort();
}

function fieldNamesOf(entries) {
  const fields = new Set();
  for (const entry of entries) {
    if (!entry || typeof entry !== 'object') continue;
    for (const field of Object.keys(entry)) fields.add(field);
  }
  return [...fields].sort();
}

function sha256(text) {
  return 'sha256:' + createHash('sha256').update(text).digest('hex');
}

function truncate(text, limit = 4000) {
  if (typeof text !== 'string') return '';
  return text.length <= limit ? text : text.slice(0, limit) + '...[' + (text.length - limit) + ' more bytes]';
}

function runProcess(launch, options) {
  const environment = { ...process.env, ...launch.environment };
  const started = new Date();
  const startedMonotonic = performance.now();
  const run = spawnSync(launch.command, launch.args, {
    cwd: REPO_ROOT,
    env: environment,
    encoding: 'utf8',
    windowsHide: true,
    timeout: options.timeoutMilliseconds,
    maxBuffer: 256 * 1024 * 1024
  });
  const durationMilliseconds = performance.now() - startedMonotonic;
  return {
    startedAt: started.toISOString(),
    completedAt: new Date().toISOString(),
    durationMilliseconds: round(durationMilliseconds),
    exitCode: run.status,
    signal: run.signal,
    error: run.error ? { code: run.error.code ?? null, message: run.error.message } : null,
    stdout: typeof run.stdout === 'string' ? run.stdout : '',
    stderr: truncate(typeof run.stderr === 'string' ? run.stderr : '')
  };
}

function preflightCsharp(launch, options) {
  if (!launch.preflight) return null;
  const environment = { ...process.env, ...launch.preflight.environment };
  const startedMonotonic = performance.now();
  const run = spawnSync(launch.preflight.command, launch.preflight.args, {
    cwd: REPO_ROOT,
    env: environment,
    encoding: 'utf8',
    windowsHide: true,
    timeout: options.timeoutMilliseconds,
    maxBuffer: 64 * 1024 * 1024
  });
  return {
    purpose: launch.preflight.purpose,
    display: displayCommand(launch.preflight.command, launch.preflight.args, launch.preflight.environment),
    exitCode: run.status,
    durationMilliseconds: round(performance.now() - startedMonotonic),
    error: run.error ? run.error.message : null,
    stdout: truncate(typeof run.stdout === 'string' ? run.stdout : '', 2000),
    stderr: truncate(typeof run.stderr === 'string' ? run.stderr : '', 2000)
  };
}

function recordedRun(target, runIndex, processRun, expected, options) {
  const record = {
    runIndex,
    startedAt: processRun.startedAt,
    completedAt: processRun.completedAt,
    durationMilliseconds: processRun.durationMilliseconds,
    exitCode: processRun.exitCode,
    signal: processRun.signal,
    processError: processRun.error,
    parsed: false,
    disposition: null,
    outcomeVariant: null,
    scenarioSequence: null,
    observedPathDigest: null,
    testimony: null,
    stdoutSha256: sha256(processRun.stdout),
    stderr: processRun.stderr
  };
  const parsed = parseResult(processRun.stdout);
  if (parsed === null) {
    record.findings = [{ code: 'RESULT_UNPARSEABLE', target, runIndex, stdoutTail: truncate(processRun.stdout.slice(-1500)) }];
    return record;
  }
  record.parsed = true;
  record.disposition = parsed.result.disposition ?? null;
  record.outcomeVariant = parsed.result.graphExecution ? parsed.result.graphExecution.outcomeVariant ?? null : null;
  record.scenarioSequence = Array.isArray(parsed.result.executions)
    ? parsed.result.executions.map((execution) => execution && execution.scenarioId)
    : null;
  record.observedPathDigest = parsed.result.graphExecution && Object.hasOwn(parsed.result.graphExecution, 'observedPathDigest')
    ? parsed.result.graphExecution.observedPathDigest
    : null;
  const testimony = { cellCount: 0, edgeCount: 0, patternCount: 0, fields: {}, timingFields: {} };
  for (const [kind, entries] of testimonyEntries(parsed.result)) {
    testimony[kind + 'Count'] = entries.length;
    testimony.fields[kind] = fieldNamesOf(entries);
    testimony.timingFields[kind] = timingFieldsOf(entries);
  }
  record.testimony = testimony;
  record.result = parsed.result;
  const findings = [];
  if (processRun.exitCode !== 0) findings.push({ code: 'RUN_EXIT_NONZERO', target, runIndex, exitCode: processRun.exitCode });
  if (expected.disposition !== undefined && record.disposition !== expected.disposition) {
    findings.push({ code: 'DISPOSITION_MISMATCH', target, runIndex, expected: expected.disposition, observed: record.disposition });
  }
  if (Array.isArray(expected.scenarioSequence) && JSON.stringify(record.scenarioSequence) !== JSON.stringify(expected.scenarioSequence)) {
    findings.push({ code: 'SCENARIO_SEQUENCE_MISMATCH', target, runIndex, expected: expected.scenarioSequence, observed: record.scenarioSequence });
  }
  if (expected.outcomeVariant !== undefined && record.outcomeVariant !== expected.outcomeVariant) {
    findings.push({ code: 'VARIANT_MISMATCH', target, runIndex, expected: expected.outcomeVariant, observed: record.outcomeVariant });
  }
  if (options.expectVariant !== null && record.outcomeVariant !== options.expectVariant) {
    findings.push({ code: 'EXPECTED_VARIANT_MISMATCH', target, runIndex, expected: options.expectVariant, observed: record.outcomeVariant });
  }
  if (findings.length > 0) record.findings = findings;
  return record;
}

function targetIdentity(target, options) {
  const targetRoot = path.join(options.projectedRoot, target);
  const carrier = readJsonIfPresent(path.join(targetRoot, 'capability-carrier.json'));
  const plan = readJsonIfPresent(path.join(options.projectedRoot, 'execution-plans', 'consumer-execution-plan.' + target + '.v3.json'));
  return {
    capabilityId: carrier && typeof carrier.capabilityId === 'string' ? carrier.capabilityId : null,
    canonicalGraphDigest: plan && typeof plan.canonicalGraphDigest === 'string' ? plan.canonicalGraphDigest : null,
    realizedGraphDigest: plan && typeof plan.realizedGraphDigest === 'string' ? plan.realizedGraphDigest : null,
    carrierPath: path.relative(REPO_ROOT, path.join(targetRoot, 'capability-carrier.json')),
    planPath: path.relative(REPO_ROOT, path.join(options.projectedRoot, 'execution-plans', 'consumer-execution-plan.' + target + '.v3.json'))
  };
}

function distinct(values) {
  return [...new Set(values)];
}

function main() {
  const options = parseArguments(process.argv.slice(2));
  const fixtureDocument = readJsonIfPresent(path.join(options.projectedRoot, 'fixtures', 'fixtures.json'));
  if (fixtureDocument === null || !Array.isArray(fixtureDocument.fixtures) || fixtureDocument.fixtures.length === 0) {
    fail('no fixtures found under ' + path.relative(REPO_ROOT, path.join(options.projectedRoot, 'fixtures', 'fixtures.json')));
  }
  const fixture = options.fixture === null
    ? fixtureDocument.fixtures[0]
    : fixtureDocument.fixtures.find((candidate) => candidate.fixtureId === options.fixture);
  if (fixture === undefined) fail('unknown fixture: ' + options.fixture);
  const expected = fixture.expected ?? {};

  const identity = {};
  for (const target of options.targets) identity[target] = targetIdentity(target, options);

  const targets = {};
  const failures = [];
  const observations = [];
  const allPerCellSamples = new Map();
  for (const target of options.targets) {
    const launch = targetLaunch(target, fixture.fixtureId, options);
    const display = displayCommand(launch.command, launch.args, launch.environment);
    const targetReport = {
      launch: { command: launch.command, args: launch.args, environment: launch.environment, display },
      preflight: null,
      runs: [],
      wholeInvocation: null,
      perCellTiming: null
    };
    const preflight = preflightCsharp(launch, options);
    if (preflight !== null) {
      targetReport.preflight = preflight;
      if (preflight.exitCode !== 0) {
        failures.push({
          code: 'CSHARP_PREFLIGHT_FAILED',
          target,
          exitCode: preflight.exitCode,
          command: preflight.display,
          error: preflight.error,
          stderr: preflight.stderr
        });
      }
    }
    for (let runIndex = 1; runIndex <= options.runs; runIndex += 1) {
      if (preflight !== null && preflight.exitCode !== 0) break;
      const processRun = runProcess(launch, options);
      const record = recordedRun(target, runIndex, processRun, expected, options);
      targetReport.runs.push(record);
      if (record.findings) failures.push(...record.findings);
      for (const [, entries] of testimonyEntries(record.result ?? { graphExecution: {} })) {
        for (const entry of entries) {
          const value = testimonyTiming(entry);
          if (value === null) continue;
          const idField = Object.hasOwn(entry, 'cellId') ? 'cellId' : Object.hasOwn(entry, 'edgeId') ? 'edgeId' : 'patternId';
          const key = target + ':' + idField + ':' + entry[idField];
          if (!allPerCellSamples.has(key)) allPerCellSamples.set(key, { id: entry[idField], target, values: [] });
          allPerCellSamples.get(key).values.push(value);
        }
      }
    }
    targetReport.wholeInvocation = summarize(targetReport.runs.map((run) => run.durationMilliseconds));
    targets[target] = targetReport;
  }

  const perCellPolicy = {
    fields: TIMING_FIELDS,
    rule: 'per-cell durations are read only from graphExecution cell/edge/pattern testimony; whole-invocation time is the measured subprocess wall clock'
  };
  if (allPerCellSamples.size > 0) {
    const byKey = {};
    for (const [key, sample] of allPerCellSamples) byKey[key] = { id: sample.id, target: sample.target, ...summarize(sample.values) };
    for (const target of Object.keys(targets)) {
      const rows = Object.entries(byKey).filter(([, row]) => row.target === target);
      targets[target].perCellTiming = { status: 'AVAILABLE', cells: Object.fromEntries(rows) };
    }
  } else {
    const evidence = {};
    for (const target of Object.keys(targets)) {
      const fields = {};
      for (const kind of ['cell', 'edge', 'pattern']) {
        const union = new Set();
        for (const run of targets[target].runs) {
          if (!run.testimony) continue;
          for (const field of run.testimony.fields[kind] ?? []) union.add(field);
        }
        fields[kind] = [...union].sort();
      }
      evidence[target] = fields;
    }
    observations.push({
      code: 'PER_CELL_TIMING_UNAVAILABLE',
      message: 'no projected body emits per-cell timing; read from testimony only, never synthesized',
      checkedFields: TIMING_FIELDS,
      evidence
    });
    for (const target of Object.keys(targets)) targets[target].perCellTiming = { status: 'PER_CELL_TIMING_UNAVAILABLE', checkedFields: TIMING_FIELDS };
  }

  const variants = {};
  for (const target of Object.keys(targets)) variants[target] = distinct(targets[target].runs.map((run) => run.outcomeVariant));
  const variantLists = Object.values(variants);
  const variantAgreed = variantLists.every((list) => list.length === 1) && distinct(variantLists.flat()).length === 1;
  const parity = {
    fixture: { fixtureId: fixture.fixtureId, expected },
    outcomeVariant: { byTarget: variants, shared: variantAgreed ? variantLists[0][0] : null, agreed: variantAgreed },
    canonicalIdentity: {
      byTarget: Object.fromEntries(Object.entries(identity).map(([target, value]) => [target, value.capabilityId])),
      capabilityIdShared: distinct(Object.values(identity).map((value) => value.capabilityId)).length === 1,
      canonicalGraphDigest: Object.fromEntries(Object.entries(identity).map(([target, value]) => [target, value.canonicalGraphDigest])),
      canonicalGraphDigestShared: distinct(Object.values(identity).map((value) => value.canonicalGraphDigest)).length === 1
    },
    observedPathDigest: {
      byTargetAndRun: Object.fromEntries(Object.entries(targets).map(([target, report]) => [
        target,
        report.runs.map((run) => run.observedPathDigest ?? null)
      ])),
      byTarget: Object.fromEntries(Object.entries(targets).map(([target, report]) => [
        target,
        distinct(report.runs.map((run) => (run.observedPathDigest ?? null) === null ? null : run.observedPathDigest))
      ]))
    }
  };
  if (!parity.outcomeVariant.agreed) {
    failures.push({ code: 'OUTCOME_VARIANT_DIVERGED', byTarget: parity.outcomeVariant.byTarget });
  }
  if (!parity.canonicalIdentity.capabilityIdShared) {
    failures.push({ code: 'CAPABILITY_IDENTITY_DIVERGED', byTarget: parity.canonicalIdentity.byTarget });
  }
  if (!parity.canonicalIdentity.canonicalGraphDigestShared) {
    failures.push({ code: 'CANONICAL_IDENTITY_DIVERGED', byTarget: parity.canonicalIdentity.canonicalGraphDigest });
  }
  const observedDigestTargets = Object.entries(parity.observedPathDigest.byTarget)
    .filter(([, values]) => values.some((value) => value !== null));
  if (observedDigestTargets.length < Object.keys(targets).length) {
    observations.push({
      code: 'OBSERVED_PATH_DIGEST_UNAVAILABLE',
      message: 'not every target exposes a non-null graphExecution.observedPathDigest',
      byTarget: parity.observedPathDigest.byTarget
    });
  }
  const observedDigests = distinct(observedDigestTargets.map(([, values]) => values.filter((value) => value !== null)).flat());
  if (observedDigests.length > 1) {
    observations.push({
      code: 'OBSERVED_PATH_DIGEST_NOT_SHARED',
      message: 'observedPathDigest differs across targets; testimony granularity differs per target, so this is evidence, not a parity failure',
      byTarget: parity.observedPathDigest.byTarget
    });
  }

  if (options.omitResults) {
    for (const target of Object.keys(targets)) {
      for (const run of targets[target].runs) delete run.result;
    }
  }

  const report = {
    performanceReportType: 'projected-cross-language-performance.v1',
    generatedAt: new Date().toISOString(),
    estateRoot: REPO_ROOT,
    projectedRoot: path.relative(REPO_ROOT, options.projectedRoot).replaceAll('\\', '/'),
    fixture: { fixtureId: fixture.fixtureId, input: fixture.input, expected },
    runsPerTarget: options.runs,
    targets,
    identity,
    parity,
    perCellPolicy,
    findings: failures,
    observations,
    disposition: failures.length === 0 ? 'ADMITTED' : 'REJECTED'
  };
  fs.mkdirSync(path.dirname(options.out), { recursive: true });
  fs.writeFileSync(options.out, JSON.stringify(report, null, 2) + '\n');

  console.log('projected cross-language performance - ' + fixture.fixtureId + ' - ' + options.runs + ' run(s) per target');
  for (const target of options.targets) {
    const summary = targets[target].wholeInvocation;
    const variant = targets[target].runs[targets[target].runs.length - 1]?.outcomeVariant ?? '(none)';
    const ok = targets[target].runs.filter((run) => run.parsed && run.exitCode === 0).length;
    const digest = targets[target].runs[0]?.observedPathDigest;
    console.log([
      '  ' + target.padEnd(7),
      'ok ' + ok + '/' + targets[target].runs.length,
      'median ' + (summary.medianMilliseconds ?? 'n/a') + ' ms',
      'p95 ' + (summary.p95Milliseconds ?? 'n/a') + ' ms',
      'variant ' + variant,
      digest ? 'observedPathDigest ' + String(digest).slice(0, 19) + '...' : 'observedPathDigest (absent)'
    ].join('  '));
  }
  console.log('  parity  ' + report.disposition + '  variant=' + (parity.outcomeVariant.shared ?? '(diverged)')
    + '  canonical=' + (parity.canonicalIdentity.canonicalGraphDigestShared
      ? String(Object.values(parity.canonicalIdentity.canonicalGraphDigest)[0]).slice(0, 19) + '...'
      : '(diverged)'));
  for (const finding of failures) console.log('  FAILURE ' + finding.code + ' ' + JSON.stringify(finding));
  for (const observation of observations) {
    console.log('  ' + observation.code + '  ' + (observation.message ?? ''));
    if (observation.code === 'PER_CELL_TIMING_UNAVAILABLE') {
      for (const target of Object.keys(observation.evidence)) {
        console.log('    ' + target.padEnd(7) + ' cell fields: ' + JSON.stringify(observation.evidence[target].cell));
      }
    }
  }
  console.log('  report  ' + path.relative(REPO_ROOT, options.out).replaceAll('\\', '/'));
  process.exitCode = report.disposition === 'ADMITTED' ? 0 : 1;
}

try {
  main();
} catch (error) {
  console.error('projected-performance: ' + error.message);
  process.exitCode = 1;
}
