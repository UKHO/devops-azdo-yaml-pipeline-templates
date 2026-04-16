locals {
  repository_name                       = "devops-azdo-yaml-pipeline-templates"
  repo_id                               = "UKHO/${local.repository_name}"
  target_branch_name                    = "main"
  test_pipeline_identifier              = "_test.yml"
  pipelineTemplateTestsAzDoFolderPath   = "${path.root}/../tests/pipelines"
  pipelineTemplateTestsAzDoFolderName   = "pipeline_template_tests"
  pipelineTemplateTestsGitHubFolderPath = "tests/pipelines/"
  pipelineTemplateTestsToDeploy = {
    for file in fileset(local.pipelineTemplateTestsAzDoFolderPath, "*/*${local.test_pipeline_identifier}") :
    replace(basename(file), ".yml", "") => {
      file_path = file
      azdo_name = replace(replace(file, ".yml", ""), "/", "_")
    }
  }

  all_pipeline_names = [
    for pipe in values(local.pipelineTemplateTestsToDeploy) :
    pipe.azdo_name
  ]

  pipeline_authorizations = merge([
    for pipeline_key in keys(local.pipelineTemplateTestsToDeploy) : {
      for auth_type, resource_id in {
        "queue"         = data.azuredevops_agent_queue.this.id
        "environment"   = data.azuredevops_environment.this.id
        "endpoint"      = data.azuredevops_serviceendpoint_azurerm.this.id
        "variablegroup" = data.azuredevops_variable_group.this.id
      } :
      "${pipeline_key}_${auth_type}" => {
        pipeline_key = pipeline_key
        type         = auth_type
        resource_id  = resource_id
      }
    }
  ]...)
}
