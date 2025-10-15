# Azure DevOps YAML Pipeline Templates - User Documentation

This directory contains comprehensive documentation for all Azure DevOps YAML pipeline templates in this repository.

## Template Categories

### 📋 Pipelines

Complete end-to-end pipeline templates for specific use cases.

- **[Infrastructure Pipeline](./pipelines/infrastructure_pipeline.md)** - Complete infrastructure deployment pipeline using Terraform

### 🏗️ Stages

Reusable stage templates for common deployment patterns.

- **[Terraform Build Stage](./stages/terraform_build.md)** - Build and validate Terraform configuration

### 💼 Jobs

Individual job templates for specific tasks.

- **[Terraform Build Job](./jobs/terraform_build.md)** - Build Terraform configuration within a stage

### ⚙️ Tasks

Task templates for individual operations.

- **[Terraform Task](./tasks/terraform.md)** - Core Terraform operations (plan, apply, destroy)
- **[Terraform Installer Task](./tasks/terraform_installer.md)** - Install and configure Terraform
- **[Publish Pipeline Artifact Task](./tasks/publish_pipeline_artifact.md)** - Publish build artifacts to pipeline

## Getting Help

### Template Issues

- Check the **Dependencies** section in each template's documentation
- Verify all required parameters are provided
- Review the **Usage Examples** for proper syntax
