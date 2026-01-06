# Infrastructure Pipeline

A complete infrastructure deployment pipeline template using Terraform for building, validating, and packaging infrastructure-as-code (IaC) files. This pipeline provides a standardised approach for Terraform-based infrastructure deployments with built-in validation and artifact publishing capabilities.

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
  template: pipelines/infrastructure_pipeline.yml@templates
  parameters:
    RelativePathToTerraformFiles: 'terraform'
    TerraformVersion: '1.5.0'
```

### Required Parameters

There are no required parameters, as each parameter has its own default value.

## Full Usage

### Full Parameter Table

| Parameter                                                                     | Type     | Required | Default           | Description                                                                                    |
|-------------------------------------------------------------------------------|----------|----------|-------------------|------------------------------------------------------------------------------------------------|
| [PipelinePool](#pipelinepool)                                                 | string   | false    | `Mare Nectaris`   | The pool that the pipeline will run from the highest level.                                    |
| [RelativePathToTerraformFiles](#relativepathtoterraformfiles)                 | string   | false    | `''`              | Target path to Terraform files (.tf, .tfvars) that require publishing as artifact.             |
| [TerraformVersion](#terraformversion)                                         | string   | false    | `'latest'`        | Version of Terraform CLI tool to use with the terraform files.                                 |
| [TerraformBuildInjectionSteps](#terraformbuildinjectionsteps)                 | stepList | false    | `[]`              | Steps to be carried out before the terraform is init, validated, and packaged.                 |
| [AzDOEnvironmentName](#azdoenvironmentname)                                   | string   | false    | `''`              | AzDO Environment name to associate the deployment jobs to.                                     |
| [AzureSubscriptionServiceConnection](#azuresubscriptionserviceconnection)     | string   | false    | `''`              | Azure service connection for the azdo environment.                                             |
| [DeploymentJobsVariableMappings](#deploymentjobsvariablemappings)             | object   | false    | `{}`              | Variable mappings to be associated with the deployment jobs.                                   |
| [BackendAzureServiceConnection](#backendazureserviceconnection)               | string   | false    | `''`              | Azure service connection for backend where the state is stored.                                |
| [BackendAzureResourceGroupName](#backendazureresourcegroupname)               | string   | false    | `''`              | Azure resource group name for backend where the state is stored.                               |
| [BackendAzureStorageAccountName](#backendazurestorageaccountname)             | string   | false    | `''`              | Azure storage account name for backend where the state is stored.                              |
| [BackendAzureContainerName](#backendazurecontainername)                       | string   | false    | `''`              | Azure storage container name for backend where the state is stored.                            |
| [BackendAzureBlobName](#backendazureblobname)                                 | string   | false    | `''`              | Azure storage blob name for backend where the state is stored.                                 |
| [KeyVaultServiceConnection](#keyvaultserviceconnection)                       | string   | false    | `''`              | Service connection for key vault access secrets.                                               |
| [KeyVaultName](#keyvaultname)                                                 | string   | false    | `''`              | Name of key vault for accessing secrets.                                                       |
| [KeyVaultSecretsFilter](#keyvaultsecretsfilter)                               | string   | false    | `'*'`             | Filter for secrets to access from key vault.                                                   |
| [RunPlanOnly](#runplanonly)                                                   | boolean  | false    | `false`           | Whether only the terraform plan should be ran and no deployment made.                          |
| [VerificationMode](#verificationmode)                                         | string   | false    | `VerifyOnDestroy` | How verification step should trigger: verify on destruction changes; on any changes; or never. |
| [TerraformEnvironmentVariableMappings](#terraformenvironmentvariablemappings) | object   | false    | `{}`              | Environment variables to be passed to the task.                                                |
| [TerraformVariableFiles](#terraformvariablefiles)                             | object   | false    | `{}`              | List of .tfvars files to be supplied to the terraform commands.                                |
| [TerraformOutputVariables](#terraformoutputvariables)                         | object   | false    | `{}`              | List of variables to be exported from the terraform after apply has been ran.                  |

### Parameter Reference

#### PipelinePool

```yaml
PipelinePool: 'MyCustomPool'
```

#### RelativePathToTerraformFiles

```yaml
RelativePathToTerraformFiles: 'infrastructure/terraform'
```

#### TerraformVersion

```yaml
TerraformVersion: '1.6.0'
```

#### TerraformBuildInjectionSteps

```yaml
TerraformBuildInjectionSteps:
  - task: PowerShell@2
    displayName: 'Generate backend config'
    inputs:
      targetType: 'inline'
      script: |
        Write-Host "Generating backend configuration..."
```

#### AzDOEnvironmentName

```yaml
AzDOEnvironmentName: 'MyAzDOEnvironment'
```

#### AzureSubscriptionServiceConnection

```yaml
AzureSubscriptionServiceConnection: 'my-azure-service-connection'
```

#### DeploymentJobsVariableMappings

```yaml
DeploymentJobsVariableMappings:
  myVar: 'value'
  anotherVar: 'anotherValue'
```

#### BackendAzureServiceConnection

```yaml
BackendAzureServiceConnection: 'my-backend-service-connection'
```

#### BackendAzureResourceGroupName

```yaml
BackendAzureResourceGroupName: 'my-resource-group'
```

#### BackendAzureStorageAccountName

```yaml
BackendAzureStorageAccountName: 'mystorageaccount'
```

#### BackendAzureContainerName

```yaml
BackendAzureContainerName: 'mycontainer'
```

#### BackendAzureBlobName

```yaml
BackendAzureBlobName: 'terraform.tfstate'
```

#### KeyVaultServiceConnection

```yaml
KeyVaultServiceConnection: 'my-keyvault-service-connection'
```

#### KeyVaultName

```yaml
KeyVaultName: 'my-keyvault'
```

#### KeyVaultSecretsFilter

```yaml
KeyVaultSecretsFilter: 'mysecret*'
```

#### RunPlanOnly

```yaml
RunPlanOnly: true
```

#### VerificationMode

```yaml
VerificationMode: 'VerifyOnAny'
```

#### TerraformEnvironmentVariableMappings

```yaml
TerraformEnvironmentVariableMappings:
  ARM_CLIENT_ID: 'xxxx-xxxx-xxxx'
  ARM_CLIENT_SECRET: 'xxxx-xxxx-xxxx'
```

#### TerraformVariableFiles

```yaml
TerraformVariableFiles:
  - 'common.tfvars'
  - 'env-specific.tfvars'
```

#### TerraformOutputVariables

```yaml
TerraformOutputVariables:
  output1: 'value1'
  output2: 'value2'
```

---

## Advanced Usage

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
