# Changelog

All notable changes to this repository are documented in this file.

## [Unreleased]

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
