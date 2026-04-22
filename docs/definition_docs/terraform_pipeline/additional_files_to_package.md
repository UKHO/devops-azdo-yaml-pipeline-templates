# AdditionalFilesToPackage

A list object that specifies additional files to include in the terraform artifact during the build stage. Each item describes a set of files to copy from a source directory to a target subdirectory within the packaged artifact.

## Definition

```yaml
AdditionalFilesToPackage:
  - SourceDirectory: string         # REQUIRED - relative path from repo root
    FilesPattern: string            # REQUIRED - glob pattern for files to copy
    TargetSubdirectoryName: string  # REQUIRED - subdirectory in artifact
```

AdditionalFilesToPackage is a list of objects. Each object in the list represents one file copy operation.

---

## Required Properties

### SourceDirectory

**Type:** `string`

**Description:** The relative path from the repository root to the directory containing the files to copy.

**Example:** `'config/shared'`, `'scripts'`, `'terraform/modules'`

---

### FilesPattern

**Type:** `string`

**Description:** A glob pattern specifying which files to copy from the source directory. Supports standard glob patterns including `*`, `**`, and `?` for pattern matching.

**Example:** `'*.tfvars'`, `'**/*.json'`, `'**/*.ps1'`

---

### TargetSubdirectoryName

**Type:** `string`

**Description:** The subdirectory name within the terraform artifact where the copied files will be placed. Can include multiple nesting levels.

**Example:** `'shared-config'`, `'scripts'`, `'config/shared'`

---

## Complete Example

```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config/shared'
    FilesPattern: '*.tfvars'
    TargetSubdirectoryName: 'shared-config'

  - SourceDirectory: 'scripts'
    FilesPattern: '**/*.ps1'
    TargetSubdirectoryName: 'scripts'

  - SourceDirectory: 'terraform/modules'
    FilesPattern: '**/*.tf'
    TargetSubdirectoryName: 'modules'
```

---

## See Also

- [Terraform Pipeline Documentation](../../user-docs/terraform_pipeline.md) – User documentation with usage patterns and examples
- [Terraform Pipeline Parameters in Detail](../../user-docs/terraform_pipeline_parameters_in_detail.md) – Parameter reference including AdditionalFilesToPackage usage and troubleshooting
