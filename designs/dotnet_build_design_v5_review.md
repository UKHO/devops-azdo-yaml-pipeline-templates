# Design: .NET Build (Iteration 5, Review Copy)

**Status:** Draft, iteration 5. Review copy of `dotnet_build_design_v5.md` with all tables converted to lists and a `**Comments:**` section after each section for review notes. Existing `SRJ:` notes from the original have been moved, word for word, into the matching `**Comments:**` section.

**Previous iterations:** 2 (`dotnet_build_design.md`), 3 (`_v3`), 4 (`_v4`). Kept for history only.

**Target:** `jobs/dotnet_build.yml` in `0.4.0`. Destinations and gates follow in later MINOR releases. Their shapes are designed and reserved now (§8, §9).

**Comments:**

## 0. What Changed From Iteration 4

> For readers who followed iteration 4. If you are new to this design, skip to §1. Every decision listed here is fully described in the section it points to.

- **Container hand-off**
  - Iteration 4: The image tarball goes "in the artifact".
  - Iteration 5: A defined **artifact hand-off contract**: one folder per package type, a **package manifest**, and filtered downloads for consumers (§6).
- **Destinations**
  - Iteration 4: A list of future standalone jobs.
  - Iteration 5: **Optional destinations** declared on `dotnet_build` itself. The template expands them into separate jobs after the build job, following the same pattern as `terraform_gated_deployment`. Each destination type is also a standalone public job (§8).
- **Push tool, feeds, registries, shares**
  - Iteration 4: Open questions.
  - Iteration 5: Resolved as **internal implementation choices** behind a stable destination shape (§8.4).
- **Gates**
  - Iteration 4: "Coverage thresholds" in a deferred list.
  - Iteration 5: A first **gate model**: tools produce reports, gates evaluate reports. The shape is reserved. A full design will follow later (§9).
- **Dockerfiles**
  - Iteration 4: Discussed inside this design.
  - Iteration 5: **Out of this template entirely.** Dockerfile builds belong to a different job (§13).
- **Reports artifact**
  - Iteration 4: Open question (always on, or opt-out?).
  - Iteration 5: **Always on** (§7).
- **Agent pools**
  - Iteration 4: Open question.
  - Iteration 5: **Any pool, supplied by the consumer.** Templates stay OS-independent. Destinations state what their pool needs (§8.3).
- **Scans tab**
  - Iteration 4: Open question.
  - Iteration 5: Explained, and turned into a recommendation (§7.2).
- **Mutation testing**
  - Iteration 4: Out of scope.
  - Iteration 5: Deferred: fits as a tool plus a gate (§9).

**Comments:**

## 1. Purpose

`jobs/dotnet_build.yml` is a public, behavioural job template. Consumers describe _what_ they want. The template decides _how_ the steps are wired.

**What it does:**

- Restores the solution once.
- Builds it once.
- Runs the selected tools (tests) against that build.
- Packages the output in one or more forms (`Publish`, `NuGet`, `Container`).
- Hands the packages over as a pipeline artifact with a manifest.
- Uploads reports and logs.

**Optionally**, it then delivers the packages to declared destinations, each in its own job.

**Comments:**

- SRJ (on "Runs the selected tools"): OK hopefully I will read out in the design about how we'll handle all of the different tools... What would be good is defining a gate to those tools that the pipeline checks the results on in order to stop any problems coming up. Plus there is the thing about ratchet'ing on the gate, meaning the pipeline almost checking the last pipeline run for what the percentage of pass rate is and making sure the current metric is getting less or not... Wonder if such a value could be stored in a AzDO Pipeline Variable that persist and that way we can track the metrics overtime... This would be useful at making sure the AI generated code is getting properly built and not degrading
  - **Response (acted on in v6 §9):** Gates are now a defined concept with one small shared template (`utils/gate_task_list.yml`) that compares a metric against a threshold and, optionally, against a baseline (ratcheting). On storing the metric in a pipeline variable that persists: Azure DevOps can't do that natively. A variable set during a run (`##vso[task.setvariable]`) is lost when the run ends. Updating a variable group through the REST API would work, but it needs extra permissions for the build service, and runs that overlap can overwrite each other's values. v6 takes the baseline from the **reports artifact of the last successful run on the target branch** instead (`DownloadPipelineArtifact@2` with `runVersion: latestFromBranch`). That needs no extra permissions, can't be changed by a consumer, and keeps a history of the metric across runs for as long as runs are retained.
- SRJ (on "Packages the output"): Yep, totally required... I'm starting to understand there is a difference in packaging of the code and then where to send that package of code. For example, container could be sent to DockerHub or it could just be put into an pipeline artifact.
  - **Response (acted on in v6 §2, §6, §8):** Agreed, and v6 is built around that split. A **package** is _what_ is produced (`Publish`, `NuGet`, `Container`). A **destination** is _where_ it goes (`ContainerRegistry`, `NuGetFeed`, `FileShare`). The pipeline artifact is the hand-off between the two.
- SRJ (on "Hands the packages over as a pipeline artifact with a manifest"): OK I will need to understand what that manifest is... Is it going to only be read by humans? Is AI going to use it? Is the follow on jobs going to read it... Any files that are created like that, the pipeline templates cannot read them, a lot of the functionality behind the templates is done at compile time and the concept of runtime behaviour isn't too much there except for some powershell scripts for the terraform deploy
  - **Response (acted on in v6 §6.4):** You're right that templates can't read the manifest, because it only exists at runtime. Destinations are declared in the same template call as the packages, so the template already knows every package's name, type and path at compile time. That makes the manifest unnecessary. **v6 removes `manifest.json` from `0.4.0`.** Instead the artifact layout is fully predictable from the configuration, and each delivery job is given the path of the file it needs as a compile-time parameter. The only facts that are known only at runtime (the NuGet version in the file name, and container tags) are handled inside the delivery job by a small `pwsh` step that reads the file itself. A manifest can be added later as a MINOR change if consumers outside this repository ask for one.
- SRJ (on "Uploads reports and logs"): OK the reports from the tools can be uploaded but on the logs themselves, not sure where they would be logged... I did want to see whether I could post the logs on pipeline runs out to elastic but honestly that probably isn't something I could do... I probably want to see if I can use Azure DevOps native tools if possible...
  - **Response (acted on in v6 §7.3):** v6 uses Azure DevOps native features only. Step logs stay in the run and follow its retention policy. The run summary appears on the run's **Extensions** tab. Test results and coverage appear on the **Tests** and **Code Coverage** tabs. Test trends across runs are available through **Test Analytics** and the Analytics views. Sending logs to Elastic is out of scope.
- SRJ (on "Optionally, it then delivers"): Hmm... I am not entirely sure that we can have the Delivery being separate jobs... I think that is PART of the output... That we need to delivery them as part of the output... If they are in a different job, not enitrely sure if that is enough... As some people may NOT want to have the artifact in the pipeline, they'll want to send it straight to its destination. So output has the delivery inside of it...
  - **Response (acted on in v6 §2, §8):** v6 treats delivery as **part of the template's output**. Consumers declare destinations in the same `dotnet_build` call, and the template produces the delivery for them. _Where_ the delivery runs is an implementation detail: it runs in separate jobs, for the reasons in §2 (its own pool, credentials and approvals, and re-running without rebuilding). On "send it straight to its destination, without the artifact": Azure DevOps can only move files between jobs through a pipeline artifact, so the artifact is the transport and can't be removed. v6 makes this explicit. Consumers don't have to use the artifact themselves, and its retention follows the run. Delivering from inside the build job is listed as an open question (v6 §15), in case a real need comes up.

## 2. Model

```text
INPUTS              PROCESSING (build job)                     OUTPUTS                      DELIVERY (separate jobs)
------              ----------------------                     -------                      ------------------------
Codebase      ──►   Prepare (SDK, secrets, feeds)        ──►   Artifact + manifest   ──►    Destinations (optional):
User options        Restore → Build (once)                     Reports artifact             ContainerRegistry, FileShare,
Tool selection      Tools → reports                            Diagnostics (opt-in)         NuGetFeed, ...
                    [Gates → pass/warn/fail]  (reserved)       Logs + run summary
                    Package (Publish | NuGet | Container)
```

