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
