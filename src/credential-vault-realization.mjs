import { pathToFileURL } from 'node:url';

const isObject = value => value !== null && typeof value === 'object' && !Array.isArray(value);

// The OS-neutral binding point for the host's credential-store realization. The
// profile behind it is the per-host data (Windows DPAPI/CNG, macOS Keychain,
// Linux Secret Service/TPM, a future cloud KMS); the same binding serves every
// host. No capability contract or capability configuration ever names a
// keystore: the vault port reads only the realization the host selected.
export const CREDENTIAL_STORE_REALIZATION_MECHANIC_ID = 'sda-credential-store-realization.v1';

function declaredProviderProfileId(configuration) {
  const bindings = Array.isArray(configuration?.overlayBindings) ? configuration.overlayBindings : [];
  const binding = bindings.find(entry => entry?.mechanicId === CREDENTIAL_STORE_REALIZATION_MECHANIC_ID
    && typeof entry?.providerProfileId === 'string' && entry.providerProfileId.length > 0);
  if (binding) return binding.providerProfileId;
  const profiles = Array.isArray(configuration?.providers) ? configuration.providers : [];
  const named = profiles.find(entry => entry?.providerProfileId === CREDENTIAL_STORE_REALIZATION_MECHANIC_ID);
  return named ? CREDENTIAL_STORE_REALIZATION_MECHANIC_ID : null;
}

function sealedRealization(realizationId) {
  return Object.freeze({ realizationId, releaseKeyHandle: () => Object.freeze({ sealed: true }) });
}

function normalizedRealization(candidate, realizationId) {
  if (!isObject(candidate) || typeof candidate.releaseKeyHandle !== 'function') return sealedRealization(realizationId);
  return typeof candidate.realizationId === 'string' && candidate.realizationId.length > 0
    ? candidate : { ...candidate, realizationId };
}

// A declared vault configuration may reference a host environment root: the
// vault store locator is declared as `%LOCALAPPDATA%\sfx\vault` (the OS default
// home for the ciphertext). The boot resolves those references against the host
// environment before the kernel or a provider sees the configuration, so the
// provider never expands a path and no key material or plaintext is involved.
// An unknown reference is left verbatim; the provider then fails closed on the
// unresolvable locator rather than guessing a location.
const ENVIRONMENT_REFERENCE = /%([A-Za-z_][A-Za-z0-9_]*)%/g;
export function resolveDeclaredEnvironmentReference(value) {
  return String(value).replace(ENVIRONMENT_REFERENCE, (match, name) =>
    typeof process.env[name] === 'string' && process.env[name].length > 0 ? process.env[name] : match);
}
function expandLocator(entry) {
  return isObject(entry) && typeof entry.storeLocator === 'string' && entry.storeLocator.includes('%')
    ? { ...entry, storeLocator: resolveDeclaredEnvironmentReference(entry.storeLocator) }
    : entry;
}
// The vault keys that may carry a declared locator: the vault port's own
// `storeLocator` and each credential authority's `storeLocator` (W4's source
// switch declares one per switched authority). Everything else is untouched.
export function resolveCredentialVaultLocators(configuration) {
  if (!isObject(configuration)) return configuration;
  let resolved = configuration;
  if (typeof configuration.storeLocator === 'string' && configuration.storeLocator.includes('%')) {
    resolved = { ...resolved, storeLocator: resolveDeclaredEnvironmentReference(configuration.storeLocator) };
  }
  if (Array.isArray(configuration.credentialAuthorities)) {
    const authorities = configuration.credentialAuthorities.map(expandLocator);
    if (authorities.some((entry, index) => entry !== configuration.credentialAuthorities[index])) {
      resolved = { ...resolved, credentialAuthorities: authorities };
    }
  }
  return resolved;
}
// The declared graph source carries its Port bindings; the boot resolves the
// vault locators once, before the graph is handed to the kernel and compiled.
export function resolveCredentialVaultLocatorsInGraphSource(graphSource) {
  const bindings = graphSource?.interfaceAuthority?.portBindings;
  if (!Array.isArray(bindings)) return graphSource;
  let changed = false;
  const portBindings = bindings.map(binding => {
    if (!isObject(binding) || !isObject(binding.configuration)) return binding;
    const configuration = resolveCredentialVaultLocators(binding.configuration);
    if (configuration === binding.configuration) return binding;
    changed = true;
    return { ...binding, configuration };
  });
  return changed ? { ...graphSource, interfaceAuthority: { ...graphSource.interfaceAuthority, portBindings } } : graphSource;
}

// Resolve the realization through the ordinary provider-resolution path: the
// binding names a profile, the profile names a module and export under the SDA
// root, and the export creates the realization that owns key custody. Any
// broken or absent declaration yields a sealed realization, never an
// environment fallback: the vault port then refuses with VAULT_SEALED and no
// key material is released.
export async function resolveCredentialStoreRealization(configuration, context = {}) {
  const providerProfileId = declaredProviderProfileId(configuration);
  if (providerProfileId === null) return null;
  const profiles = Array.isArray(configuration?.providers) ? configuration.providers : [];
  const entry = profiles.find(candidate => candidate?.providerProfileId === providerProfileId);
  if (!entry || typeof entry.module !== 'string' || entry.module.length === 0
    || typeof entry.export !== 'string' || entry.export.length === 0
    || typeof context?.sdaRoot !== 'string' || context.sdaRoot.length === 0) {
    return sealedRealization(providerProfileId);
  }
  try {
    const base = pathToFileURL(String(context.sdaRoot).replace(/\\/g, '/').replace(/\/?$/, '/')).href;
    const providerModule = await import(new URL(entry.module, base).href);
    const providerExport = providerModule[entry.export];
    const created = typeof providerExport === 'function'
      ? await providerExport({ platform: process.platform, providerProfileId })
      : providerExport;
    return normalizedRealization(created, providerProfileId);
  } catch {
    return sealedRealization(providerProfileId);
  }
}
