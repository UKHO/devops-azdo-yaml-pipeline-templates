# Terraform Gated Deployment Job

An orchestration job template that coordinates a sophisticated deployment workflow with optional plan validation, manual approval, and conditional apply phases. This job intelligently routes between Plan-only, Plan→Verify→Apply, and Apply-only modes based on configuration.

## Overview

The Terraform Gated Deployment Job:

- Orchestrates multiple deployment phases based on `RunMode` configuration
- Executes `terraform plan` in Plan phase (when configured)
- Inserts an optional manual verification gate with change verification indicators
- Automatically routes to apply phase based on plan verification results
- Applies infrastructure changes when approved
- Manages job dependencies and conditional execution automatically
- Provides intelligent change detection to determine if manual verification is needed

## Important Notices

### Change Detection Intelligence

When using `PlanVerifyApply` mode with verification enabled, the job automatically evaluates plan changes:

- Changes requiring destruction trigger manual verification if configured with `VerifyOnDestroy`
- Changes requiring creation trigger manual verification if configured with `VerifyOnAny`
- Deployments bypass manual verification if configured with `VerifyDisabled` (not recommended for production)

Manual verification is inserted dynamically — it only appears if changes warrant approval.

### Idempotent Job Names

The job automatically generates unique job names based on deployment artifact names:

- Plan job: `TerraformDeployPlan_<ArtifactName>`
- Verification job: `ManualVerification_<ArtifactName>`
- Apply job: `TerraformDeployApply_<ArtifactName>`

This allows multiple independent deployments in the same pipeline without job name conflicts.

### Plan Preservation

Note that plans generated during the Plan phase are **not** preserved between Plan and Apply phases. The Apply phase re-evaluates the current infrastructure state. For audit compliance, capture and store plan outputs during the Plan phase.

### Deployment Environments

Each phase (Plan, Apply) is tied to an Azure DevOps Environment. Ensure the environment exists and has appropriate approvers configured for your deployment strategy.

## Basic Usage

### Plan-Only Mode

Preview infrastructure changes without applying:

```yaml
- template: jobs/terraform_gated_deployment.yml@AzDOPipelineTemplates
  parameters:
    EnvironmentName: 'dev'
    TerraformDeploymentConfig:
      AzDOEnvironmentName: 'dev-environment'
      AzureServiceConnection: 'Pipeline-dev'
      RunMode: PlanOnly
      BackendConfig:
        - Key: resource_group_name
          Value: 'my-rg'
        - Key: storage_account_name
          Value: 'mytfsa'
        - Key: container_name
          Value: 'tfstate'
        - Key: key
          Value: 'dev.terraform.tfstate'
      VariableFiles:
        - 'config/dev.tfvars'
```

### Plan-Verify-Apply with Destruction Verification

Full workflow with manual gate that requires approval for destructive changes:

```yaml
- template: jobs/terraform_gated_deployment.yml@AzDOPipelineTemplates
  parameters:
    EnvironmentName: 'prod'
    TerraformDeploymentConfig:
      AzDOEnvironmentName: 'prod-environment'
      AzureServiceConnection: 'Pipeline-prod'
      RunMode: PlanVerifyApply
      VerificationMode: VerifyOnDestroy
      BackendConfig:
        resource_group_name: 'my-rg'
        storage_account_name: 'mytfsa'
        container_name: 'tfstate'
        key: 'dev.terraform.tfstate'
      VariableFiles:
        - 'config/dev.tfvars'
```

### Apply-Only Mode

Deploy without planning (for environments already planned):

```yaml
- template: jobs/terraform_gated_deployment.yml@AzDOPipelineTemplates
  parameters:
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
        - 'config/dev.tfvars'
```

## Full Parameter Table

### Core Parameters

