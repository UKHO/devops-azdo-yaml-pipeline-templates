# Infrastructure Pipeline

A complete infrastructure deployment pipeline template using Terraform for building, validating, and packaging infrastructure-as-code (IaC) files. This pipeline provides a standardized approach for Terraform-based infrastructure deployments with built-in validation and artifact publishing capabilities.

# Important Notices

⚠️ **Terraform Backend Configuration**: This pipeline initialises Terraform with `-backend=false` to avoid backend configuration during the build phase. Ensure your deployment process handles backend configuration appropriately.

⚠️ **Clean Workspace Policy**: The pipeline performs a complete workspace clean-up after validation to ensure artifact purity. Any injection steps will be re-executed on clean code.

⚠️ **Pool Requirements**: The default pool "Mare Nectaris" must be available in your Azure DevOps organisation or specify an alternative pool.

# Basic Usage

## Example of Basic Usage

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

## Required Parameters

| Parameter                      | Description                                                                       |
|--------------------------------|-----------------------------------------------------------------------------------|
| `RelativePathToTerraformFiles` | Target path to Terraform files (.tf, .tfvars) that require publishing as artifact |

# Full Usage

## Full Parameter Table

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `PipelinePool` | string | `"Mare Nectaris"` | The pool that the pipeline will run from the highest level |
| `RelativePathToTerraformFiles` | string | *Required* | Target path to Terraform files (.tf, .tfvars) that require publishing as artifact |
| `TerraformVersion` | string | `'latest'` | Version of Terraform CLI tool to use with the terraform files |
| `TerraformBuildInjectionSteps` | stepList | `[]` | Steps to be carried out before the terraform is init, validated, and packaged |

### TerraformBuildInjectionSteps

This parameter allows you to inject custom steps that will be executed twice during the pipeline:
1. Before Terraform initialisation and validation
2. After workspace clean-up on clean code (before artifact publishing)

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

## Advanced Usage

### Custom Agent Pool

```yaml
extends:
  template: pipelines/infrastructure_pipeline.yml@templates
  parameters:
    PipelinePool: 'MyCustomPool'
    RelativePathToTerraformFiles: 'infrastructure/terraform'
    TerraformVersion: '1.6.0'
```

### Complex Injection Steps with File Operations

```yaml
extends:
  template: pipelines/infrastructure_pipeline.yml@templates
  parameters:
    RelativePathToTerraformFiles: 'terraform/environments/prod'
    TerraformBuildInjectionSteps:
      - task: PowerShell@2
        displayName: 'Setup environment variables'
        inputs:
          targetType: 'inline'
          script: |
            $env:TF_VAR_environment = "production"
            $env:TF_VAR_region = "$(Azure.Region)"

      - task: FileTransform@1
        displayName: 'Transform terraform.tfvars'
        inputs:
          folderPath: '$(Build.SourcesDirectory)/terraform/environments/prod'
          fileType: 'json'
          targetFiles: 'terraform.tfvars.json'

      - task: AzureCLI@2
        displayName: 'Generate backend configuration'
        inputs:
          azureSubscription: 'prod-service-connection'
          scriptType: 'bash'
          scriptLocation: 'inlineScript'
          inlineScript: |
            # Create backend.tf with storage account details
            cat > backend.tf << EOF
            terraform {
              backend "azurerm" {
                storage_account_name = "$(StorageAccountName)"
                container_name       = "terraform-state"
                key                 = "prod.terraform.tfstate"
              }
            }
            EOF
```

### Multi-Environment Setup

```yaml
# For multiple environments, you might use this pattern:
stages:
  - template: pipelines/infrastructure_pipeline.yml@templates
    parameters:
      RelativePathToTerraformFiles: 'terraform/environments/dev'
      TerraformVersion: '1.5.0'
      TerraformBuildInjectionSteps:
        - script: echo "Setting up dev environment"
          displayName: 'Dev setup'
```

### Pipeline Flow

1. **Repository Checkout**: Checks out the source repository to the build agent
2. **Injection Steps (First Run)**: Executes any custom steps provided via `TerraformBuildInjectionSteps`
3. **Terraform Installation**: Installs the specified version of Terraform CLI
4. **Terraform Init**: Initialises Terraform with backend disabled (`-backend=false`)
5. **Terraform Validate**: Validates the Terraform configuration files
6. **Workspace Clean-up**: Performs a clean checkout to ensure artifact purity
7. **Injection Steps (Second Run)**: Re-executes injection steps on clean code
8. **artifact Publishing**: Publishes the Terraform files as a pipeline artifact named "TerraformArtifact"

## Notes

- The pipeline produces a single artifact named "TerraformArtifact" containing all Terraform files from the specified path
- Injection steps are executed twice to ensure both validation accuracy and artifact completeness
- The pipeline does not perform Terraform deployment - it focuses solely on validation and packaging
- Consider using this pipeline in conjunction with deployment pipelines that consume the published artifact
- Terraform state management should be handled in downstream deployment processes
- The pipeline supports any Terraform version through the `TerraformVersion` parameter
