# Compile Test Audit

**Status:** Proposed. Review of every `*.CompileTests.ps1` file before the [Schema Validation Library](schema-validation-library.md) work starts.

## Goal

Every template behaviour should be covered by exactly one test, at the right level, and every test should actually assert what its description says. More tests mean more maintenance and more compile calls against Azure DevOps, so this audit looks for **gaps**, **duplicates** and **weak or wrong assertions**.

## How the tests work

This is a short summary for readers without the repository.

- Each `<template>.CompileTests.ps1` sits next to its template. It defines `$validTestCases` and `$invalidTestCases`, then calls `Run-Tests -YamlPath <template>` with an optional `-TransformYamlFunction`.
- Each case makes one compile call to the Azure DevOps preview-run API (`tests/framework/Core.CompileYaml.ps1`). `Parameters` are sent as JSON `templateParameters`.
- **Valid case:** passes if the template compiles and every `ExpectedYaml` string matches the final YAML with `-like "*<text>*"`.
- **Invalid case:** passes if the call returns HTTP 400 and `apiMessage -like "*<ErrorMessage>*"`.
- **Directory tests:** `tests/jobs/jobs.CompileTests.ps1` and `tests/pipelines/pipelines.CompileTests.ps1` compile every `*_test.yml` under their folder. They only check that compilation succeeds. They are the only tests that pass config as **YAML literals**, the way consumers do.

## Inventory

| File                                                 | Valid | Invalid | Notes                                     |
| ---------------------------------------------------- | ----: | ------: | ----------------------------------------- |
| `tasks/azure_key_vault.CompileTests.ps1`             |     4 |       2 |                                           |
| `tasks/terraform.CompileTests.ps1`                   |    18 |       5 | No-service-connection branch              |
| `tasks/terraform.ServiceConnection.CompileTests.ps1` |    12 |       1 | `AzureCLI@2` branch of the same template  |
| `tasks/terraform_installer.CompileTests.ps1`         |     6 |       8 |                                           |
| `jobs/manual_verification.CompileTests.ps1`          |     5 |       1 |                                           |
| `jobs/terraform_build.CompileTests.ps1`              |    12 |       3 |                                           |
| `jobs/terraform_deploy.CompileTests.ps1`             |    26 |       5 |                                           |
| `jobs/terraform_destroy.CompileTests.ps1`            |     5 |       3 |                                           |
| `jobs/terraform_gated_deployment.CompileTests.ps1`   |    25 |      12 |                                           |
| `jobs/terraform_gated_destroy.CompileTests.ps1`      |     7 |       7 |                                           |
| `schemas/config_sources.CompileTests.ps1`            |     2 |       8 |                                           |
| `schemas/terraform_deploy_config.CompileTests.ps1`   |    12 |      24 |                                           |
| `schemas/terraform_destroy_config.CompileTests.ps1`  |     2 |       4 | Much thinner than its deploy counterpart  |
| `schemas/terraform_gated_deployment_config.CompileTests.ps1` | 12 |  20 |                                           |
| `schemas/terraform_gated_destroy_config.CompileTests.ps1`    |  6 |  10 |                                           |
| `utils/config_sources_task_list.CompileTests.ps1`    |     4 |       4 |                                           |
| `tests/framework/example_echo_task.CompileTests.ps1` |     – |       – | Framework example, 4 cases                |
| `tests/jobs/**/*_test.yml`                           |    41 |       – | Directory compile tests                   |
| `tests/pipelines/**/*_test.yml`                      |     3 |       – | Directory compile tests                   |

That is about 240 parameterised cases plus 44 directory tests, so roughly 285 compile calls per full run.

## Findings

### 1. Tests that do not assert what they claim

| Where | Problem | Fix |
| ----- | ------- | --- |
| `jobs/terraform_gated_deployment.CompileTests.ps1`: "missing required EnvironmentName parameter", "missing required TerraformDeploymentConfig parameter", "invalid CheckoutAlias value" | No `ErrorMessage`. `$null -eq ""` is false, so the check becomes `-like "**"`, which matches **any** 400 error. These cases pass for the wrong reason as long as anything fails. | Add the expected messages (`A value for the 'EnvironmentName' parameter must be provided.` and so on). In the framework, make `ErrorMessage` mandatory for invalid cases, and fail a case that omits it. |
| `tasks/terraform.CompileTests.ps1`: three invalid cases are all named "custom command with missing custom command" | Two of them test `SaveCommandConsoleOutputToFile` / `CommandConsoleOutputFileName`. The output is misleading when one fails. | Rename to describe what each tests. |
| `ExpectedYaml` entries such as `"terraform-*"` and `SecretsFilter` values with `*` (`jobs/terraform_deploy`, `jobs/terraform_destroy`) | Meant literally, but `-like` treats `*` as a wildcard, so the assertion is weaker than it looks. | Covered by framework change F2 below. |

