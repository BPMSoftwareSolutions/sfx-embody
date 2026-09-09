# Deterministic scenario input and outcome experiences

**SideFX can generate scenario input forms and outcome views deterministically.** The current database provides enough structural authority to begin, and the platform already contains a basic input renderer and a substantial vocabulary of presentation capabilities. A dependable solution should compile contracts into a versioned presentation plan, bind that plan to interaction state, and render it through the design system. AI is optional during design authoring; it is unnecessary in this execution path.

**Contract shape can determine structure, but it does not uniquely determine experience.** Two strings could be a login, a search request, or a pair of artifact references. An array of numbers could represent prices, measurements, or identifiers. Reproducible choices are possible in every case; semantically correct specialized choices require declared meaning. The recommended design combines structural defaults with explicit field ownership and presentation profiles. This also matches the existing SideFX presentation declarations, which preserve authored meaning rather than infer it from property names.[^1][^5]

The investigation covers the selected SQL model observed on September 9, 2026, all of its 824 normalized scenarios, and all 630 selected contract definitions. It is a research assessment, not an implemented form capability, a live rendering certification, or a change to contract authority.

## Evidence and scope

The census uses the database's existing restricted reader and one pinned model. Schema bytes were retrieved through the normalized contract-to-schema relationship, verified against their SHA-256 digests, and parsed locally. No capability or external provider was invoked. The query returned complete, untruncated results.[^1][^2]

| Population | Observed count | Interpretation |
|---|---:|---|
| Selected semantic definitions of kind `CAPABILITY` | 304 | Broader semantic-definition population; not a count of form entry points |
| Normalized selected capability memberships | 219 | `model.estate_capability` population |
| Capabilities with normalized scenarios and a declared root | 218 | Current candidate entry points for capability-level forms |
| Scenario inputs / scenario outcomes | 824 / 824 | All normalized scenarios, including internal steps |
| Inputs with a resolved contract and retained schema | 812 / 824 | 98.5% structural source availability |
| Outcomes with a resolved contract and retained schema | 809 / 824 | 98.2% structural source availability |
| Roots with resolved input / outcome contracts | 216 / 216 | Each denominator is 218 roots |
| Selected contract definitions | 630 | 497 distinct original schema byte digests |
| Distinct contracts used by inputs / outcomes | 365 / 381 | Contract-version identities, excluding missing references |
| Contract identities used in both directions | 153 | Reuse is common |
| Scenarios with the same input and outcome contract | 239 | Direction alone does not distinguish request fields from carried state |
| Outcome variants / scenarios declaring variants | 160 / 62 | A useful existing vocabulary for result alternatives |
| Outcome-product / variant-product relationships | 0 / 0 | Rich result views cannot currently rely on these normalized links |

These are availability and shape counts, not percentages of production-ready forms. Thirty-seven selected contracts have no direct input/outcome binding; some may still be referenced by other schemas. All 630 schemas declare JSON Schema draft 2020-12 and pass Ajv2020 meta-schema validation. That checks schema syntax, not reference closure, satisfiability, UI completeness, business meaning, or runtime execution.[^1][^3]

`manage-capsule-estate` is the one normalized capability without a normalized scenario or root in this selection. Both `author-canonical-feature` and `resolve-governed-task` have unresolved root input and outcome contracts. The remaining missing bindings occur in internal scenarios of the tooling migration promote, run, and verify capabilities. The [complete scenario inventory](scenario-inventory.md) includes every scenario and both directions; [summary.json](summary.json) names all 27 missing direction bindings.

The model calls the output face **`scenario_outcome`**, with its schema relationship in **`scenario_outcome_contract`**. There is no need to introduce a competing `scenario_output` identity merely to implement the presentation surface. Outcome `experience` text supplies valuable design context, but it is prose rather than executable layout authority.[^2]

## The structural taxonomy

There are three layers to classify independently: the root document shape, the structures within it, and the semantic role of each field. Treating these as one category would obscure why a technically valid form can still be a poor experience.

### Root documents

The following classes are mutually exclusive. A root `$ref` takes precedence, followed by root composition (`oneOf`, `anyOf`, `allOf`), followed by a named record with `contractId` and `payload`, then other named records. Therefore, an enveloped request inside `anyOf` belongs to “composed root,” and a record with a root `allOf` also belongs there.[^1]

| Root shape | All input bindings | All outcome bindings | Root inputs | Root outcomes | Presentation approach |
|---|---:|---:|---:|---:|---|
| Direct named record | 285 | 441 | 66 | 131 | Field groups for entry; labeled values and sections for results |
| Named record with `contractId` and `payload` | 250 | 236 | 107 | 50 | Preserve the full document; present payload as the primary interaction region |
| Composed root | 275 | 130 | 42 | 35 | Resolve alternatives and intersected constraints before selecting controls |
| Root reference | 1 | 2 | 0 | 0 | Resolve the exact scoped schema, then apply the same rules |
| Scalar string | 1 | 0 | 1 | 0 | A single editor, not an empty object form |
| Unresolved contract | 12 | 15 | 2 | 2 | Explain the missing authority; do not invent a specialized form or view |
| **Total** | **824** | **824** | **218** | **218** | |

The scalar example is `semantic-carrier-source.v1`, used by `validate-semantic-carrier`. The appropriate generic surface is a text editor. `say-hello-world` illustrates another distinct case: its payload is a closed empty object. It needs an action with no editable payload fields, rather than a JSON textarea asking someone to manufacture input.[^1]

### Nested structures and control families

