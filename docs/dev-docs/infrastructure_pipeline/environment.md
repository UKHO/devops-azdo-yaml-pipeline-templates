# Environment
```yaml
Environments:
  - environment: string
    DeploymentJobsVariableMappings: object
    AzureSubscriptionServiceConnection: string
    AzDOEnvironmentName: string ✅
    BackendConfiguration:
      ServiceConnection: string ✅
      ResourceGroupName: string ✅
      StorageAccountName: string ✅
      ContainerName: string ✅
      BlobName: string ✅
    KeyVaultConfiguration:
      ServiceConnection: string
      Name: string
      SecretFilter: string
    VerificationMode: string ✅
    TerraformEnvironmentVariableMappings: object ✅
    TerraformVariableFiles: [ string ] ✅
    TerraformOutputVariables: [ string ] ✅
```
## Properties

