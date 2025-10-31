# GitHub Copilot Custom Instructions

This repository (`devops-azdo-yaml-pipeline-templates`) is a centralised source for reusable Azure DevOps YAML pipeline templates. The goal is to maintain high standards, reliability, and reusability for pipelines used across multiple projects.

## Key Guidelines

- **Formatting Standards:** Always follow the formatting rules specified in the `.editorconfig` file at the root of the repository.
- **Understand Breaking Changes:** See the "Breaking Change Rules" section below for what constitutes a breaking change. Always check these rules before modifying existing templates.
- **YAML Best Practices:** Follow established YAML conventions:
  - Use consistent indentation (2 spaces).
  - Avoid unnecessary complexity.
  - Use descriptive names for parameters, steps, and jobs.
  - Document templates with comments where appropriate.
- **Reusability:** Design templates to be modular and easily consumable by other repositories.
- **Documentation:** Update or create documentation for any new features, changes, or best practices.

## Breaking Change Rules

- Any change that alters the behavior, structure, or required parameters of a template is considered a breaking change.
- Examples of breaking changes:
  - Renaming, removing, or changing the type of parameters.
  - Modifying the output structure or expected results.
  - Removing or changing steps, jobs, or tasks in a way that affects consumers.
  - Changing default values that may impact downstream usage.
- Non-breaking changes include:
  - Adding new optional parameters.
  - Adding new steps or jobs that do not affect existing behavior.
  - Improving documentation or comments.
- For breaking changes, increment the major version of the template and clearly document the change in the template and repository changelog.

## Template File Documentation

- At the top of every template file, include a short documentation block that:
  - Clearly states the purpose of the template.
  - Lists any required and optional parameters.
  - Provides one or more usage examples showing how to reference and use the template in a pipeline.
- Use YAML comments (`#`) for this documentation block.

## AzDO YAML Pipeline Anti-Patterns

- **Avoid Double-Wrapping:** Do not wrap a template inside another template unless absolutely necessary. Double-wrapping increases complexity, makes debugging harder, and can lead to unexpected behaviours. Prefer direct inclusion of steps, jobs, or tasks to keep templates simple and maintainable.
