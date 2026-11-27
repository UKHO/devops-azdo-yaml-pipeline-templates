# Compile Test Plan

**Status:** Draft for review. This plan carries out the decisions taken on [Compile Test Audit](compile-test-audit.md). It must be finished **before** the [Schema Validation Library](schema-validation-library.md) work starts, because the schema tests become that migration's regression suite.

## Baseline: `feature/test-framework-performance-boost`

This plan is based on the performance branch, not `main`. That branch changes the test framework only; no `*.CompileTests.ps1` or `*_test.yml` file changes. What matters here:

| Change | Effect on this plan |
| ------ | ------------------- |
| `Invoke-CompileYamlBatch` (`Core.CompileYaml.ps1`) sends every case of a file (valid and invalid) **concurrently**, up to `TestExecution.MaxConcurrentRequests` (default 8). It reuses one `HttpClient`, retries network failures, and backs off on HTTP 429/503 (5 attempts). Results are reported in declared order. | Adding cases now costs little wall-clock time, so the reason to trim is **maintenance**, not run time. The trimming in phase 3 stays, but the size estimates below are about upkeep. |
| Directory tests (`tests/jobs`, `tests/pipelines`) are batched the same way. | No change. |
| `Run-AllCompileTests.ps1` still runs files **one after another**, and resets `LASTEXITCODE` per file. | Concurrency is per file. With many small new test files (phase 5), a file with 4 cases waits for the slowest of 4. A further speed-up (one batch across all files) is possible but out of scope. |
| A CI pipeline, `cicd/pipelines/compile_tests.yml`, runs `Run-AllCompileTests.ps1` on every pull request to `main` (drafts included) and on `main`. It is a required status check. `TargetBranch` comes from `System.PullRequest.SourceBranch` / `Build.SourceBranch`. | Every phase is verified by CI on its pull request. Templates are resolved from the **pushed source branch**, so a pull request's tests always run against its own templates. |
| Pass criteria (`Get-ValidPassCriteriaFunction`, `Get-InvalidPassCriteriaFunction`) are **unchanged**. | Every framework fix in phase 1 (F1–F5) is still needed. |
| Parameter serialisation is unchanged: object/array parameters go as JSON strings, scalars as `[string]$value` (so a PowerShell `$true` becomes `"True"`). | Confirms that the REST path never passes typed scalars at the top level, so the YAML-literal cases (F4) are the only way to test the consumer's path. |

Framework observations from the review of that branch (not blockers; raise them on its pull request):

- **Throttle back-off blocks the whole batch.** On a 429/503 the loop calls `Start-Sleep` before dequeuing again, so completed responses from other requests wait too. Recording a "not before" time per request and skipping it until then would keep the rest flowing.
- **F3 (duplicate descriptions) must run before the batch is built**, in `Invoke-ParameterisedTests`, so a bad file fails without making any compile calls.

## Decisions

1. **Schemas own validation.** Each `schemas/<name>.CompileTests.ps1` holds essentially every validation case for that schema. A template that calls a schema (`jobs/*`, `utils/config_sources_task_list.yml`) keeps **exactly one** invalid case. It proves the schema is called and that its error reaches the caller.
2. **Duplicates go.** Delete any job- or util-level case that repeats a schema case. The same applies to cases that run the same template branch with different data.
3. **Basic parameters are tested everywhere.** Every template gets cases for its standard parameters: required parameters missing, `Condition`, `DependsOn`, `Pool` and similar, wherever the template declares them.
4. **Every gap is filled**, including the schema gaps listed in the audit.
5. **Every template gets a test file.** That includes the eight untested `tasks/*.yml` files, `utils/concat_wrap_list.yml`, `stages/*.yml` and `pipelines/terraform_pipeline.yml`.

## Test-case standards

These apply to every file touched by this plan, and to new files.

