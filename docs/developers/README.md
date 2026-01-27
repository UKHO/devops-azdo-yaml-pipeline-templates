# Developer Documentation

Welcome to the developer documentation for the Azure DevOps YAML Pipeline Templates repository. This guide is designed to help contributors and maintainers understand the repository structure, standards, best practices, and advanced topics for developing, maintaining, and extending reusable pipeline templates.

---

## 1. Repository Structure & Organization

This repository is organized to maximize clarity, modularity, and reusability:
- **tasks/**: Templates for individual Azure DevOps tasks, wrapping native tasks for stability and clarity.
- **jobs/**: Job-level templates, self-contained and reusable, often with parameter validation.
- **stages/**: Stage templates, grouping jobs for specific pipeline goals (e.g., environments).
- **pipelines/**: Entry-point templates assembling stages into complete pipelines.
- **scripts/**: PowerShell (preferred) or Bash scripts for complex or unsupported operations.
- **utils/**: Shared YAML pieces for supporting other templates.
- **tools/**: Scripts/utilities for repository maintenance.
- **schemas/**: Validation templates for complex objects passed in pipelines.

> New folders should be avoided unless necessary. Discuss with the team before adding new structure.

---

## 2. YAML Standards & Best Practices

- Use 2-space indentation (enforced by .editorconfig).
- File and folder names: `lowercase_snakecase`, `.yml` extension only.
- Avoid YAML anchors/aliases and multi-document YAML (unsupported in AzDO).
- Use compile-time expressions (`${{ }}`) for parameterization and conditional logic.
- Document all templates with a YAML comment block at the top, listing required/optional parameters and usage examples.
- Use clear `displayName` values and comments for maintainability.
- Validate parameters using schemas for complex objects.

---

## 3. Template Development Guidelines

- Group related parameters into objects for clarity and validation.
- Use schema templates for validating complex parameters.
- Avoid double-wrapping templates (see [Anti-Pattern: Double Wrapping](anti-pattern-double-wrapping.md)).
- Add new steps/jobs as optional parameters to avoid breaking changes.
- Keep documentation up to date in both YAML headers and Markdown guides.
- Required parameters should not have defaults; optional parameters should be clearly marked.

---

## 4. Scripts & Tooling

- PowerShell is the preferred scripting language; Bash is allowed for Linux-specific needs. Batch files are prohibited.
- Use scripts only when built-in tasks or YAML cannot achieve the required logic.
- Base all file paths on standard AzDO variables (e.g., `$(Pipeline.Workspace)`).
- Use IDE extensions for YAML validation and linting.
- Repository scripts (in `tools/` or `scripts/`) should be well-documented and cross-platform where possible.

---

## 5. Versioning & Breaking Changes

- Follows [Semantic Versioning 2.0.0](how-to-version.md): `vMAJOR.MINOR.PATCH`.
- Breaking changes require a major version bump and must be documented in the changelog and template header.
- Breaking changes include: adding required parameters, renaming/removing parameters, changing outputs, or altering job/task structure.
- Non-breaking changes: adding optional parameters, new steps/jobs, or documentation improvements.
- Always provide migration guidance for breaking changes.

---

## 6. Development Workflow & Testing

- Use an IDE with YAML support and follow `.editorconfig` rules.
- Open draft PRs early for feedback; use a PR checklist for display names, parameter docs, and naming.
- Test changes by running pipelines and verifying both compile and runtime behavior.
- Use feature/ and docs/ branch prefixes; delete branches after merging.
- Prefer rebasing over merging from main.

---

## 7. Advanced Topics & Architecture

- [Pipeline Decorators](pipeline-decorators-explained.md): Use for organization-wide step injection, not currently used but important for future extensibility.
- [Double Checkout Pathing](quark-double-checkouts-pathing-problems.md): Understand pathing issues when using multiple `checkout` tasks in a job.
- Architectural decisions (ADRs) should be documented and referenced in PRs.
- The repository supports both "set menu" (ready-to-use pipelines) and "salad bar" (modular jobs/tasks) approaches.

---

## 8. AI & Documentation

- AI tools can accelerate documentation and code generation but require human review.
- All AI-generated content must be validated for accuracy and adherence to standards.
- Update copilot-instructions and documentation when repository practices change.
- Use AI for routine documentation tasks, but never rely solely on AI for complex logic or undocumented features.

---

## 9. Further Reading & Planning

- [Anti-Pattern: Double Wrapping](anti-pattern-double-wrapping.md)
- [Pipeline Decorators Explained](pipeline-decorators-explained.md)
- [Double Checkout Pathing Problems](quark-double-checkouts-pathing-problems.md)
- [How to Version Templates](how-to-version.md)
- [Repository Structure Reference](repository-structure.md)

---

> Use this guide as your starting point for all development, contribution, and troubleshooting activities. For detailed examples, see the referenced guides and template headers throughout the repository.
