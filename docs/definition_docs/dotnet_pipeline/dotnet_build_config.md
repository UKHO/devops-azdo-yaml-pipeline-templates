# DotNetBuildConfig

The configuration object that defines how a .NET project is restored, built, tested, and packaged
by the `dotnet_build` job. This includes the project to build, the build configuration, optional
test execution, and the output packaging strategy (zip artifact or container image).

> **Design alignment note:** This document describes the `DotNetBuildConfig` object as it is
> **currently implemented** in `jobs/dotnet_build.yml` / `schemas/dotnet_build_config.yml`. The
> `.NET` pipeline design in `azdo-pipeline-research/design/pbis/` (PBIs A2, A3, A4, A5, A6, A8, A9,
> A10, A11, A13) describes a broader, still-evolving target model that this implementation does
> **not** yet fully match. See [Design Roadmap and Known Gaps](#design-roadmap-and-known-gaps) below
> before treating this document as the final shape of the `.NET` pipeline.

## Definition

```yaml
DotNetBuildConfig:
  RelativePathToProject: string              # REQUIRED - path to the .csproj/.sln, relative to repo root
  BuildOutputType: string                    # REQUIRED (Zip | Container)
  BuildConfiguration: string                 # OPTIONAL - defaults to 'Release'
  DotNetVersion: string                      # OPTIONAL - .NET SDK version to install (if not provided, uses the agent's default SDK)
  RunTests: boolean                          # OPTIONAL - defaults to true
  TestProjects: string                       # OPTIONAL - defaults to RelativePathToProject
  PublishTestResults: boolean                # OPTIONAL - defaults to true
  PublishOutputDirectory: string             # OPTIONAL - defaults to '$(Build.ArtifactStagingDirectory)/publish'
  ContainerRegistryServiceConnection: string # REQUIRED when BuildOutputType is 'Container'
  ContainerRepository: string                # REQUIRED when BuildOutputType is 'Container'
  Dockerfile: string                         # OPTIONAL - defaults to '**/Dockerfile'
  BuildContext: string                       # OPTIONAL - defaults to '.'
  ImageTags: string                          # OPTIONAL - defaults to '$(Build.BuildId)'
```

---

## Required Properties

### RelativePathToProject

**Type:** `string`

**Description:** The relative path from the repository root to the `.csproj` (or `.sln`) file that
should be restored, built, and (optionally) published/containerised.

**Example:** `'src/MyApi/MyApi.csproj'`

---

### BuildOutputType

**Type:** `string`

**Description:** Controls how the build output is packaged and published.

**Allowed Values:**

- `'Zip'` - Publishes the .NET project output and uploads it as a pipeline artifact.
- `'Container'` - Builds a container image from a Dockerfile and pushes it to a container registry.

**Example:** `'Zip'`

---

## Optional Properties

### BuildConfiguration

**Type:** `string`

**Description:** The MSBuild/`dotnet` build configuration to use for restore, build, test, and publish.

**Default:** `'Release'`

**Example:** `'Debug'`

---

### DotNetVersion

**Type:** `string`

**Description:** The .NET SDK version to install before building. Accepts the same version string
format as the `UseDotNet` task (e.g. a specific version or a floating version pattern). If omitted,
the SDK version already available on the agent is used and no install step is run.

**Example:** `'8.0.x'`

---

### RunTests

**Type:** `boolean`

**Description:** Controls whether `dotnet test` is run after the build step.

**Default:** `true`

**Example:** `false`

---

### TestProjects

**Type:** `string`

**Description:** The project(s) or glob pattern to pass to `dotnet test`. Only used when `RunTests`
is `true` (or omitted). If not provided, defaults to `RelativePathToProject` (i.e. tests are assumed
to live alongside/within the same project unless otherwise specified).

**Example:** `'tests/MyApi.Tests/MyApi.Tests.csproj'`

---

### PublishTestResults

**Type:** `boolean`

**Description:** Controls whether test results are published to Azure DevOps as part of the `dotnet
test` step. Only used when `RunTests` is `true` (or omitted).

**Default:** `true`

**Example:** `false`

---

### PublishOutputDirectory

**Type:** `string`

**Description:** The directory that `dotnet publish` writes to when `BuildOutputType` is `'Zip'`.
This directory is then uploaded as the pipeline artifact.

**Default:** `'$(Build.ArtifactStagingDirectory)/publish'`

**Example:** `'$(Build.ArtifactStagingDirectory)/publish/api'`

---

### ContainerRegistryServiceConnection

**Type:** `string`

**Description:** The Azure DevOps service connection used to authenticate with the target container
registry when pushing the built image.

**Required When:** `BuildOutputType` equals `'Container'`

**Example:** `'MyAcrServiceConnection'`

---

### ContainerRepository

**Type:** `string`

**Description:** The fully-qualified repository name (registry host + repository path) that the
built container image is tagged and pushed to.

**Required When:** `BuildOutputType` equals `'Container'`

**Example:** `'myregistry.azurecr.io/my-api'`

---

### Dockerfile

**Type:** `string`

**Description:** Path (or glob pattern) to the Dockerfile used to build the container image. Only
used when `BuildOutputType` is `'Container'`.

**Default:** `'**/Dockerfile'`

**Example:** `'src/MyApi/Dockerfile'`

---

### BuildContext

**Type:** `string`

**Description:** The Docker build context directory passed to the container build command. Only
used when `BuildOutputType` is `'Container'`.

**Default:** `'.'`

**Example:** `'src/MyApi'`

---

### ImageTags

**Type:** `string`

**Description:** The tag(s) applied to the built container image. Only used when `BuildOutputType`
is `'Container'`.

**Default:** `'$(Build.BuildId)'`

**Example:** `'latest'`

---

## Complete Examples

### Zip Artifact (build, test, publish)

```yaml
DotNetBuildConfig:
  RelativePathToProject: 'src/MyApi/MyApi.csproj'
  BuildOutputType: Zip
  BuildConfiguration: Release
  DotNetVersion: '8.0.x'
  RunTests: true
  TestProjects: 'tests/MyApi.Tests/MyApi.Tests.csproj'
  PublishTestResults: true
  PublishOutputDirectory: '$(Build.ArtifactStagingDirectory)/publish'
```

### Container Image (build, test, push)

```yaml
DotNetBuildConfig:
  RelativePathToProject: 'src/MyApi/MyApi.csproj'
  BuildOutputType: Container
  ContainerRegistryServiceConnection: 'MyAcrServiceConnection'
  ContainerRepository: 'myregistry.azurecr.io/my-api'
  Dockerfile: 'src/MyApi/Dockerfile'
  BuildContext: 'src/MyApi'
  ImageTags: 'latest'
```

### Zip Artifact, Tests Skipped

```yaml
DotNetBuildConfig:
  RelativePathToProject: 'src/MyApi/MyApi.csproj'
  BuildOutputType: Zip
  RunTests: false
```

---

## Design Roadmap and Known Gaps

The `.NET` pipeline design work in `azdo-pipeline-research/design/pbis/` (Workstream A) describes a
target architecture that is **more granular** than the current single-job `DotNetBuildConfig`
implementation. The sections below map each design PBI to its current implementation status so
consumers and maintainers know what's stable vs. still evolving.

### Composition model (package → test → build → scan → publish)

- **PBI A4** (resolved via `ADR-0054`) decided that `.NET` pipelines should compose as a sequence of
  standalone job templates — a shared **package job** (PBI A13) first, then a standalone
  **`dotnet_test` job** (PBI A3), then **`dotnet_build`** (PBI A2, this document), then security
  scanning, then publish-destination jobs.
- **Current implementation status:** `jobs/dotnet_build.yml` does **not** yet follow this model. It
  is a single job that checks out the repository itself, restores, builds, and (via `RunTests`)
  optionally runs tests all in one job — there is no separate package job (A13) or standalone
  `dotnet_test` job (A3) yet. `RunTests`, `TestProjects`, and `PublishTestResults` on
  `DotNetBuildConfig` are today's stand-in for what the design intends to be a completely separate
  `dotnet_test` job/config in future.
- **Action for implementers:** when A13/A3 are built, expect `RunTests`/`TestProjects`/
  `PublishTestResults` to be **deprecated on `DotNetBuildConfig`** and moved to a new
  `DotNetTestConfig` object consumed by a new `dotnet_test` job, with `dotnet_build` depending on the
  package job's artifact instead of doing its own checkout.

### Container publishing (PBI A9)

- **Current implementation:** `BuildOutputType: Container` builds from a **Dockerfile**
  (`Dockerfile`, `BuildContext`, `ImageTags` are passed to a Docker build-and-push task).
- **PBI A9 design decision:** container publishing should use the **SDK-native container publish**
  (`dotnet publish /t:PublishContainer`), explicitly **not** a hand-written Dockerfile, to avoid a
  second artifact (the Dockerfile) drifting out of sync with the project.
- **This is an open discrepancy**, not just a gap: the current `Container` output type and PBI A9's
  decided approach are two different mechanisms. PBI A9 is still "Not started" and has its own
  unresolved sub-questions (registry auth per provider, tagging convention, layer-caching strategy)
  that block a redesign. Until A9 is implemented, treat the current Dockerfile-based `Container`
  option as a pragmatic interim mechanism, not the final design.

### Additional publish destinations (not yet implemented)

The design intends `.NET` builds to support a pluggable list of publish destinations, of which only
the Dockerfile-based container path above exists today:

| PBI | Destination | Status | Notes |
|---|---|---|---|
| A8 | Cloud App Package (e.g. Azure App Service/Function App) | Not started | Framework-dependent by default; exact task sequence (e.g. `AzureWebApp@1`) still TBD |
| A9 | Container Registry (SDK-native publish) | Not started — needs its own auth/tagging/caching design pass | See discrepancy note above; current `Container` type is Dockerfile-based, not SDK-native |
| A10 | NuGet/ProGet feed | Not started | Authenticates via `NuGetAuthenticate@1` per `ADR-0031`; version sourced from `Directory.Build.props` per `ADR-0026` |
| A11 | Dacpac/Database | **Parked** | Explicitly out of the fixed tool set (`ADR-0040`); would be its own standalone template (`dotnet_dacpac`), not a `DotNetBuildConfig` destination, if ever unparked |

### Opt-in test tooling (attaches to the future `dotnet_test` job, not `dotnet_build`)

| PBI | Tool | Status | Notes |
|---|---|---|---|
| A5 | Stryker mutation testing | Not started | Opt-in via config presence (`StrykerConfig`), not a boolean; pinned via local `dotnet-tools.json` manifest per `ADR-0027` |
| A6 | ReportGenerator coverage merge | Not started | Auto-triggered when >1 coverage file is detected; no consumer-facing toggle per `ADR-0032`/`ADR-0041` |
| A12 | Playwright (e2e/UI) | Not started | Sibling template family, **not** a `.NET`/`DotNetBuildConfig` concern — Node.js-based, runs as its own downstream job |

### Deployment (PBI A7)

`dotnet_deploy` (deploying the artifact this job produces to a target environment) is explicitly out
of scope for `DotNetBuildConfig`/`dotnet_build` and needs its own research-and-design pass before
implementation — see PBI A7. `dotnet_build` only produces/publishes an artifact; it never deploys it.

---

## Related Tests

- **Schema Tests**: [`schemas/dotnet_build_config.CompileTests.ps1`](../../../schemas/dotnet_build_config.CompileTests.ps1)

## See Also

- [DotNet Build Job Documentation](../../user-docs/jobs/dotnet_build.md) - Job that uses `DotNetBuildConfig`
- [DotNetBuildConfig Schema](../../../schemas/dotnet_build_config.yml) - Validation rules enforced on this object
- Design PBIs (in `azdo-pipeline-research/design/pbis/`): A2 (this job's core design), A3 (`dotnet_test`), A4 (composition-model decision, `ADR-0054`), A5 (Stryker), A6 (ReportGenerator), A7 (`dotnet_deploy`), A8–A11 (publish destinations), A12 (Playwright), A13 (package job)

