---
description: 'Azure DevOps Pipeline YAML best practices for devops-azdo-yaml-pipeline-templates repository'
applyTo: '**.yml'
---

# Azure DevOps Pipeline YAML Best Practices

This guide applies to all YAML files in the `devops-azdo-yaml-pipeline-templates` repository.

## Formatting Standards (MUST FOLLOW)

**Always adhere to `.editorconfig` rules:**
- **Encoding:** UTF-8 **without BOM** (Byte Order Mark)
- **Line Endings:** LF (Unix-style, not CRLF)
- **Indentation:** 2 spaces (never tabs)
- **Final Newline:** Required at end of file
- **Trailing Whitespace:** Must be trimmed

**Common Issues to Avoid:**
- ❌ UTF-8 with BOM (shows as `﻿` at start of file)
- ❌ CRLF line endings
- ❌ Tab characters
- ❌ Trailing whitespace
- ❌ Missing final newline

## Template Documentation Strategy

### Tasks and Utils (`tasks/`, `utils/`) - Comprehensive In-File Documentation Required

All task and utility templates **MUST** include a documentation block at the top:

```yaml
# Azure DevOps Task: [TaskName]@[Version]
#
# Purpose:
#   Clear, concise description of what this template does.
#
# Parameters:
#   - ParamName (type, required): Description. Default: value
#   - ParamName2 (type, optional): Description
#
# Example Usage:
#   - template: tasks/example.yml
#     parameters:
#       ParamName: 'value'
#
# Notes:
#   - Important considerations
#   - Limitations or gotchas

parameters:
  # ...parameters...

steps:
  # ...implementation...
```

**Required Elements:**
- ✅ Purpose statement
- ✅ All parameters documented with types and defaults
- ✅ At least one realistic example
- ✅ Notes section (if applicable)

### Pipelines, Jobs, and Stages (`pipelines/`, `jobs/`, `stages/`) - External Documentation

These templates should **NOT** have comprehensive in-file documentation blocks:

- ✅ Use self-documenting parameter names
- ✅ Use `displayName` attribute on all parameters
- ✅ Keep template files clean and implementation-focused
- ✅ Document comprehensively in `docs/` directory (e.g., `docs/user-docs/infrastructure_pipeline.md`)

### Schemas (`schemas/`) - Brief Comments Only

```yaml
# Schema Template: Name
# Brief description of purpose
# See: docs/path/to/details.md

parameters:
  # ...parameters...
```

## Template Structure and Design

### Parameter Best Practices

```yaml
parameters:
  - name: ParameterName
    type: string  # string, number, boolean, object, stepList, jobList, etc.
    displayName: 'User-friendly description shown in UI'
    default: 'sensible-default'  # Optional, omit if parameter is required
    values:  # Optional, for enumeration
      - option1
      - option2

  - name: RequiredParameter
    type: string
    # NO default - Consumer must provide this
    displayName: 'Required parameter description'
```

**Guidelines:**
- Use `displayName` on **all** parameters for clarity
- Choose appropriate `type` for validation
- Use `values` to restrict to known options
- Comment `# NO default - Consumer must provide this` for required parameters
- Provide sensible defaults for optional parameters

### Variable Best Practices

```yaml
variables:
  - name: VariableName
    value: ${{ parameters.ParameterName }}  # Compile-time expression

  - name: RuntimeVariable
    value: $(Build.BuildId)  # Runtime expression

  # Variable from external template
  - template: ../utils/variable-template.yml
    parameters:
      SomeParam: 'value'
```

**Guidelines:**
- Use compile-time expressions (`${{ }}`) for parameters and conditions
- Use runtime expressions (`$()`) for built-in variables and outputs
- Organize variables logically (group related variables together)
- Use meaningful names that indicate purpose

### Conditional Logic

```yaml
# Compile-time conditions (evaluated before pipeline runs)
- ${{ if eq(parameters.DeployMode, 'Production') }}:
    - script: echo "Production deployment"

# Runtime conditions (evaluated during pipeline execution)
- script: echo "Conditional step"
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
```

**When to use each:**
- **Compile-time** (`${{ if }}`): Template logic, parameter-based decisions, structure changes
- **Runtime** (`condition:`): Build results, variable values, dynamic conditions

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

**Instead, use a single comprehensive template:**

```yaml
# ✅ GOOD - Single template with all logic
# terraform.yml
parameters:
  - name: Command
    type: string
    values: [init, plan, apply, destroy]

steps:
  - ${{ if eq(parameters.Command, 'init') }}:
      # ...init-specific logic...
  - ${{ else }}:
      - task: TerraformTask@5
        inputs:
          command: ${{ parameters.Command }}
```

**Exceptions where wrappers are acceptable:**
- Orchestration at different levels (pipeline → stage → job → task)
- Combining multiple unrelated templates into a workflow
- Enforcing organizational standards with validation

See: `docs/anti-pattern-double-wrapping.md`

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

This repository follows **Semantic Versioning 2.0.0**:

- **Major version** (1.0.0 → 2.0.0): Breaking changes
- **Minor version** (1.0.0 → 1.1.0): New features, backward compatible
- **Patch version** (1.0.0 → 1.0.1): Bug fixes, backward compatible

### Breaking Changes Include:

- ❌ Renaming, removing, or changing type of parameters
- ❌ Removing or renaming template files
- ❌ Changing default values that affect behavior
- ❌ Removing steps, jobs, or outputs
- ❌ Changing expected input/output structure

### Non-Breaking Changes Include:

- ✅ Adding optional parameters with defaults
- ✅ Adding new steps that don't affect existing behavior
- ✅ Improving documentation
- ✅ Fixing bugs
- ✅ Internal refactoring

**When making breaking changes:**
1. Increment major version
2. Update `CHANGELOG.md`
3. Document migration steps
4. Consider deprecation period if feasible

## Security Best Practices

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

- Use **managed identities** when possible instead of service principals
- Follow **principle of least privilege** (minimal required permissions)
- Use **environment-specific** service connections
- Implement **approval gates** for production deployments

### Secret Scanning

```yaml
# Ensure secrets are not logged
- script: |
    echo "##vso[task.setvariable variable=MySecret;isSecret=true]$(SecretValue)"
  displayName: 'Set secret variable (not logged)'
```

## Performance Optimization

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

- Use **PascalCase** for parameter names: `TerraformVersion`, `ServiceConnectionName`
- Use full words, avoid abbreviations: `TargetEnvironment` not `TgtEnv`
- Prefix boolean parameters with verbs: `EnableLogging`, `AllowFailure`, `RunTests`

## Template Reusability Checklist

When creating a new template:

- [ ] Follows correct documentation strategy (in-file for tasks/utils, external for pipelines/jobs/stages)
- [ ] All parameters have types and displayName
- [ ] Defaults are sensible and documented
- [ ] No hardcoded values (use parameters or variables)
- [ ] No double-wrapping or unnecessary abstraction
- [ ] Error handling implemented where needed
- [ ] Follows `.editorconfig` formatting rules
- [ ] Security best practices followed
- [ ] Tested with realistic scenarios
- [ ] Added example usage (in-file or in docs)

## Additional Resources

- **Repository Guidelines:** `.github/copilot-instructions.md`
- **Anti-patterns:** `docs/anti-pattern-double-wrapping.md`
- **User Documentation:** `docs/user-docs/README.md`
- **Versioning Guide:** `docs/how-to-version.md`
- **EditorConfig Spec:** https://editorconfig.org/
- **Azure DevOps YAML Schema:** https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema

