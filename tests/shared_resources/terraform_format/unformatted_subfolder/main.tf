// Fixture for the TerraformFormat check: this root file is formatted, but modules/child is NOT.
// 'terraform fmt -check' (no -recursive) passes here; 'terraform fmt -check -recursive' fails.
// Keep this file formatted.

module "child" {
  source = "./modules/child"
}

output "child_environment" {
  value = module.child.environment
}
