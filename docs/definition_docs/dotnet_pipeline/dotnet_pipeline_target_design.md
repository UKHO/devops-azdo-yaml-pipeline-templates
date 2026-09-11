# .NET Pipeline — Target Design (PBI-Derived)

> **Scope of this document:** This describes the **target design** for the `.NET` pipeline
> workstream (Workstream A) exactly as specified across the PBI design docs in
> `azdo-pipeline-research/design/pbis/`. It intentionally does **not** describe, reference, or
> reconcile against any current code in this repository — it is a pure design specification,
> to be used as the basis for implementation work. Where a PBI itself marks something as an open
> question or "TBD", that is preserved here rather than resolved.
>
> **Source PBIs:** A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13 (see
> `azdo-pipeline-research/design/pbis/`). ADR references (`[ADR-00xx]`) are as cited in those PBIs.

---

## 1. Pipeline composition model

Per **PBI A4** (resolved via `ADR-0054`), the `.NET` pipeline is composed as an ordered sequence of
standalone job templates, not a single monolithic build job:

**Package → Test → Build → Scan (before/after build as needed) → Publish**

- **Package job** (PBI A13) runs first. It packages the `.NET` solution and its test files into a
  shared artifact so downstream jobs don't each independently re-checkout/re-restore source.
- **`dotnet_test` job** (PBI A3) consumes the package job's artifact and runs test execution, plus
  any opt-in test tools (Stryker — A5, ReportGenerator — A6).
- **`dotnet_build` job** (PBI A2) consumes the package job's artifact and produces the deployable
  build output. It does not test and does not publish to a destination.
- **Security-scanning jobs** (Workstream B) run either before or after the build job, depending on
  what each scan naturally targets.
- **Publish-destination jobs** (PBI A8, A9, A10; A11 parked) run last, consuming the build job's
  output artifact.
- **`dotnet_deploy`** (PBI A7) is a separate downstream concern again, consuming whatever a
  publish-destination job produced.
- **Playwright** (PBI A12) is an architecturally separate sibling template family (Node.js-based),
  running downstream of build/deploy — it is not part of the `.NET` job sequence above.

This composition model replaces an earlier, since-superseded idea of embedding test execution as
steps inside `dotnet_build` — see PBI A4's resolution record for the history.

---

## 2. Package Job (PBI A13)

**Status:** Not started (new PBI, introduced by the A4/`ADR-0054` resolution)

**Purpose:** First job in the sequence. Packages the `.NET` solution and its test files (if
detected) into a shared artifact consumed by the downstream `dotnet_test` and `dotnet_build` jobs,
so those jobs don't each independently re-checkout/re-restore source.

### Steps

1. Checkout the repository `[ADR-0001]`
2. Install the pinned .NET SDK from `global.json` `[ADR-0019]`
3. Restore the solution
4. Detect and include test files/projects if present
5. Publish the result as a shared artifact consumed by both `dotnet_test` (A3) and `dotnet_build` (A2)

### Proposed parameters

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `RelativePathToSolution` | string | `''` | Path to the `.sln`/project — same convention as A2/A3 |
| `IncludeTestProjects` | boolean | `true` (auto-detected) | Whether test-project detection/inclusion is a real toggle or fully automatic is still open — needs confirming during implementation |
| `ArtifactName` | string | `'DotNetPackage'` | The shared artifact name consumed by A2 and A3 |

### Dependencies

- None upstream — first job in the sequence.
- **Blocks:** A2 (`dotnet_build`) and A3 (`dotnet_test`) both consume this job's output artifact.

### Out of scope

- Actually building (`dotnet build`) or testing — this job only restores/packages source.

### Open questions

- Exact artifact contract (file layout, naming, versioning) — deferred to implementation.
- Whether restore happens once here and never again downstream, or whether A2/A3 still need a
  lightweight restore step of their own depending on NuGet caching behaviour across artifact
  publish/download between jobs.

---

## 3. `dotnet_test` Job (PBI A3)

**Status:** Ready to design in detail — A4 resolved via `ADR-0054`

**Purpose:** Second job in the sequence. Runs the one mandatory test tool
(`dotnet test --no-build` + TRX publish) against the package job's artifact. Stryker (A5) and
ReportGenerator (A6) attach here as opt-in extensions.

