# Design: .NET Build (Iteration 6)

**Status:** Draft, iteration 6. This is the current design and stands on its own. You do not need to read earlier iterations to understand it.

**Previous iterations:** 2 (`dotnet_build_design.md`), 3 (`_v3`), 4 (`_v4`), 5 (`_v5`, with review notes and responses in `_v5_review`). Kept for history only.

**Target:** `jobs/dotnet_build.yml` in `0.4.0`. Destinations and gates follow in later MINOR releases. Their shapes are designed and reserved now (§8, §9).

**Comments:**

## 0. What Changed From Iteration 5

> For readers who followed iteration 5. If you are new to this design, skip to §1. Each change comes from a review note in `dotnet_build_design_v5_review.md`.

- **Package manifest (`manifest.json`)**
  - Iteration 5: A public contract, written at runtime and read by delivery jobs.
  - Iteration 6: **Removed from `0.4.0`.** Templates can't read runtime files, and destinations are declared in the same template call, so every package path is known at compile time. Delivery jobs get the path as a parameter (§6.4).
- **Delivery**
  - Iteration 5: An optional add-on after the build.
  - Iteration 6: **Part of the template's output.** Consumers declare destinations in the same call. It still runs in separate jobs, and the pipeline artifact is the transport between them (§2, §8).
- **`DotNetBuildInjectionSteps`**
  - Iteration 5: Public parameter in `0.4.0`.
  - Iteration 6: **Removed.** It can be added later as a non-breaking MINOR change (§4.1).
- **Testing**
  - Iteration 5: `Project` and `TestRunTitle` per entry.
  - Iteration 6: An optional **`Filter`** per entry, so one project can be split into separate unit and integration runs. Guidance on which tests belong in this job (§4.2, §5.1).
- **Gates**
  - Iteration 5: Model and reserved shape only.
  - Iteration 6: One shared gate template, threshold **and ratchet** checks, and the baseline taken from the last successful run's reports artifact (§9).
- **Mutation testing**
  - Iteration 5: A future tool and gate inside `dotnet_build`.
  - Iteration 6: **A future separate job**, usually in a PR-only pipeline, that uses the same gate template (§9.6).
- **Logs**
  - Iteration 5: Listed by level.
  - Iteration 6: Mapped to where each one appears in Azure DevOps. Native features only (§7.3).
- **`Type`**
  - Iteration 5: Mentioned as the way to extend.
  - Iteration 6: Explained with a worked example (§4.3).

**Comments:**

## 1. Purpose

`jobs/dotnet_build.yml` is a public, behavioural job template. Consumers describe _what_ they want. The template decides _how_ the steps are wired.

**What it does:**

- Restores the solution once.
- Builds it once.
- Runs the selected tools (tests) against that build, each writing reports.
- _(Reserved)_ Runs gates that check those reports against thresholds and the previous run.
- Packages the output in one or more forms (`Publish`, `NuGet`, `Container`).
- Hands the packages over as one pipeline artifact with a predictable layout.
- Uploads reports and a run summary.
- _(Reserved)_ Delivers packages to the destinations the consumer declared.

**Comments:**

## 2. Model

```text
INPUTS              PROCESSING (build job)                    OUTPUTS (all declared in the one template call)
------              ----------------------                    ------------------------------------------------
Codebase      ──►   Prepare (SDK, secrets, feeds)       ──►   Packages ──► pipeline artifact ──► Destinations (reserved)
User options        Restore → Build (once)                    Reports artifact                   one delivery job each:
Tool selection      Tools (tests) → reports                   Diagnostics (opt-in)               ContainerRegistry,
                    [Gates → pass/warn/fail] (reserved)       Run summary                        NuGetFeed, FileShare
                    Package (Publish | NuGet | Container)
```

**Two terms used throughout:**

- **Package:** _what_ is produced. Examples: a publish zip, a `.nupkg`, a container image tarball.
- **Destination:** _where_ a package goes. Examples: a container registry such as Docker Hub, a NuGet feed, a file share.

**Delivery is part of the output.** The consumer declares packages and destinations in the same `dotnet_build` call, and the template produces both. Delivery runs in its own jobs after the build job, because:

- **Build once.** Every destination gets the files that were tested.
- **Each destination can have its own pool, credentials and approvals.**
- **A failed delivery can be re-run on its own** ("Rerun failed jobs"), without rebuilding.

**The pipeline artifact is the transport.** Azure DevOps can only move files between jobs through a pipeline artifact. When a consumer declares destinations, the artifact is how the packages reach the delivery jobs. Consumers don't have to download it themselves, and its retention follows the run's retention policy.

