# Design: .NET Build (Iteration 7)

**Status:** Draft. This design stands on its own and supersedes [iteration 6](dotnet_build_design_v6.md), which is retained for review history.

**Target:** `jobs/dotnet_build.yml` in `0.4.0`, with `DotNetFormat` as the first pre-build check and `DotNetTest` as the first post-build check. Coverage enforcement, other checks and destinations can ship independently in later MINOR releases. Container packaging is conditional on its verification fixture.

**Comments:** Ok I would want to have more than just DotNetFormat... the idea will be to expand out on a few different things...

## 1. Purpose and Execution Model

`jobs/dotnet_build.yml` is a public behavioural template. It adopts the entry format and warning behaviour from the existing [Build Checks contract](../docs/user-docs/checks/README.md), but proposes two explicit phases for .NET rather than Terraform's single `Checks` list. The Terraform interface is unchanged. Update the shared guide when the .NET phases ship.

1. **Prepare and restore:** Check out `self` to an explicit path, disable implicit downloads where applicable, initialise job directories, install or verify the SDK, load config sources, authenticate to NuGet and restore once.
2. **Pre-build checks:** Run `PreBuildChecks` in declaration order. These checks can use source and restored metadata but cannot require compiled output.
3. **Build:** Compile once with `--no-restore`. A failed restore, blocking pre-build check or failed compile prevents post-build checks and packaging.
4. **Post-build checks:** Run `PostBuildChecks` in declaration order. These checks can use compiled output or reports already produced by earlier checks.
5. **Package:** Package the built output without rebuilding.
6. **Finalise:** Publish available reports and optional diagnostics, and upload a run summary even when a phase fails.
7. **Deliver:** Each entry in `Destinations` delivers its selected packages. `PipelineArtifact` is a real destination that runs as the final step of the build job, because every other destination downloads from it. All other destinations (later) run as separate jobs that can be retried independently of the build.

A build with both lists empty compiles and can package, but has not run checks. The summary says **No checks configured** rather than implying the packages were tested. Build checks are not Azure DevOps environment approvals and checks; the latter can protect future deployment jobs independently.

**Comments:** Ok I need to think about the 5 / 6 / 7... they will possible be a merged thing... I'm just trying to understand how to break all of this down into the subjobs for the real thing... Possible there will be a prototype that we can make first... then trial that out and see how it works...

## 2. Public Job Interface

- **`ArtifactName`** (`string`, default `'DotNetArtifact'`): Package artifact name and suffix for `DotNetBuild_<ArtifactName>`.
- **`Condition`** (`string`, default `succeeded()`): Condition for the build job.
- **`DependsOn`** (`object`, default `[]`): Dependencies for the build job.
- **`Pool`** (`string`, default `''`): Build job pool override; otherwise inherit the pipeline or stage pool.
- **`DotNetBuildConfig`** (`object`, required): Build inputs and package requests.
- **`PreBuildChecks`** (`object`, default `[]`): Checks to run after restore and before compile.
- **`PostBuildChecks`** (`object`, default `[]`): Checks to run after compile and before packaging.

- **`Destinations`** (`object`, default `[]`): Where packages are delivered. `PipelineArtifact` ships in `0.4.0`; other types follow in later MINOR releases. An empty list behaves as a single `PipelineArtifact` destination when packages are configured.

The .NET job does not accept a single `Checks` list, `Testing`, `Gates`, or generic injection steps in `0.4.0`.

**Comments:** OK I think destinations need to be included in the design even if it is 1 destination of publishpipelineartifact...

### 2.1 Example: Checks, Packages and Destinations

This is a consumer pipeline showing where the design is heading, not just what ships first. It assumes the repository has a `global.json` and that the listed test projects are part of `MyApi.sln`. The `@AzDOPipelineTemplates` alias refers to the template repository resource in the pipeline.

