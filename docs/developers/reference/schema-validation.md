# Schema Validation

Schema templates in `schemas/` validate complex object parameters **at compile time** — before any agent is allocated or any resource is touched. They are how this repository enforces structure on the rich object parameters (like `TerraformDeploymentConfig` or `ConfigSources`) that Azure DevOps itself cannot type-check beyond the top-level `type: object`.

This page explains what schema templates are, how the validation mechanism works, and the full catalogue of patterns for authoring one. For *why* compile-time validation is a core design choice, see [Design Philosophy → Fail Fast at Compile Time](../explanation/design-philosophy.md#fail-fast-at-compile-time).

## Why Schemas Exist

Azure DevOps parameters support primitive types (`string`, `number`, `boolean`) and `object`, but an `object` is opaque — the platform will not check that it has the right fields, that a field is one of an allowed set, or that a nested list contains only strings. A consumer can pass a malformed object and the error would otherwise surface deep into a running pipeline, after an agent has started and possibly after cloud resources have been touched.

A schema template closes that gap. It inspects the object during YAML compilation and **fails the compile** with a descriptive message the moment the object is wrong. Failures become cheap, fast, and unambiguous: the consumer sees exactly which field is wrong and where to read about it, before anything runs.

## How the Mechanism Works

Azure DevOps has no "assert" or "fail compilation" keyword. Schema templates exploit a quirk of the expansion engine: **a mapping whose value is the string `"Error"` is not a valid pipeline construct, so emitting one aborts compilation** and prints the mapping's key as the error message.

By placing that mapping inside a compile-time `${{ if <condition> }}` block, the error is only emitted when the condition is true:

```yaml
steps:
  - ${{ if <bad-input-condition> }}:
      - "Descriptive message explaining what is wrong. See: docs/definition_docs/path.md": "Error"
```

- The **key** is the human-readable error message shown to the consumer.
- The **value** is always the literal string `"Error"`.
- The guard is a **compile-time** expression (`${{ }}`), so it is evaluated during expansion, not at runtime.

When the condition is false, nothing is emitted and compilation continues. When true, the pipeline fails to compile and the key text is surfaced.

### Context: `steps:` vs `jobs:`

A schema is a template included by another template, so its validation block must live under the same section the including template expects. Schemas included at job level emit under `jobs:` (see `schemas/terraform_deploy_config.yml`); schemas included at step level emit under `steps:` (see `schemas/config_sources.yml`). The guard/`"Error"` mechanism is identical in both — only the surrounding section keyword differs.

## Anatomy of a Schema Template

Every schema template has three parts:

1. **A brief comment block** naming the schema, its purpose, and a `See:` link to the definition doc (see [Template Conventions → Schema Template Documentation](template-conventions.md#schema-template-documentation)).
2. **A `parameters:` block** declaring the object(s) to validate (and any context values, such as an `EnvironmentName` used to make error messages specific). Required parameters omit a default and carry a `# NO default` comment.
3. **A validation block** (`steps:` or `jobs:`) containing the guard expressions.

```yaml
# Schema Template: Example Config
# Validates the ExampleConfig object passed to jobs/example.yml.
# See: docs/definition_docs/path/to/example_config.md

parameters:
  - name: ExampleConfig
    type: object
    # NO default - Consumer must provide this
    displayName: 'Example configuration object (required)'

steps:
  - ${{ if or(not(parameters.ExampleConfig.Name), eq(parameters.ExampleConfig.Name, '')) }}:
      - "Invalid ExampleConfig: 'Name' is required. See: docs/definition_docs/path/to/example_config.md": "Error"
```

## Pattern Catalogue

These are the building blocks. Compose them to validate any object shape. Real examples live in `schemas/config_sources.yml` and `schemas/terraform_deploy_config.yml`.

### Required field

A field is missing if it is falsy or an empty string:

```yaml
- ${{ if or(not(parameters.Config.Name), eq(parameters.Config.Name, '')) }}:
    - "Invalid Config: 'Name' is required. See: docs/definition_docs/path.md": "Error"
```

### Allowed values (enum)

Reject anything outside the permitted set with `notIn`:

```yaml
- ${{ if notIn(parameters.Config.Type, 'KeyVault') }}:
    - "Invalid Config: 'Type' must be 'KeyVault'. See: docs/definition_docs/path.md": "Error"
```

### Type check (scalar vs. object/array)

There is no `typeof`. Serialise the value with `convertToJson` and check for structural characters: a JSON object starts with `{`, a JSON array with `[`. If either appears where a string is expected, the value is not a scalar:

```yaml
- ${{ if or(contains(convertToJson(parameters.Config.Name), '{'), contains(convertToJson(parameters.Config.Name), '[')) }}:
    - "Invalid Config: 'Name' must be a string. See: docs/definition_docs/path.md": "Error"
```

### Optional field: validate only when present

Gate the check on the field's presence first, by looking for the quoted field name in the object's JSON:

```yaml
- ${{ if contains(convertToJson(parameters.Config), '"VerificationMode"') }}:
    - ${{ if notIn(parameters.Config.VerificationMode, 'VerifyOnDestroy', 'VerifyOnAny', 'VerifyDisabled') }}:
        - "Invalid Config: if provided, 'VerificationMode' must be one of VerifyOnDestroy, VerifyOnAny, VerifyDisabled. See: docs/definition_docs/path.md": "Error"
```

### Non-empty list

Reject an empty required list explicitly rather than letting it slip through:

```yaml
- ${{ if eq(length(parameters.Config.Sources), 0) }}:
    - "Invalid Config: 'Sources' cannot be empty. Omit the parameter entirely if none are needed. See: docs/definition_docs/path.md": "Error"
```

### List of strings

Confirm the value is a list, then check each item is a scalar:

```yaml
- ${{ if parameters.Config.VariableFiles }}:
    - ${{ if not(contains(convertToJson(parameters.Config.VariableFiles), '[')) }}:
        - "Invalid Config: 'VariableFiles' must be a list. See: docs/definition_docs/path.md": "Error"
    - ${{ else }}:
        - ${{ each variable in parameters.Config.VariableFiles }}:
            - ${{ if or(contains(convertToJson(variable), '['), contains(convertToJson(variable), '{')) }}:
                - "Invalid Config: 'VariableFiles' items must be strings. See: docs/definition_docs/path.md": "Error"
```

### Object of key/value pairs (a map)

Confirm it is an object, then iterate entries asserting both key and value are present:

```yaml
- ${{ if parameters.Config.BackendConfig }}:
    - ${{ if not(contains(convertToJson(parameters.Config.BackendConfig), '{')) }}:
        - "Invalid Config: 'BackendConfig' must be an object of key/value pairs. See: docs/definition_docs/path.md": "Error"
    - ${{ else }}:
        - ${{ each mapping in parameters.Config.BackendConfig }}:
            - ${{ if or(not(mapping.Key), not(mapping.Value), eq(mapping.Key, ''), eq(mapping.Value, '')) }}:
                - "Invalid Config: 'BackendConfig' entries must have a non-empty key and value. See: docs/definition_docs/path.md": "Error"
```

### Iterating a list of objects

Apply per-entry checks inside an `each`:

```yaml
- ${{ each source in parameters.Config.Sources }}:
    - ${{ if or(not(source.ServiceConnection), eq(source.ServiceConnection, '')) }}:
        - "Invalid Config: each Sources entry requires 'ServiceConnection'. See: docs/definition_docs/path.md": "Error"
```

### Mutual exclusivity

Fail when two incompatible options are both supplied:

```yaml
- ${{ if and(contains(convertToJson(parameters.Config), 'ConfigSources'), parameters.Config.KeyVaultConfig.Name) }}:
    - "Invalid Config: use either KeyVaultConfig (legacy) or ConfigSources (new), not both. See: docs/user-docs/upgrades/...md": "Error"
```

### All-or-nothing group

When any member of a group is set, require all of them:

```yaml
- ${{ if or(parameters.Config.KeyVaultConfig.ServiceConnection, parameters.Config.KeyVaultConfig.Name) }}:
    - ${{ if or(not(parameters.Config.KeyVaultConfig.ServiceConnection), eq(parameters.Config.KeyVaultConfig.ServiceConnection, '')) }}:
        - "Invalid Config: KeyVaultConfig.ServiceConnection is required when any Key Vault field is set. See: docs/definition_docs/path.md": "Error"
    - ${{ if or(not(parameters.Config.KeyVaultConfig.Name), eq(parameters.Config.KeyVaultConfig.Name, '')) }}:
        - "Invalid Config: KeyVaultConfig.Name is required when any Key Vault field is set. See: docs/definition_docs/path.md": "Error"
```

## Error Message Conventions

- Start with a short label identifying the object (e.g. `Invalid ConfigSources:` or `'production' environment error:`), so the consumer knows which input is wrong.
- State the field and the exact rule that failed.
- End with a `See:` link to the object's `docs/definition_docs/` page (or an upgrade guide where relevant).
- Interpolate context where it helps (e.g. the `EnvironmentName` or the offending value) using `${{ }}`.

## Where Schemas Are Used

A schema is not run on its own — the consuming job or stage includes it as a template so its checks run during that template's compilation. For example, `jobs/terraform_deploy.yml` includes `schemas/terraform_deploy_config.yml`, passing the object through. Adding a schema include to a job is what makes its validation take effect.

## Documentation and Testing

- **Definition doc**: every validated object has a corresponding page under `docs/definition_docs/` describing its fields, required/optional status, and allowed values. Keep the schema and its definition doc in sync — a new rule in one needs the matching change in the other.
- **Tests**: assert that bad input is rejected using `InvalidTestCases` with an `ErrorMessage` in a `*.CompileTests.ps1`, and that valid input compiles using `ValidTestCases`. See [Test a Template → Writing a Test](../how-to/test-a-template.md#writing-a-test).

## See Also

- [Design Philosophy → Fail Fast at Compile Time](../explanation/design-philosophy.md#fail-fast-at-compile-time)
- [Template Conventions → Schema Template Documentation](template-conventions.md#schema-template-documentation)
- [Test a Template](../how-to/test-a-template.md)
- Worked examples: `schemas/config_sources.yml`, `schemas/terraform_deploy_config.yml`
