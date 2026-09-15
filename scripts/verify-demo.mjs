import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = fileURLToPath(new URL('../', import.meta.url));
const live = process.argv.includes('--live');
const startedAt = new Date().toISOString();
const receiptDir = path.join(root, 'evidence', 'demo-' + startedAt.replaceAll(':', '-'));
await fs.mkdir(receiptDir, { recursive: true });

const helloInput = 'evidence/hugging-face-pilots/2026-09-10T00-23-20.815Z/say-hello-world/returns-the-exact-canonical-greeting-without-domain-input.input.json';
const providerInput = 'examples/provider-resolution.request.json';
const zeroDigest = '0'.repeat(64);

const report = { suite: 'verify-demo', startedAt, live, receiptDir: path.relative(root, receiptDir), cases: [], skipped: [], liveNote: null, passed: false };
let helloObservedPathDigest = null;

function run(name, command) {
  const started = performance.now();
  const result = spawnSync(process.env.ComSpec ?? 'cmd.exe', ['/d', '/s', '/c', `"${command}"`], {
    cwd: root, encoding: 'utf8', windowsHide: true, windowsVerbatimArguments: true, timeout: 180000, maxBuffer: 16 * 1024 * 1024
  });
  if (result.error) throw result.error;
  return {
    name, command, status: result.status, wallMs: performance.now() - started,
    stdout: result.stdout ?? '', stderr: result.stderr ?? '',
    text: (result.stdout ?? '').replaceAll('\r\n', '\n'), errorText: (result.stderr ?? '').replaceAll('\r\n', '\n')
  };
}

async function request(name, command) {
  const captured = run(name, command);
  await fs.writeFile(path.join(receiptDir, name + '.stdout.txt'), captured.stdout);
  await fs.writeFile(path.join(receiptDir, name + '.stderr.txt'), captured.stderr);
  return captured;
}

function parseStdout(captured) {
  return JSON.parse(captured.stdout.trim());
}

function firstLine(text) {
  return (text.split('\n').find(line => line.trim() !== '') ?? '').trim();
}

function verified(captured, summary) {
  report.cases.push({ name: captured.name, command: captured.command, status: captured.status, wallMs: Math.round(captured.wallMs * 1000) / 1000, ...summary });
  console.log(`VERIFIED ${captured.name} (${Math.round(captured.wallMs)} ms)`);
}

