# Schema Validation Library (Review Copy)

This is a restructured copy of `designs/schema-validation-library.md` for review. The content is unchanged, but tables are split into separate items and every item has a `Comment:` block. Refer to items by section number (for example "§9.4").

## 1. Status

Proposed. Open questions (§18) must be answered before starting.

**Comment:**

## 2. Summary

Replace the hand-written checks in `schemas/` with a small library: one generic validation template driven by a declarative list of rules (type, required, allowed values, ranges, list item types, groups of fields that must be set together, and so on). Each schema becomes a short list of rules instead of 40–75 lines of nested template expressions. This also fixes several real bugs in the current checks and adds detection of unknown fields, at the top level and, through recursion, inside list items and sub-objects.

**Comment:**

## 3. Repository context

This section is for readers who cannot browse the repository.

### 3.1 What the repository is

A library of reusable Azure DevOps YAML pipeline templates for Terraform. The **public API** is `pipelines/` and `jobs/` only, which follow SemVer. Everything else (`tasks/`, `stages/`, `schemas/`, `utils/`, `scripts/`, `tools/`) is internal and can change at any time.

**Comment:**

### 3.2 Folders that matter for this design

- `schemas/`: the five validation templates, each with a `<name>.CompileTests.ps1` beside it.
- `jobs/`: public job templates. Each starts its `jobs:` list with a call to its schema.
- `utils/config_sources_task_list.yml`: a `steps:` template that calls `schemas/config_sources.yml` and then adds one Key Vault task per entry.
- `tests/framework/`: the PowerShell compile-test framework.
- `tools/`: maintainer scripts. Today it holds only `Set-TerraformVersionAcrossRepository.ps1`.
- `docs/definition_docs/`: user documentation for the config objects, for example `terraform_pipeline/terraform_job_config.md` and `shared/config_sources.md`.

**Comment:**

### 3.3 Conventions

UTF-8, LF line endings, 2-space indent (`.editorconfig`). Markdown prose is not hard-wrapped. Every user-visible change needs an entry under `## [Unreleased]` in `CHANGELOG.md`. Avoid wrapping a template in another template unless necessary (see `docs/developers/explanation/double-wrapping.md`). Ask the maintainers before adding a new top-level folder or a new dependency.

**Comment:**

### 3.4 How schemas are called

A job template validates its config object before declaring its real job:

```yaml
# jobs/terraform_deploy.yml
jobs:
  - template: /schemas/terraform_deploy_config.yml
    parameters:
      TerraformDeploymentConfig: ${{ parameters.TerraformDeploymentConfig }}
      EnvironmentName: ${{ parameters.EnvironmentName }}
  - deployment: TerraformDeploy...
```

Callers, with the schema each one calls and the level it is called at:

- `jobs/terraform_deploy.yml` calls `terraform_deploy_config.yml` at the `jobs:` level.
- `jobs/terraform_destroy.yml` calls `terraform_destroy_config.yml` at the `jobs:` level.
- `jobs/terraform_gated_deployment.yml` calls `terraform_gated_deployment_config.yml` at the `jobs:` level.
- `jobs/terraform_gated_destroy.yml` calls `terraform_gated_destroy_config.yml` at the `jobs:` level.
- `utils/config_sources_task_list.yml` calls `config_sources.yml` at the `steps:` level.

**Comment:**

### 3.5 One config object, two schemas

The gated job templates validate only the fields they use themselves (`RunMode`, the verification fields and `ApplyEvenIfNoChanges`), and then call `jobs/terraform_deploy.yml` or `jobs/terraform_destroy.yml`, which validate everything else. **One config object is therefore checked by two schemas.** `AzDOEnvironmentName` is checked in both on purpose, so that each job reports a clear error on its own.

**Comment:**

### 3.6 How errors surface

The invalid list item `"<message>": "Error"` makes compilation fail with `Unexpected value '<message>'`. Test cases assert against that text.

**Comment:**

### 3.7 Compile tests

Each `*.CompileTests.ps1` dot-sources `tests/framework/Core.ps1` and calls `Run-Tests -YamlPath <template> -TransformYamlFunction <adds a dummy job so the template compiles on its own> -ValidTestCases @(...) -InvalidTestCases @(...)`.

- A test case is a hashtable with `Description`, `Parameters` (a PowerShell hashtable, sent as JSON) and, for invalid cases, `ErrorMessage`.
- The framework compiles through the Azure DevOps preview-run REST API (`previewRun = $true`, api-version `7.1-preview.1`).
- Error matching is `$apiMessage -like "*$ErrorMessage*"`, a **wildcard** match, so `[`, `]`, `*` and `?` in an expected message are treated as pattern characters. This matters because paths such as `ConfigSources[].Name` contain brackets.
- `Run-AllCompileTests.ps1` in the repository root runs every `*.CompileTests.ps1`.

**Comment:**

## 4. Current state

### 4.1 Schemas and failure mechanism

There are five schema templates: `config_sources.yml`, `terraform_deploy_config.yml`, `terraform_destroy_config.yml`, `terraform_gated_deployment_config.yml` and `terraform_gated_destroy_config.yml`. They are called from `jobs/` and `utils/config_sources_task_list.yml`. Failure is signalled by putting an invalid item into a `jobs:` or `steps:` list, which makes compilation fail with the message as the error:

```yaml
- ${{ if <condition> }}:
    - "'${{ parameters.EnvironmentName }}' environment error: <message>": "Error"
```

**Comment:**

### 4.2 Checks that are hand-written repeatedly

- **Required, non-empty string:** `AzDOEnvironmentName` ×3, `RunMode` ×2, `ServiceConnection`, `Name`.
- **Must be one of a fixed set of values:** `RunMode`, `VerificationMode` ×2, `VerificationTimeoutBehaviour`, `Type`.
- **Optional, but validated if present:** almost every field.
- **Map of non-empty key/value pairs:** `BackendConfig` ×2, `EnvironmentVariableMappings` ×2.
- **List of strings:** `VariableFiles` ×2, `OutputVariables`.
- **Number in a range:** `VerificationTimeoutInMinutes` ×2.
- **Boolean:** `RunAsPreJob`.
- **All-or-none group:** `KeyVaultConfig` (`ServiceConnection`, `Name`, `SecretsFilter`).
- **Mutually exclusive:** `KeyVaultConfig` vs `ConfigSources`.
- **Forbidden field:** `KeyVaultConfig` and `VerificationMode` in destroy.
- **Conditionally required:** `VerificationMode` when `RunMode` is `PlanVerifyApply`.
- **List of objects with their own rules:** `ConfigSources`.

