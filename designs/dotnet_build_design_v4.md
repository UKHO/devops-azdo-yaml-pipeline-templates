# Design: .NET Build (Iteration 4)

**Status:** Draft, iteration 4. This is the current design and stands on its own.

**Previous iterations:** `dotnet_build_design.md` (2) and `dotnet_build_design_v3.md` (3).

**Target:** `jobs/dotnet_build.yml` in `0.4.0`. Distribution jobs follow in later MINOR releases.

## 1. Purpose

`jobs/dotnet_build.yml` is a public, behavioural job template. It does five things:

- Restores the solution once.
- Builds it once.
- Runs the selected tools (tests) against that build.
- Packages the build output in one or more forms: publish output, NuGet package, or container image.
- Uploads the results as pipeline artifacts, together with reports and optional diagnostics.

Consumers describe *what* they want. The template decides *how* the steps are wired.

**Changes in this iteration:**

- A `Container` package type has been added. It uses the .NET SDK's built-in container support. No Dockerfile and no Docker are needed.
- The design records where Dockerfile builds fit.
- There is an explicit list of what is not included (§13).

## 2. Model

```text
INPUTS                        PROCESSING                          OUTPUTS
------                        ----------                          -------
Codebase              ──►  Prepare (SDK, secrets, feeds)   ──►  Artifacts ──► (pipeline artifact)
User options (config)      Restore → Build (once)               Reports   ──► native tabs + reports artifact
Tool selection             Tools (Testing) → reports            Logs (throughout) + run summary
                           Package (Publish | NuGet | Container)
```

**Build in one job, distribute in others.** The build job's only destination is the pipeline artifact. Network share, NuGet feed and container registry delivery are separate public jobs that consume that artifact (§10). This means:

- Every destination ships the tested binaries.
- Each destination job can use its own pool, credentials and approval gate.
- A failed delivery can be re-run without rebuilding.

## 3. Design Drivers

| Driver | Effect |
|---|---|
| Behavioural templates, narrow public surface | One public job. Building blocks stay internal |
| Group inputs into validated objects | One `DotNetBuildConfig` made of sub-objects, each validated where it is used |
| Fail fast | Schemas check configuration at compile time. Only facts that can't be known until the job runs are checked at runtime |
| Protected internal state | Job variables use list syntax with `readonly: true` |
| No double-wrapping | One comprehensive `tasks/dotnet_cli.yml` with a `Command` enum |
| Cross-platform, open-source | Uses built-in tasks plus `pwsh`. No Docker needed in the build job. No Marketplace extensions |
| `0.2.0` lesson | Use lists of objects from day one. Use a `Type` discriminator only where entry types map to different commands |
| `0.3.1` lessons | Validate where data is used. Expand step lists directly |
| Public shape is expensive, internals are cheap | Design every sub-object for reuse now. Extract an implementation into `utils/` when a second consumer is known |

## 4. Public Interface

### 4.1 Template Parameters

| Parameter | Type | Default |
|---|---|---|
| `ArtifactName` | `string` | `'DotNetArtifact'` |
| `Condition` | `string` | `succeeded()` |
| `DependsOn` | `object` | `[]` |
| `Pool` | `string` | `''` |
| `DotNetBuildInjectionSteps` | `stepList` | `[]` |
| `DotNetBuildConfig` | `object` | *none (required)* |

### 4.2 `DotNetBuildConfig`

```yaml
DotNetBuildConfig:
  RelativePathToSolution: string          # required: .sln, .slnx or .csproj
  BuildConfiguration: string              # optional, default 'Release'

  # Preparation
  DotNetSdk:                              # optional (shared: dotnet_sdk)
    Version: string                       #   default '' → global.json
    Install: boolean                      #   default true; false = check the SDK is present, never install
  Restore:                                # optional (job-owned)
    NuGetConfigPath: string
    UseLockedMode: boolean                #   default false
  ConfigSources: [ ... ]                  # optional (shared, existing)

  # Tools
  Testing:                                # optional (shared: dotnet_testing)
    CollectCoverage: boolean              #   default true
    Projects:                             #   required when Testing is present
      - Project: string
        TestRunTitle: string              #   default 'DotNet Test - <Project>'

  # Artifacts
  Packages:                               # optional; if absent, no artifact is produced
    - Type: Publish | NuGet | Container
      Project: string                     #   required
      Arguments: string                   #   optional, extra CLI arguments for this entry
      ZipAfterPublish: boolean            #   Publish only, default true

  # Logs
  Diagnostics:                            # optional
    CollectBinaryLog: boolean             #   default false
```

**Rules for the shape:**