| Rule | Detail |
| ---- | ------ |
| One test file per template | `<template>.CompileTests.ps1` next to `<template>.yml`. A second file is allowed only for a genuinely separate code path, as in `tasks/terraform.ServiceConnection.CompileTests.ps1`. |
| Unique, specific descriptions | Say what is tested, not how: "Condition is applied to the task", not "with custom condition". |
| Invalid cases always have `ErrorMessage` | Enforced by the framework (phase 1). Use the exact text Azure DevOps returns. |
| Valid cases assert output | Every valid case in a non-schema template needs at least one `ExpectedYaml` entry that proves the behaviour in its description. Schema valid cases only need to compile, because schemas emit nothing. |
| One case per branch | Each `${{ if }}` / `${{ else }}` / `${{ each }}` branch gets one case that enters it, and one that does not if that matters. Do not repeat a branch with different data. |
| Defaults are tested once | One case with only the required parameters, asserting the default values in the output. |
| Standard parameters | For each one the template declares: **required parameter missing** (one case each), **`Condition`** (set and asserted), **`DependsOn`** (set and asserted), **`Pool`** (set and asserted), and **name/slug uniqueness** where the template builds names. |
| YAML-literal path | Templates that take booleans or numbers inside an object parameter get at least one case whose value is a YAML literal (phase 1, F4), not only a JSON parameter. |

## Phase 1: Framework

All of this is in `tests/framework/`. Each change needs its own test in `tests/framework/example_echo_task.CompileTests.ps1`, or in a new framework self-test.

| ID | Change |
| -- | ------ |
| F1 | An invalid case without `ErrorMessage` (or with `""`) **fails**, with a clear "missing ErrorMessage" message. |
| F2 | `ErrorMessage` is matched **literally** (`.Contains()`). `ExpectedYaml` keeps wildcard matching, because existing cases rely on `*`. Add `ExpectedYamlLiteral` for exact substrings that contain `*`, `?`, `[` or `]`. |
| F3 | Duplicate `Description` values within a file fail the run before any compile call. |
| F4 | Optional `YamlParameters` on a case: YAML text that a standard transform embeds as the template's parameters, so values follow the consumer's YAML-literal path. Design it in this phase; the cases that use it are added in phase 4. |
| F5 | Optional `NotExpectedYaml` on valid cases, to assert that something is **absent** (for example, no manual verification job for `PlanOnly`). Today absence cannot be checked. |

## Phase 2: Fix tests that pass for the wrong reason

| File | Change |
| ---- | ------ |
| `jobs/terraform_gated_deployment.CompileTests.ps1` | Add `ErrorMessage` to "missing required EnvironmentName parameter", "missing required TerraformDeploymentConfig parameter" and "invalid CheckoutAlias value". |
| `tasks/terraform.CompileTests.ps1` | Rename the three cases called "custom command with missing custom command" to match what they test. |
| All files | Run once after F1–F3 and fix anything they flag. |

## Phase 3: Remove duplicates

One pull request per file. Run the file before and after, and record the case count in the pull request.

**Validation duplicates** (decision 1). Keep one wiring case per caller:

| File | Remove | Keep (wiring case) |
| ---- | ------ | ------------------ |
| `jobs/terraform_gated_deployment` | AzDOEnvironmentName missing; invalid RunMode; invalid VerificationMode; VerificationTimeoutBehaviour; VerificationTimeoutInMinutes; ApplyEvenIfNoChanges ×3 | RunMode missing |
| `jobs/terraform_gated_destroy` | AzDOEnvironmentName missing; invalid RunMode; VerificationTimeoutBehaviour; VerificationTimeoutInMinutes | RunMode missing |
| `jobs/terraform_deploy` | invalid VerificationMode; partial Key Vault configuration | AzDOEnvironmentName missing |
| `jobs/terraform_destroy` | – | KeyVaultConfig not supported |
| `utils/config_sources_task_list` | unsupported Type; missing ServiceConnection | empty array |

**Same-branch duplicates:**

| File | Remove | Keep |
| ---- | ------ | ---- |
| `jobs/terraform_deploy` | "Different Terraform Version"; "Single Variable File"; "Variable Group"; "Backend Configuration" (single); "Single Output Variable"; "Default Artifact Name" (folded into the defaults case) | One case each |
| `jobs/terraform_gated_deployment` | "default Terraform version"; "default TerraformArtifactName" (both folded into a defaults case); "Complex scenario"; "Quick deploy scenario"; ApplyEvenIfNoChanges "true and VerifyOnDestroy", "true and VerifyDisabled", "true and custom TerraformArtifactName", "PlanOnly with false", "ApplyOnly with false" | ApplyEvenIfNoChanges absent / `false` / `true` |
| `tasks/terraform_installer` | Two of the four valid semantic versions | `0.15.0`, `1.11.3` |

