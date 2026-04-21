# Terraform Build Job

A job template that builds, validates, and packages Terraform infrastructure-as-code files for deployment. This job performs all pre-deployment validation and creates an artifact containing the validated Terraform files ready for use in deployment stages.

## Overview

The Terraform Build Job:

- Checks out the repository containing Terraform files
- Installs the specified version of Terraform CLI
- Initializes Terraform (without backend) to validate configuration
- Validates the Terraform configuration for syntax and semantic errors
- Packages validated Terraform files and any additional files into a pipeline artifact
- Optionally executes custom build injection steps before Terraform operations

## Important Notices

### Workspace Cleanup

The job uses `workspace: clean: all` to ensure a clean build environment each time. This removes all files from previous builds to prevent stale artifacts or configuration from affecting the build.

### Backend Configuration

The `terraform init` command runs with `-backend=false` to validate the Terraform files without requiring actual backend connectivity. This allows the build stage to complete independently of deployed infrastructure environments.

### Custom Build Steps

If you need to execute custom build logic (e.g., generating files, running linters, or modifying Terraform files), use the `TerraformBuildInjectionSteps` parameter to inject steps before Terraform operations.

## Basic Usage

### Minimal Example

```yaml
- template: jobs/terraform_build.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infra/terraform'
    ArtifactName: 'TerraformArtifact'
```

### Example with Custom Terraform Version

```yaml
- template: jobs/terraform_build.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infra/webapp'
    ArtifactName: 'WebAppTerraform'
    TerraformVersion: '1.9.0'
```

### Example with Additional Files to Package

```yaml
- template: jobs/terraform_build.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infra/terraform'
    ArtifactName: 'TerraformArtifact'
    AdditionalFilesToPackage:
      - SourceDirectory: 'deployment'
        FilesPattern: '**/*.sh'
        TargetSubdirectoryName: 'scripts'
      - SourceDirectory: 'config'
        FilesPattern: 'terraform.tfvars'
        TargetSubdirectoryName: 'config'
```

### Example with Build Injection Steps

```yaml
- template: jobs/terraform_build.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infra/terraform'
    ArtifactName: 'TerraformArtifact'
    TerraformBuildInjectionSteps:
      - task: PowerShell@2
        displayName: 'Generate Terraform Files'
        inputs:
          targetType: 'filePath'
          filePath: '$(Build.SourcesDirectory)/scripts/generate-tf.ps1'
      - script: 'echo "Pre-build validation complete"'
        displayName: 'Pre-build Validation'
```

## Full Parameter Table

| Parameter Name                 | Type     | Required | Default               | Description                                                                                                                                                                             |
|--------------------------------|----------|----------|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ArtifactName`                 | string   | No       | `'TerraformArtifact'` | Name for the published artifact containing validated Terraform files. Used to reference this artifact in deployment jobs.                                                               |
| `RelativePathToTerraformFiles` | string   | No       | `''`                  | Relative path from the repository root to the directory containing Terraform configuration files (.tf, .tfvars). Leave empty if Terraform files are at the repository root.             |
| `TerraformVersion`             | string   | No       | `'1.14.0'`            | Version of Terraform CLI to install and use for initialization and validation. Must be a valid Terraform version number.                                                                |
| `AdditionalFilesToPackage`     | object   | No       | `[]`                  | List of additional files/directories to include in the artifact beyond the Terraform files. Each entry should specify: `SourceDirectory`, `FilesPattern`, and `TargetSubdirectoryName`. |
| `TerraformBuildInjectionSteps` | stepList | No       | `[]`                  | Custom pipeline steps to execute before Terraform init and validate. Useful for generating files, running linters, or other pre-build operations.                                       |

## Advanced Usage

### Pre-Build File Generation

Use `TerraformBuildInjectionSteps` to dynamically generate Terraform configuration files before validation:

```yaml
- template: jobs/terraform_build.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infra/terraform'
    ArtifactName: 'TerraformArtifact'
    TerraformBuildInjectionSteps:
      - script: |
          $config = @{
            environment = '$(Build.SourceBranchName)'
            buildNumber = '$(Build.BuildNumber)'
          }
          $config | ConvertTo-Json | Set-Content infra/terraform/build-config.tfvars.json
        displayName: 'Generate Build Configuration'
        shell: pwsh
```

### Multiple Artifact Outputs

For projects with multiple Terraform modules, run the job multiple times with different configurations:

```yaml
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml@AzDOPipelineTemplates
        parameters:
          RelativePathToTerraformFiles: 'infra/app'
          ArtifactName: 'AppTerraform'
          TerraformVersion: '1.9.0'

      - template: jobs/terraform_build.yml@AzDOPipelineTemplates
        parameters:
          RelativePathToTerraformFiles: 'infra/networking'
          ArtifactName: 'NetworkTerraform'
          TerraformVersion: '1.9.0'
```

### Packaging Supporting Scripts

Include deployment helper scripts in the artifact for use during apply:

```yaml
- template: jobs/terraform_build.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: 'infra/terraform'
    ArtifactName: 'TerraformArtifact'
    AdditionalFilesToPackage:
      - SourceDirectory: 'scripts'
        FilesPattern: '*.ps1'
        TargetSubdirectoryName: 'deployment-scripts'
      - SourceDirectory: 'templates'
        FilesPattern: 'arm-*.json'
        TargetSubdirectoryName: 'templates'
```

## Artifact Contents

The published artifact contains:

- All `.tf` files from `RelativePathToTerraformFiles`
- All `.tfvars` files from `RelativePathToTerraformFiles`
- All `.tfvars.json` files from `RelativePathToTerraformFiles`
- Additional files specified in `AdditionalFilesToPackage` in their configured subdirectories