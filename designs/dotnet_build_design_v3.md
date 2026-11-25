# Design: .NET Build and Distribution (Iteration 3)

**Status:** Draft, iteration 3 · **Builds on:** iteration 2 (`dotnet_build_design.md`) · **Target:** `jobs/dotnet_build.yml` in `0.4.0`, with distribution jobs in later MINOR releases

## 1. What Changed From Iteration 2 and Why

Iteration 2 answered "how do we build .NET well". It did not answer **where the results go**:

- **Destinations:** `PublishProjects` mixed *what form* an output takes (a zip or a folder) with *where it goes* (always the pipeline artifact). There was no route to a network share, a NuGet feed or a container registry.
- **Reports:** test results and coverage went to the Tests and Coverage tabs, but there was no report output, so later jobs and people outside Azure DevOps couldn't use them.
- **Logs:** there was no model for logs.

Iteration 3 treats the template as a process with three parts:

```text
INPUTS                        PROCESSING                         OUTPUTS
------                        ----------                         -------
Codebase              ──►  Prepare (SDK, secrets, feeds)  ──►  Artifacts  ──► Destinations
User options (config)      Restore → Build (once)              Reports    ──► Report destinations
Tool selection             Tools (test, analyse) → reports     Logs (produced throughout)
                           Package (publish, pack)
```

Iteration 2's decisions are carried forward unless this document changes them (§12).

## 2. Inputs

| Input | Form | Notes |
|---|---|---|
| **Codebase** | The `self` checkout | Solution or project at `RelativePathToSolution`, plus `global.json`, `nuget.config`, lock files and test projects (consumer responsibilities as in iteration 2) |
| **User options** | `DotNetBuildConfig` object | Validated at compile time |
| **Tool selection** | Named sub-objects in the config (`Testing`, later others) | **Leaving a tool's sub-object out means it doesn't run.** The template fixes the order tools run in. Consumers choose *which* tools run, not *how* the pipeline is wired |

**Named sub-objects, not a generic `Tools: [ - Type: ... ]` list.** Each tool has different settings, and the order they run in matters for correctness: formatting checks run before the build, tests run after it. Keeping that order inside the template is the behavioural-template principle. A typed list would hand the ordering to consumers.

## 3. Processing

The processing steps are carried over from iteration 2, with a fixed order:

1. **Prepare:**
   - SDK (`utils/dotnet_sdk_task_list.yml`).
   - `ConfigSources` (`utils/config_sources_task_list.yml`).
   - Feed authentication (`tasks/nuget_authenticate.yml`).
   - Injection steps.
2. **Restore** once, then **Build** once (`--no-restore`).
3. **Tools** run against the build output. In v1 that is only `Testing` (`utils/dotnet_test_task_list.yml`).
4. **Package** (§4.1): turns the build output into distributable files with `--no-build`.
5. **Stage outputs**: upload the artifacts and the reports (§4, §5).

## 4. Outputs: Artifacts and Destinations

### 4.1 Separating "What" From "Where"

| Concept | Meaning | Examples |
|---|---|---|
| **Package** | A form of the build output that can be distributed | `dotnet publish` output (folder or zip), NuGet package (`.nupkg`), container image |
| **Destination** | Where a package is delivered | Pipeline artifact, network share, NuGet feed, container registry (Docker Hub, ACR) |

| Package ↓ / Destination → | Pipeline artifact | Network share | NuGet feed | Container registry |
|---|---|---|---|---|
| Publish output (zip or folder) | ✅ always | ✅ | — | Used as the *input* to an image build |
| NuGet package | ✅ always | ✅ (rare) | ✅ | — |
| Container image | — | — | — | ✅ |

### 4.2 The Key Decision: Build in One Job, Distribute in Others

**The build job's only destination is the pipeline artifact.** Every other destination is a separate public job that downloads that artifact and delivers it.

Reasons:

- **Build once, ship what was tested.** Every destination receives the same files, so the network-share copy and the NuGet package can't differ from what was tested.
- **Destinations have different agent needs:**
  - A network share needs an agent on the right network, usually self-hosted and often Windows.
  - Container builds need Docker, usually on Linux.
  - Publishing to a feed needs neither.
  - One job can only run on one pool. Separate jobs can each take their own `Pool`.
- **Destinations need different credentials and approvals.** Pushing a public NuGet package or a production image is a release decision. A separate job can be a deployment job with an approval gate. This matches the existing anti-pattern rule against mixing build and deploy, and the Terraform plan → verify → apply split.
- **Each job can be reused on its own.** A NuGet push job also works for packages that weren't built by `dotnet_build`, which fits the salad-bar model.
- **Failures are kept separate.** A share that can't be reached doesn't fail the build. It fails one delivery job, which can be re-run without rebuilding.

**Accepted cost:** each destination job downloads the artifact again and starts its own agent, adding a little time per destination.

### 4.3 Packages in the Build Job

`PublishProjects` is replaced by **`Packages`**: a list of objects with a **`Type` discriminator**. This is the case where a discriminator is justified, because each entry type maps to a different command, exactly as with `ConfigSources`.

