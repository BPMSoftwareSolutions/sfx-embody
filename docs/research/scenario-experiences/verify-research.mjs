// Verify consistency of the retained research deliverables, not a future renderer.
import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
const readJson=async file=>JSON.parse(await fs.readFile(path.resolve(here,file),'utf8'));
const [summary,contracts,bindings,probes,raw]=await Promise.all([
  readJson('summary.json'),readJson('contract-taxonomy.json'),readJson('scenario-bindings.json'),readJson('existing-form-probes.json'),readJson('../../../evidence/research/scenario-experiences/inventory.json')
]);
assert.deepEqual(summary.proof,raw.proof);
assert.equal(summary.proof.truncated,false);
assert.equal(summary.proof.disposition,'READ_QUERY_COMPLETE');
assert.equal(bindings.length,raw.scenarios.length*2);
assert.equal(new Set(bindings.map(x=>`${x.scenarioVersionPk}:${x.direction}`)).size,bindings.length);
assert.equal(contracts.length,raw.contracts.length);
assert.equal(probes.metaSchemaValidation.passed,raw.contracts.length);
assert.equal(probes.metaSchemaValidation.failures.length,0);
assert.equal(summary.counts.resolvedInputs+summary.unresolved.filter(x=>x.direction==='input').length,raw.scenarios.length);
assert.equal(summary.counts.resolvedOutcomes+summary.unresolved.filter(x=>x.direction==='outcome').length,raw.scenarios.length);
for(const [kind,total] of [['inputs',824],['outcomes',824],['rootInputs',218],['rootOutcomes',218]])assert.equal(Object.values(summary.rootClasses[kind]).reduce((n,x)=>n+x,0),total);
const byContract=new Map(raw.contracts.map(c=>[c.contract_version_pk,c]));
let pointerChecks=0;
for(const c of contracts){
  const source=byContract.get(c.contractVersionPk);
  assert.equal(c.schemaDigest,`sha256:${source.schema_digest}`);
  for(const pointers of Object.values(c.examples))for(const pointer of pointers){
    let value=source.schema;
    for(const key of pointer.slice(2).split('/').filter((x,i)=>pointer!=='#'))value=value[key.replaceAll('~1','/').replaceAll('~0','~')];
    assert.notEqual(value,undefined,`${c.contractId}:${pointer}`);
    pointerChecks++;
  }
}
const md=await fs.readFile(path.join(here,'README.md'),'utf8');
const brokenLinks=[];let localLinks=0;
for(const match of md.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)){
  const target=match[1];
  if(/^https?:\/\//.test(target))continue;
  const resolved=path.resolve(here,target);
  try{await fs.access(resolved);localLinks++;}catch{brokenLinks.push(target);}
}
assert.deepEqual(brokenLinks,[]);
const declaredNotes=new Set([...md.matchAll(/^\[\^(\d+)\]:/gm)].map(m=>m[1]));
for(const m of md.matchAll(/\[\^(\d+)\]/g))assert.ok(declaredNotes.has(m[1]),`missing footnote ${m[1]}`);
const artifactNames=(await fs.readdir(here)).filter(n=>n!=='verification.json').sort();
const artifactDigests={};
for(const n of artifactNames)artifactDigests[n]=`sha256:${createHash('sha256').update(await fs.readFile(path.join(here,n))).digest('hex')}`;
const result={verificationType:'scenario-experience-research-consistency.v1',snapshotId:summary.proof.snapshotId,queryDigest:summary.proof.queryDigest,checks:{scenarioBindings:bindings.length,uniqueScenarios:raw.scenarios.length,contractRecords:contracts.length,retainedSchemaExamplePointers:pointerChecks,localReportLinks:localLinks,footnotes:declaredNotes.size,metaSchemaValidContracts:probes.metaSchemaValidation.passed},artifactDigests,limitations:'Research artifact consistency only; does not certify a renderer or execute capabilities.'};
await fs.writeFile(path.join(here,'verification.json'),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify(result.checks,null,2));
