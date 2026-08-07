# TerraformDestroyConfig

The configuration object that defines how Terraform destroy workflows run in a target Azure DevOps environment.

## Definition

```yaml
TerraformDestroyConfig:
  AzDOEnvironmentName: string                   # REQUIRED
  RunMode: string                               # REQUIRED (PlanVerifyDestroy | PlanOnly | DestroyOnly)
  BackendConfig: object                         # OPTIONAL
  AzureServiceConnection: string                # OPTIONAL
  ConfigSources:                                # OPTIONAL (array-based)
    - Type: string                              # OPTIONAL ('KeyVault')
      ServiceConnection: string
      Name: string
      SecretsFilter: string
      RunAsPreJob: boolean
  JobsVariableMappings: object                  # OPTIONAL
  EnvironmentVariableMappings: object           # OPTIONAL
  VariableFiles: list                           # OPTIONAL
  ManualVerificationConfig: object              # OPTIONAL (only used when RunMode is PlanVerifyDestroy)
```

## Required Properties

### AzDOEnvironmentName

**Type:** `string`

**Description:** Azure DevOps environment used by the destroy deployment job.

### RunMode

**Type:** `string`

**Allowed Values:**

- `'PlanVerifyDestroy'` - Runs destroy plan, always requires manual verification, then runs destroy.
- `'PlanOnly'` - Runs destroy plan only.
- `'DestroyOnly'` - Runs destroy directly without plan or manual verification.

## Optional Properties

### BackendConfig

**Type:** `object`

**Description:** Key-value pairs passed to `terraform init` as `-backend-config` options.

### AzureServiceConnection

**Type:** `string`

**Description:** Azure service connection used for authenticated Terraform execution.

### ConfigSources

**Type:** `list` of `object`

**Description:** Ordered list of configuration sources used before Terraform execution. This workflow supports `Type: KeyVault` entries.

### JobsVariableMappings

**Type:** `object`

**Description:** Variable groups, templates, or inline variable mappings added to the job variables block.

### EnvironmentVariableMappings

**Type:** `object`

**Description:** Environment variables passed to Terraform tasks.

### VariableFiles

**Type:** `list` of `string`

**Description:** List of `.tfvars` files relative to the artifact root.

### ManualVerificationConfig

**Type:** `object`

**Description:** Optional configuration for the manual verification gate inserted when `RunMode` is
`PlanVerifyDestroy`. If provided, `TimeoutInMinutes` is required. `Instructions` defaults to a destroy-specific
message and `OnTimeoutBehaviour` defaults to `reject` when omitted. See
[ManualVerificationConfig](./manual_verification_config.md) for full details.

Has no effect for `PlanOnly` or `DestroyOnly` run modes, since no manual verification job is inserted in those
modes.

## Not Supported in Destroy Config

- `KeyVaultConfig` is deprecated and not supported in destroy workflows.
- `VerificationMode` is not supported; use run mode `PlanVerifyDestroy` for gated flows.

## Examples

### PlanVerifyDestroy

```yaml
TerraformDestroyConfig:
  AzDOEnvironmentName: production-environment
  RunMode: PlanVerifyDestroy
  AzureServiceConnection: AzureServiceConnection-Production
  BackendConfig:
    resource_group_name: rg-terraform-state-prod
    storage_account_name: sttfstateprod
    container_name: tfstate
    key: production.terraform.tfstate
  ConfigSources:
    - Type: KeyVault
      Name: kv-production-secrets
      ServiceConnection: AzureServiceConnection-Production
      SecretsFilter: '*'
  VariableFiles:
    - config/common.tfvars
    - config/production.tfvars
```

### DestroyOnly

```yaml
TerraformDestroyConfig:
  AzDOEnvironmentName: dev-environment
  RunMode: DestroyOnly
  AzureServiceConnection: AzureServiceConnection-Dev
```

## Related Tests

- [`jobs/terraform_destroy.CompileTests.ps1`](../../../jobs/terraform_destroy.CompileTests.ps1)
- [`jobs/terraform_gated_destroy.CompileTests.ps1`](../../../jobs/terraform_gated_destroy.CompileTests.ps1)
- [`schemas/terraform_destroy_config.CompileTests.ps1`](../../../schemas/terraform_destroy_config.CompileTests.ps1)

## See Also

- [Terraform Destroy Job](../../user-docs/jobs/terraform_destroy.md)
- [Terraform Gated Destroy Job](../../user-docs/jobs/terraform_gated_destroy.md)