Feature counts below are **nonexclusive counts of contract definitions**. They inspect schema positions, including `$defs` and conditional branches, without expanding external references. Open-position flags describe missing local restrictions; an enclosing intersection or other schema can impose additional restrictions. These counts are implementation requirements and review leads, not proof that every flagged path is editable in every valid instance.[^1]

| Observed feature | Contracts | Deterministic input treatment | Deterministic output treatment |
|---|---:|---|---|
| `const` | 462 | Fixed value when present; seed only under a declared initialization policy | Labeled fixed value or compact identity context |
| `enum` | 409 | Typed selection control with explicit null/absence handling | Exact value with a neutral label; semantic status styling requires a mapping |
| Arrays | 406 | Repeated scalar controls or repeated record editors | Ordered lists or repeated records; specialized tables require a presentation declaration |
| Local `$ref` | 122 | Reuse the referenced field/group contract | Reuse the referenced view structure |
| External or relative nonfragment `$ref` | 41 | Resolve from a pinned resource bundle | The same resolution requirement applies |
| Nullable type declarations | 82 | Separate absent, null, and concrete-value states | Distinguish absent, null, empty, false, and zero |
| Conditional requirements | 31 | Reevaluate applicable constraints from current values | Select applicable view regions without rewriting the result |
| Multiple non-null types in `type` | 12 | Explicit value-type selection or a faithful JSON editor | Type-directed generic presentation |
| Typed additional-property dictionaries | 5 | Key/value editor constrained by the dictionary schema | Key/value rows preserving keys and values |
| Tuple / positional array declaration | 1 | Position-specific controls | Position-specific values with declared labels if available |
| Arrays without local `items` or `prefixItems` | 59 | Arbitrary JSON-value item editor, or a declared specialization | Structured JSON inspection unless additional authority defines item meaning |
| Objects without named properties or local value restrictions | 288 | Arbitrary JSON object editor, not an invented business form | Structured inspection; specialize only with additional authority |
| Named objects without local `additionalProperties: false` | 353 | Preserve and provide access to additional members | Show additional members through an explicit expandable section |
| At least one object with more than 12 named properties | 84 | Grouping and progressive disclosure become particularly useful | Summary plus detail regions, with all fields accounted for |

There are 133 contracts using at least one of `oneOf`, `anyOf`, or `allOf`; their individual counts are 79, 28, and 40. These sets overlap. Boolean schemas also occur, mainly as object-closure keywords. A boolean schema value such as `false` must not be confused with the JSON data type `boolean` or treated as proof that an entire contract is impossible.[^1]

For future contracts, add the following generic control mappings without making a particular design library authoritative:

| Declared value meaning | Input | Output | Extra authority needed beyond a primitive type |
|---|---|---|---|
| Free text | Single-line or multiline editor | Text block | Multiline/editor intent for a specialized choice |
| Integer or decimal | Numeric draft editor | Exact number or formatted quantity | Units, scale, rounding, and locale for formatted display |
| Boolean | Checkbox or explicit choice | True/false label | A toggle is suitable only when its immediate-action meaning is intended |
| Date/time | Date/time editor | Localized date/time | Declared format and timezone semantics |
| Secret | Masked input | Omission or authorized redacted status | Sensitivity and transport policy; a field name is insufficient |
| Resource reference | Reference selector | Resolved resource summary | Resource type, lookup capability, permissions, and stable identity |
| File/media | Source acquisition control | Download or preview | Acquisition authority, media type, size limits, location policy, and preview support |
| Geographic value | Coordinate/address editor | Map | Coordinate system and location semantics |
| Measures over time | Repeated records | Chart with a data table alternative | Time/value roles, units, ordering, and aggregation rules |

The census found **zero uses of the schema keywords `format`, `default`, `examples`, `readOnly`, `writeOnly`, or `contentMediaType`**. Only 109 contracts use `title`, and 32 use `description`; all counted titles are at their document root. Eight contracts use `contentEncoding`. Consequently, today's schemas generally provide structural rules, not the metadata needed to choose passwords, dates, money displays, or media viewers automatically. Fields *named* `readOnly` inside a presentation payload are instance properties; they are not JSON Schema `readOnly` annotations.[^1]

## The semantic taxonomy

These families describe how existing contracts should become experiences. They are analytical groupings illustrated by real scenarios, not additional exclusive database counts. Each scenario can combine several families. The complete per-scenario structural classification remains available in the inventory.

| Experience family | Existing example | Input experience | Outcome experience | Required distinction |
|---|---|---|---|---|
| Simple person-supplied value | `greet-by-name` | A Name field | Greeting text | Keep the `contractId`/`payload` structure in serialization |
| No-value action | `say-hello-world` | Action with an empty payload supplied structurally | Fixed greeting | Empty object is a legitimate shape |
| Search or selection request | `resolve-sidefx-semantic-knowledge-request` | Query and intended search scope; system-bound corpus/policy references | Grounded results or typed abstention with receipt | Index entries and corpus digests are not ordinary search fields |
| Provider selection | `resolve-sidefx-eligible-providers` | Requested platform capability and target; bound inventory | Providers, eligibility, reasons, counts, and evidence | A provider's presence does not establish eligibility |
| Scaffold / authoring request | `generate-executable-capability-scaffold` | Capability identity, declared scenarios/topology, provider slots; advanced structured editors | Completeness, unresolved slots, authoring queue, and generated artifacts | The generator must not invent topology or admission testimony |
| Authority / evidence review | `admit-canonical-circuit-blueprint` | Blueprint and evidence references; bounded review inputs | Admission or held findings with attributable evidence | A review control cannot turn supplied text into trusted evidence |
| Carried workflow state | `resolve-strategic-market-signals` | Authorable signal facts; bound vocabulary/evidence; computed fields distinguished | Signal disposition, limitations, findings, and receipt | Same contract in both directions does not make all fields human-authored |
| Credential reference | `bind-external-credential-reference` | Authorized reference selector and invocation context | Availability/disposition and opaque binding metadata | A credential reference is different from entering a credential value |
| HTTP/provider request | `observe-governed-http-exchange` | Bound endpoint and policy, permitted parameters/body, credential reference | Transport disposition, status, allowed headers, bounded response evidence | Successful HTTP transport is not automatically a successful domain outcome |
| Artifact acquisition/publication | `read-authorized-file`, `write-binary-artifact` | Authorized path/reference or file acquisition adapter | Existing/empty/missing/denied states, verified artifact details, authorized download | A browser file cannot silently become an arbitrary server filesystem path |
| Document or graph projection | `project-canonical-circuit-blueprint` | Declared graph plus projection/view choices | Declared diagram/document artifacts and review evidence | A generic graph-shaped object is not sufficient graph-view authority |
| Media production | `generate-governed-narration` | Scene/narration references and performance intent | Audio asset, grounded assertions, lineage, or held/rejected details | The declared asset location needs an authorized playback adapter |

### Field ownership is a separate axis

Every input path should carry one of five roles in the compiled experience plan: **human-supplied**, **system-bound**, **fixed**, **derived**, or **unclassified**. A sixth presentation characteristic, sensitivity, applies across those roles. For example, a system-bound value can still be sensitive.

Only human-supplied fields become ordinary editable controls. Fixed members may be supplied by an explicit initialization rule. System-bound fields come from a declared context resolver. Derived fields come from an identified computation or prior scenario. Unclassified fields remain visible for engineering inspection but cannot silently masquerade as trusted system facts. Source selection and editability need to follow the scenario's actual authority, not guesses such as “every field ending in `Digest` is hidden.”

This distinction is central to the 239 scenarios that reuse their input contract for their outcome. A carrier can legitimately include preexisting findings, accumulated evidence, intermediate state, or terminal values. Which portions a person may supply depends on the selected interaction, not on JSON type. The root scenario is the practical default entry point; internal scenarios should receive their own authorable surface only when explicitly exposed as an interaction.[^1][^5]

## What the platform already does

SFX Platform publishes root input schemas from SQL into `generated/input-contracts.json`. The inspected publication contains 218 capability entries and 215 distinct parsed schema objects, with 216 roots resolving a schema; its snapshot, projection, and view-definition digests match this census. That is a valuable existing publication boundary. Runtime pages can consume contract authority without opening a database connection.[^4]

The current helper recognizes constants, enums, strings, numbers, integers, booleans, objects, homogeneous arrays, nullable types, and local JSON Pointer references. `SchemaField` creates nested controls, retains JSON editing as a fallback, and exposes a single underlying document through form/raw modes. The result panel already distinguishes unavailable, refused, unknown, and executed invocation states, but renders the outcome in a JSON `<pre>`.[^4]

The research probes identify the next limitations precisely:

| Finding | Evidence | Consequence |
|---|---|---|
| Root rendering reads direct `properties`, without resolving root composition | 33 of 216 resolved root input schemas have no direct properties; includes scaffold, HTTP exchange, credential binding, and the scalar text contract | These roots cannot currently receive a normal field layout |
| Nested unions/compositions fall back to raw | `describeField` explicitly classifies `oneOf`, `anyOf`, and `allOf` as raw after const/enum handling | Branch-aware editing needs a new interpretation layer |
| Required booleans initialize to `false` without a declared default | Executed helper probe | Untouched and explicitly false need separate interaction state |
| Optional constant fields are inserted automatically | Executed helper probe | `const` restricts a value if present; insertion is an application policy |
| Boolean property schemas are omitted from `objectProperties` | Executed helper probe | Future legal `true`/`false` property schemas need explicit handling |
| `$ref` resolution replaces the referencing object | Executed helper probe loses a sibling `minLength` | Draft 2020-12 sibling constraints must survive resolution |
| Named-object controls only render named members | Component source inspection | Extra keys can remain in the underlying document without a corresponding form control |
| Null and empty value states share some UI representations | Component source inspection | Nullable booleans, objects, arrays, empty strings, and enums need deliberate state controls |
| Client checks JSON syntax, not the full contract | Component source inspection | Add early validation while preserving the server's final admission decision |
| Output remains generic JSON | Result component inspection | A separate outcome view compiler is needed |

The existing form test's “over 80%” threshold examines direct properties only. Roots with no direct properties do not enter that denominator, and nested object recognition is not proof that every child renders. It should not be used as an estate-wide form coverage claim.[^3][^4]

These findings were obtained through source inspection and six bounded helper probes. They are not browser-level interaction tests. The proposed work should preserve the current form/raw document continuity and improve fidelity, rather than discard that useful foundation.

## Determinism: the achievable contract

The strongest useful promise is **the same complete authority and context produce the same presentation plan and value behavior**. Pixel identity across all browsers is a separate, narrower rendering claim.

```text
Presentation plan = Compile(
  scenario version + direction,
  contract digest + scoped reference bundle,
  semantic field bindings + presentation profile,
  design-system component registry + compiler version,
  target profile + locale + timezone + access policy
)

Rendered experience = Render(plan, current document, interaction state)
```

Dynamic forms remain deterministic: a changed value can activate different required fields or a different result branch according to fixed rules. Remote option sets and resolved assets are external inputs; retain their version or response identity when reproducibility matters. Do not let a live network lookup, ambient locale, clock, or unpinned model response silently affect plan selection.

There are three honest delivery levels:

