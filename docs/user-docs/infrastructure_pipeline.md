# Infrastructure Pipeline

A standardised infrastructure deployment pipeline template that uses terraform as the IaC tooling and Azure as the cloud provider. This pipeline will:

- Build/Validate/Package the terraform files
- Deploy the packaged terraform files to environments with a [manual verification gate](infrastructure_pipeline_manual_verification.md)

## Important

**Repository Resource Requirement**: The pipeline requires access to this template repository during execution. You **must** define the repository resource with the name `AzDOPipelineTemplates` (as shown in the example above) because the pipeline internally checks out this repository to access helper scripts during the deployment stage.

Pool Requirements: The default pool "Mare Nectaris" must be available in your Azure DevOps organisation or specify an alternative pool.

Terraform Workspace: This command is not currently available.

Snyk Scanning: This is not currently part of the pipeline.

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

The following parameters **must** be provided as they have no default values:

| Parameter                          | Type   | Description                                                                           |
|------------------------------------|--------|---------------------------------------------------------------------------------------|
| AzDOEnvironmentName                | string | AzDO Environment name to associate the deployment jobs to                             |
| AzureSubscriptionServiceConnection | string | Azure service connection for the azdo environment                                     |
| BackendAzureServiceConnection      | string | Azure service connection for backend where the state is stored                        |
| BackendAzureResourceGroupName      | string | Azure resource group name for backend where the state is stored                       |
| BackendAzureStorageAccountName     | string | Azure storage account name for backend where the state is stored                      |
| BackendAzureContainerName          | string | Azure storage container name for backend where the state is stored                    |
| BackendAzureBlobName               | string | Azure storage blob name for backend where the state is stored                         |
| VerificationMode                   | string | How verification step should trigger: VerifyOnDestroy, VerifyOnAny, or VerifyDisabled |

See [template parameters in details](infrastructure_pipeline_parameters_in_detail.md) for more information on all parameters.

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

## Troubleshooting

### Manual verification not triggering

**Issue**: Manual verification gate doesn't appear even when changes are detected.

**Check**:
- Verify `RunPlanOnly` is set to `false` (or not set, as default is `false`)
- Verify `VerificationMode` is set to either `VerifyOnAny` or `VerifyOnDestroy` (not `VerifyDisabled`)
- Check the plan output to ensure changes were actually detected

### Output variables not available in subsequent stages/jobs

**Cause**: Output variables from Terraform are only available after the Apply job completes and are scoped to the deployment job.

**Solution**: To use Terraform output variables in subsequent stages or jobs outside the infrastructure pipeline, you'll need to:
1. Ensure the variables are listed in `TerraformOutputVariables` parameter
2. Reference them using the correct dependency syntax: `dependencies.TerraformDeploy_Apply.outputs['TerraformDeploy_Apply.TerraformExportOutputsVariables.{variableName}']`
3. Note: Variables are only exported when `RunPlanOnly` is `false` and the apply job runs successfully

### Incorrect Terraform version being used

**Solution**: Explicitly set the `TerraformVersion` parameter. The default is `1.14.x` which installs the latest patch version of 1.14.

## Template Breakdown

For a complete breakdown of all templates, scripts, and execution flows used by this pipeline, see:

**[Infrastructure Pipeline - Template Breakdown](infrastructure_pipeline_template_breakdown.md)**

This includes:
- Visual pipeline structure
- All stages, jobs, tasks, utilities, and scripts
- Template relationships and execution order
- Customisation points
- Mermaid diagrams of execution flows

