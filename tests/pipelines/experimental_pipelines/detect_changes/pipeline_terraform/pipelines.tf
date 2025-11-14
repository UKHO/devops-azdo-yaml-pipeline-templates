locals {
  PipelineAzDoFolderName = "experimental-pipelines"
  PipelinesGitHubFolderPath = "tests/pipelines/experimental_pipelines/detect_changes"
  pipelinesToDeploy = {
    linuxTest = {
      pipeline_name = "terraform-detect-changes-test"
      yamlfile_name = "pipeline.yml"
    }
  }
}

resource "azuredevops_build_definition" "this" {
  project_id = data.azuredevops_project.this.project_id
  path       = "\\devops-azdo-yaml-pipeline-templates\\${local.PipelineAzDoFolderName}"
  for_each = local.pipelinesToDeploy

  name = "${local.PipelineAzDoFolderName}-${each.value.pipeline_name}"

  repository {
    repo_type             = "GitHub"
    repo_id               = "UKHO/devops-azdo-yaml-pipeline-templates"
    branch_name           = "refs/heads/${var.TargetBranchName}"
    yml_path              = "${local.PipelinesGitHubFolderPath}${each.value.yamlfile_name}"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }
}
