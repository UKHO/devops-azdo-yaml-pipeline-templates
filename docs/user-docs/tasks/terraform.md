# Task: Terraform

> **Source**: [../../tasks/terraform.yml](../../tasks/terraform.yml)
> **Type**: Task
> **Last Updated**: 2025-10-15

## Overview

Standardized wrapper for TerraformTask@5 with Azure (azurerm) focus. This task provides comprehensive terraform command execution with conditional parameter validation, backend configuration support, and fail-fast error handling. Supports all major terraform commands with Azure-specific optimizations.

**Hidden Functionality**:
- Automatically handles `-backend=false` for init commands when DisableBackend is true
- Provides conditional parameter validation based on command type
- Azure-only provider support (other cloud providers excluded by design)
- Command-specific parameter handling with smart defaults

## Quick Start

### Basic Usage

```yaml
- template: tasks/terraform.yml
  parameters:
    Command: 'init'
    WorkingDirectory: '$(Pipeline.Workspace)/terraform'
```

### Required Parameters

| Parameter | Type   | Required | Description                                            |
|-----------|--------|----------|--------------------------------------------------------|
| Command   | string | Yes      | Terraform command to execute (init, plan, apply, etc.) |

## Parameters Reference

| Parameter                                   | Type    | Default                 | Description                                                   |
|---------------------------------------------|---------|-------------------------|---------------------------------------------------------------|
| Command                                     | string  | *Required*              | Terraform command to execute                                  |
| WorkingDirectory                            | string  | '$(Pipeline.Workspace)' | Working directory for Terraform files                         |
| CommandOptions                              | string  | ''                      | Additional command arguments                                  |
| CustomCommand                               | string  | ''                      | Custom Terraform command (when command = custom)              |
| OutputTo                                    | string  | 'console'               | Output destination for show/output commands                   |
| OutputFileName                              | string  | ''                      | Output file name (when OutputTo = file)                       |
| OutputFormat                                | string  | 'default'               | Output format for show command                                |
| BackendAzureServiceConnection               | string  | ''                      | Azure service connection for backend                          |
| BackendAzureStorageAccountName              | string  | ''                      | Azure storage account name for backend                        |
| BackendAzureContainerName                   | string  | ''                      | Azure storage container name for backend                      |
| BackendAzureBlobName                        | string  | ''                      | Azure storage blob name for state file                        |
| BackendAzureStorageAccountResourceGroupName | string  | ''                      | Azure resource group name for backend                         |
| DisableBackend                              | boolean | false                   | Disable the backend configuration when executing init command |
| EnvironmentAzureServiceConnection           | string  | ''                      | Azure service connection for providers                        |

## Dependencies

This template wraps the Microsoft TerraformTask@5 and has no template dependencies.

## Advanced Examples

### Terraform Init with Azure Backend

```yaml
- template: tasks/terraform.yml
  parameters:
    Command: 'init'
    WorkingDirectory: '$(Pipeline.Workspace)/infrastructure'
    BackendAzureServiceConnection: 'MyAzureConnection'
    BackendAzureStorageAccountName: 'mystorageaccount'
    BackendAzureContainerName: 'tfstate'
    BackendAzureBlobName: 'terraform.tfstate'
    BackendAzureStorageAccountResourceGroupName: 'terraform-rg'
```

### Terraform Plan with Output File

```yaml
- template: tasks/terraform.yml
  parameters:
    Command: 'plan'
    WorkingDirectory: '$(Pipeline.Workspace)/terraform'
    CommandOptions: '-out tfplan'
    EnvironmentAzureServiceConnection: 'MyAzureConnection'
```

### Terraform Apply from Plan File

```yaml
- template: tasks/terraform.yml
  parameters:
    Command: 'apply'
    WorkingDirectory: '$(Pipeline.Workspace)/terraform'
    CommandOptions: 'tfplan'
    EnvironmentAzureServiceConnection: 'MyAzureConnection'
```

### Custom Terraform Commands

```yaml
- template: tasks/terraform.yml
  parameters:
    Command: 'custom'
    CustomCommand: 'workspace list'
    WorkingDirectory: '$(Pipeline.Workspace)/terraform'
```

### Terraform Show with JSON Output

```yaml
- template: tasks/terraform.yml
  parameters:
    Command: 'show'
    WorkingDirectory: '$(Pipeline.Workspace)/terraform'
    CommandOptions: 'tfplan'
    OutputTo: 'file'
    OutputFileName: 'plan-output.json'
    OutputFormat: 'json'
```

## Parameter Details

### Command Types

**Supported Values**: init, validate, show, plan, apply, output, destroy, custom

- **init**: Initialize terraform working directory
- **validate**: Validate terraform configuration files
- **show**: Show terraform plan or state file
- **plan**: Create terraform execution plan
- **apply**: Apply terraform changes
- **output**: Read terraform output values
- **destroy**: Destroy terraform-managed infrastructure
- **custom**: Execute custom terraform commands via CustomCommand parameter

### DisableBackend

When set to `true` for init commands, automatically executes `terraform init -backend=false` instead of using the TerraformTask@5. This is useful for:
- Validation-only scenarios
- Local development
- When backend configuration is not available

```yaml
- template: tasks/terraform.yml
  parameters:
    Command: 'init'
    DisableBackend: true
    WorkingDirectory: '$(Pipeline.Workspace)/terraform'
```

### Azure Backend Configuration

All backend parameters are optional but typically used together for remote state management:

```yaml
BackendAzureServiceConnection: 'connection-name'      # Required for authenticated access
BackendAzureStorageAccountName: 'storageaccount'     # Storage account for state file
BackendAzureContainerName: 'tfstate'                 # Container name
BackendAzureBlobName: 'environment.tfstate'          # State file name
BackendAzureStorageAccountResourceGroupName: 'rg'    # Resource group containing storage
```

## Notes

- Only Azure (azurerm) provider is supported by design
- Backend configuration only applies to `init` commands
- Provider configuration only applies to `plan`, `apply`, and `destroy` commands
- The task provides fail-fast error handling with detailed error messages
- Custom commands support any valid terraform CLI command not covered by standard options

---

**Related Documentation**:
- [Terraform Build Job](../jobs/terraform_build.md) - Uses this task for validation and initialization
- [Terraform Installer Task](terraform_installer.md) - Installs terraform before using this task
