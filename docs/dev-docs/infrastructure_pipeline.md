# Infrastructure Pipeline definition

```yaml
parameters:
  PipelinePool: string # Defaults to 'Mare Nectaris'.
  RelativePathToTerraformFiles: string # Defaults to ''.
  TerraformBuildInjectionSteps: stepList # Defaults to [ ].
  TerraformVersion: string # Version of terraform that will be used. Defaults to 'latest'.
  RunPlanOnly: boolean # Whether to only run terraform plan in environments. Defaults to 'false'.
  Environments: [ Environment ] # Required. The different environments to deploy terraform files to.
```

## Properties

`PipelinePool` string.

`RelativePathToTerraformFiles` string.

`TerraformBuildInjectionSteps` stepList.

`TerraformVersion` string.

`RunPlanOnly` boolean.

`Environments` [environment](infrastructure_pipeline/environment.md)

