data "azuredevops_project" "this" {
  name = var.azdo_project_name
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id            = data.azuredevops_project.this.project_id
  service_endpoint_name = var.github_serviceconnection_name
}

data "azuredevops_agent_queue" "this" {
  name       = var.azdo_agent_pool_name
  project_id = data.azuredevops_project.this.id
}

data "azuredevops_environment" "this" {
  name       = var.azdo_environment_name
  project_id = data.azuredevops_project.this.id
}

data "azuredevops_serviceendpoint_azurerm" "this" {
  service_endpoint_name = var.azurerm_serviceconnection_name
  project_id            = data.azuredevops_project.this.id
}

data "azuredevops_variable_group" "this" {
  name       = "DevOpsChapterAzureSubscription"
  project_id = data.azuredevops_project.this.id
}

resource "azuredevops_build_definition" "pipeline_template_tests" {
  project_id = data.azuredevops_project.this.project_id
  path       = "\\devops-azdo-yaml-pipeline-templates\\${local.pipelineTemplateTestsAzDoFolderName}"
  for_each   = local.pipelineTemplateTestsToDeploy

  name = each.value.azdo_name

  repository {
    repo_type             = "GitHub"
    repo_id               = local.repo_id
    branch_name           = "refs/heads/${local.target_branch_name}"
    yml_path              = "${local.pipelineTemplateTestsGitHubFolderPath}${each.value.file_path}"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }

  ci_trigger {
    use_yaml = true
  }

  pull_request_trigger {
    use_yaml = true
    forks {
      enabled       = false
      share_secrets = false
    }
  }
}

resource "azuredevops_pipeline_authorization" "this" {
  for_each = local.pipeline_authorizations

  project_id  = data.azuredevops_project.this.id
  type        = each.value.type
  pipeline_id = azuredevops_build_definition.pipeline_template_tests[each.value.pipeline_key].id
  resource_id = each.value.resource_id
}