**Build and tests stay in one job.** Re-running is job-level in Azure DevOps, so a failed test re-runs restore and build too. That's an accepted cost. Splitting tests into separate jobs would mean either building again in each job or passing the build output between jobs as an artifact. Running test projects as parallel jobs is a deferred feature (§13).

**Comments:**

## 3. Design Drivers

- **Behavioural templates, narrow public surface**
  - Effect: One public job. Building blocks stay internal.
- **Group inputs into validated objects**
  - Effect: One `DotNetBuildConfig` made of sub-objects, each validated where it is used.
- **Fail fast at compile time**
  - Effect: Schemas check configuration at compile time. Only facts that can't be known until the job runs are checked at runtime.
- **Templates only know compile-time facts**
  - Effect: Anything a template must decide (which jobs exist, which paths to download) is taken from configuration, never from files created during the run. Runtime files are read only by `pwsh` steps inside a job.
- **Protected internal state**
  - Effect: Job variables use list syntax with `readonly: true`.
- **No double-wrapping**
  - Effect: One comprehensive `tasks/dotnet_cli.yml` with a `Command` enum, rather than one wrapper per command. Orchestrating several jobs in one file, as `terraform_gated_deployment` does, is an accepted exception ([Double Wrapping](../docs/developers/explanation/double-wrapping.md)).
- **Cross-platform, open-source, Azure DevOps native**
  - Effect: Built-in tasks plus `pwsh`. No Docker in the build job. No Marketplace extensions required. Logs and metrics use Azure DevOps' own features.
- **Lists of objects from day one (`0.2.0` lesson)**
  - Effect: Use a `Type` discriminator only where entry types map to different steps or jobs.
- **Validate where the data is used (`0.3.1` lesson)**
  - Effect: Shared sub-objects carry their own schemas.
- **Public shape is expensive, internals are cheap**
  - Effect: Design every sub-object for reuse now. Extract an implementation into `utils/` when a second consumer is known. Leave out public parameters until there is a real use for them.
- **Consumers supply the pool**
  - Effect: The templates work on any pool. Where a step needs something on the agent, the template installs it where it can. Otherwise the user doc states what the agent needs.
- **Tools report, gates decide**
  - Effect: A tool never fails the build because of a threshold. Thresholds and ratchets belong to gates (§9).

**Comments:**

## 4. Public Interface

### 4.1 Template Parameters

- **`ArtifactName`**
  - Type: `string`
  - Default: `'DotNetArtifact'`
  - Status: `0.4.0`. Also the job-name suffix.
- **`Condition`**
  - Type: `string`
  - Default: `succeeded()`
  - Status: `0.4.0`
- **`DependsOn`**
  - Type: `object`
  - Default: `[]`
  - Status: `0.4.0`
- **`Pool`**
  - Type: `string`
  - Default: `''`
  - Status: `0.4.0`. The pool for the build job only.
- **`DotNetBuildConfig`**
  - Type: `object`
  - Default: _none (required)_
  - Status: `0.4.0`
- **`Destinations`**
  - Type: `object`
  - Default: `[]`
  - Status: **Reserved.** Added in a later MINOR release (§8). Adding it later with a default of `[]` is non-breaking.

**Removed: `DotNetBuildInjectionSteps`.** There is no known use for it yet. Adding a `stepList` parameter later with a default of `[]` is a non-breaking MINOR change.

**Why `Destinations` is a separate parameter from `DotNetBuildConfig`:**

- `DotNetBuildConfig` is everything the **build job** needs. Its schema validates it at the job level.
- `Destinations` is everything the **delivery jobs** need: pools, service connections, environments. None of it is used by the build job.
- A future `pipelines/dotnet_pipeline.yml` can then pass `Destinations` straight through, unchanged.

This is still open for review (§15) and can change freely until `Destinations` ships.

**Comments:**

### 4.2 `DotNetBuildConfig`

```yaml
DotNetBuildConfig:
  RelativePathToSolution: string # required: .sln, .slnx or .csproj
  BuildConfiguration: string # optional, default 'Release'

  # Preparation
  DotNetSdk: # optional (shared concept: dotnet_sdk)
    Version: string #   default '' → use global.json
    Install: boolean #   default true; false = only check the SDK is present, never install
  Restore: # optional (job-owned)
    NuGetConfigPath: string
    UseLockedMode: boolean #   default false
  ConfigSources: [...] # optional (shared concept, already exists)

  # Tools
  Testing: # optional (shared concept: dotnet_testing)
    CollectCoverage: boolean #   default true
    Projects: #   required when Testing is present
      - Project: string #     required
        TestRunTitle: string #     default 'DotNet Test - <Project>'
        Filter: string #     NEW, optional: passed to 'dotnet test --filter'

  # Gates
  Gates: [...] # RESERVED (§9)

  # Packages
  Packages: # optional; if absent, no artifact is produced
    - Name: string #   optional, default = project file name; must be unique
      Type: Publish | NuGet | Container
      Project: string #   required
      Arguments: string #   optional, extra CLI arguments for this entry
      ZipAfterPublish: boolean #   Publish only, default true

  # Logs
  Diagnostics: # optional
    CollectBinaryLog: boolean #   default false
```

