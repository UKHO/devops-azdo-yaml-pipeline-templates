locals {
  pipelineTemplateTestsAzDoFolderName   = "terraform_pipelines"
  pipelineTemplateTestsGitHubFolderPath = "tests/pipelines/terraform_pipeline/"
  pipelineTemplateTestsToDeploy = [
    "linux_test",
    "windows_test",
    "elastic_test"
  ]
}

resource "azuredevops_build_definition" "this" {
  project_id = data.azuredevops_project.this.project_id
  path       = "\\devops-azdo-yaml-pipeline-templates\\${local.pipelineTemplateTestsAzDoFolderName}"
  for_each   = local.pipelineTemplateTestsToDeploy

  name = "${local.pipelineTemplateTestsAzDoFolderName}-${each.value}"

  repository {
    repo_type             = "GitHub"
    repo_id               = "UKHO/devops-azdo-yaml-pipeline-templates"
    branch_name           = "refs/heads/${var.TargetBranchName}"
    yml_path              = "${local.pipelineTemplateTestsGitHubFolderPath}${each.value}.yml"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }
}