**Comment:**

## 5. Current checks per schema

This is the full list of what each schema checks today. It is the specification that the migrated rules must reproduce, apart from the deliberate bug fixes. `<Env>` stands for `'<EnvironmentName>' environment error`. Messages are quoted exactly.

**Comment:**

### 5.1 `terraform_gated_destroy_config.yml`

Parameters: `TerraformDestroyConfig` (object) and `EnvironmentName` (string).

#### 5.1.1 `AzDOEnvironmentName`: required, non-empty

Message: `<Env>: AzDOEnvironmentName is not properly defined and is a required field.`

**Comment:**

#### 5.1.2 `RunMode`: required, non-empty

Message: `<Env>: RunMode is not properly defined and is a required field. Must be a valid option (PlanVerifyDestroy, PlanOnly, DestroyOnly).`

**Comment:**

#### 5.1.3 `RunMode`: one of `PlanVerifyDestroy`, `PlanOnly`, `DestroyOnly`

Message: `<Env>: RunMode must be a valid option (PlanVerifyDestroy, PlanOnly, DestroyOnly).`

**Comment:**

#### 5.1.4 `VerificationTimeoutBehaviour`: if present, one of `reject`, `resume`

Message: `<Env>: VerificationTimeoutBehaviour must be either 'reject' or 'resume'.`

**Comment:**

#### 5.1.5 `VerificationTimeoutInMinutes`: if present, 1 to 43200

Message: `<Env>: VerificationTimeoutInMinutes must be a number between 1 and 43200 (30 days).`

**Comment:**

### 5.2 `terraform_gated_deployment_config.yml`

Parameters: `TerraformDeploymentConfig` and `EnvironmentName`. It has the same `AzDOEnvironmentName`, `VerificationTimeoutBehaviour` and `VerificationTimeoutInMinutes` checks as §5.1, plus the checks below.

#### 5.2.1 `RunMode`: required, non-empty; one of `PlanVerifyApply`, `PlanOnly`, `ApplyOnly`

Message: the same two messages as §5.1.2 and §5.1.3, with these values.

**Comment:**

#### 5.2.2 `VerificationMode`: when `RunMode` is `PlanVerifyApply`, one of `VerifyOnDestroy`, `VerifyOnAny`, `VerifyDisabled` (so required)

Message: `<Env>: Must provide a valid VerificationMode option (VerifyOnDestroy, VerifyOnAny, VerifyDisabled).`

**Comment:**

#### 5.2.3 `ApplyEvenIfNoChanges`: if present, JSON form is one of `true`, `false`, `"true"`, `"false"`

Message: `<Env>: ApplyEvenIfNoChanges must be a boolean (true or false).`

**Comment:**

#### 5.2.4 `ApplyEvenIfNoChanges`: otherwise, if `true` while `RunMode` is `PlanOnly` or `ApplyOnly`

Message: `<Env>: ApplyEvenIfNoChanges can only be set to true when RunMode is PlanVerifyApply.`

**Comment:**

### 5.3 `terraform_deploy_config.yml`

Parameters: `TerraformDeploymentConfig` and `EnvironmentName`. The deploy schema ignores `RunMode`, `VerificationTimeout*` and `ApplyEvenIfNoChanges`; the gated schema checks them.

#### 5.3.1 `AzDOEnvironmentName`: required, non-empty

Message: as in §5.1.1.

**Comment:**

#### 5.3.2 `VerificationMode`: if present, one of the three modes

Message: `<Env>: If provided, VerificationMode must be a valid option (VerifyOnDestroy, VerifyOnAny, VerifyDisabled).`

**Comment:**

#### 5.3.3 `AzureServiceConnection`: if present (loose match, bug 2), length is not 0

Message: `<Env>: AzureServiceConnection is not properly defined.`

**Comment:**

#### 5.3.4 `ConfigSources` + `KeyVaultConfig`: `ConfigSources` present (loose match) and any `KeyVaultConfig` member is truthy

Message: `<Env>: use either KeyVaultConfig (legacy) or ConfigSources (new), not both. Both parameters cannot coexist in the same configuration. See upgrade guide: docs/user-docs/upgrades/0.1.0-to-0.2.0-keyvaultconfig-to-configsources.md`

**Comment:**

#### 5.3.5 `KeyVaultConfig`: if any of `ServiceConnection`, `Name`, `SecretsFilter` is truthy, all three must be non-empty

Message: `<Env>: KeyVaultConfig.<Member> is required when any Key Vault configuration is provided.` (one per missing member)

**Comment:**

#### 5.3.6 `BackendConfig`: if truthy, a map whose keys and values are all non-empty

Message: `<Env>: BackendConfig is not correct. Must be an object of key/value pairs.`

**Comment:**

#### 5.3.7 `EnvironmentVariableMappings`: as for `BackendConfig`

- Not a map: `<Env>: EnvironmentVariableMappings is not correct. Must be an object of key/value pairs.`
- Bad entry: `<Env>: EnvironmentVariableMappings is not correct. Key: '<k>'. Value: '<v>'. Must be an object of key/value pairs.`

**Comment:**

#### 5.3.8 `VariableFiles`: if truthy, a list of strings

- Not a list: `<Env>: VariableFiles is not correct. Must be a list of string values.`
- Bad item: `<Env>: VariableFiles item '<json>' is not a string. This parameter must be a list of string values.`

**Comment:**

#### 5.3.9 `OutputVariables`: as for `VariableFiles`

Messages: the same two messages, with `OutputVariables`.

**Comment:**

### 5.4 `terraform_destroy_config.yml`

Parameters: `TerraformDestroyConfig` and `EnvironmentName`. It has the same `AzDOEnvironmentName`, `AzureServiceConnection`, `BackendConfig`, `EnvironmentVariableMappings` and `VariableFiles` checks as the deploy schema (no `OutputVariables`), plus the checks below.

#### 5.4.1 `KeyVaultConfig`: must be absent

Message: `<Env>: KeyVaultConfig is deprecated and not supported for destroy workflows. Use ConfigSources instead.`

**Comment:**

#### 5.4.2 `VerificationMode`: must be absent

Message: `<Env>: VerificationMode is not supported for destroy workflows. Use RunMode 'PlanVerifyDestroy' for gated destroy.`

**Comment:**

### 5.5 `config_sources.yml`

Runs at the `steps:` level and takes one parameter, `ConfigSources`, which is a **list**, not an object. Its messages have **no** environment prefix. Every message except the empty-list one ends with `See docs/definition_docs/shared/config_sources.md`, which is left out below.