**Rule:** the build job's only destination is the pipeline artifact. Everything else is delivered by a separate job that consumes that artifact. This keeps three things true:

- **Build once.** Every destination gets the tested files.
- **Each destination can have its own pool, credentials and approval.**
- **A failed delivery can be re-run without rebuilding.**

**Comments:**

- SRJ (on the diagram): OK I like that text diagram as it states all of the things involved...
  - **Response:** Kept in v6 and extended to show the delivery side.
- SRJ (on "Build once"): That sounds good...
- SRJ (on "own pool, credentials and approval"): That is an interesting point... Breaking out to multiple jobs means that I can have those things correctly assigned out...
- SRJ (on "re-run without rebuilding"): OK this is probably the biggest argument in all of this... The rerunning of the correct jobs... Like if the testing tools for the dotnet_build have failures then the whole build would be retriggered... So I need to understand how much I value that rerunning of sub jobs... It would probably create a very indepth stage with a lot of different jobs relating to the dotnet build... I'm also wondering are the tests meant to be ran before the build... what are the different level of tests that may run, for example. possible that unit tests are ran before a build then the integration tests are ran after the build...
  - **Response (acted on in v6 §2, §5):** Re-running is job-level in Azure DevOps ("Rerun failed jobs"). Delivery jobs are separate, so a failed push re-runs on its own. Build and tests stay in **one** job in v6. Splitting tests into their own jobs would mean either building again in each job (breaking "build once") or passing the build output between jobs as an artifact (slow and large). Re-running a failed test therefore re-runs restore and build too, which is an accepted cost. Running test projects as parallel jobs is listed as a deferred feature. On which tests run when, see the response to Liam's input below.
- SRJ: I asked a Lead Automation Tester at my work

```text
SRJ: Liam, TL;DR dotnet build and dotnet test in a CI context, do you have an opinion on the order of their running?

I'm designing a new AzDO Yaml Pipeline Template for dotnet_build.yml that people put codebase in, get .exe out as it were, but in the middle need to run tests. I'm faced with questions such as
Should dotnet test be ran before dotnet build?
Are all tests (unit/integration/e2e) treated equally in the sequence of running?
How many of the testing tools (xUnit/nUnit/other) should I support?
When would I run Stryker (mutation testing)?
What about UI tests... Do they go into their own job entirely and separate from the app build?
If you have any thoughts, please let me know.
 ---
Liam:
most of the time I've seen build run before test, some peeps run dotnet test --no-build after. reasoning was there's not much point attempting to run the tests if you can't build the app.
but dotnet test will run a restore and build as well so could be run in parallel.. but honestly don't have a strong opinion either way, just going by what I've seen on other projects but doesn't mean that process can't be improved
unit integration and e2e depends really. E2E usually needs a deployed app so that would be a separate stage. Integration or API can be done in generic test stage (with unit tests) if your using webapplicationfactory. But I like to separate them / run in parallel so it's easy to see what part of the test process failed.
I don't even think we should support Xunit.. nearly all of our estate uses nunit  but yeah weird teams doing weird shit
Styker is a little different, it can take a while for large apps so usually have this in a separate pipeline that triggers only on PR. so its it out of the way if you just need to redeploy main for some reason
UI yeah if your not spinning up a playwright server locally for angular, then yeah UI test should live in a different stage.
just some of my opinions
```

