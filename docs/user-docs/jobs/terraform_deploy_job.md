# Terraform Deploy Job

A job template that deploys Terraform infrastructure by executing either `terraform plan` (preview changes) or `terraform apply` (deploy changes). This job handles Azure backend configuration, variable injection, Azure Key Vault integration, and Terraform output capture.

## Overview

The Terraform Deploy Job:

- Downloads the Terraform artifact created by the build job
- Initializes Terraform with backend configuration for state management
- Executes either `terraform plan` or `terraform apply` depending on deployment mode
- Optionally verifies plan changes before applying
- Integrates with Azure Key Vault to retrieve deployment secrets
- Captures and exports Terraform output variables for downstream jobs
- Supports custom environment variables and Azure service connections

## Important Notices

### State File Management

The job uses backend configuration to connect to Azure blob storage for Terraform state. The backend must be properly configured in `TerraformDeploymentConfig.BackendConfig` for the job to function correctly. Misconfigured backend settings will cause the job to fail.

### Apply Auto-Approval

When using `Apply` mode, `terraform apply` runs with `-auto-approve` to enable fully automated deployments. This requires that your Terraform configuration is thoroughly validated and tested before applying to production environments.

### Plan Artifacts

Plans generated during `Plan` mode are stored locally but are **not** preserved between Plan and Apply stages. If you need to audit the exact plan that was applied, capture plan outputs during the Plan stage before the Apply stage executes.

### Deployment Environments

The job is tied to an Azure DevOps Environment (specified in `TerraformDeploymentConfig.AzDOEnvironmentName`). Ensure the environment exists in your Azure DevOps project and has appropriate approvers configured for production deployments.

## Basic Usage

### Plan Mode (Preview Only)

```yaml
- template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
  parameters:
    TerraformDeployMode: Plan
    TerraformArtifactName: 'TerraformArtifact'
    EnvironmentName: 'dev'
    TerraformDeploymentConfig:
      AzDOEnvironmentName: 'dev-environment'
      AzureServiceConnection: 'Pipeline-dev'
      RunMode: PlanOnly
      BackendConfig:
        resource_group_name: 'my-rg'
        storage_account_name: 'mytfsa'
        container_name: 'tfstate'
        key: 'dev.terraform.tfstate'
      VariableFiles:
        - 'config/common.tfvars'
        - 'config/dev.tfvars'
```

### Apply Mode (Deploy Infrastructure)

```yaml
- template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
  parameters:
    TerraformDeployMode: Apply
    TerraformArtifactName: 'TerraformArtifact'
    EnvironmentName: 'dev'
    TerraformDeploymentConfig:
      AzDOEnvironmentName: 'dev-environment'
      AzureServiceConnection: 'Pipeline-dev'
      RunMode: ApplyOnly
      BackendConfig:
        resource_group_name: 'my-rg'
        storage_account_name: 'mytfsa'
        container_name: 'tfstate'
        key: 'dev.terraform.tfstate'
      VariableFiles:
        - 'config/common.tfvars'
        - 'config/dev.tfvars'
      OutputVariables:
        - app_service_url
```

### Minimal Example with Service Connection

```yaml
- template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
  parameters:
    TerraformDeployMode: Plan
    EnvironmentName: staging
    TerraformDeploymentConfig:
      AzDOEnvironmentName: staging-environment
      AzureServiceConnection: Pipeline-staging
      RunMode: PlanOnly
      BackendConfig:
        resource_group_name: 'staging-rg'
        storage_account_name: 'stagingtfsa'
        container_name: 'tfstate'
        key: 'staging.terraform.tfstate'
      VariableFiles:
        - 'config/staging.tfvars'
```

## Full Parameter Table

### Core Parameters

| Parameter Name              | Type   | Required | Default                 | Description                                                                                                                                                                                                                     |
|-----------------------------|--------|----------|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `TerraformDeployMode`       | string | No       | `Plan`                  | Deployment mode: `Plan` (preview changes) or `Apply` (deploy infrastructure).                                                                                                                                                   |
| `TerraformVersion`          | string | No       | `'1.14.0'`              | Version of Terraform CLI to install and use on the deployment agent.                                                                                                                                                            |
| `TerraformArtifactName`     | string | No       | `'TerraformArtifact'`   | Name of the artifact published by the build job. Must match the artifact name from `terraform_build` job.                                                                                                                       |
| `EnvironmentName`           | string | **Yes**  | —                       | User-friendly name of the environment (e.g., 'dev', 'staging', 'production'). Used for identification.                                                                                                                          |
| `TerraformDeploymentConfig` | object | **Yes**  | —                       | Complex configuration object containing backend, variables, Azure integration, and deployment settings. See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md). |
| `DependsOn`                 | object | No       | `[]`                    | List of job names this deployment depends on (e.g., `['TerraformBuild_TerraformArtifact']`).                                                                                                                                    |
| `Condition`                 | string | No       | `succeeded()`           | Condition expression controlling whether this job runs (e.g., `eq(variables['Build.SourceBranch'], 'refs/heads/main')`).                                                                                                        |
| `CheckoutAlias`             | string | No       | `AzDOPipelineTemplates` | Repository checkout alias for the template repository (internal use, leave default).                                                                                                                                            |

### TerraformDeploymentConfig Parameters

See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md) for
detailed configuration structure.

**Essential fields:**

- `AzDOEnvironmentName` (required) — Azure DevOps Environment name
- `RunMode` (required) — One of: `PlanOnly`, `ApplyOnly`, `PlanVerifyApply`
- `BackendConfig` (required) — List of backend key-value pairs for state management
- `VariableFiles` (optional) — List of `.tfvars` file paths to apply

**Optional fields:**

