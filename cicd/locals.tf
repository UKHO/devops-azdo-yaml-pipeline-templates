locals {
  repository_name = "devops-azdo-yaml-pipeline-templates"
  repo_id         = "UKHO/${local.repository_name}"

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
}
