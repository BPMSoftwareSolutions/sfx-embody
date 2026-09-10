# Private SideFX Lab: pilot qualification and deployment design

Observed 9 September 2026, America/New_York (10 September UTC).

The initial three-root qualification passed the installed `sfx` path: **16 cases, 36 outcome assertions, zero failures**, followed by Linux parity and local renderer checks. The subsequent [live finance deployment](../../../../sfx-platform/docs/live-finance-deployment.md) now runs all three interactions and actual RapidAPI stock-price retrieval in the private Hugging Face Space through the authenticated Azure service. The sections below retain the initial qualification's narrower evidence scope.

The organization is **BPM Software Solutions**; the private Docker Space is [BPMSoftwareSolutions/SideFX](https://huggingface.co/spaces/BPMSoftwareSolutions/SideFX). The user completed the Team purchase. The initial qualification did not deploy an application; the linked deployment report records the later completed deployment using the existing Azure plan.

## Reproduction and retained observations

Run from the `sfx-embody` repository after installing its dependencies, the current `sidefx-cli`, and the database and pinned SDA workspace dependencies described in the root README:

```powershell
npm run qualify:pilots
npm run package:pilots
```

On Windows the qualifier requires PowerShell 7 (`pwsh`) and resolves the installed `sfx` command. It invokes that command from the project directory with each exact JSON input in a file. It does not replace the requested CLI proof with an SDK call. Pilot selection and additional refusal/serialization probes live in [config](../../../config/hugging-face-pilots.json); positive expectations come from selected fixture authority. Preparation is never invoked.

The [qualification runner](../../../scripts/qualify-pilots.mjs) retains each input, native stdout, native stderr, exit code, command, source digest and assertion result. It also captures the selected authority, root contracts and dependency closure, and refuses capture/execution against different snapshots or projection digests. The [tracked observation](pilot-qualification.json) contains the compact results and identities. This observation reports execution; it is not a semantic authority or managed admission record.

Full local evidence from this run is under `evidence/hugging-face-pilots/2026-09-10T00-23-20.815Z/`. `evidence/hugging-face-pilots/latest.json` points to the latest completed qualification. Evidence is ignored by Git; the runner, configuration, container recipe, profiles and compact observation are ordinary tracked-source candidates. Failed attempts can retain partial evidence directories without replacing the latest pointer.

The observed CLI commands used this shape; the receipt contains the complete path for each case:

```powershell
sfx capability invoke greet-by-name --namespace 'sidefx:capabilities' --input '@<case>.input.json' --json
```

| Pilot | Authority fixtures | Additional probes | Result |
|---|---:|---:|---|
| `say-hello-world` | 1 | 2 | Exact `Hello, World!`; missing envelope and extra payload member refused |
| `greet-by-name` | 2 | 6 | Sidney and Zoë preserved; missing, empty, null and 101-character names refused; whitespace and markup preserved as values |
| `resolve-sidefx-eligible-providers` | 4 | 1 | Declared target, missing target, wrong target, admission/conformance failures and null input distinguished |

Every CLI process returned exit code 0, including cases whose **kernel disposition was `rejected`**. Provider fixture commands terminated with either `PROVIDERS_RESOLVED` or `NOT_OBSERVABLE`; termination alone does not establish provider eligibility. The fixture named `admit-provider-once-its-target-is-declared` exercises a pure resolution calculation, not a managed admission write or external provider invocation.

Observed whole-command times were 6.425–7.157 seconds, including process startup and authority/planning work. This is a small local sample, not a service latency commitment. Markup preservation here proves serialization only; safe text rendering and browser behavior still need their own checks.

All pilots selected model 32 and a one-scenario closure each. Full capability, scenario, contract, fixture, compiler, module and artifact identities are in the tracked observation. Shared pins:

- Projection: `sha256:4b8fca785f5f6f121d6274fc480187219e5662778459ca2ce2a1d098e337fa3f`
- Snapshot: `sha256:1a770ac0795d10665a88166f8d8c968dc5b2d030fdfab2b837aa6071d135f9e9`
- SDA commit: `716811046f52dd2a67f9ff308a50d755571cbbad`

The current runs agree with all seven retained fixtures. Additional probes document contract boundaries absent from those fixtures. Historical 94/219 preparation coverage and earlier preparation-read timings are not reused as current readiness evidence. The `sfx-platform` README, capability execution guide, API README and execution explanation have been reconciled with direct invocation.

## Input ownership and renderer support

[Pilot interaction profiles](pilot-interaction-profiles.json) are now compiled into the local `sfx-platform` Lab publication and enforced by its server adapter and command-service policy. They bind ownership and presentation to the observed schema digests. They are not registered estate authority. Existing contracts remain the source for admissible values; retained fixtures remain the source for example inputs and expected outcomes. Run `npm run dev:lab` from `sfx-platform` to use the implementation.

| Profile | User controls | Fixed or system-owned input | Outcome presentation |
|---|---|---|---|
| Hello World action | Explicit Run only | Exact contract ID and empty payload object | Greeting text |
| Personal greeting form | Required name string, 1–100 characters | Contract ID; payload object assembled from declared child field | Greeting text, escaped as text |
| Provider fixture demonstration | Choose one of four retained examples, then Run | Entire canonical fixture, including inventory, target, lifecycle, assurance fields and digest claims | Resolution disposition, considered/eligible counts, provider reasons, findings and trace digests |

The provider example selector is experience state. It does not introduce an `exampleId` into the canonical capability contract. The trusted adapter resolves the selected, digest-bound fixture and constructs the existing input envelope. An arbitrary visitor-supplied inventory or `conformanceDisposition` must not become assurance evidence. The initial interaction deliberately limits the entire provider request to retained examples.

| Required feature | Qualification today | Renderer acceptance obligation |
|---|---|---|
| Closed objects and fixed constants | CLI refuses missing envelope/extra hello payload member | Serialize constants and `{}` without showing misleading editable controls |
| Required bounded strings | Missing/empty/null/oversized values refused | Preserve missing vs empty vs null; never trim or normalize implicitly |
| Unicode and markup | Values preserved by execution | Count characters consistently with JSON Schema; render markup as text; keyboard and assistive-technology checks |
| Local and relative schema references | Native bodies carry a working catalog closure | Resolve by publication scope and digest; include provider outcome's common-schema reference |
| Nested provider/finding arrays | Retained native results verified | Shared collection views, empty states, reasons and evidence links; no capability-name branch |
| Held and rejected outcomes | Kernel/domain distinctions verified | Separate transport state, kernel disposition, domain disposition and admission |
| Scalar roots, branch switching, conflicting IDs, missing authority | Not qualified by these three roots | Add independent vectors; show an explicit unsupported hold until supported |

The new `/lab` renderer offers only the declared action, text field or retained-example selector. It resolves schemas within each pilot publication, rejects unknown editable fields and renders outcomes as escaped text and structured collections. Provider reasons are visible immediately; assurance details and trace digests expand on demand. The older catalog form remains separate. The broader scalar/branch corpus and a full accessibility audit remain outside this pilot verification.

## Container dependency proof

The [packager](../../../scripts/package-qualified-pilots.mjs) replans each captured authority bundle on the trusted local machine, checks every selected authority identity against the CLI receipt, and copies the unchanged native-body closure. It does not query a newer estate. The package contains 21/22/26 body files and loads 12/14/14 modules for the three pilots respectively.

The execution image needs Node, the unchanged memory loader, those native bodies and **Ajv 8.20.0**. Its [lockfile](../../../scripts/pilot-container/package-lock.json) pins Ajv's four transitive packages with integrity values. TypeScript, Prettier, Git, the SQL driver, the CLI installation and sibling checkouts remain planning/service dependencies; they are absent from the execution-only package.

After packaging, build/run the directory named by `<qualification directory>/container-latest.json`:

```powershell
docker build --tag sidefx-pilot-dependency-proof:local <package-directory>
docker run --rm --network none --read-only --cap-drop ALL --security-opt no-new-privileges --pids-limit 64 --memory 256m --cpus 1 --stop-timeout 3 sidefx-pilot-dependency-proof:local
```

The observed image was `sha256:cda31cc6d260de4050319816ec0786f5c52f49fa6ca8d4ac261cabe2a634c0a9`, on Node 24.20.0/Linux x64. Inspection confirmed user `node`, no mounts, no network, read-only root filesystem, all capabilities dropped, no-new-privileges, 256 MiB, one CPU and a 64-process limit. Native result objects, execution records and observations matched the separately retained CLI output; only observation timestamps were excluded. Module digests matched. Three modified-body attempts were refused.

The named proof container was retained after exit so its configuration and exit code could be inspected. Build output, native stdout/stderr, image/container inspection and a package byte manifest are retained beside the package. The tracked observation includes hashes and the relevant inspected limits.

This proves that these selected bodies execute in a bounded dependency image. It does not package the complete live SQL selection/planning service, implement immutable publication execution, or qualify hostile-code isolation. The VM loader is still not a security sandbox. No worker image or retained authority bundle was uploaded to Hugging Face; execution stays on the SideFX-owned side of the proposed deployment.

## Publication-to-run and access design

The recommended first implementation binds a publication to an immutable, qualified runtime release on the SideFX service. A release pairs its scoped contracts and profiles with the exact native-body closure and authority receipt. An activation record atomically selects that pair. Existing runs keep their captured release; activating a new release cannot change the authority of a run already accepted.

Keep the command body `{ object, operation, subject, namespace?, input }`. Resolve publication identity through authenticated service routing or a generic transport header. The service validates that identity, caller, exact namespace/subject/operation and input policy against one captured release before dispatch. It must execute that release's body, not resolve the latest SQL authority again after comparison. Return a stale-publication hold with `NOT_STARTED` when the requested release is unavailable. A frontend comparison followed by today's unrestricted latest-authority invocation remains a race and is not an implementation of this design.

The execution-only package above demonstrates dependency separation, but its parity runner is not a new command provider. Integrating an immutable release into the existing generic delivery boundary still needs implementation and compatibility tests. Do not turn this packaging step or optional preparation into a prerequisite for ordinary direct `sfx` invocation.

The private Space hosts the shared renderer and server adapter. It receives sanitized publications and a narrowly scoped service credential in server-only configuration; it receives no SQL or provider credentials. The SideFX endpoint authenticates every caller and authorizes only the exact three published roots and retained provider examples for this release. Private Space visibility does not authorize an otherwise public SideFX endpoint. If per-user identity is not established initially, define the private Space as one bounded service principal with aggregate limits rather than asserting individual user attribution.

The current `sfx-platform/services/capability-api` has operation restrictions, a bounded body and concurrency reservations, but lacks authentication, exact-subject authorization and revision binding. Keep it on loopback until those controls are implemented. Reuse its generic command transport instead of adding Hugging Face commands or capability-specific routes. SQL selection/planning runs inside a trusted SideFX service; reviewed deterministic bodies run in controlled workers. Reuse the existing Azure infrastructure only after the runtime package and staged access boundary are concrete.

Required boundary tests include denied/missing credentials, unauthorized namespace/subject/operation, tampered fixture inventory, stale/revoked publication, a publication swap between validation and execution, changed body bytes, concurrent capacity exhaustion, deadline/worker termination and lost-response uncertainty. Persist run identity/status before remote dispatch and disable automatic retries until an idempotency contract is implemented. A timeout cannot establish that execution did not happen.

## Remaining gate

The qualification, execution dependency proof and local ownership/renderer slice are complete. The local runtime now checks the very plan it will execute against the published authority before loading it. The user has made Hugging Face deployment mandatory for the next run: all three interactions and a real RapidAPI stock-price request must work from `BPMSoftwareSolutions/SideFX` through the remote SideFX service. The [next-run acceptance target](next-run-live-finance.md) remains incomplete until that deployed path is verified; local execution cannot substitute for it.

The user approved account setup and this technical groundwork. The plan's proposed $500/month program ceiling and full 12-week staffing schedule are not inferred from that approval. No model evaluation, public data release or provider promotion is part of this qualification.
