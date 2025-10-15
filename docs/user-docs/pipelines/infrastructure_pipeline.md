# Pipeline: Infrastructure Pipeline

> **Source**: [../pipelines/infrastructure_pipeline.yml](../../../pipelines/infrastructure_pipeline.yml)
> **Type**: Pipeline
> **Last Updated**: 2025-10-15

## Overview

The Infrastructure Pipeline template provides a complete CI pipeline for Terraform-based infrastructure code. This pipeline orchestrates the terraform build process with configurable agent pools and supports custom build injection steps for enhanced validation and preprocessing.

**Hidden Functionality**:
- Sets pipeline-level variables from parameters for downstream usage
- Configures agent pool selection at the highest pipeline level
- Provides a complete CI pipeline focused solely on build/validation (no deployment)
- Uses "Mare Nectaris" as the default agent pool

## Quick Start

### Basic Usage

```yaml
# azure-pipelines.yml
trigger:
  - main

extends:
  template: pipelines/infrastructure_pipeline.yml
  parameters:
    RelativePathToTerraformFiles: 'infrastructure/terraform'
```

### Required Parameters

| Parameter                    | Type   | Required | Description                                                                      |
|------------------------------|--------|----------|----------------------------------------------------------------------------------|
| RelativePathToTerraformFiles | string | Yes      | Target Path to Terraform files (.tf,.tfvars) that require publishing as artifact |

## Parameters Reference

| Parameter                    | Type     | Default         | Description                                                                      |
|------------------------------|----------|-----------------|----------------------------------------------------------------------------------|
| PipelinePool                 | string   | "Mare Nectaris" | The pool that the pipeline will run from the highest level                       |
| RelativePathToTerraformFiles | string   | *Required*      | Target Path to Terraform files (.tf,.tfvars) that require publishing as artifact |
| TerraformVersion             | string   | 'latest'        | Version of Terraform CLI tool to use with the terraform files                    |
| TerraformBuildInjectionSteps | stepList | []              | Steps to be carried out before the terraform is init, validated, and packaged    |

## Dependencies

This template references the following templates:

- **[terraform_build](../stages/terraform_build.md)**: Complete terraform build stage → [terraform_build.yml](../../stages/terraform_build.yml)

## Advanced Examples

### Complete Infrastructure CI Pipeline

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - infrastructure/*

extends:
  template: pipelines/infrastructure_pipeline.yml
  parameters:
    PipelinePool: 'Self-Hosted-Linux'
    RelativePathToTerraformFiles: 'infrastructure/azure'
    TerraformVersion: '1.5.0'
    TerraformBuildInjectionSteps:
      - task: SonarCloudAnalyze@1
        displayName: 'Infrastructure Code Analysis'
        inputs:
          SonarCloud: 'SonarCloud-Connection'

      - script: |
          echo "Running infrastructure security scan"
          checkov -d infrastructure/ --framework terraform
        displayName: 'Security Validation'
```

### Multi-Environment Pipeline

```yaml
# azure-pipelines.yml
trigger:
  - main

extends:
  template: pipelines/infrastructure_pipeline.yml
  parameters:
    PipelinePool: 'Ubuntu-Latest'
    RelativePathToTerraformFiles: 'environments/$(Environment)'
    TerraformVersion: '1.4.6'
    TerraformBuildInjectionSteps:
      - script: |
          # Copy environment-specific variables
          cp environments/$(Environment)/$(Environment).tfvars terraform.tfvars
        displayName: 'Prepare Environment Configuration'

      - task: PowerShell@2
        displayName: 'Validate Environment Configuration'
        inputs:
          targetType: 'inline'
          script: |
            Write-Host "Validating $(Environment) environment configuration"
            # Add validation logic here
```

### Production Pipeline with Enhanced Validation

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - production-infrastructure/*

extends:
  template: pipelines/infrastructure_pipeline.yml
  parameters:
    PipelinePool: 'Production-Agents'
    RelativePathToTerraformFiles: 'production-infrastructure'
    TerraformVersion: '1.4.6'  # Pinned stable version
    TerraformBuildInjectionSteps:
      - task: AzureCLI@2
        displayName: 'Pre-deployment Validation'
        inputs:
          azureSubscription: 'Production-Service-Connection'
          scriptType: 'bash'
          scriptLocation: 'inlineScript'
          inlineScript: |
            echo "Validating production prerequisites"
            az account show

      - script: |
          echo "Running comprehensive terraform validation"
          terraform fmt -check=true -recursive
          terraform validate
        displayName: 'Terraform Format and Validate'

      - task: PublishTestResults@2
        displayName: 'Publish Validation Results'
        inputs:
          testResultsFormat: 'JUnit'
          testResultsFiles: '**/validation-results.xml'
        condition: always()
```

## Parameter Details

### PipelinePool

Specifies the Azure DevOps agent pool for pipeline execution:

```yaml
PipelinePool: 'Azure Pipelines'     # Microsoft-hosted agents
PipelinePool: 'Self-Hosted-Linux'   # Custom self-hosted pool
PipelinePool: 'Mare Nectaris'       # Default pool name
```

### TerraformBuildInjectionSteps

Custom steps executed within the terraform build workflow. These steps run at two points:
1. Before terraform initialization and validation
2. After workspace cleanup, before final artifact packaging

```yaml
TerraformBuildInjectionSteps:
  - script: |
      # Pre-build validation
      echo "Running custom infrastructure validation"
    displayName: 'Custom Validation'

  - task: AzureCLI@2
    displayName: 'Azure Environment Check'
    inputs:
      azureSubscription: 'ServiceConnection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az account show
        echo "Validated Azure connectivity"
```

## Pipeline Variables

The pipeline sets the following variables for use in downstream templates:

- **PipelinePool**: Agent pool selection propagated from parameters

## Notes

- This is a **CI-only pipeline** - it builds and validates but does not deploy infrastructure
- The pipeline uses the `extends` syntax, making it suitable as a base template for consumer pipelines
- Agent pool configuration applies to all stages and jobs within the pipeline
- All terraform build parameters are passed through to the underlying stage template
- The pipeline produces terraform artifacts that can be consumed by separate deployment pipelines

## Typical Usage Patterns

1. **Fork this pipeline** for infrastructure CI validation
2. **Combine with deployment pipeline** for complete CI/CD
3. **Use as PR validation** for infrastructure changes
4. **Integrate with branch policies** for automated validation

---

**Related Documentation**:
- [Terraform Build Stage](../stages/terraform_build.md) - The stage template used by this pipeline
- [Terraform Build Job](../jobs/terraform_build.md) - The underlying job implementation
- [Azure DevOps Extends Templates](https://docs.microsoft.com/en-us/azure/devops/pipelines/security/templates) - Template extension documentation
