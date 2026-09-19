// The estate command-surface conformance walk: every command the selected
// sfx-command-mapping.v1 declares is exercised live through the `sfx` CLI and
// must either complete with its recorded facts or refuse with its specific
// declared code. The collapsed codes (DATABASE_COMMAND_REJECTED,
// DECLARED_READ_FAILED, ESTATE_OPERATION_FAILED, SIDEFX_FAILURE) are never an
// acceptable answer to a declared command, so the observe --format circuit
// collapse cannot return unnoticed.
//
//   node test/command-surface.conformance.mjs [--include-slow] [--receipt FILE]
//
// The mapping is the authority for coverage: a command added to
// config/sfx.commands.json without a walk case fails this test.

import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ESTATE_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const ARGUMENTS = process.argv.slice(2);
const INCLUDE_SLOW = ARGUMENTS.includes('--include-slow');
const RECEIPT_PATH = resolve(ARGUMENTS.includes('--receipt')
  ? ARGUMENTS[ARGUMENTS.indexOf('--receipt') + 1]
  : join(ESTATE_ROOT, 'evidence', 'vault-20260916', 'command-surface', 'estate-command-surface.receipt.json'));

const FORBIDDEN_CODES = new Set([
  'DATABASE_COMMAND_REJECTED',
  'DECLARED_READ_FAILED',
  'ESTATE_OPERATION_FAILED',
  'SIDEFX_FAILURE'
]);

const ARTIFACT_DIGEST = 'a'.repeat(64);

// Each case records the command, the expected reading and whether it is slow
// (live provider work). `expect.disposition` is a completed delivery;
// `expect.code` is a declared refusal; `expect.contract` is the delivered
// document's contractId; `expect.either` admits a success or a declared refusal
// whose code is listed (the projection carrier's disposition).
const CASES = [
  { id: 'capability-list', argv: ['capability', 'list', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-list-namespace', argv: ['capability', 'list', '--namespace', 'sidefx:capabilities', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-list-absent-namespace', argv: ['capability', 'list', '--namespace', 'does-not-exist', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-catalogue', argv: ['capability', 'catalogue', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-find', argv: ['capability', 'find', 'hello', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-reveal-meaning', argv: ['capability', 'reveal', 'say-hello-world', '--as', 'meaning', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-reveal-meaning-markdown', argv: ['capability', 'reveal', 'say-hello-world', '--as', 'meaning', '--format', 'markdown', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-reveal-circuit', argv: ['capability', 'reveal', 'say-hello-world', '--as', 'circuit', '--json'], expect: { code: 'CIRCUIT_PUBLICATION_UNAVAILABLE' } },
  { id: 'capability-reveal-circuit-markdown', argv: ['capability', 'reveal', 'say-hello-world', '--as', 'circuit', '--format', 'markdown', '--json'], expect: { code: 'CAPABILITY_FORMAT_NOT_OFFERED' } },
  { id: 'capability-reveal-format-pdf', argv: ['capability', 'reveal', 'say-hello-world', '--format', 'pdf', '--json'], expect: { code: 'CAPABILITY_FORMAT_NOT_OFFERED' } },
  { id: 'capability-reveal-view-nonsense', argv: ['capability', 'reveal', 'say-hello-world', '--as', 'nonsense', '--json'], expect: { code: 'CAPABILITY_VIEW_NOT_OFFERED' } },
  { id: 'capability-invoke-hello', argv: ['capability', 'invoke', 'say-hello-world', '--input', '{}', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-invoke-display', argv: ['capability', 'invoke', 'say-hello-world', '--input', '{}', '--display', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-observe-hello', argv: ['capability', 'observe', 'say-hello-world', '--input', '{}', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-observe-circuit-format', argv: ['capability', 'observe', 'say-hello-world', '--input', '{}', '--format', 'circuit', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-observe-altitude', argv: ['capability', 'observe', 'say-hello-world', '--input', '{}', '--observation-altitude', 'scenario', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-observe-trace', argv: ['capability', 'observe', 'say-hello-world', '--input', '{}', '--trace', '--json'], expect: { disposition: 'completed' } },
  { id: 'capability-circuit-hello', argv: ['capability', 'circuit', 'say-hello-world', '--input', '{}', '--json'], expect: { contract: 'circuit-view.v1' } },
  { id: 'capability-circuit-namespace', argv: ['capability', 'circuit', 'say-hello-world', '--input', '{}', '--namespace', 'sidefx:capabilities', '--json'], expect: { contract: 'circuit-view.v1' } },
  { id: 'media-artifact', argv: ['media', 'artifact', ARTIFACT_DIGEST, '--json'], expect: { code: 'CIRCUIT_PUBLICATION_UNAVAILABLE' } },
  { id: 'media-artifact-identity', argv: ['media', 'artifact', 'not-a-digest', '--json'], expect: { code: 'IDENTITY_REJECTED', exit: 2 } },
  { id: 'capability-list-format-markdown', argv: ['capability', 'list', '--format', 'markdown', '--json'], expect: { code: 'OPTION_NOT_APPLICABLE', exit: 2 } },
  { id: 'capability-invoke-trace', argv: ['capability', 'invoke', 'say-hello-world', '--trace', '--json'], expect: { code: 'OPTION_NOT_APPLICABLE', exit: 2 } },
  { id: 'capability-observe-altitude-nonsense', argv: ['capability', 'observe', 'say-hello-world', '--input', '{}', '--observation-altitude', 'nonsense', '--json'], expect: { code: 'OPTION_NOT_APPLICABLE', exit: 2 } },
  { id: 'capability-unknown-verb', argv: ['capability', 'prepare', 'say-hello-world', '--json'], expect: { code: 'COMMAND_REJECTED', exit: 2 } },
  { id: 'unknown-object', argv: ['planet', 'list', '--json'], expect: { code: 'COMMAND_REJECTED', exit: 2 } },
  { id: 'capability-project', argv: ['capability', 'project', 'say-hello-world', '--workspace', join(ESTATE_ROOT, '.tmp-command-surface-projection'), '--json'], expect: { either: ['PROJECTION_LIFECYCLE_NOT_OFFERED_BY_CARRIER', 'COMPLETED'] } },
  {
    id: 'capability-invoke-typed-input',
    argv: ['capability', 'invoke', 'resolve-equity-market-price-evidence', '--display', '--input', 'AVGO', '--json'],
    expect: { disposition: 'completed' }, slow: true
  },
  {
    id: 'capability-circuit-equity',
    argv: ['capability', 'circuit', 'resolve-equity-market-price-evidence', '--input', 'AVGO', '--input-type', 'text', '--timeout', '900000', '--json'],
    expect: { contract: 'circuit-view.v1' }, slow: true
  },
  {
    id: 'capability-circuit-typed-input',
    argv: ['capability', 'circuit', 'request-capability-from-objective', '--input', '@test/fixtures/objective-question.txt', '--input-type', 'text', '--timeout', '900000', '--json'],
    expect: { contract: 'circuit-view.v1' }, slow: true
  }
];

function sfx(argv) {
  try {
    const stdout = execFileSync('sfx', argv, { cwd: ESTATE_ROOT, encoding: 'utf8', shell: true, timeout: 900_000, stdio: ['ignore', 'pipe', 'pipe'] });
    return { exit: 0, stdout, stderr: '' };
  } catch (error) {
    return { exit: error.status ?? 1, stdout: error.stdout ?? '', stderr: error.stderr ?? '' };
  }
}

function readingOf(caseResult) {
  const output = caseResult.stdout.trim();
  if (caseResult.exit === 0) {
    try {
      const delivered = JSON.parse(output);
      const nested = delivered.result ?? delivered;
      return { disposition: nested.disposition ?? 'completed', outcome: delivered };
    } catch { return { disposition: 'UNPARSEABLE', outcome: null }; }
  }
  try {
    const failure = JSON.parse(caseResult.stderr.trim());
    return { code: failure.error?.code ?? 'UNKNOWN', message: failure.error?.message, outcome: failure };
  } catch {
    return { code: `EXIT_${caseResult.exit}`, message: caseResult.stderr.trim().slice(0, 400), outcome: null };
  }
}

function matches(expectation, reading) {
  if (expectation.either) {
    if (reading.disposition === 'completed' && expectation.either.includes('COMPLETED')) return 'completed';
    return expectation.either.includes(reading.code) ? reading.code : null;
  }
  if (expectation.disposition !== undefined) return reading.disposition === expectation.disposition ? reading.disposition : null;
  if (expectation.code !== undefined) return reading.code === expectation.code ? reading.code : null;
  if (expectation.contract !== undefined) {
    return reading.outcome?.result?.outcome?.contractId === expectation.contract ? expectation.contract : null;
  }
  return null;
}

const mapping = JSON.parse(readFileSync(join(ESTATE_ROOT, 'config', 'sfx.commands.json'), 'utf8'));
const declaredCommands = new Set(Object.entries(mapping.commands)
  .flatMap(([object, operations]) => Object.keys(operations).map(verb => `${object} ${verb}`)));
const walkedCommands = new Set(CASES
  .map(testCase => `${testCase.argv[0]} ${testCase.argv[1]}`)
  .filter(command => declaredCommands.has(command)));
const uncovered = [...declaredCommands].filter(command => !walkedCommands.has(command));

const records = [];
let failed = 0;
for (const testCase of CASES) {
  if (testCase.slow && !INCLUDE_SLOW) {
    records.push({ id: testCase.id, command: testCase.argv.join(' '), status: 'SKIPPED_SLOW' });
    continue;
  }
  const started = Date.now();
  const caseResult = sfx(testCase.argv);
  const reading = readingOf(caseResult);
  const matched = matches(testCase.expect, reading);
  const collapsed = FORBIDDEN_CODES.has(reading.code);
  const status = matched !== null && !collapsed ? 'PASS' : 'FAIL';
  if (status === 'FAIL') failed += 1;
  records.push({
    id: testCase.id,
    command: `sfx ${testCase.argv.join(' ')}`,
    exit: caseResult.exit,
    expected: testCase.expect,
    reading: {
      disposition: reading.disposition,
      code: reading.code,
      message: reading.message,
      contractId: reading.outcome?.result?.outcome?.contractId
    },
    collapsed: collapsed || undefined,
    durationMilliseconds: Date.now() - started,
    status
  });
}

for (const command of uncovered) {
  failed += 1;
  records.push({ id: `uncovered:${command}`, command, status: 'FAIL', reason: 'declared command has no walk case' });
}

const receipt = {
  receiptType: 'sfx-command-surface-conformance.v1',
  estateRoot: ESTATE_ROOT,
  mapping: 'config/sfx.commands.json',
  mappingType: mapping.mappingType,
  declaredCommands: [...declaredCommands].sort(),
  cases: records.length,
  passed: records.filter(record => record.status === 'PASS').length,
  failed,
  skippedSlow: records.filter(record => record.status === 'SKIPPED_SLOW').length,
  collapsedCodesAdmitted: 0,
  status: failed === 0 ? 'CONFORMS' : 'FAILED',
  checkedAt: new Date().toISOString(),
  records
};

mkdirSync(dirname(RECEIPT_PATH), { recursive: true });
writeFileSync(RECEIPT_PATH, `${JSON.stringify(receipt, null, 2)}\n`);
for (const record of records) {
  process.stdout.write(`${record.status.padEnd(12)} ${record.id}${record.collapsed ? '  COLLAPSED' : ''}${record.reason ? `  ${record.reason}` : ''}\n`);
}
process.stdout.write(`${receipt.status}: ${receipt.passed}/${receipt.cases} passed, ${receipt.failed} failed, ${receipt.skippedSlow} skipped (${RECEIPT_PATH})\n`);
process.exit(failed === 0 ? 0 : 1);
