locals {
  PipelineAzDoFolderName    = "dotnet-pipelines"
  PipelinesGitHubFolderPath = "tests/pipelines/dotnet_build_pipeline/"
  pipelinesToDeploy = {
    linuxTest = {
      pipeline_name = "linux-test"
      yamlfile_name = "linux_test.yml"
    },
    windowsTest = {
      pipeline_name = "windows-test"
      yamlfile_name = "windows_test.yml"
    },
  }
}

resource "azuredevops_build_definition" "this" {
  project_id = data.azuredevops_project.this.project_id
  path       = "\\devops-azdo-yaml-pipeline-templates\\${local.PipelineAzDoFolderName}"
  for_each   = local.pipelinesToDeploy

  name = "${local.PipelineAzDoFolderName}-${each.value.pipeline_name}"

  repository {
    repo_type             = "GitHub"
    repo_id               = "UKHO/devops-azdo-yaml-pipeline-templates"
    branch_name           = "refs/heads/${var.TargetBranchName}"
    yml_path              = "${local.PipelinesGitHubFolderPath}${each.value.yamlfile_name}"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }
}
