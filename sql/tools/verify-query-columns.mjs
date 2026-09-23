#!/usr/bin/env node
// verify-query-columns.mjs
//
// The schema gate for sql/schema/efficient-queries.sql: every table/column the
// probe query set references must exist in the estate's schema authority
// (docs/authoring-altitude-model-stubs-2026-09-21/tables_columns.csv), and no
// probe may reference a heavy object or an estate-wide view. Mechanical gates
// from docs/efficient-query-tooling-plan-2026-09-22.md section 7:
//   1. every function body is inline, declared with RETURNS TABLE AS RETURN;
//   2. every function body is TOP-bounded;
//   3. no SELECT *;
//   4. no LIKE-prefix scan;
//   5. no reference to the four heavy objects or v_selected_semantic_definition.
//
// Usage: node sql/tools/verify-query-columns.mjs [queries.sql] [tables_columns.csv]
// Exit 0: all references resolve. Exit 1: at least one violation.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, '..', '..');
const queriesFile = path.resolve(process.argv[2] ?? path.join(repoRoot, 'sql', 'schema', 'efficient-queries.sql'));
const csvFile = path.resolve(process.argv[3] ?? path.join(repoRoot, 'docs', 'authoring-altitude-model-stubs-2026-09-21', 'tables_columns.csv'));

const HEAVY_OBJECTS = [
  'capability_graph_source',
  'capability_execution_declaration',
  'v_capability_execution_declaration',
  'v_capability_graph_source',
  'v_selected_semantic_definition'
];

// The declared analysis views the probe set may reference. They are not rows of
// the table authority CSV; each is explicitly permitted here.
const VIEW_ALLOWLIST = new Set(['analysis.v_scenario_invocation_closure']);

const RESERVED = new Set(['WHERE', 'ON', 'JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 'CROSS', 'FULL',
  'GROUP', 'ORDER', 'HAVING', 'UNION', 'OPTION', 'WHILE', 'BEGIN', 'END', 'AS', 'APPLY', 'SET', 'WITH',
  'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'VALUES', 'INTO', 'RETURN', 'DECLARE', 'IF', 'ELSE', 'NOT',
  'EXISTS', 'AND', 'OR']);

function loadAuthority(csvText) {
  const lines = csvText.split(/\r?\n/).filter((line) => line.trim().length > 0);
  const header = lines[0].split(',');
  const schemaIndex = header.indexOf('schema_name');
  const tableIndex = header.indexOf('table_name');
  const columnIndex = header.indexOf('column_name');
  if (schemaIndex < 0 || tableIndex < 0 || columnIndex < 0) throw new Error('CSV_HEADER_UNRECOGNIZED');
  const tables = new Map();
  for (const line of lines.slice(1)) {
    const parts = line.split(',');
    const key = `${parts[schemaIndex]}.${parts[tableIndex]}`.toLowerCase();
    if (!tables.has(key)) tables.set(key, new Set());
    tables.get(key).add(parts[columnIndex].toLowerCase());
  }
  return tables;
}

function stripLiteralsAndComments(text) {
  let output = '';
  let index = 0;
  while (index < text.length) {
    const two = text.slice(index, index + 2);
    if (two === '--') {
      const end = text.indexOf('\n', index);
      index = end < 0 ? text.length : end;
      continue;
    }
    if (two === '/*') {
      const end = text.indexOf('*/', index + 2);
      index = end < 0 ? text.length : end + 2;
      continue;
    }
    const char = text[index];
    if (char === "'") {
      index += 1;
      while (index < text.length) {
        if (text[index] === "'" && text[index + 1] === "'") { index += 2; continue; }
        if (text[index] === "'") { index += 1; break; }
        index += 1;
      }
      output += "''";
      continue;
    }
    output += char;
    index += 1;
  }
  return output;
}

const raw = fs.readFileSync(queriesFile, 'utf8');
const authority = loadAuthority(fs.readFileSync(csvFile, 'utf8'));
const sql = stripLiteralsAndComments(raw);
const failures = [];

