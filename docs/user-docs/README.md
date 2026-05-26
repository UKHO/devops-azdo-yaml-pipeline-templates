# Azure DevOps YAML Pipeline Templates - User Documentation

This directory contains comprehensive documentation for Azure DevOps YAML pipeline templates in this repository.

## 📋 Pipeline Templates

Complete end-to-end pipeline templates for specific use cases.

### Available Pipelines

| Pipeline                                                    | Purpose                                                                                                                                                                                       |
|-------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **[Terraform Pipeline](./pipelines/terraform_pipeline.md)** | Complete infrastructure deployment pipeline using Terraform for building, validating, and packaging infrastructure-as-code files with multi-environment support and manual verification gates |

### Available Jobs

| Job                                                                        | Purpose                                                                                                            |
|----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| **[Manual Verification Job](./jobs/manual_verification.md)**               | Reusable approval gate for manual workflow validation with configurable timeouts and notifications                 |
| **[Terraform Build Job](./jobs/terraform_build.md)**                       | Builds, validates, and packages Terraform files with support for additional files and custom injection steps       |
| **[Terraform Deploy Job](./jobs/terraform_deploy.md)**                     | Handles individual Terraform deployment steps (plan or apply) with environment variables and Key Vault integration |
| **[Terraform Gated Deployment Job](./jobs/terraform_gated_deployment.md)** | Orchestrates complete Terraform workflow (plan → verify → apply) with configurable run modes                       |

## Self-Documentation

All templates are self-documenting through:

- Descriptive names and `displayName` properties
- Comprehensive parameter metadata (types, defaults, descriptions)
- Inline comment blocks explaining purpose and usage