#### 5.5.1 The list: must not be empty

Message: `Invalid ConfigSources: list cannot be empty. If no configuration sources are needed, omit the parameter entirely.`

**Comment:**

#### 5.5.2 `[].Type`: required, non-empty string, equal to `KeyVault`

Message: `Invalid ConfigSources: entry field 'Type' is required, must be a non-empty string, and must be 'KeyVault'.`

**Comment:**

#### 5.5.3 `[].ServiceConnection`: required, non-empty

Message: `Invalid ConfigSources: entry is missing required field 'ServiceConnection'.`

**Comment:**

#### 5.5.4 `[].ServiceConnection`: string

Message: `Invalid ConfigSources: entry field 'ServiceConnection' must be a string.`

**Comment:**

#### 5.5.5 `[].Name`: when `Type` is `KeyVault`, required, non-empty

Message: `Invalid ConfigSources: KeyVault entry is missing required field 'Name'.`

**Comment:**

#### 5.5.6 `[].Name`: when `Type` is `KeyVault`, string

Message: `Invalid ConfigSources: KeyVault entry field 'Name' must be a string.`

**Comment:**

#### 5.5.7 `[].SecretsFilter`: when `Type` is `KeyVault` and present, non-empty string

Message: `Invalid ConfigSources: KeyVault entry field 'SecretsFilter' must be a non-empty string when provided.`

**Comment:**

#### 5.5.8 `[].RunAsPreJob`: when `Type` is `KeyVault` and present, `true` or `false`

Message: `Invalid ConfigSources: KeyVault entry field 'RunAsPreJob' must be a boolean when provided.`

**Comment:**

## 6. Bugs in the current approach

### 6.1 Bug 1: False positives in type checks

A value is treated as an object or list if `convertToJson(value)` _contains_ `{` or `[`. The valid string `"a{b"` is therefore rejected. Confirmed by a compile probe.

**Comment:**

### 6.2 Bug 2: Field-present checks match too loosely

`contains(convertToJson(cfg), 'AzureServiceConnection')` (no quotes) is true when the name appears in a nested key or in any value. Confirmed by a compile probe. `contains(..., 'ConfigSources')` has the same problem.

**Comment:**

### 6.3 Bug 3: Empty values skip validation

Optional checks use `${{ if parameters.X.Field }}`, so `BackendConfig: {}` or `VariableFiles: []` is never validated. Existing tests rely on this ("Apply with Empty Backend Configuration").

**Comment:**

### 6.4 Bug 4: Duplication

`AzDOEnvironmentName`, `BackendConfig`, `EnvironmentVariableMappings` and `VariableFiles` checks are copy-pasted between files, with slightly different wording.

**Comment:**

## 7. Verified template capabilities

### 7.1 Confirmed by a compile probe against the preview-run API

- **Look up a field by a name held in a variable:** `parameters.Obj[f]` works where `f` is a loop variable.
- **Detect type:** `convertToJson(value)` returns typed JSON. Strings start with `"`, maps with `{` and lists with `[`; booleans are `true`/`false`; numbers are bare.
- **Missing vs empty:** a missing field gives `null`; an empty string gives `""`.
- **Loop over keys:** `${{ each kv in parameters.Obj }}` exposes `kv.key`, which allows unknown-field detection.

So `startsWith(convertToJson(value), '"')` and similar give exact type checks, fixing bugs 1–3.

**Comment:**

### 7.2 Not yet verified: recursion

Whether a template can include itself, directly or through another template. This is needed for nested rules (see §10.2).

**Comment:**

### 7.3 Scalar types: booleans (conflicting evidence)

The probe found that `convertToJson` gives bare `true`/`false` and bare numbers. However, a comment in `terraform_gated_deployment_config.yml` says that booleans written in YAML object literals reach the template as **strings** (`convertToJson` gives `"true"`, with quotes), while REST/JSON callers pass real booleans. The compile tests are REST/JSON callers, because they send PowerShell hashtables as JSON. Numbers are probably affected in the same way.

Until a probe settles this, the engine must accept both forms. `Type: boolean` accepts `true`, `false`, `"true"` and `"false"`. The probe must compile a **YAML file** that contains literal values, not only a REST payload, because the two paths behave differently.

**Comment:**

### 7.4 Scalar types: numbers

No documented expression tests whether a string converts to a number without failing compilation. `lt`/`gt` raise an error when conversion fails. `eq`/`ne`/`containsValue` treat a failed conversion as no match, so they cannot tell "not a number" from "a different number".

The sketch therefore accepts only **bare** numbers for `Type: number` and applies `Min`/`Max` only to them. If the probe shows that YAML numbers arrive as strings, `Type: number` must be redesigned before `VerificationTimeoutInMinutes` is migrated. There are two options:

- Keep today's unguarded `lt`/`gt`, which gives an unreadable error for non-numeric strings.
- Accept numeric strings without checking the range.

**Comment:**

### 7.5 Scalar types: rule literals

Rule literals such as `Required: false` or `DependsOn: { Present: false }` are also YAML, so they may arrive as strings. The Templates page on Microsoft Learn notes: "Non-empty strings are cast to true in a Boolean context." So the engine never tests a rule flag for truthiness; it normalises the flags first (see §9.2). The probe must cover rule literals as well as user values.

**Comment:**

### 7.6 Scalar types: integers

`Type: number` accepts decimals such as `1.5`. See open question §18.9.

**Comment:**

## 8. Design: engine and rules

### 8.1 Engine call

Each schema makes one call to the engine with its whole rule list, instead of hand-writing checks per field. Internally the engine includes one small per-rule template for each rule (see §9):

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

**Comment:**

### 8.2 Rule properties

#### 8.2.1 `Field`

Key in `Object` to validate.

**Comment:**

#### 8.2.2 `Type`

`string`, `number`, `boolean`, `list`, `map`, `object` or `any`.

**Comment:**

#### 8.2.3 `Required`

Field must be present.

**Comment:**

#### 8.2.4 `NonEmpty`

String, list or map must not be empty when present.

**Comment:**

#### 8.2.5 `Values`

Allowed values.

**Comment:**

#### 8.2.6 `Min` / `Max`

Numeric range (inclusive).

**Comment:**

#### 8.2.7 `ItemType`

Type of each list item.

**Comment:**

#### 8.2.8 `ItemRules`

Rules applied to each object in a list (for example `ConfigSources`).

**Comment:**

#### 8.2.9 `NonEmptyEntries`

Map keys and values must be non-empty.