**Rules for the shape:**

- **Leaving out a sub-object switches that behaviour off.** There are no `RunTests` or `EnablePublish` flags.
- **`Type` names describe the output, not the tool.** The type is `Container`, not `Docker`.
- **No Docker-only fields** (`Dockerfile`, `BuildContext`). Dockerfile builds are not part of this template (§13).
- **New `Type` values and new optional fields are MINOR changes.** Removing or renaming them is MAJOR.

**`Packages[].Name`** identifies each package in the artifact folders, and destinations refer to packages by this name (§8). It defaults to the project file name, so most consumers never set it. Set it when the same project is packaged twice, for example `Publish` and `Container`.

**`Testing.Projects[].Filter`** lets one test project run as several separately titled steps. For example, `Category=Unit` and `Category=Integration` from the same project appear as two test runs, so it's clear which group failed.

**Comments:**

### 4.3 How `Type` Works

`Type` appears on each entry of three lists: `Packages`, `Destinations` (reserved) and `Gates` (reserved). It says what kind of entry it is. At compile time:

- **The schema** uses it to check which other fields are allowed and required. For example, `ZipAfterPublish` is allowed only when `Type: Publish`.
- **The template** uses it to choose what to emit for that entry. For example, in the packaging loop:

```yaml
- ${{ each package in parameters.DotNetBuildConfig.Packages }}:
    - ${{ if eq(package.Type, 'Publish') }}:
        - template: /tasks/dotnet_cli.yml # Command: publish
    - ${{ if eq(package.Type, 'NuGet') }}:
        - template: /tasks/dotnet_cli.yml # Command: pack
    - ${{ if eq(package.Type, 'Container') }}:
        - template: /tasks/dotnet_cli.yml # Command: publish, -t:PublishContainer
```

**Adding a new kind** (for example a new destination) means adding a new `Type` value, its fields in the schema, and one more `if` branch. Existing consumers' configuration doesn't change, which is why it is a MINOR change. `ConfigSources` already works this way.

**Comments:**

### 4.4 Example

```yaml
- template: jobs/dotnet_build.yml@AzDOPipelineTemplates
  parameters:
    ArtifactName: "MyApi"
    DotNetBuildConfig:
      RelativePathToSolution: "MyApi.sln"
      Testing:
        Projects:
          - Project: "tests/MyApi.Tests/MyApi.Tests.csproj"
            TestRunTitle: "Unit Tests"
            Filter: "Category=Unit"
          - Project: "tests/MyApi.Tests/MyApi.Tests.csproj"
            TestRunTitle: "Integration Tests"
            Filter: "Category=Integration"
      Packages:
        - Type: Publish
          Project: "src/MyApi/MyApi.csproj"
        - Name: "MyApi.Image" # needed: same project packaged twice
          Type: Container
          Project: "src/MyApi/MyApi.csproj"
          Arguments: "-p:ContainerRepository=myorg/myapi"
```

**Comments:**

## 5. Processing (Fixed Order)

0. **Schema validation of job-owned fields**
   - Implementation: `schemas/dotnet_build_config.yml`
   - Runs when: Always, at compile time
1. **Check out `self` (explicit `path`), then `download: none`**
   - Implementation: —
   - Runs when: Always
2. **Provide the SDK (install or check)**
   - Implementation: `utils/dotnet_sdk_task_list.yml`
   - Runs when: Always
3. **Load secrets**
   - Implementation: `utils/config_sources_task_list.yml`
   - Runs when: `ConfigSources` is present
4. **Authenticate to feeds**
   - Implementation: `tasks/nuget_authenticate.yml`
   - Runs when: Always
5. **`DotNet Restore`**
   - Implementation: `tasks/dotnet_cli.yml`
   - Runs when: Always
6. **`DotNet Build` (`--no-restore`, plus `-bl` if diagnostics are on)**
   - Implementation: `tasks/dotnet_cli.yml`
   - Runs when: Always
7. **Tools: Testing (one step per entry, `--no-build`, then publish coverage)**
   - Implementation: `utils/dotnet_test_task_list.yml`
   - Runs when: `Testing` is present
8. **_(reserved)_ Gates**
   - Implementation: `utils/gate_task_list.yml` (§9)
   - Runs when: `Gates` is present
9. **Package each entry into `$(DotNetPackagesDirectory)/<type>/<Name>`**
   - Implementation: `tasks/dotnet_cli.yml` (§6.1)
   - Runs when: `Packages` is present