| Parameter Name              | Type   | Required | Default                 | Description                                                                                                                                                                                                              |
|-----------------------------|--------|----------|-------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `EnvironmentName`           | string | **Yes**  | —                       | User-friendly environment name (e.g., 'dev', 'staging', 'production'). Used for identification.                                                                                                                          |
| `TerraformDeploymentConfig` | object | **Yes**  | —                       | Complex configuration object controlling deployment behavior, backend, variables, and verification. See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md). |
| `TerraformArtifactName`     | string | No       | `'TerraformArtifact'`   | Name of the artifact published by the build job. Must match the artifact name from `terraform_build` job.                                                                                                                |
| `TerraformVersion`          | string | No       | `'1.14.0'`              | Version of Terraform CLI to install and use on deployment agents.                                                                                                                                                        |
| `DependsOn`                 | object | No       | `[]`                    | List of job names this orchestration depends on (e.g., `['TerraformBuild_TerraformArtifact']`).                                                                                                                          |
| `Condition`                 | string | No       | `succeeded()`           | Condition expression controlling whether this orchestration runs.                                                                                                                                                        |
| `CheckoutAlias`             | string | No       | `AzDOPipelineTemplates` | Repository checkout alias for template repository (internal use, leave default).                                                                                                                                         |

### TerraformDeploymentConfig Parameters

See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md) for complete structure.

**Essential fields:**

- `AzDOEnvironmentName` (required) — Azure DevOps Environment name
- `RunMode` (required) — One of: `PlanOnly`, `ApplyOnly`, `PlanVerifyApply`
- `BackendConfig` (required) — List of backend key-value pairs for state management

**Conditionally required:**

- `VerificationMode` (required when `RunMode` is `PlanVerifyApply`) — One of: `VerifyOnDestroy`, `VerifyOnAny`,
  `VerifyDisabled`

**Optional fields:**

- `AzureServiceConnection` — Service connection for Azure provider
- `KeyVaultConfig` — Azure Key Vault integration
- `EnvironmentVariableMappings` — Environment variables for Terraform
- `VariableFiles` — List of `.tfvars` files to apply
- `OutputVariables` — Terraform output variables to export

## Advanced Usage

### Multi-Environment Deployment Pipeline

Use the same orchestration template for multiple environments with different verification modes:

```yaml
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml@AzDOPipelineTemplates
        parameters:
          RelativePathToTerraformFiles: 'infra/terraform'
          ArtifactName: 'TerraformArtifact'

  - stage: DeployDev
    dependsOn: Build
    jobs:
      - template: jobs/terraform_gated_deployment.yml@AzDOPipelineTemplates
        parameters:
          DependsOn:
            - TerraformBuild_TerraformArtifact
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
              - 'config/dev.tfvars'

   - stage: DeployProd
    dependsOn: DeployDev
    jobs:
      - template: jobs/terraform_gated_deployment.yml@AzDOPipelineTemplates
        parameters:
          DependsOn:
            - TerraformBuild_TerraformArtifact
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
              - 'config/prod.tfvars'
```

### With Azure Key Vault and Output Variables

```yaml
- template: jobs/terraform_gated_deployment.yml@AzDOPipelineTemplates
  parameters:
    EnvironmentName: prod
    TerraformDeploymentConfig:
      AzDOEnvironmentName: prod-environment
      AzureServiceConnection: Pipeline-prod
      RunMode: PlanVerifyApply
      VerificationMode: VerifyOnAny
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
        SecretsFilter: 'db-password,api-key'
      EnvironmentVariableMappings:
        TF_VAR_db_password: '$(db-password)'
        TF_VAR_api_key: '$(api-key)'
      OutputVariables:
        - app_endpoint
        - database_url
        - storage_connection_string
```

## Deployment Modes Explained

For detailed information about deployment modes and verification strategies, see [Deployment Modes and Verification Strategies](../deployment_modes_and_verification.md).

### Quick Reference

**PlanOnly Mode**
- Generated jobs: `TerraformDeployPlan_<ArtifactName>` (Plan job only)
- Use for: Preview-only deployments without applying changes
- Configuration: `RunMode: PlanOnly`

