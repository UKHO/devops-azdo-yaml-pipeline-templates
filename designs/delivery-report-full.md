# Azure DevOps Pipeline Templates – Full Delivery Record

This is the long-form record of what has been delivered in `UKHO/devops-azdo-yaml-pipeline-templates`. It is meant to be reduced to a one-page summary.

## 1. At a Glance

| Measure | Value |
|---|---|
| First commit | 19 September 2025 |
| Allocation | About 1 day per week, roughly 3 days per month in practice |
| Releases | 4 tagged: `0.1.0`, `0.2.0`, `0.3.0`, `0.3.1` |
| Merged pull requests / commits | About 30 pull requests, 58 commits on the current branch |
| Public templates | 1 pipeline and 6 job templates |
| Internal building blocks | 11 task templates, 2 stage templates, 6 schemas, 3 utilities |
| Automated test scenarios | Over 75 job-level compile scenarios, plus pipeline fixtures (Linux, Windows, Elastic) |
| Documentation | About 30 pages: user guides, definition references, upgrade guide, developer guide |
| AI context | Agent and Copilot instructions, 3 scoped rule files, 2 agent skills |

## 2. Timeline by Release

### Foundations (Sep 2025 – Jan 2026), before `0.1.0`

- Set up the repository: EditorConfig, contributing guide, and the founding documentation (#1, #5).
- Built the first Terraform deploy template, then the full task → job → stage → pipeline layering (#4, #7).
- Wrote the first user documentation for the infrastructure pipeline (#12).
- **Research spikes** recorded as runnable examples (`examples/`):
  - How Azure DevOps variables behave at pipeline, stage, and job scope (#13).
  - How pipeline parameters behave (#15).
  - These removed guesswork about platform behaviour that the templates rely on.

### Hardening (Jan – May 2026), still before `0.1.0`

- **Terraform deploy job** (#9) and **extended Terraform provider support** (#35), including service-connection-authenticated runs and an Elastic provider test fixture.
- **AI tooling (#25):** the first Copilot instructions, YAML and Markdown rule files, and prompts for scaffolding and auditing. This is when AI-assisted development started in the repo.
- **Developer documentation (#26)** for future contributors.
- **Compliance testing pipeline (#27):** Linux and Windows fixture pipelines, file-packaging support, and a repository-checkout step list.
- **PowerShell compile-test framework (#29, #32, #34, #37):**
  - Compiles templates against Azure DevOps locally and in CI.
  - Can save the compiled YAML for review.
  - Includes default pipeline tests and unit tests for the Terraform templates.
- **Robustness (#36):** better debug logging and error handling in the Terraform PowerShell scripts.
- **Professionalism and portability (#31, #33):** template paths changed to absolute references, and validation messages cleaned up.

### `0.1.0` (May 2026): first public release

- An end-to-end **Terraform pipeline**: build, validate, package, and deploy to multiple environments with manual verification gates.
- **Job templates:** Terraform build, deploy, gated deployment (plan → verify → apply), and manual verification.
- Supporting task and stage templates, schema validation, and the test framework with baseline suites.
- Consumers could pin a tagged version from this point. Release notes and reference updates followed (#60).

### `0.2.0` (June 2026): multi-source secrets

- **`ConfigSources`:** a composable list of secret providers, which allows multiple Key Vaults per deployment.
- Deprecated the legacy single `KeyVaultConfig`, with a written **upgrade guide** so consumers can migrate on their own schedule.
- More consistent validation errors and expanded test coverage.
- **Pipeline cost saving:** test pipelines no longer run on draft pull requests (#66).

### `0.3.0` (August 2026): safe teardown

- New **Terraform destroy** and **gated destroy** jobs (plan-destroy → human verification → destroy), with `PlanOnly`, `DestroyOnly`, and `PlanVerifyDestroy` modes.
- The verification timeout and timeout behaviour can now be set per environment, for both deploy and destroy.
- **Test fix:** some gated tests were not actually triggering the approval gate. They now do.

### `0.3.1` (October 2026): security and correctness

- **Security:**
  - Template-internal variables are now `readonly`, so consumers can't override them.
  - An insecure device-code sign-in flag was removed from the test framework.
- **Correctness:**
  - Schema validation was split so each job validates only what it uses.
  - Added a dedicated schema for gated destroy, which previously had none.
- **Flexibility:** build injection steps now accept conditional step expressions.
- Merged the separate deploy and destroy configuration docs into one reference.

### Unreleased, in progress (October 2026): documentation and AI-readiness overhaul

- Reorganised all documentation into the **Diátaxis** structure: how-to, reference, and explanation.
- New **`AGENTS.md`** and **`ARCHITECTURE.md`**, a written **Design Philosophy** (which replaced the earlier architecture decision records), a versioning policy, a branching model, and a release process.
- Replaced ad-hoc prompt files with **agent skills** (code review, PowerShell). Rule files are now scoped by file type.
- Rewrote the README around the public API, version pinning, and the stability contract.

## 3. Supporting Platform (Beyond the Templates)

- **Test framework** (`tests/framework`): authentication, pre-flight checks, parameterised and directory test runners, and compiled-YAML snapshots. Every behaviour change is visible in the pull request diff.
- **Runtime fixtures** (`tests/shared_resources`): real Terraform configurations (basic, resource group, Elastic, additional files) that are actually deployed by test pipelines in Azure DevOps.
- **Infrastructure-as-code for the repository itself** (`cicd/`), managed with Terraform:
  - GitHub rulesets: linear history, 1 required approval, required review-thread resolution, and required status checks.
  - Tags can't be deleted, so releases can't be changed after publication.
  - The Azure DevOps test pipeline definitions, service connections, environment, and pipeline authorisations.
- **GitHub Actions linting:** EditorConfig and `yamlfmt` checks on every pull request.
- **Tooling:** a script that bumps the Terraform version across the whole repository in one step.

## 4. Engineering Principles Established

These principles are documented and enforced through review and tests:
- A narrow public API (only `pipelines/` and `jobs/`).
- Behavioural templates rather than low-level building blocks.
- Fail fast at compile time.
- Fully declared, self-documenting parameters.
- Protected internal state (`readonly` variables).
- Defensive rendering: valid output or a clear error, never something subtly wrong.
- Validated configuration objects.
- Cross-platform (Windows and Linux) and built on open-source tasks only, with no paid extensions.
- No double-wrapping of templates.

## 5. AI-Ready Development Model

- **Always-loaded context:** `AGENTS.md`, `.github/copilot-instructions.md`, `ARCHITECTURE.md`.
- **Rules scoped by file type:** YAML pipeline standards, documentation-update rules, and Markdown rules.
- **On-demand skills:** code review and PowerShell Core.
- **Policy is written down:** what counts as public, how to version, how to update the changelog, what an agent must not do (for example, tag releases), and when it must ask first.
- **Outcome:**
  - An AI agent can scaffold templates, write tests, update documentation and the changelog, and review changes to the repository's standards.
  - The developer's role moves to direction, review, and approval.
  - This is how a 1-day-per-week allocation can keep pace.

## 6. Work in Progress and Explored (Not Yet Released)

| Branch / area | Status |
|---|---|
| .NET build template (`feature/0.4.0/dotnet-build`) | Trial build, configuration schema, and example project. Planned as `0.4.0` |
| Azure App Configuration in `ConfigSources` | Implemented with tests for single, multiple, and mixed sources |
| Snyk IaC security scanning in Terraform build | Task template, tests, and documentation drafted |
| Web App deploy to slot with health check | Early prototype (Windows) |
| Database build YAML | Early prototype |

## 7. Benefits to the Business

- **Speed:** teams adopt a tested Terraform pipeline instead of building their own.
- **Consistency:** one standard, reviewed way to build, deploy, and tear down infrastructure.
- **Risk reduction:**
  - Human approval gates on apply and destroy.
  - Bad configuration is rejected at compile time.
  - Internal variables can't be overridden.
  - Releases can't be changed after publication.
- **Predictable change:** SemVer, the changelog, and upgrade guides let consumers upgrade on their own terms.
- **Audit and compliance:** pipelines, repository rules, and test infrastructure are all defined as code, with reviewed pull requests.
- **Cost:** no paid Marketplace extensions, and no wasted runs on draft pull requests.
- **Resilience:** the knowledge is written down, which lowers key-person risk.
- **Leverage:** the AI-ready foundation increases the output of a part-time allocation.

## 8. What Is Next

1. Finish and release the documentation and AI-readiness overhaul.
2. Release `0.4.0` with the .NET build template.
3. Bring in the explored work: App Configuration sources, Snyk scanning, and Web App deploy.
4. Drive adoption across teams and use their feedback to work towards a stable `1.0.0`.
5. Move more implementation to AI agents, with the developer reviewing and approving.