- **Leaving out a sub-object switches that behaviour off.** There are no `RunTests` or `EnablePublish` flags.
- **`Type` names describe the output, not the tool.** The type is `Container`, not `Docker`.
- **No Docker-only fields.** `Dockerfile` and `BuildContext` belong to a future Dockerfile job (§10.2).
- **New `Type` values and new optional fields are MINOR changes.** Removing or renaming them is MAJOR.

### 4.3 Example

```yaml
- template: jobs/dotnet_build.yml@AzDOPipelineTemplates
  parameters:
    ArtifactName: 'MyApi'
    DotNetBuildConfig:
      RelativePathToSolution: 'MyApi.sln'
      Testing:
        Projects:
          - Project: 'tests/MyApi.UnitTests/MyApi.UnitTests.csproj'
            TestRunTitle: 'Unit Tests'
      Packages:
        - Type: Publish
          Project: 'src/MyApi/MyApi.csproj'
        - Type: Container
          Project: 'src/MyApi/MyApi.csproj'
          Arguments: '-p:ContainerRepository=myorg/myapi'
```

## 5. Processing (Fixed Order)

| # | Step | Implementation | Runs when |
|---|---|---|---|
| 0 | Validate the job-owned fields | `schemas/dotnet_build_config.yml` (`jobs:`) | Always, at compile time |
| 1 | Check out `self` to an explicit `path`, then `download: none` | — | Always |
| 2 | Provide the SDK (install or check) | `utils/dotnet_sdk_task_list.yml` | Always |
| 3 | Load secrets | `utils/config_sources_task_list.yml` | `ConfigSources` is present |
| 4 | Authenticate to feeds | `tasks/nuget_authenticate.yml` | Always |
| 5 | Run the consumer's injection steps | `- ${{ parameters.DotNetBuildInjectionSteps }}` | Supplied |
| 6 | `DotNet Restore` | `tasks/dotnet_cli.yml` | Always |
| 7 | `DotNet Build` (`--no-restore`, plus `-bl` if diagnostics are on) | `tasks/dotnet_cli.yml` | Always |
| 8 | Run tests (one step per project) and publish coverage | `utils/dotnet_test_task_list.yml` | `Testing` is present |
| 9 | Package each entry (`--no-build`) | `tasks/dotnet_cli.yml` (§6) | `Packages` is present |
| 10 | Upload the artifact | `tasks/publish_pipeline_artifact.yml` | `Packages` is present |
| 11 | Upload reports | `tasks/publish_pipeline_artifact.yml`, `succeededOrFailed()` | A tool ran |
| 12 | Upload diagnostics | `tasks/publish_pipeline_artifact.yml`, `succeededOrFailed()` | `CollectBinaryLog` is true |
| 13 | Upload the run summary | Inline `pwsh` + `##vso[task.uploadsummary]`, `succeededOrFailed()` | Always |

**Failure behaviour:**

- A failed build or failed test stops packaging. No artifact is produced from untested code.
- Test results, reports, diagnostics and the summary are still uploaded when a step fails.
- The first failing test suite stops any later suites.

## 6. Packages

| `Type` | Command (`--no-build`, same configuration) | Output in the artifact | Needs |
|---|---|---|---|
| `Publish` | `dotnet publish` (`publishWebProjects: false`) | `publish/<Project>.zip`, or `publish/<Project>/` | — |
| `NuGet` | `dotnet pack` | `nuget/<PackageId>.<Version>.nupkg` | A version from the codebase or `Arguments` (§9) |
| `Container` | `dotnet publish -t:PublishContainer -p:ContainerArchiveOutputPath=...` | `container/<Project>.tar.gz` | .NET 8+ SDK. No Docker. No registry access during the build |

### 6.1 `Container` Specifics

- **The image is built from the same tested build output, by the .NET SDK.** It is written as a tarball and never pushed from the build job. Pushing is a distribution job (§10.1).
- Image settings use the SDK's MSBuild properties, either in the project file or through `Arguments`:
  - `ContainerRepository`
  - `ContainerImageTags`
  - `ContainerBaseImage`
  - `ContainerFamily`
  - `ContainerRuntimeIdentifier`
- The template adds only `ContainerArchiveOutputPath`, so the tarball lands in a known location.
- **Linux images are the supported target.** Windows-based images are not supported in v1.
- **Points to verify with a test fixture before release:**
  - `PublishContainer` works with `--no-build`, and with the runtime identifier used at build time.
  - The tarball is produced on Windows and Linux agents.
  - `ContainerArchiveOutputPath` behaves as expected on the minimum SDK (8.0.1xx).
  - These points are written from memory of the SDK documentation, not from running it.
