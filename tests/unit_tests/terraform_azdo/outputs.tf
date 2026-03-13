output "pipeline_id" {
  value       = azuredevops_build_definition.this.id
  description = "The id of the test pipeline for yml validation."
}
