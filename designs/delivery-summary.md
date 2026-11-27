# Azure DevOps Pipeline Templates – Delivery Summary

**Period:** Sep 2025 – Oct 2026 · **Allocation:** about 1 day per week · **Releases:** `0.1.0` → `0.3.1` (4 tagged)

## What It Is

A central, versioned library of Azure DevOps pipeline templates. Teams can use a ready-made Terraform pipeline or combine six job templates, instead of each team building and maintaining its own.

## What Each Release Delivered

| Release | Delivered |
|---|---|
| **Foundations** (Sep 25 – May 26) | Layered template design. Research spikes on how Azure DevOps variables and parameters behave. A PowerShell compile-test framework. Linux and Windows test pipelines. First AI instructions |
| **0.1.0** (May 26) | First public release: an end-to-end Terraform pipeline with build, deploy, gated deployment, and manual approval jobs |
| **0.2.0** (Jun 26) | Multiple secret sources (`ConfigSources`). The old approach was deprecated with an upgrade guide |
| **0.3.0** (Aug 26) | Safe, gated infrastructure **teardown** (destroy jobs). Approval timeouts can be set per environment |
| **0.3.1** (Oct 26) | Security hardening (read-only internals, insecure sign-in removed). More precise validation |
| **In progress** | Full documentation overhaul and AI-agent context (`AGENTS.md`, architecture, design philosophy, skills) |

## The Platform Behind the Templates

- **Over 75 automated test scenarios.** Each stores a copy of its compiled output, so any behaviour change is visible in review. Real Terraform deployments run on Linux and Windows.
- **Quality gates:** pull requests need an approval and passing tests before merge. YAML and EditorConfig linting run on every pull request. Release tags can't be deleted.
- **The repository's own setup is managed as code** (GitHub rules, test pipelines, and service connections in Terraform).
- **Around 30 documentation pages:** user guides, configuration references, an upgrade guide, and a structured developer guide.
- **Written engineering principles:** fail fast at compile time, a narrow public API, protected internals, cross-platform, and no paid extensions.

## AI-Ready Development

The repository's standards, boundaries, and processes are now written down in a form AI agents load automatically. Agents can scaffold templates, write tests, update documentation and the changelog, and review code to those standards. My role shifts from sole author to **director and reviewer**. This is what lets a 1-day-per-week allocation keep growing its output.

## Benefits to the Business

- **Faster delivery:** teams adopt a tested pipeline in minutes instead of building one.
- **Lower risk:** human approval before every apply and destroy, bad configuration rejected before anything runs, and releases that can't change once published.
- **Predictable upgrades:** Semantic Versioning, a changelog, and upgrade guides.
- **Audit and compliance:** everything is defined as code and every change goes through a reviewed pull request.
- **Lower cost:** no licensed extensions, and fixes are made once for every team.
- **Less key-person risk:** the knowledge is documented, not held in one person's head.

## What Is Next

1. Release the documentation and AI-readiness overhaul.
2. **`0.4.0`:** a .NET build template (already in progress).
3. Bring in explored work: Azure App Configuration secrets, Snyk security scanning, and Web App deployment.
4. Drive adoption across teams and stabilise towards `1.0.0`.
5. Move more of the implementation to AI agents, with my oversight.