### 2. Duplicated coverage

**Validation tested twice.** The job tests repeat schema error cases that the schema tests already cover. At job level, one "the schema is wired in" case per job is enough. Every other error case belongs in the schema test only.

| File | Cases that duplicate the schema tests | Keep |
| ---- | ------------------------------------- | ---- |
| `jobs/terraform_gated_deployment` | AzDOEnvironmentName, invalid RunMode, VerificationMode, VerificationTimeoutBehaviour, VerificationTimeoutInMinutes, ApplyEvenIfNoChanges ×3 (**8**) | "missing RunMode" |
| `jobs/terraform_gated_destroy` | AzDOEnvironmentName, invalid RunMode, VerificationTimeoutBehaviour, VerificationTimeoutInMinutes (**4**) | "missing RunMode" |
| `jobs/terraform_deploy` | invalid VerificationMode, partial Key Vault configuration (**2**) | "missing AzDOEnvironmentName" |
| `utils/config_sources_task_list` | unsupported Type, missing ServiceConnection (**2**) | "empty array" |

**The same code path with different data.** These cases exercise the same template branch with different values. Keep one each unless the template actually branches on the value.

| File | Cases | Keep |
| ---- | ----- | ---- |
| `jobs/terraform_deploy` | "Specific Terraform Version" / "Different Terraform Version" | 1 |
| `jobs/terraform_deploy` | "Single Variable File" / "Multiple Variable Files" | "Multiple" |
| `jobs/terraform_deploy` | "Variable Group" / "Multiple Variable Groups" | "Multiple" |
| `jobs/terraform_deploy` | "Backend Configuration" / "Backend Configuration - Multiple Properties" | "Multiple" |
| `jobs/terraform_deploy` | "Single Output Variable" / "Multiple Output Variables" | "Multiple" |
| `jobs/terraform_deploy` | "Custom Artifact Name" / "Default Artifact Name" | Both only if the default is asserted in the output; otherwise "Custom" |
| `jobs/terraform_gated_deployment` | "custom Terraform version" / "default Terraform version (1.14.0)" | 1 (the version is passed through to `terraform_deploy`, which tests it) |
| `jobs/terraform_gated_deployment` | "custom TerraformArtifactName" / "default TerraformArtifactName" | 1 |
| `jobs/terraform_gated_deployment` | "Complex scenario" / "Quick deploy scenario" | Review: probably both are covered by the single-feature cases |
| `jobs/terraform_gated_deployment` | 7 `ApplyEvenIfNoChanges` valid cases | 3: absent, `false` and `true`. The template only interpolates the value into one `condition` (`eq('<value>', 'true')`) and does not branch on `VerificationMode`. So the `VerifyOnDestroy`, `VerifyDisabled` and custom-artifact variants add nothing. The PlanOnly/ApplyOnly + `false` cases repeat the schema tests. |
| `tasks/terraform_installer` | valid semantic versions 1.3.5, 1.11.3, 0.15.0, 2.0.1 | 2 (for example `0.15.0` and `1.11.3`) |
| `tasks/terraform_installer` | invalid `>=1.11.0` and `~1.11.0` | Keep both only if the regex treats them differently |

**Missing-parameter cases in internal schemas.** Every schema test checks that Azure DevOps rejects a missing `EnvironmentName` or config object. That tests Azure DevOps, not our code, and the public job tests already check the same contract. Removing them from `schemas/*` saves 10 calls. Keep them in `jobs/*`, because a required parameter is part of the public contract.

**Directory tests vs parameterised job tests.** Several directory tests (for example `tests/jobs/terraform_deploy/plan_basic_test.yml`) compile the same scenario as a parameterised case, but assert less. Keep the directory tests that add something the parameterised tests cannot:
- multiple instances in one pipeline (`double_*`), which catch job and task name clashes;
- YAML-literal config, which follows the consumer's path (see finding 4);
- consumer-style resource checkout.

Remove the plain "basic" ones only after confirming that a parameterised case covers the same scenario.

