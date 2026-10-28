data "azuredevops_project" "this" {
  name = var.azdo_project_name
}

data "azuredevops_serviceendpoint_github" "this" {
  project_id            = data.azuredevops_project.this.id
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

resource "azuredevops_build_definition" "template_tests" {
  project_id = data.azuredevops_project.this.id
  for_each   = local.template_tests_to_deploy

  name = each.value.azdo_name

  agent_pool_name = data.azuredevops_agent_queue.this.name

  path = "\\${local.repository_name}\\${each.value.azdo_folder_name}"
  repository {
    repo_type             = "GitHub"
    repo_id               = local.repo_id
    branch_name           = "refs/heads/main"
    yml_path              = each.value.file_path
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
  pipeline_id = azuredevops_build_definition.template_tests[each.value.pipeline_key].id
  resource_id = each.value.resource_id
}


# ---------------------------------------------------------------------------
# Compile tests pipeline (Run-AllCompileTests.ps1)
# ---------------------------------------------------------------------------

resource "azuredevops_build_definition" "compile_tests" {
  project_id = data.azuredevops_project.this.id
  name       = local.compile_tests_pipeline.azdo_name

  agent_pool_name = data.azuredevops_agent_queue.this.name

  path = "\\${local.repository_name}"
  repository {
    repo_type             = "GitHub"
    repo_id               = local.repo_id
    branch_name           = "refs/heads/main"
    yml_path              = local.compile_tests_pipeline.file_path
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }

  ci_trigger {
    use_yaml = true
  }

  # Draft pull requests are included via 'pr.drafts: true' in the YAML
  pull_request_trigger {
    use_yaml = true
    forks {
      enabled       = false
      share_secrets = false
    }
  }
}

# Only the agent queue is needed: the job deploys nothing and uses no service
# connections, environments or variable groups.
resource "azuredevops_pipeline_authorization" "compile_tests_queue" {
  project_id  = data.azuredevops_project.this.id
  type        = "queue"
  pipeline_id = azuredevops_build_definition.compile_tests.id
  resource_id = data.azuredevops_agent_queue.this.id
}
# The tests send preview runs (POST _apis/pipelines/{id}/runs, previewRun: true) of this
# pipeline's own definition using System.AccessToken, i.e. as the project build service.
# By default that identity does NOT have 'Queue builds' (checked via the security REST API),
# so grant what it needs on this definition only.
#
# The principal must be the Graph *subject* descriptor of the project build service. It is
# computed rather than looked up: 'svc.' + unpadded base64('<organisation id>:Build:<project id>').
# (The azuredevops_identity_user data source was unreliable for this identity, and returns the
# identity descriptor, which this resource rejects.)
resource "azuredevops_build_definition_permissions" "compile_tests" {
  project_id          = data.azuredevops_project.this.id
  build_definition_id = azuredevops_build_definition.compile_tests.id
  principal           = local.compile_tests_pipeline.build_service_subject_descriptor
  replace             = false

  permissions = {
    ViewBuilds          = "Allow"
    ViewBuildDefinition = "Allow"
    QueueBuilds         = "Allow"
  }
}
