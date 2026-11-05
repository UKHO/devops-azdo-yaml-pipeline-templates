// Fixture for the TerraformFormat check: this file is DELIBERATELY NOT formatted,
// so 'terraform fmt -check' fails. Do not run 'terraform fmt' on this folder.

variable "environment" {
  type = string
  default     = "dev"
}

output "environment" {
    value = var.environment
}
