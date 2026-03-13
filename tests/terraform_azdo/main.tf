data "azuredevops_project" "this" {
  name = var.azdo_project_name
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id            = data.azuredevops_project.this.project_id
  service_endpoint_name = var.github_serviceconnection_name
}

resource "azuredevops_build_definition" "this" {
  project_id = data.azuredevops_project.this.project_id
  name       = "compile_pipeline"
  path       = "\\${local.repository_name}"

  repository {
    repo_type             = "GitHub"
    repo_id               = local.repository_id
    yml_path              = "tests/terraform_azdo/empty_pipeline.yml"
    branch_name           = "refs/heads/${var.target_branch}"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.id
  }

  ci_trigger {
    use_yaml = false
  }
}
