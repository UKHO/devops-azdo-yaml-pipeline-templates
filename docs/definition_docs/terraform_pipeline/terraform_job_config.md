# Terraform Job Config

This document covers the two configuration objects used by the Terraform deploy/destroy job templates:

- **`TerraformDeploymentConfig`** — used by [`jobs/terraform_deploy.yml`](../../user-docs/jobs/terraform_deploy.md) and [`jobs/terraform_gated_deployment.yml`](../../user-docs/jobs/terraform_gated_deployment.md)
- **`TerraformDestroyConfig`** — used by [`jobs/terraform_destroy.yml`](../../user-docs/jobs/terraform_destroy.md) and [`jobs/terraform_gated_destroy.yml`](../../user-docs/jobs/terraform_gated_destroy.md)

Each object has a set of **core fields** consumed by the leaf job (`terraform_deploy.yml` / `terraform_destroy.yml`), and a set of **gated-only fields** consumed only by the orchestrator job (`terraform_gated_deployment.yml` / `terraform_gated_destroy.yml`). Each field below is labelled with which job(s) actually consume it, and which schema template validates it.

> **Validation layering:** Each job validates only the fields it actually consumes via its own schema (`schemas/terraform_deploy_config.yml`, `schemas/terraform_gated_deployment_config.yml`, `schemas/terraform_destroy_config.yml`, `schemas/terraform_gated_destroy_config.yml`). Calling a gated job validates the gated fields and then invokes the leaf schema for the remaining fields; calling a leaf job directly does not validate gated-only fields.

---

## TerraformDeploymentConfig

### Definition

```yaml
TerraformDeploymentConfig:
  AzDOEnvironmentName: string                   # REQUIRED - leaf job (terraform_deploy.yml)
  RunMode: string                               # REQUIRED - gated job only (terraform_gated_deployment.yml); PlanVerifyApply | PlanOnly | ApplyOnly
  VerificationMode: string                      # OPTIONAL - leaf job (only meaningful when RunMode is PlanVerifyApply)
  BackendConfig: object                         # OPTIONAL - leaf job
  AzureServiceConnection: string                # OPTIONAL - leaf job
  KeyVaultConfig:                               # OPTIONAL (legacy, all-or-nothing) - leaf job - use ConfigSources instead
    ServiceConnection: string
    Name: string
    SecretsFilter: string
  ConfigSources:                                # OPTIONAL (new, array-based) - leaf job - cannot use with KeyVaultConfig
    - Type: string                              # REQUIRED ('KeyVault')
      ServiceConnection: string
      SecretsFilter: string
      Name: string
      RunAsPreJob: boolean
  JobsVariableMappings: object                  # OPTIONAL - leaf job
  EnvironmentVariableMappings: object           # OPTIONAL - leaf job
  VariableFiles: list                           # OPTIONAL - leaf job
  OutputVariables: list                         # OPTIONAL - leaf job
  VerificationTimeoutInMinutes: number          # OPTIONAL - gated job only (only used when RunMode is PlanVerifyApply)
  VerificationTimeoutBehaviour: string          # OPTIONAL - gated job only ('reject' | 'resume', only used when RunMode is PlanVerifyApply)
```

### Core fields (consumed by `terraform_deploy.yml`)

Validated by `schemas/terraform_deploy_config.yml`.

#### AzDOEnvironmentName

**Type:** `string` · **Required**

The Azure DevOps environment name for approval gates and deployment tracking.

**Example:** `'production-environment'`

---

#### VerificationMode

**Type:** `string` · **Optional**

Controls whether `terraform_deploy.yml`'s Plan job adds the plan-verification steps (`terraform show` + `TerraformChangesCheck`). It is required by the gated orchestrator when `RunMode` is `PlanVerifyApply`; when calling the leaf job directly, providing it adds those plan-verification steps. If omitted, no verification steps are added.

**Allowed Values (if provided):**

- `'VerifyOnDestroy'` - Manual verification only when resources will be destroyed
- `'VerifyOnAny'` - Manual verification for any infrastructure changes
- `'VerifyDisabled'` - No manual verification (auto-apply if changes detected)

**Example:** `'VerifyOnAny'`

---

#### BackendConfig

**Type:** `object` · **Optional**

Free-form key-value pairs passed as `-backend-config` arguments to `terraform init`. If not provided, backend configuration can be hardcoded directly in your Terraform files (e.g., in `main.tf` or `terraform.tf`).

**Option 1: Pipeline Parameter (Flexible)**

```yaml
BackendConfig:
  resource_group_name: 'rg-terraform-state-prod'
  storage_account_name: 'sttfstateprod'
  container_name: 'tfstate'
  key: 'production.terraform.tfstate'
```

**Option 2: Hardcoded in Terraform (Simple)**

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

#### AzureServiceConnection

**Type:** `string` · **Optional**

The Azure DevOps service connection name used to authenticate with Azure for deploying resources and backend state storage. If not provided, the pipeline expects client credentials (`ARM_CLIENT_ID`/`ARM_CLIENT_SECRET`) to be provided via `EnvironmentVariableMappings`.

**Example:** `'AzureServiceConnection-Production'`

**Alternative (without service connection):**

```yaml
EnvironmentVariableMappings:
  ARM_CLIENT_ID: 'your-client-id'
  ARM_CLIENT_SECRET: 'your-client-secret'
  ARM_SUBSCRIPTION_ID: 'your-subscription-id'
  ARM_TENANT_ID: 'your-tenant-id'
```

---

#### KeyVaultConfig

**Type:** `object` · **Optional (legacy)**

Configuration for retrieving secrets from Azure Key Vault. All-or-nothing configuration - if any property is set, all three must be set. Mutually exclusive with `ConfigSources`. Key Vault secrets are retrieved during the Deploy stage, before Terraform operations.

| Property            | Type   | Description                                                                        |
|----------------------|--------|-------------------------------------------------------------------------------------|
| `ServiceConnection`  | string | Azure service connection for Key Vault access. Example: `'AzureServiceConnection-Production'` |
| `Name`               | string | Key Vault name. Example: `'kv-production-secrets'`                                  |
| `SecretsFilter`      | string | Filter for secrets to retrieve. Use `'*'` for all secrets or comma-separated secret names. |

---

#### ConfigSources

**Type:** `list` of `object` · **Optional**

Array-based configuration for retrieving secrets from one or more Azure Key Vaults with ordered execution. Mutually exclusive with `KeyVaultConfig`. Currently supports `Type: KeyVault` entries only.

**Migration:** If currently using `KeyVaultConfig` (legacy), see [Upgrade Guide: 0.1.0 -> 0.2.0](../../user-docs/upgrades/0.1.0-to-0.2.0-keyvaultconfig-to-configsources.md).

```yaml
ConfigSources:
  - Type: KeyVault
    Name: 'shared-secrets-vault'
    ServiceConnection: 'Azure-Prod-SC'
    SecretsFilter: 'shared-*'
    RunAsPreJob: false
```

For detailed field documentation, see [ConfigSources Definition](../shared/config_sources.md).

---

#### JobsVariableMappings

**Type:** `object` · **Optional**

List of variable mappings (variable groups, templates, or inline variables) added to the deployment job's variables block.

```yaml
JobsVariableMappings:
  - group: ProductionVariableGroup
  - group: CommonVariableGroup
  - template: config/production-variables.yml
  - name: ENVIRONMENT_NAME
    value: production
```

---

#### EnvironmentVariableMappings

**Type:** `object` · **Optional**

Key-value pairs of environment variables set for Terraform execution (`init`, `plan`, `apply`).

```yaml
EnvironmentVariableMappings:
  TF_LOG: INFO
  ARM_SKIP_PROVIDER_REGISTRATION: 'true'
```

---

#### VariableFiles

**Type:** `list` of `string` · **Optional**

List of Terraform variable file paths (`.tfvars`) relative to the Terraform working directory. Must be included in the artifact created during the build stage.

```yaml
VariableFiles:
  - config/common.tfvars
  - config/production.tfvars
```

---

#### OutputVariables

**Type:** `list` of `string` · **Optional**

List of Terraform output variable names to export as pipeline variables after a successful apply.

```yaml
OutputVariables:
  - resource_group_name
  - app_service_url
```

**Accessing Output Variables:**

- Same stage (later job):

  ```text
  dependencies.TerraformDeployApply_{ArtifactName}.outputs['TerraformDeployApply_{ArtifactName}.TerraformExportOutputsVariables.{variableName}']
  ```

- Later stage:

  ```text
  stageDependencies.Deploy_{EnvironmentName}_Terraform.TerraformDeployApply_{ArtifactName}.outputs['TerraformDeployApply_{ArtifactName}.TerraformExportOutputsVariables.{variableName}']
  ```

### Gated-only fields (consumed by `terraform_gated_deployment.yml`)

Validated by `schemas/terraform_gated_deployment_config.yml`. These fields have no effect if you call `terraform_deploy.yml` directly (except `VerificationMode`, which is a core field above).

#### RunMode

**Type:** `string` · **Required (gated job only)**

Controls which deployment jobs the orchestrator creates.

**Allowed Values:**

- `'PlanVerifyApply'` - Creates a plan, allows for manual verification (requires `VerificationMode`), then applies the plan
- `'PlanOnly'` - Creates and reviews a plan only, does not apply
- `'ApplyOnly'` - Skips planning and applies Terraform changes directly

**Example:** `'PlanVerifyApply'`

**Cross-field rule:** `VerificationMode` is required when `RunMode` is `'PlanVerifyApply'`.

---

#### VerificationTimeoutInMinutes

**Type:** `number` · **Optional** · **Allowed Range:** `1` - `43200` (30 days)

How long to wait for manual approval before applying `VerificationTimeoutBehaviour`. Only applicable when `RunMode` is `PlanVerifyApply`. Defaults to `60` when omitted.

#### VerificationTimeoutBehaviour

**Type:** `string` · **Optional** · **Allowed Values:** `'reject'` | `'resume'`

Action to take if manual verification is not actioned within `VerificationTimeoutInMinutes`. Only applicable when `RunMode` is `PlanVerifyApply`. Defaults to `'reject'` when omitted.

- `'reject'` - The job fails, halting the pipeline (default behaviour)
- `'resume'` - The job automatically succeeds as if approved, and the pipeline continues

### Complete Examples

#### PlanVerifyApply with Manual Verification

```yaml
TerraformDeploymentConfig:
  AzDOEnvironmentName: production-environment
  AzureServiceConnection: AzureServiceConnection-Production
  BackendConfig:
    resource_group_name: rg-terraform-state-prod
    storage_account_name: sttfstateprod
    container_name: tfstate
    key: production.terraform.tfstate
  RunMode: PlanVerifyApply
  VerificationMode: VerifyOnAny
  ConfigSources:
    - Type: KeyVault
      Name: kv-production-secrets
      ServiceConnection: AzureServiceConnection-Production
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

#### ApplyOnly (Skips Planning)

```yaml
TerraformDeploymentConfig:
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

### Related Tests

- **Plan Basic**: [`tests/jobs/terraform_deploy/plan_basic_test.yml`](../../../tests/jobs/terraform_deploy/plan_basic_test.yml)
- **Apply Basic**: [`tests/jobs/terraform_deploy/apply_basic_test.yml`](../../../tests/jobs/terraform_deploy/apply_basic_test.yml)
- **Gated Deployment (PlanVerifyApply)**: [`tests/jobs/terraform_gated_deployment/plan_verify_apply_test.yml`](../../../tests/jobs/terraform_gated_deployment/plan_verify_apply_test.yml)
- **Gated Deployment (PlanOnly)**: [`tests/jobs/terraform_gated_deployment/plan_only_test.yml`](../../../tests/jobs/terraform_gated_deployment/plan_only_test.yml)

---

## TerraformDestroyConfig

### Definition

```yaml
TerraformDestroyConfig:
  AzDOEnvironmentName: string                   # REQUIRED - leaf job (terraform_destroy.yml)
  RunMode: string                               # REQUIRED - gated job only (terraform_gated_destroy.yml); PlanVerifyDestroy | PlanOnly | DestroyOnly
  BackendConfig: object                         # OPTIONAL - leaf job
  AzureServiceConnection: string                # OPTIONAL - leaf job
  ConfigSources:                                # OPTIONAL (array-based) - leaf job
    - Type: string                              # OPTIONAL ('KeyVault')
      ServiceConnection: string
      Name: string
      SecretsFilter: string
      RunAsPreJob: boolean
  JobsVariableMappings: object                  # OPTIONAL - leaf job
  EnvironmentVariableMappings: object           # OPTIONAL - leaf job
  VariableFiles: list                           # OPTIONAL - leaf job
  VerificationTimeoutInMinutes: number          # OPTIONAL - gated job only (only used when RunMode is PlanVerifyDestroy)
  VerificationTimeoutBehaviour: string          # OPTIONAL - gated job only ('reject' | 'resume', only used when RunMode is PlanVerifyDestroy)
```

### Core fields (consumed by `terraform_destroy.yml`)

Validated by `schemas/terraform_destroy_config.yml`.

#### AzDOEnvironmentName

**Type:** `string` · **Required**

Azure DevOps environment used by the destroy deployment job.

#### BackendConfig

**Type:** `object` · **Optional**

Key-value pairs passed to `terraform init` as `-backend-config` options.

#### AzureServiceConnection

**Type:** `string` · **Optional**

Azure service connection used for authenticated Terraform execution.

#### ConfigSources

**Type:** `list` of `object` · **Optional**

Ordered list of configuration sources used before Terraform execution. Supports `Type: KeyVault` entries. See [ConfigSources Definition](../shared/config_sources.md) for field details.

#### JobsVariableMappings

**Type:** `object` · **Optional**

Variable groups, templates, or inline variable mappings added to the job variables block.

#### EnvironmentVariableMappings

**Type:** `object` · **Optional**

Environment variables passed to Terraform tasks.

#### VariableFiles

**Type:** `list` of `string` · **Optional**

List of `.tfvars` files relative to the artifact root.

### Not Supported in Destroy Config

- `KeyVaultConfig` is deprecated and not supported in destroy workflows — use `ConfigSources` instead.
- `VerificationMode` is not supported — use `RunMode: PlanVerifyDestroy` for gated destroy flows instead.

### Gated-only fields (consumed by `terraform_gated_destroy.yml`)

Validated by `schemas/terraform_gated_destroy_config.yml`. These fields have no effect if you call `terraform_destroy.yml` directly.

#### RunMode

**Type:** `string` · **Required (gated job only)**

**Allowed Values:**

- `'PlanVerifyDestroy'` - Runs destroy plan, always requires manual verification, then runs destroy
- `'PlanOnly'` - Runs destroy plan only
- `'DestroyOnly'` - Runs destroy directly without plan or manual verification

Unlike deployment's `RunMode`, `PlanVerifyDestroy` **always** inserts a manual verification job — there is no equivalent of `VerificationMode` for destroy workflows.

#### VerificationTimeoutInMinutes

**Type:** `number` · **Optional** · **Allowed Range:** `1` - `43200` (30 days)

How long to wait for manual approval before applying `VerificationTimeoutBehaviour`. Only applicable when `RunMode` is `PlanVerifyDestroy`. Defaults to `60` when omitted.

#### VerificationTimeoutBehaviour

**Type:** `string` · **Optional** · **Allowed Values:** `'reject'` | `'resume'`

Action to take if manual verification is not actioned within `VerificationTimeoutInMinutes`. Only applicable when `RunMode` is `PlanVerifyDestroy`. Defaults to `'reject'` when omitted.

- `'reject'` - The job fails, halting the pipeline (default behaviour)
- `'resume'` - The job automatically succeeds as if approved, and the pipeline continues

### Examples

#### PlanVerifyDestroy

```yaml
TerraformDestroyConfig:
  AzDOEnvironmentName: production-environment
  RunMode: PlanVerifyDestroy
  AzureServiceConnection: AzureServiceConnection-Production
  BackendConfig:
    resource_group_name: rg-terraform-state-prod
    storage_account_name: sttfstateprod
    container_name: tfstate
    key: production.terraform.tfstate
  ConfigSources:
    - Type: KeyVault
      Name: kv-production-secrets
      ServiceConnection: AzureServiceConnection-Production
      SecretsFilter: '*'
  VariableFiles:
    - config/common.tfvars
    - config/production.tfvars
```

#### DestroyOnly

```yaml
TerraformDestroyConfig:
  AzDOEnvironmentName: dev-environment
  RunMode: DestroyOnly
  AzureServiceConnection: AzureServiceConnection-Dev
```

### Related Tests

- [`jobs/terraform_destroy.CompileTests.ps1`](../../../jobs/terraform_destroy.CompileTests.ps1)
- [`jobs/terraform_gated_destroy.CompileTests.ps1`](../../../jobs/terraform_gated_destroy.CompileTests.ps1)
- [`schemas/terraform_destroy_config.CompileTests.ps1`](../../../schemas/terraform_destroy_config.CompileTests.ps1)
- [`schemas/terraform_gated_destroy_config.CompileTests.ps1`](../../../schemas/terraform_gated_destroy_config.CompileTests.ps1)

---

## See Also

- [Environment Config Documentation](./environment_config.md) - Complete environment configuration structure
- [ConfigSources Definition](../shared/config_sources.md) - Shared `ConfigSources` array field documentation
- [Terraform Pipeline User Documentation](../../user-docs/pipelines/terraform_pipeline.md) - End-user pipeline documentation
- [Terraform Deploy Job Documentation](../../user-docs/jobs/terraform_deploy.md)
- [Terraform Gated Deployment Job Documentation](../../user-docs/jobs/terraform_gated_deployment.md)
- [Terraform Destroy Job Documentation](../../user-docs/jobs/terraform_destroy.md)
- [Terraform Gated Destroy Job Documentation](../../user-docs/jobs/terraform_gated_destroy.md)