**ApplyOnly Mode**
- Generated jobs: `TerraformDeployApply_<ArtifactName>` (Apply job only)
- Use for: Rapid deployments to development environments without planning
- Configuration: `RunMode: ApplyOnly`

**PlanVerifyApply Mode**
- Generated jobs: Plan job → Optional verification gate → Apply job
- Use for: Production deployments requiring approval
- Configuration: `RunMode: PlanVerifyApply` with `VerificationMode` (VerifyOnDestroy, VerifyOnAny, or VerifyDisabled)

## Verification Modes

**VerifyOnDestroy** — Manual verification required only if plan includes resource destruction

**VerifyOnAny** — Manual verification required if plan includes any changes (creation, modification, or destruction)

**VerifyDisabled** — Skip manual verification entirely (not recommended for production)

## Job Dependency and Ordering

The orchestration job automatically manages job ordering:

1. **Plan job always runs first** (when `RunMode` includes Plan)
2. **Verification job inserts between Plan and Apply** (only when changes warrant it)
3. **Apply job runs last** (when `RunMode` includes Apply, and conditions are met)

Dependencies are automatically set up so jobs wait for their predecessors to complete successfully.

## Common Patterns

### Branch-Based Deployment Strategy

```yaml
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml@AzDOPipelineTemplates
        parameters:
          RelativePathToTerraformFiles: 'infra'
          ArtifactName: 'Terraform'

  - stage: Verify
    jobs:
      - template: jobs/terraform_gated_deployment.yml@AzDOPipelineTemplates
        parameters:
          Condition: eq(variables['Build.SourceBranch'], 'refs/heads/develop')
          EnvironmentName: dev
          TerraformDeploymentConfig:
            AzDOEnvironmentName: dev-environment
            AzureServiceConnection: Pipeline-dev
            RunMode: PlanOnly
            # ... backend and variables config ...

  - stage: Deploy
    dependsOn: Verify
    jobs:
      - template: jobs/terraform_gated_deployment.yml@AzDOPipelineTemplates
        parameters:
          Condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
          EnvironmentName: production
          TerraformDeploymentConfig:
            AzDOEnvironmentName: prod-environment
            AzureServiceConnection: Pipeline-prod
            RunMode: PlanVerifyApply
            VerificationMode: VerifyOnDestroy
            # ... backend and variables config ...
```

## Common Issues

### Verification Gate Not Appearing

If the manual verification gate doesn't appear when expected:

- Check that `RunMode` is set to `PlanVerifyApply`
- Verify `VerificationMode` is set to `VerifyOnDestroy` or `VerifyOnAny`
- Plan output may show no detectible changes (check terraform plan logs)
- Environment approvers may be configured incorrectly

### Apply Job Not Running

If the apply job doesn't execute after verification:

- Check the verification gate was actually approved (not just timed out)
- Verify job dependencies are correctly set up in the generated jobs
- Review Azure DevOps job logs for condition evaluation failures
- Check that `RunMode` includes apply (`PlanVerifyApply` or `ApplyOnly`)

### State Conflicts

If you see state lock timeouts between Plan and Apply:

- Ensure sufficient time between Plan and Apply phases
- Avoid running multiple pipelines to the same environment concurrently
- Check backend configuration for correctness

## Related Templates

- [**terraform_build_job.md**](terraform_build_job.md) — Build and validate Terraform before deployment
- [**terraform_deploy_job.md**](terraform_deploy_job.md) — Single-phase plan or apply job (lower-level component)
- [**manual_verification_job.md**](manual_verification_job.md) — Manual verification gate (used internally)
- [**Terraform Pipeline**](../pipelines/terraform_pipeline.md) — Complete end-to-end infrastructure deployment pipeline

## Related Documentation

- [**TerraformDeploymentConfig Documentation**](../../definition_docs/terraform_pipeline/terraform_deployment_config.md) — Complete configuration object reference

