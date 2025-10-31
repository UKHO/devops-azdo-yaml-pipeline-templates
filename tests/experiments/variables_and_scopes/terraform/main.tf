data "azuredevops_project" "this" {
  name = var.AzDO_Project_Name
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id          = data.azuredevops_project.this.project_id
  service_endpoint_id = var.GitHub_ServiceConnection_Guid
}

locals {
  variableGroups = {
    forPipeline = "ForPipeline",
    forStage    = "ForStage",
    forJob      = "ForJob"
  }
}

resource "azuredevops_variable_group" "this" {
  project_id = data.azuredevops_project.this.project_id

  for_each = local.variableGroups

  name         = "Experimental-VariablesAndScope-${each.value}"
  description  = "An experimental variable group that is safe for deletion because it is being used in an experimental branch: experiment/how-do-variables-act-at-different-scopes"
  allow_access = true

  variable {
    name  = "nonSecretVariable-${each.value}"
    value = "nonSecretVariableValue-${each.value}"
  }

  variable {
    name         = "secretVariable-${each.value}"
    secret_value = "secretVariableValue-${each.value}"
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
    branch_name           = "refs/heads/main"
    yml_path              = "tests/experiments/variables_and_scopes/how-do-variables-act-at-different-scopes.yml"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }
}
