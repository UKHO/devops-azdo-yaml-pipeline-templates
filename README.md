# Azure DevOps YAML Pipeline Templates

Reusable, versioned Azure DevOps YAML Pipeline templates that give teams consistent, production-ready, flexible templates.

## What is available

This repository follows a **set-menu + salad bar** model. Only the templates listed here are the supported public surface; everything else in the repository is an internal building block and may change without notice.

Browse the full [user documentation](docs/user-docs/README.md) for usage and upgrade guides, and the [definition docs](docs/definition_docs) for the structure of each configuration object.

### Set-menu: ready-to-use pipeline templates

Use these when you want an end-to-end pipeline with minimal setup.

| Template                                                               | Purpose                                                                                                                         | Documentation                                                        |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| [`pipelines/terraform_pipeline.yml`](pipelines/terraform_pipeline.yml) | End-to-end Terraform pipeline: build, validate, package, and deploy across multiple environments with manual verification gates | [Terraform Pipeline](docs/user-docs/pipelines/terraform_pipeline.md) |

### Salad bar: modular job templates for custom pipelines

Use these to compose your own workflow.

| Template                                                                     | Purpose                                                                                 | Documentation                                                                       |
| ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [`jobs/terraform_build.yml`](jobs/terraform_build.yml)                       | Builds, validates, and packages Terraform files                                         | [Terraform Build Job](docs/user-docs/jobs/terraform_build.md)                       |
| [`jobs/terraform_deploy.yml`](jobs/terraform_deploy.yml)                     | A single Terraform deployment step (plan or apply)                                      | [Terraform Deploy Job](docs/user-docs/jobs/terraform_deploy.md)                     |
| [`jobs/terraform_gated_deployment.yml`](jobs/terraform_gated_deployment.yml) | Complete deployment workflow (plan → verify → apply) with configurable run modes        | [Terraform Gated Deployment Job](docs/user-docs/jobs/terraform_gated_deployment.md) |
| [`jobs/terraform_destroy.yml`](jobs/terraform_destroy.yml)                   | A single Terraform destroy step (plan-destroy or destroy) using packaged artifacts      | [Terraform Destroy Job](docs/user-docs/jobs/terraform_destroy.md)                   |
| [`jobs/terraform_gated_destroy.yml`](jobs/terraform_gated_destroy.yml)       | Complete destroy workflow (plan-destroy → verify → destroy) with configurable run modes | [Terraform Gated Destroy Job](docs/user-docs/jobs/terraform_gated_destroy.md)       |
| [`jobs/manual_verification.yml`](jobs/manual_verification.yml)               | Reusable manual approval gate with configurable timeouts and notifications              | [Manual Verification Job](docs/user-docs/jobs/manual_verification.md)               |

## Reference this repository

In your consumer `azure-pipelines.yml`, add this repository as a template resource:

```yaml
resources:
  repositories:
    - repository: AzDOPipelineTemplates
      type: github
      endpoint: UKHO
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: refs/tags/0.3.1
```

Then reference templates using `@AzDOPipelineTemplates`, for example `- template: jobs/<template>.yml@AzDOPipelineTemplates`.

- **Keep the repository alias as `AzDOPipelineTemplates`.** The templates use this name internally (it is the default `CheckoutAlias`) to check out this repository for their own scripts, so a different alias will break them.
- **Always pin `ref` to a specific tagged release** (`MAJOR.MINOR.PATCH`). Tags are immutable: they are never moved once pushed, and repository rulesets protect them from deletion. An unpinned reference (e.g. `ref: refs/heads/main`, or omitting `ref` entirely) receives every merge to `main` immediately, with no warning.

## Stability and quality

The goal is templates you can depend on: they should not break your pipelines, and changes should arrive in a way you can predict. Three things deliver that.

- **Backward compatibility is the contract.** Everything in the public surface above is protected against breaking changes. A change that would break existing consumers is only released as a new major version, with an upgrade guide. See the [Versioning Policy](docs/developers/reference/versioning-policy.md).
- **Semantic Versioning is how that is communicated.** Releases follow [Semantic Versioning 2.0.0](https://semver.org/), so the version number tells you whether an upgrade is safe to take.
- **Automated testing gates every change.** Template changes are covered by a PowerShell compile-test framework ([`tests/framework`](tests/framework)) with test suites per template under [`tests`](tests), and the suite must pass before a Pull Request can merge to `main`. It verifies YAML expansion; runtime behaviour is validated separately by running fixture pipelines in Azure DevOps. See [Test a Template](docs/developers/how-to/test-a-template.md).

Compilation alone does not guarantee that `main` is as stable as a tagged release. Pinning a tagged `MAJOR.MINOR.PATCH` version is the only way to get a fixed, reproducible set of templates, so pin a tag for any production consumer pipeline.

## Design philosophy

These templates are built on a few deliberate principles. Each links to its full rationale in [Design Philosophy](docs/developers/explanation/design-philosophy.md).

- [**Behavioural solutions, not building blocks**](docs/developers/explanation/design-philosophy.md#behavioural-solutions-not-building-blocks): public templates deliver complete outcomes, so you adopt behaviour instead of assembling low-level steps.
- [**Narrow public surface**](docs/developers/explanation/design-philosophy.md#public-vs-internal): only a small, versioned set of templates is public, which lets the internals evolve without breaking you.
- [**Layered templates**](docs/developers/explanation/design-philosophy.md#layered-templates): small pieces compose into larger ones, with the composed behaviour covered by compile tests.
- [**Fail fast at compile time**](docs/developers/explanation/design-philosophy.md#fail-fast-at-compile-time): bad input is rejected before any agent runs.
- [**Fully-declared, self-documenting parameters**](docs/developers/explanation/design-philosophy.md#fully-declared-self-documenting-parameters): required inputs have no default and fail loudly; the declaration is the contract.
- [**Protected internal state**](docs/developers/explanation/design-philosophy.md#protect-template-internal-state): template-internal variables are `readonly`, so consumers cannot silently override them.
- [**Defensive rendering**](docs/developers/explanation/design-philosophy.md#defensive-safe-rendering): templates produce valid output or a clear compile-time error, never something subtly wrong.
- [**Cross-platform and open-source**](docs/developers/explanation/design-philosophy.md#cross-platform-and-open-source-by-default): run on Windows and Linux agents, preferring built-in or open-source tasks over paid Marketplace extensions.

## Feedback and contributing

These templates exist to make your pipelines easier, so we want to hear how they work for you. If you have feedback, a question, a bug report, or an idea for a new template, please get in touch by [raising an issue](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/issues).

Contributions are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md), and see the [developer documentation](docs/developers/README.md) for conventions and how to test a change. To see what has changed between releases, read the [CHANGELOG](CHANGELOG.md).