| Level | Promise | Present feasibility |
|---|---|---|
| Structural inspection | Every supported JSON value is inspectable; supported schema shapes have editable controls; unknown shapes are explicit | Feasible now as an extension of the existing renderer |
| Deterministic interaction | Typed editing, branch/constraint behavior, presence states, field ownership, serialization, and validation agree with authority | Feasible with additional compiler/state work and scoped reference closure |
| Designed experience | Login, search, evidence review, media, documents, and specialized result views use intentional layouts and semantics | Feasible with versioned presentation profiles and design-system mappings |

No evidence supports claiming that the current schemas alone deliver the third level for every scenario. Adding AI does not remove that missing semantic authority; it simply guesses at it. A designer can author the same information once as reusable data.

### Rules that make the promise meaningful

1. Resolve the selected scenario and exact input/outcome contract by database identity. Do not pick a contract from an ID suffix or filename.
2. Verify original byte digests separately from canonical parsed-document digests. Track the complete reference closure, not just the entry schema.
3. Interpret constraints without flattening away intersections, reference siblings, or conditional requirements. `oneOf` requires exactly one matching alternative; `anyOf` allows overlap. An overlap must not be presented as a uniquely established business variant.[^7][^8]
4. Choose specialized components from declared roles/profiles; use a documented generic structural policy otherwise. Registry priority and tie handling must be fixed. An ambiguous semantic specialization should yield a finding.
5. Set field order from an explicit profile. When absent, use a documented canonical key ordering, preserving array order. Do not treat SQL result order or object insertion order as intended UX order.
6. Preserve missing, null, empty string, false, zero, empty array, and empty object distinctly. Keep incomplete numeric text as draft state until parsing succeeds; respect the runtime's supported numeric precision.
7. Preserve all supplied members during form/raw transitions and view switches. Hiding a branch must not silently delete its values. If changing branches requires cleanup, apply a declared transition policy that makes the change visible.
8. Client validation should use the same dialect, formats, and substantive configuration as runtime admission. Do not silently coerce types, insert defaults, or remove fields. Ajv documents these as optional data-changing behaviors; they are not a substitute for a serialization policy.[^9]
9. Bind each rendered control to an instance path and a schema location. A layout change must not change the payload meaning or expose additional writable authority.
10. Produce a coverage manifest accounting for every applicable path as edited, displayed, fixed, system-bound, intentionally omitted under policy, or explicitly unsupported.

## Reference identity is an immediate architectural issue

The 630 selected contracts contain 44 repeated root `$id` values. Twelve of those IDs identify more than one distinct original schema digest. In particular, `.../contracts/input.schema.json` is reused by 100 contract definitions representing 91 distinct schema byte digests, and `.../contracts/outcome.schema.json` by 97 definitions representing 88 distinct digests.[^1]

Therefore, one estate-wide registry keyed only by `$id` would be ambiguous. The census also found 174 nonfragment reference occurrences across 41 contracts, including relative references. A schema URI need not be a downloadable URL; JSON Schema resolution operates against a resource registry and base URI.[^6]

Use a **scenario/capability-scoped resource bundle** built from declared catalog and source lineage. Within that bundle, an ID may resolve only to one admitted schema content identity. If the relevant bundle itself contains conflicting resources, return an ambiguity finding; do not choose first or last. Rewriting existing `$id` values globally is not a prerequisite for the research recommendation and would be a separate authority revision.

The current Node admission provider registers the first schema for an ID within its supplied contract collection. The census establishes an estate-wide collision risk, not that a particular executed capability currently receives a conflicting collection. The future experience compiler must prove bundle coherence and must not assemble all 630 schemas indiscriminately.[^10]

## A small presentation profile rather than UI details in every schema

Keep three contracts distinct: **data admissibility**, **interaction meaning**, and **visual realization**. Their identities can be bound together without forcing CSS classes, React components, or image layouts into every input schema.

Recommended precedence is: compatible scenario-specific presentation binding, then compatible contract-specific profile, then declared semantic-type mapping, then a versioned structural fallback. A binding must target the selected contract digest or an explicitly compatible version. “Newest profile wins” is not a reproducibility rule.

The minimum presentation vocabulary should carry:

| Concern | Example declaration | Why the schema alone is insufficient |
|---|---|---|
| Field identity | Instance path and source schema pointer | Schema paths and data paths differ |
| Ownership and sensitivity | Human entry, system binding, fixed, derived, secret | A required string does not explain who supplies it |
| Input meaning | Email, password, query, authority reference, source acquisition | These can all be strings |
| Labels and organization | Label key, ordered groups, help text, advanced region | Object order is not a design specification |
| Presentation | Detail record, collection, document, media, chart | The same JSON can support many legitimate views |
| Behavior | Branch binding, lookup source, commit event, empty state | Shape does not authorize an action or data lookup |
| Formatting | Currency path, units, locale policy, time basis | Primitive values do not establish units or timezone |
| Outcome interpretation | Discriminator path and explicit variant/view mapping | A field called `status` does not explain success |
| Design system | Semantic component role and token-set version | Visual consistency depends on controlled components and tokens |

A compiler can produce a target-neutral plan carrying these facts. A provider then realizes that plan using existing design-system controls. This is analogous to the separation between data schemas and UI schemas in JSON Forms, whose registry can choose custom renderers using ranked testers. Its pattern is relevant; its default renderer selection should not become unreviewed SideFX authority.[^11]

### Illustrative future login

No dedicated login root was found among the 218 selected roots. This is a design example for the future capability, not a discovered contract.

```json
{
  "dataPaths": {
    "identity": "/payload/identifier",
    "secret": "/payload/password"
  },
  "presentation": {
    "profile": "sign-in",
    "orderedFields": ["identity", "secret"],
    "identityRole": "account-identifier",
    "secretRole": "password",
    "secretSensitivity": "secret",
    "submitAction": "declared-authentication-scenario"
  }
}
```

