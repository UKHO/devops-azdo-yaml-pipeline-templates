# Terraform Destroy Job

A reusable job template for Terraform destroy execution. The template supports a destroy plan step or a direct destroy step against the published Terraform artifact.

## When to Use

Use this job template when you need to:

- Create a Terraform destroy plan without executing deletion.
- Execute Terraform destroy directly.
- Build custom workflow orchestration around destroy operations.

## What This Job Does

### Plan Mode

1. Downloads Terraform artifact from the build job.
2. Runs `terraform init`.
3. Runs `terraform plan -destroy`.

### Destroy Mode

1. Downloads Terraform artifact from the build job.
2. Runs `terraform init`.
3. Runs `terraform apply -destroy -auto-approve`.

## Basic Usage

### Plan Destroy

```yaml
jobs:
  - template: jobs/terraform_destroy.yml
    parameters:
      TerraformDestroyMode: Plan
      EnvironmentName: dev
      TerraformDestroyConfig:
        AzDOEnvironmentName: dev-environment
```

### Destroy

```yaml
jobs:
  - template: jobs/terraform_destroy.yml
    parameters:
      TerraformDestroyMode: Destroy
      EnvironmentName: dev
      TerraformDestroyConfig:
        AzDOEnvironmentName: dev-environment
```

## Parameters

### Required Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `EnvironmentName` | string | Environment identifier (for naming and validation context) |
| `TerraformDestroyConfig` | object | Destroy configuration object |

### Optional Parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `TerraformDestroyMode` | string | `Plan` | `Plan` or `Destroy` |
| `TerraformVersion` | string | `1.14.0` | Terraform CLI version |
| `TerraformArtifactName` | string | `TerraformArtifact` | Artifact name to download |
| `Pool` | string | `''` | Agent pool for the deployment job |
| `DependsOn` | object | `[ ]` | Job dependencies |
| `Condition` | string | `succeeded()` | Job condition |

## TerraformDestroyConfig

| Property | Type | Required | Description |
| --- | --- | --- | --- |
| `AzDOEnvironmentName` | string | Yes | Azure DevOps environment name |
| `BackendConfig` | object | No | Backend key-value mappings |
| `AzureServiceConnection` | string | No | Azure service connection |
| `ConfigSources` | list | No | Ordered config source list |
| `JobsVariableMappings` | object | No | Variable groups/templates/inline mappings |
| `EnvironmentVariableMappings` | object | No | Task environment variables |
| `VariableFiles` | list | No | `.tfvars` files relative to artifact root |

`KeyVaultConfig` is not supported in destroy workflows.

## Notes

- Destroy execution is artifact-based; this job does not checkout repositories.
- Ensure the build job packages all required Terraform files and variable files.

## Live Examples

- [`tests/jobs/terraform_destroy/plan_only_test.yml`](../../../tests/jobs/terraform_destroy/plan_only_test.yml)
- [`tests/jobs/terraform_destroy/destroy_only_test.yml`](../../../tests/jobs/terraform_destroy/destroy_only_test.yml)
- [`tests/jobs/terraform_destroy/destroy_with_configsources_test.yml`](../../../tests/jobs/terraform_destroy/destroy_with_configsources_test.yml)
- [`tests/jobs/terraform_destroy/plan_with_variable_files_test.yml`](../../../tests/jobs/terraform_destroy/plan_with_variable_files_test.yml)

## Related Links

- [Terraform Gated Destroy Job](./terraform_gated_destroy.md) – orchestrated destroy workflow with manual approval, built on this job
- [Terraform Build Job](./terraform_build.md) – creates the artifact this job downloads


