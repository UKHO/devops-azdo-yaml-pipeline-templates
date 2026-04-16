locals {
  test_pipeline_identifier              = "_test.yml"
  pipelineTemplateTestsAzDoFolderPath   = "${path.root}/../tests/pipelines"
  pipelineTemplateTestsAzDoFolderName   = "pipeline_template_tests"
  pipelineTemplateTestsGitHubFolderPath = "tests/pipelines/"
  pipelineTemplateTestsToDeploy = {
    for file in fileset(local.pipelineTemplateTestsAzDoFolderPath, "*/*${local.test_pipeline_identifier}") :
    replace(basename(file), ".yml", "") => {
      filePath  = file
      azdoName  = replace(replace(file, ".yml", ""), "/", "_")
    }
  }
}

moved {
  from = azuredevops_build_definition.this
  to   = azuredevops_build_definition.pipeline_template_tests
}

resource "azuredevops_build_definition" "pipeline_template_tests" {
  project_id = data.azuredevops_project.this.project_id
  path       = "\\devops-azdo-yaml-pipeline-templates\\${local.pipelineTemplateTestsAzDoFolderName}"
  for_each   = local.pipelineTemplateTestsToDeploy

  name = each.value.azdoName

  repository {
    repo_type             = "GitHub"
    repo_id               = "UKHO/devops-azdo-yaml-pipeline-templates"
    branch_name           = "refs/heads/${var.TargetBranchName}"
    yml_path              = "${local.pipelineTemplateTestsGitHubFolderPath}${each.value.filePath}"
    service_connection_id = data.azuredevops_serviceendpoint_github.this.service_endpoint_id
  }
}
