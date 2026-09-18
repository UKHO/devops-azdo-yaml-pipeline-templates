# Changelog

All notable changes to this repository are documented in this file.

## [Unreleased]

### Fixed

- Moved `RunMode` and `VerificationMode` (plus `VerificationTimeoutInMinutes`/`VerificationTimeoutBehaviour`) validation from the leaf `terraform_deploy`/`terraform_destroy` job schemas to the orchestrator `terraform_gated_deployment`/`terraform_gated_destroy` job schemas that actually consume these fields.
- Leaf jobs (`terraform_deploy`, `terraform_destroy`) now only validate the properties they use directly (backend config, service connection, variable files, etc.).
- Added a new `schemas/terraform_gated_destroy_config.yml` schema; `terraform_gated_destroy` previously had no dedicated schema and did not validate `RunMode` or the verification timeout fields at all.
- This is a non-breaking change for valid configurations: it tightens validation for `terraform_gated_destroy` consumers and relaxes validation for `terraform_deploy`/`terraform_destroy` consumers that don't set `RunMode`/`VerificationMode` directly.

### Changed

- Combined `terraform_deployment_config.md` and `terraform_destroy_config.md` into a single [`terraform_job_config.md`](docs/definition_docs/terraform_pipeline/terraform_job_config.md).
- The combined doc documents both `TerraformDeploymentConfig` and `TerraformDestroyConfig`, clearly marking which fields are validated by which job/schema.

## [0.3.0] - 2026-07-08

### Added

- Added a reusable `terraform_destroy` job template for artifact-based Terraform destroy plan and destroy execution.
- Added a reusable `terraform_gated_destroy` job template with `PlanOnly`, `DestroyOnly`, and `PlanVerifyDestroy` run modes for gated infrastructure teardown.
- Added `TerraformDestroyConfig` schema validation and definition documentation for destroy workflows.
- Added user documentation for the new destroy job templates, including end-to-end destroy examples.
- Added optional `VerificationTimeoutInMinutes` and `VerificationTimeoutBehaviour` fields to `TerraformDestroyConfig` and `TerraformDeploymentConfig`, allowing the manual verification gate's timeout duration and timeout behaviour to be configured per environment.

### Changed

- Updated user documentation index to include the new destroy and gated destroy job templates.

### Fixed

- Fixed gated deployment test scenarios that used `VerifyOnDestroy` verification mode against apply-only test infrastructure, which meant the manual verification gate was never actually triggered; scenarios now use `VerifyOnAny` with a short timeout so the gate reliably engages and resumes automatically.

## [0.2.0] - 2026-06-24

### Added

- Added reusable configuration source composition for deployments that need one or more secret providers.
- Added centralised definition documentation for configuration source objects and validation expectations.
- Added an upgrade guide to help users migrate from legacy single Key Vault configuration to configuration source arrays.

### Changed

- Clarified Key Vault task behaviour and reference guidance for pre-job secret loading scenarios.
- Improved configuration source validation rules and error consistency to make invalid input easier to diagnose.
- Expanded deployment test coverage for configuration source scenarios, including one and multiple Key Vault mappings.
- Improved public docs navigation by adding an upgrade guides entry and aligning deployment configuration docs with shared definitions.

### Deprecated

- Deprecated legacy `KeyVaultConfig`; use `ConfigSources` for new and updated deployments. See the [0.1.0 to 0.2.0 upgrade guide](docs/user-docs/upgrades/0.1.0-to-0.2.0-keyvaultconfig-to-configsources.md).

### Fixed

- Updated test pipeline pull request triggers so draft pull requests targeting `main` no longer start runs.

## [0.1.0] - 2026-05-22

Initial public release of reusable Azure DevOps YAML templates for Terraform build and deployment workflows.

### Added

- Added a complete Terraform pipeline template for reusable build and deployment workflows.
- Added reusable job templates for Terraform build, deployment, gated deployment, and manual verification scenarios.
- Added reusable task templates for common pipeline operations including Terraform execution, artifact handling, file transforms, and manual validation.
- Added supporting stage templates for standard Terraform build and deploy orchestration.
- Added a PowerShell-based compile and validation test framework for template quality checks.
- Added baseline YAML test suites covering framework, pipeline, and job template scenarios.
