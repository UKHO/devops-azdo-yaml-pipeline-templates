# Documentation Template Structure

## AI Agent Documentation Format

Each AI-generated documentation file follows this standardized structure to ensure consistency and quality:

```markdown
# [Template Type]: [Template Name]

> **Source**: [Relative link to template file]
> **Type**: [Pipeline|Stage|Job|Task]
> **Last Updated**: [Generation timestamp]

## Overview

[Template purpose and functionality description]

[Hidden functionality notes if applicable]

## Quick Start

### Basic Usage

```yaml
# Basic implementation example
[Template reference with minimal required parameters]
```

### Required Parameters

[Table of mandatory parameters only]

## Parameters Reference

[Complete parameters table with all options]

| Parameter | Type   | Default   | Description                        |
|-----------|--------|-----------|------------------------------------|
| [Name]    | [Type] | [Default] | [DisplayName + additional context] |

## Dependencies

This template references the following templates:

- **[Dependency Name]**: [Purpose] → [Link to dependency documentation]
- **[Dependency Name]**: [Purpose] → [Link to dependency documentation]

## Advanced Examples

### [Scenario 1 Name]

[Description of advanced use case]

```yaml
[Complex configuration example with explanatory comments]
```

### [Scenario 2 Name]

[Description of another advanced use case]

```yaml
[Another complex example]
```

## Parameter Details

[Detailed explanations for complex parameters with code examples]

### [Complex Parameter Name]

[Detailed explanation with examples]

```yaml
[Parameter-specific examples]
```

## Notes

[Any additional considerations, limitations, or best practices]

---

**Related Documentation**: [Links to related templates or external docs]

```

## Index Structure (README.md)

The main index file follows this format:

```markdown
# Azure DevOps Pipeline Templates - User Documentation

This directory contains comprehensive documentation for all available pipeline templates.

## Quick Navigation

### By Template Type

| Type | Templates | Description |
|------|-----------|-------------|
| **Pipelines** | [Count] templates | Complete pipeline orchestration |
| **Stages** | [Count] templates | Stage-level coordination |
| **Jobs** | [Count] templates | Job organization and execution |
| **Tasks** | [Count] templates | Individual task wrappers |

### All Templates

#### Pipelines
- **[infrastructure_pipeline](pipelines/infrastructure_pipeline.md)** - [Brief description]

#### Stages
- **[terraform_build](stages/terraform_build.md)** - [Brief description]
- **[terraform_deploy](stages/terraform_deploy.md)** - [Brief description]

#### Jobs
- **[terraform_build](jobs/terraform_build.md)** - [Brief description]

#### Tasks
- **[terraform](tasks/terraform.md)** - [Brief description]
- **[terraform_installer](tasks/terraform_installer.md)** - [Brief description]
- **[publish_pipeline_artifact](tasks/publish_pipeline_artifact.md)** - [Brief description]

## Template Hierarchy

[Visual representation of template dependencies]

## Getting Started

1. **Choose your template type**: Start with pipeline-level templates for complete solutions
2. **Review parameters**: Each template documents all available configuration options
3. **Check dependencies**: Understand which other templates are required
4. **Follow examples**: Use provided examples as starting points for your implementation

## Support

For questions about template usage, refer to:
- [Repository README](../../README.md)
- [Contributing Guidelines](../../CONTRIBUTING.md)
- [How to Version](../how-to-version.md)
```

## Section Generation Rules

### Overview Section

- Extract purpose from template comments and file structure analysis
- Include hidden functionality discovered through step analysis
- Keep concise but comprehensive

### Parameters Reference

- Generate from YAML parameters section
- Use displayName as primary description
- Add type safety and validation information
- Mark required vs optional parameters clearly

### Dependencies Section

- Analyze template: references in YAML
- Provide relative links to dependency documentation
- Explain the purpose of each dependency

### Examples Section

- Basic example shows minimal viable usage
- Advanced examples demonstrate real-world scenarios
- Include inline comments explaining configuration choices
- Cover edge cases and complex parameter combinations
