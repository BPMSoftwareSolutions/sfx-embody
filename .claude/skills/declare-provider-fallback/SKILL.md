---
name: declare-provider-fallback
description: Use when a capability must reach a second provider after the first provider's request fails - adding a fallback route, its credential and exchange ports, the selection between provider evidence, and the outcome variants that name the result. Covers which rows to author, what the declared pipeline can and cannot express, and the preflight that proves the fallback before it is installed.
---

# Declare a provider fallback

A fallback is **declared rows**, not code. Nothing in `src/` retries, ranks or
substitutes providers; the estate is a reader. A fallback route exists when the
root execution authority declares the extra operations, a transformation selects
between the routes' evidence, and the scenario declares the variants that name
each result. Lifecycle and non-negotiables: [AGENTS.md](AGENTS.md),
[sql/README.md](sql/README.md).

## 1. Establish the failing route first

Do not author against a guess about why the primary failed. Get the evidence:

```
cmd /c "sfx capability observe <capabilityId> --input '<input>' --trace"
cmd /c "sfx capability invoke <capabilityId> --input '<input>' --json"
```

Read the exchange operation's `governed-http-exchange-evidence.v1`:
`disposition`, `reachedStage`, `exchangeCount`, `transportDisposition`. These
decide whether a fallback is even the right change:

- `exchangeCount >= 1` with a provider-side rejection (quota, 4xx/5xx, timeout)
  - the provider answered and failed. A fallback route is warranted.
- `exchangeCount: 0` - **no request was made**. The failure is credential
  binding, endpoint admission, or a kernel/altitude artifact. A second provider
  fails identically. Fix the cause or file it; see
  [docs/sda-change-request-effect-altitude-execution.md](docs/sda-change-request-effect-altitude-execution.md)
  for the open physical-altitude defect that produces exactly this signature.

Then capture the working generation as the baseline (`evidence/<capability>/`),
because every claim below is a diff against it.

## 2. The rows a fallback adds

One migration in `sql/migrations/`, following the lifecycle. Five declared
changes:

| # | Row | Where authored |
| --- | --- | --- |
| 1 | Port bindings for the fallback route (its credential binding port, its exchange port) | `@port_bindings` of `model.declare_scenario`, or minted directly |
| 2 | The transformation that builds the fallback request | `model.put_semantic_definition 'TRANSFORMATION'` + `model.transformation_version` + `model.normalize_transformation_expression` |
| 3 | The operations, in order, on the root execution authority | `@operations`, or a minted `execution_authority_version` |
| 4 | The selection: which route's evidence becomes the outcome, and the provider identity that travels with it | the normalize/select transformation expression |
| 5 | The outcome variants and their `success`/`failure` classification | `@scenario.variants` (object form) |