10. **Upload `<ArtifactName>`**
    - Implementation: `tasks/publish_pipeline_artifact.yml`
    - Runs when: `Packages` is present
11. **Upload `<ArtifactName>_Reports` (`succeededOrFailed()`)**
    - Implementation: `tasks/publish_pipeline_artifact.yml`
    - Runs when: Always (§7)
12. **Upload `<ArtifactName>_Diagnostics` (`succeededOrFailed()`)**
    - Implementation: `tasks/publish_pipeline_artifact.yml`
    - Runs when: `CollectBinaryLog` is true
13. **Upload the run summary (`succeededOrFailed()`)**
    - Implementation: Inline `pwsh` + `##vso[task.uploadsummary]`
    - Runs when: Always

**Failure behaviour:**

- A failed build, failed test or failing `Enforce` gate stops packaging. No artifact is produced from untested code.
- Test results, reports, diagnostics and the summary are still uploaded when a step fails.
- The first failing test entry stops any later entries.

**Comments:**

### 5.1 Which Tests Belong in This Job

Based on input from a Lead Automation Tester:

- **Build first, then test with `--no-build`.** There's no point running tests if the app doesn't build, and it keeps "build once" true.
- **Unit tests:** yes.
- **Integration and API tests that host the app in-process** (for example with `WebApplicationFactory`): yes. List them as separate entries, or use `Filter`, so they show as separate test runs.
- **End-to-end tests that need a deployed app:** no. They belong in a later stage, after deployment.
- **UI tests** (for example Playwright): no, unless the test project starts everything it needs itself. Otherwise they belong in a later stage.
- **Mutation testing (Stryker):** no. It is slow on large apps and usually runs in a separate, PR-only pipeline (§9.6).
- **Test frameworks:** the template calls `dotnet test`, which works with any framework that has a test adapter (NUnit, xUnit, MSTest). There is no framework-specific code. Fixtures use NUnit, because most of the estate uses it.

**Comments:**

## 6. Packages and the Artifact

### 6.1 Package Types

- **`Publish`**
  - Command (`--no-build`, same configuration): `dotnet publish` (`publishWebProjects: false`)
  - Output in the artifact: `publish/<Name>.zip`, or `publish/<Name>/`
  - Needs: —
- **`NuGet`**
  - Command (`--no-build`, same configuration): `dotnet pack`
  - Output in the artifact: `nuget/<Name>/<PackageId>.<Version>.nupkg`
  - Needs: A version from the codebase or `Arguments` (§6.5)
- **`Container`**
  - Command (`--no-build`, same configuration): `dotnet publish -t:PublishContainer -p:ContainerArchiveOutputPath=...`
  - Output in the artifact: `container/<Name>.tar.gz`
  - Needs: .NET 8+ SDK. No Docker. No registry access during the build

**Comments:**

### 6.2 `Container` Specifics

- **The image is built from the same tested build output, by the .NET SDK's built-in container support.** No Dockerfile and no Docker are involved. It is written as a tarball and never pushed from the build job. Pushing is a destination (§8).
- Image settings use the SDK's MSBuild properties, either in the project file or through `Arguments`:
  - `ContainerRepository`
  - `ContainerImageTags`
  - `ContainerBaseImage`
  - `ContainerFamily`
  - `ContainerRuntimeIdentifier`
- The template adds only `ContainerArchiveOutputPath`, so the tarball lands in a known location.
- **Linux images are the supported target.** Windows-based and multi-architecture images are not supported in v1.
- **Artifact size:** image tarballs make the artifact much larger. The user doc should point to retention settings.
- The SDK behaviour above is written from the SDK documentation, not from running it. It must be confirmed by a test fixture (§14).

**Comments:**

### 6.3 Layout

```text
<ArtifactName>/
  publish/<Name>.zip            or  publish/<Name>/
  nuget/<Name>/<PackageId>.<Version>.nupkg
  container/<Name>.tar.gz
```

- **One folder per package type, then one entry per package `Name`.** Only the folders for the types actually used are created.
- **Every path can be worked out from the configuration alone.** The only exception is the `.nupkg` file name, which contains a version, so each NuGet package gets its own folder: `nuget/<Name>/`.
- **One artifact for all packages,** so there is a single thing to reference and keep.

**Comments:**

### 6.4 No Manifest in `0.4.0`

Iteration 5 proposed a `manifest.json` written at runtime. It is removed because:

- **Templates can't read it.** Templates are expanded at compile time, before the manifest exists.
- **It isn't needed.** Destinations are declared in the same template call as the packages, so the template already knows each package's name, type and path at compile time (§6.3). It passes the path to each delivery job as a parameter.
- **Runtime-only facts stay inside the job that needs them.** The two facts known only at runtime are handled by a small `pwsh` step inside the delivery job:
  - The `.nupkg` file name: the job pushes every `*.nupkg` in `nuget/<Name>/`.
  - Container tags: the push tool reads them from the tarball's own image manifest.