This sketch deliberately omits a contract binding and real action identity, so it is not a valid production profile. In the actual design, both must identify declared authority. The data contract would determine required values and constraints. The profile would determine labels, password masking, autocomplete purpose, layout, and the selected action. Authentication, session creation, and any follow-up challenge remain scenario behavior. A result profile would distinguish authenticated, challenge-required, and rejected outcomes only where the output contract declares them.

Brand illustration is a separate asset binding. A designer could create it manually or use Nano Banana or another image model, then select and retain the asset and its identity. Subsequent form compilation and rendering would remain deterministic. Text fields, error states, focus order, and validation should be real components rather than text painted into a generated image.

### Consistent shaping of future contracts

Consistency should mean a shared set of authoring rules, not forced migration of every existing record into one envelope. The compiler needs to accept the observed direct records, envelopes, scalar roots, and composed roots. For newly authored interactions, the following conventions would reduce ambiguity:

| Authoring convention | Effect on automatic experiences |
|---|---|
| Use a stable contract identity, explicit dialect, and unambiguous scoped schema resource IDs | Reliable reference resolution and plan caching |
| Declare `required` independently from type/nullability | The form knows whether a property may be absent and whether its value may be null |
| Give constrained arrays an explicit item schema | Repeated controls have a real item contract |
| Express intentionally arbitrary values honestly, with `{}` or `true` where appropriate | A generic JSON-value editor is a supported type of interaction, not a malformed-schema workaround |
| Declare object openness deliberately | Extra members remain visible and editable under the appropriate policy |
| Use a required, stable discriminator for business alternatives where the domain supports one | A view can choose a named branch without guessing; do not rewrite overlapping unions merely for convenience |
| Separate user request facts from context and accumulated testimony where the capability meaning permits | Simple user forms can bind their system context explicitly |
| Add human labels/help and reusable semantic roles to a compatible presentation profile | Consistent controls without copying target-specific styling into schemas |
| Declare units, time basis, resource kinds, and sensitivity where applicable | Numbers, strings, and references can receive appropriate specialized controls |
| Specify variant-specific required data for outcome alternatives | A completed/held/rejected view knows which content it can promise to display |

Do not narrow an intentionally open carrier solely because a particular renderer cannot handle it. The correct response is an explicit generic editor, an admitted specialization, or a renderer limitation. Similarly, JSON Schema `default` is not itself an instruction to fill a missing input, and display annotations do not enforce authorization. Initialization and access belong to the interaction policy.[^7][^9]

For the existing `greet-by-name` request, the useful form can be as small as this conceptual layout:

```text
Name
[                                      ]
Enter 1–100 characters.

[ Greet ]

Result
Hello, <the supplied name>!
```

Its submission remains the actual contract-shaped document, with a fixed `contractId` and a `payload.name` string. The display label and action copy above are proposed presentation choices; the name length bounds and greeting behavior come from the existing contract/scenario. The same pattern scales to provider selection: put the requested capability and target in the primary form, bind the inventory and snapshot context, and disclose that context as detail. A specialized form can be short even when the full request document is large.[^1]

## Outcome experiences need their own compilation pass

The outcome compiler can share schema resolution and type interpretation with the form compiler, but it has different responsibilities. An output view should explain the result, show its useful content, and preserve access to evidence. It should not render an input form with all controls disabled.

| Output family | Generic deterministic baseline | Specialized experience requiring a profile |
|---|---|---|
| Scalar | Labeled text/value | Prominent message or metric with declared units |
| Record | Ordered labeled values and nested sections | Summary/detail arrangement with declared emphasis |
| Collection | Repeated record views preserving array order | Table/card collection with declared fields, row identity, and selection behavior |
| Variant/result envelope | Exact discriminator and matching structure | Success/held/rejected/challenge view with explicit semantics |
| Findings/evidence | Structured facts with source paths | Severity list, evidence links, receipt panel, drill-down |
| Artifact | Identifier and descriptor | Download, document viewer, image/audio/video preview through an authorized adapter |
| Series/graph | Structured records | Chart, timeline, map, or graph using declared mappings |
| Open or unknown payload | Bounded structured inspection | A profile or additional contract must supply missing meaning |

There are three statuses to preserve separately: **transport/invocation state**, **kernel disposition**, and **domain outcome**. `EXECUTED` and kernel `terminated` do not mean that a business outcome was approved. A completed execution may produce `HELD`, `NOT_OBSERVABLE`, or a typed rejection. The existing invocation contract already models pre-execution refusal and unknown execution status; those distinctions must survive visual improvement.[^4]

For `resolve-sidefx-eligible-providers`, a useful declared view would show considered and eligible counts, then each provider's exact eligibility and reason, with findings and source evidence available alongside. Selecting the provider collection and count fields is a profile decision grounded in that specific contract. The generic compiler should not infer that any array named `providers` deserves eligibility badges.[^1]

For `generate-executable-capability-scaffold`, a useful view would emphasize declared completeness, unresolved slots, and the next authoring obligation, followed by artifacts and findings. The presentation must preserve a held or partial disposition. This research does not supersede the existing scaffold embodiment investigation, which recorded a type-projection hold on open contract structures.[^14]

For `generate-governed-narration`, display the admitted narration asset through an authorized media adapter with its supporting facts. A held or rejected result should show the declared reason instead. An `audioLocation` string alone does not prove a playable resource, and no `contentMediaType` annotations were found in the selected schemas.[^1]

