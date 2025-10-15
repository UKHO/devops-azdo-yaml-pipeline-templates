# Task: Terraform Installer

> **Source**: [../../tasks/terraform_installer.yml](../../tasks/terraform_installer.yml)
> **Type**: Task
> **Last Updated**: 2025-10-15

## Overview

Standardized wrapper for TerraformInstaller@1 task with consistent parameter naming and version specification support. This task installs the specified version of Terraform CLI with snake_case parameter standardization and fail-fast error handling.

**Hidden Functionality**:

- Supports semantic versioning patterns (e.g., '1.11.x' for latest patch)
- Handles version ranges (e.g., '>=1.10.0')
- Provides consistent parameter naming across all terraform-related templates
- Automatic latest version detection when 'latest' is specified

## Quick Start

### Basic Usage

```yaml
- template: tasks/terraform_installer.yml
  parameters:
    TerraformVersion: 'latest'
```

### Required Parameters

*None* - All parameters have sensible defaults.

## Parameters Reference

| Parameter        | Type   | Default  | Description                  |
|------------------|--------|----------|------------------------------|
| TerraformVersion | string | 'latest' | Terraform version to install |

## Dependencies

This template wraps the Microsoft TerraformInstaller@1 task and requires the `ms-devlabs.custom-terraform-tasks` extension.

## Advanced Examples

### Specific Version Installation

```yaml
- template: tasks/terraform_installer.yml
  parameters:
    TerraformVersion: '1.5.0'
```

### Semantic Version Pattern

```yaml
- template: tasks/terraform_installer.yml
  parameters:
    TerraformVersion: '1.5.x'  # Latest patch version in 1.5 series
```

### Version Range

```yaml
- template: tasks/terraform_installer.yml
  parameters:
    TerraformVersion: '>=1.4.0'  # Version 1.4.0 or higher
```

### Production Environment (Pinned Version)

```yaml
- template: tasks/terraform_installer.yml
  parameters:
    TerraformVersion: '1.4.6'  # Pinned stable version for production
```

## Parameter Details

### TerraformVersion

Supports multiple version specification formats:

- **'latest'**: Installs the latest stable version available
- **Specific version**: '1.5.0', '1.4.6', '0.15.5'
- **Semantic version**: '1.5.x' (latest patch in 1.5 series)
- **Version range**: '>=1.4.0' (version 1.4.0 or higher)

```yaml
# Examples of valid version specifications
TerraformVersion: 'latest'        # Latest stable
TerraformVersion: '1.5.0'         # Exact version
TerraformVersion: '1.5.x'         # Latest in 1.5 series
TerraformVersion: '>=1.4.0'       # Minimum version
```

## Notes

- Requires the `ms-devlabs.custom-terraform-tasks` Azure DevOps extension
- The task uses snake_case parameter naming for consistency with other terraform templates
- Version validation is handled by the underlying TerraformInstaller@1 task
- Installation is performed once per pipeline run and cached for subsequent steps
- Compatible with both Microsoft-hosted and self-hosted agents

---

**Related Documentation**:

- [Terraform Task](terraform.md) - Uses terraform CLI installed by this task
- [Terraform Build Job](../jobs/terraform_build.md) - Includes this task for CLI installation
