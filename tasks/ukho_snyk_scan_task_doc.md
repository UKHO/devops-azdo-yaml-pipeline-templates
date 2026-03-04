# UKHO Snyk Scan Task — Input Parameters

This document outlines all input parameters for the
[UKHO Azure Pipeline Scan Task](https://github.com/UKHO/ukho-azure-pipeline-scan-task).
Parameters are categorised by their visibility rules and usage context.

## Core Required Parameters

These parameters are required for every scan, regardless of test type.

### `serviceConnectionEndpoint`

| Property     | Value                       |
|--------------|-----------------------------|
| **Type**     | `connectedService:SnykAuth` |
| **Required** | Yes                         |
| **Default**  | *(empty)*                   |

Specifies the Snyk service connection (API token) for authentication. This
must be configured in Azure DevOps project settings before the task can run.

### `testType`

| Property          | Value                             |
|-------------------|-----------------------------------|
| **Type**          | `pickList`                        |
| **Required**      | Yes                               |
| **Default**       | `app`                             |
| **Valid options** | `app`, `code`, `container`, `iac` |

Determines which type of security scan to perform:

- `app` — Application / SCA (dependency scanning)
- `code` — SAST (static application security testing)
- `container` — Container image scanning
- `iac` — Infrastructure as Code scanning

This parameter controls visibility of other parameters and affects how other
settings behave (e.g. `monitorWhen` is forced to `never` for `code` and `iac`
test types).

### `failOnIssues`

| Property     | Value     |
|--------------|-----------|
| **Type**     | `boolean` |
| **Required** | Yes       |
| **Default**  | `true`    |

Controls whether the pipeline build should fail when Snyk detects
vulnerabilities or issues. When set to `true`, any issues matching the
severity threshold will cause the build to fail.

**Related parameters:** `failOnType`, `severityThreshold`,
`codeSeverityThreshold`

## Conditional Parameters — App / Container

These parameters are visible when `testType` is `app` or `container`.

### `dockerImageName`

| Property         | Value                             |
|------------------|-----------------------------------|
| **Type**         | `string`                          |
| **Required**     | Yes (when `testType = container`) |
| **Default**      | *(empty)*                         |
| **Visible when** | `testType = container`            |

The name (and optional tag) of the Docker container image to scan. The image
must already be built and available locally or accessible from the container
registry.

**Examples:** `myrepo/myapp:latest`, `myapp:v1.0.0`

### `dockerfilePath`

| Property         | Value                  |
|------------------|------------------------|
| **Type**         | `string`               |
| **Required**     | No                     |
| **Default**      | *(empty)*              |
| **Visible when** | `testType = container` |

Optional path to the Dockerfile for additional context during container
scanning (relative to repo root or working directory). If not provided but
`targetFile` is a Dockerfile, that will be used instead.

**Examples:** `docker/Dockerfile`, `Dockerfile`

### `targetFile`

| Property         | Value            |
|------------------|------------------|
| **Type**         | `string`         |
| **Required**     | No               |
| **Default**      | *(empty)*        |
| **Visible when** | `testType = app` |

Optional path to a specific manifest or dependency file for SCA (relative to
repo root or working directory). Examples include `package.json`, `pom.xml`,
`requirements.txt`, and `Gemfile`. If not provided, Snyk will auto-detect
manifest files.

**Examples:** `package.json`, `backend/requirements.txt`

### `severityThreshold`

| Property          | Value                                        |
|-------------------|----------------------------------------------|
| **Type**          | `pickList`                                   |
| **Required**      | No                                           |
| **Default**       | `low`                                        |
| **Valid options** | `low`, `medium`, `high`, `critical`          |
| **Visible when**  | `testType = app` or `testType = container`   |

Sets the minimum severity level for vulnerabilities to report. Only
vulnerabilities at or above this level will be included in results and may
cause the build to fail (if `failOnIssues` is `true`).

> **Note:** For code scanning, use `codeSeverityThreshold` instead. Code
> scanning does **not** support `critical` severity.

### `monitorWhen`

| Property          | Value                                      |
|-------------------|--------------------------------------------|
| **Type**          | `pickList`                                 |
| **Required**      | Yes                                        |
| **Default**       | `always`                                   |
| **Valid options** | `always`, `noIssuesFound`, `never`         |
| **Visible when**  | `testType = app` or `testType = container` |

Controls when to send monitoring data to Snyk for continuous tracking. Snyk
Monitor creates a snapshot of project dependencies in your Snyk account.

- `always` — Monitor runs after every scan (default)
- `noIssuesFound` — Monitor only runs if the scan completes with no issues
- `never` — Monitor never runs (data not sent to Snyk account)

> **Auto-override:** For test types `code` and `iac`, this is automatically
> set to `never` regardless of the configured value, as those test types use
> the `--report` workflow.

## Conditional Parameters — Code

These parameters are visible when `testType` is `code`.

### `codeSeverityThreshold`

| Property          | Value                   |
|-------------------|-------------------------|
| **Type**          | `pickList`              |
| **Required**      | No                      |
| **Default**       | `low`                   |
| **Valid options** | `low`, `medium`, `high` |
| **Visible when**  | `testType = code`       |

Sets the minimum severity level for code vulnerabilities detected by Snyk
Code (SAST). Only vulnerabilities at or above this level will be included in
results.

> **Important:** Code scanning does **not** support `critical` severity. Use
> `high` as the maximum severity for code scans.

## Optional Parameters

These parameters appear in the **Additional Settings** group and are available
for all test types.

### `failOnType`

| Property          | Value                            |
|-------------------|----------------------------------|
| **Type**          | `pickList`                       |
| **Required**      | No                               |
| **Default**       | *(none)*                         |
| **Valid options** | `all`, `patchable`, `upgradable` |

Provides granular control over which types of issues should cause a build
failure (when `failOnIssues` is `true`). This allows filtering by whether
issues are fixable.

- `all` — Fail on any detected issue (default behaviour)
- `patchable` — Fail only on issues that have a patch or update available
- `upgradable` — Fail only on issues fixable through dependency upgrades

> **Note:** Only applies to `app` and `container` test types. Ignored for
> `code` and `iac`. Only meaningful when `failOnIssues = true`.

### `projectName`

| Property     | Value     |
|--------------|-----------|
| **Type**     | `string`  |
| **Required** | No        |
| **Default**  | *(empty)* |

Custom name for this project in your Snyk account. Helps organise and
identify projects in the Snyk UI. If not provided, Snyk will generate a
default name.

> **Note:** If the project name contains spaces, it will be automatically
> quoted when passed to the Snyk CLI.

**Examples:** `MyApp-Production`, `Backend-Services`

### `organization`

| Property     | Value     |
|--------------|-----------|
| **Type**     | `string`  |
| **Required** | No        |
| **Default**  | *(empty)* |

The Snyk organisation name or ID under which this project should be scanned
and monitored. This ensures scan results are associated with the correct
organisation in your Snyk account.

If not specified, the default organisation from your Snyk API token will be
used.

**Examples:** `my-org-name`,
`12345678-1234-1234-1234-123456789012`

## Advanced Parameters

These parameters appear in the **Advanced** settings group (collapsed by
default).

### `testDirectory`

| Property     | Value                       |
|--------------|-----------------------------|
| **Type**     | `filePath`                  |
| **Required** | No                          |
| **Default**  | `$(Build.SourcesDirectory)` |

The working directory from which the Snyk scan will be executed. This should
be set to the root directory of your project or the directory containing
manifest files.

Override if your manifest files are in a subdirectory or if you need to scan
from a specific location.

**Examples:** `$(Build.SourcesDirectory)/backend`, `./src`

### `additionalArguments`

| Property     | Value     |
|--------------|-----------|
| **Type**     | `string`  |
| **Required** | No        |
| **Default**  | *(empty)* |

Pass additional command-line arguments directly to the Snyk CLI. This allows
advanced users to configure options not exposed as direct task parameters. The
task will append these to the generated command line.

**Examples:** `--all-projects`,
`--detection-depth=3 --skip-unresolved`

> **Note:** Use with caution; incorrect arguments may cause scans to fail or
> behave unexpectedly.

### `reportFileName`

| Property     | Value              |
|--------------|--------------------|
| **Type**     | `string`           |
| **Required** | No                 |
| **Default**  | *(auto-generated)* |

Custom base name for the generated scan reports. If provided, report files
will be named as `<reportFileName>.json` and `<reportFileName>.html`.

If not provided, the task auto-generates names using the pattern
`report-<testType>-<timestamp>`.

> **Note:** Reports are saved to the Azure DevOps agent temp directory and
> attached to the build for download.

**Example:** `scan-report` generates `scan-report.json` and
`scan-report.html`

## Parameter Relationship Matrix

### Visibility Rules

| Parameter               | Condition                                                                           |
|-------------------------|-------------------------------------------------------------------------------------|
| `dockerImageName`       | Required when `testType = container`                                                |
| `dockerfilePath`        | Visible when `testType = container`                                                 |
| `targetFile`            | Visible when `testType = app`                                                       |
| `severityThreshold`     | Visible when `testType = app` or `container`                                        |
| `codeSeverityThreshold` | Visible when `testType = code`                                                      |
| `monitorWhen`           | Visible when `testType = app` or `container` (auto-set to `never` for `code`/`iac`) |

### Logical Dependencies

- `failOnType` only affects behaviour when:
  - `failOnIssues = true`
  - `testType = app` or `testType = container`
- `monitorWhen` only applies when:
  - `testType = app` or `testType = container`
  - Automatically `never` for `code`/`iac` due to `--report` workflow