for (const heavy of HEAVY_OBJECTS) {
  if (new RegExp(`\\b${heavy}\\b`, 'i').test(sql)) failures.push(`heavy-object:${heavy}`);
}
if (/SELECT\s+\*/i.test(sql) || /SELECT\s+TOP\s*\(\s*\d+\s*\)\s*\*/i.test(sql)) failures.push('select-star');
if (/LIKE\s+N?'%/i.test(sql)) failures.push('like-prefix-scan');

const functionPattern = /CREATE\s+OR\s+ALTER\s+FUNCTION\s+(probe\.[A-Za-z0-9_]+)/gi;
const functions = [];
let match;
while ((match = functionPattern.exec(sql)) !== null) {
  const start = match.index;
  const next = sql.indexOf('\nGO', start);
  const body = sql.slice(start, next < 0 ? sql.length : next);
  functions.push({ name: match[1], body });
}
if (functions.length === 0) failures.push('no-functions');
for (const fn of functions) {
  if (!/RETURNS\s+TABLE\s+AS\s+RETURN/i.test(fn.body)) failures.push(`not-inline:${fn.name}`);
  if (!/TOP\s*\(/i.test(fn.body)) failures.push(`not-top-bounded:${fn.name}`);
}

const checked = new Set();
let aliasCount = 0;
const aliasCandidates = new Set();

function checkScope(scopeSql) {
  const tableRefs = new Map(); // alias -> { schema, table }
  const tablePattern = /\b(FROM|JOIN)\s+(model|source|analysis)\.([A-Za-z_][A-Za-z0-9_]*)(?:\s+(?:AS\s+)?([A-Za-z_][A-Za-z0-9_]*))?/gi;
  let tableMatch;
  while ((tableMatch = tablePattern.exec(scopeSql)) !== null) {
    const schema = tableMatch[2].toLowerCase();
    const table = tableMatch[3].toLowerCase();
    const key = `${schema}.${table}`;
    const candidateAlias = tableMatch[4];
    if (!VIEW_ALLOWLIST.has(key) && !authority.has(key)) failures.push(`unknown-table:${key}`);
    if (candidateAlias && !RESERVED.has(candidateAlias.toUpperCase()) && !['model', 'source', 'analysis'].includes(candidateAlias.toLowerCase())) {
      tableRefs.set(candidateAlias, { schema, table });
      aliasCandidates.add(candidateAlias);
    }
  }
  aliasCount += tableRefs.size;
  const columnPattern = /\b([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\b/g;
  let columnMatch;
  while ((columnMatch = columnPattern.exec(scopeSql)) !== null) {
    const prefix = columnMatch[1];
    const column = columnMatch[2];
    if (['model', 'source', 'analysis'].includes(prefix.toLowerCase())) continue;
    const ref = tableRefs.get(prefix);
    if (!ref) continue; // derived-table/CTE/table-variable alias: not a schema column
    const key = `${ref.schema}.${ref.table}`;
    const checkKey = `${key}.${column.toLowerCase()}`;
    if (checked.has(checkKey)) continue;
    checked.add(checkKey);
    if (VIEW_ALLOWLIST.has(key)) continue;
    const columns = authority.get(key);
    if (columns && !columns.has(column.toLowerCase())) failures.push(`unknown-column:${checkKey}`);
  }
}

for (const fn of functions) checkScope(fn.body);
const functionsEnd = functions.length > 0 ? sql.lastIndexOf('\nGO') : 0;
checkScope(sql.slice(functionsEnd));

console.log(`queries: ${path.relative(repoRoot, queriesFile)}`);
console.log(`authority: ${path.relative(repoRoot, csvFile)} (${authority.size} tables)`);
console.log(`functions: ${functions.length}`);
console.log(`table references: ${aliasCount} aliases in scope`);
console.log(`column references checked: ${checked.size}`);
if (failures.length > 0) {
  console.error(`FAIL (${failures.length}):`);
  for (const failure of failures.slice(0, 50)) console.error(`  ${failure}`);
  process.exitCode = 1;
} else {
  console.log('PASS: every reference resolves; heavy objects absent; functions inline and TOP-bounded.');
}
