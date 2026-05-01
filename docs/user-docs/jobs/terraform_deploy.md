# Terraform Deploy Job

A comprehensive job template for individual Terraform deployment steps. This job handles either the plan phase (showing what will change) or the apply phase (provisioning infrastructure), with support for environment variables, Key Vault integration, and output variable extraction.

---

## When to Use

Use this job template when you need to:

- **Create Terraform plans** – Show infrastructure changes without applying
- **Apply Terraform changes** – Provision or modify infrastructure
- **Integrate with custom workflows** – Build custom deployment orchestration
- **Advanced deployments** – Have fine-grained control over plan and apply steps

**Note**: For typical usage, consider using [Terraform Gated Deployment Job](./terraform_gated_deployment.md) which combines plan, verification, and apply into a single orchestrated workflow.

---

## What This Job Does

### Plan Mode

1. Downloads Terraform artifact from build stage
2. Runs `terraform init` with backend configuration
3. Runs `terraform plan` to show what will change
4. Saves plan output to JSON for analysis
5. Exports outputs as pipeline variables (if configured)

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
        RunMode: PlanVerifyApply
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
        RunMode: ApplyOnly
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

| Property                      | Type   | Required                          | Description                                                 |
|-------------------------------|--------|-----------------------------------|-------------------------------------------------------------|
| `AzDOEnvironmentName`         | string | ✓                                 | Azure DevOps environment for approval gates                 |
| `RunMode`                     | string | ✓                                 | One of: `PlanVerifyApply`, `PlanOnly`, `ApplyOnly`          |
| `VerificationMode`            | string | When RunMode is `PlanVerifyApply` | One of: `VerifyOnDestroy`, `VerifyOnAny`, `VerifyDisabled`  |
| `BackendConfig`               | object | Optional                          | Terraform backend configuration (key-value pairs)           |
| `AzureServiceConnection`      | string | Optional                          | Azure service connection for authentication                 |
| `EnvironmentVariableMappings` | object | Optional                          | Environment variables for Terraform (e.g., `TF_LOG`)        |
| `VariableFiles`               | list   | Optional                          | List of `.tfvars` files to use (paths relative to artifact) |
| `OutputVariables`             | list   | Optional                          | Terraform output names to export as pipeline variables      |
| `KeyVaultConfig`              | object | Optional                          | Azure Key Vault configuration for retrieving secrets        |
| `JobsVariableMappings`        | object | Optional                          | Variable groups or inline variables to inject               |

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
        RunMode: PlanVerifyApply
        VerificationMode: VerifyOnDestroy
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
        RunMode: ApplyOnly
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

### Apply with Key Vault

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Apply
      EnvironmentName: prod
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        RunMode: ApplyOnly
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

When `OutputVariables` are configured, Terraform outputs are exported as pipeline variables available to subsequent jobs:

```yaml
variables:
  - name: ResourceGroupName
    value: $[ stageDependencies.Deploy_prod_Infrastructure.TerraformDeployApply_TerraformArtifact.outputs['TerraformDeployApply_TerraformArtifact.TerraformExportOutputsVariables.resource_group_name'] ]
```

Replace:
- `Deploy_prod_Infrastructure` with your stage name
- `TerraformDeployApply_TerraformArtifact` with the actual job name
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
- Ensure `RunMode` includes apply (not `PlanOnly`)
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

- **Plan Mode**: [tests/jobs/terraform_deploy/plan_basic_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/jobs/terraform_deploy/plan_basic_test.yml)
- **Apply Mode**: [tests/jobs/terraform_deploy/apply_basic_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/jobs/terraform_deploy/apply_basic_test.yml)
- **With Output Variables**: [tests/jobs/terraform_deploy/apply_with_outputs_same_stage_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/jobs/terraform_deploy/apply_with_outputs_same_stage_test.yml)
- **With Multiple Mappings**: [tests/jobs/terraform_deploy/plan_with_multiple_mappings_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/jobs/terraform_deploy/plan_with_multiple_mappings_test.yml)

---

## Best Practices

- **Use with Gated Deployment** – Consider using [Terraform Gated Deployment Job](./terraform_gated_deployment.md) for orchestrated workflows
- **Separate concerns** – Plan and apply in separate jobs for better control
- **Export outputs** – Extract Terraform outputs for use in subsequent steps
- **Environment variables** – Use `EnvironmentVariableMappings` for Terraform-specific settings
- **Approval gates** – Use AzDO environments for approval requirements

---

## See Also

- [Terraform Gated Deployment Job](./terraform_gated_deployment.md) – Orchestrates plan, verify, and apply
- [Terraform Build Job](./terraform_build.md) – Creates artifacts used by this job
- [Terraform Pipeline](../pipelines/terraform_pipeline.md) – Complete pipeline using these jobs
- [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends)


