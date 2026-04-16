data "azuredevops_project" "this" {
  name = var.AzDO_Project_Name
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id          = data.azuredevops_project.this.project_id
  service_endpoint_id = var.GitHub_ServiceConnection_Guid
}

resource "azuredevops_build_definition" "pipeline_template_tests" {
  project_id = data.azuredevops_project.this.project_id
  path       = "\\devops-azdo-yaml-pipeline-templates\\${local.pipelineTemplateTestsAzDoFolderName}"
  for_each   = local.pipelineTemplateTestsToDeploy

  name = each.value.azdoName

  repository {
    repo_type             = "GitHub"
    repo_id               = "UKHO/devops-azdo-yaml-pipeline-templates"
    branch_name           = "refs/heads/${var.TargetBranchName}"
    yml_path              = "${local.pipelineTemplateTestsGitHubFolderPath}${each.value.filePath}"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }
}