- **Response to Liam's input (acted on in v6 §5, §9, §13):**
  - **Build before test:** kept. Tests run with `--no-build` against the single build, as Liam has seen most often.
  - **Unit and integration tests:** both run in this job (integration tests using `WebApplicationFactory` need no deployed app). Each entry in `Testing.Projects` is its own step with its own `TestRunTitle`, so it's clear which group failed. v6 states this in the user guidance and adds an optional `Filter` per entry, so one project can be split into "Unit" and "Integration" runs by category.
  - **End-to-end and UI tests:** they need a deployed app or a browser server, so they belong in a later stage. They stay out of scope.
  - **xUnit, NUnit and others:** the template calls `dotnet test`, which works with any framework that has a test adapter. There is no framework-specific code, so supporting NUnit doesn't cost anything extra and xUnit isn't blocked. The test fixtures will use NUnit, because most of the estate uses it.
  - **Stryker:** following Liam's advice, mutation testing is **not** a gate inside `dotnet_build`. It is slow, and teams usually run it in a separate pipeline triggered only by PRs. v6 lists it as a future separate job that would use the same gate template.

## 3. Design Drivers

- **Behavioural templates, narrow public surface**
  - Effect: One public job. Building blocks stay internal.
- **Group inputs into validated objects**
  - Effect: One `DotNetBuildConfig` made of sub-objects, each validated where it is used.
- **Fail fast**
  - Effect: Schemas check configuration at compile time. Only facts that can't be known until the job runs are checked at runtime.
- **Protected internal state**
  - Effect: Job variables use list syntax with `readonly: true`.
- **No double-wrapping**
  - Effect: One comprehensive `tasks/dotnet_cli.yml` with a `Command` enum, rather than one wrapper per command.
- **Cross-platform, open-source**
  - Effect: Built-in tasks plus `pwsh`. No Docker needed in the build job. No Marketplace extensions required.
- **Lesson from `0.2.0`**
  - Effect: Use lists of objects from day one. Use a `Type` discriminator only where entry types map to different commands.
- **Lessons from `0.3.1`**
  - Effect: Validate where the data is used. Expand step lists directly (`- ${{ parameters.X }}`).
- **Public shape is expensive, internals are cheap**
  - Effect: Design every sub-object for reuse now. Extract an implementation into `utils/` when a second consumer is known.
- **New: Consumers supply the pool**
  - Effect: The templates work on any pool. Where a step needs something on the agent, the template installs it where it can. Otherwise the user doc states what the agent needs.
- **New: Orchestration in the same file is an accepted exception to double-wrapping**
  - Effect: `terraform_gated_deployment` already combines several jobs. `dotnet_build` may do the same for destinations ([Double Wrapping, exceptions](../docs/developers/explanation/double-wrapping.md)).
- **New: Tools report, gates decide**
  - Effect: A tool never fails the build because of a threshold. Thresholds belong to gates (§9).
- **New: Extend by adding a `Type`**
  - Effect: New destinations, packages and gates are new `Type` values on an existing list. That is a MINOR change, with no change to the overall shape.

**Comments:**

- SRJ (on "Tools report, gates decide"): So the Gates are a concept that I am going to need to figure out and how we can have a consistent implementation of them, what is involved, ideally the Gate would take a metric and look at it, compare to another metric... Ideally the pipeline would have a variable associated with it that could be updated... Possible it is a good small template that could be created that allows for this...
  - **Response (acted on in v6 §9):** Yes. v6 defines one small internal template, `utils/gate_task_list.yml`, that every gate uses. Each gate does three things: it reads one metric from a report, compares it to a fixed threshold, and optionally compares it to the baseline from the last successful run. See the response in §1 for why the baseline comes from the previous run's reports artifact rather than a pipeline variable.
- SRJ (on "Extend by adding a `Type`"): Hmmm I think I will need to see this `Type` and how it'll get used and that... Probably need to read onwards to see all of that.
  - **Response (acted on in v6 §4.3):** v6 adds a short worked explanation. `Type` is a field on each entry of a list (`Packages`, `Destinations`, `Gates`) that says which kind of entry it is. The template uses it at compile time to pick the steps or job for that entry, and the schema uses it to check which other fields are allowed. This is the same pattern `ConfigSources` already uses.

## 4. Public Interface

### 4.1 Template Parameters

- **`ArtifactName`**
  - Type: `string`
  - Default: `'DotNetArtifact'`
  - Status: `0.4.0`
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
- **`DotNetBuildInjectionSteps`**
  - Type: `stepList`
  - Default: `[]`
  - Status: `0.4.0`. Runs after feed authentication, before restore (§5).