Charts should be driven by explicit field roles, units, and transformations. Vega-Lite provides an example of a declarative visualization grammar with field/type/channel encodings, but chart selection is an independent presentation decision. Merely finding two numeric properties does not establish a meaningful chart.[^13]

## Alignment with the existing design system and capabilities

The database already selects capabilities that express most of the presentation concerns this approach needs. Their contracts provide useful integration targets:[^1][^5]

| Existing capability | Reusable responsibility |
|---|---|
| `project-input-binding` | Input intent, state path, read-only relationship, constraints, commit event, labels, accessibility, lineage |
| `project-source-selection-presentation` | Acquisition source, accepted media types, multiplicity, state binding, consent, acquisition port |
| `project-structured-data-presentation` | Groups, ordered fields, labels, value paths, emphasis, empty behavior |
| `project-collection-presentation` | State source, row identity, ordered fields, empty state, selection intent |
| `project-feedback-presentation` | Feedback importance, visibility, state source, announcement semantics |
| `project-validation-presentation` | Presentation of validation facts |
| `project-presentation-state-binding` | Presentation/state relationships |
| `project-presentation-token-binding` | Token identity, roles, constraints, and fallback |
| `project-accessibility-binding`, `project-focus-navigation` | Accessibility obligations and focus/navigation meaning |
| `project-semantic-presentation-layer` | Target/language presentation-layer projection context |

The new responsibility is most plausibly **deriving and checking presentation declarations from scenario contract authority plus explicit profiles**. Existing projection capabilities preserve those declarations. In particular, `project-input-binding` explicitly defers native implementation, and the collection/structured-data features reject inferred meaning. Their presence is not proof that an end-to-end browser experience is already executable. The eventual design should assess callable provider coverage before deciding which responsibilities to compose and which gaps to implement.

The separate `C:/lab/sidefx-ui` workspaces contain provisional component families, state, binding, validation, action, geometry, and projection experiments. They offer useful vocabulary: information, action, input, media, navigation, collection, feedback; and state types including text, number, boolean, date, selection, collection, record, and money. They also explicitly report formatting and localization gaps. These materials describe themselves as unmanaged/provisional, and some README limit statements are stale relative to later described interaction work. Treat them as design references, not current admitted runtime authority.[^12]

The existing Next.js/React surface is the natural first target for a bounded proof. Preserve semantic component identities in the plan, then map them to its design-system components and tokens. A later WPF or other target can consume the same semantic plan with a different provider. Equivalent behavior does not require identical pixels.

### Implementation options to evaluate later

| Option | What it provides | Main evaluation question |
|---|---|---|
| Extend the current SFX renderer behind a semantic plan | Existing publication, invocation, design-system styling, and form/raw continuity | Can the required schema/state coverage be completed without accumulating one-off contract branches? |
| Use JSON Forms as a target renderer | Separate UI schema, renderer registry, and ranked custom-renderer selection | Can SideFX bindings, ownership, deterministic selection, and design-system components be preserved through an adapter? |
| Use react-jsonschema-form as a target renderer | React form generation with custom fields and widgets | Does its behavior match the estate's unions, reference scopes, presence states, and serialization requirements? |

The recommendation is to retain a SideFX-owned semantic plan and evaluate renderer implementations against the same corpus. A third-party library can realize controls; it should not determine contract identity, field authority, outcome semantics, or the truth of coverage claims. No package change is required by this research.[^11]

## RapidAPI and other external providers

A provider schema can enter the same pipeline after a deterministic adaptation step. Bind it to the exact provider, operation, version, source digest, parameter location, and media type. OpenAPI 3.1.1 distinguishes parameters, request bodies, responses, and security requirements, and aligns its Schema Object with JSON Schema 2020-12. Those distinctions should survive adaptation; a request body alone is not the complete operation input.[^15]

The pipeline should preserve path/query/header/body placement and serialization rules, bind credentials through the existing credential-reference boundary, and leave effectful execution to the declared scenario. A remote enum/reference selector also needs a declared lookup capability and context. Building a form must not implicitly perform the operation it describes.

For responses, transport evidence can be presented immediately under its transport contract. A specialized business view requires a decoded and admitted domain response with the appropriate contract/profile. Unknown, inconsistent, or undocumented provider payloads should produce an explicit structured-inspection result rather than a fabricated domain schema. Authentication failures, empty responses, malformed JSON, and provider errors are real outcome alternatives.

OpenAPI 3.0 sources need a separate version-aware adaptation, especially for nullable and schema semantics. This report does not assert that a particular RapidAPI source is complete, uses 3.1, or is currently available; no external provider was called.

## Candidate design and acceptance criteria

An eventual capability could accept scenario authority, direction, a scoped contract bundle, compatible presentation bindings, target/design-system references, and interaction policy. Its outcome would be a presentation plan plus a coverage report, or a typed hold identifying unresolved obligations. Names and contract identities should be authored later, after the bounded design is agreed.

The plan should be declarative data referencing allowed components and bindings. There is no need to emit arbitrary executable JSX or accept model-generated event handlers. A useful plan record includes its source digests, compiler/registry versions, selected profiles, field paths, component roles, ordering, state bindings, conditional rules, result mappings, and accessibility requirements.

The following are proposed acceptance obligations, not claims that tests already pass:

