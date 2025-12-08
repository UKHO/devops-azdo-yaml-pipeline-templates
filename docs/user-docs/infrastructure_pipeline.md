# Infrastructure Pipeline

A complete infrastructure deployment pipeline template using Terraform for building, validating, and packaging infrastructure-as-code (IaC) files. This pipeline provides a standardised approach for Terraform-based infrastructure deployments with built-in validation, artifact publishing, and deployment capabilities.

## Important Notices

⚠️ **Terraform Backend Configuration**: This pipeline initialises Terraform with `-backend=false` to avoid backend configuration during the build phase.

⚠️ **Clean Workspace Policy**: The pipeline performs a complete workspace clean-up after validation to ensure artifact purity. Any injection steps will be re-executed on clean code.

⚠️ **Pool Requirements**: The default pool "Mare Nectaris" must be available in your Azure DevOps organisation or specify an alternative pool.

## Basic Usage

### Example of Basic Usage

```yaml
# azure-pipelines.yml
resources:
  repositories:
    - repository: templates
      type: github
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: refs/heads/main

trigger:
  branches:
    include:
      - main

extends:
  template: pipelines/infrastructure_pipeline.yml@PipelineTemplates
  parameters:
    RelativePathToTerraformFiles: tests/pipelines/infrastructure_pipeline/test_terraform
    TerraformVersion: latest
    AzDOEnvironmentName: Discovery
    AzureSubscriptionServiceConnection: Pipeline-CloudDisco
    BackendAzureServiceConnection: Pipeline-CloudDisco
    BackendAzureResourceGroupName: m-devopschapter-rg
    BackendAzureStorageAccountName: ukhodoctfstatesa
    BackendAzureContainerName: tfstate
    BackendAzureBlobName: linux_test.tfstate
    RunPlanOnly: ${{ parameters.RunPlanOnly }}
    VerificationMode: VerifyOnDestroy
    TerraformEnvironmentVariableMappings:
      TF_VAR_MinRandom: 1000
      TF_VAR_MaxRandom: 100000
    TerraformOutputVariables:
      - random_number
      - random_string
    TerraformVariableFiles:
      - config/common.tfvars
      - config/discovery.tfvars
```

### Required Parameters

There are no required parameters, as each parameter has its own default value.

## Full Usage

### Full Parameter Table

| Parameter                              | Type     | Required | Default           | Description                                                                                                          |
|----------------------------------------|----------|----------|-------------------|----------------------------------------------------------------------------------------------------------------------|
| `PipelinePool`                         | string   | false    | "Mare Nectaris"   | The pool that the pipeline will run from the highest level.                                                          |
| `RelativePathToTerraformFiles`         | string   | false    | `''`              | Target path to Terraform files (.tf, .tfvars) that require publishing as an artifact.                                |
| `TerraformVersion`                     | string   | false    | `'latest'`        | Version of Terraform CLI tool to use with the terraform files.                                                       |
| `TerraformBuildInjectionSteps`         | stepList | false    | `[]`              | Steps to be carried out before the terraform is init, validated, and packaged.                                       |
| `AzDOEnvironmentName`                  | string   | false    | `''`              | AzDO Environment name to associate the deployment jobs to.                                                           |
| `AzureSubscriptionServiceConnection`   | string   | false    | `''`              | Azure service connection for the azdo environment.                                                                   |
| `DeploymentJobsVariableMappings`       | object   | false    | `{}`              | Variable mappings to be associated with the deployment jobs.                                                         |
| `BackendAzureServiceConnection`        | string   | false    | `''`              | Azure service connection for backend where the state is stored.                                                      |
| `BackendAzureResourceGroupName`        | string   | false    | `''`              | Azure resource group name for backend where the state is stored.                                                     |
| `BackendAzureStorageAccountName`       | string   | false    | `''`              | Azure storage account name for backend where the state is stored.                                                    |
| `BackendAzureContainerName`            | string   | false    | `''`              | Azure storage container name for backend where the state is stored.                                                  |
| `BackendAzureBlobName`                 | string   | false    | `''`              | Azure storage blob name for backend where the state is stored.                                                       |
| `KeyVaultServiceConnection`            | string   | false    | `''`              | Service connection for key vault access secrets.                                                                     |
| `KeyVaultName`                         | string   | false    | `''`              | Name of key vault for accessing secrets.                                                                             |
| `KeyVaultSecretsFilter`                | string   | false    | `'*'`             | Filter for secrets to access from key vault.                                                                         |
| `RunPlanOnly`                          | boolean  | false    | `false`           | Whether only the terraform plan should be run and no deployment made.                                                |
| `VerificationMode`                     | string   | false    | `VerifyOnDestroy` | How verification step should trigger: verify on destruction changes; verify on any changes; or do not verify at all. |
| `TerraformEnvironmentVariableMappings` | object   | false    | `{}`              | Environment variables to be passed to the task.                                                                      |
| `TerraformVariableFiles`               | object   | false    | `{}`              | List of .tfvars files to be supplied to the terraform commands.                                                      |
| `TerraformOutputVariables`             | object   | false    | `{}`              | List of variables to be exported from the terraform after apply has been run.                                        |

