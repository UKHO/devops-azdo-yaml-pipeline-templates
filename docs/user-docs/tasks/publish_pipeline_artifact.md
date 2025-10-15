# Task: Publish Pipeline Artifact

> **Source**: [../../tasks/publish_pipeline_artifact.yml](../../tasks/publish_pipeline_artifact.yml)
> **Type**: Task
> **Last Updated**: 2025-10-15

## Overview

Standardized wrapper for PublishPipelineArtifact@1 task that provides consistent artifact publishing functionality across pipelines. This task publishes build artifacts to Azure DevOps pipeline storage with support for parallel uploads and custom properties.

**Hidden Functionality**:

- Conditional parameter inclusion for optional properties
- Consistent naming patterns across all artifact publishing scenarios
- Automatic display name generation with artifact name
- Support for both pipeline and container publishing locations

## Quick Start

### Basic Usage

```yaml
- template: tasks/publish_pipeline_artifact.yml
  parameters:
    TargetPath: '$(Build.ArtifactStagingDirectory)'
    ArtifactName: 'MyArtifact'
```

### Required Parameters

| Parameter  | Type   | Required | Description                        |
|------------|--------|----------|------------------------------------|
| TargetPath | string | Yes*     | Path to files or folder to publish |

*Note: TargetPath has a default but should typically be specified for clarity*

## Parameters Reference

| Parameter       | Type    | Default                 | Description                                       |
|-----------------|---------|-------------------------|---------------------------------------------------|
| ArtifactName    | string  | 'drop'                  | Name of the artifact to publish                   |
| TargetPath      | string  | '$(Pipeline.Workspace)' | Path to files or folder to publish                |
| PublishLocation | string  | 'pipeline'              | Artifact publish location (pipeline or container) |
| Parallel        | boolean | false                   | Upload files in parallel                          |
| Properties      | string  | ''                      | Custom properties for the artifact                |

## Dependencies

This template wraps the Microsoft PublishPipelineArtifact@1 task and has no template dependencies.

## Advanced Examples

### Terraform Artifact Publishing

```yaml
- template: tasks/publish_pipeline_artifact.yml
  parameters:
    TargetPath: '$(Pipeline.Workspace)/terraform-configs'
    ArtifactName: 'TerraformArtifact'
    Parallel: true
```

### Multi-Artifact Publishing

```yaml
# Publish application artifacts
- template: tasks/publish_pipeline_artifact.yml
  parameters:
    TargetPath: '$(Build.ArtifactStagingDirectory)/app'
    ArtifactName: 'Application'

# Publish configuration artifacts
- template: tasks/publish_pipeline_artifact.yml
  parameters:
    TargetPath: '$(Build.ArtifactStagingDirectory)/config'
    ArtifactName: 'Configuration'
```

### Container Publishing with Properties

```yaml
- template: tasks/publish_pipeline_artifact.yml
  parameters:
    TargetPath: '$(Pipeline.Workspace)/deployment'
    ArtifactName: 'DeploymentScripts'
    PublishLocation: 'container'
    Properties: 'environment=production;version=$(Build.BuildNumber)'
    Parallel: true
```

### Large File Set with Parallel Upload

```yaml
- template: tasks/publish_pipeline_artifact.yml
  parameters:
    TargetPath: '$(Build.SourcesDirectory)/dist'
    ArtifactName: 'WebApplication'
    Parallel: true  # Improves performance for many files
```

## Parameter Details

### PublishLocation

**Supported Values**: pipeline, container

- **pipeline**: Publishes to Azure DevOps pipeline artifacts (default)
- **container**: Publishes to Azure DevOps container registry

```yaml
PublishLocation: 'pipeline'    # Standard pipeline artifacts
PublishLocation: 'container'   # Container registry publishing
```

### Parallel

When set to `true`, enables parallel file uploads for improved performance with large file sets:

```yaml
Parallel: false  # Sequential upload (default)
Parallel: true   # Parallel upload for better performance
```

### Properties

Custom key-value properties attached to the artifact for metadata purposes:

```yaml
Properties: 'key1=value1;key2=value2;version=$(Build.BuildNumber)'
```

Common property patterns:

- Version information: `version=$(Build.BuildNumber)`
- Environment targeting: `environment=production`
- Build metadata: `buildType=release;platform=x64`

## Notes

- Artifact names should be unique within a pipeline run
- TargetPath supports both files and directories
- Parallel uploads improve performance but may increase resource usage
- Published artifacts are available for download and use in subsequent stages
- Artifacts persist according to the project's retention policies

---

**Related Documentation**:

- [Terraform Build Job](../jobs/terraform_build.md) - Uses this task to publish terraform artifacts
- [Azure DevOps Artifacts Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/artifacts/) - Official artifact documentation
