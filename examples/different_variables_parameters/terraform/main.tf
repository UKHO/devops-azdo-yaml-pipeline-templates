data "azuredevops_project" "this" {
  name = var.AzDO_Project_Name
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id          = data.azuredevops_project.this.project_id
  service_endpoint_id = var.GitHub_ServiceConnection_Guid
}

resource "azuredevops_build_definition" "this" {
  project_id = data.azuredevops_project.this.project_id
  name       = "ExamplePipeline-DifferentVariableParameters"
  path       = "\\ExamplePipelines"

  repository {
    repo_type             = "GitHub"
    repo_id               = "UKHO/devops-azdo-yaml-pipeline-templates"
    branch_name           = "refs/heads/experiment/different-parameters"
    yml_path              = "examples/different_variables_parameters/different_variables_parameters.yml"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }
}