The example uses framework-specific test check names (`DotNetTestNUnit`, `DotNetTestXUnit`, `DotNetTestMSTest`). Elsewhere in this design, `DotNetTest` is a placeholder for that family until the names are settled. Each can own its own defaults (filter syntax, adapter/collector expectations, result file handling) while sharing internal reporting helpers. Entries marked `# Candidate` are not committed to a release yet.

```yaml
pool:
  vmImage: ubuntu-latest

jobs:
  - template: jobs/dotnet_build.yml@AzDOPipelineTemplates
    parameters:
      ArtifactName: MyApi
      DotNetBuildConfig:
        RelativePathToSolution: MyApi.sln
        BuildConfiguration: Release
        Restore:
          UseLockedMode: true
        Packages:
          - Type: Publish
            Project: src/MyApi/MyApi.csproj
          - Type: NuGet
            Name: MyApiClient
            Project: src/MyApi.Client/MyApi.Client.csproj
        Diagnostics:
          CollectBinaryLog: true

      PreBuildChecks:
        - Check: DotNetFormat
          TreatAsWarnings: true
        - Check: DotNetVulnerablePackages # Candidate
          MinimumSeverity: High
          TreatAsWarnings: true

      PostBuildChecks:
        - Check: DotNetTestNUnit
          Name: Unit
          Project: tests/MyApi.Tests/MyApi.Tests.csproj
          TestRunTitle: Unit tests
          Filter: "Category=Unit"
        - Check: DotNetTestNUnit
          Name: Integration
          Project: tests/MyApi.Tests/MyApi.Tests.csproj
          TestRunTitle: Integration tests
          Filter: "Category=Integration"
          CollectCoverage: false
        - Check: DotNetTestXUnit # Candidate
          Name: ClientUnit
          Project: tests/MyApi.Client.Tests/MyApi.Client.Tests.csproj
          TestRunTitle: Client unit tests
        - Check: DotNetCoverage # Later MINOR
          Name: UnitLineCoverage
          Source: Unit
          Minimum: 80
          TreatAsWarnings: true

      Destinations:
        - Type: PipelineArtifact # 0.4.0; runs inside the build job
          Name: BuildOutput
        - Type: NuGetFeed # Later MINOR
          Name: InternalFeed
          Packages: [MyApiClient]
          DependsOn: [BuildOutput]
          Feed: MyProject/MyFeed
          AzDOEnvironmentName: nuget-internal
```

**Behaviour of this example:**

- A formatting violation or a high-severity vulnerable package warns and allows compilation.
- Any failing test entry blocks packaging. The coverage check warns below 80% on the `Unit` instance only; `Integration` disables coverage so it cannot be selected as a coverage `Source`.
- The Package phase produces `publish/MyApi.zip` and `nuget/MyApiClient/<PackageId>.<Version>.nupkg`.
- `BuildOutput` is a `PipelineArtifact` destination. It runs as the last step of the build job and publishes all packages as the `MyApi` pipeline artifact. When `Destinations` is omitted, the job behaves as if a single `PipelineArtifact` destination were declared, so the simplest consumer still gets an artifact.
- `InternalFeed` runs as a separate job after `BuildOutput`, downloads only `MyApiClient`, and pushes it to the feed behind the `nuget-internal` environment approval. It can be retried without rebuilding.

**Out of scope for this job:** Playwright/browser tests and mutation testing run as their own jobs, not as build checks (see section 4).

**Comments:** OK this looks good so far... I reckon the checks will become more specific as there is all the different types of dotnet test like nunit and xunit then even mstest i think... possible teams will need all of them... then there is things like playwright and stuff

### 2.2 Build Configuration

`DotNetBuildConfig` contains only build and packaging inputs:

- `RelativePathToSolution` (required): repository-relative `.sln`, `.slnx` or `.csproj`; the selected SDK must support the file type.
- `BuildConfiguration`: defaults to `Release`; restore, build, tests and packages agree on configuration and any required runtime settings.
- `DotNetSdk`: `Version` defaults to `''` (resolve from `global.json`); `Install` defaults to `true`. `Install: false` only verifies the resolved SDK. If neither `Version` nor a usable `global.json` is available, fail with instructions to supply one.
- `Restore`: optional `NuGetConfigPath` and `UseLockedMode` (default `false`). NuGet authentication precedes restore; feed credentials are not passed as CLI arguments.
- `ConfigSources`: optional, using the existing shared config-source contract.
- `Packages`: optional list. Each entry has `Type`, `Project`, optional `Name` (project filename without extension by default), optional `Arguments`, and `ZipAfterPublish` for `Publish` only (default `true`).
- `Diagnostics`: optional `CollectBinaryLog` (default `false`). Binary logs can contain secrets; enable only when access and retention are appropriate.

**Comments:** HmmmOK... seems alright

## 3. Checks Contract

**Comments:**

### 3.1 Selection, Settings and Order

- `Check` selects a supported check by name. Each phase has an allowlist. Unknown names and checks placed in the wrong phase fail at compile time, with the supported names for that phase. Users cannot supply a template path.
- `Name` is optional for a singleton, but every occurrence of a repeated check within a phase needs a non-empty `Name`. Names are unique within each phase, case-insensitively, and use letters, digits and underscores. Include the phase in step IDs and report paths. Reserve distinct instance keys for named and unnamed checks.
- `TreatAsWarnings` defaults to `false`. A blocking failure stops subsequent work: a pre-build failure prevents compilation, and a post-build failure prevents packaging. A warning marks the job partially succeeded but allows subsequent phases. Use `continueOnError` for the check verdict, not restore, compile or finalisation.
- Entries run in the order listed within each phase. A report-driven check declares or defaults its producer explicitly; it never silently enables another check.
- A supported check can be selected with only `Check:` when its prerequisites are met (for example, a coverage check needs an earlier coverage-producing test check).

**Comments:** Make sense

### 3.2 Proposed Check Catalogue

**Pre-build**

- **`DotNetFormat`** (`0.4.0`): Source formatting without modifying files or compiling. SRJ: Yeah this one sounds OK
- **`DotNetVulnerablePackages`** (Candidate): Restored dependencies against a vulnerability policy. SRJ: OK not something I heard of before... possible as we do use snyk

**Post-build**

- **`DotNetTest`** (`0.4.0`): Test outcomes for previously built code; produces TRX and optional coverage. SRJ: this may breakdown to different tools... I think I want to make the checks very specific
- **`DotNetCoverage`** (Later MINOR): Line coverage threshold from an earlier `DotNetTest` result; optional ratchet later. SRJ: Again possible we may need the breakdown OR this may be included in other tools... There is the thing about mutation testing too but that maybe another check completely

Validate the name against the phase allowlist before dispatching to an internal template in `/checks/`, following the `terraform_build` precedent. Use typed template parameters for check settings. Inject job-owned paths and context separately and reject attempts to override them through either list.

A check may run a tool and decide its outcome (tests or format), or enforce policy on an existing report (coverage). Common reporting and metric comparison can be shared internally; there is no public generic `Gate`, generic script check, or `Type` discriminator for checks. Packages and future destinations still use `Type` for their own dispatch.

To add a check, assign a phase, define its defaults, verdict and prerequisites, wire it into the phase allowlist, and add fixtures and a Build Checks index entry. Reserve extraction of shared dispatch or schema logic for when another job needs it.

**Comments:** So yeah plenty there to go off

### 3.3 `DotNetFormat` (`0.4.0`)

Run `dotnet format whitespace --verify-no-changes --no-restore` against the configured solution or project. The initial check is whitespace-only: it uses `.editorconfig` and the existing restore, and does not run a build or fix files. No check-specific settings are proposed for `0.4.0`; `Name` and `TreatAsWarnings` still apply. Verify the command on the minimum supported SDK before release.

