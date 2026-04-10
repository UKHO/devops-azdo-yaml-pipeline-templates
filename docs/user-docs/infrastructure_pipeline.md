# Infrastructure Pipeline

A standardised infrastructure deployment pipeline template that uses terraform as the IaC tooling and Azure as the cloud provider. This pipeline will:

- Build/Validate/Package the terraform files
- Deploy the packaged terraform files to environments with a [manual verification gate](infrastructure_pipeline_manual_verification.md)

## Important

**Repository Resource Requirement**: The pipeline requires access to this template repository during execution. You **must** define the repository resource with the name `AzDOPipelineTemplates` (as shown in the example above) because the pipeline internally checks out this repository to access helper scripts during the deployment stage.

Pool Requirements: The default pool "Mare Nectaris" must be available in your Azure DevOps organisation or specify an alternative pool.

Terraform Workspace: This command is not currently available.

Snyk Scanning: This is not currently part of the pipeline.

### ⚠️ Known Limitations & Outstanding Issues

**Lock File Not Preserved Between Build and Deploy Stages**: The `.terraform.lock.hcl` file created during the build stage is not currently preserved and passed to the deploy stages. This means each deploy stage performs fresh provider resolution, which could lead to different provider versions being installed in deploy stages compared to the build stage. See [outstanding issue](#) for investigation and fixes to improve robustness.

**Plan Generated During Build is Discarded Before Apply**: The Terraform plan generated during the build/planning stage is evaluated during manual verification but is then discarded before the `terraform apply` runs in the deploy stage. This means the infrastructure provisioned during apply may differ from what was reviewed in the plan if there are external changes between stages. See [outstanding issue](#) for investigation and improvements to increase accountability and auditability of infrastructure deployments.

## Basic Usage

### Example of Basic Usage

```yaml
# azure-pipelines.yml
resources:
  repositories:
    - repository: AzDOPipelineTemplates                 # 'PipelineTemplates' has commonly been used for https://github.com/UKHO/devops-pipelinetemplates
      type: github
      endpoint: UKHO                                    # this endpoint needs defining in your AzDO Project as a service connection to GitHub
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: refs/tags/0.0.0                              # Do consult the https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/releases for the latest version

trigger:
  branches:
    include:
      - main

extends:
  template: pipelines/infrastructure_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: infra/webapp
    TerraformVersion: '1.0.9'
    EnvironmentConfigs:
      - Name: dev
        Stage:
          DependsOn: Terraform_Build
          Condition: succeeded()
        InfrastructureConfig:
          AzDOEnvironmentName: dev-environment
          AzureSubscriptionServiceConnection: Pipeline-dev
          BackendConfig:
            ServiceConnection: Pipeline-dev
            ResourceGroupName: m-project-rg
            StorageAccountName: projecttfsa
            ContainerName: tfstate
            BlobName: dev.terraform.tfstate
          VerificationMode: VerifyOnDestroy
          EnvironmentVariableMappings:
            TF_VAR_MinRandom: 1000
            TF_VAR_MaxRandom: 100000
          VariableFiles:
            - config/common.tfvars
            - config/dev.tfvars
          OutputVariables:
            - random_number
            - random_string
```

### Required Parameters

The infrastructure pipeline uses an `EnvironmentConfigs` parameter that contains a list of environment configurations. Each environment configuration has the following structure:

**For complete configuration documentation, see:**
- [EnvironmentConfig Documentation](../definition_docs/infrastructure_pipeline/environment_config.md) - Complete environment configuration structure
- [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md) - Infrastructure-specific configuration details
- [AdditionalFilesToPackage Documentation](../definition_docs/infrastructure_pipeline/additional_files_to_package.md) - Additional files to include in the terraform artifact

**Quick reference of required fields:**

| Field Path                                              | Type        | Description                                                                           |
|---------------------------------------------------------|-------------|---------------------------------------------------------------------------------------|
| Name                                                    | string      | Unique environment name (e.g., 'dev', 'staging', 'production')                        |
| Stage.DependsOn                                         | string/list | Stage dependencies (e.g., 'Terraform_Build' or list of stages)                        |
| Stage.Condition                                         | string      | Stage execution condition (e.g., 'succeeded()')                                       |
| InfrastructureConfig.AzDOEnvironmentName                | string      | AzDO Environment name to associate the deployment jobs to                             |
| InfrastructureConfig.AzureSubscriptionServiceConnection | string      | Azure service connection for the azdo environment                                     |
| InfrastructureConfig.BackendConfig.ServiceConnection    | string      | Azure service connection for backend where the state is stored                        |
| InfrastructureConfig.BackendConfig.ResourceGroupName    | string      | Azure resource group name for backend where the state is stored                       |
| InfrastructureConfig.BackendConfig.StorageAccountName   | string      | Azure storage account name for backend where the state is stored                      |
| InfrastructureConfig.BackendConfig.ContainerName        | string      | Azure storage container name for backend where the state is stored                    |
| InfrastructureConfig.BackendConfig.BlobName             | string      | Azure storage blob name for backend where the state is stored                         |
| InfrastructureConfig.VerificationMode                   | string      | How verification step should trigger: VerifyOnDestroy, VerifyOnAny, or VerifyDisabled |

See the [developer documentation](../definition_docs/infrastructure_pipeline/environment_config.md) for optional parameters and advanced configuration.

## Advanced Usage

Listed below are possible advanced usages.

_If you have any advanced usages, please consider contributing them to the documentation._

### Multi-Environment Deployment

Deploy to multiple environments with stage dependencies:

```yaml
extends:
  template: pipelines/infrastructure_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infrastructure/terraform'
    TerraformVersion: '1.6.0'
    EnvironmentConfigs:
      # Development Environment
      - Name: dev
        Stage:
          DependsOn: Terraform_Build
          Condition: succeeded()
        InfrastructureConfig:
          AzureSubscriptionServiceConnection: AzureServiceConnection-Dev
          AzDOEnvironmentName: development-environment
          BackendConfig:
            ServiceConnection: AzureServiceConnection-TerraformState
            ResourceGroupName: rg-terraform-state-dev
            StorageAccountName: sttfstatedev
            ContainerName: tfstate
            BlobName: dev.terraform.tfstate
          VerificationMode: VerifyOnDestroy
          VariableFiles:
            - config/common.tfvars
            - config/dev.tfvars

      # Production Environment (deploys after dev, only on main branch)
      - Name: production
        Stage:
          DependsOn: Deploy_dev_Infrastructure
          Condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
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
  template: pipelines/infrastructure_pipeline.yml@AzDOPipelineTemplates
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
        InfrastructureConfig:
          AzureSubscriptionServiceConnection: AzureServiceConnection-Dev
          AzDOEnvironmentName: development-environment
          BackendConfig:
            ServiceConnection: AzureServiceConnection-TerraformState
            ResourceGroupName: rg-terraform-state-dev
            StorageAccountName: sttfstatedev
            ContainerName: tfstate
            BlobName: dev.terraform.tfstate
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
  template: pipelines/infrastructure_pipeline.yml@AzDOPipelineTemplates
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
        InfrastructureConfig:
          # ... infrastructure config ...
```

## Troubleshooting

### Manual verification not triggering

**Issue**: Manual verification gate doesn't appear even when changes are detected.

**Check**:
- Verify `RunMode` is not set to `PlanOnly`
- Verify `VerificationMode` is set to either `VerifyOnAny` or `VerifyOnDestroy` (not `VerifyDisabled`)
- Check the plan output to ensure changes were actually detected

### Output variables not available in subsequent stages/jobs

**Cause**: Output variables from Terraform are only available after the Apply job completes and are scoped to the deployment job.

**Solution**: To use Terraform output variables in subsequent stages or jobs outside the infrastructure pipeline, you'll need to:
1. Ensure the variables are listed in the `OutputVariables` property of your `InfrastructureConfig`
2. Reference them using the correct dependency syntax: `dependencies.TerraformDeploy_Apply.outputs['TerraformDeploy_Apply.TerraformExportOutputsVariables.{variableName}']`
3. Note: Variables are only exported when `RunMode` is not `PlanOnly` and the apply job runs successfully

### Incorrect Terraform version being used

**Solution**: Explicitly set the `TerraformVersion` parameter. The default is `'1.14.0'`. Remember that only semantic versions (e.g., `'1.14.0'`, `'1.6.5'`) or the keyword `'latest'` are accepted — wildcards like `'1.14.x'` will be rejected with a validation error.
