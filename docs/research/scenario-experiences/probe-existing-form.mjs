// Bounded research probes of the existing helper. No UI or runtime changes.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import ts from 'typescript';
import Ajv2020 from 'ajv/dist/2020.js';
const here=path.dirname(fileURLToPath(import.meta.url));
const platformRoot=path.resolve(process.argv[2]??'C:/lab/repos/sfx-platform');
const source=await fs.readFile(path.join(platformRoot,'lib/json-schema-form.ts'),'utf8');
const js=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ES2022,target:ts.ScriptTarget.ES2022}}).outputText;
const helper=await import(`data:text/javascript;base64,${Buffer.from(js).toString('base64')}`);
const inventory=JSON.parse(await fs.readFile(path.resolve(here,'../../../evidence/research/scenario-experiences/inventory.json'),'utf8'));
const contracts=new Map(inventory.contracts.map(c=>[c.contract_version_pk,c]));
const sourceDigest=`sha256:${createHash('sha256').update(source).digest('hex')}`;
const rootSchemas=inventory.scenarios.filter(s=>s.is_root&&s.input_contract_version_pk).map(s=>({scenario:s,contract:contracts.get(s.input_contract_version_pk)}));
const noTopLevelFields=rootSchemas.filter(r=>helper.objectProperties(r.contract.schema).length===0).map(r=>({capabilityId:r.scenario.capability_id,contractId:r.contract.contract_id}));
const fixtures=[
  {name:'required boolean has no declared default',schema:{type:'object',required:['consent'],properties:{consent:{type:'boolean'}}}},
  {name:'optional const still seeded',schema:{type:'object',properties:{optional:{const:'x'}}}},
  {name:'closed empty object is a valid no-field payload',schema:{type:'object',additionalProperties:false}},
  {name:'root union has no direct properties',schema:{oneOf:[{type:'object',properties:{x:{type:'string'}}},{type:'object',properties:{y:{type:'integer'}}}]}},
  {name:'boolean property schemas are omitted',schema:{type:'object',properties:{arbitrary:true,forbidden:false}}},
  {name:'reference sibling constraint',schema:{$defs:{text:{type:'string'}},$ref:'#/$defs/text',minLength:4}}
];
const helperProbes=fixtures.map(f=>({name:f.name,schema:f.schema,field:helper.describeField(f.schema,f.schema),initial:helper.initialDocument(f.schema),propertyKeys:helper.objectProperties(f.schema).map(([k])=>k)}));
const ajv=new Ajv2020({allErrors:true,strict:false});
const schemaFailures=[];
for(const c of inventory.contracts)if(!ajv.validateSchema(c.schema))schemaFailures.push({contractId:c.contract_id,schemaDigest:c.schema_digest,errors:structuredClone(ajv.errors)});
const result={source:{path:path.join(platformRoot,'lib/json-schema-form.ts'),digest:sourceDigest},snapshotId:inventory.proof.snapshotId,resolvedRootInputs:rootSchemas.length,noTopLevelFields,noTopLevelFieldsCount:noTopLevelFields.length,helperProbes,metaSchemaValidation:{validator:'Ajv 8.20.0 / Ajv2020',contracts:inventory.contracts.length,passed:inventory.contracts.length-schemaFailures.length,failures:schemaFailures},limitations:'Helper probes and JSON Schema meta-schema validation only. No browser interaction, instance admission, external-reference closure, output renderer or capability execution proof.'};
await fs.writeFile(path.join(here,'existing-form-probes.json'),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({source:result.source,noTopLevelFieldsCount:result.noTopLevelFieldsCount,helperProbes:helperProbes.map(p=>({name:p.name,kind:p.field.kind,initial:p.initial,propertyKeys:p.propertyKeys})),metaSchemaValidation:result.metaSchemaValidation},null,2));