```yaml
Packages:
  - Type: Publish                 # dotnet publish --no-build
    Project: src/MyApi/MyApi.csproj
    Arguments: '-r linux-x64 --self-contained false'   # optional
    ZipAfterPublish: true         # optional, default true
  - Type: NuGet                   # dotnet pack --no-build
    Project: src/MyLib/MyLib.csproj
    Arguments: ''                 # optional
```

- **Allowed `Type` values in `0.4.0`:**
  - `Publish`.
  - `NuGet`: pack only. Pushing to a feed is a destination (§4.4).
- **Container images are not a `Packages` type.** An image is built *and* pushed by the container destination job, using a `Publish` package as its input (§4.4). That keeps the build job free of Docker.
- **Adding a new `Type` later is a MINOR change**, and the shape doesn't need to change.

### 4.4 Destination Jobs (Future Public Templates)

All of these are separate public jobs. Their exact designs come in later iterations, so this section only records the contract each needs from the build job.

| Future job | Consumes | Does | Agent and credential needs | Gate |
|---|---|---|---|---|
| `jobs/file_share_copy.yml` *(name to agree)* | Any package folder from the artifact | Copies to a UNC or mounted path using `pwsh` `Copy-Item` | A pool with network access to the share. On Linux the share must be mounted | Optional environment |
| `jobs/nuget_push.yml` | `nuget/*.nupkg` | `dotnet nuget push` with `NuGetAuthenticate@1` for Azure Artifacts, or a NuGet service connection for external feeds | Any pool | Environment (recommended for public feeds) |
| `jobs/dotnet_container_build.yml` | `publish/<Project>/` (unzipped) | `Docker@2` build and push, with a Dockerfile that copies the **prebuilt** output. No second `dotnet build` | A pool with Docker. A Docker Registry service connection (Docker Hub or ACR) | Environment for production registries |

**Consequences for the build job's contract:**
- A container build needs the **unzipped** publish output, so the consumer sets `ZipAfterPublish: false` for that project. The container job's schema can't see the build job's config, so this goes in its user doc and is caught by a runtime check that the folder exists.
- The destination jobs never need the SDK, except that `nuget_push` uses the `dotnet` CLI. Iteration 2 already extracted `utils/dotnet_sdk_task_list.yml`, so that job can reuse it.

**Future set menu:** a later `pipelines/dotnet_pipeline.yml` could take a `Destinations` list with a `Type` discriminator (`FileShare`, `NuGetFeed`, `ContainerRegistry`) and expand it into the right jobs and stages. That is where consumers would see "multi-destination" as a single setting. It is not part of `0.4.0`.

## 5. Outputs: Reports

Reports are files produced by tools: test results, coverage, and in future analysis results such as vulnerable-package listings or formatting checks. Each report has one or two destinations:

| Report | Produced by | Native destination | Shared destination |
|---|---|---|---|
| Test results (`.trx`) | `Testing` | Tests tab (published by `DotNetCoreCLI@2`) | Reports artifact |
| Coverage (Cobertura + HTML) | `Testing` with `CollectCoverage` | Coverage tab (`PublishCodeCoverageResults@2`) | Reports artifact |
| *(future)* Vulnerable / outdated packages | A package-audit tool | — | Reports artifact |
| *(future)* SARIF from analysers or scanners | Scan tools / separate jobs | Scans tab, if an extension is used (open question) | Reports artifact |

### 5.1 The Reports Contract (How Tools Plug In)

- The job defines a read-only variable `DotNetReportsDirectory` = `$(Agent.TempDirectory)/reports`.
- **Every tool util takes a `ReportsDirectory` parameter** and writes only to `<ReportsDirectory>/<tool-name>/`, for example `testing/trx/` and `testing/coverage/`. It publishes to its native destination itself.
- The job ends with **one** step that uploads `DotNetReportsDirectory` as the pipeline artifact **`<ArtifactName>_Reports`**, with `condition: succeededOrFailed()`, so reports from a failed run are kept.
- **Adding a tool therefore means adding a util that writes to its own subfolder.** The job and the upload step don't change. This is the reuse rule from iteration 2 applied to reports.
- Reports are **not** placed in the main artifact. Deployment and destination jobs download only what they ship, and reports are never shipped to production by accident.

## 6. Outputs: Logs

Logs are produced throughout. Three levels:

| Level | What | Default |
|---|---|---|
| Step logs | Azure DevOps captures them natively. The template's job is **clear, stable display names** (`DotNet Restore`, `DotNet Test - <title>`, etc.) and no secrets in output | Always on |
| Run summary | One Markdown summary per job via `##vso[task.uploadsummary]`: SDK version used, test counts, coverage %, packages produced. A small inline `pwsh` step | On (cheap, high value) |
| Diagnostics | MSBuild binary log (`-bl`) uploaded as `<ArtifactName>_Diagnostics` with `condition: succeededOrFailed()` | **Off.** Opt in with `Diagnostics.CollectBinaryLog: true`. Binary logs can contain secrets, so the user doc will warn about this |

