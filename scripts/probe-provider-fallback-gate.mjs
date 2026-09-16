import { createGovernedEffectContext } from 'file:///C:/lab/repos/scenario-driven-architecture/languages/typescript/runtimes/node/native-mechanic-primitives.mjs';
import { bindExternalCredentialReference } from 'file:///C:/lab/repos/scenario-driven-architecture/languages/typescript/runtimes/node/external-credential-reference-binding-provider.mjs';
import { observeGovernedHttpExchange } from 'file:///C:/lab/repos/scenario-driven-architecture/languages/typescript/runtimes/node/governed-http-exchange-provider.mjs';

const credentialConfiguration = {
  credentialAuthorities: [{
    effectScopes: ['ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY'],
    endpointAuthorityDigests: ['sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b'],
    injectionRule: { headerName: 'X-RapidAPI-Key', id: 'rapidapi-x-rapidapi-key.v1' },
    lifetimeMilliseconds: 15000,
    referenceName: 'RAPID_API_KEY',
    requestingCapabilityIds: ['resolve-equity-market-price-evidence'],
    source: 'environment'
  }]
};
const exchangeConfiguration = {
  credentialInjectionRules: [{ headerName: 'X-RapidAPI-Key', id: 'rapidapi-x-rapidapi-key.v1' }],
  endpointAuthorities: [{
    allowedRequestHeaders: ['x-rapidapi-host'],
    allowedResponseHeaders: ['content-type', 'retry-after'],
    endpointAuthorityDigest: 'sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b',
    methods: ['GET'],
    urlPrefixes: ['https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?']
  }]
};
const context = { rootExecutionId: 'probe:fallback-gate' };
const invocationIdentity = 'probe:invocation:1';
const endpointAuthorityDigest = 'sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b';

function summarize(label, value) {
  const keys = ['disposition', 'reachedStage', 'exchangeCount', 'transportDisposition', 'httpStatus', 'timing'];
  const picked = Object.fromEntries(keys.map(key => [key, value?.[key]]));
  console.log(label, JSON.stringify(picked));
}

// 1. Guarded request: the primary succeeded, so the fallback request is empty.
const guard = await observeGovernedHttpExchange(exchangeConfiguration, { requestUrl: null }, context);
summarize('guarded-empty-request:', guard);

// 2. Binding without a live one-use binding: pre-network rejection.
const noBinding = await observeGovernedHttpExchange(exchangeConfiguration, {
  requestUrl: 'https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol=AVGO&region=US',
  method: 'GET',
  safeHeaders: { 'x-rapidapi-host': 'yahoo-finance166.p.rapidapi.com' },
  allowedResponseHeaders: ['content-type', 'retry-after'],
  timeoutMilliseconds: 15000,
  maxResponseBytes: 1000000,
  requestBodyText: '',
  invocationIdentity,
  endpointAuthorityDigest,
  credentialInjectionRuleId: 'rapidapi-x-rapidapi-key.v1'
}, context);
summarize('no-live-binding:', noBinding);

// 3. Full route with a live one-use binding: the provider answers (429 expected).
const effectContext = createGovernedEffectContext();
const binding = await bindExternalCredentialReference(credentialConfiguration, {
  credentialReference: 'RAPID_API_KEY',
  invocationIdentity,
  requestingCapabilityId: 'resolve-equity-market-price-evidence',
  endpointAuthorityDigest,
  effectScope: 'ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY'
}, context, effectContext);
summarize('credential-binding:', binding);
const exchange = await observeGovernedHttpExchange(exchangeConfiguration, {
  requestUrl: 'https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?symbol=AVGO&region=US',
  method: 'GET',
  safeHeaders: { 'x-rapidapi-host': 'yahoo-finance166.p.rapidapi.com' },
  allowedResponseHeaders: ['content-type', 'retry-after'],
  timeoutMilliseconds: 15000,
  maxResponseBytes: 1000000,
  requestBodyText: '',
  invocationIdentity,
  endpointAuthorityDigest,
  credentialInjectionRuleId: 'rapidapi-x-rapidapi-key.v1',
  opaqueCredentialBinding: { bindingId: binding.opaqueBindingId, credentialInjectionRuleId: 'rapidapi-x-rapidapi-key.v1' }
}, context, effectContext);
summarize('live-route:', exchange);