### Steps

1. Run `dotnet test --no-build` against the Release build produced by A2's package input
   `[ADR-0001]`
2. Publish TRX test results **even when tests fail** `[ADR-0003]`

### Proposed parameters

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `ArtifactName` | string | inherited from A13 | The package artifact to test against |
| `Condition` | string | `succeeded()` | Same convention as A2 |
| `DependsOn` | object | `[A13's job name]` | Runs after the package job |
| `Pool` | string | `''` | |
| `TestResultsFormat` | string | `'TRX'` | Fixed, not user-configurable `[ADR-0003]` |
| `PostTestInjectionSteps` | stepList | `[ ]` | Hook after test, before downstream build/publish `[ADR-0002 escape hatch]` |

### Behavioural constraints (fixed)

- `--no-build` always used — the build tested must be the exact same build that gets published
  `[ADR-0001]`.
- TRX publish step runs unconditionally, including on test failure `[ADR-0003]`.
- No toggle to skip test execution entirely — test scope may be config-driven per test project, but
  "no tests run at all" is not a supported mode `[ADR-0034]`.

### Out of scope

- Stryker (A5), ReportGenerator (A6), Playwright (A12) — separate PBIs, opt-in on top of this
  baseline.
- Any publish-destination logic (A8–A11).

### Open questions

- Exact package-artifact contract consumed from A13 — deferred to implementation.

---

## 4. `dotnet_build` Job (PBI A2)

**Status:** In progress

**Scope:** Checkout → SDK install → restore/build only. Test execution, publish destinations, and
tool integrations are explicitly out of scope for this job (see below).

### What this job delivers

1. Checkout the repository `[ADR-0001]`
2. Install the pinned .NET SDK from `global.json` `[ADR-0019]`
3. Restore and build in `Release` configuration — mandatory, no toggle `[ADR-0001, ADR-0034]`
4. Produce a build-output artifact that downstream jobs (test, publish destinations) consume

This is deliberately the smallest useful unit: a job that produces a built, unpublished, untested
`Release` output. Every other PBI in Workstream A builds on top of this artifact rather than
extending this template directly `[ADR-0011]`.

### Proposed parameters

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `ArtifactName` | string | `'DotNetArtifact'` | Same convention as `terraform_build.yml` |
| `Condition` | string | `succeeded()` | Same convention |
| `DependsOn` | object | `[ ]` | Same convention |
| `Pool` | string | `''` | Same convention |
| `DemandsProvided` | boolean | `false` | Skip tool install steps if `true`; fail fast if the SDK is missing `[ADR-0033]` |
| `RelativePathToSolution` | string | `''` | Path from repo root to the `.sln`/project to build |
| `BuildConfiguration` | string | `'Release'` | Fixed at Release `[ADR-0001]` |
| `PreBuildInjectionSteps` | stepList | `[ ]` | Escape hatch, same pattern as `TerraformBuildInjectionSteps` `[ADR-0002 escape hatch]` |

### Output contract

The artifact produced here is the contract every other PBI in this workstream consumes. Its exact
shape (what's in it, how it's named/versioned) is deferred to implementation `[ADR-0050]`.

### Extensibility

`PreBuildInjectionSteps` — runs after checkout/SDK install, before restore/build (e.g. generating a
config file, fetching a secret) `[ADR-0002, ADR-0009]`.

### Acceptance criteria

- Template accepts the parameter set above.
- `PreBuildInjectionSteps` injection point works.
- Produces a build-output artifact consumable by A3 (test template) and A8/A9/A10 (publish
  destinations) without requiring a rebuild.

### Out of scope

- Test execution of any kind (see A3, A5, A6, A12).
- Any publish-destination step (see A8–A11).
- Deployment (see A7).
- `DemandsProvided=true` tool-presence verification detail `[ADR-0033]`.

### Open questions

- Exact build-output artifact contract shape — deferred to implementation `[ADR-0050]`.

---

## 5. Publish Destinations

Publish destinations are a **pluggable, multi-entry list** `[ADR-0004]`, referenced here as a
`PublishDestinations` parameter (array of typed objects) consumed downstream of `dotnet_build` (A2).
Each destination is described by its own PBI. None of the three active destinations have a
finalised parameter shape yet — all are marked "Not started" and the shapes below are provisional.

