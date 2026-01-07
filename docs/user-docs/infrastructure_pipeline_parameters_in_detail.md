# Template parameters in detail

## Full Parameter Table

| Parameter                                                                     | Type     | Required | Default           | Allowed values                                           | Compile Time Sensitive? | Description                                                                                                          |
|-------------------------------------------------------------------------------|----------|----------|-------------------|----------------------------------------------------------|-------------------------|----------------------------------------------------------------------------------------------------------------------|
| [PipelinePool](#pipelinepool)                                                 | string   |          | `'Mare Nectaris'` | Any                                                      |                         | The pool that the pipeline will run from the highest level.                                                          |
| [RelativePathToTerraformFiles](#relativepathtoterraformfiles)                 | string   |          | `''`              | Any                                                      |                         | Target Path to Terraform files (.tf,.tfvars) that require publishing as artifact.                                    |
| [TerraformVersion](#terraformversion)                                         | string   |          | `'1.14.x'`        | - `latest`<br> - valid version syntax                    |                         | Version of Terraform CLI tool to use with the terraform files.                                                       |
| [TerraformBuildInjectionSteps](#terraformbuildinjectionsteps)                 | stepList |          | `[]`              | Any valid steps                                          | ✔                       | Steps to be carried out before the terraform is init, validated, and packaged.                                       |
| [AzDOEnvironmentName](#azdoenvironmentname)                                   | string   | ❗        |                   | Any                                                      | ✔                       | AzDO Environment name to associate the deployment jobs to.                                                           |
| [AzureSubscriptionServiceConnection](#azuresubscriptionserviceconnection)     | string   | ❗        |                   | Any                                                      | ✔                       | Azure service connection for the azdo environment.                                                                   |
| [DeploymentJobsVariableMappings](#deploymentjobsvariablemappings)             | object   |          | `{}`              | See further documentation                                | ✔                       | Mapping of variables/groups/templates to be added to the job's variables block.                                      |
| [BackendAzureServiceConnection](#terraformbackendazure)                       | string   | ❗        |                   | Any                                                      | ✔                       | Azure service connection for backend where the state is stored.                                                      |
| [BackendAzureResourceGroupName](#terraformbackendazure)                       | string   | ❗        |                   | Any                                                      |                         | Azure resource group name for backend where the state is stored.                                                     |
| [BackendAzureStorageAccountName](#terraformbackendazure)                      | string   | ❗        |                   | Any                                                      |                         | Azure storage account name for backend where the state is stored.                                                    |
| [BackendAzureContainerName](#terraformbackendazure)                           | string   | ❗        |                   | Any                                                      |                         | Azure storage container name for backend where the state is stored.                                                  |
| [BackendAzureBlobName](#terraformbackendazure)                                | string   | ❗        |                   | Any                                                      |                         | Azure storage blob name for backend where the state is stored.                                                       |
| [KeyVaultServiceConnection](#keyvaultconfiguration)                           | string   |          | `''`              | Any                                                      | ✔                       | Service connection for key vault access secrets.                                                                     |
| [KeyVaultName](#keyvaultconfiguration)                                        | string   |          | `''`              | Any                                                      | ✔                       | Name of key vault for accessing secrets.                                                                             |
| [KeyVaultSecretsFilter](#keyvaultconfiguration)                               | string   |          | `'*'`             | Any                                                      | ✔                       | Filter for secrets to access from key vault.                                                                         |
| [RunPlanOnly](#runplanonly)                                                   | boolean  |          | `false`           | true \| false                                            | ✔                       | Whether only the terraform plan should be ran and no deployment made.                                                |
| [VerificationMode](#verificationmode)                                         | string   | ❗        |                   | - VerifyOnDestroy<br> - VerifyOnAny<br> - VerifyDisabled | ✔                       | How verification step should trigger: verify on destruction changes; verify on any changes; or do not verify at all. |
| [TerraformEnvironmentVariableMappings](#terraformenvironmentvariablemappings) | object   |          | `{}`              | See further documentation                                | ✔                       | Key/value pairs of environment variables to be passed to the task.                                                   |
| [TerraformVariableFiles](#terraformvariablefiles)                             | object   |          | `[]`              | See further documentation                                | ✔                       | List of .tfvars files to be supplied to the terraform commands.                                                      |
| [TerraformOutputVariables](#terraformoutputvariables)                         | object   |          | `[]`              | See further documentation                                | ✔                       | List of variables to be exported from the terraform after apply has been ran.                                        |

## Parameter Reference

Below are all the parameters to this template with further details.

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

### AzDOEnvironmentName

Specify the environment that Terraform is going to be deployed to.

```yaml
AzDOEnvironmentName: 'MyAzDOEnvironment'
```

Single environment limitation is not long-term.

### AzureSubscriptionServiceConnection

Specify the service connection that has permissions to the azure subscription.

```yaml
AzureSubscriptionServiceConnection: 'my-azure-service-connection'
```

Note: Can be the same as [BackendAzureServiceConnection](#terraformbackendazure).

### DeploymentJobsVariableMappings

Specify an object of variables for the deployment jobs.

```yaml
DeploymentJobsVariableMappings:
  myVar: 'value'
  anotherVar: 'anotherValue'
  group: aValidGroup
  template: aValidTemplate
```

The variables mappings will be unpacked in the following way:

1. Any key that is 'group' will have a `group:` added to the variables where the "group" is the key's value.
2. Any key that is 'template' will have a `template:` added to the variables where the "template" is the key's value.
3. All other values will be added in as `name: <key>\n value: <value>`

Currently, there is a limitation of group and template only being allowed to be defined once.

### TerraformBackendAzure

Define the required values for the pipeline to access the terraform state to the environment being deployed to.

```yaml
BackendAzureServiceConnection: 'my-backend-service-connection'
BackendAzureResourceGroupName: 'my-resource-group'
BackendAzureStorageAccountName: 'mystorageaccount'
BackendAzureContainerName: 'mycontainer'
BackendAzureBlobName: 'terraform.tfstate'
```

Note: `BackendAzureServiceConnection` can be the same service connection as [`AzureSubscriptionServiceConnection`](#azuresubscriptionserviceconnection)

### KeyVaultConfiguration

Define the optional values for the pipeline to access configuration from a key vault during the deployment of the terraform files.

```yaml
KeyVaultAzureSubscription: "MyAzureServiceConnection"
KeyVaultName: "my-key-vault"
KeyVaultSecretsFilter: "TERRAFORM-TENANT-ID,TERRAFORM-CLIENT-ID,TERRAFORM-CLIENT-SECRET,TERRAFORM-SUBSCRIPTION-ID,TERRAFORM-ACCESS-KEY"
```

You do not need to specify this if managing configuration by other means.

### RunPlanOnly

If you do not want to deploy any resources, you can run the plan only.

```yaml
RunPlanOnly: true
```

### VerificationMode

The pipeline will analyse the changes found in the plan and prompt manual verification depending on the mode that is set.

```yaml
VerificationMode: 'VerifyOnAny'
```

Options available are:

- VerifyOnDestroy
- VerifyOnAny
- VerifyDisabled

See [How does Infrastructure Manual Verification work?](infrastructure_pipeline_manual_verification.md)

### TerraformEnvironmentVariableMappings

Can provide a mapping of keys and values that get added to terraform as environment variables.

```yaml
TerraformEnvironmentVariableMappings:
  ARM_CLIENT_ID: 'xxxx-xxxx-xxxx'
  ARM_CLIENT_SECRET: 'xxxx-xxxx-xxxx'
```

### TerraformVariableFiles

Provide the terraform `.tfvars` files that are to be used with the terraform `.tf` files.

```yaml
TerraformVariableFiles:
  - 'common.tfvars'
  - 'env-specific.tfvars'
```

The pipeline will access these files from the terraform artifact created during the build stage. That stage packages all files found via
`RelativePathToTerraformFiles` parameter.

### TerraformOutputVariables

Specify the output variables from the terraform files that need to be available post deployment.

```yaml
TerraformOutputVariables:
  - output1
  - output2
```

To access the variables, see microsoft documentation [Set an output variable for use in future jobs](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/set-variables-scripts?view=azure-devops&tabs=powershell#set-an-output-variable-for-use-in-future-jobs).
