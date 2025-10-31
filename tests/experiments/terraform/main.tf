data "azuredevops_project" "this" {
  name = "DevOps Chapter"
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id          = data.azuredevops_project.this.project_id
  service_endpoint_id = "d01ddbe4-5df4-4284-8dce-448c0a40eb5e" # Got this via the 'UKHO' service connection's page
}

locals {
  variableGroups = {
    forPipeline = "ForPipeline",
    forStage = "ForStage",
    forJob = "ForJob"
  }
}

resource "azuredevops_variable_group" "this" {
  project_id   = data.azuredevops_project.this.project_id

  for_each = local.variableGroups

  name         = "Experimental-VariablesAndScope-${each.value}"
  description  = "An experimental variable group that is safe for deletion because it is being used in an experimental branch: experiment/how-do-variables-act-at-different-scopes"
  allow_access = true

  variable {
    name  = "nonSecretVariable"
    value = "water is good for you"
  }

  variable {
    name         = "secretVariable"
    secret_value = "people don't sleep as much as they should"
    is_secret    = true
  }
}

resource "azuredevops_build_definition" "this" {
  project_id = data.azuredevops_project.this.project_id
  name       = "Experiment-VariablesAndScope"
  path       = "\\Experiments"

  repository {
    repo_type             = "GitHub"
    repo_id               = "UKHO/devops-azdo-yaml-pipeline-templates"
    branch_name           = "refs/heads/experiment/how-do-variables-act-at-different-scopes"
    yml_path              = "tests/experiments/how-do-variables-act-at-different-scopes.yml"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }
}
