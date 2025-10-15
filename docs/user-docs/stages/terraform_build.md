# Stage: Terraform Build

> **Source**: [../../stages/terraform_build.yml](../../stages/terraform_build.yml)
> **Type**: Stage
> **Last Updated**: 2025-10-15

## Overview

The Terraform Build stage template orchestrates the build process for Terraform configurations by coordinating the terraform_build job. This stage provides a single-stage wrapper that handles Terraform validation, initialization, and artifact publishing within a structured pipeline stage.

**Hidden Functionality**:
- Creates a dedicated "Build" stage for clear pipeline visualization
- Passes through all parameters to the underlying terraform_build job
- Provides stage-level coordination for Terraform build processes

## Quick Start

### Basic Usage

```yaml
stages:
  - template: stages/terraform_build.yml
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
| RelativePathToTerraformFiles | string   | *Required*          | Target Path to Terraform files (.tf,.tfvars) that require publishing as artifact |
| TerraformVersion             | string   | 'latest'            | Version of Terraform CLI tool to use with the terraform files                    |
| TerraformBuildInjectionSteps | stepList | []                  | Steps to be carried out before the terraform is init, validated, and packaged    |

## Dependencies

This template references the following templates:

- **[terraform_build](../jobs/terraform_build.md)**: Executes the complete terraform build workflow → [terraform_build.yml](../../jobs/terraform_build.yml)

## Advanced Examples

### Multi-Environment Build Stage

```yaml
stages:
  - template: stages/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: 'environments/dev'
      ArtifactName: 'DevTerraformArtifact'
      TerraformVersion: '1.5.0'
      TerraformBuildInjectionSteps:
        - script: |
            echo "Preparing development environment terraform"
            cp environments/dev/dev.tfvars $(TerraformWorkingDirectory)/
          displayName: 'Prepare Dev Configuration'
```

### Build Stage with Custom Validation

```yaml
stages:
  - template: stages/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: 'src/infrastructure'
      ArtifactName: 'ProductionTerraform'
      TerraformVersion: '1.4.6'
      TerraformBuildInjectionSteps:
        - task: PowerShell@2
          displayName: 'Custom Terraform Linting'
          inputs:
            targetType: 'inline'
            script: |
              Write-Host "Running terraform fmt check"
              terraform fmt -check=true -recursive

        - script: |
            echo "Running security validation"
            checkov -d . --framework terraform
          displayName: 'Security Validation'
```

### Production Build Pipeline

```yaml
stages:
  - template: stages/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: 'infrastructure/production'
      ArtifactName: 'ProdTerraformInfrastructure'
      TerraformVersion: '1.4.6'  # Stable version for production
      TerraformBuildInjectionSteps:
        - task: SonarCloudAnalyze@1
          displayName: 'SonarCloud Analysis'
          inputs:
            SonarCloud: 'SonarCloud-Connection'

        - script: |
            # Generate production-specific terraform.tfvars
            echo 'environment = "production"' > terraform.tfvars
            echo 'instance_count = 3' >> terraform.tfvars
          displayName: 'Generate Production Variables'
```

## Parameter Details

### TerraformBuildInjectionSteps

Custom steps executed within the terraform build job at two points in the workflow:
1. Before terraform initialization and validation
2. After workspace cleanup, before final artifact packaging

```yaml
TerraformBuildInjectionSteps:
  - script: |
      # Pre-validation steps
      echo "Preparing terraform configuration"
    displayName: 'Pre-Validation Setup'

  - task: PowerShell@2
    displayName: 'Generate Dynamic Configuration'
    inputs:
      targetType: 'inline'
      script: |
        # Generate environment-specific settings
        Write-Host "Creating dynamic terraform configuration"
```

## Notes

- This stage template provides a single-stage wrapper around the terraform_build job
- All parameters are passed directly to the underlying job template
- The stage is named "Build" and will appear as such in Azure DevOps pipeline visualization
- Can be combined with other stages (e.g., terraform_deploy) for complete infrastructure pipelines
- Maintains the same parameter interface as the terraform_build job for consistency

---

**Related Documentation**:
- [Terraform Build Job](../jobs/terraform_build.md) - The job template used by this stage
- [Terraform Deploy Stage](terraform_deploy.md) - Companion deployment stage
- [Infrastructure Pipeline](../pipelines/infrastructure_pipeline.md) - Complete pipeline using this stage
