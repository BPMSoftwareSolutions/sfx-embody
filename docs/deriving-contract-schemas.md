# Deriving contract schemas from semantic transformation authority

Proposal: 2026-09-09. Status: design for review. Nothing here is implemented.

## Scope — read before acting on this document

This document proposes **one thing**: deriving JSON Schema contract documents
from an authored semantic transformation expression, and comparing derived
against authored as an oracle.

**In scope**

- Inferring contract property sets, types, `const`/`enum` and requiredness from
  a transformation expression tree.
- Reporting divergence between a derived schema and an admitted one.
- The four generator rules under "Rules the generator must obey".

**Out of scope — do not start work here from this document**

- *How a capability is promoted into the database.* That mechanism already
  exists and is settled; see below. This document does not propose, extend or
  replace it.
- *Repairing existing rows.* Corrections to already-registered capabilities are
  separate work with their own records.
- *The editor and the conveyor.* "Where this leads" is a trajectory statement for
  planning, not a work item. It names two constraints any such build must honour;
  it does not authorise starting one.
- *Contract admission policy.* Whether a derived schema may ever be admitted
  without human narrowing is a governance decision this document deliberately
  leaves open, and answers "no" for now.

**The promotion mechanism, stated once so it is not re-derived**

A capability enters the database through the `register` command in
`sidefx-database`:

```powershell
cd C:\lab\sidefx-database
node src/cli.mjs register --spec config/register/<spec>.json --dry-run
```

It packs the authored artifacts into a `sidefx-capsule-pack.v1` capsule, reads
that capsule back through the estate's own `decodeCapsule`, and promotes it under
a new mapping rule (`sidefx-capability-provisioning.v1`) as a new
`source.estate_model` over the **same** `estate_snapshot`. Generation 14 was
produced this way.

It is **not** produced by hand-written SQL, and **not** by `capture`/`derive`,
which observe the harness working tree rather than authored artifacts. Two
warnings follow from that:

- `docs/research/scaffold-projection-gap/register-equity-capabilities.sql` is a
  superseded artifact. It is 302 KB of hand-written INSERTs, it never completed
  (it aborts on `PUBLISHED_MEMBERSHIP_IMMUTABLE`), and it is not the mechanism.
  Do not extend it.
- Hand-written promotion SQL reproduces the divergence residue already recorded
  for the undefined-literal repair — corrections reproducible by script but not
  by the pipeline, with stale `capsule_digest` values left behind. The `register`
  command exists specifically so that promotion is a consequence of bytes.

## The gap this fills

`generate-executable-capability-scaffold` emits `contracts/contract-catalog.json`
naming the contracts a capability declares — and emits **no schema files**. For
`resolve-equity-market-price-evidence` the scaffold produced a catalog naming
five contracts and zero schemas, so the capability could not be admitted,
projected or invoked until the schemas were hand-authored.

That hand-authoring is the current bottleneck between "scaffold generated" and
"capability registered". This document asks how much of it can be derived from
the semantic transformation authority that is authored alongside it, and — more
carefully — how much of it *should* be.

## Operating the pipeline

Both steps below were exercised for this proposal; the commands are the ones
that ran, not illustrations.

### Invoking a capability from the database, with nothing on disk

```powershell
cd C:\lab\repos\sfx-embody
sfx capability invoke generate-executable-capability-scaffold `
  --input '@examples/rapidapi-scaffold.request.json' --json
```

No capability body, authority bundle or capsule is written anywhere. Each call
reads the selected authority through the restricted SQL reader, plans the native
body in memory, links it, and executes it. There is no preparation step and no
prerequisite: `prepare` remains available as a separate retained proof and is
never consulted by `invoke`.

The working directory matters — `sfx.config.json` selects the process binding in
`config/sfx.commands.json`, which routes to the database delivery. From anywhere
else, name it explicitly:

```powershell
sfx capability invoke <capabilityId> --input '@request.json' --json `
  --config C:\lab\repos\sfx-embody\sfx.config.json
```

The result envelope arrives on **stdout**; failures arrive on **stderr** as JSON
with a `code`, and the exit code is `0` on success or `4` on a capability
failure. Its shape:

```text
{ capabilityId, scenarioId, executions, observations, evidence,
  result: { executionId, scenarioId, input, event, outcome, disposition } }
```

One scripting note: `sfx` is a PowerShell shim, and Windows PowerShell 5.1 wraps
native stderr in error records, which makes redirection awkward. When capturing
output programmatically, call the CLI entry point directly:

```powershell
node C:\nvm4w\nodejs\node_modules\sidefx-cli\bin\sfx.mjs capability invoke `
  <capabilityId> --input '@request.json' --json > out.json 2> err.json
