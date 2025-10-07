# Azure DevOps YAML Pipeline Templates

Centralised repository for reusable Azure DevOps (AzDO) YAML pipeline templates used across projects. These templates enforce consistency, compliance, and best practices for building, testing, and deploying workloads on Azure.

---

## 🎯 Purpose

Provide a **single source of truth** for standardised pipeline templates that:

- Promote reusable and composable pipeline design.
- Enforce security, quality, and compliance checks.
- Support both .NET and platform-agnostic workloads.
- Align with Azure Landing Zone (ALZ) and internal DevOps standards.

---

## 🧩 Repository Structure

```text
devops-azdo-yaml-pipeline-templates/
├── .github/
│   ├── copilot-instructions.yml
├── cicd/
│   ├── example_cicd.yml
├── docs/
│   └── example_doc.yml
├── jobs/
│   ├── example_job.yml
├── pipelines/
│   ├── example_pipeline.yml
├── tasks/
│   ├── example_task.yml
├── scripts/
│   └── example_script.ps1
│   └── example_script.bash
├── stages/
│   ├── example_stage.yml
├── variables/
│   └── example_variable.yml
├── .editorconfig
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
└── SECURITY.md
```