| Obligation | Evidence to require |
|---|---|
| Complete source resolution | Every bound contract and reachable reference resolves uniquely in the selected scope |
| Deterministic planning | Identical complete inputs yield identical canonical plan digest; permuting irrelevant object keys does not change the plan |
| Payload fidelity | Editing and serializing preserve value types, array order, additional properties, and absent/null/empty distinctions |
| Validation parity | Representative accepted/rejected values agree with runtime admission, including unions, conditions, and reference siblings |
| Draft safety | Invalid partial text remains a draft and cannot silently replace the last valid payload or be submitted as a different value |
| Field ownership | System/derived/fixed paths cannot be overwritten by an ordinary human form binding |
| Branch fidelity | Overlapping `anyOf`, ambiguous `oneOf`, and missing discriminators receive explicit behavior |
| Coverage accounting | Every applicable value path has a rendering/binding/omission disposition; fallback usage is measured |
| Outcome truthfulness | Execution state, domain disposition, empty/null result, and held/rejected branches display accurately |
| Accessible interaction | Labels, grouping, keyboard order, error association, focus movement, and result announcements are verified |
| Bounded rendering | Large arrays, recursive data, expensive patterns, and deep schemas have declared handling and limits |
| Version isolation | Contract/profile/registry changes invalidate the appropriate plan without changing source authority |

The W3C forms guidance supports explicit labels, groups, instructions, validation feedback, and notifications. These should be part of the component contract and browser verification, rather than decoration added after form generation.[^16]

A useful first evaluation set is `greet-by-name`, `say-hello-world`, `resolve-sidefx-eligible-providers`, `generate-executable-capability-scaffold`, `bind-external-credential-reference`, `observe-governed-http-exchange`, `read-authorized-file`, and `generate-governed-narration`, plus synthetic fixtures for missing/null/false/empty distinctions, reference collisions, and ambiguous unions. This set spans simple entry, no-field input, nested collections, composition, open structures, variants, references, and media. It is a research recommendation, not an instruction to execute these capabilities.

### Recommended sequence

1. **Resolve authority and preserve values.** Extend publication to both directions, all selected scenario bindings, scoped resources, and explicit missing states. Complete presence-aware state and faithful generic inspection first.
2. **Compile generic structure.** Add root resolution, composed schemas, arrays/dictionaries, validation parity, and path coverage. Keep a measurable distinction between structural controls and fallback inspection.
3. **Add reusable experience profiles.** Start with simple request, no-field action, provider selection, evidence review, and typed result views. Connect profiles to the existing presentation vocabulary and design system.
4. **Prove the browser target.** Test the selected corpus for editing, keyboard behavior, serialization, result interpretation, and visual consistency. Only then broaden semantic types, targets, or provider adaptation.

The immediate design decision is to make **deterministic compilation with explicit semantic profiles** the core approach. That achieves dynamic forms and result experiences without requiring a model to infer field meaning at runtime, while leaving room for designers and optional AI-assisted visual authoring.

## Reproduction and research artifacts

Run these commands from the `sfx-embody` repository. The database reader owns connection configuration; no credentials are stored in these artifacts.

```powershell
node docs/research/scenario-experiences/read-inventory.mjs C:/lab/sidefx-database
node docs/research/scenario-experiences/analyze-inventory.mjs
node docs/research/scenario-experiences/probe-existing-form.mjs C:/lab/repos/sfx-platform
node docs/research/scenario-experiences/verify-research.mjs
```

The first command is read-only SQL and saves the complete extraction under the repository's ignored `evidence/` directory. The second produces the static taxonomy and scenario mappings. The third probes the existing helper and checks schema syntax. A later model selection can legitimately change counts; compare the pin tuple before comparing results.

The fourth command verifies the retained research against this observed baseline: 824 scenarios, 1,648 direction bindings, 630 contract records, 25,461 retained example pointers, and the report's local links. Its baseline totals should be reviewed deliberately when refreshing against a different model. [verification.json](verification.json) records artifact digests and the completed checks.

| Artifact | Contents |
|---|---|
| [Scenario inventory](scenario-inventory.md) | All 824 scenarios and both contract bindings |
| [Scenario bindings](scenario-bindings.json) | 1,648 direction records with contract identity, digest, root shape, and structural flags |
| [Contract taxonomy](contract-taxonomy.json) | 630 contract records, feature counts, reference occurrences, and example schema pointers |
| [Summary](summary.json) | Census, missing references, annotation gaps, duplicate schema IDs, and SQL proof |
| [Existing-form probes](existing-form-probes.json) | Helper experiments, all 33 roots lacking direct fields, and 630/630 meta-schema results |
| [SQL census](inventory.sql) | Exact selected-model extraction |
| [Raw local evidence](../../../evidence/research/scenario-experiences/inventory.json) | Parsed contract schemas, scenario definitions, selected capabilities, variants, and query proof |

Snapshot: `sha256:1a770ac0795d10665a88166f8d8c968dc5b2d030fdfab2b837aa6071d135f9e9`.

Projection: `sha256:e036610730972f246d8e33cd882e45dd793013076aea2e401086b93d4993a7ee`.

View definitions: `sha256:b574443a65db450c9f269105d725acb98087cfc0e524f6982a27d5169a110564`.

Query: `sha256:329558b394a20e5c16f2c93f5108ee1a1837695e9fb932b0f68cf48293c56ab6`.

The schema-position census does not resolve transitive references, prove that every definition is reachable, or simplify intersected constraints. Local open-position flags can therefore overestimate effective openness. The library comparison is documentation-based, not a benchmark. The supplied probe evidence covers helper behavior and schema syntax; it does not certify the current renderer or any proposed capability.

## Sources

All local and web sources were inspected September 9, 2026. Local file links identify the inspected workspace; they are not public document URLs. Counts refer to the pinned SQL selection, not necessarily the current filesystem checkout of Harness.

[^1]: SideFX Database selected-model read, [inventory.sql](inventory.sql), [summary.json](summary.json), [contract-taxonomy.json](contract-taxonomy.json), and [raw local extraction](../../../evidence/research/scenario-experiences/inventory.json). Full query/pin identity appears above. The primary source for all measured estate counts and example contract structures.

