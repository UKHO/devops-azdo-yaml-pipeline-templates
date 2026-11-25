# Pitch: Shared Pipeline Templates

## Where Each Claim Comes From

- **From the repo:**
  - Template coverage and the plan/approve/apply flow.
  - Validation, read-only internals, tagged releases, and protected tags.
  - Over 75 compile tests, Linux and Windows test deployments, and pull-request gates.
  - Four releases (May–Oct 2026), the .NET build template on a branch, and the contributor split.
  - Gaps: apply doesn't use the saved plan, Snyk is unreleased, the version is pre-1.0, and there is no usage tracking.
- **From your answers:**
  - Adopting teams: Tamatoa, O11y, Calypso, Varuna, and IDAM.
  - Non-adopting cloud teams: A'Tuin, Mazu, and Cthulhu.
  - Adoption blockers: awareness, limited time, migration effort, and "good enough" inertia.
  - .NET build and deploy is the next target.
  - The 1-day-per-week allocation, from our earlier conversation.
- **External:** no web search was available. The Further Reading links are well-known Microsoft, DORA, CNCF and HashiCorp pages listed from memory. **Check each link before sending.** The text only paraphrases their general position and makes no specific claims from them.

---

## Part A: Email

**Subject:** Five teams now share one deployment pipeline. Should the rest?

Hi [NEEDED: name],

We don't have a DevOps team, so every team builds and maintains its own deployment pipelines. That means the same work is repeated in each team, safety practices vary from team to team, and an org-wide improvement has to be made [NEEDED: number of teams/pipelines] times. Most teams stop once their pipeline "works well enough", and that limits how safely and quickly we ship.

For the past year I've spent about a day a week building a shared library of pipeline templates as the alternative. A team references a tested, versioned template instead of writing its own. Every infrastructure change is previewed before it's made. Changes that delete things need a human sign-off. Bad configuration is rejected before anything runs. Teams choose when to take each new version, so nothing changes under them unexpectedly.

Five teams already use it: Tamatoa, O11y, Calypso, Varuna, and IDAM. [NEEDED: one concrete result or quote from an adopting team.] A'Tuin, Mazu, and Cthulhu deploy to the cloud too, but still maintain their own pipelines.

Two things are holding it back:
- **Awareness and incentive:** teams rarely replace a pipeline that works.
- **Capacity:** I'm the main contributor, so progress is limited and it depends on one person.

The next step is .NET build and deploy templates. They would extend the same benefits to application delivery, not just infrastructure.

**My ask:** would you sponsor this? That means protecting my time on it, plus visibly backing adoption, for example by making the templates the expected default for new projects. A short write-up with coverage, risks, and a roadmap is attached.

Happy to walk you through it in 20 minutes.

Thanks,
[NEEDED: your name]

---

## Part B: Supporting Material

### What the Templates Cover

| Template | Purpose | Status |
|---|---|---|
| Terraform pipeline | End-to-end build → plan → approve → apply across multiple environments | Released (`0.3.1`) |
| Terraform build job | Initialises, validates, and packages Terraform as a versioned build artifact | Released |
| Terraform deploy job | Plans or applies to a named Azure DevOps environment, with backend config, Key Vault secrets, and output export | Released |
| Terraform gated deployment | Plan → manual approval → apply, with run modes and approval timeouts | Released |
| Terraform destroy / gated destroy | Previews a teardown and destroys only after approval | Released (`0.3.0`) |
| Manual verification | Reusable approval gate with timeout behaviour | Released |
| .NET build | Builds zip and container outputs, with validated configuration | In development (branch, planned `0.4.0`) |
| .NET deploy | Web App slot deploy with health check | Early prototype |
| Security scanning (Snyk IaC) | Scans infrastructure code during build | Drafted, not released |

### What's Built In

- **Plan, approve, then apply.** These are separate steps, and approval can be required for every change or only when something would be destroyed.
- **Validation before anything runs.** Bad configuration fails the pipeline immediately.
- **Protected internals.** Variables the templates use internally can't be overridden by consuming pipelines.
- **Safe versioning.** Teams pin an exact release. Release tags can't be deleted, and a changelog and upgrade guides are maintained.
- **Testing:**
  - Over 75 automated test scenarios.
  - Real test deployments on Linux and Windows.
  - Every change needs an approval and passing checks before merge.