#### TerraformBuildInjectionSteps

This parameter allows you to inject custom steps that will be executed before the terraform files are validated and packaged.

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

### Advanced Usage

Listed below are possible advanced usages.

_If you have any advanced usages, please consider contributing them to the documentation._

#### Custom Agent Pool

```yaml
extends:
  template: pipelines/infrastructure_pipeline.yml@templates
  parameters:
    PipelinePool: 'MyCustomPool'
    RelativePathToTerraformFiles: 'infrastructure/terraform'
    TerraformVersion: '1.6.0'
```

#### Injection Step to add required_version

```yaml
extends:
  template: pipelines/infrastructure_pipeline.yml@PipelineTemplates
  parameters:
    RelativePathToTerraformFiles: tests/pipelines/infrastructure_pipeline/terraform
    PipelinePool: "Mare Nubium"
    TerraformVersion: 1.1.9
    TerraformBuildInjectionSteps:
      - pwsh: |
          $path = "$(Pipeline.Workspace)/$(Build.Repository.Name)/tests/pipelines/infrastructure_pipeline/terraform/main.tf"
          $content = Get-Content $path
          $terraformStart = $content.IndexOf($($content | Where-Object { $_ -match "^terraform\s*{" }))
          if ($terraformStart -ge 0) {
            $insertIndex = $terraformStart + 1
            $content = $content[0..($insertIndex-1)] + '  required_version = "1.1.9"' + $content[$insertIndex..($content.Count-1)]
            Set-Content $path $content
          }
        displayName: "Injecting into terraform block 'required_version'"
```

---

## New: Deployment Stage Usage Examples

The pipeline now supports full deployment using the `terraform_deploy.yml` stage, enabling advanced scenarios such as remote state, key vault integration, and controlled apply/plan flows.

### Example: Full Deployment with Azure Backend and Key Vault

```yaml
extends:
  template: pipelines/infrastructure_pipeline.yml@templates
  parameters:
    RelativePathToTerraformFiles: 'terraform'
    TerraformVersion: '1.5.0'
    AzDOEnvironmentName: 'dev'
    AzureSubscriptionServiceConnection: 'my-azure-service-connection'
    BackendAzureServiceConnection: 'my-azure-service-connection'
    BackendAzureResourceGroupName: 'tfstate-rg'
    BackendAzureStorageAccountName: 'tfstateaccount'
    BackendAzureContainerName: 'tfstate'
    BackendAzureBlobName: 'dev.terraform.tfstate'
    KeyVaultServiceConnection: 'my-keyvault-service-connection'
    KeyVaultName: 'my-keyvault'
    KeyVaultSecretsFilter: '*'
    RunPlanOnly: false
    VerificationMode: 'VerifyOnAny'
    TerraformEnvironmentVariableMappings:
      ARM_CLIENT_ID: $(armClientId)
      ARM_CLIENT_SECRET: $(armClientSecret)
    TerraformVariableFiles:
      - 'dev.tfvars'
    TerraformOutputVariables:
      output_var_1: '$(outputVar1)'
```

### Example: Plan-Only Mode

```yaml
extends:
  template: pipelines/infrastructure_pipeline.yml@templates
  parameters:
    RelativePathToTerraformFiles: 'terraform'
    RunPlanOnly: true
```

---

For more details on each parameter and advanced deployment scenarios, refer to the template YAML comments and the repository README.