- **Artifact size:** image tarballs make the artifact much larger. The user doc should point to retention settings.
- **Release gate:** `Container` ships in `0.4.0` only if the Docker usage research (§12) doesn't contradict the SDK-first approach. Otherwise it follows in a later MINOR release. Adding a type later is a non-breaking change.

## 7. Reports

**How reports work:**

- The job defines `DotNetReportsDirectory`, a read-only variable.
- Every tool util takes a `ReportsDirectory` parameter. Each util writes to `<ReportsDirectory>/<tool>/` and also publishes to its native destination.
- One final step uploads the directory as `<ArtifactName>_Reports`.
- Adding a tool means adding a util. The job doesn't change.

| Report | Native destination | Reports artifact |
|---|---|---|
| Test results (`.trx`) | Tests tab (`DotNetCoreCLI@2` test publishing) | `testing/trx/` |
| Coverage (Cobertura) | Coverage tab (`PublishCodeCoverageResults@2`) | `testing/coverage/` |

**Coverage across several test projects:** this uses the built-in task. ReportGenerator is added only if the multi-project test fixture shows the merged numbers are wrong.

## 8. Logs

| Level | Content | Default |
|---|---|---|
| Step logs | Native, with stable display names: `DotNet Restore`, `DotNet Build`, `DotNet Test - <title>`, `DotNet Publish - <project>`, `DotNet Pack - <project>`, `DotNet Container - <project>` | Always on |
| Run summary | SDK version, test counts, coverage, packages produced | Always on |
| Diagnostics | MSBuild binary log, as `<ArtifactName>_Diagnostics` | Off. Binary logs can contain secrets, and the user doc will warn about this |

## 9. Versioning of Produced Packages

The template does not calculate versions in v1. Versions come from the codebase (`Directory.Build.props`/`<Version>`, `ContainerImageTags`), or are passed through `Arguments`.

A shared version-calculation util, for example GitVersion pinned as a `dotnet tool`, is a candidate for a later release.

## 10. Distribution and Other Container Routes (Future, Shape Only)

### 10.1 Distribution Jobs

These are separate public jobs. They download the artifact and deliver it.

| Future job | Consumes | Notes |
|---|---|---|
| `jobs/nuget_push.yml` | `nuget/` | Azure Artifacts via `NuGetAuthenticate@1`. External feeds via a service connection. Approval gate via an environment |
| `jobs/container_push.yml` | `container/*.tar.gz` | Pushes to Docker Hub or ACR using a Docker Registry service connection. **Undecided:** push tool (`crane`/`skopeo`/`oras`, which need no Docker, or `docker load` + `push`, which needs Docker). Approval gate via an environment |
| File share copy job (name to agree) | Any folder | `pwsh` `Copy-Item` on a pool that can reach the share |

### 10.2 Dockerfile Builds

- **Where they fit:** a future **language-agnostic** `jobs/container_build.yml`. It is not part of `dotnet_build`.
- **Recommended use:** a *thin* Dockerfile that copies the published output into a runtime image. That way the tested binaries are what ships.
- **Not a supported route:** Dockerfiles that restore, build and test inside the image. They are treated as a migration target, because templates can't see or standardise what happens inside them.
- **Limit:** a template can only control what happens around a Dockerfile (tagging, scanning, pushing, gates), not what's inside it.

### 10.3 Future Set Menu

`pipelines/dotnet_pipeline.yml` would take a `Destinations` list with a `Type` discriminator and expand it into the distribution jobs.

## 11. Building Blocks and Validation

### 11.1 Building Blocks

| Piece | Kind | Status |
|---|---|---|
| `tasks/dotnet_cli.yml` | Internal task. `DotNetCoreCLI@2` with `Command` set to restore, build, test, publish, pack or custom | New |
| `tasks/dotnet_installer.yml` | Internal task. `UseDotNet@2`, using `useGlobalJson` or a version | New |
| `tasks/nuget_authenticate.yml` | Internal task. `NuGetAuthenticate@1` | New |
| `tasks/publish_code_coverage.yml` | Internal task. `PublishCodeCoverageResults@2` | New |
| `utils/dotnet_sdk_task_list.yml` + `schemas/dotnet_sdk.yml` + `docs/definition_docs/shared/dotnet_sdk.md` | Shared concept | New |
| `utils/dotnet_test_task_list.yml` + `schemas/dotnet_testing.yml` + `docs/definition_docs/shared/dotnet_testing.md` | Shared concept | New |
| `utils/config_sources_task_list.yml` | Shared concept | Reused unchanged |
| `tasks/powershell.yml`, `tasks/publish_pipeline_artifact.yml` | Internal tasks | Reused |