- **`DotNetBuildConfig`**
  - Type: `object`
  - Default: _none (required)_
  - Status: `0.4.0`
- **`Destinations`**
  - Type: `object`
  - Default: `[]`
  - Status: **Reserved.** Added in a later MINOR release (§8). Adding it later with a default of `[]` is non-breaking.

`Destinations` is kept outside `DotNetBuildConfig` on purpose:

- `DotNetBuildConfig` describes _the build_.
- `Destinations` describes _delivery_.

Delivery runs in other jobs, on other pools, with other credentials. Keeping the two apart means a future `pipelines/dotnet_pipeline.yml` can pass `Destinations` straight through.

**Comments:**

- SRJ (on `DotNetBuildInjectionSteps`): Honestly I don't know what I am doing with the InjectionSteps... I think best leave them out for now...
  - **Response (acted on in v6 §4.1, §12):** Removed from `0.4.0`. Adding a `stepList` parameter later with a default of `[]` is a non-breaking MINOR change, so nothing is lost by waiting until there is a real use for it.
- SRJ (on keeping `Destinations` outside `DotNetBuildConfig`): Argh... I am struggling with this but yeah a
  - **Response (acted on in v6 §4.1, §15):** This note was cut off, so v6 keeps `Destinations` as a separate parameter but explains the reasons more simply. It is also an open question (v6 §15), so you can overrule it before `Destinations` ships. Nothing in `0.4.0` depends on the choice, because `Destinations` is still reserved.

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
      - Project: string
        TestRunTitle: string #   default 'DotNet Test - <Project>'

  # Gates
  Gates: [...] # RESERVED (§9)

  # Artifacts
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

**New field: `Packages[].Name`.** It identifies each package in the manifest and the artifact folders, and destinations refer to packages by this name (§8). It defaults to the project file name, so most consumers never set it. Set it when the same project is packaged twice, for example `Publish` and `Container`.

**Comments:**

### 4.3 Example

```yaml
- template: jobs/dotnet_build.yml@AzDOPipelineTemplates
  parameters:
    ArtifactName: "MyApi"
    DotNetBuildConfig:
      RelativePathToSolution: "MyApi.sln"
      Testing:
        Projects:
          - Project: "tests/MyApi.UnitTests/MyApi.UnitTests.csproj"
            TestRunTitle: "Unit Tests"
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
5. **Run the consumer's injection steps**
   - Implementation: `- ${{ parameters.DotNetBuildInjectionSteps }}`
   - Runs when: Supplied
6. **`DotNet Restore`**
   - Implementation: `tasks/dotnet_cli.yml`
   - Runs when: Always
7. **`DotNet Build` (`--no-restore`, plus `-bl` if diagnostics are on)**
   - Implementation: `tasks/dotnet_cli.yml`
   - Runs when: Always
8. **Tools: Testing (one step per project, then publish coverage)**
   - Implementation: `utils/dotnet_test_task_list.yml`
   - Runs when: `Testing` is present
9. **_(reserved)_ Gates**
   - Implementation: Gate utils (later)
   - Runs when: `Gates` is present
10. **Package each entry into `$(DotNetPackagesDirectory)/<type>/<Name>`**
    - Implementation: `tasks/dotnet_cli.yml` (§6.1)
    - Runs when: `Packages` is present
11. **Write the package manifest (§6.3)**
    - Implementation: Inline `pwsh`
    - Runs when: `Packages` is present
12. **Upload `<ArtifactName>`**
    - Implementation: `tasks/publish_pipeline_artifact.yml`
    - Runs when: `Packages` is present
13. **Upload `<ArtifactName>_Reports` (`succeededOrFailed()`)**
    - Implementation: `tasks/publish_pipeline_artifact.yml`
    - Runs when: Always (§7)
14. **Upload `<ArtifactName>_Diagnostics` (`succeededOrFailed()`)**
    - Implementation: `tasks/publish_pipeline_artifact.yml`
    - Runs when: `CollectBinaryLog` is true
15. **Upload the run summary (`succeededOrFailed()`)**
    - Implementation: Inline `pwsh` + `##vso[task.uploadsummary]`
    - Runs when: Always