**Comments:** Yeah so that is fine... Will need to get plenty of alpha testing out

## 4. `DotNetTest` (`0.4.0`, Post-build)

`DotNetTest` is a placeholder name for the test check family. It is expected to split into framework-specific checks (for example `DotNetTestNUnit`, `DotNetTestXUnit`, `DotNetTestMSTest`) that share the settings and behaviour below.

- **`Project`** (default: `DotNetBuildConfig.RelativePathToSolution`): Repository-relative solution or project to test. An override must be part of the mandatory build.
- **`Filter`** (default: `''`): Optional VSTest expression passed as one argument to `dotnet test --filter`.
- **`TestRunTitle`** (default: Derived from the instance label or target when unnamed): Display title in the Tests tab. It is not a step ID or directory name.
- **`CollectCoverage`** (default: `true`): Collect Cobertura when the fixture/project has a compatible collector.

One entry runs one `dotnet test` command with `--no-build --no-restore` and the same configuration as the mandatory build. Separate entries can run the same project with different filters and titles. Use a fresh result directory per entry and preserve distinct result files for multi-targeted or multi-project runs. Verify that filtered runs which execute zero tests do not silently pass.

Publish TRX to the Azure DevOps Tests tab even when the test command reports failures. Prefer explicit result paths and native publishing without automatic result publication that would relocate or double-publish TRX.

Publish available Cobertura to the Code Coverage tab once per job and verify the merge with multiple entries. When coverage is requested but unavailable, report it as missing, not zero; a future coverage check must not pass without valid evidence.

Unit tests and self-contained integration/API tests belong here. Tests that require a deployment, externally authenticated identity or a separately provisioned browser environment belong in later stages. Playwright and other browser tests run as their own jobs.

Mutation testing stays a separate, typically PR-only job because it mutates and rebuilds code; that job can reuse internal metric helpers through its own supported check. VSTest is the initial runner; Microsoft.Testing.Platform is deferred.

**Comments:** Again plenty of comments from me regarding the different types of tests

## 5. Report-Driven Checks (Later, Post-build)