`model.declare_scenario`
([sql/schema/declare-scenario.sql:68](sql/schema/declare-scenario.sql#L68)) does
1, 3 and 5 in one call and upserts variants on every declaration. Transformation
bodies are never authored by it - see
[guard-equity-response-decoding.sql:22](sql/migrations/guard-equity-response-decoding.sql#L22)
for the expression-authoring pattern (put the definition, mint the
`transformation_version` with `expression_profile='json-expression-tree.v1'`,
then normalize the expression into nodes).

### Port configuration for the new route

The exchange port (`sda-governed-http-exchange-port.v1`) declares
`endpointAuthorities[]` (`urlPrefixes`, `methods`, `allowedRequestHeaders`,
`allowedResponseHeaders`, `endpointAuthorityDigest`) and
`credentialInjectionRules[]`. The credential port
(`sda-external-credential-reference-binding-port.v1`) declares
`credentialAuthorities[]` (`referenceName`, `source`, `effectScopes`,
`requestingCapabilityIds`, `injectionRule`, `endpointAuthorityDigests`).

The **`endpointAuthorityDigest` ties the two together and must match exactly**.
Nothing in this repo computes it - it is only carried
([scripts/invoke-from-transaction.mjs:65](scripts/invoke-from-transaction.mjs#L65)).
It is declared authority you obtain from the endpoint authority that grants the
route. If you cannot obtain it, the change is blocked and that is a finding.
**Never compute, guess or copy a digest to make a preflight pass** - a route
admitted under a fabricated digest is fabricated authority.

The fallback provider needs its own credential reference name, its own injection
rule, and its own scope. Reusing the primary's credential row for a different
host declares something that is not true.

## 3. What the declared pipeline can and cannot express

These constraints decide the shape. Check them before designing.

- **Operations are a linear pipeline with no guard.** `model.execution_operation`
  carries `ordinal` and `operation_kind` only. There is no declared "run this
  operation only if the previous failed". Every declared operation runs. The only
  declared surface that can vary is the *expression* that builds the fallback
  request. Whether an effect port then performs a transport when handed a
  guarded or empty request is **port behavior: verify it in the preflight, never
  assume it**. If the port exchanges regardless, what you have is "always call
  both providers" - which may be acceptable, or is a finding to file under
  [docs/embodiment-completeness.md](docs/embodiment-completeness.md). Do not
  invent port behavior to make the fallback look conditional.
- **Each operation sees only `root` and `input`.** `root` is the scenario input;
  `input` is the previous operation's outcome. The primary attempt's evidence is
  *not* reachable from the selection step unless every intervening transformation
  copies it forward. Design the carrier before you design the route.
- **`invoke-scenario` cannot be authored through `model.declare_scenario`** - it
  throws `SCENARIO_OPERATION_BINDING_NOT_DECLARED`
  ([declare-scenario.sql:148](sql/schema/declare-scenario.sql#L148)) for any
  operation that is not an `invoke-port` with a binding. To put the fallback in
  its own scenario, mint the authority version directly - the pattern is
  [compose-speech-provider-http-exchange.sql](sql/migrations/compose-speech-provider-http-exchange.sql).
  Note the boundary in [sql/README.md](sql/README.md): drop-in composition works,
  adapter composition (slicing a caller carrier around a child) is not yet
  expressible, and a child's `rejected` disposition fails the parent - which is
  the disposition a failing primary route produces.
- **Expression ops in use**: `let`, `path`, `literal`, `if`, `equals`, `object`,
  `array`, `filter`, `length`, `try-parse-json`, `base64-decode-utf8`. Selection
  is `if`/`equals` over the evidence, not a new operator.
- **`let` bindings lower in document order.** Dependency order, never
  alphabetical, or a binding reference lowers as an input path and throws at
  runtime.

## 4. The selection must carry provider identity

The outcome's provider attribution is currently a **literal** in the normalize
expression (`bindingId`, `providerId`, `nativeShape`). With two routes those
literals become selections keyed to the route that actually answered. Read the
current expression from the model before changing it - `evidence/` is local and
gitignored, so it may not be present:

```sql
SELECT JSON_QUERY(definition_json,'$.semantics.expression')
FROM analysis.v_selected_semantic_definition
WHERE object_kind='TRANSFORMATION'
  AND namespace_id=N'sidefx:capability:<capabilityId>'
  AND declared_id=N'<transformationId>';
```

This is the part that is easy to get wrong and impossible to detect downstream:
evidence from provider B carrying provider A's `providerTestimony` is fabricated
authority. The same applies to `nativeShape` - each provider's native response
shape is its own, and the selection that picks a field must pick the shape with
it.

The failure disposition must also stay true: "no route completed" is a different
statement from "the primary was unavailable". Declare a variant that says which.

## 5. Reuse the vocabulary the estate already declares

The estate already declares provider-fallback vocabulary in the scaffolded
`select-equity-market-price-provider` authority. Its contracts
(`route-request`, `fallback-request`, `route-decision`, `route-hold`,
`route-rejection`) carry the terms: `routeOrder`,
`fallbackEligibleFailureClasses`, `attemptBudget`, `bindings[]` with
`bindingId`/`providerId`/`admitted`/`entitled`/`mappingClosed`,
`preferredBindingId`, `failureClass`, `attemptsUsed`; and the scenarios
`fallback-on-declared-equity-market-price-provider-unavailability`,
`hold-equity-market-price-provider-route`,
`reject-unsafe-equity-market-price-fallback`.

The scaffold output itself lives under `evidence/scaffold-output/`, which is
gitignored and may not be present; the capability and its four scenario names
are recorded durably in
`docs/research/canonical-feature-migration/review-20260911.json`. If neither is
at hand, re-derive the vocabulary from the declaration rather than restating it
from this skill.

Use those terms. Inventing a parallel vocabulary in a migration authors meaning
that no declaration backs. If the change needs a term that is declared nowhere,
you are authoring a capability, not adding a route - stop and say so.

## 6. Author, preflight, install, verify

Per [sql/README.md](sql/README.md). The skeleton - guards dropped inside the
script, its own `BEGIN TRANSACTION`, before/after result sets, ending in
`ROLLBACK` - is in
[templates/declare-fallback-route.sql](.claude/skills/declare-provider-fallback/templates/declare-fallback-route.sql).

```
node scripts/run-migration.mjs sql/migrations/<file>.sql
node --experimental-vm-modules scripts/invoke-from-transaction.mjs sql/migrations/<file>.sql <capabilityId> <input.json>
```

The preflight is the only place the whole change is exercised before it can
affect consumers. For a fallback it must answer three questions, not one:

1. **Primary succeeds** - the outcome is the primary's evidence, attributed to
   the primary, and the fallback route did not corrupt the carrier.
2. **Primary fails** - the outcome is the fallback's evidence, attributed to the
   fallback, with the declared variant. Reproduce the real failure (revoke the
   credential reference, or use the live quota rejection); do not simulate it by
   editing the expression.
3. **Both fail** - the declared "no route completed" variant, not a partially
   filled payload.

Then install (`ROLLBACK` to `COMMIT`, `node scripts/run-migration.mjs`), verify
through the real surface with `--trace` (both routes' cells visible, the
selection resolving, the variant classified), and commit - one migration per
commit.

## Traps

- **Blueprint slot inventory asserts the operation count.** Provider slots are
  declared per port and the requirements migration hard-asserts the shape -
  `EQUITY_WORKING_EXECUTION_DIVERGED` at
  [declare-equity-provider-slot-requirements.sql:49](sql/migrations/declare-equity-provider-slot-requirements.sql#L49).
  New operations mean the slot requirements are re-declared in the same change.
- **A new transformation id must be registered, and its envelope must carry
  `"id"`.** `model.put_semantic_definition 'TRANSFORMATION'` only defines the
  semantic object; the graph compiler also needs the registry row
  (`INSERT model.transformation(namespace_pk, transformation_id,
  semantic_object_pk, object_kind) SELECT namespace_pk, @id, @object,
  'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk=@object`),
  and the semantics envelope must be `{"id":…,"expression":…}` - without it
  compilation fails `GRAPH_COMPILER_INVALID_TRANSFORMATION_ID`. The template
  does both.
- **Long string literals truncate silently near 4000 characters.** Paste live
  port bindings and operations as several `N'…'` chunks under 4000 each, begin
  the concatenation with `CONVERT(nvarchar(max), N'…')`, and interpolate a
  variable inside a chunk as `N'…"' + @var + N'"…'` (a single `+`). The doubled
  form stores the literal text instead of the value and surfaces later as
  `IDENTITY_MISMATCH` at credential binding.
- **Variant classification is upserted; the scenario digest is not.** Variants
  are not part of the scenario semantics digest, so a classification change takes
  effect on re-declaration even when nothing else moved. Object form
  `{"variantId":"...","classification":"success|failure"}`; `success`/`failure`
  only, or `SCENARIO_VARIANT_CLASSIFICATION_INVALID`.
- **Idempotency.** A re-run must not mint a second authority version or
  double-link a port. Guard on the envelope digest, as
  [restore-equity-root-authority.sql](sql/migrations/restore-equity-root-authority.sql)
  does.
- **Never install with `sidefx-database/sql/migrations/run-file.mjs`** - it wraps
  its own transaction and silently discards the script's `COMMIT`.
- **Capture `--json` through `cmd /c`**; PowerShell 5.1 corrupts native stderr.
  Write input files without a BOM.
- **No capsule, artifact or projection vocabulary in a migration.** On the
  database surface it is all rows.
