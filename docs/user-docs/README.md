# Azure DevOps YAML Pipeline Templates - User Documentation

This directory contains comprehensive documentation for Azure DevOps YAML pipeline templates and jobs in this
repository.

## 📋 Pipeline Templates

Complete end-to-end pipeline templates for specific use cases.

- **[Terraform Pipeline](./pipelines/terraform_pipeline.md)** – Complete infrastructure deployment pipeline using
  Terraform for building, validating, and packaging infrastructure-as-code files

### Related Pipeline Documentation

- [Terraform Pipeline - Parameters in Detail](./pipelines/terraform_pipeline_parameters_in_detail.md)
- [Terraform Pipeline - Additional Files to Package](./pipelines/terraform_pipeline_additional_files_to_package.md)

## 🔧 Job Templates

Reusable job components for building custom pipelines. These jobs are part of the API guarantee and are fully supported
for direct consumption.

- **[Terraform Build Job](./jobs/terraform_build_job.md)** – Builds, validates, and packages Terraform files into
  deployment artifacts
- **[Terraform Deploy Job](./jobs/terraform_deploy_job.md)** – Deploys Terraform infrastructure with plan or apply
  modes, Azure Key Vault integration, and output variable capture
- **[Terraform Gated Deployment Job](./jobs/terraform_gated_deployment_job.md)** – Orchestrates sophisticated
  deployments with optional plan verification and manual approval gates
- **[Manual Verification Job](./jobs/manual_verification_job.md)** – Creates manual approval gates in your pipeline with
  customizable instructions and timeout behavior

## 📚 Deployment Strategy Guides

Detailed guides on deployment strategies and verification modes.

- **[Deployment Modes and Verification Strategies](./deployment_modes_and_verification.md)** – Comprehensive guide to PlanOnly, ApplyOnly, and PlanVerifyApply modes with verification strategies (VerifyOnDestroy, VerifyOnAny, VerifyDisabled)

## Getting Help

- Check the **Important Notices** section in each pipeline template's documentation for critical implementation details
- Review the **Basic Usage** section for quick implementation examples
- Consult the **Full Parameter Table** for complete configuration options
- Examine **Advanced Usage** examples for complex scenarios

## Template Self-Documentation

All templates in this repository are self-documenting through:

- Descriptive names and `displayName` properties
- Comprehensive parameter metadata (types, defaults, descriptions)
- Inline comment blocks explaining purpose and usage
