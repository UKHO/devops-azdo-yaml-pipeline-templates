# YAML Standards & Best Practices

## Azure DevOps YAML Limitations

Standard YAML features that **do not work** in Azure DevOps:

- **Anchors & aliases** — partially supported, unreliable across files. Avoid them.
- **Merge keys & custom tags** — not supported.
- **Multi-document YAML** (`---`) — not supported.
- **Some data types** (timestamp, binary) — not implemented.

## Formatting & Naming

- **Indentation**: 2 spaces (enforced by `.editorconfig`).
- **Template filenames**: use `lowercase_snakecase` (for example, `terraform_plan_verify_apply_job_list.yml`).
- **File extension**: `.yml` (not `.yaml`), consistent with Microsoft's default `azure-pipelines.yml`.
- **No type in template filenames**: use `template.yml`, not `job_template.yml`. For lists, use a suffix like `_job_list.yml`.

## Key Patterns

- **Compile-time expressions** (`${{ }}`): Use for parameter injection, conditional inclusion of steps/jobs, and `foreach` loops.
- **`displayName`**: Always provide clear, descriptive display names on steps, jobs, and stages.
- **Comments**: Document templates with YAML comments. Keep inline comments concise.

## Common Pitfalls

- **Conditions** are not validated at compile time — errors surface only at runtime. Test thoroughly.
- **Parameter passing** with complex objects can be tricky. Use compile-time expressions carefully.
- **Indentation errors** cause silent failures. Rely on your IDE and `.editorconfig`.

---

[← Back to Developer Documentation](README.md)

