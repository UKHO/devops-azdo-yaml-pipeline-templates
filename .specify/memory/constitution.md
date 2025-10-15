<!--
Sync Impact Report:
- Version change: Initial → 1.0.0
- Modified principles: N/A (initial creation)
- Added sections: Core Principles (5), Template Design Standards, Quality Assurance, Governance
- Removed sections: N/A
- Templates requiring updates:
  ✅ Updated: .specify/templates/plan-template.md (Constitution Check section)
  ✅ Updated: .specify/templates/spec-template.md (requirements alignment)
  ✅ Updated: .specify/templates/tasks-template.md (task categorization)
- Follow-up TODOs: None
-->

# Azure DevOps Pipeline Templates Constitution

## Core Principles

### I. Template Hierarchy (NON-NEGOTIABLE)

Templates MUST follow the four-tier hierarchy: Pipeline → Stage → Job → Task. Each tier has distinct responsibilities: Pipelines orchestrate stages across environments, Stages coordinate jobs with proper sequencing, Jobs organize tasks and handle OS-specific concerns, Tasks wrap Microsoft tasks for consistent functionality across versions. No tier may bypass its designated responsibility or directly invoke elements from non-adjacent tiers.

**Rationale**: This separation ensures maintainability, reusability, and clear responsibility boundaries that consumers can depend on.

### II. Backward Compatibility First

All changes MUST preserve existing consumer functionality unless explicitly marked as MAJOR version breaking changes. New features MUST be optional with safe defaults that maintain current behavior. Parameter removal, renaming, or default value changes require MAJOR version increment per semantic versioning rules defined in `docs/how-to-version.md`.

**Rationale**: Consumers expect template stability and rare breaking changes to maintain their CI/CD pipeline reliability.

### III. Self-Documenting Templates

Every template MUST include comprehensive inline documentation with descriptive parameter displayNames, purpose comments, and usage examples. All parameters MUST have clear descriptions explaining their impact. Template files serve as primary documentation source alongside `docs/user-docs/` for high-level guidance.

**Rationale**: Templates must be immediately understandable without external documentation dependencies.

### IV. Semantic Versioning Compliance

All changes MUST follow Semantic Versioning 2.0.0 with strict adherence to MAJOR (breaking), MINOR (additive), PATCH (fixes) classifications. Version bumps MUST be validated against `docs/how-to-version.md` guidelines. Git tags are mandatory for all releases from main branch only.

**Rationale**: Predictable versioning enables consumers to safely upgrade and plan for breaking changes.

### V. Test-Driven Development

All template changes MUST include corresponding test cases in `tests/` directory. New templates require both positive and negative test scenarios. Template modifications require regression testing to verify no unintended behavior changes. Tests must validate template functionality across supported scenarios.

**Rationale**: Template reliability is critical for consumer CI/CD pipeline success and organizational trust.

## Template Design Standards

Templates MUST be composable, reusable, and follow Azure DevOps YAML best practices. Consistent parameter naming conventions across all templates are required. Templates MUST support both .NET and platform-agnostic workloads as stated in repository purpose. Security and compliance checks should be embedded where applicable to align with Azure Landing Zone standards.

## Quality Assurance

All templates undergo mandatory code review by repository owners listed in CODEOWNERS. Changes require validation through test pipelines before merge. Documentation updates must accompany functional changes. The `.editorconfig` formatting standards are non-negotiable and automatically enforced.

## Governance

This constitution supersedes all other development practices within this repository. Constitutional amendments require documentation updates, approval from code owners, and migration plan for affected templates. All pull requests and reviews must verify constitutional compliance before merge approval. Breaking changes require explicit justification and consumer impact assessment.

**Version**: 1.0.0 | **Ratified**: 2025-10-15 | **Last Amended**: 2025-10-15
