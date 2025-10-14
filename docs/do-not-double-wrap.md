Some wrappers may be extensive in their parameters and initially it may make sense to write wrappers to the wrapper in order to create more concise templates to call, however this approach may not be a good idea. It introduces additional code that needs to be maintained, where there is extensions to the base file there will need to be more files to update as the spread of usage is unknown because there is abstraction of the templates usage by middle templates. An initial example of this would be `terraform_base.yml` that was written to wrap the TerraformTask@2, terraform itself have many different commands, such as init, validate, plan, deploy, and there were `terraform_init.yml` and `terraform_validate.yml` created to wrap those particular commands. For the validate command this was very minimal in the code:

```yaml
# Name: Terraform Validate
# Purpose: Wrapper for validate command using the terraform base file
# Azure DevOps Task: TerraformTask@5

steps:
  - template: terraform_base.yml
    parameters:
      Command: validate
```

While the init command it seemed more justified because the TerraformTask does not allow a `-backend=false` to be used without providing an service connection, which the providing of would defeat the point of `-backend=false`.

```yaml
# Name: Terraform Init
# Purpose: Wrapper for init command using the terraform base file
# Azure DevOps Task: TerraformTask@5

parameters:
  - name: BackendAzureServiceConnection
    type: string
    displayName: 'Azure service connection for backend'
    default: ''

  - name: BackendAzureStorageAccountResourceGroupName
    type: string
    displayName: 'Azure resource group name for storage account'
    default: ''

  - name: BackendAzureStorageAccountName
    type: string
    displayName: 'Azure storage account name for backend'
    default: ''

  - name: BackendAzureContainerName
    type: string
    displayName: 'Azure storage container name for backend'
    default: ''

  - name: BackendAzureBlobName
    type: string
    displayName: 'Azure storage blob name for state file'
    default: ''

  - name: DisableBackend
    type: boolean
    displayName: 'For whether to configure the backend or not'
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
        BackendAzureStorageAccountResourceGroupName: ${{ parameters.BackendAzureStorageAccountResourceGroupName }}
        BackendAzureStorageAccountName: ${{ parameters.BackendAzureStorageAccountName }}
        BackendAzureContainerName: ${{ parameters.BackendAzureContainerName }}
        BackendAzureBlobName: ${{ parameters.BackendAzureBlobName }}
```

This file wrapped the specific behaviour for the init without backend into the `terraform_init.yml` file. So it seemed justified.

However, a couple problems came to light:

1. Anyone using the `terraform_base.yml` file would not have the ability to use init without the backend, they would have to use the `terraform_init.yml` file.
2. Any changes to the `terraform_base.yml` would need to be applied to the two further wrapping files.
3. Files mostly exist to manage parameter passing and if new parameters are added into the **base** file then the double-wrappers would need updating as well.
4. One parameter that was not included was `WorkingDirectory` when testing the templates, it was found that the commands were not executing in the right directory. TerraformTask has a parameter for the working directory, but as was not calling the base file directly, the double-wrappers would need to be updated to call the parameter they weren't calling. So more parameter exposing when the parameter was already exposed in the base file.
5. The job arranging these tasks had less control over the tasks because some of their details were abstracted away, this left the job less detailed.

```yaml
jobs:
  - job: TerraformBuild
    variables:
      TargetPath: $(Build.SourcesDirectory)/${{ parameters.RelativePathToTerraformFiles }}
    workspace:
      clean: all
    displayName: "Terraform Build"
    steps:
      - checkout: self
        displayName: "Checkout self repository"

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

So a discussion was had with (@HugoBurgess) about this and another problem was revealed.

6. There was nothing to stop consumers of the repository to directly call the `terraform_base.yml` themselves. This would further make the other files redundant.

Therefore it was decided to drop the **base** file and its **double-wrappers** in favour of just using the single `terraform.yml` file. The extra init behaviour was then based into the single file where anyone wanting to use `terraform init -backend=false` would benefit.

The new job following this pattern gains extra information on how it is using the tasks and it is easier to add in additional parameters if needed.

```yaml
  - job: TerraformBuild
    variables:
      TargetPath: $(Build.SourcesDirectory)/${{ parameters.RelativePathToTerraformFiles }}
    workspace:
      clean: all
    displayName: "Terraform Build"
    steps:
      - checkout: self
        displayName: "Checkout self repository"

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
