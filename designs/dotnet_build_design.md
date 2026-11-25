# Design: `jobs/dotnet_build.yml`

**Status:** Draft, iteration 2 · **Target release:** `0.4.0` (MINOR: a new public job template) · **Replaces:** iteration 1 and the trial on `feature/0.4.0/dotnet-build`

## 1. Purpose and Scope

`jobs/dotnet_build.yml` is a public, behavioural job template. It restores and builds a .NET solution once, tests that same build, and optionally publishes chosen projects as one pipeline artifact. Consumers adopt the outcome ("build my .NET app") rather than wiring up `dotnet` steps themselves.

This job is CI only:

- **Container image builds** are needed by teams, but they are deliberately left for a later job. This design must not block them (see §6.3).
- **Deployment** is separate. It will consume this job's artifact through the contract in §8.

## 2. Design Drivers

This job is the first new template since the design philosophy was written down. `jobs/terraform_build.yml` was the prototype the principles were _discovered_ from, so it is a reference for plumbing only, not a model to copy. The newer `jobs/terraform_deploy.yml` and the `ConfigSources` pieces reflect current practice.

| Source                                                                                                                                                                      | What it means for this job                                                                                                                      |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| [Behavioural Solutions](../docs/developers/explanation/design-philosophy.md#behavioural-solutions-not-building-blocks)                                                      | One job that delivers "build, test, package". No public `dotnet_restore`- or `dotnet_test`-style building blocks                                |
| [Public vs Internal](../docs/developers/explanation/design-philosophy.md#public-vs-internal) and the [Versioning Policy](../docs/developers/reference/versioning-policy.md) | The **configuration shape** and the **artifact layout** are public and expensive to change. Internal templates are cheap to move                |
| [Group Related Inputs Into Validated Objects](../docs/developers/explanation/design-philosophy.md#group-related-inputs-into-validated-objects)                              | One `DotNetBuildConfig` object, made of sub-objects, each validated by its own schema                                                           |
| [Fail Fast at Compile Time](../docs/developers/explanation/design-philosophy.md#fail-fast-at-compile-time)                                                                  | Every field is validated by a schema. Only things that can't be known at compile time are checked at runtime                                    |
| [Protect Template-Internal State](../docs/developers/explanation/design-philosophy.md#protect-template-internal-state)                                                      | Every job variable uses list syntax with `readonly: true`                                                                                       |
| [Defensive Rendering](../docs/developers/explanation/design-philosophy.md#defensive-safe-rendering)                                                                         | An optional field that is left out renders nothing, never an empty or half-built step                                                           |
| [Flexible Execution Paths](../docs/developers/explanation/design-philosophy.md#flexible-execution-paths)                                                                    | A single input switches between installing the SDK and verifying it                                                                             |
| [Double Wrapping](../docs/developers/explanation/double-wrapping.md)                                                                                                        | One comprehensive `tasks/dotnet_cli.yml` with a `Command` enum. No `dotnet_build.yml` or `dotnet_test.yml` task wrappers                        |
| [Cross-Platform and Open-Source](../docs/developers/explanation/design-philosophy.md#cross-platform-and-open-source-by-default)                                             | Built-in tasks plus `pwsh`. Runs on Windows and Linux. No Marketplace extensions                                                                |
| [What to Template](../docs/developers/explanation/design-philosophy.md#what-to-template)                                                                                    | Only extract logic that benefits from reuse, validation or a stable interface                                                                   |
| `0.2.0` lesson (`KeyVaultConfig` → `ConfigSources`)                                                                                                                         | A single-object shape had to be deprecated and migrated. **Use list-of-objects shapes from day one** wherever more than one item is plausible   |
| `0.3.1` lesson (schema split)                                                                                                                                               | **Validate where the data is used.** Each reusable piece validates its own object. The job schema validates only the fields the job uses itself |
| `0.3.1` lesson (step lists)                                                                                                                                                 | Expand injection steps directly (`- ${{ parameters.X }}`), not through an `each` loop                                                           |

## 3. The Reuse Model

### 3.1 The Pattern `ConfigSources` Established

`ConfigSources` is the repository's working example of a reusable concept. It is built from four pieces:

| Piece                     | `ConfigSources` example                              | Role                                                                                                |
| ------------------------- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Public object shape       | `ConfigSources:` list on `TerraformDeploymentConfig` | What consumers write. This is the expensive part to change                                          |
| Shared schema             | `schemas/config_sources.yml` (emits under `steps:`)  | Validates the object wherever it is used                                                            |
| Self-validating step list | `utils/config_sources_task_list.yml`                 | Includes its own schema, then emits the steps. Any job adds the concept with one template reference |
| Shared definition doc     | `docs/definition_docs/shared/config_sources.md`      | Documented once, and linked from every job that uses it                                             |

The job using it does only two things:

- It decides _whether_ to include the concept: `${{ if parameters.Config.ConfigSources }}`.
- It passes the sub-object through.

The job's own schema does not re-validate `ConfigSources`.

### 3.2 Extraction Rule for This Job

The extraction rule follows from the cost difference above:

1. **Design every sub-object shape for reuse now.** Public shapes are costly to change later.
2. **Extract a piece into the `utils/` + `schemas/` + `docs/definition_docs/shared/` pattern now** only when all three are true:
   - It is a self-contained concept.
   - It has its own validation or branching logic.
   - A second consuming job is already known.
3. **Otherwise keep it inline in the job**, behind a sub-object of the same shape. Moving it into `utils/` later is an internal change (PATCH) because consumers see no difference.
4. **Never extract a single task with no extra logic** into a `utils/` template. That is double-wrapping. Single built-in tasks belong in `tasks/`.

### 3.3 Pieces Identified

| Concept                                                              | Sub-object        | Second known consumer                                | Decision                                                                                                           |
| -------------------------------------------------------------------- | ----------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Secrets and configuration loading                                    | `ConfigSources`   | Already shared                                       | **Reuse** `utils/config_sources_task_list.yml` as it is                                                            |
| .NET SDK provisioning (install or verify)                            | `DotNetSdk`       | Container build job, future NuGet pack job           | **Extract now:** `utils/dotnet_sdk_task_list.yml`                                                                  |
| Running tests and reporting results and coverage                     | `Testing`         | Container build job (test before building the image) | **Extract now:** `utils/dotnet_test_task_list.yml`                                                                 |
| Package restore (feed auth + restore)                                | `Restore`         | Probably the container build job                     | **Inline for now.** It is two steps tied to the build's restore-once rule. Extract when the container job arrives  |
| Publish to artifact                                                  | `PublishProjects` | .NET deploy job consumes the _output_, not the steps | **Inline.** The artifact contract (§8) is the reusable part                                                        |
| Job variable mappings (`JobsVariableMappings` in `terraform_deploy`) | —                 | Would be shared                                      | **Not in v1.** Candidate for its own extraction PR, so the deploy and build jobs end up sharing one implementation |

## 4. Public Interface

### 4.1 Template Parameters

The plumbing parameters are flat and match the existing jobs exactly, so consumers see one consistent shape across the library.

| Parameter                   | Type       | Default            | Notes                                                                                            |
| --------------------------- | ---------- | ------------------ | ------------------------------------------------------------------------------------------------ |
| `ArtifactName`              | `string`   | `'DotNetArtifact'` | Also the job-name suffix. Public: it is used in `dependsOn` and artifact downloads               |
| `Condition`                 | `string`   | `succeeded()`      |                                                                                                  |
| `DependsOn`                 | `object`   | `[]`               |                                                                                                  |
| `Pool`                      | `string`   | `''`               | When empty, the pipeline's pool is used                                                          |
| `DotNetBuildInjectionSteps` | `stepList` | `[]`               | Runs after the SDK, secrets and feed authentication are ready, before restore. Expanded directly |
| `DotNetBuildConfig`         | `object`   | _none (required)_  | `displayName` ends with `(required)` and links the definition doc                                |

Unlike `terraform_build`, there is no flat path or version parameter, and no `AdditionalFilesToPackage` equivalent. Everything .NET-specific lives in the config object.

### 4.2 `DotNetBuildConfig` Shape

```yaml
DotNetBuildConfig:
  RelativePathToSolution: string # required: .sln, .slnx or .csproj, relative to the repository root
  BuildConfiguration: string # optional, default 'Release'

  DotNetSdk: # optional object (shared: dotnet_sdk.md)
    Version: string #   optional, default '' (use global.json)
    Install: boolean #   optional, default true (false = verify only, never install)

  Restore: # optional object (job-owned)
    NuGetConfigPath: string #   optional
    UseLockedMode: boolean #   optional, default false

  Testing: # optional object (shared: dotnet_testing.md)
    CollectCoverage: boolean #   optional, default true
    Projects: #   required when Testing is present; list of objects
      - Project: string #     required: project path or glob
        TestRunTitle: string #     optional, default 'DotNet Test - <Project>'

  PublishProjects: # optional list of objects (job-owned)
    - Project: string #   required
      Arguments: string #   optional: extra publish arguments for this project only
      ZipAfterPublish: boolean #   optional, default true

  ConfigSources: [...] # optional (shared: config_sources.md, used as is)
```

**Shape decisions:**

- **`Testing.Projects` and `PublishProjects` are lists of objects, not lists of strings.** This applies the `ConfigSources` lesson. New optional fields can be added per entry later as MINOR changes, such as a test `Filter`, or a per-project `RuntimeIdentifier` for when a solution publishes a Linux API and a Windows worker. A list of strings can only grow through a breaking change.
- **No `Type` discriminator in v1.** `ConfigSources` needed one because entries map to different tasks. Test and publish entries all map to the same task, so a discriminator would be unused. Adding an optional `Type` later, with a default, is still a MINOR change.
- **Leaving a sub-object out switches the behaviour off.** There are no `RunTests` or `EnablePublish` flags. If there's no `Testing`, no tests run. If there's no `PublishProjects`, no artifact is produced. This avoids flags that can contradict the data.
- **Boolean names:** `Install` and `UseLockedMode` are verb-led, and `CollectCoverage` and `ZipAfterPublish` read as actions. `DotNetSdk.Install` replaces iteration 1's `DemandsProvided`.

### 4.3 Example

```yaml
jobs:
  - template: jobs/dotnet_build.yml@AzDOPipelineTemplates
    parameters:
      ArtifactName: "MyApi"
      DotNetBuildConfig:
        RelativePathToSolution: "MyApi.sln"
        Testing:
          Projects:
            - Project: "tests/MyApi.UnitTests/MyApi.UnitTests.csproj"
              TestRunTitle: "Unit Tests"
        PublishProjects:
          - Project: "src/MyApi/MyApi.csproj"
```

## 5. Job Composition

```yaml
jobs:
  - template: /schemas/dotnet_build_config.yml # job-owned fields only, emits under jobs:
    parameters:
      DotNetBuildConfig: ${{ parameters.DotNetBuildConfig }}
      ArtifactName: ${{ parameters.ArtifactName }}

  - job: DotNetBuild_${{ parameters.ArtifactName }}
    displayName: "Build '${{ parameters.ArtifactName }}' .NET Artifact"
    condition: ${{ parameters.Condition }}
    dependsOn: ${{ parameters.DependsOn }}
    ${{ if parameters.Pool }}:
      pool: ${{ parameters.Pool }}
    workspace:
      clean: all
    variables: # list syntax, all readonly: true
      # RepositoryCheckoutFolderName, RepositoryDirectory, DotNetSolutionPath,
      # DotNetBuildConfiguration, DotNetPublishDirectory
    steps:
      - checkout: self # clean: true, path: $(RepositoryCheckoutFolderName)
      - download: none
      - template: /utils/dotnet_sdk_task_list.yml # always, with DotNetSdk or {} (defaults)
      - ${{ if parameters.DotNetBuildConfig.ConfigSources }}:
          - template: /utils/config_sources_task_list.yml
      - template: /tasks/nuget_authenticate.yml
      - ${{ parameters.DotNetBuildInjectionSteps }}
      - template: /tasks/dotnet_cli.yml # Command: restore
      - template: /tasks/dotnet_cli.yml # Command: build
      - ${{ if parameters.DotNetBuildConfig.Testing }}:
          - template: /utils/dotnet_test_task_list.yml
      - ${{ each project in parameters.DotNetBuildConfig.PublishProjects }}:
          - template: /tasks/dotnet_cli.yml # Command: publish
      - ${{ if parameters.DotNetBuildConfig.PublishProjects }}:
          - template: /tasks/publish_pipeline_artifact.yml
```

**The job doesn't need `CheckoutAlias`** because it uses no `scripts/` files. Runtime logic stays small and runs as inline `pwsh`. If a script file is needed later, adding an optional `CheckoutAlias` with the standard default is a MINOR change.

**Order of steps before restore:** SDK, then secrets, then feed authentication, then injection steps. Consumer injection steps can then rely on `dotnet`, loaded secrets and authenticated feeds being available.

## 6. Building Blocks

### 6.1 New `tasks/` Templates (Internal, One Per Built-in Task)

Each has the standard in-file documentation block, the standard parameter property order, and a `See:` link to the Microsoft task reference.

| Template                          | Wraps                          | Notes                                                                                                                                                                                                          |
| --------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tasks/dotnet_cli.yml`            | `DotNetCoreCLI@2`              | **One comprehensive template** with a `Command` enum (`restore`, `build`, `test`, `publish`). Command-specific inputs are emitted only when relevant, and `publishWebProjects` is always `false` for `publish` |
| `tasks/dotnet_installer.yml`      | `UseDotNet@2`                  | Selects `useGlobalJson: true` or an explicit `version` at compile time                                                                                                                                         |
| `tasks/nuget_authenticate.yml`    | `NuGetAuthenticate@1`          | Does nothing when no private feeds are used                                                                                                                                                                    |
| `tasks/publish_code_coverage.yml` | `PublishCodeCoverageResults@2` | Cobertura                                                                                                                                                                                                      |

The job also reuses `tasks/powershell.yml` and `tasks/publish_pipeline_artifact.yml`.

### 6.2 New Reusable Concepts (`utils/` + `schemas/` + `docs/definition_docs/shared/`)

**`utils/dotnet_sdk_task_list.yml`**

- Includes `schemas/dotnet_sdk.yml` (steps-level).
- When `Install` is true, it uses `tasks/dotnet_installer.yml` with `Version` or `global.json`.
- When `Install` is false, it runs an inline `pwsh` check (`dotnet --version` from the repository directory, so `global.json` is respected). It fails with a clear message and never falls back to installing.
- Documented in `docs/definition_docs/shared/dotnet_sdk.md`.

**`utils/dotnet_test_task_list.yml`**

- Includes `schemas/dotnet_testing.yml` (steps-level).
- For each entry in `Projects`, it emits one `tasks/dotnet_cli.yml` `test` step: `--no-build --no-restore`, the configuration passed in, `--logger trx`, `--collect "XPlat Code Coverage"` when coverage is on, `publishTestResults: true`, and the `testRunTitle`.
- When `CollectCoverage` is true, it adds `tasks/publish_code_coverage.yml` with `condition: succeededOrFailed()`.
- It takes `BuildConfiguration` as a separate parameter, so any job can pass in its own configuration.
- Documented in `docs/definition_docs/shared/dotnet_testing.md`.

Both utils carry the standard `utils/` in-file documentation block. Both get a `*.CompileTests.ps1` and a compiled-YAML snapshot folder next to them, as `utils/config_sources_task_list` has.

### 6.3 How Container Builds Will Fit Later (Not v1)

A future `jobs/dotnet_container_build.yml` would:

- Reuse `utils/dotnet_sdk_task_list.yml`, `utils/dotnet_test_task_list.yml` and `utils/config_sources_task_list.yml` unchanged.
- Extract restore at that point, as an internal PATCH-level change.
- Accept the same `DotNetSdk`, `Testing` and `ConfigSources` sub-objects, so consumers write the same configuration in both jobs.

Nothing in v1 has to change for this to happen.

## 7. Validation

**Validate where the data is used** (the `0.3.1` lesson):

| Schema                            | Level    | Validates                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| --------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `schemas/dotnet_build_config.yml` | `jobs:`  | `RelativePathToSolution` is required and a scalar. `BuildConfiguration` is a scalar. If `Restore` is present, it is an object with a scalar `NuGetConfigPath` and a boolean `UseLockedMode`. If `PublishProjects` is present, it is a non-empty list of objects, each with a required scalar `Project`, an optional scalar `Arguments`, and an optional boolean `ZipAfterPublish`. `DotNetSdk` and `Testing`, if present, are objects (shape only) |
| `schemas/dotnet_sdk.yml`          | `steps:` | `Version` is a scalar, and `Install` is a boolean                                                                                                                                                                                                                                                                                                                                                                                                  |
| `schemas/dotnet_testing.yml`      | `steps:` | `Projects` is required and a non-empty list of objects, each with a required scalar `Project` and an optional scalar `TestRunTitle`. `CollectCoverage` is a boolean                                                                                                                                                                                                                                                                                |
| `schemas/config_sources.yml`      | `steps:` | Existing schema, unchanged                                                                                                                                                                                                                                                                                                                                                                                                                         |

**Schema rules:**

- Use the patterns from [Schema Validation](../docs/developers/reference/schema-validation.md): `startsWith` for type checks (never `contains`), and presence-gating for optional fields. Prefix errors with `'<ArtifactName>' artifact error:` in the job schema, and with `Invalid DotNetSdk:` or `Invalid Testing:` in the shared schemas. End every error with `See: <definition doc>`.
- **Runtime-only checks:** whether `global.json` exists or the SDK is present. These are handled by `dotnet_sdk_task_list.yml`.

**Related finding (separate PATCH):** `schemas/config_sources.yml` still uses `contains` for its type checks, which the schema-validation reference warns against.

## 8. Artifact Contract (Public)

The artifact layout is documented behaviour, so it falls under SemVer once released:

- There is one pipeline artifact per job, named `ArtifactName`. It exists only when `PublishProjects` is present.
- There is one entry per `PublishProjects` item, named after the project: `<ProjectName>.zip` when `ZipAfterPublish` is true, otherwise a `<ProjectName>/` folder.
- Azure Functions zips have the publish contents at the root, with `host.json` at the top level.
- The deployment type is framework-dependent unless `Arguments` says otherwise. If `Arguments` sets a runtime identifier, it must also set `--self-contained true|false`. The user doc will state this. The template does not parse `Arguments`.
- Build version stamping is not part of v1.

## 9. Behaviour Decisions

| Topic                       | Decision                                                                                                                                                                                                          |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Build once                  | Restore runs once. Build uses `--no-restore`. Test and publish use `--no-build --no-restore` with the same configuration                                                                                          |
| Test failures               | The `DotNetCoreCLI@2` `test` step publishes its TRX results even on failure, and still fails. Later test steps use the default `succeeded()`, so the first failing suite stops the rest. Coverage still publishes |
| Publish after a failed test | No. Publish steps use `succeeded()`                                                                                                                                                                               |
| Coverage merging            | Use the built-in `PublishCodeCoverageResults@2` over all Cobertura files. Add ReportGenerator, as a pinned `dotnet tool` run inline, **only if** the multi-project test fixture shows merged numbers are wrong    |
| Test runner                 | Assume VSTest (classic `dotnet test`) for v1. Microsoft.Testing.Platform is out of scope                                                                                                                          |
| SDK floor                   | Minimum `8.x`. Each newer major is supported once a test fixture passes on it                                                                                                                                     |
| Display names               | Use `DotNet Restore`, `DotNet Build`, `DotNet Test - <title>` and `DotNet Publish - <project>`. Use ".NET SDK" in prose. Never write "Dotnet" or "DOTNET"                                                         |
| Secrets                     | No credentials in `nuget.config`. Use `NuGetAuthenticate@1` for feeds and `ConfigSources` for everything else                                                                                                     |

## 10. What Becomes Public on Release

The [Versioning Policy](../docs/developers/reference/versioning-policy.md#subtle-breaking-changes) treats these as breaking if they change after `0.4.0`, so they need agreement before release:

- The job name `DotNetBuild_<ArtifactName>`, which consumers use in `dependsOn`.
- Every parameter and config field name, and every default.
- The order of steps relative to the injection point.
- The artifact layout in §8.

## 11. Delivery

The [Branching Model](../docs/developers/reference/branching-model.md) asks for small, short-lived branches. Work goes on `feature/<name>`; nested names such as `feature/0.4.0/...` are not used.

| PR       | Contents                                                                                                                                                                                                                                                                                            | Release effect                   |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| 1        | The four `tasks/` templates, with in-file documentation                                                                                                                                                                                                                                             | None (internal only)             |
| 2        | `utils/dotnet_sdk_task_list.yml` and `utils/dotnet_test_task_list.yml`, their schemas, compile tests and snapshots, and the `shared/` definition docs                                                                                                                                               | None (internal only)             |
| 3        | `jobs/dotnet_build.yml`, `schemas/dotnet_build_config.yml`, the job compile tests and snapshots, and runtime fixtures under `tests/jobs/dotnet_build/` (Linux and Windows; single and multiple test projects; publish and no publish; `Install: false`) using `tests/shared_resources/basic_dotnet` | `CHANGELOG.md` `### Added` entry |
| 3 (docs) | `docs/user-docs/jobs/dotnet_build.md` with live-example links, `docs/definition_docs/dotnet_pipeline/dotnet_build_config.md`, the README salad-bar table, and `docs/user-docs/README.md`                                                                                                            | —                                |

- **New test pipelines:** new `*_test.yml` fixtures need the `cicd/` Terraform applied before they run as Azure DevOps pipelines. This is a maintainer step ([Branching Model → Current Scaling Limits](../docs/developers/reference/branching-model.md#current-scaling-limits)).
- **Reuse from the trial branch:** keep the example project and the fixtures. Re-implement the job and schema to this design.

## 12. Out of Scope for v1

- Container images (future job, see §6.3).
- Deployment.
- NuGet pack and push.
- .NET Framework.
- dacpac, EF migrations, SBOM, code signing.
- Mutation, browser and end-to-end tests.
- Coverage thresholds.
- Security scanning (a separate job).
- NuGet caching (`Cache@2` keyed on the hash of `packages.lock.json`). Candidate for a later MINOR release.
- MSBuild binary logs (they risk containing secrets).
- Microsoft.Testing.Platform.
- Extracting `JobsVariableMappings` (separate PR).

## 13. Open Questions

1. **Shared definition doc names:** should the shared docs be named `dotnet_sdk.md` and `dotnet_testing.md`, or should the folder be split into `shared/` and `dotnet_shared/`?
2. **Test suite failures:** should every test suite run even when an earlier one fails? That needs a "build succeeded" marker variable for the test conditions to check, and it couples the test util to the job. The proposal is "no" for v1.
3. **Agent pools:** which pools and OS images must be supported at release: `Mare Nectaris`, Microsoft-hosted, or both?
