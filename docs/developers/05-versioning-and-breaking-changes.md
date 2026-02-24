# Versioning & Breaking Changes

This repository follows [Semantic Versioning 2.0.0](https://semver.org/): `vMAJOR.MINOR.PATCH`.

| Change type  | Version bump | Examples                                                                                                                                                                                |
|--------------|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Breaking** | Major        | Adding required parameters, renaming/removing parameters, changing parameter types, modifying outputs, removing/restructuring steps/jobs/tasks, changing defaults that affect consumers |
| **Feature**  | Minor        | Adding optional parameters, adding new templates, adding new steps/jobs that don't affect existing behaviour                                                                            |
| **Fix**      | Patch        | Bug fixes, internal refactors, documentation improvements                                                                                                                               |

## Subtle Breaking Changes

These may look minor but **are breaking**:

- **Renaming a task or job**: Consumers may depend on the name to access outputs or variables.
- **Rearranging jobs/steps**: Changes execution order and may break dependency chains.
- **Upgrading tool versions** (e.g. Terraform): If the new version introduces its own breaking changes, consumers are affected.

## Breaking Change Process

1. Evaluate whether the breaking change is truly necessary.
2. Increment the **major** version.
3. Document the change in the CHANGELOG.
4. Add inline comments in the affected template files.
5. Provide a migration guide explaining how to upgrade.

For the full versioning guide, see [How to Version Templates](how-to-version.md).

---

[← Back to Developer Documentation](README.md)