### 5.1 Cloud App Package (PBI A8) — priority 1

**Status:** Not started

**Behavioural decisions already fixed:**

- Framework-dependent by default; self-contained/container-style publish only when the runtime must
  be explicitly controlled `[ADR-0013]`.
- Build-once principle — consumes the exact build already tested, never triggers a separate build
  `[ADR-0001]`.
- Breaking-change boundary — changes to this destination's output shape are breaking changes for
  consumers `[ADR-0035]`.
- Part of the pluggable multi-destination list, not a single hardcoded path `[ADR-0004]`.

**Proposed parameters:**

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `PublishDestinations[].type` | string | n/a | `'CloudAppPackage'` |
| `SelfContained` | boolean | `false` | Framework-dependent is the default; only `true` when runtime control is explicitly required `[ADR-0013]` |
| `PackagePath` / target details | TBD | — | Needs finalising against whichever specific Azure task is used (e.g. `PublishBuildArtifacts@1` + `AzureWebApp@1`) |

**Dependencies:** A2 — needs a stable build-output artifact.

**Out of scope:** Actual deployment/rollout of the package (A7's job); container registry publish
(A9); NuGet/ProGet (A10).

**Open questions:** Exact task/step sequence for producing and naming the package artifact.

### 5.2 Container Registry — SDK Container Publish (PBI A9) — priority 2

**Status:** Not started — needs its own auth/tagging/caching design sub-pass before implementation

**Behavioural decisions already fixed:**

- SDK-native container publish (`dotnet publish /t:PublishContainer`) is **preferred over a
  hand-written Dockerfile** `[ADR-0013]` — avoids maintaining a separate Dockerfile artifact and its
  own drift risk.
- Breaking-change boundary, same as all destinations `[ADR-0035]`.
- Part of the pluggable multi-destination list `[ADR-0004]`.

**Explicitly NOT yet decided** (bigger design gap than the other destinations — needs a dedicated
design pass before implementation can be sized):

- Registry auth per provider (ACR, Docker Hub, GHCR, etc. each have different auth mechanisms).
- Tagging strategy (semantic version? git SHA? branch name?).
- Layer-caching strategy for build performance.

**Proposed parameters (partial — pending the design sub-pass):**

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `PublishDestinations[].type` | string | n/a | `'ContainerRegistry'` |
| `PublishDestinations[].registry` | TBD | n/a | Shape provisional |
| `PublishDestinations[].tag` | TBD | n/a | Shape provisional |
| `ContainerRegistryConnection` | string | `''` | Service connection name — auth model still TBD |

**Dependencies:** A2 (stable build-output artifact); its own design sub-pass (auth/tagging/caching)
— treat as a definition-of-ready blocker before sizing implementation work.

**Out of scope:** Dockerfile-based publishing (deliberately not the chosen approach `[ADR-0013]`);
deployment of the resulting image (A7).

**Open questions (carried over):** Registry auth model per provider; tagging convention;
layer-caching approach.

### 5.3 NuGet/ProGet Feed (PBI A10) — priority 3

**Status:** Not started

**Behavioural decisions already fixed:**

- Authenticated via `NuGetAuthenticate@1`, **not** `DotNetCoreCLI@2 push` `[ADR-0031]` — the auth
  task is the standard mechanism, not baking credentials into the push command itself.
- Versioned from `Directory.Build.props` — the canonical package-version source of truth, not a
  pipeline-computed version or a manually bumped `.csproj` value `[ADR-0026]`.
- Breaking-change boundary, same as all destinations `[ADR-0035]`.
- Part of the pluggable multi-destination list `[ADR-0004]`.

**Proposed parameters:**

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `PublishDestinations[].type` | string | n/a | `'NuGetFeed'` |
| `PublishDestinations[].feedUrl` | string | n/a | Target feed URL |
| `NuGetServiceConnection` | string | `''` | Consumed by `NuGetAuthenticate@1` |

**Step sequence (draft):**

1. Read package version from `Directory.Build.props` (already present in the repo, not generated by
   the template) `[ADR-0026]`.
2. `dotnet pack` the project(s) against the already-built Release output.
3. `NuGetAuthenticate@1` against the target feed.
4. Push the package.

**Dependencies:** A2 — needs a stable build-output artifact.

**Out of scope:** Package version *computation* logic (the template reads
`Directory.Build.props`, it doesn't decide the versioning scheme); cloud app package (A8) and
container registry (A9).

**Open questions:** Multi-package-per-solution handling — if a solution produces more than one
NuGet package, does this destination push all of them by default or require explicit opt-in per
project?

### 5.4 Dacpac/Database (PBI A11) — parked

**Status:** Parked — not started, only pick up if database delivery is pulled back into scope

- Originally priority 4 in the destination build order `[ADR-0013]`.
- **Explicitly dropped** from `dotnet_build`'s scope because `sqlpackage` is out of scope for the
  fixed tool set `[ADR-0040]`.
- `[ADR-0015]` had already decided, independently of the tool-scope question, that dacpac/database
  work gets its **own standalone template** rather than living inside `dotnet_build`'s destination
  list at all.

This is not "destination A11 of `dotnet_build`" — it is a reminder that a separate template family
(`dotnet_dacpac` or similar) would need its own research-and-design pass, structurally independent
from everything else in this document.

**If unparked, would need:** a dedicated research pass on `sqlpackage` usage patterns; a standalone
design doc; reconsideration of `[ADR-0040]`'s fixed-tool-set boundary via its own ADR.

**Open questions:** Is there active demand for this, or does `[ADR-0040]`'s boundary hold
indefinitely? A product conversation, not a technical spike, is needed before this PBI moves.

---

## 6. Opt-in Test Tooling (attaches to `dotnet_test`, PBI A3)

### 6.1 Stryker Mutation Testing (PBI A5)

**Status:** Not started

**Purpose:** Runs Stryker.NET mutation testing, entirely opt-in based on the presence of Stryker
configuration — no boolean toggle `[ADR-0041]`.

**Behavioural decisions already fixed:**

- Scope driven by consumer input, not template-auto-split — the template doesn't decide which
  projects get mutated; the consumer's config does `[ADR-0020]`.
- Local tool manifest, pinned version — Stryker.NET is installed via a committed local
  `dotnet-tools.json` manifest with an exact version pin, not a floating "latest" `[ADR-0027]`.
- Gating cadence — scoped/incremental runs on PR, full run nightly, diagnostic-first rollout (i.e.
  report-only before it becomes PR-blocking) `[ADR-0028]`.
- Multi-project execution model — one Stryker config per test project, run as a parallel matrix
  rather than one monolithic run `[ADR-0029]`.
- Reporting — mutation-testing results surface separately from unit/e2e test results, not merged
  into the same Tests-tab view `[ADR-0030]`.

**Proposed parameters:**

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `StrykerConfig` | object | `null` | Presence = opt-in. Likely a list of `{ projectPath, configFile }` pairs to support the matrix model `[ADR-0029]` — needs finalising during implementation |
| `StrykerRunMode` | string | `'incremental'` | `'incremental'` (PR) vs `'full'` (nightly) `[ADR-0028]` — may be derived from pipeline trigger context instead of an explicit parameter; needs deciding |

**Step sequence (draft):**

1. Restore the pinned Stryker.NET tool from the committed manifest `[ADR-0027]`.
2. For each entry in `StrykerConfig`, run `dotnet stryker` against that project's config, in
   parallel (matrix strategy) `[ADR-0029]`.
3. Publish mutation report(s) to a location distinct from the unit-test Tests-tab surface
   `[ADR-0030]`.

**Dependencies:** A3 (`dotnet_test`) — attaches to the `dotnet_test` job, not `dotnet_build`.
Requires the pinned local tool manifest to exist in the consumer's repo (a prerequisite documented
in onboarding, D1).

**Out of scope:** Deciding PR-blocking thresholds (cadence is fixed by `[ADR-0028]`, but the actual
mutation-score gate value is a consumer config choice); ReportGenerator merge (A6) — separate,
unrelated tool.

**Open questions:** Exact `StrykerConfig` object shape; whether `StrykerRunMode` is an explicit
parameter or derived from `Build.Reason`/trigger context.

### 6.2 ReportGenerator Multi-Project Coverage Merge (PBI A6)

**Status:** Not started

**Purpose:** Automatic coverage merge for solutions with more than one test project — no
consumer-facing toggle.

**Behavioural decisions already fixed:**

- Required, not redundant, for multi-project coverage merge — without it, multi-project coverage
  numbers are simply wrong/incomplete `[ADR-0032]`.
- No consumer-facing toggle — internal implementation detail of the test step, triggered
  automatically by detecting >1 coverage file, unlike Stryker's explicit config-presence opt-in
  `[ADR-0041]`.
- Test-result aggregation model: unit/e2e results publish natively (Tests tab), mutation results
  surface separately, coverage-merge output is its own surface too `[ADR-0030]`.

**Step sequence (draft):**

1. After `dotnet test` runs across all test projects, detect how many coverage files were produced.
2. If more than one, install/run ReportGenerator to merge them into a single report.
3. Publish the merged report as a build artifact (coverage HTML/summary).

**Proposed parameters:** None expected — auto-triggered, not parameterised, per
`[ADR-0032]`/`[ADR-0041]`. If a consumer needs to suppress it, that likely means restructuring their
test-project layout, not a template flag.

**Dependencies:** A3 (`dotnet_test`) — sits immediately after core test execution within the
`dotnet_test` job, not inside `dotnet_build`.

**Out of scope:** Any coverage threshold/gating logic (only merges reports, doesn't decide
pass/fail); Stryker (A5) — unrelated tool despite both touching "coverage".

**Open questions:** Exact detection mechanism for ">1 coverage file" (file glob count vs. an
explicit multi-project flag from `RelativePathToSolution` structure).

---

## 7. Playwright — e2e/UI Test Template (PBI A12)

**Status:** Not started

**Scope:** A standalone Playwright e2e test job template — a **sibling** template family, not a
`dotnet_build` feature, since its main tool is Node.js, not `dotnet` `[ADR-0021, ADR-0039]`.

**Behavioural decisions already fixed:**

- Sibling template, not a `dotnet_build` feature `[ADR-0021, ADR-0039]`.
- Runs as its own downstream job, after the build/deploy job it follows — not a step embedded in
  another job `[ADR-0051]`.
- Browser provisioning: container job, pinned to a specific package version — not ad-hoc browser
  installs on a shared agent `[ADR-0022]`.
- Reporting: JUnit results to the Tests tab, HTML report as a build artifact, both gated on failure
  `[ADR-0023]`.
- Test staging: smoke tests on PR, full cross-engine (Chromium/Firefox/WebKit) run nightly
  `[ADR-0024]`.
- Sharding: threshold-triggered (e.g. once suite size/runtime crosses a defined point), not
  default-on for every consumer `[ADR-0025]`.
- Post-deploy wiring is out of scope for now — this job runs downstream of whatever it's told to
  follow, but automatic "runs after every deploy" orchestration isn't being built yet `[ADR-0053]`.

**Proposed parameters:**

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `PlaywrightVersion` | string | `''` | Pinned package version for the container image `[ADR-0022]` |
| `DependsOn` | object | `[ ]` | The build/deploy job this follows |
| `RunMode` | string | `'smoke'` | `'smoke'` (PR) vs `'full'` (nightly cross-engine) `[ADR-0024]` |
| `EnableSharding` | boolean | `false` | Only flips on past the adoption threshold `[ADR-0025]` — exact threshold criteria TBD |

**Dependencies:** Not blocked by A4 — architecturally separate from the `dotnet_build`/`dotnet_test`
split question. Needs *something* to depend on (a build or deploy job) to be meaningful — likely
sequenced after A2 and/or A7 exist.

**Out of scope:** Automatic post-deploy job wiring `[ADR-0053]`; any `.NET`-specific test logic.

**Open questions:** Exact sharding adoption threshold (suite size? runtime minutes?); what
"downstream of build/deploy" means as a concrete `DependsOn` wiring convention, given A7 doesn't
exist yet.

---

## 8. `dotnet_deploy` Template (PBI A7)

**Status:** Not started — needs its own full research-and-ADR pass

**Scope:** Deployment of the artifact `dotnet_build` produces, to whichever environment(s) the
consumer targets. This is a placeholder/scaffold, not a resolved design.

**What's already decided that constrains this design:**

- Cloud-first only, on-prem out of scope for v1 `[ADR-0017]`.
- Post-deploy smoke/verification testing is explicitly out of scope — this template does not verify
  the deployment succeeded functionally `[ADR-0047]`.
- Playwright post-deploy wiring is also out of scope for now — no automatic e2e trigger after
  deploy `[ADR-0053]`.
- The artifact contract this consumes is whatever A2/A8/A9/A10 (build + publish destinations)
  settle on — `dotnet_deploy` is a pure downstream consumer, not a re-builder, per the "build once"
  principle `[ADR-0001]`.

**Open questions requiring their own research pass:**

- Environment progression model (dev/qa/live) — mentioned in the product goal's vision but nowhere
  resolved in existing ADRs.
- Approval gates / release-gate conventions.
- Rollback strategy, if any, in scope for v1.
- How this maps against the "input → process → output" shape `[ADR-0005]` for a deploy-specific
  context (what's the "output" of a deploy job — a deployment record? a URL? nothing published at
  all?).

**Dependencies:** A2 must be stable enough (build-output artifact contract finalised) before deploy
can consume it meaningfully. Should probably wait for at least one publish destination (A8/A9/A10)
to be implemented, since deploy likely targets whichever destination the consumer chose.

**Out of scope (already decided):** On-prem targets `[ADR-0017]`; post-deploy smoke testing
`[ADR-0047]`; Playwright post-deploy wiring `[ADR-0053]`; code signing `[ADR-0042]` (parked, not
deploy-specific but relevant if deploy touches signed artifacts).

**Recommended next step:** Run a dedicated research pass (mirroring the one that produced
`adr/0001`–`0053`) before attempting a design doc. This PBI should not be sized/started as
implementation work until that research exists.

---

## 9. Summary: parameter objects by job

| Job | Config object (proposed) | PBI | Status |
|---|---|---|---|
| Package job | (no named config object yet) | A13 | Not started |
| `dotnet_test` | (no named config object yet) | A3 | Ready to design in detail |
| `dotnet_build` | `DotNetBuildConfig`-equivalent (per §4 above) | A2 | In progress |
| Publish: Cloud App Package | `PublishDestinations[type=CloudAppPackage]` | A8 | Not started |
| Publish: Container Registry | `PublishDestinations[type=ContainerRegistry]` | A9 | Not started (needs design sub-pass) |
| Publish: NuGet/ProGet | `PublishDestinations[type=NuGetFeed]` | A10 | Not started |
| Publish: Dacpac/Database | N/A — own template family if unparked | A11 | Parked |
| Stryker | `StrykerConfig` | A5 | Not started |
| ReportGenerator | N/A — auto-triggered, no config | A6 | Not started |
| Playwright | (sibling template, own config) | A12 | Not started |
| `dotnet_deploy` | (no named config object yet) | A7 | Not started |

---

## See Also

Design PBIs (in `azdo-pipeline-research/design/pbis/`):

- [A2 — `dotnet_build` core](../../../../azdo-pipeline-research/design/pbis/A2-dotnet-build-core.md)
- [A3 — `dotnet_test` core](../../../../azdo-pipeline-research/design/pbis/A3-dotnet-test-core.md)
- [A4 — composition-model decision](../../../../azdo-pipeline-research/design/pbis/A4-test-template-split-decision.md)
- [A5 — Stryker](../../../../azdo-pipeline-research/design/pbis/A5-stryker.md)
- [A6 — ReportGenerator](../../../../azdo-pipeline-research/design/pbis/A6-reportgenerator.md)
- [A7 — `dotnet_deploy`](../../../../azdo-pipeline-research/design/pbis/A7-dotnet-deploy.md)
- [A8 — publish: cloud app package](../../../../azdo-pipeline-research/design/pbis/A8-publish-cloud-app-package.md)
- [A9 — publish: container registry](../../../../azdo-pipeline-research/design/pbis/A9-publish-container-registry.md)
- [A10 — publish: NuGet/ProGet](../../../../azdo-pipeline-research/design/pbis/A10-publish-nuget-proget.md)
- [A11 — publish: dacpac (parked)](../../../../azdo-pipeline-research/design/pbis/A11-publish-dacpac.md)
- [A12 — Playwright](../../../../azdo-pipeline-research/design/pbis/A12-playwright.md)
- [A13 — package job](../../../../azdo-pipeline-research/design/pbis/A13-package-job.md)