**Missing-parameter cases in schemas.** Keep them. Under decision 3, every template tests its own required parameters, and schemas are templates. This reverses the audit's suggestion.

**Directory tests** (`tests/jobs/**`). Keep `double_*` (name clashes), the `configsources` and mapping scenarios, and anything not covered by a parameterised case. Remove a `*_basic_test.yml` only if a parameterised case asserts the same scenario. List each removal in the pull request.

## Phase 4: Fill gaps in existing test files

### Schemas (decision 1: these hold the validation cases)

| File | Add |
| ---- | --- |
| `schemas/terraform_destroy_config` | **Invalid:** AzDOEnvironmentName missing; AzDOEnvironmentName empty; AzureServiceConnection empty; BackendConfig not a map; BackendConfig empty key; BackendConfig empty value; EnvironmentVariableMappings not a map; EnvironmentVariableMappings empty key; EnvironmentVariableMappings empty value; VariableFiles not a list; VariableFiles non-string item. **Valid:** all optional fields set; empty BackendConfig (pins today's "empty is allowed" behaviour). |
| `schemas/terraform_deploy_config` | **Invalid:** BackendConfig not a map; EnvironmentVariableMappings not a map; ConfigSources set together with KeyVaultConfig where only one member is set (pins today's trigger). **Valid:** empty BackendConfig; empty VariableFiles; `KeyVaultConfig: {}` alone. |
| `schemas/terraform_gated_deployment_config` | **Valid:** VerificationMode `VerifyOnDestroy` and `VerifyDisabled` with PlanVerifyApply (the schema has its own copy of the list). **Invalid:** VerificationTimeoutInMinutes as a non-numeric string (pin today's behaviour, whatever the error is). **YAML-literal (F4):** ApplyEvenIfNoChanges `true`; VerificationTimeoutInMinutes `30`. |
| `schemas/terraform_gated_destroy_config` | **Invalid:** VerificationTimeoutInMinutes as a non-numeric string. **YAML-literal (F4):** VerificationTimeoutInMinutes `30`. |
| `schemas/config_sources` | **Invalid:** Type missing; ServiceConnection not a string; Name not a string; valid first entry with an invalid second entry. **Valid:** two entries; RunAsPreJob `false`. **YAML-literal (F4):** RunAsPreJob `true`. |

### Standard parameters (decision 3)

"Not set in tests" comes from a scan of each template's `parameters:` against its test file.

| File | Add |
| ---- | --- |
| `jobs/terraform_build` | `Condition`; `DependsOn`; `Pool` |
| `jobs/terraform_deploy` | `DependsOn`; `Pool` |
| `jobs/terraform_destroy` | `Condition`; `DependsOn`; `Pool`; `TerraformVersion`; defaults case |
| `jobs/terraform_gated_deployment` | `DependsOn` (asserted on the first job only) |
| `jobs/terraform_gated_destroy` | `Condition`; `DependsOn`; `TerraformVersion` |
| `jobs/manual_verification` | `DependsOn` |
| `tasks/terraform` | `WorkingDirectory`, in both the plain and the `ServiceConnection` file |

### Branch coverage in existing files

Before writing cases, list every `${{ if }}` / `${{ else }}` / `${{ each }}` in the template and mark which case enters it. Commit that list as a comment block at the top of the test file:

```powershell
# Branch coverage
#   L51  if RunMode in (PlanVerifyApply, PlanOnly)  -> "PlanOnly mode - includes only Plan job"
#   L65  if RunMode == PlanVerifyApply              -> "PlanVerifyApply mode - ..."
```

This is a manual stand-in for a coverage tool and keeps the "one case per branch" rule reviewable. Templates with the most branches go first: `jobs/terraform_deploy.yml` (19), `tasks/terraform.yml` (13), `jobs/terraform_destroy.yml` (12), and `jobs/terraform_gated_*.yml` (7 each).

## Phase 5: New test files (decision 5)

| Template | Branches | Planned cases |
| -------- | -------: | ------------- |
| `tasks/azure_web_app.yml` | 5 | Required parameters missing (`AzureServiceConnection`, `AppName`, …); defaults case; one case per branch (slot/ASE deployment, `RuntimeStack`, `StartUpCommand`, `AppSettings`, `ConfigurationStrings`); `AppType` and `DeploymentMethod` allowed values. |
| `tasks/copy_files.yml` | 1 | Required parameters missing; defaults; the one branch; boolean options (`CleanTargetFolder`, `OverWrite`, `FlattenFolders`, `PreserveTimestamp`) in one case. |
| `tasks/delay.yml` | 0 | Default; custom `delayForMinutes`. |
| `tasks/download_pipeline_artifact.yml` | 0 | Required missing; defaults; all parameters set. |
| `tasks/file_transform.yml` | 0 | Required missing; defaults; all parameters set. |
| `tasks/manual_validation.yml` | 2 | Defaults; `Condition`; each branch (`NotifyUsers` / `Approvers`); `OnTimeoutBehaviour` allowed values; `TimeoutInMinutes`. |
| `tasks/powershell.yml` | 5 | Defaults; `TargetType` file vs inline (with the matching required parameter missing for each); `ScriptFileArguments`; `UsePowerShellCoreOnWindows`; `TaskEnvironmentVariables`; `TaskName`; `FailOnStandardError`. |
| `tasks/publish_pipeline_artifact.yml` | 0 | Required missing; defaults; all parameters set. |
| `utils/concat_wrap_list.yml` | 2 | Single item; several items (order kept); `Prefix`/`Suffix`; empty `Items`; `OutputVariableName`. |
| `stages/terraform_build.yml` | 0 | Defaults; parameters passed through to the job (one case asserting all of them). |
| `stages/terraform_deploy.yml` | 2 | One environment; several environments (`EnvironmentConfig`); each branch. |
| `pipelines/terraform_pipeline.yml` | 2 | Parameterised cases for each branch. Keep the three directory tests in `tests/pipelines/` as consumer-style smoke tests. |

`azure_web_app.yml` and `file_transform.yml` are not used anywhere in the repository. Under decision 5 they get tests anyway. If deleting them is preferred instead, that is a separate decision and needs a `CHANGELOG.md` note.

Steps-level templates (`tasks/*`, `utils/*`) compile as a pipeline root without a transform, as `tasks/terraform.CompileTests.ps1` does today. Stage- and pipeline-level templates do the same at their own level.

## Phase 6: Hand-over to the schema work

- Re-run the whole suite and record the case counts per file in this document.
- Update [Schema Validation Library](schema-validation-library.md):
  - its Testing section points at F2 (literal `ErrorMessage` only, wildcard `ExpectedYaml` kept), not a blanket `.Contains()`;
  - the scalar-types section notes that `Core.CompileYaml.ps1` sends object parameters as **JSON strings** in a flat `templateParameters` dictionary, so "REST callers pass typed booleans" is itself unverified. The F4 YAML-literal cases settle that question.
- Mark [Compile Test Audit](compile-test-audit.md) as done.

## Order and size

| Phase | Pull requests | Rough change in cases |
| ----- | ------------- | --------------------- |
| 1 Framework | 1–2 | +5 framework self-tests |
| 2 Wrong-reason fixes | 1 | 0 |
| 3 Duplicates | ~6 (one per file) | about −34 |
| 4 Gaps | ~5 schemas + ~7 jobs/tasks | about +55 |
| 5 New files | ~12 | about +75 |
| 6 Hand-over | 1 | 0 |

The net result is about +100 cases: from roughly 285 compile calls to roughly 385. Every case then maps to a branch or a standard parameter, and none repeats another. With per-file concurrency (see [Baseline](#baseline-featuretest-framework-performance-boost)), the added run time is small. The cost that matters is the number of cases to maintain.

Phases 2 and 3 can run in parallel with phase 5. Phase 4's schema cases must land before any schema code changes. All work branches from `feature/test-framework-performance-boost`, or from `main` once that branch is merged. Phase 1 needs it, because F3 hooks into the new batch runner.

## Open questions

1. **F4 design:** embed `YamlParameters` through the template's own parameter defaults, or through a wrapper pipeline that calls the template with literal values? A wrapper is closer to real consumers, but adds a template layer to every such case.
2. **Directory tests:** keep them all as smoke tests, or trim the `*_basic_test.yml` files that duplicate parameterised cases (phase 3)?
3. **Branch-coverage comments** (phase 4): acceptable as an interim measure, or should a coverage tool (static condition matrix, see the earlier discussion) come first?