**Failure behaviour:**

- A failed build, failed test or failing `Enforce` gate stops packaging. No artifact is produced from untested code.
- Test results, reports, diagnostics and the summary are still uploaded when a step fails.
- The first failing test suite stops any later suites.

**Comments:**

## 6. Packages and the Artifact Hand-Off Contract

This section covers how each package is produced, and how a container tarball (or any other package) reaches a later deployment or destination job.

**Comments:**

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
  manifest.json
  publish/<Name>.zip            or  publish/<Name>/
  nuget/<Name>/<PackageId>.<Version>.nupkg
  container/<Name>.tar.gz
```

- **One folder per package type, then one entry per package `Name`.** Only the folders for the types actually used are created. Consumers find files without having to guess.
- **One artifact for all packages,** so there is a single thing to reference, version and keep.

**Comments:**

### 6.4 The Package Manifest

Downstream jobs read the packages from `manifest.json`. They don't have to scan folders or re-derive the build's settings.

```json
{
  "schemaVersion": 1,
  "artifactName": "MyApi",
  "build": {
    "buildId": "1234",
    "sourceVersion": "<commit sha>",
    "configuration": "Release"
  },
  "packages": [
    { "name": "MyApi", "type": "Publish", "path": "publish/MyApi.zip" },
    {
      "name": "MyApi.Image",
      "type": "Container",
      "path": "container/MyApi.Image.tar.gz",
      "container": { "repository": "myorg/myapi", "tags": ["1.4.0", "1234"] }
    },
    {
      "name": "MyLib",
      "type": "NuGet",
      "path": "nuget/MyLib/MyLib.1.4.0.nupkg"
    }
  ]
}
```

**How the manifest is produced:**

- It is written by one inline `pwsh` step.
- For `Container` entries, the repository and tags are read with `dotnet msbuild -getProperty:ContainerRepository -getProperty:ContainerImageTags`, using the same `Arguments` as the package step. This must be verified in a test fixture.
- **Fallback:** the tarball's own manifest also records the image tags.

**The manifest is a public contract:**

- `schemaVersion` lets it evolve.
- Adding fields is MINOR. Removing or renaming fields is MAJOR.

**Comments:**

### 6.5 Consuming the Artifact

- Destination and deployment jobs download **only the paths they need** (`DownloadPipelineArtifact@2` with item patterns), plus `manifest.json`.
- Example: a zip deploy never downloads a container tarball.
- Consumers outside this repository (team-owned deploy jobs) can use the same contract. The user doc will publish it.

**Comments:**

### 6.6 Versions of Produced Packages

The template does not calculate versions in v1. Versions come from the codebase (`Directory.Build.props` / `<Version>`, `ContainerImageTags`), or are passed through `Arguments`. A shared version-calculation util (for example GitVersion pinned as a `dotnet tool`) is a candidate for a later release.

**Comments:**

## 7. Reports and Logs

### 7.1 Reports (Always On)

**Mechanism:**

- The job defines `DotNetReportsDirectory`, a read-only variable.
- Every tool util takes a `ReportsDirectory` parameter, writes to `<ReportsDirectory>/<tool>/`, and also publishes to its native destination.
- One final step uploads the directory as `<ArtifactName>_Reports`.
- Adding a tool means adding a util. The job doesn't change.

**Reports produced in `0.4.0`:**

- **Test results (`.trx`)**
  - Native destination: Tests tab (`DotNetCoreCLI@2` test publishing)
  - Reports artifact: `testing/trx/`
- **Coverage (Cobertura)**
  - Native destination: Coverage tab (`PublishCodeCoverageResults@2`)
  - Reports artifact: `testing/coverage/`

**Coverage across several test projects** uses the built-in task. ReportGenerator is added only if the multi-project fixture shows the merged numbers are wrong (§14).

**Always on.** The upload happens on every run, including failed runs. There is no opt-out in v1. If storage becomes an issue later, an opt-out can be added as a MINOR change.

**Comments:**

### 7.2 The "Scans Tab" Question, Explained

- **What SARIF is:** a standard file format for findings from static analysis and security tools: Roslyn analysers, CodeQL, Snyk, Trivy and others.
- **The gap in Azure DevOps:** it has a Tests tab and a Coverage tab built in, but no built-in tab for SARIF.
- **The extension:** Microsoft DevLabs publishes a free extension, "SARIF SAST Scans Tab", that adds one. It reads SARIF files from a build artifact named `CodeAnalysisLogs`.
- **The question was** whether relying on that free extension is acceptable. The repository already relies on a free DevLabs extension for `TerraformInstaller@1`, so there is a precedent.
- **Recommendation:**
  - Templates always write SARIF into the reports artifact. Nothing depends on the extension.
  - Optionally, they also publish a `CodeAnalysisLogs` copy, so organisations that have installed the extension get the tab for free.
  - This becomes relevant only when the first SARIF-producing tool arrives. Nothing in `0.4.0` produces SARIF.

**Comments:**

### 7.3 Logs

- **Step logs**
  - Content: Native, with stable display names: `DotNet Restore`, `DotNet Build`, `DotNet Test - <title>`, `DotNet Publish - <project>`, `DotNet Pack - <project>`, `DotNet Container - <project>`
  - Default: Always on
- **Run summary**
  - Content: SDK version, test counts, coverage, packages produced
  - Default: Always on
- **Diagnostics**
  - Content: MSBuild binary log, as `<ArtifactName>_Diagnostics`
  - Default: Off. Binary logs can contain secrets, and the user doc will warn about this

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
- Each of those is driven entirely by the artifact name and the manifest. This means:
  - Teams using the "salad bar" (picking individual public jobs) can use the delivery jobs without `dotnet_build`.
  - Artifacts produced by other templates or languages can use them, as long as they write a manifest.
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

1. Build the standalone public job, driven by the manifest.
2. Add the new `Type` value and its fields to the destinations schema.
3. Add the compatibility rule.

All three are MINOR changes.

**Comments:**

## 9. Gates (Reserved, Needs Its Own Design)

Gates have not existed as a concept in this repository's templates so far. The nearest precedent is Terraform's `VerificationMode`, where a script reads the plan output and decides whether a human must approve. This section sets the direction only, so `0.4.0` doesn't block it.

**Model:**

- **Tools produce reports. Gates read reports and decide.** A tool never fails the build because of a threshold. Testing fails only because a test failed.
- Examples:
  - The coverage tool writes Cobertura, and a coverage gate checks the line percentage against a minimum.
  - A mutation-testing tool (Stryker) writes a report, and a mutation gate checks the mutation score.
  - A package-audit tool lists vulnerable packages, and a vulnerability gate fails on high severity.

**Where gates run:**

- Gates run after tools and before packaging.
- A failing gate stops packaging, so nothing that fails a gate is produced.
- Gates read from `<ReportsDirectory>`. That makes them reusable across jobs and languages, wherever the reports contract is followed.

**Outcome modes:**

- **`Enforce`:** Fails the job.
- **`Warn`:** The job completes as "succeeded with issues", with a summary entry.
- **`Off`:** The gate doesn't run.

`Warn` lets teams adopt a gate gradually before enforcing it, which helps with adoption.

**Reserved shape:**

```yaml
Gates:
  - Type: Coverage | MutationScore | VulnerablePackages
    Mode: Enforce | Warn
    # Type-specific thresholds, e.g. MinimumLinePercent
