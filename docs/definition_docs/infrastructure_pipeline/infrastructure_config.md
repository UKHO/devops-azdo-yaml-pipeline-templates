# InfrastructureConfig

The configuration object that defines how Terraform should be deployed to a target Azure environment. This includes Azure service connections, backend state storage, verification settings, Key Vault integration, variable mappings, and output exports.

## Definition

```yaml
InfrastructureConfig:
  AzureSubscriptionServiceConnection: string    # REQUIRED
  AzDOEnvironmentName: string                   # REQUIRED
  BackendConfig:                                # REQUIRED
    ServiceConnection: string                   # REQUIRED
    ResourceGroupName: string                   # REQUIRED
    StorageAccountName: string                  # REQUIRED
    ContainerName: string                       # REQUIRED
    BlobName: string                            # REQUIRED
  VerificationMode: string                      # REQUIRED (VerifyOnDestroy | VerifyOnAny | VerifyDisabled)
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

### AzureSubscriptionServiceConnection

**Type:** `string`

**Description:** The Azure DevOps service connection name used to authenticate with Azure for deploying resources.

**Example:** `'AzureServiceConnection-Production'`

---

### AzDOEnvironmentName

**Type:** `string`

**Description:** The Azure DevOps environment name for approval gates and deployment tracking.

**Example:** `'production-environment'`

---

### BackendConfig

**Type:** `object`

**Description:** Configuration for Terraform backend state storage in Azure. All sub-properties are required.

---

#### BackendConfig.ServiceConnection

**Type:** `string`

**Description:** Azure service connection for backend access (can be the same as AzureSubscriptionServiceConnection).

**Example:** `'AzureServiceConnection-TerraformState'`

---

#### BackendConfig.ResourceGroupName

**Type:** `string`

**Description:** Resource group containing the storage account for Terraform state.

**Example:** `'rg-terraform-state-prod'`

---

#### BackendConfig.StorageAccountName

**Type:** `string`

**Description:** Storage account name for Terraform state.

**Example:** `'sttfstateprod'`

---

#### BackendConfig.ContainerName

**Type:** `string`

**Description:** Container name within the storage account.

**Example:** `'tfstate'`

---

#### BackendConfig.BlobName

**Type:** `string`

**Description:** Blob name for the Terraform state file.

**Example:** `'production.terraform.tfstate'`

---

### VerificationMode

**Type:** `string`

**Description:** Controls when manual verification is required.

**Allowed Values:**
- `'VerifyOnDestroy'` - Manual verification only when resources will be destroyed
- `'VerifyOnAny'` - Manual verification for any infrastructure changes
- `'VerifyDisabled'` - No manual verification (auto-apply if changes detected)

**Example:** `'VerifyOnAny'`

---

## Optional Properties

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
```
stageDependencies.Deploy_{EnvironmentName}_Infrastructure.TerraformDeploy_Apply.outputs['TerraformDeploy_Apply.TerraformExportOutputsVariables.{variableName}']
```

---

## Complete Example

```yaml
InfrastructureConfig:
  AzureSubscriptionServiceConnection: AzureServiceConnection-Production
  AzDOEnvironmentName: production-environment
  BackendConfig:
    ServiceConnection: AzureServiceConnection-TerraformState
    ResourceGroupName: rg-terraform-state-prod
    StorageAccountName: sttfstateprod
    ContainerName: tfstate
    BlobName: production.terraform.tfstate
  VerificationMode: VerifyOnAny
  KeyVaultConfig:
    ServiceConnection: AzureServiceConnection-Production
    Name: kv-production-secrets
    SecretsFilter: '*'
  JobsVariableMappings:
    - group: ProductionVariableGroup
    - group: CommonVariableGroup
    - template: config/production-variables.yml
    - name: ENVIRONMENT_NAME
      value: production
    - name: LOG_LEVEL
      value: info
  EnvironmentVariableMappings:
    TF_LOG: INFO
    ARM_SKIP_PROVIDER_REGISTRATION: 'true'
  VariableFiles:
    - config/common.tfvars
    - config/production.tfvars
  OutputVariables:
    - resource_group_name
    - app_service_url
    - storage_account_name
```

## See Also

- [Environment Config Documentation](./environment_config.md) - Complete environment configuration structure
- [User Documentation](../../user-docs/infrastructure_pipeline.md) - End-user pipeline documentation
- [Parameters in Detail](../../user-docs/infrastructure_pipeline_parameters_in_detail.md) - Legacy single-environment parameter reference