const cases = [
  {
    name: 'list-capabilities',
    command: 'sfx capability list --namespace sidefx:capabilities',
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      const header = captured.text.match(/^Capabilities \((\d+)\)$/m);
      assert.ok(header, 'capabilities header');
      const rows = captured.text.split('\n').filter(line => /^[a-z0-9.-]+\s+sidefx:capabilities\s+\(\d+ scenarios?\)$/.test(line));
      assert.equal(rows.length, Number(header[1]), 'row count matches the declared count');
      assert.ok(rows.some(row => row.startsWith('say-hello-world ')), 'say-hello-world listed');
      return { capabilities: Number(header[1]), rows: rows.length };
    }
  },
  {
    name: 'find-scaffold',
    command: 'sfx capability find scaffold',
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      assert.match(captured.text, /^Capabilities \(1\)$/m, 'one match');
      assert.match(captured.text, /^generate-executable-capability-scaffold\s+sidefx:capabilities\s+\(\d+ scenarios?\)$/m, 'the scaffold capability');
      return { matches: 1, capabilityId: 'generate-executable-capability-scaffold' };
    }
  },
  {
    name: 'reveal-equity-market-price-evidence',
    command: 'sfx capability reveal resolve-equity-market-price-evidence',
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      assert.match(captured.text, /^Capability\s+resolve-equity-market-price-evidence$/m, 'capability identity');
      assert.match(captured.text, /^Namespace\s+sidefx:capabilities$/m, 'namespace');
      assert.match(captured.text, /^Root\s+resolve-equity-market-price-evidence$/m, 'root scenario');
      assert.match(captured.text, /^Snapshot\s+sha256:[a-f0-9]{64}$/m, 'snapshot identity');
      assert.match(captured.text, /^Canonical feature$/m, 'canonical feature');
      assert.match(captured.text, /^User story$/m, 'user story');
      assert.match(captured.text, /^Experience$/m, 'experience');
      assert.match(captured.text, /^Scenarios \(\d+\)$/m, 'scenarios');
      assert.match(captured.text, /^Execution plan \(\d+\)$/m, 'execution plan');
      assert.match(captured.text, /^Ports \(\d+\)$/m, 'ports');
      assert.match(captured.text, /^Contracts \(\d+\)$/m, 'contracts');
      assert.match(captured.text, /^\s+observe-equity-price-exchange\s+->\s+sda-governed-http-exchange-port\.v1$/m, 'provider observation port');
      return { snapshotId: captured.text.match(/^Snapshot\s+(sha256:[a-f0-9]{64})$/m)[1] };
    }
  },
  {
    name: 'reveal-equity-market-price-evidence-markdown',
    command: 'sfx capability reveal resolve-equity-market-price-evidence --format markdown',
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      assert.match(captured.text, /^## Canonical feature$/m, 'Markdown canonical feature');
      assert.match(captured.text, /^## User story$/m, 'Markdown user story');
      assert.match(captured.text, /^## Experience$/m, 'Markdown experience');
      assert.match(captured.text, /^## Scenarios \(\d+\)$/m, 'Markdown scenarios');
      assert.match(captured.text, /^## Execution plan \(\d+\)$/m, 'Markdown execution plan');
      assert.match(captured.text, /^## Ports \(\d+\)$/m, 'Markdown ports');
      assert.match(captured.text, /^## Contracts \(\d+\)$/m, 'Markdown contracts');
      assert.match(captured.text, /observe-equity-price-exchange/, 'provider observation port');
      return { lines: captured.text.split('\n').length };
    }
  },
  {
    name: 'invoke-say-hello-world',
    command: `sfx capability invoke say-hello-world --namespace sidefx:capabilities --input @${helloInput} --json`,
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      assert.equal(captured.stderr, '', 'invoke writes nothing to stderr');
      const document = parseStdout(captured);
      assert.equal(document.result.disposition, 'completed', 'execution disposition');
      assert.equal(document.result.outcome.contractId, 'hello-world-greeting.v1', 'outcome contract');
      assert.equal(document.result.outcome.payload.message, 'Hello, World!', 'canonical greeting');
      helloObservedPathDigest = document.result.observedPathDigest;
      return {
        disposition: document.result.disposition, message: document.result.outcome.payload.message,
        observedPathDigest: helloObservedPathDigest, snapshotId: document.evidence.snapshotId,
        readSession: document.evidence.readSession, process: document.evidence.process
      };
    }
  },
  {
    name: 'observe-say-hello-world-trace',
    command: `sfx capability observe say-hello-world --namespace sidefx:capabilities --input @${helloInput} --trace`,
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      assert.match(captured.text, /^Scenario say-hello-world$/m, 'story header');
      assert.match(captured.text, /^GIVEN hello-world-request\s+\(hello-world-request\.v1\)$/m, 'GIVEN face');
      assert.match(captured.text, /^WHEN$/m, 'WHEN');
      assert.match(captured.text, /^  ✓ say-hello-world-port\s+[\d.]+ ms$/m, 'responsibility in story');
      assert.match(captured.text, /^THEN$/m, 'THEN');
      assert.match(captured.text, /^  ✓ hello-world-greeting\s+\(hello-world-greeting\.v1\)$/m, 'THEN face');
      assert.match(captured.text, /^TRACE$/m, 'trace tree header');
      assert.match(captured.text, /^✓ scenario say-hello-world\s+[\d.]+ ms$/m, 'trace tree root');
      assert.match(captured.text, /^    ✓ literal payload\.message\s+[\d.]+ ms$/m, 'trace tree mechanic');
      assert.match(captured.errorText, /^  ✓ \d{2}:\d{2}:\d{2}\.\d{3} say-hello-world-port\s+[\d.]+ ms$/m, 'streamed responsibility');
      assert.match(captured.errorText, /^  · \d{2}:\d{2}:\d{2}\.\d{3} literal payload\.message\s+[\d.]+ ms$/m, 'streamed mechanic with declared path');
      assert.match(captured.errorText, /^  ↳ \d{2}:\d{2}:\d{2}\.\d{3} literal payload\.message admitted\s+[\d.]+ ms$/m, 'streamed admitted edge');
      return { traceLines: captured.text.split('\n').filter(line => /[✓↳·]/.test(line)).length };
    }
  },
  {
    name: 'observe-say-hello-world-json',
    command: `sfx capability observe say-hello-world --namespace sidefx:capabilities --input @${helloInput} --json`,
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      const document = parseStdout(captured);
      assert.equal(document.result.disposition, 'completed', 'execution disposition');
      assert.equal(document.result.outcome.payload.message, 'Hello, World!', 'canonical greeting');
      assert.equal(document.story.scenario.scenarioId, 'say-hello-world', 'story scenario');
      assert.ok(document.story.scenario.responsibilities.length >= 1, 'declared responsibilities in story');
      assert.ok(document.overlay && Array.isArray(document.overlay.cells) && document.overlay.cells.length > 0, 'planned-versus-observed overlay');
      assert.ok(document.overlay.cells.every(cell => cell.semanticAddress), 'semantic address on every overlay cell');
      assert.ok(helloObservedPathDigest, 'invoke digest captured');
      const observedPathDigest = document.result.observedPathDigest ?? document.observedPathDigest;
      assert.equal(observedPathDigest, helloObservedPathDigest, 'invoke/observe observedPathDigest parity');
      return { disposition: document.result.disposition, responsibilityCount: document.story.scenario.responsibilities.length, overlayCells: document.overlay.cells.length, observedPathDigest };
    }
  },
  {
    name: 'invoke-resolve-sidefx-eligible-providers',
    command: `sfx capability invoke resolve-sidefx-eligible-providers --input @${providerInput} --json`,
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      const document = parseStdout(captured);
      assert.equal(document.result.disposition, 'completed', 'execution disposition');
      assert.equal(document.result.outcome.disposition, 'PROVIDERS_RESOLVED', 'domain disposition');
      assert.equal(document.result.outcome.eligibleCount, 1, 'eligible count');
      return { disposition: document.result.disposition, outcomeDisposition: document.result.outcome.disposition, eligibleCount: document.result.outcome.eligibleCount };
    }
  },
  {
    name: 'live-invoke-equity-market-price-evidence',
    live: true,
    command: 'sfx capability invoke resolve-equity-market-price-evidence --input QQQ --json',
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      const document = parseStdout(captured);
      assert.equal(document.result.disposition, 'completed', 'execution disposition');
      assert.equal(document.result.outcome.disposition, 'EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED', 'domain disposition');
      assert.equal(document.result.outcome.payload.symbol, 'QQQ', 'requested symbol');
      assert.equal(typeof document.result.outcome.payload.observedPrice, 'number', 'observed price');
      return {
        disposition: document.result.disposition, outcomeDisposition: document.result.outcome.disposition,
        symbol: document.result.outcome.payload.symbol, observedPrice: document.result.outcome.payload.observedPrice,
        sourceAttribution: document.result.outcome.payload.sourceAttribution
      };
    }
  },
  {
    name: 'live-observe-equity-market-price-evidence-display',
    live: true,
    command: 'sfx capability observe resolve-equity-market-price-evidence --display --input QQQ',
    summarize: (captured) => {
      assert.equal(captured.status, 0, 'exit status');
      assert.match(captured.text, /^Scenario resolve-equity-market-price-evidence$/m, 'story header');
      assert.match(captured.text, /^  ✓ observe-equity-price-exchange\s+[\d.]+ ms$/m, 'provider responsibility');
      assert.match(captured.text, /"symbol": "QQQ"/, 'displayed product symbol');
      return { displayedProduct: 'QQQ' };
    }
  },
  {
    name: 'circuit-say-hello-world',
    command: 'sfx capability circuit say-hello-world',
    summarize: (captured) => {
      assert.equal(captured.status, 4, 'exit status');
      assert.match(captured.errorText, /CIRCUIT_PUBLICATION_UNAVAILABLE/, 'honest unavailability');
      return { errorCode: 'CIRCUIT_PUBLICATION_UNAVAILABLE' };
    }
  },
  {
    name: 'media-artifact-unavailable',
    command: `sfx media artifact ${zeroDigest}`,
    summarize: (captured) => {
      assert.equal(captured.status, 4, 'exit status');
      assert.match(captured.errorText, /CIRCUIT_PUBLICATION_UNAVAILABLE/, 'honest unavailability');
      return { errorCode: 'CIRCUIT_PUBLICATION_UNAVAILABLE' };
    }
  }
];

try {
  for (const entry of cases) {
    if (entry.live && !live) {
      report.skipped.push(entry.name);
      console.log(`SKIPPED ${entry.name} (pass --live to run the network case)`);
      continue;
    }
    if (entry.live && report.liveNote) {
      report.skipped.push(entry.name);
      console.log(`SKIPPED ${entry.name} (the live environment is unavailable)`);
      continue;
    }
    const captured = await request(entry.name, entry.command);
    if (entry.live && captured.status !== 0) {
      report.liveNote = `${entry.name} exited ${captured.status}: ${firstLine(captured.errorText)}`;
      console.log(`LIVE-UNAVAILABLE ${entry.name} -- ${report.liveNote}`);
      continue;
    }
    verified(captured, entry.summarize(captured));
  }
  report.passed = true;
} catch (error) {
  report.passed = false;
  report.error = { message: error.message, stack: error.stack };
  process.exitCode = 1;
} finally {
  report.completedAt = new Date().toISOString();
  await fs.writeFile(path.join(receiptDir, 'report.json'), JSON.stringify(report, null, 2) + '\n');
  console.log('REPORT', path.join(receiptDir, 'report.json'));
  if (report.error) console.error('FAILED', report.error.message);
}