**Potential saving:** about 16 duplicated validation cases, about 16 same-path cases and 10 schema missing-parameter cases, so roughly **42 fewer compile calls (about 15%)** with no loss of coverage.

### 3. Gaps

| Template | Missing coverage |
| -------- | ---------------- |
| `schemas/terraform_destroy_config.yml` | Its checks are copy-pasted from the deploy schema, but tested only for `KeyVaultConfig` and `VerificationMode`. Missing: AzDOEnvironmentName missing/empty, empty AzureServiceConnection, BackendConfig not a map or with empty key/value, EnvironmentVariableMappings not a map or with empty key/value, VariableFiles not a list or with non-string items, and one valid "all optional fields" case. About 10 cases. |
| `schemas/terraform_deploy_config.yml` | BackendConfig **not a map** (only empty-entry cases exist); EnvironmentVariableMappings **not a map**. |
| `schemas/terraform_gated_deployment_config.yml` | `VerificationMode` is only tested with one valid value, but this schema has its own copy of the value list. Add the other two. `VerificationTimeoutInMinutes` as a non-numeric string (`"abc"`): today's behaviour is unknown and should be pinned before the migration. |
| `schemas/terraform_gated_destroy_config.yml` | `VerificationTimeoutInMinutes` as a non-numeric string. |
| `schemas/config_sources.yml` | `Type` missing; `ServiceConnection` not a string; `Name` not a string; an error in the **second** entry of a list; a valid multi-entry list. |
| `tasks/azure_web_app.yml`, `tasks/file_transform.yml` | No tests, and nothing in the repository uses them. `azure_web_app.yml` has 5 conditional branches. Decide: delete them (internal, no SemVer), or add tests. |
| `tasks/powershell.yml` (5 branches), `tasks/manual_validation.yml` (2), `tasks/copy_files.yml` (1), `utils/concat_wrap_list.yml` (2), `stages/terraform_deploy.yml` (2) | Covered only indirectly through jobs, stages and pipelines. Acceptable if the branches they use are covered. Check `powershell.yml` specifically, because it has the most logic. |
| YAML-literal values | The only tests that pass config as YAML literals are directory tests, which only check that compilation succeeds. No **invalid** case and no output assertion uses the YAML-literal path. This matters because booleans (and possibly numbers) arrive as strings on that path (see the schema design). Add a small set of YAML-literal cases through `-TransformYamlFunction`: `ApplyEvenIfNoChanges: true`, `VerificationTimeoutInMinutes: 30`, `RunAsPreJob: true`. |

### 4. Framework changes

| ID | Change | Why |
| -- | ------ | --- |
| F1 | Fail an invalid case that has no `ErrorMessage` | Finding 1: such cases currently pass on any error |
| F2 | Separate **literal** and **pattern** matching. Keep `ExpectedYaml` as wildcard patterns (several cases rely on them, for example `'inputs:*TerraformVersion:**1.14.0'`). Make `ErrorMessage` literal (`.Contains()`), or add `ExpectedYamlLiteral`. | The schema design assumes a `.Contains()` change. Applying it to `ExpectedYaml` as well would **break** the wildcard cases in `terraform_build`, `terraform_deploy`, `manual_verification` and `terraform_gated_deployment`. |
| F3 | Fail on duplicate `Description` values within a file | Finding 1: `tasks/terraform` |
| F4 | Optional: support YAML-literal parameters in a case (for example `YamlParameters`, a string embedded by a standard transform) | Finding 3: YAML-literal path |

## Proposed order

1. Framework F1 and F3, and fix the three gated-deployment cases and the `tasks/terraform` names. These are small and make every later change trustworthy.
2. F2: literal `ErrorMessage` matching, keeping `ExpectedYaml` patterns.
3. Remove duplicates (finding 2), one file per pull request, running the file before and after.
4. Fill the gaps (finding 3), starting with `terraform_destroy_config` and the YAML-literal cases. The schema migration needs these as its regression baseline.
5. Then start the schema validation library.

Test files are internal, so none of this needs a `CHANGELOG.md` entry, except deleting `tasks/azure_web_app.yml` or `tasks/file_transform.yml` if that is chosen. They are internal too, but worth recording.

## Open questions

1. Delete `tasks/azure_web_app.yml` and `tasks/file_transform.yml`, or add tests for them?
2. Keep the missing-parameter cases in `schemas/*`, or rely on the `jobs/*` ones?
