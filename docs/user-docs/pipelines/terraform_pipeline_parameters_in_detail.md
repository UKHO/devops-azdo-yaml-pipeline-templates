# Template Parameters in Detail

This document provides detailed information about all parameters available in the Terraform Pipeline template.

**Quick links**:
- For basic usage examples, see [Terraform Pipeline](./terraform_pipeline.md)
- For common scenarios, see [Common Scenarios in Terraform Pipeline](./terraform_pipeline.md#common-scenarios--patterns)
- For manual verification details, see [Manual Verification](./terraform_pipeline_manual_verification.md)
- For additional files packaging, see [AdditionalFilesToPackage Guide](./terraform_pipeline_additional_files_to_package.md)

---

## Configuration Documentation

**For comprehensive configuration details, see the developer documentation:**
- **[EnvironmentConfig Documentation](../../definition_docs/terraform_pipeline/environment_config.md)** - Complete environment configuration structure including Name, Stage dependencies/conditions, and TerraformDeploymentConfig
- **[TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md)** - Detailed terraform deployment configuration (Azure connections, backend, Key Vault, variables, etc.)

## Pipeline Structure

The infrastructure pipeline consists of multiple stages:

1. **Build Stage** (`Build_Terraform`) – Validates and packages Terraform files
   - Installs specified Terraform version
   - Runs injection steps (if provided)
   - Initializes Terraform (without backend to allow flexible backend config in deploy)
   - Validates Terraform configuration
   - Publishes Terraform files as an artifact

2. **Deploy Stages** (one per environment in EnvironmentConfigs): Deploys infrastructure with optional manual verification
   - Stage name format: `Deploy_{EnvironmentName}_Terraform`
   - Downloads Terraform artifact
   - Initializes Terraform (with backend)
   - **Plan Job**: Creates execution plan
   - **Manual Verification Job**: Optional approval gate (conditional)
   - **Apply Job**: Applies changes and exports outputs (conditional)

The deploy stage behaviour is controlled by `RunMode` and `VerificationMode` parameters within each environment's `TerraformDeploymentConfig`. See the [manual verification documentation](terraform_pipeline_manual_verification.md) for flow details.

## Pipeline-Level Parameters

These parameters apply to the entire pipeline and all environments:

| Parameter                                                     | Type     | Required | Default    | Description                                                                        |
|---------------------------------------------------------------|----------|----------|------------|------------------------------------------------------------------------------------|
| [RelativePathToTerraformFiles](#relativepathtoterraformfiles) | string   |          | `''`       | Target Path to Terraform files (.tf,.tfvars) that require publishing as artifact.  |
| [AdditionalFilesToPackage](#additionalfilestopackage)         | object   |          | `[ ]`      | List of additional files to include in the terraform artifact (see details below). |
| [TerraformVersion](#terraformversion)                         | string   |          | `'1.14.0'` | Version of Terraform CLI tool to use ('latest' or semantic version x.y.z).         |
| [TerraformBuildInjectionSteps](#terraformbuildinjectionsteps) | stepList |          | `[ ]`      | Steps to be carried out before the terraform is init, validated, and packaged.     |
| [EnvironmentConfigs](#environmentconfigs)                     | object   | ❗        | -          | List of environment configurations (see dev docs for complete structure).          |

## Environment Configuration

The `EnvironmentConfigs` parameter is a list of environment configuration objects. Each environment configuration includes:

- **Name**: Unique environment identifier
- **Stage**: Stage orchestration settings (DependsOn, Condition)
- **TerraformDeploymentConfig**: Complete terraform deployment configuration

**See the comprehensive documentation:**
- [EnvironmentConfig Structure](../../definition_docs/terraform_pipeline/environment_config.md)
- [TerraformDeploymentConfig Properties](../../definition_docs/terraform_pipeline/terraform_deployment_config.md)

### Quick EnvironmentConfig Example

```yaml
EnvironmentConfigs:
   - Name: production
     Stage:
       DependsOn: Terraform_Build
       Condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    TerraformDeploymentConfig:
      AzDOEnvironmentName: production-environment
      RunMode: PlanVerifyApply
      VerificationMode: VerifyOnAny
      # Optional: BackendConfig (omit if hardcoded in Terraform files)
      # BackendConfig:
      #   resource_group_name: rg-terraform-state-prod
      #   storage_account_name: sttfstateprod
      #   container_name: tfstate
      #   key: production.terraform.tfstate
      # Optional: AzureServiceConnection (omit to use client credentials)
      # AzureServiceConnection: AzureServiceConnection-Production
      # ... additional optional properties ...
```

## Parameter Reference

Below are all the pipeline-level parameters to this template with further details.

### RelativePathToTerraformFiles

State where the terraform files that need packaging and then deploying are located.

```yaml
RelativePathToTerraformFiles: 'infrastructure/terraform'
```

The path prepended with `$(Pipeline.Workspace)/$(Build.Repository.Name)/` for creating an absolute path to the terraform files.

### AdditionalFilesToPackage

This parameter allows you to include additional files (beyond the Terraform files in `RelativePathToTerraformFiles`) in the terraform artifact that gets deployed.

**For comprehensive guide, see:** [AdditionalFilesToPackage - Detailed Guide](./terraform_pipeline_additional_files_to_package.md)

**For object structure, see:** [AdditionalFilesToPackage Definition](../../definition_docs/terraform_pipeline/additional_files_to_package.md)

#### Quick Reference

Each item in `AdditionalFilesToPackage` is an object with three required properties:

| Property               | Type   | Description                                                |
|------------------------|--------|------------------------------------------------------------|
| SourceDirectory        | string | Relative path from repository root to the source directory |
| FilesPattern           | string | Glob pattern for files to copy (e.g., `**/*.json`)         |
| TargetSubdirectoryName | string | Subdirectory within the artifact to place the copied files |

#### Basic Example

```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config/shared'
    FilesPattern: '*.tfvars'
    TargetSubdirectoryName: 'shared-config'
  - SourceDirectory: 'scripts'
    FilesPattern: '**/*.ps1'
    TargetSubdirectoryName: 'scripts'
```

This copies all `.tfvars` files from `config/shared/` to `{artifact}/shared-config/` and all PowerShell scripts from `scripts/` to `{artifact}/scripts/`.

#### Common Patterns

| Pattern       | Use Case                                                 |
|---------------|----------------------------------------------------------|
| `*.tfvars`    | All variable files in the root directory (non-recursive) |
| `**/*.tfvars` | All variable files recursively                           |
| `**/*.tf`     | All Terraform files recursively                          |
| `**/*`        | All files recursively                                    |

For more patterns and detailed examples, see the [Detailed Guide](./terraform_pipeline_additional_files_to_package.md#glob-pattern-matching).

---

### TerraformVersion

State which terraform version you require.

```yaml
TerraformVersion: '1.6.0'
```

**Valid formats:**
- `'latest'` – Uses the latest available version
- Semantic version (e.g., `'1.6.0'`, `'1.14.3'`) – Uses the specified exact version

**Invalid formats (will fail):**
- Wildcards like `'1.14.x'` or `'1.6.*'` are not accepted
- Non-semantic formats will be rejected with a validation error

The default version is `'1.14.0'`.

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

### EnvironmentConfigs

The core configuration parameter that defines all environments to deploy to. This is a list of environment configuration objects.

**For complete documentation, see:**
- [EnvironmentConfig Structure](../../definition_docs/terraform_pipeline/environment_config.md)
- [TerraformDeploymentConfig Properties](../../definition_docs/terraform_pipeline/terraform_deployment_config.md)

**Quick structure:**

```yaml
EnvironmentConfigs:
  - Name: string                    # Environment identifier
    Stage:
      DependsOn: string | list      # Stage dependencies
      Condition: string             # Stage execution condition
    TerraformDeploymentConfig:           # Complete infrastructure configuration
      AzDOEnvironmentName: string
      RunMode: string               # PlanVerifyApply, PlanOnly, or ApplyOnly
      VerificationMode: string      # Only required for PlanVerifyApply
      BackendConfig: { }            # Optional - can hardcode in Terraform files
      AzureServiceConnection: string # Optional - can use client credentials
      # ... other optional properties ...
```

**Multi-environment example:**

```yaml
EnvironmentConfigs:
   # Development
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

   # Production (depends on dev, only on main branch)
   - Name: production
     Stage:
       DependsOn: Deploy_dev_Terraform
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

## TerraformDeploymentConfig Properties

The following properties are configured within each environment's `TerraformDeploymentConfig` object. For complete documentation, see [TerraformDeploymentConfig Documentation](../definition_docs/terraform_pipeline/terraform_deployment_config.md).

### Azure Service Connections

Define how to authenticate with Azure for deploying resources and accessing the Terraform state backend.

**Option 1: Using Azure Service Connection (Recommended)**

Provide a service connection in `TerraformDeploymentConfig`:
```yaml
TerraformDeploymentConfig:
  AzureServiceConnection: AzureServiceConnection-Production
  AzDOEnvironmentName: production-environment
  # ... other configuration ...
```

**Option 2: Using Client Credentials (If No Service Connection Available)**

If `AzureServiceConnection` is not provided, supply Azure credentials via environment variables:
```yaml
TerraformDeploymentConfig:
  AzDOEnvironmentName: production-environment
  EnvironmentVariableMappings:
    ARM_CLIENT_ID: 'your-client-id'
    ARM_CLIENT_SECRET: 'your-client-secret'
    ARM_SUBSCRIPTION_ID: 'your-subscription-id'
    ARM_TENANT_ID: 'your-tenant-id'
  # ... other configuration ...
```

See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md#azureserviceconnection) for details.

### Backend Configuration

Define how Terraform state is stored and accessed.

Provide backend config via the pipeline for flexibility across environments:

```yaml
TerraformDeploymentConfig:
  BackendConfig:
    resource_group_name: 'my-resource-group'
    storage_account_name: 'mystorageaccount'
    container_name: 'mycontainer'
    key: 'terraform.tfstate'
```

**Common Azure Backend Keys:**
- `resource_group_name`: Resource group name
- `storage_account_name`: Storage account name
- `container_name`: Container name
- `key`: Blob name for state file

**Note:** BackendConfig accepts any key-value pairs to support different backend types and providers, not just Azure. If omitted from the pipeline, ensure backend is configured in your Terraform files.

See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md#backendconfig) for details.

### Key Vault Configuration

Define optional values for accessing secrets from Azure Key Vault during deployment.

**Within `TerraformDeploymentConfig.KeyVaultConfig`:**
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

See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md#keyvaultconfig) for details.

### Verification Mode

Controls when manual verification is required for each environment. **Note:** Only applicable when `RunMode` is `PlanVerifyApply`; ignored for other RunModes.

**Within `TerraformDeploymentConfig.VerificationMode`:**

Options:
- `VerifyOnDestroy`: Manual verification only when resources will be destroyed
- `VerifyOnAny`: Manual verification for any infrastructure changes
- `VerifyDisabled`: No manual verification (auto-apply if changes detected)

Example:
```yaml
RunMode: PlanVerifyApply
VerificationMode: 'VerifyOnAny'
```

See [How does Infrastructure Manual Verification work?](terraform_pipeline_manual_verification.md) and [TerraformDeploymentConfig Documentation](../definition_docs/terraform_pipeline/terraform_deployment_config.md#verificationmode).

### Environment Variables

Provide environment variables for Terraform execution.

**Within `TerraformDeploymentConfig.EnvironmentVariableMappings`:**

Example:
```yaml
EnvironmentVariableMappings:
  ARM_CLIENT_ID: 'xxxx-xxxx-xxxx'
  ARM_CLIENT_SECRET: 'xxxx-xxxx-xxxx'
  TF_LOG: 'INFO'
```

See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md#environmentvariablemappings) for details.

### Variable Files

Provide Terraform `.tfvars` files to use with the Terraform `.tf` files.

**Within `TerraformDeploymentConfig.VariableFiles`:**

Example:
```yaml
VariableFiles:
  - 'config/common.tfvars'
  - 'config/env-specific.tfvars'
```

The pipeline will access these files from the Terraform artifact created during the build stage. That stage packages all files found via `RelativePathToTerraformFiles` parameter.

See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md#variablefiles) for details.

### Output Variables

Specify Terraform output variables to export as pipeline variables after deployment.

**Within `TerraformDeploymentConfig.OutputVariables`:**

**Note**: Output variables are only exported during the **Apply job** (when `RunMode` is not `PlanOnly` and apply runs successfully).

Example:
```yaml
OutputVariables:
  - output1
  - output2
```

#### Accessing Output Variables

The output variables are exported as Azure DevOps pipeline variables with the following naming convention:

```
stageDependencies.Deploy_{EnvironmentName}_Terraform.TerraformDeploy_Apply.outputs['TerraformDeploy_Apply.TerraformExportOutputsVariables.{variableName}']
```

**Example**: If you export a Terraform output named `resource_id` from an environment named `dev`, you would access it in a subsequent stage like this:

```yaml
stages:
  # ... infrastructure pipeline stages ...

  - stage: UseOutputs
    dependsOn: Deploy_dev_Terraform
    variables:
      ResourceId: $[stageDependencies.Deploy_dev_Terraform.TerraformDeploy_Apply.outputs['TerraformDeploy_Apply.TerraformExportOutputsVariables.resource_id']]
    jobs:
      - job: ConsumeOutput
        steps:
          - script: echo "Resource ID is $(ResourceId)"
```

For more information, see Microsoft documentation: [Set an output variable for use in future jobs](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-variables-scripts?view=azure-devops&tabs=powershell#set-an-output-variable-for-use-in-future-jobs).

See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md#outputvariables) for details.

### Jobs Variable Mappings

Specify variables, variable groups, or templates to add to deployment jobs.

**Within `TerraformDeploymentConfig.JobsVariableMappings`:**

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

See [TerraformDeploymentConfig Documentation](../../definition_docs/terraform_pipeline/terraform_deployment_config.md#jobsvariablemappings) for details.

