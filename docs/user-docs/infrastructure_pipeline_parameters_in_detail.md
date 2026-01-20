# Template parameters in detail

This document provides detailed information about all parameters available in the Infrastructure Pipeline template.

## Configuration Documentation

**For comprehensive configuration details, see the developer documentation:**
- **[EnvironmentConfig Documentation](../definition_docs/infrastructure_pipeline/environment_config.md)** - Complete environment configuration structure including Name, Stage dependencies/conditions, and InfrastructureConfig
- **[InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md)** - Detailed infrastructure-specific configuration (Azure connections, backend, Key Vault, variables, etc.)

## Pipeline Structure

The infrastructure pipeline consists of multiple stages:

1. **Build Stage**: Validates and packages Terraform files
   - Installs specified Terraform version
   - Runs injection steps (if provided)
   - Initializes Terraform (without backend)
   - Validates Terraform configuration
   - Publishes Terraform files as an artifact

2. **Deploy Stages** (one per environment in EnvironmentConfigs): Deploys infrastructure with optional manual verification
   - Stage name format: `Deploy_{EnvironmentName}_Infrastructure`
   - Downloads Terraform artifact
   - Initializes Terraform (with backend)
   - **Plan Job**: Creates execution plan
   - **Manual Verification Job**: Optional approval gate (conditional)
   - **Apply Job**: Applies changes and exports outputs (conditional)

The deploy stage behavior is controlled by `RunPlanOnly` and `VerificationMode` parameters within each environment's `InfrastructureConfig`. See the [manual verification documentation](infrastructure_pipeline_manual_verification.md) for flow details.

## Pipeline-Level Parameters

These parameters apply to the entire pipeline and all environments:

| Parameter                                                     | Type     | Required | Default           | Description                                                                       |
|---------------------------------------------------------------|----------|----------|-------------------|-----------------------------------------------------------------------------------|
| [PipelinePool](#pipelinepool)                                 | string   |          | `'Mare Nectaris'` | The pool that the pipeline will run from the highest level.                       |
| [RelativePathToTerraformFiles](#relativepathtoterraformfiles) | string   |          | `''`              | Target Path to Terraform files (.tf,.tfvars) that require publishing as artifact. |
| [TerraformVersion](#terraformversion)                         | string   |          | `'1.14.x'`        | Version of Terraform CLI tool to use with the terraform files.                    |
| [TerraformBuildInjectionSteps](#terraformbuildinjectionsteps) | stepList |          | `[]`              | Steps to be carried out before the terraform is init, validated, and packaged.    |
| [RunPlanOnly](#runplanonly)                                   | boolean  |          | `false`           | Whether only the terraform plan should be ran and no deployment made.             |
| [EnvironmentConfigs](#environmentconfigs)                     | object   | ❗        | -                 | List of environment configurations (see dev docs for complete structure).         |

## Environment Configuration

The `EnvironmentConfigs` parameter is a list of environment configuration objects. Each environment configuration includes:

- **Name**: Unique environment identifier
- **Stage**: Stage orchestration settings (DependsOn, Condition)
- **InfrastructureConfig**: Complete infrastructure deployment configuration

**See the comprehensive documentation:**
- [EnvironmentConfig Structure](../definition_docs/infrastructure_pipeline/environment_config.md)
- [InfrastructureConfig Properties](../definition_docs/infrastructure_pipeline/infrastructure_config.md)

### Quick EnvironmentConfig Example

```yaml
EnvironmentConfigs:
  - Name: production
    Stage:
      DependsOn: Terraform_Build
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
      # ... additional optional properties ...
```

## Parameter Reference

Below are all the pipeline-level parameters to this template with further details.

### PipelinePool

Change the agent pool that is being used by specifying it.

```yaml
PipelinePool: 'Mare Nubium'
```

`Mare Nectaris` is the default pool, no need to specify.

### RelativePathToTerraformFiles

State where the terraform files that need packaging and then deploying are located.

```yaml
RelativePathToTerraformFiles: 'infrastructure/terraform'
```

The path prepended with `$(Pipeline.Workspace)/$(Build.Repository.Name)/` for creating an absolute path to the terraform files.

### TerraformVersion

State which terraform version you require.

```yaml
TerraformVersion: '1.6.0'
```

The default version is `1.14.x`.

### TerraformBuildInjectionSteps

This parameter allows you to inject custom steps that will be executed before the terraform files are validated and packaged.

**Important**: These steps are run **twice** during the Build stage:
1. First, before validation (to allow modifications needed for validation to pass)
2. Second, after a clean checkout (to ensure the packaged artifact has the modifications)

This ensures that any modifications you make are both validated and included in the final artifact.

Common use cases include:

- File transformations or substitutions
- Environment-specific configuration setup
- Secret retrieval and file generation
- Custom validation or security scanning

```yaml
TerraformBuildInjectionSteps:
  - task: PowerShell@2
    displayName: 'Generate backend config'
    inputs:
      targetType: 'inline'
      script: |
        # Generate backend.tf from environment variables
        Write-Host "Generating backend configuration..."

  - task: AzureCLI@2
    displayName: 'Retrieve secrets'
    inputs:
      azureSubscription: 'service-connection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az keyvault secret show --vault-name myvault --name terraform-vars
```

### RunPlanOnly

If you do not want to deploy any resources, you can run the plan only for all environments.

```yaml
RunPlanOnly: true
```

This applies to all environments configured in `EnvironmentConfigs`.

### EnvironmentConfigs

The core configuration parameter that defines all environments to deploy to. This is a list of environment configuration objects.

**For complete documentation, see:**
- [EnvironmentConfig Structure](../definition_docs/infrastructure_pipeline/environment_config.md)
- [InfrastructureConfig Properties](../definition_docs/infrastructure_pipeline/infrastructure_config.md)

**Quick structure:**

```yaml
EnvironmentConfigs:
  - Name: string                    # Environment identifier
    Stage:
      DependsOn: string | list      # Stage dependencies
      Condition: string             # Stage execution condition
    InfrastructureConfig:           # Complete infrastructure configuration
      AzureSubscriptionServiceConnection: string
      AzDOEnvironmentName: string
      BackendConfig: { ... }
      VerificationMode: string
      # ... optional properties ...
```

**Multi-environment example:**

```yaml
EnvironmentConfigs:
  # Development
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

  # Production (depends on dev, only on main branch)
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

## InfrastructureConfig Properties

The following properties are configured within each environment's `InfrastructureConfig` object. For complete documentation, see [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md).

### Azure Service Connections

Define the Azure service connections for deployment and backend state management.

**Within `InfrastructureConfig`:**
- `AzureSubscriptionServiceConnection`: Service connection for deploying resources
- `AzDOEnvironmentName`: Azure DevOps environment name for approvals
- `BackendConfig.ServiceConnection`: Service connection for Terraform state backend

See [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md#azuresubscriptionserviceconnection) for details.

### Backend Configuration

Define the required values for accessing the Terraform state for each environment.

**Within `InfrastructureConfig.BackendConfig`:**
- `ServiceConnection`: Azure service connection
- `ResourceGroupName`: Resource group name
- `StorageAccountName`: Storage account name
- `ContainerName`: Container name
- `BlobName`: Blob name for state file

Example:
```yaml
BackendConfig:
  ServiceConnection: 'my-backend-service-connection'
  ResourceGroupName: 'my-resource-group'
  StorageAccountName: 'mystorageaccount'
  ContainerName: 'mycontainer'
  BlobName: 'terraform.tfstate'
```

See [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md#backendconfig) for details.

### Key Vault Configuration

Define optional values for accessing secrets from Azure Key Vault during deployment.

**Within `InfrastructureConfig.KeyVaultConfig`:**
- `ServiceConnection`: Service connection for Key Vault access
- `Name`: Key Vault name
- `SecretsFilter`: Filter for secrets (e.g., `'*'` for all)

**Note**: Key Vault secrets are only accessed during the **Deploy stage**, not during the Build stage. All three parameters must be provided for Key Vault integration to be enabled.

Example:
```yaml
KeyVaultConfig:
  ServiceConnection: "MyAzureServiceConnection"
  Name: "my-key-vault"
  SecretsFilter: "*"
```

See [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md#keyvaultconfig) for details.

### Verification Mode

Controls when manual verification is required for each environment.

**Within `InfrastructureConfig.VerificationMode`:**

Options:
- `VerifyOnDestroy`: Manual verification only when resources will be destroyed
- `VerifyOnAny`: Manual verification for any infrastructure changes
- `VerifyDisabled`: No manual verification (auto-apply if changes detected)

Example:
```yaml
VerificationMode: 'VerifyOnAny'
```

See [How does Infrastructure Manual Verification work?](infrastructure_pipeline_manual_verification.md) and [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md#verificationmode).

### Environment Variables

Provide environment variables for Terraform execution.

**Within `InfrastructureConfig.EnvironmentVariableMappings`:**

Example:
```yaml
EnvironmentVariableMappings:
  ARM_CLIENT_ID: 'xxxx-xxxx-xxxx'
  ARM_CLIENT_SECRET: 'xxxx-xxxx-xxxx'
  TF_LOG: 'INFO'
```

See [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md#environmentvariablemappings) for details.

### Variable Files

Provide Terraform `.tfvars` files to use with the Terraform `.tf` files.

**Within `InfrastructureConfig.VariableFiles`:**

Example:
```yaml
VariableFiles:
  - 'config/common.tfvars'
  - 'config/env-specific.tfvars'
```

The pipeline will access these files from the Terraform artifact created during the build stage. That stage packages all files found via `RelativePathToTerraformFiles` parameter.

See [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md#variablefiles) for details.

### Output Variables

Specify Terraform output variables to export as pipeline variables after deployment.

**Within `InfrastructureConfig.OutputVariables`:**

**Note**: Output variables are only exported during the **Apply job** (when `RunPlanOnly` is `false` and apply runs successfully).

Example:
```yaml
OutputVariables:
  - output1
  - output2
```

#### Accessing Output Variables

The output variables are exported as Azure DevOps pipeline variables with the following naming convention:

```
stageDependencies.Deploy_{EnvironmentName}_Infrastructure.TerraformDeploy_Apply.outputs['TerraformDeploy_Apply.TerraformExportOutputsVariables.{variableName}']
```

**Example**: If you export a Terraform output named `resource_id` from an environment named `dev`, you would access it in a subsequent stage like this:

```yaml
stages:
  # ... infrastructure pipeline stages ...

  - stage: UseOutputs
    dependsOn: Deploy_dev_Infrastructure
    variables:
      ResourceId: $[stageDependencies.Deploy_dev_Infrastructure.TerraformDeploy_Apply.outputs['TerraformDeploy_Apply.TerraformExportOutputsVariables.resource_id']]
    jobs:
      - job: ConsumeOutput
        steps:
          - script: echo "Resource ID is $(ResourceId)"
```

For more information, see Microsoft documentation: [Set an output variable for use in future jobs](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-variables-scripts?view=azure-devops&tabs=powershell#set-an-output-variable-for-use-in-future-jobs).

See [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md#outputvariables) for details.

### Jobs Variable Mappings

Specify variables, variable groups, or templates to add to deployment jobs.

**Within `InfrastructureConfig.JobsVariableMappings`:**

Example:
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

See [InfrastructureConfig Documentation](../definition_docs/infrastructure_pipeline/infrastructure_config.md#jobsvariablemappings) for details.