## 7. Output Contract (Public on Release)

The artifact layout is documented behaviour, so it falls under SemVer from `0.4.0`:

```text
<ArtifactName>/                     # only when Packages is present
  publish/<ProjectName>.zip         # Type: Publish, ZipAfterPublish: true
  publish/<ProjectName>/            # Type: Publish, ZipAfterPublish: false
  nuget/<PackageId>.<Version>.nupkg # Type: NuGet
<ArtifactName>_Reports/             # whenever a tool produced reports
  testing/trx/*.trx
  testing/coverage/Cobertura.xml (+ html/)
<ArtifactName>_Diagnostics/         # only when opted in
  build.binlog
```

The top-level folders are `publish/` and `nuget/`, one per `Type`. Each destination job then knows exactly where to look, and adding a new `Type` adds a new folder without moving existing ones.

## 8. Updated `DotNetBuildConfig` Shape

```yaml
DotNetBuildConfig:
  RelativePathToSolution: string          # required
  BuildConfiguration: string              # optional, default 'Release'
  DotNetSdk: { Version, Install }         # optional (shared, unchanged from iteration 2)
  Restore: { NuGetConfigPath, UseLockedMode }   # optional (job-owned, unchanged)
  ConfigSources: [ ... ]                  # optional (shared, unchanged)

  # Tools
  Testing:                                # optional (shared)
    CollectCoverage: boolean
    Projects: [ { Project, TestRunTitle } ]

  # Artifacts
  Packages:                               # optional, replaces PublishProjects
    - Type: Publish | NuGet
      Project: string
      Arguments: string
      ZipAfterPublish: boolean            # Publish only

  # Logs
  Diagnostics:                            # optional
    CollectBinaryLog: boolean             # default false
```

There is no `Destinations` setting on the build job (§4.2).

## 9. Versioning

A build number is now a real concern, because NuGet packages and registries require a version, and a network share drop usually needs one too.

- **v1 rule:** the version comes from the consumer's codebase (`Directory.Build.props` / `<Version>`), or is passed in `Arguments` (`-p:Version=...`). The template doesn't calculate versions.
- **Future option (open question):** a shared `utils/` concept that works out a SemVer from git (for example a pinned GitVersion `dotnet tool`) and passes it to build, pack and image tagging. That would need `fetchDepth: 0` on checkout.

## 10. Validation Changes

- **`schemas/dotnet_build_config.yml`:**
  - `Packages` is a non-empty list of objects.
  - `Type` is in `Publish` or `NuGet`.
  - `Project` is required.
  - `ZipAfterPublish` is allowed only when `Type: Publish`.
  - `Diagnostics.CollectBinaryLog` is a boolean.
  - All checks use `startsWith` and presence gating.
- The util schemas are unchanged.

## 11. Delivery Slices

| Release | Slice |
|---|---|
| `0.4.0` | `jobs/dotnet_build.yml` with `Packages` (`Publish`, `NuGet`), the reports artifact and run summary, and opt-in diagnostics |
| `0.4.x` → `0.5.0` | `jobs/nuget_push.yml` (most self-contained, any pool) |
| next MINOR | `jobs/dotnet_container_build.yml` (Docker Hub / ACR) |
| next MINOR | File share copy job, once agent and network access is confirmed |
| later | `pipelines/dotnet_pipeline.yml` with a `Destinations` list |

## 12. Decisions Changed From Iteration 2

| Iteration 2 | Iteration 3 | Why |
|---|---|---|
| `PublishProjects` (list of objects) | `Packages` with a `Type` discriminator | Several package kinds (publish, pack) now exist, each mapping to a different command |
| Artifact layout: one entry per project at the root | `publish/` and `nuget/` folders | Destination jobs need predictable locations by kind |
| Test reports only in the Tests and Coverage tabs | Also a `<ArtifactName>_Reports` artifact through a shared reports contract | Lets later jobs and people use them, and gives tools a plug-in point |
| Binary logs out of scope | Opt-in diagnostics artifact | Logs are an output in their own right; off by default because of the secrets risk |
| Container image as a future build-type option | A future destination job that consumes `Publish` output | Build once, a separate pool, and a registry push is a release decision |

## 13. Open Questions

1. **Network share:**
   - Which share(s)?
   - Which agents can reach them?
   - Windows only?
   - Does a copy count as a deployment that needs an approval?
2. **NuGet feeds:** Azure Artifacts only, or also nuget.org or other external feeds?
3. **Docker Hub vs ACR:** Is Docker Hub the real target, or is ACR also wanted? This affects the service-connection guidance and the tagging rules.
4. **Versioning:** Is consumer-supplied versioning enough for `0.4.0`, or is a shared version calculation needed before NuGet push ships?
5. **SARIF / Scans tab:** The Scans tab needs the free Microsoft "SARIF SAST Scans Tab" extension. Is that acceptable under the "no paid extensions" rule, given it is free?
6. **Is a reports artifact on every run acceptable** for storage and retention, or should it be opt-out?
