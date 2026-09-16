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
