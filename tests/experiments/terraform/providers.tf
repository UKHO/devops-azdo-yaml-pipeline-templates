# https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs#argument-reference
provider "azuredevops" {
  org_service_url = "https://dev.azure.com/ukhydro" # Required for finding the azure devops server
  # personal_access_token
  # client_id
  # client_id_file_path
  # tenant_id
  # auxiliary_tenant_ids
  # client_secret
  # client_secret_path
  # client_certificate_path
  # client_certificate
  # client_certificate_password
  # oidc_token
  # oidc_request_token
  # oidc_request_url
  # oidc_azure_service_connection_id
  # use_msi
  # use_cli
}
