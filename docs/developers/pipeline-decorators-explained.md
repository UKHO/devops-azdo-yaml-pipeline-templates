# Azure DevOps Pipeline Decorators - Complete Guide

Pipeline decorators are Azure DevOps extensions that automatically inject steps into pipelines across your organization or project without requiring changes to individual pipeline YAML files.

## Table of Contents
1. How Decorators Work
2. Decorator Structure
3. Real-World Examples
4. Key Differences: Decorators vs Templates

---

## How Decorators Work

Decorators are defined as Azure DevOps extensions and can inject steps at four injection points:

- **Pre-job**: Before a job starts (before checkout)
- **Post-job**: After a job completes (success or failure)
- **Pre-checkout**: Immediately before source checkout
- **Post-checkout**: Immediately after source checkout

// ...existing code...

---

*This document was moved from `docs/` to `docs/developers/` for advanced topics reference. See the developer documentation index for more details.*
