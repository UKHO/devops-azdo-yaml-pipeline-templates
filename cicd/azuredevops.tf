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

# Pipeline authorizations are intentionally NOT managed here. With one test
# pipeline per template test, per-pipeline authorizations made plan/apply very
# slow. The shared resources (agent queue, environment, service connection,
# variable group) are configured as "Open access" in Azure DevOps instead.
#
# The removed blocks below drop the previously managed authorizations from state
# without revoking them in Azure DevOps. They can be deleted once the change has
# been applied.
removed {
  from = azuredevops_pipeline_authorization.this

  lifecycle {
    destroy = false
  }
}

removed {
  from = azuredevops_pipeline_authorization.compile_tests_queue

  lifecycle {
    destroy = false
  }
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
