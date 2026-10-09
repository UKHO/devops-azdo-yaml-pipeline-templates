---
description: 'Azure DevOps Pipeline YAML best practices for devops-azdo-yaml-pipeline-templates repository'
applyTo: '**/*.{yml,yaml}'
---

# Azure DevOps Pipeline YAML Best Practices

This guide applies to all YAML files in the `devops-azdo-yaml-pipeline-templates` repository.

## Formatting Standards (MUST FOLLOW)

**File extension is always `.yml`, never `.yaml`.** This matches Azure DevOps's own default
(`azure-pipelines.yml`) and every existing template in this repository. Reject any new file
ending in `.yaml`.

**Always adhere to `.editorconfig` rules:**
- **Line Endings:** LF (Unix-style, not CRLF)
- **Indentation:** 2 spaces (never tabs)
- **Final Newline:** Required at end of file
- **Trailing Whitespace:** Must be trimmed

**Common Issues to Avoid:**
- ❌ CRLF line endings
- ❌ Tab characters
- ❌ Trailing whitespace
- ❌ Missing final newline

## Template Documentation Strategy

Documentation location depends on template type — see [Architecture](../../ARCHITECTURE.md#documentation-location-by-folder)
for the full rule. The exact required format for each type follows.

### Tasks and Utils (`tasks/`, `utils/`) - Comprehensive In-File Documentation Required

All task and utility templates **MUST** include a documentation block at the top:

```yaml
# Azure DevOps Task: [TaskName]@[Version]
#
# Purpose:
#   Clear, concise description of what this template does — typically two lines.
#
# Parameters:
#   - ParamName (type, required): Description.
#   - ParamName2 (type, optional): Description. Default: value
#   - ParamName3 (type, optional): Description. Values: a, b. Default: 'a'
#
# Example Usage:
#   - template: tasks/example.yml
#     parameters:
#       ParamName: 'value'
#
# Notes:
#   - Important considerations
#   - See: [link to Microsoft task reference documentation]

parameters:
  # ...parameters...

steps:
  # ...implementation...
```

**Required Elements:** see [Template Conventions](../../docs/developers/reference/template-conventions.md#task-template-file-documentation)
for the full rules (enum `Values:` notation, required vs. optional `Default:`, conditionally-required notes, example labelling, `See:` links).

### Pipelines, Jobs, and Stages (`pipelines/`, `jobs/`, `stages/`) - External Documentation

These templates should **NOT** have comprehensive in-file documentation blocks — use self-documenting
parameter names and `displayName`, and document comprehensively in `docs/` instead.

### Schemas (`schemas/`) - Brief Comments Only

Brief in-file comment block only — see [Template Conventions](../../docs/developers/reference/template-conventions.md#schema-template-documentation). Format:

```yaml
# Schema Template: Name
# Brief description of purpose
# See: docs/path/to/details.md

parameters:
  # ...parameters...
```

Schema templates validate complex object parameters at **compile time** by emitting a one-key mapping whose value is `"Error"` under a `${{ if ... }}` guard — when the condition is true, compilation fails and the key is printed as the message. Author new schemas with this pattern (required-field, type, and allowed-value checks), ending each message with a `See:` link. See [Schema Validation](../../docs/developers/reference/schema-validation.md) for the full mechanism and pattern catalogue.

```yaml
steps:
  - ${{ if or(not(parameters.Config.Name), eq(parameters.Config.Name, '')) }}:
      - "Invalid Config: field 'Name' is required. See docs/definition_docs/path/to/details.md": "Error"
  - ${{ if notIn(parameters.Config.Type, 'KeyVault') }}:
      - "Invalid Config: field 'Type' must be 'KeyVault'. See docs/definition_docs/path/to/details.md": "Error"
```

## Cross-Platform and Open-Source Tasks (MUST FOLLOW)

**Templates must run on both Windows and Linux agents.** Do not assume an OS or shell:

- Use `pwsh` (PowerShell Core) for scripting steps, not `powershell` (Windows-only) or `bash` (Unix-only).
- Avoid hardcoded path separators and OS-specific shell built-ins; use cross-platform constructs.
- Do not assume a specific agent image — consumers choose their pool.

**Prefer built-in or open-source tasks over paid Marketplace extensions.** Where a built-in Azure DevOps task, a `script`/`pwsh` step, or an open-source equivalent can do the job, use it. Do not introduce tasks that require a consumer organisation to install a licensed/paid Marketplace extension. For example, this repository invokes the Terraform CLI through a `cmdline`/`script` step rather than a Marketplace Terraform task, so no extension install is required. See [Design Philosophy](../../docs/developers/explanation/design-philosophy.md#cross-platform-and-open-source-by-default).

## Template Structure and Design

### Parameter Best Practices

```yaml
parameters:
  - name: ParameterName
    type: string  # string, number, boolean, object, stepList, jobList, etc.
    default: 'sensible-default'  # Optional, omit if parameter is required
    values:  # Optional, for enumeration
      - option1
      - option2
    displayName: 'User-friendly description shown in UI'

  - name: RequiredParameter
    type: string
    # NO default - Consumer must provide this
    displayName: 'Required parameter description (required)'

  - name: RequiredEnum
    type: string
    # NO default - Consumer must provide this
    values:
      - optionA
      - optionB
    displayName: 'Enum parameter without default (required)'

  - name: ConditionalParam
    type: string
    default: ''
    displayName: 'Only needed when Flag is true (required when Flag is set)'
```

**Guidelines:** see [Template Conventions](../../docs/developers/reference/template-conventions.md#parameters)
for the full parameter naming, ordering, and required/optional conventions.

### Variable Best Practices

```yaml
variables:
  - name: VariableName
    value: ${{ parameters.ParameterName }}  # Compile-time expression

  - name: RuntimeVariable
    value: $(Build.BuildId)  # Runtime expression

  - name: InternalOnly
    value: $(Build.SourcesDirectory)/${{ parameters.RelativePath }}
    readonly: true  # Prevents consumer pipelines from overriding this variable

  # Variable from external template
  - template: ../utils/variable-template.yml
    parameters:
      SomeParam: 'value'
```

**Guidelines:** see [Template Conventions](../../docs/developers/reference/template-conventions.md#protecting-template-internal-variables)
for variable scoping and the `readonly: true` rule. In short: use compile-time expressions
(`${{ }}`) for parameters/conditions, runtime expressions (`$()`) for built-in variables, and
mark any template-internal variable `readonly: true`.

### Conditional Logic

```yaml
# Compile-time conditions (evaluated before pipeline runs)
- ${{ if eq(parameters.DeployMode, 'Production') }}:
    - script: echo "Production deployment"

# Runtime conditions (evaluated during pipeline execution)
- script: echo "Conditional step"
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
```

**When to use each:** see [YAML Standards](../../docs/developers/reference/yaml-standards.md#key-patterns)
for the full compile-time vs. runtime distinction.

## Anti-Patterns (AVOID THESE)

### ❌ Double-Wrapping Templates

**Don't create wrapper layers for simple parameter passing:**

```yaml
# ❌ BAD - Unnecessary wrapper
# terraform_apply.yml
steps:
  - template: terraform_base.yml
    parameters:
      Command: 'apply'
```

**Instead, use a single comprehensive template** that selects behaviour at compile time, driven by built-in/`script` steps rather than a paid Marketplace task:

```yaml
# ✅ GOOD - Single template with all logic, no paid extension required
# terraform.yml
parameters:
  - name: Command
    type: string
    values: [init, plan, apply, destroy]

steps:
  - ${{ if eq(parameters.Command, 'init') }}:
      # ...init-specific logic...
  - ${{ else }}:
      - script: terraform ${{ parameters.Command }}
        displayName: 'Terraform ${{ parameters.Command }}'
```

**Exceptions where wrapping is acceptable:** orchestration across pipeline→stage→job→task
levels, combining unrelated templates into one workflow, or enforcing extra validation. See
[Double Wrapping](../../docs/developers/explanation/double-wrapping.md) for the full rationale
and exception list — do not add new exceptions here without updating that file too.

### ❌ Hardcoding Sensitive Values

```yaml
# ❌ BAD
variables:
  ApiKey: 'sk-1234567890abcdef'  # Never do this!

# ✅ GOOD - Use Azure Key Vault
- task: AzureKeyVault@2
  inputs:
    azureSubscription: 'ServiceConnection'
    KeyVaultName: 'my-keyvault'
    SecretsFilter: 'ApiKey'
```

### ❌ Mixing Build and Deploy in Same Stage

```yaml
# ❌ BAD - Build and deploy mixed
stages:
  - stage: BuildAndDeploy  # Don't mix concerns
    jobs:
      - job: Build
      - job: Deploy

# ✅ GOOD - Separate stages
stages:
  - stage: Build
    jobs:
      - job: Build
  - stage: Deploy
    dependsOn: Build
    jobs:
      - deployment: Deploy
```

### ❌ Overly Broad Triggers

```yaml
# ❌ BAD - Triggers on any file change
trigger:
  branches:
    include:
      - '*'

# ✅ GOOD - Specific paths and branches
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - src/**
      - pipelines/**
    exclude:
      - docs/**
      - '*.md'
```

## Breaking Changes and Versioning

See [Versioning Policy](../../docs/developers/reference/versioning-policy.md) for the full
SemVer rules and worked breaking/non-breaking examples. In short: a breaking change to a
`pipelines/`/`jobs/` template requires a major version bump, a `CHANGELOG.md` entry (see
[Update the Changelog](../../docs/developers/how-to/update-the-changelog.md)), migration
steps, and inline comments in the affected template files.

## Security Best Practices

See [Template Conventions](../../docs/developers/reference/template-conventions.md#security)
for the full policy (Key Vault, variable groups, managed identities, least privilege). Exact
syntax for the common cases:

### Secrets Management

```yaml
# ✅ Use Azure Key Vault
- template: tasks/azure_key_vault.yml
  parameters:
    KeyVaultServiceConnection: 'MyServiceConnection'
    KeyVaultName: 'my-vault'
    SecretsFilter: 'Secret1,Secret2'

# ✅ Use variable groups
variables:
  - group: 'ProductionSecrets'

# ✅ Mark secrets in variable declarations
variables:
  - name: Password
    value: $(SecretPassword)  # Retrieved from Key Vault or variable group
```

### Service Connections

See [Template Conventions](../../docs/developers/reference/template-conventions.md#security) —
managed identities, least privilege, environment-specific connections, approval gates.

### Secret Scanning

```yaml
# Ensure secrets are not logged
- script: |
    echo "##vso[task.setvariable variable=MySecret;isSecret=true]$(SecretValue)"
  displayName: 'Set secret variable (not logged)'
```

## Performance Optimization

See [Template Conventions](../../docs/developers/reference/template-conventions.md#performance-patterns)
for the full policy. Exact syntax:

### Caching Dependencies

```yaml
# Cache npm packages
- task: Cache@2
  inputs:
    key: 'npm | "$(Agent.OS)" | package-lock.json'
    path: $(npm_config_cache)
    restoreKeys: |
      npm | "$(Agent.OS)"

# Cache NuGet packages
- task: Cache@2
  inputs:
    key: 'nuget | "$(Agent.OS)" | **/*.csproj'
    path: $(NUGET_PACKAGES)
```

### Parallel Execution

```yaml
# Use matrix strategy for parallel jobs
strategy:
  matrix:
    linux:
      imageName: 'ubuntu-latest'
    windows:
      imageName: 'windows-latest'
    mac:
      imageName: 'macOS-latest'
```

### Shallow Clone

```yaml
# Only for builds that don't need full git history
steps:
  - checkout: self
    fetchDepth: 1  # Shallow clone
```

## Error Handling and Cleanup

See [Template Conventions](../../docs/developers/reference/template-conventions.md#error-handling)
for the full policy. Exact syntax:

### Proper Conditions

```yaml
# Continue on error
- script: echo "This might fail"
  continueOnError: true

# Run cleanup even if previous steps failed
- script: echo "Cleanup"
  condition: always()

# Run only on success
- script: echo "Success"
  condition: succeeded()

# Run only on failure
- script: echo "Failure notification"
  condition: failed()
```

### Retry Logic

```yaml
# Retry on task failure
- task: SomeTask@1
  retryCountOnTaskFailure: 3
```

## Naming Conventions

### Be Descriptive and Consistent

```yaml
# ✅ GOOD - Clear, descriptive names
stages:
  - stage: Build
    displayName: 'Build Application'

  - stage: DeployDev
    displayName: 'Deploy to Development'

jobs:
  - job: UnitTests
    displayName: 'Run Unit Tests'

  - deployment: DeployWebApp
    displayName: 'Deploy Web Application'
    environment: 'Production'

# ❌ BAD - Vague or unclear
stages:
  - stage: Stage1
  - stage: DoStuff
```

### Parameter Naming

See [Template Conventions](../../docs/developers/reference/template-conventions.md#parameters) —
PascalCase, full words over abbreviations, verb-prefixed booleans.

### Filename Naming (`tasks/`, `utils/`)

See [YAML Standards](../../docs/developers/reference/yaml-standards.md#formatting--naming) —
snake_case, `.yml` never `.yaml`.

## Testing a New or Changed Template

Validate template changes by compiling them before opening a Pull Request. Add a `*_test.yml` fixture under `tests/<area>/<template-name>/` (referencing the template as a consumer would, pinning the repo resource `ref` to `${{ variables['Build.SourceBranch'] }}`), and for `tasks/`/`utils/` optionally a `*.CompileTests.ps1` using `Run-Tests` with `ValidTestCases`/`InvalidTestCases`. Link new fixtures from the user doc's `**Live example**` entries. See [Test a Template](../../docs/developers/how-to/test-a-template.md#writing-a-test) for the full pattern and run commands.

## Template Reusability Checklist

When creating a new template:

- [ ] Follows correct documentation strategy (in-file for tasks/utils, external for pipelines/jobs/stages)
- [ ] All parameters have types and displayName
- [ ] Defaults are sensible and documented
- [ ] No hardcoded values (use parameters or variables)
- [ ] Template-internal variables are marked `readonly: true`
- [ ] No double-wrapping or unnecessary abstraction
- [ ] Error handling implemented where needed
- [ ] Follows `.editorconfig` formatting rules
- [ ] Security best practices followed
- [ ] Tested with realistic scenarios
- [ ] Added a compile test fixture under `tests/` (and linked it from the user doc's Live example)
- [ ] Added example usage (in-file or in docs)

## Additional Resources

- **Repository Guidelines:** `.github/copilot-instructions.md`
- **Architecture:** `ARCHITECTURE.md`
- **Anti-patterns:** `docs/developers/explanation/double-wrapping.md`
- **Template Conventions:** `docs/developers/reference/template-conventions.md`
- **Schema Validation:** `docs/developers/reference/schema-validation.md`
- **YAML Standards:** `docs/developers/reference/yaml-standards.md`
- **Versioning Guide:** `docs/developers/reference/versioning-policy.md`
- **User Documentation:** `docs/user-docs/README.md`
- **EditorConfig Spec:** https://editorconfig.org/
- **Azure DevOps YAML Schema:** https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema

