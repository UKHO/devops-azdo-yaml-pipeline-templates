# Terraform Deploy Job

A comprehensive job template for individual Terraform deployment steps. This job handles either the plan phase (showing what will change) or the apply phase (provisioning infrastructure), with support for environment variables, Key Vault integration, and output variable extraction.

---

## When to Use

Use this job template when you need to:

- **Create Terraform plans** – Show infrastructure changes without applying
- **Apply Terraform changes** – Provision or modify infrastructure
- **Integrate with custom workflows** – Build custom deployment orchestration
- **Advanced deployments** – Have fine-grained control over plan and apply steps

---

## What This Job Does

### Plan Mode

1. Downloads Terraform artifact from build stage
2. Runs `terraform init` with backend configuration
3. Runs `terraform plan` to show what will change
4. Saves plan output to JSON for analysis

### Apply Mode

1. Downloads Terraform artifact from build stage
2. Runs `terraform init` with backend configuration
3. Runs `terraform apply` to provision infrastructure
4. Extracts Terraform outputs as pipeline variables (if configured)

---

## Basic Usage

### Plan Only

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Plan
      EnvironmentName: dev
      TerraformDeploymentConfig:
        AzDOEnvironmentName: dev-environment
        RunMode: PlanOnly
        BackendConfig:
          resource_group_name: rg-state
          storage_account_name: tfstate
          container_name: tfstate
          key: dev.tfstate
```

### Apply Only

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Apply
      EnvironmentName: dev
      TerraformDeploymentConfig:
        AzDOEnvironmentName: dev-environment
        BackendConfig:
          resource_group_name: rg-state
          storage_account_name: tfstate
          container_name: tfstate
          key: dev.tfstate
```

---

## Parameters

### Required Parameters

| Parameter                   | Type   | Description                                                                   |
|-----------------------------|--------|-------------------------------------------------------------------------------|
| `TerraformDeployMode`       | string | `Plan` or `Apply` – determines which terraform command runs                   |
| `EnvironmentName`           | string | Environment identifier (e.g., `dev`, `prod`) – used in job naming and outputs |
| `TerraformDeploymentConfig` | object | Complete terraform deployment configuration (see below)                       |

### Configuration Parameters

| Parameter               | Type   | Default                 | Description                                    |
|-------------------------|--------|-------------------------|------------------------------------------------|
| `TerraformVersion`      | string | `1.14.0`                | Terraform CLI version to use                   |
| `TerraformArtifactName` | string | `TerraformArtifact`     | Name of artifact to download from build stage  |
| `Pool`                  | string | `''`                    | Agent pool for the job (uses default if empty) |
| `CheckoutAlias`         | string | `AzDOPipelineTemplates` | Repository alias for template checkout         |
| `DependsOn`             | object | `[ ]`                   | Jobs this job depends on                       |
| `Condition`             | string | `succeeded()`           | Condition for job execution                    |

### TerraformDeploymentConfig (Required)

Complex object with deployment configuration:

| Property                      | Type   | Required  | Description                                                   |
|-------------------------------|--------|-----------|---------------------------------------------------------------|
| `AzDOEnvironmentName`         | string | ✓         | Azure DevOps environment for approval gates                   |
| `BackendConfig`               | object | Optional  | Terraform backend configuration (key-value pairs)             |
| `AzureServiceConnection`      | string | Optional  | Azure service connection for authentication                   |
| `EnvironmentVariableMappings` | object | Optional  | Environment variables for Terraform (e.g., `TF_LOG`)          |
| `VariableFiles`               | list   | Optional  | List of `.tfvars` files to use (paths relative to artifact)   |
| `OutputVariables`             | list   | Optional  | Terraform output names to export as pipeline variables        |
| `ConfigSources`               | list   | Optional  | Configuration sources (currently `Type: KeyVault`, preferred) |
| `KeyVaultConfig`              | object | Optional  | Azure Key Vault configuration for retrieving secrets          |
| `JobsVariableMappings`        | object | Optional  | Variable groups or inline variables to inject                 |

`KeyVaultConfig` and `ConfigSources` are mutually exclusive. Use `ConfigSources` for new configurations.

---

## Examples

### Plan with Environment Variables

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Plan
      EnvironmentName: staging
      TerraformVersion: '1.5.0'
      TerraformDeploymentConfig:
        AzDOEnvironmentName: staging-environment
        BackendConfig:
          resource_group_name: rg-state-staging
          storage_account_name: ststatestaging
          container_name: tfstate
          key: staging.tfstate
        AzureServiceConnection: AzureServiceConnection-Staging
        EnvironmentVariableMappings:
          TF_LOG: DEBUG
          ARM_SKIP_PROVIDER_REGISTRATION: 'true'
        VariableFiles:
          - config/common.tfvars
          - config/staging.tfvars
```

### Apply with Variable Groups

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Apply
      EnvironmentName: prod
      DependsOn:
        - ApprovalJob
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: ststateprod
          container_name: tfstate
          key: prod.tfstate
        AzureServiceConnection: AzureServiceConnection-Prod
        JobsVariableMappings:
          - group: ProductionSecrets
        VariableFiles:
          - config/common.tfvars
          - config/prod.tfvars
        OutputVariables:
          - resource_group_id
          - app_service_url
```

### Apply with Key Vault (ConfigSources)

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Apply
      EnvironmentName: prod
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        AzureServiceConnection: AzureServiceConnection-Prod
        ConfigSources:
          - Type: KeyVault
            Name: kv-prod-secrets
            ServiceConnection: AzureServiceConnection-Prod
            SecretsFilter: '*'
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: ststateprod
          container_name: tfstate
          key: prod.tfstate
        VariableFiles:
          - config/prod.tfvars
        OutputVariables:
          - app_service_hostname
