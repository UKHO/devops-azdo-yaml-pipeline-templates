data "azuredevops_project" "this" {
  name = var.AzDO_Project_Name
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id          = data.azuredevops_project.this.project_id
  service_endpoint_id = var.GitHub_ServiceConnection_Guid
}