```

**Needs its own design document:**

- Threshold sources (the consumer, or an organisation default?).
- Whether gates can be mandated by the organisation.
- How gates appear in the run summary.

**Mutation testing** fits as a _tool_ (Stryker, writing a report) together with a _gate_ (mutation score). It is deferred until the gate design exists.

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
- `tasks/download_pipeline_artifact.yml`, which destinations will use. It needs item-pattern support added, an internal change.

Restore and packaging stay inline in the job. They move to `utils/` when a second consuming job is built, which is an internal (PATCH) change.

**Later:**

- The three delivery jobs.
- `schemas/destinations.yml`.
- `docs/definition_docs/shared/destinations.md` and `package_manifest.md`.
- Gate utils.

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
- **New:** `Packages[].Name` is unique, and is a scalar when supplied.

**Shared schemas** (`dotnet_sdk`, `dotnet_testing`, `config_sources`) validate their own sub-objects.

**Destinations schema (later):**

- `Name` is required and unique.
- `Type` is an allowed value.
- Type-specific required fields are present.
- Every name in `Packages` exists in `DotNetBuildConfig.Packages`.
- Package and destination types are compatible.

This is the first schema that checks one object against another. Its pattern will be added to the [Schema Validation](../docs/developers/reference/schema-validation.md) catalogue.

**All schemas follow the repository conventions:**

- Use `startsWith` for type checks.
- Use presence-gating for optional fields.
- Use the `'<ArtifactName>' artifact error:` or `Invalid <Concept>:` error prefixes.
- End with `See:` links.

**Comments:**

## 12. Public Contract on `0.4.0` Release

- The job name `DotNetBuild_<ArtifactName>`.
- All parameter and field names, and their defaults.
- Where injection steps run, relative to the other steps.
- The artifact layout (§6.3) and `manifest.json` `schemaVersion: 1` (§6.4).
- The reports artifact `<ArtifactName>_Reports` and its tool sub-folders (`testing/trx/`, `testing/coverage/`).
- The diagnostics artifact `<ArtifactName>_Diagnostics` (`build.binlog`).
- **Reserved names:** `Destinations`, `Gates`, and the delivery job name pattern `DotNetDeliver_<ArtifactName>_<DestinationName>`. They are documented as "coming", so nobody builds anything that conflicts with them.

**Comments:**

## 13. Not Included

**Not part of this template at all:**

- **Dockerfile builds.** If a repository needs a Dockerfile, it uses a different (language-agnostic) job, not `dotnet_build`. A template can only control what happens around a Dockerfile, not inside it.
- Deployment to App Service, Functions, AKS and other hosts.
- Security scanning (dependency, SAST, image scanning, including Snyk) as separate jobs.
- .NET Framework (Windows-only MSBuild/VSTest).
- On-premises targets.
- dacpac/sqlpackage, EF migrations.
- SBOM.
- Code signing.
- Browser and end-to-end tests, and tests that need an authenticated Azure identity.
- Config-file substitution at build time.

**Reserved shape, delivered later:**

- Destinations: container registry, file share, NuGet feed.
- Gates: coverage, mutation score, vulnerable packages.
- A complete pipeline template, `pipelines/dotnet_pipeline.yml`.

**Deferred features:**

- Calculating versions or stamping a build number.
- NuGet caching (`Cache@2` keyed on the hash of `packages.lock.json`).
- Further tools (format checks via `dotnet format --verify-no-changes`, package audit, Stryker).
- Running every test suite after one fails.
- Microsoft.Testing.Platform as a test runner (v1 assumes VSTest).
- Post-test injection.
- Windows and multi-architecture images.
- Extracting `JobsVariableMappings` into a shared util.

**Release timing:** `Type: Container` ships in `0.4.0` only if the research and fixture in §14 support it. Otherwise it ships later as a MINOR release. The artifact layout and the manifest already allow for it.

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
   - `-getProperty` gives the repository and tags for the manifest.
3. **Multi-project coverage fixture**, to decide whether ReportGenerator is needed.
4. **Test pipelines registered** through `cicd/` for the new `tests/jobs/dotnet_build/*_test.yml` fixtures. This is a maintainer step.

**Comments:**

## 15. Open Questions

1. **Destinations' default `Pool`:** should it default to the build `Pool`, as proposed, or have no default so consumers must choose?
2. **Gates design document:** when should it be written? Before or after the first destination job?
3. **Manifest for other templates:** should the manifest become repository-wide? For example, `terraform_build` could write one too, so that delivery jobs work across languages.
4. **Shared definition docs:** final names, and whether to split the `docs/definition_docs/shared/` folder as it grows.

**Comments:**
