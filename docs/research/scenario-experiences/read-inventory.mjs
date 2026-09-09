// Read-only research extraction. No capability generation or database mutation.
import fs from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
const databaseRoot=path.resolve(process.argv[2] || 'C:/lab/sidefx-database');
const {query}=await import(pathToFileURL(path.join(databaseRoot,'src/query/run.mjs')));
const statement=await fs.readFile(path.join(here,'inventory.sql'),'utf8');
const result=await query(statement,{retainObjects:false,rowLimit:100000});
if(result.truncated || result.disposition!=='READ_QUERY_COMPLETE')throw new Error('INCOMPLETE_INVENTORY');
const [counts,scenarios,rows,definitions,variants,productRelationships,capabilities]=result.recordsets;
const contracts=rows.map(({content_bytes,definition_json,...r})=>{
  const definition=JSON.parse(definition_json);
  if(!content_bytes)return {...r,definition,schema:null};
  const bytes=Buffer.from(content_bytes.base64,'base64');
  if(createHash('sha256').update(bytes).digest('hex')!==r.schema_digest)throw new Error('SCHEMA_DIGEST_MISMATCH');
  return {...r,definition,schema:JSON.parse(bytes.toString('utf8'))};
});
if(new Set(contracts.map(r=>r.contract_version_pk)).size!==contracts.length)throw new Error('DUPLICATE_CONTRACT_JOIN');
const {recordsets,...proof}=result;
const output={observedAt:new Date().toISOString(),proof,counts,capabilities,scenarios,contracts,definitions:definitions.map(({definition_json,...r})=>({...r,definition:JSON.parse(definition_json)})),variants,productRelationships};
const evidenceDir=path.resolve(here,'../../../evidence/research/scenario-experiences');
await fs.mkdir(evidenceDir,{recursive:true});
await fs.writeFile(path.join(evidenceDir,'inventory.json'),JSON.stringify(output,null,2)+'\n');
console.log(JSON.stringify({proof,counts,scenarios:scenarios.length,contracts:contracts.length,withSchema:contracts.filter(r=>r.schema!==null).length,variants:variants.length,productRelationships},null,2));