```

### Storing the generated scaffold on disk

`generate-executable-capability-scaffold` writes nothing. Its feature is explicit
that it "reads no filesystem ... authors no capability, admits no authority", and
that holds literally: there is no temporary directory and no output root. The
artifacts come back **inside the outcome payload**:

```text
result.outcome.authoredArtifacts: [ { artifactPath, artifact }, … ]
```

`artifactPath` is a *proposed* estate path (`capabilities/<capabilityId>/…`), not
a location anything wrote to. If the invocation's stdout is not captured, the
scaffold is gone.

To land it on disk, capture stdout and write each artifact:

```js
import fs from 'node:fs';
import path from 'node:path';

const envelope = JSON.parse(fs.readFileSync('out.json', 'utf8'));
const outputRoot = 'evidence/scaffold-output/resolve-equity-market-price-evidence';

for (const { artifactPath, artifact } of envelope.result.outcome.authoredArtifacts) {
  // Strip the capabilities/<id>/ prefix to land the capability's own tree.
  const relative = artifactPath.replace(/^capabilities\/[^/]+\//, '');
  const file = path.join(outputRoot, relative);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(artifact, null, 2) + '\n');
}
```

For `resolve-equity-market-price-evidence` this writes eight files:
`capability.authority.json`, `blueprint.authority.json`,
`interfaces.authority.json`, `execution-authorities.authority.json`,
`semantic-graph.authority.json`, `projection-authorities.authority.json`,
`contracts/contract-catalog.json`, and `semantic-transformation.authority.json`.

Two things to expect from that output, both relevant to this proposal:

- `semantic-transformation.authority.json` arrives with the root transformation's
  `expression` set to `null` and the id listed in `unresolvedTransformationIds`.
  The scaffold refuses to write meaning; that expression is the hand-authoring
  step this document is about accelerating *from*.
- `contracts/contract-catalog.json` names its contracts and **no schema files are
  emitted**. That is the gap below.

## What is derivable, demonstrated

The claim below is not hypothetical. It was checked against the transformation
authority authored for `resolve-equity-market-price-evidence`
([semantic-transformation.authority.json](../evidence/scaffold-output/resolve-equity-market-price-evidence/semantic-transformation.authority.json))
and compared field-by-field with the schemas that were hand-authored for it.

### Outcome shape — strong derivation

The root transformation's `value` is an `if` over two `object` expressions:

```text
value: if(conforming,
  object{ contractId, disposition, payload, providerTestimony },
  object{ contractId, disposition, reasonCode, absentFieldCount, providerTestimony })

payload:           object{ symbol, region, currency, observedPrice,
                           observedMarketTime, marketState, exchange, sourceAttribution }
