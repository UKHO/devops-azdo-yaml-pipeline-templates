# ConfigSources

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

## Rules

- `ConfigSources` cannot be empty when provided.
- Each entry must be an object with a `Type` discriminator and a `ServiceConnection` value.
- `ConfigSources` entries execute in the order listed.
- Later sources can override pipeline variables set by earlier sources.
- `KeyVault` entries require `Name` and allow `SecretsFilter` and `RunAsPreJob`.
- `KeyVault.SecretsFilter`, when provided, must be a non-empty string.
- Optional fields are validated for expected type when present.
- `KeyVaultConfig` and `ConfigSources` cannot be used together in the same `TerraformDeploymentConfig`.

---

## See Also

- [TerraformDeploymentConfig](../terraform_pipeline/terraform_deployment_config.md)