**Comment:**

#### 8.2.10 `AllOrNone`

Sub-fields that must be set together.

**Comment:**

#### 8.2.11 `Forbidden`

Field must not be present; takes a custom message.

**Comment:**

#### 8.2.12 `DependsOn`

Condition on another field that decides whether this rule applies. See §8.6.

**Comment:**

#### 8.2.13 `Otherwise`

What happens when `DependsOn` is not met: `Ignore` (default) or `Forbidden`.

**Comment:**

#### 8.2.14 `Message`

Optional override for the standard error message.

**Comment:**

#### 8.2.15 `ForbiddenValues` (proposed, see §11.1)

Values the field must not have. Compared with `containsValue`, exactly as for `Values`: case-insensitive, with type conversion. List both `true` and `"true"` to be safe.

**Comment:**

#### 8.2.16 `Properties` (proposed)

Rules applied to the sub-fields of an `object` value (for example `KeyVaultConfig`).

**Comment:**

### 8.3 Engine parameters

`Object`, `Rules`, `ErrorPrefix`, `PathPrefix`, `AllowUnknownFields` and the proposed `ErrorSuffix` (text appended to every message, default `''`).

**Comment:**

### 8.4 The same field in more than one rule

The same `Field` may appear in more than one rule. This is needed when part of a field's validation always applies and part depends on another field (see §8.6.5).

**Comment:**

### 8.5 Error messages

All errors use a standard format:

```text
<ErrorPrefix>: '<Path>' <problem>.
```

For example: `'dev' environment error: 'VerificationMode' must be one of (VerifyOnDestroy, VerifyOnAny, VerifyDisabled).`

`<Path>` includes nested keys, for example `ConfigSources[].Name`. List indexes are **not** available: `${{ each }}` does not expose an index, so a list item is shown as `[]`. Where a list item has an identifying field (for example `Name`), the item rules can include it in a custom `Message`.

**Comment:**

### 8.6 Field dependencies (`DependsOn`)

Some fields only make sense, or are only required, depending on another field.

#### 8.6.1 Case: `VerificationMode` is required when `RunMode` is `PlanVerifyApply`

- Today: hand-written check in the gated schema.
- With `DependsOn`: `DependsOn: { Field: RunMode, Equals: PlanVerifyApply }`, `Required: true`.

**Comment:**

#### 8.6.2 Case: `ConfigSources` and `KeyVaultConfig` cannot both be set

- Today: hand-written check, with the loose-match bug.
- With `DependsOn`: on `ConfigSources`, `DependsOn: { Field: KeyVaultConfig, Present: false }`, `Otherwise: Forbidden`.

**Comment:**

#### 8.6.3 Case: `VerificationTimeoutInMinutes` / `VerificationTimeoutBehaviour` only matter for `PlanVerifyApply`