providerTestimony: object{ bindingId, providerId, nativeShape }
```

Every property name of the outcome contract is present, at every nesting level.
The union of the two branches is exactly the property set of the hand-authored
`evidence.schema.json`. Further:

- `literal` values in field positions give `const` candidates
  (`contractId: "equity-market-price-evidence.v1"`).
- The set of `literal` values a field takes across branches gives an `enum`
  candidate (`disposition` → the two dispositions, plus a third contributed by
  the hold transformation).
- Branch-exclusive fields (`reasonCode`, `absentFieldCount`) are optional; fields
  present in every branch are required.

This is the highest-value derivation: outcome schemas are a near-complete
mechanical consequence of the expression that produces them.

### Input shape — partial derivation

Every `path` node rooted at `input` names a path the transformation reads. For
this capability the complete set is:

```text
payload.symbol            payload.region             payload.nativeTestimony
payload.providerBinding.bindingId                    payload.providerBinding.providerId
payload.attemptedBindings
```

That is the property set of the hand-authored `request.schema.json`. But it is a
**lower bound**, not the contract:

- A path read only inside an `if` guard is optional; a path read unconditionally
  is required. The distinction is recoverable from position in the tree, but
  only for guards the expression actually contains.
- A field the capability accepts and passes through without reading is invisible.
  Nothing in the expression mentions it.
- Reading `payload.providerBinding.bindingId` proves `providerBinding` is an
  object. It says nothing about `gateway` or `host`, which the hand-authored
  schema declares and the transformation never touches.

So input schemas derive as a skeleton plus findings, not as a contract.

### Types — from the mechanic vocabulary

The admitted mechanics constrain their operands, which yields a usable type
lattice without any annotation:

| Mechanic | Constrains |
| --- | --- |
| `filter`, `map`, `find`, `some`, `every`, `flat-map` (`from`) | array |
| `length` | array or string (`OPERAND_NOT_MEASURABLE` otherwise) |
| `greater-than` | number |
| `join` | array of strings; result string |
| `format`, `sha256`, `lower-case`, `trim` | result string |
| `includes` (`in`) | array or string |
| `object-values` | object |
| `equals(x, literal(null))` | x is nullable |
| `literal` | the JSON type of the value |
| `parse-json` / `json-stringify` | string / any |

In this capability that alone establishes `requiredValues` and
`payload.attemptedBindings` as arrays, `missingCount` as a number, and
`observedPrice` as whatever the native path yields — which is the honest answer,
because the transformation does not constrain it.

## What is not derivable, and why that is correct

A contract is a promise. An expression is a mechanism. These are different
things, and the difference is exactly what cannot be derived:

- **Semantic constraints.** `minLength: 1`, `pattern: ^sha256:[0-9a-f]{64}$`,
  `format: date-time`. The expression never checks them; the contract must.
- **Deliberate openness.** `nativeTestimony` is declared `type: object` with no
  properties *on purpose* — its shape belongs to the supplier, not to this
  capability. A deriver seeing `path(native, "quoteSummary.result.0.price")`
  would happily infer a nested structure and thereby encode one supplier's
  response shape into the canonical contract. That would be actively wrong.
- **`additionalProperties`.** Whether unknown fields are refused is a policy
  decision. Nothing in the expression expresses it.
- **Required-by-promise.** `sourceAttribution` is required because the feature
  says evidence must be attributable, not because the expression reads it.
- **Titles and descriptions.**

A deriver that silently guesses any of these produces a contract that admits
whatever the implementation happens to emit — which defeats the purpose of
having a contract at all. See "The inversion risk" below.

## Rules the generator must obey

These are not stylistic. Each corresponds to a defect observed in this estate:

1. **Never emit `type: array` without `items`.** `JsonSchemaTypeGraphBuilder`
   throws `has no admitted item schema`, which blocked
   `generate-executable-capability-scaffold` from projecting at all. Where the
   item type is unknown, emit `items: {}` — identical under Ajv, and projectable
   as `unknown[]`.
2. **Emit `type: object` without `properties` only deliberately.** It projects as
   `Record<string, unknown>` and admits any object. That is right for
   `nativeTestimony` and wrong almost everywhere else, so it must be a declared
   decision carrying a finding, never a default.
3. **One contract id, one schema file.** The scaffold's emitted catalog mapped
   four ids onto two files, which is the shape of defect 1 in the scaffold defect
   record. A deriver must refuse to alias and return
   `CONTRACT_SCHEMA_ALIASED` naming the ids.
4. **Emit the schema bodies the catalog names.** A catalog entry with no schema
   file is the gap this proposal exists to close; the deriver must not reproduce
   it.

## The inversion risk

The estate's stated order is: meaning lives in declared authority, and the
contract is the admission boundary that checks it. Deriving contracts *from*
transformations inverts that — the implementation would define the boundary that
is supposed to constrain it. A derived contract cannot catch a transformation
that produces the wrong shape, because it was computed from that shape.

Two mitigations, and the second is probably the more valuable product:

**As a generator** — emit a *candidate* schema set, every inferred constraint
marked, and require a human or a declared authority to narrow it before
admission. This is the same posture the scaffold already takes: emit what is
mechanical, mark the rest unresolved, never write the meaning.

**As an oracle** — derive the schema and *compare* it to the authored schema.
Divergence is a finding in both directions:

- The transformation emits a field the contract does not declare →
  `UNDECLARED_OUTCOME_FIELD`.
- The contract requires a field no branch produces → `UNSATISFIED_CONTRACT_FIELD`.
- The transformation reads an input path the contract does not admit →
  `UNDECLARED_INPUT_PATH`.

The oracle keeps the contract authoritative while still catching exactly the
class of defect that is expensive to find later. It would, for instance, have
caught the emitted catalog aliasing four ids onto two files without anyone
running a projection.

Recommendation: build the oracle first. It is smaller, it cannot invert the
authority direction, and it pays off on every capability already in the estate —
not only on newly scaffolded ones.

## Proposed output

For each capability, a disposition per contract rather than a single verdict:

```text
DERIVED_COMPLETE     every property, type and requiredness inferred; no findings
DERIVED_CANDIDATE    property set inferred; constraints or types unresolved
DERIVED_SKELETON     property names only (typical for input contracts)
NOT_DERIVABLE        no transformation produces or consumes this contract
```

with findings carrying the JSON pointer into the expression that produced each
inference, so a reviewer can check the derivation rather than trust it.

## Acceptance

This should not be accepted on "it produced schemas". Proposed bar:

1. Re-derive the five schemas for `resolve-equity-market-price-evidence` and
   diff against the hand-authored set. Every difference is either a finding the
   deriver declared, or a defect in the deriver.
2. Derive across the estate's existing capabilities and compare with their
   admitted contracts. Divergence counts are the real measure — and any
   capability where derivation *matches* the admitted contract exactly is a
   capability whose contract may be adding nothing.
3. A derived schema must project: run it through the node type graph. Rule 1
   above exists because that check was skipped once already.

## Where this leads

> **Not a work item.** This section exists so the team can see the trajectory
> while reviewing the proposal above. Nothing in it is scoped, estimated or
> authorised. The two constraints at the end are binding on any future build;
> the rest is direction. Do not open work from this section — open it from
> "Acceptance".

The derivation above is worth building on its own, but its longer value is that
it removes the last artifact anyone hand-writes.

After a scaffold is generated, exactly one thing is authored by hand: the root
transformation expression. The scaffold emits the capability authority,
blueprint, interfaces, execution authorities, graph, projection authorities and
catalog mechanically, and returns the transformation with `expression: null` and
the id in `unresolvedTransformationIds`. If contracts derive from the
transformation, then **the transformation is the whole authoring surface** — and
a tool that edits one artifact type covers the entire gap between a reviewed
feature and a registered capability.

Three things already favour that tool:

- **The grammar is closed.** The canonical evaluator dispatches thirty
  operations — `let`, `path`, `object`, `array`, `map`, `filter`, `find`, `if`,
  `equals`, `length`, `format`, `sha256`, `join` and the rest. A finite op set
  with known operand types is a tractable structured-editing problem rather than
  an open-ended one.
- **The persistence model exists.** `model.transformation_expression_node`,
  `_child` and `_root` already store expressions as trees addressed by JSON
  pointer, each node carrying lineage. An editor edits rows the database already
  understands; it does not need a new storage design.
- **The oracle makes editing safe.** Edit the expression, re-derive the contract,
  diff it against the admitted one. A change that breaks the promise is reported
  at edit time instead of at projection or invocation.

Beyond a manual editor, the same pieces compose into an end-to-end conveyor —
"connect to provider X and give me Y" producing a registered, invocable
capability. The provider-swap work already shows the downstream half of that is
data rather than code: gateway bindings, route policy and native-to-canonical
mapping are all declarative, and swapping suppliers changed one boolean.

The unproven link is upstream: **native shape discovery**. Authoring the mapping
required knowing that one supplier exposes price at
`quoteSummary.result.0.price.regularMarketPrice.raw` and another at
`quoteResponse.result.0.regularMarketPrice`. That was learned by calling both and
reading the responses. The RapidAPI integration strategy proposes a compiler from
saved documentation to operation descriptors, which is the candidate for that
step; it is the one link in the chain with no working proof, and everything
downstream of "here is the native shape" now has one.

Two design constraints, both learned expensively rather than assumed:

**Absence must be a first-class primitive, not an expression the author writes.**
The `"undefined"` literal defect was thirty-five nodes across five capabilities:
every guard compared `json-stringify(path(...))` against `"undefined"`, which the
declared semantics can never produce, so every absence branch was dead code. It
passed structural validation and only surfaced at execution. An expression
builder that lets an author hand-write an equality for "is this absent?" will
reproduce that defect at scale. Absence needs its own operator with one admitted
meaning.

**Port-executing fixtures must be a derived obligation, not a convention.**
Measured across the estate at the time of the scaffold defect record: 1,154
fixture cases, of which 1,045 stub the port so the transformation never runs, and
186 of 217 capabilities had no case that executed their own transformation. A
conveyor that emits fixtures alongside expressions will produce green suites over
unexecuted logic unless at least one port-executing case per capability is a
requirement the pipeline derives rather than something an author remembers.

## Boundaries

The derivation described here was verified by inspection against one capability's
authored artifacts. No deriver has been written, no estate-wide measurement has
been taken, and the type lattice has not been tested against the mechanics this
capability does not use. The claim that outcome shapes derive strongly rests on
expressions whose root `value` is an `object` or an `if` over objects; a
transformation returning a bare `path` or a `merge` of computed objects was not
examined and may derive far less.

"Where this leads" is a trajectory, not a plan with evidence behind it. The
editor and the conveyor do not exist. What is established is narrower: the
scaffold emits every other artifact mechanically, the expression grammar is
closed at thirty operations, expression trees are already normalized in the
database, and a provider swap is a data change. The two design constraints in
that section are measurements from this estate, not predictions — the
thirty-five dead absence guards and the 1,045-of-1,154 stubbed fixture cases are
both observed counts.
