# InfrastructureConfig

The configuration object that defines how Terraform should be deployed to a target Azure environment. This includes Azure service connections, backend state storage, verification settings, Key Vault integration, variable mappings, and output exports.

## Definition

```yaml
InfrastructureConfig:
  AzDOEnvironmentName: string                   # REQUIRED
  RunMode: string                               # REQUIRED (PlanVerifyApply | PlanOnly | ApplyOnly)
  VerificationMode: string                      # REQUIRED when RunMode is PlanVerifyApply
  BackendConfig: object                         # OPTIONAL - Key/value pairs for terraform backend-config (if not provided, hardcode in Terraform files)
  AzureServiceConnection: string                # OPTIONAL - Service connection (if not provided, use client credentials)
  KeyVaultConfig:                               # OPTIONAL (all-or-nothing)
    ServiceConnection: string
    Name: string
    SecretsFilter: string
  JobsVariableMappings: object                  # OPTIONAL
  EnvironmentVariableMappings: object           # OPTIONAL
  VariableFiles: list                           # OPTIONAL
  OutputVariables: list                         # OPTIONAL
```

---

## Required Properties

### AzDOEnvironmentName

**Type:** `string`

**Description:** The Azure DevOps environment name for approval gates and deployment tracking.

**Example:** `'production-environment'`

---


### RunMode

**Type:** `string`

**Description:** Controls which deployment jobs are run.

**Allowed Values:**
- `'PlanVerifyApply'` - Creates a plan, allows for manual verification (requires VerificationMode), then applies the plan
- `'PlanOnly'` - Creates and reviews a plan only, does not apply
- `'ApplyOnly'` - Skips planning and applies Terraform changes directly

**Example:** `'PlanVerifyApply'`

---

### VerificationMode

**Type:** `string`

**Description:** Controls when manual verification is required. Only applicable when `RunMode` is `PlanVerifyApply`; ignored for other RunModes.

**Allowed Values:**
- `'VerifyOnDestroy'` - Manual verification only when resources will be destroyed
- `'VerifyOnAny'` - Manual verification for any infrastructure changes
- `'VerifyDisabled'` - No manual verification (auto-apply if changes detected)

**Example:** `'VerifyOnAny'`

**Required When:** `RunMode` equals `'PlanVerifyApply'`

---

## Optional Properties

### BackendConfig

**Type:** `object`

**Description:** Free-form key-value pairs passed as `-backend-config` arguments to `terraform init`. If not provided, backend configuration can be hardcoded directly in your Terraform files (e.g., in `main.tf` or `terraform.tf`). Keys and values are arbitrary and depend on your Terraform backend provider.

**Option 1: Pipeline Parameter (Flexible)**
Define backend config via pipeline for environment-specific configuration:
```yaml
BackendConfig:
  resource_group_name: 'rg-terraform-state-prod'
  storage_account_name: 'sttfstateprod'
  container_name: 'tfstate'
  key: 'production.terraform.tfstate'
```

**Option 2: Hardcoded in Terraform (Simple)**
Define backend directly in your Terraform configuration file:
```hcl
# main.tf or terraform.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod"
    storage_account_name = "sttfstateprod"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
```

When using Option 2, omit `BackendConfig` from the pipeline entirely.

**Common Azure Backend Keys:**
- `resource_group_name` - Resource group containing the storage account for Terraform state
- `storage_account_name` - Storage account name for Terraform state
- `container_name` - Container name within the storage account
- `key` - Blob name for the Terraform state file

