# Open-Source Alternatives to Snyk Scanning

Snyk covers four scanning domains: **App** (SCA/dependencies), **Container**, **Code** (SAST), and **IaC**. Here are open-source alternatives for each:

---

## 🏆 Trivy (Aqua Security) — Best All-in-One Replacement

| Snyk Scan Type  | Trivy Equivalent                                    | Command                                                  |
|-----------------|-----------------------------------------------------|----------------------------------------------------------|
| **App** (SCA)   | `trivy fs --scanners vuln`                          | Scans lockfiles/manifests for vulnerable dependencies    |
| **Container**   | `trivy image <image>`                               | Scans container images for OS & app vulnerabilities      |
| **Code** (SAST) | `trivy fs --scanners secret,misconfig`              | Secret detection + misconfiguration (limited SAST)       |
| **IaC**         | `trivy config .` or `trivy fs --scanners misconfig` | Terraform, CloudFormation, Dockerfiles, Kubernetes, Helm |

**Verdict:** Trivy is the closest single-tool replacement for Snyk. It's fully open-source (Apache 2.0), actively maintained, has an offline DB mode, and covers all four domains. Its SAST capability is lighter than Snyk Code but covers misconfigurations and secrets well.

---

## Per-Domain Alternatives

### 1. App / SCA (Dependency Vulnerability Scanning)

| Tool                       | License    | Languages/Ecosystems                  | Notes                                                           |
|----------------------------|------------|---------------------------------------|-----------------------------------------------------------------|
| **Trivy**                  | Apache 2.0 | Most major ecosystems                 | Best all-rounder                                                |
| **Grype** (Anchore)        | Apache 2.0 | Most major ecosystems                 | Fast, pairs with Syft for SBOM generation                       |
| **OSV-Scanner** (Google)   | Apache 2.0 | Most major ecosystems                 | Uses the OSV database (aggregates NVD, GitHub Advisories, etc.) |
| **OWASP Dependency-Check** | Apache 2.0 | .NET, Java, Node.js, Python, Ruby, Go | Mature, NVD-backed, Azure DevOps extension available            |
| **pip-audit**              | Apache 2.0 | Python only                           | Lightweight, PyPI-focused                                       |
| **npm audit**              | Built-in   | Node.js only                          | Ships with npm                                                  |
| **cargo-audit**            | Apache 2.0 | Rust only                             | RustSec Advisory DB                                             |

### 2. Container Image Scanning

| Tool                | License    | Notes                                                                         |
|---------------------|------------|-------------------------------------------------------------------------------|
| **Trivy**           | Apache 2.0 | OS packages + app dependencies in images                                      |
| **Grype**           | Apache 2.0 | Pairs with Syft for SBOM-based scanning                                       |
| **Clair** (Red Hat) | Apache 2.0 | API-driven, good for registry integration                                     |
| **Anchore Engine**  | Apache 2.0 | Policy-based image scanning, more enterprise features                         |
| **Docker Scout**    | Free tier  | Built into Docker Desktop/CLI (not fully open-source but free tier available) |

### 3. Code / SAST (Static Application Security Testing)

| Tool                | License              | Languages                                       | Notes                                                                  |
|---------------------|----------------------|-------------------------------------------------|------------------------------------------------------------------------|
| **Semgrep**         | LGPL 2.1 (OSS rules) | 30+ languages                                   | Best open-source SAST — pattern-based, fast, extensive community rules |
| **SonarQube CE**    | LGPL 3.0             | 15+ languages                                   | Community Edition is free; strong code quality + security rules        |
| **CodeQL** (GitHub) | MIT (engine)         | C/C++, C#, Go, Java, JS/TS, Python, Ruby, Swift | Powerful but tied to GitHub Actions (free for public repos)            |
| **Bandit**          | Apache 2.0           | Python only                                     | Lightweight Python SAST                                                |
| **Gosec**           | Apache 2.0           | Go only                                         | Go-specific security scanner                                           |
| **Brakeman**        | MIT                  | Ruby on Rails only                              | Rails-focused                                                          |
| **Checkov**         | Apache 2.0           | IaC + some SAST                                 | Primarily IaC but expanding                                            |

### 4. IaC (Infrastructure as Code Scanning)

| Tool                     | License    | Supported IaC                                                | Notes                                                     |
|--------------------------|------------|--------------------------------------------------------------|-----------------------------------------------------------|
| **Trivy**                | Apache 2.0 | Terraform, CloudFormation, Docker, K8s, Helm                 | Integrated with its other scanners                        |
| **Checkov** (Bridgecrew) | Apache 2.0 | Terraform, CloudFormation, K8s, ARM, Bicep, Helm, Dockerfile | Most comprehensive IaC-specific scanner                   |
| **tfsec**                | MIT        | Terraform only                                               | Fast, purpose-built for Terraform (now merged into Trivy) |
| **KICS** (Checkmarx)     | Apache 2.0 | Terraform, CloudFormation, K8s, Docker, Ansible, ARM, Bicep  | Very broad IaC coverage                                   |
| **Terrascan** (Tenable)  | Apache 2.0 | Terraform, K8s, Helm, Docker, CloudFormation                 | OPA-based policy engine                                   |

---

## Recommended Combinations

### Option A: Single Tool (Simplest)
> **Trivy** — covers all four domains with one tool

### Option B: Best-of-Breed (Two Tools)
> **Trivy** (App + Container + IaC) + **Semgrep** (Code/SAST)

Trivy's SAST is limited to secrets/misconfiguration. Semgrep provides deep, pattern-based SAST across 30+ languages, making this the strongest open-source combination.

### Option C: Comprehensive (Three Tools)
> **Grype** (App/SCA) + **Trivy** (Container + IaC) + **Semgrep** (Code/SAST)

If you want specialised tools per domain with separate reporting.

---

## Azure DevOps Integration Notes

| Tool                       | Azure DevOps Integration                                                |
|----------------------------|-------------------------------------------------------------------------|
| **Trivy**                  | CLI-based — run via script task, SARIF output available for reporting   |
| **Semgrep**                | CLI-based — run via script task, SARIF output, `semgrep ci` for CI mode |
| **Checkov**                | CLI-based — pip install, SARIF/JUnit output                             |
| **OWASP Dependency-Check** | Has an official Azure DevOps extension                                  |
| **Grype**                  | CLI-based — script task, SARIF/JSON output                              |
| **OSV-Scanner**            | CLI-based — script task, JSON output                                    |

All CLI-based tools can be wrapped in a task template similar to your existing `ukho_snyk_scan_task.yml`.

---

## Summary Matrix

| Domain    | Snyk | Trivy | Semgrep | Checkov | Grype | OWASP DC | KICS |
|-----------|------|-------|---------|---------|-------|----------|------|
| App/SCA   | ✅    | ✅     | ❌       | ❌       | ✅     | ✅        | ❌    |
| Container | ✅    | ✅     | ❌       | ❌       | ✅     | ❌        | ❌    |
| Code/SAST | ✅    | 🟡¹   | ✅       | ❌       | ❌     | ❌        | ❌    |
| IaC       | ✅    | ✅     | ❌       | ✅       | ❌     | ❌        | ✅    |

¹ Trivy covers secrets and misconfigurations but not full SAST like Semgrep or Snyk Code.
