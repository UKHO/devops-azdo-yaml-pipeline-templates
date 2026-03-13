data "azuredevops_project" "this" {
  name = var.azdo_project_name
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id            = data.azuredevops_project.this.project_id
  service_endpoint_name = var.github_serviceconnection_name
}

resource "random_string" "this" {
  length = 8
  lower  = true
}

resource "azuredevops_build_definition" "this" {
  project_id = data.azuredevops_project.this.project_id
  name       = "unit_test_${random_string.this.result}"
  path       = "\\${local.repository_name}\\unit_tests"

  repository {
    repo_type             = "GitHub"
    repo_id               = local.repository_id
    yml_path              = "tests/unit_tests/yaml/pipeline.yml"
    branch_name           = "refs/heads/${var.target_branch}"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.id
  }

  ci_trigger {
    use_yaml = false
  }
}
