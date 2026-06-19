# KeyVaultConfigs

## Definition

```yaml
KeyVaultConfigs:
  - Name: string
    ServiceConnection: string
    SecretsFilter: string
    RunAsPreJob: boolean
```

## Array Entry Definitions

### Name

**Type:** `string`

**Required:** Yes

**Definition:** The Azure Key Vault name.

### ServiceConnection

**Type:** `string`

**Required:** Yes

**Definition:** The Azure Resource Manager service connection used to access the Key Vault.

### SecretsFilter

**Type:** `string`

**Required:** No

**Default:** `'*'`

**Definition:** Filter for secrets to retrieve. Use `'*'` to retrieve all secrets.

### RunAsPreJob

**Type:** `boolean`

**Required:** No

**Default:** `false`

**Definition:** When `true`, runs the Key Vault task before other tasks in the same job.

## Rules

- `KeyVaultConfig` and `KeyVaultConfigs` cannot be used together in the same `TerraformDeploymentConfig`.
- Each `KeyVaultConfigs` entry must include `Name` and `ServiceConnection`.
- `KeyVaultConfigs` entries run in the order listed.
- An empty `KeyVaultConfigs` array is invalid.

## See Also

- [Upgrade Guide: 0.1.0 → 0.2.0](../../user-docs/upgrades/0.1.0-to-0.2.0-keyvaultconfig-to-keyvaultconfigs.md)
- [Key Vault Configs Task List](../../user-docs/shared/key_vault_configs_task_list.md)
- [TerraformDeploymentConfig](../terraform_pipeline/terraform_deployment_config.md)
