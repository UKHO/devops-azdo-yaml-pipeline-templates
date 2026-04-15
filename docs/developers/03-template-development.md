# Template Development

## Parameters

- **Required parameters**: Do not set a default. Add a comment: `# no default, consumer must supply this`.
- **Optional parameters**: Provide a sensible default and mark clearly.
- **Object parameters**: Group conceptually related values into a single object (e.g., `TerraformDeploymentConfig`). Validate using a schema template in `schemas/`.
- Every parameter should have: `name`, `type`, `displayName`, and (where applicable) `default` and `allowed` values.

## Variable Scoping

Pipeline-level variables are overridden by stage-level variables, which are overridden by job-level variables. Be aware of this precedence to avoid unexpected behaviour.

## Decomposition Strategy

1. Extract individual tasks → `tasks/` templates.
2. Group tasks into jobs → `jobs/` templates.
3. Group jobs into stages → `stages/` templates.
4. Assemble stages into pipelines → `pipelines/` templates.
5. Eliminate duplication using compile-time `${{ each }}` expressions.

## Task Template File Documentation

Every task template file must include a YAML comment block at the top that:

- States the template's purpose.
- Lists all required and optional parameters with types and descriptions.
- Provides one or more usage examples.

See `tasks/terraform.yml` for a well-documented example.

## Anti-Patterns

- **Double-wrapping**: Do not wrap a template inside another template just to provide preset defaults. This increases complexity and makes debugging harder. Prefer direct inclusion. See [Anti-Pattern: Double Wrapping](anti-pattern-double-wrapping.md).
- **Excessive parameterisation**: Do not force consumers to pass unnecessary parameters.
- **Inconsistent naming**: Follow the repository's naming conventions strictly.

---

[← Back to Developer Documentation](README.md)

