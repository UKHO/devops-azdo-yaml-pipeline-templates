# Job: Terraform Build

> **Source**: [../../jobs/terraform_build.yml](../../jobs/terraform_build.yml)
> **Type**: Job
> **Last Updated**: 2025-10-15

## Overview

The Terraform Build job template provides a standardized workflow for building, validating, and packaging Terraform configurations as pipeline artifacts. This job performs terraform initialization, validation, and artifact publishing while supporting custom injection steps for additional build requirements.

**Hidden Functionality**:

- Performs `terraform validate` command to ensure Terraform files are syntactically correct
- Executes injection steps twice: once before validation and again on clean code
- Automatically handles workspace cleanup between validation and final packaging

## Quick Start

### Basic Usage

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: 'infrastructure/terraform'
      ArtifactName: 'MyTerraformArtifact'
```

### Required Parameters

| Parameter                    | Type   | Required | Description                                                                      |
|------------------------------|--------|----------|----------------------------------------------------------------------------------|
| RelativePathToTerraformFiles | string | Yes      | Target Path to Terraform files (.tf,.tfvars) that require publishing as artifact |

## Parameters Reference

| Parameter                    | Type     | Default             | Description                                                                      |
|------------------------------|----------|---------------------|----------------------------------------------------------------------------------|
| ArtifactName                 | string   | 'TerraformArtifact' | Artifact Name for Target Path to be saved as                                     |
| RelativePathToTerraformFiles | string   | ''                  | Target Path to Terraform files (.tf,.tfvars) that require publishing as artifact |
| TerraformVersion             | string   | 'latest'            | Version of Terraform CLI tool to use with the terraform files                    |
| TerraformBuildInjectionSteps | stepList | []                  | Steps to be carried out before the terraform is init, validated, and packaged    |

## Dependencies

This template references the following templates:

- **[terraform_installer](../tasks/terraform_installer.md)**: Installs the specified version of Terraform CLI → [terraform_installer.yml](../../tasks/terraform_installer.yml)
- **[terraform](../tasks/terraform.md)**: Executes terraform commands (init, validate) → [terraform.yml](../../tasks/terraform.yml)
- **[publish_pipeline_artifact](../tasks/publish_pipeline_artifact.md)**: Publishes terraform files as pipeline artifact → [publish_pipeline_artifact.yml](../../tasks/publish_pipeline_artifact.yml)

## Advanced Examples

### With Custom Build Steps

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: 'src/infrastructure'
      TerraformVersion: '1.5.0'
      ArtifactName: 'ProductionTerraform'
      TerraformBuildInjectionSteps:
        - script: |
            echo "Running custom validation scripts"
            ./scripts/validate-terraform-naming.ps1
          displayName: 'Custom Terraform Validation'
        - task: SonarCloudAnalyze@1
          displayName: 'SonarCloud Analysis'
```

### Multi-Environment Configuration

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: 'environments/dev'
      ArtifactName: 'DevEnvironmentTerraform'
      TerraformBuildInjectionSteps:
        - script: |
            cp environments/dev/dev.tfvars $(TerraformWorkingDirectory)/terraform.tfvars
          displayName: 'Copy Development Variables'

  - template: jobs/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: 'environments/prod'
      ArtifactName: 'ProdEnvironmentTerraform'
      TerraformVersion: '1.4.6'  # Use stable version for production
```

## Parameter Details

### TerraformBuildInjectionSteps

Custom steps that are executed at two points in the job workflow:

1. Before terraform initialization and validation
2. After workspace cleanup, before final artifact packaging

This allows for custom validation, file manipulation, or analysis steps while ensuring they run on clean code.

```yaml
TerraformBuildInjectionSteps:
  - script: |
      # Custom validation or setup steps
      echo "Validating terraform configuration"
    displayName: 'Custom Validation'

  - task: PowerShell@2
    displayName: 'Generate terraform.tfvars'
    inputs:
      targetType: 'inline'
      script: |
        # Generate dynamic configuration
        Write-Host "Generating environment-specific variables"
```

## Notes

- The job performs workspace cleanup between validation and packaging to ensure artifact integrity
- Terraform backend is disabled during validation (`-backend=false` flag)
- The working directory is automatically set based on the repository name and relative path
- All terraform files (.tf, .tfvars) in the specified path are included in the artifact

---

**Related Documentation**:

- [Terraform Task](../tasks/terraform.md) - Core terraform command execution
- [Terraform Deploy Stage](../stages/terraform_deploy.md) - Deployment workflows using this job
