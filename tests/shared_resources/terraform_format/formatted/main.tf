// Fixture for the TerraformFormat check: every file here is formatted, so 'terraform fmt -check' passes.
// Keep this file formatted. Run 'terraform fmt -recursive' in this folder after editing.

variable "environment" {
  type    = string
  default = "dev"
}

locals {
  name_prefix = "fmt-${var.environment}"
  tags = {
    environment = var.environment
    purpose     = "terraform-format-check-fixture"
  }
}

output "name_prefix" {
  value = local.name_prefix
}

output "tags" {
  value = local.tags
}
