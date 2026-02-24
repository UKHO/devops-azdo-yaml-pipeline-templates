# Development Workflow & Testing

## Environment Setup

- Use an IDE with YAML support configured to follow `.editorconfig`.
- 2-space indentation and no tabs are critical formatting standards.

## Branching Strategy

- `feature/xyz` for feature work.
- `docs/abc` for documentation changes.
- Delete branches after merging.
- Prefer **rebasing** over merging from main.
- Squashing is only allowed on the main branch.
- In case of conflicts, code branches take precedence.

## Pull Request Process

1. Create a **draft PR** early for initial feedback.
2. Submit code PRs and documentation PRs separately; link them in the description.
3. Use a PR checklist to verify: display names, parameter descriptions, job/stage naming.
4. The chapter lead is the main reviewer; peer review is encouraged.

## Testing

- Run the pipeline and verify correct compilation and execution.
- For Terraform, use mock providers where available.
- Document any testing limitations in the PR.
- There are no local testing tools; validation is done by running pipelines in Azure DevOps.

---

[← Back to Developer Documentation](README.md)

