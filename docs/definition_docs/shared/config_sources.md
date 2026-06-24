# ConfigSources

> `KeyVaultConfig` and `ConfigSources` are mutually exclusive in `TerraformDeploymentConfig`. Do not use both in the same configuration.

## Definition

```yaml
ConfigSources:
  - Type: string
    ServiceConnection: string
    Name: string            # KeyVault only (required)
    SecretsFilter: string    # KeyVault only (optional, default: '*')
    RunAsPreJob: boolean     # KeyVault only (optional, default: false)
```

---

## Array Entry Definitions

### Type

**Type:** `string`

**Required:** Yes

**Allowed Values:**
- `KeyVault`

**Definition:** Identifies the configuration-source type so the task list can map the entry to the correct wrapper.

---

### ServiceConnection

**Type:** `string`

**Required:** Yes

**Definition:** The Azure Resource Manager service connection used to access the source.

---

### KeyVault Entries

#### Name

**Type:** `string`

**Required:** Yes

**Definition:** The Azure Key Vault name.

---

#### SecretsFilter

**Type:** `string`

**Required:** No

**Default:** `'*'`

**Definition:** Filter for secrets to retrieve. Use `'*'` to retrieve all
secrets or a comma-separated list to target specific secrets.

---

#### RunAsPreJob

**Type:** `boolean`

**Required:** No

**Default:** `false`

**Definition:** When `true`, runs the Key Vault task before other tasks in the same job.

---

## Implemented Example

```yaml
TerraformDeploymentConfig:
  AzDOEnvironmentName: production-environment
  RunMode: ApplyOnly
  AzureServiceConnection: AzureServiceConnection-Production
  ConfigSources:
    - Type: KeyVault
      Name: kv-shared-secrets
      ServiceConnection: AzureServiceConnection-Shared
      SecretsFilter: 'shared-*'
      RunAsPreJob: true
    - Type: KeyVault
      Name: kv-app-secrets
      ServiceConnection: AzureServiceConnection-Production
      SecretsFilter: 'app-*'
```

---

## See Also

- [TerraformDeploymentConfig](../terraform_pipeline/terraform_deployment_config.md)

