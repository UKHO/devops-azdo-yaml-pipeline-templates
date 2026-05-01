# AdditionalFilesToPackage – Detailed Guide

This document provides comprehensive guidance on using the `AdditionalFilesToPackage` parameter in the Terraform Pipeline template.

**Quick Start:** See [terraform_pipeline_parameters_in_detail.md](./terraform_pipeline_parameters_in_detail.md#additionalfilestopackage) for the quick reference and basic examples.

---

## How It Works

Each item in `AdditionalFilesToPackage` is processed as a separate copy operation during the build stage. The files are copied using the Azure DevOps [Copy Files (CopyFiles@2)](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/copy-files-v2?view=azure-devops) task.

### Path Resolution

- `SourceDirectory` is appended to `$(Pipeline.Workspace)/$(Build.Repository.Name)/`
- `FilesPattern` is matched relative to the resolved source directory
- Matched files are copied to `{TerraformWorkingDirectory}/{TargetSubdirectoryName}`

### Example Artifact Structure

```
{ArtifactName}/
├── main.tf                    # From RelativePathToTerraformFiles
├── variables.tf               # From RelativePathToTerraformFiles
├── shared-config/             # From TargetSubdirectoryName
│   ├── common.tfvars
│   └── networking.tfvars
└── scripts/                   # From TargetSubdirectoryName
    ├── validate.ps1
    └── deploy.ps1
```

---

## Glob Pattern Matching

The `FilesPattern` property supports standard glob patterns for flexible file selection.

### Pattern Syntax Reference

| Pattern         | Matches                                                                    |
|-----------------|----------------------------------------------------------------------------|
| `*.tfvars`      | All `.tfvars` files in the source directory (non-recursive)                |
| `**/*.tfvars`   | All `.tfvars` files recursively in the source directory and subdirectories |
| `**/*.tf`       | All Terraform files recursively                                            |
| `config/*`      | All files in the `config/` subdirectory (one level deep)                   |
| `**/modules/**` | All files under any `modules/` directory at any depth                      |
| `**/*`          | All files recursively (includes directories)                               |
| `*`             | All files in the top-level source directory only                           |

### Multi-Line Patterns

For multiple patterns, separate them by newlines in a single FilesPattern string:

```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config'
    FilesPattern: |
      **/*.tfvars
      **/*.json
      **/*.yaml
    TargetSubdirectoryName: 'config'
```

### Pattern Matching Behavior

- **Anchored to SourceDirectory**: Patterns are evaluated starting from the `SourceDirectory` location
- **Case sensitivity**: Case-sensitive on Linux/Mac runners, case-insensitive on Windows runners
- **Hidden files**: Files starting with `.` (hidden files) are not matched unless explicitly included
- **Silent no-match**: If `FilesPattern` doesn't match any files, the operation succeeds silently with no files copied
- **Directory matching**: If a pattern matches both files and directories, both are included

---

## Common Use Cases

### Shared Terraform Variable Files

```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config'
    FilesPattern: 'common.tfvars'
    TargetSubdirectoryName: 'config'
```

**Purpose:** Enables multiple environments to reference shared variables during deployment.

**Usage in Terraform:**
```hcl
terraform {
  required_version = ">= 1.0"
}

variable "environment" {
  type = string
}

# In your deployment, pass the common variables
locals {
  common_config = file("${path.module}/../config/common.tfvars")
}
```

### Reusable Terraform Modules

```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'terraform/modules'
    FilesPattern: '**/*.tf'
    TargetSubdirectoryName: 'modules'
```

**Purpose:** Includes local terraform modules alongside main configuration.

**Usage in Terraform:**
```hcl
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  environment         = var.environment
}

module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
}
```

### Deployment Scripts

```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'scripts'
    FilesPattern: '**/*.ps1'
    TargetSubdirectoryName: 'scripts'
```

**Purpose:** Include PowerShell or other scripts needed during deployment.

**Usage in TerraformBuildInjectionSteps:**
```yaml
TerraformBuildInjectionSteps:
  - task: PowerShell@2
    displayName: 'Run validation script'
    inputs:
      filePath: '$(Pipeline.Workspace)/$(Build.Repository.Name)/scripts/validate.ps1'
```

### Multiple Configuration Sources

```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config/shared'
    FilesPattern: '*.json'
    TargetSubdirectoryName: 'config/shared'
  - SourceDirectory: 'config/env-specific'
    FilesPattern: '*.json'
    TargetSubdirectoryName: 'config/env-specific'
```

**Purpose:** Organize multiple configuration sources while preserving directory structure in the artifact.

**Directory structure:**
```
config/
├── shared/
│   ├── networking.json
│   └── security.json
└── env-specific/
    ├── dev.json
    └── prod.json
```

---

## Troubleshooting

### Files Not Being Copied

If files aren't being copied as expected, follow these debugging steps:

#### 1. Verify the pattern is correct

Patterns are relative to `SourceDirectory`, not the repository root.

**Example issue:**
```yaml
# WRONG: FilesPattern: '*.tfvars' with files in subdirectories
AdditionalFilesToPackage:
  - SourceDirectory: 'config'
    FilesPattern: '*.tfvars'  # Only matches files directly in config/
    TargetSubdirectoryName: 'config'
```

The pattern `*.tfvars` only matches `.tfvars` files in the root of `SourceDirectory`, not subdirectories like `config/dev/app.tfvars`.

**Solution:**
```yaml
# CORRECT: Use ** for recursive matching
AdditionalFilesToPackage:
  - SourceDirectory: 'config'
    FilesPattern: '**/*.tfvars'  # Matches recursively
    TargetSubdirectoryName: 'config'
```

#### 2. Check source directory exists

If `SourceDirectory` doesn't exist, the copy operation succeeds silently with no files copied.

**Debugging:**
- Verify the path is relative to the repository root
- Check that the directory actually exists in your repository
- Use simpler patterns to isolate the issue

**Example:**
```yaml
# Verify this directory exists: {repo}/terraform/modules
AdditionalFilesToPackage:
  - SourceDirectory: 'terraform/modules'
    FilesPattern: '**/*.tf'
    TargetSubdirectoryName: 'modules'
```

#### 3. Account for case sensitivity

Pattern matching behaves differently on Windows vs. Linux/Mac runners.

| Runner    | Behavior         | Example                                                                          |
|-----------|------------------|----------------------------------------------------------------------------------|
| Windows   | Case-insensitive | `*.TFVARS`, `*.tfvars`, `*.TfVars` all match                                     |
| Linux/Mac | Case-sensitive   | Only exact case matches (`*.tfvars` matches `file.tfvars` but not `file.TFVARS`) |

**Debugging on Linux/Mac:**
```yaml
# Might not work on Linux (case-sensitive):
FilesPattern: '*.TFVARS'

# Should work on Linux/Mac:
FilesPattern: '*.tfvars'
```

#### 4. Test with simpler patterns

Break complex patterns into multiple `AdditionalFilesToPackage` items to isolate issues:

**Complex pattern (hard to debug):**
```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config'
    FilesPattern: |
      **/env-*/(**/*.tfvars|**/*.json)
    TargetSubdirectoryName: 'config'
```

**Simplified patterns (easier to debug):**
```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config'
    FilesPattern: '**/*.tfvars'
    TargetSubdirectoryName: 'config'
  - SourceDirectory: 'config'
    FilesPattern: '**/*.json'
    TargetSubdirectoryName: 'config'
```

### Files Overwriting Each Other

When multiple items target the same `TargetSubdirectoryName`, files with the same name may overwrite each other.

**Example problem:**
```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config/shared'
    FilesPattern: '*.tfvars'
    TargetSubdirectoryName: 'config'  # Both copy to same target
  - SourceDirectory: 'config/env'
    FilesPattern: '*.tfvars'
    TargetSubdirectoryName: 'config'  # Risk of overwrites
```

If both `config/shared/` and `config/env/` contain a file named `common.tfvars`, the second copy operation will overwrite the first.

**Solutions:**

**Option 1: Use different target directories**
```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config/shared'
    FilesPattern: '*.tfvars'
    TargetSubdirectoryName: 'config/shared'  # Different target
  - SourceDirectory: 'config/env'
    FilesPattern: '*.tfvars'
    TargetSubdirectoryName: 'config/env'     # Different target
```

**Option 2: Use a single item with merged patterns**
```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config'
    FilesPattern: |
      shared/*.tfvars
      env/*.tfvars
    TargetSubdirectoryName: 'config'
```

### Artifact Not Being Created

If no artifact is being created at all, the issue is likely not with `AdditionalFilesToPackage` but with the main terraform files or the build stage itself. However, verify:

1. `RelativePathToTerraformFiles` points to a directory with terraform files
2. Terraform validation passes
3. Build stage completes successfully

---

## Performance Optimization

Each `AdditionalFilesToPackage` item executes one copy operation during the build stage. For better build performance, consolidate patterns where possible.

### Performance Analysis

**Less efficient (multiple copy operations):**
```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config'
    FilesPattern: '**/*.tfvars'
    TargetSubdirectoryName: 'config'
  - SourceDirectory: 'config'
    FilesPattern: '**/*.json'
    TargetSubdirectoryName: 'config'
  - SourceDirectory: 'config'
    FilesPattern: '**/*.yaml'
    TargetSubdirectoryName: 'config'
```

This executes 3 separate copy operations (6 total per build, since files are copied twice).

**More efficient (consolidated patterns):**
```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config'
    FilesPattern: |
      **/*.tfvars
      **/*.json
      **/*.yaml
    TargetSubdirectoryName: 'config'
```

This executes 1 copy operation (2 total per build).

### When to Consolidate

| Scenario                   | Recommendation                         |
|----------------------------|----------------------------------------|
| Same source and target     | Consolidate all patterns into one item |
| Different source or target | Keep as separate items                 |
| Very large artifact sets   | Consolidate to reduce copy operations  |
| Different pattern purposes | Consider separate items for clarity    |

**Example - Good separation:**
```yaml
AdditionalFilesToPackage:
  # Configuration files (separate purpose)
  - SourceDirectory: 'config'
    FilesPattern: |
      **/*.tfvars
      **/*.json
    TargetSubdirectoryName: 'config'

  # Terraform modules (separate purpose)
  - SourceDirectory: 'terraform/modules'
    FilesPattern: '**/*.tf'
    TargetSubdirectoryName: 'modules'

  # Scripts (separate purpose)
  - SourceDirectory: 'scripts'
    FilesPattern: '**/*.ps1'
    TargetSubdirectoryName: 'scripts'
```

---

## See Also

- [Terraform Pipeline Parameters in Detail](./terraform_pipeline_parameters_in_detail.md) - Quick reference and other parameters
- [AdditionalFilesToPackage Definition](../../definition_docs/terraform_pipeline/additional_files_to_package.md) - Object structure and properties
- [Copy Files Task Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/copy-files-v2?view=azure-devops) - Microsoft Azure DevOps documentation