A manifest can be added later as a MINOR change if consumers outside this repository ask for one.

**Comments:**

### 6.5 Versions of Produced Packages

The template does not calculate versions in v1. Versions come from the codebase (`Directory.Build.props` / `<Version>`, `ContainerImageTags`), or are passed through `Arguments`. A shared version-calculation util (for example GitVersion pinned as a `dotnet tool`) is a candidate for a later release.

**Comments:**

## 7. Reports and Logs

### 7.1 Reports (Always On)

**Mechanism:**

- The job defines `DotNetReportsDirectory`, a read-only variable.
- Every tool util takes a `ReportsDirectory` parameter, writes to `<ReportsDirectory>/<tool>/`, and also publishes to its native Azure DevOps tab.
- One final step uploads the directory as `<ArtifactName>_Reports`.
- Adding a tool means adding a util. The job doesn't change.

**Reports produced in `0.4.0`:**

- **Test results (`.trx`)**
  - Native destination: Tests tab (`DotNetCoreCLI@2` test publishing)
  - Reports artifact: `testing/trx/`
- **Coverage (Cobertura)**
  - Native destination: Code Coverage tab (`PublishCodeCoverageResults@2`)
  - Reports artifact: `testing/coverage/`

**Coverage across several test projects** uses the built-in task. ReportGenerator is added only if the multi-project fixture shows the merged numbers are wrong (§14).

**Always on.** The upload happens on every run, including failed runs. It is also what gates use as a baseline in later runs (§9.4). If storage becomes an issue later, an opt-out can be added as a MINOR change.

**Comments:**

### 7.2 SARIF and the "Scans Tab"

- **What SARIF is:** a standard file format for findings from static analysis and security tools: Roslyn analysers, CodeQL, Snyk, Trivy and others.
- **The gap in Azure DevOps:** it has a Tests tab and a Code Coverage tab built in, but no built-in tab for SARIF.
- **The extension:** Microsoft DevLabs publishes a free extension, "SARIF SAST Scans Tab", that adds one. It reads SARIF files from a build artifact named `CodeAnalysisLogs`. The repository already relies on a free DevLabs extension for `TerraformInstaller@1`, so there is a precedent.
- **Recommendation:**
  - Templates always write SARIF into the reports artifact. Nothing depends on the extension.
  - Optionally, they also publish a `CodeAnalysisLogs` copy, so organisations that have installed the extension get the tab for free.
  - This becomes relevant only when the first SARIF-producing tool arrives. Nothing in `0.4.0` produces SARIF.

**Comments:**

### 7.3 Logs (Azure DevOps Native Only)

- **Step logs**
  - Content: Output of every step, with stable display names: `DotNet Restore`, `DotNet Build`, `DotNet Test - <title>`, `DotNet Publish - <Name>`, `DotNet Pack - <Name>`, `DotNet Container - <Name>`
  - Where it appears: The run's **Logs** view. Kept for as long as the run is retained.
  - Default: Always on
- **Run summary**
  - Content: SDK version, test counts, coverage, gate results (when gates exist), packages produced
  - Where it appears: The run's **Extensions** tab (via `##vso[task.uploadsummary]`)
  - Default: Always on
- **Test and coverage history**
  - Content: Pass rates, failing and flaky tests, and duration across runs
  - Where it appears: The **Tests** tab and **Test Analytics** for the pipeline. Nothing extra is needed; it comes from publishing test results.
  - Default: Always on
- **Diagnostics**
  - Content: MSBuild binary log, as `<ArtifactName>_Diagnostics`
  - Where it appears: Run artifacts
  - Default: Off. Binary logs can contain secrets, and the user doc will warn about this

**Out of scope:** sending logs to external systems such as Elastic.

**Comments:**

## 8. Destinations (Reserved Shape, Delivered in Later MINOR Releases)

### 8.1 Shape

```yaml
Destinations:
  - Name: string # required, unique; used in job names
    Type: ContainerRegistry | FileShare | NuGetFeed
    Packages: [string] # optional: package Names to deliver; default = every package compatible with the Type
    Pool: string # optional: defaults to the build Pool
    AzDOEnvironmentName: string # optional: when set, the job becomes a deployment job, so environment approvals and checks apply
    DependsOn: [string] # optional: other destination Names (e.g. push the image only after the file share copy)
    # Type-specific fields:
    ServiceConnection: string # ContainerRegistry, NuGetFeed (external)
    Repository: string # ContainerRegistry: optional override of the build-time repository
    Tags: [string] # ContainerRegistry: optional extra tags
    Feed: string # NuGetFeed: Azure Artifacts feed name or external feed URL
    TargetPath: string # FileShare: UNC or mounted path; supports $(Build.BuildNumber)
```

**Comments:**

### 8.2 How It Expands

For each destination, `jobs/dotnet_build.yml` emits one job after the build job:

```text
DotNetBuild_<ArtifactName>
  └─► DotNetDeliver_<ArtifactName>_<DestinationName>   (job, or deployment job if AzDOEnvironmentName is set)
```

**How each delivery job is built:**

- The job body is the **standalone public job template** for that `Type`:
  - `jobs/container_registry_push.yml`
  - `jobs/file_share_copy.yml`
  - `jobs/nuget_feed_push.yml`
- `dotnet_build` passes each one, at compile time, the artifact name and the path of each package inside it (from §6.3). The delivery job downloads only those paths (`DownloadPipelineArtifact@2` with item patterns).
- Because each delivery job takes plain parameters, teams using the "salad bar" can call it directly for artifacts that weren't produced by `dotnet_build`.
- **Compatibility is checked at compile time.** A destination's `Packages` must name packages whose `Type` is compatible: `ContainerRegistry` ↔ `Container`, `NuGetFeed` ↔ `NuGet`, `FileShare` ↔ any.

**Precedent:** this composition is how `terraform_gated_deployment` combines plan, verify and apply jobs. It is orchestration, not double-wrapping.

**Comments:**

### 8.3 Pools and Agent Needs

Consumers choose the pool for each destination. The templates keep agent requirements to a minimum:

- **`ContainerRegistry`**
  - Agent needs: None beyond network access to the registry
  - Template behaviour: Installs a pinned push tool (internal choice, §8.4). No Docker required
- **`FileShare`**
  - Agent needs: **Network access to the share** (only the consumer can provide this)
  - Template behaviour: `pwsh` `Copy-Item`. The user doc states that Linux agents need the share mounted
- **`NuGetFeed`**
  - Agent needs: None
  - Template behaviour: Uses the `dotnet` CLI via `utils/dotnet_sdk_task_list.yml`, and `NuGetAuthenticate@1`

**Comments:**

### 8.4 Decisions Hidden Behind the Shape

The public shape doesn't change whichever way these are decided, so they can be settled when each delivery job is built, and changed later as PATCH releases:

- **Push tool:** for example `crane`, `oras`, or `docker load` + `docker push`.
- **Registry:** Docker Hub, ACR, or anything else reachable through a Docker Registry service connection.
- **NuGet feed:** Azure Artifacts, nuget.org, or another external feed. `Feed` and `ServiceConnection` cover all of them.
- **File share copy method.**

**Comments:**

### 8.5 Adding a New Destination Type

1. Build the standalone public job, taking the artifact name and package paths as parameters.
2. Add the new `Type` value and its fields to the destinations schema.
3. Add the compatibility rule.

All three are MINOR changes.

**Comments:**

## 9. Gates (Reserved, Shape and Mechanism Designed)

### 9.1 Model

- **Tools produce reports. Gates read reports and decide.** A tool never fails the build because of a threshold. Testing fails only because a test failed.
- **Every gate does the same three things:**
  1. **Read** one metric from a report in `<ReportsDirectory>` (for example line coverage from Cobertura).
  2. **Compare** it with a fixed minimum (threshold check).
  3. **Optionally compare** it with the same metric from the last successful run (ratchet check), so the metric can't go down over time.
- **Every gate writes its result** to `<ReportsDirectory>/gates/<Type>.json`. That file is uploaded with the reports artifact, and becomes the baseline for the next run.

Ratcheting guards against gradual decline, for example AI-generated code that passes the tests but slowly lowers coverage.

**Comments:**

### 9.2 Reserved Shape

```yaml
Gates:
  - Type: Coverage | VulnerablePackages # more Types later
    Mode: Enforce | Warn # Enforce fails the job; Warn = "succeeded with issues"
    Minimum: number # optional: fixed threshold (e.g. 80 for 80% line coverage)
    Ratchet: # optional: compare with the last successful run
      BaselineBranch: string #   default: PR target branch on PR builds, otherwise the current branch
      Tolerance: number #   default 0: how far the metric may drop before the gate trips
```

At least one of `Minimum` or `Ratchet` is required. `Warn` lets teams adopt a gate gradually before enforcing it.

**Comments:**

### 9.3 One Shared Gate Template

`utils/gate_task_list.yml` (internal) emits the gate steps for any `Type`:

- Each `Type` provides a small **metric reader**: a `pwsh` function that turns a report into one number. This is the only part that differs between gate types.
- The comparison, the ratchet lookup, the result file, the summary entry and the pass/warn/fail outcome are the same for every type.
- Because it reads only from `<ReportsDirectory>`, any job that follows the reports contract can use it, including future jobs for other languages and the future mutation-testing job (§9.6).

**Comments:**

### 9.4 Where the Baseline Comes From

The baseline is the gate result file from the **reports artifact of the last successful run of the same pipeline on `BaselineBranch`**. It is downloaded with `DownloadPipelineArtifact@2` (`source: specific`, the current pipeline's definition ID, `runVersion: latestFromBranch`).

**Why not a pipeline variable that persists?** Azure DevOps doesn't support one natively:

- A variable set during a run (`##vso[task.setvariable]`) is lost when the run ends.
- Updating a variable group through the REST API would work, but the build service would need extra permissions on the library, and runs that overlap could overwrite each other's values.

**Why the previous run's reports artifact works better:**

- It needs no extra permissions.
- Consumers can't change it by hand.
- It keeps a history of the metric for as long as runs are retained.

**When there is no baseline** (the first run, or after retention removes it): the ratchet check is skipped with a warning in the run summary. The threshold check still runs.

**Comments:**

### 9.5 Where Gates Run

- After tools and before packaging (§5, step 8).
- A failing `Enforce` gate stops packaging, so nothing that fails a gate is produced.
- Every gate result appears in the run summary: metric, threshold, baseline and outcome.

**Comments:**

### 9.6 Mutation Testing

Mutation testing (Stryker) is **not** part of `dotnet_build`. It is slow on large apps, and teams usually run it in a separate pipeline triggered only by PRs, so it doesn't delay a redeploy of `main`. It will be a future separate job that writes a report and uses the same gate template with a `MutationScore` type.

**Comments:**

### 9.7 Still Needs Deciding Before Gates Ship

- Whether the organisation can set gates that every pipeline must use.
- Whether there are organisation-wide default thresholds.
- Which gate `Type` ships first (`Coverage` is the proposal).

**Comments:**

## 10. Building Blocks

**New in `0.4.0`:**

- **`tasks/dotnet_cli.yml`:** Internal. `DotNetCoreCLI@2` with `Command` set to restore, build, test, publish, pack or custom.
- **`tasks/dotnet_installer.yml`:** Internal. `UseDotNet@2`, using `useGlobalJson` or a version.
- **`tasks/nuget_authenticate.yml`:** Internal. `NuGetAuthenticate@1`.
- **`tasks/publish_code_coverage.yml`:** Internal. `PublishCodeCoverageResults@2`.
- **`utils/dotnet_sdk_task_list.yml`:** Shared concept. With `schemas/dotnet_sdk.yml` and `docs/definition_docs/shared/dotnet_sdk.md`.
- **`utils/dotnet_test_task_list.yml`:** Shared concept. With `schemas/dotnet_testing.yml` and `docs/definition_docs/shared/dotnet_testing.md`.

**Reused:**

- `utils/config_sources_task_list.yml` (unchanged)
- `tasks/powershell.yml`
- `tasks/publish_pipeline_artifact.yml`

Restore and packaging stay inline in the job. They move to `utils/` when a second consuming job is built, which is an internal (PATCH) change.

**Later:**

- The three delivery jobs, and `schemas/destinations.yml`.
- `tasks/download_pipeline_artifact.yml` gains item-pattern and specific-run support (an internal change), used by delivery jobs and gate baselines.
- `utils/gate_task_list.yml`, `schemas/gates.yml` and `docs/definition_docs/shared/gates.md`.
- `docs/definition_docs/shared/destinations.md`.

**Comments:**

## 11. Validation

**Job schema (`0.4.0`, `schemas/dotnet_build_config.yml`) validates:**

- `RelativePathToSolution` is required.
- Scalar fields are scalars.
- `Restore` and `Diagnostics` have the right shape.
- `Packages` is a non-empty list of objects.
- `Type` is one of `Publish`, `NuGet` or `Container`.
- `Project` is required.
- `ZipAfterPublish` is used only with `Publish`.
- `Packages[].Name` is unique, and is a scalar when supplied.

**Shared schemas** (`dotnet_sdk`, `dotnet_testing`, `config_sources`) validate their own sub-objects. `dotnet_testing` now also checks that `Filter` is a scalar when supplied.

**Destinations schema (later):**

- `Name` is required and unique.
- `Type` is an allowed value.
- Type-specific required fields are present.
- Every name in `Packages` exists in `DotNetBuildConfig.Packages`.
- Package and destination types are compatible.

This is the first schema that checks one object against another. Its pattern will be added to the [Schema Validation](../docs/developers/reference/schema-validation.md) catalogue.

**Gates schema (later):** `Type` and `Mode` are allowed values, and at least one of `Minimum` or `Ratchet` is present.

**All schemas follow the repository conventions:**

- Use `startsWith` for type checks.
- Use presence-gating for optional fields.
- Use the `'<ArtifactName>' artifact error:` or `Invalid <Concept>:` error prefixes.
- End with `See:` links.

**Comments:**

## 12. Public Contract on `0.4.0` Release

- The job name `DotNetBuild_<ArtifactName>`.
- All parameter and field names, and their defaults.
- The artifact layout (§6.3).
- The reports artifact `<ArtifactName>_Reports` and its tool sub-folders (`testing/trx/`, `testing/coverage/`).
- The diagnostics artifact `<ArtifactName>_Diagnostics` (`build.binlog`).
- **Reserved names:** `Destinations`, `Gates`, the `gates/` reports sub-folder, and the delivery job name pattern `DotNetDeliver_<ArtifactName>_<DestinationName>`. They are documented as "coming", so nobody builds anything that conflicts with them.

**Comments:**

## 13. Not Included

**Not part of this template at all:**

- **Dockerfile builds.** If a repository needs a Dockerfile, it uses a different (language-agnostic) job, not `dotnet_build`. A template can only control what happens around a Dockerfile, not inside it.
- **Mutation testing.** A future separate job (§9.6).
- **End-to-end and UI tests** that need a deployed app or a browser server. They belong in a later stage (§5.1).
- Tests that need an authenticated Azure identity.
- Deployment to App Service, Functions, AKS and other hosts.
- Security scanning (dependency, SAST, image scanning, including Snyk) as separate jobs.
- .NET Framework (Windows-only MSBuild/VSTest).
- On-premises targets.
- dacpac/sqlpackage, EF migrations.
- SBOM.
- Code signing.
- Config-file substitution at build time.
- Sending logs to external systems such as Elastic.

**Reserved shape, delivered later:**

- Destinations: container registry, file share, NuGet feed.
- Gates: coverage first, then vulnerable packages.
- A complete pipeline template, `pipelines/dotnet_pipeline.yml`.

**Deferred features:**

- An injection-steps parameter (`DotNetBuildInjectionSteps`).
- A package manifest (`manifest.json`).
- Running test entries as parallel jobs.
- Running every test entry after one fails.
- Calculating versions or stamping a build number.
- NuGet caching (`Cache@2` keyed on the hash of `packages.lock.json`).
- Further tools (format checks via `dotnet format --verify-no-changes`, package audit).
- Microsoft.Testing.Platform as a test runner (v1 assumes VSTest).
- Windows and multi-architecture images.
- Extracting `JobsVariableMappings` into a shared util.

**Release timing:** `Type: Container` ships in `0.4.0` only if the research and fixture in §14 support it. Otherwise it ships later as a MINOR release. The artifact layout already allows for it.

**Comments:**

## 14. Research and Verification Before Release

1. **Docker usage across the org.** Search code for `Dockerfile`, `Docker@2`, `PublishContainer`, `FROM mcr.microsoft.com/dotnet`, and sort each Dockerfile into:
   - **Thin:** builds with the `dotnet` CLI, then copies the output into a runtime image.
   - **Builds everything, plain .NET:** can move to `dotnet_build` + `Type: Container`.
   - **Builds everything, needs OS packages or tools:** demand for a separate Dockerfile job.
2. **Container fixture:**
   - `PublishContainer` works with `--no-build`, and with the runtime identifier used at build time.
   - A tarball is produced on Windows and Linux agents.
   - `ContainerArchiveOutputPath` behaves as expected on the minimum SDK (8.0.1xx).
3. **Multi-project coverage fixture**, to decide whether ReportGenerator is needed.
4. **Test fixture with `Filter`:** one NUnit project split into two titled runs by category.
5. **Gate baseline spike (before gates ship):** confirm `DownloadPipelineArtifact@2` can fetch the reports artifact from the latest successful run on another branch using `System.AccessToken` with default permissions.
6. **Test pipelines registered** through `cicd/` for the new `tests/jobs/dotnet_build/*_test.yml` fixtures. This is a maintainer step.

**Comments:**

## 15. Open Questions

1. **`Destinations` placement:** keep it as a separate parameter (§4.1), or move it inside `DotNetBuildConfig`? It can change freely until `Destinations` ships.
2. **Delivering from inside the build job:** is there a real case for delivering without a separate job (for example a small team that doesn't need separate pools or approvals)? It would lose separate re-runs and credentials, so it isn't proposed.
3. **Destinations' default `Pool`:** should it default to the build `Pool`, as proposed, or have no default so consumers must choose?
4. **Gates:** organisation-mandated gates and default thresholds (§9.7).
5. **Shared definition docs:** final names, and whether to split the `docs/definition_docs/shared/` folder as it grows.

**Comments:**
