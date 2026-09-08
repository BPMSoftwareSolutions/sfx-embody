import vm from 'node:vm';
import crypto from 'node:crypto';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const hash = content => 'sha256:' + crypto.createHash('sha256').update(content).digest('hex');
const origin = 'sidefx-memory://body/';

// A candidate loading provider for the existing native body. Source is compiled
// unchanged. Only its storage/import boundary is different. This is not a
// security sandbox or an admitted replacement for the estate execution surface.
export async function loadMemoryScenario(plan) {
  if (!vm.SourceTextModule) throw new Error('MEMORY_MODULE_FLAG_REQUIRED: use --experimental-vm-modules');
  const files = new Map();
  for (const file of plan.files.filter(f => f.relativePath.includes('/body/'))) {
    const url = new URL(file.relativePath, origin);
    if (url.href !== origin + file.relativePath || url.search || url.hash) throw new Error('MEMORY_RESOURCE_PATH_INVALID');
    if (files.has(url.href)) throw new Error('MEMORY_RESOURCE_COLLISION');
    if (hash(file.content) !== file.digest) throw new Error('MEMORY_RESOURCE_DIGEST_MISMATCH:' + file.relativePath);
    files.set(url.href, { ...file });
  }
  const accesses = [], modules = new Map();
  const resource = reference => {
    const id = String(reference);
    const file = files.get(id);
    if (!file) throw new Error('MEMORY_RESOURCE_UNAVAILABLE:' + id);
    accesses.push({ kind: 'resource', id, digest: file.digest });
    return file;
  };
  const memoryFs = Object.freeze({
    readFileSync(reference, encoding) {
      const bytes = Buffer.from(resource(reference).content);
      const selectedEncoding = typeof encoding === 'string' ? encoding : encoding?.encoding;
      return selectedEncoding ? bytes.toString(selectedEncoding) : bytes;
    }
  });
  const packages = [...files.values()].filter(f => f.relativePath.endsWith('/body/package.json')).map(f => JSON.parse(f.content));
  const dependencyVersions = new Set(packages.map(p => p.dependencies?.ajv));
  if (dependencyVersions.size !== 1 || !dependencyVersions.has(require('ajv/package.json').version)) throw new Error('MEMORY_EXTERNAL_DEPENDENCY_VERSION_MISMATCH');
  const boundRequire = specifier => {
    if (specifier !== 'ajv/dist/2020') throw new Error('MEMORY_EXTERNAL_DEPENDENCY_UNBOUND:' + specifier);
    accesses.push({ kind: 'installed-dependency', specifier, version: require('ajv/package.json').version });
    return require(specifier);
  };
  const builtinValues = new Map([
    ['node:crypto', { default: crypto, ...crypto }],
    ['node:fs', { default: memoryFs, ...memoryFs }],
    ['node:module', { createRequire: reference => { resource(reference); return boundRequire; } }]
  ]);
  const moduleFor = id => {
    if (modules.has(id)) return modules.get(id);
    let module;
    if (builtinValues.has(id)) {
      const values = builtinValues.get(id);
      module = new vm.SyntheticModule(Object.keys(values), function () {
        for (const [name, value] of Object.entries(values)) this.setExport(name, value);
      }, { identifier: id });
    } else {
      const file = resource(id);
      if (!/\.(mjs|js)$/.test(file.relativePath)) throw new Error('MEMORY_MODULE_TYPE_UNSUPPORTED:' + id);
      module = new vm.SourceTextModule(file.content, {
        identifier: id,
        initializeImportMeta: meta => { meta.url = id; }
      });
    }
    modules.set(id, module);
    return module;
  };
  const entry = plan.receipts.find(r => r.plan.scenarioId === plan.selectedScenarioId);
  if (!entry) throw new Error('MEMORY_SELECTED_SCENARIO_MISSING');
  const root = moduleFor(origin + entry.base + '/body/composition.mjs');
  await root.link((specifier, parent) => {
    if (builtinValues.has(specifier)) return moduleFor(specifier);
    if (!specifier.startsWith('.')) throw new Error('MEMORY_IMPORT_UNBOUND:' + specifier);
    return moduleFor(new URL(specifier, parent.identifier).href);
  });
  await root.evaluate();
  return {
    createScenario: root.namespace.createScenario,
    accesses,
    modules: [...modules].filter(([id]) => id.startsWith(origin)).map(([id]) => ({ id, digest: files.get(id).digest })),
    externalDependencies: [{ name: 'ajv', version: require('ajv/package.json').version }]
  };
}
