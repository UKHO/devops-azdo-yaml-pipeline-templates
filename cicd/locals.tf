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

  all_pipeline_names = concat(
    [
      for pipe in values(local.template_tests_to_deploy) :
      pipe.azdo_name
    ],
    [local.compile_tests_pipeline.azdo_name]
  )

  # Single pipeline that runs Run-AllCompileTests.ps1 (all *.CompileTests.ps1 files)
  compile_tests_pipeline = {
    azdo_name = "compile_tests"
    file_path = "cicd/pipelines/compile_tests.yml"
  }
}
