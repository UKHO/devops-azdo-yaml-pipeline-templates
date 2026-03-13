output "pipeline_name" {
  value       = azuredevops_build_definition.this.name
  description = "The name of the test pipeline for yml validation."
}
