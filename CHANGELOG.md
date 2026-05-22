# Changelog

All notable changes to this repository are documented in this file.


## [0.1.0] - 2026-05-22

Initial public release of reusable Azure DevOps YAML templates for Terraform
build and deployment workflows.

### Added

- Pipeline template:
  - `pipelines/terraform_pipeline.yml`

- Job templates:
  - `jobs/terraform_build.yml`
  - `jobs/terraform_deploy.yml`
  - `jobs/terraform_gated_deployment.yml`
  - `jobs/manual_verification.yml`

- Task templates:
  - `tasks/azure_key_vault.yml`
  - `tasks/azure_web_app.yml`
  - `tasks/copy_files.yml`
  - `tasks/delay.yml`
  - `tasks/download_pipeline_artifact.yml`
  - `tasks/file_transform.yml`
  - `tasks/manual_validation.yml`
  - `tasks/powershell.yml`
  - `tasks/publish_pipeline_artifact.yml`
  - `tasks/terraform.yml`
  - `tasks/terraform_installer.yml`

- Supporting stage templates:
  - `stages/terraform_build.yml`
  - `stages/terraform_deploy.yml`

- PowerShell-based test framework and runners:
  - `tests/framework/Core.ps1`
  - `tests/framework/Core.CompileYaml.ps1`
  - `tests/framework/Core.DirectoryTestRunner.ps1`
  - `tests/framework/Core.ParameterisedTestRunner.ps1`
  - `tests/framework/Core.PreFlightValidation.ps1`
  - `tests/framework/Core.Authentication.ps1`
  - `tests/framework/Core.SaveYaml.ps1`
  - `tests/framework/Config.ps1`
  - `tests/jobs/jobs.CompileTests.ps1`
  - `tests/pipelines/pipelines.CompileTests.ps1`

- YAML test templates under `tests/` covering framework, pipeline, and jobs:
  - `tests/framework/`
  - `tests/pipelines/terraform_pipeline/`
  - `tests/jobs/manual_verification/`
  - `tests/jobs/terraform_build/`
  - `tests/jobs/terraform_deploy/`
  - `tests/jobs/terraform_gated_deployment/`
