# Developer Documentation

Welcome to the developer documentation for the Azure DevOps YAML Pipeline Templates repository. Start with [`ARCHITECTURE.md`](../../ARCHITECTURE.md) for the codemap, then use the sections below.

Pages are organised by type:

- **How-to** — task-oriented steps, for when you already know the basics.
- **Reference** — precise, complete description of a convention or policy.
- **Explanation** — background and rationale for a design decision.
- **ADR** — a permanent record of one significant decision.

---

## How-to

| Guide | Use when you need to... |
| --- | --- |
| [Test a Template](how-to/test-a-template.md) | Run the compile/test framework and follow the PR process |
| [Release a Version](how-to/release-a-version.md) | Ship a breaking change or tag a release |
| [Update the Changelog](how-to/update-the-changelog.md) | Write a `CHANGELOG.md` entry |

## Reference

| Guide | Covers |
| --- | --- |
| [YAML Standards](reference/yaml-standards.md) | AzDO YAML limitations, formatting, naming conventions |
| [Template Conventions](reference/template-conventions.md) | Parameters, variable scoping, decomposition, anti-patterns |
| [Schema Validation](reference/schema-validation.md) | Compile-time object validation: the mechanism and pattern catalogue |
| [Scripts & Tooling](reference/scripts-and-tooling.md) | Language policy, when to script, file paths, IDE setup |
| [Versioning Policy](reference/versioning-policy.md) | SemVer rules, public API scope, breaking-change examples |
| [Branching Model](reference/branching-model.md) | Branch naming, PR workflow, what is not branched |

## Explanation

| Guide | Covers |
| --- | --- |
| [Design Philosophy](explanation/design-philosophy.md) | Why set-menu + salad bar |
| [Double Wrapping](explanation/double-wrapping.md) | Why wrapping templates in templates went wrong, and the fix |
| [Checkout and Path Behaviour](explanation/checkout-and-path-behaviour.md) | Why double-checkout jobs need an explicit `path` |
| [AI & Documentation](explanation/ai-and-documentation.md) | AI usage policy, and which `.github/` agent files exist and who owns them |

## Architecture Decision Records

See [`adr/`](adr/README.md) for the ADR process and index.
