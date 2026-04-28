locals {
  repository_name          = "devops-azdo-yaml-pipeline-templates"
  repo_id                  = "UKHO/${local.repository_name}"
  test_pipeline_identifier = "_test.yml"
  template_tests_directory = "${path.root}/../tests/"
  template_tests_to_deploy = {
    for file in fileset(local.template_tests_directory, "**/*${local.test_pipeline_identifier}") :
    replace(replace(file, "/", "_"), ".yml", "") => {
      azdo_folder_name = "${split("/", file)[0]}_template_tests"
      azdo_name        = replace(replace(replace(file, ".yml", ""), "/", "_"), "${split("/", file)[0]}_", "")
      file_path        = "tests/${file}"
    }
  }

  all_pipeline_names = [
    for pipe in values(local.template_tests_to_deploy) :
    pipe.azdo_name
  ]

  pipeline_authorizations = merge([
    for pipeline_key in keys(local.template_tests_to_deploy) : {
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
