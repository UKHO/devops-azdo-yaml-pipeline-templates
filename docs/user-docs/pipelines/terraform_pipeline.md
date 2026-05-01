# Terraform Pipeline

A standardised infrastructure deployment pipeline template that uses terraform as the IaC tooling and Azure as the cloud provider. This pipeline will:

- Build/Validate/Package the terraform files
- Deploy the packaged terraform files to environments with optional [manual verification gates](terraform_pipeline_manual_verification.md)

---

## Important Setup Information

### Repository Resource Configuration

**Critical**: The pipeline requires access to this template repository during execution. You **must** define the repository resource with the name `AzDOPipelineTemplates` in your `azure-pipelines.yml` because the pipeline internally checks out this repository to access helper scripts during the deployment stage.

Example:
```yaml
resources:
  repositories:
    - repository: AzDOPipelineTemplates
      type: github
      endpoint: UKHO                    # Your GitHub service connection
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: refs/tags/v0.1.0             # Always use a specific version tag
```

See the [Basic Usage](#basic-usage) example below for the complete configuration.

### Agent Pool Considerations

The pipeline runs on the agent pool specified in your environment configuration (or defaults to Microsoft-hosted if not specified).

**Important considerations:**
- Ensure your chosen pool has internet access to download Terraform CLI
- For self-hosted agents, verify Terraform can be installed on the agent OS
- Use consistent pools for all stages to avoid unexpected behavior differences between build and deploy

### Limitations & Known Issues

#### Plan Generation and Reuse

The Terraform plan generated during the build/planning stage is evaluated during manual verification but is then discarded before the `terraform apply` runs in the deploy stage. This means infrastructure provisioned during apply may differ from what was reviewed in the plan if there are external changes between stages.

**Recommendation**: Use `VerificationMode: VerifyOnDestroy` during deployments to add an extra layer of safety for destructive changes.

## Basic Usage

### Prerequisites Checklist

Before implementing this pipeline, verify:

- ✓ You have a Git repository with Terraform files
- ✓ You have created an Azure Resource Manager service connection
- ✓ You have a GitHub service connection (for accessing template repository)
- ✓ You have an Azure storage account configured for Terraform state
- ✓ You have terraform files in your repository (e.g., `infra/`, `terraform/`)

### Example of Basic Usage

This shows a minimal working example with a single development environment:

```yaml
# azure-pipelines.yml
resources:
  repositories:
    - repository: AzDOPipelineTemplates                 # REQUIRED: Must be named 'AzDOPipelineTemplates'
      type: github
      endpoint: UKHO                                    # Your GitHub service connection name
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: refs/tags/v0.1.0                             # Always use a specific version tag - see https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/releases

trigger:
  branches:
    include:
      - main

extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: infra/webapp          # Path to your terraform files relative to repo root
    TerraformVersion: '1.5.0'                           # Terraform version to use (or 'latest')
    EnvironmentConfigs:
      - Name: dev                                       # Environment name
        Stage:
          DependsOn: Terraform_Build                    # Depends on the build stage
          Condition: succeeded()                        # Execute if build succeeded
        TerraformDeploymentConfig:
          AzDOEnvironmentName: dev-environment          # AzDO Environment for approvals
          AzureServiceConnection: Pipeline-dev          # Azure service connection name
          BackendConfig:                                # Terraform backend configuration
            resource_group_name: m-project-rg
            storage_account_name: projecttfsa
            container_name: tfstate
            key: dev.terraform.tfstate
          RunMode: PlanVerifyApply                      # Plan, verify, then apply
          VerificationMode: VerifyOnDestroy             # Only gate on destructive changes
          VariableFiles:                                # Terraform variable files
            - config/common.tfvars
            - config/dev.tfvars
          OutputVariables:                              # Terraform outputs to export
            - random_number
            - random_string
```

### What Happens

With this configuration, the pipeline will:

1. **Build Stage** (`Terraform_Build`)
   - Check out your repository
   - Install Terraform CLI version 1.5.0
   - Run `terraform init` (without backend to allow flexible backend config in deploy)
   - Run `terraform validate` to check syntax
   - Package terraform files as an artifact

2. **Deploy Stage** (`Deploy_dev_Infrastructure`)
   - Download terraform artifact
   - Run `terraform init` with the backend configuration
   - Run `terraform plan` to show what will change
   - If changes detected and `VerificationMode` is set, request manual approval
   - Run `terraform apply` to provision resources
   - Export specified outputs as pipeline variables

The infrastructure pipeline uses an `EnvironmentConfigs` parameter that contains a list of environment configurations. Each environment configuration has the following structure:

**For complete configuration documentation, see:**
- [EnvironmentConfig Documentation](../../definition_docs/terraform_pipeline/environment_config.md) - Complete environment configuration structure
- [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md) - Infrastructure-specific configuration details
- [AdditionalFilesToPackage Documentation](../../definition_docs/terraform_pipeline/additional_files_to_package.md) - Additional files to include in the terraform artifact

**Quick reference of required fields:**

| Field Path                                    | Type        | Description                                                                               |
|-----------------------------------------------|-------------|-------------------------------------------------------------------------------------------|
| Name                                          | string      | Unique environment name (e.g., 'dev', 'staging', 'production')                            |
| Stage.DependsOn                               | string/list | Stage dependencies (e.g., 'Terraform_Build' or list of stages)                            |
| Stage.Condition                               | string      | Stage execution condition (e.g., 'succeeded()')                                           |
| TerraformDeploymentConfig.AzDOEnvironmentName | string      | AzDO Environment name to associate the deployment jobs to                                 |
| TerraformDeploymentConfig.RunMode             | string      | Deployment mode: PlanVerifyApply, PlanOnly, or ApplyOnly                                  |
| TerraformDeploymentConfig.VerificationMode    | string      | Required when RunMode is PlanVerifyApply: VerifyOnDestroy, VerifyOnAny, or VerifyDisabled |

See the [developer documentation](../../definition_docs/terraform_pipeline/environment_config.md) for optional parameters and advanced configuration.

---

## Advanced Usage

### Multi-Environment Deployment

Deploy to multiple environments with stage dependencies:

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infrastructure/terraform'
    TerraformVersion: '1.6.0'
    EnvironmentConfigs:
      # Development Environment
      - Name: dev
        Stage:
          DependsOn: Terraform_Build
          Condition: succeeded()
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Dev
          AzDOEnvironmentName: development-environment
          BackendConfig:
            resource_group_name: rg-terraform-state-dev
            storage_account_name: sttfstatedev
            container_name: tfstate
            key: dev.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnDestroy
          VariableFiles:
            - config/common.tfvars
            - config/dev.tfvars

      # Production Environment (deploys after dev, only on main branch)
      - Name: production
        Stage:
          DependsOn: Deploy_dev_Infrastructure
          Condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Production
          AzDOEnvironmentName: production-environment
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

### Including Additional Files in the Terraform Artifact

Use `AdditionalFilesToPackage` to include additional files (beyond those in `RelativePathToTerraformFiles`) in the terraform artifact:

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infrastructure/terraform'
    AdditionalFilesToPackage:
      - SourceDirectory: 'config/shared'
        FilesPattern: '*.tfvars'
        TargetSubdirectoryName: 'shared-config'
      - SourceDirectory: 'scripts'
        FilesPattern: '**/*.ps1'
        TargetSubdirectoryName: 'scripts'
    TerraformVersion: '1.6.0'
    EnvironmentConfigs:
      - Name: dev
        Stage:
          DependsOn: Terraform_Build
          Condition: succeeded()
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Dev
          AzDOEnvironmentName: development-environment
          BackendConfig:
            resource_group_name: rg-terraform-state-dev
            storage_account_name: sttfstatedev
            container_name: tfstate
            key: dev.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnDestroy
          VariableFiles:
            - config/common.tfvars
            - config/dev.tfvars
```

This will:
1. Copy all `.tfvars` files from `config/shared/` into the artifact at `shared-config/`
2. Copy all PowerShell scripts from `scripts/` into the artifact at `scripts/`
3. Make these files available alongside the terraform files during deployment

### Injection Step to add required_version

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: infra/webapp
    TerraformVersion: '1.1.9'
    TerraformBuildInjectionSteps:
      - pwsh: |
          $path = "$(Pipeline.Workspace)/$(Build.Repository.Name)/infra/webapp/main.tf"
          $content = Get-Content $path
          $terraformStart = $content.IndexOf($($content | Where-Object { $_ -match "^terraform\s*{" }))
          if ($terraformStart -ge 0) {
            $insertIndex = $terraformStart + 1
            $content = $content[0..($insertIndex-1)] + '  required_version = "1.1.9"' + $content[$insertIndex..($content.Count-1)]
            Set-Content $path $content
          }
        displayName: "Injecting into terraform block 'required_version'"
    EnvironmentConfigs:
      - Name: dev
        Stage:
          DependsOn: Terraform_Build
          Condition: succeeded()
        TerraformDeploymentConfig:
          # ... infrastructure config ...
```

---

## Common Scenarios & Patterns

This section shows common implementation patterns you might want to use.

### Scenario 1: Development + Production Pipeline

Deploy to dev automatically, but require approval before deploying to production:

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infrastructure/terraform'
    TerraformVersion: '1.5.0'
    EnvironmentConfigs:
      # Development: Auto-deploy with verify-on-destroy only
      - Name: dev
        Stage:
          DependsOn: Terraform_Build
          Condition: succeeded()
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Dev
          AzDOEnvironmentName: development-environment
          BackendConfig:
            resource_group_name: rg-tf-state-dev
            storage_account_name: tfstatedev
            container_name: tfstate
            key: dev.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnDestroy          # Only gate on destructive changes
          VariableFiles:
            - config/common.tfvars
            - config/dev.tfvars

      # Production: Requires approval for any changes
      - Name: production
        Stage:
          DependsOn: Deploy_dev_Infrastructure       # Must deploy to dev first
          Condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Prod
          AzDOEnvironmentName: production-environment
          BackendConfig:
            resource_group_name: rg-tf-state-prod
            storage_account_name: tfstateprod
            container_name: tfstate
            key: prod.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnAny             # Always require approval
          VariableFiles:
            - config/common.tfvars
            - config/prod.tfvars
```

### Scenario 2: Plan-Only for Feature Branches

Enable plan-only validation on feature branches without deploying:

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infrastructure/terraform'
    TerraformVersion: '1.5.0'
    EnvironmentConfigs:
      - Name: precheck
        Stage:
          DependsOn: Terraform_Build
          Condition: and(succeeded(), not(eq(variables['Build.SourceBranch'], 'refs/heads/main')))
        TerraformDeploymentConfig:
          AzDOEnvironmentName: precheck-environment
          RunMode: PlanOnly                          # Only plan, don't apply
          VariableFiles:
            - config/common.tfvars
            - config/precheck.tfvars
```

### Scenario 3: Environment Variables & Key Vault

Use Azure Key Vault for secrets and environment-specific variables:

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infrastructure/terraform'
    TerraformVersion: '1.5.0'
    EnvironmentConfigs:
      - Name: production
        Stage:
          DependsOn: Terraform_Build
          Condition: succeeded()
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Prod
          AzDOEnvironmentName: production-environment
          BackendConfig:
            resource_group_name: rg-tf-state
            storage_account_name: tfstate
            container_name: tfstate
            key: prod.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnAny
          # Retrieve secrets from Key Vault
          KeyVaultConfig:
            ServiceConnection: AzureServiceConnection-Prod
            Name: kv-prod-secrets
            SecretsFilter: '*'
          # Environment variables for Terraform
          EnvironmentVariableMappings:
            TF_LOG: INFO                            # Enable debug logging
            ARM_SKIP_PROVIDER_REGISTRATION: 'true'
          # Variable groups from Azure DevOps
          JobsVariableMappings:
            - group: ProductionVariables
          VariableFiles:
            - config/common.tfvars
            - config/prod.tfvars
          OutputVariables:
            - resource_group_id
            - app_service_hostname
```

---

## Troubleshooting

### Repository Resource Not Found

**Error**: `Repository 'AzDOPipelineTemplates' not found`

**Cause**: The repository resource is not configured correctly or is missing from your `azure-pipelines.yml`.

**Solution**:
1. Ensure the repository resource is defined with the exact name `AzDOPipelineTemplates`
2. Verify the GitHub service connection exists in your Azure DevOps project
3. Check that the service connection has permission to access the repository

**Example**:
```yaml
resources:
  repositories:
    - repository: AzDOPipelineTemplates    # Must be exactly this name
      type: github
      endpoint: UKHO                        # Service connection must exist
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: refs/tags/v0.1.0
```

### Manual Verification Not Triggering

**Issue**: Manual verification gate doesn't appear even when changes are detected.

**Checks**:
- ✓ Verify `RunMode` is set to `PlanVerifyApply` (not `PlanOnly` or `ApplyOnly`)
- ✓ Verify `VerificationMode` is set to either `VerifyOnAny` or `VerifyOnDestroy` (not `VerifyDisabled`)
- ✓ Check the plan output in the deploy stage to ensure changes were actually detected
- ✓ Verify the AzDO Environment exists and has appropriate approvers configured
- ✓ Check pipeline logs for any error messages in the approval step

**If no changes detected**: This is expected behavior. When Terraform detects no changes:
- Plan job succeeds
- Manual verification is skipped
- Apply job is skipped
- Pipeline completes successfully

### Output Variables Not Available in Subsequent Stages

**Cause**: Output variables from Terraform are only available after the Apply job completes and are scoped to the deployment job. They are only exported when `RunMode` includes an apply operation (`PlanVerifyApply` or `ApplyOnly`, not `PlanOnly`).

**Solution**: To use Terraform output variables in subsequent stages or jobs:
1. Ensure the variables are listed in the `OutputVariables` property of your `TerraformDeploymentConfig`
2. Reference them using the correct dependency syntax:
   ```text
   stageDependencies.Deploy_{EnvironmentName}_Infrastructure.TerraformDeployApply_TerraformArtifact.outputs['TerraformDeployApply_TerraformArtifact.TerraformExportOutputsVariables.{variableName}']
   ```
   where:
   - `{EnvironmentName}` is replaced with your environment name (e.g., `dev`, `prod`)
   - `{variableName}` is the output variable name

**Example**:
```yaml
variables:
  - name: ResourceGroupId
    value: $[ stageDependencies.Deploy_dev_Infrastructure.TerraformDeployApply_TerraformArtifact.outputs['TerraformDeployApply_TerraformArtifact.TerraformExportOutputsVariables.rg_id'] ]
```

### Incorrect Terraform Version Being Used

**Symptom**: Pipeline fails due to Terraform version mismatch or syntax errors.

**Solution**:
1. Explicitly set the `TerraformVersion` parameter in your pipeline
2. The default is `'1.14.0'`. Use `'latest'` for the latest version or specify an exact semantic version (e.g., `'1.5.7'`)
3. Note that wildcards like `'1.5.x'` are NOT allowed - use exact semantic versions

**Example with exact version**:
```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    TerraformVersion: '1.5.7'
    # ... rest of parameters ...
```

**Example with latest version**:
```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    TerraformVersion: 'latest'
    # ... rest of parameters ...
```


### Backend Configuration Issues

**Symptom**: Error: `backend initialization required` or state file access errors

**Causes**:
- Backend configuration is incorrect
- Service connection doesn't have permissions to storage account
- Storage account or container doesn't exist

**Solution**:
1. Verify the storage account name and container exist in Azure
2. Verify the service connection has `Contributor` or `Storage Blob Data Owner` role on the storage account
3. Verify the backend configuration values are correct:
   ```yaml
   BackendConfig:
     resource_group_name: correct-rg      # Check exact names
     storage_account_name: correctsaname
     container_name: tfstate
     key: dev.terraform.tfstate
   ```
4. Alternatively, hardcode backend config in your Terraform files instead of using pipeline parameters

### Plan Shows No Changes

**Issue**: Terraform plan runs but shows no changes, so apply step is skipped.

**Expected behavior**: This is normal. When there are no changes:
- Plan step completes successfully
- Manual approval is skipped (not needed)
- Apply step is skipped (nothing to apply)
- Pipeline completes successfully

**If this is unexpected**:
- Check that your Terraform files are correct
- Verify variable files are being passed correctly
- Check that the Terraform backend contains existing state from previous deployments
- Verify terraform providers are correctly configured for your Azure environment



---

## Live Examples

View working test examples in the repository:

- **Windows Pipeline**: [tests/pipelines/terraform_pipeline/windows_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/pipelines/terraform_pipeline/windows_test.yml)
- **Linux Pipeline**: [tests/pipelines/terraform_pipeline/linux_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/pipelines/terraform_pipeline/linux_test.yml)
- **Elastic Pipeline**: [tests/pipelines/terraform_pipeline/elastic_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/pipelines/terraform_pipeline/elastic_test.yml)
- **Key Vault Integration**: [tests/pipelines/terraform_pipeline/keyvault_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/pipelines/terraform_pipeline/keyvault_test.yml)

These are functional test pipelines that demonstrate the template in action with various configurations.