A proposed coverage check selects one earlier test instance in `PostBuildChecks` with `Source` (the producer's `Name`). If omitted, exactly one earlier `DotNetTest` with coverage enabled must match; otherwise compilation fails with instructions to name the source. Cross-entry validation rejects missing, ambiguous, forward and coverage-disabled references.

Aggregating across named producers is not part of the first coverage check; the native coverage tab is independent of this policy input.

```yaml
# Future example: DotNetCoverage is not supported in 0.4.0.
PostBuildChecks:
  - Check: DotNetTest
    Name: Unit
    Filter: "Category=Unit"
  - Check: DotNetCoverage
    Name: UnitLineCoverage
    Source: Unit
    Minimum: 80
    TreatAsWarnings: true
```

- `Minimum` is a line coverage percentage in the range 0–100, defaulting to `0` so the check can run without a team-specific threshold. A valid report is still required. Missing, malformed or incompatible current evidence fails the check, subject to `TreatAsWarnings`.
- A later optional `Ratchet` can compare with a baseline in addition to the fixed threshold. Its proposed settings are `BaselineBranch` (PR target or current branch by default) and `Tolerance` (percentage points, default `0`). Use full ref names for lookup.
- Baselines come from the latest fully successful completed run of the same pipeline on the selected branch, using the same artifact, instance, metric and compatible input identity. Do not treat a partially successful run or mismatched producer/filter as a valid baseline.

  If no compatible baseline exists, record that the comparison was skipped and still enforce `Minimum`. A download or permission failure is not proof that no baseline exists; surface it separately.

- A small internal metric helper can share report parsing, threshold/ratchet comparison and structured results. Each policy owns its metric direction and settings: minimum coverage and maximum vulnerable-package count are not the same check with different labels.
- Before shipping ratchets, verify successful-run selection, permissions and retention in Azure DevOps. Document that overlapping runs can evaluate against the same baseline; this is not a serialised organisation-wide policy mechanism.

**Comments:**

## 6. Reports, Logging and Failure Behaviour

The job owns clean per-run directories (read-only path variables) and passes them to checks. Reports include an instance key so multiple checks cannot overwrite one another. Keep package, reports and diagnostics roots separate.

```text
<ArtifactName>_Reports/
  checks/<Phase>/<InstanceKey>/
    result.json
    trx/                      # DotNetTest only
    coverage/                 # DotNetTest when coverage is collected
<ArtifactName>_Diagnostics/
  build.binlog                # opt-in
```

A result record identifies the check and instance, outcome, and report paths; policy checks can include metric, threshold and baseline data. Write records for executed checks, including failures where possible.

The summary lists configured entries and distinguishes passed, warned, failed, skipped and unavailable results. A missing result must never read as a pass. Record the SDK version, available test/coverage counts, and packages actually produced as well.

Use native Azure DevOps Logs, Tests and Code Coverage views and `##vso[task.uploadsummary]`. Create the reports root before checks and publish it on success or failure, even if no check ran. Publish diagnostics only when enabled and a log exists.

Reporting may be unavailable on cancellation or agent loss. Report collection steps must not erase a previous failure or make packages from a failed job eligible for delivery.

A future SARIF-producing check stores SARIF in its own reports folder. Any integration with a SARIF viewer is optional and outside `0.4.0`. No paid extension or external logging service is needed.

**Comments:** yeah that diagnostics info would be good

## 7. Packages and Delivery

The Package phase runs only after a successful compile and no blocking failures in either check phase. Use the same build outputs and configuration, including any required target framework or runtime identifier. Validate declarations that would break the build-once or layout contracts; extra CLI arguments must not override template-owned build, path or output options.

- **`Publish`**: `dotnet publish --no-build`; explicit project, no automatic web project selection. Output: `publish/<Name>.zip` or `publish/<Name>/`.
- **`NuGet`**: `dotnet pack --no-build`. Output: `nuget/<Name>/<PackageId>.<Version>.nupkg`.
- **`Container`**: `dotnet publish --no-build -t:PublishContainer` with `ContainerArchiveOutputPath`. Output: `container/<Name>.tar.gz`.

Package names are unique, path-safe and validated using the explicit or derived name. With no packages configured, no destination runs and no package artifact is published. Versions come from the project or consumer-provided arguments; no version calculation in `0.4.0`.

Container packaging targets Linux images only, uses the .NET SDK rather than Docker, and writes a local tarball rather than pushing it. Pulling the base image may still require network access and credentials. The project's MSBuild properties control the base image, repository, tags and runtime.

Ship only if the minimum SDK and cross-platform fixtures prove build-once packaging and the documented output layout; otherwise defer `Container` to a MINOR release. Dockerfile builds belong in a separate job.

`Destinations` entries select packages by `Name`, defaulting to all compatible packages.

- **`PipelineArtifact`** (`0.4.0`, any package): Runs as the final step of the build job and publishes the selected packages as the `<ArtifactName>` pipeline artifact. It is the implicit destination when the list is empty. At most one entry is allowed, and it is the source every other destination downloads from.
- **Later:** `ContainerRegistry` (container), `NuGetFeed` (NuGet) and `FileShare` (any) run as separate jobs.

Each job-based entry would have a unique `Name`, optional `Pool` and `DependsOn` (other destination names), and optional `AzDOEnvironmentName` for deployment job approvals. Credentials and targets are destination-specific; confirm those fields when each destination ships.

Each delivery job depends on `DotNetBuild_<ArtifactName>` and downloads only the selected paths. A future caller can use the standalone delivery jobs directly with other artifacts.

No package manifest is needed: paths are derived from configuration, a NuGet delivery step can enumerate `.nupkg` files within the known directory, and a registry step can read tags from the image archive. Verify that warning-only builds remain eligible for delivery and that a hard failure or missing artifact does not trigger it.

**Comments:** Yep all sound good

## 8. Implementation and Validation Plan

1. **Build core:** implement `jobs/dotnet_build.yml` and its config schema. Reuse config source and artifact helpers. Use built-in tasks and `pwsh` for cross-platform steps; keep job variables read-only. Verify command-specific input support before choosing `DotNetCoreCLI@2` versus a narrow script for a command. Avoid a wrapper for every CLI subcommand.
2. **Checks wiring:** validate both lists, entry shape, phase allowlists, case-insensitive uniqueness and name syntax at compile time. Each template owns its typed settings. Reject unexpected settings and job-owned inputs. Follow repository schema conventions for type checks, presence checks, actionable errors and `See:` links.
3. **Checks and reporting:** implement internal `checks/dotnetformat.yml` and `checks/dotnettest.yml` with isolated reports and summary results. Publish test evidence to the native tabs. Add job and check docs, update the Build Checks guide and index, and record the user-facing feature under `[Unreleased]` when implemented.
4. **Package and verify:** implement Publish and NuGet packaging, then spike Container. Keep restore/package logic local until another job needs to reuse it. Register end-to-end pipelines through `cicd/` with maintainer involvement.
5. **Extend separately:** ship each later check or destination with its own compatibility and verification work. No implementation or SemVer guarantee for the proposed later settings in this draft.

**Compile fixtures:** both lists empty; valid entries in either or both phases; unknown and wrong-phase checks; ordered expansion; warning forwarding; invalid list/entry types; misspelled settings; reserved parameters; invalid and case-only duplicate names within a phase. Verify the same label in both phases does not collide.

Verify duplicate validation with nested settings present. Add producer/order tests when a dependent check ships.

**Runtime fixtures on Windows and Linux:** verify clean and unformatted source, warning-only pre-build checks allowing compile, restore/build once, two NUnit category filters with distinct titles and reports, multi-project coverage, and missing-collector handling. Verify a post-build warning lets later tests and packaging run.

In isolated failure runs, verify a blocking pre-build check prevents compile and a blocking post-build check prevents packaging, while available reports still publish.

Check package filenames/layout, including SDK/RID compatibility if shipping Container.

Keep required end-to-end status checks green: compile rejects use `InvalidTestCases`; hard-failure and skipped-package assertions that need a genuinely failed build belong in an isolated verification run, not a required PR status pipeline.

**Release contract:** the job name, shipped job parameters and defaults, supported check names/settings/behaviour, and documented artifact paths follow the [Versioning Policy](../docs/developers/reference/versioning-policy.md).

Additive optional checks or settings are MINOR. Removing or renaming a shipped check, changing its defaults, or making its verdict stricter is MAJOR. Internal check files and helper implementations may change without becoming direct consumption points.

**Comments:**

## 9. Open Questions Before Implementation

1. What minimum SDK feature band and Windows/Linux agent images will be supported for `0.4.0`? Verify `.slnx` and Container separately from the basic build path.
2. Is native coverage merging adequate for multiple projects, target frameworks and filtered runs? Add a pinned merger only if fixtures show it is needed.
3. Before coverage ratchets ship, how should baseline permission errors and renamed check instances be surfaced in the UI?
4. Before job-based destinations ship, confirm pool inheritance, registry tooling, credentials and safe retry behaviour for each destination type.
5. **Later, after a first working prototype:** can checks optionally run as their own jobs, so a failed check can be rerun without rebuilding? This would need the build job to publish its compiled output for check jobs to download, per-check job naming and dependencies, and a way to aggregate verdicts before packaging. It is deliberately out of `0.4.0`, where all checks run in the build job.

**Comments:**
