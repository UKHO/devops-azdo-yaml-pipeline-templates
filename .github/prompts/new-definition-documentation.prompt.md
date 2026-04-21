---
description: 'Generate definition documentation for a complex object parameter validated by a schema'
mode: 'edit'
---

A new schema template has been added to `schemas/`, or a pipeline uses a complex object
parameter that needs detailed definition documentation. Generate comprehensive definition
docs in `docs/definition_docs/`.

## Requirements

Ask me for:

- **Schema or template file** — which file defines or validates the object
- **Object name** — the parameter name to document (e.g., `InfrastructureConfig`,
  `EnvironmentConfig`)

Then read the schema's validation rules and the consuming template's parameters to generate
documentation following the conventions below.

## Steps

### 1. Create the documentation file

Create the file at `docs/definition_docs/{pipeline_name}/{object_name}.md`.

If the `docs/definition_docs/{pipeline_name}/` directory does not exist, create it.

### 2. Document structure

The markdown file must follow this section order. Use the existing definition docs as the
reference style (e.g., `docs/definition_docs/infrastructure_pipeline/infrastructure_config.md`).

#### Title and introduction

```markdown
# {ObjectName}

One to two sentences describing what this object configures and where it is used.
```

#### Definition block

```markdown
## Definition

```yaml
{ObjectName}:
  PropertyA: type    # REQUIRED
  PropertyB: type    # OPTIONAL
  NestedObject:      # REQUIRED
    SubProp: type    # REQUIRED
```
```

- Show the full YAML shape of the object.
- Annotate each property with `# REQUIRED` or `# OPTIONAL`.
- For enum properties, append the allowed values (e.g., `# REQUIRED (ValueA | ValueB)`).

#### Required Properties

```markdown
## Required Properties
```

For each required property, create an H3 (or H4 for nested sub-properties) with:

- **Type:** — the YAML type (`string`, `object`, `list`, etc.)
- **Description:** — one to two sentences explaining the property's purpose
- **Example:** — an inline code example of a realistic value
- For enum properties, add an **Allowed Values:** list

Separate each property with a `---` horizontal rule.

#### Optional Properties

```markdown
## Optional Properties
```

Same structure as required properties. Additionally:

- If the property has conditional requirements (e.g., "all-or-nothing"), document the rule in
  a **Note:** callout.
- If the property is a complex type (object or list), include a fenced YAML code block example
  showing the expected shape.

#### Complete Example

```markdown
## Complete Example
```

Provide a single, complete YAML example showing the object with **all** properties (required
and optional) filled in with realistic values. Use 2-space indentation.

#### See Also

```markdown
## See Also
```

Include relative links to:

- Related definition docs (e.g., a parent or child object)
- The user-docs pipeline page that consumes this object
- Any other relevant documentation

### 3. Update the schema comment block

If a schema template exists for this object, verify its brief comment block links to the new
definition doc:

```yaml
# Schema Template: [Name]
# [One-line description of purpose]
# See: docs/definition_docs/{pipeline_name}/{object_name}.md
```

### 4. Update the mapping tables

Add the new definition doc to the mapping tables in:

- `.github/instructions/update-documentation.instructions.md` (Schema Template → Definition
  Docs table)
- `.github/prompts/refresh-documentation.prompt.md` (Section 3 mapping table)

## Deriving properties from schema validation rules

Read the schema's `${{ if }}` compile-time checks to determine:

- **Required properties** — any property checked with
  `not(parameters.Object.Property)` or `eq(parameters.Object.Property, '')` is required.
- **Enum properties** — any property checked with `notIn(parameters.Object.Property, ...)`
  has a fixed set of allowed values. Extract the values from the `notIn` list.
- **Conditional requirements** — properties validated only inside an outer `${{ if }}` block
  (e.g., KeyVaultConfig sub-properties validated only when any KeyVaultConfig property is set)
  are conditionally required. Document the condition.
- **Type validation** — properties checked with `contains(convertToJson(...), '[')` expect a
  list; those checked with `contains(convertToJson(...), '{')` expect an object.

## Formatting

- Use 2-space indentation inside all YAML code blocks
- Keep line length under 400 characters (break at 80 where practical)
- Use `---` horizontal rules between property sections (matching existing definition doc style)
- All relative links must use correct paths
- Quote all string values in YAML examples that could be misinterpreted

