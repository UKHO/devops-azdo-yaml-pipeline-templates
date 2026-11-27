# Schema Validation Library

**Status:** Proposed. Open questions below must be answered before starting.

## Summary

Replace the hand-written checks in `schemas/` with a small library: one generic validation template driven by a declarative list of rules (type, required, allowed values, ranges, list item types, groups of fields that must be set together, and so on). Each schema becomes a short list of rules instead of 40–75 lines of nested template expressions. This also fixes several real bugs in the current checks and adds detection of unknown fields, at the top level and, through recursion, inside list items and sub-objects.

## Repository context

This section is for readers who cannot browse the repository.

- **What the repository is:** a library of reusable Azure DevOps YAML pipeline templates for Terraform. The **public API** is `pipelines/` and `jobs/` only, which follow SemVer. Everything else (`tasks/`, `stages/`, `schemas/`, `utils/`, `scripts/`, `tools/`) is internal and can change at any time.
- **Folders that matter for this design:**
  - `schemas/`: the five validation templates, each with a `<name>.CompileTests.ps1` beside it.
  - `jobs/`: public job templates. Each starts its `jobs:` list with a call to its schema.
  - `utils/config_sources_task_list.yml`: a `steps:` template that calls `schemas/config_sources.yml` and then adds one Key Vault task per entry.
  - `tests/framework/`: the PowerShell compile-test framework.
  - `tools/`: maintainer scripts. Today it holds only `Set-TerraformVersionAcrossRepository.ps1`.
  - `docs/definition_docs/`: user documentation for the config objects, for example `terraform_pipeline/terraform_job_config.md` and `shared/config_sources.md`.
- **Conventions:** UTF-8, LF line endings, 2-space indent (`.editorconfig`). Markdown prose is not hard-wrapped. Every user-visible change needs an entry under `## [Unreleased]` in `CHANGELOG.md`. Avoid wrapping a template in another template unless necessary (see `docs/developers/explanation/double-wrapping.md`). Ask the maintainers before adding a new top-level folder or a new dependency.
- **How schemas are called.** A job template validates its config object before declaring its real job:

  ```yaml
  # jobs/terraform_deploy.yml
  jobs:
    - template: /schemas/terraform_deploy_config.yml
      parameters:
        TerraformDeploymentConfig: ${{ parameters.TerraformDeploymentConfig }}
        EnvironmentName: ${{ parameters.EnvironmentName }}
    - deployment: TerraformDeploy...
  ```

  | Caller                                | Schema                                  | Level    |
  | ------------------------------------- | --------------------------------------- | -------- |
  | `jobs/terraform_deploy.yml`           | `terraform_deploy_config.yml`           | `jobs:`  |
  | `jobs/terraform_destroy.yml`          | `terraform_destroy_config.yml`          | `jobs:`  |
  | `jobs/terraform_gated_deployment.yml` | `terraform_gated_deployment_config.yml` | `jobs:`  |
  | `jobs/terraform_gated_destroy.yml`    | `terraform_gated_destroy_config.yml`    | `jobs:`  |
  | `utils/config_sources_task_list.yml`  | `config_sources.yml`                    | `steps:` |

  The gated job templates validate only the fields they use themselves (`RunMode`, the verification fields and `ApplyEvenIfNoChanges`), and then call `jobs/terraform_deploy.yml` or `jobs/terraform_destroy.yml`, which validate everything else. **One config object is therefore checked by two schemas.** `AzDOEnvironmentName` is checked in both on purpose, so that each job reports a clear error on its own.

- **How errors surface.** The invalid list item `"<message>": "Error"` makes compilation fail with `Unexpected value '<message>'`. Test cases assert against that text.
- **Compile tests.** Each `*.CompileTests.ps1` dot-sources `tests/framework/Core.ps1` and calls `Run-Tests -YamlPath <template> -TransformYamlFunction <adds a dummy job so the template compiles on its own> -ValidTestCases @(...) -InvalidTestCases @(...)`. A test case is a hashtable with `Description`, `Parameters` (a PowerShell hashtable, sent as JSON) and, for invalid cases, `ErrorMessage`. The framework compiles through the Azure DevOps preview-run REST API (`previewRun = $true`, api-version `7.1-preview.1`). Error matching is `$apiMessage -like "*$ErrorMessage*"`, a **wildcard** match, so `[`, `]`, `*` and `?` in an expected message are treated as pattern characters. This matters because paths such as `ConfigSources[].Name` contain brackets. `Run-AllCompileTests.ps1` in the repository root runs every `*.CompileTests.ps1`.

## Current state

There are five schema templates: `config_sources.yml`, `terraform_deploy_config.yml`, `terraform_destroy_config.yml`, `terraform_gated_deployment_config.yml` and `terraform_gated_destroy_config.yml`. They are called from `jobs/` and `utils/config_sources_task_list.yml`. Failure is signalled by putting an invalid item into a `jobs:` or `steps:` list, which makes compilation fail with the message as the error:

```yaml
- ${{ if <condition> }}:
    - "'${{ parameters.EnvironmentName }}' environment error: <message>": "Error"
```

The same few checks are hand-written over and over:

| Check                                | Occurrences                                                              |
| ------------------------------------ | ------------------------------------------------------------------------ |
| Required, non-empty string           | `AzDOEnvironmentName` ×3, `RunMode` ×2, `ServiceConnection`, `Name`      |
| Must be one of a fixed set of values | `RunMode`, `VerificationMode` ×2, `VerificationTimeoutBehaviour`, `Type` |
| Optional, but validated if present   | almost every field                                                       |
| Map of non-empty key/value pairs     | `BackendConfig` ×2, `EnvironmentVariableMappings` ×2                     |
| List of strings                      | `VariableFiles` ×2, `OutputVariables`                                    |
| Number in a range                    | `VerificationTimeoutInMinutes` ×2                                        |
| Boolean                              | `RunAsPreJob`                                                            |
| All-or-none group                    | `KeyVaultConfig` (`ServiceConnection`, `Name`, `SecretsFilter`)          |
| Mutually exclusive                   | `KeyVaultConfig` vs `ConfigSources`                                      |
| Forbidden field                      | `KeyVaultConfig` and `VerificationMode` in destroy                       |
| Conditionally required               | `VerificationMode` when `RunMode` is `PlanVerifyApply`                   |
| List of objects with their own rules | `ConfigSources`                                                          |

### Current checks per schema

This is the full list of what each schema checks today. It is the specification that the migrated rules must reproduce, apart from the deliberate bug fixes. `<Env>` stands for `'<EnvironmentName>' environment error`. Messages are quoted exactly.

`terraform_gated_destroy_config.yml` takes the parameters `TerraformDestroyConfig` (object) and `EnvironmentName` (string):

| Field                          | Check                                                 | Message                                                                                                                              |
| ------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `AzDOEnvironmentName`          | required, non-empty                                   | `<Env>: AzDOEnvironmentName is not properly defined and is a required field.`                                                        |
| `RunMode`                      | required, non-empty                                   | `<Env>: RunMode is not properly defined and is a required field. Must be a valid option (PlanVerifyDestroy, PlanOnly, DestroyOnly).` |
| `RunMode`                      | one of `PlanVerifyDestroy`, `PlanOnly`, `DestroyOnly` | `<Env>: RunMode must be a valid option (PlanVerifyDestroy, PlanOnly, DestroyOnly).`                                                  |
| `VerificationTimeoutBehaviour` | if present: one of `reject`, `resume`                 | `<Env>: VerificationTimeoutBehaviour must be either 'reject' or 'resume'.`                                                           |
| `VerificationTimeoutInMinutes` | if present: 1 to 43200                                | `<Env>: VerificationTimeoutInMinutes must be a number between 1 and 43200 (30 days).`                                                |

`terraform_gated_deployment_config.yml` takes the parameters `TerraformDeploymentConfig` and `EnvironmentName`. It has the same `AzDOEnvironmentName`, `VerificationTimeoutBehaviour` and `VerificationTimeoutInMinutes` checks, plus:

| Field                  | Check                                                                                                        | Message                                                                                               |
| ---------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `RunMode`              | required, non-empty; one of `PlanVerifyApply`, `PlanOnly`, `ApplyOnly`                                       | The same two messages as above, with these values                                                     |
| `VerificationMode`     | when `RunMode` is `PlanVerifyApply`: one of `VerifyOnDestroy`, `VerifyOnAny`, `VerifyDisabled` (so required) | `<Env>: Must provide a valid VerificationMode option (VerifyOnDestroy, VerifyOnAny, VerifyDisabled).` |
| `ApplyEvenIfNoChanges` | if present: JSON form is one of `true`, `false`, `"true"`, `"false"`                                         | `<Env>: ApplyEvenIfNoChanges must be a boolean (true or false).`                                      |
| `ApplyEvenIfNoChanges` | otherwise, if `true` while `RunMode` is `PlanOnly` or `ApplyOnly`                                            | `<Env>: ApplyEvenIfNoChanges can only be set to true when RunMode is PlanVerifyApply.`                |

`terraform_deploy_config.yml` takes the parameters `TerraformDeploymentConfig` and `EnvironmentName`:

| Field                              | Check                                                                                         | Message                                                                                                                                                                                                                               |
| ---------------------------------- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AzDOEnvironmentName`              | required, non-empty                                                                           | as above                                                                                                                                                                                                                              |
| `VerificationMode`                 | if present: one of the three modes                                                            | `<Env>: If provided, VerificationMode must be a valid option (VerifyOnDestroy, VerifyOnAny, VerifyDisabled).`                                                                                                                         |
| `AzureServiceConnection`           | if present (loose match, bug 2): length is not 0                                              | `<Env>: AzureServiceConnection is not properly defined.`                                                                                                                                                                              |
| `ConfigSources` + `KeyVaultConfig` | `ConfigSources` present (loose match) and any `KeyVaultConfig` member is truthy               | `<Env>: use either KeyVaultConfig (legacy) or ConfigSources (new), not both. Both parameters cannot coexist in the same configuration. See upgrade guide: docs/user-docs/upgrades/0.1.0-to-0.2.0-keyvaultconfig-to-configsources.md`  |
| `KeyVaultConfig`                   | if any of `ServiceConnection`, `Name`, `SecretsFilter` is truthy, all three must be non-empty | `<Env>: KeyVaultConfig.<Member> is required when any Key Vault configuration is provided.` (one per missing member)                                                                                                                   |
| `BackendConfig`                    | if truthy: a map whose keys and values are all non-empty                                      | `<Env>: BackendConfig is not correct. Must be an object of key/value pairs.`                                                                                                                                                          |
| `EnvironmentVariableMappings`      | as for `BackendConfig`                                                                        | Not a map: `<Env>: EnvironmentVariableMappings is not correct. Must be an object of key/value pairs.` Bad entry: `<Env>: EnvironmentVariableMappings is not correct. Key: '<k>'. Value: '<v>'. Must be an object of key/value pairs.` |
| `VariableFiles`                    | if truthy: a list of strings                                                                  | Not a list: `<Env>: VariableFiles is not correct. Must be a list of string values.` Bad item: `<Env>: VariableFiles item '<json>' is not a string. This parameter must be a list of string values.`                                   |
| `OutputVariables`                  | as for `VariableFiles`                                                                        | The same two messages, with `OutputVariables`                                                                                                                                                                                         |

The deploy schema ignores `RunMode`, `VerificationTimeout*` and `ApplyEvenIfNoChanges`; the gated schema checks them.

`terraform_destroy_config.yml` takes the parameters `TerraformDestroyConfig` and `EnvironmentName`. It has the same `AzDOEnvironmentName`, `AzureServiceConnection`, `BackendConfig`, `EnvironmentVariableMappings` and `VariableFiles` checks as the deploy schema (no `OutputVariables`), plus:

| Field              | Check          | Message                                                                                                              |
| ------------------ | -------------- | -------------------------------------------------------------------------------------------------------------------- |
| `KeyVaultConfig`   | must be absent | `<Env>: KeyVaultConfig is deprecated and not supported for destroy workflows. Use ConfigSources instead.`            |
| `VerificationMode` | must be absent | `<Env>: VerificationMode is not supported for destroy workflows. Use RunMode 'PlanVerifyDestroy' for gated destroy.` |

`config_sources.yml` (`steps:` level) takes one parameter, `ConfigSources`, which is a **list**, not an object. Its messages have **no** environment prefix. Every message except the empty-list one ends with `See docs/definition_docs/shared/config_sources.md`, which is left out of the table below:

| Field                  | Check                                                    | Message                                                                                                             |
| ---------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| (the list)             | must not be empty                                        | `Invalid ConfigSources: list cannot be empty. If no configuration sources are needed, omit the parameter entirely.` |
| `[].Type`              | required, non-empty string, equal to `KeyVault`          | `Invalid ConfigSources: entry field 'Type' is required, must be a non-empty string, and must be 'KeyVault'.`        |
| `[].ServiceConnection` | required, non-empty                                      | `Invalid ConfigSources: entry is missing required field 'ServiceConnection'.`                                       |
| `[].ServiceConnection` | string                                                   | `Invalid ConfigSources: entry field 'ServiceConnection' must be a string.`                                          |
| `[].Name`              | when `Type` is `KeyVault`: required, non-empty           | `Invalid ConfigSources: KeyVault entry is missing required field 'Name'.`                                           |
| `[].Name`              | when `Type` is `KeyVault`: string                        | `Invalid ConfigSources: KeyVault entry field 'Name' must be a string.`                                              |
| `[].SecretsFilter`     | when `Type` is `KeyVault` and present: non-empty string  | `Invalid ConfigSources: KeyVault entry field 'SecretsFilter' must be a non-empty string when provided.`             |
| `[].RunAsPreJob`       | when `Type` is `KeyVault` and present: `true` or `false` | `Invalid ConfigSources: KeyVault entry field 'RunAsPreJob' must be a boolean when provided.`                        |

## Bugs in the current approach

1. **False positives in type checks.** A value is treated as an object or list if `convertToJson(value)` _contains_ `{` or `[`. The valid string `"a{b"` is therefore rejected. Confirmed by a compile probe.
2. **Field-present checks match too loosely.** `contains(convertToJson(cfg), 'AzureServiceConnection')` (no quotes) is true when the name appears in a nested key or in any value. Confirmed by a compile probe. `contains(..., 'ConfigSources')` has the same problem.
3. **Empty values skip validation.** Optional checks use `${{ if parameters.X.Field }}`, so `BackendConfig: {}` or `VariableFiles: []` is never validated. Existing tests rely on this ("Apply with Empty Backend Configuration").
4. **Duplication.** `AzDOEnvironmentName`, `BackendConfig`, `EnvironmentVariableMappings` and `VariableFiles` checks are copy-pasted between files, with slightly different wording.

## Verified template capabilities

A compile probe against the preview-run API confirmed:

| Capability                                   | Result                                                                                                                                          |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Look up a field by a name held in a variable | `parameters.Obj[f]` works where `f` is a loop variable                                                                                          |
| Detect type                                  | `convertToJson(value)` returns typed JSON: strings start with `"`, maps with `{`, lists with `[`; booleans are `true`/`false`; numbers are bare |
| Missing vs empty                             | A missing field gives `null`; an empty string gives `""`                                                                                        |
| Loop over keys                               | `${{ each kv in parameters.Obj }}` exposes `kv.key`, which allows unknown-field detection                                                       |

So `startsWith(convertToJson(value), '"')` and similar give exact type checks, fixing bugs 1–3.

**Not yet verified:** whether a template can include itself, directly or through another template (needed for nested rules, see [Nested rules](#nested-rules)).

### Scalar types: conflicting evidence

The probe found that `convertToJson` gives bare `true`/`false` and bare numbers. However, a comment in `terraform_gated_deployment_config.yml` says that booleans written in YAML object literals reach the template as **strings** (`convertToJson` gives `"true"`, with quotes), while REST/JSON callers pass real booleans. The compile tests are REST/JSON callers, because they send PowerShell hashtables as JSON. Numbers are probably affected in the same way.

Until a probe settles this, the engine must accept both forms. `Type: boolean` accepts `true`, `false`, `"true"` and `"false"`. The probe must compile a **YAML file** that contains literal values, not only a REST payload, because the two paths behave differently.

**Numbers are harder.** No documented expression tests whether a string converts to a number without failing compilation. `lt`/`gt` raise an error when conversion fails. `eq`/`ne`/`containsValue` treat a failed conversion as no match, so they cannot tell "not a number" from "a different number". The sketch therefore accepts only **bare** numbers for `Type: number` and applies `Min`/`Max` only to them. If the probe shows that YAML numbers arrive as strings, `Type: number` must be redesigned before `VerificationTimeoutInMinutes` is migrated. There are two options: keep today's unguarded `lt`/`gt`, which gives an unreadable error for non-numeric strings, or accept numeric strings without checking the range.

**The same applies to the rules themselves.** Rule literals such as `Required: false` or `DependsOn: { Present: false }` are also YAML, so they may arrive as strings. The Templates page on Microsoft Learn notes: "Non-empty strings are cast to true in a Boolean context." So the engine never tests a rule flag for truthiness; it normalises the flags first (see [Normalising flags and scalars](#normalising-flags-and-scalars)). The probe must cover rule literals as well as user values.

**Integers.** `Type: number` accepts decimals such as `1.5`. See [Open questions](#open-questions).

## Design

### Engine

Each schema makes one call to the engine with its whole rule list, instead of hand-writing checks per field. Internally the engine includes one small per-rule template for each rule (see [Engine sketch](#engine-sketch)):

```yaml
- template: /schemas/lib/validate.jobs.yml
  parameters:
    Object: ${{ parameters.TerraformDeploymentConfig }}
    ErrorPrefix: "'${{ parameters.EnvironmentName }}' environment error"
    AllowUnknownFields: false
    Rules:
      - {
          Field: AzDOEnvironmentName,
          Type: string,
          Required: true,
          NonEmpty: true,
        }
      - {
          Field: VerificationMode,
          Type: string,
          Values: [VerifyOnDestroy, VerifyOnAny, VerifyDisabled],
        }
      - {
          Field: VerificationTimeoutInMinutes,
          Type: number,
          Min: 1,
          Max: 43200,
        }
      - { Field: BackendConfig, Type: map, NonEmptyEntries: true }
      - { Field: VariableFiles, Type: list, ItemType: string }
      - {
          Field: KeyVaultConfig,
          Type: object,
          AllOrNone: [ServiceConnection, Name, SecretsFilter],
        }
      - {
          Field: ConfigSources,
          Type: list,
          ItemType: object,
          DependsOn: { Field: KeyVaultConfig, Present: false },
          Otherwise: Forbidden,
        }
```

### Rule properties

| Property          | Meaning                                                                                                                                                                                   |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Field`           | Key in `Object` to validate                                                                                                                                                               |
| `Type`            | `string`, `number`, `boolean`, `list`, `map`, `object` or `any`                                                                                                                           |
| `Required`        | Field must be present                                                                                                                                                                     |
| `NonEmpty`        | String, list or map must not be empty when present                                                                                                                                        |
| `Values`          | Allowed values                                                                                                                                                                            |
| `Min` / `Max`     | Numeric range (inclusive)                                                                                                                                                                 |
| `ItemType`        | Type of each list item                                                                                                                                                                    |
| `ItemRules`       | Rules applied to each object in a list (for example `ConfigSources`)                                                                                                                      |
| `NonEmptyEntries` | Map keys and values must be non-empty                                                                                                                                                     |
| `AllOrNone`       | Sub-fields that must be set together                                                                                                                                                      |
| `Forbidden`       | Field must not be present; takes a custom message                                                                                                                                         |
| `DependsOn`       | Condition on another field that decides whether this rule applies. See [Field dependencies](#field-dependencies-dependson)                                                                |
| `Otherwise`       | What happens when `DependsOn` is not met: `Ignore` (default) or `Forbidden`                                                                                                               |
| `Message`         | Optional override for the standard error message                                                                                                                                          |
| `ForbiddenValues` | _Proposed, see [Gaps](#gaps-the-rule-model-does-not-cover-yet)._ Values the field must not have. Compared with `containsValue`, exactly as for `Values`: case-insensitive, with type conversion. List both `true` and `"true"` to be safe |
| `Properties`      | _Proposed._ Rules applied to the sub-fields of an `object` value (for example `KeyVaultConfig`)                                                                                           |

Engine parameters are `Object`, `Rules`, `ErrorPrefix`, `PathPrefix`, `AllowUnknownFields` and the proposed `ErrorSuffix` (text appended to every message, default `''`).

The same `Field` may appear in more than one rule. This is needed when part of a field's validation always applies and part depends on another field (see the `VerificationMode` example below).

### Error messages

All errors use a standard format:

```text
<ErrorPrefix>: '<Path>' <problem>.
```

For example: `'dev' environment error: 'VerificationMode' must be one of (VerifyOnDestroy, VerifyOnAny, VerifyDisabled).` `<Path>` includes nested keys, for example `ConfigSources[].Name`. List indexes are **not** available: `${{ each }}` does not expose an index, so a list item is shown as `[]`. Where a list item has an identifying field (for example `Name`), the item rules can include it in a custom `Message`.

### Field dependencies (DependsOn)

Some fields only make sense, or are only required, depending on another field. Today's cases:

| Case                                                                                              | Today                                              | Expressed with `DependsOn`                                                                                                            |
| ------------------------------------------------------------------------------------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `VerificationMode` is required when `RunMode` is `PlanVerifyApply`                                | Hand-written check in the gated schema             | `DependsOn: { Field: RunMode, Equals: PlanVerifyApply }`, `Required: true`                                                            |
| `ConfigSources` and `KeyVaultConfig` cannot both be set                                           | Hand-written check, with the loose-match bug       | On `ConfigSources`: `DependsOn: { Field: KeyVaultConfig, Present: false }`, `Otherwise: Forbidden`                                    |
| `VerificationTimeoutInMinutes` / `VerificationTimeoutBehaviour` only matter for `PlanVerifyApply` | Not enforced: silently ignored for other run modes | `DependsOn: { Field: RunMode, Equals: PlanVerifyApply }`, `Otherwise: Ignore` (today's behaviour) or `Forbidden` (stricter, breaking) |

#### Shape

```yaml
DependsOn:
  Field: <name of another field in the same Object> # required
  # exactly one of:
  Present: true | false # the other field is present / absent
  Equals: <scalar> # the other field equals this value
  In: [<scalar>, ...] # the other field is one of these values
  NotIn: [<scalar>, ...] # the other field is none of these values
Otherwise: Ignore | Forbidden # default Ignore
```

#### Semantics

- **Condition met:** every check in the rule applies (`Required`, `Type`, `Values` and so on).
- **Condition not met, `Otherwise: Ignore`:** the rule is skipped entirely.
- **Condition not met, `Otherwise: Forbidden`:** the field must be absent. The error names the dependency, for example `'ConfigSources' cannot be used when 'KeyVaultConfig' is set.`
- `DependsOn.Field` refers to a field in the **same** `Object` (siblings only). There are no cross-object or parent references.

#### Splitting a field across rules

In the gated schema, `VerificationMode` must always be one of the allowed values _if present_, but is only _required_ for `PlanVerifyApply`. That takes two rules:

```yaml
- {
    Field: VerificationMode,
    Type: string,
    Values: [VerifyOnDestroy, VerifyOnAny, VerifyDisabled],
  }
- {
    Field: VerificationMode,
    Required: true,
    DependsOn: { Field: RunMode, Equals: PlanVerifyApply },
  }
```

#### Single condition only

`DependsOn` is one condition, not a list combined with AND or OR. Template expressions cannot accumulate a result across a loop, so a generic "all of these conditions" would need a fixed, hand-unrolled maximum. No schema in the repository needs more than one condition today. If one does later, the options are a fixed second slot (`DependsOn2`, combined with AND) or a custom check outside the library.

#### What it replaces

`DependsOn` and `Otherwise` replace the earlier `When` and `ExclusiveWith` properties:

- `When` is `DependsOn` with `Otherwise: Ignore`.
- `ExclusiveWith: X` is `DependsOn: { Field: X, Present: false }` with `Otherwise: Forbidden`.

### Engine sketch

**Rough sketch, not yet compiled.** It shows how the rules are iterated and how each check is expressed. This version includes the corrections from the design review (see [Review outcomes](#review-outcomes)). Expressions marked _unverified_ need a compile probe before relying on them.

Template expressions cannot assign variables, so a single template would have to repeat `parameters.Object[rule.Field]`, `convertToJson(...)` and the whole `DependsOn` condition in every check. To avoid that, the engine is split into two files, and the values computed once per rule are passed as template **parameters**, which act as local variables:

| File                     | Responsibility                                                                                                                                                                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `validate.jobs.yml`      | Entry point. Checks that `Object` is a map, then loops over the rules. For each rule it works out the value, its JSON form, presence, shape flags, normalised rule flags and the `DependsOn` result once, and includes `validate_rule.jobs.yml`. Also checks for unknown fields. |
| `validate_rule.jobs.yml` | Runs every check for one rule against the precomputed values. For `ItemRules` and `Properties`, includes `validate.jobs.yml` again.                                                                                                     |

There are only two distinct files, but `validate_rule.jobs.yml` is **included once per rule**, plus once per item rule per list item. The 100-file limit counts distinct files, so this is fine. The real constraint is parse memory (see [Template limits](#template-limits)).

#### Normalising flags and scalars

A YAML literal such as `Required: false` inside a rule may reach the template as the **string** `"false"`, which is truthy. Rule flags must therefore never be tested with a bare `${{ if rule.X }}`. Instead, `validate.jobs.yml` normalises each flag once with `in(convertToJson(x), 'true', '"true"')`. This form gives the right answer whether `x` arrives as a boolean or a string, and gives `false` when `x` is absent (`null`). The normalised flags are passed to `validate_rule.jobs.yml` as `boolean` parameters, which are tested with `eq(parameters.X, true)`, not with bare truthiness. The same applies to user values: see [Scalar types](#scalar-types-conflicting-evidence).

#### `validate.jobs.yml`

```yaml
parameters:
  - name: Object
    type: object
  - name: Rules
    type: object
  - name: ErrorPrefix
    type: string
    default: "Validation error"
  - name: ErrorSuffix # appended to every message, for example a documentation link
    type: string
    default: ""
  - name: PathPrefix # '' at the top level; 'ConfigSources[].' for list items
    type: string
    default: ""
  - name: AllowUnknownFields
    type: boolean
    default: true

jobs:
  # The object itself must be a map; otherwise nothing below can work.
  - ${{ if not(startsWith(convertToJson(parameters.Object), '{')) }}:
      - "${{ parameters.ErrorPrefix }}: '${{ coalesce(parameters.PathPrefix, '(root)') }}' must be an object.${{ parameters.ErrorSuffix }}": Error

  - ${{ else }}:
      - ${{ each rule in parameters.Rules }}:
          - template: validate_rule.jobs.yml
            parameters:
              Rule: ${{ rule }}
              Path: ${{ parameters.PathPrefix }}${{ rule.Field }}
              ErrorPrefix: ${{ parameters.ErrorPrefix }}
              ErrorSuffix: ${{ parameters.ErrorSuffix }}
              AllowUnknownFields: ${{ parameters.AllowUnknownFields }} # inherited by ItemRules / Properties
              Value: ${{ parameters.Object[rule.Field] }}
              Json: ${{ convertToJson(parameters.Object[rule.Field]) }}
              # A missing field, or an explicit null / ~ / empty YAML value, converts to null and counts as absent
              Present: ${{ ne(convertToJson(parameters.Object[rule.Field]), 'null') }}
              # Normalised rule flags (see "Normalising flags and scalars")
              Required: ${{ in(convertToJson(rule.Required), 'true', '"true"') }}
              NonEmpty: ${{ in(convertToJson(rule.NonEmpty), 'true', '"true"') }}
              Forbidden: ${{ in(convertToJson(rule.Forbidden), 'true', '"true"') }}
              NonEmptyEntries: ${{ in(convertToJson(rule.NonEmptyEntries), 'true', '"true"') }}
              # '__none__' avoids indexing with a null key when there is no DependsOn (behaviour of a null key is undocumented)
              DependsOnField: ${{ coalesce(rule.DependsOn.Field, '__none__') }}
              ConditionMet: >-
                ${{ or(
                  eq(convertToJson(rule.DependsOn), 'null'),
                  and(in(convertToJson(rule.DependsOn.Present), 'true', '"true"'),
                      ne(convertToJson(parameters.Object[coalesce(rule.DependsOn.Field, '__none__')]), 'null')),
                  and(in(convertToJson(rule.DependsOn.Present), 'false', '"false"'),
                      eq(convertToJson(parameters.Object[coalesce(rule.DependsOn.Field, '__none__')]), 'null')),
                  and(ne(convertToJson(rule.DependsOn.Equals), 'null'),
                      eq(parameters.Object[coalesce(rule.DependsOn.Field, '__none__')], rule.DependsOn.Equals)),
                  and(ne(convertToJson(rule.DependsOn.In), 'null'),
                      containsValue(rule.DependsOn.In, parameters.Object[coalesce(rule.DependsOn.Field, '__none__')])),
                  and(ne(convertToJson(rule.DependsOn.NotIn), 'null'),
                      not(containsValue(rule.DependsOn.NotIn, parameters.Object[coalesce(rule.DependsOn.Field, '__none__')])))
                ) }}

      # Unknown fields: every key in Object must be named by at least one rule.
      # 'parameters.Rules.*.Field' (property projection over a list) is unverified in template context.
      # Fallback: an explicit KnownFields list parameter.
      - ${{ if eq(parameters.AllowUnknownFields, false) }}:
          - ${{ each kv in parameters.Object }}:
              - ${{ if not(containsValue(parameters.Rules.*.Field, kv.key)) }}:
                  - "${{ parameters.ErrorPrefix }}: '${{ parameters.PathPrefix }}${{ kv.key }}' is not a recognised field.${{ parameters.ErrorSuffix }}": Error
```

The multi-line `ConditionMet` is for readability only. Whether a folded scalar (`>-`) is accepted around a full-value `${{ }}` is unverified; the generated file can keep it on one line.

#### `validate_rule.jobs.yml`

Shape flags are derived from `Json` at the top of each check, so `convertToJson` is not repeated. Written out:

| Flag        | Expression                                                                                                       |
| ----------- | ---------------------------------------------------------------------------------------------------------------- |
| `IsString`  | `startsWith(parameters.Json, '"')`                                                                               |
| `IsList`    | `startsWith(parameters.Json, '[')`                                                                               |
| `IsMap`     | `startsWith(parameters.Json, '{')`                                                                               |
| `IsBoolean` | `in(parameters.Json, 'true', 'false', '"true"', '"false"')`                                                     |
| `IsNumber`  | `not(or(startsWith(parameters.Json, '"'), startsWith(parameters.Json, '['), startsWith(parameters.Json, '{'), in(parameters.Json, 'true', 'false', 'null')))` (bare numbers only; see [Scalar types](#scalar-types-conflicting-evidence)) |
| `IsEmpty`   | `in(parameters.Json, '""', '[]', '{}')`                                                                          |

`length()` is not used anywhere, because it is documented only for strings and arrays. Emptiness is tested on the JSON form instead.

To keep the sketch short, the flags are written by name below (`IsString` and so on). In the real file they are either expanded inline or passed as extra parameters from `validate.jobs.yml`. The second option is preferred, because it keeps each check readable.

```yaml
parameters:
  - { name: Rule, type: object }
  - { name: Path, type: string }
  - { name: ErrorPrefix, type: string }
  - { name: ErrorSuffix, type: string, default: "" }
  - { name: AllowUnknownFields, type: boolean, default: true }
  - { name: Value, type: object, default: "" }
  - { name: Json, type: string }
  - { name: Present, type: boolean }
  - { name: Required, type: boolean }
  - { name: NonEmpty, type: boolean }
  - { name: Forbidden, type: boolean }
  - { name: NonEmptyEntries, type: boolean }
  - { name: ConditionMet, type: boolean }
  - { name: DependsOnField, type: string }

jobs:
  # ---- Rule sanity: an unknown Type is a bug in the rule list, not in the user's config ----
  - ${{ if and(ne(convertToJson(parameters.Rule.Type), 'null'), notIn(parameters.Rule.Type, 'string', 'number', 'boolean', 'list', 'map', 'object', 'any')) }}:
      - "Schema rule error: '${{ parameters.Path }}' has unknown Type '${{ parameters.Rule.Type }}'.": Error

  # ---- DependsOn not met ----
  - ${{ if and(eq(parameters.ConditionMet, false), eq(parameters.Present, true), eq(parameters.Rule.Otherwise, 'Forbidden')) }}:
      - "${{ parameters.ErrorPrefix }}: ${{ coalesce(parameters.Rule.Message, format('''{0}'' cannot be used with the current value of ''{1}''.', parameters.Path, parameters.DependsOnField)) }}${{ parameters.ErrorSuffix }}": Error

  # ---- DependsOn met (or no DependsOn) ----
  - ${{ if eq(parameters.ConditionMet, true) }}:
      - ${{ if and(eq(parameters.Forbidden, true), eq(parameters.Present, true)) }}:
          - "${{ parameters.ErrorPrefix }}: ${{ coalesce(parameters.Rule.Message, format('''{0}'' is not supported.', parameters.Path)) }}${{ parameters.ErrorSuffix }}": Error

      - ${{ if and(eq(parameters.Required, true), eq(parameters.Present, false)) }}:
          - "${{ parameters.ErrorPrefix }}: ${{ coalesce(parameters.Rule.Message, format('''{0}'' is required.', parameters.Path)) }}${{ parameters.ErrorSuffix }}": Error

      - ${{ if eq(parameters.Present, true) }}:
          # Type. A failed type check skips every check below that depends on the type.
          - ${{ if and(eq(parameters.Rule.Type, 'string'), not(IsString)) }}:
              - "...: '${{ parameters.Path }}' must be a string.": Error
          - ${{ if and(eq(parameters.Rule.Type, 'list'), not(IsList)) }}:
              - "...: '${{ parameters.Path }}' must be a list.": Error
          - ${{ if and(in(parameters.Rule.Type, 'map', 'object'), not(IsMap)) }}:
              - "...: '${{ parameters.Path }}' must be an object of key/value pairs.": Error
          - ${{ if and(eq(parameters.Rule.Type, 'boolean'), not(IsBoolean)) }}:
              - "...: '${{ parameters.Path }}' must be true or false.": Error
          - ${{ if and(eq(parameters.Rule.Type, 'number'), not(IsNumber)) }}:
              - "...: '${{ parameters.Path }}' must be a number.": Error

          # NonEmpty: only for strings, lists and maps
          - ${{ if and(eq(parameters.NonEmpty, true), IsEmpty) }}:
              - "...: '${{ parameters.Path }}' must not be empty.": Error

          # Values: only for non-empty scalars, so a map or '' gets one error, not two
          - ${{ if and(ne(convertToJson(parameters.Rule.Values), 'null'), or(IsString, IsNumber, IsBoolean), not(IsEmpty), not(containsValue(parameters.Rule.Values, parameters.Value))) }}:
              - "...: '${{ parameters.Path }}' must be one of (${{ join(', ', parameters.Rule.Values) }}).": Error

          # ForbiddenValues: same guard and same comparison function as Values
          - ${{ if and(ne(convertToJson(parameters.Rule.ForbiddenValues), 'null'), or(IsString, IsNumber, IsBoolean), containsValue(parameters.Rule.ForbiddenValues, parameters.Value)) }}:
              - "...: ${{ coalesce(parameters.Rule.Message, format('''{0}'' cannot be {1} here.', parameters.Path, parameters.Json)) }}": Error

          # Min / Max: the BOUND goes on the left, so the value is converted to a number
          # (lt/gt convert the right operand to the left operand's type; a string on the left would compare as text).
          - ${{ if and(IsNumber, ne(convertToJson(parameters.Rule.Min), 'null'), gt(parameters.Rule.Min, parameters.Value)) }}:
              - "...: '${{ parameters.Path }}' must be at least ${{ parameters.Rule.Min }}.": Error
          - ${{ if and(IsNumber, ne(convertToJson(parameters.Rule.Max), 'null'), lt(parameters.Rule.Max, parameters.Value)) }}:
              - "...: '${{ parameters.Path }}' must be at most ${{ parameters.Rule.Max }}.": Error

          # ItemType: the item itself is not printed, because multi-line JSON cannot be flattened
          # ('\n' is not an escape sequence in template expressions).
          - ${{ if and(IsList, eq(parameters.Rule.ItemType, 'string')) }}:
              - ${{ each item in parameters.Value }}:
                  - ${{ if not(startsWith(convertToJson(item), '"')) }}:
                      - "...: '${{ parameters.Path }}[]' items must be strings.": Error

          # NonEmptyEntries: keys non-empty; values non-empty and not null. No length() on values.
          - ${{ if and(IsMap, eq(parameters.NonEmptyEntries, true)) }}:
              - ${{ each kv in parameters.Value }}:
                  - ${{ if or(eq(kv.key, ''), in(convertToJson(kv.value), '""', 'null', '[]', '{}')) }}:
                      - "...: '${{ parameters.Path }}' entry '${{ kv.key }}' must have a non-empty key and value.": Error

          # AllOrNone: loop over the keys that ARE set and report each missing group member.
          - ${{ if and(IsMap, ne(convertToJson(parameters.Rule.AllOrNone), 'null')) }}:
              - ${{ each kv in parameters.Value }}:
                  - ${{ if containsValue(parameters.Rule.AllOrNone, kv.key) }}:
                      - ${{ each member in parameters.Rule.AllOrNone }}:
                          - ${{ if eq(convertToJson(parameters.Value[member]), 'null') }}:
                              - "...: '${{ parameters.Path }}.${{ member }}' is required because '${{ parameters.Path }}.${{ kv.key }}' is set.": Error

          # Properties: recurse into the object (unverified - see Nested rules)
          - ${{ if and(IsMap, ne(convertToJson(parameters.Rule.Properties), 'null')) }}:
              - template: validate.jobs.yml
                parameters:
                  Object: ${{ parameters.Value }}
                  Rules: ${{ parameters.Rule.Properties }}
                  ErrorPrefix: ${{ parameters.ErrorPrefix }}
                  ErrorSuffix: ${{ parameters.ErrorSuffix }}
                  AllowUnknownFields: ${{ parameters.AllowUnknownFields }}
                  PathPrefix: ${{ parameters.Path }}.

          # ItemRules: recurse for each list item. A non-object item is reported by validate.jobs.yml's own shape check.
          - ${{ if and(IsList, ne(convertToJson(parameters.Rule.ItemRules), 'null')) }}:
              - ${{ each item in parameters.Value }}:
                  - template: validate.jobs.yml
                    parameters:
                      Object: ${{ item }}
                      Rules: ${{ parameters.Rule.ItemRules }}
                      ErrorPrefix: ${{ parameters.ErrorPrefix }}
                      ErrorSuffix: ${{ parameters.ErrorSuffix }}
                      AllowUnknownFields: ${{ parameters.AllowUnknownFields }}
                      PathPrefix: ${{ parameters.Path }}[].
```

`"...:"` in the sketch stands for the full form `"${{ parameters.ErrorPrefix }}: ${{ coalesce(parameters.Rule.Message, <standard text>) }}${{ parameters.ErrorSuffix }}"`.

#### Message override scope

- `Message` replaces only the `'<Path>' <problem>.` part. `ErrorPrefix` and `ErrorSuffix` are always added.
- `Message` applies to **every** check in its rule. So a rule with a `Message` should contain only one check; split the field across rules when it needs both a custom message and standard checks (see [Splitting a field across rules](#splitting-a-field-across-rules)).

#### `map` versus `object`

Both types require a JSON object, and the type check is the same. They differ in intent and in which properties apply:

- `map`: any keys, which are data (`BackendConfig`, `EnvironmentVariableMappings`). Use `NonEmptyEntries`. Unknown-field checking does not apply.
- `object`: a fixed set of known keys (`KeyVaultConfig`, `ConfigSources[]` items). Use `Properties`, `AllOrNone` and, through recursion, the unknown-field check.

#### `DependsOn` edge cases

- **"Exactly one of" is not enforced by the engine.** The `or(...)` is true if any branch is true, so a rule with both `Present` and `Equals` silently gets OR semantics. The meta-schema test (see [Testing](#testing)) rejects such rules instead.
- **`NotIn` with the other field absent** counts as met, because `containsValue(list, null)` is false. This is intended: "`RunMode` is not `PlanOnly`" is true when `RunMode` is missing. Missing required fields are reported by their own rules.
- **`Equals` / `In` / `NotIn` compare case-insensitively** (see [Case sensitivity](#case-sensitivity)).

#### Case sensitivity

`eq`, `in` and `containsValue` compare strings case-insensitively, so `Values` and `DependsOn.Equals`/`In`/`NotIn` accept `planverifyapply` for `PlanVerifyApply`. Today's checks behave the same way, so nothing changes, but this should be documented. A `CaseSensitive` option is not proposed.

The unknown-field check also uses `containsValue`, so a key `runmode` is **not** reported as unknown. It is unverified whether `parameters.Object['RunMode']` then finds `runmode`. If key lookup is case-sensitive, the user gets a misleading "`RunMode` is required" error instead of "unknown field". Probe it. If lookup is case-sensitive, the unknown-field check needs a case-sensitive comparison, for example `eq(convertToJson(kv.key), convertToJson(<rule field>))` in a loop.

#### Notes on the sketch

- **Repeated errors.** `AllOrNone` with two of three members set reports the missing member twice, once per member that is set. The gated deployment job also includes `jobs/terraform_deploy.yml` more than once, so the deploy schema already runs, and reports, more than once today. Whether Azure DevOps de-duplicates, orders or truncates multiple `Unexpected value` errors is undocumented. Probe a template that emits 10+ errors before any test asserts on a later error.
- **Unverified expressions** to probe before building:
  - Whether `or` / `and` short-circuiting means skipped arguments are never _evaluated_ (documented as "short-circuits", but evaluation is not stated). The `'__none__'` key makes this mostly harmless.
  - `parameters.Rules.*.Field` projection for the unknown-field check. Fallback: an explicit `KnownFields` list parameter.
  - Passing a missing field as `Value` to an `object` parameter (it may arrive as `null` or as the default `''`). `Present` and `Json` are computed in the caller, so this only affects error text.
  - `validate_rule.jobs.yml` including `validate.jobs.yml` (mutual recursion) for `ItemRules` and `Properties`. Do not build `Properties` until this passes.
  - Whether a full-value `${{ }}` passed to a `boolean` parameter keeps its type. The sketch avoids depending on it by always testing with `eq(parameters.X, true)`.
  - Whether `eq(<boolean>, 'false')` converts the string to `False`. Not needed if flags are normalised as above.
  - Case sensitivity of `parameters.Object[<key>]` (see above).
  - Whether a folded scalar (`>-`) around a full-value `${{ }}` is accepted.
- **Wrapping depth.** Job → schema → (common) → `validate` → `validate_rule` (→ `validate` → `validate_rule` for nested rules) adds 3–5 template layers. That goes against the repository convention to avoid wrapping templates unless necessary (`docs/developers/explanation/double-wrapping.md`). The justification: these layers are pure compile-time validation, emit no jobs or steps when the config is valid, and replace hundreds of lines of duplicated expressions. This must be stated in the code comments of the engine files.

#### Template limits

From Microsoft Learn, "Use YAML templates in pipelines", section "Imposed limits on template updates" (Azure DevOps Services, page dated 2026-06-17):

- No more than 100 **separate** YAML files may be included, directly or indirectly. Repeated inclusions of the same file count once, so the engine's two files are cheap.
- No more than 100 levels of template nesting.
- No more than 20 MB of memory consumed while parsing the YAML (in practice, 600 KB – 2 MB of on-disk YAML).

Earlier versions of the same page, labelled "Azure DevOps Server 2022 – Azure DevOps Server 2019", give **20** levels of nesting and **10 MB** of parse memory. If Azure DevOps Server must be supported (see [Open questions](#open-questions)), budget against those figures.

Parse memory is the binding constraint, because every rule expands `validate_rule` again. The worst case must be measured on a **full public-job compile**: `jobs/terraform_gated_deployment.yml` → `jobs/terraform_deploy.yml` (included more than once) → schema → common → engine → items, with every rule and several `ConfigSources` items. Schema-only compiles understate the cost.

### Pipeline levels

A template can only be inserted at one level of a pipeline (`stages:`, `jobs:` or `steps:`). Today the schemas use `jobs:` and `config_sources.yml` uses `steps:`. Provide:

- `schemas/lib/validate.jobs.yml`
- `schemas/lib/validate.steps.yml`
- `schemas/lib/validate.stages.yml`, only if it is needed.

To avoid hand-maintaining identical logic three times, generate the variants from a single source with a script in `tools/`. A compile test fails if the generated files are out of date. The generator must rewrite the top-level `jobs:` key **and** the relative `template: validate_rule.jobs.yml` / `template: validate.jobs.yml` references, so that the `steps` variant never includes a `jobs` file. A compile test must exercise `ItemRules` through the `steps` variant to catch this.

### Nested rules

`ConfigSources` items are objects with their own rules (`Type` decides which fields apply), and `KeyVaultConfig` is an object with its own sub-field rules (`Properties`). Preferred approach: `validate_rule.jobs.yml` includes `validate.jobs.yml` for each list item or sub-object (see the sketch). Recursion is undocumented: no Microsoft source says whether A → B → A works, or whether cycles are rejected before expansion. If it works, each level counts against the nesting limit. **This must be prototyped first.** Fallback if templates cannot include each other recursively: a third template, `validate_items.jobs.yml`, that supports exactly one level of `ItemRules` with no further nesting. That covers every schema in the repository today.

### Shared rule sets

Rules common to deploy and destroy (`AzDOEnvironmentName`, `AzureServiceConnection`, `BackendConfig`, `EnvironmentVariableMappings`, `VariableFiles`) live in one template, for example `schemas/terraform_common_config.yml`. It calls the engine once, with the shared rules followed by the schema's own rules.

Templates cannot return data, so a caller cannot fetch the shared rules and merge them. Instead, the common template takes an `AdditionalRules` parameter and appends it to its own rules:

```yaml
# schemas/terraform_common_config.yml (sketch)
jobs:
  - template: /schemas/lib/validate.jobs.yml
    parameters:
      Object: ${{ parameters.Config }}
      ErrorPrefix: "'${{ parameters.EnvironmentName }}' environment error"
      AllowUnknownFields: false
      Rules:
        - {
            Field: AzDOEnvironmentName,
            Type: string,
            Required: true,
            NonEmpty: true,
          }
        - { Field: BackendConfig, Type: map, NonEmptyEntries: true }
        # ...other shared rules
        - ${{ parameters.AdditionalRules }} # inserting an array into an array flattens it
```

There is only one engine call, with the full rule list, so the unknown-field check already knows every field and no separate key list is needed. Inserting an array into an array flattens it (documented under template expressions), so no `each` is needed.

### Gaps the rule model does not cover yet

Comparing the rule model with [Current checks per schema](#current-checks-per-schema) shows several cases it cannot express yet. Each needs a decision before implementation:

1. **`ApplyEvenIfNoChanges` can only be `true` with `PlanVerifyApply`.** The condition depends on the field's own **value**, not just whether it is present. `DependsOn` with `Otherwise: Forbidden` would also forbid `false`. Options: (a) add `ForbiddenValues: [true]` with `DependsOn: { Field: RunMode, In: [PlanOnly, ApplyOnly] }`, which is a small, general addition; or (b) keep a hand-written check after the engine call. Proposed: (a).
2. **`config_sources.yml` validates a list, not an object.** The engine's `Object` is a map. Wrap the list in a **block** mapping (a `${{ }}` inside a YAML flow mapping such as `{ ConfigSources: ${{ ... }} }` is invalid YAML, because `{`, `}` and `,` end a plain scalar in flow context):

   ```yaml
   Object:
     ConfigSources: ${{ parameters.ConfigSources }}
   ```

   Then add one rule, `{ Field: ConfigSources, Type: list, Required: true, NonEmpty: true, ItemType: object, ItemRules: [...] }`. Its prefix is `Invalid ConfigSources`, which does not fit the `<ErrorPrefix>: '<Path>' <problem>.` format well. Use `ErrorPrefix: 'Invalid ConfigSources'`, and append the documentation link with the `ErrorSuffix` engine parameter, which is added to every message. This also adds the link to the empty-list message, which has none today. That is a minor wording change, and it is accepted.
3. **Rules for sub-fields of an object** (`KeyVaultConfig.ServiceConnection` must be a non-empty string). `ItemRules` only covers list items. Add `Properties: [<rules>]`, applied to the object value with `PathPrefix: '<Path>.'`, using the same recursion as `ItemRules`. Then `AllOrNone` only enforces "all or none", and `Properties` enforces each member's type and `NonEmpty`.
4. **`AllOrNone` and empty strings.** Today a member set to `''` counts as "not set" (truthiness). The engine counts any present key as set. So `KeyVaultConfig: { Name: '' }` changes from "no error" to "`ServiceConnection` and `SecretsFilter` are required", and `Properties` also reports that `Name` must not be empty. This is stricter, and arguably correct, but it must be listed in the changelog.
5. **Unknown fields with two schemas per object.** A gated job's config passes through the gated schema **and** the non-gated schema (see [Repository context](#repository-context)). Neither knows the other's fields. Proposed: the unknown-field check runs only in the non-gated schemas (`terraform_deploy_config.yml`, `terraform_destroy_config.yml`), whose rule lists also name the gated-only fields as `{ Field: RunMode, Type: any }` and so on. Those rules are type-free, so the gated schema stays responsible for validating them. Gated schemas use `AllowUnknownFields: true`.
6. **The `KeyVaultConfig` vs `ConfigSources` message** includes an upgrade-guide link. Keep it as a `Message` override on that rule.

### Target rule sets

The rules each schema should contain after migration. They assume the gaps above are resolved as proposed. Messages that need a `Message` override are marked _(msg)_.

`terraform_gated_destroy_config.yml` (`AllowUnknownFields: true`):

```yaml
- { Field: AzDOEnvironmentName, Type: string, Required: true, NonEmpty: true }
- {
    Field: RunMode,
    Type: string,
    Required: true,
    NonEmpty: true,
    Values: [PlanVerifyDestroy, PlanOnly, DestroyOnly],
  }
- {
    Field: VerificationTimeoutBehaviour,
    Type: string,
    Values: [reject, resume],
  }
- { Field: VerificationTimeoutInMinutes, Type: number, Min: 1, Max: 43200 }
```

`terraform_gated_deployment_config.yml` (`AllowUnknownFields: true`): the same as gated destroy, with `RunMode` values `[PlanVerifyApply, PlanOnly, ApplyOnly]`, plus:

```yaml
- {
    Field: VerificationMode,
    Required: true,
    DependsOn: { Field: RunMode, Equals: PlanVerifyApply },
  }
- {
    Field: VerificationMode,
    Type: string,
    Values: [VerifyOnDestroy, VerifyOnAny, VerifyDisabled],
  }
- { Field: ApplyEvenIfNoChanges, Type: boolean }
- {
    Field: ApplyEvenIfNoChanges,
    ForbiddenValues: [true, "true"],
    DependsOn: { Field: RunMode, In: [PlanOnly, ApplyOnly] },
  }
```

`terraform_common_config.yml` (shared by deploy and destroy; `AllowUnknownFields: false`):

```yaml
- { Field: AzDOEnvironmentName, Type: string, Required: true, NonEmpty: true }
- { Field: AzureServiceConnection, Type: string, NonEmpty: true }
- { Field: BackendConfig, Type: map, NonEmptyEntries: true }
- { Field: EnvironmentVariableMappings, Type: map, NonEmptyEntries: true }
- { Field: VariableFiles, Type: list, ItemType: string }
- { Field: ConfigSources, Type: list } # items are validated by config_sources.yml when the job uses them
- { Field: JobsVariableMappings, Type: list } # read by both jobs, not validated today (pipeline variable entries)
# Gated-only fields, named so that they are not reported as unknown:
- { Field: RunMode, Type: any }
- { Field: VerificationTimeoutBehaviour, Type: any }
- { Field: VerificationTimeoutInMinutes, Type: any }
```

`terraform_deploy_config.yml` passes as `AdditionalRules`:

```yaml
- {
    Field: VerificationMode,
    Type: string,
    Values: [VerifyOnDestroy, VerifyOnAny, VerifyDisabled],
  }
- { Field: OutputVariables, Type: list, ItemType: string }
- { Field: ApplyEvenIfNoChanges, Type: any }
- Field: KeyVaultConfig
  Type: object
  AllOrNone: [ServiceConnection, Name, SecretsFilter]
  Properties:
    - { Field: ServiceConnection, Type: string, NonEmpty: true }
    - { Field: Name, Type: string, NonEmpty: true }
    - { Field: SecretsFilter, Type: string, NonEmpty: true }
- Field: ConfigSources
  DependsOn: { Field: KeyVaultConfig, Present: false }
  Otherwise: Forbidden
  Message: "... use either KeyVaultConfig (legacy) or ConfigSources (new), not both. ... upgrade guide link" # (msg)
```

`terraform_destroy_config.yml` passes as `AdditionalRules`:

```yaml
- {
    Field: KeyVaultConfig,
    Forbidden: true,
    Message: "... KeyVaultConfig is deprecated and not supported for destroy workflows. Use ConfigSources instead.",
  } # (msg)
- {
    Field: VerificationMode,
    Forbidden: true,
    Message: "... VerificationMode is not supported for destroy workflows. Use RunMode 'PlanVerifyDestroy' for gated destroy.",
  } # (msg)
```

`config_sources.yml` (`steps:` level, `ErrorPrefix: 'Invalid ConfigSources'`, `ErrorSuffix: ' See docs/definition_docs/shared/config_sources.md'`):

```yaml
- Field: ConfigSources
  Type: list
  Required: true
  NonEmpty: true
  ItemType: object
  ItemRules:
    - {
        Field: Type,
        Type: string,
        Required: true,
        NonEmpty: true,
        Values: [KeyVault],
      }
    - { Field: ServiceConnection, Type: string, Required: true, NonEmpty: true }
    - {
        Field: Name,
        Type: string,
        Required: true,
        NonEmpty: true,
        DependsOn: { Field: Type, Equals: KeyVault },
      }
    - {
        Field: SecretsFilter,
        Type: string,
        NonEmpty: true,
        DependsOn: { Field: Type, Equals: KeyVault },
      }
    - {
        Field: RunAsPreJob,
        Type: boolean,
        DependsOn: { Field: Type, Equals: KeyVault },
      }
```

The new properties these rule sets use (`ForbiddenValues`, `Properties`, and the `ErrorSuffix` engine parameter) must be added to [Rule properties](#rule-properties) and to the engine.

### Layout

```text
schemas/
  lib/
    validate.jobs.yml        # generated
    validate_rule.jobs.yml   # generated
    validate.steps.yml       # generated
    validate_rule.steps.yml  # generated
    validate.CompileTests.ps1
  terraform_common_config.yml
  terraform_deploy_config.yml        # rules only
  terraform_destroy_config.yml       # rules only
  terraform_gated_deployment_config.yml
  terraform_gated_destroy_config.yml
  config_sources.yml
tools/
  New-SchemaValidators.ps1           # generates the per-level variants
```

## Testing

- `schemas/lib/validate.CompileTests.ps1`: a pass/fail grid per rule type and property, including the bug cases (`"a{b"` as a valid string, nested-key name collisions, empty map and empty list), plus:
  - Values that are explicitly `null`, `''`, numeric strings (`"9"` against `Max: 43200`), decimals, and `"true"`/`"false"` strings.
  - A non-map `Object`, and a non-object `ConfigSources[]` item (one clear error each, with no follow-on errors).
  - Unknown keys at the top level, inside a `ConfigSources[]` item and inside `KeyVaultConfig`.
  - Rules written with string flags (`Required: "false"`) to prove the flag normalisation works.
- **Meta-schema test.** Rule typos fail silently: `Type: strng` gets no type check, and `Requried: true` is ignored. The engine reports an unknown `Type` (see the sketch). In addition, a compile test validates every schema's rule list **with the engine itself**: a rule set that describes rules (known rule keys only, `Type` from the allowed set, `Otherwise` from `Ignore`/`Forbidden`, and `DependsOn` with `Field` plus exactly one of `Present`/`Equals`/`In`/`NotIn`). "Exactly one of" cannot be expressed as a rule today, so the test checks it with a hand-written expression.
- **YAML-literal variants.** The compile tests send `Parameters` as REST/JSON `templateParameters`, but consumers write YAML literals, and the two may type scalars differently (see [Scalar types](#scalar-types-conflicting-evidence)). Every regression case involving booleans or numbers needs a variant that embeds the config as YAML in the pipeline text, for example through `-TransformYamlFunction` or the run API's `yamlOverride`.
- **Full public-job compile** of the worst case, to measure parse memory (see [Template limits](#template-limits)).
- The existing `schemas/*.CompileTests.ps1` and `jobs/*.CompileTests.ps1` act as the regression suite during migration. Expected `ErrorMessage` values change to the standard format.
- Best done **after** the test-framework literal-matching change, so that error-message assertions are exact. That change lives in a separate design, `designs/test-framework-improvements.md` (item #3), which is **not yet in the repository**. In short: `tests/framework/Core.ParameterisedTestRunner.ps1` currently matches with `-like "*$ErrorMessage*"`. It should use a literal substring match (`.Contains()`), so that `[`, `]`, `*` and `?` in messages such as `'ConfigSources[].Name'` are matched literally. Until then, those characters must be escaped in expected messages with `` ` `` (for example ``ConfigSources`[`].Name``). An unbalanced `[` in a `-like` pattern can throw an error instead of simply not matching. So land the `.Contains()` change, or escape the brackets, before migrating any message that contains `[]`.

## Versioning

`schemas/` is internal and has no SemVer guarantees. However:

- Error message text is **visible to consumers**. Standardising it needs a `CHANGELOG.md` entry under `## [Unreleased]`.
- Rejecting unknown fields could break consumers who pass extra fields to the public `jobs/` templates. That would be a **breaking change** if made an error (see open questions).
- Fixing bug 3 (empty values are now validated) could reject configurations that are accepted today, for example `BackendConfig: {}`. Decide per field whether empty is allowed (`NonEmpty`).
- Other behaviour changes that need changelog entries:
  - **Empty strings now fail type checks.** Today `BackendConfig: ''` or `VariableFiles: ''` is skipped as falsy. The engine treats `''` as present and reports "must be an object of key/value pairs" or "must be a list".
  - **The `KeyVaultConfig` / `ConfigSources` exclusion fires more often.** Today it fires only when a `KeyVaultConfig` member is truthy. The new rule fires whenever `KeyVaultConfig` is present, including `KeyVaultConfig: {}` or all-empty members.
  - **`AllOrNone` counts empty strings as set** (gap 4).
  - **Explicit `null`, `~` or an empty YAML value counts as absent**, as it does today. This means `Forbidden` and `Otherwise: Forbidden` rules do not fire for `KeyVaultConfig: ~`.
  - **List item errors no longer print the item.** `VariableFiles item '<json>' is not a string` becomes `'VariableFiles[]' items must be strings.`, because multi-line JSON cannot be flattened in a template expression.

## Migration plan

1. Prototype: probe the unverified expressions listed under [Notes on the sketch](#notes-on-the-sketch), then build the `jobs:` engine with its compile tests.
2. Migrate `terraform_gated_destroy_config.yml` (the smallest) and compare before and after.
3. Add the generator and the `steps:` variant; migrate `config_sources.yml`.
4. Extract `terraform_common_config.yml`; migrate the deploy, destroy and gated-deployment schemas.
5. Update the docs in `docs/definition_docs/` that describe validation behaviour, and update `CHANGELOG.md`.

## Review outcomes

An independent review checked the design against Microsoft's documentation. The engine sketch above already includes the corrections. This section records what changed and what was answered from the repository.

**Corrected in the sketch:**

| Finding                                                                                     | Change                                                                                                   |
| ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `lt`/`gt` convert the right operand to the left operand's type, so `gt("9", 43200)` compares text | The bound goes on the left (`gt(Min, Value)`), and only bare numbers are range-checked                    |
| The boolean check rejected `"true"`, contradicting the stated policy                        | `IsBoolean` accepts `true`, `false`, `"true"`, `"false"`                                                 |
| Rule flags may arrive as strings (`"false"` is truthy)                                      | Flags are normalised with `in(convertToJson(x), 'true', '"true"')`; booleans are tested with `eq(x, true)` |
| `replace(..., '\n', ...)` does not work: no backslash escapes exist                          | Item errors no longer print the item                                                                     |
| `length()` is documented only for strings and arrays                                         | Emptiness is tested on the JSON form (`""`, `[]`, `{}`)                                                  |
| `Values` produced a second error for maps and `''`                                           | `Values` and `ForbiddenValues` only run for non-empty scalars                                            |
| `Object` was never checked to be a map, and recursion entered non-object items             | `validate.jobs.yml` checks `Object` first and skips its rules if it is not a map                         |
| Nested calls dropped `AllowUnknownFields` and `ErrorSuffix`                                  | Both are passed down; unknown fields are now checked in list items and sub-objects                       |
| Indexing with a null key is undocumented                                                    | `coalesce(rule.DependsOn.Field, '__none__')`                                                             |
| `${{ }}` inside a YAML flow mapping is invalid YAML                                           | Block mapping for the `ConfigSources` wrapper                                                            |
| `each` was used to insert `AdditionalRules`                                                 | Plain array insertion, which flattens                                                                    |
| Template limits were wrong (20 levels)                                                      | Now 100 files / 100 levels / 20 MB for Services, 20 levels / 10 MB for older Server versions                |
| "One engine call" contradicted "one include per rule"                                       | Wording fixed                                                                                            |
| `Message` scope and `map`/`object` difference were undefined                               | Both defined in the sketch section                                                                       |
| Typos in rules fail silently                                                                | Unknown `Type` is reported, and a meta-schema test is added                                              |

**Answered from the repository:**

- **Do the gated jobs pass the config object through unchanged?** Yes. `jobs/terraform_gated_deployment.yml` and `jobs/terraform_gated_destroy.yml` pass `${{ parameters.TerraformDeploymentConfig }}` / `${{ parameters.TerraformDestroyConfig }}` unchanged to their schema and to each inclusion of `jobs/terraform_deploy.yml` / `jobs/terraform_destroy.yml`. Each gated job includes the non-gated job **more than once**, so the non-gated schema runs more than once per compile.
- **Do the job templates read fields that no rule names?** Yes: `JobsVariableMappings`. Both `jobs/terraform_deploy.yml` and `jobs/terraform_destroy.yml` read it: a list whose entries are inserted as job variables (`template` entries become `template: <x>@self`, entries with `name` or `group` are inserted as they are). It is not validated today, and has been added to the common rule set. Fields read by each job (from a scan of `parameters.<Config>.<Field>`):
  - `terraform_deploy.yml`: `AzDOEnvironmentName`, `AzureServiceConnection`, `BackendConfig`, `ConfigSources`, `EnvironmentVariableMappings`, `JobsVariableMappings`, `KeyVaultConfig`, `OutputVariables`, `VariableFiles`, `VerificationMode`.
  - `terraform_destroy.yml`: `AzDOEnvironmentName`, `AzureServiceConnection`, `BackendConfig`, `ConfigSources`, `EnvironmentVariableMappings`, `JobsVariableMappings`, `VariableFiles`.
  - `terraform_gated_deployment.yml`: `ApplyEvenIfNoChanges`, `RunMode`, `VerificationTimeoutBehaviour`, `VerificationTimeoutInMinutes`.
  - `terraform_gated_destroy.yml`: `RunMode`, `VerificationTimeoutBehaviour`, `VerificationTimeoutInMinutes`.

  Before `AllowUnknownFields: false` is enabled, re-run this scan and check the documented fields in `docs/definition_docs/terraform_pipeline/terraform_job_config.md`. Then add a compile test that passes a config containing **every** documented field.
- **Can a missing config produce the schema's own message?** No. The config parameters of the `jobs/` templates and the schemas have no default, so Azure DevOps reports its own `A value for the '<Name>' parameter must be provided.` before any schema runs. The existing tests already expect that text, and nothing changes.

## Open questions

1. **Error messages:** adopt the standard format (needs a changelog entry), or keep today's exact wording via a `Message` override on every rule?
2. **Unknown fields:** error (catches typos, but potentially breaking for the public `jobs/`), warning, or off by default with opt-in per schema?
3. **Location:** `schemas/lib/` as proposed, or elsewhere?
4. **Order of work:** after the test-framework plan (at least #3), or prototype now?
5. **Run-mode-only fields:** should `VerificationTimeoutInMinutes` and `VerificationTimeoutBehaviour` use `Otherwise: Ignore` (today's behaviour) or `Otherwise: Forbidden` (catches misconfiguration, but breaking)?
6. **Multiple conditions:** is a single `DependsOn` enough, or should a fixed second slot be designed in from the start?
7. **Empty values (bug 3):** should an empty `BackendConfig`, `EnvironmentVariableMappings` or `VariableFiles` stay valid (today's behaviour, relied on by "Apply with Empty Backend Configuration"), or be rejected with `NonEmpty`? Proposed default: keep empty values valid and validate only the entries. This is not a breaking change.
8. **Platform:** Azure DevOps Services only, or Azure DevOps Server too? Older Server versions document a nesting limit of 20 and a 10 MB parse limit, which changes the size budget.
9. **Integers:** should `Type: number` reject decimals (`VerificationTimeoutInMinutes: 1.5`)? If so, add `Integer: true`, implemented as "the JSON form contains no `.`, `e` or `E`".
10. **Nested unknown fields:** should unknown keys inside `ConfigSources[]` items and `KeyVaultConfig` be rejected? The sketch inherits the parent's setting. That is potentially breaking in the same way as at the top level.
11. **`KeyVaultConfig: {}` with `ConfigSources`:** should this be an error now? With `DependsOn: { Present: false }` it is. To keep today's behaviour, the condition would need "`KeyVaultConfig` is present and not empty", which `DependsOn` cannot express.
12. **Numbers as strings:** if YAML numbers arrive as strings, which option from [Scalar types](#scalar-types-conflicting-evidence) is preferred?
