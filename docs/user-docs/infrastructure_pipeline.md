# Infrastructure Pipeline

A standardised infrastructure deployment pipeline template that uses terraform as the IaC tooling and Azure as the cloud provider. This pipeline will:

- Build/Validate/Package the terraform files
- Deploy the packaged terraform files to environments with a [manual verification gate](infrastructure_pipeline_manual_verification.md)

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
  template: pipelines/infrastructure_pipeline.yml@PipelineTemplates
  parameters:
    RelativePathToTerraformFiles: infra/webapp
    TerraformVersion: 1.09
    AzDOEnvironmentName: dev
    AzureSubscriptionServiceConnection: Pipeline-dev
    BackendAzureServiceConnection: Pipeline-dev
    BackendAzureResourceGroupName: m-project-rg
    BackendAzureStorageAccountName: projecttfsa
    BackendAzureContainerName: tfstate
    BackendAzureBlobName: example.tfstate
    VerificationMode: VerifyOnDestroy
    TerraformEnvironmentVariableMappings:
      TF_VAR_MinRandom: 1000
      TF_VAR_MaxRandom: 100000
    TerraformOutputVariables:
      - random_number
      - random_string
    TerraformVariableFiles:
      - config/common.tfvars
      - config/dev.tfvars
```

### Required Parameters

There are no required parameters, as each parameter has its own default value.

| Parameter | Type | Required | Default | Allowed values | Compile Time Sensitive? | Description |
|-----------|------|----------|---------|----------------|-------------------------|-------------|
|           |      |          |         |                |                         |             |

See [template parameters in details](infrastructure_pipeline_parameters_in_detail.md) for more information on the parameters.

## Advanced Usage

Listed below are possible advanced usages.

_If you have any advanced usages, please consider contributing them to the documentation._

### Custom Agent Pool

```yaml
extends:
  template: pipelines/infrastructure_pipeline.yml@templates
  parameters:
    PipelinePool: 'MyCustomPool'
    RelativePathToTerraformFiles: 'infrastructure/terraform'
    TerraformVersion: '1.6.0'
```

### Injection Step to add required_version

```yaml
extends:
  template: pipelines/infrastructure_pipeline.yml@PipelineTemplates
  parameters:
    RelativePathToTerraformFiles: infra/webapp
    PipelinePool: "Mare Nubium"
    TerraformVersion: 1.1.9
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
```
