# Key Vault Configs Task List

Reusable utility template for generating `AzureKeyVault@2` tasks from a `KeyVaultConfigs` array.

## Examples

### Single Key Vault

```yaml
- template: utils/key_vault_configs_task_list.yml
  parameters:
    KeyVaultConfigs:
      - Name: 'my-vault'
        ServiceConnection: 'Azure-SC'
        SecretsFilter: 'app-*'
```

### Multiple Key Vaults

```yaml
- template: utils/key_vault_configs_task_list.yml
  parameters:
    KeyVaultConfigs:
      - Name: 'shared-vault'
        ServiceConnection: 'Azure-Prod-SC'
        SecretsFilter: 'shared-*'
      - Name: 'app-vault'
        ServiceConnection: 'Azure-Prod-SC'
        SecretsFilter: 'app-*'
      - Name: 'database-vault'
        ServiceConnection: 'Azure-Prod-SC'
        SecretsFilter: 'db-*'
```

### Mixed `RunAsPreJob`

```yaml
- template: utils/key_vault_configs_task_list.yml
  parameters:
    KeyVaultConfigs:
      - Name: 'common-vault'
        ServiceConnection: 'Azure-SC'
        RunAsPreJob: true
      - Name: 'deployment-vault'
        ServiceConnection: 'Azure-SC'
        RunAsPreJob: false
```

## How secrets are exposed

Secrets retrieved from each Key Vault are mapped to pipeline variables with the same name as the secret.

```yaml
# If the Key Vault contains these secrets:
# - db-connection-string
# - api-key

steps:
  - script: |
      echo $(db-connection-string)
      echo $(api-key)
```

## Notes

- `RunAsPreJob: true` means the Key Vault task runs before other tasks in the same job.
- `SecretsFilter` defaults to `'*'` when omitted.
- Entries run in the order listed.

## See Also

- [KeyVaultConfigs Definition](../../definition_docs/shared/key_vault_configs.md)
- [Upgrade Guide: 0.1.0 → 0.2.0](../upgrades/0.1.0-to-0.2.0-keyvaultconfig-to-keyvaultconfigs.md)
- [Azure Key Vault Task Reference](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/azure-key-vault-v2?view=azure-pipelines)