- **No paid extensions, and no lock-in to one operating system.**

### Evidence and Adoption So Far

- **Adopting teams:** Tamatoa, O11y, Calypso, Varuna, IDAM.
- **Still to adopt (cloud-deploying teams):** A'Tuin, Mazu, Cthulhu, plus [NEEDED: any others].
- **Delivery record:**
  - 4 releases between May and October 2026, with one migration supported by a written upgrade guide.
  - Ongoing activity: 167 commits across all branches since mid-April 2026.
- **Results from adopters:** [NEEDED: feedback, time saved, or incidents avoided].
- **Baseline cost of today's approach:** [NEEDED: rough time per team to build and maintain a pipeline].
- **Incidents or audit findings this would have prevented:** [NEEDED, if any and shareable].

### Risks and Mitigations

| Risk | Mitigation |
|---|---|
| **Key-person risk.** Almost all commits are mine. | Docs, architecture, and AI-agent instructions are written down. Ask: [NEEDED: a second maintainer from an adopting team] |
| **Maintenance load grows with adoption** | Narrow public surface (pipeline and job templates only). Automated tests. AI-assisted changes with human review |
| **Low adoption.** "Good enough" pipelines don't get replaced. | Sponsorship: templates become the default for new projects. Migration examples |
| **Apply doesn't use the approved plan.** It re-plans, so what's applied could differ from what was reviewed. | Fix by applying the saved, approved plan. Scheduled first on the roadmap |
| **No security scanning in released templates** | Release the drafted Snyk IaC scan |
| **Pre-1.0, so the public interface isn't formally stable** | Strict versioning already in place. Target a `1.0.0` stability commitment |
| **No usage visibility** | Track adopting repositories and pinned versions [NEEDED: method] |
| **If unsupported** | The templates keep working at their pinned versions, but fixes, .NET coverage, and onboarding stop. Teams carry on building their own pipelines |

### Proposed Roadmap (dates to confirm)

- **Next quarter [NEEDED: dates]:**
  - Fix apply-from-approved-plan.
  - Release the Snyk scan.
  - Release `0.4.0`, the .NET build template.
  - Collect feedback from the five adopting teams.
- **Quarter 2:**
  - .NET deploy template.
  - Onboard A'Tuin, Mazu, and Cthulhu, or record why not.
  - A named second maintainer.
- **Quarter 3:**
  - `1.0.0` stability commitment.
  - Templates become the default for new projects.
  - Adoption and outcome review with [NEEDED: metrics agreed with sponsor].

### Further Reading (unverified, check before sending)

- Microsoft: [Azure Pipelines templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates). Shows that reusable templates are the platform's intended way to share pipeline logic.
- Microsoft: [Security through templates](https://learn.microsoft.com/azure/devops/pipelines/security/templates). Describes enforcing standards through required templates.
- Microsoft: [Approvals and checks](https://learn.microsoft.com/azure/devops/pipelines/process/approvals). Covers environment approvals as a deployment control.
- DORA: [Research programme](https://dora.dev/research/) and [capabilities](https://dora.dev/capabilities/). Links delivery automation and platform practices to delivery performance.
- CNCF: [Platforms white paper](https://tag-app-delivery.cncf.io/whitepapers/platforms/). Argues for shared internal platforms that reduce duplicated effort across teams.
- HashiCorp: [Running Terraform in automation](https://developer.hashicorp.com/terraform/tutorials/automation/automate-terraform). Describes the plan, review, then apply-the-saved-plan workflow.

### Open Items

- [NEEDED: Head of Engineering's name] and [NEEDED: your name].
- [NEEDED: number of teams or pipelines across the org].
- [NEEDED: one concrete result or quote from an adopting team].
- [NEEDED: adopter feedback, time saved, or incidents avoided].
- [NEEDED: rough time per team to build and maintain a pipeline].
- [NEEDED: incidents or audit findings, if shareable].
- [NEEDED: any other cloud-deploying teams].
- [NEEDED: candidate second maintainer].
- [NEEDED: how adoption will be tracked].
- [NEEDED: roadmap dates].
- [NEEDED: success metrics agreed with the sponsor].
- Your sponsorship preference: encourage adoption or mandate it for new projects. The email says "expected default".
- Check every Further Reading link.