Restore and packaging stay inline in the job. They move to `utils/` when a second consuming job is built, which is an internal (PATCH) change.

### 11.2 Validation

**The job schema validates:**

- `RelativePathToSolution` is required.
- Scalar fields are scalars.
- `Restore` and `Diagnostics` have the right shape.
- `Packages` is a non-empty list of objects.
- `Type` is one of `Publish`, `NuGet` or `Container`.
- `Project` is required.
- `ZipAfterPublish` is used only with `Publish`.

**The shared schemas** validate their own sub-objects.

**All schemas:**

- Use `startsWith` for type checks.
- Use presence-gating for optional fields.
- Use the `'<ArtifactName>' artifact error:` or `Invalid <Concept>:` prefixes.
- End with `See:` links.

### 11.3 Output Contract (Public From Release)

```text
<ArtifactName>/                    publish/  nuget/  container/   (only the folders whose Type is used)
<ArtifactName>_Reports/            testing/trx/  testing/coverage/
<ArtifactName>_Diagnostics/        build.binlog                   (opt-in)
```

**Also public:**

- The job name `DotNetBuild_<ArtifactName>`.
- All parameter and field names, and their defaults.
- Where injection steps run, relative to the other steps.

## 12. Dependencies Before Release

1. **Docker usage research** across the org. Search code for:
   - `Dockerfile`
   - `Docker@2`
   - `PublishContainer`
   - `FROM mcr.microsoft.com/dotnet`

   Sort each Dockerfile into one of three groups:
   - **Thin:** copies prebuilt output into a runtime image.
   - **Builds everything, plain .NET:** can move to `dotnet_build` + `Type: Container`.
   - **Builds everything, needs OS packages or tools:** demand for a Dockerfile job.

   The result decides whether `Container` ships in `0.4.0` and when a Dockerfile job is needed.
2. **Container test fixture** confirming the checks in §6.1.
3. **Multi-project coverage fixture**, to settle the ReportGenerator question.
4. **Test pipelines registered** through `cicd/` for the new `tests/jobs/dotnet_build/*_test.yml` fixtures. This is a maintainer step.

## 13. Not Included in This Design

**Deferred to future templates (the design leaves room for them):**

- Pushing anything anywhere:
  - NuGet feeds (`nuget_push`).
  - Container registries such as Docker Hub or ACR (`container_push`).
  - Network shares (file share copy job).
- Dockerfile-based image builds (a language-agnostic `container_build`).
- Deployment to App Service, Functions, AKS and other hosts.
- A complete .NET pipeline (`pipelines/dotnet_pipeline.yml`) with a `Destinations` list.
- Security scanning: dependency, SAST or image scanning, including Snyk. These are separate jobs.

**Deferred features of this job (a later MINOR release could add them):**

- Calculating a version or stamping a build number.
- NuGet caching (`Cache@2` keyed on the hash of `packages.lock.json`).
- More tools, such as format checks (`dotnet format --verify-no-changes`) or vulnerable-package audits. They would plug in through the reports contract.
- Coverage thresholds and quality gates.
- Running every test suite after one fails.
- Microsoft.Testing.Platform as a test runner (v1 assumes VSTest).
- A post-test injection hook.
- Windows-based container images.
- Multi-architecture images.
- Extracting `JobsVariableMappings` into a shared util.

**Out of scope entirely:**

- .NET Framework (Windows-only MSBuild/VSTest).
- On-premises deployment targets.
- dacpac/sqlpackage, EF migrations, SBOM generation, code signing.
- Mutation testing, browser and end-to-end tests, and tests that need an authenticated Azure identity.
- Config-file substitution at build time.

**Not decided yet (§14):** the push tool, network share access, which feeds and registries are in scope, and the Scans-tab extension.

## 14. Open Questions

1. **Docker research outcome:** ship `Container` in `0.4.0` or later?
2. **Container push tool:** a standalone tool (`crane`/`skopeo`/`oras`), or Docker on the push agent?
3. **Network share:** which shares, which agents can reach them, and does a copy need an approval?
4. **NuGet feeds:** Azure Artifacts only, or nuget.org and other external feeds too?
5. **Registries:** Docker Hub only, or ACR as well?
6. **Scans tab for SARIF:** the free Microsoft extension is acceptable or not?
7. **Reports artifact:** always on, or opt-out?
8. **Agent pools at release:** `Mare Nectaris`, Microsoft-hosted, or both?
9. **Shared definition docs:** names, and whether to split the `shared/` folder?
