# ============================================================================
# TEST FRAMEWORK CONFIGURATION
# ============================================================================
# This file contains all environment-specific configuration that may
# need to be changed based on the deployment environment or Azure DevOps setup.
#
# All paths are relative to the repository root.
# All settings are loaded into a hashtable that's passed to the test runner.

[CmdletBinding()]
param()

# Running inside an Azure Pipelines job?
$isAzurePipelines = $env:TF_BUILD -eq 'True'

# Branch whose templates the server resolves (test YAMLs reference the template
# repository at this branch). Order of precedence:
#   1. PR builds: the PR source branch (Build.SourceBranch is refs/pull/<n>/merge, which
#      does not exist on the GitHub repository as a branch)
#   2. Other CI builds: Build.SourceBranch (the agent checkout is a detached HEAD)
#   3. Local runs: the current git branch
$targetBranch = if ($env:SYSTEM_PULLREQUEST_SOURCEBRANCH)
{
  $env:SYSTEM_PULLREQUEST_SOURCEBRANCH
}
elseif ($env:BUILD_SOURCEBRANCH)
{
  $env:BUILD_SOURCEBRANCH
}
else
{
  git rev-parse --abbrev-ref HEAD
}
$targetBranch = $targetBranch -replace '^refs/heads/', ''

# Pipeline used as the target of the preview-run (compile) requests.
# CI sets COMPILE_TESTS_PIPELINE_ID to its own definition id; locally 1576 (compile_test_pipeline) is used.
$pipelineId = if ($env:COMPILE_TESTS_PIPELINE_ID) { [int]$env:COMPILE_TESTS_PIPELINE_ID } else { 1576 }

$config = @{
  AzDO = @{
    Organization = "ukhydro"
    Project = "DevOps Chapter"
    PipelineId = $pipelineId
  }

  TargetBranch = $targetBranch
  IsAzurePipelines = $isAzurePipelines

  Validation = @{
    SkipValidation = $false
  }

  TestExecution = @{
    ShowVerboseOutput = $false
    ThrowExceptionOnTestFailure = $true
    # Maximum number of concurrent compile requests sent to Azure DevOps.
    # Lower this if you hit throttling (HTTP 429); 1 = fully sequential.
    MaxConcurrentRequests = 8
  }

  SaveCompiledYaml = $false
}

return $config