See [Terraform Backend Configuration Documentation](https://www.terraform.io/language/settings/backends) for details.

---

### AzureServiceConnection

**Type:** `string`

**Description:** The Azure DevOps service connection name used to authenticate with Azure for deploying resources and backend state storage. If not provided, the pipeline expects client credentials (ARM_CLIENT_ID and ARM_CLIENT_SECRET) to be provided via `EnvironmentVariableMappings`.

**Example:** `'AzureServiceConnection-Production'`

**Alternative (without service connection):**
When `AzureServiceConnection` is not provided, supply credentials via environment variables:
```yaml
EnvironmentVariableMappings:
  ARM_CLIENT_ID: 'your-client-id'
  ARM_CLIENT_SECRET: 'your-client-secret'
  ARM_SUBSCRIPTION_ID: 'your-subscription-id'
  ARM_TENANT_ID: 'your-tenant-id'
```

---

### KeyVaultConfig

**Type:** `object`

**Description:** Configuration for retrieving secrets from Azure Key Vault. This is an all-or-nothing configuration - if any property is set, all three must be set.

**Note:** Key Vault secrets are retrieved during the Deploy stage, before Terraform operations.

---

#### KeyVaultConfig.ServiceConnection

**Type:** `string`

**Description:** Azure service connection for Key Vault access.

**Example:** `'AzureServiceConnection-Production'`

---

#### KeyVaultConfig.Name

**Type:** `string`

**Description:** Key Vault name.

**Example:** `'kv-production-secrets'`

---

#### KeyVaultConfig.SecretsFilter

**Type:** `string`

**Description:** Filter for secrets to retrieve. Use `'*'` for all secrets or comma-separated secret names.

**Example:** `'*'` or `'secret1,secret2,secret3'`

---

### JobsVariableMappings

**Type:** `object`

**Description:** List of variable mappings (variable groups, templates, or inline variables) to be added to the deployment job's variables block. Supports variable groups, template references, and inline name/value pairs.

**Example:**
```yaml
JobsVariableMappings:
  - group: ProductionVariableGroup
  - group: CommonVariableGroup
  - template: config/production-variables.yml
  - name: ENVIRONMENT_NAME
    value: production
  - name: LOG_LEVEL
    value: info
```

---

### EnvironmentVariableMappings

**Type:** `object`

**Description:** Key-value pairs of environment variables to set for Terraform execution. These are passed to all Terraform tasks (init, plan, apply).

**Example:**
```yaml
EnvironmentVariableMappings:
  TF_LOG: INFO
  ARM_SKIP_PROVIDER_REGISTRATION: 'true'
  TF_VAR_custom_variable: 'value'
```

---

### VariableFiles

**Type:** `list` of `string`

**Description:** List of Terraform variable file paths (`.tfvars`) relative to the Terraform working directory. These files must be included in the Terraform artifact created during the build stage.

**Example:**
```yaml
VariableFiles:
  - config/common.tfvars
  - config/production.tfvars
```

---

### OutputVariables

**Type:** `list` of `string`

**Description:** List of Terraform output variable names to export as pipeline variables after a successful apply. These can be referenced in subsequent stages/jobs.

**Example:**
```yaml
OutputVariables:
  - resource_group_name
  - app_service_url
  - storage_account_name
```

**Accessing Output Variables:**

Exported variables can be accessed using:
```text
stageDependencies.Deploy_{EnvironmentName}_Infrastructure.TerraformDeploy_Apply.outputs['TerraformDeploy_Apply.TerraformExportOutputsVariables.{variableName}']
```

---

## Complete Examples

### PlanVerifyApply with Manual Verification

```yaml
InfrastructureConfig:
  AzDOEnvironmentName: production-environment
  AzureServiceConnection: AzureServiceConnection-Production
  BackendConfig:
    resource_group_name: rg-terraform-state-prod
    storage_account_name: sttfstateprod
    container_name: tfstate
    key: production.terraform.tfstate
  RunMode: PlanVerifyApply
  VerificationMode: VerifyOnAny
  KeyVaultConfig:
    ServiceConnection: AzureServiceConnection-Production
    Name: kv-production-secrets
    SecretsFilter: '*'
  JobsVariableMappings:
    - group: ProductionVariableGroup
  EnvironmentVariableMappings:
    TF_LOG: INFO
  VariableFiles:
    - config/common.tfvars
    - config/production.tfvars
  OutputVariables:
    - resource_group_name
    - app_service_url
```

### ApplyOnly (Skips Planning)

```yaml
InfrastructureConfig:
  AzDOEnvironmentName: dev-environment
  AzureServiceConnection: AzureServiceConnection-Dev
  BackendConfig:
    resource_group_name: rg-terraform-state-dev
    storage_account_name: sttfstatedev
    container_name: tfstate
    key: dev.terraform.tfstate
  RunMode: ApplyOnly
  VariableFiles:
    - config/common.tfvars
    - config/dev.tfvars
```

## See Also

- [Environment Config Documentation](./environment_config.md) - Complete environment configuration structure
- [User Documentation](../../user-docs/terraform_pipeline.md) - End-user pipeline documentation
- [Parameters in Detail](../../user-docs/terraform_pipeline_parameters_in_detail.md) - Legacy single-environment parameter reference
