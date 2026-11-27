# .NET Build (Iteration 7) — File Map

**Status:** Draft companion to [dotnet_build_design_v7.md](dotnet_build_design_v7.md). Nothing here is implemented yet.

**Legend:** **N** = new file, **M** = existing file that changes, *(later)* = not in `0.4.0`.

## Public API (versioned)

```text
jobs/
  dotnet_build.yml                          N  The job: restore → pre-build checks → build → post-build checks → package → finalise → PipelineArtifact
  dotnet_build.CompileTests.ps1             N
  dotnet_deliver_nugetfeed.yml              N  (later) separate delivery job
  dotnet_deliver_containerregistry.yml      N  (later)
  dotnet_deliver_fileshare.yml              N  (later)
```

The delivery jobs could also be added to `pipelines/` as a ready-made .NET pipeline later. Nothing is planned there for `0.4.0`.

## Checks (internal files, public names)

```text
checks/
  dotnetformat.yml                          N  pre-build
  dotnetformat.CompileTests.ps1             N
  dotnettest.yml                            N  post-build; placeholder for NUnit/XUnit/MSTest split
  dotnettest.CompileTests.ps1               N
  dotnetvulnerablepackages.yml              N  (candidate) pre-build
  dotnetcoverage.yml                        N  (later) post-build, report-driven
  terraformformat.yml                          unchanged
```

If the test check splits by framework, `dotnettest.yml` becomes `dotnettestnunit.yml`, `dotnettestxunit.yml` and `dotnettestmstest.yml`. They would share one internal helper (see `utils/`).

## Schemas (internal)

```text
schemas/
  dotnet_build.yml                          N  DotNetBuildConfig, both phase allowlists, names, Packages, Destinations
  dotnet_build.CompileTests.ps1             N
  config_sources.yml                           reused as is
```

Per the AGENTS.md rule, the supported check list lives only in this schema.

## Building Blocks (internal)

```text
tasks/
  dotnet_sdk_installer.yml                  N  UseDotNet@2 / global.json resolve + verify
  dotnet_sdk_installer.CompileTests.ps1     N
  nuget_authenticate.yml                    N  NuGetAuthenticate@1
  nuget_authenticate.CompileTests.ps1       N
  publish_test_results.yml                  N  PublishTestResults@2 (TRX)
  publish_test_results.CompileTests.ps1     N
  publish_code_coverage.yml                 N  PublishCodeCoverageResults@2 (Cobertura)
  publish_code_coverage.CompileTests.ps1    N
  publish_pipeline_artifact.yml                reused (packages, reports, diagnostics)
  download_pipeline_artifact.yml               reused (later delivery jobs)
  powershell.yml                               reused for narrow dotnet CLI steps

utils/
  config_sources_task_list.yml                 reused
  dotnet_check_dispatch.yml                 N  only if dispatching gets too big for the job; otherwise inline like terraform_build
  dotnet_package_list.yml                   N  expands Packages → Publish/NuGet/Container steps
  dotnet_package_list.CompileTests.ps1      N

scripts/dotnet/
  dotnet_resolve_sdk.ps1                    N  global.json / Version resolution and actionable error
  dotnet_check_result.ps1                   N  writes checks/<Phase>/<InstanceKey>/result.json
  dotnet_run_summary.ps1                    N  builds ##vso[task.uploadsummary] markdown
  dotnet_test_guard.ps1                     N  fails filtered runs that ran zero tests; flags missing coverage
  dotnet_metric_compare.ps1                 N  (later) threshold/ratchet helper for DotNetCoverage
```

There's no `stages/` file because the design is job-level only.

## Tests

```text
tests/jobs/dotnet_build/
  build_test.yml                            N  no checks, Publish package → PipelineArtifact
  build_nuget_test.yml                      N  Publish + NuGet packages
  no_packages_test.yml                      N  no destination runs, no artifact
  checks_dotnet_format_test.yml             N
  checks_dotnet_format_treat_as_warnings_test.yml  N
  checks_dotnet_test_test.yml               N  two NUnit category filters, distinct titles
  checks_dotnet_test_coverage_test.yml      N  multi-project coverage merge
  checks_pre_and_post_test.yml              N  both phases, same Name in each phase
  double_build_test.yml                     N  two ArtifactNames in one pipeline
  container_test.yml                        N  (conditional) only if Container ships

tests/shared_resources/dotnet/
  global.json                               N  pinned minimum SDK
  basic_solution/                           N  MyApi.sln, src/MyApi, tests/MyApi.Tests (NUnit, Category=Unit/Integration)
  nuget_library/                            N  packable class library
  dotnet_format/
    formatted/                              N
    unformatted/                            N
  multi_project_coverage/                   N  two test projects + coverlet collector
  no_coverage_collector/                    N  missing-collector case

tests/jobs/jobs.CompileTests.ps1            M  only if new jobs need registering
```

Per §8 of the design, failure scenarios (blocking pre-build, blocking post-build) run in a separate verification pipeline, not in these PR status pipelines.

## Docs

```text
docs/user-docs/jobs/dotnet_build.md         N
docs/user-docs/checks/dotnetformat.md       N
docs/user-docs/checks/dotnettest.md         N
docs/user-docs/checks/README.md             M  add PreBuild/PostBuild phase model + index entries
docs/user-docs/README.md                    M  link the new job
docs/definition_docs/dotnet_build/          N  only if it follows the terraform_pipeline pattern
CHANGELOG.md                                M  [Unreleased] → Added: jobs/dotnet_build.yml, DotNetFormat, DotNetTest, PipelineArtifact destination
```

## CI/CD (maintainer involvement)

```text
cicd/locals.tf                              M  register tests/jobs/dotnet_build/*_test.yml as ADO pipelines + GitHub status checks
```

## Suggested First Prototype

1. `jobs/dotnet_build.yml`
2. `schemas/dotnet_build.yml`
3. `checks/dotnetformat.yml`
4. `checks/dotnettest.yml`
5. `tasks/dotnet_sdk_installer.yml`
6. `tasks/publish_test_results.yml`
7. `tests/shared_resources/dotnet/basic_solution/`
8. `tests/jobs/dotnet_build/build_test.yml`
9. `tests/jobs/dotnet_build/checks_pre_and_post_test.yml`

Coverage, NuGet, the vulnerable-packages check, reporting scripts and delivery jobs can be added once that works end to end.

## Decisions That Change This Map

- **Test check naming:** splitting into framework-specific checks multiplies the `checks/` and docs files.
- **Running checks as their own jobs:** this would add a `jobs/dotnet_check.yml`, and the build job would need to publish its compiled output for it.