- `AzureServiceConnection` — Service connection for Azure provider
- `KeyVaultConfig` — Azure Key Vault integration for secrets
- `EnvironmentVariableMappings` — Environment variables for Terraform
- `VerificationMode` — Verification strategy for plan changes
- `OutputVariables` — List of Terraform output variables to export

## Advanced Usage

### With Azure Key Vault Integration

```yaml
- template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
  parameters:
    TerraformDeployMode: Apply
    EnvironmentName: prod
    TerraformDeploymentConfig:
      AzDOEnvironmentName: prod-environment
      AzureServiceConnection: Pipeline-prod
      RunMode: ApplyOnly
      BackendConfig:
        resource_group_name: 'prod-rg'
        storage_account_name: 'prodtfsa'
        container_name: 'tfstate'
        key: 'prod.terraform.tfstate'
      VariableFiles:
        - 'config/prod.tfvars'
      KeyVaultConfig:
        ServiceConnection: 'Pipeline-prod'
        Name: 'prod-kv'
        SecretsFilter: 'db-password,api-key'
      EnvironmentVariableMappings:
        TF_VAR_db_password: '$(db-password)'
        TF_VAR_api_key: '$(api-key)'
```

### Exporting Terraform Outputs

```yaml
- template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
  parameters:
    TerraformDeployMode: Apply
    EnvironmentName: dev
    TerraformDeploymentConfig:
      AzDOEnvironmentName: dev-environment
      AzureServiceConnection: Pipeline-dev
      RunMode: ApplyOnly
      BackendConfig:
        resource_group_name: 'my-rg'
        storage_account_name: 'mytfsa'
        container_name: 'tfstate'
        key: 'dev.terraform.tfstate'
      VariableFiles:
        - 'config/dev.tfvars'
      OutputVariables:
        - resource_group_id
        - storage_account_url
        - app_service_hostname
```

The exported variables will be available as pipeline variables in the format: `$(TerraformExportOutputs_<OUTPUT_NAME>)` (e.g., `$(TerraformExportOutputs_app_service_hostname)`)

### Environment Variables for Terraform

```yaml
- template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
  parameters:
    TerraformDeployMode: Apply
    EnvironmentName: dev
    TerraformDeploymentConfig:
      AzDOEnvironmentName: dev-environment
      AzureServiceConnection: Pipeline-dev
      RunMode: ApplyOnly
      BackendConfig:
        resource_group_name: 'my-rg'
        storage_account_name: 'mytfsa'
        container_name: 'tfstate'
        key: 'dev.terraform.tfstate'
      VariableFiles:
        - 'config/dev.tfvars'
      EnvironmentVariableMappings:
        TF_LOG: DEBUG
        TF_LOG_PATH: '$(Build.ArtifactStagingDirectory)/terraform.log'
```

### With Job Dependencies and Conditions

```yaml
- template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
  parameters:
    TerraformDeployMode: Plan
    EnvironmentName: dev
    DependsOn:
      - TerraformBuild_TerraformArtifact
      - RunTests
    Condition: and(succeeded('TerraformBuild_TerraformArtifact'), succeeded('RunTests'))
    TerraformDeploymentConfig:
      AzDOEnvironmentName: dev-environment
      AzureServiceConnection: Pipeline-dev
      RunMode: PlanOnly
      BackendConfig:
        resource_group_name: 'my-rg'
        storage_account_name: 'mytfsa'
        container_name: 'tfstate'
        key: 'dev.terraform.tfstate'
      VariableFiles:
        - 'config/dev.tfvars'
```

## Job Execution Flow

### Plan Mode Execution

1. Checkout template repository
2. Download Terraform artifact
3. Install Terraform CLI
4. Download secrets from Azure Key Vault (if configured)
5. Run `terraform init` with backend configuration
6. Run `terraform plan` with variable files and environment variables
7. Verify plan changes (if `VerificationMode` is specified)
8. Store plan file and outputs

### Apply Mode Execution

1. Checkout template repository
2. Download Terraform artifact
3. Install Terraform CLI
4. Download secrets from Azure Key Vault (if configured)
5. Run `terraform init` with backend configuration
6. Run `terraform apply` with auto-approval
7. Capture Terraform outputs (if `OutputVariables` specified)
8. Export outputs as pipeline variables for downstream use

## Configuration Examples

### Simple Development Pipeline

```yaml
- template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
  parameters:
    TerraformDeployMode: Apply
    EnvironmentName: dev
    TerraformDeploymentConfig:
      AzDOEnvironmentName: dev-environment
      AzureServiceConnection: Pipeline-dev
      RunMode: ApplyOnly
      BackendConfig:
        resource_group_name: 'dev-rg'
        storage_account_name: 'devtfsa'
        container_name: 'tfstate'
        key: 'dev.tfstate'
      VariableFiles:
        - 'config/common.tfvars'
        - 'config/dev.tfvars'
```

### Production with Verification and Key Vault

```yaml
- template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
  parameters:
    TerraformDeployMode: Plan
    EnvironmentName: production
    TerraformDeploymentConfig:
      AzDOEnvironmentName: prod-environment
      AzureServiceConnection: Pipeline-prod
      RunMode: PlanVerifyApply
      VerificationMode: VerifyOnDestroy
      BackendConfig:
        resource_group_name: 'prod-rg'
        storage_account_name: 'prodtfsa'
        container_name: 'tfstate'
        key: 'prod.tfstate'
      VariableFiles:
        - 'config/common.tfvars'
        - 'config/prod.tfvars'
      KeyVaultConfig:
        ServiceConnection: Pipeline-prod
        Name: prod-kv
        SecretsFilter: '*'
      OutputVariables:
        - load_balancer_ip
        - database_endpoint
```