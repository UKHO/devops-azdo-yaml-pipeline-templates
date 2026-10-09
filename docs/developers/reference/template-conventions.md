# Template Development

## Parameters

- **Required parameters**: Do not set a default. Add a comment: `# no default, consumer must supply this`, and end the `displayName` with `(required)`.
- **Optional parameters**: Provide a sensible default and mark clearly.
- **Conditionally required parameters** (optional by YAML definition, but required when another parameter is set): give them a `default` of `''`, and document the condition in the `displayName` (e.g. `'Only needed when Flag is true (required when Flag is set)'`).
- **Object parameters**: Group conceptually related values into a single object (e.g., `TerraformDeploymentConfig`). Validate using a schema template in `schemas/`.
- Every parameter should have: `name`, `type`, `displayName`, and (where applicable) `default` and `allowed` values.
- **Parameter naming**: use PascalCase (`TerraformVersion`, `ServiceConnectionName`), full words over abbreviations (`TargetEnvironment` not `TgtEnv`), and prefix boolean parameters with a verb (`EnableLogging`, `AllowFailure`, `RunTests`).
- **Property ordering** (for `tasks/` and `utils/` templates): within each parameter, properties must appear in this order: `name`, `type`, `default` (or a `# NO default` comment), `values` (when applicable), `displayName`.

## Variable Scoping

Pipeline-level variables are overridden by stage-level variables, which are overridden by job-level variables. Be aware of this precedence to avoid unexpected behaviour.

### Protecting Template-Internal Variables

Declare any variable a template defines for its own internal use with `readonly: true`:

```yaml
variables:
  - name: TargetPath
    value: $(Build.SourcesDirectory)/${{ parameters.RelativePathToTerraformFiles }}
    readonly: true
```

This prevents a consumer pipeline from silently overriding the variable with one of its own, which would otherwise be possible due to Azure DevOps's variable precedence rules. See `jobs/terraform_deploy.yml` and `jobs/terraform_build.yml` for examples.

## Decomposition Strategy

1. Extract individual tasks → `tasks/` templates.
2. Group tasks into jobs → `jobs/` templates.
3. Group jobs into stages → `stages/` templates.
4. Assemble stages into pipelines → `pipelines/` templates.
5. Eliminate duplication using compile-time `${{ each }}` expressions.

## Task Template File Documentation

Every task template file (`.yml`, never `.yaml`) must include a YAML comment block at the top. Required elements:

- **Purpose**: a one-to-two line statement of what the template does.
- **Parameters**: list every parameter with its type and required/optional status.
  - Enum parameters include their allowed values as `Values: a, b, c.` in the description.
  - Required parameters omit `Default:`; optional parameters include it.
  - Conditionally required parameters are marked `optional` with a note (e.g. "required when Flag is set").
- **Example Usage**: at least one realistic example including all required parameters. When giving three or more examples, label each additional one with a `# Description` comment.
- **Notes**: important considerations, and a `See:` link to the relevant Microsoft task reference documentation when available.

See `tasks/terraform.yml` for a well-documented example.

## Writing a Schema (Validation) Template

Schema templates in `schemas/` validate complex object parameters at **compile time**, before any agent runs. They work by emitting a one-key mapping whose value is the string `"Error"` under a compile-time `${{ if ... }}` condition: when the condition is true, Azure DevOps fails compilation and prints the key as the message. The key should be a descriptive sentence ending with a `See:` link to the definition doc.

```yaml
steps:
  # Required-field check
  - ${{ if or(not(parameters.Config.Name), eq(parameters.Config.Name, '')) }}:
      - "Invalid Config: field 'Name' is required. See docs/definition_docs/path/to/details.md": "Error"

  # Type check (object/array accidentally supplied where a string is expected)
  - ${{ if or(contains(convertToJson(parameters.Config.Name), '{'), contains(convertToJson(parameters.Config.Name), '[')) }}:
      - "Invalid Config: field 'Name' must be a string. See docs/definition_docs/path/to/details.md": "Error"

  # Allowed-values check
  - ${{ if notIn(parameters.Config.Type, 'KeyVault') }}:
      - "Invalid Config: field 'Type' must be 'KeyVault'. See docs/definition_docs/path/to/details.md": "Error"
```

Conventions for guard expressions:

- Validate a list with `${{ each item in parameters.List }}:` and apply the per-entry checks inside.
- Detect a non-scalar (object/array) value by checking whether its `convertToJson` output contains `{` or `[`.
- Gate optional-field checks on presence first: `${{ if and(contains(convertToJson(parameters.Config), '"Field"'), <bad-value condition>) }}`.
- Reject an empty required list explicitly (`eq(length(parameters.List), 0)`) rather than letting it pass silently.
- Keep each message specific and actionable, and end it with the `See:` link to the object's `docs/definition_docs/` page.

See `schemas/config_sources.yml` for a complete worked example.

## Schema Template Documentation

Schema templates (`schemas/`) take a brief in-file comment block only (detailed docs live in `docs/definition_docs/`). Format:

```yaml
# Schema Template: Name
# One-line description of purpose
# See: docs/definition_docs/path/to/details.md
```

## Anti-Patterns

- **Double-wrapping**: Do not wrap a template inside another template just to provide preset defaults. See [Double Wrapping](../explanation/double-wrapping.md).
- **Excessive parameterisation**: Do not force consumers to pass unnecessary parameters.
- **Inconsistent naming**: Follow the repository's naming conventions strictly.
- **Mixing build and deploy in the same stage**: keep `Build` and `Deploy` as separate stages with `dependsOn`, not combined jobs inside one stage.
- **Overly broad triggers**: scope `trigger`/`pr` to specific branches and paths; do not trigger on `'*'` or omit `paths`.

## Security

- Never hardcode secrets in variables or scripts. Use an Azure Key Vault task (`tasks/azure_key_vault.yml`) or a variable group (`variables: - group: 'Name'`).
- Mark any variable holding a secret as `isSecret` at the point it's set (`##vso[task.setvariable variable=Name;isSecret=true]`) so it is not logged.
- Prefer managed identities over service principals for service connections, follow least-privilege, and use environment-specific connections with approval gates for production.

## Performance Patterns

- **Caching**: use `Cache@2` for dependency caches (npm, NuGet) keyed on a lockfile hash.
- **Parallel execution**: use a `strategy.matrix` to fan out independent jobs (e.g. per-OS builds) instead of sequential jobs.
- **Shallow clone**: set `fetchDepth: 1` on `checkout: self` for builds that don't need full git history.

## Error Handling

- Use `continueOnError: true` for steps that may fail without blocking the pipeline.
- Use `condition: always()` for cleanup steps that must run regardless of prior step outcome.
- Use `condition: succeeded()` / `condition: failed()` to gate steps on prior results explicitly.
- Use `retryCountOnTaskFailure` for tasks prone to transient failures (e.g. network calls).
