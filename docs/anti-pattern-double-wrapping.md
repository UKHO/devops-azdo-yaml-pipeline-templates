Some pipeline templates may initially seem to benefit from additional wrapper templates to simplify usage or parameter passing. However, introducing multiple layers of wrappers—referred to here as **base wrappers** and **secondary wrappers**—can lead to maintenance challenges and unnecessary complexity.

For example, consider the use of a `terraform_base.yml` template wrapping the `TerraformTask@2`. To simplify specific commands, secondary wrappers like `terraform_init.yml` and `terraform_validate.yml` were created:

```yaml
# terraform_validate.yml
# Purpose: Secondary wrapper for the validate command using the base wrapper
steps:
  - template: terraform_base.yml
    parameters:
      Command: validate
```

The `terraform_init.yml` secondary wrapper was more justified, as it handled a special case where `terraform init -backend=false` required no service connection:

```yaml
# terraform_init.yml
parameters:
  - name: BackendAzureServiceConnection
    type: string
    default: ''
  # ... other backend parameters ...
  - name: DisableBackend
    type: boolean
    default: false

steps:
  - ${{ if eq(parameters.DisableBackend, true) }}:
    - script: |
        terraform init -backend=false
  - ${{ else }}:
    - template: terraform_base.yml
      parameters:
        Command: init
        BackendAzureServiceConnection: ${{ parameters.BackendAzureServiceConnection }}
        # ... other backend parameters ...
```

While this approach seemed reasonable, several problems emerged:

1. Users of the `terraform_base.yml` base wrapper could not access the special `init` behavior without using the secondary wrapper.
2. Any changes to the base wrapper required updates to all secondary wrappers.
3. Secondary wrappers mainly managed parameter passing, so new parameters in the base wrapper required updates across all wrappers.
4. Some parameters, like `WorkingDirectory`, were not exposed in secondary wrappers, causing issues and requiring further updates.
5. The job configuration lost transparency and control, as details were abstracted away by multiple wrapper layers.

Example job using secondary wrappers:

```yaml
jobs:
  - job: TerraformBuild
    variables:
      TargetPath: $(Build.SourcesDirectory)/${{ parameters.RelativePathToTerraformFiles }}
    steps:
      - checkout: self
      - template: ../tasks/terraform_installer.yml
        parameters:
          TerraformVersion: ${{ parameters.TerraformVersion }}
      - template: ../tasks/terraform_init.yml
        parameters:
          DisableBackend: true
      - template: ../tasks/terraform_validate.yml
      - template: ../tasks/publish_pipeline_artifact.yml
        parameters:
          TargetPath: ${{ variables.TargetPath }}
          ArtifactName: ${{ parameters.ArtifactName }}
```

Another issue was that consumers could bypass secondary wrappers and use the base wrapper directly, making the extra templates redundant.

To resolve these issues, the team decided to eliminate both base and secondary wrappers in favor of a single, comprehensive `terraform.yml` template. This unified template incorporated all necessary logic, including the special `init` behavior, making it easier to maintain and extend.

Example job using the unified template:

```yaml
  - job: TerraformBuild
    variables:
      TargetPath: $(Build.SourcesDirectory)/${{ parameters.RelativePathToTerraformFiles }}
    steps:
      - checkout: self
      - template: ../tasks/terraform_installer.yml
        parameters:
          TerraformVersion: ${{ parameters.TerraformVersion }}
      - template: ../tasks/terraform.yml
        parameters:
          Command: init
          DisableBackend: true
          WorkingDirectory: ${{ variables.TargetPath }}
      - template: ../tasks/terraform.yml
        parameters:
          Command: validate
          WorkingDirectory: ${{ variables.TargetPath }}
      - template: ../tasks/publish_pipeline_artifact.yml
        parameters:
          TargetPath: ${{ variables.TargetPath }}
          ArtifactName: ${{ parameters.ArtifactName }}
```

This approach improves maintainability, transparency, and extensibility, while preserving the benefits of the original examples.