```

### Apply with Key Vault (Legacy)

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Apply
      EnvironmentName: prod
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        AzureServiceConnection: AzureServiceConnection-Prod
        KeyVaultConfig:
          ServiceConnection: AzureServiceConnection-Prod
          Name: kv-prod-secrets
          SecretsFilter: '*'
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: ststateprod
          container_name: tfstate
          key: prod.tfstate
        VariableFiles:
          - config/prod.tfvars
        OutputVariables:
          - app_service_hostname
```

---

## Output Variables

When `OutputVariables` are configured, Terraform outputs are exported as pipeline variables available to:

- later jobs in the same stage
- jobs in later stages

Same stage syntax:

```yaml
variables:
  - name: ResourceGroupName
    value: $[ dependencies.TerraformDeployApply_TerraformArtifact.outputs['TerraformDeployApply_TerraformArtifact.TerraformExportOutputsVariables.resource_group_name'] ]
```

Later stage syntax:

```yaml
variables:
  - name: ResourceGroupName
    value: $[ stageDependencies.Deploy_prod_Terraform.TerraformDeployApply_TerraformArtifact.outputs['TerraformDeployApply_TerraformArtifact.TerraformExportOutputsVariables.resource_group_name'] ]
```

Replace:

- `Deploy_prod_Terraform` with your stage name
- `dependencies` (same stage) or `stageDependencies` (cross-stage), depending on where you consume the variable
- if using a non-default `TerraformArtifactName`, replace `TerraformArtifact` in `TerraformDeployApply_TerraformArtifact` with your artifact name
- `resource_group_name` with your output variable name

---

## Troubleshooting

### Backend Initialization Fails

**Cause**: Backend configuration is missing or incorrect.

**Check**:

- ✓ Verify storage account and container exist in Azure
- ✓ Ensure service connection has proper permissions
- ✓ Check backend configuration keys are correct

**Solution**: Fix backend configuration or hardcode it in Terraform files.

### Plan Shows No Changes

**Expected behavior**: When no infrastructure changes are needed, plan succeeds with no changes. This is normal.

**If unexpected**:

- ✓ Verify Terraform files are correct
- ✓ Check variable files are being applied
- ✓ Verify existing state matches your infrastructure

### Output Variables Not Available

**Cause**: Output variables only available after Apply in the correct context.

**Solution**:

- Ensure `TerraformDeployMode` is set to `Apply` (not `Plan`)
- Use correct variable reference syntax with stage/job dependencies
- Verify output names match Terraform output definitions

### Artifact Download Fails

**Cause**: Artifact from build job not found.

**Check**:

- ✓ Verify build job succeeded and published artifact
- ✓ Ensure `TerraformArtifactName` matches artifact name from build
- ✓ Check job dependencies include build job

---

## Live Examples

View working test examples in the repository:

- **Plan Mode**: [`tests/jobs/terraform_deploy/plan_basic_test.yml`](../../../tests/jobs/terraform_deploy/plan_basic_test.yml)
- **Plan with Verification Mode**: [`tests/jobs/terraform_deploy/plan_with_verify_mode_test.yml`](../../../tests/jobs/terraform_deploy/plan_with_verify_mode_test.yml)
- **Plan with Multiple Mappings**: [`tests/jobs/terraform_deploy/plan_with_multiple_mappings_test.yml`](../../../tests/jobs/terraform_deploy/plan_with_multiple_mappings_test.yml)
- **Plan + Apply Sequence**: [`tests/jobs/terraform_deploy/plan_apply_basic_test.yml`](../../../tests/jobs/terraform_deploy/plan_apply_basic_test.yml)
- **Apply Mode**: [`tests/jobs/terraform_deploy/apply_basic_test.yml`](../../../tests/jobs/terraform_deploy/apply_basic_test.yml)
- **Apply with Legacy Key Vault (KeyVaultConfig)**: [`tests/jobs/terraform_deploy/apply_with_legacy_key_vault_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_legacy_key_vault_test.yml)
- **Apply with One Key Vault (ConfigSources)**: [`tests/jobs/terraform_deploy/apply_with_configsources_one_key_vault_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_configsources_one_key_vault_test.yml)
- **Apply with Two Key Vaults (ConfigSources)**: [`tests/jobs/terraform_deploy/apply_with_configsources_two_key_vault_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_configsources_two_key_vault_test.yml)
- **Apply with Multiple Mappings**: [`tests/jobs/terraform_deploy/apply_with_multiple_mappings_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_multiple_mappings_test.yml)
- **Apply with Outputs (Same Stage)**: [`tests/jobs/terraform_deploy/apply_with_outputs_same_stage_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_outputs_same_stage_test.yml)
- **Apply with Outputs (Future Stage)**: [`tests/jobs/terraform_deploy/apply_with_outputs_future_stage_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_outputs_future_stage_test.yml)
- **Double Plan Execution**: [`tests/jobs/terraform_deploy/double_plan_basic_test.yml`](../../../tests/jobs/terraform_deploy/double_plan_basic_test.yml)
- **Double Apply Execution**: [`tests/jobs/terraform_deploy/double_apply_basic_test.yml`](../../../tests/jobs/terraform_deploy/double_apply_basic_test.yml)

---

## Best Practices

- **Separate concerns** – Plan and apply in separate jobs for better control
- **Export outputs** – Extract Terraform outputs for use in subsequent steps
- **Environment variables** – Use `EnvironmentVariableMappings` for Terraform-specific settings
- **Approval gates** – Use AzDO environments for approval requirements

---

## Related Links

- Terraform Gated Deployment Job – orchestrates plan, verify, and apply using this job
- Terraform Build Job – creates the artifact this job downloads
- Terraform Pipeline – complete pipeline template using these jobs
- [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends)
