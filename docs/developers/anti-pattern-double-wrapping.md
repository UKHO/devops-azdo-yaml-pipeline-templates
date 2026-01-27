# Anti-Pattern: Double Wrapping

Some pipeline templates may initially seem to benefit from additional wrapper templates to simplify usage or parameter passing. However, introducing multiple layers of wrappers—referred to here as **base wrappers** and **secondary wrappers**—can lead to maintenance challenges and unnecessary complexity.

For example, consider the use of a `terraform_base.yml` template wrapping the `TerraformTask@2`. To simplify specific commands, secondary wrappers like `terraform_init.yml` and `terraform_validate.yml` were created:

```yaml
# terraform_validate.yml
# Purpose: Secondary wrapper for the validate command using the base wrapper
steps:
  - template: terraform_base.yml
    parameters:
      Command: validate
```

The `terraform_init.yml` secondary wrapper was more justified, as it handled a special case where `terraform init -backend=false` required no service connection:

```yaml
# terraform_init.yml
parameters:
# ...existing code...
```

> **Guidance:** Avoid double-wrapping unless absolutely necessary. Prefer direct inclusion of steps, jobs, or tasks to keep templates simple and maintainable.

---

*This document was moved from `docs/` to `docs/developers/` for central developer reference. See the developer documentation index for more anti-patterns and best practices.*
