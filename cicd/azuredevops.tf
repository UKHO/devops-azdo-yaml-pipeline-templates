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

  name = each.value.azdo_name

  repository {
    repo_type             = "GitHub"
    repo_id               = local.repo_id
    branch_name           = "refs/heads/${var.TargetBranchName}"
    yml_path              = "${local.pipelineTemplateTestsGitHubFolderPath}${each.value.file_path}"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }

  ci_trigger {
    override {
      branch_filter {
        include = [var.TargetBranchName]
      }
      path_filter {
        include = [each.value.file_path]
      }
    }
  }

  pull_request_trigger {
    override {
      branch_filter {
        include = [var.TargetBranchName]
      }
      path_filter {
        include = [each.value.file_path]
      }
      auto_cancel = false
    }
    initial_branch = var.TargetBranchName
    forks {
      enabled       = false
      share_secrets = false
    }
  }
}