- Today: not enforced; silently ignored for other run modes.
- With `DependsOn`: `DependsOn: { Field: RunMode, Equals: PlanVerifyApply }`, with `Otherwise: Ignore` (today's behaviour) or `Forbidden` (stricter, breaking).

**Comment:**

#### 8.6.4 Shape and semantics

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

- **Condition met:** every check in the rule applies (`Required`, `Type`, `Values` and so on).
- **Condition not met, `Otherwise: Ignore`:** the rule is skipped entirely.
- **Condition not met, `Otherwise: Forbidden`:** the field must be absent. The error names the dependency, for example `'ConfigSources' cannot be used when 'KeyVaultConfig' is set.`
- `DependsOn.Field` refers to a field in the **same** `Object` (siblings only). There are no cross-object or parent references.

**Comment:**

#### 8.6.5 Splitting a field across rules

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

**Comment:**

#### 8.6.6 Single condition only

`DependsOn` is one condition, not a list combined with AND or OR. Template expressions cannot accumulate a result across a loop, so a generic "all of these conditions" would need a fixed, hand-unrolled maximum. No schema in the repository needs more than one condition today. If one does later, the options are a fixed second slot (`DependsOn2`, combined with AND) or a custom check outside the library.

**Comment:**

#### 8.6.7 What it replaces

`DependsOn` and `Otherwise` replace the earlier `When` and `ExclusiveWith` properties:

- `When` is `DependsOn` with `Otherwise: Ignore`.
- `ExclusiveWith: X` is `DependsOn: { Field: X, Present: false }` with `Otherwise: Forbidden`.

**Comment:**

## 9. Engine sketch

**Rough sketch, not yet compiled.** It shows how the rules are iterated and how each check is expressed. This version includes the corrections from the design review (see §17). Expressions marked _unverified_ need a compile probe before relying on them.

### 9.1 Two-file split

Template expressions cannot assign variables, so a single template would have to repeat `parameters.Object[rule.Field]`, `convertToJson(...)` and the whole `DependsOn` condition in every check. To avoid that, the engine is split into two files, and the values computed once per rule are passed as template **parameters**, which act as local variables:

- **`validate.jobs.yml`:** the entry point. It checks that `Object` is a map, then loops over the rules. For each rule it works out the value, its JSON form, presence, shape flags, normalised rule flags and the `DependsOn` result once, and includes `validate_rule.jobs.yml`. It also checks for unknown fields.
- **`validate_rule.jobs.yml`:** runs every check for one rule against the precomputed values. For `ItemRules` and `Properties`, it includes `validate.jobs.yml` again.

There are only two distinct files, but `validate_rule.jobs.yml` is **included once per rule**, plus once per item rule per list item. The 100-file limit counts distinct files, so this is fine. The real constraint is parse memory (see §9.11).

**Comment:**

### 9.2 Normalising flags and scalars

A YAML literal such as `Required: false` inside a rule may reach the template as the **string** `"false"`, which is truthy. Rule flags must therefore never be tested with a bare `${{ if rule.X }}`.

Instead, `validate.jobs.yml` normalises each flag once with `in(convertToJson(x), 'true', '"true"')`. This form gives the right answer whether `x` arrives as a boolean or a string, and gives `false` when `x` is absent (`null`). The normalised flags are passed to `validate_rule.jobs.yml` as `boolean` parameters, which are tested with `eq(parameters.X, true)`, not with bare truthiness. The same applies to user values (see §7.3).

**Comment:**

### 9.3 `validate.jobs.yml`

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

**Comment:**

### 9.4 `validate_rule.jobs.yml`: shape flags

Shape flags are derived from `Json` at the top of each check, so `convertToJson` is not repeated:

- **`IsString`:** `startsWith(parameters.Json, '"')`
- **`IsList`:** `startsWith(parameters.Json, '[')`
- **`IsMap`:** `startsWith(parameters.Json, '{')`
- **`IsBoolean`:** `in(parameters.Json, 'true', 'false', '"true"', '"false"')`
- **`IsNumber`:** `not(or(startsWith(parameters.Json, '"'), startsWith(parameters.Json, '['), startsWith(parameters.Json, '{'), in(parameters.Json, 'true', 'false', 'null')))` (bare numbers only; see §7.4)
- **`IsEmpty`:** `in(parameters.Json, '""', '[]', '{}')`

`length()` is not used anywhere, because it is documented only for strings and arrays. Emptiness is tested on the JSON form instead.

To keep the sketch short, the flags are written by name below (`IsString` and so on). In the real file they are either expanded inline or passed as extra parameters from `validate.jobs.yml`. The second option is preferred, because it keeps each check readable.

**Comment:**

### 9.5 `validate_rule.jobs.yml`: template

`"...:"` in the sketch stands for the full form `"${{ parameters.ErrorPrefix }}: ${{ coalesce(parameters.Rule.Message, <standard text>) }}${{ parameters.ErrorSuffix }}"`.

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

**Comment:**

### 9.6 Message override scope

- `Message` replaces only the `'<Path>' <problem>.` part. `ErrorPrefix` and `ErrorSuffix` are always added.
- `Message` applies to **every** check in its rule. So a rule with a `Message` should contain only one check; split the field across rules when it needs both a custom message and standard checks (see §8.6.5).

**Comment:**

### 9.7 `map` versus `object`

Both types require a JSON object, and the type check is the same. They differ in intent and in which properties apply:

- `map`: any keys, which are data (`BackendConfig`, `EnvironmentVariableMappings`). Use `NonEmptyEntries`. Unknown-field checking does not apply.
- `object`: a fixed set of known keys (`KeyVaultConfig`, `ConfigSources[]` items). Use `Properties`, `AllOrNone` and, through recursion, the unknown-field check.

**Comment:**

### 9.8 `DependsOn` edge cases

#### 9.8.1 "Exactly one of" is not enforced by the engine

The `or(...)` is true if any branch is true, so a rule with both `Present` and `Equals` silently gets OR semantics. The meta-schema test (see §14.2) rejects such rules instead.

**Comment:**

#### 9.8.2 `NotIn` with the other field absent

Counts as met, because `containsValue(list, null)` is false. This is intended: "`RunMode` is not `PlanOnly`" is true when `RunMode` is missing. Missing required fields are reported by their own rules.

**Comment:**

#### 9.8.3 `Equals` / `In` / `NotIn` compare case-insensitively

See §9.9.

**Comment:**

### 9.9 Case sensitivity

`eq`, `in` and `containsValue` compare strings case-insensitively, so `Values` and `DependsOn.Equals`/`In`/`NotIn` accept `planverifyapply` for `PlanVerifyApply`. Today's checks behave the same way, so nothing changes, but this should be documented. A `CaseSensitive` option is not proposed.

The unknown-field check also uses `containsValue`, so a key `runmode` is **not** reported as unknown. It is unverified whether `parameters.Object['RunMode']` then finds `runmode`. If key lookup is case-sensitive, the user gets a misleading "`RunMode` is required" error instead of "unknown field". Probe it. If lookup is case-sensitive, the unknown-field check needs a case-sensitive comparison, for example `eq(convertToJson(kv.key), convertToJson(<rule field>))` in a loop.

**Comment:**

### 9.10 Notes on the sketch

#### 9.10.1 Repeated errors

`AllOrNone` with two of three members set reports the missing member twice, once per member that is set. The gated deployment job also includes `jobs/terraform_deploy.yml` more than once, so the deploy schema already runs, and reports, more than once today. Whether Azure DevOps de-duplicates, orders or truncates multiple `Unexpected value` errors is undocumented. Probe a template that emits 10+ errors before any test asserts on a later error.

**Comment:**

#### 9.10.2 Unverified: `or` / `and` short-circuit evaluation

Whether short-circuiting means skipped arguments are never _evaluated_ (documented as "short-circuits", but evaluation is not stated). The `'__none__'` key makes this mostly harmless.

**Comment:**

#### 9.10.3 Unverified: `parameters.Rules.*.Field` projection

Used for the unknown-field check. Fallback: an explicit `KnownFields` list parameter.

**Comment:**

#### 9.10.4 Unverified: passing a missing field as `Value`

When passed to an `object` parameter, it may arrive as `null` or as the default `''`. `Present` and `Json` are computed in the caller, so this only affects error text.

**Comment:**

#### 9.10.5 Unverified: mutual recursion

`validate_rule.jobs.yml` including `validate.jobs.yml` for `ItemRules` and `Properties`. Do not build `Properties` until this passes.

**Comment:**

#### 9.10.6 Unverified: `boolean` parameter typing

Whether a full-value `${{ }}` passed to a `boolean` parameter keeps its type. The sketch avoids depending on it by always testing with `eq(parameters.X, true)`.

**Comment:**

#### 9.10.7 Unverified: `eq(<boolean>, 'false')`

Whether it converts the string to `False`. Not needed if flags are normalised as in §9.2.

**Comment:**

#### 9.10.8 Unverified: case sensitivity of `parameters.Object[<key>]`

See §9.9.

**Comment:**

#### 9.10.9 Unverified: folded scalar around a full-value expression

Whether a folded scalar (`>-`) around a full-value `${{ }}` is accepted.

**Comment:**

#### 9.10.10 Wrapping depth

Job → schema → (common) → `validate` → `validate_rule` (→ `validate` → `validate_rule` for nested rules) adds 3–5 template layers. That goes against the repository convention to avoid wrapping templates unless necessary (`docs/developers/explanation/double-wrapping.md`).

The justification: these layers are pure compile-time validation, emit no jobs or steps when the config is valid, and replace hundreds of lines of duplicated expressions. This must be stated in the code comments of the engine files.

**Comment:**

### 9.11 Template limits

From Microsoft Learn, "Use YAML templates in pipelines", section "Imposed limits on template updates" (Azure DevOps Services, page dated 2026-06-17):

- No more than 100 **separate** YAML files may be included, directly or indirectly. Repeated inclusions of the same file count once, so the engine's two files are cheap.
- No more than 100 levels of template nesting.
- No more than 20 MB of memory consumed while parsing the YAML (in practice, 600 KB – 2 MB of on-disk YAML).

Earlier versions of the same page, labelled "Azure DevOps Server 2022 – Azure DevOps Server 2019", give **20** levels of nesting and **10 MB** of parse memory. If Azure DevOps Server must be supported (see §18.8), budget against those figures.

Parse memory is the binding constraint, because every rule expands `validate_rule` again. The worst case must be measured on a **full public-job compile**: `jobs/terraform_gated_deployment.yml` → `jobs/terraform_deploy.yml` (included more than once) → schema → common → engine → items, with every rule and several `ConfigSources` items. Schema-only compiles understate the cost.

**Comment:**

## 10. Structure

### 10.1 Pipeline levels

A template can only be inserted at one level of a pipeline (`stages:`, `jobs:` or `steps:`). Today the schemas use `jobs:` and `config_sources.yml` uses `steps:`. Provide:

- `schemas/lib/validate.jobs.yml`
- `schemas/lib/validate.steps.yml`
- `schemas/lib/validate.stages.yml`, only if it is needed.

To avoid hand-maintaining identical logic three times, generate the variants from a single source with a script in `tools/`. A compile test fails if the generated files are out of date.

The generator must rewrite the top-level `jobs:` key **and** the relative `template: validate_rule.jobs.yml` / `template: validate.jobs.yml` references, so that the `steps` variant never includes a `jobs` file. A compile test must exercise `ItemRules` through the `steps` variant to catch this.

**Comment:**

### 10.2 Nested rules

`ConfigSources` items are objects with their own rules (`Type` decides which fields apply), and `KeyVaultConfig` is an object with its own sub-field rules (`Properties`). Preferred approach: `validate_rule.jobs.yml` includes `validate.jobs.yml` for each list item or sub-object (see §9.5).

Recursion is undocumented: no Microsoft source says whether A → B → A works, or whether cycles are rejected before expansion. If it works, each level counts against the nesting limit. **This must be prototyped first.**

Fallback if templates cannot include each other recursively: a third template, `validate_items.jobs.yml`, that supports exactly one level of `ItemRules` with no further nesting. That covers every schema in the repository today.

**Comment:**

### 10.3 Shared rule sets

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

**Comment:**

## 11. Gaps the rule model does not cover yet

Comparing the rule model with §5 shows several cases it cannot express yet. Each needs a decision before implementation.

### 11.1 Gap 1: `ApplyEvenIfNoChanges` can only be `true` with `PlanVerifyApply`

The condition depends on the field's own **value**, not just whether it is present. `DependsOn` with `Otherwise: Forbidden` would also forbid `false`. Options:

- (a) Add `ForbiddenValues: [true]` with `DependsOn: { Field: RunMode, In: [PlanOnly, ApplyOnly] }`, which is a small, general addition.
- (b) Keep a hand-written check after the engine call.

Proposed: (a).

**Comment:**

### 11.2 Gap 2: `config_sources.yml` validates a list, not an object

The engine's `Object` is a map. Wrap the list in a **block** mapping (a `${{ }}` inside a YAML flow mapping such as `{ ConfigSources: ${{ ... }} }` is invalid YAML, because `{`, `}` and `,` end a plain scalar in flow context):

```yaml
Object:
  ConfigSources: ${{ parameters.ConfigSources }}
```

Then add one rule, `{ Field: ConfigSources, Type: list, Required: true, NonEmpty: true, ItemType: object, ItemRules: [...] }`.

Its prefix is `Invalid ConfigSources`, which does not fit the `<ErrorPrefix>: '<Path>' <problem>.` format well. Use `ErrorPrefix: 'Invalid ConfigSources'`, and append the documentation link with the `ErrorSuffix` engine parameter, which is added to every message. This also adds the link to the empty-list message, which has none today. That is a minor wording change, and it is accepted.

**Comment:**

### 11.3 Gap 3: Rules for sub-fields of an object

For example, `KeyVaultConfig.ServiceConnection` must be a non-empty string. `ItemRules` only covers list items. Add `Properties: [<rules>]`, applied to the object value with `PathPrefix: '<Path>.'`, using the same recursion as `ItemRules`. Then `AllOrNone` only enforces "all or none", and `Properties` enforces each member's type and `NonEmpty`.

**Comment:**

### 11.4 Gap 4: `AllOrNone` and empty strings

Today a member set to `''` counts as "not set" (truthiness). The engine counts any present key as set. So `KeyVaultConfig: { Name: '' }` changes from "no error" to "`ServiceConnection` and `SecretsFilter` are required", and `Properties` also reports that `Name` must not be empty. This is stricter, and arguably correct, but it must be listed in the changelog.

**Comment:**

### 11.5 Gap 5: Unknown fields with two schemas per object

A gated job's config passes through the gated schema **and** the non-gated schema (see §3.5). Neither knows the other's fields.

Proposed: the unknown-field check runs only in the non-gated schemas (`terraform_deploy_config.yml`, `terraform_destroy_config.yml`), whose rule lists also name the gated-only fields as `{ Field: RunMode, Type: any }` and so on. Those rules are type-free, so the gated schema stays responsible for validating them. Gated schemas use `AllowUnknownFields: true`.

**Comment:**

### 11.6 Gap 6: The `KeyVaultConfig` vs `ConfigSources` message

It includes an upgrade-guide link. Keep it as a `Message` override on that rule.

**Comment:**

## 12. Target rule sets

The rules each schema should contain after migration. They assume the gaps in §11 are resolved as proposed. Messages that need a `Message` override are marked _(msg)_.

The new properties these rule sets use (`ForbiddenValues`, `Properties`, and the `ErrorSuffix` engine parameter) must be added to §8.2 and to the engine.

**Comment:**

### 12.1 `terraform_gated_destroy_config.yml` (`AllowUnknownFields: true`)

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

**Comment:**

### 12.2 `terraform_gated_deployment_config.yml` (`AllowUnknownFields: true`)

The same as gated destroy, with `RunMode` values `[PlanVerifyApply, PlanOnly, ApplyOnly]`, plus:

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

**Comment:**

### 12.3 `terraform_common_config.yml` (shared by deploy and destroy; `AllowUnknownFields: false`)

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

**Comment:**

### 12.4 `terraform_deploy_config.yml` (passed as `AdditionalRules`)

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

**Comment:**

### 12.5 `terraform_destroy_config.yml` (passed as `AdditionalRules`)

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

**Comment:**

### 12.6 `config_sources.yml`

Runs at the `steps:` level, with `ErrorPrefix: 'Invalid ConfigSources'` and `ErrorSuffix: ' See docs/definition_docs/shared/config_sources.md'`:

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

**Comment:**

## 13. Layout

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

**Comment:**

## 14. Testing

### 14.1 Engine compile tests

`schemas/lib/validate.CompileTests.ps1` contains a pass/fail grid per rule type and property, including the bug cases (`"a{b"` as a valid string, nested-key name collisions, empty map and empty list). It also covers:

- Values that are explicitly `null`, `''`, numeric strings (`"9"` against `Max: 43200`), decimals, and `"true"`/`"false"` strings.
- A non-map `Object`, and a non-object `ConfigSources[]` item (one clear error each, with no follow-on errors).
- Unknown keys at the top level, inside a `ConfigSources[]` item and inside `KeyVaultConfig`.
- Rules written with string flags (`Required: "false"`) to prove the flag normalisation works.

**Comment:**

### 14.2 Meta-schema test

Rule typos fail silently: `Type: strng` gets no type check, and `Requried: true` is ignored. The engine reports an unknown `Type` (see §9.5).

In addition, a compile test validates every schema's rule list **with the engine itself**: a rule set that describes rules (known rule keys only, `Type` from the allowed set, `Otherwise` from `Ignore`/`Forbidden`, and `DependsOn` with `Field` plus exactly one of `Present`/`Equals`/`In`/`NotIn`). "Exactly one of" cannot be expressed as a rule today, so the test checks it with a hand-written expression.

**Comment:**

### 14.3 YAML-literal variants

The compile tests send `Parameters` as REST/JSON `templateParameters`, but consumers write YAML literals, and the two may type scalars differently (see §7.3). Every regression case involving booleans or numbers needs a variant that embeds the config as YAML in the pipeline text, for example through `-TransformYamlFunction` or the run API's `yamlOverride`.

**Comment:**

### 14.4 Full public-job compile

Compile the worst case to measure parse memory (see §9.11).

**Comment:**

### 14.5 Regression suite

The existing `schemas/*.CompileTests.ps1` and `jobs/*.CompileTests.ps1` act as the regression suite during migration. Expected `ErrorMessage` values change to the standard format.

**Comment:**

### 14.6 Dependency on the test-framework literal-matching change

This work is best done **after** the test-framework literal-matching change, so that error-message assertions are exact. That change lives in a separate design, `designs/test-framework-improvements.md` (item #3), which is **not yet in the repository**.

In short: `tests/framework/Core.ParameterisedTestRunner.ps1` currently matches with `-like "*$ErrorMessage*"`. It should use a literal substring match (`.Contains()`), so that `[`, `]`, `*` and `?` in messages such as `'ConfigSources[].Name'` are matched literally.

Until then, those characters must be escaped in expected messages with `` ` `` (for example ``ConfigSources`[`].Name``). An unbalanced `[` in a `-like` pattern can throw an error instead of simply not matching. So land the `.Contains()` change, or escape the brackets, before migrating any message that contains `[]`.

**Comment:**

## 15. Versioning

`schemas/` is internal and has no SemVer guarantees. The items below still affect consumers.

### 15.1 Error message text is visible to consumers

Standardising it needs a `CHANGELOG.md` entry under `## [Unreleased]`.

**Comment:**

### 15.2 Rejecting unknown fields

This could break consumers who pass extra fields to the public `jobs/` templates. That would be a **breaking change** if made an error (see §18.2).

**Comment:**

### 15.3 Fixing bug 3 (empty values are now validated)

This could reject configurations that are accepted today, for example `BackendConfig: {}`. Decide per field whether empty is allowed (`NonEmpty`).

**Comment:**

### 15.4 Empty strings now fail type checks

Today `BackendConfig: ''` or `VariableFiles: ''` is skipped as falsy. The engine treats `''` as present and reports "must be an object of key/value pairs" or "must be a list". Needs a changelog entry.

**Comment:**

### 15.5 The `KeyVaultConfig` / `ConfigSources` exclusion fires more often

Today it fires only when a `KeyVaultConfig` member is truthy. The new rule fires whenever `KeyVaultConfig` is present, including `KeyVaultConfig: {}` or all-empty members. Needs a changelog entry.

**Comment:**

### 15.6 `AllOrNone` counts empty strings as set

See §11.4. Needs a changelog entry.

**Comment:**

### 15.7 Explicit `null`, `~` or an empty YAML value counts as absent

This is the same as today. It means `Forbidden` and `Otherwise: Forbidden` rules do not fire for `KeyVaultConfig: ~`. Needs a changelog entry.

**Comment:**

### 15.8 List item errors no longer print the item

`VariableFiles item '<json>' is not a string` becomes `'VariableFiles[]' items must be strings.`, because multi-line JSON cannot be flattened in a template expression. Needs a changelog entry.

**Comment:**

## 16. Migration plan

### 16.1 Step 1: Prototype

Probe the unverified expressions listed in §9.10, then build the `jobs:` engine with its compile tests.

**Comment:**

### 16.2 Step 2: Migrate the smallest schema

Migrate `terraform_gated_destroy_config.yml` and compare before and after.

**Comment:**

### 16.3 Step 3: Generator and `steps:` variant

Add the generator and the `steps:` variant; migrate `config_sources.yml`.

**Comment:**

### 16.4 Step 4: Common rules and remaining schemas

Extract `terraform_common_config.yml`; migrate the deploy, destroy and gated-deployment schemas.

**Comment:**

### 16.5 Step 5: Documentation and changelog

Update the docs in `docs/definition_docs/` that describe validation behaviour, and update `CHANGELOG.md`.

**Comment:**

## 17. Review outcomes

An independent review checked the design against Microsoft's documentation. The engine sketch in §9 already includes the corrections. This section records what changed and what was answered from the repository.

### 17.1 Corrected: `lt`/`gt` operand conversion

- Finding: `lt`/`gt` convert the right operand to the left operand's type, so `gt("9", 43200)` compares text.
- Change: the bound goes on the left (`gt(Min, Value)`), and only bare numbers are range-checked.

**Comment:**

### 17.2 Corrected: boolean check rejected `"true"`

- Finding: this contradicted the stated policy.
- Change: `IsBoolean` accepts `true`, `false`, `"true"`, `"false"`.

**Comment:**

### 17.3 Corrected: rule flags may arrive as strings

- Finding: `"false"` is truthy.
- Change: flags are normalised with `in(convertToJson(x), 'true', '"true"')`; booleans are tested with `eq(x, true)`.

**Comment:**

### 17.4 Corrected: `replace(..., '\n', ...)` does not work

- Finding: no backslash escapes exist.
- Change: item errors no longer print the item.

**Comment:**

### 17.5 Corrected: `length()` is documented only for strings and arrays

- Change: emptiness is tested on the JSON form (`""`, `[]`, `{}`).

**Comment:**

### 17.6 Corrected: `Values` produced a second error for maps and `''`

- Change: `Values` and `ForbiddenValues` only run for non-empty scalars.

**Comment:**

### 17.7 Corrected: `Object` was never checked to be a map

- Finding: recursion entered non-object items.
- Change: `validate.jobs.yml` checks `Object` first and skips its rules if it is not a map.

**Comment:**

### 17.8 Corrected: nested calls dropped `AllowUnknownFields` and `ErrorSuffix`

- Change: both are passed down; unknown fields are now checked in list items and sub-objects.

**Comment:**

### 17.9 Corrected: indexing with a null key is undocumented

- Change: `coalesce(rule.DependsOn.Field, '__none__')`.

**Comment:**

### 17.10 Corrected: `${{ }}` inside a YAML flow mapping is invalid YAML

- Change: block mapping for the `ConfigSources` wrapper.

**Comment:**

### 17.11 Corrected: `each` was used to insert `AdditionalRules`

- Change: plain array insertion, which flattens.

**Comment:**

### 17.12 Corrected: template limits were wrong (20 levels)

- Change: now 100 files / 100 levels / 20 MB for Services, and 20 levels / 10 MB for older Server versions.

**Comment:**

### 17.13 Corrected: "One engine call" contradicted "one include per rule"

- Change: wording fixed.

**Comment:**

### 17.14 Corrected: `Message` scope and `map`/`object` difference were undefined

- Change: both defined in the sketch section (§9.6, §9.7).

**Comment:**

### 17.15 Corrected: typos in rules fail silently

- Change: an unknown `Type` is reported, and a meta-schema test is added.

**Comment:**

### 17.16 Answered: do the gated jobs pass the config object through unchanged?

Yes. `jobs/terraform_gated_deployment.yml` and `jobs/terraform_gated_destroy.yml` pass `${{ parameters.TerraformDeploymentConfig }}` / `${{ parameters.TerraformDestroyConfig }}` unchanged to their schema and to each inclusion of `jobs/terraform_deploy.yml` / `jobs/terraform_destroy.yml`. Each gated job includes the non-gated job **more than once**, so the non-gated schema runs more than once per compile.

**Comment:**

### 17.17 Answered: do the job templates read fields that no rule names?

Yes: `JobsVariableMappings`. Both `jobs/terraform_deploy.yml` and `jobs/terraform_destroy.yml` read it. It is a list whose entries are inserted as job variables: `template` entries become `template: <x>@self`, and entries with `name` or `group` are inserted as they are. It is not validated today, and has been added to the common rule set.

Fields read by each job (from a scan of `parameters.<Config>.<Field>`):

- `terraform_deploy.yml`: `AzDOEnvironmentName`, `AzureServiceConnection`, `BackendConfig`, `ConfigSources`, `EnvironmentVariableMappings`, `JobsVariableMappings`, `KeyVaultConfig`, `OutputVariables`, `VariableFiles`, `VerificationMode`.
- `terraform_destroy.yml`: `AzDOEnvironmentName`, `AzureServiceConnection`, `BackendConfig`, `ConfigSources`, `EnvironmentVariableMappings`, `JobsVariableMappings`, `VariableFiles`.
- `terraform_gated_deployment.yml`: `ApplyEvenIfNoChanges`, `RunMode`, `VerificationTimeoutBehaviour`, `VerificationTimeoutInMinutes`.
- `terraform_gated_destroy.yml`: `RunMode`, `VerificationTimeoutBehaviour`, `VerificationTimeoutInMinutes`.

Before `AllowUnknownFields: false` is enabled, re-run this scan and check the documented fields in `docs/definition_docs/terraform_pipeline/terraform_job_config.md`. Then add a compile test that passes a config containing **every** documented field.

**Comment:**

### 17.18 Answered: can a missing config produce the schema's own message?

No. The config parameters of the `jobs/` templates and the schemas have no default, so Azure DevOps reports its own `A value for the '<Name>' parameter must be provided.` before any schema runs. The existing tests already expect that text, and nothing changes.

**Comment:**

## 18. Open questions

### 18.1 Error messages

Adopt the standard format (needs a changelog entry), or keep today's exact wording via a `Message` override on every rule?

**Comment:**

### 18.2 Unknown fields

Error (catches typos, but potentially breaking for the public `jobs/`), warning, or off by default with opt-in per schema?

**Comment:**

### 18.3 Location

`schemas/lib/` as proposed, or elsewhere?

**Comment:**

### 18.4 Order of work

After the test-framework plan (at least #3), or prototype now?

**Comment:**

### 18.5 Run-mode-only fields

Should `VerificationTimeoutInMinutes` and `VerificationTimeoutBehaviour` use `Otherwise: Ignore` (today's behaviour) or `Otherwise: Forbidden` (catches misconfiguration, but breaking)?

**Comment:**

### 18.6 Multiple conditions

Is a single `DependsOn` enough, or should a fixed second slot be designed in from the start?

**Comment:**

### 18.7 Empty values (bug 3)

Should an empty `BackendConfig`, `EnvironmentVariableMappings` or `VariableFiles` stay valid (today's behaviour, relied on by "Apply with Empty Backend Configuration"), or be rejected with `NonEmpty`? Proposed default: keep empty values valid and validate only the entries. This is not a breaking change.

**Comment:**

### 18.8 Platform

Azure DevOps Services only, or Azure DevOps Server too? Older Server versions document a nesting limit of 20 and a 10 MB parse limit, which changes the size budget.

**Comment:**

### 18.9 Integers

Should `Type: number` reject decimals (`VerificationTimeoutInMinutes: 1.5`)? If so, add `Integer: true`, implemented as "the JSON form contains no `.`, `e` or `E`".

**Comment:**

### 18.10 Nested unknown fields

Should unknown keys inside `ConfigSources[]` items and `KeyVaultConfig` be rejected? The sketch inherits the parent's setting. That is potentially breaking in the same way as at the top level.

**Comment:**

### 18.11 `KeyVaultConfig: {}` with `ConfigSources`

Should this be an error now? With `DependsOn: { Present: false }` it is. To keep today's behaviour, the condition would need "`KeyVaultConfig` is present and not empty", which `DependsOn` cannot express.

**Comment:**

### 18.12 Numbers as strings

If YAML numbers arrive as strings, which option from §7.4 is preferred?

**Comment:**
