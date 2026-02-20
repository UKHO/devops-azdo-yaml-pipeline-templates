---
description: 'Audit a task or utility template to ensure its in-file documentation block is complete and accurate'
mode: 'edit'
---

Audit the selected `tasks/` or `utils/` template file.

Compare the in-file comment block at the top of the file against the actual `parameters:` section
and `steps:` implementation below it. Report and fix any of the following:

1. **Missing comment block** — Add one following this format:

   ```yaml
   # Azure DevOps Task: [TaskName]@[Version]
   #
   # Purpose:
   #   [Clear, concise description — typically two lines]
   #
   # Parameters:
   #   - [Name] ([type], required): [Description].
   #   - [Name] ([type], optional): [Description]. Default: [value]
   #   - [Name] ([type], optional): [Description]. Values: a, b. Default: 'a'
   #
   # Example Usage:
   #   - template: tasks/[filename].yml
   #     parameters:
   #       [Name]: 'value'
   #
   # Notes:
   #   - [Considerations]
   #   - See: [link to Microsoft task reference documentation]
   ```

2. **Parameter mismatch** — Every parameter in the `parameters:` block must appear in the
   comment's Parameters list with the correct type, required/optional status, and default value.
   Remove any documented parameters that no longer exist.
   - A parameter is **required** when it has no `default:` — omit `Default:` from the comment.
   - A parameter is **optional** when it has a `default:` — include `Default: value` in the
     comment.
   - A **conditionally required** parameter (optional by YAML definition but required when
     another parameter is set) should be marked `optional` with a note in its description (e.g.,
     "required when deploying to a slot").

3. **Enum values in description** — Parameters with a `values:` list must append
   `Values: a, b, c.` to their description in the comment block.

4. **Stale examples** — If example usage references parameters that have been renamed or removed,
   update the examples to match the current parameters.

5. **Labelled examples** — When three or more examples exist, each additional example (beyond
   the first two) must have a short `# Description` label comment above it.

6. **Wrong task version** — If the `steps:` section uses a different task version (e.g.,
   `PowerShell@2`) than what the comment block states, update the comment block.

7. **Missing notes** — If the template has important limitations, conditions, or gotchas that
   are not documented in the Notes section, add them. Include a `See:` link to the Microsoft
   task reference documentation when available.

8. **Parameter property ordering** — Properties within each parameter definition must appear in
   this order: `name` → `type` → `default` (or `# NO default` comment) → `values` →
   `displayName`. Reorder any that do not match.

9. **Required enum pattern** — Parameters with `values:` but no `default:` must use
   `# NO default - Consumer must provide this` and include `(required)` in `displayName`.

10. **Filename convention** — The file must be named using `snake_case` based on the template's
    purpose (e.g., `azure_key_vault.yml`, not `AzureKeyVault.yml`).

Do not change the template's functional code — only update the comment block.