[^2]: SideFX Database, [normalized schema migration](C:/lab/sidefx-database/sql/migrations/001-normalized-estate.sql), especially `scenario_input`, `scenario_outcome`, `scenario_outcome_contract`, `contract_version`, and `schema_object`; [restricted reader](C:/lab/sidefx-database/src/query/run.mjs). Inspected checkout `266bbce853a576835b1e174ca747f6d093229327`.

[^3]: Research probes, [probe-existing-form.mjs](probe-existing-form.mjs) and [existing-form-probes.json](existing-form-probes.json). Source helper digest retained in the result; all 630 schemas passed the Ajv 8.20.0 draft-2020-12 meta-schema check.

[^4]: SFX Platform, [input publication](C:/lab/repos/sfx-platform/scripts/publish-input-contracts.mjs), [form interpretation](C:/lab/repos/sfx-platform/lib/json-schema-form.ts), [field renderer](C:/lab/repos/sfx-platform/components/estate/schema-field.tsx), [run and result panel](C:/lab/repos/sfx-platform/components/estate/capability-run-panel.tsx), [invocation contracts](C:/lab/repos/sfx-platform/contracts/invocation.ts), and [form tests](C:/lab/repos/sfx-platform/tests/schema-form.test.ts). Inspected checkout `c025299f2a12d7191d4c5819b47eb50421d02350`; publication pin matches the census.

[^5]: Agentic Harness, [input binding](C:/lab/repos/agentic-harness/features/project-input-binding.feature), [collection presentation](C:/lab/repos/agentic-harness/features/project-collection-presentation.feature), [structured data](C:/lab/repos/agentic-harness/features/project-structured-data-presentation.feature), [feedback](C:/lab/repos/agentic-harness/features/project-feedback-presentation.feature), and [design tokens](C:/lab/repos/agentic-harness/features/project-presentation-token-binding.feature). Inspected checkout `47395018b04332a34debbde637a1b3efc4d0301a`; current source declarations corroborate the presentation semantics found in selected SQL contracts, without constituting runtime proof.

[^6]: JSON Schema, [Modular JSON Schema combination](https://json-schema.org/understanding-json-schema/structuring). Official documentation on IDs, base URIs, registries, references, and reusable definitions; live documentation, publication date not stated.

[^7]: JSON Schema, [Validation: A Vocabulary for Structural Validation of JSON](https://json-schema.org/draft/2020-12/json-schema-validation), June 16, 2022, draft 2020-12; and [Core](https://json-schema.org/draft/2020-12/json-schema-core), June 2022. Vocabulary and validation semantics, including annotations and combinators.

[^8]: JSON Schema, [Conditional schema validation](https://json-schema.org/understanding-json-schema/reference/conditionals) and [Object reference](https://json-schema.org/understanding-json-schema/reference/object). Official documentation; publication dates not stated. Conditional requirements and object closure.

[^9]: Ajv, [Modifying data during validation](https://ajv.js.org/guide/modifying-data.html). Official documentation; publication date not stated. Default assignment, coercion, and additional-property removal are configurable data mutations.

[^10]: Scenario Driven Architecture, [Node schema admission provider](C:/lab/repos/scenario-driven-architecture/languages/typescript/runtimes/node/schema-contract-admission-provider.mjs), `compileContractValidators`. Uses Ajv2020 and registers schema IDs within the supplied authority collection.

[^11]: JSON Forms, [UI Schema](https://jsonforms.io/docs/uischema/) and [Custom Renderers](https://jsonforms.io/docs/tutorial/custom-renderers/); react-jsonschema-form, [Custom Widgets and Fields](https://rjsf-team.github.io/react-jsonschema-form/docs/advanced-customization/custom-widgets-fields/). Official current documentation, publication dates not stated. Both offer declarative customization patterns; neither was installed or benchmarked for this research. JSON Forms is the closer conceptual reference for a separate presentation schema and renderer registry; RJSF is a credible React form implementation option to evaluate against the estate corpus.

[^12]: SideFX.UI provisional workspaces: [composition](C:/lab/sidefx-ui/sidefx-compose-ui-surface/README.md), [component semantics](C:/lab/sidefx-ui/sidefx-ui-component/semantics/component-semantics.v1.json), [state semantics](C:/lab/sidefx-ui/sidefx-ui-state/semantics/state-semantics.v1.json), [binding](C:/lab/sidefx-ui/sidefx-ui-binding/README.md), and [validation](C:/lab/sidefx-ui/sidefx-ui-validation/README.md). Local design/implementation references, explicitly provisional.

[^13]: Vega-Lite, [Encoding](https://vega.github.io/vega-lite/docs/encoding.html). Official documentation, publication date not stated. Example of declarative data/visual channel mapping; not a recommendation to infer chart meaning from field names.

[^14]: SFX Embody, [Scaffold invocation and RapidAPI investigation](../../scaffold-invocation-rapidapi.md), September 9, 2026. Prior bounded execution investigation; its retained-capsule schema counts use a different population from this normalized selected-contract census.

[^15]: OpenAPI Initiative, [OpenAPI Specification 3.1.1](https://spec.openapis.org/oas/v3.1.1.html), October 24, 2024. Version-specific primary reference for operations, request/response structure, parameter serialization, security, and Schema Object semantics; not a claim that every provider uses this version.

[^16]: W3C Web Accessibility Initiative, [Forms Tutorial](https://www.w3.org/WAI/tutorials/forms/). Official accessibility guidance on labels, grouping, instructions, validation, and notifications.
