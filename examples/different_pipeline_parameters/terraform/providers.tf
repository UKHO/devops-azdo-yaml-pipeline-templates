# https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs#argument-reference
provider "azuredevops" {
  org_service_url = "https://dev.azure.com/ukhydro" # Required for finding the azure devops server, combined with entra id login
}
