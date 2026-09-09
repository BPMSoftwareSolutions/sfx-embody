// Static research census, not a renderer or a schema validator.
import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const here=path.dirname(fileURLToPath(import.meta.url));
const data=JSON.parse(await fs.readFile(path.resolve(here,'../../../evidence/research/scenario-experiences/inventory.json'),'utf8'));
const isObj=x=>x!==null&&typeof x==='object'&&!Array.isArray(x);
const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
const esc=s=>s.replaceAll('~','~0').replaceAll('/','~1');
const maps=['properties','patternProperties','$defs','definitions','dependentSchemas'];
const singles=['additionalProperties','unevaluatedProperties','propertyNames','contains','not','if','then','else','additionalItems','unevaluatedItems','contentSchema'];
function walk(s,p,visit){
  if(typeof s==='boolean'){visit(s,p);return;}
  if(!isObj(s))return;
  visit(s,p);
  for(const k of maps)if(isObj(s[k]))for(const [n,c]of Object.entries(s[k]))walk(c,`${p}/${k}/${esc(n)}`,visit);
  for(const k of singles)if(isObj(s[k])||typeof s[k]==='boolean')walk(s[k],`${p}/${k}`,visit);
  for(const k of ['allOf','anyOf','oneOf','prefixItems'])if(Array.isArray(s[k]))s[k].forEach((c,i)=>walk(c,`${p}/${k}/${i}`,visit));
  if(Array.isArray(s.items))s.items.forEach((c,i)=>walk(c,`${p}/items/${i}`,visit));
  else if(isObj(s.items)||typeof s.items==='boolean')walk(s.items,`${p}/items`,visit);
  if(isObj(s.dependencies))for(const [n,c]of Object.entries(s.dependencies))if(!Array.isArray(c))walk(c,`${p}/dependencies/${esc(n)}`,visit);
}
const types=s=>Array.isArray(s.type)?s.type:typeof s.type==='string'?[s.type]:[];
const countBy=(rows,f)=>rows.reduce((m,r)=>{const k=f(r);m[k]=(m[k]??0)+1;return m;},{});
const listFeatures=(s,p)=>{
  if(typeof s==='boolean')return [s?'trueSchema':'falseSchema'];
  const ts=types(s),f=[];
  for(const k of Object.keys(s))f.push(`keyword:${k}`);
  for(const t of ts)f.push(`type:${t}`);
  if(ts.includes('null'))f.push('nullable');
  if(ts.filter(t=>t!=='null').length>1)f.push('multiTypeUnion');
  if(s.$ref)f.push(s.$ref.startsWith('#')?'localRef':'externalRef');
  if(s.$ref&&Object.keys(s).some(k=>!['$ref','$comment','title','description'].includes(k)))f.push('refWithSiblings');
  if(typeof s.format==='string')f.push(`format:${s.format}`);
  if(ts.includes('array')){
    f.push('array');
    if(!own(s,'items')&&!s.prefixItems)f.push('arrayWithoutItems');
    if(isObj(s.items)&&Object.keys(s.items).length===0||s.items===true)f.push('unconstrainedItems');
    if(s.prefixItems||Array.isArray(s.items))f.push('tuple');
  }
  if(ts.includes('object')||s.properties){
    const names=Object.keys(s.properties??{});
    f.push('object');
    if(s.additionalProperties!==false)f.push('objectAllowsAdditionalKeys');
    if(s.additionalProperties===undefined)f.push('objectImplicitAdditionalKeys');
    if(isObj(s.additionalProperties))f.push('typedDictionary');
    if(!names.length && !s.patternProperties && (s.additionalProperties===undefined||s.additionalProperties===true))f.push('openObjectWithoutNamedProperties');
    if(!names.length && s.additionalProperties===false&&!s.patternProperties)f.push('closedEmptyObject');
    if(names.length && s.additionalProperties!==false)f.push('namedObjectAllowsAdditionalKeys');
    if(names.length>12)f.push('objectOver12Properties');
  }
  if(Object.keys(s).length===0)f.push('emptySchema');
  if(s.if||s.then||s.else||s.dependentRequired||s.dependentSchemas||s.dependencies)f.push('conditional');
  if(p.includes('/properties/')&&!p.endsWith('/additionalProperties'))f.push('underPropertyPath');
  return f;
};
function rootClass(s){
  if(typeof s==='boolean')return s?'unconstrained':'impossible';
  if(s.$ref)return 'reference-root';
  if(s.oneOf||s.anyOf||s.allOf)return 'composed-root';
  if(s.type==='object'){
    if(!Object.keys(s.properties??{}).length)return s.additionalProperties===false?'empty-object-root':'open-object-root';
    return own(s.properties,'contractId')&&own(s.properties,'payload')?'enveloped-record':'direct-record';
  }
  return s.type??'typeless-root';
}
const analysis=data.contracts.map(c=>{
  const features={},examples={},nodes=[];
  walk(c.schema,'#',(s,p)=>{nodes.push({s,p});for(const f of listFeatures(s,p)){features[f]=(features[f]??0)+1;(examples[f]??=[]);if(examples[f].length<3)examples[f].push(p);}});
  const refs=nodes.filter(n=>isObj(n.s)&&n.s.$ref).map(n=>({pointer:n.p,ref:n.s.$ref}));
  return {contractVersionPk:c.contract_version_pk,namespace:c.namespace_id,contractId:c.contract_id,schemaDigest:`sha256:${c.schema_digest}`,rootClass:rootClass(c.schema),nodeCount:nodes.length,features,examples,refs};
});
const byPk=new Map(analysis.map(c=>[c.contractVersionPk,c]));
const directions=data.scenarios.flatMap(s=>['input','outcome'].map(direction=>{
  const pk=direction==='input'?s.input_contract_version_pk:s.outcome_contract_version_pk;
  const c=byPk.get(pk);
  if(pk&&!c)throw new Error(`MISSING_SELECTED_CONTRACT:${pk}`);
  return {namespace:s.namespace_id,capabilityId:s.capability_id,scenarioId:s.scenario_id,scenarioVersionPk:s.scenario_version_pk,isRoot:s.is_root,direction,contractVersionPk:pk,contractId:c?.contractId??null,schemaDigest:c?.schemaDigest??null,rootClass:c?.rootClass??'unresolved',features:c?Object.keys(c.features).filter(k=>!k.startsWith('keyword:')&&!k.startsWith('type:')&&!k.startsWith('format:')&&k!=='underPropertyPath'):[]};
}));
const allFeatures=[...new Set(analysis.flatMap(c=>Object.keys(c.features)))].sort();
const inputs=directions.filter(d=>d.direction==='input'),outputs=directions.filter(d=>d.direction==='outcome');
const featureCounts=Object.fromEntries(allFeatures.map(f=>[f,{contracts:analysis.filter(c=>c.features[f]).length,nodes:analysis.reduce((n,c)=>n+(c.features[f]??0),0),inputScenarios:inputs.filter(d=>byPk.get(d.contractVersionPk)?.features[f]).length,outcomeScenarios:outputs.filter(d=>byPk.get(d.contractVersionPk)?.features[f]).length,rootInputs:inputs.filter(d=>d.isRoot&&byPk.get(d.contractVersionPk)?.features[f]).length,rootOutcomes:outputs.filter(d=>d.isRoot&&byPk.get(d.contractVersionPk)?.features[f]).length}]));
const contractIdsByRole=role=>new Set(directions.filter(d=>d.direction===role&&d.contractVersionPk).map(d=>d.contractVersionPk));
const inputIds=contractIdsByRole('input'),outputIds=contractIdsByRole('outcome');
const schemaIds=countBy(data.contracts,c=>c.schema.$id??'ABSENT');
const repeatedSchemaIds=Object.entries(schemaIds).filter(([id,n])=>id!=='ABSENT'&&n>1).map(([id,n])=>({id,contracts:n,distinctDigests:new Set(data.contracts.filter(c=>c.schema.$id===id).map(c=>c.schema_digest)).size}));
const refs=analysis.flatMap(c=>c.refs.map(r=>({contractId:c.contractId,...r})));
const summary={observedAt:data.observedAt,proof:data.proof,method:'Schema-position census including $defs and conditional branches; no runtime coverage or satisfiability claim. Boolean additionalProperties is counted as a subschema; same schema reused by scenarios is counted at each scenario binding.',counts:{selectedDefinitions:data.counts,scenarios:data.scenarios.length,scenarioCapabilities:new Set(data.scenarios.map(s=>s.namespace_id+':'+s.capability_id)).size,rootScenarios:data.scenarios.filter(s=>s.is_root).length,contracts:analysis.length,distinctSchemaBytes:new Set(analysis.map(c=>c.schemaDigest)).size,inputContracts:inputIds.size,outcomeContracts:outputIds.size,sharedBetweenInputAndOutcome:[...inputIds].filter(k=>outputIds.has(k)).length,unboundToScenario:analysis.filter(c=>!inputIds.has(c.contractVersionPk)&&!outputIds.has(c.contractVersionPk)).length,resolvedInputs:inputs.filter(d=>d.contractId).length,resolvedOutcomes:outputs.filter(d=>d.contractId).length,resolvedRootInputs:inputs.filter(d=>d.isRoot&&d.contractId).length,resolvedRootOutcomes:outputs.filter(d=>d.isRoot&&d.contractId).length,sameInputOutcomeContract:data.scenarios.filter(s=>s.input_contract_version_pk&&s.input_contract_version_pk===s.outcome_contract_version_pk).length,outcomeVariants:data.variants.length,scenariosWithVariants:new Set(data.variants.map(v=>v.scenario_version_pk)).size,productRelationships:data.productRelationships},rootClasses:{contracts:countBy(analysis,c=>c.rootClass),inputs:countBy(inputs,c=>c.rootClass),outcomes:countBy(outputs,c=>c.rootClass),rootInputs:countBy(inputs.filter(c=>c.isRoot),c=>c.rootClass),rootOutcomes:countBy(outputs.filter(c=>c.isRoot),c=>c.rootClass)},featureCounts,repeatedSchemaIds,unresolved:directions.filter(d=>!d.contractId),externalRefs:refs.filter(r=>!r.ref.startsWith('#'))};
summary.method+=' Object openness features describe missing LOCAL closure keywords, not effective admission after allOf, references, conditions or unevaluatedProperties. Root class precedence is reference, composition, record envelope, direct record, other type.';
summary.counts.normalizedCapabilities=data.capabilities.length;
summary.capabilitiesWithoutScenarios=data.capabilities.filter(c=>Number(c.scenario_count)===0);
summary.annotationCounts=Object.fromEntries(['title','description','format','default','examples','writeOnly','readOnly','contentMediaType','contentEncoding'].map(k=>[k,featureCounts[`keyword:${k}`]??{contracts:0,nodes:0,inputScenarios:0,outcomeScenarios:0,rootInputs:0,rootOutcomes:0}]));
if(data.scenarios.length!==Number(data.counts.find(c=>c.object_kind==='SCENARIO').definition_count))throw new Error('SCENARIO_COVERAGE_MISMATCH');
if(new Set(data.scenarios.map(s=>s.scenario_version_pk)).size!==data.scenarios.length)throw new Error('DUPLICATE_SCENARIO');
await fs.writeFile(path.join(here,'summary.json'),JSON.stringify(summary,null,2)+'\n');
await fs.writeFile(path.join(here,'contract-taxonomy.json'),JSON.stringify(analysis,null,2)+'\n');
await fs.writeFile(path.join(here,'scenario-bindings.json'),JSON.stringify(directions,null,2)+'\n');
const cell=s=>String(s??'UNRESOLVED').replaceAll('|','\\|');
const md=['# Scenario contract inventory','','One row per selected Scenario. The complete structured taxonomy is in [contract-taxonomy.json](contract-taxonomy.json); pointer-level examples and feature counts are static research observations, not renderer certification. All rows are in `sidefx:capabilities`. Root = declared capability entry scenario.','','| Capability | Scenario | Root | Input contract | Input shape | Outcome contract | Outcome shape |','|---|---|---|---|---|---|---|'];
for(let i=0;i<directions.length;i+=2){const a=directions[i],b=directions[i+1];md.push('| '+[a.capabilityId,a.scenarioId,a.isRoot?'yes':'',a.contractId,a.rootClass,b.contractId,b.rootClass].map(cell).join(' | ')+' |');}
await fs.writeFile(path.join(here,'scenario-inventory.md'),md.join('\n')+'\n');
console.log(JSON.stringify({counts:summary.counts,rootClasses:summary.rootClasses,features:Object.fromEntries(Object.entries(featureCounts).filter(([k])=>!k.startsWith('type:')&&!k.startsWith('keyword:')&&k!=='underPropertyPath')),annotations:Object.fromEntries(Object.entries(featureCounts).filter(([k])=>/^keyword:(title|description|default|examples|readOnly|writeOnly|format|content|oneOf|anyOf|allOf|if|then|else|\$ref)/.test(k))),repeatedSchemaIds:repeatedSchemaIds.length,externalRefs:summary.externalRefs.length,unresolved:summary.unresolved},null,2));
