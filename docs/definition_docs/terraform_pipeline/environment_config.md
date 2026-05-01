# EnvironmentConfig

The configuration for each environment in the infrastructure pipeline. This object defines the environment name, stage orchestration, and infrastructure deployment configuration.

## Definition

```yaml
EnvironmentConfigs:
  - Name: string                      # REQUIRED
    Stage:                            # REQUIRED
      DependsOn: string | list        # REQUIRED - Stage dependencies
      Condition: string               # REQUIRED - Stage condition
    TerraformDeploymentConfig: object      # REQUIRED - See terraform_deployment_config.md
```

## Required Properties

### Name

**Type:** `string`

**Description:** The unique name of the environment. This is used to generate stage names and identify the environment throughout the pipeline.

**Example:** `'dev'`, `'staging'`, `'production'`

---

### Stage

**Type:** `object`

**Description:** Configuration for the Azure DevOps stage that will be created for this environment.

---

#### Stage.DependsOn

**Type:** `string` or `list`

**Description:** The stage(s) that must complete before this stage runs. Use the generated stage name format or reference previous stages.

**Examples:**
- `'Terraform_Build'` - Depends on the build stage
- `['Terraform_Build', 'Deploy_dev_Terraform']` - Depends on multiple stages

---

#### Stage.Condition

**Type:** `string`

**Description:** The condition that controls whether this stage runs. Uses Azure DevOps expressions.

**Examples:**
- `succeeded()` - Run if previous stages succeeded
- `and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))` - Conditional logic
- `eq(dependencies.Terraform_Build.result, 'Succeeded')` - Explicit dependency check

---

### TerraformDeploymentConfig

**Type:** `object`

**Description:** The infrastructure deployment configuration containing Azure connections (optional), backend configuration, verification settings, and Terraform parameters. See [terraform_deployment_config.md](./terraform_deployment_config.md) for complete details.

---

## Complete Example

```yaml
parameters:
  - name: EnvironmentConfigs
    type: object
    default:
      # Development Environment
      - Name: dev
        Stage:
          DependsOn: Terraform_Build
          Condition: succeeded()
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Dev
          AzDOEnvironmentName: development-environment
          BackendConfig:
            resource_group_name: rg-terraform-state-dev
            storage_account_name: sttfstatedev
            container_name: tfstate
            key: dev.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnDestroy
          VariableFiles:
            - config/common.tfvars
            - config/dev.tfvars

      # Production Environment
      - Name: production
        Stage:
          DependsOn: Deploy_dev_Terraform
          Condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Production
          AzDOEnvironmentName: production-environment
          BackendConfig:
            resource_group_name: rg-terraform-state-prod
            storage_account_name: sttfstateprod
            container_name: tfstate
            key: production.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnAny
          KeyVaultConfig:
            ServiceConnection: AzureServiceConnection-Production
            Name: kv-production-secrets
            SecretsFilter: '*'
          JobsVariableMappings:
            - group: ProductionVariableGroup
          EnvironmentVariableMappings:
            TF_LOG: INFO
          VariableFiles:
            - config/common.tfvars
            - config/production.tfvars
          OutputVariables:
            - resource_group_name
            - app_service_url
```

## See Also

- [TerraformDeploymentConfig Documentation](./terraform_deployment_config.md) - Complete details on `TerraformDeploymentConfig` properties
- [Terraform Pipeline User Documentation](../../user-docs/pipelines/terraform_pipeline.md) - End-user pipeline documentation
- [Terraform Gated Deployment Job](../../user-docs/jobs/terraform_gated_deployment.md) - Job that uses EnvironmentConfigs

